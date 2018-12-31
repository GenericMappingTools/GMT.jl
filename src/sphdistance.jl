"""
	sphdistance(cmd0::String="", arg1=[], kwargs...)

Create Voronoi distance, node, or natural nearest-neighbor grid on a sphere

Full option list at [`sphdistance`](http://gmt.soest.hawaii.edu/doc/latest/sphdistance .html)

Parameters
----------

- **C** : **save_mem** : -- Bool or [] --

    For large data sets you can save some memory (at the expense of more processing).
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/sphdistance.html#c)
- **E** : **what_quantity** : -- Str --   Flags = d|n|z[dist]

    Specify the quantity that should be assigned to the grid nodes.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/sphdistance.html#e)
- **G** : **outgrid** : -- Str --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = sphdistance(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/sphdistance.html#g)
- **I** : **inc** : -- Str or Number --

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/sphdistance.html#i)
- **L** : **dist_unit** : -- Str --      Flags = d|e|f|k|M|n|u

    Specify the unit used for distance calculations.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/sphdistance.html#l)
- **N** : **nodetable** : -- Str --      Flags = nodetable

    Read the information pertaining to each Voronoi polygon (the unique node lon, lat and polygon area)
    from a separate file.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/sphdistance.html#n)
- **Q** : **voronoi_polyg** : -- Str --     Flags = voronoifile

    Append the name of a file with pre-calculated Voronoi polygons.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/sphdistance .html#q)
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
function sphdistance(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0  && return monolitic("sphdistance ", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :b :d :e :h :i :r :yx])
	cmd = parse_these_opts(cmd, d, [[:C :save_mem], [:E :what_quantity], [:G :outgrid], [:I :inc],
				[:L :dist_unit], [:N :nodetable], [:Q :voronoi_polyg]])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "sphdistance", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
sphdistance(arg1; kw...) = sphdistance("", arg1; kw...)