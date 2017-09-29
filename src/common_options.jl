# Parse the common options that all GMT modules share, plus some others functions of also common usage

const KW = Dict{Symbol,Any}

function parse_R(cmd::String, d::Dict, force=false)
    if (haskey(d, :R))
        opt_R = build_opt_R(d[:R])
    elseif (haskey(d, :region))
        opt_R = build_opt_R(d[:region])
    elseif (haskey(d, :limits))
        opt_R = build_opt_R(d[:limits])
    else
		if (force) opt_R = " -R"
		else       opt_R = ""
		end
	end
	cmd = cmd * opt_R
end

function build_opt_R(Val)
    if (isa(Val, String))
        return " -R" * Val
    elseif (isa(Val, Array) && length(Val) == 4)
        return @sprintf(" -R%.14g/%.14g/%.14g/%.14g", Val[1], Val[2], Val[3], Val[4])
    end
    return ""
end

# ---------------------------------------------------------------------------------------------------
function parse_J(cmd::String, d::Dict, force=false)
	for symb in [:J :proj :projection]
    	if (haskey(d, symb))
    	    opt_J = build_opt_J(d[symb])
			break
		else
			if (force) opt_J = " -J"
			else       opt_J = ""
			end
		end
	end

	if (!force && !isempty(opt_J))
		# If only the projection but no size, try to get it from the kwargs.
		if (haskey(d, :figwidth))
			if (isa(d[:figwidth], Number))
				s = @sprintf("%.6g", d[:figwidth])
			elseif (isa(d[:figwidth], String))
				s = d[:figwidth]
			else
				error("What the hell is this figwidth argument?")
			end
			if (haskey(d, :units))
				s = s * d[:units][1]
			end
			if (isdigit(opt_J[end]))  opt_J = opt_J * "/" * s
			else                      opt_J = opt_J * s
			end
		elseif (length(opt_J) == 4 || (length(opt_J) >= 5 && isalpha(opt_J[5])))
			opt_J = opt_J * "14c"			# If no size, default to 14 centimeters
		end
	end
	cmd = cmd * opt_J
end

function build_opt_J(Val)
    if (isa(Val, String))
		return " -J" * Val
	end
    return ""
end

# ---------------------------------------------------------------------------------------------------
function parse_B(cmd::String, d::Dict)
	for symb in [:B :frame]
		if (haskey(d, symb))
			opt_B = build_opt_B(d[symb])
			if (!isempty(opt_B))  cmd = cmd * opt_B  end
			break
		end
	end
	return cmd
end

function build_opt_B(Val)
    if (isa(Val, String))
		return " -B" * Val
	end
    return ""
end

