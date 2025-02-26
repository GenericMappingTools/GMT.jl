module Laszip

using GMT, Printf, Dates, LASzip_jll

export
	lazinfo, lazread, lazwrite, lasread, laswrite

include("laszip_h.jl")
include("laszip_dll.jl")
include("lazread.jl")
include("lazwrite.jl")

"""
	Prints an laszip error message and error out

	msgerror(lzobj::Ptr{Void}, extramsg::AbstractString="")

	Where:
		"lzobj" is a pointer to laszip_readert|writer created by unsafe_load(laszip_create(arg))
		"extramsg" is an optional extra message to be printed before the laszip error message.
"""
function msgerror(lzobj::Ptr{Cvoid}, extramsg::AbstractString="")
	s = lpad("",128,"        ")
	GC.@preserve s begin
		pStr = pointer([pointer(s)])		# Create a 1024 bytes string and get its pointer
		laszip_get_error(lzobj, pStr)
		Str = unsafe_string(unsafe_load(pStr))
	end
	isempty(extramsg) ? error(Str) : error(extramsg * "\n\t" * Str)
end
function msgerror(lzobj::Ptr{Ptr{Cvoid}}, extramsg::AbstractString="")
	lzobj = unsafe_load(lzobj)
	msgerror(lzobj, extramsg)
end

end # module
