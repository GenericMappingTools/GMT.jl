"""
	grdlandmask(cmd0::String="", arg1=nothing, kwargs...)

Reads the selected shoreline database and uses that information to decide which nodes in the
specified grid are over land or over water.

Full option list at [`grdlandmask`]($(GMTdoc)grdlandmask.html)

Parameters
----------

- $(GMT.opt_R)
- **I** | **inc** :: [Type => Str | Number]

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    ($(GMTdoc)grdlandmask.html#i)
- **A** | **area** :: [Type => Str | Number]

    Features with an area smaller than min_area in km^2 or of
    hierarchical level that is lower than min_level or higher than
    max_level will not be plotted.
    ($(GMTdoc)grdlandmask.html#a)
- **D** | **res** | **resolution** :: [Type => Str]

    Selects the resolution of the data set to use ((f)ull, (h)igh, (i)ntermediate, (l)ow, and (c)rude).
    ($(GMTdoc)grdlandmask.html#d)
- **E** | **bordervalues** :: [Type => Str | List]    ``Arg = cborder/lborder/iborder/pborder or bordervalue``

    Nodes that fall exactly on a polygon boundary should be considered to be outside the polygon
    [Default considers them to be inside].
    ($(GMTdoc)grdlandmask.html#e)
- **G** | **outgrid** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdlandmask(....) form.
    ($(GMTdoc)grdlandmask.html#g)
- **N** | **mask_geog** :: [Type => Str | List]    ``Arg = wet/dry or ocean/land/lake/island/pond``

    Sets the values that will be assigned to nodes. Values can be any number, including the textstring NaN
    ($(GMTdoc)grdlandmask.html#n)
- $(GMT.opt_V)
- $(GMT.opt_r)
- $(GMT.opt_x)
"""
function grdlandmask(cmd0::String=""; kwargs...)

	length(kwargs) == 0 && return monolitic("grdlandmask", cmd0, nothing)

	d = KW(kwargs)
	help_show_options(d)			# Check if user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:R :V_params :r :x])
	cmd  = parse_these_opts(cmd, d, [[:A :area], [:D :res :resolution], [:E :bordervalues], [:I :inc],
	                                 [:G :outgrid], [:N :mask_geog]])
	return common_grd(d, "grdlandmask " * cmd, nothing)		# Finish build cmd and run it
end