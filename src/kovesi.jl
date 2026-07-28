# Phase Preserving Dynamic Range Compression and related functions
# Converted from MATLAB code by Peter Kovesi
#
# Copyright (c) 2012-2014 Peter Kovesi
# Centre for Exploration Targeting
# The University of Western Australia
# peter.kovesi at uwa edu au
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# The Software is provided "as is", without warranty of any kind.
#
# NO FFTW: the two forward/inverse transforms go through `fft2d` (GMT's own GMT_FFT_2D), same rule
# as fft1d/rtp3d — everything Fourier in GMT.jl is computed by the GMT C library. The NaN infill
# uses GMT's own `bwdist_idx` (imgmorph/bwdist.jl) rather than a private distance transform.

"""
    kovesi(im; wavelength=nothing, clip=0.01, n=2)

Phase Preserving Dynamic Range Compression

Generates a dynamic range compressed image at a specified scale. This function is
designed to reveal subtle features within high dynamic range images such as
aeromagnetic and other potential field grids.

Phase Preserving Dynamic Range Compression allows subtle features to be revealed
without perceptual distortions. Perceptually important phase information is preserved
and the contrast amplification of anomalies in the signal is purely a function of
their amplitude.

# Arguments
- `im`: Image to be processed (can contain NaNs). A matrix or a `GMTgrid`.
- `wavelength`: Wavelength in pixels of the cut-in frequency for the highpass filter.
                Defaults to floor(max(size(im)) / 2). Try values from half the image
                size down to ~50 pixels.
- `clip`: Percentage of output image histogram to clip. Only a small value should be
          used, say 0.01 or 0.02. Defaults to 0.01%
- `n`: Order of the Butterworth high pass filter (≥1). Defaults to 2. Higher values
       give sharper cutoff but may introduce ringing artifacts.

# Returns
- Dynamic range reduced image; a `Matrix{Float32}` for a matrix input, a `GMTgrid` for a grid input.

# Reference
Peter Kovesi, "Phase Preserving Tone Mapping of Non-Photographic High Dynamic Range
Images". Proceedings: Digital Image Computing: Techniques and Applications 2012
(DICTA 2012). Available via IEEE Xplore

### Example
```julia
G = gmtread(TESTSDIR * "assets/mag_anomaly.grd");
Gc = kovesi(G, wavelength=100);
```
"""
function kovesi(im::Matrix{Float32}; wavelength=nothing, clip::Float64=0.01, n::Int=2)
	wl::Float64 = (wavelength === nothing) ? floor(maximum(size(im)) / 2) : Float64(wavelength)
	(n < 1) && error("kovesi: the Butterworth filter order 'n' must be >= 1")

	mask::BitMatrix = isnan.(im)			# no-data regions
	if any(mask)
		im_filled = _kov_fillnan(im, mask)	# fill them, NaNs propagate through the whole transform
		ph, E = _kov_highpassmonogenic(im_filled, wl, n)
		dim = _kov_histtruncate(sin.(ph) .* log.(1 .+ E), clip, clip)
		dim[mask] .= NaN32
	else
		ph, E = _kov_highpassmonogenic(im, wl, n)
		dim = _kov_histtruncate(sin.(ph) .* log.(1 .+ E), clip, clip)
	end
	return dim
end

# Anything else real (Float64/Int/... matrices) is converted once. GMT grids are already Float32,
# so the workhorse above takes them with no copy at all.
kovesi(im::Matrix{<:Real}; wavelength=nothing, clip::Float64=0.01, n::Int=2) =
	kovesi(Float32.(im); wavelength=wavelength, clip=clip, n=n)

function kovesi(G::GMTgrid; wavelength=nothing, clip::Float64=0.01, n::Int=2)
	dim = kovesi(G.z; wavelength=wavelength, clip=clip, n=n)
	Gc = mat2grid(dim, G)
	Gc.cpt = "";  Gc.z_unit = ""			# the result is a dimensionless tone-mapped field, not G's quantity
	return Gc
end

"""
    _kov_fillnan(im, mask) -> filled

Replace each NaN in `im` by the value of the closest non-NaN pixel — a crude but quick
'inpainting' so the FFT can run. `mask` is `isnan.(im)`. Nearest pixel comes from GMT's
`bwdist_idx` (feature transform), not from a private brute-force search.
"""
function _kov_fillnan(im::Matrix{Float32}, mask::BitMatrix)
	L = bwdist_idx(.!mask)					# CartesianIndex of the nearest valid (non-NaN) pixel
	newim = copy(im)
	@inbounds for idx in eachindex(mask)
		mask[idx] && (newim[idx] = im[L[idx]])
	end
	return newim
