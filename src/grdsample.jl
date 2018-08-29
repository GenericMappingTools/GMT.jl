"""
	grdsample(cmd0::String="", arg1=[], kwargs...)

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
function grdsample(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("grdsample", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)

	cmd, = parse_R("", d)
	cmd = parse_V_params(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_n(cmd, d)
	cmd, = parse_r(cmd, d)
	cmd, = parse_x(cmd, d)

    cmd = add_opt(cmd, 'G', d, [:G :outgrid])
    cmd = add_opt(cmd, 'I', d, [:I :inc])
	cmd = add_opt(cmd, 'T', d, [:T :toggle])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	if (isa(arg1, Array{<:Number}))		arg1 = mat2grid(arg1)	end
	return common_grd(d, cmd, got_fname, 1, "grdsample", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdsample(arg1=[], cmd0::String=""; kw...) = grdsample(cmd0, arg1; kw...)