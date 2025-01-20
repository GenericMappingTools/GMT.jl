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
| array  | colormap table (array of [`RGBA_Quad`](@ref))  |
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
    RGBA_Quad

Colormap table entry (after the BMP version). Note that the BMP format stores the colormap table
exactly as it appears here, with color samples being stored sequentially, in the order (b,g,r,a).

| Field | Note         |
| :---- | :----------- |
| blue  | blue value   |
| green | green value  |
| red   | red value    |
| alpha | alpha value  |
"""
struct RGBA_Quad
	blue::Cuchar
	green::Cuchar
	red::Cuchar
	alpha::Cuchar
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
    Sel

| Field | Note                                     |
| :---- | :--------------------------------------- |
| sy    | sel height                               |
| sx    | sel width                                |
| cy    | y location of sel origin                 |
| cx    | x location of sel origin                 |
| data  | {0,1,2}; data[i][j] in [row][col] order  |
| name  | used to find sel by name                 |
"""
struct Sel
    sy::Cint
    sx::Cint
    cy::Cint
    cx::Cint
    data::Ptr{Ptr{Cint}}
    name::Cstring
end

"""
    L_Kernel

Kernel

| Field | Note                            |
| :---- | :------------------------------ |
| sy    | kernel height                   |
| sx    | kernel width                    |
| cy    | y location of kernel origin     |
| cx    | x location of kernel origin     |
| data  | data[i][j] in [row][col] order  |
"""
struct L_Kernel
	sy::Cint
	sx::Cint
	cy::Cint
	cx::Cint
	data::Ptr{Ptr{Cfloat}}
end

"""
When the garbage collector collects this object the associated Sppix object will be freed in the C library.
"""
mutable struct Sppix
	ptr::Union{Ptr{Pix}, Ptr{Cvoid}}
	function Sppix(ptr::Union{Ptr{Pix}, Ptr{Cvoid}})
		retval = new(ptr)
		#finalizer(retval) do obj
			#Pix_delete!(obj)
		#end
		finalizer(Pix_delete!, retval)
		return retval
	end
end

"""
This method is called automatically by the garbage collector but can be called manually to release
the object early. This method can be called multiple times without any negative effects.

Calling this method will free the object unless a reference is held by an external library. Once
that library releases it's reference the Sppix object should be fully freed.
"""
function Pix_delete!(sppix::Sppix)::Nothing
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
pixGetSpp(pix) = ccall((:pixGetSpp, liblept), Cint, (Ptr{Pix},), pix)
pixGetWpl(pix) = ccall((:pixGetWpl, liblept), Cint, (Ptr{Pix},), pix)
pixSetWpl(pix, wpl) = ccall((:pixSetWpl, liblept), Cint, (Ptr{Pix}, Cint), pix, wpl)

function pixGetDimensions(pix, pw, ph, pd)
	ccall((:pixGetDimensions, liblept), Cint, (Ptr{Pix}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), pix, pw, ph, pd)
end

pixDestroy(ppix) = ccall((:pixDestroy, liblept), Cvoid, (Ptr{Ptr{Pix}},), ppix)
pixCopy(pixd, pixs) = ccall((:pixCopy, liblept), Ptr{Pix}, (Ptr{Pix}, Ptr{Pix}), pixd, pixs)
pixResizeImageData(pixd, pixs) = ccall((:pixResizeImageData, liblept), Cint, (Ptr{Pix}, Ptr{Pix}), pixd, pixs)
pixCopyColormap(pixd, pixs) = ccall((:pixCopyColormap, liblept), Cint, (Ptr{Pix}, Ptr{Pix}), pixd, pixs)
pixRead(filename) = ccall((:pixRead, liblept), Ptr{Pix}, (Cstring,), filename)
pixWrite(fname, pix, format) = ccall((:pixWrite, liblept), Cint, (Cstring, Ptr{Pix}, Cint), fname, pix, format)
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