end

"""
    _kov_highpassmonogenic(img, maxwavelength, n=2) -> (phase, E)

Compute phase and amplitude on highpass images via monogenic filters.

- `maxwavelength`: wavelength in pixels of the cut-in frequency of the Butterworth highpass filter
- `n`: order of the Butterworth filter (integer ≥1). Higher values give a sharper cutoff; generally
  use ≤2 to avoid ringing artifacts.

Returns the local phase (between -π/2 and π/2) and the local energy (amplitude) of the signal.
"""
function _kov_highpassmonogenic(img::Matrix{Float32}, maxwavelength::Float64, n::Int=2)
	rows, cols = size(img)
	IM = fft2d(img)							# GMT_FFT_2D, no FFTW

	radius, H1, H2 = _kov_filtergrid(rows, cols)	# frequency grid + monogenic filters, no u1/u2 temporaries

	# High pass Butterworth filter, applied in-place: each coefficient computed on the fly instead
	# of building a full H matrix.
	factor = 2 * n
	wl = maxwavelength
	@inbounds for j in 1:cols, i in 1:rows
		r = radius[i, j]
		H_val = 1.0 - 1.0 / (1.0 + (r * wl)^factor)
		IM[i, j] *= H_val
	end

	@inbounds for k = 1:numel(IM)			# monogenic filters in-place: H1 -> H1.*IM, H2 -> H2.*IM
		H1[k] *= IM[k]
		H2[k] *= IM[k]
	end

	F   = fft2d!(IM; inverse=true)			# IN PLACE: IM/H1/H2 are dead after this, so no copies
	H1F = fft2d!(H1; inverse=true)
	H2F = fft2d!(H2; inverse=true)

	phase = Matrix{Float32}(undef, rows, cols)		# phase and energy element-wise: no intermediate
	E     = Matrix{Float32}(undef, rows, cols)		# real arrays for f, h1f, h2f

	eps_val = eps(Float32)
	@inbounds for k in eachindex(F)
		f_real, h1f_real, h2f_real = real(F[k]), real(H1F[k]), real(H2F[k])
		h_mag_sq = h1f_real^2 + h2f_real^2
		phase[k] = atan(f_real / (sqrt(h_mag_sq) + eps_val))
		E[k] = sqrt(f_real^2 + h_mag_sq)
	end

	return phase, E
end

"""
    _kov_filtergrid(rows::Int, cols::Int) -> (radius, H1, H2)

Generate the grid for constructing frequency domain filters. Optimized version that constructs the
frequency grid and the monogenic filters directly, without intermediate allocations.

- `radius`: normalized radius values from 0 to 0.5, quadrant shifted
- `H1`, `H2`: monogenic filters in the frequency domain (complex)
"""
function _kov_filtergrid(rows::Int, cols::Int)
	# This function is an optimization done by Claude of the original filtergrid .m function

	# For readability reason the simpler to read but highly memory inefficient version is:
	#= Set up frequency ranges
	u1range = isodd(cols) ? Float32.((-(cols-1)÷2:(cols-1)÷2) ./ cols) : Float32.((-cols÷2:(cols÷2-1)) ./ cols)
	u2range = isodd(rows) ? Float32.((-(rows-1)÷2:(rows-1)÷2) ./ rows) : Float32.((-rows÷2:(rows÷2-1)) ./ rows)

	# Create meshgrid
	u1 = repeat(reshape(u1range, 1, :), rows, 1)
	u2 = repeat(u2range, 1, cols)

	u1 = ifftshift(u1)				# Quadrant shift (inverse of fftshift)
	u2 = ifftshift(u2)

	radius = sqrt.(u1.^2 .+ u2.^2)	# Compute radius
	=#

	radius = Matrix{Float32}(undef, rows, cols)
	H1 = Matrix{ComplexF32}(undef, rows, cols)
	H2 = Matrix{ComplexF32}(undef, rows, cols)

	cols_split = isodd(cols) ? ((cols + 1) ÷ 2 + 1) : (cols ÷ 2 + 1)	# split points, ifftshift pattern
	rows_split = isodd(rows) ? ((rows + 1) ÷ 2 + 1) : (rows ÷ 2 + 1)

	radius[1, 1] = 0.0f0				# DC component first, to keep it out of the loops
	H1[1, 1] = 0.0f0 + 0.0f0im
	H2[1, 1] = 0.0f0 + 0.0f0im

	# First column (j=1), from i=2 to skip the DC component
	@inbounds for i in 2:(rows_split - 1)
		radius[i, 1] = Float32((i - 1) / rows)
		H1[i, 1] = 0.0f0 + 0.0f0im
		H2[i, 1] = 1.0f0im
	end
	@inbounds for i in rows_split:rows
		radius[i, 1] = Float32(-(i - 1 - rows) / rows)
		H1[i, 1] = 0.0f0 + 0.0f0im
		H2[i, 1] = -1.0f0im
	end

	@inbounds for j in 2:(cols_split - 1)	# remaining columns in the first half
		u1_val = Float32((j - 1) / cols)
		@inbounds for i in 1:(rows_split - 1)		# First half of rows
			u2_val = Float32((i - 1) / rows)
			r = sqrt(u1_val * u1_val + u2_val * u2_val)
			radius[i, j] = r
			H1[i, j] = 1.0f0im * u1_val / r
			H2[i, j] = 1.0f0im * u2_val / r
		end
		@inbounds for i in rows_split:rows			# Second half of rows (negative frequencies)
			u2_val = Float32((i - 1 - rows) / rows)
			r = sqrt(u1_val * u1_val + u2_val * u2_val)
			radius[i, j] = r
			H1[i, j] = 1.0f0im * u1_val / r
			H2[i, j] = 1.0f0im * u2_val / r
		end
	end

	@inbounds for j in cols_split:cols		# second half of columns (negative frequencies: ~-N/2 to -1)
		u1_val = Float32((j - 1 - cols) / cols)
		@inbounds for i in 1:(rows_split - 1)		# First half of rows
			u2_val = Float32((i - 1) / rows)
			r = sqrt(u1_val * u1_val + u2_val * u2_val)
			radius[i, j] = r
			H1[i, j] = 1.0f0im * u1_val / r
			H2[i, j] = 1.0f0im * u2_val / r
		end
		@inbounds for i in rows_split:rows			# Second half of rows (negative frequencies)
			u2_val = Float32((i - 1 - rows) / rows)
			r = sqrt(u1_val * u1_val + u2_val * u2_val)
			radius[i, j] = r
			H1[i, j] = 1.0f0im * u1_val / r
			H2[i, j] = 1.0f0im * u2_val / r
		end
	end

	return radius, H1, H2
