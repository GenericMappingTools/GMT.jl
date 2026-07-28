# GMT's own FFT (GMT_FFT_1D / GMT_FFT_2D) and the one function built on it, kovesi (ppdrc).
# NO FFTW here on purpose: these exist precisely so that nothing Fourier in GMT.jl needs FFTW.
#
# Everything lives in a `let` block: runtests.jl includes all test files into the same Main, so
# bare assignments here would clobber other files' globals (and be clobbered by them).
#
# The DFTs below use `cis(θ) = exp(iθ)` and never name the imaginary unit. That is NOT style: an
# earlier test file leaves an `im::GMTimage` in Main, and `2im` is not an imaginary literal in
# Julia — it is numeric juxtaposition, i.e. `2 * im` — so it would silently pick up that image.

@testset "FFT" begin
	println("	FFT")
	let
		# Ground truth: the plain DFT sum. GMT computes in single precision, so compare with a
		# Float32 tolerance scaled by sqrt(N) (the magnitude a transform of unit-ish data reaches).
		dft1(x) = [sum(x[n] * cis(-2pi*(k-1)*(n-1)/length(x)) for n = 1:length(x)) for k = 1:length(x)]
		function dft2(A)
			ny, nx = size(A)
			[sum(A[i,j] * cis(-2pi*((u-1)*(i-1)/ny + (v-1)*(j-1)/nx)) for i = 1:ny, j = 1:nx)
			 for u = 1:ny, v = 1:nx]
		end

		# ---- fft1d --------------------------------------------------------------------------
		x = rand(64)
		F = fft1d(x)
		@test length(F) == 64
		@test maximum(abs.(F .- dft1(ComplexF64.(x)))) < 1e-3
		@test maximum(abs.(real(fft1d(F; inverse=true)) .- x)) < 1e-5      # round trip
		@test isempty(fft1d(ComplexF64[]))
		@test fft1d(ComplexF64.(x)) ≈ F                                    # complex input, same answer

		# A sine must land on its own bin and nowhere else.
		s = sin.(2pi .* (0:99) ./ 100 .* 5)                                # 5 cycles over 100 samples
		S = abs.(fft1d(s))
		@test argmax(S[1:50]) == 6                                         # bin 1 is DC, so 5 cycles -> 6

		# ---- fft2d --------------------------------------------------------------------------
		A = rand(16, 12)
		F2 = fft2d(A)
		@test eltype(F2) === ComplexF32                                    # GMT is single precision: never F64
		@test size(F2) == size(A)
		@test maximum(abs.(ComplexF64.(F2) .- dft2(ComplexF64.(A)))) < 1e-2
		@test maximum(abs.(real(fft2d(F2; inverse=true)) .- A)) < 1e-4     # round trip
		@test F2[1,1] ≈ ComplexF32(sum(A))                                 # no shift: DC sits at [1,1]

		# Dimensions need not be powers of two (primes included), and degenerate shapes must work.
		for (ny, nx) in ((7, 11), (13, 13), (1, 8), (8, 1), (32, 4))
			B = rand(ny, nx)
			@test maximum(abs.(ComplexF64.(fft2d(B)) .- dft2(ComplexF64.(B)))) < 1e-2
			@test maximum(abs.(real(fft2d(fft2d(B); inverse=true)) .- B)) < 1e-4
		end

		# Real and complex entry points agree.
		@test fft2d(ComplexF32.(A)) ≈ F2
		@test fft2d(ComplexF64.(A)) ≈ F2

		# ---- fft2d! -------------------------------------------------------------------------
		# GMT_FFT_2D is DESTRUCTIVE, so the two names must differ exactly there: fft2d! overwrites
		# and returns the SAME array (no copy at all), fft2d never touches its input.
		C = ComplexF32.(A)
		R = fft2d!(C)
		@test R === C
		@test C ≈ F2
		keep = ComplexF32.(A)
		fft2d(keep)
		@test keep == ComplexF32.(A)                                       # untouched by the non-bang call
		e0 = Matrix{ComplexF32}(undef, 0, 0)
		@test fft2d!(e0) === e0                                            # empty is a no-op, not an error

		# ---- kovesi (ppdrc) — the consumer, and the reason fft2d exists -----------------------
		Gk = GMT.peaks(64)
		P = kovesi(Gk, wavelength=30)
		@test isa(P, GMTgrid)
		@test size(P) == size(Gk)
		@test eltype(P.z) === Float32
		@test P.range[1:4] == Gk.range[1:4]                                # same footprint as its parent
		@test all(isfinite, P.z)
		@test extrema(P.z) != extrema(Gk.z)                                # it did something

		M = kovesi(Float32.(Gk.z))                                         # bare matrix in, matrix out
		@test isa(M, Matrix{Float32})
		@test size(M) == size(Gk.z)

		# NaN holes are filled for the transform and put back afterwards, node for node.
		z = copy(Gk.z);  z[10:20, 15:25] .= NaN32
		Gn = mat2grid(z, Gk);  Gn.hasnans = 2
		Pn = kovesi(Gn, wavelength=30)
		@test count(isnan, Pn.z) == count(isnan, z)
		@test all(isnan.(Pn.z) .== isnan.(z))                              # the SAME nodes, not just as many
		@test all(isfinite, Pn.z[.!isnan.(z)])

		@test_throws ErrorException kovesi(Gk.z, n=0)                      # Butterworth order must be >= 1
	end
end
