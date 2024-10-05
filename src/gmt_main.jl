"""
Call a GMT module. This function is not called directly by the users,
except when using the ``monolithic`` mode. Usage:

    gmt("module_name `options`", args...)
"""
function gmt(cmd::String, args...)

	(cmd == "") && return nothing		# Building docs with Quarto leads here when examples use ModernMode
	(cmd == "destroy") && return gmt_restart()
	ressurectGDAL()			# Some GMT modules may have called GDALDestroyDriverManager() 

	# ----------- Minimal error checking ------------------------
	n_argin::Int = length(args)
	if (n_argin > 0)
		if (isa(args[1], String))
			tok::String, r::String = strtok(cmd)
			if (r == "")				# User gave 'module' separately from 'options'
				cmd::String *= " " * args[1]::String	# Cat with the progname and so pretend input followed the classic construct
				args = args[2:end]
				n_argin -= 1
			end
		end
		# We may have trailing [] args in modules
		while (n_argin > 0 && (args[n_argin] === nothing))  n_argin -= 1  end
	end
	# -----------------------------------------------------------

	# 1. Get arguments, if any, and extract the GMT module name
	# First argument is the command string, e.g., "blockmean -R0/5/0/5 -I1" or just "help"
	g_module::String, r = strtok(cmd)

	isPSclosed[1] = false				# Only a gmtend() call sets this to true
	if (g_module == "begin")			# Use this default fig name instead of "gmtsession"
		fig_ext::String = (isFranklin[1]) ? " png" : (isJupyter[1]) ? " " * FMT[1] : FMT[1]
		(r == "") && (r = (isFranklin[1] || isJupyter[1]) ? (TMPDIR_USR[1] * "/" * "GMTjl_" * TMPDIR_USR[2] * TMPDIR_USR[3] * fig_ext) : "GMTplot " * fig_ext)
		# Here we must account for the fact that we may have started from a CLASSIC session. Then, the session dir does
		# not exist yet and in consequence when GMT_begin calls gmt_manage_workflow it will wrongly assume we are in CLASSIC
		# mode and write a gmt.conf in the session dir with classic instead of modern defaults. Solution is to create it now.
		API = unsafe_load(convert(Ptr{GMTAPI_CTRL}, G_API[1]))
		sess = joinpath(unsafe_string(API.session_dir), "gmt_session." * unsafe_string(API.session_name))
		!isdir(sess) && mkdir(sess)
		gmtlib_setparameter(G_API[1], "MAP_ORIGIN_X", "0")	# Workarround GMT bug.
		gmtlib_setparameter(G_API[1], "MAP_ORIGIN_Y", "0")
		IamModern[1] = true
	elseif (g_module == "end")			# Last command of a MODERN session
		(r == "") && (r = "-Vq")		# Cannot have a no-args for this case otherwise it prints help
		gmtlib_setparameter(G_API[1], "MAP_ORIGIN_X", "20c")
		gmtlib_setparameter(G_API[1], "MAP_ORIGIN_Y", "20c")
	elseif (r == "" && n_argin == 0)	# Just requesting usage message, add -? to options
		r = "-?"
	elseif (n_argin > 1 && (g_module == "psscale" || g_module == "colorbar"))	# Happens with nested calls like in grdimage
		if (!isa(args[1], GMTcpt) && isa(args[2], GMTcpt))
			args = [args[2]];		n_argin = 1
		end
	end

	pad = 2
	if (!isa(G_API[1], Ptr{Nothing}) || G_API[1] == C_NULL)
		G_API[1] = GMT_Create_Session("GMT", pad, GMT_SESSION_BITFLAGS)
		theme_modern()					# Set the MODERN theme
	end

	# 2. In case this was a clean up call or a begin/end from the modern mode
	gmt_manage_workflow(G_API[1], 0, NULL)		# Force going here to see if we are in middle of a MODERN session

	# Make sure this is a valid module
	if ((status = GMT_Call_Module(G_API[1], g_module, GMT_MODULE_EXIST, C_NULL)) != 0)
		error("GMT: No module by that name -- " * g_module * " -- was found.")
	end

	# 2+ Add -F to psconvert if user requested a return image but did not give -F.
	# The problem is that we can't use nargout to decide what to do, so we use -T to resolve the ambiguity.
	need2destroy = false
	if (g_module == "psconvert")
		if (!occursin("-F", r))
			if (!occursin("-T", r))
				r *= " -F";			need2destroy = true
			else				# Hmm, have to find if any of 'e' or 'f' are used as -T flags
				return_img = true
				if (endswith(r, " *"))  r = r[1:end-2];	return_img = false;  end	# Trick to avoid reading back img
				ind = findfirst("-T", r)
				tok = (ind !== nothing) ? lowercase(strtok(r[ind[2]:end])[1]) : ""
				if (return_img && !occursin("e", tok) && !occursin("f", tok))		# No any -Tef combo so add -F
					r *= " -F";		need2destroy = true
				end
			end
		end
		isJLL && (r *= " -G" * GSbin)
	end
	if (occursin("-%", r) || occursin("-&", r))			# It has also a mem layout request
		r, IMG_MEM_LAYOUT[1], GRD_MEM_LAYOUT[1] = parse_mem_layouts(r)
		(IMG_MEM_LAYOUT[1] != "") && (mem_layout::String = IMG_MEM_LAYOUT[1];	mem_kw = "API_IMAGE_LAYOUT")
		(GRD_MEM_LAYOUT[1] != "") && (mem_layout = GRD_MEM_LAYOUT[1];	mem_kw = "API_GRID_LAYOUT")
		(IMG_MEM_LAYOUT[1] != "" && mem_layout[end] != 'a')  && (mem_layout *= "a")
		GMT_Set_Default(G_API[1], mem_kw, mem_layout);	# Tell module to give us the image/grid with this mem layout
	end

	# 2++ Add -T to gmtwrite if user did not explicitly give -T. Seek also for MEM layout requests
	if (occursin("write", g_module))
		if (!occursin("-T", r) && n_argin == 1)
			if (isa(args[1], GMTgrid))
				r *= " -Tg"
			elseif (isa(args[1], GMTimage))
				r *= " -Ti"
			elseif (isa(args[1], GDtype))
				r *= " -Td"
			elseif (isa(args[1], GMTps))
				r *= " -Tp"
			elseif (isa(args[1], GMTcpt))
				r *= " -Tc"
			end
		end
		r, IMG_MEM_LAYOUT[1], GRD_MEM_LAYOUT[1] = parse_mem_layouts(r)
	elseif (occursin("read", g_module) && (occursin("-Ti", r) || occursin("-Tg", r)))
		need2destroy = true
	end

	# 2+++ If gmtread -Ti than temporarily set pad to 0 since we don't want padding in image arrays
	if (occursin("read", g_module) && occursin("-T", r))
		(occursin("-Ti", r) || occursin("-Tg", r)) && GMT_Set_Default(G_API[1], "API_PAD", "0")
	end

	# 3. Convert command line arguments to a linked GMT option list
	#LL = NULL
	LL = GMT_Create_Options(G_API[1], 0, r)		# It uses also the fact that GMT parses and check options

	# 4. Preprocess to update GMT option lists and return info array X

	# Here I have an issue that I can't resolve any better. For modules that can have no options (e.g. gmtinfo)
	# the LinkedList (LL) is actually created in GMT_Encode_Options but I can't get it's contents back when pLL
	# is a Ref, so I'm forced to use 'pointer', which goes against the documents recommendation.
	pLL = (LL != NULL) ? Ref([LL], 1) : pointer([NULL])

	n_itemsP = Ref{UInt32}(0)
	XX = GMT_Encode_Options(G_API[1], g_module, n_argin, pLL, n_itemsP)	# This call also changes LL
	n_items = n_itemsP[]
	if (XX == NULL && n_items > 65000)		# Just got usage/synopsis option (if (n_items == UINT_MAX)) in C
		(n_items > 65000) ? n_items = 0 : error("Failure to encode Julia command options") 
	end

	if (LL == NULL)		# The no-options case. Must get the LL that was created in GMT_Encode_Options
		LL = convert(Ptr{GMT_OPTION}, unsafe_load(pLL))
		pLL = Ref([LL], 1)		# Need this because GMT_Destroy_Options() wants a Ref
	end

	X = Vector{GMT_RESOURCE}(undef, n_items)
	for k = 1:n_items
		X[k] = unsafe_load(XX, k)        # Cannot use pointer_to_array() because GMT_RESOURCE is not immutable and would BOOM!
	end
	gmt_free_mem(G_API[1], XX)

	#println(g_module * " " * unsafe_string(GMT_Create_Cmd(G_API[1], LL)))	# Uncomment when need to confirm argins

	# 5. Assign input sources (from Julia to GMT) and output destinations (from GMT to Julia)
	(g_module == "grdpaste") && (noGrdCopy[1] = true)	# Signal grid_init() that it should not make a grid copy
	for k = 1:n_items									# Number of GMT containers involved in this module call */
		if (X[k].direction == GMT_IN && n_argin == 0) error("GMT: Expects a Matrix for input") end
		ptr = (X[k].direction == GMT_IN) ? args[X[k].pos+1] : nothing
		GMTJL_Set_Object(G_API[1], X[k], ptr, pad)		# Set object pointer
	end
	(g_module == "grdpaste") && (noGrdCopy[1] = false)

	# 6. Run GMT module; give usage message if errors arise during parsing
	status = GMT_Call_Module(G_API[1], g_module, GMT_MODULE_OPT, LL)
	if (status != 0)
		((status < 0) || status == GMT_SYNOPSIS || status == Int('?')) && return
		resetGMT()		# If it screwed, reset it to not let this error afect posterious calls.
		error("Something went wrong when calling the module. GMT error number = $status")
	end

	# 7. Hook up module GMT outputs to Julia array
	# But first count the number of outputs
	n_out = 0
	for k = 1:n_items					# Number of GMT containers involved in this module call
		(X[k].direction == GMT_IN) && continue
		n_out += 1
	end

	#out = Vector{Any}(undef, n_out)
	out = Vector{Union{GItype, GDtype, GMTcpt, GMTps}}(undef, n_out)

	for k = 1:n_items					# Get results from GMT into Julia arrays
		if (X[k].direction == GMT_IN) continue 	end      # Only looking for stuff coming OUT of GMT here
		out[X[k].pos+1] = GMTJL_Get_Object(G_API[1], X[k])    # Hook object onto rhs list
	end

	# 2++- If gmtread -Ti than reset the session's pad value that was temporarily changed above (2+++)
	if (occursin("read", g_module) && (occursin("-Ti", r) || occursin("-Tg", r)) )
		GMT_Set_Default(G_API[1], "API_PAD", string(pad))
	end

	# Due to the damn GMT pad I'm forced to a lot of trickery. One involves cheating on memory ownership
	if (CTRL.gmt_mem_bag[1] != C_NULL)
		gmt_free_mem(G_API[1], CTRL.gmt_mem_bag[1])		# Free a GMT owned memory that we pretended was ours
		CTRL.gmt_mem_bag[1] = C_NULL
	end

	# 8. Free all GMT containers involved in this module call
	for k = 1:n_items
		ppp = X[k].object
		name = String([X[k].name...])					# Because X.name is a NTuple
		(GMT_Close_VirtualFile(G_API[1], name) != 0) && error("GMT: Failed to close virtual file")
		(GMT_Destroy_Data(G_API[1], Ref([X[k].object], 1)) != 0) && error("Failed to destroy GMT<->Julia interface object")
		# Success, now make sure we dont destroy the same pointer more than once
		for kk = k+1:n_items
			if (X[kk].object == ppp) 	X[kk].object = NULL;	end
		end
	end

	# 9. Destroy linked option list
	GMT_Destroy_Options(G_API[1], pLL)

	#if (IamModern[1])  gmt_put_history(G_API[1]);	end	# Needed, otherwise history is not updated
	(IamModern[1] && g_module != "begin") && gmt_restart()		# Needed, otherwise history is not updated

	IMG_MEM_LAYOUT[1] = "";		GRD_MEM_LAYOUT[1] = ""		# Reset to not afect next readings

	# GMT6.1.0 f up and now we must be very careful to not let the GMT breaking screw us
	(need2destroy && !IamModern[1]) && gmt_restart()

	ressurectGDAL()		# Some GMT modules may have called GDALDestroyDriverManager() and some GDAL module may come after us.
	(contains(cmd, " -Gp") || contains(cmd, " -GP")) && gmt_restart()	# Apparently patterns are screwing the session
	(CTRL.pocket_B[3] != "") && (CTRL.pocket_B[3] = ""; gmt_restart())	# Apparently bg colors screw the session

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

