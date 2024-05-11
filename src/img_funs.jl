"""
    level = isodata(I::GMTimage; band=1) -> Int

`isodata` Computes global image threshold using iterative isodata method that can be used to convert
an intensity image to a binary image with ``binarize`. `level` is a normalized intensity value that lies
in the range [0 255].  This iterative technique for choosing a threshold was developed by Ridler and Calvard.
The histogram is initially segmented into two parts using a starting threshold value such as 0 = 2B-1, 
half the maximum dynamic range. The sample mean (mf,0) of the gray values associated with the foreground
pixels and the sample mean (mb,0) of the gray values associated with the background pixels are computed.
A new threshold value 1 is now computed as the average of these two sample means. The process is repeated,
based upon the new threshold, until the threshold value does not change any more.

Originaly from MATLAB http://www.mathworks.com/matlabcentral/fileexchange/3195 (BSD, Licenced)
"""
function isodata(I::GMTimage; band=1)

	counts, edges = histogray(I, band=band)# returns a histogram of the image
	i = 1
	mu = cumsum(counts)
	T = zeros(Int, length(counts))
	T[i] = round(Int, sum(edges .* counts) / mu[end])

	# STEP  2: compute Mean above T (MAT) and Mean below T (MBT) using T from step  1
	mu2 = cumsum(counts[1:T[i]])
	MBT = sum(edges[1:T[i]] .* counts[1:T[i]]) / mu2[end]

	mu3 = cumsum(counts[T[i]:end])
	MAT = sum(edges[T[i]:end] .* counts[T[i]:end]) / mu3[end]
	i += 1
	T[i] = round(Int, (MAT + MBT) / 2)

	# STEP  3 to n: repeat step  2 if T(i) != T(i-1)
	while abs(T[i] - T[i-1]) >= 1
		mu2 = cumsum(counts[1:T[i]])
		MBT = sum(edges[1:T[i]] .* counts[1:T[i]]) / mu2[end]

		mu3 = cumsum(counts[T[i]:end])
		MAT = sum(edges[T[i]:end] .* counts[T[i]:end]) / mu3[end]

		T[i+=1] = round(Int, (MAT + MBT) / 2)
	end

	round(Int, (T[i] - 1) / (edges[end] - 1) * 255)# Normalize the threshold to the range [0 255].
end

# ---------------------------------------------------------------------------------------------------
"""
    Ibw = binarize(I::GMTimage, threshold; band=1, revert=false) -> GMTimage

Converts an image to a binary image (black-and-white) using a threshold. If `revert=true`, values below the
threshold are set to 255, and values above the threshold are set to 0. If the `I` image has more than one band,
use `band` to specify which one to binarize.
"""
function binarize(I::GMTimage, threshold; band=1, revert=false)
	img = zeros(UInt8, size(I, 1), size(I, 2))
	if revert
		t = view(I.image, :, :, band) .< threshold
	else
		t = view(I.image, :, :, band) .> threshold
	end
	img[t] .= 255
	return mat2img(img, I)
end

# ---------------------------------------------------------------------------------------------------
"""
    Igray = rgb2gray(I) -> GMTimage

Converts an RGB image to a grayscale image applying the television YMQ transformation.
"""
function rgb2gray(I::GMTimage{UInt8, 3})
	img = helper_img_transforms(I, 0.299, 0.587, 0.114)
	mat2img(img, I)
end

# ---------------------------------------------------------------------------------------------------
# Helper function to apply a linear transformation to the image channels
# C1, C2, C3 are the coeficients of the transformation
function helper_img_transforms(I::GMTimage{UInt8, 3}, c1, c2, c3; buf::AbstractMatrix{UInt8}=Matrix{UInt8}(undef,0,0))
	_Img::Array{UInt8,3} = I.image			# If we don't do this it Fck insists I.image is Any and slows down 1000 times
	nxy = size(_Img, 1) * size(_Img, 2)
	img = isempty(buf) ? zeros(UInt8, size(_Img, 1), size(_Img, 2)) : buf
	if (I.layout[3] != 'P')
		@inbounds for ij = 1:nxy
			img[ij] = round(UInt8, c1 * _Img[ij] + c2 * _Img[ij+nxy] + c3 * _Img[ij+2nxy])
		end
	else            # Pixel interleaved case
		i = 0
		@inbounds for ij = 1:3:3nxy
			img[i+=1] = round(UInt8, c1 * _Img[ij] + c2 * _Img[ij+1] + c3 * _Img[ij+2])
		end
	end
	img
