"""
	grdproject(cmd0::String="", arg1=nothing, kwargs...)

Project a geographical gridded data set onto a rectangular grid or do the inverse projection.

Full option list at [`grdproject`]($(GMTdoc)grdproject.html)

Parameters
----------

- $(GMT.opt_J)
- **C** | **center** :: [Type => Str | []]      ``Arg = [dx/dy]``

    Let projected coordinates be relative to projection center [Default is relative to lower left corner].
    ($(GMTdoc)grdproject.html#c)
- **D** | **inc** :: [Type => Str | number]     ``Arg = xinc[unit][+e|n][/yinc[unit][+e|n]]``

    Set the grid spacing for the new grid. Append m for arc minute, s for arc second.
    ($(GMTdoc)grdproject.html#d)
- **E** | **dpi** :: [Type => Number]

    Set the resolution for the new grid in dots per inch.
    ($(GMTdoc)grdproject.html#e)
- **F** | **one2one** :: [Type => Str]           ``Arg = [c|i|p|e|f|k|M|n|u]``

    Force 1:1 scaling, i.e., output (or input, see -I) data are in actual projected meters [e].
    ($(GMTdoc)grdproject.html#f)
- **G** | **outgrid** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdproject(....) form.
    ($(GMTdoc)grdproject.html#g)
- **I** | **inverse** :: [Type => Bool]

    Do the Inverse transformation, from rectangular to geographical.
    ($(GMTdoc)grdproject.html#i)
- **M** | **projected_unit** :: [Type => Str]    ``Arg = c|i|p``

    Append c, i, or p to indicate that cm, inch, or point should be the projected measure unit.
    ($(GMTdoc)grdproject.html#m)
- $(GMT.opt_R)
- $(GMT.opt_V)
- $(GMT.opt_n)
- $(GMT.opt_r)
"""
function grdproject(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("grdproject", cmd0, arg1)

	d = KW(kwargs)
	cmd, = parse_common_opts(d, "", [:R :V_params :n :r])
	if ((val = find_in_dict(d, [:J :proj :projection], false)[1]) !== nothing)  # Here we don't want any default value
		cmd = parse_J(cmd, d, "", false)[1];
	end
	cmd = parse_these_opts(cmd, d, [[:C :center], [:D :inc], [:E :dpi], [:F :one2one],
	                                [:G :outgrid], [:I :inverse], [:M :projected_unit]])

	common_grd(d, cmd0, cmd, "grdproject ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdproject(arg1, cmd0::String=""; kw...) = grdproject(cmd0, arg1; kw...)