# Parse the common options that all GMT modules share, plus some others functions of also common usage

const KW = Dict{Symbol,Any}
nt2dict(nt::NamedTuple) = nt2dict(; nt...)
nt2dict(; kw...) = Dict(kw)
# Need the Symbol.() below in oder to work from PyCall
# A darker an probably more efficient way is: ((; kw...) -> kw.data)(; d...) but breaks in PyCall
dict2nt(d::Dict) = NamedTuple{Tuple(Symbol.(keys(d)))}(values(d))

function find_in_dict(d::Dict, symbs::Array{Symbol}, del::Bool=true, help_str::String="")
	# See if D contains any of the symbols in SYMBS. If yes, return corresponding value
	(show_kwargs[1] && help_str != "") && return (print_kwarg_opts(symbs, help_str), Symbol())
	for symb in symbs
		if (haskey(d, symb))
			val = d[symb]
			if (del) delete!(d, symb) end
			return val, Symbol(symb)
		end
	end
	return nothing, Symbol()
end

function del_from_dict(d::Dict, symbs::Array{Array{Symbol}})
	# Delete SYMBS from the D dict where SYMBS is an array of array os symbols
	# Example:  del_from_dict(d, [[:a :b], [:c]])
	for symb in symbs
		del_from_dict(d, symb)
	end
end

function del_from_dict(d::Dict, symbs::Array{Symbol})
	# Delete SYMBS from the D dict where symbs is an array of symbols and elements are aliases
	for alias in symbs
		if (haskey(d, alias))
			delete!(d, alias)
			return
		end
	end
end

function init_module(first::Bool, kwargs...)
	# All ps modules need these 3 lines
	d = KW(kwargs)
	help_show_options(d)		# Check if user wants ONLY the HELP mode
	K = true; O = !first
	return d, K, O
end

function GMTsyntax_opt(d::Dict, cmd::String)::String
	if haskey(d, :GMTopt)
		o::String = d[:GMTopt]
		cmd = (o[1] == ' ') ? cmd * o : cmd * " " * o
		delete!(d, :GMTopt)
	end
	cmd
end

function parse_R(d::Dict, cmd::String, O::Bool=false, del::Bool=true)
	# Build the option -R string. Make it simply -R if overlay mode (-O) and no new -R is fished here
	
	(show_kwargs[1]) && return (print_kwarg_opts([:R :region :limits], "GMTgrid | NamedTuple |Tuple | Array | String"), "")

	opt_R = [""]
	if ((val = find_in_dict(d, [:R :region :limits], del)[1]) !== nothing)
		opt_R[1] = build_opt_R(val)
	elseif (IamModern[1])
		return cmd, ""
	end

	if (opt_R[1] == "")		# See if we got the region as tuples of xlim, ylim [zlim]
		R = "";		c = 0
		if (haskey(d, :xlim) && isa(d[:xlim], Tuple) && length(d[:xlim]) == 2)
			R = sprintf(" -R%.15g/%.15g", d[:xlim][1], d[:xlim][2])
			c += 2
			if (haskey(d, :ylim) && isa(d[:ylim], Tuple) && length(d[:ylim]) == 2)
				R = @sprintf("%s/%.15g/%.15g", R, d[:ylim][1], d[:ylim][2])
				c += 2
				if (haskey(d, :zlim) && isa(d[:zlim], Tuple) && length(d[:zlim]) == 2)
					R = @sprintf("%s/%.15g/%.15g", R, d[:zlim][1], d[:zlim][2])
					del_from_dict(d, [:zlim])
				end
				del_from_dict(d, [:ylim])
			end
			del_from_dict(d, [:xlim])
		end
		if (R != "" && c == 4)  opt_R[1] = R  end
	end
	if (O && opt_R[1] == "")  opt_R[1] = " -R"  end
	if (opt_R[1] != "")			# Save limits in numeric
		try
			limits = opt_R2num(opt_R[1])
			CTRL.limits[1:length(limits)] = limits
		catch
			CTRL.limits[1] = CTRL.limits[2] = CTRL.limits[3] = CTRL.limits[4] = 0
		end
	end
	cmd = cmd * opt_R[1]
	return cmd, opt_R[1]
end

function build_opt_R(Val)::String		# Generic function that deals with all but NamedTuple args
	if (isa(Val, String) || isa(Val, Symbol))
		r = string(Val)
		if     (r == "global")     return " -Rd"
		elseif (r == "global360")  return " -Rg"
		elseif (r == "same")       return " -R"
		else                       return " -R" * r
		end
	elseif ((isa(Val, Array{<:Real}) || isa(Val, Tuple)) && (length(Val) == 4 || length(Val) == 6))
		out = arg2str(Val)
		return " -R" * rstrip(out, '/')		# Remove last '/'
	elseif (isa(Val, GMTgrid) || isa(Val, GMTimage))
		return sprintf(" -R%.15g/%.15g/%.15g/%.15g", Val.range[1], Val.range[2], Val.range[3], Val.range[4])
	end
	return ""
end

function build_opt_R(arg::NamedTuple)::String
	# Option -R can also be diabolicly complicated. Try to addres it. Stil misses the Time part.
	BB = [""]
	d = nt2dict(arg)					# Convert to Dict
	if ((val = find_in_dict(d, [:bb :limits :region :BoundingBox])[1]) !== nothing)
		if ((isa(val, Array{<:Real}) || isa(val, Tuple)) && (length(val) == 4 || length(val) == 6))
			if (haskey(d, :diag) || haskey(d, :diagonal))		# The diagonal case
				BB[1] = sprintf("%.15g/%.15g/%.15g/%.15g+r", val[1], val[3], val[2], val[4])
			else
				BB[1] = join([@sprintf("%.15g/", Float64(x)) for x in val])
				BB[1] = rstrip(BB[1], '/')		# and remove last '/'
			end
		elseif (isa(val, String) || isa(val, Symbol))
			t = string(val)
			if     (t == "global")     BB[1] = "-180/180/-90/90"
			elseif (t == "global360")  BB[1] = "0/360/-90/90"
			else                       BB[1] = string(val) 			# Whatever good stuff or shit it may contain
			end
		end
	elseif ((val = find_in_dict(d, [:bb_diag :limits_diag :region_diag :LLUR])[1]) !== nothing)	# Alternative way of saying "+r"
		BB[1] = sprintf("%.15g/%.15g/%.15g/%.15g+r", val[1], val[3], val[2], val[4])
	elseif ((val = find_in_dict(d, [:continent :cont])[1]) !== nothing)
		val = uppercase(string(val))
		if     (startswith(val, "AF"))  BB[1] = "=AF"
		elseif (startswith(val, "AN"))  BB[1] = "=AN"
		elseif (startswith(val, "AS"))  BB[1] = "=AS"
		elseif (startswith(val, "EU"))  BB[1] = "=EU"
		elseif (startswith(val, "OC"))  BB[1] = "=OC"
		elseif (val[1] == 'N')  BB[1] = "=NA"
		elseif (val[1] == 'S')  BB[1] = "=SA"
		else   error("Unknown continent name")
		end
	elseif ((val = find_in_dict(d, [:ISO :iso])[1]) !== nothing)
		!isa(val, String) && error("argument to the ISO key must be a string with country codes")
		BB[1] = val
	end

	if ((val = find_in_dict(d, [:adjust :pad :extend :expand])[1]) !== nothing)
		if (isa(val, String) || isa(val, Number))  t = string(val)
		elseif (isa(val, Array{<:Real}) || isa(val, Tuple))
			t = join([@sprintf("%.15g/", Float64(x)) for x in val])
			t = rstrip(t, '/')		# and remove last '/'
		else
			error("Increments for limits must be a String, a Number, Array or Tuple")
		end
		BB[1] = (haskey(d, :adjust)) ? BB[1] * "+r" * t : BB[1] * "+R" * t
	end

	if (haskey(d, :unit))  BB[1] *= "+u" * string(d[:unit])[1]  end	# (e.g., -R-200/200/-300/300+uk)

	(BB[1] == "") && error("No, no, no. Nothing useful in the region named tuple arguments")
	return " -R" * BB[1]
end

# ---------------------------------------------------------------------------------------------------
function opt_R2num(opt_R::String)
	# Take a -R option string and convert it to numeric
	if (opt_R == "")  return nothing  end
	if (endswith(opt_R, "Rg"))  return [0.0, 360., -90., 90.]  end
	if (endswith(opt_R, "Rd"))  return [-180.0, 180., -90., 90.]  end
	if (findfirst("/", opt_R) !== nothing)
		isdiag = false
		if ((ind = findfirst("+r", opt_R)) !== nothing)		# Diagonal mode
			opt_R = opt_R[1:ind[1]-1];	isdiag = true		# Strip the "+r"
		end
		rs = split(opt_R, '/')
		limits = zeros(length(rs))
		fst = ((ind = findfirst("R", rs[1])) !== nothing) ? ind[1] : 0
		limits[1] = parse(Float64, rs[1][fst+1:end])
		for k = 2:length(rs)
			limits[k] = parse(Float64, rs[k])
		end
		if (isdiag)  limits[2], limits[4] = limits[4], limits[2]  end
	elseif (opt_R != " -R")		# One of those complicated -R forms. Just ask GMT the limits (but slow. It takes 0.2 s)
		kml = gmt("gmt2kml " * opt_R, [0 0])[1]
		limits = zeros(4)
		t = kml.text[28][12:end];	ind = findfirst("<", t)		# north
		limits[4] = parse(Float64, t[1:(ind[1]-1)])
		t = kml.text[29][12:end];	ind = findfirst("<", t)		# south
		limits[3] = parse(Float64, t[1:(ind[1]-1)])
		t = kml.text[30][11:end];	ind = findfirst("<", t)		# east
		limits[2] = parse(Float64, t[1:(ind[1]-1)])
		t = kml.text[31][11:end];	ind = findfirst("<", t)		# east
		limits[1] = parse(Float64, t[1:(ind[1]-1)])
	else
		limits = zeros(4)
	end
	return limits
end

# ---------------------------------------------------------------------------------------------------
function parse_JZ(d::Dict, cmd::String, del::Bool=true)
	symbs = [:JZ :Jz :zscale :zsize]
	(show_kwargs[1]) && return (print_kwarg_opts(symbs, "String | Number"), "")
	opt_J = "";		seek_JZ = true
	if ((val = find_in_dict(d, [:aspect3])[1]) !== nothing)
		o = scan_opt(cmd, "-J")
		(o[1] != 'X' || o[end] == 'd') &&  @warn("aspect3 works only in linear projections (and no geog), ignoring it.") 
		if (o[1] == 'X' && o[end] != 'd')
			opt_J = " -JZ" * split(o[2:end],'/')[1];		seek_JZ = false
			cmd *= opt_J
		end
	end
	if (seek_JZ)
		val, symb = find_in_dict(d, symbs, del)
		if (val !== nothing)
			opt_J = (symb == :JZ || symb == :zsize) ? " -JZ" * arg2str(val) : " -Jz" * arg2str(val)
			cmd *= opt_J
		end
	end
	return cmd, opt_J
end

# ---------------------------------------------------------------------------------------------------
function parse_J(d::Dict, cmd::String, default::String="", map::Bool=true, O::Bool=false, del::Bool=true)
	# Build the option -J string. Make it simply -J if in overlay mode (-O) and no new -J is fished here
	# Default to 12c if no size is provided.
	# If MAP == false, do not try to append a fig size

	(show_kwargs[1]) && return (print_kwarg_opts([:J :proj :projection], "NamedTuple | String"), "")

	opt_J = [""];		mnemo = false
	if ((val = find_in_dict(d, [:J :proj :projection], del)[1]) !== nothing)
		isa(val, Dict) && (val = dict2nt(val))
		opt_J[1], mnemo = build_opt_J(val)
	elseif (IamModern[1] && ((val = find_in_dict(d, [:figscale :fig_scale :scale :figsize :fig_size], del)[1]) === nothing))
		# Subplots do not rely in the classic default mechanism
		return cmd, ""
	end
	CTRL.proj_linear[1] = (length(opt_J[1]) >= 4 && opt_J[1][4] != 'X' && opt_J[1][4] != 'x' && opt_J[1][4] != 'Q' && opt_J[1][4] != 'q') ? false : true
	if (!map && opt_J[1] != "")  return cmd * opt_J[1], opt_J[1]  end

	if (O && opt_J[1] == "")  opt_J[1] = " -J"  end

	if (!O)
		if (default == "guess" && opt_J[1] == "")
			opt_J[1] = guess_proj(CTRL.limits[1:2], CTRL.limits[3:4]);	mnemo = true	# To force append fig size
		end
		if (opt_J[1] == "")  opt_J[1] = " -JX"  end
		# If only the projection but no size, try to get it from the kwargs.
		if ((s = helper_append_figsize(d, opt_J[1], O)) != "")		# Takes care of both fig scales and fig sizes
			opt_J[1] = s
		elseif (default != "" && opt_J[1] == " -JX")
			opt_J[1] = IamSubplot[1] ? " -JX?" : (default != "guess" ? default : opt_J[1]) 	# -JX was a working default
		elseif (occursin("+width=", opt_J[1]))		# OK, a proj4 string, don't touch it. Size already in.
		elseif (occursin("+proj", opt_J[1]))		# A proj4 string but no size info. Use default size
			opt_J[1] *= "+width=" * split(def_fig_size, '/')[1]
		elseif (mnemo)							# Proj name was obtained from a name mnemonic and no size. So use default
			opt_J[1] = append_figsize(d, opt_J[1])
		elseif (!isnumeric(opt_J[1][end]) && (length(opt_J[1]) < 6 || (isletter(opt_J[1][5]) && !isnumeric(opt_J[1][6]))) )
			if (!IamSubplot[1])
				if ( ((val = find_in_dict(d, [:aspect])[1]) !== nothing) || haskey(d, :aspect3))
					opt_J[1] *= split(def_fig_size, '/')[1] * "/0"
				else
					opt_J[1] = (!startswith(opt_J[1], " -JX")) ? append_figsize(d, opt_J[1]) : opt_J[1] * def_fig_size
				end
			elseif (!occursin("?", opt_J[1]))	# If we dont have one ? for size/scale already
				opt_J[1] *= "/?"
			end
		#elseif (length(opt_J[1]) == 4 || (length(opt_J[1]) >= 5 && isletter(opt_J[1][5])))
			#if (length(opt_J[1][1]) < 6 || !isnumeric(opt_J[1][6]))
				#opt_J[1] *= def_fig_size
			#end
		end
	else										# For when a new size is entered in a middle of a script
		if ((s = helper_append_figsize(d, opt_J[1], O)) != "")  opt_J[1] = s  end
	end
	CTRL.proj_linear[1] = (length(opt_J[1]) >= 4 && opt_J[1][4] != 'X' && opt_J[1][4] != 'x' && opt_J[1][4] != 'Q' && opt_J[1][4] != 'q') ? false : true
	cmd *= opt_J[1]
	return cmd, opt_J[1]
end

function helper_append_figsize(d::Dict, opt_J::String, O::Bool)::String
	val_, symb = find_in_dict(d, [:figscale :fig_scale :scale :figsize :fig_size])
	if (val_ === nothing)  return ""  end
	val::String = arg2str(val_)
	if (occursin("scale", arg2str(symb)))		# We have a fig SCALE request
		if     (IamSubplot[1] && val == "auto")       val = "?"
		elseif (IamSubplot[1] && val == "auto,auto")  val = "?/?"
		end
		if (opt_J == " -JX")
			val = check_axesswap(d, val)
			isletter(val[1]) ? opt_J = " -J" * val : opt_J = " -Jx" * val		# FRAGILE
		elseif (O && opt_J == " -J")  error("In Overlay mode you cannot change a fig scale and NOT repeat the projection")
		else                          opt_J = append_figsize(d, opt_J, val, true)
		end
	else										# A fig SIZE request
		if (haskey(d, :units))  val *= d[:units][1]  end
		if (occursin("+proj", opt_J)) opt_J *= "+width=" * val
		else                          opt_J = append_figsize(d, opt_J, val)
		end
	end
	return opt_J
end

function append_figsize(d::Dict, opt_J::String, width::String="", scale::Bool=false)::String
	# Appending either a fig width or fig scale depending on what projection.
	# Sometimes we need to separate with a '/' others not. If WIDTH == "" we
	# use the DEF_FIG_SIZE, otherwise use WIDTH that can be a size or a scale.
	if (width == "")
		width = (IamSubplot[1]) ? "?" : split(def_fig_size, '/')[1]		# In subplot "?" is auto width
	elseif (IamSubplot[1] && (width == "auto" || width == "auto,auto"))	# In subplot one can say figsize="auto" or figsize="auto,auto"
		width = (width == "auto") ? "?" : "?/?"
	elseif ( ((val = find_in_dict(d, [:aspect])[1]) !== nothing) || haskey(d, :aspect3))
		(occursin("/", width)) && @warn("Ignoring the 'aspect' request because fig's Width and Height already provided.")
		if !occursin("/", width)  width *= "/0"  end
	end

	slash = "";		de = ""
	if (opt_J[end] == 'd')  opt_J = opt_J[1:end-1];		de = "d"  end
	if (isnumeric(opt_J[end]) && ~startswith(opt_J, " -JXp"))    slash = "/";#opt_J *= "/" * width
	else
		if (occursin("Cyl_", opt_J) || occursin("Poly", opt_J))  slash = "/";#opt_J *= "/" * width
		elseif (startswith(opt_J, " -JU") && length(opt_J) > 4)  slash = "/";#opt_J *= "/" * width
		else								# Must parse for logx, logy, loglog, etc
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
		end
	end
	width = check_axesswap(d, width)
	opt_J *= slash * width * de
	if (scale)  opt_J = opt_J[1:3] * lowercase(opt_J[4]) * opt_J[5:end]  end 		# Turn " -JX" to " -Jx"
	return opt_J
end

function check_axesswap(d::Dict, width::AbstractString)
	# Deal with the case that we want to invert the axis sense
	# axesswap(x=true, y=true) OR  axesswap("x", :y) OR axesswap(:xy)
	if (width == "" || (val = find_in_dict(d, [:inverse_axes :axesswap :axes_swap])[1]) === nothing)
		return width
	end

	swap_x = false;		swap_y = false;
	if isa(val, Dict)  val = dict2nt(val)  end
	if (isa(val, NamedTuple))
		for k in keys(val)
			if     (k == :x)  swap_x = true
			elseif (k == :y)  swap_y = true
			elseif (k == :xy) swap_x = true;  swap_y = true
			end
		end
	elseif (isa(val, Tuple))
		for k in val
			if     (string(k) == "x")  swap_x = true
			elseif (string(k) == "y")  swap_y = true
			elseif (string(k) == "xy") swap_x = true;  swap_y = true
			end
		end
	elseif (isa(val, String) || isa(val, Symbol))
		if     (string(val) == "x")  swap_x = true
		elseif (string(val) == "y")  swap_y = true
		elseif (string(val) == "xy") swap_x = true;  swap_y = true
		end
	end

	if (occursin("/", width))
		sizes = split(width,"/")
		if (swap_x) sizes[1] = "-" * sizes[1]  end
		if (swap_y) sizes[2] = "-" * sizes[2]  end
		width = sizes[1] * "/" * sizes[2]
	else
		width = "-" * width
	end
	if (occursin("?-", width))  width = replace(width, "?-" => "-?")  end 	# It may, from subplots
	return width
end

function build_opt_J(Val)::Tuple{String, Bool}
	out = "";		mnemo = false
	if (isa(Val, String) || isa(Val, Symbol))
		if (string(Val) == "guess")
			out, mnemo = guess_proj(CTRL.limits[1:2], CTRL.limits[3:4]), true
		else
			prj, mnemo = parse_proj(string(Val))
			out = " -J" * prj
		end
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

