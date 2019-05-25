#@static Sys.iswindows() ? (const thelib = "c:/v/build5/src/gmt_w64") : (const thelib = "libgmt")  # Name of GMT shared lib.
#@static Sys.iswindows() ? (const thelib = "C:/progs_cygw/GMTdev/gmt5/5.4/WIN64/bin/gmt_w64") : (const thelib = "libgmt")  # Name of GMT shared lib.
@static Sys.iswindows() ? (Sys.WORD_SIZE == 64 ? (const thelib = "gmt_w64") : (const thelib = "gmt_w32")) : (const thelib = "libgmt")  # Name of GMT shared lib.

function GMT_Create_Session(tag::String="GMT", pad=2, mode=0, print_func::Ptr{Cvoid}=C_NULL)
	ccall( (:GMT_Create_Session, thelib), Ptr{Cvoid}, (Ptr{UInt8}, UInt32, UInt32, Ptr{Cvoid}), tag, pad, mode, print_func)
end

function GMT_Create_Data(API::Ptr{Cvoid}, family, geometry, mode, dim=C_NULL, wesn=C_NULL,
                         inc=C_NULL, registration=0, pad=2, data::Ptr{Cvoid}=C_NULL)

	if (family == GMT_IS_DATASET)        ret_type = Ptr{GMT_DATASET}
	elseif (family == GMT_IS_TEXTSET)    ret_type = Ptr{GMT_TEXTSET}
	elseif (family == GMT_IS_GRID)       ret_type = Ptr{GMT_GRID}
	elseif (family == GMT_IS_CPT)        ret_type = Ptr{GMT_PALETTE}
	elseif (family == GMT_IS_IMAGE)      ret_type = Ptr{GMT_IMAGE}
	elseif (family == GMT_IS_MATRIX)     ret_type = Ptr{GMT_MATRIX}
	elseif (family == GMT_IS_MATRIX|GMT_VIA_MATRIX) ret_type = Ptr{GMT_MATRIX}
	elseif (family == GMT_IS_VECTOR)     ret_type = Ptr{GMT_VECTOR}
	elseif (family == GMT_IS_POSTSCRIPT) ret_type = Ptr{GMT_POSTSCRIPT}
	else                                 ret_type = Ptr{Cvoid}		# Should be error instead
	end

	ptr = ccall((:GMT_Create_Data, thelib), Ptr{Cvoid}, (Cstring, UInt32, UInt32, UInt32, Ptr{UInt64},
		Ptr{Cdouble}, Ptr{Cdouble}, UInt32, Cint, Ptr{Cvoid}), API, family, geometry, mode, dim, wesn, inc,
		registration, pad, data)

	convert(ret_type, ptr)
end

function GMT_Destroy_Session(API::Ptr{Cvoid})
	ccall( (:GMT_Destroy_Session, thelib), Cint, (Cstring,), API)
end

#=		Not used yet, so comment
function GMT_Read_Data(API::Ptr{Cvoid}, family, method, geometry, mode, wesn, input=C_NULL, data=C_NULL)

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
		ret_type = Ptr{Cvoid}			# Should be error instead
	end

	ptr = ccall( (:GMT_Read_Data, thelib), Ptr{Cvoid}, (Ptr{Cvoid}, UInt32, UInt32, UInt32, UInt32, Ptr{Cdouble},
		Ptr{UInt8}, Ptr{Cvoid}), API, family, method, geometry, mode, wesn, input, data)

	convert(ret_type, ptr)
end

function GMT_Insert_Data(API::Ptr{Cvoid}, object_ID::Integer, data)
	ccall((:GMT_Insert_Data, thelib), Cint, (Ptr{Cvoid}, Cint, Ptr{Cvoid}), API, object_ID, data)
end

function GMT_Duplicate_Data(API::Ptr{Cvoid}, family::Integer, mode::Integer, data::Ptr{Cvoid})
	ccall( (:GMT_Duplicate_Data, thelib), Ptr{Cvoid}, (Ptr{Cvoid}, UInt32, UInt32, Ptr{Cvoid}), API, family, mode, data)
end

