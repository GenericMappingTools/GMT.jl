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
	global IamModern
	opt_R = ""
	val, symb = find_in_dict(d, [:R :region :limits])
	if (val !== nothing)
		opt_R = build_opt_R(val)
		if (del) delete!(d, symb) end
	elseif (IamModern)
		return cmd, ""
	end

	if (opt_R == "")		# See if we got the region as tuples of xlim, ylim [zlim]
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

function build_opt_R(Val)		# Generic function that deals with all but NamedTuple args
	if (isa(Val, String) || isa(Val, Symbol))
		r = string(Val)
		if     (r == "global")     return " -Rd"
		elseif (r == "global360")  return " -Rg"
		elseif (r == "same")       return " -R"
		else                       return " -R" * r
		end
	elseif ((isa(Val, Array{<:Number}) || isa(Val, Tuple)) && (length(Val) == 4 || length(Val) == 6))
		out = arg2str(Val)
		return " -R" * rstrip(out, '/')		# Remove last '/'
	elseif (isa(Val, GMTgrid) || isa(Val, GMTimage))
		return @sprintf(" -R%.15g/%.15g/%.15g/%.15g", Val.range[1], Val.range[2], Val.range[3], Val.range[4])
	end
	return ""
end

function build_opt_R(arg::NamedTuple)
	# Option -R can also be diabolicly complicated. Try to addres it. Stil misses the Time part.
	BB = ""
	d = nt2dict(arg)					# Convert to Dict
	if ((val = find_in_dict(d, [:bb :limits :region])[1]) !== nothing)
		if ((isa(val, Array{<:Number}) || isa(val, Tuple)) && (length(val) == 4 || length(val) == 6))
			if (haskey(d, :diag))		# The diagonal case
				BB = @sprintf("%.15g/%.15g/%.15g/%.15g+r", val[1], val[3], val[2], val[4])
			else
				BB = join([@sprintf("%.15g/",x) for x in val])
				BB = rstrip(BB, '/')		# and remove last '/'
			end
		elseif (isa(val, String) || isa(val, Symbol))
			t = string(val)
			if     (t == "global")     BB = "-180/180/-90/90"
			elseif (t == "global360")  BB = "0/360/-90/90"
			else                       BB = string(val) 			# Whatever good stuff or shit it may contain
			end
		end
	elseif ((val = find_in_dict(d, [:bb_diag :limits_diag :region_diag :LLUR])[1]) !== nothing)	# Alternative way of saying "+r"
		BB = @sprintf("%.15g/%.15g/%.15g/%.15g+r", val[1], val[3], val[2], val[4])
	elseif ((val = find_in_dict(d, [:continent :cont])[1]) !== nothing)
		val = uppercase(string(val))
		if     (startswith(val, "AF"))  BB = "=AF"
		elseif (startswith(val, "AN"))  BB = "=AN"
		elseif (startswith(val, "AS"))  BB = "=AS"
		elseif (startswith(val, "EU"))  BB = "=EU"
		elseif (startswith(val, "OC"))  BB = "=OC"
		elseif (val[1] == 'N')  BB = "=NA"
		elseif (val[1] == 'S')  BB = "=SA"
		else   error("Unknown continent name")
		end
	elseif ((val = find_in_dict(d, [:ISO :iso])[1]) !== nothing)
		if (isa(val, String))  BB = val
		else                   error("argument to the ISO key must be a string with country codes")
		end
	end

	if ((val = find_in_dict(d, [:adjust :pad :extend :expand])[1]) !== nothing)
		if (isa(val, String) || isa(val, Number))  t = string(val)
		elseif (isa(val, Array{<:Number}) || isa(val, Tuple)) 
			t = join([@sprintf("%.15g/",x) for x in val])
			t = rstrip(t, '/')		# and remove last '/'
		else
			error("Increments for limits must be a String, a Number, Array or Tuple")
		end
		if (haskey(d, :adjust))  BB *= "+r" * t
		else                     BB *= "+R" * t
		end
	end

	if (haskey(d, :unit))  BB *= "+u" * string(d[:unit])[1]  end	# (e.g., -R-200/200/-300/300+uk)

	if (BB == "")
		error("No, no, no. Nothing useful in the region named tuple arguments")
	else
		return " -R" * BB
	end
end

# ---------------------------------------------------------------------------------------------------
function parse_JZ(cmd::String, d::Dict, del=false)
	opt_J = ""
	val, symb = find_in_dict(d, [:JZ :Jz :zscale :zsize])
	if (val !== nothing)
		if (symb == :JZ || symb == :zsize)  opt_J = " -JZ" * arg2str(val)
		else                                opt_J = " -Jz" * arg2str(val)
		end
		cmd *= opt_J
		if (del) delete!(d, symb) end
	end
	return cmd, opt_J
end

# ---------------------------------------------------------------------------------------------------
function parse_J(cmd::String, d::Dict, default="", map=true, O=false, del=false)
	# Build the option -J string. Make it simply -J if overlay mode (-O) and no new -J is fished here
	# Default to 12c if no size is provided.
	# If MAP == false, do not try to append a fig size
	global IamModern
	opt_J = "";		mnemo = false
	if ((val = find_in_dict(d, [:J :proj :projection], del)[1]) !== nothing)
		opt_J, mnemo = build_opt_J(val)
	elseif (IamModern)			# Subplots do not rely is the classic default mechanism
		return cmd, ""
	end
	if (!map && opt_J != "")
		return cmd * opt_J, opt_J
	end

	if (O && opt_J == "")  opt_J = " -J"  end

	if (!O)
		if (opt_J == "")  opt_J = " -JX"  end
		# If only the projection but no size, try to get it from the kwargs.
		if ((s = helper_append_figsize(d, opt_J, O)) != "")		# Takes care of both fig scales and fig sizes
			opt_J = s
		elseif (default != "" && opt_J == " -JX")
			opt_J = default  					# -JX was a working default
		elseif (occursin("+width=", opt_J))		# OK, a proj4 string, don't touch it. Size already in.
		elseif (occursin("+proj", opt_J))		# A proj4 string but no size info. Use default size
			opt_J *= "+width=" * split(def_fig_size, '/')[1]
		elseif (mnemo)							# Proj name was obtained from a name mnemonic and no size. So use default
			opt_J = append_figsize(d, opt_J)
		elseif (!isnumeric(opt_J[end]) && (length(opt_J) < 6 || (isletter(opt_J[5]) && !isnumeric(opt_J[6]))) )
			if ((val = find_in_dict(d, [:aspect :axis])[1]) !== nothing)  val = string(val)  end
			if (val == "equal")  opt_J *= split(def_fig_size, '/')[1] * "/0"
			else                 opt_J *= def_fig_size
			end
		#elseif (length(opt_J) == 4 || (length(opt_J) >= 5 && isletter(opt_J[5])))
			#if (length(opt_J) < 6 || !isnumeric(opt_J[6]))
				#opt_J *= def_fig_size
			#end
		end
	else										# For when a new size is entered in a middle of a script
		if ((s = helper_append_figsize(d, opt_J, O)) != "")  opt_J = s  end
	end
	cmd *= opt_J
	return cmd, opt_J
end

function helper_append_figsize(d, opt_J, O)
	val, symb = find_in_dict(d, [:figscale :fig_scale :scale :figsize :fig_size])
	if (val === nothing)  return ""  end
	val = arg2str(val)
	if (occursin("scale", arg2str(symb)))		# We have a fig SCALE request
		if (opt_J == " -JX")  isletter(val[1]) ? opt_J = " -J" * val : opt_J = " -Jx" * val	# FRAGILE
		elseif (O && opt_J == " -J")  error("In Overlay mode you cannot change a fig scale and NOT repeat the projection")
		else                  opt_J = append_figsize(d, opt_J, val, true)
		end
	else										# A fig SIZE request
		if (haskey(d, :units))  val *= d[:units][1]  end
		if (occursin("+proj", opt_J)) opt_J *= "+width=" * val
		else                          opt_J = append_figsize(d, opt_J, val)
		end
	end
	return opt_J
end

function append_figsize(d, opt_J, width="", scale=false)
	# Appending either a fig width or fig scale depending on what projection.
	# Sometimes we need to separate with a '/' others not. If WIDTH == "" we
	# use the DEF_FIG_SIZE, otherwise use WIDTH that can be a size or a scale.
	if (width == "")
		width = split(def_fig_size, '/')[1]
	elseif ( ((val = find_in_dict(d, [:aspect :axis])[1]) !== nothing) && (val == "equal" || val == :equal)) 
		if (occursin("/", width))
			@warn("Ignoring the axis 'equal' request because figsize with Width and Height already provided.")
		else
			width *= "/0"
		end
	end

	if (isnumeric(opt_J[end]) && ~startswith(opt_J, " -JXp"))    opt_J *= "/" * width
	else
		if (occursin("Cyl_", opt_J) || occursin("Poly", opt_J))  opt_J *= "/" * width
		elseif (startswith(opt_J, " -JU") && length(opt_J) > 4)  opt_J *= "/" * width
		else		# Must parse for logx, logy, loglog, etc
			if (startswith(opt_J, " -JXl") || startswith(opt_J, " -JXp") ||
				startswith(opt_J, " -JXT") || startswith(opt_J, " -JXt"))
				ax = opt_J[6];	flag = opt_J[5];
				if (flag == 'p' && length(opt_J) > 6)  flag *= opt_J[7:end]  end	# Case p<power>
				opt_J = opt_J[1:4]			# Trim the consumed options
				w_h = split(width,"/")
				if (length(w_h) == 2)		# Must find which (or both) axis is scaling be applyied
					(ax == 'x') ? w_h[1] *= flag : ((ax == 'y') ? w_h[2] *= flag : w_h .*= flag)
					width = w_h[1] * '/' * w_h[2]
				elseif (ax == 'y')  error("Can't select Y scaling and provide X dimension only")
				else
					width *= flag
				end
			end
			opt_J *= width
		end
	end
	if (scale)  opt_J = opt_J[1:3] * lowercase(opt_J[4]) * opt_J[5:end]  end 		# Turn " -JX" to " -Jx"
	return opt_J
end

function build_opt_J(Val)
	out = "";	mnemo = false
	if (isa(Val, String) || isa(Val, Symbol))
		prj, mnemo = parse_proj(string(Val))
		out = " -J" * prj
	elseif (isa(Val, NamedTuple))
		prj, mnemo = parse_proj(Val)
		out = " -J" * prj
	elseif (isa(Val, Number))
		if (!(typeof(Val) <: Int) || Val < 2000)
			error("The only valid case to provide a number to the 'proj' option is when that number is an EPSG code, but this (" * string(Val) * ") is clearly an invalid EPSG")
		end
		out = string(" -J", string(Val))
	elseif (isempty(Val))
		out = " -J"
	end
	return out, mnemo
