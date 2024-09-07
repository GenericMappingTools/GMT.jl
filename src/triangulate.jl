"""
	triangulate(cmd0::String="", arg1=nothing; kwargs...)

Reads randomly-spaced x,y[,z] (or file) and performs Delaunay
triangulation, i.e., it finds how the points should be connected to give the most equilateral
triangulation possible. 

See full GMT (not the `GMT.jl` one) docs at [`triangulate`]($(GMTdoc)triangulate.html)

Parameters
----------
- **A** | **area** :: [Type => Bool]

    Compute the area of the Cartesian triangles and append the areas in the output segment headers
    [no areas calculated]. Requires **triangles** and is not compatible with **voronoi** (GMT >= 6.4).
- **C** | **slope_grid** :: [Type => Number]

    Read a slope grid (in degrees) and compute the propagated uncertainty in the
    bathymetry using the CURVE algorithm
- **D** | **derivatives** :: [Type => Str]

    Take either the x- or y-derivatives of surface represented by the planar facets (only used when G is set).
- **E** | **empty** :: [Type => Str | Number]

    Set the value assigned to empty nodes when G is set [NaN].
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Use triangulation to grid the data onto an even grid (specified with R I).
    Append the name of the output grid file.
- $(opt_I)
- $(_opt_J)
- **L** | **index** :: [Type => Bool]

    Give name of file with previously computed Delaunay information. If the indexfile is binary and can be read
    the same way as the binary input table then you can append +b to spead up the reading (GMT6.4).
- **M** | **network** :: [Type => Bool]

    Output triangulation network as multiple line segments separated by a segment header record.
- **N** | **ids** :: [Type => Bool]

    Used in conjunction with G to also write the triplets of the ids of all the Delaunay vertices
- **Q** | **voronoi** :: [Type => Str | []]

    Output the edges of the Voronoi cells instead [Default is Delaunay triangle edges]
- $(_opt_R)
- **S** | **triangles** :: [Type => Bool]  

    Output triangles as polygon segments separated by a segment header record. Requires Delaunay triangulation.
- **T** | **edges** :: [Type => Bool]

    Output edges or polygons even if gridding has been selected with the G option
- $(opt_V)
- **Z** | **xyz** | **triplets** :: [Type => Bool]

- $(_opt_bi)
- $(opt_bo)
- $(_opt_di)
- $(opt_e)
- $(_opt_f)
- $(_opt_h)
- $(_opt_i)
- $(opt_r)
- $(opt_w)
- $(opt_swap_xy)

To see the full documentation type: ``@? triangulate``
"""
triangulate(cmd0::String; kwargs...) = triangulate_helper(cmd0, nothing; kwargs...)
triangulate(arg1; kwargs...)         = triangulate_helper("", arg1; kwargs...)

