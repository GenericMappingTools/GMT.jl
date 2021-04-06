"""
    gdaltranslate(indata, opts=String[]; dest="/vsimem/tmp", kwargs...)

Convert raster data between different formats and other operations also provided by the GDAL
'gdal_translate' tool. Namely sub-region extraction and resampling.
The kwargs options accept the GMT region (-R), increment (-I), target SRS (-J) any of the keywords
'outgrid', 'outfile' or 'save' = outputname options to make this function save the result in disk
in the file 'outputname'. The file format is picked from the 'outputname' file extension.
When no output file name is provided it returns a GMT object (either a grid or an image, depending
on the input type). To force the return of a GDAL dataset use the option 'gdataset=true'

  - INDATA - Input data. It can be a file name, a GMTgrid or GMTimage object or a GDAL dataset
  - OPTS   - List of options. The accepted options are the ones of the gdal_translate utility.

### Returns
A GMT grid or Image, or a GDAL dataset (or nothing if file was writen on disk).
"""
function gdaltranslate(indata, opts=String[]; dest="/vsimem/tmp", kwargs...)
	helper_run_GDAL_fun(gdaltranslate, indata, dest, opts, "", kwargs...)
end
# ---------------------------------------------------------------------------------------------------

"""
    gdalwarp(datasets::Vector{Dataset}, options=String[]; dest="/vsimem/tmp", kw...)

Image reprojection and warping function.

### Parameters
* **datasets**: The list of input datasets.
* **options**: List of options (potentially including filename and open
	options). The accepted options are the ones of the gdalwarp utility.
* **kw** are kwargs that may contain the GMT region (-R), proj (-J), inc (-I) and save=fname options

### Returns
A GMT grid or Image, or a GDAL dataset (or nothing if file was writen on disk).
"""
function gdalwarp(indata, opts=String[]; dest="/vsimem/tmp", kwargs...)
	helper_run_GDAL_fun(gdalwarp, indata, dest, opts, "", kwargs...)
end

# ---------------------------------------------------------------------------------------------------
"""
    gdaldem(dataset::Dataset, method::String, options=String[]; dest="/vsimem/tmp", colorfile, kw...)

Tools to analyze and visualize DEMs.

### Parameters
* **dataset**: The source dataset.
* **method**: the processing to apply (one of "hillshade", "slope",
    "aspect", "color-relief", "TRI", "TPI", "Roughness").
* **options**: List of options (potentially including filename and open options).
    The accepted options are the ones of the gdaldem utility.

# Keyword Arguments
* **colorfile**: color file (mandatory for "color-relief" processing, should be empty otherwise).
* **kw...**: keyword=value arguments when `method` is hillshade.

### Returns
A GMT grid or Image, or a GDAL dataset (or nothing if file was writen on disk).
"""
function gdaldem(indata, method::String, opts=String[]; dest="/vsimem/tmp", kwargs...)
	if (method == "hillshade")		# So far the only method that accept kwarg options
		d = GMT.KW(kwargs)
		band = ((val = GMT.find_in_dict(d, [:band])[1]) !== nothing) ? string(val) : "1"
		opts = ["-compute_edges", "-b", band]
		if ((val = GMT.find_in_dict(d, [:scale])[1]) === nothing)
			if (isa(indata, GMT.GMTgrid) && (occursin("longlat", indata.proj4) || occursin("latlong", indata.proj4)) ||
											grdinfo(indata, C="n")[1].data[end] == 1)
				append!(opts, ["-s", "111120"])
			end
		else
			append!(opts, ["-s", string(val)])
		end
		((val = GMT.find_in_dict(d, [:zfactor :zFactor])[1]) !== nothing) && append!(opts, ["-z", string(val)])
		((val = GMT.find_in_dict(d, [:azim :azimuth])[1]) !== nothing) && append!(opts, ["-az", string(val)])
		((val = GMT.find_in_dict(d, [:elev :altitude])[1]) !== nothing) && append!(opts, ["-alt", string(val)])
		((val = GMT.find_in_dict(d, [:combined :combine])[1]) !== nothing) && append!(opts, ["-combined"])
		((val = GMT.find_in_dict(d, [:multi :multidir :multiDirectional])[1]) !== nothing) && append!(opts, ["-multidirectional"])
		((val = GMT.find_in_dict(d, [:igor])[1]) !== nothing) && append!(opts, ["-igor"])
		((val = GMT.find_in_dict(d, [:alg])[1]) !== nothing) && append!(opts, ["-alg", string(val)])
		((val = GMT.find_in_dict(d, [:Horn])[1]) !== nothing) && append!(opts, ["-alg", "Horn"])
		((val = GMT.find_in_dict(d, [:Zeven :Zevenbergen])[1]) !== nothing) && append!(opts, ["-alg", "ZevenbergenThorne"])
		((val = GMT.find_in_dict(d, [:Vd])[1]) !== nothing) && println(opts)
	end
	helper_run_GDAL_fun(gdaldem, indata, dest, opts, method, kwargs...)
