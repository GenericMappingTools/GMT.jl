# This file contains modified versions of some functions from the Comodo.jl package (Apache 2.0 license).
# https://github.com/COMODO-research/Comodo.jl
"""
    FV = icosahedron(r=1.0; radius=1.0, origin=(0.0, 0.0, 0.0))

Create an icosahedron mesh with radius `r`. 

### Args
- `r`: the radius of the enclosing sphere.

### Kwargs
- `radius`: the keyword `radius` is an alternative to the positional argument `r`.
- `origin`: A tuple of three numbers defining the origin of the body. Default is `(0.0, 0.0, 0.0)`.
"""
function icosahedron(r=1.0; radius=1.0, origin=(0.0, 0.0, 0.0))::GMTfv

	_r::Float64 = (radius != 1.0) ? radius : r		# If spelled, the `radius` kwarg take precedence
	o::Matrix{Float64} = [origin[1] origin[2] origin[3]]

	ϕ = Base.MathConstants.golden # (1.0+sqrt(5.0))/2.0, Golden ratio
	s = _r / sqrt(ϕ + 2.0)
	t = ϕ * s

	V =[0  -s -t				# The Vertices
		 0 -s  t
		 0  s  t
		 0  s -t
		-s -t  0
		-s  t  0
		 s  t  0
		 s -t  0
		-t  0 -s
		 t  0 -s
		 t  0  s
		-t  0  s]

	F = [9 4 1					# The Faces
		 1 5 9
		 1 8 5
		 10 8 1
		 4 10 1
		 5 2 12
		 12 2 3
		 12 3 6
		 12 6 9
		 12 9 5
		 10 7 11
		 8 10 11
		 2 8 11
		 3 2 11
		 7 3 11
		 2 5 8
		 10 4 7
		 7 6 3
		 6 7 4
		 6 4 9]
 
	(o[1] != 0 || o[2] != 0 || o[3] != 0) && (V .+= o)
	fv2fv([F], V)
end

# --------------------------------------------------------
"""
    FV = octahedron(r=1.0; radius=1.0, origin=(0.0, 0.0, 0.0))

Create an octahedron mesh with radius `r`. 

### Args
- `r`: the radius of the enclosing sphere.

### Kwargs
- `radius`: the keyword `radius` is an alternative to the positional argument `r`.
- `origin`: A tuple of three numbers defining the origin of the body. Default is `(0.0, 0.0, 0.0)`.
"""
function octahedron(r=1.0; radius=0.0, origin=(0.0, 0.0, 0.0))::GMTfv

	_r::Float64 = (radius != 1.0) ? radius : r		# If spelled, the `radius` kwarg take precedence
	o::Matrix{Float64} = [origin[1] origin[2] origin[3]]
	s = _r / sqrt(2.0)

	V = [-s  -s  0.0			# The Vertices
		  s  -s  0.0
		  s   s  0.0
		 -s   s  0.0
		 0.0 0.0 -_r
		 0.0 0.0  _r]
 
	F = [5 2 1					# The Faces
		 5 3 2
		 5 4 3
		 5 1 4
		 6 1 2
		 6 2 3
		 6 3 4
		 6 4 1]

	(o[1] != 0 || o[2] != 0 || o[3] != 0) && (V .+= o)
	fv2fv([F], V)
end

# ----------------------------------------------------------------------------
"""
    FV = dodecahedron(r=1.0; radius=1.0, origin=(0.0, 0.0, 0.0))

Create an dodecahedron mesh with radius `r`. 

### Args
- `r`: the radius of the enclosing sphere.

### Kwargs
- `radius`: the keyword `radius` is an alternative to the positional argument `r`.
- `origin`: A tuple of three numbers defining the origin of the body. Default is `(0.0, 0.0, 0.0)`.
"""
function dodecahedron(r=1.0; radius=1.0, origin=(0.0, 0.0, 0.0))::GMTfv

	_r::Float64 = (radius != 1.0) ? radius : r		# If spelled, the `radius` kwarg take precedence
	o::Matrix{Float64} = [origin[1] origin[2] origin[3]]

	ϕ = Base.MathConstants.golden # (1.0+sqrt(5.0))/2.0, Golden ratio
	s = _r / sqrt(3.0)
	t = ϕ*s    
	w = (ϕ-1.0)*s

	V = [ s   s   s		# The Vertices
		  w 0.0   t
		 -t  -w 0.0
		  t   w 0.0
		 -s   s  -s
		 0.0 -t  -w
		 -t   w 0.0
		  s  -s   s
		 -s   s   s
		 -s  -s   s
		  s  -s  -s
		  w 0.0  -t
		 -s  -s  -s
		 0.0 -t   w
		 0.0  t  -w
		 -w 0.0   t
		  t  -w 0.0
		 -w 0.0  -t
		  s   s  -s
		 0.0  t   w]

	F = [20  9 16  2  1			# The Faces
		  2 16 10 14  8
		 16  9  7  3 10
		  7  9 20 15  5
		 18 13  3  7  5
		  3 13  6 14 10
		  6 13 18 12 11
		  6 11 17  8 14
		 11 12 19  4 17
		  1  2  8 17  4
		  1  4 19 15 20
		 12 18  5 15 19]

	(o[1] != 0 || o[2] != 0 || o[3] != 0) && (V .+= o)
	fv2fv([F], V)
end