# ---------------------------------------------------------------------------------------------------
function parse_X(cmd::String, d::Dict)
	# Parse the global -X option. Return CMD same as input if no -X option in args
    if (haskey(d, :X))
		cmd = cmd * " -X" * arg2str(d[:X])
	elseif (haskey(d, :x_offset))
		cmd = cmd * " -X" * arg2str(d[:x_offset])
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_Y(cmd::String, d::Dict)
	# Parse the global -Y option. Return CMD same as input if no -Y option in args
    if (haskey(d, :Y))
		cmd = cmd * " -Y" * arg2str(d[:Y])
	elseif (haskey(d, :y_offset))
		cmd = cmd * " -Y" * arg2str(d[:y_offset])
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_U(cmd::String, d::Dict)
	# Parse the global -U option. Return CMD same as input if no -U option in args
	if (haskey(d, :U))
		cmd = cmd * " -U" * arg2str(d[:U])
	elseif (haskey(d, :stamp))
		cmd = cmd * " -U" * arg2str(d[:stamp])
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_V(cmd::String, d::Dict)
	# Parse the global -V option. Return CMD same as input if no -V option in args
	for symb in [:V :verbose]
		if (haskey(d, symb))
			if (isa(d[symb], Bool) && d[symb]) cmd = cmd * " -V"
			else                               cmd = cmd * " -V" * arg2str(d[symb])
			end
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_a(cmd::String, d::Dict)
	# Parse the global -a option. Return CMD same as input if no -a option in args
	for symb in [:a :aspatial]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -a" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_bi(cmd::String, d::Dict)
	# Parse the global -bi option. Return CMD same as input if no -bi option in args
	for symb in [:bi :binary_in]
		if (haskey(d, symb))
			cmd = cmd * " -bi" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_bo(cmd::String, d::Dict)
	# Parse the global -bo option. Return CMD same as input if no -bo option in args
	for symb in [:bo :binary_out]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -bo" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_di(cmd::String, d::Dict)
	# Parse the global -di option. Return CMD same as input if no -di option in args
	for symb in [:di :nodata_in]
		if (haskey(d, symb) && isa(d[symb], Number))
			cmd = cmd * " -di" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_e(cmd::String, d::Dict)
	# Parse the global -e option. Return CMD same as input if no -e option in args
	for symb in [:e :pattern]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -e" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_f(cmd::String, d::Dict)
	# Parse the global -f option. Return CMD same as input if no -f option in args
	for symb in [:f :colinfo]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -f" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_g(cmd::String, d::Dict)
	# Parse the global -g option. Return CMD same as input if no -g option in args
	for symb in [:g :gaps]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -g" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_h(cmd::String, d::Dict)
	# Parse the global -h option. Return CMD same as input if no -h option in args
	for symb in [:h :headers]
		if (haskey(d, symb))
			cmd = cmd * " -h" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_i(cmd::String, d::Dict)
	# Parse the global -i option. Return CMD same as input if no -i option in args
	for symb in [:i :input_col]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -i" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_n(cmd::String, d::Dict)
	# Parse the global -n option. Return CMD same as input if no -n option in args
	for symb in [:n :interp :interp_method]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -n" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_swapxy(cmd::String, d::Dict)
	# Parse the global -: option. Return CMD same as input if no -: option in args
	# But because we acn't have a variable called ':' we use only the 'swapxy' alias
	for symb in [:swapxy]
		if (haskey(d, symb))
			cmd = cmd * " -:" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_p(cmd::String, d::Dict)
	# Parse the global -p option. Return CMD same as input if no -p option in args
	for symb in [:p :perspective]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -p" * d[symb]
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_t(cmd::String, d::Dict)
	# Parse the global -t option. Return CMD same as input if no -t option in args
	for symb in [:t :transparency]
		if (haskey(d, symb) && isa(d[symb], Number))
			cmd = @sprintf("%s -t%.6g", cmd, d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_pen(pen::Tuple)
	# Convert a empty to 3 args tuple containing (width[c|i|p]], [color], [style[c|i|p|])
	len = length(pen)
	if (len == 0) return "0.25p" end 	# just the default pen
	if (isa(pen[1], Number))			# First arg is differene because there is no leading ','
		s = @sprintf("%d", pen[1])
	else
		s = @sprintf("%s", pen[1])
	end
	for k = 2:len
		if (isa(pen[k], Number))
			s = @sprintf("%s,%d", s, pen[k])
		else
			s = @sprintf("%s,%s", s, pen[k])
		end
	end
	return s
end

# ---------------------------------------------------------------------------------------------------
function parse_pen_width(d::Dict)
	# Search for a "lw" or "linewidth" specification
	if (haskey(d, :lw))
		if (isa(d[:lw], Number))      return @sprintf("%f", d[:lw])
		elseif (isa(d[:lw], String))  return d[:lw]
		else error("Nonsense in line width argument")
		end
	elseif (haskey(d, :linewidh))
		if (isa(d[:linewidth], Number))      return @sprintf("%f", d[:linewidth])
		elseif (isa(d[:linewidth], String))  return d[:linewidth]
		else error("Nonsense in line width argument")
		end
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function parse_pen_color(d::Dict)
	# Search for a "lc" or "linecolor" specification
	if (haskey(d, :lc))
		if (isa(d[:lc], String))      return d[:lc]
		elseif (isa(d[:lc], Number))  return @sprintf("%d", d[:lc])
		else error("Nonsense in line color argument")
		end
	elseif (haskey(d, :linecolor))
		if (isa(d[:linecolor], String))      return d[:linecolor]
		elseif (isa(d[:linecolor], Number))  return @sprintf("%d", d[:linecolor])
		else error("Nonsense in line color argument")
		end
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function parse_pen_style(d::Dict)
	# Search for a "ls" or "linestyle" specification
	if (haskey(d, :ls))
		if (isa(d[:ls], String))  return d[:ls]
		else error("Nonsense in line style argument")
		end
	elseif (haskey(d, :linestyle))
		if (isa(d[:linestyle], String))  return d[:linestyle]
		else error("Nonsense in line style argument")
		end
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function build_pen(d::Dict)
	# Search for lw, lc, ls in d and create a pen string in case they exist
	# If no pen specs found, return the empty string ""
	s = parse_pen_width(d)
	if (isa(s, Void))  return "" end
	pen = s
	s = parse_pen_color(d)
	if (isa(s, Void))  return pen end
	pen = pen * "," * s
	s = parse_pen_style(d)
	if (!isa(s, Void))
		pen = pen * "," * s
	end
	return pen
end

# ---------------------------------------------------------------------------------------------------
function parse_arg_and_pen(arg::Tuple)
	# Parse an ARG of the type (arg, (pen)) and return a string. These may be used in pscoast -I & -N
	if (isa(arg[1], String))      s = arg[1]
	elseif (isa(arg[1], Number))  s = @sprintf("%d", arg[1])
	else	error("Nonsense first argument")
	end
	if (length(arg) > 1 && isa(arg[2], Tuple))
		s = s * "/" * parse_pen(arg[2])
	end
	return s
end

# ---------------------------------------------------------------------------------------------------
function arg2str(arg)
	# Convert an empty, a numeric or string ARG into a string ... if it's not one to start with
	# ARG can also be a Bool, in which case the TRUE value is converted to "" (empty string)
	if (isa(arg, String))
		out = arg
	elseif (isa(arg, Integer))
		out = @sprintf("%d", arg)
	elseif (isa(arg, Number))
		out = @sprintf("%.6g", arg)
	elseif (isempty(arg) || (isa(arg, Bool) && arg))
		out = ""
	else
		error("Argument 'arg' can only be a String or a Number")
	end
end

# ---------------------------------------------------------------------------------------------------
function finish_PS(cmd0::String, cmd::String, fname::String, output::String, P::Bool, K::Bool, O::Bool)
	# Finish a PS creating command. All PS creating modules should use this.
	if (P) cmd = cmd * " -P" end

	cmd = cmd * cmd0		# Append any other eventual args not send in via kwargs
	
	# Cannot mix -O,-K and output redirect between positional and kwarg arguments
	if (isempty(search(cmd0, "-K")) && isempty(search(cmd0, "-O")) && isempty(search(cmd0, ">")))
		# So the -O -K dance is provided via kwargs
		if (K && !O)              cmd = cmd * " -K > " * fname
		elseif (K && O)           cmd = cmd * " -K -O >> " * fname
		elseif (!K && O)          cmd = cmd * " -O >> " * fname
		elseif (!isempty(output)) cmd = cmd * " > " * fname
		# else no redirection to a file and the PS will be stored in GMT internal memory
		end
	end
	return cmd
end