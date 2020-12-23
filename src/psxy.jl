const psxy  = plot
const psxy! = plot!
const psxyz  = plot3d
const psxyz! = plot3d!

# ---------------------------------------------------------------------------------------------------
function common_plot_xyz(cmd0, arg1, caller::String, first::Bool, is3D::Bool, kwargs...)
	arg3 = nothing
	N_args = (arg1 === nothing) ? 0 : 1
	is_ternary = (caller == "ternary") ? true : false
	if     (is3D)       gmt_proggy = (IamModern[1]) ? "plot3d "  : "psxyz "
	elseif (is_ternary) gmt_proggy = (IamModern[1]) ? "ternary " : "psternary "
	else		        gmt_proggy = (IamModern[1]) ? "plot "    : "psxy "
	end

	(occursin(" -", cmd0)) && return monolitic(gmt_proggy, cmd0, arg1)

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd = "";	sub_module = ""			# Will change to "scatter", etc... if called by sub-modules
	g_bar_fill = nothing				# May hold a sequence of colors for gtroup Bar plots
	if (caller != "")
		if (occursin(" -", caller))		# some sub-modues use this piggy-backed call
			if ((ind = findfirst("|", caller)) !== nothing)	# A mixed case with "caler|partiall_command"
				sub_module = caller[1:ind[1]-1]
				cmd = caller[ind[1]+1:end]
				caller = sub_module		# Because of parse_BJR()
				if (caller == "events")  gmt_proggy = "events "  end
			else
				cmd = caller
				caller = "others"		# It was piggy-backed
			end
		else
			sub_module = caller
			if (sub_module == "bar")	# Needs to be processed here to destinguish from the more general 'fill'
				gval = find_in_dict(d, [:fill :fillcolor], false)[1]	# Used for group colors
				if     (isa(gval, Array{String}) && length(gval) > 1)  g_bar_fill = gval	# Given an array of fills
				elseif ((isa(gval, Array{Int}) || (isa(gval, Tuple)) && eltype(gval) == Int) && length(gval) > 1)
					g_bar_fill = Vector{String}(undef, length(gval))			# Patterns
					[g_bar_fill[k] = string('p',gval[k]) for k = 1:length(gval)]
				end
			end
		end
	end

	def_J = (is_ternary) ? " -JX12c/0" : ""
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd, caller, O, def_J)
	if (is3D)	cmd, opt_JZ  = parse_JZ(d, cmd)  end
	cmd, = parse_common_opts(d, cmd, [:a :e :f :g :l :p :t :params], first)
	cmd  = parse_these_opts(cmd, d, [[:D :shift :offset], [:I :intens], [:N :no_clip :noclip]])
	if (is_ternary)  cmd = add_opt(d, cmd, 'M', [:M :no_plot])  end
	opt_UVXY = parse_UVXY(d, "")	# Need it separate to not risk to double include it.
	cmd, opt_c = parse_c(d, cmd)	# Need opt_c because we may need to remove it from double calls

	# If a file name sent in, read it and compute a tight -R if this was not provided
	got_usr_R = (opt_R != "") ? true : false		# To know is the user set -R or we guessed it from data
	if (opt_R == "" && sub_module == "bar")  opt_R = "/-0.4/0.4/0"  end	# Make sure y_min = 0
	if (O && caller == "plotyy")
		cmd = replace(cmd, opt_R => "")			# Must remove old opt_R because a new one will be constructed
		ind = collect(findall("/", box_str[1])[2])		# 'box_str' was set in first call
		opt_R = '/' * box_str[1][4:ind[1]] * "?/?"	# Will become /x_min/x_max/?/?
	end
	cmd, arg1, opt_R, lixo, opt_i = read_data(d, cmd0, cmd, arg1, opt_R, is3D)
	if (N_args == 0 && arg1 !== nothing)  N_args = 1  end
	(!O && caller == "plotyy") && (box_str[1] = opt_R)	# This needs modifications (in plotyy) by second call

	if ((isa(arg1, GMTdataset) && arg1.proj4 != "" || isa(arg1, Vector{GMTdataset}) &&
		     arg1[1].proj4 != "") && opt_J == " -JX" * def_fig_size)
		cmd = replace(cmd, opt_J => "-JX12c/0")		# If projected, it's a axis equal for sure
	end
	if (is3D && isempty(opt_JZ) && length(collect(eachmatch(r"/", opt_R))) == 5)
		cmd *= " -JZ6c"		# Default -JZ
	end

	cmd = add_opt(d, cmd, 'A', [:A :steps :straight_lines], (x="x", y="y", meridian="m", parallel="p"))
	opt_F = add_opt(d, "", "", [:F :conn :connection],
	                (continuous=("c", nothing, 1), net=("n", nothing, 1), network=("n", nothing, 1), refpoint=("r", nothing, 1),  ignore_hdr="_a", single_group="_f", segments="_s", segments_reset="_r", anchor=("", arg2str)))
	if (length(opt_F) > 1 && !occursin("/", opt_F))  opt_F = opt_F[1]  end	# Allow con=:net or con=(1,2)
	if (opt_F != "")  cmd *= " -F" * opt_F  end

	# Error Bars?
	got_Ebars = false
	val, symb = find_in_dict(d, [:E :error :error_bars], false)
	if (val !== nothing)
		cmd, arg1 = add_opt(add_opt, (d, cmd, 'E', [symb]),
                            (x="|x",y="|y",xy="|xy",X="|X",Y="|Y", asym="_+a", colored="_+c", cline="_+cl", csymbol="_+cf", wiskers="|+n",cap="+w",pen=("+p",add_opt_pen)), false, isa(arg1, GMTdataset) ? arg1.data : (isa(arg1, Array{GMTdataset}) ? arg1[1].data : arg1) )
		got_Ebars = true
		del_from_dict(d, [symb])
	end

	# Look for color request. Do it after error bars because they may add a column
	len = length(cmd);	n_prev = N_args;
	cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1)
	#cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1, nothing, true, true, "", true)

	cmd, args, n, got_Zvars = add_opt(d, cmd, 'Z', [:Z :level], :data, [arg1, arg2, arg3], (outline="_+l", fill="_+f"))
	if (n > 0)
		arg1, arg2, arg3 = args[:]
		N_args = n
	end

	mcc = false
	if (!got_Zvars)									# Otherwise we don't care about color columns
		# See if we got a CPT. If yes there may be some work to do if no color column provided in input data.
		cmd, arg1, arg2, N_args, mcc = make_color_column(d, cmd, opt_i, len, N_args, n_prev, is3D, got_Ebars, arg1, arg2)
	end

	if (g_bar_fill === nothing)						# Otherwise bar fill colors are dealt somewhere else
		cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	end
	opt_Gsymb = add_opt_fill("", d, [:G :markerfacecolor :MarkerFaceColor :mc], 'G')	# Filling of symbols

	# To track a still existing bug in sessions management at GMT lib level
	got_pattern = false
	if (occursin("-Gp", cmd) || occursin("-GP", cmd) || occursin("-Gp", opt_Gsymb) || occursin("-GP", opt_Gsymb))
		got_pattern = true
	end

	if (is_ternary)			# Means we are in the psternary mode
		cmd = add_opt(d, cmd, 'L', [:L :labels])
	else
		opt_L = add_opt(d, "", 'L', [:L :close :polygon],
		                (left="_+xl", right="_+xr", x0="+x", bot="_+yb", top="_+yt", y0="+y", sym="_+d", asym="_+D", envelope="_+b", pen=("+p",add_opt_pen)))
		if (length(opt_L) > 3 && !occursin("-G", cmd) && !occursin("+p", cmd))  opt_L *= "+p0.5p"  end
		cmd *= opt_L
	end

	opt_Wmarker = ""
	if ((val = find_in_dict(d, [:markeredgecolor :MarkerEdgeColor])[1]) !== nothing)
		opt_Wmarker = "0.5p," * arg2str(val)		# 0.25p is too thin?
	end

	opt_W = add_opt_pen(d, [:W :pen], "W", true)     # TRUE to also seek (lw,lc,ls)
	if ((occursin("+c", opt_W) || occursin("+c", cmd)) && !occursin("-C", cmd))
		@warn("Color lines (or fill) from a color scale was selected but no color scale provided. Expect ...")
	end

	opt_S = add_opt(d, "", 'S', [:S :symbol], (symb="1", size="", unit="1"))
	if (opt_S == "")			# OK, no symbol given via the -S option. So fish in aliases
		marca, arg1, more_cols = get_marker_name(d, [:marker :Marker :shape], is3D, true, arg1)
		if ((val = find_in_dict(d, [:markersize :MarkerSize :ms :size])[1]) !== nothing)
			if (marca == "")  marca = "c"  end		# If a marker name was not selected, defaults to circle
			if (isa(val, AbstractArray))
				(length(val) != size(arg1,1)) &&
					error("The size array must have the same number of elements rows in the data")
				arg1 = hcat(arg1, val[:])
				#arg1 = hcat(arg1, convert(eltype(arg1), val[:]))
			elseif (string(val) != "indata")
				marca *= arg2str(val);
			end
			opt_S = " -S" * marca
		elseif (marca != "")		# User only selected a marker name but no size.
			opt_S = " -S" * marca
			# If data comes from a file, then no automatic symbol size is added
			op = lowercase(marca[1])
			def_size = (op == 'p') ? "3p" : "7p"	# 'p' here stands for symbol points, not units
			if (!more_cols && arg1 !== nothing && !isa(arg1, GMTcpt) && !occursin(op, "bekmrvw"))  opt_S *= def_size  end
		end
	else
		val, symb = find_in_dict(d, [:markersize :MarkerSize :ms :size])
		(val !== nothing) && @warn("option *$(symb)* is ignored when either *S* or *symbol* options are used")
		val, symb = find_in_dict(d, [:marker :Marker :shape])
		(val !== nothing) && @warn("option *$(symb)* is ignored when either *S* or *symbol* options are used")
	end

	opt_ML = ""
	if (opt_S != "")
		if ((val = find_in_dict(d, [:markerline :MarkerLine :ml])[1]) !== nothing)
			if (isa(val, Tuple))  opt_ML = " -W" * parse_pen(val) # This can hold the pen, not extended atts
			elseif (isa(val, NamedTuple))  opt_ML = add_opt_pen(nt2dict(val), [:pen], "W")
			else                  opt_ML = " -W" * arg2str(val)
			end
			if (opt_Wmarker != "")
				@warn("markerline overrides markeredgecolor");		opt_Wmarker = ""
			end
		end
		(opt_W != "" && opt_ML != "") && @warn("You cannot use both markerline and W or pen keys.")
	end

	# See if any of the scatter, bar, lines, etc... was the caller and if yes, set sensible defaults.
	cmd = check_caller(d, cmd, opt_S, opt_W, sub_module, g_bar_fill, O)

	if (opt_W != "" && opt_S == "") 						# We have a line/polygon request
		cmd *= opt_W * opt_UVXY

	elseif (opt_W == "" && opt_S != "")						# We have a symbol request
		if (opt_Wmarker != "" && opt_W == "") opt_Gsymb *= " -W" * opt_Wmarker  end		# reuse var name
		if (opt_ML != "")  cmd *= opt_ML  end				# If we have a symbol outline pen
		cmd *= opt_S * opt_Gsymb * opt_UVXY

	elseif (opt_W != "" && opt_S != "")						# We have both line/polygon and a symbol
		if (occursin(opt_Gsymb, cmd))  opt_Gsymb = ""  end
		if (opt_S[4] == 'v' || opt_S[4] == 'V' || opt_S[4] == '=')
			cmd *= opt_W * opt_S * opt_Gsymb * opt_UVXY
		else
			if (opt_Wmarker != "")  opt_Wmarker = " -W" * opt_Wmarker  end		# Set Symbol edge color
			cmd1 = cmd * opt_W * opt_UVXY
			cmd2 = replace(cmd, opt_B => "") * opt_S * opt_Gsymb * opt_Wmarker	# Don't repeat option -B
			if (opt_c != "")  cmd2 = replace(cmd2, opt_c => "")  end			# Not in scond call (subplots)
			if (opt_ML != "")  cmd1 = cmd1 * opt_ML  end	# If we have a symbol outline pen
			cmd = [cmd1; cmd2]
		end

	else
		cmd *= opt_UVXY
	end

	# Let matrices with more data columns, and for which Color info was NOT set, plot multiple lines at once
	if (!mcc && opt_S == "" && (caller == "lines" || caller == "plot") && isa(arg1, Array{<:Real,2}) && size(arg1,2) > 2+is3D && size(arg1,1) > 1 && (multi_col[1] || haskey(d, :multicol)) )
		multi_col[1] = false						# Reset because this is a use-only-once option
		penC = "";		penS = "";	cycle=:cycle
		# But if we have a color in opt_W (idiotic) let it overrule the automatic color cycle in mat2ds()
		if (opt_W != "")  penT, penC, penS = break_pen(scan_opt(opt_W, "-W"))  end
		if (penC  != "")  cycle = [penC]  end
		arg1 = mat2ds(arg1, color=cycle, ls=penS, multi=true)	# Convert to multi-segment GMTdataset
		D = gmt("gmtinfo -C", arg1)					# But now also need to update the -R string
		if (isa(cmd, Array))						# Replace old -R by the new one
			cmd[1] = replace(cmd[1], opt_R => " -R" * arg2str(round_wesn(D[1].data)))
		else
			cmd = replace(cmd, opt_R => " -R" * arg2str(round_wesn(D[1].data)))
		end
	#elseif (sub_module == "bar" && ((isa(arg1, Array{<:Real,2}) && size(arg1,2) > 2) || haskey(d, :stacked)) )
	elseif (sub_module == "bar")
		cmd, arg1 = bar_group(d, cmd, opt_R, g_bar_fill, got_Ebars, got_usr_R, arg1)
	end

	(!IamModern[1]) && put_in_legend_bag(d, cmd, arg1)

	cmd = gmt_proggy .* cmd				# In any case we need this
	cmd, K = finish_PS_nested(d, cmd, K, O)

	r = finish_PS_module(d, cmd, "", K, O, true, arg1, arg2, arg3)
	(got_pattern || occursin("-Sk", opt_S)) && gmt("destroy")  # Apparently patterns are screweing the session
	return r
