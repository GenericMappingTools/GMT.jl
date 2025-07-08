"""
    function loxodrome_inverse(lon1, lat1, lon2, lat2, a=6378137.0, f=0.0033528106647474805)

Compute the inverse problem of a loxodrome on the ellipsoid.

Given latitudes and longitudes of P1 and P2 on the ellipsoid, compute the azimuth a12 of
the loxodrome P1P2, the arc length s along the loxodrome curve.

Args:

- `lon1, lat1, lon2, lat2`: - longitude and latitude of starting and end points (degrees).
- `a` - major axis of the ellipsoid (meters). Default values for WGS84
- `f` - flattening od the ellipsoid (default = 1 / 298.257223563)

### References:
- [The Loxodrome on an Ellipsoid](http://www.mygeodesy.id.au/documents/Loxodrome%20on%20Ellipsoid.pdf)

### Returns
- Distance (meters) and azimuth from P1 to P2

## Example: Compute the distance and azimuth beyween points (0,0) and (5,5)

    dist, azim = loxodrome_inverse(0,0,5,5)
"""
function loxodrome_inverse(lon1, lat1, lon2, lat2, a=6378137.0, f=0.0033528106647474805)
	D2R = pi / 180
	lon1 *= D2R;	lat1 *= D2R
	lon2 *= D2R;	lat2 *= D2R
	e2 = f * (2 - f)

	isolat1 = isometric_lat(lat1, e2)
	isolat2 = isometric_lat(lat2, e2)
	
	# Compute changes in isometric latitude and longitude between P1 and P2
	Az12 = atan((lon2 - lon1), (isolat2 - isolat1))		# The azimuth
	# Compute distance along loxodromic curve
	m1 = meridian_dist(lat1, a, e2)
	m2 = meridian_dist(lat2, a, e2)
	lox_s = (m2 - m1) / cos(Az12);
	return lox_s, Az12 / D2R
end

# -------------------------------------------------------------------------------------------------------
"""
    loxodrome_direct(lon, lat, azimuth, distance, a=6378137.0, f=0.0033528106647474805)

Compute the direct problem of a loxodrome on the ellipsoid.

Given latitude and longitude of P1, azimuth a12 of the loxodrome P1P2 and the arc length s along the
loxodrome curve, compute the latitude and longitude of P2.

Args:

- `lon, lat`: - longitude, latitude (degrees) of starting point.
- `azimuth`:  - azimuth (degrees)
- `distance`: - distance to move from (lat,lon) in meters
- `a` - major axis of the ellipsoid (meters). Default values for WGS84
- `f` - flattening od the ellipsoid (default = 1 / 298.257223563)

### References:
- [The Loxodrome on an Ellipsoid](http://www.mygeodesy.id.au/documents/Loxodrome%20on%20Ellipsoid.pdf)

### Returns
- [lon lat] of destination after moving for [distance] metres in [azimuth] direction.

## Example: Compute the end point at a bearing of 45 degrees 10000 meters from point 0,0

    loxo = loxodrome_direct(0,0,45, 10000)
"""
function loxodrome_direct(lon, lat, azim, dist, a=6378137.0, f=0.0033528106647474805)
	(rem(azim, 90) == 0) && (azim -= 0.0001)	# Equator is a degenerated case. Comparing with GeographicLib sows 4 dec is ~good
	D2R = pi / 180
	lon *= D2R;		lat *= D2R;		azim *= D2R
	e2 = f * (2 - f)
	m1 = meridian_dist(lat, a, e2)
	m2 = dist * cos(azim) + m1

	A0, A2, A4, A6, A8, A10 = f_phi_coeff(e2)
	ae2 = a * (1 - e2)
	phi_n, dphi = lat, 1e3
	n = 0
	while (dphi > 1e-10 && n < 6)
		phi_n1 = phi_n - (ae2 * f_phi(phi_n, A0, A2, A4, A6, A8, A10) - m2) / (ae2 * f_prime_phi(phi_n, A0, A2, A4, A6, A8, A10))
		dphi = abs(phi_n1 - phi_n)
		phi_n = phi_n1
		n += 1
	end

	pi2 = pi/2
	if (-pi2 <= phi_n <= pi2)		# For long dist we may have out off bounds lats
		isolat1 = isometric_lat(lat, e2)
		isolat2 = isometric_lat(phi_n, e2)
		dlon = (isolat2 - isolat1) * tan(azim)
		lon2 = lon + dlon
		return [lon2/D2R phi_n/D2R]
	else
		return [NaN NaN]
	end
end

function f_phi(lat, A0, A2, A4, A6, A8, A10)
	A0*lat - (A2/2)*sin(2*lat) + (A4/4)*sin(4*lat) - (A6/6)*sin(6*lat) + (A8/8)*sin(8*lat) - (A10/10)*sin(10*lat)
end

function f_prime_phi(lat, A0, A2, A4, A6, A8, A10)
	A0 - A2 * cos(2*lat) + A4 * cos(4*lat) - A6 * cos(6*lat) + A8 * cos(8*lat) - A10 * cos(10*lat)
end

function meridian_dist(lat, a, e2)
	A0, A2, A4, A6, A8, A10 = f_phi_coeff(e2)
	a*(1-e2) * f_phi(lat, A0, A2, A4, A6, A8, A10)
end

function f_phi_coeff(e2)
	e4 = e2*e2;			# powers of eccentricity
	e6 = e4*e2;
	e8 = e6*e2;
	e10 = e8*e2;
	# coefficients of series expansion for meridian distance
	A0 = 1 + (3/4)*e2 + (45/64)*e4 + (175/256)*e6 + (11025/16384)*e8 + (43659/65536)*e10
	A2 =     (3/4)*e2 + (15/16)*e4 + (525/512)*e6 + (2205/2048)*e8   + (72765/65536)*e10
	A4 =                (15/64)*e4 + (105/256)*e6 + (2205/4096)*e8   + (10395/16384)*e10
	A6 =                             (35/512)*e6  + (315/2048)*e8    + (31185/131072)*e10
	A8 =                                            (315/16384)*e8   + (3465/65536)*e10
	A10 =                                                              (693/131072)*e10
	return A0, A2, A4, A6, A8, A10
end

function isometric_lat(lat, ecc2)
	# Compute isometric latitude. ECC2 is the squared eccentricity = f*(2-f), where f is the flattening
	ecc = sqrt(ecc2)
	x = ecc * sin(lat)
	y = (1-x) / (1+x)
	z = pi/4 + lat/2
	log(tan(z) * (y^(ecc/2)))
end