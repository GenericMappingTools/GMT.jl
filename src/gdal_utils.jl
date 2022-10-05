"""
    O = gd2gmt(dataset; band=0, bands=[], sds=0, pad=0)

Convert a GDAL raster dataset into either a GMTgrid (if type is Int16 or Float) or a GMTimage type
Use `band` to select a single band of the dataset. When you know that the dataset contains several
bands of an image, use the kwarg `bands` with a vector the wished bands. By default it reads all
bands of the image or grid object.

When DATASET is a string it may contain the file name or the name of a subdataset. In former case
you can use the kwarg `sds` to selec the subdataset numerically. Alternatively, provide the full `sds` name.
For files with `sds` with a scale_factor (e.g. MODIS data), that scale is applyied automaticaly.

### Examples:
       G = gd2gmt("AQUA_MODIS.20210228.L3m.DAY.NSST.sst.4km.NRT.nc", sds=1);
    or
       G = gd2gmt("SUBDATASET_1_NAME=NETCDF:AQUA_MODIS.20210228.L3m.DAY.NSST.sst.4km.NRT.nc:sst");
    or
       G = gd2gmt("NETCDF:AQUA_MODIS.20210228.L3m.DAY.NSST.sst.4km.NRT.nc:sst");
"""
function gd2gmt(_dataset; band::Int=0, bands=Vector{Int}(), sds::Int=0, pad::Int=0, layout::String="")

	(isa(_dataset, GMTgrid) || isa(_dataset, GMTimage) || isGMTdataset(_dataset)) && return _dataset

	# For some bloody reason it would print annoying (& false?) warning messages. Have to use brute force
	Gdal.CPLPushErrorHandler(@cfunction(Gdal.CPLQuietErrorHandler, Cvoid, (UInt32, Cint, Cstring)))
	dataset, scale_factor, add_offset, got_fill_val, fill_val = gd2gmt_helper(_dataset, sds)
	Gdal.CPLPopErrorHandler();
	(!isa(_dataset, String) && _dataset.ptr == C_NULL) && error("NULL dataset sent in")

	n_dsbands = Gdal.nraster(dataset)
	xSize, ySize, nBands = Gdal.width(dataset), Gdal.height(dataset), n_dsbands
	dType = Gdal.pixeltype(getband(dataset, 1))
	is_grid = (sizeof(dType) >= 4 || dType == Int16) ? true : false		# Simple (too simple?) heuristic
	in_bands = (!isempty(bands)) ? bands : ((band == 0) ? collect(1:n_dsbands) : [band])
	(maximum(in_bands) > n_dsbands) && error("One selected band is larger then number of bands in this dataset")
	ncol, nrow = xSize+2pad, ySize+2pad
	(scale_factor != 1 || add_offset != 0) && (dType = Float32)
	mat = (dataset isa Gdal.AbstractRasterBand) ? zeros(dType, ncol, nrow) : zeros(dType, ncol, nrow, length(in_bands))
	n_colors = 0
	desc = Vector{String}(undef,0)
	if (isa(dataset, Gdal.AbstractRasterBand))
		Gdal.rasterio!(dataset, mat, in_bands, 0, 0, xSize, ySize, Gdal.GF_Read, 0, 0, C_NULL, pad)
		colormap, n_colors = get_cpt_from_colortable(dataset)
		append!(desc, [Gdal.GDALGetDescription(dataset.ptr)])
	else
		ds = (isa(dataset, Gdal.RasterDataset)) ? dataset.ds : dataset
		Gdal.rasterio!(ds, mat, in_bands, 0, 0, xSize, ySize, Gdal.GF_Read, 0, 0, 0, C_NULL, pad)
		colormap, n_colors = get_cpt_from_colortable(ds)
		for bd in in_bands
			append!(desc, [Gdal.GDALGetDescription(Gdal.GDALGetRasterBand(ds.ptr, bd))])
		end
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
	(scale_factor != 1) && (mat = gd2gmt_helper_scalefac(mat, scale_factor, add_offset, got_fill_val, fill_val))

	local gt
	try
		gt = getgeotransform(dataset)
	catch
		gt = [0.5, 1.0, 0.0, ySize+0.5, 0.0, 1.0]	# Resort to no coords
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
	is_tp = (layout == "")				# if == "" array is rowmajor and hence transposed
	if (is_grid)
		#(eltype(mat) == Float64) && (mat = Float32.(mat))
		O = mat2grid(mat; hdr=hdr, proj4=prj, names=desc, is_transposed=is_tp)
		O.layout = (layout == "") ? "TRB" : layout
	else
		O = mat2img(mat; hdr=hdr, proj4=prj, noconv=true, names=desc, is_transposed=is_tp)
		O.layout = (layout == "") ? "TRBa" : layout * "a"
		if (n_colors > 0)
			O.colormap = colormap;	O.n_colors = n_colors
			((nodata = Gdal.getnodatavalue(Gdal.getband(dataset))) !== nothing) && (O.nodata = nodata)
		end
	end
	O.inc = [x_inc, y_inc]		# Reset because if pad != 0 they were recomputed inside the mat2? funs
	O.pad = pad
	return O
