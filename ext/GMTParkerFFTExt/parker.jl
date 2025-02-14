"""
    G = parkermag(mag, bat, dir::String="dir"; year=2020.0, nnx=0, nny=0, nterms=6, zobs=0.0,
	              wshort=0.0, wlong=0.0, slin=0.0, sdip=0.0, sdec=0.0, thickness=0.5, pct=30,
	              geocentric=false, padtype::String="taper", isRTP=false, verbose=false)

Calculate the magnetic direct or inverse problem using Parker's [1973] Fourier series summation approach.

Depending on the value of `dir` it will calculate the direct or inverse problem. The direct problem
calculates magnetic field given a magnetization and bathymetry. The inverse calculates magnetization
from magnetic field and bathymetry.

This function is an adaptation of the Mirone code that itself was an adaptation of Maurice Tivey's code
MATLAB Version from 1992.

### Args
- `mag`: GMTgrid or filename of the magnetic field (nT) for the direct problem or magnetization (A/m) for the
   inverse problem.
- `bat`: bathymetry grid (km positive up)
- `dir`: "dir" for direct problem or "inv" for inverse problem.

### Keyword Args
- `year`: year of observation in decimal years.
- `nnx, nny`: suitable grid dimensions for FFT. By default, they are calculated as the next _good FFT number_ that
   is 30% larger than the size of the input grids. But this value can be set via the `pct` option. To the list of
   the _good FFT numbers_ run this command: ``gmt("grdfft -Ns")``
- `nterms`: number of terms in the Parker summation (default is 6).
- `zobs`: Level of observation in km. This is zero for marine magnetics surveys.
- `wshort`: short wavelength cutoff (for the inverse problem only). By default, we comput it automatically from
   the grid increments, but often it may require a finer tunning. 
- `wlong`: long wavelength cutoff (for the inverse problem only). By default, it is also assigned automatically.
   as `max(dx*nnx, dy*nny)` with an additional condition of not being shorter than 150 km.
- `slin`: strike of line of observation (for the direct problem only).
- `sdip`: dip of line of observation. Use ``sdip=90`` for a geocentric dipole.
- `sdec`: declination of magnetization.
- `thickness`: thickness of source layer in km.
- `pct`: percentage of grid size to augment. See also the `nnx` and `nny` options. Use `pct=0` to force
   `nnx` and `nny` to be the same as the size of the input grids.
- `padtype`: Strategy used when padding an array. The default is to use "taper" Hanning window. Alternative is
   "zero" that pads with zeros.
- `isRTP`: Set this to true if the field is already reduced-to-the-pole.
- `geocentric`: use the geocentric dipole. Same as leaving `sdip=0` & `sdec=0`
- `verbose`: verbose mode

### Returns
- `G`: output grid magnetic field (nT) or magnetization (A/m).

### Examples
```julia
m = zeros(Float32, 64,64);  m[32:40,32:40] .= 10;
h = fill(-2.0f0, 64,64);
Gm = mat2grid(m, hdr=[30., 30.32, 30., 30.32]);
Gh = mat2grid(h, hdr=[30., 30.32, 30., 30.32]);
f3d = parkermag(Gm,  Gh, "dir", year=2000, thickness=1, pct=0);
m3d = parkermag(f3d, Gh, "inv", year=2000, thickness=1, pct=0);

grdimage(f3d, figsize=6, title="Field (nT)", colorbar=true)
C = makecpt(m3d);		# Need a different colormap for the magnetization
grdview!(m3d, figsize=6, zsize=4, view=(210, 40), title="Magnetization (A/m)", cmap=C, surf=:image, B=:za, xshift=8, show=true)
```
"""
function GMT.parkermag(mag::String, bat::String, dir::String="dir"; year=2020, nnx=0, nny=0, nterms=6, zobs=0.0,
	               wshort=0.0, wlong=0.0, slin=0.0, sdip=0.0, sdec=0.0, thickness=0.5, pct=30, padtype::String="taper",
				   geocentric=false, isRTP=false, verbose=false)::GMTgrid{Float32, 2}
	Gm = GMT.gmtread(mag, grd=true)
	Gh = GMT.gmtread(bat, grd=true)
	GMT.parkermag(Gm, Gh, dir; year=year, nnx=nnx, nny=nny, nterms=nterms, zobs=zobs, wshort=wshort, wlong=wlong,
	          slin=slin, sdip=sdip, sdec=sdec, thickness=thickness, pct=pct, padtype=padtype, geocentric=geocentric,
	          isRTP=isRTP, verbose=verbose)
end

function GMT.parkermag(Gm::GMTgrid, Gbat::GMTgrid, dir::String="dir"; year=2020, nnx=0, nny=0, nterms=6, zobs=0.0,
                   wshort=0.0, wlong=0.0, slin=0.0, sdip=0.0, sdec=0.0, thickness=0.5, pct=30, padtype::String="taper",
				   geocentric=false, isRTP=false, verbose=false)::GMTgrid{Float32, 2}
	helper_parkermag(Gm, Gbat, dir, Float32(year), nnx, nny, nterms, Float32(zobs), Float32(wshort), Float32(wlong),
	                 Float32(slin), Float32(sdip), Float32(sdec), Float32(thickness), Float64(pct), padtype, Bool(geocentric),
					 Bool(isRTP), Bool(verbose))
end

