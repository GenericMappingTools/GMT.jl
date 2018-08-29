"""
	grd2xyz(cmd0::String="", arg1=[], kwargs...)

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
- $(GMT.opt_bo)
- $(GMT.opt_d)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_o)
- $(GMT.opt_s)
"""
function grd2xyz(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("grd2xyz", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)

	cmd, = parse_R("", d)
	cmd = parse_V_params(cmd, d)
	cmd, = parse_bo(cmd, d)
	cmd, = parse_d(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, = parse_o(cmd, d)
	cmd, = parse_s(cmd, d)

	cmd = add_opt(cmd, 'C', d, [:C :row_col])
	cmd = add_opt(cmd, 'W', d, [:W :weight])
	cmd = add_opt(cmd, 'Z', d, [:Z :flags])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "grd2xyz", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grd2xyz(arg1=[], cmd0::String=""; kw...) = grd2xyz(cmd0, arg1; kw...)