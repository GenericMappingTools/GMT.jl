"""
	project(cmd0::String="", arg1=nothing, kwargs...)

Project data onto lines or great circles, generate tracks, or translate coordinates.

Full option list at [`project`]($(GMTdoc)project.html)

Parameters
----------

- **C** | **origin** | **start_pt** :: [Type => list/tuple]    ``Arg = (x,y)``

    Sets the origin of the projection, in Definition 1 or 2.
    ($(GMTdoc)project.html#c)
- **A** | **azim** :: [Type => Number]    ``Arg = azimuth``

    Defines the azimuth of the projection (Definition 1).
    ($(GMTdoc)project.html#a)
- **E** | **end_pt** :: [Type => list/tuple]    ``Arg = (bx,by)``

    bx,by defines the end point of the projection path (Definition 2).
    ($(GMTdoc)project.html#e)
- **F** | **out_flags** :: [Type => Str]    ``Arg = xyzpqrs``

    Specify your desired output using any combination of xyzpqrs, in any order [Default is xyzpqrs].
    ($(GMTdoc)project.html#f)
- **G** | **step** | **small_circle**: [Type => Number or list/tuple--    ``Arg = dist[/colat][+h]``

    Generate mode. No input is read. Create (r, s, p) output points every dist units of p. See Q option.
    ($(GMTdoc)project.html#g)
- **L** | **length_control** :: [Type => Number or list/tuple]    ``Arg = [w|l_{min}/l_{max}]``

    Length controls. Project only those points whose p coordinate is within l\\_min < p < l\\_max.
    ($(GMTdoc)project.html#l)
- **N** | **flat_earth** :: [Type => Bool or []]

    Flat Earth. Make a Cartesian coordinate transformation in the plane. [Default uses spherical trigonometry.]
    ($(GMTdoc)project.html#n)
- **Q** | **km** :: [Type => Bool or []]

    Map type units.
    ($(GMTdoc)project.html#q)
- **S** | **sort** :: [Type => Bool or []]

    Sort the output into increasing p order. Useful when projecting random data into a sequential profile.
    ($(GMTdoc)project.html#s)
- **T** | **pole** :: [Type => list/tuple]    ``Arg = (px,py)``

    px,py sets the position of the rotation pole of the projection. (Definition 3).
    ($(GMTdoc)project.html#t)
- **W** | **width_control** :: [Type => list/tuple]    ``Arg = (w_{min},w_{max})``

    Width controls. Project only those points whose q coordinate is within w\\_min < q < w\\_max.
    ($(GMTdoc)project.html#w)

- $(GMT.opt_write)
- $(GMT.opt_append)
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
function project(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("project", cmd0, arg1)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:V_params :b :d :e :f :g :h :i :s :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :azim], [:C :origin :start_pt], [:E :end_pt], [:F :out_flags],
	                                 [:G :step :small_circle :no_input], [:L :length_control], [:N :flat_earth], [:Q :km], [:S :sort], [:T :pole],[:W :width_control]])

	if (!occursin("-G", cmd))
		cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)
	else
		cmd = write_data(d, cmd)                # Check if want save to file
	end
	common_grd(d, "project " * cmd, arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
project(arg1, cmd0::String=""; kw...) = project(cmd0, arg1; kw...)