"""
	sample1d(cmd0::String="", arg1=nothing, kwargs...)

Resample 1-D table data using splines

Full option list at [`sample1d`](http://gmt.soest.hawaii.edu/doc/latest/sample1d.html)

Parameters
----------

- **A** : **resamp** : -- Str --        Flags = f|p|m|r|R

    For track resampling (if -T…unit is set) we can select how this is to be performed.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/sample1d.html#a)
- **F** : **interp_type** : -- Str --   Flags = l|a|c|n[+1|+2]

    Choose from l (Linear), a (Akima spline), c (natural cubic spline), and n (no interpolation:
    nearest point) [Default is Akima].
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/sample1d.html#f)
- **N** : **time_col** : -- Int --      Flags = t_col

    Indicates which column contains the independent variable (time). The left-most column
    is # 0, the right-most is # (n_cols - 1). [Default is 0].
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/sample1d.html#n)
- **T** : **equi_space** : -- List or Str --     Flags = [min/max/]inc[+a|n]] or file|list

    Evaluate the best-fit regression model at the equidistant points implied by the arguments.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/sample1d.html#t)
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
function sample1d(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("sample1d", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :b :d :e :f :g :h :i :o :yx])
	cmd = parse_these_opts(cmd, d, [[:A :resamp], [:F :interp_type], [:N :time_col], [:T :equi_space]])

	common_grd(d, cmd0, cmd, "sample1d ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
sample1d(arg1, cmd0::String=""; kw...) = sample1d(cmd0, arg1; kw...)