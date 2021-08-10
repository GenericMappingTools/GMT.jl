const psxy  = plot
const psxy! = plot!
const psxyz  = plot3d
const psxyz! = plot3d!

# ---------------------------------------------------------------------------------------------------
function common_plot_xyz(cmd0::String, arg1, caller::String, first::Bool, is3D::Bool, kwargs...)
	arg2, arg3 = nothing, nothing
	N_args = (arg1 === nothing) ? 0 : 1
	is_ternary = (caller == "ternary") ? true : false
	if     (is3D)       gmt_proggy = (IamModern[1]) ? "plot3d "  : "psxyz "
	elseif (is_ternary) gmt_proggy = (IamModern[1]) ? "ternary " : "psternary "
	else		        gmt_proggy = (IamModern[1]) ? "plot "    : "psxy "
	end

	(occursin(" -", cmd0)) && return monolitic(gmt_proggy, cmd0, arg1)

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode
	(!O) && (legend_type[1] = legend_bag())		# Make sure that we always start with an empty one

	cmd = "";	sub_module = ""			# Will change to "scatter", etc... if called by sub-modules
	g_bar_fill = Vector{String}()		# May hold a sequence of colors for gtroup Bar plots
	if (caller != "")
		if (occursin(" -", caller))		# some sub-modues use this piggy-backed call
			if ((ind = findfirst("|", caller)) !== nothing)	# A mixed case with "caler|partiall_command"
				sub_module = caller[1:ind[1]-1]
				cmd = caller[ind[1]+1:end]
				caller = sub_module		# Because of parse_BJR()
				(caller == "events") && (gmt_proggy = "events ")
			else
				cmd = caller
				caller = "others"		# It was piggy-backed
			end
		else
			sub_module = caller
			# Needs to be processed here to destinguish from the more general 'fill'
			(caller == "bar") && (g_bar_fill = helper_gbar_fill(d))
		end
	end

	if (occursin('3', caller) && !haskey(d, :p) && !haskey(d, :view) && !haskey(d, :perspective))
		d[:p] = "200/30"		# Need this before parse_BJR() so MAP_FRAME_AXES can be guessed.
	end

	if (is_ternary)
		cmd, opt_B::String = cmd * d[:B], d[:B]			# B option was parsed in plot/ternary
		delete!(d, :B)
		cmd, opt_R = parse_R(d, cmd, O)
	end
	if (is_ternary && !first) 	# Either a -J was set and we'll fish it here or no and we'll use the default.
		def_J = " -JX" * split(def_fig_size, '/')[1]
		cmd, opt_J = parse_J(d, cmd, def_J)
	else
		def_J = (is_ternary) ? " -JX" * split(def_fig_size, '/')[1] : ""		# Gives "-JX14c" 
		if (is_ternary)  cmd, opt_J = parse_J(d, cmd, def_J)
		else             cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd, caller, O, def_J)
		end
	end

	cmd, opt_JZ = parse_JZ(d, cmd)
	cmd, = parse_common_opts(d, cmd, [:a :e :f :g :p :t :params], first)
	cmd, opt_l = parse_l(d, cmd)		# Parse this one (legend) aside so we can use it in classic mode
	cmd  = parse_these_opts(cmd, d, [[:D :shift :offset], [:I :intens], [:N :no_clip :noclip]])
	parse_ls_code!(d::Dict)				# Check for linestyle codes (must be before the GMTsyntax_opt() call)
	cmd  = GMTsyntax_opt(d, cmd)		# See if an hardcore GMT syntax string has been passed
	(is_ternary) && (cmd = add_opt(d, cmd, 'M', [:M :dump]))
	opt_UVXY = parse_UVXY(d, "")		# Need it separate to not risk to double include it.
	cmd, opt_c = parse_c(d, cmd)		# Need opt_c because we may need to remove it from double calls

	# If a file name sent in, read it and compute a tight -R if this was not provided
	got_usr_R = (opt_R != "") ? true : false			# To know if the user set -R or we guessed it from data
	if (opt_R == "" && sub_module == "bar")  opt_R = "/-0.4/0.4/0"  end	# Make sure y_min = 0
	if (O && caller == "plotyy")
		cmd = replace(cmd, opt_R => "")					# Must remove old opt_R because a new one will be constructed
		ind = collect(findall("/", box_str[1])[2])		# 'box_str' was set in first call
		opt_R = '/' * box_str[1][4:ind[1]] * "?/?"		# Will become /x_min/x_max/?/?
	end
	cmd, arg1, opt_R, _, opt_i = read_data(d, cmd0, cmd, arg1, opt_R, is3D)
	(N_args == 0 && arg1 !== nothing) && (N_args = 1)
	(!O && caller == "plotyy") && (box_str[1] = opt_R)	# This needs modifications (in plotyy) by second call

	if ((isa(arg1, GMTdataset) && arg1.proj4 != "" || isa(arg1, Vector{<:GMTdataset}) &&
		     arg1[1].proj4 != "") && opt_J == " -JX" * def_fig_size)
		cmd = replace(cmd, opt_J => "-JX" * split(def_fig_size, '/')[1] * "/0")	# If projected, it's a axis equal for sure
	end
	if (is3D && isempty(opt_JZ) && length(collect(eachmatch(r"/", opt_R))) == 5)
		cmd *= " -JZ6c"		# Default -JZ
	end

	cmd = add_opt(d, cmd, 'A', [:A :steps :straight_lines], (x="x", y="y", meridian="m", parallel="p"))
	opt_F = add_opt(d, "", "", [:F :conn :connection],
	                (continuous=("c", nothing, 1), net=("n", nothing, 1), network=("n", nothing, 1), refpoint=("r", nothing, 1),  ignore_hdr="_a", single_group="_f", segments="_s", segments_reset="_r", anchor=("", arg2str)))
	(opt_F != "" && !occursin("/", opt_F)) && (opt_F = string(opt_F[1]))	# Allow con=:net or con=(1,2)
	(opt_F != "") && (cmd *= " -F" * opt_F)

	# Error Bars?
	got_Ebars = false
	val, symb = find_in_dict(d, [:E :error :error_bars], false)
	if (val !== nothing)
		cmd, arg1 = add_opt(add_opt, (d, cmd, 'E', [symb]),
                            (x="|x",y="|y",xy="|xy",X="|X",Y="|Y", asym="_+a", colored="_+c", cline="_+cl", csymbol="_+cf", wiskers="|+n",cap="+w",pen=("+p",add_opt_pen)), false, isa(arg1, GMTdataset) ? arg1.data : (isa(arg1, Vector{<:GMTdataset}) ? arg1[1].data : arg1) )
		got_Ebars = true
		del_from_dict(d, [symb])
	end

	# Look for color request. Do it after error bars because they may add a column
	len = length(cmd);	n_prev = N_args;
	cmd, args, n, got_Zvars = add_opt(d, cmd, 'Z', [:Z :level], :data, Any[arg1, arg2, arg3], (outline="_+l", fill="_+f"))
	if (n > 0)
		arg1, arg2, arg3 = args[:]
		N_args = n
	end
	in_bag = (got_Zvars) ? true : false			# Other cases should add to this list
	if (N_args < 2)
		cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1, arg2, true, true, "", in_bag)
	else			# Here we know that both arg1 & arg2 are already occupied, so must use arg3 only
		cmd, arg3, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', 0, arg3, nothing, true, true, "", in_bag)
		N_args = 3
	end

	mcc, bar_ok = false, (sub_module == "bar" && !check_bar_group(arg1))
	if ((!got_Zvars && !is_ternary) || bar_ok)	# If "bar" ONLY if not bar-group
		# See if we got a CPT. If yes there may be some work to do if no color column provided in input data.
		cmd, arg1, arg2, N_args, mcc = make_color_column(d, cmd, opt_i, len, N_args, n_prev, is3D, got_Ebars, bar_ok, g_bar_fill, arg1, arg2)
	end

	if (isempty(g_bar_fill))					# Otherwise bar fill colors are dealt somewhere else
		cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	end
	opt_Gsymb = add_opt_fill("", d, [:G :mc :markercolor :markerfacecolor :MarkerFaceColor], 'G')	# Filling of symbols

	# To track a still existing bug in sessions management at GMT lib level
	got_pattern = (occursin("-Gp", cmd) || occursin("-GP", cmd) || occursin("-Gp", opt_Gsymb) || occursin("-GP", opt_Gsymb)) ? true : false

	if (is_ternary)			# Means we are in the psternary mode
		cmd = add_opt(d, cmd, 'L', [:L :vertex_labels])
	else
		opt_L = add_opt(d, "", 'L', [:L :close :polygon],
		                (left="_+xl", right="_+xr", x0="+x", bot="_+yb", top="_+yt", y0="+y", sym="_+d", asym="_+D", envelope="_+b", pen=("+p",add_opt_pen)))
		(length(opt_L) > 3 && !occursin("-G", cmd) && !occursin("+p", cmd)) && (opt_L *= "+p0.5p")
		cmd *= opt_L
	end

	if ((val = find_in_dict(d, [:decorated])[1]) !== nothing)
		cmd = (isa(val, String)) ? cmd * " " * val : cmd * decorated(val)
	end

	opt_Wmarker = ""
	if ((val = find_in_dict(d, [:mec :markeredgecolor :MarkerEdgeColor])[1]) !== nothing)
		opt_Wmarker = "0.5p," * arg2str(val)		# 0.25p is too thin?
	end

	opt_W = add_opt_pen(d, [:W :pen], "W", true)     # TRUE to also seek (lw,lc,ls)
	((occursin("+c", opt_W)) && !occursin("-C", cmd)) &&
		@warn("Color lines (or fill) from a color scale was selected but no color scale provided. Expect ...")

	opt_S = add_opt(d, "", 'S', [:S :symbol], (symb="1", size="", unit="1"))
	if (opt_S == "")			# OK, no symbol given via the -S option. So fish in aliases
		marca, arg1, more_cols = get_marker_name(d, arg1, [:marker, :Marker, :shape], is3D, true)
		if ((val = find_in_dict(d, [:ms :markersize :MarkerSize :size])[1]) !== nothing)
			(marca == "") && (marca = "c")			# If a marker name was not selected, defaults to circle
			if (isa(val, AbstractArray))
				(length(val) != size(arg1,1)) &&
					error("The size array must have the same number of elements rows in the data")
				arg1 = hcat(arg1, val[:])
			elseif (string(val) != "indata")
				marca *= arg2str(val);
			end
			opt_S = " -S" * marca
		elseif (marca != "")		# User only selected a marker name but no size.
			opt_S = " -S" * marca
			# If data comes from a file, then no automatic symbol size is added
			op = lowercase(marca[1])
			def_size = (op == 'p') ? "2p" : "7p"	# 'p' here stands for symbol points, not units
			(!more_cols && arg1 !== nothing && !isa(arg1, GMTcpt) && !occursin(op, "bekmrvw")) && (opt_S *= def_size)
		end
	else
		val, symb = find_in_dict(d, [:ms :markersize :MarkerSize :size])
		(val !== nothing) && @warn("option *$(symb)* is ignored when either *S* or *symbol* options are used")
		val, symb = find_in_dict(d, [:marker :Marker :shape])
		(val !== nothing) && @warn("option *$(symb)* is ignored when either *S* or *symbol* options are used")
	end

	opt_ML = ""
	if (opt_S != "")
		opt_ML, opt_Wmarker = parse_markerline(d, opt_ML, opt_Wmarker)
	end

	# See if any of the scatter, bar, lines, etc... was the caller and if yes, set sensible defaults.
	cmd  = check_caller(d, cmd, opt_S, opt_W, sub_module, g_bar_fill, O)
	(mcc && caller == "bar" && !got_usr_R && opt_R != " -R") && (cmd = recompute_R_4bars!(cmd, opt_R, arg1))	# Often needed
	_cmd = build_run_cmd(cmd, opt_B, opt_Gsymb, opt_ML, opt_S, opt_W, opt_Wmarker, opt_UVXY, opt_c)
	
	(got_Zvars && opt_S == "" && opt_W == "" && !occursin(" -G", _cmd[1])) && (_cmd[1] *= " -W0.5")

	# Let matrices with more data columns, and for which Color info was NOT set, plot multiple lines at once
	arg1 = helper_multi_cols(d, arg1, mcc, opt_R, opt_S, opt_W, caller, is3D, multi_col, _cmd,
	                         sub_module, g_bar_fill, got_Ebars, got_usr_R)

	# Try to limit the damage of this Fker bug in 6.2.0
	if ((mcc || got_Ebars) && (GMTver == v"6.2.0" && isGMTdataset(arg1) && occursin(" -i", cmd)) )
		if (isa(arg1, GMTdataset))	arg1 = arg1.data
		elseif (isa(arg1, Vector{<:GMTdataset}))
			(length(arg1) > 1) && @warn("Due to a bug in GMT6.2.0 I'm forced to use only the first segment")
			arg1 = arg1[1].data
		end
	end

	(!IamModern[1]) && put_in_legend_bag(d, _cmd, arg1, O, opt_l)

	_cmd = gmt_proggy .* _cmd				# In any case we need this
	_cmd, K = finish_PS_nested(d, _cmd, K)

	finish = (is_ternary && occursin(" -M",_cmd[1])) ? false : true		# But this case (-M) is bugged still in 6.2.0
	r = finish_PS_module(d, _cmd, "", K, O, finish, arg1, arg2, arg3)
	(got_pattern || occursin("-Sk", opt_S)) && gmt("destroy")  # Apparently patterns are screweing the session
	return r
