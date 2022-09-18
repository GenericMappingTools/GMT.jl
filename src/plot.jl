"""
    plot(arg1::Array; kwargs...)

reads (x,y) pairs from files [or standard input] and generates PostScript code that will plot lines,
polygons, or symbols at those locations on a map.

Full option list at [`psxy`]($(GMTdoc)plot.html)

Parameters
----------

- **A** | **steps** | **stairs** | **straight_lines** :: [Type => Str] 

	By default, geographic line segments are drawn as great circle arcs.
	To draw them as straight lines, use this option.
    ($(GMTdoc)plot.html#a)
- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **D** | **shift** | **offset** :: [Type => Str]

    Offset the plot symbol or line locations by the given amounts dx/dy in cm, inch or points.
    ($(GMTdoc)plot.html#d)
- **E** | **error** | **error_bars** :: [Type => Str]

    Draw symmetrical error bars.
    ($(GMTdoc)plot.html#e)
- **F** | **conn** | **connection** :: [Type => Str]

    Alter the way points are connected
    ($(GMTdoc)plot.html#f)
- **G** | **fill** | **markerfacecolor** | **MarkerFaceColor** | **markercolor** | **mc** :: [Type => Str]

    Select color or pattern for filling of symbols or polygons. BUT WARN: the alias 'fill' will set the
    color of polygons OR symbols but not the two together. If your plot has polygons and symbols, use
    'fill' for the polygons and 'markerfacecolor' for filling the symbols. Same applyies for W bellow
    ($(GMTdoc)plot.html#g)
- **I** | **intens** :: [Type => Str | number]

    Use the supplied intens value (in the [-1 1] range) to modulate the fill color by simulating illumination.
    ($(GMTdoc)plot.html#i)
- **L** | **close** | **polygon** :: [Type => Str]

    Force closed polygons. 
    ($(GMTdoc)plot.html#l)
- **N** | **no_clip** | **noclip** :: [Type => Str or []]

    Do NOT clip symbols that fall outside map border 
    ($(GMTdoc)plot.html#n)
- $(GMT.opt_P)
- **S** | **symbol** | **marker** | **Marker** :: [Type => Str]

    Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines). 
    ($(GMTdoc)plot.html#s)
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

    and select their sizes with the **markersize** or **size** keyword [default is 7p].
    The marker size can be a scalar or a vector with same size numeber of rows of data. Units are
    points unless specified otherwise with (for example for cm) *par=(PROJ_LENGTH_UNIT="c")*

- **W** | **pen** | **markeredgecolor** | **mec** :: [Type => Str]

    Set pen attributes for lines or the outline of symbols
    ($(GMTdoc)plot.html#w)
    WARNING: the pen attributes will set the pen of polygons OR symbols but not the two together.
    If your plot has polygons and symbols, use **W** or **pen** for the polygons and
    **markeredgecolor** for filling the symbols. Similar to S above.
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)

- **Z** | **level** :: [Type => Str | NamedTuple]	`Arg = value|file[+f|+l] | (data=Array|Number, outline=_, fill=_)`

    Paint polygons after the level given as a cte or a vector with same size of number of polygons. Needs a color map.
    ($(GMTdoc)plot.html#z)

- **aspect** :: [Type => Str]

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
- $(GMT.opt_w)
- $(GMT.opt_swap_xy)
- $(GMT.opt_savefig)
"""
function plot(arg1; first=true, kw...)
	common_plot_xyz("", cat_1_arg(arg1), "plot", first, false, kw...)
end
plot!(arg1; kw...) = plot(arg1; first=false, kw...)

function plot(f::Function, range_x=nothing; first=true, kw...)
	rang = gen_coords4funs(range_x, "x"; kw...)
	common_plot_xyz("", cat_2_arg2(rang, [f(x) for x in rang]), "plot", first, false, kw...)
end
plot!(f::Function, rang=nothing; kw...) = plot(f, rang; first=false, kw...)

function plot(f1::Function, f2::Function, range_t=nothing; first=true, kw...)	# Parametric version
	common_plot_xyz("", help_parametric_2f(f1, f2, range_t; is3D=false, kw...), "plot", first, false, kw...)
end
plot!(f1::Function, f2::Function, range_t=nothing; kw...) = plot(f1, f2, range_t; first=false, kw...)

plot(cmd0::String="", arg1=nothing; kw...)  = common_plot_xyz(cmd0, arg1, "plot", true, false, kw...)
plot!(cmd0::String="", arg1=nothing; kw...) = common_plot_xyz(cmd0, arg1, "plot", false, false, kw...)
plot(arg1, arg2; kw...)  = common_plot_xyz("", cat_2_arg2(arg1, arg2), "plot", true, false, kw...)
plot!(arg1, arg2; kw...) = common_plot_xyz("", cat_2_arg2(arg1, arg2), "plot", false, false, kw...)
plot(arg1::Number, arg2::Number; kw...)  = common_plot_xyz("", cat_2_arg2([arg1], [arg2]), "plot", true, false, kw...)
plot!(arg1::Number, arg2::Number; kw...) = common_plot_xyz("", cat_2_arg2([arg1], [arg2]), "plot", false, false, kw...)
# ------------------------------------------------------------------------------------------------------


"""
plotyy(arg1, arg2; kwargs...)

Example:
```julia
plotyy([1 1; 2 2], [1.5 1.5; 3 3], R="0.8/3/0/5", title="Ai", ylabel=:Bla, xlabel=:Ble, seclabel=:Bli, show=1)
```
"""
function plotyy(arg1, arg2; first=true, kw...)
	d = KW(kw)
	(haskey(d, :xlabel)) ? (xlabel = string(d[:xlabel]);	delete!(d, :xlabel)) : xlabel = ""	# Only to used at the end
	(haskey(d, :seclabel)) ? (seclabel = string(d[:seclabel]);	delete!(d, :seclabel)) : seclabel = ""
	((val = find_in_dict(d, [:fmt])[1]) !== nothing) ? (fmt = arg2str(val)) : fmt = FMT[1]
	((val = find_in_dict(d, [:savefig :figname :name])[1]) !== nothing) ? (savefig = arg2str(val)) : savefig = nothing
	Vd = ((val = find_in_dict(d, [:Vd])[1]) !== nothing) ? val : 0

	cmd, opt_B = parse_B(d, "", " -Baf -BW")
	if (opt_B != " -Baf -BW")
		if (occursin(" -Bx", opt_B) || occursin(" -By", opt_B) || occursin("+t", opt_B))
			# OK, so here's the problem. Both title and label maybe multi-words, case in which they will have the
			# form: "aa bb" but since they wont be fully parsed again by parse_B we loose the info about the sapces.
			# The trick is to find and replace the sapces inside the " " chunks like parse_B does and let it undo
			# the replacing without inserting extras -B, like the "aa -Bbb" that would otherwise result.
			t = findall(isequal('"'), opt_B)	# Find indices of the " and hope they came in pairs.
			if (!isempty(t))					# Have a title and maybe an ylabel (or vice-versa)
				opt_B = opt_B[1:t[1]] * replace(opt_B[t[1]+1:t[2]-1], ' '=>'\x7f') * opt_B[t[2]:end]
				if (length(t) == 4)				# Have also an ylabel
					opt_B = opt_B[1:t[3]] * replace(opt_B[t[3]+1:t[4]-1], ' '=>'\x7f') * opt_B[t[4]:end]
				end
			end
			d[:B] = replace(opt_B, "-B" => "")
		else
			d[:B] = " af W"
		end
	else
		d[:B] = " af W"
	end
	(Vd != 0) && (d[:Vd] = Vd)
	d[:lc] = "#0072BD"
	(haskey(d, :show)) ? (delete!(d, :show);  do_show = true) : do_show = false
	d[:par] = (MAP_FRAME_PEN="#0072BD", MAP_TICK_PEN="#0072BD", FONT_ANNOT_PRIMARY="#0072BD", FONT_LABEL="#0072BD")
	r1 = common_plot_xyz("", cat_1_arg(arg1), "plotyy", first, false, d...)

	(Vd != 0) && (d[:Vd] = Vd)
	(seclabel != "" && occursin(" ", seclabel)) && (seclabel = "\"" * seclabel * "\"")
	(seclabel != "") && (seclabel = " y+l" * seclabel)
	d[:B] = " af E"	* seclabel		# Also remember that previous -B was consumed in first call
	d[:lc]  = "#D95319"
	d[:par] = (MAP_FRAME_PEN="#D95319", MAP_TICK_PEN="#D95319", FONT_ANNOT_PRIMARY="#D95319", FONT_LABEL="#D95319")
	r2 = common_plot_xyz("", cat_1_arg(arg2), "plotyy", false, false, d...)

	(xlabel != "" && occursin(" ", xlabel)) && (xlabel = "\"" * xlabel * "\"")
	opt_B = (xlabel != "") ? "af Sn x+l" * xlabel : "af Sn"
	r3 = basemap!(J="", R="", B=opt_B, Vd=Vd, fmt=fmt, name=savefig, show=do_show)
	return (Vd == 2) ? [r1;r2;r3] : nothing
