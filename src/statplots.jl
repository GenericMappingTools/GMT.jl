"""
    D = density(x::Vector{<:Real}; nbins::Integer=200, bins::Vector{<:Real}=Vector{Real}(),
                bandwidth=nothing, kernel::StrSymb="normal")

- `x`: calculate the kernel density 'd' of a dataset X for query points 'xd' The density, by default, is
    estimated using a gaussian kernel with a width obtained with the Silverman's rule. `x` may be
    a vector, a matrix or Vector{Vector{Real}}.
- `nbins`: points are queried between MIN(Y[:]) and MAX(Y[:]) where Y is the data vector.
- `bins`: Calculates the density for the query points specified by BINS. The values are used as the
    query points directly. Default is 200 points.
- `bandwidth`: uses the 'bandwidth' to calculate the kernel density. It must be a scalar.
    For the uniform case the bandwidth is set to 15% of the range, otherwise the bandwidth is chosen
    with the Silverman's rule.
- `printbw`: Logical value indicating to print the computed value of the `bandwidth`.
- `kernel`: Uses the kernel function specified by KERNEL name (a string or a symbol) to calculate the density.
    The kernel may be: 'Normal' (default) or 'Uniform'
- `extend`: By default the density curve is computed at the `bins` locatins or between data extrema as
    mentioned above. However, this is not normally enough to go down to zero. Use this option in terms of
    number of bandwidth to expand de curve. *e.g.* `extend=2`
"""
function density(x; first::Bool=true, nbins::Integer=200, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing,
                 kernel::StrSymb="normal", printbw::Bool=false, horizontal::Bool=false, extend=0, kwargs...)
	D = kernelDensity(x, horizontal; nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel, printbw=printbw, ext=extend)
	common_plot_xyz("", D, "line", first, false, kwargs...)
end
density!(x; nbins::Integer=200, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, kernel::StrSymb="normal", printbw::Bool=false, horizontal::Bool=false, extend=0, kw...) = density(x; first=false, nbins=nbins, bins=bins, bandwidth=bandwidth, kernel=kernel, printbw=printbw, horizontal=horizontal, extend=extend, kw...)

# ----------------------------------------------------------------------------------------------------------
# Adapted from the Matlab FEX contribution 60772 by Christopher Hummersone, Licensed under MIT
function kernelDensity(x::AbstractVector{<:Real}, hz=false; nbins::Integer=200, bins::Vector{<:Real}=Vector{Real}(),
                       bandwidth=nothing, kernel::StrSymb="normal", printbw::Bool=false, ext=0)

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
	printbw && println(@sprintf("\t Bandwidth = %g", h))

	xd::Vector{<:Float64} = !isempty(bins) ? sort(bins) : collect(linspace(minimum(x)-ext*h, maximum(x)+ext*h, nbins))
	d = zeros(size(xd))
	c1::Float64 = numel(x)*h
	@inbounds for i = 1:numel(xd)
		d[i] = sum(f((x .- xd[i])/h)) / c1
	end
	any(isnan.(d)) && (d[isnan.(d)] .= 0.0)
	return (hz) ? mat2ds([d xd]) : mat2ds([xd d])
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
Normal(x::AbstractVector{<:Real}) = 1/(sqrt(2*pi)) * exp.(-0.5*(x .^2))::Vector{Float64}
Normal(x::AbstractVector{<:Real}, μ::Float64) = 1/(sqrt(2*pi)) * exp.(-0.5*((x .- μ) .^2))::Vector{Float64}
Normal(x::AbstractVector{<:Real}, μ::Float64, σ::Float64)::Vector{Float64} = 1/(σ *sqrt(2*pi)) * exp.(-0.5*(((x .- μ)/σ) .^2))

"""
```julia
Uniform(x::Vector{<:Real}, a=-1.0, b=1.0)    # Uniform distribution over [a, b]
```
"""
function Uniform(x::AbstractVector{<:Real}, a=-1.0, b=1.0)
	(a == -1 && b == 1) && return 0.5 * (abs.(x) .<= 1)
	r = zeros(length(x))
	r[a .<= x .<= b] .= 1 / (b - a)
	return r
end

"""
    boxplot(data, grp=[]; pos=nothing, kwargs...)

- `data`: A vector (plots a single box), a Matrix (plots n columns boxes), a MxNxG (plots `G` groups)
          of `N` columns boxes, a Vector{Vector} (plots n clumn boxes but from data of different sizes),
          a Vector{Vector{Vector}} (plots G groups - length(data) -, where groups may have variable number
          of elements and each have its own size.)
- `grp`: Categorical vector (made of integers or text strings) used to break down a the data column vector
         in cathegories (groups).
- `pos`: a coordinate vector (or a single location when `data` is a vector) where to plot the boxes.
          Default plots them at 1:n_boxes or 1:n_groups.
- `ccolor`: Logical value indicating whether the groups have constant color (when `fill=true` is used)
           or have variable color (the default).
- `fill`: If fill=true paint the boxes with a pre-defined color scheme. Otherwise, give a list of colors
          to paint the boxes.
- `fillalpha` : When `fill` option is used, we can set the transparency of filled boxes with this
          option that takes in an array (vec or 1-row matrix) with numeric values between [0-1] or ]1-100],
	      where 100 (or 1) means full transparency.
- `boxwidth` or `cap`: Sets the the boxplot width and, optionally, the cap width. Provide info as
          `boxwidth="10p/3p"` to set the boxwidth different from the cap's. Note, however, that this
           requires GMT6.5. Previous versions do not destinguish box and cap widths.
- `groupWidth`: Specify the proportion of the x-axis interval across which each x-group of boxes should
           be spread. The default is 0.75.
- `notch`: Logical value indicating whether the box should have a notch.
- `outliers`: If other than a NamedTuple, plots outliers (1.5IQR) with the default black 5pt stars.
              If argument is a NamedTuple (marker=??, size=??, color=??, markeredge=??), where `marker`
              is one of the `plots` marker symbols, plots the outliers with those specifications. Any missing
              spec default to the above values. i.e `outliers=(size="3p")` plots black 3 pt stars.
- `horizontal` or `hbar`: plot horizontal instead of vertical boxplots.
- `weights`: Array giving the weights for the data in `data`. The array must be the same size as `data`.
- `region` or `limits`: By default we estimate the plotting limits but sometimes that may not be convenient.
           Give a region=(x_min,x_max,y_min,y_max) tuple if you want to control the plotting limits.
- `separator`: If = true plot a black line separating the groups. Otherwise provide the pen settings of those lines.
- `ticks` or `xticks` or `yticks`: A tuple with annotations interval and labels. E.g. xticks=(1:5, ["a", "b", "c", "d"])
           where first element is an AbstractArray and second an array or tuple of strings or symbols.

"""
boxplot(data::GMTdataset; pos::Vector{<:Real}=Vector{Real}(), first::Bool=true, kwargs...) =
	boxplot(data.data; pos=pos, first=first, kwargs...)

