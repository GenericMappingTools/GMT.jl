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
- $(GMT.opt_I)
- $(GMT._opt_J)
- **L** | **index** :: [Type => Bool]

    Give name of file with previously computed Delaunay information. If the indexfile is binary and can be read
    the same way as the binary input table then you can append +b to spead up the reading (GMT6.4).
- **M** | **network** :: [Type => Bool]

    Output triangulation network as multiple line segments separated by a segment header record.
- **N** | **ids** :: [Type => Bool]

    Used in conjunction with G to also write the triplets of the ids of all the Delaunay vertices
- **Q** | **voronoi** :: [Type => Str | []]

    Output the edges of the Voronoi cells instead [Default is Delaunay triangle edges]
- $(GMT._opt_R)
- **S** | **triangles** :: [Type => Bool]  

    Output triangles as polygon segments separated by a segment header record. Requires Delaunay triangulation.
- **T** | **edges** :: [Type => Bool]

    Output edges or polygons even if gridding has been selected with the G option
- $(GMT.opt_V)
- **Z** | **xyz** | **triplets** :: [Type => Bool]

- $(GMT._opt_bi)
- $(GMT.opt_bo)
- $(GMT._opt_di)
- $(GMT.opt_e)
- $(GMT._opt_f)
- $(GMT._opt_h)
- $(GMT._opt_i)
- $(GMT.opt_r)
- $(GMT.opt_w)
- $(GMT.opt_swap_xy)

To see the full documentation type: ``@? triangulate``
"""
function triangulate(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :bi :bo :di :e :f :h :i :w :yx])
	(haskey(d, :Z) && isa(d[:Z], Bool) && !d[:Z]) && delete!(d, :Z)		# Strip Z=false from 'd' (for triplot)
	cmd  = parse_these_opts(cmd, d, [[:A :area], [:C :slope_grid], [:D :derivatives], [:E :empty], [:L :index],
	                                 [:M :network], [:N :ids], [:S :triangles], [:T :edges], [:Z :xyz :triplets]])
	cmd = parse_Q_tri(d, [:Q :voronoi], cmd)
	(occursin("-I", cmd) && occursin("-R", cmd) && !occursin("-G", cmd)) && (cmd *= " -G")
	(occursin("-Q", cmd) && !occursin("-M", cmd)) && (cmd *= " -M")		# Otherwise kills Julia (GMT bug)
	(!occursin("-G", cmd)) && (cmd = parse_J(d, cmd, " ")[1])

	common_grd(d, cmd0, cmd, "triangulate ", arg1)		# Finish build cmd and run it
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
triangulate(arg1; kw...) = triangulate("", arg1; kw...)

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
