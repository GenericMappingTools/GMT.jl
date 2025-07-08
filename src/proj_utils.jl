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

struct PJ_ELLPS
	id::Cstring
	major::Cstring
	ell::Cstring
	name::Cstring
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
    dest, azim = geod(lonlat, azim, distance; proj::String="", s_srs::String="", epsg::Integer=0, dataset=false, unit=:m)

Solve the direct geodesic problem.

Args:

- `lonlat`:   - longitude, latitude (degrees). This can be a vector or a matrix with one row only.
- `azimuth`:  - azimuth (degrees) ∈ [-540, 540)
- `distance`: - distance to move from (lat,lon); can be vector and can be negative, Default is meters but see `unit`
- `proj` or `s_srs`:  - the given projection whose ellipsoid we move along. Can be a proj4 string or an WKT
- `epsg`:     - Alternative way of specifying the projection [Default is WGS84]
- `dataset`:  - If true returns a GMTdataset instead of matrix
- `unit`:     - If `distance` is not in meters use one of `unit=:km`, or `unit=:Nautical` or `unit=:Miles`

The `distance` argument can be a scalar, a Vector, a Vector{Vector} or an AbstractRange. The `azimuth` can be
a scalar or a Vector. 

When `azimuth` is a Vector we always return a GMTdataset with the multiple lines. Use this together with a
non-scalar `distance` to get lines with multiple points along the line. The number of points along line does
not need to be the same. For data, give the `distance` as a Vector{Vector} where each element of `distance`
is a vector with the distances of the points along a line. In this case the number of `distance` elements
must be equal to the number of `azimuth`. 

### Returns
- dest - destination after moving for [distance] metres in [azimuth] direction.
- azi  - forward azimuth (degrees) at destination [dest].

## Example: Compute two lines starting at (0,0) with lengths 111100 & 50000, heading at 15 and 45 degrees.

    dest, = geod([0., 0], [15., 45], [[0, 10000, 50000, 111100.], [0., 50000]])[1]
"""
geod(lonlat::Vector{<:Real}, azim, distance; proj::String="", s_srs::String="", epsg::Integer=0,
     dataset=false, unit=:m, backward::Bool=false) =
	geod([lonlat[1] lonlat[2]], azim, distance; proj=proj, s_srs=s_srs, epsg=epsg, dataset=dataset,
	     unit=unit, backward=backward)
function geod(lonlat::Matrix{<:Real}, azim, distance; proj::String="", s_srs::String="", epsg::Integer=0,
	          dataset=false, unit=:m, backward::Bool=false)
	f = unit_factor(unit)
	_dist = isa(distance, AbstractRange) ? collect(Float64, distance) .* f : distance .* f

	proj_string, projPJ_ptr, isgeog = helper_geod(proj, s_srs, epsg)
	dest, azi = helper_gdirect(projPJ_ptr, lonlat, azim, _dist, proj_string, isgeog, dataset)
	proj_destroy(projPJ_ptr)
	if (isa(dest, GDtype))
		set_dsBB!(dest)				# Compute and set the global BoundingBox for this dataset
		isa(dest, GMTdataset) ? dest.colnames = ["Lon", "Lat", "Azim"] : [dest[k].colnames = ["Lon", "Lat", "Azim"] for k in eachindex(dest)]
	end
	if (backward)
		if (isa(azi, Real))
			azi += 180;		(azi > 180) && (azi -= 360)
		else
			azi .+= 180
			for k = 1:lastindex(azi)
				(azi[k] > 180) && (azi[k] -= 360)
			end
		end
		isa(dest, GMTdataset) && (dest[:,3] = azi)
	end
	return dest, azi
end

function unit_factor(unit=:m)
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
    dist, az1, az2 = invgeod(lonlat1::Vector{<:Real}, lonlat2::Vector{<:Real}; proj::String="",
                             s_srs::String="", epsg::Integer=0, backward=false)

Solve the inverse geodesic problem.

Args:

- `lonlat1`:  - coordinates of point 1 in the given projection (or a matrix with several points).
- `lonlat2`:  - coordinates of point 2 in the given projection (or a matrix with same size as `lonlat1`).
- `proj` or `s_srs`:  - the given projection whose ellipsoid we move along. Can be a proj4 string or an WKT.
- `epsg`:     - Alternative way of specifying the projection [Default is WGS84].
- `backward`: - If `true`, return backard azimuths.

### Returns
dist - A scalar with the distance between point 1 and point 2 (meters). Or a vector when lonlat1|2
       have more than one pair of points. 

az1 - azimuth at point 1 (degrees) ∈ [-180, 180)

az2 - (forward) azimuth at point 2 (degrees) ∈ [-180, 180)

Remarks:

If either point is at a pole, the azimuth is defined by keeping the longitude fixed,
writing lat = 90 +/- eps, and taking the limit as eps -> 0+.
"""
invgeod(lonlat1::Vector{<:Real}, lonlat2::Vector{<:Real}; proj::String="", s_srs::String="",
        epsg::Integer=0, backward::Bool=false) =
	invgeod([lonlat1[1] lonlat1[2]], [lonlat2[1] lonlat2[2]]; proj=proj, s_srs=s_srs, epsg=epsg, backward=backward)
function invgeod(lonlat1::Matrix{<:Real}, lonlat2::Matrix{<:Real}; proj::String="", s_srs::String="",
	             epsg::Integer=0, backward::Bool=false)
	@assert (size(lonlat1) == size(lonlat2) || size(lonlat2,1) == 1) "Both matrices must have same size or second have one row"
	proj_string, projPJ_ptr, isgeog = helper_geod(proj, s_srs, epsg)
	(!isgeog) && (lonlat1 = xy2lonlat(lonlat1, proj_string);	lonlat2 = xy2lonlat(lonlat2, proj_string))	# Convert to geog first
	d::Vector{Float64}   = Vector{Float64}(undef, size(lonlat1,1)::Int)
	az1::Vector{Float64} = Vector{Float64}(undef, size(lonlat1,1)::Int)
	az2::Vector{Float64} = Vector{Float64}(undef, size(lonlat1,1)::Int)
	dist, azi1, azi2 = Ref{Cdouble}(), Ref{Cdouble}(), Ref{Cdouble}()
	for k = 1:size(lonlat1,1)::Int
		kk::Int = (size(lonlat2,1)::Int == 1) ? 1 : k			# To allow the "all against one" case
		ccall((:geod_inverse, libproj), Cvoid, (Ptr{Cvoid},Cdouble,Cdouble,Cdouble, Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble}),
			  pointer_from_objref(get_ellipsoid(projPJ_ptr)), lonlat1[k,2], lonlat1[k,1], lonlat2[kk,2], lonlat2[kk,1], dist, azi1, azi2)
		d[k], az1[k], az2[k] = dist[], azi1[], azi2[]
	end
	proj_destroy(projPJ_ptr)
	if (backward)
		if (isa(az1, Real))
			az1 += 180;		(az1 > 180) && (az1 -= 360)
			az2 += 180;		(az2 > 180) && (az2 -= 360)
		else
			az1 .+= 180;	az2 .+= 180
			[(az1[k] > 180) && (az1[k] -= 360) for k = 1:lastindex(az1)]
			[(az2[k] > 180) && (az2[k] -= 360) for k = 1:lastindex(az2)]
		end
	end
	return size(d,1) == 1 ? (d[1], az1[1], az2[1]) : (d, az1, az2)
