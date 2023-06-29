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

# -----------------------------------------------------------------------------------------------
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
A grid or an image and optionally the coastlines ... or errors. Not many projections support the procedure
implemented in this function.
The working or not is controlled by PROJ's `+over` option https://proj.org/usage/projections.html#longitude-wrapping

### Example:
   G = worldrectangular("@earth_relief_10m_g")
   imshow(G)
"""
worldrectangular(fname::String; proj::StrSymb="+proj=vandg +over", pm=0, latlim=:auto, latlims=nothing, pad=0, coast=false) =
	worldrectangular(gmtread(fname); proj=proj, pm=pm, latlim=latlim, latlims=latlims, pad=pad, coast=coast)
function worldrectangular(GI::GItype; proj::StrSymb="+proj=vandg +over", pm=0, latlim=:auto, latlims=nothing, pad=0, coast=false)
	# Here test if G is global
	_proj = isa(proj, Symbol) ? string(proj) : proj
	(latlim === nothing && latlims !== nothing) && (latlim = latlims)	# To accept both latlim & latlims
	autolat = false
	isa(latlim, StrSymb) && (autolat = true; latlim = nothing)
	_latlim = (latlim === nothing) ? (-90,90) : (isa(latlim, Real) ? (-latlim, latlim) : extrema(latlim))
	(_latlim[1] == _latlim[2]) && error("Your two triming latitudes ('latlim') are equal.")
	(_latlim[1] < -90 || _latlim[2] > 90) && error("Don't kid, latlim does not have real latitude limits.")
	!startswith(_proj, "+proj=") && (_proj = "+proj=" * _proj)
	!contains(_proj, " +over") && (_proj *= " +over")
	(pm > 180) && (pm -= 360);		(pm < -180) && (pm += 360)
	# The pad is an attempt to minimize the empties that may occur in the corners for some projs
	pad = (contains(proj, "wintri") && pad == 0) ? 120 : pad	# Winkel Tripel needs more
	(pad == 0) && (pad = 90)		# The default value
	res = (isa(coast, Symbol) || isa(coast, String)) ? string(coast) : (coast == 1 ? "crude" : "none")
	coastlines = (res == "none" && isa(coast, GDtype)) ? coast : GMTdataset[]	# See if we have an costlines argin.
	(isempty(coastlines) && !isa(coast, Bool) && res[1] != 'c' && res[1] != 'l' && res[1] != 'i'  && res[1] != 'h') && error("Bad input for the 'coast' option.")

	if (pm >= 0)
		Gr = grdcut(GI, R=(-180,-180+pad+pm, -90,90))		# Cut on West to be added at East
		Gr.range[1], Gr.range[2] = 180, 180+pad+pm			# pretend it is beyound 180
		if (pm < pad)
			Gl = grdcut(GI, R=(180-(pad-pm), 180, -90,90))					# Cut from East
			Gl.range[1], Gl.range[2] = Gl.range[1]-360., Gl.range[2]-360.	# To be added on the West
		else
			Gl = grdcut(GI, R=(-180+pm-pad, 180, -90,90))	# Trim original at the West
		end
	else
		Gl = grdcut(GI, R=(180-(pad-pm), 180, -90,90))			# Cut on East to be added at West
		Gl.range[1], Gl.range[2] = -180-(pad-pm), -180			# pretend it is beyound -180
		if (pm > -pad)
			Gr = grdcut(GI, R=(-180, -180+(pad+pm), -90,90))				# Cut from West
			Gr.range[1], Gr.range[2] = Gr.range[1]+360., Gr.range[2]+360.	# To be added on the East
		else
			Gr = grdcut(GI, R=(-180, 180+pad+pm, -90,90))	# Trim original at the East
		end
	end
	if (pm >= 0 && pm < pad) || (pm < 0 && pm > -pad)  G = grdpaste(Gl,GI); G = grdpaste(G,Gr)
	else                                               G = grdpaste(Gl,Gr)
	end

	(pm != 0) && (_proj *= " +pm=$pm")

	lims_geog = G.range
	G = gdalwarp(G, ["-t_srs", _proj])

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
	G.remark = "pad=$pad"		# Use this as a pocket to use in worldrectgrid()
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
- `limits`: If not empty it must be a 2 elements array with lon_min, lon_max that is used to ask for
   coastlines that expand more than 360 degrees (`worldrectangular` uses this).

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
- `limits`: If not empty it must be a 2 elements array with lon_min, lon_max that is used to ask for
   coastlines that expand more than 360 degrees (`worldrectangular` uses this).

### Returns
A Vector of GMTdataset containing the projected world GSHHG coastlines at resolution `res`.
"""
function worldrectcoast(; proj::StrSymb="", res="crude", coastlines::Vector{<:GMTdataset}=GMTdataset[], limits=Float64[], round=false)
	# Project also the coastlines to go along with the grid created by worldrectangular
	_proj  = isa(proj, Symbol) ? string(proj) : proj	# Make it a string
	cl     = (isempty(coastlines)) ? coast(dump=:true, res=res, region=:global) : coastlines
	(_proj == "" && isempty(limits)) && return cl		# No proj required nor extending the coastlines
	(round || isempty(limits)) && return lonlat2xy(cl, t_srs=_proj)		# No extensiom so we are donne.
	(_proj != "" && !contains(_proj, " +over")) && (_proj *= " +over")

	pm = (contains(_proj, "+pm=")) ? parse(Float64, string(split(split(_proj, "+pm=")[2])[1])) : 0.0
	pad = !isempty(limits) ? ((limits[2] - limits[1]) - 360.0) / 2 : 0.9

	if (pm >= 0)
		cl_right = clipbyrect(cl, (-180,-180+pad+pm, -90,90)) .+ 360
		cl_left = (pm < pad) ? clipbyrect(cl, (180-(pad-pm), 180, -90,90)) .- 360 : clipbyrect(cl, (-180+pm-pad, 180, -90,90))
	else
		cl_left = clipbyrect(cl, (180-(pad-pm), 180, -90,90)) .- 360
		cl_right = (pm > -pad) ? clipbyrect(cl, (-180, -180+(pad+pm), -90,90)) .+ 360 : clipbyrect(cl, (-180, 180+pad+pm, -90,90))
	end

	D = (pm >= 0 && pm < pad) || (pm < 0 && pm > -pad) ? cat(cat(cl_left, cl), cl_right) : cat(cl_left, cl_right)
	_proj == "" && set_dsBB!(D, false)

	return (_proj == "") ? D : lonlat2xy(D, t_srs=_proj)