end
# ------------------------------------------------------------------------------------------------------

"""
plot3d(arg1::Array; kwargs...)

reads (x,y,z) triplets and generates PostScript code that will plot lines,
polygons, or symbols at those locations in 3-D.

Full option list at [`plot3d`]($(GMTdoc)plot3d.html)

Parameters
----------

- **A** | **steps** | **straight_lines** :: [Type => Str]  

    By default, geographic line segments are drawn as great circle arcs. To draw them as straight lines, use this option.
- $(GMT.opt_J)
- $(GMT.opt_Jz)
- $(GMT.opt_R)
- $(GMT.opt_B)
- **C** | **color** :: [Type => Str]

    Give a CPT or specify -Ccolor1,color2[,color3,...] to build a linear continuous CPT from those colors automatically.
    ($(GMTdoc)plot3d.html#c)
- **D** | **offset** :: [Type => Str]

    Offset the plot symbol or line locations by the given amounts dx/dy.
    ($(GMTdoc)plot3d.html#d)
- **E** | **error_bars** :: [Type => Str]

    Draw symmetrical error bars.
    ($(GMTdoc)plot3d.html#e)
- **F** | **conn** | **connection** :: [Type => Str]

    Alter the way points are connected
    ($(GMTdoc)plot3d.html#f)
- **G** | **fill** | **markerfacecolor** | **MarkerFaceColor** | **markercolor** | **mc** :: [Type => Str]

    Select color or pattern for filling of symbols or polygons. BUT WARN: the alias 'fill' will set the
    color of polygons OR symbols but not the two together. If your plot has polygons and symbols, use
    'fill' for the polygons and 'markerfacecolor' for filling the symbols. Same applyies for W bellow
    ($(GMTdoc)plot3d.html#g)
- **I** | **intens** :: [Type => Str or number]

    Use the supplied intens value (in the [-1 1] range) to modulate the fill color by simulating illumination.
    ($(GMTdoc)plot3d.html#i)
- **L** | **closed_polygon** :: [Type => Str]

    Force closed polygons. 
    ($(GMTdoc)plot3d.html#l)
- **N** | **no_clip** :: [Type => Str | []]

    Do NOT clip symbols that fall outside map border 
    ($(GMTdoc)plot3d.html#n)
- $(GMT.opt_P)
- **S** | **symbol** | **marker** | **Marker** :: [Type => Str]

    Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines). 
    ($(GMTdoc)plot3d.html#s)
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
- **W** | **pen** | **line_attribs** | **markeredgecolor** | **MarkerEdgeColor** | **mec**:: [Type => Str]
    Set pen attributes for lines or the outline of symbols
    ($(GMTdoc)plot3d.html#w)
    WARNING: the pen attributes will set the pen of polygons OR symbols but not the two together.
    If your plot has polygons and symbols, use **W** or **line_attribs** for the polygons and
    **markeredgecolor** or **MarkerEdgeColor** for filling the symbols. Similar to S above.
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)

- **Z** | **level** :: [Type => Str | NamedTuple]	`Arg = value|file[+f|+l] | (data=Array|Number, outline=_, fill=_)`

    Paint polygons after the level given as a cte or a vector with same size of number of polygons. Needs a color map.
    ($(GMTdoc)plot3d.html#z)
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
- $(GMT.opt_w)
- $(GMT.opt_savefig)

### Example:

    plot3d(x -> sin(x)*cos(10x), y -> sin(y)*sin(10y), z -> cos(z), 0:pi/100:pi, show=true, aspect3=:equal)
"""
plot3d(arg1; kw...)  = common_plot_xyz("", cat_1_arg(arg1), "plot3d", true, true, kw...)
plot3d!(arg1; kw...) = common_plot_xyz("", cat_1_arg(arg1), "plot3d", false, true, kw...)

plot3d(cmd0::String="", arg1=nothing; kw...)  = common_plot_xyz(cmd0, arg1, "plot3d", true, true, kw...)
plot3d!(cmd0::String="", arg1=nothing; kw...) = common_plot_xyz(cmd0, arg1, "plot3d", false, true, kw...)

# ------------------------------------------------------------------------------------------------------
function plot3d(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; first=true, kw...)
	common_plot_xyz("", hcat(arg1[:], arg2[:], arg3[:]), "plot3d", first, true, kw...)
end
plot3d!(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; kw...) = plot3d(arg1, arg2, arg3; first=false, kw...)

function plot3d(f1::Function, f2::Function, range_t=nothing; first=true, kw...)
	common_plot_xyz("", help_parametric_2f(f1, f2, range_t; kw...), "plot3d", first, true, kw...)
end
plot3d!(f1::Function, f2::Function, range_t=nothing; kw...) = plot3d(f1, f2, range_t; first=false, kw...)

function plot3d(f1::Function, f2::Function, f3::Function, range_t=nothing; first=true, kw...)
	common_plot_xyz("", help_parametric_3f(f1, f2, f3, range_t; kw...), "plot3d", first, true, kw...)
end
plot3d!(f1::Function, f2::Function, f3::Function, range_t=nothing; kw...) = plot3d(f1, f2, f3, range_t; first=false, kw...)

const plot3  = plot3d			# Alias
const plot3! = plot3d!
# ------------------------------------------------------------------------------------------------------

"""
    scatter(cmd0::String="", arg1=nothing; kwargs...)

Reads (x,y) pairs and plot symbols at those locations on a map.
This module is a subset of ``plot`` to make it simpler to draw scatter plots. So many of
its (fine) controling parameters are not listed here. For a finer control, user should
consult the ``plot`` module.

Parameters
----------

- **G** | **fill** | **markerfacecolor** :: [Type => Str]

    Select color or pattern for filling of symbols or polygons.
    ($(GMTdoc)plot.html#g)
- **N** | **no_clip** :: [Type => Str | []]

    Do NOT clip symbols that fall outside map border 
    ($(GMTdoc)plot.html#n)
- $(GMT.opt_P)
- **S** :: [Type => Str]

    Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines). 
    ($(GMTdoc)plot.html#s)

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
    points unless specified otherwise with (for example for cm) *par=(PROJ_LENGTH_UNIT=:c,)*	
- **W** | **pen** | **markeredgecolor** | **mec** :: [Type => Str]

    Set pen attributes for lines or the outline of symbols
    ($(GMTdoc)plot.html#w)
- $(GMT.opt_savefig)

[`Full man page`](https://genericmappingtools.github.io/GMT.jl/latest/scatter/)
[`GMT man page`]($(GMTdoc)plot.html)
"""
function scatter(f::Function, range_x=nothing; first=true, kw...)
	rang = gen_coords4funs(range_x, "x"; kw...)
	common_plot_xyz("", cat_2_arg2(rang, [f(x) for x in rang]), "scatter",  first, false, kw...)
end
scatter!(f::Function, rang=nothing; kw...) = scatter(f, rang; first=false, kw...)

function scatter(f1::Function, f2::Function, range_t=nothing; first=true, kw...)	# Parametric version
	common_plot_xyz("", help_parametric_2f(f1, f2, range_t; is3D=false, kw...), "scatter",  first, false, kw...)
end
scatter!(f1::Function, f2::Function, range_t=nothing; kw...) = scatter(f1, f2, range_t; first=false, kw...)

