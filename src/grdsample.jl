"""
	grdsample(cmd0::String="", arg1=nothing, kwargs...)

Reads a grid file and interpolates it to create a new grid file with either: a
different registration; or a new grid-spacing or number of nodes, and perhaps
also a new sub-region

Full option list at [`grdsample`](http://gmt.soest.hawaii.edu/doc/latest/grdsample.html)

Parameters
----------

- **G** : **outgrid** : -- Str --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdsample(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdsample.html#g)
- **I** : **inc** : -- Str or Number --

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grdsample.html#i)
- $(GMT.opt_R)
- **T** : **toggle** : -- Bool --

    Toggle the node registration for the output grid so as to become the opposite of the input grid
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grdsample.html#t)
- $(GMT.opt_V)
- $(GMT.opt_f)
- $(GMT.opt_n)
- $(GMT.opt_r)
- $(GMT.opt_x)
"""
function grdsample(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("grdsample", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :f :n :r :x])
	cmd = parse_these_opts(cmd, d, [[:G :outgrid], [:I :inc], [:T :toggle]])

	common_grd(d, cmd0, cmd, "grdsample ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdsample(arg1, cmd0::String=""; kw...) = grdsample(cmd0, arg1; kw...)