"""
pscoast Plot continents, shorelines, rivers, and borders on maps

Plots grayshaded, colored, or textured land-masses [or water-masses] on
maps and [optionally] draws coastlines, rivers, and political
boundaries. A map projection must be supplied.

Full option list at http://gmt.soest.hawaii.edu/doc/latest/pscoast.html

    **Aliases:**

    - A = area
    - B = frame
    - C = river_fill
    - D = resolution
    - E = DCW
    - F = box
    - G = land
    - I = rivers
    - J = proj, projection
    - L = map_scale
    - M = dump
    - N = borders
    - P = portrait
    - R = region, limits
    - S = water
    - Td = rose
    - Tm = compass
    - V = verbose
    - X = x_offset
    - Y = y_offset
    - W = shore
    - bo = binary_out
    - p = perspective
    - t = transparency
	
	Parameters
    ----------
    J : Str
        Select map projection.
    R : Str or list
        'xmin/xmax/ymin/ymax[+r][+uunit]'.
        Specify the region of interest.
    A : Str or number
        'min_area[/min_level/max_level][+ag|i|s|S][+r|l][+ppercent]'
        Features with an area smaller than min_area in km^2 or of
        hierarchical level that is lower than min_level or higher than
        max_level will not be plotted.
    B : Str
        Set map boundary frame and axes attributes.
    C : Str
        Set the shade, color, or pattern for lakes and river-lakes.
    D : Str
        Selects the resolution of the data set to use ((f)ull, (h)igh,
        (i)ntermediate, (l)ow, and (c)rude).
	E : Str; Tuple(Str, Str); Tuple("code", (pen)), ex: ("PT",(0.5,"red","--")); Tuple((...),(...),...)
        'code1,code2,...[+l|L][+gfill][+ppen]'		
        Select painting or dumping country polygons from the Digital Chart of the World
    G : Str
        Select filling or clipping of “dry” areas.
    I : Str
        'river[/pen]'
        Draw rivers. Specify the type of rivers and [optionally] append pen
        attributes.
    N : Str
        'border[/pen]'
        Draw political boundaries. Specify the type of boundary and
        [optionally] append pen attributes
    S : Str
        Select filling or clipping of “wet” areas.
    U : Str or Bool or []
        Draw GMT time stamp logo on plot.
    V : Bool or Str   '[level]'
        Select verbosity level 
		http://gmt.soest.hawaii.edu/doc/latest/psxy.html#v
    W : Str
        '[level/]pen'
        Draw shorelines [Default is no shorelines]. Append pen attributes.
    X : Str    '[a|c|f|r][x-shift[u]]'
    Y : Str    '[a|c|f|r][y-shift[u]]'
        Shift plot origin. 
		http://gmt.soest.hawaii.edu/doc/latest/psxy.html#x
"""
# ---------------------------------------------------------------------------------------------------
function pscoast(cmd0::String=""; Vd=false, portrait=true, fmt="", clip=[], K=false, O=false, first=true, 
                 kwargs...)

	if (length(kwargs) == 0)		# Good, speed mode
		return gmt("pscoast " * cmd0)
	end

	output = fmt
	if (!isa(output, String))
		error("Output format or name must be a String")
	else
		output, opt_T, fname_ext = fname_out(output)		# OUTPUT may have been an extension only
	end

	d = KW(kwargs)
	cmd = ""
	maybe_more = false			# If latter set to true, search for lc & lc pen settings
	cmd, opt_R = parse_R(cmd, d)
	cmd, opt_J = parse_J(cmd, d)
	cmd, opt_B = parse_B(cmd, d)
	cmd = parse_U(cmd, d)
	cmd = parse_V(cmd, d)
	cmd = parse_X(cmd, d)
	cmd = parse_Y(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)
	cmd = parse_bo(cmd, d)

	if (first)  K = true;	O = false
	else        K = true;	O = true;	cmd = replace(cmd, opt_B, "");	opt_B = ""
	end

	if (!isempty(clip))
		if (clip == "land")       cmd = cmd * " -Gc"
		elseif (clip == "water")  cmd = cmd * " -Sc"
		elseif (clip == "end")    cmd = cmd * " -Q"
		else
			warn("The 'clip' argument can only be \"land\", \"water\" or \"end\". Ignoring it.")
		end
	end

	for symb in [:I :rivers]
		if (haskey(d, symb))
			if (isa(d[symb], Number))      cmd = @sprintf("%s -I%d", cmd, d[symb])
			elseif (isa(d[symb], String))  cmd = cmd * " -I" * d[symb]
			elseif (isa(d[symb], Tuple))   cmd = cmd * " -I" * parse_arg_and_pen(d[symb])
			end
			break
		end
	end

	for symb in [:N :borders]
		if (haskey(d, symb))
			if (isa(d[symb], Number))      cmd = @sprintf("%s -N%d", cmd, d[symb])
			elseif (isa(d[symb], String))  cmd = cmd * " -N" * d[symb]
			elseif (isa(d[symb], Tuple))   cmd = cmd * " -N" * parse_arg_and_pen(d[symb])
			end
			break
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
			if (isa(d[symb], Tuple))  cmd = cmd * lev * parse_pen(d[symb])
			else                      cmd = cmd * lev * arg2str(d[symb]);		maybe_more = true
			end
		end
	end

	if (maybe_more)				# Search for color and style line settings
		lc = parse_pen_color(d)
		if (!isempty(lc))
			cmd = cmd * "," * lc
			ls = parse_pen_style(d)
			if (!isempty(ls))		cmd = cmd * "," * ls	end
		end
		maybe_more = false		# and because we can use this only once, deactivate it
	end

	for symb in [:A :area]
		if (haskey(d, symb))
			if (isa(d[symb], String))      cmd = cmd * " -A" * d[symb]
			elseif (isa(d[symb], Number))  cmd = @sprintf("%s -A%d", cmd, d[symb])
			else	error("Nonsense in 'A' argument")
			end
			break
		end
	end

	for symb in [:C :river_fill]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -C" * d[symb]
			break
		end
	end

	for symb in [:D :resolution]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = string(cmd, " -D", d[symb][1])
			break
		end
	end

	for sb in [:E :DCW]
		if (haskey(d, sb))
			if (isa(d[sb], String))
				cmd = cmd * " -E" * d[sb]							# Simple case, ex E="PT,+gblue"
			elseif (isa(d[sb], Tuple))
				if (length(d[sb]) == 2 && isa(d[sb][1], Char) && isa(d[sb][2], Char))			# ex E=("PT","+p0.5")
					cmd = string(cmd, " -E", d[sb][1], ",", d[sb][2])
				elseif (length(d[sb]) == 2 && isa(d[sb][1], Char) && isa(d[sb][2], Tuple))		# ex E=("PT",(0.5,"red","--"))
					cmd = string(cmd, " -E", d[sb][1], ",+p", parse_pen(d[sb][2]))
				elseif (length(d[sb]) >= 2 && isa(d[sb][1], Tuple) && isa(d[sb][end], Tuple)) 	# ex E=((),(),...,())
					for k = 1:length(d[sb])
						if (isa(d[sb][k][2], Char))  cmd = string(cmd, " -E", d[sb][k][1], ",", d[sb][k][2])
						else                         cmd = string(cmd, " -E", d[sb][k][1], ",+p", parse_pen(d[sb][k][2]))
						end
					end
				end
			else
				error("Arguments of E can only be a String or a Tuple (or Tuple of Tuples")
			end
			break
		end
	end

	for symb in [:F :box]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -F" * d[symb]
			break
		end
	end

	for symb in [:G :land]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -G" * d[symb]
			break
		end
	end

	for symb in [:L :map_scale]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -L" * d[symb]
			break
		end
	end

	if (haskey(d, :M) || haskey(d, :dump))
		cmd = cmd * " -M"
	end

	for symb in [:S :water]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -S" * d[symb]
			break
		end
	end

	for symb in [:Td :rose]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -Td" * d[symb]
			break
		end
	end

	for symb in [:Tm :compass]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -Tm" * d[symb]
			break
		end
	end

	cmd = finish_PS(cmd0, cmd, output, portrait, K, O)

	if (haskey(d, :ps)) PS = true			# To know if returning PS to the REPL was requested
	else                PS = false
	end

	Vd && println(@sprintf("\tpscoast %s", cmd))

	P = nothing
	if (PS) P = gmt("pscoast " * cmd)
	else        gmt("pscoast " * cmd)
	end
	if (haskey(d, :show)) 					# Display Fig in default viewer
		showfig(output, fname_ext, opt_T, K)
	elseif (haskey(d, :savefig))
		showfig(output, fname_ext, opt_T, K, d[:savefig])
	end
	return P
end