end

function auto_JZ(cmd)
	# Add the -JZ option to modules that should not need it (e.g. pscoast) when used after a
	# -R with 6 elements. Without this a simple -J fails with a complain that ... -JZ is needed
	global current_view
	if (current_view !== nothing && !occursin("-JZ", cmd) && !occursin("-Jz", cmd))  cmd *= " -JZ0.01"  end
	return cmd
end

function parse_proj(p::String)
	# See "p" is a string with a projection name. If yes, convert it into the corresponding -J syntax
	if (p[1] == '+' || startswith(p, "epsg") || occursin('/', p) || length(p) < 3)  return p,false  end
	mnemo = true			# True when the projection name used one of the below mnemonics
	s = lowercase(p)
	if     (s == "aea"   || s == "albers")                 out = "B0/0"
	elseif (s == "cea"   || s == "cylindricalequalarea")   out = "Y0/0"
	elseif (s == "laea"  || s == "lambertazimuthal")       out = "A0/0"
	elseif (s == "lcc"   || s == "lambertconic")           out = "L0/0"
	elseif (s == "aeqd"  || s == "azimuthalequidistant")   out = "E0/0"
	elseif (s == "eqdc"  || s == "conicequidistant")       out = "D0/90"
	elseif (s == "tmerc" || s == "transversemercator")     out = "T0"
	elseif (s == "eqc"   || startswith(s, "plat") || startswith(s, "equidist") || startswith(s, "equirect"))  out = "Q"
	elseif (s == "eck4"  || s == "eckertiv")               out = "Kf"
	elseif (s == "eck6"  || s == "eckertvi")               out = "Ks"
	elseif (s == "omerc" || s == "obliquemerc1")           out = "Oa"
	elseif (s == "omerc2"|| s == "obliquemerc2")           out = "Ob"
	elseif (s == "omercp"|| s == "obliquemerc3")           out = "Oc"
	elseif (startswith(s, "cyl_") || startswith(s, "cylindricalster"))  out = "Cyl_stere"
	elseif (startswith(s, "cass"))   out = "C0/0"
	elseif (startswith(s, "gnom"))   out = "F0/0"
	elseif (startswith(s, "ham"))    out = "H"
	elseif (startswith(s, "lin"))    out = "X"
	elseif (startswith(s, "logx"))   out = "Xlx"
	elseif (startswith(s, "logy"))   out = "Xly"
	elseif (startswith(s, "loglog")) out = "Xll"
	elseif (startswith(s, "powx"))   v = split(s, ',');	length(v) == 2 ? out = "Xpx" * v[2] : out = "Xpx"
	elseif (startswith(s, "powy"))   v = split(s, ',');	length(v) == 2 ? out = "Xpy" * v[2] : out = "Xpy"
	elseif (startswith(s, "Time"))   out = "XTx"
	elseif (startswith(s, "time"))   out = "Xtx"
	elseif (startswith(s, "merc"))   out = "M"
	elseif (startswith(s, "mil"))    out = "J"
	elseif (startswith(s, "mol"))    out = "W"
	elseif (startswith(s, "ortho"))  out = "G0/0"
	elseif (startswith(s, "poly"))   out = "Poly"
	elseif (s == "polar")            out = "P"
	elseif (s == "polar_azim")       out = "Pa"
	elseif (startswith(s, "robin"))  out = "N"
	elseif (startswith(s, "stere"))  out = "S0/90"
	elseif (startswith(s, "sinu"))   out = "I"
	elseif (startswith(s, "utm"))    out = "U" * s[4:end]
	elseif (startswith(s, "vand"))   out = "V"
	elseif (startswith(s, "win"))    out = "R"
	else   out = p;		mnemo = false
	end
	return out, mnemo
end

function parse_proj(p::NamedTuple)
	# Take a proj=(name=xxxx, center=[lon lat], parallels=[p1 p2]), where either center or parallels
	# may be absent, but not BOTH, an create a GMT -J syntax string (note: for some projections 'center'
	# maybe a scalar but the validity of that is not checked here).
	d = nt2dict(p)					# Convert to Dict
	if ((val = find_in_dict(d, [:name])[1]) !== nothing)
		prj, mnemo = parse_proj(string(val))
		if (prj != "Cyl_stere" && prj == string(val))
			@warn("Very likely the projection name ($prj) is unknown to me. Expect troubles")
		end
	else
		error("When projection arguments are in a NamedTuple the projection 'name' keyword is madatory.")
	end

	center = ""
	if ((val = find_in_dict(d, [:center])[1]) !== nothing)
		if     (isa(val, String))  center = val
		elseif (isa(val, Number))  center = @sprintf("%.12g", val)
		elseif (isa(val, Array) || isa(val, Tuple) && length(val) == 2)  center = @sprintf("%.12g/%.12g", val[1], val[2])
		end
	end

	if (center != "" && (val = find_in_dict(d, [:horizon])[1]) !== nothing)  center = string(center, '/',val)  end

	parallels = ""
	if ((val = find_in_dict(d, [:parallel :parallels])[1]) !== nothing)
		if     (isa(val, String))  parallels = "/" * val
		elseif (isa(val, Number))  parallels = @sprintf("/%.12g", val)
		elseif (isa(val, Array) || isa(val, Tuple) && (length(val) <= 3 || length(val) == 6))
			parallels = join([@sprintf("/%.12g",x) for x in val])
		end
	end

	if     (center == "" && parallels != "")  center = "0/0" * parallels
	elseif (center != "")                     center *= parallels			# even if par == ""
	else   error("When projection is a named tuple you need to specify also 'center' and|or 'parallels'")
	end
	if (startswith(prj, "Cyl"))  prj = prj[1:9] * "/" * center	# The unique Cyl_stere case
	elseif (prj[1] == 'K' || prj[1] == 'O')  prj = prj[1:2] * center	# Eckert || Oblique Merc
	else                                     prj = prj[1]   * center
	end
	return prj, mnemo
end

# ---------------------------------------------------------------------------------------------------
function parse_B(cmd::String, d::Dict, opt_B::String="", del=false)

	global IamModern
	def_fig_axes_ = (IamModern) ? "" : def_fig_axes	# def_fig_axes is a global const

	# These four are aliases
	extra_parse = true
	if ((val = find_in_dict(d, [:B :frame :axis :axes], del)[1]) !== nothing)
		if (val == :none || val == "none")		# User explicitly said NO AXES
			return cmd, ""
		elseif (val == :noannot || val == :bare || val == "noannot" || val == "bare")
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
	if (haskey(d, :title))   t *= "+t"   * replace(str_with_blancs(d[:title]), ' '=>'\U00AF');   end
	if (haskey(d, :xlabel))  t *= " x+l" * replace(str_with_blancs(d[:xlabel]),' '=>'\U00AF');   end
	if (haskey(d, :ylabel))  t *= " y+l" * replace(str_with_blancs(d[:ylabel]),' '=>'\U00AF');   end
	if (t != "")
		if (opt_B == "" && (val = find_in_dict(d, [:xaxis :yaxis :zaxis])[1] === nothing))
			opt_B = def_fig_axes_
		else
			#if (opt_B == def_fig_axes)  opt_B = ""  end		# opt_B = def_fig_axes from argin but no good here
			if !( ((ind = findlast("-B",opt_B)) !== nothing || (ind = findlast(" ",opt_B)) !== nothing) &&
				  (occursin(r"[WESNwesntlbu+g+o]",opt_B[ind[1]:end])) )
				t = " " * t;		# Do not glue, for example, -Bg with :title
			end
		end
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
		k = 1;		r = opt_B;		found = false
		while (r != "")
			tok[k], r = GMT.strtok(r)
			tok[k] = replace(tok[k], '\U00AF'=>' ')
			if (!occursin("-B", tok[k]))  tok[k] = " -B" * tok[k] 	# Simple case, no quotes to break our heads
			else                          tok[k] = " " * tok[k]
			end
			k = k + 1
		end
		# Rebuild the B option string
		opt_B = ""
		for n = 1:k-1
			opt_B *= tok[n]
		end
	end

	# We can have one or all of them. Deal separatelly here to allow way code to keep working
	this_opt_B = "";
	for symb in [:yaxis2 :xaxis2 :axis2 :zaxis :yaxis :xaxis]
		if (haskey(d, symb) && isa(d[symb], NamedTuple))
			if     (symb == :axis2)   this_opt_B = axis(d[symb], secondary=true)
			elseif (symb == :xaxis)   this_opt_B = axis(d[symb], x=true) * this_opt_B
			elseif (symb == :xaxis2)  this_opt_B = axis(d[symb], x=true, secondary=true) * this_opt_B
			elseif (symb == :yaxis)   this_opt_B = axis(d[symb], y=true) * this_opt_B
			elseif (symb == :yaxis2)  this_opt_B = axis(d[symb], y=true, secondary=true) * this_opt_B
			elseif (symb == :zaxis)   this_opt_B = axis(d[symb], z=true) * this_opt_B
			end
		end
	end

	if (opt_B != def_fig_axes_)  opt_B *= this_opt_B
	elseif (this_opt_B != "")    opt_B  = this_opt_B
	end

	return cmd * opt_B, opt_B
end

# ---------------------------------------------------------------------------------------------------
function parse_BJR(d::Dict, cmd::String, caller, O, defaultJ="", del=false)
	# Join these three in one function. CALLER is non-empty when module is called by plot()
	cmd, opt_R = parse_R(cmd, d, O, del)
	cmd, opt_J = parse_J(cmd, d, defaultJ, true, O, del)

	global IamModern
	def_fig_axes_ = (IamModern) ? "" : def_fig_axes	# def_fig_axes is a global const

	if (caller != "" && occursin("-JX", opt_J))		# e.g. plot() sets 'caller'
		if (caller == "plot3d" || caller == "bar3" || caller == "scatter3")
			def_fig_axes3_ = (IamModern) ? "" : def_fig_axes3
			cmd, opt_B = parse_B(cmd, d, (O ? "" : def_fig_axes3_), del)
		else
			cmd, opt_B = parse_B(cmd, d, (O ? "" : def_fig_axes_), del)	# For overlays, default is no axes
		end
	else
		cmd, opt_B = parse_B(cmd, d, (O ? "" : def_fig_axes_), del)
	end
	return cmd, opt_B, opt_J, opt_R
end

