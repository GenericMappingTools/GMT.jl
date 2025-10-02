"""
crop(arg::GItype; kw...)

Crop a subregion of a grid (GMTgrid) or a image (GMTimage).

The subregion is specified with the ``limits`` or ``region`` keyword; the specified range must not
exceed the range of the input.  This function differs from ``grdcut`` in the sense that it doesn't
call the GMT lib and works only on in-memory array (i.e., no disk files).

### Returns
A grid or an image, depending on the input type, plus two 1x2 matrices with the indices of the cropped zone.

## Example
	G = peaks();
	crop(G, region=(-2,2,-2,2))
"""
function crop(arg::GItype; kw...)
	d = KW(kw)
	opt_R = parse_R(d, "")[2]
	(opt_R == "") && error("Must provide the cropping limits")
	lims = opt_R2num(opt_R)
	# Must test that requested cropping limits fit inside array BB
	lims[1], lims[2] = max(lims[1], arg.range[1]), min(lims[2], arg.range[2])	# Avoid overflows in Region
	lims[3], lims[4] = max(lims[3], arg.range[3]), min(lims[4], arg.range[4])
	row_dim, col_dim = (arg.layout == "" || arg.layout[2] == 'C') ? (1,2) : (2,1)	# If RowMajor the array is disguised 

	function rearrange_ranges(pix_x, pix_y)
		# Rearrange the cropping limits if the layout is Rowmajor and/or Topdown
		if (arg.layout[1] == 'T')  pix_y = [size(arg, row_dim)-pix_y[2]+1, size(arg, row_dim)-pix_y[1]+1]	end
		if (arg.layout[2] == 'R')  pix_x, pix_y = pix_y, pix_x  end
		pix_x, pix_y
	end

	# So far we are not able to crop row-wise array disguised as a column-wise one. So resort to GDAL
	if (arg.layout != "" && arg.layout[2] == 'R')
		proj, wkt, epsg = deepcopy(arg.proj4), deepcopy(arg.wkt), copy(arg.epsg)	# Save these because gdaltranslate may f change them
		if (arg.registration == 0)
			inc_x2, inc_y2 = arg.inc[1]/2, arg.inc[2]/2
			G = gdaltranslate(arg, R=(lims[1]-inc_x2, lims[2]+inc_x2, lims[3]-inc_y2, lims[4]+inc_y2))
		else
			G = gdaltranslate(arg, R=opt_R[4:end])
		end
		G === nothing && return nothing, Int[], Int[]		# Happened with the colorzones!
		G.proj4, G.wkt, G.epsg = proj, wkt, epsg
		lims = G.range[1:4]					# Because the gdaltranslate above adjusted the input limits (opt_R)
		pix_x, pix_y = axes2pix([lims[1] lims[3]; lims[2] lims[4]], size(arg), [arg.x[1], arg.x[end]], [arg.y[1], arg.y[end]], arg.registration, arg.layout)
		pix_x, pix_y = rearrange_ranges(pix_x, pix_y)
		return G, pix_x, pix_y
	end

	pix_x, pix_y = axes2pix([lims[1] lims[3]; lims[2] lims[4]], size(arg), [arg.x[1], arg.x[end]], [arg.y[1], arg.y[end]], arg.registration, arg.layout)

	x, y = arg.x[pix_x[1]:pix_x[2]+arg.registration], arg.y[pix_y[1]:pix_y[2]+arg.registration]
	#x, y = arg.x[pix_x[1]:pix_x[2]], arg.y[pix_y[1]:pix_y[2]]
	if (arg.layout != "")  pix_x, pix_y = rearrange_ranges(pix_x, pix_y)  end
	cropped = (ndims(arg) == 2) ? arg[pix_y[1]:pix_y[2], pix_x[1]:pix_x[2]] : arg[pix_y[1]:pix_y[2], pix_x[1]:pix_x[2], :]
	range = copy(arg.range)
	range[1:4] = [x[1], x[end], y[1], y[end]]
	if (eltype(arg) <: AbstractFloat)
		zmin, zmax = extrema_nan(cropped)
		range[5:6] = [zmin, zmax]
	end
	out = isa(arg, GMTgrid) ?  mat2grid(cropped, arg) : mat2img(cropped, arg)
	out.x, out.y, out.range = x, y, range
	out, pix_x, pix_y
