"""
    rasterzones!(GI::GItype, shapes::Vector{GMTdataset}, fun::Function; touches=false, byfeatures::Bool=false, groupby="")
or

    rasterzones!(fun::Function, GI::GItype, shapes::Vector{GMTdataset}; touches=false, byfeatures::Bool=false, groupby="")

Apply a unidimensional function `fun` to to the elements of the grid or image `GI` that lie inside the polygons
of the GMTdataset `shapes`. The `GI` array is modified in place.

### Arguments
- `GI`: A grid (GMTgrid) or image (GMTimage) type that will be modified by applying `fun` to the elements that
   fall inside the polygons of `shapes`.
- `shapes`: A vector of GMTdataset containing the polygons inside which the elements if `GI` will be assigned
   a single value obtained by applying the function `fun`.
- `fun`: A unidemensional function name used to compute the contant value for the `GI` elements that fall
   inside each of the polygons of `shapes`.

### Parameters
- `touches`: include all cells/pixels that are touched by the polygons. The default is to include only the
  cells whose centers that are inside the polygons.

- `byfeatures`: Datasets read from OGR vector files (shapes, geopackages, arrow, etc) are organized in features
  that may contain several geomeometries each. Each group of geometries in a Feature share the same `Feauture_ID`
  atribute. If `byfeatures` is true, the function `fun` will be applied to each feature independently. This
  option is actually similar to the `groupby` parameter but doesn't require an attribute name. If neither of
  `byfeatures` or `groupby` are provided, the `fun` function is applied to each of the polygons independently.

- `groupby`: If provided, it must be an attribute name, for example, `groupby="NAME"`. If not provided, we use
  the `Feature_ID` attribute that is a unique identifier assigned during an OGR file reading (by the GMT6.5 C lib).
  If neither of `byfeatures` or `groupby` are provided, the `fun` function is applied to each of the polygons
  independently.

See also: `colorzones!`

### Returns
It does't return anything but the input `GI` is modified.

## Example
    Take the Peaks grid and replace the elements that fall inside a triangle at the center by their average.

	G = GMT.peaks();
	D = mat2ds([-1 -1; 0 1; 1 -1; -1 -1]);
	rasterzones!(G, D, mean)

"""
rasterzones!(fun::Function, GI::GItype, shapes::GDtype; isRaster=true, touches=false, byfeatures::Bool=false, groupby="") =
	rasterzones!(GI, shapes, fun; isRaster=isRaster, touches=touches, byfeatures=byfeatures, groupby=groupby)
