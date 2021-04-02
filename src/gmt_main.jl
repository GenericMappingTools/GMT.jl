mutable struct GMTgrid{T<:Real,N} <: AbstractArray{T,N}
	proj4::String
	wkt::String
	epsg::Int
	range::Array{Float64,1}
	inc::Array{Float64,1}
	registration::Int
	nodata::Union{Float64, Float32}
	title::String
	remark::String
	command::String
	x::Array{Float64,1}
	y::Array{Float64,1}
	z::Array{T,N}
	x_unit::String
	y_unit::String
	z_unit::String
	layout::String
	pad::Int
end
Base.size(G::GMTgrid) = size(G.z)
Base.getindex(G::GMTgrid{T,N}, inds::Vararg{Int,N}) where {T,N} = G.z[inds...]
Base.setindex!(G::GMTgrid{T,N}, val, inds::Vararg{Int,N}) where {T,N} = G.z[inds...] = val

Base.BroadcastStyle(::Type{<:GMTgrid}) = Broadcast.ArrayStyle{GMTgrid}()
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{GMTgrid}}, ::Type{ElType}) where ElType
	G = find4similar(bc.args)		# Scan the inputs for the GMTgrid:
	GMTgrid(G.proj4, G.wkt, G.epsg, G.range, G.inc, G.registration, G.nodata, G.title, G.remark, G.command, G.x, G.y, similar(Array{ElType}, axes(bc)), G.x_unit, G.y_unit, G.z_unit, G.layout, G.pad)
end

find4similar(bc::Base.Broadcast.Broadcasted) = find4similar(bc.args)
find4similar(args::Tuple) = find4similar(find4similar(args[1]), Base.tail(args))
find4similar(x) = x
find4similar(::Tuple{}) = nothing
find4similar(G::GMTgrid, rest) = G
find4similar(::Any, rest) = find4similar(rest)

mutable struct GMTimage{T<:Unsigned, N} <: AbstractArray{T,N}
	proj4::String
	wkt::String
	epsg::Int
	range::Array{Float64,1}
	inc::Array{Float64,1}
	registration::Int
	nodata::Union{Float64, Float32}
	color_interp::String
	x::Array{Float64,1}
	y::Array{Float64,1}
#	image::Union{Array{UInt8}, Array{UInt16}}
	image::Array{T,N}
	colormap::Array{Clong,1}
	n_colors::Int
	alpha::Array{UInt8,2}
	layout::String
	pad::Int
end
Base.size(I::GMTimage) = size(I.image)
Base.getindex(I::GMTimage{T,N}, inds::Vararg{Int,N}) where {T,N} = I.image[inds...]
Base.setindex!(I::GMTimage{T,N}, val, inds::Vararg{Int,N}) where {T,N} = I.image[inds...] = val

Base.BroadcastStyle(::Type{<:GMTimage}) = Broadcast.ArrayStyle{GMTimage}()
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{GMTimage}}, ::Type{ElType}) where ElType
	I = find4similar(bc.args)		# Scan the inputs for the GMTimage:
	GMTimage(I.proj4, I.wkt, I.epsg, I.range, I.inc, I.registration, I.nodata, I.color_interp, I.x, I.y, similar(Array{ElType}, axes(bc)), I.colormap, I.n_colors, I.alpha, I.layout, I.pad)
end
find4similar(I::GMTimage, rest) = I

mutable struct GMTcpt
	colormap::Array{Float64,2}	# Mx3 matrix equal to the first three columns of cpt
	alpha::Array{Float64,1}		# Vector of alpha values. One for each color.
	range::Array{Float64,2}		# Mx2 matrix with z range for each slice
	minmax::Array{Float64,1}	# Two elements Vector with zmin,zmax
	bfn::Array{Float64,2}		# A 3x3(4?) matrix with BFN colors (one per row) in [0 1] interval
	depth::Cint					# Color depth 24, 8, 1
	hinge::Cdouble				# Z-value at discontinuous color break, or NaN
	cpt::Array{Float64,2}		# Mx6 matrix with r1 g1 b1 r2 g2 b2 for z1 z2 of each slice
	label::Vector{String}		# Labels of a Categorical CPT
	key::Vector{String}			# Keys of a Categorical CPT
	model::String				# String with color model rgb, hsv, or cmyk [rgb]
	comment::Array{String,1}	# Cell array with any comments
end

mutable struct GMTps
	postscript::String			# Actual PS plot (text string)
	length::Int 				# Byte length of postscript
	mode::Int 					# 1 = Has header, 2 = Has trailer, 3 = Has both
	comment::Array{String,1}	# Cell array with any comments
end

#mutable struct GMTdataset
	#data::Array{Float64,2}
mutable struct GMTdataset{T<:Real, N} <: AbstractArray{T,N}
	data::Array{T,N}
	text::Array{String,1}
	header::AbstractString
	comment::Array{String,1}
	proj4::String
	wkt::String
	#GMTdataset(data, text, header, comment, proj4, wkt) = new(data, text, header, comment, proj4, wkt)
	#GMTdataset(data, text) = new(data, text, string(), Array{String,1}(), string(), string())
	#GMTdataset(data) = new(data, Array{String,1}(), string(), Array{String,1}(), string(), string())
	#GMTdataset() = new(Array{Float64,2}(undef,0,0), Array{String,1}(), string(), Array{String,1}(), string(), string())
end
Base.size(D::GMTdataset) = size(D.data)
Base.getindex(D::GMTdataset{T,N}, inds::Vararg{Int,N}) where {T,N} = D.data[inds...]
Base.setindex!(D::GMTdataset{T,N}, val, inds::Vararg{Int,N}) where {T,N} = D.data[inds...] = val

Base.BroadcastStyle(::Type{<:GMTdataset}) = Broadcast.ArrayStyle{GMTdataset}()
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{GMTdataset}}, ::Type{ElType}) where ElType
	D = find4similar(bc.args)		# Scan the inputs for the GMTdataset:
	GMTdataset(D.data, D.text, D.header, D.comment, D.proj4, D.wkt)
end
find4similar(D::GMTdataset, rest) = D

GMTdataset(data::Array{Float64,2}, text::Vector{String}) = GMTdataset(data, text, "", Vector{String}(), "", "")
GMTdataset(data::Array{Float64,2}, text::String) = GMTdataset(data, [text], "", Vector{String}(), "", "")
GMTdataset(data::Array{Float64,2}) = GMTdataset(data, Vector{String}(), "", Vector{String}(), "", "")
GMTdataset(data::Array{Float32,2}, text::Vector{String}) = GMTdataset(data, text, "", Vector{String}(), "", "")
GMTdataset(data::Array{Float32,2}, text::String) = GMTdataset(data, [text], "", Vector{String}(), "", "")
GMTdataset(data::Array{Float32,2}) = GMTdataset(data, Vector{String}(), "", Vector{String}(), "", "")
GMTdataset() = GMTdataset(Array{Float64,2}(undef,0,0), Vector{String}(), "", Vector{String}(), "", "")

struct WrapperPluto fname::String end

"""
Call a GMT module. Usage:

    gmt("module_name `options`")

Example. To plot a simple map of Iberia in the postscript file nammed `lixo.ps` do:

    gmt("pscoast -R-10/0/35/45 -B1 -W1 -Gbrown -JM14c -P -V > lixo.ps")
"""
function gmt(cmd::String, args...)
	global API

	# ----------- Minimal error checking ------------------------
	n_argin = length(args)
	if (n_argin > 0)
		if (isa(args[1], String))
			tok, r = strtok(cmd)
			if (r == "")				# User gave 'module' separately from 'options'
				cmd *= " " * args[1]	# Cat with the progname and so pretend input followed the classic construct
				args = args[2:end]
				n_argin -= 1
			end
		end
		while (n_argin > 0 && (args[n_argin] === nothing || args[n_argin] == []))  n_argin -= 1  end	# We may have trailing [] args in modules
	end
	# -----------------------------------------------------------

	# 1. Get arguments, if any, and extract the GMT module name
	# First argument is the command string, e.g., "blockmean -R0/5/0/5 -I1" or just "help"
	g_module, r = strtok(cmd)

	if (g_module == "begin")		# Use this default fig name instead of "gmtsession"
		if (r == "")  r = "GMTplot " * FMT[1]  end
		IamModern[1] = true
	elseif (g_module == "end")
		IamModern[1] = false
	elseif (r == "" && n_argin == 0) # Just requesting usage message, add -? to options
		r = "-?"
	elseif (n_argin > 1 && (g_module == "psscale" || g_module == "colorbar"))	# Happens with nested calls like in grdimage
		if (!isa(args[1], GMTcpt) && isa(args[2], GMTcpt))
			args = [args[2]];		n_argin = 1
		end
	end

	pad = 2
	if (!isa(API, Ptr{Nothing}) || API == C_NULL)
		API = GMT_Create_Session("GMT", pad, GMT_SESSION_NOEXIT + GMT_SESSION_EXTERNAL + GMT_SESSION_COLMAJOR)
		if (API == C_NULL)  error("Failure to create a GMT Session")  end
	end

	if (g_module == "destroy")
		GMT_Destroy_Session(API);	API = nothing
		return
	end

	# 2. In case this was a clean up call or a begin/end from the modern mode
	gmt_manage_workflow(API, 0, NULL)		# Force going here to see if we are in middle of a MODERN session

	# Make sure this is a valid module
	if ((status = GMT_Call_Module(API, g_module, GMT_MODULE_EXIST, C_NULL)) != 0)
		error("GMT: No module by that name -- " * g_module * " -- was found.")
	end

	# 2+ Add -F to psconvert if user requested a return image but did not give -F.
	# The problem is that we can't use nargout to decide what to do, so we use -T to solve the ambiguity.
	need2destroy = false
	if (g_module == "psconvert" && !occursin("-F", r))
		if (!occursin("-T", r))
			r *= " -F";			need2destroy = true
		else				# Hmm, have to find if any of 'e' or 'f' are used as -T flags
			return_img = true
			if (endswith(r, " *"))  r = r[1:end-2];	return_img = false;  end	# Trick to avoid reading back img
			ind = findfirst("-T", r)
			tok = lowercase(strtok(r[ind[2]:end])[1])
			if (return_img && !occursin("e", tok) && !occursin("f", tok))	# No any -Tef combo so add -F
				r *= " -F";		need2destroy = true
			end
		end
	end
	if (occursin("-%", r) || occursin("-&", r))			# It has also a mem layout request
		r, img_mem_layout[1], grd_mem_layout[1] = parse_mem_layouts(r)
		(img_mem_layout[1] != "") && (mem_layout = img_mem_layout[1];	mem_kw = "API_IMAGE_LAYOUT")
		(grd_mem_layout[1] != "") && (mem_layout = grd_mem_layout[1];	mem_kw = "API_GRID_LAYOUT")
		(img_mem_layout[1] != "" && mem_layout[end] != 'a')  && (mem_layout *= "a")
		GMT_Set_Default(API, mem_kw, mem_layout);		# Tell module to give us the image/grid with this mem layout
	end

	# 2++ Add -T to gmtwrite if user did not explicitly give -T. Seek also for MEM layout requests
	if (occursin("write", g_module))
		if (!occursin("-T", r) && n_argin == 1)
			if (isa(args[1], GMTgrid))
				r *= " -Tg"
			elseif (isa(args[1], GMTimage))
				r *= " -Ti"
			elseif (isa(args[1], Array{<:GMTdataset}) || isa(args[1], GMTdataset))
				r *= " -Td"
			elseif (isa(args[1], GMTps))
				r *= " -Tp"
			elseif (isa(args[1], GMTcpt))
				r *= " -Tc"
			end
		end
		r, img_mem_layout[1], grd_mem_layout[1] = parse_mem_layouts(r)
	elseif (occursin("read", g_module) && (occursin("-Ti", r) || occursin("-Tg", r)))
		need2destroy = true
	end

	# 2+++ If gmtread -Ti than temporarily set pad to 0 since we don't want padding in image arrays
	if (occursin("read", g_module) && (r != "") && occursin("-T", r))		# It parses the 'layout' key
		(occursin("-Ti", r)) && GMT_Set_Default(API, "API_PAD", "0")
		r, img_mem_layout[1], grd_mem_layout[1] =  parse_mem_layouts(r)
	end

	# 3. Convert command line arguments to a linked GMT option list
	LL = NULL
	LL = GMT_Create_Options(API, 0, r)	# It uses also the fact that GMT parses and check options

	# 4. Preprocess to update GMT option lists and return info array X

	# Here I have an issue that I can't resolve any better. For modules that can have no options (e.g. gmtinfo)
	# the LinkedList (LL) is actually created in GMT_Encode_Options but I can't get it's contents back when pLL
	# is a Ref, so I'm forced to use 'pointer', which goes against the documents recommendation.
	if (LL != NULL)  pLL = Ref([LL], 1)
	else             pLL = pointer([NULL])
	end

	n_itemsP = pointer([0])
	X = GMT_Encode_Options(API, g_module, n_argin, pLL, n_itemsP)	# This call also changes LL
	n_items = unsafe_load(n_itemsP)
	if (X == NULL && n_items > 65000)		# Just got usage/synopsis option (if (n_items == UINT_MAX)) in C
		(n_items > 65000) ? n_items = 0 : error("Failure to encode Julia command options") 
	end

	if (LL == NULL)		# The no-options case. Must get the LL that was created in GMT_Encode_Options
		LL = convert(Ptr{GMT.GMT_OPTION}, unsafe_load(pLL))
		pLL = Ref([LL], 1)		# Need this because GMT_Destroy_Options() wants a Ref
	end

	XX = Array{GMT_RESOURCE}(undef, 1, n_items)
	for k = 1:n_items
		XX[k] = unsafe_load(X, k)        # Cannot use pointer_to_array() because GMT_RESOURCE is not immutable and would BOOM!
	end
	X = XX

	# 5. Assign input sources (from Julia to GMT) and output destinations (from GMT to Julia)
	name_PS = ""
	object_ID = zeros(Int32, n_items)
	for k = 1:n_items					# Number of GMT containers involved in this module call */
		if (X[k].direction == GMT_IN && n_argin == 0) error("GMT: Expects a Matrix for input") end
		ptr = (X[k].direction == GMT_IN) ? args[X[k].pos+1] : nothing
		GMTJL_Set_Object(API, X[k], ptr, pad)	# Set object pointer
	end

	# 6. Run GMT module; give usage message if errors arise during parsing
	status = GMT_Call_Module(API, g_module, GMT_MODULE_OPT, LL)
	if (status != 0)
		if ((status < 0) || status == GMT_SYNOPSIS || status == Int('?'))
			return
		end
		error("Something went wrong when calling the module. GMT error number =")
	end

	# 7. Hook up module GMT outputs to Julia array
	# But first cout the number of outputs
	n_out = 0
	for k = 1:n_items					# Number of GMT containers involved in this module call
		if (X[k].direction == GMT_IN) continue 	end
		n_out = n_out + 1
	end

	(n_out > 0) ? out = Array{Any}(undef, n_out) : out = nothing

	for k = 1:n_items					# Get results from GMT into Julia arrays
		if (X[k].direction == GMT_IN) continue 	end      # Only looking for stuff coming OUT of GMT here
		out[X[k].pos+1] = GMTJL_Get_Object(API, X[k])    # Hook object onto rhs list
	end

	# 2++- If gmtread -Ti than reset the session's pad value that was temporarily changed above (2+++)
	if (occursin("read", g_module) && !isempty(r) && occursin("-Ti", r))
		GMT_Set_Default(API, "API_PAD", "2")
	end

	# Due to the damn GMT pad I'm forced to a lot of trickery. One involves shitting on memory ownership
	if (CTRL.gmt_mem_bag[1] != C_NULL)
		gmt_free_mem(API, CTRL.gmt_mem_bag[1])		# Free a GMT owned memory that we pretended was ours
		CTRL.gmt_mem_bag[1] = C_NULL
	end

	# 8. Free all GMT containers involved in this module call
	for k = 1:n_items
		ppp = X[k].object
		name = String([X[k].name...])				# Because X.name is a NTuple
		(GMT_Close_VirtualFile(API, name) != 0) && error("GMT: Failed to close virtual file")
		(GMT_Destroy_Data(API, Ref([X[k].object], 1)) != 0) && error("Failed to destroy GMT<->Julia interface object")
		# Success, now make sure we dont destroy the same pointer more than once
		for kk = k+1:n_items
			if (X[kk].object == ppp) 	X[kk].object = NULL;	end
		end
	end

	# 9. Destroy linked option list
	GMT_Destroy_Options(API, pLL)

	if (IamModern[1])  GMT_Destroy_Session(API);	API = nothing  end	# Needed, otherwise history is not updated
	#if (IamModern[1])  gmt_put_history(API);	end	# Needed, otherwise history is not updated

	img_mem_layout[1] = "";		grd_mem_layout[1] = ""		# Reset to not afect next readings

	# GMT6.1.0 f up and now we must be very careful to not let the GMT breaking screw us
	if (need2destroy)  gmt("destroy")  end

	# Return a variable number of outputs but don't think we even can return 3
	if (n_out == 0)
		return nothing
	elseif (n_out == 1)
		return out[1]
	elseif (n_out == 2)
		return out[1], out[2]
	elseif (n_out == 3)
		return out[1], out[2], out[3]
	else
		return out
	end

