"""
gdaltranslate(indata, opts=String[]; dest="/vsimem/tmp", kwargs...)

	Convert raster data between different formats and other operations also provided by the GDAL
	'gdal_translate' tool. Namely sub-region extraction and resampling.
	The kwargs options accept the GMT region (-R), increment (-I), target SRS (-J) any of the keywords
	'outgrid', 'outfile' or 'save' = outputname options to make this function save the result in disk
	in the file 'outputname'. The file format is picked from the 'outputname' file extension.
	When any of the GMT options is used and no output file name is provided it returns a GMT object
	(either a grid or an image, depending on the input type). To force the return of a GDAL dataset
	use the option 'gdataset=true'

	INDATA - Input data. It can be a file name, a GMTgrid or GMTimage object or a GDAL dataset
	OPTS   - List of options. The accepted options are the ones of the gdal_translate utility.
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
The output dataset.
"""
function gdalwarp(indata, opts=String[]; dest="/vsimem/tmp", kwargs...)
	helper_run_GDAL_fun(gdalwarp, indata, dest, opts, "", kwargs...)
end

# ---------------------------------------------------------------------------------------------------
function gdaldem(indata, method::String, opts=String[]; dest="/vsimem/tmp", kwargs...)
	helper_run_GDAL_fun(gdaldem, indata, dest, opts, method, kwargs...)
end

# ---------------------------------------------------------------------------------------------------
function helper_run_GDAL_fun(f::Function, indata, dest::String, opts::Vector{String}, method::String="", kwargs...)
	# Helper function to run the GDAL function under 'some protection' and returning obj or saving in file

	d, opts, got_GMT_opts = GMT_opts_to_GDAL(opts, kwargs...)

	# For gdaldem color-relief we need a further arg that is the name of a cpt. So save one on disk
	_cmap = C_NULL
	if (f == gdaldem && ((cmap = GMT.find_in_dict(d, [:C :color :cmap])[1])) !== nothing)
		if (!isa(_cmap, String))
			_cmap = tempdir() * "/GMTtmp_cpt"
			GMT.gmtwrite(_cmap, cmap)
		else
			_cmap = cmap
		end
	end

	dataset = get_gdaldataset(indata)

	CPLPushErrorHandler(@cfunction(CPLQuietErrorHandler, Cvoid, (UInt32, Cint, Cstring)))
	((outname = GMT.add_opt(d, "", "", [:outgrid :outfile :save])) != "") && (dest = outname)
	o = (method == "") ? f(dataset, opts; dest=dest) : f(dataset, method, opts; dest=dest, colorfile=_cmap)
	if (o !== nothing)
		# If any GMT opt is used and not explicitly stated to return a GDAL datase, return a GMT type
		n_bands = (got_GMT_opts && !haskey(d, :gdataset) && isa(o, AbstractRasterBand)) ? 1 : nraster(o)
		(got_GMT_opts && !haskey(d, :gdataset)) && (o = gd2gmt(o, bands=collect(1:n_bands)))
	end
	CPLPopErrorHandler();
	o
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

"""
dither(indata; n_colors=256, save="", gdataset=false)

	Convert a 24bit RGB image to 8bit paletted.
	- Use the 'save=fname' option to save the result to disk in a GeoTiff file "fname". Do not provide
	  the extension, a '.tif' one will be appended.
	- Use 'gdataset=true' to return a GDAL dataset. The default is to return a GMTimage object.
	- Select the number of colors in the generated color table. Defaults to 256.
"""
# ---------------------------------------------------------------------------------------------------
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