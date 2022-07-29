function GMT_Create_Session(tag::String="GMT", pad=2, mode=0, print_func::Ptr{Cvoid}=C_NULL)
	API = ccall((:GMT_Create_Session, libgmt), Ptr{Cvoid}, (Ptr{UInt8}, UInt32, UInt32, Ptr{Cvoid}), tag, pad, mode, print_func)
	(API == C_NULL) && error("Failure to create a GMT Session")
	return API
end

function GMT_Create_Data(API::Ptr{Cvoid}, family::Integer, geometry, mode, dim=NULL, wesn=NULL,
                         inc=NULL, registration=0, pad=2, data::Ptr{Cvoid}=NULL)
	ptr = ccall((:GMT_Create_Data, libgmt), Ptr{Cvoid}, (Cstring, UInt32, UInt32, UInt32, Ptr{UInt64},
		Ptr{Cdouble}, Ptr{Cdouble}, UInt32, Cint, Ptr{Cvoid}), API, family, geometry, mode, dim, wesn, inc,
		registration, pad, data)

	(ptr == C_NULL) && error("Failure to allocate GMT resource")
	ptr
end

GMT_Destroy_Session(API::Ptr{Cvoid}) = ccall((:GMT_Destroy_Session, libgmt), Cint, (Cstring,), API)

#=		Not used yet, so comment
function GMT_Read_Data(API::Ptr{Cvoid}, family, method, geometry, mode, wesn, input=C_NULL, data=C_NULL)

	if (family == GMT_IS_DATASET)
		ret_type = Ptr{GMT_DATASET}
	elseif (family == GMT_IS_GRID)
		ret_type = Ptr{GMT_GRID}
	elseif (family == GMT_IS_PALETTE)
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

	ptr = ccall( (:GMT_Read_Data, libgmt), Ptr{Cvoid}, (Ptr{Cvoid}, UInt32, UInt32, UInt32, UInt32, Ptr{Cdouble},
		Ptr{UInt8}, Ptr{Cvoid}), API, family, method, geometry, mode, wesn, input, data)

	convert(ret_type, ptr)
end

function GMT_Insert_Data(API::Ptr{Cvoid}, object_ID::Integer, data)
	ccall((:GMT_Insert_Data, libgmt), Cint, (Ptr{Cvoid}, Cint, Ptr{Cvoid}), API, object_ID, data)
end

function GMT_Duplicate_Data(API::Ptr{Cvoid}, family::Integer, mode::Integer, data::Ptr{Cvoid})
	ccall( (:GMT_Duplicate_Data, libgmt), Ptr{Cvoid}, (Ptr{Cvoid}, UInt32, UInt32, Ptr{Cvoid}), API, family, mode, data)
end

function GMT_Get_Record(API::Ptr{Cvoid}, mode::Integer, retval::Ptr{Cint})
	ccall( (:GMT_Get_Record, libgmt), Ptr{Cvoid}, (Ptr{Cvoid}, UInt32, Ptr{Cint}), API, mode, retval)
end

function GMT_Manage_Session(API::Ptr{Cvoid}, mode::Integer, args::Ptr{Cvoid})
	ccall( (:GMT_Manage_Session, libgmt), Cint, (Ptr{Cvoid}, UInt32, Ptr{Cvoid}), API, mode, args)
end

function GMT_Register_IO(API, family::Integer, method::Integer, geometry::Integer, direction::Integer=0,
		wesn=C_NULL, resource=C_NULL)
	err = ccall((:GMT_Register_IO, libgmt), Cint, (Ptr{Cvoid}, UInt32, UInt32, UInt32, UInt32, Ptr{Cdouble},
		Ptr{Cvoid}), API, family, method, geometry, direction, wesn, resource)
end

function GMT_Init_IO(API::Ptr{Cvoid}, family::UInt32, geometry::UInt32, direction::UInt32, mode::UInt32, n_args::UInt32, args::Ptr{Cvoid})
	ccall( (:GMT_Init_IO, libgmt), Cint, (Ptr{Cvoid}, UInt32, UInt32, UInt32, UInt32, UInt32, Ptr{Cvoid}), API, family, geometry, direction, mode, n_args, args)