# ---------------------------------------------------------------------------------------------------
function parse_F(cmd::String, d::Dict)
	cmd = add_opt(cmd, 'F', d, [:F :box], (clearance="+c", fill=("+g", add_opt_fill), inner="+i",
	                                       pen=("+p", add_opt_pen), rounded="+r", shaded=("+s", arg2str)) )
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
	cmd = parse_UXY(cmd, d, [:X :xoff :x_off :x_offset], 'X')
	cmd = parse_UXY(cmd, d, [:Y :yoff :y_off :y_offset], 'Y')
	cmd = parse_UXY(cmd, d, [:U :stamp :time_stamp], 'U')
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_a(cmd::String, d::Dict)
	# Parse the global -a option. Return CMD same as input if no -a option in args
	parse_helper(cmd, d, [:a :aspatial], " -a")
end

function parse_b(cmd::String, d::Dict)
	# Parse the global -b option. Return CMD same as input if no -b option in args
	parse_helper(cmd, d, [:b :binary], " -b")
end

# ---------------------------------------------------------------------------------------------------
function parse_bi(cmd::String, d::Dict)
	# Parse the global -bi option. Return CMD same as input if no -bi option in args
	parse_helper(cmd, d, [:bi :binary_in], " -bi")
end

# ---------------------------------------------------------------------------------------------------
function parse_bo(cmd::String, d::Dict)
	# Parse the global -bo option. Return CMD same as input if no -bo option in args
	parse_helper(cmd, d, [:bo :binary_out], " -bo")
end

# ---------------------------------------------------------------------------------------------------
function parse_c(cmd::String, d::Dict)
	opt_val = ""
	if ((val = find_in_dict(d, [:c :panel])[1]) !== nothing)
		if (isa(val, Tuple) || isa(val, Array{<:Number}))  opt_val = arg2str(val, ',')  end
		cmd *= " -c" * opt_val
	end
	return cmd, opt_val
end

# ---------------------------------------------------------------------------------------------------
function parse_d(cmd::String, d::Dict)
	# Parse the global -di option. Return CMD same as input if no -di option in args
	parse_helper(cmd, d, [:d :nodata], " -d")
end

# ---------------------------------------------------------------------------------------------------
function parse_di(cmd::String, d::Dict)
	# Parse the global -di option. Return CMD same as input if no -di option in args
	parse_helper(cmd, d, [:di :nodata_in], " -di")
end

# ---------------------------------------------------------------------------------------------------
function parse_do(cmd::String, d::Dict)
	# Parse the global -do option. Return CMD same as input if no -do option in args
	parse_helper(cmd, d, [:do :nodata_out], " -do")
end

# ---------------------------------------------------------------------------------------------------
function parse_e(cmd::String, d::Dict)
	# Parse the global -e option. Return CMD same as input if no -e option in args
	parse_helper(cmd, d, [:e :pattern], " -e")
end

# ---------------------------------------------------------------------------------
function parse_f(cmd::String, d::Dict)
	# Parse the global -f option. Return CMD same as input if no -f option in args
	parse_helper(cmd, d, [:f :colinfo], " -f")
end

# ---------------------------------------------------------------------------------
function parse_g(cmd::String, d::Dict)
	# Parse the global -g option. Return CMD same as input if no -g option in args
	parse_helper(cmd, d, [:g :gaps], " -g")
end

# ---------------------------------------------------------------------------------
function parse_h(cmd::String, d::Dict)
	# Parse the global -h option. Return CMD same as input if no -h option in args
	parse_helper(cmd, d, [:h :header], " -h")
end

# ---------------------------------------------------------------------------------
parse_i(cmd::String, d::Dict) = parse_helper(cmd, d, [:i :incol], " -i")
parse_j(cmd::String, d::Dict) = parse_helper(cmd, d, [:j :spheric_dist :spherical_dist], " -j")

# ---------------------------------------------------------------------------------
function parse_n(cmd::String, d::Dict)
	# Parse the global -n option. Return CMD same as input if no -n option in args
	parse_helper(cmd, d, [:n :interp :interpol], " -n")
end

# ---------------------------------------------------------------------------------
function parse_o(cmd::String, d::Dict)
	# Parse the global -o option. Return CMD same as input if no -o option in args
	parse_helper(cmd, d, [:o :outcol], " -o")
end

# ---------------------------------------------------------------------------------
function parse_p(cmd::String, d::Dict)
	# Parse the global -p option. Return CMD same as input if no -p option in args
	parse_helper(cmd, d, [:p :view :perspective], " -p")
end

# ---------------------------------------------------------------------------------------------------
# Parse the global -s option. Return CMD same as input if no -s option in args
parse_s(cmd::String, d::Dict) = parse_helper(cmd, d, [:s :skip_NaN], " -s")

# ---------------------------------------------------------------------------------------------------
# Parse the global -: option. Return CMD same as input if no -: option in args
# But because we can't have a variable called ':' we use only the aliases
parse_swap_xy(cmd::String, d::Dict) = parse_helper(cmd, d, [:swap_xy :xy :yx], " -:")

# ---------------------------------------------------------------------------------------------------
function parse_r(cmd::String, d::Dict)
	# Parse the global -r option. Return CMD same as input if no -r option in args
	parse_helper(cmd, d, [:r :reg :registration], " -r")
end

# ---------------------------------------------------------------------------------------------------
# Parse the global -x option. Return CMD same as input if no -x option in args
parse_x(cmd::String, d::Dict) = parse_helper(cmd, d, [:x :cores :n_threads], " -x")

# ---------------------------------------------------------------------------------------------------
function parse_t(cmd::String, d::Dict)
	# Parse the global -t option. Return CMD same as input if no -t option in args
	parse_helper(cmd, d, [:t :alpha :transparency], " -t")
end

# ---------------------------------------------------------------------------------------------------
function parse_helper(cmd::String, d::Dict, symbs, opt::String)
	# Helper function to the parse_?() global options.
	opt_val = ""
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		opt_val = opt * arg2str(val)
		cmd *= opt_val
	end
	return cmd, opt_val
end

# ---------------------------------------------------------------------------------------------------
function parse_common_opts(d, cmd, opts, first=true)
	global current_view
	opt_p = nothing
	for opt in opts
		if     (opt == :a)  cmd, = parse_a(cmd, d)
		elseif (opt == :b)  cmd, = parse_b(cmd, d)
		elseif (opt == :c)  cmd, = parse_c(cmd, d)
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
		elseif (opt == :j)  cmd, = parse_j(cmd, d)
		elseif (opt == :n)  cmd, = parse_n(cmd, d)
		elseif (opt == :o)  cmd, = parse_o(cmd, d)
		elseif (opt == :p)  cmd, opt_p = parse_p(cmd, d)
		elseif (opt == :r)  cmd, = parse_r(cmd, d)
		elseif (opt == :s)  cmd, = parse_s(cmd, d)
		elseif (opt == :x)  cmd, = parse_x(cmd, d)
		elseif (opt == :t)  cmd, = parse_t(cmd, d)
		elseif (opt == :yx) cmd, = parse_swap_xy(cmd, d)
		elseif (opt == :R)  cmd, = parse_R(cmd, d)
		elseif (opt == :F)  cmd  = parse_F(cmd, d)
		elseif (opt == :I)  cmd  = parse_inc(cmd, d, [:I :inc], 'I')
		elseif (opt == :J)  cmd, = parse_J(cmd, d)
		elseif (opt == :JZ) cmd, = parse_JZ(cmd, d)
		elseif (opt == :UVXY) cmd = parse_UVXY(cmd, d)
		elseif (opt == :V_params) cmd = parse_V_params(cmd, d)
		elseif (opt == :params) cmd = parse_params(cmd, d)
		end
	end
	if (opt_p !== nothing)		# Restrict the contents of this block to when -p was used
		if (opt_p != "")
			if (opt_p == " -pnone")  current_view = nothing;	cmd = cmd[1:end-7];	opt_p = ""
			else                     current_view = opt_p
			end
		elseif (!first && current_view !== nothing)
			cmd *= current_view
		elseif (first)
			current_view = nothing		# Ensure we start empty
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_these_opts(cmd, d, opts)
	# Parse a group of options that individualualy would had been parsed as (example):
	# cmd = add_opt(cmd, 'A', d, [:A :horizontal])
	for opt in opts
		cmd = add_opt(cmd, string(opt[1]), d, opt)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_inc(cmd::String, d::Dict, symbs, opt, del=false)
	# Parse the quasi-global -I option. But arguments can be strings, arrays, tuples or NamedTuples
	# At the end we must recreate this syntax: xinc[unit][+e|n][/yinc[unit][+e|n]] or
	if ((val = find_in_dict(d, symbs, del)[1]) !== nothing)
		if (isa(val, NamedTuple))
			x = "";	y = "";	u = "";	e = false
			fn = fieldnames(typeof(val))
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
		global usedConfPar = true
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
	if (haskey(d, :colored))  out *= "+c"
	else
		if (haskey(d, :cline))  out *= "+cl"  end
		if (haskey(d, :ctext) || haskey(d, :csymbol))  out *= "+cf"  end
	end
	if (haskey(d, :bezier))  out *= "+s"  end
	if (haskey(d, :offset))  out *= "+o" * arg2str(d[:offset])   end

	if (out != "")		# Search for eventual vec specs, but only if something above has activated -W
		v = false
		r = helper_arrows(d)
		if (r != "")
			if (haskey(d, :vec_start))  out *= "+vb" * r[2:end];  v = true  end	# r[1] = 'v'
			if (haskey(d, :vec_stop))   out *= "+ve" * r[2:end];  v = true  end
			if (!v)  out *= "+" * r  end
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
			if (isa(val, String) || isa(val, Number) || isa(val, Symbol))
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
function parse_arg_and_pen(arg::Tuple, sep="/", pen=true, opt="")
	# Parse an ARG of the type (arg, (pen)) and return a string. These may be used in pscoast -I & -N
	# OPT is the option code letter including the leading - (e.g. -I or -N). This is only used when
	# the ARG tuple has 4, 6, etc elements (arg1,(pen), arg2,(pen), arg3,(pen), ...)
	# When pen=false we call the get_color function instead
	# SEP is normally "+g" when this function is used in the "parse_arg_and_color" mode
	if (isa(arg[1], String) || isa(arg[1], Symbol) || isa(arg[1], Number))  s = string(arg[1])
	else	error("parse_arg_and_pen: Nonsense first argument")
	end
	if (length(arg) > 1)
		if (isa(arg[2], Tuple))  s *= sep * (pen ? parse_pen(arg[2]) : get_color(arg[2])) 
		else                     s *= sep * string(arg[2])		# Whatever that is
		end
	end
	if (length(arg) >= 4) s *= " " * opt * parse_arg_and_pen((arg[3:end]))  end		# Recursive call
	return s
end

