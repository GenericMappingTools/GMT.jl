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

	any(isnan.(x)) && (x = x[.!isnan.(x)])
	#any(isnan.(x)) && (x = skipnan(x))		# x errors in default_bandwidth because it has no length()
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

function kernelDensity(mat::Vector{Vector{T}}; nbins::Integer=200, bins::Vector{<:Real}=Vector{Real}(),
                       bandwidth=nothing, kernel::StrSymb="normal") where T
	# Differs from mat::AbstractMatrix in that inner vectors can have different size but matrices not (all cols same size)
	D::Vector{GMTdataset} = Vector{GMTdataset}(undef, numel(mat))
	for k = 1:numel(mat)
		D[k] = kernelDensity(mat[k]; nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel)
	end
	return D
end

function kernelDensity(mat::Vector{Vector{Vector{T}}}; nbins::Integer=200, bins::Vector{<:Real}=Vector{Real}(),
                       bandwidth=nothing, kernel::StrSymb="normal") where T
	# First index is number of groups, second the number of violins/candles in each group. Third the number of points in each.
	D::Vector{GMTdataset} = Vector{GMTdataset}(undef, sum(length.(mat[:])))
	k, kk = 0, 0
	for ng = 1:length(mat)
		for n = 1:length(mat[kk+=1])
			D[k+=1] = kernelDensity(mat[ng][n]; nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel)
		end
	end
	return D
end

# Silverman's rule of thumb for KDE bandwidth selection from KernelDensity.jl
function default_bandwidth(data, alpha::Float64 = 0.9)::Float64
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
boxplot(data::GMTdataset; pos::Vector{<:Real}=Vector{Real}(), first::Bool=true, kwargs...) =
	boxplot(data.data; pos=pos, first=first, kwargs...)

# ----------------------------------------------------------------------------------------------------------
function boxplot(data::Vector{<:Real}, grp::AbstractVector=AbstractVector[]; pos::Vector{<:Real}=Vector{Real}(),
                 first::Bool=true, kwargs...)

	isempty(grp) && return boxplot(reshape(data,length(data),1); pos=pos, first=first, kwargs...)
	mat, g = agrupa_from_vec(data, grp)
	boxplot(mat; pos=pos, first=first, xticks=g, kwargs...)
end

# ----------------------------------------------------------------------------------------------------------
function boxplot(data::Union{Vector{Vector{T}}, AbstractMatrix{T}}; pos::Vector{<:Real}=Vector{Real}(),
                 first::Bool=true, kwargs...) where T
	(!isempty(pos) && length(pos) != size(data,2)) && error("Coordinate vector 'pos' must have same size as columns in 'data'")
	d, isVert, _fill, showOL, OLcmd, w = helper1_boxplot(kwargs)
	D, Dol = helper2_boxplot(data, pos, w, 0.0, _fill, showOL, isVert)	# Two GMTdataset's. Second may be empty
	Dv = (_fill == "gray70") ? ds2ds(D, G="gray70") : ds2ds(D)			# Split it so we can assign colors to each candle.
	if (_fill != "" && _fill != "gray70")								# Only paint the candles if explicitly requested.
		custom_colors = helper_ds_fill(d)	# A helper function of mat2ds()
		colorize_candles_violins(Dv, length(Dv), 1:1, 0, custom_colors)	# Assign default colors in Dv's headers
	end

	helper3_boxplot(d, D, Dol, first, isVert, showOL, OLcmd, num4ticks(D[:, isVert ? 1 : 2]))
end

