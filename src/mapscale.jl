"""
    mapscale(; kwargs...)

Draw a map scale bar on the map.

Can be called as an overlay (`mapscale!`) on an existing plot, or standalone with explicit
`region` and `proj`.

### Map scale options

- **anchor** :: [Type => Tuple | Str] — Reference point on the map for the scale bar.
- **scale_at_lat** :: [Type => Number] — Latitude at which the scale is computed.
- **length** or **width** :: [Type => Str | Number] — Length of the scale bar (append unit, e.g., `"1000k"`).
- **fancy** :: [Type => Bool] — Draw a fancy scale bar instead of a plain one.
- **label** :: [Type => Str | Bool] — Label for the scale bar. Use `true` for the default unit label.
- **align** :: [Type => Symbol | Str] — Label alignment (`:left`, `:right`, `:top`, `:bottom`).
- **justify** :: [Type => Str] — Justification of the scale relative to anchor.
- **offset** :: [Type => Tuple | Str] — Offset from the anchor point.
- **units** :: [Type => Bool | Str] — Append the unit to all distance annotations.
- **vertical** :: [Type => Bool] — Plot a vertical instead of horizontal Cartesian scale.
- **map** | **inside** | **outside** | **norm** | **paper** :: [Type => Str] — Coordinate system for the anchor.

All other keyword arguments (e.g., `region`, `proj`, `frame`, `par`, `show`, `savefig`, `Vd`,
`box`, etc.) are passed through to `basemap`.

### Examples

```julia
coast(region=(0,40,50,56), proj=:Mercator, frame=:auto, land=:lightgray)
mapscale!(inside=:ML, scale_at_lat=53, length="1000k", fancy=true, label=true, show=true)
```
"""
mapscale!(; kw...) = mapscale(; first=false, kw...)
function mapscale(; first=true, kw...)
	d = init_module(false, kw...)[1]		# Also checks if the user wants ONLY the HELP mode
	mapscale(first, d)
end
function mapscale(first::Bool, d::Dict{Symbol, Any})

	scale_keys = (:anchor, :scale_at_lat, :length, :width, :fancy, :label, :align,
	              :justify, :offset, :units, :vertical,
	              :map, :inside, :outside, :norm, :paper)

	nt_pairs = Pair{Symbol,Any}[]
	for k in scale_keys
		haskey(d, k) && push!(nt_pairs, k => pop!(d, k))
	end

	d[:map_scale] = (; nt_pairs...)

	haskey(d, :frame) || haskey(d, :B) || (d[:frame] = :none)
	helper_basemap(!first, true, d)
end
