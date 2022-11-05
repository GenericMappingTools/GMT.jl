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

# ----------------------------------------------------------------------------------------------------------
function density(x, nbins::Integer=200; bins::Vector{<:Real}=Vector{Real}(),
                 bandwidth=nothing, kernel::StrSymb="normal", first::Bool=true, kwargs...)
	D = kernelDensity(x; nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel)
	common_plot_xyz("", D, "line", first, false, kwargs...)
end

"""
    boxplot(data, x=nothing; x=nothing, kwargs...)

- `data`: A vector (plots a single box), a Matrix (plots n columns boxes), a MxNxG (plots `G` groups)
          of `N` columns boxes
- `x` or keyword x=??: a coordinate vector (or a single location when `data` is a vector)
          where to plot the boxes. Default plots them at 1:n_boxes or 1:n_groups.
- `outliers`: If other than a NamedTuple, plots outliers (1.5IQR) with the default black 5pt stars.
              If argument is a NamedTuple (marker=??, size=??, color=??), where `marker` is one of
			  the `plots` marker symbols, plots the outliers with those specifications. Any missing
			  spec default to the above values. i.e `outliers=(size="3p")` plots black 3 pt stars.
- `fill`:
- `horizontal` or `hbar`:
- `weights`:
- `region` or `limits`:
- `xticks` or `yticks`:
- `separator`:

"""
# ----------------------------------------------------------------------------------------------------------
function boxplot(data::Vector{<:Real}, x_=nothing; x=nothing, first::Bool=true, kwargs...)
	(x === nothing) && (x = x_)			# To allow both ways (positional & kword)
	boxplot(reshape(data,length(data),1), (x === nothing) ? Vector{Real}() : [x]; first=first, kwargs...)
end

function boxplot(data::Matrix{<:Real}, x_::Vector{<:Real}=Vector{Real}(); x::Vector{<:Real}=Vector{Real}(),
                 first::Bool=true, kwargs...)
	isempty(x) && (x = x_)					# To allow both ways (positional & kword)
	(!isempty(x) && length(x) != size(data,2)) && error("Coordinate vector 'x' must have same size as columns in 'data'")
	d, isVert = helper1_boxplot(kwargs)
	fill = ((val = find_in_dict(d, [:G :fill], false)[1]) !== nothing) ? val : ""
	w = ((val = find_in_dict(d, [:weights])[1]) !== nothing) ? Float64.(val) : Float64[]
	showOL = ((OLcmd   = find_in_dict(d, [:outliers])[1]) !== nothing)
	#showSep = ((SEPcmd = find_in_dict(d, [:separator])[1]) !== nothing)
	(!showOL && (val   = find_in_dict(d, [:otl])[1]) == true) && (showOL = true)	# Another violin private opt
	D, Dol = helper2_boxplot(data, x, w, 0.0, fill, showOL, isVert)	# Two GMTdataset's. Second may be empty
	Dv = (fill == "gray70") ? ds2ds(D, G="gray70") : ds2ds(D)		# Split it so we can assign colors to each candle.
	if (fill != "" && fill != "gray70")								# Only paint the candles if explicitly requested.
		custom_colors = helper_ds_fill(d)	# A helper function of mat2ds()
		colorize_candles_violins(Dv, length(Dv), 1, length(Dv), 0, custom_colors)	# Assign default colors in Dv's headers
	end

	i1,i2,i3,i4 = (isVert) ? (1,2,5,12) : (5,12,3,4)
	(first && (is_in_dict(d, [:R :region :limits]) === nothing)) &&
		(d[:R] = round_wesn([D.ds_bbox[i1], D.ds_bbox[i2], D.ds_bbox[i3], D.ds_bbox[i4]], false, [0.1,0.1]))

	if (!isempty(Dol))
		mk, ms, mc = parse_candle_outliers_par(OLcmd)
		d[:scatter] = (data=Dol, marker=mk, ms=ms, mc=mc)		# Still, 'Dol' may be a vec of empties
	end
	#!isempty(Dol) && (d[:scatter] = (data=Dol, marker="a", ms="5p", mc="black"))
	if (first)			# Need tis check to not duplicate ticks when called from violin
		xt = ((val = find_in_dict(d, [:xticks :yticks])[1]) !== nothing) ? val : num4ticks(D[:, isVert ? 1 : 2])
		(isVert) ? (d[:xticks] = xt) : (d[:yticks] = xt)			# Vertical or Horizontal sticks
	end
	common_plot_xyz("", Dv, "boxplot", first, false, d...)
