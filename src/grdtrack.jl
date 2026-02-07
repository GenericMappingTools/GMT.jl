"""
	grdtrack(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

Interpolates the grid(s) at the positions in the table and returns the table with the
interpolated values added as (one or more) new columns.

When using two numeric inputs and no G option, the order of the x,y and grid is not important.
That is, both of this will work: ``D = grdtrack([0 0], Grid);``  or  ``D = grdtrack(Grid, [0 0]);`` 

To see the documentation, type: ``@? grdtrack``
"""
function grdtrack(cmd0::String, arg1=nothing, arg2=nothing; kwargs...)
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	grdtrack_helper(cmd0, arg1, arg2, d)
end

function grdtrack_helper(cmd0::String, arg1, arg2, d::Dict{Symbol, Any})

	cmd, = parse_common_opts(d, "", [:R :V_params :bi :bo :di :e :f :g :h :i :n :o :s :w :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :interp_path :resample], [:C :crossprofile :equidistant], [:D :dfile],
	                                 [:E :profile], [:F :critical], [:M :between], [:N :no_skip :noskip], [:S :stack], [:T :radius], [:Z :z_only]])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)
	cmd, grid_tuple, arg1, arg2 = parse_G_grdtrk(d, [:G, :grid], cmd, arg1, arg2)
	if (isa(grid_tuple, String) && startswith(grid_tuple, "@earth_") && !contains(cmd, " -R"))
		opt_R = read_data(d, cmd0, "", arg1)[3]
		cmd *= opt_R
	end

	# Because we allow arg1 and arg2 to either exist or not and also contain data & grid in any order
	if (arg1 !== nothing && arg2 !== nothing)
		arg1_is_grid, arg1_is_fv = isa(arg1, GMTgrid), isa(arg1, GMTfv)
		arg2_is_table = (isa(arg2, Array) || isa(arg2, GMTdataset) || isa(arg2, GMTfv))
		if (arg2_is_table && (arg1_is_grid || arg1_is_fv))			# Swap the arg1, arg2
			arg1, arg2 = arg2, arg1
		end
	end

	(isa(arg1, GMTgrid) || isa(arg2, GMTgrid) && !occursin("-G", cmd)) && (cmd *= " -G")
	if (cmd0 != "" && !isa(arg1, GMTgrid) && !isa(arg1, Vector{GMTgrid}) && !occursin("-G", cmd))
		cmd = " -G" * cmd
		(isa(arg1, String)) && (cmd *= " " * arg1)
	end

	if (isa(grid_tuple, Tuple))
		if (isa(arg1, GMTfv))		# The case where we are interpolating a FacesVertices
			view(arg1.verts, :, 3) .= common_grd(d, "grdtrack -o2 " * cmd, (got_fname != 0) ? grid_tuple : tuple(view(arg1.verts, :, 1:2), grid_tuple...))
		else
			R = common_grd(d, "grdtrack " * cmd, (got_fname != 0) ? grid_tuple : tuple(arg1, grid_tuple...))
		end
	else
		if (isa(arg1, GMTfv))
			view(arg1.verts, :, 3) .= common_grd(d, "grdtrack -o2 " * cmd, view(arg1.verts, :, 1:2), arg2)
		else
			R = common_grd(d, "grdtrack " * cmd, arg1, arg2)
		end
	end
	
	isa(arg1, GMTfv) && (arg1.bbox[5:6] = [extrema(view(arg1.verts, :, 3))...]; return arg1)

	# Assign column names
	if (!isa(R, String))			# It is a string when Vd=2
		prj = isa(arg1, GMTgrid) ? arg1.proj4 : (isa(arg2, GMTgrid) ? arg2.proj4 : "")
		is_geog = isgeog(prj)
		(coln = (is_geog) ? ["Lon", "Lat"] : ["X", "Y"])
		if (isa(R, GMTdataset))
			(size(R.data, 2) == 3) ? append!(coln, ["Z"]) : append!(coln, ["Z$(i-2)" for i=3:size(R.data, 2)])
			(size(R.data, 2) == 1) && (coln = ["Z"])		# When only the Z column was asked
			R.colnames = coln
		elseif (isa(R, Vector))
			(size(R[1].data, 2) == 3) ? append!(coln, ["Z"]) : append!(coln, ["Z$(i-2)" for i=3:size(R[1].data, 2)])
			(size(R[1].data, 2) == 1) && (coln = ["Z"])		# When only the Z column was asked
			for k = 1:numel(R)  R[k].colnames = coln  end
		else		# A Tuple when -S+s was used
			if (isa(R[1], GMTdataset))
				(size(R[1].data, 2) == 3) ? append!(coln, ["Z"]) : append!(coln, ["Z$(i-2)" for i=3:size(R[1].data, 2)])
				R[1].colnames = coln
			else
				(size(R[1][1].data, 2) == 3) ? append!(coln, ["Z"]) : append!(coln, ["Z$(i-2)" for i=3:size(R[1][1].data, 2)])
				for k = 1:numel(R[1])  R[1][k].colnames = coln  end
			end
		end
	end
	R
end

# ---------------------------------------------------------------------------------------------------
function parse_G_grdtrk(d::Dict, symbs::Vector{<:Symbol}, cmd::String, arg1, arg2)

	(SHOW_KWARGS[]) && return (print_kwarg_opts(symbs, "GMTgrid | Tuple | String"), nothing,arg1,arg2)

	if ((grid_tuple = find_in_dict(d, symbs)[1]) !== nothing)
		if (isa(grid_tuple, Tuple))
			for k = 1:length(grid_tuple)  cmd *= " -G"  end		# Need as many -G as numel(grid_tuple)
		elseif (isa(grid_tuple, GMTgrid))
			cmd *= " -G"
			if     (arg1 === nothing)  arg1 = grid_tuple;
			elseif (arg2 === nothing)  arg2 = grid_tuple;
			else   error("Can't send the Grid data via G and input array")
			end
		else
			cmd = string(cmd, " -G", arg2str(grid_tuple))
		end
	end
	return cmd, grid_tuple, arg1, arg2
end

# ---------------------------------------------------------------------------------------------------
grdtrack(arg1, arg2=nothing; kw...) = isa(arg2, String) ? grdtrack(arg2, arg1; kw...) : grdtrack("", arg1, arg2; kw...)