end

# -----------------------------------------------------------------------------------------------
"""
	grat = graticules(D, width=(30,20), grid=nothing, annot_x=nothing)
or

    grat = graticules(; proj="projection", width=(30,20), pm=0, grid=nothing, annot_x=nothing)

Create a projected graticule GMTdataset with meridians and parallels at `width` intervals.

- `D`: A GMTdataset (or vector of them) holding the projection info. Instead of GMTdataset type, this
  argument may also be a referenced grid or image type.
- `proj`: Alternatively pass a proj4 string or Symbol describing the projection
- `pm`: The projection prime meridian (Default is 0 or whatever is in D.proj4).
- `width`: A scalar or two elements array/tuple with increments in longitude and latitude. If scalar, width_x = width_y.
- `grid`: Instead of using the `width` argument, that generates an automatic set of graticules, one may pass
  a two elements Vector{Vector{Real}} with the meridians (grid[1]) and parallels (grid[2]) to create.
- `annot_x`: By default, all meridians are annotated when `grat` is used in the `plotgrid!` function, but
  depending on the projection and the `latlim` argument used in `worldrectangular` we may have the longitude
  labels overlap close to the prime meridian. To minimize that pass a vector of longitudes to be annotated.
  *e.g.* ` annot_x=[-180,-150,0,150,180]` will annotate only those longitudes.

### Returns
A Vector of GMTdataset containing the projected meridians and parallels. `grat[i]` attributes store
information about that element lon,lat. 

### Example
    grat = graticules(proj="+proj=ob_tran +o_proj=moll +o_lon_p=40 +o_lat_p=50 +lon_0=60");
"""
function graticules(D::GDtype; width=(30,20), grid=Vector{Vector{Real}}[], annot_x::Union{Vector{Int},Vector{Float64}}=Int[])
	prj = getproj(D, proj4=true)
	graticules(proj=prj, width=width, grid=grid, annot_x=annot_x)
