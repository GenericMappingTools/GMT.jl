# Julia wrapper for header: /cmn/ext/gmt/gmt-5.1.1/src/gmt.h
# Automatically generated using Clang.jl wrap_c, version 0.0.0

#@windows? lib = "gmt_w64" : lib = "libgmt"   # Name of GMT shared lib.
const thelib = "gmt_w64"


function GMT_Create_Session(tag::String="Unknown", pad=2, mode=0, print_func::Ptr{Void}=C_NULL)
	ccall( (:GMT_Create_Session, thelib), Ptr{None}, (Ptr{Uint8}, Uint32, Uint32, Ptr{Void}), tag, pad, mode, print_func)
end

function GMT_Create_Data(API::Ptr{None}, family, geometry, mode, dim=C_NULL,
		wesn=C_NULL, inc=C_NULL, registration=0, pad=2, data::Ptr{None}=C_NULL)

	if (family == GMT_IS_DATASET)
		ret_type = Ptr{GMT_DATASET}
	elseif (family == GMT_IS_TEXTSET)
		ret_type = Ptr{GMT_TEXTSET}
	elseif (family == GMT_IS_GRID)
		ret_type = Ptr{GMT_GRID}
	elseif (family == GMT_IS_CPT)
		ret_type = Ptr{GMT_PALETTE}
	elseif (family == GMT_IS_IMAGE)
		ret_type = Ptr{GMT_IMAGE}
	elseif (family == GMT_IS_MATRIX)
		ret_type = Ptr{GMT_MATRIX}
	elseif (family == GMT_IS_VECTOR)
		ret_type = Ptr{GMT_VECTOR}
	else
		ret_type = Ptr{None}			# Should be error instead
	end

	ptr = ccall( (:GMT_Create_Data, thelib), Ptr{None}, (Ptr{None}, Uint32, Uint32, Uint32, Ptr{Uint64},
		Ptr{Cdouble}, Ptr{Cdouble}, Uint32, Cint, Ptr{None}), API, family, geometry, mode, dim, wesn, inc,
		registration, pad, data)

	convert(ret_type, ptr)
end

function GMT_Get_Data(API::Ptr{None}, object_ID::Cint, mode::Uint32, data::Ptr{None})
  ccall( (:GMT_Get_Data, thelib), Ptr{None}, (Ptr{None}, Cint, Uint32, Ptr{None}), API, object_ID, mode, data)
end

function GMT_Read_Data(API::Ptr{None}, family, method, geometry, mode, wesn, input=C_NULL, data=C_NULL)

	if (family == GMT_IS_DATASET)
		ret_type = Ptr{GMT_DATASET}
	elseif (family == GMT_IS_TEXTSET)
		ret_type = Ptr{GMT_TEXTSET}
	elseif (family == GMT_IS_GRID)
		ret_type = Ptr{GMT_GRID}
	elseif (family == GMT_IS_CPT)
		ret_type = Ptr{GMT_PALETTE}
	elseif (family == GMT_IS_IMAGE)
		ret_type = Ptr{GMT_IMAGE}
	elseif (family == GMT_IS_MATRIX)
		ret_type = Ptr{GMT_MATRIX}
	elseif (family == GMT_IS_VECTOR)
		ret_type = Ptr{GMT_VECTOR}
	else
		ret_type = Ptr{None}			# Should be error instead
	end

	ptr = ccall( (:GMT_Read_Data, thelib), Ptr{None}, (Ptr{None}, Uint32, Uint32, Uint32, Uint32, Ptr{Cdouble},
		Ptr{Uint8}, Ptr{None}), API, family, method, geometry, mode, wesn, input, data)

	convert(ret_type, ptr)
end

function GMT_Retrieve_Data(API::Ptr{None}, object_ID::Cint)
  ccall( (:GMT_Retrieve_Data, thelib), Ptr{None}, (Ptr{None}, Cint), API, object_ID)
end
function GMT_Duplicate_Data(API::Ptr{None}, family::Uint32, mode::Uint32, data::Ptr{None})
  ccall( (:GMT_Duplicate_Data, thelib), Ptr{None}, (Ptr{None}, Uint32, Uint32, Ptr{None}), API, family, mode, data)
end
function GMT_Get_Record(API::Ptr{None}, mode::Uint32, retval::Ptr{Cint})
  ccall( (:GMT_Get_Record, thelib), Ptr{None}, (Ptr{None}, Uint32, Ptr{Cint}), API, mode, retval)
end
function GMT_Destroy_Session(API::Ptr{None})
  ccall( (:GMT_Destroy_Session, thelib), Cint, (Ptr{None},), API)
