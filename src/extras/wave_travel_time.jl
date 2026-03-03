# This code was translated by Claude from the original in C-MEX that lieves in Mirone.

"""
    wave_travel_time(G::GMTgrid, source::Vector{<:Real}; geo::Bool=true, fill_voids::Bool=true)

Compute the tsunami travel time given a bathymetry grid and a source location.

- `G`: GMTgrid with bathymetry (z positive up, in meters). The grid should not contain NaNs.
- `source`: `[lon, lat]` of the tsunami source.
- `geo`: `true` if coordinates are geographic (degrees), `false` if Cartesian.
- `fill_voids`: fill voids left by the first wavefront expansion (default `true`).

Returns a GMTgrid with travel times in **hours** (NaN where the wave does not reach).

### Example
```julia
G = gmtread("@earth_relief_01m", R=:PT);
Gttt = wave_travel_time(G, [-11.0, 35.9])
viz(Gttt, contour=true, colorbar=true, coast=true, proj=:guess)
```
"""
function wave_travel_time(G::GMTgrid, source::Vector{<:Real}; geo::Bool=true, fill_voids::Bool=true)
	x_min, x_max, y_min, y_max = G.range[1], G.range[2], G.range[3], G.range[4]
	x_inc, y_inc = G.inc[1], G.inc[2]
	# Compute nx, ny from coordinate vectors (robust for all layouts, including transposed TRB)
	nx = length(G.x) - G.registration
	ny = length(G.y) - G.registration
	hdr = (nx=nx, ny=ny, x_min=x_min, x_max=x_max, y_min=y_min, y_max=y_max, x_inc=x_inc, y_inc=y_inc)

	# The C algorithm uses a flat row-major vector with j=1 = north.
	# G.z layout is encoded in G.layout[1:2]:
	#   "BC" = column-major, south-first (G.z[1,:]=south)
	#   "TC" = column-major, north-first (G.z[1,:]=north)
	#   "TR" = row-major, north-first (data stored transposed: z shape may be (nx,ny))
	#   "BR" = row-major, south-first (data stored transposed: z shape may be (nx,ny))
	Z  = Vector{Float32}(undef, nx * ny)
	TT = fill(Float32(1.0e6), nx * ny)
	lay = G.layout[1:2]

	# Copy grid data to Z (flat, row-major, north-first)
	if (lay == "BC" || lay == "TC")				# Column-major: G.z[j,i] is row j, col i
		flip_y = (lay == "BC")
		@inbounds for j in 1:ny, i in 1:nx
			src_row = flip_y ? (ny - j + 1) : j
			Z[(j-1)*nx + i] = G.z[src_row, i]
		end
	elseif lay == "TR"							# Row-major, north-first: already in the right order
		flip_y = false
		copyto!(Z, 1, vec(G.z), 1, nx * ny)
	else										# "BR": row-major, south-first — flip rows
		flip_y = true
		@inbounds for j in 1:ny, i in 1:nx
			Z[(j-1)*nx + i] = G.z[(ny - j) * nx + i]
		end
	end

	# Convert bathymetry to speed field
	_bat_to_speed!(Z)

	# Find source indices (1-based, in the row-major flat array convention)
	i_source = round(Int, (source[1] - x_min) / x_inc) + 1		# column index, 1-based
	j_source = round(Int, (y_max - source[2]) / y_inc) + 1		# row index, 1-based (north=1)

	(i_source < 1 || i_source > nx || j_source < 1 || j_source > ny) &&
		error("Source location is outside the grid.")

	# Pre-compute sin/cos of each latitude row (indexed by j=1..ny, j=1=north)
	sinlat = Vector{Float64}(undef, ny)
	coslat = Vector{Float64}(undef, ny)
	if geo
		@inbounds for j in 1:ny
			jg = ny - j + 1   # replicate C's row inversion
			lat = (y_min + jg * y_inc) * D2R
			sinlat[j], coslat[j] = sincos(lat)
		end
	end

	# Pre-allocate working buffers (shared across all _do_travel_time! calls)
	buf_size = 2 * (nx + ny) + 8
	bufs = (rim=Vector{Int}(undef, buf_size), rim_work=Vector{Int}(undef, buf_size),
	        rim8=Vector{Int}(undef, buf_size), rim16=Vector{Int}(undef, buf_size),
	        sinlat=sinlat, coslat=coslat)

	# Main wavefront expansion
	_do_travel_time!(Z, TT, hdr, i_source, j_source, 0.f0, 0, geo, bufs)

	if fill_voids
		# W→E sweep
		for n in 2:nx*ny
			i, j = _n_to_ij(n, nx)
			wall = (mod(i - 1, nx) == 0)    # hit left wall
			if (TT[n] == 1.0e6 && TT[n-1] != 1.0e6 && Z[n] > 0 && !wall)
				_do_travel_time!(Z, TT, hdr, i, j, TT[n-1], 10, geo, bufs)
			end
		end
		# S→N sweep (C code uses ny in wall check, not nx — replicated here for compatibility)
		for n in (nx*ny - nx):-1:1
			n2 = n + nx   # the point one row south (in j=1=north convention)
			i2, j2 = _n_to_ij(n2, nx)
			wall = (mod(i2 - 1, ny) == 0)   # replicate C's wall check: ic % ny == 0
			if (TT[n] == 1.0e6 && TT[n2] != 1.0e6 && Z[n2] > 0 && !wall)
				_do_travel_time!(Z, TT, hdr, i2, j2, TT[n2], 10, geo, bufs)
			end
		end
	end

	# Convert to hours, set unreached to NaN
	@inbounds for n in 1:nx*ny
		TT[n] = (TT[n] >= 1.0e6) ? NaN : TT[n] / 3600.0
	end

	# Build output grid — write TT (row-major, north-first) back to G.z's layout
	out_z = Array{Float32,2}(undef, size(G.z, 1), size(G.z, 2))
	if (lay == "BC" || lay == "TC")
		# Column-major output: out_z[j,i] is row j, col i
		@inbounds for j in 1:ny, i in 1:nx
			dst_row = flip_y ? (ny - j + 1) : j
			out_z[dst_row, i] = TT[(j-1)*nx + i]
		end
	elseif (lay == "TR")
		copyto!(vec(out_z), 1, TT, 1, nx * ny)
	else	# "BR"
		@inbounds for j in 1:ny, i in 1:nx
			out_z[(ny - j) * nx + i] = TT[(j-1)*nx + i]
		end
	end

	zmin = minimum(x -> isnan(x) ? Inf  : x, out_z)
	zmax = maximum(x -> isnan(x) ? -Inf : x, out_z)

	GG = GMTgrid(proj4=G.proj4, wkt=G.wkt, epsg=G.epsg, geog=G.geog,
	             range=Float64[x_min, x_max, y_min, y_max, zmin, zmax],
	             inc=Float64[x_inc, y_inc], registration=G.registration, nodata=NaN,
	             title="Tsunami Travel Time", remark="Hours from source",
	             command="wave_travel_time", x=copy(G.x), y=copy(G.y),
	             z=out_z, layout=G.layout)
	return GG
