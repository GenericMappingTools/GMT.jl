
global API			# OK, so next times we'll use this one

type GMTJL_GRID 	# The type holding a local header and data of a GMT grid
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
	x::Array{Float64,1}
	y::Array{Float64,1}
	z::Array{Float32,2}
	x_units::ASCIIString
	y_units::ASCIIString
	z_units::ASCIIString
end

type GMTJL_IMAGE 	# The type holding a local header and data of a GMT image
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
	x::Array{Float64,1}
	y::Array{Float64,1}
	image::Array{Uint8,3}
	x_units::ASCIIString
	y_units::ASCIIString
	z_units::ASCIIString
	colormap::Array{Uint8,2}
	alpha::Array{Uint8,2}
end

type GMTJL_CPT
	colormap::Array{Float64,2}
	alpha::Array{Float64,1}
	range::Array{Float64,1}
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
	pLL = pointer([LL])
	X = GMT_Encode_Options(API, g_module, '$', 0, pLL, n_items)	# This call also changes LL
	# Get the pointees
	n_items = unsafe_load(n_items)
	if (n_items == 0)
		warn("Very suspicious, n_items = 0")
	end
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
		#out, X[k].object_ID = GMTJL_register_IO(API, X[k].family, X[k].direction, ptr)
#return out
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

	# 6. Run GMT module; give usage message if errors arise during parsing
	status = GMT_Call_Module(API, g_module, GMT_MODULE_OPT, LL)
	if (status != 0) error("Something went wrong when calling the module. GMT error number = ", status)	end

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
				out = get_textset(API, X[k].object)
			elseif (X[k].family == GMT_IS_CPT)      # A GMT CPT; make it a colormap and the pos'th output item
				#out = unsafe_load(convert(Ptr{GMT_PALETTE}, X[k].object))