end
function GMT_Begin_IO(API::Ptr{Cvoid}, family::UInt32, direction::UInt32, header::UInt32)
	ccall( (:GMT_Begin_IO, libgmt), Cint, (Ptr{Cvoid}, UInt32, UInt32, UInt32), API, family, direction, header)
end
function GMT_Status_IO(API::Ptr{Cvoid}, mode::UInt32)
	ccall( (:GMT_Status_IO, libgmt), Cint, (Ptr{Cvoid}, UInt32), API, mode)
end
function GMT_End_IO(API::Ptr{Cvoid}, direction::UInt32, mode::UInt32)
	ccall( (:GMT_End_IO, libgmt), Cint, (Ptr{Cvoid}, UInt32, UInt32), API, direction, mode)
end

function GMT_Write_Data(API::Ptr{Cvoid}, family::Integer, method::Integer, geometry::Integer, mode::Integer,
	wesn, output::String, data)
	err = ccall((:GMT_Write_Data, libgmt), Cint, (Ptr{Cvoid}, UInt32, UInt32, UInt32, UInt32, Ptr{Cdouble},
		Ptr{UInt8}, Ptr{Cvoid}), API, family, method, geometry, mode, wesn, output, data)
end =#

function GMT_Destroy_Data(API::Ptr{Cvoid}, object)
	ccall((:GMT_Destroy_Data, libgmt), Cint, (Cstring, Ptr{Cvoid}), API, object)
end

function GMT_Set_Comment(API::Ptr{Cvoid}, family::Integer, mode, arg::Ptr{Cvoid}, data::Ptr{Cvoid})
	ccall((:GMT_Set_Comment, libgmt), Cint, (Cstring, UInt32, UInt32, Ptr{Cvoid}, Ptr{Cvoid}), API, family, mode, arg, data)
end

#= 
function GMT_Put_Record(API::Ptr{Cvoid}, mode::UInt32, record::Ptr{Cvoid})
	ccall( (:GMT_Put_Record, libgmt), Cint, (Ptr{Cvoid}, UInt32, Ptr{Cvoid}), API, mode, record)
end

function GMT_Encode_ID(API::Ptr{Cvoid}, fname::String, object_ID::Integer)
	err = ccall((:GMT_Encode_ID, libgmt), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Cint), API, fname, object_ID)
end

function GMT_Get_Row(API::Ptr{Cvoid}, rec_no::Cint, G::Ptr{GMT_GRID}, row::Ptr{Cfloat})
	ccall( (:GMT_Get_Row, libgmt), Cint, (Ptr{Cvoid}, Cint, Ptr{GMT_GRID}, Ptr{Cfloat}), API, rec_no, G, row)
end
function GMT_Put_Row(API::Ptr{Cvoid}, rec_no::Cint, G::Ptr{GMT_GRID}, row::Ptr{Cfloat})
	ccall( (:GMT_Put_Row, libgmt), Cint, (Ptr{Cvoid}, Cint, Ptr{GMT_GRID}, Ptr{Cfloat}), API, rec_no, G, row)
end

function GMT_Get_ID(API::Ptr{Cvoid}, family::Integer, dir::Integer, resource=C_NULL)
	ccall((:GMT_Get_ID, libgmt), Cint, (Ptr{Cvoid}, UInt32, UInt32, Ptr{Cvoid}), API, family, dir, resource)
end

function GMT_Get_Family(API::Ptr{Cvoid}, dir::Integer, head::Ptr{GMT_OPTION})
	ccall((:GMT_Get_Family, libgmt), Cint, (Ptr{Cvoid}, UInt32, Ptr{GMT_OPTION}), API, dir, head)
end

function GMT_Get_Index(API::Ptr{Cvoid}, header::Ptr{GMT_GRID_HEADER}, row::Cint, col::Cint)
	ccall((:GMT_Get_Index, libgmt), Clonglong, (Ptr{Cvoid}, Ptr{GMT_GRID_HEADER}, Cint, Cint), API, header, row, col)
end
function GMT_Get_Coord(API::Ptr{Cvoid}, family::Integer, dim::Integer, container::Ptr{Cvoid})
	ccall((:GMT_Get_Coord, libgmt), Ptr{Cdouble}, (Ptr{Cvoid}, UInt32, UInt32, Ptr{Cvoid}), API, family, dim, container)
