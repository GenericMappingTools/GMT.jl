"""
	grdblend(cmd0::String="", arg1=nothing, arg2=nothing, kwargs...)

Reads a listing of grid files and blend parameters, or up to 2 GTMgrid types, and creates
a grid by blending the other grids using cosine-taper weights.

Full option list at [`grdblend`]($(GMTdoc)grdblend.html)

Parameters
----------

- **I** | **inc** :: [Type => Str | Number]

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    ($(GMTdoc)grdblend.html#i)
- $(GMT.opt_R)
- **G** | **outgrid** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdblend(....) form.
    ($(GMTdoc)grdblend.html#g)

- **C** | **clobber** :: [Type => Str | []]      ``Arg = f|l|o|u[±]``

    Clobber mode: Instead of blending, simply pick the value of one of the grids that covers a node.
    ($(GMTdoc)grdproject.html#c)
- **N** | **nodata** :: [Type => Str | Number]

    No data. Set nodes with no input grid to this value [Default is NaN].
    ($(GMTdoc)grdblend.html#n)
- **Q** | **headless** :: [Type => Bool]

    Create plain header-less grid file (for use with external tools). Requires that the output
    grid file is a native format (i.e., not netCDF). DO NOT USE WITH **G**.
    ($(GMTdoc)grdblend.html#q)
- **W** | **no_blend** :: [Type => Str | []]

    Do not blend, just output the weights used for each node [Default makes the blend].
    Append ``z`` to write the weight*z sum instead.
    ($(GMTdoc)grdblend.html#w)
- **Z** | **scale** :: [Type => Number]

    Scale output values by scale before writing to file.
    ($(GMTdoc)grdblend.html#z)
- $(GMT.opt_V)
- $(GMT.opt_f)
- $(GMT.opt_n)
- $(GMT.opt_r)
"""
function grdblend(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:R :V_params :f :n :r])
	cmd  = parse_these_opts(cmd, d, [[:C :clobber], [:G :outgrid], [:I :inc], [:N :nodata],
	                                 [:Q :headless], [:W :no_blend], [:Z :scale]])

	cmd, got_fname, arg1, arg2 = find_data(d, cmd0, cmd, arg1, arg2)
	return common_grd(d, "grdblend " * cmd, arg1, arg2)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdblend(arg1, arg2=nothing, cmd0::String=""; kw...) = grdblend(cmd0, arg1, arg2; kw...)