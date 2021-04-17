"""
    O = gd2gmt(dataset; band=1, bands=[], sds=0, pad=0)

Convert a GDAL raster dataset into either a GMTgrid (if type is Int16 or Float) or a GMTimage type
Use BAND to select a single band of the dataset. When you know that the dataset contains several
bands of an image, use the kwarg BANDS with a vector the wished bands (1, 3 or 4 bands only).

When DATASET is a string it may contain the file name or the name of a subdataset. In former case
you can use the kwarg SDS to selec the subdataset numerically. Alternatively, provide the full SDS name.
For files with SDS with a scale_factor (e.g. MODIS data), that scale is applyied automaticaly.

    Examples:
       G = gd2gmt("AQUA_MODIS.20210228.L3m.DAY.NSST.sst.4km.NRT.nc", sds=1);
    or
       G = gd2gmt("SUBDATASET_1_NAME=NETCDF:AQUA_MODIS.20210228.L3m.DAY.NSST.sst.4km.NRT.nc:sst");
    or
       G = gd2gmt("NETCDF:AQUA_MODIS.20210228.L3m.DAY.NSST.sst.4km.NRT.nc:sst");
"""
function gd2gmt(_dataset; band::Int=0, bands=Vector{Int}(), sds::Int=0, pad::Int=0, layout::String="")

	if (isa(_dataset, AbstractString))	# A subdataset name or the full string "SUBDATASET_X_NAME=...."
		# For some bloody reason it would print annoying (& false?) warning messages. Have to use brute force
		Gdal.CPLPushErrorHandler(@cfunction(Gdal.CPLQuietErrorHandler, Cvoid, (UInt32, Cint, Cstring)))
		dataset, scale_factor, add_offset, got_fill_val, fill_val = gd2gmt_helper(_dataset, sds)
		Gdal.CPLPopErrorHandler();
	else
		scale_factor, add_offset, got_fill_val, fill_val = Float32(1), Float32(0), false, Float32(0)
		dataset = _dataset
	end
	(!isa(_dataset, String) && _dataset.ptr == C_NULL) && error("NULL dataset sent in")

	n_dsbands = Gdal.nraster(dataset)
	xSize, ySize, nBands = Gdal.width(dataset), Gdal.height(dataset), n_dsbands
	dType = Gdal.pixeltype(getband(dataset, 1))
	is_grid = (sizeof(dType) >= 4 || dType == Int16) ? true : false		# Simple (too simple?) heuristic
	if (is_grid)
		(length(bands) > 1) && error("For grids only one band request is allowed")
		(band == 0) && (band = 1)		# The default 0 was only to lest us know if any other was selected
		(!isempty(bands)) && (band = bands[1])
		in_bands = [band]
		(band > n_dsbands) && error("Selected band is larger then number of bands in this dataset")
	else
		(length(bands) == 2 || length(bands) > 4) && error("For images only 1, 3 or 4 bands are allowed")
		if     (!isempty(bands))                   in_bands = bands
		elseif (band == 0 && 3 <= n_dsbands <= 4)  in_bands = collect(1:n_dsbands)
		else                                       in_bands = (band == 0) ? [1] : [band]
		end
		(maximum(in_bands) > n_dsbands) && error("iOne selected band is larger then number of bands in this dataset")
	end
	ncol, nrow = xSize+2pad, ySize+2pad
	mat = (dataset isa Gdal.AbstractRasterBand) ? zeros(dType, ncol, nrow) : zeros(dType, ncol, nrow, length(in_bands))
	n_colors = 0
	if (isa(dataset, Gdal.AbstractRasterBand))
		Gdal.rasterio!(dataset, mat, in_bands, 0, 0, xSize, ySize, Gdal.GF_Read, 0, 0, C_NULL, pad)
		colormap, n_colors = get_cpt_from_colortable(dataset)
	else
		ds = (isa(dataset, Gdal.RasterDataset)) ? dataset.ds : dataset
		Gdal.rasterio!(ds, mat, in_bands, 0, 0, xSize, ySize, Gdal.GF_Read, 0, 0, 0, C_NULL, pad)
		colormap, n_colors = get_cpt_from_colortable(ds)
	end

	(!isa(mat, Matrix) && size(mat,3) == 1) && (mat = reshape(mat, size(mat,1), size(mat,2)))	# Fck pain
	if (layout != "")		# From GDAL it always come as a TR but not sure about the interleave
		if     (startswith(layout, "BR"))  mat = reverse(mat, dims=1)		# Just flipUD
		elseif (startswith(layout, "TC"))  mat = collect(mat')
		elseif (startswith(layout, "BC"))  mat = reverse(mat', dims=1)
		else   @warn("Unsuported layout ($(layout)) change")
		end
		layout = layout[1:2] * "B"		# Till further knowledge, assume it's always Band interleaved
	end

	# If we found a scale_factor above, apply it
	if (scale_factor != 1)		# So we must do a scale+offset op
		(got_fill_val) && (nodata = (mat .== fill_val))
		if (eltype(mat) <: Integer)
			mat = mat .* scale_factor .+ add_offset		# Also promotes (and pay) the array to float32
		else
			@inbounds @simd for k = 1:length(mat)
				mat[k] = mat[k] * scale_factor + add_offset
			end
		end
		(got_fill_val) && (mat[nodata] .= NaN32)
	end

	try
		global gt = getgeotransform(dataset)
	catch
		global gt = [0.5, 1.0, 0.0, ySize+0.5, 0.0, 1.0]	# Resort to no coords
	end

	x_inc, y_inc = gt[2], abs(gt[6])
	x_min, y_max = gt[1], gt[4]
	(is_grid) && (x_min += x_inc/2;	 y_max -= y_inc/2)	# Maitain the GMT default that grids are gridline reg.
	x_max = x_min + (xSize - 1*is_grid - 2pad) * x_inc
	y_min = y_max - (ySize - 1*is_grid - 2pad) * y_inc
	z_min, z_max = (is_grid) ? extrema_nan(mat) : extrema(mat)
	hdr = [x_min, x_max, y_min, y_max, z_min, z_max, Float64(!is_grid), x_inc, y_inc]
	prj = getproj(dataset)
	(prj != "" && !startswith(prj, "+proj")) && (prj = toPROJ4(importWKT(prj)))
	(prj == "") && (prj = seek_wkt_in_gdalinfo(gdalinfo(dataset)))
	if (is_grid)
		#!isa(mat, Matrix) && (mat = reshape(mat, size(mat,1), size(mat,2)))
		(eltype(mat) == Float64) && (mat = Float32.(mat))
		O = mat2grid(mat; hdr=hdr, proj4=prj)
		O.layout = (layout == "") ? "TRB" : layout
	else
		#(size(mat,3) == 1) && (mat = reshape(mat, size(mat,1), size(mat,2)))
		O = mat2img(mat; hdr=hdr, proj4=prj)
		O.layout = (layout == "") ? "TRBa" : layout * "a"
		if (n_colors > 0)
			O.colormap = colormap;	O.n_colors = n_colors
		end
	end
	if (O.layout[2] == 'R')
		O.x, O.y = O.y, O.x		# Because mat2* thought mat were column-major but it's rwo-major
	end
	O.inc = [x_inc, y_inc]		# Reset because if pad != 0 they were recomputed inside the mat2? funs
	O.pad = pad
	return O
end

# ---------------------------------------------------------------------------------------------------
function gd2gmt_helper(dataset::AbstractString, sds)
	# Deal with daasets as file names. Extract SUBDATASETS is wished.
	scale_factor, add_offset, got_fill_val, fill_val = Float32(1), Float32(0), false, Float32(0)
	if (sds > 0)					# Must fish the SUBDATASET name in in gdalinfo
		# Let's fish the SDS 1 name in: SUBDATASET_1_NAME=NETCDF:"AQUA_MODIS.20210228.L3m.DAY.NSST.sst.4km.NRT.nc":sst
		info = gdalinfo(dataset)
		ind = findall("SUBDATASET_", info)
		nn = 0
		for k = 1:2:length(ind)
			ind2 = findfirst('_', info[ind[1][end]+1 : ind[1][end]+3])	# Allow for up to 999 SDSs
			n = tryparse(Int, info[ind[k][end]+1 : ind[k][end]+ind2[1]-1])
			if (n == sds)			# Ok, found it, but we still need to find the EOL
				ind3 = findfirst('\n', info[ind[k][1]:end])
				dataset = info[ind[k][1] : ind[k][1] + ind3[1]-2]
				nn = n
				break
			end
		end
		(nn == 0) && error("SUBDATASET $(sds) not found in " * dataset)
	end
	sds_name = trim_SUBDATASET_str(dataset)
	((dataset = Gdal.unsafe_read(sds_name)) == C_NULL) && error("GDAL failed to read " * sds_name)

	# Hmmm, check also for scale_factor, add_offset, _FillValue
	info = gdalinfo(dataset)
	(info === nothing) && error("GDAL failed to find " * sds_name)
	if ((ind = findfirst("  Metadata:", info)) !== nothing)
		info = info[ind[1]+12 : end]			# Restrict the size of the string were to look
		if ((ind = findfirst("scale_factor=", info)) !== nothing)	# OK, found one
			ind2 = findfirst('\n', info[ind[1]:end])
			scale_factor = tryparse(Float32, info[ind[1]+13 : ind[1] + ind2[1]-2])
			add_offset = Float32(0)
			if ((ind = findfirst("add_offset=", info)) !== nothing)
				ind2 = findfirst('\n', info[ind[1]:end])
				add_offset = tryparse(Float32, info[ind[1]+11 : ind[1] + ind2[1]-2])
			end
			fill_val, got_fill_val = get_FillValue(info)
		end
	end
	return dataset, scale_factor, add_offset, got_fill_val, fill_val
end

# ---------------------------------------------------------------------------------------------------
function gd2gmt(geom::Gdal.AbstractGeometry, proj::String="")::Vector{GMTdataset}
	# Convert a geometry into a single GMTdataset
	if (Gdal.getgeomtype(geom) == Gdal.wkbPolygon)		# getx() doesn't work for polygons
		geom = Gdal.getgeom(geom,0)
	elseif (Gdal.getgeomtype(geom) == Gdal.wkbMultiPolygon)
		np = Gdal.ngeom(geom)
		D = Vector{GMTdataset}(undef, np)
		[D[k] = gd2gmt(Gdal.getgeom(geom,k-1), proj)[1] for k = 1:np]
		return D
	end

	n_dim, n_pts = Gdal.getcoorddim(geom), Gdal.ngeom(geom)
	n = (n_dim == 2) ? 2 : 3
	mat = Array{Float64,2}(undef, Gdal.ngeom(geom), n)
	[mat[k,1] = Gdal.getx(geom, k-1) for k = 1:n_pts]
	[mat[k,2] = Gdal.gety(geom, k-1) for k = 1:n_pts]
	(n_dim == 3) && ([mat[k,2] = Gdal.getz(geom, k-1) for k = 1:n_pts])
	[GMTdataset(mat, String[], "", String[], proj, "")]
end

# ---------------------------------------------------------------------------------------------------
function gd2gmt(dataset::Gdal.AbstractDataset)
	# This method is for OGR formats only
	(Gdal.OGRGetDriverByName(Gdal.shortname(getdriver(dataset))) == C_NULL) && return gd2gmt(dataset; pad=0)

	D, ds = Vector{GMTdataset}(undef, Gdal.ngeom(dataset)), 1
	for k = 1:Gdal.nlayer(dataset)
		layer = getlayer(dataset, 0)
		Gdal.resetreading!(layer)
		proj = ((p = getproj(layer)) != C_NULL) ? toPROJ4(p) : ""
		while ((feature = Gdal.nextfeature(layer)) !== nothing)
			for j = 0:Gdal.ngeom(feature)-1
				_D = gd2gmt(Gdal.getgeom(feature, j), proj)
				for d in _D
					D[ds] = d
					ds += 1
				end
			end
		end
	end
	return D
end

# ---------------------------------------------------------------------------------------------------
function get_cpt_from_colortable(dataset)
	# Extract the color info from a GDAL colortable and put it in a row vector for GMTimage.colormap
	band = (!isa(dataset, Gdal.AbstractRasterBand)) ? Gdal.getband(dataset) : dataset
	ct = Gdal.getcolortable(band)
	(ct.ptr == C_NULL) && return Vector{Clong}(), 0
	n_colors = Gdal.ncolorentry(ct)
	cmap, n = Vector{Clong}(undef, 4 * n_colors), 1
	for k = 0:n_colors-1
		c = Gdal.getcolorentry(ct, k)
		cmap[n] = c.c1;	n += 1; cmap[n] = c.c2;	n += 1; cmap[n] = c.c3;	n += 1; cmap[n] = c.c4;	n += 1;
	end
	return cmap, n_colors
end

# ---------------------------------------------------------------------------------------------------
function trim_SUBDATASET_str(sds::String)
	# If present, trim the initial "SUBDATASET_X_NAME=" som a subdataset string name
	ind = 0
	(startswith(sds, "SUBDATASET_") && (ind = findfirst('=', sds)) === nothing) && error("Badly formed SUBDATASET string")
	sds_name = sds[ind+1:end]
end

# ---------------------------------------------------------------------------------------------------
function get_FillValue(str::String)
	# Search for a _FillValue in str. Return it if found or NaN otherwise. We use the second return
	# value to tell between a true NaN as _FillValue and one that's only use for type stability
	((ind = findfirst("_FillValue=", str)) === nothing) && return NaN, false
	ind2 = findfirst('\n', str[ind[1]:end])
	fill_val = tryparse(Float32, str[ind[1]+11 : ind[1] + ind2[1]-2])
	return fill_val, true
end

# ---------------------------------------------------------------------------------------------------
function seek_wkt_in_gdalinfo(info::String)
	# Seek for a SRS string in gdalinfo info. Seems that files can have no explicit projinfo but still
	# expose them with gdalinfo.
	((ind = findfirst("SRS=GEO", info)) === nothing) && return ""
	ind2 = findfirst('\n', view(info, ind[5]:length(info)))		# Find next EOL
	proj4 = toPROJ4(importWKT(info[ind[5] : ind[5]+ind2[1]-2]))
end

# ---------------------------------------------------------------------------------------------------
"""
    ds = gmt2gd(GI)

Create GDAL dataset from the contents of GI that can be either a Grid or an Image

    ds = gmt2gd(D, save="", geometry="")

Create GDAL dataset from the contents of D, which can be a GMTdataset, a vector of GMTdataset ir a MxN array.
The SAVE keyword instructs GDAL to save the contents as an OGR file. Format is determined by file estension.
GEOMETRY can be a string with "polygon", where file will be converted to polygon/multipolygon depending
on D is a single or a multi-segment object, or "point" to convert to a multipoint geometry.
"""
function gmt2gd(GI)
	width, height = (GI.layout != "" && GI.layout[2] == 'C') ? (size(GI,2), size(GI,1)) : (size(GI,1), size(GI,2))
	if (isa(GI, GMTgrid))
		ds = creategd("", driver=getdriver("MEM"), width=width, height=height, nbands=1, dtype=eltype(GI.z))
		if (GI.layout != "" && GI.layout[2] == 'C')
			(GI.layout[1] == 'B') ? writegd!(ds, collect(reverse(GI.z, dims=1)'), 1) : writegd!(ds, collect(GI.z'), 1)
		else
			writegd!(ds, GI.z, 1)
		end
	elseif (isa(GI, GMTimage))
		ds = creategd("", driver=getdriver("MEM"), width=width, height=height, nbands=size(GI,3),
		              dtype=eltype(GI.image))
		if (GI.layout != "" && GI.layout[2] == 'C')
			indata = (GI.layout[1] == 'B') ? collect(reverse(GI.image, dims=1)') : collect(GI.image')
		else
			indata = GI.image
		end
		writegd!(ds, indata, isa(GI.image, Array{<:Real, 3}) ? Cint.(collect(1:size(GI,3))) : 1)
	end
	x_min, y_max = GI.range[1], GI.range[4]
	(GI.registration == 0) && (x_min -= GI.inc[1]/2;  y_max += GI.inc[2]/2)
	setgeotransform!(ds, [x_min, GI.inc[1], 0.0, y_max, 0.0, -GI.inc[2]])
	if     (GI.wkt != "")    setproj!(ds, GI.wkt)
	elseif (GI.proj4 != "")  setproj!(ds, toWKT(importPROJ4(GI.proj4), true))
	end
	return ds
end

# ---------------------------------------------------------------------------------------------------
gmt2gd(D::Array{<:Real,2}; save::String="", geometry::String="") = gmt2gd(mat2ds(D); save=save, geometry=geometry)
gmt2gd(D::GMTdataset; save::String="", geometry::String="") = gmt2gd([D]; save=save, geometry=geometry)
function gmt2gd(D::Vector{<:GMTdataset}; save::String="", geometry::String="")
	# ...
	n_cols = size(D[1].data, 2)
	(n_cols < 2) && error("GMTdataset must have at least 2 columns")

	geometry = lowercase(geometry)
	ispolyg  = occursin("poly", geometry);		ismultipolyg = (length(D) > 1)
	isline   = occursin("line", geometry);		ismultiline  = (length(D) > 1)
	ispoint  = occursin("point", geometry);		ismultipoint = (length(D) > 1)
	(geometry != "" && !isline && !ispoint && !ispolyg) && error("Geometry $(geometry) not yet implemented")
	if (!isline && !ispoint && !ispolyg)		# If all multi-segments are closed create a Polygon/MultiPolygon
		ispolyg = true
		for k = 1:length(D)
			(D[k].data[1,1:2] != D[k].data[end,1:2]) && (ispolyg = false; break)
		end
		isline = !ispolyg						# Otherwise make a Line/MultiLine
	end

	ds = creategd(getdriver("MEMORY"));
	#ds = creategd(getdriver("ESRI Shapefile"), filename="/vsimem/mem.shp")
	if     (D[1].proj4 != "")  sr = Gdal.importPROJ4(D[1].proj4)
	elseif (D[1].wkt   != "")  sr = Gdal.importWKT(D[1].wkt)
	else                       sr = Gdal.ISpatialRef(C_NULL)
	end

	if (ispolyg)
		geom_code, geom_cmd = (length(D) == 1) ? (Gdal.wkbPolygon, Gdal.createpolygon()) :
		                                         (Gdal.wkbMultiPolygon, Gdal.createmultipolygon())
	elseif (isline)
		geom_code, geom_cmd = (length(D) == 1) ? (Gdal.wkbLineString, Gdal.createlinestring()) :
		                                         (Gdal.wkbMultiLineString, Gdal.createmultilinestring())
	else
		geom_code, geom_cmd = (length(D) == 1) ? (Gdal.wkbPoint, Gdal.createpoint()) :
		                                         (Gdal.wkbMultiPoint, Gdal.createmultipoint())
	end

	layer = Gdal.createlayer(name="layer1", dataset=ds, geom=geom_code, spatialref=sr);
	feature = Gdal.unsafe_createfeature(layer)
	geom = geom_cmd

	if (ispolyg)
		if (ismultipolyg)
			for k = 1:length(D)
				poly = Gdal.creategeom(Gdal.wkbPolygon)
				Gdal.addgeom!(geom, Gdal.addgeom!(poly, makering(D[k].data)))
			end
		else			# Polygons with islands
			[Gdal.addgeom!(geom, makering(D[k].data)) for k = 1:length(D)]
		end
		Gdal.setgeom!(feature, geom)
	elseif (isline)
		if (ismultiline)
			for k = 1:length(D)
				line = Gdal.creategeom(Gdal.wkbLineString)
				x,y,z = helper_gmt2gd_xyz(D[k], n_cols)
				(n_cols == 2) ? Gdal.OGR_G_SetPoints(line.ptr, size(D[k].data, 1), x, 8, y, 8, C_NULL, 8) :
				                Gdal.OGR_G_SetPoints(line.ptr, size(D[k].data, 1), x, 8, y, 8, z, 8)
        		Gdal.addgeom!(geom, line)
			end
		else
			x,y,z = helper_gmt2gd_xyz(D[1], n_cols)
			(n_cols == 2) ? Gdal.OGR_G_SetPoints(geom.ptr, size(D[1].data, 1), x, 8, y, 8, C_NULL, 8) :
			                Gdal.OGR_G_SetPoints(geom.ptr, size(D[1].data, 1), x, 8, y, 8, z, 8)
		end
		Gdal.setgeom!(feature, geom)
	elseif (ispoint)
		if (ismultipoint)
			for k = 1:length(D)
				x,y,z = helper_gmt2gd_xyz(D[k], n_cols)
				if (n_cols == 2)
					[Gdal.addgeom!(geom, Gdal.createpoint(x[n], y[n])) for n = 1:length(x)]
				else
					[Gdal.addgeom!(geom, Gdal.createpoint(x[n], y[n], z[n])) for n = 1:length(x)]
				end
			end
		else
			x,y,z = helper_gmt2gd_xyz(D[1], n_cols)
			(n_cols == 2) ? Gdal.OGR_G_SetPoints(geom.ptr, size(D[1].data, 1), x, 8, y, 8, C_NULL, 8) :
			                Gdal.OGR_G_SetPoints(geom.ptr, size(D[1].data, 1), x, 8, y, 8, z, 8)
		end
		Gdal.setgeom!(feature, geom)
	end

	Gdal.setfeature!(layer, feature)
	Gdal.destroy(feature)

	if (save != "")
		ogr2ogr(ds, dest=save)
		Gdal.destroy(ds)
		return nothing
	end
	return ds
end

function helper_gmt2gd_xyz(D::GMTdataset, n_cols::Int)
	# Helper funtion to split a matrix in x,y[z] and make sure doubles are returned
	if (eltype(D) == Float64)
		x, y = D.data[:,1], D.data[:,2]
		(n_cols > 2) && (z = D.data[:,3])
	else
		x, y = Float64.(D.data[:,1]), Float64.(D.data[:,2])
		(n_cols > 2) && (z = Float64.(D.data[:,3]))
	end
	return (n_cols == 3) ? (x, y, z) : (x, y, 0.0)
end

	# This is possibly a wasting solution implying a data copy but it's bloody simpler
	#if (conv2polyg)
		#geom.ptr = (length(D) == 1) ? Gdal.OGR_G_ForceToPolygon(geom.ptr) : Gdal.OGR_G_ForceToMultiPolygon(geom.ptr)
	#end

function makering(data)
	ring = Gdal.creategeom(Gdal.wkbLinearRing)
	if (size(data,2) == 2)
		[Gdal.addpoint!(ring, data[k,1], data[k,2]) for k = 1:size(data,1)]
	else
		[Gdal.addpoint!(ring, data[k,1], data[k,2], data[k,3]) for k = 1:size(data,1)]
	end
	ring
end

# ---------------------------------------------------------------------------------------------------
"""
    G = varspacegrid(fname::String, sds_name::String=""; V::Bool=false, kw...)

Read one of those netCDF files that are not regular grids but have instead the coordinates in the
LONGITUDE abd LATITUDE arrays. MODIS L2 files are a good example of this. Data in theses files are
not layed down on a regular grid and we must interpolate to get one. Normally the lon and lat arrays
are called 'longitude' and 'latitude' and these it's what is seek for by default. But files exist
that pretend to comply to CF but use other names. In this case, use the kwargs 'xarray' & 'yarray'
to pass in the variable names. For example: xarray="XLONG", yarray="XLAT"
The other fundamental info to pass in is the name of the array to be read/interpolated. We do that
via the SDS_NAME arg.

In simpler cases the variable to be interpolated lays down on a 2D array but it is also possible that
it is stored in a 3D array. If that is the case, use the keyword 'band' to select a band (ex: 'band=2')
Bands are numbered from 1.

The interpolation is done so far with 'nearneighbor'. Both the region (-R) and increment (-I) are estimated
from data but they can be set with 'region' and 'inc' kwargs as well.
For MODIS data we can select the quality flag to filter by data quality. By default the best quality (=0) is
used, but one can select another with the quality=val kwarg. Positive 'val' values select data of quality
<= quality, whilst negative 'val' values select only data with quality >= abs(val). This allows for example
to extract only the cloud coverage.

If instead of calculating a grid (returned as a GMTgrid type) user wants the x,y,z data intself, use the
keywords 'dataset', or 'outxyz' and the output will be in a GMTdataset (i.e. use 'dataset=true').

To inquire just the list of available arrays use 'list=true' or 'gdalinfo=true' to get the full file info.

    Examples:

    G = MODIS_L2("AQUA_MODIS.20020717T135006.L2.SST.nc", "sst", V=true);

    G = MODIS_L2("TXx-narr-annual-timavg.nc", "T2MAX", xarray="XLONG", yarray="XLAT", V=true);
"""
function varspacegrid(fname::String, sds_name::String=""; quality::Int=0, V::Bool=false, inc=0.0, kw...)

	d = KW(kw)
	(inc >= 1) && error("Silly value $(inc) for the resolution of L2 MODIS grid")
	info = gdalinfo(fname)
	(haskey(d, :gdalinfo)) && (return println(info))
	((ind = findfirst("Subdatasets:", info)) === nothing) && error("This file " * fame * " is not a MODS L2 file")
	is_MODIS = (findfirst("MODISA Level-2", info) !== nothing) ? true : false
	info = info[ind[1]+12:end]		# Chop up the long string into smaller chunk where all needed info lives
	ind = findlast("SUBDATASET_", info)
	info = info[1:ind[1]]			# Chop even last SUBDATASET_X_DESC string that we wouldn't use anyway
	ind_EOLs = findall("\n", info)

	if (haskey(d, :list))
		c = ((ind = findlast("/", info[ind_EOLs[1][1] : ind_EOLs[2][1]-1])) !== nothing) ? '/' : ':'
		println("List of bands in this file:")
		[println("\t",split(info[ind_EOLs[k-1][1] : ind_EOLs[k][1]-1], c)[end]) for k = 2:2:length(ind_EOLs)]
		return nothing
	end

	(sds_name == "") && error("Must provide the band name to process. Try MODIS_L2(\"\", list=true) to print available bands")

	# Get the arrays  SUBDATASET names
	sds_z  = helper_find_sds(sds_name, info, ind_EOLs)		# Return the full SUBDATASET name (a string)
	x_name = ((val = find_in_dict(d, [:xarray])[1]) !== nothing) ? string(val) : "longitude"
	y_name = ((val = find_in_dict(d, [:yarray])[1]) !== nothing) ? string(val) : "latitude"
	sds_qual = (is_MODIS) ? helper_find_sds("qual_" * sds_name, info, ind_EOLs) : ""
	sds_lon = helper_find_sds(x_name, info, ind_EOLs)
	sds_lat = helper_find_sds(y_name, info, ind_EOLs)

	# Get the arrays with the data
	band = ((val = find_in_dict(d, [:band])[1]) !== nothing) ? Int(val) : 1
	lon, lat, z_vals, inc, proj4 = get_xyz_qual(sds_lon, sds_lat, sds_z, quality, sds_qual, inc, band, V)

	if ((opt_R = parse_R(d, "")[1]) == "")		# If != "" believe it makes sense as a -R option
		inc_txt = split("$(inc)", '.')[2]		# To count the number of decimal digits to use in rounding
		ndigits = length(inc_txt)
		min_lon, max_lon = extrema(lon)
		min_lat, max_lat = extrema(lat)
		west, east   = round(min_lon-inc; digits=ndigits), round(max_lon+inc; digits=ndigits)
		south, north = round(min_lat-inc; digits=ndigits), round(max_lat+inc; digits=ndigits)
		opt_R = sprintf("%.10g/%.10g/%.10g/%.10g", west, east, south, north)
	else
		opt_R = opt_R[4:end]		# Because it already came with " -R....." from parse_R()
	end

	if (haskey(d, :outxyz) || haskey(d, :dataset))
		O = mat2ds([lon lat z_vals])
		O[1].proj4 = proj4
	else
		O = nearneighbor([lon lat z_vals], I=inc, R=opt_R, S=2*inc, Vd=(V) ? 1 : 0)
		O.proj4 = proj4
	end
	return O
end

const MODIS_L2 = varspacegrid		# Alias

# ---------------------------------------------------------------------------------------------------
function helper_find_sds(sds::String, info::String, ind_EOLs::Vector{UnitRange{Int64}})::String
	if ((ind = findfirst("/" * sds, info)) === nothing)
		((ind = findfirst(":" * sds, info)) === nothing) && error("The band name -- " * sds * " -- does not exist")
	end
	k = 1;	while (ind_EOLs[k][1] < ind[1])  k += 1  end
	return info[ind_EOLs[k-1][1]+3:ind_EOLs[k][1]-1]	# +3 because 1 = \n and the other 2 are blanks
end

# ---------------------------------------------------------------------------------------------------
function R_inc_to_gd(inc::Vector{Float64}, opt_R::String="", BB::Vector{Float64}=Vector{Float64}())
	# Convert an opt_R string or BB vector + inc vector in the equivalent set of options for GDAL
	if (opt_R != "")
		ind = findfirst("R", opt_R)
		BB = (ind !== nothing) ? tryparse.(Float64, split(opt_R[ind[1]+1:end], '/')) : tryparse.(Float64, split(opt_R, '/'))
	end
	nx = round(Int32, (BB[2] - BB[1]) / inc[1])
	inc_y = (length(inc) == 1) ? inc[1] : inc[2]
	ny = round(Int32, (BB[4] - BB[3]) / inc_y)
	return ["-txe", "$(BB[1])", "$(BB[2])", "-tye", "$(BB[3])", "$(BB[4])", "-outsize", "$(nx)", "$(ny)"]
end

# ---------------------------------------------------------------------------------------------------
function get_xyz_qual(sds_lon::String, sds_lat::String, sds_z::String, quality::Int, sds_qual::String="",
	                  inc::Float64=0., band::Int=1, V::Bool=false)
	# Get a Mx3 matrix with data to feed interpolator. Filter with quality if that's the case
	# If INC != 0, also estimates a reasonable increment for interpolation
	(V) && println("Extract lon, lat, " * sds_z * " from file")
	G = gd2gmt(sds_z; band=band);		z_vals = G.z;		proj4 = G.proj4
	if (sds_qual != "")
		Gqual = gd2gmt(sds_qual)
		if (quality >= 0)  qual = (Gqual.image .< quality + 1)		# Best (0), Best+Intermediate (1) or all (2)
		else               qual = (Gqual.image .> -quality - 1)		# Pick only, Intermediate+Lousy (-1) or Lousy (-2)
		end
		qual = reshape(qual, size(qual,1), size(qual,2))
		z_vals = z_vals[qual]
		lon, lat, dx, dy = get_lon_lat_qual(sds_lon, sds_lat, qual, inc)
		(proj4 == "") && (proj4 = "+proj=longlat +datum=WGS84 +no_defs")	# Almost for sure that's always the case
	else
		info = gdalinfo(trim_SUBDATASET_str(sds_z))
		fill_val, got_fill_val = get_FillValue(info)
		if (got_fill_val)
			qual = (z_vals .!= fill_val)
			z_vals = z_vals[qual]
			lon, lat, dx, dy = get_lon_lat_qual(sds_lon, sds_lat, qual, inc)
		else
			G = gd2gmt(sds_lon);	lon = G.z
			G = gd2gmt(sds_lat);	lat = G.z
			(inc == 0.0) && (dx = diff(lon[:, round(Int, size(lon, 1)/2)]))
			(inc == 0.0) && (dy = diff(lat[round(Int, size(lat, 2)/2), :]))
		end
		(proj4 == "") && (proj4 = seek_wkt_in_gdalinfo(info))
	end
	(inc == 0) && (inc = guess_increment_from_coordvecs(dx, dy))
	(V) && println("Finished extraction ($(length(z_vals)) points), now intepolate")
	return lon, lat, z_vals, inc, proj4
end

function get_lon_lat_qual(sds_lon::String, sds_lat::String, qual, inc)
	# Another helper function to get only the lon, lat values that pass the 'qual' criteria
	dx, dy = Vector{Float32}(), Vector{Float32}()
	G = gd2gmt(sds_lon);
	(inc == 0.0) && (dx = diff(G.z[:, round(Int, size(G.z, 1)/2)]))
	lon = G.z[qual]
	G = gd2gmt(sds_lat);
	(inc == 0.0) && (dy = diff(G.z[round(Int, size(G.z,2)/2), :]))
	lat = G.z[qual]
	return lon, lat, dx, dy
end

# ---------------------------------------------------------------------------------------------------
function guess_increment_from_coordvecs(dx, dy)
	# Guess a good -I<inc> from the spacings in the x (lon), y(lat) arrays
	x_mean = abs(Float64(mean(dx)));		y_mean = abs(Float64(mean(dy)));
	xy_std = max(Float64(std(dx)), Float64(std(dy)))
	inc = round((x_mean + y_mean) / 2; digits=round(Int, abs(log10(xy_std))))
end

# ---------------------------------------------------------------------------------------------------
# This method needs to be here because in imshow.jl by the time it's included Gdal is not yet known
function imshow(arg1::Gdal.AbstractDataset; kw...)
	(Gdal.OGRGetDriverByName(Gdal.shortname(getdriver(arg1))) != C_NULL) && return plot(gd2gmt(arg1), show=1)
	imshow(gd2gmt(arg1), kw...)
end

# ---------------------------------------------------------------------------------------------------
"""
    blendimg!(color::GMTimage, shade::GMTimage; new=false)

Blend the RGB `color` GMTimage with the `shade` intensity image (normally obtained with gdaldem)
The `new` argument determines if we return a new RGB image or update the `color` argument.

The blending method is the one explained in https://gis.stackexchange.com/questions/255537/merging-hillshade-dem-data-into-color-relief-single-geotiff-with-qgis-and-gdal/255574#255574

### Returns
A GMT RGB Image

    blendimg!(img1::GMTimage, img2::GMTimage; new=false, transparency=0.5)

Blend two 2D UInt8 or 2 RGB images using transparency. 
  - **transparency** The default value, 0.5, gives equal weight to both images. 0.75 will make
    `img` weight 3/4 of the total sum, and so forth.
  - **new** If true returns a new GMTimage object, otherwise it cahnges the `img` content.

### Returns
A GMT intensity Image
"""
function blendimg!(color::GMTimage{UInt8, 3}, shade::GMTimage{UInt8, 2}; new=false)

	blend = (new) ? Array{UInt8,3}(undef, size(shade,1), size(shade,2), 3) : color.image

	n_pix = length(shade)
	if (color.layout[3] == 'B')			# Band interleaved
		for n = 1:3
			off = (n - 1) * n_pix
			@inbounds @simd for k = 1:n_pix
				t = shade.image[k] / 255
				blend[k+off] = (t < 0.5) ? round(UInt8, 2t * color.image[k+off]) : round(UInt8, (1 - 2*(1 - t) * (1 - color.image[k+off]/255)) * 255)
			end
		end
	else								# Assume Pixel interleaved
		nk = 1
		@inbounds @simd for k = 1:n_pix
			t = shade.image[k] / 255
			if (t < 0.5)
				blend[nk] = round(UInt8, 2t * color.image[nk]);		nk += 1
				blend[nk] = round(UInt8, 2t * color.image[nk]);		nk += 1
				blend[nk] = round(UInt8, 2t * color.image[nk]);		nk += 1
			else
				blend[nk] = round(UInt8, (1 - 2*(1 - t) * (1 - color.image[nk]/255)) * 255);	nk += 1
				blend[nk] = round(UInt8, (1 - 2*(1 - t) * (1 - color.image[nk]/255)) * 255);	nk += 1
				blend[nk] = round(UInt8, (1 - 2*(1 - t) * (1 - color.image[nk]/255)) * 255);	nk += 1
			end
		end
	end
	return (new) ? mat2img(blend, color) : color
end

function blendimg!(img1::GMTimage, img2::GMTimage; new=false, transparency=0.5)
	# This method blends two UInt8 images with transparency
	@assert eltype(img1) == eltype(img2)
	@assert length(img1) == length(img2)
	same_layout = (img1.layout[1:2] == img2.layout[1:2])
	#if (size(img1,3) == 1)
		#blend = (new) ? Array{UInt8,2}(undef, size(img1,1), size(img1,2)) : img1.image
	#else
		#blend = (new) ? Array{UInt8,3}(undef, size(img1,1), size(img1,2), 3) : img1.image
	#end
	blend = (new) ? Array{eltype(img1), ndims(img1)}(undef, size(img1)) : img1.image
	t, o = transparency, 1. - transparency
	if (same_layout)
		@inbounds @simd for k = 1:length(img1)
			blend[k] = round(UInt8, t * img1.image[k] + o * img2.image[k])
		end
	else
		(size(img1,3) == 1) && error("Sorry, blending RGB images of different mem layouts is not yet implemented")
		flip, transp = img1.layout[1] != img2.layout[1], img1.layout[2] != img2.layout[2]
		if     (flip && !transp)  blend = reverse(img2.image, dims=1)
		elseif (!flip && transp)  blend = collect(img2.image')
		else                      blend = reverse(img2.image', dims=1)
		end
		@inbounds @simd for k = 1:length(img1)
			blend[k] = round(UInt8, t * img1.image[k] + o * blend[k])
		end
		(!new) && (img1.image = blend)
	end
	return (new) ? mat2img(blend, img1) : img1
end

"""
	gdalshade(filename; kwargs...)

Create a shaded relief with the GDAL method (color image blended with shaded intensity).

- kwargs hold the keyword=value to pass the arguments to `gdaldem hillshade`

Example:
    I = gdalshade("hawaii_south.grd", C="faa.cpt", zfactor=4);

### Returns
A GMT RGB Image
"""
function gdalshade(fname; kwargs...)
	d = KW(kwargs)
	band = ((val = find_in_dict(d, [:band], false)[1]) !== nothing) ? string(val) : "1"
	cmap = find_in_dict(d, [:C :color :cmap])[1]	# The color cannot be passed to second call to gdaldem

	A = gdaldem(fname, "color-relief", ["-b", band], C=cmap)
	B = gdaldem(fname, "hillshade"; d...)
	blendimg!(A, B)
end

# ---------------------------------------------------------------------------------------------------
"""
    gammacorrection(I::GMTimage, gamma; contrast=[0.0, 1.0], brightness=[0.0, 1.0])

Apply a gamma correction to a 2D (intensity) GMTimage using the exponent `gamma`.
Optionally set also `contrast` and/or `brightness`

### Returns
A GMT intensity Image
"""
function gammacorrection(I::GMTimage, gamma; contrast=[0.0, 1.0], brightness=[0.0, 1.0])

	@assert 0.0 <= contrast[1] < 1.0;	@assert 0.0 < contrast[2] <= 1.0;	@assert contrast[2] > contrast[1]
	@assert 0.0 <= brightness[1] < 1.0;	@assert 0.0 < brightness[2] <= 1.0;	@assert brightness[2] > brightness[1]
	contrast_min, contrast_max, brightness_min, brightness_max = 0.0, 1.0, 0.0, 1.0
	lut = (eltype(I) == UInt8) ? linspace(0.0, 1, 256) : linspace(0.0, 1, 65536)
	lut = max.(contrast[1], min.(contrast[2], lut))
	lut = ((lut .- contrast[1]) ./ (contrast[2] - contrast[1])) .^ gamma;
	lut = lut .* (brightness[2] - brightness[1]) .+ brightness[1];		# If brightness[1] != 0 || brightness[2] != 1
	lut = (eltype(I) == UInt8) ? round.(UInt8, lut .* 255) : round.(UInt16, lut .* 65536)
	intlut(I, lut)
end

"""
    intlut(I, lut)

Creates an array containing new values of `I` based on the lookup table, `lut`. `I` can be a GMTimage or an uint matrix.
The types of `I` and `lut` must be the same and the number of elements of `lut` is eaqual to intmax of that type.
E.g. if eltype(lut) == UInt8 then it must contain 256 elements.

### Returns
An object of the same type as I
"""
function intlut(I, lut)
	@assert eltype(I) == eltype(lut)
	mat = Array{eltype(I), ndims(I)}(undef, size(I))
	@inbounds for n = 1:length(I)
		mat[n] = lut[I[n]+1]
	end
	return (isa(I, GMTimage)) ? mat2img(mat, I) : mat
end

# ---------------------------------------------------------------------------------------------------
"""
    texture_img(G::GMTgrid; detail=1.0, contrast=2.0, uint16=false)

Compute the Texture Shading calling functions from the software from Leland Brown at
http://www.textureshading.com/Home.html

  - **detail** is the amount of texture detail. Lower values of detail retain more elevation information,
    giving more sense of the overall, large structures and elevation trends in the terrain, at the expense
	of fine texture detail. Higher detail enhances the texture but gives an overall "flatter" general appearance,
	with elevation changes and large structure less apparent.
  - **contrast** is a parameter called “vertical enhancement.” Higher numbers increase contrast in the midtones,
    but may lose detail in the lightest and darkest features. Lower numbers highlight only the sharpest ridges
	and deepest canyons but reduce contrast overall.
  - **uint16** controls if output is a UIn16 or a UInt8 image (the dafault). Note that the original code writes
    only UInt16 images bur if we want to combine this with with the hillshade computed with `gdaldem`, a UInt8
	image is more handy.

### Returns
A UInt8 (or 16) GMT Image
"""
function texture_img(G::GMTgrid; detail=1.0, contrast=2.0, uint16=false)
	texture = deepcopy(G.z)
	terrain_filter(texture, detail, size(G,1), size(G,2), G.inc[1], G.inc[2], 0)
	(startswith(G.proj4, "+proj=merc")) && fix_mercator(texture, detail, size(G,1), size(G,2), G.range[3], G.range[4])
	terrain_image_data(texture, contrast, size(G,1), size(G,2), 0.0, (uint16) ? 65535.0 : 255.0)
	mat = (uint16) ? round.(UInt16, texture) : round.(UInt8, texture)
	Go = mat2img(mat, hdr=grid2pix(G), proj4=G.proj4, wkt=G.wkt, noconv=true, layout=G.layout*"a")
	Go.range[5:6] .= extrema(Go.image)
	Go
end