# -----------------------------------------------------------------------------------------------
function gmt_restart(restart::Bool=true)
	# Destroy the contents of the current API pointer and, by default, recreate a new one.
	GMT_Destroy_Session(G_API[1])
	if (restart)
		G_API[1] = GMT_Create_Session("GMT", 2, GMT_SESSION_BITFLAGS)
		theme_modern()				# Set the MODERN theme and calls extra_sets()
	else
		G_API[1] = C_NULL
	end
	return nothing
end

# -----------------------------------------------------------------------------------------------
function extra_sets()
	gmtlib_setparameter(G_API[1], "MAP_DEFAULT_PEN", "0.5p,black")	# Change the default 0.25 pen thickness in -W
	gmtlib_setparameter(G_API[1], "COLOR_NAN", "255")				# Stop those ugly grays
	gmtlib_setparameter(G_API[1], "MAP_ORIGIN_X", "20c")			# Change the origin offset
	gmtlib_setparameter(G_API[1], "MAP_ORIGIN_Y", "20c")
	gmtlib_setparameter(G_API[1], "MAP_EMBELLISHMENT_MODE", "auto")
end

# -----------------------------------------------------------------------------------------------
function ressurectGDAL()	# Because GMT may call GDALDestroyDriverManager()
	(Gdal.GDALGetDriverCount() == 0) && (Gdal.GDALDestroyDriverManager(); Gdal.resetdrivers())
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
		print(a, '-', Char(LL_up.option))
		print(a, unsafe_string(LL_up.arg))
		if (LL_up.next != C_NULL)
			print(a, " ")
			LL_up = unsafe_load(LL_up.next);
		else
			done = true
		end
	end
	return String(take!(a))
end
=#

# ---------------------------------------------------------------------------------------------------
function parse_mem_layouts(cmd::AbstractString)
# See if a specific grid or image mem layout is requested. If found return its value and also
# strip the corresponding option from the CMD string (otherwise GMT would scream)
# The specific codes "-%" and "-&" are set in gmtreadwrite
	GRD_MEM_LAYOUT[1] = "";	IMG_MEM_LAYOUT[1] = ""

	if ((ind = findfirst( "-%", cmd)) !== nothing)
		IMG_MEM_LAYOUT[1], resto = strtok(cmd[ind[1]+2:end])
		if (length(IMG_MEM_LAYOUT[1]) < 3 || length(IMG_MEM_LAYOUT[1]) > 4)
			error("Memory layout option must have 3 characters and not $(IMG_MEM_LAYOUT[1])")
		end
		cmd = cmd[1:ind[1]-1] * " " * resto 	# Remove the -L pseudo-option because GMT would bail out
	end
	if (isempty(IMG_MEM_LAYOUT[1]))				# Only if because we can't have a double request
		if ((ind = findfirst( "-&", cmd)) !== nothing)
			GRD_MEM_LAYOUT[1], resto = strtok(cmd[ind[1]+2:end])
			if (length(GRD_MEM_LAYOUT[1]) < 2)
				error("Memory layout option must have at least 2 chars and not $(GRD_MEM_LAYOUT[1])")
			end
			cmd = cmd[1:ind[1]-1] * " " * resto 	# Remove the -L pseudo-option because GMT would bail out
		end
	end
	IMG_MEM_LAYOUT[1] = string(IMG_MEM_LAYOUT[1]);	GRD_MEM_LAYOUT[1] = string(GRD_MEM_LAYOUT[1]);	# We don't want substrings
	return cmd, IMG_MEM_LAYOUT[1], GRD_MEM_LAYOUT[1]
end

# ---------------------------------------------------------------------------------------------------
function strtok(str)
	# A Matlab like strtok function
	(str == "") && return str
	o = split(str, limit=2, keepempty=false)
	return (length(o) == 2) ? (string(o[1]), string(o[2])) : (string(o[1]), "")
end
function strtok(str, delim)
	o = split(str, delim, limit=2, keepempty=false)
	return (length(o) == 2) ? (string(o[1]), string(o[2])) : (string(o[1]), "")
end

#= ---------------------------------------------------------------------------------------------------
function GMT_IJP(hdr::GMT_GRID_HEADER, row, col)
# Function for indecing into a GMT grid [with pad]
# padTop (hdr.pad[GMT_YHI]) and padLeft (hdr.pad[GMT_XLO]) are normally equal
	#ij = (row + hdr.pad[4]) * hdr.mx + col + hdr.pad[1]		# in C
	ij = ((row-1) + hdr.pad[4]) * hdr.mx + col + hdr.pad[1]
end
=#

#= ---------------------------------------------------------------------------------------------------
function GMT_IJP(row::Integer, col::Integer, mx, padTop, padLeft)
# Function for indecing into a GMT grid [with pad]
# padTop (hdr.pad[GMT_YHI]) and padLeft (hdr.pad[GMT_XLO]) are normally equal
	#ij = (row + padTop) * mx + col + padLeft		# in C
	ij = ((row-1) + padTop) * mx + col + padLeft
end
=#

#= ---------------------------------------------------------------------------------------------------
function MEXG_IJ(row::Integer, col::Integer, ny)
	# Get the ij that corresponds to (row,col) [no pad involved]
	#ij = col * ny + ny - row - 1		in C
	ij = col * ny - row + 1
end
=#

# ---------------------------------------------------------------------------------------------------
function get_grid(API::Ptr{Nothing}, object, cube::Bool)::GMTgrid
# Given an incoming GMT grid G, build a Julia type and assign the output components.
# Note: Incoming GMT grid has standard padding while Julia grid has none.

	if (!cube)  G = unsafe_load(convert(Ptr{GMT_GRID}, object))
	else        G = unsafe_load(convert(Ptr{GMT_CUBE}, object))
	end
	(G.data == C_NULL) && error("Programming error, output matrix is empty")

	gmt_hdr::GMT_GRID_HEADER = unsafe_load(G.header)
	ny = Int(gmt_hdr.n_rows);		nx = Int(gmt_hdr.n_columns);		nb = Int(gmt_hdr.n_bands)
	padTop = Int(gmt_hdr.pad[4]);	padLeft = Int(gmt_hdr.pad[1]);
	mx = Int(gmt_hdr.mx);			my = Int(gmt_hdr.my)

	X  = collect(range(gmt_hdr.wesn[1], stop=gmt_hdr.wesn[2], length=(nx + gmt_hdr.registration)))
	Y  = collect(range(gmt_hdr.wesn[3], stop=gmt_hdr.wesn[4], length=(ny + gmt_hdr.registration)))
	if (nb == 1)
		V = [0.]
	else
		V = zeros(nb);		t = unsafe_wrap(Array, G.z, nb)
		for n = 1:nb  V[n] = t[n]  end
	end

	t::Vector{Float32} = unsafe_wrap(Array, G.data, my * mx * nb)
	if !(nb > 1 && padLeft == 0)			# Otherwise we are in experimental ground (so far only CUBEs)
		z = (nb == 1) ? Array{Float32,2}(undef, ny, nx) : Array{Float32,3}(undef, ny, nx, nb)  
	end

	if (nb > 1)			# A CUBE
		if (padLeft == 0)
			z, layout = reshape(t, nx, ny, nb), "TRB"
		else
			for k = 1:nb
				offset = (k - 1) * gmt_hdr.size + padLeft
				#[z[row,col, k] = t[((ny-row) + padTop) * mx + col + offset] for row = 1:ny, col = 1:nx]
				for col = 1:nx
					for row = 1:ny
						z[row,col, k] = t[((ny-row) + padTop) * mx + col + offset]
					end
				end
			end
			layout = "BCB";
		end
	elseif (GRD_MEM_LAYOUT[1] == "" || startswith(GRD_MEM_LAYOUT[1], "BC"))
		for col = 1:nx
			for row = 1:ny
				ij = ((row-1) + padTop) * mx + col + padLeft		# Was GMT_IJP(row, col, mx, padTop, padLeft)
				z[col * ny - row + 1] = t[ij]						# Was z[MEXG_IJ(row, col, ny)]
			end
		end
		layout = "BCB";
	elseif (GRD_MEM_LAYOUT[1][2] == 'R')		# Store array in Row Major
		ind_y = 1:ny		# Start assuming "TR"
		if (startswith(GRD_MEM_LAYOUT[1], "BR"))  ind_y = ny:-1:1  end	# Bottom up
		k = 1
		for row = ind_y
			tt = ((row-1) + padTop) * mx + padLeft
			for col = 1:nx
				z[k] = t[col + tt]	# was t[GMT_IJP(row, col, mx, padTop, padLeft)]
				k = k + 1
			end
		end
		layout = GRD_MEM_LAYOUT[1][1:2]*'B';
	else
		# Was t[GMT_IJP(row, col, mx, padTop, padLeft)
		#[z[row,col] = t[((row-1) + padTop) * mx + col + padLeft] for row = 1:ny, col = 1:nx]
		for row = 1:ny
			for col = 1:nx
				z[row,col] = t[((row-1) + padTop) * mx + col + padLeft]
			end
		end
		layout = "TCB";
	end
	GRD_MEM_LAYOUT[1] = ""		# Reset because this variable is global

	# Return grids via a float matrix in a struct
	rng, inc = (gmt_hdr.n_bands > 1) ? (fill(NaN,8), fill(NaN,3)) : (fill(NaN,6), fill(NaN,2))
	hasnans = any(!isfinite, z) ? 2 : 1
	out = GMTgrid("", "", 0, -1, rng, inc, 0, NaN, "", "", "", "", String[], X, Y, V, z, "", "", "", "", layout, 1f0, 0f0, 0, hasnans)

	if (gmt_hdr.ProjRefPROJ4 != C_NULL)  out.proj4 = unsafe_string(gmt_hdr.ProjRefPROJ4)  end
	if (gmt_hdr.ProjRefWKT != C_NULL)    out.wkt = unsafe_string(gmt_hdr.ProjRefWKT)      end
	out.title   = String([gmt_hdr.title...])
	out.remark  = String([gmt_hdr.remark...])
	out.command = String([gmt_hdr.command...])

	# The following is uggly is a consequence of the clag.jl translation of fixed size arrays
	out.range[1:end] = (gmt_hdr.n_bands > 1) ? [gmt_hdr.wesn[1:4]..., gmt_hdr.z_min, gmt_hdr.z_max, G.z_range[:]...] :
	                                           [gmt_hdr.wesn[1:4]..., gmt_hdr.z_min, gmt_hdr.z_max]
	out.inc[1:end]   = (gmt_hdr.n_bands > 1) ? [gmt_hdr.inc[1], gmt_hdr.inc[2], G.z_inc] : [gmt_hdr.inc[1], gmt_hdr.inc[2]]
	out.nodata       = gmt_hdr.nan_value
	out.registration = gmt_hdr.registration
	out.x_unit       = String(UInt8[gmt_hdr.x_unit...])
	out.y_unit       = String(UInt8[gmt_hdr.y_unit...])
	out.z_unit       = String(UInt8[gmt_hdr.z_unit...])
	(out.proj4 == "" && out.wkt == "" && out.epsg == 0 && startswith(out.x_unit, "longitude [degrees_east]")) &&
		(out.proj4 = prj4WGS84)

	return out