scatter(cmd0::String="", arg1=nothing; first=true, kw...)  = common_plot_xyz(cmd0, arg1, "scatter",  first, false, kw...)
scatter!(cmd0::String="", arg1=nothing; kw...) = common_plot_xyz(cmd0, arg1, "scatter",  false, false, kw...)

scatter(arg; kw...)  = common_plot_xyz("", cat_1_arg(arg), "scatter", true, false, kw...)
scatter!(arg; kw...) = common_plot_xyz("", cat_1_arg(arg), "scatter", false, false, kw...)

scatter(arg1, arg2; kw...)  = common_plot_xyz("", cat_2_arg2(arg1, arg2), "scatter", true, false, kw...)
scatter!(arg1, arg2; kw...) = common_plot_xyz("", cat_2_arg2(arg1, arg2), "scatter", false, false, kw...)

# ------------------------------------------------------------------------------------------------------
scatter3(cmd0::String="", arg1=nothing; kw...)  = common_plot_xyz(cmd0, arg1, "scatter3",  true, true, kw...)
scatter3!(cmd0::String="", arg1=nothing; kw...) = common_plot_xyz(cmd0, arg1, "scatter3",  false, true, kw...)

scatter3(arg; kw...)  = common_plot_xyz("", cat_1_arg(arg), "scatter3", true, true, kw...)
scatter3!(arg; kw...) = common_plot_xyz("", cat_1_arg(arg), "scatter3", false, true, kw...)

function scatter3(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; kw...)
	common_plot_xyz("", hcat(arg1, arg2, arg3), "scatter3", true, true, kw...)
end
function scatter3!(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; kw...)
	common_plot_xyz("", hcat(arg1, arg2, arg3), "scatter3", false, true, kw...)
end

function scatter3(f1::Function, f2::Function, range_t=nothing; first=true, kw...)
	common_plot_xyz("", help_parametric_2f(f1, f2, range_t; kw...), "scatter3", first, true, kw...)
end
scatter3!(f1::Function, f2::Function, range_t=nothing; kw...) = scatter3(f1, f2, range_t; first=false, kw...)

function scatter3(f1::Function, f2::Function, f3::Function, range_t=nothing; first=true, kw...)
	common_plot_xyz("", help_parametric_3f(f1, f2, f3, range_t; kw...), "scatter3", first, true, kw...)
end
scatter3!(f1::Function, f2::Function, f3::Function, range_t=nothing; kw...) = scatter3(f1, f2, f3, range_t; first=false, kw...)

const scatter3d  = scatter3			# Alias
const scatter3d! = scatter3!
# ------------------------------------------------------------------------------------------------------


"""
    bar(cmd0::String="", arg1=nothing; kwargs...)

Reads a file or (x,y) pairs and plots vertical bars extending from base to y.

- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- **fill** :: [Type => Str --

    Select color or pattern for filling the bars
    ($(GMTdoc)plot.html#g)
- **base** | **bottom** :: [Type => Str | Num]		``key=value``

    By default, base = ymin. Use this option to change that value. If base is not appended then we read it.
    from the last input data column.
- **size** | **width** :: [Type => Str | Num]		``key=value``

    The size or width is the bar width. Append u if size is in x-units. When *width* is used the default is plot-distance units.
- $(GMT.opt_savefig)

Example:

    bar(sort(randn(10)), fill=:black, axis=:auto, show=true)
"""
function bar(cmd0::String="", arg=nothing; first=true, kw...)
	d = KW(kw)
	do_cat = (haskey(d, :stack) || haskey(d, :stacked) && isvector(arg) && length(arg) > 2) ? false : true
	if (cmd0 == "" && do_cat) arg = cat_1_arg(arg)  end	# If ARG is a vector, prepend it with a 1:N x column
	GMT.common_plot_xyz(cmd0, arg, "bar", first, false, kw...)
end
bar!(cmd0::String="", arg=nothing; kw...) = bar(cmd0, arg; first=false, kw...)

function bar(f::Function, range_x=nothing; first=true, kw...)
	rang = gen_coords4funs(range_x, "x"; kw...)
	bar("", cat_2_arg2(rang, [f(x) for x in rang]); first=first, kw...)
end
bar!(f::Function, rang=nothing; kw...) = bar(f, rang; first=false, kw...)

bar(arg1, arg2; first=true, kw...)  = common_plot_xyz("", cat_2_arg2(arg1, arg2), "bar", first, false, kw...)
bar!(arg1, arg2; kw...) = common_plot_xyz("", cat_2_arg2(arg1, arg2), "bar", false, false, kw...)
bar(arg; kw...)  = bar("", arg; kw...)
bar!(arg; kw...) = common_plot_xyz("", cat_1_arg(arg), "bar", false, false, kw...)
# ------------------------------------------------------------------------------------------------------

"""
    bar3(cmd0::String="", arg1=nothing; kwargs...)

Read a grid file, a grid or a MxN matrix and plots vertical bars extending from base to z.

- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- **fill** :: [Type => Str]		``key=color``

    Select color or pattern for filling the bars
    ($(GMTdoc)plot.html#g)
- **base** :: [Type => Str | Num]		``key=value``

    By default, base = ymin. Use this option to change that value. If base is not appended then we read it.
- $(GMT.opt_p)
- $(GMT.opt_savefig)

Example:

    G = gmt("grdmath -R-15/15/-15/15 -I0.5 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
    bar3(G, lw=:thinnest, show=true)
"""
function bar3(cmd0::String="", arg=nothing; first=true, kwargs...)
	# Contrary to "bar" this one has specific work to do here.
	d = KW(kwargs)
	opt_z = ""

	if (isa(arg, Array{<:GMTdataset,1}))  arg1 = arg[1]	# It makes no sense accepting > 1 datasets
	else                                  arg1 = arg	# Make a copy that may or not become a new thing
	end

	if (isa(arg1, Array))
		ny, nx = size(arg1)
		if ((nx >= 3 && ny > 3))  arg1 = mat2grid(arg1)  end		# Assume it is a 'bare grid'
	elseif (cmd0 != "")
		if ((val = find_in_dict(d, [:grd :grid])[1]) !== nothing)
			arg1 = gmtread(cmd0, grd=true)
		elseif ((val = find_in_dict(d, [:dataset :table])[1]) !== nothing)
			arg1 = gmtread(cmd0, dataset=true)
		else
			error("BAR3: When first arg is a name, must also state its type. e.g. grd=true or dataset=true")
		end
	end

	opt_base = add_opt(d, "", "", [:base])	# No need to purge because base is not a psxy option

	if (isa(arg1, GMTgrid))
		if (haskey(d, :bar))
			opt_S = parse_bar_cmd(d, :bar, "", "So")[1]
		else
			# 0.85 is the % of inc width of bars
			w1::Float64, w2::Float64 = arg1.inc[1]*0.85, arg1.inc[2]*0.85
			opt_S = " -So$(w1)u/$(w2)u"
			if     (haskey(d, :nbands))  opt_z = string("+z", d[:nbands]);	delete!(d, :nbands)
			elseif (haskey(d, :Nbands))  opt_z = string("+Z", d[:Nbands]);	delete!(d, :Nbands)
			end
		end
		opt, = parse_R(d, "", !first)
		if (opt == "" || opt == " -R")			# OK, no R but we know it here so put it in 'd'
			if (arg1.registration == 1)			# Fine, grid is already pixel reg
				push!(d, :R => arg1.range)
			else								# Need to get a pix reg R
				range = deepcopy(arg1.range)
				range[1] -= arg1.inc[1] / 2;	range[2] += arg1.inc[1] / 2;
				range[3] -= arg1.inc[2] / 2;	range[4] += arg1.inc[2] / 2;
				push!(d, :R => range)
			end
			z_min = arg1.range[5]
		elseif (opt_base == "")					# Shit, need to get zmin out of the opt_R string
			t = split(opt, '/')
			(length(t) == 6) ? z_min = t[5] : error("For 3D cases, region must have 6 selements")
		end
		if (opt_base == "")  push!(d, :base => z_min)  end	# Make base = z_min
		arg1 = gmt("grd2xyz", arg1)				# Now arg1 is a GMTdataset
	else
		opt_S = parse_I(d, "", [:S :width], "So", true)
		if (opt_S == "")
			opt_S = parse_bar_cmd(d, :bar, "", "So", true)[1]
		end
		if (opt_S == "")
			if ((isa(arg1, Array) && size(arg1,2) < 5) || (isa(arg1, GMTdataset) && size(arg1.data,2) < 5))
				error("BAR3: When NOT providing *width* data must contain at least 5 columns.")
			end
		end
		#if (opt_S != "" && !isletter(opt_S[end]))   opt_S = opt_S * 'u'  end
		if     (haskey(d, :nbands))  opt_z = string("+z", d[:nbands]);	delete!(d, :nbands)
		elseif (haskey(d, :Nbands))  opt_z = string("+Z", d[:Nbands]);	delete!(d, :Nbands)
		end
	end

	opt_base = add_opt(d, "", "", [:base])		# Do this again because :base may have been added above
	if (opt_base == "")
		_z_min::Float32 = (isa(arg1, Array)) ? minimum(view(arg1, :, 3)) : minimum(view(arg1.data, :, 3))
		opt_S *= "+b$_z_min" 
	else
		opt_S *= "+b" * opt_base
	end

	common_plot_xyz("", arg1, "bar3|" * opt_S * opt_z, first, true, d...)