end

# ---------------------------------------------------------------------------------------------------
"""
	YCbCr = rgb2YCbCr(I::GMTimage{UInt8, 3}; Y=false, Cb=false, Cr=false, BT709=false)
or

	Y,Cb,Cr = rgb2YCbCr(I::GMTimage{UInt8, 3}; Y=false, Cb=false, Cr=false, BT709=false)

Converts RGB color values to luminance (Y) and chrominance (Cb and Cr) values of a YCbCr image.

Optionally, return only one to three of Y, Cb and Cr in separate images. For that use the `keywords`:
`Y=true`, `Cb=true` or `Cr=true`. Each ``true`` occurence makes it return that component, otherwise it returns an empty image.

The `BT709` option makes it use the ``ITU-R BT.709`` conversion instead of the default ``ITU-R BT.601``.
See https://en.wikipedia.org/wiki/YCbCr

### Examples
```julia
Iycbcr = rgb2YCbCr(mat2img(rand(UInt8, 100, 100, 3))              # A 3D image

_,Cb,Cr = rgb2YCbCr(mat2img(rand(UInt8, 100, 100, 3), Cb=true, Cr=true)     # The Cb and Cr components

Cb = rgb2YCbCr(mat2img(rand(UInt8, 100, 100, 3), Cb=true)[2]      # The Cb component
```
"""
function rgb2YCbCr(I::GMTimage{UInt8, 3}; Y=false, Cb=false, Cr=false, BT709=false)
	if (BT709 == 0)
		c = [65.481 128.553 24.966; -37.797 -74.203 112; 112 -93.786 -18.214] / 255.0
		a1, a2 = 16.0, 128.0
	else
		c = [0.2126 0.7152 0.0722; -0.1146 -0.3854 0.499999; 0.499999 -0.4542 -0.0458]
		a1, a2 = 127.0, 127.0
	end
	composite = (Y != 0 || Cb != 0 || Cr != 0) ? false : true
	if (composite)
		img = zeros(UInt8, size(I))
		img[:,:,1] .= helper_rgb2ycbcr(I, c[1,1],  c[1,2], c[1,3], a1; buf=view(I.image, :,:,1))
		img[:,:,2] .= helper_rgb2ycbcr(I, c[2,1],  c[2,2], c[2,3], a2; buf=view(I.image, :,:,2))
		img[:,:,3] .= helper_rgb2ycbcr(I, c[3,1],  c[3,2], c[3,3], a2; buf=view(I.image, :,:,3))
		return mat2img(img, I)
	end
	_Y  = (Y  != 0) ? mat2img(helper_rgb2ycbcr(I, c[1,1],  c[1,2], c[1,3], a1), I) : GMTimage()
	_Cb = (Cb != 0) ? mat2img(helper_rgb2ycbcr(I, c[2,1],  c[2,2], c[2,3], a2), I) : GMTimage()
	_Cr = (Cr != 0) ? mat2img(helper_rgb2ycbcr(I, c[3,1],  c[3,2], c[3,3], a2), I) : GMTimage()
	return _Y, _Cb, _Cr
end
const rgb2ycbcr = rgb2YCbCr			# Alias

# ---------------------------------------------------------------------------------------------------
function helper_rgb2ycbcr(I::GMTimage{UInt8,3}, c1, c2, c3, add; buf::AbstractMatrix{UInt8}=Matrix{UInt8}(undef,0,0))
	_Img::Array{UInt8,3} = I.image			# If we don't do this it F insists I.image is Any and slows down 1000 times
	nxy::Int = size(_Img, 1) * size(_Img, 2)
	img = isempty(buf) ? zeros(UInt8, size(_Img, 1), size(_Img, 2)) : buf
	if (I.layout[3] != 'P')
		@inbounds for ij = 1:nxy
			img[ij] = round(UInt8, add + c1 * _Img[ij] + c2 * _Img[ij+nxy] + c3 * _Img[ij+2nxy])
		end
	else
		i = 0
		@inbounds for ij = 1:3:3nxy
			img[i+=1] = round(UInt8, add + c1 * _Img[ij] + c2 * _Img[ij+1] + c3 * _Img[ij+2])
		end
	end
	img
end

#= ---------------------------------------------------------------------------------------------------
function padarray(a, p)
	h, w = size(a)
	y = clamp.((1-p[1]):(h+p[1]), 1, h)
	x = clamp.((1-p[2]):(w+p[2]), 1, w)
	return a[y, x]
end
=#
