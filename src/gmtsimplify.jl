"""
	gmtsimplify(cmd0::String="", arg1=nothing; kwargs...)

Line reduction using the Douglas-Peucker algorithm.

See full GMT docs at [`gmtsimplify`]($(GMTdoc)gmtsimplify.html)

Parameters
----------

- **T** | **tol** | **tolerance** :: [Type => Str | Number]    `Arg = tolerance[unit]`

    Specifies the maximum mismatch tolerance in the user units. If the data is not Cartesian then append the distance unit.
    ($(GMTdoc)gmtsimplify.html#t)
- $(opt_V)
- $(opt_write)
- $(opt_append)
- $(opt_b)
- $(opt_d)
- $(opt_e)
- $(_opt_f)
- $(opt_g)
- $(_opt_h)
- $(_opt_i)
- $(opt_o)
- $(opt_swap_xy)
"""
gmtsimplify(cmd0::String; kw...) = gmtsimplify_helper(cmd0, nothing; kw...)
gmtsimplify(arg1; kw...)         = gmtsimplify_helper("", arg1; kw...)

# ---------------------------------------------------------------------------------------------------
function gmtsimplify_helper(cmd0::String, arg1; kw...)
	d = init_module(false, kw...)[1]
	gmtsimplify_helper(cmd0, arg1, d)
end
function gmtsimplify_helper(cmd0::String, arg1, d::Dict{Symbol, Any})

	cmd, = parse_common_opts(d, "", [:V_params :b :d :e :f :g :h :i :o :yx])
	cmd  = add_opt(d, cmd, "T", [:T :tol :tolerance])

	common_grd(d, cmd0, cmd, "gmtsimplify ", arg1)		# Finish build cmd and run it
end
