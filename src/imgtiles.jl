"""
    quadkey(lon::Real, lat::Real, zoom::Int; bounds=false, geog=true)

- `bounds`: If true, returns the bounding box of the tile, otherwise returns the tile XYZ
  coordinates and the quadtree string.
- `geog`: return the bounding box in geographic coordinates. If false, returns the bounding box
  in spherical Mercator coordinates

Returns the x,y,z & the quadtree string or the bounds

### Examples
```jldoctest
julia> quadkey(-9,39, 8)
([121, 97, 8], ["03311003";;])
```

```jldoctest
julia> quadkey(-9,39, 8, bounds=true)
2×2 Matrix{Float64}:
 -9.84375  38.8226
 -8.4375   39.9097
```

The form bellow returns the quadtree representation of the XYZ tile or the bounds coordinates in geographic coordinates

    quadkey(xyz::VecOrMat{<:Int}; bounds=true, geog=true)

### Examples
```jldoctest
julia> quadkey([121, 97, 8], bounds=false)
"03311003"
```
"""
function quadkey(lon::Real, lat::Real, zoom::Int; bounds=false, geog=true)
	zoom <= 0 && throw(error("zoom must be > 0"))
	o = mosaic(lon, lat; zoom=zoom, quadonly=true)
	(bounds != 1) && return append!(o[2], zoom), o[1]		# Return the XYZ and the quadtree
	return (geog == 1) ? [o[3] o[4]] : [o[5] o[6]]
end

function quadkey(xyz::VecOrMat{<:Int}; bounds=true, geog=true)
	# Returns the x,y,z bounds unless quadtree=true
	lon, lat_iso = getLonLat(xyz[1], xyz[2], xyz[3]+1)
	lat = isometric2geod(lat_iso, 0.0)
	quadkey(lon, lat, xyz[3]; bounds=bounds, geog=geog)[2][1]
end

# ----------------------------------------------------------------------------------------------------------
# These functions root in a translation of the Matlab code "url2image" written by me (Joaquim Luis)
# back in 2008 and included in Mirone.
"""
    I = mosaic(lon, lat; pt_radius=6371007.0, provider="", zoom::Int=0, cache::String="",
               mapwidth=15, dpi=96, verbose::Int=0, kw...)

Get image tiles from a web map tiles provider for given longitude, latitude coordinates.

### Arguments
- `lon` & `lat`:
  - `lon, lat` two scalars with the coordinates of region of interest center. To completly define
    the image area see the `neighbors` or `mosaic` option below.
  - `lon, lat` are two elements vector or matrix with the region's [lon\\_min, lon\\_max], [lat\\_min, lat\\_max].
  - Instead of two arguments, pass just one containing a GMTdataset obtained with the ``geocoder`` function.
    Example: ``mosaic(D, ...)`` or, if the search with ``geocoder`` was sufficiently generic (see its docs),
    ``mosaic(D, bbox=true)`` to use the BoundingBox returned by the query. `bbox` supports `bb`, `BB` or
    `BoundingBox` as aliases.
- `pt_radius`: The planetary radius. Defaults to Earth's WGS84 authalic radius (6371007 m).
- `provider`: Tile provider name. Currently available options are (but for more details see the docs of the
  `getprovider` function, *i.e.* ``? getprovider``):
  - "Bing" (the default), "OSM", "Esri" or a custom provider.
  - A `Provider` type from the ``TileProviders.jl`` package. You must consult the documentation of that package
	for more details on how to choose a *provider*.
- `zoom`: Zoom level (0 for automatic). A number between 0 and ~19. The maximum is provider and area dependent.
  If `zoom=0`, the zoom level is computed automatically based on the `mapwidth` and `dpi` options.
- `cache`: Full name of the the cache directory where to save the downloaded tiles. If empty, a cache
  directory is created in the system's TMP directory. If `cache="gmt"` the cache directory is created in
  ``~/.gmt/cache_tileserver``. NOTE: this normally is neeaded only for the first time you run this function when,
  if `cache!=""`, the cache dir location is saved in the ``~./gmt/tiles_cache_dir.txt`` file and used in
  subsequent calls.
- `mapwidth`: Map width in cm. Used together with the `dpi` option to automatically compute the zoom level.
- `dpi`: Dots per inch. Used together with the `mapwidth` option to automatically compute the zoom level.
- `verbose`: Verbosity level. A number between 0 and 2. Print out info while downloading the image files.
  Silent when geting files from local cache unless `verbose=2`, where it prints out info about the files
  found in the cache.

### kwargs (kw...)
- `neighbors` or `mosaic`: When `lon` and `lat` are scalars, this option specifies the number of neighbors
  of the tile containing the query point to download. Normally this should be an odd number, but it can take the
  form of a matrix and the number of tiles is then determined by the number of rows and columns.
- `merc` or `mercator`: Return tiled image in Mercator coordinates. The default is to project it back
  to geographical coordinates.
- `loose` or `loose_bounds`: By default we return an image with the limits requested in the `lon` and
  `lat` arguments. This option makes it return an image with the limits that are determined by those of
  the tiles that intersect the requested region. Note that this does not work for point queries.
- `quadonly`: Return only the quadtree string. A string or a matrix of strings when number of tiles > 1.
  Other from the quadtree string this option return also the `decimal_adress, lon, lat, x, y` that are:
  the XYZ tiles coordinates, the longitude, latitude , mercator X and Y coordinates in meters of first tile.

### Returns
- `I`: A GMTimage element or the output of the `quadonly` option explained above.

# Examples
```jldoctest
julia> I = mosaic(0.1,0.1,zoom=1)
viz(I, coast=true)
```
"""
function mosaic(D::GMTdataset; pt_radius=6371007.0, provider="", zoom::Int=0, cache::String="",
                mapwidth=15, dpi=96, verbose::Int=0, kw...)
	if (find_in_kwargs(kw, [:bb :BB :bbox :BoundingBox])[1] !== nothing)
		lon = D.ds_bbox[1:2];	lat = D.ds_bbox[3:4]
	else
		lon, lat = D.data[1,1], D.data[1,2]
	end
	mosaic(lon, lat; pt_radius=pt_radius, provider=provider, zoom=zoom, cache=cache, mapwidth=mapwidth,
           dpi=dpi, verbose=verbose, kw...)
