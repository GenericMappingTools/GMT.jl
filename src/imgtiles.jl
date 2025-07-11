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
	# Returns the x,y,z bounds
	(bounds != 1) && return XY2quadtree(xyz[1], xyz[2], xyz[3])		# Mutch safer than going through a mosaic call
	lon, lat_iso = getLonLat(xyz[1], xyz[2], xyz[3]+1)
	lat = isometric2geod(lat_iso, 0.0)
	r = quadkey(lon, lat, xyz[3]; bounds=bounds, geog=geog)
	return bounds ? r : r[2][1]		# In the bounds=true case we want to return the 2x2 Matrix
end

# ----------------------------------------------------------------------------------------------------------
# These functions root in a translation of the Matlab code "url2image" written by me (Joaquim Luis)
# back in 2008 and included in Mirone.
"""
    I = mosaic(lon, lat; pt_radius=6378137.0, provider="", zoom::Int=0, cache::String="",
               mapwidth=15, dpi=96, verbose::Int=0, kw...)

Get image tiles from a web map tiles provider for given longitude, latitude coordinates.

### Arguments
- `lon` & `lat`:
  - `lon, lat`: two scalars with the coordinates of region of interest center. To completly define
    the image area see the `neighbors` or `mosaic` option below.
  - `lon, lat` are two elements vector or matrix with the region's [lon\\_min, lon\\_max], [lat\\_min, lat\\_max].
  - Instead of two arguments, pass just one containing a GMTdataset obtained with the ``geocoder`` function.
    Example: ``mosaic(D, ...)`` or, if the search with ``geocoder`` was sufficiently generic (see its docs),
    ``mosaic(D, bbox=true)`` to use the BoundingBox returned by the query. `bbox` supports `bb`, `BB` or
    `BoundingBox` as aliases.
  - Yet another alternative is to pass either a GMTgrid or a GMTimage with a valid projection, and it doesn't
    need to be in geographic coordinates. Coordinates in other reference systems will be converted to geogs.
  - Finaly, all of the above options can be skipped if the keyword `region` is used. Note that this option is
    the same as in, for example, the ``coast`` module. And that means we can use it with
    ``earthregions`` arguments. _e.g._ ``region="IT"`` is a valid option and will get the tiles
    needed to build an image of Italy.

- `pt_radius`: The planetary radius. Defaults to Earth's WGS84 equatorial radius (6378137 m).
- `provider`: Tile provider name. Currently available options are (but for more details see the docs of the
  `getprovider` function, *i.e.* ``? getprovider``):
  - "Bing" (the default), "Google", "OSM", "Esri" or a custom provider.
  - A `Provider` type from the ``TileProviders.jl`` package. You must consult the documentation of that package
    for more details on how to choose a *provider*.
- `zoom`: Zoom level (0 for automatic). A number between 0 and ~19. The maximum is provider and area dependent.
  If `zoom=0`, the zoom level is computed automatically based on the `mapwidth` and `dpi` options.
- `cache`: Full name of the the cache directory where to save the downloaded tiles. If empty, a cache
  directory is created in the system's TMP directory. If `cache="gmt"` the cache directory is created in
  ``~/.gmt/cache_tileserver``. NOTE: this normally is neeaded only for the first time you run this function when,
  if `cache != ""`, the cache dir location is saved in the ``~./gmt/tiles_cache_dir.txt`` file and used in
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
- `tilesmesh` or `meshtiles` or `mesh`: Return a `GMTdataset` with the mesh of tiles.

### Returns
- `I`: A GMTimage element or the output of the `quadonly` option explained above.

# Examples
```jldoctest
julia> I = mosaic(0.1,0.1,zoom=1)
viz(I, coast=true)
```

```jldoctest
# Return a GMTdataset with the mesh of tiles and viz it.
D = mosaic(region=(-10, -8, 37, 39), zoom=9, mesh=true);
viz(D, coast=true)
```
"""
function mosaic(D::GDtype; pt_radius=6378137.0, provider="", zoom::Int=0, cache::String="",
                mapwidth=15, dpi=96, date::String="", verbose::Int=0, kw...)
	if (find_in_kwargs(kw, [:bb :BB :bbox :BoundingBox])[1] !== nothing)
		lon, lat = isa(D, GMTdataset) ? (D.ds_bbox[1:2], D.ds_bbox[3:4]) : (D[1].ds_bbox[1:2], D[1].ds_bbox[3:4])
	else
		lon, lat = isa(D, GMTdataset) ? (D.data[1,1], D.data[1,2]) : (D[1].data[1,1], D[1].data[1,2])
	end
	mosaic(lon, lat; pt_radius=pt_radius, provider=provider, zoom=zoom, cache=cache, mapwidth=mapwidth,
           dpi=dpi, date=date, verbose=verbose, kw...)
end

