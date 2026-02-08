"""
	grdproject(cmd0::String="", arg1=nothing, kwargs...)

Project a geographical gridded data set onto a rectangular grid or do the inverse projection.

See full GMT docs at [`grdproject`]($(GMTdoc)grdproject.html)

Parameters
----------

- $(_opt_J)
- **C** | **center** :: [Type => Str | []]      ``Arg = [dx/dy]``

    Let projected coordinates be relative to projection center [Default is relative to lower left corner].
- **D** | **inc** :: [Type => Str | number]     ``Arg = xinc[unit][+e|n][/yinc[unit][+e|n]]``

    Set the grid spacing for the new grid. Append m for arc minute, s for arc second.
- **E** | **dpi** :: [Type => Number]

    Set the resolution for the new grid in dots per inch.
- **F** | **one2one** :: [Type => Str]           ``Arg = [c|i|p|e|f|k|M|n|u]``

    Force 1:1 scaling, i.e., output (or input, see -I) data are in actual projected meters [e].
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdproject(....) form.
- **I** | **inverse** :: [Type => Bool]

    Do the Inverse transformation, from rectangular to geographical.
- **M** | **projected_unit** :: [Type => Str]    ``Arg = c|i|p``

    Append c, i, or p to indicate that cm, inch, or point should be the projected measure unit.
- $(_opt_R)
- $(opt_V)
- $(opt_n)
- $(opt_r)

To see the full documentation type: ``@? grdproject``
"""
grdproject(cmd0::String; kwargs...) = grdproject_helper(cmd0, nothing; kwargs...)
grdproject(arg1; kwargs...)         = grdproject_helper("", arg1; kwargs...)
function grdproject_helper(cmd0::String, arg1; kwargs...)
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	grdproject_helper(cmd0, arg1, d)
end

# ---------------------------------------------------------------------------------------------------
function grdproject_helper(cmd0::String, arg1, d::Dict{Symbol, Any})

	cmd::String = parse_n(d, "", true)[1]			# Here we keep the GMT default to Antialiasing
	cmd = parse_common_opts(d, cmd, [:G :R :V_params :r])[1]
	if ((val = find_in_dict(d, [:J :proj :projection], false)[1]) !== nothing)  # Here we don't want any default value
		cmd = parse_J(d, cmd, default="", map=false)[1];
	else						# See if the grid/image has proj info and use it if we can 
		prj::String = (arg1 !== nothing) ? getproj(arg1, proj4=true) : ""
		(prj == "" && cmd0 != "") && (prj = getproj(cmd0, proj4=true))
		(prj != "") && (cmd *= " -J\"" * prj * "\"")
	end
	cmd = parse_these_opts(cmd, d, [[:C :center], [:D :inc], [:E :dpi], [:F :one2one], [:I :inverse], [:M :projected_unit]])

	common_grd(d, cmd0, cmd, "grdproject ", arg1)	# Finish build cmd and run it
end
