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
function parse_J(cmd::String, d::Dict, O=false)
	# Build the option -J string. Make it simply -J if overlay mode (-O) and no new -J is fished here
	# Default to 14c if no size is provided
	opt_J = ""
	for symb in [:J :proj :projection]
		if (haskey(d, symb))
			opt_J = build_opt_J(d[symb])
			break
		end
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
function parse_BJR(d::Dict, cmd0::String, cmd::String, caller, O, default)
	# Join these thre in one function. CALLER is non-empty when module is called by plot()
	cmd, opt_R = parse_R(cmd, d, O)
	cmd, opt_J = parse_J(cmd, d, O)
	if (!O && isempty(opt_J))			# If we have no -J use this default
		opt_J = default					# " -JX12c/8c" (e.g. psxy) or " -JX12c/0" (e.g. grdimage)
		cmd = cmd * opt_J
	elseif (O && isempty(opt_J))
		cmd = cmd * " -J"
	end
	if (!isempty(caller) && !occursin("-B", cmd0) && occursin("-JX", opt_J))	# e.g. plot() sets 'caller'
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
function parse_UVXY(cmd::String, d::Dict)
	cmd = parse_V(cmd, d)
	cmd = parse_UXY(cmd, d, [:X :x_off :x_offset], 'X')
	cmd = parse_UXY(cmd, d, [:Y :y_off :y_offset], 'Y')
	cmd = parse_UXY(cmd, d, [:U :stamp :time_stamp], 'U')
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_gmtconf_MAP(cmd::String, d::Dict)
	# Parse the MAP_ type global parameters of gmt.conf
	if (haskey(d, :MAP_ANNOT_MIN_ANGLE))
		cmd = string(cmd, " --MAP_ANNOT_MIN_ANGLE=", d[:MAP_ANNOT_MIN_ANGLE])
	end
	if (haskey(d, :MAP_ANNOT_MIN_SPACING))
		cmd = string(cmd, " --MAP_ANNOT_MIN_SPACING=", d[:MAP_ANNOT_MIN_SPACING])
	end
	if (haskey(d, :MAP_ANNOT_OBLIQUE))
		cmd = string(cmd, " --MAP_ANNOT_OBLIQUE=", d[:MAP_ANNOT_OBLIQUE])
	end
	if (haskey(d, :MAP_ANNOT_OFFSET))
		cmd = string(cmd, " --MAP_ANNOT_OFFSET=", d[:MAP_ANNOT_OFFSET])
	end
	if (haskey(d, :MAP_ANNOT_OFFSET_PRIMARY))
		cmd = string(cmd, " --MAP_ANNOT_OFFSET_PRIMARY=", d[:MAP_ANNOT_OFFSET_PRIMARY])
	end
	if (haskey(d, :MAP_ANNOT_OFFSET_SECONDARY))
		cmd = string(cmd, " --MAP_ANNOT_OFFSET_SECONDARY=", d[:MAP_ANNOT_OFFSET_SECONDARY])
	end
	if (haskey(d, :MAP_ANNOT_ORTHO))
		cmd = string(cmd, " --MAP_ANNOT_ORTHO=", d[:MAP_ANNOT_ORTHO])
	end
	if (haskey(d, :MAP_DEFAULT_PEN))
		cmd = string(cmd, " --MAP_DEFAULT_PEN=", d[:MAP_DEFAULT_PEN])
	end
	if (haskey(d, :MAP_DEGREE_SYMBOL))
		cmd = string(cmd, " --MAP_DEGREE_SYMBOL=", d[:MAP_DEGREE_SYMBOL])
	end
	if (haskey(d, :MAP_FRAME_AXES))
		cmd = string(cmd, " --MAP_FRAME_AXES=", d[:MAP_FRAME_AXES])
	end
	if (haskey(d, :MAP_FRAME_PEN))
		cmd = string(cmd, " --MAP_FRAME_PEN=", d[:MAP_FRAME_PEN])
	end
	if (haskey(d, :MAP_FRAME_TYPE))
		cmd = string(cmd, " --MAP_FRAME_TYPE=", d[:MAP_FRAME_TYPE])
	end
	if (haskey(d, :MAP_FRAME_WIDTH))
		cmd = string(cmd, " --MAP_FRAME_WIDTH=", d[:MAP_FRAME_WIDTH])
	end
	if (haskey(d, :MAP_GRID_CROSS_SIZE))
		cmd = string(cmd, " --MAP_GRID_CROSS_SIZE=", d[:MAP_GRID_CROSS_SIZE])
	end
	if (haskey(d, :MAP_GRID_CROSS_SIZE_PRIMARY))
		cmd = string(cmd, " --MAP_GRID_CROSS_SIZE_PRIMARY=", d[:MAP_GRID_CROSS_SIZE_PRIMARY])
	end
	if (haskey(d, :MAP_GRID_CROSS_SIZE_SECONDARY))
		cmd = string(cmd, " --MAP_GRID_CROSS_SIZE_SECONDARY=", d[:MAP_GRID_CROSS_SIZE_SECONDARY])
	end
	if (haskey(d, :MAP_GRID_CROSS_PEN))
		cmd = string(cmd, " --MAP_GRID_CROSS_PEN=", d[:MAP_GRID_CROSS_PEN])
	end
	if (haskey(d, :MAP_GRID_PEN_PRIMARY))
		cmd = string(cmd, " --MAP_GRID_PEN_PRIMARY=", d[:MAP_GRID_PEN_PRIMARY])
	end
	if (haskey(d, :MAP_GRID_PEN_SECONDARY))
		cmd = string(cmd, " --MAP_GRID_PEN_SECONDARY=", d[:MAP_GRID_PEN_SECONDARY])
	end
	if (haskey(d, :MAP_HEADING_OFFSET))
		cmd = string(cmd, " --MAP_HEADING_OFFSET=", d[:MAP_HEADING_OFFSET])
	end
	if (haskey(d, :MAP_LABEL_OFFSET))
		cmd = string(cmd, " --MAP_LABEL_OFFSET=", d[:MAP_LABEL_OFFSET])
	end
	if (haskey(d, :MAP_LINE_STEP))
		cmd = string(cmd, " --MAP_LINE_STEP=", d[:MAP_LINE_STEP])
	end
	if (haskey(d, :MAP_LOGO))
		cmd = string(cmd, " --MAP_LOGO=", d[:MAP_LOGO])
	end
	if (haskey(d, :MAP_LOGO_POS))
		cmd = string(cmd, " --MAP_LOGO_POS=", d[:MAP_LOGO_POS])
	end
	if (haskey(d, :MAP_ORIGIN_X))
		cmd = string(cmd, " --MAP_ORIGIN_X=", d[:MAP_ORIGIN_X])
	end
	if (haskey(d, :MAP_ORIGIN_Y))
		cmd = string(cmd, " --MAP_ORIGIN_Y=", d[:MAP_ORIGIN_Y])
	end
	if (haskey(d, :MAP_POLAR_CAP))
		cmd = string(cmd, " --MAP_POLAR_CAP=", d[:MAP_POLAR_CAP])
	end
	if (haskey(d, :MAP_SCALE_HEIGHT))
		cmd = string(cmd, " --MAP_SCALE_HEIGHT=", d[:MAP_SCALE_HEIGHT])
	end
	if (haskey(d, :MAP_TICK_LENGTH))
		cmd = string(cmd, " --MAP_TICK_LENGTH=", d[:MAP_TICK_LENGTH])
	end
	if (haskey(d, :MAP_TICK_LENGTH_PRIMARY))
		cmd = string(cmd, " --MAP_TICK_LENGTH_PRIMARY=", d[:MAP_TICK_LENGTH_PRIMARY])
	end
	if (haskey(d, :MAP_TICK_LENGTH_SECONDARY))
		cmd = string(cmd, " --MAP_TICK_LENGTH_SECONDARY=", d[:MAP_TICK_LENGTH_SECONDARY])
	end
	if (haskey(d, :MAP_TICK_PEN))
		cmd = string(cmd, " --MAP_TICK_PEN=", d[:MAP_TICK_PEN])
	end
	if (haskey(d, :MAP_TICK_PEN_PRIMARY))
		cmd = string(cmd, " --MAP_TICK_PEN_PRIMARY=", d[:MAP_TICK_PEN_PRIMARY])
	end
	if (haskey(d, :MAP_TICK_PEN_SECONDARY))
		cmd = string(cmd, " --MAP_TICK_PEN_SECONDARY=", d[:MAP_TICK_PEN_SECONDARY])
	end
	if (haskey(d, :MAP_TITLE_OFFSET))
		cmd = string(cmd, " --MAP_TITLE_OFFSET=", d[:MAP_TITLE_OFFSET])
	end
	if (haskey(d, :MAP_VECTOR_SHAPE))
		cmd = string(cmd, " --MAP_VECTOR_SHAPE=", d[:MAP_VECTOR_SHAPE])
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_gmtconf_FONT(cmd::String, d::Dict)
	# Parse the FONT_ type global parameters of gmt.conf
	if (haskey(d, :FONT))
		cmd = string(cmd, " --FONT=", d[:FONT])
	end
	if (haskey(d, :FONT_ANNOT))
		cmd = string(cmd, " --FONT_ANNOT=", d[:FONT_ANNOT])
	end
	if (haskey(d, :FONT_ANNOT_PRIMARY))
		cmd = string(cmd, " --FONT_ANNOT_PRIMARY=", d[:FONT_ANNOT_PRIMARY])
	end
	if (haskey(d, :FONT_ANNOT_SECONDARY))
		cmd = string(cmd, " --FONT_ANNOT_SECONDARY=", d[:FONT_ANNOT_SECONDARY])
	end
	if (haskey(d, :FONT_HEADING))
		cmd = string(cmd, " --FONT_HEADING=", d[:FONT_HEADING])
	end
	if (haskey(d, :FONT_LABEL))
		cmd = string(cmd, " --FONT_LABEL=", d[:FONT_LABEL])
	end
	if (haskey(d, :FONT_LOGO))
		cmd = string(cmd, " --FONT_LOGO=", d[:FONT_LOGO])
	end
	if (haskey(d, :FONT_TAG))
		cmd = string(cmd, " --FONT_TAG=", d[:FONT_TAG])
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_gmtconf_FORMAT(cmd::String, d::Dict)
	# Parse the FORMAT_ type global parameters of gmt.conf
	if (haskey(d, :FORMAT_CLOCK_IN))
		cmd = string(cmd, " --FORMAT_CLOCK_IN=", d[:FORMAT_CLOCK_IN])
	end
	if (haskey(d, :FORMAT_CLOCK_MAP))
		cmd = string(cmd, " --FORMAT_CLOCK_MAP=", d[:FORMAT_CLOCK_MAP])
	end
	if (haskey(d, :FORMAT_CLOCK_OUT))
		cmd = string(cmd, " --FORMAT_CLOCK_OUT=", d[:FORMAT_CLOCK_OUT])
	end
	if (haskey(d, :FORMAT_DATE_IN))
		cmd = string(cmd, " --FORMAT_DATE_IN=", d[:FORMAT_DATE_IN])
	end
	if (haskey(d, :FORMAT_DATE_MAP))
		cmd = string(cmd, " --FORMAT_DATE_MAP=", d[:FORMAT_DATE_MAP])
	end
	if (haskey(d, :FORMAT_DATE_OUT))
		cmd = string(cmd, " --FORMAT_DATE_OUT=", d[:FORMAT_DATE_OUT])
	end
	if (haskey(d, :FORMAT_GEO_MAP))
		cmd = string(cmd, " --FORMAT_GEO_MAP=", d[:FORMAT_GEO_MAP])
	end
	if (haskey(d, :FORMAT_GEO_OUT))
		cmd = string(cmd, " --FORMAT_GEO_OUT=", d[:FORMAT_GEO_OUT])
	end
	if (haskey(d, :FORMAT_FLOAT_MAP))
		cmd = string(cmd, " --FORMAT_FLOAT_MAP=", d[:FORMAT_FLOAT_MAP])
	end
	if (haskey(d, :FORMAT_FLOAT_OUT))
		cmd = string(cmd, " --FORMAT_FLOAT_OUT=", d[:FORMAT_FLOAT_OUT])
	end
	if (haskey(d, :FORMAT_TIME_MAP))
		cmd = string(cmd, " --FORMAT_TIME_MAP=", d[:FORMAT_TIME_MAP])
	end
	if (haskey(d, :FORMAT_TIME_PRIMARY_MAP))
		cmd = string(cmd, " --FORMAT_TIME_PRIMARY_MAP=", d[:FORMAT_TIME_PRIMARY_MAP])
	end
	if (haskey(d, :FORMAT_TIME_SECONDARY_MAP))
		cmd = string(cmd, " --FORMAT_TIME_SECONDARY_MAP=", d[:FORMAT_TIME_SECONDARY_MAP])
	end
	if (haskey(d, :FORMAT_TIME_STAMP))
		cmd = string(cmd, " --FORMAT_TIME_STAMP=", d[:FORMAT_TIME_STAMP])
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_gmtconf_TIME(cmd::String, d::Dict)
	# Parse the TIME_ type global parameters of gmt.conf
	if (haskey(d, :TIME_EPOCH))
		cmd = string(cmd, " --TIME_EPOCH=", d[:TIME_EPOCH])
	end
	if (haskey(d, :TIME_INTERVAL_FRACTION))
		cmd = string(cmd, " --TIME_INTERVAL_FRACTION=", d[:TIME_INTERVAL_FRACTION])
	end
	if (haskey(d, :TIME_IS_INTERVAL))
		cmd = string(cmd, " --TIME_IS_INTERVAL=", d[:TIME_IS_INTERVAL])
	end
	if (haskey(d, :TIME_REPORT))
		cmd = string(cmd, " --TIME_REPORT=", d[:TIME_REPORT])
	end
	if (haskey(d, :TIME_SYSTEM))
		cmd = string(cmd, " --TIME_SYSTEM=", d[:TIME_SYSTEM])
	end
	if (haskey(d, :TIME_UNIT))
		cmd = string(cmd, " --TIME_UNIT=", d[:TIME_UNIT])
	end
	if (haskey(d, :TIME_WEEK_START))
		cmd = string(cmd, " --TIME_WEEK_START=", d[:TIME_WEEK_START])
	end
	if (haskey(d, :TIME_Y2K_OFFSET_YEAR))
		cmd = string(cmd, " --TIME_Y2K_OFFSET_YEAR=", d[:TIME_Y2K_OFFSET_YEAR])
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
	opt_bi = ""
	for symb in [:bi :binary_in]
		if (haskey(d, symb))
			opt_bi = " -bi" * arg2str(d[symb])
			cmd = cmd * opt_bi
			break
		end
	end
	return cmd, opt_bi
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
	opt_di = ""
	for symb in [:di :nodata_in]
		if (haskey(d, symb) && isa(d[symb], Number))
			opt_di = " -di" * arg2str(d[symb])
			cmd = cmd * opt_di
			break
		end
	end
	return cmd, opt_di
