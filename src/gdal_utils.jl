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
function gd2gmt(_dataset; band=1, bands=Vector{Int}(), sds::Int=0, pad=0)

	if (isa(_dataset, AbstractString))	# A subdataset name or the full string "SUBDATASET_X_NAME=...."
		# For some bloody reason it would print annoying (& false?) warning messages. Have to use brute force
		Gdal.CPLPushErrorHandler(@cfunction(Gdal.CPLQuietErrorHandler, Cvoid, (UInt32, Cint, Cstring)))
		dataset, scale_factor, add_offset, got_fill_val, fill_val = gd2gmt_helper(_dataset, sds)
		Gdal.CPLPopErrorHandler();
	else
		scale_factor, add_offset, got_fill_val, fill_val = Float32(1), Float32(0), false, Float32(0)
		dataset = _dataset
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
	n_colors = 0
	if (isa(dataset, Gdal.AbstractRasterBand))
		Gdal.rasterio!(dataset, mat, in_bands, 0, 0, xSize, ySize, Gdal.GF_Read, 0, 0, C_NULL, pad)
		colormap, n_colors = get_cpt_from_colortable(dataset)
	else
		ds = (isa(dataset, Gdal.RasterDataset)) ? dataset.ds : dataset
		Gdal.rasterio!(ds, mat, in_bands, 0, 0, xSize, ySize, Gdal.GF_Read, 0, 0, 0, C_NULL, pad)
		colormap, n_colors = get_cpt_from_colortable(ds)
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
	(prj == "") && (prj = seek_wkt_in_gdalinfo(gdalinfo(dataset)))
	if (is_grid)
		!isa(mat, Matrix) && (mat = reshape(mat, size(mat,1), size(mat,2)))
		(eltype(mat) == Float64) && (mat = Float32.(mat))
		O = mat2grid(mat; hdr=hdr, proj4=prj)
		O.layout = "TRB"
	else
		O = mat2img(mat; hdr=hdr, proj4=prj)
		O.layout = "TRBa"
		if (n_colors > 0)
			O.colormap = colormap;	O.n_colors = n_colors
		end
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
function get_cpt_from_colortable(dataset)
	# Extract the color info from a GDAL colortable and put it in a row vector for GMTimage.colormap
	if (!isa(dataset, Gdal.AbstractRasterBand))  band = Gdal.getband(dataset)
	else                                         band = dataset
	end
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
	if (startswith(sds, "SUBDATASET_"))
		((ind = findfirst('=', sds)) === nothing) && error("Badly formed SUBDATASET string")
	end
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
# ---------------------------------------------------------------------------------------------------
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
