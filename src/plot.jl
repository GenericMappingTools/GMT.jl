"""
    plot(arg1::Array; kwargs...)

reads (x,y) pairs from files [or standard input] and generates PostScript code that will plot lines,
polygons, or symbols at those locations on a map.

See full GMT docs at [`psxy`]($(GMTdoc)plot.html)

Parameters
----------

- **A** | **steps** | **stairs** | **straight_lines** :: [Type => Str] 

	By default, geographic line segments are drawn as great circle arcs.
	To draw them as straight lines, use this option.
- $(_opt_J)
- $(_opt_R)
- $(_opt_B)
- $(opt_C)
- **D** | **shift** | **offset** :: [Type => Str]

    Offset the plot symbol or line locations by the given amounts dx/dy in cm, inch or points.
- **E** | **error** | **error_bars** :: [Type => Str]

    Draw symmetrical error bars.
- **F** | **conn** | **connection** :: [Type => Str]

    Alter the way points are connected
- **G** | **fill** | **markerfacecolor** | **MarkerFaceColor** | **markercolor** | **mc** :: [Type => Str]

    Select color or pattern for filling of symbols or polygons. BUT WARN: the alias 'fill' will set the
    color of polygons OR symbols but not the two together. If your plot has polygons and symbols, use
    'fill' for the polygons and 'markerfacecolor' for filling the symbols. Same applyies for W bellow
- **I** | **intens** :: [Type => Str | number]

    Use the supplied intens value (in the [-1 1] range) to modulate the fill color by simulating illumination.
- **L** | **close** | **polygon** :: [Type => Str]

    Force closed polygons. 
- **N** | **no_clip** | **noclip** :: [Type => Str or []]

    Do NOT clip symbols that fall outside map border 
- $(opt_P)
- **S** | **symbol** | **marker** | **Marker** :: [Type => Str]

    Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines). 
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
    WARNING: the pen attributes will set the pen of polygons OR symbols but not the two together.
    If your plot has polygons and symbols, use **W** or **pen** for the polygons and
    **markeredgecolor** for filling the symbols. Similar to S above.
- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)

- **Z** | **level** :: [Type => Str | NamedTuple]	`Arg = value|file[+f|+l] | (data=Array|Number, outline=_, fill=_)`

    Paint polygons after the level given as a cte or a vector with same size of number of polygons. Needs a color map.

- **aspect** :: [Type => Str]

    When equal to "equal" makes a square plot.
- $(opt_a)
- $(_opt_bi)
- $(_opt_di)
- $(opt_e)
- $(_opt_f)
- $(opt_g)
- $(_opt_h)
- $(_opt_i)
- $(_opt_p)
- $(_opt_t)
- $(opt_w)
- $(opt_swap_xy)
- $(opt_savefig)
"""
function plot(arg1; first=true, kw...)
	d = KW(kw)
	_plot(arg1, first==1, d)
end
function _plot(arg1, first::Bool, d::Dict{Symbol, Any})
	# First check if arg1 is a GMTds of a linear fit and if yes, call the plotlinefit() fun
	if (isa(arg1, GDtype) && is_in_dict(d, [:linefit :regress]; del=false) !== nothing)
		att = isa(arg1, GMTdataset) ? arg1.attrib : arg1[1].attrib
		(get(att, "linearfit", "") != "") && return plotlinefit(arg1; first=first, d...)
		# If it didn't return above, see if we have a 'groupvar' request and if yes perform regression on grouops
		arg1 = with_xyvar(d, arg1)		# But first check if we have a column selection
		gidx, gnames = get_group_indices(d, arg1)
		cycle_colors = (numel(gidx) <= 7) ? matlab_cycle_colors : simple_distinct	# Will blow if > 20
		if (!isempty(gidx))
			Dv = Vector{GMTdataset{Float64,2}}(undef, length(gidx))
			for k = 1:numel(gidx)
				Dv[k] = linearfitxy(mat2ds(arg1, (gidx[k], :)))
				Dv[k].header = "-G"*cycle_colors[k] * " -W"*cycle_colors[k]
				Dv[k].attrib["group_name"] = string(gnames[k])::String
			end
			Dv[1].ds_bbox = arg1.ds_bbox
			return plotlinefit(Dv; first=first, d...)
		end
	end
	common_plot_xyz("", Tables.istable(arg1) ? arg1 : cat_1_arg(arg1, true), "plot", first, false, d)
end
plot!(arg1; kw...) = plot(arg1; first=false, kw...)

function plot(f::Function, range_x=nothing; first=true, kw...)
	rang = gen_coords4funs(range_x, "x"; kw...)
	common_plot_xyz("", cat_2_arg2(rang, [f(x) for x in rang], true), "plot", first, false; kw...)
end
plot!(f::Function, rang=nothing; kw...) = plot(f, rang; first=false, kw...)

function plot(f1::Function, f2::Function, range_t=nothing; first=true, kw...)	# Parametric version
	common_plot_xyz("", mat2ds(help_parametric_2f(f1, f2, range_t; is3D=false, kw...)), "plot", first, false; kw...)
end
plot!(f1::Function, f2::Function, range_t=nothing; kw...) = plot(f1, f2, range_t; first=false, kw...)

plot(cmd0::String="", arg1=nothing; kw...)  = common_plot_xyz(cmd0, mat2ds(arg1), "plot", true, false; kw...)
plot!(cmd0::String="", arg1=nothing; kw...) = common_plot_xyz(cmd0, mat2ds(arg1), "plot", false, false; kw...)
plot(arg1, arg2; kw...)  = common_plot_xyz("", cat_2_arg2(arg1, arg2, true), "plot", true, false; kw...)
plot!(arg1, arg2; kw...) = common_plot_xyz("", cat_2_arg2(arg1, arg2, true), "plot", false, false; kw...)
plot(arg1::Number, arg2::Number; kw...)  = common_plot_xyz("", cat_2_arg2([arg1], [arg2], true), "plot", true, false; kw...)
plot!(arg1::Number, arg2::Number; kw...) = common_plot_xyz("", cat_2_arg2([arg1], [arg2], true), "plot", false, false; kw...)
# ------------------------------------------------------------------------------------------------------


"""
plotyy(arg1, arg2; kwargs...)

Example:
```julia
plotyy([1 1; 2 2], [1.5 1.5; 3 3], R="0.8/3/0/5", title="Ai", ylabel=:Bla, xlabel=:Ble, seclabel=:Bli, show=true)
```
"""
function plotyy(arg1, arg2; first=true, kw...)
	d = KW(kw)
	(haskey(d, :xlabel)) ? (xlabel = string(d[:xlabel])::String;	delete!(d, :xlabel)) : xlabel = ""	# Only to used at the end
	(haskey(d, :seclabel)) ? (seclabel = string(d[:seclabel])::String;	delete!(d, :seclabel)) : seclabel = ""
	fmt::String = ((val = find_in_dict(d, [:fmt])[1]) !== nothing) ? arg2str(val)::String : FMT[]::String
	savefig = ((val = find_in_dict(d, [:savefig :figname :name])[1]) !== nothing) ? arg2str(val)::String : nothing
	Vd = ((val = find_in_dict(d, [:Vd])[1]) !== nothing) ? val : 0

	xaxis = find_in_dict(d, [:xaxis])[1];		xaxis2 = find_in_dict(d, [:xaxis2])[1]	# These are only for -Bx
	opt_B::String = parse_B(d, "", " -Baf -BW")[1]		# This would not ignore :xaxis and :xaxis2 but that would screw WE axes
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
	lw = get(d, :lw, nothing)
	d[:lc] = "#0072BD"
	do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)
	in_conf = get(d, :conf, nothing)	# If there is a incomming one, save it to apply also to the xaxis (Date/time axis do that)
	d[:par] = (MAP_FRAME_PEN="#0072BD", MAP_TICK_PEN="#0072BD", FONT_ANNOT_PRIMARY="#0072BD", FONT_LABEL="#0072BD")
	r1 = common_plot_xyz("", cat_1_arg(arg1, true), "plotyy", first, false, d)

	(Vd != 0) && (d[:Vd] = Vd)
	(seclabel != "" && occursin(" ", seclabel)) && (seclabel = "\"" * seclabel * "\"")
	(seclabel != "") && (seclabel = " y+l" * seclabel)
	d[:B] = " af E"	* seclabel		# Also remember that previous -B was consumed in first call
	d[:lc]  = "#D95319"
	d[:par] = (MAP_FRAME_PEN="#D95319", MAP_TICK_PEN="#D95319", FONT_ANNOT_PRIMARY="#D95319", FONT_LABEL="#D95319")
	(lw !== nothing) && (d[:lw] = lw)
	r2 = common_plot_xyz("", cat_1_arg(arg2, true), "plotyy", false, false, d)

	(xlabel != "" && occursin(" ", xlabel)) && (xlabel = "\"" * xlabel * "\"")
	opt_B = (xlabel != "") ? "af Sn x+l" * xlabel : "af Sn"
	(xaxis  !== nothing) && (dd = Dict{Symbol,Any}(:xaxis  => xaxis);  opt_B = parse_B(dd, opt_B, "")[1])
	(xaxis2 !== nothing) && (dd = Dict{Symbol,Any}(:xaxis2 => xaxis2); opt_B = parse_B(dd, opt_B, "")[1])
	opt_f = isa(arg1, GMTdataset) ? set_fT(arg1, "", "") : ""		# See if Timecol is present and set -f0T if yes
	_f = (opt_f !== "") ? opt_f[4:end] : ""
	r3 = basemap!(J="", B=opt_B, conf=in_conf, f=_f,  Vd=Vd, fmt=fmt, name=savefig, show=do_show)
	return (Vd == 2) ? [r1;r2;r3] : nothing
end
# ------------------------------------------------------------------------------------------------------

"""
plot3d(arg1::Array; kwargs...)

reads (x,y,z) triplets and generates PostScript code that will plot lines,
polygons, or symbols at those locations in 3-D.

See full GMT docs at [`plot3d`]($(GMTdoc)plot3d.html)

Parameters
----------

- **A** | **steps** | **straight_lines** :: [Type => Str]  

    By default, geographic line segments are drawn as great circle arcs. To draw them as straight lines, use this option.
- $(_opt_J)
- $(opt_Jz)
- $(_opt_R)
- $(_opt_B)
- **C** | **color** :: [Type => Str]

    Give a CPT or specify -Ccolor1,color2[,color3,...] to build a linear continuous CPT from those colors automatically.
- **D** | **offset** :: [Type => Str]

    Offset the plot symbol or line locations by the given amounts dx/dy.
- **E** | **error_bars** :: [Type => Str]

    Draw symmetrical error bars.
- **F** | **conn** | **connection** :: [Type => Str]

    Alter the way points are connected
- **G** | **fill** | **markerfacecolor** | **MarkerFaceColor** | **markercolor** | **mc** :: [Type => Str]

    Select color or pattern for filling of symbols or polygons. BUT WARN: the alias 'fill' will set the
    color of polygons OR symbols but not the two together. If your plot has polygons and symbols, use
    'fill' for the polygons and 'markerfacecolor' for filling the symbols. Same applyies for W bellow
- **I** | **intens** :: [Type => Str or number]

    Use the supplied intens value (in the [-1 1] range) to modulate the fill color by simulating illumination.
- **L** | **closed_polygon** :: [Type => Str]

    Force closed polygons. 
- **N** | **no_clip** :: [Type => Str | []]

    Do NOT clip symbols that fall outside map border 
- $(opt_P)
- **S** | **symbol** | **marker** | **Marker** :: [Type => Str]

    Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines). 
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
    WARNING: the pen attributes will set the pen of polygons OR symbols but not the two together.
    If your plot has polygons and symbols, use **W** or **line_attribs** for the polygons and
    **markeredgecolor** or **MarkerEdgeColor** for filling the symbols. Similar to S above.
- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)

- **Z** | **level** :: [Type => Str | NamedTuple]	`Arg = value|file[+f|+l] | (data=Array|Number, outline=_, fill=_)`

    Paint polygons after the level given as a cte or a vector with same size of number of polygons. Needs a color map.
- $(opt_a)
- $(_opt_bi)
- $(_opt_di)
- $(opt_e)
- $(_opt_f)
- $(opt_g)
- $(_opt_h)
- $(_opt_i)
- $(_opt_p)
- $(_opt_t)
- $(opt_w)
- $(opt_savefig)

### Example:

    plot3d(x -> sin(x)*cos(10x), y -> sin(y)*sin(10y), z -> cos(z), 0:pi/100:pi, show=true, aspect3=:equal)
"""
plot3d(arg1; kw...)  = common_plot_xyz("", cat_1_arg(arg1, true), "plot3d", true, true; kw...)
plot3d!(arg1; kw...) = common_plot_xyz("", cat_1_arg(arg1, true), "plot3d", false, true; kw...)

plot3d(cmd0::String="", arg1=nothing; kw...)  = common_plot_xyz(cmd0, mat2ds(arg1), "plot3d", true, true; kw...)
plot3d!(cmd0::String="", arg1=nothing; kw...) = common_plot_xyz(cmd0, mat2ds(arg1), "plot3d", false, true; kw...)

# ------------------------------------------------------------------------------------------------------
function plot3d(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; first=true, kw...)
	common_plot_xyz("", mat2ds(hcat(arg1[:], arg2[:], arg3[:])), "plot3d", first, true; kw...)
end
plot3d!(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; kw...) = plot3d(arg1, arg2, arg3; first=false, kw...)

function plot3d(f1::Function, f2::Function, range_t=nothing; first=true, kw...)
	common_plot_xyz("", mat2ds(help_parametric_2f(f1, f2, range_t; kw...)), "plot3d", first, true; kw...)
end
plot3d!(f1::Function, f2::Function, range_t=nothing; kw...) = plot3d(f1, f2, range_t; first=false, kw...)

function plot3d(f1::Function, f2::Function, f3::Function, range_t=nothing; first=true, kw...)
	common_plot_xyz("", mat2ds(help_parametric_3f(f1, f2, f3, range_t; kw...)), "plot3d", first, true; kw...)
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
- **N** | **noclip** | **no_clip** :: [Type => Str | []]

    Do NOT clip symbols that fall outside map border 
