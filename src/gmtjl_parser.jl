# Warning: nothing of this really works yet

const GMT_FILE_NONE     = -3
const GMT_FILE_EXPLICIT = -2
const GMT_FILE_IMPLICIT = -1

type GMTJL			# Array to hold information relating to output from GMT
	_type::Int			# type of GMT data, i.e., GMT_IS_DATASET, GMT_IS_GRID, etc.
	direction::Int		# Either GMT_IN or GMT_OUT
	ID::Int				# Registration ID returned by GMT_Register_IO
	lhs_index::Int		# Corresponding index into plhs array
	obj					# The object (structure) registered by GMTJL_Register_IO
end

type GMTJL_GRID
	ProjectionRefPROJ4::ASCIIString
	ProjectionRefWKT::ASCIIString
	hdr::Array{Float64,1}
	range::Array{Float64,1}
	inc::Array{Float64,1}
	dim::Array{Int,1}
	n_rows::Int
	n_columns::Int
	MinMax::Array{Float64,1}
	NoDataValue::Float64
	registration::Int
	title::ASCIIString
	remark::ASCIIString
	command::ASCIIString
	DataType::Int
	LayerCount::Int
	x::Ptr{Float64}
	y::Ptr{Float64}
	z::Array{Float32,2}
	x_units::ASCIIString
	y_units::ASCIIString
	z_units::ASCIIString
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_pre_process(API::Ptr{Void}, g_module::ASCIIString, module_id::Int, options, args...)
#
	keys = getfield(gmt_modules, module_id)		# The magick keys for this module
	tipo = ""
	# First, we check if this is either the read of write special module, which specifies what data type to deal with
	if (g_module == "read" || g_module == "gmtread" || g_module == "write" || g_module == "gmtwrite")
		# Special case: Must determine which data type we are dealing with
		for (k = 1:length(options))
			if (options[k][2] == 'T')
				# Find type and replace ? in keys with this type in uppercase (DGCIT) in make_char_array below
				tipo = string(uppercase(options[k][3]))		# ### 3 might boom
				break
			end
		end
		if (isempty(search("DGCIT", tipo)))
			error("GMTJL_pre_process: No or bad data type given to read|write")
		end
		ind = find_option(options, GMT_OPT_INFILE)
		if (g_module == "gmtwrite" && (ind = find_option(options, GMT_OPT_INFILE)) != 0)
			# Found a -<<file> option; this is actually the output file
			options[ind] = replace(options[ind], "<", ">")
		end
	end

	# This is the array of keys for this module, e.g., "<DI,GGO,..."
	key = replace(keys, '?', tipo)		#In the process, replace any ?-types with the selected type.
	key = split(key, ',')
	n_keys = length(key)

	# We wish to enable by "implicit" options. These are options we will provide here when the user did
	# not specifically give them as part of the command. For instance, if surface is called and the input
	# data comes from a matrix, we may leave off any input name in the command, and then it is understood
	# that we need to add a memory reference to the first matrix given as input.

	given = ones(Int,2,2)
	PS = get_key_pos(key, n_keys, options, given)

	# Note: PS will be one if this module produces PostScript
	n_items = 1
	lr_pos = [1,1]						# These position keeps track where we are in the L and R pointer arrays
	info = [GMTJL(0,0,0,0,0),GMTJL(0,0,0,0,0),GMTJL(0,0,0,0,0)]	# Another UGLY hack

	for (dir = GMT_IN+1:GMT_OUT+1)		# Separately consider input and output
		for (flavor = 1:2)				# 1 means filename input, 2 means option input
			if (given[dir,flavor] == GMT_FILE_NONE) continue;	end		# No source or destination required by this module
			if (given[dir,flavor] == GMT_FILE_EXPLICIT) continue;	end # Source or destination was set explicitly in the command; skip
			# Here we must add the primary input or output from prhs[0] or plhs[0]
			# Get info about the data set
			data_type, geometry = get_arg_dir (key[given[dir,flavor]][1], key, n_keys)
			
			# Pick the next left or right side Julia array pointer
			if (isempty(args))
				ptr = []
			else
				ptr = (dir == GMT_IN+1) ? args[lr_pos[GMT_IN+1]] : []	# The [0] is to allow later conv pointer
			end

			# Create and thus register this container
			O, ID = GMTJL_Register_IO (API, data_type, dir-1, ptr)		# -1 because C is zero based

			# Keep a record or this container as a source or destination
			info[n_items]._type = data_type
			info[n_items].ID = ID
			info[n_items].direction = dir-1			# But store it as 0 based because it's latter compared to GMT_IN
			info[n_items].lhs_index = lr_pos[dir]
			info[n_items].obj = O
			n_items += 1
			lr_pos[dir] += 1		# Advance position counter for next time
			name = bytestring(Array(Uint8, 16))
			if (GMT_Encode_ID (API, name, ID) != GMT_NOERROR)	# Make filename with embedded object ID
				error ("GMTJL_PARSER:GMTJL_pre_process: Failure to encode string")
			end
			name = chop(name)	# Remove the 16th char

			if (flavor == 1)	# Must add a new option
				# Create the missing (implicit) GMT option and append it to the options list
				t = cell(1)
				t[1] = @sprintf("-%s%s",key[given[dir,1]][1], name)	# Ghrrr, must be a more elegant way
				append!(options, t)
			else	# Must find the option and update it, or add it if not found
				ind = find_option(options, key[given[dir,2]][1])
				if (ind == 0)
					# Create the missing (implicit) GMT option and append it to options list
					t = cell(1)
					t[1] = @sprintf("-%s%s",key[given[dir,2]][1], name)
					append!(options, t)
				else
					options[ind] = options[ind][1:2] * name		# Just update its argument
				end
			end

		end
	end

	for (k = 1:length(options))			# Loop over the module options given
		if (length(options[k]) < 2)		continue	end 		# The cases of " ... > outputfile"
		if (PS > 0 && options[k][2] == GMT_OPT_OUTFILE) PS += 1;		end		# Count additional output options
	end

	if (PS == 1)		# No redirection of the PS to an actual file means an error
		error = GMT_NOERROR
	elseif (PS > 2)		# Too many output files for PS
		error = 2
	else
		error = GMT_NOERROR
	end

	GMT_Report(API, GMT_MSG_VERBOSE, @sprintf("Args are now [%s]\n", join(options, " ")))

	# Here, a command line '-F200k -G $ -L -P' has been changed to '-F200k -G@GMTAPI@-000001 @GMTAPI@-000002 -L@GMTAPI@-000003 -P'
	# where the @GMTAPI@-00000x are encodings to registered resources or destinations

	# Pass back the info array and the number of items
	return (error > 0 ? -error : n_items), info

