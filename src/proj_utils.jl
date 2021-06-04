# Functions in this file have derived from some in the PROJ4.jl pacakge https://github.com/JuliaGeo/Proj4.jl
# so part of the credit goes also for the authors of that package but the main function, "geod" was highly
# modified and does a lot more than the proj4 'geod' model.

abstract type _geodesic end
mutable struct null_geodesic <: _geodesic end

struct PJ_INFO
	major::Cint
	minor::Cint
	patch::Cint
	release::Cstring
	version::Cstring
	searchpath::Cstring
	paths::Ptr{Cstring}
	path_count::Csize_t
end

mutable struct geod_geodesic <: _geodesic
	a::Cdouble
	f::Cdouble
	f1::Cdouble
	e2::Cdouble
	ep2::Cdouble
	n::Cdouble
	b::Cdouble
	c2::Cdouble
	etol2::Cdouble
	A3x::NTuple{6, Cdouble}
	C3x::NTuple{15,Cdouble}
	C4x::NTuple{21,Cdouble}
	geod_geodesic() = new()
end

# -------------------------------------------------------------------------------------------------
"""
    geod(lonlat::Vector{<:Real}, azim, distance; proj::String="", s_srs::String="", epsg::Integer=0, dataset=false, unit=:m)

Solve the direct geodesic problem.

Args:

- `lonlat`:   - longitude, latitude (degrees) ∈ [-90, 90]
- `azimuth`:  - azimuth (degrees) ∈ [-540, 540)
- `distance`: - distance to move from (lat,lon); can be negative, Default is meters but see `unit`
- `proj` or `s_srs`:  - the given projection whose ellipsoid we move along. Can be a proj4 string or an WKT
- `epsg`:     - Alternative way of specifying the projection [Default is WGS84]
- `dataset`:  - If true returns a GMTdataset instead of matrix
- `unit`:     - If `distance` is not in meters use one of `unit=:km`, or `unit=:Nautical` or `unit=:Miles`

The `distance` argument can be a scalar, a Vector, a Vector{Vector} or an AbstractRange. The `azimuth` can be
a scalar or a Vector. 

When `azimuth` is a Vector we always return a GMTdataset with the multiple lines. Use this together with a
non-scalar `distance` to get lines with multiple points along the line. The number of points along line does
not even need to be the same. For data, give the `distance` as a Vector{Vector} where each element of `distance`
is a vector with the distances of the points along a line. In this case the number of `distance` elements
must be equal to the number of `azimuth`. 

### Returns
- dest - destination after moving for [distance] metres in [azimuth] direction.
- azi  - forward azimuth (degrees) at destination [dest].

## Example: Compute two lines starting at (0,0) with lengths 111100 & 50000, heading at 15 and 45 degrees.

    geod([0., 0], [15., 45], [[0, 10000, 50000, 111100.], [0., 50000]])[1]
"""
function geod(lonlat::Vector{<:Real}, azim, distance; proj::String="", s_srs::String="", epsg::Integer=0, dataset=false, unit=:m)
	f = dist_unit_factor(unit)
	if isa(distance, AbstractRange)  _dist = collect(Float64, distance) .* f
	else                             _dist = distance .* f
	end

	proj_string, projPJ_ptr, isgeog = helper_geod(proj, s_srs, epsg)
	dest, azi = helper_gdirect(projPJ_ptr, lonlat, azim, _dist, proj_string, isgeog, dataset)
	proj_destroy(projPJ_ptr)
	return dest, azi
end

function dist_unit_factor(unit=:m)
	# Returns the factor that converts a length to meters, or 1 if unit is unknown
	f = 1.0
	if (unit != :m)
		_u = lowercase(string(unit))		# Parse the units arg
		f = (_u[1] == 'k') ? 1000. : ((_u[1] == 'n') ? 1852.0 : (startswith(_u, "mi") ? 1609.344 : 1.0))
	end
	(unit != :m && f == 1.0) && @warn("Unknown unit ($_u). Ignoring it")
	f
end

