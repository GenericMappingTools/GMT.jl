"""
    filter1d(cmd0::String="", arg1=nothing, kwargs...)

Time domain filtering of 1-D data tables.

See full GMT (not the `GMT.jl` one) docs at [`filter1d`]($(GMTdoc)filter1d.html)

Parameters
----------

- **F** | **filter** :: [Type => Str]   `Arg = type width[modifiers]`

    Sets the filter type. Choose among convolution and non-convolution filters. Append the
    filter code followed by the full filter width in same units as time column.
- **D** | **inc** | **increment** :: [Type => Number]        `Arg = increment`

    ``increment`` is used when series is NOT equidistantly sampled. Then increment will be the abscissae resolution.
- **E** | **end** | **ends** :: [Type => Bool | []]

    Include Ends of time series in output. Default loses half the filter-width of data at each end.
- **L** | **gap_width** :: [Type => Number | Str]      `Arg = width`

    Checks for Lack of data condition. If input data has a gap exceeding width then no output will be given at that point.
- **N** | **time_col** | **timecol** :: [Type => Int]      `Arg = t_col`

    Indicates which column contains the independent variable (time). The left-most column
    is # 0, the right-most is # (n_cols - 1). [Default is 0].
- **Q** | **quality** :: [Type => Number]    `Arg = q_factor`

    Assess Quality of output value by checking mean weight in convolution. Enter q_factor between 0 and 1.
- **S** | **symmetry** :: [Type => Number]    `Arg = symmetry_factor`

    Checks symmetry of data about window center. Enter a factor between 0 and 1.
- **T** | **range** | **equispace** :: [Type => List | Str]     `Arg = [min/max/]inc[+a|n]`

    Make evenly spaced time-steps from min to max by inc [Default uses input times].
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT._opt_f)
- $(GMT.opt_g)
- $(GMT._opt_h)
- $(GMT._opt_i)
- $(GMT.opt_o)
- $(GMT.opt_swap_xy)
"""
filter1d(cmd0::String; kw...) = filter1d_helper(cmd0, nothing; kw...)
filter1d(arg1; kw...)         = filter1d_helper("", arg1; kw...)

function filter1d_helper(cmd0::String, arg1; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_common_opts(d, "", [:V_params :b :d :e :f :g :h :i :o :yx])
	cmd = parse_these_opts(cmd, d, [[:D :inc :increment], [:E :end :ends], [:L :gap_width],
                                    [:N :time_col :timecol], [:Q :quality], [:S :symmetry], [:T :range :equispace]])

	if ((symb = is_in_dict(d, [:F :filter :filter_type])) !== nothing && isa(d[symb], Tuple))
		# Accept either a F=(:gaus, 10, 1) => -Fg10+h
		_opt_F = " -F" * string(d[symb][1])[1]
		(length(d[symb]) >= 2) && (_opt_F *= string(d[symb][2]))
		(length(d[symb]) >= 3) && (_opt_F *= "+h")
		cmd *= _opt_F
		delete!(d, symb)
	else                            # Or a F=(type=:gaussian, width=10, highpass=true) => -Fg10+h
		cmd = add_opt(d, cmd, "F", [:F :filter :filter_type], (type="1", width="", highpass="_"))
	end

	(isvector(arg1)) && (arg1 = cat_1_arg(arg1))	# Accept vectors (GMT should do that too)
	common_grd(d, cmd0, cmd, "filter1d ", arg1)		# Finish build cmd and run it
end