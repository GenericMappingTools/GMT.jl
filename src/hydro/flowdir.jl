# Flow directions from a DEM: depression handling (Priority-Flood fill or carve), D8 receivers with
# routing over flats, and a topological order of the flow graph. No sparse matrices: the flow graph is
# a receiver vector and the order is built from donor lists stored as two plain index vectors.
#
# References:
#   Barnes, Lehman & Mulla (2014), Priority-Flood: An optimal depression-filling and watershed-labeling
#     algorithm for digital elevation models. Computers & Geosciences 62, 117-127.
#   Soille (2004), Optimal removal of spurious pits in grid digital elevation models. WRR 40.
#   Braun & Willett (2013), A very efficient O(n), implicit and parallel method to solve the stream power
#     equation governing fluvial incision and landscape evolution. Geomorphology 180-181, 170-179.

"""
	flownet

D8 flow-direction object returned by [`flowdir`](@ref). Its arrays use a canonical orientation:
row 1 is the southernmost row (lowest y) and column 1 the westernmost (lowest x).

Fields:
- `rcv::Vector{Int32}`: receiver (linear index) of each cell. Outlets receive into themselves; nodata cells have 0.
- `order::Vector{Int32}`: valid cells ordered so that every receiver comes before its donors (outlets first).
- `dem::Matrix{Float32}`: the hydrologically conditioned DEM (filled or carved). NaN marks nodata.
- `dx::Vector{Float64}`: cell width in x for each row (metres for geographic grids).
- `dy::Float64`: cell height in y (metres for geographic grids).
- `geog::Bool`: true if the grid is in geographic coordinates.
- `xc, yc::Vector{Float64}`: cell-centre coordinates.
- `G::GMTgrid`: the input grid, used as georeferencing template for the outputs.
"""
struct flownet
	rcv::Vector{Int32}
	order::Vector{Int32}
	dem::Matrix{Float32}
	dx::Vector{Float64}
	dy::Float64
	geog::Bool
	xc::Vector{Float64}
	yc::Vector{Float64}
	G::GMTgrid
end

Base.size(F::flownet) = size(F.dem)
function Base.show(io::IO, F::flownet)
	n_out = count(k -> F.rcv[k] == k, F.order)
	print(io, "flownet: ", size(F.dem, 1), "x", size(F.dem, 2), " grid, ", length(F.order), " valid cells, ",
	      n_out, " outlets", F.geog ? " (geographic)" : "")
end

# D8 neighbour offsets (row = south->north, col = west->east)
const _HY_DI = (1, 1, 0, -1, -1, -1, 0, 1)
const _HY_DJ = (0, 1, 1, 1, 0, -1, -1, -1)

# ---------------------------------------------------------------------------------------------------
"""
	FD = flowdir(G::GMTgrid; method=:fill, sinks=nothing, geog=nothing)

Compute D8 flow directions from the DEM `G` (a `GMTgrid` or a file name).

Depressions (pits) are removed before computing the directions so that every cell drains to an
outlet on the grid border or next to a nodata (NaN) cell:
- `method=:fill` (default): raise each depression to the level of its spill point (Priority-Flood).
- `method=:carve`: keep the depression and lower a channel from it to its spill point (breaching).

Flow on flat areas (including filled lakes) is routed toward their spill point.

- `sinks`: cells that are real internal sinks (e.g. endorheic lakes, karst). They act as outlets and
  are not filled. Give it as a `GMTgrid` (nonzero = sink) or as a Bool matrix in the canonical
  orientation (row 1 = south).
- `geog`: force geographic (`true`) or Cartesian (`false`) coordinates. By default it is taken from the
  grid's referencing. For geographic grids distances and areas are computed in metres.
- `sealevel`: cells at or below this elevation are treated as sea (nodata), so rivers end at the
  coast. E.g. `sealevel=0` for DEMs that include bathymetry (`@earth_relief`). The input is not modified.
- `progress`: optional function `(fraction, stage) -> ...` called periodically with the completed
  fraction (0..1) and a stage description, e.g. to drive a progress bar. If it returns `false` the
  computation stops and throws `GMT.HydroCancelled` (not exported; catch it as
  `e isa GMT.HydroCancelled`). `flowacc` and `twi` take the same keyword.

Returns a [`flownet`](@ref) object used by `flowacc`, `drainagebasins`, `flowdistance`, `streamorder`,
`streamnet`, `snap2stream` and `ldd`.

### Example
```julia
G  = gmtread("@earth_relief_30s", region=(-9.5,-7.5,38.5,40))
FD = flowdir(G)
A  = flowacc(FD)
B  = drainagebasins(FD, minarea=1000)
```
"""
function flowdir(G::GMTgrid; method::Union{Symbol,String}=:fill, sinks=nothing, geog=nothing, sealevel=nothing,
                 progress=nothing)
	m = Symbol(method)
	(m in (:fill, :carve)) || error("flowdir: method must be :fill or :carve, not :$m")
	_hy_report(progress, 0.0, "Preparing DEM")
	M, xc, yc = _hydro_canon(G)
	if (sealevel !== nothing)
		sl = Float32(sealevel)
		@inbounds for k in eachindex(M);  (M[k] <= sl) && (M[k] = NaN32)  end
	end
	isgeo = (geog === nothing) ? _hydro_isgeog(G) : Bool(geog)
	dx, dy = _hydro_spacing(G, yc, isgeo)
	sk = _hydro_sinks(sinks, size(M))
	parent, isseed = _hydro_condition!(M, m, sk, progress)
	_hy_report(progress, 0.85, "Flow directions")
	rcv = _hydro_receivers(M, parent, isseed, dx, dy)
	_hy_report(progress, 0.95, "Ordering the flow network")
	order = _hydro_toporder(rcv, count(!isnan, M))
	_hy_report(progress, 1.0, "Done")
	flownet(rcv, order, M, dx, dy, isgeo, xc, yc, G)
