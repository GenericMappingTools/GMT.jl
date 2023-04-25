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
function worldrectangular(GI::GItype; proj::String="+proj=vandg +over", pm=0, latlim=:auto, latlims=nothing, pad=90, coast=false)
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
	return res != "none" ? (G, worldrectcoast(proj, res)) : G
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

# -----------------------------------------------------------------------------------------------
function worldrectgrid(proj::String, inc=(30,20), pm=0)
	# Create a grid of lines in 'proj' coordinates. Input are meridians and parallels at steps
	# determined by 'inc' and centered at 'pm'. 'pm' can be transmitted via argument or contained in 'proj'
	(contains(proj, "+pm=")) && (pm = parse(Float64,string(split(split("+proj=vandg +pm=9 +over", "+pm=")[2])[1])))
	(pm != 0 && !contains(proj, "+pm=")) && (proj *= " +pm=$pm")
	(!contains(proj, "+over")) && (proj *= " +over")
	inc_x, inc_y = (length(inc) == 2) ? (inc[1], inc[2]) : (inc, inc)

	meridians = -180-60+pm:inc_x:180+60+pm
	meridian  = [(-90:2:-70); (-75:5:65); (70:2:90)]
	t = collect(0:-inc_y:-90)
	parallels = [t[end]:inc_y:t[2]; 0:inc_y:90]		# To center it on 0
	parallel  = -180-60+pm:10:180+60+pm

	Dgrid = Vector{GMTdataset}(undef, length(meridians)+length(parallels))
	n = 0
	for m = meridians
		Dgrid[n+=1] = mat2ds(lonlat2xy([fill(m,length(meridian)) meridian], t_srs=proj), attrib=Dict("merid_b" => "$m,-90", "merid_e" => "$m,90"))
	end
	for p = parallels
		Dgrid[n+=1] = mat2ds(lonlat2xy([parallel fill(p, length(parallel))], t_srs=proj), attrib=Dict("para_b" => "$p,$(parallel[1])", "para_e" => "$p,$(parallel[end])"))
	end
	Dgrid[1].attrib["n_meridians"] = "$(length(meridians))"
	Dgrid[1].attrib["n_parallels"] = "$(length(parallels))"
	return Dgrid

	#=
	Dlons = Vector{GMTdataset}(undef,length(-270:inc_x:270))
	n = 0
	for k = -270:inc_x:270
		Dlons[n+=1] = mat2ds([fill(k,19) -90:10:90'])
	end
	Dlats = Vector{GMTdataset}(undef,length(-90:inc_y:90))
	n = 0
	for k = -90:inc_y:90
		Dlats[n+=1] = mat2ds([-270:10:270' fill(k,55)])
	end
	x = lonlat2xy(Dlons, t_srs=proj)
	y = lonlat2xy(Dlats, t_srs=proj)
	x, y
	=#
end

# -----------------------------------------------------------------------------------------------
function plotgrid!(GI::GItype, Dgrid::Vector{<:GMTdataset})
	bot = [GI.range[1] GI.range[3]; GI.range[2] GI.range[3]]
	top = [GI.range[1] GI.range[4]; GI.range[2] GI.range[4]]
	n_meridians = parse(Int16, Dgrid[1].attrib["n_meridians"])
	n_parallels = parse(Int16, Dgrid[1].attrib["n_parallels"])
	lon_b, lon_t = Matrix{Float64}(undef, n_meridians,2), Matrix{Float64}(undef, n_meridians,2)
	for k = 1:n_meridians
		t = gmtspatial((Dgrid[k], bot), intersections=:e)[1,1:2]
		lon_b[k,2], lon_b[k,1] = round(xy2lonlat(t, s_srs=GI.proj4)[1], digits=0), t[1]
		t = gmtspatial((Dgrid[k], top), intersections=:e)[1,1:2]
		lon_t[k,2], lon_t[k,1] = round(xy2lonlat(t, s_srs=GI.proj4)[1], digits=0), t[1]
	end
	left = [GI.range[1] GI.range[3]; GI.range[1] GI.range[4]]
	lat = Matrix{Float64}(undef, n_parallels,2)
	n = 0
	for k = n_meridians+1:length(Dgrid)
		t = gmtspatial((Dgrid[k], left), intersections=:e)
		isempty(t) && continue
		lat[n+=1,2], lat[n,1] = round(xy2lonlat(t[1,1:2], s_srs=GI.proj4)[2], digits=0), t[2]
	end
	(n != size(lat,1)) && (lat = lat[1:n, :])	# Remove those rows not filled because parallels did not cross E-W boundary
	lon_b, lat
end