# ---------------------------------------------------------------------------------------------------
function arg2str(d::Dict, symbs)
	# Version that allow calls from add_opt()
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)  arg2str(val)  end
end

# ---------------------------------------------------------------------------------------------------
function arg2str(arg, sep='/')
	# Convert an empty, a numeric or string ARG into a string ... if it's not one to start with
	# ARG can also be a Bool, in which case the TRUE value is converted to "" (empty string)
	# SEP is the char separator used when ARG is a tuple ot array of numbers
	if (isa(arg, AbstractString) || isa(arg, Symbol))
		out = string(arg)
	elseif ((isa(arg, Bool) && arg) || isempty_(arg))
		out = ""
	elseif (isa(arg, Number))		# Have to do it after the Bool test above because Bool is a Number too
		out = @sprintf("%.15g", arg)
	elseif (isa(arg, Array{<:Number}) || (isa(arg, Tuple) && !isa(arg[1], String)) )
		#out = join([@sprintf("%.15g/",x) for x in arg])
		out = join([string(x, sep) for x in arg])
		out = rstrip(out, sep)		# Remove last '/'
	elseif (isa(arg, Tuple) && isa(arg[1], String))		# Maybe better than above but misses nice %.xxg
		out = join(arg, sep)
	else
		error(@sprintf("arg2str: argument 'arg' can only be a String, Symbol, Number, Array or a Tuple, but was %s", typeof(arg)))
	end
end

# ---------------------------------------------------------------------------------------------------
function set_KO(first::Bool)
	# Set the O K pair dance
	if (first)  K = true;	O = false
	else        K = true;	O = true;
	end
	return K, O
end

# ---------------------------------------------------------------------------------------------------
function finish_PS_nested(d::Dict, cmd::String, output::String, K::Bool, O::Bool, nested_calls)
	# Finish the PS creating command, but check also if we have any nested module calls like 'coast', 'colorbar', etc
	if ((cmd2 = add_opt_module(d, nested_calls)) !== nothing)  K = true  end
	cmd = finish_PS(d, cmd, output, K, O)
	if (cmd2 !== nothing)  cmd = [cmd; cmd2]  end
	return cmd, K
end

# ---------------------------------------------------------------------------------------------------
function finish_PS(d::Dict, cmd::String, output::String, K::Bool, O::Bool)
	# Finish a PS creating command. All PS creating modules should use this.
	global IamModern
	if (IamModern)  return cmd  end	# In Modern mode this fun does not play
	if (!O && !haskey(d, :P) && !haskey(d, :portrait))  cmd *= " -P"  end

	if (K && !O)              opt = " -K"
	elseif (K && O)           opt = " -K -O"
	else                      opt = ""
	end

	if (output != "")
		if (K && !O)          cmd *= opt * " > " * output
		elseif (!K && !O)     cmd *= opt * " > " * output
		elseif (O)            cmd *= opt * " >> " * output
		end
	else
		if ((K && !O) || (!K && !O) || O)  cmd *= opt  end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt(cmd::String, opt, d::Dict, symbs, mapa=nothing, del::Bool=false, arg=nothing)
	# Scan the D Dict for SYMBS keys and if found create the new option OPT and append it to CMD
	# If DEL == true we remove the found key.
	# ARG, is a special case to append to a matrix (complicated thing in Julia)
	# ARG can alse be a Bool, in which case when MAPA is a NT we expand each of its members as sep options
	if ((val = find_in_dict(d, symbs, del)[1]) === nothing)
		if (isa(arg, Bool) && isa(mapa, NamedTuple))	# Make each mapa[i] a mapa[i]key=mapa[i]val
			cmd_ = ""
			for k in keys(mapa)
				if ((val_ = find_in_dict(d, [k])[1]) === nothing)  continue  end
				if (isa(mapa[k], Tuple))  cmd_ *= mapa[k][1] * mapa[k][2](d, [k])
				else                      cmd_ *= mapa[k] * arg2str(val_)
				end
			end
			if (cmd_ != "")  cmd *= " -" * opt * cmd_  end
		end
		return cmd
	end

	if (isa(val, NamedTuple) && isa(mapa, NamedTuple))
		args = add_opt(val, mapa, arg)
	elseif (isa(val, Tuple) && length(val) > 1 && isa(val[1], NamedTuple))	# In fact, all val[i] -> NT
		# Used in recursive calls for options like -I, -N , -W of pscoast. Here we assume that opt != ""
		args = ""
		for k = 1:length(val)
			args *= " -" * opt * add_opt(val[k], mapa, arg)
		end
		return cmd * args
	elseif (isa(mapa, Tuple) && length(mapa) > 1 && isa(mapa[2], Function))	# grdcontour -G
		if (isa(val, NamedTuple))
			if (mapa[2] == helper_decorated)  args = mapa[2](val, true)		# 'true' => single argout
			else                              args = mapa[2](val)			# Case not yet invented
			end
		elseif (isa(val, String))
			args = val
		else
			error("The option argument must be a NamedTuple, not a simple Tuple")
		end
	else
		args = arg2str(val)
	end

	if (opt != "")  cmd = string(cmd, " -", opt, args)
	else            cmd = string(cmd, args)
	end

	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt(nt::NamedTuple, mapa::NamedTuple, arg=nothing)
	# Generic parser of options passed in a NT and whose last element is anther NT with the mapping
	# between expanded sub-options names and the original GMT flags.
	# ARG, is a special case to append to a matrix (complicated thing in Julia)
	# Example:
	#	add_opt((a=(1,0.5),b=2), (a="+a",b="-b"))
	# translates to:	"+a1/0.5-b2"
	key = keys(nt);						# The keys actually used in this call
	d = nt2dict(mapa)					# The flags mapping as a Dict (all possible flags of the specific option)
	cmd = "";		cmd_hold = Array{String,1}(undef, 2);	order = zeros(Int,2,1);  ind_o = 0
	for k = 1:length(key)				# Loop over the keys of option's tuple
		if (!haskey(d, key[k]))  continue  end
		if (isa(d[key[k]], Tuple))		# Complexify it. Here, d[key[k]][2] must be a function name.
			if (isa(nt[k], NamedTuple))
				if (d[key[k]][2] == add_opt_fill)
					cmd *= d[key[k]][1] * d[key[k]][2]("", Dict(key[k] => nt[k]), [key[k]])
				else
					local_opt = (d[key[k]][2] == helper_decorated) ? true : nothing		# 'true' means getting a single argout
					cmd *= d[key[k]][1] * d[key[k]][2](nt2dict(nt[k]), local_opt)
				end
			else						# 
				if (length(d[key[k]]) == 2)		# Run the function
					cmd *= d[key[k]][1] * d[key[k]][2](Dict(key[k] => nt[k]), [key[k]])
				else					# This branch is to deal with options -Td, -Tm, -L and -D of basemap & psscale
					ind_o += 1
					if (d[key[k]][2] === nothing)  cmd_hold[ind_o] = d[key[k]][1]	# Only flag char and order matters
					else                           cmd_hold[ind_o] = d[key[k]][1] * d[key[k]][2](nt[k])		# Run the fun
					end
					order[ind_o]    = d[key[k]][3];				# Store the order of this sub-option
				end
			end
		elseif (d[key[k]] == "1")		# Means that only first char in value is retained. Used with units
			t = arg2str(nt[k])
			if (t != "")  cmd *= t[1]
			else          cmd *= "1"	# "1" is itself the flag
			end
		elseif (d[key[k]] != "" && d[key[k]][1] == '|')		# Potentialy append to the arg matrix
			if (isa(nt[k], AbstractArray) || isa(nt[k], Tuple))
				if (isa(nt[k], AbstractArray))  append!(arg, reshape(nt[k], :))
				else                            append!(arg, reshape(collect(nt[k]), :))
				end
			end
			cmd *= d[key[k]][2:end]		# And now append the flag
		elseif (d[key[k]] != "" && d[key[k]][1] == '_')		# Means ignore the content, only keep the flag
			cmd *= d[key[k]][2:end]		# Just append the flag
		elseif (d[key[k]] != "" && d[key[k]][end] == '1')	# Means keep the flag and only first char of arg
			cmd *= d[key[k]][1:end-1] * string(nt[k])[1]
		elseif (d[key[k]] != "" && d[key[k]][end] == '#')	# Means put flag at the end and make this arg first in cmd (coast -W)
			cmd = arg2str(nt[k]) * d[key[k]][1:end-1] * cmd
		else
			cmd *= d[key[k]] * arg2str(nt[k])
		end
	end

	if (ind_o > 0)			# We have an ordered set of flags (-Tm, -Td, -D, etc...). Not so trivial case
		if     (order[1] == 1 && order[2] == 2)  cmd = cmd_hold[1] * cmd_hold[2] * cmd;		last = 2
		elseif (order[1] == 2 && order[2] == 1)  cmd = cmd_hold[2] * cmd_hold[1] * cmd;		last = 1
		else                                     cmd = cmd_hold[1] * cmd;		last = 1
		end
		if (occursin(':', cmd_hold[last]))		# It must be a geog coordinate in dd:mm
			cmd = "g" * cmd
		elseif (length(cmd_hold[last]) > 2)		# Temp patch to avoid parsing single char flags
			rs = split(cmd_hold[last], '/')
			if (length(rs) == 2)
				x = parse(Float64, rs[1]);		y = parse(Float64, rs[2]);
				if (0 <= x <= 1.0 && 0 <= y <= 1.0 && !occursin(r"[gjJxn]", string(cmd[1])))  cmd = "n" * cmd  end		# Otherwise, either a paper coord or error
			end
		end
	end

	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt(fun::Function, t1::Tuple, t2::NamedTuple, del::Bool, mat)
	# Crazzy shit to allow increasing the arg1 matrix
	n_rows, n_cols = size(mat)
	mat = reshape(mat, :)	
	cmd = fun(t1..., t2, del, mat)
	mat = reshape(mat, n_rows, :)
	return cmd, mat
end

