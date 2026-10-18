"""
    Dout = whittaker(D::GMTdataset, lambda, d=2; weights=nothing)
or

    z = whittaker(x::AbstractVecOrMat{<:Real}, y::VecOrMat{<:Real}, lambda, d=2; weights=nothing)

Perform a Whittaker-Henderson smoothing and interpolation.

### Args
- `D`:      A GMTdatset with a `x,y` data series.
- `x,y`:    In alternative to the `D` form, pass vectors of `x` and `y`.
- `lambda`: Smoothing parameter; large lambda gives smoother result.
- `d`:      Order of differences (default = 2).

### Kwargs
- `weights`: Weights (0/1 for missing/non-missing data). Note, if input `y` contains NaNs, we replace them
  by a another flag value and automatically set `w`.

### Citations
- A Perfect Smoother (https://pubs.acs.org/doi/10.1021/ac034173t)
- 'Smoothing and interpolation with finite differences'. Eilers P. H. C, 1994. (http://dl.acm.org/citation.cfm?id=180916)

- Transtaled to Julia from Matlab code from 'A Perfect Smoother'. Paul H. C. Eilers. Analytical Chemistry 2003 75 (14), 3631-3636. DOI: 10.1021/ac034173t


### Examples

```julia
D = gmtread(TESTSDIR * "/assets/nmr_with_weights_and_x.csv");
D2 = whittaker(D, 2e4, 2);
D3 = whittaker(D, 2e4, 3);
plot(D)
plot!(D2, lc=:red, lt=1, legend="Degree 2", plot=(data=D3, lc=:blue, lt=1, legend="Degree 3"), show=1)
```

```julia
t = 2001:0.003:2007;
_v = 5*cospi.((t .- 2000)/2); v = _v + (5*rand(length(t)) .- 2.5);
v[2002.6 .< t .< 2003.4] .= NaN;
z = whittaker(t, v, 0.01, 3);
plot(t, v, legend="Noisy", plot=(data=[t _v], lc=:green, lt=1, legend="Original"))
plot!(t, z, lc=:red, lt=1, legend="Degree 3", show=1)
```
"""
function whittaker(D::GMTdataset, lambda::Real, d::Int=2; weights=nothing)
	indNaN = isnan.(view(D.data, :, 2))
	gotNaN = any(indNaN)
	if (!gotNaN)
		z = whittaker(view(D.data, :, 1), view(D.data, :, 2), lambda, d, weights=weights, checkedNaN=true)
	else
		y = D.data[:, 2];	y[indNaN] .= zero(eltype(D.data));
		w = weights === nothing ? Int32.(.!indNaN) : (weights[indNaN] .= zero(eltype(D.data)))
		z = whittaker(view(D.data, :, 1), y, lambda, d, weights=w, checkedNaN=true)
	end
	Dout = deepcopy(D)
	Dout.data[:, 2] = z
	set_dsBB!(Dout)
	return Dout
end

# ------------------------------------------------------------------------------------
function whittaker(x::AbstractVecOrMat{<:Real}, y::AbstractVecOrMat{<:Real}, lambda::Real, d::Int=2; weights=nothing, checkedNaN::Bool=false)
	y, gotNaN, indNaN, weights = helper_whits(y, weights, checkedNaN)	# Check NaNs and take measures if yes
	z = whit_solve(ddmat(x, d), y, lambda, weights)
	(gotNaN) && (y[indNaN] .= NaN)
	return z
end

# ------------------------------------------------------------------------------------
# Non-documented and possibly to be commented as it produces weird results.
# D = gmtread(TESTSDIR * "/assets/nmr_with_weights_and_x.csv");
# z1 = whittaker(D[:,2], 2e4);
# z2 = whittaker(D[:,2], 2e4, 3);
# plot(D)
# plot!(D[:,1], z1, lc=:red, lt=1, plot=(data=[D[:,1] z2], lc=:blue, lt=1), title="NMR spectrum and optimal smooth", show=1)
function whittaker(y::AbstractVecOrMat{<:Real}, lambda, d=2; weights=nothing, checkedNaN::Bool=false)
	y, gotNaN, indNaN, weights = helper_whits(y, weights, checkedNaN)	# Check NaNs and take measures if yes
	z = whit_solve(ddmat(nothing, d, length(y)), y, lambda, weights)
	(gotNaN) && (y[indNaN] .= NaN)
	return z
