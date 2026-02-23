# ------------------------------------------------------------------------------------------
# Shared helpers used by the montage methods
# ------------------------------------------------------------------------------------------

"""Set up the frame/B/D options in `d` for montage panels."""
function _montage_setup_frame!(d::Dict, frame::String, opt_B::String="")
	if frame == "0"
		d[:par] = (MAP_FRAME_PEN="0",); d[:frame] = frame
	elseif frame !== ""
		d[:B] = "0"; d[:par] = (:MAP_FRAME_PEN, parse_pen(frame))
	end
	if opt_B !== ""
		d[:B] = opt_B
	elseif !haskey(d, :B) && frame == ""
		d[:D] = true; d[:B] = "+n"
	end
end

"""Convert `divlines` kwarg to a `+w<pen>` suffix string for panels_size."""
function _montage_divlines!(d::Dict, divlines)::String
	(divlines === false || divlines == 0) && return ""
	d[:divlines] = divlines
	dvl = add_opt_pen(d, [:divlines])
	return dvl !== "" ? "+w" * dvl : ""
end

"""Format `panels_size` (scalar or tuple) into a string, appending optional divlines suffix."""
function _montage_panels_size_str(panels_size, dvl::String="")::String
	if isa(panels_size, Tuple)
		return string(panels_size[1], "/", panels_size[2], dvl)
	else
		return string(panels_size, dvl)
	end
end

"""Auto-adjust subplot margins for titles, colorbars, and annotations."""
function _montage_adjust_margins!(d::Dict, titles, colorbar, cbar, margins::String)
	if margins == "0.0"
		dy = !isempty(titles) ? 0.5 : 0.0
		(cbar !== false) && (dy += 0.6)
		dx = (get(d, :B, "+n") != "+n") &&
		     (colorbar == true || colorbar == :right ||
		      (isa(cbar, String) && contains(cbar, "RM"))) ? 0.90 : 0.38
		(dx != 0 || dy != 0) && (d[:M] = "0.38c/$(dx)c/$(dy)c/0")
	else
		d[:M] = margins
	end
	d[:par] = (MAP_TITLE_OFFSET="0p", FONT_TITLE="auto,Helvetica,black")
end

"""Compute panels_size string from images or explicit value. Returns the string to use."""
function _montage_panels_size!(d::Dict, images, panels_size::String, ncols::Int)::String
	if panels_size == ""
		_imgs = isa(images, AbstractVector) ? images : [images]
		widths, heights = subplot_panel_sizes(_imgs, ncols=ncols)
		return arg2str(widths,',') * "/" * arg2str(heights,',')
	else
		return panels_size
	end
end

# ------------------------------------------------------------------------------------------
"""
    montage(images; grid=(0,0), panels_size="", margins="0.0", title="",
            titles=String[], frame="", indices=Int[], show=true, noR=false, kw...)

Display multiple images or grids arranged in a grid layout using GMT's subplot machinery.
Panel sizes are automatically computed from the aspect ratios of the input images
(via `subplot_panel_sizes`) unless `panels_size` is given explicitly.

### Arguments
- `images`: Vector of GMTimage/GMTgrid objects or file name strings.

### Keywords
- `grid`: Tuple `(nrows, ncols)` specifying grid dimensions. Use `(0,0)` for auto. Default: `(0,0)`.
- `panels_size`: Panel size — a scalar, a tuple `(w, h)`, or a pre-formatted string.
  Use `""` for auto from aspect ratios. Default: `""`.
- `margins`: Gap between panels (GMT subplot margins syntax). Default: `"0.0"`.
- `title`: Overall figure title string. Default: `""` (no title).
- `titles`: Vector of panel title strings. Default: `String[]` (no titles).
- `frame`: Frame style for panels. Use `"0"` for invisible frame outline, or a pen
  specification. Default: `""` (no frame, `-D`).
- `indices`: Vector of integer indices to select a subset of `images`. Default: `Int[]` (all).
- `noR`: If `true`, skip passing the `-R` region from the image metadata.
- `show`: Display the result (`true`) or keep the PS file open (`false`). Default: `true`.

### Examples
```julia
montage(["img1.png", "img2.png", "img3.png", "img4.png"], grid=(2,2))

imgs = [gmtread("img\$i.png") for i in 1:6]
montage(imgs, grid=(2,3), titles=["A","B","C","D","E","F"], panels_size=5)

imgs = [mat2img(rand(UInt8, 64, 64)) for _ in 1:4]
montage(imgs, grid=(2,2), panels_size=5)
```

See also: `subplot`, `subplot_panel_sizes`
"""
function montage(images; kw...)
	d = KW(kw)
	_montage_images(images, d)