end

bar3(arg1; kw...) = bar3("", arg1; first=true, kw...)
bar3!(cmd0::String="", arg1=nothing; kw...) = bar3(cmd0, arg1; first=false, kw...)
bar3!(arg1; kw...) = bar3("", arg1; first=false, kw...)
# ------------------------------------------------------------------------------------------------------

"""
    arrows(cmd0::String="", arg1=nothing; arrow=(...), kwargs...)

Plots an arrow field. When the keyword *arrow=(...)* or *vector=(...)* is used, the direction (in degrees
counter-clockwise from horizontal) and length must be found in columns 3 and 4, and size, if not specified
on the command-line, should be present in column 5. The size is the length of the vector head. Vector stem
width is set by option *pen* or *line_attrib*.

The *vecmap=(...)* variation is similar to above except azimuth (in degrees east of north) should be
given instead of direction. The azimuth will be mapped into an angle based on the chosen map projection.
If length is not in plot units but in arbitrary user units (e.g., a rate in mm/yr) then you can use the
*input_col* option to scale the corresponding column via the +sscale modifier.

The *geovec=(...)* or *geovector=(...)* keywords plot geovectors. In geovectors azimuth (in degrees east from north) and geographical length must be found in columns 3 and 4. The size is the length of the vector head. Vector width is set by *pen* or *line_attrib*. Note: Geovector stems are drawn as thin filled polygons and hence pen attributes like dashed and dotted are not available. For allowable geographical units, see the *units=()* option.

The full *arrow* options list can be consulted at [Vector Attributes](@ref)

- $(GMT.opt_B)
- $(GMT.opt_J)
- $(GMT.opt_R)
- **W** | **pen** | **line_attrib** :: [Type => Str]

    Set pen attributes for lines or the outline of symbols
    ($(GMTdoc)plot.html#w)
- $(GMT.opt_savefig)

Example:

	arrows([0 8.2 0 6], limits=(-2,4,0,9), arrow=(len=2,stop=1,shape=0.5,fill=:red), axis=:a, pen="6p", show=true)
"""
function arrows(cmd0::String="", arg1=nothing; first=true, kwargs...)
	# A arrows plotting method of plot
	d = KW(kwargs)
	cmd = helper_arrows(d, true)	# Have to delete to avoid double parsing in -W
	cmd = (cmd == "") ? " -Sv0.5+e+h0.5" : " -S" * cmd
	GMT.common_plot_xyz(cmd0, arg1, cmd, first, false, d...)
end

function helper_arrows(d::Dict, del::Bool=true)
	# Helper function to set the vector head attributes
	(show_kwargs[1]) && return print_kwarg_opts([:arrow :vector :arrow4 :vector4 :vecmap :geovec :geovector], "NamedTuple | String")

	cmd::String = ""
	val, symb = find_in_dict(d, [:arrow :vector :arrow4 :vector4 :vecmap :geovec :geovector], del)
	if (val !== nothing)
		code = 'v'
		if (symb == :geovec || symb == :geovector)
			code = '='
		elseif (symb == :vecmap)	# Uses azimuth and plots angles taking projection into account
			code = 'V'
		end
		if (isa(val, String))		# An hard core GMT string directly with options
			cmd = (val[1] != code) ? code * val : val	# In last case the GMT string already has vector flag char
		elseif (isa(val, Real))  cmd = code * "$val"
		elseif (symb == :arrow4 || symb == :vector4)  cmd = code * vector4_attrib(val)
		else                     cmd = code * vector_attrib(val)
		end
	end
	return cmd
end

arrows!(cmd0::String="", arg1=nothing; kw...) = arrows(cmd0, arg1; first=false, kw...)
arrows(arg1; kw...)  = arrows("", arg1; first=true, kw...)
arrows!(arg1; kw...) = arrows("", arg1; first=false, kw...)
# ------------------------------------------------------------------------------------------------------

"""
    lines(cmd0::String="", arg1=nothing; decorated=(...), kwargs...)

Reads a file or (x,y) pairs and plots a collection of different line with decorations

- $(GMT.opt_B)
- $(GMT.opt_J)
- $(GMT.opt_R)
- **W** | **pen** | **line_attrib** :: [Type => Str]

    Set pen attributes for lines or the outline of symbols
    ($(GMTdoc)plot.html#w)
- $(GMT.opt_savefig)

Examples:

    lines([0, 10]; [0, 20], limits=(-2,12,-2,22), proj="M2.5", pen=1, fill=:red,
		  decorated=(dist=(val=1,size=0.25), symbol=:box), show=true)

    lines(x -> cos(x) * x, y -> sin(y) * y, linspace(0,2pi,100), region=(-4,7,-5.5,2.5), lw=2, lc=:sienna,
          decorated=(quoted=true, const_label=" In Vino Veritas  - In Aqua, Rãs & Toads", font=(25,"Times-Italic"),
                     curved=true, pen=(0.5,:red)), aspect=:equal, fmt=:png, show=true)
"""
lines(cmd0::String="", arg1=nothing; first=true, kwargs...) = common_plot_xyz(cmd0, arg1, "lines", first, false, kwargs...)
lines!(cmd0::String="", arg=nothing; kw...) = lines(cmd0, arg; first=false, kw...)

function lines(f::Function, rang=nothing; first=true, kw...)
	rang = gen_coords4funs(rang, "x"; kw...)
	lines("", cat_2_arg2(rang, [f(x) for x in rang]); first=first, kw...)
end
lines!(f::Function, rang=nothing; kw...) = lines(f, rang; first=false, kw...)

function lines(f1::Function, f2::Function, rang=nothing; first=true, kw...)	# Parametric version
	lines("", help_parametric_2f(f1, f2, rang; is3D=false, kw...); first=first, kw...)
end
lines!(f1::Function, f2::Function, rang=nothing; kw...) = lines(f1, f2, rang; first=false, kw...)

lines(arg1, arg2; kw...)  = lines("", cat_2_arg2(arg1, arg2); first=true, kw...)
lines!(arg1, arg2; kw...) = lines("", cat_2_arg2(arg1, arg2); first=false, kw...)
lines(arg; kw...)  = lines("", cat_1_arg(arg); first=true, kw...)
lines!(arg; kw...) = lines("", cat_1_arg(arg); first=false, kw...)
# ------------------------------------------------------------------------------------------------------

"""
    stairs(cmd0::String="", arg1=nothing; step=:post, kwargs...)

Plot a stair function. The `step`` parameter can take the following values:

`:post` - The default. Lines move first along x for cartesian plots or the parallels for geographic
          and then along y or the meridians.
`:pre`  - Lines move first along y for cartesian plots or the meridians for geographic
          and then along x or the parallels.

Example:

    x = linspace(0, 4*pi, 50);
	stairs(x, sin.(x), show=true)
"""
function stairs(cmd0::String="", arg1=nothing; first=true, step=:post, kwargs...)
	d = KW(kwargs)
	d[:stairs_step] = step
	lines(cmd0, arg1; first=first, d...)