# Annotate all inputs because Julia recompiles everithing if a single input type changes.
function helper_parkermag(Gm::GMTgrid, Gbat::GMTgrid, dir::String, year, nnx::Int, nny::Int, nterms::Int,
                          zobs::Float32, wshort::Float32, wlong::Float32, slin::Float32, sdip::Float32,
						  sdec::Float32, thickness::Float32, pct::Float64, padtype::String, geocentric::Bool, isRTP::Bool, verbose::Bool)
	!GMT.guessgeog(Gm) && error("Input grid must be in geographical coordinates")
	dx::Float64, dy::Float64 = Gm.inc[1], Gm.inc[2]
	rlat::Float64 = (Gm.range[3] + Gm.range[4]) / 2
	rlon::Float64 = (Gm.range[1] + Gm.range[2]) / 2
	geocentric && (sdip = 0.0; sdec = 0.0)				# if field is RTP or mag is vertical
	sclat, sclon = scltln(rlat)
	dx *= sclon
	dy *= sclat
	(!startswith(dir, "dir") && isRTP) && (rlat = 90.0; rlon = 0.0)
	width, height = GMT.getsize(Gm)
	(nnx == 0 && nny == 0) && ((nnx, nny) = goodfftnumbers(width, height, pct=pct))
	if (wshort == 0.0 && wlong == 0.0)
		wshort = max(dx*2, dy*2)
		wlong  = max(dx*nnx, dy*nny)
		wlong = max(wlong,150)			# ???
	end
	rng::Vector{Float64} = Gbat.range
	sc_z = ((rng[6] - rng[5]) > 15) ? 0.001 : 1.0		# Crude guess if grid is in meters.
	zmean = -(rng[6] + rng[5]) / 2
	sc_z *= sign(zmean)					# This is for the case of when z was positive down (revert to pos up)
	mag, to_restore = mboard(Gm.z, width, height, nnx, nny, mode=padtype)
	h = mboard(Gbat.z, width, height, nnx, nny, scale=sc_z, mode=padtype)[1]
	if (startswith(dir, "dir"))
		f = syn3d(mag, h, dx, dy, rlat, rlon, year, zobs, thickness, slin, sdip, sdec, nterms, verbose)
	else
		f = inv3d(mag, h, dx, dy, wlong, wshort, rlat, rlon, year, zobs, thickness, sdec, sdip, nterms, verbose)
	end
	mat2grid(f[to_restore[1]+1:to_restore[1]+width, to_restore[3]+1:to_restore[3]+height], Gm)
end

# ------------------------------------------------------------------------------------------------------
"""
    G = parkergrav(G, dir::String="dir"; nnx=0, nny=0, nterms=6, depth=0.0, zobs=0.0,
                       pct=30, wshort=25.0, rho=1000.0, maxiter=50, min_err=1e-4, padtype::String="taper",
                       isKm::Bool=false, verbose=false)

Calculate the gravity direct or inverse problem using Parker's [1973] Fourier series summation approach.

Depending on the value of `dir` it will calculate the direct or inverse problem. The direct problem
calculates gravity anomaly given the topography of an interface. The inverse calculates interface (in meters)
from the gravity anomaly and a mean depth of that interface.

This function, for the direct problem, is equivalent to the GMT's `gravfft` module. The inverse problem follows
the aproach of the magnetic case and the description in Parker's paper and should give the ~same results of
the `3DINVER.M` program (https://doi.org/10.1016/j.cageo.2004.11.004) although I did not check it (couldn't find the package).
It does, however, reproduce very well the tests from the `Grav3D.m` program (https://github.com/PhamLT/Grav3D),
of which we are using its test synthetic interface grid.

### Args
- `G`: GMTgrid or filename of the interface (meters or km positive up) for the direct problem
   or gravity anomaly (mGal) for the inverse problem.
- `dir`: "dir" for direct problem or "inv" for inverse problem.

### Keyword Args
- `nnx, nny`: suitable grid dimensions for FFT. By default they are calculated as the next _good FFT number_ that
   is 30% larger than the size of the input grids. But this value can be set via the `pct` option. To the list of
   the _good FFT numbers_ run this command: ``gmt("grdfft -Ns")``
- `nterms`: number of terms in the Parker summation (default is 6).
- `depth`: Average depth in km of the interface. We compute that from `G` for the direct problem but have no way
   of knowing it for the inverse problem, so it MUST be set in that case.
- `zobs`: Level of observation in km. This is zero for marine surveys.
- `pct`: percentage of grid size to augment. See also the `nnx` and `nny` options. Use `pct=0` to force
   `nnx` and `nny` to be the same as the size of the input grids.
- `wshort`: short wavelength cutoff (for the inverse problem only). By default, we compute it automatically from
   the grid increments, but often it may require a finer tunning. 
- `rho`: The density contrast across the interface in kg/m^3 or g/cc.
- `maxiter`: The maximum number of iterations used in the inverse problem until the error is below `min_err`.
- `min_err`: The std error threshold used in the inverse problem between iterations. When changes are below
   this value the iterations are stopped.
- `padtype`: Strategy used when padding an array. The default is to use "taper" Hanning window. Alternative is
   "zero" that pads with zeros.
- `isKm`: Set this to true to force that `G` is in km (including the grid increments). This overrides the units guessing.
- `verbose`: verbose mode

### Returns
- `G`: output grid with gravity anomaly (mGal) or interface (m)

### Example
```julia
Gbat = gmtread(GMT.TESTSDIT * "/assets/model_interface_4parker.grd");
# Compute the gravity due to the interface. The direct problem
Ggrv = parkergrav(Gbat, rho=400, nterms=10)

# Compute the interface from the gravity. The inverse problem.
Gbat_inv = parkergrav(Ggrv, "inv", rho=400, depth=20.0)

# Recompute the gravity from inverted topography
Ggrv_rec = parkergrav(Gbat_inv, rho=400, nterms=10)

# The residues 
Gres = Ggrv - Ggrv_rec;

# Plot the results
grdimage(Gbat, figsize=7, title="Initial topography (m)", contour=true, colorbar=true)
grdimage!(Ggrv, figsize=7, xshift=9, title="Gravity anomaly (mGal)", cmap=:auto, contour=true, colorbar=true)
grdimage!(Gbat_inv, figsize=7, xshift=-9, yshift=-9.0, title="Calculated Interface (m)", cmap=:auto, contour=true, colorbar=true)
grdimage!(Gres, figsize=7, xshift=9, title="Residues (mGal)", cmap=:auto, contour=true, colorbar=true, show=true)
```
"""
function GMT.parkergrav(G::String, dir::String="dir"; nnx=0, nny=0, nterms=6, depth=0.0, zobs=0.0,
                    pct=30, wshort=25.0, rho=1000.0, maxiter=50, min_err=1e-4, padtype::String="taper",
					isKm::Bool=false, verbose=false)::GMTgrid{Float32, 2}
	_G = GMT.gmtread(G, grd=true)
	GMT.parkergrav(_G, dir=dir; nnx=nnx, nny=nny, nterms=nterms, depth=depth, zobs=zobs, pct=pct, wshort=wshort,
	                rho=rho, maxiter=maxiter, min_err=min_err, padtype=padtype, isKm=isKm, verbose=verbose)
