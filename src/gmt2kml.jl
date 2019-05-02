"""
	gmt2kml(cmd0::String="", arg1=nothing, kwargs...)

Convert GMT data tables to KML files for Google Earth

Full option list at [`gmt2kml`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html)

Parameters
----------

- **A** : **altitude_mode** : -- Str --       Flags = a|g|s[alt|xscale]

    Select one of three altitude modes recognized by Google Earth that determines the altitude (in m)
    of the feature: ``a`` absolute altitude, ``g`` altitude relative to sea surface or ground,
    ``s`` altitude relative to seafloor or ground.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#A)
- $(GMT.opt_C)
- **D** : **descript** : -- Str --   Flags = descriptfile

    File with HTML snippets that will be included as part of the main description content for the KML file.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#d)
- **E** : **extrude** : -- Str or [] --   Flags = [altitude]

    Extrude feature down to ground level.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#e)
- **F** : **feature_type** : -- Str --   Flags = e|s|t|l|p|w

    Sets the feature type. Choose from points (event, symbol, or timespan), line, polygon, or wiggle.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#f)
- **G** : **fill** : -- Str --  Flags = f|nfill

    Sets color fill (G=:f) or label font color (G=:n).
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#g)
- **I** : **icon** : -- Str --      Flags = icon

    Specify the URL to an alternative icon that should be used for the symbol
    [Default is a Google Earth circle].
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#i)
- **K** : **not_finished** : -- Bool or [] --

    Allow more KML code to be appended to the output later [finalize the KML file].
    [`-K`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#i)
- **L** : **extended_data** : -- Str --      Flags = name1,name2,…

    Extended data given. Append one or more column names separated by commas.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#l)
- **N** : **feature_name** : -- Str or Number --      Flags = [t|col |name_template|name]

    By default, if segment headers contain a -L”label string” then we use that for the name of the KML feature.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#n)
- **O** : **overlay** : -- Bool or [] --

    Append KML code to an existing KML file [initialize a new KML file].
    [`-O`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#n)
- **Qa** : **wiggles** : -- Str --      Flags =  azimuth

    Option in support of wiggle plots (requires F=:w).
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#q)
- **Qs** : **wiggle_scale** : -- Number or Str --      Flags =  scale[unit]

    Required setting for wiggle plots (i.e., it requires F=:w). Sets a wiggle scale
    in z-data units per the user’s units
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#q)
- $(GMT.opt_R)
- **S** : **scale** : -- Str --      Flags =  c|nscale

    Scale icons or labels. Here, S=:c sets a scale for the symbol icon, whereas S=:n sets
    a scale for the name labels
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#s)
- **T** : **title ** : -- Str --    Flags = title[/foldername]

    Sets the document title [default is unset]. Optionally, append /FolderName;
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#t)
- **W** : **pen** : -- Str or [] --      Flags =  [pen][attr]

    Set pen attributes for lines, wiggles or polygon outlines.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#w)
- **Z** : **attrib** : -- Str --      Flags =  args

    Set one or more attributes of the Document and Region tags.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/gmt2kml.html#z)
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

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("gmt2kml", cmd0, arg1)

	d = KW(kwargs)

	cmd = parse_common_opts(d, "", [:R :V_params :bi :di :e :f :h :i :yx])
	cmd = parse_these_opts(cmd, d, [[:A :altitude_mode], [:D :descript], [:E :extrude], [:F :feature_type],
		[:I :icon], [:K :not_finished], [:L :extended_data], [:N :feature_name], [:O :overlay], [:Qa :wiggles],
		[:Qs :wiggle_scale], [:S :scale], [:T :title], [:Z :attrib]])

	cmd = add_opt(cmd, 'G', d, [:G :fill])
	cmd *= add_opt_pen(d, [:W :pen], "W")

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)
	N_used = got_fname == 0 ? 1 : 0			# To know whether a cpt will go to arg1 or arg2
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_used, arg1)
	common_grd(d, "gmt2kml " * cmd, arg1, arg2)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmt2kml(arg1, cmd0::String=""; kw...) = gmt2kml(cmd0, arg1; kw...)