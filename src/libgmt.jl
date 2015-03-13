# Julia wrapper for header: /cmn/ext/gmt/gmt-5.1.1/src/gmt.h
# Automatically generated using Clang.jl wrap_c, version 0.0.0

@windows? (const thelib = "gmt_w64") : (const thelib = "libgmt")  # Name of GMT shared lib.


function GMT_Create_Session(tag::String="GMT5", pad=2, mode=0, print_func::Ptr{Void}=C_NULL)
	ccall( (:GMT_Create_Session, thelib), Ptr{Void}, (Ptr{Uint8}, Uint32, Uint32, Ptr{Void}), tag, pad, mode, print_func)
end

function GMT_Create_Data(API::Ptr{Void}, family, geometry, mode, dim=C_NULL, wesn=C_NULL,
		inc=C_NULL, registration=0, pad=2, data::Ptr{Void}=C_NULL)

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
		ret_type = Ptr{Void}			# Should be error instead
	end

	ptr = ccall((:GMT_Create_Data, thelib), Ptr{Void}, (Ptr{Void}, Uint32, Uint32, Uint32, Ptr{Uint64},
		Ptr{Cdouble}, Ptr{Cdouble}, Uint32, Cint, Ptr{Void}), API, family, geometry, mode, dim, wesn, inc,
		registration, pad, data)

	convert(ret_type, ptr)
end

function GMT_Get_Data(API, object_ID::Integer, mode::Integer=0, data=C_NULL)
	ccall((:GMT_Get_Data, thelib), Ptr{Void}, (Ptr{Void}, Cint, Uint32, Ptr{Void}), API, object_ID, mode, data)
end

function GMT_Read_Data(API::Ptr{Void}, family, method, geometry, mode, wesn, input=C_NULL, data=C_NULL)

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
		ret_type = Ptr{Void}			# Should be error instead
	end

	ptr = ccall( (:GMT_Read_Data, thelib), Ptr{Void}, (Ptr{Void}, Uint32, Uint32, Uint32, Uint32, Ptr{Cdouble},
		Ptr{Uint8}, Ptr{Void}), API, family, method, geometry, mode, wesn, input, data)

	convert(ret_type, ptr)
end

function GMT_Insert_Data(API::Ptr{Void}, object_ID::Integer, data)
	ccall((:GMT_Insert_Data, thelib), Cint, (Ptr{Void}, Cint, Ptr{Void}), API, object_ID, data)
end

function GMTAPI_get_moduleinfo(API::Ptr{Void}, _module::ASCIIString)
	ccall((:GMTAPI_get_moduleinfo, thelib), Ptr{Uint8}, (Ptr{Void}, Ptr{Uint8}), API, _module)
end
function GMTAPI_get_moduleinfo(API::Ptr{Void}, _module::Ptr{Uint8})
	ccall((:GMTAPI_get_moduleinfo, thelib), Ptr{Uint8}, (Ptr{Void}, Ptr{Uint8}), API, _module)
end

function GMT_Retrieve_Data(API::Ptr{Void}, object_ID::Integer)
	ccall((:GMT_Retrieve_Data, thelib), Ptr{Void}, (Ptr{Void}, Cint), API, object_ID)
end

function GMT_Duplicate_Data(API::Ptr{Void}, family::Uint32, mode::Uint32, data::Ptr{Void})
  ccall( (:GMT_Duplicate_Data, thelib), Ptr{Void}, (Ptr{Void}, Uint32, Uint32, Ptr{Void}), API, family, mode, data)
end
function GMT_Get_Record(API::Ptr{Void}, mode::Uint32, retval::Ptr{Cint})
  ccall( (:GMT_Get_Record, thelib), Ptr{Void}, (Ptr{Void}, Uint32, Ptr{Cint}), API, mode, retval)
end

function GMT_Destroy_Session(API::Ptr{Void})
	ccall( (:GMT_Destroy_Session, thelib), Cint, (Ptr{Void},), API)
end

function GMT_Register_IO(API, family::Integer, method::Integer, geometry::Integer, direction::Integer=0,
		wesn=C_NULL, resource=C_NULL)
	err = ccall((:GMT_Register_IO, thelib), Cint, (Ptr{Void}, Uint32, Uint32, Uint32, Uint32, Ptr{Cdouble},
		Ptr{Void}), API, family, method, geometry, direction, wesn, resource)
end

function GMT_Init_IO(API::Ptr{Void}, family::Uint32, geometry::Uint32, direction::Uint32, mode::Uint32, n_args::Uint32, args::Ptr{Void})
  ccall( (:GMT_Init_IO, thelib), Cint, (Ptr{Void}, Uint32, Uint32, Uint32, Uint32, Uint32, Ptr{Void}), API, family, geometry, direction, mode, n_args, args)
