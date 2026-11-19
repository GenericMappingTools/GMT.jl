# Products derived from a FlowNet: flow accumulation, drainage basins, flow distance, Strahler order,
# vector stream network, outlet snapping and PCRaster LDD export.

# Wrap a canonical (row 1 = south) matrix into a GMTgrid georeferenced like the FlowNet input.
function _hydro_grid(F::FlowNet, A::AbstractMatrix, title::String="")
	Go = mat2grid(Matrix{Float32}(A), F.G)
	Go.layout = "BCB"
	Go.title = title
	return Go
end

# Grid or matrix argument in canonical orientation and same size as the DEM.
function _hydro_layer(F::FlowNet, W)
	M = isa(W, GMTgrid) ? _hydro_canon(W)[1] : W
	(size(M) == size(F.dem)) || error("grid/matrix size $(size(M)) differs from the FlowNet size $(size(F.dem))")
	return M
end

# Distance between cell k and its receiver r.
@inline function _hydro_dist(F::FlowNet, k::Integer, r::Integer)
	ny = size(F.dem, 1)
	i = (k - 1) % ny + 1
	di = i - ((r - 1) % ny + 1)
	dj = (k - 1) ÷ ny - (r - 1) ÷ ny
	(di == 0) && return F.dx[i]
	(dj == 0) && return F.dy
	return sqrt(F.dx[i]^2 + F.dy^2)
end

# Initial per-cell contribution (1, weight, times cell area if requested). NaN outside the DEM.
function _hydro_acc_init(F::FlowNet, weights, area::Bool)
	ny = size(F.dem, 1)
	A = fill(NaN, size(F.dem))
	w = (weights === nothing) ? nothing : _hydro_layer(F, weights)
	@inbounds for k in F.order
		a = (w === nothing) ? 1.0 : Float64(w[k])
		area && (a *= F.dx[(k - 1) % ny + 1] * F.dy)
		A[k] = a
	end
	return A
end

function _hydro_acc(F::FlowNet, weights, area::Bool)
	A = _hydro_acc_init(F, weights, area)
	@inbounds for t = length(F.order):-1:1
		k = F.order[t];	r = F.rcv[k]
		(r != k) && (A[r] += A[k])
	end
	return A
end

# ---------------------------------------------------------------------------------------------------
"""
	A = flowacc(FD::FlowNet; weights=nothing, area=false, method=:d8, p=1.1)

Flow accumulation: the amount of water (number of cells, or area) draining through each cell, the
cell itself included.

- `area=true`: return the upstream area instead of the cell count (m² for geographic grids,
  squared map units otherwise).
- `weights`: a grid (or canonical matrix) with a value per cell, e.g. precipitation or runoff. Each
  cell contributes its weight instead of 1 (times its area if `area=true`).
- `method`: how the water of a cell is passed downhill.
  - `:d8` (default): all of it goes to the steepest of the 8 neighbours (the directions stored in `FD`).
  - `:mfd`: Multiple Flow Direction (Freeman, 1991). It is shared among *all* lower neighbours in
    proportion to `slope^p`. `p` controls the spreading: `p≈1` spreads widely (Quinn et al., 1991),
    `p=1.1` is Freeman's value, large `p` (>10) tends to D8.
  - `:dinf`: D-infinity (Tarboton, 1997). The steepest downhill direction is found as a continuous
    angle and the water is split between the two neighbours that bracket it. Less dispersion than MFD,
    but no straight-line artefacts like D8.

  In flats without a lower neighbour, both multi-flow methods fall back to the D8 direction.

### Which method to use
Use **D8** (the default) for anything that needs each cell to belong to a single flow path: drainage
basins, river networks, stream order, LDD maps for hydrological models. Those functions always use
D8. On hillslopes, however, water spreads rather than running down a line of single cells, and D8
draws artificial parallel straight lines on smooth slopes. Use **`:mfd` or `:dinf`** when the
accumulation is the end product on hillslopes, e.g. specific catchment area for a topographic wetness
index (TWI), soil moisture, erosion or landslide susceptibility. In valleys they make rivers several
cells wide, so do not use them to extract channels.

Between the two: **D∞** is exact on planar slopes (no lateral spreading at any flow angle) and is the
better choice on planar or converging slopes. On diverging forms (ridges, spurs, cones) it bunches
the flow along the cardinal and diagonal directions (Seibert & McGlynn, 2007); there **MFD** is more
accurate. Measured on a synthetic cone (exact specific catchment area r/2), the spread of the relative
error was 0.52 for D8, 0.06 for D∞ and 0.01 for MFD.

Note that the result is per cell. To get the specific catchment area (area per unit contour width,
used by the wetness index) divide the `area=true` result by the cell width.

References: Freeman (1991), Computers & Geosciences 17(3); Quinn et al. (1991), Hydrological
Processes 5(1); Tarboton (1997), Water Resources Research 33(2); Seibert & McGlynn (2007), Water
Resources Research 43(4).

Returns a `GMTgrid`.
"""
function flowacc(F::FlowNet; weights=nothing, area::Bool=false, method::Union{Symbol,String}=:d8, p::Real=1.1,
                 progress=nothing)
	m = Symbol(method)
	A = (m == :d8) ? _hydro_acc(F, weights, area) :
	    (m in (:mfd, :dinf)) ? _hydro_acc_multi(F, weights, area, m, Float64(p), progress) :
	    error("flowacc: method must be :d8, :mfd or :dinf, not :$m")
	tit = (area ? "Upstream area" : "Flow accumulation") * (m == :d8 ? "" : " ($m)")
	return _hydro_grid(F, A, tit)