end

function helper_whits(y, weights, checkedNaN)
	gotNaN, indNaN = false, [false, false]
	if (!checkedNaN)
		indNaN = isnan.(y)
		if ((gotNaN = any(indNaN)))
			y[indNaN] .= zero(eltype(y))
			weights = (weights === nothing) ? Int32.(.!indNaN) : (weights[indNaN] .= zero(eltype(weights)))
		end
	end
	return y, gotNaN, indNaN, weights
end

# ------------------------------------------------------------------------------------
function ddmat(x, d, m=length(x))
	# Compute divided differencing matrix of order d
	#   x:  vector of sampling positions, or `nothing` for plain (unit spacing, unscaled) differences
	#   d:  order of diffferences
	#   m:  number of points (only needed when `x === nothing`)
	# Output
	#   Dc: the (m-d) x (d+1) band of the (m-d) x m matrix D, Dc[i,k] = D[i,i+k-1];
	#       D * Y gives divided differences of order d
	#
	# Paul Eilers, 2003. Band storage instead of a sparse matrix.

	Dc = ones(Float64, m, 1)					# Order 0: the identity
	for k = 1:d
		n = m - k
		Dn = zeros(Float64, n, k + 1)
		for i = 1:n, j = 1:k+1
			Dn[i,j] = (j > 1 ? Dc[i+1,j-1] : 0.0) - (j <= k ? Dc[i,j] : 0.0)	# diff(D, dims=1)
		end
		if (x !== nothing)						# V = diag(1 ./ dx) * diff(D)
			for i = 1:n  Dn[i,:] ./= (x[i+k] - x[i])  end
		end
		Dc = Dn
	end
	return Dc
end

# ------------------------------------------------------------------------------------
"""
Solve (W + lambda * D'D) z = W*y, where D is given by its band `Dc` (see `ddmat`) and W = diag(weights)
(the identity when `weights === nothing`). The system matrix is symmetric positive definite and banded
with half-bandwidth d, so a banded Cholesky does it in O(m*d^2) with no sparse-matrix machinery.
"""
function whit_solve(Dc::Matrix{Float64}, y, lambda::Real, weights)
	m = length(y)
	d = size(Dc, 2) - 1
	(m > d) || error("whittaker: need more than $d points for differences of order $d")
	B = zeros(Float64, d + 1, m)			# Lower band: B[k+1, i] = A[i+k, i]
	for r = 1:size(Dc, 1), a = 0:d, b = 0:a	# A = lambda * D'D
		B[a-b+1, r+b] += lambda * Dc[r,a+1] * Dc[r,b+1]
	end
	rhs = Vector{Float64}(undef, m)
	for i = 1:m
		w = (weights === nothing) ? 1.0 : Float64(weights[i])
		B[1,i] += w						# A += W
		rhs[i] = w * y[i]
	end

	for j = 1:m								# In-place banded Cholesky, A = L*L'. L[i,j] = B[i-j+1, j]
		s = B[1,j]
		for k = max(1, j-d):j-1  s -= B[j-k+1,k]^2  end
		(s > 0) || error("whittaker: system is not positive definite (too few non-zero weights?)")
		B[1,j] = sqrt(s)
		for i = j+1:min(m, j+d)
			s = B[i-j+1,j]
			for k = max(1, i-d):j-1  s -= B[i-k+1,k] * B[j-k+1,k]  end
			B[i-j+1,j] = s / B[1,j]
		end
	end
	for i = 1:m								# Forward: L u = rhs
		s = rhs[i]
		for k = max(1, i-d):i-1  s -= B[i-k+1,k] * rhs[k]  end
		rhs[i] = s / B[1,i]
	end
	for i = m:-1:1							# Backward: L' z = u
		s = rhs[i]
		for k = i+1:min(m, i+d)  s -= B[k-i+1,i] * rhs[k]  end
		rhs[i] = s / B[1,i]
	end
	return rhs
end
