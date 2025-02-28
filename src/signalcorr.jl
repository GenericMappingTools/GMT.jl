# Correlation analysis of signals from the StatsBase package and Matlab like warpers xcorr and xcov
#
#  autocorrelation
#  cross-correlation

function xcorr(x::AbstractVector{<:Real}; demean::Bool=true, lags::AbstractVector{<:Integer}=Int[], maxlags=0)
	_lags = !isempty(lags) ? lags : (maxlags == 0 ? default_autolags(length(x)) : 0:minimum(maxlags, length(x)-1))
	out = Vector{float(eltype(x))}(undef, length(_lags))
	autocor!(out, x, _lags; demean=demean)
end

function xcorr(x::AbstractMatrix{<:Real}; demean::Bool=true, lags::AbstractVector{<:Integer}=Int[], maxlags=0)
	_lags = !isempty(lags) ? lags : (maxlags == 0 ? default_autolags(size(x,1)) : 0:minimum(maxlags, size(x,1)-1))
	out = Matrix{float(eltype(x))}(undef, length(_lags), size(x,2))
	autocor!(out, x, _lags; demean=demean)
end

#---------------------------------------------------------------------------------------------------------------------
"""
    xcorr(x::AbstractVecOrMat{<:Real}, y::AbstractVecOrMat{<:Real}; demean::Bool=true, lags::AbstractVector{<:Integer}=Int[], maxlags=0)

Returns the cross-correlation of two discrete-time sequences.

If x is a matrix, then r is a matrix whose columns contain the autocorrelation and cross-correlation
sequences for all combinations of the columns of x.

------
    xcorr(x::AbstractVecOrMat{<:Real}; demean::Bool=true, lags::AbstractVector{<:Integer}=Int[], maxlags=0)

Returns the autocorrelation sequence of x.

Cross-correlation measures the similarity between a vector x and shifted (lagged) copies of a vector y as
a function of the lag. 

### Kwargs
- `demean`: Specifies whether the respective means of x and y should be subtracted from them before
   computing their cross correlation.
- `lags`: When left unspecified and `maxlags=0`, the lags used are the integers from
   `-min(size(x,1)-1, 10*log10(size(x,1))) to min(size(x,1), 10*log10(size(x,1)))`
- `maxlags`: limits the lag range from `-maxlag` to `maxlag`.
"""
xcorr(x::AbstractVecOrMat{<:Real}; demean::Bool=true, lags::AbstractVector{<:Integer}=Int[], maxlags=0) =
	xcorr(x, demean=demean, lags=lags, maxlags=maxlags)

#---------------------------------------------------------------------------------------------------------------------
function xcorr(x::AbstractVector{<:Real}, y::AbstractVector{<:Real}; demean::Bool=true, lags::AbstractVector{<:Integer}=Int[], maxlags=0)
	_lags = !isempty(lags) ? lags : (maxlags == 0 ? default_crosslags(length(x)) : 0:minimum(maxlags, length(x)-1))
	out = Vector{float(Base.promote_eltype(x, y))}(undef, length(_lags))
	crosscor!(out, x, y, _lags; demean=demean)
end

function xcorr(x::AbstractMatrix{<:Real}, y::AbstractVector{<:Real}; lags::AbstractVector{<:Integer}=Int[], demean::Bool=true, maxlags=0)
	_lags = !isempty(lags) ? lags : (maxlags == 0 ? default_crosslags(size(x,1)) : 0:minimum(maxlags, size(x,1)-1))
	out = Matrix{float(Base.promote_eltype(x, y))}(undef, length(_lags), size(x,2))
	crosscor!(out, x, y, _lags; demean=demean)
end

function xcorr(x::AbstractVector{<:Real}, y::AbstractMatrix{<:Real}; lags::AbstractVector{<:Integer}=Int[], demean::Bool=true, maxlags=0)
	_lags = !isempty(lags) ? lags : (maxlags == 0 ? default_crosslags(length(x)) : 0:minimum(maxlags, length(x)-1))
	out = Matrix{float(Base.promote_eltype(x, y))}(undef, length(_lags), size(y,2))
	crosscor!(out, x, y, _lags; demean=demean)
