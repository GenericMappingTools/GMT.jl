"""
	sphdistance(cmd0::String="", arg1=nothing, kwargs...)

Create Voronoi distance, node, or natural nearest-neighbor grid on a sphere

See full GMT (not the `GMT.jl` one) docs at [`sphdistance`]($(GMTdoc)sphdistance.html)

Parameters
----------

- **C** | **save_mem** :: [Type => Bool]

    For large data sets you can save some memory (at the expense of more processing).
- **D** | **duplicates** :: [Type => Bool]

    Delete any duplicate points [Default assumes there are no duplicates].
- **E** | **what_quantity** :: [Type => Str]   ``Arg = d|n|z[dist]``

    Specify the quantity that should be assigned to the grid nodes.
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = sphdistance(....) form.
- $(GMT.opt_I)
- **L** | **dist_unit** :: [Type => Str]      ``Arg = d|e|f|k|M|n|u``

    Specify the unit used for distance calculations.
- **N** | **nodes** :: [Type => Str]      ``Arg = nodes``

    Read the information pertaining to each Voronoi polygon (the unique node lon, lat and polygon area)
    from a separate file.
- **Q** | **voronoi** :: [Type => Str]     ``Arg = voronoifile``

    Append the name of a file with pre-calculated Voronoi polygons.
- $(GMT._opt_R)
- $(GMT.opt_V)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT._opt_h)
- $(GMT._opt_i)
- $(GMT.opt_r)
- $(GMT.opt_swap_xy)

To see the full documentation type: ``@? sphdistance``
"""
function sphdistance(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :b :d :e :h :i :yx])
	cmd  = parse_these_opts(cmd, d, [[:C :save_mem], [:D :duplicates], [:E :what_quantity], [:L :dist_unit]])
	cmd, arg1, arg2 = parse_QN_sphdst(d, [[:Q :voronoi], [:N :nodes]], cmd, arg1, arg2)

	common_grd(d, "sphdistance " * cmd, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
function parse_QN_sphdst(d::Dict, symbs::Array{Array{Symbol,2},1}, cmd::String, arg1, arg2)
	(show_kwargs[1]) && print_kwarg_opts(symbs[1], "Vector{GMTdataset} | GMTdataset | Array | Number | String")
	(show_kwargs[1]) && return print_kwarg_opts(symbs[3], "Vector{GMTdataset} | GMTdataset | Array | Number | String")
	N_used = (arg1 === nothing) ?  0 : 1
	flags ="QN"			# Process option -Q & -N
	for k = 1:2
		if ((val = find_in_dict(d, symbs[k])[1]) !== nothing)
			cmd *= " -" * flags[k]
			if (isa(val, GMTdataset) || isa(val, Vector{<:GMTdataset}) || (isa(val, Array{<:Number}) && k == 2) )
				(N_used == 0) ? arg1 = val : arg2 = val
			else
				cmd *= arg2str(val)
			end
		end
	end
	return cmd, arg1, arg2
end

# ---------------------------------------------------------------------------------------------------
sphdistance(arg1; kw...) = sphdistance("", arg1; kw...)