end

# ---------------------------------------------------------------------------------------------------
function gd2gmt_helper_scalefac(mat, scale_factor, add_offset, got_fill_val, fill_val)
	# Apply a scale + offset
	(got_fill_val) && (nodata = isnodata(mat, fill_val))
	if (eltype(mat) <: Integer)
		mat = mat .* scale_factor .+ add_offset		# Also promotes (and pay) the array to float32
	else
		@inbounds Threads.@threads for k = 1:length(mat)  mat[k] = mat[k] * scale_factor + add_offset  end
	end
	(got_fill_val) && (mat[nodata] .= NaN32)
	mat
end

# ---------------------------------------------------------------------------------------------------
function gd2gmt_helper(input, sds)
	# Deal with datasets as file names. Extract SUBDATASETS if wished.
	# But `input` can also be gdal dataset, case in which the `sds` option will probably not work.
	scale_factor, add_offset, got_fill_val, fill_val = Float32(1), Float32(0), false, Float32(0)
	if (sds > 0)					# Must fish the SUBDATASET name in in gdalinfo
		# Let's fish the SDS 1 name in: SUBDATASET_1_NAME=NETCDF:"AQUA_MODIS.20210228.L3m.DAY.NSST.sst.4km.NRT.nc":sst
		info = gdalinfo(input)
		ind = findall("SUBDATASET_", info)
		nn = 0
		for k = 1:2:length(ind)
			ind2 = findfirst('_', info[ind[1][end]+1 : ind[1][end]+3])	# Allow for up to 999 SDSs
			n = tryparse(Int, info[ind[k][end]+1 : ind[k][end]+ind2[1]-1])
			if (n == sds)			# Ok, found it, but we still need to find the EOL
				ind3 = findfirst('\n', info[ind[k][1]:end])
				input = info[ind[k][1] : ind[k][1] + ind3[1]-2]
				nn = n
				break
			end
		end
		(nn == 0) && error("SUBDATASET $(sds) not found in " * input)
	end
	if (isa(input, AbstractString))
		sds_name = trim_SUBDATASET_str(input)
		((dataset = Gdal.unsafe_read(sds_name)) == C_NULL) && error("\tGDAL failed to read " * sds_name * "\n")
	else
		dataset = input
	end

	# Hmmm, check also for scale_factor, add_offset, _FillValue
	info = gdalinfo(dataset)
	(info === nothing) && error("\tGDAL failed to read " * (isa(input, AbstractString) ? sds_name : "input dataset\n"))
	if (occursin("Metadata:", info))
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
function gd2gmt(geom::Gdal.AbstractGeometry, proj::String="")::Union{GMTdataset, Vector{<:GMTdataset}}
	# Convert a geometry into a GMTdataset/Vector{GMTdadaset}
	gmtype = Gdal.getgeomtype(geom)
	if (gmtype == Gdal.wkbPolygon)		# getx() doesn't work for polygons
		geom = Gdal.getgeom(geom,0)
	elseif (gmtype == wkbMultiPolygon || gmtype == wkbMultiLineString || gmtype == Gdal.wkbGeometryCollection)
		n_pts = Gdal.ngeom(geom)
		D = Vector{GMTdataset}(undef, n_pts)
		for k = 1:n_pts  D[k] = gd2gmt(Gdal.getgeom(geom,k-1), "")  end
		(proj != "") && (D[1].proj4 = proj)
		set_dsBB!(D)				# Compute and set the BoundingBox's for this dataset
		return (length(D) == 1) ? D[1] : D
	elseif (gmtype == wkbMultiPoint)
		n_dim, n_pts = Gdal.getcoorddim(geom), Gdal.ngeom(geom)
		mat = Array{Float64,2}(undef, n_pts, n_dim)
		for k = 1:n_pts  mat[k,1] = Gdal.getx(Gdal.getgeom(geom,k-1), 0)  end
		for k = 1:n_pts  mat[k,2] = Gdal.gety(Gdal.getgeom(geom,k-1), 0)  end
		if (n_dim == 3)
			for k = 1:n_pts  mat[k,3] = Gdal.getz(Gdal.getgeom(geom,k-1), 0)  end
		end
		D = [GMTdataset(mat, Float64[], Float64[], Dict{String, String}(), String[], String[], "", String[], proj, "", 0, Int(gmtype))]
		set_dsBB!(D)				# Compute and set the BoundingBox's for this dataset
		return (length(D) == 1) ? D[1] : D
	end

	n_dim, n_pts = Gdal.getcoorddim(geom), Gdal.ngeom(geom)
	n = (n_dim == 2) ? 2 : 3
	mat = Array{Float64,2}(undef, n_pts, n)
	for k = 1:n_pts  mat[k,1] = Gdal.getx(geom, k-1)  end
	for k = 1:n_pts  mat[k,2] = Gdal.gety(geom, k-1)  end
	if (n_dim == 3)
		for k = 1:n_pts  mat[k,3] = Gdal.getz(geom, k-1) end
	end
	D = [GMTdataset(mat, Float64[], Float64[], Dict{String, String}(), String[], String[], "", String[], proj, "", 0, Int(gmtype))]
	set_dsBB!(D)				# Compute and set the BoundingBox's for this dataset
	return (length(D) == 1) ? D[1] : D