end

# --------------------------------------------------------------------------
# Internal helpers (not exported)
# --------------------------------------------------------------------------

const _EARTH_RAD = 6371008.7714   # GRS-80 sphere radius in meters
const D2R = π / 180.0

function _bat_to_speed!(Z)
	g = 9.806199203   # Moritz's 1980 IGF at 45° latitude
	@inbounds for j in eachindex(Z)
		Z[j] = (Z[j] < 0) ? sqrt(-Z[j] * g) : 0.0
	end
end

"""Linear index (1-based) → (i, j) both 1-based, row-major layout with nx columns."""
@inline function _n_to_ij(n::Int, nx::Int)
	j = div(n - 1, nx) + 1
	i = n - (j - 1) * nx
	return i, j
end

"""(i,j) 1-based → linear index (1-based)."""
@inline _ij_to_n(i::Int, j::Int, nx::Int) = (j - 1) * nx + i

"""Check if (i,j) is strictly inside the grid (not on the edge)."""
@inline _check_in(i::Int, j::Int, nx::Int, ny::Int) = (i > 1 && i < nx && j > 1 && j < ny)

"""Arc distance in meters between grid points (i0,j0) and (ic,jc). Uses pre-computed sinlat/coslat tables."""
@inline function _arc_dist(hdr, i0::Int, j0::Int, ic::Int, jc::Int, geo::Bool, bufs)
	if geo
		dlon = (ic - i0) * hdr.x_inc * D2R
		@inbounds tmp = bufs.sinlat[j0] * bufs.sinlat[jc] + bufs.coslat[j0] * bufs.coslat[jc] * cos(dlon)
		tmp = clamp(tmp, -1.0, 1.0)
		return abs(_EARTH_RAD * acos(tmp))
	else
		j0g = hdr.ny - j0 + 1
		jcg = hdr.ny - jc + 1
		dx = (ic - i0) * hdr.x_inc
		dy = (jcg - j0g) * hdr.y_inc
		return sqrt(dx * dx + dy * dy)
	end
end

