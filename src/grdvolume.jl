"""
	grdvolume(cmd0::String="", arg1=nothing, kwargs...)

Reads one 2-D grid and returns xyz-triplets.

See full GMT (not the `GMT.jl` one) docs at [`grdvolume`]($(GMTdoc)grdvolume.html)

Parameters
----------

- **C** | **cont** | **contour** :: [Type => Str | List]   ``Arg = cval or low/high/delta or rlow/high or rcval``

    Find area, volume and mean height (volume/area) inside the cval contour.
- **L** | **base_level** :: [Type => Number]          ``Arg = base``

    Also add in the volume from the level of the contour down to base [Default base is contour].
- $(_opt_R)
- **S** | **unit** :: [Type => Str]              ``Arg = e|f|k|M|n|u``

    For geographical grids, append a unit from e|f|k|M|n|u [Default is meter (e)].
- **T** :: [Type => Str]                        ``Arg = [c|h]``

    Determine the single contour that maximized the average height (= volume/area).
- $(opt_V)
- **Z** | **scale** :: [Type => Str or List]     ``Arg = fact[/shift]``

    Optionally subtract shift before scaling data by fact. [Default is no scaling].
- $(_opt_f)
- $(opt_o)

To see the full documentation type: ``@? grdvolume``
"""
function grdvolume(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:R :V_params :f :o])
	cmd  = parse_these_opts(cmd, d, [[:C :cont :contour], [:L :base_level], [:S :unit], [:T], [:Z :scale]])
	common_grd(d, cmd0, cmd, "grdvolume ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdvolume(arg1; kw...) = grdvolume("", arg1; kw...)