end

# ---------------------------------------------------------------------------------------------------
function gd2gmt(dataset::Gdal.AbstractDataset)
	# This method is for OGR formats only
	(Gdal.OGRGetDriverByName(Gdal.shortname(getdriver(dataset))) == C_NULL) && return gd2gmt(dataset; pad=0)

	D, ds = Vector{GMTdataset}(undef, Gdal.ngeom(dataset)), 1
	for k = 1:Gdal.nlayer(dataset)
		layer = getlayer(dataset, k-1)
		Gdal.resetreading!(layer)
		proj = ((p = getproj(layer)) != C_NULL) ? toPROJ4(p) : ""
		while ((feature = Gdal.nextfeature(layer)) !== nothing)
			n = Gdal.nfield(feature)
			attrib = Dict{String, String}()
			[attrib[Gdal.getname(Gdal.getfielddefn(feature, i))] = string(Gdal.getfield(feature, i)) for i = 0:n-1]

			for j = 0:Gdal.ngeom(feature)-1
				geom = Gdal.getgeom(feature, j)
				_D = gd2gmt(geom, proj)
				gt = Gdal.getgeomtype(geom)
				# Maybe when there nlayers > 1 or other cases, starting allocated size is not enough
				len_D = isa(_D, GMTdataset) ? 1 : length(_D)
				(len_D + ds >= length(D)) && append!(D, Vector{GMTdataset}(undef, round(Int, 0.5 * length(D))))
				if isa(_D, GMTdataset)
					D[ds] = _D
					D[ds].geom = gt
					(!isempty(attrib)) && (D[ds].attrib = attrib)
					ds += 1
				else
					for d in _D
						D[ds] = d
						D[ds].geom = gt
						(!isempty(attrib)) && (D[ds].attrib = attrib)
						ds += 1
					end
				end
			end
		end
	end
	(isempty(D)) && (@warn("This dataset has no geometry data. Result is empty."))
	(length(D) != ds-1) && (D = deleteat!(D,ds:length(D)))
	set_dsBB!(D)				# Compute and set the global BoundingBox for this dataset
	return (length(D) == 1) ? D[1] : D