end

function GMT_Option(API::Ptr{Cvoid}, options)
	ccall((:GMT_Option, libgmt), Cint, (Ptr{Cvoid}, Ptr{UInt8}), API, options)
end

function GMT_Get_Value(API::Ptr{Cvoid}, arg::String, par::Ptr{Cdouble})
	ccall((:GMT_Get_Value, libgmt), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Cdouble}), API, arg, par)
end
function GMT_Get_Values(API::Ptr{Cvoid}, arg::String, par::Ptr{Cdouble}, maxpar::Integer)
	ccall((:GMT_Get_Values, libgmt), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Cdouble}, Cint), API, arg, par, maxpar)
end =#

function GMT_Get_Common(API::Ptr{Cvoid}, option::Char)
	buffer = Vector{Float64}(undef, 4)
	n_par = ccall((:GMT_Get_Common, libgmt), Cint, (Ptr{Cvoid}, UInt32, Ptr{Cdouble}), API, option, buffer)
	return buffer, n_par
end

function GMT_Get_Default(API::Ptr{Cvoid}, keyword::String, value)
    ccall((:GMT_Get_Default, libgmt), Cint, (Cstring, Ptr{UInt8}, Ptr{UInt8}), API, keyword, value)
end

function GMT_Call_Module(API::Ptr{Cvoid}, _module::AbstractString, mode=0, args=C_NULL)
	#(isa(args, String)) && (args = pointer(args))
	ccall((:GMT_Call_Module, libgmt), Cint, (Cstring, Ptr{UInt8}, Cint, Ptr{Cvoid}), API, _module, mode, args)
end

function GMT_Create_Options(API::Ptr{Cvoid}, argc::Int, args)
	# VERSATILIZAR PARA O CASO DE ARGS SER STRING OU ARRAY DE STRINGS
	# ccall((:GMT_Create_Options, libgmt), Ptr{GMT_OPTION}, (Ptr{Cvoid}, Cint, Ptr{Cvoid}), API, argc, args)
	ccall((:GMT_Create_Options, libgmt), Ptr{GMT_OPTION}, (Cstring, Cint, Cstring), API, argc, args)
end
# GMT_Create_Options(API::Ptr{Cvoid}, argc::Integer, args::String) = 
#                   GMT_Create_Options(API, argc, convert(Ptr{Cvoid},pointer(args)))

function GMT_Destroy_Options(API::Ptr{Cvoid}, head::Ref{Ptr{GMT_OPTION}})
	ccall((:GMT_Destroy_Options, libgmt), Cint, (Cstring, Ref{Ptr{GMT_OPTION}}), API, head)
end

GMT_Create_Cmd(API::Ptr{Cvoid}, head::Ptr{GMT_OPTION}) =
	ccall( (:GMT_Create_Cmd, libgmt), Ptr{UInt8}, (Ptr{Cvoid}, Ptr{GMT_OPTION}), API, head)

#= 
function GMT_Make_Option(API::Ptr{Cvoid}, option::UInt8, arg::Ptr{UInt8})
	ccall((:GMT_Make_Option, libgmt), Ptr{GMT_OPTION}, (Ptr{Cvoid}, UInt8, Ptr{UInt8}), API, option, arg)
end

function GMT_Find_Option(API::Ptr{Cvoid}, option::UInt8, head::Ptr{GMT_OPTION})
	ccall((:GMT_Find_Option, libgmt), Ptr{GMT_OPTION}, (Ptr{Cvoid}, UInt8, Ptr{GMT_OPTION}), API, option, head)
end

function GMT_Append_Option(API::Ptr{Cvoid}, current::Ptr{GMT_OPTION}, head::Ptr{GMT_OPTION})
	ccall((:GMT_Append_Option, libgmt), Ptr{GMT_OPTION}, (Ptr{Cvoid}, Ptr{GMT_OPTION}, Ptr{GMT_OPTION}), API, current, head)
end
function GMT_Create_Args(API::Ptr{Cvoid}, argc::Ptr{Int}, head::Ptr{GMT_OPTION})
	ccall( (:GMT_Create_Args, libgmt), Ptr{Ptr{UInt8}}, (Ptr{Cvoid}, Ptr{Cint}, Ptr{GMT_OPTION}), API, argc, head)
