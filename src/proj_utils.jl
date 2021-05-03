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
const PJ_CONTEXT = Cvoid
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

"""
    proj_create(const char * text, PJ_CONTEXT * ctx) -> PJ *

Instantiate an object from a WKT string, PROJ string or object code (like "EPSG:4326", "urn:ogc:def:crs:EPSG::4326", "urn:ogc:def:coordinateOperation:EPSG::1671").

### Parameters
* **text**: String (must not be NULL)
* **ctx**: PROJ context, or NULL for default context

### Returns
Object that must be unreferenced with proj_destroy(), or NULL in case of error.
"""
proj_create(defn, ctx=C_NULL) = ccall((:proj_create, libproj), Ptr{Cvoid}, (Ptr{Cvoid}, Cstring), ctx, defn)
proj_destroy(P) = ccall((:proj_destroy, libproj), Ptr{Cvoid}, (Ptr{Cvoid},), P)
proj_info() = ccall((:proj_info, libproj), PJ_INFO, ())

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
    A3x::Cdouble6
    C3x::Cdouble15
    C4x::Cdouble21

	geod_geodesic() = new()
end

function geod_geodesic(a::Cdouble, f::Cdouble)
	geod = geod_geodesic()
	ccall((:geod_init, libproj), Cvoid, (Ptr{Cvoid}, Cdouble, Cdouble), pointer_from_objref(geod), a, f)
	geod
end

function _geod(projPJ_ptr::Ptr{Cvoid})
	a, ecc2 = pj_get_spheroid_defn(projPJ_ptr)
	geod_geodesic(a, 1-sqrt(1-ecc2))
end

function geod_direct(position::Vector{<:Real}, azim, distance, proj::String="")
	proj_string = (proj == "") ? "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs" : proj
	projPJ_ptr = proj_create(proj_string)
	#xy2lonlat!(position, proj)
	dest, azi = _geod_direct!(_geod(projPJ_ptr), copy(position), azim, distance)
	_geod_direct!(_geod(projPJ_ptr), copy(position), azim, distance)
	#lonlat2xy!(dest, proj), azi
	proj_destroy(projPJ_ptr)
	return dest, azi
end

function _geod_direct!(geod::geod_geodesic, lonlat::Vector{<:Real}, azim, distance)
	p = pointer(lonlat)
	azi = Ref{Cdouble}()		# the (forward) azimuth at the destination
	ccall((:geod_direct, libproj), Cvoid, (Ptr{Cvoid},Cdouble,Cdouble,Cdouble,Cdouble,Ptr{Cdouble},Ptr{Cdouble}, Ptr{Cdouble}),
	      pointer_from_objref(geod), lonlat[2], lonlat[1], azim, distance, p+sizeof(Cdouble), p, azi)
	lonlat, azi[]
end

function geod_inverse(lonlat1::Vector{Float64}, lonlat2::Vector{Float64}, proj::String="")
	proj_string = (proj == "") ? "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs" : proj
	projPJ_ptr = proj_create(proj_string)
	#_geod_inverse(_geod(proj), xy2lonlat(lonlat1, proj), xy2lonlat(lonlat2, proj))
	dist, azi1, azi2 = Ref{Cdouble}(), Ref{Cdouble}(), Ref{Cdouble}()
	ccall((:geod_inverse, libproj), Cvoid, (Ptr{Cvoid},Cdouble,Cdouble,Cdouble, Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble}),
	      pointer_from_objref(_geod(projPJ_ptr)), lonlat1[2], lonlat1[1], lonlat2[2], lonlat2[1], dist, azi1, azi2)
	proj_destroy(projPJ_ptr)
	return dist[], azi1[], azi2[]
end

#=
function pj_init_plus(proj_string::String)
    projPJ_ptr = ccall((:pj_init_plus, libproj), Ptr{Cvoid}, (Cstring,), proj_string)
    (projPJ_ptr == C_NULL) && error("Could not parse projection: \"$proj_string\": $(_strerrno())")
    projPJ_ptr		# To be freed with proj_destroy()
end

function pj_free(projPJ_ptr::Ptr{Cvoid})	# Free C datastructure associated with a projection.
    @assert projPJ_ptr != C_NULL
    ccall((:pj_free, libproj), Cvoid, (Ptr{Cvoid},), projPJ_ptr)
end
=#

"""
Fetch the internal definition of the spheroid as a tuple (a, ecc2), where

    a = major_axis
    ecc2 = eccentricity squared
"""
function pj_get_spheroid_defn(proj_ptr::Ptr{Cvoid})
    a = Ref{Cdouble}()		# major_axis
    ecc2 = Ref{Cdouble}()	# eccentricity squared
    ccall((:pj_get_spheroid_defn, libproj), Cvoid, (Ptr{Cvoid}, Ptr{Cdouble}, Ptr{Cdouble}), proj_ptr, a, ecc2)
    a[], ecc2[]
end

# Get human readable error string from proj.4 error code
_strerrno(code::Cint) = unsafe_string(ccall((:pj_strerrno, libproj), Cstring, (Cint,), code))

# Get global errno string in human readable form
_strerrno() = _strerrno(_errno())

# Get error number
_errno() = unsafe_load(ccall((:pj_get_errno_ref, libproj), Ptr{Cint}, ()))
