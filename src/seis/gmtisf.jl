"""
	gmtisf(cmd0::String; kwargs...)

Plot focal mechanisms.

Parameters
----------

- $(_opt_R)

- **G** | **fill** | **compressionfill** :: [Type => Str | Number]

    Selects shade, color or pattern for filling the sectors [Default is no fill].
- **L** | **outline_pen** | **pen_outline** :: [Type => Str | Number | Tuple]

    Draws the “beach ball” outline with pen attributes instead of with the default pen set by **pen**
- **M** | **same_size** | **samesize** :: [Type => Bool]

    Use the same size for any magnitude. Size is given with **S**
- **N** | **no_clip** | **noclip** :: [Type => Str | []]

    Do NOT skip symbols that fall outside frame boundary.

- $(opt_swap_xy)

Example: Plot a focal mechanism using the Aki & Richards convention 

```julia
    psmeca([0.0 3.0 0.0 0 45 90 5 0 0], aki=true, fill=:black, region=(-1,4,0,6), proj=:Merc, show=1)
```
"""
# ---------------------------------------------------------------------------------------------------
function gmtisf(cmd0::String; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd = parse_common_opts(d, "", [:R :V_params :yx])[1]
	cmd = parse_these_opts(cmd, d, [[:F :focal], [:D :date], [:N :notime]])
	out = common_grd(d, cmd0, cmd, "gmtisf ", nothing)	# Finish build cmd and run it
	nc = size(out,2)
	colnames = (nc == 4 || nc == 9) ? ["lon", "lat", "depth", "mag"] : (nc == 7 || nc == 12) ? ["lon", "lat", "depth", "strike", "dip", "rake", "mag"] : ["lon", "lat", "depth", "strike1", "dip1", "rake1", "strike2", "dip2", "rake2", "mantissa", "exponent"]
	(!contains(cmd, " -N")) && (append!(colnames, ["year", "month", "day", "hour", "minute"]))
	out.colnames = colnames
	return out
end