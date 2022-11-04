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
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdfilter(....) form.
    ($(GMTdoc)grdfilter.html#g)
- $(GMT.opt_I)
    ($(GMTdoc)grdfilter.html#i)
- **N** | **nans** :: [Type => Str]

    Determine how NaN-values in the input grid affects the filtered output. Values are i|p|r
    ($(GMTdoc)grdfilter.html#n)
- $(GMT._opt_R)
- **T** | **toggle** :: [Type => Bool]

    Toggle the node registration for the output grid so as to become the opposite of the input grid
    ($(GMTdoc)grdfilter.html#t)
- $(GMT.opt_V)
- $(GMT._opt_f)
"""
function grdfilter(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :f])
	cmd  = parse_these_opts(cmd, d, [[:D :distflag :distance], [:F :filter], [:N :nans], [:T :toggle]])

	common_grd(d, cmd0, cmd, "grdfilter ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdfilter(arg1; kw...) = grdfilter("", arg1; kw...)