end

# ---------------------------------------------------------------------------------------------------
function bar_group(d::Dict, cmd::String, opt_R::String, g_bar_fill, got_Ebars::Bool, got_usr_R::Bool, arg1)
	# Convert input array into a multi-segment Dataset where each segment is an element of a bar group
	# Example, plot two groups of 3 bars each: bar([0 1 2 3; 1 2 3 4], xlabel="BlaBla")
	if !( isa(arg1, Array{<:Real,2}) || (eltype(arg1) <: GMTdataset &&
		 (isa(arg1, Array{GMTdataset}) ? size(arg1[1],2) > 2 : size(arg1,2))) )
		return cmd, arg1		# No group bars, just plain bars
	end

	if (got_Ebars)
		opt_E = scan_opt(cmd, "-E")
		((ind = findfirst("+", opt_E)) !== nothing) && (opt_E = opt_E[1:ind[1]-1])	# Strip eventual modifiers
		(((ind = findfirst("X", opt_E)) !== nothing) || ((ind = findfirst("Y", opt_E)) !== nothing)) && return cmd, arg1
		n_xy_bars = (findfirst("x", opt_E) !== nothing) + (findfirst("y", opt_E) !== nothing)
		n_cols = size(arg1,2)
		((n_cols - n_xy_bars) == 2) && return cmd, arg1			# Only one-bar groups
		(iseven(n_cols)) && error("Wrong number of columns in error bars array (or prog error)")
		n = Int((n_cols - 1) / 2)
		_arg = arg1[:, 1:(n+1)]				# No need to care with GMTdatasets because case was dealt in 'got_Ebars'
		bars_cols = arg1[:,(n + 2):end]		# We'll use this to appent to the multi-segments
	else
		_arg = isa(arg1, GMTdataset) ? deepcopy(arg1.data) : (isa(arg1, Array{GMTdataset}) ? deepcopy(arg1[1].data) : deepcopy(arg1))
		bars_cols = nothing
	end

	do_multi = true;	do_bar_stack = false		# True for grouped; false for stacked groups
	if ((val = find_in_dict(d, [:stack :stacked])[1]) !== nothing)
		# Take this (two groups of 3 bars) [0 1 2 3; 1 2 3 4]  and compute this (the same but stacked)
		# [0 1 0; 0 3 1; 0 6 3; 1 2 0; 1 5 2; 1 9 4]
		nl = size(_arg,2)-1				# N layers in stack
		tmp = zeros(size(_arg,1)*nl, 3)

		for m = 1:size(_arg, 1)			# Loop over number of groups
			tmp[(m-1)*nl+1,1] = _arg[m,1];		tmp[(m-1)*nl+1,2] = _arg[m,2];	# 3rd col is zero
			for n = 2:nl				# Loop over number of layers (n bars in a group)
				tmp[(m-1)*nl+n,1] = _arg[m,1]
				if (sign(tmp[(m-1)*nl+n-1,2]) == sign(_arg[m,n+1]))		# Because when we have neg & pos, case is diff
					tmp[(m-1)*nl+n,2] = tmp[(m-1)*nl+n-1,2] + _arg[m,n+1]
					tmp[(m-1)*nl+n,3] = tmp[(m-1)*nl+n-1,2]
				else
					tmp[(m-1)*nl+n,2] = _arg[m,n+1]
					tmp[(m-1)*nl+n,3] = 0
				end
			end
		end
		_arg = tmp
		do_multi = false;		do_bar_stack = true
	end

	if (g_bar_fill === nothing && findfirst("-G0/115/190", cmd) !== nothing)	# Remove the auto color
		cmd = replace(cmd, " -G0/115/190" => "")
		g_bar_fill = true			# Just anything non array to trigger the cyclic color schema
	end

	# Convert to a multi-segment GMTdataset. There will be as many segments as elements in a group
	# and as many rows in a segment as the number of groups (number of bars if groups had only one bar)
	alpha = find_in_dict(d, [:alpha :fillalpha :transparency])[1]
	_arg = mat2ds(_arg; fill=g_bar_fill, multi=do_multi, fillalpha=alpha)
	if (do_bar_stack)  _arg = ds2ds(_arg[1], fill=g_bar_fill, color_wrap=nl, fillalpha=alpha)  end
	(g_bar_fill !== nothing) && delete!(d, :fill)

	if (bars_cols !== nothing)		# Loop over number of bars in each group and append the error bar
		for k = 1:length(_arg)
			_arg[k].data = reshape(append!(_arg[k].data[:], bars_cols[:,k]), size(_arg[k].data,1), :)
		end
	end

	# Must fish-and-break-and-rebuild -S option
	opt_S = scan_opt(cmd, "-S")
	sub_b = ((ind = findfirst("+", opt_S)) !== nothing) ? opt_S[ind[1]:end] : ""	# The +Base modifier
	(sub_b != "") && (opt_S = opt_S[1:ind[1]-1])# Strip it because we need to (re)find Bar width
	bw = (isletter(opt_S[end])) ? parse(Float64, opt_S[3:end-1]) : parse(Float64, opt_S[3:end])	# Bar width
	n_in_group = length(_arg)					# Number of bars in the group
	gap = ((val = find_in_dict(d, [:gap])[1]) !== nothing) ? val/100 : 0	# Gap between bars in a group
	new_bw = (do_bar_stack) ? bw : bw / n_in_group * (1 - gap)	# 'width' does not change in bar-stack
	new_opt_S = "-S" * opt_S[1] * "$(new_bw)u"
	cmd = (do_bar_stack) ? replace(cmd, "-S"*opt_S*sub_b => new_opt_S*"+b") : replace(cmd, "-S"*opt_S => new_opt_S)

	if (!do_bar_stack)							# 'Horizontal stack'
		g_shifts = linspace((-bw + new_bw)/2, (bw - new_bw)/2, n_in_group)
		for k = 1:n_in_group
			[_arg[k].data[n,1] += g_shifts[k] for n = 1:size(_arg[k].data,1)]
		end
	end

	if (!got_usr_R)								# Need to recompute -R
		info = gmt("gmtinfo -C", _arg)
		(info[1].data[3] > 0) && (info[1].data[3] = 0)		# If not negative then must be 0
		dx = (info[1].data[2] - info[1].data[1]) * 0.005 + new_bw/2;
		dy = (info[1].data[4] - info[1].data[3]) * 0.005;
		info[1].data[1] -= dx;	info[1].data[2] += dx;	info[1].data[4] += dy;
		(info[1].data[3] != 0) && (info[1].data[3] -= dy);
		info[1].data = round_wesn(info[1].data)		# Add a pad if not-tight
		new_opt_R = @sprintf(" -R%.12g/%.12g/%.12g/%.12g", info[1].data[1], info[1].data[2], info[1].data[3], info[1].data[4])
		cmd = replace(cmd, opt_R => new_opt_R)
	end
	return cmd, _arg
