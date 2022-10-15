"""
	gmt2kml(cmd0::String="", arg1=nothing, kwargs...)

Convert GMT data tables to KML files for Google Earth

Full option list at [`gmt2kml`]($(GMTdoc)gmt2kml.html)

Parameters
----------

- **A** | **altitude_mode** :: [Type => Str]       ``Arg = a|g|s[alt|xscale]``

    Select one of three altitude modes recognized by Google Earth that determines the altitude (in m)
    of the feature: ``a`` absolute altitude, ``g`` altitude relative to sea surface or ground,
    ``s`` altitude relative to seafloor or ground.
    ($(GMTdoc)gmt2kml.html#a)
- $(GMT.opt_C)
- **D** | **descript** :: [Type => Str]   ``Arg = descriptfile``

    File with HTML snippets that will be included as part of the main description content for the KML file.
    ($(GMTdoc)gmt2kml.html#d)
- **E** | **extrude** :: [Type => Str | []]  ``Arg = [altitude]``

    Extrude feature down to ground level.
    ($(GMTdoc)gmt2kml.html#e)
- **F** | **feature_type** :: [Type => Str]  ``Arg = e|s|t|l|p|w``

    Sets the feature type. Choose from points (event, symbol, or timespan), line, polygon, or wiggle.
    ($(GMTdoc)gmt2kml.html#f)
- **G** | **fill** :: [Type => Str]  ``Arg = f|nfill``

    Sets color fill (G=:f) or label font color (G=:n).
    ($(GMTdoc)gmt2kml.html#g)
- **I** | **icon** :: [Type => Str]      ``Arg = icon``

    Specify the URL to an alternative icon that should be used for the symbol
    [Default is a Google Earth circle].
    ($(GMTdoc)gmt2kml.html#i)
- **K** | **not_over** :: [Type => Bool]

    Allow more KML code to be appended to the output later [finalize the KML file].
    ($(GMTdoc)gmt2kml.html#k)
- **L** | **extra_data** :: [Type => Str]      ``Arg = name1,name2,…``

    Extended data given. Append one or more column names separated by commas.
    ($(GMTdoc)gmt2kml.html#l)
- **N** | **feature_name** :: [Type => Str | Number]      ``Arg = [t|col |name_template|name]``

    By default, if segment headers contain a -L”label string” then we use that for the name of the KML feature.
    ($(GMTdoc)gmt2kml.html#n)
- **O** | **overlay** :: [Type => Bool]

    Append KML code to an existing KML file [initialize a new KML file].
    ($(GMTdoc)gmt2kml.html#o)
- **Qa** | **wiggles** :: [Type => Str]      ``Arg =  azimuth``

    Option in support of wiggle plots (requires F=:w).
    ($(GMTdoc)gmt2kml.html#q)
- **Qs** | **wiggle_scale** :: [Type => Str | Number]      ``Arg =  scale[unit]``

    Required setting for wiggle plots (i.e., it requires F=:w). Sets a wiggle scale
    in z-data units per the user’s units
    ($(GMTdoc)gmt2kml.html#q)
- $(GMT.opt_R)
- **S** | **ilscale** :: [Type => Str]      ``Arg =  c|nscale``

    Scale icons or labels. Here, S=:c sets a scale for the symbol icon, whereas S=:n sets
    a scale for the name labels
    ($(GMTdoc)gmt2kml.html#s)
- **T** | **title** :: [Type => Str]    ``Arg = title[/foldername]``

    Sets the document title [default is unset]. Optionally, append /FolderName;
    ($(GMTdoc)gmt2kml.html#t)
- **W** | **pen** :: [Type => Str | []]      ``Arg =  [pen][attr]``

    Set pen attributes for lines, wiggles or polygon outlines.
    ($(GMTdoc)gmt2kml.html#w)
- **Z** | **attrib** :: [Type => Str]      ``Arg =  args``

    Set one or more attributes of the Document and Region tags.
    ($(GMTdoc)gmt2kml.html#z)
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_swap_xy)
"""
function gmt2kml(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_common_opts(d, "", [:R :V_params :bi :di :e :f :h :i :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :altitude_mode], [:D :descript], [:E :extrude], [:F :feature_type],
	                                 [:I :icon], [:K :not_over], [:L :extra_data], [:N :feature_name], [:O :overlay], [:Qa :wiggles], [:Qi :wiggle_fixedazim], [:Qs :wiggle_scale], [:S :ilscale], [:T :title], [:Z :attrib]])

	cmd = add_opt(d, cmd, "G", [:G :fill])
	cmd *= add_opt_pen(d, [:W :pen], "W")

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)
	N_used = got_fname == 0 ? 1 : 0			# To know whether a cpt will go to arg1 or arg2
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, CPTaliases, 'C', N_used, arg1)
    cmd = write_data(d, cmd)
	common_grd(d, "gmt2kml " * cmd, arg1, arg2)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmt2kml(arg1, cmd0::String=""; kw...) = gmt2kml(cmd0, arg1; kw...)