end

#= ---------------------------------------------------------------------------------------------------
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
=#

# ---------------------------------------------------------------------------------------------------
function parse_mem_layouts(cmd::AbstractString)
# See if a specific grid or image mem layout is requested. If found return its value and also
# strip the corresponding option from the CMD string (otherwise GMT would scream)
	grd_mem_layout[1] = "";	img_mem_layout[1] = ""

	if ((ind = findfirst( "-%", cmd)) !== nothing)
		img_mem_layout[1], resto = strtok(cmd[ind[1]+2:end])
		if (length(img_mem_layout[1]) < 3 || length(img_mem_layout[1]) > 4)
			error("Memory layout option must have 3 characters and not $(img_mem_layout[1])")
		end
		cmd = cmd[1:ind[1]-1] * " " * resto 	# Remove the -L pseudo-option because GMT would bail out
	end
	if (isempty(img_mem_layout[1]))				# Only if because we can't have a double request
		if ((ind = findfirst( "-&", cmd)) !== nothing)
			grd_mem_layout[1], resto = strtok(cmd[ind[1]+2:end])
			if (length(grd_mem_layout[1]) < 2)
				error("Memory layout option must have at least 2 chars and not $(grd_mem_layout[1])")
			end
			cmd = cmd[1:ind[1]-1] * " " * resto 	# Remove the -L pseudo-option because GMT would bail out
		end
	end
	img_mem_layout[1] = string(img_mem_layout[1]);	grd_mem_layout[1] = string(grd_mem_layout[1]);	# We don't want substrings
	return cmd, img_mem_layout[1], grd_mem_layout[1]
end

# ---------------------------------------------------------------------------------------------------
function strtok(args, delim::String=" ")
# A Matlab like strtok function
	tok = "";	r = ""

	@label restart
	ind = findfirst(delim, args)
	(ind === nothing) && return lstrip(args,collect(delim)), r		# Always clip delimiters at the begining
	if (startswith(args, delim))
		args = lstrip(args,collect(delim)) 			# Otherwise delim would be return as a token
		@goto restart
	end
	tok = lstrip(args[1:ind[1]-1], collect(delim))	#		""
	r = lstrip(args[ind[1]:end], collect(delim))

	return tok,r
end

#= ---------------------------------------------------------------------------------------------------
function GMT_IJP(hdr::GMT_GRID_HEADER, row, col)
# Function for indecing into a GMT grid [with pad]
# padTop (hdr.pad[GMT.GMT_YHI]) and padLeft (hdr.pad[GMT.GMT_XLO]) are normally equal
	#ij = (row + hdr.pad[4]) * hdr.mx + col + hdr.pad[1]		# in C
	ij = ((row-1) + hdr.pad[4]) * hdr.mx + col + hdr.pad[1]
end
=#

# ---------------------------------------------------------------------------------------------------
function GMT_IJP(row::Integer, col::Integer, mx, padTop, padLeft)
# Function for indecing into a GMT grid [with pad]
# padTop (hdr.pad[GMT.GMT_YHI]) and padLeft (hdr.pad[GMT.GMT_XLO]) are normally equal
	#ij = (row + padTop) * mx + col + padLeft		# in C
	ij = ((row-1) + padTop) * mx + col + padLeft
end

# ---------------------------------------------------------------------------------------------------
function MEXG_IJ(row::Integer, col::Integer, ny)
	# Get the ij that corresponds to (row,col) [no pad involved]
	#ij = col * ny + ny - row - 1		in C
	ij = col * ny - row + 1
end

# ---------------------------------------------------------------------------------------------------
function get_grid(API::Ptr{Nothing}, object)
# Given an incoming GMT grid G, build a Julia type and assign the output components.
# Note: Incoming GMT grid has standard padding while Julia grid has none.

	G = unsafe_load(convert(Ptr{GMT_GRID}, object))
	(G.data == C_NULL) && error("get_grid: programming error, output matrix is empty")

	gmt_hdr = unsafe_load(G.header)
	ny = Int(gmt_hdr.n_rows);		nx = Int(gmt_hdr.n_columns);		nz = Int(gmt_hdr.n_bands)
	padTop = Int(gmt_hdr.pad[4]);	padLeft = Int(gmt_hdr.pad[1]);
	mx = Int(gmt_hdr.mx);			my = Int(gmt_hdr.my)

#=	# Not yet implemented on the GMT side
	X = zeros(nx);		t = pointer_to_array(G.x, nx)
	[X[col] = t[col] for col = 1:nx]
	Y = zeros(ny);		t = pointer_to_array(G.y, ny)
	[Y[col] = t[col] for col = 1:ny]
=#
	X  = collect(range(gmt_hdr.wesn[1], stop=gmt_hdr.wesn[2], length=(nx + gmt_hdr.registration)))
	Y  = collect(range(gmt_hdr.wesn[3], stop=gmt_hdr.wesn[4], length=(ny + gmt_hdr.registration)))

	t = unsafe_wrap(Array, G.data, my * mx)
	z = zeros(Float32, ny, nx)

	if (grd_mem_layout[1] == "")
		for col = 1:nx
			for row = 1:ny
				ij = GMT_IJP(row, col, mx, padTop, padLeft)		# This one is Int64
				z[MEXG_IJ(row, col, ny)] = t[ij]	# Later, replace MEXG_IJ() by kk = col * ny - row + 1
			end
		end
	elseif (startswith(grd_mem_layout[1], "TR") || startswith(grd_mem_layout[1], "BR"))	# Keep the Row Major but stored in Column Major
		ind_y = 1:ny		# Start assuming "TR"
		if (startswith(grd_mem_layout[1], "BR"))  ind_y = ny:-1:1  end	# Bottom up
		k = 1
		for row = ind_y
			for col = 1:nx
				z[k] = t[GMT_IJP(row, col, mx, padTop, padLeft)]
				k = k + 1
			end
		end
		grd_mem_layout[1] = ""			# Reset because this variable is global
	else
		#for col = 1:nx
			#for row = 1:ny
				#z[row,col] = t[GMT_IJP(row, col, mx, padTop, padLeft)]
			#end
		#end
		[z[row,col] = t[GMT_IJP(row, col, mx, padTop, padLeft)] for col = 1:nx, row = 1:ny]
		grd_mem_layout[1] = ""
	end

	#t  = reshape(pointer_to_array(G.data, ny * nx), ny, nx)

	# Return grids via a float matrix in a struct
	out = GMTgrid("", "", 0, zeros(6)*NaN, zeros(2)*NaN, 0, NaN, "", "", "", X, Y, z, "", "", "", "", 0)

	if (gmt_hdr.ProjRefPROJ4 != C_NULL)  out.proj4 = unsafe_string(gmt_hdr.ProjRefPROJ4)  end
	if (gmt_hdr.ProjRefWKT != C_NULL)    out.wkt = unsafe_string(gmt_hdr.ProjRefWKT)      end
	out.title   = String([gmt_hdr.title...])
	out.remark  = String([gmt_hdr.remark...])
	out.command = String([gmt_hdr.command...])

	# The following is uggly is a consequence of the clag.jl translation of fixed sixe arrays
	out.range = vec([gmt_hdr.wesn[1] gmt_hdr.wesn[2] gmt_hdr.wesn[3] gmt_hdr.wesn[4] gmt_hdr.z_min gmt_hdr.z_max])
	out.inc          = vec([gmt_hdr.inc[1] gmt_hdr.inc[2]])
	out.nodata       = gmt_hdr.nan_value
	out.registration = gmt_hdr.registration
	out.x_unit       = String(UInt8[gmt_hdr.x_unit...])
	out.y_unit       = String(UInt8[gmt_hdr.y_unit...])
	out.z_unit       = String(UInt8[gmt_hdr.z_unit...])

	return out
end

# ---------------------------------------------------------------------------------------------------
function get_image(API::Ptr{Nothing}, object)
# Given an incoming GMT image, build a Julia type and assign the output components.
# Note: Incoming GMT image may have standard padding while Julia image has none.

	I = unsafe_load(convert(Ptr{GMT_IMAGE}, object))
	(I.data == C_NULL) && error("get_image: programming error, output matrix is empty")
	if     (I.type <= 1)  data = convert(Ptr{Cuchar}, I.data)
	elseif (I.type == 3)  data = convert(Ptr{Cushort}, I.data)
	end

	gmt_hdr = unsafe_load(I.header)
	ny = Int(gmt_hdr.n_rows);		nx = Int(gmt_hdr.n_columns);		nz = Int(gmt_hdr.n_bands)

	X  = collect(range(gmt_hdr.wesn[1], stop=gmt_hdr.wesn[2], length=(nx + gmt_hdr.registration)))
	Y  = collect(range(gmt_hdr.wesn[3], stop=gmt_hdr.wesn[4], length=(ny + gmt_hdr.registration)))

	layout = join([Char(gmt_hdr.mem_layout[k]) for k=1:4])		# This is damn diabolic
	if (occursin("0", img_mem_layout[1]) || occursin("1", img_mem_layout[1]))	# WTF is 0 or 1?
		t  = deepcopy(unsafe_wrap(Array, data, ny * nx * nz))
	else
		if (img_mem_layout[1] != "")  layout = img_mem_layout[1][1:3] * layout[4]  end	# 4rth id data determined
		if (layout != "" && layout[1] == 'I')		# The special layout for using this image in Images.jl
			o = (nz == 1) ? (ny, nx) : (nz, ny, nx)
		else
			o = (nz == 1) ? (ny, nx) : (ny, nx, nz)
		end
		t  = reshape(unsafe_wrap(Array, data, ny * nx * nz), o)	# Apparently the reshape() creates a copy as we need
	end

	if (I.colormap != C_NULL)       # Indexed image has a color map (PROBABLY NEEDS TRANSPOSITION)
		n_colors = Int64(I.n_indexed_colors)
		colormap =  deepcopy(unsafe_wrap(Array, I.colormap, n_colors * 4))
	else
		colormap, n_colors = vec(zeros(Clong,1,3)), 0	# Because we need an array
	end

	# Return image via a uint8 matrix in a struct
	cinterp = (I.color_interp != C_NULL) ? unsafe_string(I.color_interp) : ""
	out = GMTimage("", "", 0, zeros(6)*NaN, zeros(2)*NaN, 0, gmt_hdr.nan_value, cinterp, X, Y,
	               t, colormap, n_colors, Array{UInt8,2}(undef,1,1), layout, 0)

	GMT_Set_AllocMode(API, GMT_IS_IMAGE, object)
	unsafe_store!(convert(Ptr{GMT_IMAGE}, object), I)

	if (gmt_hdr.ProjRefPROJ4 != C_NULL)  out.proj4 = unsafe_string(gmt_hdr.ProjRefPROJ4)  end
	if (gmt_hdr.ProjRefWKT   != C_NULL)  out.wkt   = unsafe_string(gmt_hdr.ProjRefWKT)    end
	if (gmt_hdr.ProjRefEPSG  != 0)       out.epsg  = unsafe_string(gmt_hdr.ProjRefEPSG)   end

	out.range = vec([gmt_hdr.wesn[1] gmt_hdr.wesn[2] gmt_hdr.wesn[3] gmt_hdr.wesn[4] gmt_hdr.z_min gmt_hdr.z_max])
	out.inc          = vec([gmt_hdr.inc[1] gmt_hdr.inc[2]])
	out.registration = gmt_hdr.registration
	reg = round(Int, (X[end] - X[1]) / gmt_hdr.inc[1]) == (nx - 1)		# Confirm registration
	(reg && gmt_hdr.registration == 1) && (out.registration = 0)

	return out