end

# ---------------------------------------------------------------------------------------------------
function make_color_column(d::Dict, cmd::String, opt_i::String, len::Int, N_args::Int, n_prev::Int, is3D::Bool, got_Ebars::Bool, arg1, arg2)
	# See if we got a CPT. If yes, there is quite some work to do if no color column provided in input data.
	# N_ARGS will be == n_prev+1 when a -Ccpt was used. Otherwise they are equal.

	(arg1 === nothing || isa(arg1, GMT.GMTcpt)) && return cmd, arg1, arg2, N_args, false  # Play safe

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
			cmd *= " -i0-$(1+is3D),$(1+is3D)"
			if ((val = find_in_dict(d, [:markersize :ms :size])[1]) !== nothing)
				cmd *= "-$(2+is3D)"		# Because we know that an extra col will be added later
			end
		end
	else
		if (mz !== nothing)				# Here we must insert the color col right after the coords
			if (length(mz) != n_rows)  @warn(warn1); @goto noway  end
			if     (isa(arg1, Array))      arg1 = hcat(arg1[:,1:2+is3D], mz[:], arg1[:,3+is3D:end])
			elseif (isa(arg1,GMTdataset))  arg1.data = hcat(arg1.data[:,1:2+is3D], mz[:], arg1.data[:,3+is3D:end])
			else                           arg1[1].data = hcat(arg1[1].data[:,1:2+is3D], mz[:], arg1[1].data[:,3+is3D:end])
			end
		elseif (got_Ebars)		# The Error bars case is very multi. Don't try to guess then.
			if (opt_i != "")  @warn(warn2);	@goto noway  end
			cmd *= " -i0-$(1+is3D),$(1+is3D),$(2+is3D)-$(n_col-1)"
		end
	end

	if (N_args == n_prev)		# No cpt transmitted, so need to compute one
		if (GMTver >= v"77")		# 7 because this solution is currently still bugged
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
function get_marker_name(d::Dict, symbs::Array{Symbol}, is3D::Bool, del::Bool=true, arg1=nothing)
	marca = Array{String,1}(undef,1)
	marca = [""];		N = 0
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
				if (N > 0)  marca[1], arg1, msg = helper_markers(opt, t[2], arg1, N, cst)  end
				(msg != "") && error(msg)
				if (length(t) == 3 && isa(t[3], NamedTuple))
					if (marca[1] == "w" || marca[1] == "W")	# Ex (spiderweb): marker=(:pie, [...], (inner=1,))
						marca[1] *= add_opt(t[3], (inner="/", arc="+a", radial="+r", size=("", arg2str, 1), pen=("+p", add_opt_pen)) )
					elseif (marca[1] == "m" || marca[1] == "M")
						marca[1] *= vector_attrib(t[3])
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
					marca[1] = opt * add_opt(t, (size=("", arg2str, 1), inner="/", arc="+a", radial="+r", pen=("+p", add_opt_pen)))
				elseif (opt == "b" || opt == "B")
					marca[1] = opt * add_opt(t, (size=("", arg2str, 1), base="+b", Base="+B"))
				elseif (opt == "l")
					marca[1] = opt * add_opt(t, (size=("", arg2str, 1), letter="+t", justify="+j", font=("+f", font)))
				elseif (opt == "m" || opt == "M")
					marca[1] = opt * add_opt(t, (size=("", arg2str, 1), arrow=("", vector_attrib)))
				elseif (opt == "k" || opt == "K")
					marca[1] = opt * add_opt(t, (custom="", size="/"))
				end
			else
				t = string(t)
				if     (t == "-" || t == "x-dash")    marca[1] = "-"
				elseif (t == "+" || t == "plus")      marca[1] = "+"
				elseif (t == "a" || t == "*" || t == "star")  marca[1] = "a"
				elseif (t == "k" || t == "custom")    marca[1] = "k"
				elseif (t == "x" || t == "cross")     marca[1] = "x"
				elseif (t[1] == 'c' || t[1] == 'C')   marca[1] = "c"
				elseif (t == "d" || t == "diamond")   marca[1] = "d"
				elseif (t == "g" || t == "octagon")   marca[1] = "g"
				elseif (t == "h" || t == "hexagon")   marca[1] = "h"
				elseif (t == "i" || t == "v" || t == "inverted_tri")  marca[1] = "i"
				elseif (t == "l" || t == "letter")    marca[1] = "l"
				elseif (t == "n" || t == "pentagon")  marca[1] = "n"
				elseif (t == "p" || t == "." || t == "point")  marca[1] = "p"
				elseif (t == "s" || t == "square")    marca[1] = "s"
				elseif (t == "t" || t == "^" || t == "triangle")  marca[1] = "t"
				elseif (t == "T" || t == "Triangle")  marca[1] = "T"
				elseif (is3D && (t == "u" || t == "cube"))  marca[1] = "u"
				elseif (t == "y" || t == "y-dash")    marca[1] = "y"
				end
				# Still need to check the simpler forms of these
				if (marca[1] == "")  marca[1] = helper2_markers(t, ["e", "ellipse"])   end
				if (marca[1] == "")  marca[1] = helper2_markers(t, ["E", "Ellipse"])   end
				if (marca[1] == "")  marca[1] = helper2_markers(t, ["j", "rotrect"])   end
				if (marca[1] == "")  marca[1] = helper2_markers(t, ["J", "RotRect"])   end
				if (marca[1] == "")  marca[1] = helper2_markers(t, ["m", "matangle"])  end
				if (marca[1] == "")  marca[1] = helper2_markers(t, ["M", "Matangle"])  end
				if (marca[1] == "")  marca[1] = helper2_markers(t, ["r", "rectangle"])   end
				if (marca[1] == "")  marca[1] = helper2_markers(t, ["R", "RRectangle"])  end
				if (marca[1] == "")  marca[1] = helper2_markers(t, ["v", "vector"])  end
				if (marca[1] == "")  marca[1] = helper2_markers(t, ["V", "Vector"])  end
				if (marca[1] == "")  marca[1] = helper2_markers(t, ["w", "pie", "web"])  end
				if (marca[1] == "")  marca[1] = helper2_markers(t, ["W", "Pie", "Web"])  end
			end
			(del) && delete!(d, symb)
			break
		end
	end
	return marca[1], arg1, N > 0