end

function xcorr(x::AbstractMatrix{<:Real}, y::AbstractMatrix{<:Real}; lags::AbstractVector{<:Integer}=Int[], demean::Bool=true, maxlags=0)
	_lags = !isempty(lags) ? lags : (maxlags == 0 ? default_crosslags(size(x,1)) : 0:minimum(maxlags, size(x,1)-1))
	out = Array{float(Base.promote_eltype(x, y)),3}(undef, length(_lags), size(x,2), size(y,2))
	crosscor!(out, x, y, _lags; demean=demean)
end

#---------------------------------------------------------------------------------------------------------------------
xcorr(x::AbstractVecOrMat{<:Real}, y::AbstractVecOrMat{<:Real}; demean::Bool=true, lags::AbstractVector{<:Integer}=Int[], maxlags=0) =
xcorr(x, y, demean=demean, lags=lags, maxlags=maxlags)

#---------------------------------------------------------------------------------------------------------------------
function xcov(x::AbstractVector{<:Real}, y::AbstractVector{<:Real}; demean::Bool=true, lags::AbstractVector{<:Integer}=Int[], maxlags=0)
	_lags = !isempty(lags) ? lags : (maxlags == 0 ? default_crosslags(length(x)) : 0:minimum(maxlags, length(x)-1))
	out = Vector{float(Base.promote_eltype(x, y))}(undef, length(_lags))
	crosscov!(out, x, y, _lags; demean=demean)
end

function xcov(x::AbstractMatrix{<:Real}, y::AbstractVector{<:Real}; lags::AbstractVector{<:Integer}=Int[], demean::Bool=true, maxlags=0)
	_lags = !isempty(lags) ? lags : (maxlags == 0 ? default_crosslags(size(x,1)) : 0:minimum(maxlags, size(x,1)-1))
	out = Matrix{float(Base.promote_eltype(x, y))}(undef, length(_lags), size(x,2))
	crosscov!(out, x, y, _lags; demean=demean)
end

function xcov(x::AbstractVector{<:Real}, y::AbstractMatrix{<:Real}; lags::AbstractVector{<:Integer}=Int[], demean::Bool=true, maxlags=0)
	_lags = !isempty(lags) ? lags : (maxlags == 0 ? default_crosslags(length(x)) : 0:minimum(maxlags, length(x)-1))
	out = Matrix{float(Base.promote_eltype(x, y))}(undef, length(_lags), size(y,2))
	crosscov!(out, x, y, _lags; demean=demean)
end

function xcov(x::AbstractMatrix{<:Real}, y::AbstractMatrix{<:Real}; lags::AbstractVector{<:Integer}=Int[], demean::Bool=true, maxlags=0)
	_lags = !isempty(lags) ? lags : (maxlags == 0 ? default_crosslags(size(x,1)) : 0:minimum(maxlags, size(x,1)-1))
	out = Array{float(Base.promote_eltype(x, y)),3}(undef, length(_lags), size(x,2), size(y,2))
	crosscov!(out, x, y, _lags; demean=demean)
end

#---------------------------------------------------------------------------------------------------------------------
"""
    xcov(x, y, [lags]; demean=true)

Compute the cross covariance function (CCF) between real-valued vectors or
matrices `x` and `y`, optionally specifying the `lags`. `demean` specifies
whether the respective means of `x` and `y` should be subtracted from them
before computing their CCF.

If both x and y are vectors, return a vector of the same length as lags. Otherwise,
compute cross covariances between each pairs of columns in x and y.

### Kwargs
- `demean`: Specifies whether the respective means of x and y should be subtracted from them before
   computing their cross covariance.
- `lags`: When left unspecified and `maxlags=0`, the lags used are the integers from
   `-min(size(x,1)-1, 10*log10(size(x,1))) to min(size(x,1), 10*log10(size(x,1)))`
- `maxlags`: limits the lag range from `-maxlag` to `maxlag`.
"""
xcov(x::AbstractVecOrMat{<:Real}, y::AbstractVecOrMat{<:Real}; demean::Bool=true, lags::AbstractVector{<:Integer}=Int[], maxlags=0) =
	xcov(x, y, demean=demean, lags=lags, maxlags=maxlags)


