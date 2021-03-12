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
# ---------------------------------------------------------------------------------------------------
function gd2gmt(dataset; band=1, bands=Vector{Int}(), sds::Int=0, pad=0)

	if (isa(dataset, AbstractString))	# A subdataset name or the full string "SUBDATASET_X_NAME=...."
		# For some bloody reason it would print annoying (& false?) warning messages. Have to use brute force
		Gdal.CPLPushErrorHandler(@cfunction(Gdal.CPLQuietErrorHandler, Cvoid, (UInt32, Cint, Cstring)))
		dataset, scale_factor, add_offset, got_fill_val, fill_val = gd2gmt_helper(dataset, sds)
		Gdal.CPLPopErrorHandler();
	end

	xSize, ySize, nBands = Gdal.width(dataset), Gdal.height(dataset), Gdal.nraster(dataset)
	dType = Gdal.pixeltype(getband(dataset, 1))
	is_grid = (sizeof(dType) >= 4 || dType == Int16) ? true : false		# Simple (too simple?) heuristic
	if (is_grid)
		(length(bands) > 1) && error("For grids only one band request is allowed")
		(!isempty(bands)) && (band = bands[1])
		in_bands = [band]
	else
		(length(bands) == 2 || length(bands) > 4) && error("For images only 1, 3 or 4 bands are allowed")
		in_bands = (isempty(bands)) ? [band] : bands
	end
	ncol, nrow = xSize+2pad, ySize+2pad
	mat = (dataset isa Gdal.AbstractRasterBand) ? zeros(dType, ncol, nrow) : zeros(dType, ncol, nrow, length(in_bands)) 
	if (isa(dataset, Gdal.AbstractRasterBand))
		Gdal.rasterio!(dataset, mat, in_bands, 0, 0, xSize, ySize, Gdal.GF_Read, 0, 0, C_NULL, pad)
	else
		ds = (isa(dataset, Gdal.RasterDataset)) ? dataset.ds : dataset
		Gdal.rasterio!(ds, mat, in_bands, 0, 0, xSize, ySize, Gdal.GF_Read, 0, 0, 0, C_NULL, pad)
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
		global gt = [0.5, 1.0, 0.0, size(mat,2)+0.5, 0.0, 1.0]	# Resort to no coords
	end

	x_inc, y_inc = gt[2], abs(gt[6])
	x_min, y_max = gt[1], gt[4]
	(is_grid) && (x_min += x_inc/2;	 y_max -= y_inc/2)	# Maitain the GMT default that grids are gridline reg.
	x_max = x_min + (size(mat,1) - 1*is_grid - 2pad) * x_inc
	y_min = y_max - (size(mat,2) - 1*is_grid - 2pad) * y_inc
	z_min, z_max = (is_grid) ? extrema_nan(mat) : extrema(mat)
	hdr = [x_min, x_max, y_min, y_max, z_min, z_max, Float64(!is_grid), x_inc, y_inc]
	prj = getproj(dataset)
	(prj != "" && !startswith(prj, "+proj")) && (prj = toPROJ4(importWKT(prj)))
	if (is_grid)
		!isa(mat, Matrix) && (mat = reshape(mat, size(mat,1), size(mat,2)))
		(eltype(mat) == Float64) && (mat = Float32.(mat))
		O = mat2grid(mat; hdr=hdr, proj4=prj)
		O.layout = "TRB"
	else
		O = mat2img(mat; hdr=hdr, proj4=prj)
		O.layout = "TRBa"
	end
	O.x, O.y = O.y, O.x			# Because mat2* thought mat were column-major but it's rwo-major
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
	ind = 0
	if (startswith(dataset, "SUBDATASET_"))
		((ind = findfirst('=', dataset)) === nothing) && error("Badly formed SUBDATASET string")
	end
	sds_name = dataset[ind+1:end]
	((dataset = Gdal.unsafe_read(sds_name)) == C_NULL) && error("GDAL failed to read " * sds_name)

	# Hmmm, check also for scale_factor, add_offset, _FillValue
	info = gdalinfo(dataset)
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
			if ((ind = findfirst("_FillValue=", info)) !== nothing)
				ind2 = findfirst('\n', info[ind[1]:end])
				fill_val = tryparse(Float32, info[ind[1]+11 : ind[1] + ind2[1]-2])
				got_fill_val = true
			end
		end
	end
	return dataset, scale_factor, add_offset, got_fill_val, fill_val
