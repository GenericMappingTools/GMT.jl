global API			# OK, so next times we'll use this one
global grd_mem_layout

type GMTgrid 	# The type holding a local header and data of a GMT grid
	proj4::String
	wkt::String
	range::Array{Float64,1}
	inc::Array{Float64,1}
	registration::Int
	nodata::Float64
	title::String
	remark::String
	command::String
	datatype::String
	x::Array{Float64,1}
	y::Array{Float64,1}
	z::Array{Float32,2}
	x_unit::String
	y_unit::String
	z_unit::String
	layout::String
end

type GMTimage 	# The type holding a local header and data of a GMT image
	proj4::String
	wkt::String
	range::Array{Float64,1}
	inc::Array{Float64,1}
	registration::Int
	nodata::Float64
	title::String
	remark::String
	command::String
	datatype::String
	x::Array{Float64,1}
	y::Array{Float64,1}
	image::Array{UInt8,3}
	x_unit::String
	y_unit::String
	z_unit::String
	colormap::Array{Clong,1}
	n_colors::Int
	alpha::Array{UInt8,2}
	layout::String
end

type GMTcpt
	colormap::Array{Float64,2}
	alpha::Array{Float64,1}
	range::Array{Float64,2}
	minmax::Array{Float64,1}
	bfn::Array{Float64,2}
	depth::Cint
	hinge::Cdouble
	cpt::Array{Float64,2}
	model::String
	comment::Array{Any,1}		# Cell array with any comments
end

type GMTps
	postscript::String			# Actual PS plot (text string)
	length::Int 				# Byte length of postscript
	mode::Int 					# 1 = Has header, 2 = Has trailer, 3 = Has both
	comment::Array{Any,1}		# Cell array with any comments
end

type GMTdataset
	header::String
	data::Array{Float64,2}
	text::Array{Any,1}
	comment::Array{Any,1}
	proj4::String
	wkt::String
	GMTdataset(header, data, text, comment, proj4, wkt) = new(header, data, text, comment, proj4, wkt)
	GMTdataset() = new(string(), Array{Float64,2}(), Array{String,1}(), Array{String,1}(), string(), string())
end

# Container to hold info to allow creating grids in a simple (but limmited) maner
type ArrayContainer
	nx::Int
	ny::Int
	n_bands::Int
	grd::Ptr{Float32}
	hdr::Ptr{Float64}
end

"""
Call a GMT module. Usage:

    gmt("module_name `options`")

Example. To plot a simple map of Iberia in the postscript file nammed `lixo.ps` do:

    gmt("pscoast -R-10/0/35/45 -B1 -W1 -Gbrown -JM14c -P -V > lixo.ps")
"""
function gmt(cmd::String, args...)
	global API
	global grd_mem_layout = ""
	global img_mem_layout = "TCP"

	# ----------- Minimal error checking ------------------------
	if (~isa(cmd, String))
		error("gmt: first argument must always be a string")
	end
	n_argin = length(args)
	if (n_argin > 0 && isa(args[1], String))
		tok, r = strtok(cmd)
		if (isempty(r))							# User gave 'module' separately from 'options'
			cmd = cmd * " " * args[1]			# Cat it with the progname and so pretend input followed the classic construct
			args = args[2:end]
			n_argin -= 1
		end
	end
	# -----------------------------------------------------------

	try
		a = API
		if (!isa(API, Ptr{Void}))
			error("The 'API' is not a Ptr{Void}. Creating a new one.")
		end
	catch
		API = GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL
		                         + GMT.GMT_SESSION_COLMAJOR)
		if (API == C_NULL)
			error("Failure to create a GMT5 Session")
		end
	end

	# 1. Get arguments, if any, and extract the GMT module name
	# First argument is the command string, e.g., "blockmean -R0/5/0/5 -I1" or just "help"
	g_module, r = strtok(cmd)

	# 2. In case this was a clean up call or a begin/end from the modern mode
	if (g_module == "destroy")
		if (GMT_Destroy_Session(API) != 0)
			error("GMT: Failure to destroy GMT5 session")
		end
		API = NaN
		return
	elseif (g_module == "begin" || g_module == "figure" || g_module == "end")
		if (get_GMTversion(API) < 5.4)
			error("GMT: The modern mode is only available at GMT5.4 and up.")
		end
		if (g_module == "begin")
			if (GMT_Manage_Session(API, GMT.GMT_SESSION_BEGIN, NULL) != 0)
				error("GMT: Error running the 'begin' command")
			end
		elseif (g_module == "figure")
			if (GMT_Manage_Session(API, GMT.GMT_SESSION_FIGURE, convert(Ptr{Void},pointer(r))) != 0)
				error("GMT: Error running the 'figure' command")
			end
		else
			GMT_Manage_Session(API, GMT.GMT_SESSION_END, NULL)
			GMT_Destroy_Session(API)
			API = NaN
		end
		return
	end

	# Make sure this is a valid module
	if ((status = GMT_Call_Module(API, g_module, GMT_MODULE_EXIST, C_NULL)) != 0)
		error("GMT: No module by that name -- " * g_module * " -- was found.")
	end

	# 2+ Add -F to psconvert if user requested a return image but did not give -F.
	# The problem is that we can't use nargout to decide what to do, so we use -T to solve the ambiguity.
	if (g_module == "psconvert" && (isempty(r) || isempty(search(r, "-F"))) )
		if (isempty(r))
			r = "-F"
		else
			ind = search(r, "-T")
			if (isempty(ind))
				r = r * " -F"
			else								# Hmm, have to find if any of 'e' or 'f' are used as -T flags
				tok = strtok(r[ind[2]:end])		# Will have T?
				tok = lowercase(tok[1])
				if (isempty(search(tok,"e")) && isempty(search(tok,"f")))	# No any -Tef combo so add -F
					r = r * " -F"
				end
			end
		end
	end

	# 2++ Add -T to gmtwrite if user did not explicitly give -T.
	if ((searchindex(g_module,"write") != 0) && (searchindex(r,"-T") == 0) && n_argin == 1)
		if (ind = findfirst(fieldnames(args[1]), Symbol("z")) != 0)
			r = r * " -Tg"
		elseif (ind = findfirst(fieldnames(args[1]), Symbol("image")) != 0)
			r = r * " -Ti"
		elseif (ind = findfirst(fieldnames(args[1]), Symbol("data")) != 0)
			r = r * " -Td"
		elseif (ind = findfirst(fieldnames(args[1]), Symbol("postscript")) != 0)
			r = r * " -Tp"
		elseif (ind = findfirst(fieldnames(args[1]), Symbol("hinge")) != 0)
			r = r * " -Tc"
		end
	end

	# 2+++ If gmtread -Ti than temporarily set pad to 0 since we don't want padding in image arrays
	if ((searchindex(g_module,"read") != 0) && !isempty(r) && (searchindex(r,"-T") != 0))
		if (searchindex(r,"-Ti") != 0)
			GMT_Set_Default(API, "API_PAD", "0")
		end
		ind = searchindex(r, "-L")
		if (ind != 0)
			grd_mem_layout, resto = strtok(r[ind+2:end])
			r = r[1:ind-1] * " " * resto 	# Remove the -L pseudo-option because GMT would bail out
		end
	end

	# 3. Convert command line arguments to a linked GMT option list
	LL = C_NULL
	if (isempty(r))		# Just requesting usage message, so add -? to options
		r = "-?"
	end
	LL = GMT_Create_Options(API, 0, r)	# It uses also the fact that GMT parses and check options
	if (LL == C_NULL)
		error("Error creating the linked list of options. Probably a bad usage.")
	end

	# 4. Preprocess to update GMT option lists and return info array X

	# Here I have an issue that I can't resolve any better. For modules that can have no options (e.g. gmtinfo)
	# the LinkedList (LL) is actually created in GMT_Encode_Options but I can't get it's contents back when pLL
	# is a Ref, so I'm forced to use 'pointer', which goes against the documents recommendation.
	if (LL != C_NULL)
		pLL = Ref([LL])
	else
		pLL = pointer([C_NULL])
	end

	n_items = pointer([0])
	X = GMT_Encode_Options(API, g_module, n_argin, pLL, n_items)	# This call also changes LL
	n_items = unsafe_load(n_items)
	if (X == C_NULL && n_items > 65000)		# Just got usage/synopsis option (if (n_items == UINT_MAX)) in C
		n_items = 0
	elseif (X == C_NULL)
		error("GMT: Failure to encode Julia command options")
	end

	if (LL == C_NULL)		# The no-options case. Must get the LL that was created in GMT_Encode_Options
		LL = convert(Ptr{GMT.GMT_OPTION}, unsafe_load(pLL))
		pLL = Ref([LL])		# Need this because GMT_Destroy_Options() wants a Ref
	end

	XX = Array(GMT_RESOURCE, 1, n_items)
	for k = 1:n_items
		XX[k] = unsafe_load(X, k)        # Cannot use pointer_to_array() because GMT_RESOURCE is not immutable and would BOOM!
	end
	X = XX

	# 5. Assign input sources (from Julia to GMT) and output destinations (from GMT to Julia)
	name_PS = ""
	object_ID = zeros(Int32, n_items)
	for k = 1:n_items					# Number of GMT containers involved in this module call */
		if (X[k].direction == GMT_IN && n_argin == 0)
			error("GMT: Expected a Matrix for input")
		end
		ptr = (X[k].direction == GMT_IN) ? args[X[k].pos+1] : []
		GMTJL_Set_Object(API, X[k], ptr)	# Set object pointer
	end

	# 6. Run GMT module; give usage message if errors arise during parsing
	status = GMT_Call_Module(API, g_module, GMT_MODULE_OPT, LL)
	if (status != GMT_NOERROR)
		if (status == GMT_MODULE_USAGE || status == GMT_MODULE_SYNOPSIS || status == GMT_MODULE_LIST || status == GMT_MODULE_EXIST || status == GMT_MODULE_PURPOSE)
			return
		end
		error("Something went wrong when calling the module. GMT error number = ", status)
	end

	# 7. Hook up module GMT outputs to Julia array
	# But first cout the number of outputs
	n_out = 0
	for k = 1:n_items					# Number of GMT containers involved in this module call
		if (X[k].direction == GMT_IN) continue 	end
		n_out = n_out + 1
	end
	out = []
	if (n_out > 0)
		out = Array(Any, n_out)
	end

	for k = 1:n_items					# Get results from GMT into Julia arrays
		if (X[k].direction == GMT_IN) continue 	end      # Only looking for stuff coming OUT of GMT here
		out[X[k].pos+1] = GMTJL_Get_Object(API, X[k])	# Hook mex object onto rhs list
	end

	# 2++- If gmtread -Ti than reset the session's pad value that was temporarily changed above (2+++)
	if ((searchindex(g_module,"read") != 0) && !isempty(r) && (searchindex(r,"-Ti") != 0))
		GMT_Set_Default(API, "API_PAD", "2")
	end

	# 8. Free all GMT containers involved in this module call
	for k = 1:n_items
		ppp = X[k].object
		name = String([X[k].name...])				# Because X.name is a NTuple
		if (GMT_Close_VirtualFile(API, name) != 0)
			error("GMT: Failed to close virtual file")
		end
		if (GMT_Destroy_Data(API, Ref([X[k].object])) != GMT_NOERROR)
			error("Failed to destroy object used in the interface bewteen GMT and Julia")
		else 		# Success, now make sure we dont destroy the same pointer more than once
			for kk = k+1:n_items
				if (X[kk].object == ppp) 	X[kk].object = C_NULL;		end
			end
		end
	end

	# 9. Destroy linked option list
	if (GMT_Destroy_Options(API, pLL) != 0)
		@printf("GMT Warning: Failure to destroy GMT5 options")
	end

	# Return a variable number of outputs but don't think we even can return 3
	if (n_out == 0)
		return []
	elseif (n_out == 1)
		return out[1]
	elseif (n_out == 2)
		return out[1], out[2]
	elseif (n_out == 3)
		return out[1], out[2], out[3]
	else
		println("Case non-foreseen. More than 3 outputs?")
		return out
	end

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
function strtok(args, delim::String=" ")
# A Matlab like strtok function
	tok = "";	r = ""
	if (~isvalid(args))
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
function GMT_IJP(hdr::GMT_GRID_HEADER, row, col)
# Function for indecing into a GMT grid [with pad]
# padTop (hdr.pad[GMT.GMT_YHI]) and padLeft (hdr.pad[GMT.GMT_XLO]) are normally equal
	#ij = (row + hdr.pad[4]) * hdr.mx + col + hdr.pad[1]		# in C
	ij = ((row-1) + hdr.pad[4]) * hdr.mx + col + hdr.pad[1]