"""
    xcov(x::AbstractVecOrMat{<:Real}; demean::Bool=true, lags::AbstractVector{<:Integer}=Int[], maxlags=0)

Compute the autocovariance of a vector or matrix x optionally specifying the lags at which to compute the autocovariance.

If x is a vector, return a vector of the same length as lags. If x is a matrix, return a matrix
of size (length(lags), size(x,2)), where each column in the result corresponds to a column in x.

The output is not normalized. See `xcorr` for a function with normalization.
"""
xcov(x::AbstractVecOrMat{<:Real}; demean::Bool=true, lags::AbstractVector{<:Integer}=Int[], maxlags=0) =
	xcov(x, demean=demean, lags=lags, maxlags=maxlags)

function xcov(x::AbstractVector{<:Real}; demean::Bool=true, lags::AbstractVector{<:Integer}=Int[], maxlags=0)
	_lags = !isempty(lags) ? lags : (maxlags == 0 ? default_autolags(length(x)) : 0:minimum(maxlags, length(x)-1))
    out = Vector{float(eltype(x))}(undef, length(_lags))
    autocov!(out, x, _lags; demean=demean)
end

function xcov(x::AbstractMatrix{<:Real}; demean::Bool=true, lags::AbstractVector{<:Integer}=Int[], maxlags=0)
	_lags = !isempty(lags) ? lags : (maxlags == 0 ? default_autolags(size(x,1)) : 0:minimum(maxlags, size(x,1)-1))
    out = Matrix{float(eltype(x))}(undef, length(_lags), size(x,2))
    autocov!(out, x, _lags; demean=demean)
end

# -------------------------------------------------------------------------------------------------------
"""
    cv = conv(u::AbstractArray{<:Number, N}, v::AbstractArray{<:Number, N}; shape=:full)

Convolution of two arrays.

If `u,v` are vectors returns the convolution of vectors u and v. If `u,v` are matrices returns the two-dimensional
convolution of matrices A and B.

The keyword argument `shape` controls if we return the full convolution result (the default) or only the central part
of the convolution, the same size as `u`. In the first case (for the 1D case), the length of the output is
`length(u) + length(v) - 1`.

When we are using convolution to do filtering, we are normaly interested in recieving a result that is of the same
size of `u`. In this case, use the option `shape=:same` (in fact, anything different from `:full` will work).
But if we were multiplying polynomes, then we would want all convolution terms and `shape=:full` (again, the default)
would give us that.

### Example

```julia
julia> conv([-1, 2, 3, -2, 0, 1, 2], [2, 4, -1, 1], shape=:same)
7-element Vector{Int64}:
 15
  5
 -9
  7
  6
  7
 -1
```
"""
function conv(u::AbstractArray{<:Number, N}, v::AbstractArray{<:Number, N}; shape=:full) where {N}
	# This function was created from bits of the DSP.jl package

	au, av = axes(u), axes(v)
	sz = map((au, av) -> Base.OneTo(last(au) + last(av) - 1), au, av)
	cv = zeros(promote_type(eltype(u), eltype(v)), sz)

	index_offset = CartesianIndex(ntuple(i -> 1, N))
	if size(u, 1) ≤ size(v, 1) 			# choose the more efficient iteration order
		for m in CartesianIndices(u), n in CartesianIndices(v)
			@inbounds cv[n+m - index_offset] = muladd(u[m], v[n], cv[n+m - index_offset])
		end
	else
		for n in CartesianIndices(v), m in CartesianIndices(u)
			@inbounds cv[n+m - index_offset] = muladd(u[m], v[n], cv[n+m - index_offset])
		end
	end
	
	# Trim the output if shape is not :full (or :whatever)
	if (shape != :full)
		if (isvector(u))
			i1 = div(length(v),2) + 1
			i2 = i1 + length(u) - 1
			cv = isa(cv, Vector) ? cv[i1:i2] : (size(cv, 1) == 1 ? cv[:, i1:i2] : cv[i1:i2, :])	# To f respect the matrices
		else
			ir1 = div(size(v,1),2) + 1
			ir2 = ir1 + size(u,1) - 1
			ic1 = div(size(v,2),2) + 1
			ic2 = ic1 + size(u,2) - 1
			cv = cv[ir1:ir2, ic1:ic2]
		end
	end

	return cv