function GMT_Get_Record(API::Ptr{Cvoid}, mode::Integer, retval::Ptr{Cint})
	ccall( (:GMT_Get_Record, thelib), Ptr{Cvoid}, (Ptr{Cvoid}, UInt32, Ptr{Cint}), API, mode, retval)
end

function GMT_Manage_Session(API::Ptr{Cvoid}, mode::Integer, args::Ptr{Cvoid})
	ccall( (:GMT_Manage_Session, thelib), Cint, (Ptr{Cvoid}, UInt32, Ptr{Cvoid}), API, mode, args)
end

function GMT_Register_IO(API, family::Integer, method::Integer, geometry::Integer, direction::Integer=0,
		wesn=C_NULL, resource=C_NULL)
	err = ccall((:GMT_Register_IO, thelib), Cint, (Ptr{Cvoid}, UInt32, UInt32, UInt32, UInt32, Ptr{Cdouble},
		Ptr{Cvoid}), API, family, method, geometry, direction, wesn, resource)
end

function GMT_Init_IO(API::Ptr{Cvoid}, family::UInt32, geometry::UInt32, direction::UInt32, mode::UInt32, n_args::UInt32, args::Ptr{Cvoid})
	ccall( (:GMT_Init_IO, thelib), Cint, (Ptr{Cvoid}, UInt32, UInt32, UInt32, UInt32, UInt32, Ptr{Cvoid}), API, family, geometry, direction, mode, n_args, args)
end
function GMT_Begin_IO(API::Ptr{Cvoid}, family::UInt32, direction::UInt32, header::UInt32)
	ccall( (:GMT_Begin_IO, thelib), Cint, (Ptr{Cvoid}, UInt32, UInt32, UInt32), API, family, direction, header)
end
function GMT_Status_IO(API::Ptr{Cvoid}, mode::UInt32)
	ccall( (:GMT_Status_IO, thelib), Cint, (Ptr{Cvoid}, UInt32), API, mode)
end
function GMT_End_IO(API::Ptr{Cvoid}, direction::UInt32, mode::UInt32)
	ccall( (:GMT_End_IO, thelib), Cint, (Ptr{Cvoid}, UInt32, UInt32), API, direction, mode)
end

function GMT_Write_Data(API::Ptr{Cvoid}, family::Integer, method::Integer, geometry::Integer, mode::Integer,
	wesn, output::String, data)
	err = ccall((:GMT_Write_Data, thelib), Cint, (Ptr{Cvoid}, UInt32, UInt32, UInt32, UInt32, Ptr{Cdouble},
		Ptr{UInt8}, Ptr{Cvoid}), API, family, method, geometry, mode, wesn, output, data)
end
=#

function GMT_Destroy_Data(API::Ptr{Cvoid}, object)
	ccall( (:GMT_Destroy_Data, thelib), Cint, (Cstring, Ptr{Cvoid}), API, object)
end

function GMT_Set_Comment(API::Ptr{Cvoid}, family::Integer, mode::Integer, arg::Ptr{Cvoid}, data::Ptr{Cvoid})
	ccall( (:GMT_Set_Comment, thelib), Cint, (Cstring, UInt32, UInt32, Ptr{Cvoid}, Ptr{Cvoid}), API, family, mode, arg, data)
end

#=
function GMT_Put_Record(API::Ptr{Cvoid}, mode::UInt32, record::Ptr{Cvoid})
	ccall( (:GMT_Put_Record, thelib), Cint, (Ptr{Cvoid}, UInt32, Ptr{Cvoid}), API, mode, record)
end

function GMT_Encode_ID(API::Ptr{Cvoid}, fname::String, object_ID::Integer)
	err = ccall((:GMT_Encode_ID, thelib), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Cint), API, fname, object_ID)
end

function GMT_Get_Row(API::Ptr{Cvoid}, rec_no::Cint, G::Ptr{GMT_GRID}, row::Ptr{Cfloat})
	ccall( (:GMT_Get_Row, thelib), Cint, (Ptr{Cvoid}, Cint, Ptr{GMT_GRID}, Ptr{Cfloat}), API, rec_no, G, row)
end
function GMT_Put_Row(API::Ptr{Cvoid}, rec_no::Cint, G::Ptr{GMT_GRID}, row::Ptr{Cfloat})
	ccall( (:GMT_Put_Row, thelib), Cint, (Ptr{Cvoid}, Cint, Ptr{GMT_GRID}, Ptr{Cfloat}), API, rec_no, G, row)
