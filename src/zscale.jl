#=
This file was taken from https://github.com/JuliaPlots/PlotUtils.jl Thanks to the authors to make it
a simple function without further dependencies (other than Statistics).

C version at https://github.com/iraf-community/CDL/blob/main/cdlzscale.c
=#

"""
	zscale(input::AbstractArray,
		nsamples=1000;
		contrast=0.25,
		max_reject=0.5,
		min_npixels=5,
		k_rej=2.5,
		max_iterations=5)

Implementation of the `zscale` IRAF function for finding colorbar limits of `input`, which showcase
data near the median. This is useful for data with extreme outliers, such as astronomical images.

## Keyword arguments
* `nsamples` - The number of samples to use from `input`. If fewer than `nsamples` are present, will use the full input
* `contrast` - The desired contrast
* `max_reject` - The maximum number of pixels to reject during the iterative fitting
* `min_npixels` - The minimum number of pixels to calculate the limits after the iterative fitting
* `k_rej` - The number of standard deviations above which data is rejected
* `max_iteration` - The number of iterations used for fitting samples

See the extended help (in REPL, `??zscale`) for technical details.

## Examples
```jldoctest
julia> img = 0:9999

julia> zscale(img)
(0, 9990)
```

## Description

The zscale algorithm is designed to display the image values near the median image value,
without the time consuming process of computing a full image histogram.

This is particularly useful for astronomical images, which generally have a very peaked histogram
corresponding to the background sky in direct imaging, or the continuum in a two dimensional spectrum.

A subset of the image is examined, and approximately `nsamples` pixels are sampled evenly over the image.
The number of lines is a user parameter, `nsample_lines`.

The pixels are ranked in brightness to form the function `I(i)`, where `i` is the rank of the pixel, and
`I` is its value. Generally, the midpoint of this function (the median) is very near the peak of the image
histogram. There is a well defined slope about the midpoint, which is related to the width of the histogram.

At the ends of the `I(i)` function, there are a few very bright and dark pixels due to objects and
defects in the field. To determine the slope, a linear function is fit with iterative rejection:

```
I(i) = intercept + slope * (i - midpoint)
```

If more than half of the points are rejected, then there is no well defined slope, and the full range
of the sample defines `z1` and `z2`. Otherwise, the endpoints of the linear function are used
(provided they are within the original range of the sample):

```
z1 = I(midpoint) + (slope / contrast) * (1 - midpoint)
z2 = I(midpoint) + (slope / contrast) * (npoints - midpoint)
```

## Credits
https://github.com/JuliaPlots/PlotUtils.jl
"""
function zscale(input::AbstractArray, nsamples::Int = 1000; contrast = 0.25, max_reject = 0.5,
                min_npixels = 5, k_rej = 2.5, max_iterations = 5,)

	# get samples from finite values of input
	values = float(filter(isfinite, input))
	stride = max(1, round(Int, length(values) / nsamples))
	samples = @view values[1:stride:end][1:min(nsamples, end)]
	sort!(samples)

	N = length(samples)
	vmin = first(samples)
	vmax = last(samples)

	# fit a line to the sorted samples
	min_pix = max(min_npixels, round(Int, N * max_reject))
	x = 0:(N - 1)

	ngood = N
	last_good = N + 1

	mask = ones(Bool, N)					# good pixel mask (array bool faster than bitarray)
	ngrow = max(1, round(Int, N / 100) ÷ 2)	# get number of neighbors to mask if a pixel is bad

	local β									# line slope
	for _ ∈ 1:max_iterations				# iteratively fit samples and reject sigma-clipped outliers
		(ngood ≥ last_good || ngood < min_pix) && break

		# linear fit using mask
		x_ = @view x[mask]
		y = @view samples[mask]
		α, β = fit_line(x_, y)
		flat = @. samples - (α + β * x)

		threshold = k_rej * std(flat[mask])					# k-sigma rejection threshold
		@. mask[!(-threshold ≤ flat ≤ threshold)] = false	# detect and reject outliers based on threshold
		mask = dilate_mask(mask, ngrow)						# dilate mask

		last_good = ngood
		ngood = count(mask)
	end

	if ngood ≥ min_pix
		slope = contrast > 0 ? β / contrast : β
		center = (N - 1) ÷ 2
		m = median(samples)
		vmin = max(vmin, m - (center - 1) * slope)
		vmax = min(vmax, m + (N - center) * slope)
	end

	return vmin, vmax
end

"""
	dilate_mask(mask, ngrow)

Takes a mask and dilates each `false` with `ngrow` `false`s on either side. This is equivalent to boolean "convolution".
"""
function dilate_mask(mask, ngrow)
	out = similar(mask)
	idxs = CartesianIndices(mask)
	mindx = idxs[1].I[1]
	maxdx = idxs[end].I[1]
	@inbounds for idx ∈ idxs
		lower = max(mindx, idx.I[1] - ngrow)
		upper = min(maxdx, idx.I[1] + ngrow)
		out[idx] = all(mask[lower:upper])		# output will only be true if there are no falses in the input section
	end
	return out
end

"""
	fit_line(x, y)

Simple linear regression, returns `(intercept, slope)`.
https://en.wikipedia.org/wiki/Simple_linear_regression
"""
function fit_line(x, y)
	mx = mean(x)
	my = mean(y)
	SSxy = sum(zip(x, y)) do (xi, yi)
		(xi - mx) * (yi - my)
	end
	SSx = sum(x) do xi
		(xi - mx)^2
	end
	β = SSxy / SSx
	α = my - β * mx
	return α, β
end
