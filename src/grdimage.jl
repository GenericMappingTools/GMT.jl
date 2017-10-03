"""
pscoast Plot continents, shorelines, rivers, and borders on maps

Plots grayshaded, colored, or textured land-masses [or water-masses] on

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
	U : Str or []
		Draw GMT time stamp logo on plot.
	V : bool or Str
	W : Str
		'[level/]pen'
		Draw shorelines [Default is no shorelines]. Append pen attributes.
"""
# ---------------------------------------------------------------------------------------------------
function grdimage(cmd0::String="", arg1=[], arg2=[], arg3=[]; V=false, data=[], portrait=true, 
                                   fmt="", K=false, O=false, first=true, kwargs...)

	if (length(kwargs) == 0)		# Good, speed mode
		return gmt("grdimage " * cmd0)
	end

	if (!isempty(data) && isa(data, Tuple) && !isa(data[1], GMTgrid))
		error("When 'data' is a tuple, it MUST contain a GMTgrid data type")
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
	cmd = parse_f(cmd, d)
	cmd = parse_n(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)

	if (first)  K = true;	O = false
	else        K = true;	O = true;	cmd = replace(cmd, opt_B, "");	opt_B = ""
	end

	for symb in [:A :img_out :image_out]
		if (haskey(d, symb) && isa(d[symb], String))
			cmd = cmd * " -A" * d[symb]
			break
		end
	end

	for symb in [:C :color]
		if (haskey(d, symb))
			cmd = cmd * " -C" * arg2str(d[symb])
			break
		end
	end

	for symb in [:D :img_in :image_in]
		if (haskey(d, symb))
			cmd = cmd * " -D" * arg2str(d[symb])
			break
		end
	end

	for symb in [:E :dpi :DPI]
		if (haskey(d, symb))
			cmd = cmd * " -E" * arg2str(d[symb])
			break
		end
	end

	for symb in [:G]
		if (haskey(d, symb))
			cmd = cmd * " -G" * arg2str(d[symb])
			break
		end
	end

	for symb in [:I :shade :intensity :intensfile]
		if (haskey(d, symb))
			cmd = cmd * " -I" * arg2str(d[symb])
			break
		end
	end

	for symb in [:M :monocrome]
		if (haskey(d, symb))
			cmd = cmd * " -M" * arg2str(d[symb])
			break
		end
	end

	for symb in [:N :noclip]
		if (haskey(d, symb))
			cmd = cmd * " -N" * arg2str(d[symb])
			break
		end
	end

	for symb in [:Q :nan_t :nan_transparent]
		if (haskey(d, symb))
			cmd = cmd * " -Q" * arg2str(d[symb])
			break
		end
	end

	if (!isempty(data))
		if (!isempty(arg1))
			warn("Conflicting ways of providing input data. Both a file name via positional and
				  a data array via kwyword args were provided. Ignoring later argument")
		else
			if (isa(data, String)) 		# OK, we have data via file
				cmd = cmd * " " * data
			elseif (isa(data, Tuple) && length(data) == 3)
				arg1 = data[1];     arg2 = data[2];     arg3 = data[3]
			else
				arg1 = data				# Whatever this is
			end
		end
	end

	cmd = finish_PS(cmd0, cmd, output, portrait, K, O)

	if (haskey(d, :ps)) PS = true			# To know if returning PS to the REPL was requested
	else                PS = false
	end

	V && println(@sprintf("\tgrdimage %s", cmd))

	P = nothing
	if (!isempty(arg1) && isempty(arg2))
		if (PS) P = gmt("grdimage " * cmd, arg1)                 # A numeric input
		else        gmt("grdimage " * cmd, arg1)
		end
	elseif (!isempty(arg1) && !isempty(arg3))
		if (PS) P = gmt("grdimage " * cmd, arg1, arg2, arg3)     # The three R, G, B grids case
		else        gmt("grdimage " * cmd, arg1, arg2, arg3)
		end
	else
		if (PS) P = gmt("grdimage " * cmd)                       # Ploting from file
		else        gmt("grdimage " * cmd)
		end
	end
	if (haskey(d, :show)) 										# Display Fig in default viewer
		showfig(output, fname_ext, opt_T, K)
	elseif (haskey(d, :savefig))
		showfig(output, fname_ext, opt_T, K, d[:savefig])
	end
	return P
end