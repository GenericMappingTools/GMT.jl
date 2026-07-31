# Hellinger rotation solver for tectonic plate reconstruction
# Converted from MATLAB/Fortran by J. Luis
#
# Original: "On reconstructing tectonic plate motion from ship track crossings"
# Simplified September 9, 2000, July 2001
# The original fortran code had no License; this translation is released to the Public Domain.
# Copyright (c) 2004-2017 by J. Luis

# ========================================================================================
# QUATERNION AND COORDINATE TRANSFORMS
# ========================================================================================

"""
    trans1(ulat, ulong) -> (x, y, z)

Convert geographic latitude/longitude (degrees) to Cartesian unit-sphere coordinates.
"""
function trans1(ulat, ulong)
	D2R = π / 180
	la = ulat .* D2R
	lo = ulong .* D2R
	z = sin.(la)
	x = cos.(la) .* cos.(lo)
	y = cos.(la) .* sin.(lo)
	return x, y, z
end

"""
    trans3(alat, along, rho) -> Vector{Float64}(4)

Convert Euler pole (lat, lon in degrees) and rotation angle (degrees) to a quaternion.
"""
function trans3(alat, along, rho)
	D2R = π / 180
	qhat = zeros(4)
	qhat[1] = cos(rho * D2R / 2)
	fact = sin(rho * D2R / 2)
	qhat[4] = fact * sin(alat * D2R)
	fact *= cos(alat * D2R)
	qhat[2] = fact * cos(along * D2R)
	qhat[3] = fact * sin(along * D2R)
	return qhat
end

"""
    trans2(x, ahat) -> Vector{Float64}(4)

Compute xhat = ahat * exp(x), where ahat and xhat are quaternions and x is a 3-vector.
"""
function trans2(x, ahat)
	theta = sqrt(x[1]^2 + x[2]^2 + x[3]^2)
	theta <= 0 && return ahat[1:4]
	expx = zeros(4)
	expx[1] = cos(theta / 2)
	fact = sin(theta / 2) / theta
	expx[2:4] = fact .* x[1:3]
	return qmult(ahat, expx)
end

"""
    trans4(qhat) -> Matrix{Float64}(3,3)

Convert a quaternion to a 3x3 rotation matrix.
"""
function trans4(qhat)
	A0, A1, A2, A3 = qhat[1], qhat[2], qhat[3], qhat[4]
	amhat = zeros(3, 3)
	amhat[1,1] = A0*A0 + A1*A1 - A2*A2 - A3*A3
	amhat[2,1] = 2(A0*A3 + A1*A2)
	amhat[3,1] = 2(A1*A3 - A0*A2)
	amhat[1,2] = 2(A1*A2 - A0*A3)
	amhat[2,2] = A0*A0 - A1*A1 + A2*A2 - A3*A3
	amhat[3,2] = 2(A0*A1 + A2*A3)
	amhat[1,3] = 2(A0*A2 + A1*A3)
	amhat[2,3] = 2(A2*A3 - A0*A1)
	amhat[3,3] = A0*A0 - A1*A1 - A2*A2 + A3*A3
	return amhat
end

"""
    trans5(qhat) -> (alat, along, rho)

Convert a quaternion to Euler pole latitude, longitude and rotation angle (all in degrees).
"""
function trans5(qhat)
	R2D = 180 / π
	tmp = clamp(qhat[1], -1.0, 1.0)
	fact = acos(tmp)
	rho = fact * 2 * R2D
	tmp = clamp(qhat[4] / sin(fact), -1.0, 1.0)
	alat  = asin(tmp) * R2D
	along = atan(qhat[3], qhat[2]) * R2D
	return alat, along, rho
end

"""
    trans6(U) -> (ulat, ulong)

Convert Cartesian unit-sphere coordinates to geographic latitude/longitude (degrees).
"""
function trans6(U)
	R2D = 180 / π
	tmp = clamp(U[3], -1.0, 1.0)
	ulat = asin(tmp) * R2D
	ulong = (U[1]^2 + U[2]^2 <= 0) ? 0.0 : atan(U[2], U[1]) * R2D
	return ulat, ulong
end

"""
    qmult(A, B) -> Vector{Float64}(4)

Quaternion multiplication C = A * B.
"""
function qmult(A, B)
	C = zeros(4)
	C[1] = A[1]*B[1] - A[2]*B[2] - A[3]*B[3] - A[4]*B[4]
	C[2] = A[1]*B[2] + A[2]*B[1] + A[3]*B[4] - A[4]*B[3]
	C[3] = A[1]*B[3] + A[3]*B[1] + A[4]*B[2] - A[2]*B[4]
	C[4] = A[1]*B[4] + A[4]*B[1] + A[2]*B[3] - A[3]*B[2]
	return C
end

# ========================================================================================
# SPECIAL FUNCTIONS (from Numerical Recipes)
# ========================================================================================

"""
    gammln(xx) -> Float64

Logarithm of the gamma function, ln(Γ(xx)).
"""
function gammln(xx::Real)
	COF = [76.18009173, -86.50532033, 24.01409822, -1.231739516, 0.120858003e-2, -0.536382e-5]
	STP = 2.50662827465
	xx == 1 && return 0.0
	x = abs(xx - 1.0)
	z = x
	tmp = x + 5.5
	tmp = (x + 0.5) * log(tmp) - tmp
	ser = 1.0
	xv = x
	for j in 1:6
		xv += 1.0
		ser += COF[j] / xv
	end
	dgamm = tmp + log(STP * ser)
	return xx > 1 ? dgamm : log(π * z / sin(π * z)) - dgamm
end

"""
    gser(a, x) -> (gamser, ier)

Incomplete gamma function P(a,x) using series representation.
"""
function gser(a::Real, x::Real)
	ITMAX = 100;  eps_ = 3e-7
	gln = gammln(a)
	x <= 0 && return (x < 0 ? (0.0, 100) : (0.0, 0))
	ap = a
	som = 1.0 / a
	del = som
	ier = 101
	for _ in 1:ITMAX
		ap += 1.0
		del *= x / ap
		som += del
		if abs(del) < abs(som) * eps_
			ier = 0
			break
		end
	end
	return som * exp(-x + a * log(x) - gln), ier
end

"""
    gcf(a, x) -> (gammcf, ier)

Incomplete gamma function Q(a,x) = 1-P(a,x) using continued fraction.
"""
function gcf(a::Real, x::Real)
	ITMAX = 100;  eps_ = 3e-7
	gln = gammln(a)
	gold = 0.0
	a0 = 1.0;  a1 = x;  b0 = 0.0;  b1 = 1.0;  fac = 1.0
	g = 0.0
	for n in 1:ITMAX
		an = Float64(n)
		ana = an - a
		a0 = (a1 + a0 * ana) * fac
		b0 = (b1 + b0 * ana) * fac
		anf = an * fac
		a1 = x * a0 + anf * a1
		b1 = x * b0 + anf * b1
		if a1 != 0
			fac = 1.0 / a1
			g = b1 * fac
			abs((g - gold) / g) < eps_ && break
			gold = g
		end
	end
	return exp(-x + a * log(x) - gln) * g, 0
end

