"""
    D = kernelDensity(x::Vector{<:Real}; nbins::Integer=200, bins::Vector{<:Real}=Vector{Real}(),
                      bandwidth=nothing, kernel::StrSymb="normal")

`x`: calculate the kernel density 'd' of a dataset X for query points 'xd' The density, by feault, is
     estimated using a gaussian kernel with a width obtained with the Silverman's rule.
`nbins`: points are queried between MIN(X(:)) and MAX(X(:))
`bins`: Calculates the density for the query points specified by BINS. The values are used as the
        query points directly. Default is 200 points.
`bandwidth`: uses the 'bandwidth' to calculate the kernel density. It must be a scalar. BINS may be
             an empty array in order to use the default described above.
`kernel`: Uses the kernel function specified by KERNEL to calculate the density.
          The kernel may be: 'Normal' (default) or 'Uniform'
"""
function kernelDensity(x::Vector{<:Real}; nbins::Integer=200, bins::Vector{<:Real}=Vector{Real}(),
                       bandwidth=nothing, kernel::StrSymb="normal")

	any(isnan.(x)) && (x = x[!isnan.(x)])
	h::Float64 = (bandwidth === nothing) ? 0.0 : bandwidth	# Because of the permanent type Any shit

	ker = lowercase(string(kernel))
	if (startswith(ker, "nor"))				# "normal" 
		f = Normal;
	elseif (startswith(ker, "uni"))			# "uniform"
		f = Uniform;
		(bandwidth === nothing) && (h = 0.15 * (maximum(x) - minimum(x)))
	end
	#h = ((4*(std(x).^5))/(3*numel(x))).^(1/5)
	(h == 0.0) && (h = default_bandwidth(x))

	xd::Vector{<:Float64} = !isempty(bins) ? sort(bins) : collect(linspace(minimum(x)-0h, maximum(x)+0h, nbins))
	d = zeros(size(xd))
	c1::Float64 = numel(x)*h
	@inbounds for i = 1:numel(xd)
		d[i] = sum(f((x .- xd[i])/h)) / c1
	end
	any(isnan.(d)) && (d[isnan.(d)] .= 0.0)
	return mat2ds([xd d])
end

function kernelDensity(mat::Matrix{<:Real}; nbins::Integer=200, bins::Vector{<:Real}=Vector{Real}(),
                       bandwidth=nothing, kernel::StrSymb="normal")
	D::Vector{GMTdataset} = Vector{GMTdataset}(undef, size(mat,2))
	for k = 1:size(mat,2)
		D[k] = kernelDensity(mat[:,k]; nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel)
	end
	return D
end

# Silverman's rule of thumb for KDE bandwidth selection from KernelDensity.jl
function default_bandwidth(data::VMr, alpha::Float64 = 0.9)::Float64
	ndata = length(data)
	ndata <= 1 && return alpha

	# Calculate width using variance and IQR
	var_width = std(data)
	q25, q75 = quantile(data, [0.25, 0.75])
	quantile_width = (q75 - q25) / 1.34

	# Deal with edge cases with 0 IQR or variance
	width = min(var_width, quantile_width)
	(width == 0.0) && (width = (var_width == 0.0) ? 1.0 : var_width)

	return alpha * width * ndata^(-0.2)
end

"""
```julia
Normal(x::Vector{<:Real})     # standard Normal distribution with zero mean and unit variance
Normal(x, μ)       # Normal distribution with mean μ and unit variance
Normal(x, μ, σ)    # Normal distribution with mean μ and variance σ^2
```
"""
Normal(x::Vector{<:Real}) = 1/(sqrt(2*pi)) * exp.(-0.5*(x .^2))::Vector{Float64}
Normal(x::Vector{<:Real}, μ::Float64) = 1/(sqrt(2*pi)) * exp.(-0.5*((x .- μ) .^2))::Vector{Float64}
Normal(x::Vector{<:Real}, μ::Float64, σ::Float64)::Vector{Float64} = 1/(σ *sqrt(2*pi)) * exp.(-0.5*(((x .- μ)/σ) .^2))

