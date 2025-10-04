
"""
	img2pix(I::GMTimage)::Sppix
or

	img2pix(mat::Matrix{<:Integer}; layout="TRBa")::Sppix

Convert an image to a Sppix object (a structure with a pointer to a Leptonica Pix).

Inputs can be UInt8 or Boolean matrices or GMTimages.
"""
function img2pix(mat::Matrix{<:Integer}, bpp=8; layout="TRBa")::Sppix
	@assert isa(layout, String) && length(layout) >= 3
	img2pix(mat2img(mat, layout=layout), bpp)
end
function img2pix(mat::BitMatrix, bpp=1; layout="TRBa")::Sppix
	@assert isa(layout, String) && length(layout) >= 3
	img2pix(mat2img(collect(mat), layout=layout), 1)
end
function img2pix(I::GMTimage, bpp=8)::Sppix		# Minimalist. Still doesn't have a colormap and not yet RGB(A)
	# The Leptonoica library has (in fact it almost hasn't) an awfull documentation.
	# I was able, however, to find a way to create and fill a Pix object with a matrix. The trick is to
	# create a Pix object with the right size and then fill it with the matrix data. The pixSetupByteProcessing()
	# function is the key. It seems to deal well with the difficulty of the data padding per row.
	# However, the same does not work for 1 bpp (binary) images. The trick is to create a 8 bpp image with the
	# the same number of bits per row as the 1 bpp image, work on the bits and then convert to 1 bpp.
	width, height = getsize(I)
	n_bands = size(I,3)
	(n_bands >= 3 && !(I.layout[2] == 'R' && (I.layout[3] == 'B' || I.layout[3] == 'P'))) &&
		error("Only Row-major memory layout is supported for RGB(A) images.")
	(n_bands >= 3) && (bpp = 32)
	_width = (bpp == 1) ? ceil(Int, width/8) : (bpp == 8) ? width : width*4
	ppix = pixCreate(_width, height, 8)					# Create an empty Pix
	w, h = Ref{Cint}(0), Ref{Cint}(0)
	plineptrs = pixSetupByteProcessing(ppix, w, h)
	lineptrs = unsafe_wrap(Array, plineptrs, h[])		# ::Vector{Ptr{UInt8}}
	k = 0
	if (bpp == 8)
		if (I.layout[2] == 'R')
			for i = 1:height, j = 1:w[]		# Put the alpha values in the every fourth position
				unsafe_store!(lineptrs[i], UInt8(I.image[k+=1]), j)
			end
		else					# Column major must be written in row major
			for i = 1:h[]
				line = unsafe_wrap(Array, lineptrs[i], w[])
				for j = 1:w[]  line[j] = UInt8(I.image[i,j])  end
			end
		end
	elseif (bpp == 32)
		if (I.layout[3] == 'P')	# Pixel interleaved
			cols_iter = (n_bands == 4) ? (1:w[]) : (1:w[])[rem.(1:w[],4) .!= 0]	# (1:8)[rem.(1:8,4) .!= 0] = [1 2 3 5 6 7], that is, jump every 4th
			for i = 1:height, j = cols_iter			# cols_iter knows if we are writing RGB or RGBA
				unsafe_store!(lineptrs[i], I.image[k+=1], j)
			end
			if (n_bands == 3 && length(I.alpha) == width * height)
				k = 0
				for i = 1:height, j = 1:4:w[]		# Put the alpha values in the every fourth position
					unsafe_store!(lineptrs[i], I.alpha[k+=1], j)
				end
			end
		else					# Band interleaved
			cols_iter = (n_bands == 4) ? (1:w[]) : (1:w[])[rem.(1:w[],4) .!= 0]
			for i = 1:height
				k = 0
				for j = 1:width
					for b = 1:n_bands
						unsafe_store!(lineptrs[i], I.image[j,i,b], cols_iter[k+=1])
					end
				end
			end
			if (n_bands == 3 && length(I.alpha) == width * height)
				k = 0
				for i = 1:height, j = 1:4:w[]		# Put the alpha values in the every fourth position
					unsafe_store!(lineptrs[i], I.alpha[k+=1], j)
				end
			end
		end
	else						# bpp == 1
		resto = rem(width, 8)
		cols_iter = (resto == 0) ? (1:_width) : (1:(_width-1))
		if (I.layout[2] == 'R')
			for i = 1:h[]
				line = unsafe_wrap(Array, lineptrs[i], _width)
				for j = cols_iter
					for n = 7:-1:0
						(I.image[k+=1] != 0) && (line[j] = line[j] | UInt8(1) << UInt8(n))
					end
				end
				if (resto != 0)
					for n = resto-1:-1:0
						(I.image[k+=1] != 0) && (line[_width] = line[_width] | UInt8(1) << UInt8(n))
					end
				end
			end
		else					# Column major
			for i = 1:h[]
				line = unsafe_wrap(Array, lineptrs[i], w[])
				for j = cols_iter
					for n = 7:-1:0
						UInt8(I.image[i,j]) != 0 && (line[j] = line[j] | UInt8(1) << UInt8(n))
					end
				end
				if (resto != 0)
					for n = resto-1:-1:0
						(I.image[i,width] != 0) && (line[_width] = line[_width] | UInt8(1) << UInt8(n))
					end
				end
			end
		end
	end
	pixCleanupByteProcessing(ppix, plineptrs)
	if (bpp == 1 || bpp == 32)
		pixSetDepth(ppix, bpp)
		pixSetWidth(ppix, width)		# Set the true width
	end
	return Sppix(ppix)
end

# ---------------------------------------------------------------------------------------------------
"""
	I = pix2img(ppix::Sppix)::GMTimage

Convert a Sppix object to a GMTimage.
"""
function pix2img(ppix::Sppix)::GMTimage
	# Here we are getting the data from the Pix object. For the 1 bpp case we need to work on the bits
	# and basically do the inverse of the trick we used in img2pix().
	pdata = Ref{Ptr{UInt8}}()
	pnbytes = Ref{Csize_t}()
	bpp = pixGetDepth(ppix.ptr)
	width, height = pixGetWidth(ppix.ptr), pixGetHeight(ppix.ptr)
	if (bpp == 1)
		pixSetWidth(ppix.ptr, ceil(Int, width/8))		# Pretend we have a 8 bpp
		pixSetDepth(ppix.ptr, 8)
	end
	pixGetRasterData(ppix.ptr, pdata, pnbytes)			# for 1 bpp, had to do the pretend-to-be-8-bpp first
	r = unsafe_wrap(Array, pdata[], pnbytes[], own=(bpp == 1) ? false : true)
	if (bpp == 1)
		# https://www.geeksforgeeks.org/extract-bits-in-c/
		mat = zeros(UInt8, width, height)		# We are storing the image as "TRBa"
		u1 = UInt8(1)
		masks8 = [1,2,4,8,16,32,64,128]
		k, m = 1, 0
		resto = rem(width, 8)
		width8 = ceil(Int, width/8)
		cols_iter = (resto == 0) ? (1:width8) : (1:width8-1)
		for i = 1:height
			for j = cols_iter
				t = r[m+=1]
				for n = 7:-1:0
					(((t & masks8[n+1]) >> n) == 1) && (mat[k] = u1)
					k += 1
				end
			end
			if (resto != 0)
				t = r[m+=1]
				for n = resto-1:-1:0
					(((t & masks8[n+1]) >> n) == 1) && (mat[k] = u1)
					k += 1
				end
			end
		end
		pixSetDepth(ppix.ptr, 1)			# Reset the original bpp
		pixSetWidth(ppix.ptr, width)		# Same for width
		I = mat2img(mat, layout="TRBa", is_transposed=true)
	elseif (bpp == 8)
		I = mat2img(reshape(r, (width, height)), layout="TRBa", is_transposed=true)
		cmap = getPixCPT(ppix.ptr)
		length(cmap) > 3 && (I.colormap = cmap[:]; I.n_colors = 256)
	else		# bpp == 32. And what if we have transparency? How to know that?
		I = mat2img(reshape(r, (width, height, 3)), layout="BRPa", is_transposed=true)
	end
	return I
