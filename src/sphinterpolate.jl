"""
	sphinterpolate(cmd0::String="", arg1=[], kwargs...)

Spherical gridding in tension of data on a sphere

Full option list at [`sphinterpolate`](http://gmt.soest.hawaii.edu/doc/latest/sphinterpolate .html)

Parameters
----------

- **G** : **outgrid** : -- Str --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = sphinterpolate(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/sphinterpolate.html#g)
- **I** : **inc** : -- Str or Number --

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/sphinterpolate.html#i)
- **Q** : **tension** : -- Number or Str --     Flags = mode[/options]

    Specify one of four ways to calculate tension factors to preserve local shape properties or satisfy arc constraints.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/sphinterpolate .html#q)
- **T** : **var_tension** : -- Bool or Str --

    Use variable tension (ignored with -Q0 [constant]
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/sphinterpolate.html#t)
- **Z** : **scale** : -- Bool or Str --

    Before interpolation, scale data by the maximum data range [no scaling].
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/sphinterpolate.html#z)
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
function sphinterpolate(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("sphinterpolate ", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)

	cmd = parse_R("", d)
	cmd = parse_V(cmd, d)
	cmd, = parse_bi(cmd, d)
	cmd = parse_di(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd = parse_r(cmd, d)
	cmd = parse_swap_xy(cmd, d)
	cmd = parse_params(cmd, d)

    cmd = add_opt(cmd, 'G', d, [:G :outgrid])
	cmd = add_opt(cmd, 'I', d, [:I :inc])
	cmd = add_opt(cmd, 'Q', d, [:Q :tension])
	cmd = add_opt(cmd, 'T', d, [:T :nodetable])
	cmd = add_opt(cmd, 'Z', d, [:Z :scale])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "sphinterpolate", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
sphinterpolate(arg1=[], cmd0::String=""; kw...) = sphinterpolate(cmd0, arg1; kw...)