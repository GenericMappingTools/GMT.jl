const psxy  = plot
const psxy! = plot!
const psxyz  = plot3d
const psxyz! = plot3d!

# ---------------------------------------------------------------------------------------------------
function common_plot_xyz(cmd0, arg1, caller, first, is3D, kwargs...)
	global multi_col
	N_args = (arg1 === nothing) ? 0 : 1

	is_ternary = (caller == "ternary") ? true : false
	if (is3D)	        gmt_proggy = "psxyz "
	elseif (is_ternary) gmt_proggy = "psternary "
	else		        gmt_proggy = "psxy "
	end

	(occursin(" -", cmd0)) && return monolitic(gmt_proggy, cmd0, arg1)

	cmd = "";	sub_module = ""			# Will change to "scatter", etc... if called by sub-modules
	if (caller != "")
		if (occursin(" -", caller))		# some sub-modues use this piggy-backed call
			if ((ind = findfirst("|", caller)) !== nothing)	# A mixed case with "caler|partiall_command"
				sub_module = caller[1:ind[1]-1]
				cmd = caller[ind[1]+1:end]
				caller = sub_module		# Because of parse_BJR()
			else
				cmd = caller
				caller = "others"		# It was piggy-backed
			end
		else
			sub_module = caller
		end
	end

	d = KW(kwargs)
	output, opt_T, fname_ext, K, O = fname_out(d, first)		# OUTPUT may have been an extension only

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd, caller, O)
	if (is3D)	cmd,opt_JZ = parse_JZ(cmd, d)	end
	cmd = parse_common_opts(d, cmd, [:a :e :f :g :p :t :yx :params], first)
	cmd = parse_these_opts(cmd, d, [[:D :shift :offset], [:I :intens], [:N :noclip :no_clip]])
	if (is_ternary)  cmd = add_opt(cmd, 'M', d, [:M :no_plot])  end
	opt_UVXY = parse_UVXY("", d)	# Need it separate to not risk to double include it.
	cmd, opt_c = parse_c(cmd, d)	# Need opt_c because we may need to remove it from double calls

	# If a file name sent in, read it and compute a tight -R if this was not provided
	if (opt_R == "" && sub_module == "bar")  opt_R = "///0"  end	# Make sure y_min = 0
	cmd, arg1, opt_R, opt_i = read_data(d, cmd0, cmd, arg1, opt_R, is3D)
	
	if (is3D && isempty(opt_JZ) && length(collect(eachmatch(r"/", opt_R))) == 5)
		cmd *= " -JZ6c"		# Default -JZ
	end

	cmd = add_opt(cmd, 'A', d, [:A :steps :straight_lines], (x="x", y="y", meridian="m", parallel="p"))
	opt_F = add_opt("", "", d, [:F :conn :connection],
	                (continuous=("c", nothing, 1), net=("n", nothing, 1), network=("n", nothing, 1), refpoint=("r", nothing, 1),  ignore_hdr="_a", single_group="_f", segments="_s", segments_reset="_r", anchor=("", arg2str)))
	if (length(opt_F) > 1 && !occursin("/", opt_F))  opt_F = opt_F[1]  end	# Allow con=:net or con=(1,2)
	if (opt_F != "")  cmd *= " -F" * opt_F  end

	# Error Bars?
	got_Ebars = false
	val, symb = find_in_dict(d, [:E :error :error_bars :error_bars])
	if (val !== nothing)
		cmd, arg1 = add_opt(add_opt, (cmd, 'E', d, [symb]),
					        (x="|x",y="|y",xy="|xy",X="|X",Y="|Y", asym="_+a", colored="_+c", cline="_+cl", csymbol="_+cf", wiskers="|+n",cap="+w",pen=("+p",add_opt_pen)), false, arg1)
		got_Ebars = true
	end

	# Look for color request. Do it after error bars because they may add a column
	len = length(cmd);	n_prev = N_args;
	cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1)
	#cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1, nothing, true, true, "", true)

	# See if we got a CPT. If yes there may be some work to do if no color column provided in input data.
	cmd, arg1, arg2, N_args, mcc = make_color_column(d, cmd, opt_i, len, N_args, n_prev, is3D, got_Ebars, arg1, arg2)

	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	opt_Gsymb = add_opt_fill("", d, [:G :markerfacecolor :MarkerFaceColor :mc], 'G')	# Filling of symbols

	# To track a still existing bug in sessions management at GMT lib level
	got_pattern = false
	if (occursin("-Gp", cmd) || occursin("-GP", cmd) || occursin("-Gp", opt_Gsymb) || occursin("-GP", opt_Gsymb))
		got_pattern = true
	end

	if (is_ternary)			# Means we are in the psternary mode
		cmd = add_opt(cmd, 'L', d, [:L :labels])
	else
		cmd = add_opt(cmd, 'L', d, [:L :close],
			(left="_+xl", right="_+xr", x0="+x", bot="_+yb", top="_+yt", y0="+y", sym="_+d", asym="_+D", envelope="_+b",
			 pen=("+p",add_opt_pen)))
		if (occursin("-L", cmd) && !occursin("-G", cmd) && !occursin("+p", cmd))  cmd *= "+p0.5p"  end
	end

	opt_Wmarker = ""
	if ((val = find_in_dict(d, [:markeredgecolor :MarkerEdgeColor])[1]) !== nothing)
		opt_Wmarker = "0.5p," * arg2str(val)		# 0.25p is too thin?
	end

	opt_W = add_opt_pen(d, [:W :pen], "W")
	if (occursin("+c", opt_W) && !occursin("-C", cmd))
		@warn("Color lines (or fill) from a color scale was selected but no color scale provided. Expect ...")
	end

	opt_S = add_opt("", 'S', d, [:S :symbol], (symb="1", size="", unit="1"))
	if (opt_S == "")			# OK, no symbol given via the -S option. So fish in aliases
		marca, arg1, more_cols = get_marker_name(d, [:marker :Marker :shape], is3D, false, arg1)
		if ((val = find_in_dict(d, [:markersize :MarkerSize :ms :size])[1]) !== nothing)
			if (marca == "")  marca = "c"  end		# If a marker name was not selected, defaults to circle
			if (isa(val, AbstractArray))
				if (length(val) == size(arg1,1))
					arg1 = hcat(arg1, val[:])
				else
					error("The size array must have the same number of elements rows in the data")
				end
			else
				marca *= arg2str(val);
			end
			opt_S = " -S" * marca
		elseif (marca != "")		# User only selected a marker name but no size.
			opt_S = " -S" * marca
			# If data comes from a file, then no automatic symbol size is added
			op = lowercase(marca[1])
			if (!more_cols && arg1 !== nothing && !isa(arg1, GMTcpt) && !occursin(op, "bekmrvw"))  opt_S *= "7p"  end
		end
	end

	opt_ML = ""
	if (opt_S != "")
		if ((val = find_in_dict(d, [:markerline :MarkerLine :ml])[1]) !== nothing)
			if (isa(val, Tuple))  opt_ML = " -W" * parse_pen(val) # This can hold the pen, not extended atts
			elseif (isa(val, NamedTuple))  opt_ML = add_opt_pen(nt2dict(val), [:pen], "W")
			else                  opt_ML = " -W" * arg2str(val)
			end
			if (opt_Wmarker != "")
				opt_Wmarker = ""
				@warn("markerline overrides markeredgecolor")
			end
		end
		if (opt_W != "" && opt_ML != "")
			@warn("You cannot use both markerline and W or pen keys.")
		end
	end

	# See if any of the scatter, bar, lines, etc... was the caller and if yes, set sensible defaults.
	cmd = check_caller(d, cmd, opt_S, opt_W, sub_module, O)

	if (opt_W != "" && opt_S == "") 						# We have a line/polygon request
		cmd = finish_PS(d, cmd * opt_W * opt_UVXY, output, K, O)

	elseif (opt_W == "" && opt_S != "")						# We have a symbol request
		if (opt_Wmarker != "" && opt_W == "") opt_Gsymb *= " -W" * opt_Wmarker  end		# reuse var name
		if (opt_ML != "")  cmd *= opt_ML  end				# If we have a symbol outline pen
		cmd = finish_PS(d, cmd * opt_S * opt_Gsymb * opt_UVXY, output, K, O)

	elseif (opt_W != "" && opt_S != "")						# We have both line/polygon and a symbol
		if (occursin(opt_Gsymb, cmd))  opt_Gsymb = ""  end
		if (opt_S[4] == 'v' || opt_S[4] == 'V' || opt_S[4] == '=')
			cmd = finish_PS(d, cmd * opt_W * opt_S * opt_Gsymb * opt_UVXY, output, K, O)
		else
			if (opt_Wmarker != "")  opt_Wmarker = " -W" * opt_Wmarker  end		# Set Symbol edge color 
			cmd1 = cmd * opt_W * opt_UVXY
			cmd2 = replace(cmd, opt_B => "") * opt_S * opt_Gsymb * opt_Wmarker	# Don't repeat option -B
			if (opt_c != "")  cmd2 = replace(cmd2, opt_c => "")  end			# Not in scond call (subplots)
			if (opt_ML != "")  cmd1 = cmd1 * opt_ML  end	# If we have a symbol outline pen
			cmd = [finish_PS(d, cmd1, output, true, O); finish_PS(d, cmd2, output, K, true)]
		end

	else
		cmd = finish_PS(d, cmd * opt_UVXY, output, K, O)
	end

	# Let matrices with more data columns, and for which Color info was NOT set, plot multiple lines at once
	if (!mcc && opt_S == "" && (caller == "lines" || caller == "plot") && isa(arg1, Array{<:Number,2}) && size(arg1,2) > 2+is3D && size(arg1,1) > 1 && (multi_col || haskey(d, :multicol)) )
		multi_col = false							# Reset because this is a use-only-once option
		penC = "";		penS = "";	cycle=:cycle
		# But if we have a color in opt_W (idiotic) let it overrule the automatic color cycle in mat2ds()
		if (opt_W != "")  penT, penC, penS = break_pen(scan_opt(opt_W, "-W"))  end
		if (penC  != "")  cycle = [penC]  end
		arg1 = mat2ds(arg1, color=cycle, ls=penS)	# Convert to multi-segment GMTdataset
		D = gmt("gmtinfo -C", arg1)					# But now also need to update the -R string
		if (isa(cmd, Array))						# Replace old -R by the new one
			cmd[1] = replace(cmd[1], opt_R => " -R" * arg2str(round_wesn(D[1].data)))
		else
			cmd = replace(cmd, opt_R => " -R" * arg2str(round_wesn(D[1].data)))
		end
	end

	put_in_legend_bag(d, cmd, arg1)

	r = finish_PS_module(d, gmt_proggy .* cmd, "", output, fname_ext, opt_T, K, O, false, arg1, arg2)
	if (got_pattern || occursin("-Sk", opt_S))  gmt("destroy")  end 	# Apparently patterns are screweing the session
	return r