end

# ---------------------------------------------------------------------------------------------------
"""
Thrown by the hydrology functions when their `progress` callback returns `false` (user cancel).
"""
struct HydroCancelled <: Exception end
Base.showerror(io::IO, ::HydroCancelled) = print(io, "hydrology computation cancelled")

# Progress reporting. `progress` is `nothing` or a function `(fraction::Float64, stage::String)`.
# Returning `false` from it cancels the computation (throws HydroCancelled). Called only a few hundred
# times per run, so its cost is negligible.
@inline function _hy_report(progress, f::Float64, stage::String)
	(progress === nothing) && return nothing
	(progress(f, stage) === false) && throw(HydroCancelled())
	return nothing
end
flowdir(fname::String; kw...) = flowdir(gmtread(fname); kw...)

# ---------------------------------------------------------------------------------------------------
# Get the grid values as Matrix{Float32} with row 1 = lowest y and column 1 = lowest x, nodata = NaN.
function _hydro_canon(G::GMTgrid)
	(ndims(G.z) == 2) || error("hydro functions only accept 2D grids")
	reg = G.registration
	nx = round(Int, (G.range[2] - G.range[1]) / G.inc[1]) + (reg == 0 ? 1 : 0)
	ny = round(Int, (G.range[4] - G.range[3]) / G.inc[2]) + (reg == 0 ? 1 : 0)
	Z = G.z
	isR = length(G.layout) >= 2 && G.layout[2] == 'R'
	if (size(Z) == (nx, ny) && (nx != ny || (isR && !istransposed(Z))))
		M = Matrix{Float32}(permutedims(Z))
	elseif (size(Z) == (ny, nx))
		M = Matrix{Float32}(Z)
	else
		error("grid array size $(size(Z)) does not match its header ($ny rows x $nx columns)")
	end
	(length(G.layout) >= 1 && G.layout[1] == 'T') && reverse!(M, dims=1)
	if (!isnan(G.nodata))
		nd = Float32(G.nodata)
		@inbounds for k in eachindex(M);  (M[k] == nd) && (M[k] = NaN32)  end
	end
	x0 = G.range[1] + (reg == 1 ? G.inc[1] / 2 : 0.0)
	y0 = G.range[3] + (reg == 1 ? G.inc[2] / 2 : 0.0)
	return M, collect(x0 .+ (0:nx-1) .* G.inc[1]), collect(y0 .+ (0:ny-1) .* G.inc[2])
end

function _hydro_isgeog(G::GMTgrid)::Bool
	(G.geog > 0) && return true
	(G.proj4 == "" && G.wkt == "" && G.epsg == 0) && return false
	try  return isgeog(G)  catch;  return false  end
end

# Cell size per row. Geographic grids get metres on a sphere of the mean Earth radius.
function _hydro_spacing(G::GMTgrid, yc::Vector{Float64}, isgeo::Bool)
	if (isgeo)
		R = 6371008.8
		dy = R * deg2rad(G.inc[2])
		dx = [max(R * deg2rad(G.inc[1]) * cosd(clamp(y, -90.0, 90.0)), 1e-6 * dy) for y in yc]
	else
		dy = G.inc[2]
		dx = fill(G.inc[1], length(yc))
	end
	return dx, dy
