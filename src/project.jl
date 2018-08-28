"""
	project(cmd0::String="", arg1=[], kwargs...)

Project data onto lines or great circles, generate tracks, or translate coordinates.

Full option list at [`project`](http://gmt.soest.hawaii.edu/doc/latest/project.html)

Parameters
----------

- **C** : **origin** : -- Str or list --    Flags = cx/cy

    Sets the origin of the projection, in Definition 1 or 2.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/project.html#c)

- **A** : **azim** : -- Number --    Flags = azimuth

    Defines the azimuth of the projection (Definition 1).
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/project.html#a)
- **E** : **end_point** : -- Str or List --    Flags = bx/by

    bx/by defines the end point of the projection path (Definition 2).
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/project.html#e)
- **F** : **out_flags** : -- wStr --    Flags = xyzpqrs

    Specify your desired output using any combination of xyzpqrs, in any order [Default is xyzpqrs].
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/project.html#f)
- **G** : **no_input** : -- Str or Number --    Flags = dist[/colat][+h]

    Generate mode. No input is read. Create (r, s, p) output points every dist units of p. See Q option.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/project.html#g)
- **L** : **length_control** : -- Str or list --    Flags = [w|l_min/l_max]

    Length controls. Project only those points whose p coordinate is within l_min < p < l_max.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/project.html#l)
- **N** : **flat_earth** : -- Bool or [] --

    Flat Earth. Make a Cartesian coordinate transformation in the plane. [Default uses spherical trigonometry.]
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/project.html#n)
- **Q** : **units** : -- Bool or [] --

    Map type units.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/project.html#q)
- **S** : **sort** : -- Bool or [] --

    Sort the output into increasing p order. Useful when projecting random data into a sequential profile.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/project.html#s)
- **T** : **pole** : -- Str or list --    Flags = px/py

    px/py sets the position of the rotation pole of the projection. (Definition 3).
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/project.html#t)
- **W** : **width_control** : -- Str or list --    Flags = w_min/w_max

    Width controls. Project only those points whose q coordinate is within w_min < q < w_max.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/project.html#w)

- $(GMT.opt_V)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_s)
- $(GMT.opt_swap_xy)
"""
function project(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("project", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)

	cmd = parse_V_params("", d)
	cmd, = parse_b(cmd, d)
	cmd, = parse_d(cmd, d)
	cmd, = parse_e(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_g(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd, = parse_s(cmd, d)
	cmd, = parse_swap_xy(cmd, d)

	cmd = add_opt(cmd, 'A', d, [:A :azim])
	cmd = add_opt(cmd, 'C', d, [:C :origin])
	cmd = add_opt(cmd, 'E', d, [:E :end_point])
	cmd = add_opt(cmd, 'F', d, [:F :out_flags])
	cmd = add_opt(cmd, 'G', d, [:G :no_input])
	cmd = add_opt(cmd, 'L', d, [:L :length_control])
	cmd = add_opt(cmd, 'N', d, [:N :flat_earth])
	cmd = add_opt(cmd, 'Q', d, [:Q :units])
	cmd = add_opt(cmd, 'S', d, [:S :sort])
	cmd = add_opt(cmd, 'T', d, [:T :pole])
	cmd = add_opt(cmd, 'W', d, [:W :width_control])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "project", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
project(arg1=[], cmd0::String=""; kw...) = project(cmd0, arg1; kw...)