end

# ------------ For groups ----------------------------------------------------------------------------------
function boxplot(data::Array{<:Real,3}, x_::Vector{<:Real}=Vector{Real}();  x::Vector{<:Real}=Vector{Real}(),
                 first::Bool=true, groupwidth=0.75, varcolor_grp=true, kwargs...)
	isempty(x) && (x = x_)			# To allow both ways (positional & kword)
	(!isempty(x) && length(x) != size(data,2)) && error("Coordinate vector 'x' must have same size as columns in 'data'")
	d, isVert = helper1_boxplot(kwargs)

	n_in_grp = size(data,3)
	boxspacing = groupwidth / n_in_grp
	offs = (0:n_in_grp-1) .- ((n_in_grp-1)/2);			# Isto se cada grupo ocupar uma unidade
	D3 = Vector{GMTdataset}(undef, n_in_grp)
	fill = ((val = find_in_dict(d, [:G :fill], false)[1]) !== nothing) ? val : ""
	w = ((val = find_in_dict(d, [:weights])[1]) !== nothing) ? Float64.(val) : Float64[]
	showOL = ((OLcmd = find_in_dict(d, [:outliers])[1]) !== nothing)
	(!showOL && (val = find_in_dict(d, [:otl])[1]) == true) && (showOL = true)	# Another violin private opt
	Dol::Vector{GMTdataset} = Vector{GMTdataset}(undef, n_in_grp)
	mi, ma = 1e100, -1e100
	for nig = 1:n_in_grp								# Loop over each element in the group
		D3[nig], Dol[nig] = helper2_boxplot(view(data,:,:,nig), x, w, offs[nig]*boxspacing, fill, showOL, isVert)
		mi, ma = min(mi, D3[nig].ds_bbox[5]), max(ma, D3[nig].ds_bbox[12])
	end
	set_dsBB!(D3)				# Compute and set the global BoundingBox
	D3[1].ds_bbox[5], D3[1].ds_bbox[12] = mi, ma		# Global min/max that incles the outliers

	if (fill != "")
		custom_colors = (fill == "gray70") ? ["gray70"] : String[]
		!varcolor_grp && (D3 = ds2ds(ds2ds(D3)); set_dsBB!(D3))		# Crazzy op and wasteful but thse Ds are small
		n_ds = Int(length(D3) / n_in_grp)
		for m = 1:n_in_grp
			b = (m - 1) * n_ds + 1;		e = b + n_ds - 1
			colorize_candles_violins(D3, n_ds, b, e, varcolor_grp ? m : 0, custom_colors)	# Assign default colors
		end
	end

	i1,i2,i3,i4 = (isVert) ? (1,2,5,12) : (5,12,3,4)
	(first && (is_in_dict(d, [:R :region :limits]) === nothing)) &&
		(d[:R] = round_wesn([D3[1].ds_bbox[i1], D3[1].ds_bbox[i2], D3[1].ds_bbox[i3], D3[1].ds_bbox[i4]], false, [0.1,0.1]))

	if (showOL)
		mk, ms, mc = parse_candle_outliers_par(OLcmd)
		d[:scatter] = (data=Dol, marker=mk, ms=ms, mc=mc)		# Still, 'Dol' may be a vec of empties
	end
	if (first)			# Need tis check to not duplicate ticks when called from violin
		xt = ((val = find_in_dict(d, [:xticks :yticks])[1]) !== nothing) ? val :
		      (isodd(n_in_grp) ? num4ticks(D3[ceil(Int,n_in_grp/2)][:, isVert ? 1 : 2]) :
			                     num4ticks(round.((D3[1][:,isVert ? 1 : 2]+D3[end][:,isVert ? 1 : 2])./2, digits=1)))
		(isVert) ? (d[:xticks] = xt) : (d[:yticks] = xt)		# Vertical or Horizontal sticks
	end
	common_plot_xyz("", D3, "boxplot", first, false, d...)
end

