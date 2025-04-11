"""
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
	okada(G, x_start, y_start, W, L, depth, strike, dip, rake, slip, nu)
end

function okada(G::GMTgrid, x_start::Float64, y_start::Float64, W::Float64, L::Float64, depth::Float64,
               strike::Float64, dip::Float64, rake::Float64, slip::Float64, nu::Float64)
	x = (G.registration == 0) ? copy(G.x) : collect(linspace(G.range[1]+G.inc[1]/2, G.range[2]-G.inc[1]/2, size(G,2)))
	y = (G.registration == 0) ? copy(G.y) : collect(linspace(G.range[3]+G.inc[2]/2, G.range[4]-G.inc[2]/2, size(G,1)))
	L *= 1000; W *= 1000; depth *= 1000;		# Convert to meters
	depth = depth + sind(dip) * W/2

	if (isgeog(G))
		fault_top_center, = geod([x_start y_start], strike, L/2)			# lon,lat of fault's top center
		fault_LL, = geod([x_start y_start], strike+90, W*cosd(dip))			# fault LowerLeft corner
		fault_bot_center, = geod([fault_LL[1] fault_LL[2]], strike, L/2)
		x_centroid = (fault_top_center[1] + fault_bot_center[1]) / 2
		y_centroid = (fault_top_center[2] + fault_bot_center[2]) / 2
		#@show x_centroid, y_centroid
		#@show fault_top_center
		#@show fault_bot_center
		#@show fault_LL

		#x .-= x_centroid;	y .-= y_centroid;				# Translate coordinates to fault's centroid
		#ind_x, ind_y = div(length(x), 2), div(length(y), 2)
		#xy_x = [x fill(y[ind_y], length(x))]
		#xy_y = [fill(x[ind_x], length(y)) y]
		#xc, yc = fault_top_center[1], fault_top_center[2]
		xc, yc = x_centroid, y_centroid
		#xc, yc = 0, 0
		#t_srs = "+proj=cea +ellps=GRS80 +lat_ts=$y_centroid"
		t_srs = "+proj=tmerc +ellps=WGS84 +lon_0=$xc +lat_0=$yc"
		#x = lonlat2xy(xy_x, t_srs=t_srs)[:,1]
		#y = lonlat2xy(xy_y, t_srs=t_srs)[:,2]
		#x = mapproject(xy_x, J=t_srs)[:,1]
		#y = mapproject(xy_y, J=t_srs)[:,2]
		mat = _okada_geog(x, y, W, L, depth, strike, dip, rake, slip, nu, xc, yc)
	else
		mat = _okada(x, y, W, L, depth, strike, dip, rake, slip, nu)
	end
	rng = [G.range[1:4]..., extrema(mat)...]
	return GMTgrid(proj4=prj4WGS84, range=rng, inc=G.inc, registration=G.registration, title="Okada vertical deformation", x=G.x, y=G.y, z=mat, layout="BCB", hasnans=1)
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
	_okada(x, y, W, L, depth, strike, dip, rake, slip, nu)
end

function _okada_geog(e::Vector{Float64}, n::Vector{Float64}, W, L, depth, strike, dip, rake, slip, nu, xc, yc)
	U1, U2, sin_dip, cos_dip, sin_strike, cos_strike, ct1, ct2, ct3, ct4, ct5 =
		preokada(depth, strike, dip, rake, slip, W)
	
	mat = Matrix{Float32}(undef, length(n), length(e))
	@inbounds Threads.@threads for col = 1:length(e)
		@inbounds for row = 1:length(n)
			e1, n1, _ = geodetic2enu(e[col], n[row], 0.0, xc, yc, 0.0)
			x, p, q = xy2okada(e1, n1, sin_dip, cos_dip, sin_strike, cos_strike, L, ct1, ct2, ct3, ct4, ct5)
			mat[row,col] = okd_uz(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
		end
	end
	return mat
end

function _okada(e::Vector{Float64}, n::Vector{Float64}, W, L, depth, strike, dip, rake, slip, nu)
	U1, U2, sin_dip, cos_dip, sin_strike, cos_strike, ct1, ct2, ct3, ct4, ct5 =
		preokada(depth, strike, dip, rake, slip, W)
	mat = Matrix{Float32}(undef, length(n), length(e))
	for j = 1:length(e), i = 1:length(n)
		x, p, q = xy2okada(e[j], n[i], sin_dip, cos_dip, sin_strike, cos_strike, L, ct1, ct2, ct3, ct4, ct5)
		mat[i,j] = okd_uz(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	end
	return mat
end

function preokada(depth, strike, dip, rake, slip, W)
	# Pre-computes Okada's model for dislocation in a homogeneous elastic half-space
	strike = strike*pi/180
	dip    = dip * pi/180        # converting DIP in radian ('delta' in Okada's equations)
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

# Tests
#x=2; y=3; W = 2; L=3; depth=4; strike=90; dip=70; rake=0; slip=1; 
#GMT.okada([x-L/2], [y-cosd(dip)*W/2], depth=depth-sind(dip)*W/2, strike=strike, dip=dip, L=L, W=W, rake=rake, slip=slip) == -0.0024518357


function okd_uz(U1, U2, U3, x, p, q, L, W, sin_dip, cos_dip, nu)
	uz = (-U1 * chinnery(uz_ss,x,p,L,W,q,sin_dip, cos_dip,nu) # strike-slip
	      -U2 * chinnery(uz_ds,x,p,L,W,q,sin_dip, cos_dip,nu) # dip-slip
	      +U3 * chinnery(uz_tf,x,p,L,W,q,sin_dip, cos_dip,nu)) # tensile fault
end
function okd_uz(U1, U2, x, p, q, L, W, sin_dip, cos_dip, nu)
	(-U1 * chinnery(uz_ss,x,p,L,W,q,sin_dip, cos_dip,nu) # strike-slip
	 -U2 * chinnery(uz_ds,x,p,L,W,q,sin_dip, cos_dip,nu)) # dip-slip
end
	
chinnery(f::Function, x, p, L, W, q, sin_dip, cos_dip, nu) = f(x,p,q,sin_dip, cos_dip,nu) - f(x,p-W,q,sin_dip, cos_dip,nu) - f(x-L,p,q,sin_dip, cos_dip,nu) + f(x-L,p-W,q,sin_dip, cos_dip,nu)

"""
Displacement subfunctions
strike-slip displacement subfunctions [equation (25) p. 1144]
"""
function ux_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = xi*q/(R*(R + eta)) + I1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip
	if q != 0
		u = u + atan(xi*eta/(q*R))
	end
	return u
end

function uy_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = (eta*cos_dip + q*sin_dip)*q/(R*(R + eta)) + q*cos_dip/(R + eta)+ I2(eta,q,sin_dip, cos_dip,nu,R)*sin_dip
	return u
end

function uz_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	u = db*q/(R*(R + eta)) + q*sin_dip/(R + eta) + I4(db,eta,q,sin_dip, cos_dip,nu,R)*sin_dip
	return u
end

"""
dip-slip displacement subfunctions [equation (26) p. 1144]
"""
function ux_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = q/R - I3(eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
	return u
end

function uy_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = (eta*cos_dip + q*sin_dip)*q/(R*(R + xi)) - I1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
	if q!=0
		u = u + cos_dip*atan(xi*eta/(q*R))
	end
	return u
end
function uz_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	u = db*q/(R*(R + xi)) - I5(xi,eta,q,sin_dip, cos_dip,nu,R,db)*sin_dip*cos_dip
	if q!=0
		u = u + sin_dip*atan(xi*eta/(q*R))
	end
	return u
end

"""
tensile fault displacement subfunctions [equation (27) p. 1144]
"""
function ux_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = q^2 /(R*(R + eta)) - I3(eta,q,sin_dip, cos_dip,nu,R)*sin_dip^2
	return u
end

function uy_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = -(eta*sin_dip - q*cos_dip)*q/(R*(R + xi)) - sin_dip*xi*q/(R*(R + eta)) - I1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip^2
	if q!=0
		u = u + sin_dip*atan(xi*eta/(q*R))
	end
	return u
end

function uz_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	u = (eta*cos_dip + q*sin_dip)*q/(R*(R + xi)) + cos_dip*xi*q/(R*(R + eta)) - I5(xi,eta,q,sin_dip, cos_dip,nu,R,db)*sin_dip^2
	if q!=0
		u = u - cos_dip*atan(xi*eta/(q*R))
	end
	return u
end

"""
I... displacement subfunctions [equations (28) (29) p. 1144-1145]
"""
function I1(xi,eta,q,sin_dip, cos_dip,nu,R)
	db = eta*sin_dip - q*cos_dip
	if cos_dip > eps()
		I = (1 - 2*nu) * (-xi/(cos_dip*(R + db)))- sin_dip/cos_dip*I5(xi,eta,q,sin_dip, cos_dip,nu,R,db)
	else
		I = -(1 - 2*nu)/2 * xi*q/(R + db)^2
	end
	return I
end

function I2(eta,q,sin_dip, cos_dip,nu,R)
	return (1 - 2*nu) * (-log(R + eta)) - I3(eta,q,sin_dip, cos_dip,nu,R)
end

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

"""
 Tilt subfunctions
 strike-slip tilt subfunctions [equation (37) p. 1147]