end


# -------------------------------------------------------------------------------------------------------
#######################################
#   Helper functions
#######################################

default_laglen(lx::Int) = min(lx-1, round(Int,10*log10(lx)))
check_lags(lx::Int, lags::AbstractVector) = (maximum(lags) < lx || error("lags must be less than the sample length."))

function demean_col!(z::AbstractVector{<:Real}, x::AbstractMatrix{<:Real}, j::Int, demean::Bool)
	T = eltype(z)
	m = size(x, 1)
	@assert m == length(z)
	b = m * (j-1)
	if demean
		s = zero(T)
		for i = 1 : m
			s += x[b + i]
		end
		mv = s / m
		for i = 1 : m
			z[i] = x[b + i] - mv
		end
	else
		copyto!(z, 1, x, b+1, m)
	end
	z
end

#######################################
#   Auto-correlations
#######################################

default_autolags(lx::Int) = 0 : default_laglen(lx)

_autodot(x::AbstractVector{<:Union{Float32, Float64}}, lx::Int, l::Int) = dot(x, 1:(lx-l), x, (1+l):lx)
_autodot(x::AbstractVector{<:Real}, lx::Int, l::Int) = dot(view(x, 1:(lx-l)), view(x, (1+l):lx))


"""
	autocov!(r, x, lags; demean=true)

Compute the autocovariance of a vector or matrix `x` at `lags` and store the result
in `r`. `demean` denotes whether the mean of `x` should be subtracted from `x`
before computing the autocovariance.

If `x` is a vector, `r` must be a vector of the same length as `lags`.
If `x` is a matrix, `r` must be a matrix of size `(length(lags), size(x,2))`, and
where each column in the result will correspond to a column in `x`.

The output is not normalized. See [`autocor!`](@ref) for a method with normalization.
"""
function autocov!(r::AbstractVector{<:Real}, x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	lx = length(x)
	m = length(lags)
	length(r) == m || throw(DimensionMismatch())
	check_lags(lx, lags)

	T = typeof(zero(eltype(x)) / 1)
	z::Vector{T} = demean ? x .- mean(x) : x
	for k = 1 : m  # foreach lag value
		r[k] = _autodot(z, lx, lags[k]) / lx
	end
	return r
end

function autocov!(r::AbstractMatrix{<:Real}, x::AbstractMatrix{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	lx, ns, m = size(x, 1), size(x, 2), length(lags)
	size(r) == (m, ns) || throw(DimensionMismatch())
	check_lags(lx, lags)

	T = typeof(zero(eltype(x)) / 1)
	z = Vector{T}(undef, lx)
	for j = 1 : ns
		demean_col!(z, x, j, demean)
		for k = 1 : m
			r[k,j] = _autodot(z, lx, lags[k]) / lx
		end
	end
	return r
end


"""
	autocov(x, [lags]; demean=true)

Compute the autocovariance of a vector or matrix `x`, optionally specifying
the `lags` at which to compute the autocovariance. `demean` denotes whether
the mean of `x` should be subtracted from `x` before computing the autocovariance.

If `x` is a vector, return a vector of the same length as `lags`.
If `x` is a matrix, return a matrix of size `(length(lags), size(x,2))`,
where each column in the result corresponds to a column in `x`.

When left unspecified, the lags used are the integers from 0 to
`min(size(x,1)-1, 10*log10(size(x,1)))`.

The output is not normalized. See [`autocor`](@ref) for a function with normalization.
"""
function autocov(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	out = Vector{float(eltype(x))}(undef, length(lags))
	autocov!(out, x, lags; demean=demean)
end

function autocov(x::AbstractMatrix{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	out = Matrix{float(eltype(x))}(undef, length(lags), size(x,2))
	autocov!(out, x, lags; demean=demean)
end

autocov(x::AbstractVecOrMat{<:Real}; demean::Bool=true) =
	autocov(x, default_autolags(size(x,1)); demean=demean)


"""
	autocor!(r, x, lags; demean=true)

Compute the autocorrelation function (ACF) of a vector or matrix `x` at `lags`
and store the result in `r`. `demean` denotes whether the mean of `x` should
be subtracted from `x` before computing the ACF.

If `x` is a vector, `r` must be a vector of the same length as `lags`.
If `x` is a matrix, `r` must be a matrix of size `(length(lags), size(x,2))`, and
where each column in the result will correspond to a column in `x`.

The output is normalized by the variance of `x`, i.e. so that the lag 0
autocorrelation is 1. See [`autocov!`](@ref) for the unnormalized form.
"""
function autocor!(r::AbstractVector{<:Real}, x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	lx = length(x)
	m = length(lags)
	length(r) == m || throw(DimensionMismatch())
	check_lags(lx, lags)

	T = typeof(zero(eltype(x)) / 1)
	z::Vector{T} = demean ? x .- mean(x) : x
	zz = dot(z, z)
	for k = 1 : m  # foreach lag value
		r[k] = _autodot(z, lx, lags[k]) / zz
	end
	return r
end

function autocor!(r::AbstractMatrix{<:Real}, x::AbstractMatrix{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	lx, ns, m = size(x, 1), size(x, 2), length(lags)
	size(r) == (m, ns) || throw(DimensionMismatch())
	check_lags(lx, lags)

	T = typeof(zero(eltype(x)) / 1)
	z = Vector{T}(undef, lx)
	for j = 1 : ns
		demean_col!(z, x, j, demean)
		zz = dot(z, z)
		for k = 1 : m
			r[k,j] = _autodot(z, lx, lags[k]) / zz
		end
	end
	return r
end


"""
	autocor(x, [lags]; demean=true)

Compute the autocorrelation function (ACF) of a vector or matrix `x`,
optionally specifying the `lags`. `demean` denotes whether the mean
of `x` should be subtracted from `x` before computing the ACF.

If `x` is a vector, return a vector of the same length as `lags`.
If `x` is a matrix, return a matrix of size `(length(lags), size(x,2))`,
where each column in the result corresponds to a column in `x`.

When left unspecified, the lags used are the integers from 0 to
`min(size(x,1)-1, 10*log10(size(x,1)))`.

The output is normalized by the variance of `x`, i.e. so that the lag 0
autocorrelation is 1. See [`autocov`](@ref) for the unnormalized form.
"""
function autocor(x::AbstractVector{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	out = Vector{float(eltype(x))}(undef, length(lags))
	autocor!(out, x, lags; demean=demean)
end

function autocor(x::AbstractMatrix{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	out = Matrix{float(eltype(x))}(undef, length(lags), size(x,2))
	autocor!(out, x, lags; demean=demean)
end

autocor(x::AbstractVecOrMat{<:Real}; demean::Bool=true) = autocor(x, default_autolags(size(x,1)); demean=demean)


#######################################
#   Cross-correlations
#######################################

default_crosslags(lx::Int) = (l=default_laglen(lx); -l:l)

function _crossdot(x::AbstractVector{T}, y::AbstractVector{T}, lx::Int, l::Int) where {T<:Union{Float32, Float64}}
	if l >= 0
		dot(x, 1:(lx-l), y, (1+l):lx)
	else
		dot(x, (1-l):lx, y, 1:(lx+l))
	end
end
function _crossdot(x::AbstractVector{<:Real}, y::AbstractVector{<:Real}, lx::Int, l::Int)
	if l >= 0
		dot(view(x, 1:(lx-l)), view(y, (1+l):lx))
	else
		dot(view(x, (1-l):lx), view(y, 1:(lx+l)))
	end
end


"""
	crosscov!(r, x, y, lags; demean=true)

Compute the cross covariance function (CCF) between real-valued vectors or matrices
`x` and `y` at `lags` and store the result in `r`. `demean` specifies whether the
respective means of `x` and `y` should be subtracted from them before computing their
CCF.

If both `x` and `y` are vectors, `r` must be a vector of the same length as
`lags`. If either `x` is a matrix and `y` is a vector, `r` must be a matrix of size
`(length(lags), size(x, 2))`; if `x` is a vector and `y` is a matrix, `r` must be a matrix
of size `(length(lags), size(y, 2))`. If both `x` and `y` are matrices, `r` must be a
three-dimensional array of size `(length(lags), size(x, 2), size(y, 2))`.

The output is not normalized. See [`crosscor!`](@ref) for a function with normalization.
"""
function crosscov!(r::AbstractVector{<:Real}, x::AbstractVector{<:Real}, y::AbstractVector{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	lx = length(x)
	m = length(lags)
	(length(y) == lx && length(r) == m) || throw(DimensionMismatch())
	check_lags(lx, lags)

	T = typeof(zero(eltype(x)) / 1)
	zx::Vector{T} = demean ? x .- mean(x) : x
	S = typeof(zero(eltype(y)) / 1)
	zy::Vector{S} = demean ? y .- mean(y) : y
	for k = 1 : m  # foreach lag value
		r[k] = _crossdot(zx, zy, lx, lags[k]) / lx
	end
	return r
end

function crosscov!(r::AbstractMatrix{<:Real}, x::AbstractMatrix{<:Real}, y::AbstractVector{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	lx, ns, m = size(x, 1), size(x, 2), length(lags)
	(length(y) == lx && size(r) == (m, ns)) || throw(DimensionMismatch())
	check_lags(lx, lags)

	T = typeof(zero(eltype(x)) / 1)
	zx = Vector{T}(undef, lx)
	S = typeof(zero(eltype(y)) / 1)
	zy::Vector{S} = demean ? y .- mean(y) : y
	for j = 1 : ns
		demean_col!(zx, x, j, demean)
		for k = 1 : m
			r[k,j] = _crossdot(zx, zy, lx, lags[k]) / lx
		end
	end
	return r
end

function crosscov!(r::AbstractMatrix{<:Real}, x::AbstractVector{<:Real}, y::AbstractMatrix{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	lx, ns, m = size(x, 1), size(x, 2), length(lags)
	(size(y, 1) == lx && size(r) == (m, ns)) || throw(DimensionMismatch())
	check_lags(lx, lags)

	T = typeof(zero(eltype(x)) / 1)
	zx::Vector{T} = demean ? x .- mean(x) : x
	S = typeof(zero(eltype(y)) / 1)
	zy = Vector{S}(undef, lx)
	for j = 1 : ns
		demean_col!(zy, y, j, demean)
		for k = 1 : m
			r[k,j] = _crossdot(zx, zy, lx, lags[k]) / lx
		end
	end
	return r
end

function crosscov!(r::AbstractArray{<:Real,3}, x::AbstractMatrix{<:Real}, y::AbstractMatrix{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	lx, nx, ny, m = size(x, 1), size(x, 2), size(y, 2), length(lags)
	(size(y, 1) == lx && size(r) == (m, nx, ny)) || throw(DimensionMismatch())
	check_lags(lx, lags)

	# cached (centered) columns of x
	T = typeof(zero(eltype(x)) / 1)
	zxs = Vector{T}[]
	sizehint!(zxs, nx)
	for j = 1 : nx
		xj = x[:,j]
		if demean
			mv = mean(xj)
			for i = 1 : lx
				xj[i] -= mv
			end
		end
		push!(zxs, xj)
	end

	S = typeof(zero(eltype(y)) / 1)
	zy = Vector{S}(undef, lx)
	for j = 1 : ny
		demean_col!(zy, y, j, demean)
		for i = 1 : nx
			zx = zxs[i]
			for k = 1 : m
				r[k,i,j] = _crossdot(zx, zy, lx, lags[k]) / lx
			end
		end
	end
	return r
end


"""
	crosscov(x, y, [lags]; demean=true)

Compute the cross covariance function (CCF) between real-valued vectors or
matrices `x` and `y`, optionally specifying the `lags`. `demean` specifies
whether the respective means of `x` and `y` should be subtracted from them
before computing their CCF.

If both `x` and `y` are vectors, return a vector of the same length as
`lags`. Otherwise, compute cross covariances between each pairs of columns in `x` and `y`.

When left unspecified, the lags used are the integers from
`-min(size(x,1)-1, 10*log10(size(x,1)))` to `min(size(x,1), 10*log10(size(x,1)))`.

The output is not normalized. See [`crosscor`](@ref) for a function with normalization.
"""
function crosscov(x::AbstractVector{<:Real}, y::AbstractVector{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	out = Vector{float(Base.promote_eltype(x, y))}(undef, length(lags))
	crosscov!(out, x, y, lags; demean=demean)
end

function crosscov(x::AbstractMatrix{<:Real}, y::AbstractVector{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	out = Matrix{float(Base.promote_eltype(x, y))}(undef, length(lags), size(x,2))
	crosscov!(out, x, y, lags; demean=demean)
end

function crosscov(x::AbstractVector{<:Real}, y::AbstractMatrix{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	out = Matrix{float(Base.promote_eltype(x, y))}(undef, length(lags), size(y,2))
	crosscov!(out, x, y, lags; demean=demean)
end

function crosscov(x::AbstractMatrix{<:Real}, y::AbstractMatrix{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	out = Array{float(Base.promote_eltype(x, y)),3}(undef, length(lags), size(x,2), size(y,2))
	crosscov!(out, x, y, lags; demean=demean)
end

crosscov(x::AbstractVecOrMat{<:Real}, y::AbstractVecOrMat{<:Real}; demean::Bool=true) =
	crosscov(x, y, default_crosslags(size(x,1)); demean=demean)


## crosscor
"""
	crosscor!(r, x, y, lags; demean=true)

Compute the cross correlation between real-valued vectors or matrices `x` and `y` at
`lags` and store the result in `r`. `demean` specifies whether the respective means of
`x` and `y` should be subtracted from them before computing their cross correlation.

If both `x` and `y` are vectors, `r` must be a vector of the same length as
`lags`. If either `x` is a matrix and `y` is a vector, `r` must be a matrix of size
`(length(lags), size(x, 2))`; if `x` is a vector and `y` is a matrix, `r` must be a matrix
of size `(length(lags), size(y, 2))`. If both `x` and `y` are matrices, `r` must be a
three-dimensional array of size `(length(lags), size(x, 2), size(y, 2))`.

The output is normalized by `sqrt(var(x)*var(y))`. See [`crosscov!`](@ref) for the unnormalized form.
"""
function crosscor!(r::AbstractVector{<:Real}, x::AbstractVector{<:Real}, y::AbstractVector{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	lx, m = length(x), length(lags)
	(length(y) == lx && length(r) == m) || throw(DimensionMismatch())
	check_lags(lx, lags)

	T = typeof(zero(eltype(x)) / 1)
	zx::Vector{T} = demean ? x .- mean(x) : x
	S = typeof(zero(eltype(y)) / 1)
	zy::Vector{S} = demean ? y .- mean(y) : y
	sc = sqrt(dot(zx, zx) * dot(zy, zy))
	for k = 1 : m  # foreach lag value
		r[k] = _crossdot(zx, zy, lx, lags[k]) / sc
	end
	return r
end

function crosscor!(r::AbstractMatrix{<:Real}, x::AbstractMatrix{<:Real}, y::AbstractVector{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	lx, ns, m = size(x, 1), size(x, 2), length(lags)
	(length(y) == lx && size(r) == (m, ns)) || throw(DimensionMismatch())
	check_lags(lx, lags)

	T = typeof(zero(eltype(x)) / 1)
	zx = Vector{T}(undef, lx)
	S = typeof(zero(eltype(y)) / 1)
	zy::Vector{S} = demean ? y .- mean(y) : y
	yy = dot(zy, zy)
	for j = 1 : ns
		demean_col!(zx, x, j, demean)
		sc = sqrt(dot(zx, zx) * yy)
		for k = 1 : m
			r[k,j] = _crossdot(zx, zy, lx, lags[k]) / sc
		end
	end
	return r
end

function crosscor!(r::AbstractMatrix{<:Real}, x::AbstractVector{<:Real}, y::AbstractMatrix{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	lx, ns, m = length(x), size(y, 2), length(lags)
	(size(y, 1) == lx && size(r) == (m, ns)) || throw(DimensionMismatch())
	check_lags(lx, lags)

	T = typeof(zero(eltype(x)) / 1)
	zx::Vector{T} = demean ? x .- mean(x) : x
	S = typeof(zero(eltype(y)) / 1)
	zy = Vector{S}(undef, lx)
	xx = dot(zx, zx)
	for j = 1 : ns
		demean_col!(zy, y, j, demean)
		sc = sqrt(xx * dot(zy, zy))
		for k = 1 : m
			r[k,j] = _crossdot(zx, zy, lx, lags[k]) / sc
		end
	end
	return r
end

function crosscor!(r::AbstractArray{<:Real,3}, x::AbstractMatrix{<:Real}, y::AbstractMatrix{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	lx, nx, ny, m = size(x, 1), size(x, 2), size(y, 2), length(lags)
	(size(y, 1) == lx && size(r) == (m, nx, ny)) || throw(DimensionMismatch())
	check_lags(lx, lags)

	# cached (centered) columns of x
	T = typeof(zero(eltype(x)) / 1)
	zxs = Vector{T}[]
	sizehint!(zxs, nx)
	xxs = Vector{T}(undef, nx)

	for j = 1 : nx
		xj = x[:,j]
		if demean
			mv = mean(xj)
			for i = 1 : lx
				xj[i] -= mv
			end
		end
		push!(zxs, xj)
		xxs[j] = dot(xj, xj)
	end

	S = typeof(zero(eltype(y)) / 1)
	zy = Vector{S}(undef, lx)
	for j = 1 : ny
		demean_col!(zy, y, j, demean)
		yy = dot(zy, zy)
		for i = 1 : nx
			zx = zxs[i]
			sc = sqrt(xxs[i] * yy)
			for k = 1 : m
				r[k,i,j] = _crossdot(zx, zy, lx, lags[k]) / sc
			end
		end
	end
	return r
end


"""
	crosscor(x, y, [lags]; demean=true)

Compute the cross correlation between real-valued vectors or matrices `x` and `y`,
optionally specifying the `lags`. `demean` specifies whether the respective means of
`x` and `y` should be subtracted from them before computing their cross correlation.

If both `x` and `y` are vectors, return a vector of the same length as
`lags`. Otherwise, compute cross covariances between each pairs of columns in `x` and `y`.

When left unspecified, the lags used are the integers from
`-min(size(x,1)-1, 10*log10(size(x,1)))` to `min(size(x,1), 10*log10(size(x,1)))`.

The output is normalized by `sqrt(var(x)*var(y))`. See [`crosscov`](@ref) for the unnormalized form.
"""
function crosscor(x::AbstractVector{<:Real}, y::AbstractVector{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	out = Vector{float(Base.promote_eltype(x, y))}(undef, length(lags))
	crosscor!(out, x, y, lags; demean=demean)
end

function crosscor(x::AbstractMatrix{<:Real}, y::AbstractVector{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	out = Matrix{float(Base.promote_eltype(x, y))}(undef, length(lags), size(x,2))
	crosscor!(out, x, y, lags; demean=demean)
end

function crosscor(x::AbstractVector{<:Real}, y::AbstractMatrix{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	out = Matrix{float(Base.promote_eltype(x, y))}(undef, length(lags), size(y,2))
	crosscor!(out, x, y, lags; demean=demean)
end

function crosscor(x::AbstractMatrix{<:Real}, y::AbstractMatrix{<:Real}, lags::AbstractVector{<:Integer}; demean::Bool=true)
	out = Array{float(Base.promote_eltype(x, y)),3}(undef, length(lags), size(x,2), size(y,2))
	crosscor!(out, x, y, lags; demean=demean)
end

crosscor(x::AbstractVecOrMat{<:Real}, y::AbstractVecOrMat{<:Real}; demean::Bool=true) =
	crosscor(x, y, default_crosslags(size(x,1)); demean=demean)