"""
    gammp(a, x) -> (val, ier)

Incomplete gamma function P(a,x).
"""
function gammp(a::Real, x::Real)
	(x < 0 || a <= 0) && return (0.0, 100)
	if x < a + 1
		return gser(a, x)
	else
		val, ier = gcf(a, x)
		return 1.0 - val, ier
	end
end

"""
    erf0(x) -> (val, ier)

Error function erf(x) via incomplete gamma function.
"""
function erf0(x::Real)
	val, ier = gammp(0.5, x^2)
	return (x < 0 ? -val : val), ier
end

"""
    betacf(a, b, x) -> (val, ier)

Continued fraction evaluation for incomplete beta function.
"""
function betacf(a::Real, b::Real, x::Real)
	ITMAX = 100;  eps_ = 3e-7
	am = 1.0;  bm = 1.0;  az = 1.0
	qab = a + b;  qap = a + 1;  qam = a - 1
	bz = 1.0 - qab * x / qap
	for m in 1:ITMAX
		em = Float64(m)
		tem = em + em
		d = em * (b - m) * x / ((qam + tem) * (a + tem))
		ap = az + d * am
		bp = bz + d * bm
		d = -(a + em) * (qab + em) * x / ((a + tem) * (qap + tem))
		app = ap + d * az
		bpp = bp + d * bz
		am = ap / bpp
		bm = bp / bpp
		az_new = app / bpp
		abs(az_new - az) < eps_ * abs(az_new) && return az_new, 0
		az = az_new
		bz = 1.0
	end
	return az, 106
end

"""
    betai(a, b, x) -> (val, ier)

Incomplete beta function Iₓ(a,b).
"""
function betai(a::Real, b::Real, x::Real)
	x <= 0 && return (x < 0 ? (0.0, 105) : (0.0, 0))
	x >= 1 && return (x > 1 ? (1.0, 105) : (1.0, 0))
	bt = exp(gammln(a + b) - gammln(a) - gammln(b) + a * log(x) + b * log(1 - x))
	if x < (a + 1) / (a + b + 2)
		val, ier = betacf(a, b, x)
		return bt * val / a, ier
	else
		val, ier = betacf(b, a, 1.0 - x)
		return 1.0 - bt * val / b, ier
	end
end

# ========================================================================================
# PROBABILITY DISTRIBUTION FUNCTIONS
# ========================================================================================

"""
    xdf(d, xf) -> Float64

F-distribution CDF: P(F <= xf) with degrees of freedom d = [d1, d2].
"""
function xdf(d, xf)
	x = d[2] / (d[2] + d[1] * xf)
	val, _ = betai(d[2] / 2, d[1] / 2, x)
	return 1.0 - val
end

"""
    xdn(xn) -> Float64

Standard normal CDF: P(Z <= xn).
"""
function xdn(xn)
	x = xn / 1.4142136
	val, _ = erf0(x)
	return 0.5 + 0.5 * val
end

"""
    xdch(df, xchi) -> Float64

Chi-squared CDF: P(χ² <= xchi) with df degrees of freedom.
"""
function xdch(df, xchi)
	val, _ = gammp(df / 2, xchi / 2)
	return val
end

"""
    x2tab(pc, idf) -> Float64

Chi-squared table lookup for small integer df (1-22) and standard percentiles.
"""
function x2tab(pc::Real, idf::Int)
	CENT = [0.5, 0.7, 0.9, 0.95, 0.99]
	TABLE = [0.455 1.074 2.706 3.841 6.635;
	         1.386 2.408 4.605 5.991 9.21;
	         2.366 3.665 6.251 7.815 11.341;
	         3.357 4.878 7.779 9.488 13.277;
	         4.351 6.064 9.236 11.07 15.086;
	         5.348 7.231 10.645 12.592 16.812;
	         6.346 8.383 12.017 14.067 18.475;
	         7.344 9.524 13.362 15.507 20.09;
	         8.343 10.656 14.684 16.919 21.666;
	         9.342 11.781 15.987 18.307 23.209;
	         10.341 12.899 17.275 19.675 24.725;
	         11.34 14.011 18.549 21.026 26.217;
	         12.34 15.119 19.812 22.362 27.688;
	         13.339 16.222 21.064 23.685 29.141;
	         14.339 17.322 22.307 24.996 30.578;
	         15.338 18.418 23.542 26.296 32.0;
	         16.338 19.511 24.769 27.587 33.409;
	         17.338 20.601 25.989 28.869 34.805;
	         18.338 21.689 27.204 30.144 36.191;
	         19.337 22.775 28.412 31.41 37.566;
	         20.337 23.858 29.615 32.671 38.932;
	         21.337 24.939 30.813 33.924 40.289]
	j = findfirst(c -> abs(c - pc) < 0.0005, CENT)
	j === nothing && error("x2tab: pc=$pc not in table")
	return TABLE[idf, j]
end

# ========================================================================================
# ROOT FINDING AND INVERSE DISTRIBUTIONS
# ========================================================================================

"""
    zbrent(func, fval, dummy, x1, x2, tol) -> (zbr, ner)

Brent's method for root finding: find x such that func(dummy, x) = fval.
Modified from Press et al., Numerical Recipes.
"""
function zbrent(func::Function, fval, dummy, x1, x2, tol)
	ITMAX = 100;  eps_ = 3e-8
	a = x1;  b = x2;  ner = 0
	fa = func(dummy, a) - fval
	fb = func(dummy, b) - fval
	if fb * fa > 0
		return 0.0, -(ner + 1)
	end
	fc = fb;  c = b;  d = b - a;  e = d
	for _ in 1:ITMAX
		if fb * fc > 0
			c = a;  fc = fa;  d = b - a;  e = d
		end
		if abs(fc) < abs(fb)
			a = b;  b = c;  c = a;  fa = fb;  fb = fc;  fc = fa
		end
		tol1 = 2 * eps_ * abs(b) + 0.5 * tol
		xm = 0.5 * (c - b)
		(abs(xm) <= tol1 || fb == 0) && return b, ner
		if abs(e) >= tol1 && abs(fa) > abs(fb)
			s = fb / fa
			if a == c
				p = 2 * xm * s
				q = 1 - s
			else
				q = fa / fc
				r = fb / fc
				p = s * (2 * xm * q * (q - r) - (b - a) * (r - 1))
				q = (q - 1) * (r - 1) * (s - 1)
			end
			p > 0 && (q = -q)
			p = abs(p)
			if 2p < min(3 * xm * q - abs(tol1 * q), abs(e * q))
				e = d
				d = p / q
			else
				d = xm;  e = d
			end
		else
			d = xm;  e = d
		end
		a = b;  fa = fb
		if abs(d) > tol1
			b += d
		else
			b += xm >= 0 ? abs(tol1) : -abs(tol1)
		end
		fb = func(dummy, b) - fval
	end
	return b, -1000 * ner
end

