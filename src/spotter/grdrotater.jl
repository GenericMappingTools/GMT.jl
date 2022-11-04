"""
	grdrotater(cmd0::String="", arg1=nothing; kwargs...)

Takes a geographical grid and reconstructs it given total reconstruction rotations.

Full option list at [`grdrotater`]($(GMTdoc)grdrotater.html)

Parameters
----------

- **A** | **rot_region** :: [Type => Str | Tuple | Vec]

    Specify directly the region of the rotated grid.
    ($(GMTdoc)grdrotater.html#a)
- **D** | **rot_outline** :: [Type => Bool or Str]	``Arg = true | filename``

    Name of the grid polygon outline file. This represents the outline of the grid reconstructed to the specified time.
    ($(GMTdoc)grdrotater.html#d)
- **F** | **rot_polyg** | **rot_polygon** :: [Type => Str | GMTdaset | Mx2 array]	``Arg = filename | dataset)``

    Specify a multisegment closed polygon file that describes the inside area of the grid that should be rotated.
    ($(GMTdoc)grdrotater.html#f)
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdrotater(....) form.
    ($(GMTdoc)grdrotater.html#g)
- $(GMT._opt_R)
- **T** | **ages** :: [Type => Str | Tuple]

    Sets the desired reconstruction times. For a single time append the desired time.
    ($(GMTdoc)grdrotater.html#t)
- $(GMT.opt_V)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT._opt_f)
- $(GMT.opt_g)
- $(GMT._opt_h)
- $(GMT.opt_n)
- $(GMT.opt_o)

### Example
```julia
G = grdmath("-R-5/5/-5/5 -I0.1 -fg X Y HYPOT");
tri = [-2.411 -1.629; -0.124 2.601; 2.201 -1.629; -2.410 -1.629];
Gr, tri_rot = grdrotater(G, rotation="-40.8/32.8/-12.9", rot_outline=true, rot_polygon=tri);
imshow(Gr, plot=(data=tri_rot,))
```
"""
grdrotater(arg1; kw...) = grdrotater("", arg1; kw...)
function grdrotater(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]			# Also checks if the user wants ONLY the HELP mode

	cmd = parse_common_opts(d, "", [:G :R :V_params :b :d :f :g :h :n :o])[1]
	cmd = parse_these_opts(cmd, d, [[:A :rot_region], [:E :rotation], [:S :rot_outline_only]])
	opt_D = add_opt(d, "", "D", [:D :rot_outline])
	(opt_D == "") && (cmd *= " -N")
	cmd *= opt_D

	cmd, _, arg1 = find_data(d, cmd0, cmd, arg1)	# Find how data was transmitted
	cmd, arg1, arg2 = arg_in_slot(d, cmd, [:F :rot_polyg :rot_polygon], Union{Matrix, GDtype}, arg1, nothing)
	(show_kwargs[1]) && print_kwarg_opts([:F :rot_polyg :rot_polygon], " Inside area for rotation [String or GMTdataset]")

	cmd, arg1, arg2, arg3 = arg_in_slot(d, cmd, [:T :ages], Union{Matrix, GDtype}, arg1, arg2, nothing)
	(show_kwargs[1]) && print_kwarg_opts([:T :ages], " Sets the desired reconstruction times. [Number, String or GMTdataset]")

	common_grd(d, cmd0, cmd, "grdrotater ", arg1, arg2, arg3)		# Finish build cmd and run it
end
