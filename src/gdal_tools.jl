"""
gdaltranslate(fname::AbstractString, opts=String[]; kwargs...)

	Convert raster data between different formats and other operations also provided by the GDAL
	'gdal_translate' tool. Namely sub-region extraction and resampling.
	The kwargs options accept the GMT region (-R), increment (-I), target SRS (-J) any of the keywords
	'outgrid', 'outfile' or 'save' = outputname options to make this function save the result in disk
	in the file 'outputname'. The file format is picked from the 'outputname' file extension.
	When any of the GMT options is used and no output file name is provided it returns a GMT object
	(either a grid or an image, depending on the input type). To force the return of a GDAL dataset
	use the option 'gdataset=true'

	OPTS - List of options. The accepted options are the ones of the gdal_translate utility.
"""
# ---------------------------------------------------------------------------------------------------
function gdaltranslate(fname::AbstractString, opts=String[]; dest="/vsimem/tmp", kwargs...)
	# A version that uses a mix of GMT and GDL syntax
	d, fname, opts, got_GMT_opts = helper_GMT_opts_to_GDAL(fname, opts, kwargs...)
	helper_run_GDAL_fun(gdaltranslate, dest, d, fname, opts, got_GMT_opts)
end

# ---------------------------------------------------------------------------------------------------
function gdalwarp(fname::AbstractString, opts=String[]; dest="/vsimem/tmp", kwargs...)
	d, fname, opts, got_GMT_opts = helper_GMT_opts_to_GDAL(fname, opts, kwargs...)
	helper_run_GDAL_fun(gdalwarp, dest, d, fname, opts, got_GMT_opts)
end

# ---------------------------------------------------------------------------------------------------
function helper_GMT_opts_to_GDAL(fname::AbstractString, opts::Vector{String}, kwargs...)
	# Helper function to process some GMT options and turn them into GDAL syntax
	(fname[1] == '@') && (fname = gmtwhich(fname)[1].text[1])	# A remote file

	d = GMT.init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	((opt_R = GMT.parse_R(d, "")[1]) != "") && append!(opts, ["-projwin", split(opt_R[4:end], '/')[[1,4,2,3]]...])
	((opt_J = GMT.parse_J(d, "", " ")[1]) != " ") && append!(opts, ["-a_srs", opt_J[4:end]])
	if ((opt_I = GMT.parse_inc(d, "", [:I :inc], 'I')) != "")	# Need the 'I' to not fall into parse_inc() exceptions
		t = split(opt_I[4:end], '/')
		(length(t) == 1) ? append!(opts, ["-tr", t[1], t[1]]) : append!(opts, ["-tr", t[1], t[2]])
	end
	return d, fname, opts, (opt_R != "" || opt_J != "" || opt_I != "")
end

# ---------------------------------------------------------------------------------------------------
function helper_run_GDAL_fun(f::Function, dest::String, d::Dict, fname::AbstractString, opts::Vector{String}, got_GMT_opts::Bool)
	# Helper function to run the GDAL function under 'some protection' and returning obj or saving in file
	CPLPushErrorHandler(@cfunction(CPLQuietErrorHandler, Cvoid, (UInt32, Cint, Cstring)))
	if ((outname = GMT.add_opt(d, "", "", [:outgrid :outfile :save])) != "")
		f(Gdal.unsafe_read(fname), opts; dest=outname)
		o = nothing
	else
		o = f(Gdal.unsafe_read(fname), opts; dest=dest)
		# If any GMT opt is used and not explicitly stated to return a GDAL datase, return a GMT type
	(got_GMT_opts && !haskey(d, :gdataset)) && (o = gd2gmt(o))
	end
	CPLPopErrorHandler();
	o
end