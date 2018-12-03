"""
    plot(arg1::Array; kwargs...)

reads (x,y) pairs from files [or standard input] and generates PostScript code that will plot lines,
polygons, or symbols at those locations on a map.

Full option list at [`psxy`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html)

Parameters
----------

- **A** : **straight_lines** : -- Str --  

	By default, geographic line segments are drawn as great circle arcs.
	To draw them as straight lines, use the -A flag.
- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- **C** : **color** : -- Str --

    Give a CPT or specify -Ccolor1,color2[,color3,...] to build a linear continuous CPT from those colors automatically.
	[`-C`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#c)
- **D** : **offset** : -- Str --

    Offset the plot symbol or line locations by the given amounts dx/dy.
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

    Use the supplied intens value (in the [-1 1] range) to modulate the fill color by simulating illumination.
- **L** : **closed_polygon** : -- Str --

    Force closed polygons. 
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#l)
- **N** : **no_clip** : --- Str or [] --

    Do NOT clip symbols that fall outside map border 
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
- **W** : **line_attribs** : **markeredgecolor** : **MarkerEdgeColor** : -- Str --
    Set pen attributes for lines or the outline of symbols
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#w)
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
"""
plot(arg1; K=false, O=false, first=true, kw...) = psxy("", arg1; caller="plot", K=K, O=O, first=first, kw...)
plot!(arg1; K=true, O=true, first=false, kw...) = psxy("", arg1; caller="plot", K=K, O=O, first=first, kw...)

plot(cmd0::String="", arg1=[]; K=false, O=false, first=true, kw...) =
	psxy(cmd0, arg1; caller="plot", K=K, O=O, first=first, kw...)
plot!(cmd0::String="", arg1=[]; K=true, O=true, first=false, kw...) =
	psxy(cmd0, arg1; caller="plot", K=K, O=O, first=first, kw...)

# ------------------------------------------------------------------------------------------------------
function plot(arg1::AbstractArray, arg2::AbstractArray; K=false, O=false, first=true, kw...)
	arg = cat_2_arg2(arg1, arg2)	# If they are vectors, cat them into a Mx2 matrix
	psxy("", arg; caller="plot",  K=K, O=O, first=first, kw...)
end
function plot!(arg1::AbstractArray, arg2::AbstractArray; K=false, O=false, first=true, kw...)
	psxy("", cat_2_arg2(arg1, arg2); caller="plot",  K=true, O=true, first=false, kw...)
end
# ------------------------------------------------------------------------------------------------------

"""
plot3d(arg1::Array; kwargs...)

reads (x,y,z) triplets from files [or standard input] and generates PostScript code that will plot lines,
polygons, or symbols at those locations in 3-D.

Full option list at [`psxyz`](http://gmt.soest.hawaii.edu/doc/latest/psxyz.html)

Parameters
----------

- **A** : **straight_lines** : -- Str --  

    By default, geographic line segments are drawn as great circle arcs. To draw them as straight lines, use the -A flag.
- $(GMT.opt_J)
- $(GMT.opt_Jz)
- $(GMT.opt_R)
- $(GMT.opt_B)
- **C** : **color** : -- Str --

    Give a CPT or specify -Ccolor1,color2[,color3,...] to build a linear continuous CPT from those colors automatically.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/psxyz.html#c)
- **D** : **offset** : -- Str --

    Offset the plot symbol or line locations by the given amounts dx/dy.
- **E** : **error_bars** : -- Str --

    Draw symmetrical error bars.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/psxyz.html#e)
- **F** : **conn** : **connection** : -- Str --

    Alter the way points are connected
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/psxyz.html#f)
- **G** : **fill** : **markerfacecolor** : **MarkerFaceColor** : -- Str --

    Select color or pattern for filling of symbols or polygons. BUT WARN: the alias 'fill' will set the
    color of polygons OR symbols but not the two together. If your plot has polygons and symbols, use
    'fill' for the polygons and 'markerfacecolor' for filling the symbols. Same applyies for W bellow
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/psxyz.html#g)
- **I** : **intens** : -- Str or number --

    Use the supplied intens value (in the [-1 1] range) to modulate the fill color by simulating illumination.
- **L** : **closed_polygon** : -- Str --

    Force closed polygons. 
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/psxyz.html#l)
- **N** : **no_clip** : --- Str or [] --

    Do NOT clip symbols that fall outside map border 
- $(GMT.opt_P)
- **S** : **symbol** : **marker** : **Marker** : -- Str --

    Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines). 
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/psxyz.html#s)
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
- **W** : **line_attribs** : **markeredgecolor** : **MarkerEdgeColor** : -- Str --
    Set pen attributes for lines or the outline of symbols
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/psxyz.html#w)
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
"""
plot3d(arg1; K=false, O=false, first=true, kw...) =
	psxyz("", arg1; caller="plot3d", K=K, O=O, first=first, kw...)
