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
plot3d(arg1::Array; extra="", data=[], K=false, O=false, first=true, kw...) =
    GMT.xyz(extra, arg1; caller="plot3d", data=data, K=K, O=O, first=first, kw...)
plot3d!(arg1::Array; extra="", data=[], K=false, O=false, first=true, kw...) =
    GMT.xyz(extra, arg1; caller="plot3d", data=data, K=true, O=true, first=false, kw...)

# -----------------------------------------------------------------------------------------------------
plot3d(arg1::GMTdataset; extra="", data=[], K=false, O=false, first=true, kw...) =
	GMT.xyz(extra, arg1; caller="plot3d", data=data, K=K, O=O, first=first, kw...)
plot3d!(arg1::GMTdataset; extra="", data=[], K=false, O=false, first=true, kw...) =
	GMT.xyz(extra, arg1; caller="plot3d", data=data, K=true, O=true, first=false, kw...)
plot3d(arg1::Array{GMTdataset,1}; extra="", data=[], K=false, O=false, first=true, kw...) =
	GMT.xyz(extra, arg1; caller="plot3d", data=data, K=K, O=O, first=first, kw...)
plot3d!(arg1::Array{GMTdataset,1}; extra="", data=[], K=false, O=false, first=true, kw...) =
	GMT.xyz(extra, arg1; caller="plot3d", data=data, K=true, O=true, first=false, kw...)

# ------------------------------------------------------------------------------------------------------
plot3d(arg1::String; extra="", data=[], K=false, O=false, first=true, kw...) =
	GMT.xyz(extra, []; caller="plot3d", data=arg1, K=K, O=O, first=first, kw...)
plot3d!(arg1::String; extra="", data=[], K=false, O=false, first=true, kw...) =
	GMT.xyz(extra, []; caller="plot3d", data=arg1, K=true, O=true, first=false, kw...)

# ------------------------------------------------------------------------------------------------------
function plot3d(arg1::Array, arg2::Array; extra="", data=[], K=false, O=false, first=true, kw...)
	arg = hcat(arg1, arg2)
	GMT.xyz(extra, arg; caller="plot3d", data=[], K=K, O=O, first=first, kw...)
end
function plot3d!(arg1::Array, arg2::Array; extra="", data=[], K=false, O=false, first=true, kw...)
	arg = hcat(arg1, arg2)
	GMT.xyz(extra, arg; caller="plot3d", data=[], K=true, O=true, first=false, kw...)
end
# ------------------------------------------------------------------------------------------------------