"""
    gdaltranslate(indata, options=String[]; dest="/vsimem/tmp", kwargs...)

Convert raster data between different formats and other operations also provided by the GDAL
'gdal_translate' tool. Namely sub-region extraction and resampling.
The `kwargs` options accept the GMT region (-R), increment (-I), target SRS (-J). Any of the keywords
`outgrid`, `outfile` or `save` = outputname options to make this function save the result in disk
in the file 'outputname'. The file format is picked from the 'outputname' file extension.
When no output file name is provided it returns a GMT object (either a grid or an image, depending
on the input type). To force the return of a GDAL dataset use the option `gdataset=true`.


- `indata`: Input data. It can be a file name, a GMTgrid or GMTimage object or a GDAL dataset
- `options`:   List of options. The accepted options are the ones of the gdal_translate utility.
            This list can be in the form of a vector of strings, or joined in a simgle string.
- `kwargs`: Besides what was mentioned above one can also use `meta=metadata`, where `metadata`
            is a string vector with the form "NAME=...." for each of its elements. This data
            will be recognized by GDAL as Metadata.

### Returns
A GMT grid or Image, or a GDAL dataset (or nothing if file was writen on disk).
"""
function gdaltranslate(indata, opts=String[]; dest="/vsimem/tmp", kwargs...)
	helper_run_GDAL_fun(gdaltranslate, indata, dest, opts, "", kwargs...)
end
# ---------------------------------------------------------------------------------------------------

"""
    gdalwarp(indata, options=String[]; dest="/vsimem/tmp", kwargs...)

Image reprojection and warping function.

### Parameters
- `indata`:  Input data. It can be a file name, a GMTgrid or GMTimage object or a GDAL dataset
- `options`: List of options (potentially including filename and open
   options). The accepted options are the ones of the gdalwarp utility.
- `kwargs`:  Are kwargs that may contain the GMT region (-R), proj (-J), inc (-I) and `save=fname` options

### Returns
A GMT grid or Image, or a GDAL dataset (or nothing if file was writen on disk).
"""
function gdalwarp(indata, opts=String[]; dest="/vsimem/tmp", kwargs...)
	helper_run_GDAL_fun(gdalwarp, indata, dest, opts, "", kwargs...)
end

# ---------------------------------------------------------------------------------------------------
"""
    gdaldem(dataset, method, options=String[]; dest="/vsimem/tmp", colorfile=name|GMTcpt, kw...)

Tools to analyze and visualize DEMs.

### Parameters
* `dataset` The source dataset.
* `method` the processing to apply (one of "hillshade", "slope",
    "aspect", "color-relief", "TRI", "TPI", "Roughness").
* `options` List of options (potentially including filename and open options).
    The accepted options are the ones of the gdaldem utility.

# Keyword Arguments
* `colorfile` color file (mandatory for "color-relief" processing, should be empty otherwise).
* `kw...` keyword=value arguments when `method` is hillshade.

### Returns
A GMT grid or Image, or a GDAL dataset (or nothing if file was writen on disk).
"""
function gdaldem(indata, method::String, opts::Vector{String}=String[]; dest="/vsimem/tmp", kwargs...)
	opts = gdal_opts2vec(opts)		# Guarantied to return a Vector{String}
	if (method == "hillshade")		# So far the only method that accept kwarg options
		d = GMT.KW(kwargs)
		band = ((val = GMT.find_in_dict(d, [:band])[1]) !== nothing) ? string(val) : "1"
		append!(opts, ["-compute_edges", "-b", band])
		if ((val = GMT.find_in_dict(d, [:scale])[1]) === nothing)
			if (isa(indata, GMT.GMTgrid) && (occursin("longlat", indata.proj4) || occursin("latlong", indata.proj4)) ||
											grdinfo(indata, C="n").data[end] == 1)
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
		helper_run_GDAL_fun(gdaldem, indata, dest, opts, method, d...)
	else
		helper_run_GDAL_fun(gdaldem, indata, dest, opts, method, kwargs...)
	end
end

