"""
	gmtspatial(cmd0::String="", arg1=nothing, kwargs...)

Geospatial operations on points, lines and polygons.

Full option list at [`gmtspatial`]($(GMTdoc)gmtspatial.html)

Parameters
----------

- **A** | **nn** | **nearest_neighbor** :: [Type => Str]     `Arg = [amin_dist][unit]`

    Perform spatial nearest neighbor (NN) analysis: Determine the nearest neighbor of each point
    and report the NN distances and the point IDs involved in each pair.
    ($(GMTdoc)gmtspatial.html#a)
- **C** | **clip** :: [Type => Bool]

    Clips polygons to the map region, including map boundary to the polygon as needed. The result is a closed polygon.
    ($(GMTdoc)gmtspatial.html#c)
- **D** | **duplicates** :: [Type => Str]   `Arg = [+ffile][+aamax][+ddmax][+c|Ccmax][+sfact]`

    Check for duplicates among the input lines or polygons, or, if file is given via +f, check if the
    input features already exist among the features in file.
    ($(GMTdoc)gmtspatial.html#d)
- **E** | **handedness** :: [Type => Str]  `Arg = +|-`

    Reset the handedness of all polygons to match the given + (counter-clockwise) or - (clockwise). Implies Q+
    ($(GMTdoc)gmtspatial.html#e)
- **F** | **force_polygons** :: [Type => Str | []]   `Arg = [l]`

    Force input data to become polygons on output, i.e., close them explicitly if not already closed.
    Optionally, append l to force line geometry.
    ($(GMTdoc)gmtspatial.html#f)
- **I** | **intersections** :: [Type => Str | []]   `Arg = [e|i]`

    Determine the intersection locations between all pairs of polygons.
    ($(GMTdoc)gmtspatial.html#i)
- **N** | **in_polyg** :: [Type => Str]     `Arg = pfile[+a][+pstart][+r][+z]`

    Determine if one (or all, with +a) points of each feature in the input data are inside any of
    the polygons given in the pfile.
    ($(GMTdoc)gmtspatial.html#n)
- **Q** | **area** or **length** :: [Type => Str]      `Arg = [[-|+]unit][+cmin[/max]][+h][+l][+p][+s[a|d]]`

    Measure the area of all polygons or length of line segments.
    ($(GMTdoc)gmtspatial.html#q)
- $(GMT.opt_R)
- **S** | **polygons** :: [Type => Str]     `Arg = h|i|j|s|u`

    Spatial processing of polygons.
    ($(GMTdoc)gmtspatial.html#s)
- **T** | **truncate** :: [Type => Str | []]     `Arg = [clippolygon]`

    Truncate polygons against the specified polygon given, possibly resulting in open polygons.
    ($(GMTdoc)gmtspatial.html#t)
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_o)
- $(GMT.opt_swap_xy)
"""
function gmtspatial(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("gmtspatial", cmd0, arg1)

	d = KW(kwargs);     arg2 = nothing;     arg3 = nothing;     arg4 = nothing
	help_show_options(d)			# Check if user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:R :V_params :b :d :e :f :g :h :i :o :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :nn :nearest_neighbor], [:C :clip], [:E :handedness], [:F :force_polygons],
	                                 [:I :intersections], [:Q :area :length]])
	cmd = add_opt(d, cmd, "S", [:S :polygons :polyg_process], (buffer="+b", holes="_+h", dateline="_+s"))

	cmd, args, n, = add_opt(d, cmd, 'D', [:D :duplicates], :data, Array{Any,1}([arg1, arg2]), (amax="+a", dmax="+d", cmax="+c", Cmax="+c", fact="+s", ortho="_+p"))
	if (n > 0)
		arg1, arg2 = args[:];   cmd *= "+f"
	end
 
	cmd, args, n, = add_opt(d, cmd, 'N', [:N :in_polyg], :data, Array{Any,1}([arg1, arg2, arg3]), (all="_+a", start="+p", has_feature="_+r", add_IDs="_+z"))
	if (n > 0)  arg1, arg2, arg3 = args[:]  end

	cmd, args, n, = add_opt(d, cmd, 'T', [:T :truncate], :data, Array{Any,1}([arg1, arg2, arg3, arg4]), (x="",))
	if (n > 0)  arg1, arg2, arg3, arg4 = args[:]  end

	common_grd(d, cmd0, cmd, "gmtspatial ", arg1, arg2, arg3, arg4)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtspatial(arg1, cmd0::String=""; kw...) = gmtspatial(cmd0, arg1; kw...)