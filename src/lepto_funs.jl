
function img2pix(mat::Matrix{<:Integer}; layout="TRBa")::Sppix
	@assert isa(layout, String) && length(layout) >= 3
	img2pix(mat2img(mat, layout=layout))
end
function img2pix(I::GMTimage{<:Integer, 2})::Sppix
	# Minimalist. Still doesn't have a colormap and not yet RGB(A)

	width, height = GMT.getsize(I)
	ppix = pixCreate(width, height, 8)		# Create an empty Pix
	w,h = Ref{Cint}(0), Ref{Cint}(0)
	plineptrs = pixSetupByteProcessing(ppix, w,h)
	lineptrs = unsafe_wrap(Array, plineptrs, h[])		# ::Vector{Ptr{UInt8}}
	if (I.layout[2] == 'R')
		k = 0
		for i = 1:h[]
			line = unsafe_wrap(Array, lineptrs[i], w[])
			for j = 1:w[]
				line[j] = UInt8(I.image[k+=1])
			end
		end
	else					# Column major must be written in row major
		for i = 1:h[]
			line = unsafe_wrap(Array, lineptrs[i], w[])
			for j = 1:w[]
				line[j] = UInt8(I.image[i,j])
			end
		end
	end
	pixCleanupByteProcessing(ppix, plineptrs)
	return Sppix(ppix)
end

function pix2img(ppix::Sppix)::GMTimage
	pdata = Ref{Ptr{UInt8}}()
	pnbytes = Ref{Csize_t}()
	pixGetRasterData(ppix.ptr, pdata, pnbytes)
	r = unsafe_wrap(Array, pdata[], pnbytes[], own=true)
	mat2img(reshape(r, (pixGetWidth(ppix.ptr), pixGetHeight(ppix.ptr))), layout="TRBa")
end

# ---------------------------------------------------------------------------------------------------
"""
### Examlple
```julia
I = gmtread("C:\\programs\\MATLAB\\R2024a\\toolbox\\images\\imdata\\text.png");
marker = fill(UInt8(0),(size(I)));
marker[94,13] = UInt8(255);
Im = mat2img(marker, I);
im = imreconstruct(Im, I)
```
"""
function imreconstruct(seed::Union{Matrix{Bool}, Matrix{UInt8}}, Imask::GMTimage{<:UInt8, 2}; conn=4, insitu=true)::GMTimage
	Iseed = mat2img(seed, Imask)
	isa(eltype(Iseed), Bool) && (Iseed = togglemask(Iseed))
	imreconstruct(Iseed, Imask; conn=conn, insitu=insitu)
end
function imreconstruct(Iseed::GMTimage{<:Integer, 2}, Imask::Union{GMTimage{<:Integer, 2}, Matrix{<:Integer}}; conn=4, insitu=true)::GMTimage
	ppixIs = img2pix(Iseed)
	ppixIm = img2pix(Imask)
	p = (insitu == 1) ? ppixIs : pixCopy(C_NULL, ppixIs)	# pixCopy is a shallow copy that does duplicate data. So this is wrong
	pixSeedfillGray(p.ptr, ppixIm.ptr, conn)		# The image in 'p' is modified
	I = pix2img(p)
	#isa(eltype(Iseed), Bool) && (I = togglemask(I))
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
- `conn::Int`: Connectivity for sink filling (4 or 8). Default is 4.
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
    #if (eltype(I) == Bool)  mask = togglemask(mat)
    #else                    mask = I;
	#end
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
	fillsinks(G::GMTgrid; conn=4, insitu=false)

Fill sinks in a grid.

This function uses the ``imfill`` function to find how to fill sinks in a grid. But since ``imfill``
operates on UInt8 matrices only the vertical (z) descrimination of the grid is reduced to 256 levels,
which is not that much.

### Args
- `G::GMTgrid`: The input grid to process.

### Kwargs
- `conn::Int`: Connectivity for sink filling. Default is 4.
- `insitu::Bool`: If `true`, modify the grid in place. Default is `false`.
  Alternatively, use the conventional form ``fillsinks!(G; conn=4)``.

### Returns
- A new `GMTgrid` with sinks filled, unless `insitu` is `true`, in which case the input grid is modified and returned.

### Examples
```julia
G = peaks();
G2 = fillsinks(G)
viz(G2, shade=true)
```
"""
fillsinks!(G::GMTgrid; conn=4) = fillsinks(G; conn=conn, insitu=true)
function fillsinks(G::GMTgrid; conn=4, insitu=false)
	I = imagesc(G)
	I2 = imfill(I, conn=conn)
	d = (I .== I2')
	D = polygonize(d)
	means = isa(D, Vector) ? median.(grdtrack(G, D, o=2)) : median(grdtrack(G, D, o=2))	# The mean of each interpolated contour
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
