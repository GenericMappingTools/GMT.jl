"""
	regress(cmd0::String="", arg1=nothing, kwargs...)

Linear regression of 1-D data sets.

Full option list at [`regress`](http://gmt.soest.hawaii.edu/doc/latest/gmtregress.html)

Parameters
----------

- **A** : **all_slopes** : -- Str or List --        Flags = min/max/inc

    Instead of determining a best-fit regression we explore the full range of regressions.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/gmtregress.html#a)
- **C** : **confidence_level** : -- Int --      Flags = level

    Set the confidence level (in %) to use for the optional calculation of confidence
    bands on the regression [95].
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/gmtregress.html#c)
- **E** : **regression_type** : -- Str --    Flags = x|y|o|r

    Type of linear regression, i.e., select the type of misfit we should calculate.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/gmtregress.html#e)
- **F** : **column_combination** : -- Str --   Flags = x|y|m|l|c

    Append a combination of the columns you wish returned;
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/gmtregress.html#f)
- **N** : **norm** : -- Int or Str --           Flags = 1|2|r|w

    Selects the norm to use for the misfit calculation.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/gmtregress.html#n)
- **S** : **restrict** : -- Str or [] --        Flags = [r]

    Restricts which records will be output.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/gmtregress.html#s)
- **T** : **equi_space** : -- List or Str --     Flags = [min/max/]inc[+a|n]] or file|list

    Evaluate the best-fit regression model at the equidistant points implied by the arguments.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/gmtregress.html#t)
- **W** : **weighted** : -- Str or [] --     Flags = [w][x][y][r]

    Specifies weighted regression and which weights will be provided.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/gmtregress.html#w)
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
function regress(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("gmtregress", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :b :d :e :g :h :i :o :yx])
    cmd = parse_these_opts(cmd, d, [[:A :all_slopes], [:C :confidence_level], [:E :regression_type], [:N :norm],
                [:F :column_combination], [:S :restrict], [:T :equi_space], [:W :weighted]])

	common_grd(d, cmd0, cmd, "gmtregress ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
regress(arg1, cmd0::String=""; kw...) = regress(cmd0, arg1; kw...)

gmtregress = regress 		# Alias