end

## -------------------------------------------------------------------------------------------------
"""
    angles, ind = vecangles(lonlat0::VecOrMat{Real}, lonlat1::Matrix{Real}; proj::String="",
                            s_srs::String="", epsg::Integer=0, sorted=true)

Computes the angles between lines taken from the central point `lonlat0` and those passed in the Mx2
matrix `lonlat1`. 

Args:

- `lonlat1`:  - coordinates of point 1 in the given projection (or a matrix with several points).
- `lonlat2`:  - coordinates of point 2 in the given projection (or a matrix with same size as `lonlat1`).
- `proj` or `s_srs`:  - the given projection whose ellipsoid we move along. Can be a proj4 string or an WKT.
- `epsg`:     - Alternative way of specifying the projection [Default is WGS84].
- `sorted`:   - By default we sort the lines azimuth so that the angles refer to contiguous line.
                If `sorted` is set to `false` we compute the angles in the order of points as given in `lonlat2`.

### Returns
- `angles` - A Float64 vector with the angles between center and points determined by the arguments plus the
             angle betwen the lines from center to first and from center to last point.
- `ind` - A vector of Int with the order obtained by sorting the lines azimuths (when `sorted=true`).
          Apply it to `lonlat2[ind,:]` to get the point distribution order in the same way as `angles`.
          Neddless, ofc, if `sorted=false`.
"""
function vecangles(lonlat0::VMr, lonlat1::Matrix{<:Real}; proj::String="",
                   s_srs::String="", epsg::Integer=0, sorted=true)
	az = invgeod(lonlat1, [lonlat0[1] lonlat0[2]]; proj=proj, s_srs=s_srs, backward=true)[3]
	[(az[k] < 0) && (az[k] += 360) for k = 1:lastindex(az)]
	if (sorted)
		p = sortperm(az)
		sort!(az)
	else
		p = collect(1:length(az))
	end
	difas = append!(diff(az), [az[1] - az[end]].+360)
	return difas, p
end

# -------------------------------------------------------------------------------------------------
"""
    circgeo(lon, lat; radius=X, proj="", s_srs="", epsg=0, dataset=false, unit=:m, np=120, shape="")
Or

    circgeo(lonlat; radius=X, proj="", s_srs="", epsg=0, dataset=false, unit=:m, np=120, shape="")

Compute a geographical circle (and other shapes) in geographical or in projected coordinates.

### Args
- `lonlat`:   - longitude, latitude (degrees). If a Mx2 matrix, returns as many segments as number of rows.
                Use this to compute multiple shapes at different positions. In this case output type is
                always a vector of GMTdatasets.

### Kwargs
- `radius`:   - The circle radius in meters (but see `unit`) or circumscribing circle for the other shapes
- `proj` or `s_srs`:  - the given projection whose ellipsoid we move along. Can be a proj4 string or an WKT
- `epsg`:     - Alternative way of specifying the projection [Default is WGS84]
- `dataset`:  - If true returns a GMTdataset instead of matrix (with single shapes)
- `unit`:     - If `radius` is not in meters use one of `unit=:km`, or `unit=:Nautical` or `unit=:Miles`
- `np`:       - Number of points into which the circle is descretized (Default = 120)
- `shape`:    - Optional string/symbol with "triangle", "square", "pentagon" or "hexagon" (or just the first char)
                to compute one of those geometries instead of a circle. `np` is ignored in these cases.

### Returns
- circ - A Mx2 matrix or GMTdataset with the circle coordinates

### Example:
Compute a circle about the (0,0) point with a radius of 50 km
```julia
    c = circgeo([0. 0], radius=50, unit=:k)
```
"""
circgeo(lon::Real, lat::Real; radius::Real=0., proj::String="", s_srs::String="", epsg::Integer=0, dataset::Bool=false, unit=:m, np::Int=120, shape="") =
	circgeo([lon lat]; radius=radius, proj=proj, s_srs=s_srs, epsg=epsg, dataset=dataset, unit=unit, np=np, shape=shape)
circgeo(lonlat::Vector{<:Real}; radius::Real=0., proj::String="", s_srs::String="", epsg::Integer=0, dataset::Bool=false, unit=:m, np::Int=120, shape="") =
	circgeo([lonlat[1] lonlat[2]]; radius=radius, proj=proj, s_srs=s_srs, epsg=epsg, dataset=dataset, unit=unit, np=np, shape=shape)

function circgeo(lonlat::Matrix{<:Real}; radius::Real=0., proj::String="", s_srs::String="", epsg::Integer=0, dataset::Bool=false, unit=:m, np::Int=120, shape="")
	(radius == 0) && error("Must provide circle Radius. Obvious, not?")
	_shape = lowercase(string(shape))
	if     (_shape == "")     azim = collect(Float64, linspace(0, 360, np))	# The default (circle)
	elseif (_shape[1] == 't') azim = [0.,  120, 240, 0]					# Triangle
	elseif (_shape[1] == 's') azim = [45., 135, 225, 315, 45]			# Square
	elseif (_shape[1] == 'p') azim = [0.,  72, 144, 216, 288, 360]		# Pentagon
	elseif (_shape[1] == 'h') azim = [0.,  60, 120, 180, 240, 300, 360]	# Hexagon
	else   error("Bad shape name ($(shape))")
	end
	n_shapes = size(lonlat, 1)
	if (n_shapes > 1)	# Multiple shapes require a GMTdataset output
		D = Array{GMTdataset}(undef, n_shapes)
		for k = 1:n_shapes
			D[k] = geod(lonlat[k,:], azim, radius; proj=proj, s_srs=s_srs, epsg=epsg, dataset=true, unit=unit)[1]
		end
	else		# Here the output may be a GMTdadaset or a simple Mx2 matrix depending on the 'dataset' value.
		D = geod(lonlat[1,:], azim, radius; proj=proj, s_srs=s_srs, epsg=epsg, dataset=dataset, unit=unit)[1]
	end
	D
end