end
stairs!(cmd0::String="", arg1=nothing; step=:post, kw...) = stairs(cmd0, arg1; first=false, step=step, kw...)
stairs(arg; step=:post, kw...) = stairs("", cat_1_arg(arg); step=step, kw...)
stairs!(arg; step=:post, kw...) = stairs("", cat_1_arg(arg); first=false, step=step, kw...)
stairs(arg1, arg2; kw...)  = stairs("", cat_2_arg2(arg1, arg2); step=step, kw...)
stairs!(arg1, arg2; kw...)  = stairs("", cat_2_arg2(arg1, arg2); first=false, step=step, kw...)

# ------------------------------------------------------------------------------------------------------
"""
    band(cmd0::String="", arg1=nothing; width=0.0, envelope=false, kwargs...)

Plot a line with a symmetrical or asymmetrical band around it. If the band is not color filled then,
by default, only the envelope outline is plotted.

Example: Plot the sinc function with a green band of width 0.1 (above and below the sinc line)

    x = y = -10:0.11:10;
	band(x, sin.(x)./x, width=0.1, fill="green@80", show=true)

or, the same but using a function

    band(x->sin(x)/x, 10, width=0.1, fill="green@80", show=true)
"""
function band(cmd0::String="", arg1=nothing; first=true, width=0.0, envelope=false, kwargs...)
	(!isa(width, Real) && !isa(width, Tuple{<:Real, <:Real})) && error("The 'width' value must be a scalar or a Tuple of scalars")
	d = KW(kwargs)
	(cmd0 != "") && (arg1 = read_data(d, cmd0, "", arg1, " ", false, true)[2])	# Make sure we have the data here
	n_cols = (isa(arg1, Vector{<:GMTdataset})) ? size(arg1[1],2) : size(arg1,2)
	(n_cols < 3 && width == 0 && !envelope) && error("Data table has less than 3 columns and no width specified.")

	opt_L = (n_cols == 3) ? "+d" : ""
	opt_L = (n_cols == 4) ? (envelope ? "+b" : "+D") : ""
	if (opt_L == "")	# Shit, it means we need to expand the dataset matrices. But only 'width' case is possibe
		if (isa(arg1, Vector{<:GMTdataset}))
			if (isa(width, Real))
				for k in eachindex(arg1)  arg1[k].data = [arg1[k].data repeat([width], size(arg1[k],1))]  end
				opt_L = "+d"
			else
				for k in eachindex(arg1)  arg1[k].data = [arg1[k].data repeat([width[1] width[2]], size(arg1[k],1))]  end
				opt_L = "+D"
			end
		else
			ec = isa(width, Real) ? repeat([width], size(arg1,1)) : repeat([width[1] width[2]], size(arg1,1))
			(isa(arg1, GMTdataset)) ? (arg1.data = [arg1.data ec]) : arg1 = [arg1 ec]
			opt_L = isa(width, Real) ? "+d" : "+D"
		end
	end
	# Above we made some -L guessings but users may want to apply finer control, so let them access all options
	_L = add_opt(d, "", "", [:L :polygon], (sym="_+d", asym="_+D", envelope="_+b", pen=("+p",add_opt_pen)))
	d[:L] = (_L != "") ? _L : opt_L
	multi_col[1] = false		# Some cat_2_arg2 paths set it to true, wich cannot happen in this function 

	common_plot_xyz("", arg1, "lines", first, false, d...)
end
band!(cmd0::String="", arg1=nothing; width=0.0, envelope=false, kw...) =
	band(cmd0, arg1; first=false, width=width, envelope=envelope, kw...)
band(arg; width=0.0, envelope=false, kw...)  = band("", cat_1_arg(arg); width=width, envelope=envelope, kw...)
band!(arg; width=0.0, envelope=false, kw...) = band("", cat_1_arg(arg); first=false, width=width, envelope=envelope, kw...)

band(arg1, arg2; width=0.0, envelope=false, kw...) =
	band("", cat_2_arg2(arg1, arg2); width=width, envelope=envelope, kw...)
band!(arg1, arg2; width=0.0, envelope=false, kw...) =
	band("", cat_2_arg2(arg1, arg2); first=false, width=width, envelope=envelope, kw...)
band(arg1, arg2, arg3; kw...) = band("", cat_3_arg2(arg1, arg2, arg3); envelope=true, kw...)
band!(arg1, arg2, arg3; kw...) = band("", cat_3_arg2(arg1, arg2, arg3); first=false, envelope=true, kw...)

function band(f::Function, rang=nothing; first=true, width=0.0, envelope=false, kw...)
	rang = gen_coords4funs(rang, "x"; kw...)
	band("", cat_2_arg2(rang, [f(x) for x in rang]); first=first, width=width, envelope=envelope, kw...)
end
band!(f::Function, rang=nothing; width=0.0, envelope=false, kw...) = band(f, rang; first=false, width=width, envelope=envelope, kw...)

# ------------------------------------------------------------------------------------------------------
"""
    hlines(arg; decorated=(...), kwargs...)

Plots one or a collection of horizontal lines with eventual decorations

- $(GMT.opt_B)
- $(GMT.opt_J)
- $(GMT.opt_R)
- **W** | **pen** | **line_attrib** :: [Type => Str]

    Set pen attributes for the horizontal lines
    ($(GMTdoc)plot.html#w)

Example:

    plot(rand(5,3))
    hlines!([0.2, 0.6], pen=(1, :red), show=true)
"""
function hlines(arg1=nothing; first=true, kwargs...)
	# A lines plotting method of plot
	d = KW(kwargs)
	(arg1 === nothing && ((arg1_ = find_in_dict(d, [:data])[1]) === nothing)) && error("No input data")
	# If I don't do this stupid gymn with arg1 vs arg1_ then arg1 is Core.Boxed F..
	len::Int = (arg1 !== nothing) ? length(arg1) : length(arg1_)
	mat::Matrix{Float64} = ones(2, len)
	if (arg1 !== nothing)
		for k = 1:len   mat[1,k] = mat[2,k] = arg1[k]   end
	else
		for k = 1:len   mat[1,k] = mat[2,k] = arg1_[k]  end
	end
	x::Vector{Float64} = ((opt_R = parse_R(d, "")[2]) != "") ? vec(opt_R2num(opt_R)[1:2]) : [-1e50, 1e50]
	D::Vector{GMTdataset} = mat2ds(mat, x=x, multi=true)

	common_plot_xyz("", D, "lines", first, false, d...)
end
hlines!(arg=nothing; kw...) = hlines(arg; first=false, kw...)
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
"""
    vlines(arg; decorated=(...), kwargs...)

Plots one or a collection of vertical lines with eventual decorations

- $(GMT.opt_B)
- $(GMT.opt_J)
- $(GMT.opt_R)
- **W** | **pen** | **line_attrib** :: [Type => Str]

    Set pen attributes for the horizontal lines
    ($(GMTdoc)plot.html#w)

Example:

    plot(rand(5,3), region=[0,1,0,1])
    vlines!([0.2, 0.6], pen=(1, :red), show=true)
"""
function vlines(arg1=nothing; first=true, kwargs...)
	# A lines plotting method of plot
	d = KW(kwargs)
	(arg1 === nothing && ((arg1_ = find_in_dict(d, [:data])[1]) === nothing)) && error("No input data")
	# If I don't do this stupid gymn with arg1 vs arg1_ then arg1 is Core.Boxed F..
	len::Int = (arg1 !== nothing) ? length(arg1) : length(arg1_)

	mat::Matrix{Float64} = ones(2, len)
	mat[1,:] = mat[2,:] = (arg1 !== nothing) ? arg1 : arg1_
	x::Vector{Float64} = ((opt_R = parse_R(d, "")[2]) != "") ? vec(opt_R2num(opt_R)[3:4]) : [-1e50, 1e50]
	D::Vector{GMTdataset} = mat2ds(mat, x=x, multi=true)
	# Now we need tp swapp x / y columns because the vlines case is more complicated to implement.
	for k = 1:len
		D[k].data[:,1], D[k].data[:,2] = D[k].data[:,2], D[k].data[:,1]
	end

	common_plot_xyz("", D, "lines", first, false, d...)
end
vlines!(arg=nothing; kw...) = vlines(arg; first=false, kw...)
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
hband(mat::Matrix{<:Real}; height=false, percent=false, first=true, kw...) =
	helper_hvband(mat, "h"; height=height, percent=percent, first=first, kw...)