function parse_proj(p::String)
	# See "p" if is a string with a projection name. If yes, convert it into the corresponding -J syntax
	if (p == "")  return p,false  end
	if (p[1] == '+' || startswith(p, "epsg") || startswith(p, "EPSG") || occursin('/', p) || length(p) < 3)
		p = replace(p, " " => "")		# Remove the spaces from proj4 strings
		return p,false
	end
	out = [""];
	s = lowercase(p);		mnemo = true	# True when the projection name used one of the below mnemonics
	if     (s == "aea"   || s == "albers")                 out[1] = "B0/0"
	elseif (s == "cea"   || s == "cylindricalequalarea")   out[1] = "Y0/0"
	elseif (s == "laea"  || s == "lambertazimuthal")       out[1] = "A0/0"
	elseif (s == "lcc"   || s == "lambertconic")           out[1] = "L0/0"
	elseif (s == "aeqd"  || s == "azimuthalequidistant")   out[1] = "E0/0"
	elseif (s == "eqdc"  || s == "conicequidistant")       out[1] = "D0/90"
	elseif (s == "tmerc" || s == "transversemercator")     out[1] = "T0"
	elseif (s == "eqc"   || startswith(s, "plat") || startswith(s, "equidist") || startswith(s, "equirect"))  out[1] = "Q"
	elseif (s == "eck4"  || s == "eckertiv")               out[1] = "Kf"
	elseif (s == "eck6"  || s == "eckertvi")               out[1] = "Ks"
	elseif (s == "omerc" || s == "obliquemerc1")           out[1] = "Oa"
	elseif (s == "omerc2"|| s == "obliquemerc2")           out[1] = "Ob"
	elseif (s == "omercp"|| s == "obliquemerc3")           out[1] = "Oc"
	elseif (startswith(s, "cyl_") || startswith(s, "cylindricalster"))  out[1] = "Cyl_stere"
	elseif (startswith(s, "cass"))   out[1] = "C0/0"
	elseif (startswith(s, "geo"))    out[1] = "Xd"		# Linear geogs
	elseif (startswith(s, "gnom"))   out[1] = "F0/0"
	elseif (startswith(s, "ham"))    out[1] = "H"
	elseif (startswith(s, "lin"))    out[1] = "X"
	elseif (startswith(s, "logx"))   out[1] = "Xlx"
	elseif (startswith(s, "logy"))   out[1] = "Xly"
	elseif (startswith(s, "loglog")) out[1] = "Xll"
	elseif (startswith(s, "powx"))   v = split(s, ',');	length(v) == 2 ? out[1] = "Xpx" * v[2] : out[1] = "Xpx"
	elseif (startswith(s, "powy"))   v = split(s, ',');	length(v) == 2 ? out[1] = "Xpy" * v[2] : out[1] = "Xpy"
	elseif (startswith(s, "Time"))   out[1] = "XTx"
	elseif (startswith(s, "time"))   out[1] = "Xtx"
	elseif (startswith(s, "merc"))   out[1] = "M"
	elseif (startswith(s, "mil"))    out[1] = "J"
	elseif (startswith(s, "mol"))    out[1] = "W"
	elseif (startswith(s, "ortho"))  out[1] = "G0/0"
	elseif (startswith(s, "poly"))   out[1] = "Poly"
	elseif (s == "polar")            out[1] = "P"
	elseif (s == "polar_azim")       out[1] = "Pa"
	elseif (startswith(s, "robin"))  out[1] = "N"
	elseif (startswith(s, "stere"))  out[1] = "S0/90"
	elseif (startswith(s, "sinu"))   out[1] = "I"
	elseif (startswith(s, "utm"))    out[1] = "U" * s[4:end]
	elseif (startswith(s, "vand"))   out[1] = "V"
	elseif (startswith(s, "win"))    out[1] = "R"
	else   out[1] = p;		mnemo = false
	end
	return out[1], mnemo
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
		elseif (isa(val, Number))  center = sprintf("%.12g", val)
		elseif (isa(val, Array) || isa(val, Tuple) && length(val) == 2)
			if (isa(val, Array))  center = sprintf("%.12g/%.12g", val[1], val[2])
			else		# Accept also strings in tuple (Needed for movie)
				center  = (isa(val[1], String)) ? val[1] * "/" : sprintf("%.12g/", val[1])
				center *= (isa(val[2], String)) ? val[2] : sprintf("%.12g", val[2])
			end
		end
	end

	if (center != "" && (val = find_in_dict(d, [:horizon])[1]) !== nothing)  center = string(center, '/',val)  end

	parallels = ""
	if ((val = find_in_dict(d, [:parallel :parallels])[1]) !== nothing)
		if     (isa(val, String))  parallels = "/" * val
		elseif (isa(val, Number))  parallels = sprintf("/%.12g", val)
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
function guess_proj(lonlim, latlim)
	# Select a projection based on map limits. Follows closely the Matlab behavior

	if (lonlim[1] == 0.0 && lonlim[2] == 0.0 && latlim[1] == 0.0 && latlim[2] == 0.0)
		@warn("Numeric values of 'CTRL.limits' not available. Cannot use the 'guess' option (Must specify a projection)")
		return(" -JX")
	end
	if (latlim == [-90, 90] && (lonlim[2]-lonlim[1]) > 359.99)	# Whole Earth
		proj = string(" -JN", sum(lonlim)/2)		# Robinson
	elseif (maximum(abs.(latlim)) < 30)
		proj = string(" -JM")						# Mercator
	elseif abs(latlim[2]-latlim[1]) <= 90 && abs(sum(latlim)) > 20 && maximum(abs.(latlim)) < 90
		# doesn't extend to the pole, not straddling equator
		parallels = latlim .+ diff(latlim) .* [1/6 -1/6]
		proj = string(" -JD", sum(lonlim)/2, '/', sum(latlim)/2, '/', parallels[1], '/', parallels[2])	# eqdc
	elseif abs(latlim[2]-latlim[1]) < 85 && maximum(abs.(latlim)) < 90	# doesn't extend to the pole, not straddling equator
		proj = string(" -JI", sum(lonlim)/2)							# Sinusoidal
	elseif (maximum(latlim) == 90 && minimum(latlim) >= 75)
		proj = string(" -JS", sum(lonlim)/2, "/90")						# General Stereographic - North Pole
	elseif (minimum(latlim) == -90 && maximum(latlim) <= -75)
		proj = string(" -JS", sum(lonlim)/2, "/-90")					# General Stereographic - South Pole
	elseif maximum(abs.(latlim)) == 90 && abs(lonlim[2]-lonlim[1]) < 180
		proj = string(" -JPoly", sum(lonlim)/2, '/', sum(latlim)/2)		# Polyconic
	elseif maximum(abs.(latlim)) == 90 && abs(latlim[2]-latlim[1]) < 90
		proj = string(" -JE", sum(lonlim)/2, '/', 90 * sign(latlim[2]))	# azimuthalequidistant
	else
		proj = string(" -JJ", sum(lonlim)/2)							# Miller
	end
end

# ---------------------------------------------------------------------------------------------------
function parse_B(d::Dict, cmd::String, _opt_B::String="", del::Bool=true)::Tuple{String,String}

	(show_kwargs[1]) && return (print_kwarg_opts([:B :frame :axis :axes :xaxis :yaxis :zaxis :axis2 :xaxis2 :yaxis2], "NamedTuple | String"), "")

	def_fig_axes_  = (IamModern[1]) ? "" : def_fig_axes		# def_fig_axes is a global const
	def_fig_axes3_ = (IamModern[1]) ? "" : def_fig_axes3	# def_fig_axes is a global const

	opt_B = [_opt_B]

	# These four are aliases
	extra_parse = true;		have_a_none = false
	if ((val = find_in_dict(d, [:B :frame :axis :axes], del)[1]) !== nothing)
		isa(val, Dict) && (val = dict2nt(val))
		if (isa(val, String) || isa(val, Symbol))
			val = string(val)					# In case it was a symbol
			if (val == "none")					# User explicitly said NO AXES
				if     (haskey(d, :xlabel))  val = "-BS";	have_a_none = true		# Unless labels are wanted, but
				elseif (haskey(d, :ylabel))  val = "-BW";	have_a_none = true		# GMT Bug forces using tricks
				else   return cmd, ""
				end
			elseif (val == "noannot" || val == "bare")
				return cmd * " -B0", " -B0"
			elseif (val == "same")				# User explicitly said "Same as previous -B"
				return cmd * " -B", " -B"
			elseif (startswith(val, "auto"))
				is3D = false
				if     (occursin("XYZg", val)) val = " -Bafg -Bzafg -B+" * ((GMTver <= v"6.1") ? "b" : "w");  is3D = true
				elseif (occursin("XYZ", val))  val = def_fig_axes3;		is3D = true
				elseif (occursin("XYg", val))  val = " -Bafg -BWSen"
				elseif (occursin("XY", val))   val = def_fig_axes
				elseif (occursin("LB", val))   val = " -Baf -BLB"
				elseif (occursin("L",  val))   val = " -Baf -BL"
				elseif (occursin("R",  val))   val = " -Baf -BR"
				elseif (occursin("B",  val))   val = " -Baf -BB"
				elseif (occursin("Xg", val))   val = " -Bafg -BwSen"
				elseif (occursin("X",  val))   val = " -Baf -BwSen"
				elseif (occursin("Yg", val))   val = " -Bafg -BWsen"
				elseif (occursin("Y",  val))   val = " -Baf -BWsen"
				elseif (val == "auto")         val = def_fig_axes		# 2D case
				end
				cmd = guess_WESN(d, cmd)
			elseif (length(val) <= 5 && !occursin(" ", val) && occursin(r"[WESNwesnzZ]", val))
				val *= " af"		# To prevent that setting B=:WSen removes all annots
			end
		end
		if (isa(val, NamedTuple)) opt_B[1] = axis(val);	extra_parse = false
		else                      opt_B[1] = string(val)
		end
	end

	# Let the :title and x|y_label be given on main kwarg list. Risky if used with NamedTuples way.
	t = ""		# Use the trick to replace blanks by some utf8 char and undo it in extra_parse
	if (haskey(d, :title))   t *= "+t"   * replace(str_with_blancs(d[:title]), ' '=>'\U00AF');   delete!(d, :title);	end
	if (haskey(d, :xlabel))  t *= " x+l" * replace(str_with_blancs(d[:xlabel]),' '=>'\U00AF');   delete!(d, :xlabel);	end
	if (haskey(d, :ylabel))  t *= " y+l" * replace(str_with_blancs(d[:ylabel]),' '=>'\U00AF');   delete!(d, :ylabel);	end
	if (haskey(d, :zlabel))  t *= " z+l" * replace(str_with_blancs(d[:zlabel]),' '=>'\U00AF');   delete!(d, :zlabel);	end
	if (t != "")
		if (opt_B[1] == "" && (val = find_in_dict(d, [:xaxis :yaxis :zaxis :xticks :yticks :zticks], false)[1] === nothing))
			opt_B[1] = def_fig_axes_
		elseif (opt_B[1] != "")			# Because  findlast("-B","") Errors!!!!!
			if !( ((ind = findlast("-B",opt_B[1])) !== nothing || (ind = findlast(" ",opt_B[1])) !== nothing) &&
				  (occursin(r"[WESNwesntlbu+g+o]",opt_B[1][ind[1]:end])) )
				t = " " * t;		# Do not glue, for example, -Bg with :title
			end
		end
		opt_B[1] *= t;
		extra_parse = true
	end

	# These are not and we can have one or all of them. NamedTuples are dealt at the end
	for symb in [:xaxis :yaxis :zaxis :axis2 :xaxis2 :yaxis2]
		if (haskey(d, symb) && !isa(d[symb], NamedTuple) && !isa(d[symb], Dict))
			opt_B[1] = string(d[symb], " ", opt_B[1])
		end
	end

	if (extra_parse && (opt_B[1] != def_fig_axes && opt_B[1] != def_fig_axes3))
		# This is old code that takes care to break a string in tokens and prefix with a -B to each token
		tok = Vector{String}(undef, 10)
		k = 1;		r = opt_B[1];		found = false
		while (r != "")
			tok[k], r = GMT.strtok(r)
			tok[k] = replace(tok[k], '\U00AF'=>' ')
			if (!occursin("-B", tok[k])) tok[k] = " -B" * tok[k]
			else                         tok[k] = " " * tok[k]
			end
			k = k + 1
		end
		# Rebuild the B option string
		opt_B[1] = ""
		for n = 1:k-1
			opt_B[1] *= tok[n]
		end
	end

	# We can have one or all of them. Deal separatelly here to allow way code to keep working
	this_opt_B = "";
	for symb in [:yaxis2 :xaxis2 :axis2 :zaxis :yaxis :xaxis]
		if (haskey(d, symb) && (isa(d[symb], NamedTuple) || isa(d[symb], Dict)))
			if (isa(d[symb], Dict))  d[symb] = dict2nt(d[symb])  end
			if     (symb == :axis2)   this_opt_B = axis(d[symb], secondary=true);		delete!(d, symb)
			elseif (symb == :xaxis)   this_opt_B = axis(d[symb], x=true) * this_opt_B;	delete!(d, symb)
			elseif (symb == :xaxis2)  this_opt_B = axis(d[symb], x=true, secondary=true) * this_opt_B;	delete!(d, symb)
			elseif (symb == :yaxis)   this_opt_B = axis(d[symb], y=true) * this_opt_B;	delete!(d, symb)
			elseif (symb == :yaxis2)  this_opt_B = axis(d[symb], y=true, secondary=true) * this_opt_B;	delete!(d, symb)
			elseif (symb == :zaxis)   this_opt_B = axis(d[symb], z=true) * this_opt_B;	delete!(d, symb)
			end
		end
	end
	# These can come up outside of an ?axis tuple, so need to be sekeed too.
	for symb in [:xticks :yticks :zticks]
		if (haskey(d, symb))
			if     (symb == :xticks)  this_opt_B = " -Bpxc" * xticks(d[symb]) * this_opt_B;	delete!(d, symb)
			elseif (symb == :yticks)  this_opt_B = " -Bpyc" * yticks(d[symb]) * this_opt_B;	delete!(d, symb)
			elseif (symb == :zticks)  this_opt_B = " -Bpzc" * zticks(d[symb]) * this_opt_B;	delete!(d, symb)
			end
		end
	end

	if (opt_B[1] != def_fig_axes_ && opt_B[1] != def_fig_axes3_)  opt_B[1] = this_opt_B * opt_B[1]
	elseif (this_opt_B != "")  opt_B[1] = this_opt_B
	end
	(have_a_none) && (opt_B[1] *= " --MAP_FRAME_PEN=0.001,white@100")	# Need to resort to this sad trick

	return cmd * opt_B[1], opt_B[1]
end

# ---------------------------------------------------------------------------------------------------
function guess_WESN(d::Dict, cmd::String)
	# For automatic -B option settings add MAP_FRAME_AXES option such that only the two closest
	# axes will be annotated. For now this function is only used in 3D modules.
	if ((val = find_in_dict(d, [:p :view :perspective], false)[1]) !== nothing && (isa(val, Tuple) || isa(val, String)))
		if (isa(val, String))					# imshows sends -p already digested. Must reverse
			_val = tryparse(Float64, split(val, "/")[1])
			quadrant = mod(div(_val, 90), 4)	# But since the angle is azim those are not the trig quadrants
		else
			quadrant = mod(div(val[1], 90), 4)
		end
		if     (quadrant == 0)  axs = "wsNEZ"	# Trig first quadrant
		elseif (quadrant == 1)  axs = "wSnEZ"	# Trig fourth quadrant
		elseif (quadrant == 2)  axs = "WSneZ"	# Trig third quadrant
		else   axs = "WseNZ"	# Trig second quadrant
		end
		cmd *= " --MAP_FRAME_AXES=" * axs
	end
	cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_BJR(d::Dict, cmd::String, caller::String, O::Bool, defaultJ::String="", del::Bool=true)
	# Join these three in one function. CALLER is non-empty when module is called by plot()
	cmd, opt_R = parse_R(d, cmd, O, del)
	cmd, opt_J = parse_J(d, cmd, defaultJ, true, O, del)

	def_fig_axes_ = (IamModern[1]) ? "" : def_fig_axes	# def_fig_axes is a global const

	if (caller != "" && occursin("-JX", opt_J))		# e.g. plot() sets 'caller'
		if (occursin("3", caller) || caller == "grdview")
			def_fig_axes3_ = (IamModern[1]) ? "" : def_fig_axes3
			cmd, opt_B = parse_B(d, cmd, (O ? "" : def_fig_axes3_), del)
		else
			xx = (O ? "" : caller != "ternary" ? def_fig_axes_ : string(split(def_fig_axes_)[1]))
			cmd, opt_B = parse_B(d, cmd, xx, del)	# For overlays, default is no axes
		end
	else
		cmd, opt_B = parse_B(d, cmd, (O ? "" : def_fig_axes_), del)
	end
	return cmd, opt_B, opt_J, opt_R
end

# ---------------------------------------------------------------------------------------------------
function parse_F(d::Dict, cmd::String)::String
	cmd = add_opt(d, cmd, 'F', [:F :box], (clearance="+c", fill=("+g", add_opt_fill), inner="+i",
	                                       pen=("+p", add_opt_pen), rounded="+r", shaded=("+s", arg2str)) )
end

# ---------------------------------------------------------------------------------------------------
function parse_Td(d::Dict, cmd::String)::String
	cmd = parse_type_anchor(d, cmd, [:Td :rose],
							(map=("g", nothing, 1), outside=("J", nothing, 1), inside=("j", nothing, 1), norm=("n", nothing, 1), paper=("x", nothing, 1), anchor=("", arg2str, 2), width="+w", justify="+j", fancy="+f", labels="+l", label="+l", offset=("+o", arg2str)), 'j')
end
function parse_Tm(d::Dict, cmd::String)::String
	cmd = parse_type_anchor(d, cmd, [:Tm :compass],
	                        (map=("g", nothing, 1), outside=("J", nothing, 1), inside=("j", nothing, 1), norm=("n", nothing, 1), paper=("x", nothing, 1), anchor=("", arg2str, 2), width="+w", dec="+d", justify="+j", rose_primary=("+i", add_opt_pen), rose_secondary=("+p", add_opt_pen), labels="+l", label="+l", annot=("+t", arg2str), offset=("+o", arg2str)), 'j')
end
function parse_L(d::Dict, cmd::String)::String
	cmd = parse_type_anchor(d, cmd, [:L :map_scale],
	                        (map=("g", nothing, 1), outside=("J", nothing, 1), inside=("j", nothing, 1), norm=("n", nothing, 1), paper=("x", nothing, 1), anchor=("", arg2str, 2), scale_at_lat="+c", length="+w", width="+w", align="+a1", justify="+j", fancy="_+f", label="+l", offset=("+o", arg2str), units="_+u", vertical="_+v"), 'j')
end