end
function graticules(G_I::GItype; width=(30,20), grid=Vector{Vector{Real}}[], annot_x::Union{Vector{Int},Vector{Float64}}=Int[])
	prj = getproj(G_I, proj4=true)
	graticules(proj=prj, width=width, grid=grid, annot_x=annot_x)
end
function graticules(; proj::StrSymb="", width=(30,20), grid=Vector{Vector{Real}}[], pm=0, annot_x::Union{Vector{Int},Vector{Float64}}=Int[])
	worldrectgrid(proj=proj, width=width, grid=grid, pm=pm, worldrect=false, annot_x=annot_x)
end

# -----------------------------------------------------------------------------------------------
"""
    grat = worldrectgrid(GI; width=(30,20), grid=nothing, annot_x=nothing)
or

    grat = worldrectgrid(; proj="projection", width=(30,20), grid=nothing, annot_x=nothing)

Create a grid of lines (graticules) in projected coordinates. The projection system is extracted from
the `GI` metadata.

- `GI`: A GMTgrid or GMTimage data type created with the `worldrectangular` function.
- `D`: Alternatively pass a "projection" (as a proj4 string) holding the projection info.
- `width`: A scalar or two elements array/tuple with increments in longitude and latitude. If scalar, width_x = width_y.
- `grid`: Instead of using the `width` argument, that generates an automatic set of graticules, one may pass
  a two elements Vector{Vector{Real}} with the meridians (grid[1]) and parallels (grid[2]) to create.
- `annot_x`: By default, all meridians are annotated when `grat` is used in the `plotgrid!` function, but
  depending on the projection and the `latlim` argument used in `worldrectangular` we may have the longitude
  labels overlap close to the prime meridian. To minimize that pass a vector of longitudes to be annotated.
  *e.g.* ` annot_x=[-180,-150,0,150,180]` will annotate only those longitudes.

### Returns
A Vector of GMTdataset containing the projected meridians and parallels. `grat[i]` attributes store
information about that element lon,lat. 
"""
function worldrectgrid(G_I::GItype; width=(30,20), grid=Vector{Vector{Real}}[], annot_x::Union{Vector{Int},Vector{Float64}}=Int[])
	prj = getproj(G_I, proj4=true)
	pad = contains(G_I.remark, "pad=") ? parse(Int,G_I.remark[5:end]) : 60
	worldrectgrid(proj=prj, width=width, pad=pad, grid=grid, annot_x=annot_x)
end
function worldrectgrid(D::GDtype; width=(30,20), grid=Vector{Vector{Real}}[], annot_x::Union{Vector{Int},Vector{Float64}}=Int[])
	# Normally called only by graticules, not directly
	prj = getproj(D, proj4=true)
	worldrectgrid(proj=prj, width=width, grid=grid, annot_x=annot_x)
end
function worldrectgrid(; proj::StrSymb="", width=(30,20), grid=Vector{Vector{Real}}[], annot_x::Union{Vector{Int},Vector{Float64}}=Int[], pm=0, worldrect=true, pad=60)
	# Create a grid of lines in 'proj' coordinates. Input are meridians and parallels at steps
	# determined by 'width' and centered at 'pm'. 'pm' can be transmitted via argument or contained in 'proj'
	# 'worldrect=false' means we don't extend beyound  the [-180 180]+pm as we do for worldrectangular.

	_proj = isa(proj, Symbol) ? string(proj) : proj
	_proj == "" && error("Input has no projection info")
	!startswith(_proj, "+proj=") && (_proj = "+proj=" * _proj)
	(contains(_proj, "+pm=")) && (pm = parse(Float64, string(split(split(proj, "+pm=")[2])[1])))
	(pm != 0 && !contains(_proj, "+pm=")) && (_proj *= " +pm=$pm")
	(worldrect && !contains(_proj, "+over")) && (_proj *= " +over")
	inc_x, inc_y = (length(width) == 2) ? (width[1], width[2]) : (width, width)
	pad = worldrect ? pad : 0

	if (isempty(grid))
		t = pm:-inc_x:-180.0-pad+pm
		meridians = [t[end]:inc_x:t[2]; pm:inc_x:180+pad+pm]	# Center on pm
		t = collect(0.0:-inc_y:-90)
		parallels = [t[end]:inc_y:t[2]; 0.0:inc_y:90]			# To center it on 0
	else
		meridians, parallels = Float64.(grid[1]), Float64.(grid[2])
	end

	meridian  = [-90:0.25:-89.25; -89.0:1:-80; -78.0:2:78; 80:1:89; 89.25:0.25:90]	# Attempt to have less points, but ...
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
			_m = m;	(_m < -180) && (_m += 360.);	(_m > 180) && (_m -= 360.)	
			an = isempty(annot_x) ? true : _m in annot_x
			Dgrid[n+=1] = mat2ds(lonlat2xy([fill(m,length(meridian)) meridian], t_srs=_proj), attrib=Dict("merid_b" => "$m,-90", "merid_e" => "$m,90", "annot" => an ? "y" : "n"))
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
end

