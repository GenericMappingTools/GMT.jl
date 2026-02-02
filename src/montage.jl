export montage

# This file was initially created by Claude and still needs to be worked on.

# ------------------------------------------------------------------------------------------
"""
    montage(images; kwargs...)

Display multiple images arranged in a grid using GMT's subplot.

### Arguments
- `images`: Vector of GMTimage/GMTgrid objects, filenames, or a 3D/4D array.

### Keywords
- `grid`: Tuple (nrows, ncols) specifying grid dimensions. Default: approximately square.
- `panels_size`: Size of each panel in cm, e.g. `5` or `(5, 4)`. Default: auto.
- `margin`: Margin between panels. Default: "0.1c"
- `title`: Overall figure title.
- `titles`: Vector of titles for each panel.
- `frame`: Frame setting for panels. Default: :none
- `indices`: Vector of indices selecting which images to display.
- `show`: Display the result. Default: true.

### Example
```julia
# From files
montage(["img1.png", "img2.png", "img3.png", "img4.png"], grid=(2,2))

# From GMTimage array with titles
imgs = [gmtread("img\$i.png") for i in 1:6]
montage(imgs, grid=(2,3), titles=["A","B","C","D","E","F"], panels_size=5)

# From 3D array
montage(rand(UInt8, 64, 64, 9), grid=(3,3), margin="0.2c")
```
"""
function montage(images; grid=nothing, panels_size=nothing, margin="-0.23c",
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

	(frame === nothing) && (d[:D] = true)	# No frames around panels
	(title !== nothing) && (d[:title] = title)

	ps = (panels_size !== nothing) ? panels_size : max(3, min(8, 18 / max(nrows, ncols)))
	d[:panels_size] = ps
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

# Calculate grid dimensions
# ----------------------------------------------------------------------------------------------------------
function _montage_grid_size(n, size)
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