end

# ---------------------------------------------------------------------------------------------------
function GMT_IJP(row::Integer, col, mx, padTop, padLeft)
# Function for indecing into a GMT grid [with pad]
# padTop (hdr.pad[GMT.GMT_YHI]) and padLeft (hdr.pad[GMT.GMT_XLO]) are normally equal
	#ij = (row + padTop) * mx + col + padLeft		# in C
	ij = ((row-1) + padTop) * mx + col + padLeft
end

# ---------------------------------------------------------------------------------------------------
function MEXG_IJ(row, col, ny)
	# Get the ij that corresponds to (row,col) [no pad involved]
	#ij = col * ny + ny - row - 1		in C
	ij = col * ny - row + 1
end

# ---------------------------------------------------------------------------------------------------
function get_grid(API::Ptr{Void}, object)
# Given an incoming GMT grid G, build a Julia type and assign the output components.
# Note: Incoming GMT grid has standard padding while Julia grid has none.
	global grd_mem_layout

	G = unsafe_load(convert(Ptr{GMT_GRID}, object))
	if (G.data == C_NULL)
		error("get_grid: programming error, output matrix is empty")
	end

	gmt_hdr = unsafe_load(G.header)
	ny = Int(gmt_hdr.n_rows);		nx = Int(gmt_hdr.n_columns);		nz = Int(gmt_hdr.n_bands)
	padTop = Int(gmt_hdr.pad[4]);	padLeft = Int(gmt_hdr.pad[1]);
	mx = Int(gmt_hdr.mx);		my = Int(gmt_hdr.my)

#=	# Not yet implemented on the GMT side
	X = zeros(nx);		t = pointer_to_array(G.x, nx)
	[X[col] = t[col] for col = 1:nx]
	Y = zeros(ny);		t = pointer_to_array(G.y, ny)
	[Y[col] = t[col] for col = 1:ny]
=#
	X  = linspace(gmt_hdr.wesn[1], gmt_hdr.wesn[2], nx)
	Y  = linspace(gmt_hdr.wesn[3], gmt_hdr.wesn[4], ny)

	#API = unsafe_load(convert(Ptr{GMTAPI_CTRL}, API))	# Get access to a minimalist API struct (no API.GMT)
	t = unsafe_wrap(Array, G.data, my * mx)
	z = zeros(Float32, ny, nx)

	if (isempty(grd_mem_layout))
		for col = 1:nx
			for row = 1:ny
				#ij = GMT_IJP(gmt_hdr, row, col)
				ij = GMT_IJP(row, col, mx, padTop, padLeft)		# This one is Int64
				z[MEXG_IJ(row, col, ny)] = t[ij]	# Later, replace MEXG_IJ() by kk = col * ny - row + 1
			end
		end
	elseif (grd_mem_layout == "TR" || grd_mem_layout == "BR")	# Keep the Row Major but stored in Column Major
		ind_y = 1:ny		# Start assuming "TR"
		if (grd_mem_layout == "BR");	ind_y = ny:-1:1;	end	# Bottom up
		k = 1
		for row = ind_y
			for col = 1:nx
				ij = GMT_IJP(row, col, mx, padTop, padLeft)		# This one is Int64
				z[k] = t[ij]
				k = k + 1
			end
		end
		grd_mem_layout = ""			# Reset because this variable is global
	else
		for col = 1:nx
			for row = 1:ny
				ij = GMT_IJP(row, col, mx, padTop, padLeft)		# This one is Int64
				z[row,col] = t[ij]
			end
		end
		grd_mem_layout = ""
	end

	#t  = reshape(pointer_to_array(G.data, ny * nx), ny, nx)

	# Return grids via a float matrix in a struct
	out = GMTgrid("", "", zeros(6)*NaN, zeros(2)*NaN, 0, NaN, "", "", "", "", X, Y, z, "", "", "", "")

	if (gmt_hdr.ProjRefPROJ4 != C_NULL)
		out.proj4 = unsafe_string(gmt_hdr.ProjRefPROJ4)
	end
	if (gmt_hdr.ProjRefWKT != C_NULL)
		out.wkt = unsafe_string(gmt_hdr.ProjRefWKT)
	end

	# The following is uggly is a consequence of the clag.jl translation of fixed sixe arrays
	out.range = vec([gmt_hdr.wesn[1] gmt_hdr.wesn[2] gmt_hdr.wesn[3] gmt_hdr.wesn[4] gmt_hdr.z_min gmt_hdr.z_max])
	out.inc          = vec([gmt_hdr.inc[1] gmt_hdr.inc[2]])
	out.nodata       = gmt_hdr.nan_value
	out.registration = gmt_hdr.registration
	out.x_unit       = String(UInt8[gmt_hdr.x_unit...])
	out.y_unit       = String(UInt8[gmt_hdr.y_unit...])
	out.z_unit       = String(UInt8[gmt_hdr.z_unit...])
	#out.x_unit       = unsafe_string(UInt8[gmt_hdr.x_unit...])
	#out.y_unit       = unsafe_string(UInt8[gmt_hdr.y_unit...])
	#out.z_unit       = unsafe_string(UInt8[gmt_hdr.z_unit...])

	return out
end

# ---------------------------------------------------------------------------------------------------
function get_image(API::Ptr{Void}, object)
# Given an incoming GMT image, build a Julia type and assign the output components.
# Note: Incoming GMT image may have standard padding while Julia image has none.
	global img_mem_layout

	I = unsafe_load(convert(Ptr{GMT_IMAGE}, object))
	if (I.data == C_NULL)
		error("get_image: programming error, output matrix is empty")
	end

	gmt_hdr = unsafe_load(I.header)
	ny = Int(gmt_hdr.n_rows);		nx = Int(gmt_hdr.n_columns);		nz = Int(gmt_hdr.n_bands)

#=	# Not yet implemented on the GMT side
	X = zeros(nx);		t = pointer_to_array(I.x, nx)
	[X[col] = t[col] for col = 1:nx]
	Y = zeros(ny);		t = pointer_to_array(I.y, ny)
	[Y[col] = t[col] for col = 1:ny]
=#
	X  = linspace(gmt_hdr.wesn[1], gmt_hdr.wesn[2], nx)
	Y  = linspace(gmt_hdr.wesn[3], gmt_hdr.wesn[4], ny)

	if (!isempty(search(img_mem_layout, "TCP")))		# BIP case for Images.jl
		t  = reshape(unsafe_wrap(Array, I.data, ny * nx * nz), nz, ny, nx)
	else
		t  = reshape(unsafe_wrap(Array, I.data, ny * nx * nz), ny, nx, nz)
	end

	if (I.colormap != C_NULL)       # Indexed image has a color map (PROBABLY NEEDS TRANSPOSITION)
		n_colors = Int64(I.n_indexed_colors)
		colormap = unsafe_wrap(Array, I.colormap, n_colors * 4)
		#colormap = reshape(colormap, 4, n_colors)'
	else
		colormap = vec(zeros(Clong,1,3))	# Because we need an array
		n_colors = 0
	end

	# Return image via a uint8 matrix in a struct
	layout = join([Char(gmt_hdr.mem_layout[k]) for k=1:4])		# This is damn diabolic
	if (gmt_hdr.n_bands <= 3)
		out = GMTimage("", "", zeros(6)*NaN, zeros(2)*NaN, 0, NaN, "", "", "", "", X, Y,
	                      t, "", "", "", colormap, n_colors, zeros(UInt8,ny,nx), layout) 	# <== Ver o que fazer com o alpha
	else 			# RGB(A) image
		out = GMTimage("", "", zeros(6)*NaN, zeros(2)*NaN, 0, NaN, "", "", "", "", X, Y,
	                      t[:,:,1:3], "", "", "", colormap, n_colors, t[:,:,4], layout)
	end
	I.alloc_mode = GMT.GMT_ALLOC_EXTERNALLY;	# So that GMT's Garbageman does not free I.data
	unsafe_store!(convert(Ptr{GMT_IMAGE}, object), I)

	if (gmt_hdr.ProjRefPROJ4 != C_NULL)
		out.proj4 = unsafe_string(gmt_hdr.ProjRefPROJ4)
	end
	if (gmt_hdr.ProjRefWKT != C_NULL)
		out.ProjRefWKT = unsafe_string(gmt_hdr.ProjRefWKT)
	end

	out.range = vec([gmt_hdr.wesn[1] gmt_hdr.wesn[2] gmt_hdr.wesn[3] gmt_hdr.wesn[4] gmt_hdr.z_min gmt_hdr.z_max])
	out.inc          = vec([gmt_hdr.inc[1] gmt_hdr.inc[2]])
	out.nodata       = gmt_hdr.nan_value
	out.registration = gmt_hdr.registration

	return out
