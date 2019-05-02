"""
	grd2xyz(cmd0::String="", arg1=nothing, kwargs...)

Reads one 2-D grid and returns xyz-triplets.

Full option list at [`grd2xyz`](http://gmt.soest.hawaii.edu/doc/latest/grd2xyz.html)

Parameters
----------

- $(GMT.opt_J)
- **C** : **row_col** : -- Bool --

    Replace the x- and y-coordinates on output with the corresponding column and row numbers.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/grd2xyz.html#c)
- $(GMT.opt_R)
- $(GMT.opt_V)
- **W** : **weight** : -- Str --           Flags = [a|weight]

    Write out x,y,z,w, where w is the supplied weight (or 1 if not supplied) [Default writes x,y,z only].
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/grd2xyz.html#w)
- **Z** : **flags** : -- Str --

    Write a 1-column table. Output will be organized according to the specified ordering
    convention contained in ``flags``.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/grd2xyz.html#z)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_bo)
- $(GMT.opt_d)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_o)
- $(GMT.opt_s)
"""
function grd2xyz(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("grd2xyz", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :bo :d :f :h :o :s])
    cmd = parse_these_opts(cmd, d, [[:C :row_col], [:W :weight], [:Z :flags]])

	common_grd(d, cmd0, cmd, "grd2xyz ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grd2xyz(arg1; kw...) = grd2xyz("", arg1; kw...)