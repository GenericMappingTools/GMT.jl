"""
	grdproject(cmd0::String="", arg1=[], kwargs...)

Project a geographical gridded data set onto a rectangular grid or do the inverse projection.

Full option list at [`grdproject`](http://gmt.soest.hawaii.edu/doc/latest/grdproject.html)

Parameters
----------

- $(GMT.opt_J)
- **C** : **center** : -- Str or [] --      Flags = [dx/dy]

    Let projected coordinates be relative to projection center [Default is relative to lower left corner].
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/grdproject.html#c)
- **D** : **inc** : -- Str or number --     Flags = xinc[unit][+e|n][/yinc[unit][+e|n]]

    Set the grid spacing for the new grid. Append m for arc minute, s for arc second.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdproject.html#d)
- **E** : **dpi** : -- Number --

    Set the resolution for the new grid in dots per inch.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/grdproject.html#e)
- **F** : **one2one** : -- Str --           Flags = [c|i|p|e|f|k|M|n|u]

    Force 1:1 scaling, i.e., output (or input, see -I) data are in actual projected meters [e].
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/grdproject.html#f)
- **G** : **outgrid** : -- Str --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdproject(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdproject.html#g)
- **I** : **inverse** : -- Bool --

    Do the Inverse transformation, from rectangular to geographical.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grdproject.html#i)
- **M** : **projected_unit** : -- Str --    Flags = c|i|p

    Append c, i, or p to indicate that cm, inch, or point should be the projected measure unit.
    [`-M`](http://gmt.soest.hawaii.edu/doc/latest/grdproject.html#m)
- $(GMT.opt_R)
- $(GMT.opt_V)
- $(GMT.opt_n)
- $(GMT.opt_r)
"""
function grdproject(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("grdproject", cmd0, arg1)	# Speedy mode

	if (isempty(cmd0) && isempty_(arg1))
		error("Must provide the grid to work with.")
	end

	d = KW(kwargs)

	cmd, opt_R = parse_R("", d)
	cmd, opt_J = parse_J(cmd, d)
	cmd = parse_V(cmd, d)
	cmd = parse_n(cmd, d)
	cmd = parse_r(cmd, d)
	cmd = parse_params(cmd, d)

	cmd = add_opt(cmd, 'C', d, [:C :center])
	cmd = add_opt(cmd, 'D', d, [:D :inc])
	cmd = add_opt(cmd, 'E', d, [:E :dpi])
	cmd = add_opt(cmd, 'F', d, [:F :one2one])
	cmd = add_opt(cmd, 'G', d, [:G :outgrid])
	cmd = add_opt(cmd, 'I', d, [:I :inverse])
	cmd = add_opt(cmd, 'M', d, [:M :projected_unit])

	no_output = common_grd(cmd, 'G')		# See if an output is requested (or write result in grid file)
	return common_grd(d, cmd0, cmd, arg1, no_output, "grdproject")	# Shared by several grdxxx modules
end

# ---------------------------------------------------------------------------------------------------
grdproject(arg1=[], cmd0::String=""; kw...) = grdproject(cmd0, arg1; kw...)