"""
    F = fft1d(x::Vector; inverse=false) -> Vector{ComplexF64}

One-dimensional **F**ast **F**ourier **T**ransform of the vector `x`, computed by GMT's own C
library (`GMT_FFT_1D`). `x` may be real or complex; the result is always `ComplexF64` with the same
length. Pass `inverse=true` for the inverse transform (GMT normalises the inverse by `1/length(x)`,
so `fft1d(fft1d(x); inverse=true) ≈ x`). The length need NOT be a power of two — GMT selects the
FFT kernel. Note that GMT works in single precision, so expect round-off near `1e-6`.

### Example
```julia
F = fft1d(sin.(2π .* (0:99) ./ 100));   # forward transform
y = real(fft1d(F; inverse=true));       # back to the (real) signal
```
"""
fft1d(x::Vector{<:Real}; inverse::Bool=false) = fft1d(ComplexF32.(x); inverse=inverse)

function fft1d(x::Vector{<:Complex}; inverse::Bool=false)
	N = length(x)
	N == 0 && return ComplexF64[]
	buf = Vector{Float32}(undef, 2N)               # GMT wants interleaved single-precision (re, im)
	@inbounds for i = 1:N
		buf[2i-1] = Float32(real(x[i]));  buf[2i] = Float32(imag(x[i]))
	end
	dir  = inverse ? Cint(1) : Cint(0)             # GMT_FFT_INV : GMT_FFT_FWD
	stat = GC.@preserve buf GMT_FFT_1D(G_API[], pointer(buf), N, dir, UInt32(0))  # mode 0 = GMT_FFT_COMPLEX
	(stat == 0) || error("fft1d: GMT_FFT_1D returned status $stat")
	return ComplexF64[ComplexF64(buf[2i-1], buf[2i]) for i = 1:N]
end

"""
    F = fft2d(A::Matrix; inverse=false) -> Matrix{ComplexF32}

Two-dimensional **F**ast **F**ourier **T**ransform of the matrix `A`, computed by GMT's own C
library (`GMT_FFT_2D`). `A` may be real or complex; the result is always `ComplexF32` of the same
size — GMT is a single-precision library, so a `ComplexF64` result would only be inflated zeros.
Pass `inverse=true` for the inverse transform (GMT normalises it by `1/length(A)`, so
`fft2d(fft2d(A); inverse=true) ≈ A`). Dimensions need NOT be powers of two, but the transform is
much faster on "good" sizes (products of small primes). Same output convention as `fft1d`: no
shift applied, the zero frequency sits at `F[1,1]`. Expect round-off near `1e-6` relative.

Use this instead of pulling in FFTW.jl — everything Fourier in GMT.jl goes through the GMT library.

See `fft2d!` for the in-place form, which transforms with NO copy at all.

### Example
```julia
F = fft2d(GMT.peaks(64).z);          # forward transform
A = real(fft2d(F; inverse=true));    # back to the (real) matrix
```
"""
fft2d(A::Matrix{<:Real};    inverse::Bool=false) = fft2d!(ComplexF32.(A); inverse=inverse)
fft2d(A::Matrix{<:Complex}; inverse::Bool=false) = fft2d!(ComplexF32.(A); inverse=inverse)
# The `copy` here is NOT a conversion — ComplexF32 is already GMT's exact layout. GMT_FFT_2D is
# DESTRUCTIVE (it overwrites the buffer), so the non-bang name has to hand it a copy or it would
# trash the caller's matrix. Don't need the input afterwards? Call fft2d! and nothing is copied.
fft2d(A::Matrix{ComplexF32};        inverse::Bool=false) = fft2d!(copy(A);        inverse=inverse)

"""
    fft2d!(A::Matrix{ComplexF32}; inverse=false) -> A

In-place `fft2d`: `A` is overwritten with its transform and returned. NO buffer, NO copy — a
`Matrix{ComplexF32}` is already interleaved (re, im) single-precision pairs, which is byte-for-byte
the layout `GMT_FFT_2D` reads and writes, so the C call works straight on Julia's own memory.

Use it whenever the input is dead after the transform (the usual case in a filter chain: forward,
multiply by a filter, inverse). Every `fft2d` method above is just a copy followed by this.
"""
function fft2d!(A::Matrix{ComplexF32}; inverse::Bool=false)
	ny, nx = size(A)                               # Julia is column-major: the FIRST dim varies fastest,
	(ny * nx == 0) && return A                     # which is exactly what GMT_FFT_2D calls its "nx"
	dir  = inverse ? Cint(1) : Cint(0)             # GMT_FFT_INV : GMT_FFT_FWD
	stat = GC.@preserve A GMT_FFT_2D(G_API[], Ptr{Cfloat}(pointer(A)), UInt32(ny), UInt32(nx), dir, UInt32(0))
	(stat == 0) || error("fft2d!: GMT_FFT_2D returned status $stat")
	return A
end