boxplot(data::GMTdataset, x=nothing; first::Bool=true, kwargs...) = boxplot(data.data, x; first=first, kwargs...)
boxplot!(data::Vector{<:Real},  x=nothing; kwargs...) = boxplot(data, x; first=false, kwargs...)
boxplot!(data::Matrix{<:Real},  x::Vector{<:Real}=Vector{Real}(); kwargs...) = boxplot(data, x; first=false, kwargs...)
boxplot!(data::Array{<:Real,3}, x::Vector{<:Real}=Vector{Real}(); kwargs...) = boxplot(data, x; first=false, kwargs...)

# ----------------------------------------------------------------------------------------------------------
parse_candle_outliers_par(OLcmd) = "a", "5p", "black"	
function parse_candle_outliers_par(OLcmd::NamedTuple)
	# OLcmd=(marker=??, size=??, color=??) that defaults to: "a" (star); "5p", "black"
	d = nt2dict(OLcmd)
	marker = (haskey(d, :marker)) ? get_marker_name(d, nothing, [:marker], false, false)[1] : "a"
	sz = string(get(d, :size, "5p"))
	color = string(get(d, :color, "black"))
	marker, sz, color
end

# ----------------------------------------------------------------------------------------------------------
function helper1_boxplot(kwargs)
	d = KW(kwargs)
	str = "Y"
	str = (find_in_dict(d, [:horizontal :hbar])[1] !== nothing) ? "X" : "Y"
	isVert = (str == "Y")
	(isVert && (val = find_in_dict(d, [:hor])[1] == true)) && (isVert=false; str="X")	# A private violins opt
	(find_in_dict(d, [:notch])[1] !== nothing) && (str *= "+n")
	if ((val = (find_in_dict(d, [:boxwidth :cap])[1]) !== nothing))
		str *= string("+w",val)
		(GMTver >= v"6.5" && !contains(str,"/") && find_in_dict(d, [:byviolin])[1] !== nothing) && (str *= "/0")
	end
	(GMTver >= v"6.5" && find_in_dict(d, [:byviolin])[1] !== nothing) && (str *= "+w7p/0")
	((opt_W::String = add_opt_pen(d, [:W :pen], "")) != "") && (str *= "+p"*opt_W)	# GMT BUG. Plain -W is ignored
	d[:E] = str
	return d, isVert
end

# ----------------------------------------------------------------------------------------------------------
function helper2_boxplot(data::AbstractMatrix{<:Real}, x::Vector{<:Real}=Vector{Real}(), w::VMr=Vector{Float64}(),
                         off_in_grp::Float64=0.0, cor="", outliers::Bool=false, isVert::Bool=true)
	# OFF_IN_GRP is the offset relative to group's center (zero when groups have only one bar)
	# Returns a Tuple(GMTdataset, GMTdataset)
	_x = isempty(x) ? collect(1.0:size(data,2)) : x
	mat = zeros(size(data,2), 7)
	matOL = Matrix{Float64}[]		# To store the eventual outliers
	first = true
	mi, ma = 1e100, -1e100
	for k = 1:size(data,2)			# Loop over number of groups (or number of candle sticks if each group has only 1)
		t = view(data,:,k)
		q0, q25, q50, q75, q100 = _quantile(t, w, [0.0, 0.25, 0.5, 0.75, 1.0])
		if (outliers)
			mi, ma = min(mi, q0), max(ma, q100)		# For keeping a global min/max that includes the outliers too
			ind_l = t .< (q25 - 1.5*(q75-q25))
			ind_h = t .> (q75 + 1.5*(q75-q25))
			ind = ind_l .|| ind_h
			if (any(ind))
				q0, q25, q50, q75, q100 = _quantile(t[.!ind], w, [0.0, 0.25, 0.5, 0.75, 1.0])
				t_ol = t[ind]
				ot = isVert ? [fill(_x[k]+off_in_grp, length(t_ol)) t_ol] : [t_ol fill(_x[k]+off_in_grp, length(t_ol))]
				matOL = (first) ? ot : [matOL; ot]
				first = false
			end
		end
		mat[k, :] = (isVert) ? [_x[k]+off_in_grp q50 q0 q25 q75 q100 length(t)] :
		                       [q50 _x[k]+off_in_grp q0 q25 q75 q100 length(t)]	# Add n_pts even if that's not used (no notch)
	end
	D = mat2ds(mat, color=cor)
	Dol = !isempty(matOL) ? mat2ds(matOL) : GMTdataset()
	(outliers) && (D.ds_bbox[5] = mi; D.ds_bbox[12] = ma)	# With the outliers limits too
	return D, Dol
