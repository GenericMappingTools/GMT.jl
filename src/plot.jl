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
	opt_G = add_opt("", 'G', d, [:G :fill :markerfacecolor], true)
	opt_W = add_opt("", 'W', d, [:markeredgecolor], true)

	opt_S = get_marker_name(d, [:symbol :marker], true)
	if (isempty(opt_S))  opt_S = " -Sc"
	else                 opt_S = " -S" * opt_S
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

	if (opt == "")  	opt  = "8p"		end		# Default to 8p
	if (opt_G == "")	opt_G = " -G0"	end
	caller = opt_S * opt * opt_G * opt_W		# Piggy-back this

	if (is3D)
		opt = add_opt("", 'p', d, [:p :view], true)
		if (opt == "")  caller = caller * " -p200/30"
		else            caller = caller * opt
		end
	end

	GMT.common_plot_xyz(cmd0, arg1, caller, K, O, first, is3D, d...)
end
# ------------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------------
function bar(arg1::AbstractArray, arg2::AbstractArray; K=false, O=false, first=true, kw...)
	if ((size(arg1,2) == 1 || size(arg1,1) == 1) && (size(arg2,2) == 1 || size(arg2,1) == 1))
		arg = hcat(arg1[:], arg2[:])
	else
		error("BARPLOT: The two array args must be vectors or ONE column (or row) matrices.")
	end
	bar("", arg; K=K, O=O, first=first, kw...)
end
function bar(arg::AbstractArray; K=false, O=false, first=true, kw...)
	if (size(arg,2) == 1 || size(arg,1) == 1)
		x = collect(1:length(arg))
		arg1 = [x arg[:]]
	end
	bar("", arg; K=K, O=O, first=first, kw...)
end
function bar!(arg1::AbstractArray, arg2::AbstractArray; K=true, O=true, first=false, kw...)
	if ((size(arg1,2) == 1 || size(arg1,1) == 1) && (size(arg2,2) == 1 || size(arg2,1) == 1))
		arg = hcat(arg1[:], arg2[:])
	else
		error("BARPLOT: The two array args must be vectors or ONE column (or row) matrices.")
	end
	bar("", arg; K=K, O=O, first=first, kw...)
end
function bar!(arg::AbstractArray; K=true, O=true, first=false, kw...)
	if (size(arg,2) == 1 || size(arg,1) == 1)
		x = collect(1:length(arg))
		arg1 = [x arg[:]]
	end
	bar("", arg; K=K, O=O, first=first, kw...)
end

# ------------------------------------------------------------------------------------------------------
function bar(cmd0::String="", arg1=[]; K=false, O=false, first=true, kwargs...)

	if (isa(arg1, Array{GMT.GMTdataset,1}))		# Shitty consequence of arg1 being the output of a prev cmd
		arg1 = arg1[1]
	end

	if (isempty(cmd0) && isa(arg1, AbstractArray) && size(arg1,2) == 1 || size(arg1,1) == 1)	# y only
		arg1 = hcat(1:length(arg1), arg1[:])
	end

	d = KW(kwargs)
	opt_G = add_opt("", 'G', d, [:G :fill], true)
	if (opt_G == "")	opt_G = " -G0/115/190"	end	# Default bar color

	opt_S = add_opt("", "Sb",  d, [:size], true)
	if (opt_S == "")
		opt = add_opt("", "",  d, [:width])		# No need to purge because width is not a psxy option
		if (opt == "")	opt = "0.8"	end			# The default
		opt_S = " -Sb" * opt * "u"
	end

	optB = add_opt("", "",  d, [:bottom :base])	# No need to purge because bottom is not a psxy option
	if (optB == "")	optB = "0"	end
	optB = "+b" * optB

	caller = opt_G * opt_S * optB				# Piggy-back this

	GMT.common_plot_xyz(cmd0, arg1, caller, K, O, first, false, d...)
end

# ------------------------------------------------------------------------------------------------------
bar3!(arg1; K=true, O=true, first=false, kw...) = bar3(arg1; K=K, O=O, first=first, kw...)