"""
    xidn(plev) -> (xn, ier)

Inverse standard normal distribution: find xn such that P(Z <= xn) = plev.
"""
function xidn(plev::Real)
	TOL = 0.0001
	P = [0.5, 0.6, 0.7, 0.8, 0.85, 0.9, 0.95, 0.975, 0.9875, 0.99, 0.995, 0.9975, 0.999, 0.9995]
	TABLE = [0.0, 0.253, 0.524, 0.842, 1.036, 1.282, 1.645, 1.960, 2.240, 2.326, 2.576, 2.807, 3.090, 3.291]

	qlev = 0.5 + abs(plev - 0.5)
	xn = TABLE[end]
	ier = 111111
	for i in 1:14
		if abs(qlev - P[i]) < 0.00049
			xn = TABLE[i];  ier = 0;  break
		end
		if qlev < P[i]
			xn, _ = zbrent((_,v) -> xdn(v), qlev, 0.0, TABLE[i-1], TABLE[i], TOL)
			ier = 0;  break
		end
	end
	plev < 0.5 && (xn = -xn)
	return xn, ier
end

"""
    xidch(plev, df) -> (xchi, ier)

Inverse chi-squared distribution: find xchi such that P(χ² <= xchi | df) = plev.
"""
function xidch(plev::Real, df::Real)
	TOL = 0.0001
	P = [0.5, 0.7, 0.9, 0.95, 0.99]
	ier = 0
	if df <= 0
		return 0.0, 111111
	end

	idf = round(Int, df)
	if abs(idf - df) < 0.001 && idf <= 22
		for i in 1:5
			if abs(plev - P[i]) < 0.00049
				return x2tab(plev, idf), 0
			end
			if i > 1 && plev > P[i-1] && plev < P[i]
				a = x2tab(P[i-1], idf)
				b = x2tab(P[i], idf)
				xchi, _ = zbrent((_,v) -> xdch(df, v), plev, df, a, b, TOL)
				return xchi, 0
			end
		end
	end

	b_xn, ier2 = xidn(plev)
	b = df + sqrt(2 * df) * b_xn
	ier2 != 0 && (b = df)
	b = max(1.0, b)
	a = b
	pa = xdch(df, a)
	while pa >= plev
		a *= 0.9
		pa = xdch(df, a)
	end
	pb = xdch(df, b)
	while pb <= plev
		b *= 1.1
		pb = xdch(df, b)
	end
	xchi, _ = zbrent((_,v) -> xdch(df, v), plev, df, a, b, TOL)
	return xchi, 0
end

"""
    xidf(plev, d1, d2) -> (xf, ier)

Inverse F-distribution: find xf such that P(F <= xf | d1, d2) = plev.
"""
function xidf(plev::Real, d1::Real, d2::Real)
	TOL = 0.0001
	d = [d1, d2]
	(plev <= 0 || plev >= 1 || d1 <= 0 || d2 <= 0) && return 1.0, 111111
	xf, ier = xidch(plev, d1)
	a = xf
	pa = xdf(d, a)
	while pa >= plev
		a /= 2
		pa = xdf(d, a)
	end
	b = xf
	pb = xdf(d, b)
	while pb <= plev
		b *= 2
		pb = xdf(d, b)
	end
	xf, _ = zbrent((_,v) -> xdf(d, v), plev, d, a, b, TOL)
	return xf, 0
end

# ========================================================================================
# OPTIMIZATION: OBJECTIVE FUNCTION AND NELDER-MEAD SIMPLEX
# ========================================================================================

"""
    r1(h, sigma, qhati, nsect, eta, etai) -> (r, eta, etai)

Compute the Hellinger misfit objective function. `sigma` is a 4D array (2, nsect, 3, 3),
`h` is a 3-vector perturbation, `qhati` is the current quaternion estimate.
Returns the misfit `r`, plus updated `eta` and `etai` arrays.
"""
function r1(h, sigma, qhati, nsect, eta, etai)
	qhat = trans2(h, qhati)
	ahat = trans4(qhat)
	r = 0.0
	sig = zeros(3, 3)

	for i in 1:nsect
		for j in 1:3, k in 1:3
			sig[j,k] = sigma[1, i, j, k]
			for k1 in 1:3, k2 in 1:3
				sig[j,k] += ahat[k1,j] * sigma[2, i, k1, k2] * ahat[k2,k]
			end
		end

		F = eigen(sig)
		idx = sortperm(real.(F.values))
		D = real.(F.values[idx])
		V = real.(F.vectors[:, idx])

		eta[i,1,1] = 0;       eta[i,2,1] = V[3,1];   eta[i,3,1] = -V[2,1]
		eta[i,1,2] = -V[3,1]; eta[i,2,2] = 0;         eta[i,3,2] = V[1,1]
		eta[i,1,3] = V[2,1];  eta[i,2,3] = -V[1,1];   eta[i,3,3] = 0

		if abs(V[3,1]) > 0.2
			etai[i,:,1] = eta[i,:,1]
			etai[i,:,2] = eta[i,:,2]
		elseif abs(V[1,1]) > 0.2
			etai[i,:,1] = eta[i,:,2]
			etai[i,:,2] = eta[i,:,3]
		else
			etai[i,:,1] = eta[i,:,1]
			etai[i,:,2] = eta[i,:,3]
		end
		r += D[1]
	end
	return r, eta, etai
end

"""
    grds(eps_, sigma, qhati, nsect) -> (qhati, eps_, rmin)

Grid search over rotations within eps_ of the initial quaternion estimate.
"""
function grds(eps_::Real, sigma, qhati, nsect)
	rmin = 1.1e30
	eps5 = eps_ / 5
	imin = jmin = kmin = 0
	eta  = zeros(nsect, 3, 3)
	etai = zeros(nsect, 3, 2)
	for i in -5:5, j in -5:5, k in -5:5
		h = [i, j, k] .* eps5
		rv, _, _ = r1(h, sigma, qhati, nsect, eta, etai)
		if rv < rmin
			imin = i;  jmin = j;  kmin = k;  rmin = rv
		end
	end
	h = [imin, jmin, kmin] .* eps5
	return trans2(h, qhati), eps5, rmin
end