end

# ----------------------------------------------------------------------------------------------------------
# Create a x|y|ztics tuple argument by converting the numbers to strings while dropping unnecessary decimals
num4ticks(v::Vector{<:Real}) = (v, [@sprintf("%g ", x) for x in v])

"""
"""
# ----------------------------------------------------------------------------------------------------------
function violin(data::Vector{<:Real}, x_=nothing; x=nothing, nbins::Integer=100, bins::Vector{<:Real}=Vector{Real}(),
                bandwidth=nothing, kernel::StrSymb="normal", first::Bool=true, kwargs...)

	(x === nothing) && (x = x_)			# To allow both ways (positional & kword)
	violin(reshape(data,length(data),1), (x === nothing) ? Vector{Real}() : [x]; x=(x === nothing) ? Vector{Real}() : [x],
                   nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel, first=first, kwargs...)
end

# ----------------------------------------------------------------------------------------------------------
function violin(data::Matrix{<:Real}, x_::Vector{<:Real}=Vector{Real}(); x::Vector{<:Real}=Vector{Real}(),
                nbins::Integer=100, first::Bool=true, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, kernel::StrSymb="normal", groupwidth=0.75, kwargs...)

	isempty(x) && (x = x_)			# To allow both ways (positional & kword)
	(!isempty(x) && length(x) != size(data,2)) && error("Coordinate vector 'x' must have same size as columns in 'data'")
	scatter = (find_in_kwargs(kwargs, [:scatter])[1] !== nothing)
	isVert  = (find_in_kwargs(kwargs, [:horizontal :hbar])[1] === nothing) ? true : false	# Can't delete here
	Dv, Ds, xc = helper_violin(data, x; groupwidth=groupwidth, nbins=nbins, bins=bins, bandwidth=bandwidth,
                               kernel=kernel, scatter=scatter, isVert=isVert)
	helper2_violin(Dv, Ds, data, x, xc, 1, false, first, isVert, kwargs)
end

# ------------ For groups ----------------------------------------------------------------------------------
#groupwidth  - Proportion of the x-axis interval across which each x-group of boxes should be spread.
#varcolor_grp = true		# If colors varie for each in a group, or are constant inside each group.
function violin(data::Array{<:Real,3}, x_::Vector{<:Real}=Vector{Real}(); x::Vector{<:Real}=Vector{Real}(),
                nbins::Integer=100, first::Bool=true, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, kernel::StrSymb="normal", groupwidth=0.75, varcolor_grp=true, kwargs...)

	isempty(x) && (x = x_)			# To allow both ways (positional & kword)
	(!isempty(x) && length(x) != size(data,2)) && error("Coordinate vector 'x' must have same size as columns in 'data'")
	D3::Vector{GMTdataset} = Vector{GMTdataset}(undef, size(data,2)*size(data,3))
	scatter = (find_in_kwargs(kwargs, [:scatter])[1] !== nothing)
	Ds::Vector{GMTdataset} = (scatter) ? Vector{GMTdataset}(undef, length(D3)) : Vector{GMTdataset}()
	split = (find_in_kwargs(kwargs, [:split])[1] !== nothing)
	(split && size(data,3) != 2) && (split=false; @warn("The split method requires groups of two violins only. Ignoring."))
	isVert = (find_in_kwargs(kwargs, [:horizontal :hbar])[1] === nothing) ? true : false

	n, m, n_in_grp = 0, 0, size(data,3)
	boxspacing = groupwidth / n_in_grp
	offs = (0:n_in_grp-1) .- ((n_in_grp-1)/2);			# Isto se cada grupo ocupar uma unidade
	xc = Float64[]				# Because of the stupid locality of vars inside the for block
	for nig = 1:n_in_grp								# Loop over each element in the group
		_split = (split) ? nig : 0
		Dv, _D, xc = helper_violin(view(data,:,:,nig), x, offs[nig]*boxspacing, n_in_grp; groupwidth=groupwidth,
		                           nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel, scatter=scatter, split=_split, isVert=isVert)
		for k = 1:size(data,2)  D3[n+=1] = Dv[k]  end	# Loop over number of groups
		(scatter) && for k = 1:size(data,2)  Ds[m+=1] = _D[k]  end		# Store the scatter pts
	end
	helper2_violin(D3, Ds, data, x, xc, n_in_grp, varcolor_grp, first, isVert, kwargs)	# House keeping and call the plot funs
