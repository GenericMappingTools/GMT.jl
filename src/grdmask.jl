"""
	grdmask(cmd0::String="", arg1=nothing, kwargs...)

1. It reads one or more pathfiles that each define a closed polygon.
2. The pathfiles simply represent data point locations and the mask is set to the inside or outside
   value depending on whether a node is within a maximum distance from the nearest data point. 

   See full GMT (not the `GMT.jl` one) docs at [`grdmask`]($(GMTdoc)grdmask.html)

Parameters
----------

- $(_opt_R)
- $(opt_I)
- **A** | **steps** :: [Type => Str | Number]		``Arg = m|p|x|y``

    If the input data are geographic then the sides in the polygons will be approximated by great circle arcs.
    When using this option sides will be regarded as straight lines.
- **C** | **clobber** :: [Type => Str]		``Arg = f|l|o|u``

    Clobber mode: Selects the polygon whose z-value will determine the grid nodes.
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdmask(....) form.
- **N** | **out_edge_in** :: [Type => Str | List]    ``Arg = [z|Z|p|P]values``

    Sets the out/edge/in that will be assigned to nodes that are outside the polygons, on the edge, or inside.
    Values can be any number, including the textstring NaN [Default is 0/0/1].
- **S** | **search_radius** :: [Type => Str | List]    ``Arg = search_radius[unit] |xlim/ylim``

    Set nodes to inside, on edge, or outside depending on their distance to the nearest data point.
- $(opt_V)
- $(_opt_bi)
- $(_opt_di)
- $(opt_e)
- $(_opt_f)
- $(opt_g)
- $(_opt_h)
- $(_opt_i)
- $(opt_j)
- $(opt_n)
- $(opt_r)
- $(opt_x)
- $(opt_w)
- $(opt_swap_xy)

To see the full documentation type: ``@? grdmask``
"""
grdmask(cmd0::String; kwargs...) = grdmask_helper(cmd0, nothing; kwargs...)
grdmask(arg1; kwargs...)         = grdmask_helper("", arg1; kwargs...)

# ---------------------------------------------------------------------------------------------------
function grdmask_helper(cmd0::String, arg1; kwargs...)

	d = init_module(false, kwargs...)[1]	    	# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :a :e :f :g :j :n :yx :x :w])
	cmd  = parse_these_opts(cmd, d, [[:A :steps :straight_lines], [:C :clober], [:N :out_edge_in], [:S :search_radius]])
	if (cmd0 != "")
		try
			arg1 = gmtread(cmd0)
		catch
			error("Failed to automatically load the input file. You must do it manually and pass it as numeric.")
		end
	end
	common_grd(d, "grdmask " * cmd, arg1)           # Finish build cmd and run it
end
