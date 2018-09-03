"""
	filter1d(cmd0::String="", arg1=[], kwargs...)

Time domain filtering of 1-D data tables.

Full option list at [`filter1d`](http://gmt.soest.hawaii.edu/doc/latest/filter1d.html)

Parameters
----------

- **F** : **filter_type** : -- Str --   Flags = type width[modifiers]

    Sets the filter type. Choose among convolution and non-convolution filters. Append the
    filter code followed by the full filter width in same units as time column.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/filter1d.html#f)
- **D** : **inc** : -- Number --        Flags = increment

    ``increment`` is used when series is NOT equidistantly sampled. Then increment will be the abscissae resolution.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/filter1d.html#d)
- **E** : **ends** : -- Bool or [] --

    Include Ends of time series in output. Default loses half the filter-width of data at each end.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/filter1d.html#e)
- **N** : **time_col** : -- Int --      Flags = t_col

    Indicates which column contains the independent variable (time). The left-most column
    is # 0, the right-most is # (n_cols - 1). [Default is 0].
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/filter1d.html#n)
- **Q** : **quality** : -- Number --    Flags = q_factor

    Assess Quality of output value by checking mean weight in convolution. Enter q_factor between 0 and 1.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/filter1d.html#q)
- **S** : **symetry** : -- Number --    Flags = symmetry_factor

    Checks symmetry of data about window center. Enter a factor between 0 and 1.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/filter1d.html#s)
- **T** : **equi_space** : -- List or Str --     Flags = [min/max/]inc[+a|n]

    Make evenly spaced time-steps from min to max by inc [Default uses input times].
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/filter1d.html#t)
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
function filter1d(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("filter1d", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)

	cmd = parse_V_params("", d)
	cmd, = parse_b(cmd, d)
	cmd, = parse_d(cmd, d)
	cmd, = parse_e(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_g(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd, = parse_o(cmd, d)
	cmd, = parse_swap_xy(cmd, d)

	cmd = add_opt(cmd, 'F', d, [:F :filter_type])
	cmd = add_opt(cmd, 'D', d, [:D :inc])
	cmd = add_opt(cmd, 'E', d, [:E :ends])
	cmd = add_opt(cmd, 'N', d, [:N :time_col])
	cmd = add_opt(cmd, 'Q', d, [:Q :quality])
	cmd = add_opt(cmd, 'S', d, [:S :symetry])
	cmd = add_opt(cmd, 'T', d, [:T :equi_space])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "filter1d", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
filter1d(arg1=[], cmd0::String=""; kw...) = filter1d(cmd0, arg1; kw...)