# ---------------------------------------------------------------------------------------------------
function triangulate_helper(cmd0::String, arg1; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :bi :bo :di :e :f :h :i :w :yx])
	(haskey(d, :Z) && isa(d[:Z], Bool) && !d[:Z]) && delete!(d, :Z)		# Strip Z=false from 'd' (for triplot)
	cmd  = parse_these_opts(cmd, d, [[:A :area], [:C :slope_grid], [:D :derivatives], [:E :empty], [:L :index],
	                                 [:M :network], [:N :ids], [:S :triangles], [:T :edges], [:Z :xyz :triplets]])
	cmd = parse_Q_tri(d, [:Q :voronoi], cmd)
	(occursin("-I", cmd) && occursin("-R", cmd) && !occursin("-G", cmd)) && (cmd *= " -G")
	(occursin("-Q", cmd) && !occursin("-M", cmd)) && (cmd *= " -M")		# Otherwise kills Julia (GMT bug)
	(!occursin("-G", cmd)) && (cmd = parse_J(d, cmd, " ")[1])

	out = common_grd(d, cmd0, cmd, "triangulate ", arg1)		# Finish build cmd and run it
	if isa(out, GDtype)
		set_dsBB!(out, false)
		(contains(cmd, " -S") && contains(cmd, " -Z")) && setgeom!(out, wkbPolygonZM)
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
function parse_Q_tri(d::Dict, symbs::Array{Symbol}, cmd::String)
	(SHOW_KWARGS[1]) && return print_kwarg_opts(symbs, "Bool | String")	# Just print the options
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		cmd *= " -Q";   val_::String = string(val)
		(startswith(val_, "pol")) && (cmd *= "n")
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
"""
  triplot(in::Matrix; onlyedges::Bool=false, noplot::Bool=false, kw...)

Plots the 2-D triangulation or Voronoi polygons defined by the points in a matrix

- `in`: The input data. Can be either a Mx2 or Mx3 matrix.
- `noplot`: Return the computed Delaunay or Veronoi data instead of plotting it (the default).
- `onlyedges`: By default we compute Delaunay tringles or Veronoi cells as polygons. Use this option as
   `onlyedges=true` to compute multiple line segments.
- `region`: Sets the data region (xmin,xmax,ymin,ymax) for `voronoi` (required). If not provided we compute it from `in`.
- `voronoi`: Compute Voronoi cells instead of Delaunay triangles (requires `region`).
- `kw...`: keyword arguments used in the ``plot`` module (ignore if `noplot=true`).


### Returns
A GMTdataset if `noplot=true` or ``nothing`` otherwise.

## Example:

  triplot(rand(5,2), voronoi=true, show=true)

  triplot(rand(5,3), lc=:red, show=true)
"""
function triplot(in::Matrix; onlyedges::Bool=false, noplot::Bool=false, first::Bool=true, kw...)
	d = KW(kw)
	do_voronoi::Bool = ((val = find_in_dict(d, [:voronoi])[1]) !== nothing)
	if (do_voronoi)
		opt_R = parse_R(d, "", false, false)[2]
		(opt_R == "") && (opt_R = read_data(d, "", "", in, "")[3])
		opt_Q = onlyedges ? "" : "pol"
	end
	Vd::Int = get(d, :Vd, 0)
	doZ = (size(in, 2) > 2)		# If 3 columns, output them too
	D = (do_voronoi) ? triangulate(in, M=true, voronoi=opt_Q, R=opt_R[4:end], Z=doZ, Vd=Vd) :
		(onlyedges) ? triangulate(in, M=true, Z=doZ, Vd=Vd) : triangulate(in, S=true, Z=doZ, Vd=Vd)
	isa(D, Vector{<:GMTdataset}) && (for k = 1:numel(D)  D[k].geom = wkbPolygon  end)
	isa(D, GMTdataset) && (D.geom = wkbPolygon)
	(noplot || Vd > 1) && return D
	GMT.common_plot_xyz("", D, "plot", first, false, d...)
end

triplot!(in::Matrix; onlyedges::Bool=false, noplot::Bool=false, kw...) = triplot(in; onlyedges=onlyedges, noplot=noplot, first=false, kw...)

# ---------------------------------------------------------------------------------------------------
"""
    trisurf(in, kw...)

Plots the 3-D triangular surface defined by the points in a Mx3 matrix or a GMTdataset with data 
x, y, z in the 3 first columns. The triangles are computed with a Delaunay triangulation done internaly.
Since this is a `plot3d` _avatar_ all options in this function are those of the `plot3d` program.

### Example
    x,y,z = GMT.peaks(N=45, grid=false);
	trisurf([x[:] y[:] z[:]], pen=0.5, show=true)
"""
function trisurf(in::Union{Matrix, GDtype}; gdal=true, first::Bool=true, kw...)
	(size(in, 2) < 3) && error("'trisurf' needs at least 3 columns in input")
	d = KW(kw)
	first && (d[:aspect] = get(d, :aspect, "equal"))
	d[:p] = get(d, :p, "135/30")
	D = gdal ? delaunay(in, 0.0, false) : triangulate(in, S=true, Z=true)
	Zs = Vector{Float64}(undef, size(D,1))
	for k = 1:numel(Zs)
		Zs[k] = (D[k].bbox[5] + D[k].bbox[6]) / 2
	end
	ind = sortperm(Zs)			# Sort in groing z. Needed to sort the triangles too otherwise is a mess.
	ds_bbox = D[1].ds_bbox
	D = D[ind];		D[1].ds_bbox = ds_bbox
	d[:Z] = Zs[ind]
	common_plot_xyz("", D, "plot3d", first, true, d...)
end
trisurf!(in::Union{Matrix, GDtype}; gdal=true, kw...) = trisurf(in; gdal=gdal, first=false, kw...)