plot3d!(arg1; K=false, O=false, first=true, kw...) =
	psxyz("", arg1; caller="plot3d", K=true, O=true, first=false, kw...)

# ------------------------------------------------------------------------------------------------------
plot3d(cmd0::String; K=false, O=false, first=true, kw...) =
	psxyz(cmd0; caller="plot3d", K=K, O=O, first=first, kw...)
plot3d!(cmd0::String; K=false, O=false, first=true, kw...) =
	psxyz(cmd0; caller="plot3d", K=true, O=true, first=false, kw...)

# ------------------------------------------------------------------------------------------------------
function plot3d(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; K=false, O=false, first=true, kw...)
	arg = hcat(arg1[:], arg2[:], arg3[:])
	psxyz("", arg; caller="plot3d", K=K, O=O, first=first, kw...)
end
function plot3d!(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; K=false, O=false, first=true, kw...)
	arg = hcat(arg1[:], arg2[:], arg3[:])
	psxyz("", arg; caller="plot3d", K=true, O=true, first=false, kw...)
end
# ------------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------------
scatter(arg1;   K=false, O=false, first=true, kw...)  = scatter("", arg1; K=K, O=O, first=first, is3D=false, kw...)
scatter!(arg1;  K=true,  O=true,  first=false, kw...) = scatter("", arg1; K=K, O=O, first=first, is3D=false, kw...)
scatter3(arg1;  K=false, O=false, first=true, kw...)  = scatter("", arg1; K=K, O=O, first=first, is3D=true, kw...)
scatter3!(arg1; K=true,  O=true,  first=false, kw...) = scatter("", arg1; K=K, O=O, first=first, is3D=true, kw...)

function scatter(arg::AbstractArray; K=false, O=false, first=true, kw...)
	arg = cat_1_arg(arg)			# If ARG is a vector, prepend it with a 1:N x column
	scatter("", arg; K=K, O=O, first=first, kw...)
end
scatter!(arg::AbstractArray; K=false, O=false, first=true, kw...) = scatter(arg; K=K, O=O, first=first, kw...)
function scatter(arg1::AbstractArray, arg2::AbstractArray; K=false, O=false, first=true, kw...)
	arg = cat_2_arg2(arg1, arg2)	# If they are vectors, cat them into a Mx2 matrix
	scatter("", arg; K=K, O=O, first=first, is3D=false, kw...)
end
function scatter!(arg1::AbstractArray, arg2::AbstractArray; K=true, O=true, first=false, kw...)
	arg = cat_2_arg2(arg1, arg2)	# If they are vectors, cat them into a Mx2 matrix
	scatter("", arg; K=K, O=O, first=first, is3D=false, kw...)
end
function scatter3(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; K=false, O=false, first=true, kw...)
	arg = hcat(arg1, arg2, arg3)
	scatter("", arg; K=K, O=O, first=first, is3D=true, kw...)
end
function scatter3!(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; K=true, O=true, first=false, kw...)
	#arg = hcat(arg1, arg2, arg3)
	scatter("", hcat(arg1, arg2, arg3); K=K, O=O, first=first, is3D=true, kw...)
end

"""
    scatter(cmd0::String="", arg1=[], kwargs...)

Reads (x,y) pairs and plot symbols at those locations on a map.
This module is a subset of ``plot`` to make it simpler to draw scatter plots. So many of
its (fine) controling parameters are not listed here. For a finer control, user should
consult the ``plot`` module.

Parameters
----------

- **G** : **fill** : **markerfacecolor** : -- Str --

    Select color or pattern for filling of symbols or polygons.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#g)
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
    points unless specified otherwise with (for example for cm) *par=(PROJ_LENGTH_UNIT=:c,)*	
- **W** : **pen** : **markeredgecolor** : -- Str --

    Set pen attributes for lines or the outline of symbols
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html#w)

[`Full man page`](https://genericmappingtools.github.io/GMT.jl/latest/scatter/)
[`GMT man page`](http://gmt.soest.hawaii.edu/doc/latest/plot.html)
"""
function scatter(cmd0::String="", arg1=[]; K=false, O=false, first=true, is3D=false, kwargs...)
	if (is3D)  GMT.common_plot_xyz(cmd0, arg1, "scatter3", K, O, first, is3D, kwargs...)
	else       GMT.common_plot_xyz(cmd0, arg1, "scatter",  K, O, first, is3D, kwargs...)
	end