end

# ---------------------------------------------------------------------------------------------------
function make_color_column(d, cmd, opt_i, len, N_args, n_prev, is3D, got_Ebars, arg1, arg2)
	# See if we got a CPT. If yes, there is quite some work to do if no color column provided in input data.
	# N_ARGS will be == n_prev+1 when a -Ccpt was used. Otherwise they are equal.

	if (arg1 === nothing || isa(arg1, GMT.GMTcpt))  return cmd, arg1, arg2, N_args, false  end		# Play safe

	mz, the_kw = find_in_dict(d, [:zcolor :markerz :mz])
	if (!(N_args > n_prev || len < length(cmd)) && mz === nothing)	# No color request, so return right away
		return cmd, arg1, arg2, N_args, false
	end

	if (isa(arg1, Array{<:Number}))  n_rows, n_col = size(arg1)
	elseif (isa(arg1,GMTdataset))    n_rows, n_col = size(arg1.data)
	else                             n_rows, n_col = size(arg1[1].data)
	end

	warn1 = string("Probably color column in ", the_kw, " has incorrect dims. Ignoring it.")
	warn2 = "Plotting with color table requires adding one more column to the dataset but your -i
	option didn't do it, so you won't get what you expect. Try -i0-1,1 for 2D or -i0-2,2 for 3D plots"

	if (n_col <= 2+is3D)
		if (mz !== nothing)
			if (length(mz) != n_rows)  @warn(warn1); @goto noway  end
			if (isa(arg1, Array))          arg1 = hcat(arg1, mz[:])
			elseif (isa(arg1,GMTdataset))  arg1.data = hcat(arg1.data, mz[:])
			else                           arg1[1].data = hcat(arg1[1].data, mz[:])
			end
		else
			if (opt_i != "")  @warn(warn2);		@goto noway		end
			cmd = @sprintf("%s -i0-%d,%d", cmd, 1+is3D, 1+is3D)
			if ((val = find_in_dict(d, [:markersize :ms :size])[1]) !== nothing)
				cmd = @sprintf("%s-%d", cmd, 2+is3D)	# Because we know that an extra col will be added later
			end
		end
	else
		if (mz !== nothing)			# Here we must insert the color col right after the coords
			if (length(mz) != n_rows)  @warn(warn1); @goto noway  end
			if     (isa(arg1, Array))      arg1 = hcat(arg1[:,1:2+is3D], mz[:], arg1[:,3+is3D:end])
			elseif (isa(arg1,GMTdataset))  arg1.data = hcat(arg1.data[:,1:2+is3D], mz[:], arg1.data[:,3+is3D:end])
			else                           arg1[1].data = hcat(arg1[1].data[:,1:2+is3D], mz[:], arg1[1].data[:,3+is3D:end])
			end
		elseif (!got_Ebars)		# The Error bars case is very multi. Don't try to guess then.
			if (opt_i == "")  cmd = @sprintf("%s -i0-%d,%d,%d-%d", cmd, 1+is3D, 1+is3D, 2+is3D, n_col-1)
			else              @warn(warn2);		@goto noway 
			end
		end
	end

	if (N_args == n_prev)		# No cpt transmitted, so need to compute one
		if (GMTver >= 7)		# 7 because this solution is currently still bugged
			#=
			if (mz !== nothing)
				arg2 = gmt("makecpt -E " * cmd[len+2:end], mz[:])
			else
				if (isa(arg1, Array))  arg2 = gmt("makecpt -E " * cmd[len+2:end], arg1)
				else                   arg2 = gmt("makecpt -E " * cmd[len+2:end], arg1.data)
				end
			end
			=#
		else
			if (mz !== nothing)               mi, ma = extrema(mz)
			else
				if     (isa(arg1, Array))     mi, ma = extrema(view(arg1, :, 2+is3D))
				elseif (isa(arg1,GMTdataset)) mi, ma = extrema(view(arg1.data, :, 2+is3D))
				else                          mi, ma = extrema(view(arg1[1].data, :, 2+is3D))
				end
			end
			just_C = cmd[len+2:end];	reset_i = ""
			if ((ind = findfirst(" -i", just_C)) !== nothing)
				reset_i = just_C[ind[1]:end] 
				just_C  = just_C[1:ind[1]-1]
			end
			arg2 = gmt(string("makecpt -T", mi-0.001*abs(mi), '/', ma+0.001*abs(ma), " ", just_C))
			if (occursin(" -C", cmd))  cmd = cmd[1:len+3]  end		# Strip the cpt name
			if (reset_i != "")  cmd *= reset_i  end		# Reset -i, in case it existed
		end
		if (!occursin(" -C", cmd))  cmd *= " -C"  end	# Need to inform that there is a cpt to use
		N_args = 2
	end

	@label noway

	return cmd, arg1, arg2, N_args, true
