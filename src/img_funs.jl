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
function rgb2gray(I::GMTimage)
    nxy = size(I, 1) * size(I, 2)
    img = zeros(UInt8, size(I, 1), size(I, 2))
    if (I.layout[3] != 'P')
        @inbounds for ij = 1:nxy
            img[ij] = round(UInt8, 0.299 * I.image[ij] + 0.587 * I.image[ij+nxy] + 0.114 * I.image[ij+2nxy])
        end
    else            # Pixel interleaved case
        i = 0
        @inbounds for ij = 1:3:3nxy
            img[i+=1] = round(UInt8, 0.299 * I.image[ij] + 0.587 * I.image[ij+1] + 0.114 * I.image[ij+2])
        end
    end
    mat2img(img, I)
end

#= ---------------------------------------------------------------------------------------------------
function padarray(a, p)
	h, w = size(a)
	y = clamp.((1-p[1]):(h+p[1]), 1, h)
	x = clamp.((1-p[2]):(w+p[2]), 1, w)
	return a[y, x]
end
=#
