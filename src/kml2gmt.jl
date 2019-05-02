"""
	kml2gmt(cmd0::String="", arg1=nothing, kwargs...)

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
function kml2gmt(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("kml2gmt", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :bo :do :yx])
	cmd = parse_these_opts(cmd, d, [[:F :select], [:Z :altitudes], [:E :extended]])

	common_grd(d, cmd0, cmd, "kml2gmt ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
kml2gmt(arg1, cmd0::String=""; kw...) = kml2gmt(cmd0, arg1; kw...)