# -------------------------------------------------------------------------------------------------
"""
    buffergeo(D::GMTdataset; width=0, unit=:m, np=120, flatstart=false, flatend=false, epsg::Integer=0, tol=0.01)
or

    buffergeo(line::Matrix; width=0, unit=:m, np=120, flatstart=false, flatend=false, proj::String="", epsg::Integer=0, tol=0.01)
or

    buffergeo(fname::String; width=0, unit=:m, np=120, flatstart=false, flatend=false, proj::String="", epsg::Integer=0, tol=0.01)

Computes a buffer arround a poly-line. This calculation is performed on a ellipsoidal Earth (or other planet)
using the GeographicLib (via PROJ4) so it should be very accurate.

### Parameters
- `D` | `line` | fname: - the geometry. This can either be a GMTdataset (or vector of it), a Mx2 matrix, the name
                          of file that can be read as a GMTdataset by `gmtread()` or a GDAL AbstractDataset object
- `width`:  - the buffer width to be applied. Expressed meters (the default), km or Miles (see `unit`)
- `unit`:   - If `width` is not in meters use one of `unit=:km`, or `unit=:Nautical` or `unit=:Miles`
- `np`:     - Number of points into which circles are descretized (Default = 120)
- `flatstart` - When computing buffers arround poly-lines make the start *flat* (no half-circle)
- `flatend`   - Same as `flatstart` but for the buffer end
- `proj`  - If line data is in Cartesians but with a known projection pass in a PROJ4 string to allow computing the buffer
- `epsg`  - Same as `proj` but using an EPSG code
- `tol`   - At the end simplify the buffer line with a Douglas-Peucker procedure. Use TOL=0 to NOT do the line
            simplification, or use any other value in degrees. Default computes it as 0.5% of buffer width.

### Returns
A GMT dataset or a vector of it (when input is Vector{GMTdataset})

## Example: Compute a buffer with 50000 m width

    D = buffergeo([0 0; 10 10; 15 20], width=50000);
"""
buffergeo(fname::String; width=0, unit=:m, np=120, flatstart=false, flatend=false, epsg::Integer=0, tol=-1.0) =
	buffergeo(gmtread(fname); width=width, unit=unit, np=np, flatstart=flatstart, flatend=flatend, epsg=epsg, tol=tol)

buffergeo(ds::Gdal.AbstractDataset; width=0, unit=:m, np=120, flatstart=false, flatend=false, epsg::Integer=0, tol=-1.0) =
	buffergeo(gmt2gd(ds); width=width, unit=unit, np=np, flatstart=flatstart, flatend=flatend, epsg=epsg, tol=tol)

buffergeo(D::GMTdataset; width=0, unit=:m, np=120, flatstart=false, flatend=false, epsg::Integer=0, tol=-1.0) =
	buffergeo(D.data; width=width, unit=unit, np=np, flatstart=flatstart, flatend=flatend, proj=D.proj4, epsg=epsg, tol=tol)

function buffergeo(D::Vector{<:GMTdataset}; width=0, unit=:m, np=120, flatstart=false, flatend=false, epsg::Integer=0, tol=-1.0)
	_D = Vector{GMTdataset{Float64,2}}(undef, length(D))
	for k = 1:length(D)
		_D[k] = buffergeo(D[k].data; width=width, unit=unit, np=np, flatstart=flatstart, flatend=flatend,
		                  proj=D[1].proj4, epsg=epsg, tol=tol)
	end
	return (length(_D) == 1) ? _D[1] : _D		# Drop the damn Vector singletons
end

function buffergeo(line::Matrix{<:Real}; width=0, unit=:m, np=120, flatstart=false, flatend=false, proj::String="", epsg::Integer=0, tol=-1.0)
	# This function can be a bit optimized with a clever choice of which points to compute on the circle.
	# Points close to the segment axis are ofc nover needed.
	(width == 0) && error("Must provide the buffer width. Obvious, not?")
	dist, azim, = invgeod(line[1:end-1, :], line[2:end, :], proj=proj, epsg=epsg)	# distances and azimuths between the polyline vertices
	#(line[1, 1:2] == line[end, 1:2]) && (flatstart = flatend = false)		# Polygons can't have start/end flat edges
	width *= unit_factor(unit)
	n_seg = length(azim)
	
	# --------------------- When 'line' is actually a single point -------------------------------------------- 
	n_seg == 0 && return mat2ds(circgeo(line, radius=width, np=np, proj=proj, epsg=epsg), proj=proj, epsg=epsg)

	D, _D = GMTdataset(), GMTdataset()
	for n = 1:n_seg
		seg = [geod(line[n,:], azim[n], 0:width/4:dist[n], proj=proj, epsg=epsg)[1]; line[n+1:n+1,:]]
		n_vert = size(seg,1)
		for k = 2:n_vert
			if (k == 2)
				c0 = circgeo(seg[1,:], radius=width, np=np, proj=proj, epsg=epsg);	trim_dateline!(c0, seg[1,1])
				c  = circgeo(seg[2,:], radius=width, np=np, proj=proj, epsg=epsg);	trim_dateline!(c , seg[2,1])
				_D = polyunion(c0, c)
				continue
			end
			c = circgeo(seg[k,:], radius=width, np=np, proj=proj, epsg=epsg)
			trim_dateline!(c, seg[k,1])
			_D = polyunion(_D, c)
		end
		if (n == 1)  D = _D
		else         D = polyunion(_D, D)
		end
	end

	# At this point we still have a "wavy" buffer resulting from the union of the circles. Ideally we should
	# be able to use GMT's mapproject to find only the points that are at the exact 'width' distance from the
	# line, but at this moment there seems to be an issue in GMT and distances are shorter. However we can
	# do some cheap statistics to get read of the more inner points a get an almost perfec buffer.
	Ddist2line = mapproject(D, L=(line=line, unit=:e))		# Find the distance from buffer points to input line
	if (isa(Ddist2line, GMTdataset))
		d_mean = mean(view(Ddist2line.data, :, 3))
		ind = view(Ddist2line.data, :, 3) .>= d_mean
	else
		d_mean = mean(view(Ddist2line[1].data, :, 3))
		ind = view(Ddist2line[1].data, :, 3) .>= d_mean
	end
	ind[1], ind[end] = true, true			# Ensure first and last are not removed
	isa(D, GMTdataset) ? (D.data = D.data[ind, :]) : (D[1].data = D[1].data[ind, :])# Remove all points that are less 1% above the mean

	(proj == "" && epsg == 0) && (isa(D, GMTdataset) ? (D.proj4 == prj4WGS84) : (D[1].proj4 == prj4WGS84))
	(proj != "") && (isa(D, GMTdataset) ? (D.proj4 = proj) : (D[1].proj4 = proj))
	(epsg != 0) && (t = toPROJ4(importEPSG(epsg)); isa(D, GMTdataset) ? (D.proj4 = t) : (D[1].proj4 = t))
	(tol < 0) && (tol = width * 0.005 / 111111)		# Tolerance as 0.5% of buffer width converted to degrees
	return (tol > 0) ? simplify(D, tol) : D			# If TOL > 0 do a DP simplify on final buffer
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

