"""
	gmtsimplify(cmd0::String="", arg1=nothing, kwargs...)

Line reduction using the Douglas-Peucker algorithm.

Full option list at [`gmtsimplify`]($(GMTdoc)gmtsimplify.html)

Parameters
----------

- **T** | **tol** | **tolerance** :: [Type => Str | Number]    `Arg = tolerance[unit]`

    Specifies the maximum mismatch tolerance in the user units. If the data is not Cartesian then append the distance unit.
    ($(GMTdoc)gmtsimplify.html#t)
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_o)
- $(GMT.opt_swap_xy)
"""
function gmtsimplify(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("gmtsimplify", cmd0, arg1)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_common_opts(d, "", [:V_params :b :d :e :f :g :h :i :o :yx])
	cmd  = add_opt(d, cmd, 'T', [:T :tol :tolerance])

	common_grd(d, cmd0, cmd, "gmtsimplify ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtsimplify(arg1, cmd0::String=""; kw...) = gmtsimplify(cmd0, arg1; kw...)