end

# ---------------------------------------------------------------------------------------------------
function parse_do(cmd::String, d::Dict)
	# Parse the global -do option. Return CMD same as input if no -do option in args
	for symb in [:do :nodata_out]
		if (haskey(d, symb) && isa(d[symb], Number))
			cmd = cmd * " -do" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_e(cmd::String, d::Dict)
	# Parse the global -e option. Return CMD same as input if no -e option in args
	for symb in [:e :pattern]
		if (haskey(d, symb))
			cmd = cmd * " -e" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_f(cmd::String, d::Dict)
	# Parse the global -f option. Return CMD same as input if no -f option in args
	for symb in [:f :colinfo]
		if (haskey(d, symb))
			cmd = cmd * " -f" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_g(cmd::String, d::Dict)
	# Parse the global -g option. Return CMD same as input if no -g option in args
	for symb in [:g :gaps]
		if (haskey(d, symb))
			cmd = cmd * " -g" * arg2str(d[symb])
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
	opt_i = ""
	for symb in [:i :input_col]
		if (haskey(d, symb))
			opt_i = " -i" * arg2str(d[symb])
			cmd = cmd * opt_i
			break
		end
	end
	return cmd, opt_i
end

# ---------------------------------------------------------------------------------------------------
function parse_n(cmd::String, d::Dict)
	# Parse the global -n option. Return CMD same as input if no -n option in args
	for symb in [:n :interp :interp_method]
		if (haskey(d, symb))
			cmd = cmd * " -n" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_s(cmd::String, d::Dict)
	# Parse the global -s option. Return CMD same as input if no -s option in args
	for symb in [:s :skip_col]
		if (haskey(d, symb))
			cmd = cmd * " -s" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_swap_xy(cmd::String, d::Dict)
	# Parse the global -: option. Return CMD same as input if no -: option in args
	# But because we can't have a variable called ':' we use only the 'swap_xy' alias
	for symb in [:swap_xy]
		if (haskey(d, symb))
			cmd = cmd * " -:" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_o(cmd::String, d::Dict)
	# Parse the global -o option. Return CMD same as input if no -o option in args
	for symb in [:o :output_col]
		if (haskey(d, symb))
			cmd = cmd * " -o" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_p(cmd::String, d::Dict)
	# Parse the global -p option. Return CMD same as input if no -p option in args
	for symb in [:p :view :perspective]
		if (haskey(d, symb))
			cmd = cmd * " -p" * arg2str(d[symb])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_r(cmd::String, d::Dict)
	# Parse the global -r option. Return CMD same as input if no -r option in args
	for symb in [:r :reg :registration]
		if (haskey(d, symb))
			cmd = cmd * " -r"
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_t(cmd::String, d::Dict)
	# Parse the global -t option. Return CMD same as input if no -t option in args
	for symb in [:t :alpha :transparency]
		if (haskey(d, symb) && isa(d[symb], Number))
			cmd = @sprintf("%s -t%.6g", cmd, d[symb])
			break
		end
	end
	return cmd
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
		out = @sprintf("%.8g", arg)
	elseif (isa(arg, Array{<:Number}))
		out = join([@sprintf("%.4g/",x) for x in min(4, length(arg))])	# No more than 4 to avoid 'abuses'
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
function finish_PS(d::Dict, cmd0::String, cmd::String, output::String, K::Bool, O::Bool)
	# Finish a PS creating command. All PS creating modules should use this.
	if (!haskey(d, :P) && !haskey(d, :portrait))
		cmd = cmd * " -P"
	end

	if (!isempty(cmd0))
		cmd = cmd * " " * cmd0		# Append any other eventual args not send in via kwargs
	end
	
	# Cannot mix -O,-K and output redirect between positional and kwarg arguments
	if (!occursin("-K", cmd0) && !occursin("-)", cmd0) && !occursin(">", cmd0))
		# So the -O -K dance is provided via kwargs
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
function add_opt_s(cmd::String, opt, d::Dict, symbs)
	# Same as add_opt() but where we only accept string arguments
	for sym in symbs
		if (haskey(d, sym) && isa(d[sym], String))
			cmd = string(cmd, " -", opt, d[sym])
			break
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt_cpt(d::Dict, cmd::String, symbs, opt::Char, N_args, arg1, arg2)
	# Deal with options of the form -Ccolor, where color can be a string or a GMTcpt type
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
function read_data(data, cmd, arg, opt_R, opt_i, opt_bi, opt_di, is3D=false)
	# In case DATA holds a file name, read that data and put it in ARG
	# Also compute a tight -R if this was not provided 
	if (!isempty_(data) && !isempty_(arg))
		warn("Conflicting ways of providing input data. Both a file name via positional and
			  a data array via keyword args were provided. Unknown effect of this.")
	end
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
	if (!isempty_(data)) arg = data  end

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
function read_data(data, cmd, arg1, arg2=[], arg3=[])
	# In case DATA holds a grid file name, copy it into cmd. If Grids put them in ARGs
	if (!isempty_(data) && !isempty_(arg1))
		warn("Conflicting ways of providing input data. Both a file name via positional and
			  a data array via keyword args were provided. Unknown effect of this.")
	end
	if (!isempty_(data))
		if (isa(data, String)) 		# OK, we have data via file
			cmd = cmd * " " * data
		elseif (isa(data, Tuple) && length(data) == 3)
			arg1 = data[1];     arg2 = data[2];     arg3 = data[3]
		else
			arg1 = data				# Whatever this is
		end
	end
	return cmd, arg1, arg2, arg3
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
	if (arg == nothing)
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
function finish_PS_module(d::Dict, cmd::String, opt_extra::String, arg1, arg2, arg3, arg4, arg5, arg6,
                          output::String, fname_ext::String, opt_T::String, K::Bool, prog::String)
	# Common code shared by most of the PS producing modules.
	# OPT_EXTRA is used to force an LHS for cases whe the PS module also produces other things

	if (haskey(d, :ps)) PS = true			# To know if returning PS to the REPL was requested
	else                PS = false
	end
	if (!isempty(opt_extra) && occursin(opt_extra, cmd))  PS = true  end	# For example -D in grdcontour

	(haskey(d, :Vd)) && println(@sprintf("\t%s %s", prog, cmd))

	P = nothing
	if (PS)
		if     (!isempty_(arg6))  P = gmt(string(prog, " ", cmd), arg1, arg2, arg3, arg4, arg5, arg6)
		elseif (!isempty_(arg5))  P = gmt(string(prog, " ", cmd), arg1, arg2, arg3, arg4, arg5)
		elseif (!isempty_(arg4))  P = gmt(string(prog, " ", cmd), arg1, arg2, arg3, arg4)
		elseif (!isempty_(arg3))  P = gmt(string(prog, " ", cmd), arg1, arg2, arg3)
		elseif (!isempty_(arg2))  P = gmt(string(prog, " ", cmd), arg1, arg2)
		elseif (!isempty_(arg2))  P = gmt(string(prog, " ", cmd), arg1, arg2)
		elseif (!isempty_(arg1))  P = gmt(string(prog, " ", cmd), arg1)
		else                      P = gmt(string(prog, " ", cmd))
		end
	else
		if     (!isempty_(arg6))  gmt(string(prog, " ", cmd), arg1, arg2, arg3, arg4, arg5, arg6)
		elseif (!isempty_(arg5))  gmt(string(prog, " ", cmd), arg1, arg2, arg3, arg4, arg5)
		elseif (!isempty_(arg4))  gmt(string(prog, " ", cmd), arg1, arg2, arg3, arg4)
		elseif (!isempty_(arg3))  gmt(string(prog, " ", cmd), arg1, arg2, arg3)
		elseif (!isempty_(arg2))  gmt(string(prog, " ", cmd), arg1, arg2)
		elseif (!isempty_(arg1))  gmt(string(prog, " ", cmd), arg1)
		else                      gmt(string(prog, " ", cmd))
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

# ---------------------------------------------------------------------------------------------------
function finish_PS_module(d::Dict, cmd::Array{String,1}, opt_extra::String, arg1, arg2, N_args::Integer,
                          output::String, fname_ext::String, opt_T::String, K::Bool, prog::String)
	# This version uses onle two ARGi and CMD is an Array of strings
	# Also N_args is no longer used and must be removed.

	if (haskey(d, :ps)) PS = true			# To know if returning PS to the REPL was requested
	else                PS = false
	end

	P = nothing
	for k = 1:length(cmd)
		(haskey(d, :Vd)) && println(@sprintf("\t%s %s", prog, cmd[k]))
		if (isempty_(arg1))					# Simple case
			if (PS) P = gmt(string(prog, " ", cmd[k]))
			else        gmt(string(prog, " ", cmd[k]))
			end
		elseif (isempty_(arg2))				# One numeric input
			if (PS) P = gmt(string(prog, " ", cmd[k]), arg1)
			else        gmt(string(prog, " ", cmd[k]), arg1)
			end
		else								# Two numeric inputs (data + CPT)
			if (PS) P = gmt(string(prog, " ", cmd[k]), arg1, arg2)
			else        gmt(string(prog, " ", cmd[k]), arg1, arg2)
			end
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

# ---------------------------------------------------------------------------------------------------
function finish_PS_module(d::Dict, cmd::String, opt_extra::String, arg1, arg2, output::String,
                          fname_ext::String, opt_T::String, K::Bool, prog::String)
	finish_PS_module(d, [cmd], opt_extra, arg1, arg2, 0, output, fname_ext, opt_T, K, prog)
	# This version uses only two ARGi and CMD is a string
end

# --------------------------------------------------------------------------------------------------
function monolitic(prog::String, cmd0::String, arg1=[], need_out::Bool=true)
	# Run this module in the monolitic way. e.g. [outs] = gmt("module args",[inputs])
	# NEED_OUT signals if the module has an output. The PS producers, however, may or not
	# return something (the PS itself), psconvert can also have it (the Image) or not.
	R = nothing
	if (need_out && occursin(">", cmd0))  need_out = false  end		# Interpreted as "> file" so not LHS
	if (need_out)
		if (isempty(arg1))  R = gmt(prog * " " * cmd0)
		else                R = gmt(prog * " " * cmd0, arg1)
		end
	else
		if (isempty(arg1))  gmt(prog * " " * cmd0)
		else                gmt(prog * " " * cmd0, arg1)
		end
	end
	return R
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