"""
function uzx_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = -xi * q ^ 2 * A(eta,R)*cos_dip + ((xi*q)/R^3 - K1(xi,eta,q,sin_dip, cos_dip,nu,R))*sin_dip
	return u
end

function uzy_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	yb = eta*cos_dip + q*sin_dip
	u = (db*q/R^3)*cos_dip + (xi ^ 2 * q*A(eta,R)*cos_dip - sin_dip/R + yb*q/R^3 - K2(xi,eta,q,dip,nu,R))*sin_dip
	return u
end

"""
 dip-slip tilt subfunctions [equation (38) p. 1147]
"""
function uzx_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	u = db*q/R^3 + q*sin_dip/(R*(R + eta)) + K3(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
	return u
end

function uzy_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	yb = eta*cos_dip + q*sin_dip
	u = yb*db*q*A(xi,R) - (2*db/(R*(R + xi)) + xi*sin_dip/(R*(R + eta)))*sin_dip + K1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
	return u
end
"""
 tensile fault tilt subfunctions [equation (39) p. 1147]
"""
function uzx_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = q ^ 2 /R ^ 3 * sin_dip - q ^ 3 *A(eta,R)*cos_dip + K3(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip^2
	return u
end

function uzy_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	yb = eta*cos_dip + q*sin_dip
	u = (yb*sin_dip + db*cos_dip)*q ^ 2 *A(xi,R) + xi*q ^ 2 *A(eta,R)*sin_dip*cos_dip - (2*q/(R*(R + xi)) - K1(xi,eta,q,sin_dip, cos_dip,nu,R))*sin_dip^2
	return u
end

A(x,R) = (2*R + x)/(R ^ 3 *(R + x)^2)

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

function K2(xi,eta,q,sin_dip, cos_dip,nu,R)
	return (1 - 2*nu) * (-sin_dip/R + q*cos_dip/(R*(R + eta))) - K3(xi,eta,q,sin_dip, cos_dip,nu,R)
end

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


# Strain subfunctions
# strike-slip strain subfunctions [equation (31) p. 1145]

function uxx_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2);
	u = xi ^ 2 * q * A(eta,R) - J1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip
	return u
end

function uxy_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	u = xi ^3 * db/(R ^ 3 *(eta ^ 2 + q ^ 2))- (xi ^ 3 *A(eta,R) + J2(xi,eta,q,sin_dip, cos_dip,nu,R))*sin_dip
	return u
end

function uyx_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = xi * q / R ^ 3 * cos_dip + (xi * q ^ 2 * A(eta,R) - J2(xi,eta,q,sin_dip, cos_dip,nu,R))*sin_dip
	return u
end

function uyy_ss(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	yb = eta*cos_dip + q*sin_dip
	u = yb * q / R ^ 3 * cos_dip + (q ^ 3 * A(eta,R)*sin_dip - 2*q*sin_dip/(R*(R + eta)) - (xi^2 + eta^2)/ R ^ 3 * cos_dip - J4(xi,eta,q,sin_dip, cos_dip,nu,R))*sin_dip
	return u
end

# dip-slip strain subfunctions [equation (32) p. 1146]

function uxx_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = xi*q/R^3 + J3(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
	return u
end

function uxy_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	yb = eta*cos_dip + q*sin_dip
	u = yb*q/R^3 - sin_dip/R + J1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
	return u
end

function uyx_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	yb = eta*cos_dip + q*sin_dip
	u = yb*q/R^3 + q*cos_dip/(R*(R + eta)) + J1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
	return u
end

function uyy_ds(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	yb = eta*cos_dip + q*sin_dip
	u = yb ^ 2 * q * A(xi,R) - (2*yb/(R*(R + xi)) + xi*cos_dip/(R*(R + eta)))*sin_dip + J2(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip*cos_dip
	return u
end

# tensile fault strain subfunctions [equation (33) p. 1146]

function uxx_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = xi * q ^ 2 * A(eta,R) + J3(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip^2
	return u
end

function uxy_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	u = -db*q/ R ^ 3 - xi^ 2 *q*A(eta,R)*sin_dip + J1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip^2
	return u
end

function uyx_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	u = q ^ 2 /R ^ 3 *cos_dip + q ^ 3 * A(eta,R)*sin_dip + J1(xi,eta,q,sin_dip, cos_dip,nu,R)*sin_dip^2
	return u
end

function uyy_tf(xi,eta,q,sin_dip, cos_dip,nu)
	R = sqrt(xi^2 + eta^2 + q^2)
	db = eta*sin_dip - q*cos_dip
	yb = eta*cos_dip + q*sin_dip
	u = (yb * cos_dip - db*sin_dip) * q ^ 2 * A(xi,R) - q*sin(2*dip)/(R*(R + xi)) - (xi * q ^ 2 *A(eta,R) - J2(xi,eta,q,sin_dip, cos_dip,nu,R))*sin_dip^2
	return u
end

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

function J3(xi,eta,q,sin_dip, cos_dip,nu,R)
	return (1 - 2*nu) * -xi/(R*(R + eta)) - J2(xi,eta,q,sin_dip, cos_dip,nu,R)
end

function J4(xi,eta,q,sin_dip, cos_dip,nu,R)
	return (1 - 2*nu) * (-cos_dip/R - q*sin_dip/(R*(R + eta))) - J1(xi,eta,q,sin_dip, cos_dip,nu,R)
end