end

# ---------------------------------------------------------------------------------------------------
function get_image(API::Ptr{Nothing}, object)::GMTimage
# Given an incoming GMT image, build a Julia type and assign the output components.
# Note: Incoming GMT image may have standard padding while Julia image has none.

	I::GMT_IMAGE = unsafe_load(convert(Ptr{GMT_IMAGE}, object))
	(I.data == C_NULL) && error("get_image: programming error, output matrix is empty")
	if     (I.type == 3)  data = convert(Ptr{Cushort}, I.data)
	elseif (I.type == 5)  data = convert(Ptr{Cuint}, I.data)
	elseif (I.type <= 1)  data = convert(Ptr{Cuchar}, I.data)
	else   error("Only unsigned types are acceped in images. Maybe you meant to read data as a grid?")
	end

	gmt_hdr::GMT_GRID_HEADER = unsafe_load(I.header)
	ny = Int(gmt_hdr.n_rows);		nx = Int(gmt_hdr.n_columns);		nz = Int(gmt_hdr.n_bands)

	wesn = [gmt_hdr.wesn[1], gmt_hdr.wesn[2], gmt_hdr.wesn[3], gmt_hdr.wesn[4]]
	if (gmt_hdr.registration == 0)		# For images we always want pixel registration, so fix this
		wesn[1] -= gmt_hdr.inc[1]/2;	wesn[2] += gmt_hdr.inc[1]/2
		wesn[3] -= gmt_hdr.inc[2]/2;	wesn[4] += gmt_hdr.inc[2]/2
		gmt_hdr.registration = 1
	end
	X  = collect(range(wesn[1], stop=wesn[2], length=(nx + gmt_hdr.registration)))
	Y  = collect(range(wesn[3], stop=wesn[4], length=(ny + gmt_hdr.registration)))

	layout = join([Char(gmt_hdr.mem_layout[k]) for k=1:4])		# This is damn diabolic (and GMT is lying for cubes)
	if (occursin("0", IMG_MEM_LAYOUT[1]) || occursin("1", IMG_MEM_LAYOUT[1]))	# WTF is 0 or 1?
		t = deepcopy(unsafe_wrap(Array, data, ny * nx * nz))
	else
		if (IMG_MEM_LAYOUT[1] != "")  layout = IMG_MEM_LAYOUT[1][1:3] * layout[4]  end	# 4rth is data determined
		if (layout != "" && layout[1] == 'I')		# The special layout for using this image in Images.jl
			o = (nz == 1) ? (ny, nx) : (nz, ny, nx)
		else
			o = (nz == 1) ? (ny, nx) : (ny, nx, nz)
			isBRP = startswith(layout, "BRP") || startswith(layout, "TRP")
			(nz == 1 && isBRP) && (layout = "BRPa")	# For 1 layer "BRBa" and "BRPa" is actualy the same.
			(!isBRP && nz > 1) && @warn("Only 'I' for Images.jl and 'BRP' MEM layouts are allowed.")
			
			# OK, the above is not always true. Image cubes are not pixel interleaved. But how to detect them?
			(I.type > 1 || (nz == 2 || nz > 4)) && (layout = layout[1:2] * "B" * layout[4])	# Stil leaves out cases of uint8 cubes.
		end
		t = reshape(unsafe_wrap(Array, data, ny * nx * nz), o)	# Apparently the reshape() creates a copy
	end

	if (I.colormap != C_NULL)       # Indexed image has a color map (Scanline)
		n_colors = Int64(I.n_indexed_colors)
		colormap::Vector{Int32} = deepcopy(unsafe_wrap(Array, I.colormap, n_colors * 4))
	else
		colormap, n_colors = vec(zeros(Int32,1,3)), 0	# Because we need an array
	end

	# Return image via a uint8 matrix in a struct
	cinterp = (I.color_interp != C_NULL) ? unsafe_string(I.color_interp) : ""
	out = GMTimage("", "", 0, -1, zeros(6)*NaN, [NaN, NaN], 0, gmt_hdr.nan_value, cinterp, String[], String[], X, Y,
	               zeros(nz), t, colormap, String[], n_colors, Array{UInt8,2}(undef,1,1), layout, 0)

	GMT_Set_AllocMode(API, GMT_IS_IMAGE, object)
	unsafe_store!(convert(Ptr{GMT_IMAGE}, object), I)

	if (gmt_hdr.ProjRefPROJ4 != C_NULL)  out.proj4 = unsafe_string(gmt_hdr.ProjRefPROJ4)  end
	if (gmt_hdr.ProjRefWKT   != C_NULL)  out.wkt   = unsafe_string(gmt_hdr.ProjRefWKT)    end
	if (gmt_hdr.ProjRefEPSG  != 0)       out.epsg  = Int(gmt_hdr.ProjRefEPSG)   end

	out.range = vec([wesn[1] wesn[2] wesn[3] wesn[4] gmt_hdr.z_min gmt_hdr.z_max])
	out.inc          = vec([gmt_hdr.inc[1] gmt_hdr.inc[2]])
	out.registration = gmt_hdr.registration
	reg = round(Int, (X[end] - X[1]) / gmt_hdr.inc[1]) == (nx - 1)		# Confirm registration
	(reg && gmt_hdr.registration == 1) && (out.registration = 0)

	return out
end

# ---------------------------------------------------------------------------------------------------
function get_palette(API::Ptr{Nothing}, object::Ptr{Nothing})::GMTcpt
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
# categorical: 0 = No, 1 = Yes, 2 = Yes and keys are strings.
# label		# Labels of a Categorical CPT. Vector of strings, one for each color
# key		# Keys of a Categorical CPT. Vector of strings, one for each color
# model:	String with color model rgb, hsv, or cmyk [rgb]
# comment:	Cell array with any comments

	C::GMT_PALETTE = unsafe_load(convert(Ptr{GMT_PALETTE}, object))

	(C.data == C_NULL) && error("get_palette: programming error, output CPT is empty")

	model::String = (C.model & GMT_HSV != 0) ? "hsv" : ((C.model & GMT_CMYK != 0) ? "cmyk" : "rgb")
	n_colors::UInt32 = (C.is_continuous != 0) ? C.n_colors + 1 : C.n_colors

	out = GMTcpt(zeros(n_colors, 3), zeros(n_colors), zeros(C.n_colors, 2), [NaN,NaN], zeros(3,3), 8, 0.0,
	             zeros(C.n_colors,6), C.categorical, Vector{String}(undef,C.n_colors), Vector{String}(undef,C.n_colors), model, String[])

	gmt_lut = unsafe_load(C.data, 1)
	is_gray = true				# Because of a GMT bug we must check it here
	for j = 1:C.n_colors		# Copy r/g/b from palette to Julia array
		gmt_lut = unsafe_load(C.data, j)
		for k = 1:3 	out.colormap[j, k] = gmt_lut.rgb_low[k]		end
		for k = 1:3
			out.cpt[j, k]   = gmt_lut.rgb_low[k]
			out.cpt[j, k+3] = gmt_lut.rgb_high[k]		# Not sure this is equal to the ML MEX case
		end
		is_gray && (is_gray = (out.cpt[j, 1] == out.cpt[j, 2] == out.cpt[j, 3]))
		is_gray && (is_gray = (out.cpt[j, 4] == out.cpt[j, 5] == out.cpt[j, 6]))
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
	for j = 1:3, k = 1:3
		out.bfn[j,k] = C.bfn[j].rgb[k]
	end

	out.depth = (C.is_bw != 0) ? 1 : ((C.is_gray != 0) ? 8 : 24)
	(out.depth == 1 && is_gray) && (out.depth = 8)		# To workaround a GMT bug
	out.hinge = (C.has_hinge != 0) ? C.hinge : NaN;
	gmt_lut = unsafe_load(C.data, 1)
	out.minmax[1] = gmt_lut.z_low
	gmt_lut = unsafe_load(C.data, C.n_colors)
	out.minmax[2] = gmt_lut.z_high

	return out
end

# ---------------------------------------------------------------------------------------------------
function get_PS(API::Ptr{Nothing}, object::Ptr{Nothing})::GMTps
# Given a GMT Postscript structure P, build a Julia PS type
# Each segment will have 4 items:
# postscript:	Text string with the entire PostScript plot
# length:	Byte length of postscript
# mode:	1 has header, 2 has trailer, 3 is complete
# comment:	Cell array with any comments
	(object == C_NULL) && error("get_PS: programming error, input object is NULL")

	P::GMT_POSTSCRIPT = unsafe_load(convert(Ptr{GMT_POSTSCRIPT}, object))
	out = GMTps(unsafe_string(P.data), Int(P.n_bytes), Int(P.mode), [])	# NEED TO FILL THE COMMENT
end

