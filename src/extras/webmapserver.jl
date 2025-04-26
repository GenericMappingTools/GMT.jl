struct WMSlayer
	name::String
	title::String
	srs::String
	crs::String
	bbox::NTuple{4,Float64}
	imgformat::String
	tilesize::Int
	overviewcount::Int
	resolution::Float64
	tiled::Bool
	transparent::Bool
end
struct WMS
	serverURL::String
	OnlineResource::String
	version::String
	request::String
	layernames::Vector{String}
	layer::Vector{WMSlayer}
end

# ---------------------------------------------------------------------------------------------------
"""
    wmsinfo(server::String)

Read the xml information from the WebMapServer service and create a WMS data type that holds the information
necessary to download the data. The `show` method will display the contents of the WMS data type.

- `server`: The server URL address.

## Example
    wms = wmsinfo("http://tiles.maps.eox.at/wms?")

As an option, use the form

    wmsinfo(wms; layer)

to get further information, in particular the number of bands and sizes, of the layer number or layer name `layer`. `wms` is
returned by the first form.
"""
function wmsinfo(server::String)::WMS
	w = gdalinfo("WMS:" * server)
	(w === nothing) && error("unable to open '$(server)'")
	sds = split(w, "SUBDATASET_")
	lastguy = collect(2:2:length(sds))[end]

	names, layers = String[], WMSlayer[]

	onlineRes::String, ver::SubString{String}, req::SubString{String}, name::SubString{String}, srs::SubString{String}, crs::SubString{String}, bbox, fmt::SubString{String}, ts, cnt, res, til, trans = "", "", "", "", "", "", zeros(4), "", 0, 0, 0., false, false
	for k = 2:2:length(sds)
		f = split(sds[k], '&')
		if (k == 2)					# "f[1] = 1_NAME=WMS:http://tiles.maps.eox.at/?SERVICE=WMS"
			ind = findfirst("=", f[1]); t = f[1][ind[1]+5:end]
			ind = findfirst("?", t);	onlineRes = t[1:ind[1]]
		end
		for n = 2:numel(f)			# Loop over the fields of the SUBDATASET_XX_NAME
			if     (startswith(f[n], "VERSION"))  ver = f[n][9:end];  continue
			elseif (startswith(f[n], "REQUEST"))  req = f[n][9:end];  continue
			elseif (startswith(f[n], "LAYERS"))   name = f[n][8:end]; continue
			elseif (startswith(f[n], "SRS"))      srs = f[n][5:end];  continue
			elseif (startswith(f[n], "CRS"))      crs = f[n][5:end];  continue
			elseif (startswith(f[n], "BBOX"))     bbox = parse.(Float64, split(f[n][6:end], ',')); continue
			elseif (startswith(f[n], "FORMAT"))         fmt = f[n][8:end];	continue
			elseif (startswith(f[n], "TILESIZE"))       ts  = parse(Int, f[n][10:end]);	continue
			elseif (startswith(f[n], "OVERVIEWCOUNT"))  cnt = parse(Int, f[n][15:end]);	continue
			elseif (startswith(f[n], "MINRESOLUTION"))  res = parse(Float64, f[n][15:end]);	continue
			elseif (startswith(f[n], "TILED"))          til = contains(f[n], "true");	continue
			elseif (startswith(f[n], "TRANSPARENT"))    trans = contains(f[n], "true");	continue
			end
		end
		ind = findfirst("=", sds[k+1])
		title = (ind !== nothing) ? chomp(rstrip(sds[k+1][ind[1]+1:end])) : ""	# It comes with a damn "...\n  "
		if (k == lastguy)			# Last one contains trailing trash with fake "Corner Coordinates: ..."
			ind = findfirst("Corner", title)
			title = title[1:ind[1]-2]
		end
		append!(names, [name])
		append!(layers, [WMSlayer(name, title, srs, crs, (bbox[1],bbox[3],bbox[2],bbox[4]), fmt, ts, cnt, res, til, trans)])
		name, srs, crs, bbox, fmt, ts, cnt, res, til, trans = "", "", "", zeros(4), "", 0, 0, 0., false, false
	end
	WMS(server, onlineRes, ver, req, names, layers)
end

# ---------------------------------------------------------------------------------------------------
function wmsinfo(wms::WMS; layer=0, stronly::Bool=false)
	# This method inquires a specific layer
	layer_n = get_layer_number(wms, layer)
	nt = (region=wms.layer[layer_n].bbox, size=(10,10))
	str, = wms_helper(wms; layer=layer_n, nt...)
	println(str)
	(!stronly) && println(gdalinfo(str))
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    wmsread(wms::WMS; layer=?, kwargs...)

