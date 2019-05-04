"""
	gmtspatial(cmd0::String="", arg1=nothing, kwargs...)

Geospatial operations on points, lines and polygons.

Full option list at [`gmtspatial`](http://gmt.soest.hawaii.edu/doc/latest/gmtspatial.html)

Parameters
----------

- **A** : **nn** : **nearest_neighbor** : -- Str --     Flags = [amin_dist][unit]

    Perform spatial nearest neighbor (NN) analysis: Determine the nearest neighbor of each point
    and report the NN distances and the point IDs involved in each pair.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/gmtspatial.html#a)
- **C** : **clip** : -- Bool or [] --

    Clips polygons to the map region, including map boundary to the polygon as needed. The result is a closed polygon.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/gmtspatial.html#C)
- **D** : **duplicates** : -- Str --   Flags = [+ffile][+aamax][+ddmax][+c|Ccmax][+sfact]

    Check for duplicates among the input lines or polygons, or, if file is given via +f, check if the
    input features already exist among the features in file.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/gmtspatial.html#d)
- **E** : **handedness** : -- Str --   Flags = +|-

    Reset the handedness of all polygons to match the given + (counter-clockwise) or - (clockwise). Implies Q+
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/gmtspatial.html#E)
- **F** : **force_polygons** : -- Str or [] --   Flags = [l]

    Force input data to become polygons on output, i.e., close them explicitly if not already closed.
    Optionally, append l to force line geometry.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/gmtspatial.html#f)
- **I** : **intersections** : -- Str or [] --   Flags = [e|i]

    Determine the intersection locations between all pairs of polygons.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/gmtspatial.html#i)
- **N** : **in_polyg** : -- Str --      Flags = pfile[+a][+pstart][+r][+z]

    Determine if one (or all, with +a) points of each feature in the input data are inside any of
    the polygons given in the pfile.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/gmtspatial.html#n)
- **Q** : **area** or **length** : -- Str --      Flags = [[-|+]unit][+cmin[/max]][+h][+l][+p][+s[a|d]]

    Measure the area of all polygons or length of line segments.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/gmtspatial.html#q)
- $(GMT.opt_R)
- **S** : **polyg_process** : -- Int --      Flags = h|i|j|s|u

    Spatial processing of polygons.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/gmtspatial.html#s)
- **T** : **truncate** : -- Str or [] --     Flags = [clippolygon]

    Truncate polygons against the specified polygon given, possibly resulting in open polygons.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/gmtspatial.html#t)
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

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :b :d :e :g :h :i :o :yx])
	cmd = parse_these_opts(cmd, d, [[:A :nn :nearest_neighbor], [:C :clip], [:D :duplicates], [:E :handedness],
				[:F :force_polygons], [:I :intersections], [:N :in_polyg], [:Q :area :length],
				[:S :polyg_process], [:T :truncate]])

	common_grd(d, cmd0, cmd, "gmtspatial ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtspatial(arg1, cmd0::String=""; kw...) = gmtspatial(cmd0, arg1; kw...)