# -------------------------------------------------------------------------------------------------
"""
    function geodesic(D; step=0, unit=:m, np=0, proj::String="", epsg::Integer=0, longest::Bool=false)
or

    function geodesic(lon1, lat1, lon2, lat2; step=0, unit=:m, np=0, proj::String="", epsg::Integer=0, longest::Bool=false)

Generate geodesic line(s) (shortest distace) on an ellipsoid. Input data can be two or more points.
In later case each line segment is descretized at `step` increments,

### Parameters

- `D`: - the input points. This can either be a GMTdataset (or vector of it), a Mx2 matrix, the name
         of file that can be read as a GMTdataset by `gmtread()` or a GDAL AbstractDataset object
- `step`: - Incremental distance at which the segment line is descretized in meters(the default), but see `unit`
- `unit`: - If `step` is not in meters use one of `unit=:km`, or `unit=:Nautical` or `unit=:Miles`
- `np`:   - Number of intermediate points between poly-line vertices (alternative to `step`)
- `proj`  - If line data is in Cartesians but with a known projection pass in a PROJ4 string
- `epsg`  - Same as `proj` but using an EPSG code
- `longest` - Compute the 'long way around' of the geodesic. That is, going from point A to B taking
              the longest path. But mind you that geodesics other than meridians and equator are not closed
              paths (see https://en.wikipedia.org/wiki/Geodesics_on_an_ellipsoid). This line is obtained by
              computing the azimuth from A to B, at B, and start the line at B with that azimuth and go around
              the Earth till we reach, _close_ to A, but not exactly A (except for the simple meridian cases).

### Returns
A Mx2 matrix with the lon lat of the points along the geodesic when input is a matrix. A GMT dataset
or a vector of it (when input is Vector{GMTdataset}).

## Example: Compute an geodesic between points (0,0) and (30,50) discretized at 100 km steps.

    mat = geodesic([0 0; 30 50], step=100, unit=:k);
"""
geodesic(fname::String; step=0.0, unit=:m, np=0, proj::String="", epsg::Integer=0, longest::Bool=false) =
	geodesic(gmtread(fname); step=step, unit=unit, np=np, proj=proj, epsg=epsg, longest=longest)

geodesic(ll1::VMr, ll2::VMr; step=0.0, unit=:m, np = 180, proj::String="", epsg::Integer=0, longest::Bool=false) =
	geodesic([ll1[1] ll1[2]; ll2[1] ll2[2]]; step=step, unit=unit, np=np, proj=proj, epsg=epsg, longest=longest)

geodesic(lon1::Real, lat1::Real, lon2::Real, lat2::Real; step=0.0, unit=:m, np=0, proj::String="",
         epsg::Integer=0, longest::Bool=false) =
	geodesic([lon1 lat1; lon2 lat2]; step=step, unit=unit, np=np, proj=proj, epsg=epsg, longest=longest)

geodesic(ds::Gdal.AbstractDataset; step=0.0, unit=:m, np=0, proj::String="", epsg::Integer=0, longest::Bool=false) =
	geodesic(gmt2gd(ds); step=step, unit=unit, np=np, proj=proj, epsg=epsg, longest=longest)

function geodesic(D::Vector{<:GMTdataset}; step=0.0, unit=:m, np=0, proj::String="", epsg::Integer=0,
	              longest::Bool=false)
	_D = Vector{GMTdataset{Float64,2}}(undef, length(D))
	for k = 1:length(D)
		_D[k] = mat2ds(geodesic(D[k].data; step=step, unit=unit, np=np, proj = (proj == "") ? D[k].proj4 : proj,
		               epsg=epsg, longest=longest))
	end
	return (length(_D) == 1) ? _D[1] : _D		# Drop the damn Vector singletons
end
function geodesic(D::GMTdataset; step=0.0, unit=:m, np=0, proj::String="", epsg::Integer=0, longest::Bool=false)
	mat2ds(geodesic(D.data; step=step, unit=unit, np=np, proj = (proj == "") ? D.proj4 : proj,
	       epsg=epsg, longest=longest))
end

function geodesic(line::Matrix{<:Real}; step=0.0, unit=:m, np=0, proj::String="", epsg::Integer=0, longest::Bool=false)
	(!longest && step == 0 && np == 0) && error("For 'longest' must provide either a 'step' or a 'np' (number of points).")
	(size(line, 1) == 1) && error("Lines cannot have a single point.")
	(np > 0 && size(line, 1) != 2) && error("Number of intermediate points cannot be used with polylines.")
	step *= unit_factor(unit)
	
	longest && return geodesic_long(line[1,:], line[end,:]; step=step, np=np, proj=proj, epsg=epsg)

	dist, azim, = invgeod(line[1:end-1, :], line[2:end, :], proj=proj, epsg=epsg)	# dist and azims between the polyline vertices

	(np > 0) && (step = dist[1] / (np + 1))
	seg = geod(line[1,:], azim[1], 0:step:dist[1], proj=proj, epsg=epsg)[1]
	if (size(line, 1) == 2)
		(hypot((seg[end,:] .- line[2,:])...) > 1) && (seg = [seg; line[2:2, :]])	# If increment does not land exactly at end point
		isa(seg, GMTdataset) && (seg.attrib = Dict("Length" => "$(dist)"))
	else
		for n = 2:size(line,1)-1
			_seg = geod(line[n,:], azim[n], 0:step:dist[n], proj=proj, epsg=epsg)[1]
			(hypot((_seg[end,:] .- line[n,:])...) > 1) && (_seg = [_seg; line[n+1:n+1, :]])
			seg = [seg; _seg]			# Horrible but we can't know in advance the number of final points
		end
		isa(seg, Vector{<:GMTdataset}) && (seg[1].attrib = Dict("Length" => "$(sum(dist))"))	# Is this is right?
	end
	seg
end
const orthodrome = geodesic