# ------------ For groups ----------------------------------------------------------------------------------
function boxplot(data::Array{T,3}; pos::Vector{<:Real}=Vector{Real}(), first::Bool=true,
                 groupwidth=0.75, ccolor=false, kwargs...) where T

	(!isempty(pos) && length(pos) != size(data,2)) && error("Coordinate vector 'pos' must have same size as columns in 'data'")
	d, isVert, _fill, showOL, OLcmd, w = helper1_boxplot(kwargs)

	N_grp = size(data,3)							# N elements in group
	boxspacing = groupwidth / N_grp
	offs = (0:N_grp-1) .- ((N_grp-1)/2);			# Isto se cada grupo ocupar uma unidade
	D3 = Vector{GMTdataset}(undef, N_grp)			# As many as the number of elements in a group
	Dol::Vector{GMTdataset} = Vector{GMTdataset}(undef, N_grp)
	mi, ma = 1e100, -1e100
	for nig = 1:N_grp								# Loop over each element in the group
		D3[nig], Dol[nig] = helper2_boxplot(view(data,:,:,nig), pos, w, offs[nig]*boxspacing, _fill, showOL, isVert)
		mi, ma = min(mi, D3[nig].ds_bbox[5]), max(ma, D3[nig].ds_bbox[12])
	end
	set_dsBB!(D3)				# Compute and set the global BoundingBox
	D3[1].ds_bbox[5], D3[1].ds_bbox[12] = mi, ma	# Global min/max that includes the outliers

	# Need to compute this now because D3 may be 'remixed'
	n4t = (isodd(N_grp) ? num4ticks(D3[ceil(Int,N_grp/2)][:, isVert ? 1 : 2]) :
			              num4ticks(round.((D3[1][:,isVert ? 1 : 2]+D3[end][:,isVert ? 1 : 2])./2, digits=1)))

	if (_fill != "")
		custom_colors = (_fill == "gray70") ? ["gray70"] : String[]
		ccolor && (D3 = ds2ds(ds2ds(D3)); set_dsBB!(D3))		# Crazzy op and wasteful but these Ds are small
		n_ds = Int(length(D3) / N_grp)
		for m = 1:N_grp
			b = (m - 1) * n_ds + 1;		e = b + n_ds - 1
			colorize_candles_violins(D3, n_ds, b:e, !ccolor ? m : 0, custom_colors)	# Assign default colors
		end
	end

	helper3_boxplot(d, D3, Dol, first, isVert, showOL, OLcmd, n4t)
end

# ----------------------------------------------------------------------------------------------------------
function boxplot(data::Vector{Vector{Vector{T}}}; pos::Vector{<:Real}=Vector{Real}(), first::Bool=true,
                 groupwidth=0.75, ccolor=false, kwargs...) where T

	(!isempty(pos) && length(pos) != size(data,2)) && error("Coordinate vector 'pos' must have same size as columns in 'data'")
	d, isVert, _fill, showOL, OLcmd, w = helper1_boxplot(kwargs)

	N_in_each_grp = length.(data[:])					# Vec with the N elements in each group
	N_grp = length(N_in_each_grp)
	D3_ = Vector{GMTdataset}(undef, N_grp)				# As many as number of groups
	Dol = Vector{GMTdataset}(undef, N_grp)
	_pos = !isempty(pos) ? pos : collect(1.0:N_grp)
	mi, ma = 1e100, -1e100
	for ng = 1:N_grp									# Loop over number of groups
		N_in_this_grp = N_in_each_grp[ng]
		boxspacing = groupwidth / N_in_this_grp
		offs = (0:N_in_this_grp-1) .- ((N_in_this_grp-1)/2);
		_x = fill(_pos[ng], N_in_this_grp) .+ offs*boxspacing	# This case stores the candles by groups.
		D3_[ng], Dol[ng] = helper2_boxplot(data[ng], _x, w, 0.0, _fill, showOL, isVert)
		mi, ma = min(mi, D3_[ng].ds_bbox[5]), max(ma, D3_[ng].ds_bbox[12])
	end

	set_dsBB!(D3_)		# Set global BoundingBox
	D3_[1].ds_bbox[5], D3_[1].ds_bbox[12] = mi, ma		# Global min/max that includes the outliers

	# Need to compute this now because D3_ may be 'remixed'
	n4t = num4ticks(round.([mean(D3_[k][:, isVert ? 1 : 2]) for k = 1:numel(D3_)], digits=1))

	if (_fill != "")
		custom_colors = (_fill == "gray70") ? ["gray70"] : String[]
		D3_ = colorize_VecVecVec(D3_, N_grp, N_in_each_grp, !ccolor, custom_colors, "box")
	end

	helper3_boxplot(d, D3_, Dol, first, isVert, showOL, OLcmd, n4t)
