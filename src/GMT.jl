VERSION >= v"0.4" && __precompile__()

module GMT

GMTver = 5.4

export
	GMTver,
	GMT_Call_Module,
	GMT_Create_Args,
	GMT_Create_Session,
	GMT_Create_Options,
	GMT_Create_Cmd,
	GMT_Create_Data,
	GMT_Destroy_Options,
	GMT_Destroy_Args,
	GMT_Destroy_Session,
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
	GMT_Write_Data,
	GMT_Init_VirtualFile, GMT_Open_VirtualFile, GMT_Close_VirtualFile, GMT_Read_VirtualFile,
	GMT_Get_Matrix, GMT_Put_Matrix, GMT_Get_Vector, GMT_Put_Vector,
	GMT_IS_DATASET, GMT_IS_TEXTSET, GMT_IS_GRID, GMT_IS_LINE,
	GMT_IS_CPT, GMT_IS_IMAGE, GMT_IS_VECTOR, GMT_IS_MATRIX,
	GMT_IS_POINT, GMT_IS_SURFACE, GMT_DATASET, GMT_IS_PLP,
	GMT_GRID, GMT_MATRIX, GMT_PALETTE, GMT_PS,
	GMT_UNIVECTOR, GMT_IN, GMT_OUT, GMT_OK,
	GMT_VIA_NONE, GMT_VIA_VECTOR, GMT_VIA_MATRIX, GMT_VIA_OUTPUT,
	GMT_IS_DUPLICATE_VIA_VECTOR, GMT_IS_REFERENCE_VIA_VECTOR,
	GMT_IS_DUPLICATE_VIA_MATRIX, GMT_IS_REFERENCE_VIA_MATRIX,
	GMT_MODULE_EXIST, GMT_MODULE_PURPOSE, GMT_MODULE_OPT, GMT_MODULE_CMD,
	GMT_GRID_ALL,
	GMT_Report, array_container,
	GMT_Encode_Options, GMT_Expand_Option, gmtlib_grd_flip_vertical,
	gmt_core_module_info,
	gmt, grid_type,
	GMT_RESOURCE, GMTAPI_CTRL, GMTAPI_DATA_OBJECT,
	pscoast, pscoast!, psxy, psxy!, grdcontour, grdcontour!, grdimage, grdimage!,
	grdview, grdview!, plot, plot!, makecpt, psscale, psscale!,
	NULL

include("common_docs.jl")
include("libgmt_h.jl")
include("libgmt.jl")
include("gmt_main.jl")
include("common_options.jl")
include("pscoast.jl")
include("psscale.jl")
include("psxy.jl")
include("plot.jl")
include("grdcontour.jl")
include("grdimage.jl")
include("grdview.jl")
include("makecpt.jl")

end # module