end

# ---------------------------------------------------------------------------------------------------
# Receivers and fractions of cell k for the multiple-flow methods. Writes into tg/fr, returns their
# number. Only strictly lower neighbours receive water; with none, the D8 receiver (flat routing)
# is used. Hence the flow graph stays acyclic.
function _hydro_multi_targets!(tg::Vector{Int}, fr::Vector{Float64}, F::FlowNet, k::Int, m::Symbol, p::Float64)
	z = F.dem
	ny, nx = size(z)
	i = (k - 1) % ny + 1;	j = (k - 1) ÷ ny + 1
	z0 = Float64(z[k])
	dx = F.dx[i];	dy = F.dy;	dd = sqrt(dx^2 + dy^2)
	n = 0
	if (m == :mfd)
		tot = 0.0
		@inbounds for d = 1:8
			ii = i + _HY_DI[d];	jj = j + _HY_DJ[d]
			(1 <= ii <= ny && 1 <= jj <= nx) || continue
			kk = ii + (jj - 1) * ny
			zn = z[kk]
			(isnan(zn) || zn >= z0) && continue
			dist = (_HY_DI[d] == 0) ? dx : (_HY_DJ[d] == 0) ? dy : dd
			w = (p == 1.0) ? (z0 - zn) / dist : ((z0 - zn) / dist)^p
			n += 1;	tg[n] = kk;	fr[n] = w;	tot += w
		end
		@inbounds for t = 1:n  fr[t] /= tot  end
	else			# :dinf - 8 triangular facets, each made of one cardinal and one diagonal neighbour
		best = 0.0;	k1 = 0;	k2 = 0;	f1 = 0.0
		@inbounds for d in (1, 3, 5, 7)					# cardinal neighbours (N, E, S, W)
			ci = i + _HY_DI[d];	cj = j + _HY_DJ[d]
			(1 <= ci <= ny && 1 <= cj <= nx) || continue
			kc = ci + (cj - 1) * ny
			e1 = Float64(z[kc]);	isnan(e1) && continue
			d1 = (_HY_DI[d] == 0) ? dx : dy				# distance to the cardinal neighbour
			d2 = (_HY_DI[d] == 0) ? dy : dx				# side step to the diagonal one
			for dg in (d == 1 ? 8 : d - 1, d + 1)		# the two diagonals next to this cardinal
				gi = i + _HY_DI[dg];	gj = j + _HY_DJ[dg]
				(1 <= gi <= ny && 1 <= gj <= nx) || continue
				kg = gi + (gj - 1) * ny
				e2 = Float64(z[kg]);	isnan(e2) && continue
				s1 = (z0 - e1) / d1;	s2 = (e1 - e2) / d2
				amax = atan(d2, d1)
				r = atan(s2, s1)
				if (r < 0)        r = 0.0;  s = s1
				elseif (r > amax) r = amax; s = (z0 - e2) / sqrt(d1^2 + d2^2)
				else              s = sqrt(s1^2 + s2^2)
				end
				(s > best) && (best = s; k1 = kc; k2 = kg; f1 = 1.0 - r / amax)
			end
		end
		if (best > 0)
			(f1 > 1e-12)       && (n += 1; tg[n] = k1; fr[n] = f1)
			(1 - f1 > 1e-12)   && (n += 1; tg[n] = k2; fr[n] = 1.0 - f1)
		end
	end
	if (n == 0)			# flat or outlet: D8 direction
		r = Int(F.rcv[k])
		(r != k) && (n = 1; tg[1] = r; fr[1] = 1.0)
	end
	return n
