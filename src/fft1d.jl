"""
    F = fft1d(x::AbstractVector; inverse=false) -> Vector{ComplexF64}

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
fft1d(x::AbstractVector{<:Real}; inverse::Bool=false) = fft1d(ComplexF32.(x); inverse=inverse)

function fft1d(x::AbstractVector{<:Complex}; inverse::Bool=false)
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
