const psxy  = plot
const psxy! = plot!
const psxyz  = plot3d
const psxyz! = plot3d!

# ---------------------------------------------------------------------------------------------------
function common_plot_xyz(cmd0, arg1, caller, first, is3D, kwargs...)
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
			#caller = ""				# Because of parse_BJR()
		end
	end

	d = KW(kwargs)
	output, opt_T, fname_ext, K, O = fname_out(d, first)		# OUTPUT may have been an extension only

	if (!occursin("-J", cmd))			# bar, bar3 and others may send in a -J
		opt_J = " -JX" * def_fig_size
		if ((val = find_in_dict(d, [:aspect :axis])[1]) !== nothing)
			if (val == "equal" || val == :equal)	# Need also a 'tight' option?
				if ((ind = findfirst("/", opt_J)) !== nothing)	# Already had something in height
					opt_J = opt_J[1:ind[1]-1] * "/0"
				else
					opt_J = " -JX12c/0"
				end
			end
		end
	else
		opt_J = ""
	end

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd, caller, O, opt_J)
	if (is3D)	cmd,opt_JZ = parse_JZ(cmd, d)	end
	cmd = parse_common_opts(d, cmd, [:a :e :f :g :p :t :yx :params], first)
	cmd = parse_these_opts(cmd, d, [[:D :shift :offset], [:F :conn :connection], [:I :intens], [:N :noclip :no_clip]])
	if (is_ternary)  cmd = add_opt(cmd, 'M', d, [:M :no_plot])  end
	opt_UVXY = parse_UVXY("", d)	# Need it separate to not risk to double include it.

	# If a file name sent in, read it and compute a tight -R if this was not provided
	if (opt_R == "" && sub_module == "bar")  opt_R = "///0"  end	# Make sure y_min = 0
	cmd, arg1, opt_R, opt_i = read_data(d, cmd0, cmd, arg1, opt_R, is3D)
	
	if (is3D && isempty(opt_JZ) && length(collect(eachmatch(r"/", opt_R))) == 5)
		cmd *= " -JZ6c"		# Default -JZ
	end

	cmd = add_opt(cmd, 'A', d, [:A :steps :straight_lines], (x="x", y="y", meridian="m", parallel="p"))

	# Error Bars?
	if ((val = find_in_dict(d, [:E :error :error_bars])[1]) !== nothing)
		n_rows, n_cols = size(arg1)
		arg1 = reshape(arg1, :)				# Crazzy shit to allow increasing the arg1 matrix
		cmd = add_opt(cmd, 'E', d, [:E :error :error_bars],
					  (x="|x",y="|y",xy="|xy",X="|X",Y="|Y",asym="+a",cline="+cl",csymbol="+cf",
					   wiskers="|+n",cap="+w",pen=("+p",add_opt_pen)), false, arg1)
		arg1 = reshape(arg1, n_rows, :)
	end

	# Look for color request. Do it after error bars because they may add a column
	len = length(cmd);	n_prev = N_args;
	cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1)

	# See if we got a CPT. If yes there may be some work to do if no color column provided in input data.
	cmd, arg1, arg2, N_args, mcc = make_color_column(d, cmd, opt_i, len, N_args, n_prev, is3D, arg1, arg2)

	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	opt_Gsymb = add_opt_fill("", d, [:G :markerfacecolor :MarkerFaceColor :mc], 'G')		# Filling of symbols

	# To track a still existing bug in sessions management at GMT lib level
	if (occursin("-Gp", cmd) || occursin("-GP", cmd) || occursin("-Gp", opt_Gsymb) || occursin("-GP", opt_Gsymb))
		got_pattern = true
	else
		got_pattern = false
	end

	if (is_ternary)			# Means we are in the psternary mode
		cmd = add_opt(cmd, 'L', d, [:L :labels])
	else
		cmd = add_opt(cmd, 'L', d, [:L :close],
			(left="+xl", right="+xr", bot="+yb", top="+yt", sym="+d", asym="+D", envelope="+b",
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
		marca = get_marker_name(d, [:marker :Marker :shape], is3D)
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
		elseif (marca != "")			# User only selected a marker name but no size.
			opt_S = " -S" * marca * "7p"
		end
	end

	opt_ML = ""
	if (opt_S != "")
		if ((val = find_in_dict(d, [:markerline :MarkerLine])[1]) !== nothing)
			if (isa(val, Tuple))  opt_ML = " -W" * parse_pen(val) # This can hold the pen, not extended atts
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
	cmd = check_caller(d, cmd, opt_S, sub_module, O)

	if (occursin(" -B0", cmd))  cmd = replace(cmd, " -B0" => "")  end	# -B0 really means NO AXES

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
			if (opt_ML != "")  cmd1 = cmd1 * opt_ML  end	# If we have a symbol outline pen
			cmd = [finish_PS(d, cmd1, output, true, O); finish_PS(d, cmd2, output, K, true)]
		end

	elseif (opt_S != "" && opt_ML != "")					# We have a symbol outline pen
		cmd = finish_PS(d, cmd * opt_ML * opt_S * opt_Gsymb * opt_UVXY, output, K, O)

	else
		cmd = finish_PS(d, cmd * opt_UVXY, output, K, O)
	end

	# Let matrices with more data columns, and for which no Color info was NOT set, plot multiple lines at once
	if (!mcc && opt_S == "" && (caller == "lines" || caller == "plot") && isa(arg1, Array{Float64,2}) && size(arg1,2) > 2+is3D)
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
	if (got_pattern)  gmt("destroy")  end 	# Apparently patterns are screweing the session
	return r
end

# ---------------------------------------------------------------------------------------------------
function make_color_column(d, cmd, opt_i, len, N_args, n_prev, is3D, arg1, arg2)
	# See if we got a CPT. If yes, there is quite some work to do if no color column provided in input data.

	if (isempty_(arg1))  return cmd, arg1, arg2, N_args, false  end		# Just play safe

	mz, the_kw = find_in_dict(d, [:zcolor :markerz :mz])
	if (!(N_args > n_prev || len < length(cmd)) && mz === nothing)	# No color request, so return right away
		return cmd, arg1, arg2, N_args, false
	end

	if (isa(arg1, Array))          n_rows, n_col = size(arg1)
	elseif (isa(arg1,GMTdataset))  n_rows, n_col = size(arg1.data)
	else                           n_rows, n_col = size(arg1[1].data)
	end

	warn1 = string("Probably color column in ", the_kw, " has incorrect dims. Ignoring it.")
	warn2 = "Plotting with color table requires adding one more column to the dataset but your -i
	option didn't do it, so you won't get waht you expect. Try -i0-1,1 for 2D or -i0-2,2 for 3D plots"

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
	elseif (n_col > 2+is3D)
		if (mz !== nothing)			# Here we must insert the color col right after the coords
			if (length(mz) != n_rows)  @warn(warn1); @goto noway  end
			if     (isa(arg1, Array))      arg1 = hcat(arg1[:,1:2+is3D], mz[:], arg1[:,3+is3D:end])
			elseif (isa(arg1,GMTdataset))  arg1.data = hcat(arg1.data[:,1:2+is3D], mz[:], arg1.data[:,3+is3D:end])
			else                           arg1[1].data = hcat(arg1[1].data[:,1:2+is3D], mz[:], arg1[1].data[:,3+is3D:end])
			end
		else
			if (opt_i == "")  cmd = @sprintf("%s -i0-%d,%d,%d-%d", cmd, 1+is3D, 1+is3D, 2+is3D, n_col-1)
			else              @warn(warn2);		@goto noway 
			end
		end
	end

	if (N_args == n_prev)		# No cpt transmitted, so need to compute one
		if (GMTver >= 8)		# 7 because this solution is currently still bugged
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
function get_marker_name(d::Dict, symbs, is3D=false, del=false)
	marca = ""
	for symb in symbs
		if (haskey(d, symb))
			t = d[symb]
			if (isa(t, Symbol))	t = string(t)	end
			if     (t == "-" || t == "x-dash")   marca = "-"
			elseif (t == "+" || t == "plus")     marca = "+"
			elseif (t == "a" || t == "*" || t == "star")     marca = "a"
			elseif (t == "c" || t == "circle")   marca = "c"
			elseif (t == "d" || t == "diamond")  marca = "d"
			elseif (t == "g" || t == "octagon")  marca = "g"
			elseif (t == "h" || t == "hexagon")  marca = "h"
			elseif (t == "i" || t == "v" || t == "inverted_tri")  marca = "i"
			elseif (t == "n" || t == "pentagon")  marca = "n"
			elseif (t == "p" || t == "." || t == "point")     marca = "p"
			elseif (t == "r" || t == "rectangle") marca = "r"
			elseif (t == "s" || t == "square")    marca = "s"
			elseif (t == "t" || t == "^" || t == "triangle")  marca = "t"
			elseif (t == "x" || t == "cross")     marca = "x"
			elseif (is3D && (t == "u" || t == "cube"))  marca = "u"
			elseif (t == "y" || t == "y-dash")    marca = "y"
			end
			if (del)  delete!(d, symb)  end
			break
		end
	end
	return marca
end

# ---------------------------------------------------------------------------------------------------
function check_caller(d::Dict, cmd::String, opt_S::String, caller::String, O::Bool)
	# Set sensible defaults for the sub-modules "scatter" & "bar"
	if (caller == "scatter")
		if (opt_S == "")  cmd *= " -Sc7p"  end
	elseif (caller == "scatter3")
		if (opt_S == "")  cmd *= " -Su7p"  end
	elseif (caller == "lines")
		if (!occursin("+p", cmd)) cmd *= " -W0.25p"  end # Do not leave without a pen specification
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
	else
		if (!occursin(" -B", cmd) && !O)  cmd *= def_fig_axes   end
	end

	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_bar_cmd(d::Dict, key::Symbol, cmd::String, optS::String)
	# Deal with parsing the 'bar' & 'hbar' keywors of psxy. Also called by plot/bar3. For this
	# later module if input is not a string or NamedTuple the scatter options must be processed in bar3().
	# KEY is either :bar or :hbar
	# OPTS is either "Sb", "SB" or "So"
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
		if ((ind = findfirst("+", opt)) !== nothing)	# See if need to insert a 'u'
			if (!isletter(opt[ind[1]-1]))  opt = opt[1:ind[1]-1] * 'u' * opt[ind[1]:end]  end
		else
			pb = (optS != "So") ? "+b0" : ""		# The default for bar3 (So) is set in the bar3() fun
			if (!isletter(opt[end]))  opt *= 'u' * pb	# No base set so default to ...
			else                      opt *= pb
			end
		end
		cmd *= opt
	end
	return cmd
end