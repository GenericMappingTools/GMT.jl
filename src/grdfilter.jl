"""
	grdfilter(cmd0::String="", arg1=nothing, kwargs...)

Filter a grid file in the time domain using one of the selected convolution or non-convolution 
isotropic or rectangular filters and compute distances using Cartesian or Spherical geometries.

Full option list at [`grdfilter`]($(GMTdoc)grdfilter.html)

Parameters
----------

- **F** | **filter** :: [Type => Str]

    Sets the filter type. 
    ($(GMTdoc)grdfilter.html#f)
- **D** | **distflag** | **distance** :: [Type => Number]

    Distance flag tells how grid (x,y) relates to filter width.
    ($(GMTdoc)grdfilter.html#d)
- **G** | **outgrid** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdfilter(....) form.
    ($(GMTdoc)grdfilter.html#g)
- **I** | **inc** :: [Type => Str or Number]

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    ($(GMTdoc)grdfilter.html#i)
- **N** | **nans** :: [Type => Str]

    Determine how NaN-values in the input grid affects the filtered output. Values are i|p|r
    ($(GMTdoc)grdfilter.html#n)
- $(GMT.opt_R)
- **T** | **toggle** :: [Type => Bool]

    Toggle the node registration for the output grid so as to become the opposite of the input grid
    ($(GMTdoc)grdfilter.html#t)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grdfilter(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("grdfilter", cmd0, arg1)

	d = KW(kwargs)
	cmd, = parse_common_opts(d, "", [:R :I :V_params :f])
	cmd  = parse_these_opts(cmd, d, [[:D :distflag :distance], [:F :filter], [:G :outgrid], [:N :nans], [:T :toggle]])

	common_grd(d, cmd0, cmd, "grdfilter ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdfilter(arg1, cmd0::String=""; kw...) = grdfilter(cmd0, arg1; kw...)