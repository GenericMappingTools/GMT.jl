Base.@kwdef struct lasout_types
	stored::String = ""
	grd::GMTgrid = GMTgrid()
	ds::GMTdataset = GMTdataset()
	dsv::Vector{GMTdataset} = [GMTdataset()]
	function lasout_types(stored, grd, ds, dsv)
		stored = !isempty(grd) ? "grd" : (!isempty(ds) ? "ds" : (!isempty(dsv) ? "dsv" : ""))
		new(stored, grd, ds, dsv)
	end
end

"""
    argsout = lazread(FileName::AbstractString; out::String="xyz", type::DataType=Float64, class=0, startstop="1:end")

Read data from a LIDAR laz (laszip compressed) or las format file.

- `FileName`: Name of the input LIDAR file.

### Keyword Arguments

- `out`: Select what data to output. The default is "xyz" meaning that only these three are sent out.
   Examples include: "xyz", "xy", "yx", "z", "xyzi", "xyzt", "xyzit", "xyzti", "xyzic" "xyzc", "RGB", "RGBI"
   where 'i' stands for intensity (UInt16), 'c' for classification (Int8) and 't' for GPS time (Float64)

- `type`: The float components (xyz) may be required in Float32. The default is Float64.

- `startstop="start:stop"`: A string that restricts the output to the points from start to stop.

- `class`: Restrict the output to the points belonging to the classification 'class' (an Integer).
   This option implies two passes, with the first for counting the number of points in class.

### Returns

	ARGSOUT is tuple with a Mx3 xyz array plus 't' and|or 'i' depending whether they were selected or not

### Example

To read the x,y,z,t data from file "lixo.laz" do:
```julia
	xyz, t = lazread("lixo.laz", "xyzt")
```
"""
function lazread(fname::AbstractString; out::String="xyz", type::DataType=Float64, class=0, startstop="1:end")

	(isempty(out)) && error("Empty output vars string is BIG ERROR. Bye, Bye.")

	header, reader, = get_header_and_reader(fname)

	# Get a pointer to the points that will be read
	point = Ref{Ptr{laszip_point}}()
	if (laszip_get_point_pointer(reader[], point) != 0)
		msgerror(reader[], "getting point pointer from laszip reader")
	end

	# Input parsing -------------------------------------------------------------------------------------
	argout, firstPT, lastPT = parse_inputs_las2dat(header, point, reader, out, class, startstop)
	totalNP::Int = lastPT - firstPT + 1
	# ---------------------------------------------------------------------------------------------------

	fType = Float64
	(!occursin('t', argout) && type == Float32) && (fType = Float32)	# A time selection implies Float64

	if (header.global_encoding == 32768)
		argout = "g"
		just_z = Vector{Float32}(undef, lastPT * 3)		# Grids are always in Float32
	else
		# ------ Pre-allocations ---------------------------------------------------------------------
		if (startswith(argout, "xyz") || startswith(argout, "xyt"))  n_col = 3
		elseif (startswith(argout, "xyzt"))  n_col = 4
		elseif (startswith(argout, "xy"))    n_col = 2
		elseif (startswith(argout, "z"))     n_col = 1
		end
		xyz = zeros(fType, totalNP, n_col)
		(occursin('i', argout))	&& (intens = zeros(UInt16,  totalNP, 1))
		#(occursin('t', argout))	&& (tempo  = zeros(Float64, totalNP, 1))
		(occursin('c', argout))	&& (class  = zeros(Int8,    totalNP, 1))
		(occursin('n', argout))	&& (n_ret  = zeros(Int8,    totalNP, 1))
		if (occursin('R', argout) || occursin('G', argout) || occursin('B', argout))
			RGB = occursin('I', argout) ? zeros(UInt16, totalNP, 4) : zeros(UInt16, totalNP, 3)
		end
	end
	#-------------------------------------------------------------------------------------------------

	# CRUTIAL TODO ----------------------------
	# if firstPT != 1 MUST SEEK FORWARD TILL IT
	#------------------------------------------

	coords = 1:3					# Default for out == "xyz"
	if (argout == "xyz")
		@inbounds for k = 1:totalNP
			laszip_read_point(reader[])
			pt = unsafe_load(point[])
			xyz[k,1] = pt.X;	xyz[k,2] = pt.Y;	xyz[k,3] = pt.Z
		end
	elseif (argout == "xy")
		@inbounds for k = 1:totalNP
			laszip_read_point(reader[])
			pt = unsafe_load(point[])
			xyz[k,1] = pt.X;	xyz[k,2] = pt.Y
		end
		coords = 1:2
	elseif (argout == "z")
		@inbounds for k = 1:totalNP
			laszip_read_point(reader[])
			pt = unsafe_load(point[])
			xyz[k,1] = pt.Z
		end
		coords = 3:3
	elseif (argout == "xyzt")
		@inbounds for k = 1:totalNP
			laszip_read_point(reader[])
			pt = unsafe_load(point[])
			xyz[k,1] = pt.X;	xyz[k,2] = pt.Y;	xyz[k,3] = pt.Z;	xyz[k,4] = pt.gps_time
		end
	elseif (argout == "xyzti")
		@inbounds for k = 1:totalNP
			laszip_read_point(reader[])
			pt = unsafe_load(point[])
			xyz[k,1] = pt.X;	xyz[k,2] = pt.Y;	xyz[k,3] = pt.Z;	xyz[k,4] = pt.gps_time
			intens[k] = pt.intensity
		end
	elseif (argout == "xyzi")
		@inbounds for k = 1:totalNP
			laszip_read_point(reader[])
			pt = unsafe_load(point[])
			xyz[k,1]  = pt.X;	xyz[k,2]  = pt.Y;	xyz[k,3]  = pt.Z
			intens[k] = pt.intensity
		end
	elseif (argout == "xyzic")
		@inbounds for k = 1:totalNP
			laszip_read_point(reader[])
			pt = unsafe_load(point[])
			xyz[k,1]  = pt.X;	xyz[k,2]  = pt.Y;	xyz[k,3]  = pt.Z
			intens[k] = pt.intensity
			if (header->point_data_format > 5)
				class[k] = (pt.extended_classification != 0) ? pt.extended_classification : pt.classification
			else
				class[k]  = pt.classification
			end
		end
	elseif (argout == "xyzc")
		@inbounds for k = 1:totalNP
			laszip_read_point(reader[])
			pt = unsafe_load(point[])
			xyz[k,1]  = pt.X;	xyz[k,2]  = pt.Y;	xyz[k,3]  = pt.Z
			if (header->point_data_format > 5)
				class[k] = (pt.extended_classification != 0) ? pt.extended_classification : pt.classification
			else
				class[k]  = pt.classification
			end
		end
	elseif (argout == "RGB")
		@inbounds for k = firstPT:lastPT
			laszip_read_point(reader[])
			pt = unsafe_load(point[])
			RGB[k,1] = pt.rgb.d1;	RGB[k,2] = pt.rgb.d2;	RGB[k,3] = pt.rgb.d3
		end
		coords = 1:0
	elseif (argout == "RGBI")
		@inbounds for k = 1:totalNP
			laszip_read_point(reader[])
			pt = unsafe_load(point[])
			RGB[k,1] = pt.rgb.d1;	RGB[k,2] = pt.rgb.d2;	RGB[k,3] = pt.rgb.d3
			RGB[k,4] = pt.rgb.d4
		end
		coords = 1:0
	elseif (argout != "g")
		# OK, here we have the generic but less efficient code (lots of IFs inside loops)
		# AND THIS IS STILL NOT TAKEN INTO ACOUNT ON OUTPUT. SO BASICALLY IS A NON-WORKING CODE
		#=
		for k = 1:totalNP
			laszip_read_point(reader[])
			pt = unsafe_load(point[])
			for n = 1:GMT.numel(argout)
				if (argout[n] == 'x')
					xyz[k,1] = pt.X
				elseif (argout[n] == 'y')
					xyz[k,2] = pt.Y
				elseif (argout[n] == 'z')
					xyz[k,3] = pt.Z
				elseif (argout[n] == 'i')
					intens[k] = pt.intensity
				elseif (argout[n] == 't')
					tempo[k]  = pt.gps_time
				elseif (argout[n] == 'c')
					if (header->point_data_format > 5)
						class[k] = (pt.extended_classification != 0) ? pt.extended_classification : pt.classification
					else
						class[k]  = pt.classification
					end
				elseif (argout[n] == 'n')
					n_ret = (header->point_data_format > 5) ? pt.extended_number_of_returns : pt.number_of_returns
				elseif (argout[n] == 'R' || argout[n] == 'G' || argout[n] == 'B')
					RGB[k,1] = pt.rgb.d1
					RGB[k,2] = pt.rgb.d2
					RGB[k,3] = pt.rgb.d3
					(size(RGB,2) == 4) && (RGB[k,4] = pt.rgb.d4)
				end
			end
		end
		=#
	end

	if (argout == "g")
		G::GMTgrid = rebuild_grid(header, reader, point, just_z)
	else
		xyz = apply_scale_offset(header, xyz, coords, totalNP)
	end

	# Close the reader
	(laszip_close_reader(reader[]) != 0) && msgerror(reader[], "closing laszip reader")

	# Destroy the reader
	(laszip_destroy(reader[]) != 0) && msgerror(reader[], "destroying laszip reader")

	if (argout == "xyz" || argout == "xy" || argout == "z" || argout == "xyzt")
		lasout_types(ds=mat2ds(xyz))
	elseif (argout == "xyzi")
		lasout_types(dsv = [mat2ds(xyz), mat2ds(intens)])	
	elseif (argout == "xyzti")
		lasout_types(dsv = [mat2ds(xyz), mat2ds(intens)])	
	elseif (argout == "RGB" || argout == "RGBI")
		lasout_types(ds=mat2ds(RGB))
	elseif (argout == "g")			# The disgised GRID case
		lasout_types(grd=G)
	else
		error("Unknown argout type")
	end