# -------------------------------------------------------------------------------------------------
function geodesic_long(lonlat1::VMr, lonlat2::VMr; step=0.0, np=180, proj::String="", epsg::Integer=0)
	# Compute the long way round, complementary of the shortest path between A & B. See GMT forum discussion
	# https://forum.generic-mapping-tools.org/t/oblique-mercator-for-straight-line-between-points-as-maps-equator

	_name = TMPDIR_USR[1] * "/" * "GMTtmp_" * TMPDIR_USR[2] * TMPDIR_USR[3] * ".dat" 	# Due to bug in mapproject need to save in tmp file
	
	distAB, azA, = invgeod(lonlat1, lonlat2, proj=proj, epsg=epsg)		# Distance and azim between the end points 
	dest1, = geod(lonlat1, azA, 39950, unit=:km, proj=proj, epsg=epsg)	# Destination of a point before the perimeter
	dest2, = geod(lonlat1, azA, 40050, unit=:km, proj=proj, epsg=epsg)	# Destination of a point after the perimeter
	t = geodesic([dest1[1] dest1[2]; dest2[1] dest2[2]], step=1000, proj=proj, epsg=epsg)	# Temp geodesic arround the perimeter point
	gmtwrite(_name, t);				# Workaround a bug in <= 6.4.0
	x = mapproject([lonlat1[1] lonlat1[2]], L=_name)	# Assume the closest point to A corresponds to full perimeter.
	d, = invgeod(dest1, [x[4] x[5]], proj=proj, epsg=epsg)	# Distance from dest1 to the point where the geodesic does a full perimeter.
	dtot = 39950000 + d				# Total length of this geodesic (A bit in excess probably due to geodesics not closing)
	(step != 0) && (np = round(Int, dtot / step) + 1)	# Takes precedence over 'np' because that one has a default value.

	function get_mindist(az)
		D = geod(lonlat1, az, linspace(0,dtot,360), proj=proj, epsg=epsg)[1]
		gmtwrite(_name, D);
		mapproject([lonlat2[1] lonlat2[2]], L=_name)	# Find closest point to B in the passing by geodesic
	end

	# Using the azimuth computed from the shortest distance between A & B will always give only an aproximation
	# to find the 'longest way around' and reach B. So we need to refine it, see comment in tis GMT forum post
	# https://forum.generic-mapping-tools.org/t/oblique-mercator-for-straight-line-between-points-as-maps-equator/3223/17
	# The following trick seems to work pretty well:
	# 1. Compute the shortest distance between B and estimate arrival point
	# 2. Repeat but using now a small perturbation (0.1 deg) to the first azimuth
	# 3. Use the difference in the two distances to estimate how many (fractional) times we must correct
	#    the initial azimuth estimate obtained from the shortest path between A & B.
	az, daz = azA + 180, 0.1
	d0 = get_mindist(az)[3]
	dt = get_mindist(az + daz)[3]
	dd = abs(dt - d0)
	az = (dt < d0) ? az + (d0 / dd) * daz : az - (d0 / dd) * daz

	d = geod(lonlat1, az, dtot-distAB)[1]				# First estimate of the arrival point
	D = mapproject(lonlat2, G=(d[1], d[2]))				# Distance between estimation and true point
	total_len = dtot - distAB - D[end]					# Correct 'dtot' that was estimated in excess.
	p,a = geod(lonlat1, az, linspace(0,total_len,np))	# Possibly because the path is slightly hellicoidal.
	prj = (proj != "" && (contains(proj,"=lon") || contains(proj,"=lat"))) ? proj : prj4WGS84
	D = mat2ds(hcat(p,a), attrib=Dict("Length" => "$(total_len)", "ShortLength" => "$distAB"), colnames=["Lon", "Lat", "azim"], proj=prj)
	p = (proj != "") ? ", proj="*proj : ""
	n = (np != 180)  ? ", np=$np" : ""
	e = (epsg != 0)  ? ", epsg=$epsg" : ""
	D.comment = ["geodesic($(lonlat1), $(lonlat2), longest=true" * p * n * e]	# Store the command that was run
	set_dsBB!(D)										# Update BB
	try rm(_name); catch; end

	return D
end

# -------------------------------------------------------------------------------------------------
"""
    function loxodrome(lon1,lat1,lon2,lat2; step=0, unit=:m, np=0, proj::String="", epsg::Integer=0)
or

    function loxodrome(D; step=0, unit=:m, np=0, proj::String="", epsg::Integer=0)

Generate a loxodrome (rhumb line) on an ellipsoid. Input data can be two or more points.
In later case each line segment is descretized at `step` increments,

### Parameters

- `D`: - the input points. This can either be a 2x2 matrix or a GMTdataset. Note that only the first 2 points are used.
- `step`: - Incremental distance at which the segment line is descretized in meters(the default), but see `unit`
- `unit`: - If `step` is not in meters use one of `unit=:km`, or `unit=:Nautical` or `unit=:Miles`
- `np`:   - Number of intermediate points to be generated between end points (alternative to `step`)
- `proj`  - If line data is in Cartesians but with a known projection pass in a PROJ4 string
- `epsg`  - Same as `proj` but using an EPSG code

### References:
- [The Loxodrome on an Ellipsoid](http://www.mygeodesy.id.au/documents/Loxodrome%20on%20Ellipsoid.pdf)

### Returns
A Mx2 matrix with the lon lat of the points along the loxodrome when input is a matrix or the 2 pairs of points.
A GMTdataset when the input is GMTdataset.

## Example: Compute an loxodrome between points (0,0) and (30,50) discretized at 100 km steps.

    loxo = loxodrome([0 0; 30 50], step=100, unit=:k);
"""
loxodrome(lon1::Real, lat1::Real, lon2::Real, lat2::Real; step=0, unit=:m, np=0, proj::String="", epsg::Integer=0) =
	loxodrome([lon1 lat1; lon2 lat2]; step=step, unit=unit, np=np, proj=proj, epsg=epsg)

function loxodrome(D::GMTdataset; step=0, unit=:m, np=0, proj::String="", epsg::Integer=0)
	mat2ds(loxodrome(D.data; step=step, unit=unit, np=np, proj = (proj == "") ? D.proj4 : proj, epsg=epsg))
end

function loxodrome(line::Matrix{<:Real}; step=0, np=0, unit=:m, proj::String="", epsg::Integer=0)
	(step == 0 && np == 0) && error("Must provide either a 'step' or a 'np' (number of points).")
	(size(line, 1) == 1) && error("Lines cannot have a single point.")
	step *= unit_factor(unit)
	dist, azim = loxodrome_inverse(line[1,1], line[1,2], line[2,1], line[2,2])
	(np > 0) && (step = dist / (np + 1))
	distances = collect(0:step:dist)
	((dist - distances[end]) > 1) && append!(distances, dist)	# Make sure we don't loose destiny point
	loxo = Array{Float64,2}(undef, length(distances), 2)
	for k = 1:lastindex(distances)
		loxo[k, :] = loxodrome_direct(line[1,1], line[1,2], azim, distances[k])
	end
	loxo
end

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
	elseif (isa(azim, Real) && isvector(dist))					# One line only with several points along it
		dest, azi = Array{Float64}(undef, length(dist)::Int, 2), Vector{Float64}(undef, length(dist)::Int)
		for k = 1:lastindex(dist)::Int
			d, azi[k] = _geod_direct!(ggd, copy(lonlat), azim, dist[k])
			dest[k, :] = (isgeog) ? d : lonlat2xy(d, proj_string)
		end
		(dataset) && (dest = helper_gdirect_SRS([dest azi], proj_string, wkbLineString))	# Return a GMTdataset
	elseif (isvector(azim) && length(dist) == 1)				# A circle (dist has became a vector in 4rth line)
		dest, azi = Array{Float64}(undef, length(azim), 2), Vector{Float64}(undef, length(azim))
		for k = 1:lastindex(azim)
			d, azi[k] = _geod_direct!(ggd, copy(lonlat), azim[k], dist[1])
			dest[k, 1:2] = (isgeog) ? d : lonlat2xy(d, proj_string)
		end
		(dataset) &&		# Return a GMTdataset
			(dest = GMTdataset(hcat(dest, azi), Float64[], Float64[], DictSvS(), String[], String[],
			                   "",String[], startswith(proj_string, "+proj") ? proj_string : "", "", 0, Int(wkbLineString)))
	elseif (isvector(azim) && isvector(dist))					# Multi-lines with variable length and/or number of points
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
		D = Vector{GMTdataset{Float64,2}}(undef, n_lines)
		for nl = 1:n_lines
			n_pts = length(Vdist[nl])					# Number of points in this line
			dest = Array{Float64}(undef, n_pts, 3)		# Azimuth goes into the D too
			for np = 1:n_pts
				d, azi = _geod_direct!(ggd, copy(lonlat), azim[nl], Vdist[nl][np])
				dest[np, 1:2] = (isgeog) ? d : lonlat2xy(d, proj_string)
				dest[np, 3] = azi		# Fck language that makes it a pain to try anything vectorized 
			end
			D[nl] = GMTdataset(dest, Float64[], Float64[], DictSvS(), String[], String[], "", String[], "", "", 0, Int(wkbLineString))
			helper_gdirect_SRS(dest, proj_string, wkbLineString, D[nl])	# Just assign the SRS
		end
		r = (n_lines == 1) ? D[1] : D
		return r, nothing		# Here both the point coordinates and the azim are in the GMTdataset
	else
		error("'azimuth' MUST be either a scalar or a 1-dim array, and 'distance' may also be a Vector{Vector}")
	end
	return dest, azi