end

# ---------------------------------------------------------------------------------------------------
function get_cpt_from_colortable(dataset)
	# Extract the color info from a GDAL colortable and put it in a row vector for GMTimage.colormap
	band = (!isa(dataset, Gdal.AbstractRasterBand)) ? Gdal.getband(dataset) : dataset
	ct = Gdal.getcolortable(band)
	(ct.ptr == C_NULL) && return Vector{Int32}(), 0
	n_colors = Gdal.ncolorentry(ct)
	cmap, n = Vector{Int32}(undef, 4 * n_colors), 1
	for k = 0:n_colors-1
		c = Gdal.getcolorentry(ct, k)
		cmap[n] = c.c1;	n += 1; cmap[n] = c.c2;	n += 1; cmap[n] = c.c3;	n += 1; cmap[n] = c.c4;	n += 1;
	end
	return cmap, n_colors
end

# ---------------------------------------------------------------------------------------------------
function trim_SUBDATASET_str(sds::String)
	# If present, trim the initial "SUBDATASET_X_NAME=" from a subdataset string name
	ind = 0
	(startswith(sds, "SUBDATASET_") && (ind = findfirst('=', sds)) === nothing) && error("Badly formed SUBDATASET string")
	return sds[ind+1:end]
end

# ---------------------------------------------------------------------------------------------------
function get_FillValue(str::String)
	# Search for a _FillValue in str. Return it if found or NaN otherwise. We use the second return
	# value to tell between a true NaN as _FillValue and one that's only use for type stability
	((ind = findfirst("_FillValue=", str)) === nothing) && return NaN, false
	ind2 = findfirst('\n', str[ind[1]:end])
	fill_val = (ind2 !== nothing) ? tryparse(Float32, str[ind[1]+11 : ind[1] + ind2[1]-2]) : tryparse(Float32, str[ind[1]+11:end])
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
The `save` keyword instructs GDAL to save the contents as an OGR file. Format is determined by file estension.
`geometry` can be a string with "polygon", where file will be converted to polygon/multipolygon depending
on `D` is a single or a multi-segment object, or "point" to convert to a multipoint geometry.
"""
function gmt2gd(GI)
	width, height = (GI.layout != "" && GI.layout[2] == 'C') ? (size(GI,2), size(GI,1)) : (size(GI,1), size(GI,2))
	ds = Gdal.create("", driver=getdriver("MEM"), width=width, height=height, nbands=size(GI,3), dtype=eltype(GI[1]))
	if (isa(GI, GMTgrid))
		if (GI.layout != "" && GI.layout[2] == 'C')
			if (ndims(GI.z) == 2)
				indata = (GI.layout[1] == 'B') ? collect(reverse(GI.z, dims=1)') : collect(GI.z')
			else
				indata = (GI.layout[1] == 'B') ? collect(permutedims(reverse(GI.z, dims=1), (2, 1, 3))) : collect(permutedims(GI.z,(2, 1, 3)))
			end
		else
			indata = GI.z
		end
		Gdal.write!(ds, indata, isa(GI.z, Array{<:Real, 3}) ? Cint.(collect(1:size(GI,3))) : 1)
	elseif (isa(GI, GMTimage))
		if (GI.layout != "" && GI.layout[2] == 'C')
			if (ndims(GI.image) == 2)
				indata = (GI.layout[1] == 'B') ? collect(reverse(GI.image, dims=1)') : collect(GI.image')
			else
				indata = (GI.layout[1] == 'B') ? collect(permutedims(reverse(GI.image, dims=1), (2, 1, 3))) : collect(permutedims(GI.image,(2, 1, 3)))
			end
		else
			indata = GI.image
		end
		Gdal.write!(ds, indata, isa(GI.image, Array{<:Real, 3}) ? Cint.(collect(1:size(GI,3))) : 1)

		if (GI.n_colors > 0)
			ct = Gdal.createcolortable(UInt32(1))	# RGB
			n = 1
			for k = 0:GI.n_colors-1
				c1, c2, c3, c4 = GI.colormap[n],GI.colormap[n+1],GI.colormap[n+2],GI.colormap[n+3]
				#Gdal.createcolorramp!(ct, k, Gdal.GDALColorEntry(c1,c2,c3,c4), k, Gdal.GDALColorEntry(c1,c2,c3,c4))
				Gdal.setcolorentry!(ct, k, Gdal.GDALColorEntry(c1,c2,c3,c4));
				n += 4
			end
			Gdal.setcolortable!(Gdal.getband(ds), ct)
			(!isnan(GI.nodata)) && (Gdal.setnodatavalue!(Gdal.getband(ds), GI.nodata))
		end
	end

	if (!isempty(GI.names))			# Set bands description
		[Gdal.GDALSetDescription(Gdal.GDALGetRasterBand(ds.ptr, k), GI.names[k]) for k = 1:min(size(GI,3), length(GI.names))]
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
	ismulti  = (length(D) > 1) || (D[1].geom == wkbPoint && size(D[1].data, 1) > 1)
	ispolyg  = occursin("poly", geometry);
	isline   = occursin("line", geometry);
	ispoint  = occursin("point", geometry);
	(geometry != "" && !isline && !ispoint && !ispolyg) && error("Geometry $(geometry) not yet implemented")
	if (D[1].geom == 0 && !isline && !ispoint && !ispolyg)	# If all multi-segments are closed create a Polygon/MultiPolygon
		ispolyg = true
		for k = 1:length(D)
			(D[k].data[1,1:2] != D[k].data[end,1:2]) && (ispolyg = false; break)
		end
		isline = !ispolyg						# Otherwise make a Line/MultiLine
	end

	ds = Gdal.create(getdriver("MEMORY"));
	#ds = Gdal.create(getdriver("ESRI Shapefile"), filename="/vsimem/mem.shp")
	if     (D[1].proj4 != "")  sr = Gdal.importPROJ4(D[1].proj4)
	elseif (D[1].wkt   != "")  sr = Gdal.importWKT(D[1].wkt)
	else                       sr = Gdal.ISpatialRef(C_NULL)
	end

	if (ispolyg || D[1].geom == wkbPolygon || D[1].geom == wkbMultiPolygon)	# If guessed or in Dataset
		geom_code, geom_cmd = (!ismulti) ? (wkbPolygon, Gdal.createpolygon()) :
		                                   (wkbMultiPolygon, Gdal.createmultipolygon())
	elseif (isline || D[1].geom == wkbLineString || D[1].geom == wkbMultiLineString)
		geom_code, geom_cmd = (!ismulti) ? (wkbLineString, Gdal.createlinestring()) :
		                                   (wkbMultiLineString, Gdal.createmultilinestring())
	elseif (D[1].geom == wkbMultiPoint || (ispoint && !ismulti))
		geom_code, geom_cmd = wkbMultiPoint, Gdal.createmultipoint()
	else
		geom_code, geom_cmd = (!ismulti) ? (wkbPoint, Gdal.createpoint()) :
		                                   (wkbMultiPoint, Gdal.createmultipoint())
	end

	layer = Gdal.createlayer(name="layer1", dataset=ds, geom=geom_code, spatialref=sr);
	feature = Gdal.unsafe_createfeature(layer)
	geom = geom_cmd

	if (ispolyg || D[1].geom == wkbPolygon || D[1].geom == wkbMultiPolygon)
		if (ismulti)
			for k = 1:length(D)
				poly = Gdal.creategeom(Gdal.wkbPolygon)
				Gdal.addgeom!(geom, Gdal.addgeom!(poly, makering(D[k].data)))
			end
		else			# Polygons with islands
			[Gdal.addgeom!(geom, makering(D[k].data)) for k = 1:length(D)]
		end
		Gdal.setgeom!(feature, geom)
	elseif (isline || D[1].geom == wkbLineString || D[1].geom == wkbMultiLineString)
		if (ismulti)
			for k = 1:length(D)
				line = Gdal.creategeom(wkbLineString)
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
	elseif (ispoint || D[1].geom == wkbPoint || D[1].geom == wkbMultiPoint)
		if (D[1].geom == wkbMultiPoint || ismulti)
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
	else
		@warn("Geometries with geometry code $(D[1].geom) are not yet implemented")
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
	cmap = find_in_dict(d, CPTaliases)[1]	# The color cannot be passed to second call to gdaldem

	A = gdaldem(fname, "color-relief", ["-b", band], C=cmap)
	B = gdaldem(fname, "hillshade"; d...)
	blendimg!(A, B)
end

# ---------------------------------------------------------------------------------------------------
"""
    gdalread(fname::AbstractString, opts=String[]; gdataset=false, kwargs...)