end

# ----------------------------------------------------------------------------------------------------------
function helper3_boxplot(d, D, Dol, first, isVert, showOL, OLcmd, n4t)
	i1,i2,i3,i4 = (isVert) ? (1,2,5,12) : (5,12,3,4)
	(first && (is_in_dict(d, [:R :region :limits]) === nothing)) &&
		(d[:R] = isa(D, Vector) ? 
		         round_wesn([D[1].ds_bbox[i1], D[1].ds_bbox[i2], D[1].ds_bbox[i3], D[1].ds_bbox[i4]], false, [0.1,0.1]) :
		         round_wesn([D.ds_bbox[i1], D.ds_bbox[i2], D.ds_bbox[i3], D.ds_bbox[i4]], false, [0.1,0.1]))

	if (showOL)
		mk, ms, mc, mec = parse_candle_outliers_par(OLcmd)
		d[:scatter] = (data=Dol, marker=mk, ms=ms, mc=mc)		# Still, 'Dol' may be a vec of empties
	end
	if (first)			# Need this check to not duplicate ticks when called from violin
		xt = ((val = find_in_dict(d, [:xticks :yticks :ticks])[1]) !== nothing) ?  val : n4t
		(isVert) ? (d[:xticks] = xt) : (d[:yticks] = xt)		# Vertical or Horizontal sticks
	end

	plotcandles_and_showsep(d, D, first, isVert, true)	# See also if a group separator was requested
end

# ----------------------------------------------------------------------------------------------------------
boxplot!(data::Vector{<:Real}; pos::Vector{<:Real}=Vector{Real}(), kwargs...) = boxplot(data; pos=pos, first=false, kwargs...)
boxplot!(data::Matrix{<:Real}; pos::Vector{<:Real}=Vector{Real}(), kwargs...) = boxplot(data; pos=pos, first=false, kwargs...)
boxplot!(data::Array{<:Real,3}; pos::Vector{<:Real}=Vector{Real}(), kwargs...) = boxplot(data; pos=pos, first=false, kwargs...)

# ----------------------------------------------------------------------------------------------------------
function plotcandles_and_showsep(d, D, first::Bool, isVert::Bool, allvar::Bool=false)
	# Plot the candle sticks and deal with the request separator for lines between groups.
	# The ALLVAR case = true is when the groups may have different number of elements. D is then by group.
	showSep = ((SEPcmd = find_in_dict(d, [:separator])[1]) !== nothing)
	(showSep) && (sep_pen = parse_stats_separator_pen(d, SEPcmd))
	(showSep) && (do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0))
	common_plot_xyz("", D, "boxplot", first, false, d...)
	if (showSep)
		if (isa(D, Vector))
			#allvar = !all(diff(size.(D[:],1)) .== 0)	# Forgot where allvar was supposed to be set.
			xc = (allvar) ? [mean(D[k][:,1]) for k=1:numel(D)] : (D[1][:,isVert ? 1 : 2]+D[end][:,isVert ? 1 : 2])./2
			xs = xc[1:end-1] .+ diff(xc)/2
		else
			xc = D[:, isVert ? 1 : 2];	xs = xc[1:end-1] .+ diff(xc)/2
		end
		(isVert) ? vlines!(xs, pen=sep_pen, show=do_show) : hlines!(xs, pen=sep_pen, show=do_show)
	end
end

# ----------------------------------------------------------------------------------------------------------
parse_candle_outliers_par(OLcmd) = "a", "5p", "black", "black"
function parse_candle_outliers_par(OLcmd::NamedTuple)::Tuple{String, String, String, String}
	# OLcmd=(marker=??, size=??, color=??) that defaults to: "a" (star); "5p", "black"
	d = nt2dict(OLcmd)
	marker = (haskey(d, :marker)) ? get_marker_name(d, nothing, [:marker], false, false)[1] : "a"
	sz = string(get(d, :size, "5p"))
	color = string(get(d, :color, "black"))
	mec::String = ((val = find_in_dict(d, [:mec :markeredgecolor :MarkerEdgeColor])[1]) !== nothing) ?
	                      "0.5p," * arg2str(val) : "0.5p,black"
	marker, sz, color, mec
