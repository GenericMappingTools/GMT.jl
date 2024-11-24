"""
    Db = bezier(D::GMTdataset; t=nothing, np::Int=0, pure=false, firstcurve=true) -> GMTdataset
---
    mat = bezier(p::Matrix{<:Real}; t=nothing, np::Int=0, pure=false, firstcurve=true) -> Matrix{Float64}
---
	mat = bezier(p1::Vector{T}, p2::Vector{T}, p3::Vector{T}, p4::Vector{T}; t=nothing, np::Int=0, pure=false) where {T <: Real}
---

Create a Bezier curve from a set of control points.

A function for cubic Bezier interpolation for a given set of control points (knots). Each control point can
exist in an N-dimensional space but only tested 2D and 3D cases. Data can be geographic or Cartesian. The
default for this function is to compute a curve that passes through the control points. This can be changed
by setting `pure` to `true` and then we instead compute a curve that passes through the first and last.

When more than 4 control points are provided, we make a curve composition by connecting the first curve,
made with points 1,2,3,4, second curve, made with points 2,3,4,5 and so on. The way this connection is
made is controlled by the `firstcurve` argument. With more than 4 control points, the `pure` option is not
allowed. 

### Args
- `D`: A ``GMTdataset`` object with a matrix of control points. This matrix may have 2 (2D) or 3 columns (3D).
   If `D` represents geographical data, we create a spherical Bezier curve by using an intermediate step of
   converting the data to ECEF, compute the 3D curve, and then convert it back to geographic coordinates.
---
- `p::Matrix{<:Real}`: Matrix with at least 4 control points. Same as the `D` case, except for the possibility
   of geographical data.
---
- `p1, p2, p3, p4`: Vectors of control points. They can be 2D or 3D (two or three elements).
---

### Kwargs
- `t`: Vector of values of the ``t`` paramter at which bezier curve is evaluated. By default is
   evaluated at 101 evenly spaced values between 0 and 1, but see `np` below.
- `np`: Number of values of the ``t`` paramter at which bezier curve is evaluated. Default is 101.
- `pure`: By default we compute a curve that passes through the control points. If `pure` is `true`,
   we instead compute a curve that passes through the first and last control points and the other two
   are used to control the path. This is what _pure_ cubic bezier curves do.
- `firstcurve`: Applies  only when the number of control points is > 4 and sets how the different
   curves are connected. If `true`, the first curve takes precedence. Using as example the case of
   two curves given by 5 control points; the final curve is obtained by connecting the first curve
   (made with the first 4 control points) with the second curve (made with the last 4 control points).
   But since these two curves shared the second, third and fourth control points, that part is removed
   from the second curve, leaving only the 4rth to 5th contribution. When `firstcurve` is `false`, the
   opposite happens. The first curve contributes only with the part from first to second control points.	

### Returns
- `Db`: A ``GMTdataset`` object with the coordinates of the Bezier curve, when input is a ``GMTdataset``.
- `mat::Matrix{Float64}`: Matrix of coordinates of the Bezier curve, when input is a matrix.

### Example

```julia
# A spherical Bezier curve with 4 knots
D = bezier(mat2ds([30. -15; 30 45; -30 45; -30 -15], proj4="geog"));

# A composed spherical Bezier curve with 5 knots and predominance  of second curve
D = bezier(mat2ds([30. -15; 30 45; -30 45; -30 -15; -20 -25], proj4="geog"), firstcurve=false);
```
"""
function bezier(D::GMTdataset; t=nothing, np::Int=0, pure=false, firstcurve=true)::GMTdataset{Float64, 2}
	is_geo = isgeog(D)
	if (is_geo)
		mat::Matrix{Float64} = (size(D.data, 2) == 2) ? [D.data fill(0, size(D.data, 1))] : D.data
		mat = mapproject(mat, E=true).data						# Convert to ECEF
	else
		mat = D.data
	end
	(pure == 1 && size(mat, 1) > 4) && (pure = false;
		@warn("pure option not allowed for more than 4 control points. Reverting to 'impure'"))
	
	out::Matrix{Float64} = bezier(mat; t=t, np=np, pure=pure, firstcurve=firstcurve)
	is_geo && (out = mapproject(out, E=true, I=true).data)		# Convert back to geographic
	return mat2ds(out, D)::GMTdataset{Float64, 2}
end

# ---------------------------------------------------------------------------------------------------
function bezier(p1::Vector{T}, p2::Vector{T}, p3::Vector{T}, p4::Vector{T}; t=nothing, np::Int=0, pure=false) where {T <: Real}
	# Rooted in FEX contrib https://www.mathworks.com/matlabcentral/fileexchange/7441-bezier-interpolation-in-n-dimension-space
	# By Murtaza Ali Khan (2024).
	@assert (length(p1) == length(p2)) && (length(p2) == length(p3)) && (length(p3) == length(p4)) "Control points must have equal size"

	if (pure != 1)
		p1, p2, p3, p4 = bezier_newknots(p1, p2, p3, p4)	# If pure=false, make curve pass through control points
	end
	
	(t === nothing) && (t = (np == 0) ? linspace(0,1,101) : linspace(0,1,np))

	# Equation of Bezier Curve, utilizing Horner's rule for efficient computation.
	c4 = -p1 .+ 3*(p2 .- p3) .+ p4
	c3 = 3*(p1 .- 2*p2 .+ p3)
	c2 = 3*(p2 .- p1)
	c1 = p1

	out = Matrix{Float64}(undef, length(t), length(p1))
	# If I don't use a function and use threads, 't' becomes a Core.box!!!!!!
	function out_fun(out, tt)
		@inbounds Threads.@threads for k in eachindex(tt)
			out[k,:] = c4*tt[k]^3 + c3*tt[k]^2 + c2*tt[k] + c1
		end
	end
	out_fun(out, t)
	return out