end

# -------------------------------------------------------------------------------------------------
function helper_gdirect_SRS(mat, proj_string::String, geom, D=GMTdataset())
	# Convert the output of geod_direct into a GMTdataset and, if possible, assign it a SRS
	# If a 'D' is sent in, we only (eventually) assign it an SRS
	isempty(D) && (D = GMTdataset(mat, Float64[], Float64[], DictSvS(), String[], String[], "", String[], "", "", 0, Int(geom)))
	(startswith(proj_string, "+proj")) && (D.proj4 = proj_string)
	D
end

# -------------------------------------------------------------------------------------------------
function _geod_direct!(geod::geod_geodesic, lonlat, azim, distance)
	GC.@preserve lonlat begin
	p = pointer(lonlat)
	azi = Ref{Cdouble}()		# the (forward) azimuth at the destination
	ccall((:geod_direct, libproj), Cvoid, (Ptr{Cvoid},Cdouble,Cdouble,Cdouble,Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble}),
		  pointer_from_objref(geod), lonlat[2], lonlat[1], azim, distance, p+sizeof(Cdouble), p, azi)
	end
	lonlat, azi[]
end

# -------------------------------------------------------------------------------------------------
function helper_geod(proj::String, s_srs::String, epsg::Integer, usedefault=true)::Tuple{String, Ptr{Nothing}, Bool}
	# 'proj' and 's_srs' are synonyms.
	# Return the projection string and also if the projection is geogs.
	if     (proj  != "")  prj_string = proj
	elseif (s_srs != "")  prj_string = s_srs
	elseif (epsg > 0)     prj_string = toPROJ4(importEPSG(epsg))
	elseif (usedefault)   prj_string = prj4WGS84
	else                  return "", C_NULL, false		# Slightly dangerous.
	end
	(startswith(prj_string, "GEOGC")) && (prj_string = toPROJ4(importWKT(prj_string)))
	prj_string, proj_create(prj_string), (startswith(prj_string, "+proj=longl") || startswith(prj_string, "+proj=lonl") || startswith(prj_string, "+proj=latl") || epsg == 4326)
end

# -------------------------------------------------------------------------------------------------
function geod_geodesic(a::Cdouble, f::Cdouble)::geod_geodesic
	geod = geod_geodesic()
	ccall((:geod_init, libproj), Cvoid, (Ptr{Cvoid}, Cdouble, Cdouble), pointer_from_objref(geod), a, f)
	geod
end

# -------------------------------------------------------------------------------------------------
function get_ellipsoid(projPJ_ptr::Ptr{Cvoid})::geod_geodesic
	#a, ecc2 = pj_get_spheroid_defn(projPJ_ptr)
	#geod_geodesic(a, 1-sqrt(1-ecc2))
	a, inv_f, = proj_ellipsoid_get_parameters(C_NULL, projPJ_ptr)
	f = (inv_f == 0.) ? 0.0 : 1 / inv_f		# Don't know why but for spheres we must set f = 0
	geod_geodesic(a, f)
end

# -------------------------------------------------------------------------------------------------
function proj_create(proj_str::String, ctx=C_NULL)
	# Returns an Object that must be unreferenced with proj_destroy()
	# THIS GUY IS VERY EXPENSIVE. TRY TO MINIMIZE ITS USAGE.
	projPJ_ptr = ccall((:proj_create, libproj), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring), ctx, proj2wkt(proj_str))
	(projPJ_ptr == C_NULL) && error("Could not parse projection: \"$proj_str\"")
	projPJ_ptr
end

proj_create_crs_to_crs(s_crs, t_crs, area, ctx=C_NULL) =
	ccall((:proj_create_crs_to_crs, libproj), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring, Cstring, Ptr{Cvoid}), ctx, s_crs, t_crs, area)

# -------------------------------------------------------------------------------------------------
function proj_destroy(projPJ_ptr::Ptr{Cvoid})	# Free C datastructure associated with a projection.
	@assert projPJ_ptr != C_NULL
	ccall((:proj_destroy, libproj), Ptr{Cvoid}, (Ptr{Cvoid},), projPJ_ptr)
end

#= -------------------------------------------------------------------------------------------------
function pj_get_spheroid_defn(proj_ptr::Ptr{Cvoid})
	a = Ref{Cdouble}()		# major_axis
	ecc2 = Ref{Cdouble}()	# eccentricity squared
	ccall((:pj_get_spheroid_defn, libproj), Cvoid, (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}), proj_ptr, a, ecc2)
	a[], ecc2[]
end
=#

# -------------------------------------------------------------------------------------------------
function proj_info()
	pji = ccall((:proj_info, libproj), PJ_INFO, ())
	println(unsafe_string(pji.release), "\n", "Located at: ", unsafe_string(pji.searchpath))
end

#=
function _transform!(src_ptr::Ptr{Cvoid}, dest_ptr::Ptr{Cvoid}, point_count::Integer, point_stride::Integer,
                     x::Ptr{Cdouble}, y::Ptr{Cdouble}, z::Ptr{Cdouble})
	@assert src_ptr != C_NULL && dest_ptr != C_NULL
	err = ccall((:pj_transform, libproj), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Int32, Cint, Ptr{Cdouble}, Ptr{Cdouble},
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

function is_latlong(proj_ptr::Ptr{Cvoid})
	@assert proj_ptr != C_NULL
	ccall((:pj_is_latlong, libproj), Cint, (Ptr{Cvoid},), proj_ptr) != 0
end
=#

function proj_get_ellipsoid(proj_ptr::Ptr{Cvoid}, ctx=C_NULL)
	# Returned object must be unreferenced with proj_destroy()
	ccall((:proj_get_ellipsoid, libproj), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}), ctx, proj_ptr)
end