end
function GMT.parkergrav(Gz::GMTgrid{Float32, 2}, dir::String="dir"; nnx=0, nny=0, nterms=6, depth=0.0, zobs=0.0,
                    pct=30, wshort=25.0, rho=1000.0, maxiter=50, min_err=1e-4, padtype::String="taper",
					isKm::Bool=false, verbose=false)::GMTgrid{Float32, 2}
	dx::Float64, dy::Float64 = Gz.inc[1], Gz.inc[2]
	rng::Vector{Float64} = Gz.range
	sclat = 1.0
	if (GMT.guessgeog(Gz))
		sclat, sclon = scltln((rng[3] + rng[4]) / 2)
		dx *= sclon
		dy *= sclat
	end
	width, height = GMT.getsize(Gz)
	(nnx == 0 && nny == 0) && ((nnx, nny) = goodfftnumbers(width, height, pct=pct))
	sc_z = ((rng[6] - rng[5]) > 15) ? 1.0 : 1000.0		# Crude guess if grid is in meters.
	zmean = -(rng[6] + rng[5]) / 2
	sc_z *= sign(zmean)					# This is for the case of when z was positive down (revert to pos up)
	if (startswith(dir, "dir"))
		# This branch works in SI
		h, to_restore = mboard(Gz.z, width, height, nnx, nny, offset=Float64(zmean), scale=sc_z, mode=padtype)
		(rho < 10) && (rho *= 1000)		# Heuristic to guess if density contrast was given in g/cc
		if (sclat != 1)  sc = 1.0
		else             sc = (dy > 25) ? 1.0 : 1000.0;		isKm && (sc = 1000.0)	# But let 'isKm' override
		end
		g = grav_fwd(h, dx*sc, dy*sc, zobs*sc_z, zmean*sc_z, rho, nterms)
	else
		# This branch works in km because I couldn't solve numeric shits when using meters. So convert dists to km
		(depth <= 0) && error("For the inverse problem you must provide the average depth (in km) of the interface.")
		g, to_restore = mboard(Gz.z, width, height, nnx, nny, mode=padtype)
		(rho > 10) && (rho *= 0.001)		# Heuristic to guess if density contrast was given in kg/m^3. Go to g/cc
		if (sclat != 1)  sc = 0.001
		else             sc = (dy > 25) ? 0.001 : 1.0;		isKm && (sc = 1.0)	# If > 25 we assume its meters. Must divide by 1000
		end
		wlong = 1e6			# Just a very long wavelength to make the filter a high-cut filter.
		g = grav_inv(g, dx*sc, dy*sc, wlong, wshort, depth, rho, maxiter, min_err, verbose)::Matrix{Float32}
	end
	mat2grid(g[to_restore[1]+1:to_restore[1]+width, to_restore[3]+1:to_restore[3]+height], Gz)
end

