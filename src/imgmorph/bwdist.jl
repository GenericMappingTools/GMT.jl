# These functions are from the ImageMorphology.jl package, adapted here
# for use in GMT.jl without requiring the entire package as a dependency.

function bwdist(img::AbstractArray{Bool, N}; weights=nothing, nthreads=Threads.nthreads()) where {N}
    ft = feature_transform(img; weights=weights, nthreads=nthreads)
	distance_transform(ft, weights)
end
function bwdist_idx(img::AbstractArray{Bool, N}; weights=nothing, nthreads=Threads.nthreads()) where {N}
    ft = feature_transform(img; weights=weights, nthreads=nthreads)
end

bwdist(mat::AbstractArray{T, N}; weights=nothing, nthreads=Threads.nthreads()) where {T,N} =
	bwdist(mat .!= zero(T); weights=weights, nthreads=nthreads)
bwdist_idx(mat::AbstractArray{T, N}; weights=nothing, nthreads=Threads.nthreads()) where {T,N} =
	bwdist_idx(mat .!= zero(T); weights=weights, nthreads=nthreads)

struct SplitAxis <: AbstractVector{UnitRange{Int}}
	splits::Vector{Int}
end

"""
    SplitAxis(ax::AbstractUnitRange, n::Real)

Split `ax` into `ceil(Int, n)` approximately equal-sized chunks. The first chunk is no larger than any other chunk,
and any fractional "deficit" in `n` will further shrink the first chunk.

This can be useful in splitting work across threads. When the first thread is responsible for assigning work to the others,
it's often useful to assign less work to it to account for the time spent scheduling.

# Examples

```julia
julia> collect(SplitAxis(1:16, 4))
4-element Vector{UnitRange{$Int}}:
 1:4
 5:8
 9:12
 13:16
```

In the latter case all the ranges except the first have length 5; consequently, only one element remains for the first chunk.
"""
function SplitAxis(ax::AbstractUnitRange{<:Integer}, n::Real)
	step = ceil(Int, length(ax)/n)
	# Give the smallest amount of work to thread 1, since often it is also scheduling the work for all
	# the other threads.
	SplitAxis(max.(first(ax)-1, collect(reverse(range(last(ax), step=-step, length=ceil(Int, n)+1)))))
end

Base.@propagate_inbounds Base.getindex(sax::SplitAxis, i::Int) = sax.splits[i]+1:sax.splits[i+1]

Base.size(sax::SplitAxis) = (length(sax.splits)-1,)

struct SplitAxes{N} <: AbstractVector{Tuple{UnitRange{Int},Vararg{UnitRange{Int},N}}}
	inner::NTuple{N,UnitRange{Int}}
	splitax::SplitAxis
end

"""
    SplitAxes(axs::NTuple{N,AbstractUnitRange}, n::Real)

Split `axs` into `ceil(Int, n)` approximately equal-sized chunks along the final dimension represented by `axs`.

See [`SplitAxis`](@ref) for further details.

# Examples

```julia
julia> A = rand(3, 16);

julia> collect(SplitAxes(axes(A), 4))
4-element Vector{Tuple{UnitRange{$Int}, UnitRange{$Int}}}:
 (1:3, 1:4)
 (1:3, 5:8)
 (1:3, 9:12)
 (1:3, 13:16)
```
"""
SplitAxes(axs::Tuple{AbstractUnitRange,Vararg{AbstractUnitRange}}, n::Real) = SplitAxes{length(axs)-1}(Base.front(axs), SplitAxis(axs[end], n))

Base.@propagate_inbounds Base.getindex(saxs::SplitAxes, i::Int) = (saxs.inner..., saxs.splitax[i])

Base.size(saxs::SplitAxes) = size(saxs.splitax)