end

# ---------------------------------------------------------------------------------------------------
function get_palette(API::Ptr{Void}, object::Ptr{Void})
# Given a GMT CPT C, build a Julia type and assign values.
# Each segment will have 10 items:
# colormap:	Nx3 array of colors usable in Matlab' colormap
# alpha:	Nx1 array with transparency values
# range:	Nx1 arran with z-values at color changes
# minmax:	2x1 array with min/max zvalues
# bfn:		3x3 array with colors for background, forground, nan
# depth	Color depth 24, 8, 1
# hinge:	Z-value at discontinuous color break, or NaN
# cpt:		Nx6 full GMT CPT array
# model:	String with color model rgb, hsv, or cmyk [rgb]
# comment:	Cell array with any comments

	C = unsafe_load(convert(Ptr{GMT_PALETTE}, object))

	if (C.data == C_NULL)
		error("get_palette: programming error, output CPT is empty")
	end

	if (C.model & GMT_HSV != 0)
		model = "hsv"
	elseif (C.model & GMT_CMYK != 0)
		model = "cmyk"
	else
		model = "rgb"
	end
	n_colors = (C.is_continuous != 0) ? C.n_colors + 1 : C.n_colors

	out = GMTcpt(zeros(n_colors, 3), zeros(n_colors), zeros(C.n_colors, 2), zeros(2)*NaN, zeros(3,3), 8, 0.0,
	                zeros(C.n_colors,6), model, [])

	for j = 1:C.n_colors       # Copy r/g/b from palette to Julia array
		gmt_lut = unsafe_load(C.data, j)
		for k = 1:3 	out.colormap[j, k] = gmt_lut.rgb_low[k]		end
		for k = 1:3
			out.cpt[j, k]   = gmt_lut.rgb_low[k]
			out.cpt[j, k+3] = gmt_lut.rgb_high[k]		# Not sure this is equal to the ML MEX case
		end
		out.alpha[j]       = gmt_lut.rgb_low[4]
		out.range[j, 1]    = gmt_lut.z_low
		out.range[j, 2]    = gmt_lut.z_high
	end
	if (C.is_continuous != 0)    # Add last color
		for k = 1:3 	out.colormap[n_colors, k] = gmt_lut.rgb_high[1]		end
		out.alpha[n_colors] = gmt_lut.rgb_low[4]
	end
	for j = 1:3
		for k = 1:3
			out.bfn[j,k] = C.bfn[j].rgb[k]
		end
	end
	gmt_lut = unsafe_load(C.data, 1)
	out.minmax[1] = gmt_lut.z_low
	gmt_lut = unsafe_load(C.data, C.n_colors)
	out.minmax[2] = gmt_lut.z_high
	out.depth = (C.is_bw != 0) ? 1 : ((C.is_gray != 0) ? 8 : 24)
	out.hinge = (C.has_hinge != 0) ? C.hinge : NaN;

	return out
end

# ---------------------------------------------------------------------------------------------------
function get_textset_(API::Ptr{Void}, object::Ptr{Void})
# Given a GMT GMT_TEXTSET T, build a Julia array of segment structure and assign values.
# Each segment will have 6 items:
# header:	Text string with the segment header (could be empty)
# data:	Matrix with any converted data for this segment (n_rows by n_columns)
# text:	Cell array with the text items
# comment:	Cell array with any comments
# proj4:	String with any proj4 information
# wkt:		String with any WKT information

	if (object == C_NULL)	error("programming error, textset is NULL")		end

	T = unsafe_load(convert(Ptr{GMT_TEXTSET}, object))		# GMT_TEXTSET
	flag = [GMT.GMT_LAX_CONVERSION, 0, 0]
	n_columns = 0
	have_numerical = false

	D = GMT_Convert_Data(API, object, GMT_IS_TEXTSET, NULL, GMT_IS_DATASET, Ref(pointer(flag)))		# Ptr{Void}

	if (D != NULL)											# Ptr{GMT_DATASET}
		DS = unsafe_load(convert(Ptr{GMT_DATASET}, D))		# GMT_DATASET
		Dtab = unsafe_load(unsafe_load(DS.table))			# GMT_DATATABLE
		Dseg = unsafe_load(unsafe_load(Dtab.segment))		# GMT_DATASEGMENT
		pCols = pointer_to_array(Dseg.data, DS.n_columns)	# Pointer to the columns
		for col = 1:DS.n_columns							# Now determine number of non-NaN columns from first row
			if (!isnan(unsafe_load(pCols[col])))
				n_columns = n_columns + 1
			end
		end
		have_numerical = true
	end

	seg_out = 0
	for tbl = 1:T.n_tables
		Ttab = unsafe_load(unsafe_load(T.table), tbl)	# GMT.GMT_TEXTTABLE
		for seg = 1:Ttab.n_segments
			Ttab_Seg = unsafe_load(unsafe_load(Ttab.segment), seg)		# GMT_TEXTSEGMENT
			if (Ttab_Seg.n_rows > 0)
				seg_out = seg_out + 1
			end
		end
	end

	Ttab_1 = unsafe_load(unsafe_load(T.table), 1)
	n_headers = Ttab_1.n_headers

	Darr = [GMTdataset() for i = 1:seg_out]			# Create the array of DATASETS

	seg_out = 1
	Tab = unsafe_wrap(Array, T.table, T.n_tables)		# D.n_tables-element Array{Ptr{GMT.GMT_DATATABLE},1}
	for tbl = 1:T.n_tables
		Ttab = unsafe_load(unsafe_load(T.table), tbl)	# GMT.GMT_TEXTTABLE
		for seg = 1:Ttab.n_segments
			Ttab_Seg = unsafe_load(unsafe_load(Ttab.segment), seg)		# GMT_TEXTSEGMENT
			if (Ttab_Seg.n_rows == 0)	continue 	end # Skip empty segments

			if (have_numerical)							# We have numerial data to consider
				Dtab_Seg = unsafe_load(unsafe_load(Dtab.segment), seg)	# Shorthand to the corresponding data segment
				dest = zeros(Ttab_Seg.n_rows, n_columns)
				for col = 1:n_columns					# Copy the data columns
					unsafe_copy!(pointer(dest, Ttab_Seg.n_rows * (col - 1) + 1), unsafe_load(Dtab_Seg.data, col), Ttab_Seg.n_rows)
				end
				Darr[seg].data = dest
			end

			if (!have_numerical)
				dest = Array(Any,Ttab_Seg.n_rows)
				for row = 1:Ttab_Seg.n_rows
					t = unsafe_load(Ttab_Seg.data, row)	# Ptr{UInt8}
					dest[row] = unsafe_string(t)
				end
				Darr[seg_out].text = dest
			end

			#headers = pointer_to_array(Ttab_1.header, Ttab_1.n_headers)	# n_headers-element Array{Ptr{UInt8},1}
			headers = unsafe_wrap(Array, Ttab_1.header, Ttab_1.n_headers)	# n_headers-element Array{Ptr{UInt8},1}
			dest = Array(Any,length(headers))
			for k = 1:n_headers
				dest[k] = unsafe_string(headers[k])
			end
			Darr[seg_out].comment = dest

			seg_out = seg_out + 1
		end
	end

	if (have_numerical && GMT_Destroy_Data(API, Ref([D])) != 0)
		println("Warning: Failure to delete intermediate D in GMTMEX_Get_Textset\n")
	end

	return Darr
end

# ---------------------------------------------------------------------------------------------------
function get_textset(API::Ptr{Void}, object::Ptr{Void})
# Hook this Julia TEXTSET into the k'th output item

	if (object == C_NULL)
		error("programming error, textset is NULL")
	end

	t = [GMT.GMT_STRICT_CONVERSION, 0, 0]
	if ((V = GMT_Convert_Data(API, object, GMT.GMT_IS_TEXTSET, C_NULL, GMT.GMT_IS_VECTOR, Ref(pointer(t)))) != C_NULL)
		C = get_dataset(API, V)
		return C
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
	for seg = 1:p[1].n_segments
		S = pointer_to_array(pointer_to_array(p[1].segment,1)[seg],seg)	# p[1].segment::Ptr{Ptr{GMT.GMT_TEXTSEGMENT}}
		if (p[1].n_segments > 1)
			C[k] = @sprintf("> %s", unsafe_string(S[1].header))
			k += 1
		end
		for row = 1:S[1].n_rows
			k += 1
			C[k] = unsafe_string(pointer_to_array(S[1].data, row)[row])
		end
	end

	return C
end

# ---------------------------------------------------------------------------------------------------
function get_PS(API::Ptr{Void}, object::Ptr{Void})
# Given a GMT Postscript structure P, build a Julia PS type
# Each segment will have 4 items:
# postscript:	Text string with the entire PostScript plot
# length:	Byte length of postscript
# mode:	1 has header, 2 has trailer, 3 is complete
# comment:	Cell array with any comments
	if (object == C_NULL)
		error("get_palette: programming error, output textset is NULL")
	end

	P = unsafe_load(convert(Ptr{GMT_POSTSCRIPT}, object))
	out = GMTps(unsafe_string(P.data), Int(P.n_bytes), Int(P.mode), [])	# NEED TO FILL THE COMMENT

	return out
end