end

# MFD: number of cells sending water to each cell, counted from the RECEIVER's side so that every task
# writes only its own cells (threaded, no atomics). A cell receives from every higher valid neighbour,
# plus from equal-elevation (flat) neighbours whose D8 direction points at it — exactly what
# _hydro_multi_targets! sends.
function _hydro_ndonors_mfd(F::FlowNet)
	z = F.dem
	ny, nx = size(z)
	ndon = zeros(Int32, ny * nx)
	Threads.@threads for j = 1:nx
		@inbounds for i = 1:ny
			r = i + (j - 1) * ny
			zr = z[r]
			isnan(zr) && continue
			c = 0
			for d = 1:8
				ii = i + _HY_DI[d];	jj = j + _HY_DJ[d]
				(1 <= ii <= ny && 1 <= jj <= nx) || continue
				kk = ii + (jj - 1) * ny
				zn = z[kk]
				(isnan(zn) || zn < zr) && continue			# a donor is never lower
				((zn > zr) || F.rcv[kk] == r) && (c += 1)
			end
			ndon[r] = Int32(c)
		end
	end
	return ndon
end

# D∞: every cell sends to at most two cells. Their indices and the first one's share are computed once,
# threaded (the facet search with its atan/sqrt is the expensive part), into three flat arrays
# (12 bytes per cell). t2 == 0 when all the water goes to t1; t1 == 0 for outlets.
function _hydro_dinf_table(F::FlowNet)
	n = length(F.rcv)
	t1 = zeros(Int32, n);	t2 = zeros(Int32, n);	f1 = ones(Float32, n)
	nx = size(F.dem, 2);	ny = size(F.dem, 1)
	Threads.@threads for j = 1:nx
		tg = zeros(Int, 8);	fr = zeros(8)
		@inbounds for i = 1:ny
			k = i + (j - 1) * ny
			isnan(F.dem[k]) && continue
			c = _hydro_multi_targets!(tg, fr, F, k, :dinf, 1.0)
			(c >= 1) && (t1[k] = Int32(tg[1]);	f1[k] = Float32(fr[1]))
			(c >= 2) && (t2[k] = Int32(tg[2]))
		end
	end
	return t1, t2, f1
end

