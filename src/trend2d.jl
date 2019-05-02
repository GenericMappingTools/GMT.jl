"""
	trend2d(cmd0::String="", arg1=nothing, kwargs...)

Fit a [weighted] [robust] polynomial model for z = f(x,y) to xyz[w] data.

Full option list at [`trend2d`](http://gmt.soest.hawaii.edu/doc/latest/trend2d.html)

Parameters
----------

- **F** : **output** : -- Str --   Flags = xyzmrw|p

    Specify up to five letters from the set {x y m r w} in any order to create columns of output. 
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/trend2d.html#f)
- **N** : **n_model** : -- Str --      Flags = n_model[+r]

    Specify the number of terms in the model, n_model, and append +r to do a robust fit. E.g.,
    a robust bilinear model is N="4+r".
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/trend2d.html#n)

- **C** : **condition_number** : -- Number --   Flags = condition_number

    Set the maximum allowed condition number for the matrix solution.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/trend2d.html#c)
- **I** : **confidence_level** : -- Number or [] --   Flags = [confidence_level]

    Iteratively increase the number of model parameters, starting at one, until n_model is reachedx
    or the reduction in variance of the model is not significant at the confidence_level level.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/trend2d.html#i)
- **W** : **weights** : -- Str or [] --     Flags = [+s]

    Weights are supplied in input column 4. Do a weighted least squares fit [or start with
    these weights when doing the iterative robust fit].
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/trend2d.html#w)
- $(GMT.opt_V)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_swap_xy)
"""
function trend2d(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("trend2d", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :b :d :e :f :h :i :yx])
	cmd = parse_these_opts(cmd, d, [[:C :condition_number], [:I :confidence_level], [:F :output],
				[:N :n_model], [:W :weights]])

	common_grd(d, cmd0, cmd, "trend2d ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
trend2d(arg1, cmd0::String=""; kw...) = trend2d(cmd0, arg1; kw...)