end
function GMT_Begin_IO(API::Ptr{Void}, family::Uint32, direction::Uint32, header::Uint32)
  ccall( (:GMT_Begin_IO, thelib), Cint, (Ptr{Void}, Uint32, Uint32, Uint32), API, family, direction, header)
end
function GMT_Status_IO(API::Ptr{Void}, mode::Uint32)
  ccall( (:GMT_Status_IO, thelib), Cint, (Ptr{Void}, Uint32), API, mode)
end
function GMT_End_IO(API::Ptr{Void}, direction::Uint32, mode::Uint32)
  ccall( (:GMT_End_IO, thelib), Cint, (Ptr{Void}, Uint32, Uint32), API, direction, mode)
end

function GMT_Put_Data(API::Ptr{Void}, object_ID::Integer, mode::Integer, data)
	ccall((:GMT_Put_Data, thelib), Cint, (Ptr{Void}, Cint, Uint32, Ptr{Void}), API, object_ID, mode, data)
end

function GMT_Write_Data(API::Ptr{Void}, family::Integer, method::Integer, geometry::Integer, mode::Integer,
	wesn, output::String, data)

	err = ccall((:GMT_Write_Data, thelib), Cint, (Ptr{Void}, Uint32, Uint32, Uint32, Uint32, Ptr{Cdouble},
		Ptr{Uint8}, Ptr{Void}), API, family, method, geometry, mode, wesn, output, data)
end

function get_that_pointer(object)
	ccall( (:get_that_pointer, thelib), Ptr{Void}, (Ptr{Void},), object)
end

function GMT_Destroy_Data(API::Ptr{Void}, object)
	ccall( (:GMT_Destroy_Data, thelib), Cint, (Ptr{Void}, Ptr{Void}), API, object)
end

function GMT_Put_Record(API::Ptr{Void}, mode::Uint32, record::Ptr{Void})
  ccall( (:GMT_Put_Record, thelib), Cint, (Ptr{Void}, Uint32, Ptr{Void}), API, mode, record)
end

function GMT_Encode_ID(API::Ptr{Void}, fname::String, object_ID::Integer)
	err = ccall((:GMT_Encode_ID, thelib), Cint, (Ptr{Void}, Ptr{Uint8}, Cint), API, fname, object_ID)
end

function GMT_Get_Row(API::Ptr{Void}, rec_no::Cint, G::Ptr{GMT_GRID}, row::Ptr{Cfloat})
  ccall( (:GMT_Get_Row, thelib), Cint, (Ptr{Void}, Cint, Ptr{GMT_GRID}, Ptr{Cfloat}), API, rec_no, G, row)
end
function GMT_Put_Row(API::Ptr{Void}, rec_no::Cint, G::Ptr{GMT_GRID}, row::Ptr{Cfloat})
  ccall( (:GMT_Put_Row, thelib), Cint, (Ptr{Void}, Cint, Ptr{GMT_GRID}, Ptr{Cfloat}), API, rec_no, G, row)
end
function GMT_Set_Comment(API::Ptr{Void}, family::Integer, mode::Integer, arg::Ptr{Void}, data::Ptr{Void})
  ccall( (:GMT_Set_Comment, thelib), Cint, (Ptr{Void}, Uint32, Uint32, Ptr{Void}, Ptr{Void}), API, family, mode, arg, data)
end

function GMT_Get_ID(API::Ptr{Void}, family::Integer, dir::Integer, resource=C_NULL)
	ccall((:GMT_Get_ID, thelib), Cint, (Ptr{Void}, Uint32, Uint32, Ptr{Void}), API, family, dir, resource)
end

function GMT_Get_Index(API::Ptr{Void}, header::Ptr{GMT_GRID_HEADER}, row::Cint, col::Cint)
  ccall( (:GMT_Get_Index, thelib), int64_t, (Ptr{Void}, Ptr{GMT_GRID_HEADER}, Cint, Cint), API, header, row, col)
end
function GMT_Get_Coord(API::Ptr{Void}, family::Integer, dim::Integer, container::Ptr{Void})
  ccall( (:GMT_Get_Coord, thelib), Ptr{Cdouble}, (Ptr{Void}, Uint32, Uint32, Ptr{Void}), API, family, dim, container)
end

function GMT_Option(API::Ptr{Void}, options)
	ccall( (:GMT_Option, thelib), Cint, (Ptr{Void}, Ptr{Uint8}), API, options)
