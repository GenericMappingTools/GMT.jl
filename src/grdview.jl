"""
    grdview(cmd0::String="", arg1=[], arg2=[], arg3=[]; kwargs...)

Reads a 2-D grid file and produces a 3-D perspective plot by drawing a mesh, painting a
colored/grayshaded surface made up of polygons, or by scanline conversion of these polygons
to a raster image.

Full option list at [`grdview`](http://gmt.soest.hawaii.edu/doc/latest/grdview.html)

- $(GMT.opt_J)
- $(GMT.opt_Jz)
- $(GMT.opt_R)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **G** : **drapefile** : -- Str or GMTgrid or a Tuple with 3 GMTgrid types --

    Drape the image in drapefile on top of the relief provided by relief_file.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdview.html#g)
- **I** : **shade** : **intensity** : **intensfileintens** : -- Str or GMTgrid --

    Gives the name of a grid file or GMTgrid with intensities in the (-1,+1) range,
    or a grdgradient shading flags.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grdview.html#i)
- **N** : **plane** : -- Str or Int --

    Draws a plane at this z-level.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdview.html#n)
- $(GMT.opt_P)
- **Q** : **surftime** : **surf_type** : -- Str or Int --

    Specify **m** for mesh plot, **s* for surface, **i** for image.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/grdview.html#q)
- **S** : **smooth** : -- Number --

    Smooth the contours before plotting.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/grdview.html#s)
- **T** : **no_interp** : -- Str --

    Plot image without any interpolation.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grdview.html#t)
- **W** : **contour** : **mesh** : **facade** : -- Str --

    Draw contour, mesh or facade. Append pen attributes.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/grdview.html#w)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_f)
- $(GMT.opt_n)
- $(GMT.opt_p)
- $(GMT.opt_t)
"""
function grdview(cmd0::String="", arg1=[]; first=true, kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("grdview", cmd0, arg1)
	arg2 = [];	arg3 = [];	arg4 = [];	arg5 = [];

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	K, O = set_KO(first)		# Set the K O dance
	cmd, opt_B, = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd = parse_common_opts(d, cmd, [:UVXY :JZ :f :n :p :t :params])
	cmd = parse_these_opts(cmd, d, [[:N :plane], [:Q :surftype :surf_type], [:S :smooth], [:T :no_interp],
				[:W], [:Wc :contour], [:Wm :mesh], [:Wf :facade]])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)		# Find how data was transmitted

	if (isa(arg1, Array{<:Number}))  arg1 = mat2grid(arg1)  end

	N_used = got_fname == 0 ? 1 : 0				# To know whether a cpt will go to arg1 or arg2
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_used, arg1, arg2)

	if ((val = find_in_dict(d, [:I :shade :intensity :intensfile])[1]) !== nothing)
		if (!isa(val, GMTgrid))			# Uff, simple. Either a file name or a -A type modifier
			cmd *= " -I" * arg2str(val)
		else
			cmd, N_used = put_in_slot(cmd, val, 'I', [arg1, arg2, arg3])
			if     (N_used == 1)  arg1 = val
			elseif (N_used == 2)  arg2 = val
			elseif (N_used == 3)  arg3 = val
			end
		end
	end

	if ((val = find_in_dict(d, [:G :drapefile])[1]) !== nothing)
		if (isa(val, String))				# Uff, simple. Either a file name or a -A type modifier
			cmd *= " -G" * val
		elseif (isa(val, GMTgrid))			# A single drape grid (arg1-3 may be used already)
			cmd, N_used = put_in_slot(cmd, val, 'G', [arg1, arg2, arg3, arg4])
			if (N_used == 1)     arg1 = val
			elseif (N_used == 2) arg2 = val
			elseif (N_used == 3) arg3 = val
			elseif (N_used == 4) arg4 = val
			end
		elseif (isa(val, Tuple) && length(val) == 3)
			cmd, N_used = put_in_slot(cmd, val[1], 'G', [arg1, arg2, arg3, arg4, arg5])
			cmd *= " -G -G"		# Because the above only set one -G and we need 3
			if (N_used == 1)      arg1 = val[1];	arg2 = val[2];		arg3 = val[3]
			elseif (N_used == 2)  arg2 = val[1];	arg3 = val[2];		arg4 = val[3]
			elseif (N_used == 3)  arg3 = val[1];	arg4 = val[2];		arg5 = val[3]
			end
		else
			error("Wrong way of setting the drape (G) option.")
		end
	end

	cmd = finish_PS(d, cmd, output, K, O)
    return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, "grdview", arg1, arg2, arg3, arg4, arg5)
end

# ---------------------------------------------------------------------------------------------------
grdview!(cmd0::String="", arg1=[]; first=false, kw...) = grdview(cmd0, arg1; first=first, kw...)
grdview(arg1; first=true, kw...) = grdview("", arg1; first=first, kw...)
grdview!(arg1; first=false, kw...) = grdview("", arg1; first=first, kw...)