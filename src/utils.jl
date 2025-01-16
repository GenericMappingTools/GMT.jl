# Collect generic utility functions in this file

""" Return the decimal part of a float number `x`"""
getdecimal(x::AbstractFloat) = x - trunc(Int, x)

""" Return an ierator over data skipping non-finite values"""
skipnan(itr) = Iterators.filter(el->isfinite(el), itr)

square(x) = x ^ 2
pow(b,e)  = b ^ e

function funcurve(f::Function, lims::VMr, n=100)::Vector{Float64}
	# Geneate a curve between lims[1] and lims[2] having the form of function 'f'
	if     (f == exp)    x::Vector{Float64} = vec(log.(Float64.(lims)))
	elseif (f == log)    x = vec(exp.(Float64.(lims)))
	elseif (f == log10)  x = vec(exp10.(Float64.(lims)))
	elseif (f == exp10)  x = vec(log10.(Float64.(lims)))
	elseif (f == sqrt)   x = vec(square.(Float64.(lims)))
	elseif (f == square) x = vec(sqrt.(Float64.(lims)))
	else   error("Function $f not implemented in funcurve().")
	end
	f.(linspace(x[1], x[2], n))
end

"""
    x, y = pol2cart(theta, rho; deg=false)

Transform polar to Cartesian coordinates. Angles are in radians by default.
Use `deg=true` if angles are in degrees. Input can be scalar, vectors or matrices.
"""
function pol2cart(theta, rho; deg::Bool=false)
	return (deg) ? (rho .* cosd.(theta), rho .* sind.(theta)) : (rho .* cos.(theta), rho .* sin.(theta))
end

"""
    theta, rho = cart2pol(x, y; deg=false)

Transform Cartesian to polar coordinates. Angles are returned in radians by default.
Use `deg=true` to return the angles in degrees. Input can be scalar, vectors or matrices.
"""
cart2pol(x, y; deg::Bool=false) = (deg) ? atand.(y,x) : atan.(y,x), hypot.(x,y)


"""
    x, y, z = sph2cart(az, elev, rho; deg=false)

Transform spherical coordinates to Cartesian. Angles are in radians by default.
Use `deg=true` if angles are in degrees. Input can be scalar, vectors or matrices.
"""
function sph2cart(az, elev, rho; deg::Bool=false)
	z = rho .* ((deg) ? sind.(elev) : sin.(elev))
	t = rho .* ((deg) ? cosd.(elev) : cos.(elev))
	x = t   .* ((deg) ? cosd.(az)   : cos.(az))
	y = t   .* ((deg) ? sind.(az)   : sin.(az))
	return x,y,z
end

"""
    az, elev, rho = cart2sph(x, y, z; deg=false)

Transform Cartesian coordinates to spherical. Angles are returned in radians by default.
Use `deg=true` to return the angles in degrees. Input can be scalar, vectors or matrices.
"""
function cart2sph(x, y, z; deg::Bool=false)
	h   = hypot.(x, y)
	rho = hypot.(h, z)
	elev = (deg) ? atand.(z, h) : atan.(z, h)
	az   = (deg) ? atand.(y, x) : atan.(y, x)
	return az, elev, rho
end

# ----------------------------------------------------------------------------------------------------------
"""
    count_chars(str::AbstractString, c::Char[=','])

Count the number of characters `c` in the AbstracString `str`
"""
function count_chars(str::AbstractString, c::Char=',')::Int
	count(i->(i == c), str)
end

# ----------------------------------------------------------------------------------------------------------
"""
    ind = uniqueind(x)

Return the index `ind` such that x[ind] gets the unique values of x. No sorting is done
"""
uniqueind(x) = unique(i -> x[i], eachindex(x))

"""
    u, ind = gunique(x::AbstractVector; sorted=false)

Return an array containing only the unique elements of `x` and the indices `ind` such that `u = x[ind]`.
If `sorted` is true the output is sorted (default is not)

    u, ic, ia = gunique(x::AbstractMatrix; sorted::Bool=false, rows=true)

Behaves like Matlab's unique(x, 'rows'), where u = x(ia,:) and x = u(ic,:). If `rows` is false then `ic` is empty.
"""
function gunique(x::AbstractVector; sorted::Bool=false)

	function uniquit(x)
		if sorted
			_ind = sortperm(x)
			_x = x[_ind]
			ind = uniqueind(_x)
			return _x[ind], _ind[ind]
		else
			ind = uniqueind(x)
			return x[ind], ind
		end
	end

	if (eltype(x) <: AbstractFloat && any(isnan.(x)))
		uniquit(collect(skipnan(x)))
	else
		uniquit(x)
	end
end

# Method for matrices. The default is like Matalb's [C, ind] = unique(A, 'rows')
function gunique(x::AbstractMatrix; sorted::Bool=false, rows=true)
	!rows && return gunique(vec(x); sorted=sorted)

	if (sorted)
		#xx = view(x, ind,:)
		#ind_ = sortslicesperm(xx, dims=1)
		#ind = ind[ind_]

		rows = size(x,1)
		IC = sortslicesperm(x, dims=1)
		C = x[IC, :]
		d = view(C, 1:rows-1, :) .!= view(C, 2:rows, :)
		d = any(d, dims=2)
		d = vec([true; d])			# First row is always a member of unique list.
		C = C[d, :]
		IA = cumsum(d, dims=1)		# Lists position, starting at 1.
		IA[IC] = IA		#Re-reference POS to indexing of SORT.
		IC = IC[d]
		return C, IC, IA
	end

	ind = first.(unique(last,pairs(eachrow(x))))
	return x[ind, :], ind, Vector{Int}()
end

# ----------------------------------------------------------------------------------------------------------
"""
   p = sortslicesperm(A; dims=1, kws...)

Like `sortslices` but return instead the indices `p` such that `A[p, :] == sortslices(A; dims=1, kws...)`
"""
function sortslicesperm(A::AbstractArray; dims::Union{Integer, Tuple{Vararg{Integer}}}=1, kws...)
    itspace = compute_itspace(A, Val{dims}())
    vecs = map(its->view(A, its...), itspace)
    p = sortperm(vecs; kws...)
end

# Works around inference's lack of ability to recognize partial constness
struct DimSelector{dims, T}
    A::T
end
DimSelector{dims}(x::T) where {dims, T} = DimSelector{dims, T}(x)
(ds::DimSelector{dims, T})(i) where {dims, T} = i in dims ? axes(ds.A, i) : (:,)

_negdims(n, dims) = filter(i->!(i in dims), 1:n)

function compute_itspace(A, ::Val{dims}) where {dims}
    negdims = _negdims(ndims(A), dims)
    axs = Iterators.product(ntuple(DimSelector{dims}(A), ndims(A))...)
    vec(permutedims(collect(axs), (dims..., negdims...)))
end


#= ------------------------------------------------------------
"""
Delete rows from a matrix where any of its columns has a NaN
"""
function del_mat_row_nans(mat)
	nanrows = any(isnan.(mat), dims=2)
	return (any(nanrows)) ? mat[vec(.!nanrows),:] : mat
end
=#