end

# ---------------------------------------------------------------------------------------------------
"""
    pal = getPixCPT(ppix::Ptr{Pix})::Matrix{Int32}

Get the color palette from a Pix object and return it as a 256x4 matrix (or [0 0 0] if no colormap).
"""
function getPixCPT(ppix::Ptr{Pix})::Matrix{Int32}
	(unsafe_load(ppix).colormap == C_NULL) && return zeros(Int32, 1, 3)		# No colormap
	P = convert(Ptr{Pix}, ppix)
	Pi::Pix = unsafe_load(P)				# We now have a Pix structure
	Pc = unsafe_load(Pi.colormap)			# PixColormap
	(Pc.depth != 8) && error("Other than 8 bit color palettes are not implemented yet")
	Pq = convert(Ptr{RGBA_Quad}, Pc.array)
	RGBA = unsafe_wrap(Array, Pq, Pc.n)		# Pc.n-element Vector{GMT.RGBA_Quad}
	pal = zeros(Int32, 256, 4)				# Remember that GDAL (at least via GMT) expects a 256x4 palette
	for k = 1:Pc.n							# Loop over n colors in palette
		pal[k,1] = RGBA[k].red
		pal[k,2] = RGBA[k].green
		pal[k,3] = RGBA[k].blue
		pal[k,4] = RGBA[k].alpha
	end
	return pal
end

# ---------------------------------------------------------------------------------------------------
"""
    I = imreconstruct(marker::Union{Matrix{Bool}, Matrix{UInt8}}, Imask::GMTimage{<:UInt8, 2}; conn=4, insitu=true)

Perform morphological reconstruction of the image `marker` under the image `mask`.

The elements of `marker` must be less than or equal to the corresponding elements of `mask`.
If the values in `marker` are greater than corresponding elements in `mask`, then ``imreconstruct``
clips the values to the mask level before starting the procedure. The worphological work is
done by the Leptonica function ``pixSeedfillGray``.

### Args
- `marker`: The image to be reconstructed (will hold the reconstructed image). This can be a matrix
  or a ``GMTimage`` with Boolean or UInt8 types
- `mask`: The mask image. Types (``GMTimage`` or matrix) are Boolean or UInt8.

### Kwargs
- `conn::Int`: Connectivity for the image reconstruction (4 or 8). Default is 4.
- `insitu::Bool`: If true, the input images are treated as in situ. Default is true.

### Returns
- A new ``GMTimage`` (or Matrix).

### Examlple

Use reconstruction to segment an image

```julia
text(["Hello World"], region=(1.92,2.08,1.97,2.02), x=2.0, y=2.0, font=(30, "Helvetica-Bold", :white),
     frame=(axes=:none, bg=:black), figsize=(6,0), name="tmp.png")
I = gmtread("tmp.png", band=1);
marker = fill(UInt8(0),(size(I)));
marker[390,130] = UInt8(255);
im = imreconstruct(Im, I)
```
"""
function imreconstruct(seed::Union{Matrix{Bool}, Matrix{UInt8}}, Imask::GMTimage{<:UInt8, 2}; conn=4, insitu=true)::GMTimage
	Iseed = mat2img(seed, Imask)
	(eltype(Iseed) == Bool) && (Iseed = togglemask(Iseed))
	imreconstruct(Iseed, Imask; conn=conn, insitu=insitu)
end
function imreconstruct(Iseed::GMTimage{<:Integer, 2}, Imask::Union{GMTimage{<:Integer, 2}, Matrix{<:Integer}}; conn=4, insitu=true)::GMTimage
	ppixIs = img2pix(Iseed)
	ppixIm = img2pix(Imask)
	p = (insitu == 1) ? ppixIs : pixCopy(C_NULL, ppixIs)	# pixCopy is a shallow copy that does duplicate data. So this is wrong
	pixSeedfillGray(p.ptr, ppixIm.ptr, conn)		# The image in 'p' is modified
	I = pix2img(p)
	(eltype(Iseed) == Bool) && (I = togglemask(I))
	return I
end
function imreconstruct(seed::Union{Matrix{Bool}, Matrix{UInt8}}, mask::Union{Matrix{Bool}, Matrix{UInt8}};
                       conn=4, layout="TRBa", insitu=true, is_transposed=false)
	istp = (is_transposed == 1)
	I = imreconstruct(mat2img(seed, layout=layout, is_transposed=istp), mat2img(mask, layout=layout, is_transposed=istp); conn=conn, insitu=insitu)
	return I.image					# Because we received matrices so the output is a matrix as well.
end
#=			Not working
function imreconstruct(Iseed::GMTimage{Bool, 2}, Imask::GMTimage{Bool, 2}; conn=4, insitu=true)::GMTimage
	Iseed = togglemask(Iseed);		Imask = togglemask(Imask)
	I = imreconstruct(Iseed, Imask; conn=conn, insitu=insitu)
	togglemask(Imask)
	return I
end
=#

# ---------------------------------------------------------------------------------------------------
"""
    I2 = imfill(I; conn=4, is_transposed=true, layout="TRBa")

Fill holes in the grayscale ``GMTimage`` I or UInt8 matrix I.

Here, a hole is defined as an area of dark pixels surrounded by lighter pixels.

### Args
- `I::Union{GMTimage{UInt8, 2}, GMTimage{Bool, 2}, Matrix{UInt8}, Matrix{Bool}, BitMatrix}`: Input image.

### Kwargs
- `conn::Int`: Connectivity for the image filling (4 or 8). Default is 4.
- `is_transposed::Bool`: If `true`, it informs that the input image array is transposed. Default is `true`.
   Normally the ``GMTimage`` carries information to know about the transposition (which is `true` when the layout is "TRB").
   When passing a matrix in column-major order (the default in Julia), `is_transposed` must be set to `false`.
   NOTE: The deaful is `true` because that is the normal case when reading a file image with ``gmtread`` or ``gdalread``.
- `layout::String`: Layout of the input Matrix (default is "TRBa"). If the input is a GMTimage,
   this argument should have been set automatically and can normally be ignored.

### Returns
- A new ``GMTimage`` (or Matrix) with the holes filled.

### Examples
```julia
# Example from Matlab imfill
I = gmtread("TESTSDIR * "assets/coins.png");
Ibw = binarize(I);
BW2 = imfill(Ibw);
```
"""
function imfill(mat::Matrix{<:Integer}; conn=4, is_transposed=true, layout="TRBa")
	@assert conn == 4 || conn == 8 "Only conn=4 or conn=8 are supported"
    mask = padarray(mat, ones(Int, 1, ndims(mat)), padval=-Inf)		# 'mask' is always a matrix
	imcomplement!(mask)
    marker = copy(mask)

	marker[2:end-1, 2:end-1] .= typemin(eltype(mat))
    I2 = imreconstruct(marker, mask, conn=conn, is_transposed=is_transposed, layout=layout)
	imcomplement!(I2)
	I2 = I2[2:end-1, 2:end-1]
	(eltype(mat) <: Bool) && (I2 = collect(I2 .== 255))
	return I2
