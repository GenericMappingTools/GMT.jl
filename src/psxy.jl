"""
    xy(cmd0::String="", arg1=[]; kwargs...)

reads (x,y) pairs and plot lines, polygons, or symbols at those locations on a map.

Full option list at [`psxy`](http://gmt.soest.hawaii.edu/doc/latest/plot.html)

Parameters
----------

- **A** : **straight_lines** : -- Str --  

    By default, geographic line segments are drawn as great circle arcs. To draw them as straight
    lines, use the -A flag.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#a)
- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **D** : **shift** : **offset** : -- Str --

    Offset the plot symbol or line locations by the given amounts dx/dy.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#d)
- **E** : **error** : **error_bars** : -- Str --

    Draw symmetrical error bars.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#e)
- **F** : **conn** : **connection** : -- Str --

    Alter the way points are connected
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#f)
- **G** : **fill** : **markerfacecolor** : -- Str --

    Select color or pattern for filling of symbols or polygons. BUT WARN: the alias 'fill' will set the
    color of polygons OR symbols but not the two together. If your plot has polygons and symbols, use
    'fill' for the polygons and 'markerfacecolor' for filling the symbols. Same applyies for W bellow
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#g)
- **I** : **intens** : -- Str or number --

    Use the supplied intens value (in the [-1 1] range) to modulate the fill color by simulating
    shading illumination.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#i)
- **L** : **polygon** : -- Str --

    Force closed polygons. 
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#l)
- **N** : **no_clip** : -- Str or [] --

    Do NOT clip symbols that fall outside map border 
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#n)
- $(GMT.opt_P)
- **S** : **symbol** : -- Str --

    Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines). 
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#s)

    Alternatively select a sub-set of symbols using the aliases: **marker** or **shape**and values:

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

    and select their sizes with the **markersize** or **size** keyword [default is 7p].
    The marker size can be a scalar or a vector with same size numeber of rows of data. Units are
    points unless specified otherwise with (for example for cm) *par=(PROJ_LENGTH_UNIT="c")*
- **W** : **pen** : **line_attrib** : **markeredgecolor** : -- Str --

    Set pen attributes for lines or the outline of symbols
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#w)
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
function psxy(cmd0::String="", arg1=[]; caller="", K=false, O=false, first=true, kwargs...)
	if (isempty(cmd0) && isa(arg1, AbstractArray) && length(arg1) != 2 &&
		(size(arg1,2) == 1 || size(arg1,1) == 1))	# y only
		arg1 = hcat(1:length(arg1), arg1[:])
	end
	common_plot_xyz(cmd0, arg1, caller, K, O, first, false, kwargs...)
end

# ---------------------------------------------------------------------------------------------------
function psxyz(cmd0::String="", arg1=[]; caller="", K=false, O=false, first=true, kwargs...)
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

	if (isa(arg1, Array{GMT.GMTdataset,1}))		# Shitty consequence of arg1 being the output of a prev cmd
		arg1 = arg1[1]
	end

	cmd = ""
	sub_module = ""						# Will change to "scatter", etc... if called by sub-modules
	if (!isempty(caller))
		if (occursin(" -", caller))		# some sub-modues use this piggy-backed call
			if ((ind = findfirst("|", caller)) !== nothing)	# A mixed case with "caler|partiall_command"
				sub_module = caller[1:ind[1]-1]
				cmd = caller[ind[1]+1:end]
				caller = sub_module		# Because of parse_BJR()
			else
				cmd = caller
				caller = "others"		# It was piggy-backed
			end
		else
			sub_module = caller
			caller = ""					# Because of parse_BJR()
		end
	end

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	if (!occursin("-J", cmd))			# bar, bar3 and others may send in a -J
		opt_J = " -JX" * def_fig_size
		if ((val = find_in_dict(d, [:axis :aspect])[1]) !== nothing)
			if (val == "equal" || val == :equal)	# Need also a 'tight' option?
				if ((ind = findfirst("/", opt_J)) !== nothing)	# Already had something in height
					opt_J = opt_J[1:ind[1]-1] * "/0"
				else
					opt_J = " -JX12c/0"
				end
			end
		end
	else
		opt_J = ""
	end

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd, caller, O, opt_J)
	if (is3D)	cmd,opt_JZ = parse_JZ(cmd, d)	end
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_di = parse_di(cmd, d)
	cmd, opt_i  = parse_i(cmd, d)
	#=
	cmd  = parse_UVXY(cmd, d)
	cmd, = parse_a(cmd, d)
	cmd, = parse_e(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_g(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, = parse_p(cmd, d)
	cmd, = parse_t(cmd, d)
	cmd, = parse_swap_xy(cmd, d)
	cmd  = parse_params(cmd, d)
	=#
	cmd = parse_common_opts(d, cmd, [:a :e :f :g :h :p :t :xy :UVXY :params])

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	# If a file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, opt_i = read_data(d, cmd0, cmd, arg1, opt_R, opt_i, opt_bi, opt_di, is3D)
	
	if (is3D && isempty(opt_JZ) && length(collect(eachmatch(r"/", opt_R))) == 5)
		cmd = cmd * " -JZ6c"	# Default -JZ
	end

	cmd = add_opt(cmd, 'A', d, [:A :straight_lines])
	cmd = add_opt(cmd, 'D', d, [:D :shift :offset])				# 'offset' may be needed in vec attribs
	cmd = add_opt(cmd, 'F', d, [:F :conn :connection])

	if ((val = find_in_dict(d, [:E :error :error_bars])[1]) !== nothing)	# Crazzy shit to allow increasing the arg1 matrix
		n_rows, n_cols = size(arg1)
		arg1 = reshape(arg1, :)
		cmd = add_opt(cmd, 'E', d, [:E :error :error_bars],
					  (x="|x",y="|y",xy="|xy",X="|X",Y="|Y",asym="+a",cline="+cl",csymbol="+cf",
					   wiskers="|+n",cap="+w",pen="+p"), false, arg1)
		arg1 = reshape(arg1, n_rows, :)
	end

	# Look for color request. Do it after error bars because they may add a column
	len = length(cmd);	n_prev = N_args;
	cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1, arg2)

	# See if we got a CPT. If yes there may be some work to do if no color column provided in input data.
	cmd, arg1, arg2, N_args = make_color_column(d, cmd, opt_i, len, N_args, n_prev, is3D, arg1, arg2)

	cmd = add_opt(cmd, 'G', d, [:G :fill])
	opt_Gsymb = add_opt("", 'G', d, [:G :markerfacecolor :mc])	# Filling color for symbols

	opt_Wmarker = ""
	if (haskey(d, :markeredgecolor))
		opt_Wmarker = "0.5p," * arg2str(d[:markeredgecolor])	# 0.25p is so thin
	end

	cmd = add_opt(cmd, 'I', d, [:I :intens])
	cmd = add_opt(cmd, 'L', d, [:L :polygon])
	cmd = add_opt(cmd, 'N', d, [:N :no_clip])

	opt_W = add_opt_pen(d, [:W :pen :line_attrib], "W")
	if (occursin("+c", opt_W) && !occursin("-C", cmd))
		@warn("Color lines (or fill) from a color scale was selected but no color scale provided. Expect ...")
	end

	opt_S = add_opt("", 'S', d, [:S :symbol], (symb="1", size="", unit="1"))
	if (opt_S == "")			# OK, no symbol given via the -S option. So fish in aliases
		marca = get_marker_name(d, [:marker :shape], is3D)
		if ((val = find_in_dict(d, [:markersize :ms :size])[1]) !== nothing)
			if (marca == "")  marca = "c"  end		# If a marker name was not selected, defaults to circle
			#ms = ""
			if (isa(val, AbstractArray))
				if (length(val) == size(arg1,1))
					arg1 = hcat(arg1, val[:])
					#ms = " "		# Just to defeat the empty test below
				else
					error("The size array must have the same number of elements rows in the data")
				end
			else
				marca = marca * arg2str(val);	#ms = " "
			end
			#if (ms == "")  marca = marca * "7p"		end		# Default to 7p
			opt_S = " -S" * marca
		elseif (marca != "")			# User only selected a marker name but no size.
			opt_S = " -S" * marca * "7p"
		end
	end

	if (opt_S != "")
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
		if (opt_W != "" && opt_ML != "")
			@warn("You cannot use both markeredgecolor and W or line_attrib keys.")
		end
	end

	# See if any of the scatter, bar, lines, etc... was the caller and if yes, set sensible defaults.
	cmd = check_caller(d, cmd, opt_S, sub_module, O)

	if (opt_W != "" && opt_S == "") 						# We have a line/polygon request
		cmd = [finish_PS(d, cmd * opt_W, output, K, O)]

	elseif (opt_W == "" && opt_S != "")						# We have a symbol request
		if (opt_Wmarker != "" && opt_W == "")
			opt_Gsymb = opt_Gsymb * " -W" * opt_Wmarker		# Piggy back in this option string
		end
		if (opt_ML != "")  cmd = cmd * opt_ML  end			# If we have a symbol outline pen
		cmd = [finish_PS(d, cmd * opt_S * opt_Gsymb, output, K, O)]

	elseif (opt_W != "" && opt_S != "")						# We have both line/polygon and a symbol
		if (occursin(opt_Gsymb, cmd))  opt_Gsymb = ""  end
		if (opt_S[4] == 'v' || opt_S[4] == 'V' || opt_S[4] == '=')
			cmd = [finish_PS(d, cmd * opt_W * opt_S * opt_Gsymb, output, K, O)]
		else
			if (opt_Wmarker != "")
				opt_Wmarker = " -W" * opt_Wmarker			# Set Symbol edge color 
			end
			cmd1 = cmd * opt_W
			cmd2 = replace(cmd, opt_B => "") * opt_S * opt_Gsymb * opt_Wmarker	# Don't repeat option -B
			if (opt_ML != "")  cmd1 = cmd1 * opt_ML  end	# If we have a symbol outline pen
			cmd = [finish_PS(d, cmd1, output, true, O)
			       finish_PS(d, cmd2, output, K, true)]
		end

	elseif (opt_S != "" && opt_ML != "")					# We have a symbol outline pen
		cmd = [finish_PS(d, cmd * opt_ML * opt_S * opt_Gsymb, output, K, O)]

	else
		cmd = [finish_PS(d, cmd, output, K, O)]
	end

    return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, gmt_proggy, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
function make_color_column(d, cmd, opt_i, len, N_args, n_prev, is3D, arg1, arg2)
	# See if we got a CPT. If yes there is quite some work to do if no color column provided in input data.

	if (isempty_(arg1))  return cmd, arg1, arg2, N_args  end		# Just play safe

	mz, the_kw = find_in_dict(d, [:zcolor :markerz :mz])
	if (!(N_args > n_prev || len < length(cmd)) && mz === nothing)	# No color request, so return right away
		return cmd, arg1, arg2, N_args
	end

	if (isa(arg1, Array))  n_rows, n_col = size(arg1)
	else                   n_rows, n_col = size(arg1.data)			# Must be a GMTdataset
	end

	warn1 = string("Probably color column in ", the_kw, " has incorrect dims. Ignoring it.")
	warn2 = "Plotting with color table requires adding one more column to the dataset but your -i
	option didn't do it, so you won't get waht you expect. Try -i0-1,1 for 2D or -i0-2,2 for 3D plots"

	if (n_col <= 2+is3D)
		if (mz !== nothing)
			if (length(mz) != n_rows)  @warn(warn1); @goto noway  end
			if (isa(arg1, Array))  arg1 = hcat(arg1, mz[:])
			else                   arg1.data = hcat(arg1.data, mz[:])
			end
		else
			if (opt_i == "")  cmd = @sprintf("%s -i0-%d,%d", cmd, 1+is3D, 1+is3D)
			else              @warn(warn2);		@goto noway
			end
		end
	elseif (n_col > 2+is3D)
		if (mz !== nothing)			# Here we must insert the color col right after the coords
			if (length(mz) != n_rows)  @warn(warn1); @goto noway  end
			if (isa(arg1, Array))  arg1 = hcat(arg1[:,1:2+is3D], mz[:], arg1[:,3+is3D:end])
			else                   arg1.data = hcat(arg1.data[:,1:2+is3D], mz[:], arg1.data[:,3+is3D:end])
			end
		else
			if (opt_i == "")  cmd = @sprintf("%s -i0-%d,%d,%d-%d", cmd, 1+is3D, 1+is3D, 2+is3D, n_col-1)
			else              @warn(warn2);		@goto noway 
			end
		end
	end

	if (N_args == n_prev)		# No cpt transmitted, so need to compute one
		if (GMTver >= 7)		# 7 because this solution is currently still bugged
			#=
			if (mz !== nothing)
				arg2 = gmt("makecpt -E " * cmd[len+2:end], mz[:])
			else
				if (isa(arg1, Array))  arg2 = gmt("makecpt -E " * cmd[len+2:end], arg1)
				else                   arg2 = gmt("makecpt -E " * cmd[len+2:end], arg1.data)
				end
			end
			=#
		else
			if (mz !== nothing)
				mi, ma = extrema(mz)
			else
				if (isa(arg1, Array))  mi, ma = extrema(view(arg1, :, 2+is3D))
				else                   mi, ma = extrema(view(arg1.data, :, 2+is3D))
				end
			end
			just_C = cmd[len+2:end];	reset_i = ""
			if ((ind = findfirst(" -i", just_C)) !== nothing)
				reset_i = just_C[ind[1]:end] 
				just_C  = just_C[1:ind[1]-1]
			end
			arg2 = gmt(string("makecpt -T", mi-0.001*abs(mi), '/', ma+0.001*abs(ma), " ", just_C))
			if (occursin(" -C", cmd))  cmd = cmd[1:len+3]  end		# Strip the cpt name
			if (reset_i != "")  cmd = cmd * reset_i  end	# Reset -i, in case it existed
		end
		if (!occursin(" -C", cmd))  cmd = cmd * " -C"  end	# Need to inform that there is a cpt to use
		N_args = 2
	end

	@label noway

	return cmd, arg1, arg2, N_args
end

# ---------------------------------------------------------------------------------------------------
function get_marker_name(d::Dict, symbs, is3D=false, del=false)
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
			if (del)  delete!(d, symb)  end
			break
		end
	end
	return marca
end

# ---------------------------------------------------------------------------------------------------
function check_caller(d::Dict, cmd::String, opt_S::String, caller::String, O::Bool)
	# Set sensible defaults for the sub-modules "scatter" & "bar"
	if (caller == "scatter")
		if (opt_S == "")  cmd = cmd * " -Sc7p"  end
	elseif (caller == "scatter3")
		if (opt_S == "")  cmd = cmd * " -Su7p"  end
	elseif (caller == "bar")
		if (opt_S == "")
			if (haskey(d, :bar))
				cmd = GMT.parse_bar_cmd(d, :bar, cmd, "Sb")
			elseif (haskey(d, :hbar))
				cmd = GMT.parse_bar_cmd(d, :hbar, cmd, "SB")
			else
				opt = add_opt("", "",  d, [:width])		# No need to purge because width is not a psxy option
				if (opt == "")	opt = "0.8"	end			# The default
				cmd = cmd * " -Sb" * opt * "u"

				optB = add_opt("", "",  d, [:base])
				if (optB == "")	optB = "0"	end
				cmd = cmd * "+b" * optB
			end
		end
		if (!occursin(" -G", cmd) && !occursin(" -C", cmd))  cmd = cmd * " -G0/115/190"	end		# Default color
	elseif (caller == "bar3")
		if (haskey(d, :noshade) && occursin("-So", cmd))
			cmd = replace(cmd, "-So" => "-SO", count=1)
		end
		if (!occursin(" -G", cmd) && !occursin(" -C", cmd))  cmd = cmd * " -G0/115/190"	end	
		if (!occursin(" -J", cmd))  cmd = cmd * " -JX12c/0"  end
	end

	if (occursin('3', caller))
		if (!occursin(" -B", cmd) && !O)  cmd = cmd * def_fig_axes3  end	# For overlays default is no axes
		if (!occursin(" -p", cmd))  cmd = cmd * " -p200/30"  end
	else
		if (!occursin(" -B", cmd) && !O)  cmd = cmd * def_fig_axes   end
	end

	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_bar_cmd(d::Dict, key::Symbol, cmd::String, optS::String)
	# Deal with parsing the 'bar' & 'hbar' keywors of psxy. Also called by plot/bar3. For this
	# later module is input is not a string or NamedTuple the scatter options must be processed in bar3().
	# KEY is either :bar or :hbar
	# OPT is either "Sb", "SB" or "So"
	opt =""
	if (haskey(d, key))
		if (isa(d[key], String))
			cmd = cmd * " -" * optS * d[key]
		elseif (isa(d[key], NamedTuple))
			opt = add_opt("", optS, d, [key], (width="",unit="1",base="+b",height="+B",nbands="+z",Nbands="+Z"))
		else
			error("Argument of the *bar* keyword can be only a string or a NamedTuple.")
		end
	end

	if (opt != "")				# Still need to finish parsing this
		if ((ind = findfirst("+", opt)) !== nothing)	# See if need to insert a 'u'
			if (!isletter(opt[ind[1]-1]))  opt = opt[1:ind[1]-1] * 'u' * opt[ind[1]:end]  end
		else
			pb = ""
			if (optS != "So")  pb = "+b0"  end	# The default for bar3 (So) is set in the bar3() fun
			if (!isletter(opt[end]))  opt = opt * 'u' * pb	# No base set so default to ...
			else                      opt = opt * pb
			end
		end
		cmd = cmd * opt
	end
	return cmd
end
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
psxy(arg1; caller=[], K=false, O=false, first=true, kw...) =
	psxy("", arg1; caller=caller, K=K, O=O, first=first, kw...)
psxy!(arg1; caller=[], K=true, O=true, first=false, kw...) =
	psxy("", arg1; caller=caller, K=K, O=O, first=first, kw...)

psxy!(cmd0::String="", arg1=[]; caller=[], K=true, O=true, first=false, kw...) =
	psxy(cmd0, arg1; caller=caller, K=K, O=O, first=first, kw...)
psxy!(arg1=[]; caller=[], K=true, O=true, first=false, kw...) =
	psxy("", arg1; caller=caller, K=K, O=O, first=first, kw...)

# ---------------------------------------------------------------------------------------------------
psxyz!(cmd0::String="", arg1=[]; caller=[], K=true, O=true,  first=false, kw...) =
	psxyz(cmd0, arg1; caller=caller, K=K, O=O,  first=first, kw...)
psxyz!(arg1=[]; caller=[], K=true, O=true, first=false, kw...) =
	psxyz("", arg1; caller=caller, K=K, O=O, first=first, kw...)
