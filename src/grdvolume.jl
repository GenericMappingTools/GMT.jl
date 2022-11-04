"""
	grdvolume(cmd0::String="", arg1=nothing, kwargs...)

Reads one 2-D grid and returns xyz-triplets.

Full option list at [`grdvolume`]($(GMTdoc)grdvolume.html)

Parameters
----------

- **C** | **cont** | **contour** :: [Type => Str | List]   ``Arg = cval or low/high/delta or rlow/high or rcval``

    Find area, volume and mean height (volume/area) inside the cval contour.
    ($(GMTdoc)grdvolume.html#c)
- **L** | **base_level** :: [Type => Number]          ``Arg = base``

    Also add in the volume from the level of the contour down to base [Default base is contour].
    ($(GMTdoc)grdvolume.html#l)
- $(GMT._opt_R)
- **S** | **unit** :: [Type => Str]              ``Arg = e|f|k|M|n|u``

    For geographical grids, append a unit from e|f|k|M|n|u [Default is meter (e)].
    ($(GMTdoc)grdvolume.html#s)
- **T** :: [Type => Str]                        ``Arg = [c|h]``

    Determine the single contour that maximized the average height (= volume/area).
    ($(GMTdoc)grdvolume.html#t)
- $(GMT.opt_V)
- **Z** | **scale** :: [Type => Str or List]     ``Arg = fact[/shift]``

    Optionally subtract shift before scaling data by fact. [Default is no scaling].
    ($(GMTdoc)grdvolume.html#z)
- $(GMT._opt_f)
- $(GMT.opt_o)
"""
function grdvolume(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:R :V_params :f :o])
	cmd  = parse_these_opts(cmd, d, [[:C :cont :contour], [:L :base_level], [:S :unit], [:T], [:Z :scale]])
	common_grd(d, cmd0, cmd, "grdvolume ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdvolume(arg1; kw...) = grdvolume("", arg1; kw...)