# ---------------------------------------------------------------------------------------------------
function get_dataset(API::Ptr{Nothing}, object::Ptr{Nothing})::GDtype
# Given a GMT DATASET D, build an array of segment structure and assign values.
# Each segment will have 6 items:
# header:	Text string with the segment header (could be empty)
# data:	Matrix with the data for this segment (n_rows by n_columns)
# text:	Empty cell array (since datasets have no text)
# comment:	Cell array with any comments
# proj4:	String with any proj4 information
# wkt:		String with any WKT information

	(object == C_NULL) && return GMTdataset()		# No output produced - return a null data set
	D::GMT_DATASET = unsafe_load(convert(Ptr{GMT_DATASET}, object))

	# This is for the particular case of the DCW countries that have a myriad of small segments and no Attributes
	min_pts = (get(POSTMAN[1], "minpts", "") != "") ? parse(Int, POSTMAN[1]["minpts"]) - 1 : 0
	(min_pts > 0) && delete!(POSTMAN[1], "minpts")
	DCWnames = (get(POSTMAN[1], "DCWnames", "") != "") ? true : false		# If DCW country names will turn into attribs
	(DCWnames) && delete!(POSTMAN[1], "DCWnames")

	seg_out = 0;
	T::Vector{Ptr{GMT_DATATABLE}} = unsafe_wrap(Array, D.table, D.n_tables)
	for tbl = 1:D.n_tables
		DT::GMT_DATATABLE = unsafe_load(T[tbl])
		for seg = 1:DT.n_segments
			S::Vector{Ptr{GMT_DATASEGMENT}} = unsafe_wrap(Array, DT.segment, seg)
			DS::GMT_DATASEGMENT = unsafe_load(S[seg])
			if (DS.n_rows > min_pts)
				seg_out += 1
			end
		end
	end

	Darr = [GMTdataset() for i = 1:seg_out]					# Create the array of DATASETS

	seg_out = 1
	T = unsafe_wrap(Array, D.table, D.n_tables)				# D.n_tables-element Array{Ptr{GMT_DATATABLE},1}
	for tbl = 1:D.n_tables
		DT = unsafe_load(T[tbl])							# GMT_DATATABLE
		S = unsafe_wrap(Array, DT.segment, DT.n_segments)	# n_segments-element Array{Ptr{GMT_DATASEGMENT},1}
		for seg = 1:DT.n_segments
			DS = unsafe_load(S[seg])						# GMT_DATASEGMENT
			(DS.n_rows <= min_pts) && continue 				# Skip empty/small segments

			C = unsafe_wrap(Array, DS.data, DS.n_columns)	# DS.data = Ptr{Ptr{Float64}}; C = Array{Ptr{Float64},1}
			dest::Matrix{Float64} = zeros(Float64, DS.n_rows, DS.n_columns)
			for col = 1:DS.n_columns						# Copy the data columns
				unsafe_copyto!(pointer(dest, DS.n_rows * (col - 1) + 1), unsafe_load(DS.data, col), DS.n_rows)
			end
			Darr[seg_out].data = dest
			if (!isvector(dest))							# One-rowers do not have BBs
				bb = extrema(dest, dims=1)					# A N Tuple.
				Darr[seg_out].bbox = collect(Float64, Iterators.flatten(bb))
			end

			if (DS.text != C_NULL)
				texts = unsafe_wrap(Array, DS.text, DS.n_rows)	# n_headers-element Array{Ptr{UInt8},1}
				if (texts != NULL)
					dest_s = Vector{String}(undef, DS.n_rows)
					n = 0
					for row = 1:DS.n_rows					# Copy the text rows, but check if they are not all NULL
						if (texts[row] != NULL)  dest_s[row] = unsafe_string(texts[row]);		n+=1
						else                     dest_s[row] = ""
						end
					end
					(n > 0) && (Darr[seg_out].text = dest_s)	# If they are all empty, no bother to save them.
				end
			end

			if (DS.header != C_NULL)
				hdrstr = unsafe_string(DS.header)
				if (!DCWnames)
					Darr[seg_out].header = hdrstr
				else
					(DCWnames && (ind = findfirst(" Segment", hdrstr)) !== nothing) &&
						(Darr[seg_out].attrib["NAME"] = hdrstr[2:ind[1]-1])
				end
			end
			if (seg == 1)
				#headers = pointer_to_array(DT.header, DT.n_headers)	# n_headers-element Array{Ptr{UInt8},1}
				headers = unsafe_wrap(Array, DT.header, DT.n_headers)	# n_headers-element Array{Ptr{UInt8},1}
				dest_s = Vector{String}(undef, length(headers))
				for k = 1:numel(headers)
					dest_s[k] = unsafe_string(headers[k])
				end
				Darr[seg_out].comment = dest_s
			end
			seg_out += 1
		end
	end
	if (!isempty(Darr))
		all_bbs = any(isnan.(Darr[1].bbox)) ? true : false		# See if set_dsBB! must compute NaN-resintant bboxes.
		set_dsBB!(Darr, all_bbs)				# Compute and set the global BoundingBox for this dataset
	else
		return GMTdataset()
	end

	return (length(Darr) == 1) ? Darr[1] : Darr
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_Set_Object(API::Ptr{Nothing}, X::GMT_RESOURCE, ptr, pad)::GMT_RESOURCE
	# Create the object container and hook as X->object

	if (X.family == GMT_IS_GRID)			# Get a grid from Julia or a dummy one to hold GMT output
		X.object =  grid_init(API, X, ptr, pad, false)
	elseif (X.family == GMT_IS_CUBE)		# Get a grid from Julia or a dummy one to hold GMT output
		X.object =  grid_init(API, X, ptr, pad, true)
	elseif (X.family == GMT_IS_IMAGE)		# Get an image from Julia or a dummy one to hold GMT output
		X.object = image_init(API, ptr)
	elseif (X.family == GMT_IS_DATASET)		# Get a dataset from Julia or a dummy one to hold GMT output
		actual_family = [GMT_IS_DATASET]	# Default but may change to matrix
		if (ptr !== nothing && isa(ptr, GMTdataset))
			if (isempty(ptr.text) && isempty(ptr.header))  X.object = dataset_init(API, ptr.data, actual_family)
			else                    X.object = dataset_init(API, [ptr], X.direction)	# When TEXT still need to go here
			end
		elseif (isa(ptr, Vector{<:GMTdataset}))
			X.object = dataset_init(API, ptr, X.direction)
		else
			if (X.direction == GMT_OUT)		# Here we accept ptr === nothing
				X.object = convert(Ptr{GMT_DATASET}, GMT_Create_Data(API, GMT_IS_DATASET, GMT_IS_PLP, GMT_IS_OUTPUT, NULL, NULL, NULL, 0, 0, NULL))
			else
				X.object = (ptr !== nothing) ? dataset_init(API, ptr, actual_family) : error("'ptr' = nothing in call to dataset_init()")
			end
		end
		X.family = actual_family[1]
	elseif (X.family == GMT_IS_PALETTE)		# Get a palette from Julia or a dummy one to hold GMT output
		if (!isa(ptr, GMTcpt) && X.direction == GMT_OUT)	# To avoid letting call palette_init() with a nothing
			X.object = convert(Ptr{GMT_PALETTE}, GMT_Create_Data(API, GMT_IS_PALETTE, GMT_IS_NONE, GMT_IS_OUTPUT, NULL, NULL, NULL, 0, 0, NULL))
		else
			X.object = (ptr !== nothing) ? palette_init(API, ptr) : error("'ptr' = nothing in call to palette_init()")
		end
	elseif (X.family == GMT_IS_POSTSCRIPT)	# Get a PostScript struct from Matlab or a dummy one to hold GMT output
		X.object = ps_init(API, ptr, X.direction)
	else
		error("GMTJL_Set_Object: Bad data type ($(X.family))")
	end
	(X.object == NULL) && error("GMT: Failure to register the resource")

	name::String = String([X.name...])
	# Make filename with embedded object ID
	(GMT_Open_VirtualFile(API, X.family, X.geometry, X.direction, X.object, name) != 0) && error("GMT: Failure to open virtual file") 
	# Replace ? in argument with name
	(GMT_Expand_Option(API, X.option, name) != 0) && error("GMT: Failure to expand filename marker (?)") 
	X.name = map(UInt8, (name...,))::NTuple{32, UInt8}

	return X
end

# ---------------------------------------------------------------------------------------------------
function GMTJL_Get_Object(API::Ptr{Nothing}, X::GMT_RESOURCE)
	name = String([X.name...])
	# In line-by-line modules it is possible no output is produced, hence we make an exception for DATASET
	((X.object = GMT_Read_VirtualFile(API, name)) == NULL && X.family != GMT_IS_DATASET) &&
		error("GMT: Error reading virtual file $name from GMT")

	if (X.family == GMT_IS_GRID)         	# A GMT grid; make it the pos'th output item
		ptr = get_grid(API, X.object, false)
	elseif (X.family == GMT_IS_CUBE)       	# A GMT cube; make it the pos'th output item
		ptr = get_grid(API, X.object, true)
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
function grid_init(API::Ptr{Nothing}, X::GMT_RESOURCE, grd_box, pad::Int=2, cube::Bool=false)
# If GRD_BOX is empty just allocate (GMT) an empty container and return
# If GRD_BOX is not empty it must contain a GMTgrid type.

	(isempty_(grd_box)) && return (cube) ?		# Just tell grid_init() to allocate an empty container
		convert(Ptr{GMT_CUBE}, GMT_Create_Data(API, GMT_IS_CUBE, GMT_IS_VOLUME, GMT_IS_OUTPUT, NULL, NULL, NULL, 0, 0, NULL)) :
		convert(Ptr{GMT_GRID}, GMT_Create_Data(API, GMT_IS_GRID, GMT_IS_SURFACE, GMT_IS_OUTPUT, NULL, NULL, NULL, 0, 0, NULL))

	israsters(grd_box) && (grd_box::GMTgrid = rasters2grid(grd_box))
	!isa(grd_box, GMTgrid) && error("grd_init: input ($(typeof(grd_box))) is not a GRID container type")
	grid_init(API, X, grd_box, pad, cube)
end

