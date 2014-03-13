module GMT

export
	GMT_Create_Session,
	create_session,
	GMT_Create_Data,
	create_data,
	GMT_Get_Data,
	GMT_Read_Data,
	GMT_Retrieve_Data,
	GMT_Retrieve_Data,
	GMT_Message,
	GMT_Call_Module,
	GMT_IS_DATASET, GMT_IS_TEXTSET, GMT_IS_GRID,
	GMT_IS_CPT, GMT_IS_IMAGE, GMT_IS_VECTOR, GMT_IS_MATRIX,
	GMT_IS_COORD, GMT_IS_POINT,	GMT_IS_MATRIX, GMT_IS_SURFACE,
	GMT_DATASET,
	GMT_UNIVECTOR

include("gmt_common.jl")
include("GMTfuns.jl")


end