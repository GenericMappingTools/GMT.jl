"""
	grdsample(cmd0::String="", arg1=nothing, kwargs...)

Reads a grid file and interpolates it to create a new grid file with either: a
different registration; or a new grid-spacing or number of nodes, and perhaps
also a new sub-region

See full GMT docs at [`grdsample`]($(GMTdoc)grdsample.html)

Parameters
----------

- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdsample(....) form.
- $(opt_I)
- $(_opt_R)
- **T** | **toggle** :: [Type => Bool]

    Toggle the node registration for the output grid so as to become the opposite of the input grid
- $(opt_V)
- $(_opt_f)
- $(opt_n)
- $(opt_r)
- $(opt_x)

To see the full documentation type: ``@? grdsample``
"""
grdsample(cmd0::String; kwargs...) = grdsample_helper(cmd0, nothing; kwargs...)
grdsample(arg1; kwargs...)         = grdsample_helper("", arg1; kwargs...)
function grdsample_helper(cmd0::String, arg1; kwargs...)
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	grdsample_helper(wrapGrids(cmd0, arg1), d)
end

# ---------------------------------------------------------------------------------------------------
function grdsample_helper(w::wrapGrids, d::Dict{Symbol, Any})
	cmd0, arg1 = unwrapGrids(w)

	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :f :n :x])
	cmd  = parse_these_opts(cmd, d, [[:T :toggle]])
	common_grd(d, cmd0, cmd, "grdsample ", arg1)		# Finish build cmd and run it
end