# ------------------------------------------------------------------------------------------------------
function syn3d(m3d, h, dx, dy, rlat, rlon, yr, zobs, thick, slin, sdip, sdec, nterms, verbose)::Matrix{Float32}
	# SYN3D Calculate magnetic field given a magnetization and bathymetry
	# map using Parker's [1973] Fourier series summation approach
	# Input arrays:
	#    m3d 	magnetization (A/m)
	#    h 		bathymetry (km +ve up)
	#    rlat 	latitude of survey area (dec. deg.)
	#    rlon 	longitude of survey area (dec. deg.)
	#    yr 	year of survey (dec. year)
	#    zobs 	observation level (+km up)
	#    thick 	thickness of source layer (km)
	#    dx 	x grid spacing  (km) 
	#    dy		y grid spacing  (km)
	#    slin	azimuth of lineations (deg) (optional)
	#    sdec	declination of magnetization (optional)
	#    sdip	inclination of magnetization (optional)
	#
	# Usage: f3d=syn3d(m3d,h,rlat,rlon,yr,zobs,thick,slin,dx,dy,sdip,sdec)
	#   or geocentric dipole: 
	#        f3d=syn3d(m3d,h,rlat,rlon,yr,zobs,thick,slin,dx,dy);
	#
	# Original version:
	# Maurice A. Tivey MATLAB Version 5 August 1992
	#                                   March  1996
	#  Joaquim Luis         Jan   2025
	#       Converted the Mirone version to Julia. In the process the absurd memory consumption
	#       was highly reduced.
	#
	#---------------------------------------------------------------------------------

	@assert size(m3d) == size(h) error("The two input matrices must have exactly the same size")
	D2R = π / 180  # conversion radians to degrees
	mu = 100       # conversion factor to nT
	cte = 2 * π * mu

	ny::Int, nx::Int = size(m3d)

	if (verbose)
		println("     3D MAGNETIC FIELD FORWARD MODEL")
		println("       Constant thickness layer")
		println(" M.A.Tivey      Version: May, 2004")
		println(" Zobs = $(zobs) Rlat = $(rlat) Rlon = $(rlon)")
		println(" Yr = $(yr)")
		println(" Thick = $(thick)")
		println(" Slin,Sdec,Sdip = $(slin) $(sdec) $(sdip)")
		println(" Nterms $(nterms)")
		println(" Number of points in map are : $(nx) x $(ny)")
	end

	if (abs(sdip) == 90 && abs(rlat) == 90)
		decl1, incl1 = 0.0, 90.0		# Trick used to inform that the Field is RTP
	else
		decl1::Float64, incl1::Float64 = magref([rlon rlat], alt=zobs, onetime=yr).data[8:9]
	end

	# compute skewness parameter
	if abs(sdec) > 0 || abs(sdip) > 0
		# [theta, ampfac] = nskew(yr, rlat, rlon, zobs, slin, sdec, sdip)
	else
		# [theta, ampfac] = nskew(yr, rlat, rlon, zobs, slin)
		sdip = atan(2 * sin(rlat * D2R) / cos(rlat * D2R)) / D2R
		sdec = 0.0
	end

	#slin = 0.0					# slin is forced to zero
	ra1 = incl1 * D2R
	rb1 = (decl1 - slin) * D2R
	ra2 = sdip * D2R
	rb2 = (sdec - slin) * D2R

	# calculate wavenumber array
	k, kx, ky = create_wavenumbers(nx, ny, dx, dy, eltype(h))

	O_ = Matrix{Complex{eltype(k)}}(undef, ny, nx)
	t1_r, t1_i = sin(ra1), im * cos(ra1)
	t2_r, t2_i = sin(ra2), im * cos(ra2)
	Threads.@threads for col = 1:nx
		for row = 1:ny
			aux_ = atan(ky[row], kx[col])
			@inbounds O_[row,col] = (t1_r + t1_i * sin(aux_ + rb1)) * (t2_r + t2_i * sin(aux_ + rb2))
		end
	end
	O = fftshift(O_)

	# shift zero level of bathy
	hmin, hmax = extrema(h)
	hwiggl = abs(hmax - hmin) / 2
	zup = zobs - hmax
	if (verbose)
		println(" $(hmin) $(hmax) = MIN, MAX OBSERVED BATHY")
		println(" SHIFT ZERO OF BATHY WILL BE $(hmax)")
		println(" NOTE OBSERVATIONS ARE $(zup) KM ABOVE BATHY")
		println("ZOBS=$(zobs) ZUP=$(zup)")
		println("$(hwiggl) = HWIGGL, DISTANCE TO MID-LINE OF BATHY")
		println(" THIS IS OPTIMUM ZERO LEVEL FOR FORWARD PROBLEM")
	end
	zup += hwiggl
	h .+= Float32(hwiggl - hmax)

	zup_ = convert(eltype(h), -zup)		# Do this to avoid doing (-k .* zup) in next line, which has to multiply the k MATRIX by -1
	eterm = exp.(k .* zup_)				# do upcon term
	# now do summing over nterms
	msum = eterm .* fft(m3d)
	aux = Matrix{eltype(k)}(undef, ny, nx)
	for n in 1:nterms
		Threads.@threads for m = 1:GMT.numel(h) @inbounds aux[m] = m3d[m] * h[m]^n end
		MH = fft(aux)
		fact_n = factorial(n)
		Threads.@threads for m = 1:GMT.numel(h) @inbounds msum[m] += eterm[m] * (k[m]^n / fact_n) * MH[m] end
	end

	Threads.@threads for n = 1:GMT.numel(msum)
		@inbounds O[n] = cte * msum[n] * (1 - exp(-k[n] * thick)) * O[n]		# Reuse 'O' array (double complex)
	end
	Float32.(real(ifft(O)))
end