end

# ---------------------------------------------------------------------------------------------------
function parse_markerline(d::Dict, opt_ML::String, opt_Wmarker::String)
	# Make this code into a function so that it can also be called from mk_styled_line!()
	if ((val = find_in_dict(d, [:ml :markerline :MarkerLine])[1]) !== nothing)
		if (isa(val, Tuple))           opt_ML = " -W" * parse_pen(val) # This can hold the pen, not extended atts
		elseif (isa(val, NamedTuple))  opt_ML = add_opt_pen(nt2dict(val), [:pen], "W")
		else                           opt_ML = " -W" * arg2str(val)
		end
		if (opt_Wmarker != "")
			@warn("markerline overrides markeredgecolor");		opt_Wmarker = ""
		end
	end
	return opt_ML, opt_Wmarker
end

# ---------------------------------------------------------------------------------------------------
function build_run_cmd(cmd, opt_B, opt_Gsymb, opt_ML, opt_S, opt_W, opt_Wmarker, opt_UVXY, opt_c)::Vector{String}
	# Build the executble command vector
	if (opt_W != "" && opt_S == "") 						# We have a line/polygon request
		_cmd = [cmd * opt_W * opt_UVXY]

	elseif (opt_W == "" && (opt_S != "" || opt_Gsymb != ""))	# We have a symbol request
		(opt_Wmarker != "" && opt_W == "") && (opt_Gsymb *= " -W" * opt_Wmarker)	# reuse var name
		(opt_ML != "") && (cmd *= opt_ML)					# If we have a symbol outline pen
		_cmd = [cmd * opt_S * opt_Gsymb * opt_UVXY]

	elseif (opt_W != "" && opt_S != "")						# We have both line/polygon and a symbol
		(occursin(opt_Gsymb, cmd)) && (opt_Gsymb = "")
		if (opt_S[4] == 'v' || opt_S[4] == 'V' || opt_S[4] == '=')
			_cmd = [cmd * opt_W * opt_S * opt_Gsymb * opt_UVXY]
		else
			(opt_Wmarker != "") && (opt_Wmarker = " -W" * opt_Wmarker)		# Set Symbol edge color
			cmd1 = cmd * opt_W * opt_UVXY
			(opt_B != " " && opt_B != "") && (cmd = replace(cmd, opt_B => ""))	# Some themes make opt_B = " "
			cmd2 = cmd * opt_S * opt_Gsymb * opt_Wmarker	# Don't repeat option -B
			(opt_c != "")  && (cmd2 = replace(cmd2, opt_c => ""))  				# Not in scond call (subplots)
			(opt_ML != "") && (cmd2 = cmd2 * opt_ML)				# If we have a symbol outline pen
			_cmd = [cmd1; cmd2]
		end

	else
		_cmd = [cmd * opt_UVXY]
	end