end
"""
ds = gmt2gd(GI)

	Create GDAL dataset from the contents of GI that can be either a Grid or an Image
"""
# ---------------------------------------------------------------------------------------------------
function gmt2gd(GI)

	if (isa(GI, GMTgrid))
		ds = creategd("", driver = getdriver("MEM"), width=size(GI,2), height=size(GI,1), nbands=1, dtype=eltype(GI.z))
		writegd!(ds, GI.z, 1)
	elseif (isa(GI, GMTimage))
		ds = creategd("", driver = getdriver("MEM"), width=size(GI,2), height=size(GI,1), nbands=size(GI,3),
		              dtype=eltype(GI.image))
		writegd!(ds, GI.image, Cint.(collect(1:size(GI,3))))
	end
	x_min, y_max = GI.range[1], GI.range[4]
	(GI.registration == 0) && (x_min -= GI.inc[1]/2;  y_max += GI.inc[2]/2)
	setgeotransform!(ds, [x_min, GI.inc[1], 0.0, y_max, 0.0, GI.inc[2]])
	if     (GI.wkt != "")    setproj!(ds, GI.wkt)
	elseif (GI.proj4 != "")  setproj!(ds, toWKT(importPROJ4(GI.proj4), true))
	end
	return ds
end

"""
G = MODIS_L2(fname::String, sds_name::String=""; V::Bool=false, inc=0.0, kw...)
"""
# ---------------------------------------------------------------------------------------------------
function MODIS_L2(fname::String, sds_name::String=""; quality::Int=0, V::Bool=false, inc=0.0, kw...)

	d = KW(kw)
	(inc >= 1) && error("Silly value $(inc) for the resolution of L2 MODIS grid")
	info = gdalinfo(fname)
	((ind = findfirst("Subdatasets:", info)) === nothing) && error("This file " * fame * " is not a MODS L2 file")
	info = info[ind[1]+12:end]		# Chop up the long string into smaller chunk where all needed info lives
	ind = findlast("SUBDATASET_", info)
	info = info[1:ind[1]]			# Chop even last SUBDATASET_X_DESC string that we wouldn't use anyway
	ind_EOLs = findall("\n", info)

	if (haskey(d, :list))
		println("List of bands in this file:")
		[println("\t",split(info[ind_EOLs[k-1][1] : ind_EOLs[k][1]-1], '/')[end]) for k = 2:2:length(ind_EOLs)]
		return nothing
	end

	(sds_name == "") && error("Must provide the band name to process. Try MODIS_L2(\"\", list=true) to print available bands")

	# Get the arrays  SUBDATASET names
	sds_bnd = helper_find_sds(sds_name, info, ind_EOLs)
	sds_lon = helper_find_sds("longitude", info, ind_EOLs)
	sds_lat = helper_find_sds("latitude", info, ind_EOLs)
	sds_qual= helper_find_sds("qual_sst", info, ind_EOLs)

	# Get the arrays with the data
	(V) && println("Start extracting lon, lat, " * sds_name * " from L2 file")
	Gqual= gd2gmt(sds_qual)
	if (quality >= 0)
		qual = (Gqual.image .< quality + 1)		# Select Best (0), Best+Intermediate (1) or all (2) quality data
	else
		qual = (Gqual.image .> -quality - 1)	# Select only, Intermediate+Lousy (-1) or Lousy (-2)
	end
	qual = reshape(qual, size(qual,1), size(qual,2))
	G = gd2gmt(sds_bnd)
	bnd_vals = G.z[qual]
	G = gd2gmt(sds_lon)
	lon = G.z[qual]
	G = gd2gmt(sds_lat)
	lat = G.z[qual]
	(V) && println("Finished, now intepolate")
	(inc == 0.0) && (inc = 0.01)	# The default resolution. ~1 km

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

	#R_inc_to_gd([inc], opt_R)
	G = nearneighbor([lon lat bnd_vals], I=0.01, R=opt_R, S=0.05)
end

function helper_find_sds(sds::String, info::String, ind_EOLs::Vector{UnitRange{Int64}})::String
	((ind = findfirst("/" * sds, info)) === nothing) && error("The band name -- " * sds * " -- does not exist")
	k = 1;	while (ind_EOLs[k][1] < ind[1])  k += 1  end
	return info[ind_EOLs[k-1][1]+3:ind_EOLs[k][1]-1]	# +3 because 1 = \n and the other 2 are blanks
end

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
