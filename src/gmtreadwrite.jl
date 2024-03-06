"""
	gmtread(fname::String; kwargs...)

Read GMT object from file. The object is one of "grid" or "grd", "image" or "img",
"data" or "table", "cmap" or "cpt" and "ps" (for postscript), and OGR formats (shp, kml, json).
Use a type specificatin to force a certain reading path (e.g. `grd=true` to read grids) or take
the chance of letting the data type be guessed via the file extension. Known extensions are:

- Grids:      .grd, .jp2 .nc
- Images:     .jpg, .jp2 .png, .tif, .tiff, .bmp, .webp
- Datasets:   .dat, .txt, .csv
- Datasets:   .shp, .kml, .json, .geojson, .gmt, .gpkg, .gpx, .gml
- CPT:        .cpt
- PostScript: .ps, .eps

Parameters
----------

Specify data type (with *type*=true, e.g. `img=true`).  Choose among:
- `grd` | `grid`: Load a grid.

- `img` | `image`: Load an image.

- `cpt` | `cmap`: Load a GMT color palette.

- `data` | `dataset` | `table`: Load a dataset (a table of numbers).

- `ogr`: Load a dataset via GDAL OGR (a table of numbers). Many things can happen here.

- `ps`: Load a PostScript file

- `gdal`: Force reading the file via GDAL. Should only be used to read grids.

- `varname`: When netCDF files have more than one 2D (or higher) variables use *varname* to pick the wished
  variable. e.g. ``varname=:slp`` to read the variable named ``slp``. This option defaults data type to `grid`.
  This option can be used both with and without the `gdal` option. Former case uses GMT lib to read the cube and
  outputs and 3D array in column major order, later case (the one with `gdal`) uses GDAL to read the cube and
  outputs and 3D array in row major order. Remember that the ``layout`` member of the GMTgrid type informs
  about memory layout.

- `layer`| `layers` | `band` | `bands`: A string, or a number or an Array. When files are multiband or
  nc files with 3D or 4D arrays, we access them via these keywords. `layer=4` reads the fourth layer (or band)
  of the file. The file can be a grid or an image. If it is a grid, layer can be a scalar (to read 3D arrays)
  or an array of two elements (to read a 4D array). This option should not be used with the `gdal` option.

  If file is an image `layer` can be a 1 or a 1x3 array (to read a RGB image). Note that in this later case
  bands do not need to be contiguous. A `band=[1,5,2]` composes an RGB out of those bands. See more at
  $(GMTdoc)/GMT_Docs.html#modifiers-for-coards-compliant-netcdf-files) but note that we use **1 based** indexing here.

  Use ``layers=:all`` to read all levels of a 3D cube netCDF file.

- $(GMT._opt_R)
- $(GMT.opt_V)
- $(GMT._opt_bi)
- $(GMT._opt_f)

Example: to read a nc called 'lixo.grd'

    G = gmtread("lixo.grd");

to read a jpg image with the bands reversed

    I = gmtread("image.jpg", band=[2,1,0]);
"""
function gmtread(_fname::String; kwargs...)

	fname::String = _fname					# Because args signatures seam to worth shit in body.
	d = init_module(false, kwargs...)[1]	# Also checks if the user wants ONLY the HELP mode
	cmd::String, opt_R::String = parse_R(d, "")
	cmd, opt_i = parse_i(d, cmd)
	cmd = parse_common_opts(d, cmd, [:V_params :f :h])[1]
	cmd, opt_bi = parse_bi(d, cmd)
	proggy = "read "						# When reading an entire grid cube, this will change to 'grdinterpolate'

	# Process these first so they may take precedence over defaults set below
	opt_T = add_opt(d, "", "Tg", [:grd :grid])
	if (opt_T != "")		# Force read via GDAL
		((val = find_in_dict(d, [:gdal])[1]) !== nothing) && (fname *= "=gd")
	else
		opt_T = add_opt(d, "", "Ti", [:img :image])
	end
	if (opt_T == "")  opt_T = add_opt(d, "", "Td", [:data :dataset :table])  end
	if (opt_T == "")  opt_T = add_opt(d, "", "Tc", [:cpt :cmap])  end
	if (opt_T == "")  opt_T = add_opt(d, "", "Tp", [:ps])   end
	if (opt_T == "")  opt_T = add_opt(d, "", "To", [:ogr])  end

	ogr_layer::Int32 = Int32(0)			# Used only with ogrread. Means by default read only the first layer
	if ((varname = find_in_dict(d, [:varname])[1]) !== nothing) # See if we have a nc varname / layer request
		varname = string(varname)::String
		(opt_T == "") && (opt_T = " -Tg")		# Though not used in if 'gdal', it still avoids going into needless tests below
		if ((val = find_in_dict(d, [:gdal])[1]) !== nothing)	# This branch is fragile
			fname = sneak_in_SUBDASETS(fname, varname)	# Get the composed name (fname + subdaset and driver)
			proggy = "gdalread"
			gdopts = ""
			if ((val = find_in_dict(d, [:layer :layers :band :bands])[1]) !== nothing)
				if (isa(val, Real))               gdopts = @sprintf(" -b %d", val)
				elseif (isa(val, AbstractArray))  gdopts = join([@sprintf(" -b %d", val[i]) for i in 1:numel(val)])
				end
			end
		else
			fname *= "?" * varname
			if ((val = find_in_dict(d, [:layer :layers :band :bands])[1]) !== nothing)
				if (isa(val, Real))       fname *= @sprintf("[%d]", val-1)
				elseif (isa(val, AbstractArray))  fname *= @sprintf("[%d,%d]", val[1]-1, val[2]-1)	# A 4D array
				elseif ((isa(val, String) || isa(val, Symbol)) && (string(val) == "all")) proggy = "grdinterpolate "
				end
			end
		end
	else											# See if we have a bands request
		if ((val = find_in_dict(d, [:layer :layers :band :bands])[1]) !== nothing)
			(opt_T == "") && (opt_T = guess_T_from_ext(fname))
			if (opt_T == " -To")					# See if it's a OGR layer request
				ogr_layer = Int32(val)::Int32 - 1	# -1 because it's going to be sent to C (zero based)
			else
				ds = Gdal.unsafe_read(fname)
				(Gdal.nraster(ds) < 2) &&			# Check that file is indeed a cube
					(println("\tThis file ($fname) does not contain cube data (more than one layer).
					\n\tRun 'println(gdalinfo(\"$fname\"))' for details.");
					Gdal.GDALClose(ds.ptr); return nothing)
				if (isa(val, String) || isa(val, Symbol) || isa(val, Real))
					bd_str::String = string(val)::String
					if (bd_str == "all")
						proggy = ((val = find_in_dict(d, [:gdal])[1]) !== nothing) ? "gdalread" : "grdinterpolate "
					else
						fname = string(fname, "+b", parse(Int, bd_str)-1)	# Should be possible to have a GDAL alternative here.
					end
				elseif (isa(val, Array) || isa(val, Tuple))
					#(opt_T == " -Tg") && (println("\tSorry, we do not yet support loading multiple layers from grids."); return nothing)
					opt_T = " -Ti"
					# Replacement for the annoying fact that one cannot do @sprintf(repeat("%d,", n), val...)
					fname  *= @sprintf("+b%d", Int(val[1])::Int -1)
					for k = 2:lastindex(val)  fname *= @sprintf(",%d", val[k]-1)  end
				end
			end
		end
	end

	# These are tricky gals, but we know who they are so use that knowledge.
	if (opt_T == "")
		if (startswith(fname, "@earth_day") || startswith(fname, "@earth_night"))                opt_T = " -Ti"
		elseif ((fname[1] == '@' && contains(fname, "_relief")) || startswith(fname, "@srtm_"))  opt_T = " -Tg"
		end
		# To shut up a f annoying GMT warning.
		(opt_T == " -Tg") && startswith(fname, "@earth_") && !endswith(fname, "_g") && !endswith(fname, "_p") && (fname *= "_g")
	end

	(opt_T == "" && opt_bi != "") && (opt_T = " -Td")	# If asked to read binary, must be a 'data' file.

	if (opt_T == "")
		((opt_T = guess_T_from_ext(fname)) == "") && error("Must select the input data type (grid, image, dataset, ogr, cmap or ps)")
		(opt_T == " -Tg" && haskey(d, :ignore_grd)) && return nothing	# contourf uses this
		if (opt_T == " -To" && fname[1] == '@')		# Because GMT ogrread does not know the '@' mechanism.
			fname = joinpath(readlines(`gmt --show-userdir`)[1], "cache", fname[2:end])
			!isfile(fname) && error("File $fname does not exist in cache.")
		elseif (opt_T == " -Toz")					# Means we got a zipped ogr file
			fname, opt_T = "/vsizip/" * fname, " -To"
		end
	else
		opt_T = opt_T[1:4]      					# Remove whatever was given as argument to type kwarg
	end

	if (opt_T == " -Ti" || opt_T == " -Tg")			# See if we have a mem layout request
		if ((val = find_in_dict(d, [:layout :mem_layout])[1]) !== nothing)
			(opt_T == " -Ti" && startswith(string(val)::String, "TRB")) && return gdaltranslate(fname)
			# MUST TAKE SOME ACTION HERE. FOR IMAGES I THINK ONLY THE "I" FOR IMAGES.JL IS REALLY POSSIBLE
			cmd = (opt_T == " -Ti") ? cmd * " -%" * arg2str(val) : cmd * " -&" * arg2str(val)
		end
	end

	if (opt_T != " -To")			# All others but OGR
		(proggy == "read ") && (cmd *= opt_T)
		(dbg_print_cmd(d, cmd) !== nothing) && return proggy * fname * cmd
		o = (proggy == "gdalread") ? gdalread(fname, gdopts) : gmt(proggy * fname * cmd)
		(isempty(o)) && (@warn("\tfile \"$fname\" is empty or has no data after the header.\n"); return GMTdataset())

		((cptname = check_remote_cpt(fname)) != "") && (o.cpt = cptname)	# Seek for default CPT names
		(isa(o, GMTimage)) && (o.range[5:6] .= extrema(o.image))	# It's ugly to see those floatmin/max in there.
		(isa(o, GMTimage) && size(o.image, 3) < 3) && (o.layout = o.layout[1:2] * "B" * (length(o.layout) == 4 ? o.layout[4] : "a"))

		# If loading a cube, see also if there are layers descriptions to fetch.
		if ((isa(o, GMTgrid) && size(o,3) > 1)) || (isa(o, GMTimage) && !(eltype(o) <: UInt8) && size(o,3) > 1)
			desc = get_cube_layers_desc(fname)
			!all(desc .== "") && (o.names = desc)
		end

		if (opt_i != "" && contains(opt_i, '+'))
			spli = split(opt_i[4:end], ',')
			for k = 1:numel(spli)
				((ind = findfirst('+', spli[k])) !== nothing) && (spli[k] = spli[k][1:ind[1]-1])
			end
			corder = parse.(Int, spli) .+ 1
		elseif (opt_i != "")
			corder = parse.(Int, split(opt_i[4:end], ',')) .+ 1		# +1 because -i in GMT is 0 based
		else
			corder = Int[]
		end

		# If GMTdataset see if the comment may have the column names
		if (isa(o, GMTdataset) && isempty(o.colnames) && !isempty(o.comment)) ||
			(isa(o, Vector{<:GMTdataset}) && isempty(o[1].colnames) && !isempty(o[1].comment))
			helper_set_colnames!(o, corder)		# Set colnames if file has a comment line supporting it
		end

		# Try guess if ascii file has time columns and if yes leave trace of it in GMTdadaset metadata.
		(opt_bi == "" && isa(o, GDtype)) && file_has_time!(fname, o, corder)

		if (isa(o, GMTgrid))
			o.hasnans = any(!isfinite, o.z) ? 2 : 1
			# Check if we should assign a default CPT to this grid
			((fname[1] == '@') && (cptname = check_remote_cpt(fname)) != "") && (o.cpt = cptname)
		end
		return o
	end

	(dbg_print_cmd(d, cmd) !== nothing) && return "ogrread " * fname * " " * cmd
	# Because of the certificates shits on Windows. But for some reason the set in gmtlib_check_url_name() is not visible
	(Sys.iswindows()) && run(`cmd /c set GDAL_HTTP_UNSAFESSL=YES`)
	API2 = GMT_Create_Session("GMT", 2, GMT_SESSION_NOEXIT + GMT_SESSION_EXTERNAL + GMT_SESSION_NOGDALCLOSE + GMT_SESSION_COLMAJOR);

	drop_islands = ((val = find_in_dict(d, [:no_islands :no_holes])[1]) !== nothing) ? true : false
	x = (opt_R == "") ? [0.0, 0, 0, 0] : opt_R2num(opt_R)		# See if we have a limits request
	lims = tuple(vcat(x,[0.0, 0.0])...)
	ctrl = OGRREAD_CTRL(Int32(0), ogr_layer, pointer(fname), lims)
	O = ogr2GMTdataset(gmt_ogrread(API2, pointer([ctrl])), drop_islands)

	ressurectGDAL()				# Because GMT called GDALDestroyDriverManager()
	GMT_Destroy_Session(API2)
	return O
end

# ---------------------------------------------------------------------------------
function sneak_in_SUBDASETS(fname, varname)
	# Create a new filename with the SUBDATASET_ name. Need this when GDAL is reading per SUBDASET and not whole file
	# 'fname' is the file name and 'varname' the name of the subdataset.
	gdinfo = gdalinfo(fname)
	((ind1 = findfirst("SUBDATASET_", gdinfo)) === nothing) && error("The $varname SUBDATASET does not exist in $fname")
	tmp_s  = gdinfo[ind1[end]:ind1[end]+20]		# 20 should be enough to include the format name. e.g. "HDF"
	ind2   = findfirst("=", tmp_s)				# For example, tmp_s = "_1_NAME=NETCDF:\"woa18"
	ind3   = findfirst(":", tmp_s)
	fmt    = tmp_s[ind2[1]+1:ind3[1]]			# e.g. fmt = "NETCDF:"
	fname  = fmt * fname * ":" * string(varname)::String
	return fname
end

# ---------------------------------------------------------------------------------
"""
    desc = get_cube_layers_desc(fname::String, layers::Vector{Int}=Int[]) -> Vector{String}

- `fname`: The name of a disk file of a cube.

- `layers`: Only used when called from ``find_layers()`` in ``RemoteS``
"""
function get_cube_layers_desc(fname::String, layers::Vector{Int}=Int[])#::String[]
	if ((ind = findfirst("?", fname)) !== nothing)
		fname = sneak_in_SUBDASETS(fname[1:ind[1]-1], fname[ind[1]+1:end])
	end
	ds = Gdal.unsafe_read(fname)
	n_bands, msg = Gdal.nraster(ds), ""
	(n_bands < 2) && (msg = "This file ($fname) does not contain cube data (more than one layer).")
	(!isempty(layers) && maximum(layers) > n_bands) && (msg = "Asked for more 'layers' ($(n_bands)) than this cube contains.")
	(msg != "") && (Gdal.GDALClose(ds.ptr); error(msg))
	desc = fill("", n_bands)
	[desc[k] = Gdal.GDALGetDescription(Gdal.GDALGetRasterBand(ds.ptr, k)) for k = 1:n_bands]
	Gdal.GDALClose(ds.ptr)
	return desc
end

# ---------------------------------------------------------------------------------
function helper_set_colnames!(o::GDtype, corder::Vector{Int}=Int[])
	# This is used both by gmtread() and inside read_data()
	if (isa(o, GMTdataset))
		isempty(o.comment) && return nothing
		ncs = size(o,2)			# Next line checks if the comment is comma separated
		hfs = (count(i->(i == ','), o.comment[1]) >= ncs-1) ? strip.(split(o.comment[1], ',')) : split(o.comment[1])
		col_text = (!isempty(o.text) && length(hfs) > ncs) ? hfs[ncs+1] : ""
		(!isempty(corder)) && (hfs = hfs[corder])
		o.colnames = (length(hfs) > ncs) ? string.(hfs)[1:ncs] : string.(hfs)
		(col_text != "") && (append!(o.colnames, [col_text]))
	else
		isempty(o[1].comment) && return nothing
		hfs, ncs = split(o[1].comment[1]), size(o[1],2)
		(length(hfs) == 1) && (hfs = split(o[1].comment[1], ','))	# Try also the comma separator
		col_text = (!isempty(o[1].text) && length(hfs) > ncs) ? hfs[ncs+1] : ""
		(!isempty(corder)) && (hfs = hfs[corder])
		o[1].colnames = (length(hfs) > ncs) ? string.(hfs)[1:ncs] : string.(hfs)
		#(!isempty(corder)) && (o[1].colnames = o[1].colnames[corder])
		(col_text != "") && (append!(o[1].colnames, [col_text]))
	end
	return nothing
end

# ---------------------------------------------------------------------------------
function file_has_time!(fname::String, D::GDtype, corder::Vector{Int}=Int[])
	# Try guess if 'fname' file has time columns and if yes leave trace of it in D's metadata.
	# We do that by scanning the first valid line in file.
	# 'corder' is a vector of ints filled with column orders specified by -i. If no -i that it is empty

	startswith(fname, "http") && return nothing			# We can't "open(fname)" beloow
	#line1 = split(collect(Iterators.take(eachline(fname), 1))[1])	# Read first line and cut it in tokens
	isone = isa(D, GMTdataset) ? true : false
	if (isone && isempty(D.colnames)) || (!isone && isempty(D[1].colnames))		# If no colnames set yet
		names_str = (isone) ? ["col.$i" for i=1:size(D,2)] : ["col.$i" for i=1:size(D[1],2)]
		isone ? (D.colnames = names_str) : [D[k].colnames = names_str for k = 1:lastindex(D)]	# Default col names
	end
	n_cols = (isone) ? size(D,2) : size(D[1],2)
	Tc, f1, n_it = "", 1, 0
	(fname[1] == '@') && (gmt("gmtwhich -Gc $fname"); fname = joinpath(GMT.GMTuserdir[1], "cache", fname[2:end]))
	fid = open(fname)
	iter = eachline(fid)
	try
		for it in iter
			(n_it > 10 || Tc != "") && break			# Means that previous iteration found it.
			n_commas = count_chars(it)
			use_commas = (n_cols > 1) && (n_commas >= n_cols-1)		# To see if we split on spaces or on commas.
			line1 = (use_commas) ? split(it, ',') : split(it)
			n_it += 1			# Counter to not let this go on infinetely
			(isempty(line1) || contains(">#!%;", line1[1][1])) && continue
			loop_inds = isempty(corder) ? (1:n_cols) : corder
			for k in loop_inds
				# Time cols may come in forms like [-]yyyy-mm-dd[T| [hh:mm:ss.sss]], so to find them we seek for
				# '-' chars in the middle of strings that we KNOW have been converted to numbers. The shit that is
				# left to be solved is that we can have TWO strings, 'yyyy-mm-dd hh:mm:ss.sss' to mean a single time.
				if ((i = findlast("-", line1[k])) !== nothing && i[1] > 1 && lowercase(line1[k][i[1]-1]) != 'e')
					Ts = (f1 == 1) ? "Time" : "Time$(f1)";		f1 += 1
					ind_t = (!isempty(corder)) ? findfirst(k .== corder) : k	# When -i was used 'corder' has new col order
					Tc = (Tc == "") ? "$ind_t" : Tc * ",$ind_t"			# Accept more than one time columns
					(isone) ? (D.colnames[ind_t] = Ts) : (D[1].colnames[ind_t] = Ts)
				end
			end
			(Tc != "") && ((isone) ? (D.attrib["Timecol"] = Tc) : (D[1].attrib["Timecol"] = Tc))
		end
	catch err
		isone ? (D.colnames = String[]) : [D[k].colnames = String[] for k = 1:lastindex(D)]
		@warn("Failed to parse file '$fname' for file_has_time!(). Error was:\n $err")
	end
	close(fid)
	return nothing
end
	
# ---------------------------------------------------------------------------------
function guess_T_from_ext(fname::String, write::Bool=false)::String
	# Guess the -T option from a couple of known extensions
	fn, ext = splitext(fname)
	if (ext == ".zip")			# Accept ogr zipped files, e.g., *.shp.zip
		((out = guess_T_from_ext(fn)) == " -To") && return " -Toz"
	end

	_kml = (!write) ? "kml" : "*"	# This because on write we dont want to check for kml (let it be written as text)

	(length(ext) > 8 || occursin("?", ext)) && return (occursin("?", ext)) ? " -Tg" : "" # A SUBDATASET encoded fname?
	ext = lowercase(ext[2:end])
	(!write && (ext == "jp2" || ext == "tif" || ext == "tiff") && (!isfile(fname) && !startswith(fname, "/vsi") &&
		!occursin("https:", fname) && !occursin("http:", fname) && !occursin("ftps:", fname) && !occursin("ftp:", fname))) &&
		error("File $fname does not exist.")
	if     (findfirst(isequal(ext), ["grd", "nc", "nc=gd"])  !== nothing)  out = " -Tg";
	elseif (findfirst(isequal(ext), ["dat", "txt", "csv"])   !== nothing)  out = " -Td";
	elseif (findfirst(isequal(ext), ["jpg", "jpeg", "png", "bmp", "webp"]) 	!== nothing)  out = " -Ti";
	elseif (findfirst(isequal(ext), ["arrow", "shp", _kml, "json", "feather", "geojson", "gmt", "gpkg", "gpx", "gml", "parquet"]) !== nothing)  out = " -To";
	elseif (ext == "jp2") ressurectGDAL(); out = (findfirst("Type=UInt", gdalinfo(fname)) !== nothing) ? " -Ti" : " -Tg"
	elseif (ext == "cpt")  out = " -Tc";
	elseif (ext == "ps" || ext == "eps")  out = " -Tp";
	elseif (startswith(ext, "tif"))
		write && return " -Ti"			# Back to the caller must desambiguate if -Ti or -Tg
		ressurectGDAL();
		gdinfo = gdalinfo(fname)
		(gdinfo === nothing) && error("gdalinfo failed - unable to open $fname")
		out = (findfirst("Type=UInt", gdinfo) !== nothing || findfirst("Type=Byte", gdinfo) !== nothing) ? " -Ti" : " -Tg"
	else
		out = ""
	end
end

"""
	gmtwrite(fname::AbstractString, data; kwargs...)

Write a GMT object to file. The object is one of "grid" or "grd", "image" or "img",
"dataset" or "table", "cmap" or "cpt" and "ps" (for postscript).

When saving grids, images and datasets we have a panoply of formats at our disposal.
For the datasets case if the file name ends in .arrow, .shp, .json, .feather, .geojson, .gmt,
.gpkg, .gpx, .gml or .parquet then it automatically selects ``gdalwrite`` and saves the GMT
dataset in that OGR vector format. The .kml is treated as a special case because there are GMT modules
(e.g. `gmt2kml`) that produce KML formatted data and so we write it directly as a text file.

Parameters
----------

- `id`:  [Type => Str] 

    Use an ``id`` code when not not saving a grid into a standard COARDS-compliant netCDF grid. This ``id``
    is made up of two characters like ``ef`` to save in ESRI Arc/Info ASCII Grid Interchange format (ASCII float).
    See the full list of ids at $(GMTdoc)grdconvert.html#format-identifier.

    ($(GMTdoc)grdconvert.html#g)
- `scale` | `offset`: [Type => Number]

    You may optionally ask to scale the data and then offset them with the specified amounts.
    These modifiers are particularly practical when storing the data as integers, by first removing an offset
    and then scaling down the values.
- `nan` | `novalue` | `invalid` | `missing`: [Type => Number]

    Lets you supply a value that represents an invalid grid entry, i.e., ‘Not-a-Number’.
- `gdal`: [Type => Bool]

    Force the use of the GDAL library to write the grid (to be used only with grids).
    ($(GMTdoc)GMT_Docs.html#grid-file-format-specifications)
- `driver`: [Type => Str]

    When saving in other than the netCDF format we must tell the GDAL library what is wished format.
    That is done by specifying the driver name used by GDAL itself (e.g., netCDF, GTiFF, etc...).
- `datatype`: [Type => Str] 		``Arg = u8|u16|i16|u32|i32|float32``

    When saving with GDAL we can specify the data type from u8|u16|i16|u32|i32|float32 where ‘i’ and ‘u’ denote
    signed and unsigned integers respectively.
- $(GMT._opt_R)
- $(GMT.opt_V)
- $(GMT.opt_bo)
- $(GMT._opt_f)

Example: write the GMTgrid 'G' object into a nc file called 'lixo.grd'

	gmtwrite("lixo.grd", G);
"""
gmtwrite(data; kwargs...) = gmtwrite("", data; kwargs...)
function gmtwrite(fname::AbstractString, data; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_R(d, "")
	cmd, = parse_common_opts(d, cmd, [:V_params :f])
	if (fname == "")
		opt_G = parse_G(d, "")[1]
		(opt_G != "") && (fname = opt_G[4:end])	# opt_G comes with the " -G" prefix
	end
	(fname == "") && error("Output file name cannot be empty.")

	if (isa(data, GMTgrid))
		#opt_T = " -Tg"
		#fname *= parse_grd_format(d)			# If we have format requests
		#cmd, = parse_f(d, cmd)
		#CTRL.proj_linear[1] = true				# To force pad=0 and julia memory (no dup)

		# GMT doesn't write correct CF nc grids that are referenced but non-geographic. So, use GDAL in those cases
		fmt = parse_grd_format(d)				# See if we have format requests
		_, opt_f = parse_f(d, "")
		ext = lowercase(splitext(fname)[2])
		if (fmt == "" && opt_f == "" && (ext == ".grd" || ext == ".nc"))
			prj = getproj(data, proj4=true)
			(prj != "" && !contains(prj, "=long") && !contains(prj, "=lat")) && return gdaltranslate(data, dest=fname)
		elseif (fmt == "" && ext == ".tif" || ext == ".tiff")	# If .tif, write a Geotiff file
			fmt = "=gd:GTiff"
		end
		opt_T = " -Tg"
		fname *= fmt
		cmd *= opt_f
		CTRL.proj_linear[1] = true				# To force pad=0 and julia memory (no dup)
	elseif (isa(data, GMTimage))
		opt_T = " -Ti"
		fname *= parse_grd_format(d)			# If we have format requests
		CTRL.proj_linear[1] = true				# To force pad=0 and julia memory (no dup) in image_init()
		transpcmap!(data, true)
	elseif (isa(data, GDtype))
		opt_T = " -Td"
		cmd, = parse_bo(d, cmd)					# Write to binary file
	elseif (isa(data, GMTcpt))
		opt_T = " -Tc"
	elseif (isa(data, GMTps))
		opt_T = " -Tp"
	elseif (isa(data, Array{UInt8}))
		fmt = parse_grd_format(d)				# See if we have format requests
		if (fmt == "")							# If no format, write a dataset
			opt_T = " -Td"
			cmd, = parse_bo(d, cmd)				# Write to binary file
		else
			data = mat2img(data)
			fname *= fmt
			opt_T = " -Ti"
		end
	elseif (isa(data, AbstractArray))
		fmt = parse_grd_format(d)				# See if we have format requests
		if (fmt == "")							# If no format, write a dataset
			opt_T = " -Td"
			cmd, = parse_bo(d, cmd)				# Write to binary file
		else
			data = mat2grid(data)
			fname *= fmt
			opt_T = " -Tg"
		end
	else
		error("Input data of unknown data type $(typeof(data))")
	end
	cmd = cmd * opt_T

	if (opt_T == " -Ti" || opt_T == " -Tg")		# See if we have a mem layout request
		if ((val = find_in_dict(d, [:layout :mem_layout])[1]) !== nothing)
			cmd = (opt_T == " -Ti") ? cmd * " -%" * arg2str(val) : cmd * " -&" * arg2str(val)
		end
	end

	(dbg_print_cmd(d, cmd) !== nothing) && return "gmtwrite " * fname * cmd

	(opt_T == " -Tg" && isa(data, GMTgrid) && (data.scale != 1 || data.offset != 0)) && (fname *= "+s$(data.scale)+o$(data.offset)")
	if (guess_T_from_ext(fname, true) == " -To")  gdalwrite(fname, data)		# Write OGR data
	else                                          gmt("write " * fname * cmd, data)
	end
	(opt_T == " -Ti") && transpcmap!(data, false)		# Reset original cmap (in case it was changed)
	return nothing
end

# -----------------------------------------------------------------------------------------------
function parse_grd_format(d::Dict)::String
# Scan options to fill any of  [=<id>][+s<scale>][+o<offset>][+n<nan>][:<driver>[/<dataType>]
# that control the grid/image output format
	out = ""
	for sym in [:id :gdal :driver]
		if (haskey(d, sym))
			if (sym == :gdal || sym == :driver)
				out = "=gd"
			else
				t = arg2str(d[sym])
				(length(t) != 2) && error(@sprintf("Format code MUST have 2 characters and not %s", t))
				out = "=" * t
			end
			break
		end
	end
	if ((val = find_in_dict(d, [:scale])[1]) !== nothing)   out *= "+s" * arg2str(val)  end
	if ((val = find_in_dict(d, [:offset])[1]) !== nothing)  out *= "+o" * arg2str(val)  end
	if ((val = find_in_dict(d, [:nan :novalue :invalid :missing])[1]) !== nothing)
		out *= "+n" * arg2str(val)
	end
	if ((val = find_in_dict(d, [:driver])[1]) !== nothing)
		out *= ":" * arg2str(val)
		((val = find_in_dict(d, [:datatype])[1]) !== nothing) && (out *= "/" * arg2str(val))
	end
	delete!(d, [:id, :gdal])
	return out
end

# -----------------------------------------------------------------------------------------------
function transpcmap!(I::GMTimage, toGMT::Bool=true)
	# So, the shit is in GMT when making plots it expects the colormap to be column-major (MEX inheritance)
	# but gdalwrite it expects it to be row-major. So we must do some transpose work here.
	# Not anymore (GMT6.3), now gdalwrite expects column-mjor. Shit.
	(ndims(I) != 2 || I.n_colors <= 1 || eltype(I) == UInt16) && return nothing 	# Nothing to do

	n_colors = I.n_colors
	(n_colors > 2000) && (n_colors = Int(floor(n_colors / 1000)))
	if (toGMT)
		n_cols = Int(length(I.colormap) / n_colors)
		(I.n_colors < 2000 || n_cols == 4) && (I.n_colors *= 1000)	#  Because gmtwrite uses a trick to know if cmap is Mx2 or Mx4
	else
		(I.n_colors > 2000) && (I.n_colors = div(I.n_colors, 1000))		# Revert the trick 
		#n_cols = Int(length(I.colormap) / n_colors)
	end
	return nothing
end
