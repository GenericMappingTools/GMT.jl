
function img2pix(mat::Matrix{UInt8}; layout="TRBa")::Sppix
	@assert isa(layout, String) && length(layout) >= 3
	img2pix(mat2img(mat, layout=layout))
end
function img2pix(I::GMTimage{UInt8, 2})::Sppix
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
				line[j] = I.image[k+=1]
			end
		end
	else					# Column major must be written in row major
		for i = 1:h[]
			line = unsafe_wrap(Array, lineptrs[i], w[])
			for j = 1:w[]
				line[j] = I.image[i,j]
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
function imreconstruct(Iseed::GMTimage, Imask::Union{GMTimage{<:UInt8, 2}, Matrix{UInt8}}; conn=4, insitu=true)::GMTimage
	ppixIs = img2pix(Iseed)
	ppixIm = img2pix(Imask)
	p = (insitu == 1) ? ppixIs : pixCopy(C_NULL, ppixIs)	# pixCopy is a shallow copy that does duplicate data. So this is wrong
	pixSeedfillGray(p.ptr, ppixIm.ptr, conn)		# The image in 'p' is modified
	pix2img(p)
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

#r = Ref(tuple(5.0, 2.0, 1.0, 6.0))
#p = Base.unsafe_convert(Ptr{Float64}, r)
#u = unsafe_wrap(Array, p, 4)

# ---------------------------------------------------------------------------------------------------
function imfill(mat::Matrix{<:Real}; conn=4, is_transposed=false)
    #if (eltype(I) == Bool)  mask = togglemask(mat)
    #else                    mask = I;
	#end
    mask = padarray(mat, ones(Int, 1, ndims(mat)), padval=-Inf)		# 'mask' is always a matrix
	GMT.imcomplement!(mask)
    marker = copy(mask)

	marker[2:end-1, 2:end-1] .= typemin(eltype(mat))
    I2 = imreconstruct(marker, mask, conn=conn, is_transposed=is_transposed)
	GMT.imcomplement!(I2)
	I2 = I2[2:end-1, 2:end-1]
	isa(eltype(mat), Bool) && (I2 = (I2 .!= 0))
	return I2
end
function imfill(I::GMTimage; conn=4)::GMTimage
	mat2img(imfill(I.image; conn=conn, is_transposed=(GMT.getsize(I) == size(I) && I.layout[2] == 'R')), I)
end