Read the `layer` number provided by the service from which the `wms` type was created.

### Parameters
- `wms`: A WMS type obtained from the `wmsinfo` function.
- `layer`: The layer number or layer name of interest from those provided by the WMS service. That is,
   both of these forms are allowed: `layer=3` or `layer="Invented layer name"`

### `kwargs` is the keywords/values pairs used to set
- `region | limits`: The region limits. Options are:
   - A Tuple or Array with 4 elements defining the `(xmin, xmax, ymin, ymax)` or a string defining the
     limits in all ways that GMT can recognize. 
   - When the layer has the data projected, we can pass a Tuple or Array with 3 elements `(lon0, lat0, width)`,
     where first two set the center of a square in geographical coordinates and the third (`width`) is the
     width of that box in meters.
   - A ``mosaic`` tile name in the form ``X,Y,Z`` or a quadtree. Example: ``region="7829,6374,14"``. See the ``mosaic``
     function manual for more information. This form also sets the default cellsize for that tile. NOTE:
     this is a geographical coordinates only that implicitly sets ``geog=true``. See below on how to change
     the default resolution.
- `cellsize | pixelsize | resolution | res`: Sets the requested cell size in meters [default]. Use a string appended with a 'd'
   (e.g. `resolution="0.001d"`) if the resolution is given in degrees. This way works only when the layer is in geogs.
- `zoom or refine`: When the region is derived from a ``mosaic`` tile name, the default is to get an image with 256 columns
   and _n_ rows where _n_ depends on latitude. So, either the area is large and consequently the resolution is low, or
   the inverse (small area and resolution is high). To change this status, use the `zoom` or `refine` options.
   - `zoom`: an integer >= 1 that for each increment duplicates the base resolution by 2. _e.g._, `zoom=2`
      quadruplicates the default resolution. This option is almost redundant with the `refine`, but is offered
      for consistency with the ``mosaic`` function.
   - `refine`: an integer >= 2 multiplication factor that is used to increment the resolution by factor. _e.g._, `refine=2`
      duplicates the image resolution.
- `size`: Alternatively to the the `cellsize` use this option, a tuple or array with two elements, to specify
   the image dimensions. Example, `size=(1200, 100)` to get an image with 1200 rows and 100 columns.
- `time`: Some services provide data along time. Use this option to provide a time string as provided by DateTime.
   For example: `time=string(DateTime(2021,10,29))`
- `geog | force_geog | forcegeog`: Force the requested layer to be in geographical coordinates. This is useful when the
   data is in projected coordinates (check that by asking the contents of `wms.layer[layer].srs`) but want to pass a
   `region` in geogs. Warning: there is no guarantee that this always works. 

### Returns
A GMTimage

### Examples

    wms = wmsinfo("http://tiles.maps.eox.at/wms?")
    img = wmsread(wms, layer=3, region=(-10,-5,37,44), pixelsize=500);

    # Retrieve and display a MODIS image
    wms = wmsinfo("https://gibs-c.earthdata.nasa.gov/wms/epsg4326/best/wms.cgi");
    img = wmsread(wms, layer="MODIS_Terra_CorrectedReflectance_TrueColor", region=(9,22,32,43), time="2021-10-29T00:00:00", pixelsize=750);
    imshow(img, proj=:guess)
"""
function wmsread(wms::WMS; layer=0, time::String="", kw...)::GMTimage
	layer_n = get_layer_number(wms, layer)
	str, dim_x, dim_y = wms_helper(wms; layer=layer_n, time=time, kw...)
	opts = ["-outsize", "$(dim_x)", "$(dim_y)"]
	((Vd = find_in_kwargs(kw, [:Vd])[1]) !== nothing) && (println(str, "\n", opts); (Vd == 2) && return nothing) 
	gdaltranslate(str, opts)
end

# ---------------------------------------------------------------------------------------------------
"""
    wmstest(wms::WMS; layer, size::Bool=false, kwargs...)

Test function that generates the GetMap request string or the size of the resulting image
given the requested resolution. It is meant to generate first the command that gets the image/grid
but not running it. Specially usefull to check that the resulting image size is not huge.

### Parameters
- `wms`: A WMS type obtained from the `wmsinfo` function.
- `layer`: The layer number or layer name of interest from those provided by the WMS service. That is,
   both of these forms are allowed: `layer=3` or `layer="Invented layer name"`
- `size`: If `false`, returns the GetMap request string, otherwise the image size given the requested resolution.

### `kwargs` is the keywords/values pairs used to set
- `region | limits`: The region limits. This can be a Tuple or Array with 4 elements defining the `(xmin, xmax, ymin, ymax)`
   or a string defining the limits in all ways that GMT can recognize. When the layer has the data projected, we can
   a Tuple or Array with 3 elements `(lon0, lat0, width)`, where first two set the center of a square in geographical
   coordinates and the third (`width`) is the width of that box in meters.
