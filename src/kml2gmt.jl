"""
	kml2gmt(cmd0::String="", arg1=[], kwargs...)

kml2gmt - Extract GMT table data from Google Earth KML files

Full option list at [`kml2gmt`](http://gmt.soest.hawaii.edu/doc/latest/kml2gmt.html)

Parameters
----------

- **F** : **select** : -- Str --        Flags = s|l|p

    Specify a particular feature type to output. Choose from points (s), line (l), or polygon (p).
    By default we output all geometries.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/kml2gmt.html#f)
- **Z** : **altitudes** : -- Bool or [] --

    Output the altitude coordinates as GMT z coordinates [Default will output just longitude and latitude].
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/kml2gmt.html#z)
- $(GMT.opt_V)
- $(GMT.opt_bo)
- $(GMT.opt_do)
- $(GMT.opt_swap_xy)
"""
function kml2gmt(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("kml2gmt", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)

	cmd = parse_V_params("", d)
	cmd, = parse_bo(cmd, d)
	cmd, = parse_do(cmd, d)
	cmd, = parse_swap_xy(cmd, d)

	cmd = add_opt(cmd, 'F', d, [:F :select])
	cmd = add_opt(cmd, 'Z', d, [:Z :altitudes])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "kml2gmt", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
kml2gmt(arg1=[], cmd0::String=""; kw...) = kml2gmt(cmd0, arg1; kw...)