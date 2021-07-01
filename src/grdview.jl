"""
    grdview(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; kwargs...)

Reads a 2-D grid and produces a 3-D perspective plot by drawing a mesh, painting a
colored/grayshaded surface made up of polygons, or by scanline conversion of these polygons
to a raster image.

Full option list at [`grdview`]($(GMTdoc)grdview.html)

- $(GMT.opt_J)
- $(GMT.opt_Jz)
- $(GMT.opt_R)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **G** | **drapefile** :: [Type => Str | GMTgrid | a Tuple with 3 GMTgrid types]

    Drape the image in drapefile on top of the relief provided by relief_file.
    ($(GMTdoc)grdview.html#g)
- **I** | **shade** | **shading** | **intensity** :: [Type => Str | GMTgrid]		``Arg = GMTgrid | filename``

    Gives the name of a grid file or GMTgrid with intensities in the (-1,+1) range,
    or a grdgradient shading flags.
    ($(GMTdoc)grdview.html#i)
- **N** | **plane** :: [Type => Str | Int]		``Arg = (level [,fill])``

    Draws a plane at this z-level.
    ($(GMTdoc)grdview.html#n)
- $(GMT.opt_P)
- **Q** | **surftype** | **surf** :: [Type => Str | Int] ``Arg = mesh=Bool, surface=Bool, image=Bool, wterfall=(:rows|cols,[fill])``

    Specify **m** for mesh plot, **s** for surface, **i** for image.
    ($(GMTdoc)grdview.html#q)
- **S** | **smoothfactor** :: [Type => Number]

    Used to resample the contour lines at roughly every (gridbox_size/smoothfactor) interval..
    ($(GMTdoc)grdview.html#s)
- **T** | **tiles** | **no_interp** :: [Type => Str | NT]	``Arg = (skip|skip_nan=Bool, outlines=Bool|pen)``

    Plot image without any interpolation.
    ($(GMTdoc)grdview.html#t)
- **W** | **pens** | **pen** :: [Type => Str]	``Arg = (contour=Bool|pen, mesh=Bool|pen, facade=Bool|pen)``

    Draw contour, mesh or facade. Append pen attributes.
    ($(GMTdoc)grdview.html#w)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_f)
- $(GMT.opt_n)
- $(GMT.opt_p)
- $(GMT.opt_t)
"""
function grdview(cmd0::String="", arg1=nothing; first=true, kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("grdview", cmd0, arg1)
	arg2 = nothing;	arg3 = nothing;	arg4 = nothing;	arg5 = nothing;

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode
	common_insert_R!(d, O, cmd0, arg1)			# Set -R in 'd' out of grid/images (with coords) if limits was not used

	has_opt_B = (find_in_dict(d, [:B :frame :axis :axes], false)[1] !== nothing)
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "grdview", O, " -JX" * split(def_fig_size, '/')[1] * "/0")
	(!has_opt_B && (isa(arg1, GMTimage) && isimgsize(arg1) || CTRL.limits[1:4] == zeros(4)) && opt_B == def_fig_axes[1]) &&
		(cmd = replace(cmd, opt_B => ""))	# Dont plot axes for plain images if that was not required

	cmd, = parse_common_opts(d, cmd, [:UVXY :c :f :n :p :t :params], first)
	cmd  = add_opt(d, cmd, 'S', [:S :smooth])
	if ((val = find_in_dict(d, [:N :plane])[1]) !== nothing)
		cmd *= " -N" * parse_arg_and_pen(val, "+g", false)
	end
	cmd = add_opt(d, cmd, 'Q', [:Q :surf :surftype],
				  (mesh=("m", add_opt_fill), surface="_s", surf="_s", img=("i",arg2str), image="i", nan_alpha="_c", monochrome="_+m", waterfall=(rows="my", cols="mx", fill=add_opt_fill)))
	cmd = add_opt(d, cmd, 'W', [:W :pens :pen], (contour=("c", add_opt_pen),
	              mesh=("m", add_opt_pen), facade=("f", add_opt_pen)) )
	cmd = add_opt(d, cmd, 'T', [:T :no_interp :tiles], (skip="_+s", skip_nan="_+s", outlines=("+o", add_opt_pen)) )
	(!occursin(" -T", cmd)) ? cmd = parse_JZ(d, cmd)[1] : del_from_dict(d, [:JZ])	# Means, even if we had one, ignore silently
	cmd = add_opt(d, cmd, "%", [:layout :mem_layout], nothing)

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)		# Find how data was transmitted

	(isa(arg1, Array{<:Number})) && (arg1 = mat2grid(arg1))

	cmd, N_used, arg1, arg2, arg3 = common_get_R_cpt(d, cmd0, cmd, opt_R, got_fname, arg1, arg2, arg3, "grdview")
	cmd, arg1, arg2, arg3, arg4 = common_shade(d, cmd, arg1, arg2, arg3, arg4, "grdview")
	cmd, arg1, arg2, arg3, arg4, arg5 = parse_G_grdview(d, [:G :drapefile], cmd, arg1, arg2, arg3, arg4, arg5)

	_cmd, K = finish_PS_nested(d, ["grdview " * cmd], K)
    return finish_PS_module(d, _cmd, "", K, O, true, arg1, arg2, arg3, arg4, arg5)
end

# ---------------------------------------------------------------------------------------------------
function parse_G_grdview(d::Dict, symbs::Array{<:Symbol}, cmd::String, arg1, arg2, arg3, arg4, arg5)
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "GMTgrid | Tuple | String"), arg1, arg2, arg3, arg4, arg5
	if ((val = find_in_dict(d, [:G :drapefile])[1]) !== nothing)
		if (isa(val, String))				# Uff, simple. Either a file name or a -A type modifier
			cmd *= " -G" * val
		elseif (isa(val, GMTgrid))			# A single drape grid (arg1-3 may be used already)
			cmd, N_used = put_in_slot(cmd, val, 'G', [arg1, arg2, arg3, arg4])
			if     (N_used == 1)  arg1 = val
			elseif (N_used == 2)  arg2 = val
			elseif (N_used == 3)  arg3 = val
			elseif (N_used == 4)  arg4 = val
			end
		elseif (isa(val, Tuple) && length(val) == 3)
			cmd, N_used = put_in_slot(cmd, val[1], 'G', [arg1, arg2, arg3, arg4, arg5])
			cmd *= " -G -G"		# Because the above only set one -G and we need 3
			if     (N_used == 1)  arg1 = val[1];	arg2 = val[2];		arg3 = val[3]
			elseif (N_used == 2)  arg2 = val[1];	arg3 = val[2];		arg4 = val[3]
			elseif (N_used == 3)  arg3 = val[1];	arg4 = val[2];		arg5 = val[3]
			end
		else
			error("Wrong way of setting the drape (G) option.")
		end
	end
	return cmd, arg1, arg2, arg3, arg4, arg5
end

# ---------------------------------------------------------------------------------------------------
grdview!(cmd0::String="", arg1=nothing; first=false, kw...) = grdview(cmd0, arg1; first=first, kw...)
grdview(arg1; first=true, kw...) = grdview("", arg1; first=first, kw...)
grdview!(arg1; first=false, kw...) = grdview("", arg1; first=first, kw...)