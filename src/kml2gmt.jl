"""
	kml2gmt(cmd0::String="", arg1=nothing, kwargs...)

kml2gmt - Extract GMT table data from Google Earth KML files

See full GMT (not the `GMT.jl` one) docs at [`kml2gmt`]($(GMTdoc)kml2gmt.html)

Parameters
----------

- **F** | **feature_type** :: [Type => Str]        ``Arg = s|l|p``

    Specify a particular feature type to output. Choose from points (s), line (l), or polygon (p).
    By default we output all geometries.
- **Z** | **altitudes** :: [Type => Bool]

    Output the altitude coordinates as GMT z coordinates [Default will output just longitude and latitude].
    ($(GMTdoc)kml2gmt.html#z)
- $(GMT.opt_V)
- $(GMT.opt_bo)
- $(GMT.opt_do)
- $(GMT.opt_swap_xy)

To see the full documentation type: ``@? kml2gmt``
"""
function kml2gmt(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:V_params :bo :do :yx])
	cmd  = parse_these_opts(cmd, d, [[:F :feature_type :select], [:Z :altitudes], [:E :extended]])
	common_grd(d, cmd0, cmd, "kml2gmt ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
kml2gmt(arg1; kw...) = kml2gmt("", arg1; kw...)