# Julia wrapper for header: /opt/local/include/gmt/gmt.h
# Automatically generated using Clang.jl wrap_c, version 0.0.0

#@windows? lib = "gmt_w64" : lib = "libgmt"		# Name of GMT shared lib.
const lib = "gmt_w64"

@c Ptr{None} GMT_Create_Session (Ptr{Uint8}, Uint32, Uint32, Ptr{Void}) lib
function create_session(tag::String="INCOGNITO", pad::Integer=2)
	API=ccall((:GMT_Create_Session,lib), Ptr{Void}, (Ptr{Uint8},Uint32,Uint32,Ptr{Void}), tag, uint32(pad), uint32(0), C_NULL)
end

# void *GMT_Create_Data (void *API, unsigned int family, unsigned int geometry,
#                        unsigned int mode, uint64_t par[], double *wesn,
#                        double *inc, unsigned int registration, int pad, void *data)
@c Ptr{None} GMT_Create_Data (Ptr{None}, Uint32, Uint32, Uint32, Ptr{Culonglong}, Ptr{Cdouble},
		Ptr{Cdouble}, Uint32, Cint, Ptr{None}) gmt_w64

function create_data(API::Ptr{None}, family, geometry, mode, par,
        wesn::Ptr=C_NULL, inc::Ptr=C_NULL, reg=0, pad=2, data::Ptr{Void}=C_NULL)

	if (family == GMT_IS_VECTOR)
		ret_type = Ptr{GMT_VECTOR}
	elseif (family == GMT_IS_IMAGE)
		ret_type = Ptr{GMT_IMAGE}
	elseif (family == GMT_IS_MATRIX)
		ret_type = Ptr{GMT_MATRIX}
	elseif (family == GMT_IS_DATASET)
		ret_type = Ptr{GMT_DATASET}
	else
		ret_type = Ptr{None}
	end

	ptr = ccall((:GMT_Create_Data,lib), Ptr{Void}, (Ptr{None}, Uint32, Uint32, Uint32, Ptr{Culonglong},
		Ptr{Cdouble}, Ptr{Cdouble}, Uint32, Cint, Ptr{None}),
		API, uint32(family),uint32(geometry),uint32(mode),par,wesn,inc,uint32(reg),int32(pad), data)

	convert(ret_type, ptr)
end