# ----------------------------------------------------------------------------
"""
    FV = tetrahedron(r=1.0; radius=1.0, origin=(0.0, 0.0, 0.0))

Create a tetrahedron mesh with radius `r`. 

### Args
- `r`: the radius of the enclosing sphere.

### Kwargs
- `radius`: the keyword `radius` is an alternative to the positional argument `r`.
- `origin`: A tuple of three numbers defining the origin of the body. Default is `(0.0, 0.0, 0.0)`.
"""
function tetrahedron(r=1.0; radius=1.0, origin=(0.0, 0.0, 0.0))::GMTfv

	_r::Float64 = (radius != 1.0) ? radius : r		# If spelled, the `radius` kwarg take precedence
	o::Matrix{Float64} = [origin[1] origin[2] origin[3]]

	a = r*sqrt(2.0)/sqrt(3.0)
	b = -_r * sqrt(2.0)/3.0
	c = -_r / 3.0       

	V = [-a    b     c	# The Vertices
		  a    b     c
		  0.0  0.0  _r
		  0.0 -2.0*b c]

	F = [1 2 3			# The Faces
		 4 2 1
		 4 3 2
		 4 1 3]

	(o[1] != 0 || o[2] != 0 || o[3] != 0) && (V .+= o)
	fv2fv([F], V)
end

# ----------------------------------------------------------------------------
"""
    FV = cube(r=1.0; radius=1.0, origin=(0.0, 0.0, 0.0))

Create a cube mesh with radius `r`. 

### Args
- `r`: the radius of the enclosing sphere.

### Kwargs
- `radius`: the keyword `radius` is an alternative to the positional argument `r`.
- `origin`: A tuple of three numbers defining the origin of the body. Default is `(0.0, 0.0, 0.0)`.
"""
function cube(r=1.0; radius=1.0, origin=(0.0, 0.0, 0.0))::GMTfv

	_r::Float64 = (radius != 1.0) ? radius : r		# If spelled, the `radius` kwarg take precedence
	o::Matrix{Float64} = [origin[1] origin[2] origin[3]]

	s = _r / sqrt(3.0)

	V = [-s -s -s			# The Vertices
		 -s  s -s
		  s  s -s
		  s -s -s
		 -s -s  s
		 -s  s  s
		  s  s  s
		  s -s  s]

	F = [1 2 3 4			# The Faces
		 8 7 6 5
		 5 6 2 1
		 6 7 3 2
		 7 8 4 3
		 8 5 1 4]

	(o[1] != 0 || o[2] != 0 || o[3] != 0) && (V .+= o)
	fv2fv([F], V)
end

# ----------------------------------------------------------------------------
"""
    FV = sphere(r=1; radius=1.0, n=1, center=(0.0, 0.0, 0.0))

Create a triangulated geodesic sphere. 

Generates a geodesic sphere triangulation based on the number of refinement iterations `n`
and the radius `r`. Geodesic spheres (aka Buckminster-Fuller spheres) are triangulations
of a sphere that have near uniform edge lenghts.  The algorithm starts with a regular
icosahedron. Next this icosahedron is refined `n` times, while nodes are pushed to a sphere
surface with radius `r` at each iteration.

### Args
- `r`: the radius of the sphere.

### Kwargs
- `radius`: the keyword `radius` is an alternative to the positional argument `r`.
- `n`: is the number of iterations used to obtain the sphere from the icosahedron.
- `center`: A tuple of three numbers defining the center of the sphere.

### Returns
A two elements vector of GMTdataset where first contains the vertices and the second
the indices that define the faces.
"""
function sphere(r=1; n=1, radius=1.0, center=(0.0, 0.0, 0.0))::GMTfv
	_r::Float64 = (radius != 1.0) ? radius : r		# If spelled, the `radius` kwarg take precedence
	o::Matrix{Float64} = [center[1] center[2] center[3]]

	FV = icosahedron(_r)	# Can't use the center here because subTriSplit() screws it up
	# Sub-triangulate the icosahedron for geodesic sphere triangulation
	if (n > 0)				# If refinement is requested
		Fn::Matrix{Int} = FV.faces[1];	Vn::Matrix{Float64} = FV.verts;		# Initialise Fn, Vn as input F and V
		for q = 1:n			# iteratively refine triangulation and push back radii to be r        
			Vn, Fn  = subTriSplit(Vn, Fn, 1)			# Sub-triangulate      
			T, P, R = cart2sph(view(Vn,:,1),view(Vn,:,2),view(Vn,:,3))			# Convert to spherical coordinates
			x, y, z = sph2cart(T, P, _r .* ones(size(R)))	# Push back radii
			Vn[:,1] .= x;	Vn[:,2] .= y;	Vn[:,3] .= z
		end
	end
	(o[1] != 0 || o[2] != 0 || o[3] != 0) && (Vn .+= o)
	fv2fv([Fn], Vn)
end

# ----------------------------------------------------------------------------
"""
    FV = subTriSplit(FV::Vector{<:GMTdataset}, n=1)

    V, F = subTriSplit(V, F, n=1)

Split the triangulation defined by the faces F, and the vertices V, n times.

Each triangle is linearly split into 4 triangles with each iterations.
First mode ingests a two elements vector of GMTdataset where first contains the vertices and the second
the indices that define the faces and returns a same type. The second mode expects the vertices and faces
as two separate arrays (but it also accepts GMTdatasets) and returns two matrices with the vertices and faces.

- `n`: is the number of times the triangulation is split.
"""
function subTriSplit(FV::Vector{<:GMTdataset}, n=1)::GMTfv
	V, F = subTriSplit(FV[1].data, FV[2].data, n)
	fv2fv([F], V)