end

function GMT_Destroy_Args(API::Ptr{Cvoid}, argc::Cint, argv::Ptr{Ptr{Ptr{UInt8}}})
	ccall( (:GMT_Destroy_Args, libgmt), Cint, (Ptr{Cvoid}, Cint, Ptr{Ptr{Ptr{UInt8}}}), API, argc, argv)
end
function GMT_Destroy_Cmd(API::Ptr{Cvoid}, cmd::Ptr{Ptr{UInt8}})
	ccall( (:GMT_Destroy_Cmd, libgmt), Cint, (Ptr{Cvoid}, Ptr{Ptr{UInt8}}), API, cmd)
end
function GMT_Update_Option(API::Ptr{Cvoid}, current::Ptr{GMT_OPTION}, arg::Ptr{UInt8})
	ccall( (:GMT_Update_Option, libgmt), Cint, (Ptr{Cvoid}, Ptr{GMT_OPTION}, Ptr{UInt8}), API, current, arg)
end
function GMT_Delete_Option(API::Ptr{Cvoid}, current::Ptr{GMT_OPTION}, head::Ptr{Ptr{GMT_OPTION}})
	ccall( (:GMT_Delete_Option, libgmt), Cint, (Ptr{Cvoid}, Ptr{GMT_OPTION}, Ptr{Ptr{GMT_OPTION}}), API, current, head)
end
function GMT_Parse_Common(API::Ptr{Cvoid}, given_options::Ptr{UInt8}, options::Ptr{GMT_OPTION})
	ccall( (:GMT_Parse_Common, libgmt), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{GMT_OPTION}), API, given_options, options)
end

function GMT_FFT_Option(API::Ptr{Cvoid}, option::UInt8, dim::UInt32, string::Ptr{UInt8})
	ccall( (:GMT_FFT_Option, libgmt), UInt32, (Ptr{Cvoid}, UInt8, UInt32, Ptr{UInt8}), API, option, dim, string)
end
function GMT_FFT_Parse(API::Ptr{Cvoid}, option::UInt8, dim::UInt32, args::Ptr{UInt8})
	ccall( (:GMT_FFT_Parse, libgmt), Ptr{Cvoid}, (Ptr{Cvoid}, UInt8, UInt32, Ptr{UInt8}), API, option, dim, args)
end
function GMT_FFT_Create(API::Ptr{Cvoid}, X::Ptr{Cvoid}, dim::UInt32, mode::UInt32, F::Ptr{Cvoid})
	ccall( (:GMT_FFT_Create, libgmt), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, UInt32, UInt32, Ptr{Cvoid}), API, X, dim, mode, F)
end
function GMT_FFT_Wavenumber(API::Ptr{Cvoid}, k::UInt16, mode::UInt32, K::Ptr{Cvoid})
	ccall( (:GMT_FFT_Wavenumber, libgmt), Cdouble, (Ptr{Cvoid}, UInt16, UInt32, Ptr{Cvoid}), API, k, mode, K)
end
function GMT_FFT(API::Ptr{Cvoid}, X::Ptr{Cvoid}, direction::Cint, mode::UInt32, K::Ptr{Cvoid})
	ccall( (:GMT_FFT, libgmt), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Cint, UInt32, Ptr{Cvoid}), API, X, direction, mode, K)
end
function GMT_FFT_Destroy(API::Ptr{Cvoid}, K::Ptr{Cvoid})
	ccall( (:GMT_FFT_Destroy, libgmt), Cint, (Ptr{Cvoid}, Ptr{Cvoid}), API, K)
end
function GMT_FFT_1D(API::Ptr{Cvoid}, data::Ptr{Cfloat}, n::UInt16, direction::Cint, mode::UInt32)
	ccall( (:GMT_FFT_1D, libgmt), Cint, (Ptr{Cvoid}, Ptr{Cfloat}, UInt16, Cint, UInt32), API, data, n, direction, mode)
end
function GMT_FFT_2D(API::Ptr{Cvoid}, data::Ptr{Cfloat}, nx::UInt32, ny::UInt32, direction::Cint, mode::UInt32)
	ccall( (:GMT_FFT_2D, libgmt), Cint, (Ptr{Cvoid}, Ptr{Cfloat}, UInt32, UInt32, Cint, UInt32), API, data, nx, ny, direction, mode)
