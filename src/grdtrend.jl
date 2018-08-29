"""
	grdtrend(cmd0::String="", arg1=[], arg2=[]; kwargs...)

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
function grdtrend(cmd0::String="", arg1=[], arg2=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("grdtrend", cmd0, arg1, arg2)	# Speedy mode

	if (isempty(cmd0) && isempty_(arg1))
		error("Must provide the grid to work with.")
	end

	d = KW(kwargs)

	cmd = add_opt("", 'N', d, [:N :model])
	if (!occursin("-N", cmd))
		error("The 'model' parameter is mandatory")
	end

	cmd, = parse_R(cmd, d)
	cmd = parse_V_params(cmd, d)
	cmd = add_opt(cmd, 'D', d, [:D :diff])
	cmd = add_opt(cmd, 'T', d, [:T :trend])

	if (occursin("-D", cmd) && occursin("-T", cmd))
		warning("Usage error, both difference and trend were required. Ignoring the trend request.")
	elseif (!occursin("-D", cmd) && !occursin("-T", cmd))
		cmd = cmd * " -T" 			# No -T -or -D provided so default to -T
	end

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	if (isa(arg1, Array{<:Number}))		arg1 = mat2grid(arg1)	end

	for sym in [:W :weights]
		if (haskey(d, sym))
			if (!isa(d[sym], GMTgrid))
				cmd = cmd * " -W" * arg2str(d[sym])
			else
				cmd, N_used = put_in_slot(cmd, d[sym], 'W', [arg1, arg2])
				if (N_used == 1)     arg1 = d[sym]
				elseif (N_used == 2) arg2 = d[sym]
				end
			end
			break
		end
	end

	if (isempty_(arg2))
		return common_grd(d, cmd, got_fname, 1, "grdtrend", arg1)		# Finish build cmd and run it
	else
		return common_grd(d, cmd, got_fname, 2, "grdtrend", arg1, arg2)
	end
end

# ---------------------------------------------------------------------------------------------------
grdtrend(arg1=[], arg2=[], cmd0::String=""; kw...) = grdtrend(cmd0, arg1, arg2; kw...)