end
subTriSplit(V::GMTdataset{Float64,2}, F::GMTdataset{Int,2}, n=1) = subTriSplit(V.data, F.data, n)
function subTriSplit(V::Matrix{Float64}, F::Matrix{Int}, n=1)
	
	(n == 0) && return V, F			# Nothing to do

	if (n == 1)		# Splitting just once
		#Setting up new vertices and faces such that no new unshared points are added. 
	
		E = [F[:,[1,2]]; F[:,[2,3]];  F[:,[3,1]]]	# Non-unique edges matrix
		Es = sort(E, dims=2)						# Sorted edges matrix, so 1-2 is the same as 2-1
	
		E, ind1, ind2  = gunique(Es, sorted=true)	# Get unique edges and their indices.
		ind2 .+= size(V,1)							# Offset indices since new pointsd (Vm below) are appended "under" V
	
		#Create face array (knowing each face has three new points associated with it)
		numFaces = size(F,1)				# The number of faces
		indF  = 1:numFaces					# Indices for all faces
		indP1 = ind2[indF]					# Indices of all new first points
		indP2 = ind2[indF .+ numFaces]		# Indices of all new second points
		indP3 = ind2[indF .+ 2*numFaces]	# Indices of all new third points
	
		Fn = [F[:,1] indP1 indP3;			# 1st new corner face
			  F[:,2] indP2 indP1;			# 2nd new corner face
			  F[:,3] indP3 indP2;			# 3rd new corner face
			  indP1 indP2 indP3]			# New central face
	
		# Create vertex arrays
		Vm = 0.5 * (V[E[:,1],:] + V[E[:,2],:])	#new mid-edge points
		Vn = [V; Vm]		# Join point sets    
	elseif (n > 1)			# Splitting more than once so recursively split once 
		Fn = F;	Vn = V;		# Initialise Fn, Vn as input F and V
		for q = 1:n			# Split once n times
			Vn, Fn = subTriSplit(Vn, Fn, 1)	# Split once
		end
	end
	return Vn, Fn
end	

# ----------------------------------------------------------------------------
"""
    FV = torus(; r=2.0, R=5.0, center=(0.0, 0.0, 0.0), nx=100, ny=50) -> GMTfv

Create a torus mesh with radius `r`. 

### Kwargs
- `r`: the inner radius of the torus.
- `R`: the outer radius of the torus.
- `center`: A 3-element array or tuple of three numbers defining the origin of the body. Default is `(0.0, 0.0, 0.0)`.
- `nx`: the number of vertices in the xx direction.	
- `ny`: the number of vertices in the yy direction.
"""
function torus(; r=2.0, R=5.0, center=(0.0, 0.0, 0.0), nx=100, ny=50)::GMTfv
	if (R < r)  R, r = r, R  end
	Θ, ϕ = range(-pi,pi,nx), range(-pi,pi,ny)
	x = [(R + cos(v)) * cos(u) + center[1] for u in Θ, v in ϕ]
	y = [(R + cos(v)) * sin(u) + center[2] for u in Θ, v in ϕ]
	z = [r*sin(v) + center[3] for u in Θ, v in ϕ]
	surf2fv(x, y, z)
end

# ----------------------------------------------------------------------------
"""
    FV = extrude(shape::Matrix{<:AbstractFloat}, h; base=0.0, closed=true) -> GMTfv

Create an extruded 2D/3D shape.

### Args
- `shape`: The shape to extrude. It can be a 2D polygon or a 3D polygon defined by a Mx2 or Mx3 matrix or a `GMTdataset`
- `h`: The height of the extrusion. Same units as in `shape`.

### Kwargs
- `base`: The base height of the 2D shape to extrude. Default is 0. Ignored if the shape is a 3D polygon.
- `closed`: If true (the default), close the shape at top and bottom.

### Example
Extrude the Swisserland
```julia
	Dsw = coast(M=true, DCW=(country=:CH, file=:ODS));	# Get the Swiss border
	FV = extrude(Dsw, 0.2)
	viz(FV)
```
"""
function extrude(shape::Matrix{<:AbstractFloat}, h; base=0.0, closed=true)::GMTfv
	np = size(shape, 1)
	if (size(shape, 2) < 3)			# 2D polygon
		V = [shape fill(convert(eltype(shape), base), np); shape fill(convert(eltype(shape), h+base), np)]
	else
		V = [shape; shape .+ [0 0 convert(eltype(shape), h)]]
	end

	if (h * facenorm(shape, normalize=false)[3] > 0)  v1, v2, f2, f4 = np:-1:1, np+1:2np,    1,  np		# Normal is pointing up
	else                                              v1, v2, f2, f4 = 1:np,    2np:-1:np+1, np, 1		# Normal is pointing down
	end

	if (closed == 1)  F = [reshape([v1;], 1, :), zeros(Int, np-1, 5), reshape([v2;], 1, :)]
	else              F = [zeros(Int, np-1, 5)]
	end
	iF = (closed == 1) ? 2 : 1		# Index of the faces vector that will contain the vertical faces
	for n = 1:np-1					# Create vertical faces
		F[iF][n, 1], F[iF][n, 2], F[iF][n, 3], F[iF][n, 4], F[iF][n, 5] = n, n+f2, n+np+1, n+f4, n
	end
	FV = fv2fv(F, V; bfculling=(closed == 1))
	(closed == 1) && (FV.isflat = [true, false, true])
	return FV
