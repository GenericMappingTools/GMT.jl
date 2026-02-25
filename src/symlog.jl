# Written by Claude.ai

"""
    symlog(x, y; axis=:y, linthresh=1, linscale=1, base=10, kwargs...)
    symlog(D::GMTdataset; axis=:y, linthresh=1, linscale=1, base=10, kwargs...)

Plot data with a symmetric logarithmic scale, like matplotlib's symlog.
Linear in [-linthresh, linthresh], logarithmic beyond.

- `axis`: which axis to transform: `:y` (default), `:x`, or `:xy` for both
- `linthresh`: threshold below which the scale is linear (must be > 0)
- `linscale`: scale factor for the linear region
- `base`: logarithm base (default 10)
- All other kwargs are forwarded to `plot()`

### Example
```julia
x = 1:100
y = @. 10.0^(x/20) - 10.0^((101-x)/20)
symlog(x, y, linthresh=10, lw=1)
```
"""
function symlog(x::AbstractVector{<:Real}, y::AbstractVector{<:Real}; axis::Symbol=:y,
                linthresh::Real=1, linscale::Real=1, base::Real=10, first::Bool=true, kwargs...)
	d = KW(kwargs)
	lt, ls, b = Float64(linthresh), Float64(linscale), Float64(base)
	_symlog_plot(Float64.(x), Float64.(y), axis, lt, ls, b, first, d)
end

function symlog(D::GMTdataset; axis::Symbol=:y,
                linthresh::Real=1, linscale::Real=1, base::Real=10, first::Bool=true, kwargs...)
	d = KW(kwargs)
	lt, ls, b = Float64(linthresh), Float64(linscale), Float64(base)
	_symlog_plot(Float64.(view(D.data,:,1)), Float64.(view(D.data,:,2)), axis, lt, ls, b, first, d)
end

function symlog(D::Vector{<:GMTdataset}; axis::Symbol=:y,
                linthresh::Real=1, linscale::Real=1, base::Real=10, first::Bool=true, kwargs...)
	d = KW(kwargs)
	lt, ls, b = Float64(linthresh), Float64(linscale), Float64(base)
	# Transform each dataset and plot; first one creates, rest overlay
	for (i, Di) in enumerate(D)
		xx, yy = Float64.(view(Di.data,:,1)), Float64.(view(Di.data,:,2))
		_symlog_plot(xx, yy, axis, lt, ls, b, i == 1 && first, d)
		(i == 1) && (d = Dict{Symbol,Any}())		# Only pass user opts on first call
	end
end

function _symlog_plot(x::Vector{Float64}, y::Vector{Float64}, axis::Symbol,
                      lt::Float64, ls::Float64, b::Float64, first::Bool, d::Dict)

	# Transform the data
	xt = (axis == :x || axis == :xy) ? [_symlog(v, lt, ls, b) for v in x] : x
	yt = (axis == :y || axis == :xy) ? [_symlog(v, lt, ls, b) for v in y] : y

	# Build custom tick annotations for the transformed axis/axes
	if (axis == :y || axis == :xy)
		tpos, tlab = _symlog_ticks(y, lt, ls, b)
		typ = ["a " * l for l in tlab]
		d[:yaxis] = (custom = (pos=tpos, type=typ),)
	end
	if (axis == :x || axis == :xy)
		tpos, tlab = _symlog_ticks(x, lt, ls, b)
		typ = ["a " * l for l in tlab]
		d[:xaxis] = (custom = (pos=tpos, type=typ),)
	end

	# Ensure the non-transformed axis gets default annotations
	if (axis == :y && !haskey(d, :xaxis) && !haskey(d, :frame) && !haskey(d, :B))
		d[:xaxis] = (annot=:auto,)
	elseif (axis == :x && !haskey(d, :yaxis) && !haskey(d, :frame) && !haskey(d, :B))
		d[:yaxis] = (annot=:auto,)
	end

	plot(mat2ds(hcat(xt, yt)); first=first, d...)
end

# ---------------------------------------------------------------------------
# Core transform (single compilation, no type specialization)
# ---------------------------------------------------------------------------
function _symlog(x::Float64, linthresh::Float64, linscale::Float64, base::Float64)::Float64
	log_base = log(base)
	linscale_adj = linscale / (1.0 - 1.0 / base)
	abs_x = abs(x)
	if abs_x <= linthresh
		return x * linscale_adj / linthresh
	else
		return sign(x) * (linscale_adj + linscale * log(abs_x / linthresh) / log_base)
	end
end

"""
    isymlog(y; linthresh=1, linscale=1, base=10)

Inverse of the symlog transform. Converts transformed values back to original scale.
"""
function isymlog(y::Real; linthresh::Real=1, linscale::Real=1, base::Real=10)
	_isymlog(Float64(y), Float64(linthresh), Float64(linscale), Float64(base))
end

function isymlog(v::AbstractArray{<:Real}; linthresh::Real=1, linscale::Real=1, base::Real=10)
	lt, ls, b = Float64(linthresh), Float64(linscale), Float64(base)
	[_isymlog(Float64(y), lt, ls, b) for y in v]
end

function _isymlog(y::Float64, linthresh::Float64, linscale::Float64, base::Float64)::Float64
	log_base = log(base)
	linscale_adj = linscale / (1.0 - 1.0 / base)
	if abs(y) <= linscale_adj
		return y * linthresh / linscale_adj
	else
		return sign(y) * linthresh * exp((abs(y) - linscale_adj) * log_base / linscale)
	end
end

# ---------------------------------------------------------------------------
# Tick generation — produces positions in transformed space + original-value labels
# ---------------------------------------------------------------------------
function _symlog_ticks(data::Vector{Float64}, lt::Float64, ls::Float64, b::Float64)
	vmin, vmax = extrema(data)
	ticks = Float64[]
	labels = String[]

	function add_tick!(val::Float64)
		push!(ticks, _symlog(val, lt, ls, b))
		push!(labels, _fmt_tick(val))
	end

	(vmin <= 0 <= vmax) && add_tick!(0.0)

	# +/- linthresh boundaries
	(vmin <= -lt && vmax >= -lt) && add_tick!(-lt)
	(vmax >= lt && vmin <= lt)   && add_tick!(lt)

	# Positive log ticks
	if vmax > lt
		for e in floor(Int, log(b, lt)):ceil(Int, log(b, vmax))
			val = Float64(b^e)
			(val >= lt && val <= vmax) && add_tick!(val)
		end
	end

	# Negative log ticks
	if vmin < -lt
		for e in floor(Int, log(b, lt)):ceil(Int, log(b, abs(vmin)))
			val = -Float64(b^e)
			(val <= -lt && val >= vmin) && add_tick!(val)
		end
	end

	perm = sortperm(ticks)
	return ticks[perm], labels[perm]
end

function _fmt_tick(v::Float64)::String
	if v == 0
		return "0"
	elseif abs(v) >= 1 && abs(v) == round(abs(v))
		return string(Int(v))
	else
		return @sprintf("%.4g", v)
	end
end