end

# --------------------------------------------------------------------------------
function get_header_and_reader(fname::AbstractString)
	# Used by lazread and lazinfo
    reader = Ref{Ptr{Cvoid}}()
	(laszip_create(reader) != 0) && msgerror(reader[], "creating laszip reader")

	is_compressed = Ref{Cint}(0)
	if ((laszip_open_reader(reader[], fname, is_compressed)) != 0)
		msgerror(reader[], "opening laszip reader for file $fname")
	end

    header_ptr = Ref{Ptr{laszip_header}}()
	laszip_get_header_pointer(reader[], header_ptr)
	if (laszip_get_header_pointer(reader[], header_ptr) != 0)		# Get header pointer
		msgerror(reader, "getting header pointer from laszip reader")
	end
	header = unsafe_load(header_ptr[])
	return header, reader, is_compressed[] == 1
end

# --------------------------------------------------------------------------------
function rebuild_grid(header, reader, point, z)::GMTgrid
# Recreate a 2D array plus a 1x9 header vector as used by GMT
	n = 1
	@inbounds for k = 1:header.number_of_point_records
		laszip_read_point(reader[])
		pt = unsafe_load(point[])
		z[n]    = pt.X
		z[n+1]  = pt.Y
		z[n+2]  = pt.Z
		n = n + 3
	end

	if (header.z_scale_factor != 1 && header.z_offset != 0)
		@inbounds for k = 1:3*header.number_of_point_records
			z[k] = z[k] * header.z_scale_factor + header.z_offset
		end
	elseif (header.z_scale_factor != 1 && header.z_offset == 0)
		@inbounds for k = 1:3*header.number_of_point_records
			z[k] *= header.z_scale_factor
		end
	end

	h, n_rows, n_cols, layout = helper_lazgrid(header)		# Get grid header info

	# Now we have to find and throw away eventual extra values of the z vector
	r = 3*header.number_of_point_records - n_rows * n_cols
	if (r == 1)
		pop!(z)
	elseif (r == 2)
		pop!(z);	pop!(z)
	end

	mima = GMT.extrema_nan(z)
	z_ = reshape(z, n_rows, n_cols)
	h[5:6] .= mima

	return mat2grid(z_, hdr=h, layout=layout)
