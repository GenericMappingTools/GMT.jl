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

"""
    GI[,coast] = worldrectangular(GI; proj::String="+proj=vandg", pm=0, latlim=:auto, coast=false)

Try to createa rectangular map out miscellaneous and not cylindrical projections.

- `GI`: A GMTgrid or GMTimage data type. `GI` can also be a string with a file name of a grid or image.
- `proj`: A PROJ4 string describing the projection.
- `pm`: The projection prime meridian (Default is 0).
- `latlim or latlims`: Latitude(s) at which the rectangular map is trimmed. The default (:auto) means
   that we will try to trim such that we get a fully filled grid/image. Use `latlim=(lat_s,lat_n)` or
   `latlim=lat` to make it equivalent to `latlim=(-lat,lat)`.
- `coast`: Return also the coastlines projected with `proj`. Pass `coast=res`, where `res` is one of
   GMT coastline resolutions (*e.g.* :crude, :low, :intermediate). `coast=true` is <==> `coast=:crude`

### Returns
A grid or an image and optionaly the coastlines ... or errors. Not many projections support the procedure
implemented in this function.
The working or not is controlled by PROJ's `+over` option https://proj.org/usage/projections.html#longitude-wrapping

### Example:
   G = worldrectangular("@earth_relief_10m_g")
   imshow(G)
"""
# -----------------------------------------------------------------------------------------------
worldrectangular(fname::String; proj::String="+proj=vandg +over", pm=0, latlim=:auto, latlims=nothing, pad=90, coast=false) =
	worldrectangular(gmtread(fname); proj=proj, pm=pm, latlim=latlim, latlims=latlims, pad=pad, coast=coast)
function worldrectangular(GI; proj::String="+proj=vandg +over", pm=0, latlim=:auto, latlims=nothing, pad=90, coast=false)
	# Here test if G is global
	(latlim === nothing && latlims !== nothing) && (latlim = latlims)	# To accept both latlim & latlims
	autolat = false
	isa(latlim, StrSymb) && (autolat = true; latlim = nothing)
	_latlim = (latlim === nothing) ? (-90,90) : (isa(latlim, Real) ? (-latlim, latlim) : extrema(latlim))
	(_latlim[1] < -90 || _latlim[2] > 90) && error("Don't kidd, latlim does not have real latitude limits.")
	!startswith(proj, "+proj=") && (proj = "+proj=" * proj)
	!contains(proj, " +over") && (proj *= " +over")
	(pm > 180) && (pm -= 360);		(pm < -180) && (pm += 360)
	sw = pad	# This is an attempt to let try minimize the empties that may occur in the corners for some projs
	res = (isa(coast, Symbol) || isa(coast, String)) ? string(coast) : (coast == 1 ? "crude" : "none")

	if (pm > -90)
		Gr = grdcut(GI, R=(-180,-180+sw+pm,-90,90))			# Chop of 90 deg on the West
		Gr.range[1], Gr.range[2] = 180, 180+sw+pm		# and pretend it is beyound 180
	end
	if (-90 < pm < 90)
		Gl = grdcut(GI, R=(180-sw+pm,180,-90,90))
		Gl.range[1], Gl.range[2] = -180-sw+pm, -180
		G = grdpaste(Gl,GI)
		G = grdpaste(G,Gr)
	elseif (pm >= 90)		# For PADs > 90 this case is not working well
		G = grdcut(GI, R=(-180+pm-90,180,-90,90))
		G = grdpaste(G,Gr)
	else	# <= -90
		d = 90 + pm		#  d < 0
		Gr = grdcut(GI, R=(-180,180+d,-90,90))
		Gl = grdcut(GI, R=(0+d,180,-90,90))
		Gl.range[1], Gl.range[2] = -360+d, -180
		G = grdpaste(Gl,Gr)
	end
	(pm != 0) && (proj *= " +pm=$pm")
	G = gdalwarp(G, ["-t_srs", proj])

	xy = lonlat2xy([-180.0+pm 0; 180+pm 0], t_srs=proj)
	pix_x = axes2pix(xy, size(G), [G.x[1], G.x[end]], [G.y[1], G.y[end]], G.registration, G.layout)[1]
	if (autolat)
		t = G[pix_x[1], :]		# The column corresponding to lon = -180
		kt = length(t) + 1;		while(isnan(t[kt -= 1]) && kt > 1) end
		kb = 0;					while(isnan(t[kb += 1]) && kb < length(t)) end
		yb, yt = G.y[kb], G.y[kt]
	else
		xy = lonlat2xy([-180.0+pm _latlim[1]; 180+pm _latlim[2]], t_srs=proj)
		_pix_x, _pix_y = axes2pix(xy, size(G), [G.x[1], G.x[end]], [G.y[1], G.y[end]], G.registration, G.layout)
		yc = pix2axes([_pix_x _pix_y], G.x, G.y)[2]
		yb, yt = yc[1], yc[2]
	end

	G = grdcut(G, R=(G.x[pix_x[1]], G.x[pix_x[2]], yb, yt))
	@show(res)
	return coast != "none" ? (G, worldrectcoast(proj, res)) : G
end

# -----------------------------------------------------------------------------------------------
function worldrectcoast(proj::String, res)
	# Project also the coastlines to go along with the grid created by worldrectangular
	cl = coast(dump=:true, res=res, region=:global)
	#cl_right = coast(dump=:true, res=res, region=(-180,0,-90,90)) .+ 360	# Good try but some points screw
	#cl_left  = coast(dump=:true, res=res, region=(0,180,-90,90)) .- 360
	cl_right = cl .+ 360
	cl_left  = cl .- 360
	cl_vdg   = lonlat2xy(cl, t_srs=proj)
	cl_right_vdg = lonlat2xy(cl_right, t_srs=proj)
	cl_left_vdg  = lonlat2xy(cl_left, t_srs=proj)
	tmp = cat(cl_left_vdg, cl_vdg)
	cat(tmp, cl_right_vdg)
end
