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
function kernelDensity(x::AbstractVector{<:Real}; nbins::Integer=200, bins::Vector{<:Real}=Vector{Real}(),
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

function kernelDensity(mat::AbstractMatrix{<:Real}; nbins::Integer=200, bins::Vector{<:Real}=Vector{Real}(),
                       bandwidth=nothing, kernel::StrSymb="normal")
	D::Vector{GMTdataset} = Vector{GMTdataset}(undef, size(mat,2))
	for k = 1:size(mat,2)
		D[k] = kernelDensity(view(mat,:,k); nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel)
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
	boxplot(reshape(data,length(data),1), (x === nothing) ? Vector{Real}() : [x]; first=true, kwargs...)
end

function boxplot(data::Matrix{<:Real}, x::Vector{<:Real}=Vector{Real}(); first::Bool=true, kwargs...)
	(!isempty(x) && length(x) != size(data,2)) && error("Coordinate vector 'x' must have same size as columns in 'data'")
	d = helper1_boxplot(kwargs)
	fill_color = ((val = find_in_dict(d, [:G :fill], false)[1]) !== nothing) ? val : ""
	w = ((val = find_in_dict(d, [:weights])[1]) !== nothing) ? Float64.(val) : Float64[]
	showOL = (find_in_dict(d, [:outliers])[1] !== nothing)
	D, Dol = helper2_boxplot(data, x, w, 0.0, fill_color, showOL)
	#(fill_color == "") && colorize_candles_violins(D, 1, 1, 1, 0)		# Assign default colors in D's headers
	(first && (is_in_dict(d, [:R :region :limits]) === nothing)) &&
		(d[:R] = round_wesn([D.ds_bbox[1], D.ds_bbox[2], D.ds_bbox[5], D.ds_bbox[12]], false, [0.1,0.1]))
	!isempty(Dol) && (d[:scatter] = (data=Dol, marker=:star, ms="4p", mc="black"))
	common_plot_xyz("", D, "line", first, false, d...)
end

# ------------ For groups ------------------------------
function boxplot(data::Array{<:Real,3}, x::Vector{<:Real}=Vector{Real}(); first::Bool=true, groupwidth=0.75,
                 varcolor_grp=true, kwargs...)
	(!isempty(x) && length(x) != size(data,2)) && error("Coordinate vector 'x' must have same size as columns in 'data'")
	d = helper1_boxplot(kwargs)

	_x = isempty(x) ? collect(1.0:size(data,2)) : x
	n, n_in_grp = 0, size(data,3)
	boxspacing = groupwidth / n_in_grp
	offs = (0:n_in_grp-1) .- ((n_in_grp-1)/2);			# Isto se cada grupo ocupar uma unidade
	D3::Vector{GMTdataset} = Vector{GMTdataset}(undef, n_in_grp)
	fill_color = ((val = find_in_dict(d, [:G :fill], false)[1]) !== nothing) ? val : ""
	w = ((val = find_in_dict(d, [:weights])[1]) !== nothing) ? Float64.(val) : Float64[]
	showOL = (find_in_dict(d, [:outliers])[1] !== nothing)
	Dol::Vector{GMTdataset} = Vector{GMTdataset}(undef, n_in_grp)
	for nig = 1:n_in_grp								# Loop over each element in the group
		D3[nig], Dol[nig] = helper2_boxplot(view(data,:,:,nig), x, w, offs[nig]*boxspacing, fill_color, showOL)
	end
	set_dsBB!(D3)				# Compute and set the global BoundingBox

	n_ds = Int(length(D3) / n_in_grp)
	for m = 1:n_in_grp
		fill_color != "" && continue	# Yep, don't do it because it's already done by helper2_boxplot
		b = (m - 1) * n_ds + 1;		e = b + n_ds - 1
		colorize_candles_violins(D3, n_ds, b, e, varcolor_grp ? m : 0)	# Assign default colores in D's headers
	end

	(first && (is_in_dict(d, [:R :region :limits]) === nothing)) &&
		(d[:R] = round_wesn([D3[1].ds_bbox[1], D3[1].ds_bbox[2], D3[1].ds_bbox[5], D3[1].ds_bbox[12]], false, [0.1,0.1]))
	showOL && (d[:scatter] = (data=Dol, marker=:star, ms="4p", mc="black"))		# Still, 'Dol' may be a vec of empties
	common_plot_xyz("", D3, "line", first, false, d...)
end

boxplot(data::GMTdataset, x=nothing; first::Bool=true, kwargs...) = boxplot(data.data, x; first=first, kwargs...)
boxplot!(data::Vector{<:Real},  x=nothing; kwargs...) = boxplot(data, x; first=false, kwargs...)
boxplot!(data::Matrix{<:Real},  x::Vector{<:Real}=Vector{Real}(); kwargs...) = boxplot(data, x; first=false, kwargs...)
boxplot!(data::Array{<:Real,3}, x::Vector{<:Real}=Vector{Real}(); kwargs...) = boxplot(data, x; first=false, kwargs...)

function helper1_boxplot(kwarg)
	d = KW(kwarg)
	d[:E] = "Y"
	return d
end

# ----------------------------------------------------------------------------------------------------------
function helper2_boxplot(data::AbstractMatrix{<:Real}, x::Vector{<:Real}=Vector{Real}(), w::VMr=Vector{Float64}(),
                         off_in_grp::Float64=0.0, cor="", outliers::Bool=false)
	# OFF_IN_GRP is the offset relative to group's center (zero when groups have only one bar)
	# Returns a Tuple(GMTdataset, GMTdataset)
	_x = isempty(x) ? collect(1.0:size(data,2)) : x
	mat = zeros(size(data,2), 6)
	matOL = Matrix{Float64}[]
	first = true
	for k = 1:size(data,2)			# Loop over number of groups (or number of candle sticks if each group has only 1)
		_w = isa(w, Matrix) ? view(w,:,k) : w
		q0, q25, q50, q75, q100 = _quantile(view(data,:,k), w, [0.0, 0.25, 0.5, 0.75, 1.0])
		if (outliers)
			t = view(data,:,k)
			ind_l = t .< (q25 - 1.5*(q75-q25))
			ind_h = t .> (q75 + 1.5*(q75-q25))
			ind = ind_l .|| ind_h
			if (any(ind))
				q0, q25, q50, q75, q100 = _quantile(t[.!ind], w, [0.0, 0.25, 0.5, 0.75, 1.0])
				t_ol = t[ind]
				matOL = (first) ? [fill(_x[k]+off_in_grp, length(t_ol)) t_ol] :
				                  [matOL; [fill(_x[k]+off_in_grp, length(t_ol)) t_ol]]
				first = false
			end
		end
		mat[k, :] = [_x[k]+off_in_grp q50 q0 q25 q75 q100]
	end
	D = mat2ds(mat, color=cor)
	Dol = !isempty(matOL) ? mat2ds(matOL) : GMTdataset()
	(outliers) && (D.ds_bbox[5]  = !isempty(Dol.ds_bbox) ? min(D.ds_bbox[5],  Dol.ds_bbox[3]) : D.ds_bbox[5];
                   D.ds_bbox[12] = !isempty(Dol.ds_bbox) ? max(D.ds_bbox[12], Dol.ds_bbox[4]) : D.ds_bbox[12])
	return D, Dol
end

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

function violin(data::Matrix{<:Real}, x::Vector{<:Real}=Vector{Real}(); nbins::Integer=100, first::Bool=true,
	            bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, kernel::StrSymb="normal", kwargs...)

	(!isempty(x) && length(x) != size(data,2)) && error("Coordinate vector 'x' must have same size as columns in 'data'")
	scatter = (find_in_kwargs(kwargs, [:scatter])[1] !== nothing)
	Dv, Ds = helper_violin(data, x; nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel, scatter=scatter)
	helper2_violin(Dv, Ds, data, x, 1, false, first, kwargs)
end

# ------------ For groups ------------------------------
#groupwidth  - Proportion of the x-axis interval across which each x-group of boxes should be spread.
#varcolor_grp = true		# If colors varie for each in a group, or are constant inside each group.
function violin(data::Array{<:Real,3}, x::Vector{<:Real}=Vector{Real}(); nbins::Integer=100, first::Bool=true,
	            bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, kernel::StrSymb="normal", groupwidth=0.75,
				varcolor_grp=true, kwargs...)

	(!isempty(x) && length(x) != size(data,2)) && error("Coordinate vector 'x' must have same size as columns in 'data'")
	D3::Vector{GMTdataset} = Vector{GMTdataset}(undef, size(data,2)*size(data,3))
	scatter = (find_in_kwargs(kwargs, [:scatter])[1] !== nothing)
	Ds::Vector{GMTdataset} = (scatter) ? Vector{GMTdataset}(undef, length(D3)) : Vector{GMTdataset}()
	split = (find_in_kwargs(kwargs, [:split])[1] !== nothing)
	(split && size(data,3) != 2) && (split=false; @warn("The split method requires groups of two violins only. Ignoring."))
	(split && scatter) && (scatter=false; @warn("The split method does not implement scattering plot."))

	n, m, n_in_grp = 0, 0, size(data,3)
	boxspacing = groupwidth / n_in_grp
	offs = (0:n_in_grp-1) .- ((n_in_grp-1)/2);			# Isto se cada grupo ocupar uma unidade
	for nig = 1:n_in_grp								# Loop over each element in the group
		_split = (split) ? nig : 0
		Dv, _D = helper_violin(view(data,:,:,nig), x, offs[nig]*boxspacing, n_in_grp; nbins=nbins, bins=bins,
		                       bandwidth=bandwidth, kernel=kernel, scatter=scatter, split=_split)
		for k = 1:size(data,2)  D3[n+=1] = Dv[k]  end	# Loop over number of groups
		(scatter) && for k = 1:size(data,2)  Ds[m+=1], = _D[k]  end		# Store the scatter pts
	end
	helper2_violin(D3, Ds, data, x, n_in_grp, varcolor_grp, first, kwargs)	# Do some house keeping and call the plot funs
end

# ----------------------------------------------------------------------------------------------------------
function helper_violin(data::AbstractMatrix{<:Real}, x::Vector{<:Real}=Vector{Real}(), off_in_grp::Float64=0.0,
                       n_in_grp::Int=1; groupwidth::Float64=0.75, nbins::Integer=100, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, kernel::StrSymb="normal", scatter::Bool=false, split::Int=0)
	# OFF_IN_GRP is the offset relative to group's center (zero when groups have only one violin)
	# SPLIT is either 0 (no split); 1 store only lefy half; 2 store right half
	_x = isempty(x) ? collect(1.0:size(data,2)) : x
	Dv = kernelDensity(data; nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel)
	Ds = (scatter) ? Vector{GMTdataset}(undef, length(Dv)) : Vector{GMTdataset}()
	for k = 1:numel(Dv)
		xd, d = view(Dv[k].data,:,1), view(Dv[k].data,:,2)
		d = 1/2n_in_grp * 0.75 * groupwidth .* d ./ maximum(d)
		if (split == 0)			# Both sides
			_data = [[d; -d[end:-1:1]; d[1]] .+ (_x[k] + off_in_grp) [xd; xd[end:-1:1]; xd[1]]]
		elseif (split == 1)		# Left half
			_data = [[0.0; -d[end:-1:1]; 0.0] .+ _x[k] [xd[end]; xd[end:-1:1]; xd[1]]]
		else					# Right half
			_data = [[d; 0.0; 0.0] .+ _x[k] [xd; xd[end]; xd[1]]]
		end
		Dv[k].data = _data		# Reuse the struct

		if (scatter)
			maxDisplacement = sample1d([collect(xd) d], range=data[:,k]).data	# Interpolate them on the 'edge'
			randOffset = (2*rand(size(data,1))) .- 1;
			Ds[k] = mat2ds([randOffset .* maxDisplacement[:,2] .+ (_x[k] + off_in_grp) maxDisplacement[:,1]])
		end
	end
	set_dsBB!(Dv)				# Compute and set the global BoundingBox
	return Dv, Ds
end

function helper2_violin(D, Ds, data, x, n_in_grp, var_in_grp, first, kwargs)
	# This piece of code is common to viloin(Matrix2D) and violin(Matrix3D)
	# Ds is a GMTdataset with the scatter points or an empty one if no scatters.
	#var_in_grp = true		# If colors varie for each in a group, or are constant inside each group.

	n_ds = Int(length(D) / n_in_grp)
	for m = 1:n_in_grp
		b = (m - 1) * n_ds + 1;		e = b + n_ds - 1
		colorize_candles_violins(D, n_ds, b, e, var_in_grp ? m : 0)
	end

	d = KW(kwargs)
	haskey(d, :split) && delete!(d, :split)		# Could not have been deleted before
	if (find_in_kwargs(kwargs, [:boxplot])[1] !== nothing)			# Request to plot the candle sticks too
		delete!(d, :boxplot)
		do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)
		fill_box = (find_in_kwargs(kwargs, [:G :fill])[1] !== nothing) ? "gray70" : ""
		common_plot_xyz("", D, "line", first, false, d...)			# The violins
		if (isempty(Ds))
			boxplot(data, x; first=false, G=fill_box, show=do_show)	# The candle sticks
		else
			d[:G] = fill_box
			boxplot(data, x; first=false, d...)						# The candle sticks
			d[:show], d[:G], d[:marker] = do_show, "black", "point"
			common_plot_xyz("", Ds, "scatter", false, false, d...)	# The scatter plot
		end
	else
		!isempty(Ds) && (do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)) 
		common_plot_xyz("", D, "line", first, false, d...)			# The violins
		if (!isempty(Ds))
			d[:show], d[:G], d[:marker] = do_show, "black", "point"
			common_plot_xyz("", Ds, "scatter", false, false, d...)	# The scatter pts
		end
	end