end

function helper_markers(opt::String, ext, arg1, N::Int, cst::Bool)
	# Helper function to deal with the cases where one sends marker's extra columns via command
	# Example that will land and be processed here:  marker=(:Ellipse, [30 10 15])
	# N is the number of extra columns
	marca = Array{String,1}(undef,1)
	marca = [""];	 msg = ""
	if (size(ext,2) == N && arg1 !== nothing)
		S = Symbol(opt)
		marca[1], arg1 = add_opt(add_opt, (Dict(S => (par=ext,)), opt, "", [S]), (par="|",), true, arg1)
	elseif (cst && length(ext) == 1)
		marca[1] = opt * "-" * string(ext)
	else
		msg = string("Wrong number of extra columns for marker (", opt, "). Got ", size(ext,2), " but expected ", N)
	end
	return marca[1], arg1, msg
end

function helper2_markers(opt::String, alias::Vector{String})::String
	marca = [""]
	if (opt == alias[1])			# User used only the one letter syntax
		marca[1] = alias[1]
	else
		for k = 2:length(alias)		# Loop because of cases like ["w" "pie" "web"]
			o2 = alias[k][1:min(2,length(alias[k]))]	# check the first 2 chars and Ro, Rotrect or RotRec are all good
			if (startswith(opt, o2))  marca[1] = alias[1]; break  end		# Good when, for example, marker=:Pie
		end
	end

	# If we still have found nothing, assume that OPT is a full GMT opt string (e.g. W/5+a30+r45+p2,red)
	if (marca[1] == "" && opt[1] == alias[1][1])  marca[1] = opt  end
	return marca[1]
