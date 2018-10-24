"""
	xy(cmd0::String="", arg1=[]; kwargs...)

reads (x,y) pairs and plot lines, polygons, or symbols at those locations on a map.

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
- **G** : **fill** : **markerfacecolor** : -- Str --

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
- **S** : -- Str --

    Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines). 
	[`-S`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#s)

    Alternatively select a sub-set of symbols using the aliases: **symbol** or **marker** and values:

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
	
	and select their sizes with the **markersize** or **size** keyword [default is 8p].
	The marker size can be a scalar or a vector with same size numeber of rows of data. Units are
	points unless specified otherwise with (for example for cm) *par=(PROJ_LENGTH_UNIT="c")*
- **W** : **pen** : **line_attrib** : **markeredgecolor** : -- Str --

    Set pen attributes for lines or the outline of symbols
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#w)
    WARNING: the pen attributes will set the pen of polygons OR symbols but not the two together.
    If your plot has polygons and symbols, use **W** or **line_attribs** for the polygons and
    **markeredgecolor** for filling the symbols. Similar to S above.
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
	if (isempty(cmd0) && isa(arg1, AbstractArray) && length(arg1) != 2 &&
		(size(arg1,2) == 1 || size(arg1,1) == 1))	# y only
		arg1 = hcat(1:length(arg1), arg1[:])
	end
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

	if (is3D)	gmt_proggy = "psxyz"
	else		gmt_proggy = "psxy"
	end

	((isempty(cmd0) && isempty_(arg1)) || occursin(" -", cmd0)) && return monolitic(gmt_proggy, cmd0, arg1)

	if (!isempty(caller) && occursin(" -", caller))
		cmd = caller
		caller = []					# It was piggy-backed by scatter or others
	else
		cmd = ""
	end

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	if (!occursin("-J", cmd))		# bar, bar3 and others may send in a -J
		opt_J = " -JX12c/8c"
		for symb in [:axis :aspect]
			if (haskey(d, symb))
				if (d[symb] == "equal" || d[symb] == :equal)	# Need also a 'tight' option?
					opt_J = " -JX12c"
				end
				break
			end
		end
	else
		opt_J = ""
	end

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd, caller, O, opt_J)
	if (is3D)	cmd,opt_JZ = parse_JZ(cmd, d)	end
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
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R, opt_i, opt_bi, opt_di, is3D)
	
	if (is3D && isempty(opt_JZ) && length(collect(eachmatch(r"/", opt_R))) == 5)
		cmd = cmd * " -JZ6c"	# Default -JZ
	end

	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1, arg2)

	cmd = add_opt(cmd, 'A', d, [:A :straight_lines])
	cmd = add_opt(cmd, 'D', d, [:D :offset])
	cmd = add_opt(cmd, 'E', d, [:E :error_bars])
	cmd = add_opt(cmd, 'F', d, [:F :conn :connection])

	cmd = add_opt(cmd, 'G', d, [:G :fill])
	opt_Gsymb = add_opt("", 'G', d, [:G :markerfacecolor])		# Filling color for symbols

	opt_Wmarker = ""
	if (haskey(d, :markeredgecolor))
		opt_Wmarker = "0.5p," * arg2str(d[:markeredgecolor])	# 0.25p is so thin
	end

	cmd = add_opt(cmd, 'I', d, [:I :intens])
	cmd = add_opt(cmd, 'L', d, [:L :closed_polygon])
	cmd = add_opt(cmd, 'N', d, [:N :no_clip])

	#=
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
	=#
	opt_W = add_opt_pen(d, [:W :pen :line_attrib], "W")

	opt_S = add_opt("", 'S', d, [:S :symbol])
	if (isempty(opt_S))			# OK, no symbol given via the -S option. So fish in aliases
		marca = get_marker_name(d, [:marker])
		if (!isempty(marca))
			ms = ""
			for symb in [:size :markersize]
				if (haskey(d, symb))
					if (isa(d[symb], AbstractArray))
						if (length(d[symb]) == size(arg1,1))
							arg1 = hcat(arg1, d[symb][:])
							ms = " "		# Just to defeat the empty test below
						else
							error("The size array must have the same number of elements rows in the data")
						end
					else
						marca = marca * arg2str(d[symb]);	ms = " "
					end
					break
				end
			end
			if (ms == "")  marca = marca * "8p"		end		# Default to 8p
		end
		if (!isempty(marca))  opt_S = " -S" * marca  end
	end

	if (!isempty(opt_S))
		opt_ML = ""
		if (haskey(d, :markerline))
			if (isa(d[:markerline], Tuple))			# Like this it can hold the pen, not extended atts
				opt_ML = " -W" * parse_pen(d[:markerline])
			else
				opt_ML = " -W" * arg2str(d[:markerline])
			end
			if (!isempty(opt_Wmarker))
				opt_Wmarker = ""
				@warn("markerline overrides markeredgecolor")
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
function get_marker_name(d::Dict, symbs, del=false)
	marca = ""
	for symb in symbs
		if (haskey(d, symb))
			t = d[symb]
			if (isa(t, Symbol))	t = string(t)	end
			if     (t == "-" || t == "x-dash")   marca = "-"
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
			if (del)
				delete!(d, symb)
			end
			break
		end
	end
	return marca
end

# ---------------------------------------------------------------------------------------------------
xy(arg1; caller=[], K=false, O=false, first=true, kw...) =
	xy("", arg1; caller=caller, K=K, O=O, first=first, kw...)
xy!(arg1; caller=[], K=true, O=true, first=false, kw...) =
	xy("", arg1; caller=caller, K=K, O=O, first=first, kw...)

xy!(cmd0::String="", arg1=[]; caller=[], K=true, O=true, first=false, kw...) =
	xy(cmd0, arg1; caller=caller, K=K, O=O, first=first, kw...)
xy!(arg1=[]; caller=[], K=true, O=true, first=false, kw...) =
	xy("", arg1; caller=caller, K=K, O=O, first=first, kw...)

# ---------------------------------------------------------------------------------------------------
xyz!(cmd0::String="", arg1=[]; caller=[], K=true, O=true,  first=false, kw...) =
	xyz(cmd0, arg1; caller=caller, K=K, O=O,  first=first, kw...)
xyz!(arg1=[]; caller=[], K=true, O=true, first=false, kw...) =
	xyz("", arg1; caller=caller, K=K, O=O, first=first, kw...)

# ---------------------------------------------------------------------------------------------------
psxy   = xy				# Alias
psxy!  = xy!			# Alias
psxyz  = xyz			# Alias
psxyz! = xyz!			# Alias