
"""
	img2pix(I::GMTimage)::Sppix
or

	img2pix(mat::Matrix{<:Integer}; layout="TRBa")::Sppix

Convert an image to a Sppix object (a structure with a pointer to a Leptonica Pix).

Inputs can be UInt8 or Boolean matrices or GMTimages.
"""
function img2pix(mat::Matrix{<:Integer}, bpp=8; layout="TRBa")::Sppix
	@assert isa(layout, String) && length(layout) >= 3
	img2pix(mat2img(mat, layout=layout), bpp=bpp)
end
function img2pix(I::GMTimage{<:Integer, 2}, bpp=8)::Sppix		# Minimalist. Still doesn't have a colormap and not yet RGB(A)
	# The Leptonoica library has (in fact it almost hasn't) an awfull documentation.
	# I was able, however, to find a way to create and fill a Pix object with a matrix. The trick is to
	# create a Pix object with the right size and then fill it with the matrix data. The pixSetupByteProcessing()
	# function is the key. It seems to deal well with the difficulty of the data padding per row.
	# However, the same does not work for 1 bpp (binary) images. The trick is to create a 8 bpp image with the
	# the same number of bits per row as the 1 bpp image, work on the bits and then convert to 1 bpp.
	width, height = GMT.getsize(I)
	_width = (bpp == 8) ? width : ceil(Int, width/8)
	ppix = pixCreate(_width, height, 8)					# Create an empty Pix
	w, h = Ref{Cint}(0), Ref{Cint}(0)
	plineptrs = pixSetupByteProcessing(ppix, w, h)
	lineptrs = unsafe_wrap(Array, plineptrs, h[])		# ::Vector{Ptr{UInt8}}
	if (bpp == 8)
		if (I.layout[2] == 'R')
			k = 0
			for i = 1:h[]
				line = unsafe_wrap(Array, lineptrs[i], w[])
				for j = 1:w[]  line[j] = UInt8(I.image[k+=1])  end
			end
		else					# Column major must be written in row major
			for i = 1:h[]
				line = unsafe_wrap(Array, lineptrs[i], w[])
				for j = 1:w[]  line[j] = UInt8(I.image[i,j])  end
			end
		end
	else					# bpp == 1
		resto = rem(width, 8)
		cols_iter = (resto == 0) ? (1:_width) : (1:(_width-1))
		if (I.layout[2] == 'R')
			k = 0
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
		else
			for i = 1:h[]
				line = unsafe_wrap(Array, lineptrs[i], w[])
				for j = cols_iter
					for n = 7:-1:0
						UInt8(I.image[i,j]) != 0 && (line[j] = line[j] | UInt8(1) << UInt8(n))
					end
				end
				if (resto != 0)
					for n = resto-1:-1:0
						(I.image[i,j+n+1] != 0) && (line[_width] = line[_width] | UInt8(1) << UInt8(n))
					end
				end
			end
		end
	end
	pixCleanupByteProcessing(ppix, plineptrs)
	if (bpp == 1)
		pixSetDepth(ppix, 1)
		pixSetWidth(ppix, width)		# Set the true width for 1 bpp
		#pixSetWpl(ppix, 8)
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
		u255 = UInt8(255)
		masks8 = [1,2,4,8,16,32,64,128]
		k, m = 1, 0
		resto = rem(width, 8)
		width8 = ceil(Int, width/8)
		cols_iter = (resto == 0) ? (1:width8) : (1:width8-1)
		for i = 1:height
			for j = cols_iter
				t = r[m+=1]
				for n = 7:-1:0
					#((t & u1) == u1) && (mat[k] = u255);	t = t >> u1
					(((t & masks8[n+1]) >> n) == 1) && (mat[k] = u255)
					k += 1
				end
			end
			if (resto != 0)
				t = r[m+=1]
				for n = resto-1:-1:0
					(((t & masks8[n+1]) >> n) == 1) && (mat[k] = u255)
					k += 1
				end
			end
		end
		pixSetDepth(ppix.ptr, 1)			# Reset the original bpp
		pixSetWidth(ppix.ptr, width)		# Same for width
		mat2img(mat, layout="TRBa", is_transposed=true)
	else
		mat2img(reshape(r, (pixGetWidth(ppix.ptr), pixGetHeight(ppix.ptr))), layout="TRBa", is_transposed=true)
	end
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
I = gmtread("C:\\programs\\MATLAB\\R2024b\\toolbox\\images\\imdata\\coins.png");
Ibw = binarize(I);
BW2 = imfill(Ibw);
```
"""
function imfill(mat::Matrix{<:Integer}; conn=4, is_transposed=true, layout="TRBa")
	@assert conn == 4 || conn == 8 "Only conn=4 or conn=8 are supported"
    mask = padarray(mat, ones(Int, 1, ndims(mat)), padval=-Inf)		# 'mask' is always a matrix
	GMT.imcomplement!(mask)
    marker = copy(mask)

	marker[2:end-1, 2:end-1] .= typemin(eltype(mat))
    I2 = imreconstruct(marker, mask, conn=conn, is_transposed=is_transposed, layout=layout)
	GMT.imcomplement!(I2)
	I2 = I2[2:end-1, 2:end-1]
	(eltype(mat) <: Bool) && (I2 = collect(I2 .== 255))
	return I2
end
function imfill(I::GMTimage; conn=4)::GMTimage
	mat2img(imfill(I.image; conn=conn, is_transposed=(GMT.getsize(I) == size(I) && I.layout[2] == 'R'), layout=I.layout), I)
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
operates on UInt8 matrices only the vertical (z) descrimination of the grid is reduced to 256 levels,
which is not that much.

### Args
- `G::GMTgrid`: The input grid to process.

### Kwargs
- `conn::Int`: Connectivity for sink filling (4 or 8). Default is 4.
- `region`: Limit the action to a region of the grid specified by `region`. See for example the ``coast``
  manual for and extended doc on this keword, but note that here only `region` is accepted and not `R`, etc...
- `saco::Bool`: Save the lines (GMTdataset ~contours) used to fill the sinks in a global variable called
  GMT.SACO. This is intended to avoid return them all the time when function ends. This global variable
  is a ``[Dict{String,Union{AbstractArray, Vector{AbstractArray}}}()]``, so to access its contents you must use:

  ``D = get(GMT.SACO[1], "saco", nothing)``, where ``D`` is now a GMTdataset or a vector of them.

  NOTE: It is the user's responsibility to empty this global variable when it is no longer needed.

  You do that with: ``delete!(GMT.SACO[1], "saco")``
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
plot!(get(GMT.SACO[1], "saco", nothing), color=:white, show=true)
```
"""
function fillsinks(G::GMTgrid; conn=4, region=nothing, saco=false, insitu=false)
	I = imagesc(G, region=region)
	I2 = imfill(I, conn=conn)
	d = (I .== I2')
	D = polygonize(d)
	if (saco == 1)
		Dtrk = grdtrack(G, D)
		means = isa(D, Vector) ? median.(Dtrk) : median(Dtrk)
		GMT.SACO[1] = Dict("saco" => Dtrk)			# Save the grdtrack interpolated lines for eventual external use.
	else
		means = isa(D, Vector) ? median.(grdtrack(G, D, o=2)) : median(grdtrack(G, D, o=2))	# The mean of each interpolated contour
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

function helper_morph(I, hsize, vsize, tipo, sel)
	bpp = (eltype(I) == Bool || I.range[6] == 1) ? 1 : 8
	(bpp == 1 && sel === nothing) && (sel = strel("box", hsize1, vsize))#(bpp = 8)
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
	end
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
  ``"disk"``, ``"diamond"``, ``"square"``, ``"box"``, and ``"rec"`` or ``"rectangle"``.

- `par1`: Is the radius of the structuring element for ``"disk"`` and ``"diamond"`` and the width
  for the remaining ones.

- `par2`: If provided (the height), all structuring elements become rectangular with a `par1 x par2`
  (width x height) size.

### Returns
A Sel type object.

"""
function strel(nhood::Matrix{<:Integer}; name::String="")::Sel
	sy, sx = size(nhood)
	cx, cy = floor.(Int32, (size(nhood))./2)
	_nhood = Int32.(nhood)
	data = [pointer(_nhood[:,i]) for i in 1:size(_nhood,1)]
	Sel(sy, sx, cy, cx, pointer(data), Base.unsafe_convert(Cstring, name))
end
function strel(name::String, par1::Int, par2::Int=0)::Sel
	(!(name in ["disk", "diamond", "square", "box"]) && !startswith(name, "rec")) && error("Unknown structuring element name: $name")
	@assert par1 > 0
	par2 == 0 && (par2 = par1)
	if (name == "disk" || name == "diamond")
		xy = (name == "disk") ? circlepts(par1*1.001) : [-par1 0.0; 0 par1; par1 0; 0 -par1; -par1 0]	# circlepts is from solids.jl
		X,Y = meshgrid(-par1:par1, -par2:par2)
		out = reshape(Int32.(inpolygon([X[:] Y[:]], xy) .>= 0), size(X))
	else				# (name == "square" || startswith(name, "rec") || name == "box")
		out	= ones(Int32, par1, par2)
	end
	strel(out, name=name)
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