end
# ------------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------------
function bar(arg1::NTuple; K=false, O=false, first=true, kw...)
	bar(1:length(arg1), collect(arg1); K=K, O=O, first=first, kw...)
end
bar!(arg1::NTuple; K=true, O=true, first=false, kw...) = bar(arg1; K=K, O=O, first=first, kw...)

function bar(arg1::NTuple, arg2::NTuple; K=false, O=false, first=true, kw...)
	bar(collect(arg1), collect(arg2); K=K, O=O, first=first, kw...)
end
bar!(arg1::NTuple, arg2::NTuple; K=true, O=true, first=false, kw...) =
	bar(arg1, arg2; K=K, O=O, first=first, kw...)

function bar(arg1::AbstractArray, arg2::AbstractArray; K=false, O=false, first=true, kw...)
	arg = cat_2_arg2(arg1, arg2)	# If they are vectors, cat them into a Mx2 matrix
	bar("", arg; K=K, O=O, first=first, kw...)
end
bar!(arg1::AbstractArray, arg2::AbstractArray; K=true, O=true, first=false, kw...) =
	bar(arg1, arg2; K=K, O=O, first=first, kw...)

function bar(arg::AbstractArray; K=false, O=false, first=true, kw...)
	arg = cat_1_arg(arg)			# If ARG is a vector, prepend it with a 1:N x column
	bar("", arg; K=K, O=O, first=first, kw...)
end
bar!(arg::AbstractArray; K=true, O=true, first=false, kw...) = bar(arg; K=false, O=false, first=true, kw...)

# ------------------------------------------------------------------------------------------------------
"""
    bar(cmd0::String="", arg1=[], arg2=[], kwargs...)

Reads a file or (x,y) pairs and plots vertical bars extending from base to y.

- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- **fill** : -- Str --

    Select color or pattern for filling the bars
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#g)
- **base** : **bottom** : -- Str or Num --		``key=value``

    By default, base = ymin. Use this option to change that value. If base is not appended then we read it.
    from the last input data column.
- **size** : **width** : -- Str or Num --		``key=value``

    The size or width is the bar width. Append u if size is in x-units. When *width* is used the default is plot-distance units.

Example:

    bar(sort(randn(10)), fill=:black, frame=:auto, show=true)
"""
function bar(cmd0::String="", arg=[]; K=false, O=false, first=true, kwargs...)
	if (cmd0 == "") arg = cat_1_arg(arg)  end	# If ARG is a vector, prepend it with a 1:N x column
	GMT.common_plot_xyz(cmd0, arg, "bar", K, O, first, false, kwargs...)
end