# -------------------------------------------------------------------------------------------------
"""
    invgeod(lonlat1::Vector{<:Real}, lonlat2::Vector{<:Real}; proj::String="", s_srs::String="", epsg::Integer=0)

Solve the inverse geodesic problem.

Args:

- `lonlat1`:  - coordinates of point 1 in the given projection
- `lonlat2`:  - coordinates of point 2 in the given projection
- `proj` or `s_srs`:  - the given projection whose ellipsoid we move along. Can be a proj4 string or an WKT
- `epsg`:     - Alternative way of specifying the projection [Default is WGS84]

### Returns
dist - distance between point 1 and point 2 (meters).
azi1 - azimuth at point 1 (degrees) ∈ [-180, 180)
azi2 - (forward) azimuth at point 2 (degrees) ∈ [-180, 180)

Remarks:

If either point is at a pole, the azimuth is defined by keeping the longitude fixed,
writing lat = 90 +/- eps, and taking the limit as eps -> 0+.
"""
invgeod(lonlat1::Vector{<:Real}, lonlat2::Vector{<:Real}; proj::String="", s_srs::String="", epsg::Integer=0) =
	invgeod([lonlat1[1] lonlat1[2]], [lonlat2[1] lonlat2[2]]; proj=proj, s_srs=s_srs, epsg=epsg)
function invgeod(lonlat1::Matrix{<:Real}, lonlat2::Matrix{<:Real}; proj::String="", s_srs::String="", epsg::Integer=0)
	@assert (size(lonlat1) == size(lonlat2) || size(lonlat2,1) == 1) "Both matrices must have same size or second have one row"
	proj_string, projPJ_ptr, isgeog = helper_geod(proj, s_srs, epsg)
	(!isgeog) && (lonlat1 = xy2lonlat(lonlat1, proj_string);	lonlat2 = xy2lonlat(lonlat2, proj_string))	# Convert to geogd first
	d   = Vector{Float64}(undef, size(lonlat1,1))
	az1 = Vector{Float64}(undef, size(lonlat1,1))
	az2 = Vector{Float64}(undef, size(lonlat1,1))
	dist, azi1, azi2 = Ref{Cdouble}(), Ref{Cdouble}(), Ref{Cdouble}()
	for k = 1:size(lonlat1,1)
		kk = (size(lonlat2,1) == 1) ? 1 : k			# To allow the "all against one" case
		ccall((:geod_inverse, libproj), Cvoid, (Ptr{Cvoid},Cdouble,Cdouble,Cdouble, Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble}),
			  pointer_from_objref(get_ellipsoid(projPJ_ptr)), lonlat1[k,2], lonlat1[k,1], lonlat2[kk,2], lonlat2[kk,1], dist, azi1, azi2)
		d[k], az1[k], az2[k] = dist[], azi1[], azi2[]
	end
	proj_destroy(projPJ_ptr)
	return d, az1, az2
end

# -------------------------------------------------------------------------------------------------
"""
    circgeo(lonlat::Vector{<:Real}; radius=X, proj::String="", s_srs::String="", epsg::Integer=0, dataset=false, unit=:m, np=120)
or

    circgeo(lon, lat; radius=X, proj::String="", s_srs::String="", epsg::Integer=0, dataset=false, unit=:m, np=120)

Args:

- `lonlat`:   - longitude, latitude (degrees)
- `radius`:   - The circle radius in meters (but see `unit`)
- `proj` or `s_srs`:  - the given projection whose ellipsoid we move along. Can be a proj4 string or an WKT
- `epsg`:     - Alternative way of specifying the projection [Default is WGS84]
- `dataset`:  - If true returns a GMTdataset instead of matrix
- `unit`:     - If `radius` is not in meters use one of `unit=:km`, or `unit=:Nautical` or `unit=:Miles`
- `np`:       - Number of points into which the circle is descretized (Default = 120)

### Returns
- circ - A Mx2 matrix or GMTdataset with the circle coordinates

## Example: Compute circle about the (0,0) point with a radius of 50 km

    c = circgeo([0.,0], radius=50, unit=:k)
"""
circgeo(lon::Real, lat::Real; radius::Real=0., proj::String="", s_srs::String="", epsg::Integer=0, dataset::Bool=false, unit=:m, np::Int=120) = circgeo([lon, lat]; radius=radius, proj=proj, s_srs=s_srs, epsg=epsg, dataset=dataset, unit=unit, np=np)
function circgeo(lonlat::Vector{<:Real}; radius::Real=0., proj::String="", s_srs::String="", epsg::Integer=0, dataset::Bool=false, unit=:m, np::Int=120)
	(radius == 0) && error("Must provide circle Radius. Obvious, not?")
	azim = collect(Float64, linspace(0, 360, np))
	geod(lonlat, azim, radius; proj=proj, s_srs=s_srs, epsg=epsg, dataset=dataset, unit=unit)[1]
