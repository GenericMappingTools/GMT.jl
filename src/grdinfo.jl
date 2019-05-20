"""
    grdinfo(cmd0::String="", arg1=nothing; kwargs...)

Reads a 2-D grid file and reports metadata and various statistics for the (x,y,z) data in the grid file

Full option list at [`grdinfo`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html)

Parameters
----------

- **C** : **numeric** : -- Str or Number --

    Formats the report using tab-separated fields on a single line.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#c)
- **D** : **tiles** : -- Number or Str --  

    Divide a single grid’s domain (or the -R domain, if no grid given) into tiles of size
    dx times dy (set via -I).
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#d)
- **F** : -- Bool or [] --

    Report grid domain and x/y-increments in world mapping format.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#f)
- **I** : **nearest** : -- Number or Str --     Flags = [dx[/dy]|b|i|r]

    Report the min/max of the region to the nearest multiple of dx and dy, and output
    this in the form -Rw/e/s/n
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#i)
- **L** : **force_scan** : -- Number or Str --

    Report stats after actually scanning the data.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#l)
- **M** : **minmax_pos** : -- Bool or [] --

    Find and report the location of min/max z-values.
    [`-M`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#m)
- $(GMT.opt_R)
- **T** : **zmin_max** : -- Number or Str --
    Determine min and max z-value.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grdinfo.html#t)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grdinfo(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && !isa(arg1, GMTgrid) && return monolitic("grdinfo", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :f])
	cmd = parse_these_opts(cmd, d, [[:C :numeric], [:D :tiles], [:F], [:I :nearest],
				[:L :force_scan], [:M :minmax_pos], [:T :zmin_max]])

	common_grd(d, cmd0, cmd, "grdinfo ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdinfo(arg1, cmd0::String=""; kw...) = grdinfo(cmd0, arg1; kw...)