# -----------------------------------------------------------------------------------------------
"""
    plotgrid!(GI, grid; annot=true, sides="WESN", fmt="", figname="", show=false)

Plot grid lines on top of an image created with the `worldrectangular` function.

- `GI`: A GMTgrid or GMTimage data type.
- `grid`: A vector of GMTdatset with meridians and parallels to be plotted. This is normaly produced
    by the `graticules()` or `worldrectgrid()` functions.
- `annot`: Wether to plot coordinate annotations or not (`annot=false`).
- `sides`: Which sides of plot to annotate. `W` or `L` means annotate the left side and so on for any
    combination of "WESNLRBT". To not annotate a particular side just omit that character. *e.g.*
   `sides="WS"` will annotate only the left and bottom axes.
- `figname`: To create a figure in local directory and with a name `figname`. If `figname` has an extension
   that is used to select the fig format. *e.g.* `figname=fig.pdf` creates a PDF file localy called 'fig.pdf' 
- `fmt`: Create the raster figure in format `format`. Default is `fmt=:png`. To get it in PDF do `fmt=:pdf`
- `show`: If `true`, finish and display the figure.
"""
function plotgrid!(GI::GItype, Dgrat::Vector{<:GMTdataset}; annot=true, sides::String="WESN", fmt="", savefig="", figname="", name="", show=false)
	# Make an image of the grid G_I overlaid with the graticules in Dgrat
	prj = getproj(GI, proj4=true)
	bot = [GI.range[1] GI.range[3]; GI.range[2] GI.range[3]]
	top = [GI.range[1] GI.range[4]; GI.range[2] GI.range[4]]
	n_meridians = parse(Int16, Dgrat[1].attrib["n_meridians"])
	n_parallels = parse(Int16, Dgrat[1].attrib["n_parallels"])
	lon_S, lon_N = Matrix{Float64}(undef, n_meridians,3), Matrix{Float64}(undef, n_meridians,3)
	k1, k2 = 0, 0
	sides = uppercase(sides)
	annot_N = contains(sides,'N') || contains(sides,'T')
	annot_S = contains(sides,'S') || contains(sides,'B')
	annot_W = contains(sides,'W') || contains(sides,'L')
	annot_E = contains(sides,'E') || contains(sides,'R')
	for k = 1:n_meridians
		if (annot_S)
			t = gmtspatial((Dgrat[k], bot), intersections=:e)
			isempty(t) && continue
			lon_S[k1+=1,2], lon_S[k1,1] = round(xy2lonlat(t[1,1:2], s_srs=prj)[1], digits=0), t[1]
			lon_S[k1,3] = Dgrat[k].attrib["annot"] == "y"	# Do annot or tick only?
		end

		if (annot_N)
			t = gmtspatial((Dgrat[k], top), intersections=:e)
			isempty(t) && continue
			lon_N[k2+=1,2], lon_N[k2,1] = round(xy2lonlat(t[1,1:2], s_srs=prj)[1], digits=0), t[1]
			lon_N[k2,3] = Dgrat[k].attrib["annot"] == "y"
		end
	end
	(annot_S && k1 != size(lon_S,1)) && (lon_S = lon_S[1:k1, :])	# Remove rows not filled
	(annot_N && k2 != size(lon_N,1)) && (lon_N = lon_N[1:k2, :])
	for k = 1:size(lon_S,1)
		(annot_S && lon_S[k,2] >  180) && (lon_S[k,2] -= 360.)
		(annot_S && lon_S[k,2] < -180) && (lon_S[k,2] += 360.)
	end
	for k = 1:size(lon_N,1)
		(annot_N && lon_N[k,2] >  180) && (lon_N[k,2] -= 360.)
		(annot_N && lon_N[k,2] < -180) && (lon_N[k,2] += 360.)
	end

	left = [GI.range[1] GI.range[3]; GI.range[1] GI.range[4]]
	lat = Matrix{Float64}(undef, n_parallels,2)
	n = 0
	if (annot_W || annot_E)
		for k = n_meridians+1:length(Dgrat)
			t = gmtspatial((Dgrat[k], left), intersections=:e)
			isempty(t) && continue
			lat[n+=1,2], lat[n,1] = round(xy2lonlat(t[1,1:2], s_srs=prj)[2], digits=0), t[2]
		end
		(annot_W && n != size(lat,1)) && (lat = lat[1:n, :])	# Remove rows not filled because parallels did not cross E-W boundary
	end

	plot!(Dgrat)
	if (annot == 1)
		(annot_W || annot_E) && (txt = [@sprintf("a %d", lat[k,2]) for k = 1:size(lat,1)])
		ax = (annot_W && annot_E) ? "WE" : annot_W ? "W" : "E"	# Which axis to annot
		(annot_W && !isempty(txt)) && basemap!(yaxis=(custom=(pos=lat[:,1], type=txt),), par=(FONT_ANNOT_PRIMARY="+7",), B=ax)

		if (annot_N)
			txt = [@sprintf("a %d", lon_N[k,2]) for k = 1:size(lon_N,1)]
			for k = 1:numel(txt) if lon_N[k,3] == 0 (txt[k] = "f") end  end
			basemap!(xaxis=(custom=(pos=lon_N[:,1], type=txt),), par=(FONT_ANNOT_PRIMARY="+7",), B="N")
		end
		if (annot_S)
			txt = [@sprintf("a %d", lon_S[k,2]) for k = 1:size(lon_S,1)]
			for k = 1:numel(txt) if lon_S[k,3] == 0 (txt[k] = "f") end  end
			basemap!(xaxis=(custom=(pos=lon_S[:,1], type=txt),), par=(FONT_ANNOT_PRIMARY="+7",), B="S")
		end
	end
	_fmt = (fmt == "") ? FMT[1] : string(fmt)
	_name = (name != "") ? string(name) : figname != "" ? string(figname) : savefig != "" ? string(savefig) : ""
	(show == 1) ? showfig(fmt=_fmt, name=_name) : nothing