end

# ---------------------------------------------------------------------------------------------------
function get_marker_name(d::Dict, symbs, is3D, del=false, arg1=nothing)
	marca = "";		N = 0
	for symb in symbs
		if (haskey(d, symb))
			t = d[symb]
			if (isa(t, Tuple))				# e.g. marker=(:r, [2 3])
				msg = "";	cst = false
				o = string(t[1])
				if     (startswith(o, "E"))  opt = "E";  N = 3; cst = true
				elseif (startswith(o, "e"))  opt = "e";  N = 3
				elseif (o == "J" || startswith(o, "Rot"))  opt = "J";  N = 3; cst = true
				elseif (o == "j" || startswith(o, "rot"))  opt = "j";  N = 3
				elseif (o == "M" || startswith(o, "Mat"))  opt = "M";  N = 3
				elseif (o == "m" || startswith(o, "mat"))  opt = "m";  N = 3
				elseif (o == "R" || startswith(o, "Rec"))  opt = "R";  N = 3
				elseif (o == "r" || startswith(o, "rec"))  opt = "r";  N = 2
				elseif (o == "V" || startswith(o, "Vec"))  opt = "V";  N = 2
				elseif (o == "v" || startswith(o, "vec"))  opt = "v";  N = 2
				elseif (o == "w" || o == "pie" || o == "web" || o == "wedge")  opt = "w";  N = 2
				elseif (o == "W" || o == "Pie" || o == "Web" || o == "Wedge")  opt = "W";  N = 2
				end
				if (N > 0)  marca, arg1, msg = helper_markers(opt, t[2], arg1, N, cst)  end
				if (msg != "")  error(msg)  end
				if (length(t) == 3 && isa(t[3], NamedTuple))
					if (marca == "w" || marca == "W")	# Ex (spiderweb): marker=(:pie, [...], (inner=1,)) 
						marca *= add_opt(t[3], (inner="/", arc="+a", radial="+r", size=("", arg2str, 1), pen=("+p", add_opt_pen)) )
					elseif (marca == "m" || marca == "M")
						marca *= vector_attrib(t[3])
					end
				end
			elseif (isa(t, NamedTuple))		# e.g. marker=(pie=true, inner=1, ...)
				key = keys(t)[1];	opt = ""
				if     (key == :w || key == :pie || key == :web || key == :wedge)  opt = "w"
				elseif (key == :W || key == :Pie || key == :Web || key == :Wedge)  opt = "W"
				elseif (key == :b || key == :bar)     opt = "b"
				elseif (key == :B || key == :HBar)    opt = "B"
				elseif (key == :l || key == :letter)  opt = "l"
				elseif (key == :K || key == :Custom)  opt = "K"
				elseif (key == :k || key == :custom)  opt = "k"
				elseif (key == :M || key == :Matang)  opt = "M"
				elseif (key == :m || key == :matang)  opt = "m"
				end
				if (opt == "w" || opt == "W")
					marca = opt * add_opt(t, (size=("", arg2str, 1), inner="/", arc="+a", radial="+r", pen=("+p", add_opt_pen)))
				elseif (opt == "b" || opt == "B")
					marca = opt * add_opt(t, (size=("", arg2str, 1), base="+b", Base="+B"))
				elseif (opt == "l")
					marca = opt * add_opt(t, (size=("", arg2str, 1), letter="+t", justify="+j", font=("+f", font)))
				elseif (opt == "m" || opt == "M")
					marca = opt * add_opt(t, (size=("", arg2str, 1), arrow=("", vector_attrib)))
				elseif (opt == "k" || opt == "K")
					marca = opt * add_opt(t, (custom="", size="/"))
				end
			else
				if (isa(t, Symbol))	t = string(t)	end
				if     (t == "-" || t == "x-dash")    marca = "-"
				elseif (t == "+" || t == "plus")      marca = "+"
				elseif (t == "a" || t == "*" || t == "star")  marca = "a"
				elseif (t == "k" || t == "custom")    marca = "k"
				elseif (t == "x" || t == "cross")     marca = "x"
				elseif (t[1] == 'c' || t[1] == 'C')   marca = "c"
				elseif (t == "d" || t == "diamond")   marca = "d"
				elseif (t == "g" || t == "octagon")   marca = "g"
				elseif (t == "h" || t == "hexagon")   marca = "h"
				elseif (t == "i" || t == "v" || t == "inverted_tri")  marca = "i"
				elseif (t == "l" || t == "letter")    marca = "l"
				elseif (t == "n" || t == "pentagon")  marca = "n"
				elseif (t == "p" || t == "." || t == "point")  marca = "p"
				elseif (t == "s" || t == "square")    marca = "s"
				elseif (t == "t" || t == "^" || t == "triangle")  marca = "t"
				elseif (t == "T" || t == "Triangle")  marca = "T"
				elseif (is3D && (t == "u" || t == "cube"))  marca = "u"
				elseif (t == "y" || t == "y-dash")    marca = "y"
				end
				# Still need to check the simpler forms of these
				if (marca == "")  marca = helper2_markers(t, ["e" "ellipse"])   end
				if (marca == "")  marca = helper2_markers(t, ["E" "Ellipse"])   end
				if (marca == "")  marca = helper2_markers(t, ["j" "rotrect"])   end
				if (marca == "")  marca = helper2_markers(t, ["J" "RotRect"])   end
				if (marca == "")  marca = helper2_markers(t, ["m" "matangle"])  end
				if (marca == "")  marca = helper2_markers(t, ["M" "Matangle"])  end
				if (marca == "")  marca = helper2_markers(t, ["r" "rectangle"])   end
				if (marca == "")  marca = helper2_markers(t, ["R" "RRectangle"])  end
				if (marca == "")  marca = helper2_markers(t, ["v" "vector"])  end
				if (marca == "")  marca = helper2_markers(t, ["V" "Vector"])  end
				if (marca == "")  marca = helper2_markers(t, ["w" "pie" "web"])  end
				if (marca == "")  marca = helper2_markers(t, ["W" "Pie" "Web"])  end
			end
			if (del)  delete!(d, symb)  end
			break
		end
	end
	return marca, arg1, N > 0