#return out
				out = get_cpt(API, X[k].object)
			elseif (X[k].family == GMT_IS_IMAGE)    # A GMT Image; make it the pos'th output item
				out = get_image(API, X[k].object)
			end
		else		# Free any memory allocated outside of GMT
			if (X[k].family == GMT_IS_TEXTSET)		# We have to free the text in table.segment.record
				#GMTJL_Free_Textset(X[k].object)
			end
		end
		if (X[k].family != GMT_IS_TEXTSET) 			# Gave up. The GMT_IS_TEXTSET will have to leak (blame the immutables)
			if (GMT_Destroy_Data(API, pointer([X[k].object])) != GMT.GMT_NOERROR)
				error("GMT: Failed to destroy object used in the interface bewteen GMT and Julia")
			end
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

	ny = int(gmt_hdr.ny);		nx = int(gmt_hdr.nx)
	# Return grids via a float matrix in a struct
	out = GMTJL_GRID("", "", zeros(9)*NaN, zeros(4)*NaN, zeros(2)*NaN, zeros(Int,2), 0, 0,
	                 zeros(2)*NaN, NaN, 0, "", "", "", 0, 0, zeros(Float64,nx), zeros(Float64,ny),
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
	out.LayerCount   = int(gmt_hdr.n_bands)
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
function get_image(API, object)
# ...
	I = unsafe_load(convert(Ptr{GMT_IMAGE}, object))
	if (I.data == C_NULL)
		error("get_image: programming error, output matrix is empty")
	end

	gmt_hdr = unsafe_load(I.header)

	ny = int(gmt_hdr.ny);		nx = int(gmt_hdr.nx);	nz = gmt_hdr.n_bands
	# Return grids via a float matrix in a struct
	out = GMTJL_IMAGE("", "", zeros(9)*NaN, zeros(4)*NaN, zeros(2)*NaN, zeros(Int,2), 0, 0,
	                 zeros(2)*NaN, NaN, 0, "", "", "", 0, 0, zeros(Float64,nx), zeros(Float64,ny),
	                 zeros(Uint8,ny,nx,nz), "", "", "", zeros(Uint8,ny,3), zeros(Uint8,ny,nx))

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
	out.LayerCount   = int(gmt_hdr.n_bands)
	out.x            = linspace(out.range[1], out.range[2], out.n_columns)
	out.y            = linspace(out.range[3], out.range[4], out.n_rows)
	t                = pointer_to_array(I.data, out.n_rows * out.n_columns * gmt_hdr.n_bands)

	if (I.ColorMap != C_NULL)       # Indexed image has a color map
		out.image = t
		out.colormap = I.ColorMap 	# PROBABLY NEEDS TRANSPOSITION
	elseif (gmt_hdr.n_bands == 1)   # gray image
		out.image = t
	elseif (gmt_hdr.n_bands == 3)   # RGB image
		out.image = reshape(t, out.n_rows, out.n_columns, 3)
	elseif (gmt_hdr.n_bands == 4)   # RGBA image
		out.image = t[:,:,1:3]
		out.alpha = t[:,:,4]
	end

	return out
end

# ---------------------------------------------------------------------------------------------------
function get_cpt(API, object::Ptr{Void})
	# Hook this Julia CPT into the k'th output item

	C = unsafe_load(convert(Ptr{GMT_PALETTE}, object))

	if (C.range == C_NULL)
		error("get_cpt: programming error, output CPT is empty")
	end

	n_colors = (C.is_continuous != 0) ? C.n_colors + 1 : C.n_colors
	out = GMTJL_CPT(zeros(n_colors, 3), zeros(n_colors), zeros(2)*NaN)

	for (j = 1:C.n_colors)       # Copy r/g/b from palette to Matlab array
		gmt_lut = unsafe_load(C.range, j)
		out.colormap[j, 1] = gmt_lut.rgb_low.d1
		out.colormap[j, 2] = gmt_lut.rgb_low.d2
		out.colormap[j, 3] = gmt_lut.rgb_low.d3
		#for (k = 1:3)
			#out.colormap[j+k*n_colors] = C.range[j].rgb_low[k]
		#end
		#out.alpha[j] = C.range[j].rgb_low[4]
		out.alpha[j] = gmt_lut.rgb_low.d4
	end
	if (C.is_continuous != 0)    # Add last color
		gmt_lut = unsafe_load(C.range, n_colors)
		out.colormap[n_colors, 1] = gmt_lut.rgb_high.d1
		out.colormap[n_colors, 2] = gmt_lut.rgb_high.d2
		out.colormap[n_colors, 3] = gmt_lut.rgb_high.d3
		#for (k = 1:3)
		#	out.colormap[j+k*n_colors] = gmt_lut.rgb_high[k]
		#end
	end
	gmt_lut = unsafe_load(C.range, 1)
	out.range[1] = gmt_lut.z_low
	gmt_lut = unsafe_load(C.range, C.n_colors)
	out.range[2] = gmt_lut.z_high

	return out
end

# ---------------------------------------------------------------------------------------------------
function get_textset(API, object::Ptr{Void})
	# Hook this Julia TEXTSET into the k'th output item
	
	if (object == C_NULL)
		error("get_cpt: programming error, output textset is NULL")
	end

	T = unsafe_load(convert(Ptr{GMT_TEXTSET}, object))
	p = pointer_to_array(pointer_to_array(T.table,1)[1],1) 		# T.table::Ptr{Ptr{GMT.GMT_TEXTTABLE}}

	# Create a cell array to hold all records
	k = T.n_records
	if (p[1].n_segments > 1) k += p[1].n_segments	end
	C = cell(k)
	# There is only one table when used in the external API, but it may have many segments.
	# The segment information is lost when returned to Julia

	k = 0
	for (seg = 1:p[1].n_segments)
		S = pointer_to_array(pointer_to_array(p[1].segment,1)[seg],seg)	# p[1].segment::Ptr{Ptr{GMT.GMT_TEXTSEGMENT}}
		if (p[1].n_segments > 1)
			C[k] = @sprintf("> %s", bytestring(S[1].header))
			k += 1 
		end
		for (row = 1:S[1].n_rows)
			k += 1
			C[k] = bytestring(pointer_to_array(S[1].record, row)[row])
		end
	end

	return C
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
		obj = GMTJL_grid_init(API, ptr, dir)
		ID  = GMT_Get_ID(API, GMT_IS_GRID, dir, obj)
	elseif (family == GMT_IS_IMAGE)
		obj = GMTJL_image_init(API, ptr, dir)
		ID  = GMT_Get_ID(API, GMT_IS_IMAGE, dir, obj)
	elseif (family == GMT_IS_DATASET)
		# Get a matrix container, and if input and associate it with the Julia pointer
		# MUST TEST HERE THAT ptr IS A MATRIX
		obj = GMTJL_matrix_init(API, ptr, dir)
		ID  = GMT_Get_ID(API, GMT_IS_DATASET, dir, obj)
	elseif (family == GMT_IS_CPT)
		# Get a CPT container, and if input and associate it with the Julia CPT pointer
		obj = GMTJL_CPT_init(API, ptr, dir)
		ID  = GMT_Get_ID(API, GMT_IS_CPT, dir, obj)
	elseif (family == GMT_IS_TEXTSET)
		# Get a TEXTSET container, and if input we associate it with the Julia pointer
		obj = GMTJL_Text_init(API, ptr, dir)
		ID  = GMT_Get_ID(API, GMT_IS_TEXTSET, dir, obj)
	else
		error("GMTJL_register_IO: Bad data type ", family)
	end
	return obj, ID
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
		if ((G = GMT_Create_Data(API, GMT_IS_GRID, GMT_IS_SURFACE, GMT_GRID_HEADER_ONLY, C_NULL,
		                         hdr[1:4], hdr[8:9], UInt32(hdr[7]), pad)) == C_NULL)
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
		Gb.alloc_mode = UInt32(GMT.GMT_ALLOCATED_EXTERNALLY)	# Since array was allocated by Julia
		h = unsafe_load(Gb.header)
		h.z_min = hdr[5]			# Set the z_min, z_max
		h.z_max = hdr[6]
		unsafe_store!(Gb.header, h)
		unsafe_store!(G, Gb)
		GMT_Report(API, GMT.GMT_MSG_DEBUG, @sprintf("Allocate GMT Grid %s in parser\n", G) )
	else	# Just allocate an empty container to hold the output grid, and pass GMT_VIA_OUTPUT
		if ((G = GMT_Create_Data (API, GMT_IS_GRID, GMT_IS_SURFACE, GMT_GRID_HEADER_ONLY, 
		                          C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error ("grid_init: Failure to alloc GMT blank grid container for holding output grid")
		end
	end
	return G
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_image_init(API::Ptr{Void}, img_box, dir::Integer=GMT_IN)
	# ...

	if (isempty(img_box))		# Just tell GMTJL_image_init() to allocate an empty container 
		R = GMTJL_image_init(API, [0.0], [0.0 0 0 0 0 0 0 0 0], dir)
		return R
	end

	if (isa(img_box, GMT_grd_container))
		img = pointer_to_array(img_box.grd, img_box.nx * img_box.ny * img_box.n_bands)
		hdr = pointer_to_array(img_box.hdr, 9)
	elseif (isa(img_box, GMTJL_IMAGE))
		img = img_box.image
		hdr = img_box.hdr
	else
		error("GMTJL_PARSER:image_init: input is not a GRID|IMAGE container type")
	end
	R = GMTJL_image_init(API, img, hdr, dir)
	return R
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_image_init(API::Ptr{Void}, img, hdr::Array{Float64}, dir::Integer=GMT_IN, pad::Int=0)
# ...

	if (dir == GMT_IN)
		if ((I = GMT_Create_Data(API, GMT_IS_IMAGE, GMT_IS_SURFACE, GMT_GRID_ALL, C_NULL,
		                          hdr[1:4], hdr[8:9], UInt32(hdr[7]), pad)) == C_NULL)
			error ("image_init: Failure to alloc GMT source image for input")
		end
		n_rows = size(img, 1);		n_cols = size(img, 2);		n_pages = size(img, 3)
		t = zeros(UInt32, n_rows, n_cols, n_pages)

		for (col = 1:n_cols)
			ic = col * n_rows
			for (row = 1:n_rows)
				ij = ic - row + 1
				t[row, col] = grd[ij]
			end
		end

		Ib = unsafe_load(I)			# Ib = GMT_IMAGE (constructor with 1 method)
		Ib.data = pointer(t)
		Ib.alloc_mode = UInt32(GMT.GMT_ALLOCATED_EXTERNALLY)	# Since array was allocated by Julia
		h = unsafe_load(Ib.header)
		h.z_min = hdr[5]			# Set the z_min, z_max
		h.z_max = hdr[6]
		unsafe_store!(Ib.header, h)
		unsafe_store!(I, Ib)
		GMT_Report(API, GMT.GMT_MSG_DEBUG, @sprintf("Allocate GMT Image %s in parser\n", I) )
	else	# Just allocate an empty container to hold the output grid, and pass GMT_VIA_OUTPUT
		if ((I = GMT_Create_Data (API, GMT_IS_IMAGE, GMT_IS_SURFACE, GMT_GRID_HEADER_ONLY, 
		                          C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error ("image_init: Failure to alloc GMT blank grid container for holding output grid")
		end
		GMT_set_mem_layout(API, "TCLS")
	end
	return I

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
			error("GMTJL_matrix_init: only floating point types allowed in input. Others need to be added")
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

# ---------------------------------------------------------------------------------------------------
function GMTJL_CPT_init(API::Ptr{Void}, cpt, dir::Integer)
	# Used to Create an empty CPT container to hold a GMT CPT.
 	# If direction is GMT_IN then we are given a Matlab CPT and can determine its size, etc.
	# If direction is GMT_OUT then we allocate an empty GMT CPT as a destination.

	if (dir == GMT_IN)	# Dimensions are known from the input pointer

		#if (isempty(cpt))
		#	error("GMTJL_CPT_init: The input that was supposed to contain the CPT, is empty")
		#end

		if (!isa(cpt, GMTJL_CPT))
			error("GMTJL_CPT_init: Expected a CPT structure for input")
		end

		#error("GMTJL_CPT_init: Could not find colormap array with CPT values")
		#error("GMTMEX_CPT_init: Could not find range array for CPT range")
		#error("GMTMEX_CPT_init: Could not find alpha array for CPT transparency")

		n_colors = size(cpt.colormap, 1)
		if ((C = GMT_Create_Data(API, GMT_IS_CPT, GMT_IS_NONE, 0, pointer([n_colors]), C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("GMTJL_CPT_init: Failure to alloc GMT source CPT for input")
		end

		dz = (cpt.range[2] - cpt.range[1]) / (n_colors + 1)

		Cb = unsafe_load(C)
		for (j = 1:n_colors)
			#for (k = 1:3)
			#	P.range[j].rgb_low[k] = colormap[j + k * n_colors]
			#end
			glut = unsafe_load(Cb.range, j)
			rgb_low  = GMT.Array_4_Cdouble(cpt.colormap[j,1], cpt.colormap[j,2], cpt.colormap[j,3], cpt.alpha[j])
			rgb_high = GMT.Array_4_Cdouble(cpt.colormap[j,1], cpt.colormap[j,2], cpt.colormap[j,3], cpt.alpha[j])
			z_low = j * dz
			z_high = (j+1) * dz
			lut = GMT_LUT(z_low, z_high, glut.i_dz, rgb_low, rgb_high, glut.rgb_diff, glut.hsv_low, glut.hsv_high,
			              glut.hsv_diff, glut.annot, glut.skip, glut.fill, glut.label)

			unsafe_store!(Cb.range, lut, j)
		end
		unsafe_store!(C, Cb)
	else 	# Just allocate an empty container to hold an output grid (signal this by passing NULLs)
		if ((C = GMT_Create_Data(API, GMT_IS_CPT, GMT_IS_NONE, 0, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("GMTJL_CPT_init: Failure to alloc GMT blank CPT container for holding output CPT")
		end
	end

	return C
end


# ---------------------------------------------------------------------------------------------------
function GMTJL_Text_init(API::Ptr{Void}, txt, dir::Integer)
	# Used to Create an empty Textset container to hold a GMT TEXTSET.
 	# If direction is GMT_IN then we are given a Matlab CPT and can determine its size, etc.
	# If direction is GMT_OUT then we allocate an empty GMT CPT as a destination.

	# Disclaimer: This code is absolutely diabolic. Thanks to immutables.

	if (dir == GMT_IN)	# Dimensions are known from the input pointer

		#if (isempty(txt))
		#	error("GMTJL_Text_init: The input that was supposed to contain the TXT, is empty")
		#end

		if (!isa(txt, Array{Any}))
			error("GMTJL_Text_init: Expected a Cell array for input")
		end

		#error("GMTJL_CPT_init: Could not find colormap array with CPT values")
		#error("GMTMEX_CPT_init: Could not find range array for CPT range")
		#error("GMTMEX_CPT_init: Could not find alpha array for CPT transparency")

		dim = [1 1 0]
		dim[3] = size(txt, 1)
		if (dim[3] == 1)                # Check if we got a transpose arrangement or just one record
			rec = size(txt, 2)          # Also possibly number of records
			if (rec > 1) dim[3] = rec end  # User gave row-vector of cells
		end

		if ((T = GMT_Create_Data(API, GMT_IS_TEXTSET, GMT_IS_NONE, 0, pointer(dim), C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("GMTJL_Text_init: Failure to alloc GMT source TEXTSET for input")
		end
		T0 = pointer_to_array(T, 1)		# ::Array{GMT.GMT_TEXTSET,1}

		record = Ptr{Uint8}[0 for i=1:dim[3]]	# Can't use cell() because it creates an object of type Any which later fcks all
		for (rec = 1:dim[3])
			record[rec] = pointer(txt[rec])
		end
		record = pointer(record)

		# Get the above created GMT_TEXTTABLE to use in the construction of a new (immutable) one
		seg = 1		# There is only one segment coming from Julia
		p  = pointer_to_array(pointer_to_array(T0[1].table,1)[1],1)         # T.table::Ptr{Ptr{GMT.GMT_TEXTTABLE}}
		S0 = pointer_to_array(pointer_to_array(p[1].segment,1)[seg],seg)	# p[1].segment::Ptr{Ptr{GMT.GMT_TEXTSEGMENT}}

		TS = GMT_TEXTSEGMENT(dim[3], record, S0[1].label, S0[1].header, S0[1].id, S0[1].mode, S0[1].n_alloc,
		                     S0[1].file, S0[1].tvalue)

		#segment::Ptr{Ptr{GMT_TEXTSEGMENT}}
		TSp1 = pointer([TS])		# ::Ptr{GMT_TEXTSEGMENT}
		TSp2 = pointer([TSp1])		# ::Ptr{Ptr{GMT_TEXTSEGMENT}}
		TT0 = p[1]                  # ::GMT_TEXTTABLE
		TT = GMT_TEXTTABLE(TT0.n_headers, TT0.n_segments, dim[3], TT0.header, TSp2, TT0.id, TT0.n_alloc,
		                   TT0.mode, TT0.file)
		pointer_to_array(TSp2,1)	# Just to prevent the garbage man to destroy TSp? before this time
		TTp1 = pointer([TT])		# ::Ptr{GMT_TEXTTABLE}
		TTp2 = pointer([TTp1])		# ::Ptr{Ptr{GMT_TEXTTABLE}}
		Tt   = GMT_TEXTSET(T0[1].n_tables, T0[1].n_segments, dim[3], TTp2, T0[1].id, T0[1].n_alloc, T0[1].geometry,
		                   T0[1].alloc_level, T0[1].io_mode, T0[1].alloc_mode, T0[1].file)
		pointer_to_array(TTp2,2)	# Just to prevent the garbage man to destroy TTp? before this time
		#table::Ptr{Ptr{GMT_TEXTTABLE}}
		unsafe_store!(T, Tt)

	else 	# Just allocate an empty container to hold an output grid (signal this by passing NULLs)
		if ((T = GMT_Create_Data(API, GMT_IS_TEXTSET, GMT_IS_NONE, 0, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("GMTJL_Text_init: Failure to alloc GMT blank TEXTSET container for holding output TEXT")
		end
	end

	return T
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_Free_Textset(Tp::Ptr{Void})
	# We have to free the text in table.segment.record because it can't be freed by GMT but the containers need to
	# ... but unfortunatelly I'm unable to program this function. There is always some immut thing that
	# I'm unable to replace and the GMT_Destroy_Data() crashes Julia.

	if (Tp == C_NULL)
		error("GMTJL_Free_Textset: programming error, textset T is NULL or empty")
	end

	T = pointer_to_array(convert(Ptr{GMT_TEXTSET}, Tp),1)
	p = pointer_to_array(pointer_to_array(T[1].table,1)[1],1) 		# T.table::Ptr{Ptr{GMT.GMT_TEXTTABLE}}

	for (seg = 1:p[1].n_segments)
#		S = T->table[0]->segment[seg];
		S = pointer_to_array(pointer_to_array(p[1].segment,seg)[seg],seg)	# p[1].segment::Ptr{Ptr{GMT.GMT_TEXTSEGMENT}}
		#pr1 = zeros(Int64, S[1].n_rows)
		pr1 = pointer_to_array(S[1].record, S[1].n_rows)
		for (row = 1:S[1].n_rows)
			pr = pointer_to_array(pr1[row], 1)
			pr1[row] = C_NULL 	# Let's hope that the gc cleans up the rest
			unsafe_store!(pointer(pr), pr1[row])
@show(pr)
		end

@show(pr1)
		pr = pointer(pr1)
@show(pr)
		unsafe_store!(pr, C_NULL)
@show(pr)
@show(S[1].record)
	end
end


#= ---------------------------------------------------------------------------------------------------
import Base: isempty
function isempty(x::Any)
	empty = false
	try
		isempty(x)
		empty = true
	end
	return empty
end
=#