- `cellsize | pixelsize | resolution | res`: Sets the requested cell size in meters [default]. Use a string appended with a 'd'
   (e.g. `resolution="0.001d"`) if the resolution is given in degrees. This way works only when the layer is in geogs.

### Returns
Either a the GetMap request string (when `size=false`) or the resulting image/grid size `dim_x, dim_y`

## Example
    wmstest(wms, layer=34, region=(-8,39, 100000), pixelsize=100)

	"WMS:http://tiles.maps.eox.at/?SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&LAYERS=s2cloudless-2020_3857&SRS=EPSG:900913&BBOX=-940555.9,4671671.6,-840555.9,4771671.68&FORMAT=image/jpeg&TILESIZE=256&OVERVIEWCOUNT=18&MINRESOLUTION=0.59716428347794&TILED=true"
"""
function wmstest(wms::WMS; layer=0, size::Bool=false, kw...)
	layer_n = get_layer_number(wms, layer)
	str, dim_x, dim_y = wms_helper(wms; layer=layer_n, kw...)
	return (size) ? (dim_y, dim_x) : str
end

# ---------------------------------------------------------------------------------------------------
function get_layer_number(wms::WMS, layer::Union{Int, AbstractString})::Int
	# Return the layer number in case 'layer' is a string
	if (isa(layer, AbstractString))
		layer_n = findfirst(wms.layernames .== layer)
		(layer_n === nothing) && error("Layer name not found in this WMS service")
	else
		layer_n = layer
	end
	(layer_n <= 0) && error("Must set the layer number or layer name that you want information about.")
	(layer_n > length(wms.layer)) && error("The requested layer is greater then the number of layers in this dataset.")
	layer_n
end

# ---------------------------------------------------------------------------------------------------
function wms_helper(wms::WMS; layer=0, kw...)
	# Helper function that creates the Getmap string and also optionaly computes the image size from resolution.
	layer_n = get_layer_number(wms, layer)
	d = KW(kw)
	((reg = find_in_dict(d, [:R :region :limits], false)[1]) === nothing) && error("Must provide the `region` option.")

	SRS::String = find_in_dict(d, [:geog :force_geog :forcegeog])[1] !== nothing ? "EPSG:4326" : wms.layer[layer_n].srs

	if (isa(reg, Tuple) || isa(reg, VMr))
		len::Int = length(reg)				# reg is a damn Any
		(len > 4 || len < 3) && error("The region array must have THREE or FOUR elements.")
		if (len == 4)
			lims::Vector{Float64} = Float64.([reg[1], reg[2], reg[3], reg[4]])	# Make a copy to have the same name as in the other branch.
		else
			(contains(SRS, "4326") || contains(wms.layer[layer_n].crs, ":84")) &&
				error("This is a Geographical layer so you cannot set the region with a center and a width.")
			t_srs = epsg2proj(parse(Int, SRS[6:end]))							# Convert to proj4 because lonlat2xy() does not know EPSG
			center::Matrix{Float64} = lonlat2xy([reg[1] reg[2]], t_srs)	# Box center in projected coordinates
			half_w::Float64 = reg[3] / 2
			lims = [center[1]-half_w, center[1]+half_w, center[2]-half_w, center[2]+half_w]
		end
	else
		parse_R(d, "")			# This fills CTRL.limits, which is what we need here
		lims = CTRL.limits[1:4]
	end
	BB = @sprintf("%.12g,%.12g,%.12g,%.12g", lims[1], lims[3], lims[2], lims[4])
	(wms.layer[layer_n].bbox[1] > lims[1] || wms.layer[layer_n].bbox[2] < lims[2] || wms.layer[layer_n].bbox[3] > lims[3] || wms.layer[layer_n].bbox[4] < lims[4]) && @warn("Requested region overflows this layer BoundingBox")

	function loc_getsize(res::Float64, lims::Vector{<:Real})::Tuple{Int, Int}
		_dim_x = round(Int, (lims[2] - lims[1]) / res)		# Assume data has pixel registration
		_dim_y = round(Int, (lims[4] - lims[3]) / res)
		return _dim_x, _dim_y
	end

	if ((dim = find_in_dict(d, [:size])[1]) !== nothing)	# Got the image size directly
		(!isa(dim, Tuple) && !isa(dim, VMr) && length(dim) != 2) &&
			error("The 'size' option must be a Tuple or Array with TWO elements")
		dim_x::Int, dim_y::Int = dim[2], dim[1]
	elseif ((res = find_in_dict(d, [:res :cellsize :pixelsize :resolution])[1]) !== nothing)
		if (isa(res, String) && res[end] == 'd')			# Got resolution in degrees (a string ending with a 'd')
			(!contains(SRS, "4326") && !contains(wms.layer[layer_n].crs, ":84")) &&
				error("This is not a Geographical dataset so you cannot set the resolution in degrees")
			_res::Float64 = parse(Float64, res[1:end-1])
			dim_x, dim_y = loc_getsize(_res, lims)
		else
			if (!contains(SRS, "4326") && !contains(wms.layer[layer_n].crs, ":84"))	# Easy case
				_res = res
			else				# Here BB is in degrees and resolution in meters
				deg_per_m = 360 / (6371000 * 2pi)			# Use spherical authalic radius
				_res = res * deg_per_m
			end
			dim_x, dim_y = loc_getsize(_res, lims)
		end
	elseif (CTRL.limits[2] != "")		# Indirect check if -R was set via a mosaic tile name. A bit FRAGILE
		try _res = tryparse(Float64, CTRL.pocket_R[2])
		catch; error("Programming error. 'CTRL.pocket_R[2]' is empty")
		end
		if ((fact_ = find_in_dict(d, [:refine])[1]) !== nothing)
			((fact = tryparse(Int, fact_)) === nothing) && error("The 'refine' option must be an integer")
			_res /= fact
		elseif ((zoom = find_in_dict(d, [:zoom])[1]) !== nothing)
			@assert (isa(zoom, Int) && zoom > 0) "'zoom' is not an integer > 0"
			_res /= 2 ^ zoom
		end
		dim_x, dim_y = loc_getsize(_res, lims)
		SRS = "EPSG:4326"			# This is a geogs case only
	else
		error("Must provide either the 'size' or the 'resolution' option")
	end

	#WMS:http://tiles.maps.eox.at/?SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&LAYERS=overlay_base_bright&SRS=EPSG:4326&BBOX=-180.000000,-90.000000,180.000000,90.000000&FORMAT=image/png&TILESIZE=256&OVERVIEWCOUNT=17&MINRESOLUTION=0.0000053644180298&TILED=true

	TILED = (wms.layer[layer_n].tiled) ? @sprintf("&TILED=%s", string(wms.layer[layer_n].tiled)) : ""
	TRANS = (wms.layer[layer_n].transparent) ? @sprintf("&TRANSPARENT=%s", string(wms.layer[layer_n].transparent)) : ""
	MINRES= (wms.layer[layer_n].resolution > 0.) ? @sprintf("&MINRESOLUTION=%.14f", wms.layer[layer_n].resolution) : ""
	OVCNT = (wms.layer[layer_n].overviewcount > 0) ? @sprintf("&OVERVIEWCOUNT=%d", wms.layer[layer_n].overviewcount) : ""
	TILSZ = (wms.layer[layer_n].tilesize > 0) ? @sprintf("&TILESIZE=%d", wms.layer[layer_n].tilesize) : ""
	FMT   = (wms.layer[layer_n].imgformat != "") ? @sprintf("&FORMAT=%s", wms.layer[layer_n].imgformat) : "&FORMAT=image/png"
	TIME::String  = ((val = find_in_dict(d, [:time])[1]) !== nothing && isa(val,String)) ? "&time=" * val * "Z" : ""
	
	str = @sprintf("WMS:%sSERVICE=WMS&VERSION=%s&REQUEST=GetMap&LAYERS=%s&SRS=%s&BBOX=%s%s%s%s%s%s%s%s", wms.OnlineResource, wms.version, wms.layer[layer_n].name, SRS, BB, FMT, TILSZ, OVCNT, MINRES, TILED, TRANS, TIME)

	return str, dim_x, dim_y
end

# ---------------------------------------------------------------------------------------------------
function Base.:show(io::IO, W::WMS)
	println("serverURL:\t", W.serverURL);   println("OnlineResource:\t", W.OnlineResource)
	println("version:\t", W.version);       println("request:\t", W.request);
	println("layernames:\t", W.layernames)
	println("\nlayer:\t", length(W.layer), " Layers. Use layer[k] to see the contents of layer k")
end
function Base.:show(io::IO, W::WMSlayer)
	println("name:\t", W.name);		println("title:\t", W.title);		println("srs:\t", W.srs);
	println("crs:\t", W.crs);		println("bbox:\t", W.bbox)
	println("imgformat:\t", W.imgformat);          println("tilesize:\t", W.tilesize)
	println("overviewcount:\t", W.overviewcount);  println("resolution:\t", W.resolution)
	println("tiled:\t", W.tiled); println("transparent:\t", W.transparent)
end