end

function GMT_Get_ID(API::Ptr{Cvoid}, family::Integer, dir::Integer, resource=C_NULL)
	ccall((:GMT_Get_ID, thelib), Cint, (Ptr{Cvoid}, UInt32, UInt32, Ptr{Cvoid}), API, family, dir, resource)
end

function GMT_Get_Family(API::Ptr{Cvoid}, dir::Integer, head::Ptr{GMT_OPTION})
	ccall((:GMT_Get_Family, thelib), Cint, (Ptr{Cvoid}, UInt32, Ptr{GMT_OPTION}), API, dir, head)
end

function GMT_Get_Index(API::Ptr{Cvoid}, header::Ptr{GMT_GRID_HEADER}, row::Cint, col::Cint)
	ccall((:GMT_Get_Index, thelib), Clonglong, (Ptr{Cvoid}, Ptr{GMT_GRID_HEADER}, Cint, Cint), API, header, row, col)
end
function GMT_Get_Coord(API::Ptr{Cvoid}, family::Integer, dim::Integer, container::Ptr{Cvoid})
	ccall((:GMT_Get_Coord, thelib), Ptr{Cdouble}, (Ptr{Cvoid}, UInt32, UInt32, Ptr{Cvoid}), API, family, dim, container)
end

function GMT_Option(API::Ptr{Cvoid}, options)
	ccall((:GMT_Option, thelib), Cint, (Ptr{Cvoid}, Ptr{UInt8}), API, options)
end

function GMT_Get_Common(API::Ptr{Cvoid}, option::UInt32, par::Ptr{Cdouble})
	ccall((:GMT_Get_Common, thelib), Cint, (Ptr{Cvoid}, UInt32, Ptr{Cdouble}), API, option, par)
end

function GMT_Get_Value(API::Ptr{Cvoid}, arg::String, par::Ptr{Cdouble})
	ccall((:GMT_Get_Value, thelib), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Cdouble}), API, arg, par)
end
function GMT_Get_Values(API::Ptr{Cvoid}, arg::String, par::Ptr{Cdouble}, maxpar::Integer)
	ccall((:GMT_Get_Values, thelib), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Cdouble}, Cint), API, arg, par, maxpar)
end
=#

function GMT_Get_Default(API::Ptr{Cvoid}, keyword::String, value)
    ccall((:GMT_Get_Default, thelib), Cint, (Cstring, Ptr{UInt8}, Ptr{UInt8}), API, keyword, value)
end

function GMT_Call_Module(API::Ptr{Cvoid}, _module=C_NULL, mode::Integer=0, args=C_NULL)
	if (isa(args,String))	args = pointer(args)	end
	ccall((:GMT_Call_Module, thelib), Cint, (Cstring, Ptr{UInt8}, Cint, Ptr{Cvoid}), API, _module, mode, args)
end

function GMT_Create_Options(API::Ptr{Cvoid}, argc::Integer, args)
	# VERSATILIZAR PARA O CASO DE ARGS SER STRING OU ARRAY DE STRINGS
	#ccall((:GMT_Create_Options, thelib), Ptr{GMT_OPTION}, (Ptr{Cvoid}, Cint, Ptr{Cvoid}), API, argc, args)
	ccall((:GMT_Create_Options, thelib), Ptr{GMT_OPTION}, (Cstring, Cint, Cstring), API, argc, args)
end
#GMT_Create_Options(API::Ptr{Cvoid}, argc::Integer, args::String) = 
#                   GMT_Create_Options(API, argc, convert(Ptr{Cvoid},pointer(args)))

function GMT_Destroy_Options(API::Ptr{Cvoid}, head::Ref{Ptr{GMT_OPTION}})
	ccall( (:GMT_Destroy_Options, thelib), Cint, (Cstring, Ref{Ptr{GMT_OPTION}}), API, head)
end

#=
function GMT_Make_Option(API::Ptr{Cvoid}, option::UInt8, arg::Ptr{UInt8})
	ccall((:GMT_Make_Option, thelib), Ptr{GMT_OPTION}, (Ptr{Cvoid}, UInt8, Ptr{UInt8}), API, option, arg)
