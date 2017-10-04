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
    - B = frame, axes
    - C = color
    - D = offset
    - E = error_bars
    - F = conn, connection
    - G = fill, markerfacecolor, MarkerFaceColor
    - I = intens
    - J = proj, projection
    - L = closed_polygon
    - N = no_clip
    - P = portrait
    - R = region, limits
    - S = symbol, marker, Marker
    - U = stamp
    - V = verbose
    - X = x_offset
    - Y = y_offset
    - W = line_attribs, markeredgecolor, MarkerEdgeColor
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
	
	Parameters
    ----------
    J : proj : projection : -- Str --
        Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.
        http://gmt.soest.hawaii.edu/doc/latest/psxy.html#j
    R : region : limits : -- Str or list --    'xmin/xmax/ymin/ymax[+r][+uunit]'.
        Specify the region of interest. Set to data minimum BoundinBox if not provided.
        http://gmt.soest.hawaii.edu/doc/latest/psxy.html#r
    B : frame : axes : -- Str --  '[p|s]parameters'
        Set map boundary frame and axes attributes.
        http://gmt.soest.hawaii.edu/doc/latest/psxy.html#b
    C : color : -- Str --
        Give a CPT or specify -Ccolor1,color2[,color3,...] to build a linear continuous CPT from those colors automatically.
        http://gmt.soest.hawaii.edu/doc/latest/psxy.html#c
    D : offset : -- Str --  'dx/dy'
        Offset the plot symbol or line locations by the given amounts dx/dy.
    E : error_bars : -- Str --   '[x|y|X|Y][+a][+cl|f][+n][+wcap][+ppen]'
        Draw symmetrical error bars.
        http://gmt.soest.hawaii.edu/doc/latest/psxy.html#e
    F : conn : connection : -- Str --   '[c|n|r][a|f|s|r|refpoint]'
        Alter the way points are connected
        http://gmt.soest.hawaii.edu/doc/latest/psxy.html#f
    G : fill : markerfacecolor : MarkerFaceColor : -- Str --
        Select color or pattern for filling of symbols or polygons. BUT WARN: the alias 'fill' will set the
        color of polygons OR symbols but not the two together. If your plot has polygons and symbols, use
        'fill' for the polygons and 'markerfacecolor' for filling the symbols. Same applyies for W bellow
        http://gmt.soest.hawaii.edu/doc/latest/psxy.html#g
    I : intens : -- Str or number --
        Use the supplied intens value (in the [-1 1] range) to modulate the fill color by simulating illumination.
    L : closed_polygon : -- Str --    '[+b|d|D][+xl|r|x0][+yl|r|y0][+ppen]'
        Force closed polygons. 
        http://gmt.soest.hawaii.edu/doc/latest/psxy.html#l
    N : no_clip : --- Str or [] --   '[c|r]'
        Do NOT clip symbols that fall outside map border 
    S : symbol : marker : Marker : -- Str --  '[symbol][size[u]]'
        Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines). 
        http://gmt.soest.hawaii.edu/doc/latest/psxy.html#s
        Alternatively select a sub-set of symbols using the aliases: 'marker' or 'Marker' and values: 
           "-" or "x-dash"
           "+" or "plus"
           "a" or "*" or "star"
           "c" or "circle"
           "d" or "diamond"
           "g" or "octagon"
           "h" or "hexagon"
           "i" or "v" or "inverted_tri"
           "n" or "pentagon"
           "p" or "." or "point"
           "r" or "rectangle"
           "s" or "square"
           "t" or "^" or "triangle"
           "x" or "cross"
           "y" or "y-dash"
    W : line_attribs : markeredgecolor : MarkerEdgeColor : -- Str --  '[pen][attr]'
        Set pen attributes for lines or the outline of symbols
		http://gmt.soest.hawaii.edu/doc/latest/psxy.html#w
        WARNING: the pen attributes will set the pen of polygons OR symbols but not the two together.
        If your plot has polygons and symbols, use 'W' or 'line_attribs' for the polygons and
        'markeredgecolor' or 'MarkerEdgeColor' for filling the symbols. Similar to S above.
    U : stamp : --- Str or Bool or [] --   '[[just]/dx/dy/][c|label]'
        Draw GMT time stamp logo on plot.
    V : verbose : -- Bool or Str --   '[level]'
        Select verbosity level 
		http://gmt.soest.hawaii.edu/doc/latest/psxy.html#v
    X : x_offset : -- Str --   '[a|c|f|r][x-shift[u]]'
    Y : x_offset : -- Str --   '[a|c|f|r][y-shift[u]]'
        Shift plot origin. 
		http://gmt.soest.hawaii.edu/doc/latest/psxy.html#x
