# Parse the common options that all GMT modules share, plus some others functions of also common usage

const KW = Dict{Symbol,Any}

function parse_R(cmd::String, d::Dict, O=false)
	# Build the option -R string. Make it simply -R if overlay mode (-O) and no new -R is fished here
	opt_R = ""
	for sym in [:R :region :limits]
		if (haskey(d, sym))
			opt_R = build_opt_R(d[sym])
			break
		end
	end
	if (O && isempty(opt_R))  opt_R = " -R"  end
	cmd = cmd * opt_R
	return cmd, opt_R
end

function build_opt_R(Val)
	if (isa(Val, String))
		return " -R" * Val
	elseif (isa(Val, Array) && length(Val) == 4)
		return @sprintf(" -R%.14g/%.14g/%.14g/%.14g", Val[1], Val[2], Val[3], Val[4])
	elseif (isa(Val, Array) && length(Val) == 6)
		return @sprintf(" -R%.14g/%.14g/%.14g/%.14g/%.14g/%.14g", Val[1], Val[2], Val[3], Val[4], Val[5], Val[6])
	elseif (isa(Val, GMTgrid) || isa(Val, GMTimage))
		return @sprintf(" -R%.14g/%.14g/%.14g/%.14g", Val.range[1], Val.range[2], Val.range[3], Val.range[4])
	end
	return ""
end

# ---------------------------------------------------------------------------------------------------
function parse_JZ(cmd::String, d::Dict)
	for sym in [:JZ :Jz]
		if (haskey(d, sym))
			if (sym == :JZ)
				cmd = cmd * " -JZ" * arg2str(d[sym])
			else
				cmd = cmd * " -Jz" * arg2str(d[sym])
			end
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_J(cmd::String, d::Dict, map=true, O=false)
	# Build the option -J string. Make it simply -J if overlay mode (-O) and no new -J is fished here
	# Default to 14c if no size is provided.
	# If MAP == false, do not try to append a fig size
	opt_J = ""
	for symb in [:J :proj :projection]
		if (haskey(d, symb))
			opt_J = build_opt_J(d[symb])
			break
		end
	end
	if (!map && !isempty(opt_J))
		return cmd * opt_J, opt_J
	end

	if (O && isempty(opt_J))  opt_J = " -J"  end

	if (!O && !isempty(opt_J))
		# If only the projection but no size, try to get it from the kwargs.
		if (haskey(d, :figsize))
			if (isa(d[:figsize], Number))
				s = @sprintf("%.8g", d[:figsize])
			elseif (isa(d[:figsize], Array) && length(d[:figsize]) == 2)
				s = @sprintf("%.10g/%.10g", d[:figsize][1], d[:figsize][2])
			elseif (isa(d[:figsize], String))
				s = d[:figsize]
			else
				error("What the hell is this figwidth argument?")
			end
			if (haskey(d, :units))
				s = s * d[:units][1]
			end
			if (isdigit(opt_J[end]))  opt_J = opt_J * "/" * s
			else                      opt_J = opt_J * s
			end
		elseif (haskey(d, :figscale))
			opt_J = opt_J * string(d[:figscale])
		elseif (length(opt_J) == 4 || (length(opt_J) >= 5 && isletter(opt_J[5])))	# No size provided
			opt_J = opt_J * "14c"			# If no size, default to 14 centimeters
		end
	end
	cmd = cmd * opt_J
	return cmd, opt_J
end

function build_opt_J(Val)
	if (isa(Val, String))
		return " -J" * Val
	elseif (isa(Val, Symbol))
		return " -J" * string(Val)
	elseif (isempty(Val))
		return " -J"
	end
	return ""
end