# ---------------------------------------------------------------------------------------------------
function add_opt_cpt(d::Dict, cmd::String, symbs, opt::Char, N_args=0, arg1=nothing, arg2=nothing,
	                 store=false, def=false, opt_T="", in_bag=false)
	# Deal with options of the form -Ccolor, where color can be a string or a GMTcpt type
	# SYMBS is normally: [:C :color :cmap]
	# N_args only applyies to when a GMTcpt was transmitted. Than it's either 0, case in which
	# the cpt is put in arg1, or 1 and the cpt goes to arg2.
	# STORE, when true, will save the cpt in the global state
	# DEF, when true, means to use the default cpt (Jet)
	# OPT_T, when != "", contains a min/max/n_slices/+n string to calculate a cpt with n_slices colors between [min max]
	# IN_BAG, if true means that, if not empty, we return the contents of `current_cpt`
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		if (isa(val, GMT.GMTcpt))
			if (N_args > 1)  error("Can't send the CPT data via option AND input array")  end
			cmd, arg1, arg2, N_args = helper_add_cpt(cmd, opt, N_args, arg1, arg2, val, store)
		else
			if (opt_T != "")
				cpt = makecpt(opt_T * " -C" * get_color(val))
				cmd, arg1, arg2, N_args = helper_add_cpt(cmd, opt, N_args, arg1, arg2, cpt, store)
			else
				cmd *= " -" * opt * get_color(val)
			end
		end
	elseif (def && opt_T != "")		# Requested the use of the default color map (here Jet, instead of rainbow)
		cpt = makecpt(opt_T * " -Cjet")
		cmd, arg1, arg2, N_args = helper_add_cpt(cmd, opt, N_args, arg1, arg2, cpt, store)
	elseif (in_bag)					# If everything else has failed and we have one in the Bag, return it
		global current_cpt
		if (current_cpt !== nothing)
			cmd, arg1, arg2, N_args = helper_add_cpt(cmd, opt, N_args, arg1, arg2, current_cpt, false)
		end
	end
	return cmd, arg1, arg2, N_args
end
# ---------------------
function helper_add_cpt(cmd, opt, N_args, arg1, arg2, val, store)
	# Helper function to avoid repeating 3 times the same code in add_opt_cpt
	(N_args == 0) ? arg1 = val : arg2 = val;	N_args += 1
	if (store)  global current_cpt = val  end
	cmd *= " -" * opt
	return cmd, arg1, arg2, N_args
end

# ---------------------------------------------------------------------------------------------------
add_opt_fill(d::Dict, symbs, opt="") = add_opt_fill("", d, symbs, opt)
function add_opt_fill(cmd::String, d::Dict, symbs, opt="")
	# Deal with the area fill attributes option. Normally, -G
	if ((val = find_in_dict(d, symbs)[1]) === nothing)  return cmd  end
	if (opt != "")  opt = " -" * opt  end
	if (isa(val, NamedTuple))
		d2 = nt2dict(val)
		cmd *= opt
		if     (haskey(d2, :pattern))     cmd *= 'p' * add_opt("", "", d2, [:pattern])
		elseif (haskey(d2, :inv_pattern)) cmd *= 'P' * add_opt("", "", d2, [:inv_pattern])
		else   error("For 'fill' option as a NamedTuple, you MUST provide a 'patern' member")
		end

		if ((val2 = find_in_dict(d2, [:bg :background])[1]) !== nothing)  cmd *= "+b" * get_color(val2)  end
		if ((val2 = find_in_dict(d2, [:fg :foreground])[1]) !== nothing)  cmd *= "+f" * get_color(val2)  end
		if (haskey(d2, :dpi))  cmd = string(cmd, "+r", d2[:dpi])  end
	else
		cmd *= opt * get_color(val)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function get_cpt_set_R(d, cmd0, cmd, opt_R, got_fname, arg1, arg2=nothing, arg3=nothing, prog="")
	# Get CPT either from keyword input of from current_cpt.
	# Also puts -R in cmd when accessing grids from grdimage|view|contour, etc... (due to a GMT bug that doesn't do it)
	# Used CMD0 = "" to use this function from within non-grd modules
	global current_cpt
	cpt_opt_T = ""
	if (isa(arg1, GMTgrid))			# GMT bug, -R will not be stored in gmt.history
		range = arg1.range
	elseif (cmd0 != "")
		info = grdinfo(cmd0 * " -C");	range = info[1].data
	end
	if (isa(arg1, GMTgrid) || cmd0 != "")
		if (current_cpt === nothing && (val = find_in_dict(d, [:C :color :cmap])[1]) === nothing)
			# If no cpt name sent in, then compute (later) a default cpt
			cpt_opt_T = @sprintf(" -T%.14g/%.14g/128+n", range[5], range[6])
		end
		if (opt_R == "")
			cmd *= @sprintf(" -R%.14g/%.14g/%.14g/%.14g", range[1], range[2], range[3], range[4])
		end
	end

	N_used = got_fname == 0 ? 1 : 0					# To know whether a cpt will go to arg1 or arg2
	get_cpt = false;	in_bag = true;		# IN_BAG means seek if current_cpt != nothing and return it
	if (prog == "grdview")
		get_cpt = true
		if ((val = find_in_dict(d, [:G :drapefile])[1]) !== nothing)
			if (isa(val, Tuple) && length(val) == 3)  get_cpt = false  end	# Playing safe
		end
	elseif (prog == "grdimage" && (isempty_(arg3) && !occursin("-D", cmd)))
		get_cpt = true		# This still lieve out the case when the r,g,b were sent as a text.
	elseif (prog == "grdcontour" || prog == "pscontour")	# Here C means Contours but we cheat, so always check if C, color, ... is present
		get_cpt = true;		cpt_opt_T = ""		# This is hell. And what if I want to auto generate a cpt?
		if (prog == "grdcontour" && !occursin("+c", cmd))  in_bag = false  end
	#elseif (prog == "" && current_cpt !== nothing)		# Not yet used
		#get_cpt = true
	end
	if (get_cpt)
		cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_used, arg1, arg2, true, true, cpt_opt_T, in_bag)
	end
	return cmd, N_used, arg1, arg2, arg3
end

# ---------------------------------------------------------------------------------------------------
function add_opt_module(d::Dict, symbs)
	#  SYMBS should contain a module name 'coast' or 'colorbar', and if present in D,
	# 'val' must be a NamedTuple with the module's arguments.
	out = Array{String,1}()
	for k = 1:length(symbs)
		r = nothing
		if (haskey(d, symbs[k]))
			val = d[symbs[k]]
			if (isa(val, NamedTuple))
				nt = (val..., Vd=2)
				if     (symbs[k] == :coast)    r = coast!(; nt...)
				elseif (symbs[k] == :colorbar) r = colorbar!(; nt...)
				elseif (symbs[k] == :basemap)  r = basemap!(; nt...)
				end
			elseif (isa(val, Number) && (val != 0))		# Allow setting coast=true || colorbar=true
				if     (symbs[k] == :coast)    r = coast!(W=0.5, Vd=2)
				elseif (symbs[k] == :colorbar) r = colorbar!(pos=(anchor=:MR,), B=:a, Vd=2)
				end
			end
		end
		if (r != nothing)  append!(out, [r])  end
	end
	if (out == [])  return nothing
	else            return out
	end
end

# ---------------------------------------------------------------------------------------------------
function get_color(val)
	# Parse a color input. Always return a string
	# color1,color2[,color3,…] colorn can be a r/g/b triplet, a color name, or an HTML hexadecimal color (e.g. #aabbcc
	if (isa(val, String) || isa(val, Symbol) || isa(val, Number))  return isa(val, Bool) ? "" : string(val)  end

	out = ""
	if (isa(val, Tuple))
		for k = 1:length(val)
			if (isa(val[k], Tuple) && (length(val[k]) == 3))
				s = 1
				if (val[k][1] <= 1 && val[k][2] <= 1 && val[k][3] <= 1)  s = 255  end	# colors in [0 1]
				out *= @sprintf("%d/%d/%d,", val[k][1]*s, val[k][2]*s, val[k][3]*s)
			elseif (isa(val[k], Symbol) || isa(val[k], String) || isa(val[k], Number))
				out *= string(val[k],",")
			else
				error("Color tuples must have only one or three elements")
			end
		end
		out = rstrip(out, ',')		# Strip last ','``
	elseif ((isa(val, Array) && (size(val, 2) == 3)) || (isa(val, Vector) && length(val) == 3))
		if (isa(val, Vector))  val = val'  end
		if (val[1,1] <= 1 && val[1,2] <= 1 && val[1,3] <= 1)
			copia = val .* 255		# Do not change the original
		else
			copia = val
		end
		out = @sprintf("%d/%d/%d", copia[1,1], copia[1,2], copia[1,3])
		for k = 2:size(copia, 1)
			out = @sprintf("%s,%d/%d/%d", out, copia[k,1], copia[k,2], copia[k,3])
		end
	else
		error(@sprintf("GOT_COLOR, got an unsupported data type: %s", typeof(val)))
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
function font(d::Dict, symbs)
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		font(val)
	else
		# Should not come here anymore, collect returns the dict members in arbitrary order
		font(collect(values(d))[1])
	end
end
function font(val)
	# parse and create a font string.
	# TODO: either add a NammedTuple option and/or guess if 2nd arg is the font name or the color
	# And this: Optionally, you may append =pen to the fill value in order to draw the text outline with
	# the specified pen; if used you may optionally skip the filling of the text by setting fill to -.
	if (isa(val, String) || isa(val, Number))  return string(val)  end

	s = ""
	if (isa(val, Tuple))
		s = parse_units(val[1])
		if (length(val) > 1)
			s = string(s,',',val[2])
			if (length(val) > 2)
				s = string(s, ',', get_color(val[3]))
			end
		end
	end
	return s
end

# ---------------------------------------------------------------------------------------------------
function parse_units(val)
	# Parse a units string in the form d|e|f|k|n|M|n|s or expanded
	if (isa(val, String) || isa(val, Symbol) || isa(val, Number))  return string(val)  end

	if (isa(val, Tuple) && (length(val) == 2))
		return string(val[1], parse_unit_unit(val[2]))
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

	if     (str == "e" || str == "meter")  out = "e";
	elseif (str == "M" || str == "mile")   out = "M";
	elseif (str == "nodes")                out = "+n";
	elseif (str == "data")                 out = "u";		# For the `scatter` modules
	else                                   out = string(str[1])		# To be type-stable
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

	secondary ? primo = 's' : primo = 'p'			# Primary or secondary axis
	x ? axe = "x" : y ? axe = "y" : z ? axe = "z" : axe = ""	# Are we dealing with a specific axis?

	opt = " -B"
	if ((val = find_in_dict(d, [:frame :axes])[1]) !== nothing)
		opt *= helper0_axes(val)
	end

	if (haskey(d, :corners)) opt *= string(d[:corners])  end	# 1234
	#if (haskey(d, :fill))    opt *= "+g" * get_color(d[:fill])  end
	val, symb = find_in_dict(d, [:fill :bg :background])
	if (val !== nothing)     opt *= "+g" * add_opt_fill(d, [symb])  end	# Works, but patterns can screw
	if (haskey(d, :cube))    opt *= "+b"  end
	if (haskey(d, :noframe)) opt *= "+n"  end
	if (haskey(d, :pole))    opt *= "+o" * arg2str(d[:pole])  end
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
	if (haskey(d, :ticks_unit)) ints *= helper2_axes(d[:ticks_unit])   end
	if (haskey(d, :grid))       ints *= "g" * helper1_axes(d[:grid])   end
	if (haskey(d, :prefix))     ints *= "+p" * str_with_blancs(arg2str(d[:prefix]))  end
	if (haskey(d, :suffix))     ints *= "+u" * str_with_blancs(arg2str(d[:suffix]))  end
	if (haskey(d, :slanted))
		s = arg2str(d[:slanted])
		if (s != "")
			if (!isnumeric(s[1]) && s[1] != '-' && s[1] != '+')
				s = s[1]
				if (axe == "y" && s != 'p')  error("slanted option: Only 'parallel' is allowed for the y-axis")  end
			end
			ints *= "+a" * s
		end
	end
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
		if     (s == "log")  ints *= 'l'
		elseif (s == "10log" || s == "pow")  ints *= 'p'
		elseif (s == "exp")  ints *= 'p'
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
	# Used by annot, ticks and grid to accept also 'auto' and "" to mean automatic
	out = arg2str(arg)
	if (out != "" && out[1] == 'a')  out = ""  end
	return out