end

function GMT_Find_Option(API::Ptr{Cvoid}, option::UInt8, head::Ptr{GMT_OPTION})
	ccall((:GMT_Find_Option, thelib), Ptr{GMT_OPTION}, (Ptr{Cvoid}, UInt8, Ptr{GMT_OPTION}), API, option, head)
end

function GMT_Append_Option(API::Ptr{Cvoid}, current::Ptr{GMT_OPTION}, head::Ptr{GMT_OPTION})
	ccall((:GMT_Append_Option, thelib), Ptr{GMT_OPTION}, (Ptr{Cvoid}, Ptr{GMT_OPTION}, Ptr{GMT_OPTION}), API, current, head)
end
function GMT_Create_Args(API::Ptr{Cvoid}, argc::Ptr{Int}, head::Ptr{GMT_OPTION})
	ccall( (:GMT_Create_Args, thelib), Ptr{Ptr{UInt8}}, (Ptr{Cvoid}, Ptr{Cint}, Ptr{GMT_OPTION}), API, argc, head)
end
function GMT_Create_Cmd(API::Ptr{Cvoid}, head::Ptr{GMT_OPTION})
	ccall( (:GMT_Create_Cmd, thelib), Ptr{UInt8}, (Ptr{Cvoid}, Ptr{GMT_OPTION}), API, head)
end

function GMT_Destroy_Args(API::Ptr{Cvoid}, argc::Cint, argv::Ptr{Ptr{Ptr{UInt8}}})
	ccall( (:GMT_Destroy_Args, thelib), Cint, (Ptr{Cvoid}, Cint, Ptr{Ptr{Ptr{UInt8}}}), API, argc, argv)
end
function GMT_Destroy_Cmd(API::Ptr{Cvoid}, cmd::Ptr{Ptr{UInt8}})
	ccall( (:GMT_Destroy_Cmd, thelib), Cint, (Ptr{Cvoid}, Ptr{Ptr{UInt8}}), API, cmd)
end
function GMT_Update_Option(API::Ptr{Cvoid}, current::Ptr{GMT_OPTION}, arg::Ptr{UInt8})
	ccall( (:GMT_Update_Option, thelib), Cint, (Ptr{Cvoid}, Ptr{GMT_OPTION}, Ptr{UInt8}), API, current, arg)
end
function GMT_Delete_Option(API::Ptr{Cvoid}, current::Ptr{GMT_OPTION}, head::Ptr{Ptr{GMT_OPTION}})
	ccall( (:GMT_Delete_Option, thelib), Cint, (Ptr{Cvoid}, Ptr{GMT_OPTION}, Ptr{Ptr{GMT_OPTION}}), API, current, head)
end
function GMT_Parse_Common(API::Ptr{Cvoid}, given_options::Ptr{UInt8}, options::Ptr{GMT_OPTION})
	ccall( (:GMT_Parse_Common, thelib), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{GMT_OPTION}), API, given_options, options)
end

function GMT_FFT_Option(API::Ptr{Cvoid}, option::UInt8, dim::UInt32, string::Ptr{UInt8})
	ccall( (:GMT_FFT_Option, thelib), UInt32, (Ptr{Cvoid}, UInt8, UInt32, Ptr{UInt8}), API, option, dim, string)
end
function GMT_FFT_Parse(API::Ptr{Cvoid}, option::UInt8, dim::UInt32, args::Ptr{UInt8})
	ccall( (:GMT_FFT_Parse, thelib), Ptr{Cvoid}, (Ptr{Cvoid}, UInt8, UInt32, Ptr{UInt8}), API, option, dim, args)
end
function GMT_FFT_Create(API::Ptr{Cvoid}, X::Ptr{Cvoid}, dim::UInt32, mode::UInt32, F::Ptr{Cvoid})
	ccall( (:GMT_FFT_Create, thelib), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt32, UInt32, Ptr{Cvoid}), API, X, dim, mode, F)
end
function GMT_FFT_Wavenumber(API::Ptr{Cvoid}, k::UInt16, mode::UInt32, K::Ptr{Cvoid})
	ccall( (:GMT_FFT_Wavenumber, thelib), Cdouble, (Ptr{Cvoid}, UInt16, UInt32, Ptr{Cvoid}), API, k, mode, K)
