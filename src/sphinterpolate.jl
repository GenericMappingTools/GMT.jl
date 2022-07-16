"""
	sphinterpolate(cmd0::String="", arg1=nothing, kwargs...)

Spherical gridding in tension of data on a sphere

Full option list at [`sphinterpolate`]($(GMTdoc)sphinterpolate .html)

Parameters
----------

- **D** | **skipdup** :: [Type => Bool]

    Delete any duplicate points [Default assumes there are no duplicates].
    ($(GMTdoc)sphinterpolate.html#d)
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = sphinterpolate(....) form.
    ($(GMTdoc)sphinterpolate.html#g)
- $(GMT.opt_I)
    ($(GMTdoc)sphinterpolate.html#i)
- **Q** | **tension** :: [Type => Number | Str]     ``Arg = mode[/options]``

    Specify one of four ways to calculate tension factors to preserve local shape properties or satisfy arc constraints.
    ($(GMTdoc)sphinterpolate.html#q)
- **T** | **var_tension** :: [Type => Bool | Str]

    Use variable tension (ignored with -Q0 [constant]
    ($(GMTdoc)sphinterpolate.html#t)
- **Z** | **scale** :: [Type => Bool | Str]

    Before interpolation, scale data by the maximum data range [no scaling].
    ($(GMTdoc)sphinterpolate.html#z)
- $(GMT.opt_R)
- $(GMT.opt_V)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_r)
- $(GMT.opt_swap_xy)
"""
function sphinterpolate(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :bi :di :e :h :i :yx])
	cmd  = parse_these_opts(cmd, d, [[:D :skipdup :duplicates], [:Q :tension], [:T :nodetable], [:Z :scale]])

	common_grd(d, cmd0, cmd, "sphinterpolate ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
sphinterpolate(arg1, cmd0::String=""; kw...) = sphinterpolate(cmd0, arg1; kw...)