end

# ---------------------------------------------------------------------------------------------------
function helper_multi_cols(d::Dict, arg1, mcc, opt_R, opt_S, opt_W, caller, is3D, multi_col, _cmd, sub_module, g_bar_fill, got_Ebars, got_usr_R)
	# Let matrices with more data columns, and for which Color info was NOT set, plot multiple lines at once
	if (!mcc && opt_S == "" && (caller == "lines" || caller == "plot") && isa(arg1, Matrix{<:Real}) && size(arg1,2) > 2+is3D && size(arg1,1) > 1 && (multi_col[1] || haskey(d, :multicol)) )
		penC, penS = "", "";	cycle=:cycle;	multi_col[1] = false	# Reset because this is a use-only-once option
		(haskey(d, :multicol)) && delete!(d, :multicol)
		# But if we have a color in opt_W (idiotic) let it overrule the automatic color cycle in mat2ds()
		if (opt_W != "")  penT, penC, penS = break_pen(scan_opt(opt_W, "-W"))
		else              _cmd[1] *= " -W0.5"
		end
		if (penC != "")  cycle = [penC]  end
		arg1 = mat2ds(arg1, color=cycle, ls=penS, multi=true)	# Convert to multi-segment GMTdataset
		D::Vector{<:GMTdataset} = gmt("gmtinfo -C", arg1)		# But now also need to update the -R string
		_cmd[1] = replace(_cmd[1], opt_R => " -R" * arg2str(round_wesn(D[1].data)))
	elseif (!mcc && sub_module == "bar" && check_bar_group(arg1))	# !mcc because the bar-groups all have mcc = false
		_cmd[1], arg1 = bar_group(d, _cmd[1], opt_R, g_bar_fill, got_Ebars, got_usr_R, arg1)
	end
	return arg1