end

# -------------------------------------------------------------------------------------------------
"""
    buffergeo(D::Vector{<:GMTdataset}; width=0, unit=:m, np=120, flatstart=false, flatend=false, epsg::Integer=0, tol=0.01)
or

    buffergeo(D::Vector{<:GMTdataset}; width=0, unit=:m, np=120, flatstart=false, flatend=false, epsg::Integer=0, tol=0.01)
or

    buffergeo(line::Matrix; width=0, unit=:m, np=120, flatstart=false, flatend=false, proj::String="", epsg::Integer=0, tol=0.01)
or

    buffergeo(fname::String; width=0, unit=:m, np=120, flatstart=false, flatend=false, proj::String="", epsg::Integer=0, tol=0.01)

Computes a buffer arround a poly-line. This calculation is performed on a ellipsoidal Earth (or other planet)
using the GeographicLib (via PROJ4) so it should be very accurate.

### Parameters
- `D` | `line` | fname: - the geometry. This can either be a GMTdataset (or vector of it), a Mx2 matrix or the name
                          of file that can be read as a GMTdataset by `gmtread()`
- `width`:  - the buffer width to be applied. Expressed meters (the default), km or Miles (see `unit`)
- `unit`:   - If `width` is not in meters use one of `unit=:km`, or `unit=:Nautical` or `unit=:Miles`
- `np`:     - Number of points into which circles are descretized (Default = 120)
- `flatstart` - When computing buffers arround poly-lines make the start *flat* (no half-circle)
- `flatend`   - Same as `flatstart` but for the buffer end
- `proj`  - If line data is in Cartesians but with a known projection pass in a PROJ4 string to allow computing the buffer
- `epsg`  - Same as `proj` but using an EPSG code
- `tol`   - At the end simplify the buffer line with a Douglas-Peucker procedure. Use TOL=0 to NOT do the line
            simplification, or use any other value thean the default 0.01.

### Returns
A GMT dataset or a vector of it (when input is Vector{GMTdataset})

## Example: Compute a buffer with 50000 width

    D = buffergeo([0 0; 10 10; 15 20], width=50000);
"""
buffergeo(fname::String; width=0, unit=:m, np=120, flatstart=false, flatend=false, epsg::Integer=0, tol=0.01) =
	buffergeo(gmtread(fname); width=width, unit=unit, np=np, flatstart=flatstart, flatend=flatend, epsg=epsg, tol=tol)
buffergeo(D::GMTdataset; width=0, unit=:m, np=120, flatstart=false, flatend=false, epsg::Integer=0, tol=0.01) =
	buffergeo(D.data; width=width, unit=unit, np=np, flatstart=flatstart, flatend=flatend, proj=D.proj4, epsg=epsg, tol=tol)[1]
function buffergeo(D::Vector{<:GMTdataset}; width=0, unit=:m, np=120, flatstart=false, flatend=false, epsg::Integer=0, tol=0.01)
	_D = Vector{GMTdataset}(undef, length(D))
	for k = 1:length(D)
		_D[k], = buffergeo(D[k].data; width=width, unit=unit, np=np, flatstart=flatstart, flatend=flatend,
		                   proj=D[1].proj4, epsg=epsg, tol=tol)
	end
	return (length(_D) == 1) ? _D[1] : _D		# Drop the damn Vector singletons
