"""
	grdtrack(cmd0::String="", arg1=[], arg2=[]; kwargs...)

Interpolates the grid(s) at the positions in the table and writes out the table with the
interpolated values added as (one or more) new columns.

Full option list at [`grdtrack`](http://gmt.soest.hawaii.edu/doc/latest/grdtrack.html)

Parameters
----------

- **A** : **interp_path** : -- Str --
	[`-A`](http://gmt.soest.hawaii.edu/doc/latest/grdtrack.html#a)
- **C** : **equi** : -- Str --
	[`-C`](http://gmt.soest.hawaii.edu/doc/latest/grdtrack.html#c)
- **D** : **dfile** : -- Str --  
	[`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdtrack.html#d)
- **E** : **by_coord** : -- Str --
	[`-E`](http://gmt.soest.hawaii.edu/doc/latest/grdtrack.html#e)
- **G** : **grid** : -- Str or GMTgrid --
	[`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdtrack.html#g)
- **N** : **no_skip** : -- Bool or [] --
	[`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdtrack.html#n)
- $(GMT.opt_R)
- **S** : **stack** : -- Str --
	[`-S`](http://gmt.soest.hawaii.edu/doc/latest/grdtrack.html#s)
- **T** : **radius** : -- Number, Str or [] --
	[`-T`](http://gmt.soest.hawaii.edu/doc/latest/grdtrack.html#t)
- **Z** : **z_only** : -- Bool or [] --
	[`-Z`](http://gmt.soest.hawaii.edu/doc/latest/grdtrack.html#z)
- $(GMT.opt_V)
- $(GMT.opt_bi)
- $(GMT.opt_bo)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_n)
- $(GMT.opt_o)
- $(GMT.opt_s)
- $(GMT.opt_swap_xy)

'arg1' may contain the table data as an array or a GMTdataset type and GMTgrid or it can be
left empty. Same thing for 'arg2'. 'cmd' can have the file name of either the table or the grid.
"""
# ---------------------------------------------------------------------------------------------------
function grdtrack(cmd0::String="", arg1=[], arg2=[]; data=[], kwargs...)

	length(kwargs) == 0 && isempty_(arg1) && isempty_(data) && return monolitic("grdtrack", cmd0, arg1)	# Speedy mode

	if (!isempty_(data) && !isa(data, GMTgrid))
		error("When using 'data', it MUST contain a GMTgrid data type")
	end

	d = KW(kwargs)
	cmd, opt_R = parse_R("", d)
	cmd = parse_V(cmd, d)
	cmd, = parse_bi(cmd, d)
	cmd = parse_bo(cmd, d)
	cmd, = parse_di(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_g(cmd, d)
	cmd = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd = parse_n(cmd, d)
	cmd = parse_o(cmd, d)
	cmd = parse_s(cmd, d)
	cmd = parse_swap_xy(cmd, d)

	cmd = add_opt(cmd, 'A', d, [:A :interp_path])
	cmd = add_opt(cmd, 'C', d, [:C :equi])
	cmd = add_opt(cmd, 'D', d, [:D :dfile])
	cmd = add_opt(cmd, 'E', d, [:E :by_coord])
	cmd = add_opt(cmd, 'N', d, [:N :no_skip])
	cmd = add_opt(cmd, 'S', d, [:S :stack])
	cmd = add_opt(cmd, 'T', d, [:T :radius])
	cmd = add_opt(cmd, 'Z', d, [:Z :z_only])

	for sym in [:G :grid]
		if (haskey(d, sym))
			if (isa(d[sym], GMT.GMTgrid))
				cmd = string(cmd, " -G")
				if     (isempty_(arg1))  arg1 = d[sym];
				elseif (isempty_(arg2))  arg2 = d[sym];
				else   error(string("Can't send the Grid data via G and input array"))
				end
			else
				cmd = string(cmd, " -G", arg2str(d[sym]))
			end
			break
		end
	end

	no_slot = false
	if (!isempty_(data) && (isa(data, Array) || isa(data, GMTdataset)))
		if     (isempty_(arg1))  arg1 = data
		elseif (isempty_(arg2))  arg2 = data
		else   no_slot = true
		end
	elseif (!isempty_(data) && isa(data, GMTgrid))
		if     (isempty_(arg1))  arg1 = data
		elseif (isempty_(arg2))  arg2 = data
		else   no_slot = true
		end
	end
	if (no_slot)
		warn("Inconsistent usage of the 'data' keyword. Data transmittend in conflicting ways.")
	end

	# Because we allow arg1 and arg2 to either exist or not and also contain data & grid in any order
	arg1_is_table = false;		arg2_is_table = false
	arg1_is_grid  = false;		arg2_is_grid  = false
	if     (isa(arg1, Array) || isa(arg1, GMTdataset))  arg1_is_table = true
	elseif (isa(arg2, Array) || isa(arg2, GMTdataset))  arg2_is_table = true
	end
	if     (isa(arg1, GMTgrid))  arg1_is_grid = true
	elseif (isa(arg2, GMTgrid))  arg2_is_grid = true
	end

	if (arg1_is_grid || arg2_is_grid && !contains(cmd, "-G"))  cmd = cmd * " -G"  end

	(haskey(d, :Vd)) && println(@sprintf("\tgrdtrack %s", cmd))

	# Count how many argi
	N_args = 0
	if (!isempty_(arg1))  N_args += 1  end
	if (!isempty_(arg2))  N_args += 1  end

	if (N_args == 0)
		R = gmt("grdtrack " * cmd)
	elseif (N_args == 1)
		R = gmt("grdtrack " * cmd, arg1)
	else
		# Here is more complicated because first argument must hold data and second the grid
		if (arg1_is_table && arg2_is_grid)
			R = gmt("grdtrack " * cmd, arg1, arg2)
		elseif (arg2_is_table && arg1_is_grid)
			R = gmt("grdtrack " * cmd, arg2, arg1)
		else
			error("Shit, failed in the logic of finding which data type is which")
		end
	end
	return R
end

# ---------------------------------------------------------------------------------------------------
grdtrack(arg1=[], arg2=[], cmd0::String=""; data=[], kw...) = grdtrack(cmd0, arg1, arg2; data=data, kw...)