"""
	gmtregress(cmd0::String="", arg1=[], kwargs...)

Linear regression of 1-D data sets.

Full option list at [`gmtregress`](http://gmt.soest.hawaii.edu/doc/latest/gmtregress.html)

Parameters
----------

- **A** : **all_slopes** : -- Str or List --        Flags = min/max/inc

    Instead of determining a best-fit regression we explore the full range of regressions.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/gmtregress.html#a)
- **C** : **confidence_level** : -- Int --      Flags = level

    Set the confidence level (in %) to use for the optional calculation of confidence
    bands on the regression [95].
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/gmtregress.html#c)
- **E** : **type_of_regression** : -- Str --    Flags = x|y|o|r

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
function gmtregress(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("gmtregress", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)

	cmd = parse_V_params("", d)
	cmd, = parse_b(cmd, d)
	cmd, = parse_d(cmd, d)
	cmd, = parse_e(cmd, d)
	cmd, = parse_g(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd, = parse_o(cmd, d)
	cmd, = parse_swap_xy(cmd, d)

	cmd = add_opt(cmd, 'A', d, [:A :all_slopes])
	cmd = add_opt(cmd, 'C', d, [:C :confidence_level])
	cmd = add_opt(cmd, 'E', d, [:E :type_of_regression])
	cmd = add_opt(cmd, 'F', d, [:F :column_combination])
	cmd = add_opt(cmd, 'N', d, [:N :norm])
	cmd = add_opt(cmd, 'S', d, [:S :restrict])
	cmd = add_opt(cmd, 'T', d, [:T :equi_space])
	cmd = add_opt(cmd, 'W', d, [:W :weighted])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "gmtregress", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtregress(arg1=[], cmd0::String=""; kw...) = gmtregress(cmd0, arg1; kw...)