Read a raster or a vector file from a disk file and return the result either as a GMT type (the default)
or a GDAL dataset.

- `fname`: Input data. It can be a file name, a GMTgrid or GMTimage object or a GDAL dataset
- `opts`:  List of options. The accepted options are the ones of the gdal_translate utility.
           This list can be in the form of a vector of strings, or joined in a simgle string.
- `gdataset`: If set to `true` forces the return of a GDAL dataset instead of a GMT type.
- `kwargs`: This options accept the GMT region (-R) and increment (-I)

### Returns
A GMT grid/image or a GDAL dataset
"""
function gdalread(fname::AbstractString, optsP=String[]; opts=String[], gdataset=false, kw...)
	(fname == "") && error("Input file name is missing.")
	(isempty(optsP) && !isempty(opts)) && (optsP = opts)		# Accept either Positional or KW argument
	ressurectGDAL();
	ds_t = Gdal.read(fname, flags=Gdal.GDAL_OF_RASTER, I=false)
	if (ds_t.ptr != C_NULL && Gdal.OGRGetDriverByName(Gdal.shortname(getdriver(ds_t))) == C_NULL)
		ds = gdaltranslate(ds_t, optsP; gdataset=gdataset, kw...)
	else
		(ds_t.ptr == C_NULL) && (ds_t = Gdal.read(fname, flags = Gdal.GDAL_OF_VECTOR | Gdal.GDAL_OF_VERBOSE_ERROR, I=false))
		optsP = (isempty(optsP)) ? ["-overwrite"] : (isa(optsP, String) ? ["-overwrite " * optsP] : append!(optsP, ["-overwrite"]))
		ds = ogr2ogr(ds_t, optsP; gdataset=true, kw...)
		(ds.ptr != C_NULL) && Gdal.deletedatasource(ds, "/vsimem/tmp")		# WTF I need to do this?
	end
	Gdal.GDALClose(ds_t.ptr)			# WTF it needs explicit close?
	return (gdataset) ? ds : gd2gmt(ds)
end

# ---------------------------------------------------------------------------------------------------
const ncType = Dict(
	Int8    => 1,
	UInt8   => 7,
	Int16   => 3,
	UInt16  => 8,
	Int32   => 4,
	UInt32  => 9,
	Int64   => 10,
	UInt64  => 11,
	Float32 => 5,
	Float64 => 6,
	Char    => 2,
	String  => 12)
"""
    gdalwrite(data, fname::AbstractString, opts=String[]; kwargs...)