end

function helper_markers(opt, ext, arg1, N, cst)
	# Helper function to deal with the cases where one sends marker's extra columns via command
	# Example that will land and be processed here:  marker=(:Ellipse, [30 10 15])
	# N is the number of extra columns
	marca = "";		msg = ""
	if (size(ext,2) == N && arg1 !== nothing)
		S = Symbol(opt)
		marca, arg1 = add_opt(add_opt, (opt, "", Dict(S => (par=ext,)), [S]), (par="|",), true, arg1)
	elseif (cst && length(ext) == 1)
		marca = opt * "-" * string(ext)
	else
		msg = string("Wrong number of extra columns for marker (", opt, "). Got ", size(ext,2), " but expected ", N)
	end
	return marca, arg1, msg
end

function helper2_markers(opt, alias)
	marca = ""
	if (opt == alias[1])			# User used only the one letter syntax
		marca = alias[1]
	else
		for k = 2:length(alias)		# Loop because of cases like ["w" "pie" "web"] 
			o2 = alias[k][1:min(2,length(alias[k]))]	# check the first 2 chars and Ro, Rotrect or RotRec are all good
			if (startswith(opt, o2))  marca = alias[1]; break  end		# Good when, for example, marker=:Pie
		end
	end

	# If we still have found nothing, assume that OPT is a full GMT opt string (e.g. W/5+a30+r45+p2,red)
	if (marca == "" && opt[1] == alias[1][1])  marca = opt  end
	return marca