end

# ----------------------------------------------------------------------------------------------------------
# Create D's with the violin shapes and optionally fill a second D with the scatter points.
function helper_violin(data::AbstractMatrix{<:Real}, x::Vector{<:Real}=Vector{Real}(), off_in_grp::Float64=0.0,
                       n_in_grp::Int=1; groupwidth::Float64=0.75, nbins::Integer=100, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, kernel::StrSymb="normal", scatter::Bool=false, split::Int=0, isVert::Bool=true)
	# OFF_IN_GRP is the offset relative to group's center (zero when groups have only one violin)
	# SPLIT is either 0 (no split); 1 store only lefy half; 2 store right half
	_x = isempty(x) ? collect(1.0:size(data,2)) : Float64.(x)
	Dv = kernelDensity(data; nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel)
	Ds = (scatter) ? Vector{GMTdataset}(undef, length(Dv)) : Vector{GMTdataset}()
	for k = 1:numel(Dv)
		xd, d = view(Dv[k].data,:,1), view(Dv[k].data,:,2)
		d = 1/2n_in_grp * 0.75 * groupwidth .* d ./ maximum(d)
		if (split == 0)					# Both sides
			_data = (isVert) ? [[d; -d[end:-1:1]; d[1]] .+ (_x[k] + off_in_grp) [xd; xd[end:-1:1]; xd[1]]] :
			                   [[xd; xd[end:-1:1]; xd[1]] [d; -d[end:-1:1]; d[1]] .+ (_x[k] + off_in_grp)]
		elseif (split == 1)				# Left half
			_data = (isVert) ? [[0.; -d[end:-1:1]; 0.; 0.] .+ _x[k] [xd[end]; xd[end:-1:1]; xd[1]; xd[end]]] :
			                   [[xd[end]; xd[end:-1:1]; xd[1]; xd[end]] [0.; -d[end:-1:1]; 0.; 0.] .+ _x[k]]
		else							# Right half
			_data = (isVert) ? [[d; 0.0; 0.0; d[1]] .+ _x[k] [xd; xd[end]; xd[1]; xd[1]]] :
			                   [[xd; xd[end]; xd[1]; xd[1]] [d; 0.0; 0.0; d[1]] .+ _x[k]]
		end
		Dv[k].data = _data				# Reuse the struct

		if (scatter)
			maxDisplacement = sample1d([collect(xd) d], range=data[:,k]).data	# Interpolate them on the 'edge'
			n = size(data,1)
			randOffset = (split == 0) ? 2*rand(n) .- 1 : (split == 1) ? -rand(n) : rand(n)
			(split != 0) && (off_in_grp = 0.0)
			Ds[k] = (isVert) ? mat2ds([randOffset .* maxDisplacement[:,2] .+ (_x[k] + off_in_grp) maxDisplacement[:,1]]) :
			                   mat2ds([maxDisplacement[:,1] randOffset .* maxDisplacement[:,2] .+ (_x[k] + off_in_grp)])
		end
	end
	set_dsBB!(Dv)				# Compute and set the global BoundingBox
	return Dv, Ds, _x
end

