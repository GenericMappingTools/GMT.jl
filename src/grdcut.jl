"""
	grdcut(cmd0::String="", arg1=[], kwargs...)

Produce a new outgrid which is a subregion of ingrid. The subregion is specified with
``limits`` (the -R); the specified range must not exceed the range of ingrid (but see ``extend``).

Parameters
----------

- **E** | **rowlice** | **colslice** :: [Type => Number]

    Extract a vertical slice going along the x-column coord or along the y-row coord.
- **F** | **clip** | **cutline** :: [Type => Str | GMTdaset | Mx2 array | NamedTuple]	`Arg = array|fname[+c] | (polygon=Array|Str, crop2cutline=Bool, invert=Bool)`

    Specify a closed polygon (either a file or a dataset). All grid nodes outside the
    polygon will be set to NaN.
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdcut(....) form.
- **img** | **usegdal** | **gdal** :: [Type => Any]

    Force the cut operation to be done by GDAL. Works for images where GMT fails or even crash.
- $(_opt_J)
- **N** | **extend** :: [Type => Str or []]

    Allow grid to be extended if new region exceeds existing boundaries. Append nodata value
    to initialize nodes outside current region [Default is NaN].
- $(_opt_R)
- **S** | **circ_subregion** :: [Type => Str]    ``Arg = [n]lon/lat/radius[unit]``

    Specify an origin and radius; append a distance unit and we determine the corresponding
    rectangular region so that all grid nodes on or inside the circle are contained in the subset.
- $(opt_V)
- **Z** | **range** :: [Type => Str]       ``Arg = [n|N |r][min/max]``

    Determine a new rectangular region so that all nodes outside this region are also outside
    the given z-range.
- $(_opt_f)

To see the full documentation type: ``@? grdcut``
"""
grdcut(cmd0::String; kwargs...) = grdcut_helper(cmd0, nothing; kwargs...)
grdcut(arg1; kwargs...)         = grdcut_helper("", arg1; kwargs...)
grdcut(; kwargs...)             = grdcut_helper("", nothing; kwargs...)		# To allow grdcut(data=..., ...)
function grdcut_helper(cmd0::String, arg1; kwargs...)
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	grdcut_helper(wrapGrids(cmd0, arg1), d)
end

# ---------------------------------------------------------------------------------------------------
function grdcut_helper(w::wrapGrids, d::Dict{Symbol, Any})::Union{Nothing, GMTgrid, GMTimage, String}
	cmd0, arg1 = unwrapGrids(w)

	arg2 = nothing
	cmd::String, opt_R::String = parse_R(d, "")
    cmd, = parse_common_opts(d, cmd, [:V_params :f])
    opt_J, = parse_J(d, "")
    (!startswith(opt_J, " -JX")) && (cmd *= opt_J)
	cmd = parse_these_opts(cmd, d, [[:D :dryrun], [:E], [:N :extend], [:S :circ_subregion], [:Z :range]])
	!contains(cmd, " -E") && (((val = find_in_dict(d, [:rowslice])[1]) !== nothing) && (cmd *= " -Ey$val"))
	!contains(cmd, " -E") && (((val = find_in_dict(d, [:colslice])[1]) !== nothing) && (cmd *= " -Ex$val"))
	opt_G = parse_G(d, "")[1]
	outname = (opt_G != "") ? opt_G[4:end] : ""
	cmd *= opt_G
	cmd, args, n, = add_opt(d, cmd, "F", [:F :clip :cutline], :polygon, Array{Any,1}([arg1, arg2]),
	                        (crop2cutline="_+c", invert="_+i"))
	(!contains(cmd, "-F") && opt_R == "") && error("Must provide the cutting limits. Either 'region' or 'clip'")
	if (n > 0)  arg1, arg2 = args[:]  end
	(SHOW_KWARGS[]) && return print_kwarg_opts([:img :usegdal :gdal], "Any")		# Just print the options

	# Images in file or any file but with a gdal request are read-and-cut but GDAL
	if (cmd0 != "" && (guess_T_from_ext(cmd0) == " -Ti" || (find_in_dict(d, [:usegdal :gdal])[1]) !== nothing))
		(dbg_print_cmd(d, cmd) !== nothing) && return "grdcut $cmd0 " * cmd		# Vd=2 cause this return	# FORCES RECOMPILE plot()
		t = split(scan_opt(cmd, "-R"), '/')
		opts = ["-projwin", t[1], t[4], t[2], t[3]]		# -projwin <ulx> <uly> <lrx> <lry>
		R = cut_with_gdal(cmd0, opts, outname)		# FORCES RECOMPILE plot()
	else
		# If only cut, call crop directly
		do_crop_here = ((oJ = scan_opt(cmd, "-J")) != "" && in(oJ[1], "xXQq"))	# Try to catch cases where -J does not need to go via grdcut
		R = ((do_crop_here || cmd == opt_R) && (arg1 !== nothing && arg2 === nothing)) ? crop(arg1; R=opt_R2num(opt_R))[1] :
			common_grd(d, cmd0, cmd, "grdcut ", arg1, arg2)	# Finish build cmd and run it	# FORCES RECOMPILE plot()
	end
	(R !== nothing && ((prj = planets_prj4(cmd0)) != "")) && (R.proj4 = prj)	# Get cached (@moon_..., etc) planets proj4
	return R
end

function cut_with_gdal(fname::String, opts::Vector{<:AbstractString}, outname::String="")
	if (outname == "")
		gdaltranslate(fname, opts)	# Layout is "TRB" so all matrices are contrary to Julia order
	else
		gdaltranslate(fname, opts; dest=outname)
		return nothing				# Since it wrote a file so nothing to return
	end
end
