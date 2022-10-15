"""
    surface(cmd0::String="", arg1=nothing; kwargs...)

Reads randomly-spaced (x,y,z) triples and produces a binary grid file of gridded values z(x,y) by solving:
	
		(1 - T) * L (L (z)) + T * L (z) = 0

Full option list at [`surface`]($(GMTdoc)surface.html)

Parameters
----------

- $(GMT._opt_R)
- $(GMT.opt_I)
    ($(GMTdoc)surface.html#i)
- **A** | **aspect_ratio** :: [Type => Number]

    Aspect ratio. If desired, grid anisotropy can be added to the equations.
    ($(GMTdoc)surface.html#a)
- **C** | **convergence** :: [Type => Number]

    Convergence limit. Iteration is assumed to have converged when the maximum absolute change in any
    grid value is less than convergence_limit.
    ($(GMTdoc)surface.html#c)
- **D** | **breakline** :: [Type => String | NamedTuple]     `Arg = breakline[+z[level]] | (data=Array, [zlevel=x])`

    Use xyz data in the breakline file as a ‘soft breakline’, that is a line whose vertices will be used to
    constrain the nearest grid nodes without any further interpolation.
    ($(GMTdoc)surface.html#d)
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = surface(....) form.
    ($(GMTdoc)surface.html#g)
- **Ll** | **lower** :: [Type => Str | Number]

    Impose limits on the output solution. lower sets the lower bound. lower can be the name of a grid
    file with lower bound values, a fixed value, d to set to minimum input value,
    ($(GMTdoc)surface.html#l)
- **Lu** | **upper** :: [Type => Str | Number]

    ($(GMTdoc)surface.html#l)
- **M** | **mask** :: [Type => Number]      `Arg = max_radius`

    After solving for the surface, apply a mask so that nodes farther than max_radius away from a data constraint is set to NaN.
    ($(GMTdoc)surface.html#m)
- **N** | **iterations** | **max_iterations** :: [Type => Number]

    Number of iterations. Iteration will cease when convergence_limit is reached or when number of
    iterations reaches max_iterations.
    ($(GMTdoc)surface.html#n)
- **Q** | **suggest** :: [Type => Bool]

    Suggest grid dimensions which have a highly composite greatest common factor.
    ($(GMTdoc)surface.html#q)
- **S** | **search_radius** :: [Type => Number | Str]  

    Sets the resolution of the projected grid that will be created.
    ($(GMTdoc)surface.html#s)
- **T** | **tension** :: [Type => Number | Str]

    Tension factor[s]. These must be between 0 and 1.
    ($(GMTdoc)surface.html#t)
- $(GMT.opt_V)
- **W** | **log** :: [Type => Str]

    Write convergence information to a log file [surface_log.txt].
    ($(GMTdoc)surface.html#w)
- **Z** | **over_relaxation** :: [Type => Str | GMTgrid]

    Over-relaxation factor. This parameter is used to accelerate the convergence; it is a number between 1 and 2.
    ($(GMTdoc)surface.html#z)
- $(GMT.opt_a)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_r)
- $(GMT.opt_w)
- $(GMT.opt_swap_xy)
"""
function surface(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	arg2 = nothing
	
	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :a :bi :di :e :f :h :i :w :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :aspect_ratio], [:C :convergence], [:Ll :lower], [:Lu :upper], [:M :mask],
	                                  [:N :iterations :max_iterations], [:Q :suggest], [:S :search_radius], [:T :tension], [:W :log], [:Z :over_relaxation]])
	cmd, args, n, = add_opt(d, cmd, "D", [:D :breakline], :data, Array{Any,1}([arg1, arg2]), (zlevel="+z",))
	(!contains(cmd, " -R") && !isempty(CTRL.pocket_R[1])) && (cmd *= " -R")
	if (n > 0)  arg1, arg2 = args[:]  end

	common_grd(d, cmd0, cmd, "surface ", arg1, arg2)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
surface(arg1, cmd0::String=""; kw...) = surface(cmd0, arg1; kw...)