"""
I = mosaic(GI::Union{GMTgrid, GMTimage}; ...)

Same as above but the `lon` & `lat` are extracted from the `GI` header. The grid or image `GI` must have set a valid
projection, and it doesn't need to be in geographic coordinates. Coordinates in other reference systems will be converted to geogs.
"""
function mosaic(GI::GItype; pt_radius=6378137.0, provider="", zoom::Int=0, cache::String="",
                mapwidth=15, dpi=96, date::String="", verbose::Int=0, kw...)
	((prj = getproj(GI, proj4=true)) == "") && error("To use the 'mosaic' function with a grid or image this has to have a valid projection")
	if isgeog(prj)
		lon, lat = GI.range[1:2], GI.range[3:4]
	else
		ll = xy2lonlat([GI.range[1] GI.range[3]; GI.range[2] GI.range[4]], s_srs=prj)
		lon, lat = ll[:,1], ll[:,2]
	end
	mosaic(lon, lat; pt_radius=pt_radius, provider=provider, zoom=zoom, cache=cache, mapwidth=mapwidth,
           dpi=dpi, date=date, verbose=verbose, kw...)
end

"""
I = mosaic(; region=??, ...)

Same as above but this time the BoundingBox is extracted from the `region` option. Note that this option is the same as
in, for example, the `coast` module.

# Example
```jldoctest
julia> I = mosaic(region=(91,110,6,22))		# zoom level is computed automatically
viz(I, coast=true)
```
"""
function mosaic(; pt_radius=6378137.0, provider="", zoom::Int=0, cache::String="",
                mapwidth=15, dpi=96, date::String="", verbose::Int=0, kw...)
	isempty(kw) && return mosaic(zoom)		# Call the method that only prints the zoom levels table.
	d = KW(kw)
	((opt_R = parse_R(d, "")[1]) == "") && error("To use the 'mosaic' function without the 'lon & lat' arguments you need to specify the 'region' option.")
	ll = opt_R2num(opt_R)
	lon, lat = ll[1:2], ll[3:4]
	mosaic(lon, lat; pt_radius=pt_radius, provider=provider, zoom=zoom, cache=cache, mapwidth=mapwidth,
           dpi=dpi, date=date, verbose=verbose, d...)
end

# This method is mostly for calls from python's juliacall that used PyList (because dumb Py consider this a list: [1.0, 2.6])
function mosaic(lon::AbstractVecOrMat, lat::AbstractVecOrMat; pt_radius=6378137.0, provider="", zoom::Int=0, cache::String="",
                mapwidth=15, dpi=96, verbose::Int=0, date::String="", key::String="", kw...)
	_lon::Vector{Float64}, _lat::Vector{Float64} = vec(Float64.(lon)), vec(Float64.(lat))
	mosaic(_lon, _lat; pt_radius=pt_radius, provider=provider, zoom=zoom, cache=cache, mapwidth=mapwidth,
           dpi=dpi, date=date, verbose=verbose, key=key, kw...)
end

function mosaic(lon::Tuple{<:Real, <:Real}, lat::Tuple{<:Real, <:Real}; pt_radius=6378137.0, provider="", zoom::Int=0, cache::String="",
                mapwidth=15, dpi=96, verbose::Int=0, date::String="", key::String="", kw...)
	_lon::Vector{Float64}, _lat::Vector{Float64} = Float64.([lon...]), Float64.([lat...])
	mosaic(_lon, _lat; pt_radius=pt_radius, provider=provider, zoom=zoom, cache=cache, mapwidth=mapwidth,
           dpi=dpi, date=date, verbose=verbose, key=key, kw...)
end

function mosaic(lon::Real, lat::Real; pt_radius=6378137.0, provider="", zoom::Int=0, cache::String="",
                mapwidth=15, dpi=96, verbose::Int=0, date::String="", key::String="", kw...)
	mosaic([Float64(lon)], [Float64(lat)]; pt_radius=pt_radius, provider=provider, zoom=zoom,
           cache=cache, mapwidth=mapwidth, dpi=dpi, date=date, verbose=verbose, key=key, kw...)
end

"""
I = mosaic(address::String; ...)

Same as above but the `lon` & `lat` are extracted from the `address` code. The code can be a ``quadtree`` or a ``XYZ``
tile address. This is a more specialized usage that relies on users knowledge on tile code names based on quadtrees
or XYZ encoding. An example of these codes is provided by the attributes of when we use the `mesh=true` option.

An important difference between the `address` option and the `lon & lat` option is that the `address` option also
set the zoom level, so here the ``zoom`` option means the extra zoom level added to that implied by ``address``.
A number higher than 3 is suspiciously large.

# Example
```jldoctest
julia> I = mosaic("033110322", zoom=2)
viz(I, coast=true)
```
"""
function mosaic(address::String; pt_radius=6378137.0, provider="", zoom::Int=0, cache::String="",
                verbose::Int=0, date::String="", key::String="", kw...)

	lims, zoomL = mosaic_limits(address)
	mosaic(lims[1:2], lims[3:4]; pt_radius=pt_radius, provider=provider, zoom=zoomL+zoom, cache=cache,
	       date=date, verbose=verbose, key=key, kw...)
