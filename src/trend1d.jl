"""
	trend1d(cmd0::String="", arg1=nothing, kwargs...)

Fit a [weighted] [robust] polynomial/Fourier model for y = f(x) to xy[w] data.

Full option list at [`trend1d`](http://gmt.soest.hawaii.edu/doc/latest/trend1d.html)

Parameters
----------

- **F** : **output** : -- Str --   Flags = xymrw|p|P|c

    Specify up to five letters from the set {x y m r w} in any order to create columns of output. 
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/trend1d.html#f)
- **N** : **n_model** : -- Str --      Flags = [p|P|f|F|c|C|s|S|x]n[,…][+llength][+oorigin][+r]

    Specify Specify the number of terms in the model, n_model, and append +r to do a robust fit. E.g., a robust bilinear model is -N4+r.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/trend1d.html#n)

- **C** : **condition_number** : -- Number --   Flags = condition_number

    Set the maximum allowed condition number for the matrix solution.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/trend1d.html#c)
- **I** : **confidence_level** : -- Number or [] --   Flags = [confidence_level]

    Iteratively increase the number of model parameters, starting at one, until n_model is reachedx
    or the reduction in variance of the model is not significant at the confidence_level level.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/trend1d.html#i)
- **W** : **weights** : -- Str or [] --     Flags = [+s]

    Weights are supplied in input column 3. Do a weighted least squares fit [or start with
    these weights when doing the iterative robust fit].
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/trend1d.html#w)
- $(GMT.opt_V)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_swap_xy)
"""
function trend1d(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("trend1d", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :b :d :e :f :h :i :yx])
	cmd = parse_these_opts(cmd, d, [[:C :condition_number], [:I :confidence_level], [:F :output],
				[:N :n_model], [:W :weights]])

	common_grd(d, cmd0, cmd, "trend1d ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
trend1d(arg1, cmd0::String=""; kw...) = trend1d(cmd0, arg1; kw...)