# Multiple-flow accumulation. Cells are processed in a topological order of the multi-flow graph
# (Kahn's algorithm: a cell is processed once all the cells that send it water are done).
function _hydro_acc_multi(F::FlowNet, weights, area::Bool, m::Symbol, p::Float64, progress=nothing)
	nv = length(F.order);	stage = "Flow accumulation ($(uppercase(string(m))))"
	_hy_report(progress, 0.0, stage)
	A = _hydro_acc_init(F, weights, area)
	queue = Vector{Int32}(undef, nv)
	h = 1;	nq = 0
	if (m == :dinf)
		t1, t2, f1 = _hydro_dinf_table(F)
		ndon = zeros(Int32, length(F.rcv))
		@inbounds for k in F.order
			(t1[k] != 0) && (ndon[t1[k]] += Int32(1))
			(t2[k] != 0) && (ndon[t2[k]] += Int32(1))
		end
		_hy_report(progress, 0.4, stage)
		@inbounds for k in F.order
			(ndon[k] == 0) && (nq += 1; queue[nq] = k)
		end
		@inbounds while h <= nq
			k = queue[h];	h += 1
			(h & 0xFFFF == 0) && _hy_report(progress, 0.4 + 0.6 * h / nv, stage)
			a = A[k]
			r = t1[k]
			(r == 0) && continue
			s = t2[k]
			A[r] += (s == 0) ? a : a * f1[k]
			((ndon[r] -= Int32(1)) == 0) && (nq += 1; queue[nq] = r)
			(s == 0) && continue
			A[s] += a * (1 - Float64(f1[k]))
			((ndon[s] -= Int32(1)) == 0) && (nq += 1; queue[nq] = s)
		end
	else
		ndon = _hydro_ndonors_mfd(F)
		_hy_report(progress, 0.1, stage)
		tg = zeros(Int, 8);	fr = zeros(8)
		@inbounds for k in F.order
			(ndon[k] == 0) && (nq += 1; queue[nq] = k)
		end
		@inbounds while h <= nq
			k = Int(queue[h]);	h += 1
			(h & 0xFFFF == 0) && _hy_report(progress, 0.1 + 0.9 * h / nv, stage)
			n = _hydro_multi_targets!(tg, fr, F, k, m, p)
			for t = 1:n
				r = tg[t]
				A[r] += A[k] * fr[t]
				ndon[r] -= Int32(1)
				(ndon[r] == 0) && (nq += 1; queue[nq] = Int32(r))
			end
		end
	end
	(nq == nv) || error("flowacc: internal error, multi-flow graph has cycles")
	return A
end

# ---------------------------------------------------------------------------------------------------
# Convert outlet coordinates to linear indices. Accepts a Nx2 matrix, a GMTdataset or a (x,y) tuple.
function _hydro_xy2ind(F::FlowNet, xy)
	P = isa(xy, GMTdataset) ? xy.data : isa(xy, Tuple) ? [xy[1] xy[2]] : xy
	(size(P, 2) >= 2) || error("outlets must have two columns (x, y)")
	ny, nx = size(F.dem)
	ind = Vector{Int}(undef, size(P, 1))
	for p = 1:size(P, 1)
		j = round(Int, (P[p, 1] - F.xc[1]) / F.G.inc[1]) + 1
		i = round(Int, (P[p, 2] - F.yc[1]) / F.G.inc[2]) + 1
		(1 <= i <= ny && 1 <= j <= nx) || error("outlet $p ($(P[p,1]), $(P[p,2])) is outside the grid")
		ind[p] = i + (j - 1) * ny
	end
	return ind
end

# Move each index to the cell with the largest flow accumulation within `radius` cells.
function _hydro_snap!(ind::Vector{Int}, F::FlowNet, radius::Int, A::Matrix{Float64})
	ny, nx = size(F.dem)
	for p in eachindex(ind)
		i0 = (ind[p] - 1) % ny + 1;	j0 = (ind[p] - 1) ÷ ny + 1
		best = isnan(A[ind[p]]) ? -Inf : A[ind[p]]
		for j = max(1, j0 - radius):min(nx, j0 + radius), i = max(1, i0 - radius):min(ny, i0 + radius)
			((i - i0)^2 + (j - j0)^2 > radius^2) && continue
			k = i + (j - 1) * ny
			(!isnan(A[k]) && A[k] > best) && (best = A[k]; ind[p] = k)
		end
	end
	return ind
end

"""
	xy = snap2stream(FD::FlowNet, outlets; radius=3)

Move each outlet to the cell with the largest flow accumulation within `radius` cells, so that
points digitized near a river land on the river. `outlets` is a Nx2 matrix of (x, y), a `GMTdataset`
or a `(x, y)` tuple. Returns a Nx2 matrix with the snapped cell-centre coordinates.
"""
function snap2stream(F::FlowNet, outlets; radius::Int=3)
	ind = _hydro_snap!(_hydro_xy2ind(F, outlets), F, radius, _hydro_acc(F, nothing, false))
	ny = size(F.dem, 1)
	return [[F.xc[(k - 1) ÷ ny + 1] for k in ind] [F.yc[(k - 1) % ny + 1] for k in ind]]
