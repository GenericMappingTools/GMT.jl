"""
	gmtread(fname::String; kwargs...)

Read GMT object from file. The object is one of "grid" or "grd", "image" or "img",
"data" or "table", "cmap" or "cpt" and "ps" (for postscript), and OGR formats (shp, kml, json).
Use a type specificatin to force a certain reading path (e.g. `grd=true` to read grids) or take
the chance of letting the data type be guessed via the file extension. Known extensions are:

- Grids:      .grd .jp2 .nc
- Images:     .jpg .jp2 .png, .tif, .tiff, .bmp, .webp
- Datasets:   .dat .txt .csv .isf
- Datasets:   .arrow .arrows .shp .kml .kmz .json .gmt .feather .fgb .gpkg .geojson .gpx .gml .ipc .parquet .sqlite
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

- `inrows`: Select specific data rows to be read. Valid args include ranges or a string with an hard core GMT -q option.

- `nodata`: When reading table data via GMT (but not GDAL), this option allows user-coded missing data values
  to be translated to NaN values. By default examine all input columns after the first two. Use the +c modifier
  to override the starting column used for the examinations. e.g. `nodata=-99999+c1` to replace all -99999 values
  in second column with NaNs.

- `stride`: When reading table data via GMT (but not GDAL), this option allows subsampling the data. Provide a
  number to be used as stride for the rows. A `stride=2` will read every other row.

- `layer`| `layers` | `band` | `bands`: A string, a number or an Array. When files are multiband or nc
  files with 3D or 4D arrays, we access them via these keywords. `layer=4` reads the fourth layer (or band)
  of the file. The file can be a grid or an image. If it is a grid, layer can be a scalar (to read 3D arrays)
  or an array of two elements (to read a 4D array). Use `layers=:all` to read all layers.

  If file is an image, `layer` can be a 1 or a 1x3 array (to read a RGB image). Note that in this later case
  bands do not need to be contiguous. A `band=[1,5,2]` composes an RGB out of those bands. See more at
  $(GMTdoc)/GMT_Docs.html#modifiers-for-coards-compliant-netcdf-files) but note that we use **1 based** indexing here.

  Use ``layers=:all`` to read all levels of a 3D cube netCDF file.

- $(_opt_R)
- $(opt_V)
- $(_opt_bi)
- $(_opt_f)

Example: to read a nc called 'lixo.grd'

    G = gmtread("lixo.grd");

to read a jpg image with the bands reversed

    I = gmtread("image.jpg", band=[2,1,0]);
"""
function gmtread(_fname::String; kwargs...)

	endswith(_fname, ".xlsx") && return read_xls(_fname; kwargs...)		# Excel extension

	fname::String = _fname					# Because args signatures seam to worth shit in body.
	d = init_module(false, kwargs...)[1]	# Also checks if the user wants ONLY the HELP mode
	cmd::String, opt_R::String = parse_R(d, "")
	cmd, opt_i = parse_i(d, cmd)
	cmd, opt_h = parse_h(d, cmd)
	cmd = parse_common_opts(d, cmd, [:V_params :f])[1]
	cmd, opt_bi = parse_bi(d, cmd)
	proggy = "read "						# When reading an entire grid cube, this will change to 'grdinterpolate'

	# Process these first so they may take precedence over defaults set below
	opt_T = add_opt(d, "", "Tg", [:grd :grid])
	via_gdal = ((find_in_dict(d, [:gdal])[1]) !== nothing)
	if (via_gdal)		# Force read via GDAL
		if (opt_T != "")                                      fname *= "=gd"
		elseif ((opt_T = guess_T_from_ext(fname)) == " -Tg")  fname *= "=gd"
		end
	else
		(opt_T == "") && (opt_T = add_opt(d, "", "Ti", [:img :image]))
	end

	if (opt_T == "")  opt_T = add_opt(d, "", "Td", [:data :dataset :table])  end
	if (opt_T == "")  opt_T = add_opt(d, "", "Tc", [:cpt :cmap])  end
	if (opt_T == "")  opt_T = add_opt(d, "", "Tp", [:ps])   end
	if (opt_T == "")  opt_T = add_opt(d, "", "To", [:ogr])  end

	ogr_layer::Int32 = Int32(0)			# Used only with ogrread. Means by default read only the first layer
	if ((_varname = find_in_dict(d, [:varname])[1]) !== nothing) # See if we have a nc varname / layer request
		varname::String = string(_varname)
		(opt_T == "") && (opt_T = " -Tg")		# Though not used in if 'gdal', it still avoids going into needless tests below
		if (via_gdal || contains(varname, '/'))	# This branch is fragile
			fname = sneak_in_SUBDASETS(fname, varname)	# Get the composed name (fname + subdaset and driver)
			proggy = "gdalread"
			gdopts::String = ""
			if ((val1 = find_in_dict(d, [:layer :layers :band :bands])[1]) !== nothing)
				if (isa(val1, Real))               gdopts = string(" -b ", val1)
				elseif (isa(val1, AbstractArray))  gdopts = join([string(" -b ", val1[i]) for i in 1:numel(val1)])
				end
			end
		else
			fname *= "?" * varname
			if ((val = find_in_dict(d, [:layer :layers :band :bands])[1]) !== nothing)
				if     (isa(val, Real))           fname *= @sprintf("[%d]", val-1)
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
				endswith(fname, "=gd") && (fname = fname[1:end-3])	# Further up, we might have added "=gd" to fname.
				ds = Gdal.unsafe_read(fname)
				(Gdal.nraster(ds) < 2) &&			# Check that file is indeed a cube
					(println("\tThis file ($fname) does not contain cube data (more than one layer).
					\n\tRun 'println(gdalinfo(\"$fname\"))' for details.");
					Gdal.GDALClose(ds.ptr); return nothing)
				if (isa(val, String) || isa(val, Symbol) || isa(val, Real))
					bd_str::String = string(val)::String
					if (via_gdal)
						gdopts = ""
						if (isa(val, Real))               gdopts = string(" -b ", val)
						elseif (isa(val, AbstractArray))  gdopts = join([string(" -b ", val[i]) for i in 1:numel(val)])
						end
					end
					if (bd_str == "all")
						proggy = via_gdal ? "gdalread" : "grdinterpolate "
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
		if (startswith(fname, "@earth_day") || startswith(fname, "@earth_night"))
			opt_T = " -Ti"
		elseif ((fname[1] == '@' && any(contains.(fname, ["_relief", "_age", "_dist", "_faa", "_gebco", "_geoid", "_mag", "_mask", "_mdt", "_mss", "_synbath", "_wdmam"]))) || startswith(fname, "@srtm_"))
			opt_T = " -Tg"
		end
		# To shut up a f annoying GMT warning.
		#(opt_T == " -Tg") && startswith(fname, "@earth_") && !endswith(fname, "_g") && !endswith(fname, "_p") && (fname *= "_g")
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
		elseif (opt_T == "obj")						# Means we got a .obj file. Read it and leave
			return read_obj(fname)
		elseif (opt_T == "las")						# Means we got a .laz or .las file. Read it and leave
			o_las = lazread(fname; kwargs...)
			return getproperty(o_las, Symbol(o_las.stored))
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
		if (proggy == "read ")
			((val = find_in_dict(d, [:stride])[1]) !== nothing) && (cmd *= " -Em" * arg2str(val)::String; proggy = "gmtconvert ")
			((val = find_in_dict(d, [:q :inrows :inrow])[1]) !== nothing) && (cmd *= " -q" * arg2str(val)::String; proggy = "gmtconvert ")
			((val = find_in_dict(d, [:d :nodata])[1]) !== nothing) && (cmd *= " -di" * arg2str(val)::String; proggy = "gmtconvert ")
			cmd *= opt_T
		end

		# -----------------------  READ READ READ ------------------------
		(dbg_print_cmd(d, cmd) !== nothing) && return proggy * fname * cmd
		isISF =	(endswith(fname, ".isf") || endswith(fname, ".ISF"))
		if (isISF)
			o = gmtisf(fname; d...)
		else
			o = (proggy == "gdalread") ? gdalread(fname, gdopts) : gmt(proggy * fname * cmd)
		end
		(isempty(o)) && (@warn("\tfile \"$fname\" is empty or has no data after the header.\n"); return GMTdataset())
		((prj = planets_prj4(fname)) != "") && (o.proj4 = prj)		# Get cached (@moon_..., etc) planets proj4

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

		# This function barrier searches for Attrib(name,value[,name,value,...]) in the header lines and parses them as attributes
		function fish_attrib_in_header!(D::Vector{<:GMTdataset})
			!isempty(D[1].attrib) || !contains(D[1].header, "Attrib(") && return
			class_ids = String[]		# We may have multiple classes in the file and need to count number of occurences of each
			last_ind = 0
			for k = 1:numel(D)
				@inbounds atts = split(D[k].header, "Attrib(")[2][1:end-1]
				at2 = split(atts, ",")
				for n = 1:numel(at2)
					name, s_val = split(at2[n], "=")
					D[k].attrib[name] = string(s_val)
					if (lowercase(name) == "class")			# "class" attributes are special for assisted classification
						((ind_id = findfirst(s_val .== class_ids)) !== nothing) ? (D[k].attrib["id"] = string(ind_id)) :
						           (D[k].attrib["id"] = "$(last_ind+=1)"; append!(class_ids,  [s_val]))
					end
				end
			end
			return nothing
		end

		isa(o, Vector{<:GMTdataset}) && fish_attrib_in_header!(o)

		# Try guess if ascii file has time columns and if yes leave trace of it in GMTdadaset metadata.
		(opt_bi == "" && !isISF && isa(o, GDtype)) && file_has_time!(fname, o, corder, opt_h)

		# Function barrier to check if we should assign a default CPT to this grid and set the 'hasnans' field
		function check_set_default_cpt!(G::GMTgrid, fname::String)
			G.hasnans = any(!isfinite, G.z) ? 2 : 1
			((fname[1] == '@') && (cptname = check_remote_cpt(fname)) != "") && (G.cpt = cptname)
			return nothing
		end
		isa(o, GMTgrid) && check_set_default_cpt!(o, fname)

		return o
	end

	(dbg_print_cmd(d, cmd) !== nothing) && return "ogrread " * fname * " " * cmd
	# Because of the certificates shits on Windows. But for some reason the set in gmtlib_check_url_name() is not visible
	(Sys.iswindows()) && run(`cmd /c set GDAL_HTTP_UNSAFESSL=YES`)
	API2 = GMT_Create_Session("GMT", 2, GMT_SESSION_NOEXIT + GMT_SESSION_EXTERNAL + GMT_SESSION_NOGDALCLOSE + GMT_SESSION_COLMAJOR);

	drop_islands = (find_in_dict(d, [:no_islands :no_holes])[1] !== nothing) ? true : false
	x = (opt_R == "") ? [0.0, 0, 0, 0] : opt_R2num(opt_R)		# See if we have a limits request
	lims = tuple(vcat(x,[0.0, 0.0])...)
	GC.@preserve fname begin
		ctrl = OGRREAD_CTRL(Int32(0), ogr_layer, pointer(fname), lims)
		O = ogr2GMTdataset(gmt_ogrread(API2, Ref(ctrl)), drop_islands)
	end

	ressurectGDAL()				# Because GMT called GDALDestroyDriverManager()
	GMT_Destroy_Session(API2)
	return O
end

# ---------------------------------------------------------------------------------
function planets_prj4(fname)
	# If fname refers to a (cached) planet other than Earth, return the proj4 string for it.
	((ind = findfirst(startswith.(fname, ["@moon", "@mars", "@merc", "@venu", "@plut"]))) === nothing) && return ""
	rs = ["+R=1737400", "+R=3396190", "+R=2439400", "+R=6051800", "+R=1188300"]
	return string("+proj=longlat ", rs[ind], " +no_defs")
end

# ---------------------------------------------------------------------------------
function sneak_in_SUBDASETS(fname, varname)::String
	# Create a new filename with the SUBDATASET_ name. Need this when GDAL is reading per SUBDASET and not whole file
	# 'fname' is the file name and 'varname' the name of the subdataset.
	endswith(fname, "=gd") && (fname = fname[1:end-3])		# A previous check may have added the "=gd". If yes, remove it.
	gdinfo = gdalinfo(fname)
	((ind1 = findfirst("SUBDATASET_", gdinfo)) === nothing) && error("The $varname SUBDATASET does not exist in $fname")
	tmp_s  = gdinfo[ind1[end]:ind1[end]+20]		# 20 should be enough to include the format name. e.g. "HDF"
	ind2   = findfirst("=", tmp_s)				# For example, tmp_s = "_1_NAME=NETCDF:\"woa18"
	ind3   = findfirst(":", tmp_s)
	fmt    = tmp_s[ind2[1]+1:ind3[1]]			# e.g. fmt = "NETCDF:"
	_fname::String = fmt * fname * ":" * string(varname)
	return _fname
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
	if ((ind = findfirst("[", fname)) !== nothing)	# 'fname' may have a ending layer number in the form [n]
		fname = fname[1:ind[1]-1]
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
	function inside_worker(D, corder)
		isempty(D.comment) && return nothing
		ncs = size(D,2)			# Next line checks if the comment is comma separated
		for k = numel(D.comment):-1:1		# We may have many empty entries in the 'comment' field.
			hfs = (count(i->(i == ','), D.comment[k]) >= ncs-1) ? strip.(split(D.comment[k], ',')) : split(D.comment[k])
			!isempty(hfs) && break
		end
		(length(hfs) < ncs) && return	# Junk in comments does not let guessing column names.
		col_text = (!isempty(D.text) && length(hfs) > ncs) ? hfs[ncs+1] : ""
		(!isempty(corder)) && (hfs = hfs[corder])
		D.colnames = (length(hfs) > ncs) ? string.(hfs)[1:ncs] : string.(hfs)
		(col_text != "") && (append!(D.colnames, [col_text]))
	end

	(isa(o, GMTdataset)) ? inside_worker(o, corder) : inside_worker(o[1], corder)
	return nothing
end

# ---------------------------------------------------------------------------------
function file_has_time!(fname::String, D::GDtype, corder::Vector{Int}=Int[], opt_h::String="")
	# Try guess if 'fname' file has time columns and if yes leave trace of it in D's metadata.
	# We do that by scanning the first valid line in file.
	# 'corder' is a vector of ints filled with column orders specified by -i. If no -i that it is empty

	startswith(fname, "http") && return nothing			# We can't "open(fname)" beloow
	
	# When col n has date and col n+1 has time, change the col date to a date-time column
	function join_date_time_cols!(D::GMTdataset, n)
		nada = zero(eltype(D))
		@inbounds for k = 1:size(D,1)
			D[k,n-1] += D[k,n] * 3600.0		# Multiply only by 60*60 because GMT 'thinks' hh:mm:ss is an angle and not a time
			D[k,n] = nada
		end
		return nothing
	end
	function join_date_time_cols!(D::Vector{<:GMTdataset}, n)
		for i = 1:numel(D)  join_date_time_cols!(D[i], n)  end 
	end

	#line1 = split(collect(Iterators.take(eachline(fname), 1))[1])	# Read first line and cut it in tokens
	isone = isa(D, GMTdataset) ? true : false
	if (isone && isempty(D.colnames)) || (!isone && isempty(D[1].colnames))		# If no colnames set yet
		names_str = (isone) ? ["col.$i" for i=1:size(D,2)] : ["col.$i" for i=1:size(D[1],2)]
		isone ? (D.colnames = names_str) : [D[k].colnames = names_str for k = 1:lastindex(D)]	# Default col names
	end
	n_cols = (isone) ? size(D,2) : size(D[1],2)
	Tc, f1, n_it = "", 1, 0
	(fname[1] == '@') && (gmt("gmtwhich -Gc $fname"); fname = joinpath(GMTuserdir[1], "cache", fname[2:end]))
	fid = open(fname)
	iter = eachline(fid)
	try
		n_hdr = (opt_h != "") ? parse(Int, opt_h[4:end]) : 0		# Number of declared header lines via -h option
		for it in iter
			(n_it < n_hdr) && (n_it += 1; continue)
			(n_it > (30 + n_hdr) || Tc != "") && break				# Means that previous iteration found it.
			n_commas = count_chars(it)
			use_commas = (n_cols > 1) && (n_commas >= n_cols-1)		# To see if we split on spaces or on commas.
			line1 = (use_commas) ? split(it, ',') : split(it)
			n_it += 1			# Counter to not let this go on infinetely
			(isempty(line1) || contains(">#!%;", line1[1][1])) && continue
			loop_inds = isempty(corder) ? (1:n_cols) : corder
			(length(line1) < length(loop_inds)) && continue			# Sometimes CSV files ends with a colon, and that adds a col to lines
			for k in loop_inds
				# Time cols may come in forms like [-]yyyy-mm-dd[T| [hh:mm:ss.sss]], so to find them we seek for
				# '-' chars in the middle of strings that we KNOW have been converted to numbers.
				if ((i = findlast("-", line1[k])) !== nothing && i[1] > 1 && lowercase(line1[k][i[1]-1]) != 'e')
					Ts = (f1 == 1) ? "Time" : "Time$(f1)";		f1 += 1
					ind_t = (!isempty(corder)) ? findfirst(k .== corder) : k	# When -i was used 'corder' has new col order
					Tc = (Tc == "") ? "$ind_t" : Tc * ",$ind_t"			# Accept more than one time columns
					(isone) ? (D.colnames[ind_t] = Ts) : (D[1].colnames[ind_t] = Ts)
					if (Tc != "" && k < loop_inds[end] && length(findall(":", line1[k+1])) == 2)
						join_date_time_cols!(D, k+1)	# To solve the TWO strings, 'yyyy-mm-dd hh:mm:ss.sss' to mean a single time.
					end
				end
			end
			(Tc != "") && ((isone) ? (D.attrib["Timecol"] = Tc) : (D[1].attrib["Timecol"] = Tc))
		end
	catch err
		isone ? (D.colnames = String[]) : [D[k].colnames = String[] for k = 1:lastindex(D)]
		@warn("Failed to parse file '$fname' for file_has_time!(). Error was:\n $err")
	end
	close(fid)
	isone ? (length(D.colnames) < n_cols && (D.colnames = String[])) : (length(D[1].colnames) < n_cols && (D[1].colnames = String[]))
	!isone && !isempty(D[1].attrib) && [D[k].attrib = D[1].attrib for k = 2:lastindex(D)]	# All segs must have same attrib (?)
	return nothing
end
	
# ---------------------------------------------------------------------------------
function guess_T_from_ext(fname::String; write::Bool=false, text_only::Bool=false)::String
	# Guess the -T option from a couple of known extensions
	fn, ext = splitext(fname)
	contains(ext, "+") && return " -Tg"		# Only grids are allowed to have +s+o+n,...
	ext = lowercase(ext[2:end])
	(ext == "obj") && return "obj"	# To be read by read_obj() internal function.
	(ext == "laz" || ext == "las") && return "las"	# To be read by lazwrite()
	if (ext == "zip")				# Accept ogr zipped files, e.g., *.shp.zip
		((out = guess_T_from_ext(fn)) == " -To") && return " -Toz"
		((info = gdalinfo("/vsizip/"*fname)) != "") && return " -Toz"	# A bit risky but allows reading zipped ogr files
	end

	_kml = (!write || !text_only) ? "kml" : "*"		# When it's text_only, we are writting an output gmt2kml

	(length(ext) > 8 || occursin("?", ext)) && return (occursin("?", ext)) ? " -Tg" : "" # A SUBDATASET encoded fname?
	(!write && (ext == "jp2" || ext == "tif" || ext == "tiff") && (!isfile(fname) && !startswith(fname, "/vsi") &&
		!occursin("https:", fname) && !occursin("http:", fname) && !occursin("ftps:", fname) && !occursin("ftp:", fname))) &&
		error("File $fname does not exist.")
	if     (findfirst(isequal(ext), ["grd", "nc", "nc=gd"])  !== nothing)  out = " -Tg";
	elseif (findfirst(isequal(ext), ["dat", "txt", "csv", "isf"])   !== nothing)  out = " -Td";
	elseif (findfirst(isequal(ext), ["jpg", "jpeg", "png", "bmp", "webp"]) 	!== nothing)  out = " -Ti";
	elseif (findfirst(isequal(ext), ["arrow", "arrows", "shp", _kml, "kmz", "json", "feather", "fgb", "geojson", "gmt", "gpkg", "gpx", "gml", "ipc", "parquet", "sqlite"]) !== nothing)  out = " -To";
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

- `binary`: Applyes only when saving a `stl` file. By default it is true. Use `binary=false` to save in ascii.

- `id`:  [Type => Str] 

    Use an ``id`` code when not not saving a grid into a standard COARDS-compliant netCDF grid. This ``id``
    is made up of two characters like ``ef`` to save in ESRI Arc/Info ASCII Grid Interchange format (ASCII float).
    See the full list of ids at $(GMTdoc)grdconvert.html#format-identifier.

    ($(GMTdoc)grdconvert.html#g)
- `scale` | `offset`: [Type => Number]

    You may optionally ask to scale the data and then offset them with the specified amounts.
    These modifiers are particularly practical when storing the data as integers, by first removing an offset
    and then scaling down the values. The `scale` factor can also be applied when saving to stl (scales the z values).

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
- $(_opt_R)
- $(opt_V)
- $(opt_bo)
- $(_opt_f)

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
	_, opt_f = parse_f(d, "")

	if (isa(data, GMTgrid))
		(endswith(fname, ".laz") || endswith(fname, ".LAZ")) && return lazwrite(fname, data; kwargs...)		# Lasz

		# GMT doesn't write correct CF nc grids that are referenced but non-geographic. So, use GDAL in those cases
		fmt = parse_grd_format(d)				# See if we have format requests
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
		isa(data, Vector) && (endswith(fname, ".stl") || endswith(fname, ".STL")) && return write_stl(fname, data; kwargs...)	# STL
		(endswith(fname, ".laz") || endswith(fname, ".LAZ")) && return lazwrite(fname, data; kwargs...)		# Lasz
		opt_T = " -Td"
		cmd, = parse_bo(d, cmd)					# Write to binary file
		cmd = isa(data, GMTdataset) ? set_fT(data, cmd, opt_f) : set_fT(data[1], cmd, opt_f)
	elseif (isa(data, GMTfv))
		(endswith(fname, ".obj") || endswith(fname, ".OBJ")) && return write_obj(fname, data)
		(endswith(fname, ".stl") || endswith(fname, ".STL")) && return write_stl(fname, data; kwargs...)
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
		(endswith(fname, ".laz") || endswith(fname, ".LAZ")) && return dat2las(fname, data; kwargs...)		# Lasz
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
	text_only = isa(data, GMTdataset) && isempty(data.data)
	if (guess_T_from_ext(fname, write=true, text_only=text_only) == " -To")
		gdalwrite(fname, data)		# Write OGR data
	else
		(isa(data, GItype) && startswith(data.layout, "TRB") && ndims(data) == 2) && (data.layout = "TRPa")	# Just a patch. NEED full fix
		gmt("write " * fname * cmd, data)
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
	(n_colors >= 2000) && (n_colors = Int(floor(n_colors / 1000)))
	if (toGMT)
		n_cols = Int(length(I.colormap) / n_colors)
		(I.n_colors < 2000 || n_cols == 4) && (I.n_colors *= 1000)	#  Because gmtwrite uses a trick to know if cmap is Mx2 or Mx4
	else
		(I.n_colors >= 2000) && (I.n_colors = div(I.n_colors, 1000))		# Revert the trick 
	end
	return nothing
end

#=
function ncd_read_ghrsst(; year::Int=0, month=nothing, day=nothing, doy=nothing, lon=nothing, lat=nothing)

	(doy === nothing && (month === nothing || day === nothing)) && error("Must specify at least the 'doy', OR 'month and day'")
	_year = (year == 0) ? Dates.year(now())-1 : year     # -1 because current year is not complete
	the_date = ""
	(doy !== nothing) && (the_date = replace(string(doy2date(doy, _year)), "-" => ""))
	(doy === nothing) && (the_date = @sprintf("%d%02d%02d", _year, month, day))
	#the_day = (day !== nothing) ? @sprintf("%03d", day) : @sprintf("%03d", Dates.month(doy2date(doy, _year)))
	the_doy = (doy !== nothing) ? @sprintf("%03d", doy) : @sprintf("%03d", Dates.day(doy2date(doy, _year)))

	#url = string("https://www.ncei.noaa.gov/thredds-ocean/dodsC/ghrsst/L4/GLOB/JPL/MUR/", _year, '/', the_doy, '/', the_date,"090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc")
	url = "https://www.ncei.noaa.gov/thredds-ocean/dodsC/ghrsst/L4/GLOB/JPL/MUR/2023/060/20230301090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc"

	#url = "https://opendap.earthdata.nasa.gov/providers/POCLOUD/collections/GHRSST%20Level%204%20MUR%20Global%20Foundation%20Sea%20Surface%20Temperature%20Analysis%20(v4.1)/granules/" * the_date * "090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1"

	ds = NCDataset(url)
	lonr, latr = lon, lat
	ds_subset = NCDatasets.@select(ds["analysed_sst"], $lonr[1] <= lon <= $lonr[2] && $latr[1] <= lat <= $latr[2])

	ncvar = ds_subset["analysed_sst"]
	lon = ds_subset["lon"][:]
	lat = ds_subset["lat"][:]
	time = ds_subset["time"][1]
	SST = ncvar[:,:,1]

	return SST, lon, lat
end
=#


# --------------------------------------------------------------------------------------------------------
"""
    VF = read_obj(fname)::GMTfv

Read a Wavefront .obj file and return the result in a FaceVertices object.
"""
function read_obj(fname)
	# This functions became convoluted because we want to be able to read .obj files that may have
	# a different number of vertices per face. For example we may have a sphere made of quadrangles
	# and triangles to close the poles. We deal with these cases by storing the faces matices in a
	# vector that will have as many elements as there are different geometries. This way we workaround
	# the limitation that matrices must have the same number of columns, but we add complexity.
	count_v, count_f, vr, fr = 0, 0, 0, 0
	first, has_slash = true, false
	n_vert_vec = Int[]		# Vector to store the number of vertices per each face

	# Do a first round to find out how many vertices and faces there are as well as if indices are simple or with slashes
	fid = open(fname)
	iter = eachline(fid)
	for it in iter
		isempty(it) && continue
		if (it[1] == 'v' && it[2] == ' ') count_v += 1
		elseif (it[1] == 'f')
			first && (has_slash = contains(it, '/'); first = false)
			push!(n_vert_vec, length(split(it))-1)		# Store the number of vertices of this face
			count_f += 1
		end
	end
	close(fid)		# Don't know how to rewind 'iter', so close file and open it again.

	u = sort(unique(n_vert_vec))		# Number of faces geometries (tri, quad, etc) in growing order of vertices number
	n_geoms = length(u)
	off = minimum(n_vert_vec) - 1
	n_vert_vec .-= off					# Shift indices so they start at one and we can easily compute a histogram
	hst = zeros(Int, n_geoms)
	@inbounds for k = 1:numel(n_vert_vec)  hst[n_vert_vec[k]] += 1  end		# Micro histogram
	n_vert_vec .+= off
	F = Vector{Matrix{Int}}(undef, n_geoms)
	for k = 1:n_geoms
		F[k] = fill(0, hst[k], n_vert_vec[findfirst(n_vert_vec .== u[k])])	# Initialize each matrix of faces (onre for each geometry type)
	end

	ind_F = ones(Int, count_f)			# Indices of faces
	for k = 2:n_geoms
		ind_F[n_vert_vec .== u[k]] .= k	# For each face, we store the index of the corresponding geometry. That is we know which geometry it belongs to
	end
	count_F_rows = zeros(Int, n_geoms)

	V = Matrix{Float64}(undef, count_v, 3)
	fid = open(fname)
	iter = eachline(fid)
	for it in iter
		isempty(it) && continue
		line = split(it)
		if (line[1] == "v")
			vr += 1
			V[vr, 1], V[vr, 2], V[vr, 3] = parse(Float64, line[2]), parse(Float64, line[3]), parse(Float64, line[4])
		elseif (line[1] == "f")
			fr += 1
			i_t = ind_F[fr]
			count_F_rows[i_t] += 1		# 
			if (has_slash)				# Vertex with texture/normals coordinate indices
				for k = 1:n_vert_vec[fr]
					spli = split(line[k+1], "/")
					F[i_t][count_F_rows[i_t], k] = parse(Int, spli[1])
				end
			else						# simple vertex indices
				for k = 1:n_vert_vec[fr]
					F[i_t][count_F_rows[i_t], k] = parse(Int, line[k+1])
				end
			end
		end
	end
	close(fid)
	fv2fv(F, V)
end

# --------------------------------------------------------------------------------------------------------
"""
    write_obj(fname, FV::GMTfv)

Write a OBJ file. 
"""
function write_obj(fname::AbstractString, FV::GMTfv)
	fid = open(fname, write=true)

	for k = 1:size(FV.verts, 1)
		@printf(fid, "v %.12g %.12g %.12g\n", FV.verts[k,1], FV.verts[k,2], FV.verts[k,3])
	end
	for n = 1:numel(FV.faces)				# Number of face groups
		for m = 1:size(FV.faces[n], 1)		# Number of rows in this group
			println(fid, "f ", join(convert.(Int, FV.faces[n][m,:]), " "))
		end
	end
	close(fid)
end

# --------------------------------------------------------------------------------------------------------
"""
    write_stl(fname, D::Vector{<:GMTdataset}; binary=true, scale=1.0)

Write a STL file. 
"""
# Inspired in MeshIO stl.jl
function write_stl(fname::AbstractString, D::Vector{<:GMTdataset}; binary::Bool=true, scale=1.0)
	name = fileparts(fname)[2]
	fid = open(fname, write=true)

	if (binary)
		foreach(k -> write(fid, 0x00), 1:80)	# header (empty)
		write(fid, UInt32(length(D)))			# number of triangles
    	for k = 1:length(D)
			n = facenorm(D[k].data)
			foreach(j-> write(fid, Float32(n[j])), 1:3)
			for t = 1:3
				write(fid, Float32(D[k][t,1]), Float32(D[k][t,2]), Float32(D[k][t,3]*scale))
			end
			write(fid, 0x0000)		# write 16bit empty byte count
		end
	else
    	write(fid, "solid $name\n")
		for k = 1:length(D)
			n = facenorm(D[k].data)
			@printf fid "facet normal %.12g %.12g %.12g\n" n[1] n[2] n[3]
			write(fid,"\touter loop\n")
			@printf fid "\t\tvertex  %.12g %.12g %.12g\n" D[k][1,1] D[k][1,2] D[k][1,3]*scale
			@printf fid "\t\tvertex  %.12g %.12g %.12g\n" D[k][2,1] D[k][2,2] D[k][2,3]*scale
			@printf fid "\t\tvertex  %.12g %.12g %.12g\n" D[k][3,1] D[k][3,2] D[k][3,3]*scale
			write(fid,"\tendloop\n")
			write(fid,"endfacet\n")
		end
		write(fid,"endsolid $name\n")
	end
	close(fid)
end

function write_stl(fname::AbstractString, FV::GMTfv; binary::Bool=true, scale=1.0)
	@assert size(FV.faces[1],2) == 3 "Only triangulated bodies can be saved in STL format."
	name = fileparts(fname)[2]
	fid = open(fname, write=true)

	function hlp(FV, t, k, m)
		t[1,:] .= FV.verts[FV.faces[k][m,1],:]
		t[2,:] .= FV.verts[FV.faces[k][m,2],:]
		t[3,:] .= FV.verts[FV.faces[k][m,3],:]
		return t, facenorm(t)
	end

	t = zeros(3,3)
	if (binary)
		foreach(k -> write(fid, 0x00), 1:80)	# header (empty)
		write(fid, UInt32(sum(size.(FV.faces,1))))	# number of triangles
		for k = 1:numel(FV.faces)				# Number of face groups
			for m = 1:size(FV.faces[k], 1)		# Number of rows in this group
				t, n = hlp(FV, t, k, m)
				foreach(j-> write(fid, Float32(n[j])), 1:3)
				for c = 1:3
					write(fid, Float32(t[c,1]), Float32(t[c,2]), Float32(t[c,3]*scale))
				end
				write(fid, 0x0000)				# write 16bit empty byte count
			end
		end
	else
    	write(fid, "solid $name\n")
		for k = 1:numel(FV.faces)				# Number of face groups
			for m = 1:size(FV.faces[k], 1)		# Number of rows in this group
				t, n = hlp(FV, t, k, m)
				@printf(fid, "facet normal %.12g %.12g %.12g\n", n[1], n[2], n[3])
				write(fid,"\touter loop\n")
				@printf fid "\t\tvertex  %.12g %.12g %.12g\n" t[1,1] t[1,2] t[1,3]*scale
				@printf fid "\t\tvertex  %.12g %.12g %.12g\n" t[2,1] t[2,2] t[2,3]*scale
				@printf fid "\t\tvertex  %.12g %.12g %.12g\n" t[3,1] t[3,2] t[3,3]*scale
				write(fid,"\tendloop\nendfacet\n")
			end
		end
		write(fid,"endsolid $name\n")
	end
	close(fid)
end
