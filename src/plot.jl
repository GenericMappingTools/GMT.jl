"""
    plot(arg1::Array; kwargs...)

reads (x,y) pairs from files [or standard input] and generates PostScript code that will plot lines,
polygons, or symbols at those locations on a map.

Full option list at [`psxy`]($(GMTdoc)plot.html)

Parameters
----------

- **A** | **steps** | **straight_lines** :: [Type => Str] 

	By default, geographic line segments are drawn as great circle arcs.
	To draw them as straight lines, use this option.
    ($(GMTdoc)plot.html#a)
- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **D** | **shift** | **offset** :: [Type => Str]

    Offset the plot symbol or line locations by the given amounts dx/dy.
    ($(GMTdoc)plot.html#d)
- **E** | **error** | **error_bars** :: [Type => Str]

    Draw symmetrical error bars.
    ($(GMTdoc)plot.html#e)
- **F** | **conn** | **connection** :: [Type => Str]

    Alter the way points are connected
    ($(GMTdoc)plot.html#f)
- **G** | **fill** | **markerfacecolor** | **MarkerFaceColor** | **mc** :: [Type => Str]

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

- **W** | **pen** | **markeredgecolor** :: [Type => Str]

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

- **axis** | **aspect** :: [Type => Str]

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
plot3d(arg1::Array; kwargs...)

reads (x,y,z) triplets from files [or standard input] and generates PostScript code that will plot lines,
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
- **G** | **fill** | **markerfacecolor** | **MarkerFaceColor** :: [Type => Str]

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
- **W** | **pen** | **line_attribs** | **markeredgecolor** | **MarkerEdgeColor** :: [Type => Str]
    Set pen attributes for lines or the outline of symbols
    ($(GMTdoc)plot3d.html#w)
    WARNING: the pen attributes will set the pen of polygons OR symbols but not the two together.
    If your plot has polygons and symbols, use **W** or **line_attribs** for the polygons and
    **markeredgecolor** or **MarkerEdgeColor** for filling the symbols. Similar to S above.
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
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

Example:

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
- **W** | **pen** | **markeredgecolor** :: [Type => Str]

    Set pen attributes for lines or the outline of symbols
    ($(GMTdoc)plot.html#w)

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

scatter3(arg; kw...)  = common_plot_xyz("", cat_1_arg(arg), "scatte3", true, false, kw...)
scatter3!(arg; kw...) = common_plot_xyz("", cat_1_arg(arg), "scatte3", false, false, kw...)

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
			arg1 = gmtread(cmd0, dataset=true);		arg1 = arg1[1]
		else
			error("BAR3: When first arg is a name, must also state its type. e.g. grd=true or dataset=true")
		end
	end

	opt_base = add_opt(d, "", "", [:base])	# No need to purge because base is not a psxy option

	if (isa(arg1, GMTgrid))
		if (haskey(d, :bar))
			opt_S = parse_bar_cmd(d, :bar, "", "So")
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
		arg1 = gmt("grd2xyz", arg1)[1]			# Now arg1 is a GMTdataset
	else
		opt_S = parse_inc(d, "", [:S :width], "So", true)
		if (opt_S == "")
			opt_S = parse_bar_cmd(d, :bar, "", "So", true)
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

Example:

	arrows([0 8.2 0 6], limits=(-2,4,0,9), arrow=(len=2,stop=1,shape=0.5,fill=:red), axis=:a, pen="6p", show=true)
"""
function arrows(cmd0::String="", arg1=nothing; first=true, kwargs...)
	# A arrows plotting method of plot

	d = KW(kwargs)
	cmd = helper_arrows(d, true)	# Have to delete to avoid double parsing in -W
	if (cmd == "")  cmd = " -Sv0.5+e+h0.5"	# Minimalist defaults
	else            cmd = " -S" * cmd
	end

	GMT.common_plot_xyz(cmd0, arg1, cmd, first, false, d...)
end

function helper_arrows(d::Dict, del::Bool=true)
	# Helper function to set the vector head attributes
	cmd = ""
	val, symb = find_in_dict(d, [:arrow :vector :arrow4 :vector4 :vecmap :geovec :geovector], del)
	if (val !== nothing)
		code = 'v'
		if (symb == :geovec || symb == :geovector)
			code = '='
		elseif (symb == :vecmap)	# Uses azimuth and plots angles taking projection into account
			code = 'V'
		end
		if (isa(val, String))		# An hard core GMT string directly with options
			if (val[1] != code)    cmd = code * val
			else                   cmd = val		# The GMT string already had vector flag char
			end
		elseif (isa(val, Number))  cmd = code * "$val"
		elseif (symb == :arrow4 || symb == :vector4)  cmd = code * vector4_attrib(val)
		else                       cmd = code * vector_attrib(val)
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

Examples:

    lines([0, 10]; [0, 20], limits=(-2,12,-2,22), proj="M2.5", pen=1, fill=:red,
		  decorated=(dist=(val=1,size=0.25), symbol=:box), show=true)

    lines(x -> cos(x) * x, y -> sin(y) * y, linspace(0,2pi,100), region=(-4,7,-5.5,2.5), lw=2, lc=:sienna,
          decorated=(quoted=true, const_label=" In Vino Veritas  - In Aqua, Rãs & Toads", font=(25,"Times-Italic"),
                     curved=true, pen=(0.5,:red)), aspect=:equal, fmt=:png, show=true)