end
function buffergeo(line::Matrix{<:Real}; width=0, unit=:m, np=120, flatstart=false, flatend=false, proj::String="", epsg::Integer=0, tol=0.01)
	# This function can still be optimized if one manage to reduce the number of times that proj_create() is called
	# and a more clever choice of which points to compute on the circle. Points along the segment axis are ofc nover needed
	(width == 0) && error("Must provide the buffer width. Obvious, not?")
	dist, azim, = invgeod(line[1:end-1, :], line[2:end, :], proj=proj, epsg=epsg)	# Compute distances and azimuths between the polyline vertices
	#(line[1, 1:2] == line[end, 1:2]) && (flatstart = flatend = false)		# Polygons can't have start/end flat edges
	width *= dist_unit_factor(unit)
	n_seg = length(azim)
	for n = 1:n_seg
		seg = [geod(line[n,:], azim[n], 0:width/4:dist[n], proj=proj, epsg=epsg)[1]; line[n+1:n+1,:]]
		n_vert = size(seg,1)
		for k = 2:n_vert
			if (k == 2)
				c0 = circgeo(seg[1,:], radius=width, np=np, proj=proj, epsg=epsg);	trim_dateline!(c0, seg[1,1])
				c  = circgeo(seg[2,:], radius=width, np=np, proj=proj, epsg=epsg);	trim_dateline!(c , seg[2,1])
				global _D = polyunion(c0, c)
				continue
			end
			c = circgeo(seg[k,:], radius=width, np=np, proj=proj, epsg=epsg)
			trim_dateline!(c, seg[k,1])
			_D = polyunion(_D, c)
		end
		#linearize_buff_seg!(_D, seg)		# Attempt to see what a filterring by segment does ... 3x slower
		if (n == 1)  global D = _D
		else         D = polyunion(_D, D)
		end
	end

	# At this point we still have a "wavy" buffer resulting from the union of the circles. Ideally we should
	# be able to use GMT's mapproject to find only the points that are at the exact 'width' distance from the
	# line, but at this moment there seems to be an issue in GMT and distances are shorter. However with can
	# do some cheap statistics to get read of the more inner points a get an almost perfec buffer.
	Ddist2line = mapproject(D, L=(line=line, unit=:e))		# Find the distance from buffer points to input line
	d_mean = mean(view(Ddist2line[1].data, :, 3))
	ind = view(Ddist2line[1].data, :, 3) .> d_mean * 1.01
	D[1].data = D[1].data[ind, :]			# Remove all points that are less 1% above the mean

	(proj == "" && epsg == 0) && (D[1].proj4 == "+proj=longlat +datum=WGS84 +no_defs")
	(proj != "") && (D[1].proj4 = proj)
	(epsg != 0) && (D[1].proj4 = toPROJ4(importEPSG(epsg)))
	return (tol > 0) ? simplify(D, tol) : D		# If TOL > 0 do a DP simplify on final buffer
end

function trim_dateline!(mat, lon0)
	# When the the mat polygon (a circle normally) crosses the dateline, trim it from the standpoint of its centroid
	mi, ma = extrema(view(mat,:,1))
	if ((ma - mi) > 180)		# Polygon crosses the dateline
		if (lon0 > 0)  mat[view(mat,:,1) .< 0, 1] .= 180.  # and centroid is at the 11:xxx side
		else           mat[view(mat,:,1) .> 0, 1] .= -180.
		end
	end
end

#=
function linearize_buff_seg!(D::Vector{<:GMTdataset}, seg::Matrix{Float64})
	# This a test/temp function that plays more fair with mapproject -L in the sense that we use the segment
	# already interpolated along the geodetic and since the line is now segmented the difference between
	# small circles (mapproject) and great circle arcs should be much smaller. However, mapproject -L still
	# gives distances that in average ar in error off > 1-2 km
	Ddist2line = mapproject(D, L=(line=seg, unit=:e))		# Find the distance from buffer points to input line
	d_mean = mean(view(Ddist2line[1].data, :, 3))
	ind = view(Ddist2line[1].data, :, 3) .>= d_mean * 1.0
	ind[1], ind[end] = true, true			# Ensure first and last are not removed
	D[1].data = D[1].data[ind, :]			# Remove all points that are less 1% above the mean
	#@show(d_mean, size(_D[1]))
end
=#

