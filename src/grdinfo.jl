"""
    grdinfo(cmd0::String="", arg1=nothing; kwargs...)

Reads a 2-D grid file and reports metadata and various statistics for the (x,y,z) data in the grid file

Full option list at [`grdinfo`]($(GMTdoc)grdinfo.html)

Parameters
----------

- **C** | **numeric** :: [Type => Str | Number]

    Formats the report using tab-separated fields on a single line.
    ($(GMTdoc)grdinfo.html#c)
- **D** | **tiles** :: [Type => Number | Str]  

    Divide a single grid’s domain (or the -R domain, if no grid given) into tiles of size
    dx times dy (set via -I).
    ($(GMTdoc)grdinfo.html#d)
- **F** :: [Type => Bool]

    Report grid domain and x/y-increments in world mapping format.
    ($(GMTdoc)grdinfo.html#f)
- **G** | **force_download** :: [Type => Bool]

    Force (possible) download and mosaicing of all tiles of tiled global remote grids in order
    to report the requested information.
    ($(GMTdoc)grdinfo.html#g)
- **I** | **nearest** :: [Type => Number | Str]     ``Arg = [dx[/dy]|b|i|r]``

    Report the min/max of the region to the nearest multiple of dx and dy, and output
    this in the form -Rw/e/s/n
    ($(GMTdoc)grdinfo.html#i)
- **L** | **force_scan** :: [Type => Number | Str]

    Report stats after actually scanning the data.
    ($(GMTdoc)grdinfo.html#l)
- **M** | **minmax_pos** :: [Type => Bool]

    Find and report the location of min/max z-values.
    ($(GMTdoc)grdinfo.html#m)
- **Q** | **cube** :: [Type => Bool]

    Input files must be data 3-D netCDF data cube. Not compatible with **D**, **E**, **F**, and **Ib** (GMT6.2)
    ($(GMTdoc)grdinfo.html#q)
- $(GMT.opt_R)
- **T** | **zmin_max** :: [Type => Number | Str]
    Determine min and max z-value.
    ($(GMTdoc)grdinfo.html#t)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grdinfo(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && !isa(arg1, GMTgrid) && return monolitic("grdinfo", cmd0, arg1)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:R :V_params :f])
	cmd  = parse_these_opts(cmd, d, [[:C :numeric], [:D :tiles], [:F], [:G :force_download], [:I :nearest],
	                                 [:L :force_scan], [:M :minmax_pos], [:Q :cube], [:T :zmin_max]])
    (isa(arg1, GMTgrid) && size(arg1,3) > 1 && !occursin("-Q", cmd)) && (cmd *= " -Q")  # arg1 is a CUBE
	common_grd(d, cmd0, cmd, "grdinfo ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdinfo(arg1, cmd0::String=""; kw...) = grdinfo(cmd0, arg1; kw...)