end

function _hydro_sinks(sinks, sz)
	(sinks === nothing) && return nothing
	S = isa(sinks, GMTgrid) ? (_hydro_canon(sinks)[1] .!= 0) : BitMatrix(sinks .!= 0)
	(size(S) == sz) || error("sinks must have the same size as the DEM $(sz), not $(size(S))")
	return S
end

# ---------------------------------------------------------------------------------------------------
# Minimal binary min-heap of (elevation, cell). Equal elevations need no tie-break: cells at the level
# of the cell they are reached from never enter the heap, they go to the FIFO pit queue (see below).
# The sift moves a "hole" instead of swapping, so each level costs one write instead of three.
mutable struct _HyHeap
	z::Vector{Float32}
	v::Vector{Int32}
	n::Int
end
_HyHeap(cap::Integer) = _HyHeap(Vector{Float32}(undef, cap), Vector{Int32}(undef, cap), 0)

function _hy_push!(q::_HyHeap, z::Float32, v::Int32)
	q.n += 1
	i = q.n
	@inbounds while i > 1
		p = i >> 1
		(z < q.z[p]) || break
		q.z[i] = q.z[p];	q.v[i] = q.v[p]
		i = p
	end
	@inbounds q.z[i] = z;	@inbounds q.v[i] = v
	return nothing
end

function _hy_pop!(q::_HyHeap)::Int32
	@inbounds v = q.v[1]
	n = q.n
	@inbounds zl = q.z[n];	@inbounds vl = q.v[n]
	n -= 1;	q.n = n
	i = 1
	@inbounds while true
		l = 2i
		(l > n) && break
		c = (l + 1 <= n && q.z[l + 1] < q.z[l]) ? l + 1 : l
		(q.z[c] < zl) || break
		q.z[i] = q.z[c];	q.v[i] = q.v[c]
		i = c
	end
	(n > 0) && (@inbounds q.z[i] = zl;	@inbounds q.v[i] = vl)
	return v
end

# ---------------------------------------------------------------------------------------------------
# Priority-Flood from the outlets (grid border, cells next to NaN, user sinks). Modifies `z` in place.
# Returns the parent (the cell each cell was reached from) and the seed mask.
# :fill  raises cells lower than the cell they were reached from.
# :carve lowers the already-flooded path back toward the outlet to the level of the lower cell.
# In both cases z[parent] <= z[cell] at the end, which guarantees an acyclic flow graph.
#
# Cells reached at or below the level of the cell they come from (pits, flats, filled lakes) go to a
# plain FIFO queue that is emptied before the heap is touched again (Barnes et al., 2014, "improved"
# Priority-Flood): they cost O(1) instead of O(log n), and flats are still walked breadth-first from
# their spill point. Each cell enters exactly one of the two queues, once, so the FIFO is a flat array.
function _hydro_condition!(z::Matrix{Float32}, method::Symbol, sinks, progress=nothing)
	ny, nx = size(z)
	parent = zeros(Int32, ny * nx)
	closed = zeros(Bool, ny * nx)
	isseed = falses(ny, nx)
	nvalid = count(!isnan, z)
	q = _HyHeap(nvalid)
	pit = Vector{Int32}(undef, nvalid);	ph = 1;	pt = 0
	@inbounds for j = 1:nx, i = 1:ny
		k = i + (j - 1) * ny
		isnan(z[k]) && continue
		s = (i == 1 || i == ny || j == 1 || j == nx) || (sinks !== nothing && sinks[k])
		if (!s)
			for d = 1:8
				isnan(z[i + _HY_DI[d], j + _HY_DJ[d]]) && (s = true; break)
			end
		end
		s || continue
		isseed[k] = true;	closed[k] = true
		_hy_push!(q, z[k], Int32(k))
	end

	carve = (method == :carve)
	npop = 0
	stage = carve ? "Carving depressions" : "Filling depressions"
	@inbounds for k in eachindex(z)  isnan(z[k]) && (closed[k] = true)  end	# nodata is never entered
	offs = ntuple(d -> _HY_DI[d] + _HY_DJ[d] * ny, 8)			# linear offsets of the 8 neighbours
	nlast = ny * nx - ny
	@inbounds while ph <= pt || q.n > 0
		if (ph <= pt)
			c = pit[ph];	ph += 1
		else
			c = _hy_pop!(q)
		end
		((npop += 1) & 0xFFFF == 0) && _hy_report(progress, 0.05 + 0.75 * npop / nvalid, stage)
		r0 = (c - 1) % ny									# 0-based row; interior cells skip all bound tests
		inner = (r0 != 0 && r0 != ny - 1 && c > ny && c <= nlast)
		for d = 1:8
			if (inner)
				k = c + offs[d]
			else
				i = r0 + 1 + _HY_DI[d];	j = (c - 1) ÷ ny + 1 + _HY_DJ[d]
				(1 <= i <= ny && 1 <= j <= nx) || continue
				k = i + (j - 1) * ny
			end
			closed[k] && continue
			closed[k] = true
			parent[k] = c
			if (z[k] <= z[c])
				if (z[k] < z[c])
					if (carve)
						t = z[k];	cur = c
						while (cur != 0 && z[cur] > t)
							z[cur] = t
							cur = parent[cur]
						end
					else
						z[k] = z[c]
					end
				end
				pt += 1;	pit[pt] = Int32(k)
			else
				_hy_push!(q, z[k], Int32(k))
			end
		end
	end
	return parent, isseed