"""
    amoeba(P, Y, ndim, ftol, maxiter, funk, args...) -> (P, Y, eta, etai)

Downhill simplex (Nelder-Mead) minimization.
Modified from Press et al., Numerical Recipes.

- `P`: ndim x (ndim+1) matrix of simplex vertices
- `Y`: (ndim+1) vector of function values
- `funk(h, args...)`: objective function returning (val, eta, etai)
"""
function amoeba(P, Y, ndim, ftol, maxiter, funk, args...)
	ALPHA = 1.0;  BETA = 0.5;  GAMMA = 2.0
	mpts = ndim + 1
	work = zeros(ndim, 3)

	# Extract eta, etai from initial evaluations
	eta = etai = nothing
	for i in 1:mpts
		Y[i], eta, etai = funk(P[:, i], args...)
	end

	iter = 0
	while true
		ilo = 1
		ihi, inhi = Y[1] > Y[2] ? (1, 2) : (2, 1)

		for i in 1:mpts
			Y[i] < Y[ilo] && (ilo = i)
			if Y[i] > Y[ihi]
				inhi = ihi;  ihi = i
			elseif Y[i] > Y[inhi] && i != ihi
				inhi = i
			end
		end

		rtol = 2 * abs(Y[ihi] - Y[ilo]) / (abs(Y[ihi]) + abs(Y[ilo]) + 1e-30)
		if rtol < ftol || iter >= maxiter
			if ilo != 1
				P[:, 1], P[:, ilo] = P[:, ilo], P[:, 1]
				Y[1], Y[ilo] = Y[ilo], Y[1]
			end
			return P, Y, eta, etai
		end

		iter += 1
		work[:, 1] .= 0
		for i in 1:mpts
			i != ihi && (work[:, 1] .+= P[:, i])
		end
		work[:, 1] ./= ndim

		# Reflection
		work[:, 2] = (1 + ALPHA) .* work[:, 1] .- ALPHA .* P[:, ihi]
		ypr, eta, etai = funk(work[:, 2], args...)

		if ypr <= Y[ilo]
			# Expansion
			work[:, 3] = GAMMA .* work[:, 2] .+ (1 - GAMMA) .* work[:, 1]
			yprr, eta, etai = funk(work[:, 3], args...)
			if yprr < Y[ilo]
				P[:, ihi] = work[:, 3];  Y[ihi] = yprr
			else
				P[:, ihi] = work[:, 2];  Y[ihi] = ypr
			end
		elseif ypr >= Y[inhi]
			if ypr < Y[ihi]
				P[:, ihi] = work[:, 2];  Y[ihi] = ypr
			end
			# Contraction
			work[:, 3] = BETA .* P[:, ihi] .+ (1 - BETA) .* work[:, 1]
			yprr, eta, etai = funk(work[:, 3], args...)
			if yprr < Y[ihi]
				P[:, ihi] = work[:, 3];  Y[ihi] = yprr
			else
				# Shrink
				for i in 1:mpts
					if i != ilo
						work[:, 2] = 0.5 .* (P[:, i] .+ P[:, ilo])
						P[:, i] = work[:, 2]
						Y[i], eta, etai = funk(work[:, 2], args...)
					end
				end
			end
		else
			P[:, ihi] = work[:, 2];  Y[ihi] = ypr
		end
	end
end

# ========================================================================================
# UTILITY FUNCTIONS
# ========================================================================================

"""
    classical_hellinger_order(flags_w, isow, flags_e, isoe) -> Matrix{Float64}

Merge two isochrons and their segment flags into a single array ordered by segment number.
Returns (lon, lat) pairs interleaved by segment.
"""
function classical_hellinger_order(flags_w::Vector{Int}, isow::Matrix{Float64},
                                   flags_e::Vector{Int}, isoe::Matrix{Float64})
	max_seg = max(flags_w[end], flags_e[end])
	mixed = zeros(length(flags_w) + length(flags_e), 2)
	off = 0
	for k in 1:max_seg
		ind_w = findall(flags_w .== k)
		n_w = length(ind_w)
		if n_w > 0
			mixed[off+1:off+n_w, :] = isow[ind_w, :]
			off += n_w
		end
		ind_e = findall(flags_e .== k)
		n_e = length(ind_e)
		if n_e > 0
			mixed[off+1:off+n_e, :] = isoe[ind_e, :]
			off += n_e
		end
	end
	return mixed[1:off, :]
end

# ========================================================================================
# MAIN DRIVER
# ========================================================================================

"""
    hellinger(along, alat, rho, isoc_mov, isoc_fix; flags_mov, flags_fix,
              std_invented=4.0, plev=0.95, do_geodetic=true) -> HellingerResult

Hellinger rotation fitting for tectonic plate reconstruction.

Estimates the best-fit Euler rotation to rotate `isoc_mov` (moving plate isochron) onto
`isoc_fix` (fixed plate isochron) using the Hellinger criterion.

### Arguments
- `along, alat, rho`: Initial guess for Euler pole (longitude, latitude, angle in degrees)
- `isoc_mov`: Nx2 matrix [lon lat] of moving plate crossing points
- `isoc_fix`: Mx2 matrix [lon lat] of fixed plate crossing points

### Keywords
- `flags_mov::Vector{Int}`: Segment indices for each point in isoc_mov
- `flags_fix::Vector{Int}`: Segment indices for each point in isoc_fix
- `sig_mov::Vector{Float64}`: Per-point errors (km) for moving plate (default: std_invented)
- `sig_fix::Vector{Float64}`: Per-point errors (km) for fixed plate (default: std_invented)
- `std_invented::Float64`: Default error if sig_mov/sig_fix not given (default: 4.0 km)
- `plev::Float64`: Confidence level (default: 0.95)
- `do_geodetic::Bool`: Convert to geocentric coords (default: true)

### Returns
Named tuple with fields:
- `along, alat, rho`: Fitted Euler pole and angle (degrees)
- `covariance`: 3x3 covariance matrix of the rotation
- `hatkap`: Estimated kappa
- `df`: Degrees of freedom
- `rmin`: Misfit
- `ndata, nsect`: Number of data points and sections
- `xchi`: Critical chi-squared value

Note: This requires the external function `bingham()` for confidence ellipse computation.
"""
function hellinger(along::Real, alat::Real, rho::Real, isoc_mov::Matrix{Float64}, isoc_fix::Matrix{Float64};
                   flags_mov::Vector{Int}=Int[], flags_fix::Vector{Int}=Int[],
                   sig_mov::Vector{Float64}=Float64[], sig_fix::Vector{Float64}=Float64[],
                   std_invented::Float64=4.0, plev::Float64=0.95, do_geodetic::Bool=true, force_pole::Bool=false)
	_hellinger(Float64(along), Float64(alat), Float64(rho), isoc_mov::Matrix{Float64}, isoc_fix,
               flags_mov, flags_fix, sig_mov, sig_fix, std_invented, plev, do_geodetic, force_pole)
end