end

# ----------------------------------------------------------------------------
function extrude(shape::GMTdataset, h; base=0.0, closed=true)::GMTfv
	FV = extrude(shape.data, h; base=base, closed=closed)
	copyrefA2B!(shape, FV)
	return FV
end

# ----------------------------------------------------------------------------
function extrude(shape::Vector{<:GMTdataset}, h; base=0.0, closed=true)::Vector{GMTfv}
	FV = Vector{GMTfv}(undef, numel(shape))
	for k = 1:numel(shape)
		FV[k] = extrude(shape[k].data, h; base=base, closed=closed)
	end
	copyrefA2B!(shape[1], FV[1])
	return FV
end

# ----------------------------------------------------------------------------
"""
    FV = cylinder(r, h; base=0.0, center=(0.0, 0.0, 0.0), geog=false, unit="m", np=36) -> GMTfv

Create a cylinder with radius `r` and height `h`.

### Args
- `r`: The radius of the cylinder. For geographical cylinders, the default is meters. But see `unit` below.
- `h`: The height of the cylinder. It should be in the same unit as `r`.

### Kwargs
- `base`: The base height of the cylinder. Default is 0.
- `center`: A 3-element array or tuple of three numbers defining the origin of the body. Default is `(0.0, 0.0, 0.0)`.
- `closed`: If true (the default), close the cylinder at top and bottom.
- `geog`: If true, create a cylinder in geographical coordinates.
- `unit`: For geographical cylinders only.If radius is not in meters use one of `unit=:km`, or `unit=:Nautical` or `unit=:Miles`
- `np`: The number of vertices in the circle. Default is 36.

Return a Faces-Vertices dataset.

### Example
```julia
	FV = cylinder(50, 100)
	viz(FV)
```
"""
function cylinder(r, h; base=0.0, center=(0.0, 0.0, 0.0), closed=true, geog=false, unit=:m, np=36)::GMTfv
	h0 = (base != 0.0) ? base : length(center) == 3 ? center[3] : 0.0
	if (geog == 1)
		xy::Matrix{Float64} = circgeo(center[1], center[2]; radius=r, np=np, unit=unit)
	else
		t = linspace(0, 2pi, np)
		xy = [(center[1] .+ r * cos.(t)) (center[2] .+ r * sin.(t))]
	end
	extrude(xy, h; base=h0, closed=closed)
end

# ----------------------------------------------------------------------------
"""
    xyz = ellipse3D(a=1.0, b=a; center=(0.0, 0.0, 0.0), ang1=0.0, ang2=360.0, rot=0.0, e=0.0, f=0.0, plane=:xy, is2D=false, np=72)

Create an ellipse in 2D or 3D space.

### Args
- `a`: The semi-major axis length of the ellipse.
- `b`: The semi-minor axis length of the ellipse. Defaults to `a` if not provided (that is, a circle).

### Kwargs
- `center`: A 3-element array or tuple defining the center of the ellipse.
- `ang1`: The starting angle of the ellipse in degrees.
- `ang2`: The ending angle of the ellipse in degrees.
- `rot`: The rotation angle of the ellipse in degrees. Positive means counterclockwise.
- `e`: The eccentricity of the ellipse, between 0 and 1.
- `f`: The flattening of the ellipse, defined as `(a-b)/a`.
- `plane`: The plane in which to create the ellipse, one of `:xy`, `:xz`, or `:yz`.
- `is2D`: If true, create a 2D ellipse (no z-coordinate).
- `np`: The number of points to use to define the ellipse.

### Returns
- `xyz`: A matrix of points defining the ellipse, with each row representing a point in 3D space.
"""
function ellipse3D(a=1.0, b=a; center=(0.0, 0.0, 0.0), ang1=0.0, ang2=360.0, rot=0.0, e=0.0, f=0.0, plane=:xy, is2D=false, np=72)
	@assert 0 <= e < 1 "Excentricity must be between in the interval [0 1["
	!(plane == :xy || plane == :xz || plane == :yz) && error("The keyword `plane` must be one of :xy, :xz or :yz")
	ang1 *= pi/180;		ang2 *= pi/180
	t = linspace(ang1, ang2, np)
	if (a == b)
		if     (e != 0) b = sqrt(1 - e^2) * a	# e = sqrt(1 - (b/a)^2)
		elseif (f != 0) b = sqrt(1 - 1/f) * a
		end
	end

	(plane != :xy) && (t = reverse(t))			# The clockwise tests are failing for non :xy ??

	xp, yp = a * cos.(t), b * sin.(t)
	if (rot == 0)
		if (is2D == 1)
			xyz = [(center[1] .+ xp) (center[2] .+ yp)]
		else
			xyz = (plane == :xy) ? [(center[1] .+ xp) (center[2] .+ yp) fill(0.0, np)] :
			      (plane == :xz) ? [(center[1] .+ xp) fill(0.0, np) (center[3] .+ yp)] :
			                       [fill(0.0, np) (center[2] .+ xp) (center[3] .+ yp)]		# :yz
		end
	else
		R = [cosd(rot) sind(rot); -sind(rot) cosd(rot)]
		xy = [xp yp] * R
		if (is2D == 1)
			xyz = (center[1] != 0 || center[2] != 0) ? [(center[1] .+ view(xy,:,1)) (center[2] .+ view(xy,:,2))] : xy
		else
			xyz = (plane == :xy) ? [(center[1] .+ view(xy,:,1)) (center[2] .+ view(xy,:,2)) fill(0.0, np)] :
			      (plane == :xz) ? [(center[1] .+ view(xy,:,1)) fill(0.0, np) (center[3] .+ view(xy,:,2))] :
			                       [fill(0.0, np) (center[2] .+ view(xy,:,1)) (center[3] .+ view(xy,:,2))]
		end
	end

	return xyz