end
function imfill(I::GMTimage; conn=4)::GMTimage
	mat2img(imfill(I.image; conn=conn, is_transposed=(getsize(I) == size(I) && I.layout[2] == 'R'), layout=I.layout), I)
end
function imfill(mat::BitMatrix; conn=4, is_transposed=true, layout="TRBa")
	# This method can be improved to use the Leptonica function pixSeedfillBinary()
	r = imfill(UInt8.(mat); conn=conn, is_transposed=is_transposed, layout=layout)
	r .== 1
end

# ---------------------------------------------------------------------------------------------------
"""
	fillsinks(G::GMTgrid; conn=4, region=nothing, saco=false, insitu=false)

Fill sinks in a grid.

This function uses the ``imfill`` function to find how to fill sinks in a grid. But since ``imfill``
operates on UInt8 matrices only, the vertical (z) descrimination of the grid is reduced to 256 levels,
which is not that much.

### Args
- `G::GMTgrid`: The input grid to process.

### Kwargs
- `conn::Int`: Connectivity for sink filling (4 or 8). Default is 4.
- `region`: Limit the action to a region of the grid specified by `region`. See for example the ``coast``
  manual for and extended doc on this keword, but note that here only `region` is accepted and not `R`, etc...
- `saco::Bool`: Save the lines (GMTdataset ~contours) used to fill the sinks in a global variable called
  SACO. This is intended to avoid return them all the time when function ends. This global variable
  is a ``[Dict{String,Union{AbstractArray, Vector{AbstractArray}}}()]``, so to access its contents you must use:

  ``D = get(SACO[1], "saco", nothing)``, where ``D`` is now a GMTdataset or a vector of them.

  NOTE: It is the user's responsibility to empty this global variable when it is no longer needed.

  You do that with: ``delete!(SACO[1], "saco")``
- `insitu::Bool`: If `true`, modify the grid in place. Default is `false`.
  Alternatively, use the conventional form ``fillsinks!(G; conn=4)``.

### Returns
- A new `GMTgrid` with sinks filled, unless `insitu` is `true`, in which case the input grid is modified and returned.

### Examples
```julia
G = peaks();
G2 = fillsinks(G);
viz(G2, shade=true)
```

Now save the filling contours and make a plot that overlayes them
```julia
G2 = fillsinks(G);
G2 = fillsinks(G, saco=true);
grdimage(G2)
plot!(get(SACO[1], "saco", nothing), color=:white, show=true)
```
"""
function fillsinks(G::GMTgrid; conn=4, region=nothing, saco=false, insitu=false)
	I = imagesc(G, region=region)
	I2 = imfill(I, conn=conn)
	d = (I .== I2')
	D = polygonize(d)
	if (saco == 1)
		Dtrk = gmt("grdtrack -G -n+a", D, G)
		means = isa(D, Vector) ? median.(Dtrk) : median(Dtrk)
		SACO[1] = Dict("saco" => Dtrk)			# Save the grdtrack interpolated lines for eventual external use.
	else
		#Dtrk = grdtrack(G, D, o=2)
		Dtrk = gmt("grdtrack -G -n+a -o2", D, G)
		means = isa(D, Vector) ? median.(Dtrk) : median(Dtrk)	# The mean of each interpolated contour
	end
	_G = (insitu == 1) ? G : deepcopy(G)

	function filled_ranges(G, D)
		x0, y0, dx, dy = G.range[1], G.range[3], G.inc[1], G.inc[2]
		col_1 = round(Int, (D.bbox[1] - x0) / dx) + 1
		col_2 = round(Int, (D.bbox[2] - x0) / dx) + 1
		row_1 = round(Int, (D.bbox[3] - y0) / dy) + 1
		row_2 = round(Int, (D.bbox[4] - y0) / dy) + 1
		return x0, y0, dx, dy, col_1, col_2, row_1, row_2
	end

	if (isa(D, Vector))
		for k = 1:numel(D)
			x0, y0, dx, dy, col_1, col_2, row_1, row_2 = filled_ranges(G, D[k])
			Threads.@threads for i = col_1:col_2
				t = (i-1)*dx+x0
				for j = row_1:row_2
					@inbounds pip(t, (j-1)*dy+y0, D[k].data) >= 0 && (_G.z[j,i] = means[k])
				end
			end
		end
	else
		x0, y0, dx, dy, col_1, col_2, row_1, row_2 = filled_ranges(G, D)
		Threads.@threads for i = col_1:col_2
			t = (i-1)*dx+x0
			for j = row_1:row_2
				@inbounds pip(t, (j-1)*dy+y0, D.data) >= 0 && (_G.z[j,i] = means)
			end
		end
	end
	_G.range[5] = minimum_nan(_G.z)
	return _G
end
fillsinks!(G::GMTgrid; conn=4, region=nothing, saco=false) = fillsinks(G; conn=conn, region=region, saco=saco, insitu=true)

# ---------------------------------------------------------------------------------------------------
"""
    J = imerode(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3, sel=nothing)::GMTimage

Erode the grayscale or binary image I.

The erosion is performed with a matrix of 0’s and 1’s with width `hsize` and height `vsize`, or, if possible,
with the structuring element `sel`. Later case is faster but it is only available for binary images, where by
_binary_ images we mean Boolean images or images with only 0’s and 1’s of UInt8 type.

### Args
- `I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}`: Input image.

### Kwargs
- `hsize::Int=3`: Horizontal size of the 'box' structuring element.
- `vsize::Int=3`: Vertical size of the 'box' structuring element.
- `sel=nothing`: Structuring element (See ``strel`` function). An alternative to `hsize` and `vsize` options.
  If equal to ``nothing``, a structuring box of size `hsize` x `vsize` is used.

### Returns
A new `GMTimage` of the same type as `I` with the erosion applied.

### Example
Erosion with a disk radius of 10, 5 and 20

```julia
I = gmtread(TESTSDIR * "assets/chip.png");
J1 = imerode(I, sel=strel("disk", 10));
J2 = imerode(I, sel=strel("disk", 5));
J3 = imerode(I, sel=strel("disk", 20));
grdimage(I, figsize=6)
grdimage!(J1, figsize=6, xshift=6.1)
grdimage!(J2, figsize=6, xshift=-6.1, yshift=-6.1)
grdimage!(J3, figsize=6, xshift=-6.1, show=true)
```
"""
function imerode(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3, sel=nothing)::GMTimage
	helper_morph(I, hsize, vsize, "erode", sel)
end

# ---------------------------------------------------------------------------------------------------
"""
    J = imdilate(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3, sel=nothing)::GMTimage

Dilate the grayscale or binary image I.

The dilation is performed with a matrix of 0’s and 1’s with width `hsize` and height `vsize`, or, if possible,
with the structuring element `sel`. Later case is faster but it is only available for binary images, where by
_binary_ images we mean Boolean images or images with only 0’s and 1’s of UInt8 type.

### Args
- `I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}`: Input image.

### Kwargs
- `hsize::Int=3`: Horizontal size of the 'box' structuring element.
- `vsize::Int=3`: Vertical size of the 'box' structuring element.
- `sel=nothing`: Structuring element (See ``strel`` function). An alternative to `hsize` and `vsize` options.
  If equal to ``nothing``, a structuring box of size `hsize` x `vsize` is used.

### Returns
A new `GMTimage` of the same type as `I` with the dilation applied.

### Example
Dilation with a square of width 3 (the default when neither `sel`, nor `hsize` or `vsize` are specified)

```julia
I = gmtread(TESTSDIR * "assets/fig_text_bw.png");
J = imdilate(I);
grdimage(I, figsize=7)
grdimage!(J, figsize=7, xshift=7.1, show=true)
```
"""
function imdilate(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3, sel=nothing)::GMTimage
	helper_morph(I, hsize, vsize, "dilate", sel)
end

# ---------------------------------------------------------------------------------------------------
"""
    J = imopen(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3, sel=nothing)::GMTimage

Open the grayscale or binary image I.

The morphological opening operation is an erosion followed by a dilation, using the same structuring
element for both operations.
The opening is performed with a matrix of 0’s and 1’s with width `hsize` and height `vsize`, or, if possible,
with the structuring element `sel`. Later case is faster but it is only available for binary images, where by
_binary_ images we mean Boolean images or images with only 0’s and 1’s of UInt8 type.

### Args
- `I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}`: Input image.

### Kwargs
- `hsize::Int=3`: Horizontal size of the 'box' structuring element.
- `vsize::Int=3`: Vertical size of the 'box' structuring element.
- `sel=nothing`: Structuring element (See ``strel`` function). An alternative to `hsize` and `vsize` options.
  If equal to ``nothing``, a structuring box of size `hsize` x `vsize` is used.

### Returns
A new `GMTimage` of the same type as `I` with the opening applied.

### Example

Illustration of opening with a structuring box of width 20

```julia
I = gmtread(TESTSDIR * "assets/packman.png");
J = imopen(I, sel=strel("box", 20));
grdimage(I, figsize=7)
grdimage!(J, figsize=7, xshift=7.1, show=true)
```
"""
function imopen(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3, sel=nothing)::GMTimage
	helper_morph(I, hsize, vsize, "open", sel)
end

# ---------------------------------------------------------------------------------------------------
"""
    J = imclose(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3, sel=nothing)::GMTimage

Close the grayscale or binary image I.

The morphological close operation is a dilation followed by an erosion, using the same structuring element
for both operations.
The closing is performed with a matrix of 0’s and 1’s with width `hsize` and height `vsize`, or, if possible,
with the structuring element `sel`. Later case is faster but it is only available for binary images, where by
_binary_ images we mean Boolean images or images with only 0’s and 1’s of UInt8 type.

### Args
- `I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}`: Input image.

### Kwargs
- `hsize::Int=3`: Horizontal size of the 'box' structuring element.
- `vsize::Int=3`: Vertical size of the 'box' structuring element.
- `sel=nothing`: Structuring element (See ``strel`` function). An alternative to `hsize` and `vsize` options.
  If equal to ``nothing``, a structuring box of size `hsize` x `vsize` is used.

### Returns
A new `GMTimage` of the same type as `I` with the closing applied.

### Example

Illustration of closing with a structuring box of width 20

```julia
I = gmtread(TESTSDIR * "assets/packman.png");
J = imclose(I, sel=strel("box", 20));
grdimage(I, figsize=7)
grdimage!(J, figsize=7, xshift=7.1, show=true)
```
"""
function imclose(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3, sel=nothing)::GMTimage
	helper_morph(I, hsize, vsize, "close", sel)
end

# ---------------------------------------------------------------------------------------------------
"""
    J = imtophat(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3)::GMTimage

Do a morphological top-hat operation on a grayscale or binary image.

Top-hat computes the morphological opening of the image and does a: `orig_image - opening`

This transform can be used to enhance contrast in a grayscale image with nonuniform
illumination. It can also isolate small bright objects in an image.

### Args
- `I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}`: Input image.

### Kwargs
- `hsize::Int=3`: Horizontal size of the 'box' structuring element.
- `vsize::Int=3`: Vertical size of the 'box' structuring element.

### Returns
A new `GMTimage` of the same type as `I` with the tophat applied.

### Example
Perform the top-hat filtering and display the image.

```julia
I = gmtread(TESTSDIR * "assets/rice.png");
J = imtophat(I, hsize=11, vsize=11);
grdimage(I, figsize=6)
grdimage!(J, figsize=6, xshift=6, show=true)
```
"""
function imtophat(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3)::GMTimage
	helper_morph(I, hsize, vsize, "tophat", nothing)
end

# ---------------------------------------------------------------------------------------------------
"""
    J = imbothat(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3)::GMTimage

Do a morphological bop-hat operation on a grayscale or binary image.

Bottom-hat computes the morphological closing of the image and does a: `closing - orig_image`
This transform isolates pixels that are darker than other pixels in their neighborhood.

### Args
- `I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}`: Input image.

### Kwargs
- `hsize::Int=3`: Horizontal size of the 'box' structuring element.
- `vsize::Int=3`: Vertical size of the 'box' structuring element.

### Returns
A new `GMTimage` of the same type as `I` with the bothat applied.
"""
function imbothat(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3)::GMTimage
	helper_morph(I, hsize, vsize, "bothat", nothing)
end

# ---------------------------------------------------------------------------------------------------
"""
    J = bwhitmiss(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}, interval::Matrix{<:Integer})::GMTimage

Performs the hit-miss operation on a binary image defined in terms of a matrix called an _interval_.

An _interval_ is a matrix whose elements are 0 or 1 or 2 and results from _joining_ two structural
elements SE1 and SE2. 0's are ignored. The 1's make up the domain of SE1 and the 2's the domain of SE2.

### Args
- `I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}`: Input image.

### Kwargs
- `hsize::Int=3`: Horizontal size of the 'box' structuring element.
- `vsize::Int=3`: Vertical size of the 'box' structuring element.
- `smooth::Int=0`: Half-width of convolution smoothing filter. The width is (2 * smoothing + 1), so 0 is no-op.

### Returns
A new `GMTimage` of the same type as `I` with the hitmiss applied.

### Example (from the DIP book)

Consider the task of locating upper-left corner pixels of objects in an bw image. We want to locate
foreground pixels that have east and south neighbors (these are 'hits') and that have no northeast, northwest,
west or southwest neighbors (these are 'misses'). These requirements lead to the following interval matrix:

```julia
interval = [2 2 2; 2 1 1; 2 1 0];
I = gmtread(TESTSDIR * "assets/small_squares.png");
J = bwhitmiss(I, interval);
grdimage(I, figsize=6)
grdimage!(J, figsize=6, xshift=6.05, show=true)
```
"""
function bwhitmiss(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}, interval)::GMTimage
	helper_morph(I, 0, 0, "hitmiss", strel(interval))
