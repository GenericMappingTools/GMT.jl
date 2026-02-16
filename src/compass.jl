"""
    compass(; kwargs...)

Draw a map directional rose or magnetic compass on the map.

If `dec` (magnetic declination) is provided, draws a magnetic compass rose (`-Tm`).
Otherwise, draws a directional rose (`-Td`).

Can be called standalone (creates its own plot) or as an overlay (`compass!`) on an existing plot.
When called standalone without `region`/`proj`, a default canvas sized to fit the rose is created
automatically.

### Compass-specific options

- **anchor** :: [Type => Tuple | Str] — Reference point on the map for the rose.
- **width** :: [Type => Number | Str] — Width of the rose in cm.
- **justify** :: [Type => Str] — Justification of the rose relative to anchor.
- **labels** or **label** :: [Type => Str] — Comma-separated labels for the cardinal points.
- **offset** :: [Type => Tuple | Str] — Offset from the anchor point.
- **map** | **inside** | **outside** | **norm** | **paper** :: [Type => Str] — Coordinate system for the anchor.

### Directional rose only (`-Td`)

- **fancy** :: [Type => Bool | Int] — Draw a fancy rose. 1-3 for different levels.

### Magnetic compass only (`-Tm`)

- **dec** :: [Type => Number | Str] — Magnetic declination.
- **rose_primary** :: [Type => Tuple | Str] — Pen for the primary rose circle.
- **rose_secondary** :: [Type => Tuple | Str] — Pen for the secondary rose circle.
- **annot** :: [Type => Tuple | Str] — Annotation info for the magnetic compass.

All other keyword arguments (e.g., `region`, `proj`, `par`, `show`, `savefig`, `Vd`, etc.)
are passed through to `basemap`.

### Examples

Draw a standalone directional rose:

```julia
compass(width=2.5, fancy=true, labels=",,,N", show=true)
```

Draw a directional rose as overlay:

```julia
coast(region=(-10,10,-10,10), proj=:Mercator, frame=:auto, land=:lightgray)
compass!(width=2.5, anchor=(0,0), justify=:CM, fancy=true, labels=",,,N", show=true)
```

Draw a magnetic compass:

```julia
basemap(region=(-8,8,-6,6), proj=:Mercator, frame=:auto)
compass!(anchor=(0,0), width=6, dec=-14.5, annot=(45,10,5,30,10,2),
         rose_primary=(0.25,:blue), rose_secondary=0.5, labels="", show=true)
```
"""
compass!(; kw...) = compass(; first=false, kw...)
function compass(; first=true, kw...)
	d = init_module(false, kw...)[1]		# Also checks if the user wants ONLY the HELP mode
	compass(first, d)
end
function compass(first::Bool, d::Dict{Symbol, Any})

	compass_keys = (:anchor, :width, :justify, :labels, :label, :offset,
	                :map, :inside, :outside, :norm, :paper,
	                :fancy, :dec, :rose_primary, :rose_secondary, :annot)

	nt_pairs = Pair{Symbol,Any}[]
	for k in compass_keys
		haskey(d, k) && push!(nt_pairs, k => pop!(d, k))
	end

	is_magnetic = any(p -> p.first === :dec, nt_pairs)

	# When standalone (first=true) and no region/proj given, create a paper-coordinates canvas.
	has_RJ = any(k -> haskey(d, k), (:R, :region, :limits, :J, :proj, :projection))
	if (first && !has_RJ)
		# Get the width to size the canvas (default 5 cm)
		w = 5.0
		for p in nt_pairs
			if p.first === :width
				w = isa(p.second, Real) ? Float64(p.second) : 5.0
				break
			end
		end
		sz = ceil(w * 1.6; digits=1)	# Canvas slightly larger than the rose
		d[:region] = (0, sz, 0, sz)
		d[:proj] = "X$(sz)c"
		# Default anchor to center of canvas in paper coordinates if not provided
		has_anchor = any(p -> p.first === :anchor, nt_pairs)
		has_coord  = any(p -> p.first in (:map, :inside, :outside, :norm, :paper), nt_pairs)
		if !has_anchor && !has_coord
			# No positioning at all — center the rose on the canvas
			push!(nt_pairs, :paper => "$(sz/2)/$(sz/2)")
			push!(nt_pairs, :justify => :CM)
		elseif has_anchor && !has_coord
			# User gave anchor but no coordinate system — use paper coords
			anc = pop_anchor!(nt_pairs)
			push!(nt_pairs, :paper => isa(anc, Tuple) ? join(anc, '/') : string(anc))
		end
	end

	nt = (; nt_pairs...)

	if is_magnetic
		d[:compass] = nt    # -> parse_Tm -> -Tm
	else
		d[:rose] = nt       # -> parse_Td -> -Td
	end

	haskey(d, :frame) || haskey(d, :B) || (d[:frame] = :none)
	helper_basemap(!first, true, d)
end

# Helper to pop :anchor from nt_pairs and return its value
function pop_anchor!(pairs::Vector{Pair{Symbol,Any}})
	for i in eachindex(pairs)
		if pairs[i].first === :anchor
			val = pairs[i].second
			deleteat!(pairs, i)
			return val
		end
	end
	return nothing
end