end
# ------------------------
function helper2_axes(arg)
	# Used by
	out = arg2str(arg)
	if (out == "")
		@warn("Empty units. Ignoring this units request.");		return out
	end
	if     (out == "Y" || out == "year")     out = 'Y'
	elseif (out == "y" || out == "year2")    out = 'y'
	elseif (out == "O" || out == "month")    out = 'O'
	elseif (out == "o" || out == "month2")   out = 'o'
	elseif (out == "U" || out == "ISOweek")  out = 'U'
	elseif (out == "u" || out == "ISOweek2") out = 'u'
	elseif (out == "r" || out == "Gregorian_week") out = 'r'
	elseif (out == "K" || out == "ISOweekday") out = 'K'
	elseif (out == "k" || out == "weekday")  out = 'k'
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
			error("Custom annotations NamedTuple must contain the member 'pos'")
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
vector_attrib(d::Dict, lixo=nothing) = vector_attrib(; d...)	# When comming from add_opt()
vector_attrib(t::NamedTuple) = vector_attrib(; t...)
function vector_attrib(;kwargs...)
	d = KW(kwargs)
	cmd = add_opt("", "", d, [:len :length])
	if (haskey(d, :angle))  cmd = string(cmd, "+a", d[:angle])  end
	if (haskey(d, :middle))
		cmd *= "+m";
		if (d[:middle] == "reverse" || d[:middle] == :reverse)	cmd *= "r"  end
		cmd = helper_vec_loc(d, :middle, cmd)
	else
		for symb in [:start :stop]
			if (haskey(d, symb) && symb == :start)
				cmd *= "+b";
				cmd = helper_vec_loc(d, :start, cmd)
			elseif (haskey(d, symb) && symb == :stop)
				cmd *= "+e";
				cmd = helper_vec_loc(d, :stop, cmd)
			end
		end
	end

	if (haskey(d, :justify))
		t = string(d[:justify])[1]
		if     (t == 'b')  cmd *= "+jb"	# "begin"
		elseif (t == 'e')  cmd *= "+je"	# "end"
		elseif (t == 'c')  cmd *= "+jc"	# "center"
		end
	end

	if ((val = find_in_dict(d, [:half :half_arrow])[1]) !== nothing)
		if (val == "left" || val == :left)	cmd *= "+l"
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

	if (haskey(d, :pole))  cmd *= "+o" * arg2str(d[:pole])  end
	if (haskey(d, :pen))
		if ((p = add_opt_pen(d, [:pen], "")) != "")  cmd *= "+p" * p  end
	end

	if (haskey(d, :shape))
		if (isa(d[:shape], String) || isa(d[:shape], Symbol))
			t = string(d[:shape])[1]
			if     (t == 't')  cmd *= "+h0"		# triang
			elseif (t == 'a')  cmd *= "+h1"		# arrow
			elseif (t == 'V')  cmd *= "+h2"		# V
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

# ---------------------------------------------------------------------------------------------------
#vector4_attrib(d::Dict, lixo=nothing) = vector4_attrib(; d...)	# When comming from add_opt()
vector4_attrib(t::NamedTuple) = vector4_attrib(; t...)
function vector4_attrib(; kwargs...)
	# Old GMT4 vectors (still supported in GMT6)
	d = KW(kwargs)
	cmd = "t"
	if ((val = find_in_dict(d, [:align :center])[1]) !== nothing)
		c = string(val)[1]
		if     (c == 'h' || c == 'b')  cmd = "h"		# Head
		elseif (c == 'm' || c == 'c')  cmd = "b"		# Middle
		elseif (c == 'p')              cmd = "s"		# Point
		end
	end
	if (haskey(d, :double) || haskey(d, :double_head))  cmd = uppercase(cmd)  end

	if (haskey(d, :norm))  cmd = string(cmd, "n", d[:norm])  end
	if ((val = find_in_dict(d, [:head])[1]) !== nothing)
		if (isa(val, NamedTuple))
			ha = "0.075c";	hl = "0.3c";	hw = "0.25c"
			dh = nt2dict(val)
			if (haskey(dh, :arrowwidth))  ha = string(dh[:arrowwidth])  end
			if (haskey(dh, :headlength))  hl = string(dh[:headlength])  end
			if (haskey(dh, :headwidth))   hw = string(dh[:headwidth])   end
			hh = ha * '/' * hl * '/' * hw
		elseif (isa(val, Tuple) && length(val) == 3)  hh = arg2str(val)
		elseif (isa(val, String))                     hh = val		# No checking
		end
		cmd *= hh
	end
	return cmd
end

# -----------------------------------
function helper_vec_loc(d, symb, cmd)
	# Helper function to the 'begin', 'middle', 'end' vector attrib function
	t = string(d[symb])
	if     (t == "line"      )	cmd *= "t"
	elseif (t == "arrow"     )	cmd *= "a"
	elseif (t == "circle"    )	cmd *= "c"
	elseif (t == "tail"      )	cmd *= "i"
	elseif (t == "open_arrow")	cmd *= "A"
	elseif (t == "open_tail" )	cmd *= "I"
	elseif (t == "left_side" )	cmd *= "l"
	elseif (t == "right_side")	cmd *= "r"
	end
	return cmd
end
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
decorated(nt::NamedTuple) = decorated(;nt...)
function decorated(;kwargs...)
	d = KW(kwargs)
	cmd, optD = helper_decorated(d)

	if (haskey(d, :dec2))				# -S~ mode (decorated, with symbols, lines).
		cmd *= ":"
		marca = get_marker_name(d, [:marker :symbol], false)[1]	# This fun lieves in psxy.jl
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
		if (optD == "")  optD = "d"  end	# Really need to improve the algo of this
		opt_S = " -S~"
	elseif (haskey(d, :quoted))				# -Sq mode (quoted lines).
		cmd *= ":"
		cmd = parse_quoted(d, cmd)
		if (optD == "")  optD = "d"  end	# Really need to improve the algo of this
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

# ---------------------------------------------------------
helper_decorated(nt::NamedTuple, compose=false) = helper_decorated(nt2dict(nt), compose)
function helper_decorated(d::Dict, compose=false)
	# Helper function to deal with the gap and symbol size parameters.
	# At same time it's also what we need to call to build up the grdcontour -G option.
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
			error("DECORATED: 'dist' (or 'distance') option. Unknown data type.")
		end
		if     (symb == :distmap)  optD = "D"		# Here we know that we are dealing with a -S~ for sure.
		elseif (symb != :number && compose)  optD = "d"		# I feer the case :number is not parsed anywhere
		end
	end
	if (cmd == "")
		val, symb = find_in_dict(d, [:line :Line])
		flag = (symb == :line) ? 'l' : 'L'
		if (val !== nothing)
			if (isa(val, Array{<:Number}))
				if (size(val,2) !=4)
					error("DECORATED: 'line' option. When array, it must be an Mx4 one")
				end
				optD = string(flag,val[1,1],'/',val[1,2],'/',val[1,3],'/',val[1,4])
				for k = 2:size(val,1)
					optD = string(optD,',',val[k,1],'/',val[k,2],'/',val[k,3],'/',val[k,4])
				end
			elseif (isa(val, Tuple) || isa(val, String))
				optD = flag * arg2str(val)
			else
				@warn("DECORATED: lines option. Unknown option data type. Ignoring this.")
			end
		end
	end
	if (cmd == "" && optD == "")
		optD = ((val = find_in_dict(d, [:n_labels :n_symbols])[1]) !== nothing) ? string("n",val) : "n1"
	end
	if (cmd == "")
		if ((val = find_in_dict(d, [:N_labels :N_symbols])[1]) !== nothing)
			optD = string("N", val);
		end
	end
	if (compose)
		return optD * cmd			# For example for grdgradient -G
	else
		return cmd, optD
	end
end

# -------------------------------------------------
#parse_quoted(nt::NamedTuple) = parse_quoted(;nt...)
function parse_quoted(d::Dict, opt)
	# This function is isolated from () above to allow calling it seperately from grdcontour
	# In fact both -A and -G grdcontour options are almost equal to a decorated line in psxy.
	# So we need a mechanism to call it all at once (psxy) or in two parts (grdcontour).
	cmd = (isa(opt, String)) ? opt : ""			# Need to do this to prevent from calls that don't set OPT
	if (haskey(d, :angle))   cmd  = string(cmd, "+a", d[:angle])  end
	if (haskey(d, :debug))   cmd *= "+d"  end
	if (haskey(d, :clearance ))  cmd *= "+c" * arg2str(d[:clearance]) end
	if (haskey(d, :delay))   cmd *= "+e"  end
	if (haskey(d, :font))    cmd *= "+f" * font(d[:font])    end
	if (haskey(d, :color))   cmd *= "+g" * arg2str(d[:color])   end
	if (haskey(d, :justify)) cmd = string(cmd, "+j", d[:justify]) end
	if (haskey(d, :const_label)) cmd = string(cmd, "+l", str_with_blancs(d[:const_label]))  end
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
	return cmd