end

function colorize_candles_violins(D::Vector{<:GMTdataset}, n::Int, b::Int, e::Int, vc::Int=0)
	# Assign default colors in D.header field to get an automatic coloring
	kk = 0
	if (n <= 8)
		for k = b:e  D[k].header = " -G" * (vc > 0 ? matlab_cycle_colors[vc] : matlab_cycle_colors[kk+=1])  end
	elseif (n <= 20)
		for k = b:e  D[k].header = " -G" * (vc > 0 ? simple_distinct[vc] : simple_distinct[kk+=1])  end
	else	# Use the alphabet_colors and cycle arround if needed (except in the vc (VariableColor per group case))
		for k = b:e  kk+=1; D[k].header = " -G" * (vc > 0 ? alphabet_colors[vc] : alphabet_colors[((kk % 26) != 0) ? kk % 26 : 26])  end
	end
	return D
end

# ----------------------------------------------------------------------------------------------------------
function _quantile(v::AbstractVector{<:Real}, w::AbstractVector{<:Real}, p::AbstractVector{<:Real})
	return isempty(w) ? quantile(v, p) : quantile_weights(v, w, p)
end

function quantile_weights(v::AbstractVector{V}, w::AbstractVector{W}, p::AbstractVector{<:Real}) where {V,W<:Real}
	# This function comes from StatsBase/weights.jl because we don't want to add that dependency just 4 1 fun
	isempty(v) && throw(ArgumentError("quantile of an empty array is undefined"))
	isempty(p) && throw(ArgumentError("empty quantile array"))
	all(x -> 0 <= x <= 1, p) || throw(ArgumentError("input probability out of [0,1] range"))

	wsum = sum(w)
	wsum == 0 && throw(ArgumentError("weight vector cannot sum to zero"))
	length(v) == length(w) || throw(ArgumentError("data and weight vectors must be the same size," *
		"got $(length(v)) and $(length(w))"))
	for x in w
		isnan(x) && throw(ArgumentError("weight vector cannot contain NaN entries"))
		x < 0 && throw(ArgumentError("weight vector cannot contain negative entries"))
	end

	# remove zeros weights and sort
	nz = .!iszero.(w)
	vw = sort!(collect(zip(view(v, nz), view(w, nz))))
	N = length(vw)

	# prepare percentiles
	ppermute = sortperm(p)
	p = p[ppermute]

	# prepare out vector
	out = Vector{typeof(zero(V)/1)}(undef, length(p))
	fill!(out, vw[end][1])

	@inbounds for x in v
		isnan(x) && return fill!(out, x)
	end

	# loop on quantiles
	Sk, Skold = zero(W), zero(W)
	vk, vkold = zero(V), zero(V)
	k = 0

	w1 = vw[1][2]
	for i in 1:length(p)
		h = p[i] * (wsum - w1) + w1
		while Sk <= h
			k += 1
			(k > N) && return out	# out was initialized with maximum v
			Skold, vkold = Sk, vk
			vk, wk = vw[k]
			Sk += wk
		end
		out[ppermute[i]] = vkold + (h - Skold) / (Sk - Skold) * (vk - vkold)
	end
	return out
end
