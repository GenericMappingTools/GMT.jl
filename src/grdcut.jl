"""
	grdcut(cmd0::String="", arg1=[], kwargs...)

Produce a new outgrid which is a subregion of ingrid. The subregion is specified with
``limits`` (the -R); the specified range must not exceed the range of ingrid (but see ``extend``).

Full option list at [`grdcut`]($(GMTdoc)grdcut.html)

Parameters
----------

- **F** | **clip** | **cutline** :: [Type => Str | GMTdaset | Mx2 array | NamedTuple]	`Arg = array|fname[+c] | (polygon=Array|Str, crop2cutline=Bool, invert=Bool)`

    Specify a closed polygon (either a file or a dataset). All grid nodes outside the
    polygon will be set to NaN (>= GMT6.2).
    ($(GMTdoc)grdcut.html#f)
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdcut(....) form.
    ($(GMTdoc)grdcut.html#g)
- **img** | **usegdal** | **gdal** :: [Type => Any]

    Force the cut operation to be done by GDAL. Works for images where GMT fails or even crash.
- $(GMT._opt_J)
- **N** | **extend** :: [Type => Str or []]

    Allow grid to be extended if new region exceeds existing boundaries. Append nodata value
    to initialize nodes outside current region [Default is NaN].
    ($(GMTdoc)grdcut.html#n)
- $(GMT._opt_R)
- **S** | **circ_subregion** :: [Type => Str]    ``Arg = [n]lon/lat/radius[unit]``

    Specify an origin and radius; append a distance unit and we determine the corresponding
    rectangular region so that all grid nodes on or inside the circle are contained in the subset.
    ($(GMTdoc)grdcut.html#s)
- $(GMT.opt_V)
- **Z** | **z_subregion** :: [Type => Str]       ``Arg = [n|N |r][min/max]``

    Determine a new rectangular region so that all nodes outside this region are also outside
    the given z-range.
    ($(GMTdoc)grdcut.html#z)
- $(GMT._opt_f)
"""
function grdcut(cmd0::String="", arg1=nothing; kwargs...)

	arg2 = nothing
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd::String, opt_R::String = parse_R(d, "")
    cmd, = parse_common_opts(d, cmd, [:V_params :f])
    opt_J, = parse_J(d, "")
    (!startswith(opt_J, " -JX")) && (cmd *= opt_J)
	cmd = parse_these_opts(cmd, d, [[:D :dryrun], [:N :extend], [:S :circ_subregion], [:Z :z_subregion]])
	opt_G = parse_G(d, "")[1]
	outname = (opt_G != "") ? opt_G[4:end] : ""
	cmd *= opt_G
	cmd, args, n, = add_opt(d, cmd, "F", [:F :clip :cutline], :polygon, Array{Any,1}([arg1, arg2]),
	                        (crop2cutline="_+c", invert="_+i"))
	(!contains(cmd, "-F") && opt_R == "") && error("Must provide the cutting limits. Either 'region' or 'clip'")
	if (n > 0)  arg1, arg2 = args[:]  end
	(show_kwargs[1]) && return print_kwarg_opts([:img :usegdal :gdal], "Any")		# Just print the options

	if (cmd0 != "" && (guess_T_from_ext(cmd0) == " -Ti" || (find_in_dict(d, [:usegdal :gdal])[1]) !== nothing))
		(dbg_print_cmd(d, cmd) !== nothing) && return "grdcut $cmd0 " * cmd		# Vd=2 cause this return
		t = split(scan_opt(cmd, "-R"), '/')
		opts = ["-projwin", t[1], t[4], t[2], t[3]]		# -projwin <ulx> <uly> <lrx> <lry>
		cut_with_gdal(cmd0, opts, outname)
	else
		common_grd(d, cmd0, cmd, "grdcut ", arg1, arg2)	# Finish build cmd and run it
	end
end

function cut_with_gdal(fname::String, opts::Vector{<:AbstractString}, outname::String="")
	if (outname == "")
		gdaltranslate(fname, opts)	# Layout is "TRB" so all matrices are contrary to Julia order
	else
		gdaltranslate(fname, opts; dest=outname)
		return nothing				# Since it wrote a file so nothing to return
	end
end

# ---------------------------------------------------------------------------------------------------
grdcut(arg1; kw...) = grdcut("", arg1; kw...)

# ---------------------------------------------------------------------------------------------------
"""
crop(arg::GItype; kw...)

Crop a subregion of a grid (GMTgrid) or a image (GMTimage). The subregion is specified with the
``limits`` or ``region`` keyword; the specified range must not exceed the range of the input.
This function differs from ``grdcut`` in the sense that it doesn't call the GMT lib and works only on
in-memory array (i.e., no disk files).

### Returns
A grid or an image, depending on the input type, plus two 1x2 matrices with the indices of the cropped zone.

## Example
	G = GMT.peaks();
	crop(G, region=(-2,2,-2,2))
"""
function crop(arg::GItype; kw...)
	d = KW(kw)
	_, opt_R = parse_R(d, "")
	(opt_R == "") && error("Must provide the cropping limits")
	lims = opt_R2num(opt_R)
	# Must test that requested cropping limits fit inside array BB
	lims[1], lims[2] = max(lims[1], arg.range[1]), min(lims[2], arg.range[2])	# Avoid overflows in Region
	lims[3], lims[4] = max(lims[3], arg.range[3]), min(lims[4], arg.range[4])
	row_dim, col_dim = (arg.layout == "" || arg.layout[2] == 'C') ? (1,2) : (2,1)	# If RowMajor the array is transposed 
	slope = (size(arg, col_dim) - 1) / (arg.x[end] - arg.x[1])
	pix_x = round.(Int, slope .* (lims[1:2] .- arg.x[1]) .+ 1)
	slope = (size(arg, row_dim) - 1) / (arg.y[end] - arg.y[1])
	pix_y = round.(Int, slope .* (lims[3:4] .- arg.y[1]) .+ 1)

	function rearrange_ranges(pix_x, pix_y)
		# Rearrange the cropping limits if the layout is Rowmajor and/or Topdown
		if (arg.layout[1] == 'T')  pix_y = [size(arg, row_dim)-pix_y[2]+1, size(arg, row_dim)-pix_y[1]+1]	end
		if (arg.layout[2] == 'R')  pix_x, pix_y = pix_y, pix_x  end
		pix_x, pix_y
	end

	x, y = arg.x[pix_x[1]:pix_x[2]+1], arg.y[pix_y[1]:pix_y[2]+1]
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
