# Parse the common options that all GMT modules share, plus some others functions of also common usage

const KW = Dict{Symbol,Any}
nt2dict(nt::NamedTuple) = nt2dict(; nt...)
nt2dict(; kw...) = Dict(kw)

function find_in_dict(d::Dict, symbs, del=false)
	# See if D contains any of the symbols in SYMBS. If yes, return corresponding value
	for symb in symbs
		if (haskey(d, symb))
			val = d[symb]
			if (del) delete!(d, symb) end
			return val, symb
		end
	end
	return nothing, 0
end

function parse_R(cmd::String, d::Dict, O=false, del=false)
	# Build the option -R string. Make it simply -R if overlay mode (-O) and no new -R is fished here
	opt_R = ""
	val, symb = find_in_dict(d, [:R :region :limits])
	if (val !== nothing)
		opt_R = build_opt_R(val)
		if (del) delete!(d, symb) end
	end
	if (isempty(opt_R))		# See if we got the region as tuples of xlim, ylim [zlim]
		R = "";		c = 0
		if (haskey(d, :xlim) && isa(d[:xlim], Tuple) && length(d[:xlim]) == 2)
			R = @sprintf(" -R%.15g/%.15g", d[:xlim][1], d[:xlim][2])
			c += 2
			if (haskey(d, :ylim) && isa(d[:ylim], Tuple) && length(d[:ylim]) == 2)
				R = @sprintf("%s/%.15g/%.15g", R, d[:ylim][1], d[:ylim][2])
				c += 2
				if (haskey(d, :zlim) && isa(d[:zlim], Tuple) && length(d[:zlim]) == 2)
					R = @sprintf("%s/%.15g/%.15g", R, d[:zlim][1], d[:zlim][2])
				end
			end
		end
		if (!isempty(R) && c == 4)  opt_R = R  end
	end
	if (O && isempty(opt_R))  opt_R = " -R"  end
	cmd = cmd * opt_R
	return cmd, opt_R
end

function build_opt_R(Val)
	if (isa(Val, String) || isa(Val, Symbol))
		return string(" -R", Val)
	elseif ((isa(Val, Array{<:Number}) || isa(Val, Tuple)) && (length(Val) == 4 || length(Val) == 6))
		out = join([@sprintf("%.15g/",x) for x in Val])
		return " -R" * rstrip(out, '/')		# Remove last '/'
	elseif (isa(Val, GMTgrid) || isa(Val, GMTimage))
		return @sprintf(" -R%.15g/%.15g/%.15g/%.15g", Val.range[1], Val.range[2], Val.range[3], Val.range[4])
	end
	return ""
end

# ---------------------------------------------------------------------------------------------------
function parse_JZ(cmd::String, d::Dict, del=false)
	opt_J = ""
	val, symb = find_in_dict(d, [:JZ :Jz])
	if (val !== nothing)
		if (symb == :JZ)  opt_J = " -JZ" * arg2str(val)
		else              opt_J = " -Jz" * arg2str(val)
		end
		cmd *= opt_J
		if (del) delete!(d, symb) end
	end
	return cmd, opt_J
end

# ---------------------------------------------------------------------------------------------------
function parse_J(cmd::String, d::Dict, default="", map=true, O=false, del=false)
	# Build the option -J string. Make it simply -J if overlay mode (-O) and no new -J is fished here
	# Default to 14c if no size is provided.
	# If MAP == false, do not try to append a fig size
	opt_J = ""
	if ((val = find_in_dict(d, [:J :proj], del)[1]) !== nothing)
		opt_J = build_opt_J(val)
	end
	if (!map && opt_J != "")
		return cmd * opt_J, opt_J
	end

	if (O && opt_J == "")  opt_J = " -J"  end

	if (!O)
		if (opt_J == "")  opt_J = " -JX"  end
		# If only the projection but no size, try to get it from the kwargs.
		if (haskey(d, :figsize))
			s = arg2str(d[:figsize])
			if (haskey(d, :units))  s *= d[:units][1]  end
			if (isdigit(opt_J[end]))  opt_J *= "/" * s
			else                      opt_J *= s
			end
		elseif ((val = find_in_dict(d, [:figscale :scale])[1]) !== nothing)
			val = string(val)
			if (opt_J == " -JX")  isletter(val[1]) ? opt_J = " -J" * val : opt_J = " -Jx" * val	# FRAGILE
			else                  opt_J *= string(val)
			end
		elseif (default != "" && opt_J == "")		# WILL SCREW SO EASILY!!! 
			opt_J = default
		elseif (length(opt_J) == 4 || (length(opt_J) >= 5 && isletter(opt_J[5])))
			if !(length(opt_J) >= 6 && isnumeric(opt_J[6]))
				opt_J *= def_fig_size[1:3]		# If no size, default to 12 centimeters
			end
		end
	end
	cmd *= opt_J
	return cmd, opt_J
end

function build_opt_J(Val)
	if (isa(Val, String) || isa(Val, Symbol))
		s = string(Val)
		if (!isletter(s[1])) error("This (" * s * ") is a bad 'proj' argument. Must start with a char code.") end
		return " -J" * s
	elseif (isa(Val, Number))
		if (!(typeof(Val) <: Int) || Val < 2000)
			error("The only valid case to provide a number to the 'proj' option is when that number is an EPSG code, but this (" * string(Val) * ") is clearly an invalid EPSG")
		end
		return string(" -JX", string(Val))
	elseif (isempty(Val))
		return " -J"
	end
	return ""
end

# ---------------------------------------------------------------------------------------------------
function parse_B(cmd::String, d::Dict, opt_B::String="", del=false)

	# These four are aliases
	extra_parse = true
	if ((val = find_in_dict(d, [:B :frame :axis :axes], del)[1]) !== nothing)
		if (val == :none || val == "none")		# User explicitly said NO AXES
			return cmd * " -B0", " -B0"
		elseif (val == :same || val == "same")	# User explicitly said "Same as previous -B"
			return cmd * " -B", " -B"
		end
		if (isa(val, NamedTuple)) opt_B = axis(val);	extra_parse = false
		else                      opt_B = string(val)
		end
	end

	# Let the :title and x|y_label be given on main kwarg list. Risky if used with NamedTuples way.
	t = ""		# Use the trick to replace blanks by some utf8 char and undo it in extra_parse
	if (haskey(d, :title))   t *= "+t"  * replace(str_with_blancs(d[:title]), ' '=>'\U00AF');   end
	if (haskey(d, :xlabel))  t *= " x+l" * replace(str_with_blancs(d[:xlabel]),' '=>'\U00AF');   end
	if (haskey(d, :ylabel))  t *= " y+l" * replace(str_with_blancs(d[:ylabel]),' '=>'\U00AF');   end
	if (t != "")
		if (opt_B == "")
			opt_B = def_fig_axes
		else
			if !( ((ind = findlast("-B",opt_B)) !== nothing || (ind = findlast(" ",opt_B)) !== nothing) &&
				  (occursin(r"[WESNwesntlbu+g+o]",opt_B[ind[1]:end])) )
				t = " " * t;		# Do not glue, for example, -Bg with :title
			end
		end
		#opt_B = replace(opt_B, "-B" => "")	# Needed so that bellow titles with blanks don't get -B's
		opt_B *= t;		extra_parse = true
	end

	# These are not and we can have one or all of them. NamedTuples are dealt at the end
	for symb in [:xaxis :yaxis :zaxis :axis2 :xaxis2 :yaxis2]
		if (haskey(d, symb) && !isa(d[symb], NamedTuple))
			opt_B = string(d[symb], " ", opt_B)
		end
	end

	if (extra_parse)
		# This is old code that takes care to break a string in tokens and prefix with a -B to each token
		tok = Vector{String}(undef, 10)
		k = 1
		r = opt_B
		found = false
		while (r != "")
			tok[k],r = GMT.strtok(r)
			#=
			if (occursin(r"[WESNwesntlbu+g+o]", tok[k]) && !occursin("+t", tok[k]))		# If title here, forget about :title
				if (haskey(d, :title) && isa(d[:title], String))
					tok[k] = tok[k] * "+t\"" * d[:title] * "\""
				end
			elseif (occursin(r"[afgpsxyz+S+u]", tok[k]) && !occursin(r"[+l+L]", tok[k]))	# If label, forget about :x|y_label
				if (haskey(d, :xlabel) && isa(d[:xlabel], String))  tok[k] = tok[k] * " -Bx+l\"" * d[:xlabel] * "\""  end
				if (haskey(d, :ylabel) && isa(d[:ylabel], String))  tok[k] = tok[k] * " -By+l\"" * d[:ylabel] * "\""  end
			end
			=#
			tok[k] = replace(tok[k], '\U00AF'=>' ')
			if (!occursin("-B", tok[k]))
				if (!occursin('"', tok[k]))
					tok[k] = " -B" * tok[k] 				# Simple case, no quotes to break our heads
				else
					if (!found)  tok[k] = " -B" * tok[k] 	# A title in quotes with spaces
					else         tok[k] = " " * tok[k]
					end
					found = !found
				end
			else
				tok[k] = " " * tok[k]
			end
			k = k + 1
		end
		# Rebuild the B option string
		opt_B = ""
		for n = 1:k-1
			opt_B = opt_B * tok[n]
		end
	end

	# We can have one or all of them. Deal separatelly here to allow way code to keep working
	for symb in [:xaxis :yaxis :zaxis :axis2 :xaxis2 :yaxis2 :zaxis2]
		if (haskey(d, symb) && isa(d[symb], NamedTuple))
			if     (symb == :axis2)   opt_B = axis(d[symb], secondary=true) * opt_B
			elseif (symb == :xaxis)   opt_B = axis(d[symb], x=true) * opt_B
			elseif (symb == :xaxis2)  opt_B = axis(d[symb], x=true, secondary=true) * opt_B
			elseif (symb == :yaxis)   opt_B = axis(d[symb], y=true) * opt_B
			elseif (symb == :yaxis2)  opt_B = axis(d[symb], y=true, secondary=true) * opt_B
			elseif (symb == :zaxis)   opt_B = axis(d[symb], z=true) * opt_B
			end
		end
	end

	if (opt_B != "")  cmd = cmd * opt_B  end
	return cmd, opt_B