end

# ---------------------------------------------------------------------------------------------------
"""
    pix_x, pix_y = axes2pix(xy, dims, x, y, reg=0, layout::String="TC")

Convert axes coordinates to pixel/cell coordinates.

- `xy`: A Mx2 matrix with x & y coordinates in same units as those in the `x,y` vectors
- `x,y: should be the coordinate vectors of a GMTgrid or GMTimage types`
- `dims`: Tuple with the number of rows,columns as returned by size(GI)

Return two vectors of Int with the indices that map `xy` to `x` and `y`
"""
function axes2pix(xy, dims, x, y, reg=0, layout::String="TC")
	(numel(x) != 2 || numel(y) != 2) && error("x and y must be a two elements array or tuple.")
	row_dim, col_dim = (layout == "" || layout[2] == 'C') ? (1,2) : (2,1)	# If RowMajor the array is transposed 
	#row_dim, col_dim = 1,2
	one_or_zero = (reg == 0) ? 1.0 : 0.0
	slope = (dims[col_dim] - one_or_zero) / (x[end] - x[1]);	isnan(slope) && (slope = 1.0)	# Vertical slices of a cube
	pix_x = round.(Int, slope .* (xy[:,1] .- x[1]) .+ [1.0, one_or_zero])
	pix_x[1] < 1 && (pix_x[1] = 1)		# Happened in worldrectangular() when the grid x limits returned by gdalwarp were not suitable
	slope = (dims[row_dim] - one_or_zero) / (y[end] - y[1]);	isnan(slope) && (slope = 1.0)
	pix_y = round.(Int, slope .* (xy[:,2] .- y[1]) .+ [1.0, one_or_zero])

	#=
	inc_x = (x[end] - x[1]) / (dims[col_dim] - one_or_zero)
	inc_y = (y[end] - y[1]) / (dims[row_dim] - one_or_zero)
	if (reg == 0)
		pix_x = round.(Int, (xy[:,1] .- x[1]) / inc_x) .+ 1
		pix_y = round.(Int, (xy[:,2] .- y[1]) / inc_y) .+ 1
	else
		pix_x = floor.(Int, (xy[:,1] .- x[1]) / inc_x) .+ 1
		pix_y = floor.(Int, (xy[:,2] .- y[1]) / inc_y) .+ 1
	end
	pix_x[2] > dims[col_dim] && (pix_x[2] = dims[col_dim])		# Happens when x|y are equal to the xy limits
	pix_y[2] > dims[row_dim] && (pix_y[2] = dims[row_dim])
	=#
	pix_x[2] < pix_x[1] && (pix_x[2] = pix_x[1])		# May happen when only one cell and for not obvious reasons
	pix_y[2] < pix_y[1] && (pix_y[2] = pix_y[1])
	pix_x, pix_y
end

# ---------------------------------------------------------------------------------------------------
"""
    xc, yc = pix2axes(xy::Matrix{<:Int}, x, y)

Convert pixel/cell to axes coordinates

- `xy`: A Mx2 matrix with indices referring to the `x` and `y` vectors
- `x`, `y`: Vectors of monotonically and regular growing coordinates

Return two vectors of same type as that of x,y
"""
function pix2axes(xy::Matrix{<:Int}, x, y)
	xc = x[1] .+ (xy[:,1] .- 1) .* (x[2] - x[1])
	yc = y[1] .+ (xy[:,2] .- 1) .* (y[2] - y[1])
	xc, yc
end