end
function GMT_FFT(API::Ptr{Cvoid}, X::Ptr{Cvoid}, direction::Cint, mode::UInt32, K::Ptr{Cvoid})
	ccall( (:GMT_FFT, thelib), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Cint, UInt32, Ptr{Cvoid}), API, X, direction, mode, K)
end
function GMT_FFT_Destroy(API::Ptr{Cvoid}, K::Ptr{Cvoid})
	ccall( (:GMT_FFT_Destroy, thelib), Cint, (Ptr{Cvoid}, Ptr{Cvoid}), API, K)
end
function GMT_FFT_1D(API::Ptr{Cvoid}, data::Ptr{Cfloat}, n::UInt16, direction::Cint, mode::UInt32)
	ccall( (:GMT_FFT_1D, thelib), Cint, (Ptr{Cvoid}, Ptr{Cfloat}, UInt16, Cint, UInt32), API, data, n, direction, mode)
end
function GMT_FFT_2D(API::Ptr{Cvoid}, data::Ptr{Cfloat}, nx::UInt32, ny::UInt32, direction::Cint, mode::UInt32)
	ccall( (:GMT_FFT_2D, thelib), Cint, (Ptr{Cvoid}, Ptr{Cfloat}, UInt32, UInt32, Cint, UInt32), API, data, nx, ny, direction, mode)
end
=#

function GMT_Report(API, vlevel::Int, txt)
	ccall((:GMT_Report, thelib), Cvoid, (Cstring, Cint, Ptr{UInt8}), API, vlevel, txt)
end

function GMT_Encode_Options(V_API::Ptr{Cvoid}, _module, n_argin::Integer, head::Ref{Ptr{GMT_OPTION}}, n::Ptr{Int})
	ccall((:GMT_Encode_Options, thelib), Ptr{GMT_RESOURCE}, (Cstring, Ptr{UInt8}, Int32, Ref{Ptr{GMT_OPTION}},
					Ptr{UInt32}), V_API, _module, n_argin, head, n)
end
function GMT_Encode_Options(V_API::Ptr{Cvoid}, _module, n_argin::Integer, head, n::Ptr{Int})
	ccall((:GMT_Encode_Options, thelib), Ptr{GMT_RESOURCE}, (Cstring, Ptr{UInt8}, Int32, Ptr{Ptr{Cvoid}}, Ptr{UInt32}),
					V_API, _module, n_argin, head, n)
end

function GMT_Expand_Option(V_API::Ptr{Cvoid}, opt::Ptr{GMT_OPTION}, arg)
	ccall((:GMT_Expand_Option, thelib), Cint, (Cstring, Ptr{GMT_OPTION}, Ptr{UInt8}), V_API, opt, arg)
end

#=
function gmt_core_module_info(API, candidate)
	ccall((:gmt_core_module_info, thelib), Ptr{UInt8}, (Ptr{Cvoid}, Ptr{UInt8}), API, candidate)
end

function gmtlib_grd_flip_vertical(gridp, n_cols::Integer, n_rows::Integer, n_stride::Integer=0, cell_size::Integer=1)
	ccall((:gmtlib_grd_flip_vertical, thelib), Cvoid, (Ptr{Cvoid}, UInt32, UInt32, UInt32, Csize_t),
				 gridp, n_cols, n_rows, n_stride, cell_size)
end

function GMT_set_mem_layout(API, mem_layout)
	ccall((:GMT_set_mem_layout, thelib), Cvoid, (Ptr{Cvoid}, Ptr{UInt8}), API, mem_layout)
end
=#

function GMT_Set_Default(API::Ptr{Cvoid}, keyword, value)
	ccall((:GMT_Set_Default, thelib), Cvoid, (Cstring, Ptr{UInt8}, Ptr{UInt8}), API, keyword, value)
end

function GMT_blind_change_struct(API::Ptr{Cvoid}, X, what, keyword::String, off::Integer)
	ccall((:GMT_blind_change_struct, thelib), Cint, (Cstring, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{UInt8}, Csize_t),
				 API, X, what, keyword, off)
end