"""
    ogr2ogr(indata, options=String[]; dest="/vsimem/tmp", kwargs...)

### Parameters
* `indata` The source dataset.
* `options` List of options (potentially including filename and open
            options). The accepted options are the ones of the gdalwarp utility.
* `kw` are kwargs that may contain the GMT region (-R), proj (-J), inc (-I) and `save=fname` options

### Returns
A GMT dataset, or a GDAL dataset (or nothing if file was writen on disk).
"""
function gdalvectortranslate(indata, opts=String[]; dest="/vsimem/tmp", kwargs...)
	helper_run_GDAL_fun(gdalvectortranslate, indata, dest, opts, "", kwargs...)
end

# ---------------------------------------------------------------------------------------------------
function helper_run_GDAL_fun(f::Function, indata, dest::String, opts, method::String="", kwargs...)
	# Helper function to run the GDAL function under 'some protection' and returning obj or saving in file

	GMT.ressurectGDAL()				# Another black-hole plug attempt.
	opts = gdal_opts2vec(opts)		# Guarantied to return a Vector{String}
	d, opts, got_GMT_opts = GMT_opts_to_GDAL(opts, kwargs...)
	((val = GMT.find_in_dict(d, [:Vd])[1]) !== nothing) && println(opts)

	# For gdaldem color-relief we need a further arg that is the name of a cpt. So save one on disk
	_cmap = C_NULL
	if (f == gdaldem && ((cmap = GMT.find_in_dict(d, GMT.CPTaliases)[1])) !== nothing)
		_cmap = tempdir() * "/GMTtmp_cpt.cpt"
		if ( (isa(cmap, String) && (lowercase(splitext(cmap)[2][2:end]) == "cpt")) || isa(cmap, GMT.GMTcpt) )
			save_cpt4gdal(cmap, _cmap)	# GDAL pretend to recognise CPTs but it almost doesn't
		else
			_cmap = cmap				# Risky, assume it's something GDAL can read
		end
	end

	dataset, needclose = get_gdaldataset(indata, opts, f == gdalvectortranslate)
	((outname = GMT.add_opt(d, "", "", [:outgrid :outfile :save])) != "") && (dest = outname)
	default_gdopts!(f, dataset, opts, dest)	# Assign some default options in function of the driver and data type
	((val = GMT.find_in_dict(d, [:meta])[1]) !== nothing && isa(val,Vector{String})) &&
		Gdal.GDALSetMetadata(dataset.ptr, val, C_NULL)		# Metadata must be in the form NAME=.....

	CPLPushErrorHandler(@cfunction(CPLQuietErrorHandler, Cvoid, (UInt32, Cint, Cstring)))
	o = (method == "") ? f(dataset, opts; dest=dest, gdataset=true) : f(dataset, method, opts; dest=dest, gdataset=true, colorfile=_cmap)
	(o !== nothing && o.ptr == C_NULL) && @warn("$(f) returned a NULL pointer.")
	if (o !== nothing)
		# If not explicitly stated to return a GDAL datase, return a GMT type
		if (f == ogr2ogr)
			deletedatasource(o, "/vsimem/tmp")		# WTF do I need to do this?
			!(haskey(d, :gdataset) && !d[:gdataset]) && (o = gd2gmt(o))
		else
			n_bands = (got_GMT_opts && !haskey(d, :gdataset) && isa(o, AbstractRasterBand)) ? 1 : nraster(o)
			if (!haskey(d, :gdataset))
				_o = gd2gmt(o, bands=collect(1:n_bands))
				if (ndims(_o) == 3)			# If it's 3D maybe it's a cube. Check the metadata
					meta = Gdal.getmetadata(o)
					if (!isempty(meta) && (val = Gdal.fetchnamevalue(meta, "NETCDF_DIM_z_VALUES")) != "")
						_o.v = parse.(Float64, split(val[2:end-1],','))
						append!(_o.inc, [_o.v[2] - _o.v[1]])
						_o.range = [_o.range[1:6]; _o.v[1]; _o.v[end]]
					end
				end
				o = _o
			end
		end
		haskey(d, :gdataset) && delete!(d, :gdataset)
	end
	(needclose) && GDALClose(dataset.ptr)
	CPLPopErrorHandler();
	(length(d) > 0) && println("Warning: the following options were not consumed in $f => ", keys(d))
	o
end

