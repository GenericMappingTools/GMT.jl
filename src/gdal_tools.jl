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
- `options`: List of options. The accepted options are the ones of the gdal_translate utility.
            This list can be in the form of a vector of strings, or joined in a single string.
- `kwargs`: Besides what was mentioned above one can also use `meta=metadata`, where `metadata`
            is a string vector with the form "NAME=...." for each of its elements. This data
            will be recognized by GDAL as Metadata.
            The `kwargs` may also contain the GMT region (-R), proj (-J), inc (-I) and `save=fname` options.

### Returns
A GMT grid or Image, or a GDAL dataset (or nothing if file was writen on disk).
"""
function gdaltranslate(indata, opts=String[]; dest="/vsimem/tmp", kwargs...)
	helper_run_GDAL_fun(gdaltranslate, indata, dest, opts, "", kwargs...)
end
# ---------------------------------------------------------------------------------------------------

"""
    gdalwarp(indata, options=String[]; dest="/vsimem/tmp", kwargs...)

Image/Grid reprojection and warping function.

### Args
- `indata`:  Input data. It can be a file name, a GMTgrid or GMTimage object or a GDAL dataset
- `options`: List of options. The accepted options are the ones of the gdal_translate utility.
            This list can be in the form of a vector of strings, or joined in a single string.
            The accepted options are the ones of the gdalwarp utility.

- `kwargs`: Besides what was mentioned above one can also use `meta=metadata`, where `metadata`
            is a string vector with the form "NAME=...." for each of its elements. This data
            will be recognized by GDAL as Metadata.
            The `kwargs` may also contain the GMT region (-R), proj (-J), inc (-I) and `save=fname` options.

### Returns
A GMT grid or Image, or a GDAL dataset (or nothing if file was writen on disk).
"""
function gdalwarp(indata, opts=String[]; dest="/vsimem/tmp", kwargs...)
	helper_run_GDAL_fun(gdalwarp, indata, dest, opts, "", kwargs...)
end

# ---------------------------------------------------------------------------------------------------
"""
    fillnodata!(data::GItype; nodata=nothing, kwargs...)

Fill selected raster regions by interpolation from the edges.

### Args
- `data`:  Input data. It can be a file name, a GMTgrid or GMTimage object.

### Kwargs
- `nodata`: The nodata value that will be used to fill the regions. Otherwise use the `nodata` attribute of `indata`
   if it exists, or NaN if none of the above were set.
- band: the band number. Default is first layer in `indata` 
- maxdist: the maximum number of cels to search in all directions to find values to interpolate from. Default, fills all.
- nsmooth: the number of 3x3 smoothing filter passes to run (0 or more).

### Returns
The modified input `data`
"""
function fillnodata!(indata::GItype; nodata=nothing, kwargs...)
	d = GMT.KW(kwargs)
	d[:nodata] = (nodata !== nothing) ? nodata : isa(indata, GItype) ? indata.nodata : NaN
	helper_run_GDAL_fun(gdalfillnodata!, indata, "", String[], "", d...)
end

# ---------------------------------------------------------------------------------------------------
"""
    GI = fillnodata(data::String; nodata=nothing, kwargs...) -> GMTgrid or GMTimage

Fill selected raster regions by interpolation from the edges.

### Parameters
- `data`:  Input data. The file name of a grid or image that can be read with `gmtread`.
- `nodata`: The nodata value that will be used to fill the regions. Otherwise use the `nodata` attribute of `indata`
   if it exists, or NaN if none of the above were set.
- `kwargs`:
  - band: the band number. Default is first layer in `indata` 
  - maxdist: the maximum number of cels to search in all directions to find values to interpolate from. Default, fills all.
  - nsmooth: the number of 3x3 smoothing filter passes to run (0 or more).

### Returns
A GMTgrid or GMTimage object with the `band` nodata values filled by interpolation.
"""
function fillnodata(indata::String; nodata=nothing, kwargs...)
	indata = gmtread(indata, layout="TRB")
	fillnodata!(indata; nodata=nothing, kwargs...)
	return indata
end

# ---------------------------------------------------------------------------------------------------
"""
    D = polygonize(data::GItype; kwargs...) -> Vector{GMTdataset}