# ---------------------------------------------------------------------------------------------------
# D = grid2tri("cam_slab2_dep_02.24.18.grd", "cam_slab2_thk_02.24.18.grd")
# plot3(D,  zsize=3, G="+z", L=true, proj=:merc, show=1, pen=0)
# plot3(D,  zsize=3,  proj=:merc,  G="+z", C="aa.cpt", show=1, Z=linspace(-7,-400,length(D)), Vd=1)
"""
    grid2tri(G, G2=nothing; bottom=false, downsample=0, level=false, ratio=0.01, thickness=0.0, wall=false)

Triangulates the surface defined by the grid `G`, and optionally the bottom surface `G2`, plus the
vertical wall between them, or between `G` and constant level or a constant thickness. Optionally
computes only the vertical wall or the full closed bodie (that is, including the bottom surface).

The output of this function can be used in ``plot3d`` to create 3D views of volume layer.

NOTE: The `G` grid should have a _out-skirt_ of NaNs, otherwise just use ``grdview`` with the ``N`` option.

### Parameters
- `G`: A GMTgrid object or a grid file name representing the surface to be triangulated.

- `G2`: An optional second grid (ot file name) representing the bottom surface of the layer. Using this
  option makes the `thickness` option be ignored.

### Keywords
- `bottom`: If true, fully close the body with the bottom surface. By default we don't do this because that
  surface is not visible whem elevation view angle is positive. But we may want this if later we want to save
  this mesh in STL for importing in a 3D viewer software.

- `layer`: If true, we interpret `thickness` option as meaning a contant level value. That is, the vertical
  wall is computed from the sides of `G` and a constant level provided via the `thickness` option.

- `downsample`: If the grid is of too high resolution, files here get big and operations slow down with this
  and later figures may not benefit much. In those cases it is a good idea to downsample the grid. The 
  `downsample` option accepts an integer reduction factor. `downsample=2` will shrink the grid by a factor two
  in each dimention, `downsample=3` will shrink it by a factor three etc.

- `ratio`: A slightly tricky parameter that determines how close the computed concave hull is to the true
  concave hull. A value smaller to 0.005 seems to do it but we normally don't want that close because the
  vertical wall obtained from this will be too jagged. The default value of 0.01 seems to work well to get
  a smoother concave hull but one that still fits the objective of getting a nice vertical wall. May need
  tweaking for specific cases.

- `thickness`: A scalar representing the layer thickness in the same units as those of the input grid.
  NOTE: this option is ignored when two grids are passed in input.

- `wall`: If true, only the vertical wall  between `G` and `G2`, or `G` + `thickness` is computed and returned.

### Returns
A vector of GMTdataset with the triangulated surface and vertical wall, or just the wall or the full closed body.
"""
function grid2tri(G, G2=nothing; thickness=0.0, level=false, downsample=0, ratio=0.01, bottom=false, wall=false)
	(!isa(G2, GMTgrid) && !isa(G2, String) && thickness <= 0.0) &&
		error("Must provide a bottom grid or a thickness for this layer.")

	(wall != 0) && (bottom = false)
	Dbnd_t, Dpts = gridhull(G; downsample=downsample, ratio=ratio)	# Compute the top concave hull
	Dt_t = triangulate(Dpts, S="+za", Z=true)			# Triangulation of top surface
	if (wall != 0)										# If we only want the vertical wall no need to compute the others
		Dc = gmtspatial(Dt_t, Q=true, o="0,1")			# Compute the polygon centroids
		ind = (Dc in Dbnd_t) .== 1
		Dt_t = Dt_t[ind]								# Delete the triangles outside the concave hull
		Dt_t[1].ds_bbox = Dt_t[1].bbox					# Because we may have deleted first Dt_t
		Dt_t[1].proj4 = Dbnd_t.proj4
		Dt_t[1].geom = wkbPolygonZM
		set_dsBB!(Dt_t, false)
	end

	if (isa(G2, GMTgrid) || isa(G2, String))
		Dbnd_b, Dpts = gridhull(G2; downsample=downsample, ratio=ratio)	# Compute the bottom concave hull
		if (bottom == 1)
			Dt_b = triangulate(Dpts, S="+za", Z=true)	# Triangulation of bottom surface
			Dt_b = Dt_b[ind]							# Delete the triangles outside the concave hull (reuse the same 'ind')
			Dt_b[1].ds_bbox = Dt_b[1].bbox				# Because we may have deleted first Dt
			Dt_b[1].geom = wkbPolygonZM
			for k = 1:numel(Dt_b)						# Must reverse the order of the vertices so normals point outward
				Dt_b[k][3,1], Dt_b[k][2,1] = Dt_b[k][2,1], Dt_b[k][3,1]
				Dt_b[k][3,2], Dt_b[k][2,2] = Dt_b[k][2,2], Dt_b[k][3,2]
				Dt_b[k][3,3], Dt_b[k][2,3] = Dt_b[k][2,3], Dt_b[k][3,3]
			end
			set_dsBB!(Dt_b, false)
		end
		Dwall = vwall(Dbnd_t, view(Dbnd_b, :, 3))
		(bottom == 1) && append!(Dt_b, Dwall)			# If including bottom too, start with it and add the wall.
	else
		Dwall = vwall(Dbnd_t, thickness, level != 0)
	end

	(wall == 0) && append!(Dwall, Dt_t)
	return Dwall
