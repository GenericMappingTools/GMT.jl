# From https://github.com/xKDR/Lowess.jl with some (few) modifications.
"""
```julia
lowess(x, y, span = 2 / 3, nsteps = 3, delta = 0.01 * (maximum(x) - minimum(x)))
```

Compute the smooth of a scatterplot of `y` against `x` using robust locally weighted regression.
Input vectors `x` and `y` must contain either integers or floats. Parameters `span` and `delta`
must be of type `T`, where `T <: AbstractFloat`. Returns a vector `ys`; `ys[i]` is the fitted
value at `x[i]`. To get the smooth plot, `ys` must be plotted against `x`.

# Arguments

  - `x::Vector`: Abscissas of the points on the scatterplot. `x` must be ordered.
  - `y::Vector`: Ordinates of the points in the scatterplot.
  - `span`: The amount of smoothing.
  - `nsteps::Integer`: Number of iterations in the robust fit.
  - `delta`: A nonnegative parameter which may be used to save computations.
    Default is `0.01 * (maximum(x) - minimum(x))`.

# Example

```julia
x = sort(10 .* rand(100))
y = sin.(x) .+ 0.5 * rand(100)
ys = lowess(x, y, span=0.2)
scatter(x, y)
plot!(x, ys)
```
"""
function lowess(D::GMTdataset; span=2/3, nsteps=3, delta=0.0)
	(delta == 0.0) && (delta = 0.01 * (D.bbox[2] - D.bbox[1]))
	new_y = lowess(view(D.data, :, 1), view(D.data, :, 2); span=span, nsteps=nsteps, delta=convert(eltype(D.data), delta))
	mat2ds([D.data[:,1] new_y], D)
end

function lowess(x::AbstractVector{R}, y::AbstractVector{S}; span::T=2/3, nsteps::Integer=3,
                delta::T = 0.01 * (maximum(x) - minimum(x))) where {R <: Real, S <: Real, T <: AbstractFloat}
	lowess((R <: AbstractFloat) ? x : Vector{Float64}(x), (S <: AbstractFloat) ? y : Vector{Float64}(y); span=span, nsteps=nsteps, delta=delta)
end

function lowess(mat::Matrix{<:Real}; span=2/3, nsteps::Integer=3, delta=0.1*diff(collect(extrema(view(mat, :,2))), dims=1)[1])
	new_y = lowess(view(mat, :,1), view(mat, :,2); span=span, nsteps=nsteps, delta=delta)
	return [mat[:,1] new_y]
end
function lowess(x::AbstractVector{T}, y::AbstractVector{T}; span::T=2/3, nsteps::Integer=3,
                delta::T = 0.01 * (maximum(x) - minimum(x))) where {T <: AbstractFloat}
	# defining needed variables

	n::Int = length(x)
	ys::Vector{T} = Vector{T}(undef, n)
	rw::Vector{T} = Vector{T}(undef, n)
	res::Vector{T} = Vector{T}(undef, n)

	iter::Int = 0
	ok::Vector{Int} = Vector{Int}(undef, 1)
	# for safety, initialize ok to 0
	ok[1] = 0

	i::Int = 0
	j::Int = 0
	last::Int = 0
	m1::Int = 0
	m2::Int = 0
	nleft::Int = 0
	nright::Int = 0
	ns::Int = 0
	d1::T = 0.0
	d2::T = 0.0
	denom::T = 0.0
	alpha::T = 0.0
	cut::T = 0.0
	cmad::T = 0.0
	c9::T = 0.0
	c1::T = 0.0
	r::T = 0.0

	(n < 2) && (ys[1] = y[1]; return ys)

	ns = max(min(floor(Int, span * n), n), 2)  # at least two, at most n points
	for iter = 1:(nsteps + 1)  # robustness iterations
		nleft = 0
		nright = ns - 1
		last = -1   # index of prev estimated point
		i = 0   # index of current point

		while true
			while (nright < n - 1)
				# move nleft, nright to right if radius decreases
				d1 = x[i + 1] - x[nleft + 1]
				d2 = x[nright + 2] - x[i + 1]
				# if d1 <= d2 with x[nright + 2] == x[nright + 1], lowest fixes
				(d1 <= d2) && break
				# radius will not decrease by move right
				nleft = nleft + 1
				nright = nright + 1
			end

			lowest(x, y, n, x[i + 1], ys, i, nleft, nright, res, (iter > 1), rw, ok)

			# fitted value at x[i + 1]
			(ok == 0) && (ys[i + 1] = y[i + 1])

			# all weights zero - copy over value (all rw==0)
			if (last < i - 1)   # skipped points -- interpolate
				denom = x[i + 1] - x[last + 1]  # non-zero - proof?
				j = last + 1
				for t = (last + 1):(i - 1) # t = j at all times
					alpha = (x[j + 1] - x[last + 1]) / denom
					ys[j + 1] = alpha * ys[i + 1] + (1.0 - alpha) * ys[last + 1]
					j = j + 1
				end
			end

			last = i    # last point actually estimated
			cut = x[last + 1] + delta   # x coord of close points

			# find close points
			i = last + 1
			for t = (last + 1):(n - 1) # t = i at all times
				if (x[i + 1] > cut) # i one beyond last pt within cut
					break
				end

				if (x[i + 1] == x[last + 1])
					ys[i + 1] = ys[last + 1]
					last = i
				end
				i = i + 1
			end
			i = max(last + 1, i - 1)

			# back 1 point so interpolation within delta, but always go forward
			# check do while loop condition
			(last < n - 1) || break
		end

		# residuals
		for i = 0:(n - 1)
			res[i + 1] = y[i + 1] - ys[i + 1]
		end

		(iter > nsteps) && break  # compute robustness weights except last time

		for i = 0:(n - 1)
			rw[i + 1] = abs(res[i + 1])
		end

		sort!(rw)

		m1 = floor(1 + n / 2)
		m2 = n - m1 + 1
		cmad = 3.0 * (rw[m1 + 1] + rw[m2 + 1])  # 6 median abs resid
		c9 = 0.999 * cmad
		c1 = 0.001 * cmad
		for i = 0:(n - 1)
			r = abs(res[i + 1])
			if (r <= c1)    # near 0, avoid underflow
				rw[i + 1] = 1.0
			elseif (r > c9) # near 1, avoid underflow
				rw[i + 1] = 0.0
			else
				rw[i + 1] = (1.0 - (r / cmad)^2)^2
			end
		end
	end
	return ys