# Because the GDAL reconnaissance of GMT cpts is very very weak, we must re-write CPTs in a way that it can swallow
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
	((opt_J = GMT.parse_J(d, "", " ")[1]) != "") && append!(opts, ["-a_srs", opt_J[4:end]])
	if ((opt_I = GMT.parse_I(d, "", [:I :inc :increment :spacing], "I")) != "")	# Need the 'I' to not fall into parse_I() exceptions
		t = split(opt_I[4:end], '/')
		(length(t) == 1) ? append!(opts, ["-tr", t[1], t[1]]) : append!(opts, ["-tr", t[1], t[2]])
	end
	return d, opts, (opt_R != "" || length(opt_J) > 1 || opt_I != "")
end

# ---------------------------------------------------------------------------------------------------
function gdal_opts2vec(opts)::Vector{String}
	# Break up a string of options into a vector string as it's needed by GDAL lower level functions
	(opts == "") && return String[]
	(isempty(opts) || (isa(opts, Vector{<:AbstractString}) && length(opts) > 1)) && return opts	# if already a vec
	(eltype(opts) != Char && !(eltype(opts) <: AbstractString)) &&
		error("Options for GDAL must be a string or a vector of one string")
	_opts = (isa(opts, Vector{<:AbstractString})) ? opts[1] : opts

	ind = helper_opts2vec(_opts)
	isempty(ind) && return split(_opts)			# Perfect, just a 'simple' options list, split and go
	_opts = _opts[1:ind[1][1]-1] * replace(_opts[ind[1][1]+1 : ind[2][1]-1], ' ' => '\x7f') * _opts[ind[2][1]+1 : end]

	while (!isempty(helper_opts2vec(_opts)))	# See if we have more
		ind = helper_opts2vec(_opts)
		_opts = _opts[1:ind[1][1]-1] * replace(_opts[ind[1][1]+1 : ind[2][1]-1], ' ' => '\x7f') * _opts[ind[2][1]+1 : end]
	end

	v = split(_opts)
	[v[i] = replace(v[i], '\x7f' => ' ') for i = 1:length(v)]		# Undo the Char(127) char
end

function helper_opts2vec(opts::String)
	ind = findall("\"", opts)
	isempty(ind) && (ind = findall("'", opts))
	(!isempty(ind) && rem(length(ind), 2) != 0) && error("Delimiting characters like $(opts[ind[1][1]]) must come in pairs")
	return ind
end

# ---------------------------------------------------------------------------------------------------
function default_gdopts!(f::Function, ds, opts::Vector{String}, dest::String)
	# Assign some default options in function of the driver and data type

	driver = shortname(getdriver(ds))
	dt = GDALGetRasterDataType(ds.ptr)
	# For some reason when MEM driver (only it?) dt comes == 1, even when data is float. So check again.
	(startswith(lowercase(driver), "mem") && dt == 1 && isa(ds, Gdal.IDataset)) && (dt = GDALGetRasterDataType(getband(ds,1).ptr))
	(dt >= 6 && f == gdalwarp && !any(startswith.(opts, "-dstnodata"))) && append!(opts, ["-dstnodata","NaN"])
	(dt >= 6 && f == gdaltranslate && !any(startswith.(opts, "-a_nodata"))) && append!(opts, ["-a_nodata","NaN"])

	startswith(dest, "/vsimem") && return nothing	# In this case we won't set any more defaults

	ext = lowercase(splitext(dest)[2])
	isTiff = (ext == ".tif" || ext == ".tiff")
	isNC   = (driver == "netCDF" || ext == ".nc"  || ext == ".grd") && (width(ds) > 128 && height(ds) > 128)
	(ext == ".grd") && append!(opts, ["-of", "netCDF"])		# Accept .grd as meaning netcdf and not Surfer ascii (GDAL default)
	((dt == 1 || isTiff) && !any(startswith.(opts, "COMPRESS"))) && append!(opts, ["-co", "COMPRESS=DEFLATE", "-co", "PREDICTOR=2"])
	((dt == 1 || isTiff) && !any(startswith.(opts, "TILED"))) && append!(opts, ["-co", "TILED=YES"])
	(isNC) && append!(opts,["-co", "FORMAT=NC4", "-co", "COMPRESS=DEFLATE", "-co", "ZLEVEL=4"]) 
end