end

# ---------------------------------------------------------------------------------------------------
function get_palette(API::Ptr{Nothing}, object::Ptr{Nothing})
# Given a GMT CPT C, build a Julia type and assign values.
# Each segment will have 10 items:
# colormap:	Nx3 array of colors usable in Matlab' colormap
# alpha:	Nx1 array with transparency values
# range:	Nx2 arran with z-values at color changes
# minmax:	2x1 array with min/max zvalues
# bfn:		3x3 array with colors for background, forground, nan
# depth	Color depth 24, 8, 1
# hinge:	Z-value at discontinuous color break, or NaN
# cpt:		Nx6 full GMT CPT array
# label		# Labels of a Categorical CPT. Vector of strings, one for each color
# key		# Keys of a Categorical CPT. Vector of strings, one for each color
# model:	String with color model rgb, hsv, or cmyk [rgb]
# comment:	Cell array with any comments

	C = unsafe_load(convert(Ptr{GMT_PALETTE}, object))

	(C.data == C_NULL) && error("get_palette: programming error, output CPT is empty")

	model = (C.model & GMT_HSV != 0) ? "hsv" : ((C.model & GMT_CMYK != 0) ? "cmyk" : "rgb")
	n_colors = (C.is_continuous != 0) ? C.n_colors + 1 : C.n_colors

	out = GMTcpt(zeros(n_colors, 3), zeros(n_colors), zeros(C.n_colors, 2), zeros(2)*NaN, zeros(3,3), 8, 0.0,
	             zeros(C.n_colors,6), Vector{String}(undef,C.n_colors), Vector{String}(undef,C.n_colors), model, [])

	for j = 1:C.n_colors       # Copy r/g/b from palette to Julia array
		gmt_lut = unsafe_load(C.data, j)
		for k = 1:3 	out.colormap[j, k] = gmt_lut.rgb_low[k]		end
		for k = 1:3
			out.cpt[j, k]   = gmt_lut.rgb_low[k]
			out.cpt[j, k+3] = gmt_lut.rgb_high[k]		# Not sure this is equal to the ML MEX case
		end
		out.alpha[j]    = gmt_lut.rgb_low[4]
		out.range[j, 1] = gmt_lut.z_low
		out.range[j, 2] = gmt_lut.z_high
		out.label[j]    = (gmt_lut.label == C_NULL) ? "" : unsafe_string(gmt_lut.label)
		out.key[j]      = (gmt_lut.key   == C_NULL) ? "" : unsafe_string(gmt_lut.key)
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
function get_PS(API::Ptr{Nothing}, object::Ptr{Nothing})
# Given a GMT Postscript structure P, build a Julia PS type
# Each segment will have 4 items:
# postscript:	Text string with the entire PostScript plot
# length:	Byte length of postscript
# mode:	1 has header, 2 has trailer, 3 is complete
# comment:	Cell array with any comments
	(object == C_NULL) && error("get_PS: programming error, input object is NULL")

	P = unsafe_load(convert(Ptr{GMT_POSTSCRIPT}, object))
	out = GMTps(unsafe_string(P.data), Int(P.n_bytes), Int(P.mode), [])	# NEED TO FILL THE COMMENT
end

# ---------------------------------------------------------------------------------------------------
function get_dataset(API::Ptr{Nothing}, object::Ptr{Nothing})
# Given a GMT DATASET D, build an array of segment structure and assign values.
# Each segment will have 6 items:
# header:	Text string with the segment header (could be empty)
# data:	Matrix with the data for this segment (n_rows by n_columns)
# text:	Empty cell array (since datasets have no text)
# comment:	Cell array with any comments
# proj4:	String with any proj4 information
# wkt:		String with any WKT information

	(object == C_NULL) && return GMTdataset()		# No output produced - return a null data set
	D = unsafe_load(convert(Ptr{GMT_DATASET}, object))

	seg_out = 0
	T = unsafe_wrap(Array, D.table, D.n_tables)
	for tbl = 1:D.n_tables
		DT = unsafe_load(T[tbl])
		for seg = 1:DT.n_segments
			S  = unsafe_wrap(Array, DT.segment, seg)
			DS = unsafe_load(S[seg])
			if (DS.n_rows != 0)
				seg_out = seg_out + 1
			end
		end
	end

	Darr = [GMTdataset() for i = 1:seg_out]					# Create the array of DATASETS

	seg_out = 1
	T = unsafe_wrap(Array, D.table, D.n_tables)				# D.n_tables-element Array{Ptr{GMT.GMT_DATATABLE},1}
	for tbl = 1:D.n_tables
		DT = unsafe_load(T[tbl])							# GMT.GMT_DATATABLE
		S = unsafe_wrap(Array, DT.segment, DT.n_segments)	# n_segments-element Array{Ptr{GMT.GMT_DATASEGMENT},1}
		for seg = 1:DT.n_segments
			DS = unsafe_load(S[seg])						# GMT.GMT_DATASEGMENT
			(DS.n_rows == 0) && continue 					# Skip empty segments

			C = unsafe_wrap(Array, DS.data, DS.n_columns)	# DS.data = Ptr{Ptr{Float64}}; C = Array{Ptr{Float64},1}
			dest = zeros(Float64, DS.n_rows, DS.n_columns)
			for col = 1:DS.n_columns						# Copy the data columns
				unsafe_copyto!(pointer(dest, DS.n_rows * (col - 1) + 1), unsafe_load(DS.data, col), DS.n_rows)
			end
			Darr[seg_out].data = dest

			if (DS.text != C_NULL)
				texts = unsafe_wrap(Array, DS.text, DS.n_rows)	# n_headers-element Array{Ptr{UInt8},1}
				if (texts != NULL)
					dest = Array{String}(undef, DS.n_rows)
					for row = 1:DS.n_rows					# Copy the text rows
						if (texts[row] != NULL)  dest[row] = unsafe_string(texts[row])  end
					end
					Darr[seg_out].text = dest
				end
			end

			if (DS.header != C_NULL)	Darr[seg_out].header = unsafe_string(DS.header)	end
			if (seg == 1)
				#headers = pointer_to_array(DT.header, DT.n_headers)	# n_headers-element Array{Ptr{UInt8},1}
				headers = unsafe_wrap(Array, DT.header, DT.n_headers)	# n_headers-element Array{Ptr{UInt8},1}
				dest = Array{String}(undef, length(headers))
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
function GMTJL_Set_Object(API::Ptr{Nothing}, X::GMT_RESOURCE, ptr, pad)
	# Create the object container and hook as X->object
	oo = unsafe_load(X.option)
	#module_input = (oo.option == GMT.GMT_OPT_INFILE)

	if (X.family == GMT_IS_GRID)			# Get a grid from Julia or a dummy one to hold GMT output
		X.object =  grid_init(API, ptr, X.direction, pad)
	elseif (X.family == GMT_IS_IMAGE)		# Get an image from Julia or a dummy one to hold GMT output
		X.object = image_init(API, ptr, X.direction)
	elseif (X.family == GMT_IS_DATASET)		# Get a dataset from Julia or a dummy one to hold GMT output
		# Ostensibly a DATASET, but it might be a TEXTSET passed via a cell array, so we must check
		actual_family = [GMT_IS_DATASET]		# Default but may change to matrix
		X.object = dataset_init_(API, ptr, X.direction, actual_family)
		X.family = actual_family[1]
	elseif (X.family == GMT_IS_PALETTE)		# Get a palette from Julia or a dummy one to hold GMT output
		if (!isa(ptr, GMTcpt) && X.direction == GMT_OUT)	# To avoid letting call palette_init() with a nothing
			X.object = GMT_Create_Data(API, GMT_IS_PALETTE, GMT_IS_NONE, GMT_IS_OUTPUT, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)
		else
			X.object = palette_init(API, ptr)
		end
	elseif (X.family == GMT_IS_POSTSCRIPT)	# Get a PostScript struct from Matlab or a dummy one to hold GMT output
		X.object = ps_init(API, ptr, X.direction)
	else
		error("GMTJL_Set_Object: Bad data type ($(X.family))")
	end
	(X.object == NULL) && error("GMT: Failure to register the resource")

	name = String([X.name...])
	# Make filename with embedded object ID
	(GMT_Open_VirtualFile(API, X.family, X.geometry, X.direction, X.object, name) != 0) && error("GMT: Failure to open virtual file") 
	# Replace ? in argument with name
	(GMT_Expand_Option(API, X.option, name) != 0) && error("GMT: Failure to expand filename marker (?)") 
	X.name = map(UInt8, (name...,))

	return X
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_Get_Object(API::Ptr{Nothing}, X::GMT_RESOURCE)
	name = String([X.name...])
	# In line-by-line modules it is possible no output is produced, hence we make an exception for DATASET
	((X.object = GMT_Read_VirtualFile(API, name)) == NULL && X.family != GMT_IS_DATASET) &&
		error("GMT: Error reading virtual file $name from GMT")
	if (X.family == GMT_IS_GRID)         	# A GMT grid; make it the pos'th output item
		ptr = get_grid(API, X.object)
	elseif (X.family == GMT_IS_DATASET)		# A GMT table; make it a matrix and the pos'th output item
		ptr = get_dataset(API, X.object)
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
function grid_init(API::Ptr{Nothing}, grd_box, dir::Integer=GMT_IN, pad::Int=2)
# If GRD_BOX is empty just allocate (GMT) an empty container and return
# If GRD_BOX is not empty it must contain a GMTgrid type.

	if (isempty_(grd_box))			# Just tell grid_init() to allocate an empty container
		return GMT_Create_Data(API, GMT_IS_GRID, GMT_IS_SURFACE, GMT_IS_OUTPUT,
		                       C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)
	end
	(!isa(grd_box, GMTgrid) && !isa(grd_box, Vector{GMTgrid})) &&
		error("grd_init: input ($(typeof(grd_box))) is not a GRID container type")

	grid_init(API, grd_box, pad)
end

# ---------------------------------------------------------------------------------------------------
function grid_init(API::Ptr{Nothing}, Grid::GMTgrid, pad::Int=2)
# We are given a Julia grid and use it to fill the GMT_GRID structure

	mode = (length(Grid.layout) > 1 && Grid.layout[2] == 'R') ? GMT_CONTAINER_ONLY : GMT_CONTAINER_AND_DATA
	(mode == GMT_CONTAINER_ONLY) && (pad = Grid.pad)		# Here we must follow what the Grid says it has

	hdr = [Grid.range; Grid.registration; Grid.inc]
	G = GMT_Create_Data(API, GMT_IS_GRID, GMT_IS_SURFACE, mode, C_NULL,
	                    hdr[1:4], hdr[8:9], UInt32(hdr[7]), pad)

	Gb = unsafe_load(G)			# Gb = GMT_GRID (constructor with 1 method)
	h = unsafe_load(Gb.header)

	if (mode == GMT_CONTAINER_AND_DATA)
		grd = Grid.z
		n_rows = size(grd, 1);		n_cols = size(grd, 2);		mx = n_cols + 2*pad;
		t = unsafe_wrap(Array, Gb.data, h.size)

		k = 1
		if (eltype(grd) == Float32)
			for col = 1:n_cols, row = n_rows:-1:1
				t[GMT_IJP(row, col, mx, pad, pad)] = grd[k];		k += 1
			end
		else
			for col = 1:n_cols, row = n_rows:-1:1
				t[GMT_IJP(row, col, mx, pad, pad)] = Float32(grd[k]);		k += 1
			end
		end
	else
		Gb.data = pointer(Grid.z)
		GMT_Set_AllocMode(API, GMT_IS_GRID, G)	# Otherwise memory already belongs to GMT
		#GMT_Set_Default(API, "API_GRID_LAYOUT", "TR");
	end

	h.z_min, h.z_max = hdr[5], hdr[6]		# Set the z_min, z_max

	try
		h.x_unit = map(UInt8, (Grid.x_unit...,))
		h.y_unit = map(UInt8, (Grid.y_unit...,))
		h.z_unit = map(UInt8, (Grid.z_unit...,))
	catch
		h.x_unit = map(UInt8, (string("x", repeat("\0",79))...,))
		h.y_unit = map(UInt8, (string("y", repeat("\0",79))...,))
		h.z_unit = map(UInt8, (string("z", repeat("\0",79))...,))
	end

	if (Grid.title != "")    h.title   = map(UInt8, (Grid.title...,))    end
	if (Grid.remark != "")   h.remark  = map(UInt8, (Grid.remark...,))   end
	if (Grid.command != "")  h.command = map(UInt8, (Grid.command...,))  end
	if (Grid.proj4 != "")    h.ProjRefPROJ4 = pointer(Grid.proj4)  end
	if (Grid.wkt != "")      h.ProjRefWKT   = pointer(Grid.wkt)    end
	if (Grid.epsg != 0)      h.ProjRefEPSG  = Int32(Grid.epsg)     end

	unsafe_store!(Gb.header, h)
	unsafe_store!(G, Gb)

	return G