end

function _montage_images(images, d::Dict)
	indices = pop!(d, :indices, Int[])::Vector{Int}
	!isempty(indices) && (images = images[indices])
	((n = length(images)) == 0) && error("No images to display")

	grid     = pop!(d, :grid, (0,0))
	margins  = string(pop!(d, :margins, "0.0"))::String
	title    = string(pop!(d, :title, ""))::String
	titles   = pop!(d, :titles, String[])
	frame    = string(pop!(d, :frame, ""))::String
	_show    = pop!(d, :show, true)::Bool
	noR      = pop!(d, :noR, false)::Bool
	ps_val   = pop!(d, :panels_size, "")	# Can be number, tuple, or string

	nrows, ncols = _montage_grid_size(n, grid)

	d[:grid] = (nrows, ncols)
	d[:margin] = margins
	_montage_setup_frame!(d, frame)
	(title !== "") && (d[:title] = title)

	# Build panels_size string
	if ps_val == "" || ps_val === nothing
		ps_str = _montage_panels_size!(d, images, "", ncols)
	elseif isa(ps_val, Tuple)
		ps_str = string(ps_val[1], "/", ps_val[2])
	else
		ps_str = string(ps_val)
	end
	d[:panels_size] = ps_str

	Vd = get(d, :Vd, 0)

	# Save and remove keys that subplot doesn't understand but viz needs
	_has_cpt = haskey(d, :C)
	saved_cpt = _has_cpt ? pop!(d, :C) : GMTcpt()

	subplot("", false, d)
	d = CTRL.pocket_d[1]

	_has_cpt && (d[:C] = saved_cpt)

	# Plot each input
	d[:J] = "x?"
	k = 0;	n_inputs = length(images)
	for row in 1:nrows
		for col in 1:ncols
			((k += 1) > n_inputs) && break
			panel_title = (!isempty(titles) && k <= length(titles)) ? titles[k] : nothing
			opt_R = isa(images[k], GItype) ? (noR ? "" : getR(images[k])) : ""
			viz(images[k]; panel=(row, col), title=panel_title, R=(opt_R !== "" ? opt_R : nothing), Vd=Vd, show=false, d...)
		end
	end
	subplot(_show ? :show : :end)

	return nothing
end

# ----------------------------------------------------------------------------------------------------------
"""
    montage(GI; grid=(0,0), panels_size="", margins="0.0", title="",
            titles="", frame="", indices=Int[], cmap=nothing,
            cmap_mode="same", colorbar=false, divlines=false, show=true, kw...)

Display the layers of a 3D grid or image cube arranged in a grid layout.

Each layer along the third dimension is extracted via `slicecube` and plotted in its own
panel using `grdimage` inside a GMT `subplot`.

### Arguments
- `GI`: A 3D `GMTgrid` or `GMTimage` cube (must have at least 2 layers).

### Keywords
- `grid`: Tuple `(nrows, ncols)` specifying the panel grid dimensions. Use `(0,0)` for auto.
- `panels_size`: Panel size in cm — a scalar, a tuple `(w, h)`, or a pre-formatted string.
  Default: auto-computed from the cube's aspect ratio.
- `margins`: Gap between panels (GMT subplot margins syntax). Default: `"0.0"`.
- `title`: Overall figure title string.
- `titles`: Vector of per-panel title strings, or `"auto"` to derive titles from the cube's
  `names` field or `v` (vertical coordinate) values.
- `frame`: Frame style for panels (e.g. `"0"` for invisible outline). Default: no frame.
- `indices`: Vector of integer indices to select a subset of layers.
- `cmap`: Color palette — a colormap name (e.g. `"turbo"`), a `GMTcpt` object, or `nothing`
  for the GMT default colormap.
- `cmap_mode`: `"same"` (default) uses a single CPT computed from the cube's global min/max.
  `"individual"` computes a separate CPT per layer, each scaled to that layer's own range.
- `colorbar`: Add a colorbar to each panel. `false` (default, no colorbar), `true` (right side),
  or a GMT colorbar position string/NamedTuple.
- `divlines`: Draw dividing lines between panels. E.g. `divlines=0.5` or `divlines=(1,:red)`.
- `show`: Display the result. Default: `true`.

### Examples
```julia
G = gmtread("cube.nc", layers=:all)
montage(G)

montage(G, grid=(2,3), titles="auto")

montage(G, cmap="turbo", colorbar=true)

montage(G, cmap="turbo", cmap_mode=:individual, colorbar=true)

montage(G, indices=[1,3,5], divlines=(0.5,:red))
```

See also: `slicecube`, `imshow`, `subplot`
"""
function montage(GI::GItype; kw...)
	d = KW(kw)
	_montage_cube(GI, d)