end

# --------------------------------------------------------------------------------
function helper_lazgrid(header)
	# Common code to rebuild_grid & lazinfo

	# Remember that this case used hijacked members of the header structure
	one = (header.project_ID_GUID_data_1 == 0 ? 1 : 0)
	n_rows = Int(header.project_ID_GUID_data_2)
	n_cols = Int(header.project_ID_GUID_data_3)
	x_inc  = (header.max_x - header.min_x) / (n_cols - one)
	y_inc  = (header.max_y - header.min_y) / (n_rows - one)
	h = [header.min_x header.max_x header.min_y header.max_y header.min_z header.max_z header.project_ID_GUID_data_1 x_inc y_inc]

	# Here we have to undo the trick used in lazwrite to store the first 2 chars of the layout in the UINT16 variable
	layout = string(header.file_source_ID)			# First convert it to a string number
	layout = Char(parse(Int, layout[1:2])) * Char(parse(Int, layout[3:4])) * 'B'	# Then conv to char and add the 'B'

	return h, n_rows, n_cols, layout
end

# --------------------------------------------------------------------------------
function apply_scale_offset(header, xyz, coords, totalNP)
# COORDS is a range of xyz (1:2 for "xy", 3:3 for "z")

	scale  = [header.x_scale_factor header.y_scale_factor header.z_scale_factor]
	offset = [header.x_offset header.y_offset header.z_offset]
	ncoord = length(coords)

	if (header.x_scale_factor != 1 && (header.x_offset != 0 || header.y_offset != 0 || header.z_offset != 0))
		# Scale and offset
		for k = 1:totalNP			# Loop over number of points
			for j = 1:ncoord		# Loop over number of output coords
				@inbounds xyz[k,j] = xyz[k,j] * scale[coords[j]] + offset[coords[j]]
			end
		end
	elseif (header.x_scale_factor != 1 && header.x_offset == 0 && header.y_offset == 0 && header.z_offset == 0)
		# Scale only (assume that if scale_x != 1 so are the other scales)
		for k = 1:totalNP
			for j = 1:ncoord
				@inbounds xyz[k,j] *= scale[coords[j]]
			end
		end
	elseif (header.x_scale_factor != 1 || header.y_scale_factor != 1 || header.z_scale_factor != 1 ||
			header.x_offset != 0 || header.y_offset != 0 || header.z_offset != 0)
		# Probably an unforeseen case above. Just do Scale and offset
		for k = 1:totalNP
			for j = 1:ncoord
				@inbounds xyz[k,j] = xyz[k,j] * scale[coords[j]] + offset[coords[j]]
			end
		end
	end
	return xyz