# ----------------------------------------------------------------------------------------------------------
function boxplot(data::AbstractVector{<:Real}, grp::AbstractVector=AbstractVector[]; pos::Vector{<:Real}=Vector{Real}(),
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
	c = false
	if (_fill != "" && _fill != "gray70")								# Only paint the candles if explicitly requested.
		set_dsBB!(Dv)
		custom_colors = helper_ds_fill(d, nc=length(Dv))	# A helper function of mat2ds()
		colorize_candles_violins(Dv, length(Dv), 1:length(Dv), 0, custom_colors)	# Assign default colors in Dv's headers
		c = true
	end

	helper3_boxplot(d, c ? Dv : D, Dol, first, isVert, showOL, OLcmd, num4ticks(D[:, isVert ? 1 : 2]), false, isa(data, Vector))
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
	mi, ma, nol = 1e100, -1e100, 0
	for nig = 1:N_grp								# Loop over each element in the group
		D3[nig], Dt = helper2_boxplot(view(data,:,:,nig), pos, w, offs[nig]*boxspacing, _fill, showOL, isVert)
		!isempty(Dt) && (Dol[nol+=1] = Dt)			# Retain only the non-empties
		mi, ma = min(mi, D3[nig].ds_bbox[5]), max(ma, D3[nig].ds_bbox[12])
	end
	(nol < N_grp) && (Dol = Dol[1:nol])
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

	helper3_boxplot(d, D3, Dol, first, isVert, showOL, OLcmd, n4t, true, false)
end

# ----------------------------------------------------------------------------------------------------------
function boxplot(data::Vector{Vector{Vector{T}}}; pos::Vector{<:Real}=Vector{Real}(), first::Bool=true,
                 groupwidth=0.75, ccolor=false, kwargs...) where T

	(!isempty(pos) && length(pos) != size(data,2)) && error("Coordinate vector 'pos' must have same size as columns in 'data'")
	d, isVert, _fill, showOL, OLcmd, w = helper1_boxplot(kwargs)

	N_in_each_grp = length.(data[:])					# Vec with the N elements in each group
	N_grp = length(N_in_each_grp)
	Dol = Vector{GMTdataset}(undef, N_grp)
	D3_ = Vector{GMTdataset}(undef, N_grp)				# As many as number of groups
	_pos = !isempty(pos) ? pos : collect(1.0:N_grp)
	mi, ma, nol = 1e100, -1e100, 0
	for ng = 1:N_grp									# Loop over number of groups
		N_in_this_grp = N_in_each_grp[ng]
		boxspacing = groupwidth / N_in_this_grp
		offs = (0:N_in_this_grp-1) .- ((N_in_this_grp-1)/2);
		_x = fill(_pos[ng], N_in_this_grp) .+ offs*boxspacing	# This case stores the candles by groups.
		D3_[ng], Dt = helper2_boxplot(data[ng], _x, w, 0.0, _fill, showOL, isVert)
		!isempty(Dt) && (Dol[nol+=1] = Dt)				# Retain only the non-empties
		mi, ma = min(mi, D3_[ng].ds_bbox[5]), max(ma, D3_[ng].ds_bbox[12])
	end
	(nol < N_grp) && (Dol = Dol[1:nol])

	set_dsBB!(D3_)		# Set global BoundingBox
	D3_[1].ds_bbox[5], D3_[1].ds_bbox[12] = mi, ma		# Global min/max that includes the outliers

	# Need to compute this now because D3_ may be 'remixed'
	n4t = num4ticks(round.([mean(D3_[k][:, isVert ? 1 : 2]) for k = 1:numel(D3_)], digits=1))

	if (_fill != "")
		custom_colors::Vector{String} = (_fill == "gray70") ? ["gray70"] : String[]
		D = colorize_VecVecVec(D3_, N_grp, N_in_each_grp, ccolor, custom_colors, "box")
		helper3_boxplot(d, D, Dol, first, isVert, showOL, OLcmd, n4t, true, true)
	else
		helper3_boxplot(d, D3_, Dol, first, isVert, showOL, OLcmd, n4t, true, true)
	end
end

# ----------------------------------------------------------------------------------------------------------
function helper3_boxplot(d, D, Dol, first, isVert, showOL, OLcmd, n4t, isGroup::Bool=false, allvar::Bool=false)
	i1,i2,i3,i4 = (isVert) ? (1,2,5,12) : (5,12,3,4)
	(first && (is_in_dict(d, [:R :region :limits]) === nothing)) &&
		(d[:R] = isa(D, Vector) ? 
		         round_wesn([D[1].ds_bbox[i1], D[1].ds_bbox[i2], D[1].ds_bbox[i3], D[1].ds_bbox[i4]], false, [0.1,0.1]) :
		         round_wesn([D.ds_bbox[i1], D.ds_bbox[i2], D.ds_bbox[i3], D.ds_bbox[i4]], false, [0.1,0.1]))

	if (showOL)
		mk, ms, mc, mec = parse_candle_outliers_par(OLcmd)
		d[:scatter] = (data=Dol, marker=mk, ms=ms, mc=mc, mec=mec)		# Still, 'Dol' may be a vec of empties
	end
	if (first)			# Need this check to not duplicate ticks when called from violin
		xt = ((val = find_in_dict(d, [:xticks :yticks :ticks])[1]) !== nothing) ?  val : n4t
		(isVert) ? (d[:xticks] = xt) : (d[:yticks] = xt)		# Vertical or Horizontal sticks
	end

	plotcandles_and_showsep(d, D, first, isVert, n4t, isGroup, allvar)	# See also if a group separator was requested
end

# ----------------------------------------------------------------------------------------------------------
function plotcandles_and_showsep(d, D, first::Bool, isVert::Bool, n4t, isGroup::Bool, allvar::Bool)
	# Plot the candle sticks and deal with the request separator for lines between groups.
	# The ALLVAR case = true is when the groups may have different number of elements. D is then by group.
	showSep = ((SEPcmd = find_in_dict(d, [:separator])[1]) !== nothing)
	(showSep) && (sep_pen = parse_stats_separator_pen(d, SEPcmd))
	(showSep) && (do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0))
	common_plot_xyz("", D, "boxplot", first, false, d...)
	if (showSep)
		issplit = isa(D, Vector) && all(size.(D[:],1) .=== 1)
		if (isGroup)
			xc = (allvar) ? [mean(D[k][:,1]) for k=1:numel(D)] : (D[1][:,isVert ? 1 : 2]+D[end][:,isVert ? 1 : 2])./2
			(allvar && issplit) && (xc = n4t[1])		# A trick because the group info was already lost here
			xs = xc[1:end-1] .+ diff(xc)/2
		else
			xc = (issplit) ? [mean(D[k][:,1]) for k=1:numel(D)] : D[:, isVert ? 1 : 2];
			xs = xc[1:end-1] .+ diff(xc)/2
		end
		(isVert) ? vlines!(xs, pen=sep_pen, show=do_show) : hlines!(xs, pen=sep_pen, show=do_show)
	end
end

# ----------------------------------------------------------------------------------------------------------
parse_candle_outliers_par(OLcmd) = "a", "6p", "black", "0.25p,gray80"
function parse_candle_outliers_par(OLcmd::NamedTuple)::Tuple{String, String, String, String}
	# OLcmd=(marker=??, size=??, color=??) that defaults to: "a" (star); "5p", "black"
	d = nt2dict(OLcmd)
	marker = (haskey(d, :marker)) ? get_marker_name(d, nothing, [:marker], false, false)[1] : "a"
	sz = string(get(d, :size, "6p"))
	color = string(get(d, :color, "black"))
	mec::String = ((val = find_in_dict(d, [:mec :markeredgecolor :MarkerEdgeColor])[1]) !== nothing) ?
	                      arg2str(val,',') : "black"		# No line thickness because psxy adds one (0.5p)
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
	if ((val = (find_in_dict(d, [:boxwidth :cap])[1])) !== nothing)
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
	_fill = ((val = find_in_dict(d, [:G :fill], false)[1]) !== nothing) ? val : ""	# fill should be made a string always
	w = ((val = find_in_dict(d, [:weights])[1]) !== nothing) ? Float64.(val) : Float64[]
	
	return d, isVert, _fill, showOL, OLcmd, w
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
num4ticks(v::AbstractVector{<:Real}) = (v, [@sprintf("%g ", x) for x in v])::Tuple{AbstractVector{<:Real}, Vector{String}}