end

function GMT_Get_Common(API::Ptr{Void}, option::Uint32, par::Ptr{Cdouble})
  ccall( (:GMT_Get_Common, thelib), Cint, (Ptr{Void}, Uint32, Ptr{Cdouble}), API, option, par)
end

function GMT_Get_Default(API::Ptr{Void}, keyword::String, value)
	ccall( (:GMT_Get_Default, thelib), Cint, (Ptr{Void}, Ptr{Uint8}, Ptr{Uint8}), API, keyword, value)
end

function GMT_Get_Value(API::Ptr{Void}, arg::String, par::Ptr{Cdouble})
  ccall( (:GMT_Get_Value, thelib), Cint, (Ptr{Void}, Ptr{Uint8}, Ptr{Cdouble}), API, arg, par)
end

function GMT_Call_Module(API::Ptr{Void}, _module=C_NULL, mode::Integer=0, args=C_NULL)
	if (isa(args,ASCIIString))	args = pointer(args)	end
	ccall((:GMT_Call_Module, thelib), Cint, (Ptr{Void}, Ptr{Uint8}, Cint, Ptr{Void}), API, _module, mode, args)
end

function GMT_Create_Options(API::Ptr{Void}, argc::Integer, args)
	# VERSATILIZAR PARA O CASO DE ARGS SER STRING OU ARRAY DE STRINGS
	ccall((:GMT_Create_Options, thelib), Ptr{GMT_OPTION}, (Ptr{Void}, Cint, Ptr{Void}), API, argc, args)
end
GMT_Create_Options(API::Ptr{Void}, argc::Integer, args::ASCIIString) = 
                   GMT_Create_Options(API, argc, convert(Ptr{Void},pointer(args)))

function GMT_Make_Option(API::Ptr{Void}, option::Uint8, arg::Ptr{Uint8})
  ccall( (:GMT_Make_Option, thelib), Ptr{GMT_OPTION}, (Ptr{Void}, Uint8, Ptr{Uint8}), API, option, arg)
end

function GMT_Find_Option(API::Ptr{Void}, option::Uint8, head::Ptr{GMT_OPTION})
	ccall((:GMT_Find_Option, thelib), Ptr{GMT_OPTION}, (Ptr{Void}, Uint8, Ptr{GMT_OPTION}), API, option, head)
end

function GMT_Append_Option(API::Ptr{Void}, current::Ptr{GMT_OPTION}, head::Ptr{GMT_OPTION})
  ccall( (:GMT_Append_Option, thelib), Ptr{GMT_OPTION}, (Ptr{Void}, Ptr{GMT_OPTION}, Ptr{GMT_OPTION}), API, current, head)
end
function GMT_Create_Args(API::Ptr{Void}, argc::Ptr{Int}, head::Ptr{GMT_OPTION})
  ccall( (:GMT_Create_Args, thelib), Ptr{Ptr{Uint8}}, (Ptr{Void}, Ptr{Cint}, Ptr{GMT_OPTION}), API, argc, head)
end
function GMT_Create_Cmd(API::Ptr{Void}, head::Ptr{GMT_OPTION})
  ccall( (:GMT_Create_Cmd, thelib), Ptr{Uint8}, (Ptr{Void}, Ptr{GMT_OPTION}), API, head)
end
function GMT_Destroy_Options(API::Ptr{Void}, head::Ptr{Ptr{GMT_OPTION}})
  ccall( (:GMT_Destroy_Options, thelib), Cint, (Ptr{Void}, Ptr{Ptr{GMT_OPTION}}), API, head)
end
function GMT_Destroy_Args(API::Ptr{Void}, argc::Cint, argv::Ptr{Ptr{Ptr{Uint8}}})
  ccall( (:GMT_Destroy_Args, thelib), Cint, (Ptr{Void}, Cint, Ptr{Ptr{Ptr{Uint8}}}), API, argc, argv)
end
function GMT_Destroy_Cmd(API::Ptr{Void}, cmd::Ptr{Ptr{Uint8}})
  ccall( (:GMT_Destroy_Cmd, thelib), Cint, (Ptr{Void}, Ptr{Ptr{Uint8}}), API, cmd)
end
function GMT_Update_Option(API::Ptr{Void}, current::Ptr{GMT_OPTION}, arg::Ptr{Uint8})
  ccall( (:GMT_Update_Option, thelib), Cint, (Ptr{Void}, Ptr{GMT_OPTION}, Ptr{Uint8}), API, current, arg)
