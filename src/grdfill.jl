"""
	grdfill(cmd0::String="", arg1=nothing, kwargs...)

Reads a grid that presumably has unfilled holes that the user wants to fill in some fashion.
Holes are identified by NaN values but this criteria can be changed.

Full option list at [`grdfill`]($(GMTdoc)grdfill.html)

Parameters
----------

- **A** | **mode** :: [Type => Str]		``Arg = mode[arg]``

    Specify the hole-filling algorithm to use. Choose from c for constant fill and append the constant value,
    n for nearest neighbor (and optionally append a search radius in pixels). 
    ($(GMTdoc)grdfill.html#a)
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdfill(....) form.
    ($(GMTdoc)grdfill.html#g)
- **L** | **list** :: [Type => Str]	``Arg = [p]``

    Just list the rectangular subregions west east south north of each hole. No grid fill takes place and
    **outgrid** is ignored. Optionally, append **p** to instead write closed polygons for all subregions.
- **N** | **nodata** :: [Type => Str]	``Arg = nodata``

    Sets the node value that identifies a point as a member of a hole [Default is NaN].
    ($(GMTdoc)grdfill.html#n)
- $(GMT._opt_R)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grdfill(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:G :R :V_params :f])
	cmd  = parse_these_opts(cmd, d, [[:A :mode :algo], [:L :list], [:N :nodata]])

	common_grd(d, cmd0, cmd, "grdfill ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdfill(arg1; kw...) = grdfill("", arg1; kw...)