#=
function buffergeo_(line::Matrix{<:Real}; width=0, unit=:m, np=120, flatstart=false, flatend=false, proj::String="", epsg::Integer=0)
	(width == 0) && error("Must provide the buffer width. Obvious, not?")
	(line[1, 1:2] == line[end, 1:2]) && (flatstart = flatend = false)		# Polygons can't have start/end flat edges
	dist, azim, = invgeod(line[1:end-1, :], line[2:end, :])		# Compute distances and azimuths between the polyline vertices
	width *= dist_unit_factor(unit)
	D = GMTdataset()
	n_seg = length(azim)
	for n = 1:n_seg
		#t1 = geod([line[n,  1], line[n,  2]], [azim[n]-90, azim[n]+90], width)[1]
		#t2 = geod([line[n+1,1], line[n+1,2]], [azim[n]+90, azim[n]-90], width)[1]
		#rec = [t1; t2; t1[1,1] t1[1,2]]		# Rectangle arround this line segment
		rec = buff_segment_tube([line[n,1], line[n,2]], [line[n+1,1], line[n+1,2]], dist[n], azim[n], width, proj, epsg)
		(n_seg == 1 && flatstart && flatend) && return mat2ds(rec, proj=proj)		# Kindof degenerate case. Just a rectangle

		c = circgeo([line[n+1,1], line[n+1,2]], radius=width, np=np)
		if (n == 1)
			if (!flatstart)
				c0 = circgeo([line[1,1], line[1,2]], radius=width, np=np)
				D  = polyunion(polyunion(rec, c0), c)
			else
				c = circgeo([line[2,1], line[2,2]], radius=width, np=np)
				D = polyunion(rec, c)
			end
		elseif (n == n_seg && flatend)		# Last segment
			D = polyunion(D, rec)			# previous buffer + last rect
		else
			D = polyunion(D, polyunion(rec, c))	# Merge This segment + end circle `with previously build buffer
		end
	end
	return D
end

function buff_segment_tube(p1::Vector{<:Real}, p2::Vector{<:Real}, dist, azim, width, proj, epsg)
	# Compute a geodesic tube along the line segment from p1 to p2. Descritize the tube at 2width distance
	# p1 & p2 are the segment vertices; 'dist' -> seg distance; 'azim' -> seg azimuth; 'width' -> buffer width
	seg = [geod(p1, azim, 0:2width:dist, proj=proj, epsg=epsg)[1]; [p2[1] p2[2]]]	# Discretize segment at 2width steps
	n_vert = size(seg,1)
	tube = Array{Float64,2}(undef, 2*n_vert+1, 2)
	for k = 1:n_vert
		t = geod(seg[k,:], [azim-90, azim+90], width, proj=proj, epsg=epsg)[1]	# Returns a 2x2 matrix ([x1 y1; x2 y2])
		tube[k,:] = t[1,:]
		tube[2n_vert-k+1,:] = t[2,:]
	end
	tube[end,:] = tube[1,:]
	tube
end
=#

# -------------------------------------------------------------------------------------------------
function helper_gdirect(projPJ_ptr, lonlat, azim, dist, proj_string, isgeog, dataset)
	lonlat = Float64.(lonlat)
	(!isgeog) && (lonlat = xy2lonlat(lonlat, proj_string))		# Need to convert to geogd first
	ggd = get_ellipsoid(projPJ_ptr)
	
	(isvector(azim) && isa(dist, Real)) && (dist = [dist,])		# multi-points. Just make 'dist' a vector to reuse a case below 

	if (isa(azim, Real) && isa(dist, Real))						# One line only with one end-point
		dest, azi = _geod_direct!(ggd, copy(lonlat), azim, dist)
		(!isgeog) && (dest = lonlat2xy(dest, proj_string))
		(dataset) && (dest = helper_gdirect_SRS(dest, proj_string, wkbPoint))
	elseif (isa(azim, Real) && isvector(dist))			# One line only with several points along it
		dest, azi = Array{Float64}(undef, length(dist), 2), Vector{Float64}(undef, length(dist))
		for k = 1:length(dist)
			d, azi[k] = _geod_direct!(ggd, copy(lonlat), azim, dist[k])
			dest[k, :] = (isgeog) ? d : lonlat2xy(d, proj_string)
		end
		(dataset) && (dest = helper_gdirect_SRS([dest azi], proj_string, wkbLineString))	# Return a GMTdataset
	elseif (isvector(azim) && length(dist) == 1)		# A circle (dist has became a vector in 4rth line)
		dest = Array{Float64}(undef, length(azim), 2)
		for np = 1:length(azim)
			d = _geod_direct!(ggd, copy(lonlat), azim[np], dist[1])[1]
			dest[np, 1:2] = (isgeog) ? d : lonlat2xy(d, proj_string)
		end
		(dataset) &&		# Return a GMTdataset
			(dest = GMTdataset(dest, Vector{String}(), "", Vector{String}(), startswith(proj_string, "+proj") ? proj_string : "", "", wkbPolygon))
		azi = nothing
	elseif (isvector(azim) && isvector(dist))			# multi-lines with variable length and/or number of points
		n_lines = length(azim)							# Number of lines
		(!isa(dist, Vector)) && (dist = vec(dist))
		(!isa(dist, Vector) && !isa(dist, Vector{<:Vector})) && error("The 'distances' input MUST be a Vector or a Vector{Vector}")
		if (!isa(dist, Vector{<:Vector}))				# If not, make it a Vector{Vector} to use the same algo below
			isa(dist, Matrix) && (dist = vec(dist))		# Because we accepted also 1-row or 1-col matrices
			Vdist = Vector{Vector{Float64}}(undef, n_lines)
			[Vdist[k] = dist for k = 1:n_lines]
		else
			(length(dist) != n_lines) && (proj_destroy(projPJ_ptr);error("Number of distance vectors MUST be equal to number of azimuths"))
			Vdist = dist
		end
		D = Vector{GMTdataset}(undef, n_lines)
		for nl = 1:n_lines
			n_pts = length(Vdist[nl])					# Number of points in this line
			dest = Array{Float64}(undef, n_pts, 3)		# Azimuth goes into the D too
			for np = 1:n_pts
				d, azi = _geod_direct!(ggd, copy(lonlat), azim[nl], Vdist[nl][np])
				dest[np, 1:2] = (isgeog) ? d : lonlat2xy(d, proj_string)
				dest[np, 3] = azi		# Fck language that makes it a pain to try anything vectorized 
			end
			D[nl] = GMTdataset(dest, Vector{String}(), "", Vector{String}(), "", "", wkbLineString)
			helper_gdirect_SRS(dest, proj_string, wkbLineString, D[nl])	# Just assign the SRS
		end
		return D, nothing		# Here both the point coordinates and the azim are in the GMTdataset
	else
		error("'azimuth' MUST be either a scalar or a 1-dim array, and 'distance' may also be a Vector{Vector}")
	end
	return dest, azi