end

function _montage_cube(GI::GItype, d::Dict)
	n_levels = size(GI, 3)
	(n_levels < 2) && (@warn("Input has only one layer, nothing to montage."); return nothing)

	indices   = pop!(d, :indices, Int[])::Vector{Int}
	grid      = pop!(d, :grid, (0,0))
	margins   = string(pop!(d, :margins, "0.0"))::String
	title     = string(pop!(d, :title, ""))::String
	titles    = pop!(d, :titles, "")
	frame     = string(pop!(d, :frame, ""))::String
	cmap      = pop!(d, :cmap, nothing)
	cmap_mode = string(pop!(d, :cmap_mode, "same"))::String
	colorbar  = pop!(d, :colorbar, false)
	divlines  = pop!(d, :divlines, false)
	_show     = pop!(d, :show, true)::Bool
	ps_val    = pop!(d, :panels_size, "")

	layers = !isempty(indices) ? indices : collect(1:n_levels)
	n_layers = length(layers)

	# Build panel titles
	_titles = String[]
	if isa(titles, AbstractVector) && !isempty(titles)
		_titles = titles
	elseif isa(titles, AbstractString) && titles !== ""
		if lowercase(titles) == "auto"
			if     (!isempty(GI.names) && !all(GI.names .== ""))  _titles = GI.names[layers]
			elseif (isa(GI, GMTgrid) && !isempty(GI.v))           _titles = string.(GI.v[layers])
			else                                                  _titles = string.(layers)
			end
		else
			_titles = [titles]
		end
	end

	# Handle cmap and cmap_mode
	individual = lowercase(cmap_mode) == "individual"
	if (!individual)
		if (cmap === nothing)
			d[:C] = makecpt(GI.range[5], GI.range[6])
		elseif isa(cmap, GMTcpt)
			d[:C] = cmap
		else
			d[:C] = makecpt(C=cmap, range=(GI.range[5], GI.range[6]))
		end
	end
	_indiv_cmap = cmap

	# Compute a uniform panels_size from the cube's aspect ratio if not provided
	nrows, ncols = _montage_grid_size(n_layers, grid)
	if ps_val == "" || ps_val === nothing
		W, H = getsize(GI)
		aspect = H / W
		pw = max(3, min(8, 18 / max(nrows, ncols)))
		panels_size = (pw, round(pw * aspect, digits=2))
	elseif isa(ps_val, Tuple)
		panels_size = ps_val
	else
		panels_size = ps_val
	end

	dvl = _montage_divlines!(d, divlines)

	# Handle colorbar
	(colorbar != false) && (d[:colorbar] = colorbar)

	# Extract 2D slices
	slices = [slicecube(GI, layers[k]) for k in 1:n_layers]

	ps_str = _montage_panels_size_str(panels_size, dvl)

	if (!individual)
		# Delegate to _montage_images via the Dict path
		d[:grid] = grid;  d[:panels_size] = ps_str;  d[:margins] = margins
		d[:title] = title;  d[:titles] = _titles;  d[:frame] = frame;  d[:show] = _show
		_montage_images(slices, d)
	else
		# For individual CPTs we need to reset CURRENT_CPT between panels
		d[:grid] = (nrows, ncols)
		_montage_setup_frame!(d, frame)
		_montage_adjust_margins!(d, _titles, colorbar, colorbar, margins)
		(title !== "") && (d[:title] = title)
		d[:panels_size] = ps_str
		saved_cbar = haskey(d, :colorbar) ? pop!(d, :colorbar) : false
		Vd = get(d, :Vd, 0)
		subplot("", false, d)
		d = CTRL.pocket_d[1]
		d[:J] = "x?"
		(saved_cbar !== false) && (d[:colorbar] = saved_cbar)
		k = 0
		for row in 1:nrows, col in 1:ncols
			((k += 1) > n_layers) && break
			CURRENT_CPT[] = GMTcpt()		# Force a new CPT for each layer
			panel_title = (!isempty(_titles) && k <= length(_titles)) ? _titles[k] : nothing
			zmin, zmax = slices[k].range[5], slices[k].range[6]
			if (zmin == zmax)
				d[:C] = makecpt(zmin - 1, zmax + 1)
			elseif (_indiv_cmap !== nothing)
				isa(_indiv_cmap, GMTcpt) ? (d[:C] = _indiv_cmap) : (d[:C] = makecpt(C=_indiv_cmap, range=(zmin, zmax)))
			end
			viz(slices[k]; panel=(row, col), title=panel_title, R=getR(slices[k]), Vd=Vd, show=false, d...)
			haskey(d, :C) && delete!(d, :C)
		end
		subplot(_show ? :show : :end)
	end
