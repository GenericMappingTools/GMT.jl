export montage

# ------------------------------------------------------------------------------------------
"""
    montage(images; grid=nothing, panels_size=nothing, margin="0.0", title=nothing,
            titles=nothing, frame=nothing, indices=nothing, show=true, noR=false, kw...)

Display multiple images or grids arranged in a grid layout using GMT's subplot machinery.
Panel sizes are automatically computed from the aspect ratios of the input images
(via `subplot_panel_sizes`) unless `panels_size` is given explicitly.

### Arguments
- `images`: Vector of GMTimage/GMTgrid objects or file name strings.

### Keywords
- `grid`: Tuple `(nrows, ncols)` specifying grid dimensions. Default: approximately square.
- `panels_size`: Panel size in cm — a scalar for square panels, a tuple `(w, h)`, or
  a pre-formatted string `"w1,w2,.../h1,h2,..."`. Default: auto from aspect ratios.
- `margin`: Gap between panels (GMT subplot margin syntax). Default: `"0.0"`.
- `title`: Overall figure title string.
- `titles`: Vector of strings with individual panel titles.
- `frame`: Frame style for panels. Use `"0"` for invisible frame outline, or a pen
  specification. Default: no frame (`-D`).
- `indices`: Vector of integer indices to select a subset of `images`.
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
function montage(images; grid=nothing, panels_size=nothing, margin="0.0",
                 title=nothing, titles=nothing, frame=nothing, indices=nothing,
                 show::Bool=true, noR::Bool=false, kw...)

	(indices !== nothing) && (images = images[indices])	# Apply indices selection
	((n = length(images)) == 0) && error("No images to display")
	nrows, ncols = _montage_grid_size(n, grid)		# Calculate grid dimensions

	d = KW(kw)
	d[:grid] = (nrows, ncols)
	d[:margin] = margin
	(frame == "0") ? (d[:par] = (MAP_FRAME_PEN="0",); d[:frame] = frame) :
	                 ((frame !== nothing) && (d[:B] ="0"; d[:par] = (:MAP_FRAME_PEN,parse_pen(frame))))

	(frame === nothing) && (d[:D] = true; d[:B] ="+n")	# No frames around panels and no space for the unexisting annots/ticks
	(title !== nothing) && (d[:title] = title)

	if (panels_size === nothing)
		if (panels_size == :squares)
			d[:panels_size] = max(3, min(8, 18 / max(nrows, ncols)))
		else
			widths, heights = subplot_panel_sizes(images, ncols=ncols)
			d[:panels_size] = arg2str(widths,',') * "/" * arg2str(heights,',')	# ((Tuple(widths), Tuple(heights))
		end
	else
		d[:panels_size] = panels_size
	end

	Vd = get(d, :Vd, 0)				# Get the Vd option that will be consumed by subplot\

	subplot("", false, d)	# Create subplot (since we already have the Dict pass it directly)
	d = CTRL.pocket_d[1]			# Fetch options not consumed by subplot.

	# Plot each ... input
	d[:J] = "x?"
	k = 0;	n_inputs = length(images)
	for row in 1:nrows
		for col in 1:ncols
			((k += 1) > n_inputs) && break
			panel_title = (titles !== nothing && k <= length(titles)) ? titles[k] : nothing
			opt_R = isa(images[k], GItype) ? (noR ? "" : getR(images[k])) : ""
			viz(images[k]; panel=(row, col), title=panel_title, R=(opt_R !== "" ? opt_R : nothing), Vd=Vd, show=false, d...)
		end
	end
	subplot(show ? :show : :end)	# End subplot

	return nothing
end

# ----------------------------------------------------------------------------------------------------------
"""
    montage(D::Vector{<:GMTdataset}; grid=nothing, panels_size=nothing, margins=nothing,
            choro=true, colorbar=false, title="", titles=String[], show=true, kw...)

Display a multi-panel choropleth from vector polygon data. Each panel maps one numeric
attribute of `D` (obtained via `getattribs`). Panels are laid out in a subplot grid, each
drawn with `choropleth`.

### Arguments
- `D`: Vector of `GMTdataset` polygons with numeric attributes stored in `D[k].attrib`.

### Keywords
- `grid`: Tuple `(nrows, ncols)`. Default: approximately square for the number of attributes.
- `panels_size`: Panel size in cm. Default: auto-estimated from a trial plot.
- `margins`: Subplot margins (GMT `-M` syntax). Default: auto-tuned for titles/colorbars.
- `choro`: If `true` (default), use choropleth mode (one panel per attribute).
- `colorbar`: Colorbar placement — `false` (no bar), `true` (right side), `:bot` (bottom),
  or a GMT colorbar position string (e.g. `"JBC+o0/5p"`). Default: `true` when `choro=true`.
- `title`: Overall figure title.
- `titles`: Vector of panel title strings, or `"att"` to use attribute names as titles.
- `show`: Display the result. Default: `true`.

### Examples
```julia
D = getdcw("PT,ES,FR", file=:ODS)
montage(D, titles="att")

montage(D, colorbar=:bot, title="Iberia + France")
```