end
function parse_stats_separator_pen(d, SEPcmd)
	# Get the pen used in te separators option
	SEPcmd === nothing && return "0.5p"
	d[:sp] = SEPcmd
	add_opt_pen(d, [:sp])
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
	pen = ((optW::String = add_opt_pen(d, [:W :pen :boxpen])) != "") ? optW : "0.5p"	# GMT BUG. Plain -W is ignored
	(haskey(d, :byviolin)) && (delete!(d, :byviolin))	# Only consumed by GMT >= 6.5
	str *= "+p" * pen
	d[:E] = str

	showOL = ((OLcmd = find_in_dict(d, [:outliers])[1]) !== nothing)
	if (!showOL) 
		if ((val = find_in_dict(d, [:otl])[1]) !== nothing && val != false)		# A violin private opt
			showOL = true
			isa(val, NamedTuple) && (OLcmd = val)
		end
	end
	fill = ((val = find_in_dict(d, [:G :fill], false)[1]) !== nothing) ? val : ""	# fill should be made a string always
	w = ((val = find_in_dict(d, [:weights])[1]) !== nothing) ? Float64.(val) : Float64[]
	
	return d, isVert, fill, showOL, OLcmd, w
end

# ----------------------------------------------------------------------------------------------------------
function helper2_boxplot(data::Union{Vector{Vector{T}}, AbstractMatrix{T}}, x::Vector{<:Real}=Vector{Real}(),
                         w::VMr=Vector{Float64}(), off_in_grp::Float64=0.0, cor="", outliers::Bool=false, isVert::Bool=true) where T
	# OFF_IN_GRP is the offset relative to group's center (zero when groups have only one bar)
	# Returns a Tuple(GMTdataset, GMTdataset)
	n_boxs = isa(data, AbstractMatrix) ? size(data,2) : length(data)
	_x = !isempty(x) ? x : collect(1.0:n_boxs)
	mat = zeros(n_boxs, 7)
	matOL = Matrix{Float64}[]	# To store the eventual outliers
	first = true
	mi, ma = 1e100, -1e100
	for k = 1:n_boxs			# Loop over number of groups (or number of candle sticks if each group has only 1)
		t = isa(data, AbstractMatrix) ? view(data,:,k) : data[k]
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
		                       [q50 _x[k]+off_in_grp q0 q25 q75 q100 length(t)]	# Add n_pts even when not used (no notch)
	end
	D = mat2ds(mat, color=cor)
	Dol = !isempty(matOL) ? mat2ds(matOL) : GMTdataset()
	(outliers) && (D.ds_bbox[5] = mi; D.ds_bbox[12] = ma)	# With the outliers limits too
	return D, Dol
end

# ----------------------------------------------------------------------------------------------------------
function agrupa_from_vec(vec::Vector{<:Real}, grp::AbstractVector)
	# Take the vector VEC and break it into chunks as selected by the categorical vector GRP, then group
	# them into a matrix MxN_groups whe M is the size of the longest chunk. Remainings are filled with NaNs
	(length(grp) != length(vec)) && error("Categorical group vector must be of same size as the 'data' vector.")
	g = unique(grp)
	x = [sum(grp .== g[k]) for k = 1:numel(g)]
	mat = [zeros(x[k]) for k = 1:length(g)]
	for k = 1:numel(g)
		ind = findall(grp .== g[k])
		mat[k] = vec[ind]
	end
	mat, g
end

# ----------------------------------------------------------------------------------------------------------
# Create a x|y|ztics tuple argument by converting the numbers to strings while dropping unnecessary decimals
num4ticks(v::AbstractVector{<:Real}) = (v, [@sprintf("%g ", x) for x in v])

