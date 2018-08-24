"""
    greenspline(cmd0::String="", arg1=[]; kwargs...)

Reads randomly-spaced (x,y,z) triples and produces a binary grid file of gridded values z(x,y) by solving:
	
		(1 - T) * L (L (z)) + T * L (z) = 0

Full option list at [`greenspline`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html)

Parameters
----------

- $(GMT.opt_R)
- **I** : **inc** : -- Str or Number --
	*x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#i)
- **A** : **aspect_ratio** : -- Number --
    Aspect ratio. If desired, grid anisotropy can be added to the equations.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#a)
- **C** : **convergence** : -- Number --
	Convergence limit. Iteration is assumed to have converged when the maximum absolute change in any
	grid value is less than convergence_limit.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#c)
- **G** : **grid** : -- Str or [] --
	Optional output grid file name. If not provided return a GMTgrid type.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#g)
- **Ll** : **lower** : -- Str or Number --
	Impose limits on the output solution. lower sets the lower bound. lower can be the name of a grid
	file with lower bound values, a fixed value, d to set to minimum input value,
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#l)
- **Lu** : **upper** : -- Str or Number --
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#l)
- **N** : **max_iterations** : -- Number --
	Number of iterations. Iteration will cease when convergence_limit is reached or when number of
	iterations reaches max_iterations.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#n)
- **Q** : **suggest** : -- Bool or [] --
    Suggest grid dimensions which have a highly composite greatest common factor.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#q)
- **S** : **search_radius** : -- Number or Str --  
    Sets the resolution of the projected grid that will be created.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#s)
- **T** : **tension** : -- Number or Str --
    Tension factor[s]. These must be between 0 and 1.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#t)
- $(GMT.opt_V)
- **Z** : **over_relaxation** : -- Str or GMTgrid --
    Over-relaxation factor. This parameter is used to accelerate the convergence; it is a number between 1 and 2.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/greenspline.html#z)
- $(GMT.opt_bi)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_o)
- $(GMT.opt_x)
- $(GMT.opt_swap_xy)
"""
function greenspline(cmd0::String="", arg1=[]; data=[], kwargs...)

	length(kwargs) == 0 && isempty(data) && return monolitic("greenspline", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	cmd = ""
	cmd, opt_R = parse_R(cmd, d)
	cmd = parse_V(cmd, d)
	cmd, = parse_bi(cmd, d)
	cmd, = parse_d(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd = parse_o(cmd, d)
	cmd = parse_x(cmd, d)
	cmd = parse_swap_xy(cmd, d)
	cmd = parse_params(cmd, d)

	cmd = add_opt(cmd, 'A', d, [:A :gradfile])
	cmd = add_opt(cmd, 'C', d, [:C :approximate])
	cmd = add_opt(cmd, 'D', d, [:D :mode])
	cmd = add_opt(cmd, 'E', d, [:E :misfit])
	cmd = add_opt(cmd, 'G', d, [:G :grid])
	cmd = add_opt(cmd, 'I', d, [:I :inc])
	cmd = add_opt(cmd, "L", d, [:L :leave_trend])
	cmd = add_opt(cmd, 'N', d, [:N :nodefile])
	cmd = add_opt(cmd, 'Q', d, [:Q :direction_derivative])
	cmd = add_opt(cmd, 'S', d, [:S :splines])
	cmd = add_opt(cmd, 'T', d, [:T :maskgrid])
	cmd = add_opt(cmd, 'W', d, [:W :uncertainties])

	no_output = common_grd(cmd, 'G')		# See if an output is requested (or write result in grid file)
    cmd, arg1, = read_data(data, cmd, arg1)

	return common_grd(d, cmd0, cmd, arg1, [], no_output, "greenspline")	# Shared by several grdxxx modules
end

# ---------------------------------------------------------------------------------------------------
greenspline(arg1::GMTgrid, cmd0::String=""; data=[], kw...) = greenspline(cmd0, arg1; data=data, kw...)
greenspline(arg1::Array, cmd0::String=""; data=[], kw...) = greenspline(cmd0, arg1; data=data, kw...)