end

function GMT_Register_IO(API::Ptr{None}, family, method, geometry, direction=0, wesn=C_NULL, resource=C_NULL)
	ccall( (:GMT_Register_IO, thelib), Cint, (Ptr{None}, Uint32, Uint32, Uint32, Uint32, Ptr{Cdouble},
		Ptr{None}), API, family, method, geometry, direction, wesn, resource)
end

function GMT_Init_IO(API::Ptr{None}, family::Uint32, geometry::Uint32, direction::Uint32, mode::Uint32, n_args::Uint32, args::Ptr{None})
  ccall( (:GMT_Init_IO, thelib), Cint, (Ptr{None}, Uint32, Uint32, Uint32, Uint32, Uint32, Ptr{None}), API, family, geometry, direction, mode, n_args, args)
end
function GMT_Begin_IO(API::Ptr{None}, family::Uint32, direction::Uint32, header::Uint32)
  ccall( (:GMT_Begin_IO, thelib), Cint, (Ptr{None}, Uint32, Uint32, Uint32), API, family, direction, header)
end
function GMT_Status_IO(API::Ptr{None}, mode::Uint32)
  ccall( (:GMT_Status_IO, thelib), Cint, (Ptr{None}, Uint32), API, mode)
end
function GMT_End_IO(API::Ptr{None}, direction::Uint32, mode::Uint32)
  ccall( (:GMT_End_IO, thelib), Cint, (Ptr{None}, Uint32, Uint32), API, direction, mode)
end
function GMT_Put_Data(API::Ptr{None}, object_ID::Cint, mode::Uint32, data::Ptr{None})
  ccall( (:GMT_Put_Data, thelib), Cint, (Ptr{None}, Cint, Uint32, Ptr{None}), API, object_ID, mode, data)
end

function GMT_Write_Data(API::Ptr{None}, family::Integer, method::Integer, geometry::Integer, mode::Integer,
	wesn::Ptr{Cdouble}, output::String, data)

	ccall( (:GMT_Write_Data, thelib), Cint, (Ptr{None}, Uint32, Uint32, Uint32, Uint32, Ptr{Cdouble},
		Ptr{Uint8}, Ptr{None}), API, family, method, geometry, mode, wesn, output, data)
end

function GMT_Destroy_Data(API::Ptr{None}, object::Ptr{None})
  ccall( (:GMT_Destroy_Data, thelib), Cint, (Ptr{None}, Ptr{None}), API, object)
end
function GMT_Put_Record(API::Ptr{None}, mode::Uint32, record::Ptr{None})
  ccall( (:GMT_Put_Record, thelib), Cint, (Ptr{None}, Uint32, Ptr{None}), API, mode, record)
end
function GMT_Encode_ID(API::Ptr{None}, string::Ptr{Uint8}, object_ID::Cint)
  ccall( (:GMT_Encode_ID, thelib), Cint, (Ptr{None}, Ptr{Uint8}, Cint), API, string, object_ID)
end
function GMT_Get_Row(API::Ptr{None}, rec_no::Cint, G::Ptr{GMT_GRID}, row::Ptr{Cfloat})
  ccall( (:GMT_Get_Row, thelib), Cint, (Ptr{None}, Cint, Ptr{GMT_GRID}, Ptr{Cfloat}), API, rec_no, G, row)
end
function GMT_Put_Row(API::Ptr{None}, rec_no::Cint, G::Ptr{GMT_GRID}, row::Ptr{Cfloat})
  ccall( (:GMT_Put_Row, thelib), Cint, (Ptr{None}, Cint, Ptr{GMT_GRID}, Ptr{Cfloat}), API, rec_no, G, row)
end
function GMT_Set_Comment(API::Ptr{None}, family::Uint32, mode::Uint32, arg::Ptr{None}, data::Ptr{None})
  ccall( (:GMT_Set_Comment, thelib), Cint, (Ptr{None}, Uint32, Uint32, Ptr{None}, Ptr{None}), API, family, mode, arg, data)
end
function GMT_Get_ID(API::Ptr{None}, family::Uint32, direction::Uint32, resource::Ptr{None})
  ccall( (:GMT_Get_ID, thelib), Cint, (Ptr{None}, Uint32, Uint32, Ptr{None}), API, family, direction, resource)
end
function GMT_Get_Index(API::Ptr{None}, header::Ptr{GMT_GRID_HEADER}, row::Cint, col::Cint)
  ccall( (:GMT_Get_Index, thelib), int64_t, (Ptr{None}, Ptr{GMT_GRID_HEADER}, Cint, Cint), API, header, row, col)
