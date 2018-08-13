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
	Compute the difference (input data - trend)
	[`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdtrend.html#d)
- **T** : **trend** : -- Str or [] --
	Compute the trend surface
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

	cmd, opt_R = parse_R("", d)
	cmd = parse_V(cmd, d)

	cmd = add_opt(cmd, 'N', d, [:N :model])
	cmd = add_opt(cmd, 'D', d, [:D :diff])
	cmd = add_opt(cmd, 'T', d, [:T :trend])
	cmd = add_opt(cmd, 'W', d, [:W :weights])

	if (occursin(cmd, "-D") && occursin(cmd, "-T"))
		warning("Usage error, both difference and trend were required. Ignoring the trend request.")
	end

	ff = findfirst("-D", cmd)
	if (ff == nothing)
		ff = findfirst("-T", cmd)
	end
	ind = (ff == nothing) ? 0 : first(ff)
	if (ind > 0 && cmd[ind+2] != ' ')      # A file name was provided
		no_output = true
	else
		no_output = false
		if (ind == 0)						# No -T -or -D provided so default to -T
			cmd = cmd * " -T"
		end
	end

	if (isempty_(arg1) && !isempty(cmd0))	# Grid was passed as file name
		cmd = cmd0 * " " * cmd
		(haskey(d, :Vd)) && println(@sprintf("\tgrdtrend %s", cmd))
		if (no_output)
			if (!isempty_(arg2))  gmt("grdtrend " * cmd, arg2)
			else                  gmt("grdtrend " * cmd)
			end
			return nothing
		else
			if (!isempty_(arg2))  O = gmt("grdtrend " * cmd, arg2)
			else                  O = gmt("grdtrend " * cmd)
			end
			return O
		end
	else
		(haskey(d, :Vd)) && println(@sprintf("\tgrdtrend %s", cmd))
		if (no_output)
			if (!isempty_(arg2))  gmt("grdtrend " * cmd, arg1, arg2)
			else                  gmt("grdtrend " * cmd, arg1)
			end
			return nothing
		else
			if (!isempty_(arg2))  O = gmt("grdtrend " * cmd, arg1, arg2)
			else                  O = gmt("grdtrend " * cmd, arg1)
			end
			return O
		end
	end
end

# ---------------------------------------------------------------------------------------------------
grdtrend(arg1=[], arg2=[], cmd0::String=""; kw...) = grdtrend(cmd0, arg1, arg2; kw...)