This method, which uses the GDAL GDALPolygonize function, creates vector polygons for all connected regions
of pixels in the raster sharing a common pixel/cell value. The input may be a grid or an image. This function can
be rather slow as it picks lots of polygons in pixels with slightly different values at transitions between colors.
Its natural use is to digitize masks images.

### Args
- `data`: Input data. It can be a GMTgrid or GMTimage object.

### Kwargs
- `min, nmin, npixels or ncells`: The minimum number of cells/pixels for a polygon to be retained.
    Default is 1. This can be set to filter out small polygons.
- `min_area`: Minimum area in m2 for a polygon to be retained. This option takes precedence over the one
    above that is based in the counting of cells. Note also that this is an approximate value because at this
    point we still don't know exactly the latitudes of the polygons.
- `max_area`: Maximum area in m2 for a polygon to be retained.
- `simplify`: Apply the Douglas-Peucker line simplification algorithm to the poligons. Provide a tolerence
    in meters. For example: `simplify=0.5`. But be warned that this is a risky option since a too large tolerance
	can lead to loss of otherwise good polygons. A good rule of thumb is to use the cell size for the tolerance.
	And in fact that is what we do when using `simplify=:auto`.
- `sort`: If true, will sort polygons by pixel count. Default is the order that GDAL decides internally.
"""
function polygonize(data::GItype; gdataset=nothing, kwargs...)
	d = GMT.KW(kwargs)
	(gdataset === nothing) && (d[:gdataset] = true)
	m_per_deg = 2pi * 6371000 / 360;	m_per_deg_2 = m_per_deg^2
	_isgeog = GMT.isgeog(data)
	min_area::Float64 = ((val = find_in_dict(d, [:min_area :minarea])[1]) !== nothing) ? Float64(val) : 0.0
	max_area::Float64 = ((val = find_in_dict(d, [:max_area :maxarea])[1]) !== nothing) ? Float64(val) : 0.0

	if ((val = find_in_dict(d, [:min :nmin :npixels :ncells])[1]) !== nothing || min_area > 0.0 || max_area > 0.0)
		# Compute the cell area. We have to do the (approximate) calculation here because in gd2gmt it often knows not if GEOG.
		if (_isgeog && min_area > 0.0 || max_area > 0.0)
			mean_lat = (data.range[3] + data.range[4]) / 2
			cell_area  = min_area / m_per_deg_2 / cosd(mean_lat)		# Approximate area in deg^2. At this time we don't know polygs lat
			cell_area2 = max_area / m_per_deg_2 / cosd(mean_lat)
			(val !== nothing) && @warn("'min_area' takes precedence over 'min', 'nmin', 'npixels' or 'ncells'")
		else
			cell_area = Float64(val)::Float64 * data.inc[1] * data.inc[2]
		end
		s_area = string(cell_area)
		isempty(GMT.POSTMAN[1]) ? (GMT.POSTMAN[1] = Dict("min_polygon_area" => s_area)) : GMT.POSTMAN[1]["min_polygon_area"] = s_area
		(max_area > 0.0) && (GMT.POSTMAN[1]["max_polygon_area"] = string(cell_area2))
		_isgeog && (GMT.POSTMAN[1]["polygon_isgeog"] = "1")
	end

	o = helper_run_GDAL_fun(gdalpolygonize, data, "", String[], "", d...)

	if (gdataset === nothing)						# Should be doing this for GDAL objects too but need to learn how to.
		GMT.POSTMAN[1]["polygonize"] = "y"			# To inform gd2gmt() that it should check if last Di is the whole area.
		(find_in_dict(d, [:sort])[1] !== nothing) && (GMT.POSTMAN[1]["sort_polygons"] = "y")
		if ((val = find_in_dict(d, [:simplify])[1]) !== nothing)
			s_val::String = string(val)
			# If simplify=auto, then use the cell side to estimate the simplification tolerance.
			s_val[1] == 'a' && (s_val = _isgeog ? string(data.inc[1] * m_per_deg) : string(data.inc[1]))
			GMT.POSTMAN[1]["simplify"] = s_val
		end
		prj = getproj(data)
		D = gd2gmt(o);
		!isempty(D) && (isa(D, Vector) ? (D[1].proj4 = prj) : (D.proj4 = prj))
		delete!(GMT.POSTMAN[1], "min_polygon_area")	# In case it was set above
		delete!(GMT.POSTMAN[1], "polygon_isgeog")
		return D
	end
	delete!(GMT.POSTMAN[1], "min_polygon_area")
	o
end

function polygonize(data::String; kwargs...)
	data = gmtread(data, layout="TRB")
	polygonize(data; kwargs...)
end

# ---------------------------------------------------------------------------------------------------
"""
    gdaldem(dataset, method, options=String[]; dest="/vsimem/tmp", color=name|GMTcpt, kw...)