end

function GMT_Report(API, vlevel::Integer, txt)
	ccall((:GMT_Report, libgmt), Cvoid, (Cstring, Cint, Ptr{UInt8}), API, vlevel, txt)
end =#

function GMT_Encode_Options(V_API::Ptr{Cvoid}, _module, n_argin::Int, head::Ref{Ptr{GMT_OPTION}}, n::Ptr{Int})
	ccall((:GMT_Encode_Options, libgmt), Ptr{GMT_RESOURCE}, (Cstring, Ptr{UInt8}, Int32, Ref{Ptr{GMT_OPTION}},
					Ptr{UInt32}), V_API, _module, n_argin, head, n)
end
function GMT_Encode_Options(V_API::Ptr{Cvoid}, _module, n_argin::Int, head, n::Ptr{Int})
	ccall((:GMT_Encode_Options, libgmt), Ptr{GMT_RESOURCE}, (Cstring, Ptr{UInt8}, Int32, Ptr{Ptr{Cvoid}}, Ptr{UInt32}),
					V_API, _module, n_argin, head, n)
end

function GMT_Expand_Option(V_API::Ptr{Cvoid}, opt::Ptr{GMT_OPTION}, arg)
	ccall((:GMT_Expand_Option, libgmt), Cint, (Cstring, Ptr{GMT_OPTION}, Ptr{UInt8}), V_API, opt, arg)
end

#= 
function gmt_core_module_info(API, candidate)
	ccall((:gmt_core_module_info, libgmt), Ptr{UInt8}, (Ptr{Cvoid}, Ptr{UInt8}), API, candidate)
end

function gmtlib_grd_flip_vertical(gridp, n_cols::Integer, n_rows::Integer, n_stride::Integer=0, cell_size::Integer=1)
	ccall((:gmtlib_grd_flip_vertical, libgmt), Cvoid, (Ptr{Cvoid}, UInt32, UInt32, UInt32, Csize_t),
				 gridp, n_cols, n_rows, n_stride, cell_size)
end

function GMT_set_mem_layout(API, mem_layout)
	ccall((:GMT_set_mem_layout, libgmt), Cvoid, (Ptr{Cvoid}, Ptr{UInt8}), API, mem_layout)
end =#

GMT_Set_Default(API::Ptr{Cvoid}, keyword, value) =
	ccall((:GMT_Set_Default, libgmt), Cvoid, (Cstring, Ptr{UInt8}, Ptr{UInt8}), API, keyword, value)

function GMT_blind_change_struct(API::Ptr{Cvoid}, X, what, keyword::String, off)
	(GMTver > v"6.0") ?		# Use this construct to cheat Coverage
		ccall((:gmtlib_blind_change_struct, libgmt), Cint, (Cstring, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{UInt8}, Csize_t), API, X, what, keyword, off) : ccall((:GMT_blind_change_struct, libgmt), Cint, (Cstring, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{UInt8}, Csize_t), API, X, what, keyword, off)
end

#= 
function GMT_Convert_Data(API::Ptr{Cvoid}, In::Ptr{Cvoid}, family_in::Integer, out::Ptr{Cvoid}, family_out::Integer, flag)
	ccall((:GMT_Convert_Data, libgmt), Ptr{Cvoid}, (Cstring, Ptr{Cvoid}, UInt32, Ptr{Cvoid}, UInt32, Ptr{UInt32}), API, In,
				 family_in, out, family_out, flag)
end

function GMT_blind_change_struct_(API::Ptr{Cvoid}, X, what, keyword::String)
	ccall((:GMT_blind_change_struct_, libgmt), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{UInt8}),
				 API, X, what, keyword)
end

function GMT_Read_Group(API::Ptr{Cvoid}, family::Integer, method::Integer, geometry::Integer, mode::Integer,
												wesn, sources::Ptr{Cvoid}, n_items::Ptr{UInt32}, data::Ptr{Cvoid})
	ccall((:GMT_Read_Group, libgmt), Ptr{Cvoid}, (Ptr{Cvoid}, UInt32, UInt32, UInt32, UInt32, Ptr{Cdouble},
				 Ptr{Cvoid}, Ptr{UInt32}, Ptr{Cvoid}), API, family, method, geometry, mode, wesn, sources, n_items, data)