"""
```julia
Uniform(x::Vector{<:Real}, a=-1.0, b=1.0)    # Uniform distribution over [a, b]
```
"""
function Uniform(x::Vector{<:Real}, a=-1.0, b=1.0)
	(a == -1 && b == 1) && return 0.5 * (abs.(x) .<= 1)
	r = zeros(length(x))
	r[a .<= x .<= b] .= 1 / (b - a)
	return r
end

# --------------------------------------------------------------------------------
function density(x, nbins::Integer=200; bins::Vector{<:Real}=Vector{Real}(),
                 bandwidth=nothing, kernel::StrSymb="normal", first::Bool=true, kwargs...)
	D = kernelDensity(x; nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel)
	common_plot_xyz("", D, "line", first, false, kwargs...)
end

"""
"""
# --------------------------------------------------------------------------------
function boxplot(data::Vector{<:Real}, x=nothing; first::Bool=true, kwargs...)
	d = KW(kwargs)
	q0, q25, q50, q75, q100 = quantile(data, [0.0, 0.25, 0.5, 0.75, 1.0])
	d[:E] = "Y"
	_x = (x === nothing) ? 1.0 : x
	(first && (is_in_dict(d, [:R :region :limits]) === nothing)) && (d[:R] = (_x -0.1*abs(_x), _x+0.1*abs(_x), q0, q100))
	common_plot_xyz("", [_x q50 q0 q25 q75 q100], "line", first, false, d...)
end

function boxplot(data::Matrix{<:Real}, x::Vector{<:Real}=Vector{Real}(); first::Bool=true, kwargs...)
	d = KW(kwargs)
	(!isempty(x) && length(x) != size(data,2)) && error("Coordinate vector 'x' must have same size as columns in 'data'")
	_x = isempty(x) ? collect(1.0:size(data,2)) : x
	mat = zeros(size(data,2), 6)
	for k = 1:size(data,2)
		q0, q25, q50, q75, q100 = quantile(view(data,:,k), [0.0, 0.25, 0.5, 0.75, 1.0])
		mat[k, :] = [_x[k] q50 q0 q25 q75 q100]
	end
	d[:E] = "Y"
	(first && (is_in_dict(d, [:R :region :limits]) === nothing)) &&
		(d[:R] = round_wesn([minimum(mat[:,1]), maximum(mat[:,1]), minimum(mat[:,3]), maximum(mat[:,6])], false, [0.1,0]))
	common_plot_xyz("", mat, "line", first, false, d...)
end
boxplot(data::GMTdataset, x=nothing; first::Bool=true, kwargs...) = boxplot(data.data, x; first=first, kwargs...)
boxplot!(data::Vector{<:Real}, x=nothing; kwargs...) = boxplot(data, x; first=false, kwargs...)
boxplot!(data::Matrix{<:Real}, x::Vector{<:Real}=Vector{Real}(); kwargs...) = boxplot(data, x; first=false, kwargs...)

"""
"""
# --------------------------------------------------------------------------------
function violin(data::Vector{<:Real}, x=nothing; nbins::Integer=100, bins::Vector{<:Real}=Vector{Real}(),
                bandwidth=nothing, kernel::StrSymb="normal", first::Bool=true, kwargs...)

	D = kernelDensity(data; nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel)
	xd, d = view(D.data,:,1), view(D.data,:,2)
	(x !== nothing) && (xd .+= x)
	_data = [[d; -d[end:-1:1]] [xd; xd[end:-1:1]]]
	common_plot_xyz("", _data, "line", first, false, kwargs...)
end

function violin(data::Matrix{<:Real}, x::Vector{<:Real}=Vector{Real}(); nbins::Integer=100,
	            bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, kernel::StrSymb="normal", first::Bool=true, kwargs...)

	(!isempty(x) && length(x) != size(data,2)) && error("Coordinate vector 'x' must have same size as columns in 'data'")
	_x = isempty(x) ? collect(1.0:size(data,2)) : x
	Dv = kernelDensity(data; nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel)
	for k = 1:numel(Dv)
		xd, d = view(Dv[k].data,:,1), view(Dv[k].data,:,2)
		_data = [[d; -d[end:-1:1]].+_x[k] [xd; xd[end:-1:1]]]
		Dv[k].data = _data		# Reuse the struct
	end
	set_dsBB!(Dv)				# Compute and set the global BoundingBox
	common_plot_xyz("", Dv, "line", first, false, kwargs...)
end