# ---------------------------------------------------------------------------------------------------
#parse_type_anchor(::String, ::Dict) = parse_type_anchor(Dict(), "", [:a], (a=0,), 'a')
function parse_type_anchor(d::Dict, cmd::String, symbs::Array{Symbol}, mapa::NamedTuple, def_CS::Char, del::Bool=true)
	# SYMBS: [:D :pos :position] | ...
	# MAPA is the NamedTuple of suboptions
	# def_CS is the default "Coordinate system". Colorbar has 'J', logo has 'g', many have 'j'
	(show_kwargs[1]) && return print_kwarg_opts(symbs, mapa)	# Just print the kwargs of this option call
	opt = add_opt(d, "", "", symbs, mapa, del)
	if (opt != "" && opt[1] != 'j' && opt[1] != 'J' && opt[1] != 'g' && opt[1] != 'n' && opt[1] != 'x')
		opt = def_CS * opt
	end
	if (opt != "")  cmd *= " -" * string(symbs[1]) * opt  end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_UXY(cmd::String, d::Dict, aliases, opt::Char)::String
	# Parse the global -U, -X, -Y options. Return CMD same as input if no option OPT in args
	# ALIASES: [:X :x_off :x_offset] (same for Y) or [:U :time_stamp :timestamp]
	if ((val = find_in_dict(d, aliases, true)[1]) !== nothing)
		cmd = string(cmd, " -", opt, val)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_V(d::Dict, cmd::String)::String
	# Parse the global -V option. Return CMD same as input if no -V option in args
	if ((val = find_in_dict(d, [:V :verbose], true)[1]) !== nothing)
		if (isa(val, Bool) && val) cmd *= " -V"
		else                       cmd *= " -V" * arg2str(val)
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_V_params(d::Dict, cmd::String)
	# Parse the global -V option and the --PAR=val. Return CMD same as input if no options in args
	cmd = parse_V(d, cmd)
	return parse_params(d, cmd)
end

# ---------------------------------------------------------------------------------------------------
function parse_UVXY(d::Dict, cmd::String)
	cmd = parse_V(d, cmd)
	cmd = parse_UXY(cmd, d, [:X :xoff :x_off :x_offset :xshift], 'X')
	cmd = parse_UXY(cmd, d, [:Y :yoff :y_off :y_offset :yshift], 'Y')
	cmd = parse_UXY(cmd, d, [:U :time_stamp :timestamp], 'U')
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_a(d::Dict, cmd::String)
	# Parse the global -a option. Return CMD same as input if no -a option in args
	parse_helper(cmd, d, [:a :aspatial], " -a")
end

# ---------------------------------------------------------------------------------------------------
function parse_b(d::Dict, cmd::String, symbs::Array{Symbol}=[:b :binary])
	# Parse the global -b option. Return CMD same as input if no -b option in args
	cmd_ = add_opt(d, "", symbs[1], symbs, 
	               (ncols=("", arg2str, 1), type=("", data_type, 2), swapp_bytes="_w", little_endian="_+l", big_endian="+b"))
	return cmd * cmd_, cmd_
end
parse_bi(d::Dict, cmd::String) = parse_b(d, cmd, [:bi :binary_in])
parse_bo(d::Dict, cmd::String) = parse_b(d, cmd, [:bo :binary_out])
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
function parse_c(d::Dict, cmd::String)::Tuple{String, String}
	# Most of the work here is because GMT counts from 0 but here we count from 1, so conversions needed
	opt_val::String = ""
	if ((val = find_in_dict(d, [:c :panel])[1]) !== nothing)
		if (isa(val, Tuple) || isa(val, Array{<:Number}) || isa(val, Integer))
			opt_val = arg2str(val .- 1, ',')
		elseif (isa(val, String) || isa(val, Symbol))
			_val::String = string(val)		# In case it was a symbol
			if ((ind = findfirst(",", _val)) !== nothing)	# Shit, user really likes complicating
				opt_val = string(parse(Int, val[1:ind[1]-1]) - 1, ',', parse(Int, _val[ind[1]+1:end]) - 1)
			elseif (_val != "" && _val != "next")
				opt_val = string(parse(Int, _val) - 1)
			end
		end
		cmd *= " -c" * opt_val
	end
	return cmd, opt_val
end

# ---------------------------------------------------------------------------------------------------
function parse_d(d::Dict, cmd::String, symbs::Array{Symbol}=[:d :nodata])
	(show_kwargs[1]) && return (print_kwarg_opts(symbs, "$(symbs[2])=val"),"")
	parse_helper(cmd, d, [:d :nodata], " -d")
end
parse_di(d::Dict, cmd::String) = parse_d(d, cmd, [:di :nodata_in])
parse_do(d::Dict, cmd::String) = parse_d(d, cmd, [:do :nodata_out])
parse_e(d::Dict, cmd::String) = parse_helper(cmd, d, [:e :pattern], " -e")
parse_f(d::Dict, cmd::String) = parse_helper(cmd, d, [:f :colinfo :coltypes], " -f")
parse_g(d::Dict, cmd::String) = parse_helper(cmd, d, [:g :gap], " -g")
parse_h(d::Dict, cmd::String) = parse_helper(cmd, d, [:h :header], " -h")
parse_i(d::Dict, cmd::String) = parse_helper(cmd, d, [:i :incols :incol], " -i", ',')
parse_j(d::Dict, cmd::String) = parse_helper(cmd, d, [:j :spheric_dist :spherical_dist], " -j")

# ---------------------------------------------------------------------------------
function parse_l(d::Dict, cmd::String)
	cmd_ = add_opt(d, "", 'l', [:l :legend],
		(text=("", arg2str, 1), hline=("+D", add_opt_pen), vspace="+G", header="+H", line_text="+L", n_cols="+N", ncols="+N", ssize="+S", start_vline=("+V", add_opt_pen), end_vline=("+v", add_opt_pen), font=("+f", font), fill="+g", justify="+j", offset="+o", frame_pen=("+p", add_opt_pen), width="+w", scale="+x"), false)
	# Now make sure blanks in legen text are wrapped in ""
	if ((ind = findfirst("+", cmd_)) !== nothing)
		cmd_ = " -l" * str_with_blancs(cmd_[4:ind[1]-1]) * cmd_[ind[1]:end]
	elseif (cmd_ != "")
		cmd_ = " -l" * str_with_blancs(cmd_[4:end])
	end
	if (IamModern[1])  cmd *= cmd_  end		# l option is only available in modern mode
	return cmd, cmd_
end

# ---------------------------------------------------------------------------------
function parse_n(d::Dict, cmd::String, gmtcompat::Bool=false)
	# Parse the global -n option. Return CMD same as input if no -n option in args
	# The GMTCOMPAT arg is used to reverse the default aliasing in GMT, which is ON by default
	# However, practise has shown that this makes projecting images significantly slower with not clear benefits
	cmd_ = add_opt(d, "", 'n', [:n :interp :interpol], 
				   (B_spline=("b", nothing, 1), bicubic=("c", nothing, 1), bilinear=("l", nothing, 1), near_neighbor=("n", nothing, 1), aliasing="_+a", antialiasing="_-a", bc="+b", clipz="_+c", threshold="+t"))
	# Some gymnics to make aliasing de default (contrary to GMT default). Use antialiasing=Any to revert this.
	if (!gmtcompat)
		if (cmd_ != "" && !occursin("+a", cmd_)) 
			cmd_ = (occursin("-a", cmd_)) ? replace(cmd_, "-a" => "") : cmd_ * "+a"
			(cmd_ == " -n") && (cmd_ = "")	# Happens when only n="-a" was transmitted.
		elseif (cmd_ == "")
			cmd_ *= " -n+a"		# Default to no-aliasing. Antialising on map projection is very slow and often not needed.
		end
	end
	return cmd * cmd_, cmd_
end

# ---------------------------------------------------------------------------------
parse_o(d::Dict, cmd::String) = parse_helper(cmd, d, [:o :outcols :outcol], " -o", ',')
parse_p(d::Dict, cmd::String) = parse_helper(cmd, d, [:p :view :perspective], " -p")

# ---------------------------------------------------------------------------------
function parse_q(d::Dict, cmd::String)
	parse_helper(cmd, d, [:q :inrow :inrows], " -q")
	parse_helper(cmd, d, [:qo :outrow :outrows], " -qo")
end

# ---------------------------------------------------------------------------------------------------
# Parse the global -s option. Return CMD same as input if no -s option in args
parse_s(d::Dict, cmd::String) = parse_helper(cmd, d, [:s :skip_NaN], " -s")

# ---------------------------------------------------------------------------------------------------
# Parse the global -: option. Return CMD same as input if no -: option in args
# But because we can't have a variable called ':' we use only the aliases
parse_swap_xy(d::Dict, cmd::String) = parse_helper(cmd, d, [:yx :swap_xy], " -:")

# ---------------------------------------------------------------------------------------------------
function parse_r(d::Dict, cmd::String)
	# Parse the global -r option. Return CMD same as input if no -r option in args
	parse_helper(cmd, d, [:r :reg :registration], " -r")
end

# ---------------------------------------------------------------------------------------------------
# Parse the global -x option. Return CMD same as input if no -x option in args
parse_x(d::Dict, cmd::String) = parse_helper(cmd, d, [:x :cores :n_threads], " -x")

# ---------------------------------------------------------------------------------------------------
function parse_t(d::Dict, cmd::String)
	opt_val = ""
	if ((val = find_in_dict(d, [:t :alpha :transparency])[1]) !== nothing)
		t = (isa(val, String)) ? parse(Float32, val) : val
		if (t < 1) t *= 100  end
		opt_val = string(" -t", t)
		cmd *= opt_val
	end
	return cmd, opt_val
end

# ---------------------------------------------------------------------------------------------------
function parse_write(d::Dict, cmd::String)::String
	if ((val = find_in_dict(d, [:write :savefile :|>], true)[1]) !== nothing)
		cmd *=  " > " * val
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_append(d::Dict, cmd::String)::String
	if ((val = find_in_dict(d, [:append], true)[1]) !== nothing)
		cmd *=  " >> " * val
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_helper(cmd::String, d::Dict, symbs, opt::String, sep='/')
	# Helper function to the parse_?() global options.
	(show_kwargs[1]) && return (print_kwarg_opts(symbs, "(Common option not yet expanded)"),"")
	opt_val = ""
	if ((val = find_in_dict(d, symbs, true)[1]) !== nothing)
		opt_val = opt * arg2str(val, sep)
		cmd *= opt_val
	end
	return cmd, opt_val
end

# ---------------------------------------------------------------------------------------------------
function parse_common_opts(d::Dict, cmd::String, opts::Array{<:Symbol}, first::Bool=true)
	(show_kwargs[1]) && return (print_kwarg_opts(opts, "(Common options)"),"")	# Just print the options
	opt_p = nothing;	o = ""
	for opt in opts
		if     (opt == :a)  cmd, o = parse_a(d, cmd)
		elseif (opt == :b)  cmd, o = parse_b(d, cmd)
		elseif (opt == :c)  cmd, o = parse_c(d, cmd)
		elseif (opt == :bi) cmd, o = parse_bi(d, cmd)
		elseif (opt == :bo) cmd, o = parse_bo(d, cmd)
		elseif (opt == :d)  cmd, o = parse_d(d, cmd)
		elseif (opt == :di) cmd, o = parse_di(d, cmd)
		elseif (opt == :do) cmd, o = parse_do(d, cmd)
		elseif (opt == :e)  cmd, o = parse_e(d, cmd)
		elseif (opt == :f)  cmd, o = parse_f(d, cmd)
		elseif (opt == :g)  cmd, o = parse_g(d, cmd)
		elseif (opt == :h)  cmd, o = parse_h(d, cmd)
		elseif (opt == :i)  cmd, o = parse_i(d, cmd)
		elseif (opt == :j)  cmd, o = parse_j(d, cmd)
		elseif (opt == :l)  cmd, o = parse_l(d, cmd)
		elseif (opt == :n)  cmd, o = parse_n(d, cmd)
		elseif (opt == :o)  cmd, o = parse_o(d, cmd)
		elseif (opt == :p)  cmd, opt_p = parse_p(d, cmd)
		elseif (opt == :r)  cmd, o = parse_r(d, cmd)
		elseif (opt == :s)  cmd, o = parse_s(d, cmd)
		elseif (opt == :x)  cmd, o = parse_x(d, cmd)
		elseif (opt == :t)  cmd, o = parse_t(d, cmd)
		elseif (opt == :yx) cmd, o = parse_swap_xy(d, cmd)
		elseif (opt == :R)  cmd, o = parse_R(d, cmd)
		elseif (opt == :F)  cmd  = parse_F(d, cmd)
		elseif (opt == :I)  cmd  = parse_inc(d, cmd, [:I :inc], 'I')
		elseif (opt == :J)  cmd, o = parse_J(d, cmd)
		elseif (opt == :JZ) cmd, o = parse_JZ(d, cmd)
		elseif (opt == :UVXY)     cmd = parse_UVXY(d, cmd)
		elseif (opt == :V_params) cmd = parse_V_params(d, cmd)
		elseif (opt == :params)   cmd = parse_params(d, cmd)
		elseif (opt == :write)    cmd = parse_write(d, cmd)
		elseif (opt == :append)   cmd = parse_append(d, cmd)
		end
	end
	if (opt_p !== nothing)		# Restrict the contents of this block to when -p was used
		if (opt_p != "")
			if (opt_p == " -pnone")  current_view[1] = "";	cmd = cmd[1:end-7];	opt_p = ""
			elseif (startswith(opt_p, " -pa") || startswith(opt_p, " -pd"))
				current_view[1] = " -p210/30";	cmd = replace(cmd, opt_p => "") * current_view[1]		# auto, def, 3d
			else                     current_view[1] = opt_p
			end
		elseif (!first && current_view[1] != "")
			cmd *= current_view[1]
		elseif (first)
			current_view[1] = ""		# Ensure we start empty
		end
	end
	if ((val = find_in_dict(d, [:theme])[1]) !== nothing)
		isa(val, NamedTuple) && theme(string(val[1]); nt2dict(val)...)
		(isa(val, String) || isa(val, Symbol)) && theme(string(val))
	end
	return cmd, o
end

# ---------------------------------------------------------------------------------------------------
function parse_these_opts(cmd::String, d::Dict, opts, del::Bool=true)::String
	# Parse a group of options that individualualy would had been parsed as (example):
	# cmd = add_opt(d, cmd, 'A', [:A :horizontal])
	for opt in opts
		cmd = add_opt(d, cmd, string(opt[1]), opt, nothing, del)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_inc(d::Dict, cmd::String, symbs, opt, del::Bool=true)::String
	# Parse the quasi-global -I option. But arguments can be strings, arrays, tuples or NamedTuples
	# At the end we must recreate this syntax: xinc[unit][+e|n][/yinc[unit][+e|n]] or
	if ((val = find_in_dict(d, symbs, del)[1]) !== nothing)
		if isa(val, Dict)  val = dict2nt(val)  end
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
				u = parse_unit_unit(u)
				if (u != "u")  cmd *= u  end	# "u" is only for the `scatter` modules
			end
			if (e)  cmd *= "+e"  end
			if (y != "")
				cmd = string(cmd, "/", y, u)
				if (e)  cmd *= "+e"  end		# Should never have this and u != ""
			end
		else
			if (opt != "")  cmd  = string(cmd, " -", opt, arg2str(val))
			else            cmd *= arg2str(val)
			end
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_params(d::Dict, cmd::String)::String
	# Parse the gmt.conf parameters when used from within the modules. Return a --PAR=val string
	# The input to this kwarg can be a tuple (e.g. (PAR,val)) or a NamedTuple (P1=V1, P2=V2,...)

	_cmd = Array{String,1}(undef,1)		# Otherwise Traceur insists this fun was returning a Any
	_cmd = [cmd]
	if ((val = find_in_dict(d, [:conf :par :params], true)[1]) !== nothing)
		if isa(val, Dict)  val = dict2nt(val)  end
		(!isa(val, NamedTuple) && !isa(val, Tuple)) && @warn("BAD usage: Parameter is neither a Tuple or a NamedTuple")
		if (isa(val, NamedTuple))
			fn = fieldnames(typeof(val))
			for k = 1:length(fn)		# Suspect that this is higly inefficient but N is small
				_cmd[1] *= " --" * string(fn[k]) * "=" * string(val[k])
			end
		elseif (isa(val, Tuple))
			_cmd[1] *= " --" * string(val[1]) * "=" * string(val[2])
		end
		usedConfPar[1] = true
	end
	return _cmd[1]
end

# ---------------------------------------------------------------------------------------------------
function add_opt_pen(d::Dict, symbs, opt::String="", sub::Bool=true, del::Bool=true)::String
	# Build a pen option. Input can be either a full hard core string or spread in lw (or lt), lc, ls, etc or a tuple
	# If SUB is true (lw, lc, ls) are not seeked because we are parsing a sub-option

	(show_kwargs[1]) && return print_kwarg_opts(symbs, "NamedTuple | Tuple | String | Number")	# Just print the options

	if (opt != "")  opt = " -" * opt  end	# Will become -W<pen>, for example
	out = [""]
	pen = build_pen(d, del)					# Either a full pen string or empty ("") (Seeks for lw (or lt), lc, etc)
	if (pen != "")
		out[1] = opt * pen
	else
		if ((val = find_in_dict(d, symbs, del)[1]) !== nothing)
			if isa(val, Dict)  val = dict2nt(val)  end
			if (isa(val, Tuple))				# Like this it can hold the pen, not extended atts
				if (isa(val[1], NamedTuple))	# Then assume they are all NTs
					for v in val
						d2 = nt2dict(v)			# Decompose the NT and feed it into this-self
						out[1] *= opt * add_opt_pen(d2, symbs, "", true, false)
					end
				else
					out[1] = opt * parse_pen(val)	# Should be a better function
				end
			elseif (isa(val, NamedTuple))		# Make a recursive call. Will screw if used in mix mode
				# This branch is very convoluted and fragile
				d2 = nt2dict(val)				# Decompose the NT and feed into this-self
				t = add_opt_pen(d2, symbs, "", true, false)
				if (t == "")
					d, out[1] = nt2dict(val), opt
				else
					out[1] = opt * t
					d = Dict{Symbol,Any}()		# Just let it go straight to end. Returning here seems bugged
				end
			else
				out[1] = opt * arg2str(val)
			end
		end
	end

	# All further options prepend or append to an existing pen. So, if empty we are donne here.
	(out[1] == "") && return out[1]

	# -W in ps|grdcontour may have extra flags at the begining but take care to not prepend on a blank
	if     (out[1][1] != ' ' && haskey(d, :cont) || haskey(d, :contour))  out[1] = "c" * out[1]
	elseif (out[1][1] != ' ' && haskey(d, :annot))                        out[1] = "a" * out[1]
	end

	# Some -W take extra options to indicate that color comes from CPT
	if (haskey(d, :colored))  out[1] *= "+c"
	else
		if ((val = find_in_dict(d, [:cline :color_line :colot_lines])[1]) !== nothing)  out[1] *= "+cl"  end
		if ((val = find_in_dict(d, [:ctext :color_text :csymbol :color_symbols :color_symbol])[1]) !== nothing)  out[1] *= "+cf"  end
	end
	if (haskey(d, :bezier))  out[1] *= "+s";  del_from_dict(d, [:bezier])  end
	if (haskey(d, :offset))  out[1] *= "+o" * arg2str(d[:offset])   end

	if (out[1] != "")		# Search for eventual vec specs, but only if something above has activated -W
		v = false
		r = helper_arrows(d)
		if (r != "")
			if (haskey(d, :vec_start))  out[1] *= "+vb" * r[2:end];  v = true  end	# r[1] = 'v'
			if (haskey(d, :vec_stop))   out[1] *= "+ve" * r[2:end];  v = true  end
			if (!v)  out[1] *= "+" * r  end
		end
	end

	return out[1]
end