# ----------------------------------------------------------------------------------------------------------
function helper2_violin(D, Ds, data, x, xc, n_in_grp, var_in_grp, first, isVert, kwargs)
	# This piece of code is common to viloin(Matrix2D) and violin(Matrix3D)
	# Ds is a GMTdataset with the scatter points or an empty one if no scatters.
	# XC vector with the center positions (group centers in case of groups.)
	# var_in_grp = true		# If colors varie for each in a group, or are constant inside each group.

	d = KW(kwargs)
	fill_box = ((val = find_in_kwargs(kwargs, [:G :fill :fillcolor])[1]) !== nothing) ? "gray70" : ""
	if (fill_box != "")		# In this case we may also have received a color list. Check it
		custom_colors = helper_ds_fill(d)		# A helper function of mat2ds()
		n_ds = Int(length(D) / n_in_grp)
		for m = 1:n_in_grp
			b = (m - 1) * n_ds + 1;		e = b + n_ds - 1
			colorize_candles_violins(D, n_ds, b, e, var_in_grp ? m : 0, custom_colors)
		end
	end

	find_in_dict(d, [:horizontal :hbar])		# Just delete if it's still in 'd'
	xt = ((val = find_in_dict(d, [:xticks :yticks])[1]) !== nothing) ? val : num4ticks(xc)
	(isVert) ? (d[:xticks] = xt) : (d[:yticks] = xt)				# Vertical or Horizontal violins
	showOL = (find_in_dict(d, [:outliers])[1] !== nothing)

	haskey(d, :split) && delete!(d, :split)		# Could not have been deleted before

	if (find_in_kwargs(kwargs, [:boxplot])[1] !== nothing || showOL)	# Request to plot the candle sticks too
		delete!(d, :boxplot)
		haskey(d, :scatter) && delete!(d, :scatter)
		do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)
		opt_t = parse_t(d, "", false)[1]		# Seek for transparency opt
		(opt_t != "") && (opt_t = opt_t[4:end])

		common_plot_xyz("", D, "violin", first, false, d...)			# The violins
		del_from_dict(d, [[:xticks], [:yticks], [:G, :fill]])			# To no plot them again
		hz  = !isVert ? true : false			# For the case horizontal violins want candle sticks too
		otl =  showOL ? true : false			# For the case violins want outliers too
		if (isempty(Ds))						# Just the candle sticks
			boxplot(data, x; first=false, G=fill_box, t=opt_t, hor=hz, otl=otl, byviolin=true, show=do_show)
		else									# The candles + the scatter
			boxplot(data, x; first=false, G=fill_box, t=opt_t, hor=hz, otl=otl, byviolin=true)
			d[:show], d[:G], d[:marker] = do_show, "black", "point"
			common_plot_xyz("", Ds, "scatter", false, false, d...)		# The scatter plot
		end
	else
		!isempty(Ds) && (do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)) 
		common_plot_xyz("", D, "violin", first, false, d...)			# The violins
		if (!isempty(Ds))
			del_from_dict(d, [[:xticks], [:yticks], [:G, :fill]])
			d[:show], d[:G], d[:marker] = do_show, "black", "point"
			common_plot_xyz("", Ds, "scatter", false, false, d...)		# The scatter pts
		end
	end
end

# ----------------------------------------------------------------------------------------------------------
function colorize_candles_violins(D::Vector{<:GMTdataset}, ng::Int, b::Int, e::Int, vc::Int=0, colors::Vector{String}=String[])
	# Assign default colors in D.header field to get an automatic coloring
	# NG: number of groups that may, or not, be equal to length(D)
	# VC: = 0 means all in each group have the same color, otherwise they varie within the group

	kk = 0
	if (!isempty(colors))		# If we have a set of pre-deffined colors
		nc = length(colors)
		for k = b:e  kk+=1; D[k].header *= " -G" * (vc > 0 ? colors[((vc % nc) != 0) ? vc % nc : nc] :
			                                                 colors[((kk % nc) != 0) ? kk % nc : nc])
		end
		return D
	end

	if (ng <= 8)
		for k = b:e  D[k].header *= " -G" * (vc > 0 ? matlab_cycle_colors[vc] : matlab_cycle_colors[kk+=1])  end
	elseif (ng <= 20)
		for k = b:e  D[k].header *= " -G" * (vc > 0 ? simple_distinct[vc] : simple_distinct[kk+=1])  end
	else	# Use the alphabet_colors and cycle arround if needed (except in the vc (VariableColor per group case))
		for k = b:e  kk+=1; D[k].header *= " -G" * (vc > 0 ? alphabet_colors[vc] :
		                                                     alphabet_colors[((kk % 26) != 0) ? kk % 26 : 26])  end
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
	for i in 1:numel(p)
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