end

# ---------------------------------------------------------------------------------------------------
function GMTJL_post_process(API::Ptr{Void}, X, n_items::Int)
	out = [0.f0]
	for (item = 1:n_items)
		if (X[item]._type == GMT_IS_GRID)           # We read or wrote a GMT grid, examine further
			if (X[item].direction == GMT_OUT)       # Here, GMT_OUT means "Return this info to Julia"
				if ((R = GMT_Retrieve_Data(API, X[item].ID)) == C_NULL)
					error("GMTJL_PARSER:Error retrieving grid from GMT\n")
				end

				Rb = unsafe_load(convert(Ptr{GMT_GRID}, R))
				if (Rb.data == C_NULL)
					error("GMTMEX_post_process: programming error, output matrix is empty")
				end

				gmt_hdr = unsafe_load(Rb.header)

				ny = Int(gmt_hdr.ny);		nx = Int(gmt_hdr.nx)
				# Return grids via a float matrix in a struct
				out = GMTJL_GRID("", "", zeros(9)*NaN, zeros(4)*NaN, zeros(2)*NaN, zeros(Int,2), 0, 0,
				                 zeros(2)*NaN, NaN, 0, "", "", "", 0, 0, C_NULL, C_NULL,
				                 zeros(Float32,ny,nx), "", "", "")

				if (gmt_hdr.ProjRefPROJ4 != C_NULL)
					out.ProjectionRefPROJ4 = bytestring(gmt_hdr.ProjRefPROJ4)
				end
				if (gmt_hdr.ProjRefWKT != C_NULL)
					out.ProjectionRefWKT = bytestring(gmt_hdr.ProjectionRefWKT)
				end
				# The following is uggly is a consequence of the clag.jl translation of fixed sixe arrays  
				out.range = vec([gmt_hdr.wesn.d1 gmt_hdr.wesn.d2 gmt_hdr.wesn.d3 gmt_hdr.wesn.d4])
				out.hdr   = vec([gmt_hdr.wesn.d1 gmt_hdr.wesn.d2 gmt_hdr.wesn.d3 gmt_hdr.wesn.d4 gmt_hdr.z_min gmt_hdr.z_max gmt_hdr.registration gmt_hdr.inc.d1 gmt_hdr.inc.d2])
				out.inc          = vec([gmt_hdr.inc.d1 gmt_hdr.inc.d2])
				out.n_rows       = ny
				out.n_columns    = nx
				out.MinMax       = vec([gmt_hdr.z_min gmt_hdr.z_max])
				out.NoDataValue  = gmt_hdr.nan_value
				out.dim          = vec([gmt_hdr.ny gmt_hdr.nx])
				out.registration = gmt_hdr.registration
				out.LayerCount   = Int(gmt_hdr.n_bands)
				out.x            = linspace(out.range[1], out.range[2], out.n_columns)
				out.y            = linspace(out.range[3], out.range[4], out.n_rows)
				t                = pointer_to_array(Rb.data, out.n_rows * out.n_columns)

				for (col = 1:out.n_columns)
					for (row = 1:out.n_rows)
						ij = col * out.n_rows - row + 1
						out.z[row, col] = t[ij]
					end
				end

			else
				R = X[item].obj;
			end
		elseif (X[item]._type == GMT_IS_DATASET)    # Return tables with double (mxDOUBLE_CLASS) matrix
			if (X[item].direction == GMT_OUT)       # Here, GMT_OUT means "Return this info to Julia"
				if ((R = GMT_Retrieve_Data(API, X[item].ID)) == C_NULL)
					error("GMTJL_PARSER: Error retrieving matrix from GMT")
				end
				Rb = unsafe_load(convert(Ptr{GMT_MATRIX}, R))

				out = zeros(Float32, Rb.n_rows, Rb.n_columns)
				if (Rb.shape == GMT_IS_COL_FORMAT)  # Easy, just copy
					out = copy!(out, pointer_to_array(convert(Ptr{Cfloat},Rb.data), Rb.n_rows * Rb.n_columns))
				else	# Must transpose
					t = pointer_to_array(convert(Ptr{Cfloat},Rb.data), Rb.n_rows * Rb.n_columns)
					for (col = 1:Rb.n_columns)
						for (row = 1:Rb.n_rows)
							ij = (row - 1) * Rb.n_columns + col
							out[row, col] = t[ij]
						end
					end
				end
			else
				R = X[item].obj;
			end

			# Else we were passing Julia data into GMT as data input and we are now done with it.
			# We always destroy R at this point, whether input or output.  The alloc_mode
			# will prevent accidential freeing of any externally-allocated arrays.

			if (GMT_Destroy_Data(API, pointer([R])) != GMT_NOERROR)
				error("GMTJL_post_process: Failed to destroy matrix R used in the interface bewteen GMT and Julia")
			end
		else
			error("GMTJL_PARSER: not yet implemented")
		end
	end

	return out