hband!(mat::Matrix{<:Real}; height=false, percent=false, kw...) =
	helper_hvband(mat, "h"; height=height, percent=percent, first=false, kw...)
vband(mat::Matrix{<:Real}; width=false, percent=false, first=true, kw...) =
	helper_hvband(mat, "v"; width=width, percent=percent, first=first, kw...)
vband!(mat::Matrix{<:Real}; width=false, percent=false, kw...) =
	helper_hvband(mat, "v"; width=width, percent=percent, first=false, kw...)
const vspan  = vband
const vspan! = vband!
const hspan  = hband
const hspan! = hband!

function helper_hvband(mat::Matrix{<:Real}, tipo="v"; width=false, height=false, percent=false, first=true, kwargs...)
	# This is the main function for the hband and vband functions.
	d, _, O = init_module(first, kwargs...)
	cmd, = parse_R(d, "", O, false)
	all(CTRL.limits .== 0.) && error("Need to know the axes limits in a numeric form.")
	cmd, = parse_J(d, cmd, "", true, O, false)
	!CTRL.proj_linear[1] && error("Plotting vbands is only possible with linear projections.")
	cmd, = parse_B(d, cmd)
	n_ds = size(mat, 1)
	got_pattern = false
	fill = find_in_dict(d, [:fill :color])[1]
	colors = (fill === nothing) ? Base.fill("lightblue", n_ds) :
	         (isa(fill, String) || isa(fill, Symbol)) ? Base.fill(string(fill), n_ds) :
	         (isa(fill, Array{String}) || isa(fill, Array{Symbol})) ? string.(fill) :
			 isa(fill, Tuple) && (eltype(fill) == String || eltype(fill) == Symbol) ? string.(fill) :
			 isa(fill, NamedTuple) ? (got_pattern = true; [add_opt_fill(fill)]) :		# Single pattern
			 isa(fill, Tuple) && isa(fill[1], NamedTuple) ? (got_pattern = true; [add_opt_fill(fi) for fi in fill]) :
			 error("Bad color argument")
	alpha = find_in_dict(d, [:fillalpha :alpha :transparency])[1]
	transp = (alpha === nothing) ? Base.fill("@75", n_ds) :
	         isa(alpha, Real) ? Base.fill(isa(alpha, AbstractFloat) ? string("@",alpha*100) : string("@",alpha), n_ds) :
			 isvector(alpha) || isa(alpha, Tuple) ? (eltype(alpha) <: AbstractFloat ? string.("@",alpha.*100) : string.("@",alpha)) :
			 error("Bad transparency (fillapha) argument")

	if (tipo == "v")  ind_w, ind_b, ind_t, thick, bB = 7:8, 9, 10, width  != 0, "b"
	else              ind_w, ind_b, ind_t, thick, bB = 9:10, 7, 9, height != 0, "B"
	end

	D::Vector{GMTdataset} = Vector{GMTdataset}(undef, n_ds)
	for k = 1:n_ds
		w = (thick) ? mat[k,2] : (percent != 0) ? mat[k,2]*diff(CTRL.limits[ind_w]) : mat[k,2]-mat[k,1]	# bar width
		i = rem(k, length(colors)); (i == 0) && (i = length(colors))
		j = rem(k, length(transp)); (j == 0) && (j = length(transp))
		b = (size(mat,2) > 2 && !isnan(mat[k,3])) ? mat[k,3] : CTRL.limits[ind_b]	# The bar base
		t = (size(mat,2) > 3 && !isnan(mat[k,4])) ? mat[k,4] : CTRL.limits[ind_t]	# The bar top
		hdr = string("-S", bB, w, "u+b", b, "0 -G", colors[i], transp[j])
		c = (thick || percent != 0) ? mat[k,1] : (mat[k,1] + (mat[k,2] - mat[k,1]) / 2)	# Bar center position
		D[k] = GMTdataset((tipo == "v") ? [c t 0] : [t c 0], Float64[], Float64[], Dict{String, String}(), String[], String[], hdr, String[], "", "", 0, 0)
	end

	haskey(d, :nested) && (CTRL.pocket_call[1] = D; delete!(d, :nested)) # Happens only when called nested from plot

	d[:S] = bB						# Add -Sb|B, otherwise headers are not scanned.
	got_pattern && (d[:G] = "p1")	# Patterns fck the session. Use this to inform gmt() that session must be recreated
	common_plot_xyz("", D, "", first, false, d...)
end

# ------------------------------------------------------------------------------------------------------
"""
    ternary(cmd0="", arg1=nothing; image=false, clockwise=false, kwargs...)

Reads (a,b,c[,z]) records from table [or file] and plots image and symbols at those locations on a ternary diagram.

- **B** | **frame** :: [Type => NamedTuple | Str] --

    For ternary diagrams the three sides are referred to as a (bottom), b (right), and c (left). The default is to
    annotate and draw grid lines but without labeling the axes. But since labeling is a very important feature, you
    can use the `labels` option that take as argument a 3 elements Tuple with the labels of the 3 axes. Further
    control on annotations and grid spacing (on/off) is achieved by using the `frame=(annot=?, grid=?, alabel=?, blabel=?,
    clabel=?, suffix=?)` form. Note that not all options of the general `frame` options are accepted in this module and for more
    elaborated frame option selection you will have to resort to the pure GMT syntax in the form `frame="<arg> <arg> <arg>"`
    ($(GMTdoc)psternary.html#b)
- $(GMT.opt_C)
- **G** | **fill** :: [Type => Str] --

    Select color or pattern for filling the bars
    ($(GMTdoc)psternary.html#c)
- **L** | **vertex_labels** :: [Type => Str | Tuple of strings] --		`Arg = a/b/c`

    Set the labels for the three diagram vertices where the component is 100% [none]. 
    ($(GMTdoc)psternary.html#l)
- **M** | **dump** :: [Type => Str]

    Dumps the converted input (a,b,c[,z]) records to Cartesian (x,y,[,z]) records, where x, y
    are normalized coordinates on the triangle (i.e., 0–1 in x and 0–sqrt(3)/2 in y). No plotting occurs.
    ($(GMTdoc)coast.html#m)
- **N** | **no_clip** | **noclip** :: [Type => Str or []]

    Do NOT clip symbols that fall outside map border 
    ($(GMTdoc)psternary.html#n)
- **R** | **region** | **limits** :: [Type => Tuple | Str]

    Give the min and max limits for each of the three axis a, b, and c. Default is (0,100,0,100,0,100)
- $(GMT.opt_P)
- **S** | **symbol** :: [Type => Str]

    Plot individual symbols in a ternary diagram. If `S` is not given then we will instead plot lines
    (requires `pen`) or polygons (requires `color` or `fill`). 
    ($(GMTdoc)psternary.html#s)

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
    points unless specified otherwise with (for example for cm) *par=(PROJ_LENGTH_UNIT=:c,)*	
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** | **pen** :: [Type => Str | Number]

    Sets the attributes for the particular line.
    ($(GMTdoc)psternary.html#w)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_p)
- $(GMT.opt_q)
- $(GMT.opt_t)
- $(GMT.opt_savefig)

Other than the above options, the `kwargs` input accepts still the following options
- `image`: - Fills the ternary plot with an image computed automatically with `grdimage` from a grid interpolated with `surface`
- `contour`: - This option works in two different ways. If used together with `image` it overlays a contour
               by doing a call to `grdcontour`. However, if used alone it will call `contour` to do the contours.
               The difference is important because this option can be used in *default mode* with `contour=true`
               where the number and annotated contours is picked automatically, or the use can exert full control
               by passing as argument a NamedTuple with all options appropriated to that module. *e.g.*
               `contour=(cont=10, annot=20, pen=0.5)`
- `contourf`: - Works a bit like the _standalone_ `contour`. If used with `contourf=true` call make a filled contour
                using automatic parameters. The form `contourf=(...)` let us selects options of the contourf module.
- `clockwise`: - Set it to `true` to indicate that positive axes directions be clock-wise
                 [Default lets the a, b, c axes be positive in a counter-clockwise direction].
"""
function ternary(cmd0::String="", arg1=nothing; first::Bool=true, image::Bool=false, kwargs...)
	# A wrapper for psternary
	(cmd0 == "" && arg1 === nothing) && (arg1 = [0.0 0.0 0.0])	# No data in, just a kind of ternary basemap
	(cmd0 != "") && (arg1 = gmtread(cmd0))
	d = init_module(first, kwargs...)[1]
	opt_J = parse_J(d, "", " -JX" * split(def_fig_size, '/')[1] * "/0", true, false, false)[2]
	opt_R = parse_R(d, "")[1]
	d[:R] = (opt_R ==  "") ? "0/100/0/100/0/100" : opt_R[4:end]
	parse_B4ternary!(d, first)
	clockwise = haskey(d, :clockwise)
	if (image || haskey(d, :contourf) || haskey(d, :contour))
		t = tern2cart(isa(arg1, GMTdataset) ? arg1.data : isa(arg1, Vector{<:GMTdataset}) ? arg1[1].data : arg1, clockwise)
		!endswith(opt_J, "/0") && (opt_J *= "/0")			# Need the "/0". Very important.
		if (haskey(d, :contourf))
			contourf(t, R=(0.0,1.0,0,sqrt(3)/2), B=:none, J=opt_J[4:end], backdoor=d[:contourf], first=first)
			delete!(d, :contourf)
		else
			G = gmt("surface -R0/1/0/0.865 -I0.005 -T0.5 -Vq", t)
			Gmask = gmt("grdmask -R0/1/0/0.865 -I0.005 -NNaN/1/1", [0.0 0; 0.5 0.865; 1 0; 0 0])
			G *= Gmask
			if (image)			# grdimage plus eventual contours
				grdimage(G, B=:none, J=opt_J[4:end], Q=true, first=first)
				if (haskey(d, :contour))
					grdcontour!(G, backdoor=d[:contour])
					delete!(d, :contour)
				end
			else				# Only contours
				pscontour(t, R=(0.0,1.0,0,sqrt(3)/2), B=:none, J=opt_J[4:end], backdoor=d[:contour], first=first)
				delete!(d, :contour)
			end
		end
		first = false
	end
	if (clockwise)
		endswith(opt_J, "/0") && (opt_J = opt_J[1:end-2])		# Strip the trailing "/0". Very important.
		d[:J] = "X-" * opt_J[5:end]
		del_from_dict(d, [:proj, :projection])		# To avoid non-consumed warnings
		delete!(d, :clockwise)
	end
	if ((val = find_in_dict(d, [:par :conf :params], false)[1]) === nothing)
		d[:par] = (MAP_GRID_PEN_PRIMARY="thinnest,gray",)
	end
	if (GMTver <= v"6.2.0" && (val = find_in_dict(d, CPTaliases, false)[1]) !== nothing && isa(val, GMTcpt))
		_name = joinpath(tempdir(), "GMTjl_tmp.cpt");
		gmtwrite(_name, val);	d[:C] = _name	# Workaround a bug in 6.2.0
	end
	(G_API[1] == C_NULL) && gmt_restart()	# Force having a valid API. We can't afford otherwise here.
	(GMTver <= v"6.2.0") && gmtlib_setparameter(G_API[1], "MAP_FRAME_AXES", "WESNZ")	# Because of a bug in 6.2.0 modern theme
	r = common_plot_xyz("", arg1, "ternary", first, false, d...)
	(GMTver <= v"6.2.0") && gmtlib_setparameter(G_API[1], "MAP_FRAME_AXES", "auto")
	# With the following trick we leave the -R history in 0/1/0/1 and so we can append with plot, text, etc
	gmt("psxy -Scp -R0/1/0/1 -JX -O -Vq > " * joinpath(tempdir(), "lixo.ps"), [0. 0.])
	return r