function _hellinger(along::Float64, alat::Float64, rho::Float64, isoc_mov::Matrix{Float64}, isoc_fix::Matrix{Float64},
                    flags_mov::Vector{Int}, flags_fix::Vector{Int}, sig_mov::Vector{Float64}, sig_fix::Vector{Float64},
                    std_invented::Float64, plev::Float64, do_geodetic::Bool, force_pole::Bool)

	D2R = π / 180
	rfact = 4.0528473e7
	hlim = 1e-10
	nsig = 4
	maxfn = 1000

	# Convert to geocentric if requested
	mov = copy(isoc_mov)
	fix = copy(isoc_fix)
	if do_geodetic
		ecc = 0.0818191908426215		# WGS84
		mov_rad = mov .* D2R
		fix_rad = fix .* D2R
		mov[:, 2] = atan.(((1 - ecc^2) .* sin.(mov_rad[:, 2])), cos.(mov_rad[:, 2])) ./ D2R
		fix[:, 2] = atan.(((1 - ecc^2) .* sin.(fix_rad[:, 2])), cos.(fix_rad[:, 2])) ./ D2R
	end

	# Build the data matrix: [side, section, lat, lon, sigma]
	n_mov = size(mov, 1)
	n_fix = size(fix, 1)

	s_mov = isempty(sig_mov) ? fill(std_invented, n_mov) : sig_mov
	s_fix = isempty(sig_fix) ? fill(std_invented, n_fix) : sig_fix
	f_mov = isempty(flags_mov) ? ones(Int, n_mov) : flags_mov
	f_fix = isempty(flags_fix) ? ones(Int, n_fix) : flags_fix

	data = vcat(
		hcat(ones(n_mov), f_mov, mov[:, 2], mov[:, 1], s_mov),
		hcat(fill(2.0, n_fix), f_fix, fix[:, 2], fix[:, 1], s_fix)
	)

	ndata = size(data, 1)
	nsect = round(Int, maximum(data[:, 2]))

	sigma = zeros(2, nsect, 3, 3)
	eta  = zeros(nsect, 3, 3)
	etai = zeros(nsect, 3, 2)

	x, y, z = trans1(data[:, 3], data[:, 4])
	ax = hcat(x, y, z)
	sd = data[:, 5] .^ 2

	for k in 1:ndata
		side = round(Int, data[k, 1])
		sect = round(Int, data[k, 2])
		for j1 in 1:3, j2 in 1:3
			sigma[side, sect, j1, j2] += ax[k, j1] * ax[k, j2] / sd[k]
		end
	end

	# Initialize quaternion
	qhati = trans3(alat, along, rho)
	h = ones(3)
	_, eta, etai = r1(h, sigma, qhati, nsect, eta, etai)

	# force_pole: a zero simplex size makes the amoeba unable to move, so the fitted rotation comes
	# back as the one that went in — the "Force input = output" switch, used to get the Hellinger
	# statistics of a pole obtained some other way.
	eps_ = force_pole ? 0.0 : 10.0 * D2R

	h = zeros(3)
	rmin, eta, etai = r1(h, sigma, qhati, nsect, eta, etai)
	rmin *= rfact

	# Amoeba iterations
	hp = zeros(3, 4)
	yp = zeros(4)
	kflag = 0
	qhat = copy(qhati)
	for _ in 1:15
		for j in 1:4
			hp[:, j] .= 0
			j > 1 && (hp[j-1, j] = eps_)
			yp[j], eta, etai = r1(hp[:, j], sigma, qhati, nsect, eta, etai)
		end

		ftol = 10.0^(-(2 * nsig + 1))
		hp, yp, eta, etai = amoeba(hp, yp, 3, ftol, maxfn,
			(h_arg, sig, qi, ns, et, eti) -> r1(h_arg, sig, qi, ns, et, eti),
			sigma, qhati, nsect, eta, etai)
		rmin, eta, etai = r1(hp[:, 1], sigma, qhati, nsect, eta, etai)
		rmin *= rfact
		qhat = trans2(hp[:, 1], qhati)
		alat, along, rho = trans5(qhat)
		eps_ /= 20
		qhati[1:4] = qhat[1:4]

		kflag == 1 && break
		if abs(hp[1,1]) < hlim && abs(hp[2,1]) < hlim && abs(hp[3,1]) < hlim
			kflag += 1
		end
	end

	alat, along, rho = trans5(qhat)
	ahat = trans4(qhat)

	# Replace sigma-tilde with (ahat^T) * sigma-tilde * ahat
	for isect in 1:nsect
		temp = zeros(3, 3)
		for i in 1:3, j in 1:3
			for k1 in 1:3, k2 in 1:3
				temp[i,j] += ahat[k1,i] * sigma[2, isect, k1, k2] * ahat[k2,j]
			end
		end
		sigma[2, isect, :, :] = temp
	end

	# Build (X^T)*X matrix in symmetric packed form
	msig = 2 * nsect^2 + 7 * nsect + 6
	sigma2 = zeros(msig)
	k = 0
	for i in 1:3, j in 1:i
		k += 1
		for isect in 1:nsect
			for k1 in 1:3, k2 in 1:3
				sigma2[k] += eta[isect, i, k1] * sigma[2, isect, k1, k2] * eta[isect, j, k2]
			end
		end
	end
	for isect in 1:nsect
		for i in 1:2
			for j in 1:3
				k += 1
				for k1 in 1:3, k2 in 1:3
					sigma2[k] += etai[isect, k1, i] * sigma[2, isect, k1, k2] * eta[isect, j, k2]
				end
			end
			k += 2 * (isect - 1)
			for j in 1:i
				k += 1
				for k1 in 1:3, k2 in 1:3
					sigma2[k] += etai[isect, k1, i] * (sigma[1, isect, k1, k2] + sigma[2, isect, k1, k2]) * etai[isect, k2, j]
				end
			end
		end
	end

	ndim = 2 * nsect + 3
	sigma3 = zeros(ndim, ndim)
	k = 0
	for i in 1:ndim, j in 1:i
		k += 1
		sigma3[i, j] = sigma2[k]
		sigma3[j, i] = sigma2[k]
	end

	# Eigendecomposition for variance-covariance
	F = eigen(sigma3)
	idx = sortperm(real.(F.values))
	D_vals = real.(F.values[idx])
	V_mat  = real.(F.vectors[:, idx])
	sigma3 .= 0
	for i in 1:ndim, j in 1:ndim
		for kk in 1:ndim
			sigma3[i, j] += V_mat[i, kk] * V_mat[j, kk] / (D_vals[kk] * rfact)
		end
	end

	# Statistical tests
	df = ndata - 2 * nsect - 3
	plev1 = (1 - plev) / 2
	xchi1, _ = xidch(plev1, Float64(df))
	plev1 = 1 - plev1
	xchi_upper, _ = xidch(plev1, Float64(df))
	fkap1 = xchi_upper / rmin
	fkap2 = xchi1 / rmin
	hatkap = df / rmin
	xchi_f, _ = xidf(plev, 3.0, Float64(df))
	xchi_f = xchi_f * rmin * 3 / df

	cov = sigma3[1:3, 1:3]

	return (along=along, alat=alat, rho=rho, covariance=cov,
	        hatkap=hatkap, df=df, rmin=rmin, ndata=ndata, nsect=nsect,
	        xchi=xchi_f, fkap1=fkap1, fkap2=fkap2, plev=plev,
	        ahat_matrix=ahat, qhat=qhat)
end

# ========================================================================================
# BINGHAM CONFIDENCE REGION
# ========================================================================================
# Port of Mirone's utils/bingham.m (itself a translation of the 1988 Fortran that goes with the
# Hellinger method). It turns the 4x4 Bingham matrix of the fitted rotation into the boundary of
# the confidence region of the ROTATION AXIS, as a closed curve in longitude/latitude.
#
# NOT ported: the original's `grid` subroutine (the min/max rotation ANGLE over a lon/lat grid,
# written to Fortran units 31/32). Its only call site is commented out in the MATLAB source, so it
# has no caller here either.
#
# Two clear unit typos of that partially-finished MATLAB translation are corrected, and only those:
# the icase = 2, 3 branch multiplied radians by D2R where every sibling branch (and the printed
# min/max) uses R2D. Everything else, including the odd loop shapes, is kept as it stands.

# largin(): the largest integer <= x.
_bingham_largin(x::Real) = floor(Int, x)