# ------------------------------------------------------------------------------------------------------
"""
    bar3(cmd0::String="", arg1=[], kwargs...)

Read a grid file, a grid or a MxN matrix and plots vertical bars extending from base to z.

- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- **fill** : -- Str --		``key=color``

    Select color or pattern for filling the bars
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#g)
- **base** : -- Str or Num --		``key=value``

    By default, base = ymin. Use this option to change that value. If base is not appended then we read it.
- $(GMT.opt_p)

Example:

    G = gmt("grdmath -R-15/15/-15/15 -I0.5 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
    bar3(G, lw=:thinnest, show=true)
"""
function bar3(cmd0::String="", arg=[]; K=false, O=false, first=true, kwargs...)
	# Contrary to "bar" this one has specific work to do here.
	d = KW(kwargs)
	opt_z = ""

	arg1 = arg			# Make a copy that may or not become a new thing

	if (isa(arg1, Array))
		ny, nx = size(arg1)
		if ((nx > 3 && ny > 3))  arg1 = mat2grid(arg1)  end		# Assume it is a 'bare grid'
	end

	if (isa(arg1, GMTgrid))
		if (haskey(d, :bar))
			opt_S = GMT.parse_bar_cmd(d, :bar, "", "So")
		else
			# 0.85 is the % of inc width of bars
			opt_S = @sprintf(" -So%.8gu/%.8gu", arg1.inc[1]*0.85, arg1.inc[2]*0.85)
			if     (haskey(d, :nbands))  opt_z = string("+z", d[:nbands])
			elseif (haskey(d, :Nbands))  opt_z = string("+Z", d[:Nbands])
			end
		end
		opt, = parse_R("", d, O)
		if (opt == "")							# OK, no R but we know it here so put it in 'd'
			if (arg1.registration == 1)			# Fine, grid is already pixel reg
				push!(d, :R => arg1.range)
			else								# Need to get a pix reg R
				range = deepcopy(arg1.range)
				range[1] = range[1] - arg1.inc[1] / 2;	range[2] = range[2] + arg1.inc[1] / 2;
				range[3] = range[3] - arg1.inc[2] / 2;	range[4] = range[4] + arg1.inc[2] / 2;
				push!(d, :R => range)
			end
		end
		arg1 = gmt("grd2xyz", arg1)[1]			# Now arg1 is a GMTdataset
	else
		opt_S = parse_inc("", d, [:width], "So", true)
		if (opt_S == "")
			if ((isa(arg1, Array) && size(arg1,2) < 5) || (isa(arg1, GMTdataset) && size(arg1.data,2) < 5) ||
				(isa(arg1, Array{GMT.GMTdataset,1}) && size(arg1[1].data,2) < 5))
				error("BAR3: When NOT providing *width* data must contain at least 5 columns.")
			end
		end
		if (!isletter(opt_S[end]))  opt_S = opt_S * 'u'  end
		if     (haskey(d, :nbands))  opt_z = string("+z", d[:nbands])
		elseif (haskey(d, :Nbands))  opt_z = string("+Z", d[:Nbands])
		end
	end

	opt = add_opt("", "",  d, [:base])	# No need to purge because base is not a psxy option
	if (opt == "")
		if (isa(arg1, Array))			# 1.05 means base is 5% below minimum
			opt_S = @sprintf("%s+b%.8g", opt_S, minimum(view(arg1, :, 3)) * 1.05)
		else
			opt_S = @sprintf("%s+b%.8g", opt_S, minimum(view(arg1.data, :, 3)) * 1.05)
		end
	else
		opt_S = opt_S * "+b" * opt
	end

	caller = "bar3|" * opt_S * opt_z

	GMT.common_plot_xyz(cmd0, arg1, caller, K, O, first, true, d...)
end

# ------------------------------------------------------------------------------------------------------
bar3(arg1; K=false, O=false, first=true, kw...) = bar3("", arg1; K=K, O=O, first=first, kw...)
bar3!(cmd0::String="", arg1=[]; K=true, O=true, first=false, kw...) = bar3(cmd0, arg1; K=K, O=O, first=first, kw...)
bar3!(arg1; K=true, O=true, first=false, kw...) = bar3("", arg1; K=K, O=O, first=first, kw...)

# ------------------------------------------------------------------------------------------------------
"""
    arrows(cmd0::String="", arg1=[], arrow=(...), kwargs...)

Reads a file or (x,y) pairs and plots an arrow field

When the keyword *arrow=(...)* or *vector=(...)* is used, the direction (in degrees counter-clockwise
from horizontal) and length must be found in columns 3 and 4, and size, if not specified on the
command-line, should be present in column 5. The size is the length of the vector head. Vector stem
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
- **W** : **pen** : **line_attrib** : -- Str --

    Set pen attributes for lines or the outline of symbols
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#w)

Example:

	arrows([0 8.2 0 6], limits=(-2,4,0,9), arrow=(len=2,stop=1,shape=0.5,fill=:red), J=14, frame=:a, pen="6p", show=true)
"""
function arrows(cmd0::String="", arg1=[]; K=false, O=false, first=true, kwargs...)
	# A arrows plotting method of plot

	d = KW(kwargs)
	cmd = helper_arrows(d)
	if (cmd == "")  cmd = " -Sv0.5+e+h0.5"	# Minimalist defaults
	else            cmd = " -S" * cmd
	end

	GMT.common_plot_xyz(cmd0, arg1, cmd, K, O, first, false, d...)
end