# ----------------------------------------------------------------------------------------------------------
function std_nan(A, dims=1)
	# Compute std of a matrix or vector accounting for the possibility of NaNs.
	if (any(isnan.(A)))
		N = (dims == 1) ? size(A, 2) : size(A, 1)
		S = zeros(1, N)
		if (dims == 1)
			for k = 1:N  S[k] = std(skipnan(view(A, :,k)))  end
		else
			for k = 1:N  S[k] = std(skipnan(view(A, k,:)))  end
		end
	else
		S = std(A, dims=dims)
	end
end

# --------------------------------------------------------------------------------------------------
# Incredibly Julia ignores the NaN nature and incredibly min(1,NaN) = NaN, so need to ... fck
extrema_nan(A::AbstractArray{<:AbstractFloat}) = minimum_nan(A), maximum_nan(A)
extrema_nan(A) = extrema(A)

"""
    extrema_cols(A; col=1)

Compute the minimum and maximum of a column of a matrix/vector `A` ignoring NaNs
"""
function extrema_cols(A; col=1)
	(col > size(A,2)) && error("'col' ($col) larger than number of coluns in array ($(size(A,2)))")
	mi, ma = typemax(eltype(A)), typemin(eltype(A))
	@inbounds for n = 1:size(A,1)
		mi = ifelse(mi > A[n,col], A[n,col], mi)
		ma = ifelse(ma < A[n,col], A[n,col], ma)
	end
	return mi, ma
end

"""
    extrema_cols_nan(A; col=1)

Compute the minimum and maximum of a column of a matrix/vector `A` NOT ignoring NaNs or Infs
"""
function extrema_cols_nan(A; col=1)
	(col > size(A,2)) && error("'col' ($col) larger than number of coluns in array ($(size(A,2)))")
	mi, ma = typemax(eltype(A)), typemin(eltype(A))
	@inbounds for n = 1:size(A,1)
		if isfinite(A[n,col])
			mi = ifelse(mi > A[n,col], A[n,col], mi)
			ma = ifelse(ma < A[n,col], A[n,col], ma)
		end
	end
	return mi, ma
end

function minimum_nan(A::AbstractArray{<:AbstractFloat})
	mi = minimum(A);	!isnan(mi) && return mi		# The noNaNs version is a order of magnitude faster
	mi = typemax(eltype(A))
	@inbounds for k in eachindex(A) mi = ifelse(isfinite(A[k]), min(mi, A[k]), mi)  end
	mi == typemax(eltype(A)) && (mi = convert(eltype(A), NaN))	# Better to return NaN then +Inf
	return mi
end
minimum_nan(A) = minimum(A)

function maximum_nan(A::AbstractArray{<:AbstractFloat})
	ma = maximum(A);	!isnan(ma) && return ma		# The noNaNs version is a order of magnitude faster
	ma = typemin(eltype(A))
	@inbounds for k in eachindex(A) ma = ifelse(isfinite(A[k]), max(ma, A[k]), ma)  end
	ma == typemin(eltype(A)) && (ma = convert(eltype(A), NaN))	# Better to return NaN than -Inf
	return ma
end
maximum_nan(A) = maximum(A)

function findmax_nan(x::AbstractVector{T}) where T
	# Since Julia doesn't ignore NaNs and prefer to return wrong results findmax is useless when data
	# has NaNs. We start by runing findmax() and only if max is NaN we fallback to a slower algorithm.
	ma, ind = findmax(x)
	if (isnan(ma))
		ma, ind = typemin(eltype(x)), 0
		for k in eachindex(x)
			!isnan(x[k]) && ((x[k] > ma) && (ma = x[k]; ind = k))
		end
	end
	ma, ind
end
function findmin_nan(x::AbstractVector{T}) where T
	mi, ind = findmin(x)
	if (isnan(mi))
		mi, ind = typemax(eltype(x)), 0
		for k in eachindex(x)
			!isnan(x[k]) && ((x[k] < mi) && (mi = x[k]; ind = k))
		end
	end
	mi, ind
end
nanmean(x)   = mean(filter(!isnan,x))
nanmean(x,y) = mapslices(nanmean,x,dims=y)
nanstd(x)    = std(filter(!isnan,x))
nanstd(x,y)  = mapslices(nanstd,x,dims=y)

# --------------------------------------------------------------------------------------------------
Base.minimum(A::Array{<:Complex{<:Integer}}) = minimum(real(A)), minimum(imag(A))
Base.maximum(A::Array{<:Complex{<:Integer}}) = maximum(real(A)), maximum(imag(A))
Base.minimum(A::Array{<:Complex{<:AbstractFloat}}) = minimum(real(A)), minimum(imag(A))
Base.maximum(A::Array{<:Complex{<:AbstractFloat}}) = maximum(real(A)), maximum(imag(A))
function Base.extrema(A::Array{<:Complex{<:Integer}})		# Returns real_min, real_max, imag_min, imag_max
	mi_r, mi_i = minimum(A), maximum(A)
	return mi_r[1], mi_i[1], mi_r[2], mi_i[2]
end
function Base.extrema(A::Array{<:Complex{<:Real}})
	mi_r, mi_i = minimum_nan(A), maximum_nan(A)
	return mi_r[1], mi_i[1], mi_r[2], mi_i[2]
end
# --------------------------------------------------------------------------------------------------
"""
    doy2date(doy[, year]) -> Date

Compute the date from the Day-Of-Year `doy`. If `year` is ommited we take it to mean the current year.
Both `doy` and `year` can be strings or integers.
"""
function doy2date(doy, year=nothing)
	_year = (year === nothing) ? string(Dates.year(now())) : string(year)
	n_days = Dates.date2epochdays(Date(_year))
	_doy = (isa(doy, Integer)) ? doy : parse(Int64, doy)
	n_days += _doy - 1
	Dates.epochdays2date(n_days)
end
"""
    date2doy(date) -> Integer

Compute the Day-Of-Year (DOY) from `date` that can be a string or a Date/DateTime type. If ommited,
returns today's DOY
"""
date2doy() = dayofyear(now())
date2doy(date::TimeType) = dayofyear(date)
date2doy(date::String) = dayofyear(Date(date))

# --------------------------------------------------------------------------------------------------
"""
    yeardecimal(date)

Convert a Date or DateTime or a string representation of them to decimal years.

### Example
    yeardecimal(now())
"""
function yeardecimal(dtm::Union{String, Vector{String}})
	try
		yeardecimal(DateTime.(dtm))
	catch
		yeardecimal(Date.(dtm))
	end
end
function yeardecimal(dtm::Union{Date, Vector{Date}})
	year.(dtm) .+ (dayofyear.(dtm) .- 1) ./ daysinyear.(dtm)
end
function yeardecimal(dtm::Union{DateTime, Vector{DateTime}})
	Y = year.(dtm)
	# FRAC = number_of_milli_sec_in_datetime / number_of_milli_sec_in_that_year
	frac = (Dates.datetime2epochms.(dtm) .- Dates.datetime2epochms.(DateTime.(Y))) ./ (daysinyear.(dtm) .* 86400000)
	Y .+ frac
end

