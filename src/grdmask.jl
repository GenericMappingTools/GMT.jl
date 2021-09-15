"""
	grdmask(cmd0::String="", arg1=nothing, kwargs...)

1. It reads one or more pathfiles that each define a closed polygon.
2. The pathfiles simply represent data point locations and the mask is set to the inside or outside
   value depending on whether a node is within a maximum distance from the nearest data point. 

Full option list at [`grdmask`]($(GMTdoc)grdmask.html)

Parameters
----------

- $(GMT.opt_R)
- $(GMT.opt_I)
    ($(GMTdoc)grdmask.html#i)
- **A** | **steps** | **straight_lines** :: [Type => Str | Number]		``Arg = m|p|x|y``

    If the input data are geographic then the sides in the polygons will be approximated by great circle arcs.
    When using this option sides will be regarded as straight lines.
    ($(GMTdoc)grdmask.html#a)
- **G** | **outgrid** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdmask(....) form.
    ($(GMTdoc)grdmask.html#g)
- **N** | **out_edge_in** :: [Type => Str | List]    ``Arg = [z|Z|p|P]values``

    Sets the out/edge/in that will be assigned to nodes that are outside the polygons, on the edge, or inside.
    Values can be any number, including the textstring NaN [Default is 0/0/1].
    ($(GMTdoc)grdmask.html#n)
- **S** | **search_radius** :: [Type => Str | List]    ``Arg = search_radius[unit] |xlim/ylim``

    Set nodes to inside, on edge, or outside depending on their distance to the nearest data point.
- $(GMT.opt_V)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_j)
- $(GMT.opt_n)
- $(GMT.opt_r)
- $(GMT.opt_x)
- $(GMT.opt_w)
- $(GMT.opt_swap_xy)
"""
function grdmask(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("grdmask", cmd0, arg1)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:I :R :V_params :a :e :f :g :j :n :yx :r :x :w])
	cmd  = parse_these_opts(cmd, d, [[:A :steps :straight_lines], [:G :outgrid],
	                                 [:N :out_edge_in], [:S :search_radius]])
	return common_grd(d, "grdmask " * cmd, arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdmask(arg1, cmd0::String=""; kw...) = grdmask(cmd0, arg1; kw...)
