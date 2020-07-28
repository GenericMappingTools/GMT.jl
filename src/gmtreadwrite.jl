"""
	gmtread(fname::String, data; kwargs...)

Read GMT object from file. The object is one of "grid" or "grd", "image" or "img",
"data" or "table", "cmap" or "cpt" and "ps" (for postscript), and OGR formats (shp, kml, json).
Use a type specificatin to force a certain reading path (e.g. grd=true to read grids) or take
the chance of letting the data type be guessed via the file extension. Known extensions are:
Grids:      .grd
Images:     .jpg, .png, .tif, .bmp
Datasets:   .dat, .txt, .csv
Datasets:   .shp, .kml, .json
CPT:        .cpt
PostScript: .ps, .eps

Parameters
----------

Specify data type.  Choose among:
- **grd** | **grid** :: [Type => Any]

    Load a grid.
- **img** | **image** :: [Type => Any]

    Load an image.
- **cpt** | **cmap** :: [Type => Any]

    Load a GMT color palette.
- **data** | **dataset** | **table** :: [Type => Any]

    Load a dataset (a table of numbers).
- **ogr** :: [Type => Any]

    Load a dataset via GDAL OGR (a table of numbers). Many things can happen here.
- **ps** :: [Type => Any]

    Load a PostScript file
- **gdal** :: [Type => Any]

    Force reading the file via GDAL. Should only be used to read grids.
- **varname** :: [Type => Str]

    When netCDF files have more than one 2D (or higher) variables use *varname* to pick the wished variable.
    e.g. varname=:slp to read the variable named 'slp'. This option defaults data type to 'grid'
- **layer** | **band** :: [Type => Str, Number, Array]

    When files are multiband or nc files with 3D or 4D arrays, we access them via these keywords.
    layer=4 reads the fourth layer (or band) of the file. But the file can be a grid or an image. If it is a
    grid layer can be a scalar (to read 3D arrays) or an array of two elements (to read a 4D array).
    If file is an image 'layer' can be a 1 or a 1x3 array (to read a RGB image). Not that in this later case
    bands do not need to be contiguous. A band=[0,5,2] composes an RGB out of those bands. See more at
    $(GMTdoc)/GMT_Docs.html#modifiers-for-coards-compliant-netcdf-files)

- $(GMT.opt_R)
- $(GMT.opt_V)
- $(GMT.opt_bi)
- $(GMT.opt_f)

Example: to read a nc called 'lixo.grd'

    G = gmtread("lixo.grd");

to read a jpg image with the bands reversed (this example is currently broken in GMT5. Needs GMT6dev)

    I = gmtread("image.jpg", band=[2,1,0]);
"""
function gmtread(fname::String; kwargs...)

	d = KW(kwargs)
	cmd, = parse_common_opts(d, "", [:R :V_params :f :i :h])
	cmd, opt_bi = parse_bi(cmd, d)

	# Process these first so they may take precedence over defaults set below
	opt_T = add_opt("", "Tg", d, [:grd :grid])
	if (opt_T != "")		# Force read via GDAL
		if ((val = find_in_dict(d, [:gdal])[1]) !== nothing)  fname = fname * "=gd"  end
	else
		opt_T = add_opt("", "Ti", d, [:img :image])
	end
	if (opt_T == "")  opt_T = add_opt("", "Td", d, [:data :dataset :table])  end
	if (opt_T == "")  opt_T = add_opt("", "Tc", d, [:cpt :cmap])  end
	if (opt_T == "")  opt_T = add_opt("", "Tp", d, [:ps])   end
	if (opt_T == "")  opt_T = add_opt("", "To", d, [:ogr])  end

	if ((varname = find_in_dict(d, [:varname])[1]) !== nothing) # See if we have a nc varname / layer request
		if (isempty(opt_T))			# Force read via GDAL
			if ((val = find_in_dict(d, [:gdal])[1]) !== nothing)  fname = fname * "=gd"  end
			opt_T = " -Tg"
		end
		fname = fname * "?" * arg2str(varname)
		if ((val = find_in_dict(d, [:layer :band])[1]) !== nothing)
			if (isa(val, Number))     fname *= @sprintf("[%d]", val)
			elseif (isa(val, Array))  fname *= @sprintf("[%d,%d]", val[1], val[2])	# A 4D array
			end
		end
	else									# See if we have a bands request
		if ((val = find_in_dict(d, [:layer :band])[1]) !== nothing)
			fname = fname * "+b"
			if (isa(val, String) || isa(val, Symbol) || isa(val, Number))
				fname = string(fname, val)
			elseif (isa(val, Array) || isa(val, Tuple))
				if (length(val) == 3)
					fname = fname * @sprintf("%d,%d,%d", val[1], val[2], val[3])
				else
					error("Number of bands in the 'band' option can only be 1 or 3")
				end
			end
			if (isempty(opt_T))	opt_T = " -Ti"	end
		end
	end

	if (opt_T == "")
		if ((opt_T = guess_T_from_ext(fname)) === nothing)		# Try some guesses
			error("Must select one input data type (grid, image, dataset, cmap or ps)")
		end
		if (opt_T == " -Tg" && haskey(d, :ignore_grd))  return nothing  end 	# contourf uses this
	else
		opt_T = opt_T[1:4]      				# Remove whatever was given as argument to type kwarg
	end

	if (opt_T == " -Ti" || opt_T == " -Tg")		# See if we have a mem layout request
		if ((val = find_in_dict(d, [:layout])[1]) !== nothing)
			cmd = (opt_T == " -Ti") ? cmd * " -%" * arg2str(val) : cmd * " -&" * arg2str(val)
		end
	end

	if (opt_T != " -To")			# All others but OGR
		if (opt_T == " -Td" && !isempty(opt_bi))  cmd *= opt_bi  end		# Read from binary file
		cmd *= opt_T
		if (dbg_print_cmd(d, cmd) !== nothing)  return "gmtread " * cmd  end
		O = gmt("read " * fname * cmd)
	else
		opt_R = parse_R("", d)[1]
		if (dbg_print_cmd(d, cmd) !== nothing)  return "ogrread " * cmd  end
		# Because of the certificates shits on Windows. But for some reason the set in gmtlib_check_url_name() is not visible
		if (Sys.iswindows())  run(`cmd /c set GDAL_HTTP_UNSAFESSL=YES`)  end
		API2 = GMT_Create_Session("GMT", 2, GMT_SESSION_NOEXIT + GMT_SESSION_EXTERNAL + GMT_SESSION_COLMAJOR);
		if (GMTver >= 6.1)
			x = opt_R2num(opt_R)		# See if we have a limits request
			lims = (x === nothing) ? C_NULL : x
			O = ogr2GMTdataset(gmt_ogrread(API2, fname, lims))
		else
			O = ogr2GMTdataset(gmt_ogrread(API2, fname))
		end
	end
