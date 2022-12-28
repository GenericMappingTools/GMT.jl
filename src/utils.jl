# Collect generic utility functions in this file

""" Return the decimal part of a float number `x`"""
getdecimal(x::AbstractFloat) = x - trunc(Int, x)

""" Return an ierator over data skipping non-finite values"""
skipnan(itr) = Iterators.filter(el->isfinite(el), itr)

square(x) = x^2

function funcurve(f::Function, lims::VMr, n=100)
	# Geneate a curve between lims[1] and lims[2] having the form of function 'f'
	if     (f == exp)    x = log.(lims)
	elseif (f == log)    x = exp.(lims)
	elseif (f == log10)  x = exp10.(lims)
	elseif (f == exp10)  x = log10.(lims)
	elseif (f == sqrt)   x = square.(lims)
	elseif (f == square) x = sqrt.(lims)
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
	h,  = hypot.(x, y)
	rho = hypot.(h, z)
	elev = (deg) ? atand.(z, h) : atan.(z, h)
	az   = (deg) ? atand.(y, x) : atan.(y, x)
	return az, elev, rho
end

# ----------------------------------------------------------------------------------------------------------
"""
    count_chars(str::AbstractString, c::Char)

Count the number of characters `c` in the AbstracString `str`
"""
function count_chars(str::AbstractString, c::Char)::Int
	count(i->(i == ','), str)
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
function extrema_nan(A)
	# Incredibly Julia ignores the NaN nature and incredibly min(1,NaN) = NaN, so need to ... fck
	if (eltype(A) <: AbstractFloat)  return minimum_nan(A), maximum_nan(A)
	else                             return extrema(A)
	end
end

function minimum_nan(A)
	#return (eltype(A) <: AbstractFloat) ? minimum(x->isnan(x) ?  Inf : x,A) : minimum(A)
	if (eltype(A) <: AbstractFloat)
		mi = typemax(eltype(A))
		@inbounds for k in eachindex(A) !isnan(A[k]) && (mi = min(mi, A[k])) end
		mi == typemax(eltype(A)) && (mi = convert(eltype(A), NaN))	# Better to return NaN than +Inf
		mi
	else
		minimum(A)
	end
end

function maximum_nan(A)
	#return (eltype(A) <: AbstractFloat) ? maximum(x->isnan(x) ? -Inf : x,A) : maximum(A)
	if (eltype(A) <: AbstractFloat)
		ma = typemin(eltype(A))
		@inbounds for k in eachindex(A) !isnan(A[k]) && (ma = max(ma, A[k])) end
		ma == typemin(eltype(A)) && (ma = convert(eltype(A), NaN))	# Better to return NaN than -Inf
		ma
	else
		maximum(A)
	end
end
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
		G = GMTgrid("", "", 0, [_x[1], _x[end], _y[1], _y[end], minimum(z), maximum(z)], [inc, inc],
					reg, NaN, "", "", "", "", String[], _x, _y, Vector{Float64}(), z, "x", "y", "", "z", "", 1f0, 0f0, 0, 0)
		return G
	else
		return x,y,z
	end
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
    R = rescale(A, a=0.0, b=1.0; inputmin=nothing, inputmax=nothing, stretch=false, type=nothing)

- `A`: is either a GMTgrid, GMTimage, Matrix{AbstractArray} or a file name. In later case the file is read
   with a call to `gmtread` that automatically decides how to read it based on the file extension ... not 100% safe.
- `rescale(A)` rescales all entries of an array `A` to [0,1].
- `rescale(A,b,c)` rescales all entries of A to the interval [b,c].
- `rescale(..., inputmin=imin)` sets the lower bound `imin` for the input range. Input values less
   than `imin` will be replaced with `imin`. The default is min(A).
- `rescale(..., inputmax=imax)` sets the lower bound `imax` for the input range. Input values greater
   than `imax` will be replaced with `imax`. The default is max(A).
