"""
	gmtread(fname::String; kwargs...)

Read GMT object from file. The object is one of "grid" or "grd", "image" or "img",
"data" or "table", "cmap" or "cpt" and "ps" (for postscript).

Parameters
----------

Specify data type.  Choose among:
- **grd** : **grid** : -- Any --

    Tell the program to load a grid.
- **img** : **image** : -- Any --

    Tell the program to load an image.
- **cpt** : **cmap** : -- Any --

    Tell the program to load a GMT color palette.
- **data** : **table** : -- Any --

    Tell the program to load a dataset (a table of numbers).
- **ps** : -- Any --

    Tell the program to load a PostScript file

- **gdal** : -- Any --

    Force reading the file via GDAL. Should only be used to read grids.
- **varname** : -- String --

    When netCDF files have more than one 2D (or higher) variables use *varname* to pick the wished variable.
    e.g. varname=:slp to read the variable named 'slp'. This option defaults data type to 'grid'
- **layer** : **band** : -- Str, Number, Array --

    When files are multiband or nc files with 3D or 4D arrays, we access them via these keywords.
    layer=4 reads the fourth layer (or band) of the file. But the file can be a grid or an image. If it is a
    grid layer can be a scalar (to read 3D arrays) or an array of two elements (to read a 4D array).
    If file is an image 'layer' can be a 1 or a 1x3 array (to read a RGB image). Not that in this later case
    bands do not to be contiguous. A band=[0,5,2] composes an RGB aout of those bands. See more at
    (https://gmt.soest.hawaii.edu/doc/latest/GMT_Docs.html#modifiers-for-coards-compliant-netcdf-files)

- $(GMT.opt_R)
- $(GMT.opt_V)
- $(GMT.opt_bi)
- $(GMT.opt_f)

Example: to read a nc called 'lixo.grd'

	G = gmtread("lixo.grd", grd=true);
	
to read a jpg image with the bands reversed (this example is currently broken in GMT5. Needs GMT6dev)

    I = gmtread("image.jpg", band=[2,1,0]);
"""
function gmtread(fname::String=""; kwargs...)

	if (isempty(fname))
		error("First argument cannot be empty. It must contain the file name to read.")
	end

	d = KW(kwargs)
	cmd, opt_R = parse_R("", d)
	cmd = parse_V(cmd, d)
	cmd = parse_f(cmd, d)
	cmd, opt_bi = parse_bi(cmd, d)

	# Process these first so they may take precedence over defaults set below
	opt_T = add_opt("", "Tg", d, [:grd :grid])
	if (!isempty(opt_T))
		(haskey(d, :gdal)) && (fname = fname * "=gd")     # Force read via GDAL
	else
		opt_T = add_opt("", "Ti", d, [:img :image])
	end
	if (isempty(opt_T))
		opt_T = add_opt("", "Td", d, [:data :table])
	end
	if (isempty(opt_T))
		opt_T = add_opt("", "Tc", d, [:cpt :cmap])
	end
	if (isempty(opt_T))
		opt_T = add_opt("", "Tp", d, [:ps])
	end

	if (haskey(d, :varname))				# See if we have a nc varname / layer request
		if (isempty(opt_T))
			(haskey(d, :gdal)) && (fname = fname * "=gd")     # Force read via GDAL
			opt_T = " -Tg"
		end
		fname = fname * "?" * arg2str(d[:varname])
		for sym in [:layer :band]
			if (haskey(d, sym))
				b = d[sym]
				if (isa(b, Number))
					fname = fname * @sprintf("[%d]", b)
				elseif (isa(b, Array))		# A 4D array
					fname = fname * @sprintf("[%d,%d]", b[1], b[2])
				end
				break
			end
		end
	else									# See if we have a bands request
		for sym in [:layer :band]
			if (haskey(d, sym))
				fname = fname * "+b"
				b = d[sym]
				if (isa(b, String))
					fname = fname * b
				elseif (isa(b, Symbol))
					fname = fname * string(b)
				elseif (isa(b, Number))
					fname = fname * @sprintf("%d", b)
				elseif (isa(b, Array))
					if (length(b) == 3)
						fname = fname * @sprintf("%d,%d,%d", b[1], b[2], b[3])
					else
						error("Number of bands in the 'band' option can only be 1 or 3")
					end
				end
				if (isempty(opt_T))	opt_T = " -Ti"	end
				break
			end
		end
	end

	if (isempty(opt_T))
		error("Must select one input data type (grid, image, data, cmap or ps")
	else
		opt_T = opt_T[1:4]      				# Remove whatever was given as argument to type kwarg
	end

	if (opt_T == " -Ti" || opt_T == " -Tg")		# See if we have a mem layout request
		if (haskey(d, :layout))
			t = arg2str(d[:layout])
			if (length(t) != 3)
				error(@sprintf("Memory layout option must have 3 characters and not %s", t))
			end
			cmd = (opt_T == " -Ti") ? cmd * " -," * t : cmd * " -;" * t
		end
	end

	if (opt_T == " -Td" && !isempty(opt_bi))	# Read from binary file
		cmd = cmd * opt_bi
	end
	cmd = cmd * opt_T
	(haskey(d, :Vd)) && println(@sprintf("\tread %s %s", fname, cmd))

	O = gmt("read " * fname * cmd)