or

    gdalwrite(fname::AbstractString, data, opts=String[]; kwargs...)

Write a raster or a vector file to disk

- `fname`: Output file name. If not explicitly selected via `opts` the used driver will be picked from the file extension.
- `data`:  The data to be saved in file. It can be a GMT type or a GDAL dataset.
- `opts`:  List of options. The accepted options are the ones of the gdal_translate or ogr2ogr utility.
           This list can be in the form of a vector of strings, or joined in a simgle string.
- `kwargs`: This options accept the GMT region (-R) and increment (-I)

or

    gdalwrite(cube, fname::AbstractString, v=nothing; dim_name::String="time", dim_units::String="")

Write a MxNxP `cube` object to disk as a multilayered file.

- `cube`: A GMTgrid or GMTimage cube
- `fname`: The file name where to save the `cube`
- `v`: A vector with the coordinates of the Z layers (if omitted create one as 1:size(cube,3))
- `dim_name`: The name of the variable of the ``vertical`` dimension.
- `dim_units`: The units of the `v` vector. If not provided, use the `cube.z_units` if exist (GMTgrid only)
"""
gdalwrite(fname::AbstractString, data, optsP=String[]; opts=String[], kw...) = gdalwrite(data, fname, optsP, true; opts=opts, kw...)
function gdalwrite(data, fname::AbstractString, optsP=String[], pickme::Bool=true; opts=String[], kw...)
	(fname == "") && error("Output file name is missing.")
	(isempty(optsP) && !isempty(opts)) && (optsP = opts)		# Accept either Positional or KW argument
	ds, = Gdal.get_gdaldataset(data, optsP)
	if (Gdal.OGRGetDriverByName(Gdal.shortname(getdriver(ds))) == C_NULL)
		gdaltranslate(ds, optsP; dest=fname, kw...)
	else
		ogr2ogr(ds, optsP; dest=fname, kw...)
	end
end

function gdalwrite(cube::GItype, fname::AbstractString, v=nothing; dim_name::String="time", dim_units::String="")
	nbands = size(cube,3)
	(v === nothing && !isempty(cube.v)) && (v = cube.v)
	_v = (v === nothing) ? "$(collect(1:nbands))" : "$(v)"
	ds = gmt2gd(cube)
	Gdal.setmetadataitem(ds, "NETCDF_DIM_EXTRA", dim_name)
	code = (v === nothing) ? 4 : ncType[eltype(v)]		# Pick the v data type.
	Gdal.setmetadataitem(ds, "NETCDF_DIM_" * dim_name * "_DEF", "{$(nbands),$(code)}")
	Gdal.setmetadataitem(ds, "NETCDF_DIM_" * dim_name * "_VALUES", "{" *_v[2:end-1] * "}")
	Gdal.setmetadataitem(ds, dim_name * "#axis", string(dim_name[1]))
	#Gdal.setmetadataitem(ds, "Band1#actual_range","{0,50000}")
	if (dim_units != "")                              Gdal.setmetadataitem(ds, dim_name * "#units", dim_units)
	elseif (isa(cube, GMTgrid) && cube.z_unit != "")  Gdal.setmetadataitem(ds, dim_name * "#units", cube.z_unit)
	end
	crs = Gdal.getproj(cube, wkt=true)
	(crs != "" ) && Gdal.setproj!(ds, crs)
	Gdal.unsafe_copy(ds, filename=fname, driver=getdriver("netCDF"), options=["FORMAT=NC4", "COMPRESS=DEFLATE", "ZLEVEL=4"])
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    lonlat2xy(lonlat::Matrix{<:Real}; t_srs, s_srs="+proj=longlat +datum=WGS84")
or

    lonlat2xy(D::GMTdataset; t_srs, s_srs="+proj=longlat +datum=WGS84")

Computes the forward projection from LatLon to XY in the given projection. The input is assumed to be in WGS84.
If it isn't, pass the appropriate projection info via the `s_srs` option (PROJ4, WKT, EPSG).

### Parameters
* `lonlat`: The input data. It can be a Matrix, or a GMTdataset (or vector of it)
* `t_srs`:  The destiny projection system. This can be a PROJ4, a WKT string or EPSG code

### Returns
A Matrix if input is a Matrix or a GMTdadaset if input had that type
"""
function lonlat2xy(xy::Vector{<:Real}, t_srs_=nothing; t_srs=nothing, s_srs=prj4WGS84)
	vec(lonlat2xy(reshape(xy[:],1,length(xy)), t_srs_; t_srs=t_srs, s_srs=s_srs))