"""
    violin(data, grp=[]; pos=nothing, kwargs...)

- `data`: A vector (plots a single box), a Matrix (plots n columns boxes), a MxNxG (plots `G` groups)
          of `N` columns boxes, a Vector{Vector} (plots n clumn boxes but from data of different sizes),
          a Vector{Vector{Vector}} (plots G groups - length(data) -, where groups may have variable number
          of elements and each have its own size.)
- `grp`: Categorical vector (made of integers or text strings) used to break down a the data column vector
         in cathegories (groups).
- `pos`: a coordinate vector (or a single location when `data` is a vector) where to plot the boxes.
          Default plots them at 1:n_boxes or 1:n_groups.
- `ccolor`: Logical value indicating whether the groups have constant color (when `fill=true` is used)
           or have variable color (the default).
- `fill`: If fill=true, paint the violins with a pre-defined color scheme. Otherwise, give a list of colors
          to paint them.
- `fillalpha` : When `fill` option is used, we can set the transparency of filled violins with this
          option that takes in an array (vec or 1-row matrix) with numeric values between [0-1] or ]1-100],
	      where 100 (or 1) means full transparency.
- `boxplot`: Logical value indicating whether to add boxplots on top of the violins. When the violins are color
          painted, adding boxplots adds them in light gray.
- `boxwidth` or `cap`: Sets the the boxplot width and, optionally, the cap width. Provide info as
          `boxwidth="10p/3p"` to set the boxwidth different from the cap's. Note, however, that this
           requires GMT6.5. Previous versions do not destinguish box and cap widths.
- `groupWidth`: Specify the proportion of the x-axis interval across which each x-group of boxes should
           be spread. The default is 0.75.
- `horizontal` or `hbar`: plot horizontal instead of vertical boxplots.
- `notch`: Logical value indicating whether the box should have a notch.
- `nbins`: points are queried between MIN(Y[:]) and MAX(Y[:]) where Y is the data vector.
- `bins`: Calculates the density for the query points specified by BINS. The values are used as the
          query points directly. Default is 100 points.
- `bandwidth`: uses the 'bandwidth' to calculate the kernel density. It must be a scalar. BINS may be
             an empty array in order to use the default described above.
- `kernel`: Uses the kernel function specified by KERNEL to calculate the density.
          The kernel may be: 'Normal' (default) or 'Uniform'
- `outliers`: If other than a NamedTuple, plots outliers (1.5IQR) with the default black 5pt stars.
              If argument is a NamedTuple (marker=??, size=??, color=??, markeredge=??), where `marker`
              is one of the `plots` marker symbols, plots the outliers with those specifications. Any missing
              spec default to the above values. i.e `outliers=(size="3p")` plots black 3 pt stars.
- `scatter`: Logical value indicating whether to add a scatter plot on top of the violins (and boxplots) 
           If arg is a NamedTuple, take it to mean the same thing as described above for the `outliers`.
- `weights`: Array giving the weights for the data in `data`. The array must be the same size as `data`.
- `region` or `limits`: By default we estimate the plotting limits but sometimes that may not be convenient.
           Give a region=(x_min,x_max,y_min,y_max) tuple if you want to control the plotting limits.
- `split`: If true, when `data` come in groups, the  groups that have two elements will be plotted with the
           left-side of one and the right side of the other. For groups that have other number of elements
           this option is ignored.
- `ticks` or `xticks` or `yticks`: A tuple with annotations interval and labels. E.g. xticks=(1:5, ["a", "b", "c", "d"])
           where first element is an AbstractArray and second an array or tuple of strings or symbols.
- `separator`: If = true plot a black line separating the groups. Otherwise provide the pen settings of those lines.


Example:
  y = randn(200,4,3);
  violin(y, separator=(:red,:dashed), boxplot=true, outliers=true, fill=true, xticks=["A","B","C","D"], show=1)

  violin(randn(100,3,2), outliers=(ms="6p", mc=:black, mec=("0.25p",:yellow)), fill=true, show=1)

  vvv = [[randn(50), randn(30)], [randn(40), randn(48), randn(45)], [randn(35), randn(43)]];
  violin(vvv, outliers=true, fill=true, separator=:red, split=true, show=1)
"""

# ----------------------------------------------------------------------------------------------------------
violin(data::GMTdataset; pos::Vector{<:Real}=Vector{Real}(), first::Bool=true, kwargs...) =
	violin(data.data; pos=pos, first=first, kwargs...)

# ----------------------------------------------------------------------------------------------------------
function violin(data::Vector{<:Real}, grp::AbstractVector=AbstractVector[]; first::Bool=true,
                pos::Vector{<:Real}=Vector{Real}(), nbins::Integer=100, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, groupwidth=0.75, kernel::StrSymb="normal", kwargs...)

	isempty(grp) && return violin(reshape(data,length(data),1); pos=pos, nbins=nbins, bins=bins,
	                              bandwidth=bandwidth, groupwidth=groupwidth, kernel=kernel, first=first, kwargs...)
	mat, g = agrupa_from_vec(data, grp)
	violin(mat; first=first, pos=pos, nbins=nbins, bins=bins, bandwidth=bandwidth, groupwidth=groupwidth, kernel=kernel,
	       xticks=g, kwargs...)
end

# ----------------------------------------------------------------------------------------------------------
function violin(data::Union{Vector{Vector{T}}, AbstractMatrix{T}}; first::Bool=true, pos::Vector{<:Real}=Vector{Real}(),
                nbins::Integer=100, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, groupwidth=0.75, kernel::StrSymb="normal", kwargs...) where T

	(!isempty(pos) && length(pos) != size(data,2)) && error("Coordinate vector 'pos' must have same size as columns in 'data'")
	scatter = (find_in_kwargs(kwargs, [:scatter])[1] !== nothing)
	isVert  = (find_in_kwargs(kwargs, [:horizontal :hbar])[1] === nothing) ? true : false	# Can't delete here
	Dv, Ds, xc = helper1_violin(data, pos; groupwidth=groupwidth, nbins=nbins, bins=bins, bandwidth=bandwidth,
                                kernel=kernel, scatter=scatter, isVert=isVert)
	helper2_violin(Dv, Ds, data, xc, 1, true, first, isVert, Int[], kwargs)
end

# ------------ For groups ----------------------------------------------------------------------------------
function violin(data::Array{<:Real,3}; pos::Vector{<:Real}=Vector{Real}(), nbins::Integer=100, first::Bool=true,
	            bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, kernel::StrSymb="normal", groupwidth=0.75, ccolor=false, kwargs...)

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
	helper2_violin(D3, Ds, data, xc, N_grp, ccolor, first, isVert, Int[], kwargs)	# House keeping and call the plot funs
end

# ----------------------------------------------------------------------------------------------------------
function violin(data::Vector{Vector{Vector{T}}}; pos::Vector{<:Real}=Vector{Real}(), nbins::Integer=100,
	            first::Bool=true, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, kernel::StrSymb="normal", groupwidth=0.75, ccolor=false, kwargs...) where T

	(!isempty(pos) && length(pos) != length(data)) && error("Coordinate vector 'pos' must have same size as columns in 'data'")
	scatter = (find_in_kwargs(kwargs, [:scatter])[1] !== nothing)
	isVert  = (find_in_kwargs(kwargs, [:horizontal :hbar])[1] === nothing) ? true : false
	split   = (find_in_kwargs(kwargs, [:split])[1] !== nothing)

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
	helper2_violin(D3, Ds, data, 1:N_grp, N_grp, ccolor, first, isVert, N_in_each_grp, kwargs)
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
function helper2_violin(D, Ds, data, xc, N_grp, ccolor, first, isVert, N_in_each_grp, kwargs)
	# This piece of code is common to viloin(Matrix2D) and violin(Matrix3D)
	# Ds is a GMTdataset with the scatter points or an empty one if no scatters.
	# XC vector with the center positions (group centers in case of groups.)
	# ccolor = false		# If colors varie for each in a group, or are constant inside each group.
	# N_in_each_grp is not empty when the caller was the Vector{Vector{Vector}} method

	d = KW(kwargs)
	fill_box = ((val = find_in_kwargs(kwargs, [:G :fill :fillcolor])[1]) !== nothing) ? "gray70" : ""
	if (fill_box != "")		# In this case we may also have received a color list. Check it
		custom_colors = helper_ds_fill(d, nc=length(D))		# A helper function of mat2ds()
		if (isempty(N_in_each_grp))
			n_ds = Int(length(D) / N_grp)
			for m = 1:N_grp
				b = (m - 1) * n_ds + 1;		e = b + n_ds - 1
				colorize_candles_violins(D, n_ds, b:e, !ccolor ? m : 0, custom_colors)
			end
		else
			colorize_VecVecVec(D, N_grp, N_in_each_grp, ccolor, custom_colors, "violin")
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
			R = boxplot(data; first=false, G=fill_box, t=opt_t, hor=hz, otl=otl, byviolin=true, show=this_show)
		else						# The candles + the scatter
			boxplot(data; first=false, G=fill_box, t=opt_t, hor=hz, otl=otl, byviolin=true)
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
function colorize_VecVecVec(D, N_grp, N_in_each_grp, ccolor, custom_colors, type="box")
	if (!ccolor)		# This was a diabolic case
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
			colorize_candles_violins(D, N_grp, vv[m], !ccolor ? m : 0, custom_colors)	# Assign default colors
		end
	else
		colorize_candles_violins(D, N_grp, 1:N_grp, !ccolor ? m : 0, custom_colors)
	end
	return D