function proj_ellipsoid_get_parameters(ellipsoid::Ptr{Cvoid}=NULL, proj_ptr::Ptr{Cvoid}=NULL, ctx=NULL)
	# proj_ellipsoid_get_parameters(PJ_CONTEXT *ctx, const PJ *ellipsoid, double *out_semi_major_metre, double *out_semi_minor_metre, int *out_is_semi_minor_computed, double *out_inv_flattening)
	semi_major = Ref{Cdouble}()		# semi-major axis in meters
	semi_minor = Ref{Cdouble}()		# semi-minor axis in meters
	inv_flattening = Ref{Cdouble}()		# semi-minor axis in meters
	is_semi_minor_computed = Ref{Cint}()		#
	need_destroy = (ellipsoid == NULL)
	(ellipsoid == NULL) && (ellipsoid = proj_get_ellipsoid(proj_ptr))
	ccall((:proj_ellipsoid_get_parameters, libproj), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cdouble}), ctx, ellipsoid, semi_major, semi_minor, is_semi_minor_computed, inv_flattening)
	need_destroy && proj_destroy(ellipsoid)		# If it was created above
	semi_major[], inv_flattening[], semi_minor[]
end

"""
    proj2wkt(proj4_str::String, pretty::Bool=false)

Convert a PROJ4 string into the WKT form. Use `pretty=true` to return a more human readable text.
"""
function proj2wkt(proj4_str::String; pretty::Bool=false)
	!startswith(proj4_str, "+proj=") && error("$(proj4_str) is not a valid proj4 string")
	toWKT(importPROJ4(proj4_str), pretty)
end

"""
    wkt2proj(wkt_str::String)

Convert a WKT SRS string into the PROJ4 form.
"""
wkt2proj(wkt_str::String) = toPROJ4(importWKT(wkt_str))

"""
    epsg2proj(code::Integer)

Convert a EPSG code into the PROJ4 form.
"""
epsg2proj(code::Integer)  = toPROJ4(importEPSG(code))

"""
    epsg2wkt(code::Integer, pretty::Bool=false)

Convert a EPSG code into the WKT form. Use `pretty=true` to return a more human readable text.
"""
epsg2wkt(code::Integer; pretty::Bool=false) = toWKT(importEPSG(code), pretty)

# The next functions are from GMT but stored here since thay are about projections too.

# -----------------------------------------------------------------------------------------
"""
    lat = isometric2geod(latin, flat)

Convert isometric latitudes to geodetic latitudes.

### Arguments
- `latin`: Isometric latitude(s) in degrees
- `flat`: Flattening of the ellipsoid (use 0.0 for is spherical).

### Returns
- Geodetic latitude(s) in degrees
"""
function isometric2geod(latin, flat)
    latcnf = 2 * atan.(exp.(latin * pi / 180)) .- pi / 2
    lat = conf2geod(latcnf, flat)
    return lat * 180 / pi
end

# -----------------------------------------------------------------------------------------
"""
    lat = conf2geod(latin, flat)

Convert conformal latitude `latin` to geodetic latitude using the flattening of the ellipsoid.

### Arguments
- `latin`: Conformal latitude(s) in radians
- `flat`: Flattening of ellipsoid (use 0.0 for is spherical)

### Returns
- `lat`: Geodetic latitude(s) in radians
"""
function conf2geod(latin, flat)
    e2 = flat * (2.0 - flat)
    e4 = e2 * e2
    e6 = e4 * e2
    e8 = e4 * e4

    c0 = e2 / 2 + 5 * e4 / 24 + e6 / 12 + 13 * e8 / 360
    c1 = 7 * e4 / 48 + 29 * e6 / 240 + 811 * e8 / 11520
    c2 = 7 * e6 / 120 + 81 * e8 / 1120
    c3 = 4279 * e8 / 161280

    rl2 = 2.0 * latin
    sin2phi = sin.(rl2)
    cos2phi = cos.(rl2)
	return latin .+ sin2phi .* (c0 .+ cos2phi .* (c1 .+ cos2phi .* (c2 .+ cos2phi * c3)))
end

# -----------------------------------------------------------------------------------------
"""
    lat = geod2isometric(latin, flat)

Convert geodetic latitudes to isometric latitudes.

### Arguments
- `latin`: Geodetic latitude(s) in degrees
- `flat`: Flattening of the ellipsoid  (Use 0.0 for is spherical)

### Returns
- Isometric latitude in degrees
"""
function geod2isometric(latin, flat)
    latin = latin * pi / 180
    latcnf = geod2cnf(latin, flat)
    lat = log.(tan.(pi / 4 .+ latcnf / 2))
    return lat * 180 / pi
end

# -----------------------------------------------------------------------------------------
"""
    latconf = geod2cnf(latin, flat)

Convert geodetic latitudes `latin` to conformal latitudes using the
flattening `flat` of the ellipsoid.

### Arguments
- `latin`: Geodetic latitude(s) in radians
- `flat`: Flattening of the ellipsoid  (Use 0.0 for is spherical)

### Returns
- Conformal latitude(s) in radians.
"""
function geod2cnf(latin, flat)
    f1 = 1 .- flat * sin.(latin)
    f2 = 1 .+ flat * sin.(latin)
    f3 = 1 .- sin.(latin)
    f4 = 1 .+ sin.(latin)
    return 2 * atan.(sqrt.((f4 ./ f3) .* ((f1 ./ f2) .^ flat))) .- pi / 2
end

# -----------------------------------------------------------------------------------------
function meridionalRad(a, flat)
	# Compute Meridional radius as defined in GMT_lar_swap_init() of gmt_map.c
	# A -> Equatorial radius; F -> flatness
	e2 = flat * (2.0 - flat)
	e4 = e2 * e2
	e6 = e4 * e2
	e8 = e4 * e4

	xx0 = 1 / 4
	xx1 = xx0 * 3 / 16
	xx2 = xx1 * 3 * 5 / 36
	xx3 = xx2 * 5 * 7 / 64
	x = xx0 * e2 + (xx1 * e4 + (xx2 * e6 + xx3 * e8))
	return a * (1 - x)
end

# ---------------------------------------------------------------------------------------------------
"""
    x, y = geog2merc(lon, lat, pt_radius)

Convert from mercator to geographic coordinates in degrees. For a sphere, `lat` should be the geocentric
latitude(s), but for an ellipsoid `lat` should contain the isometric latitude(s).

### Returns
- x,y Mercator coordinates in meters.
"""
function geog2merc(lon, lat, pt_radius)
	D2R = pi / 180
	x = lon * D2R * pt_radius
	y = log.(tan.((pi/4) .+ 0.5 .* D2R .* lat)) * pt_radius
	return x, y
end

# ---------------------------------------------------------------------------------------------------
"""
    lon = wraplon180!(lon::Vector{<:Real})

Wrap longitudes to be in the range -180 to 180.
"""
function wraplon180!(lon::AbstractVecOrMat{<:Real})
	ind = lon .< -180
	while any(ind)
		lon[ind] .+= 360
		ind = lon .< -180
	end

	ind = lon .> 180
	while any(ind)
		lon[ind] .-= 360
		ind = lon .> 180
	end
	return lon