end
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
function fname_out(d::Dict, first::Bool)
	# Create an file name in the TMP dir when OUT holds only a known extension. The name is: GMTjl_tmp.ext
	EXT = ""
	if (haskey(d, :fmt))  out = string(d[:fmt])
	else                  out = FMT						# Use the global FMT choice
	end
	if (out == "" && !Sys.iswindows())
		error("NOT specifying the **fmt** format is only allowed on Windows")
	end
	if (haskey(d, :ps))			# In any case this means we want the PS sent back to Julia
		out = "";	EXT = "ps"
	end
	# When OUT == "" here, it plays a double role. It means to put the PS in memory or
	# return it to the REPL. The ambiguity is cleared in finish_PS_module()

	opt_T = "";
	if (out == "pdfg" || out == "gpdf")  out = "pdg"  end	# Trick to keep the ext with only 3 chars (for GeoPDFs)
	if (length(out) <= 3)
		@static Sys.iswindows() ? template = tempdir() * "GMTjl_tmp.ps" : template = tempdir() * "/" * "GMTjl_tmp.ps"
		ext = lowercase(out)
		if (ext == "ps")       out = template;  EXT = ext
		elseif (ext == "pdf")  opt_T = " -Tf";	out = template;		EXT = ext
		elseif (ext == "eps")  opt_T = " -Te";	out = template;		EXT = ext
		elseif (ext == "png")  opt_T = " -Tg";	out = template;		EXT = ext
		elseif (ext == "PNG")  opt_T = " -TG";	out = template;		EXT = "png"		# Don't want it to be .PNG
		elseif (ext == "jpg")  opt_T = " -Tj";	out = template;		EXT = ext
		elseif (ext == "tif")  opt_T = " -Tt";	out = template;		EXT = ext
		elseif (ext == "pdg")  opt_T = " -Tf -Qp";	out = template;	EXT = "pdf"
		end
	end
	K, O = set_KO(first)		# Set the K O dance
	return out, opt_T, EXT, K, O
end

# ---------------------------------------------------------------------------------------------------
function read_data(d::Dict, fname::String, cmd, arg, opt_R="", opt_i="", is3D=false)
	# In case DATA holds a file name, read that data and put it in ARG
	# Also compute a tight -R if this was not provided
	global IamModern
	data_kw = nothing
	if (haskey(d, :data))  data_kw = d[:data]  end
	if (fname != "")       data_kw = fname     end

	cmd, opt_i  = parse_i(cmd, d)		# If data is to be read as binary
	cmd, opt_di = parse_di(cmd, d)		# If data missing data other than NaN
	cmd, opt_h  = parse_h(cmd, d)
	if (isa(data_kw, String))
		if (opt_R == "")				# Then we must read the file to determine -R
			lixo, opt_bi = parse_bi("", d)	# See if user says file is binary
			if (GMTver >= 6)				# Due to a bug in GMT5, gmtread has no -i option
				data_kw = gmt("read -Td " * opt_i * opt_bi * opt_di * opt_h * " " * data_kw)
				if (opt_i != "")			# Remove the -i option from cmd. It has done its job
					cmd = replace(cmd, opt_i => "")
					opt_i = ""
				end
				if (opt_h != "")  cmd = replace(cmd, opt_h => "");	opt_h = ""  end
			else
				data_kw = gmt("read -Td " * opt_bi * opt_di * opt_h * " " * data_kw)
			end
		else							# No need to find -R so let the GMT module read the file
			cmd = data_kw * " " * cmd
			data_kw = nothing			# Prevent that it goes (repeated) into 'arg'
		end
	end

	if (data_kw !== nothing)  arg = data_kw  end		# Finaly move the data into ARG

	if (!IamModern && (opt_R == "" || opt_R[1] == '/'))
		info = gmt("gmtinfo -C" * opt_i * opt_di * opt_h, arg)		# Here we are reading from an original GMTdataset or Array
		if (opt_R != "" && opt_R[1] == '/')	# Modify what will be reported as a -R string
			# Example "/-0.1/0.1/0//" will extend x axis +/- 0.1, set y_min=0 and no change to y_max
			rs = split(opt_R, '/')
			for k = 2:length(rs)
				if (rs[k] != "")
					x = parse(Float64, rs[k])
					(x == 0.0) ? info[1].data[k-1] = x : info[1].data[k-1] += x
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
		cmd *= opt_R
	end

	return cmd, arg, opt_R, opt_i
end

# ---------------------------------------------------------------------------------------------------
round_wesn(wesn::Array{Int}, geo::Bool=false) = round_wesn(float(wesn),geo)
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
function find_data(d::Dict, cmd0::String, cmd::String, args...)
	# ...
	got_fname = 0;		data_kw = nothing
	if (haskey(d, :data))	data_kw = d[:data]	end
	if (cmd0 != "")						# Data was passed as file name
		cmd = cmd0 * " " * cmd
		got_fname = 1
	end

	# Check if we need to save to file
	if     (haskey(d, :>))      cmd = string(cmd, " > ", d[:>])
	elseif (haskey(d, :|>))     cmd = string(cmd, " > ", d[:|>])
	elseif (haskey(d, :write))  cmd = string(cmd, " > ", d[:write])
	elseif (haskey(d, :>>))     cmd = string(cmd, " > ", d[:>>])
	elseif (haskey(d, :write_append))  cmd = string(cmd, " > ", d[:write_append])
	end

	tipo = length(args)
	if (tipo == 1)
		# Accepts "input1"; arg1; data=input1;
		if (got_fname != 0 || args[1] !== nothing)
			return cmd, got_fname, args[1]		# got_fname = 1 => data is in cmd;	got_fname = 0 => data is in arg1
		elseif (data_kw !== nothing)
			if (isa(data_kw, String))
				cmd = data_kw * " " * cmd
				return cmd, 1, args[1]			# got_fname = 1 => data is in cmd
			else
				return cmd, 0, data_kw 		# got_fname = 0 => data is in arg1
			end
		else
			error("Missing input data to run this module.")
		end
	elseif (tipo == 2)			# Two inputs (but second can be optional in some modules)
		# Accepts "input1 input2"; "input1", arg1; "input1", data=input2; arg1, arg2; data=(input1,input2)
		if (got_fname != 0)
			if (args[1] === nothing && data_kw === nothing)
				return cmd, 1, args[1], args[2]		# got_fname = 1 => all data is in cmd
			elseif (args[1] !== nothing)
				return cmd, 2, args[1], args[2]		# got_fname = 2 => data is in cmd and arg1
			elseif (data_kw !== nothing && length(data_kw) == 1)
				return cmd, 2, data_kw, args[2]	# got_fname = 2 => data is in cmd and arg1
			end
		else
			if (args[1] !== nothing && args[2] !== nothing)
				return cmd, 0, args[1], args[2]				# got_fname = 0 => all data is in arg1,2
			elseif (args[1] !== nothing && args[2] === nothing && data_kw === nothing)
				return cmd, 0, args[1], args[2]				# got_fname = 0 => all data is in arg1
			elseif (args[1] !== nothing && args[2] === nothing && data_kw !== nothing && length(data_kw) == 1)
				return cmd, 0, args[1], data_kw			# got_fname = 0 => all data is in arg1,2
			elseif (data_kw !== nothing && length(data_kw) == 2)
				return cmd, 0, data_kw[1], data_kw[2]	# got_fname = 0 => all data is in arg1,2
			end
		end
		error("Missing input data to run this module.")
	elseif (tipo == 3)			# Three inputs
		# Accepts "input1 input2 input3"; arg1, arg2, arg3; data=(input1,input2,input3)
		if (got_fname != 0)
			if (args[1] === nothing && data_kw === nothing)
				return cmd, 1, args[1], args[2], args[3]			# got_fname = 1 => all data is in cmd
			else
				error("Cannot mix input as file names and numeric data.")
			end
		else
			if (args[1] === nothing && args[2] === nothing && args[3] === nothing)
				return cmd, 0, args[1], args[2], args[3]			# got_fname = 0 => ???
			elseif (data_kw !== nothing && length(data_kw) == 3)
				return cmd, 0, data_kw[1], data_kw[2], data_kw[3]	# got_fname = 0 => all data in arg1,2,3
			else
				return cmd, 0, args[1], args[2], args[3]
			end
		end
	end
end

# ---------------------------------------------------------------------------------------------------
function common_grd(d::Dict, cmd0::String, cmd::String, prog::String, args...)
	n_args = 0
	for k = 1:length(args) if (args[k] !== nothing)  n_args += 1  end  end	# Drop the nothings
	if     (n_args <= 1)  cmd, got_fname, arg1 = find_data(d, cmd0, cmd, args[1])
	elseif (n_args == 2)  cmd, got_fname, arg1, arg2 = find_data(d, cmd0, cmd, args[1], args[2])
	elseif (n_args == 3)  cmd, got_fname, arg1, arg2, arg3 = find_data(d, cmd0, cmd, args[1], args[2], args[3])
	end
	if (arg1 !== nothing && isa(arg1, Array{<:Number}) && startswith(prog, "grd"))  arg1 = mat2grid(arg1)  end
	(n_args <= 1) ? common_grd(d, prog * cmd, arg1) : (n_args == 2) ? common_grd(d, prog * cmd, arg1, arg2) : common_grd(d, prog * cmd, arg1, arg2, arg3)
end

# ---------------------------------------------------------------------------------------------------
function common_grd(d::Dict, cmd::String, args...)
	# This chunk of code is shared by several grdxxx modules, so wrap it in a function
	if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end		# Vd=2 cause this return
	# First case below is of a ARGS tuple(tuple) with all numeric inputs.
	isa(args, Tuple{Tuple}) ? gmt(cmd, args[1]...) : gmt(cmd, args...)
end

# ---------------------------------------------------------------------------------------------------
function dbg_print_cmd(d::Dict, cmd)
	# Print the gmt command when the Vd=1 kwarg was used
	if (haskey(d, :Vd))
		if (d[:Vd] == :cmd || d[:Vd] == 2)		# For testing puposes, return the GMT command
			return cmd
		else
			println(@sprintf("\t%s", cmd))
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

	global current_cpt = nothing		# Always reset to empty when fig is finalized
	global current_view = nothing
	if (opt_T != "")
		if (K) gmt("psxy -T -R0/1/0/1 -JX1 -O >> " * fname_ps)  end		# Close the PS file first
		if ((val = find_in_dict(d, [:dpi :DPI])[1]) !== nothing)  opt_T *= string(" -E", val)  end
		gmt("psconvert -A1p -Qg4 -Qt4 " * fname_ps * opt_T)
		out = fname_ps[1:end-2] * fname_ext
		if (fname != "")
			out = mv(out, fname, force=true)
		end
	elseif (fname_ps != "")
		if (K) gmt("psxy -T -R0/1/0/1 -JX1 -O >> " * fname_ps)  end		# Close the PS file first
		out = fname_ps
		if (fname != "")
			out = mv(out, fname, force=true)
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
	if (arg === nothing)  return true  end
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

