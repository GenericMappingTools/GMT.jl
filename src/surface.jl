"""
    surface(cmd0::String="", arg1=nothing; kwargs...)

Reads randomly-spaced (x,y,z) triples and produces a binary grid file of gridded values z(x,y) by solving:
	
		(1 - T) * L (L (z)) + T * L (z) = 0

See full GMT (not the `GMT.jl` one) docs at [`surface`]($(GMTdoc)surface.html)

Parameters
----------

- $(_opt_R)
- $(opt_I)
- **A** | **aspect_ratio** :: [Type => Number]

    Aspect ratio. If desired, grid anisotropy can be added to the equations.
- **C** | **convergence** :: [Type => Number]

    Convergence limit. Iteration is assumed to have converged when the maximum absolute change in any
    grid value is less than convergence_limit.
- **D** | **breakline** :: [Type => String | NamedTuple]     `Arg = breakline[+z[level]] | (data=Array, [zlevel=x])`

    Use xyz data in the breakline file as a ‘soft breakline’, that is a line whose vertices will be used to
    constrain the nearest grid nodes without any further interpolation.
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = surface(....) form.
- **Ll** | **lower** :: [Type => Str | Number]

    Impose limits on the output solution. lower sets the lower bound. lower can be the name of a grid
    file with lower bound values, a fixed value, d to set to minimum input value,
- **Lu** | **upper** :: [Type => Str | Number]

- **M** | **mask** :: [Type => Number]      `Arg = max_radius`

    After solving for the surface, apply a mask so that nodes farther than max_radius away from a data constraint is set to NaN.
- **N** | **iterations** | **max_iterations** :: [Type => Number]

    Number of iterations. Iteration will cease when convergence_limit is reached or when number of
    iterations reaches max_iterations.
- **Q** | **suggest** :: [Type => Bool]

    Suggest grid dimensions which have a highly composite greatest common factor.
- **S** | **search_radius** :: [Type => Number | Str]  

    Sets the resolution of the projected grid that will be created.
- **T** | **tension** :: [Type => Number | Str]

    Tension factor[s]. These must be between 0 and 1.
- $(opt_V)
- **W** | **log** :: [Type => Str]

    Write convergence information to a log file [surface_log.txt].
- **Z** | **over_relaxation** :: [Type => Str | GMTgrid]

    Over-relaxation factor. This parameter is used to accelerate the convergence; it is a number between 1 and 2.

- **preproc** :: [Type => Bool | Str/Symb]

    This option means that the data is previously passed through one of ``block*`` modules to decimate the data
    in each cell as strongly advised. `preproc=true` will use ``blockmean``. To use any of the other two,
    pass its name as value. *e.g.* `preproc="blockmedian"`.
- $(opt_a)
- $(_opt_bi)
- $(_opt_di)
- $(opt_e)
- $(_opt_f)
- $(_opt_h)
- $(_opt_i)
- $(opt_r)
- $(opt_w)
- $(opt_swap_xy)

To see the full documentation type: ``@? surface``
"""
function surface(cmd0::String="", arg1::Union{Nothing, MatGDsGd}=nothing; kwargs...)

	arg2 = nothing
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	d = seek_auto_RI(d, cmd0, arg1)				# If -R -I (or one of them) not set, guess.

	if ((val = find_in_dict(d, [:preproc :preprocess])[1]) !== nothing)
		_val = string(val)::String
		fun = (_val == "blockmedian") ? blockmedian : (_val == "blockmode") ? blockmode : blockmean
		r = ((val = find_in_dict(d, [:r :reg :registration])[1]) !== nothing) ? string(val)::String : "g"
		Vd::Int = ((val = find_in_dict(d, [:Vd], false)[1]) !== nothing) ? val : 0
		if (Vd == 2)
			println(string(fun, " -R",d[:R], " -I",d[:I], " -r",r))
		else
			arg1 = (cmd0 != "") ? fun(cmd0; R=d[:R], I=d[:I], r=r) : fun(arg1; R=d[:R], I=d[:I], r=r)
			cmd0 = ""	# Since it may have been just consumed above 
		end
	end

	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :a :bi :di :e :f :h :i :w :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :aspect_ratio], [:C :convergence], [:Ll :lower], [:Lu :upper], [:M :mask],
	                                 [:N :iterations :max_iterations], [:Q :suggest], [:S :search_radius], [:T :tension], [:W :log], [:Z :over_relaxation]])
	cmd, args, n, = add_opt(d, cmd, "D", [:D :breakline], :data, Array{Any,1}([arg1, arg2]), (zlevel="+z",))
	#(!contains(cmd, " -R") && !isempty(CTRL.pocket_R[1])) && (cmd *= " -R")
	if (n > 0)  arg1, arg2 = args[:]  end

	common_grd(d, cmd0, cmd, "surface ", arg1, arg2)		# Finish build cmd and run it
end

surface(arg1::MatGDsGd; kw...) = surface("", arg1; kw...)