# ---------------------------------------------------------------------------------------------------
function parse_B(cmd::String, d::Dict, opt_B::String="")
	for sym in [:B :frame :axes]
		if (haskey(d, sym))
			if (isa(d[sym], String))
				opt_B = d[sym]
			elseif (isa(d[sym], Symbol))
				opt_B = string(d[sym])
			end
			break
		end
	end

	tok = Vector{String}(undef, 10)
	k = 1
	r = opt_B
	found = false
	while (!isempty(r))
		tok[k],r = GMT.strtok(r)
		if (occursin(r"[WESNwesntlbu+g+o]", tok[k]) && !occursin("+t", tok[k]))		# If title here, forget about :title
			if (haskey(d, :title) && isa(d[:title], String))
				tok[k] = tok[k] * "+t\"" * d[:title] * "\""
			end
		elseif (occursin(r"[afgpsxyz+S+u]", tok[k]) && !occursin(r"[+l+L]", tok[k]))	# If label here, forget about :x|y_label
			if (haskey(d, :x_label) && isa(d[:x_label], String))  tok[k] = tok[k] * " -Bx+l\"" * d[:x_label] * "\""  end
			if (haskey(d, :y_label) && isa(d[:y_label], String))  tok[k] = tok[k] * " -By+l\"" * d[:y_label] * "\""  end
		end
		if (!occursin("-B", tok[k]))
			if (!occursin('"', tok[k]))
				tok[k] = " -B" * tok[k] 		# Simple case, no quotes to break our heads
			else
				if (!found)
					tok[k] = " -B" * tok[k] 	# A title in quotes with spaces
					found = true
				else
					tok[k] = " " * tok[k]
					found = false
				end
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

	if (!isempty(opt_B))  cmd = cmd * opt_B  end
	return cmd, opt_B
end

# ---------------------------------------------------------------------------------------------------
function parse_BJR(d::Dict, cmd::String, caller, O, default)
	# Join these three in one function. CALLER is non-empty when module is called by plot()
	cmd, opt_R = parse_R(cmd, d, O)
	cmd, opt_J = parse_J(cmd, d, true, O)
	if (!O && isempty(opt_J))			# If we have no -J use this default
		opt_J = default					# " -JX12c/8c" (e.g. psxy) or " -JX12c/0" (e.g. grdimage)
		cmd = cmd * opt_J
	elseif (O && isempty(opt_J))
		cmd = cmd * " -J"
	end
	if (!isempty(caller) && occursin("-JX", opt_J))		# e.g. plot() sets 'caller'
		if (caller == "plot3d")
			cmd, opt_B = parse_B(cmd, d, "-Ba -Bza -BWSZ")
		else
			cmd, opt_B = parse_B(cmd, d, "-Ba -BWS")
		end
	else
		cmd, opt_B = parse_B(cmd, d)
	end
	return cmd, opt_B, opt_J, opt_R
end

# ---------------------------------------------------------------------------------------------------
function parse_UXY(cmd::String, d::Dict, aliases, opt::Char)
	# Parse the global -U, -X, -Y options. Return CMD same as input if no option  OPT in args
	# ALIASES: [:X :x_off :x_offset] (same for Y) or [:U :time_stamp :stamp]
	for symb in aliases
		if (haskey(d, symb))
			cmd = string(cmd, " -", opt, d[symb])
			break
		end
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
function parse_V_params(cmd::String, d::Dict)
	# Parse the global -V option and the --PAR=val. Return CMD same as input if no options in args
	cmd = parse_V(cmd, d)
	return parse_params(cmd, d)
end

# ---------------------------------------------------------------------------------------------------
function parse_UVXY(cmd::String, d::Dict)
	cmd = parse_V(cmd, d)
	cmd = parse_UXY(cmd, d, [:X :x_off :x_offset], 'X')
	cmd = parse_UXY(cmd, d, [:Y :y_off :y_offset], 'Y')
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
function parse_s(cmd::String, d::Dict)
	# Parse the global -s option. Return CMD same as input if no -s option in args
	return parse_helper(cmd, d, [:s :skip_col], " -s")
end

# ---------------------------------------------------------------------------------------------------
function parse_swap_xy(cmd::String, d::Dict)
	# Parse the global -: option. Return CMD same as input if no -: option in args
	# But because we can't have a variable called ':' we use only the 'swap_xy' alias
	return parse_helper(cmd, d, [:swap_xy], " -:")