end

# ----------------------------------------------------------------------------------------------------------
boxplot!(data::GMTdataset; pos::Vector{<:Real}=Vector{Real}(), kw...) = boxplot(data.data; pos=pos, first=false, kw...)
boxplot!(data::AbstractVector{<:Real}, grp::AbstractVector=AbstractVector[]; pos::Vector{<:Real}=Vector{Real}(), kw...) = boxplot(data, grp; pos=pos, first=false, kw...)
boxplot!(data::Union{Vector{Vector{T}}, AbstractMatrix{T}}; pos::Vector{<:Real}=Vector{Real}(), kw...) where T = boxplot(data; pos=pos, first=false, kw...)
boxplot!(data::Array{T,3}; pos::Vector{<:Real}=Vector{Real}(), groupwidth=0.75, ccolor=false, kw...) where T = boxplot(data; pos=pos, groupwidth=groupwidth, ccolor=ccolor, first=false, kw...)
boxplot!(data::Vector{Vector{Vector{T}}}; pos::Vector{<:Real}=Vector{Real}(), groupwidth=0.75, ccolor=false, kw...) where T = boxplot(data; pos=pos, groupwidth=groupwidth, ccolor=ccolor, first=false, kw...)

violin!(data::GMTdataset; pos::Vector{<:Real}=Vector{Real}(), kw...) = violin(data.data; pos=pos, first=false, kw...)
violin!(data::AbstractVector{<:Real}, grp::AbstractVector=AbstractVector[]; pos::Vector{<:Real}=Vector{Real}(), kw...) = violin(data, grp; pos=pos, first=false, kw...)
violin!(data::Union{Vector{Vector{T}}, AbstractMatrix{T}}; pos::Vector{<:Real}=Vector{Real}(), nbins::Integer=100, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, groupwidth=0.75, kernel::StrSymb="normal", kw...) where T = violin(data; pos=pos, nbins=nbins, bins=bins, bandwidth=bandwidth, groupwidth=groupwidth, kernel=kernel, first=false, kw...)
violin!(data::Array{<:Real,3}; pos::Vector{<:Real}=Vector{Real}(), nbins::Integer=100, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, groupwidth=0.75, kernel::StrSymb="normal", ccolor=false, kw...) = violin(data; pos=pos, nbins=nbins, bins=bins, bandwidth=bandwidth, groupwidth=groupwidth, kernel=kernel, ccolor=ccolor, first=false, kw...)
violin!(data::Vector{Vector{Vector{T}}}; pos::Vector{<:Real}=Vector{Real}(), nbins::Integer=100, bins::Vector{<:Real}=Vector{Real}(), bandwidth=nothing, groupwidth=0.75, kernel::StrSymb="normal", ccolor=false, kw...) where T = violin(data; pos=pos, nbins=nbins, bins=bins, bandwidth=bandwidth, groupwidth=groupwidth, kernel=kernel, ccolor=ccolor, first=false, kw...)

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

# ----------------------------------------------------------------------------------------------------------
# Parts of this are from Distributions.jl & Makie

"""
    qqplot(x::AbstractVector{AbstractFloat}, y::AbstractVector{AbstractFloat}; kwargs...)

The qqplot function compares the quantiles of two distributions.

- `qqline`: determines how to compute a fit line for the Q-Q plot. The options are
    - `identity`: draw the line y = x (the deafult).
    - `fit`: draw a least squares line fit of the quantile pairs.
    - `fitrobust ` or `quantile`: draw the line that passes through the first and third quartiles of the distributions.
    - `none`: do not draw any line.

    Broadly speaking, `qqline=:identity` is useful to see if x and y follow the same distribution, whereas `qqline=:fit` and `qqline=:fitrobust` are useful to see if the distribution of y can be obtained from the distribution of x via an affine transformation.
- For fine setting of the line and scatter points use the same options as in the `plot` module.

Examples:

    qqplot(randn(100), randn(100), show=true)

    qqplot(randn(100), show=true)

"""
function qqplot(x, y; qqline=:identity, first=true, kwargs...)
	!(qqline in (:identity, :fit, :fitrobust, :quantile, :none)) &&
		throw(ArgumentError("valid values for qqline are :identity, :fit, :fitrobust or :none, but encountered " * repr(qqline)))
	qx, qy = qqbuild(x, y)
	xs = collect(extrema(qx))
	plotline = true				# By default we want the fit line plotted
	if (qqline === :identity)
		ys = xs
	elseif (qqline === :fit)
		itc, slp = hcat(fill!(similar(qx), 1), qx) \ qy
		ys = slp .* xs .+ itc
	elseif (qqline === :quantile || qqline == :fitrobust)
		quantx, quanty = quantile(qx, [0.25, 0.75]), quantile(qy, [0.25, 0.75])
		slp = diff(quanty) ./ diff(quantx)
		ys = quanty .+ slp .* (xs .- quantx)
	else	# no line
		plotline = false
	end

	# Because the plot with the points and the line are actually two plots and we have only one "kwargs"
	# we must do some fishing and conditionaly set some defaults.
	d = KW(kwargs)
	(is_in_dict(d, [:aspect]) === nothing) && (d[:aspect] = :equal)
	do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)

	if (plotline)						# Normally, we want the line but a 'qqline=:none' avoids it.
		if (is_in_dict(d, [:R :region :limits]) === nothing)	# Need to pass in the scatter limits, not the line's
			t::Vector{Float64} = round_wesn([xs..., extrema(qy)...])
			d[:R] = @sprintf("%.12g/%.12g/%.12g/%.12g", t[1], t[2], t[3], t[4])
		end
		lines("", [xs ys]; first=first, d...)		# Plot the line
		is_in_dict(d, [:aspect :xaxis :yaxis :axis2 :xaxis2 :yaxis2 :title :subtitle :xlabel :ylabel :xticks :yticks], del=true)
		del_from_dict(d, [[:R, :region, :limits], [:W, :pen], [:B, :frame, :axes, :axis]])
		first = false
	end

	find_in_dict(d, [:ms :markersize :MarkerSize :size], false)[1] === nothing && (d[:ms] = "4p")
	if (find_in_dict(d, [:G :mc :markercolor :markerfacecolor :MarkerFaceColor], false)[1] === nothing)
		d[:G] = "#0072BD"
		(find_in_dict(d, [:mec :markeredgecolor :MarkerEdgeColor], false)[1] === nothing) && (d[:mec] = "0.25p,black")
	end
	d[:show] = do_show
	common_plot_xyz("", [qx qy], "scatter", first, false, d...)		# The scatter plot
end

function qqplot(x; qqline=:identity, first=true, kwargs...)
	p = (.5:length(x)) ./ length(x)
	y = sqrt(2) .* erfinv(2 .* p .- 1)
	qqplot(x, y; qqline=qqline, first=first, kwargs...)
end

qqplot!(x, y; qqline=:identity, kw...) = qqplot(x, y; qqline=qqline, first=false, kw...)
qqplot!(x; qqline=:identity, kw...) = qqplot(x; qqline=qqline, first=false, kw...)

"""
    qqnorm(x; qqline=:identity, kwargs...)

The qqnorm is a `qqplot` shorthand for comparing a distribution to the normal distribution. If the
distributions are similar the points will be on a straight line.
"""
qqnorm(x; qqline=:identity, first=true, kw...) = qqplot(x; qqline=qqline, first=first, kw...)
qqnorm!(x; qqline=:identity, kw...) = qqplot(x; qqline=qqline, first=false, kw...)

