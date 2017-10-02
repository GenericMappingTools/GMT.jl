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
function psxy(cmd0::String="", arg1=[]; V=false, caller=[], data=[], portrait=true, output="",
              K=false, O=false,  ps=false, kwargs...)

	if (length(kwargs) == 0 && isempty(arg1) && isempty(data))			# Good, the speedy mode
		if (isempty(arg1))
			return gmt("psxy " * cmd0)
		else
			return gmt("psxy " * cmd0, arg1)
		end
	end

	if (!isempty(data) && !isempty(arg1))
		warn("Conflicting ways of providing input data. Both a file name via positional and
			  a data array via keyword args were provided. Ignoring former argument")
	end

	if (!isa(output, String))
		error("Output name must be a String")
	end

    d = KW(kwargs)
	cmd = ""
	cmd, opt_R = parse_R(cmd, d)
	cmd, opt_J = parse_J(cmd, d)
	cmd, opt_B = parse_B(cmd, d)
	cmd = parse_U(cmd, d)
	cmd = parse_V(cmd, d)
	cmd = parse_X(cmd, d)
	cmd = parse_Y(cmd, d)
	cmd = parse_a(cmd, d)
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_di = parse_di(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_g(cmd, d)
	cmd = parse_h(cmd, d)
	cmd, opt_i = parse_i(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)
	cmd = parse_swapxy(cmd, d)

	# Read in the 'data' and compute a tight -R if this was not provided 
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
	if (!isempty(data)) arg1 = data  end

	if (isempty(opt_R))
		info = gmt("gmtinfo -C" * opt_i, arg1)		# Here we reading from an original GMTdataset or Array
		if (size(info[1].data, 2) < 4)
			error("Need at least 2 columns of data to run this program")
		end
		opt_R = @sprintf(" -R%.8g/%.8g/%.8g/%.8g", info[1].data[1], info[1].data[2], info[1].data[3], info[1].data[4])
		cmd = cmd * opt_R
	end

	# If we have no -J use this default
	if (isempty(opt_J))  cmd = cmd * " -JX12c/8c"  end

	for sym in [:A :straight_lines]
		if (haskey(d, sym))
			cmd = cmd * " -A" * arg2str(d[sym])
			break
		end
	end

	for sym in [:C :color]
		if (haskey(d, sym))
			cmd = cmd * " -C" * arg2str(d[sym])
			break
		end
	end

	for sym in [:D :offset]
		if (haskey(d, sym))
			cmd = cmd * " -D" * arg2str(d[sym])
			break
		end
	end

	for sym in [:E :error_bars]
		if (haskey(d, sym))
			cmd = cmd * " -E" * arg2str(d[sym])
			break
		end
	end

	for sym in [:F :conn :connection]
		if (haskey(d, sym))
			cmd = cmd * " -F" * arg2str(d[sym])
			break
		end
	end

	for sym in [:G :fill]
		if (haskey(d, sym))
			cmd = cmd * " -G" * arg2str(d[sym])
			break
		end
	end
	opt_Gsymb = ""			# Filling color for symbols
	for sym in [:G :markerfacecolor :MarkerFaceColor]
		if (haskey(d, sym))
			opt_Gsymb = " -G" * arg2str(d[sym])
			break
		end
	end

	opt_Wmarker = ""
	for sym in [:markeredgecolor :MarkerEdgeColor]
		if (haskey(d, sym))
			opt_Wmarker = "0.5p," * arg2str(d[sym])		# 0.25p is so thin
			break
		end
	end

	for sym in [:I :intens]
		if (haskey(d, sym))
			cmd = cmd * " -I" * arg2str(d[sym])
			break
		end
	end

	for sym in [:L :closed_polygon]
		if (haskey(d, sym))
			cmd = cmd * " -L" * arg2str(d[sym])
			break
		end
	end

	for sym in [:N :no_clip]
		if (haskey(d, sym))
			cmd = cmd * " -N" * arg2str(d[sym])
			break
		end
	end

	opt_W = ""
	pen = build_pen(d)						# Either a full pen string or empty ("")
	if (!isempty(pen))
		opt_W = " -W" * pen
	else
		for sym in [:W :line_attrib]
			if (haskey(d, sym))
				if (isa(d[sym], String))
					opt_W = " -W" * arg2str(d[sym])
				elseif (isa(d[sym], Tuple))	# Like this it can hold the pen, not extended atts
					opt_W = " -W" * parse_pen(d[sym])
				else
					error("Nonsense in W option")
				end
				break
			end
		end
	end

	opt_S = ""
	for sym in [:S :symbol]
		if (haskey(d, sym))
			opt_S = " -S" * arg2str(d[sym])
			break
		end
	end
	if (isempty(opt_S))			# OK, no symbol given via the -S option. So fish in aliases
		marca = ""
		for sym in [:marker :Marker]
			if (haskey(d, sym))
				if (d[sym] == "-"     || d[sym] == "x-dash")   marca = "-"
				elseif (d[sym] == "+" || d[sym] == "plus")     marca = "+"
				elseif (d[sym] == "a" || d[sym] == "*" || d[sym] == "star")     marca = "a"
				elseif (d[sym] == "c" || d[sym] == "circle")   marca = "c"
				elseif (d[sym] == "d" || d[sym] == "diamond")  marca = "d"
				elseif (d[sym] == "g" || d[sym] == "octagon")  marca = "g"
				elseif (d[sym] == "h" || d[sym] == "hexagon")  marca = "h"
				elseif (d[sym] == "i" || d[sym] == "v" || d[sym] == "inverted_tri")  marca = "i"
				elseif (d[sym] == "n" || d[sym] == "pentagon")  marca = "n"
				elseif (d[sym] == "p" || d[sym] == "." || d[sym] == "point")     marca = "p"
				elseif (d[sym] == "r" || d[sym] == "rectangle") marca = "r"
				elseif (d[sym] == "s" || d[sym] == "square")    marca = "s"
				elseif (d[sym] == "t" || d[sym] == "^" || d[sym] == "triangle")  marca = "t"
				elseif (d[sym] == "x" || d[sym] == "cross")     marca = "x"
				elseif (d[sym] == "y" || d[sym] == "y-dash")    marca = "y"
				end
				break
			end
		end
		if (!isempty(marca))
			done = false
			for sym in [:markersize :MarkerSize :size]
				if (haskey(d, sym))
					marca = marca * arg2str(d[sym])
					done = true
					break
				end
			end
			if (!done)  marca = marca * "8p"  end			# Default to 8p
		end
		if (!isempty(marca))  opt_S = " -S" * marca  end
	end

	if (!isempty(caller) && isempty(opt_B) && searchindex(cmd0,"-B") != 0 && searchindex(cmd, "-JX") != 0)		# 'caller' isn't empty when called from 'plot'
		cmd = cmd * " -Ba -BWS"
	end

	if (!isempty(opt_W) && isempty(opt_S)) 			# We have a line/polygon request
		cmd = [finish_PS(cmd0, cmd * opt_W, output, portrait, K, O)]
	elseif (isempty(opt_W) && !isempty(opt_S))		# We have a symbol request
		if (!isempty(opt_Wmarker) && isempty(opt_W))
			opt_Gsymb = opt_Gsymb * " -W" * opt_Wmarker	# Piggy back in this option string
		end
		cmd = [finish_PS(cmd0, cmd * opt_S * opt_Gsymb, output, portrait, K, O)]
	elseif (!isempty(opt_W) && !isempty(opt_S))		# We have both line/polygon and symbol requests 
		if (!isempty(opt_Wmarker))
			opt_Wmarker = " -W" * opt_Wmarker		# Set Symbol edge color 
		end
		cmd1 = cmd * opt_W
		cmd2 = replace(cmd, opt_B, "") * opt_S * opt_Gsymb * opt_Wmarker	# Don't repeat option -B
		cmd = [finish_PS(cmd0, cmd1, output, portrait, true, O)
			   finish_PS(cmd0, cmd2, output, portrait, K, true)]
	else
		cmd = [finish_PS(cmd0, cmd, output, portrait, K, O)]
	end

	P = nothing
	for k = 1:length(cmd)
		V && println(@sprintf("\tpsxy %s", cmd[k]))
		if (!isempty(arg1))					# A numeric input
			if (ps) P = gmt("psxy " * cmd[k], arg1)
			else        gmt("psxy " * cmd[k], arg1)
			end
		else								# Ploting from file
			if (ps) P = gmt("psxy " * cmd[k])
			else        gmt("psxy " * cmd[k])
			end
		end
	end
	return P
end

#=
WTF I can do this

julia> foo(a::String="", b=[]; v=false, c=[], kw...) = 1
foo (generic function with 3 methods)

julia> foo(a=[], b::String=""; v=false, c=[], kw...) = foo(b, a; v=false, c=[], kw...)
foo (generic function with 5 methods)

But not this

psxy(arg1=[], cmd0::String=""; V=false, data=[], portrait=true, output=[], K=false, O=false,  kwargs...) =
	psxy(cmd0, arg1; V=V, data=data, portrait=portrait, output=output, K=K, O=O,  kwargs...)

WARNING: Method definition psxy() in module GMT at c:\j\.julia\v0.6\GMT\src\psxy.jl:45 overwritten at c:\j\.julia\v0.6\GMT\src\psxy.jl:252.
WARNING: Method definition #psxy(Array{Any, 1}, typeof(GMT.psxy)) in module GMT overwritten.
=#