end

# ---------------------------------------------------------------------------------------------------
function image_init(API::Ptr{Nothing}, img_box, dir::Integer=GMT_IN)
# ...

	if (isempty_(img_box))			# Just tell image_init() to allocate an empty container
		I = GMT_Create_Data(API, GMT_IS_IMAGE, GMT_IS_SURFACE, GMT_IS_OUTPUT,
		                    C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)
		if (img_mem_layout[1] != "")
			mem_layout = length(img_mem_layout[1]) == 3 ? img_mem_layout[1] * "a" : img_mem_layout[1]
			GMT_Set_Default(API, "API_IMAGE_LAYOUT", mem_layout);
		end
		return I
	end

	(!isa(img_box, GMTimage)) && error("image_init: input is not a IMAGE container type")
	return image_init(API, img_box)
end

# ---------------------------------------------------------------------------------------------------
function image_init(API::Ptr{Nothing}, Img::GMTimage, pad::Int=0)
# We are given a Julia image and use it to fill the GMT_IMAGE structure

	n_rows = size(Img.image, 1);		n_cols = size(Img.image, 2);		n_bands = size(Img.image, 3)
	if (Img.layout[2] == 'R')  n_rows, n_cols = n_cols, n_rows  end
	family = GMT_IS_IMAGE
	if (GMTver >= v"6.1" && (n_bands == 2 || n_bands == 4))	# Then we want the alpha layer together with data
		family = family | GMT_IMAGE_ALPHA_LAYER
	end
	(!CTRL.proj_linear[1]) && (pad = 2)
	mode = (pad == 2) ? GMT_CONTAINER_AND_DATA : GMT_CONTAINER_ONLY
	(pad == 2 && Img.pad == 0 && Img.layout[2] == 'R') && (mode = GMT_CONTAINER_AND_DATA)	# Unfortunately

	I = GMT_Create_Data(API, family, GMT_IS_SURFACE, mode, pointer([n_cols, n_rows, n_bands]),
	                    Img.range[1:4], Img.inc, Img.registration, pad)
	Ib = unsafe_load(I)				# Ib = GMT_IMAGE (constructor with 1 method)
	h = unsafe_load(Ib.header)

	if (pad == 2 && Img.layout[2] != 'R')						# When we need to project
		img_padded = unsafe_wrap(Array, convert(Ptr{UInt8}, Ib.data), h.size * n_bands)
		mx = n_cols + 2pad
		nRGBA = (n_bands == 1) ? 1 : ((n_bands == 3) ? 3 : 4)	# Don't know if RGBA will work`
		colVec = Vector{Int}(undef, n_cols)
		for band = 1:n_bands
			[colVec[n] = (n-1) * nRGBA + band-1 for n = 1:n_cols]
			k = 1
			for row = 1:n_rows
				off = nRGBA * pad + (pad + row - 1) * nRGBA * mx + 1	# Don't bloody ask!
				for col = 1:n_cols
					img_padded[colVec[col] + off] = Img.image[band + (k-1) * nRGBA];	k += 1
				end
			end
		end
		mem_owned_by_gmt = true
	elseif (pad == 2 && Img.pad == 0 && Img.layout[2] == 'R')	# Also need to project
		img_padded = unsafe_wrap(Array, convert(Ptr{UInt8}, Ib.data), h.size * n_bands)
		mx, k = n_cols + 2pad, 1
		for band = 1:n_bands
			off_band = (band - 1) * h.size
			for row = 1:n_rows
				off = pad * mx + (row - 1) * mx + pad + off_band
				for col = 1:n_cols
					img_padded[col + off] = Img.image[k];	k += 1
				end
			end
		end
		mem_owned_by_gmt = true
	else
		Ib.data = pointer(Img.image)
		mem_owned_by_gmt = (pad == 0) ? false : true
	end
	
	(mem_owned_by_gmt) && (CTRL.gmt_mem_bag[1] = Ib.data)	# Hold on the GMT owned array to be freed in gmt()

	if (length(Img.colormap) > 3)  Ib.colormap = pointer(Img.colormap)  end
	Ib.n_indexed_colors = Img.n_colors
	if (Img.color_interp != "")    Ib.color_interp = pointer(Img.color_interp)  end
	if (size(Img.alpha) != (1,1))  Ib.alpha = pointer(Img.alpha)
	else                           Ib.alpha = C_NULL
	end

	GMT_Set_AllocMode(API, GMT_IS_IMAGE, I)		# Tell GMT that memory is external
	h.z_min = Img.range[5]			# Set the z_min, z_max
	h.z_max = Img.range[6]
	h.mem_layout = map(UInt8, (Img.layout...,))
	if (Img.proj4 != "")    h.ProjRefPROJ4 = pointer(Img.proj4)  end
	if (Img.wkt != "")      h.ProjRefWKT   = pointer(Img.wkt)    end
	if (Img.epsg != 0)      h.ProjRefEPSG  = Int32(Img.epsg)     end
	unsafe_store!(Ib.header, h)
	unsafe_store!(I, Ib)

	if (!startswith(Img.layout, "BRP"))
		img = (mem_owned_by_gmt) ? img_padded : deepcopy(Img.image)
		GMT_Change_Layout(API, GMT_IS_IMAGE, "BRP", 0, I, img);		# Convert to BRP
		Ib.data = pointer(img)
		unsafe_store!(I, Ib)
	end

	return I
end

# ---------------------------------------------------------------------------------------------------
function dataset_init_(API::Ptr{Nothing}, Darr, direction::Integer, actual_family)
# Create containers to hold or receive data tables:
# direction == GMT_IN:  Create empty GMT_DATASET container, fill from Julia, and use as GMT input.
#	Input from Julia may be a structure or a plain matrix
# direction == GMT_OUT: Create empty GMT_DATASET container, let GMT fill it out, and use for Julia output.
# If direction is GMT_IN then we are given a Julia struct and can determine dimension.
# If output then we dont know size so we set dimensions to zero.

	if (direction == GMT_OUT)
		return GMT_Create_Data(API, GMT_IS_DATASET, GMT_IS_PLP, GMT_IS_OUTPUT, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)
	end

	(Darr == C_NULL) && error("Input is empty where it can't be.")
	if (isa(Darr, GMTdataset))	Darr = [Darr]	end 	# So the remaining algorithm works for all cases
	if (!(isa(Darr, Array{<:GMTdataset,1})))	# Got a matrix as input, pass data pointers via MATRIX to save memory
		D = dataset_init(API, Darr, direction, actual_family)
		return D
	end

	# We come here if we did not receive a matrix
	dim = [1, 0, 0, 0]
	dim[GMT.GMT_SEG+1] = length(Darr)				# Number of segments
	(dim[GMT.GMT_SEG+1] == 0) && error("Input has zero segments where it can't be")
	dim[GMT.GMT_COL+1] = size(Darr[1].data, 2)		# Number of columns

	mode = (length(Darr[1].text) != 0) ? GMT_WITH_STRINGS : GMT_NO_STRINGS

	pdim = pointer(dim)
	D = GMT_Create_Data(API, GMT_IS_DATASET, GMT_IS_PLP, mode, pdim, C_NULL, C_NULL, 0, 0, C_NULL)
	DS = unsafe_load(D)

	DT = unsafe_load(unsafe_load(DS.table))				# GMT.GMT_DATATABLE

	n_records = 0
	for seg = 1:dim[GMT.GMT_SEG+1] 						# Each incoming structure is a new data segment
		dim[GMT.GMT_ROW+1] = size(Darr[seg].data, 1)	# Number of rows in matrix
		if (dim[GMT.GMT_ROW+1] == 0)					# When we have only text
			dim[GMT.GMT_ROW+1] = size(Darr[seg].text, 1)
		end

		# This segment also has a cell array of strings?
		mode = (length(Darr[seg].text) != 0) ? GMT_WITH_STRINGS : GMT_NO_STRINGS

		DSv = convert(Ptr{Nothing}, unsafe_load(DT.segment, seg))		# DT.segment = Ptr{Ptr{GMT.GMT_DATASEGMENT}}
		S = GMT_Alloc_Segment(API, mode, dim[GMT.GMT_ROW+1], dim[GMT.GMT_COL+1], Darr[seg].header, DSv) # Ptr{GMT_DATASEGMENT}
		Sb = unsafe_load(S)								# GMT_DATASEGMENT;		Sb.data -> Ptr{Ptr{Float64}}
		for col = 1:Sb.n_columns						# Copy the data columns
			#unsafe_store!(Sb.data, pointer(Darr[seg].data[:,col]), col)	# This would allow shared mem
			unsafe_copyto!(unsafe_load(Sb.data, col), pointer(Darr[seg].data[:,col]), Sb.n_rows)
		end

		if (mode == GMT_WITH_STRINGS)	# Add in the trailing strings
			for row = 1:Sb.n_rows
				unsafe_store!(Sb.text, GMT_Duplicate_String(API, Darr[seg].text[row]), row)
			end
		end

		n_records += Sb.n_rows							# Must manually keep track of totals
		if (seg == 1 && length(Darr[1].comment) > 0)	# First segment may have table information
			for k = 1:size(Darr[1].comment,1)
				if (GMT_Set_Comment(API, GMT_IS_DATASET, GMT_COMMENT_IS_TEXT, convert(Ptr{Nothing},
					                pointer(Darr[1].comment[k])), convert(Ptr{Nothing}, D)) != 0)
					println("dataset_init_: Failed to set a dataset header")
				end
			end
		end

		if (mode == GMT_WITH_STRINGS)
			DS.type_ = (DS.n_columns != 0) ? GMT_READ_MIXED : GMT_READ_TEXT
		else
			DS.type_ = GMT_READ_DATA
		end

		unsafe_store!(S, Sb)
		unsafe_store!(DT.segment, S, seg)
	end
	DT.n_records = n_records
	DS.n_records = n_records

	return D
end

# ---------------------------------------------------------------------------------------------------
function dataset_init(API::Ptr{Nothing}, ptr, direction::Integer, actual_family)
# Used to create containers to hold or receive data:
# direction == GMT_IN:  Create empty Matrix container, associate it with julia data matrix, and use as GMT input.
# direction == GMT_OUT: Create empty Vector container, let GMT fill it out, and use for output.
# Note that in GMT these will be considered DATASETs via GMT_MATRIX or GMT_VECTOR.
# If direction is GMT_IN then we are given a Julia matrix and can determine size, etc.
# If output then we dont know size so all we do is specify data type.

	if (direction == GMT_IN) 	# Dimensions are known, extract them and set dim array for a GMT_MATRIX resource */
		dim = pointer([size(ptr,2), size(ptr,1), 0])	# MATRIX in GMT uses (col,row)
		M = GMT_Create_Data(API, GMT_IS_MATRIX|GMT_VIA_MATRIX, GMT_IS_PLP, 0, dim, C_NULL, C_NULL, 0, 0, C_NULL)
		actual_family[1] = actual_family[1] | GMT_VIA_MATRIX

		Mb = unsafe_load(M)			# Mb = GMT_MATRIX (constructor with 1 method)
		#tipo = get_datatype(ptr)
		Mb.n_rows    = size(ptr,1)
		Mb.n_columns = size(ptr,2)

		if (eltype(ptr)     == Float64)		Mb.type = UInt32(GMT.GMT_DOUBLE)
		elseif (eltype(ptr) == Float32)		Mb.type = UInt32(GMT.GMT_FLOAT)
		elseif (eltype(ptr) == UInt64)		Mb.type = UInt32(GMT.GMT_ULONG)
		elseif (eltype(ptr) == Int64)		Mb.type = UInt32(GMT.GMT_LONG)
		elseif (eltype(ptr) == UInt32)		Mb.type = UInt32(GMT.GMT_UINT)
		elseif (eltype(ptr) == Int32)		Mb.type = UInt32(GMT.GMT_INT)
		elseif (eltype(ptr) == UInt16)		Mb.type = UInt32(GMT.GMT_USHORT)
		elseif (eltype(ptr) == Int16)		Mb.type = UInt32(GMT.GMT_SHORT)
		elseif (eltype(ptr) == UInt8)		Mb.type = UInt32(GMT.GMT_UCHAR)
		elseif (eltype(ptr) == Int8)		Mb.type = UInt32(GMT.GMT_CHAR)
		else
			error("Only integer or floating point types allowed in input. Not this: $(typeof(ptr))")
		end
		Mb.data = pointer(ptr)
		Mb.dim  = Mb.n_rows		# Data from Julia is in column major
		GMT_Set_AllocMode(API, GMT_IS_MATRIX, M)
		Mb.shape = GMT.GMT_IS_COL_FORMAT;			# Julia order is column major
		unsafe_store!(M, Mb)
		return M

	else	# To receive data from GMT we use a GMT_VECTOR resource instead
		# There are no dimensions and we are just getting an empty container for output
		return GMT_Create_Data(API, GMT_IS_VECTOR, GMT_IS_PLP, GMT_IS_OUTPUT, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)
	end
