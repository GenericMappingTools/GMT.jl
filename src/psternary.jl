"""
	ternary(cmd0::String="", arg1=[]; kwargs...)

reads (x,y) pairs and generates PostScript code that will plot lines,
polygons, or symbols at those locations on a map.

Full option list at [`ternary`](http://gmt.soest.hawaii.edu/doc/latest/ternary.html)

Parameters
----------

- **A** : **straight_lines** : -- Str --  

    By default, geographic line segments are drawn as great circle arcs. To draw them as straight
    lines, use the -A flag.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/ternary.html#a)
- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **G** : **fill** : **markerfacecolor** : **MarkerFaceColor** : -- Str --

    Select color or pattern for filling of symbols or polygons. BUT WARN: the alias 'fill' will set the
    color of polygons OR symbols but not the two together. If your plot has polygons and symbols, use
    'fill' for the polygons and 'markerfacecolor' for filling the symbols. Same applyies for W bellow
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/ternary.html#g)
- **L** : **labels** : -- Str --            Flags = a/b/c

    Set the labels for the three diagram vertices [none]. 
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/ternary.html#l)
- **M** : **no_plot** : -- Bool or [] --

    Do no plotting. Instead, convert the input (a,b,c[,*z*]) records to Cartesian (x,y,[,*z*]) records,
    where x, y are normalized coordinates on the triangle (i.e., 0-1 in xand 0-sqrt(3)/2 in y).
    [`-M`](http://gmt.soest.hawaii.edu/doc/latest/ternary.html#m)
- **N** : **no_clip** : -- Bool or [] --

    Do NOT clip symbols that fall outside map border 
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/ternary.html#n)
- $(GMT.opt_P)
- **S** : **symbol** : **marker** : **shape** : -- Str --

    Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines). 
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/ternary.html#s)
    Alternatively select a sub-set of symbols using the aliases: **symbol**, **marker** or **shape**and values:

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
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/ternary.html#w)
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
function ternary(cmd0::String="", arg1=[]; caller=[], K=false, O=false, first=true, kwargs...)

	arg2 = []		# May be needed if GMTcpt type is sent in via C
	N_args = isempty_(arg1) ? 0 : 1

	((isempty(cmd0) && isempty_(arg1) || occursin(" -", cmd0)) && return monolitic("ternary", cmd0, arg1))	# Monolitic mode

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	opt_J = " -JX12c/10.4c"                     # Equilateral triangle
	for sym in [:axis :aspect]
		if (haskey(d, sym))
			if (d[sym] == "equal")				# Need also a 'tight' option
				opt_J = " -JX12c"
			end
			break
		end
	end
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", caller, O, opt_J)
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_di = parse_di(cmd, d)
	cmd, opt_i = parse_i(cmd, d)
	cmd = parse_common_opts(d, cmd, [:a :e :f :g :h :p :t :xy :UVXY :params])

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, = read_data(d, cmd0, cmd, arg1, opt_R, opt_i, opt_bi, opt_di, false)

	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1, arg2)

	cmd = add_opt(cmd, 'L', d, [:L :straight_lines])
	cmd = add_opt(cmd, 'M', d, [:M :offset])
	cmd = add_opt(cmd, 'N', d, [:N :error_bars])

	cmd = add_opt(cmd, 'G', d, [:G :fill])
	opt_Gsymb = add_opt("", 'G', d, [:G :markerfacecolor :mc])	# Filling color for symbols

	opt_Wmarker = ""
	if (haskey(d, :markeredgecolor))
		opt_Wmarker = "0.5p," * arg2str(d[:markeredgecolor])	# 0.25p is so thin
	end

	cmd = add_opt(cmd, 'L', d, [:L :labels])
	cmd = add_opt(cmd, 'M', d, [:M :no_plot])
	cmd = add_opt(cmd, 'N', d, [:N :no_clip])

	opt_W = ""
	pen = build_pen(d)					# Either a full pen string or empty ("")
	if (pen != "")
		opt_W = " -W" * pen
	else
		if ((val = find_in_dict(d, [:W :line_attrib])[1]) !== nothing)
			if (isa(val, Tuple))		# Like this it can hold the pen, not extended atts
				opt_W = " -W" * parse_pen(val)
			else
				opt_W = " -W" * arg2str(val)
			end
		end
	end

	opt_S = add_opt("", 'S', d, [:S :symbol], (symb="1", size="", unit="1"))
	if (opt_S == "")			# OK, no symbol given via the -S option. So fish in aliases
		marca = get_marker_name(d, [:marker :shape], false)
		if (marca != "")
			done = false
			if ((val = find_in_dict(d, [:markersize :ms :size])[1]) !== nothing)
				marca = marca * arg2str(val)
				done = true
			end
			if (!done)  marca = marca * "8p"  end			# Default to 8p
		end
		if (marca != "")  opt_S = " -S" * marca  end
	end

	if (opt_S != "")			# 
		opt_ML = ""
		if (haskey(d, :markerline))
			if (isa(:markerline, Tuple))	# Like this it can hold the pen, not extended atts
				opt_ML = " -W" * parse_pen(:markerline)
			else
				opt_ML = " -W" * arg2str(:markerline)
			end
			if (!isempty(opt_Wmarker))
				opt_Wmarker = ""
				@warn("markerline overrides markeredgecolor")
			end
		end
		if (opt_W != "" && !isempty(opt_ML))
			@warn("You cannot use both markeredgecolor and W or line_attrib keys.")
		end
	end

	if (opt_W != "" && opt_S == "") 			# We have a line/polygon request
		cmd = [finish_PS(d, cmd * opt_W, output, K, O)]
	elseif (opt_W == "" && opt_S != "")			# We have a symbol request
		if (opt_Wmarker != "" && opt_W == "")
			opt_Gsymb = opt_Gsymb * " -W" * opt_Wmarker	# Piggy back in this option string
		end
		if (opt_ML != "")  cmd = cmd * opt_ML  end		# If we have a symbol outline pen
		cmd = [finish_PS(d, cmd * opt_S * opt_Gsymb, output, K, O)]
	elseif (opt_W != "" && opt_S != "")		# We have both line/polygon and a symbol
		# that is not a vector (because Vector width is set by -W)
		if (opt_S[4] == 'v' || opt_S[4] == 'V' || opt_S[4] == '=')
			cmd = [finish_PS(d, cmd * opt_W * opt_S * opt_Gsymb, output, K, O)]
		else
			if (opt_Wmarker != "")
				opt_Wmarker = " -W" * opt_Wmarker	# Set Symbol edge color 
			end
			cmd1 = cmd * opt_W
			cmd2 = replace(cmd, opt_B => "") * opt_S * opt_Gsymb * opt_Wmarker	# Don't repeat option -B
			if (opt_ML != "")  cmd1 = cmd1 * opt_ML  end		# If we have a symbol outline pen
			cmd = [finish_PS(d, cmd1, output, true, O)
			       finish_PS(d, cmd2, output, K, true)]
		end
	elseif (opt_S != "" && opt_ML != "")		# We have a symbol outline pen
		cmd = [finish_PS(d, cmd * opt_ML * opt_S * opt_Gsymb, output, K, O)]
	else
		cmd = [finish_PS(d, cmd, output, K, O)]
	end

	return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, "psternary", arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
ternary(arg1; caller=[], K=false, O=false, first=true, kw...) =
	ternary("", arg1; caller=caller, K=K, O=O,  first=first, kw...)

ternary!(cmd0::String="", arg1=[]; caller=[], K=true, O=true,  first=false, kw...) =
	ternary(cmd0, arg1; caller=caller, K=K, O=O,  first=first, kw...)
ternary!(arg1=[]; caller=[], K=true, O=true,  first=false, kw...) =
	ternary("", arg1; caller=caller, K=K, O=O,  first=first, kw...)

const psternary  = ternary            # Aliases
const psternary! = ternary!           # Aliases