end

# ---------------------------------------------------------------------------------------------------
function find_option(options, opt)
# Substitute of GMT_Find_Option() but for options in a cell array of strings
	if (!isa(opt, Char))	opt = char(opt)	end
	ind = 0
	for (k = 1:length(options))
		if (options[k][min(2,length(options[k]))] == opt)
			ind = k
			break
		end
	end
	return ind
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_grid_init(API::Ptr{Void}, grd_box, dir::Integer=GMT_IN)
	# ...

	empty = false 		# F... F... it's a shame having to do this
	try
		isempty(grd_box)
		empty = true
	end

	if (empty)			# Just tell GMTJL_grid_init() to allocate an empty container 
		R = GMTJL_grid_init(API, [0.0], [0.0 0 0 0 0 0 0 0 0], dir)
		return R
	end

	if (isa(grd_box, GMT_grd_container))
		grd = pointer_to_array(grd_box.grd, grd_box.nx * grd_box.ny)
		hdr = pointer_to_array(grd_box.hdr, 9)
	elseif (isa(grd_box, GMTJL_GRID))
		grd = grd_box.z
		hdr = grd_box.hdr
	else
		error("GMTJL_PARSER:grd_init: input is not a GRID|IMAGE container type")
	end
	R = GMTJL_grid_init(API, grd, hdr, dir)
	return R
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_grid_init(API::Ptr{Void}, grd, hdr::Array{Float64}, dir::Integer=GMT_IN, pad::Int=0)
	# Used to Create an empty Grid container to hold a GMT grid.
 	# If direction is GMT_IN then we are given a Julia grid and can determine its size, etc.
	# If direction is GMT_OUT then we allocate an empty GMT grid as a destination.
	#dim = [size(grd,1), size(grd,2), 1]

	if (dir == GMT_IN)
		if ((G = GMT_Create_Data (API, GMT_IS_GRID, GMT_IS_SURFACE, GMT_GRID_HEADER_ONLY, C_NULL,
		                          hdr[1:4], hdr[8:9], uint32(hdr[7]), pad)) == C_NULL)
			error ("GMTJL_PARSER:grid_init: Failure to alloc GMT source matrix for input")
		end

		n_rows = size(grd, 1);		n_cols = size(grd, 2)
		t = zeros(Float32, n_rows, n_cols)

		for (col = 1:n_cols)
			ic = col * n_rows
			for (row = 1:n_rows)
				ij = ic - row + 1
				t[row, col] = grd[ij]
			end
		end

		Gb = unsafe_load(G)			# Gb = GMT_GRID (constructor with 1 method)
		Gb.data = pointer(t)
		Gb.alloc_mode = uint32(GMT_ALLOCATED_EXTERNALLY)	# Since array was allocated by Julia
		h = unsafe_load(Gb.header)
		h.z_min = hdr[5]			# Set the z_min, z_max
		h.z_max = hdr[6]
		unsafe_store!(Gb.header, h)
		unsafe_store!(G, Gb)
		GMT_Report (API, GMT_MSG_DEBUG, @sprintf("Allocate GMT Grid %s in gmtjl_parser\n", G) )
	else	# Just allocate an empty container to hold the output grid, and pass GMT_VIA_OUTPUT
		if ((G = GMT_Create_Data (API, GMT_IS_GRID, GMT_IS_SURFACE, GMT_GRID_HEADER_ONLY, 
		                          C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error ("GMTJL_PARSER:grid_init: Failure to alloc GMT blank grid container for holding output grid")
		end
	end
	return G
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_matrix_init(API::Ptr{Void}, grd, dir::Integer=GMT_IN, pad::Int=0)
# ...
	if (dir == GMT_IN)
		dim = pointer([size(grd,2), size(grd,1), 0])	# MATRIX in GMT uses (col,row)
		mode = 0;
	else
		dim = C_NULL
		mode = GMT_VIA_OUTPUT;
	end

	if ((M = GMT_Create_Data(API, GMT_IS_MATRIX, GMT_IS_PLP, mode, dim, C_NULL, C_NULL, 0, 0, C_NULL))
			== C_NULL)
		println("GMTJL_PARSER:matrix_init: Failure to alloc GMT source matrix")
		return -1
	end

	GMT_Report(API, GMT_MSG_DEBUG, @sprintf("Allocate GMT Matrix %s in gmtjl_parser\n", M) )
	Mb = unsafe_load(M)			# Mb = GMT_MATRIX (constructor with 1 method)
	Mb.n_rows    = size(grd,1)
	Mb.n_columns = size(grd,2)

	if (dir == GMT_IN)
		# NEED TO ADD CODE FOR THE OTHER DATA TYPES
		if (eltype(grd) == Float64)
			Mb._type = uint32(GMT_DOUBLE)
		elseif (eltype(grd) == Float32)
			Mb._type = uint32(GMT_FLOAT)
		else
			error("GMTJL_matrix_init: only floating point types allowed in input")
		end
		Mb.data  = pointer(grd)
		Mb.dim = Mb.n_rows		# Data from Julia is in column major
		Mb.alloc_mode = GMT_ALLOC_EXTERNALLY;	# Since matrix was allocated by Julia
		Mb.shape = GMT_IS_COL_FORMAT;		# Julia order is column major */

	else
		Mb._type = uint32(GMT_FLOAT)		# PROVIDE A MEAN TO CHOOSE?
		if (~isempty(grd))
			Mb.data  = pointer(grd)
		end
		# Data from GMT must be in row format since we may not know n_rows until later
		Mb.shape = uint32(GMT_IS_ROW_FORMAT)
	end

	unsafe_store!(M, Mb)
	return M
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_Register_IO (API::Ptr{Void}, family::Integer, dir::Integer, ptr)
	# Create the grid or matrix contains, register them, and return the ID
	ID = GMT_NOTSET
	if (family == GMT_IS_GRID)
		# Get an empty grid, and if input we and associate it with the Julia grid pointer
		R = GMTJL_grid_init (API, ptr, dir)
		ID = GMT_Get_ID (API, GMT_IS_GRID, dir, R)

	elseif (family == GMT_IS_DATASET)
		# Get a matrix container, and if input and associate it with the Julia pointer
		# MUST TEST HERE THAT ptr IS A MATRIX
		R = GMTJL_matrix_init (API, ptr, dir)
		ID = GMT_Get_ID (API, GMT_IS_DATASET, dir, R)
	else
		error("GMTJL_PARSER:GMTJL_Register_IO: Bad data type ", family)
	end
	return R, ID
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_find_module (API, g_module::String)
# Just search for module and return entry in keys array. Only modules listed in mexproginfo.txt are used
	gmt_module = "gmt"
	nomes = names(gmt_modules)
	n_modules = length(nomes)
	prefix = 0
	k = 1
	while (k <= n_modules && g_module != @sprintf("%s",nomes[k]))	# Have to use dirty trick (know no more)
		k = k + 1
	end
	if (k == n_modules + 1)
		# Not found in the known list, try prepending gmt to the module name (i.e. gmt + get = gmtget)
		gmt_module = gmt_module * g_module
		k = 1
		while (k <= n_modules && gmt_module != @sprintf("%s",nomes[k]))
			k = k + 1
		end
		if (k == n_modules + 1)		return -1, prefix;	end		# Not found in the known list
		prefix = -1
	end
	# OK, found in the list - now call it and see if it is actually available */
	id = k
	if ((k = GMT_Call_Module (API, @sprintf("%s",nomes[id]), GMT_MODULE_EXIST, C_NULL)) == GMT_NOERROR)
		return id, prefix		# Found and accessible
	end
	return -1, prefix			# Not found in any shared libraries
end


# ---------------------------------------------------------------------------------------------------
function get_key_pos (key, n_keys::Int, options, def::Array{Int})
	# Must determine if default input and output have been set via program options or if they should be added explicitly.
 	# As an example, consider the GMT command grdfilter in.nc -Fg200k -Gfilt.nc.  In Matlab this might be
	# filt = gmt ('grdfilter $ -Fg200k -G$', in);
	# However, it is more natural not to specify the lame -G$, i.e.
	# filt = gmt ('grdfilter $ -Fg200k', in);
	# or even the other lame $, e.g.
	# filt = gmt ('grdfilter -Fg200k', in);
	# In that case we need to know that -G is the default way to specify the output grid and if -G is
	# not given we must associate -G with the first left-hand-side item (here filt).

	GMT_IN = 1;		GMT_OUT = 2		# Redefine these here because Julia is one based
	PS = 0
	def[GMT_IN,1]  = GMT_FILE_IMPLICIT	# Initialize to setting the i/o implicitly for filenames
	def[GMT_OUT,1] = GMT_FILE_NONE		# Initialize to setting the i/o implicitly for filenames
	def[GMT_IN,2]  = def[GMT_OUT,2] = GMT_FILE_NONE	# For options with mising filenames they are NONE unless set

	# Loop over the module options to see if inputs and outputs are set explicitly or implicitly
	for (k = 1:length(options))
		# First see if this option is one that might take $
		pos = -1
		for (n = 1:length(key))
#println("---k = ", k, " ---n = ",n, " ---key = ", key, "  ---opts = ", options)
			if (length(options[k]) < 2)		continue	end 		# The cases of " ... > outputfile"
			if (key[n][1] == options[k][2])		pos = n;	end
		end
		if (pos == -1) continue;	end		# No, it was some other harmless option, e.g., -J, -O ,etc.
		flavor = (options[k][2] == '<') ? 1 : 2			# Filename or option with filename ?
		# SE COMECAR A DAR MUITA MERDA ... EU TINHA key[pos][2]
		dir = (key[pos][3] == 'I') ? GMT_IN : GMT_OUT	# Input of output ?
		if (flavor == 1)								# File name was given on command line
			def[dir,flavor] = GMT_FILE_EXPLICIT;
		else		# Command option; e.g., here we have -G<file>, -G$, or -G [the last two means implicit]
			def[dir,flavor] = (length(options[k]) == 1 || options[k][2] == '$') ? GMT_FILE_IMPLICIT : GMT_FILE_EXPLICIT	# The option provided no file name (or gave $) so it is implicit
		end
	end

	# Here, if def[] == GMT_FILE_IMPLICIT (the default in/out option was NOT given),
	# then we want to return the corresponding entry in key
	for (pos = 1:n_keys)		# For all module options that might take a file
		flavor = (key[pos][1] == '<') ? 1 : 2;
		if ((key[pos][3] == 'I' || key[pos][3] == 'i') && key[pos][1] == '-')
			# This program takes no input (e.g., psbasemap, pscoast)
			def[GMT_IN,1] = def[GMT_IN,2]  = GMT_FILE_NONE;
		elseif (key[pos][3] == 'I' && def[GMT_IN,flavor] == GMT_FILE_IMPLICIT)
			# Must add implicit input; use def to determine option,type
			def[GMT_IN,flavor] = pos;
		elseif ((key[pos][3] == 'O' || key[pos][3] == 'o') && key[pos][1] == '-')
			# This program produces no output */
			def[GMT_OUT,1] = def[GMT_OUT,2] = GMT_FILE_NONE;
		elseif (key[pos][3] == 'O' && def[GMT_OUT,flavor] == GMT_FILE_IMPLICIT)
			# Must add implicit output; use def to determine option,type
			def[GMT_OUT,flavor] = pos;
		elseif (key[pos][3] == 'O' && def[GMT_OUT,flavor] == GMT_FILE_NONE && flavor == 2)
			# Must add mising output option; use def to determine option,type
			def[GMT_OUT,flavor] = pos;
		end
		if ((key[pos][3] == 'O' || key[pos][3] == 'o') && key[pos][2] == 'X' && key[pos][1] == '-')
			PS = 1;		#This program produces PostScript
		end
	end
	return PS
end

# ---------------------------------------------------------------------------------------------------
function get_arg_dir (option, key, n_keys::Int)
# key is an array with options of the current program that read/write data
	
	# 1. First determine if option is one of the choices in key
	
	item = -1
	for (k = 1:length(key))
		if (key[k][1] == option)		item = k;	end
	end

	if (item == -1)		# This means a coding error we must fix
		error ("GMTJL_PARSER:get_arg_dir: This option does not allow \$ arguments")
	end
	
	# 2. Assign direction, data_type, and geometry
	
	if (key[item][2] == 'G')		# 2nd char contains the data type code
		data_type = GMT_IS_GRID
		geometry = GMT_IS_SURFACE
	elseif (key[item][2] == 'P')
		data_type = GMT_IS_DATASET
		geometry = GMT_IS_POLY
	elseif (key[item][2] == 'L')
		data_type = GMT_IS_DATASET
		geometry = GMT_IS_LINE
	elseif (key[item][2] == 'D')
		data_type = GMT_IS_DATASET
		geometry = GMT_IS_POINT
	elseif (key[item][2] == 'C')
		data_type = GMT_IS_CPT
		geometry = GMT_IS_NONE
	elseif (key[item][2] == 'T')
		data_type = GMT_IS_TEXTSET
		geometry = GMT_IS_NONE
	elseif (key[item][2] == 'I')
		data_type = GMT_IS_IMAGE
		geometry = GMT_IS_SURFACE
	elseif (key[item][2] == 'X')
		data_type = GMT_IS_PS
		geometry = GMT_IS_NONE
	else
		error ("GMTJL_PARSER:get_arg_dir: Bad data_type character in 3-char module code!");
	end

	# Third key character contains the in/out code
	# The following is UGLY and when this is working I'll either find a elegant solution or do
	# a ccall() and screw the strings immutability
	if (key[item][3] == 'I')	# This was the default input option set explicitly; no need to add later
		key[item] = key[item][1:2] * "i"
	end
	if (key[item][3] == 'O')	# This was the default output option set explicitly; no need to add later
		key[item] = key[item][1:2] * "o"
	end
	io_dir = ((key[item][3] == 'i') ? GMT_IN : GMT_OUT)	# Return the direction of i/o
	return data_type, geometry, io_dir
end