"""
    feature_transform(img::AbstractArray{Bool, N}; weights=nothing, nthreads=Threads.nthreads()) -> F

Compute the feature transform of a binary image `I`, finding the
closest "feature" (positions where `I` is `true`) for each location in
`I`.  Specifically, `F[i]` is a `CartesianIndex` encoding the position
closest to `i` for which `I[F[i]]` is `true`.  In cases where two or
more features in `I` have the same distance from `i`, an arbitrary
feature is chosen. If `I` has no `true` values, then all locations are
mapped to an index where each coordinate is `typemin(Int)`.

Optionally specify the weight `w` assigned to each coordinate.  For
example, if `I` corresponds to an image where voxels are anisotropic,
`w` could be the voxel spacing along each coordinate axis. The default
value of `nothing` is equivalent to `w=(1,1,...)`.

See also: [`distance_transform`](@ref).

# Citation

- [1] Maurer, Calvin R., Rensheng Qi, and Vijay Raghavan. "A linear time algorithm for
  computing exact Euclidean distance transforms of binary images in arbitrary dimensions."
  _IEEE Transactions on Pattern Analysis and Machine Intelligence_ 25.2 (2003): 265-270.
"""
function feature_transform(img::AbstractArray{Bool, N}; weights::Union{Nothing,NTuple{N}}=nothing,
                           nthreads::Int=length(img) < 1000 ? 1 : Threads.nthreads(),) where {N}
	nthreads > 0 || error("the number of threads must be positive, got $nthreads")
	N == 0 && return reshape([CartesianIndex()])
	# Allocate the output
	F = similar(img, CartesianIndex{N})
	axsimg = axes(img)
	# To allocate temporary storage for voronoift!, compute one
	# element (so we have the proper type)
	fi = first(CartesianIndices(axsimg))
	drft = DistRFT(fi, weights, (), Base.tail(fi.I))
	if nthreads == 1 || N == 1
		tmp = typeof(drft)[]
		computeft!(F, img, axsimg, CartesianIndex(), weights, tmp)
		# Finish the last dimension (for multithreading, we avoid doing it in computeft!)
		finishft!(F, img, axsimg, CartesianIndex(), weights, tmp)
	else
		tmps = [typeof(drft)[] for _ in 1:nthreads] # temporary storage (one per thread)
		saxs = SplitAxes(axsimg, nthreads - 0.2)   # give main thread less work since it also schedules the others
		tasks = [Threads.@spawn computeft!(F, img, saxs[i], CartesianIndex(), weights, tmps[i]) for i in 2:nthreads]
		computeft!(F, img, saxs[1], CartesianIndex(), weights, tmps[1])
		foreach(wait, tasks)
		# Finish the last dimension
		saxs1 = SplitAxes(axsimg[1:(N - 1)], nthreads - 0.2)
		tasks = [Threads.@spawn finishft!(F, img, (saxs1[i]..., axsimg[end]), CartesianIndex(), weights, tmps[i]) for i in 2:nthreads]
		finishft!(F, img, (saxs1[1]..., axsimg[end]), CartesianIndex(), weights, tmps[1])
		foreach(wait, tasks)
	end
	return F
end

"""
	distance_transform(F::AbstractArray{CartesianIndex}, [w=nothing]) -> D

Compute the distance transform of `F`, where each element `F[i]`
represents a "target" or "feature" location assigned to `i`.
Specifically, `D[i]` is the distance between `i` and `F[i]`.
Optionally specify the weight `w` assigned to each coordinate; the
default value of `nothing` is equivalent to `w=(1,1,...)`.

See also: [`feature_transform`](@ref).
"""
function distance_transform(F::AbstractArray{CartesianIndex{N},N}, w::Union{Nothing,NTuple{N}}=nothing) where {N}
	# To allocate the proper output type, compute the distance for one element
	R = CartesianIndices(axes(F))
	dst = wnorm2(zero(eltype(R)), w)
	D = similar(F, typeof(sqrt(dst)))

	∅ = nullindex(F)
	@inbounds for i in R
		fi = F[i]
		D[i] = fi == ∅ ? Inf : sqrt(wnorm2(fi - i, w))
	end

	return D
end

# This recursive implementation computes the feature transform, other than for finishing the
# work along the final axis (axis `N` for an `N` dimensional array).
# Omission of the final axis makes it easy to implement multithreading.
# You can finish the final axis with a call to `finishft!` with `jpost = CartesianIndex()`.
function computeft!(F, img, axsimg, jpost::CartesianIndex{K}, pixelspacing, tmp) where {K}
	# tmp is workspace for voronoift!
	∅ = nullindex(F)                             # sentinel position
	if K == ndims(img) - 1                           # innermost loop (d=1 case, line 1)
		# Fig. 2, lines 2-8
		@inbounds @simd for i1 in axes(img, 1)
			F[i1, jpost] = img[i1, jpost] ? CartesianIndex(i1, jpost) : ∅
		end
	else                                         # recursively handle trailing dimensions
		# Fig. 2, lines 10-12
		for i1 in axsimg[ndims(img) - K]
			computeft!(F, img, axsimg, CartesianIndex(i1, jpost), pixelspacing, tmp)
		end
	end
	K == 0 && return F                           # defer the final axis, where threads will be split across next-to-last axis
	return finishft!(F, img, axsimg, jpost, pixelspacing, tmp)
end

function finishft!(F, img, axsimg, jpost, pixelspacing, tmp)
	# Fig. 2, lines 14-20
	axespre = truncatet(axsimg, jpost)          # first N-K-1 axes (these are "finished" within each K+1-dimensional slice)
	for jpre in CartesianIndices(axespre)
		voronoift!(F, img, jpre, jpost, pixelspacing, tmp)     # finish axis N-K in K-dimensional slice `jpost`
	end
	return F
end

