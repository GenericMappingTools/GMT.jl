"""
	xyz2grd(cmd0::String="", arg1=nothing; kwargs...)

Convert data table to a grid file. 

Full option list at [`xyz2grd`](http://gmt.soest.hawaii.edu/doc/latest/xyz2grd.html)

Parameters
----------

- **I** : **inc** : -- Str or Number --     Flags = xinc[unit][+e|n][/yinc[unit][+e|n]]

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/xyz2grd.html#i)
- $(GMT.opt_R)
- **A** : **multiple_nodes** : -- Str --      Flags = [d|f|l|m|n|r|S|s|u|z]

    By default we will calculate mean values if multiple entries fall on the same node.
    Use A to change this behavior.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/xyz2grd.html#a)
- **D** : **header** : -- Str --  Flags = [+xxname][+yyname][+zzname][+sscale][+ooffset][+ninvalid][+ttitle][+rremark]

    Output edges
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/xyz2grd.html#d)
- **G** : **outgrid** : -- Str --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdclip(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/xyz2grd.html#g)
- $(GMT.opt_J)
- **S** : **swap** : -- Str or [] --        Flags = [zfile]

    Swap the byte-order of the input only. No grid file is produced.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/xyz2grd.html#s)
- $(GMT.opt_V)
- **Z** : **flags** : -- Str --

    Read a 1-column table. This assumes that all the nodes are present and sorted according to specified ordering convention contained in. ``flags``.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/grd2xyz.html#z)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_r)
- $(GMT.opt_swap_xy)
"""
function xyz2grd(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("xyz2grd", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :J :V_params :bi :di :e :f :h :i :r :yx])
	cmd = parse_these_opts(cmd, d, [[:A :multiple_nodes], [:D :header], [:G :outgrid], [:I :inc],
				[:S :swap], [:Z :flags]])

	common_grd(d, cmd0, cmd, "xyz2grd ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
xyz2grd(arg1::Array, cmd0::String=""; kw...) = xyz2grd(cmd0, arg1; kw...)