end

# ----------------------------------------------------------------------------------------------------------
"""
    lims, zoomL = mosaic_limits(address::String)

Helper function that returns the limits and zoom level implied by the address.

The `address` can be a ``quadtree`` or a ``XYZ`` tile address.
"""
function mosaic_limits(address::String)
	s = split(address, ",")
	(length(s) != 3 && length(s) != 1) && throw(error("Wrong type of tile address: $address"))

	# Functions for parsing the tiles XYZ code when given as ranges. E.g. "317-9" means 317 to 319 or 317+2 -> 315 to 319
	function parse_LL(s_ind, ind)			# This version is for the form: 317-9 or 319-21
		base, add = s_ind[1:ind-1], s_ind[ind+1:end]
		first = parse(Int, base)
		t = (length(add) == 1) ? base[1:end-1] * add : base[1:end-2] * add
		last  = parse(Int, t)
		return first, last
	end
	function parse_CC(s_ind, ind)			# This version is for the form: 317+2
		base, add = parse(Int, s_ind[1:ind-1]), parse(Int, s_ind[ind+1:end])
		return base-add, base+add
	end

	if (length(s) == 3)
		if     ((ind = findfirst('-', s[1])) !== nothing)  xf, xl = parse_LL(s[1], ind)
		elseif ((ind = findfirst('+', s[1])) !== nothing)  xf, xl = parse_CC(s[1], ind)
		else                                               xf = parse(Int, s[1]);	xl = xf
		end

		if     ((ind = findfirst('-', s[2])) !== nothing)  yf, yl = parse_LL(s[2], ind)
		elseif ((ind = findfirst('+', s[2])) !== nothing)  yf, yl = parse_CC(s[2], ind)
		else                                               yf = parse(Int, s[2]);	yl = yf
		end
		zoomL = parse(Int, s[3])
		if (xf != xl || yf != yl)
			#limsLL::Matrix{Float64} = quadkey([xf, yf, zoomL])			# Each comes as 2x2 with [xmin ymin; xmax ymax]
			#limsUR::Matrix{Float64} = quadkey([xl, yl, zoomL])
			#lims::Vector{Float64} = [min(limsLL[1], limsUR[1]), max(limsLL[2], limsUR[2]), min(limsLL[3], limsUR[3]), max(limsLL[4], limsUR[4])]
			tLL = quadbounds_limits(XY2quadtree(xf, yf, zoomL))[1][1]	# A 5x2 matrix with the square corners (first_pt = last_pt)	
			tUR = quadbounds_limits(XY2quadtree(xl, yl, zoomL))[1][1]
			lims = [min(tLL[1,1], tUR[1,1]), max(tLL[3,1], tUR[3,1]), min(tLL[1,2], tUR[1,2]), max(tLL[3,2], tUR[3,2])]
		else
			#lims = vec(quadkey([xf, yf, zoomL]))
			tq = quadbounds_limits(XY2quadtree(xf, yf, zoomL))[1][1]	# A 5x2 matrix with the square corners (first_pt = last_pt)	
			lims = [tq[1,1], tq[3,1], tq[1,2], tq[3,2]]
		end
	else
		v, zoomL = quadbounds_limits(address)
		lims = collect(Float64, Iterators.flatten(extrema(v[1], dims=1)))
		if (length(v) > 1)
			for k = 2:numel(v)
				_lims = collect(Float64, Iterators.flatten(extrema(v[k], dims=1)))
				lims[1] = min(lims[1], _lims[1]);		lims[2] = max(lims[2], _lims[2])
				lims[3] = min(lims[3], _lims[3]);		lims[4] = max(lims[4], _lims[4])
			end
		end
		zoomL -= 1						# Also because in getQuadLims() we add 1 to zoom.
	end
	return lims, zoomL
end

# ----------------------------------------------------------------------------------------------------------
"""
I = mosaic(address::VecOrMat{<:Real}; ...)

Very similar to above but where `address` is a ``XYZ`` tile address given as a vector of 3 integers.
"""
function mosaic(address::VecOrMat{<:Real}; pt_radius=6378137.0, provider="", zoom::Int=0, cache::String="",
                verbose::Int=0, date::String="", key::String="", kw...)
	(length(address) != 3) && throw(error("Wrong type of tile XYZ address ... must have X, Y and Z"))
	s_addr = join(string.(address), ",")
	mosaic(s_addr; pt_radius=pt_radius, provider=provider, zoom=zoom, cache=cache, verbose=verbose, date=date, key=key, kw...)
end

