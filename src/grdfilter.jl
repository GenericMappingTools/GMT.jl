"""
	grdfilter(cmd0::String="", arg1=nothing, kwargs...)

Filter a grid file in the time domain using one of the selected convolution or non-convolution 
isotropic or rectangular filters and compute distances using Cartesian or Spherical geometries.

See full GMT (not the `GMT.jl` one) docs at [`grdfilter`]($(GMTdoc)grdfilter.html)

Parameters
----------

- **F** | **filter** :: [Type => Str]

    Sets the filter type. 
- **D** | **distflag** | **distance** :: [Type => Number]

    Distance flag tells how grid (x,y) relates to filter width.
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdfilter(....) form.
- $(GMT.opt_I)
- **N** | **nans** :: [Type => Str]

    Determine how NaN-values in the input grid affects the filtered output. Values are i|p|r
- $(GMT._opt_R)
- **T** | **toggle** :: [Type => Bool]

    Toggle the node registration for the output grid so as to become the opposite of the input grid
- $(GMT.opt_V)
- $(GMT._opt_f)

To see the full documentation type: ``@? grdfilter``
"""
function grdfilter(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :f])
	cmd  = parse_these_opts(cmd, d, [[:D :distflag :distance], [:F :filter], [:N :nans], [:T :toggle]])

	common_grd(d, cmd0, cmd, "grdfilter ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdfilter(arg1; kw...) = grdfilter("", arg1; kw...)