- $(opt_P)
- **S** :: [Type => Str]

    Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines). 

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
	
    and select their sizes with the `markersize` or `size` keyword [default is 8p].
    The marker size can be a scalar or a vector with same size numeber of rows of data. Units are
    points unless specified otherwise with (for example for cm) *par=(PROJ_LENGTH_UNIT=:c,)*	
- **W** | **pen** | **markeredgecolor** | **mec** :: [Type => Str]

    Set pen attributes for lines or the outline of symbols
- $(opt_savefig)
"""
function scatter(f::Function, range_x=nothing; first=true, kw...)
	rang = gen_coords4funs(range_x, "x"; kw...)
	common_plot_xyz("", cat_2_arg2(rang, [f(x) for x in rang], true), "scatter",  first, false; kw...)
end
scatter!(f::Function, rang=nothing; kw...) = scatter(f, rang; first=false, kw...)

function scatter(f1::Function, f2::Function, range_t=nothing; first=true, kw...)	# Parametric version
	common_plot_xyz("", mat2ds(help_parametric_2f(f1, f2, range_t; is3D=false, kw...)), "scatter",  first, false; kw...)
end
scatter!(f1::Function, f2::Function, range_t=nothing; kw...) = scatter(f1, f2, range_t; first=false, kw...)

scatter(cmd0::String="",  arg1=nothing; kw...) = common_plot_xyz(cmd0, mat2ds(arg1), "scatter",  true, false; kw...)
scatter!(cmd0::String="", arg1=nothing; kw...) = common_plot_xyz(cmd0, mat2ds(arg1), "scatter",  false, false; kw...)

scatter(arg; kw...)  = common_plot_xyz("", cat_1_arg(arg, true), "scatter", true, false; kw...)
scatter!(arg; kw...) = common_plot_xyz("", cat_1_arg(arg, true), "scatter", false, false; kw...)

scatter(arg1, arg2; kw...)  = common_plot_xyz("", cat_2_arg2(arg1, arg2, true), "scatter", true, false; kw...)
scatter!(arg1, arg2; kw...) = common_plot_xyz("", cat_2_arg2(arg1, arg2, true), "scatter", false, false; kw...)

bubblechart  = scatter		# Alias that supposedly only plots circles
bubblechart! = scatter!

function scatter(D::Vector{<:GMTdataset{Float64,2}}; first=true, kw...)
	d = KW(kw)
	labels = String[]
	if ((s_val = hlp_desnany_str(d, [:labels], false)) !== "")
		ts = fish_attrib_in_str(s_val)
		labels = [D[k].attrib[ts] for k = 1:length(D)]
	end
	Dc = mat2ds(gmt_centroid_area(G_API[], D, Int(isgeog(D)), ca=2), geom=wkbPoint, text=labels)
	(is_in_dict(d, [:marker, :Marker, :shape]) === nothing) && (d[:marker] = "circ")
	(is_in_dict(d, [:ms :markersize :MarkerSize :size]) === nothing) && (d[:ms] = "12p")
	_common_plot_xyz("", Dc, "bubble", !first, true, false, d)
end

# ------------------------------------------------------------------------------------------------------
scatter3(cmd0::String="", arg1=nothing; kw...)  = common_plot_xyz(cmd0, mat2ds(arg1), "scatter3",  true, true; kw...)
scatter3!(cmd0::String="", arg1=nothing; kw...) = common_plot_xyz(cmd0, mat2ds(arg1), "scatter3",  false, true; kw...)

scatter3(arg; kw...)  = common_plot_xyz("", cat_1_arg(arg, true), "scatter3", true, true; kw...)
scatter3!(arg; kw...) = common_plot_xyz("", cat_1_arg(arg, true), "scatter3", false, true; kw...)

function scatter3(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; kw...)
	common_plot_xyz("", mat2ds(hcat(arg1, arg2, arg3)), "scatter3", true, true; kw...)
end
function scatter3!(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; kw...)
	common_plot_xyz("", mat2ds(hcat(arg1, arg2, arg3)), "scatter3", false, true; kw...)
end

function scatter3(f1::Function, f2::Function, range_t=nothing; first=true, kw...)
	common_plot_xyz("", mat2ds(help_parametric_2f(f1, f2, range_t; kw...)), "scatter3", first, true; kw...)
end
scatter3!(f1::Function, f2::Function, range_t=nothing; kw...) = scatter3(f1, f2, range_t; first=false, kw...)

function scatter3(f1::Function, f2::Function, f3::Function, range_t=nothing; first=true, kw...)
	common_plot_xyz("", mat2ds(help_parametric_3f(f1, f2, f3, range_t; kw...)), "scatter3", first, true; kw...)
end
scatter3!(f1::Function, f2::Function, f3::Function, range_t=nothing; kw...) = scatter3(f1, f2, f3, range_t; first=false, kw...)

const scatter3d  = scatter3			# Alias
const scatter3d! = scatter3!
# ------------------------------------------------------------------------------------------------------


"""
    bar(cmd0::String="", arg1=nothing; kwargs...)

Reads a file or (x,y) pairs and plots vertical bars extending from base to y.