# ---------------------------------------------------------------------------------------------------
function get_dataset_(API::Ptr{Void}, object)
# Given a GMT DATASET D, build an array of segment structure and assign values.
# Each segment will have 6 items:
# header:	Text string with the segment header (could be empty)
# data:	Matrix with the data for this segment (n_rows by n_columns)
# text:	Empty cell array (since datasets have no text)
# comment:	Cell array with any comments
# proj4:	String with any proj4 information
# wkt:		String with any WKT information

	D = unsafe_load(convert(Ptr{GMT_DATASET}, object))
	if (D == C_NULL || D.n_segments == 0)
		error("programming error, input Dataset is empty")
	end

	seg_out = 0
	for tbl = 1:D.n_tables
		T = unsafe_wrap(Array, D.table, tbl)
		DT = unsafe_load(T[tbl])
		for seg = 1:DT.n_segments
			S  = unsafe_wrap(Array, DT.segment, seg)
			DS = unsafe_load(S[seg])
			if (DS.n_rows != 0)
				seg_out = seg_out + 1
			end
		end
	end

	Darr = [GMTdataset() for i = 1:seg_out]			# Create the array of DATASETS

	seg_out = 1
	T = unsafe_wrap(Array, D.table, D.n_tables)			# D.n_tables-element Array{Ptr{GMT.GMT_DATATABLE},1}
	for tbl = 1:D.n_tables
		DT = unsafe_load(T[tbl])						# GMT.GMT_DATATABLE
		S = unsafe_wrap(Array, DT.segment, DT.n_segments)# n_segments-element Array{Ptr{GMT.GMT_DATASEGMENT},1}
		for seg = 1:DT.n_segments
			DS = unsafe_load(S[seg])					# GMT.GMT_DATASEGMENT
			if (DS.n_rows == 0) continue 	end			# Skip empty segments

			C = unsafe_wrap(Array, DS.data, DS.n_columns)	# DS.data = Ptr{Ptr{Float64}}; C = Array{Ptr{Float64},1}
			dest = zeros(Float64, DS.n_rows, DS.n_columns)
			for col = 1:DS.n_columns					# Copy the data columns
				unsafe_copy!(pointer(dest, DS.n_rows * (col - 1) + 1), unsafe_load(DS.data, col), DS.n_rows)
			end
			Darr[seg_out].data = dest

			if (DS.header != C_NULL)	Darr[seg_out].header = unsafe_string(DS.header)	end
			if (seg == 1)
				#headers = pointer_to_array(DT.header, DT.n_headers)	# n_headers-element Array{Ptr{UInt8},1}
				headers = unsafe_wrap(Array, DT.header, DT.n_headers)	# n_headers-element Array{Ptr{UInt8},1}
				dest = Array(Any,length(headers))
				for k = 1:length(headers)
					dest[k] = unsafe_string(headers[k])
				end
				Darr[seg_out].comment = dest
			end
			seg_out = seg_out + 1
		end
	end

	return Darr
end

# ---------------------------------------------------------------------------------------------------
function get_dataset(API::Ptr{Void}, object)
# Given an incoming GMT dataset via vectors, build a matrix and assign values per column

	V = unsafe_load(convert(Ptr{GMT_VECTOR}, object))
	if (V.data == C_NULL)
		error("programming error, input Dataset is NULL")
	end
	if (V.data == C_NULL)
		error("programming error, input Dataset empty")
	end

	tipo = GMTJL_type(API)
	if (tipo == DOUBLE_CLASS)
		out = zeros(Float64, V.n_rows, V.n_columns)
		t = pointer_to_array(convert(Ptr{Ptr{Cdouble}},V.data), V.n_columns)
	elseif (tipo == SINGLE_CLASS)
		out = zeros(Float32, V.n_rows, V.n_columns)
		t = pointer_to_array(convert(Ptr{Ptr{Cfloat}},V.data), V.n_columns)
	elseif (tipo == UINT64_CLASS)
		out = zeros(Culonglong, V.n_rows, V.n_columns)
		t = pointer_to_array(convert(Ptr{Ptr{Culonglong}},V.data), V.n_columns)
	elseif (tipo == INT64_CLASS)
		out = zeros(Clonglong, V.n_rows, V.n_columns)
		t = pointer_to_array(convert(Ptr{Ptr{Clonglong}},V.data), V.n_columns)
	elseif (tipo == UINT32_CLASS)
		out = zeros(Cuint, V.n_rows, V.n_columns)
		t = pointer_to_array(convert(Ptr{Ptr{Cuint}},V.data), V.n_columns)
	elseif (tipo == INT32_CLASS)
		out = zeros(Cint, V.n_rows, V.n_columns)
		t = pointer_to_array(convert(Ptr{Ptr{Cint}},V.data), V.n_columns)
	elseif (tipo == UINT16_CLASS)
		out = zeros(Cushort, V.n_rows, V.n_columns)
		t = pointer_to_array(convert(Ptr{Ptr{Cushort}},V.data), V.n_columns)
	elseif (tipo == INT16_CLASS)
		out = zeros(Cshort, V.n_rows, V.n_columns)
		t = pointer_to_array(convert(Ptr{Ptr{Cshort}},V.data), V.n_columns)
	elseif (tipo == UINT8_CLASS)
		out = zeros(Cuchar, V.n_rows, V.n_columns)
		t = pointer_to_array(convert(Ptr{Ptr{Cuchar}},V.data), V.n_columns)
	elseif (tipo == INT8_CLASS)
		out = zeros(Cchar, V.n_rows, V.n_columns)
		t = pointer_to_array(convert(Ptr{Ptr{Cchar}},V.data), V.n_columns)
	else
		error("get_dataset: Unsupported data type in GMT matrix input.")
	end

	for c = 1:V.n_columns
		tt = pointer_to_array(t[c], V.n_rows)
		for r = 1:V.n_rows
			out[r, c] = tt[r]
		end
	end

#=
	out = zeros(Float64, V.n_rows, V.n_columns)
	if (V.shape == GMT.GMT_IS_COL_FORMAT)  # Easy, just copy
		out = copy!(out, t)
	else	# Must transpose
		for col = 1:V.n_columns
			for row = 1:V.n_rows
				#ij = (row - 1) * V.n_columns + col
				ij = (col - 1) * V.n_rows + col
				out[row, col] = t[ij]
			end
		end
	end
=#

	return out
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_Set_Object(API::Ptr{Void}, X::GMT_RESOURCE, ptr)
	# Create the object container and hook as X->object
	name = Any["Matrix", "CellArray"]
	oo = unsafe_load(X.option)
	module_input = (oo.option == GMT.GMT_OPT_INFILE)

	if (X.family == GMT_IS_GRID)			# Get a grid from Julia or a dummy one to hold GMT output
		X.object =  grid_init(API, module_input, ptr, X.direction)
		GMT_Report(API, GMT_MSG_DEBUG, "GMTMEX_Set_Object: Got Grid\n")
	elseif (X.family == GMT_IS_IMAGE)		# Get an image from Julia or a dummy one to hold GMT output
		X.object = image_init(API, module_input, ptr, X.direction)
		GMT_Report(API, GMT_MSG_DEBUG, "GMTMEX_Set_Object: Got Image\n");
	elseif (X.family == GMT_IS_DATASET)		# Get a dataset from Julia or a dummy one to hold GMT output
		# Ostensibly a DATASET, but it might be a TEXTSET passed via a cell array, so we must check
		if (X.direction == GMT_IN && (isa(ptr, Array{Any}) || (eltype(ptr) == String)))	# Got text input
			X.object = text_init_(API, module_input, ptr, X.direction, GMT_IS_TEXTSET)
			X.family = GMT_IS_TEXTSET
		else		# Got something for which a dataset container is appropriate
			X.object = dataset_init_(API, module_input, ptr, X.direction)
		end
		GMT_Report(API, GMT_MSG_DEBUG, @sprintf("GMTMEX_Set_Object: Got %s\n", name[X.family+1]))
	elseif (X.family == GMT_IS_TEXTSET)		# Get a textset from Julia or a dummy one to hold GMT output
		X.object = text_init_(API, module_input, ptr, X.direction, GMT_IS_TEXTSET)
		GMT_Report(API, GMT_MSG_DEBUG, "GMTMEX_Set_Object: Got TEXTSET\n")
	elseif (X.family == GMT_IS_PALETTE)		# Get a palette from Julia or a dummy one to hold GMT output
		X.object = palette_init(API, module_input, ptr, X.direction)
		GMT_Report(API, GMT_MSG_DEBUG, "GMTMEX_Set_Object: Got CPT\n")
	elseif (X.family == GMT_IS_POSTSCRIPT)	# Get a PostScript struct from Matlab or a dummy one to hold GMT output
		X.object = ps_init(API, module_input, ptr, X.direction)
		GMT_Report(API, GMT_MSG_DEBUG, "GMTMEX_Set_Object: Got POSTSCRIPT\n")
	else
		GMT_Report(API, GMT_MSG_NORMAL, @sprintf("GMTMEX_Set_Object: Bad data type (%d)\n", X.family))
	end
	if (X.object == NULL)	error("GMT: Failure to register the resource")	end

	name = String([X.name...])
	if (GMT_Open_VirtualFile(API, X.family, X.geometry, X.direction, X.object, name) != GMT_NOERROR) # Make filename with embedded object ID */
		error("GMT: Failure to open virtual file")
	end
	if (GMT_Expand_Option(API, X.option, name) != GMT_NOERROR)	# Replace ? in argument with name
		error("GMT: Failure to expand filename marker (?)")
	end
	X.name = map(UInt8, (name...))

	return X
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_Get_Object(API::Ptr{Void}, X::GMT_RESOURCE)
	#name = unsafe_string([X.name...])			# Because X.name is a NTuple
	name = String([X.name...])
	if ((X.object = GMT_Read_VirtualFile(API, name)) == NULL)
		error(@sprintf("GMT: Error reading virtual file %s from GMT", name))
	end
	if (X.family == GMT_IS_GRID)         	# A GMT grid; make it the pos'th output item
		ptr = get_grid(API, X.object)
	elseif (X.family == GMT_IS_DATASET)		# A GMT table; make it a matrix and the pos'th output item
		ptr = get_dataset_(API, X.object)
	elseif (X.family == GMT_IS_TEXTSET)		# A GMT textset; make it a cell and the pos'th output item
		ptr = get_textset_(API, X.object)
	elseif (X.family == GMT_IS_PALETTE)		# A GMT CPT; make it a colormap and the pos'th output item
		ptr = get_palette(API, X.object)
	elseif (X.family == GMT_IS_IMAGE)		# A GMT Image; make it the pos'th output item
		ptr = get_image(API, X.object)
	elseif (X.family == GMT_IS_POSTSCRIPT)	# A GMT PostScript string; make it the pos'th output item
		ptr = get_PS(API, X.object)