end

function parse_B4ternary!(d::Dict, first::Bool=true)
	# Ternary accepts only a special brand of -B. Try to parse and/or build -B option
	opt_B = parse_B(d, "", " -Bafg")[2]
	if ((val = find_in_dict(d, [:labels])[1]) !== nothing)		# This should be the easier way
		!(isa(val,Tuple) && length(val) == 3) && error("The `labels` option must be Tuple with 3 elements.")
		opt_Bs = split(opt_B)							# This drops the leading ' '
		x = (opt_Bs[1][3] == 'p') ? opt_Bs[1][4:end] : opt_Bs[1][3:end]
		d[:B] = " -Ba$(x)+l" * string(val[1]) * " -Bb$(x)+l" * string(val[2]) * " -Bc$(x)+l" * string(val[3])
		[d[:B] *= " " * opt_Bs[k] for k = 2:length(opt_Bs)]		# Append the remains, if any.
	else		# Ui, try to parse a string like this: " -Bpag8+u\" %\" -Ba+la -Bb+lb -Bc+lc"
		(!first && opt_B == " -Bafg") && return			# Do not use the default -B on overlays.
		opt_Bs = split(opt_B, " -B")[2:end]				# 2:end because surprisingly the first is = ""
		if (length(opt_Bs) == 1)  d[:B] = opt_B			# Accept whatever was selected
		else											# User may have used frame=(annot=?,grid=?, alabel=?,...)
			if (length(opt_Bs) == 3) d[:B] = opt_B		# OK, silly no annotations,ticks,grid
			else
				x = opt_Bs[1][2:end]
				d[:B] = " -Ba$(x)" * opt_Bs[2][2:end] * " -Bb$(x)" * opt_Bs[3][2:end] * " -Bc$(x)" * opt_Bs[4][2:end]
				[d[:B] *= " -B" * opt_Bs[k] for k = 5:length(opt_Bs)]		# Append the remains, if any.
			end
		end
	end
end

"""
    tern2cart(abcz::Matrix{<:Real}, reverse::Bool=false)

Converts ternary to cartesian units.

`abcz` is either a Mx3 (a,b,c) or Mx4 (a,b,c,z) matrix

"""
function tern2cart(abcz::Matrix{<:Real}, reverse::Bool=false)
	# converts ternary to cartesian units. ABCZ is either a Mx3 (a,b,c) or Mx4 (a,b,c,z) matrix
	a,b,c = !reverse ? (3,1,2) : (1,2,3)
	s = view(abcz, :, a) + view(abcz, :, b) + view(abcz, :, c)	# s = (a + b + c)
	x = 0.5 .* (2.0 .* view(abcz, :, b) + view(abcz, :, c)) ./ s
	y = 0.5 .* sqrt(3.) .* view(abcz, :, c) ./ s
	return (size(abcz,2) == 3) ? [x y] : [x y abcz[:,4]]
end

function dict_auto_add!(d::Dict)
	# If the Dict 'd' has a 'backdoor' member that is a NamedTuple, add its contents to the Dict
	if ((val = find_in_dict(d, [:backdoor])[1]) !== nothing && isa(val, NamedTuple))
		key = keys(val)
		for n = 1:length(val)  d[key[n]] = val[n]  end
		delete!(d, :backdoor)
	end
end

ternary!(cmd0::String="", arg1=nothing; kw...) = ternary(cmd0, arg1; first=false, kw...)
ternary(arg1;  kw...) = ternary("", arg1; first=true, kw...)
ternary!(arg1; kw...) = ternary("", arg1; first=false, kw...)
ternary(kw...) = ternary("", nothing; first=true, kw...)
const psternary  = ternary            # Aliases
const psternary! = ternary!           # Aliases

