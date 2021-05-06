# Functions in this file have derived from some in the PROJ4.jl pacakge https://github.com/JuliaGeo/Proj4.jl
# so part of the credit goes also for the authors of that package but the main function, "geod" was highly
# modified and does a lot more than the proj4 'geod' model.

@static Sys.iswindows() ?
	(Sys.WORD_SIZE == 64 ? (const libproj = "proj_w64") : (const libproj = "proj_w32")) : (
		Sys.isapple() ? (const libproj = Symbol(split(readlines(pipeline(`otool -L $(GMT.thelib)`, `grep libproj`))[1])[1])) : (
			Sys.isunix() ? (const libproj = Symbol(split(readlines(pipeline(`ldd $(GMT.thelib)`, `grep libproj`))[1])[3])) :
			error("Don't know how to use PROJ4 in this OS.")
		)
	)

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

mutable struct geod_geodesic
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
	f = 1.0
	if (unit != :m)
		_u = lowercase(string(unit))		# Parse the units arg
		f = (_u[1] == 'k') ? 1000. : ((_u[1] == 'n') ? 1852.0 : (startswith(_u, "mi") ? 1600.0 : 1.0))
	end
	(unit != :m && f == 1.0) && @warn("Unknown unit ($_u). Ignoring it")
	isa(distance, AbstractRange) && (distance = collect(Float64, distance))

	proj_string, projPJ_ptr, isgeog = helper_geod(proj, s_srs, epsg)
	dest, azi = helper_gdirect(projPJ_ptr, lonlat, azim, distance, proj_string, isgeog, dataset, epsg, f)
	proj_destroy(projPJ_ptr)
	return dest, azi
end

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
function invgeod(lonlat1::Vector{<:Real}, lonlat2::Vector{<:Real}; proj::String="", s_srs::String="", epsg::Integer=0)
	proj_string, projPJ_ptr, isgeog = helper_geod(proj, s_srs, epsg)
	(!isgeog) && (lonlat1 = xy2lonlat(lonlat1, proj_string);	lonlat2 = xy2lonlat(lonlat2, proj_string))	# Convert to geogd first
	dist, azi1, azi2 = Ref{Cdouble}(), Ref{Cdouble}(), Ref{Cdouble}()
	ccall((:geod_inverse, libproj), Cvoid, (Ptr{Cvoid},Cdouble,Cdouble,Cdouble, Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble}),
		  pointer_from_objref(get_ellipsoid(projPJ_ptr)), lonlat1[2], lonlat1[1], lonlat2[2], lonlat2[1], dist, azi1, azi2)
	proj_destroy(projPJ_ptr)
	return dist[], azi1[], azi2[]
end

function helper_gdirect(projPJ_ptr, lonlat, azim, dist, proj_string, isgeog, dataset, epsg, f)
	lonlat = Float64.(lonlat)
	(!isgeog) && (lonlat = xy2lonlat(lonlat, proj_string))		# Need to convert to geogd first
	ggd = get_ellipsoid(projPJ_ptr)
	
	(isvector(azim) && isa(dist, Real)) && (dist = [dist,])		# multi-points. Just make 'dist' a vector to reuse a case below 

	if (isa(azim, Real) && isa(dist, Real))						# One line only with one end-point
		dest, azi = _geod_direct!(get_ellipsoid(projPJ_ptr), copy(lonlat), azim, dist*f)
		(!isgeog) && (dest = lonlat2xy(dest, proj_string))
		(dataset) && (dest = helper_gdirect_SRS(dest, proj_string, wkbPoint))
	elseif (isa(azim, Real) && isvector(dist))			# One line only with several points along it
		dest, azi = Array{Float64}(undef, length(dist), 2), Vector{Float64}(undef, length(dist))
		for k = 1:length(dist)
			d, azi[k] = _geod_direct!(ggd, copy(lonlat), azim, dist[k]*f)
			dest[k, :] = (isgeog) ? d : lonlat2xy(d, proj_string)
		end
		(dataset) && (dest = helper_gdirect_SRS([dest azi], proj_string, wkbLineString))		# Return a GMTdataset
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
				d, azi = _geod_direct!(ggd, copy(lonlat), azim[nl], Vdist[nl][np]*f)
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

function helper_gdirect_SRS(mat, proj_string::String, geom, D=GMTdataset())
	# Convert the output of geod_direct into a GMTdataset and, if possible, assign it a SRS
	# If a 'D' is sent in, we only (eventually) assign it an SRS
	isempty(D) && (D = GMTdataset([mat[1] mat[2]], Vector{String}(), "", Vector{String}(), "", "", geom))
	if     (startswith(proj_string, "+proj"))  D.proj4 = proj_string
	end
	D
end

function _geod_direct!(geod::geod_geodesic, lonlat::Vector{Float64}, azim, distance)
	p = pointer(lonlat)
	azi = Ref{Cdouble}()		# the (forward) azimuth at the destination
	ccall((:geod_direct, libproj), Cvoid, (Ptr{Cvoid},Cdouble,Cdouble,Cdouble,Cdouble,Ptr{Cdouble},Ptr{Cdouble}, Ptr{Cdouble}),
		  pointer_from_objref(geod), lonlat[2], lonlat[1], azim, distance, p+sizeof(Cdouble), p, azi)
	lonlat, azi[]
end

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

function geod_geodesic(a::Cdouble, f::Cdouble)::geod_geodesic
	geod = geod_geodesic()
	ccall((:geod_init, libproj), Cvoid, (Ptr{Cvoid}, Cdouble, Cdouble), pointer_from_objref(geod), a, f)
	geod
end

function get_ellipsoid(projPJ_ptr::Ptr{Cvoid})::geod_geodesic
	a, ecc2 = pj_get_spheroid_defn(projPJ_ptr)
	geod_geodesic(a, 1-sqrt(1-ecc2))
end

function proj_create(proj_string::String, ctx=C_NULL)
	# Returns an Object that must be unreferenced with proj_destroy()
	projPJ_ptr = ccall((:proj_create, libproj), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring), ctx, proj_string)
	(projPJ_ptr == C_NULL) && error("Could not parse projection: \"$proj_string\"")
	projPJ_ptr
end

proj_create_crs_to_crs(s_crs, t_crs, area, ctx=C_NULL) =
	ccall((:proj_create_crs_to_crs, libproj), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring, Cstring, Ptr{Cvoid}), ctx, s_crs, t_crs, area)

function proj_destroy(projPJ_ptr::Ptr{Cvoid})	# Free C datastructure associated with a projection.
	@assert projPJ_ptr != C_NULL
	ccall((:proj_destroy, libproj), Ptr{Cvoid}, (Ptr{Cvoid},), projPJ_ptr)
end

function pj_get_spheroid_defn(proj_ptr::Ptr{Cvoid})
	a = Ref{Cdouble}()		# major_axis
	ecc2 = Ref{Cdouble}()	# eccentricity squared
	ccall((:pj_get_spheroid_defn, libproj), Cvoid, (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}), proj_ptr, a, ecc2)
	a[], ecc2[]
end

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
=#

function is_latlong(proj_ptr::Ptr{Cvoid})
	@assert proj_ptr != C_NULL
	ccall((:pj_is_latlong, libproj), Cint, (Ptr{Cvoid},), proj_ptr) != 0
end