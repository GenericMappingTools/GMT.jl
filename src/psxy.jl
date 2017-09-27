"""
psxy reads (x,y) pairs from files [or standard input] and generates PostScript code that will plot lines,
polygons, or symbols at those locations on a map. If a symbol is selected and no symbol size given,
then psxy will interpret the third column of the input data as symbol size. Symbols whose size is <= 0 are skipped.
If no symbols are specified then the symbol code must be present as last column in the input. If -S is not used,
a line connecting the data points will be drawn instead. To explicitly close polygons, use -L.
Select a fill with -G. If -G is set, -W will control whether the polygon outline is drawn or not.
If a symbol is selected, -G and -W determines the fill and outline/no outline, respectively.

Full option list at http://gmt.soest.hawaii.edu/doc/latest/pscoast.html

    **Aliases:**

    - A = straight_lines
    - B = frame
    - C = color
    - D = offset
    - E = error_bars
    - F = conn, connection
    - G = fill
    - I = intens
    - J = proj, projection
    - L = closed_polygon
    - N = no_clip
    - P = portrait
    - R = region, limits
    - V = verbose
    - X = x_offset
    - Y = y_offset
    - W = line_attribs
    - a = aspatial
    - bi = binary_in
    - di = nodata_in
    - e = patern
    - f = colinfo
    - g = gaps
    - h = headers
    - i = input_col
    - p = perspective
    - t = transparency
"""
# ---------------------------------------------------------------------------------------------------
function psxy(cmd0::String="", arg1=[]; Vd=false, data=[], portrait=true, output=[], K=false, O=false,  kwargs...)

	if (length(kwargs) == 0)			# Good, the speedy mode
		return gmt("psxy " * cmd0)
	end

	if (isempty(output))          fname = "lixo.ps"
	elseif (isa(output, String))  fname = output
	else error("Output name must be a String")
	end

    d = KW(kwargs)
	cmd = ""
	cmd = parse_R(cmd, d)
	cmd = parse_J(cmd, d)
	cmd = parse_B(cmd, d)
	cmd = parse_U(cmd, d)
	cmd = parse_V(cmd, d)
	cmd = parse_X(cmd, d)
	cmd = parse_Y(cmd, d)
	cmd = parse_a(cmd, d)
	cmd = parse_bi(cmd, d)
	cmd = parse_di(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_g(cmd, d)
	cmd = parse_h(cmd, d)
	cmd = parse_i(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)
	cmd = parse_swapxy(cmd, d)

	for symb in [:A :straight_lines]
		if (haskey(d, symb))
			cmd = cmd * " -A" * arg2str(d[symb])
			break
		end
	end

	for symb in [:C :color]
		if (haskey(d, symb))
			cmd = cmd * " -C" * arg2str(d[symb])
			break
		end
	end

	for symb in [:D :offset]
		if (haskey(d, symb))
			cmd = cmd * " -D" * arg2str(d[symb])
			break
		end
	end

	for symb in [:E :error_bars]
		if (haskey(d, symb))
			cmd = cmd * " -E" * arg2str(d[symb])
			break
		end
	end

	for symb in [:F :conn :connection]
		if (haskey(d, symb))
			cmd = cmd * " -F" * arg2str(d[symb])
			break
		end
	end

	for symb in [:G :fill]
		if (haskey(d, symb))
			cmd = cmd * " -G" * arg2str(d[symb])
			break
		end
	end

	for symb in [:I :intens]
		if (haskey(d, symb))
			cmd = cmd * " -I" * arg2str(d[symb])
			break
		end
	end

	for symb in [:L :closed_polygon]
		if (haskey(d, symb))
			cmd = cmd * " -L" * arg2str(d[symb])
			break
		end
	end

	for symb in [:N :no_clip]
		if (haskey(d, symb))
			cmd = cmd * " -N" * arg2str(d[symb])
			break
		end
	end

	pen = build_pen(d)						# Either a full pen string or empty ("")
	for symb in [:W :line_attrib]
		if (haskey(d, symb))
			if (isa(d[symb], String))		# Will screw if it has the [pen] and pen is not empty
				cmd = cmd * " -W" * pen * arg2str(d[symb])
			elseif (isa(d[symb], Tuple))	# Like this it can hold the pen, not extended atts
				pen = parse_pen(d[symb])	# If 'pen' already existed ...
				cmd = cmd * " -W" * pen
			else
				error("Nonsense in W option")
			end
			break
		end
	end

	s = ""
	for symb in [:S :symbol]
		if (haskey(d, symb))
			s = " -S" * arg2str(d[symb])
			break
		end
	end
	if (isempty(s))			# OK, no symbol given via the -S option. So fish in aliases
		marca = ""
		if (haskey(d, :marker))
			if (d[:marker] == "-"     || d[:marker] == "x-dash")   marca = "-"
			elseif (d[:marker] == "+" || d[:marker] == "plus")     marca = "+"
			elseif (d[:marker] == "a" || d[:marker] == "star")     marca = "a"
			elseif (d[:marker] == "c" || d[:marker] == "circle")   marca = "c"
			elseif (d[:marker] == "d" || d[:marker] == "diamond")  marca = "d"
			elseif (d[:marker] == "g" || d[:marker] == "octagon")  marca = "g"
			elseif (d[:marker] == "h" || d[:marker] == "hexagon")  marca = "h"
			elseif (d[:marker] == "i" || d[:marker] == "inverted_tri")  marca = "i"
			elseif (d[:marker] == "n" || d[:marker] == "pentagon")  marca = "n"
			elseif (d[:marker] == "p" || d[:marker] == "point")     marca = "p"
			elseif (d[:marker] == "r" || d[:marker] == "rectangle") marca = "r"
			elseif (d[:marker] == "s" || d[:marker] == "square")    marca = "s"
			elseif (d[:marker] == "t" || d[:marker] == "triangle")  marca = "t"
			elseif (d[:marker] == "x" || d[:marker] == "cross")     marca = "x"
			elseif (d[:marker] == "y" || d[:marker] == "y-dash")    marca = "y"
			end
		end
		if (!isempty(marca))
			if (haskey(d, :size))
				marca = marca * arg2str(d[:size])
			else
				marca = marca * "8p"			# Default to 8p
			end
		end
		s = " -S" * marca
	end
	if (!isempty(s))
		cmd = cmd * s
	end

	if (!isempty(data))
		if (!isempty(arg1))
			warn("Conflicting ways of providing input data. Both a file name via positional and
			      a data array via kwyword args were provided. Ignoring later argument")
		else
			if (isa(data, String)) 		# OK, we have data via file
				cmd = cmd * " " * data
			else
				arg1 = data				# Whatever this is
			end
		end
	end

	cmd = finish_PS(cmd0, cmd, fname, output, portrait, K, O)

	#Vd && @show(@sprintf("psxy %s", cmd))
	Vd && println(@sprintf("\tpsxy %s", cmd))
	if (!isempty(arg1))
		return gmt("psxy " * cmd, arg1)    # A numeric input
	else
		return gmt("psxy " * cmd)          # Ploting from file
	end
end