function voronoift!(F, img, jpre, jpost, pixelspacing, tmp)
	d = length(jpre) + 1   # axis to work along
	∅ = nullindex(F)
	empty!(tmp)
	for i in axes(img, d)
		# Fig 3, lines 3-13
		xi = CartesianIndex(jpre, i, jpost)
		@inbounds fi = F[xi]
		if fi != ∅
			fidist = DistRFT(fi, pixelspacing, jpre, jpost)
			if length(tmp) < 2
				push!(tmp, fidist)
			else
				@inbounds while length(tmp) >= 2 && removeft(tmp[end - 1], tmp[end], fidist)
					pop!(tmp)
				end
				push!(tmp, fidist)
			end
		end
	end
	nS = length(tmp)
	nS == 0 && return F
	# Fig 3, lines 18-24
	l = 1
	@inbounds fthis = tmp[l].fi
	for i in axes(img, d)
		xi = CartesianIndex(jpre, i, jpost)
		d2this = wnorm2(xi - fthis, pixelspacing)
		while l < nS
			@inbounds fnext = tmp[l + 1].fi
			d2next = wnorm2(xi - fnext, pixelspacing)
			if d2this > d2next
				d2this, fthis = d2next, fnext
				l += 1
			else
				break
			end
		end
		@inbounds F[xi] = fthis
	end
	return F
end

## Utilities

# Stores a feature location and its distance from the hyperplane Rd
struct DistRFT{N,T}
	fi::CartesianIndex{N}
	dist2::T
	d::Int  # the coordinate in dimension d
end

"""
	DistRFT(fi::CartesianIndex, w, jpre, jpost)

Bundles a feature `fi` together with its distance from the line Rd,
where Rd is specified by `(jpre..., :, jpost...)`. `w` is the
weighting applied to each coordinate, and must be `nothing` or be a
tuple with the same number of coordiantes as `fi`.

"""
function DistRFT(fi::CartesianIndex, w, jpre::CartesianIndex, jpost::CartesianIndex)
	d2pre, ipost, wpost = dist2pre(fi.I, w, jpre.I)
	d2post = wnorm2(CartesianIndex(ipost) - jpost, wpost)
	@inbounds fid = fi[length(jpre) + 1]
	return DistRFT(fi, d2pre + d2post, fid)
end
function DistRFT(fi::CartesianIndex, w, jpre::Tuple, jpost::Tuple)
	return DistRFT(fi, w, CartesianIndex(jpre), CartesianIndex(jpost))
end

@inline function removeft(u, v, w)
	a, b, c = v.d - u.d, w.d - v.d, w.d - u.d
	return c * v.dist2 - b * u.dist2 - a * w.dist2 > a * b * c
end

"""
	truncatet(inds, j::CartesianIndex{K})

Discard the last `K+1` elements of the tuple `inds`.
"""
truncatet(inds, j::CartesianIndex) = _truncatet((), inds, j)
_truncatet(out, inds::NTuple{N}, j::CartesianIndex{N}) where {N} = Base.front(out)
@inline _truncatet(out, inds, j) = _truncatet((out..., inds[1]), Base.tail(inds), j)

nullindex(A::AbstractArray{T,N}) where {T,N} = typemin(Int) * oneunit(CartesianIndex{N})

"""
	wnorm2(x::CartesianIndex, w)

Compute `∑ (w[i]*x[i])^2`.  Specifying `nothing` for `w` is equivalent to `w = (1,1,...)`.
"""
wnorm2(x::CartesianIndex, w) = _wnorm2(0, x.I, w)
_wnorm2(s, ::Tuple{}, ::Nothing) = s
_wnorm2(s, ::Tuple{}, ::Tuple{}) = s
@inline _wnorm2(s, x, w::Nothing) = _wnorm2(s + sqr(x[1]), Base.tail(x), w)
@inline _wnorm2(s, x, w) = _wnorm2(s + sqr(w[1] * x[1]), Base.tail(x), Base.tail(w))

"""
	dist2pre(x, w, jpre) -> s, xpost, wpost

`s` is equivalent to `wnorm2(x[1:length(jpre)]-jpre, w)`. `xpost` and
`wpost` contain the trailing indices of `x` and `w` (skipping the
element `length(jpre)+1`).
"""
dist2pre(x::Tuple, w, jpre) = _dist2pre(0, x, w, jpre)
_dist2pre(s, x, w::Nothing, ::Tuple{}) = s, Base.tail(x), w
_dist2pre(s, x, w, ::Tuple{}) = s, Base.tail(x), Base.tail(w)
@inline function _dist2pre(s, x, w::Nothing, jpre)
	return _dist2pre(s + sqr(x[1] - jpre[1]), Base.tail(x), w, Base.tail(jpre))
end
@inline function _dist2pre(s, x, w, jpre)
	return _dist2pre(s + sqr(w[1] * (x[1] - jpre[1])), Base.tail(x), Base.tail(w), Base.tail(jpre))
end

@inline sqr(x) = x * x
