"""
    grdview(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[], arg5=[], arg6=[]; data=[],
            fmt="", K=false, O=false, first=true, kwargs...)

Reads a 2-D grid file and produces a 3-D perspective plot by drawing a mesh, painting a
colored/grayshaded surface made up of polygons, or by scanline conversion of these polygons
to a raster image.

Full option list at [`grdimage`](http://gmt.soest.hawaii.edu/doc/latest/grdview.html)

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
                 fmt="", K=false, O=false, first=true, kwargs...)

	if (length(kwargs) == 0)		# Good, speed mode
		return gmt("grdview " * cmd0)
	end

	if (!isempty_(data) && !isempty_(arg1))
		warn("Conflicting ways of providing input data. Both a file name via positional and
			  a data array via keyword args were provided. Ignoring former argument")
	end

	output = fmt
	if (!isa(output, String))
		error("Output format or name must be a String")
	else
		output, opt_T, fname_ext = fname_out(output)		# OUTPUT may have been an extension only
	end

	d = KW(kwargs)
	cmd = ""
	maybe_more = false			# If latter set to true, search for lc & lc pen settings
	cmd, opt_R = parse_R(cmd, d)
	cmd, opt_B = parse_B(cmd, d)
	cmd, opt_J = parse_J(cmd, d)
	cmd = parse_JZ(cmd, d)
	cmd = parse_U(cmd, d)
	cmd = parse_V(cmd, d)
	cmd = parse_X(cmd, d)
	cmd = parse_Y(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_n(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)

	if (first)  K = true;	O = false
	else        K = true;	O = true;	cmd = replace(cmd, opt_B, "");	opt_B = ""
	end

	cmd = add_opt(cmd, 'N', d, [:N :plane])
	cmd = add_opt(cmd, 'Q', d, [:Q :type])
	cmd = add_opt(cmd, 'S', d, [:S :smooth])
	cmd = add_opt(cmd, 'T', d, [:T :no_interp])
	cmd = add_opt(cmd, 'W', d, [:W])
	cmd = add_opt(cmd, "Wc", d, [:contour])
	cmd = add_opt(cmd, "Wm", d, [:mesh])
	cmd = add_opt(cmd, "Wf", d, [:facade])

	if (!isempty_(data))
		if (!isempty_(arg1))
			warn("Conflicting ways of providing input data. Both a file name via positional and
				  a data array via kwyword args were provided. Ignoring later argument")
		else
			if (isa(data, String)) 		# OK, we have data via file
				cmd = cmd * " " * data
			else
				arg1 = data				# Whatever this is
			end
		end
	end

	for sym in [:C :color :cmap]
		if (haskey(d, sym))
			if (!isa(d[sym], GMTcpt))	# Uff, simple. Either a file name or a -A type modifier
				cmd = cmd * " -C" * arg2str(d[sym])
			else
				cmd, N_cpt = put_in_slot(cmd, d[sym], 'C', (arg1, arg2))
				if (N_cpt == 1)     arg1 = [d[sym]]
				elseif (N_cpt == 2) arg2 = [d[sym]]
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
				cmd,N_shade = put_in_slot(cmd, d[sym], 'I', (arg1, arg2, arg3))
				if (N_shade == 1)     arg1 = [d[sym]]
				elseif (N_shade == 2) arg2 = [d[sym]]
				elseif (N_shade == 3) arg3 = [d[sym]]
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
				cmd,N_drape = put_in_slot(cmd, d[sym], 'G', (arg1, arg2, arg3, arg4))
				if (N_drape == 1)     arg1 = [d[sym]]
				elseif (N_drape == 2) arg2 = [d[sym]]
				elseif (N_drape == 3) arg3 = [d[sym]]
				elseif (N_drape == 4) arg4 = [d[sym]]
				end
			elseif (isa(d[sym], Tuple) && length(d[sym]) == 3)
				cmd,N_drape = put_in_slot(cmd, d[sym][1], 'G', (arg1, arg2, arg3, arg4, arg5, arg6))
				if (N_drape == 1)      arg1 = [d[sym][1]];	arg2 = [d[sym][2]];		arg3 = [d[sym][3]]
				elseif (N_drape == 2)  arg2 = [d[sym][1]];	arg3 = [d[sym][2]];		arg4 = [d[sym][3]]
				elseif (N_drape == 3)  arg3 = [d[sym][1]];	arg4 = [d[sym][2]];		arg5 = [d[sym][3]]
				elseif (N_drape == 4)  arg4 = [d[sym][1]];	arg5 = [d[sym][2]];		arg6 = [d[sym][3]]
				end
			end
		end
	end

	cmd = finish_PS(d, cmd0, cmd, output, K, O)

	if (haskey(d, :ps)) PS = true			# To know if returning PS to the REPL was requested
	else                PS = false
	end

	(haskey(d, :Vd)) && println(@sprintf("\tgrdview %s", cmd))

	P = nothing
	if (PS)
		if     (!isempty_(arg6))  P = gmt("grdview " * cmd, arg1[1], arg2[1], arg3[1], arg4[1], arg5[1], arg6[1])
		elseif (!isempty_(arg5))  P = gmt("grdview " * cmd, arg1[1], arg2[1], arg3[1], arg4[1], arg5[1])
		elseif (!isempty_(arg4))  P = gmt("grdview " * cmd, arg1[1], arg2[1], arg3[1], arg4[1])
		elseif (!isempty_(arg3))  P = gmt("grdview " * cmd, arg1[1], arg2[1], arg3[1])
		elseif (!isempty_(arg2))  P = gmt("grdview " * cmd, arg1[1], arg2[1])
		elseif (!isempty_(arg1))  P = gmt("grdview " * cmd, arg1[1])
		else                     P = gmt("grdview " * cmd)
		end
	else
		if     (!isempty_(arg6))  gmt("grdview " * cmd, arg1[1], arg2[1], arg3[1], arg4[1], arg5[1], arg6[1])
		elseif (!isempty_(arg5))  gmt("grdview " * cmd, arg1[1], arg2[1], arg3[1], arg4[1], arg5[1])
		elseif (!isempty_(arg4))  gmt("grdview " * cmd, arg1[1], arg2[1], arg3[1], arg4[1])
		elseif (!isempty_(arg3))  gmt("grdview " * cmd, arg1[1], arg2[1], arg3[1])
		elseif (!isempty_(arg2))  gmt("grdview " * cmd, arg1[1], arg2[1])
		elseif (!isempty_(arg1))  gmt("grdview " * cmd, arg1[1])
		else                     gmt("grdview " * cmd)
		end
	end
	show_or_save(d, output, fname_ext, opt_T, K)    # Display Fig in default viewer or save it to file
	return P
end

# ---------------------------------------------------------------------------------------------------
grdview!(cmd0::String="", arg1=[]; data=[], fmt="", K=true, O=true, first=false, kw...) =
	grdview(cmd0, arg1; data=data, fmt=fmt, K=true, O=true, first=false, kw...)

# ---------------------------------------------------------------------------------------------------
function put_in_slot(cmd::String, val, opt::Char, args)
	# Find the first non-empty slot in ARGS and assign it the Val of d[:symb]
	# Return also the index of that first non-empty slot in ARGS
	k = 1
	for arg in args					# Find the first empty slot
		if (isempty_(arg))
			cmd = string(cmd, " -", opt)
			break
		end
		k += 1
	end
	return cmd, k
end