end

# ----------------------------------------------------------------------------------------------------------
"""
    montage(D::Vector{<:GMTdataset}; grid=(0,0), panels_size="", margins="0.0",
            choro=true, colorbar=false, attribs=String[], title="", titles=String[],
            divlines=false, show=true, kw...)

Display a multi-panel choropleth from vector polygon data. Each panel maps one numeric
attribute of `D` (obtained via `getattribs`). Panels are laid out in a subplot grid, each
drawn with `choropleth`.

### Arguments
- `D`: Vector of `GMTdataset` polygons with numeric attributes stored in `D[k].attrib`.

### Keywords
- `grid`: Tuple `(nrows, ncols)`. Use `(0,0)` for auto. Default: `(0,0)`.
- `panels_size`: Panel size in cm. Use `""` for auto-estimated. Default: `""`.
- `margins`: Subplot margins (GMT `-M` syntax). Default: `"0.0"` (auto-tuned for titles/colorbars).
- `choro`: If `true` (default), use choropleth mode (one panel per attribute).
- `colorbar`: Colorbar placement — `false` (no bar), `true` (right side), `:bot` (bottom),
  or a GMT colorbar position string (e.g. `"JBC+o0/5p"`). Default: `true` when `choro=true`.
- `attribs`: Vector of attribute names. Make plots only for these attributes. Default: all attributes.
- `title`: Overall figure title.
- `titles`: Vector of panel title strings, or `"att"` to use attribute names as titles.
- `divlines`: Add dividing lines between panels. _i.e._ `divlines=pen`, where `pen` is a pen spefification.
- `show`: Display the result. Default: `true`.
- `kw`: Any additional keyword arguments are passed to `choropleth`.

### Examples
```julia
D = getdcw("PT,ES,FR", file=:ODS)
montage(D, titles="att")

montage(D, colorbar=:bot, title="Iberia + France")
```

See also: `choropleth`, `subplot`, `getattribs`
"""
function montage(D::Vector{<:GMTdataset}; kw...)
	d = KW(kw)
	_montage_choro(D, d)
end

