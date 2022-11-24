# Collect generic utility functions in this file

""" Return the decimal part of a float number `x`"""
getdecimal(x::AbstractFloat) = x - trunc(Int, x)

""" Return an ierator over data skipping non-finite values"""
skipnan(itr) = Iterators.filter(el->isfinite(el), itr)

square(x) = x^2

function funcurve(f::Function, lims::VMr, n=100)
	# Geneate a curve between lims[1] and lims[2] having the form of function 'f'
	if     (f == exp)    x = log.(lims)
	elseif (f == log)    x = exp.(lims)
	elseif (f == log10)  x = exp10.(lims)
	elseif (f == exp10)  x = log10.(lims)
	elseif (f == sqrt)   x = square.(lims)
	elseif (f == square) x = sqrt.(lims)
	else   error("Function $f not implemented in funcurve().")
	end
	f.(linspace(x[1], x[2], n))
end

"""
    x, y = pol2cart2(theta, rho; deg=false)

Transform polar to Cartesian coordinates. Angles are in radians by default.
Use `deg=true` if angles are in degrees. Input can be scalar, vectors or matrices.
"""
function pol2cart(theta, rho; deg::Bool=false)
	return (deg) ? (rho .* cosd.(theta), rho .* sind.(theta)) : (rho .* cos.(theta), rho .* sin.(theta))
end

"""
    theta, rho = cart2pol(x, y; deg=false)

Transform Cartesian to polar coordinates. Angles are returned in radians by default.
Use `deg=true` to return the angles in degrees. Input can be scalar, vectors or matrices.
"""
cart2pol(x, y; deg::Bool=false) = (deg) ? atand.(y,x) : atan.(y,x), hypot.(x,y)


"""
    x, y, z = sph2cart(az, elev, rho; deg=false)

Transform spherical coordinates to Cartesian. Angles are in radians by default.
Use `deg=true` if angles are in degrees. Input can be scalar, vectors or matrices.
"""
function sph2cart(az, elev, rho; deg::Bool=false)
	z = rho .* ((deg) ? sind.(elev) : sin.(elev))
	t = rho .* ((deg) ? cosd.(elev) : cos.(elev))
	x = t   .* ((deg) ? cosd.(az)   : cos.(az))
	y = t   .* ((deg) ? sind.(az)   : sin.(az))
	return x,y,z
end

"""
    az, elev, rho = cart2sph(x, y, z; deg=false)

Transform Cartesian coordinates to spherical. Angles are returned in radians by default.
Use `deg=true` to return the angles in degrees. Input can be scalar, vectors or matrices.
"""
function cart2sph(x, y, z; deg::Bool=false)
	h,  = hypot.(x, y)
	rho = hypot.(h, z)
	elev = (deg) ? atand.(z, h) : atan.(z, h)
	az   = (deg) ? atand.(y, x) : atan.(y, x)
	return az, elev, rho
end

"""
    ind = uniqueind(x)

Return the index `ind` such that x[ind] gets the unique values of x. No sorting is done
"""
uniqueind(x) = unique(i -> x[i], eachindex(x))

"""
    u, ind = gunique(x::AbstractVector; sorted=false)

Return an array containing only the unique elements of `x` and the indices `ind` such that `u = x[ind]`.
If `sorted` is true the output is sorted (default is not)
"""
function gunique(x::AbstractVector; sorted::Bool=false)

	function uniquit(x)
		if sorted
			_ind = sortperm(x)
			_x = x[_ind]
			ind = uniqueind(_x)
			return _x[ind], _ind[ind]
		else
			ind = uniqueind(x)
			return x[ind], ind
		end
	end

	if (eltype(x) <: AbstractFloat && any(isnan.(x)))
		uniquit(collect(skipnan(x)))
	else
		uniquit(x)
	end
end

#= ------------------------------------------------------------
"""
Delete rows from a matrix where any of its columns has a NaN
"""
function del_mat_row_nans(mat)
	nanrows = any(isnan.(mat), dims=2)
	return (any(nanrows)) ? mat[vec(.!nanrows),:] : mat
end
=#
