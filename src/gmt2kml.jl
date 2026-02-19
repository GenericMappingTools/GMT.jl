"""
	gmt2kml(cmd0::String="", arg1=nothing, kwargs...)

Convert GMT data tables to KML files for Google Earth

Parameters
----------

- **A** | **altitude_mode** :: [Type => Str]       ``Arg = a|g|s[alt|xscale]``

    Select one of three altitude modes recognized by Google Earth that determines the altitude (in m)
    of the feature: ``a`` absolute altitude, ``g`` altitude relative to sea surface or ground,
    ``s`` altitude relative to seafloor or ground.
- $(opt_C)
- **D** | **descript** :: [Type => Str]   ``Arg = descriptfile``

    File with HTML snippets that will be included as part of the main description content for the KML file.
- **E** | **extrude** :: [Type => Str | []]  ``Arg = [altitude]``

    Extrude feature down to ground level.
- **F** | **feature_type** :: [Type => Str]  ``Arg = e|s|t|l|p|w``

    Sets the feature type. Choose from points (event, symbol, or timespan), line, polygon, or wiggle.
- **G** | **fill** :: [Type => Str]  ``Arg = f|nfill``

    Sets color fill (G=:f) or label font color (G=:n).
- **I** | **icon** :: [Type => Str]      ``Arg = icon``

    Specify the URL to an alternative icon that should be used for the symbol
    [Default is a Google Earth circle].
- **K** | **not_over** :: [Type => Bool]

    Allow more KML code to be appended to the output later [finalize the KML file].
- **L** | **extra_data** :: [Type => Str]      ``Arg = name1,name2,…``

    Extended data given. Append one or more column names separated by commas.
- **N** | **feature_name** :: [Type => Str | Number]      ``Arg = [t|col |name_template|name]``

    By default, if segment headers contain a -L”label string” then we use that for the name of the KML feature.
- **O** | **overlay** :: [Type => Bool]

    Append KML code to an existing KML file [initialize a new KML file].
- **Qa** | **wiggles** :: [Type => Str]      ``Arg =  azimuth``

    Option in support of wiggle plots (requires F=:w).
- **Qs** | **wiggle_scale** :: [Type => Str | Number]      ``Arg =  scale[unit]``

    Required setting for wiggle plots (i.e., it requires F=:w). Sets a wiggle scale
    in z-data units per the user’s units
- $(_opt_R)
- **S** | **ilscale** :: [Type => Str]      ``Arg =  c|nscale``

    Scale icons or labels. Here, S=:c sets a scale for the symbol icon, whereas S=:n sets
    a scale for the name labels
- **T** | **title** :: [Type => Str]    ``Arg = title[/foldername]``

    Sets the document title [default is unset]. Optionally, append /FolderName;
- **W** | **pen** :: [Type => Str | []]      ``Arg =  [pen][attr]``

    Set pen attributes for lines, wiggles or polygon outlines.
- **Z** | **attrib** :: [Type => Str]      ``Arg =  args``

    Set one or more attributes of the Document and Region tags.
- $(opt_V)
- $(opt_write)
- $(opt_append)

To see the full documentation type: ``@? gmt2kml``
"""
gmt2kml(cmd0::String; kw...) = gmt2kml_helper(cmd0, nothing; kw...)
gmt2kml(arg1; kw...)         = gmt2kml_helper("", arg1; kw...)

# ---------------------------------------------------------------------------------------------------
function gmt2kml_helper(cmd0::String, arg1; kw...)
	d = init_module(false, kw...)[1]
	gmt2kml_helper(wrapDatasets(cmd0, arg1), d)
end
function gmt2kml_helper(w::wrapDatasets, d::Dict{Symbol, Any})
	cmd0, arg1 = unwrapDatasets(w::wrapDatasets)

	cmd, = parse_common_opts(d, "", [:R :V_params :bi :di :e :f :h :i :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :altitude_mode], [:D :descript], [:E :extrude], [:F :feature_type], [:G :fill],
	                                 [:I :icon], [:K :not_over], [:L :extra_data], [:N :feature_name], [:O :overlay], [:Qa :wiggles], [:Qi :wiggle_fixedazim], [:Qs :wiggle_scale], [:S :ilscale], [:T :title], [:Z :attrib]])

	cmd *= add_opt_pen(d, [:W :pen], opt="W")

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)
	N_used = got_fname == 0 ? 1 : 0			# To know whether a cpt will go to arg1 or arg2
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, CPTaliases, 'C', N_used, arg1)
    cmd = write_data(d, cmd)
	common_grd(d, "gmt2kml " * cmd, arg1, arg2)		# Finish build cmd and run it
end
