"""
    coast(cmd0::String=""; kwargs...)

Plot continents, shorelines, rivers, and borders on maps.
Plots grayshaded, colored, or textured land-masses [or water-masses] on
maps and [optionally] draws coastlines, rivers, and political
boundaries. A map projection must be supplied.

Full option list at [`coast`]($(GMTdoc)coast.html)

Parameters
----------

- $(GMT.opt_J)
- $(GMT.opt_R)
- **A** | **area** :: [Type => Str or Number]

    Features with an area smaller than min_area in km^2 or of
    hierarchical level that is lower than min_level or higher than
    max_level will not be plotted.
    ($(GMTdoc)coast.html#a)
- $(GMT.opt_B)
- **C** | **river_fill** :: [Type => Str]

    Set the shade, color, or pattern for lakes and river-lakes.
    ($(GMTdoc)coast.html#c)
- **D** | **res** | **resolution** :: [Type => Str]		``Arg = c|l|i|h|f|a``

    Selects the resolution of the data set to use ((f)ull, (h)igh, (i)ntermediate, (l)ow, (c)rude), or (a)uto).
    ($(GMTdoc)coast.html#d)
- **E** | **DCW** :: [Type => Str]

    Select painting or dumping country polygons from the Digital Chart of the World.
    ($(GMTdoc)coast.html#e)
    + Tuple("code", Str); Tuple("code" [,"fill"], (pen)); Tuple((...),(...),...)
    + ex: ("PT",(0.5,"red","--")); (("PT","gblue",(0.5,"red"),("ES",(0.5,"yellow")))
- **F** | **box** :: [Type => Str]

    Draws a rectangular border around the map scale or rose.
    ($(GMTdoc)coast.html#f)
- **G** | **land** :: [Type => Str]

    Select filling or clipping of “dry” areas.
    ($(GMTdoc)coast.html#g)
- **I** | **rivers** :: [Type => Str]

    Draw rivers. Specify the type of rivers and [optionally] append pen attributes.
    ($(GMTdoc)coast.html#i)
- **L** | **map_scale** :: [Type => Str]

    Draw a map scale.
    ($(GMTdoc)coast.html#l)
- **M** | **dump** :: [Type => Str]

    Dumps a single multisegment ASCII output. No plotting occurs.
    ($(GMTdoc)coast.html#m)
- **N** | **borders** :: [Type => Str]

    Draw political boundaries. Specify the type of boundary and [optionally] append pen attributes
    ($(GMTdoc)coast.html#n)
- $(GMT.opt_P)
- **clip** :: [Type => Str]		``Arg = land|water|end``

    To clip land do *clip=:land*, *clip=:water* clips water. Use *end* to mark end of existing clip path.
    No projection information is needed.
    ($(GMTdoc)coast.html#q)
- **S** | **water** | **ocean** :: [Type => Str]

    Select filling or clipping of “wet” areas.
    ($(GMTdoc)coast.html#s)
- **Td** | **rose`** :: [Type => Str]

    Draws a map directional rose on the map at the location defined by the reference and anchor points.
    ($(GMTdoc)coast.html#t)
- **Tm** | **compass** :: [Type => Str]

    Draws a map magnetic rose on the map at the location defined by the reference and anchor points.
    ($(GMTdoc)coast.html#t)
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** | **shore** :: [Type => Str]
    Draw shorelines [Default is no shorelines]. Append pen attributes.
    ($(GMTdoc)coast.html#w)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bo)
- $(GMT.opt_p)
- $(GMT.opt_t)
"""
function coast(cmd0::String=""; clip=nothing, first=true, kwargs...)

	gmt_proggy = (IamModern[1]) ? "coast "  : "pscoast "
	(length(kwargs) == 0 && clip === nothing) && return monolitic(gmt_proggy, cmd0)

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	maybe_more = false			# If latter set to true, search for lc & lc pen settings
	cmd = parse_E_coast(d, [:E :DCW :dcw], "")		# Process first to avoid warning about "guess"
	cmd = add_opt(d, cmd, "M", [:M :dump])
	if (!occursin("-E+l", cmd) && !occursin("-E+L", cmd) && !occursin("-M", cmd))
		cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd, "", O, "guess")
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
	cmd = parse_INW_coast(d, [[:I :rivers], [:N :borders], [:W :shore :shorelines]], cmd, "INW")
	(show_kwargs[1]) && print_kwarg_opts([:I :rivers],  "NamedTuple | Tuple | Dict | String")
	(show_kwargs[1]) && print_kwarg_opts([:N :borders], "NamedTuple | Tuple | Dict | String")
	(show_kwargs[1]) && print_kwarg_opts([:W :shore :shorelines],   "NamedTuple | Tuple | Dict | String")

	if (!occursin(" -C",cmd) && !occursin(" -E",cmd) && !occursin(" -G",cmd) && !occursin(" -I",cmd) &&
		!occursin(" -M",cmd) && !occursin(" -N",cmd) && !occursin(" -Q",cmd) && !occursin(" -S",cmd) && !occursin(" -W",cmd))
		cmd *= " -W0.5p"
	end
	(!occursin("-D",cmd)) && (cmd *= " -Da")			# Then pick automatic
	finish = !occursin(" -M",cmd) && !occursin("-E+l", cmd)  && !occursin("-E+L", cmd) ? true : false	# Otherwise the dump would be redirected to GMTjl_tmp.ps

	return finish_PS_module(d, gmt_proggy * cmd, "", K, O, finish)