end

# ---------------------------------------------------------------------------------------------------
function check_caller(d::Dict, _cmd::String, opt_S::String, opt_W::String, caller::String, g_bar_fill, O::Bool)::String
	# Set sensible defaults for the sub-modules "scatter" & "bar"
	cmd = Vector{String}(undef,1)
	cmd[1] = _cmd
	if (caller == "scatter")
		if (opt_S == "")  cmd[1] *= " -Sc5p"  end
	elseif (caller == "scatter3")
		if (opt_S == "")  cmd[1] *= " -Su2p"  end
	elseif (caller == "lines")
		if (!occursin("+p", cmd[1]) && opt_W == "") cmd[1] *= " -W0.25p"  end # Do not leave without a pen specification
	elseif (caller == "bar")
		if (opt_S == "")
			if (haskey(d, :bar))
				cmd[1] = parse_bar_cmd(d, :bar, cmd[1], "Sb")
			elseif (haskey(d, :hbar))
				cmd[1] = parse_bar_cmd(d, :hbar, cmd[1], "SB")
			else
				opt = (haskey(d, :width)) ? add_opt(d, "", "",  [:width]) : "0.8"	# The default
				cmd[1] *= " -Sb" * opt * "u"

				optB = (haskey(d, :base)) ? add_opt(d, "", "",  [:base]) : "0"
				cmd[1] *= "+b" * optB
			end
		end
		(g_bar_fill === nothing && !occursin(" -G", cmd[1]) && !occursin(" -C", cmd[1])) && (cmd[1] *= " -G0/115/190")	# Default color
	elseif (caller == "bar3")
		if (haskey(d, :noshade) && occursin("-So", cmd[1]))
			cmd[1] = replace(cmd[1], "-So" => "-SO", count=1);
			delete!(d, :noshade)
		end
		if (!occursin(" -G", cmd[1]) && !occursin(" -C", cmd[1]))  cmd[1] *= " -G0/115/190"	end
		if (!occursin(" -J", cmd[1]))  cmd[1] *= " -JX12c/0"  end
	end

	if (occursin('3', caller))
		if (!occursin(" -B", cmd[1]) && !O)  cmd[1] *= def_fig_axes3  end	# For overlays default is no axes
		if (!occursin(" -p", cmd[1]))  cmd[1] *= " -p200/30"  end
	end

	return cmd[1]
end

# ---------------------------------------------------------------------------------------------------
function parse_bar_cmd(d::Dict, key::Symbol, cmd::String, optS::String, no_u::Bool=false)::String
	# Deal with parsing the 'bar' & 'hbar' keywors of psxy. Also called by plot/bar3. For this
	# later module if input is not a string or NamedTuple the scatter options must be processed in bar3().
	# KEY is either :bar or :hbar
	# OPTS is either "Sb", "SB" or "So"
	# NO_U if true means to NOT automatic adding of flag 'u'
	opt =""
	if (haskey(d, key))
		if (isa(d[key], String))
			cmd *= " -" * optS * d[key];	delete!(d, key)
		elseif (isa(d[key], NamedTuple))
			opt = add_opt(d, "", optS, [key], (width="",unit="1",base="+b",height="+B",nbands="+z",Nbands="+Z"))
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
