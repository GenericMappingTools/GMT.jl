"""
Convert from geodetic coordinates to local East, North, Up (ENU) coordinates.
"""
function geodetic2enu(lon, lat, h, lon0, lat0, h0)
	#
	D1 = mapproject([lon lat h], geod2ecef=true);
	D0 = mapproject([lon0 lat0 h0], geod2ecef=true);
	d  = D1.data .- D0.data;
	xEast, yNorth, zUp = ecef2enuv(view(d, :, 1), view(d, :, 2), view(d, :, 3), lon0, lat0)
end

function ecef2enuv(u, v, w, lon0, lat0)
	# Adapted from Octave, that adapted from anonymous contributor that probably adapted from Matlab
	t     =  cosd(lon0) .* u + sind(lon0) .* v;
	east  = -sind(lon0) .* u + cosd(lon0) .* v;
	up    =  cosd(lat0) .* t + sind(lat0) .* w;
	north = -sind(lat0) .* t + cosd(lat0) .* w;
	return east, north, up
end