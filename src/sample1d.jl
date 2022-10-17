"""
	sample1d(cmd0::String="", arg1=nothing, kwargs...)

Resample 1-D table data using splines

Full option list at [`sample1d`]($(GMTdoc)sample1d.html)

Parameters
----------

- **A** | **resample** :: [Type => Str]        ``Arg = f|p|m|r|R``

    For track resampling (if -T…unit is set) we can select how this is to be performed.
    ($(GMTdoc)sample1d.html#a)
- **F** | **interp** :: [Type => Str]   ``Arg = l|a|c|n|s<p>[+1|+2]``

    Choose from l (Linear), a (Akima spline), c (natural cubic spline), and n (no interpolation:
    nearest point) [Default is Akima].
    ($(GMTdoc)sample1d.html#f)
- **N** | **time_col** :: [Type => Int]      ``Arg = t_col``

    Indicates which column contains the independent variable (time). The left-most column
    is # 0, the right-most is # (n_cols - 1). [Default is 0].
    ($(GMTdoc)sample1d.html#n)
- **T** | **inc** | **range** :: [Type => List | Str]     ``Arg = [min/max/]inc[+a|n]] or file|list``

    Evaluate the best-fit regression model at the equidistant points implied by the arguments.
    ($(GMTdoc)sample1d.html#t)
- $(GMT.opt_V)
- **W** | **weights** :: [Type => Int]     ``Arg = w_col``

    Sets the column number of the weights to be used with a smoothing cubic spline. Requires Fs. (GMT6.1)
    ($(GMTdoc)sample1d.html#w)
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
- $(GMT.opt_w)
- $(GMT.opt_swap_xy)
"""
function sample1d(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd = parse_common_opts(d, "", [:V_params :b :d :e :f :g :h :i :o :w :yx])[1]
	cmd = parse_these_opts(cmd, d, [[:A :resample], [:N :time_col :timecol], [:W :weights :weights_col]])
	cmd, Tvec = parse_opt_range(d, cmd, "T")
	(GMTver >= v"6.4.0") && (cmd = add_opt(d, cmd, "E", [:E :keeptxt]))

	if ((val = find_in_dict(d, [:F :interp :interp_type])[1]) !== nothing)
		# F=:akima, F="akima", F="s0.1+d2", F="cubic+d1", F="c+d1"
		p, deriv = "", ""
		if (isa(val, String) || isa(val, Symbol))
			_val::String = string(val)
			# Extract and strip an eventual "+d?" flag
			if ((ind = findfirst('+', _val)) !== nothing)
				deriv = "+d" * _val[end];	_val = _val[1:ind-1]
			end
			if _val[1] == 's'
				(isletter(_val[end])) && error("SAMPLE1D: smoothing type must provide smoothing parameter")
				n = length(_val) + 1
				while (!isletter(_val[n-=1]) && n > 0) end
				opt = "s" * _val[n+1:end]
			else
				opt = string(_val[1])
			end
			opt *= deriv
		else (isa(val, Tuple) && length(val) <= 3)
			# F=(:akima, "first"), F=(:smothing, 0.1), F=(:smothing, 0.1, :second)
			t = string(val[1])[1]
			if (t == 's')	# Either: F=(:smothing, 0.1) or F=(:smothing, 0.1, :second)
				p = string(val[2])
				(length(val) == 3) && (deriv = (string(val[3])[1] == 'f') ? "+d1" : "+d2")
			else							# Must be one of: F=(:akima, "first"), etc
				deriv = (string(val[2])[1] == 'f') ? "+d1" : "+d2"
			end
			opt = t * p * deriv
		end
		cmd *= " -F" * opt
	end

	common_grd(d, cmd0, cmd, "sample1d ", arg1, isempty(Tvec) ? nothing : Tvec)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
sample1d(arg1; kw...) = sample1d("", arg1; kw...)