# ------------------------------------------------------------------------------------------------------
function grav_fwd(h, dx, dy, zobs, zmean, rho, nterms)::Matrix{Float32}

	ny::Int, nx::Int = size(h)
	nxy = nx * ny
	k = create_wavenumbers(nx, ny, dx, dy, eltype(h))[1]		# calculate wavenumber array

	zup = abs(zobs - abs(zmean))		# 'abs? to avoid confusion with zavg value
	zup_ = convert(eltype(h), -zup)		# Do this to avoid doing (-k .* zup) in next line, which has to multiply the k MATRIX by -1
	eterm = exp.(k .* zup_)				# do upcon term

	# now do summing over nterms
	msum = zeros(Complex{Float32}, ny, nx)
	aux  = Matrix{eltype(k)}(undef, ny, nx)
	for n in 1:nterms
		#Threads.@threads for m = 1:nxy @inbounds aux[m] = h[m]^n end
		Threads.@threads for m = 1:nxy @inbounds aux[m] = (-h[m])^n end
		MH = fft(aux)
		fact_n = factorial(n)
		Threads.@threads for m = 1:nxy @inbounds msum[m] += ((-k[m])^(n-1) / fact_n) * MH[m] end
	end

	cte = Float32(-2 * π * rho * 6.6743 * 1e-6)		# 1e-6 = 1e-11 * 1e5
	Threads.@threads for n = 1:nxy  @inbounds msum[n] *= cte * eterm[n]  end
	Float32.(real(ifft(msum)))
end

# ------------------------------------------------------------------------------------------------------
function grav_inv(grav, dx, dy, wl, ws, zmean, rho, max_iter, min_err, verbose)::Matrix{Float32}

	_zmean = convert(eltype(grav), zmean)
	cte = Float32(2 * π * rho * 6.6743)				# 1e-6 = 1e-11 * 1e5
	ny::Int, nx::Int = size(grav)
	nxy = nx * ny
	k   = create_wavenumbers(nx, ny, dx, dy, eltype(grav))[1]		# calculate wavenumber array
	wts = bpass3d(nx, ny, convert(eltype(grav), dx), convert(eltype(grav), dy), wl, ws, false)	# set up bandpass filter

	F = -fft(grav) ./ (cte * exp.(-k .* _zmean) .+ eps(1.0f0))
	for m = 1:nxy @inbounds F[m] *= wts[m] end
	F[1,1] = 0
	interface = real(ifft(F))
	z_back = interface
	rms = 1e6
	n_iter, m = 0, 2
	fact = 2			# First factorial in series
	aux  = Matrix{eltype(grav)}(undef, ny, nx)

	function nonsense(F, k, interface, z_back, wts, aux, nxy, m, fact)
		# Put this inside a nested function to avoid that using Threads.@threads creates Core.boxes
		# But timings, with or without the threads, are the same ?????????
		Threads.@threads for n = 1:nxy  @inbounds aux[n] = interface[n]^m  end
		aux2 = fft(aux)
		Threads.@threads for n = 1:nxy  @inbounds F[n] = (F[n] - ((-k[n])^(m-1)) * aux2[n] ./ fact) * wts[n]  end
		F[1,1] = 0
		_interface = real(ifft(F))

		soma = 0.0
		for n = 1:nxy  @inbounds soma += (_interface[n] - z_back[n])^2  end		# Still can't use Threads.@threads here
		_rms = sqrt(soma / nxy)
		if (!isnan(_rms))
			Threads.@threads for n = 1:nxy  @inbounds z_back[n] = _interface[n]  end
		else
			Threads.@threads for n = 1:nxy  @inbounds _interface[n] = z_back[n]  end
			_rms = 1e-10
			@warn("Stop iteration because latest interface has NaN")
		end		
		return F, _interface, z_back, _rms
	end

	while (rms > min_err && n_iter < max_iter)
		F, interface, z_back, rms = nonsense(F, k, interface, z_back, wts, aux, nxy, m, fact)
		n_iter += 1
		verbose && println("Iteration = $n_iter, rms = $rms")
		m += 1
		fact *= m		# Update the factorial value
	end
	verbose && println("grav_inv: finished after $n_iter iterations")
	for n = 1:nxy  @inbounds interface[n] = -1000 * (interface[n] + _zmean)  end	# Add the mmean interface level and make it m v+up
	Float32.(interface)
end

# ------------------------------------------------------------------------------------------------------
function create_wavenumbers(nx, ny, dx, dy, dt::DataType=Float32)
	nx2, ny2 = div(nx, 2), div(ny, 2)
	sft_x = iseven(nx) ? 1 : 0
	sft_y = iseven(ny) ? 1 : 0
	dkx = convert(dt, (2 * π / (nx * dx)))
	dky = convert(dt, (2 * π / (ny * dy)))
	kx = (-nx2:nx2-sft_x) .* dkx
	ky = (-ny2:ny2-sft_y) .* dky

	k_ = Matrix{eltype(dkx)}(undef, ny, nx)
	Threads.@threads for col = 1:nx
		for row = 1:ny
			@inbounds k_[row,col] = sqrt.(kx[col]^2 .+ ky[row]^2)
		end
	end
	k = ifftshift(k_)
	return k, kx, ky
end

# ------------------------------------------------------------------------------------------------------
"""
	sclat, sclon = scltln(orlat)
"""
function scltln(orlat)
# Routine to determine lat-lon scales, km/deg, for ellipsoids
# of revolution,  using equations of:
#       Snyder, J.P., 1987, Map Projections -- A Working Manual,
#       USGS Professional Paper 1395, Washington DC, 383p. cf. pp 24-25.
#
# Currently, this is hard-wired for the WGS-84 ellipsoid.
#
# The basic equations are:
# 	sclat = a * (1-e*e)    /  (1 - e*e * sin(orlat)*sin(orlat))**(1.5)
#	sclon = a * cos(orlat) /  (1 - e*e * sin(orlat)*sin(orlat))**(0.5)
#
# where:    a  is the equatorial radius
#           b  is the polar radius
#           e  is the eccentricity
#           f  is the flattening
# Also:
#	e*e = 1. - b*b/a*a
#	f   = 1. - b/a
#
# Dan Scheirer, 21 May 1991