end

# --------------------------------------------------------------------------------------------
function parse_inputs_las2dat(header, point, reader, outpar, class, startstop)
# Check validity of input and in future will parse string options

	# Defaults
	out = zeros(Int8,11)
	n_inClass = 0
	firstPT::Int = 1
	lastPT::Int  = header.number_of_point_records

	i = 1
	for k in eachindex(outpar)
		if     (outpar[k] == 'x') out[i] = 'x';		i += 1
		elseif (outpar[k] == 'y') out[i] = 'y';		i += 1
		elseif (outpar[k] == 'z') out[i] = 'z';		i += 1
		elseif (outpar[k] == 'i') out[i] = 'i';		i += 1
		elseif (outpar[k] == 'c') out[i] = 'c';		i += 1
		elseif (outpar[k] == 'n') out[i] = 'n';		i += 1
		elseif (outpar[k] == 'R')
			if (header.point_data_format != 2 && header.point_data_format != 3 && header.point_data_format != 5 &&
				header.point_data_format != 7 && header.point_data_format != 8 && header.point_data_format != 10)
				@warn("requested 'R' but points do not have RGB. Ignoring it.")
			else
				out[i] = 'R';		i += 1
			end
		elseif (outpar[k] == 'G')
			if (header.point_data_format != 2 && header.point_data_format != 3 && header.point_data_format != 5 &&
				header.point_data_format != 7 && header.point_data_format != 8 && header.point_data_format != 10)
				@warn("requested 'G' but points do not have RGB. Ignoring it.")
			else
				out[i] = 'G';		i += 1
			end
		elseif (outpar[k] == 'B')
			if (header.point_data_format != 2 && header.point_data_format != 3 && header.point_data_format != 5 &&
				header.point_data_format != 7 && header.point_data_format != 8 && header.point_data_format != 10)
				@warn("requested 'B' but points do not have RGB. Ignoring it.")
			else
				out[i] = 'B';		i += 1
			end
		elseif (outpar[k] == 'I')
			if (header.point_data_format != 8 && header.point_data_format != 10)
				@warn("requested 'I' but points do not have RGBI. Ignoring it.")
			else
				out[i] = 'I';		i += 1
			end
		elseif (outpar[k] == 't')
			if (header.point_data_format != 1 && header.point_data_format != 3 &&
				header.point_data_format != 4 && header.point_data_format != 5)
				@warn("requested 't' but points do not have gps time. Ignoring it.")
			else
				out[i] = 't';		i += 1
			end
		end
	end

	# ------------------------------------ PARSE THE KEYWORD OPTIONS -----------------------------------------
	if (class != 0)
		# And now check how many of these class we have
		n_inClass = 0		# Again so no funny plays with more than one -C
		for n = 1:header.number_of_point_records
			laszip_read_point(reader)
			pt = unsafe_load(point[])
			(class == pt.classification) && (n_inClass += 1)
		end
		# Here we must rewind the file, no?
		laszip_seek_point(reader, 0)	# Is it this?
	end

	if (class != 0 && n_inClass == 0)
		@warn("Requested a class but no points inside that class. Ignoring the class request to avoid error.")
		class = 0
	end

	if (startstop != "1:end")
		ind = something(findfirst(isequal(':'), startstop), 0)
		if (ind != 0)
			firstPT = parse(Int,startstop[1:ind-1])
			lastPT  = parse(Int,startstop[ind+1:end])
		else
			lastPT  = parse(Int,startstop)
		end
		if (firstPT > header.number_of_point_records)	firstPT = 1		end
		if (lastPT  > header.number_of_point_records)	lastPT = header.number_of_point_records		end
	end
	# --------------------------------------------------------------------------------------------------------

	argout = unsafe_string(pointer(out))
	return argout, firstPT, lastPT