# ---------------------------------------------------------------------------------------------------
function opt_pen(d::Dict, opt::Char, symbs)::String
	# Create an option string of the type -Wpen
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "Tuple | String | Number")	# Just print the options

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
function parse_pen(pen::Tuple)::String
	# Convert an empty to 3 args tuple containing (width[c|i|p]], [color], [style[c|i|p|])
	s = arg2str(pen[1])					# First arg is different because there is no leading ','
	if (length(pen) > 1)
		s *= ',' * get_color(pen[2])
		if (length(pen) > 2)  s *= ',' * arg2str(pen[3])  end
	end
	return s
end

# ---------------------------------------------------------------------------------------------------
function parse_pen_color(d::Dict, symbs=nothing, del::Bool=false)::String
	# Need this as a separate fun because it's used from modules
	lc = ""
	if (symbs === nothing)  symbs = [:lc :linecolor]  end
	if ((val = find_in_dict(d, symbs, del)[1]) !== nothing)
		lc = string(get_color(val))
	end
	return lc
end

# ---------------------------------------------------------------------------------------------------
function build_pen(d::Dict, del::Bool=false)::String
	# Search for lw, lc, ls in d and create a pen string in case they exist
	# If no pen specs found, return the empty string ""
	lw = add_opt(d, "", "", [:lw :linewidth], nothing, del)		# Line width
	if (lw == "")  lw = add_opt(d, "", "", [:lt :linethick :linethickness], nothing, del)  end	# Line width
	ls = add_opt(d, "", "", [:ls :linestyle], nothing, del)		# Line style
	lc = parse_pen_color(d, [:lc :linecolor], del)
	out = ""
	if (lw != "" || lc != "" || ls != "")
		out = lw * "," * lc * "," * ls
		while (out[end] == ',')  out = rstrip(out, ',')  end	# Strip unneeded commas
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
function parse_arg_and_pen(arg::Tuple, sep="/", pen::Bool=true, opt="")::String
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
function parse_ls_code!(d::Dict)
	if ((val = find_in_dict(d, [:ls :linestyle])[1]) !== nothing)
		if (isa(val, String) && (val[1] == '-' || val[1] == '.' || isnumeric(val[1])))
			d[:ls] = val	# Assume it's a "--." or the more complex len_gap_len_gap... form. So reset it and return
		else
			o = mk_styled_line!(d, val)
			(o !== nothing) && (d[:ls] = o)		# Means used an option like for example ls="DashDot"
		end
	end
	return nothing
end

function mk_styled_line!(d::Dict, code::String)
	# Parse the CODE string and generate line style. These line styles can be a single annotated line with symbols
	# or two lines, one a plain line and the other the symbols to plot. This is achieved by tweaking the D dict
	# and inserting in it the members that the common_plot_xyz function is expecting.
	# To get the first type use CODEs as "LineCirc" or "DashDotSquare" or "LineTriang#". The last form will invert
	# the way the symbol is plotted by drawing a white outline and a filled circle, making it similar to GitHub Traffic.
	# The second form (annotated line) requires separating the style and marker name by a '&', '_' or '!'. The last
	# two ways allow sending CODE as a Symbol (e.g. :line!circ). Enclose the "Symbol" in a pair of those markersize
	# to create an annotated line instead. E.g. ls="Line&Bla Bla Bla&" 
	_code = lowercase(code)
	inv = !isletter(code[end])					# To know if we want to make white outline and fill = lc
	is1line = (occursin("&", _code) || occursin("_", _code) || occursin("!", _code))	# e.g. line&Circ
	if (is1line && (_code[end] == '&' || _code[end] == '_' || _code[end] == '!') &&		# For case code="Dash&Bla Bla&"
		(length(findall("&",_code)) == 2 || length(findall("_",_code)) == 2 || length(findall("!",_code)) == 2))
		decor_str, inv = true, true				# Setting inv=true is an helper. It avoids reading the flag as part of text
	else
		decor_str = false
	end

	if     (startswith(_code, "line"))        ls = "";     symbol = (length(_code) == 4)  ? "" : code[5 + is1line : end-inv]
	elseif (startswith(_code, "dashdot"))     ls = "-.";   symbol = (length(_code) == 7)  ? "" : code[8 + is1line : end-inv]
	elseif (startswith(_code, "dashdashdot")) ls = "--.";  symbol = (length(_code) == 11) ? "" : code[12+ is1line : end-inv]
	elseif (startswith(_code, "dash"))        ls = "-";    symbol = (length(_code) == 4)  ? "" : code[5 + is1line : end-inv]
	elseif (startswith(_code, "dotdotdash"))  ls = "..-";  symbol = (length(_code) == 10) ? "" : code[11+ is1line : end-inv]
	elseif (startswith(_code, "dot"))         ls = ".";    symbol = (length(_code) == 3)  ? "" : code[4 + is1line : end-inv]
	else   error("Bad line style. Options are (for example) [Line|DashDot|Dash|Dot]Circ")
	end

	(symbol == "") && return ls		# It means only the line style was transmitted. Return to allow use as ls="DashDot"

	lc = parse_pen_color(d, [:lc :linecolor], false)
	lw = add_opt(d, "", "", [:lw :linewidth])		# Line width
	d[:ls] = ls										# The linestyle picked above
	d[:lw] = (lw != "") ? lw : "0.75"

	if (is1line)									# e.g. line&Circ or line_Triang or line!Square
		if (decor_str)
			d[:GMTopt] = line_decorated_with_string(symbol)
		else	
			d[:GMTopt] = line_decorated_with_symbol(lw=lw, lc=lc, symbol=symbol)
		end
	else											# e.g. lineCirc
		marca = get_marker_name(Dict(:marker => symbol), nothing, [:marker], false)[1]	# This fun lieves in psxy.jl
		(marca == "") && error("The selected symbol [$(symbol)] is invalid")
		if (isletter(code[end]))
			f = 4									# Multiplying factor for the symbol size
			d[:ml], d[:mc] = (lc == "") ? d[:lw] : (d[:lw], lc), "white"	# MarkerLine and MarkerColor
		else										# Invert the above. I.e. white outline and lc fill color
			d[:ml], d[:mc], f = (d[:lw], "white"), lc, 5
		end
		d[:symbol] = string(marca, round(f * parse(Float64,d[:lw]) * 2.54/72, digits=2))
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function line_decorated_with_symbol(; lw=0.75, lc="black", ms=0, symbol="circ", dist=0, fill="white")::String
	# Create an Annotated line with few controls. We estimate the symbol size after the line thickness.
	(lc == "") && (lc = "black")
	_lw = (lw == "") ? 0.75 : isa(lw, String) ? parse(Float64, lw) : lw		# If last case is not numeric ...
	ss = (ms != 0) ? ms : round(4 * _lw * 2.54/72, digits=2)
	_dist = (dist == 0) ? 4ss : dist * ss
	decorated(dist=_dist, symbol=symbol, size=ss, pen=(_lw,lc), fill=fill, dec2=true)
end

# ---------------------------------------------------------------------------------------------------
function line_decorated_with_string(str::AbstractString; dist=0)::String
	# Create an Quoted line with few controls.
	str_len = length(str) * 4 * 2.54/72		# Very rough estimate of line length assuming a font od ~9 pts
	_dist = (dist == 0) ? max(3, round(str_len * 3, digits=1)) : dist	# Simple heuristic to estimate dist
	decorated(dist=_dist, const_label=str, quoted=true, curved=true)
end

# ---------------------------------------------------------------------------------------------------
function arg2str(d::Dict, symbs)::String
	# Version that allow calls from add_opt()
	return ((val = find_in_dict(d, symbs)[1]) !== nothing) ? arg2str(val) : ""
end

# ---------------------------------------------------------------------------------------------------
function arg2str(arg, sep='/')::String
	# Convert an empty, a numeric or string ARG into a string ... if it's not one to start with
	# ARG can also be a Bool, in which case the TRUE value is converted to "" (empty string)
	# SEP is the char separator used when ARG is a tuple or array of numbers
	if (isa(arg, AbstractString) || isa(arg, Symbol))
		out = string(arg)
		if (occursin(" ", out) && !startswith(out, "\""))	# Wrap it in quotes
			out = "\"" * out * "\""
		end
	elseif ((isa(arg, Bool) && arg) || isempty_(arg))
		out = ""
	elseif (isa(arg, Real))		# Have to do it after the Bool test above because Bool is a Number too
		out = @sprintf("%.12g", arg)
	elseif (isa(arg, Array{<:Real}) || (isa(arg, Tuple) && !isa(arg[1], String)) )
		out = join([string(x, sep) for x in arg])
		out = rstrip(out, sep)		# Remove last '/'
	elseif (isa(arg, Tuple) && isa(arg[1], String))		# Maybe better than above but misses nice %.xxg
		out = join(arg, sep)
	else
		error("arg2str: argument 'arg' can only be a String, Symbol, Number, Array or a Tuple, but was $(typeof(arg))")
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
function finish_PS_nested(d::Dict, cmd::Vector{String}, K::Bool=true)::Tuple{Vector{String}, Bool}
	# Finish the PS creating command, but check also if we have any nested module calls like 'coast', 'colorbar', etc
	cmd2::Vector{String} = add_opt_module(d)
	if (!isempty(cmd2))
		if (startswith(cmd2[1], "clip"))		# Deal with the particular psclip case (Tricky)
			if (isa(CTRL.pocket_call[1], Symbol) || isa(CTRL.pocket_call[1], String))	# Assume it's a clip=end
				cmd::Vector{String}, CTRL.pocket_call[1] = [cmd; "psclip -C"], nothing
			else
				ind = findfirst(" -R", cmd[1]);		opt_R::String = strtok(cmd[1][ind[1]:end])[1]
				ind = findfirst(" -J", cmd[1]);		opt_J::String = strtok(cmd[1][ind[1]:end])[1]
				extra::String = strtok(cmd2[1])[2] * " "	# When psclip recieved extra arguments
				t, opt_B, opt_B1 = "psclip " * extra * opt_R * " " * opt_J, "", ""
				ind = findall(" -B", cmd[1])
				if (!isempty(ind) && (findfirst("-N", extra) === nothing))
					[opt_B *= " " * strtok(cmd[1][ind[k][1]:end])[1] for k = 1:length(ind)]
					# Here we need to reset any -B parts that do NOT include the plotting area and which were clipped.
					if (CTRL.pocket_B[1] == "" && CTRL.pocket_B[1] == "")
						opt_B1::String = opt_B * " -R -J"
					else
						(CTRL.pocket_B[1] != "") && (opt_B1 = replace(opt_B,  CTRL.pocket_B[1] => ""))	# grid
						(CTRL.pocket_B[2] != "") && (opt_B1 = replace(opt_B1, CTRL.pocket_B[2] => ""))	# Fill
						(occursin("-Bp ", opt_B1)) && (opt_B1 = replace(opt_B1, "-Bp " => ""))		# Delete stray -Bp 
						opt_B1 = replace(opt_B1, "-B " => "")		#			""
						(endswith(opt_B1, " -B")) && (opt_B1 = opt_B1[1:end-2])
						(opt_B1 != "") && (opt_B1 *= " -R -J")		# When not-empty it needs the -R -J
						CTRL.pocket_B[1] = CTRL.pocket_B[2] = ""	# Empty these guys
					end
				end
				cmd = [t; cmd; "psclip -C" * opt_B1]
			end
		else
			append!(cmd, cmd2)
		end
	end
	return cmd, K
end

# ---------------------------------------------------------------------------------------------------
function finish_PS(d::Dict, cmd::Vector{String}, output::String, K::Bool, O::Bool)::Vector{String}
	# Finish a PS creating command. All PS creating modules should use this.
	IamModern[1] && return cmd  			# In Modern mode this fun does not play
	for k = 1:length(cmd)
		if (!occursin(" >", cmd[k]))	# Nested calls already have the redirection set
			cmd[k] = (k == 1) ? finish_PS(d, cmd[k], output, K, O) : finish_PS(d, cmd[k], output, true, true)
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function finish_PS(d::Dict, cmd::String, output::String, K::Bool, O::Bool)::String
	if (!O && ((val = find_in_dict(d, [:P :portrait])[1]) === nothing))  cmd *= " -P"  end

	opt = (K && !O) ? " -K" : ((K && O) ? " -K -O" : "")

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
function prepare2geotif(d::Dict, cmd::Vector{String}, opt_T::String, O::Bool)::Tuple{Vector{String}, String}
	# Prepare automatic settings to allow creating a GeoTIF or a KML from a PS map
	# Makes use of psconvert -W option -W
	function helper2geotif(cmd::String)::String
		# Strip all -B's and add convenient settings for creating GeoTIFF's and KLM's
		opts = split(cmd, " ");		cmd  = ""
		for opt in opts
			if     (startswith(opt, "-JX12c"))  cmd *= "-JX30cd/0 "		# Default size is too small
			elseif (!startswith(opt, "-B"))     cmd *= opt * " "
			end
		end
		cmd *= " -B0 --MAP_FRAME_TYPE=inside --MAP_FRAME_PEN=0.1,254"
	end

	if (!O && ((val = find_in_dict(d, [:geotif])[1]) !== nothing))		# Only first layer
		cmd[1] = helper2geotif(cmd[1])
		if (startswith(string(val), "trans"))  opt_T = " -TG -W+g"  end	# A transparent GeoTIFF
	elseif (!O && ((val = find_in_dict(d, [:kml])[1]) !== nothing))		# Only first layer
		if (!occursin("-JX", cmd[1]) && !occursin("-Jx", cmd[1]))
			@warn("Creating KML requires the use of a cartesian projection of geographical coordinates. Not your case")
			return cmd, opt_T
		end
		cmd[1] = helper2geotif(cmd[1])
		if (isa(val, String) || isa(val, Symbol))	# A transparent KML
			if (startswith(string(val), "trans"))  opt_T = " -TG -W+k"
			else                                   opt_T = string(" -TG -W+k", val)		# Whatever 'val' is
			end
		elseif (isa(val, NamedTuple) || isa(val, Dict))
			# [+tdocname][+nlayername][+ofoldername][+aaltmode[alt]][+lminLOD/maxLOD][+fminfade/maxfade][+uURL]
			if isa(val, Dict)  val = dict2nt(val)  end
			opt_T = add_opt(Dict(:kml => val), " -TG -W+k", "", [:kml],
							(title="+t", layer="+n", layername="+n", folder="+o", foldername="+o", altmode="+a", LOD=("+l", arg2str), fade=("+f", arg2str), URL="+u"))
		end
	end
	return cmd, opt_T
end

# ---------------------------------------------------------------------------------------------------
function add_opt_1char(cmd::String, d::Dict, symbs, del::Bool=true)::String
	# Scan the D Dict for SYMBS keys and if found create the new option OPT and append it to CMD
	# If DEL == true we remove the found key.
	# The keyword value must be a string, symbol or a tuple of them. We only retain the first character of each item
	# Ex:  GMT.add_opt_1char("", Dict(:N => ("abc", "sw", "x"), :Q=>"datum"), [[:N :geod2aux], [:Q :list]]) == " -Nasx -Qd"
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "Str | Symb | Tuple")
	for opt in symbs
		if ((val = find_in_dict(d, opt, del)[1]) === nothing)  continue  end
		args = ""
		if (isa(val, String) || isa(val, Symbol))
			if ((args = arg2str(val)) != "")  args = args[1]  end
		elseif (isa(val, Tuple))
			for k = 1:length(val)
				args *= arg2str(val[k])[1]
			end
		end
		cmd = string(cmd, " -", opt[1], args)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt(d::Dict, cmd::String, opt, symbs, mapa=nothing, del::Bool=true, arg=nothing)::String
	# Scan the D Dict for SYMBS keys and if found create the new option OPT and append it to CMD
	# If DEL == false we do not remove the found key.
	# ARG, is a special case to append to a matrix (complicated thing in Julia)
	# ARG can also be a Bool, in which case when MAPA is a NT we expand each of its members as sep options
	# If ARG is a string, then the keys of MAPA can be used as values of SYMB and are replaced by vals of MAPA
	#    Example (hitogram -Z): add_opt(d, "", 'Z', [:Z :kind], (counts="0", freq="1",...)) Z=freq => -Z1
	#  But this only works when sub-options have default values. i.e. they are aliases
	(show_kwargs[1]) && return print_kwarg_opts(symbs, mapa)	# Just print the kwargs of this option call

	if ((val = find_in_dict(d, symbs, del)[1]) === nothing)
		if (isa(arg, Bool) && isa(mapa, NamedTuple))	# Make each mapa[i] a mapa[i]key=mapa[i]val
			local cmd_ = [""]
			for k in keys(mapa)
				((val_ = find_in_dict(d, [k], false)[1]) === nothing) && continue
				if (isa(mapa[k], Tuple))  cmd_[1] *= mapa[k][1] * mapa[k][2](d, [k])
				else
					if (mapa[k][1] == '_')  cmd_[1] *= mapa[k][2:end]		# Keep omly the flag
					else                    cmd_[1] *= mapa[k] * arg2str(val_)
					end
				end
				del_from_dict(d, [k])		# Now we can delete the key
			end
			if (cmd_[1] != "")  cmd *= " -" * opt * cmd_[1]  end
		end
		return cmd
	elseif (isa(arg, String) && isa(mapa, NamedTuple))	# Use the mapa KEYS as possibe values of 'val'
		local cmd_ = ""
		for k in keys(mapa)
			if (string(val) == string(k))
				cmd_ = " -" * opt
				#(length(mapa[k][1]) == 0) && error("Need alias valu. Cannot be empty")
				first_ind = (mapa[k][1] == "_") ? 2 : 1
				cmd_ *= mapa[k][first_ind:end]
				break
			end
		end
		(cmd_ != "") && return cmd * cmd_	# Otherwise continue to see if the other (NT) form was provided
	end

	args = Array{String,1}(undef,1)
	if isa(val, Dict)  val = dict2nt(val)  end	# For Py usage
	if (isa(val, NamedTuple) && isa(mapa, NamedTuple))
		args[1] = add_opt(val, mapa, arg)
	elseif (isa(val, Tuple) && length(val) > 1 && isa(val[1], NamedTuple))	# In fact, all val[i] -> NT
		# Used in recursive calls for options like -I, -N , -W of pscoast. Here we assume that opt != ""
		args[1] = ""
		for k = 1:length(val)
			args[1] *= " -" * opt * add_opt(val[k], mapa, arg)
		end
		return cmd * args[1]
	elseif (isa(mapa, Tuple) && length(mapa) > 1 && isa(mapa[2], Function))	# grdcontour -G
		(!isa(val, NamedTuple) && !isa(val, String)) &&
			error("The option argument must be a NamedTuple, not a simple Tuple")
		if (isa(val, NamedTuple))
			args[1] = (mapa[2] == helper_decorated) ? mapa[2](val, true) : args[1] = mapa[2](val)	# 2nd case not yet inv
		elseif (isa(val, String))  args[1] = val
		end
	else
		args[1] = arg2str(val)
		if isa(mapa, NamedTuple)		# Let aa=(bb=true,...) be addressed as aa=:bb
			s = Symbol(args[1])
			for k in keys(mapa)
				if (s != k)  continue  end
				v = mapa[k]
				if (isa(v, String) && (v[1] == '_'))	# Only the modifier matters
					args[1] = v[2:end]
				elseif (isa(v, Tuple) && length(v) == 3 && v[2] === nothing)	# A ("t", nothing, 1) type
					args[1] = v[1]
				end
				break
			end
		end
	end

	cmd = (opt != "") ? string(cmd, " -", opt, args[1]) : string(cmd, args[1])

	return cmd
end