"""

Example:
  y = randn(200,4,3);
  violin(y, separator=(:red,:dashed), boxplot=true, outliers=true, fill=true, xticks=["A","B","C","D"], show=1)
"""
# ----------------------------------------------------------------------------------------------------------
function violin(data::Vector{<:Real}, grp::AbstractVector=AbstractVector[]; first::Bool=true,
                pos::Vector{<:Real}=Vector{Real}(), nbins::Integer=100, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, groupwidth=0.75, kernel::StrSymb="normal", kwargs...)

	isempty(grp) && return violin(reshape(data,length(data),1); pos=pos, nbins=nbins, bins=bins,
	                              bandwidth=bandwidth, groupwidth=groupwidth, kernel=kernel, first=first, kwargs...)
	mat, g = agrupa_from_vec(data, grp)
	violin(mat; first=first, pos=pos, nbins=nbins, bins=bins, bandwidth=bandwidth, groupwidth=groupwidth, kernel=kernel,
	       xticks=g, kwargs...)
end

# ----
# violin(randn(100,3), fill=true,  show=1)
# violin([round.(randn(50),digits=1), round.(randn(40),digits=3)], fill=true,  show=1)
function violin(data::Union{Vector{Vector{T}}, AbstractMatrix{T}}; first::Bool=true, pos::Vector{<:Real}=Vector{Real}(),
                nbins::Integer=100, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, groupwidth=0.75, kernel::StrSymb="normal", kwargs...) where T

	(!isempty(pos) && length(pos) != size(data,2)) && error("Coordinate vector 'pos' must have same size as columns in 'data'")
	scatter = (find_in_kwargs(kwargs, [:scatter])[1] !== nothing)
	isVert  = (find_in_kwargs(kwargs, [:horizontal :hbar])[1] === nothing) ? true : false	# Can't delete here
	Dv, Ds, xc = helper1_violin(data, pos; groupwidth=groupwidth, nbins=nbins, bins=bins, bandwidth=bandwidth,
                                kernel=kernel, scatter=scatter, isVert=isVert)
	helper2_violin(Dv, Ds, data, pos, xc, 1, true, first, isVert, Int[], kwargs)
end

# ------------ For groups ----------------------------------------------------------------------------------
#groupwidth  - Proportion of the x-axis interval across which each x-group of boxes should be spread.
#ccolor = false		# If colors varie for each in a group, or are constant inside each group.
function violin(data::Array{<:Real,3}, x::AbstractVector=AbstractVector[]; pos::Vector{<:Real}=Vector{Real}(),
                nbins::Integer=100, first::Bool=true, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, kernel::StrSymb="normal", groupwidth=0.75, ccolor=false, kwargs...)

	(!isempty(pos) && length(pos) != size(data,2)) && error("Coordinate vector 'pos' must have same size as columns in 'data'")
	scatter = (find_in_kwargs(kwargs, [:scatter])[1] !== nothing)
	isVert = (find_in_kwargs(kwargs, [:horizontal :hbar])[1] === nothing) ? true : false
	D3::Vector{GMTdataset} = Vector{GMTdataset}(undef, size(data,2)*size(data,3))
	Ds::Vector{GMTdataset} = (scatter) ? Vector{GMTdataset}(undef, length(D3)) : Vector{GMTdataset}()
	split = (find_in_kwargs(kwargs, [:split])[1] !== nothing)
	(split && size(data,3) != 2) && (split=false; @warn("The split method requires groups of two violins only. Ignoring."))

	n, m, N_grp = 0, 0, size(data,3)
	boxspacing = groupwidth / N_grp
	offs = (0:N_grp-1) .- ((N_grp-1)/2);			# Isto se cada grupo ocupar uma unidade
	xc = Float64[]				# Because of the stupid locality of vars inside the for block
	for nig = 1:N_grp								# Loop over each element in the group
		_split = (split) ? nig : 0
		Dv, _D, xc = helper1_violin(view(data,:,:,nig), pos, offs[nig]*boxspacing, N_grp; groupwidth=groupwidth, nbins=nbins,
		                            bins=bins, bandwidth=bandwidth, kernel=kernel, scatter=scatter, split=_split, isVert=isVert)
		for k = 1:size(data,2)  D3[n+=1] = Dv[k]  end	# Loop over number of groups
		(scatter) && for k = 1:size(data,2)  Ds[m+=1] = _D[k]  end		# Store the scatter pts
	end
	helper2_violin(D3, Ds, data, pos, xc, N_grp, ccolor, first, isVert, Int[], kwargs)	# House keeping and call the plot funs
