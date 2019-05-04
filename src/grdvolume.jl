"""
	grdvolume(cmd0::String="", arg1=nothing, kwargs...)

Reads one 2-D grid and returns xyz-triplets.

Full option list at [`grdvolume`](http://gmt.soest.hawaii.edu/doc/latest/grdvolume.html)

Parameters
----------

- **C** : **cont** : **contour** : -- Str or List --   Flags = cval or low/high/delta or rlow/high or rcval

    Find area, volume and mean height (volume/area) inside the cval contour.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/grdvolume.html#c)
- **L** : **base_level** : -- Number --           Flags = base

    Also add in the volume from the level of the contour down to base [Default base is contour].
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/grdvolume.html#l)
- $(GMT.opt_R)
- **S** : **unit** : -- Str --              Flags = e|f|k|M|n|u

    For geographical grids, append a unit from e|f|k|M|n|u [Default is meter (e)].
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/grdvolume.html#s)
- **T** : -- Str --                         Flags = [c|h]

    Determine the single contour that maximized the average height (= volume/area).
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grdvolume.html#t)
- $(GMT.opt_V)
- **Z** : **scale** : -- Str or List --     Flags = fact[/shift]

    Optionally subtract shift before scaling data by fact. [Default is no scaling].
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/grdvolume.html#z)
- $(GMT.opt_f)
- $(GMT.opt_o)
"""
function grdvolume(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("grdvolume", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :f :o])
	cmd = parse_these_opts(cmd, d, [[:C :cont :contour], [:L :base_level], [:S :unit], [:T], [:Z :scale]])

	common_grd(d, cmd0, cmd, "grdvolume ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdvolume(arg1, cmd0::String=""; kw...) = grdvolume(cmd0, arg1; kw...)