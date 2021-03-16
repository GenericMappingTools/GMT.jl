"""
	grdcut(cmd0::String="", arg1=[], kwargs...)

Produce a new outgrid file which is a subregion of ingrid. The subregion is specified with
``limits`` (the -R); the specified range must not exceed the range of ingrid (but see ``extend``).

Full option list at [`grdcut`]($(GMTdoc)grdcut.html)

Parameters
----------

- **G** | **outgrid** :: [Type => Str]

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

	length(kwargs) == 0 && return monolitic("grdcut", cmd0, arg1)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
    cmd, = parse_common_opts(d, "", [:R :V_params :f])
    opt_J, = parse_J(d, "")
    if (!startswith(opt_J, " -JX"))  cmd *= opt_J  end
	cmd = parse_these_opts(cmd, d, [[:G :outgrid], [:N :extend], [:S :circ_subregion], [:Z :z_subregion]])
	(show_kwargs[1]) && return print_kwarg_opts([:img :usegdal], "Any")		# Just print the options
	if (cmd0 != "" && ((find_in_dict(d, [:img :usegdal])[1]) !== nothing))
		t = split(scan_opt(cmd, "-R"), '/')
		opts = ["-projwin", t[1], t[4], t[2], t[3]]		# -projwin <ulx> <uly> <lrx> <lry>
		(cmd0[1] == '@') && (cmd0 = gmtwhich(cmd0)[1].text[1])	# A remote file
		ds = readgd(cmd0)
		new_ds = gdaltranslate(ds, opts)
		gd2gmt(new_ds)
	else
		common_grd(d, cmd0, cmd, "grdcut ", arg1)		# Finish build cmd and run it
	end
end

# ---------------------------------------------------------------------------------------------------
grdcut(arg1, cmd0::String=""; kw...) = grdcut(cmd0, arg1; kw...)