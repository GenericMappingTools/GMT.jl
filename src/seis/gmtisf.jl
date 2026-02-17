"""
	gmtisf(cmd0::String; kwargs...)

Read seismicity data in the a ISF formated file.

Parameters
----------

- $(_opt_R)

- **D** | **date** :: date="datestart[/dateend]"

    Limit the output to data >= datestart, or between datestart and dateend. <date> must be in ISO format, e.g, 2000-04-25.
- **F** | **focal** :: [Type => Bool or Str or Symbol]

    Select only events that have focal mechanisms. The default is Global CMT convention. Use `focal=:a` for the AKI convention
- **N** | **notime** :: [Type => Bool]

    Do NOT output time information.

- `abstime or unixtime` :: [Type => Integer]

    Convert the YYYY, MM, DD, HH, MM columns into a unixtime. Default puts it as first column,
    use `abstime=2` to put it as last column.

- $(opt_swap_xy)

This module can also be called via `gmtread`. _I.,e._ `gmtread("file.isf", opts...)_
"""
function gmtisf(cmd0::String; kw...)::GMTdataset{Float64,2}
	d = init_module(false, kw...)[1]
	gmtisf(cmd0, d)
end
function gmtisf(cmd0::String, d::Dict{Symbol, Any})::GMTdataset{Float64,2}

	cmd = parse_common_opts(d, "", [:R :V_params :yx])[1]
	cmd = parse_these_opts(cmd, d, [[:F :focal], [:D :date], [:N :notime]])
	abstime::Int = ((val = find_in_dict(d, [:abstime :unixtime])[1]) !== nothing) ? Int(val) : 0
	(abstime != 0 && contains(cmd, " -N")) && error("'abstime' and 'notime' options are mutually exclusive.")
	out::GMTdataset{Float64,2} = common_grd(d, cmd0, cmd, "gmtisf ", nothing)	# Finish build cmd and run it
	nc = size(out,2)
	colnames = (nc == 4 || nc == 9) ? ["lon", "lat", "depth", "mag"] : (nc == 7 || nc == 12) ? ["lon", "lat", "depth", "strike", "dip", "rake", "mag"] : ["lon", "lat", "depth", "strike1", "dip1", "rake1", "strike2", "dip2", "rake2", "mantissa", "exponent"]
	(!contains(cmd, " -N")) && (append!(colnames, ["year", "month", "day", "hour", "minute"]))
	out.colnames = colnames
	(abstime != 0) && isf_unixtime!(out, abstime)
	return out
end

# ---------------------------------------------------------------------------------------------------
function isf_unixtime!(D::GMTdataset{Float64,2}, first_col=1)
	# Convert the 5 last columns with YYYY MM DD HH MM to unix time.
	# If first_col = 1, then the the abstime is in the first column, otherwise in the last
	nc = size(D,2)
	t = datetime2unix.((DateTime.(view(D,:,nc-4), view(D,:,nc-3), view(D,:,nc-2), view(D,:,nc-1), view(D,:,nc))))
	if (first_col == 1)
		D.data = hcat(t, D.data[:, 1:(nc-5)])
		D.colnames = ["time", D.colnames[1:(nc-5)]...]
		settimecol!(D, 1)
	else
		D.data = hcat(D.data[:, 1:(nc-5)], t)
		D.colnames = [D.colnames[1:(nc-5)]..., "time"]
		settimecol!(D, nc-4)
	end
	set_dsBB!(D)
end