end

# ---------------------------------------------------------------------------------------------------
function helper_gbar_fill(d::Dict)::Vector{String}
	# This is a function that tryies to hammer the insistence that g_bar_fill is a Any
	# g_bar_fill may hold a sequence of colors for gtroup Bar plots
	gval = find_in_dict(d, [:fill :fillcolor], false)[1]	# Used for group colors
	if (isa(gval, Array{String}) && length(gval) > 1)
		g_bar_fill = Vector{String}()
		append!(g_bar_fill, gval)
	elseif ((isa(gval, Array{Int}) || isa(gval, Tuple) && eltype(gval) == Int) && length(gval) > 1)
		g_bar_fill = Vector{String}(undef, length(gval))			# Patterns
		[g_bar_fill[k] = string('p',gval[k]) for k = 1:length(gval)]
	elseif (isa(gval, Tuple) && (eltype(gval) == String || eltype(gval) == Symbol) && length(gval) > 1)
		g_bar_fill = Vector{String}(undef, length(gval))			# Patterns
		[g_bar_fill[k] = string(gval[k]) for k = 1:length(gval)]
	else
		g_bar_fill = Vector{String}()		# To have somthing to return
	end
	return g_bar_fill
end

# ---------------------------------------------------------------------------------------------------
# Check if a group bar request or just bars. Returns TRUE in first case and FALSE in second
check_bar_group(arg1) = ( (isa(arg1, Array{<:Real,2}) || eltype(arg1) <: GMTdataset) &&
                          (isa(arg1, Vector{<:GMTdataset}) ? size(arg1[1],2) > 2 : size(arg1,2) > 2) )::Bool