end

# ---------------------------------------------------------------------------------------------------
function parse_o(cmd::String, d::Dict)
	# Parse the global -o option. Return CMD same as input if no -o option in args
	return parse_helper(cmd, d, [:o :output_col], " -o")
end

# ---------------------------------------------------------------------------------------------------
function parse_p(cmd::String, d::Dict)
	# Parse the global -p option. Return CMD same as input if no -p option in args
	return parse_helper(cmd, d, [:p :view :perspective], " -p")
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
	for sym in symbs
		if (haskey(d, sym))
			opt_val = opt * arg2str(d[sym])
			cmd = cmd * opt_val
			break
		end
	end
	return cmd, opt_val
end

# ---------------------------------------------------------------------------------------------------
function parse_params(cmd::String, d::Dict)
	# Parse the gmt.conf parameters when used from within the modules. Return a --PAR=val string
	# The input to this kwarg can be a tuple (e.g. (PAR,val)) or a NamedTuple (P1=V1, P2=V2,...)

	for symb in [:conf :par :params]
		#if (haskey(d, symb) && isa(d[symb], NamedTuple))
		if (haskey(d, symb))
			t = d[symb]
			if (isa(t, NamedTuple))
				fn = fieldnames(typeof(t))
				for k = 1:length(fn)
					cmd = cmd * " --" * string(fn[k]) * "=" * string(t[2])
				end
			elseif (isa(t, Tuple))
				cmd = cmd * " --" * string(t[1]) * "=" * string(t[2])
			end
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function opt_pen(d::Dict, opt::Char, symbs)
	# Create an option string of the type -Wpen
	out = ""
	pen = build_pen(d)						# Either a full pen string or empty ("")
	if (!isempty(pen))
		out = string(" -", opt, pen)
	else
		for sym in symbs
			if (haskey(d, sym))
				if (isa(d[sym], String))
					out = string(" -", opt, arg2str(d[sym]))
				elseif (isa(d[sym], Number))
					out = string(" -", opt, d[sym])
				elseif (isa(d[sym], Tuple))	# Like this it can hold the pen, not extended atts
					out = string(" -", opt, parse_pen(d[sym]))
				else
					error(string("Nonsense in ", opt, " option"))
				end
				break
			end
		end
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
function parse_pen(pen::Tuple)
	# Convert a empty to 3 args tuple containing (width[c|i|p]], [color], [style[c|i|p|])
	len = length(pen)
	if (len == 0) return "0.25p" end 	# just the default pen
	s = arg2str(pen[1])					# First arg is differene because there is no leading ','
	for k = 2:len
		if (isa(pen[k], Number))
			s = @sprintf("%s,%.8g", s, pen[k])
		else
			s = @sprintf("%s,%s", s, pen[k])
		end
	end
	return s
end

# ---------------------------------------------------------------------------------------------------
function parse_pen_width(d::Dict)
	# Search for a "lw" or "linewidth" specification
	pw = ""
	for sym in [:lw :linewidth :LineWidth]
		if (haskey(d, sym))
			pw = string(d[sym])
		end
	end
	return pw
end

# ---------------------------------------------------------------------------------------------------
function parse_pen_color(d::Dict)
	# Search for a "lc" or "linecolor" specification
	pc = ""
	for sym in [:lc :linecolor :LineColor]
		if (haskey(d, sym))
			pc = string(d[sym])
			break
		end
	end
	return pc
end

# ---------------------------------------------------------------------------------------------------
function parse_pen_style(d::Dict)
	# Search for a "ls" or "linestyle" specification
	ps = ""
	for sym in [:ls :linestyle :LineStyle]
		if (haskey(d, sym))
			ps = string(d[sym])
		end
	end
	return ps
end

