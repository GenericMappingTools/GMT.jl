"""
	pstext(cmd0::String="", arg1=[]; fmt="", kwargs...)

Plots text strings of variable size, font type, and orientation. Various map projections are
provided, with the option to draw and annotate the map boundaries.

Full option list at [`pstext`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html)

Parameters
----------

- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- **A** : **azimuths** : -- Bool or [] --
    Angles are given as azimuths; convert them to directions using the current projection.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#a)
- **C** : **clearance** : -- Str --
    Sets the clearance between the text and the surrounding box [15%].
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#c)
- **D** : **offset** : -- Str --
    Offsets the text from the projected (x,y) point by dx,dy [0/0].
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#d)
- **F** : **text_attrib** : -- Str or number --
    Specify up to three text attributes (font, angle, and justification).
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#f)
- **G** : **fill** : -- Number or Str --
    Sets the shade or color used for filling the text box [Default is no fill].
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#g)
- $(GMT.opt_Jz)
- **L** : **list** : -- Bool or [] --
    Lists the font-numbers and font-names available, then exits.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#l)
- **N** : **no_clip** : --- Str or [] --
    Do NOT clip text at map boundaries.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#n)
- $(GMT.opt_P)
- **Q** : **change_case** : --- Str --
    Change all text to either lower or upper case.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#q)
- **T** : **text_box** : --- Str --
    Specify the shape of the textbox when using G and/or W.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#t)
- **W** : **line_attribs** : -- Str --
    Sets the pen used to draw a rectangle around the text string.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#w)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_a)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_p)
- $(GMT.opt_t)
"""
# ---------------------------------------------------------------------------------------------------
function pstext(cmd0::String="", arg1=[]; caller=[], data=[], fmt="",
              K=false, O=false, first=true, kwargs...)

	arg2 = []		# May be needed if GMTcpt type is sent in via G
	N_args = isempty_(arg1) ? 0 : 1

	if (length(kwargs) == 0 && N_args == 0 && isempty(data))			# Good, the speedy mode
		if (N_args == 0)  return gmt("pstext " * cmd0)
		else              return gmt("pstext " * cmd0, arg1)
		end
	end

	if (!isempty(data) && N_args == 1)
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
	cmd, opt_R = parse_R(cmd, d, O)
	cmd, opt_J = parse_J(cmd, d, O)
	if (!O && isempty(opt_J))					# If we have no -J use this default
		opt_J = " -JX12c/0"
		cmd = cmd * opt_J
	end
	cmd = parse_JZ(cmd, d)
	if (!isempty(caller) && contains(cmd0,"-B") && contains(opt_J, "-JX"))	# e.g. plot() sets 'caller'
		cmd, opt_B = parse_B(cmd, d, "-Ba -BWS")
	else
		cmd, opt_B = parse_B(cmd, d)
	end
	cmd = parse_U(cmd, d)
	cmd = parse_V(cmd, d)
	cmd = parse_X(cmd, d)
	cmd = parse_Y(cmd, d)
	cmd, = parse_bi(cmd, d)
	cmd, = parse_di(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)

	if (first)  K = true;	O = false
	else        K = true;	O = true;	cmd = replace(cmd, opt_B, "");	opt_B = ""
	end

	# Read in the 'data' and compute a tight -R if this was not provided 
	if (isa(data, String))
		if (GMTver >= 6)				# Due to a bug in GMT5, gmtread has no -i option 
			data = gmt("read -Td " * opt_i * opt_bi * opt_di * " " * data)
			if (!isempty(opt_i))		# Remove the -i option from cmd. It has done its job
				cmd = replace(cmd, opt_i, "")
				opt_i = ""
			end
		else
			data = gmt("read -Td " * opt_bi * opt_di * " " * data)
		end
	end
	if (!isempty(data)) arg1 = data  end

    cmd = add_opt(cmd, 'W', d, [:W :bin :bin_width])

	if (isempty(opt_R))
		info = gmt("gmtinfo -C" * opt_i, arg1)		# Here we are reading from an original GMTdataset or Array
		if (size(info[1].data, 2) < 4)
			error("Need at least 2 columns of data to run this program")
		end
		opt_R = @sprintf(" -R%.8g/%.8g/%.8g/%.8g", info[1].data[1], info[1].data[2], info[1].data[3], info[1].data[4])
		cmd = cmd * opt_R
	end

	for sym in [:C :color]
		if (haskey(d, sym))
			if (isa(d[sym], GMT.GMTcpt))
				cmd = cmd * " -C"
				if     (N_args == 0)  arg1 = d[sym];	N_args += 1
				elseif (N_args == 1)  arg2 = d[sym];	N_args += 1
				else   error("Can't send the CPT data via G and input array")
				end
			else
				cmd = cmd * " -C" * arg2str(d[sym])
			end
			break
		end
	end

	cmd = add_opt(cmd, 'A', d, [:A :horizontal])
	cmd = add_opt(cmd, 'D', d, [:D :annot :annotate])
	cmd = add_opt(cmd, 'F', d, [:F :center])
    cmd = add_opt(cmd, 'G', d, [:G :fill])
	cmd = add_opt(cmd, 'I', d, [:I :inquire])
	cmd = add_opt(cmd, 'L', d, [:L :pen])

	cmd = add_opt(cmd, 'Q', d, [:Q :change_case])
	cmd = add_opt(cmd, 'T', d, [:T :text_box])
	cmd = add_opt(cmd, 'Z', d, [:Z :3D])

	opt_W = ""
	pen = build_pen(d)						# Either a full pen string or empty ("")
	if (!isempty(pen))
		opt_W = " -W" * pen
	else
		for sym in [:W :line_attrib]
			if (haskey(d, sym))
				if (isa(d[sym], String))
					opt_W = " -W" * arg2str(d[sym])
				elseif (isa(d[sym], Tuple))	# Like this it can hold the pen, not extended atts
					opt_W = " -W" * parse_pen(d[sym])
				else
					error("Nonsense in W option")
				end
				break
			end
		end
	end

	if (!isempty(opt_W)) 		# We have a rectangle request
		cmd = [finish_PS(d, cmd0, cmd * opt_W, output, K, O)]
	else
		cmd = [finish_PS(d, cmd0, cmd, output, K, O)]
	end

	if (haskey(d, :ps)) PS = true			# To know if returning PS to the REPL was requested
	else                PS = false
	end

	P = nothing
	for k = 1:length(cmd)
		(haskey(d, :Vd)) && println(@sprintf("\tpstext %s", cmd[k]))
		if (N_args == 0)					# Simple case
			if (PS) P = gmt("pstext " * cmd[k])
			else        gmt("pstext " * cmd[k])
			end
		elseif (N_args == 1)				# One numeric input
			if (PS) P = gmt("pstext " * cmd[k], arg1)
			else        gmt("pstext " * cmd[k], arg1)
			end
		else								# Two numeric inputs (data + CPT)
			if (PS) P = gmt("pstext " * cmd[k], arg1, arg2)
			else        gmt("pstext " * cmd[k], arg1, arg2)
			end
		end
	end
	if (haskey(d, :show)) 					# Display Fig in default viewer
		showfig(output, fname_ext, opt_T, K)
	elseif (haskey(d, :savefig))
		showfig(output, fname_ext, opt_T, K, d[:savefig])
	end
	return P
end

# ---------------------------------------------------------------------------------------------------
pstext!(cmd0::String="", arg1=[], arg2::GMTcpt=[]; caller=[], data=[], fmt="",
      K=true, O=true,  first=false, kwargs...) =
	pstext(cmd0, arg1, arg2; caller=caller, data=data, fmt=fmt,
	     K=true, O=true,  first=false, kwargs...)