end

# ---------------------------------------------------------------------------------------------------
function parse_BJR(d::Dict, cmd::String, caller, O, default, del=false)
	# Join these three in one function. CALLER is non-empty when module is called by plot()
	cmd, opt_R = parse_R(cmd, d, O, del)
	cmd, opt_J = parse_J(cmd, d, default, true, O, del)
	if (!O && opt_J == "")			# If we have no -J use this default
		opt_J = default					# " -JX12c/8c" (e.g. psxy) or " -JX12c/0" (e.g. grdimage)
		cmd *= opt_J
	elseif (O && opt_J == "")
		cmd *= " -J"
	end

	if (caller != "" && occursin("-JX", opt_J))		# e.g. plot() sets 'caller'
		if (caller == "plot3d" || caller == "bar3" || caller == "scatter3")
			cmd, opt_B = parse_B(cmd, d, (O ? "" : def_fig_axes3), del)
		else
			cmd, opt_B = parse_B(cmd, d, (O ? "" : def_fig_axes), del)	# For overlays, default is no axes
		end
	else
		cmd, opt_B = parse_B(cmd, d, (O ? "" : def_fig_axes), del)
	end
	return cmd, opt_B, opt_J, opt_R
end

# ---------------------------------------------------------------------------------------------------
function parse_UXY(cmd::String, d::Dict, aliases, opt::Char)
	# Parse the global -U, -X, -Y options. Return CMD same as input if no option OPT in args
	# ALIASES: [:X :x_off :x_offset] (same for Y) or [:U :time_stamp :stamp]
	if ((val = find_in_dict(d, aliases)[1]) !== nothing)
		cmd = string(cmd, " -", opt, val)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_V(cmd::String, d::Dict)
	# Parse the global -V option. Return CMD same as input if no -V option in args
	if ((val = find_in_dict(d, [:V :verbose])[1]) !== nothing)
		if (isa(val, Bool) && val) cmd *= " -V"
		else                       cmd *= " -V" * arg2str(val)
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_V_params(cmd::String, d::Dict)
	# Parse the global -V option and the --PAR=val. Return CMD same as input if no options in args
	cmd = parse_V(cmd, d)
	return parse_params(cmd, d)
end

# ---------------------------------------------------------------------------------------------------
function parse_UVXY(cmd::String, d::Dict)
	cmd = parse_V(cmd, d)
	cmd = parse_UXY(cmd, d, [:X :x_off :off_x :x_offset], 'X')
	cmd = parse_UXY(cmd, d, [:Y :y_off :off_y :y_offset], 'Y')
	cmd = parse_UXY(cmd, d, [:U :stamp :time_stamp], 'U')
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_a(cmd::String, d::Dict)
	# Parse the global -a option. Return CMD same as input if no -a option in args
	return parse_helper(cmd, d, [:a :aspatial], " -a")
end

# ---------------------------------------------------------------------------------------------------
function parse_b(cmd::String, d::Dict)
	# Parse the global -b option. Return CMD same as input if no -b option in args
	return parse_helper(cmd, d, [:b :binary], " -b")
end

# ---------------------------------------------------------------------------------------------------
function parse_bi(cmd::String, d::Dict)
	# Parse the global -bi option. Return CMD same as input if no -bi option in args
	return parse_helper(cmd, d, [:bi :binary_in], " -bi")
end

# ---------------------------------------------------------------------------------------------------
function parse_bo(cmd::String, d::Dict)
	# Parse the global -bo option. Return CMD same as input if no -bo option in args
	return parse_helper(cmd, d, [:bo :binary_out], " -bo")
end

# ---------------------------------------------------------------------------------------------------
function parse_d(cmd::String, d::Dict)
	# Parse the global -di option. Return CMD same as input if no -di option in args
	return parse_helper(cmd, d, [:d :nodata], " -d")
end

# ---------------------------------------------------------------------------------------------------
function parse_di(cmd::String, d::Dict)
	# Parse the global -di option. Return CMD same as input if no -di option in args
	return parse_helper(cmd, d, [:di :nodata_in], " -di")
end

# ---------------------------------------------------------------------------------------------------
function parse_do(cmd::String, d::Dict)
	# Parse the global -do option. Return CMD same as input if no -do option in args
	return parse_helper(cmd, d, [:do :nodata_out], " -do")
end

# ---------------------------------------------------------------------------------------------------
function parse_e(cmd::String, d::Dict)
	# Parse the global -e option. Return CMD same as input if no -e option in args
	return parse_helper(cmd, d, [:e :pattern], " -e")
end

# ---------------------------------------------------------------------------------------------------
function parse_f(cmd::String, d::Dict)
	# Parse the global -f option. Return CMD same as input if no -f option in args
	return parse_helper(cmd, d, [:f :colinfo], " -f")
end

# ---------------------------------------------------------------------------------------------------
function parse_g(cmd::String, d::Dict)
	# Parse the global -g option. Return CMD same as input if no -g option in args
	return parse_helper(cmd, d, [:g :gaps], " -g")
end

# ---------------------------------------------------------------------------------------------------
function parse_h(cmd::String, d::Dict)
	# Parse the global -h option. Return CMD same as input if no -h option in args
	return parse_helper(cmd, d, [:h :headers], " -h")
end

# ---------------------------------------------------------------------------------------------------
function parse_i(cmd::String, d::Dict)
	# Parse the global -i option. Return CMD same as input if no -i option in args
	return parse_helper(cmd, d, [:i :input_col], " -i")
end

# ---------------------------------------------------------------------------------------------------
function parse_n(cmd::String, d::Dict)
	# Parse the global -n option. Return CMD same as input if no -n option in args
	return parse_helper(cmd, d, [:n :interp :interp_method], " -n")
end

# ---------------------------------------------------------------------------------------------------
function parse_o(cmd::String, d::Dict)
	# Parse the global -o option. Return CMD same as input if no -o option in args
	return parse_helper(cmd, d, [:o :output_col], " -o")
end

# ---------------------------------------------------------------------------------------------------
function parse_p(cmd::String, d::Dict)
	# Parse the global -p option. Return CMD same as input if no -p option in args
	return parse_helper(cmd, d, [:p :view], " -p")
end

# ---------------------------------------------------------------------------------------------------
function parse_s(cmd::String, d::Dict)
	# Parse the global -s option. Return CMD same as input if no -s option in args
	return parse_helper(cmd, d, [:s :skip_col], " -s")
end

# ---------------------------------------------------------------------------------------------------
function parse_swap_xy(cmd::String, d::Dict)
	# Parse the global -: option. Return CMD same as input if no -: option in args
	# But because we can't have a variable called ':' we use only the 'swap_xy' alias
	return parse_helper(cmd, d, [:swap_xy :xy], " -:")
end

# ---------------------------------------------------------------------------------------------------
function parse_r(cmd::String, d::Dict)
	# Parse the global -r option. Return CMD same as input if no -r option in args
	return parse_helper(cmd, d, [:r :reg :registration], " -r")
end

# ---------------------------------------------------------------------------------------------------
function parse_x(cmd::String, d::Dict)
	# Parse the global -x option. Return CMD same as input if no -x option in args
	return parse_helper(cmd, d, [:x :n_threads], " -x")
end

# ---------------------------------------------------------------------------------------------------
function parse_t(cmd::String, d::Dict)
	# Parse the global -t option. Return CMD same as input if no -t option in args
	return parse_helper(cmd, d, [:t :alpha :transparency], " -t")
end

# ---------------------------------------------------------------------------------------------------
function parse_helper(cmd::String, d::Dict, symbs, opt::String)
	# Helper function to the parse_?() global options. Isolate in a fun to not repeat over and over
	opt_val = ""
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		opt_val = opt * arg2str(val)
		cmd *= opt_val
	end
	return cmd, opt_val
end