end

# ----------------------------------------------------------------------------
"""
   xy = circlepts(r=1.0; center=(0.0, 0.0), ang1=0.0, ang2=360.0, np=72)

Create an circle in 2D space (see `ellipse3D` if want a circle in the 3D space).

### Args
- `r`: The circle radius.

### Kwargs
- `center`: A 2-element array or tuple defining the center of the circle.
- `ang1`: The starting angle in degrees.
- `ang2`: The ending angle in degrees.
- `np`: The number of points to use to define the circle.

### Returns
- `xy`: A Mx2 matrix of points defining the circle, where M = `np` 
"""
function circlepts(r=1.0; center=(0.0, 0.0), ang1=0.0, ang2=360.0, np=72)
	t = linspace(ang1*pi/180, ang2*pi/180, np)
	[(center[1] .+ r * cos.(t)) (center[2] .+ r * sin.(t))]
end

# ----------------------------------------------------------------------------
"""
    R = spinmat(theta, n) -> Matrix{Float64}

Compute the rotation matrix that rotates by angle `theta` (in degrees) about the vector `n`.
"""
function spinmat(theta, n)
	cross_prod_mat(x) = [0.0 -x[3] x[2]; x[3] 0 -x[1]; -x[2] x[1] 0]

	W = cross_prod_mat(n / norm(n))
	eye(3) .+ W * sind(theta) .+ W^2 * (1-cosd(theta))
end