"""
    bingham(q, lhat, fk, uxx) -> (blong, blat, jer)

Points on the boundary of the confidence region for the axis of a fitted rotation.

- `q`: the 4x4 Bingham matrix in symmetric (lower-triangle, row-wise) storage — 10 elements.
- `lhat`: the smallest eigenvalue of `q`.
- `fk`: the constant that sets the confidence level (`xchi` from [`hellinger`](@ref)).
- `uxx`: the optimal axis of rotation, as a Cartesian unit vector.

Returns the boundary longitudes and latitudes (degrees) and an error flag (0 = all is well).
"""
function bingham(q::Vector{Float64}, lhat::Float64, fk::Float64, uxx::Vector{Float64})
	length(q) < 10 && error("bingham: q must hold the 10 elements of a symmetric 4x4 matrix")
	# qtilde = (q - lhat*I) / fk, still in symmetric storage (1, 3, 6, 10 are the diagonal).
	qt = copy(q)
	for k in (1, 3, 6, 10);  qt[k] -= lhat;  end
	qt ./= fk
	qf = zeros(4, 4)
	k = 0
	for i in 1:4, j in 1:i
		k += 1
		qf[i, j] = qt[k];  qf[j, i] = qt[k]
	end

	azero = qf[1, 1]
	nu = zeros(3);  w = zeros(3, 3)
	icase = 7                                   # the identity is inside the region: any axis goes
	if azero > 1
		nu, w, _, icase, ier = _bingham_meig(qf, uxx)
		ier != 0 && return (Float64[], Float64[], 1)
	end
	blong, blat, ier = _bingham_boundc(azero, nu, w, icase)
	ier != 0 && return (Float64[], Float64[], 1)
	return (blong, blat, 0)
end

# meig(): eigen-decomposition of m = (azero-1)*b - dvect*dvect', and from the signs and sizes of
# its eigenvalues the TYPE of the admissible-axis set (icase 1..6).
function _bingham_meig(qf::Matrix{Float64}, uxx::Vector{Float64})
	nu = zeros(3);  w = zeros(3, 3)
	azero = qf[1, 1]
	dvect = qf[2:4, 1]
	b     = qf[2:4, 2:4]
	mf    = (azero - 1) .* b .- dvect * dvect'

	F = eigen(Symmetric(mf))
	d = real.(F.values);  z = real.(F.vectors)
	p = sortperm(d);  d = d[p];  z = z[:, p]

	nneg = 0;  npos = 0;  kneg = 0;  kpos = Int[]
	for i in 1:3
		if d[i] < 0
			nneg += 1;  kneg = i
		elseif d[i] > 0
			npos += 1;  push!(kpos, i)
		end
	end
	if nneg != 1 || npos != 2
		@warn "bingham/meig: m should have one negative and two positive eigenvalues; it has $nneg and $npos"
		return (nu, w, mf, 0, 1)
	end

	nlarg = count(kk -> d[kk] > (azero - 1.0), kpos)
	rhanded = () -> begin                        # make the columns of w a right-handed system
		det = w[1,1]*w[2,2]*w[3,3] + w[1,2]*w[2,3]*w[3,1] + w[1,3]*w[3,2]*w[2,1] -
		      w[1,3]*w[2,2]*w[3,1] - w[1,2]*w[2,1]*w[3,3] - w[1,1]*w[2,3]*w[3,2]
		det <= 0 && (w[:, 1] .= -w[:, 1])
	end

	local icase::Int
	if nlarg == 2
		# The admissible axes are two antipodal caps. nu(3) is the negative eigenvalue and its
		# eigenvector is turned to make an acute angle with the optimal axis.
		nu[3] = d[kneg];  w[:, 3] = z[:, kneg]
		for j in 1:2
			nu[j] = d[kpos[j]];  w[:, j] = z[:, kpos[j]]
		end
		sum(w[i, 3] * uxx[i] for i in 1:3) < 0 && (w[:, 3] .= -w[:, 3])
		if mf[3, 3] > (azero - 1)
			icase = 1                            # a cap containing neither pole — the usual case
		else
			icase = w[3, 3] >= 0 ? 2 : 3         # the cap contains the north / south pole
		end
		rhanded()
	elseif nlarg == 1
		# The admissible axes are the COMPLEMENT of two antipodal (excluded) caps.
		nu[1] = d[kneg];  w[:, 1] = z[:, kneg]
		for j in 2:3
			nu[j] = d[kpos[j-1]];  w[:, j] = z[:, kpos[j-1]]
		end
		if mf[3, 3] <= (azero - 1)
			icase = 5
			rhanded()
		else
			icase = 4
			w[3, 3] < 0 && (w[:, 3] .= -w[:, 3])
		end
	else
		icase = 6                                # any axis is admissible
	end
	return (nu, w, mf, icase, 0)
end

# evalf(): f(phit) = dphit/ds along the bounding curve, and on the way the (phi, theta) of the
# point and its axis vector u. `icode` = 0 for the first point, positive afterwards (then `oldu`
# and `ophi` are used to keep phi continuous across the 2*pi wrap).
function _bingham_evalf(phit::Float64, nu::Vector{Float64}, w::Matrix{Float64}, azero::Float64,
                        icode::Int, oldu::Vector{Float64}, ophi::Float64)
	cospt = cos(phit);  sinpt = sin(phit)
	denom = nu[1]*cospt*cospt + nu[2]*sinpt*sinpt - nu[3]
	num   = azero - 1.0 - nu[3]
	costt = sqrt(num / denom)
	thetat = acos(clamp(costt, -1.0, 1.0))
	eta = [costt*cospt, costt*sinpt, sin(thetat)]
	u = w * eta

	lambda = (nu[2] - nu[1]) / num
	dedpt = zeros(3)
	dedpt[1] = -eta[2] * (lambda*eta[1]*eta[1] + 1.0)
	dedpt[2] = -eta[1] * (lambda*eta[2]*eta[2] - 1.0)
	ss = eta[1]*eta[1] + eta[2]*eta[2]
	dedpt[3] = lambda * eta[1] * eta[2] * ss / eta[3]
	dudpt = w * dedpt

	cost2 = u[1]*u[1] + u[2]*u[2]
	dpdpt = (-u[2]*dudpt[1] + u[1]*dudpt[2]) / cost2
	dtdpt = dudpt[3] / sqrt(cost2)
	fval = 1.0 / sqrt(dpdpt*dpdpt + dtdpt*dtdpt)
	phi   = atan(u[2], u[1])
	theta = asin(clamp(u[3], -1.0, 1.0))
	icode == 0 && return (fval, phi, theta, u, 0)

	alpha = u[1]*oldu[1] + u[2]*oldu[2]
	beta  = -u[1]*oldu[2] + u[2]*oldu[1]
	ephi  = ophi + atan(beta, alpha)
	if abs(ephi - phi) < pi/180
		return (fval, phi, theta, u, 0)
	elseif abs(ephi - phi - 2pi) < pi/180
		return (fval, phi + 2pi, theta, u, 0)
	elseif abs(ephi - phi + 2pi) < pi/180
		return (fval, phi - 2pi, theta, u, 0)
	end
	@warn "bingham/evalf: unable to determine phi for a point on the bounding curve"
	return (fval, phi, theta, u, 1)
end

