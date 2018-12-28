"""
    coast(cmd0::String=""; clip=[], kwargs...)

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
- **S** : **water** : -- Str --

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
function coast(cmd0::String=""; clip=[], first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("pscoast", cmd0, arg1)

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	maybe_more = false				# If latter set to true, search for lc & lc pen settings
	K, O = set_KO(first)		# Set the K O dance
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12cd/0")
	cmd = parse_common_opts(d, cmd, [:UVXY :bo :p :t :params])
	cmd = parse_these_opts(cmd, d, [[:A :area], [:C :river_fill], [:D :res :resolution], [:G :land],
				[:L :map_scale], [:M :dump], [:S :water], [:Td :rose], [:Tm :compass]])

	cmd = add_opt(cmd, 'F', d, [:F :box], (clearance="+c", fill=("+g", add_opt_fill), inner="+i",
	                                       pen=("+p", add_opt_pen), rounded="+r", shade="+s"))

	if (!isempty_(clip))
		if (clip == "land" || clip == :land)       cmd *= " -Gc"
		elseif (clip == "water" || clip == :water) cmd *= " -Sc"
		elseif (clip == "end" || clip == :end)     cmd *= " -Q"
		else
			@warn("The 'clip' argument can only be \"land\", \"water\" or \"end\". Ignoring it.")
		end
	end

	if ((val = find_in_dict(d, [:I :rivers])[1]) !== nothing)
		if (isa(val, Number))      cmd = @sprintf("%s -I%d", cmd, val)
		elseif (isa(val, String))  cmd *= " -I" * val
		elseif (isa(val, Tuple))   cmd *= " -I" * parse_arg_and_pen(val)
		end
	end

	if ((val = find_in_dict(d, [:N :borders])[1]) !== nothing)
		if (isa(val, Number))      cmd = @sprintf("%s -N%d", cmd, val)
		elseif (isa(val, String))  cmd *= " -N" * val
		elseif (isa(val, Tuple))   cmd *= " -N" * parse_arg_and_pen(val)
		end
	end

	for symb in [:W :shore :shore1 :shore2 :shore3 :shore4]
		if (haskey(d, symb))
			if (symb == :shore || symb == :W) lev = " -W"
			elseif (symb == :shore1)          lev = " -W1/"
			elseif (symb == :shore2)          lev = " -W2/" 
			elseif (symb == :shore3)          lev = " -W3/" 
			elseif (symb == :shore4)          lev = " -W4/" 
			end
			if (isa(d[symb], Tuple))  cmd *= lev * parse_pen(d[symb])
			else                      cmd *= lev * arg2str(d[symb]);		maybe_more = true
			end
		end
	end

	if (maybe_more)				# Search for color and style line settings
		lc = parse_pen_color(d)
		if (lc != "")
			cmd *= "," * lc
			ls = add_opt("", "", d, [:ls :linestyle], nothing)
			if (ls != "")  cmd *= "," * ls	end
		end
	end

	if ((val = find_in_dict(d, [:E :DCW])[1]) !== nothing)
		if (isa(val, String))
			cmd *= " -E" * val					# Simple case, ex E="PT,+gblue"
		elseif (isa(val, Tuple))
			if (length(val) >= 2 && isa(val[1], Tuple) && isa(val[end], Tuple)) 	# ex E=((),(),...,())
				for k = 1:length(val)
					cmd = parse_dcw(val[k], cmd)
				end
			else
				cmd = parse_dcw(val, cmd)
			end
		else
			error("Arguments of E can only be a String or a Tuple (or Tuple of Tuples")
		end
	end

	if (!occursin("-C",cmd) && !occursin("-E",cmd) && !occursin("-G",cmd) && !occursin("-I",cmd) &&
		!occursin("-M",cmd) && !occursin("-N",cmd) && !occursin("-Q",cmd) && !occursin("-S",cmd) && !occursin("-W",cmd))
		cmd *= " -W0.5p"
	end
	if (!occursin("-D",cmd))  cmd *= " -Da"  end		# Then pick automatic

	cmd = finish_PS(d, cmd, output, K, O)
    return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, "pscoast")
end

# ---------------------------------------------------------------------------------------------------
function parse_dcw(val::Tuple, cmd::String)
	# Parse the multiple forms that the -E option may assume
	if (length(val) >= 2 && isa(val[1], String) && isa(val[2], String) && isa(val[end], String))
		# ex: E=("PT","+p0.5") or E=("PT","+p0.5","+gblue")
		cmd = string(cmd, " -E", val[1], ",", val[2])
		if (length(val) == 3)  cmd = string(cmd, ",", val[3])  end
	elseif (length(val) >= 2 && isa(val[1], String))
		if (length(val) == 2 && isa(val[2], Tuple))			# ex: E=("PT", (0.5,"red","--"))
			cmd = string(cmd, " -E", val[1], ",+p", parse_pen(val[2]))
		elseif (length(val) == 3 && isa(val[2], Tuple) && isa(val[3], String))
			# ex: E=("PT", (0.5, "red", "--"), "+gblue")
			cmd = string(cmd, " -E", val[1], ",+p", parse_pen(val[2]), val[3])
		elseif (length(val) == 3 && isa(val[3], Tuple) && isa(val[2], String))
			# ex: E=("PT", "+gblue", (0.5,"red","--"))
			cmd = string(cmd, " -E", val[1], val[2], ",+p", parse_pen(val[3]))
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
coast!(cmd0::String=""; clip=[], first=false, kw...) = coast(cmd0; clip=clip, first=first, kw...)

const pscoast  = coast			# Alias for GMT5
const pscoast! = coast!			# Alias for GMT5