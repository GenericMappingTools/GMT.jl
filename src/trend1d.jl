"""
	trend1d(cmd0::String="", arg1=nothing, kwargs...)

Fit a [weighted] [robust] polynomial/Fourier model for y = f(x) to xy[w] data.

See full GMT (not the `GMT.jl` one) docs at [`trend1d`]($(GMTdoc)trend1d.html)

Parameters
----------

- **F** | **out** | **output** :: [Type => Str]   ``Arg = xymrw|p|P|c``

    Specify up to five letters from the set {x y m r w} in any order to create columns of output. 
- **N** | **model** :: [Type => Str]      ``Arg = [p|P|f|F|c|C|s|S|x]n[,…][+llength][+oorigin][+r]``

    Specify Specify the number of terms in the model, n_model, and append +r to do a robust fit. E.g., a robust bilinear model is -N4+r.
- **C** | **condition_number** :: [Type => Number]   ``Arg = condition_number``

    Set the maximum allowed condition number for the matrix solution.
- **I** | **conf_level** :: [Type => Number | []]   ``Arg = [confe_level]``

    Iteratively increase the number of model parameters, starting at one, until n_model is reachedx
    or the reduction in variance of the model is not significant at the conf_level level.
- **W** | **weights** :: [Type => Str | []]     ``Arg = [+s]``

    Weights are supplied in input column 3. Do a weighted least squares fit [or start with
    these weights when doing the iterative robust fit].
- $(opt_V)
- $(opt_b)
- $(opt_d)
- $(opt_e)
- $(_opt_f)
- $(_opt_h)
- $(_opt_i)
- $(opt_w)
- $(opt_swap_xy)

To see the full documentation type: ``@? trend1d``
"""
function trend1d(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_common_opts(d, "", [:V_params :b :d :e :f :h :i :w :yx])
	cmd  = parse_these_opts(cmd, d, [[:C :condition_number], [:I :conf_level :confidence_level], [:F :out :output],
	                                 [:N :model :n_model], [:W :weights]])
	common_grd(d, cmd0, cmd, "trend1d ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
trend1d(arg1; kw...) = trend1d("", arg1; kw...)