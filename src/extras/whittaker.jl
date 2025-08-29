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
	m = length(y)
	D = ddmat(x, d)
	if (weights === nothing)
		E = sparse(I*one(eltype(y)), m, m)
		C = cholesky(E + lambda * D' * D)
		z = C \ (C' \ y)
	else
		W = spdiagm(m, m, 0 => weights)
		C = cholesky(W + lambda * D' * D)
		z = C \ (C' \ (weights .*y))
	end
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
	m = length(y);
	E = sparse(I*one(eltype(y)), m, m)
	D = diff(E, dims=1);
	for k = 2:d  D = diff(D, dims=1)  end
	if (weights === nothing)
		C = cholesky(E + lambda * D' * D)
		z = C \ (C' \ y)
	else
		W = spdiagm(m, m, 0 => weights)
		C = cholesky(W + lambda * D' * D);
		z = C \ (C' \ (weights .* y));
	end
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
function ddmat(x, d)
	# Compute divided differencing matrix of order d
	#   x:  vector of sampling positions
	#   d:  order of diffferences
	# Output
	#   D:  the matrix; D * Y gives divided differences of order d
	#
	# Paul Eilers, 2003
	
	m = length(x)
	if (d == 0)
		D = sparse(I*one(eltype(x)), m, m)
	else
		dx = x[(d + 1):m] - x[1:(m - d)]
		V = spdiagm(m - d, m - d, 0 => 1 ./ dx)
		D = V * diff(ddmat(x, d - 1), dims=1)
	end
	return D
end