function _montage_choro(D::Vector{<:GMTdataset}, d::Dict)
	grid      = pop!(d, :grid, (0,0))
	ps_val    = pop!(d, :panels_size, "")
	margins   = string(pop!(d, :margins, "0.0"))::String
	choro     = pop!(d, :choro, true)
	colorbar  = pop!(d, :colorbar, false)
	title     = string(pop!(d, :title, ""))::String
	titles    = pop!(d, :titles, String[])
	attribs   = pop!(d, :attribs, String[])::Vector{String}
	divlines  = pop!(d, :divlines, false)
	_show     = pop!(d, :show, true)::Bool

	atts = getattribs(D);
	deleteat!(atts, atts .== "Feature_ID")
	!isempty(attribs) && (atts = intersect(atts, attribs))
	n_atts = length(atts)
	n_atts == 0 && (@warn("No attributes to display"); return nothing)

	(isa(titles, StrSymb) && startswith(string(titles), "att")) && (titles = atts)

	_choro = (n_atts > 0 && choro == 1)
	(!_choro && length(D) < 2) && error("No reasonable datasets to display")
	cbar = (colorbar == false && _choro) ? true : colorbar
	nrows, ncols = _montage_grid_size(n_atts, grid)

	Vd = get(d, :Vd, 0)
	opt_R = parse_R(d, "")[1]
	d[:R] = (opt_R !== "") ? opt_R[4:end] : getregion(D)[1:4]
	parse_R(d, "", del=false)
	opt_J = parse_J(d, "", default="x?", map=false, del=true)[1]

	slash = ((isdigit(opt_J[end]) && ~startswith(opt_J, " -JXp")) || (occursin("Cyl_", opt_J) || occursin("Poly", opt_J)) || (startswith(opt_J, " -JU") && length(opt_J) > 4)) ? "/" : ""

	opt_B = parse_B(d, "", "")[1]
	(opt_B !== "") && (opt_B = replace(opt_B, "-B" => ""))
	_montage_setup_frame!(d, "", opt_B)
	(d[:B] == "+n") && (cbar == :bot) && (cbar = "JBC+o0/5p")
	(d[:B] == "+n") && (cbar == true) && (cbar = "JRM+o5p/0")

	d[:grid] = (nrows, ncols)
	_montage_adjust_margins!(d, titles, colorbar, cbar, margins)

	(title !== "") && (d[:title] = title)

	ps = max(3, min(8, 18 / max(nrows, ncols)))
	dvl = _montage_divlines!(d, divlines)
	if ps_val == "" || ps_val === nothing
		width, height = estimate_plot_size(D, colorbar == false ? false : colorbar, isempty(titles) ? "" : "Bla", nothing, d[:B] != "+n")
		d[:Fs] = string(ps,"/", round(height/width*ps, digits=2), dvl)
	else
		d[:Fs] = string(ps,dvl)
	end

	subplot("", false, d)

	d = CTRL.pocket_d[1]
	d[:J] = (opt_J == "x?") ? (isgeog(D) ? "q?" : "x?") : opt_J[4:end] * slash * "?"

	for k = 1:n_atts
		panel_title = (!isempty(titles) && k <= length(titles)) ? titles[k] : nothing
		choropleth(D, atts[k]; panel=k, title=panel_title, colorbar=(colorbar == false ? false : cbar), Vd=Vd, d...)
	end
	subplot(_show ? :show : :end)

	return nothing
end

# ----------------------------------------------------------------------------------------------------------
function _montage_grid_size(n::Int, grid)::Tuple{Int,Int}
	if grid == (0,0) || grid === nothing
		ncols = ceil(Int, sqrt(n))
		nrows = ceil(Int, n / ncols)
	else
		nrows, ncols = grid
		(nrows == 0 || (isa(nrows, AbstractFloat) && isnan(nrows))) && (nrows = ceil(Int, n / ncols))
		(ncols == 0 || (isa(ncols, AbstractFloat) && isnan(ncols))) && (ncols = ceil(Int, n / nrows))
	end
	return Int(nrows), Int(ncols)
end

# ----------------------------------------------------------------------------------------------------------
function estimate_plot_size(D, cbar, title, proj, has_B, kw...)
	# Estimate plot size of a single panel
	fname = TMPDIR_USR.dir * "/" * "GMTjl_" * TMPDIR_USR.username * TMPDIR_USR.pid_suffix * ".png"
	(cbar != false) && makecpt(C=:jet)		# Just a tinny CPT to get to the dimensions
	has_B && (cbar == :bot) && (cbar = "JBC+o0/25p")	# Add space for baddly accounted colorbar position
	plot(D; dpi=50, title=title, colorbar=cbar, J=proj, savefig=fname, kw...)
	dims = getsize(fname)
	return dims
end