end

function violin(data::Vector{Vector{Vector{T}}}, x::AbstractVector=AbstractVector[]; pos::Vector{<:Real}=Vector{Real}(),
                nbins::Integer=100, first::Bool=true, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, kernel::StrSymb="normal", groupwidth=0.75, ccolor=false, kwargs...) where T

	(!isempty(pos) && length(pos) != length(data)) && error("Coordinate vector 'pos' must have same size as columns in 'data'")
	scatter = (find_in_kwargs(kwargs, [:scatter])[1] !== nothing)
	isVert  = (find_in_kwargs(kwargs, [:horizontal :hbar])[1] === nothing) ? true : false
	split   = (find_in_kwargs(kwargs, [:split])[1] !== nothing)
	#(split && size(data,3) != 2) && (split=false; @warn("The split method requires groups of two violins only. Ignoring."))

	N_in_each_grp = length.(data[:])					# Vec with the N elements in each group
	N_grp = length(N_in_each_grp)
	D3::Vector{GMTdataset} = Vector{GMTdataset}(undef, sum(N_in_each_grp))		# As many as ...
	Ds::Vector{GMTdataset} = (scatter) ? Vector{GMTdataset}(undef, length(D3)) : Vector{GMTdataset}()
	_pos = !isempty(pos) ? pos : collect(1.0:N_grp)
	n, m = 0, 0
	for nig = 1:N_grp									# Loop over number of groups
		N_in_this_grp = N_in_each_grp[nig]
		boxspacing = groupwidth / N_in_this_grp
		offs = (0:N_in_this_grp-1) .- ((N_in_this_grp-1)/2);
		_x = fill(_pos[nig], N_in_this_grp) .+ offs*boxspacing	# This case stores the candles by groups.

		_split = (length(data[nig]) != 2) ? 0 : (split) ? nig : 0	# Only split if they are two
		(_split != 0) && (_x = fill(mean(_x), length(_x)))		# Pass in the central position

		Dv, _D, = helper1_violin(data[nig], _x, 0., N_in_this_grp; groupwidth=groupwidth, nbins=nbins, bins=bins,
		                         bandwidth=bandwidth, kernel=kernel, scatter=scatter, split=_split, isVert=isVert, swing=true)
		for k = 1:length(data[nig])  D3[n+=1] = Dv[k]  end	# Loop over number of groups
		(scatter) && for k = 1:length(data[nig])  Ds[m+=1] = _D[k]  end		# Store the scatter pts
	end
	helper2_violin(D3, Ds, data, pos, 1:N_grp, N_grp, ccolor, first, isVert, N_in_each_grp, kwargs)
end

