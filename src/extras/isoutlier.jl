"""
	bv = isoutlier(x; critic=3.0, method::Symbol=:median, threshold=nothing, width=0.0) -> Union{BitVector, BitMatrix}

Return a logical array whose elements are true when an outlier is detected in the corresponding element of `x`.

If `x` is a matrix, and `width` is not used, then ``isoutlier`` operates on each column of `x` separately.
By default, an outlier is a value that is more than three median absolute deviations (MAD) from the median.
But that can be changed via the `critic` option.

- `critic`: A number that sets the threshold for detecting outliers. The default is 3.0, which means that
   a value is considered an outlier if it is more than 3 MAD from the median (when `method` is `:median`),
   or more than 3 standard deviations (when `method` is `:mean`).
- `method`: The method used to calculate the threshold for outliers. It can be one of the following:
  - `:median`: Uses the median absolute deviation (MAD) method. Outliers are defined as elements more than
   `critic` MAD from the median.
  - `:mean`: Uses the mean and standard deviation method. Outliers are defined as elements more than `critic`
   standard deviations from the mean. This method is faster but less robust than "median".
  - `:quartiles`: Uses the interquartile range (IQR) method. Outliers are defined as elements more than 1.5
   interquartile ranges above the upper quartile (75 percent) or below the lower quartile (25 percent).
   This method is useful when the data in `x` is not normally distributed.
- `threshold`: Is an alternative to the `method` option. It specifies the percentile thresholds, given as a
   two-element array whose elements are in the interval [0, 100]. The first element indicates the lower percentile
   threshold, and the second element indicates the upper percentile threshold. It can also be a single number
   between (0, 100), which is interpreted as the percentage of end member points that are considered outliers.
   For example, `threshold=1` means that the lower and upper thresholds are the 1th and 99th percentiles.
- `width`: If this option is used (only when `x` is a Matrix or a GMTdataset) we detect local outliers using
   a moving window method with window length ``width``. This length is given in the same units as the input
   data stored in first column of `x`.

### Example:
```julia
x = [57, 59, 60, 100, 59, 58, 57, 58, 300, 61, 62, 60, 62, 58, 57];
findall(isoutlier(x))
2-element Vector{Int64}:
 4
 9
```

```julia
x = -50.0:50;	y = x / 50 .+ 3 .+ 0.25 * rand(length(x));
y[[30,50,60]] = [4,-3,6];	# Add 3 outliers
findall(isoutlier([x y], width=5))
```
"""
function isoutlier(x::AbstractVector{<:Real}; critic=3.0, method::Symbol=:median, threshold=nothing)
	method in [:median, :mean, :quartiles] || throw(ArgumentError("Unknown method: $method. Use :median, :mean or :quartiles"))
	if (threshold !== nothing)
		!(isa(threshold, VecOrMat{<:Real}) || isa(threshold, Real)) &&
			throw(ArgumentError("Threshold: $threshold must be a scalar or a 2 elements array."))
		if (isa(threshold, VecOrMat{<:Real}))
			@assert !(length(threshold) == 2 && threshold[1] >= 0.0 && threshold[2] <= 100) "Threshold must be a 2 elements array in the [0 100] interval"
			_thresh = [Float64(threshold[1])/100, Float64(threshold[2])/100]	# Make it [0 1]
		else
			@assert threshold > 0.0 && threshold < 100 "When threshold is a scalar, it must be in the ]0 100[ interval."
			_thresh = [Float64(threshold)/100, Float64(100 - threshold)/100]	# Make it [0 1]
		end
		method = :threshold
	end

	bv = BitVector(undef, length(x))
	if (method == :median)
		_mad, _med = mad(x);	_mad *= critic
		@inbounds for k in eachindex(x)
			bv[k] = abs(x[k] - _med)  > _mad
		end
	elseif (method == :mean)
		_mean, _std = nanmean(x), nanstd(x) * critic;
		@inbounds for k in eachindex(x)
			bv[k] = abs(x[k] - _mean)  > _std
		end
	elseif (method == :threshold)
		q_l, q_u = quantile(x, _thresh)
		@inbounds for k in eachindex(x)
			bv[k] = (x[k] < q_l) || (x[k] > q_u)
		end
	else			# method == :quartiles
		q25, q75 = quantile(x, [0.25, 0.75])
		crit = (q75 - q25) * 1.5
		q_minus, q_plus  = q25 - crit, q75 + crit
		@inbounds for k in eachindex(x)
			bv[k] = (x[k] < q_minus) || (x[k] > q_plus)
		end
	end
	return bv
end

function isoutlier(mat::AbstractMatrix{<:Real}; critic=3.0, method::Symbol=:median, threshold=nothing, width=0.0)
	width > 0 && return isoutlier(mat2ds(mat), critic=critic, method=method, threshold=threshold, width=width)
	bm = BitMatrix(undef, size(mat))
	for k = 1:size(mat,2)
		bm[:,k] .= isoutlier(view(mat, :, k), critic=critic, method=method, threshold=threshold)
	end
	return bm
end

function isoutlier(D::GMTdataset{<:Real,2}; critic=3.0, method::Symbol=:median, threshold=nothing, width=0.0)
	(threshold === nothing && width <= 0) && error("Must provide the window length of via the `width` option or use the `threshold` option.")
	if (width > 0)
		method in [:median, :mean] || throw(ArgumentError("Unknown method: $method. Here use only one of :median or :mean"))
		_method = (method == :mean) ? :boxcar : method		# :boxcar is the name in GMT for 'mean'
		#Dres = filter1d(D, filter=(type=_method, width=width, highpass=true), E=true, Vd=1)
		Dres = gmt("filter1d -E -F" * string(_method)[1] * "$(width)+h", D)
		isoutlier(view(Dres.data, :, 2), critic=critic, method=method, threshold=threshold)
	else
		isoutlier(view(D.data, :, 2), critic=critic, method=method, threshold=threshold)
	end
end
