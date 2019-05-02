"""
	grdedit(cmd0::String="", arg1=nothing, kwargs...)

Reads the header information in a binary 2-D grid file and replaces the information with
values provided on the command line.

Full option list at [`grdedit`](http://gmt.soest.hawaii.edu/doc/latest/grdedit.html)

Parameters
----------

- **A** : **adjust** : -- Bool --

    If necessary, adjust the file’s x_inc, y_inc to be compatible with its domain.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/grdedit.html#a)
- **C** : **adjust** : -- Bool --

    Clear the command history from the grid header.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/grdedit.html#c)
- **D** : **header** : -- Str --    Flags = [+xxname][+yyname][+zzname][+sscale][+ooffset][+ninvalid][+ttitle][+rremark

    Change these header parameters.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdedit.html#d)
- **E** : **header** : -- Str --    Flags = [a|h|l|r|t|v]

    Transform the grid in one of six ways and (for l|r|t) interchange the x and y information
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/grdedit.html#e)
- **G** : **outgrid** : -- Str --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdedit(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdedit.html#g)
- $(GMT.opt_J)
- **N** : **replace** : -- Str or Mx3 array --

    Read the ASCII (or binary) file table and replace the corresponding nodal values in the
    grid with these x,y,z values. Alternatively, provide a Mx3 matrix with values to be changed. 
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdedit.html#n)
- $(GMT.opt_R)
- **S** : **wrap** : -- Bool --

    For global, geographical grids only. Grid values will be shifted longitudinally according to
    the new borders given in ``limits`` (R option).
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/grdedit.html#s)
- **T** : **toggle** : -- Bool --

    Make necessary changes in the header to convert a gridline-registered grid to a pixel-registered
    grid, or vice-versa.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grdedit.html#t)
- $(GMT.opt_V)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_swap_xy)
"""
function grdedit(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("grdedit", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :J :V_params :bi :di :e :f :yx])
	cmd = parse_these_opts(cmd, d, [[:A :adjust], [:C :clear_history], [:D :header], [:E :flip], [:G :outgrid],
				[:N :replace], [:S :wrap], [:T :toggle]])

	common_grd(d, cmd0, cmd, "grdedit ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdedit(arg1, cmd0::String=""; kw...) = grdedit(cmd0, arg1; kw...)