function helper_arrows(d::Dict)
	# Helper function to set the vector head attributes
	cmd = ""
	val, symb = find_in_dict(d, [:arrow :vector :vecmap :geovec :geovector])
	if (val !== nothing)
		code = 'v'
		if (symb == :geovec || symb == :geovector)
			code = '='
		elseif (symb == :vecmap)	# Uses azimuth and plots angles taking projection into account
			code = 'V'
		end
		if (isa(val, String))		# An hard core GMT string directly with options
			if (val[1] != code)  cmd = code * val
			else                 cmd = val			# The GMT string already had vector flag char
			end
		else
			cmd = code * vector_attrib(val)
		end
	end
	return cmd
end
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
arrows(arg1; K=false, O=false, first=true, kw...) = arrows("", arg1; K=K, O=O, first=first, kw...)
arrows!(cmd0::String="", arg1=[]; K=true, O=true, first=false, kw...) =
	arrows(cmd0, arg1; K=K, O=O, first=first, kw...)
arrows!(arg1; K=true, O=true, first=false, kw...) = arrows("", arg1; K=K, O=O, first=first, kw...)


# ------------------------------------------------------------------------------------------------------
"""
    lines(cmd0::String="", arg1=[], decorated=(...), kwargs...)

Reads a file or (x,y) pairs and plots a nice collection of different line with decorations

- $(GMT.opt_B)
- $(GMT.opt_J)
- $(GMT.opt_R)
- **W** : **pen** : **line_attrib** : -- Str --

    Set pen attributes for lines or the outline of symbols
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/plot.html#w)

Example:

	lines([0 0; 10 20], limits=(-2,12,-2,22), proj="M2.5", pen=1, fill=:red,
	      decorated=(dist=(val=1,size=0.25), symbol=:box), show=true)
"""
function lines(cmd0::String="", arg1=[]; K=false, O=false, first=true, kwargs...)
	# A lines plotting method of plot

	d = KW(kwargs)
	cmd = ""
	if (haskey(d, :decorated))
		if (isa(d[:decorated], String))		# A hard core GMT string directly with options, including -S
			cmd = " " * d[:decorated]
		else
			cmd = decorated(d[:decorated])
		end
	end

	GMT.common_plot_xyz(cmd0, arg1, cmd, K, O, first, false, d...)
end

# ------------------------------------------------------------------------------------------------------
function lines(arg1::AbstractArray, arg2::AbstractArray; K=false, O=false, first=true, kw...)
	arg = cat_2_arg2(arg1, arg2)	# If they are vectors, cat them into a Mx2 matrix
	lines("", arg; K=K, O=O, first=first, kw...)
end
function lines!(arg1::AbstractArray, arg2::AbstractArray; K=true, O=true, first=false, kw...)
	arg = cat_2_arg2(arg1, arg2)	# If they are vectors, cat them into a Mx2 matrix
	lines("", arg; K=K, O=O, first=first, kw...)
end

function lines(arg::AbstractArray; K=false, O=false, first=true, kw...)
	arg = cat_1_arg(arg)			# If ARG is a vector, prepend it with a 1:N x column
	lines("", arg; K=K, O=O, first=first, kw...)
end
function lines!(arg; K=true, O=true, first=false, kw...)
	#arg = cat_1_arg(arg)			# If ARG is a vector, prepend it with a 1:N x column
	lines("", cat_1_arg(arg); K=K, O=O, first=first, kw...)
end

lines!(cmd0::String="", arg=[]; K=true, O=true, first=false, kw...) =
	lines(cmd0, arg; K=K, O=O, first=first, kw...)

# ------------------------------------------------------------------------------------------------------
function cat_1_arg(arg)
	# When functions that expect matrices get only a vector, add a first col with 1:nx
	if (!isa(arg, Array{GMT.GMTdataset,1}) && (isa(arg, Vector) || isa(arg, UnitRange) || isa(arg, StepRangeLen)) )
		arg = hcat(1:length(arg), arg)
	end
	return arg
end

# ------------------------------------------------------------------------------------------------------
function cat_2_arg2(arg1, arg2)
	# Cat two vectors in a Mx2 matrix
	if (!isa(arg1, Array{GMT.GMTdataset,1}) && !isa(arg2, Array{GMT.GMTdataset,1}) &&
		(isa(arg1, Vector) || isa(arg1, UnitRange) || isa(arg1, StepRangeLen)) &&
		(isa(arg2, Vector) || isa(arg2, UnitRange) || isa(arg2, StepRangeLen)) )
		arg = hcat(arg1, arg2)
	else
		@show(isa(arg1, Vector) || isa(arg1, UnitRange))
		error("The two array args must be vectors or ONE column (or row) matrices.")
	end
end