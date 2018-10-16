"""
plot(arg1::Array; kwargs...)

reads (x,y) pairs from files [or standard input] and generates PostScript code that will plot lines,
polygons, or symbols at those locations on a map.

Full option list at [`psxy`](http://gmt.soest.hawaii.edu/doc/latest/psxy.html)

Parameters
----------

- **A** : **straight_lines** : -- Str --  

	By default, geographic line segments are drawn as great circle arcs. To draw them as straight lines, use the -A flag.
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
plot(arg1::Array; extra="", K=false, O=false, first=true, kw...) =
	GMT.xy(extra, arg1; caller="plot", K=K, O=O, first=first, kw...)
plot!(arg1::Array; extra="", K=false, O=false, first=true, kw...) =
	GMT.xy(extra, arg1; caller="plot", K=true, O=true, first=false, kw...)

# -----------------------------------------------------------------------------------------------------
plot(arg1::GMTdataset; extra="", K=false, O=false, first=true, kw...) =
	GMT.xy(extra, arg1; caller="plot", K=K, O=O, first=first, kw...)
plot!(arg1::GMTdataset; extra="", K=false, O=false, first=true, kw...) =
	GMT.xy(extra, arg1; caller="plot", K=true, O=true, first=false, kw...)
plot(arg1::Array{GMTdataset,1}; extra="", K=false, O=false, first=true, kw...) =
	GMT.xy(extra, arg1; caller="plot", K=K, O=O, first=first, kw...)
plot!(arg1::Array{GMTdataset,1}; extra="", K=false, O=false, first=true, kw...) =
	GMT.xy(extra, arg1; caller="plot", K=true, O=true, first=false, kw...)

# ------------------------------------------------------------------------------------------------------
plot(arg1::String; extra="", K=false, O=false, first=true, kw...) =
	GMT.xy(extra, []; caller="plot", K=K, O=O, first=first, kw...)
plot!(arg1::String; extra="", K=true, O=true, first=false, kw...) =
	GMT.xy(extra, []; caller="plot", K=K, O=O, first=first, kw...)

# ------------------------------------------------------------------------------------------------------
function plot(arg1::Array, arg2::Array; extra="", K=false, O=false, first=true, kw...)
	arg = hcat(arg1, arg2)
	GMT.xy(extra, arg; caller="plot",  K=K, O=O, first=first, kw...)
end
function plot!(arg1::Array, arg2::Array; extra="", K=false, O=false, first=true, kw...)
	arg = hcat(arg1, arg2)
	GMT.xy(extra, arg; caller="plot",  K=true, O=true, first=false, kw...)
end
# ------------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------------
scatter(arg1; K=false, O=false, first=true, kw...) = scatter("", arg1; K=K, O=O, first=first, is3D=false, kw...)
scatter!(arg1; K=true, O=true, first=false, kw...) = scatter("", arg1; K=K, O=O, first=first, is3D=false, kw...)
scatter3(arg1; K=false, O=false, first=true, kw...) = scatter("", arg1; K=K, O=O, first=first, is3D=true, kw...)
scatter3!(arg1; K=true, O=true, first=false, kw...) = scatter("", arg1; K=K, O=O, first=first, is3D=true, kw...)

function scatter(arg1::AbstractArray, arg2::AbstractArray; K=false, O=false, first=true, kw...)
	if ((size(arg1,2) == 1 || size(arg1,1) == 1) && (size(arg2,2) == 1 || size(arg2,1) == 1))
		arg = hcat(arg1[:], arg2[:])
	else
		error("SCATTER: The two array args must be vectors or ONE column (or row) matrices.")
	end
	scatter("", arg; K=K, O=O, first=first, is3D=false, kw...)
end
function scatter!(arg1::AbstractArray, arg2::AbstractArray; K=true, O=true, first=false, kw...)
	if ((size(arg1,2) == 1 || size(arg1,1) == 1) && (size(arg2,2) == 1 || size(arg2,1) == 1))
		arg = hcat(arg1[:], arg2[:])
	else
		error("SCATTER: The two array args must be vectors or ONE column (or row) matrices.")
	end
	scatter("", arg; K=K, O=O, first=first, is3D=false, kw...)
end
function scatter3(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; K=false, O=false, first=true, kw...)
	arg = hcat(arg1, arg2, arg3)
	scatter("", arg; K=K, O=O, first=first, is3D=true, kw...)
end
function scatter3!(arg1::AbstractArray, arg2::AbstractArray, arg3::AbstractArray; K=true, O=true, first=false, kw...)
	arg = hcat(arg1, arg2, arg3)
	scatter("", arg; K=K, O=O, first=first, is3D=true, kw...)
end

# ------------------------------------------------------------------------------------------------------
function scatter(cmd0::String="", arg1=[]; K=false, O=false, first=true, is3D=false, kwargs...)

	if (isempty(cmd0) && isa(arg1, AbstractArray) && size(arg1,2) == 1 || size(arg1,1) == 1)	# y only
		arg1 = hcat(1:length(arg1), arg1[:])
	end

	d = KW(kwargs)
	optG = add_opt("", 'G', d, [:G :fill :markerfacecolor], true)
	optW = add_opt("", 'W', d, [:markeredgecolor], true)

	optS = get_marker_name(d, [:symbol :marker], true)
	if (isempty(optS))  optS = " -Sc"
	else                optS = " -S" * optS
	end

	opt = ""
	for symb in [:size :markersize]
		if (haskey(d, symb))
			if (isa(d[symb], AbstractArray))
				if (length(d[symb]) == size(arg1,1))
					arg1 = hcat(arg1, d[symb][:])
					opt = " "		# Just to defeat the empty test below
				else
					error("SCATTER: The size array must have the same number of elements rows in the data")
				end
			else
				opt = arg2str(d[symb])
			end
			delete!(d, symb)
			break
		end
	end

	if (opt == "")  opt  = "8p"		end		# Default to 8p
	if (optG == "")	optG = " -G0"	end
	caller = optS * opt * optG * optW		# Piggy-back this

	if (is3D)
		opt = add_opt("", 'p', d, [:p :view :perspective], true)
		if (opt == "")  caller = caller * " -p170/45"
		else            caller = caller * opt
		end
	end

	GMT.common_plot_xyz(cmd0, arg1, caller, K, O, first, is3D, d...)
end
# ------------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------------
function barplot(arg1::AbstractArray, arg2::AbstractArray; K=false, O=false, first=true, kw...)
	if ((size(arg1,2) == 1 || size(arg1,1) == 1) && (size(arg2,2) == 1 || size(arg2,1) == 1))
		arg = hcat(arg1[:], arg2[:])
	else
		error("BARPLOT: The two array args must be vectors or ONE column (or row) matrices.")
	end
	barplot("", arg; K=K, O=O, first=first, is3D=false, kw...)
end
function barplot(arg::AbstractArray; K=false, O=false, first=true, kw...)
	if (size(arg,2) == 1 || size(arg,1) == 1)
		x = collect(1:length(arg))
		arg1 = [x arg[:]]
	end
	barplot("", arg; K=K, O=O, first=first, is3D=false, kw...)
end
function barplot!(arg1::AbstractArray, arg2::AbstractArray; K=true, O=true, first=false, kw...)
	if ((size(arg1,2) == 1 || size(arg1,1) == 1) && (size(arg2,2) == 1 || size(arg2,1) == 1))
		arg = hcat(arg1[:], arg2[:])
	else
		error("BARPLOT: The two array args must be vectors or ONE column (or row) matrices.")
	end
	barplot("", arg; K=K, O=O, first=first, is3D=false, kw...)
end
function barplot!(arg::AbstractArray; K=true, O=true, first=false, kw...)
	if (size(arg,2) == 1 || size(arg,1) == 1)
		x = collect(1:length(arg))
		arg1 = [x arg[:]]
	end
	barplot("", arg; K=K, O=O, first=first, is3D=false, kw...)
end
# ------------------------------------------------------------------------------------------------------
function barplot(cmd0::String="", arg1=[]; K=false, O=false, first=true, is3D=false, kwargs...)

	if (isempty(cmd0) && isa(arg1, AbstractArray) && size(arg1,2) == 1 || size(arg1,1) == 1)	# y only
		arg1 = hcat(1:length(arg1), arg1[:])
	end

	d = KW(kwargs)
	optG = add_opt("", 'G', d, [:G :fill], true)

	optS = add_opt("", "Sb",  d, [:size], true)
	if (optS == "")
		optW = add_opt("", "",  d, [:width])	# No need to purge because width is not a psxy option
		if (optW == "")	optW = "0.8"	end		# The default
		optS = " -Sb" * optW * "u"
	end


	optB = add_opt("", "",  d, [:bottom])		# No need to purge because bottom is not a psxy option
	if (optB == "")	optB = "0"	end
	optB = "+b" * optB

	caller = optG * optS * optB				# Piggy-back this

	GMT.common_plot_xyz(cmd0, arg1, caller, K, O, first, is3D, d...)
end