end

function mosaic(lon, lat; pt_radius=6371007.0, provider="", zoom::Int=0, cache::String="",
                mapwidth=15, dpi=96, verbose::Int=0, kw...)
	(size(lon) != size(lat)) && throw(error("lon & lat must be of the same size"))
	d = Dict{Symbol,Any}(kw)
	flatness = 0.0		# Not needed because the tile servers serve data in spherical Mercator, but some funs expect flatness

	(mapwidth < 1) && error("Don't joke with us, a map with a width less than 1 cm???")
	(length(lon) == 1 && zoom == 0) && error("Need to specify zoom level for single point query")
	(zoom == 0) && (zoom = guessZoomLevel(mapwidth, (lon[2]-lon[1]), dpi))

	provider_url, zoom, ext, isZXY, isZYX, provider_code, variant = getprovider(provider, zoom)
	isXeYeZ = contains(provider_url, "lyrs=")
	isBing  = contains(provider_url, "virtualearth")

	# Check for user cache location
	f = joinpath(GMTuserdir[1], "tiles_cache_dir.txt")
	if (cache == "")
		(isfile(f)) && (cache = readline(f))
		length(cache) < 3 && (cache = joinpath(tmpdir_usr[1], "cache_" * tmpdir_usr[2]))
	else
		(cache == "gmt") && (cache = joinpath(GMTuserdir[1], "cache_tileserver"))	# cache it in ~/.gmt
		(isfile(f)) && rm(f)			# Remove old cache location
		write(f, cache)					# Save new cache location
	end

	quadkey::Matrix{Char} = ['0' '1'; '2' '3']
	quadonly = ((val = find_in_dict(d, [:quadonly])[1]) !== nothing) ? true : false
	inMerc   = ((val = find_in_dict(d, [:merc :mercator])[1]) !== nothing) ? true : false
	isExact  = ((val = find_in_dict(d, [:loose :loose_bounds])[1]) === nothing) ? true : false
	(isExact && length(lon) == 1) && (isExact = false)
	neighbors::Matrix{Float64} = ((val = find_in_dict(d, [:N :neighbors :mosaic])[1]) === nothing) ? [1.0;;] : isa(val, Int) ? ones(Int64(val),Int64(val)) : ones(size(val))
	(length(neighbors) > 1 && length(lon) > 1) && error("The 'neighbor' option is only for single point queries.")
	delete!(d, [[:bb], [:BB], [:bbox], [:BoundingBox]])		# Remove this valid ones befor checking for mistakes.
	(length(d) > 0) && println("\n\tWarning: the following options were not consumed in mosaic => ", keys(d),"\n")

	any(lat .> 85.0511)  && (lat[lat .> 85.0511]  .= 85.0511)
	any(lat .< -85.0511) && (lat[lat .< -85.0511] .= -85.0511)
	lon = wraplon180!(lon)		# Make sure that longitudes are in the range -180 to 180 (for scalars need a return value)

	lat_orig = lat				# Save original lat for eventual use in the exact region option
	lat = geod2isometric(lat, flatness)
	x, y, xmm, ymm = getPixel(lon, lat, zoom)		# x,y are the fractional number of the 256 bins counting from origin
	x, y = floor.(x), floor.(y)
	lon_mm, latiso_mm = getLonLat(xmm, ymm, zoom+8)	# WHY + 8 ?
	latiso_mm = flipud(latiso_mm[:, end:-1:1])		# Flip because origin was top -> down. flipud to have south at 1 row and growing north with rows
	lat_mm = isometric2geod(latiso_mm, flatness)

	# ---------------------- Case when rectangle BB was given
	if (length(lon) == 2)					# See if have other tiles in between the ones deffined by lon_min and lon_max
		Dtile = xmm[2, 1] - xmm[1, 2]		# > 0, have tiles in the midle; == 0, two contiguous tiles; < 0, same tile
		nInTilesX = Dtile > 0 ? Dtile / 256 : Dtile == 0 ? 0 : -1

		Dtile = ymm[2, 1] - ymm[1, 2]		# Idem for lat
		nInTilesY = Dtile > 0 ? Dtile / 256 : Dtile == 0 ? 0 : -1
		neighbors = ones(Int(nInTilesY)+2, Int(nInTilesX)+2)		# Create the neighbors matrix

		lon_mm = [minimum(lon_mm), maximum(lon_mm)]
		lat_mm = [minimum(lat_mm), maximum(lat_mm)]
		latiso_mm = [minimum(latiso_mm), maximum(latiso_mm)]

		# Calculate center so that the below MxN neighbors code case can be reused
		x = div((x[1] + x[2]), 2)
		y = div((y[1] + y[2]), 2)
	end

	# ---------------------- CORE THING ---- Calculate the quadtree string
	quadtree = ""
	for i in 1:zoom-1
		x, _rx = divrem(x, 2);		rx = Int(_rx) + 1
		y, _ry = divrem(y, 2);		ry = Int(_ry) + 1
		quadtree *= quadkey[ry, rx]
	end
	quadtree = quadtree[end:-1:1]
	zoom -= 1						# Was increased by 1 in getprovider() because counts from 0, but now we use it from 1

	# ----------------------- Find the tile decimal adress. x counts from 0 at -180 to 2^(zoom - 1) - 1 at +180 
	decimal_adress::Vector{Int} = getQuadLims(quadtree, quadkey, 1)[1]

	pref_bak = deepcopy(provider_url)
	if quadonly
		provider_url = (!isZXY) ? string(provider_url[end]) : ""
	end

	mMo, nMo = size(neighbors)
	tile_url = Matrix{String}(undef, mMo, nMo)
	quad_ = Matrix{String}(undef, mMo, nMo)				# quad_ is a copy with the quadtree string only
	mc, nc = ceil(Int, mMo / 2), ceil(Int, nMo / 2)		# Find central point
	mm, nn = [1, mMo] .- mc, [1, nMo] .- nc				# Shift vector about central point
	if (!quadonly && isBing)
		for i in mm[1]:mm[2]
			for j in nn[1]:nn[2]
				quad_[i+mc, j+nc] = getNext(quadtree, quadkey, i, j)
				tile_url[i+mc, j+nc] = provider_url * quad_[i+mc, j+nc] * "?g=244"
			end
		end
	else
		for i in mm[1]:mm[2]
			for j in nn[1]:nn[2]
				quad_[i+mc, j+nc] = getNext(quadtree, quadkey, i, j)
				decAdr::Vector{Int} = getQuadLims(quad_[i+mc, j+nc], quadkey, 1)[1]
				(isZYX) && (decAdr = [decAdr[2], decAdr[1]])		# Swap x and y because Esri uses z,y,x instead of z,x,y
				if (isXeYeZ)
					tile_url[i+mc, j+nc] = string(provider_url, decAdr[1], "&y=", decAdr[2], "&z=$(zoom)")
				elseif (isZXY)
					tile_url[i+mc, j+nc] = string(pref_bak, zoom, "/", decAdr[1], "/", decAdr[2], ".", ext)
				else
					tile_url[i+mc, j+nc] = provider_url * quad_[i+mc, j+nc]
				end
			end
		end
	end

	if length(lon) == 1				# Otherwise (rectangle limits on input) we already know them
		lon_mm = [lon_mm[1] + nn[1] * (lon_mm[2] - lon_mm[1]), lon_mm[2] + nn[2] * (lon_mm[2] - lon_mm[1])]
		latiso_mm = [latiso_mm[1] - mm[2] * (latiso_mm[2] - latiso_mm[1]), latiso_mm[2] - mm[1] * (latiso_mm[2] - latiso_mm[1])]
		lat_mm = isometric2geod(latiso_mm, flatness)
	end

	(flatness != 0) && (pt_radius *= pt_radius / meridionalRad(pt_radius, flatness))

	x, y = geog2merc(lon_mm, (flatness == 0) ? lat_mm : latiso_mm, pt_radius)

	if (!quadonly)
		cache, cache_supp = completeCacheName(cache, zoom, provider_code; variant=variant)
		if !isa(tile_url, Matrix)
			img = getImgTile(quadkey, quad_[1], tile_url, cache, cache_supp, ext, isZXY, verbose)
		else
			img = zeros(UInt8, (256 * nMo, 256 * mMo, 3))
			for row = 1:mMo					# Rows
				for col = 1:nMo				# Cols
					img[(col-1)*256+1:col*256, (row-1)*256+1:row*256, :] =
						getImgTile(quadkey, quad_[row, col], tile_url[row, col], cache, cache_supp, ext, isZXY, verbose)
				end
			end
		end

		xx = collect(linspace(x[1], x[2], size(img,1)+1))
		yy = collect(linspace(y[1], y[2], size(img,2)+1))
		I = mat2img(img, x=xx, y=yy, proj4="+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=$pt_radius +b=$pt_radius +units=m +no_defs", layout="TRBa", is_transposed=true)

		if (inMerc && isExact)		# Cut to the exact required limits
			mat::Matrix{Float64} = mapproject([lon[1] lat_orig[1]; lon[2] lat_orig[2]], J=I.proj4).data
			I = grdcut(I, R=(mat[1,1], mat[2,1], mat[1,2], mat[2,2]))
		elseif (!inMerc)			# That is, if project to Geogs
			gdwopts = ["-t_srs","+proj=latlong +datum=WGS84", "-r","cubic"]
			isExact && append!(gdwopts, ["-te"], ["$(lon[1])"], ["$(lat_orig[1])"], ["$(lon[2])"], ["$(lat_orig[2]))"])
			I = gdalwarp(I, gdwopts)
		end

		return I
	end
	return quad_, decimal_adress, lon_mm, lat_mm, x, y