end

# ---------------------------------------------------------------------------------------------------
function helper_run_GDAL_fun(f::Function, indata, dest::String, opts::Vector{String}, method::String="", kwargs...)
	# Helper function to run the GDAL function under 'some protection' and returning obj or saving in file

	d, opts, got_GMT_opts = GMT_opts_to_GDAL(opts, kwargs...)

	# For gdaldem color-relief we need a further arg that is the name of a cpt. So save one on disk
	_cmap = C_NULL
	if (f == gdaldem && ((cmap = GMT.find_in_dict(d, [:C :color :cmap])[1])) !== nothing)
		if ((isa(cmap, String) && (lowercase(splitext(cmap)[2][2:end]) == "cpt")) || isa(cmap, GMT.GMTcpt))
			save_cpt4gdal(cmap, tempdir() * "/GMTtmp_cpt.cpt")	# GDAL pretend to recognise CPTs but it almost doesn't
		else
			_cmap = cmap
		end
	end

	dataset = get_gdaldataset(indata)

	CPLPushErrorHandler(@cfunction(CPLQuietErrorHandler, Cvoid, (UInt32, Cint, Cstring)))
	((outname = GMT.add_opt(d, "", "", [:outgrid :outfile :save])) != "") && (dest = outname)
	o = (method == "") ? f(dataset, opts; dest=dest) : f(dataset, method, opts; dest=dest, colorfile=_cmap)
	(o.ptr == C_NULL) && @warn("$(f) returned a NULL pointer.")
	if (o !== nothing)
		# If not explicitly stated to return a GDAL datase, return a GMT type
		n_bands = (got_GMT_opts && !haskey(d, :gdataset) && isa(o, AbstractRasterBand)) ? 1 : nraster(o)
		(!haskey(d, :gdataset)) && (o = gd2gmt(o, bands=collect(1:n_bands)))
	end
	CPLPopErrorHandler();
	o
end

# Because the GDAL reconnaissance  of GMT cpts is very very weak, we must re-write CPTs in a way that it can swallow
save_cpt4gdal(cpt::String, outname::String) = save_cpt4gdal(GMT.gmtread(cpt), outname)
function save_cpt4gdal(cpt::GMT.GMTcpt, outname::String)
	fid = open(outname, "w")
	try
		println(fid, "#COLOR_MODEL = RGB\n#")
		for k = 1:size(cpt.range,1)
			@printf(fid, "%.12g\t%.0f %.0f %.0f\t%.12g\t%.0f %.0f %.0f\n", cpt.range[k,1], cpt.cpt[k,1]*255, cpt.cpt[k,2]*255, cpt.cpt[k,3]*255, cpt.range[k,2], cpt.cpt[k,4]*255, cpt.cpt[k,5]*255, cpt.cpt[k,6]*255)
		end
	catch err
		@warn("Error $(err) saving a GDAL pleasing CPT file $(outname)")
	end
	close(fid)
end

