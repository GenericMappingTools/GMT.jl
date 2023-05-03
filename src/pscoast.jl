"""
    coast(cmd0::String=""; kwargs...)

Plot continents, shorelines, rivers, and borders on maps.
Plots grayshaded, colored, or textured land-masses [or water-masses] on
maps and [optionally] draws coastlines, rivers, and political
boundaries. A map projection must be supplied.

See full GMT (not the `GMT.jl` one) docs at [`coast`]($(GMTdoc)coast.html)

Parameters
----------

- $(GMT._opt_J)
- $(GMT._opt_R)
- **A** | **area** :: [Type => Str or Number]

    Features with an area smaller than min_area in km^2 or of
    hierarchical level that is lower than min_level or higher than
    max_level will not be plotted.
- $(GMT._opt_B)
- **C** | **river_fill** :: [Type => Str]

    Set the shade, color, or pattern for lakes and river-lakes.
- **D** | **res** | **resolution** :: [Type => Str]		``Arg = c|l|i|h|f|a``

    Selects the resolution of the data set to use ((f)ull, (h)igh, (i)ntermediate, (l)ow, (c)rude), or (a)uto).
- **E** | **DCW** :: [Type => Str]

    Select painting or dumping country polygons from the Digital Chart of the World.
    + Tuple("code", Str); Tuple(code, number); Tuple("code" [,"fill"], (pen)); Tuple((...),(...),...)
    + ex: ("PT",(0.5,"red","--")); (("PT","gblue",(0.5,"red"),("ES",(0.5,"yellow")))
    +     DCW=:PT; DCW=(:PT, 1); DCW=("PT", :red)
- **F** | **box** :: [Type => Str]

    Draws a rectangular border around the map scale or rose.
- **G** | **land** :: [Type => Str]

    Select filling or clipping of “dry” areas.
- **I** | **rivers** :: [Type => Str]

    Draw rivers. Specify the type of rivers and [optionally] append pen attributes.
- **L** | **map_scale** :: [Type => Str]

    Draw a map scale.
- **M** | **dump** :: [Type => Str]

    Dumps a single multisegment ASCII output. No plotting occurs.
- **N** | **borders** :: [Type => Str]

    Draw political boundaries. Specify the type of boundary and [optionally] append pen attributes
- $(GMT.opt_P)
- **clip** :: [Type => Str]		``Arg = land|water|end``

    To clip land do *clip=:land*, *clip=:water* clips water. Use *end* to mark end of existing clip path.
    No projection information is needed.
- **S** | **water** | **ocean** :: [Type => Str]

    Select filling or clipping of “wet” areas.
- **Td** | **rose`** :: [Type => Str]

    Draws a map directional rose on the map at the location defined by the reference and anchor points.
- **Tm** | **compass** :: [Type => Str]

    Draws a map magnetic rose on the map at the location defined by the reference and anchor points.
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** | **shore** | **shorelines** | **coast** | **coastlines** :: [Type => Str]
    Draw shorelines [Default is no shorelines]. Append pen attributes.
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bo)
- $(GMT._opt_p)
- $(GMT._opt_t)
- $(GMT.opt_savefig)

To see the full documentation type: ``@? coast``
"""
function coast(cmd0::String=""; clip=nothing, first=true, kwargs...)

	gmt_proggy = (IamModern[1]) ? "coast "  : "pscoast "
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd = parse_E_coast(d, [:E, :DCW], "")		# Process first to avoid warning about "guess"
	cmd = add_opt(d, cmd, "M", [:M :dump])
	if (!occursin("-E+l", cmd) && !occursin("-E+L", cmd))
		cmd, = parse_R(d, cmd, O)
		if (!contains(cmd, " -M"))				# If Dump no -R & -B
			cmd = parse_J(d, cmd, "guess", true, O)[1]
			cmd = parse_B(d, cmd, (O ? "" : (IamModern[1]) ? "" : def_fig_axes[1]))[1]
		end
	end
	cmd, = parse_common_opts(d, cmd, [:F :JZ :UVXY :bo :c :p :t :params], first)
	cmd  = parse_these_opts(cmd, d, [[:A :area], [:C :river_fill], [:D :res :resolution]])
	cmd  = parse_Td(d, cmd)
	cmd  = parse_Tm(d, cmd)
	cmd  = parse_L(d, cmd)
	cmd  = add_opt_fill(cmd, d, [:G :land], 'G')
	cmd  = add_opt_fill(cmd, d, [:S :water :ocean], 'S')

	if (clip !== nothing)
		clip = string(clip)
		if     (clip == "land")    cmd *= " -Gc"
		elseif (clip == "water" || clip == "ocean") cmd *= " -Sc"
		elseif (clip == "end")     cmd *= " -Q"
		else
			@warn("The 'clip' argument can only be a string with 'land', 'water' or 'end'. Ignoring it.")
		end
	end

	# Parse these three options that can be made to respond to same code
	cmd = parse_INW_coast(d, [[:I :rivers], [:N :borders], [:W :shore :shorelines :coast :coastlines]], cmd, "INW")
	(show_kwargs[1]) && print_kwarg_opts([:I :rivers],  "NamedTuple | Tuple | Dict | String")
	(show_kwargs[1]) && print_kwarg_opts([:N :borders], "NamedTuple | Tuple | Dict | String")
	(show_kwargs[1]) && print_kwarg_opts([:W :shore :shorelines :coast],   "NamedTuple | Tuple | Dict | String")

	if (!occursin(" -C",cmd) && !occursin(" -E",cmd) && !occursin(" -G",cmd) && !occursin(" -I",cmd) &&
		!occursin(" -M",cmd) && !occursin(" -N",cmd) && !occursin(" -Q",cmd) && !occursin(" -S",cmd) && !occursin(" -W",cmd))
		cmd *= " -W0.5p"
	end
	(!occursin("-D",cmd)) && (cmd *= " -Da")			# Then pick automatic
	finish = !occursin(" -M",cmd) && !occursin("-E+l", cmd) && !occursin("-E+L", cmd) ? true : false	# Otherwise the dump would be redirected to GMT_user.ps

	# Just let D = coast(R=:PT, dump=true) work without any furthers shits (plain GMT doesn't let it)
	(occursin(" -M",cmd) && !occursin("-E", cmd) && !occursin("-I", cmd) && !occursin("-N", cmd) && !occursin("-W", cmd) && !occursin("-A", cmd)) &&
		(cmd *= " -W -A0/1/1")

	get_largest = (!finish && occursin(" -E", cmd) && (find_in_dict(d, [:biggest :largest])[1] !== nothing))
	_cmd = (finish) ? finish_PS_nested(d, [gmt_proggy * cmd]) : [gmt_proggy * cmd]

	R = finish_PS_module(d, _cmd, "", K, O, finish)
	if (get_largest)
		ind = argmax(size.(R))
		R = [R[ind]]		# Keep it a vector to be consistent with the other Dump cases
		R[1].proj4, R[1].geom = prj4WGS84, wkbPolygon
	end
	geom = occursin(" -M", cmd) ? (occursin(" -E", cmd) ? wkbPolygon : wkbLineString) : wkbUnknown
	isa(R, Vector{<:GMTdataset}) && (for k = 1:numel(R)  R[k].colnames = ["Lon", "Lat"]; R[k].geom = geom  end; R[1].proj4 = prj4WGS84)
	isa(R, GMTdataset) && (R.colnames = ["Lon", "Lat"]; R.geom = geom; R.proj4 = prj4WGS84)
	R
