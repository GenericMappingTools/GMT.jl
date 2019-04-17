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

	if (isempty(cmd0) && isempty_(arg1))  error("Must provide the grid to work with.")  end

	d = KW(kwargs)

	cmd, = parse_R("", d)
	cmd = parse_V_params(cmd, d)
	cmd = parse_these_opts(cmd, d, [[:D :diff], [:N :model], [:T :trend]])
	if (!occursin("-N", cmd))  error("The 'model' parameter is mandatory")  end

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	if (isa(arg1, Array{<:Number}))  arg1 = mat2grid(arg1)  end

	if ((val = find_in_dict(d, [:W :weights])[1]) !== nothing)
		if (!isa(val, GMTgrid))
			cmd *= " -W" * arg2str(val)
		else
			cmd, N_used = put_in_slot(cmd, val, 'W', [arg1, arg2])
			(N_used == 1) ? arg1 = val : arg2 = val
		end
	end

	if (occursin("-D", cmd) && occursin("-T", cmd))
		@warn("Usage error, both difference and trend were required. Ignoring the trend request.")
	elseif (!occursin("-D", cmd) && !occursin("-T", cmd) && !occursin("-W", cmd))
		cmd *= " -T" 			# No -T -or -D provided so default to -T
	end

	return common_grd(d, "grdtrend " * cmd, got_fname, 2, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
grdtrend(arg1, arg2=nothing, cmd0::String=""; kw...) = grdtrend(cmd0, arg1, arg2; kw...)