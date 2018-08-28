"""
    surface(cmd0::String="", arg1=[]; kwargs...)

Reads randomly-spaced (x,y,z) triples and produces a binary grid file of gridded values z(x,y) by solving:
	
		(1 - T) * L (L (z)) + T * L (z) = 0

Full option list at [`surface`](http://gmt.soest.hawaii.edu/doc/latest/surface.html)

Parameters
----------

- $(GMT.opt_R)
- **I** : **inc** : -- Str or Number --

	*x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#i)
- **A** : **aspect_ratio** : -- Number --

    Aspect ratio. If desired, grid anisotropy can be added to the equations.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#a)
- **C** : **convergence** : -- Number --

	Convergence limit. Iteration is assumed to have converged when the maximum absolute change in any
	grid value is less than convergence_limit.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#c)
- **G** : **outgrid** : -- Str --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = surface(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#g)
- **Ll** : **lower** : -- Str or Number --

	Impose limits on the output solution. lower sets the lower bound. lower can be the name of a grid
	file with lower bound values, a fixed value, d to set to minimum input value,
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#l)
- **Lu** : **upper** : -- Str or Number --

    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#l)
- **N** : **max_iterations** : -- Number --

	Number of iterations. Iteration will cease when convergence_limit is reached or when number of
	iterations reaches max_iterations.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#n)
- **Q** : **suggest** : -- Bool or [] --

    Suggest grid dimensions which have a highly composite greatest common factor.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#q)
- **S** : **search_radius** : -- Number or Str --  

    Sets the resolution of the projected grid that will be created.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#s)
- **T** : **tension** : -- Number or Str --

    Tension factor[s]. These must be between 0 and 1.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#t)
- $(GMT.opt_V)
- **Z** : **over_relaxation** : -- Str or GMTgrid --

    Over-relaxation factor. This parameter is used to accelerate the convergence; it is a number between 1 and 2.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#z)
- $(GMT.opt_a)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_r)
- $(GMT.opt_swap_xy)
"""
function surface(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("surface", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	cmd, = parse_R("", d)
	cmd = parse_V_params(cmd, d)
	cmd, = parse_a(cmd, d)
	cmd, = parse_bi(cmd, d)
	cmd, = parse_di(cmd, d)
	cmd, = parse_e(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd, = parse_r(cmd, d)
	cmd, = parse_swap_xy(cmd, d)

	cmd = add_opt(cmd, 'A', d, [:A :aspect_ratio])
	cmd = add_opt(cmd, 'C', d, [:C :convergence])
	cmd = add_opt(cmd, 'G', d, [:G :grid :outgrid])
	cmd = add_opt(cmd, 'I', d, [:I :inc])
	cmd = add_opt(cmd, "Ll", d, [:Ll :lower])
	cmd = add_opt(cmd, "Lu", d, [:Ll :upper])
	cmd = add_opt(cmd, 'N', d, [:N :max_iterations])
	cmd = add_opt(cmd, 'Q', d, [:Q :suggest])
	cmd = add_opt(cmd, 'S', d, [:S :search_radius])
	cmd = add_opt(cmd, 'T', d, [:T :tension])
	cmd = add_opt(cmd, 'Z', d, [:Z :over_relaxation])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "surface", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
surface(arg1=[], cmd0::String=""; kw...) = surface(cmd0, arg1; kw...)