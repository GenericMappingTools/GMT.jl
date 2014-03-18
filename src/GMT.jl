module GMT

export
	GMT_Call_Module,
	GMT_Create_Session,
	GMT_Create_Data,
	GMT_Get_Default,
	GMT_Option,
	GMT_Read_Data,
	GMT_Register_IO,
	GMT_Get_Data,
	GMT_Read_Data,
	GMT_Retrieve_Data,
	GMT_Retrieve_Data,
	GMT_Message,
	GMT_Call_Module,
	GMT_Write_Data,
	GMT_IS_DATASET, GMT_IS_TEXTSET, GMT_IS_GRID, GMT_IS_LINE,
	GMT_IS_CPT, GMT_IS_IMAGE, GMT_IS_VECTOR, GMT_IS_MATRIX,
	GMT_IS_COORD, GMT_IS_POINT,	GMT_IS_MATRIX, GMT_IS_SURFACE,
	GMT_DATASET,
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
	GMT_GRID_ALL,
	grdread, grdwrite

include("libgmt_h.jl")
include("libgmt.jl")

# Encarnation of the old Matlab grdread that reads a grid
function grdread(API::Ptr{None}, fname::String)
	wesn = zeros(6);
	G = GMT_Read_Data(API, GMT_IS_GRID, GMT_IS_FILE, GMT_IS_SURFACE, GMT_GRID_ALL, wesn, fname, C_NULL)
	Gb = unsafe_load(G)
	hdr = unsafe_load(Gb.header)
	header = [hdr.wesn.d1,hdr.wesn.d2,hdr.wesn.d3,hdr.wesn.d4,hdr.z_min,hdr.z_max,hdr.registration,hdr.inc.d1,hdr.inc.d2]

	grd=pointer_to_array(Gb.data, convert(Int64,hdr.nx*hdr.ny))		# It converts Uint32*Uint32 = Uint64 ????
	grd = reshape(grd,(int64(hdr.ny),int64(hdr.nx)));
	return grd,header
end

function grdwrite(API::Ptr{None}, fname::String, hdr::Array{Float64}, grd::Array{Float32})
	nx = uint64((hdr[2] - hdr[1]) / hdr[8]) + (hdr[7] != 0 ? 1 : 0)
	ny = uint64((hdr[4] - hdr[3]) / hdr[9]) + (hdr[7] != 0 ? 1 : 0)
	dim = [nx, ny, 1];
	wesn = hdr[1:6]
	inc = hdr[8:9]
	#M = GMT_Create_Data (API, GMT_IS_GRID, GMT_IS_SURFACE, 0, dim)
		#No wesn given and no -R in effect.  Cannot initialize new grid
	
	#M = GMT_Create_Data (API, GMT_IS_MATRIX, GMT_IS_SURFACE, 0, dim)
	#Mb = unsafe_load(M)
	
	G = GMT_Create_Data (API, GMT_IS_GRID, GMT_IS_SURFACE, GMT_GRID_HEADER_ONLY, C_NULL, wesn, inc, hdr[7], 2)
	Gb = unsafe_load(G)
	unsafe_store!(Gb.data, reshape(grd,nx*ny))

	#err = (GMT_Write_Data (API, GMT_IS_GRID, GMT_IS_FILE, GMT_IS_SURFACE, GMT_WRITE_SET, wesn, fname, M) != GMT_OK)
	#return err
end

end # module
