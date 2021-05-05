@static Sys.iswindows() ?
	(Sys.WORD_SIZE == 64 ? (const libproj = "proj_w64") : (const libproj = "proj_w32")) : 
	(
		Sys.isapple() ? (const libproj = Symbol(split(readlines(pipeline(`otool -L $gmtlib`, `grep libproj`))[1])[1])) :
		(
		    Sys.isunix() ? (const libproj = Symbol(split(readlines(pipeline(`ldd $gmtlib`, `grep libproj`))[1])[3])) :
			error("Don't know how to install this package in this OS.")
		)
	)


const PJ_LOG_FUNCTION = Ptr{Cvoid}
const PJ = Cvoid

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

struct Cdouble6
    x1::Cdouble
    x2::Cdouble
    x3::Cdouble
    x4::Cdouble
    x5::Cdouble
    x6::Cdouble
end

struct Cdouble15
    x1::Cdouble
    x2::Cdouble
    x3::Cdouble
    x4::Cdouble
    x5::Cdouble
    x6::Cdouble
    x7::Cdouble
    x8::Cdouble
    x9::Cdouble
    x10::Cdouble
    x11::Cdouble
    x12::Cdouble
    x13::Cdouble
    x14::Cdouble
    x15::Cdouble
end

struct Cdouble21
    x1::Cdouble
    x2::Cdouble
    x3::Cdouble
    x4::Cdouble
    x5::Cdouble
    x6::Cdouble
    x7::Cdouble
    x8::Cdouble
    x9::Cdouble
    x10::Cdouble
    x11::Cdouble
    x12::Cdouble
    x13::Cdouble
    x14::Cdouble
    x15::Cdouble
    x16::Cdouble
    x17::Cdouble
    x18::Cdouble
    x19::Cdouble
    x20::Cdouble
    x21::Cdouble
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

    # Arrays of parameters must be expanded manually,
    # currently (either inline, or in an immutable helper-type)
    # In the future, some of these restrictions may be reduced/eliminated.
    #A3x::Cdouble6
    #C3x::Cdouble15
    #C4x::Cdouble21

    A3x::NTuple{6, Cdouble}
    C3x::NTuple{15,Cdouble}
    C4x::NTuple{21,Cdouble}

	geod_geodesic() = new()
end

function geod(lonlat::Vector{<:Real}, azim, distance; proj::String="", s_srs::String="", epsg::Integer=0, dataset=false, unit=:m)
	f = 1.0
	if (unit != :m)
		_u = lowercase(string(unit))		# Parse the units arg
		f = (_u[1] == 'k') ? 1000. : ((_u[1] == 'n') ? 1852.0 : (startswith(_u, "mi") ? 1600.0 : 1.0))
	end
	(unit != :m && f == 1.0) && @warn("Unknown unit ($_u). Ignoring it")

	isa(distance, AbstractRange) && (distance = collect(distance))
	proj_string, projPJ_ptr, isgeog = helper_geod(proj, s_srs, epsg)
	dest, azi = helper_gdirect(projPJ_ptr, lonlat, azim, distance, proj_string, isgeog, dataset, epsg, f)
	proj_destroy(projPJ_ptr)
	return dest, azi
end

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
	(!isgeog) && (lonlat = xy2lonlat(lonlat, proj_string))		# Need to convert to geogd first
	ggd = get_ellipsoid(projPJ_ptr)
	if (isa(azim, Real) && isa(dist, Real))						# One line only with one end-point
		dest, azi = _geod_direct!(get_ellipsoid(projPJ_ptr), copy(lonlat), azim, dist*f)
		(!isgeog) && (dest = lonlat2xy(dest, proj_string))
		(dataset) && (dest = helper_gdirect_SRS(dest, proj_string, epsg, wkbPoint))
	elseif (isa(azim, Real) && isvector(dist))	# One line only with several points along it
		dest, azi = Array{Float64}(undef, length(dist), 2), Vector{Float64}(undef, length(dist))
		for k = 1:length(dist)
			d, azi[k] = _geod_direct!(ggd, copy(lonlat), azim, dist[k]*f)
			dest[k, :] = (isgeog) ? d : lonlat2xy(d, proj_string)
		end
		(dataset) && (dest = helper_gdirect_SRS([dest azi], proj_string, epsg, wkbLineString))		# Return a GMTdataset
	elseif (isvector(azim) && isvector(dist))			# multi-lines with variable length and/or number of points
		n_lines = length(azim)							# Number of lines
		(!isa(dist, Vector) && !isa(dist, Vector{<:Vector})) && error("The 'distances' input MUST be a Vector or a Vector{Vector}")
		if (!isa(dist, Vector{<:Vector}))				# If not, make it a Vector{Vector} to use the same algo below
			isa(dist, Matrix) && (dist = vec(dist))		# Because we accepted also 1-row or 1-col matrices
			Vdist = Vector{Vector{Float64}}(undef, n_lines)
			[Vdist[k] = dist for k = 1:n_lines]
		else
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
			helper_gdirect_SRS(dest, proj_string, epsg, wkbLineString, D[nl])	# Just assign the SRS
		end
		return D, nothing		# Here both the point coordinates and the azim are in the GMTdataset
	else
		error("'azimuth' MUST be either a scalar or a 1-dim array, and 'distance' may also be a Vector{Vector}")
	end
	return dest, azi
end

function helper_gdirect_SRS(mat, proj_string::String, epsg::Integer, geom, D=GMTdataset())
	# Convert the output of geod_direct into a GMTdataset and, if possible, assign it a SRS
	# If a 'D' is sent in, we only (eventually) assign it an SRS
	isempty(D) && (D = GMTdataset([mat[1] mat[2]], Vector{String}(), "", Vector{String}(), "", "", geom))
	if     (startswith(proj_string, "+proj"))   D.proj4 = proj_string
	elseif (startswith(proj_string, "GEOGCS"))  D.wkt = proj_string
	elseif (epsg > 2000)                        D.proj4 = toPROJ4(Gdal.importEPSG(epsg))
	end
	D
end

function _geod_direct!(geod::geod_geodesic, lonlat::Vector{<:Real}, azim, distance)
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
	elseif (epsg > 0)     prj_string = @sprintf("EPSG=%d", epsg)
	else                  prj_string = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
	end
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

proj_info() = ccall((:proj_info, libproj), PJ_INFO, ())

function proj_create(proj_string::String, ctx=C_NULL)
	# Returns an Object that must be unreferenced with proj_destroy()
    projPJ_ptr = ccall((:proj_create, libproj), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring), ctx, proj_string)
    (projPJ_ptr == C_NULL) && error("Could not parse projection: \"$proj_string\":")
    projPJ_ptr
end

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