# ---------------------------------------------------------------------------------------------------
function genFun(this_key::Symbol, user_input::NamedTuple, mapa::NamedTuple)::String
	d = nt2dict(mapa)
	(!haskey(d, this_key)) && return		# Should it be a error?
	out = ""
	key = keys(user_input)					# user_input = (rows=1, fill=:red)
	val_namedTup = d[this_key]				# water=(rows="my", cols="mx", fill=add_opt_fill)
	d = nt2dict(val_namedTup)
	for k = 1:length(user_input)
		if (haskey(d, key[k]))
			val = d[key[k]]
			if (isa(val, Function))
				if (val == add_opt_fill) out *= val(Dict(key[k] => user_input[key[k]]))  end
			else
				out *= string(d[key[k]])
			end
		end
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
function add_opt(nt::NamedTuple, mapa::NamedTuple, arg=nothing)::String
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
		!haskey(d, key[k]) && continue
		if (isa(nt[k], Dict))  nt[k] = dict2nt(nt[k])  end
		if (isa(d[key[k]], Tuple))		# Complexify it. Here, d[key[k]][2] must be a function name.
			if (isa(nt[k], NamedTuple))
				if (d[key[k]][2] == add_opt_fill)
					cmd *= d[key[k]][1] * d[key[k]][2]("", Dict(key[k] => nt[k]), [key[k]])
				else
					local_opt = (d[key[k]][2] == helper_decorated) ? true : nothing		# 'true' means single argout
					cmd *= d[key[k]][1] * d[key[k]][2](nt2dict(nt[k]), local_opt)
				end
			else						#
				if (length(d[key[k]]) == 2)		# Run the function
					cmd *= d[key[k]][1] * d[key[k]][2](Dict(key[k] => nt[k]), [key[k]])
				else					# This branch is to deal with options -Td, -Tm, -L and -D of basemap & psscale
					ind_o += 1
					if (d[key[k]][2] === nothing)  cmd_hold[ind_o] = d[key[k]][1]	# Only flag char and order matters
					elseif (length(d[key[k]][1]) == 2 && d[key[k]][1][1] == '-' && !isa(nt[k], Tuple))	# e.g. -L (&g, arg2str, 1)
						cmd_hold[ind_o] = string(d[key[k]][1][2])	# where g<scalar>
					else		# Run the fun
						cmd_hold[ind_o] = (d[key[k]][1] == "") ? d[key[k]][2](nt[k]) : d[key[k]][1][end] * d[key[k]][2](nt[k])
					end
					order[ind_o]    = d[key[k]][3];				# Store the order of this sub-option
				end
			end
		elseif (isa(d[key[k]], NamedTuple))		#
			if (isa(nt[k], NamedTuple))
				cmd *= genFun(key[k], nt[k], mapa)
			else						# Create a NT where value = key. For example for: surf=(waterfall=:rows,)
				if (!isa(nt[1], Tuple))			# nt[1] may be a symbol, or string. E.g.  surf=(water=:cols,)
					cmd *= genFun(key[k], (; Symbol(nt[1]) => nt[1]), mapa)
				else
					if ((val = find_in_dict(d, [key[1]])[1]) !== nothing)		# surf=(waterfall=(:cols,:red),)
						cmd *= genFun(key[k], (; Symbol(nt[1][1]) => nt[1][1], keys(val)[end] => nt[1][end]), mapa)
					end
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
#=
		elseif (length(cmd_hold[last]) > 2)		# Temp patch to avoid parsing single char flags
			rs = split(cmd_hold[last], '/')
			if (length(rs) == 2)
				x = tryparse(Float64, rs[1]);		y = tryparse(Float64, rs[2]);
				if (x !== nothing && y !== nothing && 0 <= x <= 1.0 && 0 <= y <= 1.0 && !occursin(r"[gjJxn]", string(cmd[1])))  cmd = "n" * cmd  end		# Otherwise, either a paper coord or error
			end
=#
		end
	end

	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt(fun::Function, t1::Tuple, t2::NamedTuple, del::Bool, mat)
	# Crazzy shit to allow increasing the arg1 matrix
	(mat === nothing) && return fun(t1..., t2, del, mat), mat  # psxy error_bars may send mat = nothing
	n_rows = size(mat, 1)
	mat = reshape(mat, :)
	cmd = fun(t1..., t2, del, mat)
	mat = reshape(mat, n_rows, :)
	return cmd, mat
end

# ---------------------------------------------------------------------------------------------------
function add_opt(d::Dict, cmd::String, opt, symbs, need_symb::Symbol, args, nt_opts::NamedTuple)
	# This version specializes in the case where an option may transmit an array, or read a file, with optional flags.
	# When optional flags are used we need to use NamedTuples (the NT_OPTS arg). In that case the NEED_SYMB
	# is the keyword name (a symbol) whose value holds the array. An error is raised if this symbol is missing in D
	# ARGS is a 1-to-3 array of GMT types with in which some may be NOTHING. The value is an array, it will be
	# stored in first non-empty element of ARGS.
	# Example where this is used (plot -Z):  Z=(outline=true, data=[1, 4])
	(show_kwargs[1]) && print_kwarg_opts(symbs)		# Just print the kwargs of this option call

	N_used = 0;		got_one = false
	val,symb = find_in_dict(d, symbs, false)
	if (val !== nothing)
		to_slot = true
		if isa(val, Dict)  val = dict2nt(val)  end
		if (isa(val, Tuple) && length(val) == 2)
			# This is crazzy trickery to accept also (e.g) C=(pratt,"200k") instead of C=(pts=pratt,dist="200k")
			val = dict2nt(Dict(need_symb=>val[1], keys(nt_opts)[1]=>val[2]))
			d[symb] = val		# Need to patch also the input option
		end
		if (isa(val, NamedTuple))
			di = nt2dict(val)
			((val = find_in_dict(di, [need_symb], false)[1]) === nothing) && error(string(need_symb, " member cannot be missing"))
			if (isa(val, Number) || isa(val, String))	# So that this (psxy) also works:	Z=(outline=true, data=3)
				opt::String = string(opt,val)
				to_slot = false
			end
			cmd = add_opt(d, cmd, opt, symbs, nt_opts)
		elseif (isa(val, Array{<:Real}) || isa(val, GMTdataset) || isa(val, Vector{<:GMTdataset}) || isa(val, GMTcpt) || typeof(val) <: AbstractRange)
			if (typeof(val) <: AbstractRange)  val = collect(val)  end
			cmd::String = string(cmd, " -", opt)
		elseif (isa(val, String) || isa(val, Symbol) || isa(val, Number))
			cmd = string(cmd, " -", opt * arg2str(val))
			to_slot = false
		else
			error("Bad argument type ($(typeof(val))) to option $opt")
		end
		if (to_slot)
			for k = 1:length(args)
				if (args[k] === nothing)
					args[k] = val
					N_used = k
					break
				end
			end
		end
		del_from_dict(d, symbs)
		got_one = true
	end
	return cmd, args, N_used, got_one
end

# ---------------------------------------------------------------------------------------------------
function add_opt_cpt(d::Dict, cmd::String, symbs, opt::Char, N_args::Int=0, arg1=nothing, arg2=nothing,
	                 store::Bool=false, def::Bool=false, opt_T::String="", in_bag::Bool=false)
	# Deal with options of the form -Ccolor, where color can be a string or a GMTcpt type
	# SYMBS is normally: [:C :color :cmap]
	# N_args only applyies to when a GMTcpt was transmitted. Than it's either 0, case in which
	# the cpt is put in arg1, or 1 and the cpt goes to arg2.
	# STORE, when true, will save the cpt in the global state
	# DEF, when true, means to use the default cpt (Turbo)
	# OPT_T, when != "", contains a min/max/n_slices/+n string to calculate a cpt with n_slices colors between [min max]
	# IN_BAG, if true means that, if not empty, we return the contents of `current_cpt`

	(show_kwargs[1]) && return print_kwarg_opts(symbs, "GMTcpt | Tuple | Array | String | Number"), arg1, arg2, N_args

	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		if (isa(val, GMT.GMTcpt))
			(N_args > 1) && error("Can't send the CPT data via option AND input array")
			cmd, arg1, arg2, N_args = helper_add_cpt(cmd, opt, N_args, arg1, arg2, val, store)
		else
			if (opt_T != "")
				cpt::GMTcpt = makecpt(opt_T * " -C" * get_color(val))
				cmd, arg1, arg2, N_args = helper_add_cpt(cmd, opt, N_args, arg1, arg2, cpt, store)
			else
				c = get_color(val)
				opt_C = " -" * opt * c		# This is pre-made GMT cpt
				cmd *= opt_C
				if (store && c != "" && tryparse(Float32, c) === nothing)	# Because if !== nothing then it's number and -Cn is not valid
					try			# Wrap in try because not always (e.g. grdcontour -C) this is a makecpt callable
						r = makecpt(opt_C * " -Vq")
						global current_cpt[1] = (r !== nothing) ? r : GMTcpt()
					catch
					end
				elseif (in_bag && !isempty(current_cpt[1]))	# If we have something in Bag, return it
					cmd, arg1, arg2, N_args = helper_add_cpt(cmd, "", N_args, arg1, arg2, current_cpt[1], false)
				end
			end
		end
	elseif (def && opt_T != "")						# Requested the use of the default color map
		if (IamModern[1])  opt_T *= " -H"  end		# Piggy back this otherwise we get no CPT back in Modern
		if (haskey(d, :this_cpt) && d[:this_cpt] != "")		# A specific CPT name was requested
			cpt = makecpt(opt_T * " -C" * d[:this_cpt])
		else
			opt_T *= " -Cturbo"
			cpt = makecpt(opt_T)
			cpt.bfn[3, :] = [1.0 1.0 1.0]	# Some deep bug, in occasions, returns grays on 2nd and on calls
		end
		cmd, arg1, arg2, N_args = helper_add_cpt(cmd, opt, N_args, arg1, arg2, cpt, store)
	elseif (in_bag && !isempty(current_cpt[1]))		# If everything else has failed and we have one in the Bag, return it
		cmd, arg1, arg2, N_args = helper_add_cpt(cmd, opt, N_args, arg1, arg2, current_cpt[1], false)
	end
	if (occursin(" -C", cmd))
		if ((val = find_in_dict(d, [:hinge])[1]) !== nothing)       cmd *= string("+h", val)  end
		if ((val = find_in_dict(d, [:meter2unit])[1]) !== nothing)  cmd *= "+U" * parse_unit_unit(val)  end
		if ((val = find_in_dict(d, [:unit2meter])[1]) !== nothing)  cmd *= "+u" * parse_unit_unit(val)  end
	end
	return cmd, arg1, arg2, N_args
end
# ---------------------
function helper_add_cpt(cmd::String, opt, N_args::Int, arg1, arg2, val::GMTcpt, store::Bool)
	# Helper function to avoid repeating 3 times the same code in add_opt_cpt
	(N_args == 0) ? arg1 = val : arg2 = val;	N_args += 1
	if (store)  global current_cpt[1] = val  end
	(isa(opt, Char) || (isa(opt, String) && opt != "")) && (cmd *= " -" * opt)
	return cmd, arg1, arg2, N_args
end

# ---------------------------------------------------------------------------------------------------
#add_opt_fill(d::Dict, opt::String="") = add_opt_fill("", d, [d[collect(keys(d))[1]]], opt)	# Use ONLY when len(d) == 1
function add_opt_fill(d::Dict, opt::String="")
	add_opt_fill(d, [collect(keys(d))[1]], opt)	# Use ONLY when len(d) == 1
end
add_opt_fill(d::Dict, symbs, opt="") = add_opt_fill("", d, symbs, opt)
function add_opt_fill(cmd::String, d::Dict, symbs, opt="", del::Bool=true)::String
	# Deal with the area fill attributes option. Normally, -G
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "NamedTuple | Tuple | Array | String | Number")
	((val = find_in_dict(d, symbs, del)[1]) === nothing) && return cmd
	if isa(val, Dict)  val = dict2nt(val)  end
	if (opt != "")  opt = string(" -", opt)  end
	return add_opt_fill(val, cmd, opt)
end

function add_opt_fill(val, cmd::String="",  opt="")::String
	# This version can be called directy with VAL as a NT or a string
	if (isa(val, NamedTuple))
		d2 = nt2dict(val)
		cmd *= opt
		if     (haskey(d2, :pattern))     cmd *= 'p' * add_opt(d2, "", "", [:pattern])
		elseif (haskey(d2, :inv_pattern)) cmd *= 'P' * add_opt(d2, "", "", [:inv_pattern])
		else   error("For 'fill' option as a NamedTuple, you MUST provide a 'patern' member")
		end

		if ((val2 = find_in_dict(d2, [:bg :background], false)[1]) !== nothing)  cmd *= "+b" * get_color(val2)  end
		if ((val2 = find_in_dict(d2, [:fg :foreground], false)[1]) !== nothing)  cmd *= "+f" * get_color(val2)  end
		if (haskey(d2, :dpi))  cmd = string(cmd, "+r", d2[:dpi])  end
	else
		cmd *= string(opt, get_color(val))
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function get_cpt_set_R(d::Dict, cmd0::String, cmd::String, opt_R::String, got_fname::Int, arg1, arg2=nothing, arg3=nothing, prog::String="")
	# Get CPT either from keyword input of from current_cpt.
	# Also puts -R in cmd when accessing grids from grdimage|view|contour, etc... (due to a GMT bug that doesn't do it)
	# Use CMD0 = "" to use this function from within non-grd modules
	global current_cpt
	cpt_opt_T::String = ""
	if (isa(arg1, GMTgrid) || isa(arg1, GMTimage))			# GMT bug, -R will not be stored in gmt.history
		range = arg1.range
	elseif (cmd0 != "" && cmd0[1] != '@')
		info::Array{GMT.GMTdataset,1} = grdinfo(cmd0 * " -C");	range = info[1].data
	end
	if (isa(arg1, GMTgrid) || isa(arg1, GMTimage) || (cmd0 != "" && cmd0[1] != '@'))
		if (isempty(current_cpt[1]) && (val = find_in_dict(d, [:C :color :cmap], false)[1]) === nothing)
			# If no cpt name sent in, then compute (later) a default cpt
			cpt_opt_T = sprintf(" -T%.12g/%.12g/128+n", range[5] - 1e-6, range[6] + 1e-6)
		end
		if (opt_R == "" && (!IamModern[1] || (IamModern[1] && FirstModern[1])) )	# No -R ovewrite by accident
			cmd *= sprintf(" -R%.14g/%.14g/%.14g/%.14g", range[1], range[2], range[3], range[4])
		end
	end

	N_used = (got_fname == 0) ? 1 : 0			# To know whether a cpt will go to arg1 or arg2
	get_cpt = false;	in_bag = true;			# IN_BAG means seek if current_cpt != nothing and return it
	if (prog == "grdview")
		get_cpt = true
		if ((val = find_in_dict(d, [:G :drapefile], false)[1]) !== nothing)
			if (isa(val, Tuple) && length(val) == 3)  get_cpt = false  end	# Playing safe
		end
	elseif (prog == "grdimage")
		if (!isa(arg1, GMTimage) && (arg3 === nothing && !occursin("-D", cmd)) )
			get_cpt = true		# This still lives out the case when the r,g,b were sent as a text.
		elseif (find_in_dict(d, [:C :color :cmap], false)[1] !== nothing)
			@warn("You are possibly asking to assign a CPT to an image. That is not allowed by GMT. See function image_cpt!")
		end
	elseif (prog == "grdcontour" || prog == "pscontour")	# Here C means Contours but we cheat, so always check if C, color, ... is present
		get_cpt = true;		cpt_opt_T = ""		# This is hell. And what if I want to auto generate a cpt?
		if (prog == "grdcontour" && !occursin("+c", cmd))  in_bag = false  end
	end
	if (get_cpt)
		cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_used, arg1, arg2, true, true, cpt_opt_T, in_bag)
		N_used = (arg1 !== nothing) + (arg2 !== nothing)
	end

	if (IamModern[1] && FirstModern[1])  FirstModern[1] = false;  end
	return cmd, N_used, arg1, arg2, arg3
end

# ---------------------------------------------------------------------------------------------------
function add_opt_module(d::Dict)::Vector{String}
	#  SYMBS should contain a module name (e.g. 'coast' or 'colorbar'), and if present in D,
	# 'val' can be a NamedTuple with the module's arguments or a 'true'.
	out = Vector{String}()
	for symb in CTRL.callable			# Loop over modules list that can be called inside other modules
		r = nothing
		if (haskey(d, symb))
			val = d[symb]
			if isa(val, Dict)  val = dict2nt(val)  end
			if (isa(val, NamedTuple))
				nt = (val..., Vd=2)
				if     (symb == :coast)     r = coast!(; nt...)
				elseif (symb == :colorbar)  r = colorbar!(; nt...)
				elseif (symb == :basemap)   r = basemap!(; nt...)
				elseif (symb == :logo)      r = logo!(; nt...)
				elseif (symb == :text)      r = text!(; nt...)
				elseif (symb == :clip)		# Need lots of little shits to parse the clip options
					CTRL.pocket_call[1] = val[1];
					k,v = keys(nt), values(nt)
					nt = NamedTuple{Tuple(Symbol.(k[2:end]))}(v[2:end])		# Fck, what a craziness to remove 1 el from a nt
					r = clip!(; nt...)
					r = r[1:findfirst(" -K", r)[1]];	# Remove the "-K -O >> ..."
					r = replace(r, " -R -J" => "")
					r = "clip " * strtok(r)[2]			# Make sure the prog name is 'clip' and not 'psclip'
				elseif (symb == :arrows || symb == :lines || symb == :scatter || symb == :scatter3 || symb == :plot
					   || symb == :plot3 || symb == :hlines || symb == :vlines)
					_d = nt2dict(nt)
					(haskey(_d, :data)) && (CTRL.pocket_call[1] = _d[:data]; del_from_dict(d, [:data]))
					r = (symb == :arrows) ? arrows!(; nt...) : (symb == :lines) ? lines!(; nt...) :
					(symb == :scatter) ? scatter!(; nt...) : (symb == :scatter3) ? scatter3!(; nt...) :
					(symb == :plot) ? plot!(; nt...) : (symb == :plot3) ? plot3!(; nt...) :
					(symb == :hlines) ? hlines!(; nt...) : vlines!(; nt...)
				end
			elseif (isa(val, Number) && (val != 0))		# Allow setting coast=true || colorbar=true
				if     (symb == :coast)    r = coast!(W=0.5, Vd=2)
				elseif (symb == :colorbar) r = colorbar!(pos=(anchor="MR",), B="af", Vd=2)
				elseif (symb == :logo)     r = logo!(Vd=2)
				end
			elseif (symb == :colorbar && (isa(val, String) || isa(val, Symbol)))
				t = lowercase(string(val)[1])		# Accept "Top, Bot, Left" but default to Right
				anc = (t == 't') ? "TC" : (t == 'b' ? "BC" : (t == 'l' ? "ML" : "MR"))
				r = colorbar!(pos=(anchor=anc,), B="af", Vd=2)
			elseif (symb == :clip)
				CTRL.pocket_call[1] = val;	r = "clip"
			end
			delete!(d, symb)
		end
		(r !== nothing) && append!(out, [r])
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
function get_color(val)::String
	# Parse a color input. Always return a string
	# color1,color2[,color3,…] colorn can be a r/g/b triplet, a color name, or an HTML hexadecimal color (e.g. #aabbcc
	if (isa(val, String) || isa(val, Symbol) || isa(val, Number))  return isa(val, Bool) ? "" : string(val)  end

	out = [""]
	if (isa(val, Tuple))
		for k = 1:length(val)
			if (isa(val[k], Tuple) && (length(val[k]) == 3))
				s = 1
				if (val[k][1] <= 1 && val[k][2] <= 1 && val[k][3] <= 1)  s = 255  end	# colors in [0 1]
				out[1] *= @sprintf("%.0f/%.0f/%.0f,", val[k][1]*s, val[k][2]*s, val[k][3]*s)
			elseif (isa(val[k], Symbol) || isa(val[k], String) || isa(val[k], Number))
				out[1] *= string(val[k],",")
			else
				error("Color tuples must have only one or three elements")
			end
		end
		out[1] = rstrip(out[1], ',')		# Strip last ','``
	elseif ((isa(val, Array) && (size(val, 2) == 3)) || (isa(val, Vector) && length(val) == 3))
		if (isa(val, Vector))  val = val'  end
		if (val[1,1] <= 1 && val[1,2] <= 1 && val[1,3] <= 1)
			copia = val .* 255		# Do not change the original
		else
			copia = val
		end
		out[1] = @sprintf("%.0f/%.0f/%.0f", copia[1,1], copia[1,2], copia[1,3])
		for k = 2:size(copia, 1)
			out[1] = @sprintf("%s,%.0f/%.0f/%.0f", out[1], copia[k,1], copia[k,2], copia[k,3])
		end
	else
		@warn("got this bad data type: $(typeof(val))")	# Need to split because f julia change in 6.1
		error("GOT_COLOR, got an unsupported data type")
	end
	return out[1]
