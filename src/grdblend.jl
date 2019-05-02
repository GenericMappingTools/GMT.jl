"""
	grdblend(cmd0::String="", arg1=nothing, arg2=nothing, kwargs...)

Reads a listing of grid files and blend parameters, or up to 2 GTMgrid types, and creates
a grid by blending the other grids using cosine-taper weights.

Full option list at [`grdblend`](http://gmt.soest.hawaii.edu/doc/latest/grdblend.html)

Parameters
----------

- **I** : **inc** : -- Str or Number --

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grdblend.html#i)
- $(GMT.opt_R)
- **G** : **outgrid** : -- Str --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdblend(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdblend.html#g)

- **C** : **clobber** : -- Str or [] --      Flags = f|l|o|u[±]

    Clobber mode: Instead of blending, simply pick the value of one of the grids that covers a node.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/grdproject.html#c)
- **N** : **nodata** : -- Str or Number --

    No data. Set nodes with no input grid to this value [Default is NaN].
	[`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdblend.html#n)
- **Q** : **headless** : -- Bool or [] --

    Create plain header-less grid file (for use with external tools). Requires that the output
    grid file is a native format (i.e., not netCDF). DO NOT USE WITH **G**.
	[`-Q`](http://gmt.soest.hawaii.edu/doc/latest/grdblend.html#q)
- **W** : **no_blend** : -- Str or [] --

    Do not blend, just output the weights used for each node [Default makes the blend].
    Append ``z`` to write the weight*z sum instead.
	[`-W`](http://gmt.soest.hawaii.edu/doc/latest/grdblend.html#w)
- **Z** : **scale** : -- Number --

    Scale output values by scale before writing to file.
	[`-Z`](http://gmt.soest.hawaii.edu/doc/latest/grdblend.html#z)
- $(GMT.opt_V)
- $(GMT.opt_f)
- $(GMT.opt_n)
- $(GMT.opt_r)
"""
function grdblend(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :f :n :r])
	cmd = parse_these_opts(cmd, d, [[:C :clobber], [:G :outgrid], [:I :inc], [:N :nodata],
				[:Q :headless], [:W :no_blend], [:Z :scale]])

	cmd, got_fname, arg1, arg2 = find_data(d, cmd0, cmd, arg1, arg2)
	return common_grd(d, "grdblend " * cmd, arg1, arg2)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdblend(arg1, arg2=nothing, cmd0::String=""; kw...) = grdblend(cmd0, arg1, arg2; kw...)