# boundc(): walk the bounding curve by Euler's method on dphit/ds = f(phit) and return the points.
function _bingham_boundc(azero::Float64, nu::Vector{Float64}, w::Matrix{Float64}, icase::Int)
	R2D = 180 / pi;  TWOPI = 2pi
	npart = 300;  kmax = 400
	(icase >= 6) && return (Float64[], Float64[], 0)   # every axis admissible: no bounding curve

	phi   = zeros(kmax);  theta = zeros(kmax)
	phit  = zeros(kmax);  phim  = zeros(kmax);  thetm = zeros(kmax)
	oldu  = zeros(3);  ophi = 0.0

	# Estimated length of the curve, from thirteen points at equal steps in phit.
	delpt = pi / 6
	for k in 1:13
		phit[k] = (k - 1) * delpt
		_, phi[k], theta[k], u, ier = _bingham_evalf(phit[k], nu, w, azero, k - 1, oldu, ophi)
		ier != 0 && return (Float64[], Float64[], 1)
		oldu = u;  ophi = phi[k]
	end
	eleng = 0.0
	for k in 1:12
		eleng += hypot(phi[k+1] - phi[k], theta[k+1] - theta[k])
	end
	dels = eleng / npart
	phit[1] = 0.0
	icase == 3 && (dels = -dels)

	kend = 0
	for k in 2:kmax
		fval, phi[k-1], theta[k-1], u, ier = _bingham_evalf(phit[k-1], nu, w, azero, k - 2, oldu, ophi)
		ier != 0 && return (Float64[], Float64[], 1)
		oldu = u;  ophi = phi[k-1]
		phit[k] = phit[k-1] + fval * dels          # Euler's method on dphit/ds = f(phit)
		if abs(phit[k]) >= TWOPI
			kend = k
			break
		end
	end
	if kend == 0
		@warn "bingham/boundc: unable to close the bounding curve with npart=$npart, kmax=$kmax"
		return (Float64[], Float64[], 1)
	end
	k = kend

	if icase == 1
		# A cap containing neither pole: a closed curve. Centre the longitudes if they straddle.
		npt = k
		phit[npt] = TWOPI;  phi[npt] = phi[1];  theta[npt] = theta[1]
		pmin, pmax = extrema(view(phi, 1:npt))
		pmean = (pmin + pmax) / 2
		if pmean > pi
			@views phi[1:npt] .-= TWOPI
		elseif pmean <= -pi
			@views phi[1:npt] .+= TWOPI
		end
		return (phi[1:npt] .* R2D, theta[1:npt] .* R2D, 0)

	elseif 2 <= icase <= 4
		# A cap containing a pole (2, 3), or an equatorial belt (4): re-order the points so that
		# longitude runs from -180 to 180.
		npt = k - 1
		npt < 1 && return (Float64[], Float64[], 1)
		@views phim[1:npt] .= phi[1:npt]
		@views thetm[1:npt] .= theta[1:npt]
		for k_ in 2:npt
			phi[k_] <= pi && continue
			kz = k - 1
			for l in 1:(npt - kz)
				phim[l] = phi[kz + l] - TWOPI;  thetm[l] = theta[kz + l]
			end
			for l in 1:kz
				k2 = l + npt - kz
				k2 <= npt || continue
				phim[k2] = phi[l];  thetm[k2] = theta[l]
			end
		end
		if icase != 4
			return (phim[1:npt] .* R2D, thetm[1:npt] .* R2D, 0)   # (D2R in the MATLAB: a typo)
		end
		if any(<=(0), view(phim, 1:npt))
			@warn "bingham/boundc (icase=4): the points on the bounding curve are too sparse"
			return (Float64[], Float64[], 1)
		end
		return (phim[1:npt] .* R2D, thetm[1:npt] .* R2D, 0)

	elseif icase == 5
		# The complement of two antipodal caps that contain no pole. If the cap we have crosses
		# +/-pi it is replaced by its antipode; the curve is then closed (subcase a) or broken into
		# one closed and two open pieces (subcase b) — all of them returned as one polyline here.
		npt = k
		phi[npt] = phi[1];  theta[npt] = theta[1]
		if any(>(pi), view(phi, 1:npt))
			@views phi[1:npt] .-= pi
			@views theta[1:npt] .= -theta[1:npt]
		elseif any(<=(-pi), view(phi, 1:npt))
			@views phi[1:npt] .+= pi
			@views theta[1:npt] .= -theta[1:npt]
		end
		return (phi[1:npt] .* R2D, theta[1:npt] .* R2D, 0)
	end
	return (Float64[], Float64[], 1)
end

# ========================================================================================
# HELLINGER WITH AUTOMATIC SEGMENTATION
# ========================================================================================
# Port of the wrapper half of Mirone's utils/hellinger.m: the part that turns two plain isochrons
# into the sectioned data the Hellinger estimator needs, and the part that turns the estimator's
# covariance into the numbers a user reads (confidence volume, statistics, 95% error ellipse).
#
# The segmentation is not invented: the moving isochron is simplified with Douglas-Peucker
# (`gmtsimplify -T<tol>k`), consecutive kept vertices define the Hellinger sections, and every
# point of each isochron is assigned to a section by `mapproject -L…+p` — the same two GMT
# operations the MATLAB code called through cvlib_mex and gmtmex.

# rot_euler(..., ecc = -1): rotate geodetic lon/lat (degrees) about an Euler pole, with the
# rotation itself done on geocentric latitudes. Built from this file's own quaternion machinery.
function _hell_rot_euler(lon::Vector{Float64}, lat::Vector{Float64}, along, alat, rho)
	D2R = π / 180;  ecc = 0.0818191908426215
	glat = atan.((1 - ecc^2) .* sin.(lat .* D2R), cos.(lat .* D2R)) ./ D2R
	x, y, z = trans1(glat, lon)
	R = trans4(trans3(alat, along, rho))
	rlon = similar(lon);  rlat = similar(lat)
	for k in eachindex(x)
		if isnan(x[k])                                  # the NaN rows that separate the sections
			rlon[k] = NaN;  rlat[k] = NaN
			continue
		end
		v = R * [x[k], y[k], z[k]]
		la, lo = trans6(v)
		rlon[k] = lo
		rlat[k] = atan(sin(la * D2R), (1 - ecc^2) * cos(la * D2R)) / D2R
	end
	return (rlon, rlat)
end

# segmentate(): which Hellinger section each point of ISOC belongs to. `segmented` is the
# NaN-separated list of two-point sections; mapproject -L reports the section a point is nearest to.
function _hell_segmentate(isoc::Matrix{Float64}, segmented::Matrix{Float64})
	tmp = tempname() * ".txt"
	try
		open(tmp, "w") do io
			started = false
			for r in 1:size(segmented, 1)
				if isnan(segmented[r, 1])
					started = false
					continue
				end
				started || println(io, ">")
				started = true
				println(io, segmented[r, 1], "\t", segmented[r, 2])
			end
		end
		D = gmt("mapproject -L" * tmp * "+uk+p", isoc)
		M = isa(D, Vector) ? D[1].data : D.data
		size(M, 2) < 4 && error("mapproject -L returned no segment id")
		return round.(Int, M[:, 4]) .+ 1            # mapproject is C, hence 0-based
	finally
		isfile(tmp) && rm(tmp, force=true)
	end
end