end

# ---------------------------------------------------------------------------------------------------
function palette_init(API::Ptr{Nothing}, cpt::GMTcpt)
	# Create and fill a GMT CPT.

	n_colors = size(cpt.colormap, 1)	# n_colors != n_ranges for continuous CPTs
	n_ranges = size(cpt.range, 1)
	one = 0
	if (n_colors > n_ranges)		# Continuous
		n_ranges = n_colors;		# Actual length of colormap array
		n_colors = n_colors - 1;	# Number of CPT slices
		one = 1
	end

	P::Ptr{GMT.GMT_PALETTE} = GMT_Create_Data(API, GMT_IS_PALETTE, GMT_IS_NONE, 0, pointer([n_colors]), C_NULL, C_NULL, 0, 0, C_NULL)

	(one != 0) && mutateit(API, P, "is_continuous", one)

	if (cpt.depth == 1)      mutateit(API, P, "is_bw", 1)
	elseif (cpt.depth == 8)  mutateit(API, P, "is_gray", 1)
	end
	!isnan(cpt.hinge) && mutateit(API, P, "has_hinge", 1)

	Pb = unsafe_load(P)				# We now have a GMT.GMT_PALETTE

	if (!isnan(cpt.hinge))			# If we have a hinge pass it in to the GMT owned struct
		Pb.hinge = cpt.hinge
		Pb.mode = Pb.mode & GMT.GMT_CPT_HINGED
	end

	Pb.model = (cpt.model == "rgb") ? GMT_RGB : ((cpt.model == "hsv") ? GMT_HSV : GMT_CMYK)

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
		# GMT6.1 bug does not free "key" but frees "label" and does not see if memory is external. Hence crash or mem leaks
		_key = (cpt.key[j] == "" || GMTver >= v"6.2") ? glut.key : pointer(cpt.key[j])	# All it's possible in GMT < 6.2

		annot = (j == Pb.n_colors) ? 3 : 1				# Annotations L for all but last which is B(oth)
		lut = GMT_LUT(z_low, z_high, glut.i_dz, rgb_low, rgb_high, glut.rgb_diff, glut.hsv_low, glut.hsv_high,
		              glut.hsv_diff, annot, glut.skip, glut.fill, glut.label, _key)

		unsafe_store!(Pb.data, lut, j)
	end
	unsafe_store!(P, Pb)

	# For Categorical case was half broken till 6.2 so we must treat things differently
	if (cpt.key[1] != "" && GMTver >= v"6.2")
		GMT_Put_Strings(API, GMT_IS_PALETTE | GMT_IS_PALETTE_KEY, convert(Ptr{Cvoid}, P), cpt.key);
		if (cpt.label[1] != "")
			GMT_Put_Strings(API, GMT_IS_PALETTE | GMT_IS_PALETTE_LABEL, convert(Ptr{Cvoid}, P), cpt.label);
		end
		mutateit(API, P, "categorical", 2)
	elseif (cpt.key[1] != "")
		mutateit(API, P, "categorical", 2)
	end

	return P
end

# ---------------------------------------------------------------------------------------------------
function ps_init(API::Ptr{Nothing}, ps, dir::Integer)
# Used to Create an empty POSTSCRIPT container to hold a GMT POSTSCRIPT object.
# If direction is GMT_IN then we are given a Julia structure with known sizes.
# If direction is GMT_OUT then we allocate an empty GMT POSTSCRIPT as a destination.
	if (dir == GMT_OUT)
		return GMT_Create_Data(API, GMT_IS_POSTSCRIPT, GMT_IS_NONE, GMT_IS_OUTPUT, C_NULL, C_NULL, C_NULL, 0, 0, C_NULL)
	end

	(!isa(ps, GMTps)) && error("Expected a PS structure for input")

	# Passing dim[0] = 0 since we dont want any allocation of a PS string
	pdim = pointer([0])
	P = GMT_Create_Data(API, GMT_IS_POSTSCRIPT, GMT_IS_NONE, 0, pdim, NULL, NULL, 0, 0, NULL)

	P0 = unsafe_load(P)		# GMT.GMT_POSTSCRIPT

	P0.n_bytes = ps.length
	P0.mode = ps.mode
	P0.data = pointer(ps.postscript)
	GMT_Set_AllocMode(API, GMT_IS_POSTSCRIPT, P)

	unsafe_store!(P, P0)
	return P
end

# ---------------------------------------------------------------------------------------------------
function ogr2GMTdataset(in::Ptr{OGR_FEATURES}, drop_islands=false)
	(in == NULL)  && return nothing
	OGR_F = unsafe_load(in)
	n_max = OGR_F.n_rows * OGR_F.n_cols * OGR_F.n_layers
	n_total_segments = OGR_F.n_filled

	if (!drop_islands)
		# First count the number of islands. Need to know the size to put in the D pre-allocation
		n_islands = OGR_F.n_islands
		for k = 2:n_max
			OGR_F = unsafe_load(in, k)
			n_islands += OGR_F.n_islands
		end
		n_total_segments += n_islands
	end

	D = Vector{GMTdataset}(undef, n_total_segments)

	n = 1
	for k = 1:n_max
		OGR_F = unsafe_load(in, k)
		if (k == 1)
			proj4 = OGR_F.proj4 != C_NULL ? unsafe_string(OGR_F.proj4) : ""
			wkt   = OGR_F.wkt != C_NULL ? unsafe_string(OGR_F.wkt) : ""
		else
			proj4 = wkt = ""
		end
		if (OGR_F.np > 0)
			hdr = (OGR_F.att_number > 0) ? join([@sprintf("%s,", unsafe_string(unsafe_load(OGR_F.att_values,i))) for i = 1:OGR_F.att_number]) : ""
			if (hdr != "")  hdr = rstrip(hdr, ',')  end		# Strip last ','
			if (OGR_F.n_islands == 0)
				D[n] = GMTdataset([unsafe_wrap(Array, OGR_F.x, OGR_F.np) unsafe_wrap(Array, OGR_F.y, OGR_F.np)],
				                   Array{String,1}(), hdr, Array{String,1}(), proj4, wkt)
			else
				# In this case, for the time being, I'm droping the islands
				islands = reshape(unsafe_wrap(Array, OGR_F.islands, 2 * (OGR_F.n_islands+1)), OGR_F.n_islands+1, 2) 
				np_main = islands[1,2]+1		# Number of points of outer ring
				D[n] = GMTdataset([unsafe_wrap(Array, OGR_F.x, np_main) unsafe_wrap(Array, OGR_F.y, np_main)],
				                   Array{String,1}(), hdr, Array{String,1}(), proj4, wkt)

				if (!drop_islands)
					for k = 2:size(islands,2)		# 2 because first row holds the outer ring indexes 
						n = n + 1
						off = islands[k,1] * 8
						len = islands[k,2] - islands[k,1] + 1
						D[n] = GMTdataset([unsafe_wrap(Array, OGR_F.x+off, len) unsafe_wrap(Array, OGR_F.y+off, len)],
						                   Array{String,1}(), " -Ph", Array{String,1}(), proj4, wkt)
					end
				end
			end
			n = n + 1
		end
	end
	(n_total_segments > (n-1)) && deleteat!(D, n:n_total_segments)
	return D
end

#= ---------------------------------------------------------------------------------------------------
function convert_string(str)
# Convert a string stored in one of those GMT.Array_XXX_Uint8 types into an ascii string
	k = 1
	while (str.(k) != UInt8(0))
		k = k + 1
	end
	out = join([Char(str.(n)) for n=1:k])
end
=#

#= ---------------------------------------------------------------------------------------------------
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
	if (var === nothing)		return DOUBLE_CLASS	end		# Motivated by project -G

	println("Unable to discovery this data type - Default to double")
	return DOUBLE_CLASS
end
=#

# ---------------------------------------------------------------------------------------------------
function strncmp(str1::String, str2::String, num)
	# Pseudo strncmp
	a = str1[1:min(num,length(str1))] == str2
end

# ---------------------------------------------------------------------------------------------------
function mutateit(API::Ptr{Nothing}, t_type, member::String, val)
	# Mutate the member 'member' of an immutable struct whose pointer is T_TYPE
	# VAL is the new value of the MEMBER field.
	# It's up to the user to guarantie that MEMBER and VAL have the same data type
	# T_TYPE can actually be either a variable of a certain struct or a pointer to it.
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
	fo = map(idx->fieldoffset(dt, idx), 1:fieldcount(dt))
	ind = findfirst(isequal(Symbol(member)), fieldnames(dt))	# Find the index of the "is_continuous" member
	# This would work too
	# ind = ccall(:jl_field_index, Cint, (Any, Any, Cint), dt, symbol(member), 1) + 1
	p_val = (isa(val, AbstractString)) ? pointer(val) : pointer([val])		# No idea why I have to do this
	GMT_blind_change_struct(API, p_type, p_val, @sprintf("%s",ft[ind]), fo[ind])
	typeof(p_type); 	typeof(p_val)		# Just to be sure that GC doesn't kill them before their due time
end

# ---------------------------------------------------------------------------------------------------
function num2str(mat)
# Pseudo num2str, but returns all in a cell array of strings and no precision control yet.
	n_cols = size(mat, 2);		n_rows = size(mat, 1)
	out = Array{String}(undef, n_rows)
	for nr = 1:n_rows
		out[nr] = join([@sprintf("%s\t", mat[nr,k]) for k=1:n_cols-1])
		out[nr] = string(out[nr], mat[nr,n_cols])
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
#=
"""
Inquire about GMT version. Will return 5.3 for all versions up to this one and the truth for rest
"""
function get_GMTversion(API::Ptr{Nothing})
	status = GMT_Call_Module(API, "psternary", GMT.GMT_MODULE_EXIST, C_NULL)
	ver = 5.3
	if (status == 0)
		value = "        "
		GMT_Get_Default(API, "API_VERSION", value)
		ver = Meta.parse(value[1:3])
	end
end
=#

# ---------------------------------------------------------------------------------------------------
function text_record(data, text, hdr=Vector{String}())
	# Create a text record to send to pstext. DATA is the Mx2 coordinates array.
	# TEXT is a string or a cell array

	if (isa(data, Vector))  data = data[:,:]  end 	# Needs to be 2D
	if (!isa(data, Array{Float64}))  data = Float64.(data)  end

	if (isa(text, String))
		T = GMTdataset(data, [text], "", Vector{String}(), "", "")
	elseif (isa(text, Array{String}))
		if (text[1][1] == '>')			# Alternative (but risky) way of setting the header content
			T = GMTdataset(data, text[2:end], text[1], Vector{String}(), "", "")
		else
			T = GMTdataset(data, text, (isempty(hdr) ? "" : hdr), Vector{String}(), "", "")
		end
	elseif (isa(text, Array{Array}) || isa(text, Array{Vector{String}}))
		nl_t = length(text);	nl_d = length(data)
		(nl_d > 0 && nl_d != nl_t) && error("Number of data points is not equal to number of text strings.")
		T = Vector{GMTdataset}(undef,nl_t)
		for k = 1:nl_t
			T[k] = GMTdataset((nl_d == 0 ? data : data[k]), text[k], (isempty(hdr) ? "" : hdr[k]), Vector{String}(), "", "")
		end
	else
		error("Wrong type ($(typeof(text))) for the 'text' argin")
	end
	return T
end
text_record(text) = text_record(Array{Float64,2}(undef,0,0), text)
text_record(text::Array{String}, hdr::String) = text_record(Array{Float64,2}(undef,0,0), text, hdr)