See also: `choropleth`, `subplot`, `getattribs`
"""
function montage(D::Vector{<:GMTdataset}; grid=nothing, panels_size=nothing, margins=nothing, choro=true,
                 colorbar::Union{Bool,Symbol,NamedTuple,String}=false, title="", titles=String[], show::Bool=true, kw...)
	atts = getattribs(D);	n_atts = length(atts)

	(isa(titles, StrSymb) && startswith(string(titles), "att")) && (titles = atts)

	_choro = (n_atts > 0 && choro == 1)
	(!_choro && length(D) < 2) && error("No reasonable datasets to display")
	cbar = (colorbar == false && _choro) ? true : colorbar			# Type unstable
	n_atts = 4
	nrows, ncols = _montage_grid_size(n_atts, grid)					# Calculate grid dimensions

	d = KW(kw)
	Vd = get(d, :Vd, 0)					# Get the Vd option that will be consumed by subplot
	opt_R = parse_R(d, "")[1]
	d[:R] = (opt_R !== "") ? opt_R[4:end] : getregion(D)[1:4]		# Prepare info so CTRL.limits is set in next call
	parse_R(d, "", del=false)
	opt_J = parse_J(d, "", default="x?", map=false, del=true)[1]	# Now that CTRL.limits is set, J=:guess works

	# We need to know if we have to add a "/?" or just a "?" to the opt_J
	slash = ((isdigit(opt_J[end]) && ~startswith(opt_J, " -JXp")) || (occursin("Cyl_", opt_J) || occursin("Poly", opt_J)) || (startswith(opt_J, " -JU") && length(opt_J) > 4)) ? "/" : ""

	opt_B = parse_B(d, "", "")[1]
	(opt_B !== "") && (opt_B = replace(opt_B, "-B" => ""))			# So that a multi-word -B can be rebuilt later
	(opt_B !== "") ? (d[:B] = opt_B) : (d[:B] = "+n"; d[:D] = true)
	(d[:B] == "+n") && (cbar == :bot) && (cbar = "JBC+o0/5p")		# Move the colorbar up a bit. It was too far from south axis
	(d[:B] == "+n") && (cbar == true) && (cbar = "JRM+o5p/0")		# Move the colorbar left a bit. It was too far from right axis

	d[:grid] = (nrows, ncols)
	dy = !isempty(titles) ? 0.5 : 0.0
	(cbar !== false) && (dy += 0.6)
	dx = (d[:B] != "+n") && (colorbar == true || colorbar == :right || (isa(colorbar, String) && contains(cbar, "RM"))) ? 0.90 : 0.38
	(margins === nothing && (dx != 0 || dy != 0)) && (d[:M] = "0.38c/$(dx)c/$(dy)c/0")	# No margins set, titles neead tweaks.
	(margins !== nothing) && (d[:M] = arg2str(margins))				# Margins option was set, use them
	d[:par] = (MAP_TITLE_OFFSET="0p", FONT_TITLE="auto,Helvetica,black")

	(title !== "") && (d[:title] = title)

	ps = max(3, min(8, 18 / max(nrows, ncols)))
	if (panels_size === nothing)
		width, height = estimate_plot_size(D, colorbar == false ? false : colorbar, isempty(titles) ? "" : "Bla", nothing, d[:B] != "+n", kw...)
		d[:Fs] = string(ps,"/", round(height/width*ps, digits=2), "+w0.5")
	else
		d[:Fs] = string(ps,"+w0.5")
	end

	subplot("", false, d)				# Create subplot (since we already have the Dict pass it directly)

	d = CTRL.pocket_d[1]				# Fetch options not consumed by subplot.
	d[:J] = (opt_J == "x?") ? (isgeog(D) ? "q?" : "x?") : opt_J[4:end] * slash * "?"

	for k = 1:n_atts
		panel_title = (!isempty(titles) && k <= length(titles)) ? titles[k] : nothing
		choropleth(D, atts[k]; panel=k, title=panel_title, colorbar=(colorbar == false ? false : cbar), Vd=Vd, d...)
	end
	subplot(show ? :show : :end)	# End subplot

	return nothing
end

# ----------------------------------------------------------------------------------------------------------
function _montage_grid_size(n, size)
	# Calculate grid dimension
	if size === nothing || all(x -> x === nothing || x == 0 || (isa(x, AbstractFloat) && isnan(x)), size)
		ncols = ceil(Int, sqrt(n))
		nrows = ceil(Int, n / ncols)
	else
		nrows, ncols = size
		(nrows == 0 || (isa(nrows, AbstractFloat) && isnan(nrows))) && (nrows = ceil(Int, n / ncols))
		(ncols == 0 || (isa(ncols, AbstractFloat) && isnan(ncols))) && (ncols = ceil(Int, n / nrows))
	end
	return Int(nrows), Int(ncols)
end

# ----------------------------------------------------------------------------------------------------------
function estimate_plot_size(D, cbar, title, proj, has_B, kw...)
	# Estimate plot size of a single panel
	fname = TMPDIR_USR.dir * "/" * "GMTjl__" * TMPDIR_USR.username * TMPDIR_USR.pid_suffix * ".png"
	(cbar != false) && makecpt(C=:jet)		# Just a tinny CPT to get to the dimensions
	has_B && (cbar == :bot) && (cbar = "JBC+o0/25p")	# Add space for baddly accounted colorbar position
	plot(D; dpi=50, title=title, colorbar=cbar, J=proj, savefig=fname, kw...)
	#dims = Int.(gmt("grdinfo -C " * fname)[9:10])
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
