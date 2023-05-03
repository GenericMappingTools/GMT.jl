"""
    xEast, yNorth, zUp = geodetic2enu(lon, lat, h, lon0, lat0, h0)

Convert from geodetic coordinates to local East, North, Up (ENU) coordinates.
"""
function geodetic2enu(lon, lat, h, lon0, lat0, h0)
	#
	D1 = mapproject([lon lat h], geod2ecef=true);
	D0 = mapproject([lon0 lat0 h0], geod2ecef=true);
	d  = D1.data .- D0.data;
	ecef2enuv(view(d, :, 1), view(d, :, 2), view(d, :, 3), lon0, lat0)
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
   Pass `coast=D`, where `D` is vector of GMTdataset containing coastline polygons with a provenience
   other than the GSHHG GMT database.

### Returns
A grid or an image and optionaly the coastlines ... or errors. Not many projections support the procedure
implemented in this function.
The working or not is controlled by PROJ's `+over` option https://proj.org/usage/projections.html#longitude-wrapping

### Example:
   G = worldrectangular("@earth_relief_10m_g")
   imshow(G)
"""
# -----------------------------------------------------------------------------------------------
worldrectangular(fname::String; proj::StrSymb="+proj=vandg +over", pm=0, latlim=:auto, latlims=nothing, pad=90, coast=false) =
	worldrectangular(gmtread(fname); proj=proj, pm=pm, latlim=latlim, latlims=latlims, pad=pad, coast=coast)
function worldrectangular(GI::GItype; proj::StrSymb="+proj=vandg +over", pm=0, latlim=:auto, latlims=nothing, pad=90, coast=false)
	# Here test if G is global
	_proj = isa(proj, Symbol) ? string(proj) : proj
	(latlim === nothing && latlims !== nothing) && (latlim = latlims)	# To accept both latlim & latlims
	autolat = false
	isa(latlim, StrSymb) && (autolat = true; latlim = nothing)
	_latlim = (latlim === nothing) ? (-90,90) : (isa(latlim, Real) ? (-latlim, latlim) : extrema(latlim))
	(_latlim[1] == _latlim[2]) && error("Yout two triming latitudes ('latlim') are equal.")
	(_latlim[1] < -90 || _latlim[2] > 90) && error("Don't kid, latlim does not have real latitude limits.")
	!startswith(_proj, "+proj=") && (_proj = "+proj=" * _proj)
	!contains(_proj, " +over") && (_proj *= " +over")
	(pm > 180) && (pm -= 360);		(pm < -180) && (pm += 360)
	# The sw (side width) is an attempt to let try minimize the empties that may occur in the corners for some projs
	sw = (contains(proj, "wintri") && pad == 90) ? 120 : pad	# Winkel Tripel needs more
	res = (isa(coast, Symbol) || isa(coast, String)) ? string(coast) : (coast == 1 ? "crude" : "none")
	coastlines = (res == "none" && isa(coast, GDtype)) ? coast : GMTdataset[]	# See if we have an costlines argin.
	(isempty(coastlines) && res[1] != 'c' && res[1] != 'l' && res[1] != 'i'  && res[1] != 'h') && error("Bad input for the 'coast' option.")

	if (pm > -90)
		Gr = grdcut(GI, R=(-180,-180+sw+pm,-90,90))			# Chop of 90 deg on the West
		Gr.range[1], Gr.range[2] = 180, 180+sw+pm			# and pretend it is beyound 180
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
	(pm != 0) && (_proj *= " +pm=$pm")
	lims_geog = G.range
	G = gdalwarp(G, ["-t_srs", _proj])
	G.remark = "pad=$sw"		# Use this as a pocket to use in worldrectgrid()

	xy = lonlat2xy([-180.0+pm 0; 180+pm 0], t_srs=_proj)
	pix_x = axes2pix(xy, size(G), [G.x[1], G.x[end]], [G.y[1], G.y[end]], G.registration, G.layout)[1]
	if (autolat)
		t = G[pix_x[1], :]		# The column corresponding to lon = -180
		kt = length(t) + 1;		while(isnan(t[kt -= 1]) && kt > 1) end
		kb = 0;					while(isnan(t[kb += 1]) && kb < length(t)) end
		yb, yt = G.y[kb], G.y[kt]
	else
		xy = lonlat2xy([-180.0+pm _latlim[1]; 180+pm _latlim[2]], t_srs=_proj)
		_pix_x, _pix_y = axes2pix(xy, size(G), [G.x[1], G.x[end]], [G.y[1], G.y[end]], G.registration, G.layout)
		yc = pix2axes([_pix_x _pix_y], G.x, G.y)[2]
		yb, yt = yc[1], yc[2]
	end

	G = grdcut(G, R=(G.x[pix_x[1]], G.x[pix_x[2]], yb, yt))
	return (res != "none" || !isempty(coastlines)) ? (G, worldrectcoast(proj=_proj, res=res, coastlines=coastlines, limits=lims_geog)) : G
end

# -----------------------------------------------------------------------------------------------
"""
    cl = coastlinesproj(proj="?", res="crude", coastlines=nothing)