# ---------------------------------------------------------------------------------------------------
"""
    D = mat2ds(mat [,txt]; x=nothing, hdr=nothing, color=nothing, fill=nothing, ls=nothing, text=nothing, multi=false)

Take a 2D `mat` array and convert it into a GMTdataset. `x` is an optional coordinates vector (must have the
same number of elements as rows in `mat`). Use `x=:ny` to generate a coords array 1:n_rows of `mat`.
- `hdr` optional String vector with either one or n_rows multisegment headers.
- `color` optional array of strings with color names/values. Its length can be smaller than n_rows, case in
   which colors will be cycled.
- `linethick`, or `lt` for selecting different line thicknesses. Work alike `color`, but should be 
   a vector of numbers, or just a single number that is then appl	ied to all lines.
- `fill`  Optional string array with color names or array of "patterns"
- `ls`    Line style. A string or an array of strings with ``length = size(mat,1)`` with line styles.
- `txt`   Return a Text record which is a Dataset with data = Mx2 and text in third column. The ``text``
   can be an array with same size as ``mat``rows or a string (will be reapeated n_rows times.) 
- `multi` When number of columns in `mat` > 2, or == 2 and x != nothing, make an multisegment Dataset with
   first column and 2, first and 3, etc. Convenient when want to plot a matrix where each column is a line. 
"""
function mat2ds(mat, txt=Vector{String}(); hdr=Vector{String}(), kwargs...)
	d = KW(kwargs)

	(!isempty(txt)) && return text_record(mat, txt,  hdr)
	((text = find_in_dict(d, [:text])[1]) !== nothing) && return text_record(mat, text, hdr)

	val = find_in_dict(d, [:multi :multicol])[1]
	multi = (val === nothing) ? false : ((val) ? true : false)	# Like this it will error if val is not Bool

	if ((x = find_in_dict(d, [:x])[1]) !== nothing)
		n_ds = (multi) ? size(mat, 2) : 1
		xx = (x == :ny || x == "ny") ? collect(1.0:size(mat, 1)) : x
		(length(xx) != size(mat, 1)) && error("Number of X coordinates and MAT number of rows are not equal")
	else
		n_ds = (ndims(mat) == 3) ? size(mat,3) : ((multi) ? size(mat, 2) - 1 : 1)
		xx = Vector{Float64}()
	end

	if (!isempty(hdr) && isa(hdr, String))	# Accept one only but expand to n_ds with the remaining as blanks
		bak = hdr;		hdr = Base.fill("", n_ds);	hdr[1] = bak
	elseif (!isempty(hdr) && length(hdr) != n_ds)
		error("The header vector can only have length = 1 or same number of MAT Y columns")
	end

	if ((color = find_in_dict(d, [:color])[1]) !== nothing)
		_color::Array{String} = isa(color, Array{String}) ? color : ["#0072BD", "#D95319", "#EDB120", "#7E2F8E", "#77AC30", "#4DBEEE", "#A2142F"]
	end
	_fill = helper_ds_fill(d)

	# ---  Here we deal with line colors and line thickness. If not provided we override the GMR defaultb -Wthin ---
	val = find_in_dict(d, [:lt :linethick :linethickness])[1]
	_lt = (val === nothing) ? [0.5] : val
	_lts = Vector{String}(undef, n_ds)
	n_thick = length(_lt)
	[_lts[k] = " -W" * string(_lt[((k % n_thick) != 0) ? k % n_thick : n_thick])  for k = 1:n_ds]

	if (color !== nothing)
		n_colors = length(_color)
		if (isempty(hdr))
			hdr = Vector{String}(undef, n_ds)
			[hdr[k]  = _lts[k] * string(",", _color[((k % n_colors) != 0) ? k % n_colors : n_colors])  for k = 1:n_ds]
		else
			[hdr[k] *= _lts[k] * string(",", _color[((k % n_colors) != 0) ? k % n_colors : n_colors])  for k = 1:n_ds]
		end
	else						# Here we just overriding the GMT -W default that is too thin.
		if (isempty(hdr))
			hdr = Vector{String}(undef, n_ds)
			[hdr[k]  = _lts[k] for k = 1:n_ds]
		else
			[hdr[k] *= _lts[k] for k = 1:n_ds]
		end
	end
	# ----------------------------------------

	if ((ls = find_in_dict(d, [:ls :linestyle])[1]) !== nothing && ls != "")
		if (isa(ls, AbstractString) || isa(ls, Symbol))
			[hdr[k] = string(hdr[k], ',', ls) for k = 1:n_ds]
		else
			[hdr[k] = string(hdr[k], ',', ls[k]) for k = 1:n_ds]
		end
	end

	if (!isempty(_fill))				# Paint the polygons (in case of)
		n_colors = length(_fill)
		if (isempty(hdr))
			hdr = Array{String,1}(undef, n_ds)
			[hdr[k]  = " -G" * _fill[((k % n_colors) != 0) ? k % n_colors : n_colors]  for k = 1:n_ds]
		else
			[hdr[k] *= " -G" * _fill[((k % n_colors) != 0) ? k % n_colors : n_colors]  for k = 1:n_ds]
		end
	end

	prj = ((proj = find_in_dict(d, [:proj :proj4])[1]) !== nothing) ? proj : ""
	(prj != "" && !startswith(prj, "+proj=")) && (prj = "+proj=" * prj)
	wkt = ((wk = find_in_dict(d, [:wkt])[1]) !== nothing) ? wk : ""

	D = Vector{GMTdataset}(undef, n_ds)

	if (!isa(mat, Array{Float64}))  mat = Float64.(mat)  end
	if (isempty(xx))
		if (ndims(mat) == 3)
			for k = 1:n_ds
				D[k] = GMTdataset(view(mat,:,:,k), String[], (isempty(hdr) ? "" : hdr[k]), String[], prj, wkt)
			end
		elseif (!multi)
			D[1] = GMTdataset(mat, String[], (isempty(hdr) ? "" : hdr[1]), String[], prj, wkt)
		else
			for k = 1:n_ds
				D[k] = GMTdataset(mat[:,[1,k+1]], String[], (isempty(hdr) ? "" : hdr[k]), String[], prj, wkt)
			end
		end
	else
		if (!multi)
			D[1] = GMTdataset(hcat(xx,mat), String[], (isempty(hdr) ? "" : hdr[1]), String[], prj, wkt)
		else
			for k = 1:n_ds
				D[k] = GMTdataset(hcat(xx,mat[:,k]), String[], (isempty(hdr) ? "" : hdr[k]), String[], prj, wkt)
			end
		end
	end
	return D
end

# ---------------------------------------------------------------------------------------------------
function ds2ds(D::GMTdataset; kwargs...)::Vector{GMTdataset}
	# Take one DS and split it in an array of DS, one for each row and optionally add -G,fill>
	# So far only for internal use but may grow in function of needs
	d = KW(kwargs)

	#multi = "r"		# Default split by rows
	#if ((val = find_in_dict(d, [:multi])[1]) !== nothing)  multi = "c"  end		# Then by columns
	_fill = helper_ds_fill(d)

	if ((val = find_in_dict(d, [:color_wrap])[1]) !== nothing)	# color_wrap is a kind of private option for bar-stack
		n_colors = Int(val)
	end

	n_ds = size(D.data, 1)
	if (!isempty(_fill))				# Paint the polygons (in case of)
		hdr = Vector{String}(undef, n_ds)
		[hdr[k] = " -G" * _fill[((k % n_colors) != 0) ? k % n_colors : n_colors]  for k = 1:n_ds]
		if (D.header != "")  hdr[1] = D.header * hdr[1]  end	# Copy eventual contents of first header
	end

	Dm = Vector{GMTdataset}(undef, n_ds)
	for k = 1:n_ds
		Dm[k] = GMTdataset(D.data[k:k, :], String[], (isempty(_fill) ? "" : hdr[k]), String[], "", "")
	end
	Dm[1].comment = D.comment;	Dm[1].proj4 = D.proj4;	Dm[1].wkt = D.wkt
	(size(D.text) == n_ds) && [Dm.text[k] = D.text[k] for k = 1:n_ds]
	Dm
end

# ------------------------------
function helper_ds_fill(d::Dict)
	# Shared by ds2ds & mat2ds
	if ((fill_val = find_in_dict(d, [:fill :fillcolor])[1]) !== nothing)
		_fill::Array{String} = (isa(fill_val, Array{String}) && !isempty(fill_val)) ? fill_val :
		                       ["#0072BD", "#D95319", "#EDB120", "#7E2F8E", "#77AC30", "#4DBEEE", "#A2142F", "0/255/0"]
		n_colors = length(_fill)
		if ((alpha_val = find_in_dict(d, [:fillalpha])[1]) !== nothing)
			if (eltype(alpha_val) <: AbstractFloat && maximum(alpha_val) <= 1)  alpha_val = collect(alpha_val) .* 100  end
			_alpha = Vector{String}(undef, n_colors)
			na = min(length(alpha_val), n_colors)
			[_alpha[k] = join(string('@',alpha_val[k])) for k = 1:na]
			(na < n_colors) && [_alpha[k] = "" for k = na+1:n_colors]
			[_fill[k] *= _alpha[k] for k = 1:n_colors]		# And finaly apply the transparency
		end
	else
		_fill = Vector{String}()
	end
	return _fill
end

# ---------------------------------------------------------------------------------------------------
"""
    I = mat2img(mat::Array{<:Unsigned}; x=[], y=[], hdr=nothing, proj4::String="", wkt::String="", cmap=nothing, kw...)

Take a 2D 'mat' array and a HDR 1x9 [xmin xmax ymin ymax zmin zmax reg xinc yinc] header descriptor
and return a GMTimage type.
Alternatively to HDR, provide a pair of vectors, x & y, with the X and Y coordinates.
Optionaly, the HDR arg may be ommited and it will computed from 'mat' alone, but then x=1:ncol, y=1:nrow
When 'mat' is a 3D UInt16 array we automatically compute a UInt8 RGB image. In that case 'cmap' is ignored.
But if no conversion is wanted use option 'noconv=true'

    I = mat2img(mat::Array{UInt16}; x=[], y=[], hdr=nothing, proj4::String="", wkt::String="", kw...)

Take a `mat` array of UInt16 and scale it down to UInt8. Input can be 2D or 3D.
If the kw variable `stretch` is used, we stretch the intervals in `stretch` to [0 255].
Use this option to stretch the image histogram.
If `stretch` is a scalar, scale the values > `stretch` to [0 255]
  stretch = [v1 v2] scales all values >= v1 && <= v2 to [0 255]
  stretch = [v1 v2 v3 v4 v5 v6] scales firts band >= v1 && <= v2 to [0 255], second >= v3 && <= v4, same for third
  stretch = :auto | "auto" | true | 1 will do an automatic stretching from values obtained from histogram thresholds
"""
function mat2img(mat::Array{<:Unsigned}, dumb::Int=0; x=Vector{Float64}(), y=Vector{Float64}(), hdr=nothing, proj4::String="", wkt::String="", cmap=nothing, kw...)
	# Take a 2D array of uint8 and turn it into a GMTimage.
	color_interp = "";		n_colors = 0;
	if (cmap !== nothing)
		have_alpha = !all(cmap.alpha .== 0.0)
		nc = have_alpha ? 4 : 3
		colormap = zeros(Clong, 256 * nc)
		n_colors = 256;			# Because for GDAL we always send 256 even if they are not all filled
		@inbounds for n = 1:3	# Write 'colormap' row-wise
			@inbounds for m = 1:size(cmap.colormap, 1)
				colormap[m + (n-1)*n_colors] = round(Int32, cmap.colormap[m,n] * 255);
			end
		end
		if (have_alpha)			# Have alpha color(s)
			[colormap[m + 3*n_colors] = round(Int32, cmap.colormap[m,4] * 255) for m = 1:size(cmap.colormap, 1)]
			n_colors *= 1000				# Flag that we have alpha colors in an indexed image
		end
	else
		if (size(mat,3) == 1)  color_interp = "Gray"  end
		colormap = zeros(Clong,3)			# Because we need an array
	end

	nx = size(mat, 2);		ny = size(mat, 1);
	x, y, hdr, x_inc, y_inc = grdimg_hdr_xy(mat, 1, hdr, x, y)

	mem_layout = (size(mat,3) == 1) ? "TCBa" : "TCBa"		# Just to have something. Likely wrong for 3D
	d = KW(kw)
	if ((val = find_in_dict(d, [:layout :mem_layout])[1]) !== nothing)  mem_layout = string(val)  end

	I = GMTimage(proj4, wkt, 0, hdr[:], [x_inc, y_inc], 1, NaN, color_interp,
	             x,y,mat, colormap, n_colors, Array{UInt8,2}(undef,1,1), mem_layout, 0)
end

# ---------------------------------------------------------------------------------------------------
function mat2img(mat::Array{UInt16}; x=Vector{Float64}(), y=Vector{Float64}(), hdr=nothing, proj4::String="", wkt::String="", kw...)
	# Take an array of UInt16 and scale it down to UInt8. Input can be 2D or 3D.
	# If the kw variable 'stretch' is used, we stretch the intervals in 'stretch' to [0 255].
	# Use this option to stretch the image histogram.
	# If 'stretch' is a scalar, scale the values > 'stretch' to [0 255]
	# stretch = [v1 v2] scales all values >= v1 && <= v2 to [0 255]
	# stretch = [v1 v2 v3 v4 v5 v6] scales firts band >= v1 && <= v2 to [0 255], second >= v3 && <= v4, same for third
	d = KW(kw)
	if ((val = find_in_dict(d, [:noconv])[1]) !== nothing)		# No conversion to UInt8 is wished
		return mat2img(mat, 1; x=x, y=y, hdr=hdr, proj4=proj4, wkt=wkt, d...)
	end
	img = Array{UInt8}(undef,size(mat));
	if ((vals = find_in_dict(d, [:histo_bounds :stretch], false)[1]) !== nothing)
		nz = 1
		isa(mat, Array{UInt16,3}) ? (ny, nx, nz) = size(mat) : (ny, nx) = size(mat)

		(vals == "auto" || vals == :auto || (isa(vals, Bool) && vals) || (isa(vals, Number) && vals == 1)) &&
			(vals = [find_histo_limits(mat)...])	# Out is a tuple, convert to vector
		len = length(vals)

		(len > 2*nz) && error("'stretch' has more elements then allowed by image dimensions")
		(len != 1 && len != 2 && len != 6) &&
			error("Bad 'stretch' argument. It must be a 1, 2 or 6 elements array and not $len")

		val = (len == 1) ? convert(UInt16, vals)::UInt16 : convert(Array{UInt16}, vals)::Array{UInt16}
		if (len == 1)
			sc = 255 / (65535 - val)
			@inbounds for k = 1:length(img)
				img[k] = (mat[k] < val) ? 0 : round(UInt8, (mat[k] - val) * sc)
			end
		elseif (len == 2)
			val = [parse(UInt16, @sprintf("%d", vals[1])) parse(UInt16, @sprintf("%d", vals[2]))]
			sc = 255 / (val[2] - val[1])
			@inbounds for k = 1:length(img)
				img[k] = (mat[k] < val[1]) ? 0 : ((mat[k] > val[2]) ? 255 : UInt8(round((mat[k]-val[1])*sc)))
			end
		else	# len = 6
			nxy = nx * ny
			v1 = [1 3 5];	v2 = [2 4 6]
			sc = [255 / (val[2] - val[1]), 255 / (val[4] - val[3]), 255 / (val[6] - val[5])]
			@inbounds for n = 1:nz, k = 1+(n-1)*nxy:n*nxy
				img[k] = (mat[k] < val[v1[n]]) ? 0 : ((mat[k] > val[v2[n]]) ? 255 : round(UInt8, (mat[k]-val[v1[n]])*sc[n]))
			end
		end
	else
		sc = 255/65535
		@inbounds @simd for k = 1:length(img)
			img[k] = round(UInt8, mat[k]*sc)
		end
	end
	mat2img(img; x=x, y=y, hdr=hdr, proj4=proj4, wkt=wkt, d...)