end

# ---------------------------------------------------------------------------------------------------
# Steepest-descent D8 receiver. Cells with no lower neighbour (flats) drain to their Priority-Flood
# parent, which has the same elevation and lies on the path to the spill point. Seeds without a lower
# neighbour are outlets (receive into themselves).
function _hydro_receivers(z::Matrix{Float32}, parent::Vector{Int32}, isseed::BitMatrix, dx::Vector{Float64}, dy::Float64)
	ny, nx = size(z)
	rcv = zeros(Int32, ny * nx)
	Threads.@threads for j = 1:nx				# every cell is independent: one column per task
		_hydro_receivers_col!(rcv, z, parent, isseed, dx, dy, j)
	end
	return rcv
end

function _hydro_receivers_col!(rcv::Vector{Int32}, z::Matrix{Float32}, parent::Vector{Int32}, isseed::BitMatrix,
                               dx::Vector{Float64}, dy::Float64, j::Int)
	ny, nx = size(z)
	@inbounds for i = 1:ny
		k = i + (j - 1) * ny
		zk = z[k]
		isnan(zk) && continue
		dd = sqrt(dx[i]^2 + dy^2)
		best = 0.0;	r = 0
		for d = 1:8
			ii = i + _HY_DI[d];	jj = j + _HY_DJ[d]
			(1 <= ii <= ny && 1 <= jj <= nx) || continue
			kk = ii + (jj - 1) * ny
			zn = z[kk]
			(isnan(zn) || zn >= zk) && continue
			dist = (_HY_DI[d] == 0) ? dx[i] : (_HY_DJ[d] == 0) ? dy : dd
			s = (zk - zn) / dist
			(s > best) && (best = s; r = kk)
		end
		rcv[k] = (r != 0) ? Int32(r) : isseed[k] ? Int32(k) : parent[k]
	end
	return rcv
end

# ---------------------------------------------------------------------------------------------------
# Donor lists in compressed form (offsets + donor indices), built with a counting sort.
function _hydro_donors(rcv::Vector{Int32})
	n = length(rcv)
	off = zeros(Int32, n + 1)
	@inbounds for k = 1:n
		r = rcv[k]
		(r != 0 && r != k) && (off[r + 1] += Int32(1))
	end
	@inbounds for k = 1:n  off[k + 1] += off[k]  end
	don = Vector{Int32}(undef, off[end])
	pos = copy(off)
	@inbounds for k = 1:n
		r = rcv[k]
		(r == 0 || r == k) && continue
		pos[r] += Int32(1)
		don[pos[r]] = Int32(k)
	end
	return off, don
end

# Breadth-first order from the outlets: every receiver comes before its donors.
function _hydro_toporder(rcv::Vector{Int32}, nvalid::Int)
	off, don = _hydro_donors(rcv)
	order = Vector{Int32}(undef, nvalid)
	m = 0
	@inbounds for k = 1:length(rcv)
		(rcv[k] == k) && (m += 1; order[m] = Int32(k))
	end
	h = 1
	@inbounds while h <= m
		c = order[h];	h += 1
		for p = off[c] + 1:off[c + 1]
			m += 1;	order[m] = don[p]
		end
	end
	(m == nvalid) || error("flowdir: internal error, $(nvalid - m) cells do not reach an outlet (cycle in flow graph)")
	return order
end