Extract the coastlines from GMT's GSHHG database and project them using PROJ (NOT the GMT projection machinery).
This allows the use of many of the PROJ proijections that are not available from pure GMT.

- `proj`: A proj4 string describing the projection (Mandatory).
- `res`: The GSHHG coastline resolution. Available options are: `crude`, `low`, `intermediate`, `high` and `full`
- `coastlines`: In alternative to the `res` option, one may pass a GMTdataset with coastlines
   previously loaded (with `gmtread`) from another source.

### Returns
A Vector of GMTdataset containing the projected (or not) world GSHHG coastlines at resolution `res`.

### Example
    cl = coastlinesproj(proj="+proj=ob_tran +o_proj=moll +o_lon_p=40 +o_lat_p=50 +lon_0=60");
"""
function coastlinesproj(; proj::StrSymb="", res="crude", coastlines::Vector{<:GMTdataset}=GMTdataset[], lonlim=Float64[])
	# Project the GSHHG coastlines with PROJ. 'proj' must be a valid proj4 string.
	_proj = isa(proj, Symbol) ? string(proj) : proj
	(_proj != "" && !startswith(_proj, "+proj=")) && (_proj = "+proj=" * _proj)
	round = (!isempty(lonlim) && (lonlim[2] - lonlim[1]) > 360) ? false : true
	worldrectcoast(proj=_proj, res=res, coastlines=coastlines, limits=lonlim, round=round)
end

# -----------------------------------------------------------------------------------------------
"""
    cl = worldrectcoast(proj="?", res="crude", coastlines=nothing, limits=Float64[])

Return a project coastline, at `res` resolution, suitable to overlain in a grid created with the
`worldrectangular` function. Note that this function, contrary to `coastlinesproj`, returns coastline
data that spans > 360 degrees.

- `proj`: A proj4 string describing the projection (Mandatory).
- `res`: The GSHHG coastline resolution. Available options are: `crude`, `low`, `intermediate`, `high` and `full`
- `coastlines`: In alternative to the `res` option, one may pass a GMTdataset with coastlines
   previously loaded (with `gmtread`) from another source.
- `limits`: If not empty ...

### Returns
A Vector of GMTdataset containing the projected world GSHHG coastlines at resolution `res`.
"""
function worldrectcoast(; proj::StrSymb="", res="crude", coastlines::Vector{<:GMTdataset}=GMTdataset[], limits=Float64[], round=false)
	# Project also the coastlines to go along with the grid created by worldrectangular
	_proj  = isa(proj, Symbol) ? string(proj) : proj
	cl     = (isempty(coastlines)) ? coast(dump=:true, res=res, region=:global) : coastlines
	(_proj == "" && isempty(limits)) && return cl	# No proj required nor extending the coastlines
	(round || isempty(limits)) && return lonlat2xy(cl, t_srs=_proj)		# No extensiom so we are donne.
	(_proj != "" && !contains(_proj, " +over")) && (_proj *= " +over")

	#cl_right = coast(dump=:true, res=res, region=(-180,0,-90,90)) .+ 360	# Good try but some points screw
	#cl_left  = coast(dump=:true, res=res, region=(0,180,-90,90)) .- 360
	pm = (contains(_proj, "+pm=")) ? parse(Float64, string(split(split(_proj, "+pm=")[2])[1])) : 0.0
	tic()
	cl_right = clipbyrect(cl, (-180, -180+limits[2]-180, -90,90)) .+ 360.
	cl_left  = clipbyrect(cl, (180+limits[1]+180, 180, -90,90)) .- 360.
	toc()

	#println("W = ", limits[1], "\tw = ", 180+limits[1]+180-360, "\tE = ", limits[2], "\te = ", -180+limits[2]-180+360)
	#println("Right\t\t", gmtinfo(cl_right))
	#println("Left\t\t", gmtinfo(cl_left))

	_proj == "" && (R = cat(cat(cl_left, cl), cl_right); set_dsBB!(R, false); return R)	# No proj requested, are also done here.

	cl_prj       = lonlat2xy(cl, t_srs=_proj)
	cl_right_prj = lonlat2xy(cl_right, t_srs=_proj)
	cl_left_prj  = lonlat2xy(cl_left, t_srs=_proj)
	tmp = cat(cl_left_prj, cl_prj)
	cat(tmp, cl_right_prj)
end

# -----------------------------------------------------------------------------------------------
"""
    grat = graticules(proj="", width=(30,20), pm=0)
or

	grat = graticules(D::GDtype, width=(30,20))