end

# ---------------------------------------------------------------------------------------------------
function parse_INW_coast(d::Dict, symbs::Array{Array{Symbol,2},1}, cmd::String, flags::String)
	# This function is also used by pshistogram (opt -N). Must be length(flags) == length(symbs)
	(length(symbs) != length(flags)) && error("Length of symbs must be equal to number of chars in FLAGS")
	for k = 1:length(symbs)
		if ((val = find_in_dict(d, symbs[k], false)[1]) !== nothing)
			if (isa(val, NamedTuple) || isa(val, Dict) || (isa(val, Tuple) && isa(val[1], NamedTuple)))  
				cmd = add_opt(d, cmd, flags[k], symbs[k], (type="/#", level="/#", mode="+p#", pen=("", add_opt_pen)))
			elseif (isa(val, Tuple))  cmd *= " -" * flags[k] * parse_pen(val)
			else                      cmd *= " -" * flags[k] * arg2str(val)	# Includes Str, Number or Symb
			end
			del_from_dict(d, symbs[k])		# Now we can delete the kwarg
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_E_coast(d::Dict, symbs::Array{<:Symbol}, cmd::String)
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "NamedTuple | Tuple | Dict | String")
	if ((val = find_in_dict(d, symbs, false)[1]) !== nothing)
		if (isa(val, String) || isa(val, Symbol))
			cmd = string(cmd, " -E", val)			# Simple case, ex E="PT,+gblue"
		elseif (isa(val, NamedTuple) || isa(val, Dict))
			cmd = add_opt(d, cmd, "E", [:DCW :E], (country="", name="", continent="=",
			                                       pen=("+p", add_opt_pen), fill=("+g", add_opt_fill)))
		elseif (isa(val, Tuple))
			cmd = parse_dcw(cmd, val)
		end
		if (GMTver >= v"6.1")  cmd *= " -Vq"  end		# Suppress annoying warnings regarding filling syntax with +r<dpi>
		del_from_dict(d, symbs)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_dcw(cmd::String, val::Tuple)
	for k = 1:length(val)
		if (isa(val[k], NamedTuple) || isa(val[k], Dict))
			if (isa(val[k], Dict))  val[k] = dict2nt(val[k])  end
			cmd *= add_opt(Dict(:DCW => val[k]), "", "E", [:DCW],
			               (country="", name="", continent="=", pen=("+p", add_opt_pen), fill=("+g", add_opt_fill)))
		elseif (isa(val[k], Tuple))
			cmd *= parse_dcw(val[k])
		else
			cmd *= parse_dcw(val)
			break
		end
	end
	return cmd
end

function parse_dcw(val::Tuple)
    t = string("", " -E", val[1])
	if (length(val) > 1)
		if (isa(val[2], Tuple))  t *= "+p" * parse_pen(val[2])
		else                     t *= string(val[2])
		end
		if (length(val) > 2)
			if (isa(val[3], Tuple))  t *= add_opt_fill("+g", Dict(fill => val[3]), [:fill])
			else                     t *= string(val[3])
			end
		end
	end
	return t
end

# ---------------------------------------------------------------------------------------------------
coast!(cmd0::String=""; clip=nothing, kw...) = coast(cmd0; clip=clip, first=false, kw...)

const pscoast  = coast			# Alias
const pscoast! = coast!