# ---------------------------------------------------------------------------------------------------
function bar_group(d::Dict, cmd::String, opt_R::String, g_bar_fill::Array{String}, got_Ebars::Bool, got_usr_R::Bool, arg1)
	# Convert input array into a multi-segment Dataset where each segment is an element of a bar group
	# Example, plot two groups of 3 bars each: bar([0 1 2 3; 1 2 3 4], xlabel="BlaBla")

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
		_arg = isa(arg1, GMTdataset) ? deepcopy(arg1.data) : (isa(arg1, Vector{<:GMTdataset}) ? deepcopy(arg1[1].data) : deepcopy(arg1))
		bars_cols = missing
	end

	do_multi = true;	is_stack = false		# True for grouped; false for stacked groups
	is_hbar = occursin("-SB", cmd)				# An horizontal bar plot
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
		(is_hbar) && (tmp = [tmp[:,2] tmp[:,1] tmp[:,3]])	# Horizontal bars must swap 1-2 cols
		_arg = tmp
		do_multi = false;		is_stack = true
	end

	if (isempty(g_bar_fill) && findfirst("-G0/115/190", cmd) !== nothing)		# Remove the auto color
		cmd = replace(cmd, " -G0/115/190" => "")
	end

	# Convert to a multi-segment GMTdataset. There will be as many segments as elements in a group
	# and as many rows in a segment as the number of groups (number of bars if groups had only one bar)
	alpha = find_in_dict(d, [:alpha :fillalpha :transparency])[1]
	_argD = mat2ds(_arg; fill=g_bar_fill, multi=do_multi, fillalpha=alpha)
	(is_stack) && (_argD = ds2ds(_argD[1], fill=g_bar_fill, color_wrap=nl, fillalpha=alpha))
	if (is_hbar && !is_stack)					# Must swap first & second col
		for k = 1:length(_argD)
			_argD[k].data = [_argD[k].data[:,2] _argD[k].data[:,1]]
		end
	end
	(!isempty(g_bar_fill)) && delete!(d, :fill)

	if (bars_cols !== missing)		# Loop over number of bars in each group and append the error bar
		for k = 1:length(_argD)
			_argD[k].data = reshape(append!(_argD[k].data[:], bars_cols[:,k]), size(_argD[k].data,1), :)
		end
	end

	# Must fish-and-break-and-rebuild -S option
	opt_S = scan_opt(cmd, "-S")
	sub_b = ((ind = findfirst("+", opt_S)) !== nothing) ? opt_S[ind[1]:end] : ""	# The +Base modifier
	(sub_b != "") && (opt_S = opt_S[1:ind[1]-1])# Strip it because we need to (re)find Bar width
	bw = (isletter(opt_S[end])) ? parse(Float64, opt_S[3:end-1]) : parse(Float64, opt_S[2:end])	# Bar width
	n_in_group = length(_argD)					# Number of bars in the group
	gap = ((val = find_in_dict(d, [:gap])[1]) !== nothing) ? val/100 : 0	# Gap between bars in a group
	new_bw = (is_stack) ? bw : bw / n_in_group * (1 - gap)	# 'width' does not change in bar-stack
	new_opt_S = "-S" * opt_S[1] * "$(new_bw)u"
	cmd = (is_stack) ? replace(cmd, "-S"*opt_S*sub_b => new_opt_S*"+b") : replace(cmd, "-S"*opt_S => new_opt_S)

	if (!is_stack)								# 'Horizontal stack'
		g_shifts = linspace((-bw + new_bw)/2, (bw - new_bw)/2, n_in_group)
		col = (is_hbar) ? 2 : 1					# Horizontal and Vertical bars get shits in different columns
		for k = 1:n_in_group
			[_argD[k].data[n, col] += g_shifts[k] for n = 1:size(_argD[k].data,1)]
		end
	end

	if (!got_usr_R)								# Need to recompute -R
		info = gmt("gmtinfo -C", _argD)
		(info[1].data[3] > 0) && (info[1].data[3] = 0)		# If not negative then must be 0
		if (!is_hbar)
			dx = (info[1].data[2] - info[1].data[1]) * 0.005 + new_bw/2;
			dy = (info[1].data[4] - info[1].data[3]) * 0.005;
			info[1].data[1] -= dx;	info[1].data[2] += dx;	info[1].data[4] += dy;
			(info[1].data[3] != 0) && (info[1].data[3] -= dy);
		else
			dx = (info[1].data[2] - info[1].data[1]) * 0.005
			dy = (info[1].data[4] - info[1].data[3]) * 0.005 + new_bw/2;
			info[1].data[1] = 0.0;	info[1].data[2] += dx;	info[1].data[3] -= dy;	info[1].data[4] += dy;
			(info[1].data[1] != 0) && (info[1].data[1] -= dx);
		end
		info[1].data = round_wesn(info[1].data)		# Add a pad if not-tight
		new_opt_R = sprintf(" -R%.15g/%.15g/%.15g/%.15g", info[1].data[1], info[1].data[2], info[1].data[3], info[1].data[4])
		cmd = replace(cmd, opt_R => new_opt_R)
	end
	return cmd, _argD
