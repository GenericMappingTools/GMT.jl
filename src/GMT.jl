module GMT

export
	GMT_Call_Module,
	GMT_Create_Args,
	GMT_Create_Session,
	GMT_Create_Options,
	GMT_Create_Cmd,
	GMT_Create_Data,
	GMT_Destroy_Options,
	GMT_Destroy_Args,
	GMT_Encode_ID,
	GMT_Get_ID,
	GMT_Get_Default,
	GMT_Option,
	GMT_Read_Data,
	GMT_Register_IO,
	GMT_Get_Data,
	GMT_Retrieve_Data,
	GMT_Destroy_Data,
	GMT_Message,
	GMT_Call_Module,
	GMT_Write_Data,
	GMT_IS_DATASET, GMT_IS_TEXTSET, GMT_IS_GRID, GMT_IS_LINE,
	GMT_IS_CPT, GMT_IS_IMAGE, GMT_IS_VECTOR, GMT_IS_MATRIX,
	GMT_IS_COORD, GMT_IS_POINT,	GMT_IS_MATRIX, GMT_IS_SURFACE,
	GMT_DATASET, GMT_IS_PLP,
	GMT_GRID, GMT_MATRIX,
	GMT_UNIVECTOR,
	GMT_IN, GMT_OUT, GMT_OK,
	GMT_IS_FILE, GMT_IS_STREAM,	GMT_IS_FDESC,
	GMT_IS_DUPLICATE, GMT_IS_REFERENCE,
	GMT_VIA_NONE, GMT_VIA_VECTOR, GMT_VIA_MATRIX, GMT_VIA_OUTPUT,
	GMT_IS_DUPLICATE_VIA_VECTOR, GMT_IS_REFERENCE_VIA_VECTOR,
	GMT_IS_DUPLICATE_VIA_MATRIX, GMT_IS_REFERENCE_VIA_MATRIX,
	GMT_MODULE_EXIST, GMT_MODULE_PURPOSE, GMT_MODULE_OPT, GMT_MODULE_CMD,
	GMT_GRID_DATA_ONLY, GMT_GRID_HEADER_ONLY, GMT_GRID_ALL,
	GMT_GRID_ALL, GMT_WRITE_SET, GMT_Report,
	GMT_grd_container,
	GMTAPI_get_moduleinfo, GMTAPI_lib_tag, GMTAPI_key_to_family, GMTAPI_get_key, GMTAPI_found_marker,
	GMTAPI_open_grd, GMTAPI_close_grd, GMTAPI_update_txt_item, GMTAPI_get_key, GMT_Encode_Options, GMT_Expand_Option,
	gmt_core_module_info,
	# From gmtjl_parser
	GMTJL_find_module, GMTJL_pre_process, GMTJL_post_process, GMTJL_Register_IO, GMTJL_Register_IO, 
	# From gmt_modules
	gmt_modules, GMT_RESOURCE, GMTJL_GRID,

	gmt, grdread, grdwrite, grdimage, GMTJL_grid_init, GMTJL_matrix_init

include("libgmt_h.jl")
include("libgmt.jl")
include("gmtjl_parser.jl")
include("gmt_modules.jl")
include("gmt_main.jl")


# Encarnation of the old Matlab grdread that reads a grid
function grdread(API::Ptr{None}, fname::String)
	wesn = zeros(4);
	G = GMT_Read_Data(API, GMT_IS_GRID, GMT_IS_FILE, GMT_IS_SURFACE, GMT_GRID_ALL, wesn, fname, C_NULL)
	Gb = unsafe_load(G)
	hdr = unsafe_load(Gb.header)
	header = [hdr.wesn.d1,hdr.wesn.d2,hdr.wesn.d3,hdr.wesn.d4,hdr.z_min,hdr.z_max,hdr.registration,hdr.inc.d1,hdr.inc.d2]

	grd = pointer_to_array(Gb.data, convert(Int64,hdr.nx*hdr.ny))		# It converts Uint32*Uint32 = Uint64 ????
	grd = reshape(grd,(int64(hdr.ny),int64(hdr.nx)));
	return grd,header
end

function grdwrite(API::Ptr{None}, fname::String, hdr::Array{Float64}, grd::Array{Float32})
	nx = uint64((hdr[2] - hdr[1]) / hdr[8]) + (hdr[7] != 0 ? 1 : 0)
	ny = uint64((hdr[4] - hdr[3]) / hdr[9]) + (hdr[7] != 0 ? 1 : 0)
	dim = [nx, ny, 1];
	wesn = hdr[1:4]
	inc = hdr[8:9]
	
	G = GMT_Create_Data (API, GMT_IS_GRID, GMT_IS_SURFACE, GMT_GRID_HEADER_ONLY, C_NULL, wesn, inc, hdr[7], 2)
	Gb = unsafe_load(G)			# Gb = GMT_GRID (constructor with 1 method)
	Gb.data = pointer(grd)
	unsafe_store!(G, Gb)

	err = (GMT_Write_Data (API, GMT_IS_GRID, GMT_IS_FILE, GMT_IS_SURFACE, GMT_WRITE_SET, wesn, fname, G) != GMT_OK)
end

function grdimage (API, wesn=C_NULL, img=C_NULL)
	wesn = [-10,0,35,45];
	img = Array(Uint8,256,256,3);
	if ((ID = GMT_Register_IO (API, GMT_IS_IMAGE, GMT_IS_REFERENCE, GMT_IS_SURFACE, GMT_IN, wesn, img)) == GMT_NOTSET)
		println("GRDIMAGE ERROR: Failed to register source")
		return -1
		#return (API.error)
	end
	
	str = bytestring(Array(Uint8, 16))
	if (GMT_Encode_ID (API, str, ID) != GMT_OK)		# Make filename with embedded object ID
		println("GRDIMAGE ERROR: Failed to encode source")
		return -1
		#return (API->error);
	end

	s = str * " -R-10/0/35/45 -JM14c -Ba2 -P -Vd > lixo.ps"
	println(s)
	if (GMT_Call_Module (API, "grdimage", GMT_MODULE_CMD, s) != GMT_OK)		# Plot the image
		#Return (API->error);
	end
end

end # module
