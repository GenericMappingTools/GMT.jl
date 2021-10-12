"""
	grdcut(cmd0::String="", arg1=[], kwargs...)

Produce a new outgrid file which is a subregion of ingrid. The subregion is specified with
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
- **img** | **usegdal** :: [Type => Any]

    Force the cut operation to be done by GDAL. Works for images where GMT fails or even crash.
- $(GMT.opt_J)
- **N** | **extend** :: [Type => Str or []]

    Allow grid to be extended if new region exceeds existing boundaries. Append nodata value
    to initialize nodes outside current region [Default is NaN].
    ($(GMTdoc)grdcut.html#n)
- $(GMT.opt_R)
- **S** | **circ_subregion** :: [Type => Str]    ``Arg = [n]lon/lat/radius[unit]``

    Specify an origin and radius; append a distance unit and we determine the corresponding
    rectangular region so that all grid nodes on or inside the circle are contained in the subset.
    ($(GMTdoc)grdcut.html#s)
- $(GMT.opt_V)
- **Z** | **z_subregion** :: [Type => Str]       ``Arg = [n|N |r][min/max]``

    Determine a new rectangular region so that all nodes outside this region are also outside
    the given z-range.
    ($(GMTdoc)grdcut.html#z)
- $(GMT.opt_f)
"""
function grdcut(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && contains(cmd0, " ") && return monolitic("grdcut", cmd0, arg1)

	arg2 = nothing
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, opt_R = parse_R(d, "")
	(opt_R == "") && error("Must provide the cutting limits (GMT option R)")
    cmd, = parse_common_opts(d, cmd, [:V_params :f])
    opt_J, = parse_J(d, "")
    (!startswith(opt_J, " -JX")) && (cmd *= opt_J)
	cmd = parse_these_opts(cmd, d, [[:D], [:N :extend], [:S :circ_subregion], [:Z :z_subregion]])
	opt_G = parse_G(d, "")[1]
	outname = (opt_G != "") ? opt_G[4:end] : ""
	cmd *= opt_G
	cmd, args, n, = add_opt(d, cmd, 'F', [:F :clip :cutline], :polygon, Array{Any,1}([arg1, arg2]),
	                        (crop2cutline="_+c", invert="_+i"))
	if (n > 0)  arg1, arg2 = args[:]  end
	(show_kwargs[1]) && return print_kwarg_opts([:img :usegdal], "Any")		# Just print the options

	if (cmd0 != "" && (guess_T_from_ext(cmd0) == " -Ti" || (find_in_dict(d, [:usegdal])[1]) !== nothing))
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
grdcut(arg1, cmd0::String=""; kw...) = grdcut(cmd0, arg1; kw...)