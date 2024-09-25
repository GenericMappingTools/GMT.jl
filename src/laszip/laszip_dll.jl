# Automatically generated using Clang.jl wrap_c, version 0.0.0

const laszip = replace(liblaszip, "_api" => "")

function laszip_get_version(major, minor, revision, build)
    ccall((:laszip_get_version, laszip), Cint, (Ptr{UInt8}, Ptr{UInt8}, Ptr{UInt16}, Ptr{UInt32}), major, minor, revision, build)
end

function laszip_create(pointer::Ref{Ptr{Cvoid}})
    ccall((:laszip_create, laszip), Cint, (Ptr{Ptr{Cvoid}},), pointer)
end

function laszip_get_error(pointer::Ptr{Cvoid}, error)
    ccall((:laszip_get_error, laszip), Cint, (Ptr{Cvoid}, Ptr{Ptr{UInt8}}), pointer, error)
end

#=
function laszip_get_warning(pointer::Ptr{Cvoid},warning::Ptr{Ptr{UInt8}})
    ccall((:laszip_get_warning, laszip), Cint, (Ptr{Cvoid},Ptr{Ptr{UInt8}}), pointer,warning)
end

function laszip_clean(pointer::Ptr{Cvoid})
    ccall((:laszip_clean, laszip), Cint, (Ptr{Cvoid},), pointer)
end
=#

function laszip_destroy(pointer::Ptr{Cvoid})
    ccall((:laszip_destroy, laszip), Cint, (Ptr{Cvoid},), pointer)
end

function laszip_get_header_pointer(pointer::Ptr{Cvoid}, header_pointer::Ref{Ptr{laszip_header}})
    ccall((:laszip_get_header_pointer, laszip), Cint, (Ptr{Cvoid}, Ptr{Ptr{laszip_header}}), pointer, header_pointer)
end

function laszip_get_point_pointer(pointer::Ptr{Cvoid}, point_pointer::Ref{Ptr{laszip_point}})
    ccall((:laszip_get_point_pointer, laszip), Cint, (Ptr{Cvoid},Ptr{Ptr{laszip_point}}), pointer, point_pointer)
end

function laszip_get_point_count(pointer::Ptr{Cvoid}, count::Ptr{Clonglong})
    ccall((:laszip_get_point_count, laszip), Cint, (Ptr{Cvoid}, Ptr{Clonglong}), pointer, count)
end

#=
function laszip_set_header(pointer::Ptr{Cvoid},header::Ptr{laszip_header})
    ccall((:laszip_set_header, laszip), Cint, (Ptr{Cvoid}, Ptr{laszip_header}), pointer, header)
end

function laszip_check_for_integer_overflow(pointer::Ptr{Cvoid})
    ccall((:laszip_check_for_integer_overflow, laszip), Cint, (Ptr{Cvoid},), pointer)
end

function laszip_auto_offset(pointer::Ptr{Cvoid})
    ccall((:laszip_auto_offset, laszip), Cint, (Ptr{Cvoid},), pointer)
end
=#

function laszip_set_point(pointer::Ptr{Cvoid},point::Ptr{laszip_point})
    ccall((:laszip_set_point, laszip), Cint, (Ptr{Cvoid},Ptr{laszip_point}), pointer, point)
end

function laszip_set_coordinates(pointer::Ptr{Cvoid},coordinates::Ptr{Cdouble})
    ccall((:laszip_set_coordinates, laszip), Cint, (Ptr{Cvoid},Ptr{Cdouble}), pointer, coordinates)
end

#=
function laszip_get_coordinates(pointer::Ptr{Cvoid}, coordinates::Ptr{Cdouble})
    ccall((:laszip_get_coordinates, laszip), Cint, (Ptr{Cvoid}, Ptr{Cdouble}), pointer, coordinates)
end

function laszip_set_geokeys(pointer::Ptr{Cvoid}, number::UInt32, key_entries::Ptr{laszip_geokey})
    ccall((:laszip_set_geokeys, laszip), Cint, (Ptr{Cvoid}, UInt32, Ptr{laszip_geokey}), pointer, number, key_entries)
end

function laszip_set_geodouble_params(pointer::Ptr{Cvoid}, number::UInt32, geodouble_params::Ptr{Cdouble})
    ccall((:laszip_set_geodouble_params, laszip), Cint, (Ptr{Cvoid}, UInt32, Ptr{Cdouble}), pointer, number, geodouble_params)
end

function laszip_set_geoascii_params(pointer::Ptr{Cvoid}, number::UInt32, geoascii_params::Ptr{UInt8})
    ccall((:laszip_set_geoascii_params, laszip), Cint, (Ptr{Cvoid}, UInt32, Ptr{UInt8}), pointer, number, geoascii_params)
end

function laszip_add_vlr(pointer::Ptr{Cvoid}, vlr::Ptr{laszip_vlr})
    ccall((:laszip_add_vlr, laszip), Cint, (Ptr{Cvoid}, Ptr{laszip_vlr}), pointer, vlr)
end

function laszip_seek_point(pointer::Ptr{Cvoid}, index::Clonglong)
    ccall((:laszip_seek_point, laszip), Cint, (Ptr{Cvoid}, Clonglong), pointer, index)
end
=#

function laszip_open_writer(pointer::Ptr{Cvoid}, fname, compress::Int)
    ccall((:laszip_open_writer, laszip), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Cint), pointer, fname, compress)
end

function laszip_write_point(pointer::Ptr{Cvoid})
    ccall((:laszip_write_point, laszip), Cint, (Ptr{Cvoid},), pointer)
end

function laszip_close_writer(pointer::Ptr{Cvoid})
    ccall((:laszip_close_writer, laszip), Cint, (Ptr{Cvoid},), pointer)
end

function laszip_open_reader(pointer::Ptr{Cvoid}, fname, is_compressed)
    ccall((:laszip_open_reader, laszip), Cint, (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Cint}), pointer, fname, is_compressed)
end

function laszip_read_point(pointer::Ptr{Cvoid})
    ccall((:laszip_read_point, laszip), Cint, (Ptr{Cvoid},), pointer)
end

function laszip_close_reader(pointer::Ptr{Cvoid})
    ccall((:laszip_close_reader, laszip), Cint, (Ptr{Cvoid},), pointer)
end

#=
function create_empty_header()
    ccall((:create_empty_header, laszip), laszip_header, ())
end
function create_empty_point()
    ccall((:create_empty_point, laszip), laszip_point, ())
end
function create_empty_vlr()
    ccall((:create_empty_vlr, laszip), laszip_vlr, ())
end
=#
