"""
	grdtrend(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

reads a 2-D grid file and fits a low-order polynomial trend to these data by
[optionally weighted] least-squares.

See full GMT (not the `GMT.jl` one) docs at [`grdtrend`]($(GMTdoc)grdtrend.html)

Parameters
----------

- **N** | **model** :: [Type => Str | Number]

    Sets the number of model parameters to fit.
- **D** | **diff** :: [Type => Str | []]

    Compute the difference (input data - trend). Optionaly provide a file name to save result on disk.
- **T** | **trend** :: [Type => Str | []]

    Compute the trend surface. Optionaly provide a file name to save result on disk.
- **W** | **weights** :: [Type => Str]

    If weight.nc exists, it will be read and used to solve a weighted least-squares problem.
- $(GMT._opt_R)
- $(GMT.opt_V)

To see the full documentation type: ``@? grdtrend``
"""
function grdtrend(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_R(d, "")
	cmd = parse_V_params(d, cmd)
	cmd = parse_these_opts(cmd, d, [[:D :diff], [:T :trend]])
	opt_N = add_opt(d, "", "N", [:N :model], (n="", n_model="", robust="_+r", xonly="_+x", yonly="_+y"), true, true)
	(opt_N == "" && !show_kwargs[1]) && error("The 'model' parameter is mandatory")
	cmd *= opt_N

	cmd, _, arg1 = find_data(d, cmd0, cmd, arg1)
	(isa(arg1, Array{<:Number})) && (arg1 = mat2grid(arg1))

	cmd, arg1, arg2 = parse_W_grdtrend(d, [:W :weights], cmd, arg1, arg2)

	if (occursin("-D", cmd) && occursin("-T", cmd))
		@warn("Usage error, both difference and trend were required. Ignoring the trend request.")
	elseif (!occursin("-D", cmd) && !occursin("-T", cmd))
		cmd *= " -T" 			# No -T -or -D provided so default to -T
	end

	return common_grd(d, "grdtrend " * cmd, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
function parse_W_grdtrend(d::Dict, symbs::Array{<:Symbol}, cmd::String, arg1, arg2)

	(show_kwargs[1]) && return (print_kwarg_opts(symbs, "Tuple | String"), arg1,arg2)

	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		if (isa(val, String) || isa(val, Symbol))
			cmd *= " -W" * arg2str(val)
		else
			if (isa(val, Tuple) && length(val) == 2 && (isa(val[1], GMTgrid) || isa(val[1], Vector{GMTgrid})))
				val = val[1];	cmd *= "+s"
			end
			cmd, N_used = put_in_slot(cmd, 'W', arg1, arg2)
			(N_used == 1) ? arg1 = val : arg2 = val
		end
	end
	return cmd, arg1, arg2
end

# ---------------------------------------------------------------------------------------------------
grdtrend(arg1, arg2=nothing; kw...) = grdtrend("", arg1, arg2; kw...)