end

# ---------------------------------------------------------------------------------------------------
function recompute_R_4bars!(cmd::String, opt_R::String, arg1)
	# Recompute the -R for bar plots (non-grouped), taking into account the width embeded in option S
	opt_S = scan_opt(cmd, "-S")
	sub_b = ((ind = findfirst("+", opt_S)) !== nothing) ? opt_S[ind[1]:end] : ""	# The +Base modifier
	(sub_b != "") && (opt_S = opt_S[1:ind[1]-1])# Strip it because we need to (re)find Bar width
	bw = (isletter(opt_S[end])) ? parse(Float64, opt_S[3:end-1]) : parse(Float64, opt_S[2:end])	# Bar width
	info = gmt("gmtinfo -C", arg1)
	dx = (info[1].data[2] - info[1].data[1]) * 0.005 + bw/2;
	dy = (info[1].data[4] - info[1].data[3]) * 0.005;
	info[1].data[1] -= dx;	info[1].data[2] += dx;	info[1].data[4] += dy;
	info[1].data = round_wesn(info[1].data)		# Add a pad if not-tight
	new_opt_R = sprintf(" -R%.15g/%.15g/%.15g/%.15g", info[1].data[1], info[1].data[2], 0, info[1].data[4])
	cmd = replace(cmd, opt_R => new_opt_R)
end

# ---------------------------------------------------------------------------------------------------
function make_color_column(d::Dict, cmd::String, opt_i::String, len::Int, N_args::Int, n_prev::Int, is3D::Bool, got_Ebars::Bool, bar_ok::Bool, bar_fill, arg1, arg2)
	# See if we got a CPT. If yes, there is quite some work to do if no color column provided in input data.
	# N_ARGS will be == n_prev+1 when a -Ccpt was used. Otherwise they are equal.

	(arg1 === nothing || isa(arg1, GMT.GMTcpt)) && return cmd, arg1, arg2, N_args, false  # Play safe

	mz, the_kw = find_in_dict(d, [:zcolor :markerz :mz])
	if ((!(N_args > n_prev || len < length(cmd)) && mz === nothing) && !bar_ok)	# No color request, so return right away
		return cmd, arg1, arg2, N_args, false
	end

	# Filled polygons with -Z don't need extra col
	((val = find_in_dict(d, [:G :fill], false)[1]) == "+z") && return cmd, arg1, arg2, N_args, false

	if     (isa(arg1, Vector{<:GMTdataset}))           n_rows, n_col = size(arg1[1])
	elseif (isa(arg1,GMTdataset) || isa(arg1, Array))  n_rows, n_col = size(arg1)
	end

	if (!isempty(bar_fill))
		if (isa(arg1,GMTdataset) || isa(arg1, Array))  arg1 = hcat(arg1, 1:n_rows)
		elseif (isa(arg1, Vector{<:GMTdataset}))       arg1[1].data = hcat(arg1[1].data, 1:n_rows)
		end
		arg2::GMTcpt = gmt(string("makecpt -T1/$(n_rows+1)/1 -C" * join(bar_fill, ",")))
		current_cpt[1] = arg2
		(!occursin(" -C", cmd)) && (cmd *= " -C")	# Need to inform that there is a cpt to use
		find_in_dict(d, [:G :fill])					# Must delete the :fill. Not used anymore
		return cmd, arg1, arg2, 2, true
	end

	warn1 = string("Probably color column in ", the_kw, " has incorrect dims. Ignoring it.")
	warn2 = "Plotting with color table requires adding one more column to the dataset but your -i
	option didn't do it, so you won't get what you expect. Try -i0-1,1 for 2D or -i0-2,2 for 3D plots"

	if (n_col <= 2+is3D)
		if (mz !== nothing)
			if (length(mz) != n_rows)  @warn(warn1); @goto noway  end
			if (isa(arg1,GMTdataset) || isa(arg1, Array))  arg1    = hcat(arg1, mz[:])
			elseif (isa(arg1, Vector{<:GMTdataset}))       arg1[1] = hcat(arg1[1], mz[:]) 
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
			if (isa(arg1,GMTdataset) || isa(arg1, Array))  arg1    = hcat(arg1[:,1:2+is3D],    mz[:], arg1[:,3+is3D:end])
			elseif (isa(arg1, Vector{<:GMTdataset}))       arg1[1] = hcat(arg1[1][:,1:2+is3D], mz[:], arg1[1][:,3+is3D:end])
			end
		elseif (got_Ebars)				# The Error bars case is very multi. Don't try to guess then.
			if (opt_i != "")  @warn(warn2);	@goto noway  end
			cmd *= " -i0-$(1+is3D),$(1+is3D),$(2+is3D)-$(n_col-1)"
		end
	end

	if (N_args == n_prev)				# No cpt transmitted, so need to compute one
		if (mz !== nothing)                                    mi, ma = extrema(mz)
		else
			the_col = min(n_col,3)+is3D
			got_Ebars && (the_col -= 1)			# Bars => 2 cols
			if     (isa(arg1, Vector{<:GMTdataset}))           mi, ma = extrema(view(arg1[1], :, the_col))
			elseif (isa(arg1,GMTdataset) || isa(arg1, Array))  mi, ma = extrema(view(arg1,    :, the_col))
			end
		end
		just_C = cmd[len+2:end];	reset_i = ""
		if ((ind = findfirst(" -i", just_C)) !== nothing)
			reset_i = just_C[ind[1]:end]
			just_C  = just_C[1:ind[1]-1]
		end
		arg2 = gmt(string("makecpt -T", mi-0.001*abs(mi), '/', ma+0.001*abs(ma), " ", just_C) * (IamModern[1] ? " -H" : ""))
		current_cpt[1] = arg2
		if (occursin(" -C", cmd))  cmd = cmd[1:len+3]  end		# Strip the cpt name
		if (reset_i != "")  cmd *= reset_i  end		# Reset -i, in case it existed

		(!occursin(" -C", cmd)) && (cmd *= " -C")	# Need to inform that there is a cpt to use
		N_args = 2
	end

	@label noway

	return cmd, arg1, arg2, N_args, true
