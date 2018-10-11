"""
	xy(cmd0::String="", arg1=[]; kwargs...)

reads (x,y) pairs and generates PostScript code that will plot lines,
polygons, or symbols at those locations on a map.

Full option list at [`psxy`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html)

Parameters
----------

- **A** : **straight_lines** : -- Str --  

    By default, geographic line segments are drawn as great circle arcs. To draw them as straight
    lines, use the -A flag.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#a)
- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **D** : **offset** : -- Str --

    Offset the plot symbol or line locations by the given amounts dx/dy.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#d)
- **E** : **error_bars** : -- Str --

    Draw symmetrical error bars.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#e)
- **F** : **conn** : **connection** : -- Str --

    Alter the way points are connected
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#f)
- **G** : **fill** : **markerfacecolor** : **MarkerFaceColor** : -- Str --

    Select color or pattern for filling of symbols or polygons. BUT WARN: the alias 'fill' will set the
    color of polygons OR symbols but not the two together. If your plot has polygons and symbols, use
    'fill' for the polygons and 'markerfacecolor' for filling the symbols. Same applyies for W bellow
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#g)
- **I** : **intens** : -- Str or number --

	Use the supplied intens value (in the [-1 1] range) to modulate the fill color by simulating
	shading illumination.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#i)
- **L** : **closed_polygon** : -- Str --

    Force closed polygons. 
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#l)
- **N** : **no_clip** : -- Str or [] --

    Do NOT clip symbols that fall outside map border 
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#n)
- $(GMT.opt_P)
- **S** : **symbol** : **marker** : **Marker** : -- Str --

    Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines). 
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#s)
    Alternatively select a sub-set of symbols using the aliases: **marker** or **Marker** and values:

    + **-**, **x_dash**
    + **+**, **plus**
    + **a**, *, **star**
    + **c**, **circle**
    + **d**, **diamond**
    + **g**, **octagon**
    + **h**, **hexagon**
    + **i**, **v**, **inverted_tri**
    + **n**, **pentagon**
    + **p**, **.**, **point**
    + **r**, **rectangle**
    + **s**, **square**
    + **t**, **^**, **triangle**
    + **x**, **cross**
    + **y**, **y_dash**
- **W** : **line_attrib** : **markeredgecolor** : **MarkerEdgeColor** : -- Str --

    Set pen attributes for lines or the outline of symbols
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#w)
    WARNING: the pen attributes will set the pen of polygons OR symbols but not the two together.
    If your plot has polygons and symbols, use **W** or **line_attribs** for the polygons and
    **markeredgecolor** or **MarkerEdgeColor** for filling the symbols. Similar to S above.
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- **axis** : **aspect** : -- Str --
    When equal to "equal" makes a square plot.
- $(GMT.opt_a)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_p)
- $(GMT.opt_t)
- $(GMT.opt_swap_xy)
"""
function xy(cmd0::String="", arg1=[]; caller=[], K=false, O=false, first=true, kwargs...)
	common_plot_xyz(cmd0, arg1, caller, K, O, first, false, kwargs...)
end

# ---------------------------------------------------------------------------------------------------
function xyz(cmd0::String="", arg1=[]; caller=[], K=false, O=false, first=true, kwargs...)
	common_plot_xyz(cmd0, arg1, caller, K, O, first, true, kwargs...)
end