end

# -----------------------------------------------------------------------------------------------
"""
"""
function cubeplot(fname1::Union{GMTimage, String}, fname2::Union{GMTimage, String}="", fname3::Union{GMTimage, String}=""; back::Bool=false, show=false, notop::Bool=false, kw...)
	# ...
	d = KW(kw)
	opt_R = ((txt::String = parse_R(d, "")[2]) != "") ? txt[4:end] : "0/9/0/9/0/9"
	opt_J = ((txt = parse_J(d, "")[2]) != "") ? txt[4:end] : "X15/0";	txt = ""
	opt_JZ = ((txt = parse_JZ(d, "")[2]) != "") ? txt[5:end] : "15";
	txt == "" && (CTRL.pocket_J[3] = " -JZ15")
	opt_p = ((txt = parse_p(d, "")[2]) != "" && txt != " -p") ? txt[4:end] : "135/30"
	opt_t = ((txt = parse_t(d, "")[2]) != "") ? txt[4:end] : "0"
	front, see = !back, show == 1

	f1 = fname1
	if     (isempty(fname2) && isempty(fname3))    f2, f3 = fname1, fname1	# Only one image
	elseif (!isempty(fname2) && !isempty(fname3))  f2, f3 = fname2, fname3	# Three different images
	else                                           f2, f3 = fname2, fname2	# Two images, repeat second on the vert sides
	end

	basemap(R=opt_R, J=opt_J, JZ=opt_JZ, p=opt_p)
	vsz = parse(Float64, opt_JZ)
	TB = front ? :T : :B
	SN = front ? :S : :N
	EW = front ? :E : :W
	bak = CTRL.pocket_J[3]		# Save this because sideplot() calls parse_JZ with too few info to preserve it in case of need.
	!notop && image!(f1, compact=sideplot(plane=TB, vsize=vsz), t=opt_t)	# 'compact' is that option that lets pass a GMT str
	image!(f2, compact=sideplot(plane=SN, vsize=vsz), t=opt_t)
	R = image!(f3, compact=sideplot(plane=EW, vsize=vsz), t=opt_t)
	CTRL.pocket_J[3] = bak
	see && showfig(d...)
	return R