"""
    hellinger_auto(along, alat, rho, isoc_mov, isoc_fix; dp_tol=8.0, force_pole=false,
                   std_invented=4.0, plev=0.95) -> NamedTuple

[`hellinger`](@ref) with the Hellinger sections found automatically.

The moving isochron is simplified with Douglas-Peucker at `dp_tol` km; consecutive kept vertices
become the sections, and both isochrons' points are assigned to them with `mapproject`. On top of
the fit it returns the confidence volume, the printable statistics block and the 95% confidence
ellipse of the pole (see [`bingham`](@ref)).

### Returns
`along, alat, rho` (the fitted pole), `vol` (km^3), `stats` (String), `ellipse_lon`, `ellipse_lat`,
`segments`, `segments_rot` (the segmentation guess and its rotation, NaN-separated), `flags_mov`,
`flags_fix`, and `result` — the full [`hellinger`](@ref) answer.
"""
function hellinger_auto(along::Real, alat::Real, rho::Real, isoc_mov::Matrix{Float64},
                        isoc_fix::Matrix{Float64}; dp_tol::Real=8.0, force_pole::Bool=false,
                        std_invented::Float64=4.0, plev::Float64=0.95)
	_hellinger_auto(Float64(along), Float64(alat), Float64(rho), isoc_mov, isoc_fix, Float64(dp_tol), force_pole,
	                std_invented, plev)
end
function _hellinger_auto(along::Float64, alat::Float64, rho::Float64, isoc_mov::Matrix{Float64},
                         isoc_fix::Matrix{Float64}, dp_tol::Float64, force_pole::Bool,
                         std_invented::Float64, plev::Float64)
	D2R = π / 180;  ecc = 0.0818191908426215
	size(isoc_mov, 1) < 3 && error("hellinger_auto: the moving isochron needs at least 3 points")

	# The sections are looked for on geocentric latitudes, as in the MATLAB original (the solver
	# converts its own inputs, so it is given the untouched geodetic coordinates further down).
	mov = copy(isoc_mov);  fix = copy(isoc_fix)
	mov[:, 2] = atan.((1 - ecc^2) .* sin.(mov[:, 2] .* D2R), cos.(mov[:, 2] .* D2R)) ./ D2R
	fix[:, 2] = atan.((1 - ecc^2) .* sin.(fix[:, 2] .* D2R), cos.(fix[:, 2] .* D2R)) ./ D2R

	B = gmtsimplify(mat2ds(mov), T="$(dp_tol)k")
	dp = isa(B, Vector) ? B[1].data : B.data
	size(dp, 1) < 2 && error("hellinger_auto: the DP tolerance left fewer than two vertices")

	# The DP vertices, as consecutive two-point sections separated by NaNs.
	nseg = size(dp, 1) - 1
	segmented = fill(NaN, 3 * nseg, 2)
	for k in 1:nseg
		segmented[3k-2, 1] = dp[k, 1];    segmented[3k-2, 2] = dp[k, 2]
		segmented[3k-1, 1] = dp[k+1, 1];  segmented[3k-1, 2] = dp[k+1, 2]
	end

	flags_mov = _hell_segmentate(mov, segmented)
	rlon, rlat = _hell_rot_euler(segmented[:, 1], segmented[:, 2], along, alat, rho)
	segmented_rot = hcat(rlon, rlat)
	flags_fix = _hell_segmentate(fix, segmented_rot)

	# Unpaired sections at the far end of one isochron make the covariance come out NaN; the
	# extreme points they hold are unpaired anyway, so they are folded into the last common one.
	delta = flags_fix[end] - flags_mov[end]
	if abs(delta) > 1
		k = 0
		if delta > 0
			while flags_mov[end-k] > flags_fix[end] + 1
				flags_fix[end-k] = flags_mov[end] + 1;  k += 1
			end
		else
			while flags_mov[end-k] > flags_fix[end] + 1
				flags_mov[end-k] = flags_fix[end] + 1;  k += 1
			end
		end
	end

	H = hellinger(along, alat, rho, isoc_mov, isoc_fix; flags_mov=flags_mov, flags_fix=flags_fix,
	              std_invented=std_invented, plev=plev, do_geodetic=true, force_pole=force_pole)

	cov = H.covariance
	if any(isnan, cov)
		@warn "hellinger_auto: the covariance came out NaN — no confidence region"
		return (along=H.along, alat=H.alat, rho=H.rho, vol=NaN, stats="covariance is NaN",
		        ellipse_lon=Float64[], ellipse_lat=Float64[], segments=segmented,
		        segments_rot=segmented_rot, flags_mov=flags_mov, flags_fix=flags_fix, result=H)
	end

	# H11.2 = the inverse of the rotation block of the covariance, through its eigen-decomposition.
	F = eigen(Symmetric(Matrix(cov)))
	dd = real.(F.values);  V = real.(F.vectors)
	p = sortperm(dd);  dd = dd[p];  V = V[:, p]
	sigma4 = zeros(3, 3)
	for i in 1:3, j in 1:3, k in 1:3
		sigma4[i, j] += V[i, k] * V[j, k] / dd[k]
	end

	# The Bingham matrix of the rotation, in symmetric storage.
	qhat = H.qhat
	ahatm = zeros(3, 4)
	ahatm[1,1] = -qhat[2];  ahatm[1,2] =  qhat[1];  ahatm[1,3] =  qhat[4];  ahatm[1,4] = -qhat[3]
	ahatm[2,1] = -qhat[3];  ahatm[2,2] = -qhat[4];  ahatm[2,3] =  qhat[1];  ahatm[2,4] =  qhat[2]
	ahatm[3,1] = -qhat[4];  ahatm[3,2] =  qhat[3];  ahatm[3,3] = -qhat[2];  ahatm[3,4] =  qhat[1]
	qbing = zeros(10)
	k = 0
	for i in 1:4, j in 1:i
		k += 1
		for k1 in 1:3, k2 in 1:3
			qbing[k] += 4 * ahatm[k1, i] * sigma4[k1, k2] * ahatm[k2, j]
		end
	end

	x, y, z = trans1(H.alat, H.along)
	elong, elat, _ = bingham(qbing, 0.0, H.xchi, [x, y, z])

	# Volume of the confidence region, vol = 4/3*pi*a*b*c, after the conreg.f program of J-Y Royer.
	Fs = eigen(Symmetric(sigma4))
	angled = sqrt.(H.xchi ./ real.(Fs.values)) ./ D2R
	vol = 4/3 * π * prod(angled) * 111.111^3

	stats = string(
		"Results from Hellinger1 using in memory segmentation\n",
		"Fitted rotation--alat, along, rho:\n",
		@sprintf("%f\t%f\t%f\n", H.alat, H.along, H.rho),
		"conf. level, conf. interval for kappa:\n",
		@sprintf("%f\t%f\t%f\n", H.plev, H.fkap2, H.fkap1),
		"kappahat, degrees of freedom, xchi:\n",
		@sprintf("%f\t%d\t%f\n", H.hatkap, H.df, H.xchi),
		"Number of points, sections, misfit, reduced misfit:\n",
		@sprintf("%d\t%d\t%f\t%f\n", H.ndata, H.nsect, H.rmin, 1/sqrt(H.hatkap)),
		"covariance matrix:\n",
		@sprintf("%g\t%g\t%g\n%g\t%g\t%g\n%g\t%g\t%g\n", cov[1,1], cov[1,2], cov[1,3],
		         cov[2,1], cov[2,2], cov[2,3], cov[3,1], cov[3,2], cov[3,3]),
		@sprintf("confidence region volume: %g km3", vol))

	return (along=H.along, alat=H.alat, rho=H.rho, vol=vol, stats=stats,
	        ellipse_lon=elong, ellipse_lat=elat, segments=segmented, segments_rot=segmented_rot,
	        flags_mov=flags_mov, flags_fix=flags_fix, result=H)
end