end

# ---------------------------------------------------------------------------------------------------
"""
    getprovider(name, zoom::Int; variant="")

Get information about a tile provider given its name and zoom level. The returned information
is only relevant for internal use and is an implementation detail not documented here.

### Arguments
- `name`: Name of the tile provider. Currently available are "Bing" (the default), "OSM", "Esri".
  Optionally, the `name` can be a tuple of two strings, where the first string is the provider name
  and the second string is the variant name (see the `variant` bellow).
- The `name` argument can also be a `Provider` type from the TileProviders.jl package. For example,
  after importing TileProviders.jl, ``provider = NASAGIBSTimeseries()`` and next pass it to `getprovider`.
- `zoom`: Requested zoom level. Will be capped at the provider's maximum.
- `variant`: Optional variant for providers with multiple map layers.
  - `Bing`: variants => "Aerial" (default), "Road", or "Hybrid".
  - `Esri`: variants => "World\\_Street\\_Map" (default), "Elevation/World\\_Hillshade", or "World\\_Imagery".
"""
getprovider(name::Tuple{String,String}, zoom::Int) = getprovider(name[1], zoom; variant=name[2])
function getprovider(name::StrSymb, zoom::Int; variant="", format="", ZYX::Bool=false, dir_code="")
	# The 'format', 'dir_code' and 'ZYX' kwargs are of internal use only and passed in when using a TileProviders type
	isZXY, ext = false, "jpg"
	isZYX = ZYX ? true : false
	(format != "") && (ext = format)
	_name = lowercase(string(name))
	if (_name == "" || _name == "bing")
		t::String = (variant == "") ? "a" : string(lowercase(variant)[1])
		(t != "a" && t != "r" && t != "h") && error("Bing only supports 'a' (Aerial), 'r' (Road) or 'h' (Hybrid)")
		url = "http://" * t * "0.ortho.tiles.virtualearth.net/tiles/" * t;
		max_zoom = 19;	code = "bing";	variant = t
		(t == 'r' || t == 'h') && (ext = "png")
	elseif (_name == "osm" || _name == "openstreetmap")
		url = "https://tile.openstreetmap.org/";
		max_zoom = 19;	ext = "png";	isZXY = true;	code = "osm"
	elseif _name == "moon"
		url = "https://mw1.google.com/mw-planetary/lunar/lunarmaps_v1/apollo/";
		max_zoom = 10;	isZXY = true;	code = "moon"
	elseif _name == "esri"
		t = (variant == "") ? "World_Street_Map" : variant
		url = "https://server.arcgisonline.com/ArcGIS/rest/services/" * t * "/MapServer/tile/";
		max_zoom = 23;	isZXY, isZYX = true, true;	code = "esri";	variant = t
	elseif (startswith(_name, "goo"))
		# variants: satelite="s", roadmap="m", terrain="p", hybrid="y"
		v = (variant == "") ? 's' : lowercase(variant)[1]
		t = (v == 's') ? "s" : (v == 'r') ? "m" : (v == 't') ? "p" : (v == 'h') ? "y" : error("Supported variants: 'Satellite', 'Road' 'Terrain' or 'Hybrid'")
		url = "https://mt1.google.com/vt/lyrs=" * t * "&x=";
		max_zoom = 22;	isZXY = true; code = "g" * t;	variant = t
	else
		url, isZXY, max_zoom, code = name, true, 22, dir_code == "" ? "unknown" : dir_code
	end
	zoom += 1
	(zoom > max_zoom+1) && (zoom = max_zoom+1; @warn("Zoom level $zoom is too high for the '$code' provider. Zoom level set to $max_zoom"))
	return url, zoom, ext, isZXY, isZYX, code, variant
