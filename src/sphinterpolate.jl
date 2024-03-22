"""
	sphinterpolate(cmd0::String="", arg1=nothing, kwargs...)

Spherical gridding in tension of data on a sphere

See full GMT (not the `GMT.jl` one) docs at [`sphinterpolate`]($(GMTdoc)sphinterpolate .html)

Parameters
----------

- **D** | **skipdup** :: [Type => Bool]

    Delete any duplicate points [Default assumes there are no duplicates].
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = sphinterpolate(....) form.
- $(opt_I)
- **Q** | **tension** :: [Type => Number | Str]     ``Arg = mode[/options]``

    Specify one of four ways to calculate tension factors to preserve local shape properties or satisfy arc constraints.
- **T** | **var_tension** :: [Type => Bool | Str]

    Use variable tension (ignored with -Q0 [constant]
- **Z** | **scale** :: [Type => Bool | Str]

    Before interpolation, scale data by the maximum data range [no scaling].
- $(_opt_R)
- $(opt_V)
- $(_opt_bi)
- $(_opt_di)
- $(opt_e)
- $(_opt_h)
- $(_opt_i)
- $(opt_r)
- $(opt_swap_xy)

To see the full documentation type: ``@? sphinterpolate``
"""
function sphinterpolate(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :bi :di :e :h :i :yx])
	cmd  = parse_these_opts(cmd, d, [[:D :skipdup :duplicates], [:Q :tension], [:T :nodetable], [:Z :scale]])

	common_grd(d, cmd0, cmd, "sphinterpolate ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
sphinterpolate(arg1; kw...) = sphinterpolate("", arg1; kw...)