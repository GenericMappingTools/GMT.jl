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
	cmd = parse_common_opts(d, "", [:R :V_params :bi :bo :di :e :f :g :h :i :n :o :s :xy])
	cmd = parse_these_opts(cmd, d, [[:A :interp_path], [:C :equi], [:D :dfile], [:E :by_coord],
				[:N :no_skip], [:S :stack], [:T :radius], [:Z :z_only]])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)

	grid_tuple = nothing
	if ((val = find_in_dict(d, [:G :grid])[1]) !== nothing)
		if (isa(val, Tuple))
			grid_tuple = val
			for k = 1:length(grid_tuple)  cmd *= " -G"  end		# Need as many -G as numel(grid_tuple)
		elseif (isa(val, GMT.GMTgrid))
			cmd = string(cmd, " -G")
			if     (isempty_(arg1))  arg1 = val;
			elseif (isempty_(arg2))  arg2 = val;
			else   error(string("Can't send the Grid data via G and input array"))
			end
		else
			cmd = string(cmd, " -G", arg2str(val))
		end
	end

	# Because we allow arg1 and arg2 to either exist or not and also contain data & grid in any order
	if (!isempty_(arg1) && !isempty_(arg2))
		arg1_is_table = false;	arg2_is_table = false;	arg1_is_grid = false;	arg2_is_grid = false
		if (isa(arg1, GMTgrid))		arg1_is_grid = true		end
		if (isa(arg2, Array) || isa(arg2, GMTdataset))  arg2_is_table = true	end
		if (arg2_is_table && arg1_is_grid)			# Swap the arg1, arg2
			tmp = arg1;		arg1 = arg2;	arg2 = tmp
		end
	end

	if (isa(arg1, GMTgrid) || isa(arg2, GMTgrid) && !occursin("-G", cmd))  cmd = cmd * " -G"  end

	if (isa(grid_tuple, Tuple))
		return common_grd(d, cmd, got_fname, 3, "grdtrack", (got_fname != 0) ? grid_tuple : tuple(arg1,grid_tuple...))
	else
		return common_grd(d, cmd, got_fname, 2, "grdtrack", arg1, arg2)
	end

end

# ---------------------------------------------------------------------------------------------------
grdtrack(arg1=[], arg2=[], cmd0::String=""; kw...) = grdtrack(cmd0, arg1, arg2; kw...)