end

# --------------------------------------------------------------------------------------------------
function lowest(x::AbstractVector{T}, y::AbstractVector{T}, n::Integer, xs::T, ys::AbstractVector{T},
	ys_pos::Integer, nleft::Integer, nright::Integer, w::AbstractVector{T}, userw::Bool, rw::AbstractVector{T},
	ok::Vector{Int}) where {T <: AbstractFloat}
	b::T = 0.0
	c::T = 0.0
	r::T = 0.0
	nrt::Int = 0

	# Julia indexing starts at 1, so add 1 to all indexes
	range::T = x[n] - x[1]
	h::T = max(xs - x[nleft + 1], x[nright + 1] - xs)
	h9::T = 0.999 * h
	h1::T = 0.001 * h

	# compute weights (pick up all ties on right)
	a::T = 0.0     # sum of weights
	j::Int = nleft   # initialize j

	for i = nleft:(n - 1)  # i = j at all times
		w[j + 1] = 0.0
		r = abs(x[j + 1] - xs)      # replaced fabs with abs
		if (r <= h9)       # small enough for non-zero weight
			if (r > h1)
				w[j + 1] = (1.0 - (r / h)^3)^3
			else
				w[j + 1] = 1.0
			end
			if (userw)
				w[j + 1] = rw[j + 1] * w[j + 1]
			end
			a += w[j + 1]
		elseif (x[j + 1] > xs)      # get out at first zero wt on right
			break
		end
		j = j + 1
	end

	nrt = j - 1     # rightmost pt (may be greater than nright because of ties)
	if (a <= 0.0)
		ok[1] = 0   # ok is a 1 length vector
	else   # weighted least squares
		ok[1] = 1

		# make sum of w[j + 1] == 1
		j = nleft
		for i = nleft:nrt      # i = j at all times
			w[j + 1] = w[j + 1] / a
			j = j + 1
		end

		if (h > 0.0)    # use linear fit
			# find weighted center of x values
			j = nleft
			a = 0.0
			for i = nleft:nrt  # i = j at all times
				a += w[j + 1] * x[j + 1]
				j = j + 1
			end

			b = xs - a

			j = nleft
			c = 0.0
			for i = nleft:nrt  # i = j at all times
				c += w[j + 1] * (x[j + 1] - a) * (x[j + 1] - a)
				j = j + 1
			end

			if (sqrt(c) > 0.001 * range)
				# points are spread out enough to compute slope
				b = b / c

				j = nleft
				for i = nleft:nrt  # i = j at all times
					w[j + 1] = w[j + 1] * (1.0 + b * (x[j + 1] - a))
					j = j + 1
				end
			end
		end

		j = nleft
		ys[ys_pos + 1] = 0.0
		for i = nleft:nrt  # i = j at all times
			ys[ys_pos + 1] += w[j + 1] * y[j + 1]
			j = j + 1
		end
	end
end