# ---------------------------------------------------------------------------------------------------
function build_pen(d::Dict)
	# Search for lw, lc, ls in d and create a pen string in case they exist
	# If no pen specs found, return the empty string ""
	lw = parse_pen_width(d)
	lc = parse_pen_color(d)
	ls = parse_pen_style(d)
	if (!isempty(lw) || !isempty(lc) || !isempty(ls))
		return lw * "," * lc * "," * ls
	else
		return ""
	end
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
	elseif (isa(arg, Symbol))
		out = string(arg)
	elseif (isempty(arg) || (isa(arg, Bool) && arg))
		out = ""
	elseif (isa(arg, Number))		# Have to do it after the Bool test above because Bool is a Number too
		out = @sprintf("%.12g", arg)
	elseif (isa(arg, Array{<:Number}))
		out = join([@sprintf("%.12g/",x) for x in arg])
		out = rstrip(out, '/')		# Remove last '/'
	else
		error("Argument 'arg' can only be a String or a Number")
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
	if (!haskey(d, :P) && !haskey(d, :portrait))
		cmd = cmd * " -P"
	end

	if (K && !O)              opt = " -K"
	elseif (K && O)           opt = " -K -O"
	elseif (!K && O)          opt = " -O"
	else                      opt = ""
	end

	if (!isempty(output))
		if (K && !O)          cmd = cmd * opt * " > " * output
		elseif (!K && !O)     cmd = cmd * opt * " > " * output
		elseif (O)            cmd = cmd * opt * " >> " * output
		end
	else
		if (K && !O)          cmd = cmd * opt
		elseif (!K && !O)     cmd = cmd * opt
		elseif (O)            cmd = cmd * opt
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt(cmd::String, opt, d::Dict, symbs, del::Bool=false)
	# Scan the D Dict for SYMBS keys and if found create the new option OPT and append it to CMD
	# If DEL == true we remove the found key. Useful when 
	for sym in symbs
		if (haskey(d, sym))
			cmd = string(cmd, " -", opt, arg2str(d[sym]))
			if (del)
				delete!(d, sym)
			end
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt_cpt(d::Dict, cmd::String, symbs, opt::Char, N_args, arg1, arg2=[])
	# Deal with options of the form -Ccolor, where color can be a string or a GMTcpt type
	# N_args only applyies to when a GMTcpt was transmitted, Than it's either 0, case in which
	# the cpt is put in arg1, or 1 and the cpt goes to arg2.
	for sym in symbs
		if (haskey(d, sym))
			if (isa(d[sym], GMT.GMTcpt))
				cmd = string(cmd, " -", opt)
				if     (N_args == 0)  arg1 = d[sym];	N_args += 1
				elseif (N_args == 1)  arg2 = d[sym];	N_args += 1
				else   error(string("Can't send the CPT data via ", opt, " and input array"))
				end
			else
				cmd = string(cmd, " -", opt, arg2str(d[sym]))
			end
			break
		end
	end
	return cmd, arg1, arg2, N_args