end

# ---------------------------------------------------------------------------------------------------
function getprovider(arg, zoom::Int)
	# This method uses as input a TileProviders type. Note that we don't have TileProviders as a dependency
	# but make a dummy guess about it. Example usage: (night lights)
	# provider = NASAGIBSTimeseries()
	# I = mosaic(geocoder("Iberia"), bbox=true, provider=provider, verbose=2)
	fs = fields(arg)
	!(length(fs) == 2 && (fs[1] == :url && fs[2] == :options)) && error("Argument for this method must be a TileProviders provider.")

	function geturl(provider)		# This function was "borrowed"/modified from TileProviders.jl
		ops = provider.options
		zoom > get(ops, :max_zoom, 19) && (@warn("zoom ($(zoom)) is larger than max_zoom ($(ops[:max_zoom]))"); zoom = ops[:max_zoom])
		subdomain = haskey(ops, :subdomains) ? string(rand(ops[:subdomains]), ".") : ""		# Choose a random subdomain
		replacements = ["{s}." => subdomain,		# We replace the trailing . in case there is no subdomain
						"{x}" => "0", "{y}" => "0", "{z}" => "0", "{r}" => ""]
		foreach(keys(ops), values(ops)) do key, val
			if !(key in (:attributes, :html_attributes, :name))
				push!(replacements, string('{', key, '}') => string(val))
			end
		end
		return replace(provider.url, replacements...)
	end

	url = geturl(arg)
	ind = findfirst("0/0/0", url)		# Will strip this part and let the manin mosaic() fun fill it with its due.
	code = string(arg.options[:name])	# A unique subdir name for the cache directory.
	((v = get(arg.options, :variant, "")) !== "") && (code *= filesep * v)
	getprovider(url[1:ind[1]-1], zoom; format=arg.options[:format], ZYX=contains(arg.url, "{z}/{y}/{x}"), dir_code=code)