# ---------------------------------------------------------------------------------------------------
function parse_common_opts(d, cmd, opts)
	for opt in opts
		if     (opt == :a)  cmd, = parse_a(cmd, d)
		elseif (opt == :b)  cmd, = parse_b(cmd, d)
		elseif (opt == :bi) cmd, = parse_bi(cmd, d)
		elseif (opt == :bo) cmd, = parse_bo(cmd, d)
		elseif (opt == :d)  cmd, = parse_d(cmd, d)
		elseif (opt == :di) cmd, = parse_di(cmd, d)
		elseif (opt == :do) cmd, = parse_do(cmd, d)
		elseif (opt == :e)  cmd, = parse_e(cmd, d)
		elseif (opt == :f)  cmd, = parse_f(cmd, d)
		elseif (opt == :g)  cmd, = parse_g(cmd, d)
		elseif (opt == :h)  cmd, = parse_h(cmd, d)
		elseif (opt == :i)  cmd, = parse_i(cmd, d)
		elseif (opt == :n)  cmd, = parse_n(cmd, d)
		elseif (opt == :o)  cmd, = parse_o(cmd, d)
		elseif (opt == :p)  cmd, = parse_p(cmd, d)
		elseif (opt == :r)  cmd, = parse_r(cmd, d)
		elseif (opt == :s)  cmd, = parse_p(cmd, d)
		elseif (opt == :x)  cmd, = parse_x(cmd, d)
		elseif (opt == :t)  cmd, = parse_t(cmd, d)
		elseif (opt == :xy) cmd, = parse_swap_xy(cmd, d)
		elseif (opt == :R)  cmd, = parse_R(cmd, d)
		elseif (opt == :J)  cmd, = parse_J(cmd, d)
		elseif (opt == :JZ) cmd, = parse_JZ(cmd, d)
		elseif (opt == :UVXY) cmd = parse_UVXY(cmd, d)
		elseif (opt == :V_params) cmd = parse_V_params(cmd, d)
		elseif (opt == :params) cmd = parse_params(cmd, d)
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_inc(cmd::String, d::Dict, symbs, opt, del=false)
	# Parse the quasi-global -I option. But arguments can be strings, arrays, tuples or NamedTuples
	# At the end we must recreate this syntax: xinc[unit][+e|n][/yinc[unit][+e|n]] or 
	if ((val = find_in_dict(d, symbs, del)[1]) !== nothing)
		if (isa(val, NamedTuple))
			fn = fieldnames(typeof(val))
			x = "";	y = "";	u = "";	e = false
			for k = 1:length(fn)
				if     (fn[k] == :x)     x  = string(val[k])
				elseif (fn[k] == :y)     y  = string(val[k])
				elseif (fn[k] == :unit)  u  = string(val[k])
				elseif (fn[k] == :extend) e = true
				end
			end
			if (x == "") error("Need at least the x increment")	end
			cmd = string(cmd, " -", opt, x)
			if (u != "")
				if (u == "m" || u == "minutes" || u == "s" || u == "seconds" ||
					u == "f" || u == "foot"    || u == "k" || u == "km" || u == "n" || u == "nautical")
					cmd *= u[1]
				elseif (u == "e" || u == "meter") cmd *= "e";	u = "e"
				elseif (u == "M" || u == "mile")  cmd *= "M";	u = "M"
				elseif (u == "nodes")             cmd *= "+n";	u = "+n"
				elseif (u == "data")              u = "u";		# For the `scatter` modules
				end
			end
			if (e)  cmd *= "+e"  end
			if (y != "")
				cmd = string(cmd, "/", y, u)
				if (e)  cmd *= "+e"  end		# Should never have this and u != ""
			end
		else
			if (opt != "")  cmd = string(cmd, " -", opt, arg2str(val))
			else            cmd = string(cmd, arg2str(val))
			end
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_params(cmd::String, d::Dict)
	# Parse the gmt.conf parameters when used from within the modules. Return a --PAR=val string
	# The input to this kwarg can be a tuple (e.g. (PAR,val)) or a NamedTuple (P1=V1, P2=V2,...)

	if ((val = find_in_dict(d, [:conf :par :params])[1]) !== nothing)
		if (isa(val, NamedTuple))
			fn = fieldnames(typeof(val))
			for k = 1:length(fn)		# Suspect that this is higly inefficient but N is small
				cmd *= " --" * string(fn[k]) * "=" * string(val[k])
			end
		elseif (isa(val, Tuple))
			cmd *= " --" * string(val[1]) * "=" * string(val[2])
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt_pen(d::Dict, symbs, opt="", del::Bool=false)
	# Build a pen option. Input can be either a full hard core string or spread in lw, lc, lw, etc or a tuple
	if (opt != "")  opt = " -" * opt  end 	# Will become -W<pen>, for example
	out = ""
	pen = build_pen(d, del)					# Either a full pen string or empty ("") (Seeks for lw, lc, etc)
	if (pen != "")
		out = opt * pen
	else
		if ((val = find_in_dict(d, symbs, del)[1]) !== nothing)
			if (isa(val, Tuple))			# Like this it can hold the pen, not extended atts
				out = opt * parse_pen(val)	# Should be a better function
			elseif (isa(val, NamedTuple))	# Make a recursive call. Will screw if used in mix mode
				d2 = nt2dict(val)			# Decompose the NT and feed into this-self
				return opt * add_opt_pen(d2, symbs, "")
			else
				out = opt * arg2str(val)
			end
		end
	end

	# Some -W take extra options to indicate that color comes from CPT
	if (haskey(d, :cline))  out *= "+cl"  end
	if (haskey(d, :ctext) || haskey(d, :csymbol))  out *= "+cf"  end
	if (haskey(d, :bezier))  out *= "+s"  end
	if (haskey(d, :offset))  out *= "+o" * arg2str(d[:offset])   end

	if (out != "")		# Search for eventual vec specs, but only if something above has activated -W
		r = helper_arrows(d)
		if (r != "")
			if     (haskey(d, :vec_start))  out *= "+vb" * r[2:end]	# r[1] = 'v'
			elseif (haskey(d, :vec_stop))   out *= "+ve" * r[2:end]
			else   out *= "+" * r
			end
		end
	end

	return out
end

# ---------------------------------------------------------------------------------------------------
function opt_pen(d::Dict, opt::Char, symbs)
	# Create an option string of the type -Wpen
	out = ""
	pen = build_pen(d)						# Either a full pen string or empty ("")
	if (!isempty(pen))
		out = string(" -", opt, pen)
	else
		if ((val = find_in_dict(d, symbs)[1]) !== nothing)
			if (isa(val, String) || isa(val, Number))
				out = string(" -", opt, val)
			elseif (isa(val, Tuple))	# Like this it can hold the pen, not extended atts
				out = string(" -", opt, parse_pen(val))
			else
				error(string("Nonsense in ", opt, " option"))
			end
		end
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
function parse_pen(pen::Tuple)
	# Convert an empty to 3 args tuple containing (width[c|i|p]], [color], [style[c|i|p|])
	len = length(pen)
	if (len == 0) return "0.25p" end 	# just the default pen
	s = arg2str(pen[1])					# First arg is different because there is no leading ','
	if (length(pen) > 1)
		s *= ',' * get_color(pen[2])
		if (length(pen) > 2)  s *= ',' * arg2str(pen[3])  end
	end
	return s
end

# ---------------------------------------------------------------------------------------------------
function parse_pen_color(d::Dict, symbs=nothing, del::Bool=false)
	# Need this as a separate fun because it's used from modules
	lc = ""
	if (symbs === nothing)  symbs = [:lc :linecolor]  end
	if ((val = find_in_dict(d, symbs, del)[1]) !== nothing)
		lc = get_color(val)
	end
	return lc
end

# ---------------------------------------------------------------------------------------------------
function build_pen(d::Dict, del::Bool=false)
	# Search for lw, lc, ls in d and create a pen string in case they exist
	# If no pen specs found, return the empty string ""
	lw = add_opt("", "", d, [:lw :linewidth], nothing, del)	# Line width
	ls = add_opt("", "", d, [:ls :linestyle], nothing, del)	# Line style
	lc = parse_pen_color(d, [:lc :linecolor], del)
	out = ""
	if (lw != "" || lc != "" || ls != "")
		out = lw * "," * lc * "," * ls
		while (out[end] == ',')  out = rstrip(out, ',')  end	# Strip unneeded commas
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
function parse_arg_and_pen(arg::Tuple)
	# Parse an ARG of the type (arg, (pen)) and return a string. These may be used in pscoast -I & -N
	if (isa(arg[1], String))      s = arg[1]
	elseif (isa(arg[1], Number))  s = @sprintf("%d", arg[1])
	else	error("Nonsense first argument")
	end
	if (length(arg) > 1 && isa(arg[2], Tuple))  s *= "/" * parse_pen(arg[2])  end
	return s
end

