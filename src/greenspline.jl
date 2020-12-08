"""
    greenspline(cmd0::String="", arg1=nothing; kwargs...)

Reads randomly-spaced (x,y,z) triples and produces a binary grid file of gridded values z(x,y) by solving:
	
		(1 - T) * L (L (z)) + T * L (z) = 0

Full option list at [`greenspline`]($(GMTdoc)greenspline.html)

Parameters
----------

- $(GMT.opt_R)
- **I** | **inc** :: [Type => Str | Number]

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    ($(GMTdoc)greenspline.html#i)
- **A** | **gradient** :: [Type => Str | Array]		``Arg = gradfile+f1|2|3|4|5 | (data=Array, format=x)``

    The solution will partly be constrained by surface gradients v = v*n, where v is the
    gradient magnitude and n its unit vector direction.
    ($(GMTdoc)greenspline.html#a)
- **C** | **approx** | **approximate** :: [Type => Str | Number]	``Arg = [n]value[+ffile]``

    Find an approximate surface fit: Solve the linear system for the spline coefficients by
    SVD and eliminate the contribution from all eigenvalues whose ratio to the largest
    eigenvalue is less than value.
    ($(GMTdoc)greenspline.html#c)
- **G** | **grid** :: [Type => Str | []]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = greenspline(....) form.
    ($(GMTdoc)greenspline.html#g)
- **D** | **mode** :: [Type => Number]

    Sets the distance flag that determines how we calculate distances between data points.
    ($(GMTdoc)greenspline.html#d)
- **E** :|**misfit** :: [Type => Str | []]		``Arg = [misfitfile]``

    Evaluate the spline exactly at the input data locations and report statistics of
    the misfit (mean, standard deviation, and rms).
    ($(GMTdoc)greenspline.html#e)
- **L** | **leave_trend** :: [Type => Bool]

    Do not remove a linear (1-D) or planer (2-D) trend when -D selects mode 0-3.
    ($(GMTdoc)greenspline.html#l)
- **N** | **nodes** :: [Type => Number | Array]			``Arg = nodefile``

    ASCII file with coordinates of desired output locations x in the first column(s).
    ($(GMTdoc)greenspline.html#n)
- **Q** | **dir_derivative** :: [Type => Str]		``Arg = az|x/y/z``

    Rather than evaluate the surface, take the directional derivative in the az azimuth and
    return the magnitude of this derivative instead.
    ($(GMTdoc)greenspline.html#q)
- **S** | **splines** :: [Type => Str]				``Arg = c|t|l|r|p|q[pars]``

    Select one of six different splines. The first two are used for 1-D, 2-D, or 3-D Cartesian splines.
    ($(GMTdoc)greenspline.html#s)
- **T** | **mask** :: [Type => Str]					``Arg = maskgrid``

    For 2-D interpolation only. Only evaluate the solution at the nodes in the maskgrid that are
    not equal to NaN.
    ($(GMTdoc)greenspline.html#t)
- $(GMT.opt_V)
- **W** | **uncertainties** :: [Type => Str | []]	``Arg = [w]``

	Data one-sigma uncertainties are provided in the last column. We then compute weights that
	are inversely proportional to the uncertainties squared.
    ($(GMTdoc)greenspline.html#w)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_o)
- $(GMT.opt_r)
- $(GMT.opt_x)
- $(GMT.opt_swap_xy)
"""
function greenspline(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("greenspline", cmd0, arg1)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	arg2 = nothing;     arg3 = nothing

	cmd, = parse_common_opts(d, "", [:R :V_params :bi :d :e :f :h :i :o :r :x :yx])
	cmd  = parse_these_opts(cmd, d, [[:C :approx :approximate], [:D :mode], [:E :misfit],
	                                 [:G :grid], [:I :inc], [:L :leave_trend], [:Q :dir_derivative], [:S :splines], [:T :mask], [:W :uncertainties]])
	cmd, args, n, = add_opt(d, cmd, 'A', [:A :gradient], :data, Array{Any,1}([arg1, arg2]), (format="+f",))
	if (n > 0)  arg1, arg2 = args[:]  end
	cmd, args, n, = add_opt(d, cmd, 'N', [:N :nodes], :data, Array{Any,1}([arg1, arg2, arg3]), (x="",))
	if (n > 0)  arg1, arg2, arg3 = args[:]  end

	common_grd(d, cmd0, cmd, "greenspline ", arg1, arg2, arg3)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
greenspline(arg1, cmd0::String=""; kw...) = greenspline(cmd0, arg1; kw...)