function GMT_Convert_Data(API::Ptr{Cvoid}, In::Ptr{Cvoid}, family_in::Integer, out::Ptr{Cvoid}, family_out::Integer, flag)
	ccall((:GMT_Convert_Data, thelib), Ptr{Cvoid}, (Cstring, Ptr{Cvoid}, UInt32, Ptr{Cvoid}, UInt32, Ptr{UInt32}), API, In,
				 family_in, out, family_out, flag)
end

#=
function GMT_blind_change_struct_(API::Ptr{Cvoid}, X, what, keyword::String)
	ccall((:GMT_blind_change_struct_, thelib), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{UInt8}),
				 API, X, what, keyword)
end

function GMT_Read_Group(API::Ptr{Cvoid}, family::Integer, method::Integer, geometry::Integer, mode::Integer,
												wesn, sources::Ptr{Cvoid}, n_items::Ptr{UInt32}, data::Ptr{Cvoid})
	ccall((:GMT_Read_Group, thelib), Ptr{Cvoid}, (Ptr{Cvoid}, UInt32, UInt32, UInt32, UInt32, Ptr{Cdouble},
				 Ptr{Cvoid}, Ptr{UInt32}, Ptr{Cvoid}), API, family, method, geometry, mode, wesn, sources, n_items, data)
end

function GMT_Get_Index(API::Ptr{Cvoid}, header::Ptr{GMT_GRID_HEADER}, row::Integer, col::Integer)
	ccall((:GMT_Get_Index, thelib), UInt64, (Ptr{Cvoid}, Ptr{GMT_GRID_HEADER}, Cint, Cint), API, header, row, col)
end

function GMT_Get_Pixel(API::Ptr{Cvoid}, header::Ptr{GMT_GRID_HEADER}, row::Integer, col::Integer, layer::Integer)
	ccall((:GMT_Get_Pixel, thelib), UInt64, (Ptr{Cvoid}, Ptr{GMT_GRID_HEADER}, Cint, Cint, Cint), API, header, row, col, layer)
end

function GMT_Set_Index(API::Ptr{Cvoid}, header::Ptr{GMT_GRID_HEADER}, code)
	ccall((:GMT_Set_Index, thelib), Cint, (Ptr{Cvoid}, Ptr{GMT_GRID_HEADER}, Ptr{UInt8}), API, header, code)
end
=#

function GMT_Alloc_Segment(API::Ptr{Cvoid}, family::Integer, n_rows::Integer, n_columns::Integer, header, S::Ptr{Cvoid})
	if (family == GMT_IS_DATASET || family == GMT_WITH_STRINGS)
		ret_type = Ptr{GMT_DATASEGMENT}
	elseif (family == GMT_IS_TEXTSET)
		ret_type = Ptr{GMT_TEXTSEGMENT}
	else
		error("Bad family type")
	end

	ptr = ccall((:GMT_Alloc_Segment, thelib), Ptr{Cvoid}, (Cstring, UInt32, UInt64, UInt64, Ptr{UInt8}, Ptr{Cvoid}),
							 API, family, n_rows, n_columns, header, S)

	convert(ret_type, ptr)
end

#=
function GMT_Set_Columns(API::Ptr{Cvoid}, n_columns::Integer, mode)
	ccall((:GMT_Set_Columns, thelib), Cint, (Ptr{Cvoid}, UInt32, UInt32), API, n_columns, mode)
end

function GMT_Destroy_Group(API::Ptr{Cvoid}, obj::Ptr{Cvoid}, n_items::Integer)
	ccall((:GMT_Destroy_Group, thelib), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Cuint), API, obj, n_items)
end