end

# ---------------------------------------------------------------------------------------------------
function get_marker_name(d::Dict, arg1, symbs::Vector{Symbol}, is3D::Bool, del::Bool=true)
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
				t1 = string(t)
				(t1[1] != 'T') && (t1 = lowercase(t1))
				if     (t1 == "-" || t1 == "x-dash")    marca[1] = "-"
				elseif (t1 == "+" || t1 == "plus")      marca[1] = "+"
				elseif (t1 == "a" || t1 == "*" || t1 == "star")  marca[1] = "a"
				elseif (t1 == "k" || t1 == "custom")    marca[1] = "k"
				elseif (t1 == "x" || t1 == "cross")     marca[1] = "x"
				elseif (is3D && (t1 == "u" || t1 == "cube"))  marca[1] = "u"	# Must come before next line
				elseif (t1[1] == 'c')                   marca[1] = "c"
				elseif (t1[1] == 'd')                   marca[1] = "d"		# diamond
				elseif (t1 == "g" || t1 == "octagon")   marca[1] = "g"
				elseif (t1[1] == 'h')                   marca[1] = "h"		# hexagon
				elseif (t1 == "i" || t1 == "v" || t1 == "inverted_tri")  marca[1] = "i"
				elseif (t1[1] == 'l')                   marca[1] = "l"		# letter
				elseif (t1 == "n" || t1 == "pentagon")  marca[1] = "n"
				elseif (t1 == "p" || t1 == "." || t1 == "point")  marca[1] = "p"
				elseif (t1[1] == 's')                   marca[1] = "s"		# square
				elseif (t1[1] == 't' || t1 == "^")      marca[1] = "t"		# triangle
				elseif (t1[1] == 'T')                   marca[1] = "T"		# Triangle
				elseif (t1[1] == 'y')                   marca[1] = "y"		# y-dash
				end
				t1 = string(t)		# Repeat conversion for the case it was lower-cased above
				# Still need to check the simpler forms of these
				if (marca[1] == "")  marca[1] = helper2_markers(t1, ["e", "ellipse"])   end
				if (marca[1] == "")  marca[1] = helper2_markers(t1, ["E", "Ellipse"])   end
				if (marca[1] == "")  marca[1] = helper2_markers(t1, ["j", "rotrect"])   end
				if (marca[1] == "")  marca[1] = helper2_markers(t1, ["J", "RotRect"])   end
				if (marca[1] == "")  marca[1] = helper2_markers(t1, ["m", "matangle"])  end
				if (marca[1] == "")  marca[1] = helper2_markers(t1, ["M", "Matangle"])  end
				if (marca[1] == "")  marca[1] = helper2_markers(t1, ["r", "rectangle"])   end
				if (marca[1] == "")  marca[1] = helper2_markers(t1, ["R", "RRectangle"])  end
				if (marca[1] == "")  marca[1] = helper2_markers(t1, ["v", "vector"])  end
				if (marca[1] == "")  marca[1] = helper2_markers(t1, ["V", "Vector"])  end
				if (marca[1] == "")  marca[1] = helper2_markers(t1, ["w", "pie", "web"])  end
				if (marca[1] == "")  marca[1] = helper2_markers(t1, ["W", "Pie", "Web"])  end
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
	marca = "";	 msg = ""
	if (size(ext,2) == N && arg1 !== nothing)
		S = Symbol(opt)
		marca, arg1 = add_opt(add_opt, (Dict(S => (par=ext,)), opt, "", [S]), (par="|",), true, arg1)
	elseif (cst && length(ext) == 1)
		marca = opt * "-" * string(ext)
	else
		msg = string("Wrong number of extra columns for marker (", opt, "). Got ", size(ext,2), " but expected ", N)
	end
	return marca, arg1, msg