end

# ---------------------------------------------------------------------------------------------------
function mat2img(img::GMTimage; kw...)
	# Scale a UInt16 GMTimage to UInt8. Return a new object but with all old image parameters
	(!isa(img.image, Array{UInt16}))  && return img		# Nothing to do
	I = mat2img(img.image; kw...)
	I.proj4 = img.proj4;	I.wkt = img.wkt;	I.epsg = img.epsg
	I.range = img.range;	I.inc = img.inc;	I.registration = img.registration
	I.nodata = img.nodata;	I.color_interp = img.color_interp;
	I.x = img.x;	I.y = img.y;	I.colormap = img.colormap;
	I.n_colors = img.n_colors;		I.alpha = img.alpha;	I.layout = img.layout;
	return I
end

# ---------------------------------------------------------------------------------------------------
"""
    I = image_alpha!(img::GMTimage; alpha_ind::Integer, alpha_vec::Vector{Integer}, alpha_band::UInt8)

Change the alpha transparency of the GMTimage object 'img'. If the image is indexed, one can either
change just the color index that will be made transparent by uing 'alpha_ind=n' or provide a vector
of transaparency values in the range [0 255]; This vector can be shorter than the orginal number of colors.
Use `alpha_band` to change, or add, the alpha of true color images (RGB).

    Example1: change to the third color in cmap to represent the new transparent color
        image_alpha!(img, alpha_ind=3)

    Example2: change to the first 6 colors in cmap by assigning them random values
        image_alpha!(img, alpha_vec=round.(Int32,rand(6).*255))
"""
function image_alpha!(img::GMTimage; alpha_ind=nothing, alpha_vec=nothing, alpha_band=nothing)
	# Change the alpha transparency of an image
	n_colors = img.n_colors
	if (n_colors > 100000)  n_colors = Int(floor(n_colors / 1000))  end
	if (alpha_ind !== nothing)			# Change the index of the alpha color
		(alpha_ind < 0 || alpha_ind > 255) && error("Alpha color index must be in the [0 255] interval")
		img.n_colors = n_colors * 1000 + Int32(alpha_ind)
	elseif (alpha_vec !== nothing)		# Replace/add the alpha column of the colormap matrix. Allow also shorter vectors
		@assert(isa(alpha_vec, Vector{<:Integer}))
		(length(alpha_vec) > n_colors) && error("Length of alpha vector is larger than the number of colors")
		n_col = div(length(img.colormap), n_colors)
		vec = convert.(Int32, alpha_vec)
		if (n_col == 4)  img.colormap[(end-length(vec)+1):end] = vec;
		else             img.colormap = [img.colormap; [vec[:]; round.(Int32, ones(n_colors - length(vec)) .* 255)]]
		end
		img.n_colors = n_colors * 1000
	elseif (alpha_band !== nothing)		# Replace the entire alpha band
		@assert(isa(alpha_band, Array{<:UInt8, 2}))
		ny1, nx1, = size(img.image)
		ny2, nx2  = size(alpha_band)
		(ny1 != ny2 || nx1 != nx2) && error("alpha channel has wrong dimensions")
		(size(img.image, 3) != 3) ? @warn("Adding alpha band is restricted to true color images (RGB)") :
		                            img.alpha = alpha_band
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    image_cpt!(img::GMTimage, cpt::GMTcpt, clear::Bool=false)

Add (or replace) a colormap to a GMTimage object from the colors in the cpt.
This should have effect only if IMG is indexed.
Use `image_cpt!(img, clear=true)` to remove a previously existent `colormap` field in IMG
"""
function image_cpt!(img::GMTimage, cpt::GMTcpt)
	# Insert the cpt info in the img.colormap member
	n = 1
	colormap = fill(Int32(255), size(cpt.colormap,1) * 4)
	for k = 1:size(cpt.colormap,1)
		colormap[n:n+2] = round.(Int32, cpt.colormap[k,:] .* 255);	n += 3
	end
	img.colormap = colormap
	img.n_colors = size(cpt.colormap,1)
	return nothing
end
function image_cpt!(img::GMTimage; clear::Bool=true)
	if (clear)
		img.colormap, img.n_colors = fill(Int32(0), 3), 0
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    I = ind2rgb(I)

Convert an indexed image I to RGB. It uses the internal colormap to do the conversion.
"""
function ind2rgb(img::GMTimage)
	# ...
	(size(img.image, 3) >= 3) && return img 	# Image is already RGB(A)
	imgRGB = zeros(UInt8,size(img.image,1), size(img.image,2), 3)
	n = 1
	for k = 1:length(img.image)
		start_c = img.image[k] * 4
		for c = 1:3
			imgRGB[n] = img.colormap[start_c+c];	n += 1
		end
	end
	mat2img(imgRGB, x=img.x, y=img.y, proj4=img.proj4, wkt=img.wkt, mem_layout="BRPa")
end

# ---------------------------------------------------------------------------------------------------
"""
    G = mat2grid(mat; reg=nothing, x=[], y=[], hdr=nothing, proj4::String="", wkt::String="", tit::String="", rem::String="", cmd::String="")

Take a 2D `mat` array and a HDR 1x9 [xmin xmax ymin ymax zmin zmax reg xinc yinc] header descriptor
and return a grid GMTgrid type.
Alternatively to HDR, provide a pair of vectors, x & y, with the X and Y coordinates.
Optionaly, the HDR arg may be ommited and it will computed from `mat` alone, but then x=1:ncol, y=1:nrow
When HDR is not used, REG == nothing [default] means create a gridline registration grid and REG == 1,
or REG="pixel" a pixel registered grid.

Other methods of this function do:

    G = mat2grid([val]; hdr=hdr_vec, reg=nothing, proj4::String="", wkt::String="", tit::String="", rem::String="")

Create Float GMTgrid with size, coordinates and increment determined by the contents of the HDR var. This
array, which is now MANDATORY, has either the same meaning as above OR, alternatively, containng only
[xmin xmax ymin ymax xinc yinc]
VAL is the value that will be fill the matrix (default VAL = Float32(0)). To get a Float64 array use, for
example, VAL = 1.0 Ay other non Float64 will be converted to Float32

    Example: mat2grid(1, hdr=[0. 5 0 5 1 1])

    G = mat2grid(f::Function, x, y; reg=nothing, proj4::String="", wkt::String="", epsg::Int=0, tit::String="", rem::String="")

Where F is a function and X,Y the vectors coordinates defining it's domain. Creates a Float32 GMTgrid with
size determined by the sizes of the X & Y vectors.

    Example: f(x,y) = x^2 + y^2;  G = mat2grid(f, x = -2:0.05:2, y = -2:0.05:2)

    G = mat2grid(f::String, x=[], y=[])

Whre F is a pre-set function name. Currently available:
   - "ackley", "eggbox", "sombrero", "parabola" and "rosenbrock" 
X,Y are vectors coordinates defining the function's domain, but default values are provided for each function.
creates a Float32 GMTgrid.

    Example: G = mat2grid("sombrero")
"""
function mat2grid(val::Real=Float32(0); reg=nothing, hdr=nothing, proj4::String="", wkt::String="", epsg::Int=0, tit::String="", rem::String="")
	(hdr === nothing) && error("When creating grid type with no data the 'hdr' arg cannot be missing")
	(!isa(hdr, Array{Float64})) && (hdr = Float64.(hdr))
	(!isa(val, AbstractFloat)) && (val = Float32(val))		# We only want floats here
	if (length(hdr) == 6)
		hdr = [hdr[1], hdr[2], hdr[3], hdr[4], val, val, reg === nothing ? 0. : 1., hdr[5], hdr[6]]
	end
	mat2grid([nothing val]; reg=reg, hdr=hdr, proj4=proj4, wkt=wkt, epsg=epsg, tit=tit, rem=rem)
end

function mat2grid(mat::DenseMatrix, xx=Vector{Float64}(), yy=Vector{Float64}(); reg=nothing, x=Vector{Float64}(), y=Vector{Float64}(), hdr=nothing, proj4::String="", wkt::String="", epsg::Int=0, tit::String="", rem::String="", cmd::String="")
# Take a 2D array of floats and turn it into a GMTgrid

	!isa(mat[2], Real) && error("input matrix must be of Real numbers")
	reg_ = 0
	if (isa(reg, String) || isa(reg, Symbol))
		t = lowercase(string(reg))
		reg_ = (t != "pixel") ? 0 : 1
	elseif (isa(reg, Number))
		reg_ = (reg == 0) ? 0 : 1
	end
	if (isempty(x) && !isempty(xx))  x = xx  end
	if (isempty(y) && !isempty(yy))  y = yy  end
	x, y, hdr, x_inc, y_inc = grdimg_hdr_xy(mat, reg_, hdr, x, y)

	# Now we still must check if the method with no input MAT was called. In that case mat = [nothing val]
	# and the MAT must be finally computed.
	nx = size(mat, 2);		ny = size(mat, 1);
	if (ny == 1 && nx == 2 && mat[1] === nothing)
		fill_val = mat[2]
		mat = zeros(eltype(fill_val), length(y), length(x))
		(fill_val != 0) && fill!(mat, fill_val)
	end

	G = GMTgrid(proj4, wkt, epsg, hdr[1:6], [x_inc, y_inc], reg_, NaN, tit, rem, cmd, x, y, mat, "x", "y", "z", "", 0)
end

function mat2grid(f::Function, x, y; reg=nothing, proj4::String="", wkt::String="", epsg::Int=0, tit::String="", rem::String="")
	z = Array{Float32,2}(undef,length(y),length(x))
	for i = 1:length(x)
		for j = 1:length(y)
			z[j,i] = f(x[i],y[j])
		end
	end
	mat2grid(z; reg=reg, x=x, y=y, proj4=proj4, wkt=wkt, epsg=epsg, tit=tit, rem=rem)
end

function mat2grid(f::String, x=Vector{Float64}(), y=Vector{Float64}())
	# Something is very wrong here. If I add named vars it annoyingly warns
	#	WARNING: Method definition f2(Any, Any) in module GMT at C:\Users\joaqu\.julia\dev\GMT\src\gmt_main.jl:1556 overwritten on the same line.
	if (startswith(f, "ack"))				# Ackley (inverted) https://en.wikipedia.org/wiki/Ackley_function
		f_ack(x,y) = 20 * exp(-0.2 * sqrt(0.5 * (x^2 + y^2))) + exp(0.5*(cos(2pi*x) + cos(2pi*y))) - 22.718281828459045
		if (isempty(x))  x = -5:0.05:5;	y = -5:0.05:5;  end
		mat2grid(f_ack, x, y)
	elseif (startswith(f, "egg"))
		f_egg(x, y) = (sin(x*10) + cos(y*10)) / 4
		if (isempty(x))  x = -1:0.01:1;	y = -1:0.01:1;  end
		mat2grid(f_egg, x, y)
	elseif (startswith(f, "para"))
		f_parab(x,y) = x^2 + y^2
		if (isempty(x))  x = -2:0.05:2;	y = -2:0.05:2;  end
		mat2grid(f_parab, x, y)
	elseif (startswith(f, "rosen"))			# rosenbrock
		f_rosen(x,y) = (1 - x)^2 + 100 * (y - x^2)^2
		if (isempty(x))  x = -2:0.05:2;	y = -1:0.05:3;  end
		mat2grid(f_rosen, x, y)
	elseif (startswith(f, "somb"))			# sombrero
		f_somb(x,y) = cos(sqrt(x^2 + y^2) * 2pi / 8) * exp(-sqrt(x^2 + y^2) / 10)
		if (isempty(x))  x = -15:0.2:15;	y = -15:0.2:15;  end
		mat2grid(f_somb, x, y)
	else
		@warn("Unknown surface '$f'. Just giving you a parabola.")
		mat2grid("para")
	end
end