end

# ---------------------------------------------------------------------------------------------------
"""
    J = imhdome(I::GMTimage{<:UInt8, 2}, H; conn=4)::GMTimage

### Args
- `I::GMTimage{<:UInt8, 2}`: Input image.
- `H`: height below the filling maskhdome; must be >= 0 (words of the Leptonica pixHDome() docs)

### Kwargs
- `conn::Int=4`: Connectivity value used to identify the regional maxima in I (4 or 8). Default is 4.

### Returns
A new ``GMTimage`` of the same type as `I`.

"""
function imhdome(I::GMTimage{<:UInt8, 2}, height; conn=4)::GMTimage
	@assert conn == 4 || conn == 8 "Only conn=4 or conn=8 are supported"
	helper_morph(I, height, conn, "hdome", nothing)
end

# ---------------------------------------------------------------------------------------------------
"""
    J = imhmin(I::GMTimage{<:UInt8, 2}, H; conn=4)::GMTimage

Suppress regional minima in image using H-minima transform.

The H-minima transform decreases the depth of all regional minima by an amount up to `H`. As a result,
the transform fully suppresses regional minima whose depth is less than `H`. Regional minima are
connected pixels with the same intensity value, t, that are surrounded by pixels with an intensity
value greater than t.

### Args
- `I::GMTimage{<:UInt8, 2}`: Input image.
- `H`: Bump's maximum regional depth.

### Kwargs
- `conn::Int=4`: Connectivity value used to identify the regional maxima in I (4 or 8). Default is 4.

### Returns
A new ``GMTimage`` of the same type as `I`.

### Example

```julia
a = fill(UInt8(10),10,10);
a[2:4,2:4] .= 7;  
a[6:8,6:8] .= 2;
a[1:3,7:9] .= 13;
a[2,8] .= 10;
I = imhmin(mat2img(a), 4);
```
"""
function imhmin(I::GMTimage{<:UInt8, 2}, height; conn=4)::GMTimage
	@assert conn == 4 || conn == 8 "Only conn=4 or conn=8 are supported"
	helper_morph(I, height, conn, "hmin", nothing)
