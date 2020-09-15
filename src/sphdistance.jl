"""
	sphdistance(cmd0::String="", arg1=nothing, kwargs...)

Create Voronoi distance, node, or natural nearest-neighbor grid on a sphere

Full option list at [`sphdistance`]($(GMTdoc)sphdistance.html)

Parameters
----------

- **C** | **save_mem** :: [Type => Bool]

    For large data sets you can save some memory (at the expense of more processing).
    ($(GMTdoc)sphdistance.html#a)
- **E** | **what_quantity** :: [Type => Str]   ``Arg = d|n|z[dist]``

    Specify the quantity that should be assigned to the grid nodes.
    ($(GMTdoc)sphdistance.html#e)
- **G** | **grid** | **outgrid** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = sphdistance(....) form.
    ($(GMTdoc)sphdistance.html#g)
- **I** | **inc** :: [Type => Str or Number]

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    ($(GMTdoc)sphdistance.html#i)
- **L** | **dist_unit** :: [Type => Str]      ``Arg = d|e|f|k|M|n|u``

    Specify the unit used for distance calculations.
    ($(GMTdoc)sphdistance.html#l)
- **N** | **nodes** :: [Type => Str]      ``Arg = nodes``

    Read the information pertaining to each Voronoi polygon (the unique node lon, lat and polygon area)
    from a separate file.
    ($(GMTdoc)sphdistance.html#n)
- **Q** | **voronoi** :: [Type => Str]     ``Arg = voronoifile``

    Append the name of a file with pre-calculated Voronoi polygons.
    ($(GMTdoc)sphdistance.html#q)
- $(GMT.opt_R)
- $(GMT.opt_V)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_r)
- $(GMT.opt_swap_xy)
"""
function sphdistance(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("sphdistance ", cmd0, arg1, arg2)

	d = KW(kwargs)
	cmd, = parse_common_opts(d, "", [:I :R :V_params :b :d :e :h :i :r :yx])
	cmd  = parse_these_opts(cmd, d, [[:C :save_mem], [:E :what_quantity], [:G :grid :outgrid], [:L :dist_unit]])

	(arg1 === nothing) ? N_used = 0 : N_used = 1
	symbs = [[:Q :voronoi], [:N :nodes]];	flags = "QN"	# Process option -Q & -N
	for k = 1:2
		if ((val = find_in_dict(d, symbs[k])[1]) !== nothing)
			cmd *= " -" * flags[k]
			if (isa(val, GMTdataset) || isa(val, Array{<:GMTdataset}) || (isa(val, Array{<:Number}) && k == 2) )
				(N_used == 0) ? arg1 = val : arg2 = val
			else
				cmd *= arg2str(val)
			end
		end
	end

	common_grd(d, "sphdistance " * cmd, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
sphdistance(arg1; kw...) = sphdistance("", arg1; kw...)