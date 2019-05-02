"""
    filter1d(cmd0::String="", arg1=nothing, kwargs...)

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
function filter1d(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("filter1d", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :b :d :e :f :g :h :i :o :yx])
	cmd = parse_these_opts(cmd, d, [[:F :filter_type], [:D :inc], [:E :ends], [:N :time_col],
	                       [:Q :quality], [:S :symetry], [:T :equi_space]])

	common_grd(d, cmd0, cmd, "filter1d ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
filter1d(arg1, cmd0::String=""; kw...) = filter1d(cmd0, arg1; kw...)