# ---------------------------------------------------------------------------------------------------
function grid_init(API::Ptr{Nothing}, X::GMT_RESOURCE, Grid::GMTgrid, pad::Int=2, cube::Bool=false)::Ptr{GMT_GRID}
# We are given a Julia grid and use it to fill the GMT_GRID structure

	mode = (Grid.layout != "" && Grid.layout[2] == 'R') ? GMT_CONTAINER_ONLY : GMT_CONTAINER_AND_DATA
	noGrdCopy[1] && (mode = GMT_CONTAINER_ONLY)
	(mode == GMT_CONTAINER_ONLY) && (pad = Grid.pad)		# Here we must follow what the Grid says it has
	n_bds = size(Grid.z, 3);
	_cube = (cube || n_bds > 1)

	if (_cube)
		_inc = copy(Grid.inc)
		(length(_inc) < 3) && (append!(_inc, 1.0))		# Shit this cube has no v_inc
		# We need to make sure z_inc is correct because GMT allocates memory based on the n_bands computed it and z_range
		if ((_nz = round(Int, (Grid.range[6] - Grid.range[5]) / (_inc[3]+eps()) + 1)) != size(Grid.z, 3))	# +eps() to avoid zero division
			_inc[3] = (Grid.range[6] - Grid.range[5]) / (size(Grid.z, 3) - 1.0)
			(length(Grid.inc) < 3) ? @warn("This cube doesn't even has a z_inc. Computing one to not error.") : @warn("The z_inc of this cube is wrong. It is $(Grid.inc[3]) but should be $(_inc[3])")
		end
		G = convert(Ptr{GMT_CUBE}, GMT_Create_Data(API, GMT_IS_CUBE, GMT_IS_VOLUME, mode, NULL, Grid.range, _inc, UInt32(Grid.registration), pad))
		X.family, X.geometry = GMT_IS_CUBE, GMT_IS_VOLUME
	else
		G = convert(Ptr{GMT_GRID}, GMT_Create_Data(API, GMT_IS_GRID, GMT_IS_SURFACE, mode, NULL, Float64.(Grid.range[1:4]), Float64.(Grid.inc[1:2]), UInt32(Grid.registration), pad))
	end

	Gb = unsafe_load(G)			# Gb = GMT_GRID | GMT_CUBE
	h = unsafe_load(Gb.header)

	if (mode == GMT_CONTAINER_AND_DATA)
		grd = Grid.z
		n_rows = size(grd, 1);		n_cols = size(grd, 2);#		mx = n_cols + 2*pad;
		mx, my = Int(h.mx), Int(h.my)
		size2D = mx*my
		t::Vector{Float32} = unsafe_wrap(Array, Gb.data, size2D * n_bds)

		k = 1
		for bnd = 1:n_bds
			off = (bnd - 1) * size2D + pad
			if (eltype(grd) == Float32)
				for col = 1:n_cols, row = n_rows:-1:1
					t[((row-1) + pad) * mx + col + off] = grd[k];		k += 1
				end
			else
				for col = 1:n_cols, row = n_rows:-1:1
					t[((row-1) + pad) * mx + col + off] = Float32(grd[k]);		k += 1
				end
			end
		end
	else
		Gb.data = (eltype(Grid.z) == Float32) ? pointer(Grid.z) : pointer(Float32.(Grid.z))		# Horrible wasting if input is not float32
		GMT_Set_AllocMode(API, GMT_IS_GRID, G)	# Otherwise memory already belongs to GMT
		#GMT_Set_Default(API, "API_GRID_LAYOUT", "TR");
	end

	h.z_min, h.z_max = Grid.range[5], Grid.range[6]		# Set the z_min, z_max
	(_cube) && (h.n_bands = n_bds)

	# Previous to ~14 April 2023 GMT did not accept grids claiming to be geogs and with lon ranges > 360
	no_xUnit = (Grid.range[2] - Grid.range[1]) > 360 && (startswith(Grid.x_unit, "longitude") || contains(Grid.x_unit, "degrees_e"))
	try
		h.x_unit::NTuple{80,UInt8} = !no_xUnit ? map(UInt8, (string(Grid.x_unit, repeat("\0",80-length(Grid.x_unit)))...,)) :
		                                         map(UInt8, (string("x", repeat("\0",79))...,))
		h.y_unit::NTuple{80,UInt8} = map(UInt8, (string(Grid.y_unit, repeat("\0",80-length(Grid.y_unit)))...,))
		h.z_unit::NTuple{80,UInt8} = map(UInt8, (string(Grid.z_unit, repeat("\0",80-length(Grid.z_unit)))...,))
	catch
		h.x_unit = map(UInt8, (string("x", repeat("\0",79))...,))
		h.y_unit = map(UInt8, (string("y", repeat("\0",79))...,))
		h.z_unit = map(UInt8, (string("z", repeat("\0",79))...,))
	end

	(Grid.title != "")   && (h.title   = map(UInt8, (string(Grid.title, repeat("\0", 80-length(Grid.title)))...,)))
	(Grid.remark != "")  && (h.remark  = map(UInt8, (string(Grid.remark, repeat("\0", 160-length(Grid.remark)))...,)))
	(Grid.command != "") && (h.command = map(UInt8, (string(Grid.command, repeat("\0", 320-length(Grid.command)))...,)))
	if (Grid.proj4 != "")    h.ProjRefPROJ4 = pointer(Grid.proj4)  end
	if (Grid.wkt != "")      h.ProjRefWKT   = pointer(Grid.wkt)    end
	if (Grid.epsg != 0)      h.ProjRefEPSG  = Int32(Grid.epsg)     end

	unsafe_store!(Gb.header, h)
	unsafe_store!(G, Gb)

	return G
end

# ---------------------------------------------------------------------------------------------------
function image_init(API::Ptr{Nothing}, img_box)::Ptr{GMT_IMAGE}
# ...

	if (isempty_(img_box))			# Just tell image_init() to allocate an empty container
		I = convert(Ptr{GMT_IMAGE}, GMT_Create_Data(API, GMT_IS_IMAGE, GMT_IS_SURFACE, GMT_IS_OUTPUT, NULL, NULL, NULL, 0, 0, NULL))
		if (IMG_MEM_LAYOUT[1] != "")
			mem_layout = length(IMG_MEM_LAYOUT[1]) == 3 ? IMG_MEM_LAYOUT[1] * "a" : IMG_MEM_LAYOUT[1]
			GMT_Set_Default(API, "API_IMAGE_LAYOUT", mem_layout);
		end
		return I
	end

	!isa(img_box, GMTimage) && error("image_init: input ($(typeof(img_box))) is not a IMAGE container type")
	image_init(API, img_box)
end

# ---------------------------------------------------------------------------------------------------
function image_init(API::Ptr{Nothing}, Img::GMTimage)::Ptr{GMT_IMAGE}
# We are given a Julia image and use it to fill the GMT_IMAGE structure

	n_rows = size(Img.image, 1);		n_cols = size(Img.image, 2);		n_bands = size(Img.image, 3)
	if (Img.layout[2] == 'R' && Img.layout[3] == 'B')  n_rows, n_cols = n_cols, n_rows  end
	family = GMT_IS_IMAGE
	if (n_bands == 2 || n_bands == 4)			# Then we want the alpha layer together with data
		family = family | GMT_IMAGE_ALPHA_LAYER
	end
	pad = (!CTRL.proj_linear[1]) ? 2 : 0
	mode = (pad == 2) ? GMT_CONTAINER_AND_DATA : GMT_CONTAINER_ONLY
	(pad == 2 && Img.pad == 0 && Img.layout[2] == 'R') && (mode = GMT_CONTAINER_AND_DATA)	# Unfortunately

	I = convert(Ptr{GMT_IMAGE}, GMT_Create_Data(API, family, GMT_IS_SURFACE, mode, pointer([n_cols, n_rows, n_bands]),
	                                            Float64.(Img.range[1:4]), Float64.(Img.inc), Img.registration, pad))
	Ib::GMT_IMAGE = unsafe_load(I)				# Ib = GMT_IMAGE (constructor with 1 method)
	h::GMT_GRID_HEADER = unsafe_load(Ib.header)

	mem_owned_by_gmt = true
	already_converted = false
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
	elseif (pad == 2 && Img.pad == 0 && Img.layout[2] == 'R')	# Also need to project
		img_padded = unsafe_wrap(Array, convert(Ptr{UInt8}, Ib.data), h.size * n_bands)
		toRP_pad(Img, img_padded, n_rows, n_cols, pad)
		already_converted = true
	else
		Ib.data = pointer(Img.image)
		mem_owned_by_gmt = (pad == 0) ? false : true
	end

	(mem_owned_by_gmt) && (CTRL.gmt_mem_bag[1] = Ib.data)	# Hold on the GMT owned array to be freed in gmt()

	if (length(Img.colormap) > 3)  Ib.colormap = pointer(Img.colormap)  end
	Ib.n_indexed_colors = Img.n_colors
	if (Img.color_interp != "")    Ib.color_interp = pointer(Img.color_interp)  end
	Ib.alpha = (size(Img.alpha) != (1,1)) ? pointer(Img.alpha) : C_NULL

	GMT_Set_AllocMode(API, GMT_IS_IMAGE, I)		# Tell GMT that memory is external
	h.z_min = Img.range[5]						# Set the z_min, z_max
	h.z_max = Img.range[6]
	im_layout = (length(Img.layout) == 4) ? Img.layout : (length(Img.layout) == 3) ? Img.layout * "a" : Img.layout
	h.mem_layout = map(UInt8, (im_layout...,))
	if (Img.proj4 != "")    h.ProjRefPROJ4 = pointer(Img.proj4)  end
	if (Img.wkt != "")      h.ProjRefWKT   = pointer(Img.wkt)    end
	if (Img.epsg != 0)      h.ProjRefEPSG  = Int32(Img.epsg)     end
	unsafe_store!(Ib.header, h)
	unsafe_store!(I, Ib)

	if (!already_converted && !startswith(Img.layout, "BRP"))
		img = (mem_owned_by_gmt) ? img_padded : copy(Img.image)		# This copy is a waste when not Change_layout. Needs revisit.
		(size(img,3) > 2) && GMT_Change_Layout(API, GMT_IS_IMAGE, "BRP", 0, I, img);	# Convert to BRP. Not 100% on the > 2 though.
		Ib.data = pointer(img)
		unsafe_store!(I, Ib)
	end

	return I
end

function toRP_pad(img, o, n_rows, n_cols, pad)
	# Convert to a B(?T)RP padded array. The shit is that TRB images were read by GDAL and are
	# stored transposed so that we can pass them back to GDAL without any copy. But B(?)RP were
	# read through GMT and are not transposed. This makes a hell to deal with and not messing. 
	n_bands = size(img.image, 3)
	m, i = (n_cols * pad + 5pad) * n_bands, 0	# 5pad!!!!!!! WTF is this coming from? But other numbers create a black stripe on E
	if (img.layout[3] == 'B')			# TRB. Read directly by GDAL and sored transposed.
		if (n_bands == 1)
			@inbounds for n = 1:n_rows
				r = view(img.image, :,n,1)
				@inbounds for k = 1:n_cols  o[m+=1] = r[k]  end
				m += 2pad
			end
		else
			@inbounds for n = 1:n_rows
				r, g, b = view(img.image, :,n,1), view(img.image, :,n,2), view(img.image, :,n,3)
				@inbounds for k = 1:n_cols
					o[m+=1], o[m+=1], o[m+=1] = r[k], g[k], b[k]
				end
				m += 2pad * 3
			end
		end
	else								# B(T?)RP. Read through GMT and NOT stored transposed.
		if (n_bands == 1)
			@inbounds for n = 1:n_rows
				@inbounds for k = 1:n_cols  o[m+=1] = img.image[i+=1]  end
				m += 2pad
			end
		else
			@inbounds for n = 1:n_rows
				@inbounds for k = 1:n_cols
					o[m+=1], o[m+=1], o[m+=1] = img.image[i+=1], img.image[i+=1], img.image[i+=1]
				end
				m += 2pad * 3
			end
		end
	end
	nothing
end