end


# ---------------------------------------------------------------------------------------------------
function completeCacheName(cache, zoomL, provider_code; variant="")
	cache_supp = ""
	name = lowercase(fileparts(cache)[2])
	
	!startswith(name, "cache_") && (cache = joinpath(cache, "cache"))
	plusZLnumber = (zoomL > 9) ? "$(zoomL)" : "0" * "$(zoomL)"			# If the zoomlevel is less than 10, add a leading 0
	v = (variant == "") ? "" : filesep * variant
	cache_supp = filesep * provider_code * v * filesep * plusZLnumber	# Append the zoomlevel to the cache dir tree
			
	return cache, cache_supp
end

# -------------------------------------------------------------------------------------------------
"""
    limits, Dtiles, zoomL = quadbounds(quadtree; flatness=0.0, geog=true)

Compute the coordinates of the `quadtree` quadtree. Either a single quadtree string or an array
of quadtree strings.

- `quadtree`: Either a single quadtree string or a `Matrix{String}` of quadtree strings.
  This is the quadtree string or array of strings to compute coordinates for and is obtained
  from a call to the `mosaic` using the `quadonly` option (see example below).
- `flaness`: Flatness of the ellipsoid.

### Returns
- `limits`: The BoundingBox coords in geogs in [lonMin lonMax latMin latMax] format.
- `Dtiles`: A GMTdataset vector with the corner coordinates of each tile.
- `zoomL`: Zoom level of the tiles.

### Example
  quadtree = mosaic([-10. -8],[37. 39.], zoom=8, quadonly=1)[1]

  D = quadbounds(quadtree)[2]
"""
quadbounds(quadtree::String; geog=true) = quadbounds([quadtree;;]; geog=geog)
function quadbounds(quadtree::Matrix{String}; geog=true)
	quadkey = ['0' '1'; '2' '3']			# Only one used now.
	flatness = 0.0
	
	if isa(quadtree, AbstractString)		# A single quadtree
		lims, zoomL = getQuadLims(quadtree, quadkey, "")
		tiles_bb = lims[[1, 2, 4, 3]]		# In case idiot choice of 2 argouts
	else									# Several in a cell array
		tiles_bb = zeros(length(quadtree), 4)
		lims = [361 -361 -361 361]
		for k = 1:length(quadtree)
			lim, zoomL = getQuadLims(quadtree[k], quadkey, "")		# Remember that lim(3) = y_max
			lims = [min(lims[1], lim[1]), max(lims[2], lim[2]), max(lims[3], lim[3]), min(lims[4], lim[4])]
			tiles_bb[k, :] .= lim
		end
	end
	
	lims[3:4] = isometric2geod(reverse(lims[3:4]), flatness)		# Convert to geodetic lats
	tiles_bb[:, 3:4] .= isometric2geod(tiles_bb[:, 4:-1:3], flatness)
	v = Vector{Matrix{Float64}}(undef, size(tiles_bb, 1))
	for k = 1:size(tiles_bb, 1)
		v[k] = [tiles_bb[k,1] tiles_bb[k,3];
		        tiles_bb[k,1] tiles_bb[k,4];
				tiles_bb[k,2] tiles_bb[k,4];
				tiles_bb[k,2] tiles_bb[k,3]; tiles_bb[k,1] tiles_bb[k,3]]
		if (!geog)  xm, ym = geog2merc(v[k][:,1], v[k][:,2], 6378137.0);	v[k] = [xm ym]	end
	end
	proj = geog ? prj4WGS84 : "+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=6378137 +b=6378137 +units=m +no_defs"
	D = mat2ds(v, proj=proj, geom=wkbPolygon)
	set_dsBB!(D)
	return lims, D, zoomL