end

# ---------------------------------------------------------------------------------------------------
"""
	B = drainagebasins(FD::FlowNet; outlets=nothing, snap=0, minarea=0)

Label drainage basins (catchments).

- Without `outlets`: every cell gets the label of the outlet it finally drains to. Basins are numbered
  by decreasing size (1 = largest). Basins with fewer than `minarea` cells are set to NaN.
- With `outlets` (Nx2 matrix of x,y, a `GMTdataset` or a `(x,y)` tuple): label the area upstream of
  each point; basin `i` belongs to outlet `i`. Nested outlets give nested sub-basins. Cells that do
  not drain to any outlet are NaN. `snap > 0` first moves each outlet to the highest flow
  accumulation within `snap` cells (see [`snap2stream`](@ref)).

Returns a `GMTgrid` (Float32, labels are exact up to 16.7 million basins).
To get the basin outlines as polygons use `polygonize(B)`.
"""
function drainagebasins(F::FlowNet; outlets=nothing, snap::Int=0, minarea::Real=0)
	n = length(F.rcv)
	lab = zeros(Int32, size(F.dem))
	if (outlets === nothing)
		nb = Int32(0)
		@inbounds for k in F.order
			r = F.rcv[k]
			lab[k] = (r == k) ? (nb += Int32(1)) : lab[r]
		end
		cnt = zeros(Int, nb)
		@inbounds for k in F.order  cnt[lab[k]] += 1  end
		p = sortperm(cnt, rev=true)
		newid = zeros(Int32, nb)
		for (rank, b) in enumerate(p)
			newid[b] = (cnt[b] >= minarea) ? Int32(rank) : Int32(0)
		end
		@inbounds for k in F.order  lab[k] = newid[lab[k]]  end
	else
		ind = _hydro_xy2ind(F, outlets)
		(snap > 0) && _hydro_snap!(ind, F, snap, _hydro_acc(F, nothing, false))
		for (b, k) in enumerate(ind)  lab[k] = Int32(b)  end
		@inbounds for k in F.order
			(lab[k] == 0 && F.rcv[k] != k) && (lab[k] = lab[F.rcv[k]])
		end
	end
	B = Matrix{Float32}(undef, size(F.dem))
	@inbounds for k = 1:n  B[k] = (lab[k] == 0) ? NaN32 : Float32(lab[k])  end
	return _hydro_grid(F, B, "Drainage basins")
end

# ---------------------------------------------------------------------------------------------------
"""
	D = flowdistance(FD::FlowNet)

Distance from each cell to its outlet, measured along the flow path (metres for geographic grids,
map units otherwise). Returns a `GMTgrid`.
"""
function flowdistance(F::FlowNet)
	D = fill(NaN, size(F.dem))
	@inbounds for k in F.order
		r = F.rcv[k]
		D[k] = (r == k) ? 0.0 : D[r] + _hydro_dist(F, k, r)
	end
	return _hydro_grid(F, D, "Flow distance")
end

# ---------------------------------------------------------------------------------------------------
# Stream mask and Strahler order (UInt8, 0 = not a stream).
function _hydro_strahler(F::FlowNet, threshold::Real, area::Bool)
	A = _hydro_acc(F, nothing, area)
	ord = zeros(UInt8, size(F.dem))
	mx  = zeros(UInt8, size(F.dem))
	cnt = zeros(UInt8, size(F.dem))
	@inbounds for t = length(F.order):-1:1		# donors before receivers
		k = F.order[t]
		(A[k] >= threshold) || continue
		o = (mx[k] == 0) ? UInt8(1) : (cnt[k] >= 2) ? mx[k] + UInt8(1) : mx[k]
		ord[k] = o
		r = F.rcv[k]
		(r == k) && continue
		if (o > mx[r])      mx[r] = o; cnt[r] = 1
		elseif (o == mx[r]) cnt[r] = min(cnt[r] + 1, 2)
		end
	end
	return ord