# ---------------------------------------------------------------------------------------------------
function dataset_init(API::Ptr{Nothing}, Darr::Vector{<:GMTdataset}, direction::Integer)::Ptr{GMT_DATASET}
# Create containers to hold or receive data tables:
# direction == GMT_IN:  Create empty GMT_DATASET container, fill from Julia, and use as GMT input.
#	Input from Julia may be a structure or a plain matrix
# direction == GMT_OUT: Create empty GMT_DATASET container, let GMT fill it out, and use for Julia output.
# If direction is GMT_IN then we are given a Julia struct and can determine dimension.
# If output then we dont know size so we set dimensions to zero.

	(Darr == C_NULL || length(Darr) == 0) && error("Input is empty where it can't be.")

	isFV(Darr) && return dataset_init_FV(API, Darr)			# Special case for Face-Vertices obj.

	# We come here if we did not receive a matrix
	dim = [1, 0, 0, 0]
	dim[GMT_SEG+1] = length(Darr)					# Number of segments
	dim[GMT_COL+1] = size(Darr[1].data, 2)			# Number of columns

	mode = (length(Darr[1].text) != 0) ? GMT_WITH_STRINGS : GMT_NO_STRINGS

	pdim = pointer(dim)
	D = convert(Ptr{GMT_DATASET}, GMT_Create_Data(API, GMT_IS_DATASET, GMT_IS_PLP, mode, pdim, NULL, NULL, 0, 0, NULL))
	DS::GMT_DATASET = unsafe_load(D)

	DT = unsafe_load(unsafe_load(DS.table))			# GMT_DATATABLE

	n_records = 0
	isFloat4 = (eltype(Darr[1].data) == Float64)
	for seg = 1:dim[GMT_SEG+1] 						# Each incoming structure is a new data segment
		dim[GMT_ROW+1] = size(Darr[seg].data, 1)	# Number of rows in matrix
		if (dim[GMT_ROW+1] == 0)					# When we have only text
			dim[GMT_ROW+1] = size(Darr[seg].text, 1)
		end

		# This segment also has a cell array of strings?
		mode = (length(Darr[seg].text) != 0) ? GMT_WITH_STRINGS : GMT_NO_STRINGS

		DSv = convert(Ptr{Nothing}, unsafe_load(DT.segment, seg))		# DT.segment = Ptr{Ptr{GMT_DATASEGMENT}}
		S = GMT_Alloc_Segment(API, mode, dim[GMT_ROW+1], dim[GMT_COL+1], Darr[seg].header, DSv) # Ptr{GMT_DATASEGMENT}
		Sb = unsafe_load(S)							# GMT_DATASEGMENT;		Sb.data -> Ptr{Ptr{Float64}}
		for col = 1:Sb.n_columns					# Copy the data columns
			#unsafe_store!(Sb.data, pointer(Darr[seg].data[:,col]), col)	# This would allow shared mem
			if (isFloat4)							# They must be Float64 because of the .data type in GMT_DATASEGMENT
				unsafe_copyto!(unsafe_load(Sb.data, col), pointer(Darr[seg].data[:,col]), Sb.n_rows)
			else
				unsafe_copyto!(unsafe_load(Sb.data, col), pointer(Float64.(Darr[seg].data[:,col])), Sb.n_rows)
			end
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
					println("dataset_init: Failed to set a dataset header")
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
	DT.n_records, DS.n_records = n_records, n_records	# They are equal because our GMT_DATASET have only one table
	Dt = unsafe_load(DS.table)
	unsafe_store!(Dt, DT)
	unsafe_store!(DS.table, Dt)
	unsafe_store!(D, DS)

	return D
end

# ---------------------------------------------------------------------------------------------------
function dataset_init_FV(API::Ptr{Nothing}, FV)::Ptr{GMT_MATRIX}
	V::GMTdataset{Float64,2}, F::GMTdataset{Int,2} = FV[1], FV[2]
	n_segs = size(F.data, 1)				# Number of segments or faces (polygons)
	n_rows = size(F.data, 2)				# Number of rows (vertexes of the polygon)
	n_cols = size(V.data, 2)				# Number of columns (2 for x,y; 3 for x,y,z)
	dim = [1, n_segs, n_rows, n_cols]		# [1, GMT_SEG+1, GMT_ROW+1, GMT_COL+1]

	pdim = pointer(dim)
	D = convert(Ptr{GMT_DATASET}, GMT_Create_Data(API, GMT_IS_DATASET, GMT_IS_PLP, GMT_NO_STRINGS, pdim, NULL, NULL, 0, 0, NULL))
	DS::GMT_DATASET = unsafe_load(D)
	DT = unsafe_load(unsafe_load(DS.table))			# GMT_DATATABLE

	n_records = 0
	tmp = zeros(n_rows, n_cols)

	for seg = 1:n_segs 								# Each row in F (a face) is a new data segment (a polygon)
		DSv = convert(Ptr{Nothing}, unsafe_load(DT.segment, seg))		# DT.segment = Ptr{Ptr{GMT_DATASEGMENT}}
		S = GMT_Alloc_Segment(API, GMT_NO_STRINGS, n_rows, n_cols, "", DSv) # Ptr{GMT_DATASEGMENT}
		Sb = unsafe_load(S)							# GMT_DATASEGMENT;		Sb.data -> Ptr{Ptr{Float64}}
		
		for c = 1:n_cols, r = 1:n_rows
			tmp[r,c] = V.data[F.data[seg, r], c]
		end
		for col = 1:n_cols							# Copy the data columns
			unsafe_copyto!(unsafe_load(Sb.data, col), pointer(tmp[:,col]), n_rows)
		end

		n_records += n_rows							# Must manually keep track of totals
		DS.type_ = GMT_READ_DATA
		unsafe_store!(S, Sb)
		unsafe_store!(DT.segment, S, seg)
	end
	DT.n_records, DS.n_records = n_records, n_records	# They are equal because our GMT_DATASET has only one table
	Dt = unsafe_load(DS.table)
	unsafe_store!(Dt, DT)
	unsafe_store!(DS.table, Dt)
	unsafe_store!(D, DS)

	return D
end

# ---------------------------------------------------------------------------------------------------
function dataset_init(API::Ptr{Nothing}, ptr, actual_family::Vector{<:Integer})::Ptr{GMT_MATRIX}
# Create empty Matrix container, associate it with julia data matrix, and use as GMT input.

	dim = pointer([size(ptr,2), size(ptr,1), 0])	# MATRIX in GMT uses (col,row)
	M = convert(Ptr{GMT_MATRIX}, GMT_Create_Data(API, GMT_IS_MATRIX|GMT_VIA_MATRIX, GMT_IS_PLP, 0, dim, NULL, NULL, 0, 0, NULL))
	actual_family[1] = actual_family[1] | GMT_VIA_MATRIX

	Mb::GMT_MATRIX = unsafe_load(M)			# Mb = GMT_MATRIX (constructor with 1 method)
	#tipo = get_datatype(ptr)
	Mb.n_rows    = size(ptr,1)
	Mb.n_columns = size(ptr,2)

	if (eltype(ptr)     == Float64)		Mb.type = UInt32(GMT_DOUBLE)
	elseif (eltype(ptr) == Float32)		Mb.type = UInt32(GMT_FLOAT)
	elseif (eltype(ptr) == UInt64)		Mb.type = UInt32(GMT_ULONG)
	elseif (eltype(ptr) == Int64)		Mb.type = UInt32(GMT_LONG)
	elseif (eltype(ptr) == UInt32)		Mb.type = UInt32(GMT_UINT)
	elseif (eltype(ptr) == Int32)		Mb.type = UInt32(GMT_INT)
	elseif (eltype(ptr) == UInt16)		Mb.type = UInt32(GMT_USHORT)
	elseif (eltype(ptr) == Int16)		Mb.type = UInt32(GMT_SHORT)
	elseif (eltype(ptr) == UInt8)		Mb.type = UInt32(GMT_UCHAR)
	elseif (eltype(ptr) == Int8)		Mb.type = UInt32(GMT_CHAR)
	else
		error("Only integer or floating point types allowed in input. Not this: $(typeof(ptr))")
	end
	Mb.data = pointer(ptr)
	Mb.dim  = Mb.n_rows		# Data from Julia is in column major
	ret::Cint = GMT_Set_AllocMode(API, GMT_IS_MATRIX, M)
	Mb.shape = GMT_IS_COL_FORMAT;			# Julia order is column major
	unsafe_store!(M, Mb)
	return M
end

# ---------------------------------------------------------------------------------------------------
function palette_init(API::Ptr{Nothing}, cpt::GMTcpt)::Ptr{GMT_PALETTE}
	# Create and fill a GMT CPT.
	# A CPT is categorical when the 'keys' are not empty, and is of type 2 when 'keys' are non-numeric
	# 'labels' can be present in both normal and categorical CPTs so they can't be used to indentify categoricals
	# So, in fact, a normal CPT with labels is equivalent to a categorical with numeric and contiguous 'keys'.

	n_colors = size(cpt.colormap, 1)	# n_colors != n_ranges for continuous CPTs
	n_ranges = size(cpt.range, 1)
	one = 0
	if (n_colors > n_ranges)			# Continuous
		n_ranges, one = n_colors, 1;	# Actual length of colormap array
		n_colors = n_colors - 1;		# Number of CPT slices
	end

	ptr = Ref{UInt64}(n_colors)
	P = convert(Ptr{GMT_PALETTE}, GMT_Create_Data(API, GMT_IS_PALETTE, GMT_IS_NONE, 0, ptr, NULL, NULL, 0, 0, NULL))
	(n_colors > 100000) && @warn("Que exagero de cores")	# Just to protect n_colors to be GC'ed before here

	Pb::GMT_PALETTE = unsafe_load(P)	# We now have a GMT_PALETTE

	(one != 0) && (Pb.is_continuous = UInt32(1))
	if (cpt.depth == 1)      Pb.is_bw   = UInt32(1) 
	elseif (cpt.depth == 8)  Pb.is_gray = UInt32(1)
	end
	!isnan(cpt.hinge) && (Pb.has_hinge = UInt32(1))

	if (!isnan(cpt.hinge))				# If we have a hinge pass it in to the GMT owned struct
		Pb.hinge = cpt.hinge
		Pb.mode = Pb.mode & GMT_CPT_HINGED
	end

	Pb.model = (cpt.model == "rgb") ? GMT_RGB : ((cpt.model == "hsv") ? GMT_HSV : GMT_CMYK)

	# Check 'categorality'
	(cpt.key[1] != "") && (Pb.categorical = (tryparse(Float64, cpt.key[1]) === nothing) ? 2 : 1)

	if (Pb.categorical == 0)			# Categorical CPTs have no BFN
		b = (GMT_BFN((cpt.bfn[1,1], cpt.bfn[1,2], cpt.bfn[1,3],0), Pb.bfn[1].hsv, Pb.bfn[1].skip, Pb.bfn[1].fill),
			GMT_BFN((cpt.bfn[2,1], cpt.bfn[2,2], cpt.bfn[2,3],0), Pb.bfn[1].hsv, Pb.bfn[1].skip, Pb.bfn[1].fill),
			GMT_BFN((cpt.bfn[3,1], cpt.bfn[3,2], cpt.bfn[3,3],0), Pb.bfn[1].hsv, Pb.bfn[1].skip, Pb.bfn[1].fill))
		Pb.bfn = b
	end
	
	for j = 1:Pb.n_colors
		glut = unsafe_load(Pb.data, j)
		rgb_low  = (cpt.cpt[j,1], cpt.cpt[j,2], cpt.cpt[j,3], cpt.alpha[j])
		rgb_high = (cpt.cpt[j,4], cpt.cpt[j,5], cpt.cpt[j,6], cpt.alpha[j+one])
		rgb_diff = (cpt.cpt[j,4]-cpt.cpt[j,1], cpt.cpt[j,5]-cpt.cpt[j,2], cpt.cpt[j,6]-cpt.cpt[j,3], 0.0)
		z_low  = cpt.range[j,1]
		z_high = cpt.range[j,2]
		# GMT6.1 bug does not free "key" but frees "label" and does not see if memory is external. Hence crash or mem leaks

		annot = (j == Pb.n_colors) ? 3 : 1				# Annotations L for all but last which is B(oth)
		lut = GMT_LUT(z_low, z_high, glut.i_dz, rgb_low, rgb_high, rgb_diff, glut.hsv_low, glut.hsv_high,
		              glut.hsv_diff, annot, glut.skip, glut.fill, C_NULL, C_NULL)

		unsafe_store!(Pb.data, lut, j)
	end

	# Categorical case was half broken till 6.2 so we must treat things differently
	if (cpt.key[1] != "")
		GMT_Put_Strings(API, GMT_IS_PALETTE | GMT_IS_PALETTE_KEY, convert(Ptr{Cvoid}, P), cpt.key)
	end
	if (cpt.label[1] != "")
		GMT_Put_Strings(API, GMT_IS_PALETTE | GMT_IS_PALETTE_LABEL, convert(Ptr{Cvoid}, P), cpt.label)
	end

	@GC.preserve P  GMT_Set_AllocMode(API, GMT_IS_PALETTE, P)		# Tell GMT that memory is external (IS IT REALY NEEDED?)
	@GC.preserve Pb unsafe_store!(P, Pb)

	return P