end

# -------------------------------------------------------------------------------------------------
function getNext(quadtree, quadkey, v, h)::String
	# To navigate up/down/left/right, we can translate the string of q-t this way: q=0 r=1 t=2 s=3
	# We can treat each letter as a 2-bit number, where bit 0 means left/right and bit 1 means up/down.
	# Therefore, a string gets translated like: 
	#    tqstqrrqstsrtsqsqr =
	#  = 203201103231230301
	#  H 001001101011010101 (horizontal)
	#  V 101100001110110100 (vertical)
	#
	# Now, we have two 18-bit binary numbers that encode position. To navigate east, for example,
	# we simply increment the horizontal number, then reencode: 
	#  H 001001101011010110
	#  V 101100001110110100
	#  = 203201103231230310
	#
	#	From: web.media.mit.edu/~nvawter/projects/googlemaps/index.html

	isequal([h, v], [0, 0]) && return quadtree		# Trivial case

	N = length(quadtree)
	quad_num = zeros(Int, N)
	quad_num[findall(quadkey[1, 2], quadtree)] .= 1
	quad_num[findall(quadkey[2, 1], quadtree)] .= 2
	quad_num[findall(quadkey[2, 2], quadtree)] .= 3

	new_quad = fill(' ', N)
	
	tmp = dec2bin.(quad_num, 2)
	V = [t[1] for t in tmp]
	H = [t[2] for t in tmp]

	(h != 0) &&	(H = dec2bin(bin2dec(join(H)) + h, N))	# East-West
	(v != 0) &&	(V = dec2bin(bin2dec(join(V)) + v, N))	# Up-Down

	# Test if we are getting out of +180. If yes, wrap the exccess it to -180
	(length(H) > N) && (H = dec2bin(h - 1))

	new_tile_bin = join.(eachrow([collect(V) collect(H)]))		# So f. complicated. In Matlab is just [V(:) H(:)]
	quad_num = bin2dec.(new_tile_bin)

	# Now reencode the new numeric quadtree
	new_quad[quad_num .== 0] .= quadkey[1, 1]
	new_quad[quad_num .== 1] .= quadkey[1, 2]
	new_quad[quad_num .== 2] .= quadkey[2, 1]
	new_quad[quad_num .== 3] .= quadkey[2, 2]
	join(new_quad)
end

# -----------------------------------------------------------------------------------------
function getQuadLims(quadtree, quadkey, opt)
	# Compute the limits of a quadtree string.
	# OPT == [] => lims = [lon1 lon2 lat1 lat2];	ELSE,	lims = [pixelX pixelY];
	pato, quadtree, = fileparts(quadtree)		# If quadtree is a filename, retain only what matters
	
	zoomL = length(quadtree) + 1
	quad_x = zeros(Int, zoomL)
	quad_y = copy(quad_x)

	# MAPPING: X -> 0=0 1=1 3=1 2=0;		Y -> 0=0 1=0 3=1 2=1
	quad_x[findall(quadkey[1, 2], quadtree)] .= 1
	quad_x[findall(quadkey[2, 1], quadtree)] .= 0
	quad_x[findall(quadkey[2, 2], quadtree)] .= 1
	
	quad_y[findall(quadkey[1, 2], quadtree)] .= 0
	quad_y[findall(quadkey[2, 1], quadtree)] .= 1
	quad_y[findall(quadkey[2, 2], quadtree)] .= 1
	
	pixelX, pixelY = 0, 0
	
	for k = 1:length(quadtree)
		pixelX = pixelX * 2 .+ quad_x[k]
		pixelY = pixelY * 2 .+ quad_y[k]
	end
	
	if isempty(opt)
		lon1, lat1 = getLonLat(pixelX, pixelY, zoomL)
		lon2, lat2 = getLonLat(pixelX .+ 1, pixelY .+ 1, zoomL)
		lims = [lon1, lon2, lat1, lat2]
	else
		lims = [pixelX, pixelY]
	end
	return lims, zoomL
end