end

# ---------------------------------------------------------------------------------------------------
function bezier(p::Matrix{<:Real}; t=nothing, np::Int=0, pure=false, firstcurve=true)::Matrix{Float64}
	(size(p, 1) < 4) && error("Input must have at least 4 rows")
	(t === nothing) && (t = (np == 0) ? linspace(0,1,101) : linspace(0,1,np))
	o::Matrix{Float64} = bezier(p[1,:], p[2,:], p[3,:], p[4,:]; t=t)	# 'out' is Core.box because it's modified below. But WHY?????
	return (size(p, 1) == 4) ? o : helper_bezier_cb(o, Float64.(p), t, firstcurve)	# This avoids exporting the Core.box
end

function helper_bezier_cb(o::Matrix{Float64}, p::Matrix{Float64}, t, firstcurve::Bool)::Matrix{Float64}
	# Made this function barrier to restrict the Core.box. For some incomprehensible reason, 'o' becomes
	# a Core.box and that happens due to the appending (the 'vcats' below). Both Cthulhu and the debugger
	# show that 'o' is no longer a Core.box when it lands on the calling function.
	# This function is not efficient due to the matrix concatenations, but it's not expeced to cat much data.
	for k = 5:size(p, 1)
		oo = bezier(p[k-3,:], p[k-2,:], p[k-1,:], p[k,:]; t=t)
		if (firstcurve)
			xn = o[end,1];		yn = o[end,2];		zn = o[end,3]
			d::Vector{Float64} = [(oo[n,1] - xn)^2 + (oo[n,2] - yn)^2 + (oo[n,3] - zn)^2 for n = 1:size(oo, 1)]
		else
			xn = oo[1,1];		yn = oo[1,2];		zn = oo[1,3]
			d = [(o[n,1] - xn)^2 + (o[n,2] - yn)^2 + (o[n,3] - zn)^2 for n = 1:size(oo, 1)]
		end
		m = argmin(d)
		o = firstcurve ? vcat(o, oo[m+1:end,:]) : vcat(o[1:m,:], oo)
	end
	return o		# Cthulhu says o::Union{Core.Box, Matrix{Float64}}
end

# ---------------------------------------------------------------------------------------------------
"""
	p1, p2, p3, p4 = bezier_newknots(p1::Vector{T}, p2::Vector{T}, p3::Vector{T}, p4::Vector{T}) where T

Convert the cubic Bezier control points 2 and 3 such that an original curve with these 4 knots
pass through these 4 points. Returns 4 vectors corresponding to new control points, where first and
last are repeated from input.
"""
function bezier_newknots(p1::Vector{T}, p2::Vector{T}, p3::Vector{T}, p4::Vector{T}) where {T <: Real}
	# https://forum.processing.org/two/discussion/21355/fixed-make-bezier-curve-pass-through-control-points.html
	c1 = hypot(p1[1]-p2[1], p1[2]-p2[2], p1[3]-p2[3])	# Distance between p1 and p2
	c2 = hypot(p2[1]-p3[1], p2[2]-p3[2], p2[3]-p3[3])
	c3 = hypot(p3[1]-p4[1], p3[2]-p4[2], p3[3]-p4[3])

	t1 = c1 / (c1 + c2 + c3)
	t2 = (c1 + c2) / (c1 + c2 + c3)

	b1 = (1 - t1)^3
	b2 = (1 - t2)^3
	b3 = t1^3
	b4 = t2^3

	# make curve segment lengths proportional to chord lengths
	a = t1 * (1 - t1) * (1 - t1) * 3
	b = (1 - t1) * t1 * t1 * 3
	c = t2 * (1 - t2) * (1 - t2) * 3
	d = (1 - t2) * t2 * t2 * 3

	x1, y1, z1 = p1;	x2, y2, z2 = p2;	x3, y3, z3 = p3;	x4, y4, z4 = p4
	e = x2 - (x1 * b1) - (x4 * b3)
	f = x3 - (x1 * b2) - (x4 * b4)
	g = y2 - (y1 * b1) - (y4 * b3)
	h = y3 - (y1 * b2) - (y4 * b4)
	i = z2 - (z1 * b1) - (z4 * b3)
	j = z3 - (z1 * b2) - (z4 * b4)

	x3 = (e - a / c * f) / (b - a * d / c)
	x2 = (e - (b * x3)) / a
	y3 = (g - a / c * h) / (b - a * d / c)
	y2 = (g - (b * y3)) / a
	z3 = (i - a / c * j) / (b - a * d / c)
	z2 = (i - (b * z3)) / a
	return Float64.(p1), [x2, y2, z2], [x3, y3, z3], Float64.(p4)
end