#		status = GMT_Call_Module(API, "psconvert", GMT_MODULE_CMD, "# -A -Tg")
#		status = GMT_Call_Module(API, "psconvert", GMT_MODULE_CMD, name_PS * " -A -Tf")
	else
		error("GMT: Internal Error - unsupported data type\n");
	end
	return ptr
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_register_IO(API::Ptr{Void}, X::GMT_RESOURCE, ptr)
# Create the grid or matrix containers, register them, and return the ID
	oo = unsafe_load(X.option)
	module_input = (oo.option == GMT.GMT_OPT_INFILE)
	ID = GMT.GMT_NOTSET
	if (X.family == GMT_IS_GRID)
		# Get an empty grid, and if input associate it with the Julia grid pointer
		obj = grid_init(API, module_input, ptr, X.direction)
		ID  = GMT_Get_ID(API, GMT_IS_GRID, X.direction, obj)
	elseif (X.family == GMT_IS_IMAGE)
		obj = image_init(API, module_input, ptr, X.direction)
		ID  = GMT_Get_ID(API, GMT_IS_IMAGE, X.direction, obj)
	elseif (X.family == GMT_IS_DATASET)
		# Ostensibly a DATASET, but it might be a TEXTSET passed via a cell array, so we must check
		if (X.direction == GMT_IN && ((eltype(ptr) == Array{Any}) || (eltype(ptr) == String)))		# Got TEXTSET input
			obj = text_init_(API, module_input, ptr, X.direction, GMT_IS_TEXTSET)
		else 		# Get a matrix container, and if input we associate it with the Julia pointer
			obj = dataset_init_(API, module_input, ptr, X.direction)
		end
		ID  = GMT_Get_ID(API, GMT_IS_DATASET, X.direction, obj)
	elseif (X.family == GMT_IS_PALETTE)
		# Get a CPT container, and if input associate it with the Julia CPT pointer
		obj = palette_init(API, module_input, ptr, X.direction)
		ID  = GMT_Get_ID(API, GMT_IS_PALETTE, X.direction, obj)
	elseif (X.family == GMT_IS_TEXTSET)
		# Get a TEXTSET container, and if input associate it with the Julia pointer
		obj = text_init_(API, module_input, ptr, X.direction, GMT_IS_TEXTSET)
		ID  = GMT_Get_ID(API, GMT_IS_TEXTSET, X.direction, obj)
	elseif (X.family == GMT_IS_POSTSCRIPT)
		obj = ps_init(API, module_input, ptr, X.direction)
		ID  = GMT_Get_ID(API, GMT_IS_POSTSCRIPT, X.direction, obj)
	else
		error("GMTJL_register_IO: Bad data type ", X.family)
	end
	return obj, ID
end