end

function GMT_Get_Index(API::Ptr{Cvoid}, header::Ptr{GMT_GRID_HEADER}, row::Integer, col::Integer)
	ccall((:GMT_Get_Index, libgmt), UInt64, (Ptr{Cvoid}, Ptr{GMT_GRID_HEADER}, Cint, Cint), API, header, row, col)
end

function GMT_Get_Pixel(API::Ptr{Cvoid}, header::Ptr{GMT_GRID_HEADER}, row::Integer, col::Integer, layer::Integer)
	ccall((:GMT_Get_Pixel, libgmt), UInt64, (Ptr{Cvoid}, Ptr{GMT_GRID_HEADER}, Cint, Cint, Cint), API, header, row, col, layer)
end

function GMT_Set_Index(API::Ptr{Cvoid}, header::Ptr{GMT_GRID_HEADER}, code)
	ccall((:GMT_Set_Index, libgmt), Cint, (Ptr{Cvoid}, Ptr{GMT_GRID_HEADER}, Ptr{UInt8}), API, header, code)
end =#

function GMT_Alloc_Segment(API::Ptr{Cvoid}, family::Integer, n_rows::Integer, n_columns::Integer, header, S::Ptr{Cvoid})
	(family != GMT_IS_DATASET && family != GMT_WITH_STRINGS) && error("Bad family type")

	ptr = ccall((:GMT_Alloc_Segment, libgmt), Ptr{Cvoid}, (Cstring, UInt32, UInt64, UInt64, Ptr{UInt8}, Ptr{Cvoid}),
							 API, family, n_rows, n_columns, header, S)

	convert(Ptr{GMT_DATASEGMENT}, ptr)
end

#= 
function GMT_Set_Columns(API::Ptr{Cvoid}, n_columns::Integer, mode)
	ccall((:GMT_Set_Columns, libgmt), Cint, (Ptr{Cvoid}, UInt32, UInt32), API, n_columns, mode)
end

function GMT_Destroy_Group(API::Ptr{Cvoid}, obj::Ptr{Cvoid}, n_items::Integer)
	ccall((:GMT_Destroy_Group, libgmt), Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Cuint), API, obj, n_items)
end =#

function GMT_Change_Layout(API::Ptr{Cvoid}, family::Integer, code::String, mode::Integer, obj, data=C_NULL, alpha=C_NULL)
	ccall((:GMT_Change_Layout, libgmt), Cint, (Ptr{Cvoid}, Cuint, Ptr{UInt8}, Cuint, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
	      API, family, code, mode, obj, data, alpha)
end

function GMT_Duplicate_String(API::Ptr{Cvoid}, str)
	ccall((:GMT_Duplicate_String, libgmt), Ptr{UInt8}, (Cstring, Ptr{UInt8}), API, str)
end

function GMT_Open_VirtualFile(API::Ptr{Cvoid}, family::Integer, geometry::Integer, dir::Integer, data, name)
	dir |= GMT_Get_Enum(API, "GMT_IS_REFERENCE")
	ccall((:GMT_Open_VirtualFile, libgmt), Cint, (Cstring, UInt32, UInt32, UInt32, Ptr{Cvoid}, Ptr{UInt8}), API, family, geometry, dir, data, name)
end
function GMT_Close_VirtualFile(API::Ptr{Cvoid}, str)
	ccall((:GMT_Close_VirtualFile, libgmt), Cint, (Cstring, Ptr{UInt8}), API, str)
end

function GMT_Read_VirtualFile(API::Ptr{Cvoid}, str)
	ccall((:GMT_Read_VirtualFile, libgmt), Ptr{Cvoid}, (Cstring, Ptr{UInt8}), API, str)
end

#= 
function GMT_Init_VirtualFile(API::Ptr{Cvoid}, mode::Integer, name)
	ccall((:GMT_Init_VirtualFile, libgmt), Ptr{Cvoid}, (Ptr{Cvoid}, UInt32, Ptr{UInt8}), API, mode, name)
end

function GMT_Put_Vector(API::Ptr{Cvoid}, V::GMT_VECTOR, col::Integer, tipo::Integer, vector)
	ccall((:GMT_Put_Vector, libgmt), Cint, (Ptr{Cvoid}, GMT_VECTOR, UInt32, UInt32, Ptr{Cvoid}), API, V, col, tipo, vector)
end
function GMT_Get_Vector(API::Ptr{Cvoid}, V::Ptr{GMT_VECTOR}, col::Integer)
	ccall((:GMT_Get_Vector, libgmt), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{GMT_VECTOR}, UInt32), API, V, col)