# ----------------------------------------------------------------------------------------------------------
# All methods above will land here and are guarantied to have a unique input type for lon, lat.
function mosaic(lon::Vector{<:Float64}, lat::Vector{<:Float64}; pt_radius=6378137.0, provider="", zoom::Int=0, cache::String="",
                mapwidth=15, dpi=96, verbose::Int=0, date::String="", key::String="", kw...)
	(length(lon) != length(lat)) && throw(error("lon & lat must be of the same size"))
	d = Dict{Symbol,Any}(kw)
	flatness = 0.0		# Not needed because the tile servers serve data in spherical Mercator, but some funs expect flatness

	(mapwidth < 1) && error("Don't joke with us, a map with a width less than 1 cm???")
	(length(lon) == 1 && zoom == 0) && error("Need to specify zoom level for single point query")
	(zoom == 0) && (zoom = guessZoomLevel(mapwidth, (lon[2]-lon[1]), dpi))

	quadTiles = (find_in_dict(d, [:tilesmesh :meshtiles :mesh])[1] !== nothing) ? true : false
	quadTiles && (provider = "mesh")
	provider_url, zoom, ext, isZXY, isZYX, provider_code, variant, sitekey = getprovider(provider, zoom, date=date, key=key)
	isXeYeZ = contains(provider_url, "lyrs=")
	isBing  = contains(provider_url, "virtualearth")

	# Check for user cache location
	f = joinpath(GMTuserdir[1], "tiles_cache_dir.txt")
	if (cache == "")
		(isfile(f)) && (cache = readline(f))
		length(cache) < 3 && (cache = joinpath(TMPDIR_USR[1], "cache_" * TMPDIR_USR[2] * TMPDIR_USR[3]))
	else
		(cache == "gmt") && (cache = joinpath(GMTuserdir[1], "cache_tileserver"))	# cache it in ~/.gmt
		(isfile(f)) && rm(f)			# Remove old cache location
		write(f, cache)					# Save new cache location
	end

	quadkey::Matrix{Char} = ['0' '1'; '2' '3']
	quadonly  = ((val = find_in_dict(d, [:quadonly])[1]) !== nothing) ? true : false
	inMerc    = ((val = find_in_dict(d, [:merc :mercator])[1]) !== nothing) ? true : false
	isExact   = ((val = find_in_dict(d, [:loose :loose_bounds])[1]) === nothing) ? true : false
	(isExact && length(lon) == 1) && (isExact = false)
	neighbors::Matrix{Float64} = ((val = find_in_dict(d, [:N :neighbors :neighbours :mosaic])[1]) === nothing) ? [1.0;;] : isa(val, Int) ? ones(Int64(val),Int64(val)) : ones(val[1],val[2])
	(length(neighbors) > 1 && length(lon) > 1) && error("The 'neighbor' option is only for single point queries.")
	delete!(d, [[:bb], [:BB], [:bbox], [:BoundingBox]])		# Remove this valid ones befor checking for mistakes.
	(length(d) > 0) && println("\n\tWarning: the following options were not consumed in mosaic => ", keys(d),"\n")

	any(lat .> 85.0511)  && (lat[lat .> 85.0511]  .= 85.0511)
	any(lat .< -85.0511) && (lat[lat .< -85.0511] .= -85.0511)
	lon = wraplon180!(lon)		# Make sure that longitudes are in the range -180 to 180 (for scalars need a return value)

	lat_orig = lat				# Save original lat for eventual use in the exact region option
	lon[1]   += 1e3eps()		# To avoid the last tile being beyond the limits when it was original AT the limts (exact limits match)
	lat[1]   += 1e3eps()
	if (length(lon) > 1)
		lon[end] -= 1e3eps()
		lat[end] -= 1e3eps()
	end
	lat = geod2isometric(lat, flatness)
	x, y, xmm, ymm = getPixel(lon, lat, zoom)		# x,y are the fractional number of the 256 bins counting from origin
	x, y = floor.(x), floor.(y)
	lon_mm, latiso_mm = getLonLat(xmm, ymm, zoom+8)	# WHY + 8 ?
	latiso_mm = flipud(latiso_mm[:, end:-1:1])		# Flip because origin was top -> down. flipud to have south at 1 row and growing north with rows
	lat_mm = isometric2geod(latiso_mm, flatness)

	# ---------------------- Case when rectangle BB was given
	if (length(lon) == 2)					# See if have other tiles in between the ones deffined by lon_min and lon_max
		Dtile = xmm[2, 1] - xmm[1, 2]		# > 0, have tiles in the midle; == 0, two contiguous tiles; < 0, same tile
		nInTilesX = Dtile > 0 ? Int(Dtile / 256) : Dtile == 0 ? 0 : -1

		Dtile = ymm[2, 1] - ymm[1, 2]		# Idem for lat
		nInTilesY = Dtile > 0 ? Int(Dtile / 256) : Dtile == 0 ? 0 : -1
		neighbors = ones(Int(nInTilesY)+2, Int(nInTilesX)+2)		# Create the neighbors matrix

		lon_mm = [minimum(lon_mm), maximum(lon_mm)]
		lat_mm = [minimum(lat_mm), maximum(lat_mm)]
		latiso_mm = [minimum(latiso_mm), maximum(latiso_mm)]

		# Calculate center so that the below MxN neighbors code case can be reused
		_x = div((x[1] + x[2]), 2)
		_y = div((y[1] + y[2]), 2)
	else
		_x, _y = x[1], y[1]
	end

	# ---------------------- CORE THING ---- Calculate the quadtree string
	quadtree = ""
	for i in 1:zoom-1
		_x, _rx = divrem(_x, 2);		rx = Int(_rx) + 1
		_y, _ry = divrem(_y, 2);		ry = Int(_ry) + 1
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
				(provider_code == "nimbo") && (decAdr[2] = 2^zoom - decAdr[2])		# Because Nimbus count y from top (shit)
				(isZYX) && (decAdr = [decAdr[2], decAdr[1]])		# Swap x and y because Esri uses z,y,x instead of z,x,y
				if (isXeYeZ)
					tile_url[i+mc, j+nc] = string(provider_url, decAdr[1], "&y=", decAdr[2], "&z=$(zoom)")
				elseif (isZXY)
					tile_url[i+mc, j+nc] = string(pref_bak, zoom, "/", decAdr[1], "/", decAdr[2], ".", ext)
				else
					tile_url[i+mc, j+nc] = provider_url * quad_[i+mc, j+nc]
				end
				(sitekey != "") && (tile_url[i+mc, j+nc] *= sitekey)
			end
		end
	end

	if length(lon) == 1				# Otherwise (rectangle limits on input) we already know them
		lon_mm = [lon_mm[1] + nn[1] * (lon_mm[2] - lon_mm[1]), lon_mm[2] + nn[2] * (lon_mm[2] - lon_mm[1])]
		latiso_mm = [latiso_mm[1] - mm[2] * (latiso_mm[2] - latiso_mm[1]), latiso_mm[2] - mm[1] * (latiso_mm[2] - latiso_mm[1])]
		lat_mm = isometric2geod(latiso_mm, flatness)
	end

	(flatness != 0) && (pt_radius *= pt_radius / meridionalRad(pt_radius, flatness))

	xm, ym = geog2merc(lon_mm, (flatness == 0) ? lat_mm : latiso_mm, pt_radius)

	# -------- Return here if only the quadtree is needed ---------
	quadonly && return quad_, decimal_adress, lon_mm, lat_mm, xm, ym

	# Return here if user wants a GMTdataset with the coordinates of the tiles
	quadTiles && return quadbounds(quad_; quadkey=quadkey)[1]

	# ------------------ Get the tiles and build up the image --------------------
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

	xx = collect(linspace(xm[1], xm[2], size(img,1)+1))
	yy = collect(linspace(ym[1], ym[2], size(img,2)+1))
	I::GMTimage{UInt8, 3} = mat2img(img, x=xx, y=yy, proj4="+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=$pt_radius +b=$pt_radius +units=m +no_defs", layout="TRBa", is_transposed=true)
	@assert typeof(I) === GMTimage{UInt8, 3}	# Fck compiler. Not even this convinced it to make I type stable

	if (inMerc && isExact)		# Cut to the exact required limits
		mat::Matrix{Float64} = mapproject([lon[1] lat_orig[1]; lon[2] lat_orig[2]], J=I.proj4).data
		I = grdcut(I, R=(mat[1,1], mat[2,1], mat[1,2], mat[2,2]))::GMTimage{UInt8, 3}
	elseif (!inMerc)			# That is, if project to Geogs
		gdwopts = ["-t_srs","+proj=latlong +datum=WGS84", "-r","cubic"]
		isExact && append!(gdwopts, ["-te"], ["$(lon[1])"], ["$(lat_orig[1])"], ["$(lon[2])"], ["$(lat_orig[2])"])
		I = gdalwarp(I, gdwopts)::GMTimage{UInt8, 3}
	end

	return I