end

# ---------------------------------------------------------------------------------------------------
function font(d::Dict, symbs)
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		font(val)
	end
end
function font(val)
	# parse and create a font string.
	# TODO: either add a NammedTuple option and/or guess if 2nd arg is the font name or the color
	# And this: Optionally, you may append =pen to the fill value in order to draw the text outline with
	# the specified pen; if used you may optionally skip the filling of the text by setting fill to -.
	(isa(val, String) || isa(val, Number)) && return string(val)

	s = ""
	if (isa(val, Tuple))
		s = parse_units(val[1])
		if (length(val) > 1)
			s = string(s,',',val[2])
			if (length(val) > 2)  s = string(s, ',', get_color(val[3]))  end
		end
	end
	return s
end

# ---------------------------------------------------------------------------------------------------
function parse_units(val)
	# Parse a units string in the form d|e|f|k|n|M|n|s or expanded
	(isa(val, String) || isa(val, Symbol) || isa(val, Number)) && return string(val)

	!(isa(val, Tuple) && (length(val) == 2)) && error("PARSE_UNITS, got and unsupported data type: $(typeof(val))")
	return string(val[1], parse_unit_unit(val[2]))
end

# ---------------------------
function parse_unit_unit(str)::String
	if (isa(str, Symbol))  str = string(str)  end
	!isa(str, String) && error("Argument data type must be String or Symbol but was: $(typeof(val))")

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
function data_type(val)
	# Parse data type for using in -b
	str = string(val)
#=
	if     (str == "char" || str =="int8")  out = "c"
	elseif (str == "uint8")   out = "u"
	elseif (str == "int16")   out = "h"
	elseif (str == "uint16")  out = "H"
	elseif (str == "int32")   out = "i"
	elseif (str == "uint32")  out = "I"
	elseif (str == "int64")   out = "l"
	elseif (str == "uint64")  out = "L"
	elseif (str == "float" || str == "float")  out = "f"
	elseif (str == "double")  out = "d"
	else                      out = "d"
	end
=#
	d = Dict("char" => "c", "int8" => "c", "uint8" => "u", "int16" => "h", "uint16" => "H", "int32" => "i", "uint32" => "I", "int64" => "l", "uint64" => "L", "float" => "f", "single" => "f", "double" => "d")
	out = haskey(d, str) ? d[str] : "d"
end

# ---------------------------------------------------------------------------------------------------
axis(nt::NamedTuple; x::Bool=false, y::Bool=false, z::Bool=false, secondary::Bool=false) = axis(;x=x, y=y, z=z, secondary=secondary, nt...)
function axis(;x::Bool=false, y::Bool=false, z::Bool=false, secondary::Bool=false, kwargs...)::String
	# Build the (terrible) -B option
	d = KW(kwargs)

	# Before anything else
	(haskey(d, :none)) && return " -B0"

	primo = secondary ? "s" : "p"					# Primary or secondary axis
	if (z)  primo = ""  end							# Z axis have no primary/secondary
	axe = x ? "x" : (y ? "y" : (z ? "z" : ""))		# Are we dealing with a specific axis?

	opt = [" -B"]
	if ((val = find_in_dict(d, [:frame :axes])[1]) !== nothing)
		if isa(val, Dict)  val = dict2nt(val)  end
		opt[1] *= helper0_axes(val)
	end

	if (haskey(d, :corners)) opt[1] *= string(d[:corners])  end	# 1234
	#if (haskey(d, :fill))    opt *= "+g" * get_color(d[:fill])  end
	val, symb = find_in_dict(d, [:fill :bg :background], false)
	if (val !== nothing)
		tB = "+g" * add_opt_fill(d, [symb])
		opt[1] *= tB					# Works, but patterns can screw
		CTRL.pocket_B[2] = tB			# Save this one because we may need to revert it during psclip parsing
	end
	if (GMTver > v"6.1")
		if ((val = find_in_dict(d, [:Xfill :Xbg :Xwall])[1]) !== nothing)  opt[1] = add_opt_fill(val, opt[1], "+x")  end
		if ((val = find_in_dict(d, [:Yfill :Ybg :Ywall])[1]) !== nothing)  opt[1] = add_opt_fill(val, opt[1], "+y")  end
		if ((p = add_opt_pen(d, [:wall_outline], "+w")) != "")  opt[1] *= p  end
	end
	if (haskey(d, :cube))    opt[1] *= "+b"  end
	if (haskey(d, :noframe)) opt[1] *= "+n"  end
	if (haskey(d, :pole))    opt[1] *= "+o" * arg2str(d[:pole])  end
	if (haskey(d, :title))   opt[1] *= "+t" * str_with_blancs(arg2str(d[:title]))  end

	if (opt[1] == " -B")  opt[1] = ""  end	# If nothing, no -B

	# axes supps
	ax_sup = ""
	if (haskey(d, :seclabel))   ax_sup *= "+s" * str_with_blancs(arg2str(d[:seclabel]))   end

	if (haskey(d, :label))
		opt[1] *= " -B" * primo * axe * "+l"  * str_with_blancs(arg2str(d[:label])) * ax_sup
	else
		if (haskey(d, :xlabel))  opt[1] *= " -B" * primo * "x+l" * str_with_blancs(arg2str(d[:xlabel])) * ax_sup  end
		if (haskey(d, :zlabel))  opt[1] *= " -B" * primo * "z+l" * str_with_blancs(arg2str(d[:zlabel])) * ax_sup  end
		if (haskey(d, :ylabel))
			opt[1] *= " -B" * primo * "y+l" * str_with_blancs(arg2str(d[:ylabel])) * ax_sup
		elseif (haskey(d, :Yhlabel))
			opt_L = (axe != "y") ? "y+L" : "+L"
			opt[1] *= " -B" * primo * axe * opt_L  * str_with_blancs(arg2str(d[:Yhlabel])) * ax_sup
		end
		haskey(d, :alabel) && (opt[1] *= " -Ba+l" * str_with_blancs(arg2str(d[:alabel])))	# For Ternary
		haskey(d, :blabel) && (opt[1] *= " -Bb+l" * str_with_blancs(arg2str(d[:blabel])))
		haskey(d, :clabel) && (opt[1] *= " -Bc+l" * str_with_blancs(arg2str(d[:clabel])))
	end

	# intervals
	ints = [""]
	if (haskey(d, :annot))      ints[1] *= "a" * helper1_axes(d[:annot])  end
	if (haskey(d, :annot_unit)) ints[1] *= helper2_axes(d[:annot_unit])   end
	if (haskey(d, :ticks))      ints[1] *= "f" * helper1_axes(d[:ticks])  end
	if (haskey(d, :ticks_unit)) ints[1] *= helper2_axes(d[:ticks_unit])   end
	if (haskey(d, :grid))       tB = "g" * helper1_axes(d[:grid]); ints[1] *= tB;	CTRL.pocket_B[1] = tB  end
	if (haskey(d, :prefix))     ints[1] *= "+p" * str_with_blancs(arg2str(d[:prefix]))  end
	if (haskey(d, :suffix))     ints[1] *= "+u" * str_with_blancs(arg2str(d[:suffix]))  end
	if (haskey(d, :slanted))
		s = arg2str(d[:slanted])
		if (s != "")
			if (!isnumeric(s[1]) && s[1] != '-' && s[1] != '+')
				s = s[1]
				(axe == "y" && s != 'p') && error("slanted option: Only 'parallel' is allowed for the y-axis")
			end
			ints[1] *= "+a" * s
		end
	end
	if (haskey(d, :custom))
		if (isa(d[:custom], String))  ints[1] *= 'c' * d[:custom]
		else
			if ((r = helper3_axes(d[:custom], primo, axe)) != "")  ints[1] *= 'c' * r  end
		end
	elseif (haskey(d, :customticks))			# These ticks are custom axis
		if ((r = ticks(d[:customticks]; axis=axe, primary=primo)) != "")  ints[1] *= 'c' * r  end
	elseif (haskey(d, :pi))
		if (isa(d[:pi], Number))
			ints[1] = string(ints[1], d[:pi], "pi")		# (n)pi
		elseif (isa(d[:pi], Array) || isa(d[:pi], Tuple))
			ints[1] = string(ints[1], d[:pi][1], "pi", d[:pi][2])	# (n)pi(m)
		end
	elseif (haskey(d, :scale))
		s = arg2str(d[:scale])
		if     (s == "log")  ints[1] *= 'l'
		elseif (s == "10log" || s == "pow")  ints[1] *= 'p'
		elseif (s == "exp")  ints[1] *= 'p'
		end
	end
	if (haskey(d, :phase_add))
		ints[1] *= "+" * arg2str(d[:phase_add])
	elseif (haskey(d, :phase_sub))
		ints[1] *= "-" * arg2str(d[:phase_sub])
	end
	if (ints[1] != "") opt[1] = " -B" * primo * axe * ints[1] * opt[1]  end

	# Check if ax_sup was requested
	if (opt[1] == "" && ax_sup != "")  opt[1] = " -B" * primo * axe * ax_sup  end

	return opt[1]
end

# ------------------------
function helper0_axes(arg)::String
	# Deal with the available ways of specifying the WESN(Z),wesn(z),lbrt(u)
	# The solution is very enginious and allows using "left_full", "l_full" or only "l_f"
	# to mean 'W'. Same for others:
	# bottom|bot|b_f(ull);  right|r_f(ull);  t(op)_f(ull);  up_f(ull)  => S, E, N, Z
	# bottom|bot|b_t(icks); right|r_t(icks); t(op)_t(icks); up_t(icks) => s, e, n, z
	# bottom|bot|b_b(are);  right|r_b(are);  t(op)_b(are);  up_b(are)  => b, r, t, u

	(isa(arg, String) || isa(arg, Symbol)) && return string(arg) # Assume that a WESNwesn was already sent in.

	(!isa(arg, Tuple)) &&
		error("The 'axes' argument must be a String, Symbol or a Tuple but was ($(typeof(arg)))")

	opt = "";	lbrtu = "lbrtu";	WSENZ = "WSENZ";	wsenz = "wsenz";	lbrtu = "lbrtu"
	for k = 1:length(arg)
		t = string(arg[k])		# For the case it was a symbol
		if (occursin("_f", t))
			for n = 1:5  (t[1] == lbrtu[n]) && (opt *= WSENZ[n]; continue)  end
		elseif (occursin("_t", t))
			for n = 1:5  (t[1] == lbrtu[n]) && (opt *= wsenz[n]; continue)  end
		elseif (occursin("_b", t))
			for n = 1:5  (t[1] == lbrtu[n]) && (opt *= lbrtu[n]; continue)  end
		end
	end
	return opt
end

# ------------------------
function helper1_axes(arg)::String
	# Used by annot, ticks and grid to accept also 'auto' and "" to mean automatic
	out = arg2str(arg)
	if (out != "" && out[1] == 'a')  out = ""  end
	return out
end
# ------------------------
function helper2_axes(arg)::String
	# Used by
	out = arg2str(arg)
	if (out == "")
		@warn("Empty units. Ignoring this units request.");		return out
	end
	if     (out == "Y" || out == "year")     out = "Y"
	elseif (out == "y" || out == "year2")    out = "y"
	elseif (out == "O" || out == "month")    out = "O"
	elseif (out == "o" || out == "month2")   out = "o"
	elseif (out == "U" || out == "ISOweek")  out = "U"
	elseif (out == "u" || out == "ISOweek2") out = "u"
	elseif (out == "r" || out == "Gregorian_week") out = "r"
	elseif (out == "K" || out == "ISOweekday") out = "K"
	elseif (out == "k" || out == "weekday")  out = "k"
	elseif (out == "D" || out == "date")     out = "D"
	elseif (out == "d" || out == "day_date") out = "d"
	elseif (out == "R" || out == "day_week") out = "R"
	elseif (out == "H" || out == "hour")     out = "H"
	elseif (out == "h" || out == "hour2")    out = "h"
	elseif (out == "M" || out == "minute")   out = "M"
	elseif (out == "m" || out == "minute2")  out = "m"
	elseif (out == "S" || out == "second")   out = "S"
	elseif (out == "s" || out == "second2")  out = "s"
	else
		@warn("Unknown units request (" * out * ") Ignoring it")
		out = ""
	end
	return out
end
# ------------------------------------------------------------
function helper3_axes(arg, primo::String, axe::String)::String
	# Parse the custom annotations arg, save result into a tmp file and return its name

	label = ""
	if (isa(arg, AbstractArray))
		pos, n_annot = arg, length(pos)
		tipo = fill('a', n_annot)			# Default to annotate
	elseif (isa(arg, NamedTuple) || isa(arg, Dict))
		if (isa(arg, NamedTuple))  d = nt2dict(arg)  end
		!haskey(d, :pos) && error("Custom annotations NamedTuple must contain the member 'pos'")
		pos = d[:pos]
		n_annot = length(pos);		got_tipo = false
		if ((val = find_in_dict(d, [:type])[1]) !== nothing)
			if (isa(val, Char) || isa(val, String) || isa(val, Symbol))
				tipo = Vector{String}(undef, n_annot)
				[tipo[k] = string(val) for k = 1:n_annot]	# Repeat the same 'type' n_annot times
			else
				tipo = val		# Assume it's a good guy, otherwise ...
			end
			got_tipo = true
		end

		if (haskey(d, :label))
			if (length(d[:label]) != n_annot)
				error("Number of labels in custom annotations must be the same as the 'pos' element")
			end
			label = d[:label]
			tipo = Vector{String}(undef, n_annot)
			for k = 1:n_annot
				if (isa(label[k], Symbol) || label[k][1] != '/')
					tipo[k] = "a"
				else
					t = split(label[k])
					tipo[k] = t[1][2:end]
					if (length(t) > 1)
						label[k] = join([t[n] * " " for n =2:length(t)])
						label[k] = rstrip(label[k], ' ')		# and remove last ' '
					else
						label[k] = ""
					end
				end
			end
		elseif (!got_tipo)
			tipo = fill("a", n_annot)		# Default to annotate
		end
	else
		@warn("Argument of the custom annotations must be an N-array or a NamedTuple");		return ""
	end

	temp = "GMTjl_custom_" * primo
	if (axe != "") temp *= axe  end
	fname = joinpath(tempdir(), temp * ".txt")
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

# ---------------------------------------------------
xticks(labels, pos=nothing) = ticks(labels, pos; axis="x")
yticks(labels, pos=nothing) = ticks(labels, pos; axis="y")
zticks(labels, pos=nothing) = ticks(labels, pos; axis="z")
function ticks(labels, pos=nothing; axis="x", primary="p")
	# Simple plot of custom ticks.
	# LABELS can be an Array or Tuple of strinfs or symbols with the labels to be plotted at ticks in POS
	if (isa(labels, Tuple) && length(labels) == 2 && isa(labels[1], AbstractArray))
		r = helper3_axes((pos=labels[1], label=labels[2]), primary, axis)
	else
		_pos = (pos === nothing) ? (1:length(labels)) : pos
		r = helper3_axes((pos=_pos, label=labels), primary, axis)
	end
	r
end
# ---------------------------------------------------------------------------------------------------

function str_with_blancs(str)::String
	# If the STR string has spaces enclose it with quotes
	out = string(str)
	if (occursin(" ", out) && !startswith(out, "\""))  out = string("\"", out, "\"")  end
	return out
end

# ---------------------------------------------------------------------------------------------------
vector_attrib(d::Dict, lixo=nothing) = vector_attrib(; d...)	# When comming from add_opt()
vector_attrib(t::NamedTuple) = vector_attrib(; t...)
function vector_attrib(;kwargs...)::String
	d = KW(kwargs)
	cmd = add_opt(d, "", "", [:len :length])
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
		else
			cmd *= "+g" * get_color(d[:fill])		# MUST GET TESTS TO THIS
			if (!haskey(d, :pen))  cmd = cmd * "+p"  end 	# Let FILL paint the whole header (contrary to >= GMT6.1)
		end
	end

	if (haskey(d, :norm))  cmd = string(cmd, "+n", d[:norm])  end

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
			(d[:shape] < -2 || d[:shape] > 2) && error("Numeric shape code must be in the [-2 2] interval.")
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
function vector4_attrib(; kwargs...)::String
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
		if isa(val, Dict)  val = dict2nt(val)  end
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
function helper_vec_loc(d::Dict, symb, cmd::String)::String
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
function decorated(;kwargs...)::String
	d = KW(kwargs)
	cmd, optD = helper_decorated(d)

	if (haskey(d, :dec2))				# -S~ mode (decorated, with symbols, lines).
		cmd *= ":"
		marca = get_marker_name(d, nothing, [:marker, :symbol], false)[1]	# This fun lieves in psxy.jl
		if (marca == "")
			cmd = "+sa0.5" * cmd
		else
			cmd *= "+s" * marca
			if ((val = find_in_dict(d, [:size :ms :markersize :symbsize :symbolsize])[1]) !== nothing)
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
			if (isa(val, Array{<:Real}))
				(size(val,2) !=4) && error("DECORATED: 'line' option. When array, it must be an Mx4 one")
				optD = string(flag,val[1,1],'/',val[1,2],'/',val[1,3],'/',val[1,4])
				for k = 2:size(val,1)
					optD = string(optD,',',val[k,1],'/',val[k,2],'/',val[k,3],'/',val[k,4])
				end
			elseif (isa(val, Tuple))
				if (length(val) == 2 && (isa(val[1], String) || isa(val[1], Symbol)) )
					t1 = string(val[1]);	t2 = string(val[2])		# t1/t2 can also be 2 char or a LongWord justification
					t1 = startswith(t1, "min") ? "Z-" : justify(t1)
					t2 = startswith(t2, "max") ? "Z+" : justify(t2)
					optD = flag * t1 * "/" * t2
				else
					optD = flag * arg2str(val)
				end
			elseif (isa(val, String))
				optD = flag * val
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
function parse_quoted(d::Dict, opt)::String
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
function fname_out(d::Dict, del::Bool=false)
	# Create a file name in the TMP dir when OUT holds only a known extension. The name is: GMTjl_tmp.ext

	EXT = FMT[1];	fname = ""
	if ((val = find_in_dict(d, [:savefig :figname :name], del)[1]) !== nothing)
		fname, EXT = splitext(string(val))
		EXT = (EXT == "") ? FMT[1] : EXT[2:end]
	end
	if (EXT == FMT[1] && haskey(d, :fmt))
		EXT = string(d[:fmt])
		(del) && delete!(d, :fmt)
	end
	(EXT == "" && !Sys.iswindows()) && error("Return an image is only for Windows")
	(1 == length(EXT) > 3) && error("Bad graphics file extension")

	if (haskey(d, :ps))			# In any case this means we want the PS sent back to Julia
		fname, EXT, ret_ps = "", "ps", true
		(del) && delete!(d, :ps)
	else
		ret_ps = false			# To know if we want to return or save PS in mem
	end

	opt_T = "";
	if (fname != "" || haskey(d, :show) && d[:show] != 0)	# Only last command (either show or save) may set -T
		(EXT == "pdfg" || EXT == "gpdf") && (EXT = "pdg")	# Trick to keep the ext with only 3 chars (for GeoPDFs)
		ext = lowercase(EXT)
		if     (ext == "ps")   EXT = ext
		elseif (ext == "pdf")  opt_T = " -Tf";	EXT = ext
		elseif (ext == "eps")  opt_T = " -Te";	EXT = ext
		elseif (EXT == "PNG")  opt_T = " -TG";	EXT = "png"		# Don't want it to be .PNG
		elseif (ext == "png")  opt_T = " -Tg";	EXT = ext
		elseif (ext == "jpg")  opt_T = " -Tj";	EXT = ext
		elseif (ext == "tif")  opt_T = " -Tt";	EXT = ext
		elseif (ext == "tiff") opt_T = " -Tt -W+g";	EXT = ext
		elseif (ext == "kml")  opt_T = " -Tt -W+k";	EXT = ext
		elseif (ext == "pdg")  opt_T = " -Tf -Qp";	EXT = "pdf"
		else   error("Unknown graphics file extension (.$EXT)")
		end
	end

	if (fname != "")  fname *= "." * EXT  end
	def_name = joinpath(tempdir(), "GMTjl_tmp.ps")
	return def_name, opt_T, EXT, fname, ret_ps