- $(_opt_J)
- $(_opt_R)
- $(_opt_B)
- **fill** :: [Type => Str --

    Select color or pattern for filling the bars
- **base** | **bottom** :: [Type => Str | Num]		``key=value``

    By default, base = ymin. Use this option to change that value. If base is not appended then we read it.
    from the last input data column.
- **size** | **width** :: [Type => Str | Num]		``key=value``

    The size or width is the bar width. Append u if size is in x-units. When *width* is used the default is plot-distance units.
- $(opt_savefig)

Example:

    bar(sort(randn(10)), fill=:black, axis=:auto, show=true)
"""
function bar(cmd0::String="", arg=nothing; first=true, kw...)
	d = KW(kw)
	(cmd0 != "" && arg === nothing) && (arg = gmtread(cmd0))
	isa(arg, GMTdataset) && (arg::Matrix{<:Float64} = arg.data)
	isa(arg, Vector{<:GMTdataset}) && (arg = arg[1].data; @warn("Multi-segments not allowed in 'bar'. Keeping only first segment."))
	invokelatest(_bar, arg, first, d)
end
function _bar(arg, first::Bool, d::Dict{Symbol,Any})

	do_cat = ((haskey(d, :stack) || haskey(d, :stacked)) && isvector(arg) && length(arg) > 2) ? false : true
	is_waterfall = ((val = hlp_desnany_str(d, [:stack :stacked], false)) !== "" && startswith(val, "water"))
	if (is_waterfall)
		isa(arg, Vector) && (arg = reshape(arg, 1, length(arg)))		# Waterfall stacks must be matrices
		(arg[1] != 0) && (arg = hcat(repeat([1.0],size(arg,1)), arg))	# If first el != 0 assume coord is missing
		do_cat = false
	elseif (haskey(d, :xticks))
		arg = hcat(1:size(arg,1), arg)
		do_cat = false
	end

	if (do_cat) arg = Float64.(cat_1_arg(arg))  end		# If ARG is a vector, prepend it with a 1:N x column
	common_plot_xyz("", mat2ds(arg), "bar", first, false, d)
end
bar!(cmd0::String="", arg=nothing; kw...) = bar(cmd0, arg; first=false, kw...)

function bar(f::Function, range_x=nothing; first=true, kw...)
	rang = gen_coords4funs(range_x, "x"; kw...)
	bar("", cat_2_arg2(rang, [f(x) for x in rang]); first=first, kw...)
end
bar!(f::Function, rang=nothing; kw...) = bar(f, rang; first=false, kw...)

bar(arg1, arg2; first=true, kw...)  = common_plot_xyz("", cat_2_arg2(arg1, Float64.(arg2), true), "bar", first, false; kw...)
bar!(arg1, arg2; kw...) = common_plot_xyz("", cat_2_arg2(arg1, Float64.(arg2), true), "bar", false, false; kw...)
bar(arg; kw...)  = bar("", arg; kw...)
bar!(arg; kw...) = common_plot_xyz("", cat_1_arg(arg, true), "bar", false, false; kw...)
# ------------------------------------------------------------------------------------------------------

"""
    bar3(cmd0::String="", arg1=nothing; kwargs...)

Read a grid file, a grid or a MxN matrix and plots vertical bars extending from base to z.

- $(_opt_J)
- $(_opt_R)
- $(_opt_B)
- **fill** :: [Type => Str]		``key=color``

    Select color or pattern for filling the bars
- **base** :: [Type => Str | Num]		``key=value``

    By default, base = ymin. Use this option to change that value. If base is not appended then we read it.
- $(_opt_p)
- $(opt_savefig)

Example:

    G = gmt("grdmath -R-15/15/-15/15 -I0.5 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
    bar3(G, lw=:thinnest, show=true)
"""
function bar3(cmd0::String="", arg=nothing; first=true, kwargs...)
	# Contrary to "bar" this one has specific work to do here.
	d = KW(kwargs)
	opt_z::String = ""

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
	opt_R = ""

	if (isa(arg1, GMTgrid))
		if (haskey(d, :bar))
			opt_S::String = parse_bar_cmd(d, :bar, "", "So")[1]
		else
			# 0.85 is the % of inc width of bars
			w1::Float64, w2::Float64 = arg1.inc[1]*0.85, arg1.inc[2]*0.85
			opt_S = " -So$(w1)u/$(w2)u"
			if     (haskey(d, :nbands))  opt_z = string("+z", d[:nbands]);	delete!(d, :nbands)
			elseif (haskey(d, :Nbands))  opt_z = string("+Z", d[:Nbands]);	delete!(d, :Nbands)
			end
		end
		opt_R, = parse_R(d, "", O=!first)
		if (opt_R == "" || opt_R == " -R")			# OK, no R but we know it here so put it in 'd'
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
			t = split(opt_R, '/')
			(length(t) == 6) ? z_min = t[5] : error("For 3D cases, region must have 6 selements")
		end
		(opt_base == "") ? push!(d, :base => 0)	: push!(d, :base => opt_base) 
		arg1 = gmt("grd2xyz", arg1)				# Now arg1 is a GMTdataset
	else
		opt_S = parse_I(d, "", [:S :width], "So", true)
		if (opt_S == "")
			opt_S = parse_bar_cmd(d, :bar, "", "So"; no_u=true)[1]
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

	opt_base::String = add_opt(d, "", "", [:base])		# Do this again because :base may have been added above
	if (opt_base == "")
		_z_min::Float32 = (isa(arg1, Array)) ? minimum(view(arg1, :, 3)) : minimum(view(arg1.data, :, 3))
		opt_S *= "+b$_z_min" 
	else
		opt_S *= "+b" * opt_base
	end

	(opt_R != "") && (d[:R] = opt_R[4:end])
	common_plot_xyz("", mat2ds(arg1), "bar3|" * opt_S * opt_z, first, true, d)
end

bar3(arg1; kw...) = bar3("", arg1; first=true, kw...)
bar3!(cmd0::String="", arg1=nothing; kw...) = bar3(cmd0, arg1; first=false, kw...)
bar3!(arg1; kw...) = bar3("", arg1; first=false, kw...)
# ------------------------------------------------------------------------------------------------------

"""
    lines(cmd0::String="", arg1=nothing; decorated=(...), kwargs...)

Read a file or (x,y) pairs and plot a collection of different line with decorations

- $(_opt_B)
- $(_opt_J)
- $(_opt_R)
- **W** | **pen** | **line_attrib** :: [Type => Str]

    Set pen attributes for lines or the outline of symbols
- $(opt_savefig)

Examples:

    lines([0, 10]; [0, 20], limits=(-2,12,-2,22), proj="M2.5", pen=1, fill=:red,
		  decorated=(dist=(val=1,size=0.25), symbol=:box), show=true)

    lines(x -> cos(x) * x, y -> sin(y) * y, linspace(0,2pi,100), region=(-4,7,-5.5,2.5), lw=2, lc=:sienna,
          decorated=(quoted=true, const_label=" In Vino Veritas  - In Aqua, Rãs & Toads", font=(25,"Times-Italic"),
                     curved=true, pen=(0.5,:red)), aspect=:equal, fmt=:png, show=true)
"""
lines(cmd0::String="", arg1=nothing; first=true, kwargs...) = common_plot_xyz(cmd0, mat2ds(arg1), "lines", first, false; kwargs...)
lines!(cmd0::String="", arg1=nothing; kw...) = lines(cmd0, arg1; first=false, kw...)

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
lines(arg; kw...)  = lines("", cat_1_arg(arg, true); first=true, kw...)
lines!(arg; kw...) = lines("", cat_1_arg(arg, true); first=false, kw...)

# ------------------------------------------------------------------------------------------------------
# fill_between(D, fill="blue@70,brown@80", lt=1, ls=:dot, show=1)
# fill_between(D, fill="blue@70,brown@80", lt=1, ls=:dot, show=1)
# fill_between(D, lt=1, ls=:dot, lc=:green, show=1)
# fill_between([theta y1], [theta y2], legend=(labels=(:Aa,:Vv), pos=:TL, box=:none), show=1)
# fill_between([theta y1], [theta y2], white=true, show=1)
"""
    fill_between(D1 [,D2]; kwargs...)

Fill the area between two horizontal curves.

The curves are defined by the points (x, y1, y2) in matrix or GMTdataset `D1`. This creates one or
multiple polygons describing the filled area. Alternatively, give a second matrix, `D2` (or a scalar y=cte)
and the polygons are constructed from the intersections of curves `D1` and `D2`.

- `fill_between(..., fill=colors)`: Give a list with two colors to paint the 'up' and 'down' polygons.
- `fill_between(..., fillalpha=[alpha1,alpha2])`: Sets the transparency of the two sets of polygons (default 60%).
- `fill_between(..., pen=...)`: Sets pen specifications for the two curves. Easiest is to use the shortcuts
   `lt`, `lc` and `ls` for the line thickness, color and style like it is used in the `plot()` module.
- `fill_between(..., stairs=true)`: Plot stairs curves instead.
- `fill_between(..., markers=true)`: Add marker points at the data locations.
- `fill_between(..., white=true)`: Draw a thin white border between the curves and the fills.
- `fill_between(..., labels=...)`: Pass labels to use in a legend.
   - `labels=true` wil use the column names in `D1` and `D2`. 
   - `labels="Lab1,Lab2"` or `labels=["Lab1","Lab2"]` (this one can be a Tuple too) use the text in `Lab1`, `Lab2`.
- `fill_between(..., legend=...)`: If used as the above `labels` it behaves like wise, but its argument can
   also be a named tuple with `legend=(labels="Lab1,Lab2", position=poscode, box=(...))`.

Example:

    theta = linspace(-2π, 2π, 150);
    y1 = sin.(theta) ./ theta;
    y2 = sin.(2*theta) ./ theta;
    fill_between([theta y1], [theta y2], white=true, legend="Sinc1,Sinc2", show=1)
"""
fill_between(fname::String; first::Bool=true, kw...) = fill_between(gmtread(fname); first=first, kw...)
function fill_between(arg1, arg2=nothing; first=true, kwargs...)

	function find_the_pos(x, x_int)
		len_x = length(x)
		_ind = zeros(Int, length(x_int))
		n = 0
		for k = 1:numel(x_int)
			while(n < len_x && x[n+=1] < x_int[k]) end
			_ind[k] = n-1
		end
		return _ind
	end
	function fish_labels(bal, legs, one_array, D1, D2)
		# See if we have labels to use in legend or asked to use column names.
		if (isa(bal, Bool) && bal) legs = one_array ? [D1.colnames[2], D1.colnames[3]] : [D1.colnames[2], D2.colnames[2]]
		elseif (isempty(legs) && isa(bal, String) && contains(bal,",")) legs = [string.(split(bal,","))...]
		elseif (isempty(legs) && isa(bal, Tuple) || isa(bal, Array) && length(bal) > 1) legs = [string(bal[1]), string(bal[2])]
		end
		return legs
	end

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	fc = helper_ds_fill(d)						# Got fill colors?
	if (!isempty(fc))
		!any(contains.(fc, "@")) && (fc .*= "@60")			# If no transparency provided default to 60%
		(length(fc) == 1) && (append!(fc, ["white@100"]))	# May need two fill colors, so generalize it.
		fill_colors = fc
	else
		fill_colors = ["darkgreen@60", "darkred@60"]
	end

	# Deal with pen line specifications
	if ((lc = add_opt_pen(d, [:W, :pen])) != "")			# Actualy a lc, lt, ls but one cal only change lt and ls
		if !contains(lc, ",")				# Just a line thickness
			l_colors = [string(lc,",",split(fill_colors[1], "@")[1]), string(lc,",",split(fill_colors[2], "@")[1])]
		elseif (contains(lc ,",,"))			# A ,,ls or lt,,ls
			if (startswith(lc ,",,"))		# ,,ls
				l_colors = [string("0.5,",split(fill_colors[1], "@")[1], ",",lc[3:end]), string("0.5,",split(fill_colors[2], "@")[1], ",",lc[3:end])]
			else							# lt,,ls
				l_colors = [string(split(lc, ",")[1], ",", split(fill_colors[1], "@")[1], ",", split(lc,",")[3]), string(split(lc, ",")[1], ",", split(fill_colors[2], "@")[1], ",", split(lc,",")[3])]
			end
		elseif ((nc = count_chars(lc, ',')) != 0)
			if (nc == 1)					# must be a ,lc or a lt,lc
				if (lc[1] == ',')			# a ,lc
					l_colors = [lc, lc]
				else
					l_colors = [string(lc, ",", split(fill_colors[1], "@")[1]), string(lc, ",", split(fill_colors[2], "@")[1])]
				end
			else							# must be nc == 2 => lt,lc,ls.
				l_colors = [lc, lc]
			end
		end					# There should be no ELSE branch
	else
		l_colors = [string("0.5,",split(fill_colors[1], "@")[1]), string("0.5,",split(fill_colors[2], "@")[1])]
	end

	one_array = (arg2 === nothing)
	D1 = mat2ds(arg1)
	if (isa(arg2, Real))  D2 = mat2ds([D1.data[1] arg2; D1.data[end,1] arg2]); set_dsBB!(D2)	# 2nd line is y = arg2
	else                  D2 = (!one_array) ? mat2ds(arg2) : GMTdataset()
	end

	if (one_array)
		int = gmtspatial((D1[:,[1,2]], D1[:,[1,3]]), intersections=:e, sort=true)
		if (isempty(int))				# Hmm so lines do not cross. Just create the polygon and we are done.
			ff = (D1.ds_bbox[6] > D1.ds_bbox[4]) ? 2 : 1		# If second curve is above first, swapp fill color
			Dsd = mat2ds([D1[:,[1,2]]; D1[end:-1:1, [1:3]]], fill=fill_colors[ff])
			@goto no_crossings			# What a delicious relict from past
		end
		ind = find_the_pos(view(D1, :, 1), view(int, :, 1))		# Indices of the points before the intersections
		n_crossings = size(ind,1)
		Dsd = Vector{GMTdataset{Float64,2}}(undef, n_crossings+1)
		ff = (D1[1,2] < D1[1,3]) ? 2 : 1
		Dsd[1] = mat2ds([D1[1:ind[1], [1,2]]; int[1:1,1:2]; D1[ind[1]:-1:1, [1,3]]], fill=fill_colors[ff])
		for k = 2:n_crossings
			s, e = ind[k-1], ind[k]
			fillColor = (D1[ind[k]-1,2] >= D1[ind[k]-1,3]) ? fill_colors[1] : fill_colors[2]
			Dsd[k] = mat2ds([int[k-1:k-1,1:2]; D1[s:e, [1,2]]; int[k:k,1:2]; D1[e:-1:s, [1,3]]], fill=fillColor)
		end
		k = n_crossings
		s, e = ind[k], size(D1, 1)
		fillColor = (D1[end,2] >= D1[end,3]) ? fill_colors[1] : fill_colors[2]
		Dsd[n_crossings+1] = mat2ds([int[k:k,1:2]; D1[s:e, [1,2]]; D1[e:-1:s, [1,3]]], fill=fillColor)
	else
		int = gmtspatial((D1, D2), intersections=:e, sort=true)
		if (isempty(int))				# Hmm so lines do not cross. Just create the polygon and we are done.
			ff = (D2.ds_bbox[4] > D1.ds_bbox[4]) ? 2 : 1			# If second curve is above first, swapp fill color
			Dsd = mat2ds([D1.data; D2.data[end:-1:1, :]], fill=fill_colors[ff])
			@goto no_crossings			# What a delicious relict from past
		end
		ind1 = find_the_pos(view(D1, :, 1), view(int, :, 1))		# Indices of the points before the intersections at line 1
		ind2 = find_the_pos(view(D2, :, 1), view(int, :, 1))		# Indices of the points before the intersections at line 2
		n_crossings = size(int,1)
		Dsd = Vector{GMTdataset{Float64,2}}(undef, n_crossings+1)
		ff = (D1[1,2] < D2[1,2]) ? 2 : 1
		Dsd[1] = mat2ds([D1[1:ind1[1], [1,2]]; int[1:1,1:2]; D2[ind2[1]:-1:1, [1,2]]], fill=fill_colors[ff])
		for k = 2:n_crossings
			s1, e1, s2, e2 = ind1[k-1], ind1[k], ind2[k-1], ind2[k]
			fillColor = (D1[ind1[k]-1,2] >= D2[max(1,ind2[k]-1),2]) ? fill_colors[1] : fill_colors[2]
			Dsd[k] = mat2ds([int[k-1:k-1,1:2]; D1[s1:e1, [1,2]]; int[k:k,1:2]; D2[e2:-1:s2, [1,2]]], fill=fillColor)
		end
		k = n_crossings
		s1, e1, s2, e2 = ind1[k], size(D1, 1), ind2[k], size(D2, 1)
		fillColor = (D1[end,2] >= D2[end,2]) ? fill_colors[1] : fill_colors[2]
		Dsd[n_crossings+1] = mat2ds([int[k:k,1:2]; D1[s1:e1, [1,2]]; D2[e2:-1:s2, [1,2]]], fill=fillColor)
	end
	@label no_crossings
	set_dsBB!(Dsd)
	(get(D1.attrib, "Timecol", "") == "1") && (Dsd[1].attrib["Timecol"] = "1")	# Try to keep an eventual Timecol

	Vd = haskey(d, :Vd) ? d[:Vd] : -1
	do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)
	do_markers = ((val = find_in_dict(d, [:markers])[1]) !== nothing && val != 0)
	do_stairs = ((val = find_in_dict(d, [:stairs])[1]) !== nothing && val != 0)

	legs, lab_pos::String, lab_box = String[], "", nothing
	((val = find_in_dict(d, [:labels])[1]) !== nothing) && (legs = fish_labels(val, legs, one_array, D1, D2))
	if (isempty(legs) && (val = find_in_dict(d, [:leg :legend])[1]) !== nothing)	# OK, so this likely means a legend location
		legs = fish_labels(val, legs, one_array, D1, D2)
		if (isempty(legs) && isa(val, NamedTuple))		# Must break & complicate because here a setting applies to 2 lines
			dd = nt2dict(val)
			lab_pos = ((val = find_in_dict(dd, [:pos :position])[1]) !== nothing) ? string(val) : ""	# Legend position
			((val = find_in_dict(dd, [:label :labels])[1]) !== nothing) && (legs = fish_labels(val, legs, one_array, D1, D2))
			((val = find_in_dict(dd, [:box])[1]) !== nothing) && (lab_box = val)
		end
	end

	border = 0.0
	if (find_in_dict(d, [:white :witeborder])[1] !== nothing)
		_lt = break_pen(scan_opt(l_colors[1], "-W"))[1]
		border = (_lt == "") ? 1.5 : size_unit(_lt)+1.0
	end

	# ---------------------------------- Plot the patches ---------------------------------------
	do_stairs && (d[:A] = "y")
	common_plot_xyz("", Dsd, "", first, false, d)	# The patches
	do_stairs && (delete!(d, :A))
	delete!(d, [[:theme], [:figsize], [:frame], [:xaxis], [:yaxis]])	# To not repeat -B -J
	# -------------------------------------------------------------------------------------------

	_D2 = one_array ? mat2ds(D1, (:,[1,3])) : D2		# Put second line in a unique var

	if (border > 0)										# Plot a white border
		one_array ? common_plot_xyz("", [mat2ds(D1, (:,[1,2])), _D2], "lines", false, false, Dict(:W => "$(border),white", :Vd => Vd)) :
		            common_plot_xyz("", [D1, _D2], "lines", false, false, Dict(:W => "$(border),white", :Vd => Vd))
	end

	do_stairs && (d[:stairs_step] = :pre)
	d[:W], d[:Vd] = l_colors[1], Vd
	do_markers && (d[:marker] = :point; d[:mc] = string(split(fill_colors[1], "@")[1]))
	!isempty(legs) && (d[:legend] = legs[1])
	common_plot_xyz("", D1, "lines", false, false; d...)		# This d... must be. D cant be consumed at this point

	do_stairs && (d[:stairs_step] = :post)
	d[:W], d[:Vd] = l_colors[2], Vd
	do_markers && (d[:marker] = :point; d[:mc] = string(split(fill_colors[2], "@")[1]))
	!isempty(legs) && (d[:legend] = (lab_pos == "") ? legs[2] : (label=legs[2], pos=lab_pos, box=lab_box))
	d[:show] = do_show
	common_plot_xyz("", _D2, "lines", false, false, d)

	#=
	d[:marker] = "c"
	d[:ms] = "1p"
	d[:mc] = :black
	d[:Vd] = Vd
	d[:show] = do_show
	common_plot_xyz("", int, "", false, false, d)
	=#
end

fill_between!(arg1, arg2=nothing; kw...) = fill_between(arg1, arg2; first=false, kw...)

# ------------------------------------------------------------------------------------------------------
"""
    stairs(cmd0::String="", arg1=nothing; step=:post, kwargs...)

Plot a stair function. The `step` parameter can take the following values:

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
stairs!(cmd0::String="", arg1=nothing; step=:post, kw...) = stairs(cmd0, mat2ds(arg1); first=false, step=step, kw...)
stairs(arg; step=:post, kw...)  = stairs("", cat_1_arg(arg, true); step=step, kw...)
stairs!(arg; step=:post, kw...) = stairs("", cat_1_arg(arg, true); first=false, step=step, kw...)
stairs(arg1, arg2; step=:post, kw...)  = stairs("", cat_2_arg2(arg1, arg2, true); step=step, kw...)
stairs!(arg1, arg2; step=:post, kw...) = stairs("", cat_2_arg2(arg1, arg2, true); first=false, step=step, kw...)

# ------------------------------------------------------------------------------------------------------
function helper_input_ds(d::Dict, cmd0::String="", arg1=nothing)
	# Block common to some functions. Read the file if cmd0 != "" and takes care of "select by col"
	# if arg1 is a GMTdataset (or a vector of them). 
	(cmd0 != "") && (arg1 = read_data(d, cmd0, "", nothing, "", false, true)[2])
	isa(arg1, GMTdataset) && (arg1 = with_xyvar(d, arg1))	# It's not implemented for GMTdataset vectors
	#(isa(arg1, Matrix) && size(arg1,2) > 2 && find_in_dict(d, [:multicol])[1] !== nothing) && (arg1 = mat2ds(arg1, multi=true, color="yes"))
	(isa(arg1, GMTdataset) && size(arg1,2) > 2 && find_in_dict(d, [:multi :multicol])[1] !== nothing) && (arg1 = ds2ds(arg1, multi=true, fill=(haskey(d, :fill) ? d[:fill] : true)))
	haveVarFill = (haskey(d, :fill) && d[:fill] == true)		# Probably no longer true
	haveR = (find_in_dict(d, [:R :region :limits :region_llur :limits_llur :limits_diag :region_diag :xlim :xlims :xlimits], false)[1] !== nothing)
	return arg1, haveR, haveVarFill
end

# ------------------------------------------------------------------------------------------------------
"""
    stem(cmd0::String="", arg1=nothing; kwargs...)

Example:

    Y = linspace(-2*pi,2*pi,50);
	stem([Y Y], show=true)

	stem(Y,[Y -Y], multicol=true, fill=true, show=true)
"""
function stem(cmd0::String="", arg1=nothing; first=true, kwargs...)
	d = KW(kwargs)
	arg1, haveR, haveVarFill = helper_input_ds(d, cmd0, arg1)

	if (isGMTdataset(arg1))
		# OK, so now we have a GMTdataset or a vector of them. Must create new ones with extra columns.
		if (isa(arg1, GMTdataset))
			(!haveR) && (mimas = arg1.bbox[1:4])
			arg1.data = [view(arg1,:,1) zeros(size(arg1,1)) view(arg1,:,1) view(arg1,:,2)]
			add2ds!(arg1)			# Fix arg1 meta after column insertion.
		else
			(!haveR) && (mimas = arg1[1].ds_bbox[1:4])
			for a in arg1			# Loop to create the new arrays and assign fill color if needed.
				a.data = [a[:,1] zeros(size(a,1)) a[:,1] a[:,2]]
				(haveVarFill && (ind = findfirst(" -W,", a.header)) !== nothing) && (a.header *= " -G" * a.header[ind[end]+1:end])
			end
			add2ds!(arg1[1])		# Fix arg1 meta after column insertion.
		end
	else							# Case of plain matrices
		isempty(arg1) && error("stem: 'arg1' cannot be empty.")
		if (!haveR)
			mm = extrema(arg1, dims=1)
			mimas = [mm[1][1], mm[1][2], mm[2][1], mm[2][2]]
		end
		arg1 = [arg1[:,1] zeros(size(arg1,1)) arg1[:,1] arg1[:,2]]
	end
	if (!haveR)
		t = round_wesn(mimas)		# Add a pad. Also sets the CTRL.limits plot values
		(t[3] > 0) && (t[3] = 0)	# Stems, when all positives, must start at zero
		CTRL.limits[1:4] = mimas				# These are the data limits
		opt_R::String = @sprintf(" -R%.12g/%.12g/%.12g/%.12g", t[1], t[2], t[3], t[4])
		_opt_R::String = merge_R_and_xyzlims(d, opt_R)	# See if a x or ylim is used
		if (_opt_R != opt_R)					# Yes, it was so need to update the plot limits in CTRL.limits
			CTRL.limits[7:10], opt_R = opt_R2num(_opt_R), _opt_R
		end
		d[:R] = opt_R[4:end]
	end

	len = ((val = find_in_dict(d, [:ms :markersize :MarkerSize :size])[1]) !== nothing) ? arg2str(val)::String : "8p"
	d[:S] = "v$(len)+ec+s"

	_show = false
	if (!haskey(d, :nobaseline) && haskey(d, :show))	# If baseline we need to use the true show only at hline!()
		_show = d[:show] != 0;		d[:show]=false		# Backup the :show val
	end

	MULTI_COL[] = false		# Some cat_2_arg2 paths set it to true, wich cannot happen in this function
	have_baseline = ((find_in_dict(d, [:nobaseline])[1]) === nothing)
	out1, out2 = common_plot_xyz("", mat2ds(arg1), "stem", first, false, d), nothing
	(have_baseline) && (out2 = hlines!(0.0, show=_show))	# See if we have a no-baseline request
	(out1 !== nothing && out2 !== nothing) ? [out1;out2] : ((out1 !== nothing) ? out1 : out2)
end

stem!(cmd0::String="", arg1=nothing; kw...) = stem(cmd0, arg1; first=false, kw...)
stem(arg; kw...) = stem("", cat_1_arg(arg, true); kw...)
stem!(arg; kw...) = stem("", cat_1_arg(arg, true); first=false, kw...)
stem(arg1, arg2; kw...)  = stem("", cat_2_arg2(arg1, arg2, true); kw...)
stem!(arg1, arg2; kw...) = stem("", cat_2_arg2(arg1, arg2, true); first=false, kw...)

# ------------------------------------------------------------------------------------------------------
"""
    arrows(cmd0::String="", arg1=nothing; arrow=(...), kwargs...)

Plot an arrow field.

When the keyword `arrow=(...)` or `vector=(...)` is used, the direction (in degrees counter-clockwise
from horizontal) and length must be found in columns 3 and 4, and size, if not specified on the command-line,
should be present in column 5. The size is the length of the vector head. Vector stem width is set by
option `pen` or `line_attrib`.

The `vecmap=(...)` variation is similar to above except azimuth (in degrees east of north) should be
given instead of direction. The azimuth will be mapped into an angle based on the chosen map projection.
If length is not in plot units but in arbitrary user units (e.g., a rate in mm/yr) then you can use the
*input_col* option to scale the corresponding column via the +sscale modifier.

The `geovec=(...)` or `geovector=(...)` keywords plot geovectors. In geovectors, azimuth (in degrees east
from north) and geographical length must be found in columns 3 and 4. The size is the length of the vector
head. Vector width is set by `pen` or `line_attrib`. Note: Geovector stems are drawn as thin filled polygons
and hence pen attributes like dashed and dotted are not available. For allowable geographical units, see
the `units=()` option.

The full `arrow` options list can be consulted at [Vector Attributes](@ref)

- $(_opt_B)
- $(_opt_J)
- $(_opt_R)
- **W** | **pen** | **line_attrib** :: [Type => Str]

    Set pen attributes for lines or the outline of symbols
- $(opt_savefig)

Example:

	arrows([0 8.2 0 6], limits=(-2,4,0,9), arrow=(len=2,stop=1,shape=0.5,fill=:red), axis=:a, pen="6p", show=true)
"""
function arrows(cmd0::String="", arg1=nothing; first=true, kwargs...)
	# A arrows plotting method of plot
	d = KW(kwargs)
	arg1, haveR, haveVarFill = helper_input_ds(d, cmd0, arg1)		# Read file or read "by-columns"

	# TYPEVEC = 0, ==> u,v = theta,rho. TYPEVEC = 1, ==> u,v = u,v. TYPEVEC = 2, ==> u,v = x2,y2 
	typevec = (find_in_dict(d, [:uv])[1] !== nothing) ? 1 : (find_in_dict(d, [:endpt :endpoint])[1] !== nothing) ? 2 : 0
	d, arg1 = helper_vecBug(d, arg1, first, haveR, haveVarFill, typevec)		# Deal with GMT nasty bug
	common_plot_xyz(cmd0, mat2ds(arg1), "", first, false, d)
end

arrows!(cmd0::String="", arg1=nothing; kw...) = arrows(cmd0, arg1; first=false, kw...)
arrows(arg1; kw...)  = arrows("", arg1; first=true, kw...)
arrows!(arg1; kw...) = arrows("", arg1; first=false, kw...)

# ------------------------------------------------------------------------------------------------------
function helper_vecZscale!(d::Dict, arg1, first::Bool, typevec::Int; opt_R::String="", fancy_arrow::Bool=false, paper_u::Bool=false)
	# We have a GMT bug (up till 6.4.0) that screws when vector components are dx,dy or r,theta and
	# x,y is not isometric or when -Sv+z<scale> (and possibly in other cases). So, between thinking and
	# dumb trial-and-error I came out with this patch that computes two scale factors, one to be applied
	# to the y component and the other that sets a +z<scale> under the hood.
	#
	# Though we are trying to accept also Vector{GMTdataset}, not sure if that's reasonable. What to do with them?

	isone = (isGMTdataset(arg1) && isa(arg1, GMTdataset)) ? true : false
	Tc = (isGMTdataset(arg1) && (isone ? get(arg1.attrib, "Timecol", "") == "1" :
	                                     get(arg1[1].attrib, "Timecol", "") == "1")) ? true : false
	if (typevec < 2 || Tc)		# typevec = 2 means u,v are in fact the end points and that doesn't need scaling.
		opt_R::String = (first) ? ((opt_R == "") ? parse_R(d, "", O=false, del=false)[2] : opt_R) : CTRL.pocket_R[1]
		opt_J::String = (first) ? parse_J(d, "", default="", map=true, O=false, del=false)[2] : CTRL.pocket_J[1]
		aspect_limits = (CTRL.limits[10] - CTRL.limits[9]) / (CTRL.limits[8] - CTRL.limits[7])	# Plot, not data, limits
		Dwh::Matrix{<:Float64} = gmt("mapproject -W " * opt_R * opt_J).data		# Fig dimensions in paper coords.
		aspect_sizes  = Dwh[2] / Dwh[1]
		scale_fig     = round(aspect_sizes / aspect_limits, digits=8)	# This compensates for the non-isometry
		
		unit = isa(arg1, Vector{<:GMTdataset}) ? "q" : "iq"	# The BUG only strikes on matrices, not GMTdatsets
		def_z_val = paper_u ? 1.0 : Dwh[1] / (CTRL.limits[8] - CTRL.limits[7])
		def_z::String = @sprintf("+z%.8g%s", def_z_val, unit)
	end
	if (Tc)				# Have a time column
		bb = (isone) ? arg1.bbox : arg1[1].ds_bbox
		#           2 * max(abs(miny,maxy))     /      (y_plot_max - y_plot_min)     /  max(abs(vmin,vmax))  * H/2
		facTc = (2*max(abs(bb[8]), abs(bb[7]))) / (CTRL.limits[10] - CTRL.limits[9]) / max(abs.(bb[7:8])...) * Dwh[2] / 2
		def_z, scale_fig = @sprintf("+z%.8gi", facTc), 1.0
	end
	def_e = (find_in_dict(d, [:nohead])[1] !== nothing) ? "" : "+e"
	def_h = (fancy_arrow) ? "+h0.5" : "+h2"
	
	isArrowGMT4 = haskey(d, :arrow4) || haskey(d, :vector4)
	isArrowGMT4 && (unit = replace(unit, "q" => ""); def_z = def_h = def_e = "")	# GMT4 arrows stuff only

	code = "v"
	if ((ahdr::String = helper_arrows(d)) != "")		# Have to use delete to avoid double parsing in -W
		contains(ahdr, "+e") && (def_e = "")
		contains(ahdr, "+h") && (def_h = "")
		if (typevec < 2 && contains(ahdr, "+z"))
			ss, def_z = split(ahdr, "+"), ""
			for s in ss
				if (s[1] == 'z' && length(s) > 1)
					if (Tc)
						def_z = @sprintf("+z%0.12gi",parse(Float64,s[2:end]) * facTc)
					else
						def_z = @sprintf("+z%0.12g%s",parse(Float64,s[2:end]) * (Dwh[1]/(CTRL.limits[8] - CTRL.limits[7])), unit)
					end
					ahdr = replace(ahdr, "+"*s => "")	# Remove the +z flag because it's in def_z now
					break
				end
			end
		end
		code = string(ahdr[1])
		ahdr = ahdr[2:end]								# Need to drop the code because that is set elsewhere.
	end

	len = ((val = find_in_dict(d, [:ms :markersize :MarkerSize :size])[1]) !== nothing) ? arg2str(val)::String : "8p"
	(ahdr != "" && ahdr[1] != '+') && (len = "")		# Because a length was set in the arrow(len=?,...) and it takes precedence(?)
	contains(ahdr, "+s") && (def_z = "")				# If second point (+s) no scaling(+z)
	d[:S] = code * "$(len)" * ahdr * def_e * def_h * ((typevec < 2) ? def_z : "+s")

	# Need to apply a scale factor that also compensates for the GMT bug.
	if (typevec < 2 && isa(arg1, Vector{<:GMTdataset}) && scale_fig != 1.0)
		for a in arg1
			(eltype(a.data) <: Integer) && (a.data = convert(Array{Float64}, a.data))
			for k = 1:size(a,1)  a[k,4] *= scale_fig  end
		end
	elseif (typevec < 2 && scale_fig != 1.0)
		(eltype(arg1) <: Integer) && (arg1 = convert(Array{Float64}, arg1))	# Because it fck errors instead of promoting
		for k = 1:size(arg1,1)  arg1[k,4] *= scale_fig  end
	end

	return d, arg1
end

# ------------------------------------------------------------------------------------------------------
function helper_vecBug(d, arg1, first::Bool, haveR::Bool, haveVarFill::Bool, typevec::Int; isfeather::Bool=false)
	# Helper function that deals with setting several defaults and mostly patch a GMT vectors bug.
	# TYPEVEC = 0, ==> u,v = theta,rho. TYPEVEC = 1, ==> u,v = u,v. TYPEVEC = 2, ==> u,v = x2,y2 

	isempty(arg1) && error("'arg1' input cannot be empty.")
	
	function get_minmaxs(D::GMTdataset)
		# Get x,y minmax from datasets that may have had teir columns rearranged.
		(typevec < 2) ? [min(D.bbox[1], D.bbox[1]+D.bbox[5]), max(D.bbox[2], D.bbox[2]+D.bbox[6]),
		                 min(D.bbox[3], D.bbox[3]+D.bbox[7]), max(D.bbox[4], D.bbox[4]+D.bbox[8])] :
		                D.bbox[1:4] 
	end

	function expandDS!(D::GMTdataset)
		# Expand a GMTdatset if its number of columns is 2 or 3. Also update the colnames.
		((_n_cols::Int = size(D, 2)) >= 4) && return D		# Nothing to do
		(_n_cols < 2) && error("This does not have at least 2 columns as required (it has $_n_cols).")
		if (_n_cols == 2)
			D.data = hcat(1:size(D,1), zeros(size(D,1),1), D.data)		# Add x & y
			D.colnames = ["X", "Y", "U", "V"]
		else
			D.data = hcat(D[:,1], zeros(size(D,1),1), D.data[:,2:3])	# Add y
			D.colnames = [(((Tc = get(D.attrib, "Timecol", "")) == "1") ? "Time" : "X"), "Y", "U", "V"]
		end
		set_dsBB!(D)			# Update the BBs
		return D
	end

	function rθ2uv(arg1)		# Convert to u,v
		if (eltype(arg1) <: Integer)
			arg1 = convert(Array{Float64}, arg1)
		else
			arg1 = deepcopy(arg1)	# We don't want to modify the original
		end
		for k = 1:size(arg1,1)
			s, c = sincosd(arg1[k,3])
			arg1[k,3] = arg1[k,4] * c
			arg1[k,4] = arg1[k,4] * s
		end
		return arg1
	end

	isArrowGMT4 = haskey(d, :arrow4) || haskey(d, :vector4)

	if (isGMTdataset(arg1))		# Have a GMTdataset or a vector of them. Must create new ones with extra columns.
		if (isa(arg1, GMTdataset))
			isfeather && expandDS!(arg1)				# But not expand if not a feather call
			if (!isArrowGMT4 && typevec == 0)
				arg1 = rθ2uv(arg1)
				arg1.bbox[5:8] = [extrema(view(arg1,:,3))... extrema(view(arg1,:,4))...]
			end
			(!haveR) && (mimas = get_minmaxs(arg1))
		else
			mimas = [Inf -Inf Inf -Inf]
			for a in arg1			# Loop to create the new arrays and assign fill color if needed.
				isfeather && expandDS!(a)				# Same as above
				if (!isArrowGMT4 && typevec == 0)
					a = rθ2uv(a)
					a.bbox[5:8] = [extrema(view(a,:,3))... extrema(view(a,:,4))...]
				end
				(!haveR) && (mm = get_minmaxs(a); mimas = [min(mimas[1],mm[1]), max(mimas[2],mm[2]), min(mimas[3],mm[3]), max(mimas[4],mm[4])])
				(haveVarFill && (ind = findfirst(" -W,", a.header)) !== nothing) && (a.header::String *= " -G" * a.header[ind[end]+1:end]::String)
			end
		end
	else						# A plain mtrix
		n_cols::Int = size(arg1, 2)
		(!isfeather && n_cols < 4) && error("Column data must have at least 4 columns and not $n_cols")
		if (isfeather)
			(2 > n_cols < 4) && error("Neead at least 4 columns but got $n_cols")
			(n_cols == 2) && (arg1 = hcat(1:size(arg1,1), zeros(size(arg1,1),1), arg1))		# Add x & y
			(n_cols == 3) && (arg1 = hcat(arg1[:,1], zeros(size(arg1,1),1), arg1[:,2:3]))	# Add y
		end
		(!isArrowGMT4 && typevec == 0) && (arg1 = rθ2uv(arg1))
		if (!haveR)
			mm = extrema(arg1, dims=1)
			mimas = (typevec < 2) ? [min(mm[1][1], mm[1][1]+mm[3][1]), max(mm[1][2], mm[1][2]+mm[3][2]),
			                         min(mm[2][1], mm[2][1]+mm[4][1]), max(mm[2][2], mm[2][2]+mm[4][2])] :
									[mm[1][1], mm[1][2], mm[2][1], mm[2][2]] 
		end
	end

	opt_R::String = ""
	if (first && !haveR)					# Build a -R from data limits
		dx, dy = (mimas[2] - mimas[1]) * 0.01, (mimas[4] - mimas[3]) * 0.01
		t = round_wesn(mimas + [-dx, dx, -dy, dy])		# Add a pad. Also sets the CTRL.limits plot values
		CTRL.limits[1:4] = mimas			# These are the data limits
		opt_R = @sprintf(" -R%.12g/%.12g/%.12g/%.12g", t[1], t[2], t[3], t[4])
		_opt_R = merge_R_and_xyzlims(d, opt_R)	# See if a x or ylim is used
		if (_opt_R != opt_R)				# Yes, it was so need to update the plot limits in CTRL.limits
			CTRL.limits[7:10], opt_R = opt_R2num(_opt_R), _opt_R
		end
		d[:R] = opt_R[4:end]
	end

	u = (find_in_dict(d, [:paper, :paper_units], false)[1] !== nothing) ? true : false
	d, arg1 = helper_vecZscale!(d, arg1, first, typevec; opt_R=opt_R, fancy_arrow=!isfeather, paper_u=u)	# Apply scale factor and compensates GMT bug.
	return d, arg1
end

# ------------------------------------------------------------------------------------------------------
"""
    feather(cmd0::String="", arg1=nothing; arrow=(...), kwargs...)

"""
function feather(cmd0::String="", arg1=nothing; first=true, kwargs...)
	d = KW(kwargs)
	d[:nomulticol] = true		# Prevent that with_xyvar() (called by helper_input_ds()) splits by columns
	arg1, haveR, haveVarFill = helper_input_ds(d, cmd0, arg1)		# Read file or read "by-columns"
	delete!(d, :nomulticol)

	# TYPEVEC = 0, ==> u,v = theta,rho. TYPEVEC = 1, ==> u,v = u,v. TYPEVEC = 2, ==> u,v = x2,y2 
	typevec = (find_in_dict(d, [:rtheta])[1] !== nothing) ? 0 : (find_in_dict(d, [:endpt :endpoint])[1] !== nothing) ? 2 : 1
	d, arg1 = helper_vecBug(d, arg1, first, haveR, haveVarFill, typevec; isfeather=true)	# Deal with the GMT annoying bug
	common_plot_xyz("", mat2ds(arg1), "feather", first, false, d)
end

feather!(cmd0::String="", arg1=nothing; kw...) = feather!(cmd0, arg1; first=false, kw...)
feather(arg1; kw...)  = feather("", arg1; kw...)
feather!(arg1; kw...) = feather("", arg1; first=false, kw...)
feather(arg1, arg2; kw...)  = feather("", cat_2_arg2(arg1, arg2); kw...)
feather!(arg1, arg2; kw...) = feather("", cat_2_arg2(arg1, arg2); first=false, kw...)
feather(arg1, arg2, arg3; kw...)  = feather("", cat_3_arg2(arg1, arg2, arg3); kw...)
feather!(arg1, arg2, arg3; kw...) = feather("", cat_3_arg2(arg1, arg2, arg3); first=false, kw...)
feather(arg1, arg2, arg3, arg4; kw...)  = feather("", cat_2_arg2(arg1, cat_3_arg2(arg2, arg3, arg4)); kw...)
feather!(arg1, arg2, arg3, arg4; kw...) = feather("", cat_2_arg2(arg1, cat_3_arg2(arg2, arg3, arg4)); first=false, kw...)

#= ------------------------------------------------------------------------------------------------------
function quiver(cmd0::String="", arg1=nothing; first=true, kwargs...)
	d = KW(kwargs)
	(cmd0 != "") && (arg1 = read_data(d, cmd0, "", nothing, false, true)[2])
	(isa(arg1, Matrix) && size(arg1,2) > 2 && find_in_dict(d, [:multicol])[1] !== nothing) && (arg1 = mat2ds(arg1, multi=true, color="yes"))
	haveR = (find_in_dict(d, [:R :region :limits :region_llur :limits_llur :limits_diag :region_diag :xlim :xlimits], false)[1] !== nothing)
	haveVarFill = (haskey(d, :fill) && d[:fill] == true);
	haveVarFill && delete!(d, :fill)		# Otherwise GMT would error
	(haveVarFill && !isa(arg1, Vector{<:GMTdataset})) && (@warn("'fill=true' is only usable with multi-segments"); delete!(d, :fill))

	(haveR) && (opt_R = parse_R(d, "", O=false, del=false)[2])
	opt_J = parse_J(d, "", default="", map=true, O=false, del=false)[2]
	Dhw = mapproject(opt_R * opt_J * " -W")

	if (isGMTdataset(arg1))
		isa(arg1, GMTdataset) && (arg1 = with_xyvar(d, arg1))	# It's not implemented for GMTdataset vectors
		# OK, so now we GMTdataset or a vector of them. Must create new ones with extra columns.
		if (isa(arg1, GMTdataset))
		else
		end
	else
		if (!haveR)
			mm = extrema(arg1, dims=1)
			mimas = [mm[1][1], mm[1][2], mm[2][1], mm[2][2]]
		end
	end
	if (!haveR)
		t = round_wesn(mimas)		# Add a pad
		d[:R] = @sprintf("%.12g/%.12g/%.12g/%.12g", t[1], t[2], t[3], t[4])
	end

	len = ((val = find_in_dict(d, [:ms :markersize :MarkerSize :size])[1]) !== nothing) ? arg2str(val) : "8p"
	d[:S] = "v$(len)+e+s"

	MULTI_COL[] = false		# Some cat_2_arg2 paths set it to true, wich cannot happen in this function 
	common_plot_xyz("", mat2ds(arg1), "quiver", first, false, d)
end
function quiver(arg1, arg2, arg3, arg4; first=true, kw...)
	@assert(length(arg1) == length(arg2) && length(arg2) == length(arg3) && length(arg3) == length(arg4))
	isvector(arg1) && return quiver("", [vec(arg1) vec(arg2) vec(arg1)+vec(arg3) vec(arg2)+vec(arg4)], first=first, kw...)
	autos = quiv_autoscale(arg1, arg2, arg3, arg4)
	quiver("", [arg1[:] arg2[:] arg1[:]+arg3[:].*autos arg2[:]+arg4[:].*autos]; first=first, kw...)	# Hopefully they are 2D matrices
end

function quiv_autoscale(x,y,u,v)
	if (isvector(x))  n = sqrt(length(x)); m = n
	else              m,n = size(x)
	end
	delx = diff([extrema(x)...])[1] / n
	dely = diff([extrema(y)...])[1] / m
	del = delx^2 + dely^2
	autoscale, ma = 0.9, -1e100
	if (del > 0)
		for k in eachindex(u)  ma = max(ma, u[k]^2 + v[k]^2)  end
		autoscale /= sqrt(ma/del)
	end
	return autoscale
end
=#

# ------------------------------------------------------------------------------------------------------
"""
    radar(cmd0="", arg1=nothing; axeslimts=Float64[], annotall=false, axeslabels=String[], kwargs...)

Radar plots are a useful way for seeing which variables have similar values or if there are outliers
amongst each variable. By default we expect a matrix, or a GMTdatset (or a vector of them) with normalized
values. This is so because a radar plot has multiple axis that each have different limits. So the options are
to pass normalized variables or set each axis limits via the `axeslimts` option.

- `axeslimts`: A vector with the same size as columns in the input matrix with the max extent of each variable.
               NOTE that if you don't provide this option we assume input data is normalized.
- `annotall`: By default only the first axis is annotated, which is all it needs when variables are normalized.
              However, when using non-normalized variables it may be useful to show the limits of each axis.
- `axeslabels` or `labels`: String vector with the names of each variable axis. Plots a default "Label?" if
                            not provided.

By default the polygons are not filled but that is often not so nice. To fill with the default cyclic color
use just `fill=true`. Other options are to use:

- `fill` or `fillcolor`: A string vector with polygon colors. If number of colors is less then number of
                         polygons we cycle through the number of provided colors.
- `fillalpha`: The default is to paint polygons with a transparency of 70%. For other transparency values
               pass in a vector of transparencies (between [0-1] or ]1-100]) via this option.
- `lw` or `pen`: Sets the outline pen settings (default is line thickness '= 1 pt' with same color as polygon's)

Examples:

    radar([0.5 0.5 0.6 0.9 0.77; 0.6 0.5 0.8 0.2 0.9], show=true, marker=:circ, fill=true)

    radar([10.5 20.5 30.6 40.9 46], axeslimts=[15, 25, 50, 90, 50], labels=["Spoons","Forks","Knifes","Dishes","Oranges"],
          annotall=true, marker=:circ, fill=true, show=1)
"""
radar(cmd0::String; kwargs...)  = radar_helper(cmd0, nothing; kwargs...)
radar(arg1; kwargs...)          = radar_helper("", arg1; kwargs...)
radar!(cmd0::String; kwargs...) = radar_helper(cmd0, nothing; first=false, kwargs...)
radar!(arg1; kwargs...)         = radar_helper("", arg1; first=false, kwargs...)

# ---------------------------------------------------------------------------------------------------
function radar_helper(cmd0::String, arg1; first::Bool=true, axeslimts=Float64[], annotall::Bool=false,
	                  axeslabels::Vector{String}=String[], labels::Vector{String}=String[], kwargs...)
	d = KW(kwargs)
	(cmd0 != "") && (arg1 = read_data(d, cmd0, "", arg1, " ", false, true)[2])	# Make sure we have the data here
	if (isa(arg1, GMTdataset))                data::Matrix{Float64} = arg1.data
	elseif (isa(arg1, Vector{<:GMTdataset}))  data = ds2ds(arg1).data
	elseif (isa(arg1, Vector{<:Real}))        data = reshape(arg, 1, length(arg1))
	else                                      data = arg1
	end

	(!isempty(axeslimts) && length(axeslimts) != size(data,2)) &&
		error("'axeslimits' size must be equal to number of columns in input data.")
	isnorm = !isempty(axeslimts) ? false : true		# Is input data normalized?

	n_axes = size(data,2)					# Number of axes in this radar plot
	i_ang = (n_axes == 5) ? 18.0 : 0.		# For pethagons show second axis alingned with YY
	d_ang = 360 / n_axes					# Angular distance between axis

	if (!isnorm)							# If input data is not normalized ...
		maxs_round = fill(0.0, 1, n_axes)
		for k = 1:n_axes  maxs_round[k] = round_wesn([0. 0 0 axeslimts[k]])[4]  end
	end

	basemap(R= (isnorm) ? "0/1/0/1" : @sprintf("0/%.10g/0/1", maxs_round[1]), J="X12", B="xa S", X=50, p="$i_ang")
	opt_B = annotall ? "xa S" : "xa s"
	for k = 2:n_axes
		basemap!(R= (isnorm) ? "0/1/0/1" : @sprintf("0/%.10g/0/1", maxs_round[k]), p="$((k-1)*d_ang+i_ang)", B=opt_B)
	end

	ax_angs = collect(i_ang+0.0001:d_ang:360)

	def_fill::Vector{String} = [" "]		# Means, no fill
	((val = find_in_dict(d, [:fill :fillcolor], false)[1]) !== nothing) && (def_fill = (val == true) ? String[] : string.(val))
	isempty(def_fill) && (haskey(d, :fill) ? delete!(d, :fill) : delete!(d, :fillcolor))	# Otherwise fill=true boom
	def_alpha = (def_fill != [" "] && !haskey(d, :fillalpha)) ? fill(0.7, 1, n_axes) : haskey(d, :fillalpha) ? d[:fillalpha] : [0]

	D = mat2ds((isnorm) ? collect(data') : collect((data ./ maxs_round)'), x=ax_angs, multi=true, color=:cycle, fill=def_fill, fillalpha=def_alpha)

	!isempty(labels) && (axeslabels = labels)	# Alias that does not involve a F. Any
	isempty(axeslabels) && (axeslabels = ["Label$k" for k = 1:n_axes])
	opt_B = isnorm ? "xa0 yg0.2" : "xa0 yag"
	basemap!(R=(-180,180,0,1), J="P24", p=0, B=opt_B, X=-12, Y=-12, xticks=(ax_angs, axeslabels))	# [0-360] is bugged
	
	d[:L] = true		# Make sure line is closed.
	(is_in_dict(d, [:lw :W :pen]) === nothing) && (d[:lw] = 1)
	common_plot_xyz("", D, "line", false, false, d)
end

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
	MULTI_COL[] = false		# Some cat_2_arg2 paths set it to true, wich cannot happen in this function 

	common_plot_xyz("", mat2ds(arg1), "lines", first, false, d)
end
band!(cmd0::String="", arg1=nothing; width=0.0, envelope=false, kw...) =
	band(cmd0, arg1; first=false, width=width, envelope=envelope, kw...)
band(arg; width=0.0, envelope=false, kw...)  = band("", cat_1_arg(arg, true); width=width, envelope=envelope, kw...)
band!(arg; width=0.0, envelope=false, kw...) = band("", cat_1_arg(arg, true); first=false, width=width, envelope=envelope, kw...)

band(arg1, arg2; width=0.0, envelope=false, kw...) =
	band("", cat_2_arg2(arg1, arg2, true); width=width, envelope=envelope, kw...)
band!(arg1, arg2; width=0.0, envelope=false, kw...) =
	band("", cat_2_arg2(arg1, arg2, true); first=false, width=width, envelope=envelope, kw...)
band(arg1, arg2, arg3; kw...) = band("", cat_3_arg2(arg1, arg2, arg3); envelope=true, kw...)
band!(arg1, arg2, arg3; kw...) = band("", cat_3_arg2(arg1, arg2, arg3); first=false, envelope=true, kw...)

function band(f::Function, rang=nothing; first=true, width=0.0, envelope=false, kw...)
	rang = gen_coords4funs(rang, "x"; kw...)
	band("", cat_2_arg2(rang, [f(x) for x in rang]); first=first, width=width, envelope=envelope, kw...)
end
band!(f::Function, rang=nothing; width=0.0, envelope=false, kw...) = band(f, rang; first=false, width=width, envelope=envelope, kw...)

# ------------------------------------------------------------------------------------------------------
"""
    hlines(arg; decorated=(...), xmin=NaN, xmax=NaN, percent=false, kwargs...)

Plots one or a collection of horizontal lines with eventual decorations

- `xmin` & `xmax`: Limit the horizontal lines to start a `xmin` and/or end at `xmax`
- `percent`: If true the `xmin` & `xmax` are interpreted as fractions of the figure height.

- $(_opt_B)
- $(_opt_J)
- $(_opt_R)
- **W** | **pen** | **line_attrib** :: [Type => Str]

    Set pen attributes for the horizontal lines

Example:

    plot(rand(5,3))
    hlines!([0.2, 0.6], pen=(1, :red), show=true)
"""
function hlines(arg1=nothing; first=true, xmin=NaN, xmax=NaN, percent=false, kwargs...)
	# A lines plotting method of plot
	helper_vhlines(arg1, false, first, xmin, xmax, percent, kwargs...)
end
hlines!(arg=nothing; ymin=NaN, ymax=NaN, percent=false, kw...) = hlines(arg; first=false, ymin=ymin, ymax=ymax, percent=percent, kw...)
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
"""
    vlines(arg; decorated=(...), ymin=NaN, ymax=NaN, percent=false, kwargs...)

Plots one or a collection of vertical lines with eventual decorations

- `ymin` & `ymax`: Limit the vertical lines to start a `ymin` and/or end at `ymax`
- `percent`: If true the `xmin` & `xmax` are interpreted as fractions of the figure width.

- $(_opt_B)
- $(_opt_J)
- $(_opt_R)
- **W** | **pen** | **line_attrib** :: [Type => Str]

    Set pen attributes for the horizontal lines

Example:

    plot(rand(5,3), region=[0,1,0,1])
    vlines!([0.2, 0.6], pen=(1, :red), show=true)
"""
function vlines(arg1=nothing; first=true, ymin=NaN, ymax=NaN, percent=false, kwargs...)
	# A lines plotting method of plot
	helper_vhlines(arg1, true, first, ymin, ymax, percent, kwargs...)
end
vlines!(arg=nothing; ymin=NaN, ymax=NaN, percent=false, kw...) = vlines(arg; first=false, ymin=ymin, ymax=ymax, percent=percent, kw...)

# ------------------------------------------------------------------------------------------------------
function helper_vhlines(arg1, vert::Bool, first::Bool, xymin, xymax, percent, kwargs...)
	d = KW(kwargs)
	(arg1 === nothing && ((arg1_ = find_in_dict(d, [:data])[1]) === nothing)) && error("No input data")
	# If I don't do this stupid gymn with arg1 vs arg1_ then arg1 is Core.Boxed F..
	len::Int = (arg1 !== nothing) ? length(arg1) : length(arg1_)

	mat::Matrix{Float64} = ones(2, len)
	mat[1,:] = mat[2,:] .= (arg1 !== nothing) ? arg1 : arg1_

	parse_R(d, "", O=first, del=false)[2]		# Just to make the limits land in CTRL.limits (if they aren't there already)
	xy = vert ? [CTRL.limits[9], CTRL.limits[10]] : [CTRL.limits[7], CTRL.limits[8]]
	xy == [0, 0] && (xy = [-1e150, 1e150])	# Because -R for histograms may have it [0 0] to let GMT C set the true limits.
	!isnan(xymin) && (xy[1] = !percent ? xymin : xy[1] + (xy[2]-xy[1]) * xymin)
	!isnan(xymax) && (xy[2] = !percent ? xymax : xy[1] + (xy[2]-xy[1]) * xymax)
	D::GMTdataset = mat2ds(mat, x=xy, multi=true, nanseg=true)[1]
	vert && (d[:yx] = true)		# Because we need to swapp x / y columns in the vlines case
	delete!(d, [[:xmin], [:xmax], [:ymin], [:ymax]])

	common_plot_xyz("", D, "lines", first, false, d)
end

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
	cmd, = parse_R(d, "", O=O, del=false)
	all(CTRL.limits .== 0.) && error("Need to know the axes limits in a numeric form.")
	cmd, = parse_J(d, cmd, default="", map=true, O=O, del=false)
	!CTRL.proj_linear[1] && error("Plotting bands is only possible with linear projections.")
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

	D = Vector{GMTdataset{Float64,2}}(undef, n_ds)
	for k = 1:n_ds
		w = (thick) ? mat[k,2] : (percent != 0) ? mat[k,2]*diff(CTRL.limits[ind_w]) : mat[k,2]-mat[k,1]	# bar width
		i = rem(k, length(colors)); (i == 0) && (i = length(colors))
		j = rem(k, length(transp)); (j == 0) && (j = length(transp))
		b = (size(mat,2) > 2 && !isnan(mat[k,3])) ? mat[k,3] : CTRL.limits[ind_b]	# The bar base
		t = (size(mat,2) > 3 && !isnan(mat[k,4])) ? mat[k,4] : CTRL.limits[ind_t]	# The bar top
		hdr = string("-S", bB, w, "u+b", b, "0 -G", colors[i], transp[j])
		c = (thick || percent != 0) ? mat[k,1] : (mat[k,1] + (mat[k,2] - mat[k,1]) / 2)	# Bar center position
		D[k] = GMTdataset((tipo == "v") ? [c t 0] : [t c 0], Float64[], Float64[], DictSvS(), String[], String[], hdr, String[], "", "", 0, 0)
	end

	haskey(d, :nested) && (pocket_call[][1] = D; delete!(d, :nested)) # Happens only when called nested from plot

	d[:S] = bB						# Add -Sb|B, otherwise headers are not scanned.
	got_pattern && (d[:G] = "p1")	# Patterns fck the session. Use this to inform gmt() that session must be recreated
	common_plot_xyz("", D, "", first, false, d)
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
- $(opt_C)
- **G** | **fill** :: [Type => Str] --

    Select color or pattern for filling the bars
- **L** | **vertex_labels** :: [Type => Str | Tuple of strings] --		`Arg = a/b/c`

    Set the labels for the three diagram vertices where the component is 100% [none]. 
- **M** | **dump** :: [Type => Str]

    Dumps the converted input (a,b,c[,z]) records to Cartesian (x,y,[,z]) records, where x, y
    are normalized coordinates on the triangle (i.e., 0–1 in x and 0–sqrt(3)/2 in y). No plotting occurs.
- **N** | **no_clip** | **noclip** :: [Type => Str or []]

    Do NOT clip symbols that fall outside map border 
- **R** | **region** | **limits** :: [Type => Tuple | Str]

    Give the min and max limits for each of the three axis a, b, and c. Default is (0,100,0,100,0,100)
- **S** | **symbol** :: [Type => Str]

    Plot individual symbols in a ternary diagram. If `S` is not given then we will instead plot lines
    (requires `pen`) or polygons (requires `color` or `fill`). 

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
- $(opt_U)
- $(opt_V)
- **W** | **pen** :: [Type => Str | Number]

    Sets the attributes for the particular line.
- $(opt_X)
- $(opt_Y)
- $(_opt_bi)
- $(_opt_di)
- $(opt_e)
- $(_opt_f)
- $(opt_g)
- $(_opt_h)
- $(_opt_i)
- $(_opt_p)
- $(opt_q)
- $(_opt_t)
- $(opt_savefig)

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
	opt_J::String = parse_J(d, "", default=" -JX" * split(DEF_FIG_SIZE, '/')[1] * "/0", map=true, O=false, del=false)[2]
	opt_R::String = parse_R(d, "")[1]
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
		delete!(d, [:proj, :projection])		# To avoid non-consumed warnings
		delete!(d, :clockwise)
	end
	if ((val = find_in_dict(d, [:par :conf :params], false)[1]) === nothing)
		d[:par] = (MAP_GRID_PEN_PRIMARY="thinnest,gray",)
	end
	(G_API[] == C_NULL) && gmt_restart()	# Force having a valid API. We can't afford otherwise here.
	r = common_plot_xyz("", mat2ds(arg1), "ternary", first, false, d)
	# With the following trick we leave the -R history in 0/1/0/1 and so we can append with plot, text, etc
	gmt("psxy -Scp -R0/1/0/1 -JX -O -Vq > " * joinpath(TMPDIR_USR.dir, "lixo_" * TMPDIR_USR.username * TMPDIR_USR.pid_suffix * ".ps"), [0. 0.])
	CTRL.pocket_R[1] = " -R0/1/0/1"		# Since we now always explicitly set -R, we must save it in CTRL.pocket_R
	return r
end

function parse_B4ternary!(d::Dict, first::Bool=true)
	# Ternary accepts only a special brand of -B. Try to parse and/or build -B option
	opt_B = parse_B(d, "", " -Bafg")[2]
	if ((val = find_in_dict(d, [:labels])[1]) !== nothing)		# This should be the easier way
		!(isa(val,Tuple) && length(val) == 3) && error("The `labels` option must be Tuple with 3 elements.")
		opt_Bs = split(opt_B)							# This drops the leading ' '
		x::String = (opt_Bs[1][3] == 'p') ? opt_Bs[1][4:end] : opt_Bs[1][3:end]
		d[:B] = " -Ba$(x)+l" * string(val[1])::String * " -Bb$(x)+l" * string(val[2])::String * " -Bc$(x)+l" * string(val[3])::String
		for k = 2:numel(opt_Bs)  d[:B] *= " " * opt_Bs[k]  end	# Append the remains, if any.
	else		# Ui, try to parse a string like this: " -Bpag8+u\" %\" -Ba+la -Bb+lb -Bc+lc"
		(!first && opt_B == " -Bafg") && return			# Do not use the default -B on overlays.
		opt_Bs = split(opt_B, " -B")[2:end]				# 2:end because surprisingly the first is = ""
		if (length(opt_Bs) == 1)  d[:B] = opt_B			# Accept whatever was selected
		else											# User may have used frame=(annot=?,grid=?, alabel=?,...)
			if (length(opt_Bs) == 3) d[:B] = opt_B		# OK, silly no annotations,ticks,grid
			else
				x = opt_Bs[1][2:end]
				d[:B] = " -Ba$(x)" * opt_Bs[2][2:end] * " -Bb$(x)" * opt_Bs[3][2:end] * " -Bc$(x)" * opt_Bs[4][2:end]
				for k = 5:numel(opt_Bs)  d[:B] *= " -B" * opt_Bs[k]  end	# Append the remains, if any.
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
		for n = 1:numel(val)  d[key[n]] = val[n]  end
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

See full GMT docs at [`events`]($(GMTdoc)events.html)

Parameters
----------

- **T** | **now** :: [Type => Int | Str]

    Set the current plot time. If absolute times are used you must also use -fT.
- $(_opt_B)
- $(opt_C)
- **D** | **shift** | **offset** :: [Type => Str]	``Arg = [j|J]dx[/dy][+v[pen]]``

    Offset the text from the projected (x,y) point by dx,dy [0/0].
- **E** | **knots** :: [Type => Str]	``Arg = s|t[+o|Odt][+rdt][+pdt][+ddt][+fdt][+ldt]``

    Set the time knots for the symbol or text time-functions.
- **G** | **fill** :: [Type => Str | Int | Touple]

    Set constant shade or color for all symbols.
- $(_opt_J)
- **L** | **duration** :: [Type => Bool | Number | Str]		``Arg = [length|t]``

    Specify the length (i.e., duration) of the event.
- **M** | **rise** :: [Type => Str]		``Arg = i|s|t[val1][+cval2]``

    Modify the initial intensity, size magnification, or transparency of the symbol during the rise interval.
- **Q** | **save** :: [Type => Number]

    Save the intermediate event symbols and labels to permanent files instead of removing them when done.
- $(_opt_R)
- **W** | **pen** | **markeredgecolor** | **mec** :: [Type => Str]

    Specify symbol outline pen attributes [Default is no outline].
- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)
- $(_opt_bi)
- $(_opt_di)
- $(opt_e)
- $(_opt_f)
- $(_opt_h)
- $(_opt_i)
- $(_opt_p)
- $(opt_swap_xy)
- $(opt_savefig)
"""
# ------------------------------------------------------------------------------------------------------
function events(cmd0::String="", arg1=nothing; kwargs...)
	# events share a lot of options with plot
	d = KW(kwargs)
	cmd::String = add_opt(d, "", "T", [:T :now])
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
		(angle="+a", Angle="+A", font=("+f", font), justify="+j", region_justify="+c", header="_+h", label="_+l", rec_number="+r", text="+t", zvalues="+z"); del=false)
	common_plot_xyz(cmd0, mat2ds(arg1), "events|" * cmd, true, false, d)
end
const psevents = events            # Alias

# ------------------------------------------------------------------------------------------------------
cat_1_arg(arg::GMTdataset, toDS::Bool=false) = return arg			# Miserable attempts to force type stability
cat_1_arg(arg::Vector{<:GMTdataset}, toDS::Bool=false) = return arg
function cat_1_arg(arg, toDS::Bool=false)
	(isa(arg, GMTfv) || isa(arg, Vector{GMTfv})) && return arg		# A FV type. Nothing to do here
	# Add a first column with 1:n to all args that are not GMTdatasets
	if (isa(arg, Vector) || typeof(arg) <: AbstractRange)
		if isa(arg, Vector{<:Vector{<:Real}})
			(length(arg) == 1) && (arg = hcat(collect(eltype(arg[1]), 1:length(arg[1])), arg[1]))
			(length(arg)  > 1) && (arg = reduce(hcat,arg))
		else
			arg = hcat(collect(eltype(arg), 1:size(arg,1)), arg)
		end
	elseif (isvector(arg) && length(arg) > 4)		# 4 because we want to leave the possibiloty of a 3D point + color
		arg = hcat(collect(eltype(arg), 1:length(arg)), vec(arg))
	elseif (isa(arg, Tuple{Vector{<:Real}, Vector{<:Real}}))	# This must come before next one
		arg = hcat(arg[1], arg[2])
	elseif (isa(arg, NTuple))
		arg = hcat(collect(eltype(arg), 1:length(arg)), collect(arg))
	elseif (isdataframe(arg) || isODE(arg))
		return arg
	end
	return toDS ? mat2ds(arg) : arg
end

# ------------------------------------------------------------------------------------------------------
function cat_2_arg2(arg1, arg2, toDS::Bool=false)::Union{Matrix{<:Real}, GMTdataset}
	# Cat two vectors (or tuples) or a vector (or tuple) and a matrix in a Mx2 matrix

	arg2 === nothing && return arg1
	isa(arg1, Real) && isa(arg2, Real) && return [arg1 arg2]
	isa(arg2, Function) && (arg2 = arg2.(arg1))
	!((isa(arg1, Vector) || typeof(arg1) <: AbstractRange || isa(arg1, NTuple) || isa(arg1, Matrix)) && (isa(arg2, Vector) || typeof(arg2) <: AbstractRange || isa(arg2, NTuple) || isa(arg2, Matrix))) &&
		error("Unknown types ($(typeof(arg1))) and ($(typeof(arg2))) in cat_2_arg2() function")

	if (isa(arg1, NTuple))  arg1 = collect(arg1)  end
	if (isa(arg2, NTuple))  arg2 = collect(arg2)  end
	if (size(arg1,1) == 1 && size(arg1,2) != 1)  arg1 = arg1[:]  end
	if (size(arg2,1) == 1 && size(arg2,2) != 1)  arg2 = arg2[:]  end
	arg = toDS ? mat2ds(hcat(arg1, arg2)) : hcat(arg1, arg2)
	if (size(arg,2) > 2)  global MULTI_COL[] = true  end
	return arg
end
function cat_2_arg2(arg1::GMTdataset, arg2::VMr, toDS::Bool=false)::GMTdataset
	_arg = (isvector(arg2) && isa(arg2, Matrix)) ? vec(arg2) : arg2		# Converts a one line matrix into a vec
	arg1.data = hcat(arg1.data, _arg)		# Will error if sizes not compatible
	append!(arg1.colnames, ["Z$i" for i=length(arg1.colnames)+1:size(arg1,2)])
	set_dsBB!(arg1)							# Update BB
	return arg1
end
function cat_2_arg2(arg1::VMr, arg2::GMTdataset, toDS::Bool=false)::Union{Matrix{<:Real}, GMTdataset}
	_arg = (isvector(arg1) && isa(arg1, Matrix)) ? vec(arg1) : arg1		# Converts a one line matrix into a vec
	_arg = hcat(_arg, arg2.data)			# Will error if sizes not compatible
	return toDS ? mat2ds(_arg) : _arg
end
function cat_2_arg2(arg1::GMTdataset, arg2::GMTdataset, toDS::Bool=false)::GMTdataset
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
"""
    piechart(x::VecOrMat; kw...)

Create a pie chart of the values in the vector data `x`.

Each slice has a label indicating its size as a percentage of the whole pie or a label provided by the user.

### Args
- `x`: Slice data, specified as a vector of numeric values. The size of each slice is a percentage of the whole pie,
   depending on the sum of the elements of data:
   - If sum(data) < 1, the values of data specify the areas of the pie slices, and the result is a partial pie.
   - If sum(data) ≥ 1, the data values are normalized by data/sum(data) to determine the area of each slice of the pie.

### Kwargs
- `colors`: - A sequence of comma separated colors through which the pie chart will cycle. By default we use the cycle colors.
- `explode`: - Offset slices, specified as a Int or logical vector. Slice numbers specified in this option are
   _exploded_ with a shift of 4% of the pie diameter. Example: `explode=2` will explode slice 2. `explode=[2,4]`
   will explode slices 2 and 4.
- `font`: The fontsize used in labels. By default we compute onde from the pie size (see ``ms`` below), but
   user can specify a fontsize in points (and optionally a font name and color).
- `labels`: - A string vector or a tuple with the labels of each slice.
- `labelstyle`: - Label style, specified as one of the values in the next list.
   - `"namepercent"`: - Display the ``labels`` and proportions values (as percentages) next to the corresponding slices.
   - `"namedata"`: - Labels with the name and value of each slice.
   - `"name"`: - Display the ``labels`` values next to the corresponding slices.
   - `"data"`: - Display the Data values next to the corresponding slices.
   - `"percent"`: - Display the proportions values (as percentages) next to the corresponding slices (the defaul when no ``labels`` are provided).
   - `"none"`: - Do not display any labels.
- `ms or markersize`: - The diameter of the pie in cm (Default is 8 cm).

### Example
```julia
piechart([1,2,3,4], explode=2, labels=("A","B","C","D"), labelstyle="namepercent", show=true)
```
"""
function piechart(x::VecOrMat; first::Bool=true, kw...)
	d = KW(kw)
	sumx = sum(x)
	@assert (sumx != 0) "Sum of x must be non-zero"
	X = (sumx > 1) ? vec(x) / sumx : vec(Float64.(x))
	data = zeros(length(X), 4)
	data[1, 3] = 90. - X[1]*360
	data[1, 4] = 90.0
	for k = 2:numel(X)
		data[k, 3] = data[k-1, 3] - X[k]*360
		data[k, 4] = data[k-1, 3]
	end
	
	#mid_angs = [(data[k, 3] + data[k, 4]) / 2 for k = 1:numel(x)]		# Compute the bissections angles
	mid_angs = Vector{Float64}(undef, length(x))
	@inbounds for k = 1:numel(x)				# Compute the bissections angles
		mid_angs[k] = (data[k, 3] + data[k, 4]) / 2
	end

	do_explode = false
	non_exploded = ones(Bool, length(X))		# Default to no explosion
	if ((val = find_in_dict(d, [:explode])[1]) !== nothing)
		explode::Vector{Int} = isa(val, Bool) ? find(val) : [(val)...]
		maximum(explode) > length(X) && error("The explode option must be a vector of Ints with no values larger than the size of data")
		data_explode = data[explode, :]			# Get the exploded data
		non_exploded[explode] .= false
		data = data[non_exploded, :]			# Get the non-exploded data
		do_explode = true
	end
	
	# Need to parse these ones first to not get messages of "not-consumed" options from plot()
	ms::Float64 = ((val = find_in_dict(d, [:ms :markersize :MarkerSize :size])[1]) === nothing) ? 8.0 : parse(Float64, val)
	labels::Vector{<:String} = ((val = find_in_dict(d, [:labels :label])[1]) === nothing) ? String[] : [string.(val)...]
	labelstyle::String = ((val = find_in_dict(d, [:labelstyle])[1]) === nothing) ? "" : string(val)::String

	!isempty(labels) && (length(labels) != length(X)) &&
		error("The number of labels ($(length(labels))) does not match the number of data slices ($(length(X)))")
	!(labelstyle in ["", "namepercent", "namedata", "name", "data", "percent", "none"]) &&
		(@warn("Bad value ($labelstyle) for the 'labelstyle' option. Defaulting to 'percent'"); labelstyle = "percent")
	isempty(labels) && (labelstyle in ["namepercent", "namedata", "name", "data"]) &&
		(@warn("When not providing 'labels' cannot use this 'labelstyle' option ($labelstyle). Defaulting to 'percent'"); labelstyle = "percent")
	(isempty(labels) && labelstyle == "") && (labelstyle = "percent")

	# Now we can parse the rest of the options
	if ((val = find_in_dict(d, [:color :colors])[1]) === nothing)
		fill = (length(X) <= 8) ? matlab_cycle_colors[1:length(X)] : simple_distinct[1:length(X)]
	else
		fill = string.(split(string(val), ","))
		(length(fill) < length(X)) && (fill = repeat(fill, ceil(Int, length(X)/length(fill))))
		(length(fill) > length(X)) && (fill = fill[1:length(X)])
	end
	d[:R] = (-2*ms, 2*ms, -2*ms, 2*ms)			# Set it big enough that even long legends do not get clipped
	d[:marker] = "wedge"
	d[:ms] = ms
	d[:B] = "none"
	one_not_exploded = any(non_exploded)		# If we have at least one not exploded slice
	one_not_exploded ? (Dv = ds2ds(mat2ds(data), fill=fill[non_exploded])) : (d[:ms] = 0)

	# ------------ If no lables wanted we just plot the wedges and return
	(labelstyle == "none") && return _common_plot_xyz("", Dv, "plot", !first, true, false, d)

	fs = font(d, [:font])						# See if we have a font (size & others) specification	
	fs = (fs != "") ? fs : string(round(ms / (2.54/72) / 30, digits=1))	# Use a font size that is ~30 smaler than pie diameter

	do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)
	one_not_exploded ? _common_plot_xyz("", Dv, "plot", !first, true, false, d) : _common_plot_xyz("", [0 0 0 0], "plot", !first, true, false, d)

	# Compute the h-v scales
	sc_x = (CTRL.limits[2]-CTRL.limits[1]) / CTRL.figsize[1]
	sc_y = CTRL.figsize[2] != 0.0 ? (CTRL.limits[4]-CTRL.limits[3]) / CTRL.figsize[2] : sc_x

	# If some slices are to be "exploded"
	explode_off = ms * 0.04				# The offset of exploded slices (4% of the pie diameter)
	if (do_explode)
		for k = 1:size(data_explode, 1)
			data_explode[k, 1] += explode_off * sc_x * cosd(mid_angs[explode[k]])
			data_explode[k, 2] += explode_off * sc_y * sind(mid_angs[explode[k]])
		end
		Dv = ds2ds(mat2ds(data_explode), fill=fill[explode])
		d[:marker], d[:ms] = "wedge", ms-explode_off/2
		_common_plot_xyz("", Dv, "plot", true, true, false, d)
	end

	#  Get the text positions
	r = ms * 1.05 / 2							# In cm
	txt_pts = zeros(length(X), 2)
	for k = 1:numel(X)
		_r = non_exploded[k] ? r : r + explode_off
		txt_pts[k, 1], txt_pts[k, 2] = _r * sc_x * cosd(mid_angs[k]), _r * sc_y * sind(mid_angs[k])
	end

	str = (labelstyle == "percent") ? string.(round.(X*100, digits=1), "%") : (labelstyle == "namepercent") ?
		labels .* " (" .* string.(round.(X*100, digits=1), "%)") : (labelstyle == "namedata") ?
		labels .* " (" .* string.(vec(x), ")") : (labelstyle == "name") ?
		labels : (labelstyle == "data") ? string.(vec(x)) : String[]

	justs = pick_justify(mid_angs)				# Get the text box justifications

	text!(mat2ds(txt_pts, text=justs .* " " .* str), F="+f"*fs*"+j", show=do_show)
end

# ------------------------------------------------------------------------------------------------------
piechart!(x::VecOrMat; kw...) = piechart(x; first=false, kw...)

# ------------------------------------------------------------------------------------------------------
function pick_justify(angs)::Vector{String}
	justs = ["BL", "ML", "TL", "TC", "TR", "MR", "BR", "BC"]
	t = collect(1:length(angs))
	angs[angs .< 0] .+= 360
	for k = 1:numel(angs)
		if     (angs[k] >= 80 && angs[k] <= 100)   t[k] = 8
		elseif (angs[k] >= 170 && angs[k] <= 190)  t[k] = 6
		elseif (angs[k] >= 260 && angs[k] <= 280)  t[k] = 4
		elseif (angs[k] >= 350 && angs[k] <= 10)   t[k] = 2
		elseif (angs[k]  > 10 && angs[k]  < 80)    t[k] = 1
		elseif (angs[k]  > 100 && angs[k] < 170)   t[k] = 7
		elseif (angs[k]  > 190 && angs[k] < 260)   t[k] = 5
		elseif (angs[k]  > 280 && angs[k] < 350)   t[k] = 3
		end
	end
	return justs[t]
end

# ------------------------------------------------------------------------------------------------------
"""
    biplot(name::String | D::GMTDataset; arrow::Tuple=(0.3, 0.5, 0.75, "#0072BD"), cmap=:categorical,
           colorbar::Bool=true, marker=:point,ms="auto", obsnumbers::Bool=false, PC=(1,2),
           varlabels=:yes, xlabel="", ylabel="", kw...)

Create a 2D biplot of the Principal Component Analysis (PCA) of a two-dimensional chart that
represents the relationship between the rows and columns of a table.

- `cmd0`: The name of a 2D data table file readable with ``gmtread()``, or a ``GMTdataset`` with the data.
- `arrow`: a tuple with the following values: (len, shape, width, color). If this default is used we scale them by fig size.
   - `len`: the length of the arrowhead in cm. Default is 0.3.
   - `shape`: the shape of the arrow. Default is 0.5.
   - `width`: the width of the arrow stem in points. Default is 0.75.
   - `color`: the color of the arrow. Default is "#0072BD".
- `cmap`: a String or Symbol with the name of a GMT colormap. 
   - Or a string with "matlab" or "distinct"
   - Or "alphabet" for colormaps with distinct colors.
   - Or a comma separated string with color names; either normal names ("red,green") or hex color codes ("#ff0000,#00ff00").
   - Or "none" for plotting all points in black color. A single color in hexadecimal format plots all points in that color.
   Default is "categorical".
- `colorbar`: whether to plot a colorbar. Default is true.
- `marker`: a String or Symbol with the name of a GMT marker symbol. Default is "point".
- `ms`: a String or Symbol with the name of a GMT marker size. Default is "auto" (also scales sizes with the size of the plot).
- `obsnumbers`: whether to plot observation numbers on the plot. Default is false. Note that in this case we are not able
   to plot colored numbers by category, so we plot the symbols as well (use `cmap="none"` if you don't want this).
- `PC`: a tuple with the principal components to plot. Default is (1, 2). For example, PC=(2,3) plots
   the 2nd and 3rd principal components.
- `varlabels`: whether to plot variable labels. The default is :yes and it prints as labels the column names
   if the input GMTdataset. Is it hasn't column names, then it prints "A,B,C,...". Give a string vector to plot custom labels.
- `xlabel`: a String with the x-axis label. Default is "", which prints "PC[PC[1]]".
- `ylabel`: a String with the y-axis label. Default is "", which prints "PC[PC[2]]".
- `kw...`: Any additional keyword argument to be passed to the ``plot()`` function.

### Examples

```julia
biplot(TESTSDIR * "iris.dat", show=true)

# Plot a 6 cm fig with observarion numbers
biplot(TESTSDIR * "iris.dat", figsize=6, obsnumbers=true, show=true)
```
"""
biplot(cmd0::String; first::Bool=true, PC=(1,2), xlabel="", ylabel="", varlabels=:yes, cmap=:categorical, marker=:point,
       ms="auto", obsnumbers::Bool=false, colorbar::Bool=true, arrow::Tuple=(0.3, 0.5, 0.75, "#0072BD"), kw...) =
	biplot(gmtread(cmd0)::GMTdataset{Float64,2}; first=first, PC=PC, xlabel=xlabel, ylabel=ylabel, varlabels=varlabels,
           cmap=cmap, marker=marker, ms=ms, obsnumbers=obsnumbers, colorbar=colorbar, arrow=arrow, kw...)

function biplot(D::GMTdataset{T,2}; first::Bool=true, PC=(1,2), cmap=:categorical, xlabel="", ylabel="",
                varlabels=:yes, marker=:point, ms="auto", obsnumbers::Bool=false, colorbar::Bool=true,
                arrow::Tuple=(0.3, 0.5, 0.75, "#0072BD"), kw...) where {T<:Real}
	xlab = (xlabel == "") ? "PC$(PC[1])" : xlabel
	ylab = (ylabel == "") ? "PC$(PC[2])" : ylabel
	labels = isa(varlabels, Vector{<:String}) ? varlabels : String[]
	if (lowercase(string(varlabels)) != "no")
		labels = startswith(D.colnames[1], "col.") ? string.(collect('A':'Z')[1:size(D,2)]) : D.colnames[1:size(D,2)]
	end
	Z = zscores(D)
	scores, coefs, _, explained, = pca(Z)
	biplot(Float64.(coefs[:,[PC[1], PC[2]]]), Float64.(scores[:,[PC[1], PC[2]]]), Float64.(explained[[PC[1], PC[2]]]),
	       labels, D.text, obsnumbers, xlab, ylab, lowercase(string(cmap)), string(marker), string(ms), colorbar,
           (Float64.(arrow[1:3])..., string(arrow[4])), first, KW(kw))
end

function biplot(coefs::Matrix{Float64}, scores::Matrix{Float64}, explained::Vector{Float64}, varlabels::Vector{<:String},
	            obslabels::Vector{<:String}, obsnumb::Bool, xlabel::String, ylabel::String, cmap::String, marker::String,
                ms::String, colorbar::Bool, arrow_pars::Tuple{Float64, Float64, Float64, String}, first::Bool, d::Dict{Symbol,Any})

	!isempty(varlabels) && (length(varlabels) != size(coefs, 1)) &&
		error("The number of varlabels ($(length(varlabels))) does not match the number of rows in data ($(size(coefs, 1)))")

	show = find_in_dict(d, [:show])[1] !== nothing;		fmt = find_in_dict(d, [:fmt])[1];	(fmt === nothing) && (fmt = FMT[]);
	savefig = find_in_dict(d, [:savefig :figname :name])[1];
	signs = sign.(coefs[findmax(abs, coefs, dims=1)[2]])
	coefs = coefs .* signs				# Make sure that at each column the largest coefficient is positive.

	# Scale the scores so they fit on the plot, and change their sign according to the sign convention for the coefs.
	maxlen = sqrt(maximum(sum(coefs.^2, dims=2)))
	scores = maxlen .* scores ./ maximum(abs, scores) .* signs 		# Normalize the scores to the max of the coefficients

	if ((val = find_in_dict(d, [:figsize :fig_size], false)[1]) !== nothing)
		figsize::Float64 = isa(val, Tuple) ? val[1] : val 
	else
		figsize = 15.0;		d[:aspect] = "equal"
	end

	mima, mima_c = extrema(scores), extrema(coefs)
	mima = (min(mima[1], mima_c[1]), max(mima[2], mima_c[2]))
	r = round_wesn([mima[1], mima[2], mima_c[1], mima_c[2]])
	r[1] = -max(-r[1], r[2]);	r[2] = -r[1];	r[3] = -max(-r[3], r[4]);	r[4] = -r[3]
	d[:R] = @sprintf("%.1f/%.1f/%.1f/%.1f", r[1], r[2], r[3], r[4])
	d[:marker] = marker
	d[:ms] = (ms == "auto") ? @sprintf("%.1fp", figsize / 15 * 3) : ms		# Scale ms to figsize
	d[:B] = "afg"

	if (xlabel != "")
		!isempty(explained) && (xlabel = xlabel * "\" (" * string(round(explained[1], digits=1)) * "%)\"")
		!isempty(explained) && (ylabel = ylabel * "\" (" * string(round(explained[2], digits=1)) * "%)\"")
		d[:B] *= " x+l" * xlabel * " y+l" * ylabel
	end

	if (cmap != "none" && !(cmap[1] == '#' && !contains(cmap, ',')))
		gidx, gnames = grp2idx(obslabels)			# Find the groups and their indices
		ind_grps = ones(length(obslabels))
		for i = 1:numel(gidx), j = 1:length(gidx[i]), ind_grps[gidx[i][j]] = i  end
		d[:zcolor] = ind_grps
		
		if ((cmap == "matlab") || (cmap == "distinct") || (cmap == "alphabet"))		# Distinct colornames
			cmap = join((cmap == "matlab") ? matlab_cycle_colors[1:length(gidx)] : (cmap == "distinct") ? simple_distinct[1:length(gidx)] : alphabet_colors[1:length(gidx)], ",")
		end
		d[:C] = makecpt(cmap=cmap, range=join(gnames,","))
		colorbar && (d[:colorbar] = true)
	end

	scores = mat2ds(scores, text=obslabels)
	common_plot_xyz("", scores, "biplot", first, false, d)
	obsnumb && text!(scores, F=@sprintf("+f%.1fp+r1", figsize/15*8))	# Plot also the observation numbers
	(arrow_pars == (0.3, 0.5, 0.75, "#0072BD") && figsize != 15) &&		# If default arrow_pars, scale them by fig size
		(arrow_pars = (max(arrow_pars[1]*figsize/15*0.3, 0.1), arrow_pars[2], arrow_pars[3]*figsize/15*0.75, arrow_pars[4]))
	feather!([fill(0.0, size(coefs, 1)) coefs[:,1:2]], endpt=true, arrow=(len=arrow_pars[1], shape=arrow_pars[2]),
	         lw=arrow_pars[3], lc=arrow_pars[4], fill=arrow_pars[4])

	if (!isempty(varlabels))
		text!(mat2ds(coefs, text=varlabels), F=@sprintf("+f%.1fp", (figsize / (15/9) + 1)),
		      D=@sprintf("%.2fc", max(figsize/15*0.15, 0.05)))
	end
	show && showfig(fmt=fmt, savefig=savefig)
end

biplot!(D::GMTdataset{T,2}; PC=(1,2), cmap=:categorical, xlabel="", ylabel="", varlabels=:yes, marker=:point, ms="auto",
        obsnumbers::Bool=false, colorbar::Bool=true, arrow::Tuple=(0.3, 0.5, 0.75, "#0072BD"), kw...) where {T<:Real} =
	biplot(D; first=false, PC=PC, cmap=cmap, xlabel=xlabel, ylabel=ylabel, varlabels=varlabels,
	       marker=marker, ms=ms, obsnumbers=obsnumbers, colorbar=colorbar, arrow=arrow, kw...)

biplot!(cmd0::String; PC=(1,2), xlabel="", ylabel="", varlabels=:yes, cmap=:categorical, marker=:point,
        ms="auto", obsnumbers::Bool=false, colorbar::Bool=true, arrow::Tuple=(0.3, 0.5, 0.75, "#0072BD"), kw...) =
	biplot(cmd0; first=false, PC=PC, xlabel=xlabel, ylabel=ylabel, varlabels=varlabels, cmap=cmap,
	       marker=marker, ms=ms, obsnumbers=obsnumbers, colorbar=colorbar, arrow=arrow, kw...)

# ------------------------------------------------------------------------------------------------------
"""
	stereonet(mat; schmidt=true, wulff=false, kw...)

Plot a stereonet map in either Schmidt or Wulff projection.

- `mat`: A GMTdataset or a matrix with two columns: azimuth and plunge.
- `schmidt`: If true, use Schmidt projection. If false, use Wulff projection.
- `wulff`: If true, use Wulff projection.
- `kw`: Additional keyword arguments to pass to the `plot` function. Namely, `figsize`, `figname`,
  and line & marker settings (see ``plots`` manual for details on them).

In case the produced figure is still not satisfactory, you can make one by yourself.
For that use the `Dv, Dp = stereonet_data(mat)` function to get the fault planes and poles. A good place
to start is the `stereonet` function itself. Type ``@edit stereonet([0 0])`` to see the code.

### Example
```julia
stereonet([90 30; 180 45; 270 60; 0 15; 30 45; 120 48; 225 27; 350 80], show=true)
```
"""
function stereonet(mat::AbstractArray{T,2}; first=true, schmidt=true, wulff=false, kw...) where T<:Real
	d = KW(kw)
	_stereonet(mat, first, schmidt, wulff, d)
end
function _stereonet(mat::AbstractArray{T,2}, first::Bool, schmidt::Bool, wulff::Bool, d) where T<:Real
	show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)
	savefig = find_in_dict(d, [:savefig :figname :name])[1];
	Vd = get(d, :Vd, 0)
	wulff && (schmidt = false)			# Wulff stereonet

	Dv, Dp = stereonet_data(mat)
	prj = schmidt ? :laea : (name=:stereo, center=[0,0])# "S0/0/15c"
	(is_in_dict(d, [:lc :linecolor]) === nothing) && (d[:lc] = "red")
	(is_in_dict(d, [:lt :linethickness]) === nothing) && (d[:lt] = 0.5)
	d[:par] = (MAP_GRID_PEN_PRIMARY="0.25,gray", MAP_GRID_PEN_SECONDARY="0.25,black")
	d[:B], d[:R], d[:J] = "pg5 sg20", :d, prj
	common_plot_xyz("",  Dv, "plot", first, false, d)		# Plot the fault planes
	(Vd != 0) && (d[:Vd] = Vd)

	(is_in_dict(d, [:marker :Marker :shape]) === nothing) && (d[:marker] = "circ")
	(is_in_dict(d, [:mec :markeredgecolor :MarkerEdgeColor]) === nothing) && (d[:mec] = "0.0p,black")
	(is_in_dict(d, [:mc :markercolor]) === nothing) && (d[:mc] = "blue")
	(is_in_dict(d, [:ms :markersize :MarkerSize :size]) === nothing) && (d[:ms] = "3p")
	common_plot_xyz("",  Dp, "stereonet", false, false, d)		# Plot the poles
	basemap!(J="P" * CTRL.pocket_J[2] * "+a", B="a15", show=show, savefig=savefig)
end
stereonet!(mat::AbstractArray{T,2}; schmidt=true, wulff=false, kw...) where T<:Real =
	stereonet(mat; first=false, schmidt=schmidt, wulff=wulff, kw...)

function stereonet_data(mat::AbstractArray{T,2}) where T<:Real
	# This function computes the fault planes and the poles. Returns a vector of GMTdataset
	# with the fault planes and a GMTdataset with the poles.
	@assert size(mat,2) >= 2 "Input matrix must have at least two columns: azimuth and plunge"
	Dv = Vector{GMTdataset{Float64,2}}(undef, size(mat,1))
	polos = Matrix{Float64}(undef, size(mat,1), 2)
	for k = 1:size(mat,1)
		m = [fill(90.0-mat[k,2], 180) collect(linspace(-90.0, 90, 180))]
		x,y,z = sph2cart(m[:,1], m[:,2], 1.0, deg=true)
		R = eulermat([mat[k,1],0,0])[2]
		m2 = [x y z] * R
		lon, lat, = cart2sph(m2[:,1], m2[:,2], m2[:,3], deg=true)
		Dv[k] = mat2ds([lon lat], geom=wkbLineString)
		
		# Now the poles	
		x,y,z = sph2cart(-mat[k,2], 0.0, 1.0, deg=true)
		m2 = [x y z] * R
		lon, lat, = cart2sph(m2[1], m2[2], m2[3], deg=true)
		polos[k,1], polos[k,2] = lon, lat
	end
	set_dsBB!(Dv)
	return Dv, mat2ds(polos, geom=wkbPoint)
end