function qqbuild(x::AbstractVector, y::AbstractVector)
	n = min(length(x), length(y))
	grid = [0.0:(1 / (n - 1)):1.0;]
	qx = quantile(x, grid)
	qy = quantile(y, grid)
	return qx, qy
end

# This is from SpecialFunctions.jl
using Base.Math: @horner
erfinv(x::AbstractFloat) = _erfinv(Float64(x))

function erfinv(x::AbstractVector{<:AbstractFloat})
	efi = Vector{Float64}(undef, numel(x))
	for k = 1:numel(x)
		efi[k] = _erfinv(Float64(x[k]))
	end
	return efi
end

function _erfinv(x::Float64)
	a = abs(x)
	if a >= 1.0
		if     (x == 1.0)   return Inf
		elseif (x == -1.0)  return -Inf
		end
		throw(DomainError(a, "`abs(x)` cannot be greater than 1."))
	elseif a <= 0.75 # Table 17 in Blair et al.
		t = x*x - 0.5625
		return x * @horner(t, 0.16030_49558_44066_229311e2, -0.90784_95926_29603_26650e2, 0.18644_91486_16209_87391e3,
							 -0.16900_14273_46423_82420e3, 0.65454_66284_79448_7048e2, -0.86421_30115_87247_794e1,
							  0.17605_87821_39059_0) /
				   @horner(t, 0.14780_64707_15138_316110e2, -0.91374_16702_42603_13936e2, 0.21015_79048_62053_17714e3,
							 -0.22210_25412_18551_32366e3, 0.10760_45391_60551_23830e3, -0.20601_07303_28265_443e2,
							  0.1e1)
	elseif a <= 0.9375 # Table 37 in Blair et al.
		t = x*x - 0.87890625
		return x * @horner(t, -0.15238_92634_40726_128e-1, 0.34445_56924_13612_5216, -0.29344_39867_25424_78687e1,
							   0.11763_50570_52178_27302e2, -0.22655_29282_31011_04193e2, 0.19121_33439_65803_30163e2,
							  -0.54789_27619_59831_8769e1, 0.23751_66890_24448) /
				   @horner(t, -0.10846_51696_02059_954e-1, 0.26106_28885_84307_8511, -0.24068_31810_43937_57995e1,
							   0.10695_12997_33870_14469e2, -0.23716_71552_15965_81025e2, 0.24640_15894_39172_84883e2,
							  -0.10014_37634_97830_70835e2, 0.1e1)
	else # Table 57 in Blair et al.
		t = inv(sqrt(-log1p(-a)))
		return @horner(t, 0.10501_31152_37334_38116e-3, 0.10532_61131_42333_38164_25e-1, 0.26987_80273_62432_83544_516,
						  0.23268_69578_89196_90806_414e1, 0.71678_54794_91079_96810_001e1, 0.85475_61182_21678_27825_185e1,
						  0.68738_08807_35438_39802_913e1, 0.36270_02483_09587_08930_02e1, 0.88606_27392_96515_46814_9) /
			  (copysign(t, x) *
			   @horner(t, 0.10501_26668_70303_37690e-3, 0.10532_86230_09333_27531_11e-1, 0.27019_86237_37515_54845_553,
						  0.23501_43639_79702_53259_123e1, 0.76078_02878_58012_77064_351e1, 0.11181_58610_40569_07827_3451e2,
						  0.11948_78791_84353_96667_8438e2, 0.81922_40974_72699_07893_913e1, 0.40993_87907_63680_15361_45e1,
						  0.1e1))
	end
end

# ----------------------------------------------------------------------------------------------------------
function ecdf(x::AbstractVector{<:Real})
	# Adapted from Patrik Forssén (2022). Fast Empirical CDF (https://www.mathworks.com/matlabcentral/fileexchange/114990-fast-empirical-cdf)
	xF, idx = gunique(x, sorted=true)
	
	# Number of occurrences of each unique sample
	counts = zeros(Int32,maximum(idx))
	for k in idx  counts[k] = 1  end	# Replicate what this does in Matlab:  counts = accumarray(idx, 1);

	F = cumsum(counts)/numel(x)			# Sum the occurrences to get the CDF 
	xF0 = xF[1] - 10*eps(xF[1])			# First point (do not want it to be repeated)
	 
	F  = [0; F]
	xF = [xF0; xF]
	xF, F
end

# ----------------------------------------------------------------------------------------------------------
"""
    ecdfplot(x::AbstractVector{<:Real}; kwargs...)

Plot the empirical cumulative distribution function (ECDF) of `x`.
The `kwargs` may contain any option used in the `plot` module.

Example:
    ecdfplot(randn(100), show=true)
"""
function ecdfplot(x::AbstractVector{<:Real}; first=true, kwargs...)
	x, y = ecdf(x)
	stairs("", [x y]; first=first, kwargs...)
end
ecdfplot!(x::AbstractVector{<:Real}; kwargs...) = ecdfplot(x; first=false, kwargs...)