end

# These methods are function barriers to stop the type instability to propagate. Unfortunately, a similar
# solution but at the end of the main function, that would cover all cases, is IRRITATINGLY ignored by Julia
read_data(d::Dict, fname::String, cmd::String, arg::Vector{GMTdataset}, opt_R::String="", is3D::Bool=false, get_info::Bool=false)::Tuple{String, Vector{GMTdataset}, String, Vector{GMTdataset}, String} = _read_data(d, fname, cmd, arg, opt_R, is3D, get_info)

read_data(d::Dict, fname::String, cmd::String, arg::GMTdataset, opt_R::String="", is3D::Bool=false, get_info::Bool=false)::Tuple{String, GMTdataset, String, Vector{GMTdataset}, String} = _read_data(d, fname, cmd, arg, opt_R, is3D, get_info)

read_data(d::Dict, fname::String, cmd::String, arg::Matrix{Float64}, opt_R::String="", is3D::Bool=false, get_info::Bool=false)::Tuple{String, Matrix{Float64}, String, Vector{GMTdataset}, String} = _read_data(d, fname, cmd, arg, opt_R, is3D, get_info)

read_data(d::Dict, fname::String, cmd::String, arg::Matrix{Any}, opt_R::String="", is3D::Bool=false, get_info::Bool=false)::Tuple{String, Matrix{Float64}, String, Vector{GMTdataset}, String} = _read_data(d, fname, cmd, arg, opt_R, is3D, get_info)

read_data(d::Dict, fname::String, cmd::String, arg::Vector{DateTime}, opt_R::String="", is3D::Bool=false, get_info::Bool=false)::Tuple{String, Vector{Float64}, String, Vector{GMTdataset}, String} = _read_data(d, fname, cmd, arg, opt_R, is3D, get_info)

# This is the fall-back method. Unfortunately, I've not found a solution that covers the passing in of a file name
# because we fall in the same situation as with passing the input data via the 'data' kw, and this one can have any type.
read_data(d::Dict, fname::String, cmd::String, arg, opt_R::String="", is3D::Bool=false, get_info::Bool=false) = _read_data(d, fname, cmd, arg, opt_R, is3D, get_info)

# ---------------------------------------------------------------------------------------------------
function _read_data(d::Dict, fname::String, cmd::String, arg, opt_R::String="", is3D::Bool=false, get_info::Bool=false)
	# In case DATA holds a file name, read that data and put it in ARG
	# Also compute a tight -R if this was not provided

	(show_kwargs[1]) && return cmd, arg, opt_R, Vector{GMTdataset}(), ""		# In HELP mode we do nothing here

	(IamModern[1] && FirstModern[1]) && (FirstModern[1] = false)
	force_get_R = (IamModern[1] && GMTver > v"6") ? false : true	# GMT6.0 BUG, modern mode does not auto-compute -R
	#force_get_R = true		# Due to a GMT6.0 BUG, modern mode does not compute -R automatically and 6.1 is not good too

	cmd, opt_i  = parse_i(d, cmd)		# If data is to be read with some column order
	cmd, opt_bi = parse_bi(d, cmd)		# If data is to be read as binary
	cmd, opt_di = parse_di(d, cmd)		# If data missing data other than NaN
	cmd, opt_h  = parse_h(d, cmd)
	cmd, opt_yx = parse_swap_xy(d, cmd)
	(CTRL.proj_linear[1]) && (opt_yx *= " -fc")			# To avoid the lib remembering last eventual geog case
	if (endswith(opt_yx, "-:"))  opt_yx *= "i"  end		# Need to be -:i not -: to not swap output too
	if (fname != "")
		if (((!IamModern[1] && opt_R == "") || get_info) && !convert_syntax[1])		# Must read file to find -R
			if (!IamSubplot[1] || GMTver > v"6.1.1")		# Protect against a GMT bug
				arg = gmt("read -Td " * opt_i * opt_bi * opt_di * opt_h * opt_yx * " " * fname)
				# Remove the these options from cmd. Their job is done
				if (opt_i != "")  cmd = replace(cmd, opt_i => "");	opt_i = ""  end
				if (opt_h != "")  cmd = replace(cmd, opt_h => "");	opt_h = ""  end
			end
		else							# No need to find -R so let the GMT module read the file
			cmd = fname * " " * cmd
		end
	elseif (haskey(d, :data))
		arg = d[:data];		del_from_dict(d, [:data])
	end

	# See if we have DateTime objects
	got_datetime, is_onecol = false, false
	if (isa(arg, Vector{DateTime}))					# Must convert to numeric
		min_max = round_datetime(extrema(arg))		# Good numbers for limits
		arg = Dates.value.(arg) ./ 1000;			cmd *= " --TIME_SYSTEM=dr0001"
		got_datetime, is_onecol = true, true
	elseif (isa(arg, Matrix{Any}) && typeof(arg[1]) == DateTime)	# Matrix with DateTime in first col
		min_max = round_datetime(extrema(view(arg, :, 1)))
		arg[:,1] = Dates.value.(arg[:,1]) ./ 1000;	cmd *= " --TIME_SYSTEM=dr0001"
		t = Array{Float64, 2}(undef, size(arg))
		[t[k] = arg[k] for k in eachindex(arg)]
		arg, got_datetime = t, true
	end

	have_info = false
	no_R = (opt_R == "" || opt_R[1] == '/' || opt_R == " -Rtight")
	if (((!IamModern[1] && no_R) || (force_get_R && no_R)) && !convert_syntax[1])
		info::Vector{GMTdataset} = gmt("gmtinfo -C" * opt_bi * opt_i * opt_di * opt_h * opt_yx, arg)	# Here we are reading from an original GMTdataset or Array
		have_info = true
		if (info[1].data[1] > info[1].data[2])		# Workaround a bug/feature in GMT when -: is arround
			info[1].data[2], info[1].data[1] = info[1].data[1], info[1].data[2]
		end
		if (opt_R != "" && opt_R[1] == '/')			# Modify what will be reported as a -R string
			rs = split(opt_R, '/')
			if (!occursin("?", opt_R))
				# Example "///0/" will set y_min=0 if info.data[3] > 0 and no other changes otherwise
				for k = 2:length(rs)
					(rs[k] == "") && continue
					x = parse(Float64, rs[k])
					if (x == 0.0)
						info[1].data[k-1] = (info[1].data[k-1] > 0) ? 0 : info[1].data[k-1]
					end
				end
			else
				# Example: "/1/2/?/?"  Retain x_min = 1 & x_max = 2 and get y_min|max from data. Used by plotyy
				for k = 2:length(rs)
					(rs[k] != "?") && (info[1].data[k-1] = parse(Float64, rs[k]))	# Keep value already in previous -R
				end
			end
		end
		if (opt_R != " -Rtight")
			if (!occursin("?", opt_R) && !is_onecol)		# is_onecol is true only for DateTime data
				dx = (info[1].data[2] - info[1].data[1]) * 0.005;	dy = (info[1].data[4] - info[1].data[3]) * 0.005;
				info[1].data[1] -= dx;	info[1].data[2] += dx;	info[1].data[3] -= dy;	info[1].data[4] += dy;
				info[1].data = round_wesn(info[1].data)		# Add a pad if not-tight
			elseif (!is_onecol)
				t = round_wesn(info[1].data)		# Add a pad
				[info[1].data[k-1] = t[k-1] for k = 2:length(rs) if (rs[k] == "?")]
			end
		else
			cmd = replace(cmd, " -Rtight" => "")	# Must remove old -R
		end
		if (got_datetime)
			opt_R = " -R" * Dates.format(min_max[1], "yyyy-mm-ddTHH:MM:SS.s") * "/" *
			        Dates.format(min_max[2], "yyyy-mm-ddTHH:MM:SS.s")
			(!is_onecol) && (opt_R *= sprintf("/%.12g/%.12g", info[1].data[3], info[1].data[4]))
		elseif (is3D)
			opt_R = @sprintf(" -R%.12g/%.12g/%.12g/%.12g/%.12g/%.12g", info[1].data[1], info[1].data[2],
			                 info[1].data[3], info[1].data[4], info[1].data[5], info[1].data[6])
		else
			opt_R = sprintf(" -R%.12g/%.12g/%.12g/%.12g", info[1].data[1], info[1].data[2],
			                 info[1].data[3], info[1].data[4])
		end
		(!is_onecol) && (cmd *= opt_R)		# The onecol case (for histogram) has an imcomplete -R
	end

	if (get_info && !have_info && !convert_syntax[1])
		info = gmt("gmtinfo -C" * opt_bi * opt_i * opt_di * opt_h * opt_yx, arg)
		if (info[1].data[1] > info[1].data[2])		# Workaround a bug/feature in GMT when -: is arround
			info[1].data[2], info[1].data[1] = info[1].data[1], info[1].data[2]
		end
	elseif (!have_info)
		info = Vector{GMTdataset}()			# Need something to return
	end

	return cmd, arg, opt_R, info, opt_i
end

# ---------------------------------------------------------------------------------------------------
round_wesn(wesn::Array{Int}, geo::Bool=false) = round_wesn(float(wesn), geo)
function round_wesn(wesn::Array{Float64, 2}, geo::Bool=false)::Array{Float64, 2}
	# When input is an one row matix return an output of same size
	_wesn = wesn[:]
	_wesn = round_wesn(_wesn, geo)
	reshape(_wesn, 1, length(_wesn))
end
function round_wesn(_wesn::Vector{Float64}, geo::Bool=false)::Vector{Float64}
	# Use data range to round to nearest reasonable multiples
	# If wesn has 6 elements (is3D), last two are not modified.
	wesn = deepcopy(_wesn)		# To not change the input
	set = zeros(Bool, 2)
	range = [0.0, 0.0]
	if (wesn[1] == wesn[2])
		wesn[1] -= abs(wesn[1]) * 0.1;	wesn[2] += abs(wesn[2]) * 0.1
		if (wesn[1] == wesn[2])  wesn[1] = -0.1;	wesn[2] = 0.1;	end		# x was = 0
	end
	if (wesn[3] == wesn[4])
		wesn[3] -= abs(wesn[3]) * 0.1;	wesn[4] += abs(wesn[4]) * 0.1
		if (wesn[3] == wesn[4])  wesn[3] = -0.1;	wesn[4] = 0.1;	end		# y was = 0
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
		set[side] && continue			# Done above */
		mag = round(log10(range[side])) - 1.0
		inc = 10.0^mag
		if ((range[side] / inc) > 10.0) inc *= 2.0	end	# Factor of 2 in the rounding
		if ((range[side] / inc) > 10.0) inc *= 2.5	end	# Factor of 5 in the rounding
		s = 1.0
		if (geo) 	# Use arc integer minutes or seconds if possible
			if (inc < 1.0 && inc > 0.05) 				# Nearest arc minute
				s, inc = 60.0, 1.0
				if ((s * range[side] / inc) > 10.0) inc *= 2.0	end		# 2 arcmin
				if ((s * range[side] / inc) > 10.0) inc *= 2.5	end		# 5 arcmin
			elseif (inc < 0.1 && inc > 0.005) 			# Nearest arc second
				s, inc = 3600.0, 1.0
				if ((s * range[side] / inc) > 10.0) inc *= 2.0	end		# 2 arcsec
				if ((s * range[side] / inc) > 10.0) inc *= 2.5	end		# 5 arcsec
			end
			wesn[item] = (floor(s * wesn[item] / inc) * inc) / s;	item += 1;
			wesn[item] = (ceil(s * wesn[item] / inc) * inc) / s;	item += 1;
		else
			# Round BB to the next fifth of a decade.
			one_fifth_dec = inc / 5					# One fifth of a decade
			x = (floor(wesn[item] / inc) * inc);
			wesn[item] = x - ceil((x - wesn[item]) / one_fifth_dec) * one_fifth_dec;	item += 1
			x = (ceil(wesn[item] / inc) * inc);
			wesn[item] = x - floor((x - wesn[item]) / one_fifth_dec) * one_fifth_dec;	item += 1
		end
	end
	return wesn
end

# ---------------------------------------------------------------------------------------------------
"""
Round a Vector or Tuple (2 elements) of DateTime type to a nearest nice number to use in plot limits
"""
round_datetime(val::Tuple{DateTime, DateTime}) = round_datetime([val[1], val[2]])
function round_datetime(val::Array{DateTime})
	r = Dates.value(val[end] - val[1])
	if (r > 86400000 * 365.25)  rfac = Dates.Year;		add = Dates.Year(1)
	elseif (r > 86400000 * 31)  rfac = Dates.Month;		add = Dates.Month(1)
	elseif (r > 86400000 * 7)   rfac = Dates.Week;		add = Dates.Week(1)
	elseif (r > 86400000)       rfac = Dates.Day;		add = Dates.Day(1)
	elseif (r > 3600000)        rfac = Dates.Hour;		add = Dates.Hour(1)
	elseif (r > 60000)          rfac = Dates.Minute;	add = Dates.Minute(1)
	elseif (r > 1000)           rfac = Dates.Second;	add = Dates.Second(1)
	else                        rfac = Dates.Millisecond;	add = Dates.Millisecond(1)
	end
	out = [floor(val[1], rfac)-add, ceil(val[end], rfac)+add]
end

#= ---------------------------------------------------------------------------------------------------
function round_pretty(val)
	log = floor(log10(val))
	frac = (log > 1) ? 4 : 1		# This keeps from adding digits after the decimal
	round(val * frac * 10^ -log) / frac / 10^-log
end
=#

# ---------------------------------------------------------------------------------------------------
function isvector(x)::Bool
	# Return true if x is a vector in the Matlab sense
	isa(x, Vector) || (isa(x, Array) && ( ((size(x,1) == 1) && size(x,2) > 1) || ((size(x,1) > 1) && size(x,2) == 1) ))
end

# ---------------------------------------------------------------------------------------------------
function find_data(d::Dict, cmd0::String, cmd::String, args...)
	# ...
	
	(show_kwargs[1]) && return cmd, 0, nothing		# In HELP mode we do nothing here

	got_fname = 0;		data_kw = nothing
	if (haskey(d, :data))  data_kw = d[:data];  delete!(d, :data)  end
	if (cmd0 != "")						# Data was passed as file name
		cmd = cmd0 * " " * cmd
		got_fname = 1
	end

	write_data(d, cmd)			# Check if we need to save to file

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
			(args[1] === nothing && data_kw === nothing) &&
				return cmd, 1, args[1], args[2]		# got_fname = 1 => all data is in cmd
			(args[1] !== nothing) &&
				return cmd, 2, args[1], args[2]		# got_fname = 2 => data is in cmd and arg1
			(data_kw !== nothing && length(data_kw) == 1) &&
				return cmd, 2, data_kw, args[2]		# got_fname = 2 => data is in cmd and arg1
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
			(args[1] !== nothing || data_kw !== nothing) && error("Cannot mix input as file names and numeric data.")
			return cmd, 1, args[1], args[2], args[3]			# got_fname = 1 => all data is in cmd
		else
			(args[1] === nothing && args[2] === nothing && args[3] === nothing) &&
				return cmd, 0, args[1], args[2], args[3]			# got_fname = 0 => ???
			(data_kw !== nothing && length(data_kw) == 3) &&
				return cmd, 0, data_kw[1], data_kw[2], data_kw[3]	# got_fname = 0 => all data in arg1,2,3

			return cmd, 0, args[1], args[2], args[3]
		end
	end
end

# ---------------------------------------------------------------------------------------------------
function write_data(d::Dict, cmd::String)
	# Check if we need to save to file (redirect stdout)
	if     ((val = find_in_dict(d, [:|>])[1])     !== nothing)  cmd = string(cmd, " > ", val)
	elseif ((val = find_in_dict(d, [:write])[1])  !== nothing)  cmd = string(cmd, " > ", val)
	elseif ((val = find_in_dict(d, [:append])[1]) !== nothing)  cmd = string(cmd, " >> ", val)
	end
	return cmd
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
	if (IamModern[1])  cmd = replace(cmd, " -R " => " ")  end
	(dbg_print_cmd(d, cmd) !== nothing) && return cmd		# Vd=2 cause this return
	# First case below is of a ARGS tuple(tuple) with all numeric inputs.
	R = isa(args, Tuple{Tuple}) ? gmt(cmd, args[1]...) : gmt(cmd, args...)
	show_non_consumed(d, cmd)
	return R
end

