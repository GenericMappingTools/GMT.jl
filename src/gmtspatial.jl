"""
	gmtspatial(cmd0::String="", arg1=[], kwargs...)

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
- **Q** : **area_or_length** : -- Str --      Flags = [[-|+]unit][+cmin[/max]][+h][+l][+p][+s[a|d]]

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
function gmtspatial(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("gmtspatial", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)

	cmd, = parse_R("", d)
	cmd = parse_V_params(cmd, d)
	cmd, = parse_b(cmd, d)
	cmd, = parse_d(cmd, d)
	cmd, = parse_e(cmd, d)
	cmd, = parse_g(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd, = parse_o(cmd, d)
	cmd, = parse_swap_xy(cmd, d)

	cmd = add_opt(cmd, 'A', d, [:A :nn :nearest_neighbor])
	cmd = add_opt(cmd, 'C', d, [:C :clip])
	cmd = add_opt(cmd, 'D', d, [:D :duplicates])
	cmd = add_opt(cmd, 'E', d, [:E :handedness])
	cmd = add_opt(cmd, 'F', d, [:F :force_polygons])
	cmd = add_opt(cmd, 'I', d, [:I :intersections])
	cmd = add_opt(cmd, 'N', d, [:N :in_polyg])
	cmd = add_opt(cmd, 'Q', d, [:Q :area_or_length])
	cmd = add_opt(cmd, 'S', d, [:S :polyg_process])
	cmd = add_opt(cmd, 'T', d, [:T :truncate])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "gmtspatial", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtspatial(arg1=[], cmd0::String=""; kw...) = gmtspatial(cmd0, arg1; kw...)