# -----------------------------------------------------------------------------------------
function getPixel(lon, lat, zoomL)
	# Compute the pixel coordinate for a given longitude and latitude.
	# In fact x,y are the fractional number of the 256 bins counting from origin
	pixPerDeg = 2^(zoomL - 1) / 360
	x = (lon .+ 180) * pixPerDeg
	y = (180 .- lat) * pixPerDeg
	isa(y, VecOrMat) && (y = y[end:-1:1])			# WHY ?????
	
	if length(lon) == 1
		xmm = [floor(x) floor(x) + 1] * 256			# [x_min x_max] pixel coords of the rectangle
		ymm = [floor(y) floor(y) + 1] * 256
	else #(length(lon) == 2)						# lon, lat contain a rectangle limits
		xmm = [floor(x[1]) floor(x[1]) + 1; floor(x[2]) floor(x[2]) + 1] * 256
		ymm = [floor.(y) floor.(y) .+ 1] * 256
		ymm = reshape(ymm, (2, 2))
	end
	return x, y, xmm, ymm
end

# -----------------------------------------------------------------------------------------
function getLonLat(pixelX, pixelY, zoomL)
	# Compute the longitude and isometric latitude for a given pixel coordinate.
	pixPerDeg = 2^(zoomL - 1) / 360
	lon = pixelX / pixPerDeg .- 180
	lat = 180 .- pixelY / pixPerDeg
	return lon, lat
end

# -----------------------------------------------------------------------------------------
function getImgTile(quadkey, quadtree, url, cache, cache_supp, ext, isZXY, verbose)::Array{UInt8,3}
	# Get the image either from a local cache or by url 
	# cache_supp contains (for example) the /../13 subdirs
	local img = Array{UInt8,3}(undef, 0,0,0)
	fname = ""
	try
		!isZXY && (quadtree = string(url[8], quadtree))

		if !isempty(cache)
			fname = string(cache, cache_supp, filesep, quadtree, ".", ext)

			if isfile(fname)
				(verbose > 1) && println("Retrieving file from cache: ", fname)
				_img = gdalread(fname)
			else
				_img = netFetchTile(url, string(cache, cache_supp), quadtree, ext, verbose)
			end
		else
			_img = netFetchTile(url, "", quadtree, ext, verbose)
		end
		_img !== nothing && (img = _img.image)

		if (isempty(img))
			img = fill(UInt8(200), (256, 256, 3))
		elseif (ndims(img) == 2)
			img = ind2rgb(_img).image
		end

	catch ex
		println(ex)
		isempty(img) && !isempty(fname) && isfile(fname) && rm(fname)
		img = fill(UInt8(200), (256, 256, 3))
	end

	return img
end

# -----------------------------------------------------------------------------------------
function netFetchTile(url, cache, quadtree, ext, verbose)
	# Fetch a file from the web either using gdal or Downloads (when gdal is not able to)
	(verbose > 0) && println("Downloading file ", url)
	try
		dest_fiche = "lixogrr"					# Don't recall anymore what this default, defaults for!
		if !isempty(cache)
			!isdir(cache) && mkpath(cache)		# Need to create a new dir
			dest_fiche = string(cache, filesep, quadtree, ".", ext)
		end

		Downloads.download(url, dest_fiche)		# Could try to make this a parallel job, but does it worth it?

		finfo = stat(dest_fiche)
		if (finfo.size < 100)				# Delete the file anyway because it exists but is empty
			println("Failed to download file: ", url)
			rm(dest_fiche)
			return nothing
		end

		img = gdalread(dest_fiche)
		(size(img, 3) == 4) && (img = img[:, :, 1:3])		# We don't deal yet with alpha-maps in images

		return img
	catch ex
		println(ex)
		return nothing
	end
end

#=  Commented (not finished BTW) until deciding if direct tiles downlowd with GDAL is a good thing
function saveInCache(cache, fname, img, ext)
	# This function gets called when a file was downloaded. If a cache dir info is available, save it there. 
	# Still, if cache (main)dir exists but not the required cache (sub)dir, than create it (or raise error exception)
	# CACHE is here the full path to the cache directory name. As just said, if it doesn't exist creat it
	# FNAME is the full file name, which is = CACHE/image_name (image_name has some degrees of freedom)
	# ATT is the gdalread attribute structure
	# IMG is ... the image (2D or 3D)
	# EXT is either 'jpg', 'jpeg' (3D) or 'png' (2D)
	isempty(cache) && return

	if isdir(cache) == false
		mkpath(cache)
	end

	if ndims(img) == 3 && (ext == "jpg" || ext == "jpeg")
		imwrite(img, fname, quality=100)
	elseif ndims(img) == 3 && ext == "png"
		imwrite(img, fname)
	elseif ndims(img) == 2 && ext == "png"
		cmap = att.Band.ColorMap.CMap[:, 1:3]
		imwrite(img, cmap, fname)
	elseif ndims(img) == 2 && ext == "jpg"			# Do nothing. VE returns a 256x256 when the tile has no image
	else
		error("Unknown error while trying to save image in cache")
	end
end
=#


#=
dpi = 100
pixPerDeg = 2^(zoomL - 1) / 360
pixPerCm = 1 * dpi / 2.54
pixPerCm / pixPerDeg = DegPerCm
DegPerCm = dLon / mapWidth
pixPerCm / pixPerDeg = dLon / mapWidth
pixPerDeg = pixPerCm / (dLon / mapWidth)