end

"""
	S = streamorder(FD::FlowNet; threshold=1000, area=false)

Strahler order of the stream network. A cell is part of the network when its flow accumulation is
at least `threshold` (cells, or area units if `area=true`; see [`flowacc`](@ref)). Cells outside
the network are NaN. Returns a `GMTgrid`.
"""
function streamorder(F::FlowNet; threshold::Real=1000, area::Bool=false)
	ord = _hydro_strahler(F, threshold, area)
	S = Matrix{Float32}(undef, size(ord))
	@inbounds for k in eachindex(ord)  S[k] = (ord[k] == 0) ? NaN32 : Float32(ord[k])  end
	return _hydro_grid(F, S, "Strahler order")
end

"""
	D = streamnet(FD::FlowNet; threshold=1000, area=false)

Vector stream network: one line per reach, from a channel head or a confluence down to the next
confluence or outlet. The network is selected like in [`streamorder`](@ref).

Returns a `Vector{GMTdataset}` with columns x, y, elevation (of the conditioned DEM) and Strahler
order. The header of each line holds `-Z<order>`, so `plot(D, Z=true, C=cpt)` colours the reaches by
order. The `attrib` field also keeps the order (key "order").
"""
function streamnet(F::FlowNet; threshold::Real=1000, area::Bool=false)
	ord = _hydro_strahler(F, threshold, area)
	ny = size(F.dem, 1)
	ndon = zeros(UInt8, size(F.dem))			# number of stream donors (saturates at 2)
	@inbounds for k in F.order
		(ord[k] == 0) && continue
		r = F.rcv[k]
		(r != k) && (ndon[r] = min(ndon[r] + 1, 2))
	end
	segs = Matrix{Float64}[];	hdrs = String[];	orders = Int[]
	path = Int32[]
	@inbounds for k in F.order
		(ord[k] == 0 || ndon[k] == 1) && continue	# reaches start at heads (0 donors) and confluences (2+)
		F.rcv[k] == k && ndon[k] == 0 && continue	# isolated one-cell outlet
		empty!(path);	push!(path, k);	cur = k
		while true
			r = F.rcv[cur]
			(r == cur || ord[r] == 0) && break
			push!(path, r)
			(ndon[r] != 1) && break
			cur = r
		end
		(length(path) < 2) && continue
		seg = Matrix{Float64}(undef, length(path), 4)
		for (p, c) in enumerate(path)
			seg[p, 1] = F.xc[(c - 1) ÷ ny + 1];	seg[p, 2] = F.yc[(c - 1) % ny + 1]
			seg[p, 3] = F.dem[c];	seg[p, 4] = ord[k]
		end
		push!(segs, seg);	push!(hdrs, "-Z$(ord[k])");	push!(orders, ord[k])
	end
	isempty(segs) && return GMTdataset[]
	D = mat2ds(segs, hdr=hdrs)
	Dv = isa(D, Vector) ? D : [D]
	for (d, o) in zip(Dv, orders)
		d.proj4 = F.G.proj4;	d.wkt = F.G.wkt;	d.epsg = F.G.epsg
		d.colnames = ["x", "y", "z", "order"]
		d.attrib = Dict("order" => string(o))
		d.geom = wkbLineString
	end
	return Dv
end

# ---------------------------------------------------------------------------------------------------
"""
	L = ldd(FD::FlowNet)

Local drain direction in PCRaster encoding (the numeric keypad: 8 = north, 6 = east, 2 = south,
4 = west, 9/3/1/7 diagonals, 5 = pit/outlet). This is the `Ldd` map that LISFLOOD needs.
Returns a `GMTgrid` (NaN for nodata). Save it with `gmtwrite` or convert to PCRaster `.map` format.
"""
function ldd(F::FlowNet)
	ny = size(F.dem, 1)
	L = fill(NaN32, size(F.dem))
	@inbounds for k in F.order
		r = F.rcv[k]
		di = (r - 1) % ny - (k - 1) % ny			# +1 = north
		dj = (r - 1) ÷ ny - (k - 1) ÷ ny			# +1 = east
		L[k] = Float32(5 + dj + 3di)
	end
	return _hydro_grid(F, L, "LDD (PCRaster encoding)")