# ---------------------------------------------------------------------------------------------------
function common_plot_xyz(cmd0, arg1, caller, K, O, first, is3D, kwargs...)
	arg2 = []		# May be needed if GMTcpt type is sent in via C
	N_args = isempty_(arg1) ? 0 : 1

	if (is3D)
		gmt_proggy = "psxyz"
	else
		gmt_proggy = "psxy"
	end

	((isempty(cmd0) && isempty_(arg1)) || occursin(" -", cmd0)) && return monolitic(gmt_proggy, cmd0, arg1)

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	opt_J = " -JX12c/8c"
	for sym in [:axis :aspect]
		if (haskey(d, sym))
			if (d[sym] == "equal")				# Need also a 'tight' option
				opt_J = " -JX12c"
			end
			break
		end
	end
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", caller, O, opt_J)
	if (is3D)	cmd = parse_JZ(cmd, d)	end
	cmd = parse_UVXY(cmd, d)
	cmd, = parse_a(cmd, d)
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_di = parse_di(cmd, d)
	cmd, = parse_e(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_g(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, opt_i = parse_i(cmd, d)
	cmd, = parse_p(cmd, d)
	cmd, = parse_t(cmd, d)
	cmd, = parse_swap_xy(cmd, d)
	cmd = parse_params(cmd, d)

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, opt_i = read_data(d, cmd0, cmd, arg1, opt_R, opt_i, opt_bi, opt_di, is3D)

	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1, arg2)

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
				if (isa(d[sym], Tuple))		# Like this it can hold the pen, not extended atts
					opt_W = " -W" * parse_pen(d[sym])
				else
					opt_W = " -W" * arg2str(d[sym])
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
				t = d[sym]
				if (isa(t, Symbol))	t = string(t)	end
				if (t == "-"     || t == "x-dash")   marca = "-"
				elseif (t == "+" || t == "plus")     marca = "+"
				elseif (t == "a" || t == "*" || t == "star")     marca = "a"
				elseif (t == "c" || t == "circle")   marca = "c"
				elseif (t == "d" || t == "diamond")  marca = "d"
				elseif (t == "g" || t == "octagon")  marca = "g"
				elseif (t == "h" || t == "hexagon")  marca = "h"
				elseif (t == "i" || t == "v" || t == "inverted_tri")  marca = "i"
				elseif (t == "n" || t == "pentagon")  marca = "n"
				elseif (t == "p" || t == "." || t == "point")     marca = "p"
				elseif (t == "r" || t == "rectangle") marca = "r"
				elseif (t == "s" || t == "square")    marca = "s"
				elseif (t == "t" || t == "^" || t == "triangle")  marca = "t"
				elseif (t == "x" || t == "cross")     marca = "x"
				elseif (is3D && (t == "u" || t == "cube"))  marca = "u"
				elseif (t == "y" || t == "y-dash")    marca = "y"
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

	if (!isempty(opt_S))			# 
		opt_ML = ""
		for sym in [:markerline :MarkerLine]
			if (haskey(d, sym))
				if (isa(d[sym], Tuple))	# Like this it can hold the pen, not extended atts
					opt_ML = " -W" * parse_pen(d[sym])
				else
					opt_ML = " -W" * arg2str(d[sym])
				end
				if (!isempty(opt_Wmarker))
					opt_Wmarker = ""
					@warn("markerline overrides markeredgecolor")
				end
				break
			end
		end
		if (!isempty(opt_W) && !isempty(opt_ML))
			@warn("You cannot use both markeredgecolor and W or line_attrib keys.")
		end
	end

	if (!isempty(opt_W) && isempty(opt_S)) 			# We have a line/polygon request
		cmd = [finish_PS(d, cmd * opt_W, output, K, O)]
	elseif (isempty(opt_W) && !isempty(opt_S))		# We have a symbol request
		if (!isempty(opt_Wmarker) && isempty(opt_W))
			opt_Gsymb = opt_Gsymb * " -W" * opt_Wmarker	# Piggy back in this option string
		end
		if (!isempty(opt_ML))						# If we have a symbol outline pen
			cmd = cmd * opt_ML
		end
		cmd = [finish_PS(d, cmd * opt_S * opt_Gsymb, output, K, O)]
	elseif (!isempty(opt_W) && !isempty(opt_S))		# We have both line/polygon and a symbol
		# that is not a vector (because Vector width is set by -W)
		if (opt_S[4] == 'v' || opt_S[4] == 'V' || opt_S[4] == '=')
			cmd = [finish_PS(d, cmd * opt_W * opt_S * opt_Gsymb, output, K, O)]
		else
			if (!isempty(opt_Wmarker))
				opt_Wmarker = " -W" * opt_Wmarker	# Set Symbol edge color 
			end
			cmd1 = cmd * opt_W
			cmd2 = replace(cmd, opt_B => "") * opt_S * opt_Gsymb * opt_Wmarker	# Don't repeat option -B
			if (!isempty(opt_ML))					# If we have a symbol outline pen
				cmd1 = cmd1 * opt_ML
			end
			cmd = [finish_PS(d, cmd1, output, true, O)
			       finish_PS(d, cmd2, output, K, true)]
		end
	elseif (!isempty(opt_S) && !isempty(opt_ML))		# We have a symbol outline pen
		cmd = [finish_PS(d, cmd * opt_ML * opt_S * opt_Gsymb, output, K, O)]
	else
		cmd = [finish_PS(d, cmd, output, K, O)]
	end

    return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, gmt_proggy, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
xy!(cmd0::String="", arg1=[]; caller=[], K=true, O=true,  first=false, kw...) =
	xy(cmd0, arg1; caller=caller, K=K, O=O,  first=first, kw...)
xy!(arg1=[]; caller=[], K=true, O=true,  first=false, kw...) =
	xy("", arg1; caller=caller, K=K, O=O,  first=first, kw...)

# ---------------------------------------------------------------------------------------------------
xyz!(cmd0::String="", arg1=[]; caller=[], K=true, O=true,  first=false, kw...) =
	xyz(cmd0, arg1; caller=caller, K=K, O=O,  first=first, kw...)
xyz!(arg1=[]; caller=[], K=true, O=true,  first=false, kw...) =
	xyz("", arg1; caller=caller, K=K, O=O,  first=first, kw...)

psxy   = xy				# Alias
psxy!  = xy!			# Alias
psxyz  = xyz			# Alias
psxyz! = xyz!			# Alias