# --------------------------------------------------------------------------------------------------
function peaks(; N=49, grid::Bool=true, pixreg::Bool=false)
	x,y = meshgrid(range(-3,stop=3,length=N))

	z = 3 * (1 .- x).^2 .* exp.(-(x.^2) - (y .+ 1).^2) - 10*(x./5 - x.^3 - y.^5) .* exp.(-x.^2 - y.^2)
	    - 1/3 * exp.(-(x .+ 1).^2 - y.^2)

	if (grid)
		inc = y[2]-y[1]
		_x = (pixreg) ? collect(range(-3-inc/2,stop=3+inc/2,length=N+1)) : collect(range(-3,stop=3,length=N))
		_y = copy(_x)
		z = Float32.(z)
		reg = (pixreg) ? 1 : 0
		G = GMTgrid("", "", 0, 0, [_x[1], _x[end], _y[1], _y[end], minimum(z), maximum(z)], [inc, inc],
					reg, NaN, "", "", "", "", String[], _x, _y, Vector{Float64}(), z, "x", "y", "", "z", "BCB", 1f0, 0f0, 0, 1)
		return G
	else
		return x,y,z
	end
end

# -------------------------------------------------------------------------------------------------
# Median absolute deviation. This function is a trimmed version from the StatsBase package
# https://github.com/JuliaStats/StatsBase.jl/blob/60fb5cd400c31d75efd5cdb7e4edd5088d4b1229/src/scalarstats.jl#L527-L536
"""
    mad(x)

Compute the median absolute deviation (MAD) of collection `x` around the median

The MAD is multiplied by `1 / quantile(Normal(), 3/4) ≈ 1.4826`, in order to obtain a consistent estimator
of the standard deviation under the assumption that the data is normally distributed.
"""
mad(x) = mad!(Base.copymutable(x))
function mad!(x::AbstractArray)
	mad_constant = 1.4826022185056018
	isempty(x) && throw(ArgumentError("mad is not defined for empty arrays"))
	c = median!(x)
	T = promote_type(typeof(c), eltype(x))
	U = eltype(x)
	x2 = U == T ? x : isconcretetype(U) && isconcretetype(T) && sizeof(U) == sizeof(T) ? reinterpret(T, x) : similar(x, T)
	x2 .= abs.(x .- c)
	return median!(x2)  * mad_constant
end

meshgrid(v::AbstractVector) = meshgrid(v, v)
function meshgrid(vx::AbstractVector{T}, vy::AbstractVector{T}) where T
	X = [x for _ in vy, x in vx]
	Y = [y for y in vy, _ in vx]
	X, Y
end

function meshgrid(vx::AbstractVector{T}, vy::AbstractVector{T}, vz::AbstractVector{T}) where T
	m, n, o = length(vy), length(vx), length(vz)
	vx = reshape(vx, 1, n, 1)
	vy = reshape(vy, m, 1, 1)
	vz = reshape(vz, 1, 1, o)
	om = ones(Int, m)
	on = ones(Int, n)
	oo = ones(Int, o)
	(vx[om, :, oo], vy[:, on, oo], vz[om, on, :])
end

# --------------------------------------------------------------------------------------------------
function tic()
    t0 = time_ns()
    task_local_storage(:TIMERS, (t0, get(task_local_storage(), :TIMERS, ())))
    return t0
end

function _toq()
    t1 = time_ns()
    timers = get(task_local_storage(), :TIMERS, ())
    (timers === ()) && error("`toc()` without `tic()`")
    t0 = timers[1]::UInt64
    task_local_storage(:TIMERS, timers[2])
    (t1-t0)/1e9
end

function toc(V=true)
    t = _toq()
    (V) && println("elapsed time: ", t, " seconds")
    return t
end

# --------------------------------------------------------------------------------------------------
"""
    isnodata(array::AbstractArray, val=0)

Return a boolean array with the same size a `array` with 1's (`true`) where ``array[i] == val``.
Test with an image have shown that this function was 5x faster than ``ind = (I.image .== 0)``
"""
function isnodata(array::AbstractArray, val=0)
	nrows, ncols = size(array,1), size(array,2)
	nlayers = (ndims(array) == 3) ? size(array,3) : 1
	if (ndims(array) == 3)  indNaN = fill(false, nrows, ncols, nlayers)
	else                    indNaN = fill(false, nrows, ncols)
	end
	@inbounds Threads.@threads for k = 1:nrows * ncols * nlayers	# 5x faster than: indNaN = (I.image .== 0)
		(array[k] == val) && (indNaN[k] = true)
	end
	indNaN
end

#=
function isnodata(array::Matrix{T}, val=0) where T
	nrows, ncols = size(array)
	indNaN = fill(false, nrows, ncols)
	@inbounds Threads.@threads for k = 1:nrows * ncols	# 5x faster than: indNaN = (I.image .== 0)
		(array[k] == val) && (indNaN[k] = true)
	end
	indNaN
end
function isnodata(array::Array{T,3}, val=0) where T
	nrows, ncols, nlayers = size(array)
	indNaN = fill(false, nrows, ncols, nlayers)
	@inbounds Threads.@threads for k = 1:nrows * ncols * nlayers	# 5x faster than: indNaN = (I.image .== 0)
		(array[k] == val) && (indNaN[k] = true)
	end
	indNaN
end
=#

# ---------------------------------------------------------------------------------------------------
function fakedata(sz...)
	# 'Stolen' from Plots.fakedata()
	y = zeros(sz...)
	for r in 2:size(y,1)
		y[r,:] = 0.95 * vec(y[r-1,:]) + randn(size(y,2))
	end
	y
end

# ---------------------------------------------------------------------------------------------------
"""
    delrows!(A::Matrix, rows::VecOrMat)

Delete the rows of Matrix `A` listed in the vector `rows`
"""
function delrows!(A::Matrix, rows::VecOrMat)
	nrows, ncols = size(A)
	npts = length(A)
	A = reshape(A, npts)
	ndr = length(rows)			# Number of rows to delete
	inds = Vector{Int}(undef, ndr * ncols)
	for k = 1:ndr
		inds[(k-1)*ncols+1:k*ncols] = collect(rows[k]:nrows:npts-nrows+rows[k])
	end
	inds = sort(inds)
	reshape(deleteat!(A, inds), nrows-ndr, ncols)
end

# --------------------------------------------------------------------------------------------------
"""
    R = rescale(A; low=0.0, up=1.0; inputmin=nothing, inputmax=nothing, stretch=false, type=nothing)

- `A`: is either a GMTgrid, GMTimage, Matrix{AbstractArray} or a file name. In later case the file is read
   with a call to `gmtread` that automatically decides how to read it based on the file extension ... not 100% safe.
- `rescale(A)` rescales all entries of an array `A` to [0,1].
- `rescale(A,low,up)` rescales all entries of A to the interval [low,up].
- `rescale(..., inputmin=imin)` sets the lower bound `imin` for the input range. Input values less
   than `imin` will be replaced with `imin`. The default is min(A).
- `rescale(..., inputmax=imax)` sets the lower bound `imax` for the input range. Input values greater
   than `imax` will be replaced with `imax`. The default is max(A).
- `rescale(..., stretch=true)` automatically determines [inputmin inputmax] via a call to histogram that
   will (try to) find good limits for histogram stretching. The form `stretch=(imin,imax)` allows specifying
   the input limits directly.
- `type`: Converts the scaled array to this data type. Valid options are all Unsigned types (e.g. `UInt8`).
   Default returns the same data type as `A` if it's an AbstractFloat, or Float64 if `A` is an integer.

Returns a GMTgrid if `A` is a GMTgrid of floats, a GMTimage if `A` is a GMTimage and `type` is used or
an array of Float32|64 otherwise.
"""
function rescale(A::String; low=0.0, up=1.0, inputmin=nothing, inputmax=nothing, stretch=false, type=nothing)
	GI = gmtread(A)
	rescale(GI; low=low, up=up, inputmin=inputmin, inputmax=inputmax, stretch=stretch, type=type)