end
function GMT_Get_Coord(API::Ptr{None}, family::Uint32, dim::Uint32, container::Ptr{None})
  ccall( (:GMT_Get_Coord, thelib), Ptr{Cdouble}, (Ptr{None}, Uint32, Uint32, Ptr{None}), API, family, dim, container)
end

function GMT_Option(API::Ptr{None}, options)
	ccall( (:GMT_Option, thelib), Cint, (Ptr{None}, Ptr{Uint8}), API, options)
end

function GMT_Get_Common(API::Ptr{None}, option::Uint32, par::Ptr{Cdouble})
  ccall( (:GMT_Get_Common, thelib), Cint, (Ptr{None}, Uint32, Ptr{Cdouble}), API, option, par)
end

function GMT_Get_Default(API::Ptr{None}, keyword::String, value)
	ccall( (:GMT_Get_Default, thelib), Cint, (Ptr{None}, Ptr{Uint8}, Ptr{Uint8}), API, keyword, value)
end

function GMT_Get_Value(API::Ptr{None}, arg::String, par::Ptr{Cdouble})
  ccall( (:GMT_Get_Value, thelib), Cint, (Ptr{None}, Ptr{Uint8}, Ptr{Cdouble}), API, arg, par)
end

function GMT_Call_Module(API::Ptr{None}, _module=C_NULL, mode=0, args=C_NULL)
	ccall( (:GMT_Call_Module, thelib), Cint, (Ptr{None}, Ptr{Uint8}, Cint, Ptr{None}), API, _module, mode, args)
end

function GMT_Create_Options(API::Ptr{None}, argc::Cint, in::Ptr{None})
  ccall( (:GMT_Create_Options, thelib), Ptr{GMT_OPTION}, (Ptr{None}, Cint, Ptr{None}), API, argc, in)
end
function GMT_Make_Option(API::Ptr{None}, option::Uint8, arg::Ptr{Uint8})
  ccall( (:GMT_Make_Option, thelib), Ptr{GMT_OPTION}, (Ptr{None}, Uint8, Ptr{Uint8}), API, option, arg)
end
function GMT_Find_Option(API::Ptr{None}, option::Uint8, head::Ptr{GMT_OPTION})
  ccall( (:GMT_Find_Option, thelib), Ptr{GMT_OPTION}, (Ptr{None}, Uint8, Ptr{GMT_OPTION}), API, option, head)
end
function GMT_Append_Option(API::Ptr{None}, current::Ptr{GMT_OPTION}, head::Ptr{GMT_OPTION})
  ccall( (:GMT_Append_Option, thelib), Ptr{GMT_OPTION}, (Ptr{None}, Ptr{GMT_OPTION}, Ptr{GMT_OPTION}), API, current, head)
end
function GMT_Create_Args(API::Ptr{None}, argc::Ptr{Cint}, head::Ptr{GMT_OPTION})
  ccall( (:GMT_Create_Args, thelib), Ptr{Ptr{Uint8}}, (Ptr{None}, Ptr{Cint}, Ptr{GMT_OPTION}), API, argc, head)
end
function GMT_Create_Cmd(API::Ptr{None}, head::Ptr{GMT_OPTION})
  ccall( (:GMT_Create_Cmd, thelib), Ptr{Uint8}, (Ptr{None}, Ptr{GMT_OPTION}), API, head)
end
function GMT_Destroy_Options(API::Ptr{None}, head::Ptr{Ptr{GMT_OPTION}})
  ccall( (:GMT_Destroy_Options, thelib), Cint, (Ptr{None}, Ptr{Ptr{GMT_OPTION}}), API, head)
end
function GMT_Destroy_Args(API::Ptr{None}, argc::Cint, argv::Ptr{Ptr{Ptr{Uint8}}})
  ccall( (:GMT_Destroy_Args, thelib), Cint, (Ptr{None}, Cint, Ptr{Ptr{Ptr{Uint8}}}), API, argc, argv)
end
function GMT_Destroy_Cmd(API::Ptr{None}, cmd::Ptr{Ptr{Uint8}})
  ccall( (:GMT_Destroy_Cmd, thelib), Cint, (Ptr{None}, Ptr{Ptr{Uint8}}), API, cmd)
end
function GMT_Update_Option(API::Ptr{None}, current::Ptr{GMT_OPTION}, arg::Ptr{Uint8})
  ccall( (:GMT_Update_Option, thelib), Cint, (Ptr{None}, Ptr{GMT_OPTION}, Ptr{Uint8}), API, current, arg)
