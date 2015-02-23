
global API			# OK, so next times we'll use this one

type GMTJL_GRID 	# The type holding a locla header and data of a GMT grid
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

function gmt(cmd::String, args...)

	# ----------- Minimal error checking ------------------------
	if (~isa(cmd, String))
		error("gmt: first argument must always be a string")
	end
	n_argin = length(args)
	if (n_argin > 0 && isa(args[1], String))		# TO BE CORRECT, SHOULD BE any(isa('char'))
		error("gmt: second argument when exists must be numeric")
	end
	# -----------------------------------------------------------

	#try
		#a=API		# Must test here if it's a valid one
	#catch
		API = GMT_Create_Session("GMT5", 0, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL)
		if (API == C_NULL)
			error("Failure to create a GMT5 Session")
		end
	#end

	# 2. Get arguments, if any, and extract the GMT module name
	# First argument is the command string, e.g., "blockmean -R0/5/0/5 -I1" or just "help"
	g_module,r = strtok(cmd)
	
	# 3. Convert mex command line arguments to a linked GMT option list
	LL = GMT_Create_Options(API, 0, r)	# It uses also the fact that GMT parses and check options
	if (LL == C_NULL)
		error("Error creating the linked list of options. Probably a bad usage.")
	end

	# 4. Preprocess to update GMT option lists and return info array X
	n_items = pointer([0])
	X = GMT_Encode_Options(API, g_module, '$', pointer([LL]), n_items)	# This call also changes LL
	# Get the pointees
	n_items = unsafe_load(n_items)
	#X = pointer_to_array(X,n_items)     # The array of GMT_RESOURCE structs
	XX = Array(GMT_RESOURCE, 1, n_items)
	for (k = 1:n_items)
		XX[k] = unsafe_load(X, k)        # Cannot us pointer_to_array() because GMT_RESOURCE is not immutable and would BOOM!
	end
	X = XX

	# 5. Assign input (from julia) and output (from GMT) resources
	for (k = 1:n_items)                 # Number of GMT containers involved in this module call */
		ptr = (X[k].direction == GMT_IN) ? args[X[k].pos+1] : []
		X[k].object, X[k].object_ID = GMTJL_register_IO(API, X[k].family, X[k].direction, ptr)
		if (X[k].object == C_NULL || X[k].object_ID == GMT.GMT_NOTSET)
			error("GMT: Failure to register the resource\n")
		end
		name = "                "
		if (GMT_Encode_ID(API, name, X[k].object_ID) != GMT.GMT_NOERROR)        # Make filename with embedded object ID */
			error("GMT: Failure to encode string")
		end
		if (GMT_Expand_Option(API, X[k].option, '$', name) != GMT.GMT_NOERROR)  # Replace ARG_MARKER in argument with name */
			error("GMT: Failure to expand filename marker")
		end
	end

	# 6. Run GMT module; give usage message if errors arise during parsing */
	status = GMT_Call_Module(API, g_module, GMT_MODULE_OPT, LL)
	if (status != 0) error("Something went wrong. GMT error number = ", status)	end

	# 7. Hook up module GMT outputs to Julia array
	out = []
	for (k = 1:n_items)                     # Number of GMT containers involved in this module call
		if (X[k].direction == GMT_OUT)      # Get results from GMT into Julia arrays
			if ((X[k].object = GMT_Retrieve_Data(API, X[k].object_ID)) == C_NULL)
				error("GMT: Error retrieving object from GMT")
			end
			pos = X[k].pos                  # Short-hand for index into the plhs[] array being returned to Matlab
			if (X[k].family == GMT_IS_GRID)         # Determine what container we got
				out = get_grid(API, X[k].object)
			elseif (X[k].family == GMT_IS_DATASET)  # A GMT table; make it a matrix and the pos'th output item
				out = get_table(API, X[k].object)
			elseif (X[k].family == GMT_IS_TEXTSET)  # A GMT textset; make it a cell and the pos'th output item
			elseif (X[k].family == GMT_IS_CPT)      # A GMT CPT; make it a colormap and the pos'th output item
			elseif (X[k].family == GMT_IS_IMAGE)    # A GMT Image; make it the pos'th output item
			end
		end
		if (GMT_Destroy_Data(API, pointer([X[k].object])) != GMT.GMT_NOERROR)
			error("GMT: Failed to destroy object used in the interface bewteen GMT and Matlab")
		end
	end

	# 8. Destroy linked option list
	if (GMT_Destroy_Options(API, pointer([LL])) != 0)
		error("GMT: Failure to destroy GMT5 options")
	end

	return out

end

# ---------------------------------------------------------------------------------------------------
function create_cmd(LL)
	# Takes a LinkedList LL of gmt options created by GMT_Create_Options() and join them in a single
	# string but taking care that all options start with the '-' char and insert '<' if necessary
	# For example "-Tg lixo.grd" will become "-Tg -<lixo.grd"
	LL_up = unsafe_load(LL);
	done = false
	a = IOBuffer()
	while (!done)
		print(a, '-', char(LL_up.option))
		print(a, bytestring(LL_up.arg))
		if (LL_up.next != C_NULL)
			print(a, " ")
			LL_up = unsafe_load(LL_up.next);
		else
			done = true
		end
	end
	return takebuf_string(a)
end