end

# ---------------------------------------------------------------------------------------------------
function ps_init(API::Ptr{Nothing}, ps, dir::Integer)::Ptr{GMT_POSTSCRIPT}
# Used to Create an empty POSTSCRIPT container to hold a GMT POSTSCRIPT object.
# If direction is GMT_IN then we are given a Julia structure with known sizes.
# If direction is GMT_OUT then we allocate an empty GMT POSTSCRIPT as a destination.
	if (dir == GMT_OUT)
		return convert(Ptr{GMT_POSTSCRIPT}, GMT_Create_Data(API, GMT_IS_POSTSCRIPT, GMT_IS_NONE, GMT_IS_OUTPUT, NULL, NULL, NULL, 0, 0, NULL))
	end

	(!isa(ps, GMTps)) && error("Expected a PS structure for input")

	# Passing dim[0] = 0 since we dont want any allocation of a PS string
	pdim = Ref{UInt64}(0)
	P = convert(Ptr{GMT_POSTSCRIPT}, GMT_Create_Data(API, GMT_IS_POSTSCRIPT, GMT_IS_NONE, 0, pdim, NULL, NULL, 0, 0, NULL))

	P0::GMT_POSTSCRIPT = unsafe_load(P)		# GMT_POSTSCRIPT

	P0.n_bytes = ps.length
	P0.mode = ps.mode
	P0.data = pointer(ps.postscript)
	GMT_Set_AllocMode(API, GMT_IS_POSTSCRIPT, P)

	unsafe_store!(P, P0)
	return P
end

# ---------------------------------------------------------------------------------------------------
function ogr2GMTdataset(in::Ptr{OGR_FEATURES}, drop_islands=false)::Union{GMTdataset, Vector{<:GMTdataset}}
	(in == NULL)  && return nothing
	OGR_F::OGR_FEATURES = unsafe_load(in)
	n_max = OGR_F.n_rows * OGR_F.n_cols * OGR_F.n_layers
	n_total_segments = OGR_F.n_filled
	ds_bbox = OGR_F.BoundingBox
	(n_total_segments == 0) && (@warn("Could not read this OGR dataset. A reading error or there is no data in it."); return GMTdataset())

	if (!drop_islands)
		# First count the number of islands. Need to know the size to put in the D pre-allocation
		n_islands = OGR_F.n_islands
		for k = 2:n_max
			OGR_F = unsafe_load(in, k)
			n_islands += OGR_F.n_islands
		end
		n_total_segments += n_islands
		(n_islands > 0) && println("\tThis file has islands (holes in polygons).\n\tUse `gmtread(..., no_islands=true)` to ignore them.")
	end

	D::Vector{GMTdataset} = Vector{GMTdataset}(undef, n_total_segments)

	n = 1
	attrib = DictSvS();	# For the case there are no attribs at all.
	have_Feature_ID = (GMTver >= v"6.5.0")		# Feature_ID is available only in >= GMT6.5.0
	for k = 1:n_max
		OGR_F = unsafe_load(in, k)
		if (k == 1)
			proj4 = OGR_F.proj4 != C_NULL ? unsafe_string(OGR_F.proj4) : ""
			wkt   = OGR_F.wkt != C_NULL ? unsafe_string(OGR_F.wkt) : ""
			(proj4 == "" && wkt != "") && (proj4 = wkt2proj(wkt))
			is_geog = (contains(proj4, "=longlat") || contains(proj4, "=lonlat") || contains(proj4, "=latlon")) ? true : false
			(coln = (is_geog) ? ["Lon", "Lat"] : ["X", "Y"])
		else
			proj4, wkt, coln = "", "", String[]
		end

		if (OGR_F.np > 0)
			hdr = ""
			if (OGR_F.att_number > 0)
				attrib = DictSvS()
				for i = 1:OGR_F.att_number
					attrib[unsafe_string(unsafe_load(OGR_F.att_names,i))] = unsafe_string(unsafe_load(OGR_F.att_values,i))
				end
				(have_Feature_ID) && (attrib["Feature_ID"] = unsafe_string(OGR_F.name))		# Needs GMT6.5.0
			else		# use the previous attrib. This is RISKY but gmt_ogrread only stores attribs in 1st geom of each feature
				(n > 1) && (attrib = D[n-1].attrib)
			end

			if (OGR_F.n_islands == 0)
				geom_type = unsafe_string(OGR_F.type)
				geom = (geom_type == "Polygon") ? wkbPolygon : ((geom_type == "LineString") ? wkbLineString : wkbPoint)
				D[n] = GMTdataset([unsafe_wrap(Array, OGR_F.x, OGR_F.np) unsafe_wrap(Array, OGR_F.y, OGR_F.np)],
				                  Float64[], Float64[], attrib, coln, String[], hdr, String[], proj4, wkt, 0, Int(geom))
			else
				islands = reshape(unsafe_wrap(Array, OGR_F.islands, 2 * (OGR_F.n_islands+1)), OGR_F.n_islands+1, 2) 
				np_main = islands[1,2]+1			# Number of points of outer ring
				D[n] = GMTdataset([unsafe_wrap(Array, OGR_F.x, np_main) unsafe_wrap(Array, OGR_F.y, np_main)], Float64[],
				                  Float64[], attrib, coln, String[], hdr, String[], proj4, wkt, 0, Int(wkbPolygon))

				if (!drop_islands)
					for k = 2:size(islands,2)		# 2 because first row holds the outer ring indexes 
						n = n + 1
						off = islands[k,1] * 8
						len = islands[k,2] - islands[k,1] + 1
						D[n] = GMTdataset([unsafe_wrap(Array, OGR_F.x+off, len) unsafe_wrap(Array, OGR_F.y+off, len)],
						                  Float64[], Float64[], attrib, coln, String[], " -Ph", String[], proj4, wkt, 0, Int(wkbPolygon))
					end
				end
			end
			n = n + 1
		end
	end
	(n_total_segments > (n-1)) && deleteat!(D, n:n_total_segments)
	for k = 1:length(D)			# Compute the BoundingBoxes per segment (C version doesn't do it)
		bb = Base.invokelatest(extrema, D[k].data, dims=1)		# A N Tuple.
		D[k].bbox = collect(Float64, Iterators.flatten(bb))
	end
	D[1].ds_bbox = collect(ds_bbox)			# It always has 6 elements and last two maybe zero
	return (length(D) == 1) ? D[1] : D
end

# ---------------------------------------------------------------------------------------------------
function strncmp(str1::String, str2::String, num)
	# Pseudo strncmp
	a = str1[1:min(num,length(str1))] == str2
end

#= ---------------------------------------------------------------------------------------------------
function mutateit(API::Ptr{Nothing}, t_type, member::String, val)
	# Mutate the member 'member' of an immutable struct whose pointer is T_TYPE
	# VAL is the new value of the MEMBER field.
	# It's up to the user to guarantie that MEMBER and VAL have the same data type
	# T_TYPE can actually be either a variable of a certain struct or a pointer to it.
	# In latter case, we fish the specific datatype from it.
	if (isa(t_type, Ptr))
		x_type, p_type = unsafe_load(t_type), t_type
	else
		x_type, p_type = t_type, pointer([t_type])	# Need the pointer to later send to GMT_blind_change
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
=#

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
function resetGMT(dorestart::Bool=true)
	# Reset everything to a fresh GMT session. That is reset all global variables to their initial state
	IamModern[1] = false;	FirstModern[1] = false;		IamSubplot[1] = false;	usedConfPar[1] = false;
	MULTI_COL[1] = false;	CONVERT_SYNTAX[1] = false;	CURRENT_VIEW[1] = "";	SHOW_KWARGS[1] = false;
	IMG_MEM_LAYOUT[1] = "";	GRD_MEM_LAYOUT[1] = "";		CTRL.limits .= 0.0;	CTRL.proj_linear[1] = true;
	CTRLshapes.fname[1] = "";CTRLshapes.first[1] = true; CTRLshapes.points[1] = false;
	CURRENT_CPT[1]  = GMTcpt();		LEGEND_TYPE[1] = legend_bag();	ressurectGDAL()
	DEF_FIG_AXES[1] = DEF_FIG_AXES_BAK;		DEF_FIG_AXES3[1] = DEF_FIG_AXES3_BAK;
	CTRL.pocket_J[1], CTRL.pocket_J[2], CTRL.pocket_J[3], CTRL.pocket_J[4] = "", "", "", "   ";
	CTRL.IamInPaperMode[:] = [false, true];	IamInset[1], IamInset[2] = false, false
	CTRL.pocket_call[1:3] .= nothing;	CTRL.pocket_R[1:2] .= "";	CTRL.figsize .= 0.0
	CTRL.XYlabels[1] = "";	CTRL.XYlabels[2] = "";	CTRL.returnPS[1] = false
	(dorestart) && (gmt_restart(); clear_sessions())
end

# ---------------------------------------------------------------------------------------------------
"""
    upGMT(up=false)

Check if a new GMT (C binaries) version is available. If yes, use `upGMT(true)` to update it.
"""
function upGMT(up::Bool=false, auto::Bool=false)
	!Sys.iswindows() && (@warn("This function is for Windows use only."); return nothing)
	fn = joinpath(dirname(@__FILE__),"..","deps","devdate.txt")
	d = Date(readline(fn), dateformat"y-m-d")
	if (GMTdevdate < d)
		!up ? println("A New GMT C library version ($d) is available. Update it with:\n\t upGMT(true)") :
		      (ENV["UPDATE_GMTWIN"] = 1;  Pkg.build("GMT"))
	else
		!auto && println("You are using the latest available GMT binary.")
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function clear_sessions(age::Int=0)
	# Delete stray sessions left behind by old failed process. Thanks to @htyeim
	# AGE is in seconds
	# Windows version of ``gmt clear sessions`` fails in 6.0 and it errors if no sessions dir
	try		# Because the sessions dir may not exist 
		sp = joinpath(GMTuserdir[1], "sessions")
		dirs = readdir(sp)
		isempty(dirs) && return nothing
		session_dirs = filter(x->startswith(x, "gmt_session."), dirs)
		n = datetime2unix(now(UTC))
		for sd in session_dirs
			fp = joinpath(sp, sd)
			(n - mtime(fp) > age) && rm(fp, recursive = true)	# created age seconds before
		end
	catch
	end