end

"""
	gmtwrite(fname::String, data; kwargs...)

Write a GMT object to file. The object is one of "grid" or "grd", "image" or "img",
"data" or "table", "cmap" or "cpt" and "ps" (for postscript).

Parameters
----------

- $(GMT.opt_R)
- $(GMT.opt_V)
- $(GMT.opt_bo)
- $(GMT.opt_f)

Example: write the GMTgrid 'G' object into a nc file called 'lixo.grd'

	gmtwrite("lixo.grd", G);
"""
function gmtwrite(fname::String="", data=[]; kwargs...)

	if (isempty(fname))
		error("First argument cannot be empty. It must contain the file name to write.")
	end

	d = KW(kwargs)
	cmd, opt_R = parse_R("", d)
	cmd = parse_V(cmd, d)

	if (isa(data, GMTgrid))
		opt_T = " -Tg"
		fname = fname * parse_grd_format(d)	# If we have format requests
		cmd = parse_f(cmd, d)
	elseif (isa(data, GMTimage))
		opt_T = " -Ti"
		fname = fname * parse_grd_format(d)	# If we have format requests
	elseif (isa(data, GMTdataset))
		opt_T = " -Td"
		cmd = parse_bo(cmd, d)				# Write to binary file
	elseif (isa(data, GMTcpt))
		opt_T = " -Tc"
	elseif (isa(data, GMTps))
		opt_T = " -Ts"
	elseif (isa(data, AbstractArray))
		data = mat2grid(data)
		opt_T = " -Tg"
	elseif (isempty_(data))
		error("Second argument must contain the data to save in file, and not be EMPTY like it is in this case.")
	end
	cmd = cmd * opt_T

	if (opt_T == " -Ti" || opt_T == " -Tg")		# See if we have a mem layout request
		if (haskey(d, :layout))
			t = arg2str(d[:layout])
			if (length(t) != 3)
				error(@sprintf("Memory layout option must have 3 characters and not %s", t))
			end
			cmd = (opt_T == " -Ti") ? cmd * " -," * t : cmd * " -;" * t
		end
	end

	(haskey(d, :Vd)) && println(@sprintf("\twrite %s %s", fname, cmd))

	gmt("write " * fname * cmd, data)
	return nothing
end

# -----------------------------------------------------------------------------------------------
function parse_grd_format(d::Dict)
# Scan options to fill any of  [=<id>][+s<scale>][+o<offset>][+n<nan>][:<driver>[/<dataType>]
# that control the grid/image output format
	out = ""
	for sym in [:fmt :format :gdal]
		if (haskey(d, sym))
			if (sym == :gdal)
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
	if (haskey(d, :scale))
		out = out * "+s" * arg2str(d[:scale])
	end
	if (haskey(d, :offset))
		out = out * "+o" * arg2str(d[:offset])
	end
	for sym in [:nan :novalue :invalid :missing]
		if (haskey(d, sym))
			out = out * "+n" * arg2str(d[sym])
			break
		end
	end
	if (haskey(d, :driver))
		out = out * arg2str(d[:driver])
		if (haskey(d, :datatype))
			out = out * "/" * arg2str(d[:datatype])
		end
	end
	return out
end