# ---------------------------------------------------------------------------------------------------
function strtok(args, delim::ASCIIString=" ")
# A Matlab like strtok function
	tok = "";	r = ""
	if (~is_valid_ascii(args))
		return tok, r
	end

	ind = search(args, delim)
	if (isempty(ind))
		return lstrip(args,collect(delim)), r		# Always clip delimiters at the begining
	end
	tok = lstrip(args[1:ind[1]-1], collect(delim))	#		""
	r = lstrip(args[ind[1]:end], collect(delim))

	return tok,r
end

# ---------------------------------------------------------------------------------------------------
function get_grid(API, object)
# ...
	G = unsafe_load(convert(Ptr{GMT_GRID}, object))
	if (G.data == C_NULL)
		error("get_grid: programming error, output matrix is empty")
	end

	gmt_hdr = unsafe_load(G.header)

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
	t                = pointer_to_array(G.data, out.n_rows * out.n_columns)

	for (col = 1:out.n_columns)
		for (row = 1:out.n_rows)
			ij = col * out.n_rows - row + 1
			out.z[row, col] = t[ij]
		end
	end

	return out
end

# ---------------------------------------------------------------------------------------------------
function get_table(API, object)
# ...
	M = unsafe_load(convert(Ptr{GMT_MATRIX}, object))
	if (M.data == C_NULL)
		error("get_table: programming error, output matrix is empty")
	end

	out = zeros(Float32, M.n_rows, M.n_columns)
	if (M.shape == GMT.GMT_IS_COL_FORMAT)  # Easy, just copy
		out = copy!(out, pointer_to_array(convert(Ptr{Cfloat},M.data), M.n_rows * M.n_columns))
	else	# Must transpose
		t = pointer_to_array(convert(Ptr{Cfloat},M.data), M.n_rows * M.n_columns)
		for (col = 1:M.n_columns)
			for (row = 1:M.n_rows)
				ij = (row - 1) * M.n_columns + col
				out[row, col] = t[ij]
			end
		end
	end

	return out
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_register_IO (API::Ptr{Void}, family::Integer, dir::Integer, ptr)
	# Create the grid or matrix contains, register them, and return the ID
	ID = GMT.GMT_NOTSET
	if (family == GMT_IS_GRID)
		# Get an empty grid, and if input we and associate it with the Julia grid pointer
		R = GMTJL_grid_init(API, ptr, dir)
		ID = GMT_Get_ID(API, GMT_IS_GRID, dir, R)

	elseif (family == GMT_IS_DATASET)
		# Get a matrix container, and if input and associate it with the Julia pointer
		# MUST TEST HERE THAT ptr IS A MATRIX
		R = GMTJL_matrix_init(API, ptr, dir)
		ID = GMT_Get_ID(API, GMT_IS_DATASET, dir, R)
	else
		error("GMTJL_register_IO: Bad data type ", family)
	end
	return R, ID
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
			error ("grid_init: Failure to alloc GMT source matrix for input")
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
		Gb.alloc_mode = uint32(GMT.GMT_ALLOCATED_EXTERNALLY)	# Since array was allocated by Julia
		h = unsafe_load(Gb.header)
		h.z_min = hdr[5]			# Set the z_min, z_max
		h.z_max = hdr[6]
		unsafe_store!(Gb.header, h)
		unsafe_store!(G, Gb)
		GMT_Report(API, GMT.GMT_MSG_DEBUG, @sprintf("Allocate GMT Grid %s in gmtjl_parser\n", G) )
	else	# Just allocate an empty container to hold the output grid, and pass GMT_VIA_OUTPUT
		if ((G = GMT_Create_Data (API, GMT_IS_GRID, GMT_IS_SURFACE, GMT_GRID_HEADER_ONLY, 
		                          C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error ("grid_init: Failure to alloc GMT blank grid container for holding output grid")
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

	GMT_Report(API, GMT.GMT_MSG_DEBUG, @sprintf("Allocate GMT Matrix %s in gmtjl_parser\n", M) )
	Mb = unsafe_load(M)			# Mb = GMT_MATRIX (constructor with 1 method)
	Mb.n_rows    = size(grd,1)
	Mb.n_columns = size(grd,2)

	if (dir == GMT_IN)
		# NEED TO ADD CODE FOR THE OTHER DATA TYPES
		if (eltype(grd) == Float64)
			Mb._type = uint32(GMT.GMT_DOUBLE)
		elseif (eltype(grd) == Float32)
			Mb._type = uint32(GMT.GMT_FLOAT)
		else
			error("GMTJL_matrix_init: only floating point types allowed in input")
		end
		Mb.data  = pointer(grd)
		Mb.dim = Mb.n_rows		# Data from Julia is in column major
		Mb.alloc_mode = GMT.GMT_ALLOC_EXTERNALLY;	# Since matrix was allocated by Julia
		Mb.shape = GMT.GMT_IS_COL_FORMAT;		# Julia order is column major */

	else
		Mb._type = uint32(GMT.GMT_FLOAT)		# PROVIDE A MEAN TO CHOOSE?
		if (~isempty(grd))
			Mb.data  = pointer(grd)
		end
		# Data from GMT must be in row format since we may not know n_rows until later
		Mb.shape = uint32(GMT.GMT_IS_ROW_FORMAT)
	end

	unsafe_store!(M, Mb)
	return M
end