end

# ---------------------------------------------------------------------------------------------------
function check_caller(d::Dict, cmd::String, opt_S::String, opt_W::String, caller::String, O::Bool)
	# Set sensible defaults for the sub-modules "scatter" & "bar"
	if (caller == "scatter")
		if (opt_S == "")  cmd *= " -Sc7p"  end
	elseif (caller == "scatter3")
		if (opt_S == "")  cmd *= " -Su7p"  end
	elseif (caller == "lines")
		if (!occursin("+p", cmd) && opt_W == "") cmd *= " -W0.25p"  end # Do not leave without a pen specification
	elseif (caller == "bar")
		if (opt_S == "")
			if (haskey(d, :bar))
				cmd = GMT.parse_bar_cmd(d, :bar, cmd, "Sb")
			elseif (haskey(d, :hbar))
				cmd = GMT.parse_bar_cmd(d, :hbar, cmd, "SB")
			else
				opt = add_opt("", "",  d, [:width])		# No need to purge because width is not a psxy option
				if (opt == "")	opt = "0.8"	end			# The default
				cmd *= " -Sb" * opt * "u"

				optB = add_opt("", "",  d, [:base])
				if (optB == "")	optB = "0"	end
				cmd *= "+b" * optB
			end
		end
		if (!occursin(" -G", cmd) && !occursin(" -C", cmd))  cmd *= " -G0/115/190"	end		# Default color
	elseif (caller == "bar3")
		if (haskey(d, :noshade) && occursin("-So", cmd))
			cmd = replace(cmd, "-So" => "-SO", count=1)
		end
		if (!occursin(" -G", cmd) && !occursin(" -C", cmd))  cmd *= " -G0/115/190"	end	
		if (!occursin(" -J", cmd))  cmd *= " -JX12c/0"  end
	end

	if (occursin('3', caller))
		if (!occursin(" -B", cmd) && !O)  cmd *= def_fig_axes3  end	# For overlays default is no axes
		if (!occursin(" -p", cmd))  cmd *= " -p200/30"  end
	#else
		#if (!occursin(" -B", cmd) && !O)  cmd *= def_fig_axes   end
	end

	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_bar_cmd(d::Dict, key::Symbol, cmd::String, optS::String, no_u=false)
	# Deal with parsing the 'bar' & 'hbar' keywors of psxy. Also called by plot/bar3. For this
	# later module if input is not a string or NamedTuple the scatter options must be processed in bar3().
	# KEY is either :bar or :hbar
	# OPTS is either "Sb", "SB" or "So"
	# NO_U if true means to NO automatic adding of flag 'u'
	opt =""
	if (haskey(d, key))
		if (isa(d[key], String))
			cmd *= " -" * optS * d[key]
		elseif (isa(d[key], NamedTuple))
			opt = add_opt("", optS, d, [key], (width="",unit="1",base="+b",height="+B",nbands="+z",Nbands="+Z"))
		else
			error("Argument of the *bar* keyword can be only a string or a NamedTuple.")
		end
	end

	if (opt != "")				# Still need to finish parsing this
		flag_u = no_u ? "" : 'u' 
		if ((ind = findfirst("+", opt)) !== nothing)	# See if need to insert a 'u'
			if (!isletter(opt[ind[1]-1]))  opt = opt[1:ind[1]-1] * flag_u * opt[ind[1]:end]  end
		else
			pb = (optS != "So") ? "+b0" : ""		# The default for bar3 (So) is set in the bar3() fun
			if (!isletter(opt[end]))  opt *= flag_u	  end	# No base set so default to ...
			opt *= pb
		end
		cmd *= opt
	end
	return cmd
end