"""
Find the rim points k nodes away from (i0, j0). Returns their linear indices in `rim_out`,
and the number of valid points found.
"""
function _find_rim_points!(rim_out::Vector{Int}, Z, hdr, i0::Int, j0::Int, k::Int)
	nx, ny = hdr.nx, hdr.ny
	n = 0
	ic_min = i0 - k;  ic_max = i0 + k
	jc_min = j0 - k;  jc_max = j0 + k

	all_in = _check_in(ic_min, jc_min, nx, ny) && _check_in(ic_max, jc_max, nx, ny)

	# Match C's edge traversal exactly to get the same 8k unique corner allocation:
	# Edge 1: j=jc_max (full row, includes both corners)
	@inbounds for i in ic_min:ic_max
		if all_in || _check_in(i, jc_max, nx, ny)
			idx = _ij_to_n(i, jc_max, nx)
			if Z[idx] > 0
				n += 1;  rim_out[n] = idx
			end
		end
	end
	# Edge 2: i=ic_max, j from jc_min to jc_max-1 (excludes jc_max corner, already in edge 1)
	@inbounds for j in jc_min:jc_max-1
		if all_in || _check_in(ic_max, j, nx, ny)
			idx = _ij_to_n(ic_max, j, nx)
			if Z[idx] > 0
				n += 1;  rim_out[n] = idx
			end
		end
	end
	# Edge 3: j=jc_min, i from ic_min to ic_max-1 (excludes ic_max corner, already in edge 2)
	@inbounds for i in ic_min:ic_max-1
		if all_in || _check_in(i, jc_min, nx, ny)
			idx = _ij_to_n(i, jc_min, nx)
			if Z[idx] > 0
				n += 1;  rim_out[n] = idx
			end
		end
	end
	# Edge 4: i=ic_min, j from jc_min+1 to jc_max-1 (excludes both corners)
	@inbounds for j in jc_min+1:jc_max-1
		if all_in || _check_in(ic_min, j, nx, ny)
			idx = _ij_to_n(ic_min, j, nx)
			if Z[idx] > 0
				n += 1;  rim_out[n] = idx
			end
		end
	end
	return n
end

"""Set travel time at one rim neighbour, keeping the minimum."""
@inline function _set_travel_time!(Z, TT, hdr, i0::Int, j0::Int, rim_idx::Int, geo::Bool, bufs)
	ic, jc = _n_to_ij(rim_idx, hdr.nx)
	@inbounds if Z[rim_idx] > 0
		n0 = _ij_to_n(i0, j0, hdr.nx)
		TT[n0] == 1.0e6 && return
		v_mean = (Z[rim_idx] + Z[n0]) / 2
		ds = _arc_dist(hdr, i0, j0, ic, jc, geo, bufs)
		dt = ds / v_mean
		TT[rim_idx] = min(TT[n0] + dt, TT[rim_idx])
	end
end

"""Main wavefront expansion loop."""
function _do_travel_time!(Z, TT, hdr, i_source::Int, j_source::Int, t0, max_range::Int, geo::Bool, bufs)
	nx, ny = hdr.nx, hdr.ny
	i0, j0 = i_source, j_source

	TT[_ij_to_n(i0, j0, nx)] = t0

	# Maximum number of rims to expand
	i_e = nx - i0
	i_w = i0 - 1
	j_n = j0
	j_s = ny - j0

	nl_max = max(i_e, i_w, j_n, j_s)
	(t0 > 0.01) && (nl_max = max_range)

	rim, rim_work, rim8, rim16 = bufs.rim, bufs.rim_work, bufs.rim8, bufs.rim16

	first = true
	for k in 1:nl_max-1
		np_rim = _find_rim_points!(rim_work, Z, hdr, i0, j0, k)

		# Copy to rim (stable copy for iteration)
		@inbounds for l in 1:np_rim
			rim[l] = rim_work[l]
		end

		if first
			for l in 1:np_rim
				_set_travel_time!(Z, TT, hdr, i0, j0, rim_work[l], geo, bufs)
			end
		end
		first = false   # C sets first=FALSE unconditionally, outside the if block

		# Circulate the rim-k points
		@inbounds for l in 1:np_rim
			ci, cj = _n_to_ij(rim[l], nx)
			# Skip edge points
			(ci <= 1 || ci >= nx || cj <= 1 || cj >= ny) && continue

			np8 = _find_rim_points!(rim_work, Z, hdr, ci, cj, 1)
			@inbounds for m in 1:np8
				rim8[m] = rim_work[m]
			end
			np16 = _find_rim_points!(rim_work, Z, hdr, ci, cj, 2)
			@inbounds for m in 1:np16
				rim16[m] = rim_work[m]
			end

			for m in 1:np8
				_set_travel_time!(Z, TT, hdr, ci, cj, rim8[m], geo, bufs)
			end
			for m in 1:np16
				_set_travel_time!(Z, TT, hdr, ci, cj, rim16[m], geo, bufs)
			end
		end

		i0, j0 = i_source, j_source   # reset to true origin
	end
end
