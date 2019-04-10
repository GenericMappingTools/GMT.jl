"""
	gmtsimplify(cmd0::String="", arg1=nothing, kwargs...)

Line reduction using the Douglas-Peucker algorithm.

Full option list at [`gmtsimplify`](http://gmt.soest.hawaii.edu/doc/latest/gmtsimplify.html)

Parameters
----------

- **T** : **tol** : **tolerance** : -- Number or Str --    Flags = tolerance[unit]

    Specifies the maximum mismatch tolerance in the user units. If the data is not Cartesian then append the distance unit.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/gmtsimplify.html#t)
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

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :b :d :e :f :g :h :i :o :yx])
	cmd = add_opt(cmd, 'T', d, [:T :tol :tolerance])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, "gmtsimplify " * cmd, got_fname, 1, arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtsimplify(arg1, cmd0::String=""; kw...) = gmtsimplify(cmd0, arg1; kw...)