# ---------------------------------------------------------------------------------------------------
function arg2str(arg)
	# Convert an empty, a numeric or string ARG into a string ... if it's not one to start with
	# ARG can also be a Bool, in which case the TRUE value is converted to "" (empty string)
	if (isa(arg, String) || isa(arg, Symbol))
		out = string(arg)
	elseif (isempty_(arg) || (isa(arg, Bool) && arg))
		out = ""
	elseif (isa(arg, Number))		# Have to do it after the Bool test above because Bool is a Number too
		out = @sprintf("%.15g", arg)
	elseif (isa(arg, Array{<:Number}) || isa(arg, Tuple))
		out = join([@sprintf("%.15g/",x) for x in arg])
		out = rstrip(out, '/')		# Remove last '/'
	else
		error(@sprintf("arg2str: argument 'arg' can only be a String, Symbol, Number, Array or a Tuple,
		                but was %s", typeof(arg)))
	end
end

# ---------------------------------------------------------------------------------------------------
function set_KO(cmd, opt_B, first, K, O)
	# Set the O K pair dance
	if (first)  K = true;	O = false
	else        K = true;	O = true;
	end
	return cmd, K, O, opt_B
end

# ---------------------------------------------------------------------------------------------------
function finish_PS(d::Dict, cmd::String, output::String, K::Bool, O::Bool)
	# Finish a PS creating command. All PS creating modules should use this.
	if (!haskey(d, :P) && !haskey(d, :portrait))  cmd *= " -P"  end

	if (K && !O)              opt = " -K"
	elseif (K && O)           opt = " -K -O"
	elseif (!K && O)          opt = " -O"
	else                      opt = ""
	end

	if (output != "")
		if (K && !O)          cmd *= opt * " > " * output
		elseif (!K && !O)     cmd *= opt * " > " * output
		elseif (O)            cmd *= opt * " >> " * output
		end
	else
		if (K && !O)          cmd *= opt
		elseif (!K && !O)     cmd *= opt
		elseif (O)            cmd *= opt
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt(cmd::String, opt, d::Dict, symbs, mapa=nothing, del::Bool=false, arg=nothing)
	# Scan the D Dict for SYMBS keys and if found create the new option OPT and append it to CMD
	# If DEL == true we remove the found key.
	if ((val = find_in_dict(d, symbs, del)[1]) !== nothing)
		if (isa(val, NamedTuple))  args = add_opt(val, mapa, arg)
		else                       args = arg2str(val)
		end
		if (opt != "")  cmd = string(cmd, " -", opt, args)
		else            cmd = string(cmd, args)
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt(nt::NamedTuple, mapa::NamedTuple, arg=nothing)
	# Generic parser of options passed in a NT and whose last element is anther NT with the mapping
	# between expanded sub-options names and the original GMT flags.
	# Example: 
	#	add_opt((a=(1,0.5),b=2), (a="+a",b="-b"))
	# translates to:	"+a1/0.5-b2"
	key = keys(nt);
	d = nt2dict(mapa)				# The flags mapping as a Dict
	cmd = ""
	for k = 1:length(key)			# Loop over the keys of option's tuple
		if (haskey(d, key[k]))
			if (d[key[k]] == "1")	# Means that only first char in value is retained. Used with units
				t = arg2str(nt[k])
				if (t != "")  cmd *= t[1]
				else          cmd *= "1"	# "1" is itself the flag
				end
			elseif (d[key[k]] != "" && d[key[k]][1] == '|')		# Potentialy append to the arg matrix
				if (arg === nothing)
					@warn(@sprintf("The key %s implies appending to input but the 'arg' variable is empty. Ignoring it.",key[k]))
					continue
				end
				if (isa(nt[k], AbstractArray) || isa(nt[k], NTuple))
					if (mod(length(arg), length(nt[k])) != 0)
						@warn("The columns to be appended do not have the same number of rows as the input data. Ignoring it.")
						continue
					end
					if (isa(nt[k], AbstractArray))  append!(arg, reshape(nt[k], :))
					else                            append!(arg, reshape(collect(nt[k]), :))
					end
				end
				cmd *= d[key[k]][2:end]		# And now append the flag
			else
				cmd *= d[key[k]] * arg2str(nt[k])
			end
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt_cpt(d::Dict, cmd::String, symbs, opt::Char, N_args=0, arg1=[], arg2=[])
	# Deal with options of the form -Ccolor, where color can be a string or a GMTcpt type
	# N_args only applyies to when a GMTcpt was transmitted. Than it's either 0, case in which
	# the cpt is put in arg1, or 1 and the cpt goes to arg2.
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		if (isa(val, GMT.GMTcpt))
			cmd = string(cmd, " -", opt)
			if     (N_args == 0)  arg1 = val;	N_args += 1
			elseif (N_args == 1)  arg2 = val;	N_args += 1
			else   error(string("Can't send the CPT data via ", opt, " and input array"))
			end
		else
			cmd = string(cmd, " -", opt, get_color(val))
		end
	end
	return cmd, arg1, arg2, N_args
end

# ---------------------------------------------------------------------------------------------------
function add_opt_fill(cmd::String, opt, d::Dict, symbs)
	# Deal with the area fill attributes option. Normally, -G
	if ((val = find_in_dict(d, symbs)[1]) === nothing)  return cmd  end
	if (isa(val, NamedTuple))
		d2 = nt2dict(val)
		cmd *= " -" * opt
		if     (haskey(d2, :pattern))     cmd *= 'p' * add_opt("", "", d2, [:pattern])
		elseif (haskey(d2, :inv_pattern)) cmd *= 'P' * add_opt("", "", d2, [:inv_pattern])
		else   error("For 'fill' option as a NamedTuple, you MUST provide a 'patern' member")
		end

		if ((val2 = find_in_dict(d2, [:bg :background])[1]) !== nothing)
			cmd *= "+b" * get_color(val2)
		end
		if ((val2 = find_in_dict(d2, [:fg :foreground])[1]) !== nothing)
			cmd *= "+f" * get_color(val2)
		end
		if (haskey(d2, :dpi))  cmd = string(cmd, "+r", d2[:dpi])  end
	else
		cmd *= " -" * opt * get_color(val)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function get_color(val)
	# Parse a color input. Always return a string
	# color1,color2[,color3,…] colorn can be a r/g/b triplet, a color name, or an HTML hexadecimal color (e.g. #aabbcc 
	if (isa(val, String) || isa(val, Symbol) || isa(val, Number))  return string(val)  end

	if (isa(val, Tuple) && (length(val) == 3))
		if (val[1] <= 1 && val[2] <= 1 && val[3] <= 1)		# Assume colors components are in [0 1]
			return @sprintf("%d/%d/%d", val[1]*255, val[2]*255, val[3]*255)
		else
			return @sprintf("%d/%d/%d", val[1], val[2], val[3])
		end
	elseif (isa(val, Array) && (size(val, 2) == 3))
		if (val[1,1] <= 1 && val[1,2] <= 1 && val[1,3] <= 1)
			copy = val .* 255		# Do not change the original
		else
			copy = val
		end
		out = @sprintf("%d/%d/%d", copy[1], copy[2], copy[3])
		for k = 2:size(copy, 1)
			out = @sprintf("%s,%d/%d/%d", out, copy[k,1], copy[k,2], copy[k,3])
		end
		return out
	else
		error(@sprintf("GOT_COLOR, got and unsupported data type: %s", typeof(val)))
	end
end

# ---------------------------------------------------------------------------------------------------
function font(val)
	# parse and create a font string.
	# TODO: either add a NammedTuple option and/or guess if 2nd arg is the font name or the color
	# And this: Optionally, you may append =pen to the fill value in order to draw the text outline with
	# the specified pen; if used you may optionally skip the filling of the text by setting fill to -.
	if (isa(val, String) || isa(val, Number))  return string(val)  end

	if (isa(val, Tuple))
		s = parse_units(val[1])
		if (length(val) > 1)
			s = string(s,',',val[2])
			if (length(val) > 2)
				s = string(s, ',', get_color(val[3]))
			end
		end
	end
end

# ---------------------------------------------------------------------------------------------------
function parse_units(val)
	# Parse a units string in the form d|e|f|k|n|M|n|s or expanded
	if (isa(val, String) || isa(val, Symbol) || isa(val, Number))  return string(val)  end

	if (isa(val, Tuple) && (length(val) == 2))
		return string(val[1]) * parse_unit_uint(val[2])
	else
		error(@sprintf("PARSE_UNITS, got and unsupported data type: %s", typeof(val)))
	end
end

# ---------------------------
function parse_unit_unit(str)
	out = ""
	if (isa(str, Symbol))  str = string(str)  end
	if (!isa(str, String))
		error(@sprintf("Argument data type must be String or Symbol but was: %s", typeof(str)))
	end
	if (str == "m" || str == "minutes" || str == "s" || str == "seconds" || str == "d" || str == "degrees" ||
		str == "f" || str == "foot"    || str == "k" || str == "km" || str == "n" || str == "nautical")
		out = str[1]
	elseif (str == "e" || str == "meter")
		out = "e";
	elseif (str == "M" || str == "mile")
		out = "M";
	elseif (str == "nodes")		# 
		out = cmd * "+n";
	elseif (str == "data")		# For the `scatter` modules
		out = "u";
	end
	return out
end
# ---------------------------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------------------------
axis(nt::NamedTuple; x=false, y=false, z=false, secondary=false) = axis(;x=x, y=y, z=z, secondary=secondary, nt...)
function axis(;x=false, y=false, z=false, secondary=false, kwargs...)
	# Build the (terrible) -B option
	d = KW(kwargs)

	# Before anything else
	if (haskey(d, :none)) return " -B0"  end

	secondary ? primo = 's' : primo = 'p'			# Primary or secondary axe
	x ? axe = "x" : y ? axe = "y" : z ? axe = "z" : axe = ""	# Are we dealing with a specific axis?

	opt = " -B"
	if (haskey(d, :axes)) opt *= helper0_axes(d[:axes])  end

	if (haskey(d, :corners)) opt *= string(d[:corners])  end	# 1234
	if (haskey(d, :fill))    opt *= "+g" * get_color(d[:fill])  end
	if (haskey(d, :cube))    opt *= "+b"  end
	if (haskey(d, :noframe)) opt *= "+n"  end
	if (haskey(d, :oblique_pole))  opt *= "+o" * arg2str(d[:oblique_pole])  end
	if (haskey(d, :title))   opt *= "+t" * str_with_blancs(arg2str(d[:title]))  end

	if (opt == " -B")  opt = ""  end	# If nothing, no -B

	# axes supps
	ax_sup = ""
	if (haskey(d, :seclabel))   ax_sup *= "+s" * str_with_blancs(arg2str(d[:seclabel]))   end

	if (haskey(d, :label))
		opt *= " -B" * primo * axe * "+l"  * str_with_blancs(arg2str(d[:label])) * ax_sup
	else
		if (haskey(d, :xlabel))  opt *= " -B" * primo * "x+l" * str_with_blancs(arg2str(d[:xlabel])) * ax_sup  end
		if (haskey(d, :zlabel))  opt *= " -B" * primo * "z+l" * str_with_blancs(arg2str(d[:zlabel])) * ax_sup  end
		if (haskey(d, :ylabel))
			opt *= " -B" * primo * "y+l" * str_with_blancs(arg2str(d[:ylabel])) * ax_sup
		elseif (haskey(d, :Yhlabel))
			axe != "y" ? opt_L = "y+L" : opt_L = "+L"
			opt *= " -B" * primo * axe * opt_L  * str_with_blancs(arg2str(d[:Yhlabel])) * ax_sup
		end
	end

	# intervals
	ints = ""
	if (haskey(d, :annot))      ints *= "a" * helper1_axes(d[:annot])  end
	if (haskey(d, :annot_unit)) ints *= helper2_axes(d[:annot_unit])   end
	if (haskey(d, :ticks))      ints *= "f" * helper1_axes(d[:ticks])  end
	if (haskey(d, :grid))       ints *= "g" * helper1_axes(d[:grid])   end
	if (haskey(d, :prefix))     ints *= "+p" * str_with_blancs(arg2str(d[:prefix]))  end
	if (haskey(d, :suffix))     ints *= "+u" * str_with_blancs(arg2str(d[:suffix]))  end
	if (haskey(d, :custom))
		if (isa(d[:custom], String))  ints *= 'c' * d[:custom]
		else
			if ((r = helper3_axes(d[:custom], primo, axe)) != "")  ints = ints * 'c' * r  end
		end
		# Should find a way to also accept custom=GMTdataset
	elseif (haskey(d, :pi))
		if (isa(d[:pi], Number))
			ints = string(ints, d[:pi], "pi")		# (n)pi
		elseif (isa(d[:pi], Array) || isa(d[:pi], Tuple))
			ints = string(ints, d[:pi][1], "pi", d[:pi][2])	# (n)pi(m)
		end
	elseif (haskey(d, :scale))
		s = arg2str(d[:scale])
		if     (s == "log")    ints *= 'l'
		elseif (s == "10log")  ints *= 'p'
		elseif (s == "exp")    ints *= 'p'
		end
	end
	if (haskey(d, :phase_add))
		ints *= "+" * arg2str(d[:phase_add])
	elseif (haskey(d, :phase_sub))
		ints *= "-" * arg2str(d[:phase_sub])
	end
	if (ints != "") opt *= " -B" * primo * axe * ints  end

	# Check if ax_sup was requested
	if (opt == "" && ax_sup != "")  opt = " -B" * primo * axe * ax_sup  end

	return opt
end

# ------------------------
function helper0_axes(arg)
	# Deal with the available ways of specifying the WESN(Z),wesn(z),lbrt(u)
	# The solution is very enginious and allows using "left_full", "l_full" or only "l_f"
	# to mean 'W'. Same for others:
	# bottom|bot|b_f(ull);  right|r_f(ull);  t(op)_f(ull);  up_f(ull)  => S, E, N, Z
	# bottom|bot|b_t(icks); right|r_t(icks); t(op)_t(icks); up_t(icks) => s, e, n, z
	# bottom|bot|b_b(are);  right|r_b(are);  t(op)_b(are);  up_b(are)  => b, r, t, u

	if (isa(arg, String) || isa(arg, Symbol))	# Assume that a WESNwesn string was already sent in.
		return string(arg)
	end

	if (!isa(arg, Tuple))
		error(@sprintf("The 'axes' argument must be a String, Symbol or a Tuple but was (%s)", typeof(arg)))
	end

	opt = ""
	for k = 1:length(arg)
		t = string(arg[k])		# For the case it was a symbol
		if (occursin("_f", t))
			if     (t[1] == 'l')  opt *= "W"
			elseif (t[1] == 'b')  opt *= "S"
			elseif (t[1] == 'r')  opt *= "E"
			elseif (t[1] == 't')  opt *= "N"
			elseif (t[1] == 'u')  opt *= "Z"
			end
		elseif (occursin("_t", t))
			if     (t[1] == 'l')  opt *= "w"
			elseif (t[1] == 'b')  opt *= "s"
			elseif (t[1] == 'r')  opt *= "e"
			elseif (t[1] == 't')  opt *= "n"
			elseif (t[1] == 'u')  opt *= "z"
			end
		elseif (occursin("_b", t))
			if     (t[1] == 'l')  opt *= "l"
			elseif (t[1] == 'b')  opt *= "b"
			elseif (t[1] == 'r')  opt *= "r"
			elseif (t[1] == 't')  opt *= "t"
			elseif (t[1] == 'u')  opt *= "u"
			end
		end
	end
	return opt
end

# ------------------------
function helper1_axes(arg)
	# Used by annot, ticks and grid to accept also 'auto', [] and "" to mean automatic
	out = arg2str(arg)
	if (out != "" && out[1] == 'a')  out = ""  end
	return out
end
# ------------------------
function helper2_axes(arg)
	# Used by 
	out = arg2str(arg)
	if (out == "")
		@warn("Empty units. Ignoring this units request.")
		return out
	end
	if     (out == "Y" || out == "year")     out = 'Y'
	elseif (out == "y" || out == "year2")    out = 'y'
	elseif (out == "O" || out == "month")    out = 'O'
	elseif (out == "o" || out == "month2")   out = 'o'
	elseif (out == "U" || out == "ISOweek")  out = 'U'
	elseif (out == "u" || out == "ISOweek2") out = 'u'
	elseif (out == "r" || out == "Gregorian_week") out = 'r'
	elseif (out == "K" || out == "ISOweekday") out = 'K'
	elseif (out == "D" || out == "date")     out = 'D'
	elseif (out == "d" || out == "day_date") out = 'd'
	elseif (out == "R" || out == "day_week") out = 'R'
	elseif (out == "H" || out == "hour")     out = 'H'
	elseif (out == "h" || out == "hour2")    out = 'h'
	elseif (out == "M" || out == "minute")   out = 'M'
	elseif (out == "m" || out == "minute2")  out = 'm'
	elseif (out == "S" || out == "second")   out = 'S'
	elseif (out == "s" || out == "second2")  out = 's'
	else
		@warn("Unknown units request (" * out * ") Ignoring it")
		out = ""
	end
	return out
end
# ------------------------
function helper3_axes(arg, primo, axe)
	# Parse the custom annotations arg, save result into a tmp file and return its name	

	label = ""
	if (isa(arg, AbstractArray))
		pos = arg
		n_annot = length(pos)
		tipo = fill('a', n_annot)			# Default to annotate
	elseif (isa(arg, NamedTuple))
		d = nt2dict(arg)
		if (!haskey(d, :pos))
			error("The custom annotations NamedTuple must contain at least the named member 'pos'")
		end
		pos = d[:pos]
		n_annot = length(pos)
		if ((val = find_in_dict(d, [:type_ :type])[1]) !== nothing)
			if (isa(val, Char) || isa(val, String) || isa(val, Symbol))
				tipo = Array{Any,1}(undef, n_annot)
				for k = 1:n_annot  tipo[k] = val  end
			else
				tipo = val		# Assume it's a good guy, otherwise ...
			end
		else
			tipo = fill('a', n_annot)		# Default to annotate
		end

		if (haskey(d, :label))
			if (!isa(d[:label], Array) || length(d[:label]) != n_annot)
				error("Number of labels in custom annotations must be the same as the 'pos' element")
			end
			label = d[:label]
		end
	else
		@warn("Argument of the custom annotations must be an N-array or a NamedTuple")
		return ""
	end

	temp = "GMTjl_custom_" * primo
	if (axe != "") temp *= axe  end
	@static Sys.iswindows() ? fname = tempdir() * temp * ".txt" : fname = tempdir() * "/" * temp * ".txt" 
	fid = open(fname, "w")
	if (label != "")
		for k = 1:n_annot
			println(fid, pos[k], ' ', tipo[k], ' ', label[k])
		end
	else
		for k = 1:n_annot
			println(fid, pos[k], ' ', tipo[k])
		end
	end
	close(fid)
	return fname
end
# ---------------------------------------------------------------------------------------------------

function str_with_blancs(str)
	# If the STR string has spaces enclose it with quotes
	out = string(str)
	if (occursin(" ", out))  out = string("\"", out, "\"")  end
	return out
end

# ---------------------------------------------------------------------------------------------------
vector_attrib(t::NamedTuple) = vector_attrib(; t...)
function vector_attrib(;kwargs...)
	d = KW(kwargs)
	cmd = add_opt("", "", d, [:len :length])
	if (haskey(d, :angle))  cmd = string(cmd, "+a", d[:angle])  end
	if (haskey(d, :middle))
		cmd = cmd * "+m";
		if (d[:middle] == "reverse" || d[:middle] == :reverse)	cmd = cmd * "r"  end
		cmd = helper_vec_loc(d, :middle, cmd)
	else
		for symb in [:start :stop]
			if (haskey(d, symb) && symb == :start)
				cmd = cmd * "+b";
				cmd = helper_vec_loc(d, :start, cmd)
			elseif (haskey(d, symb) && symb == :stop)
				cmd = cmd * "+e";
				cmd = helper_vec_loc(d, :stop, cmd)
			end
		end
	end

	if (haskey(d, :justify))
		if     (d[:justify] == "beginning" || d[:justify] == :beginning)  cmd *= "+jb"
		elseif (d[:justify] == "end"       || d[:justify] == :end)        cmd *= "+je"
		elseif (d[:justify] == "center"    || d[:justify] == :center)     cmd *= "+jc"
		end
	end

	if (haskey(d, :half_arrow))
		if (d[:half_arrow] == "left" || d[:half_arrow] == :left)	cmd *= "+l"
		else	cmd *= "+r"		# Whatever, gives right half
		end
	end

	if (haskey(d, :fill))
		if (d[:fill] == "none" || d[:fill] == :none) cmd *= "+g-"
		else	cmd *= "+g" * get_color(d[:fill])		# MUST GET TESTS TO THIS
		end
	end

	if (haskey(d, :norm))
		if (GMTver < 6 && isa(d[:norm], String) && !isletter(d[:norm][end]))	# Avoid Bug in 5.X
			cmd = string(cmd, "+n", parse(Float64, d[:norm]) / 2.54, "i")
		elseif (GMTver < 6 && isa(d[:norm], Number))
			cmd = string(cmd, "+n", d[:norm] / 2.54, "i")
		else
			cmd = string(cmd, "+n", d[:norm])
		end
	end

	if (haskey(d, :oblique_pole))  cmd = cmd * "+o" * arg2str(d[:oblique_pole])  end
	if (haskey(d, :pen))
		p = add_opt_pen(d, [:pen], "")
		if (p != "")  cmd *= "+p" * p  end
	end

	if (haskey(d, :shape))
		if (isa(d[:shape], String) || isa(d[:shape], Symbol))
			if     (d[:shape] == "triang" || d[:shape] == :triang)	cmd *= "+h0"
			elseif (d[:shape] == "arrow"  || d[:shape] == :arrow)	cmd *= "+h1"
			elseif (d[:shape] == "V"      || d[:shape] == :V)	    cmd *= "+h2"
			else	error("Shape string can be only: 'triang', 'arrow' or 'V'")
			end
		elseif (isa(d[:shape], Number))
			if (d[:shape] < -2 || d[:shape] > 2) error("Numeric shape code must be in the [-2 2] interval.") end
			cmd = string(cmd, "+h", d[:shape])
		else
			error("Bad data type for the 'shape' option")
		end
	end

	if (haskey(d, :trim))  cmd *= "+t" * arg2str(d[:trim])  end
	if (haskey(d, :ang1_ang2) || haskey(d, :start_stop))  cmd *= "+q"  end
	if (haskey(d, :endpoint))  cmd *= "+s"  end
	if (haskey(d, :uv))    cmd *= "+z" * arg2str(d[:uv])  end
	return cmd
end

# -----------------------------------
function helper_vec_loc(d, symb, cmd)
	# Helper function to the 'begin', 'middle', 'end' vector attrib function
	if     (d[symb] == "line"       || d[symb] == :line)	cmd *= "t"
	elseif (d[symb] == "arrow"      || d[symb] == :arrow)	cmd *= "a"
	elseif (d[symb] == "circle"     || d[symb] == :circle)	cmd *= "c"
	elseif (d[symb] == "tail"       || d[symb] == :tail)	cmd *= "i"
	elseif (d[symb] == "open_arrow" || d[symb] == :open_arrow)	cmd *= "A"
	elseif (d[symb] == "open_tail"  || d[symb] == :open_tail)	cmd *= "I"
	elseif (d[symb] == "left_side"  || d[symb] == :left_side)	cmd *= "l"
	elseif (d[symb] == "right_side" || d[symb] == :right_side)	cmd *= "r"
	end
	return cmd
end
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
decorated(nt::NamedTuple) = decorated(;nt...)
function decorated(;kwargs...)
	d = KW(kwargs)

	cmd, optD = helper_decorated(d)		# 'cmd' cannot come out empty (would have errored)

	if (haskey(d, :dec2))				# -S~ mode (decorated, with symbols, lines).
		cmd *= ":"
		marca = get_marker_name(d, [:marker :symbol])		# This fun lieves in psxy.jl
		if (marca == "")
			cmd = "+sa0.5" * cmd
		else
			cmd *= "+s" * marca
			if ((val = find_in_dict(d, [:size :markersize :symbsize :symbolsize])[1]) !== nothing)
				cmd *= arg2str(val);
			end
		end
		if (haskey(d, :angle))   cmd = string(cmd, "+a", d[:angle])  end
		if (haskey(d, :debug))   cmd *= "+d"  end
		if (haskey(d, :fill))    cmd *= "+g" * get_color(d[:fill])    end
		if (haskey(d, :nudge))   cmd *= "+n" * arg2str(d[:nudge])   end
		if (haskey(d, :n_data))  cmd *= "+w" * arg2str(d[:n_data])  end
		if (optD == "")  optD = "d"  end	# Need to find out also when it's -D
		opt_S = " -S~"
	elseif (haskey(d, :quoted))				# -Sq mode (quoted lines).
		if (haskey(d, :angle))   cmd  = string(cmd, "+a", d[:angle])  end
		if (haskey(d, :debug))   cmd *= "+d"  end
		if (haskey(d, :clearance ))  cmd *= "+c" * arg2str(d[:clearance]) end
		if (haskey(d, :delay))   cmd *= "+e"  end
		if (haskey(d, :font))    cmd *= "+f" * font(d[:font])    end
		if (haskey(d, :color))   cmd *= "+g" * arg2str(d[:color])   end
		if (haskey(d, :justify)) cmd *= "+j" * arg2str(d[:justify]) end
		if (haskey(d, :const_label)) cmd *= "+l" * arg2str(d[:const_label])  end
		if (haskey(d, :nudge))   cmd *= "+n" * arg2str(d[:nudge])   end
		if (haskey(d, :rounded)) cmd *= "+o"  end
		if (haskey(d, :min_rad)) cmd *= "+r" * arg2str(d[:min_rad]) end
		if (haskey(d, :unit))    cmd *= "+u" * arg2str(d[:unit])    end
		if (haskey(d, :curved))  cmd *= "+v"  end
		if (haskey(d, :n_data))  cmd *= "+w" * arg2str(d[:n_data])  end
		if (haskey(d, :prefix))  cmd *= "+=" * arg2str(d[:prefix])  end
		if (haskey(d, :suffices)) cmd *= "+x" * arg2str(d[:suffices])  end		# Only when -SqN2
		if (haskey(d, :label))
			if (isa(d[:label], String))
				cmd *= "+L" * d[:label]
			elseif (isa(d[:label], Symbol))
				if     (d[:label] == :header)  cmd *= "+Lh"
				elseif (d[:label] == :input)   cmd *= "+Lf"
				else   error("Wrong content for the :label option. Must be only :header or :input")
				end
			elseif (isa(d[:label], Tuple))
				if     (d[:label][1] == :plot_dist)  cmd *= "+Ld" * string(d[:label][2])
				elseif (d[:label][1] == :map_dist)   cmd *= "+LD" * parse_units(d[:label][2])
				else   error("Wrong content for the :label option. Must be only :plot_dist or :map_dist")
				end
			else
				@warn("'label' option must be a string or a NamedTuple. Since it wasn't I'm ignoring it.")
			end
		end
		if (optD == "")  optD = "d"  end	# Need to find out also when it's -D
		opt_S = " -Sq"
	else									# -Sf mode (front lines).
		if     (haskey(d, :left))  cmd *= "+l"
		elseif (haskey(d, :right)) cmd *= "+r"
		end
		if (haskey(d, :symbol))
			if     (d[:symbol] == "box"      || d[:symbol] == :box)      cmd *= "+b"
			elseif (d[:symbol] == "circle"   || d[:symbol] == :circle)   cmd *= "+c"
			elseif (d[:symbol] == "fault"    || d[:symbol] == :fault)    cmd *= "+f"
			elseif (d[:symbol] == "triangle" || d[:symbol] == :triangle) cmd *= "+t"
			elseif (d[:symbol] == "slip"     || d[:symbol] == :slip)     cmd *= "+s"
			elseif (d[:symbol] == "arcuate"  || d[:symbol] == :arcuate)  cmd *= "+S"
			else   @warn(string("DECORATED: unknown symbol: ", d[:symbol]))
			end
		end
		if (haskey(d, :offset))  cmd *= "+o" * arg2str(d[:offset]);	delete!(d, :offset)  end
		opt_S = " -Sf"
	end

	if (haskey(d, :pen))
		cmd *= "+p"
		if (!isempty_(d[:pen])) cmd *= add_opt_pen(d, [:pen])  end
	end
	return opt_S * optD * cmd
end

# --------------------------------
function helper_decorated(d::Dict)
	# Helper function to deal with the gap and symbol size parameters
	cmd = "";	optD = ""
	val, symb = find_in_dict(d, [:dist :distance :distmap :number])
	if (val !== nothing)
		# The String assumes all is already encoded. Number, Array only accept numerics
		# Tuple accepts numerics and/or strings.
		if (isa(val, String) || isa(val, Number) || isa(val, Symbol))
			cmd = string(val)
		elseif (isa(val, Array) || isa(val, Tuple))
			if (symb == :number)  cmd = "-" * string(val[1], '/', val[2])
			else                  cmd = string(val[1], '/', val[2])
			end
		else
			error("DECORATED: the 'dist' (or 'distance') parameter is mandatory and must be either a string or a named tuple.")
		end
		if (symb == :distmap)  optD = "D"  end		# Here we know that we are dealing with a -S~ for sure.
	end
	if (cmd == "")
		if ((val = find_in_dict(d, [:lines :Lines])[1]) !== nothing)
			if (!isa(val, Array) && size(val,2) !=4)
				@warn("DECORATED: lines option must me an Array Mx4. Ignoring this.")
			else
				opt = string(val)
				s = string("+",opt[1], val[1,1],'/',val[1,2],'/',val[1,3],'/',val[1,4])
				for k = 2:size(val,1)
					s = string(s,',',val[k,1],'/',val[k,2],'/',val[k,3],'/',val[k,4])
				end
			end
		end
	end
	if (cmd == "")
		if ((val = find_in_dict(d, [:n_labels :n_symbols])[1]) !== nothing)
			cmd = string("n", val);
		end
	end
	if (cmd == "")
		if ((val = find_in_dict(d, [:N_labels :N_symbols])[1]) !== nothing)
			cmd = string("N", val);
		end
	end
	if (cmd == "")
		error("DECORATED: no controlling algorithm to place the elements was provided (dist, n_symbols, etc).")
	end
	return cmd, optD
end
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
function fname_out(d::Dict)
	# Create an file name in the TMP dir when OUT holds only a known extension. The name is: GMTjl_tmp.ext
	EXT = ""
	if (haskey(d, :fmt))
		out = (isa(d[:fmt], Symbol)) ? string(d[:fmt]) : d[:fmt]
	else
		out = FMT						# Use the global FMT choice
	end
	if (isempty(out) && !Sys.iswindows())
		error("NOT specifying the **fmt** format is only allowed on Windows")
	end
	if (haskey(d, :ps))			# In any case this means we want the PS sent back to Julia
		out = ""
		EXT = "ps"
	end
	# When OUT == "" here, it plays a double role. It means to put the PS in memory or
	# return it to the REPL. The ambiguity is cleared in finish_PS_module()

	opt_T = "";
	if (length(out) <= 3)
		@static Sys.iswindows() ? template = tempdir() * "GMTjl_tmp.ps" : template = tempdir() * "/" * "GMTjl_tmp.ps" 
		ext = lowercase(out)
		if (ext == "ps")       out = template;  EXT = ext
		elseif (ext == "pdf")  opt_T = " -Tf";	out = template;		EXT = ext
		elseif (ext == "eps")  opt_T = " -Te";	out = template;		EXT = ext
		elseif (ext == "png")  opt_T = " -Tg";	out = template;		EXT = ext
		elseif (ext == "jpg")  opt_T = " -Tj";	out = template;		EXT = ext
		elseif (ext == "tif")  opt_T = " -Tt";	out = template;		EXT = ext
		end
	end
	return out, opt_T, EXT
end

# ---------------------------------------------------------------------------------------------------
function read_data(d::Dict, fname::String, cmd, arg, opt_R="", opt_i="", opt_bi="", opt_di="", is3D=false)
	# In case DATA holds a file name, read that data and put it in ARG
	# Also compute a tight -R if this was not provided
	data_kw = nothing
	if (haskey(d, :data))	data_kw = d[:data]	end

	ins = sum([data_kw !== nothing !isempty_(arg) !isempty(fname)])
	if (ins > 1)
		@warn("Conflicting ways of providing input data. Either a file name via positional and
		a data array via keyword args were provided or numeric input. Unknown effect of this.")
	end

	if (fname != "")	data_kw = fname		end

	if (isa(data_kw, String))
		if (GMTver >= 6)				# Due to a bug in GMT5, gmtread has no -i option 
			data_kw = gmt("read -Td " * opt_i * opt_bi * opt_di * " " * data_kw)
			if (!isempty(opt_i))		# Remove the -i option from cmd. It has done its job
				cmd = replace(cmd, opt_i, "")
				opt_i = ""
			end
		else
			data_kw = gmt("read -Td " * opt_bi * opt_di * " " * data_kw)
		end
	end

	if (!isempty_(data_kw)) arg = data_kw  end		# Finaly move the data into ARG

	if (opt_R == "" || opt_R[1] == '/')
		info = gmt("gmtinfo -C" * opt_i, arg)		# Here we are reading from an original GMTdataset or Array
		if (opt_R != "" && opt_R[1] == '/')	# Modify waht will be reported as a -R string
			# Example "/-1/1/0//" will extend x axis +/- 0.1, set y_min=0 and no change to y_max
			rs = split(opt_R, '/')
			for k = 2:length(rs)
				if (rs[k] != "")
					x = parse(Float64, rs[k])
					if (x == 0.0) info[1].data[k-1] = x
					else          info[1].data[k-1] += x 
					end
				end
			end
		end
		if (opt_R != "tight")  info[1].data = round_wesn(info[1].data)  end
		if (is3D)
			opt_R = @sprintf(" -R%.12g/%.12g/%.12g/%.12g/%.12g/%.12g", info[1].data[1], info[1].data[2],
			                 info[1].data[3], info[1].data[4], info[1].data[5], info[1].data[6])
		else
			opt_R = @sprintf(" -R%.12g/%.12g/%.12g/%.12g", info[1].data[1], info[1].data[2],
			                 info[1].data[3], info[1].data[4])
		end
		cmd = cmd * opt_R
	end

	return cmd, arg, opt_R, opt_i
end

# ---------------------------------------------------------------------------------------------------
function round_wesn(wesn, geo::Bool=false)
	# Use data range to round to nearest reasonable multiples
	# If wesn has 6 elements (is3D), last two are not modified.
	set = zeros(Bool, 2)
	range = [0.0, 0.0]
	if (wesn[1] == wesn[2])
		wesn[1] -= abs(wesn[1]) * 0.1;	wesn[2] += abs(wesn[2]) * 0.1
	end
	if (wesn[3] == wesn[4])
		wesn[3] -= abs(wesn[3]) * 0.1;	wesn[4] += abs(wesn[4]) * 0.1
	end
	range[1] = wesn[2] - wesn[1]
	range[2] = wesn[4] - wesn[3]
	if (geo) 					# Special checks due to periodicity
		if (range[1] > 306.0) 	# If within 15% of a full 360 we promote to 360
			wesn[1] = 0.0;	wesn[2] = 360.0
			set[1] = true
		end
		if (range[2] > 153.0) 	# If within 15% of a full 180 we promote to 180
			wesn[3] = -90.0;	wesn[4] = 90.0
			set[2] = true
		end
	end

	item = 1
	for side = 1:2
		if (set[side]) continue		end		# Done above */
		mag = round(log10(range[side])) - 1.0
		inc = 10.0^mag
		if ((range[side] / inc) > 10.0) inc *= 2.0	end	# Factor of 2 in the rounding
		if ((range[side] / inc) > 10.0) inc *= 2.5	end	# Factor of 5 in the rounding
		s = 1.0
		if (geo) 	# Use arc integer minutes or seconds if possible
			if (inc < 1.0 && inc > 0.05) 				# Nearest arc minute
				s = 60.0;		inc = 1.0
				if ((s * range[side] / inc) > 10.0) inc *= 2.0	end		# 2 arcmin
				if ((s * range[side] / inc) > 10.0) inc *= 2.5	end		# 5 arcmin
			elseif (inc < 0.1 && inc > 0.005) 			# Nearest arc second
				s = 3600.0;		inc = 1.0
				if ((s * range[side] / inc) > 10.0) inc *= 2.0	end		# 2 arcsec
				if ((s * range[side] / inc) > 10.0) inc *= 2.5	end		# 5 arcsec
			end
		end
		wesn[item] = (floor(s * wesn[item] / inc) * inc) / s;	item += 1;
		wesn[item] = (ceil(s * wesn[item] / inc) * inc) / s;	item += 1;
	end
	return wesn
end

# ---------------------------------------------------------------------------------------------------
function find_data(d::Dict, cmd0::String, cmd::String, tipo, arg1=[], arg2=[], arg3=[], arg4=[])
	# ...
	got_fname = 0;		data_kw = nothing
	if (haskey(d, :data))	data_kw = d[:data]	end
	if (!isempty(cmd0))						# Data was passed as file name
		cmd = cmd0 * " " * cmd
		got_fname = 1
	end

	# Check if we need to save to file
	if (haskey(d, :>))			cmd = string(cmd, " > ", d[:>])
	elseif (haskey(d, :|>))		cmd = string(cmd, " > ", d[:|>])
	elseif (haskey(d, :write))	cmd = string(cmd, " > ", d[write])
	elseif (haskey(d, :>>))		cmd = string(cmd, " > ", d[:>>])
	elseif (haskey(d, :write_append))	cmd = string(cmd, " > ", d[write_append])
	end

	if (tipo == 1)
		# Accepts "input1"; arg1; data=input1;
		if (got_fname != 0) 
			return cmd, got_fname, arg1		# got_fname = 1 => data is in cmd 
		elseif (!isempty_(arg1))
			return cmd, got_fname, arg1 	# got_fname = 0 => data is in arg1
		elseif (data_kw !== nothing)
			if (isa(data_kw, String))
				cmd = data_kw * " " * cmd
				return cmd, 1, arg1			# got_fname = 1 => data is in cmd 
			else
				return cmd, 0, data_kw 		# got_fname = 0 => data is in arg1
			end
		else
			error("Missing input data to run this module.")
		end
	elseif (tipo == 2)			# Two inputs (but second can be optional is some modules)
		# Accepts "input1  input2"; "input1", arg1; "input1", data=input2; arg1, arg2; data=(input1,input2)
		if (got_fname != 0)
			if (isempty_(arg1) && data_kw === nothing)
				return cmd, 1, arg1, arg2		# got_fname = 1 => all data is in cmd 
			elseif (!isempty_(arg1))
				return cmd, 2, arg1, arg2		# got_fname = 2 => data is in cmd and arg1
			elseif (data_kw !== nothing && length(data_kw) == 1)
				return cmd, 2, data_kw, arg2	# got_fname = 2 => data is in cmd and arg1
			else
				error("Missing input data to run this module.")
			end
		else
			if (!isempty_(arg1) && !isempty_(arg2))
				return cmd, 0, arg1, arg2				# got_fname = 0 => all data is in arg1,2
			elseif (!isempty_(arg1) && isempty_(arg2) && data_kw === nothing)
				return cmd, 0, arg1, arg2				# got_fname = 0 => all data is in arg1
			elseif (!isempty_(arg1) && isempty_(arg2) && data_kw !== nothing && length(data_kw) == 1)
				return cmd, 0, arg1, data_kw			# got_fname = 0 => all data is in arg1,2
			elseif (data_kw !== nothing && length(data_kw) == 2)
				return cmd, 0, data_kw[1], data_kw[2]	# got_fname = 0 => all data is in arg1,2
			else
				error("Missing input data to run this module.")
			end
		end
	elseif (tipo == 3)			# Three inputs
		# Accepts "input1  input2 input3"; arg1, arg2, arg3; data=(input1,input2,input3)
		if (got_fname != 0)
			if (isempty_(arg1) && data_kw === nothing)
				return cmd, 1, arg1, arg2, arg3			# got_fname = 1 => all data is in cmd 
			else
				error("Cannot mix input as file names and numeric data.")
			end
		else
			if (isempty_(arg1) && isempty_(arg2) && isempty_(arg3))
				return cmd, 0, arg1, arg2, arg3			# got_fname = 0 => all data in arg1,2,3
			elseif (data_kw !== nothing && length(data_kw) == 3)
				return cmd, 0, data_kw[1], data_kw[2], data_kw[3]	# got_fname = 0 => all data in arg1,2,3
			end
		end
	end
end

# ---------------------------------------------------------------------------------------------------
function common_grd(d::Dict, cmd::String, got_fname::Int, tipo::Int, prog::String, args...)
	# This chunk of code is shared by several grdxxx modules, so wrap it in a function
	dbg_print_cmd(d, cmd, prog)
	cmd = prog * " " * cmd		# Instead of having this in all cases below
	if (tipo == 1)				# One input only
		if (got_fname != 0)
			return gmt(cmd)
		else
			return gmt(cmd, args[1])
		end
	elseif (tipo == 2)			# Two inputs
		if (got_fname == 1)
			return gmt(cmd)
		elseif (got_fname == 2)	# NOT SURE ON THIS ONE
			return gmt(cmd, args[1])
		else
			return gmt(cmd, args[1], args[2])
		end
	else						# ARGS is a tuple(tuple) with all numeric inputs
		return gmt(cmd, args[1]...)		# args[1] because args is a tuple(tuple)
	end
end

# ---------------------------------------------------------------------------------------------------
function dbg_print_cmd(d::Dict, cmd::String, prog::String)
	# Print the gmt command when the Vd=1 kwarg was used
	#(haskey(d, :Vd)) && println(@sprintf("\t%s %s", prog, cmd))
	if (haskey(d, :Vd))
		if (d[:Vd] == :cmd)		# For testing puposes, return the GMT command
			return cmd
		else
			println(@sprintf("\t%s %s", prog, cmd))
		end
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function showfig(d::Dict, fname_ps::String, fname_ext::String, opt_T::String, K=false, fname="")
	# Take a PS file, convert it with psconvert (unless opt_T == "" meaning file is PS)
	# and display it in default system viewer
	# FNAME_EXT hold the extension when not PS
	# OPT_T holds the psconvert -T option, again when not PS
	# FNAME is for when using the savefig option

	if (opt_T != "")
		if (K) gmt("psxy -T -R0/1/0/1 -JX1 -O >> " * fname_ps)  end		# Close the PS file first
		gmt("psconvert -A1p -Qg4 -Qt4 " * fname_ps * opt_T)
		out = fname_ps[1:end-2] * fname_ext
		if (fname != "")
			run(`mv $out $fname`)
			out = fname
		end
	elseif (fname_ps != "")
		out = fname_ps
		if (fname != "")
			run(`mv $out $fname`)
			out = fname
		end
	else
		if (K)  gmt("psxy -T -R0/1/0/1 -JX1 -O ")  end		# Close the PS file first
		if (fname_ext == "")
			return gmt("psconvert = -A1p")					# Return a GMTimage object
		else
			out = tempdir() * "GMTjl_tmp.pdf"
			gmt("psconvert = -A1p -Tf -F" * out)
		end
	end

	if (haskey(d, :show) && d[:show] != 0)
		@static if (Sys.iswindows()) run(ignorestatus(`explorer $out`))
		elseif (Sys.isapple()) run(`open $(out)`)
		elseif (Sys.islinux() || Sys.isbsd()) run(`xdg-open $(out)`)
		end
	end
end

# ---------------------------------------------------------------------------------------------------
function isempty_(arg)
	# F... F... it's a shame having to do this
	if (arg === nothing)
		return true
	end
	try
		vazio = isempty(arg)
		return vazio
	catch
		return false
	end
end

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

# ---------------------------------------------------------------------------------------------------
function finish_PS_module(d::Dict, cmd, opt_extra::String, output::String, fname_ext::String, 
						   opt_T::String, K::Bool, prog::String, arg1=[], arg2=[], arg3=[], 
						   arg4=[], arg5=[], arg6=[])
	# FNAME_EXT hold the extension when not PS
	# OPT_EXTRA is used by grdcontour -D or pssolar -I to not try to create and view a img file
	if (isa(cmd, Array{String, 1}))
		for k = 1:length(cmd)
			if ((r = dbg_print_cmd(d, cmd[k], prog)) !== nothing)  return r  end 	# For tests only
			if (isempty_(arg1))					# Simple case
				P = gmt(string(prog, " ", cmd[k]))
			elseif (isempty_(arg2))				# One numeric input
				P = gmt(string(prog, " ", cmd[k]), arg1)
			else								# Two numeric inputs
				P = gmt(string(prog, " ", cmd[k]), arg1, arg2)
			end
		end
	else
		if ((r = dbg_print_cmd(d, cmd, prog)) !== nothing)  return r  end 	# For tests only
		cmd = string(prog, " ", cmd)
		if     (!isempty_(arg6))  P = gmt(cmd, arg1, arg2, arg3, arg4, arg5, arg6)
		elseif (!isempty_(arg5))  P = gmt(cmd, arg1, arg2, arg3, arg4, arg5)
		elseif (!isempty_(arg4))  P = gmt(cmd, arg1, arg2, arg3, arg4)
		elseif (!isempty_(arg3))  P = gmt(cmd, arg1, arg2, arg3)
		elseif (!isempty_(arg2))  P = gmt(cmd, arg1, arg2)
		elseif (!isempty_(arg2))  P = gmt(cmd, arg1, arg2)
		elseif (!isempty_(arg1))  P = gmt(cmd, arg1)
		else                      P = gmt(cmd)
		end
	end

	fname = ""
	if (haskey(d, :savefig))		# Also ensure that file has the right extension
		fname, ext = splitext(d[:savefig])
		if (fname_ext != "")  fname *= '.' * fname_ext
		else                  fname *= ext			# PS, otherwise shit had happened
		end
	end

	if (isempty(fname_ext) && isempty(opt_extra))	# Return result as an GMTimage
		P = showfig(d, output, fname_ext, "", K)
	elseif ((haskey(d, :show) && d[:show] != 0) || fname != "")
		showfig(d, output, fname_ext, opt_T, K, fname)
	end
	return P
end

# --------------------------------------------------------------------------------------------------
function monolitic(prog::String, cmd0::String, args...)
	# Run this module in the monolithic way. e.g. [outs] = gmt("module args",[inputs])
	cmd0 = prog * " " * cmd0
	if (isempty_(args[1]))	return gmt(cmd0)
	else					return gmt(cmd0, args...)
	end
end

# --------------------------------------------------------------------------------------------------
function peaks(; N=49, grid=true)
	x,y = meshgrid(range(-3,stop=3,length=N))
	
	z =  3 * (1 .- x).^2 .* exp.(-(x.^2) - (y .+ 1).^2) - 10*(x./5 - x.^3 - y.^5) .* exp.(-x.^2 - y.^2)
	   - 1/3 * exp.(-(x .+ 1).^2 - y.^2)

	if (grid)
		x = collect(range(-3,stop=3,length=N))
		y = deepcopy(x)
		z = Float32.(z)
		G = GMTgrid("", "", [x[1], x[end], y[1], y[end], minimum(z), maximum(z)], [x[2]-x[1], y[2]-y[1]], 
					0, NaN, "", "", "", "", x, y, z, "x", "y", "z", "")
		return G
	else
		return x,y,z
	end
end	

meshgrid(v::AbstractVector) = meshgrid(v, v)
function meshgrid(vx::AbstractVector{T}, vy::AbstractVector{T}) where T
	m, n = length(vy), length(vx)
	vx = reshape(vx, 1, n)
	vy = reshape(vy, m, 1)
	(repeat(vx, m, 1), repeat(vy, 1, n))
end

function meshgrid(vx::AbstractVector{T}, vy::AbstractVector{T}, vz::AbstractVector{T}) where T
	m, n, o = length(vy), length(vx), length(vz)
	vx = reshape(vx, 1, n, 1)
	vy = reshape(vy, m, 1, 1)
	vz = reshape(vz, 1, 1, o)
	om = ones(Int, m)
	on = ones(Int, n)
	oo = ones(Int, o)
	(vx[om, :, oo], vy[:, on, oo], vz[om, on, :])
end