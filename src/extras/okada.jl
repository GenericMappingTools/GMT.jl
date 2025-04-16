#=
OKADA85 Surface deformation due to a finite rectangular source.
	[uE,uN,uZ,uZE,uZN,uNN,uNE,uEN,uEE] = OKADA85(...
	   E,N,DEPTH,STRIKE,DIP,LENGTH,WIDTH,RAKE,SLIP,OPEN)
	computes displacements, tilts and strains at the surface of an elastic
	half-space, due to a dislocation defined by RAKE, SLIP, and OPEN on a
	rectangular fault defined by orientation STRIKE and DIP, and size LENGTH and
	WIDTH. The fault centroid is located (0,0,-DEPTH).

	   E,N    : coordinates of observation points in a geographic referential
	            (East,North,Up) relative to fault centroid (units are described below)
	   DEPTH  : depth of the fault centroid (DEPTH > 0)
	   STRIKE : fault trace direction (0 to 360° relative to North), defined so
	            that the fault dips to the right side of the trace
	   DIP    : angle between the fault and a horizontal plane (0 to 90°)
	   LENGTH : fault length in the STRIKE direction (LENGTH > 0)
	   WIDTH  : fault width in the DIP direction (WIDTH > 0)
	   RAKE   : direction the hanging wall moves during rupture, measured relative
	            to the fault STRIKE (-180 to 180°).
	   SLIP   : dislocation in RAKE direction (length unit)
	   OPEN   : dislocation in tensile component (same unit as SLIP)

	returns the following variables (same matrix size as E and N):
	   uN,uE,uZ        : displacements (unit of SLIP and OPEN)
	   uZE,uZN         : tilts (in rad * FACTOR)
	   uNN,uNE,uEN,uEE : horizontal strains POSITIVE = COMPRESSION (unit of FACTOR)

	Length unit consistency: E, N, DEPTH, LENGTH, and WIDTH must have the same
	unit (e.g. km) which can be different from that of SLIP and OPEN (e.g. m) but
	with a possible FACTOR on tilt and strain results (in this case, an
	amplification of km/m = 1000). To have FACTOR = 1 (tilt in radians and
	correct strain unit), use the same length unit for all aforesaid variables.

	[...] = OKADA85(...,NU) specifies Poisson's ratio NU (default is 0.25 for an isotropic medium).

	Formulas and notations from Okada [1985] solution excepted for strain
	convention (here positive strain means compression), and for the fault
	parameters after Aki & Richards [1980], e.g.:
	      DIP=90, RAKE=0   : left lateral (senestral) strike slip
	      DIP=90, RAKE=180 : right lateral (dextral) strike slip
	      DIP=70, RAKE=90  : reverse fault
	      DIP=70, RAKE=-90 : normal fault


	Note that vertical strain components can be obtained with following equations:
	   uNZ = -uZN;
	   uEZ = -uZE;
	   uZZ = -(uEE + uNN)*NU/(1-NU);

	[...] = OKADA85(...,'plot') or OKADA85(...) without output argument
	produces a 3-D figure with fault geometry and dislocation at scale (if
	all of the fault parameters are scalar).

	Equations are all vectorized excepted for argument DIP which must be
	a scalar (beacause of a singularity in Okada's equations); all other
	arguments can be scalar or matrix of the same size.

	Example:

	   [E,N] = meshgrid(linspace(-10,10,50));
	   [uE,uN,uZ] = okada85(E,N,2,30,70,5,3,-45,1,1,'plot');
	   figure, surf(E,N,uN)

	considers a 5x3 fault at depth 2, N30°-strike, 70°-dip, and unit dislocation
	in all directions (reverse, senestral and open). Displacements are computed
	on a regular grid from -10 to 10, and North displacements are plotted as a surface.


	Author: François Beauducel <beauducel@ipgp.fr>
	   Institut de Physique du Globe de Paris
	Created: 1997
	Updated: 2014-05-24

	References:
	   Aki K., and P. G. Richards, Quantitative seismology, Freemann & Co,
	      New York, 1980.
	   Okada Y., Surface deformation due to shear and tensile faults in a
	      half-space, Bull. Seismol. Soc. Am., 75:4, 1135-1154, 1985.	
=#

"""
    Gdef = okada(G::GMTgrid; kw...)

### Args
- `G`: A grid defining the region and the grid spacing where the deformation will be computed.
- `x_start`: The x coordinate of the fault's start (UpperLeft corner of the fault plane).
- `y_start`: The y coordinate of the fault's start.
- `W`: The width of the fault in km.
- `L`: The length of the fault in km.
- `depth`: The depth of the fault top center in km (`depth` > 0).
- `strike`: The strike of the fault trace direction (0 to 360° relative to North) defined so that
   the fault dips to the right side of the trace.
- `dip`: The dip of the fault in degrees (angle between the fault plane and the horizontal plane).
- `rake`: Direction the hanging wall moves during rupture, measured relative to the fault STRIKE (-180 to 180°).
- `slip`: Dislocation in `rake` direction (km when `G` is in geographic coordinates, length unit when in cartesian).
- `open`: dislocation in tensile component (same unit as `slip`).
- `nu`: The Poisson's ratio of the faulted medium.
"""
function okada(G::GMTgrid; kw...)
	# Do all the parsings here so that only this tinny function gets recompiled when any of kwargs change.
	(x = get(kw, :x_start, nothing)) === nothing && error("'x_start' must be specified");	x_start = Float64(x)
	(y = get(kw, :y_start, nothing)) === nothing && error("'y_start' must be specified");	y_start = Float64(y)
	(d = get(kw, :depth, nothing))  === nothing && error("'depth' must be specified");	depth = Float64(d)
	(s = get(kw, :strike, nothing)) === nothing && error("'strike' must be specified"); strike = Float64(s)
	(d = get(kw, :dip, nothing))    === nothing && error("'dip' must be specified"); dip = Float64(d)
	(l = get(kw, :L, nothing))      === nothing && error("'L' must be specified"); L = Float64(l)
	(w = get(kw, :W, nothing))      === nothing && error("'W' must be specified"); W = Float64(w)
	(r = get(kw, :rake, nothing))   === nothing && error("'rake' must be specified"); rake = Float64(r)
	(s = get(kw, :slip, nothing))   === nothing && error("'slip' must be specified"); slip = Float64(s)
	(n = get(kw, :nu, 0.25)); nu = Float64(n)
	U3 = get(kw, :open, 0.0);
	okada(G, x_start, y_start, W, L, depth, strike, dip, rake, slip, nu, U3=U3)
end

function okada(G::GMTgrid, x_start::Float64, y_start::Float64, W::Float64, L::Float64, depth::Float64,
               strike::Float64, dip::Float64, rake::Float64, slip::Float64, nu::Float64; U3=0.0)
	x = (G.registration == 0) ? copy(G.x) : collect(linspace(G.range[1]+G.inc[1]/2, G.range[2]-G.inc[1]/2, size(G,2)))
	y = (G.registration == 0) ? copy(G.y) : collect(linspace(G.range[3]+G.inc[2]/2, G.range[4]-G.inc[2]/2, size(G,1)))
	L *= 1000; W *= 1000; depth *= 1000;		# Convert to meters
	depth = depth + sind(dip) * W/2

	if (guessgeog(G))
		fault_top_center, = geod([x_start y_start], strike, L/2)			# lon,lat of fault's top center
		fault_LL, = geod([x_start y_start], strike+90, W*cosd(dip))			# fault LowerLeft corner
		fault_bot_center, = geod([fault_LL[1] fault_LL[2]], strike, L/2)
		x_centroid = (fault_top_center[1] + fault_bot_center[1]) / 2
		y_centroid = (fault_top_center[2] + fault_bot_center[2]) / 2
		mat = okada_geog_z(x, y, W, L, depth, strike, dip, rake, slip, nu, x_centroid, y_centroid, Float64(U3))
	else
		mat = okada_z(x, y, W, L, depth, strike, dip, rake, slip, nu, Float64(U3))
	end
	rng = [G.range[1:4]..., extrema(mat)...]
	GMTgrid(proj4=prj4WGS84, range=rng, inc=G.inc, registration=G.registration, title="Okada vertical deformation", x=G.x, y=G.y, z=mat, layout="BCB", hasnans=1)
end

function okada(x::Vector{Float64}, y::Vector{Float64}; kw...)
	# This method assumes x,y are already in the fault centroid reference. Good for run the tests.
	(d = get(kw, :depth, nothing))  === nothing && error("'depth' must be specified");	depth = Float64(d)
	(s = get(kw, :strike, nothing)) === nothing && error("'strike' must be specified"); strike = Float64(s)
	(d = get(kw, :dip, nothing))    === nothing && error("'dip' must be specified"); dip = Float64(d)
	(l = get(kw, :L, nothing))      === nothing && error("'L' must be specified"); L = Float64(l)
	(w = get(kw, :W, nothing))      === nothing && error("'W' must be specified"); W = Float64(w)
	(r = get(kw, :rake, nothing))   === nothing && error("'rake' must be specified"); rake = Float64(r)
	(s = get(kw, :slip, nothing))   === nothing && error("'slip' must be specified"); slip = Float64(s)
	(n = get(kw, :nu, 0.25)); nu = Float64(n)
	U3 = get(kw, :open, 0.0);
	do_all3 = (get(kw, :enz, nothing) !== nothing)

	if (do_all3)
		okada_enz(x, y, W, L, depth, strike, dip, rake, slip, nu, Float64(U3))
	else
		okada_z(x, y, W, L, depth, strike, dip, rake, slip, nu, Float64(U3))
	end
end

#---------------------------------------------------------------------------------------------------
function okada_geog_z(e::Vector{Float64}, n::Vector{Float64}, W, L, depth, strike, dip, rake, slip, nu, xc, yc, U3)
	U1, U2, sin_dip, cos_dip, sin_strike, cos_strike, ct1, ct2, ct3, ct4, ct5 =
		preokada(depth, strike, dip, rake, slip, W)
	
	mat = Matrix{Float32}(undef, length(n), length(e))
	if (U3 == 0.0)
		@inbounds Threads.@threads for col = 1:length(e)
			@inbounds for row = 1:length(n)
				e1, n1, _ = geodetic2enu(e[col], n[row], 0.0, xc, yc, 0.0)
				x, p, q = xy2okada(e1, n1, sin_dip, cos_dip, sin_strike, cos_strike, L, ct1, ct2, ct3, ct4, ct5)
				mat[row,col] = okd_uz(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
			end
		end
	else
		U3 /= (2*pi)		# Move the "/(2*pi)" term from ukd_u?? to here
		@inbounds Threads.@threads for col = 1:length(e)
			@inbounds for row = 1:length(n)
				e1, n1, _ = geodetic2enu(e[col], n[row], 0.0, xc, yc, 0.0)
				x, p, q = xy2okada(e1, n1, sin_dip, cos_dip, sin_strike, cos_strike, L, ct1, ct2, ct3, ct4, ct5)
				mat[row,col] = okd_uz(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
			end
		end
	end
	return mat
end

#= ---------------------------------------------------------------------------------------------------
function okada_geog_enz(e::Vector{Float64}, n::Vector{Float64}, W, L, depth, strike, dip, rake, slip, nu, xc, yc, U3)
	# This method computes the 3 components of the deformation
	U1, U2, sin_dip, cos_dip, sin_strike, cos_strike, ct1, ct2, ct3, ct4, ct5 =
		preokada(depth, strike, dip, rake, slip, W)

	ue = Matrix{Float32}(undef, length(n), length(e))
	un = Matrix{Float32}(undef, length(n), length(e))
	uz = Matrix{Float32}(undef, length(n), length(e))
	if (U3 == 0.0)
		@inbounds Threads.@threads for col = 1:length(e)
			@inbounds for row = 1:length(n)
				e1, n1, _ = geodetic2enu(e[col], n[row], 0.0, xc, yc, 0.0)
				x, p, q = xy2okada(e1, n1, sin_dip, cos_dip, sin_strike, cos_strike, L, ct1, ct2, ct3, ct4, ct5)
				ue[row,col], un[row,col], uz[row,col] = helper_okada2_enz(U1, U2, x, p, q, L, W, sin_dip, cos_dip, sin_strike, cos_strike, nu)
			end
		end
	else
		U3 /= (2*pi)		# Move the "/(2*pi)" term from ukd_u?? to here
		@inbounds Threads.@threads for col = 1:length(e)
			@inbounds for row = 1:length(n)
				e1, n1, _ = geodetic2enu(e[col], n[row], 0.0, xc, yc, 0.0)
				x, p, q = xy2okada(e1, n1, sin_dip, cos_dip, sin_strike, cos_strike, L, ct1, ct2, ct3, ct4, ct5)
				ue[row,col], un[row,col], uz[row,col] = helper_okada3_enz(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, sin_strike, cos_strike, nu)
			end
		end
	end
	return ue, un, uz
end
=#

function helper_okada2_enz(U1, U2, x, p, q, L, W, sin_dip, cos_dip, sin_strike, cos_strike, nu)
	uz = okd_uz(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	ux = okd_ux(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	uy = okd_uy(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	ue = ux * sin_strike - uy * cos_strike			# Rotation from Okada's axes to geographic
	un = ux * cos_strike + uy * sin_strike
	return ue, un, uz
end

function helper_okada3_enz(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, sin_strike, cos_strike, nu)
	uz = okd_uz(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
	ux = okd_ux(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
	uy = okd_uy(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
	ue = ux * sin_strike - uy * cos_strike
	un = ux * cos_strike + uy * sin_strike
	return ue, un, uz
end

#---------------------------------------------------------------------------------------------------
# The non-geog case.
function okada_z(e::Vector{Float64}, n::Vector{Float64}, W, L, depth, strike, dip, rake, slip, nu, U3)
	U1, U2, sin_dip, cos_dip, sin_strike, cos_strike, ct1, ct2, ct3, ct4, ct5 =
		preokada(depth, strike, dip, rake, slip, W)
	mat = Matrix{Float32}(undef, length(n), length(e))
	if (U3 == 0.0)
		@inbounds Threads.@threads for col = 1:length(e)
			@inbounds for row = 1:length(n)
				x, p, q = xy2okada(e[col], n[row], sin_dip, cos_dip, sin_strike, cos_strike, L, ct1, ct2, ct3, ct4, ct5)
				mat[row,col] = okd_uz(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
			end
		end
	else
		U3 /= (2*pi)		# Move the "/(2*pi)" term from ukd_u?? to here
		@inbounds Threads.@threads for col = 1:length(e)
			@inbounds for row = 1:length(n)
				x, p, q = xy2okada(e[col], n[row], sin_dip, cos_dip, sin_strike, cos_strike, L, ct1, ct2, ct3, ct4, ct5)
				mat[row,col] = okd_uz(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
			end
		end
	end
	return mat
end

function okada_enz(e::Vector{Float64}, n::Vector{Float64}, W, L, depth, strike, dip, rake, slip, nu, U3)
	U1, U2, sin_dip, cos_dip, sin_strike, cos_strike, ct1, ct2, ct3, ct4, ct5 =
		preokada(depth, strike, dip, rake, slip, W)
	ue = Matrix{Float32}(undef, length(n), length(e))
	un = Matrix{Float32}(undef, length(n), length(e))
	uz = Matrix{Float32}(undef, length(n), length(e))
	if (U3 == 0.0)
		@inbounds Threads.@threads for col = 1:length(e)
			@inbounds for row = 1:length(n)
				x, p, q = xy2okada(e[col], n[row], sin_dip, cos_dip, sin_strike, cos_strike, L, ct1, ct2, ct3, ct4, ct5)
				ue[row,col], un[row,col], uz[row,col] = helper_okada2_enz(U1, U2, x, p, q, L, W, sin_dip, cos_dip, sin_strike, cos_strike, nu)
			end
		end
	else
		U3 /= (2*pi)		# Move the "/(2*pi)" term from ukd_u?? to here
		@inbounds Threads.@threads for col = 1:length(e)
			@inbounds for row = 1:length(n)
				x, p, q = xy2okada(e[col], n[row], sin_dip, cos_dip, sin_strike, cos_strike, L, ct1, ct2, ct3, ct4, ct5)
				ue[row,col], un[row,col], uz[row,col] = helper_okada3_enz(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, sin_strike, cos_strike, nu)
			end
		end
	end
	return ue, un, uz
end

#---------------------------------------------------------------------------------------------------
function preokada(depth, strike, dip, rake, slip, W)
	# Pre-computes Okada's model geometric parameters.
	strike = strike*pi/180
	dip    = dip * pi/180
	rake   = rake * pi/180

	sin_dip, cos_dip       = sin(dip), cos(dip)
	sin_strike, cos_strike = sin(strike), cos(strike)

	# Defines dislocation in the fault plane system
	U1 = cos(rake) * slip / (2*pi)		# Move the "/(2*pi)" term from ukd_u?? to here
	U2 = sin(rake) * slip / (2*pi)
	d = depth + sin_dip * W/2			# d is fault's top edge (this cannot be true. Looks like bottom edge)
	ct1 = cos_strike * cos_dip * W/2
	ct2 = sin_strike * cos_dip * W/2
	ct3 = W * cos_dip
	ct4 = d * sin_dip
	ct5 = d * cos_dip

	return U1, U2, sin_dip, cos_dip, sin_strike, cos_strike, ct1, ct2, ct3, ct4, ct5
end


function xy2okada(e, n, sin_dip, cos_dip, sin_strike, cos_strike, L, ct1, ct2, ct3, ct4, ct5)
	# Converts fault coordinates (E,N,DEPTH) relative to centroid into Okada's reference system (X,Y,D)
	ec = e + ct1			# ct1 = cos_strike * cos_dip * W/2
	nc = n - ct2			# ct2 = sin_strike * cos_dip * W/2
	x = cos_strike * nc + sin_strike * ec + L/2
	y = sin_strike * nc - cos_strike * ec + ct3		# ct3 = W * cos_dip
	# Variable substitution (independent from xi and eta)
	p = y * cos_dip + ct4	# ct4 = d * sin_dip
	q = y * sin_dip - ct5	# ct5 = d * cos_dip
	return x, p, q
end

# Notes for I... and K... subfunctions:
#	1. original formulas use Lame's parameters as mu/(mu+lambda) which
#	   depends only on the Poisson's ratio = 1 - 2*nu
#	2. tests for cos(dip) == 0 are made with "cos(dip) > eps"
#	   because cos(90*pi/180) is not zero but = 6.1232e-17 (!)

chinnery(f::Function, x, p, L, W, q, sin_dip, cos_dip, nu) =
	f(x,p,q,sin_dip, cos_dip,nu) - f(x,p-W,q,sin_dip, cos_dip,nu) - f(x-L,p,q,sin_dip, cos_dip,nu) + f(x-L,p-W,q,sin_dip, cos_dip,nu)


#---------------------------------------------------------------------------------------------------
# Displacements
function okd_ux(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
	ux = (-U1 * chinnery(ux_ss,x,p,L,W,q,sin_dip, cos_dip,nu)		# strike-slip
	      -U2 * chinnery(ux_ds,x,p,L,W,q,sin_dip, cos_dip,nu)		# dip-slip
	      +U3 * chinnery(ux_tf,x,p,L,W,q,sin_dip, cos_dip,nu))		# tensile fault
end
function okd_ux(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	(-U1 * chinnery(ux_ss,x,p,L,W,q,sin_dip, cos_dip,nu)			# strike-slip
	 -U2 * chinnery(ux_ds,x,p,L,W,q,sin_dip, cos_dip,nu))			# dip-slip
end

function okd_uy(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
	uy = (-U1 * chinnery(uy_ss,x,p,L,W,q,sin_dip, cos_dip,nu)		# strike-slip
	      -U2 * chinnery(uy_ds,x,p,L,W,q,sin_dip, cos_dip,nu)		# dip-slip
	      +U3 * chinnery(uy_tf,x,p,L,W,q,sin_dip, cos_dip,nu))		# tensile fault
end
function okd_uy(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	(-U1 * chinnery(uy_ss,x,p,L,W,q,sin_dip, cos_dip,nu)			# strike-slip
	 -U2 * chinnery(uy_ds,x,p,L,W,q,sin_dip, cos_dip,nu))			# dip-slip
end

function okd_uz(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
	uz = (-U1 * chinnery(uz_ss,x,p,L,W,q,sin_dip, cos_dip,nu)		# strike-slip
	      -U2 * chinnery(uz_ds,x,p,L,W,q,sin_dip, cos_dip,nu)		# dip-slip
	      +U3 * chinnery(uz_tf,x,p,L,W,q,sin_dip, cos_dip,nu))		# tensile fault
end
function okd_uz(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	(-U1 * chinnery(uz_ss,x,p,L,W,q,sin_dip, cos_dip,nu)			# strike-slip
	 -U2 * chinnery(uz_ds,x,p,L,W,q,sin_dip, cos_dip,nu))			# dip-slip
end


#---------------------------------------------------------------------------------------------------
# Tilt
function okd_uzx(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
	uzx =(-U1 * chinnery(uzx_ss,x,p,L,W,q,sin_dip, cos_dip,nu)		# strike-slip
	      -U2 * chinnery(uzx_ds,x,p,L,W,q,sin_dip, cos_dip,nu)		# dip-slip
	      +U3 * chinnery(uzx_tf,x,p,L,W,q,sin_dip, cos_dip,nu))		# tensile fault
end
function okd_uzx(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	(-U1 * chinnery(uzx_ss,x,p,L,W,q,sin_dip, cos_dip,nu)
	 -U2 * chinnery(uzx_ds,x,p,L,W,q,sin_dip, cos_dip,nu))
end

function okd_uzy(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
	uzy =(-U1 * chinnery(uzy_ss,x,p,L,W,q,sin_dip, cos_dip,nu)		# strike-slip
	      -U2 * chinnery(uzy_ds,x,p,L,W,q,sin_dip, cos_dip,nu)		# dip-slip
	      +U3 * chinnery(uzy_tf,x,p,L,W,q,sin_dip, cos_dip,nu))		# tensile fault
end
function okd_uzy(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	(-U1 * chinnery(uzy_ss,x,p,L,W,q,sin_dip, cos_dip,nu)
	 -U2 * chinnery(uzy_ds,x,p,L,W,q,sin_dip, cos_dip,nu))
end

# Rotation from Okada's axes to geographic
#uze = -sin(strike)*uzx + cos(strike)*uzy
#uzn = -cos(strike)*uzx - sin(strike)*uzy

#---------------------------------------------------------------------------------------------------
# Strain
function okd_uxx(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
	uxx = (-U1 * chinnery(uxx_ss,x,p,L,W,q,sin_dip, cos_dip,nu)		# strike-slip
	       -U2 * chinnery(uxx_ds,x,p,L,W,q,sin_dip, cos_dip,nu)		# dip-slip
	       +U3 * chinnery(uxx_tf,x,p,L,W,q,sin_dip, cos_dip,nu))	# tensile fault
end
function okd_uxx(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	(-U1 * chinnery(uxx_ss,x,p,L,W,q,sin_dip, cos_dip,nu)
	 -U2 * chinnery(uxx_ds,x,p,L,W,q,sin_dip, cos_dip,nu))
end

function okd_uxy(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
	uxy = (-U1 * chinnery(uxy_ss,x,p,L,W,q,sin_dip, cos_dip,nu)		# strike-slip
	       -U2 * chinnery(uxy_ds,x,p,L,W,q,sin_dip, cos_dip,nu)		# dip-slip
	       +U3 * chinnery(uxy_tf,x,p,L,W,q,sin_dip, cos_dip,nu))	# tensile fault
end
function okd_uxy(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	(-U1 * chinnery(uxy_ss,x,p,L,W,q,sin_dip, cos_dip,nu)
	 -U2 * chinnery(uxy_ds,x,p,L,W,q,sin_dip, cos_dip,nu))
end

function okd_uyx(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
	uyx = (-U1 * chinnery(uyx_ss,x,p,L,W,q,sin_dip, cos_dip,nu)		# strike-slip
	       -U2 * chinnery(uyx_ds,x,p,L,W,q,sin_dip, cos_dip,nu)		# dip-slip
	       +U3 * chinnery(uyx_tf,x,p,L,W,q,sin_dip, cos_dip,nu))	# tensile fault
end
function okd_uyx(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	(-U1 * chinnery(uyx_ss,x,p,L,W,q,sin_dip, cos_dip,nu)
	 -U2 * chinnery(uyx_ds,x,p,L,W,q,sin_dip, cos_dip,nu))
end

function okd_uyy(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
	uyy = (-U1 * chinnery(uyy_ss,x,p,L,W,q,sin_dip, cos_dip,nu)		# strike-slip
	       -U2 * chinnery(uyy_ds,x,p,L,W,q,sin_dip, cos_dip,nu)		# dip-slip
		   +U3 * chinnery(uyy_tf,x,p,L,W,q,sin_dip, cos_dip,nu))	# tensile fault
end
function okd_uyy(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	(-U1 * chinnery(uyy_ss,x,p,L,W,q,sin_dip, cos_dip,nu)
	 -U2 * chinnery(uyy_ds,x,p,L,W,q,sin_dip, cos_dip,nu))
end

# Rotation from Okada's axes to geographic
#unn = cos(strike)^2*uxx + sin(2*strike)*(uxy+uyx)/2 + sin(strike)^2*uyy
#une = sin(2*strike)*(uxx-uyy)/2 + sin(strike)^2*uyx - cos(strike)^2*uxy
#uen = sin(2*strike)*(uxx-uyy)/2 - cos(strike)^2*uyx + sin(strike)^2*uxy
#uee = sin(strike)^2*uxx - sin(2*strike)*(uyx+uxy)/2 + cos(strike)^2*uyy

#---------------------------------------------------------------------------------------------------
# Displacement subfunctions
# strike-slip displacement subfunctions [equation (25) p. 1144]
function ux_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = xi*q/(R*(R + eta)) + I1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip
	if (q != 0)
		u += atan(xi*eta/(q*R))
	end
	return u
end

function uy_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	(eta*cos_dip + q*sin_dip)*q/(R*(R + eta)) + q*cos_dip/(R + eta)+ I2(eta,q,sin_dip, cos_dip,nu,R)*sin_dip
end

function uz_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	db*q/(R*(R + eta)) + q*sin_dip/(R + eta) + I4(db,eta,q,sin_dip, cos_dip,nu,R)*sin_dip
end

#---------------------------------------------------------------------------------------------------
# dip-slip displacement subfunctions [equation (26) p. 1144]
function ux_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	q/R - I3(eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
end

function uy_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = (eta*cos_dip + q*sin_dip)*q/(R*(R + xi)) - I1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
	if (q != 0)
		u += cos_dip*atan(xi*eta/(q*R))
	end
	return u
end
function uz_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	u = db*q/(R*(R + xi)) - I5(xi,eta,q,sin_dip, cos_dip,nu,R,db)*sin_dip*cos_dip
	if (q != 0)
		u += sin_dip*atan(xi*eta/(q*R))
	end
	return u
end

#---------------------------------------------------------------------------------------------------
# tensile fault displacement subfunctions [equation (27) p. 1144]
function ux_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	q^2 /(R*(R + eta)) - I3(eta,q,sin_dip, cos_dip,nu,R)*sin_dip^2
end

function uy_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = -(eta*sin_dip - q*cos_dip)*q/(R*(R + xi)) - sin_dip*xi*q/(R*(R + eta)) - I1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip^2
	if (q != 0)
		u += sin_dip*atan(xi*eta/(q*R))
	end
	return u
end

function uz_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	u = (eta*cos_dip + q*sin_dip)*q/(R*(R + xi)) + cos_dip*xi*q/(R*(R + eta)) - I5(xi,eta,q,sin_dip, cos_dip,nu,R,db)*sin_dip^2
	if (q != 0)
		u -= cos_dip*atan(xi*eta/(q*R))
	end
	return u
end

#---------------------------------------------------------------------------------------------------
# I... displacement subfunctions [equations (28) (29) p. 1144-1145]
function I1(xi,eta,q,sin_dip, cos_dip,nu,R)
	db = eta*sin_dip - q*cos_dip
	if cos_dip > eps()
		I = (1 - 2*nu) * (-xi/(cos_dip*(R + db))) - sin_dip/cos_dip * I5(xi,eta,q,sin_dip, cos_dip,nu,R,db)
	else
		I = -(1 - 2*nu)/2 * xi*q/(R + db)^2
	end
	return I
end

I2(eta,q,sin_dip, cos_dip,nu,R) = (1 - 2*nu) * (-log(R + eta)) - I3(eta,q,sin_dip, cos_dip,nu,R)

function I3(eta,q,sin_dip, cos_dip,nu,R)
	yb = eta*cos_dip + q*sin_dip
	db = eta*sin_dip - q*cos_dip
	if cos_dip > eps()
		I = (1 - 2*nu) * (yb/(cos_dip*(R + db)) - log(R + eta)) + sin_dip/cos_dip * I4(db,eta,q,sin_dip, cos_dip,nu,R)
	else
		I = (1 - 2*nu)/2 * (eta/(R + db) + yb*q/(R + db)^2 - log(R + eta))
	end
	return I
end

function I4(db,eta,q,sin_dip, cos_dip,nu,R)
	if cos_dip > eps()
		I = (1 - 2*nu) * 1 / cos_dip * (log(R + db) - sin_dip*log(R + eta))
	else
		I = -(1 - 2*nu) * q / (R + db)
	end
	return I
end

function I5(xi,eta,q,sin_dip, cos_dip,nu,R,db)
	X = sqrt(xi^2 + q^2)
	if cos_dip > eps()
		I = (1 - 2*nu) * 2 / cos_dip * atan((eta*(X + q*cos_dip) + X*(R + X)*sin_dip) /(xi*(R + X)*cos_dip))
		xi == 0 && (I = 0)
	else
		I = -(1 - 2*nu) * xi*sin_dip/(R + db)
	end
	return I
end

#=
#---------------------------------------------------------------------------------------------------
# Tilt subfunctions
# strike-slip tilt subfunctions [equation (37) p. 1147]
function uzx_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	-xi * q ^ 2 * A(eta,R)*cos_dip + ((xi*q)/R^3 - K1(xi,eta,q,sin_dip, cos_dip,nu,R))*sin_dip
end

function uzy_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	yb = eta*cos_dip + q*sin_dip
	(db*q/R^3)*cos_dip + (xi ^ 2 * q*A(eta,R)*cos_dip - sin_dip/R + yb*q/R^3 - K2(xi,eta,q,dip,nu,R))*sin_dip
end

#---------------------------------------------------------------------------------------------------
# dip-slip tilt subfunctions [equation (38) p. 1147]
function uzx_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	db*q/R^3 + q*sin_dip/(R*(R + eta)) + K3(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
end

function uzy_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	yb = eta*cos_dip + q*sin_dip
	yb*db*q*A(xi,R) - (2*db/(R*(R + xi)) + xi*sin_dip/(R*(R + eta)))*sin_dip + K1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
end

#---------------------------------------------------------------------------------------------------
# tensile fault tilt subfunctions [equation (39) p. 1147]
function uzx_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	q ^ 2 /R ^ 3 * sin_dip - q ^ 3 *A(eta,R)*cos_dip + K3(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip^2
end

function uzy_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	yb = eta*cos_dip + q*sin_dip
	(yb*sin_dip + db*cos_dip)*q ^ 2 *A(xi,R) + xi*q ^ 2 *A(eta,R)*sin_dip*cos_dip - (2*q/(R*(R + xi)) - K1(xi,eta,q,sin_dip, cos_dip,nu,R))*sin_dip^2
end

A(x,R) = (2*R + x)/(R ^ 3 *(R + x)^2)

#---------------------------------------------------------------------------------------------------
#  K... tilt subfunctions [equations (40) (41) p. 1148]
function K1(xi,eta,q,sin_dip, cos_dip,nu,R)
	db = eta*sin_dip - q*cos_dip
	if cos_dip > eps()
		K = (1 - 2*nu) * xi/cos_dip * (1 / (R*(R + db)) - sin_dip/(R*(R + eta)))
	else
		K = (1 - 2*nu) * xi*q/(R*(R + db)^2)
	end
	return K
end

K2(xi,eta,q,sin_dip, cos_dip,nu,R) = (1 - 2*nu) * (-sin_dip/R + q*cos_dip/(R*(R + eta))) - K3(xi,eta,q,sin_dip, cos_dip,nu,R)

function K3(xi,eta,q,sin_dip, cos_dip,nu,R)
	db = eta*sin_dip - q*cos_dip
	yb = eta*cos_dip + q*sin_dip
	if cos_dip > eps()
		K = (1 - 2*nu) * 1 /cos_dip * (q/(R*(R + eta)) - yb/(R*(R + db)))
	else
		K = (1 - 2*nu) * sin_dip/(R + db) * (xi^ 2 /(R*(R + db)) - 1)
	end
	return K
end


#---------------------------------------------------------------------------------------------------
# Strain subfunctions
# strike-slip strain subfunctions [equation (31) p. 1145]

function uxx_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2);
	xi ^ 2 * q * A(eta,R) - J1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip
end

function uxy_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	xi ^3 * db/(R ^ 3 *(eta ^ 2 + q ^ 2))- (xi ^ 3 *A(eta,R) + J2(xi,eta,q,sin_dip, cos_dip,nu,R))*sin_dip
end

function uyx_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	xi * q / R ^ 3 * cos_dip + (xi * q ^ 2 * A(eta,R) - J2(xi,eta,q,sin_dip, cos_dip,nu,R))*sin_dip
end

function uyy_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	yb = eta*cos_dip + q*sin_dip
	yb * q / R ^ 3 * cos_dip + (q ^ 3 * A(eta,R)*sin_dip - 2*q*sin_dip/(R*(R + eta)) - (xi^2 + eta^2)/ R ^ 3 * cos_dip - J4(xi,eta,q,sin_dip, cos_dip,nu,R))*sin_dip
end

#---------------------------------------------------------------------------------------------------
# dip-slip strain subfunctions [equation (32) p. 1146]
function uxx_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	xi*q/R^3 + J3(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
end

function uxy_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	yb = eta*cos_dip + q*sin_dip
	yb*q/R^3 - sin_dip/R + J1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
end

function uyx_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	yb = eta*cos_dip + q*sin_dip
	yb*q/R^3 + q*cos_dip/(R*(R + eta)) + J1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
end

function uyy_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	yb = eta*cos_dip + q*sin_dip
	yb ^ 2 * q * A(xi,R) - (2*yb/(R*(R + xi)) + xi*cos_dip/(R*(R + eta)))*sin_dip + J2(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
end

#---------------------------------------------------------------------------------------------------
# tensile fault strain subfunctions [equation (33) p. 1146]
function uxx_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	xi * q ^ 2 * A(eta,R) + J3(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip^2
end

function uxy_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	-db*q/ R ^ 3 - xi^ 2 *q*A(eta,R)*sin_dip + J1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip^2
end

function uyx_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	q ^ 2 /R ^ 3 *cos_dip + q ^ 3 * A(eta,R)*sin_dip + J1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip^2
end

function uyy_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	yb = eta*cos_dip + q*sin_dip
	(yb * cos_dip - db*sin_dip) * q ^ 2 * A(xi,R) - q*sin(2*dip)/(R*(R + xi)) - (xi * q ^ 2 *A(eta,R) - J2(xi,eta,q,sin_dip, cos_dip,nu,R))*sin_dip^2
end

#---------------------------------------------------------------------------------------------------
# J... tensile fault subfunctions [equations (34) (35) p. 1146-1147]
function J1(xi,eta,q,sin_dip, cos_dip,nu,R)
	db = eta*sin_dip - q*cos_dip
	if cos_dip > eps()
		J = (1 - 2*nu) * 1 /cos_dip * (xi ^ 2 /(R*(R + db)^2) - 1 /(R + db)) - sin_dip/cos_dip*K3(xi,eta,q,sin_dip, cos_dip,nu,R)
	else
		J = (1 - 2*nu)/2 * q/(R + db)^2 * (2 * xi ^ 2 /(R*(R + db)) - 1)
	end
	return J
end

function J2(xi,eta,q,sin_dip, cos_dip,nu,R)
	db = eta*sin_dip - q*cos_dip
	yb = eta*cos_dip + q*sin_dip
	if cos_dip > eps()
		J = (1 - 2*nu) * 1 /cos_dip * xi*yb/(R*(R + db)^2) - sin_dip/cos_dip*K1(xi,eta,q,sin_dip, cos_dip,nu,R)
	else
		J = (1 - 2*nu)/2 * xi*sin_dip/(R + db)^ 2 * (2*q ^ 2 /(R*(R + db)) - 1)
	end
	return J
end

J3(xi,eta,q,sin_dip, cos_dip,nu,R) = (1 - 2*nu) * -xi/(R*(R + eta)) - J2(xi,eta,q,sin_dip, cos_dip,nu,R)

J4(xi,eta,q,sin_dip, cos_dip,nu,R) = (1 - 2*nu) * (-cos_dip/R - q*sin_dip/(R*(R + eta))) - J1(xi,eta,q,sin_dip, cos_dip,nu,R)
=#