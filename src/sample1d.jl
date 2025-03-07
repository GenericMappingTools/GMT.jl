"""
	sample1d(cmd0::String="", arg1=nothing, kwargs...)

Resample 1-D table data using splines

Parameters
----------

- **A** | **resample** :: [Type => Str]        ``Arg = f|p|m|r|R``

    For track resampling (if -T…unit is set) we can select how this is to be performed.
- **E** | **keeptext** :: [Type => Bool]

    If the input dataset contains records with trailing text then we will attempt to add these to
    output records that exactly match the input times.
- **F** | **interp** :: [Type => Str]   ``Arg = l|a|c|n|s<p>[+1|+2]``

    Choose from l (Linear), a (Akima spline), c (natural cubic spline), and n (no interpolation:
    nearest point) [Default is Akima].
- **N** | **time_col** :: [Type => Int]      ``Arg = t_col``

    Indicates which column contains the independent variable (time). The left-most column
    is # 0, the right-most is # (n_cols - 1). [Default is 0].
- **T** | **inc** | **range** :: [Type => List | Str]     ``Arg = [min/max/]inc[+a|n]] or file|list``

    Evaluate the best-fit regression model at the equidistant points implied by the arguments.
- `cumdist` | `cumsum`: [Type => Bool]

    Compute the cumulative distance along the input line. Note that for this the first two columns
    must contain the spatial coordinates.
- $(opt_V)
- **W** | **weights** :: [Type => Int]     ``Arg = w_col``

    Sets the column number of the weights to be used with a smoothing cubic spline. Requires Fs.
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

To see the full documentation type: ``@? sample1d``
"""
sample1d(cmd0::String; kw...) = sample1d_helper(cmd0, nothing; kw...)
sample1d(arg1; kw...)         = sample1d_helper("", arg1; kw...)

# ---------------------------------------------------------------------------------------------------
function sample1d_helper(cmd0::String, arg1; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd = parse_common_opts(d, "", [:V_params :b :d :e :f :g :h :i :o :w :yx])[1]
	cmd = parse_these_opts(cmd, d, [[:A :resample], [:N :time_col :timecol], [:W :weights :weights_col]])
	cmd, Tvec = parse_opt_range(d, cmd, "T")
	have_cumdist = false
	((val = find_in_dict(d, [:cumdist :cumsum])[1]) !== nothing) && (cmd *= "c+a"; have_cumdist = true)
	cmd = add_opt(d, cmd, "E", [:E :keeptext :keeptxt])		# Needs GMT6.4 but not testing that anymore.

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

	r = common_grd(d, cmd0, cmd, "sample1d ", arg1, isempty(Tvec) ? nothing : Tvec)		# Finish build cmd and run it
	(r === nothing || isa(r, String)) && return r		# Nothing if saved in file, String if Vd == 2

	if isa(arg1, GDtype)
		colnames = isa(arg1, GMTdataset) ? arg1.colnames : arg1[1].colnames
		have_cumdist && append!(colnames, ["cumdist"])
		!isempty(arg1.attrib) && (r.attrib = arg1.attrib)	# Keep the attribs
	else		# Input was eith a matrix or a file name
		nc = isa(r, GMTdataset) ? size(r, 2) : size(r[1], 2)
		colnames = [@sprintf("Z%d", k) for k = 1:nc]
		(nc > 1) && (colnames[1] = "X"; colnames[2] = "Y")
		have_cumdist && (colnames[end] = "cumdist")
	end
	isa(r, GMTdataset) ? (r.colnames = colnames) : (r[1].colnames = colnames)
	return r
end