Create a projected graticule GMTdataset with meridians and parallels at `width` intervals.

- `proj`: A proj4 string or Symbol describing the projection
- `D`: Alternatively pass a GMTdataset (or vector of them) holding the projection info in the `proj4` field.
- `width`: A scalar or two elements array/tuple with increments in longitude and latitude. If scalar, width_x = width_y.
- `pm`: The projection prime meridian (Default is 0 or whatever is in D.proj4).

### Returns
A Vector of GMTdataset containing the projected meridians and parallels. `grat[i]` attributes store
information about that element lon,lat. 

### Example
    grat = graticules(proj="+proj=ob_tran +o_proj=moll +o_lon_p=40 +o_lat_p=50 +lon_0=60");
"""
function graticules(D::GDtype; width=(30,20))
	prj = (isa(D, Vector)) ? D[1].proj4 : D.proj4
	prj == "" && error("Input dataset has no proj4 projection info")
	graticules(proj=prj, width=width)
end
function graticules(; proj::StrSymb="", width=(30,20), pm=0)
	# This fun should probably be merged with worldrectgrid
	_proj = isa(proj, Symbol) ? string(proj) : proj
	(_proj != "" && !startswith(_proj, "+proj=")) && (_proj = "+proj=" * _proj)
	worldrectgrid(proj=_proj, width=width, pm=pm, worldrect=false)
end

# -----------------------------------------------------------------------------------------------
function worldrectgrid(G_I::GItype; width=(30,20))
	((prj = G_I.proj4) == "") && error("Input Grid/Image has no proj4 projection info")
	pad = contains(G_I.remark, "pad=") ? parse(Int,G_I.remark[5:end]) : 60
	worldrectgrid(proj=prj, width=width, pad=pad)
end
function worldrectgrid(D::GDtype; width=(30,20))		# This one is normally called only by graticules, not directly
	prj = (isa(D, Vector)) ? D[1].proj4 : D.proj4
	prj == "" && error("Input dataset has no proj4 projection info")
	worldrectgrid(proj=prj, width=width)
end
function worldrectgrid(; proj::StrSymb="", width=(30,20), pm=0, worldrect=true, pad=60)
	# Create a grid of lines in 'proj' coordinates. Input are meridians and parallels at steps
	# determined by 'width' and centered at 'pm'. 'pm' can be transmitted via argument or contained in 'proj'
	# 'worldrect=false' means we don't extend beyound  the [-180 180]+pm as we do for worldrectangular.

	_proj = isa(proj, Symbol) ? string(proj) : proj
	!startswith(_proj, "+proj=") && (_proj = "+proj=" * _proj)
	(contains(_proj, "+pm=")) && (pm = parse(Float64, string(split(split(proj, "+pm=")[2])[1])))
	(pm != 0 && !contains(_proj, "+pm=")) && (_proj *= " +pm=$pm")
	(worldrect && !contains(_proj, "+over")) && (_proj *= " +over")
	inc_x, inc_y = (length(width) == 2) ? (width[1], width[2]) : (width, width)
	pad = worldrect ? pad : 0

	t = pm:-inc_x:-180.0-pad+pm
	meridians = [t[end]:inc_x:t[2]; pm:inc_x:180+pad+pm]	# Center on pm
	meridian  = [-90:0.25:-89.25; -89.0:1:-80; -78.0:2:78; 80:1:89; 89.25:0.25:90]	# Attempt to have less points, but ...
	t = collect(0.0:-inc_y:-90)
	parallels = [t[end]:inc_y:t[2]; 0.0:inc_y:90]			# To center it on 0
	parallel  = -180.0-pad+pm:5:180+pad+pm

	function check_gaps(D, n1, n2, testone=true)
		# Some projections have projected graticules that are broken and lines go left-right like crazy.
		# This function tries to detect the breaking points based on cheap stats. When detected, insert NaN rows
		if (testone)					# Test if we have broken parallels
			d = diff(D[round(Int, (n1+n2)/2)], dims=1)
			dists = hypot.(view(d,:,1), view(d, :, 2))
			(median(dists) > 3 * maximum(dists)) && return nothing	# (3?) This projection has no broken parallels.
		end
		for n = n1:n2
			d = diff(D[n], dims=1);		dists = hypot.(view(d,:,1), view(d, :, 2))
			ind = findall(dists .> 5*median(dists))				# 5 is an heuristic
			isempty(ind) && continue							# This parallel is not broken
			if (length(ind) == 1)		# A single break
				D[n].data = [D[n].data[1:ind[1],:]; NaN NaN; D[n].data[ind[1]+1:end,:]]
			else						# Assume there are only two breaks. If not ...
				D[n].data = [D[n].data[1:ind[1],:]; NaN NaN; D[n].data[ind[1]+1:ind[2],:]; NaN NaN; D[n].data[ind[2]+1:end,:]]
			end
		end
		testone && check_gaps(D, 1, n1-1, false)		# If parallels were broken there good chances that meridians are too.
		return nothing
	end

	Dgrid = Vector{GMTdataset}(undef, length(meridians)+length(parallels))
	n = 0
	if (_proj != "")
		for m = meridians
			Dgrid[n+=1] = mat2ds(lonlat2xy([fill(m,length(meridian)) meridian], t_srs=_proj), attrib=Dict("merid_b" => "$m,-90", "merid_e" => "$m,90"))
		end
		for p = parallels
			Dgrid[n+=1] = mat2ds(lonlat2xy([parallel fill(p, length(parallel))], t_srs=_proj), attrib=Dict("para_b" => "$p,$(parallel[1])", "para_e" => "$p,$(parallel[end])"))
		end
		!worldrect && check_gaps(Dgrid, length(meridians)+1, length(Dgrid))		# Try this only with non-worldrect
	else					# Cartesian graticules
		for m = meridians
			Dgrid[n+=1] = mat2ds([fill(m,length(meridian)) meridian], attrib=Dict("merid_b" => "$m,-90", "merid_e" => "$m,90"))
		end
		for p = parallels
			Dgrid[n+=1] = mat2ds([parallel fill(p, length(parallel))], attrib=Dict("para_b" => "$p,$(parallel[1])", "para_e" => "$p,$(parallel[end])"))
		end
	end
	Dgrid[1].attrib["n_meridians"] = "$(length(meridians))"
	Dgrid[1].attrib["n_parallels"] = "$(length(parallels))"
	Dgrid[1].proj4 = _proj
	set_dsBB!(Dgrid, false)
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
	x = lonlat2xy(Dlons, t_srs=_proj)
	y = lonlat2xy(Dlats, t_srs=_proj)
	x, y
	=#
end

# -----------------------------------------------------------------------------------------------
function plotgrid!(GI::GItype, Dgrat::Vector{<:GMTdataset})
	# Make an image of the grid G_I overlaid with the graticules in Dgrat
	bot = [GI.range[1] GI.range[3]; GI.range[2] GI.range[3]]
	top = [GI.range[1] GI.range[4]; GI.range[2] GI.range[4]]
	n_meridians = parse(Int16, Dgrat[1].attrib["n_meridians"])
	n_parallels = parse(Int16, Dgrat[1].attrib["n_parallels"])
	lon_b, lon_t = Matrix{Float64}(undef, n_meridians,2), Matrix{Float64}(undef, n_meridians,2)
	k1, k2 = 0, 0
	for k = 1:n_meridians
		t = gmtspatial((Dgrat[k], bot), intersections=:e)
		isempty(t) && continue
		lon_b[k1+=1,2], lon_b[k1,1] = round(xy2lonlat(t[1,1:2], s_srs=GI.proj4)[1], digits=0), t[1]
		t = gmtspatial((Dgrat[k], top), intersections=:e)
		isempty(t) && continue
		lon_t[k2+=1,2], lon_t[k2,1] = round(xy2lonlat(t[1,1:2], s_srs=GI.proj4)[1], digits=0), t[1]
	end
	(k1 != size(lon_b,1)) && (lon_b = lon_b[1:k1, :])	# Remove rows not filled
	(k2 != size(lon_t,1)) && (lon_t = lon_t[1:k2, :])	# Remove rows not filled
	for k = 1:size(lon_b,1)
		(lon_b[k,2] >  180) && (lon_b[k,2] -= 360.)
		(lon_b[k,2] < -180) && (lon_b[k,2] += 360.)
	end

	left = [GI.range[1] GI.range[3]; GI.range[1] GI.range[4]]
	lat = Matrix{Float64}(undef, n_parallels,2)
	n = 0
	for k = n_meridians+1:length(Dgrat)
		t = gmtspatial((Dgrat[k], left), intersections=:e)
		isempty(t) && continue
		lat[n+=1,2], lat[n,1] = round(xy2lonlat(t[1,1:2], s_srs=GI.proj4)[2], digits=0), t[2]
	end
	(n != size(lat,1)) && (lat = lat[1:n, :])	# Remove rows not filled because parallels did not cross E-W boundary

	plot!(Dgrat)
	txt = [@sprintf("a %d", lat[k,2]) for k = 1:size(lat,1)]
	basemap!(yaxis=(custom=(pos=lat[:,1], type=txt),), par=(FONT_ANNOT_PRIMARY="+7",))
	txt = [@sprintf("a %d", lon_b[k,2]) for k = 1:size(lon_b,1)]
	basemap!(xaxis=(custom=(pos=lon_b[:,1], type=txt),), par=(FONT_ANNOT_PRIMARY="+7",), show=1)
end