end

"""
    _kov_histtruncate(im, lHistCut, uHistCut=lHistCut)

Truncate the ends of an image histogram: clips `lHistCut`/`uHistCut` percent of the lower/upper
ends, so grey levels spread across the primary part of the histogram. For color images (3D arrays)
converts to HSV, truncates the V channel, normalizes it to [0,1] and converts back to RGB.
"""
function _kov_histtruncate(im::Matrix{Float32}, lHistCut::Float64, uHistCut::Float64=lHistCut)
	_kov_checkcuts(lHistCut, uHistCut)
	return _kov_histtruncate_2d(im, lHistCut, uHistCut)
end

function _kov_histtruncate(im::Array{Float32,3}, lHistCut::Float64, uHistCut::Float64=lHistCut)
	_kov_checkcuts(lHistCut, uHistCut)
	hsv = rgb2hsv(im)						# the generic converters live in utils.jl, not here
	hsv[:, :, 3] = _kov_histtruncate_2d(hsv[:, :, 3], lHistCut, uHistCut)
	hsv[:, :, 3] = _kov_normalize_channel(hsv[:, :, 3])
	return hsv2rgb(hsv)
end

_kov_checkcuts(lHistCut::Float64, uHistCut::Float64) =
	(lHistCut < 0 || lHistCut > 100 || uHistCut < 0 || uHistCut > 100) &&
		error("Histogram truncation values must be between 0 and 100")

function _kov_histtruncate_2d(im::Matrix{Float32}, lHistCut::Float64, uHistCut::Float64)
	valid_pixels = im[.!isnan.(im)]
	isempty(valid_pixels) && return im

	sortv = sort(valid_pixels)
	N = length(sortv)

	lind = max(1, min(floor(Int, 1 + N * lHistCut / 100), N))
	hind = max(1, min(ceil(Int, N - N * uHistCut / 100), N))

	low_val, high_val = sortv[lind], sortv[hind]
	im[im .< low_val] .= low_val
	im[im .> high_val] .= high_val
	return im
end

"""
    _kov_normalize_channel(channel) -> normalized

Normalize a 2D array to the [0, 1] range.
"""
function _kov_normalize_channel(channel::Matrix{Float32})
	minval, maxval = extrema(channel)
	(minval == maxval) && return fill(0.5f0, size(channel))
	return (channel .- minval) ./ (maxval - minval)
end

# rgb2hsv/hsv2rgb are NOT here: they are generic colour-space conversions and live in utils.jl,
# so anything else in GMT.jl uses the same maths instead of a private copy.
