"""
	grdtrend(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

reads a 2-D grid file and fits a low-order polynomial trend to these data by
[optionally weighted] least-squares.

Full option list at [`grdtrend`](http://gmt.soest.hawaii.edu/doc/latest/grdtrend.html)

Parameters
----------

- **N** : **model** : -- Str or Number --

    Sets the number of model parameters to fit.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdtrend.html#n)
- **D** : **diff** : -- Str or [] --

    Compute the difference (input data - trend). Optionaly provide a file name to save result on disk.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdtrend.html#d)
- **T** : **trend** : -- Str or [] --

    Compute the trend surface. Optionaly provide a file name to save result on disk.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grdtrend.html#t)
- **W** : **weights** : -- Str --

    If weight.nc exists, it will be read and used to solve a weighted least-squares problem.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/grdtrend.html#w)
- $(GMT.opt_R)
- $(GMT.opt_V)
"""
function grdtrend(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("grdtrend", cmd0, arg1, arg2)

	d = KW(kwargs)

	cmd, = parse_R("", d)
	cmd = parse_V_params(cmd, d)
	cmd = parse_these_opts(cmd, d, [[:D :diff], [:T :trend]])
	opt_N = add_opt("", "N", d, [:N :model], (n="", n_model="", robust="_+r"), false, true)
	if (opt_N == "")  error("The 'model' parameter is mandatory")  end
	cmd *= opt_N

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)
	if (isa(arg1, Array{<:Number}))  arg1 = mat2grid(arg1)  end

	if ((val = find_in_dict(d, [:W :weights])[1]) !== nothing)
		if (isa(val, String) || isa(val, Symbol))
			cmd *= " -W" * arg2str(val)
		else
			if (isa(val, Tuple) && length(val) == 2 && (isa(val, GMTgrid) || isa(val, Array{GMT.GMTgrid,1})))
				val = val[1];	cmd *= "+s"
			end
			cmd, N_used = put_in_slot(cmd, val, 'W', [arg1, arg2])
			(N_used == 1) ? arg1 = val : arg2 = val
		end
	end

	if (occursin("-D", cmd) && occursin("-T", cmd))
		@warn("Usage error, both difference and trend were required. Ignoring the trend request.")
	elseif (!occursin("-D", cmd) && !occursin("-T", cmd))
		cmd *= " -T" 			# No -T -or -D provided so default to -T
	end

	return common_grd(d, "grdtrend " * cmd, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
grdtrend(arg1, arg2=nothing, cmd0::String=""; kw...) = grdtrend(cmd0, arg1, arg2; kw...)