end

# ---------------------------------------------------------------------------------------------------
"""
    J = imhmax(I::GMTimage{<:UInt8, 2}, H; conn=4)::GMTimage

Suppress regional maxima in image using H-maxima transform.

The H-maxima transform decreases the height of all regional maxima by an amount up to `H`. As a result,
the transform fully suppresses regional maxima whose height is less than `H`. Regional maxima are connected
pixels with the same intensity value, t, that are surrounded by pixels with an intensity value less than t.

### Args
- `I::GMTimage{<:UInt8, 2}`: Input image.
- `H`: Bump's maximum regional height.

### Kwargs
- `conn::Int=4`: Connectivity value used to identify the regional maxima in I (4 or 8). Default is 4.

### Returns
A new ``GMTimage`` of the same type as `I`.

### Example

```julia
a = fill(UInt8(10),10,10);
a[2:4,2:4] .= UInt8(13);
a[6:8,6:8] .= UInt8(18);
I = imhmax(mat2img(a), 4);
```
"""
function imhmax(I::GMTimage{<:UInt8, 2}, height; conn=4)::GMTimage
	@assert conn == 4 || conn == 8 "Only conn=4 or conn=8 are supported"
	helper_morph(I, height, conn, "hmax", nothing)
end

# ---------------------------------------------------------------------------------------------------
"""
	J = immorphgrad(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3, smooth=0)::GMTimage

Compute the morphological gradient of a grayscale or binary image.

This is the difference between dilation and erosion of an image. The parameter `smooth` can be used to
smooth the result.

### Args
- `I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}`: Input image.

### Kwargs
- `hsize::Int=3`: Horizontal size of the 'box' structuring element.
- `vsize::Int=3`: Vertical size of the 'box' structuring element.
- `smooth::Int=0`: Half-width of convolution smoothing filter. The width is (2 * smoothing + 1), so 0 is no-op.

### Returns
A new `GMTimage` of the same type as `I` with the morphological gradient applied.

### Example

The result will look like the outline of the object. 

```julia
I = gmtread(TESTSDIR * "assets/j.png");
J = immorphgrad(I, hsize=5, vsize=5);
grdimage(I, figsize=5)
grdimage!(J, figsize=5, xshift=5, show=true)
```
"""
function immorphgrad(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize::Int=3, vsize::Int=3, smooth::Int=0)::GMTimage
	vs = (smooth > 0) ? parse(Int, bitstring(UInt32(vsize)) * bitstring(UInt32(smooth)); base=2) : vsize 	# Overload to condense 2in1
	helper_morph(I, hsize, vsize, "mgrad", nothing)
end

# ---------------------------------------------------------------------------------------------------
"""
    J = bwperim(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize=3, vsize=3, sel=nothing)::GMTimage

Find perimeter of objects in binary image I.

A pixel is part of the perimeter if it is nonzero and it is connected to at least one zero-valued pixel.
To detect the image's perimeter, the structuring element should a box of size `3 x 3` (or, better, use the defaults),
but a different sizes can be provided. This operation, consisting on subtracting an erosion of `I` from `I`,
is alsoknown as a morphological `internal gradient`.

### Args
- `I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}`: Input image.

### Kwargs
- `hsize::Int=3`: Horizontal size of the 'box' structuring element.
- `vsize::Int=3`: Vertical size of the 'box' structuring element.
- `sel=nothing`: Structuring element (See ``strel`` function). An alternative to `hsize` and `vsize` options.
  If equal to ``nothing``, a structuring box of size `hsize` x `vsize` is used.

### Returns
A new `GMTimage` of the same type as `I` with the perimeter.

### Example

```julia
I = gmtread(TESTSDIR * "assets/circles.png");
J = bwperim(I);
grdimage(I, figsize=6)
grdimage!(J, figsize=6, xshift=6, show=true)
```
"""
function bwperim(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; hsize::Int=3, vsize::Int=3, sel=nothing)::GMTimage
	helper_morph(I, hsize, vsize, "perim", sel)
end