"""
# ---------------------------------------------------------------------------------------------------
function psxy(cmd0::String="", arg1=[]; Vd=false, caller=[], data=[], portrait=true, fmt="",
              K=false, O=false, first=true, kwargs...)

	arg2 = []		# May be needed if GMTcpt type is sent in via C
	N_args = isempty(arg1) ? 0 : 1

	if (length(kwargs) == 0 && N_args == 0 && isempty(data))			# Good, the speedy mode
		if (N_args == 0)  return gmt("psxy " * cmd0)
		else              return gmt("psxy " * cmd0, arg1)
		end
	end

	if (!isempty(data) && N_args == 1)
		warn("Conflicting ways of providing input data. Both a file name via positional and
			  a data array via keyword args were provided. Ignoring former argument")
	end

	output = fmt
	if (!isa(output, String))
		error("Output format or name must be a String")
	else
		output, opt_T, fname_ext = fname_out(output)		# OUTPUT may have been an extension only
	end

    d = KW(kwargs)
	cmd = ""
	cmd, opt_R = parse_R(cmd, d, O)
	cmd, opt_J = parse_J(cmd, d, O)
	if (!O && isempty(opt_J))					# If we have no -J use this default
		opt_J = " -JX12c/8c"
		cmd = cmd * opt_J
	end
	if (!isempty(caller) && searchindex(cmd0,"-B") == 0 && searchindex(opt_J, "-JX") != 0)	# e.g. plot() sets 'caller'
		cmd, opt_B = parse_B(cmd, d, "-Ba -BWS")
	else
		cmd, opt_B = parse_B(cmd, d)
	end
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

	if (first)  K = true;	O = false
	else        K = true;	O = true;	cmd = replace(cmd, opt_B, "");	opt_B = ""
	end

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

	for sym in [:C :color]
		if (haskey(d, sym))
			if (isa(d[sym], GMT.GMTcpt))
				cmd = cmd * " -C"
				if     (N_args == 0)  arg1 = d[sym];	N_args += 1
				elseif (N_args == 1)  arg2 = d[sym];	N_args += 1
				else   error("Can't send the CPT data via C and input array")
				end
			else
				cmd = cmd * " -C" * arg2str(d[sym])
			end
			break
		end
	end

	cmd = add_opt(cmd, 'A', d, [:A :straight_lines])
	cmd = add_opt(cmd, 'D', d, [:D :offset])
	cmd = add_opt(cmd, 'E', d, [:E :error_bars])
	cmd = add_opt(cmd, 'F', d, [:F :conn :connection])

	cmd = add_opt(cmd, 'G', d, [:G :fill])
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

	cmd = add_opt(cmd, 'I', d, [:I :intens])
	cmd = add_opt(cmd, 'L', d, [:L :closed_polygon])
	cmd = add_opt(cmd, 'N', d, [:N :no_clip])

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

	if (haskey(d, :ps)) PS = true			# To know if returning PS to the REPL was requested
	else                PS = false
	end

	P = nothing
	for k = 1:length(cmd)
		Vd && println(@sprintf("\tpsxy %s", cmd[k]))
		if (N_args == 0)					# Simple case
			if (PS) P = gmt("psxy " * cmd[k])
			else        gmt("psxy " * cmd[k])
			end
		elseif (N_args == 1)				# One numeric input
			if (PS) P = gmt("psxy " * cmd[k], arg1)
			else        gmt("psxy " * cmd[k], arg1)
			end
		else								# Two numeric inputs (data + CPT)
			if (PS) P = gmt("psxy " * cmd[k], arg1, arg2)
			else        gmt("psxy " * cmd[k], arg1, arg2)
			end
		end
	end
	if (haskey(d, :show)) 					# Display Fig in default viewer
		showfig(output, fname_ext, opt_T, K)
	elseif (haskey(d, :savefig))
		showfig(output, fname_ext, opt_T, K, d[:savefig])
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

# ---------------------------------------------------------------------------------------------------
psxy!(cmd0::String="", arg1=[], arg2::GMTcpt=[]; V=false, caller=[], data=[], portrait=true, fmt="",
      K=false, O=false,  first=false, kwargs...) =
	psxy(cmd0, arg1, arg2; V=V, caller=caller, data=data, portrait=portrait, fmt=fmt,
	     K=true, O=true,  first=first, kwargs...)
