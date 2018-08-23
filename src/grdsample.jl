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

	if (isempty(cmd0) && isempty_(arg1))
		error("Must provide the grid to work with.")
	end

	d = KW(kwargs)

	cmd, opt_R = parse_R("", d)
	cmd = parse_V(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_n(cmd, d)
	cmd = parse_r(cmd, d)
	cmd = parse_x(cmd, d)
	cmd = parse_params(cmd, d)

    cmd = add_opt(cmd, 'G', d, [:G :outgrid])
    cmd = add_opt(cmd, 'I', d, [:I :inc])
	cmd = add_opt(cmd, 'T', d, [:T :toggle])

	no_output = common_grd(cmd, 'G')		# See if an output is requested (or write result in grid file)
	return common_grd(d, cmd0, cmd, arg1, [], no_output, "grdsample")	# Shared by several grdxxx modules
end

# ---------------------------------------------------------------------------------------------------
grdsample(arg1=[], cmd0::String=""; kw...) = grdsample(cmd0, arg1; kw...)