end
function GMT_Delete_Option(API::Ptr{None}, current::Ptr{GMT_OPTION})
  ccall( (:GMT_Delete_Option, thelib), Cint, (Ptr{None}, Ptr{GMT_OPTION}), API, current)
end
function GMT_Parse_Common(API::Ptr{None}, given_options::Ptr{Uint8}, options::Ptr{GMT_OPTION})
  ccall( (:GMT_Parse_Common, thelib), Cint, (Ptr{None}, Ptr{Uint8}, Ptr{GMT_OPTION}), API, given_options, options)
end
function GMT_FFT_Option(API::Ptr{None}, option::Uint8, dim::Uint32, string::Ptr{Uint8})
  ccall( (:GMT_FFT_Option, thelib), Uint32, (Ptr{None}, Uint8, Uint32, Ptr{Uint8}), API, option, dim, string)
end
function GMT_FFT_Parse(API::Ptr{None}, option::Uint8, dim::Uint32, args::Ptr{Uint8})
  ccall( (:GMT_FFT_Parse, thelib), Ptr{None}, (Ptr{None}, Uint8, Uint32, Ptr{Uint8}), API, option, dim, args)
end
function GMT_FFT_Create(API::Ptr{None}, X::Ptr{None}, dim::Uint32, mode::Uint32, F::Ptr{None})
  ccall( (:GMT_FFT_Create, thelib), Ptr{None}, (Ptr{None}, Ptr{None}, Uint32, Uint32, Ptr{None}), API, X, dim, mode, F)
end
function GMT_FFT_Wavenumber(API::Ptr{None}, k::Uint64, mode::Uint32, K::Ptr{None})
  ccall( (:GMT_FFT_Wavenumber, thelib), Cdouble, (Ptr{None}, Uint64, Uint32, Ptr{None}), API, k, mode, K)
end
function GMT_FFT(API::Ptr{None}, X::Ptr{None}, direction::Cint, mode::Uint32, K::Ptr{None})
  ccall( (:GMT_FFT, thelib), Cint, (Ptr{None}, Ptr{None}, Cint, Uint32, Ptr{None}), API, X, direction, mode, K)
end
function GMT_FFT_Destroy(API::Ptr{None}, K::Ptr{None})
  ccall( (:GMT_FFT_Destroy, thelib), Cint, (Ptr{None}, Ptr{None}), API, K)
end
function GMT_FFT_1D(API::Ptr{None}, data::Ptr{Cfloat}, n::Uint64, direction::Cint, mode::Uint32)
  ccall( (:GMT_FFT_1D, thelib), Cint, (Ptr{None}, Ptr{Cfloat}, Uint64, Cint, Uint32), API, data, n, direction, mode)
end
function GMT_FFT_2D(API::Ptr{None}, data::Ptr{Cfloat}, nx::Uint32, ny::Uint32, direction::Cint, mode::Uint32)
  ccall( (:GMT_FFT_2D, thelib), Cint, (Ptr{None}, Ptr{Cfloat}, Uint32, Uint32, Cint, Uint32), API, data, nx, ny, direction, mode)
end
function GMT_F77_readgrdinfo_(dim::Ptr{Uint32}, wesn::Ptr{Cdouble}, inc::Ptr{Cdouble}, title::Ptr{Uint8}, remark::Ptr{Uint8}, file::Ptr{Uint8})
  ccall( (:GMT_F77_readgrdinfo_, thelib), Cint, (Ptr{Uint32}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Uint8}, Ptr{Uint8}, Ptr{Uint8}), dim, wesn, inc, title, remark, file)
end
function GMT_F77_readgrd_(array::Ptr{Cfloat}, dim::Ptr{Uint32}, wesn::Ptr{Cdouble}, inc::Ptr{Cdouble}, title::Ptr{Uint8}, remark::Ptr{Uint8}, file::Ptr{Uint8})
  ccall( (:GMT_F77_readgrd_, thelib), Cint, (Ptr{Cfloat}, Ptr{Uint32}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Uint8}, Ptr{Uint8}, Ptr{Uint8}), array, dim, wesn, inc, title, remark, file)
end
function GMT_F77_writegrd_(array::Ptr{Cfloat}, dim::Ptr{Uint32}, wesn::Ptr{Cdouble}, inc::Ptr{Cdouble}, title::Ptr{Uint8}, remark::Ptr{Uint8}, file::Ptr{Uint8})
  ccall( (:GMT_F77_writegrd_, thelib), Cint, (Ptr{Cfloat}, Ptr{Uint32}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Uint8}, Ptr{Uint8}, Ptr{Uint8}), array, dim, wesn, inc, title, remark, file)
end

