VERSION >= v"0.4" && __precompile__()

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
	GMT_GRID, GMT_MATRIX, GMT_PALETTE,
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
	array_container,
	GMTAPI_get_moduleinfo, GMTAPI_lib_tag, GMTAPI_key_to_family, GMTAPI_get_key, GMTAPI_found_marker,
	GMTAPI_open_grd, GMTAPI_close_grd, GMTAPI_update_txt_item, GMTAPI_get_key, GMT_Encode_Options, GMT_Expand_Option,
	GMT_grid_flip_vertical,
	gmt_core_module_info,
	gmt,
	GMT_RESOURCE, GMTAPI_CTRL, GMTAPI_DATA_OBJECT

include("libgmt_h.jl")
include("libgmt.jl")
include("gmt_main.jl")

end # module
