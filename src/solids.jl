# This file contains modified versions of some functions from the Comodo.jl package (Apache 2.0 license).
# https://github.com/COMODO-research/Comodo.jl
"""
    FV = icosahedron(r=1.0)

Creates an icosahedron mesh with radius `r. 
"""
function icosahedron(r=1.0)

	ϕ = Base.MathConstants.golden # (1.0+sqrt(5.0))/2.0, Golden ratio
	s = r / sqrt(ϕ + 2.0)
	t = ϕ * s

	V = [0.0  -s  -t				# The Vertices
		 0.0  -s   t
		 0.0   s   t
		 0.0   s  -t
		 -s   -t  0.0
		 -s    t  0.0
		  s    t  0.0
		  s   -t  0.0
		 -t  0.0  -s
		  t  0.0  -s
		  t  0.0   s
		 -t  0.0   s]

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
 
	DV = GMTdataset(data=V, geom=wkbPointZ);	set_dsBB!(DV)
	return [DV, GMTdataset(data=F)]
end

# --------------------------------------------------------
"""
    FV = octahedron(r=1.0)

Creates an octahedron mesh with radius `r`. 
"""
function octahedron(r=1.0)

	s = r/sqrt(2.0)

	V = [-s  -s  0.0			# The Vertices
		  s  -s  0.0
		  s   s  0.0
		 -s   s  0.0
		 0.0 0.0 -r
		 0.0 0.0  r]
 
	F = [5 2 1					# The Faces
		 5 3 2
		 5 4 3
		 5 1 4
		 6 1 2
		 6 2 3
		 6 3 4
		 6 4 1]

	DV = GMTdataset(data=V, geom=wkbPointZ);	set_dsBB!(DV)
	return [DV, GMTdataset(data=F)]
end

# ----------------------------------------------------------------------------
"""
    FV = dodecahedron(r=1.0)

Creates an dodecahedron mesh with radius `r`. 
"""
function dodecahedron(r=1.0)

	ϕ = Base.MathConstants.golden # (1.0+sqrt(5.0))/2.0, Golden ratio
	s = r/sqrt(3.0)
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
    
	DV = GMTdataset(data=V, geom=wkbPointZ);	set_dsBB!(DV)
	return [DV, GMTdataset(data=F)]
end

# ----------------------------------------------------------------------------
"""
    FV = tetrahedron(r=1.0)

Creates a tetrahedron mesh with radius `r`. 
"""
function tetrahedron(r=1.0)

	a = r*sqrt(2.0)/sqrt(3.0)
	b = -r*sqrt(2.0)/3.0
	c = -r/3.0       

	V = [-a    b     c	# The Vertices
		  a    b     c
		  0.0  0.0   r
		  0.0 -2.0*b c]

	F = [1 2 3			# The Faces
		 4 2 1
		 4 3 2
		 4 1 3]

	DV = GMTdataset(data=V, geom=wkbPointZ);	set_dsBB!(DV)
	return [DV, GMTdataset(data=F)]
end

# ----------------------------------------------------------------------------
"""
    FV = cube(r=1.0)

Creates a cube mesh with radius `r`. 
"""
function cube(r=1.0)

	s = r/sqrt(3.0)

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

	DV = GMTdataset(data=V, geom=wkbPointZ);	set_dsBB!(DV)
	return [DV, GMTdataset(data=F)]
end

# ----------------------------------------------------------------------------
"""
    FV = geosphere(n, r=1; radius=1.0)

Generate a geodesic sphere triangulation based on the number of refinement iterations `n`
and the radius `r`. Geodesic spheres (aka Buckminster-Fuller spheres) are triangulations
of a sphere that have near uniform edge lenghts.  The algorithm starts with a regular
icosahedron. Next this icosahedron is refined `n` times, while nodes are pushed to a sphere
surface with radius `r` at each iteration.

- `radius`: the keyword `radius` is an alternative to the positional argument `r`.
- `n`: is the number of times of iterations used to obtain the sphere from the icosahedron.

### Returns
A two elements vector of GMTdataset where first contains the vertices and the second
the indices that define the faces.
"""
function geosphere(n, r=1; radius=1.0)
	(radius != 1 && r == 1) && (r = radius)
	FV = icosahedron(r)
	# Sub-triangulate the icosahedron for geodesic sphere triangulation
	if (n > 0)				# If refinement is requested
		Fn::Matrix{Int} = FV[2].data;	Vn::Matrix{Float64} = FV[1].data;		# Initialise Fn, Vn as input F and V
		for q = 1:n			# iteratively refine triangulation and push back radii to be r        
			Vn, Fn  = subTriSplit(Vn, Fn, 1)			# Sub-triangulate      
			T, P, R = cart2sph(view(Vn,:,1),view(Vn,:,2),view(Vn,:,3))			# Convert to spherical coordinates
			x, y, z = sph2cart(T, P, r.*ones(size(R)))	# Push back radii
			Vn[:,1] .= x;	Vn[:,2] .= y;	Vn[:,3] .= z
		end
	end
	DV = GMTdataset(data=Vn, geom=wkbPointZ);	set_dsBB!(DV)
	return [DV, GMTdataset(data=Fn)]
end

# ----------------------------------------------------------------------------
"""
    FV = subTriSplit(FV::Vector{<:GMTdataset}, n=1)

    V, F = subTriSplit(V, F, n=1)

Splits the triangulation defined by the faces F, and the vertices V, n times. Each triangle is
linearly split into 4 triangles with each iterations.

First mode ingests a two elements vector of GMTdataset where first contains the vertices and the second
the indices that define the faces and returns a same type. The second mode expects the vertices and faces
as two separate arrays (but it also accepts GMTdatasets) and returns two matrices with the vertices and faces.

- `n`: is the number of times the triangulation is split.
"""
function subTriSplit(FV::Vector{<:GMTdataset}, n=1)
	V, F = subTriSplit(FV[1].data, FV[2].data, n)
	DV = GMTdataset(data=V, geom=wkbPointZ);	set_dsBB!(DV)
	return [DV, GMTdataset(data=F)]
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
