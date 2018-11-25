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
- **G** : **grid** : -- Str or GMTgrid or Tuple(GMTgrid's) --

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

When using two numeric inputs and no G option, the order of the x,y and grid is not important.
That is, both of this will work: D = grdtrack([0 0], G);  or  D = grdtrack(G, [0 0]); 
"""
function grdtrack(cmd0::String="", arg1=[], arg2=[]; kwargs...)

	length(kwargs) == 0 && isempty_(arg1) && return monolitic("grdtrack", cmd0, arg1)

	d = KW(kwargs)
#=
	cmd, = parse_R("", d)
	cmd = parse_V_params(cmd, d)
	cmd, = parse_bi(cmd, d)
	cmd, = parse_bo(cmd, d)
	cmd, = parse_di(cmd, d)
	cmd, = parse_e(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_g(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd, = parse_n(cmd, d)
	cmd, = parse_o(cmd, d)
	cmd, = parse_s(cmd, d)
	cmd, = parse_swap_xy(cmd, d)
=#
	cmd = parse_common_opts(d, "", [:R :V_params :bi :bo :di :e :f :g :h :i :n :o :s :xy])

	cmd = add_opt(cmd, 'A', d, [:A :interp_path])
	cmd = add_opt(cmd, 'C', d, [:C :equi])
	cmd = add_opt(cmd, 'D', d, [:D :dfile])
	cmd = add_opt(cmd, 'E', d, [:E :by_coord])
	cmd = add_opt(cmd, 'N', d, [:N :no_skip])
	cmd = add_opt(cmd, 'S', d, [:S :stack])
	cmd = add_opt(cmd, 'T', d, [:T :radius])
	cmd = add_opt(cmd, 'Z', d, [:Z :z_only])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)

	grid_tuple = nothing
	for sym in [:G :grid]
		if (haskey(d, sym))
			if (isa(d[sym], Tuple))
				grid_tuple = d[sym]
				for k = 1:length(grid_tuple)	# Need as many -G as numel(grid_tuple)
					cmd = string(cmd, " -G")
				end
			elseif (isa(d[sym], GMT.GMTgrid))
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

	# Because we allow arg1 and arg2 to either exist or not and also contain data & grid in any order
	if (!isempty_(arg1) && !isempty_(arg2))
		arg1_is_table = false;		arg2_is_table = false
		arg1_is_grid  = false;		arg2_is_grid  = false
		if (isa(arg1, GMTgrid))		arg1_is_grid = true		end
		if (isa(arg2, Array) || isa(arg2, GMTdataset))  arg2_is_table = true	end
		if (arg2_is_table && arg1_is_grid)			# Swap the arg1, arg2
			tmp = arg1;		arg1 = arg2;	arg2 = tmp
		end
	end

	if (isa(arg1, GMTgrid) || isa(arg2, GMTgrid) && !occursin("-G", cmd))  cmd = cmd * " -G"  end

	if (isa(grid_tuple, Tuple))
		if (got_fname != 0)
			return common_grd(d, cmd, got_fname, 3, "grdtrack", grid_tuple)
		else
			return common_grd(d, cmd, got_fname, 3, "grdtrack", tuple(arg1, grid_tuple...))
		end
	elseif (isempty_(arg2))
		return common_grd(d, cmd, got_fname, 1, "grdtrack", arg1)		# Finish build cmd and run it
	else
		return common_grd(d, cmd, got_fname, 2, "grdtrack", arg1, arg2)
	end

end

# ---------------------------------------------------------------------------------------------------
grdtrack(arg1=[], arg2=[], cmd0::String=""; kw...) = grdtrack(cmd0, arg1, arg2; kw...)