end

# -----------------------------------------------------------------------------------------------
"""
"""
function sideplot(; plane=:xz, vsize=8, depth=NaN, kw...)
	# ...
	# basemap(R="-3/3/-3/3", JZ=8, J=:linear, p=(135,30))
	# image!("@maxresdefault.jpg", compact=GMT.sideplot(plane=:W))
	d = KW(kw)
	opt_R = (is_in_dict(d, [:R :limits :region]) !== nothing) ? parse_R(d, "")[2] : CTRL.pocket_R[1]
	(opt_R == "") && error("Map limits not provided nor found in memory from a previous command.")
	lims = (CTRL.limits != zeros(12)) ? CTRL.limits[7:12] : opt_R2num(opt_R)
	(lims == zeros(4)) && error("Bad limts. Can't continue.")

	opt_J = (is_in_dict(d, [:J :proj :projection]) !== nothing) ? parse_J(d, "")[2] : CTRL.pocket_J[1]
	(opt_J == "") && error("Must provide the map projection")

	opt_JZ = parse_JZ(d, "")[2]
	zsize = (opt_JZ == "") ? vsize : parse(Float64, opt_JZ[5:end])

	o = (is_in_dict(d, [:p :view :perspective]) !== nothing) ? parse_p(d, "")[2] : current_view[1]
	spli = split(o[4:end], '/')
	(length(spli) < 2) && error("The 'view' option must contain (azim,elev,z) or just (azim,elev)")
	azim, elev = parse(Float64, spli[1]), parse(Float64, spli[2])
	(length(spli) == 3) && (depth = parse(Float64, spli[3]))

	# Over which side is the plot going to be made?
	_p = string(plane)
	_p = (_p == "W") ? "yz" : (_p == "E") ? "zy" : (_p == "S") ? "xz" : (_p == "N") ? "zx" :
	     (_p == "B") ? "xy" : (_p == "T") ? "yx" : _p	# Accept aslso WESNTB

	p = (_p == "xz" || _p == "zx") ? 'y' : (_p == "yz" || _p == "zy") ? 'x' : (_p == "xy" || _p == "yx") ? 'z' :
	    (_p == "x" || _p == "y" || _p == "z") ? _p[1] : error("Unknown plane '$plane'")
	if (length(_p) == 2 && (_p[1] == 'z' || _p == "yx"))
		!isnan(depth) && @warn("Error: $plane and depth = $depth are conflicting choices. Ignoring the 'depth' selection.")
		depth = (_p == "zx") ? lims[4] : (_p == "zy") ? lims[2] : lims[6]
	end

	t::Matrix{Float64} = gmt("mapproject -W " * opt_R * opt_J).data
	W, H = t[1], t[2]
	opt_X, opt_Y = "", ""
	mi, len = (p == 'x') ? (lims[1], (lims[2] - lims[1])) : (p == 'y') ? (lims[3], (lims[4] - lims[3])) : (lims[5], (lims[6] - lims[5])) 
	if (!isnan(depth))
		a = azim - 180
		rot = [cosd(a) sind(a); -sind(a) cosd(a)]
		pct = (depth - mi) / len
		if (p != 'z')
			side, y_sign = (p == 'x') ? (W,1.0) : (H, 1.0)		# Later we'll deal with Z
			t = [0 side * pct] * rot
			if (p == 'x')  t[1], t[2] = t[2], -t[1]  end
			opt_X = @sprintf(" -Xa%.4f", t[1])
			opt_Y = @sprintf(" -Ya%.4f", t[2] * sind(elev) * y_sign)
		else
			opt_Y, opt_X = @sprintf(" -Ya%.4f", vsize * pct * cosd(elev)), ""
		end
	end
	_W, _H = (p == 'x') ? (H, zsize) : (p == 'y') ? (W, zsize) : (W, H)
	@sprintf(" -Dg%.12g/%.12g+w%.12g/%.12g -p%c%.0f/%.0f %s %s", lims[1], lims[3], _W, _H, p, azim, elev, opt_X, opt_Y)
end