@c Ptr{None} GMT_Get_Data (Ptr{None}, Cint, Uint32, Ptr{None}) lib
@c Ptr{None} GMT_Read_Data (Ptr{None}, Uint32, Uint32, Uint32, Uint32, Ptr{Cdouble}, Ptr{Uint8}, Ptr{None}) lib
@c Ptr{None} GMT_Retrieve_Data (Ptr{None}, Cint) lib
@c Ptr{None} GMT_Duplicate_Data (Ptr{None}, Uint32, Uint32, Ptr{None}) lib
@c Ptr{None} GMT_Get_Record (Ptr{None}, Uint32, Ptr{Cint}) lib
@c Cint GMT_Destroy_Session (Ptr{None},) lib
@c Cint GMT_Register_IO (Ptr{None}, Uint32, Uint32, Uint32, Uint32, Ptr{Cdouble}, Ptr{None}) lib
@c Cint GMT_Init_IO (Ptr{None}, Uint32, Uint32, Uint32, Uint32, Uint32, Ptr{None}) lib
@c Cint GMT_Begin_IO (Ptr{None}, Uint32, Uint32, Uint32) lib
@c Cint GMT_Status_IO (Ptr{None}, Uint32) lib
@c Cint GMT_End_IO (Ptr{None}, Uint32, Uint32) lib
@c Cint GMT_Put_Data (Ptr{None}, Cint, Uint32, Ptr{None}) lib
@c Cint GMT_Write_Data (Ptr{None}, Uint32, Uint32, Uint32, Uint32, Ptr{Cdouble}, Ptr{Uint8}, Ptr{None}) lib
@c Cint GMT_Destroy_Data (Ptr{None}, Ptr{None}) lib
@c Cint GMT_Put_Record (Ptr{None}, Uint32, Ptr{None}) lib
@c Cint GMT_Encode_ID (Ptr{None}, Ptr{Uint8}, Cint) lib
@c Cint GMT_Get_Row (Ptr{None}, Cint, Ptr{GMT_GRID}, Ptr{Cfloat}) lib
@c Cint GMT_Put_Row (Ptr{None}, Cint, Ptr{GMT_GRID}, Ptr{Cfloat}) lib
@c Cint GMT_Set_Comment (Ptr{None}, Uint32, Uint32, Ptr{None}, Ptr{None}) lib
@c Cint GMT_Get_ID (Ptr{None}, Uint32, Uint32, Ptr{None}) lib
@c int64_t GMT_Get_Index (Ptr{None}, Ptr{GMT_GRID_HEADER}, Cint, Cint) lib
@c Ptr{Cdouble} GMT_Get_Coord (Ptr{None}, Uint32, Uint32, Ptr{None}) lib
@c Cint GMT_Option (Ptr{None}, Ptr{Uint8}) lib
@c Cint GMT_Get_Common (Ptr{None}, Uint32, Ptr{Cdouble}) lib
@c Cint GMT_Get_Default (Ptr{None}, Ptr{Uint8}, Ptr{Uint8}) lib
@c Cint GMT_Get_Value (Ptr{None}, Ptr{Uint8}, Ptr{Cdouble}) lib
@c Cint GMT_Report (Ptr{None}, Uint32, Ptr{Uint8}) lib
@c Cint GMT_Message (Ptr{None}, Uint32, Ptr{Uint8}) lib
@c Cint GMT_Call_Module (Ptr{None}, Ptr{Uint8}, Cint, Ptr{None}) lib
@c Ptr{GMT_OPTION} GMT_Create_Options (Ptr{None}, Cint, Ptr{None}) lib
@c Ptr{GMT_OPTION} GMT_Make_Option (Ptr{None}, Uint8, Ptr{Uint8}) lib
@c Ptr{GMT_OPTION} GMT_Find_Option (Ptr{None}, Uint8, Ptr{GMT_OPTION}) lib
@c Ptr{GMT_OPTION} GMT_Append_Option (Ptr{None}, Ptr{GMT_OPTION}, Ptr{GMT_OPTION}) lib
@c Ptr{Ptr{Uint8}} GMT_Create_Args (Ptr{None}, Ptr{Cint}, Ptr{GMT_OPTION}) lib
@c Ptr{Uint8} GMT_Create_Cmd (Ptr{None}, Ptr{GMT_OPTION}) lib
@c Cint GMT_Destroy_Options (Ptr{None}, Ptr{Ptr{GMT_OPTION}}) lib
@c Cint GMT_Destroy_Args (Ptr{None}, Cint, Ptr{Ptr{Ptr{Uint8}}}) lib
@c Cint GMT_Destroy_Cmd (Ptr{None}, Ptr{Ptr{Uint8}}) lib
@c Cint GMT_Update_Option (Ptr{None}, Ptr{GMT_OPTION}, Ptr{Uint8}) lib
@c Cint GMT_Delete_Option (Ptr{None}, Ptr{GMT_OPTION}) lib
@c Cint GMT_Parse_Common (Ptr{None}, Ptr{Uint8}, Ptr{GMT_OPTION}) lib
@c Uint32 GMT_FFT_Option (Ptr{None}, Uint8, Uint32, Ptr{Uint8}) lib
@c Ptr{None} GMT_FFT_Parse (Ptr{None}, Uint8, Uint32, Ptr{Uint8}) lib
@c Ptr{None} GMT_FFT_Create (Ptr{None}, Ptr{None}, Uint32, Uint32, Ptr{None}) lib
@c Cdouble GMT_FFT_Wavenumber (Ptr{None}, uint64_t, Uint32, Ptr{None}) lib
@c Cint GMT_FFT (Ptr{None}, Ptr{None}, Cint, Uint32, Ptr{None}) lib
@c Cint GMT_FFT_Destroy (Ptr{None}, Ptr{None}) lib
@c Cint GMT_FFT_1D (Ptr{None}, Ptr{Cfloat}, uint64_t, Cint, Uint32) lib
@c Cint GMT_FFT_2D (Ptr{None}, Ptr{Cfloat}, Uint32, Uint32, Cint, Uint32) lib
@c Cint GMT_F77_readgrdinfo_ (Ptr{Uint32}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Uint8}, Ptr{Uint8}, Ptr{Uint8}) lib
@c Cint GMT_F77_readgrd_ (Ptr{Cfloat}, Ptr{Uint32}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Uint8}, Ptr{Uint8}, Ptr{Uint8}) lib
@c Cint GMT_F77_writegrd_ (Ptr{Cfloat}, Ptr{Uint32}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Uint8}, Ptr{Uint8}, Ptr{Uint8}) lib