end
function wraplon180!(lon::Real)		# This one is for scalars only
	lon < -180 && (lon += 360)
	lon > 180 && (lon -= 360)
	return lon
end

function wraplon180!(D::GMTdataset)
	(D.bbox[1] >= -180 && D.bbox[1] <= 180 && D.bbox[2] >= -180 && D.bbox[2] <= 180) && return D
	wraplon180!(view(D.data, :, 1))
	wraplon180!(view(D.bbox, 1:2))
	wraplon180!(view(D.ds_bbox, 1:2))
	return D
end
function wraplon180!(D::Vector{<:GMTdataset})
	for n = 1: numel(D)
		(D[n].bbox[1] >= -180 && D[n].bbox[1] <= 180 && D[n].bbox[2] >= -180 && D[n].bbox[2] <= 180) && continue
		wraplon180!(view(D[n].data, :, 1))
		wraplon180!(view(D[n].bbox, 1:2))
	end
	wraplon180!(view(D[1].ds_bbox, 1:2))
	return D
end

"""
    WESN = get_geoglimits(GI::GItype)::Vector{Float64}

Get the geographical limits of grids or images and return them in a [West, East, South, North] vector.
If grid/image is not referenced, returns an empty vector.
"""
function get_geoglimits(GI::GItype)::Vector{Float64}
	prj = getproj(GI, proj4=true)
	region = getregion(GI)
	helper_geoglimits(prj, region)
end

function get_geoglimits(D::GDtype)::Vector{Float64}
	prj = getproj(D, proj4=true)
	region = getregion(D)
	helper_geoglimits(prj, region)
end

function helper_geoglimits(prj::String, region::Vector{Float64})::Vector{Float64}
	if (length(prj) > 12 && !contains(prj, " "))	# For when a condensed (for GMT) proj string was passed.
		prj = replace(prj, "+" => " +")
	end
	(prj == "") && return Float64[]		# GI is not referenced
	isgeog(prj) && return region	# GI is already in geographic coordinates

	Gdal.CPLPushErrorHandler(@cfunction(Gdal.CPLQuietErrorHandler, Cvoid, (UInt32, Cint, Cstring)))
	opts = ["-s_srs", prj, "-t_srs", prj4WGS84, "-overwrite"]
	ds = Gdal.get_gdaldataset([region[1] region[3]], opts, false)[1]
	o1 = Gdal.gdalvectortranslate(ds, opts; dest="/vsimem/tmp", gdataset=true)
	ds = Gdal.get_gdaldataset([region[2] region[4]], opts, false)[1]
	o2 = Gdal.gdalvectortranslate(ds, opts; dest="/vsimem/tmp", gdataset=true)
	if (o1.ptr == C_NULL || o2.ptr == C_NULL)		# Diagonals failed, probably a Mollweide or alike projection
		t = xy2lonlat([region[1] min(0,region[4]); region[2] min(0,region[4]);
		               0 region; 0 region], s_srs=prj, t_srs=prj4WGS84)
		return [t[1, 1], t[2, 1], t[3, 2], t[4, 2]]
	else
		t = xy2lonlat([region[1] region[3]; region[2] region[4]], s_srs=prj, t_srs=prj4WGS84)
		return [t[1, 1], t[2, 1], t[1, 2], t[2, 2]]
	end
end

# ---------------------------------------------------------------------------------------------------
"""
    setsrs!(GID::Union{GItype, GDtype}; prj::String="", proj::String="", proj4::String="", wkt::String="", epsg::Int=0)
or

    setcrs!(GID::Union{GItype, GDtype}; prj::String="", proj::String="", proj4::String="", wkt::String="", epsg::Int=0)

Set the spatial reference of a GMTgrid, GMTimage or GMTdataset(s). Pass one or more of the ways to reference the
grid/image/dataset objects. Note that if you pass more than one way, the rest of the information is redundant and
should not be contradictory.

- `prj`, `proj` or `proj4`: Aliases for passing a PROJ4 string.

- `wkt`: A WKT (Well Known Format) string.

- `epsg`: A EPSG code.

### Return
This function returns nothing as what it does is to add/change the object referencing information.
"""
function setsrs!(GID::Union{GItype, GDtype}; prj::String="", proj::String="", proj4::String="", wkt::String="", epsg::Int=0)
	O = (GID isa GItype || GID isa GMTdataset) ? GID : GID[1]	# Select one "comon" type that we can address equaly.
	_prj = (prj != "" ? prj : proj != "" ? proj : proj4 != "" ? proj4 : "")
	(_prj != "") && (_prj == "geog" && (_prj = "+proj=longlat"); (!startswith(_prj, "+proj=") && (_prj = "+proj=" * _prj)); O.proj4 = _prj)
	(wkt != "") && (O.wkt = wkt)
	(epsg > 0)  && (O.epsg = epsg)		# Here we should be testing that the epsg code is a valide one
	return nothing
end
const setcrs! = setsrs!

# ---------------------------------------------------------------------------------------------------
"""
    setcoords!(GI::GItype; x::Vector{<:Real}=Float64[], y::Vector{<:Real}=Float64[], registration::Int=0)

Assign x,y coordinates to a GMTgrid or GMTimage. The `x,y` arguments are mandatory and can be two elements
vectors with [xmin, xmax] and [ymin, ymax] respectively or vectors with ncolumns and nrows if `registration=0`
or with ncolumns+1 and nrows+1 if `registration=1`.

### Return
This function returns nothing as what it does is to change the object coordinates information. See also
the `setsrs!` function.
"""
function setcoords!(GI::GItype; x::Vector{<:Real}=Float64[], y::Vector{<:Real}=Float64[], registration::Int=0)
	isempty(x) || isempty(y) && error("X and/or Y coordinates vectors are empty")
	nx = (GI.layout != "" && GI.layout[2] == 'C') ? size(GI,2) : (GI.layout != "" && GI.layout[2] == 'R') ? size(GI,1) : size(GI,2)
	ny = (GI.layout != "" && GI.layout[2] == 'C') ? size(GI,1) : (GI.layout != "" && GI.layout[2] == 'R') ? size(GI,2) : size(GI,1)
	(length(x) == nx || length(x) == nx-1) ? (GI.x = x) : (length(x) == 2 ? (GI.x = linspace(x[1], x[2], nx+registration)) :
		error("X coordinates vector should have length of 2 or $(nx) or $(nx-1)"))
	(length(y) == ny || length(y) == ny-1) ? (GI.y = y) : (length(y) == 2 ? (GI.y = linspace(y[1], y[2], nx+registration)) :
		error("Y coordinates vector should have length of 2 or $(ny) or $(ny-1)"))
	GI.range[1:4] = [GI.x[1], GI.x[end], GI.y[1], GI.y[end]]
	GI.inc[1:2]   = [GI.x[2] - GI.x[1], GI.y[2] - GI.y[1]]
	GI.registration = (length(GI.x) == nx) ? 0 : 1
	return nothing
end