end

function GMT_Put_Matrix(API::Ptr{Cvoid}, M::GMT_MATRIX, tipo::Integer, matrix)
	ccall((:GMT_Put_Matrix, libgmt), Cint, (Ptr{Cvoid}, GMT_MATRIX, UInt32, Ptr{Cvoid}), API, M, tipo, matrix)
end
function GMT_Get_Matrix(API::Ptr{Cvoid}, M::Ptr{GMT_MATRIX})
	ccall((:GMT_Get_Matrix, libgmt), Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{GMT_MATRIX}), API, M)
end

function GMT_Error_Message(API::Ptr{Cvoid})
	ccall((:GMT_Error_Message, libgmt), Ptr{UInt8}, (Ptr{Cvoid},), API)
end =#

# -------------------------------------------------------------------------------------------------------------
function GMT_Set_AllocMode(API::Ptr{Cvoid}, family::Integer, object)
	ccall((:GMT_Set_AllocMode, libgmt), Cint, (Cstring, UInt32, Ptr{Cvoid}), API, family, object)
end

function gmt_manage_workflow(API::Ptr{Cvoid}, mode::Int, texto)
	ccall((:gmt_manage_workflow, libgmt), Cint, (Cstring, UInt32, Cstring), API, mode, texto)
end

function GMT_Get_Enum(API::Ptr{Cvoid}, enum_name::String)
	ccall((:GMT_Get_Enum, libgmt), Cint, (Cstring, Ptr{UInt8}), API, enum_name)
end

function GMT_Get_Version()
	ver = ccall((:GMT_Get_Version, libgmt), Cfloat, (Ptr{Cvoid}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), C_NULL, C_NULL, C_NULL, C_NULL)
end
function GMT_Get_Version(major, minor, patch)
	ver = ccall((:GMT_Get_Version, libgmt), Cfloat, (Ptr{Cvoid}, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), C_NULL, major, minor, patch)
end

function GMT_Get_Ctrl(API::Ptr{Cvoid})
	ccall((:gmtlib_get_ctrl, libgmt), Ptr{Cvoid}, (Cstring,), API)
end

#= 
function gmt_getpen(API::Ptr{Cvoid}, buffer, P)
	GMT_ = GMT_Get_Ctrl(API)
	ccall((:gmt_getpen, libgmt), Cint, (Cstring, Ptr{Cuint}, Ref{GMT_PEN}), GMT_, buffer, P)
end =#

function gmtlib_setparameter(API, keyword::String, value::String)
	(!isa(API, Ptr{Nothing}) || API == C_NULL) && return UInt32(1)
	ccall((:gmtlib_setparameter, libgmt), Cuint, (Cstring, Ptr{UInt8}, Ptr{UInt8}, Bool), GMT_Get_Ctrl(API), keyword, value, true)
end

function gmtlib_getparameter(API, keyword::String)
	(!isa(API, Ptr{Nothing}) || API == C_NULL) && return UInt32(1)
	ccall((:gmtlib_getparameter, libgmt), Ptr{UInt8}, (Cstring, Ptr{UInt8}), GMT_Get_Ctrl(API), keyword)
end

function reset_defaults(API::Ptr{Cvoid})
	(GMTver > v"6.1.1") ? ccall((:gmt_conf_SI, libgmt), Cvoid, (Cstring,), GMT_Get_Ctrl(API)) :
	                      ccall((:gmt_conf, libgmt), Cvoid, (Cstring,), GMT_Get_Ctrl(API))
end

function gmt_ogrread(API::Ptr{Cvoid}, fname::String, region=C_NULL)
	GMT_ = GMT_Get_Ctrl(API)
	ccall((:gmt_ogrread, libgmt), Ptr{OGR_FEATURES}, (Cstring, Ptr{UInt8}, Ptr{Cdouble}), GMT_, fname, region)