end

# -------------------------------------------------------------------------------------------------
function helper_gdirect_SRS(mat, proj_string::String, geom, D=GMTdataset())
	# Convert the output of geod_direct into a GMTdataset and, if possible, assign it a SRS
	# If a 'D' is sent in, we only (eventually) assign it an SRS
	isempty(D) && (D = GMTdataset([mat[1] mat[2]], Vector{String}(), "", Vector{String}(), "", "", geom))
	(startswith(proj_string, "+proj")) && (D.proj4 = proj_string)
	D
end

# -------------------------------------------------------------------------------------------------
function _geod_direct!(geod::geod_geodesic, lonlat::Vector{Float64}, azim, distance)
	p = pointer(lonlat)
	azi = Ref{Cdouble}()		# the (forward) azimuth at the destination
	ccall((:geod_direct, libproj), Cvoid, (Ptr{Cvoid},Cdouble,Cdouble,Cdouble,Cdouble,Ptr{Cdouble},Ptr{Cdouble}, Ptr{Cdouble}),
		  pointer_from_objref(geod), lonlat[2], lonlat[1], azim, distance, p+sizeof(Cdouble), p, azi)
	lonlat, azi[]
end

# -------------------------------------------------------------------------------------------------
function helper_geod(proj::String, s_srs::String, epsg::Integer)::Tuple{String, Ptr{Nothing}, Bool}
	# 'proj' and 's_srs' are synonyms.
	# Return the projection string ans also if the projection is geogs.
	if     (proj  != "")  prj_string = proj
	elseif (s_srs != "")  prj_string = s_srs
	elseif (epsg > 0)     prj_string = toPROJ4(importEPSG(epsg))
	else                  prj_string = "+proj=longlat +datum=WGS84 +no_defs"
	end
	(startswith(prj_string, "GEOGC")) && (prj_string = toPROJ4(importWKT(prj_string)))
	prj_string, proj_create(prj_string), (startswith(prj_string, "+proj=longl") || startswith(prj_string, "+proj=latl") || epsg == 4326)
end

# -------------------------------------------------------------------------------------------------
function geod_geodesic(a::Cdouble, f::Cdouble)::geod_geodesic
	geod = geod_geodesic()
	ccall((:geod_init, libproj), Cvoid, (Ptr{Cvoid}, Cdouble, Cdouble), pointer_from_objref(geod), a, f)
	geod
