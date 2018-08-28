"""
	triangulate(cmd0::String="", arg1=[]; kwargs...)

Reads one or more ASCII [or binary] files (or standard input) containing x,y[,z] and performs Delaunay
triangulation, i.e., it find how the points should be connected to give the most equilateral
triangulation possible. 

Full option list at [`triangulate`](http://gmt.soest.hawaii.edu/doc/latest/triangulate.html)

Parameters
----------
- **C** : **slope_grid** : -- Number --
    Read a slope grid (in degrees) and compute the propagated uncertainty in the
    bathymetry using the CURVE algorithm
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/triangulate.html#c)
- **D** : **derivatives** : -- Str --
    Take either the x- or y-derivatives of surface represented by the planar facets (only used when G is set).
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/triangulate.html#a)
- **E** : **empty** : -- Bool or [] --
    Set the value assigned to empty nodes when G is set [NaN].
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/triangulate.html#e)
- **G** : **grid** : -- Str or [] --
    Use triangulation to grid the data onto an even grid (specified with R I).
    Append the name of the output grid file.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/triangulate.html#g)
- **I** : **inc** : -- Str or Number --
    *x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/triangulate.html#i)
- $(GMT.opt_J)
- **M** : **network** : -- Bool or [] --
    Output triangulation network as multiple line segments separated by a segment header record.
    [`-M`](http://gmt.soest.hawaii.edu/doc/latest/triangulate.html#m)
- **N** : **ids** : -- Bool or [] --
    Used in conjunction with G to also write the triplets of the ids of all the Delaunay vertices
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/triangulate.html#n)
- **Q** : **voronoi** : -- Str or [] --
    Output the edges of the Voronoi cells instead [Default is Delaunay triangle edges]
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/triangulate.html#q)
- $(GMT.opt_R)
- **S** : **triangles** : -- Bool or [] --  
    Output triangles as polygon segments separated by a segment header record. Requires Delaunay triangulation.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/triangulate.html#s)
- **T** : **edges** : -- Bool or [] --
    Output edges or polygons even if gridding has been selected with the G option
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/triangulate.html#t)
- $(GMT.opt_V)
- **Z** : **xyz** : **triplets** : -- Bool or [] --
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/triangulate.html#z)
- $(GMT.opt_bi)
- $(GMT.opt_bo)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_r)
- $(GMT.opt_swap_xy)
"""
function triangulate(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("triangulate", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	cmd, = parse_R("", d)
	cmd, = parse_J(cmd, d)
	cmd  = parse_V_params(cmd, d)
	cmd, = parse_bi(cmd, d)
	cmd, = parse_bo(cmd, d)
	cmd, = parse_di(cmd, d)
	cmd, = parse_e(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd, = parse_r(cmd, d)
	cmd, = parse_swap_xy(cmd, d)

	cmd = add_opt(cmd, 'C', d, [:C :slope_grid])
	cmd = add_opt(cmd, 'D', d, [:D :derivatives])
	cmd = add_opt(cmd, 'E', d, [:E :empty])
    cmd = add_opt(cmd, 'G', d, [:G :grid])
	cmd = add_opt(cmd, 'I', d, [:I :inc])
	cmd = add_opt(cmd, 'M', d, [:N :network])
	cmd = add_opt(cmd, 'N', d, [:N :ids])
	cmd = add_opt(cmd, 'Q', d, [:Q :voronoi])
	cmd = add_opt(cmd, 'S', d, [:S :triangles])
	cmd = add_opt(cmd, 'T', d, [:T :edges])
	cmd = add_opt(cmd, 'Z', d, [:Z :xyz :triplets])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "triangulate", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
triangulate(arg1::Array, cmd0::String=""; kw...) = triangulate(cmd0, arg1; kw...)