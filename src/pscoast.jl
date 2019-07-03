"""
    coast(cmd0::String=""; kwargs...)

Plot continents, shorelines, rivers, and borders on maps.
Plots grayshaded, colored, or textured land-masses [or water-masses] on
maps and [optionally] draws coastlines, rivers, and political
boundaries. A map projection must be supplied.

Full option list at [`pscoast`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html)

Parameters
----------

- $(GMT.opt_J)
- $(GMT.opt_R)
- **A** : **area** : -- Str or Number --

    Features with an area smaller than min_area in km^2 or of
    hierarchical level that is lower than min_level or higher than
    max_level will not be plotted.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#a)
- $(GMT.opt_B)
- **C** : **river_fill** : -- Str --

    Set the shade, color, or pattern for lakes and river-lakes.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#c)
- **D** : **res** : **resolution** : -- Str --		Flags = c|l|i|h|f|a

    Selects the resolution of the data set to use ((f)ull, (h)igh, (i)ntermediate, (l)ow, (c)rude), or (a)uto).
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#d)
- **E** : **DCW** : -- Str --

    Select painting or dumping country polygons from the Digital Chart of the World.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#e)
    + Tuple("code", Str); Tuple("code" [,"fill"], (pen)); Tuple((...),(...),...)
    + ex: ("PT",(0.5,"red","--")); (("PT","gblue",(0.5,"red"),("ES",(0.5,"yellow")))
- **F** : **box** : -- Str --

    Draws a rectangular border around the map scale or rose.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#f)
- **G** : **land** : -- Str --

    Select filling or clipping of “dry” areas.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#g)
- **I** : **rivers** : -- Str --

    Draw rivers. Specify the type of rivers and [optionally] append pen attributes.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#i)
- **L** : **map_scale** : -- Str --

    Draw a map scale.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#l)
- **M** : **dump** : -- Str --

    Dumps a single multisegment ASCII output. No plotting occurs.
    [`-M`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#m)
- **N** : **borders** : -- Str --

    Draw political boundaries. Specify the type of boundary and [optionally] append pen attributes
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#n)
- $(GMT.opt_P)
- **clip** : -- Str --		Flags = land|water|end

    To clip land do *clip=:land*, *clip=:water* clips water. Use *end* to mark end of existing clip path.
    No projection information is needed.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#q)
- **S** : **water** : **ocean** : -- Str --

    Select filling or clipping of “wet” areas.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#s)
- **Td** : **rose`** : -- Str --

    Draws a map directional rose on the map at the location defined by the reference and anchor points.
    [`-Td`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#t)
- **Tm** : **compass** : -- Str --

    Draws a map magnetic rose on the map at the location defined by the reference and anchor points.
    [`-Tm`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#t)
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** : **shore** : -- Str --
    Draw shorelines [Default is no shorelines]. Append pen attributes.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/pscoast.html#w)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bo)
- $(GMT.opt_p)
- $(GMT.opt_t)
"""
function coast(cmd0::String=""; clip=nothing, first=true, kwargs...)

	length(kwargs) == 0 && clip == nothing && return monolitic("pscoast", cmd0)

	d = KW(kwargs)
	output, opt_T, fname_ext, K, O = fname_out(d, first)		# OUTPUT may have been an extension only

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

	return finish_PS_module(d, "pscoast " * cmd, "", output, fname_ext, opt_T, K, O, finish)
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