end

# ---------------------------------------------------------------------------------------------------
"""
	quadtree = XY2quadtree(x, y, zoom; quadkey::Matrix{Char}=['0' '1'; '2' '3']) -> String

Convert the tile coordinates `x` and `y` to the quadtree string.
"""
function XY2quadtree(x, y, zoom; quadkey::Matrix{Char}=['0' '1'; '2' '3'])
	quadtree = ""
	_x::Int, _y::Int = Int(x), Int(y)
	for i = 1:zoom
		_x, _rx = divrem(_x, 2);		rx = Int(_rx) + 1
		_y, _ry = divrem(_y, 2);		ry = Int(_ry) + 1
		quadtree *= quadkey[ry, rx]
	end
	return quadtree[end:-1:1]
end

# ---------------------------------------------------------------------------------------------------
"""
    mosaic([zoom::Int=??])

Print a table with the zoom level characteristics in terms of tile sizes, resolutions, typical use.

If the `zoom` option is used then the table is printed with that zoom level only.

# Example
```jldoctest
julia> mosaic(zoom=10)
┌───────┬────────────────┬────────────┬────────────────┬────────────────────┐
│ Level │     Tile width │  m / pixel │         ~Scale │        Examples of │
│       │ ° of longitude │ on Equator │                │ areas to represent │
├───────┼────────────────┼────────────┼────────────────┼────────────────────┤
│    10 │          0.352 │    153.054 │ 1:500 thousand │  metropolitan area │
└───────┴────────────────┴────────────┴────────────────┴────────────────────┘
```
"""
function mosaic(zoom)
	(zoom < 1 || zoom > 22) && (zoom = 0)
	hdr = (["Level", "Tile width", "m / pixel", "~Scale", "Examples of"], ["", "° of longitude", "on Equator", "", "areas to represent"])
	data = Any[
			1  180 78_272 "1:250 million" ""
			2   90 39_136 "1:150 million" "subcontinental area"
			3   45 19_568 "1:70 million"  "largest country"
			4   22.5  9_784 "1:35 million" ""
			5 	11.25 4_892 "1:15 million" "large African country"
			6 	5.625 2_446 "1:10 million" "large European country"
			7 	2.813 1_223 "1:4 million" "small country, US state"
			8 	1.406 611.388 "1:2 million" ""
			9 	0.703 305.694 "1:1 million" "wide area, large metropolitan area"
			10 	0.352 153.054 "1:500 thousand" "metropolitan area"
			11 	0.176 76.532 "1:250 thousand" "city"
			12 	0.088 38.266 "1:150 thousand" "town, or city district"
			13 	0.044 19.133 "1:70 thousand" "village, or suburb"
			14 	0.022 9.566 "1:35 thousand" ""
			15 	0.011 4.783 "1:15 thousand" "small road"
			16 	0.005 2.174 "1:8 thousand" "street"
			17 	0.003 1.305 "1:4 thousand" "block, park, addresses"
			18 	0.001 0.435 "1:2 thousand" "some buildings, trees"
			19 	0.0005 0.217 "1:1 thousand" "local highway and crossing details"
			20 	0.00025 0.109 "1:5 hundred" "A mid-sized building"
			21 	0.000125 0.054 "1:250" ""
		]
	println("\t\t\t\tZoom levels")
	(zoom == 0) ? pretty_table(data; header=hdr) : pretty_table(data[zoom:zoom, :]; header=hdr)