# ---------------------------------------------------------------------------------------------------
dbg_print_cmd(d::Dict, cmd::String) = dbg_print_cmd(d, [cmd])
function dbg_print_cmd(d::Dict, cmd::Vector{String})
	# Print the gmt command when the Vd>=1 kwarg was used.
	# In case of convert_syntax = true, just put the cmds in a global var 'cmds_history' used in movie

	if (show_kwargs[1])  show_kwargs[1] = false; return ""  end	# If in HELP mode

	if ( ((Vd = find_in_dict(d, [:Vd])[1]) !== nothing) || convert_syntax[1])
		(convert_syntax[1]) && return update_cmds_history(cmd)	# For movies mainly.
		(Vd <= 0) && return nothing		# Don't let user play tricks

		if (Vd >= 2)	# Delete these first before reporting
			del_from_dict(d, [[:show], [:leg :legend], [:box_pos], [:leg_pos], [:figname], [:name], [:savefig]])
		end
		if (length(d) > 0)
			dd = deepcopy(d)		# Make copy so that we can harmlessly delete those below
			del_from_dict(dd, [[:show], [:leg :legend], [:box_pos], [:leg_pos], [:fmt :savefig :figname :name]])
			prog = isa(cmd, String) ? split(cmd)[1] : split(cmd[1])[1]
			(length(dd) > 0) && println("Warning: the following options were not consumed in $prog => ", keys(dd))
		end
		(Vd == 1) && println("\t", length(cmd) == 1 ? cmd[1] : cmd)
		(Vd >= 2) && return length(cmd) == 1 ? cmd[1] : cmd
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function update_cmds_history(cmd::Vector{String})
	# Separate into fun to work as a function barrier for var stability
	global cmds_history
	cmd_ = cmd[1]			# AND WHAT ABOUT THE OTHER ELEMENTS? DO THEY EXIST?
	if (length(cmds_history) == 1 && cmds_history[1] == "")		# First time here
		cmds_history[1] = cmd_
	else
		push!(cmds_history, cmd_)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function showfig(d::Dict, fname_ps::String, fname_ext::String, opt_T::String, K::Bool=false, fname::String="")
	# Take a PS file, convert it with psconvert (unless opt_T == "" meaning file is PS)
	# and display it in default system viewer
	# FNAME_EXT holds the extension when not PS
	# OPT_T holds the psconvert -T option, again when not PS
	# FNAME is for when using the savefig option

	global current_cpt[1] = GMTcpt()		# Reset to empty when fig is finalized
	if (fname == "" && (isdefined(Main, :IJulia) && Main.IJulia.inited) ||
	                    isdefined(Main, :PlutoRunner) && Main.PlutoRunner isa Module)
		opt_T = " -Tg"; fname_ext = "png"		# In Jupyter or Pluto, png only
	end
	if (opt_T != "")
		if (K) close_PS_file(fname_ps)  end		# Close the PS file first
		if ((val = find_in_dict(d, [:dpi :DPI])[1]) !== nothing)  opt_T *= string(" -E", val)  end
		gmt("psconvert -A1p -Qg4 -Qt4 " * fname_ps * opt_T * " *")
		out = fname_ps[1:end-2] * fname_ext
		if (fname != "")  out = mv(out, fname, force=true)  end
	elseif (fname_ps != "")
		if (K) close_PS_file(fname_ps)  end		# Close the PS file first
		out = (fname != "") ? mv(fname_ps, fname, force=true) : fname_ps
	end

	if (haskey(d, :show) && d[:show] != 0)
		if (isdefined(Main, :IJulia) && Main.IJulia.inited)		# From Jupyter?
			if (fname == "") display("image/png", read(out))
			else             @warn("In Jupyter you can only visualize png files. File $fname was saved in disk though.")
			end
		elseif isdefined(Main, :PlutoRunner) && Main.PlutoRunner isa Module
			return WrapperPluto(out)		# This return must make it all way down to base so that Plut displays it
		else
			@static if (Sys.iswindows()) out = replace(out, "/" => "\\"); run(ignorestatus(`explorer $out`))
			elseif (Sys.isapple()) run(`open $(out)`)
			elseif (Sys.islinux() || Sys.isbsd()) run(`xdg-open $(out)`)
			end
		end
		(ThemeIsOn[1]) && (reset_defaults(API);	ThemeIsOn[1] = false)
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
# Use only to close PS fig and optionally convert/show
function showfig(; kwargs...)
	d = KW(kwargs)
	if (!haskey(d, :show))  d[:show] = true  end		# The default is to show
	finish_PS_module(d, "psxy -R0/1/0/1 -JX0.001c -T -O", "", false, true, true)
end

# ---------------------------------------------------------------------------------------------------
function close_PS_file(fname::AbstractString)
	(GMTver > v"6.1.1") ? gmt("psxy -T -O >> " * fname) : gmt("psxy -T -R0/1/0/1 -JX0.001 -O >> " * fname)
	# Do the equivalent of "psxy -T -O"
	#=
	fid = open(fname, "a")
	write(fid, "\n0 A\nFQ\nO0\n0 0 TM\n\n")
	write(fid, "%%BeginObject PSL_Layer_2\n0 setlinecap\n0 setlinejoin\n3.32550952342 setmiterlimit\n%%EndObject\n")
	write(fid, "\ngrestore\nPSL_movie_label_completion /PSL_movie_label_completion {} def\n")
	write(fid, "PSL_movie_prog_indicator_completion /PSL_movie_prog_indicator_completion {} def\n")
	write(fid, "%PSL_Begin_Trailer\n%%PageTrailer\nU\nshowpage\n\n%%Trailer\n\nend\n%%EOF")
	close(fid)
	=#
end

# ---------------------------------------------------------------------------------------------------
function isempty_(arg)
	# F... F... it's a shame having to do this
	(arg === nothing) && return true
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
finish_PS_module(d::Dict, cmd::String, opt_extra::String, K::Bool, O::Bool, finish::Bool, args...) =
	finish_PS_module(d, [cmd], opt_extra, K, O, finish, args...)
function finish_PS_module(d::Dict, cmd::Vector{String}, opt_extra::String, K::Bool, O::Bool, finish::Bool, args...)
	# FNAME_EXT hold the extension when not PS
	# OPT_EXTRA is used by grdcontour -D or pssolar -I to not try to create and view an img file

	#while (length(args) > 1 && args[end] === nothing)  pop!(args)  end		# Remove trailing nothings

	output, opt_T, fname_ext, fname, ret_ps = fname_out(d, true)
	if (ret_ps)  output = ""  end  						# Here we don't want to save to file
	cmd, opt_T = prepare2geotif(d, cmd, opt_T, O)		# Settings for the GeoTIFF and KML cases
	if (finish)  cmd = finish_PS(d, cmd, output, K, O)  end

	if ((r = dbg_print_cmd(d, cmd)) !== nothing)  return length(r) == 1 ? r[1] : r  end 	# For tests only
	img_mem_layout[1] = add_opt(d, "", "", [:layout])
	if (img_mem_layout[1] == "images")  img_mem_layout[1] = "I   "  end	# Special layout for Images.jl

	if (fname_ext != "ps" && !IamModern[1])				# Exptend to a larger paper size (5 x A0)
		cmd[1] *= " --PS_MEDIA=11920x16850"				# In Modern mode GMT takes care of this.
	end

	for k = 1:length(cmd)
		is_psscale = (startswith(cmd[k], "psscale") || startswith(cmd[k], "colorbar"))
		is_pscoast = (startswith(cmd[k], "pscoast") || startswith(cmd[k], "coast"))
		is_basemap = (startswith(cmd[k], "psbasemap") || startswith(cmd[k], "basemap"))
		if (k > 1 && is_psscale && !isa(args[1], GMTcpt))	# Ex: imshow(I, cmap=C, colorbar=true)
			cmd2, arg1, = add_opt_cpt(d, cmd[k], [:C :color :cmap], 'C', 0, nothing, nothing, false, false, "", true)
			(arg1 === nothing) && (@warn("No cmap found to use in colorbar. Ignoring this command."); continue)
			P = gmt(cmd[k], arg1)
			continue
		elseif (k > 1 && (is_pscoast || is_basemap) && (isa(args[1], GMTimage) || isa(args[1], GMTgrid)))
			proj4 = args[1].proj4
			(proj4 == "" && args[1].wkt != "") && (proj4 = toPROJ4(importWKT(args[1].wkt)))
			if ((proj4 != "") && !startswith(proj4, "+proj=lat") && !startswith(proj4, "+proj=lon"))
				opt_J = replace(proj4, " " => "")
				lims = args[1].range
				D::Vector{GMTdataset} = mapproject([lims[1] lims[3]; lims[2] lims[4]], J=opt_J, I=true)
				mm = extrema(D[1].data, dims=1)
				xmi::Float64, ymi::Float64, xma::Float64, yma::Float64 = mm[1][1],mm[2][1],mm[1][2],mm[2][2]
				opt_R::String = sprintf(" -R%f/%f/%f/%f+r ", xmi,ymi,xma,yma)
				o = scan_opt(cmd[1], "-J")
				if     (o[1] == 'x')  size_ = "+scale=" * o[2:end]
				elseif (o[1] == 'X')  size_ = "+width=" * o[2:end]
				else   @warn("Could not find the right fig size used. Result will be wrong");  size_ = ""
				end
				cmd[k] = replace(cmd[k], " -J" => " -J" * opt_J * size_)
				cmd[k] = replace(cmd[k], " -R" => opt_R)
			end
		elseif (k > 1 && !is_psscale && !is_pscoast && !is_basemap && CTRL.pocket_call[1] !== nothing)
			# For nested calls that need to pass data
			P = gmt(cmd[k], CTRL.pocket_call[1])
			CTRL.pocket_call[1] = nothing					# Clear it right away
			continue
		elseif (startswith(cmd[k], "psclip"))		# Shitty case. Pure (unique) psclip requires args. Compose cmd not
			P = (CTRL.pocket_call[1] !== nothing) ? gmt(cmd[k], CTRL.pocket_call[1]) :
			                                        (length(cmd) > 1) ? gmt(cmd[k]) : gmt(cmd[k], args...)
			CTRL.pocket_call[1] = nothing					# For the case it was not yet empty
			continue
		end
		P = gmt(cmd[k], args...)
	end

	(!IamModern[1]) && digests_legend_bag(d, true)			# Plot the legend if requested

	if (usedConfPar[1])				# Hacky shit to force start over when --PAR options were use
		usedConfPar[1] = false;		gmt("destroy")
	end

	if (!IamModern[1])
		if (fname_ext == "" && opt_extra == "")		# Return result as an GMTimage
			P = showfig(d, output, fname_ext, "", K)
			gmt("destroy")							# Returning a PS screws the session
		elseif ((haskey(d, :show) && d[:show] != 0) || fname != "" || opt_T != "")
			P = showfig(d, output, fname_ext, opt_T, K, fname)		# Return something here for the case we are in Pluto
			(typeof(P) == Base.Process) && (P = nothing)			# Don't want spurious message on REPL when plotting
		end
	end
	show_non_consumed(d, cmd)
	return P
end

# --------------------------------------------------------------------------------------------------
function show_non_consumed(d::Dict, cmd)
	# First delete some that could not have been delete earlier (from legend for example)
	del_from_dict(d, [[:fmt], [:show], [:leg :legend], [:box_pos], [:leg_pos], [:P :portrait]])
	if (length(d) > 0)
		prog = isa(cmd, String) ? split(cmd)[1] : split(cmd[1])[1]
		println("Warning: the following options were not consumed in $prog => ", keys(d))
	end
	CTRL.limits[1:6] = zeros(6);	CTRL.proj_linear[1] = true;		# Reset these for safety
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
	if (isa(arg, Array{<:GMTdataset,1}))		# Multi-segments can have different settings per line
		(isa(cmd, String)) ? cmd_ = deepcopy([cmd]) : cmd_ = deepcopy(cmd)
		lix, penC, penS = break_pen(scan_opt(arg[1].header, "-W"))
		penT, penC_, penS_ = break_pen(scan_opt(cmd_[end], "-W"))
		if (penC == "")  penC = penC_  end
		if (penS == "")  penS = penS_  end
		cmd_[end] = "-W" * penT * ',' * penC * ',' * penS * " " * cmd_[end]	# Trick to make the parser find this pen
		pens = Vector{String}(undef,length(arg)-1)
		for k = 1:length(arg)-1
			t = scan_opt(arg[k+1].header, "-W")
			if     (t == "")      pens[k] = " -W0."
			elseif (t[1] == ',')  pens[k] = " -W" * penT * t		# Can't have, e.g., ",,230/159/0" => Crash
			elseif (occursin(",",t))  pens[k] = " -W" * t  
			else                  pens[k] = " -W" * penT * ',' * t	# Not sure what this case covers now
			end
		end
		append!(cmd_, pens)			# Append the 'pens' var to the input arg CMD

		lab = Vector{String}(undef,length(arg))
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
		lab = [string(val)]
	elseif (legend_type === nothing)
		lab = ["y1"]
	else
		lab = ["y$(size(legend_type.label, 1))"]
	end

	if ((isa(cmd_, Vector{String}) && !occursin("-O", cmd_[1])) || (isa(cmd_, String) && !occursin("-O", cmd_)))
		legend_type = nothing					# Make sure that we always start with an empty one
	end

	if (legend_type === nothing)
		#legend_type = legend_bag(Vector{String}(undef,1), Vector{String}(undef,1))
		legend_type = legend_bag((isa(cmd_, String)) ? [cmd_] : cmd_, lab)
	else
		isa(cmd_, String) ? append!(legend_type.cmd, [cmd_]) : append!(legend_type.cmd, cmd_)
		append!(legend_type.label, lab)
	end
	return nothing
end

# --------------------------------------------------------------------------------------------------
function digests_legend_bag(d::Dict, del::Bool=false)
	# Plot a legend if the leg or legend keywords were used. Legend info is stored in LEGEND_TYPE global variable
	global legend_type

	if ((val = find_in_dict(d, [:leg :legend], del)[1]) !== nothing)
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
		if ((opt_D = add_opt(d, "", "", [:leg_pos :legend_pos :legend_position],
			(map_coord="g",plot_coord="x",norm="n",pos="j",width="+w",justify="+j",spacing="+l",offset="+o"))) == "")
			just = (isa(val, String) || isa(val, Symbol)) ? justify(val) : "TR"		# "TR" is the default
			opt_D = @sprintf("j%s+w%.3f+o0.1", just, symbW*1.2 + lab_width)
		else
			if (opt_D[1] != 'j' && opt_D[1] != 'g' && opt_D[1] != 'x' && opt_D[1] != 'n')  opt_D = "jTR" * opt_D  end
			if (!occursin("+w", opt_D))  opt_D = @sprintf("%s+w%.3f", opt_D, symbW*1.2 + lab_width)  end
			if (!occursin("+o", opt_D))  opt_D *= "+o0.1"  end
		end

		if ((opt_F = add_opt(d, "", "", [:box_pos :box_position],
			(clearance="+c", fill=("+g", add_opt_fill), inner="+i", pen=("+p", add_opt_pen), rounded="+r", shade="+s"))) == "")
			opt_F = "+p0.5+gwhite"
		else
			if (!occursin("+p", opt_F))  opt_F *= "+p0.5"    end
			if (!occursin("+g", opt_F))  opt_F *= "+gwhite"  end
		end
		legend!(text_record(leg), F=opt_F, D=opt_D, par=(:FONT_ANNOT_PRIMARY, fs))
		legend_type = nothing			# Job done, now empty the bag
	end
	return nothing
end

# --------------------------------------------------------------------------------------------------
function scan_opt(cmd::AbstractString, opt::String)::String
	# Scan the CMD string for the OPT option. Note OPT mut be a 2 chars -X GMT option.
	out = ((ind = findfirst(opt, cmd)) !== nothing) ? strtok(cmd[ind[1]+2:end])[1] : ""
end

# --------------------------------------------------------------------------------------------------
function break_pen(pen::AbstractString)
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
function justify(arg)::String
	# Take a string or symbol in ARG and return the two chars justification code.
	if (isa(arg, Symbol))  arg = string(arg)  end
	(length(arg) == 2) && return arg		# Assume it's already the 2 chars code (no further checking)
	arg = lowercase(arg)
	if     (startswith(arg, "topl"))     out = "TL"
	elseif (startswith(arg, "middlel"))  out = "ML"
	elseif (startswith(arg, "bottoml"))  out = "BL"
	elseif (startswith(arg, "topc"))     out = "TC"
	elseif (startswith(arg, "middlec"))  out = "MC"
	elseif (startswith(arg, "bottomc"))  out = "BC"
	elseif (startswith(arg, "topr"))     out = "TR"
	elseif (startswith(arg, "middler"))  out = "MR"
	elseif (startswith(arg, "bottomr"))  out = "BR"
	else
		@warn("Justification code provided ($arg) is not valid. Defaulting to TopRight");	out = "TR"
	end
	return out
end

# --------------------------------------------------------------------------------------------------
function monolitic(prog::String, cmd0::String, args...)
	# Run this module in the monolithic way. e.g. [outs] = gmt("module args",[inputs])
	return gmt(prog * " " * cmd0, args...)
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
		G = GMTgrid("", "", 0, [x[1], x[end], y[1], y[end], minimum(z), maximum(z)], [x[2]-x[1], y[2]-y[1]],
					0, NaN, "", "", "", x, y, Vector{Float64}(), z, "x", "y", "", "z", "", 0)
		return G
	else
		return x,y,z
	end
end

meshgrid(v::AbstractVector) = meshgrid(v, v)
function meshgrid(vx::AbstractVector{T}, vy::AbstractVector{T}) where T
	m, n = length(vy), length(vx)
	#vx = reshape(vx, 1, n)
	#vy = reshape(vy, m, 1)
	#(repeat(vx, m, 1), repeat(vy, 1, n))
	(vx' .* ones(m), vy .* ones(n)')
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
    (timers === ()) && error("`toc()` without `tic()`")
    t0 = timers[1]::UInt64
    task_local_storage(:TIMERS, timers[2])
    (t1-t0)/1e9
end

function toc(V=true)
    t = _toq()
    (V) && println("elapsed time: ", t, " seconds")
    return t
end

# --------------------------------------------------------------------------------------------------
function extrema_nan(A)
	# Incredibly Julia ignores the NaN nature and incredibly min(1,NaN) = NaN, so need to ... fck
	if (eltype(A) <: AbstractFloat)  return minimum_nan(A), maximum_nan(A)
	else                             return extrema(A)
	end
end
function minimum_nan(A)
	return (eltype(A) <: AbstractFloat) ? minimum(x->isnan(x) ?  Inf : x,A) : minimum(A)
end
function maximum_nan(A)
	return (eltype(A) <: AbstractFloat) ? maximum(x->isnan(x) ? -Inf : x,A) : maximum(A)
end
nanmean(x)   = mean(filter(!isnan,x))
nanmean(x,y) = mapslices(nanmean,x,dims=y)
nanstd(x)    = std(filter(!isnan,x))
nanstd(x,y)  = mapslices(nanstd,x,dims=y)
# --------------------------------------------------------------------------------------------------
function help_show_options(d::Dict)
	if (find_in_dict(d, [:help])[1] !== nothing)  show_kwargs[1] = true  end	# Put in HELP mode
end

# --------------------------------------------------------------------------------------------------
function print_kwarg_opts(symbs, mapa=nothing)::String
	# Print the kwargs options
	opt = "Option: " * join([@sprintf("%s, or ",x) for x in symbs])[1:end-5]
	if (isa(mapa, NamedTuple))
		keys_ = keys(mapa)
		vals = Vector{String}(undef, length(keys_))
		for k = 1:length(keys_)
			t = mapa[keys_[k]]
			vals[k] = (isa(t, Tuple)) ? "?(" * t[1] : "?(" * t
			if (length(vals[k]) > 2 && vals[k][3] == '_')  vals[k] = "Any(" * vals[k][4:end]  end
		end
		sub_opt = join([@sprintf("%s=%s), ",keys_[k], vals[k]) for k = 1:length(keys_)])
		opt *= " => (" * sub_opt * ")"
	elseif (isa(mapa, String))
		opt *= " => " * mapa
	else
		opt *= " => Tuple | String | Number | Bool [Possibly not yet expanded]"
	end
	println(opt)
	return ""		# Must return != nothing so that dbg_print_cmd() signals stop progam's execution
end

# --------------------------------------------------------------------------------------------------
function gmthelp(opt)
	show_kwargs[1] = true
	if (isa(opt, Array{Symbol}))
		for o in opt  gmthelp(o)  end
	else
		o = string(opt)
		try
			if (length(o) <= 2)
				getfield(GMT, Symbol(string("parse_",o)))(Dict(), "")
			else
				getfield(GMT, Symbol(o))(help=1)
			end
		catch err
			println("   ==>  '$o' is not a valid option/module name, or its help is not yet implemented")
			println("   LastError ==>  '$err'")
		end
	end
	show_kwargs[1] = false
	return nothing
end