end

# ---------------------------------------------------------------------------------------------------
function parse_INW_coast(d::Dict, symbs::Vector{Matrix{Symbol}}, cmd::String, flags::String)
	# This function is also used by pshistogram (opt -N). Must be length(flags) == length(symbs)
	(length(symbs) != length(flags)) && error("Length of symbs must be equal to number of chars in FLAGS")
	for k = 1:length(symbs)
		if ((val = find_in_dict(d, symbs[k], false)[1]) !== nothing)
			if (isa(val, NamedTuple) || isa(val, Dict) || (isa(val, Tuple) && isa(val[1], NamedTuple)))  
				cmd::String = add_opt(d, cmd, string(flags[k]), symbs[k], (type="/#", level="/#", mode="+p#", pen=("", add_opt_pen)))
			elseif (isa(val, Tuple))
				if (flags[k] == 'W')	# The shore case is ambiguous, this shore=(1,:red) could mean -W1/red or -W1,red 
					cmd *= " -W" * parse_pen(val)	# We take it to mean pen only. Levels must use the NT form
				else
					cmd *= " -" * flags[k] * string(val[1])::String * "/" * parse_pen(val[2])::String
				end
			else    cmd *= " -" * flags[k] * arg2str(val)	# Includes Str, Number or Symb
			end
			del_from_dict(d, vec(symbs[k]))			# Now we can delete the kwarg
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_E_coast(d::Dict, symbs::Vector{Symbol}, cmd::String)
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "NamedTuple | Tuple | Dict | String")
	if ((val = find_in_dict(d, symbs, false)[1]) !== nothing)
		if (isa(val, String) || isa(val, Symbol))	# Simple case, ex E="PT,+gblue" or E=:PT
			t::String = string(" -E", val)
			!contains(t, "+") && (t *= "+p0.5")		# If only code(s), append pen
			cmd *= t
		elseif (isa(val, NamedTuple) || isa(val, Dict))
			cmd = add_opt(d, cmd, "E", [:DCW :E], (country="", name="", continent="=",
			                                       pen=("+p", add_opt_pen), fill=("+g", add_opt_fill)))
		elseif (isa(val, Tuple))
			cmd = parse_dcw(cmd, val)
		end
		cmd *= " -Vq"				# Suppress annoying warnings regarding filling syntax with +r<dpi>
		del_from_dict(d, symbs)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_dcw(cmd::String, val::Tuple)::String
	# First test if (code, pen) or (code, fill) are passed in.
	if (isa(val, Tuple) && length(val) == 2)
		(isa(val[2], Real)) && return string(cmd, " -E", val[1], "+p", val[2])
		(isa(val[2], String) || isa(val[2], Symbol)) && return string(cmd, " -E", val[1], "+g", string(val[2]))
	end

	for k = 1:numel(val)
		if (isa(val[k], NamedTuple) || isa(val[k], Dict))
			isa(val[k], Dict) && (val[k] = Base.invokelatest(dict2nt, val[k]))
			cmd *= add_opt(Dict(:DCW => val[k]), "", "E", [:DCW],
			               (country="", name="", continent="=", pen=("+p", add_opt_pen), fill=("+g", add_opt_fill)))::String
		elseif (isa(val[k], Tuple))
			cmd *= parse_dcw(val[k])
		else
			cmd *= parse_dcw(val)
			break
		end
	end
	return cmd
end

function parse_dcw(val::Tuple)::String
    t::String = string("", " -E", val[1])
	if (length(val) > 1)
		if (isa(val[2], Tuple))  t *= "+p" * parse_pen(val[2])::String
		else                     t *= string(val[2])::String
		end
		if (length(val) > 2)
			if (isa(val[3], Tuple))  t *= add_opt_fill("+g", Dict(fill => val[3]), [:fill])::String
			else                     t *= string(val[3])::String
			end
		end
	end
	return t
end

# ---------------------------------------------------------------------------------------------------
coast!(cmd0::String=""; clip=nothing, kw...) = coast(cmd0; clip=clip, first=false, kw...)

const pscoast  = coast			# Alias
const pscoast! = coast!