end

# ---------------------------------------------------------------------------------------------------
"""
    getprovider(name, zoom::Int; variant="", date::String="", key::String="")

Get information about a tile provider given its name and zoom level. The returned information
is only relevant for internal use and is an implementation detail not documented here.

### Arguments
- `name`: Name of the tile provider. Currently available are "Bing" (the default), "Google", "OSM", "Esri", "Nimbo".
  Optionally, the `name` can be a tuple of two strings, where the first string is the provider name
  and the second string is the variant name (see the `variant` bellow).

- The `name` argument can also be a `Provider` type from the TileProviders.jl package. For example,
  after importing TileProviders.jl, ``provider = NASAGIBSTimeseries()`` and next pass it to `getprovider`.

- `date`: Currently only used with the 'Nimbo' provider. Pass date in 'YYYY_MM' or 'YYYY,MM' format.

- `key`: Currently only used with the 'Nimbo' provider. Pass your https://nimbo.earth/ API key.

- `zoom`: Requested zoom level. Will be capped at the provider's maximum.

- `variant`: Optional variant for providers with multiple map layers.
  - `Bing`: variants => "Aerial" (default), "Road", or "Hybrid".
  - `Google`: variants => "Satellite", "Road", "Terrain", or "Hybrid".
  - `Esri`: variants => "World\\_Street\\_Map" (default), "Elevation/World\\_Hillshade", or "World\\_Imagery".
  - `Nimbo`: variants => "RGB" (default), "NIR", "NDVI", or "RADAR".
"""
getprovider(name::Tuple{String,String}, zoom::Int; date::String="", key="") = getprovider(name[1], zoom; variant=name[2], date=date, key=key)
function getprovider(name::StrSymb, zoom::Int; variant="", format="", ZYX::Bool=false, dir_code="", date::String="", key::String="")
	# The 'format', 'dir_code' and 'ZYX' kwargs are of internal use only and passed in when using a TileProviders type
	sitekey = ""
	isZXY, ext = false, "jpg"
	isZYX = ZYX ? true : false
	(format != "") && (ext = format)
	_name::String = lowercase(string(name))
	if (_name == "" || _name == "bing")
		t::String = (variant == "") ? "a" : string(lowercase(variant)[1])
		(t != "a" && t != "r" && t != "h") && error("Bing only supports 'a' (Aerial), 'r' (Road) or 'h' (Hybrid)")
		url::String = "http://" * t * "0.ortho.tiles.virtualearth.net/tiles/" * t;
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
	elseif (startswith(_name, "nimb"))
		(key == "") && error("Nimbo provider requires a key. You can get one from https://www.nimbo.earth/ by opening a free account.")
		(variant == "") && (variant = "RGB")
		vv = lowercase(variant)
		v = (vv == "rgb") ? '1' : vv == "nir" ? '2' : vv == "ndvi" ? '3' : '4'
		(v == '4') && (variant = "RADAR")				# To play safe
		(length(date) == 0 || (length(date) != 6 && length(date) == 7)) || (date[5] != '_' && date[5] != ',') &&
			error("Date must be in 'YYYY_MM' or 'YYYY,MM' format")
		d = (date == "") ? "2023_12" : date[5] == ',' ? replace(date, "," => "_") : date
		(d[6] == '0') && (d = d[1:5] * d[7])			# If the month is 01, make it 1 (same for 02, 03, etc)
		variant = d * "_" * v * filesep * variant		# Need to carry also the dates (this will be used in cache name)
		url = "https://prod-data.nimbo.earth/mapcache/tms/1.0.0/" * d * "_" * v * "@kermap/"
		max_zoom = 13;	isZXY = true; code = "nimbo";	ext = "png";	sitekey = "?kermap_token=" * key
	#elseif (_name == "ortosat")							# 
		# variants: CorVerdadeira, falsacor
		#layer = (variant == "falsacor") ? 1 : 2
		#wms = wmsinfo("https://ortos.dgterritorio.gov.pt/wms/ortosat2023?service=wms&request=getcapabilities")
		#url, isZXY, max_zoom, code = wms, true, 19, "ortosat"
	elseif (_name == "mesh")							# For mesh we don't care the provider and max zoom is ilimitted
		url, isZXY, max_zoom, code = string(name), true, 50, "unknown"
	else
		!startswith(_name, "http") && @warn("Unrecognized provider: $name. Quite likely this is not a valid name.")
		url, isZXY, max_zoom, code = string(name), true, 22, dir_code == "" ? "unknown" : dir_code
	end
	zoom += 1
	(zoom > max_zoom+1) && (zoom = max_zoom+1; @warn("Zoom level $zoom is too high for the '$code' provider. Zoom level set to $max_zoom"))
	return url, zoom, ext, isZXY, isZYX, code, variant, sitekey
