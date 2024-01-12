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
	h,  = hypot.(x, y)
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
# Incredibly Julia ignores the NaN nature and incredibly min(1,NaN) = NaN, so need to ... fck
extrema_nan(A::Array{<:AbstractFloat}) = minimum_nan(A), maximum_nan(A)
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

function minimum_nan(A::Array{<:AbstractFloat})
	mi = minimum(A);	!isnan(mi) && return mi		# The noNaNs version is a order of magnitude faster
	mi = typemax(eltype(A))
	@inbounds for k in eachindex(A) mi = ifelse(!isnan(A[k]), min(mi, A[k]), mi)  end
	mi == typemax(eltype(A)) && (mi = convert(eltype(A), NaN))	# Better to return NaN then +Inf
	return mi
end
minimum_nan(A) = minimum(A)

function maximum_nan(A::Array{<:AbstractFloat})
	ma = maximum(A);	!isnan(ma) && return ma		# The noNaNs version is a order of magnitude faster
	ma = typemin(eltype(A))
	@inbounds for k in eachindex(A) ma = ifelse(!isnan(A[k]), max(ma, A[k]), ma)  end
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
function Base.extrema(A::Array{<:Complex{<:AbstractFloat}})
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
					reg, NaN, "", "", "", "", String[], _x, _y, Vector{Float64}(), z, "x", "y", "", "z", "BCB", 1f0, 0f0, 0, 2)
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
const numel = length
dec2bin(n::Integer, mindigits::Int=0) = string(n, base=2, pad=mindigits)
bin2dec(b::Union{AbstractString, Char}) = parse(Int, b, base=2)

function fileparts(fn::String)
	pato, ext = splitext(fn)
	pato, fname = splitdir(pato)
	return pato, fname, ext
end

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

isdefined(Main, :VSCodeServer) && (const VSdisp = Main.VSCodeServer.vscodedisplay)

function ds2df end
function Ginnerjoin end
function Gouterjoin end
function Gleftjoin end
function Grightjoin end
function Gcrossjoin end
function Gsemijoin end
function Gantijoin end