end

# --------------------------------------------------------------------------------------------
"""
    lazinfo(fname::AbstractString; veronly=false)

Prints information about the LAS file `fname`. If that file is a grid, report the usual grid header info.

- `veronly`: If true, prints only the laszip library version number.
"""
function lazinfo(fname::AbstractString; veronly=false)
	if (veronly == 1)
		major, minor, revision, build = Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt16}(0), Ref{UInt32}(0)
		laszip_get_version(major, minor, revision, build)
		println("LASzip $(major[]).$(minor[]).$(revision[]) (build $(build[]))")
		return
	end

	header, reader, is_compressed = get_header_and_reader(fname)
	(laszip_close_reader(reader[]) != 0) && msgerror(reader[], "closing laszip reader")		# Close reader
	(laszip_destroy(reader[]) != 0) && msgerror(reader[], "destroying laszip reader")		# Destroy reader

	if (header.global_encoding == 32768)
		h, n_rows, n_cols, layout = helper_lazgrid(header)		# Get grid header info
		println("A GMTgrid stored in LASzip format with type Float32")
		println((h[7] == 0) ? "Gridline " : "Pixel ", "node registration used")
		println("x_min: ", h[1], "\tx_max :", h[2], "\tx_inc :", h[8], "\tn_columns :", n_cols)
		println("y_min: ", h[3], "\ty_max :", h[4], "\ty_inc :", h[9], "\tn_rows :", n_rows)
		println("z_min: ", h[5], "\tz_max :", h[6])
		println("Mem layout:\t", layout)
		return
	end

	return header
end

# --------------------------------------------------------------------------------------------
lazread(s::lasout_types) = getproperty(s, Symbol(s.stored))

const lasread = lazread