end

# ---------------------------------------------------------------------------------------------------
function getprovider(arg, zoom::Int; date::String="", key="")
	# This method uses as input a TileProviders type. Note that we don't have TileProviders as a dependency
	# but make a dummy guess about it. NOTE: the 'date and key' keywords are ignored here but needed for a signature match
	# Example usage: (night lights)
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
    Dtiles, zoomL = quadbounds(quadtree; geog=true, quadkey=['0' '1'; '2' '3'])

Compute the coordinates of the `quadtree` quadtree. Either a single quadtree string or an array
of quadtree strings.

- `quadtree`: Either a single quadtree string or a `Matrix{String}` of quadtree strings.
  This is the quadtree string or array of strings to compute coordinates for and is obtained
  from a call to the `mosaic` using the `quadonly` option (see example below).
- `quadkey=['0' '1'; '2' '3']`: The quadkey for the quadtree.

### Returns
- `Dtiles`: A GMTdataset vector with the corner coordinates of each tile.
- `zoomL`: Zoom level of the tiles.

### Example
```jldoctest
  quadtree = mosaic([-10. -8],[37. 39.], zoom=8, quadonly=1)[1];
  D = quadbounds(quadtree)[1];
  viz(D)
```
"""
quadbounds(quadtree::String; geog=true, quadkey=['0' '1'; '2' '3']) = quadbounds([quadtree;;]; geog=geog, quadkey=quadkey)
function quadbounds(quadtree::Matrix{String}; geog=true, quadkey=['0' '1'; '2' '3'])
	v, zoomL = quadbounds_limits(quadtree; geog=geog, quadkey=quadkey)
	proj = geog ? prj4WGS84 : "+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +a=6378137 +b=6378137 +units=m +no_defs"
	D = mat2ds(v, proj=proj, geom=wkbPolygon)
	D[1].comment = ["Zoom level = $zoomL"]
	for k = 1:numel(D)						# Add tile addresses as attributes
		D[k].attrib["quadtree"] = quadtree[k]
		XY = getQuadLims(quadtree[k], quadkey, 1)[1]
		D[k].attrib["XYZ"] = join(string.(XY), ",") * ",$(zoomL-1)"
	end
	(length(D) == 1) && (D = D[1])
	set_dsBB!(D)
	return D, zoomL
end

# This helper function is useful when we want only the limits and no extra overhead of a GMTdataset
quadbounds_limits(quadtree::AbstractString; geog=true, quadkey=['0' '1'; '2' '3']) = quadbounds_limits([quadtree;;]; geog=geog, quadkey=quadkey)
function quadbounds_limits(quadtree::Matrix{<:AbstractString}; geog=true, quadkey=['0' '1'; '2' '3'])
	flatness = 0.0
	
	tiles_bb = zeros(length(quadtree), 4)
	isempty(tiles_bb) && error("The 'quadtree' input cannot be empty.")		# #1711		
	zoomL = 0			# Can't stand this need. F. F. F
	for k = 1:length(quadtree)
		lim, zoomL = getQuadLims(quadtree[k], quadkey, "")		# Remember that lim(3) = y_max
		tiles_bb[k, :] .= lim
	end
	
	tiles_bb[:, 3:4] .= isometric2geod(tiles_bb[:, 4:-1:3], flatness)
	v = Vector{Matrix{Float64}}(undef, size(tiles_bb, 1))
	for k = 1:size(tiles_bb, 1)
		v[k] = [tiles_bb[k,1] tiles_bb[k,3];
		        tiles_bb[k,1] tiles_bb[k,4];
				tiles_bb[k,2] tiles_bb[k,4];
				tiles_bb[k,2] tiles_bb[k,3];
				tiles_bb[k,1] tiles_bb[k,3]]
		if (!geog)  xm, ym = geog2merc(v[k][:,1], v[k][:,2], 6378137.0);	v[k] = [xm ym]	end
	end
	return v, zoomL
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
	(length(H) > N) && (H = dec2bin(h - 1, N))

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
	_, quadtree, = fileparts(quadtree)		# If quadtree is a filename, retain only what matters
	
	zoomL = length(quadtree) + 1
	quad_x = zeros(Int, zoomL)
	quad_y = zeros(Int, zoomL)

	# MAPPING: X -> 0=0 1=1 3=1 2=0;		Y -> 0=0 1=0 3=1 2=1
	quad_x[findall(quadkey[1, 2], quadtree)] .= 1
	quad_x[findall(quadkey[2, 1], quadtree)] .= 0
	quad_x[findall(quadkey[2, 2], quadtree)] .= 1
	
	quad_y[findall(quadkey[1, 2], quadtree)] .= 0
	quad_y[findall(quadkey[2, 1], quadtree)] .= 1
	quad_y[findall(quadkey[2, 2], quadtree)] .= 1
	
	pixelX, pixelY = 0, 0
	
	for k = 1:length(quadtree)
		pixelX = pixelX * 2 + quad_x[k]
		pixelY = pixelY * 2 + quad_y[k]
	end
	
	if isempty(opt)
		lon1, lat1 = getLonLat(pixelX, pixelY, zoomL)
		lon2, lat2 = getLonLat(pixelX + 1, pixelY + 1, zoomL)
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
	y = (180 .- lat) * pixPerDeg .+ 1e5 * eps()	# Don't know why I use floor instead of round but floor may "floor" to the wrong side.
	isa(y, VecOrMat) && (y = y[end:-1:1])			# WHY ?????
	
	if length(lon) == 1
		xmm = [floor.(x) floor.(x) .+ 1] * 256		# [x_min x_max] pixel coords of the rectangle
		ymm = [floor.(y) floor.(y) .+ 1] * 256
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
function geocoder(address::String; options=String[])::GDtype
	# Get the geocoder info for a given address. Adapted from https://www.itopen.it/geocoding-with-gdal/

	_ops = isempty(options) ? C_NULL : options	# The default is ["SERVICE", "OSM_NOMINATIM"]
	hSession = GMT.Gdal.OGRGeocodeCreateSession(_ops)
	hLayer = GMT.Gdal.OGRGeocode(hSession, address, C_NULL, [""])
	hFDefn = GMT.Gdal.OGR_L_GetLayerDefn(hLayer)
	hFeature = GMT.Gdal.OGR_L_GetNextFeature(hLayer)
	count = GMT.Gdal.OGR_FD_GetFieldCount(hFDefn)
	(count == 0) && (@warn("No result found for the address $address"); return GMTdataset())
	dic = Dict{String,String}()
	for k = 0:count-1
		hFieldDefn = GMT.Gdal.OGR_FD_GetFieldDefn(hFDefn,k)
		((val = GMT.Gdal.OGR_F_GetFieldAsString(hFeature, k)) != "") && (dic[GMT.Gdal.OGR_Fld_GetNameRef(hFieldDefn)] = val)
	end

	BB = parse.(Float64, split(dic["boundingbox"], ","))
	GMT.Gdal.OGRGeocodeFreeResult(hLayer)
	GMT.Gdal.OGRGeocodeDestroySession(hSession)
	D::GDtype = mat2ds([parse(Float64, dic["lon"]) parse(Float64, dic["lat"])], attrib=dic, proj4=prj4WGS84, geom=wkbPoint)
	D.ds_bbox = [BB[3], BB[4], BB[1], BB[2]]
	return D
end

# ------------------------------------------------------------------------------------------------
"""
    istilename(s::AbstractString)

Check if the string `s` is a XYZ or quadtree tile name. Useful for parse_R() and others that can
than extract the tile limits and associated resolution.
"""
function istilename(s::AbstractString)::Bool
	(count_chars(s, ',') == 2) && return true
	contains(s, "-R") && occursin(r"^[0-3]+$", s[findfirst('R', s)+1:end]) && return true	# Accepts also that 's' is an opt_R
	occursin(r"^[0-3]+$", s) && return true
	return false
end