end
function rescale(A::AbstractArray; low=0.0, up=1.0, inputmin=nothing, inputmax=nothing, stretch=false, type=nothing)
	(type !== nothing && (!isa(type, DataType) || !(type <: Unsigned))) && error("The 'type' variable must be an Unsigned DataType")
	((inputmin !== nothing || inputmax !== nothing) && stretch == 1) && @warn("The `stretch` option overrules `inputmin|max`.")
	low = Float64(low)
	up  = Float64(up)
	if (stretch == 1)
		inputmin, inputmax = histogram(A, getauto=true)
	elseif (isa(stretch, Tuple) || (isvector(stretch) && length(stretch) == 2))
		inputmin, inputmax = stretch[1], stretch[2]
	end
	(inputmin === nothing) && (mi::Float64 = (isa(A, GItype)) ? A.range[5] : minimum_nan(A))
	(inputmax === nothing) && (ma::Float64 = (isa(A, GItype)) ? A.range[6] : maximum_nan(A))
	_inmin::Float64 = convert(Float64, (inputmin === nothing) ? mi : inputmin)
	_inmax::Float64 = convert(Float64, (inputmax === nothing) ? ma : inputmax)
	d1 = _inmax - _inmin
	(d1 <= 0.0) && error("Stretch range has inputmin > inputmax.")
	d2 = up - low
	sc::Float64 = d2 / d1
	have_nans = false
	if (eltype(A) <: AbstractFloat)		# Float arrays can have NaNs
		have_nans = !(isa(A, GMTgrid) && A.hasnans == 1)
		have_nans && (have_nans = any(!isfinite, A))
	end
	if (type !== nothing)
		(low != 0.0 || up != 1.0) && (@warn("When converting to Unsigned must have a=0, b=1"); low=0.0; up=1.0)
		o = (type == UInt8) ? Array{UInt8}(undef, size(A)) : Array{UInt16}(undef, size(A))
		_tmax::Float64 = (type == UInt8) ? typemax(UInt8) : typemax(UInt16)
		sc  *= _tmax
		low *= _tmax
		if (have_nans)
			if (inputmin === nothing && inputmax === nothing)	# Faster case. No IFs in loop
				if (type == UInt8)
					@inbounds for k = 1:numel(A)  isnan(A[k]) && (o[k] = 0; continue); o[k] = round(UInt8,  low + (A[k] -_inmin) * sc)  end
				else
					@inbounds for k = 1:numel(A)  isnan(A[k]) && (o[k] = 0; continue); o[k] = round(UInt16, low + (A[k] -_inmin) * sc)  end
				end
			else
				low_i, up_i = round(type, low), round(type, up*typemax(type))
				@inbounds for k = 1:numel(A)
					isnan(A[k]) && (o[k] = 0; continue)
					o[k] = (A[k] < _inmin) ? low_i : ((A[k] > _inmax) ? up_i : round(type, low + (A[k] -_inmin) * sc))
				end
			end
		else
			if (inputmin === nothing && inputmax === nothing)	# Faster case. No IFs in loop
				if (type == UInt8)
					@inbounds for k = 1:numel(A)  o[k] = round(UInt8,  low + (A[k] -_inmin) * sc)  end
				else
					@inbounds for k = 1:numel(A)  o[k] = round(UInt16, low + (A[k] -_inmin) * sc)  end
				end
			else
				low_i, up_i = round(type, low), round(type, up*typemax(type))
				@inbounds for k = 1:numel(A)
					o[k] = (A[k] < _inmin) ? low_i : ((A[k] > _inmax) ? up_i : round(type, low + (A[k] -_inmin) * sc))
				end
			end
		end
		return isa(A, GItype) ? mat2img(o, A) : o
	else
		oType = (eltype(A) <: AbstractFloat) ? eltype(A) : Float64
		o = Array{oType}(undef, size(A))
		if (oType <: Integer && have_nans)						# Shitty case
			if (inputmin === nothing && inputmax === nothing)	# Faster case. No IFs in loop
				@inbounds for k = 1:numel(A)  isnan(A[k]) && (o[k] = 0; continue); o[k] = low + (A[k] -_inmin) * sc  end
			else
				@inbounds for k = 1:numel(A)
					isnan(A[k]) && (o[k] = 0; continue)
					o[k] = (A[k] < _inmin) ? low : ((A[k] > _inmax) ? up : low + (A[k] -_inmin) * sc)
				end
			end
		else
			if (inputmin === nothing && inputmax === nothing)	# Faster case. No IFs in loop
				@inbounds for k = 1:numel(A)  o[k] = low + (A[k] -_inmin) * sc  end
			else
				@inbounds for k = 1:numel(A)
					o[k] = (A[k] < _inmin) ? low : ((A[k] > _inmax) ? up : low + (A[k] -_inmin) * sc)
				end
			end		end
		return isa(A, GItype) ? mat2grid(o, A) : o
	end
end

# --------------------------------------------------------------------------------------------------
"""
	M = magic(n::Int) => Matrix{Int}
	
M = magic(n) returns an n-by-n matrix constructed from the integers 1 through n^2 with equal row and column sums.
The order n must be a scalar greater than or equal to 3 in order to create a valid magic square.
"""
function magic(n::Int)
	# From:  https://gist.github.com/phillipberndt/2db94bf5e0c16161dedc
	# Had to suffer with Julia painful matrix indexing system to make it work. Gives the same as magic.m
	if n % 2 == 1
		p = (1:n)
		M = n * mod.(p .+ (p' .- div(n+3, 2)), n) .+ mod.(p .+ (2p' .- 2), n) .+ 1
	elseif n % 4 == 0
		J = div.((1:n) .% 4, 2)
		K = J' .== J
		M = collect(1:n:(n*n)) .+ reshape(0:n-1, 1, n)	# Is it really true that we can't make a 1 row matix?????
		M[K] .= n^2 .+ 1 .- M[K]
	else
		p = div(n, 2)
		M = magic(p)
		M = [M M .+ 2p^2; M .+ 3p^2 M .+ p^2]
		(n == 2) && return M
		i = (1:p)
		k = Int((n-2)/4)
		j = convert(Array{Int}, [(1:k); ((n-k+2):n)])
		M[[i; i.+p],j] = M[[i.+p; i],j]
		ii = k+1
		j = [1; ii]
		M[[ii; ii+p],j] = M[[ii+p; ii],j]
	end
	return M