# ---------------------------------------------------------------------------------------------------
function GMT_opts_to_GDAL(opts::Vector{String}, kwargs...)
	# Helper function to process some GMT options and turn them into GDAL syntax
	d = GMT.init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	((opt_R = GMT.parse_R(d, "")[1]) != "") && append!(opts, ["-projwin", split(opt_R[4:end], '/')[[1,4,2,3]]...])	# Ugly
	((opt_J = GMT.parse_J(d, "", " ")[1]) != " ") && append!(opts, ["-a_srs", opt_J[4:end]])
	if ((opt_I = GMT.parse_inc(d, "", [:I :inc], 'I')) != "")	# Need the 'I' to not fall into parse_inc() exceptions
		t = split(opt_I[4:end], '/')
		(length(t) == 1) ? append!(opts, ["-tr", t[1], t[1]]) : append!(opts, ["-tr", t[1], t[2]])
	end
	return d, opts, (opt_R != "" || length(opt_J) > 1 || opt_I != "")
end

#= ---------------------------------------------------------------------------------------------------
function default_gdopts!(ds, opts::Vector{String})
	# Assign some default options in function of the driver and data type
	driver = shortname(getdriver(ds))
	dt = GDALGetRasterDataType(ds.ptr)
	(driver == "MEM" && dt < 6) && return nothing		# We have no defaults so far for integer data in MEM 
	(dt == 1 && !any(startswith.(opts, "COMPRESS"))) && append!(opts, ["COMPRESS=DEFLATE", "PREDICTOR=2"])
	(dt == 1 && !any(startswith.(opts, "TILED"))) && append!(opts, ["TILED=YES"])
	(dt >= 6 && !any(startswith.(opts, "a_nodata"))) && append!(opts, ["-a_nodata","NaN"])
	(driver == "netCDF") && append!(opts,["FORMAT=NC4", "COMPRESS=DEFLATE", "ZLEVEL=4"]) 
end
=#

# ---------------------------------------------------------------------------------------------------
function get_gdaldataset(indata)
	# Get a GDAL dataset from either a file name, a GMT grid or image, or a dataset itself
	if isa(indata, AbstractString)		# Check also for remote files (those that start with a @)
		ds = (indata[1] == '@') ? Gdal.unsafe_read(gmtwhich(indata)[1].text[1]) : Gdal.unsafe_read(indata)
	elseif (isa(indata, GMT.GMTgrid) || isa(indata, GMT.GMTimage))
		ds = gmt2gd(indata)
	else
		ds = indata		# If it's not a GDAL dataset or convenient descendent, shit will follow soon
	end
end

# ---------------------------------------------------------------------------------------------------
"""
    dither(indata; n_colors=256, save="", gdataset=false)

Convert a 24bit RGB image to 8bit paletted.
- Use the 'save=fname' option to save the result to disk in a GeoTiff file "fname". Do not provide
  the extension, a '.tif' one will be appended.
- Use 'gdataset=true' to return a GDAL dataset. The default is to return a GMTimage object.
- Select the number of colors in the generated color table. Defaults to 256.
"""
function dither(indata, opts=String[]; n_colors::Integer=8, save::String="", gdataset::Bool=false)
	# ...
	src_ds = get_gdaldataset(indata)
	(nraster(src_ds) < 3) && error("Input image must have at least 3 bands")
	r_band, g_band, b_band = getband(src_ds, 1), getband(src_ds, 2), getband(src_ds, 3)

	drv_name = (save == "") ? "MEM" : "GTiff"
	(save != "") && (save *= ".tif")
	(drv_name != "MEM") && append!(opts, ["TILED=YES", "TILED=YES", "COMPRESS=DEFLATE", "PREDICTOR=2"])
	dst_ds = create(save, driver=getdriver(drv_name), width=width(src_ds), height=height(src_ds),
	                nbands=1, dtype=UInt8, options=opts)
	try
		setproj!(dst_ds, getproj(src_ds))
		setgeotransform!(dst_ds, getgeotransform(src_ds))
	catch
	end
	dst_band = getband(dst_ds, 1)
	ct = createcolortable(UInt32(1))

	ComputeMedianCutPCT(r_band, g_band, b_band, n_colors, ct)
	setcolortable!(dst_band, ct)
	DitherRGB2PCT(r_band, g_band, b_band, dst_band, ct)
	if (save != "")						# Because a file was writen
		destroy(dst_ds)
		return nothing
	end
	(gdataset) ? dst_ds : gd2gmt(dst_ds)
end