end

# ---------------------------------------------------------------------------------------------------
"""
	T = twi(FD::FlowNet; method=:mfd, p=1.1, minslope=0.001, progress=nothing)

Topographic Wetness Index, TWI = ln(a / tan β) (Beven & Kirkby, 1979).

- `a` is the specific catchment area: the upstream area per unit contour width, i.e. the upstream
  area from [`flowacc`](@ref) (`area=true`) divided by the cell width. In metres for geographic grids.
- `β` is the local slope, from central differences of the ORIGINAL DEM (not the filled one, whose
  flats would have zero slope).

High values mark cells that collect a lot of water and drain it slowly (valley bottoms, hollows,
foot slopes): wet soils, saturation-excess runoff, wetlands. Low values mark well-drained crests and
steep slopes. Typical range 2–20.

- `method`: flow accumulation method, see [`flowacc`](@ref). The default `:mfd` is the usual choice for
  TWI because it lets water spread over hillslopes; `:dinf` is the other common one. `:d8` is
  accepted but gives the stripy pattern D8 is known for and is not recommended here.
- `p`: MFD exponent (see `flowacc`).
- `minslope`: lower bound for tan β, so flat cells (lakes, filled pits, plains) do not get an infinite
  index. Default 0.001 (0.06°).

Returns a `GMTgrid`. References: Beven & Kirkby (1979), Hydrological Sciences Bulletin 24(1);
Sørensen, Zinko & Seibert (2006), Hydrology and Earth System Sciences 10, on the choice of method.
"""
function twi(F::FlowNet; method::Union{Symbol,String}=:mfd, p::Real=1.1, minslope::Real=0.001, progress=nothing)
	m = Symbol(method)
	A = (m == :d8) ? _hydro_acc(F, nothing, true) :
	    (m in (:mfd, :dinf)) ? _hydro_acc_multi(F, nothing, true, m, Float64(p),
	                                             (progress === nothing) ? nothing : (f, s) -> progress(0.9f, s)) :
	    error("twi: method must be :d8, :mfd or :dinf, not :$m")
	_hy_report(progress, 0.9, "Slope and wetness index")
	Z = _hydro_canon(F.G)[1]				# original DEM: the slope must not see the filled flats
	ny, nx = size(Z)
	T = fill(NaN32, ny, nx)
	tmin = Float64(minslope)
	@inbounds for k in F.order
		i = (k - 1) % ny + 1;	j = (k - 1) ÷ ny + 1
		gx = _hy_deriv(Z, i, j, 0, 1, F.dx[i])
		gy = _hy_deriv(Z, i, j, 1, 0, F.dy)
		tanb = max(sqrt(gx^2 + gy^2), tmin)
		a = A[k] / sqrt(F.dx[i] * F.dy)
		T[k] = Float32(log(a / tanb))
	end
	_hy_report(progress, 1.0, "Done")
	return _hydro_grid(F, T, "Topographic wetness index ($m)")
end

# Central difference along (di,dj) with one-sided fallback at borders and next to NaN.
@inline function _hy_deriv(Z::Matrix{Float32}, i::Int, j::Int, di::Int, dj::Int, h::Float64)
	ny, nx = size(Z)
	z0 = Float64(Z[i, j])
	ip, jp, im, jm = i + di, j + dj, i - di, j - dj
	zp = (1 <= ip <= ny && 1 <= jp <= nx) ? Float64(Z[ip, jp]) : NaN
	zm = (1 <= im <= ny && 1 <= jm <= nx) ? Float64(Z[im, jm]) : NaN
	!isnan(zp) && !isnan(zm) && return (zp - zm) / (2h)
	!isnan(zp) && return (zp - z0) / h
	!isnan(zm) && return (z0 - zm) / h
	return 0.0
end