end

"""
    setfld!(D, kwargs...)

Sets fields of GMTdataset (or a vector of it), GMTgrid and GMTimage. Field names and field
values are transmitted via `kwargs`

Example:
    setfld!(D, geom=wkbPolygon)
"""
function setfld!(D::Union{GMTgrid, GMTimage, GMTdataset}; kwargs...)
	for key in keys(kwargs) 
		setfield!(D, key, kwargs[key])
	end
end
function setfld!(D::Vector{<:GMTdataset}; kwargs...)
	for d in D
		setfld!(d; kwargs...)
	end
end

# ---------------------------------------------------------------------------------------------------
function get_group_indices(d::Dict, data)::Tuple{Vector{Vector{Union{Int,String}}}, Vector{Any}}
	# If 'data' is a Vector{GMTdataset} return results respecting only the first GMTdataset of the array.
	group::Vector{Union{Int,String}} = ((val = find_in_dict(d, [:group])[1]) === nothing) ? Int[] : val
	groupvar::StrSymb = ((val = find_in_dict(d, [:groupvar :hue])[1]) === nothing) ? "" : val
	((groupvar != "") && !isa(data, GDtype)) && error("'groupvar' can only be used when input is a GMTdataset")
	(isempty(group) && groupvar == "") && return Int[], []
	get_group_indices(isa(data, Vector{<:GMTdataset}) ? data[1] : data, group, groupvar)
end

function get_group_indices(data, group, groupvar::StrSymb)::Tuple{Vector{Vector{Union{Int,String}}}, Vector{Any}}
	# This function is not meant for public consuption. In fact it's only called directly by the parallelplot() fun
	# or indirectly, via the other method, by plot().
	# Returns a Vector of AbstractVectors with the indices of each group and a Vector of names or numbers
	(isempty(group) && isa(data, GMTdataset) && groupvar == "text") && (group = data.text)
	(!isempty(group) && length(group) != size(data,1)) && error("Length of `group` and number of rows in input don't match.")
	if (isempty(group) && isa(data, GMTdataset))
		isa(groupvar, Integer) && (group = Base.invokelatest(view, data.data, :, groupvar))
		if (isempty(group))
			gvar = string(groupvar)
			x = (gvar .== data.colnames)	# Try also to fish the name of the text column
			any(x) && (group = x[end] ? data.text : Base.invokelatest(view, data, :, findfirst(x)))
		end
	end
	gidx, gnames = !isempty(group) ? grp2idx(group) : ([1:size(data,1)], [0])
end

# ----------------------------------------------------------------------------------------------------------
"""
    gidx, gnames = grp2idx(s::AbstracVector)

Creates an index Vector{Vector} from the grouping variable S. S can be an AbstracVector of elements
for which the `==` method is defined. It returns a Vector of Vectors with the indices of the elements
of each group. There will be as many groups as `length(gidx)`. `gnames` is a string vector holding
the group names.
"""
function grp2idx(s)
	gnames = unique(s)
	gidx = [findall(s .== gnames[k]) for k = 1:numel(gnames)]
	gidx, gnames
end

# ----------------------------------------------------------------------------------------------------------
"""
"""
function replicateline(xy, d)
	# https://stackoverflow.com/questions/1250419/finding-points-on-a-line-with-a-given-distance
	# magnitude = (1^2 + m^2)^(1/2)
	# N = <1, m> / magnitude = <1 / magnitude, m / magnitude>
	# f(t) = A + t*N

	line2 = Matrix{Float64}(undef, size(xy))
	m1 = -(xy[2,1] - xy[1,1]) / (xy[2,2] - xy[1,2])		# Slope of the perpendicular to first segment
	inv_mag_d = d / sqrt(1 + m1*m1)
	line2[1, 1] = xy[1, 1] + inv_mag_d
	line2[1, 2] = xy[1, 2] + m1 * inv_mag_d

	@inbounds for k = 2:size(xy,1)-1
		m2 = -(xy[k,1] - xy[k-1,1]) / (xy[k,2] - xy[k-1,2])		# Slope of the perpendicular to line segment k -> k+1
		m = (m1 + m2) / 2						# ...
		inv_mag_d = d / sqrt(1 + m*m)
		line2[k, 1] = xy[k, 1] + inv_mag_d
		line2[k, 2] = xy[k, 2] + m * inv_mag_d
		m1 = m2
	end

	m1 = -(xy[end,1] - xy[end-1,1]) / (xy[end,2] - xy[end-1,2])		# Slope of the perpendicular to last segment
	inv_mag_d = d / sqrt(1 + m1*m1)
	line2[end, 1] = xy[end, 1] + inv_mag_d
	line2[end, 2] = xy[end, 2] + m1 * inv_mag_d

	return line2
end

# ---------------------------------------------------------------------------------------------------
"""
    height (nrows), width (ncols) = dims(GI::GItype)

Return the width and height of the grid/cube or image. The difference from `size` is that
the when the memory layout is 'rows' the array is transposed and we get the wrong info. Here,
we use the sizes of the 'x,y' coordinate vectors to determine the array's true shape.
"""
dims(GI::GItype) = (GI.layout != "" && GI.layout[2] == 'C') ? (size(GI,1), size(GI,2)) : (length(GI.y), length(GI.x)) .- GI.registration

# EDIPO SECTION
# ---------------------------------------------------------------------------------------------------
linspace(start, stop, length=100) = range(start, stop=stop, length=length)
logspace(start, stop, length=100) = exp10.(range(start, stop=stop, length=length))
fields(arg) = fieldnames(typeof(arg))
fields(arg::Array) = fieldnames(typeof(arg[1]))
flipud(A) = reverse(A, dims=1)
fliplr(A) = reverse(A, dims=2)
flipdim(A,dim)  = reverse(A, dims=dim)
flipdim!(A,dim) = reverse!(A, dims=dim)
#feval(fn_str, args...) = eval(Symbol(fn_str))(args...)
numel(args...)::Int = length(args...)
dec2bin(n::Integer, mindigits::Int=0) = string(n, base=2, pad=mindigits)
bin2dec(b::Union{AbstractString, Char}) = parse(Int, b, base=2)

function sub2ind(sz, args...)
	linidx = LinearIndices(sz)
	getindex.([linidx], args...)
end

function fileparts(fn::String)
	pato, ext = splitext(fn)
	pato, fname = splitdir(pato)
	return pato, fname, ext
end

# ---------------------------------------------------------------------------------------------------
"""
    I = eye(n=3) returns an n-by-n identity matrix with ones on the main diagonal and zeros elsewhere.
"""
function eye(n=3)
	M = zeros(n,n)
	@inbounds for i = 1:n
		M[i,i] = 1.0
	end
	M
end

# ---------------------------------------------------------------------------------------------------
function uniq(A; dims=1)
	# Like the Matlab function
	# https://discourse.julialang.org/t/unique-indices-method-similar-to-matlab/34446/7
	@assert ndims(A) ∈ (1, 2)
	slA = ndims(A) > 1 ? eachslice(A; dims) : A
  
	ia = unique(i -> slA[i], axes(A, dims))
	sort!(ia; by=i -> slA[i])
  
	C = stack(slA[ia]; dims)
	slC = ndims(A) > 1 ? eachslice(C; dims) : C
  
	ic = map(r -> findfirst(==(slA[r]), slC), axes(A, dims))
	C, ia, ic
