"""
	grdlandmask(cmd0::String="", arg1=nothing, kwargs...)

Reads the selected shoreline database and uses that information to decide which nodes in the
specified grid are over land or over water.

Full option list at [`grdlandmask`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html)

Parameters
----------

- $(GMT.opt_R)
- **I** : **inc** : -- Str or Number --

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html#i)
- **A** : **area** : -- Str or Number --

    Features with an area smaller than min_area in km^2 or of
    hierarchical level that is lower than min_level or higher than
    max_level will not be plotted.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html#a)
- **D** : **res** : **resolution** : -- Str --

    Selects the resolution of the data set to use ((f)ull, (h)igh, (i)ntermediate, (l)ow, and (c)rude).
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html#d)
- **E** : **bordervalues** : -- Str or List --    Flags = cborder/lborder/iborder/pborder or bordervalue

    Nodes that fall exactly on a polygon boundary should be considered to be outside the polygon
    [Default considers them to be inside].
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html#e)
- **G** : **outgrid** : -- Str --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdlandmask(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html#g)
- **N** : **mask_geog** : -- Str or List --    Flags = wet/dry or ocean/land/lake/island/pond

    Sets the values that will be assigned to nodes. Values can be any number, including the textstring NaN
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdlandmask.html#n)
- $(GMT.opt_V)
- $(GMT.opt_r)
- $(GMT.opt_x)
"""
function grdlandmask(cmd0::String=""; kwargs...)

	length(kwargs) == 0 && return monolitic("grdlandmask", cmd0, nothing)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :r :x])
	cmd = parse_these_opts(cmd, d, [[:A :area], [:D :res :resolution], [:E :bordervalues], [:I :inc],
				[:G :outgrid], [:N :mask_geog]])

	return common_grd(d, "grdlandmask " * cmd, nothing)		# Finish build cmd and run it
end