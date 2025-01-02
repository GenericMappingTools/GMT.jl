# Found Leptonica_jll via https://github.com/pixel27/Tesseract.jl, from which the struct Sppix was ~copied
# and modified to fit the needs of this package.
#
# Also created a Leptonica.jl with clang.jl but the generated .jl is gigantic (> 30000 lines). So I picked
# a couple of function wrappers from there and put in this file. When more functionality is needed it's easy
# to add more function wrappers.
"""
	PixColormap

Colormap of a [`Pix`]

| Field  | Note                                           |
| :----- | :--------------------------------------------- |
| array  | colormap table (array of [`RGBA_QUAD`](@ref))  |
| depth  | of pix (1, 2, 4 or 8 bpp)                      |
| nalloc | number of color entries allocated              |
| n      | number of color entries used                   |
"""
struct PixColormap
	array::Ptr{Cvoid}
	depth::Cint
	nalloc::Cint
	n::Cint
end

"""
	Pix

| Field    | Note                                                |
| :------- | :-------------------------------------------------- |
| w        | width in pixels                                     |
| h        | height in pixels                                    |
| d        | depth in bits (bpp)                                 |
| spp      | number of samples per pixel                         |
| wpl      | 32-bit words/line                                   |
| refcount | reference count (1 if no clones)                    |
| xres     | image res (ppi) in x direction  (use 0 if unknown)  |
| yres     | image res (ppi) in y direction  (use 0 if unknown)  |
| informat | input file format, IFF\\_*                          |
| special  | special instructions for I/O, etc                   |
| text     | text string associated with pix                     |
| colormap | colormap (may be null)                              |
| data     | the image data                                      |
"""
struct Pix
	w::Cuint
	h::Cuint
	d::Cuint
	spp::Cuint
	wpl::Cuint
	refcount::Cint
	xres::Cint
	yres::Cint
	informat::Cint
	special::Cint
	text::Cstring
	colormap::Ptr{PixColormap}
	data::Ptr{Cuint}
end
"""
When the garbage collector collects this object the associated Sppix object will be freed in the C library.
"""
mutable struct Sppix
	ptr::Union{Ptr{Pix}, Ptr{Cvoid}}
	function Sppix(ptr::Union{Ptr{Pix}, Ptr{Cvoid}})
		retval = new(ptr)
		#finalizer(retval) do obj
			#PIX_delete!(obj)
		#end
		finalizer(PIX_delete!, retval)
		return retval
	end
end

"""
This method is called automatically by the garbage collector but can be called manually to release
the object early. This method can be called multiple times without any negative effects.

Calling this method will free the object unless a reference is held by an external library. Once
that library releases it's reference the Sppix object should be fully freed.
"""
function PIX_delete!(sppix::Sppix)::Nothing
	if sppix.ptr != C_NULL
		pixDestroy(Ref(sppix.ptr))
		sppix.ptr = C_NULL
	end
	nothing
end

pixGetWidth(pix) = ccall((:pixGetWidth, liblept), Cint, (Ptr{Pix},), pix)

pixSetWidth(pix, width) = ccall((:pixSetWidth, liblept), Cint, (Ptr{Pix}, Cint), pix, width)

pixGetHeight(pix) = ccall((:pixGetHeight, liblept), Cint, (Ptr{Pix},), pix)

pixSetHeight(pix, height) = ccall((:pixSetHeight, liblept), Cint, (Ptr{Pix}, Cint), pix, height)

pixGetDepth(pix) = ccall((:pixGetDepth, liblept), Cint, (Ptr{Pix},), pix)

pixSetDepth(pix, depth) = ccall((:pixSetDepth, liblept), Cint, (Ptr{Pix}, Cint), pix, depth)

function pixGetDimensions(pix, pw, ph, pd)
	ccall((:pixGetDimensions, liblept), Cint, (Ptr{Pix}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), pix, pw, ph, pd)
end

pixDestroy(ppix) = ccall((:pixDestroy, liblept), Cvoid, (Ptr{Ptr{Pix}},), ppix)

pixCopy(pixd, pixs) = ccall((:pixCopy, liblept), Ptr{Pix}, (Ptr{Pix}, Ptr{Pix}), pixd, pixs)

pixResizeImageData(pixd, pixs) = ccall((:pixResizeImageData, liblept), Cint, (Ptr{Pix}, Ptr{Pix}), pixd, pixs)

pixCopyColormap(pixd, pixs) = ccall((:pixCopyColormap, liblept), Cint, (Ptr{Pix}, Ptr{Pix}), pixd, pixs)

pixRead(filename) = ccall((:pixRead, liblept), Ptr{Pix}, (Cstring,), filename)

pixEndianTwoByteSwapNew(pixs) = ccall((:pixEndianTwoByteSwapNew, liblept), Ptr{Pix}, (Ptr{Pix},), pixs)

pixEndianTwoByteSwap(pixs) = ccall((:pixEndianTwoByteSwap, liblept), Cint, (Ptr{Pix},), pixs)

function pixGetRasterData(pixs, pdata, pnbytes)
	ccall((:pixGetRasterData, liblept), Cint, (Ptr{Pix}, Ptr{Ptr{Cuchar}}, Ptr{Csize_t}), pixs, pdata, pnbytes)
end

pixCreate(width, height, depth) = ccall((:pixCreate, liblept), Ptr{Pix}, (Cint, Cint, Cint), width, height, depth)

function pixSetupByteProcessing(pix, pw, ph)
	ccall((:pixSetupByteProcessing, liblept), Ptr{Ptr{Cuchar}}, (Ptr{Pix}, Ptr{Cint}, Ptr{Cint}), pix, pw, ph)
end

function pixCleanupByteProcessing(pix, lineptrs)
	ccall((:pixCleanupByteProcessing, liblept), Cint, (Ptr{Pix}, Ptr{Ptr{Cuchar}}), pix, lineptrs)
end

function pixSeedfillGray(pixs, pixm, conn)
	ccall((:pixSeedfillGray, liblept), Cint, (Ptr{Pix}, Ptr{Pix}, Cint), pixs, pixm, conn)
end

function pixSeedfillGrayInv(pixs, pixm, conn)
	ccall((:pixSeedfillGrayInv, liblept), Cint, (Ptr{Pix}, Ptr{Pix}, Cint), pixs, pixm, conn)
end