# ----------------------------------------------------------------------------
"""
    R = eulermat(a) -> Matrix{Float64}

Compute the Euler rotation matrix that rotates by angles `a` (in degrees) about the x, y and z axes.
"""
eulermat(; rx=0.0, ry=0.0, rz=0.0) = eulermat([rx, ry, rz])
function eulermat(a)
	@assert length(a) == 3 "Angle vector must be of length 3"
	Rx = [1 0 0; 0 cosd(a[1]) sind(a[1]); 0 -sind(a[1]) cosd(a[1])]
	Ry = [cosd(a[2])  0 -sind(a[2]); 0 1 0; sin(a[2]) 0 cos(a[2])]
	Rz = [cosd(a[3]) sind(a[3]) 0; -sind(a[3]) cosd(a[3]) 0; 0 0 1]
	R = Rx * Ry * Rz
	return R, collect(R')
end

# ----------------------------------------------------------------------------
"""
    FV = revolve(curve::Matrix{Real}; extent = 360, ang1=0, ang2=360, dir=:positive, n=[0.0,0.0,1.0], n_steps=0, closed=true, type=:quad) -> GMTfv

Revolve curves to build surfaces.

This function rotates the curve `curve` by the angle `extent`, in the direction 
defined by `direction` (`:positive`, `:negative`, `:both`), around the vector 
`n`, to build the output mesh defined as a Faces-Vertices type.

### Credit
This function is a modified version on the `revolvecurve` function from the `Comodo.jl` package.

### Args
- `curve`: A Mx3 matrix of points defining the curve to revolve. Each row is a point in 3D space.

### Kwargs
- `extent`: The extent of the revolved curve in degrees. Default is 360 degrees. But a finer control
   is possible using the `ang1` and `ang2` arguments.
- `ang1`: The starting angle in degrees. Use this if start and end angles do not define a full revolution.
- `ang2`: The ending angle in degrees.
- `dir`: The direction of the revolved curve (`:positive`, `:negative`, `:both`).
- `n`: The normal vector of the revolved curve.
- `n_steps`: The number of steps used to build the revolved curve. If `0` (the default) the number
   of steps is computed from the curve point spacing.
- `closed`: If `true` (the default), close the revolved curve at the start and end slice.
- `type`: The type of faces used to build the revolved curve (`:quad` (default), `:tri`).

### Returns
- `FV`: A Faces-Vertices dataset.

### Example
```julia
    ns=15; x=linspace(0,2*pi,ns).+1; y=zeros(size(x)); z=-cos.(x); curve=[x[:] y[:] z[:]];
	FV = revolve(curve)
	viz(FV, pen=0)
```
"""
function revolve(curve; extent=360.0, ang1=0.0, ang2=360.0, dir=:positive, n=[0.0,0.0,1.0], n_steps::Int=0, closed=false, type=:quad)

	n_pts = size(curve,1)

	# Compute n_steps from curve point spacing
	if (n_steps == 0)
		L = [0.0; cumsum(sqrt.(sum(diff(curve, dims=1).^2, dims=2)), dims=1)]	# Compute the accumulated distance along the curve
		rMax = 0.0
		for k = 1:n_pts
			v = [curve[k, 1], curve[k, 2], curve[k, 3]]
			cc = cross(cross(n, v), n)
			rNow = dot(cc / norm(cc), cc)
			if !isnan(rNow)
				rMax = max(rMax, rNow)
			end
		end
		(ang1 != 0 || ang2 != 360) && (extent = abs(ang2 - ang1))
		n_steps = ceil(Int, (rMax*extent*pi/180) / mean(diff(L, dims=1)))        
	end

    # Set up angle range
	if (ang1 != 0 || ang2 != 360)
		θ_range = range(ang1, ang2, n_steps)
	elseif dir == :positive
		θ_range = range(0, extent, n_steps)
	elseif dir == :negative
		θ_range = range(-extent, 0, n_steps)
	elseif dir == :both
		θ_range = range(-extent/2, extent/2, n_steps)
	else
		throw(ArgumentError("$dir is not a valid direction, Use :positive, :in, or :both."))
	end

	X = Matrix{Float64}(undef, n_pts, n_steps)
	Y,Z = copy(X), copy(X)
	curveT = curve'
	for k = 1:n_steps
		R = spinmat(θ_range[k], n)
		curve_rot = R * curveT		# Rotate the polygon
		for m = 1:n_pts
			X[m,k] = curve_rot[1,m]
			Y[m,k] = curve_rot[2,m]
			Z[m,k] = curve_rot[3,m]
		end
	end

	surf_ini = surf_fim = nothing
	if (closed == 1)
		surf_ini = reshape(1:n_pts, 1, n_pts)		# So stupid way of creating a row matrix
		surf_fim = surf_ini .+ (length(X) - n_pts)
	end

	surf2fv(X, Y, Z; type=type, bfculling=(closed == 1), top=surf_fim, bottom=surf_ini)	# bot -> FV.faces[1]; top -> FV.faces[end]
end


# ----------------------------------------------------------------------------
"""
    FV = loft(C1, C2; n_steps::Int=0, closed=true, type=:quad) -> GMTfv

Loft (linearly) a surface mesh between two input 3D curves.

### Args
- `C1, C2`: Two Mx3 matrices of points defining the 3D curves to _loft_. Each row is a point in 3D space.

### Kwargs
- `n_steps`: The number of steps used to build the lofted surface. If `0` (the default) the number
   of steps is computed from the curve point spacing.
- `closed`: If `true` (the default), close the lofted surface at the top and bottom with planes
   created with `C1` and `C2`.
- `type`: The type of faces used to build the lofted surface (`:quad` (default), `:tri`).

### Example
```julia
ns=75; t=linspace(0,2*pi,ns); r=5; x=r*cos.(t); y=r*sin.(t); z=zeros(size(x));
C1=[x[:] y[:] z[:]];

f(t) = r + 2.0.* sin(6.0*t)
C2 = [(f(t)*cos(t),f(t)*sin(t),3) for t in range(0, 2pi, ns)];
C2 = stack(C2)'

FV = loft(C1, C2);
viz(FV, pen=0)
```
"""
function loft(C1, C2; n_steps::Int=0, closed=true, type=:quad)
	@assert size(C1) == size(C2) "C1 and C2 curves must have the same number of elements."

	function linA2B(A, B, n)	# Linear interpolate vector of components (x,y or z) from A to B
		C = repeat(A, 1, n) .+ ((B-A) / (n-1)) * (0:n-1)'
		for k = 1:numel(A)  C[k, end] = B[k]  end	# Make sure the last points are those of B
		return C
	end

	if (n_steps == 0)			# Derive n_steps from distance and mean curve point spacing
		d = 0.0
		for k = 1:size(C1,1)
			d += norm([C1[k,1] - C2[k,1], C1[k,2] - C2[k,2], C1[k,3] - C2[k,3]])
		end
		d /= size(C1,1)
		L1 = [0.0; cumsum(sqrt.(sum(diff(C1, dims=1).^2, dims=2)), dims=1)]	# The cumdist along the curve
		L2 = [0.0; cumsum(sqrt.(sum(diff(C2, dims=1).^2, dims=2)), dims=1)]
		dp = 0.5* (mean(diff(L1, dims=1)) + mean(diff(L2, dims=1)))
		n_steps = ceil(Int, d / dp)
	end

	X = linA2B(view(C1, :, 1), view(C2, :, 1), n_steps)
	Y = linA2B(view(C1, :, 2), view(C2, :, 2), n_steps)
	Z = linA2B(view(C1, :, 3), view(C2, :, 3), n_steps)

	top = bot = nothing
	if (closed == 1)
		bot = reshape(1:size(X,1), 1, size(X,1))		# So stupid way of creating a row matrix
		top = bot .+ (length(X) - size(X,1))
	end

	surf2fv(X, Y, Z; type=type, bfculling=(closed != 1), top=top, bottom=bot)
end


# ---------------------------------------------------------------------------------------------------
"""
    FV = flatfv(I::Union{GMTimage, AbstractString}; shape=nothing, level=0.0) ->GMTfv

Create a flat 3D surface from an image and a set of xyz or xy coordinates.

This function creates a face for each pixel in the image that is inside the `shape` and assigns the
face's color from that of the image. So be careful that the image is not too large. As explained below,
this function creates flat surfaces in any of the xy, xz or yz planes. While this may seam a big
limitation, it can be circumvented by a posterior rotation of the image with the help of a rotation
matrix created with the `eulermat` function.

### Args
- `I`: A `GMTimage` object or a file name of an image.

### Kwargs
- `shape`: A xyz or xy polygon defining a flat surface. When it is a 3D polygon, it must lie in the xz or yz planes.
   But it can also be a can also be a Symbol; one of `:circle`, `:circ`, `:ellipse`. In this later case, we
   compute a normalized circle or ellipse with dimensions taken from number of rows and columns in `I`.
   The ellipse (with a horizontal major) eccentricity  is computed from the ratio of the number of rows and columns.

- `level`: In case that `shape` is a polygon in the xy plane, this is the level or height of that flat surface.
   For other plane orientations, this level is extracted from the column of constant values in `shape`.

Returns:
- A `GMTfv` object representing the flat 3D surface.

### Example
```julia
FV = flatfv("image.png", shape=:circle, level=1.0);
viz(FV)
```
"""
#=
flatfv(I::Union{GMTimage, AbstractString}, mat::Union{GMTdataset, Matrix{AbstractFloat}}; level=0.0, thickness=0.0, isbase=false)::GMTfv =
	helper_flatfv(I; shape=mat, level=level, thickness=thickness, isbase=(isbase == 1))

function flatfv(I::Union{GMTimage, AbstractString}; shape::Symbol=:n, level=0.0, thickness=0.0, isbase=false)::GMTfv
	(shape == :n) && error("No shape given. Please specify one of: :circle, :circ, :ellipse")
	helper_flatfv(I; shape=shape, level=level, thickness=thickness, isbase=(isbase == 1))
end

function flatfv(I::Union{GMTimage, AbstractString}, Dv::Vector{<:GMTdataset}; level=0.0, thickness=0.0, isbase=false)::Vector{GMTfv}
	FV = Vector{GMTfv}(undef, numel(Dv))
	for k = 1:numel(Dv)
		FV[k] = helper_flatfv(I; shape=mat[k], level=level, thickness=thickness, isbase=(isbase == 1))
	end
end
=#

function flatfv(I::Union{GMTimage, AbstractString}; shape=:n, level=0.0, thickness=0.0, isbase=false)::Union{GMTfv, Vector{GMTfv}}
	if (isa(shape, Vector))
		FV = Vector{GMTfv}(undef, length(shape))
		for k = 1:numel(FV)
			FV[k] = helper_flatfv(I, shape[k], level, thickness, isbase == 1)
		end
		return FV
	else
		helper_flatfv(I, shape, level, thickness, isbase == 1)
	end
end

#function flatfv(I::Union{GMTimage, AbstractString}; shape=:n, level=0.0, thickness=0.0, isbase=false)::GMTfv
function helper_flatfv(I::Union{GMTimage, AbstractString}, shape, level, thickness, isbase::Bool)::GMTfv

	function crop_if_possible(I::Union{GMTimage, AbstractString}, shape)
		# If the image is referenced crop it to the 'shape's bounding box
		if isa(I, AbstractString)
			D = grdinfo(I, C=1)
			isnoref = (D[2] - D[1] == D[9] && D[7] == 1) && (D[4] - D[3] == D[10] && D[8] == 1)
		else
			isnoref = isimgsize(I)		# A function from grdimage.jl
		end
		isnoref && return I				# A plain image with no coords
	
		if (isa(shape, GDtype))
			x, y = isa(shape, Vector) ? (shape[1].ds_bbox[1:2], shape[1].ds_bbox[3:4]) : (shape.bbox[1:2], shape.bbox[3:4])
		else
			x = extrema(view(shape, :, 1))	# xx minmax
			y = extrema(view(shape, :, 2))
		end
		isa(I, AbstractString) && (x[1] < D[1] || x[2] > D[2] || y[1] < D[3] || y[2] > D[4]) &&
			error("The 'shape' is outside the image.")
		isa(I, GMTimage) && (x[1] < I.range[1] || x[2] > I.range[2] || y[1] < I.range[3] || y[2] > I.range[4]) &&
			error("The 'shape' is outside the image.")
	
		return isa(I, AbstractString) ? gmtread(I, R=(x[1], x[2], y[1], y[2]), V=:q) : crop(I, R=(x[1], x[2], y[1], y[2]))[1]
	end

	function forceRGB(I)::GMTimage{UInt8, 3}
		I_::GMTimage = isa(I, GMTimage) ? I : gmtread(I)::GMTimage
		size(I_, 3) == 1 && (I_ = ind2rgb(I_))
		return I_
	end

	I = crop_if_possible(I, shape)
	_I::GMTimage{UInt8, 3} = forceRGB(I)
	n_cols::Int, n_rows::Int = getsize(_I)	# Works for both 'regular' and GDAL transposed images

	hasAlphaMask = (length(_I.layout) == 4 && _I.layout[4] == 'A')
	if hasAlphaMask
		if (_I.layout[3] == 'B')				# Band interleaved
			_masca = (_I.image[:, :, 4] .== 255)'
		else									# Pixel interleaved
			_masca = reshape((_I.image[4:4:end] .== 255), n_cols, n_rows)'
		end
	end

	if (shape == :circle || shape == :circ || shape == :ellipse)
		X,Y = meshgrid(linspace(0, 1, n_cols+1), linspace(1, 0, n_rows+1))
		Z = fill(Float64(level), n_rows+1, n_cols+1)
		if (shape == :ellipse)
			e = sqrt(1 - ((n_rows+1) / (n_cols+1))^2)
			masca = maskregion(X, Y, ellipse3D(0.5; center=(0.5, 0.5), e=e))	# An horizontal ellipse
		else
			masca = maskregion(X, Y, circlepts(0.5; center=(0.5, 0.5)))			# A normalized circle
		end
	elseif (isa(shape, Array{<:AbstractFloat}) || isa(shape, GMTdataset))
		if (size(shape, 2) == 2)
			xc = extrema(view(shape, :, 1))			# Start and end coordinates
			yc = extrema(view(shape, :, 2))
			X,Y = meshgrid(linspace(xc[1], xc[2], n_cols+1), linspace(yc[2], yc[1], n_rows+1))
			Z = fill(Float64(level), n_rows+1, n_cols+1)
			masca = maskregion(X, Y, shape)
		elseif (size(shape, 2) == 3)				# A 3D polygon but not necessarily in the xy plane
			c0 = std(diff(view(shape, :, 1), dims=1)) ≈ 0 ? 1 : std(diff(view(shape, :, 2), dims=1)) ≈ 0 ? 2 :
			     std(diff(view(shape, :, 3), dims=1)) ≈ 0 ? 3 : error("'shape' is not a circle in the horizontal or vertical planes.")
			two_col = (c0 == 1) ? (2,3) : (c0 == 2) ? (1,3) : (1,2)		# The indices of the non-zero columns
			xc = extrema(view(shape, :, two_col[1]))
			yc = extrema(view(shape, :, two_col[2]))
			_X,_Y = meshgrid(linspace(xc[1], xc[2], n_cols+1), linspace(yc[2], yc[1], n_rows+1))
			masca = maskregion(_X, _Y, shape[:, [two_col[1], two_col[2]]])
			level = (c0 == 1) ? shape[1] : (c0 == 2) ? shape[1,2] : shape[1,3]
			_Z = fill(Float64(level), n_rows+1, n_cols+1)
			X, Y, Z = (c0 == 1) ? (_Z, _X, _Y) : (c0 == 2) ? (_X, _Z, _Y) : (_X, _Y, _Z)
		end
		(sum(masca) == 0) && (masca[div(size(masca, 1), 2), div(size(masca, 2), 2)] = true)		# Tinny polygons can give empty masks
	else
		X,Y = meshgrid(_I.x, reverse(_I.y))		# MUST CONFIRM that these coords are pixel-reg
		Z = fill(Float64(level), n_rows+1, n_cols+1)
		masca = BitArray(undef,0,0)
	end
	doMask = !isempty(masca)

	if (hasAlphaMask)
		masca = doMask ? masca .& _masca : _masca
		doMask = true
	end

	FV = surf2fv(X, Y, Z, type=:quad, mask=masca)
	copyrefA2B!(_I, FV)
	n_colors = doMask ? sum(masca) : (n_rows * n_cols)

	# --------------- See if we need to add a vertical wall 
	n_wall = 0
	if (thickness != 0)
		FVwall = vwall(shape, thickness, size(FV.verts,1); isbase=isbase)
		n_wall = size(FVwall.faces[1], 1)		# Number of wall faces

		FV.verts = vcat(FV.verts, FVwall.verts)
		FV.faces = vcat(FVwall.faces, FV.faces)
		mima = extrema(view(FV.verts, :, 3))
		FV.bbox[5:6] .= mima
	end

	cor = Vector{String}(undef, n_colors)
	kk = 0
	if (_I.layout[3] == 'P')		# Pixel interleaved
		n_interleaved = (length(_I.layout) == 4 && _I.layout[4] == 'A') ? 4 : 3
		@inbounds for n = 1:n_cols, m = 1:n_rows
			doMask && !masca[m,n] && continue
			k = (m-1) * n_cols * n_interleaved + (n-1) * n_interleaved
			cor[kk+=1] = @sprintf("-G#%.2x%.2x%.2x", _I[k+=1], _I[k+=1], _I[k+=1])
		end
	else							# Band interleaved
		nxy, nxy2 = n_rows * n_cols, n_rows * n_cols * 2
		@inbounds for n = 1:n_cols, m = 1:n_rows
			doMask && !masca[m,n] && continue
			k = (m-1) * n_cols + n
			cor[kk+=1] = @sprintf("-G#%.2x%.2x%.2x", _I[k], _I[k+nxy], _I[k+nxy2])
		end
	end

	if (n_wall == 0)				# No vertical wall
		FV.color, FV.isflat = [cor], [true]
	else
		cor_wall = Vector{String}(undef, n_wall)
		#for k = 1:n_wall  cor_wall[k] = "-G180"  end
		FV.color = [cor_wall, cor]
		FV.isflat = [false, true]
		FV.color_vwall = "140,220"
	end
	return FV
end

# ---------------------------------------------------------------------------------------------------
"""
	bbox = getbbox(FV::Vector{GMTfv}) -> Vector{Float64}

Return the global bounding box of a vector of GMTfv structures.
"""
function getbbox(FV::Vector{GMTfv})::Vector{Float64}
	bbox = FV[1].bbox
	for k = 2:numel(FV)
		bbox[1], bbox[3], bbox[5] = min(bbox[1], FV[k].bbox[1]), min(bbox[3], FV[k].bbox[3]), min(bbox[5], FV[k].bbox[5])
		bbox[2], bbox[4], bbox[6] = max(bbox[2], FV[k].bbox[2]), max(bbox[4], FV[k].bbox[4]), max(bbox[6], FV[k].bbox[6])
	end
	return bbox
end