# ---------------------------------------------------------------------------------------------------
function get_gdaldataset(data, opts, isVec::Bool=false)
	# Get a GDAL dataset from either a file name, a GMT grid or image, or a dataset itself
	# In case of a file name we must be careful and deal with possible "+b" band requests from GMT.
	# isVec tells us if the fiename 'data' is to be opened as a Vector or a Raster.
	needclose = false
	if isa(data, AbstractString)			# Check also for remote files (those that start with a @). MAY SCREW VIOLENTLY
		(data == "") && error("File name is empty.")
		name, ext = splitext(data)			# Be carefull, the name may carry a bands request. e.g. "LC08__cube.tiff+b3,2,1"
		name = ((ind = findfirst("+", ext)) === nothing) ? data : name * ext[1:ind[1]-1]
		if (ind !== nothing && ext[ind[1]+1] == 'b')	# So we must convert the "+b3,2,1" into GDAL syntax
			o = split(ext[ind[1]+2:end], ",")			# But we must add 1 because GDAL band count is 1-based and GMT 0-based
			p = parse.(Int, o) .+ 1
			o = [string(c) for c in p]
			if (isa(opts, Vector{String}))
				for k = 1:length(o)  append!(opts, ["-b", o[k]])  end
			else
				opts *= " -b" * join(o, " -b ")
			end
		end
		flags = isVec ? GDAL_OF_VECTOR | GDAL_OF_VERBOSE_ERROR : GDAL_OF_READONLY | GDAL_OF_VERBOSE_ERROR
		ds = (name[1] == '@') ? Gdal.unsafe_read(gmtwhich(name).text[1]) : Gdal.unsafe_read(name, flags=flags)
		needclose = true					# For some reason file remains open and we must close it explicitly
	elseif (isa(data, GMTgrid) || isa(data, GMTimage) || GMT.isGMTdataset(data) || isa(data, Matrix{<:Real}))
		ds = gmt2gd(data)
	elseif (isa(data, AbstractGeometry))	# VERY UNSATISFACTORY. SHOULD BE ABLE TO GETPARENT (POSSIBLE?)
		ds = wrapgeom(data)
	else
		ds = data							# If it's not a GDAL dataset or convenient descendent, shit will follow soon
	end
	(ds === nothing || ds.ptr == C_NULL) && error("Error fetching the GDAL dataset from input $(typeof(data))")
	return ds, needclose
end

# ---------------------------------------------------------------------------------------------------
"""
    dither(indata; n_colors=256, save="", gdataset=false)

Convert a 24bit RGB image to 8bit paletted.
- Use the `save=fname` option to save the result to disk in a GeoTiff file `fname`. If `fname`
  has no extension a `.tif` one will be appended. Alternatively give file names with extension
  `.png` or `.nc` to save the file in one of those formats.
- `gdataset=true`: to return a GDAL dataset. The default is to return a GMTimage object.
- `n_colors`: Select the number of colors in the generated color table. Defaults to 256.
"""
function dither(indata, opts=String[]; n_colors::Integer=256, save::String="", gdataset::Bool=false)
	# ...
	src_ds, needclose = get_gdaldataset(indata, "", false)
	(nraster(src_ds) < 3) && error("Input image must have at least 3 bands")
	(isa(indata, GMTimage) && !startswith(indata.layout, "TRB")) &&
		error("Image memory layout must be `TRB` and not $(indata.layout). Load image with gdaltranslate()")
	r_band, g_band, b_band = getband(src_ds, 1), getband(src_ds, 2), getband(src_ds, 3)

	drv_name = "MEM"
	if (save != "")
		fn, ext = splitext(save)
		ext = lowercase(ext)
		drv_name = (ext == "" || ext == ".tif" || ext == ".tiff") ? "GTiff" : (ext == ".png" ? "PNG" : (ext == ".nc" ? "netCDF" : ""))
		if (drv_name == "")
			@warn("Format not supported. Only TIF, PNG or netCDF are allowed. Resorting to TIF")
			drv_name, save = "GTiff", fn * ".tif"
		end
		(ext == "") && (save *= ".tif")
	end

	(drv_name == "GTiff") && append!(opts, ["TILED=YES", "TILED=YES", "COMPRESS=DEFLATE", "PREDICTOR=2"])
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
	(needclose) && GDALClose(src_ds.ptr)
	if (save != "")						# Because a file was writen
		destroy(dst_ds)
		return nothing
	end
	(gdataset) ? dst_ds : gd2gmt(dst_ds)
end