# ---------------------------------------------------------------------------------------------------
function grdimg_hdr_xy(mat, reg, hdr, x=Vector{Float64}(), y=Vector{Float64}())
# Generate x,y coords array and compute/update header plus increments for grids/images
	nx = size(mat, 2);		ny = size(mat, 1);

	if (!isempty(x) && !isempty(y))		# But not tested if they are equi-spaced as they MUST be
		if ((length(x) != (nx+reg) || length(y) != (ny+reg)) && (length(x) != 2 || length(y) != 2))
			error("size of x,y vectors incompatible with 2D array size")
		end
		one_or_zero = reg == 0 ? 1 : 0
		if (length(x) != 2)				# Check that REGistration and coords are compatible
			(reg == 1 && round((x[end] - x[1]) / (x[2] - x[1])) != nx) &&		# Gave REG = pix but xx say grid
				(@warn("Gave REGistration = 'pixel' but X coordinates say it's gridline. Keeping later reg."); one_or_zero = 1)
		else
			x = collect(range(x[1], stop=x[2], length=nx+reg))
			y = collect(range(y[1], stop=y[2], length=ny+reg))
		end
		x_inc = (x[end] - x[1]) / (nx - one_or_zero)
		y_inc = (y[end] - y[1]) / (ny - one_or_zero)
		zmin, zmax = extrema_nan(mat)
		hdr = [x[1], x[end], y[1], y[end], zmin, zmax]
	elseif (hdr === nothing)
		zmin, zmax = extrema_nan(mat)
		if (reg == 0)  x = collect(1.0:nx);		y = collect(1.0:ny)
		else           x = collect(0.5:nx+0.5);	y = collect(0.5:ny+0.5)
		end
		hdr = [x[1], x[end], y[1], y[end], zmin, zmax]
		x_inc = 1.0;	y_inc = 1.0
	else
		(length(hdr) != 9) && error("The HDR array must have 9 elements")
		(!isa(hdr, Array{Float64})) && (hdr = Float64.(hdr))
		one_or_zero = (hdr[7] == 0) ? 1 : 0
		if (ny == 1 && nx == 2 && mat[1] === nothing)
			# In this case the 'mat' is a tricked matrix with [nothing val]. Compute nx,ny from header
			# The final matrix will be computed in the main mat2grid method
			nx = Int(round((hdr[2] - hdr[1]) / hdr[8] + one_or_zero))
			ny = Int(round((hdr[4] - hdr[3]) / hdr[9] + one_or_zero))
		end
		x = collect(range(hdr[1], stop=hdr[2], length=nx))
		y = collect(range(hdr[3], stop=hdr[4], length=ny))
		# Recompute the x|y_inc to make sure they are right.
		x_inc = (hdr[2] - hdr[1]) / (nx - one_or_zero)
		y_inc = (hdr[4] - hdr[3]) / (ny - one_or_zero)
	end
	if (isa(x, UnitRange))  x = collect(x)  end			# The AbstractArrays are much less forgivable
	if (isa(y, UnitRange))  y = collect(y)  end
	if (!isa(x, Vector{Float64}))  x = Float64.(x)  end
	if (!isa(y, Vector{Float64}))  y = Float64.(y)  end
	return x, y, hdr, x_inc, y_inc
end

#= ---------------------------------------------------------------------------------------------------
function mksymbol(f::Function, cmd0::String="", arg1=nothing; kwargs...)
	# Make a fig and convert it to EPS so it can be used as a custom symbol is plot(3)
	d = KW(kwargs)
	t = ((val = find_in_dict(d, [:symbname :symb_name :symbol])[1]) !== nothing) ? string(val) : "GMTsymbol"
	d[:savefig] = t * ".eps"
	f(cmd0, arg1; d...)
end
mksymbol(f::Function, arg1; kw...) = mksymbol(f, "", arg1; kw...)
=#

# ---------------------------------------------------------------------------------------------------
"""
    make_zvals_vec(D, user_ids::Vector{String}, vals::Array{<:Real}, sub_head=0, upper=false, lower=false)

  - USER_IDS -> is a string vector with the ids (names in header) of the GMTdataset D 
  - VALS     -> is a vector with the the numbers to be used in plot -Z to color the polygons.
  - SUB_HEAD -> Position in header where field is to be found in the comma separated string.
Create a vector with ZVALS to use in plot where length(ZVALS) == length(D)
The elements of ZVALS are made up from the VALS but it can be larger if there are segments with
no headers. In that case it replicates the previously known value until it finds a new segment ID.

Returns a Vector{Float64} with the same length as the number of segments in D. The content is
made up after the contents of VALS but repeated such that each polygon of the same family, i.e.
with the same USER_ID, has the same value.
"""
function make_zvals_vec(D, user_ids::Vector{String}, vals::Array{<:Real}, sub_head::Int=0, case::Int=0)::Vector{Float64}

	n_user_ids = length(user_ids)
	@assert(n_user_ids == length(vals))
	data_ids, ind = get_segment_ids(D, case)
	(ind[1] != 1) && error("This function requires that first segment has a a header with an id")
	n_data_ids = length(data_ids)
	(n_user_ids > n_data_ids) &&
		@warn("Number of segment IDs requested is larger than segments with headers in data")

	if (sub_head != 0)
		[data_ids[k] = split(data_ids[k],',')[sub_head]  for k = 1:length(ind)]
	end
 
	n_seg = (isa(D, Array)) ? length(D) : 1
	zvals = fill(NaN, n_seg)
	n = 1
	for k = 1:n_data_ids
		for m = 1:n_user_ids
			if startswith(data_ids[k], user_ids[m])			# Find first occurence of user_ids[k] in a segment header
				last = (k < n_data_ids) ? ind[k+1]-1 : n_seg
				[zvals[j] = vals[m] for j = ind[k]:last]		# Repeat the last VAL for segments with no headers
				#println("k = ", k, " m = ",m, " pol_id = ", data_ids[k], ";  usr id = ", user_ids[m], " Racio = ", vals[m], " i1 = ", ind[k], " i2 = ",last)
				n = last + 1					# Prepare for next new VAL
				break
			end
		end
	end
	return zvals
end

# ---------------------------------------------------------------------------------------------------
function edit_segment_headers!(D, vals::Array, opt::String)
	# Add an option OPT to segment headers with a val from VALS. Number of elements of VALS must be
	# equal to the number of segments in D that have a header. If numel(val) == 1 must encapsulate it in []

	ids, ind = get_segment_ids(D)
	if (isa(D, Array))
		[D[ind[k]].header *= string(opt, vals[k])  for k = 1:length(ind)]
	else
		D.header *= string(opt, vals[1])
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    ids, ind = get_segment_ids(D, case=0)::Tuple{Vector{String}, Vector{Int}}

Where D is a GMTdataset of a vector of them, returns the segment ids (first text after the '>') and
the idices of those segments.
"""
function get_segment_ids(D, case::Int=0)::Tuple{Vector{String}, Vector{Int}}
	# Get segment ids (first text after the '>') and the idices of those segments
	# CASE -> If == 1 force return in LOWER case. If == 2 force upper case. Default (case = 0) dosen't touch
	if (isa(D, Array))  n = length(D);	d = Dict(k => D[k].header for k = 1:n)
	else                n = 1;			d = Dict(1 => D.header)
	end
	tf = Vector{Bool}(undef,n)					# pre-allocate
	[tf[k] = (d[k] !== "" && d[k][1] != ' ') ? true : false for k = 1:n];	# Mask of non-empty headers
	ind = 1:n
	ind = ind[tf]			# OK, now we have the indices of the segments with headers != ""
	ids = Vector{String}(undef,length(ind))		# pre-allocate
	if (case == 1)
		[ids[k] = lowercase(d[ind[k]]) for k = 1:length(ind)]	# indices of non-empty segments
	elseif (case == 2)
		[ids[k] = uppercase(d[ind[k]]) for k = 1:length(ind)]
	else
		[ids[k] = d[ind[k]] for k = 1:length(ind)]
	end
	return ids, ind
end

# ---------------------------------------------------------------------------------------------------
function resetGMT()
	# Reset everything to a fresh GMT session. That is reset all global variables to their initial state
	IamModern[1] = false;	FirstModern[1] = false;		IamSubplot[1] = false;	usedConfPar[1] = false;
	multi_col[1] = false;	convert_syntax[1] = false;	current_view[1] = "";	show_kwargs[1] = false;
	img_mem_layout[1] = "";	grd_mem_layout[1] = "";		CTRL.limits[1:6] = zeros(6);	CTRL.proj_linear[1] = true;
	CTRLshapes.fname[1] = "";CTRLshapes.first[1] = true; CTRLshapes.points[1] = false;
	global current_cpt  = nothing;	global legend_type  = nothing
	gmt("destroy")
	clear_sessions()
end

# ---------------------------------------------------------------------------------------------------
function clear_sessions(age::Int=0)
	# Delete stray sessions left behind by old failed process. Thanks to @htyeim
	# AGE is in seconds
	# Windows version of ``gmt clear sessions`` fails in 6.0 and it errors if no sessions dir
	try		# Becuse the sessions dir may not exist 
		if (GMTver >= v"6.1")
			sp = readlines(`gmt --show-userdir`)[1] * "/sessions"
			dirs = readdir(sp)
			session_dirs = filter(x->startswith(x, "gmt_session."), dirs)
			n = datetime2unix(now(UTC))
			for sd in session_dirs
				fp = joinpath(sp, sd)
				if (n - mtime(fp) > age) 		# created age seconds before
					rm(fp, recursive = true)
				end
			end
		else
			run(`gmt clear sessions`)
		end
	catch
	end
end

# ---------------------------------------------------------------------------------------------------
function Base.:show(io::IO, G::GMTgrid)
	(G.title   != "" && G.title[1]   != '\0') && println("title: ", rstrip(G.title, '\0'))
	(G.remark  != "" && G.remark[1]  != '\0') && println("remark: ", rstrip(G.remark, '\0'))
	(G.command != "" && G.command[1] != '\0') && println("command: ", rstrip(G.command, '\0'))
	println((G.registration == 0) ? "Gridline " : "Pixel ", "node registration used")
	println("x_min: ", G.range[1], "\tx_max :", G.range[2], "\tx_inc :", G.inc[1], "\tn_columns :", size(G.z,2))
	println("y_min: ", G.range[3], "\ty_max :", G.range[4], "\ty_inc :", G.inc[2], "\tn_rows :", size(G.z,1))
	println("z_min: ", G.range[5], "\tz_max :", G.range[6])
	(G.proj4 != "") && println("PROJ: ", G.proj4)
	(G.wkt   != "") && println("WKT: ", G.wkt)
	(G.epsg  != 0)  && println("EPSG: ", G.epsg)
end

# ---------------------------------------------------------------------------------------------------
function Base.:show(io::IO, G::GMTimage)
	println((G.registration == 0) ? "Gridline " : "Pixel ", "node registration used")
	println("x_min: ", G.range[1], "\tx_max :", G.range[2], "\tx_inc :", G.inc[1], "\tn_columns :", size(G.image,2))
	println("y_min: ", G.range[3], "\ty_max :", G.range[4], "\ty_inc :", G.inc[2], "\tn_rows :", size(G.image,1))
	println("z_min: ", G.range[5], "\tz_max :", G.range[6])
	(G.proj4 != "") && println("PROJ: ", G.proj4)
	(G.wkt   != "") && println("WKT: ", G.wkt)
	(G.epsg  != 0)  && println("EPSG: ", G.epsg)
end

# ---------------------------------------------------------------------------------------------------
function Base.:show(io::IO, ::MIME"text/plain", D::Array{<:GMTdataset})
	println(typeof(D), " with ", length(D), " segments")
	(length(D) == 0) && return
	(~isempty(D[1].comment)) && println("Comment:\t", D[1].comment)
	(D[1].proj4 != "") && println("PROJ: ", D[1].proj4)
	(D[1].wkt   != "") && println("WKT: ", D[1].wkt)
	#for k = 1:length(D)
		#(D[k].header != "") && println("Header",k, ":\t", D[k].header)
	#end

	# Do not print all headers as they may be many. But because there can be empty headers the mat complexify
	n_from_top = k = 1
	while (n_from_top < min(length(D), 11) && k <= length(D))		# Print the at most first 10 non empty
		(D[k].header != "") ? (println("Header",k, ":\t", D[k].header); k += 1; n_from_top += 1) : k += 1
	end
	if (n_from_top < length(D))		# If we have more segments print the at most last 10
		n_from_bot = 1
		for k = length(D):-1:1		# Find the (max) last 10 non empty
			(D[k].header != "") && (n_from_bot += 1)
			n_from_bot > 10 && break
		end
		println("...")
		n = max(n_from_top + 1, length(D) - n_from_bot + 1) + 1		# Make sure to print only non yet printed
		for k = n:length(D)
			(D[k].header != "") && println("Header",k, ":\t", D[k].header)
		end
	end

	println("First segment DATA")
	display(D[1].data)
	if (~isempty(D[1].text))
		println("First segment TEXT")
		display(D[1].text)
	end
end

# ---------------------------------------------------------------------------------------------------
function Base.:show(io::IO, D::GMTdataset)
	(~isempty(D.comment)) && println("Comment:\t", D.comment)
	(D.proj4  != "") && println("PROJ: ", D.proj4)
	(D.wkt    != "") && println("WKT: ", D.wkt)
	(D.header != "") && println("Header:\t", D.header)
	display(D.data)
	(~isempty(D.text)) && display(D.text)
end

# ---------- For Pluto ------------------------------------------------------------------------------
Base.:show(io::IO, mime::MIME"image/png", wp::WrapperPluto) = write(io, read(wp.fname))

# ---------------------------------------------------------------------------------------------------
function fakedata(sz...)
	# 'Stolen' from Plots.fakedata()
	y = zeros(sz...)
	for r in 2:size(y,1)
		y[r,:] = 0.95 * vec(y[r-1,:]) + randn(size(y,2))
	end
	y
end

# EDIPO SECTION
# ---------------------------------------------------------------------------------------------------
linspace(start, stop, length=100) = range(start, stop=stop, length=length)
logspace(start, stop, length=100) = exp10.(range(start, stop=stop, length=length))
fields(arg) = fieldnames(typeof(arg))
fields(arg::Array) = fieldnames(typeof(arg[1]))
#feval(fn_str, args...) = eval(Symbol(fn_str))(args...)