"""
function lines(cmd0::String="", arg1=nothing; first=true, kwargs...)
	# A lines plotting method of plot
	d = KW(kwargs)
	if ((val = find_in_dict(d, [:decorated])[1]) !== nothing)
		cmd = (isa(val, String)) ? val : decorated(val)
	else
		cmd = "lines"
	end

	common_plot_xyz(cmd0, arg1, cmd, first, false, d...)
end
lines!(cmd0::String="", arg=nothing; kw...) = lines(cmd0, arg; first=false, kw...)

function lines(f::Function, range_x=nothing; first=true, kw...)
	rang = gen_coords4funs(range_x, "x"; kw...)
	lines("", cat_2_arg2(rang, [f(x) for x in rang]); first=first, kw...)
end
lines!(f::Function, rang=nothing; kw...) = lines(f, rang; first=false, kw...)

function lines(f1::Function, f2::Function, range_t=nothing; first=true, kw...)	# Parametric version
	lines("", help_parametric_2f(f1, f2, range_t; is3D=false, kw...); first=first, kw...)
end
lines!(f1::Function, f2::Function, range_t=nothing; kw...) = lines(f1, f2, range_t; first=false, kw...)

lines(arg1, arg2; kw...)  = lines("", cat_2_arg2(arg1, arg2); first=true, kw...)
lines!(arg1, arg2; kw...) = lines("", cat_2_arg2(arg1, arg2); first=false, kw...)
lines(arg; kw...)  = lines("", cat_1_arg(arg); first=true, kw...)
lines!(arg; kw...) = lines("", cat_1_arg(arg); first=false, kw...)
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
	(arg1 === nothing && ((arg1 = find_in_dict(d, [:data])[1]) === nothing)) && error("No input data")
	if ((val = find_in_dict(d, [:decorated])[1]) !== nothing)
		cmd = (isa(val, String)) ? val : decorated(val)
	else
		cmd = "lines"
	end
	mat = ones(2, length(arg1))
	[mat[1,k] = mat[2,k] = arg1[k] for k = 1:length(arg1)]
	if ((opt_R = parse_R(d, "")[2]) != "")  x = vec(opt_R2num(opt_R)[1:2])
	else                                    x = [-1e50, 1e50];
	end
	D = mat2ds(mat, x=x, multi=true)

	common_plot_xyz("", D, cmd, first, false, d...)
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
	(arg1 === nothing && ((arg1 = find_in_dict(d, [:data])[1]) === nothing)) && error("No input data")
	if ((val = find_in_dict(d, [:decorated])[1]) !== nothing)
		cmd = (isa(val, String)) ? val : decorated(val)
	else
		cmd = "lines"
	end
	mat = ones(2, length(arg1))
	mat[1,:] = mat[2,:] = arg1
	if ((opt_R = parse_R(d, "")[2]) != "")  x = vec(opt_R2num(opt_R)[3:4])
	else                                    x = [-1e50, 1e50];
	end
	D = mat2ds(mat, x=x, multi=true)
	# Now we need tp swapp x / y columns because the vlines case is more complicated to implement.
	for k = 1:length(arg1)
		D[k].data[:,1], D[k].data[:,2] = D[k].data[:,2], D[k].data[:,1]
	end

	common_plot_xyz("", D, cmd, first, false, d...)
end
vlines!(arg=nothing; kw...) = vlines(arg; first=false, kw...)
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
function ternary(cmd0::String="", arg1=nothing; first=true, kwargs...)
	# A wrapper for psternary
	common_plot_xyz(cmd0, arg1, "ternary", first, false, kwargs...)
end
ternary!(cmd0::String="", arg1=nothing; kw...) = ternary(cmd0, arg1; first=false, kw...)
ternary(arg1;  kw...)  = ternary("", arg1; first=true, kw...)
ternary!(arg1; kw...)  = ternary("", arg1; first=false, kw...)
const psternary  = ternary            # Aliases
const psternary! = ternary!           # Aliases


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
- **W** | **pen** | **markeredgecolor** :: [Type => Str]

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
	cmd = add_opt(d, cmd, 'D', [:D :offset],
		(away=("j", nothing, 1), corners=("J", nothing, 1), shift="", line=("+v",add_opt_pen)))
	cmd = add_opt(d, cmd, 'F', [:F :attrib],
		(angle="+a", Angle="+A", font=("+f", font), justify="+j", region_justify="+c", header="_+h", label="_+l", rec_number="+r", text="+t", zvalues="+z"), false)
	common_plot_xyz(cmd0, arg1, "events|" * cmd, true, false, d...)
end
const psevents = events            # Alias

# ------------------------------------------------------------------------------------------------------
function cat_1_arg(arg)
	# Add a first column with 1:n to all args that are not GMTdatasets
	(isa(arg, Array{<:GMTdataset,1}) || isa(arg, GMTdataset))  &&  return arg
	if (isa(arg, Vector) || typeof(arg) <: AbstractRange)
		#arg = hcat(collect(1:size(arg,1)), arg)
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

# ------------------------------------------------------------------------------------------------------
function gen_coords4funs(rang=nothing, axis="x"; kw...)
	# Generate axes coordenates to use when plot functions

	if (rang === nothing)
		symb = (axis == "x") ? [:xlim] : [:ylim]
		if ((val = find_in_dict(KW(kw), symb)[1]) !== nothing)
		(!isa(val, Tuple) && !isa(val, Array{<:Real})) && error("$(string(symb[1])) must be a tuple or array, not '$(typeof(val))'")
			(length(val) != 2) && error("$(string(symb[1])) must have 2 elements")
			rang = linspace(val[1], val[2], 200)
		else
			rang = linspace(-5, 5)
		end
	elseif (isa(rang, Real))
		rang = linspace(-rang, rang)
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