# ---------------------------------------------------------------------------------------------------
"""
    J = bwskell(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; type::Int=1, maxiters::Int=0, conn::Int=4)::GMTimage

Reduce all objects to lines in 2-D binary image.

Reduces all objects in the 2-D binary image `I` to 1-pixel wide curved lines, without changing the essential
structure of the image. This process, called skeletonization, extracts the centerline while preserving the topology.

### Args
- `I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}`: Input image.

### Kwargs
- `type::Int=1`: 1 To thin the foreground (normal situation), or 2 to thin the background.
- `maxiters::Int=0`: Maximum number of iterations allowed. Use 0 to iterate untill completion.
- `conn::Int=4`: 4 for 4-connectivity, 8 for 8-connectivity.

### Returns
A new `GMTimage` of the same type as `I` with the skeleton.

### Example

```julia
I = gmtread(TESTSDIR * "assets/bone.png");
J = bwskell(I);
grdimage(I, figsize=6)
grdimage!(J, figsize=6, xshift=6, show=true)
```
"""
function bwskell(I::Union{GMTimage{<:UInt8, 2}, GMTimage{<:Bool, 2}}; type::Int=1, maxiters::Int=0, conn::Int=4)::GMTimage
	@assert conn == 4 || conn == 8 "Only conn=4 or conn=8 are supported"
	@assert type == 1 || type == 2 "'type' must be 1 (foreground) or 2 (background)"
	c = bitcat2(type, conn)						# Join type and connectivity in a single number
	helper_morph(I, c, maxiters, "skell", nothing)
end

# ---------------------------------------------------------------------------------------------------
"""
    J = function imsegment(I::GMTimage{<:UInt8, 3}; maxdist::Int=0, maxcolors::Int=0, selsize::Int=3, colors::Int=5)::GMTimage

Unsupervised RGB color segmentation.

For more details see the docs in Leptonica's function ``pixColorSegment`` (in src/colorseg.c).

### Args
- `I::GMTimage{<:UInt8, 3}`: Input RGB image.

### Kwargs
- `maxdist::Int=0`: Maximum euclidean dist to existing cluster.
- `maxcolors::Int=0`: Maximum number of colors allowed in first pass.
- `selsize::Int=3`: Size of the structuring element for closing to remove noise.
- `colors::Int=5`: Number of final colors allowed after 4th pass.

As a very rough guideline (Leptonica docs), given a target value of `colors`, here are
approximate values of `maxdist` and `maxcolors`:

| `colors` | `maxcolors` | `maxdist` |
|----------|-------------|-----------|
| 2        | 4           | 150       |
| 3        | 6           | 100       |
| 4        | 8           | 90        |
| 5        | 10          | 75        |
| 6        | 12          | 60        |
| 7        | 14          | 45        |
| 8        | 16          | 30        |

### Returns
A new, indexed, `GMTimage` with the segmentation.

### Example

This was thought as a simple example but turned out to show a bit tricky result. The image
"bunny_cenora.jpg" is simple and we can clearly see that it has only 6 colors, so we would
expect that ``colors=6`` would do the job. But in fact we need to set ``colors=7`` because
the outline (black) is in fact picked as two different (dark) colors.

```julia
I = gmtread(TESTSDIR * "assets/bunny_cenora.jpg");
J = imsegment(I, colors=7);
grdimage(I, figsize=6)
grdimage!(J, figsize=6, xshift=6, show=true)
```
"""
function imsegment(I::GMTimage{<:UInt8, 3}; maxdist::Int=0, maxcolors::Int=0, selsize::Int=3, colors::Int=5)::GMTimage
	table = [2 150; 3 100; 4 90; 5 75; 6 60; 7 45; 8 30]
	(maxdist == 0 && maxcolors == 0 && 2 <= colors <= 8) && (maxcolors = 2 * colors; maxdist = table[colors-1, 1])
	c = bitcat2(maxcolors, colors)				# Join them in a single number
	d = bitcat2(maxdist, selsize)
	helper_morph(I, c, d, "segment", nothing)
end

# ---------------------------------------------------------------------------------------------------
"""
    J = imrankfilter(I::GMTimage; width::Int=3, height::Int=0, rank=0.5)::GMTimage

Rank order filter.

This defines, for each pixel, a neighborhood of pixels given by a rectangle "centered" on the pixel.
This set of ``width x height`` pixels has a distribution of values, and if they are sorted in increasing
order, we choose the pixel such that rank*(wf*hf-1) pixels have a lower or equal value and (1-rank)*(wf*hf-1)
pixels have an equal or greater value. In other words, `rank=0` returns the minimun, `rank=1` returns
the maximum in box and `rank=0.5` returns the median. Other values return the quantile.

### Args
- `I::GMTimage`: Input image. This can be a RGB, grayscale or a binary image.

### Kwargs
- `width::Int=3`: Width of the filter.
- `height::Int`: Height of the filter (defaults to `width`).
- `rank=0.5`: Rank.

### Returns
A new `GMTimage` of the same type as `I` with the filtered image.

### Example

```julia
I = gmtread(TESTSDIR * "assets/small_squares.png");
J = imrankfilter(I, width=10);
grdimage(I, figsize=6)
grdimage!(J, figsize=6, xshift=6, show=true)
```
"""
function imrankfilter(I::GMTimage; width::Int=3, height::Int=0, rank=0.5)::GMTimage
	(height == 0) && (height = width)
	c = bitcat2(width, height)
	helper_morph(I, c, round(Int, rank * 1000), "rankf", nothing)
end

# ---------------------------------------------------------------------------------------------------
"""
    J = imsobel(I::GMTimage{<:UInt8, 2}; direction::Int=2)::GMTimage

Sobel edge detecting filter.

Returns a binary image BW containing 1s where the function finds edges in the grayscale or binary image I and 0s elsewhere.

### Args
- `I::GMTimage`: Input grayscale image.

### Kwargs
- `direction::Int=2`: Orientation flag: `0` means detect horizontal edges, `1` means vertical and `2` means all edges.

### Returns
A new `GMTimage` grayscale image `I` with the edge detection, edges are brighter.

### Example

Let us vectorize the rice grains in the image "rice.png". The result is not perfect because
the grains in the image's edge are not closed and therefore not filled. And those get polygonized
twice (in and outside) making the red lines look thicker (but they are not, they are just doubled).

```julia
I = gmtread(TESTSDIR * "assets/rice.png");
J = imsobel(I);
BW = binarize(J);
BW = bwskell(BW);	# Skeletize to get a better approximation of the shapes.
BW = imfill(BW);	# Fill to avoid "double" vectorization (outside and inside grain outline)
D = polygonize(BW);
grdimage(I, figsize=5)
grdimage!(J, figsize=5, xshift=5.05)
grdimage!(BW, figsize=5, xshift=-5.05, yshift=-5.05)
grdimage!(I, figsize=5, xshift=5.05, plot=(data=D, lc=:red), show=true)
```
"""
function imsobel(I::GMTimage{<:UInt8, 2}; direction::Int=2)::GMTimage
	@assert 0 <= direction <= 2 "'direction' must be 0 (horizontal), 1 (vertical) or 2 (all edges)"
	helper_morph(I, direction, 0, "sobel", nothing)
end