# These constants belong to the: WGS, 1984 ellipsoid (gmt_defaults.h)
	a = 6378.137;   b = 6356.7521;
	
	e2 = 1 - (b*b)/(a*a);
	sinlat = sin(orlat*pi/180);
	denom  = sqrt(1 - e2 * sinlat * sinlat);
	sclat = (pi/180) * a * (1 - e2)  / denom / denom / denom;
	sclon = (pi/180) * a * cos(orlat*pi/180) / denom;
	return sclat, sclon
end

# ------------------------------------------------------------------------------------------------------
"""
Pad a matrix before FFTit

W = MBOARD(W,NX,NY) mirror the matrix about last row and column
[W,TO_RESTORE] = MBOARD(W,NX,NY,NNX,NNY) taper the matrix with a NNX, NNY hanning window.
That means the matrix will be added NNY/2 rows on top; NNY/2 rows at bottom;
NNX/2 at left and NNY/2 at right. The pading skirt will fall down to zero on each of these bands
TO_RESTORE is a vector with the width of the pading bands [top, bot, left, right] that
is used to restore the original matrix dimensions after the FFT

If NNX or NNY == 0, than those are estimated as being the closest number to NX * 1.2 (or NY)
IF MBOARD([],NX,NY,0,0) compute only the good NNX = NX * 1.2 & NNY = NY * 1.2 and return
them in W. TO_RESTORE will contain "nlist". Note that there are no error testing. 
"""
function mboard(w, nx, ny, nnx=0, nny=0; mode="taper", scale=1.0, offset=0.0)

	_scale  = convert(eltype(w), scale)
	_offset = convert(eltype(w), offset)
	if (nx == nnx && ny == nny)
		wp = copy(w)				# Because we always return a new matrix (which is later modified in the direct/inverse functions)
		(offset != 0) && (wp .+= _offset)
		(scale  != 1) && (wp *= _scale)
		return wp, [0, 0, 0, 0]
	end
	(nnx == 0 || nny == 0) && ((nnx, nny) = goodfftnumbers(nx, ny))

	dnx, dny = nnx - nx, nny - ny
	dnx_w = floor(Int, dnx / 2)
	dnx_e = dnx - dnx_w
	dny_n = floor(Int, dny / 2)
	dny_s = dny - dny_n
	to_restore = [dny_n, dny_s, dnx_w, dnx_e]

	# If we have an offset request, it must be done before the padding
	wp = GMT.padarray((offset == 0) ? w : (copy(w) .+ _offset), (dny_n, dny_s, dnx_w, dnx_e); padval=0)

	if mode != "taper"				# Pad with zeros
		(scale  != 1) && (wp *= _scale)
		return wp, to_restore
	else
		# Extend to South
		vhan = hanning(2*dny_s)
		vhan = vhan[end÷2+1:end]
		tmp1 = repeat(vhan, 1, nny)
		tmp2 = repeat(wp[ny+dny_n:ny+dny_n, :], dny_s, 1)
		wp[ny+dny_n+1:end, :] .= tmp1 .* tmp2
			
		# Extend to East
		vhan = hanning(2*dnx_e)
		vhan = vhan[end÷2+1:end]
		tmp1 = repeat(vhan', ny+dny, 1)
		tmp2 = repeat(wp[:, nx+dnx_w], outer=(1, dnx_e))
		wp[:, nx+dnx_w+1:end] .= tmp1 .* tmp2
			
		# Extend to North
		vhan = hanning(2*dny_n)
		vhan = vhan[1:end÷2]
		tmp1 = repeat(vhan, 1, nny)
		tmp2 = repeat(wp[dny_n+1:dny_n+1, :], dny_n, 1)
		wp[1:dny_n, :] .= tmp1 .* tmp2

		# Extend to West
		vhan = hanning(2*dnx_w)
		vhan = vhan[1:end÷2]
		tmp1 = repeat(vhan', nny, 1)
		tmp2 = repeat(wp[:, dnx_w+1:dnx_w+1], 1, dnx_w)
		wp[:, 1:dnx_w] .= tmp1 .* tmp2
			
		(scale != 1.0) && (wp *= _scale)
		return wp, to_restore
	end
	
end

# ------------------------------------------------------------------------------------------------------
"""
	hanning(n)

Returns a symmetric N point hanning window
"""
function hanning(n)
	a0, a1, a2, a3, a4 = 0.5, 0.5, 0, 0, 0
	
	half = (rem(n, 2) == 0) ?  half = n / 2 : half = (n + 1) / 2
	x = (0:half-1) / (n - 1)
	w = a0 .- a1 * cos.(2π * x) .+ a2 * cos.(4π * x) .- a3 * cos.(6π * x) .+ a4 * cos.(8π * x)
	return [w; w[end:-1:1]]
end

# ------------------------------------------------------------------------------------------------------
"""
	nnx, nny = goodfftnumbers(nx, ny; pct=30)

Return the good FFT numbers for nx, ny that are pct% greater than the nx, ny sizes
"""
function goodfftnumbers(nx, ny; pct=30)

	nlist = [64, 72, 75, 80, 81, 90, 96, 100, 108, 120, 125, 128, 135, 144, 150, 160, 162, 180, 192, 200,
			216, 225, 240, 243, 250, 256, 270, 288, 300, 320, 324, 360, 375, 384, 400, 405, 432, 450, 480,
			486, 500, 512, 540, 576, 600, 625, 640, 648, 675, 720, 729, 750, 768, 800, 810, 864, 900, 960,
			972, 1000, 1024, 1080, 1125, 1152, 1200, 1215, 1250, 1280, 1296, 1350, 1440, 1458, 1500,
			1536, 1600, 1620, 1728, 1800, 1875, 1920, 1944, 2000, 2025, 2048, 2160, 2187, 2250, 2304,
			2400, 2430, 2500, 2560, 2592, 2700, 2880, 2916, 3000, 3072, 3125, 3200, 3240, 3375, 3456,
			3600, 3645, 3750, 3840, 3888, 4000, 4096, 4320, 4374, 4500, 4608, 4800, 4860, 5000]

	@assert pct >= 0 && pct <= 100
	(pct == 0) && (return nx, ny)
	(pct > 1) && (pct /= 100)
	nnx = round(Int, nx * (1.0 + pct))
	nnx = (nnx > nlist[end]) ? nx : nlist[findfirst((nlist .- nnx) .> 0)]

	nny = round(Int, ny * (1.0 + pct))
	nny = (nny > nlist[end]) ? ny : nlist[findfirst((nlist .- nny) .> 0)]
	return nnx, nny
end


# ------------------------------------------------------------------------------------------------------
"""
"""
function inv3d(f3d, h, dx, dy, wl, ws, rlat, rlon, yr, zobs, thick, sdec, sdip, nterms, verbose)

	@assert size(f3d) == size(h) error("The two input matrices must have exactly the same size")
	D2R = π / 180  # conversion radians to degrees
	mu = 100       # conversion factor to nT
	cte = 2 * π * mu

	ny::Int, nx::Int = size(f3d)

	# changeable parameters
	nitrs = 10
	tolmag = 0.0001
	flag = 0

	# remove mean from input field
	mnf3d = mean(f3d)
	f3d .-= mnf3d

	decl::Float64, incl::Float64 = magref([rlon rlat], alt=zobs, onetime=yr).data[8:9]

	# compute phase and amplitude factors from 2D method
	if (sdec == 0 && abs(sdip) == 90)
		if (abs(rlat) == 90 && rlon == 0)		# Trick used to inform that the Field is RTP
			incl = 90.0
			decl = 0.0
		end
	elseif (sdec != 0.0 || sdip != 0.0)			# Accept what was sent in
	else
		sdip = atan(2 * sin(rlat * D2R) / cos(rlat * D2R)) / D2R
		sdec = 0.0
	end

	slin = 0.0  # slin is forced to zero
	ra1 = incl * D2R
	rb1 = (decl - slin) * D2R
	ra2 = sdip * D2R
	rb2 = (sdec - slin) * D2R

	# make wave number array
	k, kx, ky = create_wavenumbers(nx, ny, dx, dy, eltype(f3d))

	# calculate geometric and amplitude factors
	amp_ = Matrix{Complex{eltype(kx)}}(undef, ny, nx)
	pha_ = Matrix{Complex{eltype(kx)}}(undef, ny, nx)
	t1_r, t1_i = sin(ra1), im * cos(ra1)
	t2_r, t2_i = sin(ra2), im * cos(ra2)
	Threads.@threads for col = 1:nx
		for row = 1:ny
			aux_ = atan(ky[row], kx[col])
			@inbounds amp_[row,col] = (t1_r + t1_i * sin(aux_ + rb1)) * (t2_r + t2_i * sin(aux_ + rb2))
			@inbounds pha_[row,col] = exp(im * (angle(t1_r + t1_i * sin(aux_ + rb1)) + angle(t2_r + t2_i * sin(aux_ + rb2))))
		end
	end
	amp = abs.(fftshift(amp_))
	phase = fftshift(pha_)

	# shift zero level of bathy
	hmin, hmax = extrema(h)
	hwiggl = abs(hmax - hmin) / 2
	zup = zobs - hmax
	h .+= Float32(hwiggl - hmax)

	wts = bpass3d(nx, ny, convert(eltype(f3d), dx), convert(eltype(f3d), dy), wl, ws, verbose)	# set up bandpass filter

	dexpw = exp.(-k .* hwiggl)
	F = fft(f3d)					# take fft of observed magnetic field and initial m3d
	m3d = zeros(eltype(F), ny, nx)  # make an initial guess of 0 for m3d

	# now do summing over nterms
	B = Matrix{eltype(F)}(undef, ny, nx)
	Threads.@threads for nm = 2:nx*ny
		B[nm] = (F[nm] * exp(k[nm] * zup)) / (cte * (1 - exp(-k[nm] * thick)) * amp[nm] * phase[nm])
	end
	B[1] = 0

	lastm3d = zeros(eltype(F), ny, nx)
	mlast   = zeros(eltype(F), ny, nx)
	M       = zeros(eltype(F), ny, nx)
	aux     = Matrix{eltype(F)}(undef, ny, nx)
	dsum    = Matrix{eltype(F)}(undef, ny, nx)
	nParker = 0
	erpast = 0.0
	for iter in 1:nitrs
		sum = zeros(eltype(F), ny, nx)
		for nkount in 1:nterms
			n = nkount - 1
			for m = 1:nx*ny @inbounds aux[m] = m3d[m] * h[m]^n end		# If I use Threads.@threads then m3d is Core.Box WTF!!
			MH = fft(aux)

			fact_n = factorial(n)
			for m = 1:nx*ny @inbounds dsum[m] = dexpw[m] * (k[m]^n / fact_n) * MH[m] end

			for m = 1:nx*ny @inbounds sum[m] += dsum[m] end

			nParker = nkount
		end

		# transform to get new solution
		Threads.@threads for m = 2:nx*ny @inbounds M[m] = B[m] - sum[m] + mlast[m] end		# M[1, 1] = 0 by the initialization step above

		# filter before transforming to ensure no blow ups
		Threads.@threads for m = 1:nx*ny @inbounds mlast[m] = M[m] * wts[m] end
		m3d = ifft(mlast)
		# do convergence test
		errmax = convert(eltype(f3d), 0.0)

		dif_max, this_mean = -Inf32, 0.0f0
		for m = 1:nx*ny									# Can't use Threads.@threads here neither. WTF is happening?
			tdif = abs(lastm3d[m] - m3d[m])
			dif_max = ifelse(tdif > dif_max, tdif, dif_max)
			this_mean += tdif
		end
		dif_avg = this_mean / (nx * ny)
	
		(errmax - dif_max < 0) && (errmax = dif_max)
		for m = 1:nx*ny @inbounds lastm3d[m] = m3d[m] end

		(iter == 1) && (erpast = errmax)
		(errmax > erpast) && (flag = 1; break)		# set the flag to show diverging solution
		erpast = errmax
		verbose && println("Iteration = $iter", "\tErrmax = $errmax", "\tParker term = $nParker", "\tAverage dif = $dif_avg")
		(errmax < tolmag) && (flag = 0; break)		# test for errmax less than tolerance
	end
	(flag == 1) && println("WARNING: Diverging solution. Error is increasing with iterations.")

	return Float32.(real(m3d))
end


# --------------------------------------------------------------------------------------------------
"""
    wts = bpass3d(nnx::Int, nny::Int, dx::Float, dy::Float, wlong::Real, wshort::Real, verbose::Bool)

Sets up bandpass filter weights in 2 dimensions.

### Args
	
- `nnx, nny`: Grid dimensions
- `dx, dy`: Sampling intervals
- `wlong:`: Long wavelength cutoff
- `wshort`: Short wavelength cutoff

Returns:
	Matrix containing bandpass filter weights. The type of this matrix depends on the type of `dx`.
	It can be a `Float32` or `Float64` matrix.
"""
function bpass3d(nnx, nny, dx::T, dy, wlong, wshort, verbose::Bool) where T
	!isa(dx, AbstractFloat) && (dx = Float32(dx); dy = Float32(dy))
	# Constants
	twopi = pi * 2
	dk1 = twopi/((nnx-1)*dx)
	dk2 = twopi/((nny-1)*dy)

	# Calculate wavenumber array
	k, _, _ = create_wavenumbers(nnx, nny, dx, dy, eltype(dx))
	
	# Default values for wshort and wlong
	wshort = wshort == 0.0 ? max(dx*2, dy*2) : wshort
	wlong = wlong == 0.0 ? min(nnx*dx, nny*dy) : wlong

	# Calculate filter parameters
	klo = twopi/wlong
	khi = twopi/wshort
	khif = 0.5*khi
	klof = 2*klo
	dkl = klof-klo
	dkh = khi-khif

	# Print diagnostic information
	if (verbose)
		println("BPASS3D SET UP BANDPASS WEIGHTS ARRAY:")
		println("HIPASS COSINE TAPER FROM K=$(klo) TO K=$(klof)")
		println("LOPASS COSINE TAPER FROM K=$(khif) TO K=$(khi)")
		println("DK1, DK2=$(dk1), $(dk2)")
	end

	# Calculate wavelength information
	wl1 = wlong > 0 ? twopi/klo : 1000
	wl2 = wlong > 0 ? twopi/klof : 1000
	wl3 = twopi/khif
	wl4 = twopi/khi
	wnx = twopi/(dk1*(nnx-1)/2)
	wny = twopi/(dk2*(nny-1)/2)

	if (verbose)
		println("\nIE BANDPASS OVER WAVELENGTHS")
		println("INF CUT-- $(wl1)--TAPER-- $(wl2) (PASS) $(wl3)--TAPER--$(wl4)")
		println("--  CUT TO NYQUIST X,Y=$(wnx), $(wny)")
	end

	# Initialize weights array
	wts = zeros(eltype(k), size(k))

	# Calculate bandpass filter weights
	@inbounds for i in 1:nny
		for j in 1:nnx
			if (k[i,j] > klo && k[i,j] < khi)
				wts[i,j] = 1
			end
			
			if (k[i,j] > klo && k[i,j] < klof)
				wts[i,j] *= (1-cos(pi*(k[i,j]-klo)/dkl))/2
			end
			
			if (k[i,j] > khif && k[i,j] < khi)
				wts[i,j] *= (1-cos(pi*(khi-k[i,j])/dkh))/2
			end
		end
	end

	return wts
end