2^(zoomL - 1) = pixPerDeg * 360
(zoomL - 1) = log2(pixPerDeg * 360)
zoomL = log2(pixPerDeg * 360) + 1
=#
function guessZoomLevel(mapWidthInCm, dLon, dpi=100)
	pixPerCm = 1 * dpi / 2.54
	pixPerDeg = pixPerCm / (dLon / mapWidthInCm) / 256
	round(Int, log2(pixPerDeg * 360) + 1)
end

# -----------------------------------------------------------------------------------------
"""
    D = geocoder(address::String; options=String[]) => GMTdataset

Get the geocoder info for a given address by calling the GDAL/OGR geocoding functions.
See https://gdal.org/doxygen/ogr__geocoding_8h.html

### Arguments
- `address`: The string to geocode.
- `options`: These are the options passed to GDAL and in the form of a vector of strings. For example,
  the default is equivalent to `options=["SERVICE", "OSM_NOMINATIM"]`.
    - "CACHE\\_FILE" : Defaults to "ogr\\_geocode\\_cache.sqlite" (or otherwise "ogr\\_geocode\\_cache.csv" if the
      SQLite driver isn't available). Might be any CSV, SQLite or PostgreSQL datasource.
    - "READ_CACHE" : "TRUE" (default) or "FALSE"
    - "WRITE_CACHE" : "TRUE" (default) or "FALSE"
    - "SERVICE": "OSM\\_NOMINATIM" (default), "MAPQUEST\\_NOMINATIM", "YAHOO", "GEONAMES", "BING" or other value.
      Note: "YAHOO" is no longer available as a free service.
    - "EMAIL": used by OSM_NOMINATIM. Optional, but recommended.
    - "USERNAME": used by GEONAMES. Compulsory in that case.
    - "KEY": used by BING. Compulsory in that case.
    - "APPLICATION": used to set the User-Agent MIME header. Defaults to GDAL/OGR version string.
    - "LANGUAGE": used to set the Accept-Language MIME header. Preferred language order for showing search results.
    - "DELAY": minimum delay, in second, between 2 consecutive queries. Defaults to 1.0.
    - "QUERY\\_TEMPLATE": URL template for GET requests. Must contain one and only one occurrence of %s in it.
      If not specified, for SERVICE=OSM\\_NOMINATIM, MAPQUEST\\_NOMINATIM, YAHOO, GEONAMES or BING, the URL
      template is hard-coded.
    - "REVERSE\\_QUERY\\_TEMPLATE": URL template for GET requests for reverse geocoding. Must contain one and only
      one occurrence of {lon} and {lat} in it. If not specified, for SERVICE=OSM\\_NOMINATIM, MAPQUEST\\_NOMINATIM,
      YAHOO, GEONAMES or BING, the URL template is hard-coded.


### Returns
A GMTdataset with the longitude, latitude, and full attribute dictionary returned by the geocoder for
the input address. This dataset contains only one point but geocoding service resturns also a BoundingBox
containing that point. When the `address` is very specific that BB is tiny arround the point, but when the
query is general (for example,just the name of a city or even a country), the BB is large and may be very
useful to use in the `mosaic` program. For that purpose, the returned BB is sored in the GMTdatset
``ds_bbox`` field.

### Example
    geocoder("Paris, France")
"""
function geocoder(address::String; options=String[])
	# Get the geocoder info for a given address. Adapted from https://www.itopen.it/geocoding-with-gdal/

	_ops = isempty(options) ? C_NULL : options	# The default is ["SERVICE", "OSM_NOMINATIM"]
	hSession = GMT.Gdal.OGRGeocodeCreateSession(_ops)
	hLayer = GMT.Gdal.OGRGeocode(hSession, address, C_NULL, [""])
	hFDefn = GMT.Gdal.OGR_L_GetLayerDefn(hLayer)
	hFeature = GMT.Gdal.OGR_L_GetNextFeature(hLayer)
	count = GMT.Gdal.OGR_FD_GetFieldCount(hFDefn)
	(count == 0) && (@warn("No result found for the address $address"); return nothing)
	dic = Dict{String,String}()
	for k = 0:count-1
		hFieldDefn = GMT.Gdal.OGR_FD_GetFieldDefn(hFDefn,k)
		((val = GMT.Gdal.OGR_F_GetFieldAsString(hFeature, k)) != "") && (dic[GMT.Gdal.OGR_Fld_GetNameRef(hFieldDefn)] = val)
	end

	BB = parse.(Float64, split(dic["boundingbox"], ","))
	GMT.Gdal.OGRGeocodeFreeResult(hLayer)
	GMT.Gdal.OGRGeocodeDestroySession(hSession)
	D = mat2ds([parse(Float64, dic["lon"]) parse(Float64, dic["lat"])], attrib=dic, proj4=prj4WGS84, geom=wkbPoint)
	D.ds_bbox = [BB[3], BB[4], BB[1], BB[2]]
	return D
end