Tools to analyze and visualize DEMs.

### Parameters
* `dataset` The source dataset.
* `method` the processing to apply (one of "hillshade", "slope",
    "aspect", "color-relief", "TRI", "TPI", "Roughness").
* `options` List of options (potentially including filename and open options).
    The accepted options are the ones of the gdaldem utility.

# Keyword Arguments
* `color` color file (mandatory for "color-relief" processing, should be empty otherwise).
   If `color` is just a CPT name we compute a CPT from it and the input grid.

* `kw...` keyword=value arguments when `method` is hillshade.

### Returns
A GMT grid or Image, or a GDAL dataset (or nothing if file was writen on disk).
"""
function gdaldem(indata, method::String, opts::Vector{String}=String[]; dest="/vsimem/tmp", kwargs...)
	opts = gdal_opts2vec(opts)		# Guarantied to return a Vector{String}
	if (method == "hillshade")		# So far the only method that accept kwarg options
		d = GMT.KW(kwargs)
		band = ((val = find_in_dict(d, [:band])[1]) !== nothing) ? string(val)::String : "1"
		append!(opts, ["-compute_edges", "-b", band])
		if ((val = find_in_dict(d, [:scale])[1]) === nothing)
			if (isa(indata, GMTgrid) && (occursin("longlat", indata.proj4) || occursin("latlong", indata.proj4)) ||
			                             grdinfo(indata, C="n").data[end] == 1)
				append!(opts, ["-s", "111120"])
			end
		else
			append!(opts, ["-s", string(val)])
		end
		((val = find_in_dict(d, [:zfactor :zFactor])[1]) !== nothing) && append!(opts, ["-z", string(val)])
		((val = find_in_dict(d, [:azim :azimuth])[1]) !== nothing) && append!(opts, ["-az", string(val)])
		((val = find_in_dict(d, [:elev :altitude])[1]) !== nothing) && append!(opts, ["-alt", string(val)])
		((val = find_in_dict(d, [:combined :combine])[1]) !== nothing) && append!(opts, ["-combined"])
		((val = find_in_dict(d, [:multi :multidir :multiDirectional])[1]) !== nothing) && append!(opts, ["-multidirectional"])
		((val = find_in_dict(d, [:igor])[1]) !== nothing) && append!(opts, ["-igor"])
		((val = find_in_dict(d, [:alg])[1]) !== nothing) && append!(opts, ["-alg", string(val)])
		((val = find_in_dict(d, [:Horn])[1]) !== nothing) && append!(opts, ["-alg", "Horn"])
		((val = find_in_dict(d, [:Zeven :Zevenbergen])[1]) !== nothing) && append!(opts, ["-alg", "ZevenbergenThorne"])
		helper_run_GDAL_fun(gdaldem, indata, dest, opts, method, d...)
	else
		helper_run_GDAL_fun(gdaldem, indata, dest, opts, method, kwargs...)
	end
end

# ---------------------------------------------------------------------------------------------------
"""
    G = gdalgrid(indata, method::StrSymb="", options=String[]; dest="/vsimem/tmp", kw...)

### Parameters
- `indata`: The source dataset. It can be a file name, a GMTdataset, a Mx3 matrix or a GDAL dataset
- `method`: The interpolation method name. One of "invdist", "invdistnn", "average", "nearest", "linear",
            "minimum", "maximum", "range", "count", "average_distance", "average_distance_pts".
- `options`: List of options. The accepted options are the ones of the gdal_grid utility.
            This list can be in the form of a vector of strings, or joined in a single string.
- `kwargs`: The `kwargs` may also contain the GMT region (-R), inc (-I) and `save=fname` options.