end

# -------------------------------------------------------------------------------------------------
function get_ellipsoid(projPJ_ptr::Ptr{Cvoid})::geod_geodesic
	a, ecc2 = pj_get_spheroid_defn(projPJ_ptr)
	geod_geodesic(a, 1-sqrt(1-ecc2))
end

# -------------------------------------------------------------------------------------------------
function proj_create(proj_string::String, ctx=C_NULL)
	# Returns an Object that must be unreferenced with proj_destroy()
	# THIS GUY IS VERY EXPENSIVE. TRY TO MINIMIZE ITS USAGE.
	projPJ_ptr = ccall((:proj_create, libproj), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring), ctx, proj_string)
	(projPJ_ptr == C_NULL) && error("Could not parse projection: \"$proj_string\"")
	projPJ_ptr
end

proj_create_crs_to_crs(s_crs, t_crs, area, ctx=C_NULL) =
	ccall((:proj_create_crs_to_crs, libproj), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring, Cstring, Ptr{Cvoid}), ctx, s_crs, t_crs, area)

# -------------------------------------------------------------------------------------------------
function proj_destroy(projPJ_ptr::Ptr{Cvoid})	# Free C datastructure associated with a projection.
	@assert projPJ_ptr != C_NULL
	ccall((:proj_destroy, libproj), Ptr{Cvoid}, (Ptr{Cvoid},), projPJ_ptr)
end

# -------------------------------------------------------------------------------------------------
function pj_get_spheroid_defn(proj_ptr::Ptr{Cvoid})
	a = Ref{Cdouble}()		# major_axis
	ecc2 = Ref{Cdouble}()	# eccentricity squared
	ccall((:pj_get_spheroid_defn, libproj), Cvoid, (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}), proj_ptr, a, ecc2)
	a[], ecc2[]
end

# -------------------------------------------------------------------------------------------------
function proj_info()
	pji = ccall((:proj_info, libproj), PJ_INFO, ())
	println(unsafe_string(pji.release), "\n", "Located at: ", unsafe_string(pji.searchpath))
end

#=
function _transform!(src_ptr::Ptr{Cvoid}, dest_ptr::Ptr{Cvoid}, point_count::Integer, point_stride::Integer,
                     x::Ptr{Cdouble}, y::Ptr{Cdouble}, z::Ptr{Cdouble})
	@assert src_ptr != C_NULL && dest_ptr != C_NULL
	err = ccall((:pj_transform, libproj), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Clong, Cint, Ptr{Cdouble}, Ptr{Cdouble},
                Ptr{Cdouble}), src_ptr, dest_ptr, point_count, point_stride, x, y, z)
	err != 0 && error("transform error: $(_strerrno(err))")
end

_transform!(s_ptr::Ptr{Cvoid}, t_ptr::Ptr{Cvoid}, pos::Vector{Cdouble}) = _transform!(s_ptr, t_ptr, reshape(pos, 1, length(pos)))
function _transform!(s_ptr::Ptr{Cvoid}, t_ptr::Ptr{Cvoid}, position::Array{Cdouble,2})
	@assert s_ptr != C_NULL && t_ptr != C_NULL
	npoints, ndim = size(position)
	@assert ndim >= 2

	x = pointer(position)
	y = x + sizeof(Cdouble)*npoints
	z = (ndim == 2) ? Ptr{Cdouble}(C_NULL) : x + 2*sizeof(Cdouble)*npoints

	_transform!(s_ptr, t_ptr, npoints, 1, x, y, z)
	position
end

mutable struct Projection
    #ctx::Context   # Projection context object
    rep::Ptr{Cvoid} # Pointer to internal projPJ struct
    geod::_geodesic
end

function Projection(proj_ptr::Ptr{Cvoid})
    proj = Projection(proj_ptr, null_geodesic())
    finalizer(freeProjection, proj)
    proj
end

Projection(proj_string::String) = Projection(proj_create(proj_string))
function freeProjection(proj::Projection)
    proj_destroy(proj.rep)
    proj.rep = C_NULL
end
=#

function is_latlong(proj_ptr::Ptr{Cvoid})
	@assert proj_ptr != C_NULL
	ccall((:pj_is_latlong, libproj), Cint, (Ptr{Cvoid},), proj_ptr) != 0
end