end

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
function read_data(d::Dict, fname::String, cmd, arg, opt_R, opt_i, opt_bi, opt_di, is3D=false)
	# In case DATA holds a file name, read that data and put it in ARG
	# Also compute a tight -R if this was not provided 
	data_kw = nothing
	if (haskey(d, :data))	data_kw = d[:data]	end

	ins = sum([data_kw !== nothing !isempty_(arg) !isempty(fname)])
	if (ins > 1)
		warn("Conflicting ways of providing input data. Either a file name via positional and
		a data array via keyword args were provided or numeric input. Unknown effect of this.")
	end

	if (!isempty(fname))		data_kw = fname		end

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

	if (isempty(opt_R))
		info = gmt("gmtinfo -C" * opt_i, arg)		# Here we are reading from an original GMTdataset or Array
		if (size(info[1].data, 2) < 4)
			error("Need at least 2 columns of data to run this program")
		end
		if (is3D)
			opt_R = @sprintf(" -R%.8g/%.8g/%.8g/%.8g/%.8g/%.8g", info[1].data[1], info[1].data[2], info[1].data[3], info[1].data[4], info[1].data[5], info[1].data[6])
		else
			opt_R = @sprintf(" -R%.8g/%.8g/%.8g/%.8g", info[1].data[1], info[1].data[2], info[1].data[3], info[1].data[4])
		end
		cmd = cmd * opt_R
	end

	return cmd, arg, opt_R, opt_i
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

#= ---------------------------------------------------------------------------------------------------
function common_grd(cmd::String, flag::Char)
	# Detect an output grid file name was requested, normally via -G, or not. Latter implies
	# that the result grid is returned in a G GMTgrid type.
	# Used the the grdxxx modules that produce a grid.
	ff = findfirst(string("-", flag), cmd)
	ind = (ff === nothing) ? 0 : first(ff)
	if (ind > 0 && length(cmd) > ind+2 && cmd[ind+2] != ' ')      # A file name was provided
		no_output = true
	else
		no_output = false
	end
end
=#

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
	(haskey(d, :Vd)) && println(@sprintf("\t%s %s", prog, cmd))
end

# ---------------------------------------------------------------------------------------------------
function showfig(fname_ps::String, fname_ext::String, opt_T::String, K=false, fname="")
	# Take a PS file, convert it with psconvert (unless opt_T == "" meaning file is PS)
	# and display it in default system viewer
	# FNAME_EXT hold the extension when not PS
	# OPT_T holds the psconvert -T option, again when not PS
	# FNAME is for when we implement the savefig option
	if (!isempty(opt_T))
		if (K) gmt("psxy -T -R0/1/0/1 -JX1 -O >> " * fname_ps)  end			# Close the PS file first
		gmt("psconvert -A1p -Qg4 -Qt4 " * fname_ps * opt_T)
		out = fname_ps[1:end-2] * fname_ext
		if (!isempty(fname))
			run(`mv $out $fname`)
			out = fname
		end
	elseif (!isempty(fname_ps))
		out = fname_ps
	else
		if (K) gmt("psxy -T -R0/1/0/1 -JX1 -O ")  end		# Close the PS file first
		if (isempty(fname_ext))
			return gmt("psconvert = -A1p")					# Return a GMTimage object
		else
			out = tempdir() * "GMTjl_tmp.pdf"
			gmt("psconvert = -A1p -Tf -F" * out)
		end
	end
	@static if (Sys.iswindows()) run(ignorestatus(`explorer $out`))
	elseif (Sys.isapple()) run(`open $(out)`)
	elseif (Sys.islinux() || Sys.isbsd()) run(`xdg-open $(out)`)
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
	if (isa(cmd, Array{String, 1}))
		for k = 1:length(cmd)
			dbg_print_cmd(d, cmd[k], prog)
			if (isempty_(arg1))					# Simple case
				P = gmt(string(prog, " ", cmd[k]))
			elseif (isempty_(arg2))				# One numeric input
				P = gmt(string(prog, " ", cmd[k]), arg1)
			else								# Two numeric inputs
				P = gmt(string(prog, " ", cmd[k]), arg1, arg2)
			end
		end
	else
		dbg_print_cmd(d, cmd, prog)
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

	if (isempty(fname_ext) && isempty(opt_extra))	# Return result as an GMTimage
		P = showfig(output, fname_ext, "", K)
	else
		if (haskey(d, :show) && d[:show] != 0) 		# Display Fig in default viewer
			showfig(output, fname_ext, opt_T, K)
		elseif (haskey(d, :savefig))
			showfig(output, fname_ext, opt_T, K, d[:savefig])
		end
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
function peaks(N=49)
	x,y = meshgrid(range(-3,stop=3,length=N))
	
	z =  3 * (1 .- x).^2 .* exp.(-(x.^2) - (y .+ 1).^2) - 10*(x./5 - x.^3 - y.^5) .* exp.(-x.^2 - y.^2)
	   - 1/3 * exp.(-(x .+ 1).^2 - y.^2)
	return x,y,z
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