end

function lonlat2xy(xy::Matrix{<:Real}, t_srs_=nothing; t_srs=nothing, s_srs=prj4WGS84)
	(t_srs_ !== nothing) && (t_srs = t_srs_)
	isa(s_srs, Int) && (s_srs = epsg2wkt(s_srs))
	isa(t_srs, Int) && (t_srs = epsg2wkt(t_srs))
	(t_srs === nothing) && error("Must specify at least the target referencing system.")
	D = ogr2ogr(xy, ["-s_srs", s_srs, "-t_srs", t_srs, "-overwrite"])
	return D.data		# Return only the array because that's what was sent in
end

lonlat2xy(D::GMTdataset, t_srs_=nothing; t_srs=nothing, s_srs=prj4WGS84) = lonlat2xy([D], t_srs_; t_srs=t_srs, s_srs=s_srs)
function lonlat2xy(D::Vector{<:GMTdataset}, t_srs_=nothing; t_srs=nothing, s_srs=prj4WGS84)
	(t_srs_ !== nothing) && (t_srs = t_srs_)
	isa(t_srs, Int) && (t_srs = epsg2wkt(t_srs))
	isa(s_srs, Int) && (s_srs = epsg2wkt(s_srs))

	(D[1].proj4 == "" && D[1].wkt == "" && t_srs === nothing) && error("No projection information whatsoever on the input data.")
	if (t_srs != "") _t_srs = t_srs
	else             _t_srs = (D[1].proj4 != "") ? D[1].proj4 : D[1].wkt
	end
	ogr2ogr(D, ["-s_srs", s_srs, "-t_srs", _t_srs, "-overwrite"])