function rasterzones!(GI::GItype, shapes::GDtype, fun::Function; isRaster=true, touches=false,
                      byfeatures::Bool=false, groupby="")

	function within(bbox_p::Vector{Float64}, bbox_R::Vector{Float64})	# Check if the polygon BB is contained inside the image's region.
		bbox_p[1] >= bbox_R[1] && bbox_p[2] <= bbox_R[2] && bbox_p[3] >= bbox_R[3] && bbox_p[4] <= bbox_R[4]
	end
	function maskit(GI_, mask, band)
		t = (band > 0) ? skipnan(GI_[mask, band]) : skipnan(GI_[mask])
		return (eltype(GI_) <: Integer) ? round(eltype(GI_), fun(t)) : fun(t)
	end
	function mask_GI!(GI, _GI, pix_x, pix_y, mask, n_layers) # Apply the mask to a Grid/Image
		if (n_layers == 1)
			_GI[mask] .= maskit(_GI, mask, 0)
			GI[pix_y[1]:pix_y[2], pix_x[1]:pix_x[2]] = _GI
		else
			for n = 1:n_layers
				_GI[mask, n] .= maskit(_GI, mask, n)
				GI[pix_y[1]:pix_y[2], pix_x[1]:pix_x[2], n] = _GI[:,:,n]
			end
		end
	end

	# GDAL always returns TRB, so if GI has a different one, must convert. Also assume that an empty layout <=> BCB
	layout = startswith(GI.layout, "TR") ? "" : (GI.layout == "" ? "BCB" : GI.layout)
	row_dim, col_dim = (GI.layout == "" || GI.layout[2] == 'C') ? (1,2) : (2,1)	# If RowMajor the array is transposed 
	n_layers = size(GI, 3)

	if (byfeatures || groupby != "")		# Compute the result (stats or raster) on a per feature basis
		vv, names = splitds(shapes, groupby=groupby)
		!isRaster && (mat = zeros(length(vv), n_layers))
		for k = 1:numel(vv)
			Dt = shapes[vv[k]]
			set_dsBB!(Dt, false)	# Compute the BB for all polygons in this feature
			# TODO. Eventualy check if only some polygoms are outside and drop them.
			!within(Dt[1].ds_bbox, GI.range) && continue
			_GI, pix_x, pix_y = GMT.crop(GI, region=Dt[1].ds_bbox)
			((mask = maskgdal(Dt, size(_GI, col_dim), size(_GI, row_dim), touches=touches, layout=layout)) === nothing) && continue

			if (isRaster)  mask_GI!(GI, _GI, pix_x, pix_y, mask, n_layers)
			else           for n = 1:n_layers   mat[k,n] = maskit(_GI, mask, n-1)   end
			end
		end
	else									# Compute the result (stats or raster) on a per polygon basis
		isa(shapes, GMTdataset) && (shapes = [shapes])
		!isRaster && (mat = zeros(length(shapes), n_layers))
		for k = 1:numel(shapes)
			!within(shapes[k].bbox, GI.range) && continue		# Catch any exterior polygon before it errors
			_GI, pix_x, pix_y = GMT.crop(GI, region=shapes[k].bbox)
			_GI === nothing && continue  	# Skip this polygon if it's completely outside the grid or just too small
			((mask = maskgdal(shapes[k], size(_GI, col_dim), size(_GI, row_dim), touches=touches, layout=layout)) === nothing) && continue

			(_GI.layout != "" && _GI.layout[2] == 'C') && (mask = mask')	# mask is always TRB
			if (isRaster)  mask_GI!(GI, _GI, pix_x, pix_y, mask, n_layers)
			else           for n = 1:n_layers   mat[k,n] = maskit(_GI, mask, n-1)   end
			end
		end
		names = String[]					# We need something to return
	end
	return isRaster ? nothing : (mat, names)
end

# ---------------------------------------------------------------------------------------------------
"""
    GI = rasterzones(GI::GItype, shapes::GDtype, fun::Function; touches=false)
or

	GI = rasterzones(fun::Function, GI::GItype, shapes::GDtype; touches=false)

Compute the statistics of `fun` applied to the elements of the grid or image `GI` that lie inside the polygons
of the GMTdataset `shapes`. See the `rasterzones!` documentation for more details. The difference is that
this function returns a new grid/image instead of changing the input.
"""
rasterzones(GI::GItype, shapes::GDtype, fun::Function) = rasterzones!(deepcopy(GI), shapes, fun)
rasterzones(fun::Function, GI::GItype, shapes::GDtype) = rasterzones!(deepcopy(GI), shapes, fun)

# ---------------------------------------------------------------------------------------------------
"""
    zonal_statistics(GI::GItype, shapes::GDtype, fun::Function; touches=false, byfeatures=false, groupby="")
or

    zonal_statistics(fun::Function, GI::GItype, shapes::GDtype; touches=false, byfeatures=false, groupby="")

or `zonal_stats(...)`

Compute the statistics of `fun` applied to the elements of the grid or image `GI` that lie inside the polygons
of the GMTdataset `shapes`. 

### Arguments
- `GI`: A grid (GMTgrid) or image (GMTimage) type uppon which the statistics will be computed by applying the
   `fun` function to the elements that fall inside the polygons of `shapes`.

- `shapes`: A vector of GMTdataset containing the polygons inside which the elements if `GI` will be assigned
   a single value obtained by applying the function `fun`.

- `fun`: A unidemensional function name used to compute the contant value for the `GI` elements that fall
   inside each of the polygons of `shapes`.

### Parameters
- `touches`: include all cells/pixels that are touched by the polygons. The default is to include only the
  cells whose centers that are inside the polygons.

- `byfeatures`: Datasets read from OGR vector filres (shapes, geopackages, arrow, etc) are organized in features
  that may contain several geomeometries each. Each group of geometries in a Feature share the same `Feauture_ID`
  atribute. If `byfeatures` is true, the function `fun` will be applied to each feature independently. This
  option is actually similar to the `groupby` parameter but doesn't require an attribute name. If neither of
  `byfeatures` or `groupby` are provided, the `fun` function is applied to each of the polygons independently.

- `groupby`: If provided, it must be an attribute name, for example, `groupby="NAME"`. If not provided, we use
  the `Feature_ID` attribute that is a unique identifier assigned during an OGR file reading (by the GMT6.5 C lib).
  If neither of `byfeatures` or `groupby` are provided, the `fun` function is applied to each of the polygons independently.

### Examples
  What is the mean altitude of Swisserland?
```julia
G = gmtread("@earth_relief_06m");
Swiss = coast(DCW=:CH, dump=true, minpts=50);
zonal_statistics(G, Swiss, mean)

1×1 GMTdataset{Float64, 2}
 Row │       X
─────┼─────────
   1 │ 1313.21
```
"""
zonal_statistics(fun::Function, GI::GItype, shapes::GDtype; touches=false, byfeatures::Bool=false, groupby="") =
	zonal_statistics(GI, shapes, fun; touches=touches, byfeatures=byfeatures, groupby=groupby)
function zonal_statistics(GI::GItype, shapes::GDtype, fun::Function; touches=false, byfeatures::Bool=false, groupby="")
	mat, names = rasterzones!(GI, shapes, fun; isRaster=false, touches=touches, byfeatures=byfeatures, groupby=groupby)
	mat2ds(mat, names)
end
const zonal_stats  = zonal_statistics			# Alias

# ---------------------------------------------------------------------------------------------------
"""
    colorzones!(shapes::Vector{GMTdataset}[, fun::Function]; img::GMTimage=nothing,
	            url::AbstractString="", layer=0, pixelsize::Int=0, append::Bool=true)

Paint the polygons in the `shapes` with the average color that those polygons ocupy in the `img` image.
When the `shapes` are plotted the resulting image looks like a choropleth map. Alternatively, instead of
transmitting the `img` image one can provide a WMS URL, `layer` number and `pixelsize` to download images from
the Web Map Server service, covering each one the bounding box of each of the `shapes` polygons. This option
is much slower than passing the entire image at once but consumes much less memory. Important when the total area
is large (think Russia size) because even at a moderately resultion it can imply downloading a huge file.

### Parameters
- `shapes`: A vector of GMTdataset containing the polygons to be painted. This container will be changed
   in the sense that the `header` field of each polygon (a GMTdataset) will be appended with the fill
   color (but see also the `append` option that controls how this change takes place.)
- `fun`: By default the average color is obtained by taking the square root of the average of squares of each
   of the three (RGB) bands (or just one for grayscale images). Give the name of another function to replace
   this default. For example `median` will assign the color by computing the median of each component inside
   the polygon area in question.
- `img`: the image from which the stats (`fun`) of each color for each polygon will be computed.
- `url`: In case the `img` option is not used, pass the Web Map Server URL (see the `wmsinfo` and `wmsread` functions)
   from where the images covering the BoundingBox of each polygon will be downloaded. Warning, this is a much slower
   method but potentially useful when the images to download risk to be very big. 
- `layer`: When the `url` option is used this one becomes mandatory and represents the layer number or layer name of
   interest from those provided by the WMS service. That is, both forms are allowed: `layer=3` or
   `layer="Invented layer name"`
- `pixelsize`: Sets the requested cell size in meters [default]. Use a string appended with a 'd'
   (e.g. `resolution="0.001d"`) if the resolution is given in degrees. This way works only when the layer is in geogs.
- `append`: By default, the color assignment  to each of the polygons in the `shapes` vector is achieved by
   appending the fill color to the possibly existing header field. Running the `colorzones` command more than once
   keeps adding (now ignored, because only the first is used) colors. Setting `append=false` forces rewriting
   the header field at each run and hence the assigned color is always the one used (but the previous header is cleared out).

See also: `rasterzones!`

### Returns
It does't return anything but the input `shapes` is modified.

### Example
    Read the 2020 Sentinel2 Earth color for Portugal at 100 m resolution. Load the administrative
	regions and compute their median colors.
	
    wms = wmsinfo("http://tiles.maps.eox.at/wms?");
    img = wmsread(wms, layer=3, region=(-9.6,-6,36.9,42.2), pixelsize=100);
	Pt = gmtread("C:/programs/compa_libs/covid19pt/extra/mapas/concelhos/concelhos.shp");
	colorzones!(Pt, median, img=img);
	imshow(Pt, proj=:guess)
"""
colorzones!(shapes::GDtype; img::GMTimage=nothing, url::AbstractString="", layer=0, pixelsize::Int=0, append::Bool=true) =
	colorzones!(shapes, meansqrt; img=img, url=url, layer=layer, pixelsize=pixelsize, append=append)
function colorzones!(shapes::GDtype, fun::Function; img::GMTimage=nothing, url::AbstractString="", layer=0, pixelsize::Int=0, append::Bool=true)

	(img === nothing && url == "") && error("Must either pass a grid/image or a WMS URL.")
	(img !== nothing && url != "") && error("Make up your mind. Pass ONLY one of grid/image or a WMS URL.")
	(url != "" && (layer == 0 || pixelsize == 0)) && error("When passing a WMS URL must also provide the layer and the pixelsize.")

	function within(k)		# Check if the polygon BB is contained inside the image's region.
		shapes[k].bbox[1] >= img.range[1] && shapes[k].bbox[2] <= img.range[2] && shapes[k].bbox[3] >= img.range[3] && shapes[k].bbox[4] <= img.range[4]
	end

	(url != "") && (wms = wmsinfo(url))
	(url != "") && (layer_n = get_layer_number(wms, layer))
	#layout = ""		# GDAL always returns TRB, so if img has a different one, we must convert (arg in gdalrasterize).
	#(img !== nothing && !startswith(img.layout, "TR")) && (layout = img.layout)
	#row_dim, col_dim = (img.layout == "" || img.layout[2] == 'C') ? (1,2) : (2,1)	# If RowMajor the array is disguised 
	row_dim, col_dim = (1,2)

	isa(shapes, GMTdataset) && (shapes = [shapes])
	for k = 1:numel(shapes)
		!within(k) && continue				# Catch any exterior polygon before it errors
		_img = (url != "") ? wmsread(wms, layer=layer_n, region=shapes[k], pixelsize=pixelsize) : GMT.crop(img, region=shapes[k])[1]
		_img === nothing && continue		# Catch crop shits (for example, polygons too small)

		mk = gdalrasterize(shapes[k],
			["-of", "MEM", "-ts","$(size(_img, col_dim))","$(size(_img, row_dim))", "-burn", "1", "-ot", "Byte"], layout=img.layout)
		mask = reinterpret(Bool, mk.image)
		(!any(mask)) && continue			# If mask is all falses stop before it errors

		opt_G = (ndims(_img) >= 3) ? @sprintf(" -G%.0f/%.0f/%.0f", fun(_img[mask,1]), fun(_img[mask,2]), fun(_img[mask,3])) :
		         (c = fun(_img[mask,1]); @sprintf(" -G%.0f/%.0f/%.0f", c,c,c)) 
		shapes[k].header = (append) ? shapes[k].header * opt_G : opt_G
		(url != "" && rem(k, 10) == 0) && (println("Done ",k, " of ", length(shapes)); print(stdout, "\e[", 1, "A", "\e[1G"))
	end
	return nothing
end

"""
maskgdal(D::GDtype, nx, ny; region=Float64[], touches=false, layout::String="", inverse=false)


"""
function maskgdal(D::GDtype, nx, ny; region=Float64[], touches=false, layout::String="", inverse=false)::Union{Nothing, Matrix{Bool}}
	# Compute the mask matrix
	local mask
	opts = ["-of", "MEM", "-ts","$(nx)","$(ny)", "-burn", "1", "-ot", "Byte"]
	(touches == 1) && append!(opts, ["-at"])
	!isempty(region) && append!(opts, ["-te", sprintf("%.12g", region[1]), sprintf("%.12g", region[3]), sprintf("%.12g", region[2]), sprintf("%.12g", region[4])])
	try
		mk = gdalrasterize(D, opts, layout=layout)	# This may fail if the polygon is degenerated.
		mask = reinterpret(Bool, mk.image)
		(!any(mask)) && return nothing				# If mask is all falses stop before it errors
	catch
		return nothing
	end
	inverse && (mask .= .!mask)
	return reshape(mask, nx, ny)					# Must find why need the reshape
end

function meansqrt(x)
	sum = 0.0
	@inbounds for k = 1:numel(x)
		sum += Float64(x[k]) * x[k]
	end
	sqrt(sum/length(x))
end
