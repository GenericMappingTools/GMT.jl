"""
    greenspline(cmd0::String="", arg1=nothing; kwargs...)

Reads randomly-spaced (x,y,z) triples and produces a binary grid file of gridded values z(x,y) by solving:
	
		(1 - T) * L (L (z)) + T * L (z) = 0

Full option list at [`greenspline`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html)

Parameters
----------

- $(GMT.opt_R)
- **I** : **inc** : -- Str or Number --

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#i)
- **A** : **gradient** : -- Str --		``Flags = gradfile+f1|2|3|4|5``

    The solution will partly be constrained by surface gradients v = v*n, where v is the
    gradient magnitude and n its unit vector direction.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#a)
- **C** : **approx** : **approximate** : -- Str or Number --	``Flags = [n]value[+ffile]``

    Find an approximate surface fit: Solve the linear system for the spline coefficients by
    SVD and eliminate the contribution from all eigenvalues whose ratio to the largest
    eigenvalue is less than value.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#c)
- **G** : **grid** : -- Str or [] --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = greenspline(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#g)
- **D** : **mode** : -- Number --

    Sets the distance flag that determines how we calculate distances between data points.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#d)
- **E** : **misfit** : -- Str or [] --		``Flags = [misfitfile]``

    Evaluate the spline exactly at the input data locations and report statistics of
    the misfit (mean, standard deviation, and rms).
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#e)
- **L** : **leave_trend** : -- Bool or [] --

    Do not remove a linear (1-D) or planer (2-D) trend when -D selects mode 0-3.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#L)
- **N** : **nodes** : -- Number --			``Flags = nodefile``

    ASCII file with coordinates of desired output locations x in the first column(s).
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#n)
- **Q** : **dir_derivative** : -- Str --		``Flags = az|x/y/z``

    Rather than evaluate the surface, take the directional derivative in the az azimuth and
    return the magnitude of this derivative instead.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#q)
- **S** : **splines** : -- Str --				``Flags = c|t|l|r|p|q[pars]``

    Select one of six different splines. The first two are used for 1-D, 2-D, or 3-D Cartesian splines.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#s)

- **T** : **mask** : -- Str --					``Flags = maskgrid``

    For 2-D interpolation only. Only evaluate the solution at the nodes in the maskgrid that are
    not equal to NaN.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#t)
- $(GMT.opt_V)
- **W** : **uncertainties** : -- Str or [] --	``Flags = [w]``

	Data one-sigma uncertainties are provided in the last column. We then compute weights that
	are inversely proportional to the uncertainties squared.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#w)
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

    d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :bi :d :e :f :h :i :o :r :x :yx])
	cmd = parse_these_opts(cmd, d, [[:A :gradient], [:C :approx :approximate], [:D :mode], [:E :misfit],
				[:G :grid], [:I :inc], [:L :leave_trend], [:N :nodes], [:Q :dir_derivative], [:S :splines],
				[:T :mask], [:W :uncertainties]])

	common_grd(d, cmd0, cmd, "greenspline ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
greenspline(arg1, cmd0::String=""; kw...) = greenspline(cmd0, arg1; kw...)