## ---------------------------------------------------------------------------------------------------
function finish_PS_module(d::Dict, cmd, opt_extra::String, output::String, fname_ext::String,
	opt_T::String, K::Bool, O::Bool, finish::Bool, args...)
	# FNAME_EXT hold the extension when not PS
	# OPT_EXTRA is used by grdcontour -D or pssolar -I to not try to create and view a img file
	if (finish) cmd = finish_PS(d, cmd, output, K, O)  end

	if ((r = dbg_print_cmd(d, cmd)) !== nothing)  return r  end 	# For tests only
	global img_mem_layout = add_opt("", "", d, [:layout])
	global usedConfPar

	if (isa(cmd, Array{String, 1}))
		for k = 1:length(cmd)
			P = gmt(cmd[k], args...)
		end
	else
		P = gmt(cmd, args...)
	end

	digests_legend_bag(d)			# Plot the legend if requested

	if (usedConfPar)				# Hacky shit to force start over when --PAR options were use
		usedConfPar = false
		gmt("destroy")
	end

	fname = ""
	if (haskey(d, :savefig))		# Also ensure that file has the right extension
		fname, ext = splitext(d[:savefig])
		if (fname_ext != "")  fname *= '.' * fname_ext
		else                  fname *= ext		# PS, otherwise shit had happened
		end
	end

	if (fname_ext == "" && opt_extra == "")		# Return result as an GMTimage
		P = showfig(d, output, fname_ext, "", K)
		gmt("destroy")							# Returning a PS screws the session
	elseif ((haskey(d, :show) && d[:show] != 0) || fname != "")
		showfig(d, output, fname_ext, opt_T, K, fname)
	end
	return P
end

# --------------------------------------------------------------------------------------------------
mutable struct legend_bag
	label::Array{String,1}
	cmd::Array{String,1}
end

# --------------------------------------------------------------------------------------------------
function put_in_legend_bag(d::Dict, cmd, arg=nothing)
	# So far this fun is only called from plot() and stores line/symbol info in global var LEGEND_TYPE
	global legend_type

	cmd_ = cmd									# Starts to be just a shallow copy
	if (isa(arg, Array{GMT.GMTdataset,1}))		# Multi-segments can have different settings per line
		(isa(cmd, String)) ? cmd_ = deepcopy([cmd]) : cmd_ = deepcopy(cmd)
		lix, penC, penS = break_pen(scan_opt(arg[1].header, "-W"))
		penT, penC_, penS_ = break_pen(scan_opt(cmd_[end], "-W"))
		if (penC == "")  penC = penC_  end
		if (penS == "")  penS = penS_  end
		cmd_[end] = "-W" * penT * ',' * penC * ',' * penS * " " * cmd_[end]	# Trick to make the parser find this pen
		pens = Array{String,1}(undef,length(arg)-1)
		for k = 1:length(arg)-1
			t = scan_opt(arg[k+1].header, "-W")
			if     (t == "")      pens[k] = " -W0.5"
			elseif (t[1] == ',')  pens[k] = " -W" * penT * t		# Can't have, e.g., ",,230/159/0" => Crash
			else                  pens[k] = " -W" * penT * ',' * t
			end
		end
		append!(cmd_, pens)			# Append the 'pens' var to the input arg CMD

		lab = Array{String,1}(undef,length(arg))
		if ((val = find_in_dict(d, [:lab :label])[1]) !== nothing)		# Have label(s)
			if (!isa(val, Array))				# One single label, take it as a label prefix
				for k = 1:length(arg)  lab[k] = string(val,k)  end
			else
				for k = 1:min(length(arg), length(val))  lab[k] = string(val[k],k)  end
				if (length(val) < length(arg))	# Probably shit, but don't error because of it
					for k = length(val)+1:length(arg)  lab[k] = string(val[end],k)  end
				end
			end
		else
			for k = 1:length(arg)  lab[k] = string('y',k)  end
		end
	elseif ((val = find_in_dict(d, [:lab :label])[1]) !== nothing)
		lab = [val]
	elseif (legend_type === nothing)
		lab = ["y1"]
	else
		lab = [@sprintf("y%d", size(legend_type.label ,1))]
	end

	if ((isa(cmd_, Array{String, 1}) && !occursin("-O", cmd_[1])) || (isa(cmd_, String) && !occursin("-O", cmd_)))
		legend_type = nothing					# Make sure that we always start with an empty one
	end

	if (legend_type === nothing)
		legend_type = legend_bag(Array{String,1}(undef,1), Array{String,1}(undef,1))
		legend_type.cmd = (isa(cmd_, String)) ? [cmd_] : cmd_
		legend_type.label = lab
	else
		isa(cmd_, String) ? append!(legend_type.cmd, [cmd_]) : append!(legend_type.cmd, cmd_)
		append!(legend_type.label, lab)
	end
end

# --------------------------------------------------------------------------------------------------
function digests_legend_bag(d::Dict)
	# Plot a legend if the leg or legend keywords were used. Legend info is stored in LEGEND_TYPE global variable
	global legend_type

	if ((val = find_in_dict(d, [:leg :legend])[1]) !== nothing)
		(legend_type === nothing) && @warn("This module does not support automatic legends") && return

		fs = 10					# Font size in points
		symbW = 0.75			# Symbol width. Default to 0.75 cm (good for lines)
		nl  = length(legend_type.label)
		leg = Array{String,1}(undef,nl)
		for k = 1:nl											# Loop over number of entries
			if ((symb = scan_opt(legend_type.cmd[k], "-S")) == "")  symb = "-"
			else                                                    symbW_ = symb[2:end];	symb = symb[1]
			end
			if ((fill = scan_opt(legend_type.cmd[k], "-G")) == "")  fill = "-"  end
			pen  = scan_opt(legend_type.cmd[k],  "-W");
			(pen == "" && symb != "-" && fill != "-") ? pen = "-" : (pen == "" ? pen = "0.25p" : pen = pen)
			if (symb == "-")
				leg[k] = @sprintf("S %.3fc %s %.2fc %s %s %.2fc %s",
				                  symbW/2, symb, symbW, fill, pen, symbW+0.14, legend_type.label[k])
			else
				leg[k] = @sprintf("S - %s %s %s %s - %s", symb, symbW_, fill, pen, legend_type.label[k])
			end
		end

		lab_width = maximum(length.(legend_type.label[:])) * fs / 72 * 2.54 * 0.55 + 0.15	# Guess label width in cm
		if ((opt_D = add_opt("", "", d, [:leg_pos :legend_pos :legend_position],
			(map_coord="g",plot_coord="x",norm="n",pos="j",width="+w",justify="+j",spacing="+l",offset="+o"))) == "")
			just = (isa(val, String) || isa(val, Symbol)) ? justify(val) : "TR"		# "TR" is the default
			opt_D = @sprintf("j%s+w%.3f+o0.1", just, symbW*1.2 + lab_width)
		else
			if (opt_D[1] != 'j' && opt_D[1] != 'g' && opt_D[1] != 'x' && opt_D[1] != 'n')  opt_D = "jTR" * opt_D  end
			if (!occursin("+w", opt_D))  opt_D = @sprintf("%s+w%.3f", opt_D, symbW*1.2 + lab_width)  end
			if (!occursin("+o", opt_D))  opt_D *= "+o0.1"  end
		end

		if ((opt_F = add_opt("", "", d, [:box_pos :box_position],
			(clearance="+c", fill=("+g", add_opt_fill), inner="+i", pen=("+p", add_opt_pen), rounded="+r", shade="+s"))) == "")
			opt_F = "+p0.5+gwhite"
		else
			if (!occursin("+p", opt_F))  opt_F *= "+p0.5"    end
			if (!occursin("+g", opt_F))  opt_F *= "+gwhite"  end
		end
		legend!(text_record(leg), F=opt_F, D=opt_D, par=(:FONT_ANNOT_PRIMARY, fs))
		legend_type = nothing			# Job done, now empty the bag
	end
end

# --------------------------------------------------------------------------------------------------
function scan_opt(cmd, opt)
	# Scan the CMD string for the OPT option. Note OPT mut be a 2 chars -X GMT option.
	out = ""
	if ((ind = findfirst(opt, cmd)) !== nothing)  out, = strtok(cmd[ind[1]+2:end])  end
	return out
end

# --------------------------------------------------------------------------------------------------
function break_pen(pen)
	# Break a pen string in its form thick,color,style into its constituints
	# Absolutely minimalist. Will fail if -Wwidth,color,style pattern is not followed.

	ps = split(pen, ',')
	nc = length(ps)
	if     (nc == 1)  penT = ps[1];    penC = "";       penS = "";	
	elseif (nc == 2)  penT = ps[1];    penC = ps[2];    penS = "";	
	else              penT = ps[1];    penC = ps[2];    penS = ps[3];	
	end
	return penT, penC, penS
end

# --------------------------------------------------------------------------------------------------
function justify(arg)
	# Take a string or symbol in ARG and return the two chars justification code.
	if (isa(arg, Symbol))  arg = string(arg)  end
	if (length(arg) == 2)  return arg  end 		# Assume it's already the 2 chars code (no further checking)
	if     (arg == "topleft"      || arg == "TopLeft")       out = "TL"
	elseif (arg == "middleleft"   || arg == "MiddleLeft")    out = "ML"
	elseif (arg == "bottomleft"   || arg == "BottomLeft")    out = "BL"
	elseif (arg == "topcenter"    || arg == "TopCenter")     out = "TC"
	elseif (arg == "middlecenter" || arg == "MiddleCenter")  out = "MC"
	elseif (arg == "bottomcenter" || arg == "BottomCenter")  out = "BC"
	elseif (arg == "topcright"    || arg == "TopRight")      out = "TR"
	elseif (arg == "middleright"  || arg == "MiddleRight")   out = "MR"
	elseif (arg == "bottomright"  || arg == "BottomRight")   out = "BR"
	else
		@warn("Justification code provided ($arg) is not valid. Defaulting to TopRight")
		out = "TR"
	end
	return out
end

# --------------------------------------------------------------------------------------------------
function monolitic(prog::String, cmd0::String, args...)
	# Run this module in the monolithic way. e.g. [outs] = gmt("module args",[inputs])
	cmd0 = prog * " " * cmd0
	return gmt(cmd0, args...)
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

# --------------------------------------------------------------------------------------------------
function tic()
    t0 = time_ns()
    task_local_storage(:TIMERS, (t0, get(task_local_storage(), :TIMERS, ())))
    return t0
end

function _toq()
    t1 = time_ns()
    timers = get(task_local_storage(), :TIMERS, ())
    if timers === ()
        error("`toc()` without `tic()`")
    end
    t0 = timers[1]::UInt64
    task_local_storage(:TIMERS, timers[2])
    (t1-t0)/1e9
end

function toc(V=true)
    t = _toq()
    if (V)  println("elapsed time: ", t, " seconds")  end
    return t
end