function GMT_Change_Layout(API::Ptr{Cvoid}, family::Integer, code, mode::Integer, obj::Ptr{Cvoid}, data::Ptr{Cvoid}=C_NULL, alpha::Ptr{Cvoid}=C_NULL)
	ccall((:GMT_Change_Layout, thelib), Cint, (Ptr{Cvoid}, Cuint, Ptr{UInt8}, Cuint, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
	      API, family, code, mode, obj, data, alpha)
end
=#

function GMT_Duplicate_String(API::Ptr{Cvoid}, str)
	ccall((:GMT_Duplicate_String, thelib), Ptr{UInt8}, (Cstring, Ptr{UInt8}), API, str)
end

function GMT_Open_VirtualFile(API::Ptr{Cvoid}, family::Integer, geometry::Integer, dir::Integer, data, name)
	ccall((:GMT_Open_VirtualFile, thelib), Cint, (Cstring, UInt32, UInt32, UInt32, Ptr{Cvoid}, Ptr{UInt8}), API, family, geometry, dir, data, name)
end
function GMT_Close_VirtualFile(API::Ptr{Cvoid}, str)
	ccall((:GMT_Close_VirtualFile, thelib), Cint, (Cstring, Ptr{UInt8}), API, str)
end

function GMT_Read_VirtualFile(API::Ptr{Cvoid}, str)
	ccall((:GMT_Read_VirtualFile, thelib), Ptr{Cvoid}, (Cstring, Ptr{UInt8}), API, str)
end

#=
function GMT_Init_VirtualFile(API::Ptr{Cvoid}, mode::Integer, name)
	ccall((:GMT_Init_VirtualFile, thelib), Ptr{Cvoid}, (Ptr{Cvoid}, UInt32, Ptr{UInt8}), API, mode, name)
end

function GMT_Put_Vector(API::Ptr{Cvoid}, V::GMT_VECTOR, col::Integer, tipo::Integer, vector)
	ccall((:GMT_Put_Vector, thelib), Cint, (Ptr{Cvoid}, GMT_VECTOR, UInt32, UInt32, Ptr{Cvoid}), API, V, col, tipo, vector)
end
function GMT_Get_Vector(API::Ptr{Cvoid}, V::Ptr{GMT_VECTOR}, col::Integer)
	ccall((:GMT_Get_Vector, thelib), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{GMT_VECTOR}, UInt32), API, V, col)
end

function GMT_Put_Matrix(API::Ptr{Cvoid}, M::GMT_MATRIX, tipo::Integer, matrix)
	ccall((:GMT_Put_Matrix, thelib), Cint, (Ptr{Cvoid}, GMT_MATRIX, UInt32, Ptr{Cvoid}), API, M, tipo, matrix)
end
function GMT_Get_Matrix(API::Ptr{Cvoid}, M::Ptr{GMT_MATRIX})
	ccall((:GMT_Get_Matrix, thelib), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{GMT_MATRIX}), API, M)
end

function GMT_Error_Message(API::Ptr{Cvoid})
	ccall((:GMT_Error_Message, thelib), Ptr{UInt8}, (Ptr{Cvoid},), API)
end
=#

# ------------------ Development function in 5.4.0 ------------------------------------------------------------

# -------------------------------------------------------------------------------------------------------------
function GMT_Set_AllocMode(API::Ptr{Cvoid}, family::Integer, object)
	ccall((:GMT_Set_AllocMode, thelib), Cint, (Cstring, UInt32, Ptr{Cvoid}), API, family, object)
end

function gmt_manage_workflow(API::Ptr{Cvoid}, mode::Integer, texto)
	ccall((:gmt_manage_workflow, thelib), Cint, (Cstring, UInt32, Cstring), API, mode, texto)
end

function GMT_Get_Version()
	ver = ccall((:GMT_Get_Version, thelib), Cfloat, (Ptr{Cvoid}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), C_NULL, C_NULL, C_NULL, C_NULL)
end
function GMT_Get_Version(major, minor, patch)
	ver = ccall((:GMT_Get_Version, thelib), Cfloat, (Ptr{Cvoid}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), C_NULL, major, minor, patch)
end

function GMT_Get_Ctrl(API::Ptr{Cvoid})
	ccall((:GMT_Get_Ctrl, thelib), Ptr{Cvoid}, (Cstring,), API)
end

function gmt_getpen(API::Ptr{Cvoid}, buffer, P)
	GMT_ = GMT_Get_Ctrl(API)
	ccall((:gmt_getpen, thelib), Cint, (Cstring, Ptr{Cuint}, Ref{GMT_PEN}), GMT_, buffer, P)
end

function gmt_ogrread(API::Ptr{Cvoid}, fname::String)
	GMT_ = GMT_Get_Ctrl(API)
	ccall((:gmt_ogrread, thelib), Ptr{OGR_FEATURES}, (Cstring, Ptr{UInt8}), GMT_, fname)
end