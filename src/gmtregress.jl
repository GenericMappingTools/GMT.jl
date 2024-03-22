"""
	regress(cmd0::String="", arg1=nothing, kwargs...)

Linear regression of 1-D data sets.

See full GMT (not the `GMT.jl` one) docs at [`regress`]($(GMTdoc)gmtregress.html)

Parameters
----------

- **A** | **all_slopes** :: [Type => Str | List]        ``Arg = min/max/inc``

    Instead of determining a best-fit regression we explore the full range of regressions.
- **C** | **ci** | **cl** | **confidence_level** :: [Type => Int]      ``Arg = level``

    Set the confidence level (in %) to use for the optional calculation of confidence
    bands on the regression [95].
- **E** | **regression_type** :: [Type => Str]   ``Arg = x|y|o|r``

    Type of linear regression, i.e., select the type of misfit we should calculate.
- **F** | **column_combination** :: [Type => Str]   ``Arg = x|y|m|l|c``

    Append a combination of the columns you wish returned;
- **N** | **norm** :: [Type => Str | Int]          ``Arg = 1|2|r|w``

    Selects the norm to use for the misfit calculation.
- **S** | **restrict** :: [Type => Str | []]        ``Arg = [r]``

    Restricts which records will be output.
- **T** | **equi_space** :: [Type => Str | List]     ``Arg = [min/max/]inc[+a|n]] or file|list``

    Evaluate the best-fit regression model at the equidistant points implied by the arguments.
- **W** | **weighted** :: [Type => Str | []]     ``Arg = [w][x][y][r]``

    Specifies weighted regression and which weights will be provided.

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
- $(opt_w)
- $(opt_swap_xy)
"""
function regress(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:V_params :b :d :e :g :h :i :o :w :yx])
    cmd  = parse_these_opts(cmd, d, [[:A :all_slopes], [:C :ci :cl :confidence_level], [:E :regression_type], [:N :norm],
                                     [:F :column_combination], [:S :restrict], [:T :equi_space], [:W :weights :weighted]])

	common_grd(d, cmd0, cmd, "gmtregress ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
regress(arg1; kw...) = regress("", arg1; kw...)

gmtregress = regress 		# Alias