end

function helper2_markers(opt::String, alias::Vector{String})::String
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
	(marca == "" && opt[1] == alias[1][1]) && (marca = opt)
	return marca
end

# ---------------------------------------------------------------------------------------------------
function check_caller(d::Dict, cmd::String, opt_S::String, opt_W::String, caller::String, g_bar_fill::Array{String}, O::Bool)::String
	# Set sensible defaults for the sub-modules "scatter" & "bar"
	if (caller == "scatter")
		if (opt_S == "")  cmd *= " -Sc5p"  end
	elseif (caller == "scatter3")
		if (opt_S == "")  cmd *= " -Su2p"  end
	elseif (caller == "lines")
		if (!occursin("+p", cmd) && opt_W == "") cmd *= " -W0.25p"  end # Do not leave without a pen specification
	elseif (caller == "bar")
		if (opt_S == "")
			bar_type = 0
			if (haskey(d, :bar))
				cmd, bar_opts = parse_bar_cmd(d, :bar, cmd, "Sb")
				bar_type = 1;	delete!(d, :bar)
			elseif (haskey(d, :hbar))
				cmd, bar_opts = parse_bar_cmd(d, :hbar, cmd, "SB")
				bar_type = 2;	delete!(d, :hbar)
			end
			if (bar_type == 0 || bar_opts == "")	# bar_opts == "" means only bar=true or hbar=true was used
				opt = (haskey(d, :width)) ? add_opt(d, "", "",  [:width]) : "0.8"	# The default
				_Stype = (bar_type == 2) ? " -SB" : " -Sb"
				cmd *= _Stype * opt * "u"

				optB = (haskey(d, :base)) ? add_opt(d, "", "",  [:base]) : "0"
				cmd *= "+b" * optB
			end
		end
		(isempty(g_bar_fill) && !occursin(" -G", cmd) && !occursin(" -C", cmd)) && (cmd *= " -G0/115/190")	# Default color
	elseif (caller == "bar3")
		if (haskey(d, :noshade) && occursin("-So", cmd))
			cmd = replace(cmd, "-So" => "-SO", count=1);
			delete!(d, :noshade)
		end
		if (!occursin(" -G", cmd) && !occursin(" -C", cmd))  cmd *= " -G0/115/190"	end
		if (!occursin(" -J", cmd))  cmd *= " -JX12c/0"  end
	end

	if (occursin('3', caller))
		if (!occursin(" -B", cmd) && !O)  cmd *= def_fig_axes3[1]  end	# For overlays default is no axes
	end

	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_bar_cmd(d::Dict, key::Symbol, cmd::String, optS::String, no_u::Bool=false)::Tuple{String, String}
	# Deal with parsing the 'bar' & 'hbar' keywors of psxy. Also called by plot/bar3. For this
	# later module if input is not a string or NamedTuple the scatter options must be processed in bar3().
	# KEY is either :bar or :hbar
	# OPTS is either "Sb", "SB" or "So"
	# NO_U if true means to NOT automatic adding of flag 'u'
	opt ="";	got_str = false
	if (haskey(d, key))
		if (isa(d[key], String))
			opt, got_str = d[key], true
			cmd *= " -" * optS * opt;	delete!(d, key)
		elseif (isa(d[key], NamedTuple))
			opt = add_opt(d, "", optS, [key], (width="",unit="1",base="+b",height="+B",nbands="+z",Nbands="+Z"))
		elseif (isa(d[key], Bool) && d[key])
		else
			error("Argument of the *bar* keyword can be only a string or a NamedTuple.")
		end
	end

	if (opt != "" && !got_str)				# Still need to finish parsing this
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
	return cmd, opt
end
