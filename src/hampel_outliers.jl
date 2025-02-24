# The code here is taken from https://github.com/tobydriscoll/HampelOutliers.jl
# It is copied and not used directly as a dependency because we don't want to introduce another
# chain of the dependencies due to the use of the `mad` function from StatsBase.jl
# A bunch of dependencies only because of a simple single function is a too high price.

# Default function to measure spread of data. It becomes the stadard deviation for normally distributed data
mad_spread = x -> mad(x)

"""
	hampel(x; spread=mad(x), threshold=2)

Identify outliers using the Hampel criterion.

Given vector `x`, identify elements xₖ such that

```math
|xₖ - m| > t S,
```

where ``m`` is the median of the elements, the dispersion scale ``S`` is provided by the
function `spread`, and the parameter ``t`` is given by `threshold`. The return value
is a `Bool` vector.

By default, `spread` is `mad` and `threshold` is 2.
"""
hampel(x::AbstractVector; kwargs...)::Vector{Bool} = hampel_identify!(falses(size(x)), x; kwargs...)

hampel_identify(x::AbstractVector; kwargs...) = hampel_identify!(falses(size(x)), x; kwargs...)
function hampel_identify!(y::AbstractVector, x::AbstractVector; spread=mad_spread, threshold=2)::Vector{Bool}
    S = spread(x)
    m = median(x)
    for k in eachindex(x)
        y[k] = abs(x[k] - m) > threshold * S
    end
    return y
end

"""
	hampel(x, K; spread=mad, threshold=2, boundary=:truncate)

Apply a windowed Hampel filter to a time series.

Given vector `x` and half-width `K`, apply a Hampel criterion within a
sliding window of width 2K+1. The median ``m`` of the window replaces the element
``xₖ`` at the center of the window if it satisfies

```math
|xₖ - m| > t S,
```

where the dispersion scale ``S`` is provided by the function `spread` and the parameter
``t`` is given by `threshold`. The window shortens near the beginning and end of the vector
to avoid referencing fictitious elements. Larger values of ``t`` make the filter less agressive,
while ``t=0`` is the standard median filter.

For recursive filtering, see `hampel!`

The value of `boundary` determines how the filter handles the boundaries of the vector:

- `:truncate` (default): the window is shortened at the boundaries
- `:reflect`: values are reflected across the boundaries
- `:repeat`: end values are repeated as necessary

	hampel(x, weights; ...)

Apply a weighted Hampel filter to a time series.

Given vector `x` and a vector `weights` of positive intgers, before computing the criterion
each element in the window is repeated by the number of times given by its corresponding
weight. This is typically used to make the central element more influential than the others.


### CREDITS
This function is adapted from https://github.com/tobydriscoll/HampelOutliers.jl and you should
consult the original source for more details and examples. The differences with respect to original
`HampelOutliers.jl` functions is that here we created different methods for `Hampel.identify` and
`Hampel.filter` and called them collectively just ``hampel`` and let the multi-dispatch do the work.

### Example

```julia
t = (1:50) / 10; x = [1:2:40; 5t + (@. 6cos(t + 0.5(t)^2)); fill(40,20)];
x[12] = -10; x[50:52] .= -12; x[79:82] .= [-5, 50, 55, 0];
plot(x, marker=:point, mc=:blue, lc=:blue, label="Original", xlabel="k", ylabel="x_k")
scatter!(m, ms="2p", mc=:red, MarkerEdgeColor=true, label="Median filter")
scatter!(y, ms="2p", mc=:green, MarkerEdgeColor=true, label="Hampel filter", show=true)
```
"""
hampel(x, K::Integer; kwargs...) = hampel_filter(x, K; kwargs...)
hampel(x::AbstractVector, weights::Vector{<:Integer}; kwargs...) = hampel_filter(x, weights; kwargs...)

hampel_filter(x, K::Integer; kwargs...) = hampel_filter(x, fill(1, 2K + 1); kwargs...)
hampel_filter(x::AbstractVector, weights::Vector{<:Integer}; kwargs...) = hampel_filter!(similar(x), x, weights; kwargs...)

"""
	hampel!(y, x, K; spread=mad, threshold=2)
	hampel!(y, x, weights; ...)

Apply a weighted Hampel filter in-place.

The idiom `hampel!(x, x,...)` will make the filter recursive, i.e., vector elements are
replaced as they are found, possibly affecting future results.
"""
hampel!(y::AbstractVector, x::AbstractVector, K::Integer; kwargs...) = hampel_filter!(y, x, K; kwargs...)
hampel!(y::AbstractVector, x::AbstractVector, weights::Vector{<:Integer}; spread=mad_spread, threshold=2, boundary=:truncate) =
    hampel_filter!(y, x, weights; spread=spread, threshold=threshold, boundary=boundary)

hampel_filter!(y::AbstractVector, x::AbstractVector, K::Integer; kwargs...) = hampel_filter!(y, x, fill(1, 2K + 1); kwargs...)
function hampel_filter!(y::AbstractVector, x::AbstractVector, weights::Vector{<:Integer}; spread=mad_spread, threshold=2, boundary=:truncate)
    KK1 = length(weights)
    @assert isodd(KK1) "Must specify an odd number of weights"
    K = (KK1 - 1) ÷ 2  # filter half-width

    x_idx = collect(eachindex(x))
    y_idx = collect(eachindex(y))
    N = length(x)

    # Set up duplications as specified by the weights.
    idx = vcat([fill(i, m) for (i, m) in zip(-K:K, weights)]...)
    inbnds = falses(length(idx))

    function valid(idx)
        map!(i -> 1 <= i <= N, inbnds, idx)
        # avoid allocating unless needed for boundary condition
        if all(inbnds)
            return idx
        elseif boundary == :truncate
            return view(idx, inbnds)
        elseif boundary == :reflect
            v = copy(idx)
            v[v .< 1] .= 2  .- v[v .< 1]
            v[v .> N] .= 2N .- v[v .> N]
            return v
        elseif boundary == :repeat
            return map(i -> max(1, min(i, N)), idx)
        else
            throw(ArgumentError("Invalid boundary condition"))
        end
    end

    for (nx, ny) in zip(x_idx, y_idx)
        @. idx += 1
        v = valid(idx)
        window = view(x, x_idx[v])
        win_med = median(window)
        S = spread(window)
        out = abs(x[nx] - win_med) > threshold * S
        y[ny] = out ? win_med : x[nx]
    end
    return y
end