# ----------------------------------------------------------------------------------------------------------
"""
    subplot_panel_sizes(aspect_ratios::Matrix{<:Real}; total_width::Real=20.0) -> (widths, heights)

Compute optimal column widths and row heights for a subplot grid, given the aspect ratios
(width/height) of each panel's content.

Given images with different aspect ratios `a[i,j]` in an R×C grid, find column widths
`w_1,...,w_C` and row heights `h_1,...,h_R` such that `w_j / h_i ≈ a[i,j]` for all panels.
Column widths can differ from each other but are the same across all rows. Row heights can
differ from each other but are the same across all columns.

The solution minimizes `Σ (log(w_j/h_i) - log(a[i,j]))²` via the additive two-way
decomposition of `log(a[i,j])`:
- `w_j ∝ exp(mean_i(log(a[i,j])))` — geometric mean of aspect ratios in column j
- `h_i ∝ exp(-mean_j(log(a[i,j])))` — inverse geometric mean of aspect ratios in row i

### Arguments
- `aspect_ratios`: R×C matrix where `a[i,j] = image_width / image_height` for panel (i,j).
  Use `NaN` for empty panels.
- `total_width`: desired total width (sum of all column widths) in cm. Default: 20.

### Returns
- `widths`:  Vector of C column widths (sum = `total_width`)
- `heights`: Vector of R row heights

The output can be passed directly to `subplot` via `panels_size=(Tuple(widths), Tuple(heights))`.

### Example
```julia
# 2×3 grid: landscape, square, wide / portrait, portrait, slightly wide
a = [1.5 1.0 2.0;
     0.8 0.7 1.2]
w, h = subplot_panel_sizes(a, total_width=24.0)
# w ≈ [7.1, 5.4, 11.5]  (wide images get wider columns)
# h ≈ [5.1, 7.5]         (portrait row gets taller)

# Use with subplot:
subplot(grid=(2,3), panels_size=(Tuple(w), Tuple(h)))
```
"""
function subplot_panel_sizes(aspect_ratios::Matrix{<:Real}; total_width::Real=20.0)
	R, C = size(aspect_ratios)

	# Handle NaN (empty panels) by replacing with row/column-aware medians
	a = copy(Float64.(aspect_ratios))
	_fill_nans_ar!(a)

	L = log.(a)

	# Two-way additive decomposition in log-space (optimal least-squares solution)
	col_means = vec(sum(L, dims=1) ./ R)   # mean over rows for each column j
	row_means = vec(sum(L, dims=2) ./ C)   # mean over columns for each row i

	# Column widths ∝ geometric mean of aspect ratios in that column
	w = exp.(col_means)
	w .*= total_width / sum(w)

	# Row heights: h_i = exp(mean(log(w)) - row_mean_i)
	mean_log_w = sum(log.(w)) / C
	h = [exp(mean_log_w - row_means[i]) for i in 1:R]

	return round.(w, digits=2), round.(h, digits=2)
end

# ----------------------------------------------------------------------------------------------------------
"""
    subplot_panel_sizes(GI::Vector; ncols::Int=0, total_width::Real=20.0) -> (widths, heights)

Compute optimal panel sizes from a vector of GMTgrid/GMTimage objects.

The aspect ratio of each element is computed from its spatial extent (`range` field).
For geographic data (`geog == 1`), a cos(latitude) correction is applied.

### Arguments
- `GI`: vector of GMTgrid or GMTimage objects. `nothing` entries mark empty panels.
- `ncols`: number of columns. Default: auto (≈ square grid).
- `total_width`: desired total width in cm. Default: 20.

### Example
```julia
G1 = gmtread("@earth_relief_10m", region=(-10,10,30,50))
G2 = gmtread("@earth_relief_10m", region=(100,160,-40,0))
G3 = gmtread("@earth_relief_10m", region=(-80,-60,-10,10))
w, h = subplot_panel_sizes([G1, G2, G3], ncols=3)
```
"""
function subplot_panel_sizes(GI::Vector; ncols::Int=0, total_width::Real=20.0)
	n = length(GI)
	(ncols <= 0) && (ncols = ceil(Int, sqrt(n)))
	nrows = ceil(Int, n / ncols)

	a = fill(NaN, nrows, ncols)
	for k in 1:n
		GI[k] === nothing && continue
		i = (k - 1) ÷ ncols + 1
		j = (k - 1) % ncols + 1
		W, H = getsize(GI[k])			# width (columns) and height (rows)
		a[i, j] = W / H
	end
	return subplot_panel_sizes(a; total_width=total_width)
end

# ----------------------------------------------------------------------------------------------------------
"""Fill NaN entries with the median of available values in the same row/col, or the global median."""
function _fill_nans_ar!(a::Matrix{Float64})
	R, C = size(a)
	vals = filter(!isnan, a)
	global_med = isempty(vals) ? 1.0 : median(vals)
	for j in 1:C, i in 1:R
		isnan(a[i, j]) || continue
		row_vals = filter(!isnan, a[i, :])
		col_vals = filter(!isnan, a[:, j])
		if !isempty(row_vals)
			a[i, j] = median(row_vals)
		elseif !isempty(col_vals)
			a[i, j] = median(col_vals)
		else
			a[i, j] = global_med
		end
	end
end
