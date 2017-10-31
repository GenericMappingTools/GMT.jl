"""
    grdview(cmd0::String="", arg1=[], arg2=[], arg3=[]; fmt="", kwargs...)

Reads a 2-D grid file and produces a 3-D perspective plot by drawing a mesh, painting a
colored/grayshaded surface made up of polygons, or by scanline conversion of these polygons
to a raster image.

Full option list at [`grdview`](http://gmt.soest.hawaii.edu/doc/latest/grdview.html)

- $(GMT.opt_J)
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
- $(GMT.opt_Jz)
- **N** : **plane** : -- Str or Int --
    Draws a plane at this z-level.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdview.html#n)
- $(GMT.opt_P)
- **Q** : **type** : -- Str or Int --
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
# ---------------------------------------------------------------------------------------------------
function grdview(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; data=[],
                 fmt::String="", K=false, O=false, first=true, kwargs...)

	length(kwargs) == 0 && isempty(data) && return monolitic("grdview", cmd0, arg1)	# Speedy mode
	output, opt_T, fname_ext = fname_out(fmt)		# OUTPUT may have been an extension only

	d = KW(kwargs)
	cmd = ""
    cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd0, cmd, "", O, " -JX12c/0")
	cmd = parse_JZ(cmd, d)
	cmd = parse_UVXY(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_n(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	cmd = add_opt(cmd, 'N', d, [:N :plane])
	cmd = add_opt(cmd, 'Q', d, [:Q :type])
	cmd = add_opt(cmd, 'S', d, [:S :smooth])
	cmd = add_opt(cmd, 'T', d, [:T :no_interp])
	cmd = add_opt(cmd, 'W', d, [:W])
	cmd = add_opt(cmd, "Wc", d, [:contour])
	cmd = add_opt(cmd, "Wm", d, [:mesh])
	cmd = add_opt(cmd, "Wf", d, [:facade])

	# In case DATA holds a grid file name, copy it into cmd. If Grids put them in ARGs
	cmd, arg1, arg2, arg3 = read_data(data, cmd, arg1, arg2, arg3)

	for sym in [:C :color :cmap]
		if (haskey(d, sym))
			if (!isa(d[sym], GMTcpt))	# Uff, simple. Either a file name or a -A type modifier
				cmd = cmd * " -C" * arg2str(d[sym])
			else
				cmd, N_cpt = put_in_slot(cmd, d[sym], 'C', [arg1, arg2])
				if (N_cpt == 1)     arg1 = d[sym]
				elseif (N_cpt == 2) arg2 = d[sym]
				end
			end
			break
		end
	end

	for sym in [:I :shade :intensity :intensfile]
		if (haskey(d, sym))
			if (!isa(d[sym], GMTgrid))                  # Uff, simple. Either a file name or a -A type modifier
				cmd = cmd * " -I" * arg2str(d[sym])
			else
				cmd,N_shade = put_in_slot(cmd, d[sym], 'I', [arg1, arg2, arg3])
				if (N_shade == 1)     arg1 = d[sym]
				elseif (N_shade == 2) arg2 = d[sym]
				elseif (N_shade == 3) arg3 = d[sym]
				end
			end
			break
		end
	end

	for sym in [:G :drapefile]
		if (haskey(d, sym))
			if (isa(d[sym], String))					# Uff, simple. Either a file name or a -A type modifier
				cmd = cmd * " -G" * d[sym]
			elseif (isa(d[sym], GMTgrid))				# A single drape grid
				cmd,N_drape = put_in_slot(cmd, d[sym], 'G', [arg1, arg2, arg3, arg4])
				if (N_drape == 1)     arg1 = d[sym]
				elseif (N_drape == 2) arg2 = d[sym]
				elseif (N_drape == 3) arg3 = d[sym]
				elseif (N_drape == 4) arg4 = d[sym]
				end
			elseif (isa(d[sym], Tuple) && length(d[sym]) == 3)
				cmd,N_drape = put_in_slot(cmd, d[sym][1], 'G', [arg1, arg2, arg3, arg4, arg5, arg6])
				if (N_drape == 1)      arg1 = d[sym][1];	arg2 = d[sym][2];		arg3 = d[sym][3]
				elseif (N_drape == 2)  arg2 = d[sym][1];	arg3 = d[sym][2];		arg4 = d[sym][3]
				elseif (N_drape == 3)  arg3 = d[sym][1];	arg4 = d[sym][2];		arg5 = d[sym][3]
				elseif (N_drape == 4)  arg4 = d[sym][1];	arg5 = d[sym][2];		arg6 = d[sym][3]
				end
			end
		end
	end

	cmd = finish_PS(d, cmd0, cmd, output, K, O)
    return finish_PS_module(d, cmd, "", arg1, arg2, arg3, arg4, arg5, arg6, output, fname_ext, opt_T, K, "grdview")
end

# ---------------------------------------------------------------------------------------------------
grdview!(cmd0::String="", arg1=[]; data=[], fmt::String="", K=true, O=true, first=false, kw...) =
	grdview(cmd0, arg1; data=data, fmt=fmt, K=true, O=true, first=false, kw...)

grdview(arg1::GMTgrid, cmd0::String="", arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; data=[],
        fmt::String="", K=false, O=false, first=true, kw...) =
	grdview(cmd0, arg1, arg2, arg3, arg4, arg5, arg6; data=data, fmt=fmt, K=K, O=O, first=first, kw...)

grdview!(arg1::GMTgrid, cmd0::String="", arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; data=[],
        fmt::String="", K=true, O=true, first=false, kw...) =
	grdview(cmd0, arg1, arg2, arg3, arg4, arg5, arg6; data=data, fmt=fmt, K=true, O=true, first=false, kw...)