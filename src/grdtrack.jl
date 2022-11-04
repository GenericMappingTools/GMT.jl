"""
	grdtrack(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

Interpolates the grid(s) at the positions in the table and returns the table with the
interpolated values added as (one or more) new columns.

Full option list at [`grdtrack`]($(GMTdoc)/grdtrack.html)

Parameters
----------

- **A** | **interp_path** | **resample** :: [Type => Str]		`Arg = f|p|m|r|R[+l]`

    For track resampling (if `crossprofile` or `profile` are set) we can select how this is to be performed. 
    ($(GMTdoc)grdtrack.html#a)
- **C** | **crossprofile** :: [Type => Str]		`Arg = length/ds[/spacing][+a|+v][l|r]`

    Use input line segments to create an equidistant and (optionally) equally-spaced set of crossing
    profiles along which we sample the grid(s)
    ($(GMTdoc)grdtrack.html#c)
- **D** | **dfile** :: [Type => Str]  

    In concert with `crossprofile` we can save the (possibly resampled) original lines to the file dfile
    ($(GMTdoc)grdtrack.html#d)
- **E** | **profile** :: [Type => Str]

    Instead of reading input track coordinates, specify profiles via coordinates and modifiers.
    ($(GMTdoc)grdtrack.html#e)
- **F** | **critical** :: [Type => Str]

    Find critical points along each cross-profile as a function of along-track distance. Requires
    `crossprofile` and a single input grid.
    ($(GMTdoc)grdtrack.html#e)
- **G** | **grid** :: [Type => Str | GMTgrid | Tuple(GMTgrid's)]

    ($(GMTdoc)grdtrack.html#g)
- **N** | **no_skip** | **noskip** :: [Type => Bool]

    ($(GMTdoc)grdtrack.html#n)
- $(GMT._opt_R)
- **S** | **stack** :: [Type => Str]

    ($(GMTdoc)grdtrack.html#s)
- **T** | **radius** :: [Type => Number, Str | []]

    ($(GMTdoc)grdtrack.html#t)
- **Z** | **z_only** :: [Type => Bool]

    ($(GMTdoc)grdtrack.html#z)
- $(GMT.opt_V)
- $(GMT._opt_bi)
- $(GMT.opt_bo)
- $(GMT._opt_di)
- $(GMT.opt_e)
- $(GMT._opt_f)
- $(GMT.opt_g)
- $(GMT._opt_h)
- $(GMT._opt_i)
- $(GMT.opt_n)
- $(GMT.opt_o)
- $(GMT.opt_s)
- $(GMT.opt_w)
- $(GMT.opt_swap_xy)

When using two numeric inputs and no G option, the order of the x,y and grid is not important.
That is, both of this will work: D = grdtrack([0 0], G);  or  D = grdtrack(G, [0 0]); 
"""
function grdtrack(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_common_opts(d, "", [:R :V_params :bi :bo :di :e :f :g :h :i :n :o :s :w :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :interp_path :resample], [:C :crossprofile :equidistant], [:D :dfile],
	                                 [:E :profile], [:F :critical], [:N :no_skip :noskip], [:S :stack], [:T :radius], [:Z :z_only]])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)
	cmd, grid_tuple, arg1, arg2 = parse_G_grdtrk(d, [:G, :grid], cmd, arg1, arg2)
	if (isa(grid_tuple, String) && startswith(grid_tuple, "@earth_") && !contains(cmd, " -R"))
		opt_R = read_data(d, cmd0, "", arg1)[3]
		cmd *= opt_R
	end

	# Because we allow arg1 and arg2 to either exist or not and also contain data & grid in any order
	if (arg1 !== nothing && arg2 !== nothing)
		arg2_is_table = false;	arg1_is_grid = false
		(isa(arg1, GMTgrid)) && (arg1_is_grid = true)
		(isa(arg2, Array) || isa(arg2, GMTdataset)) && (arg2_is_table = true)
		if (arg2_is_table && arg1_is_grid)			# Swap the arg1, arg2
			arg1, arg2 = arg2, arg1
		end
	end

	(isa(arg1, GMTgrid) || isa(arg2, GMTgrid) && !occursin("-G", cmd)) && (cmd *= " -G")
	if (cmd0 != "" && !isa(arg1, GMTgrid) && !isa(arg1, Vector{GMTgrid}) && !occursin("-G", cmd))
		cmd = " -G" * cmd
		(isa(arg1, String)) && (cmd *= " " * arg1)
	end

	if (isa(grid_tuple, Tuple))
		R = common_grd(d, "grdtrack " * cmd, (got_fname != 0) ? grid_tuple : tuple(arg1, grid_tuple...))
	else
		R = common_grd(d, "grdtrack " * cmd, arg1, arg2)
	end

	# Assign column names
	if (!isa(R, String))			# It is a string when Vd=2
		prj = isa(arg1, GMTgrid) ? arg1.proj4 : (isa(arg2, GMTgrid) ? arg2.proj4 : "")
		is_geog = (contains(prj, "=longlat") || contains(prj, "=latlong")) ? true : false
		(coln = (is_geog) ? ["Lon", "Lat"] : ["X", "Y"])
		if (isa(R, GMTdataset))
			(size(R.data, 2) == 3) ? append!(coln, ["Z"]) : append!(coln, ["Z$(i-2)" for i=3:size(R.data, 2)])
			R.colnames = coln
		else
			(size(R[1].data, 2) == 3) ? append!(coln, ["Z"]) : append!(coln, ["Z$(i-2)" for i=3:size(R[1].data, 2)])
			for k = 1:length(R)  R[k].colnames = coln  end
		end
	end
	R
end

# ---------------------------------------------------------------------------------------------------
function parse_G_grdtrk(d::Dict, symbs::Vector{<:Symbol}, cmd::String, arg1, arg2)

	(show_kwargs[1]) && return (print_kwarg_opts(symbs, "GMTgrid | Tuple | String"), nothing,arg1,arg2)

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
grdtrack(arg1, arg2=nothing; kw...) = grdtrack("", arg1, arg2; kw...)