#_liblept = "C:\\programs\\compa_libs\\leptonica\\compileds\\VC14_64\\lib\\leptonica_w64.dll"
pixSeedfillGray(pixs, pixm, conn)  = ccall((:pixSeedfillGray, liblept), Cint, (Ptr{Pix}, Ptr{Pix}, Cint), pixs, pixm, conn)
pixSeedfillGrayInv(pixs, pixm, conn) = ccall((:pixSeedfillGrayInv, liblept), Cint, (Ptr{Pix}, Ptr{Pix}, Cint), pixs, pixm, conn)
pixErodeGray(pixs, hsize, vsize)   = ccall((:pixErodeGray, liblept),  Ptr{Pix}, (Ptr{Pix}, Cint, Cint), pixs, hsize, vsize)
pixDilateGray(pixs, hsize, vsize)  = ccall((:pixDilateGray, liblept), Ptr{Pix}, (Ptr{Pix}, Cint, Cint), pixs, hsize, vsize)
pixOpenGray(pixs, hsize, vsize)    = ccall((:pixOpenGray, liblept),   Ptr{Pix}, (Ptr{Pix}, Cint, Cint), pixs, hsize, vsize)
pixCloseGray(pixs, hsize, vsize)   = ccall((:pixCloseGray, liblept),  Ptr{Pix}, (Ptr{Pix}, Cint, Cint), pixs, hsize, vsize)
pixErodeGray3(pixs, hsize, vsize)  = ccall((:pixErodeGray3, liblept), Ptr{Pix}, (Ptr{Pix}, Cint, Cint), pixs, hsize, vsize)
pixDilateGray3(pixs, hsize, vsize) = ccall((:pixDilateGray3, liblept),Ptr{Pix}, (Ptr{Pix}, Cint, Cint), pixs, hsize, vsize)
pixOpenGray3(pixs, hsize, vsize)   = ccall((:pixOpenGray3, liblept),  Ptr{Pix}, (Ptr{Pix}, Cint, Cint), pixs, hsize, vsize)
pixCloseGray3(pixs, hsize, vsize)  = ccall((:pixCloseGray3, liblept), Ptr{Pix}, (Ptr{Pix}, Cint, Cint), pixs, hsize, vsize)
pixDilate(pixd, pixs, sel) = ccall((:pixDilate, liblept), Ptr{Pix}, (Ptr{Pix}, Ptr{Pix}, Ptr{Sel}), pixd, pixs, sel)
pixErode(pixd, pixs, sel)  = ccall((:pixErode, liblept),  Ptr{Pix}, (Ptr{Pix}, Ptr{Pix}, Ptr{Sel}), pixd, pixs, sel)
pixOpen(pixd, pixs, sel)   = ccall((:pixOpen, liblept),   Ptr{Pix}, (Ptr{Pix}, Ptr{Pix}, Ptr{Sel}), pixd, pixs, sel)
pixClose(pixd, pixs, sel)  = ccall((:pixClose, liblept),  Ptr{Pix}, (Ptr{Pix}, Ptr{Pix}, Ptr{Sel}), pixd, pixs, sel)
#pixCloseSafe(pixd, pixs, sel) = ccall((:pixCloseSafe, liblept), Ptr{Pix}, (Ptr{Pix}, Ptr{Pix}, Ptr{Sel}), pixd, pixs, sel)

function pixMorphGradient(pixs, hsize, vsize, smoothing)
	ccall((:pixMorphGradient, liblept), Ptr{Pix}, (Ptr{Pix}, Cint, Cint, Cint), pixs, hsize, vsize, smoothing)
end
pixHDome(pixs, height, conn) = ccall((:pixHDome, liblept), Ptr{Pix}, (Ptr{Pix}, Cint, Cint), pixs, height, conn)
pixHMT(pixd, pixs, sel) = ccall((:pixHMT, liblept), Ptr{Pix}, (Ptr{Pix}, Ptr{Pix}, Ptr{Sel}), pixd, pixs, sel)
pixTophat(pixs, hsize, vsize, type) = ccall((:pixTophat, liblept), Ptr{Pix}, (Ptr{Pix}, Cint, Cint, Cint), pixs, hsize, vsize, type)

pixAddGray(pixd, pixs1, pixs2) = ccall((:pixAddGray, liblept), Ptr{Pix}, (Ptr{Pix}, Ptr{Pix}, Ptr{Pix}), pixd, pixs1, pixs2)
pixSubtractGray(pixd, pixs1, pixs2) = ccall((:pixSubtractGray, liblept), Ptr{Pix}, (Ptr{Pix}, Ptr{Pix}, Ptr{Pix}), pixd, pixs1, pixs2)

function pixThinConnected(pixs, type, connectivity, maxiters)
	ccall((:pixThinConnected, liblept), Ptr{Pix}, (Ptr{Pix}, Cint, Cint, Cint), pixs, type, connectivity, maxiters)
end

function pixColorSegment(pixs, maxdist, maxcolors, selsize, finalcolors, debugflag)
	ccall((:pixColorSegment, liblept), Ptr{Pix}, (Ptr{Pix}, Cint, Cint, Cint, Cint, Cint), pixs, maxdist, maxcolors, selsize, finalcolors, debugflag)
end

pixRankFilter(pixs, wf, hf, rank) = ccall((:pixRankFilter, liblept), Ptr{Pix}, (Ptr{Pix}, Cint, Cint, Cfloat), pixs, wf, hf, rank)
pixSobelEdgeFilter(pixs, orientflag) = ccall((:pixSobelEdgeFilter, liblept), Ptr{Pix}, (Ptr{Pix}, Cint), pixs, orientflag)
pixTwoSidedEdgeFilter(pixs, orientflag) = ccall((:pixTwoSidedEdgeFilter, liblept), Ptr{Pix}, (Ptr{Pix}, Cint), pixs, orientflag)

function pixConvolve(pixs, kel, outdepth, normflag)
	ccall((:pixConvolve, liblept), Ptr{Pix}, (Ptr{Pix}, Ptr{L_Kernel}, Cint, Cint), pixs, kel, outdepth, normflag)
end
function pixConvolveSep(pixs, kelx, kely, outdepth, normflag)
    ccall((:pixConvolveSep, liblept), Ptr{Pix}, (Ptr{Pix}, Ptr{L_Kernel}, Ptr{L_Kernel}, Cint, Cint), pixs, kelx, kely, outdepth, normflag)
end

pixConvolveRGB(pixs, kel) = ccall((:pixConvolveRGB, liblept), Ptr{Pix}, (Ptr{Pix}, Ptr{L_Kernel}), pixs, kel)
function pixConvolveRGBSep(pixs, kelx, kely)
	ccall((:pixConvolveRGBSep, liblept), Ptr{Pix}, (Ptr{Pix}, Ptr{L_Kernel}, Ptr{L_Kernel}), pixs, kelx, kely)
end

