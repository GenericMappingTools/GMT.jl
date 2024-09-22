"""
Write XYZ data to a LIDAR laz (laszip compressed) or las format file. Usage:

	dat2las(FileName::AbstractString, xyz, hdr_vec=[]; scaleX=[], scaleY=[], scaleZ=[], offX=[], offY=[], offZ=[])

	Where:
		"FileName" Name of the output LIDAR file
		xyz  A Mx3 array with the point coordinates

Example. To write the x,y,z data to file "lixo.laz" do:

	dat2las("lixo.laz", xyz)
"""
function dat2las(fname::AbstractString, xyz, hdr_vec=[]; scaleX=[], scaleY=[], scaleZ=[], offX=[], offY=[], offZ=[])

	parse_inputs_dat2las(xyz, hdr_vec)
	n_rows, n_cols = size(xyz)

	if (!isempty(hdr_vec))
		min_x, max_x, min_y, max_y, min_z, max_z = hdr_vec[1:6]
	end

	#  Create the writer
	laszip_writer = convert(Ptr{Ptr{Cvoid}},pointer([pointer([0])]))
	if (laszip_create(laszip_writer) != 0)
		msgerror(laszip_writer, "creating laszip writer")
	end

	header = pointer([pointer([laszip_header()])])    # Get an empty header directly from C
	laszip_writer = unsafe_load(laszip_writer)

	if (laszip_get_header_pointer(laszip_writer, header) != 0)      # Get the header pointer
		msgerror(laszip_writer, "getting header pointer from laszip writer")
	end

	hdr = unsafe_load(unsafe_load(header))      # Get back the straight type

	# Populate the header
	hdr.version_major = 1
	hdr.version_minor = 2
	hdr.point_data_format = 1
	hdr.number_of_point_records = n_rows
	hdr.x_scale_factor = 1.0
	hdr.y_scale_factor = 1.0
	hdr.z_scale_factor = 1.0
	if (n_cols == 3 && isempty(hdr_vec))		# The 'regular' situation
		min_x, min_y, min_z = minimum(xyz, dims=1)
		max_x, max_y, max_z = maximum(xyz, dims=1)
	end
	hdr.max_x = max_x
	hdr.min_x = min_x
	hdr.max_y = max_y
	hdr.min_y = min_y
	hdr.max_z = max_z
	hdr.min_z = min_z

	# ----------------- Find reasonable scale_factor and offset -----------------------------------------
	if (hdr.min_x >= -360 && hdr.max_x <= 360 && hdr.min_y >= -90 && hdr.max_y <= 90)	# Assume geogs
		hdr.x_scale_factor = isempty(scaleX) ? 1e-7 : scaleX
		hdr.y_scale_factor = isempty(scaleY) ? 1e-7 : scaleY
	else
		hdr.x_scale_factor = isempty(scaleX) ? 1e-3 : scaleX
		hdr.y_scale_factor = isempty(scaleY) ? 1e-3 : scaleY
	end
	hdr.z_scale_factor = isempty(scaleZ) ? 1e-2 : scaleZ

	if (!isnan(hdr.min_x) && !isnan(hdr.max_x))
		if (isempty(offX))
			hdr.x_offset = (floor((hdr.min_x + hdr.max_x)/hdr.x_scale_factor/20000000)) * 10000000 * hdr.x_scale_factor
		else
			hdr.x_offset = offX
		end
	end
	if (!isnan(hdr.min_y) && !isnan(hdr.max_y))
		if (isempty(offY))
			hdr.y_offset = (floor((hdr.min_y + hdr.max_y)/hdr.y_scale_factor/20000000)) * 10000000 * hdr.y_scale_factor
		else
			hdr.y_offset = offY
		end
	end
	if (!isnan(hdr.min_z) && !isnan(hdr.max_z))
		if (isempty(offZ))
			hdr.z_offset = (floor((hdr.min_z + hdr.max_z)/hdr.z_scale_factor/20000000)) * 10000000 * hdr.z_scale_factor
		else
			hdr.z_offset = offZ
		end
	end
	# ---------------------------------------------------------------------------------------------------

	# This is the case where we are storing a grid pretending it's a regular LAZ file. Must hijack some header members
	if (!isempty(hdr_vec))
		hdr.x_scale_factor = hdr.z_scale_factor		# Because in fact we only have zz's
		hdr.y_scale_factor = hdr.z_scale_factor
		hdr.x_offset = hdr.z_offset
		hdr.y_offset = hdr.z_offset
		hdr.number_of_point_records = UInt32(ceil(n_rows / 3))
		hdr.global_encoding = 32768;	# Use this number to codify as GRID. bin(UInt16(32768)) = "1000000000000000"

		one = (hdr_vec[7] == 0 ? 1 : 0)
		hdr.project_ID_GUID_data_1 = hdr_vec[7]
		hdr.project_ID_GUID_data_2 = round(UInt16, (hdr.max_y - hdr.min_y) / hdr_vec[8]) + one 	# n_rows in 2D array
		hdr.project_ID_GUID_data_3 = round(UInt16, (hdr.max_x - hdr.min_x) / hdr_vec[9]) + one 	# n_cols in 2D array
	end

	# Save back the header to its C pointer
	unsafe_store!(unsafe_load(header), hdr)

	if (laszip_open_writer(laszip_writer, fname, 1) != 0)
		msgerror(laszip_writer, @sprintf("opening laszip writer for %s", fname))
	end

	# Get a pointer to the points that will be written
	point = pointer([pointer([laszip_point()])])
	if (laszip_get_point_pointer(laszip_writer, point) != 0)
		msgerror(laszip_writer, "getting point pointer from laszip writer")
	end
	point = unsafe_load(point)

	coordinates = zeros(3)
	if (n_cols == 3)
		for n = 1:n_rows
			#=
			pt = unsafe_load(point)
			pt.X = round(Int32, (xyz[n,1]-hdr.x_offset) * hdr.x_scale_factor)
			pt.Y = round(Int32, (xyz[n,2]-hdr.y_offset) * hdr.y_scale_factor)
			pt.Z = round(Int32, (xyz[n,3]-hdr.z_offset) * hdr.z_scale_factor)
			unsafe_store!(point, pt)
			=#
			coordinates[1] = xyz[n,1]
			coordinates[2] = xyz[n,2]
			coordinates[3] = xyz[n,3]
			laszip_set_coordinates(laszip_writer, convert(Ptr{Cdouble}, pointer(coordinates)))
			laszip_write_point(laszip_writer)
		end
	else
		# Deal with special case of a Z column only where we will cheat by splitting trhough the XYZ
		r = rem(n_rows, 3)
		last_ind = (r == 0 ? n_rows : n_rows - 1)
		for n = 1:3:last_ind
			#pt = unsafe_load(point)
			#pt.X = round(Int32, (xyz[n,1]-hdr.z_offset)   * hdr.z_scale_factor)
			#pt.Y = round(Int32, (xyz[n+1,1]-hdr.z_offset) * hdr.z_scale_factor)
			#pt.Z = round(Int32, (xyz[n+2,1]-hdr.z_offset) * hdr.z_scale_factor)
			coordinates[1] = xyz[n]
			coordinates[2] = xyz[n+1]
			coordinates[3] = xyz[n+2]
			laszip_set_coordinates(laszip_writer, convert(Ptr{Cdouble}, pointer(coordinates)))
			laszip_write_point(laszip_writer)
		end
		#pt = unsafe_load(point)
		if (r == 1)
			#pt.X = round(Int32, (xyz[last_ind+1,1]-hdr.z_offset) * hdr.z_scale_factor)
			#pt.Y = pt.X
			#pt.Z = pt.X
			coordinates[1] = xyz[last_ind+1]
			laszip_set_coordinates(laszip_writer, convert(Ptr{Cdouble}, pointer(coordinates)))
			laszip_write_point(laszip_writer)
		elseif (r == 2)
			#pt.X = round(Int32, (xyz[last_ind+1,1]-hdr.z_offset) * hdr.z_scale_factor)
			#pt.Y = round(Int32, (xyz[last_ind+2,1]-hdr.z_offset) * hdr.z_scale_factor)
			#pt.Z = pt.Y
			coordinates[1] = xyz[last_ind+1]
			coordinates[2] = xyz[last_ind+2]
			laszip_set_coordinates(laszip_writer, convert(Ptr{Cdouble}, pointer(coordinates)))
			laszip_write_point(laszip_writer)
		end
	end

	# Close the writer
	if (laszip_close_writer(laszip_writer) != 0)
		msgerror(laszip_writer, "closing laszip writer")
	end
	# Destroy the writer
	if (laszip_destroy(laszip_writer) != 0)
		msgerror(laszip_writer, "destroying laszip writer")
	end

end

# --------------------------------------------------------------------------
function parse_inputs_dat2las(xyz, hdr_vec)
# Check validity of input and in future will parse string options

	n_rows, n_cols = size(xyz)
	((n_cols != 3 && n_cols != 1)) && error("Input array can only have 1 or 3 columns OR be a 2D array")
	if (!isempty(hdr_vec))
		(length(hdr_vec) < 7) && error("HDR argument does not have at least 7 elements")
	end
end

const xyz2laz  = dat2las			# Alias