end

# ---------------------------------------------------------------------------------
function guess_T_from_ext(fname::String)
	# Guess the -T option from a couple of known extensions
	fname, ext = splitext(fname)
	if (length(ext) >= 5)			# A SUBDATASET encoded fname?
		if (occursin("?", ext))  return " -Tg"
		else                     return nothing
		end
	end
	ext = lowercase(ext[2:end])
	if     (findfirst(isequal(ext), ["grd", "nc", "nc=gd"])  !== nothing)  out = " -Tg";
	elseif (findfirst(isequal(ext), ["dat", "txt", "csv"])   !== nothing)  out = " -Td";
	elseif (findfirst(isequal(ext), ["jpg", "png", "tif", "tiff", "bmp"]) 	!== nothing)  out = " -Ti";
	elseif (findfirst(isequal(ext), ["shp", "kml", "json", "geojson", "gmt"])  !== nothing)  out = " -To";
	elseif (ext == "cpt")  out = " -Tc";
	elseif (ext == "ps" || ext == "eps")  out = " -Tp";
	else
		out = nothing
	end
end

"""
	gmtwrite(fname::String, data; kwargs...)

Write a GMT object to file. The object is one of "grid" or "grd", "image" or "img",
"dataset" or "table", "cmap" or "cpt" and "ps" (for postscript).

When saving grids we have a large panoply of formats at our disposal.

Parameters
----------

- **id** ::  [Type => Str] 

    Use an ``id`` code when not not saving a grid into a standard COARDS-compliant netCDF grid. This ``id``
    is made up of two characters like ``ef`` to save in ESRI Arc/Info ASCII Grid Interchange format (ASCII float).
    See the full list of ids at $(GMTdoc)grdconvert.html#format-identifier.

    ($(GMTdoc)grdconvert.html#g)
- **scale** | **offset** :: [Type => Number]

    You may optionally ask to scale the data and then offset them with the specified amounts.
    These modifiers are particularly practical when storing the data as integers, by first removing an offset
    and then scaling down the values.
- **nan** | **novalue** | **invalid** | **missing** :: [Type => Number]

    Lets you supply a value that represents an invalid grid entry, i.e., ‘Not-a-Number’.
- **gdal** :: [Type => Bool]

    Force the use of the GDAL library to write the grid (to be used only with grids).
    ($(GMTdoc)GMT_Docs.html#grid-file-format-specifications)
- **driver** :: [Type => Str]

    When saving in other than the netCDF format we must tell the GDAL library what is wished format.
    That is done by specifying the driver name used by GDAL itself (e.g., netCDF, GTiFF, etc...).
- **datatype** :: [Type => Str] 		``Arg = u8|u16|i16|u32|i32|float32``

    When saving with GDAL we can specify the data type from u8|u16|i16|u32|i32|float32 where ‘i’ and ‘u’ denote
    signed and unsigned integers respectively.
- $(GMT.opt_R)
- $(GMT.opt_V)
- $(GMT.opt_bo)
- $(GMT.opt_f)

Example: write the GMTgrid 'G' object into a nc file called 'lixo.grd'

	gmtwrite("lixo.grd", G);
"""
function gmtwrite(fname::String, data; kwargs...)

	if (fname == "")
		error("First argument cannot be empty. It must contain the file name to write.")
	end

	d = KW(kwargs)
	cmd, opt_R = parse_R("", d)
	cmd = parse_V_params(cmd, d)

	if (isa(data, GMTgrid))
		opt_T = " -Tg"
		fname = fname * parse_grd_format(d)		# If we have format requests
		cmd, = parse_f(cmd, d)
	elseif (isa(data, GMTimage))
		opt_T = " -Ti"
		fname *= parse_grd_format(d)			# If we have format requests
	elseif (isa(data, GMTdataset))
		opt_T = " -Td"
		cmd, = parse_bo(cmd, d)					# Write to binary file
	elseif (isa(data, GMTcpt))
		opt_T = " -Tc"
	elseif (isa(data, GMTps))
		opt_T = " -Tp"
	elseif (isa(data, Array{UInt8}))
		fmt = parse_grd_format(d)				# See if we have format requests
		if (fmt == "")							# If no format, write a dataset
			opt_T = " -Td"
			cmd, = parse_bo(cmd, d)				# Write to binary file
		else
			data = mat2img(data)
			fname *= fmt
			opt_T = " -Ti"
		end
	elseif (isa(data, AbstractArray))
		fmt = parse_grd_format(d)				# See if we have format requests
		if (fmt == "")							# If no format, write a dataset
			opt_T = " -Td"
			cmd, = parse_bo(cmd, d)				# Write to binary file
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
		if ((val = find_in_dict(d, [:layout])[1]) !== nothing)
			cmd = (opt_T == " -Ti") ? cmd * " -%" * arg2str(val) : cmd * " -&" * arg2str(val)
		end
	end

	if (dbg_print_cmd(d, cmd) !== nothing)  return "gmtwrite " * fname * cmd  end

	gmt("write " * fname * cmd, data)
	return nothing
end

# -----------------------------------------------------------------------------------------------
function parse_grd_format(d::Dict)
# Scan options to fill any of  [=<id>][+s<scale>][+o<offset>][+n<nan>][:<driver>[/<dataType>]
# that control the grid/image output format
	out = ""
	for sym in [:id :gdal :driver]
		if (haskey(d, sym))
			if (sym == :gdal || sym == :driver)
				out = "=gd"
			else
				t = arg2str(d[sym])
				if (length(t) != 2)
					error(@sprintf("Format code MUST have 2 characters and not %s", t))
				end
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
		if ((val = find_in_dict(d, [:datatype])[1]) !== nothing)
			out *= "/" * arg2str(val)
		end
	end
	del_from_dict(d, [:id :gdal])
	return out
end