# ----------------------------------------------------------------------------------------------------------
# Create D's with the violin shapes and optionally fill a second D with the scatter points.
function helper1_violin(data::Union{Vector{Vector{T}}, AbstractMatrix{T}}, x::Vector{<:Real}=Vector{Real}(),
                        off_in_grp::Float64=0.0, N_grp::Int=1; groupwidth::Float64=0.75, nbins::Integer=100, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, kernel::StrSymb="normal", scatter::Bool=false, split::Int=0, isVert::Bool=true, swing::Bool=true) where T
	# OFF_IN_GRP is the offset relative to group's center (zero when groups have only one violin)
	# SPLIT is either 0 (no split); 1 store only lefy half; 2 store right half
	# For the SPLIT case the SWING option is true when called from VecVecVec and means SPLIT will toggle between 1-2
	
	_x = !isempty(x) ? Float64.(x) : isa(data, AbstractMatrix) ? collect(1.0:size(data,2)) : collect(1.0:length(data))

	Dv = kernelDensity(data; nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel)
	Ds = (scatter) ? Vector{GMTdataset}(undef, length(Dv)) : Vector{GMTdataset}()
	for k = 1:numel(Dv)
		xd, d = view(Dv[k].data,:,1), view(Dv[k].data,:,2)
		d = 1/2N_grp * 0.75 * groupwidth .* d ./ maximum(d)
		(k == 2 && split != 0 && swing) && (split = (split == 1) ? 2 : 1)	# Not realy sure why we have to do this.
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
			# Interpolate them on the 'edge'
			maxDisplacement = isa(data, AbstractMatrix) ? sample1d([collect(xd) d], range=data[:,k]).data :
			                                              sample1d([collect(xd) d], range=data[k]).data
			n = isa(data, AbstractMatrix) ? size(data,1) : length(data[k])
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
function helper2_violin(D, Ds, data, x, xc, N_grp, ccolor, first, isVert, N_in_each_grp, kwargs)
	# This piece of code is common to viloin(Matrix2D) and violin(Matrix3D)
	# Ds is a GMTdataset with the scatter points or an empty one if no scatters.
	# XC vector with the center positions (group centers in case of groups.)
	# ccolor = false		# If colors varie for each in a group, or are constant inside each group.
	# N_in_each_grp is not empty when the caller was the Vector{Vector{Vector}} method

	d = KW(kwargs)
	fill_box = ((val = find_in_kwargs(kwargs, [:G :fill :fillcolor])[1]) !== nothing) ? "gray70" : ""
	if (fill_box != "")		# In this case we may also have received a color list. Check it
		custom_colors = helper_ds_fill(d)		# A helper function of mat2ds()
		if (isempty(N_in_each_grp))
			n_ds = Int(length(D) / N_grp)
			for m = 1:N_grp
				b = (m - 1) * n_ds + 1;		e = b + n_ds - 1
				colorize_candles_violins(D, n_ds, b:e, !ccolor ? m : 0, custom_colors)
			end
		else
			colorize_VecVecVec(D, N_grp, N_in_each_grp, !ccolor, custom_colors, "violin")
		end
	end

	find_in_dict(d, [:horizontal :hbar])		# Just delete if it's still in 'd'
	xt = ((val = find_in_dict(d, [:xticks :yticks :ticks])[1]) !== nothing) ? val : num4ticks(xc)
	(isVert) ? (d[:xticks] = xt) : (d[:yticks] = xt)				# Vertical or Horizontal violins
	showOL  = ((OLcmd  = find_in_dict(d, [:outliers])[1]) !== nothing)
	showSep = ((SEPcmd = find_in_dict(d, [:separator])[1]) !== nothing)
	(showSep) && (sep_pen = parse_stats_separator_pen(d, SEPcmd))

	haskey(d, :split) && delete!(d, :split)		# Could not have been deleted before

	if (find_in_kwargs(kwargs, [:boxplot])[1] !== nothing || showOL)	# Request to plot the candle sticks too
		delete!(d, :boxplot)
		haskey(d, :scatter) && delete!(d, :scatter)
		do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)
		opt_t = parse_t(d, "", false)[1]		# Seek for transparency opt
		(opt_t != "") && (opt_t = opt_t[4:end])

		R = common_plot_xyz("", D, "violin", first, false, d...)		# The violins
		del_from_dict(d, [[:xticks], [:yticks], [:G, :fill]])			# To no plot them again
		hz  = !isVert ? true : false			# For the case horizontal violins want candle sticks too
		(showOL && isempty(Ds) && isa(OLcmd, Bool)) && (OLcmd = (size="4p",))	# No scatter, smaller stars
		otl = (!showOL) ? false : (isa(OLcmd, Bool)) ? true : OLcmd		# For the case violins want outliers too
		this_show = (showSep) ? false : do_show
		if (isempty(Ds))			# Just the candle sticks
			R = boxplot(data; first=false, G=fill_box, t=opt_t, hor=hz, otl=otl, byviolin=true, ccolor=true, show=this_show)
		else						# The candles + the scatter
			boxplot(data; first=false, G=fill_box, t=opt_t, hor=hz, otl=otl, byviolin=true, ccolor=true)
			d[:show], d[:G], d[:marker] = this_show, "black", "point"
			R = common_plot_xyz("", Ds, "scatter", false, false, d...)		# The scatter plot
		end
		(showSep) && (f = (isVert) ? vlines! : hlines!;	R = f(xc[1:end-1] .+ diff(xc)/2, pen=sep_pen, show=do_show))
	else
		(!isempty(Ds) || showSep) && (do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)) 
		R = common_plot_xyz("", D, "violin", first, false, d...)			# The violins
		if (!isempty(Ds))
			del_from_dict(d, [[:xticks], [:yticks], [:G, :fill]])
			d[:G], d[:marker] = "black", "point"
			d[:show] = (showSep) ? false : do_show
			R = common_plot_xyz("", Ds, "scatter", false, false, d...)		# The scatter pts
		end
		(showSep) && (f = (isVert) ? vlines! : hlines!;	R = f(xc[1:end-1] .+ diff(xc)/2, pen=sep_pen, show=do_show))
	end
	R