end

# ---------------------------------------------------------------------------------------------------
"""
    p = polyfit(x, y, n=length(x)-1; xscale=1)

Returns the coefficients for a polynomial p(x) of degree `n` that is the least-squares best fit for the data in y.
The coefficients in p are in ascending powers, and the length of p is n+1.

The `xscale` parameter is useful when needing to get coeeficients in different x units. For example when converting
months or seconds into years.
"""
polyfit(D::GMTdataset, n::Int=size(x,1)-1; xscale=1) = polyfit(view(D.data, :,1), view(D.data, :,2), n, xscale=xscale)
function polyfit(x, y, n::Int=length(x)-1; xscale=1)
	@assert length(x) == length(y) "X,Y sizes mismatch"
	@assert 1 <= n <= length(x) - 1  "Order of polynome must be between 1 and length(x)-1"

	# Construct the Vandermonde matrix V = [1 x ... x.^n]
	V = fill(1.0, length(x), n+1)
	[V[:,k+1] .= V[:,k] .* (x * xscale) for k = 1:n]
	p = V \ vec(y)
end

# ---------------------------------------------------------------------------------------------------
"""
    y = polyval(p::AbstractArray, x::Union{AbstractArray, Number})

Evaluates the polynomial p at each point in x. The argument p is a vector of length n+1 whose elements are the
coefficients (in ascending order of powers) of an nth-degree polynomial:
"""
function polyval(p::AbstractArray, x::Union{AbstractArray, Number})
	pt = promote_type(eltype(p), eltype(x))

	length(p) == 0 && return fill(zero(eltype(x)), length(x))
	y = fill(convert(pt, p[end]), length(x))
	for k = (length(p)-1):-1:1
		y .= p[k] .+ x .* y
	end
	return length(x) == 1 ? y[1] : y
end

# ---------------------------------------------------------------------------------------------------
# https://discourse.julialang.org/t/wrap2pi-what-should-it-do/119441/23
"""
    wrap2pi(angle)

Limit the angle to the range -π .. π .
"""
wrap2pi(x::typeof(π)) = rem2pi(float(x), RoundNearest)
wrap2pi(x) = rem2pi(x, RoundNearest)

#=
function range(x)
    min = typemax(eltype(x))
    max = typemin(eltype(x))
    for xi in x
        min = ifelse(min > xi, xi, min)
        max = ifelse(max < xi, xi, max)
    end
    return max - min
end
=#


# ---------------------------------------------------------------------------------------------------
# From https://gist.github.com/jmert/4e1061bb42be80a4e517fc815b83f1bc
"""
	y, ind = lttb(v::AbstractVector, decfactor=10)

	D, ind = lttb(D::GMTdataset, decfactor=10)

The largest triangle, three-buckets reduction of the vector `v` over points `1:N` to a
new, shorter vector `y` at `x` with `N = length(v) ÷ decfactor`.

Returns the shorter vector `y` and indices of picked points in `ind`

See https://skemman.is/bitstream/1946/15343/3/SS_MSthesis.pdf
"""
function lttb(D::GMTdataset, decfactor::Int=10)::GMTdataset
	y, ind = lttb(view(D.data, :, 2), decfactor)
	(size(D,2) == 2) ? mat2ds([D.data[ind,1] y], ref=D) : mat2ds([D.data[ind,1] y D.data[ind,3:end]], ref=D)
end
function lttb(v::AbstractVector, decfactor::Int=10)
	N = length(v)
	N <= decfactor && return similar(v), collect(1:decfactor)
	n = N ÷ decfactor

	w = similar(v, n)
	z = similar(w, Int)

	# always take the first and last data point
	@inbounds begin
		w[1] = y₀ = v[1]
		w[n] = v[N]
		z[1] = x₀ = 1
		z[n] = N
	end

	# split original vector into buckets of equal length (excluding two endpoints)
	#   - s[ii] is the inclusive lower edge of the bin
	s = range(2, N, length = n-1)
	@inline lower(k) = round(Int, s[k])
	@inline upper(k) = k+1 < n ? round(Int, s[k+1]) : N-1
	@inline binrange(k) = lower(k):upper(k)

	# then for each bin
	@inbounds for ii in 1:n-2
		# calculate the mean of the next bin to use as a fixed end of the triangle
		r = binrange(ii+1)
		x₂ = mean(r)
		y₂ = sum(@view v[r]) / length(r)

		# then for each point in this bin, calculate the area of the triangle, keeping # track of the maximum
		r = binrange(ii)
		x̂, ŷ, Â = first(r), v[first(r)], typemin(y₀)
		for jj in r
			x₁, y₁ = jj, v[jj]
			# triangle area:
			A = abs(x₀*(y₁-y₂) + x₁*(y₂-y₀) + x₂*(y₀-y₁)) / 2
			# update coordinate if area is larger
			if A > Â
				x̂, ŷ, Â = x₁, y₁, A
			end
			x₀, y₀ = x₁, y₁
		end
		z[ii+1] = x̂
		w[ii+1] = ŷ
	end

	return w, z
end

#=
function hopalong(num, a, b, c)
    
	x::Float64, y::Float64 = 0, 0
	u, v, d = Float64[], Float64[], Float64[]
	for i = 1:num
		xx = y - sign(x) * sqrt(abs(b*x - c)); yy = a - x; x = xx; y = yy;
		push!(u, x); push!(v, y); push!(d, sqrt(x^2 + y^2))
	end
	return u, v, d
end
=#

# ------------------------------------------------------------------------------------------------------
"""
    D = whereami() -> GMTdataset

Shows your current location plus some additional information (Timezone, Country, City, Zip, IP address).
"""
function whereami()
	io = IOBuffer()
	Downloads.download("https://api.ipify.org?format=csv", io)
	ip = String(take!(io))
	Downloads.download("http://ip-api.com/json/" * ip, io)
	_s = String(take!(io))
	s = split(_s, ",")
	i_lon, i_lat = findfirst(contains.(s, "lon")), findfirst(contains.(s, "lat"))
	i_country, i_city = findfirst(contains.(s, "country")), findfirst(contains.(s, "city"))
	i_zip, i_tz = findfirst(contains.(s, "zip")), findfirst(contains.(s, "timezone"))
	i_region, i_query = findfirst(contains.(s, "regionName")), findfirst(contains.(s, "query"))
	lon = parse(Float64, split(s[i_lon],":")[2])
	lat = parse(Float64, split(s[i_lat],":")[2])
	country = string(split(s[i_country],":")[2][2:end-1])		# The [2:end-1] removes the quotes
	s_city = split(s[i_city],":")[2]
	city = string(s_city[2:lastindex(s_city)-1])
	zip = string(split(s[i_zip],":")[2][2:end-1])
	timezone = string(split(s[i_tz],":")[2][2:end-1])
	region = string(split(s[i_region],":")[2][2:end-1])
	ip = string(split(s[i_query],":")[2][2:end-2])
	mat2ds([lon lat], colnames=["Lon","Lat"], attrib=Dict("Country" => country, "City" => city, "Region" => region, "Zip" => zip, "Timezone" => timezone, "IP" => ip))
