# File from Geodesy.jl

"""
An ellipsoidal representation of the Earth, for converting between LLA and
other co-ordinate systems such as ECEF.
"""
struct Ellipsoid
	a::Float64        # Semi-major axis
	b::Float64        # Semi-minor axis
	f::Float64        # Flattening
	e2::Float64       # Eccentricity squared
	name::Symbol      # Conventional name
end

function Ellipsoid(; a::String="", b::String="", f_inv::String="", name=:UNKNOWN)
	(isempty(a) || isempty(b) == isempty(f_inv)) && throw(ArgumentError("Specify parameter 'a' and either 'b' or 'f_inv'"))
	if isempty(b)  _ellipsoid_af(parse(Float64, a), parse(Float64, f_inv), name)
	else           _ellipsoid_ab(parse(Float64, a), parse(Float64, b), name)
	end
end

function _ellipsoid_ab(a::Float64, b::Float64, name)
	f = 1 - b/a
	e2 = f*(2-f)
	Ellipsoid(a, b, f, e2, name)
end
function _ellipsoid_af(a::Float64, f_inv::Float64, name)
	b = a * (1 - inv(f_inv))
	_ellipsoid_ab(a, b, name)
end

function Base.show(io::IO, el::Ellipsoid)
	if el.name != :UNKNOWN
		# To clarify that these are Ellipsoids, we wrap the name in 'Ellipsoid',
		# even though the name itself should resolve to the correct ellipsoid instance.
		print(io, "Ellipsoid($(el.name))")
	else
		print(io, "Ellipsoid(a=$(el.a), b=$(el.b))")
	end
end

#-------------------------------------------------------------------------------
# Standard ellipsoids

# Worldwide
const WGS84_ellps = Ellipsoid(a = "6378137.0", f_inv = "298.257223563", name=:WGS84_ellps)
const GRS80_ellps = Ellipsoid(a = "6378137.0", f_inv = "298.2572221008827112431628366", name=:GRS80_ellps) #NB: not the definition - f_inv is derived.

# Regional
#const airy1830   = Ellipsoid(a = "6377563.396", b = "6356256.909", name=:airy1830)
#const clarke1866 = Ellipsoid(a = "6378206.4",   b = "6356583.8", name=:clarke1866)

ellipsoid(x) = error("No ellipsoid defined for datum $x")