# ---------------------------------------------------------------------------------------------------
function grid_init(API::Ptr{Void}, module_input, grd_box, dir::Integer=GMT_IN)
# If GRD_BOX is empty just allocate (GMT) an empty container and return
# If GRD_BOX is not empty it must contain either a ArrayContainer or a GMTgrid type.

	empty = false 		# F... F... it's a shame having to do this
	try
		isempty(grd_box)
		empty = true
	end

	if (empty)			# Just tell grid_init() to allocate an empty container
		GMT_CREATE_MODE = 0
		if (get_GMTversion(API) > 5.3)	GMT_CREATE_MODE = GMT_IS_OUTPUT;	end
		if ((R = GMT_Create_Data(API, GMT_IS_GRID, GMT_IS_SURFACE, GMT_CREATE_MODE,
		                         C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("Failure to alloc GMT blank grid container for holding output grid")
		end
		return R
	end

	if (isa(grd_box, ArrayContainer))
		grd = pointer_to_array(grd_box.grd, (grd_box.ny, grd_box.nx))
		hdr = pointer_to_array(grd_box.hdr, 9)
		R = grid_init(API, module_input, [], grd, hdr)
	elseif (isa(grd_box, GMTgrid))
		R = grid_init(API, module_input, grd_box, [], [])
	else
		error(@sprintf("GMTJL_PARSER:grd_init: input (%s) is not a GRID|IMAGE container type", typeof(grd_box)))
	end
	return R
end

# ---------------------------------------------------------------------------------------------------
function grid_init(API::Ptr{Void}, module_input, Grid, grd, hdr, pad::Int=2)
# We are given a Julia grid and can determine its size, etc.

	if (isa(Grid, GMTgrid))
		grd = Grid.z
		hdr = [Grid.range; Grid.registration; Grid.inc]
	end
	if ((G = GMT_Create_Data(API, GMT_IS_GRID, GMT_IS_SURFACE, GMT_GRID_ALL, C_NULL,
	                         hdr[1:4], hdr[8:9], UInt32(hdr[7]), pad)) == C_NULL)
		error("grid_init: Failure to alloc GMT source matrix for input")
	end

	n_rows = size(grd, 1);		n_cols = size(grd, 2);		mx = n_cols + 2*pad;
	Gb = unsafe_load(G)			# Gb = GMT_GRID (constructor with 1 method)
	h = unsafe_load(Gb.header)
	t = unsafe_wrap(Array, Gb.data, h.size)

	for col = 1:n_cols
		for row = 1:n_rows
			ij = GMT_IJP(row, col, mx, pad, pad)
			t[ij] = grd[MEXG_IJ(row, col, n_rows)]	# Later, replace MEXG_IJ() by kk = col * ny - row + 1
		end
	end

	h.z_min = hdr[5]			# Set the z_min, z_max
	h.z_max = hdr[6]

	if (isa(Grid, GMTgrid))
		h.x_unit = map(UInt8, (Grid.x_unit...))
		h.y_unit = map(UInt8, (Grid.y_unit...))
		h.z_unit = map(UInt8, (Grid.z_unit...))
	end

	unsafe_store!(Gb.header, h)
	unsafe_store!(G, Gb)
	GMT_Report(API, GMT.GMT_MSG_DEBUG, @sprintf("Allocate GMT Grid %s in parser\n", G))

	return G
end

# ---------------------------------------------------------------------------------------------------
function image_init(API::Ptr{Void}, module_input, img_box, dir::Integer=GMT_IN)
	# ...
	global img_mem_layout

	empty = false 		# F... F... it's a shame having to do this
	try
		isempty(img_box)
		empty = true
	end

	if (empty)			# Just tell image_init() to allocate an empty container
		GMT_CREATE_MODE = 0
		if (get_GMTversion(API) > 5.3)	GMT_CREATE_MODE = GMT_IS_OUTPUT;	end
		if ((I = GMT_Create_Data(API, GMT_IS_IMAGE, GMT_IS_SURFACE, GMT_CREATE_MODE,
		                         C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("image_init: Failure to alloc GMT blank grid container for holding output image")
		end
		if (!isempty(img_mem_layout))
			GMT_Set_Default(API, "API_IMAGE_LAYOUT", img_mem_layout * "a");		# State how we wish to receive images from GDAL
		end
		return I
	end

	if (isa(img_box, ArrayContainer))
		img = pointer_to_array(img_box.grd, (img_box.ny, img_box.nx, img_box.n_bands))
		hdr = pointer_to_array(img_box.hdr, 9)
		I = image_init(API, img, hdr)
	elseif (isa(img_box, GMTimage))
		#img = img_box.image
		#hdr = [img_box.range; img_box.registration; img_box.inc]
		I = image_init(API, img_box)
	else
		error("GMTJL_PARSER:image_init: input is not a IMAGE container type")
	end
	return I
end

# ---------------------------------------------------------------------------------------------------
function image_init(API::Ptr{Void}, Img::GMTimage, pad::Int=0)
#
	n_rows = size(Img.image, 1);		n_cols = size(Img.image, 2);		n_pages = size(Img.image, 3)
	dim = pointer([n_cols, n_rows, n_pages])
	if ((I = GMT_Create_Data(API, GMT_IS_IMAGE, GMT_IS_SURFACE, GMT_GRID_ALL, dim,
	                         C_NULL, C_NULL, UInt32(Img.registration), pad)) == C_NULL)
		error("image_init: Failure to alloc GMT source image for input")
	end
	Ib = unsafe_load(I)			# Ib = GMT_IMAGE (constructor with 1 method)

	Ib.data = pointer(Img.image)
	Ib.alloc_mode = UInt32(GMT.GMT_ALLOCATED_EXTERNALLY)	# Since array was allocated by Julia
	h = unsafe_load(Ib.header)
	h.z_min = Img.range[5]			# Set the z_min, z_max
	h.z_max = Img.range[6]
	h.mem_layout = map(UInt8, (Img.layout...))
	unsafe_store!(Ib.header, h)
	unsafe_store!(I, Ib)
	GMT_Report(API, GMT.GMT_MSG_DEBUG, @sprintf("Allocate GMT Image %s in parser\n", I))

	return I
end

# ---------------------------------------------------------------------------------------------------
function image_init(API::Ptr{Void}, img, hdr::Array{Float64}, pad::Int=0)
# Used to Create an empty Image container to hold a GMT image.
# We are given a Julia image and can determine its size, etc.
	global img_mem_layout

	n_rows = size(img, 1);		n_cols = size(img, 2);		n_pages = size(img, 3)
	dim = pointer([n_cols, n_rows, n_pages])
	if ((I = GMT_Create_Data(API, GMT_IS_IMAGE, GMT_IS_SURFACE, GMT_GRID_ALL, dim,
	                         C_NULL, C_NULL, UInt32(hdr[7]), pad)) == C_NULL)
		error("image_init: Failure to alloc GMT source image for input")
	end
	Ib = unsafe_load(I)			# Ib = GMT_IMAGE (constructor with 1 method)

#=
	t = zeros(UInt8, n_rows, n_cols, n_pages)
	for col = 1:n_cols
		ic = col * n_rows
		for row = 1:n_rows
			ij = ic - row + 1
			t[row, col] = img[ij]
		end
	end
	Ib.data = pointer(t)
=#

	Ib.data = pointer(img)
	Ib.alloc_mode = UInt32(GMT.GMT_ALLOCATED_EXTERNALLY)		# Since array was allocated by Julia
	h = unsafe_load(Ib.header)
	h.z_min = hdr[5]			# Set the z_min, z_max
	h.z_max = hdr[6]
	if (!isempty(img_mem_layout))
		h.mem_layout = map(UInt8, (img_mem_layout * "a"...))	# The memory layout order
	end
	unsafe_store!(Ib.header, h)
	unsafe_store!(I, Ib)
	GMT_Report(API, GMT.GMT_MSG_DEBUG, @sprintf("Allocate GMT Image %s in parser\n", I))

	return I
end

# ---------------------------------------------------------------------------------------------------
function matrix_init(API::Ptr{Void}, module_input, grd, dir::Integer=GMT_IN, pad::Int=0)
# ...
	if (dir == GMT_IN)
		dim = pointer([size(grd,2), size(grd,1), 0])	# MATRIX in GMT uses (col,row)
		mode = 0;
	else
		dim = C_NULL
		mode = GMT_VIA_OUTPUT;
	end

	if ((M = GMT_Create_Data(API, GMT_IS_MATRIX, GMT_IS_PLP, mode, dim, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
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
			Mb._type = UInt32(GMT.GMT_DOUBLE)
		elseif (eltype(grd) == Float32)
			Mb._type = UInt32(GMT.GMT_FLOAT)
		else
			error("only floating point types allowed in input. Others need to be added")
		end
		Mb.data  = pointer(grd)
		Mb.dim = Mb.n_rows		# Data from Julia is in column major
		Mb.alloc_mode = GMT.GMT_ALLOC_EXTERNALLY;	# Since matrix was allocated by Julia
		Mb.shape = GMT.GMT_IS_COL_FORMAT;		# Julia order is column major */

	else
		Mb._type = UInt32(GMT.GMT_FLOAT)		# PROVIDE A MEAN TO CHOOSE?
		if (~isempty(grd))
			Mb.data  = pointer(grd)
		end
		# Data from GMT must be in row format since we may not know n_rows until later
		Mb.shape = UInt32(GMT.GMT_IS_ROW_FORMAT)
	end

	unsafe_store!(M, Mb)
	return M
end

# ---------------------------------------------------------------------------------------------------
function dataset_init_(API::Ptr{Void}, module_input, Darr, direction::Integer)
# Create containers to hold or receive data tables:
# direction == GMT_IN:  Create empty GMT_DATASET container, fill from Julia, and use as GMT input.
#	Input from Julia may be a structure or a plain matrix
# direction == GMT_OUT: Create empty GMT_DATASET container, let GMT fill it out, and use for Mex output.
# If direction is GMT_IN then we are given a Julia struct and can determine dimension.
# If output then we dont know size so we set dimensions to zero.

	if (direction == GMT_OUT)
		GMT_CREATE_MODE = 0
		if (get_GMTversion(API) > 5.3)	GMT_CREATE_MODE = GMT_IS_OUTPUT;	end
		if ((D = GMT_Create_Data(API, GMT_IS_DATASET, GMT_IS_PLP, GMT_CREATE_MODE, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("Failure to alloc GMT source Dataset\n")
		end
		GMT_Report(API, GMT_MSG_DEBUG, @sprintf("dataset_init_: Allocated GMT Dataset %s\n", D))
		return D
	end

	if (Darr == C_NULL) error("Input is empty where it can't be.")	end
	#if (!((eltype(Darr) == Array{Any}) || (eltype(Darr) == String)))	# Got a matrix as input, pass data pointers via MATRIX to save memory
	if (isa(Darr, GMTdataset))	Darr = [Darr]	end 	# So the remaining algorithm works for all cases
	if (!(isa(Darr, Array{GMTdataset,1})))	# Got a matrix as input, pass data pointers via MATRIX to save memory
		D = dataset_init(API, module_input, Darr, direction)
		return D
	end
	# We come here if we did not receive a matrix
	#if (!isa(Darr, GMTdataset)) error("Expected a GMTdataset type for input")	end
	dim = [1, 0, 0, 0]
	dim[GMT.GMT_SEG+1] = length(Darr)					# Number of segments
	if (dim[GMT.GMT_SEG+1] == 0)	error("Input has zero segments where it can't be")	end
	if (length(Darr[1].data) == 0)	error("The 'data' array is NULL where it can't be")	end
	dim[GMT.GMT_COL+1] = size(Darr[1].data, 2)		# Number of columns
	if (dim[GMT.GMT_COL+1] == 0) error("Input has zero columns where it can't be.")	end

	pdim = pointer(dim)
	if ((D = GMT_Create_Data(API, GMT_IS_DATASET, GMT_IS_PLP, 0, pdim, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
		error("Failure to alloc GMT destination dataset")
	end
	DS = unsafe_load(convert(Ptr{GMT_DATASET}, D))
	GMT_Report(API, GMT_MSG_DEBUG, @sprintf("dataset_init_: Allocated GMT dataset %s\n", D))

	DT = unsafe_load(unsafe_load(DS.table))				# GMT.GMT_DATATABLE

	n_records = 0
	for seg = 1:dim[GMT.GMT_SEG+1] 						# Each incoming structure is a new data segment
		dim[GMT.GMT_ROW+1] = size(Darr[seg].data, 1)	# Number of rows in matrix
		DSv = convert(Ptr{Void}, unsafe_load(DT.segment, seg))		# DT.segment = Ptr{Ptr{GMT.GMT_DATASEGMENT}}
		S = GMT_Alloc_Segment(API, GMT_IS_DATASET, dim[GMT.GMT_ROW+1], dim[GMT.GMT_COL+1], Darr[seg].header, DSv) # Ptr{GMT_DATASEGMENT}
		Sb = unsafe_load(S)								# GMT_DATASEGMENT;		Sb.data -> Ptr{Ptr{Float64}}
		for col = 1:Sb.n_columns						# Copy the data columns
			#unsafe_store!(Sb.data, pointer(Darr[seg].data[:,col]), col)	# This would allow shared mem
			unsafe_copy!(unsafe_load(Sb.data, col), pointer(Darr[seg].data[:,col]), Sb.n_rows)
		end
		n_records += Sb.n_rows							# Must manually keep track of totals
		if (seg == 1 && length(Darr[1].comment) > 0)	# First segment may have table information
			for k = 1:size(Darr[1].comment,1)
				if (GMT_Set_Comment(API, GMT_IS_DATASET, GMT_COMMENT_IS_TEXT, convert(Ptr{Void}, pointer(Darr[1].comment[k])),
				                    convert(Ptr{Void}, D)) != 0)
					println("dataset_init_: Failed to set a dataset header")
				end
			end
		end
		unsafe_store!(S, Sb)
		unsafe_store!(DT.segment, S, seg)
	end
	DT.n_records = n_records
	DS.n_records = n_records

	return D
end

# ---------------------------------------------------------------------------------------------------
function dataset_init(API::Ptr{Void}, module_input, ptr, direction::Integer)
# Used to create containers to hold or receive data:
# direction == GMT_IN:  Create empty Matrix container, associate it with mex data matrix, and use as GMT input.
# direction == GMT_OUT: Create empty Vector container, let GMT fill it out, and use for Mex output.
# Note that in GMT these will be considered DATASETs via GMT_MATRIX or GMT_VECTOR.
# If direction is GMT_IN then we are given a Julia matrix and can determine size, etc.
# If output then we dont know size so all we do is specify data type.

	if (direction == GMT_IN) 	# Dimensions are known, extract them and set dim array for a GMT_MATRIX resource */
		dim = pointer([size(ptr,2), size(ptr,1), 0])	# MATRIX in GMT uses (col,row)
		#if (!mxIsNumeric (ptr)) error("Expected a Matrix for input\n");
		if ((M = GMT_Create_Data(API, GMT_IS_MATRIX, GMT_IS_PLP, 0, dim, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("Failure to alloc GMT source matrix")
		end

		GMT_Report(API, GMT.GMT_MSG_DEBUG, @sprintf("Allocate GMT Matrix %s in gmtjl_parser\n", M) )
		Mb = unsafe_load(M)			# Mb = GMT_MATRIX (constructor with 1 method)
		tipo = get_datatype(ptr)
		Mb.n_rows    = size(ptr,1)
		Mb.n_columns = size(ptr,2)

		if (eltype(ptr)     == Float64)		Mb._type = UInt32(GMT.GMT_DOUBLE)
		elseif (eltype(ptr) == Float32)		Mb._type = UInt32(GMT.GMT_FLOAT)
		elseif (eltype(ptr) == UInt64)		Mb._type = UInt32(GMT.GMT_ULONG)
		elseif (eltype(ptr) == Int64)		Mb._type = UInt32(GMT.GMT_LONG)
		elseif (eltype(ptr) == UInt32)		Mb._type = UInt32(GMT.GMT_UINT)
		elseif (eltype(ptr) == Int32)		Mb._type = UInt32(GMT.GMT_INT)
		elseif (eltype(ptr) == UInt16)		Mb._type = UInt32(GMT.GMT_USHORT)
		elseif (eltype(ptr) == Int16)		Mb._type = UInt32(GMT.GMT_SHORT)
		elseif (eltype(ptr) == UInt8)		Mb._type = UInt32(GMT.GMT_UCHAR)
		elseif (eltype(ptr) == Int8)		Mb._type = UInt32(GMT.GMT_CHAR)
		else
			println("Type \"", typeof(ptr), "\" not allowed")
			error("only integer or floating point types allowed in input. Others need to be added")
		end
		Mb.data = pointer(ptr)
		Mb.dim  = Mb.n_rows		# Data from Julia is in column major
		Mb.alloc_mode = GMT.GMT_ALLOC_EXTERNALLY;	# Since matrix was allocated by Julia
		Mb.shape = GMT.GMT_IS_COL_FORMAT;			# Julia order is column major
		unsafe_store!(M, Mb)
		return M

	else	# To receive data from GMT we use a GMT_VECTOR resource instead
		# There are no dimensions and we are just getting an empty container for output
		GMT_CREATE_MODE = 0
		if (get_GMTversion(API) > 5.3)	GMT_CREATE_MODE = GMT_IS_OUTPUT;	end
		if ((V = GMT_Create_Data(API, GMT_IS_VECTOR, GMT_IS_PLP, GMT_CREATE_MODE, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("Failure to alloc GMT source vector\n")
		end
		GMT_Report(API, GMT_MSG_DEBUG, @sprintf("dataset_init: Allocated GMT Vector %s\n", V))
		return V
	end
end

# ---------------------------------------------------------------------------------------------------
function palette_init(API::Ptr{Void}, module_input, cpt, dir::Integer)
	# Used to Create an empty CPT container to hold a GMT CPT.
 	# If direction is GMT_IN then we are given a Julia CPT and can determine its size, etc.
	# If direction is GMT_OUT then we allocate an empty GMT CPT as a destination.

	if (dir == GMT_OUT)
		GMT_CREATE_MODE = 0
		if (get_GMTversion(API) > 5.3)	GMT_CREATE_MODE = GMT_IS_OUTPUT;	end
		if ((P = GMT_Create_Data(API, GMT_IS_PALETTE, GMT_IS_NONE, GMT_CREATE_MODE, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("Failure to alloc GMT blank CPT container for holding output CPT")
		end
		return P
	end

	# Dimensions are known from the input pointer

	if (!isa(cpt, GMTcpt))
		error("Expected a CPT structure for input")
	end

	n_colors = size(cpt.colormap, 1)	# n_colors != n_ranges for continuous CPTs
	n_ranges = size(cpt.range, 1)
	one = 1
	if (n_colors > n_ranges)		# Continuous
		n_ranges = n_colors;		# Actual length of colormap array
		n_colors = n_colors - 1;	# Number of CPT slices
	else
		one = 0
	end

	if ((P = GMT_Create_Data(API, GMT_IS_PALETTE, GMT_IS_NONE, 0, pointer([n_colors]), C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
		error("Failure to alloc GMT source CPT for input")
	end

	if (one != 0)
		mutateit(API, P, "is_continuous", one)
	end
	if (cpt.depth == 1)
		mutateit(API, P, "is_bw", 1)
	elseif (cpt.depth == 8)
		mutateit(API, P, "is_gray", 1)
	end
	if (!isnan(cpt.hinge))
		mutateit(API, P, "has_hinge", 1)
		#P->mode &= GMT.GMT_CPT_HINGED;			# <========= Still need to translate this
		Pb.mode = Pb.mode & GMT.GMT_CPT_HINGED
	end

	Pb = unsafe_load(P)		# GMT.GMT_PALETTE

	if (cpt.model == "rgb")
		Pb.model = GMT_RGB
	elseif (cpt.model == "hsv")
		Pb.model = GMT_HSV
	else
		Pb.model = GMT_CMYK
	end

	b = (GMT.GMT_BFN((cpt.bfn[1,1], cpt.bfn[1,2], cpt.bfn[1,3],0), Pb.bfn[1].hsv, Pb.bfn[1].skip, Pb.bfn[1].fill),
	     GMT.GMT_BFN((cpt.bfn[2,1], cpt.bfn[2,2], cpt.bfn[2,3],0), Pb.bfn[1].hsv, Pb.bfn[1].skip, Pb.bfn[1].fill),
	     GMT.GMT_BFN((cpt.bfn[3,1], cpt.bfn[3,2], cpt.bfn[3,3],0), Pb.bfn[1].hsv, Pb.bfn[1].skip, Pb.bfn[1].fill))
	Pb.bfn = b

	for j = 1:Pb.n_colors
		glut = unsafe_load(Pb.data, j)
		rgb_low  = (cpt.cpt[j,1], cpt.cpt[j,2], cpt.cpt[j,3], cpt.alpha[j])
		rgb_high = (cpt.cpt[j,4], cpt.cpt[j,5], cpt.cpt[j,6], cpt.alpha[j+one])
		#rgb_low  = (cpt.colormap[j,1], cpt.colormap[j,2], cpt.colormap[j,3], cpt.alpha[j])
		#rgb_high = (cpt.colormap[j+one,1], cpt.colormap[j+one,2], cpt.colormap[j+one,3], cpt.alpha[j+one])
		z_low  = cpt.range[j,1]
		z_high = cpt.range[j,2]

		annot = 3						# Enforce annotations for now
		lut = GMT_LUT(z_low, z_high, glut.i_dz, rgb_low, rgb_high, glut.rgb_diff, glut.hsv_low, glut.hsv_high,
		              glut.hsv_diff, annot, glut.skip, glut.fill, glut.label)

		unsafe_store!(Pb.data, lut, j)
	end
	unsafe_store!(P, Pb)

	return P
end

# ---------------------------------------------------------------------------------------------------
function text_init_(API::Ptr{Void}, module_input, Darr, dir::Integer, family::Integer=GMT_IS_TEXTSET)
#
	if (dir == GMT_OUT)
		GMT_CREATE_MODE = 0
		if (get_GMTversion(API) > 5.3)	GMT_CREATE_MODE = GMT_IS_OUTPUT;	end
		if ((T = GMT_Create_Data(API, GMT_IS_TEXTSET, GMT_IS_NONE, GMT_CREATE_MODE, NULL, NULL, NULL, 0, 0, NULL)) == NULL)
			error("Failure to alloc GMT blank TEXTSET container for holding output TEXT")
		end
		return T
	end

	if (isa(Darr, Array{GMTdataset,1}))
		dim = [1 0 0]
		dim[GMT.GMT_SEG+1] = length(Darr)		# Number of segments
		if (dim[GMT.GMT_SEG+1] == 0) error("Input has zero segments where it can't be")	end
		pdim = pointer(dim)
		if ((T = GMT_Create_Data(API, GMT_IS_TEXTSET, GMT_IS_PLP, 0, pdim, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("Failure to alloc GMT destination dataset.")
		end
		GMT_Report(API, GMT_MSG_DEBUG, @sprintf("text_init_: Allocated GMT textset %s", T))

		TS = unsafe_load(convert(Ptr{GMT_TEXTSET}, T))
		TT = unsafe_load(unsafe_load(TS.table))				# GMT.GMT_TEXTTABLE

		for seg = 1:dim[GMT.GMT_SEG+1] 						# Each incoming structure is a new data segment
			dim[GMT.GMT_ROW+1] = size(Darr[seg].data, 1)	# Number of rows in matrix
			TSv = convert(Ptr{Void}, unsafe_load(TT.segment, seg))		# TT.segment = Ptr{Ptr{GMT.GMT_TEXTSEGMENT}}

			if (length(Darr[seg].text) == 0)
				add_text = false
			else
				dim[GMT_ROW+1] = size(Darr[seg].text,1)		# Number of rows found
				add_text = true
			end
			n_cols = size(Darr[seg].data, 2)				# Number of data cols, if any

			# Allocate new text segment and hook it up to the table
			S = GMT_Alloc_Segment(API, GMT_IS_TEXTSET, dim[GMT.GMT_ROW+1], 0, Darr[seg].header, TSv) # Ptr{GMT_TEXTSET}
			Sb = unsafe_load(S)								# GMT_TEXTSEGMENT;		Sb.data -> Ptr{Ptr{UInt8}}

			# Combine any data and cell arrays into text records
			for row = 1:Sb.n_rows
				# First deal with the [optional] data matrix for leading columns
				if (n_cols > 0)
					buff = join([@sprintf("%s\t", Darr[seg].data[row,k]) for k=1:n_cols])
				end
				if (add_text)				# Then append the optional text strings
					buff = buff * Darr[seg].text[row]
				else
					buff = rstrip(buff)		# Strip last '\t'
				end
				unsafe_store!(Sb.data, GMT_Duplicate_String(API, buff), row)	# This allows shared mem
			end

			if (seg == 1 && length(Darr[1].comment) > 0)	# First segment may have dataset information
				for k = 1:size(Darr[1].comment,1)
					if (GMT_Set_Comment(API, GMT_IS_TEXTSET, GMT_COMMENT_IS_TEXT, convert(Ptr{Void}, pointer(Darr[1].comment[k])),
					                    convert(Ptr{Void}, T)) != 0)
						println("text_init_: Failed to set a textset header")
					end
				end
			end
			unsafe_store!(S, Sb)
			unsafe_store!(TT.segment, S, seg)
		end
	else
		T = text_init(API, module_input, Darr, dir)
	end

	return T
end

# ---------------------------------------------------------------------------------------------------
function text_init(API::Ptr{Void}, module_input, txt, dir::Integer, family::Integer=GMT_IS_TEXTSET)
	# Used to Create an empty Textset container to hold a GMT TEXTSET.
 	# If direction is GMT_IN then we are given a Julia cell array and can determine its size, etc.
	# If direction is GMT_OUT then we allocate an empty GMT TEXTSET as a destination.


	# Disclaimer: This code is absolutely diabolic. Thanks to immutables.

	if (dir == GMT_IN)	# Dimensions are known from the input pointer

		#if (module_input) family |= GMT_VIA_MODULE_INPUT;	gmtmex_parser.c has this which is not ported yet

		if (!isa(txt, Array{Any}) && isa(txt, String))
			txt = Any[txt]
		elseif (isa(txt[1], Number))
			txt = num2str(txt)			# Convert the numeric matrix into a cell array of strings
		end
		if (VERSION.minor > 4)
			if (!isa(txt, Array{Any}) && !(eltype(txt) == String))
				error(@sprintf("Expected a Cell array or a String for input, got a \"%s\"", typeof(txt)))
			end
		end

		dim = [1 1 0]
		dim[3] = size(txt, 1)
		if (dim[3] == 1)                # Check if we got a transpose arrangement or just one record
			rec = size(txt, 2)          # Also possibly number of records
			if (rec > 1) dim[3] = rec end  # User gave row-vector of cells
		end

		if ((T = GMT_Create_Data(API, family, GMT_IS_NONE, 0, pointer(dim), C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("Failure to alloc GMT source TEXTSET for input")
		end
		mutateit(API, T, "alloc_mode", GMT_ALLOC_EXTERNALLY)

		T0 = unsafe_load(T)				# GMT.GMT_TEXTSET
		#T0.alloc_mode = GMT_ALLOC_EXTERNALLY

		TTABLE  = unsafe_load(unsafe_load(T0.table,1),1)		# ::GMT.GMT_TEXTTABLE
		S0 = unsafe_load(unsafe_load(TTABLE.segment,1),1)		# ::GMT.GMT_TEXTSEGMENT

		for rec = 1:dim[3]
			unsafe_store!(S0.data, pointer(txt[rec]), rec)
		end

		#GMT_blind_change_struct_(API, unsafe_load(TTABLE.segment,1), pointer([dim[3]]), "API_STRUCT_MEMBER_TEXTSEGMENT_1")
		mutateit(API, unsafe_load(TTABLE.segment,1), "n_rows", dim[3])

		# This chunk is no longer need as long as it works the call to GMT_Set_alloc_mode() that sets
		# the number of rows using very uggly tricks via C. The problem with the commented code below
		# comes from the GMT GarbageMan that would crash Julia when attempting to free a the Julia owned TS

#=
		TS = GMT_TEXTSEGMENT(dim[3], S0.record, S0.label, S0.header, S0.id, S0.mode, S0.n_alloc,
		                     S0.file, S0.tvalue)

		#segment::Ptr{Ptr{GMT_TEXTSEGMENT}}
		TSp1 = pointer([TS])		# ::Ptr{GMT_TEXTSEGMENT}
		TSp2 = pointer([TSp1])		# ::Ptr{Ptr{GMT_TEXTSEGMENT}}
		TT0  = TTABLE               # ::GMT_TEXTTABLE
		TT = GMT_TEXTTABLE(TT0.n_headers, TT0.n_segments, dim[3], TT0.header, TSp2, TT0.id, TT0.n_alloc,
		                   TT0.mode, TT0.file)
		pointer_to_array(TSp2,1)	# Just to prevent the garbage man to destroy TSp? before this time
		TTp1 = pointer([TT])		# ::Ptr{GMT_TEXTTABLE}
		TTp2 = pointer([TTp1])		# ::Ptr{Ptr{GMT_TEXTTABLE}}
		# Actually, here it ignores all but the pointers (TTp2)
		Tt   = GMT_TEXTSET(T0[1].n_tables, T0[1].n_segments, dim[3], TTp2, T0[1].id, T0[1].n_alloc, T0[1].geometry,
		                   T0[1].alloc_level, T0[1].io_mode, GMT.GMT_ALLOC_EXTERNALLY, T0[1].file)
		pointer_to_array(TTp2,2)	# Just to prevent the GarbageMan to destroy TTp? before this time
		unsafe_store!(T, Tt)
=#

	else 	# Just allocate an empty container to hold an output grid (signal this by passing NULLs)
		GMT_CREATE_MODE = 0
		if (get_GMTversion(API) > 5.3)	GMT_CREATE_MODE = GMT_IS_OUTPUT;	end
		if ((T = GMT_Create_Data(API, GMT_IS_TEXTSET, GMT_IS_NONE, GMT_CREATE_MODE, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("Failure to alloc GMT blank TEXTSET container for holding output TEXT")
		end
	end

	return T
end

# ---------------------------------------------------------------------------------------------------
function ps_init(API::Ptr{Void}, module_input, ps, dir::Integer)
# Used to Create an empty POSTSCRIPT container to hold a GMT POSTSCRIPT object.
# If direction is GMT_IN then we are given a Julia structure with known sizes.
# If direction is GMT_OUT then we allocate an empty GMT POSTSCRIPT as a destination.
	if (dir == GMT_OUT)
		GMT_CREATE_MODE = 0
		if (get_GMTversion(API) > 5.3)	GMT_CREATE_MODE = GMT_IS_OUTPUT;	end
		if ((P = GMT_Create_Data(API, GMT_IS_POSTSCRIPT, GMT_IS_NONE, GMT_CREATE_MODE, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)) == C_NULL)
			error("Failure to alloc GMT blank PS container for holding output PostScript")
		end
		return P
	end

	if (!isa(ps, GMTps))
		error("Expected a PS structure for input")
	end

	# Passing dim[0] = 0 since we dont want any allocation of a PS string
	pdim = pointer([0])
	if ((P = GMT_Create_Data(API, GMT_IS_POSTSCRIPT, GMT_IS_NONE, 0, pdim, NULL, NULL, 0, 0, NULL)) == NULL)
		error("gmtmex_ps_init: Failure to alloc GMT POSTSCRIPT source for input")
	end

	P0 = unsafe_load(P)		# GMT.GMT_POSTSCRIPT

	P0.n_bytes = ps.length
	P0.mode = ps.mode
	P0.data = pointer(ps.postscript)
	P0.alloc_mode = GMT.GMT_ALLOC_EXTERNALLY 	# Hence we are not allowed to free it
	P0.n_alloc = 0			# But nothing was actually allocated here - just passing pointer from Julia

	unsafe_store!(P, P0)

	GMT_Report(API, GMT_MSG_DEBUG, @sprintf("ps_init: Allocated GMT POSTSCRIPT %s", P))

	return P
end


# ---------------------------------------------------------------------------------------------------
function convert_string(str)
# Convert a string stored in one of those GMT.Array_XXX_Uint8 types into an ascii string
	k = 1
	while (str.(k) != UInt8(0))
		k = k + 1
	end
	out = join([Char(str.(n)) for n=1:k])
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_type(API::Ptr{Void})		# Set default export type
	value = "        "		# 8 spaces
	GMT_Get_Default(API, "GMT_EXPORT_TYPE", value)
	if (strncmp(value, "double", 6)) return DOUBLE_CLASS	end
	if (strncmp(value, "single", 6)) return SINGLE_CLASS	end
	if (strncmp(value, "long",   4)) return  INT64_CLASS	end
	if (strncmp(value, "ulong",  5)) return UINT64_CLASS	end
	if (strncmp(value, "int",    3)) return  INT32_CLASS	end
	if (strncmp(value, "uint",   4)) return UINT32_CLASS	end
	if (strncmp(value, "short",  5)) return  INT16_CLASS	end
	if (strncmp(value, "ushort", 6)) return UINT16_CLASS	end
	if (strncmp(value, "char",   4)) return   INT8_CLASS	end
	if (strncmp(value, "uchar",  5)) return  UINT8_CLASS	end

	println("Unable to interpret GMT_EXPORT_TYPE - Default to double")
	return DOUBLE_CLASS
end

# ---------------------------------------------------------------------------------------------------
function get_datatype(var)
# Get the data type of VAR
	if (eltype(var) == Float64) return DOUBLE_CLASS	end
	if (eltype(var) == Float32) return SINGLE_CLASS	end
	if (eltype(var) == UInt64) 	return UINT64_CLASS	end
	if (eltype(var) == Int64) 	return INT64_CLASS	end
	if (eltype(var) == UInt32) 	return UINT32_CLASS	end
	if (eltype(var) == Int32) 	return INT32_CLASS	end
	if (eltype(var) == UInt16) 	return UINT16_CLASS	end
	if (eltype(var) == Int16) 	return INT16_CLASS	end
	if (eltype(var) == UInt8) 	return UINT8_CLASS	end
	if (eltype(var) == Int8) 	return INT8_CLASS	end

	println("Unable to discovery this data type - Default to double")
	return DOUBLE_CLASS
end

# ---------------------------------------------------------------------------------------------------
function strncmp(str1, str2, num)
# Pseudo strncmp
	a = str1[1:min(num,length(str1))] == str2
end

# ---------------------------------------------------------------------------------------------------
function mutateit(API::Ptr{Void}, t_type, member::String, val)
	# Mutate the member 'member' of an immutable type whose pointer is T_TYPE
	# VAL is the new value of the MEMBER field.
	# It's up to the user to guarantie that MEMBER and VAL have the same data type
	# T_TYPE can actually be either a variable of a certain type or a pointer to it.
	# In latter case, we fish the specific datatype from it.
	if (isa(t_type, Ptr))
		x_type = unsafe_load(t_type)
		p_type = t_type
	else
		x_type = t_type
		p_type = pointer([t_type])	# We need the pointer to type to later send to GMT_blind_change
	end
	dt = typeof(x_type)			# Get the specific datatype. That's what we'll need for next inquires
	ft = dt.types
	#fo = fieldoffsets(dt)
	fo = map(idx->fieldoffset(dt, idx), 1:nfields(dt))
	ind = findfirst(fieldnames(dt), Symbol(member))	# Find the index of the "is_continuous" member
	# This would work too
	# ind = ccall(:jl_field_index, Cint, (Any, Any, Cint), dt, symbol(member), 1) + 1
	if (isa(val, AbstractString))	# No idea why I have to do this
		p_val = pointer(val)
	else
		p_val = pointer([val])
	end
	GMT_blind_change_struct(API, p_type, p_val, @sprintf("%s",ft[ind]), fo[ind])
	typeof(p_type); 	typeof(p_val)		# Just to be sure that GC doesn't kill them before their due time
end

# ---------------------------------------------------------------------------------------------------
function num2str(mat)
# Pseudo num2str, but returns all in a cell array of strings and no precision control yet.
	n_cols = size(mat, 2);		n_rows = size(mat, 1)
	out = cell(n_rows, 1)
	for nr = 1:n_rows
		out[nr] = join([@sprintf("%s\t", mat[nr,k]) for k=1:n_cols-1])
		out[nr] = out[nr] * @sprintf("%s", mat[nr,n_cols])
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
"""
G = grid_type(z, hdr=[])
    Take a 2D Z array and a HDR 1x9 [xmin xmax ymin ymax zmin zmax ref xinc yinc] header descriptor
    and return a grid GMTgrid type.
    Optionaly, the HDR arg may be ommited and it will computed from Z alone, but than x=1:ncol, y=1:nrow
"""
function grid_type(z, hdr=[])
	n_rows = size(z,1);		n_cols = size(z,2)
	if (n_rows == 1 || n_cols == 1)
		error("Z must be a 2D array")
	end
	if (isempty(hdr))
		zmin, zmax = extrema(z)
		hdr = [1. n_cols 1. n_rows zmin zmax 0 1 1]
	elseif (length(hdr) != 9)
		error("The HDR array must have 9 elements")
	end
	x = linspace(hdr[1], hdr[2], n_cols)
	y = linspace(hdr[3], hdr[4], n_rows)
	# Recompute the x|y_inc to make sure they are right.
	one_or_zero = hdr[7] == 0 ? 1 : 0
	x_inc = (hdr[2] - hdr[1]) / (n_cols - one_or_zero)
	y_inc = (hdr[4] - hdr[3]) / (n_rows - one_or_zero)
	G = GMTgrid("", "", hdr[1:6], [x_inc, y_inc], hdr[7], NaN, "", "", "", "", x, y, z, "", "", "", "")
end

# ---------------------------------------------------------------------------------------------------
"""
Inquire about GMT version. Will return 5.3 for all versions up to this one and the truth for rest
"""
function get_GMTversion(API::Ptr{Void})
	status = GMT_Call_Module(API, "psternary", GMT.GMT_MODULE_EXIST, C_NULL)
	if (status != 0)
		ver = 5.3
	else
		value = "        "
		GMT_Get_Default(API, "API_VERSION", value)
		ver = parse(value[1:3])
	end
end

#=
Em GMT_Create_Session(API, ...)
	API->pad = pad;

O GMT_begin chama indirectamente esta
void GMT_set_pad (struct GMT_CTRL *GMT, unsigned int pad) {
	GMT->current.io.pad[XLO] = GMT->current.io.pad[XHI] = GMT->current.io.pad[YLO] = GMT->current.io.pad[YHI] = pad;
}
=#