# ----------------------------------------------------------------------------------------------------------
"""
    parallelplot(cmd0="", arg1=nothing; labels|axeslabels=String[], group=Vector{String},
	             groupvar="", normalize="range", kwargs...)

- `axeslabels` or `labels`: String vector with the names of each variable axis. Plots a default "Label?" if
     not provided.
- `group`: A string vector or vector of integers used to group the lines in the plot.
- `groupvar`: Uses the table variable specified by `groupvar` to group the lines in the plot. `groupvar` can
     be a column number, or a column name passed in as a Symbol. *e.g.* `groupvar=:Male` if a column with that
     name exists.  When `arg1` is GMTdatset or `cmd0` is the name of a file with one and it has the `text` field
     filled, use `groupvar="text"` to use that text field as the grouping vector.
- `yvar`: This can take the form of column names or column numbers. Example `yvar=(2,3)`, or `yvar=[:Y, :Z1, :Z2]`.
- `nomalize`: 
    - `range`: (Default) Display raw data along coordinate rulers that have independent minimum and maximum limits.
	- `none`: Display raw data along coordinate rulers that have the same minimum and maximum limits.
	- `zscore`: Display z-scores (with a mean of 0 and a standard deviation of 1) along each coordinate ruler.
	- `scale`: Display values scaled by standard deviation along each coordinate ruler.
- `quantile`: Give a quantile in the [0-1] interval to plot the median +- `quantile` as dashed lines.
- `std`: Instead of median plus quantile lines, draw the mean +- one standard deviation. This is achieved with
     both `std=true` or `std=1`. For other number od standard deviations use, *e.g.* `std=2`, or `std=1.5`.
- `band`: If used, instead of the dashed lines referred above, plot a band centered in the median. The band
     colors are assigned automatically but this can be overriden by the `fill` option. If set and `quantile`
     not given, set a default of `quantile = 0.25`.
- `fill`: When `band` option is used and want to control the bands colors, give a list of colors to paint them.
- `fillalpha` : When `fill` option is used, we can set the bands transparency with this option that takes in an array
    (vec or 1-row matrix) with numeric values between [0-1] or ]1-100], where 100 (or 1) means full transparency.
- For fine the lines settings use the same options as in the `plot` module.

Example:

    parallelplot("iris.dat", groupvar="text", quantile=0.25, legend=true, band=true, show=1)
"""
function parallelplot(cmd0::String="", arg1=nothing; first::Bool=true, axeslabels::Vector{String}=String[],
                      labels::Vector{String}=String[], group::AbstractVector=AbstractVector[], groupvar="", normalize="range", kwargs...)
	d = KW(kwargs)
	(cmd0 != "") && (arg1 = read_data(d, cmd0, "", arg1, " ", false, true)[2])	# Make sure we have the data here
	if     (isa(arg1, Matrix{<:Real}))        data = mat2ds(arg1)
	elseif (isa(arg1, Vector{<:GMTdataset}))  data = ds2ds(arg1)
	else                                      data = mat2ds(arg1)
	end
	(isempty(group) && groupvar == "text") && (group = data.text)
	(!isempty(group) && length(group) != size(data,1)) && error("Length of `group` and number of rows in input don't match.")
	set_dsBB!(data)		# Update the min/maxs

	data = with_xyvar(d, data, true)			# See if we have a column request based on column names
	_bbox = data.ds_bbox

	!isempty(labels) && (axeslabels = labels)	# Alias that does not involve a F. Any
	isempty(axeslabels) && (axeslabels = data.colnames[1:size(data,2)])

	n_axes = size(data,2)						# Number of axes in this plot
	ax_pos = 1:n_axes

	_quantile::Float64 = ((val = find_in_dict(d, [:quantile])[1]) !== nothing) ? val : 0.0
	(_quantile < 0 || _quantile > 0.5) && error("`quantile` must be in the [0, 0.5] interval")
	haveband = haskey(d, :band)					# To know if data must be formatted for band() use.
	(haveband && _quantile == 0) && (_quantile = 0.25)	# Default to quantile = 0.25 when not given and ask for band
	_std::Float64 = ((val = find_in_dict(d, [:std])[1]) === nothing) ? 0.0 : (isa(val, Bool) ? 1.0 : val)

	function helper_D(D, _data, gidx, normtype, _bbox, gc)
		# Common to two IF branches
		b, n = 1, 0
		for k = 1:numel(gidx)					# Loop over number of groups
			nr = length(gidx[k])
			t = normalizeArray(normtype, _data[gidx[k],:], _bbox)
			if (_quantile == 0 && _std == 0)	# No envelope lines nor bands
				D[b:b+nr-1] = mat2ds(collect(t'), x=ax_pos, multi=true, color=[gc[k]])
			else
				l, c, h = zeros(size(t,2)), zeros(size(t,2)), zeros(size(t,2))
				for nc = 1:size(t,2)
					vc = view(t, :,nc)
					if (_std == 0)				# Quantiles
						l[nc], c[nc], h[nc] = quantile(skipnan(vc), [0.5-_quantile, 0.5, 0.5+_quantile])
					else						# Mean +- STD
						c[nc] = nanmean(vc)
						_st = std_nan(vc)[1] * _std
						l[nc], h[nc] = c[nc] - _st, c[nc] + _st
					end
				end
				# THE SHIT. GMT6.4 is bugged when headers contain the -G<color> field (it screws the polygons)
				if (haveband)		# Format to use in band()
					# But we need that -G<color> for latter trickly extract the and use it in the online command.
					D[n+=1] = mat2ds(c, x=ax_pos, multi=true, color=[gc[k]], fill=[gc[k]], fillalpha=0.7)[1]
					D[n].data = [D[n].data c.-l h.-c]
					D[n].colnames = [D[n].colnames..., "Low", "High"]
				else
					D[n+=1] = mat2ds(c, x=ax_pos, multi=true, color=[gc[k]])[1]
					D[n+=1] = mat2ds(l, x=ax_pos, multi=true, color=[gc[k]], ls=:dash)[1]
					D[n+=1] = mat2ds(h, x=ax_pos, multi=true, color=[gc[k]], ls=:dash)[1]
				end
			end
			b += nr
		end	
		(_quantile != 0 || _std != 0) && deleteat!(D, n+1:length(D))	# Because in this case D was allocated in excess.
		D
	end

	function check_bbox!(_data, _bbox)		# Check that bbox has no NaNs
		if (any(isnan.(_bbox)))
			for k = 1:size(_data,2)
				isnan(_bbox[2k-1]) && (_bbox[2k-1] = minimum_nan(view(_data, :,k))) 
				isnan(_bbox[2k]) && (_bbox[2k] = maximum_nan(view(_data, :,k))) 
			end
		end
	end

	(isempty(group) && isa(groupvar, Integer)) && (group = data.data[:, groupvar])
	(isempty(group) && isa(groupvar, Symbol))  && (group = data.data[groupvar, groupvar][:,2])	# With some risky trickery
	(isempty(group)) && (group = fill(0, size(data,1)))		# Make it a single group to reuse the same code
	gidx, gnames = grp2idx(group)

	D = Vector{GMTdataset}(undef, length(group))
	gc = helper_ds_fill(d; nc=numel(gidx))
	isempty(gc) && (gc = (numel(gidx) < 8) ? matlab_cycle_colors : simple_distinct)		# Group colors
	if (normalize == "range" || normalize == "" || normalize == "none")
		helper_D(D, data.data, gidx, normalize, _bbox, gc)	# Splits D in many D's (one per line)
	else
		_data = copy(data.data)
		for k = 1:numel(gidx)
			_data[gidx[k],:] = normalizeArray(normalize, _data[gidx[k],:])
		end
		_bbox = collect(Iterators.flatten(extrema(_data, dims=1)))
		check_bbox!(_data, _bbox)		# Ensure _bbox has no NaNs
		helper_D(D, _data, gidx, "range", _bbox, gc)
	end

	(is_in_dict(d, [:figsize :fig_size]) === nothing) && (d[:figsize] = def_fig_size)
	d[:xticks] = (ax_pos, axeslabels)
	do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)

	del_from_dict(d, [:R, :region, :limits])		# Clear any eventualy user provided -R
	if (normalize != "" && normalize != "none")
		d[:R], d[:B] = @sprintf("1/%d/0/1", n_axes), "xa0 S"
	else
		mima = round_wesn([0. 0. extrema(_bbox)...])[3:4]
		d[:R] = @sprintf("1/%d/%.10g/%.10g", n_axes, mima...)
	end
	!haskey(d, :Vd) && (d[:Vd] = 0)					# To no warn if basemap unknown options have been used. e.g. -W
	basemap(; d...)						# <== Start the plot

	del_from_dict(d, [[:R], [:B, :frame, :axes, :axis], [:J, :proj], [:figsize, :fig_size], [:band], [:aspect], [:xaxis], [:yaxis], [:axis2], [:xaxis2], [:yaxis2], [:title], [:subtitle], [:xlabel], [:ylabel], [:xticks], [:yticks]])

	if (normalize != "" && normalize != "none")		# Plot the vertical axes
		for k = 1:n_axes-1
			basemap!(R= @sprintf("0/%d/%.10g/%.10g", n_axes, _bbox[2*(k-1)+1], _bbox[2k]), X="a$((k-1)*CTRL.figsize[1]/(n_axes-1))", B="W yaf", Vd=d[:Vd])
		end
		basemap!(R= @sprintf("0/%d/%.10g/%.10g", n_axes, _bbox[2*(n_axes-1)+1], _bbox[2n_axes]), B="E yaf", Vd=d[:Vd])
		d[:R] = @sprintf("1/%d/0/1", n_axes)		# Reset this because under the hood they are all normalized
	end
	
	d[:W] = build_pen(d, true)
	d[:show] = do_show
	!haveband && (d[:gindex] = [gidx[k][1] for k=1:numel(gidx)])	# The `band` case is handled in put_in_legend_bag
	(_quantile != 0 || _std != 0) && (d[:gindex] = 1:3:length(D))	# But the envelope is a different case
	(!haveband && haskey(d, :legend) && isa(d[:legend], Bool) && d[:legend] && gnames != 0) && (d[:label] = gnames)
	!haveband ? common_plot_xyz("", D, "line", false, false, d...) : plot_bands_from_vecDS(D, d, do_show, d[:W], gnames)
end

parallelplot!(cmd0::String="", arg1=nothing; axeslabels::Vector{String}=String[], labels::Vector{String}=String[], group::AbstractVector=AbstractVector[], groupvar="", normalize="range", kw...) = parallelplot(cmd0, arg1; first=false, axeslabels=axeslabels, labels=labels, group=group, groupvar=groupvar, normalize=normalize, kw...)

parallelplot(arg1; axeslabels::Vector{String}=String[], labels::Vector{String}=String[], group::AbstractVector=AbstractVector[], groupvar="", normalize="range", kw...) = parallelplot("", arg1; first=true, axeslabels=axeslabels, labels=labels, group=group, groupvar=groupvar, normalize=normalize, kw...)

parallelplot!(arg1; axeslabels::Vector{String}=String[], labels::Vector{String}=String[], group::AbstractVector=AbstractVector[], groupvar="", normalize="range", kw...) = parallelplot("", arg1; first=false, axeslabels=axeslabels, labels=labels, group=group, groupvar=groupvar, normalize=normalize, kw...)

# ----------------------------------------------------------------------------------------------------------
function plot_bands_from_vecDS(D::Vector{GMTdataset}, d, do_show, pen, gnames)
	# This function is needed because of a GMT bug that screws the polygons when headers have -G
	d[:show], isname = false, false
	lw, lc, ls = break_pen(pen)
	for k = 1:numel(D)
		s = split(D[k].header)
		d[:G] = string(s[2][3:end])
		d[:W] = lw * (lc == "" ? s[1][3:end] : ","*lc) * "," * ls
		if (haskey(d, :legend))
			(isname || (isa(d[:legend], Bool) && d[:legend])) && (d[:legend] = gnames[k]; isname = true)
		end
		D[k].header = string(s[1])
		(k == numel(D)) && (d[:show] = do_show)		# Last one. Show it if has to.
		band!(D[k]; d...)
	end
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
function normalizeArray(method, A, bbox=Float64[])
	# Matrix A should NOT contain NaNs
	n_cols = size(A,2)
	if (method == "range")		# rulers (columns) have independent minimum and maximum limits
		for n = 1:n_cols
			A[:,n] = ((view(A, :,n) .- bbox[2*(n-1)+1])) ./ (bbox[2n] - bbox[2*(n-1)+1])
		end
	elseif (method == "zscore")	# z-scores (mean of 0 and a standard deviation of 1) along each coordinate ruler
		if (any(isnan.(A)))
			S, C = zeros(1, n_cols), zeros(1, n_cols)
			for k = 1:n_cols
				t = skipnan(view(A, :,k))
				S[k] = std(t)
				C[k] = mean(t)
			end
		else
			S, C = std(A, dims=1), mean(A, dims=1)
		end
		A = (A .- C) ./ S
	elseif (method == "scale")	# values scaled by standard deviation along each coordinate ruler
		S = std_nan(A)
		A = A ./ S
	end
	A
end

# ----------------------------------------------------------------------------------------------------------
"""
    cornerplot(data; kwargs...)

Takes a nSamples-by-nDimensions array, and makes density plots of every combination of the dimensions.
Plots as a triangular matrix of subplots showing the correlation among input variables. Input `data`
can be a MxN matrix, a `GMTdataset` or a file name that upon reading with `gmtread` returns a `GMTdataset`.

The plot consists of histograms of each column along the diagonal and scatter or hexagonal bining plots
for the inter-variable relations, depending on if the the number of samples is <= 1000. But this can be
changed with options in `kwargs`.

- `cornerplot(data)`: plots every 2D projection of a multidimensional data set. 
- `cornerplot(..., varnames)`: prints the names of each dimension. `varnames` is a vector of strings
   of length nDimensions. If not provided, column names in the `GMTdaset` are used.
- `cornerplot(..., truths)`: indicates reference values on the plots.
- `cornerplot(..., quantile)`: list of fractional quantiles to show on the 1-D histograms as vertical dashed lines.
- `cornerplot(..., hexbin=true)`: Force hexbin plots even when number of points <= 1000.
- `cornerplot(..., scatter=true)`: Force scatter plots even when number of points > 1000.
- `cornerplot(..., histcolor|histfill=color)`: To paint diagonal histograms witha selected color (histcolor=:none to no paint).

Several more options in `kwargs` can be used to control plot details (and are passed to the `subplot`,
`binstats` and `plot` functions.)

Example:
    cornerplot(randn(2500,3), cmap=:viridis, show=1)
"""
cornerplot(fname::String; first::Bool=true, kw...) = cornerplot(gmtread(fname); first=first, kw...)
function cornerplot(arg1; first::Bool=true, kwargs...)
	# ...
	d = KW(kwargs)
	D = mat2ds(arg1)				# Simplifies life further down (knows min/maxs etc)
	D = with_xyvar(d, D, true)		# See if we have a column request based on column names
	ndims = size(D,2)
	(size(D,1) < ndims) && throw(ArgumentError("input array should have less samples than dimensions, try transposing"))
	CTRL.figsize[1] = (ndims == 2) ? 8 : (ndims == 3 ? 6 : 20/ndims)	# Set figsize needed to compute hexagons size
	endwith = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0) ? Symbol("show") : Symbol("end")
	Vd = haskey(d, :Vd) ? d[:Vd] : -1

	(is_in_dict(d, [:SC :Sc :col_axes :colaxes :sharex]) === nothing) && (d[:SC] = "b")
	(is_in_dict(d, [:SR :Sr :row_axes :rowaxes :sharey]) === nothing) && (d[:SR] = "lx")
	(is_in_dict(d, [:M :margin :margins]) === nothing) && (d[:M] = "0.05")
	((val = find_in_dict(d, [:title])[1]) !== nothing) && (d[:T] = val)		# Must check this before parse_B() comes on
	d[:B] = ((opt_B = parse_B(d, "")[2]) != "") ? replace(opt_B, "-B" => "") : "WSrt"
	d[:Vd] = Vd
	d[:grid] = "$(ndims)x$(ndims)"

	r = subplot(; d...)
		d = CTRL.pocket_d[1]		# Get back what was not consumemd in subplot
		(Vd >= 0) && (d[:Vd] = Vd)	# Restore this in case
		(Vd == 2) && return r		# Almost useless but at least wont error
		truths::Vector{Float64} = ((val = find_in_dict(d, [:truths])[1]) !== nothing) ? val : Float64[]
		(!isempty(truths) && length(truths) != size(D,2)) && (@warn("The `truths` vector must have same length as n dimensions. Ignoring it."); truths = Float64[])
		quantiles::Vector{Float64} = ((val = find_in_dict(d, [:quantiles])[1]) !== nothing) ? val : Float64[]

		# Plot the diagonal histograms. Compute a nice xmin/xmax and create a -Rxmin/xmax/0/0
		# This has the further beautifull side effect of aligning exactly the x annotations of the other
		# non diagonal plots because the algorith to auto xlimits is the same.
		hstColor::String = ((val = find_in_dict(d, [:histcolor, :histfill])[1]) !== nothing) ? string(val) : "#0072BD"
		for k = 1:ndims
			t = D[:,k]
			mima = round_wesn([extrema(t)...,0,0])
			opt_R = @sprintf("%.10g/%.10g/0/0", mima[1], mima[2])
			if (k == 1)
				histogram(t, panel=(k,k), R=opt_R, G=hstColor, W=0.1, Vd=Vd)
			elseif (k < ndims)
				histogram(t, conf=(MAP_FRAME_TYPE="inside",), B="Wsrt a", R=opt_R, G=hstColor, W=0.1, panel=(k,k), Vd=Vd)
			else			# Here we want to have annotations both inside and outside, which is not possible. So trickit
				histogram(t, B="lSrt a", R=opt_R, panel=(k,k), fill="", W="0,white", Vd=Vd)	# Used only to plot the bott axis
				histogram(t, conf=(MAP_FRAME_TYPE="inside",), B="Wbrt a", R=opt_R, G=hstColor, W=0.1, Vd=Vd)
			end
			(!isempty(quantiles)) && vlines!(quantile(view(D,:,k), quantiles); ls=:dash)
			(!isempty(truths))    && vlines!(truths[k]; lw=0.75)
		end
		ndims == 1 && return subplot(endwith)

		d2::Dict{Symbol, Any} = Dict()
		do_scatter, do_hexbin = false, false
		if ((val = find_in_dict(d, [:scatter])[1]) !== nothing)
			(val == 1) && (do_scatter = true)
		elseif ((val = find_in_dict(d, [:hexbin])[1]) !== nothing)
			do_hexbin = true
			(isa(val, NamedTuple)) && (d2 = nt2dict(val))		# To pass a opts to binstats
		else
			(size(D,1) > 1000) ? (do_hexbin = true) : (do_scatter = true)	# When > 1k pts def to hexbin
		end
		(do_hexbin) && (d[:hexbin] = true;	d2[:C] = "number";	d2[:tiling] = "hex")

		varnames::Vector{String} = ((val = find_in_dict(d, [:varnames])[1]) !== nothing) ? string.(val) : D.colnames
		(length(varnames) < length(D.colnames)) && (varnames = D.colnames)		# Quick&dirty for user idiot input

		# Plot the other subplots down the columns
		for c1 = 1:ndims-1				# col
			for c2 = c1+1:ndims			# row
				d[:panel] = (c2,c1)
				d[:xlabel], d[:ylabel] = varnames[c1], varnames[c2]
				if (do_scatter)
					d[:marker] = ((val = find_in_dict(d, [:marker :Marker :shape])[1]) !== nothing) ? val : "p"
					common_plot_xyz("", D[:,[c1,c2]], "scatter", first, false, d...)
				else		#if (do_hexbin)
					d[:ml] = 0.1;
					common_plot_xyz("", gmtbinstats(D[:,[c1,c2]]; d2...), "scatter", first, false, d...)
				end
				if (!isempty(truths))
					hlines!(truths[c2])
					vlines!(truths[c1])
				end
			end
		end
	subplot(endwith)