end

function print_ranges(GI::GItype)
	println("x_min: ", GI.range[1], "\tx_max :", GI.range[2], "\tx_inc :", GI.inc[1], "\tn_columns :", size(GI,2))
	println("y_min: ", GI.range[3], "\ty_max :", GI.range[4], "\ty_inc :", GI.inc[2], "\tn_rows :", size(GI,1))
	(eltype(GI) <: Complex) ? println("z_min: ", GI.range[5], "\tz_max :", GI.range[6], "\tz_min_img :", GI.range[7], "\tz_max_img :", GI.range[8]) :
	println("z_min: ", GI.range[5], "\tz_max :", GI.range[6])
end
function print_crs(GID, saysomething=false)
	(saysomething && GID.proj4 == "" && GID.wkt == "" && GID.epsg == 0) && (println("This object have no proj information."); return)
	(GID.proj4 != "") && println("PROJ: ", GID.proj4)
	(GID.wkt   != "") && println("WKT: ",  GID.wkt)
	(GID.epsg  != 0)  && println("EPSG: ", GID.epsg)
	return nothing
end

"""
### `info(GI, showdata::Bool=true; data=true, full=false, crs::Bool=false)`

Shows information about the `GI` grid or image that includes dimensional and, if exists, referencing data.

- `showdata`: Boolean that controls if a small array subset is printed or not.
  Alternatively, use `data=false` as a synonym for not showing the data array.
- `crs`: Boolean that if `true` only prints the referencing information.
- `full`: For grids print also some more type metadata (var names, etc).

### `info(D::GDtype; crs::Bool=false, attribs=false, att="")`

Shows information about the `D` GMTdataset (or vector of them).

- `crs`: Boolean that if `true` only prints the referencing information.
- `attribs`: In case the dataset has attributes, like they do when resulting from reading a shape file, use
  this parameter to print only the attribute table. A setting of `attribs=true` will print the entire attributes
  table. Give a positive number, _e.g._ `attribs=5` to show only the first 5 attributes. A negative number prints
  the last n attribs. A vector range, `attribs=5:9` is also accepted.
- `att`: Name of one attribute. Returns a string vector with the values of the attribute passed into this option.
  Example, ``attn = info(D, att="NAME")`` returns all values of the attribute ``NAME``.

### `info(any)`

Runs ``show(stdout, "text/plain", any)`` which prints all elements of `any`. Good for printing the entire vector or matrix.
"""
function info(GI::GItype, showdata::Bool=true; data=true, full=false, crs::Bool=false)
	isempty(GI) && return println("Empty object")
	crs && return print_crs(GI)
	(data != 1) && (showdata = false)
	isa(GI, GMTimage) ? println("A GMTimage object with $(size(GI,3)) bands of type $(eltype(GI))") :
	                    println("A GMTgrid object with $(size(GI,3)) layers of type $(eltype(GI))")
	!all(isempty.(GI.names)) && [println('\t',name) for name in GI.names]
	if isa(GI, GMTgrid)
		(GI.title   != "" && GI.title[1]   != '\0') && println("title: ", rstrip(GI.title, '\0'))
		(GI.remark  != "" && GI.remark[1]  != '\0') && println("remark: ", rstrip(GI.remark, '\0'))
		(GI.command != "" && GI.command[1] != '\0') && println("command: ", rstrip(GI.command, '\0'))
	end
	println((GI.registration == 0) ? "Gridline " : "Pixel ", "node registration used")
	print_ranges(GI)
	(isa(GI, GMTgrid) && GI.scale != 1) && println("Scale, Offset: ", GI.scale, "\t", GI.offset)
	println("Mem layout:\t", GI.layout)
	if (isa(GI, GMTgrid) && full == 1)
		println("Nodata: ", GI.nodata, "\tHas nodata: ", GI.hasnans, "\tPad: ", GI.pad)
		println("x_unit: ", GI.x_unit, "\ty_unit: ", GI.y_unit, "\tz_unit: ", GI.z_unit, "\tv_unit: ", GI.v_unit)
	end
	print_crs(GI)
	showdata && (isa(GI, GMTgrid) ? display(GI.z) : display(GI.image))
	return nothing
end

function info(D::GDtype; crs::Bool=false, attribs=false, att::StrSymb="")
	crs && return isa(D, Vector) ? print_crs(D[1]) : print_crs(D)	# Report projection info and return

	(attribs == false) && (_D = isa(D, Vector) ? D[1] : D)
	(attribs == false && att == "" && isempty(_D.attrib)) && return show(_D)
	(attribs == false && att == "") && (t = make_attrtbl(D, false);
	                                    return isa(t, Tuple) ? show(_D, attrib_table=t[1]) : show(_D, attrib_table=t))

	# OK, here we are dealing with printing the attribs, or returning a column with the values of one attrib.
	(attribs == false && att != "")	&& (attribs = true)
	n_att = (attribs == true) ? 0 : attribs
	!isa(n_att, Int) && !isa(n_att, AbstractVector) && error("'attribs' can only be an integer or an AbstractVector.")
	
	tit = "Attribute table (Dict{String, String})"
	if (!isa(D, Vector) && att == "")
		pretty_table(reshape(vec(string.(values(D.attrib))), 1, length(D.attrib)), header=vec(string.(keys(D.attrib))), title=tit)
	else
		# Do differently depending on: plot whole attrib table or return the values of one attribute.
		if (att == "") att_tbl, att_names = make_attrtbl(D, true)
		else           att_tbl = make_attrtbl(D, att=att)
		end
		if (isa(n_att, Int))
			tbl = (n_att > 0) ? att_tbl[1:n_att,:] : (n_att < 0) ? att_tbl[size(att_tbl,1)+n_att+1:end,:] : att_tbl
		else
			tbl = att_tbl[n_att, :]
		end
		(att != "") && return tbl				# If only one attribute was requested we end here.
		pretty_table(tbl; header=att_names, alignment=:l, show_row_number=true, title=tit, crop=:horizontal)
	end
	return nothing
end
info(any) = show(stdout, "text/plain", any)		# Show the f all of whatever 'any' is

# ---------------------------------------------------------------------------------------------------
Base.:show(io::IO, G::GMTgrid) = info(G, false)
Base.:display(G::GMTgrid) = show(G)		# Otherwise by default it only displays the numbers
Base.:show(io::IO, I::GMTimage) = info(I, false)
Base.:display(I::GMTimage) = show(I)

"""
    att_tbl, att_names = make_attrtbl(D::GDtype, names::Bool=false; att::StrSymb="")

Create a string matrix with the dataset attributes. 'names', if true, returns also a string vector
with attribute names. 'att', if == to one atribute, returns only that column of the att table.
"""
function make_attrtbl(D::GDtype, names::Bool=false; att::StrSymb="")
	!isa(D, Vector) && (att_tbl = reshape(vec(string.(values(D.attrib))),1,length(D.attrib)))
	!isa(D, Vector) && return att_tbl

	len_D, len_att = length(D), length(D[1].attrib)
	att_tbl = Matrix{String}(undef, len_D, len_att)
	for k = 1:len_D
		att_tbl[k, :] = reshape(vec(string.(values(D[k].attrib))), 1, len_att)
	end
	att_names = (names || att != "") ? vec(string.(keys(D[1].attrib))) : String[]
	(att != "") && ((ind = findfirst(string(att) .== att_names)) !== nothing) && return att_tbl[:,ind]
	att_tbl, att_names
end

# ---------------------------------------------------------------------------------------------------
function Base.:show(io::IO, ::MIME"text/plain", D::Vector{<:GMTdataset})
	println(typeof(D), " with ", length(D), " segments")
	(length(D) == 0) && return

	println("Showing first segment. To see other segments just type its element number. e.g. D[2]\n")
	isempty(D[1].attrib) ? show(D[1]) : show(D[1], attrib_table=make_attrtbl(D, false)[1])
end
Base.:show(io::IO, ::MIME"text/plain", D::GMTdataset) = show(D)
Base.:display(D::GMTdataset) = show(D)		# Otherwise the default prints nothing when text only (data == [])

# ---------------------------------------------------------------------------------------------------
function Base.show(io::IO, C::GMTcpt)
	isempty(C) && return
	if (C.categorical > 0)
		mat = (size(C.cpt,1) > 1) ? [C.range[:,1] round.([C.colormap*255 C.alpha[1:size(C.cpt,1)]*255], digits=0)] : [C.range[1] round.([C.colormap*255 C.alpha[1]*255], digits=0)]
		D = GMTdataset(data=mat, colnames=["z", "r", "g", "b", "alpha"])
	else
		mat = (size(C.cpt,1) > 1) ? [round.([C.cpt.*255 C.alpha[1:size(C.cpt,1)].*255], digits=0) C.range] : [round.([C.cpt.*255 C.alpha[1].*255], digits=0) C.range]
		D = GMTdataset(data=mat, colnames=["r1", "g1", "b1", "r2", "g2", "b2", "alpha", "z1", "z2"])
	end
	D.bbox = Float64[]
	(!isempty(C.label) && length(C.label) == size(C.cpt,1) && any(C.label .!= "")) && (D.text = C.label)
	println("Extract of a GMTcpt exposed as a GMTdataset for display.")
	(C.categorical > 0) && println("CATEGORICAL palette.")
	(~all(isempty.(C.comment))) && println("Comment:\t", C.comment)
	println("Model: ", C.model)
	println("Color depth: ", C.depth)
	(!isnan(C.hinge)) && println("Hinge: ", C.hinge)
	show(D, text_colname="Labels")		# text_colname will not be used if CPT.label is empty (most of times)
end
Base.:show(io::IO, ::MIME"text/plain", C::GMTcpt) = show(C)


info(C::GMTcpt) = show(C)

# ---------- For Pluto ------------------------------------------------------------------------------
Base.:show(io::IO, mime::MIME"image/png", wp::WrapperPluto) = write(io, read(wp.fname))

# ---------- For Tables -----------------------------------------------------------------------------
Base.:names(D::GDtype) = isa(D, Vector) ? D[1].colnames : D.colnames
#Base.:names(D::GMTdataset) = D.colnames
#Base.:names(D::Vector{GMTdataset}) = D[1].colnames

# ---------- For fck stop printing UInts in hexadecinal ---------------------------------------------
#Base.show(io::IO, x::T) where {T<:Union{UInt, UInt128, UInt64, UInt32, UInt16, UInt8}} = Base.print(io, x)