end

# ----------------------------------------------------------------------------------------------------------
function colorize_candles_violins(D::Vector{<:GMTdataset}, ng::Int, be::AbstractVector{Int}, vc::Int=0, colors::Vector{String}=String[])
	# Assign default colors in D.header field to get an automatic coloring
	# NG: number of groups that may, or not, be equal to length(D)
	# VC: = 0 means all in each group have the same color, otherwise they varie within the group

	kk = 0
	if (!isempty(colors))		# If we have a set of user colors
		nc = length(colors)
		for k in be  kk+=1; D[k].header *= " -G" * (vc > 0 ? colors[((vc % nc) != 0) ? vc % nc : nc] :
			                                                 colors[((kk % nc) != 0) ? kk % nc : nc])
		end
		return D
	end

	if (ng <= 8)
		for k in be  D[k].header *= " -G" * (vc > 0 ? matlab_cycle_colors[vc] : matlab_cycle_colors[kk+=1])  end
	else	# Use the simple_distinct and cycle arround if needed (except in the vc (VariableColor per group case))
		for k in be  kk+=1; D[k].header *= " -G" * (vc > 0 ? simple_distinct[vc] :
		                                                     simple_distinct[((kk % 20) != 0) ? kk % 20 : 20])  end
	end
	return D
end

# ----------------------------------------------------------------------------------------------------------
function colorize_VecVecVec(D, N_grp, N_in_each_grp, varcolor_in_grp, custom_colors, type="box")
	if (varcolor_in_grp)		# This was a diabolic case
		# Ex: [[[11],[12]], [[21],[22],[23]], [[31],[32]]] ==> [[1,3,6], [2,4,7], [5]]
		vv = [[1] for _ = 1:N_grp]						# Initialize a Vec{Vec{}} with [[1], [1], [1], ...]
		vv[1] = cumsum([1, N_in_each_grp[1:end-1]...])	# Fill the first vector from info that we already know.

		mask = zeros(Bool, maximum(N_in_each_grp), length(N_in_each_grp))
		for k = 1:size(mask,2)
			mask[1:N_in_each_grp[k],k] .= true
		end
		for n = 2:maximum(N_in_each_grp)		# Loop over GROUPS
			ind = findall(mask[n,:])
			vv[n] = vv[n-1][ind] .+ 1
		end
		if (type == "box")						# For use only by boxplots
			D = ds2ds(ds2ds(D)); set_dsBB!(D)	# Crazzy op and wasteful but thse Ds are small
		end
		for m = 1:N_grp
			colorize_candles_violins(D, N_grp, vv[m], varcolor_in_grp ? m : 0, custom_colors)	# Assign default colors
		end
	else
		colorize_candles_violins(D, N_grp, 1:N_grp, varcolor_in_grp ? m : 0, custom_colors)
	end
	return D
end

# ----------------------------------------------------------------------------------------------------------
function _quantile(v::AbstractVector{T}, w::AbstractVector{<:Real}, p::AbstractVector{<:Real}) where T
	any(isnan.(v)) && (v = skipnan(v))
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