end
cornerplot!(arg1; kw...) = cornerplot(arg1; first=false, kw...)
cornerplot!(fname::String; kw...) = cornerplot(gmtread(fname); first=false, kw...)

# ----------------------------------------------------------------------------------------------------------
# marginalhist(randn(2000,2), scatter=true, show=true, histkw=(annot=true,))
# marginalhist(randn(2000,2), scatter=true, show=true, histkw=(frame="none",))
# marginalhist(randn(2000,2), scatter=true, show=true, histkw=(frame="none", G=:green, W="0@100"), Vd=1)
# marginalhist(randn(2000,2), scatter=true, density=true, show=true, histkw=(frame=:none, G="red@60"), Vd=1)
marginalhist(fname::String; first::Bool=true, kw...) = marginalhist(gmtread(fname); first=first, kw...)
function marginalhist(arg1::Union{GDtype, Matrix{<:Real}}; first=true, kwargs...)
	d = KW(kwargs)
	D = mat2ds(arg1)				# Simplifies life further down (knows min/maxs etc)
	D = with_xyvar(d, D, true)		# See if we have a column request based on column names
	endwith = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0) ? Symbol("show") : Symbol("end")
	Vd = haskey(d, :Vd) ? d[:Vd] : -1

	#(is_in_dict(d, [:M :margin :margins]) === nothing) && (d[:M] = "-0.20c")
	((val = find_in_dict(d, [:title])[1]) !== nothing) && (d[:T] = val)		# Must check this before parse_B() comes on
	d[:B] = ((opt_B = parse_B(d, "")[2]) != "") ? replace(opt_B, "-B" => "") : "WSrt"
	d[:Vd] = Vd
	d[:grid] = "2x2"

	gap::Float64 = ((val = find_in_dict(d, [:gap :margin :margins])[1]) === nothing) ? 0.0 : val
	gap_total = gap - 0.2
	d[:M] = "$gap_total"

	d2::Dict{Symbol, Any} = Dict()
	do_scatter, do_hexbin = false, false
	if ((val = find_in_dict(d, [:scatter])[1]) !== nothing)
		(val == 1) && (do_scatter = true)
	elseif ((val = find_in_dict(d, [:hexbin])[1]) !== nothing)
		do_hexbin = true
		(isa(val, NamedTuple)) && (d2 = nt2dict(val))		# To pass a opts to binstats
	else
		(size(D,1) > 2000) ? (do_hexbin = true) : (do_scatter = true)	# When > 1k pts def to hexbin
	end
	(do_hexbin) && (d[:hexbin] = true;	d2[:C] = "number";	d2[:tiling] = "hex")

	opt_J = parse_J(d, "")[2][5:end]	# Drop the initial " -JX"
	s = split(opt_J, "/")
	W = size_unit(s[1])
	if (length(s) > 1 && s[2] == "0" || s[2] == "?")	# In this case, recompute fig size to e isometric
		H = W * (D.ds_bbox[4] - D.ds_bbox[3]) / (D.ds_bbox[2] - D.ds_bbox[1])
		opt_J = "$(W)/$(H)"
	elseif (opt_J == def_fig_size)		# Here switch of Hexbins. The ELSE case is not taken care (no hexbins if not iso)
		do_hexbin = false
	end

	f::Float64 = ((val = find_in_dict(d, [:frac :fraction])[1]) !== nothing) ? val : 0.15
	d[:F] = "f" * opt_J * "/+f" * "$(1/f),1/1,$(1/f)"
	CTRL.figsize[1] = W					# Set figsize needed to compute hexagons size
	doDensity = (find_in_dict(d, [:density :Density])[1] !== nothing)	# For now, no control on the density computing params

	r = subplot(; d...)
		d = CTRL.pocket_d[1]			# Get back what was not consumemd in subplot
		(Vd >= 0) && (d[:Vd] = Vd)		# Restore this in case
		(Vd == 2) && return r			# Almost useless but at least wont error

		cmd_hist, annotHst, doBH = "", "", true
		if ((val = find_in_dict(d, [:histkw :hist_kw :histkwargs :hist_kwargs])[1]) !== nothing && isa(val, NamedTuple))
			dh::Dict{Symbol, Any} = nt2dict(val);	dh[:Vd] = 2;
			annotHst = ((val = find_in_dict(dh, [:annot])[1]) !== nothing) ? (val == true ? " -Ba" : arg2str(val)) : ""
			cmd_hist = histogram(nothing; dh...)[12:end]	# Let the histogram module parse all options (and drop prog name)
			(((symb = is_in_dict(dh, [:frame :axes])) !== nothing) && (dh[symb] == :none || dh[symb] == "none")) && (doBH = false)
		end
		!contains(cmd_hist, "-W") && (cmd_hist *= (doDensity ? " -W0.5" : " -W0.1"))
		!contains(cmd_hist, "-G") && (cmd_hist *= " -G" * (((val = find_in_dict(d, [:histcolor, :histfill])[1]) !== nothing) ? string(val) : "#0072BD"))
		contains(cmd_hist, " -R") && @warn("SHOULD NOT have tried to set histogram limits.")

		# Top Histogram
		t = D[:,1]
		mima = round_wesn([extrema(t)...,0,0])
		opt_R = @sprintf("%.10g/%.10g/0/0", mima[1], mima[2])
		cmd_hist_t = deepcopy(cmd_hist)
		cmd_hist_t *= (doBH) ? ((annotHst == "") ? " -Blb" : " -BWb" * annotHst) : " -Bb --MAP_FRAME_PEN=0.001,white@100"
		doDensity ? density(t, GMTopt=cmd_hist_t, panel=(1,1), Vd=Vd) : histogram(t, R=opt_R, GMTopt=cmd_hist_t, panel=(1,1), Vd=Vd)

		# Right Histogram
		t = D[:,2]
		mima = round_wesn([extrema(t)...,0,0])
		opt_R = @sprintf("%.10g/%.10g/0/0", mima[1], mima[2])
		cmd_hist *= (doBH) ? ((annotHst == "") ? " -Blb" : " -BlS" * annotHst) : " -Bl --MAP_FRAME_PEN=0.001,white@100"
		doDensity ? density(t, horizontal=true, GMTopt=cmd_hist_t, panel=(2,2), Vd=Vd) : histogram(t, R=opt_R, horizontal=true, GMTopt=cmd_hist, panel=(2,2), Vd=Vd)

		# The scatterogram
		d[:panel] = (2,1)
		mima = round_wesn(D.ds_bbox[1:4])
		d[:R] = @sprintf("%.10g/%.10g/%.10g/%.10g", mima...)
		if (do_scatter)
			d[:marker] = ((val = find_in_dict(d, [:marker :Marker :shape])[1]) !== nothing) ? val : "p"
			common_plot_xyz("", D, "scatter", first, false, d...)
		else		#if (do_hexbin)
			d[:ml] = 0.1;
			CTRL.figsize[1] = (CTRL.figsize[1] - gap) * (1 -f)
			common_plot_xyz("", gmtbinstats(D; d2...), "scatter", first, false, d...)
		end
	subplot(endwith)
end
marginalhist!(arg1; kw...) = marginalhist(arg1; first=false, kw...)
marginalhist!(fname::String; kw...) = marginalhist(fname; first=false, kw...)