- `rescale(..., stretch=true)` automatically determines [inputmin inputmax] via a call to histogram that
   will (try to) find good limits for histogram stretching. 
- `type`: Converts the scaled array to this data type. Valid options are all Unsigned types (e.g. `UInt8`).
   Default returns the same data type as `A` if it's an AbstractFloat, or Flot64 if `A` is an integer.

Returns a GMTgrid if `A` is a GMTgrid of floats, a GMTimage if `A` is a GMTimage and `type` is used or
an array of Float32|64 otherwise.
"""
function rescale(A::String, low=0.0, up=1.0; inputmin=nothing, inputmax=nothing, stretch::Bool=false, type=nothing)
	GI = gmtread(A)
	rescale(GI, low, up, inputmin=inputmin, inputmax=inputmax, stretch=stretch, type=type)
end
function rescale(A::AbstractArray, low=0.0, up=1.0; inputmin=nothing, inputmax=nothing, stretch::Bool=false, type=nothing)
	(type !== nothing && (!isa(type, DataType) || !(type <: Unsigned))) && error("The 'type' variable must be an Unsigned DataType")
	((inputmin !== nothing || inputmax !== nothing) && stretch) && @warn("The `stretch` option overrules `inputmin|max`.")
	if (stretch)
		inputmin, inputmax = histogram(A, getauto=true)
	end
	(inputmin === nothing) && (mi = (isa(A, GItype)) ? A.range[5] : minimum_nan(A))
	(inputmax === nothing) && (ma = (isa(A, GItype)) ? A.range[6] : maximum_nan(A))
	_inmin = convert(Float64, (inputmin === nothing) ? mi : inputmin)
	_inmax = convert(Float64, (inputmax === nothing) ? ma : inputmax)
	d1 = _inmax - _inmin
	d2 = up - low
	sc::Float64 = d2 / d1
	if (type !== nothing)
		(low != 0.0 || up != 1.0) && (@warn("When converting to Unsigned must have a=0, b=1"); low=0.0; up=1.0)
		o = Array{type}(undef, size(A))
		sc *= typemax(type)
		low *= typemax(type)
		if (inputmin === nothing && inputmax === nothing)	# Faster case. No IFs in loop
			@inbounds Threads.@threads for k = 1:numel(A)  o[k] = round(type, low + (A[k] -_inmin) * sc)  end
		else
			low_i, up_i = round(type, low), round(type, up*typemax(type))
			@inbounds Threads.@threads for k = 1:numel(A)
				o[k] = (A[k] < _inmin) ? low_i : ((A[k] > _inmax) ? up_i : round(type, low + (A[k] -_inmin) * sc))
			end
		end
		return isa(A, GItype) ? mat2img(o, A) : o
	else
		oType = isa(eltype(A), AbstractFloat) ? eltype(A) : Float64
		o = Array{oType}(undef, size(A))
		if (inputmin === nothing && inputmax === nothing)	# Faster case. No IFs in loop
			@inbounds Threads.@threads for k = 1:numel(A)  o[k] = low + (A[k] -_inmin) * sc  end
		else
			@inbounds Threads.@threads for k = 1:numel(A)
				o[k] = (A[k] < _inmin) ? low : ((A[k] > _inmax) ? up : low + (A[k] -_inmin) * sc)
			end
		end
		return isa(A, GItype) ? mat2grid(o, A) : o
	end
end

# --------------------------------------------------------------------------------------------------
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

# EDIPO SECTION
# ---------------------------------------------------------------------------------------------------
linspace(start, stop, length=100) = range(start, stop=stop, length=length)
logspace(start, stop, length=100) = exp10.(range(start, stop=stop, length=length))
fields(arg) = fieldnames(typeof(arg))
fields(arg::Array) = fieldnames(typeof(arg[1]))
#feval(fn_str, args...) = eval(Symbol(fn_str))(args...)
const numel = length