end

# ------------------------------------------------------------------------------------------------------
# From this old SO post https://stackoverflow.com/questions/20484581/search-for-files-in-a-folder
"""
    names = searchdir(path, template_name) -> Vector{String}

Search in directory `path` for files starting with `template_name`. Returns a vector with the names.
"""
searchdir(path, key) = filter(x->occursin(key,x), readdir(path))

# ------------------------------------------------------------------------------------------------------
"""
	bb = getbb(D::GDtype) -> Vector{Float64}

Get the bounding box of a dataset (or vector of them). Note: the returned data is based on information
in `D`metadata, not in rescanning the actual data.
"""
getbb(D::GDtype) = isa(D, Vector) ? D[1].ds_bbox : D.ds_bbox

# ------------------------------------------------------------------------------------------------------
"""
    width, height = getsize(GI::GItype) -> Tuple(Int, Int)

Return the width and height of the grid or image.

The grid case is simple but images are more complicated due to the memory layout.
To disambiguate this, we are not relying in 'size(GI)' but on the length of the
x,y coordinates vectors, that are assumed to always be correct. 
"""
function getsize(GI::GItype)
	(GI.layout != "" && GI.layout[2] == 'C') ? (size(GI,2), size(GI,1)) : (length(GI.x), length(GI.y)) .- GI.registration
end

# ------------------------------------------------------------------------------------------------------
"""
    nrows, ncols, nseg = getsize(D::GDtype) -> Tuple(Int, Int, Int)

Return the number of rows, columns and segments in the dataset `D`.
"""
getsize(D::GDtype) = isa(D, GMTdataset) ? (size(D.data,1), size(D.data,2), 1) : (size(D[1].data,1), size(D[1].data,2), size(D,3))

# ------------------------------------------------------------------------------------------------------
"""
	getface(FV::GMTfv, face=1, n=1; view=false) -> Matrix{Float64}

Return the n-th face of the group number `face`. If `view` is true, return the viewable face.

### Example
```julia
FV = cylinder(1.0, 4.0, np=5)
getface(FV, 1, 1, view=true)
```
"""
function getface(FV::GMTfv, face=1, n=1; view=false)
	(view == 1) ? FV.verts[FV.faces_view[face][n,:],:] : FV.verts[FV.faces[face][n,:],:]
end

# ------------------------------------------------------------------------------------------------------
"""
    isclockwise(poly::Matrix{<:AbstractFloat}, view=(0.0,0.0,1.0)) -> Bool

Return true if the 2D/3D `poly` is clockwise when seen from the `view` direction.

### Example
```julia
poly = [0.0 0.0 0.0; 0.0 0.0 1.0; 0.0 1.0 1.0; 0.0 1.0 0.0; 0.0 0.0 0.0]
isclockwise(poly, (1.0,0.1,0.0))
```
"""
function isclockwise(poly::Matrix{<:AbstractFloat}, view=(0.0,0.0,1.0))
	dot(facenorm(poly, normalize=false), [view[1], view[2], view[3]]) <= 0.0
end

# ------------------------------------------------------------------------------------------------------
"""
    settimecol!(D::GDtype, Tcol)

Set the time column in the dataset D (or vector of them).

`Tcol` is either an Int scalar or vector of Ints with the column number(s) that hold the time columns.
"""
settimecol!(D::GDtype, Tc::Int) = isa(D, Vector) ? (D[1].attrib["Timecol"] = string(Tc)) : (D.attrib["Timecol"] = string(Tc))
settimecol!(D::GDtype, Tc::VecOrMat{<:Int}) = isa(D, Vector) ? (D[1].attrib["Timecol"] = join(Tc, ",")) : (D.attrib["Timecol"] = join(Tc, ","))
const set_timecol! = settimecol!
	
# ------------------------------------------------------------------------------------------------------
"""
    setgeom!(D::GDtype, gm::Integer=0; geom::Integer=0)

Changes the geometry of the dataset `D` (or vector of them). The keyword version takes precedence.

### Args
- `D`: A GMTdataset, or a vector of them.
- `geom` | `gm`: the new geometry to apply to D. These are alternatives ways of seting the geometry
  but the keyword version takes precedence.

### Kwargs
- `geom`: the new geometry to apply to D.
"""
function setgeom!(D::GMTdataset, gm::Integer=0; geom::Integer=0)
	D.geom = (geom != 0) ? geom : gm	# The keyword version takes precedenceg
end
function setgeom!(D::Vector{<:GMTdataset}, gm::Integer=0; geom::Integer=0)
	g = (geom != 0) ? geom : gm			# The keyword version takes precedence
	for k = 1:length(D) D[k].geom = g end
end

# ---------------------------------------------------------------------------------------------------
"""
    copyrefA2B!(A, B) -> nothing

Copy the referencing information in object `A` to object `B`.

Both `A` and `B` can be either a GMTgrid or GMTimage or GMTdataset or vectors of GMTdataset objects.
Attention that any previous referencing information stored in object `A` will be lost
(replaced by that on object `B`).
"""
function copyrefA2B!(A, B)
	prj, wkt, epsg = isa(A, Vector) ? (A[1].proj4, A[1].wkt, A[1].epsg) : (A.proj4, A.wkt, A.epsg)
	isa(B, Vector) ? (B[1].proj4 = prj; B[1].wkt = wkt; B[1].epsg = epsg) : (B.proj4 = prj; B.wkt = wkt; B.epsg = epsg)
	return nothing
end

# ------------------------------------------------------------------------------------------------------
"""
    l1, l2 = connect_rectangles(R1, R2) -> Tuple{Matrix{Float64}, Matrix{Float64}}

Find the lines that connect two rectangles and do not intersect any of them (for zoom windows).

- `R1` and `R2` are the [xmin, xmax, ymin, ymax] coordinates of the two rectangles:

### Example:
```julia
R1 = [0.0, 3, 0, 2]; R2 = [5., 10, 5, 8];
l1, l2 = connect_rectangles(R1, R2)
```
"""
connect_rectangles(R1, R2) = connect_rectangles(vec(Float64.(R1)), vec(Float64.(R2)))
function connect_rectangles(R1::Vector{Float64}, R2::Vector{Float64})
	# Create lines that connect the corresponding vertices starting clock-wise at LL corner
	# The idea is to find the lines that do not cross neither of the two rectangles
	lines = [[R1[1] R1[3]; R2[1] R2[3]], [R1[1] R1[4]; R2[1] R2[4]], [R1[2] R1[4]; R2[2] R2[4]], [R1[2] R1[3]; R2[2] R2[3]]]
	rec1 = [R1[1] R1[3]; R1[1] R1[4]; R1[2] R1[4]; R1[2] R1[3]; R1[1] R1[3]];
	rec2 = [R2[1] R2[3]; R2[1] R2[4]; R2[2] R2[4]; R2[2] R2[3]; R2[1] R2[3]];
	auto_cross = [false, false, false, false]
	for k = 1:4			# Find the line that crosses the first rectangle (there is only one)
		size(intersection(lines[k], rec1), 1) > 1 && (auto_cross[k] = true; break)	# Once found one, we are done.
	end

	c, nf = [false, false, false, false], 0
	!auto_cross[1] && (size(intersection(lines[1], rec2),1) == 1) && (nf += 1; c[1] = true)
	!auto_cross[2] && (size(intersection(lines[2], rec2),1) == 1) && (nf += 1; c[2] = true)
	(nf < 2 && !auto_cross[3] && size(intersection(lines[3], rec2),1) == 1) && (nf += 1; c[3] = true)
	(nf < 2 && !auto_cross[4] && size(intersection(lines[4], rec2),1) == 1) && (nf += 1; c[4] = true)
	ind = findall(c)
	return lines[ind[1]], lines[ind[2]] 
