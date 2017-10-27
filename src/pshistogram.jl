"""
	pshistogram(cmd0::String="", arg1=[]; fmt="", kwargs...)

Reads file and examines the first data column to calculate histogram parameters based on the bin-width provided.

Full option list at [`pshistogram`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html)

Parameters
----------

- $(GMT.opt_J)
- **A** : **horizontal** : -- Bool or [] --
    Plot the histogram horizontally from x = 0 [Default is vertically from y = 0].
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#a)
- $(GMT.opt_B)
- **C** : **color** : -- Str or GMTcpt --
    Give a CPT. The mid x-value for each bar is used to look-up the bar color.
	[`-C`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#c)
- **D** : **annot** : **annotate** : -- Str or [] --
    Annotate each bar with the count it represents.
	[`-D`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#d)
- **F** : **center** : -- Bool or [] --
    Center bin on each value. [Default is left edge].
	[`-F`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#f)
- **G** : **fill** : -- Number or Str --
    Select filling of bars [Default is no fill].
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#g)
- **I** : **inquire** : -- Str or [] --
    Inquire about min/max x and y after binning.
	[`-I`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#i)
- $(GMT.opt_Jz)
- **L** : **pen** : -- Number or Str --
    Draw bar outline using the specified pen thickness. [Default is no outline].
	[`-L`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#l)
- **N** : **normal** : -- Str --
    Draw the equivalent normal distribution; append desired pen.
	[`-N`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#n)
- $(GMT.opt_P)
- **Q** : **cumulative** : -- Str or [] --
    Draw a cumulative histogram. Append r to instead compute the reverse cumulative histogram.
	[`-Q`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#q)
- $(GMT.opt_R)
- **S** : **stairs** : -- Bool or [] --
    Draws a stairs-step diagram which does not include the internal bars of the default histogram.
	[`-S`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#s)
- **Z** : **kind** : -- Str --
    Choose between 6 types of histograms:
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/pshistogram.html#z)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_p)
- $(GMT.opt_t)
"""
# ---------------------------------------------------------------------------------------------------
function pshistogram(cmd0::String="", arg1=[]; caller=[], data=[], fmt="",
              K=false, O=false, first=true, kwargs...)

	arg2 = []		# May be needed if GMTcpt type is sent in via C
	N_args = isempty_(arg1) ? 0 : 1

	if (length(kwargs) == 0 && N_args == 0 && isempty(data))			# Good, the speedy mode
		if (N_args == 0)  return gmt("pshistogram " * cmd0)
		else              return gmt("pshistogram " * cmd0, arg1)
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
	cmd = parse_a(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_h(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)
	cmd = parse_swappxy(cmd, d)

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

	if (isempty(opt_R))
		info = gmt("gmtinfo -C" * opt_i, arg1)		# Here we are reading from an original GMTdataset or Array
		if (size(info[1].data, 2) < 4)
			error("Need at least 2 columns of data to run this program")
		end
		opt_R = @sprintf(" -R%.8g/%.8g/%.8g/%.8g", info[1].data[1], info[1].data[2], info[1].data[3], info[1].data[4])
		cmd = cmd * opt_R
	end

	for sym in [:G :color]
		if (haskey(d, sym))
			if (isa(d[sym], GMT.GMTcpt))
				cmd = cmd * " -G"
				if     (N_args == 0)  arg1 = d[sym];	N_args += 1
				elseif (N_args == 1)  arg2 = d[sym];	N_args += 1
				else   error("Can't send the CPT data via G and input array")
				end
			else
				cmd = cmd * " -G" * arg2str(d[sym])
			end
			break
		end
	end

	cmd = add_opt(cmd, 'A', d, [:A :horizontal])
	cmd = add_opt(cmd, 'C', d, [:C :color])
	cmd = add_opt(cmd, 'D', d, [:D :annot :annotate])
	cmd = add_opt(cmd, 'F', d, [:F :center])
    cmd = add_opt(cmd, 'G', d, [:G :fill])
	cmd = add_opt(cmd, 'I', d, [:I :inquire])
	cmd = cmd * opt_pen(d, "L", [:L :pen])
	cmd = add_opt(cmd, 'Q', d, [:Q :cumulative])
	cmd = add_opt(cmd, 'S', d, [:S :stairs])
	cmd = add_opt(cmd, 'Z', d, [:Z :kind])

	for symb in [:N :normal]
		if (haskey(d, symb))
			if (isa(d[symb], Number))      cmd = @sprintf("%s -N%d", cmd, d[symb])
			elseif (isa(d[symb], String))  cmd = cmd * " -N" * d[symb]
			elseif (isa(d[symb], Tuple))   cmd = cmd * " -N" * parse_arg_and_pen(d[symb])
			end
			break
		end
	end

	cmd = [finish_PS(d, cmd0, cmd, output, K, O)]

	if (haskey(d, :ps)) PS = true			# To know if returning PS to the REPL was requested
	else                PS = false
	end

	P = nothing
	for k = 1:length(cmd)
		(haskey(d, :Vd)) && println(@sprintf("\tpshistogram %s", cmd[k]))
		if (N_args == 0)					# Simple case
			if (PS) P = gmt("pshistogram " * cmd[k])
			else        gmt("pshistogram " * cmd[k])
			end
		elseif (N_args == 1)				# One numeric input
			if (PS) P = gmt("pshistogram " * cmd[k], arg1)
			else        gmt("pshistogram " * cmd[k], arg1)
			end
		else								# Two numeric inputs (data + CPT)
			if (PS) P = gmt("pshistogram " * cmd[k], arg1, arg2)
			else        gmt("pshistogram " * cmd[k], arg1, arg2)
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
pshistogram!(cmd0::String="", arg1=[], arg2::GMTcpt=[]; caller=[], data=[], fmt="",
      K=true, O=true,  first=false, kwargs...) =
	pshistogram(cmd0, arg1, arg2; caller=caller, data=data, fmt=fmt,
	     K=true, O=true,  first=false, kwargs...)