end

# ---------------------------------------------------------------------------------------------------
"""
    xy2lonlat(xy::Matrix{<:Real}, s_srs=""; s_srs="", t_srs="+proj=longlat +datum=WGS84")
or

    xy2lonlat(D::GMTdataset, s_srs=""; s_srs="", t_srs="+proj=longlat +datum=WGS84")

Computes the inverse projection from XY to LonLat in the given projection. The output is assumed to be in WGS84.
If that isn't right, pass the appropriate projection info via the `t_srs` option (PROJ4, WKT, EPSG).

### Parameters
* `xy`: The input data. It can be a Matrix, or a GMTdataset (or vector of it)
* `s_srs`:  The data projection system. This can be a PROJ4, a WKT string or EPSG code
* `t_srs`:  The target SRS. If the default is not satisfactory, provide a new projection info (PROJ4, WKT, EPSG)

### Returns
A Matrix if input is a Matrix or a GMTdadaset if input had that type
"""
function xy2lonlat(xy::Vector{<:Real}, s_srs_=nothing; s_srs=nothing, t_srs=prj4WGS84)
	vec(xy2lonlat(reshape(xy[:],1,length(xy)), s_srs_; s_srs=s_srs, t_srs=t_srs))
end

function xy2lonlat(xy::Matrix{<:Real}, s_srs_=nothing; s_srs=nothing, t_srs=prj4WGS84)
	(s_srs_ !== nothing) && (s_srs = s_srs_)
	isa(s_srs, Int) && (s_srs = epsg2wkt(s_srs))
	isa(t_srs, Int) && (t_srs = epsg2wkt(t_srs))
	(s_srs === nothing) && error("Must specify at least the source referencing system.")
	D = ogr2ogr(xy, ["-s_srs", s_srs, "-t_srs", t_srs, "-overwrite"])
	return D.data		# Return only the array because that's what was sent in
end

xy2lonlat(D::GMTdataset, s_srs_=nothing; s_srs=nothing, t_srs=prj4WGS84) = xy2lonlat([D], s_srs_; s_srs=s_srs, t_srs=t_srs)
function xy2lonlat(D::Vector{<:GMTdataset}, s_srs_=nothing; s_srs=nothing, t_srs=prj4WGS84)
	(s_srs_ !== nothing) && (s_srs = s_srs_)
	isa(s_srs, Int) && (s_srs = epsg2wkt(s_srs))
	isa(t_srs, Int) && (t_srs = epsg2wkt(t_srs))

	(D[1].proj4 == "" && D[1].wkt == "" && s_srs === nothing) && error("No projection information whatsoever on the input data.")
	if (s_srs != "") _s_srs = s_srs
	else             _s_srs = (D[1].proj4 != "") ? D[1].proj4 : D[1].wkt
	end
	ogr2ogr(D, ["-s_srs", _s_srs, "-t_srs", t_srs, "-overwrite"])
end