end

# ---------------------------------------------------------------------------------------------------
"""
    overlap, value = rect_overlap(xc_1, yc_1, xc_2, yc_2, width1, height1, width2, height2) -> Bool, Float64

Check if two rectangles, aligned with the axes (non-rotated), overlap.

- `xc_1, yc_1`: Center of the first rectangle
- `xc_2, yc_2`: Center of the second rectangle
- `width1, height1`: Width and height of the first rectangle
- `width2, height2`: Width and height of the second rectangle

Returns:
- `overlap`: True if there is overlap, false if there is no overlap
- `value`: The degree of overlap or non-overlap
"""
function rect_overlap(xc_1, yc_1, xc_2, yc_2, width1, height1, width2, height2)
	# https://stackoverflow.com/questions/30009808/what-algorithm-or-approach-for-placing-rectangles-without-overlapp#comment48138654_30010022

	pix = max((xc_2 - xc_1 -(width1/2)-(width2/2)),   (xc_1 - xc_2 -(width2/2)-(width1/2)))
	piy = max((yc_2 - yc_1 -(height1/2)-(height2/2)), (yc_1 - yc_2 -(height2/2)-(height1/2)))
	pivalue = max(pix, piy)
	
	overlap = (pivalue < 0) ? true : false
	return overlap, pivalue
end

# ----------------------------------------------------------------------------
"""
    n = facenorm(M::AbstractMatrix{<:Real}; normalize=true, zfact=1.0)

Calculate the normal vector of a polygon with vertices in `M`.

- `normalize`: By default, it returns the unit vector. If `false`, it returns the non-normalized 
  vector that represents the area of the polygon.

- `zfact`: If different from 1, the last dimension of `M` (normally, the Z variable)
  is multiplied by `zfact`.

### Returns
A 3 elements vector with the components of the normal vector.
"""
function facenorm(M::AbstractMatrix{<:Real}; zfact=1.0, normalize=true)
	# Must take care of the case when the first and last vertices are the same
	p1 = M[1,:]
	last = (p1 == M[end,:]) ? size(M,1)-1 : size(M,1)
	if (zfact == 1.0)
		c = cross2(M[last,:], p1)			# First edge
		for k = 1:last-1					# Loop from first to end-1
			c += cross2(M[k,:], M[k+1,:])	# Sum the rest of edges
		end
	else
		p2 = M[last,:]
		p1[end] *= zfact;	p2[end] *= zfact
		c = cross(p2, p1)					# First edge
		for k = 1:last-1					# Loop from first to end-1
			p1, p2 = M[k,:], M[k+1,:]
			p1[end] *= zfact;	p2[end] *= zfact
			c += cross(p1, p2)				# Sum the rest of edges
		end
	end
	return normalize ? c / norm(c) : c	# The cross product gives us 2 * A(rea)
end

# Like the cross() function from LinearAlgebra but deals also with 2D vectors, though it returns a 3D vector
function cross2(a::AbstractVector, b::AbstractVector)
	(length(a) == length(b) == 2) && return [0, 0, a[1]*b[2] - a[2]*b[1]]
	if !(length(a) == length(b) == 3)
		throw(DimensionMismatch("cross product is only defined for vectors of length 3"))
	end
	a1, a2, a3 = a
	b1, b2, b3 = b
	[a2*b3-a3*b2, a3*b1-a1*b3, a1*b2-a2*b1]
end

# ---------------------------------------------------------------------------------------------------
"""
    A, B, C, D = eq_plane(azim, elev, dist)

Calculate the equation of a plane (Eq: Ax + By + Cz + D = 0) given the azimuth,
elevation and distance to the plane.

- `azim`: Azimuth in degrees (clockwise from North)
- `elev`: Elevation in degrees
- `dist`: Distance to the plane

To compute the distance fom a point to that plane, do:
```julia
	p = (0,0,0);
	dist = abs(A * p[1] + B * p[2] + C * p[3] + D)
```
"""
function eq_plane(azim, elev, dist)
	nx, ny, nz = cosd(elev) * sind(azim), cosd(elev) * cosd(azim), sind(elev)
	Px, Py, Pz = dist * nx, dist * ny, dist * nz
	D = Px * nx + Py * ny + Pz * nz
	return nx, ny, nz, D		# Eq of plane: Ax + By + Cz + D = 0
end

# ---------------------------------------------------------------------------------------------------
"""
	n = bitcat2(n1, n2)::Int64

Concatenate two Int numbers into a 64-bit integer (first 32 bits are n1, last 32 bits are n2).
Note: `n1` and `n2` must fit into a UIn32 integers
"""
function bitcat2(n1, n2)::Int64
	parse(Int, bitstring(UInt32(n1)) * bitstring(UInt32(n2)); base=2)
end

"""
    n1, n2 = bituncat2(N::Int64)

Extract two Int numbers from a 64-bit integer (first 32 bits are n1, last 32 bits are n2).
"""
function bituncat2(N::Int64)::Tuple{Int, Int}
	s = bitstring(N)
	return parse(Int, s[1:32]; base=2), parse(Int, s[33:64]; base=2)
end

# ---------------------------------------------------------------------------------------------------
include("makeDCWs.jl")
	
# ------------------------------------------------------------------------------------------------------
isdefined(Main, :VSCodeServer) && (const VSdisp = Main.VSCodeServer.vscodedisplay)

function ds2df end
function Ginnerjoin end
function Gouterjoin end
function Gleftjoin end
function Grightjoin end
function Gcrossjoin end
function Gsemijoin end
function Gantijoin end

#=
function harmfit(x, y, n::Int=1)
	@assert length(x) == length(y) "x and y must have the same length"
	c = [mean(y .* exp.(-k * x*im)) for k = 1:n]
	h = [2*abs.(c) angle.(c)]

	yy = fill(mean(y), length(x))
	for k = 1:n
		yy .+= h[k,1] * cos.(k * x .+ h[k,2])
	end

	return h, yy
end
=#

#GI.geometry[1].geoms[1].rings[1].vertices.data[1].coords.lat.val

#r = Ref(tuple(5.0, 2.0, 1.0, 6.0))
#p = Base.unsafe_convert(Ptr{Float64}, r)
#u = unsafe_wrap(Array, p, 4)