# ---------------------------------------------------------------------------------------------------
"""
	J = imfilter(I::GMTimage, kernel::Matrix{<:Real}; normalize::Int=1, sep::Bool=false)::GMTimage

Generic convolution filter.

### Args
- `I::GMTimage`: Input image. This can be a RGB or grayscale image.
- `kernel::Matrix{<:Real}`: The filter kernel MxN matrix.

### Kwargs
- `normalize::Int=1`: Normalize the filter to unit sum. This is the default, unless ``sum(kernel) == 0``,
   case in which we change it to 0.
- `sep::Bool=false`: Try to decompose the filter into two 1-D components. If possible, this leads to a faster execution.
   MxN x (m+n) operations, instead of MxN x mxn. Where M,N and m,n are the sizes of the image I and the kernel filter respectively.

### Returns
A new `GMTimage` of the same type as `I` with the filtered image.

### Example

Apply an 3x3 Mean Removal filter to the image "moon.png".

```julia
I = gmtread(TESTSDIR * "assets/moon.png");
J = imfilter(I, [-1 -1 -1; -1 9 -1; -1 -1 -1]);
grdimage(I, figsize=5)
grdimage!(J, figsize=5, xshift=5, show=true)
```
"""
function imfilter(I::GMTimage, kernel::Matrix{<:Real}; normalize::Int=1, sep::Bool=false)::GMTimage
	@assert (eltype(I) == UInt8) "'imfilter' is only available for UInt8 images"
	@assert all(isfinite.(kernel))
	isapprox(sum(kernel), 0, atol=1e-8) && (normalize = 0)
	bpp = (size(I,3) >= 3) ? 32 : 8
	ppixI = img2pix(I, bpp)
	if (sep)  hy, hx = decompose_2D(kernel)  end

	if (sep && !isempty(hy))
		kely = Ref(filtkernel(reshape(hy, 1, length(hy))));		kelx = Ref(filtkernel(reshape(hx, 1, length(hx))))
		if (size(I,3) == 1)  ppix = pixConvolveSep(ppixI.ptr, kelx, kely, 8, normalize)	# 8 => requesting to always return a 8 bpp image
		else                 ppix = pixConvolveRGBSep(ppixI.ptr, kelx, kely)
		end
	else
		kel = Ref(filtkernel(kernel))
		if (size(I,3) == 1)  ppix = pixConvolve(ppixI.ptr, kel, 8, normalize)	# 8 => requesting to always return a 8 bpp image
		else                 ppix = pixConvolveRGB(ppixI.ptr, kel)
		end
	end

	(ppix == C_NULL) && (@warn("Convolution filter operation failed"); return GMTimage())
	pix2img(Sppix(ppix))
end

"""
    J = imregionalmin(GI|mat; maxmin::Int=0)
"""
function imregionalmin(G::Union{GMTgrid, Matrix{<:AbstractFloat}}; maxmin::Int=0)::GMTimage{UInt8, 2}
	I = imagesc(G, cpt="gray")
	imregionalmin(I; maxmin=maxmin)
end

function imregionalmin(I; maxmin::Int=0)::GMTimage{UInt8, 2}
	(eltype(I) == Bool || eltype(I) == UInt8 || size(I,3) == 1) || error("Only 2D UInt8 or Boolean images are supported")
	ppixI = img2pix(I)
	ppixmin = Ref(img2pix(zeros(UInt8, size(I))).ptr)
	r = pixLocalExtrema(ppixI.ptr, maxmin, 0, ppixmin, C_NULL)
	(r == 1) && (@warn("imregionalmin filter operation failed"); return GMTimage())
	pix2img(Sppix(ppixmin[]))
end

"""
    J = imregionalmax(GI|mat; minmax::Int=0)
"""
function imregionalmax(G::Union{GMTgrid, Matrix{<:AbstractFloat}}; minmax::Int=0)::GMTimage{UInt8, 2}
	I = imagesc(G, cpt="gray")
	imregionalmax(I; minmax=minmax)
end

function imregionalmax(I; minmax::Int=0)::GMTimage{UInt8, 2}
	(eltype(I) == Bool || eltype(I) == UInt8 || size(I,3) == 1) || error("Only 2D UInt8 or Boolean images are supported")
	ppixI = img2pix(I)
	ppixmax = Ref(img2pix(zeros(UInt8, size(I))).ptr)
	r = pixLocalExtrema(ppixI.ptr, 0, minmax, C_NULL, ppixmax)
	(r == 1) && (@warn("imregionalmin filter operation failed"); return GMTimage())
	pix2img(Sppix(ppixmax[]))
end

"""
    J = imclearborder(I; conn::Int=4)

Suppress connected components that touch the image border.
"""
function imclearborder(I; conn::Int=4)::GMTimage{UInt8, 2}
	bpp = (eltype(I) == Bool || I.range[6] == 1) ? 1 : 8
	(bpp == 8 && I.range[6] == 255 && I.n_colors == 0 && rem(sum(I.image), 255) == 0) && (bpp = 1)	# A bit risky but not much
	(bpp != 1 || size(I,3) != 1) && error("Only Black&White 2D images are supported")
	ppixI = img2pix(I, bpp)

	ppix = pixRemoveBorderConnComps(ppixI.ptr, conn)
	(ppix == C_NULL) && (@warn("imclearborder filter operation failed"); return GMTimage())
	pix2img(Sppix(ppix))
end

# This does the decomposition of a 2D kernel into 2 1D kernels
# https://www.mathworks.com/matlabcentral/fileexchange/28238-kernel-decomposition
function decompose_2D(h)
	ms, ns = size(h)
	(ms == 1 || ns == 1) && return Float64[], Float64[]
	u, s, v = svd(h)
	tol = maximum(size(h)) * eps(maximum(s))
	rank = sum(s .> tol)
	separable = rank==1
	!separable && return Float64[], Float64[]
	hy = u[:,1] * sqrt(s[1])
	hx = (conj(v[:,1]) * sqrt(s[1]))
	return hy, hx
end

