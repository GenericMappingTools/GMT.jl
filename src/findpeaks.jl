"""
    findpeaks(y, x=1:length(y); min_height=minimum(y), min_prom=minimum(y), min_dist=0, threshold=0; xsorted::Bool=false)
    findpeaks(D::GMTdataset; min_height=minimum(y), min_prom=minimum(y), min_dist=0, threshold=0; xsorted::Bool=false)

Returns indices of local maxima (sorted from highest peaks to lowest) in 1D array of real numbers.
Similar to MATLAB's findpeaks().

A local peak is a data sample that is either larger than its two neighboring samples or is equal to Inf.
The peaks are output in order of occurrence. This function is from the ``Findpeaks.jl``
(https://github.com/tungli/Findpeaks.jl) package.

### Args
- `y`: Input data, specified as a vector. `y` must be real and must have at least three elements.
- `x`: Locations, specified as a vector or a datetime array. `x` must increase monotonically and have the
   same length as `y`. If `x` is omitted, then the indices of `y` are used as locations.
- `D`: Alternatively to `y` and `x` you can provide a `GMTdataset` with two, `x,y` (or more), columns.

### Kwargs
- `min_height`: Minimum peak height, specified as a real scalar. Use this argument to have
   ``findpeaks`` return only those peaks higher than `min_height`. 
- `min_prom`: Minimum peak prominence, specified as a nonnegative real scalar. Use this
   argument to have ``findpeaks`` return only those peaks that have a relative importance of at least
   `min_prom` (see https://www.mathworks.com/help/signal/ref/findpeaks.html#buff2uu).
- `min_dist`: Minimum peak separation (keeping highest peaks). When you specify a value for this option,
   the algorithm chooses the tallest peak and ignores all peaks within `min_dist` of it.
- `threshold`: Minimal difference (absolute value) between peak and neighboring points. Use this argument to have
   ``findpeaks`` return only those peaks that exceed their immediate neighboring values by at least the value of `threshold`.
- `xsorted`: If true, the indices of local maxima are sorted in ascending order of `x`. Default is to sort by amplitude.

### Returns
- `peaks`: Indices of local maxima (sorted from highest peaks to lowest when `xsorted=false`).

### Examples
```julia
D = gmtread(TESTSDIR * "assets/example_spectrum.txt");
peaks = findpeaks(D, min_prom=1000.);
plot(D, title="Prominent peaks")
scatter!(D[peaks,:], mc=:red, show=true)
```
"""
function findpeaks(y::AbstractVecOrMat{T}, x::AbstractVecOrMat=collect(1:length(y)); min_height::Real=minimum(y),
                   min_prom=0.0, min_dist=0.0, threshold=0.0, xsorted::Bool=false) where {T <: Real}

	isa(y, AbstractMatrix) && (y = vec(y))
	peaks = in_threshold(diff(y), threshold)
	(min_prom != 0) && (peaks = with_prominence(y, peaks, min_prom))
	peaks = peaks[y[peaks] .> min_height]			# minimal height refinement
	peaks = with_distance(peaks, x, y, min_dist, xsorted=xsorted)
end
function findpeaks(D::GMTdataset; min_height=D.bbox[1], min_prom=0.0, min_dist=0.0, threshold=0.0)
	findpeaks(view(D.data, :, 2), view(D.data, :, 1); min_height=min_height, min_prom=min_prom, min_dist=min_dist, threshold=threshold)
end

function in_threshold(dy::AbstractVector{T}, threshold::T) where {T <: Real}
	# Select peaks that are inside threshold.

	peaks = collect(1:length(dy))
	k = 0
	for i = 2:numel(dy)
		if dy[i] <= -threshold && dy[i-1] >= threshold
			peaks[k+=1] = i
		end
	end
	peaks[1:k]
end

function with_prominence(y::AbstractVector{T}, peaks::AbstractVector{Int}, min_prom,) where {T <: Real}
	# Select peaks that have a given prominence
	peaks[prominence(y, peaks) .> min_prom]		# minimal prominence refinement
end

"""
Calculate peaks' prominences
"""
function prominence(y::AbstractVector{T}, peaks::AbstractVector{Int}) where {T <: Real}
	yP = y[peaks]
	proms = zero(yP)

	for (i, p) in enumerate(peaks)
		lP, rP = 1, length(y)
		for j = (i-1):-1:1
			if yP[j] > yP[i]
				lP = peaks[j]
				break
			end
		end
		ml = minimum(y[lP:p])
		for j = (i+1):length(yP)
			if yP[j] > yP[i]
				rP = peaks[j]
				break
			end
		end
		mr = minimum(y[p:rP])
		ref = max(mr,ml)
		proms[i] = yP[i] - ref
	end
	return proms
end

function with_distance(peaks::AbstractVector{Int}, x::AbstractVector{<:Real}, y::AbstractVector{T}, min_dist; xsorted::Bool=false) where {T <: Real}
	# Select only peaks that are further apart than `min_dist`
	xsorted && min_dist == 0 && return peaks	# nothing to do in this case

	peaks2del = zeros(Bool, length(peaks))
	inds = sortperm(y[peaks], rev=true)
	permute!(peaks, inds)
	for i = 1:numel(peaks)
		for j = 1:(i-1)
			if abs(x[peaks[i]] - x[peaks[j]]) <= min_dist
				!peaks2del[j] && (peaks2del[i] = true)
			end
		end
	end
	return xsorted ? sort(peaks[.!peaks2del]) : peaks[.!peaks2del]
end
