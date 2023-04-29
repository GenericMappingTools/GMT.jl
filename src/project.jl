"""
	project(cmd0::String="", arg1=nothing, kwargs...)

Project data onto lines or great circles, generate tracks, or translate coordinates.

See full GMT (not the `GMT.jl` one) docs at [`project`]($(GMTdoc)project.html)

Parameters
----------

- **C** | **origin** | **center** :: [Type => list/tuple]    ``Arg = (x,y)``

    Sets the origin of the projection, in Definition 1 or 2.
- **A** | **azim** | **azimuth** :: [Type => Number]    ``Arg = azimuth``

    Defines the azimuth of the projection (Definition 1).
- **E** | **end_pt** | **endpoint** :: [Type => list/tuple]    ``Arg = (bx,by)``

    bx,by defines the end point of the projection path (Definition 2).
- **F** | **outvars** :: [Type => Str]    ``Arg = xyzpqrs``

    Specify your desired output using any combination of xyzpqrs, in any order [Default is xyzpqrs].
- **G** | **step** | **generate** :: [Type => Number or list/tuple--    ``Arg = dist[/colat][+h]``

    Generate mode. No input is read. Create (r, s, p) output points every dist units of p. See Q option.
- **L** | **length** :: [Type => Number or list/tuple]    ``Arg = [w|l_{min}/l_{max}]``

    Length controls. Project only those points whose p coordinate is within l\\_min < p < l\\_max.
- **N** | **flat_earth** :: [Type => Bool or []]

    Flat Earth. Make a Cartesian coordinate transformation in the plane. [Default uses spherical trigonometry.]
- **Q** | **km** :: [Type => Bool or []]

    Map type units.
- **S** | **sort** :: [Type => Bool or []]

    Sort the output into increasing p order. Useful when projecting random data into a sequential profile.
- **T** | **pole** :: [Type => list/tuple]    ``Arg = (px,py)``

    px,py sets the position of the rotation pole of the projection. (Definition 3).
- **W** | **width** :: [Type => list/tuple]    ``Arg = (w_{min},w_{max})``

    Width controls. Project only those points whose q coordinate is within w\\_min < q < w\\_max.
- **Z** | **ellipse** :: [Type => Number | Tuple | String]    ``Arg = major/minor/azimuth[+e|n]``

    Make ellipse with major and minor axes given in km (unless **N** is given for a Cartesian ellipse) and the
    azimuth of the major axis in degrees; used in conjunction with **origin** (sets its center) and **step**
    (sets the distance increment).

- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_V)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT._opt_f)
- $(GMT.opt_g)
- $(GMT._opt_h)
- $(GMT._opt_i)
- $(GMT.opt_o)
- $(GMT.opt_s)
- $(GMT.opt_swap_xy)

To see the full documentation type: ``@? project``
"""
function project(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:V_params :b :d :e :f :g :h :i :o :s :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :azim], [:C :origin :startpoint :start_pt], [:E :endpoint :end_pt],
                                     [:F :outvars :out_flags], [:G :step :generate], [:L :length], [:N :flat_earth], [:Q :km], [:S :sort], [:T :pole], [:W :width], [:Z :ellipse]])

	if (!occursin("-G", cmd)) cmd, _, arg1 = find_data(d, cmd0, cmd, arg1)
	else                      cmd = write_data(d, cmd)      # Check if want save to file
	end
	common_grd(d, "project " * cmd, arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
project(arg1; kw...) = project("", arg1; kw...)