# ------------------------------------------------------------------------------------------------------
function bar3(arg; K=false, O=false, first=true, kwargs...)
#
	d = KW(kwargs)

	arg1 = arg			# Make a copy that may or not become a new thing
	if (isa(arg1, Array{GMT.GMTdataset,1}))		# Shitty consequence of arg1 being the output of a prev cmd
		arg1 = arg1[1]
	end

	if (isa(arg1, Array))
		ny, nx = size(arg1)
		if ((nx > 3 && ny > 3))					# Assume it is a 'bare grid'
			arg1 = mat2grid(arg1)
		end
	end

	if (isa(arg1, GMTgrid))
		opt_S = @sprintf(" -So%.8gu/%.8gu", arg1.inc[1]*0.80, arg1.inc[2]*0.80)
		opt, = parse_R("", d, O)
		if (opt == "")							# OK, no R but we know it here so put it in 'd'
			push!(d, :R => arg1.range)
		end
		arg1 = gmt("grd2xyz", arg1)[1]			# Now arg1 is a GMTdataset
	else
		opt_S = parse_inc("", d, [:size :width], "So", true)
		if (opt_S == "")	error("BAR3: must provide the column bar width.")	end
	end

	if (!isa(arg1, Array) && !isa(arg1, GMTdataset))
		error(@sprintf("I don't know how this datatype (%s) managed to make it's way here but can't use it.", typeof(arg1)))
	end

	opt = add_opt("", "",  d, [:bottom :base])	# No need to purge because bottom is not a psxy option
	if (opt == "")
		if (isa(arg1, Array))
			opt_S = @sprintf("%s+b%.8g", opt_S, minimum(view(arg1, :, 3)) * 1.05)
		else
			opt_S = @sprintf("%s+b%.8g", opt_S, minimum(view(arg1.data, :, 3)) * 1.05)
		end
	else
		opt_S = opt_S * "+b" * opt
	end

	opt_G = add_opt("", 'G', d, [:G :fill], true)
	if (opt_G == "")	opt_G = " -G0/115/190"	end		# Default bar color

	opt_J, = parse_J("", d, true, false, true)			# Trim it if exists in d
	if (opt_J == "")	opt_J = " -JX12c/0"		end		# Default fig size

	#s = split(opt_R[4:end], "/")
	#R = [parse(Float64, s[k]) for k = 1:length(s)]

	caller = opt_G * opt_S * opt_J						# Piggy-back this
	opt = add_opt("", 'p', d, [:p :view], true)
	if (opt == "")  caller = caller * " -p200/30"	end

	GMT.common_plot_xyz("", arg1, caller, K, O, first, true, d...)
end

# ------------------------------------------------------------------------------------------------------
function arrows(cmd0::String="", arg1=[]; K=false, O=false, first=true, kwargs...)

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
	for symb in [:arrow :vector :vecmap :geovec :geovector]
		if (haskey(d, symb))
			code = "v"
			if (symb == :geovec || symb == :geovector)
				code = "="
			elseif (symb == :vecmap)		# Uses azimuth and plots angles taking projection into account
				code = "V"
			end
			if (isa(d[symb], String))		# An hard core GMT string directly with options
				cmd = code * d[symb]
			else
				cmd = code * vector_attrib(d[symb])
			end
			break
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
function lines(cmd0::String="", arg1=[]; K=false, O=false, first=true, kwargs...)

	d = KW(kwargs)
	cmd = ""
	if (haskey(d, :decorated))
		if (isa(d[:decorated], String))		# A hard core GMT string directly with options, including -S
			cmd = " " * d[:decorated]
		else
			cmd = decorated(d[:decorated])
		end
	end

	if (!occursin("+p", cmd))					# If no pen was specified search for a -W
		pen = add_opt_pen(d, [:W :pen], "W", true)
		if (pen == "")
			cmd = cmd * " -W0.25p"				# Do not leave without a pen specification
		else
			cmd = cmd * pen
			if (haskey(d, :bezier))  cmd = cmd * "+s"  end
			if (haskey(d, :offset))  cmd = cmd * "+o" * arg2str(d[:offset]);	delete!(d, :offset)  end
			# Search for eventual vec specs
			r = helper_arrows(d)
			if (r != "")
				if     (haskey(d, :vec_start))  cmd = cmd * "+vb" * r[2:end]	# r[1] = 'v'
				elseif (haskey(d, :vec_stop))   cmd = cmd * "+ve" * r[2:end]
				else   cmd = cmd * "+" * r
				end
			end
		end
	end

	GMT.common_plot_xyz(cmd0, arg1, cmd, K, O, first, false, d...)
end

# ------------------------------------------------------------------------------------------------------
lines(arg1; K=false, O=false, first=true, kw...) = lines("", arg1; K=K, O=O, first=first, kw...)

lines!(cmd0::String="", arg1=[]; K=true, O=true, first=false, kw...) =
	lines(cmd0, arg1; K=K, O=O, first=first, kw...)
lines!(arg1; K=true, O=true, first=false, kw...) = lines("", arg1; K=K, O=O, first=first, kw...)