### Returns
A GMTgrid or a GDAL dataset (or nothing if file was writen on disk). To force the return of a GDAL
dataset use the option `gdataset=true`.
"""
function gdalgrid(indata, opts::Union{String, Vector{String}}=""; dest="/vsimem/tmp", method::Union{AbstractString, Symbol}="", kwargs...)
	if (method == "")
		_mtd = "-a invdist:nodata=NaN"
	else
		_mtd = isa(method, Symbol) ? string(method) : method 
		(!startswith(_mtd, "invdist") && !startswith(_mtd, "invdistnn") && !startswith(_mtd, "average") && !startswith(_mtd, "nearest") && !startswith(_mtd, "linear") && !startswith(_mtd, "minimum") && !startswith(_mtd, "maximum") && !startswith(_mtd, "range") && !startswith(_mtd, "count") && !startswith(_mtd, "average_distance") && !startswith(_mtd, "average_distance_pts")) && error("Bad interpolation algorithm $_mtd")
		_mtd = "-a " * _mtd
		!occursin("nodata", _mtd) && (_mtd *= ":nodata=NaN")
	end
	_opts = isa(opts, Vector) ? join(opts, " ") : opts		# Let's make a string to reduce confusion
	!occursin("-ot", _opts) && (_opts *= " -ot Float32")
	_mtd *= " " * _opts
	helper_run_GDAL_fun(gdalgrid, indata, dest, _mtd, "", kwargs...)
end

# ---------------------------------------------------------------------------------------------------
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
function helper_run_GDAL_fun(f::Function, indata, dest::String, opts, method::String="", kwargs...)::Union{GItype, GDtype, Gdal.AbstractDataset, Nothing}
	# Helper function to run the GDAL function under 'some protection' and returning obj or saving in file

	GMT.ressurectGDAL()				# Another black-hole plug attempt.
	opts = gdal_opts2vec(opts)		# Guarantied to return a Vector{String}
	d, opts, got_GMT_opts = GMT_opts_to_GDAL(f, opts, kwargs...)
	Vd::Int = ((val = find_in_dict(d, [:Vd])[1]) !== nothing) ? val : 0		# More gymns to avoid Anys
	(Vd > 0) && println(opts)

	# For gdaldem color-relief we need a further arg that is the name of a cpt. So save one on disk
	_cmap = C_NULL
	if (f == gdaldem && ((cmap = find_in_dict(d, GMT.CPTaliases)[1])) !== nothing)
		_cmap = TMPDIR_USR[1] * "/GMTjl_cpt_" * TMPDIR_USR[2] * TMPDIR_USR[3] * ".cpt"
		if ((isa(cmap, String) && (lowercase(splitext(cmap)[2][2:end]) == "cpt")) || isa(cmap, GMTcpt))
			save_cpt4gdal(cmap, _cmap)	# GDAL pretend to recognise CPTs but it almost doesn't
		elseif ((isa(cmap, String) || isa(cmap, Symbol)) && isa(indata, GMTgrid))
			save_cpt4gdal(makecpt(indata, C=string(cmap)), _cmap)
		else
			_cmap = cmap				# Risky, assume it's something GDAL can read
		end
	end

	dataset, needclose = get_gdaldataset(indata, opts, f == gdalvectortranslate || f == gdalgrid)
	if ((ind = findfirst("-projwin" .== opts)) !== nothing && !("-projwin_srs" in opts))
		x_min, x_max, y_min, y_max, = getregion(dataset)
		x_min > parse(Float64, opts[ind+1]) && error("Requested x_min " * opts[ind+1] * " is outside dataset extent")
		x_max < parse(Float64, opts[ind+3]) && error("Requested x_max " * opts[ind+3] * " is outside dataset extent")
		y_min > parse(Float64, opts[ind+4]) && error("Requested y_min " * opts[ind+4] * " is outside dataset extent")
		y_max < parse(Float64, opts[ind+2]) && error("Requested y_max " * opts[ind+2] * " is outside dataset extent")
	end
	((outname = GMT.add_opt(d, "", "", [:outgrid :outfile :save])) != "") && (dest = outname)
	default_gdopts!(f, dataset, opts, dest)	# Assign some default options in function of the driver and data type
	((val = find_in_dict(d, [:meta])[1]) !== nothing && isa(val,Vector{String})) &&
		Gdal.GDALSetMetadata(dataset.ptr, val, C_NULL)		# Metadata must be in the form NAME=.....

	CPLPushErrorHandler(@cfunction(CPLQuietErrorHandler, Cvoid, (UInt32, Cint, Cstring)))
	#setconfigoption("CPL_LOG_ERRORS", "ON")

	if (f == gdalfillnodata!)			# This guy has its own peculiarities
		f(dataset; d...)
		o = gd2gmt(dataset)
		indata.z, indata.hasnans, indata.layout = o.z, 1, o.layout
		return nothing
	else
		o = (method == "") ? f(dataset, opts; dest=dest, gdataset=true) : f(dataset, method, opts; dest=dest, gdataset=true, colorfile=_cmap)
	end

	(o !== nothing && o.ptr == C_NULL) && error("$(f) returned a NULL pointer.")
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
	(Vd > 0 && length(d) > 0) && println("Warning: the following options were not consumed in $f => ", keys(d))
	return o
end

# ---------------------------------------------------------------------------------------------------
# Because the GDAL reconnaissance of GMT cpts is very very weak, we must re-write CPTs in a way that it can swallow
save_cpt4gdal(cpt::String, outname::String) = save_cpt4gdal(gmtread(cpt), outname)
function save_cpt4gdal(cpt::GMTcpt, outname::String)
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
function GMT_opts_to_GDAL(f::Function, opts::Vector{String}, kwargs...)
	# Helper function to process some GMT options and turn them into GDAL syntax
	d = GMT.init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	if ((opt_R = GMT.parse_R(d, "")[1]) != "")
		s = split(opt_R[4:end], '/')
		if (f != gdalgrid)
			if haskey(d, :srcwin)					# projwin & srcwin have different syntax
				R = parse.(Float64, s)
				op = ["-srcwin", "$(R[1])", "$(R[3])", "$(R[2]-R[1])", "$(R[4]-R[3])"]
			else
				op = ["-projwin", s[1], s[4], s[2], s[3]]
			end
		end
		f == gdalgrid ? append!(opts, ["-txe", s[1], s[2], "-tye", s[3], s[4]]) : append!(opts, op)
		#f == gdalgrid ? append!(opts, ["-txe", s[1], s[2], "-tye", s[3], s[4]]) : append!(opts, ["-projwin", split(opt_R[4:end], '/')[[1,4,2,3]]...])	# Ugly
	end
	((opt_J = GMT.parse_J(d, "", default=" ")[1]) != "") && append!(opts, ["-a_srs", opt_J[4:end]])
	if ((opt_I = GMT.parse_I(d, "", [:I :inc :increment :spacing], "I", true)) != "")	# Need the 'I' to not fall into parse_I() exceptions
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
	[v[i] = replace(v[i], '\x7f' => ' ') for i = 1:lastindex(v)]		# Undo the Char(127) char
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
	(f != ogr2ogr && f != gdalgrid && startswith(lowercase(driver), "mem") && dt == 1 && isa(ds, Gdal.IDataset)) && (dt = GDALGetRasterDataType(getband(ds,1).ptr))
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
function get_gdaldataset(data, opts, isVec::Bool=false)::Tuple{Gdal.AbstractDataset, Bool}
	# Get a GDAL dataset from either a file name, a GMT grid or image, or a dataset itself
	# In case of a file name we must be careful and deal with possible "+b" band requests from GMT.
	# isVec tells us if the filename 'data' is to be opened as a Vector or a Raster.
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
				for k = 1:lastindex(o)  append!(opts, ["-b", o[k]])  end
			else
				opts *= " -b" * join(o, " -b ")
			end
		end
		flags = isVec ? GDAL_OF_VECTOR | GDAL_OF_VERBOSE_ERROR : GDAL_OF_READONLY | GDAL_OF_VERBOSE_ERROR
		_ext = lowercase(ext[2:end])		# Drop the leading dot too
		if ((name[1] == '@') || (findfirst(isequal(_ext), ["dat", "txt", "csv"]) !== nothing))
			ds::Gdal.AbstractDataset = gmt2gd(gmtread(name))
		else
			ds = Gdal.unsafe_read(name, flags=flags)
			needclose = true
		end
	elseif (isa(data, GMTgrid) || isa(data, GMTimage) || isa(data, GDtype) || isa(data, Matrix{<:Real}))
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
