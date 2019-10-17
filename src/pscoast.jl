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

	length(kwargs) == 0 && clip == nothing && return monolitic("pscoast", cmd0)

	d = KW(kwargs)
    K, O = set_KO(first)		# Set the K O dance

	maybe_more = false				# If latter set to true, search for lc & lc pen settings
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12cd/0")
	cmd = parse_common_opts(d, cmd, [:F :JZ :UVXY :bo :c :p :t :params], first)
	cmd = auto_JZ(cmd)		# Add -JZ if perspective for the case -R.../z_min/z_max
	cmd = parse_these_opts(cmd, d, [[:A :area], [:C :river_fill], [:D :res :resolution], [:M :dump]])
	#cmd = parse_TdTmL(d, cmd)
    cmd = parse_type_anchor(d, cmd, [[:Td :rose], [:Tm :compass], [:L :map_scale]])
	cmd = add_opt_fill(cmd, d, [:G :land], 'G')
	cmd = add_opt_fill(cmd, d, [:S :water :ocean], 'S')

	if (clip !== nothing)
		clip = string(clip)
		if     (clip == "land")    cmd *= " -Gc"
		elseif (clip == "water" || clip == "ocean") cmd *= " -Sc"
		elseif (clip == "end")     cmd *= " -Q"
		else
			@warn("The 'clip' argument can only be a string with 'land', 'water' or 'end'. Ignoring it.")
		end
	end

	# Parse these three options that can be made to respond to same code`
	symbs = [[:I :rivers], [:N :borders], [:W :shore]];	flags ="INW"
	for k = 1:3
		if ((val = find_in_dict(d, symbs[k])[1]) !== nothing)
			if (isa(val, NamedTuple) || (isa(val, Tuple) && isa(val[1], NamedTuple)))  
				cmd = add_opt(cmd, flags[k], d, symbs[k], (type="/#", level="/#", pen=("", add_opt_pen)))
			elseif (isa(val, Tuple))  cmd *= " -" * flags[k] * parse_pen(val)
			else                      cmd *= " -" * flags[k] * arg2str(val)	# Includes Str, Number or Symb
			end
		end
	end

	if ((val = find_in_dict(d, [:E :DCW])[1]) !== nothing)
		if (isa(val, String) || isa(val, Symbol))
			cmd = string(cmd, " -E", val)			# Simple case, ex E="PT,+gblue"
		elseif (isa(val, NamedTuple))
			cmd = add_opt(cmd, "E", d, [:DCW :E], (country="", name="", continent="=",
			                                       pen=("+p", add_opt_pen), fill=("+g", add_opt_fill)))
		elseif (isa(val, Tuple))
			cmd = parse_dcw(cmd, val)
		end
	end

	if (!occursin("-C",cmd) && !occursin("-E",cmd) && !occursin("-G",cmd) && !occursin("-I",cmd) &&
		!occursin("-M",cmd) && !occursin("-N",cmd) && !occursin("-Q",cmd) && !occursin("-S",cmd) && !occursin("-W",cmd))
		cmd *= " -W0.5p"
	end
	if (!occursin("-D",cmd))  cmd *= " -Da"  end		# Then pick automatic
	finish = !occursin("-M ",cmd) ? true : false		# Otherwise the dump would be redirected to GMTjl_tmp.ps

	return finish_PS_module(d, "pscoast " * cmd, "", K, O, finish)
end

# ---------------------------------------------------------------------------------------------------
function parse_dcw(cmd::String, val::Tuple)
	for k = 1:length(val)
		if (isa(val[k], NamedTuple))
			cmd *= add_opt("", "E", Dict(:DCW => val[k]), [:DCW],
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
coast!(cmd0::String=""; clip=nothing, first=false, kw...) = coast(cmd0; clip=clip, first=first, kw...)

const pscoast  = coast			# Alias for GMT5
const pscoast! = coast!			# Alias for GMT5