# ----------------------------------------------------------------------------------------------
"""
    events(cmd0::String, arg1=nothing; kwargs...)

Plot event symbols and labels for a moment in time

Full option list at [`events`]($(GMTdoc)events.html)

Parameters
----------

- **T** | **now** :: [Type => Int | Str]

    Set the current plot time. If absolute times are used you must also use -fT.
    ($(GMTdoc)events.html#t)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **D** | **shift** | **offset** :: [Type => Str]	``Arg = [j|J]dx[/dy][+v[pen]]``

    Offset the text from the projected (x,y) point by dx,dy [0/0].
    ($(GMTdoc)events.html#d)
- **E** | **knots** :: [Type => Str]	``Arg = s|t[+o|Odt][+rdt][+pdt][+ddt][+fdt][+ldt]``

    Set the time knots for the symbol or text time-functions.
    ($(GMTdoc)events.html#e)
- **G** | **fill** :: [Type => Str | Int | Touple]

    Set constant shade or color for all symbols.
    ($(GMTdoc)events.html#g)
- $(GMT.opt_J)
- **L** | **duration** :: [Type => Bool | Number | Str]		``Arg = [length|t]``

    Specify the length (i.e., duration) of the event.
    ($(GMTdoc)events.html#l)
- **M** | **rise** :: [Type => Str]		``Arg = i|s|t[val1][+cval2]``

    Modify the initial intensity, size magnification, or transparency of the symbol during the rise interval.
    ($(GMTdoc)events.html#m)
- **Q** | **save** :: [Type => Number]

    Save the intermediate event symbols and labels to permanent files instead of removing them when done.
    ($(GMTdoc)events.html#q)
- $(GMT.opt_R)
- **W** | **pen** | **markeredgecolor** | **mec** :: [Type => Str]

    Specify symbol outline pen attributes [Default is no outline].
    ($(GMTdoc)events.html#w)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_p)
- $(GMT.opt_swap_xy)
- $(GMT.opt_savefig)
"""
# ------------------------------------------------------------------------------------------------------
function events(cmd0::String="", arg1=nothing; kwargs...)
	# events share a lot of options with plot
	d = KW(kwargs)
	cmd = add_opt(d, "", "T", [:T :now])
	if (!occursin("-T", cmd))  error("The 'now' (T) option is mandatory")  end
	cmd = add_opt(d, cmd, "E", [:E :knots],
		(symbol=("s", nothing, 1), text=("t", nothing, 1), shift_startEnd = "+o", shift_start="+O", raise="+r", plateau="+p", decay="+d", fade="+f", text_duration="+l"))
	cmd = add_opt(d, cmd, "M", [:M :rise],
		(intensity=("i", arg2str, 1), size=("s", arg2str, 1), transparency=("t", arg2str, 1), coda="+c"))
	cmd = add_opt(d, cmd, "L", [:L :duration])
	cmd = add_opt(d, cmd, "Q", [:Q :save])
	cmd = add_opt(d, cmd, "D", [:D :offset],
		(away=("j", nothing, 1), corners=("J", nothing, 1), shift="", line=("+v",add_opt_pen)))
	cmd = add_opt(d, cmd, "F", [:F :attrib],
		(angle="+a", Angle="+A", font=("+f", font), justify="+j", region_justify="+c", header="_+h", label="_+l", rec_number="+r", text="+t", zvalues="+z"), false)
	common_plot_xyz(cmd0, arg1, "events|" * cmd, true, false, d...)
end
const psevents = events            # Alias

# ------------------------------------------------------------------------------------------------------
cat_1_arg(arg::GMTdataset) = return arg				# Miserable attempts to force type stability
cat_1_arg(arg::Vector{<:GMTdataset}) = return arg
function cat_1_arg(arg)
	# Add a first column with 1:n to all args that are not GMTdatasets
	if (isa(arg, Vector) || typeof(arg) <: AbstractRange)
		arg = hcat(collect(eltype(arg), 1:size(arg,1)), arg)
	#elseif (isa(arg, Array) && size(arg,1) == 1)		# Accept also row arrays. CAN'T IT BREAKS plot([1 1])
		#arg = hcat(collect(eltype(arg), 1:length(arg)), arg')
	elseif (isa(arg, NTuple))
		arg = hcat(collect(eltype(arg), 1:length(arg)), collect(arg))
	end
	return arg
end

# ------------------------------------------------------------------------------------------------------
function cat_2_arg2(arg1, arg2)
	# Cat two vectors (or tuples) or a vector (or tuple) and a matrix in a Mx2 matrix

	arg2 === nothing && return arg1
	isa(arg1, Real) && isa(arg2, Real) && return [arg1 arg2]
	!((isa(arg1, Vector) || typeof(arg1) <: AbstractRange || isa(arg1, NTuple) || isa(arg1, Matrix)) && (isa(arg2, Vector) || typeof(arg2) <: AbstractRange || isa(arg2, NTuple) || isa(arg2, Matrix)) ) &&
		error("Unknown types ($(typeof(arg1))) and ($(typeof(arg2))) in cat_2_arg2() function")

	if (isa(arg1, NTuple))  arg1 = collect(arg1)  end
	if (isa(arg2, NTuple))  arg2 = collect(arg2)  end
	if (size(arg1,1) == 1 && size(arg1,2) != 1)  arg1 = arg1[:]  end
	if (size(arg2,1) == 1 && size(arg2,2) != 1)  arg2 = arg2[:]  end
	arg = hcat(arg1, arg2)
	if (size(arg,2) > 2)  global multi_col[1] = true  end
	return arg
end
function cat_2_arg2(arg1::GMTdataset, arg2::VMr)::GMTdataset
	_arg = (isvector(arg2) && isa(arg2, Matrix)) ? vec(arg2) : arg2		# Converts a one line matrix into a vec
	arg1.data = hcat(arg1.data, _arg)		# Will error if sizes not compatible
	append!(arg1.colnames, ["Z$i" for i=length(arg1.colnames)+1:size(arg1,2)])
	set_dsBB!(arg1)							# Update BB
	return arg1
end
function cat_2_arg2(arg1::VMr, arg2::GMTdataset)::Matrix{<:Real}
	_arg = (isvector(arg1) && isa(arg1, Matrix)) ? vec(arg1) : arg1		# Converts a one line matrix into a vec
	_arg = hcat(_arg, arg2.data)			# Will error if sizes not compatible
	return _arg
end
function cat_2_arg2(arg1::GMTdataset, arg2::GMTdataset)::GMTdataset
	arg1.data = hcat(arg1.data, arg2.data)	# Will error if sizes not compatible
	append!(arg1.colnames, ["Z$i" for i=length(arg1.colnames)+1:size(arg1,2)])
	set_dsBB!(arg1)							# Update BB
	return arg1
end

# ------------------------------------------------------------------------------------------------------
cat_3_arg2(arg1::VMr, arg2, arg3)::Matrix{<:Real} = cat_2_arg2(arg1, cat_2_arg2(arg2, arg3))
cat_3_arg2(arg1::GMTdataset, arg2, arg3)::GMTdataset = cat_2_arg2(arg1, cat_2_arg2(arg2, arg3))

# ------------------------------------------------------------------------------------------------------
function gen_coords4funs(rang=nothing, axis="x"; kw...)
	# Generate axes coordenates to use when plot functions
	# If rang === nothing we must either have a two elements x|ylim in kw or otherwise default to (-5,5)
	# When rang is a scalar we return linspace(-rang, rang, 200)

	if (rang === nothing)
		symb = (axis == "x") ? [:xlim] : [:ylim]
		if ((val = find_in_dict(KW(kw), symb)[1]) !== nothing)
			(!isa(val, Tuple) && !isa(val, Array{<:Real})) && error("$(string(symb[1])) must be a tuple or array, not '$(typeof(val))'")
			(length(val) != 2) && error("$(string(symb[1])) must have 2 elements")
			rang = linspace(val[1], val[2], 200)
		else
			rang = linspace(-5, 5, 200)
		end
	elseif (isa(rang, Real))
		rang = linspace(-rang, rang, 200)
	elseif (length(rang) == 2 && eltype(rang) <: Real)
		rang = linspace(rang[1], rang[2], 200)
	end
	return rang
end

# ------------------------------------------------------------------------------------------------------
# Common code shared by the functions that accept parametric equations
function help_parametric_2f(f1::Function, f2::Function, range_t=nothing; is3D=true, kw...)
	# This function is shared by both the 2D & 3D cases
	t = collect(gen_coords4funs(range_t, "x"; kw...));
	x = [f1(x) for x in t];		y = [f2(y) for y in t]
	out = (is3D) ? hcat(x[:], y[:], t[:]) : hcat(x[:], y[:])
	return out
end

function help_parametric_3f(f1::Function, f2::Function, f3::Function, range_t=nothing; kw...)
	t = collect(gen_coords4funs(range_t, "x"; kw...));
	x = [f1(x) for x in t];		y = [f2(y) for y in t];		z = [f3(z) for z in t]
	return hcat(x[:], y[:], z[:])
end
# ------------------------------------------------------------------------------------------------------
