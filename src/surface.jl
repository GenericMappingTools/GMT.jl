"""
    surface(cmd0::String="", arg1=[]; fmt="", kwargs...)

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
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#e)
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
- $(GMT.opt_swappxy)
"""
# ---------------------------------------------------------------------------------------------------
function surface(cmd0::String="", arg1=[]; data=[], kwargs...)

	if (length(kwargs) == 0)		# Good, speed mode
		return gmt("surface " * cmd0)
	end

	if (!isempty_(data) && isa(data, Tuple) && !isa(data[1], GMTgrid))
		error("When 'data' is a tuple, it MUST contain a GMTgrid data type")
	end

	d = KW(kwargs)
	cmd = ""
	cmd, opt_R = parse_R(cmd, d)
	cmd, opt_J = parse_J(cmd, d)
	cmd = parse_V(cmd, d)
	cmd = parse_a(cmd, d)
	cmd, = parse_bi(cmd, d)
	cmd, = parse_di(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd = parse_r(cmd, d)
	cmd = parse_swappxy(cmd, d)
	cmd = add_opt(cmd, 'I', d, [:I :inc])

	cmd = add_opt(cmd, 'A', d, [:A :aspect_ratio])
	cmd = add_opt(cmd, 'C', d, [:C :convergence])
	cmd = add_opt(cmd, "Ll", d, [:Ll :lower])
	cmd = add_opt(cmd, "Lu", d, [:Ll :upper])
	cmd = add_opt(cmd, 'N', d, [:N :max_iterations])
	cmd = add_opt(cmd, 'Q', d, [:Q :suggest])
	cmd = add_opt(cmd, 'S', d, [:S :search_radius])
	cmd = add_opt(cmd, 'T', d, [:T :tension])
	cmd = add_opt(cmd, 'Z', d, [:Z :over_relaxation])

	if (!isempty_(data))
		if (!isempty_(arg1))
			warn("Conflicting ways of providing input data. Both a file name via positional and
				  a data array via kwyword args were provided. Ignoring later argument")
		else
			if (isa(data, String)) 		# OK, we have data via file
				cmd = cmd * " " * data
			else
				arg1 = data				# Whatever this is
			end
		end
	end

	(haskey(d, :Vd)) && println(@sprintf("\tsurface %s", cmd))

	G = nothing
	if (contains(cmd, "-Q"))
		if (!isempty_(arg1))  gmt("surface " * cmd, arg1)
		else                  gmt("surface " * cmd)
		end
	else
		if (!isempty_(arg1))  G = gmt("surface " * cmd, arg1)
		else                  G = gmt("surface " * cmd)
		end
	end
	return G
end

# ---------------------------------------------------------------------------------------------------
surface(arg1::GMTgrid, cmd0::String=""; data=[], kw...) = surface(cmd0, arg1; data=data, kw...)
surface(arg1::Array, cmd0::String=""; data=[], kw...) = surface(cmd0, arg1; data=data, kw...)