end
function GMT_Delete_Option(API::Ptr{Void}, current::Ptr{GMT_OPTION})
  ccall( (:GMT_Delete_Option, thelib), Cint, (Ptr{Void}, Ptr{GMT_OPTION}), API, current)
end
function GMT_Parse_Common(API::Ptr{Void}, given_options::Ptr{Uint8}, options::Ptr{GMT_OPTION})
  ccall( (:GMT_Parse_Common, thelib), Cint, (Ptr{Void}, Ptr{Uint8}, Ptr{GMT_OPTION}), API, given_options, options)
end
function GMT_FFT_Option(API::Ptr{Void}, option::Uint8, dim::Uint32, string::Ptr{Uint8})
  ccall( (:GMT_FFT_Option, thelib), Uint32, (Ptr{Void}, Uint8, Uint32, Ptr{Uint8}), API, option, dim, string)
end
function GMT_FFT_Parse(API::Ptr{Void}, option::Uint8, dim::Uint32, args::Ptr{Uint8})
  ccall( (:GMT_FFT_Parse, thelib), Ptr{Void}, (Ptr{Void}, Uint8, Uint32, Ptr{Uint8}), API, option, dim, args)
end
function GMT_FFT_Create(API::Ptr{Void}, X::Ptr{Void}, dim::Uint32, mode::Uint32, F::Ptr{Void})
  ccall( (:GMT_FFT_Create, thelib), Ptr{Void}, (Ptr{Void}, Ptr{Void}, Uint32, Uint32, Ptr{Void}), API, X, dim, mode, F)
end
function GMT_FFT_Wavenumber(API::Ptr{Void}, k::Uint64, mode::Uint32, K::Ptr{Void})
  ccall( (:GMT_FFT_Wavenumber, thelib), Cdouble, (Ptr{Void}, Uint64, Uint32, Ptr{Void}), API, k, mode, K)
end
function GMT_FFT(API::Ptr{Void}, X::Ptr{Void}, direction::Cint, mode::Uint32, K::Ptr{Void})
  ccall( (:GMT_FFT, thelib), Cint, (Ptr{Void}, Ptr{Void}, Cint, Uint32, Ptr{Void}), API, X, direction, mode, K)
end
function GMT_FFT_Destroy(API::Ptr{Void}, K::Ptr{Void})
  ccall( (:GMT_FFT_Destroy, thelib), Cint, (Ptr{Void}, Ptr{Void}), API, K)
end
function GMT_FFT_1D(API::Ptr{Void}, data::Ptr{Cfloat}, n::Uint64, direction::Cint, mode::Uint32)
  ccall( (:GMT_FFT_1D, thelib), Cint, (Ptr{Void}, Ptr{Cfloat}, Uint64, Cint, Uint32), API, data, n, direction, mode)
end
function GMT_FFT_2D(API::Ptr{Void}, data::Ptr{Cfloat}, nx::Uint32, ny::Uint32, direction::Cint, mode::Uint32)
  ccall( (:GMT_FFT_2D, thelib), Cint, (Ptr{Void}, Ptr{Cfloat}, Uint32, Uint32, Cint, Uint32), API, data, nx, ny, direction, mode)
end

function GMT_Report(API, vlevel::Int, txt::String)
	ccall((:GMT_Report, thelib), Void, (Ptr{Void}, Cint, Ptr{Uint8}), API, vlevel, txt)
end

function GMTAPI_lib_tag(name::String)
	ccall((:GMTAPI_lib_tag, thelib), Ptr{Uint8}, (Ptr{Uint8},), name)
end
function GMTAPI_lib_tag(name::Ptr{Uint8})
	ccall((:GMTAPI_lib_tag, thelib), Ptr{Uint8}, (Ptr{Uint8},), name)
end

function GMTAPI_key_to_family(API::Ptr{Void}, key::String, family::Ptr{Int}, geometry::Ptr{Int})
	ccall((:GMTAPI_key_to_family, thelib), Cint, (Ptr{Void}, Ptr{Uint8}, Ptr{Int}, Ptr{Int}), API, key, family, geometry)
end

function GMTAPI_get_key(API::Ptr{Void}, option::Char, keys::Ptr{Ptr{Uint8}}, n_keys::Int)
	ccall((:GMTAPI_get_key, thelib), Cint, (Ptr{Void}, Char, Ptr{Ptr{Uint8}}, Int), API, option, keys, n_keys)
end

function GMTAPI_found_marker(text::String, marker::Char)
	ccall((:GMTAPI_found_marker, thelib), Uint32, (Ptr{Uint8}, Char), text, marker)
end
function GMTAPI_found_marker(text::Ptr{Uint8}, marker::Char)
	ccall((:GMTAPI_found_marker, thelib), Uint32, (Ptr{Uint8}, Char), text, marker)