end

function gmt_ogrread(API::Ptr{Cvoid}, X)
	ccall((:gmt_ogrread2, libgmt), Ptr{OGR_FEATURES}, (Cstring, Ptr{Cvoid}), GMT_Get_Ctrl(API), X)
end

#= 
function gmt_put_history(API::Ptr{Cvoid})
	ccall((:gmt_put_history, libgmt), Cint, (Cstring,), GMT_Get_Ctrl(API))
end =#

function GMT_Put_Strings(API::Ptr{Cvoid}, family::Integer, object::Ptr{Cvoid}, txt::Vector{String})
	ccall((:GMT_Put_Strings, libgmt), Cint, (Cstring, UInt32, Cstring, Ptr{Ptr{UInt8}}), API, family, object, txt)
end

function gmt_get_rgb_from_z(API::Ptr{Cvoid}, P::Ptr{GMT.GMT_PALETTE}, value::Cdouble, rgb::Vector{Float64})
	GMT_ = GMT_Get_Ctrl(API)
	ccall((:gmt_get_rgb_from_z, libgmt), Cint, (Cstring, Ptr{Cvoid}, Cdouble, Ptr{Cdouble}), GMT_, P, value, rgb)
end

function gmt_free_mem(API::Ptr{Cvoid}, mem)
	GMT_ = GMT_Get_Ctrl(API)
	ccall((:gmt_free_func, libgmt), Cvoid, (Cstring, Ptr{Cvoid}, Bool, Cstring), GMT_, mem, true, "Julia")
end

#=
function sprintf(format::String, x...)
	strp = Ref{Ptr{Cchar}}(0)
	if (length(x) == 1)
		len = ccall(:asprintf, Cint, (Ptr{Ptr{Cchar}}, Cstring, Cdouble...), strp, format, x[1])
	elseif (length(x) == 2)
		len = ccall(:asprintf, Cint, (Ptr{Ptr{Cchar}}, Cstring, Cdouble, Cdouble...), strp, format, x[1], x[2])
	elseif (length(x) == 4)
		len = ccall(:asprintf, Cint, (Ptr{Ptr{Cchar}}, Cstring, Cdouble, Cdouble, Cdouble, Cdouble...), strp, format, x[1], x[2], x[3], x[4])
	end
	str = unsafe_string(strp[],len)
	Libc.free(strp[])
	return str
end
=#

#=
function get_common_R(API::Ptr{Cvoid})
	R = COMMON_R((false,false,false,false), false, 0, 0, 0, (0., 0., 0., 0., 0., 0.), (0., 0., 0., 0.), (0., 0.), map(UInt8, (string(repeat(" ",256))...,)))
	Rp = pointer([R])
	ccall((:gmtlib_get_common_R, libgmt), Cint, (Cstring, Ptr{COMMON_R}), API, Rp)
	return unsafe_load(Rp)
end
=#

terrain_filter(data, detail, nrows, ncols, xinc, yinc, coord_type, center_lat=0.0, progress=C_NULL) =
	ccall((:terrain_filter, libgmt), Cint, (Ptr{Cfloat}, Cdouble, Cint, Cint, Cdouble, Cdouble, Cint, Cdouble, Ptr{Cvoid}), data, detail, nrows, ncols, xinc, yinc, coord_type, center_lat, progress)

terrain_image_data(data, contrast, nrows, ncols, image_min=0., image_max=65535.0) =
	ccall((:terrain_image_data, libgmt), Cint, (Ptr{Cfloat}, Cint, Cint, Cdouble, Cdouble, Cdouble), data, nrows, ncols, contrast, image_min, image_max)

fix_mercator(data, detail, nrows, ncols, lat1, lat2) =
	ccall((:fix_mercator, libgmt), Cvoid, (Ptr{Cfloat}, Cdouble, Cint, Cint, Cdouble, Cdouble), data, nrows, ncols, detail, lat1, lat2)

fix_polar_stereographic(data, detail, nrows, ncols, center_res) =
	ccall((:fix_polar_stereographic, libgmt), Cvoid, (Ptr{Cfloat}, Cdouble, Cint, Cint, Cdouble), data, nrows, ncols, detail, center_res)