# =====================================================================================================
function helper_morph(I, hsize, vsize, tipo, sel)
	bpp = (eltype(I) == Bool || I.range[6] == 1) ? 1 : 8
	(bpp == 8 && I.range[6] == 255 && I.n_colors == 0 && rem(sum(I.image), 255) == 0) && (bpp = 1)	# A bit risky but not much
	(tipo in ["hitmiss", "perim", "skell"] && bpp != 1) && error("'bwhitmiss' or 'bwperim' are only available for binary images")
	nosel = (tipo in ["skell", "rankf"])		# List of 1 bpp that do not use 'sel'
	(bpp == 1 && !nosel && sel === nothing) && (sel = strel("box", hsize, vsize))
	(tipo in ["tophat", "bothat", "hdome", "hmin", "hmax", "mgrad", "perim", "rankf"]) && (bpp = 8)		# Those must be 8 bpp	
	ppixI = img2pix(I, bpp)
	is3 = (hsize == 1 || hsize == 3) && (vsize == 1 || vsize == 3)	# To use faster methods
	pI = ppixI.ptr			# Short name
	if (tipo == "erode")
		ppix = (bpp == 1) ? pixErode(pI, pI, Ref(sel)) : (is3 && bpp == 8) ? pixErodeGray3(pI, hsize, vsize) : pixErodeGray(pI, hsize, vsize)
	elseif (tipo == "dilate")
		ppix = (bpp == 1) ? pixDilate(pI, pI, Ref(sel)) : (is3 && bpp == 8) ? pixDilateGray3(pI, hsize, vsize) : pixDilateGray(pI, hsize, vsize)
	elseif (tipo == "open")
		ppix = (bpp == 1) ? pixOpen(pI, pI, Ref(sel)) : (is3 && bpp == 8) ? pixOpenGray3(pI, hsize, vsize) : pixOpenGray(pI, hsize, vsize)
	elseif (tipo == "close")
		ppix = (bpp == 1) ? pixClose(pI, pI, Ref(sel)) : (is3 && bpp == 8) ? pixCloseGray3(pI, hsize, vsize) : pixCloseGray(pI, hsize, vsize)
	elseif (tipo == "tophat")
		ppix = pixTophat(pI, hsize, vsize, UInt32(0))	# 0 = L_TOPHAT_WHITE: image - opening
	elseif (tipo == "bothat")
		ppix = pixTophat(pI, hsize, vsize, UInt32(1))	# 1 = L_TOPHAT_BLACK: closing - image
	elseif (tipo == "hitmiss")
		ppix = pixHMT(pI, pI, Ref(sel))
	elseif (tipo in ["hdome", "hmin", "hmax"])
		ppix = pixHDome(pI, hsize, vsize)				# Here hsize = height and vsize = conn
		if (tipo == "hmin")
			ppix = pixAddGray(ppix, ppix, pI)
		elseif (tipo == "hmax")
			_ppix = pixSubtractGray(pI, pI, ppix)		# _ppix == pI (memorywise)
			pixDestroy(Ref(ppix))						# Free ppix to not leak its memory
			ppix = _ppix								# Rename  because letter all cases are 'ppix'
		end
	elseif (tipo == "mgrad")
		smooth = 0
		if (vsize > 10000)								# Here we have overloaded vsize (first 32 bits) with smooth (last 32 bits)
			s = bitstring(vsize)
			vsize = parse(Int, s[1:32]; base=2)
			smooth = parse(Int, s[33:64]; base=2)
		end
		ppix = pixMorphGradient(pI, hsize, vsize, smooth)
	elseif (tipo == "perim")
		ppix = (is3 && bpp == 8) ? pixErodeGray3(pI, hsize, vsize) : pixErodeGray(pI, hsize, vsize)
		_ppix = pixSubtractGray(pI, pI, ppix)			# _ppix == pI (memorywise)
		pixDestroy(Ref(ppix))							# Free ppix to not leak its memory
		ppix = _ppix									# Rename  because letter all cases are 'ppix'
	elseif (tipo == "rankf")
		wf, hf = bituncat2(hsize)
		ppix = pixRankFilter(pI, wf, hf, Float32(vsize/1000))
	elseif (tipo == "segment")
		maxcolors, finalcolors = bituncat2(hsize)
		maxdist, selsize = bituncat2(vsize)
		ppix = pixColorSegment(pI, maxdist, maxcolors, selsize, finalcolors, 0)
		(ppix == C_NULL) && (@warn("'imgsegment': pixColorSegment failed"); return GMTimage())
	elseif (tipo == "skell")
		type, conn = bituncat2(hsize)
		ppix = pixThinConnected(pI, type, conn, vsize)
	elseif (tipo == "sobel")
		ppix = pixSobelEdgeFilter(pI, hsize)
	end
	(ppix == C_NULL) && (@warn("Operation '$(tipo)' failed"); return GMTimage())
	_I = pix2img(Sppix(ppix))
	(eltype(I) == Bool) && (_I = togglemask(_I))		# Probably wrong
	return _I
end

# ---------------------------------------------------------------------------------------------------
"""
    sel = strel(nhood::Matrix{<:Integer})::Sel
or

	sel = strel(name::String, par1::Int, par2::Int=0)::Sel

Create a strel (structuring element) object for morphological operations.

A flat structuring element is a binary valued neighborhood in which the 1's pixels are included in
the morphological computation, and the 0's pixels are not.

### Args
- `nhood`: must be a matrix of 0’s and 1’s.

- `name`: Alternatively, you can specify a structuring element name among:
  ``"cross"``, ``"disk"``, ``"diamond"``, ``"square"``, ``"box"``, and ``"rec"`` or ``"rectangle"``.

- `par1`: Is the radius of the structuring element for ``"disk"`` and ``"diamond"`` and the width
  for the remaining ones.

- `par2`: If provided (the height), all structuring elements become rectangular with a `par1 x par2`
  (width x height) size.

### Returns
A Sel type object.
"""
function strel(nhood::Matrix{<:Integer}; name::String="")::Sel
	sy, sx = size(nhood)
	cy, cx = floor.(Int32, (size(nhood))./2)
	_nhood = Int32.(nhood)
	GC.@preserve _nhood begin
		data = [pointer(_nhood[i,:]) for i in 1:size(_nhood,1)]
		r = Sel(sy, sx, cy, cx, pointer(data), Base.unsafe_convert(Cstring, name))
	end
	return r
end
function strel(nhood::Vector{<:Integer}; name::String="")::Sel	# Because in Julia it's stupidly difficult to create a one col matrix.
	strel(reshape(nhood, (length(nhood), 1)); name=name)
end
function strel(name::String, par1::Int, par2::Int=0)::Sel
	(!(name in ["cross", "disk", "diamond", "square", "box"]) && !startswith(name, "rec")) && error("Unknown structuring element name: $name")
	@assert par1 > 0
	par2 == 0 && (par2 = par1)
	if (name == "disk" || name == "diamond")
		xy = (name == "disk") ? circlepts(par1*1.001) : [-par1 0.0; 0 par1; par1 0; 0 -par1; -par1 0]	# circlepts is from solids.jl
		X,Y = meshgrid(-par1:par1, -par2:par2)
		out = reshape(Int32.(inpolygon([X[:] Y[:]], xy) .>= 0), size(X))
	elseif (name == "cross")	
		out	= zeros(Int32, par1, par2)
		out[:,par1÷2+1] .= 1
		out[par2÷2+1,:] .= 1
	else				# (name == "square" || startswith(name, "rec") || name == "box")
		out	= ones(Int32, par1, par2)
	end
	strel(out, name=name)
end

# ---------------------------------------------------------------------------------------------------
function filtkernel(mat::Matrix{<:Real})::L_Kernel
	sy, sx = size(mat)
	cy, cx = floor.(Int32, (size(mat))./2)
	_mat = Float32.(mat)
	GC.@preserve _mat begin
		data = [pointer(_mat[i,:]) for i in 1:size(_mat,1)]
		r = L_Kernel(sy, sx, cy, cx, pointer(data))
	end
	return r
end

function Base.show(io::IO, ::MIME"text/plain", sel::Sel)::Nothing
	println(io, "Name: ", unsafe_string(sel.name))
	mat = Matrix{Int32}(undef, sel.sy, sel.sx)
	p = unsafe_wrap(Array, sel.data, sel.sy)
	for n = 1:sel.sy
		mat[n,:] .= unsafe_wrap(Array, p[n], sel.sx)
	end
	println(io, display(mat))
end