end

#= These depend on GMT_CTRL that is not wrapped
function GMTAPI_open_grd(GMT::Ptr{GMT_CTRL}, file::String, G::Ptr{GMT_GRID}, mode::Char, access_mode::Int)
	ccall((:GMTAPI_open_grd, thelib), Cint, (Ptr{GMT_CTRL}, String, Ptr{GMT_GRID}, Char, Uint32), GMT, file, G, mode, access_mode)
end
function GMTAPI_open_grd(GMT::Ptr{GMT_CTRL}, file::Ptr{Uint8), G::Ptr{GMT_GRID}, mode::Char, access_mode::Int)
	ccall((:GMTAPI_open_grd, thelib), Cint, (Ptr{GMT_CTRL}, String, Ptr{GMT_GRID}, Char, Uint32), GMT, file, G, mode, access_mode)
end

function GMTAPI_close_grd(GMT::Ptr{GMT_CTRL}, G::Ptr{GMT_GRID})
	ccall((:GMTAPI_close_grd, thelib), Void, (Ptr{GMT_CTRL}, Ptr{GMT_GRID}), GMT, G)
end

function GMTAPI_update_txt_item(API::Ptr{GMTAPI_CTRL}, mode::Int, arg::Ptr{Void}, length::Int, string::String)
	ccall((:GMTAPI_update_txt_item, thelib), Void, (Ptr{GMTAPI_CTRL}, Int, Ptr{Void}, Int, String), API, mode, arg, length, string)
end
=#

function GMTAPI_get_key(API::Ptr{Void}, string::ASCIIString, _type::Char, n_items::Ptr{Int}, PS::Ptr{Int})
	ccall((:GMTAPI_get_key, thelib), Ptr{Ptr{Uint8}}, (Ptr{Void}, ASCIIString, Char, Ptr{Uint32}, PS::Ptr{Uint32}),
	       API, string, _type, n_items, PS)
end
function GMTAPI_get_key(API::Ptr{Void}, string::Ptr{Uint8}, _type::Char, n_items::Ptr{Int}, PS::Ptr{Int})
	ccall((:GMTAPI_get_key, thelib), Ptr{Ptr{Uint8}}, (Ptr{Void}, String, Char, Ptr{Uint32}, PS::Ptr{Uint32}),
	       API, string, _type, n_items, PS)
end

function GMT_Encode_Options(V_API::Ptr{Void}, _module::ASCIIString, marker::Char, nleft::Integer, head::Ptr{Ptr{GMT_OPTION}}, n::Ptr{Int})
	ccall((:GMT_Encode_Options, thelib), Ptr{GMT_RESOURCE}, (Ptr{Void}, Ptr{Uint8}, Char, Cint, Ptr{Ptr{GMT_OPTION}},
	        Ptr{Uint32}), V_API, _module, marker, nleft, head, n)
end
function GMT_Encode_Options(V_API::Ptr{Void}, _module::Ptr{Uint8}, marker::Char, nleft::Integer, head::Ptr{Ptr{GMT_OPTION}}, n::Ptr{Int})
	ccall((:GMT_Encode_Options, thelib), Ptr{GMT_RESOURCE}, (Ptr{Void}, Ptr{Uint8}, Char, Cint, Ptr{Ptr{GMT_OPTION}},
	        Ptr{Uint32}), V_API, _module, marker, nleft, head, n)
end


function GMT_Expand_Option(V_API::Ptr{Void}, opt::Ptr{GMT_OPTION}, marker::Char, arg::ASCIIString)
	ccall((:GMT_Expand_Option, thelib), Cint, (Ptr{Void}, Ptr{GMT_OPTION}, Char, Ptr{Uint8}), V_API, opt, marker, arg)
end
function GMT_Expand_Option(V_API::Ptr{Void}, opt::Ptr{GMT_OPTION}, marker::Char, arg::Ptr{Uint8})
	ccall((:GMT_Expand_Option, thelib), Cint, (Ptr{Void}, Ptr{GMT_OPTION}, Char, Ptr{Uint8}), V_API, opt, marker, arg)
end


function gmt_core_module_info(API, candidate::String)
	ccall((:gmt_core_module_info, thelib), Ptr{Uint8}, (Ptr{Void}, Ptr{Uint8}), API, candidate)
end
function gmt_core_module_info(API, candidate::Ptr{Uint8})
	ccall((:gmt_core_module_info, thelib), Ptr{Uint8}, (Ptr{Void}, Ptr{Uint8}), API, candidate)
end