end

# ---------------------------------------------------------------------------------------------------
"""
    B, V = gridhull(G; downsample::UInt=0, ratio=0.01) -> GMTdataset, Matrix

- `G`: The input grid. It can be either a GMTgrid or a grid file name.

### Keywords
- `downsample`: Downsample the input grid by `downsample` times.
- `ratio`: The ratio of the concave hull to the convex hull.
"""
function gridhull(G; downsample::Int=0, ratio=0.01)
	_G = isa(G, String) ? gmtread(G) : G
	(downsample > 1) && (_G = grdsample(_G, I="$(div(size(_G.z,2),2)+1)+n/$(div(size(_G.z,1),2)+1)+n", V="q"))
	V = grd2xyz(_G, s=true)					# Convert to x,y,z while dropping the NaNs
	B = concavehull(V.data, ratio, false)	# Compute the ~concave hull when excluding the outer NaNs (ignores holes)
	B.proj4, B.wkt, B.epsg = _G.proj4, _G.wkt, _G.epsg
	return B, V
end

# ---------------------------------------------------------------------------------------------------
"""
    D = vwall(Bt, thk, level::Bool=false) -> Vector{GMTdataset}

Compute the vertical wall between grid's concave hull `Bt` with a fixed or variable height `thk`.

- `Bt`: A Mx3 matrix or a GMTdataset with the concave hull of the top surface given in a clock-wise order
  (The order returned by GDAL's `concavehull` function).

- `thk`: A constant or a vector with the thickness of the wall.

- `level`: If ``true`` `thk` is interpreted as the level of the bottom surface instead of a constant thickness.
"""
function vwall(Bt::Union{Matrix{<:Real}, GMTdataset}, thk::Union{<:Real, AbstractVector{<:Real}}, level::Bool=false)
	Bb = copy(Bt)						# Always return a Matrix, not a DS
	if isa(thk, Real)
		if (level)  view(Bb, :, 3) .=  convert(eltype(Bt), thk)
		else        view(Bb, :, 3) .-= convert(eltype(Bt), thk)
		end
	else            view(Bb, :, 3) .-= thk
	end
	vwall(Bt, Bb)
end

# ---------------------------------------------------------------------------------------------------
"""
    D = vwall(Bt::Union{Matrix, GMTdataset}, Bb::Union{Matrix, GMTdataset}) -> Vector{GMTdataset}

Compute the vertical wall between two grid's concave hull `Bt` and `Bb`.
"""
function vwall(Bt::Union{Matrix{<:Real}, GMTdataset}, Bb::Union{Matrix{<:Real}, GMTdataset})
	(size(Bt) != size(Bb)) && error("Input matrices must be the same size")
	n_sideT = size(Bb,1) - 1
	Twall = Vector{GMTdataset}(undef, 2 * n_sideT)
	for k = 1:n_sideT
		kk = 2 * k -1
		Twall[kk]   = GMTdataset(data=[Bt[k,1]   Bt[k,2]   Bt[k,3];   Bt[k+1,1] Bt[k+1,2] Bt[k+1,3]; Bb[k,1] Bb[k,2] Bb[k,3]])
		Twall[kk+1] = GMTdataset(data=[Bt[k+1,1] Bt[k+1,2] Bt[k+1,3]; Bb[k+1,1] Bb[k+1,2] Bb[k+1,3]; Bb[k,1] Bb[k,2] Bb[k,3]])
		Twall[kk].header = Twall[kk+1].header = "-Z$(Bt[k,3]+1e6)"		# Can be used, e.g., with the foreground color of a CPT 
	end
	set_dsBB!(Twall)
	isa(Bt, GMTdataset) && (Twall[1].proj4 = Bt.proj4)
	Twall[1].geom = wkbPolygonZM
	return Twall
end
