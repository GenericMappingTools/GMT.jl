"""
    S = streamlines(U::GMTgrid, V::GMTgrid, startX, startY; step=0.1, max_vert::Int=10000)

Compute 2-D streamlines as a 2-D matrix (in fact, a GMTdataset) of vector fields.
The inputs `U` and `V` are GMTgrids with the `x` and `y` velocity components, and `startX` and
`startY` are the starting positions of the streamlines. `step` is the step size in data units for
interpolating the vector data and `max_vert` is the maximum number of vertices in a streamline.
`startX` and `startY` can both be scalars, vectors or one a scalar and the other a vector.
Returns a Vector{GMTdataset} with the streamlines.

    S = streamlines(U::GMTgrid, V::GMTgrid, D::GMTdataset; step=0.1, max_vert::Int=10000)

In this method the streamlines starting positions are fetch from the 2 columns of the `D` argument.
Returns a Vector{GMTdataset} with the streamlines.

    S, A = streamlines(U::GMTgrid, V::GMTgrid; step=0.1, max_vert::Int=10000)

Method that computes automatically spaced streamlines from 2D grids U and V. Returns the streamlines
in the `S` Vector{GMTdataset} and `A` holds the positions along the streamlines where to plot
arrow-heads if wished.

    S = streamlines(U::GMTgrid, V::GMTgrid; side::Union{String, Symbol}="left", step=0.1, max_vert::Int=10000)

Here we auto-generate the starting positions along one of the 4 sides of the grid. Select the wished side
with the `side` keyword. Returns a Vector{GMTdataset} with the streamlines.

    S = streamlines(x, y, U::Matrix, V::Matrix, sx, sy; step=0.1, max_vert::Int=10000)

This last 2D method let users pass the `x` and `y` vector data coordinates, U and V are matrices with the
velocity data and the remaining arguments have the same meaning as in the other methods. Returns a
Vector{GMTdataset} with the streamlines.

    S = streamlines(x::Matrix, y::Matrix, U::Matrix, V::Matrix; step=0.1, max_vert::Int=10000)

`x` and `y` are assumed to be meshgrids with the *x* and *y* starting coordinates.

    S = streamlines(U::GMTgrid, V::GMTgrid, W::GMTgrid, startX, startY, startZ; step=0.1, max_vert::Int=10000)

Conpute 3D volume of vector fields with streamline. Here `U`,`V` and `W` are 3D cubes with `x,y,z`
velocity components. `startX`, `startY` and `startZ` can be scalar or vector coordinate arrays.
Returns a Vector{GMTdataset} with the streamlines.

### Example
    x,y = GMT.meshgrid(-10:10);
    u = 2 .* x .* y;
    v = y .^2 - x .^ 2;
    U = mat2grid(u, x[1,:], y[:,1]);
    V = mat2grid(v, x[1,:], y[:,1]);
    r,a = streamlines(U, V);
    plot(r, decorated=(locations=a, symbol=(custom="arrow", size=0.3), fill=:black, dec2=true), show=1)
"""
function streamlines(x, y, U::Matrix, V::Matrix, sx, sy; step=0.1, max_vert::Int=10000)
	U = mat2grid(U, x, y)
	V = mat2grid(V, x, y)
	streamlines(U, V, sx, sy, step=step, max_vert=max_vert)
end
function streamlines(x::Matrix, y::Matrix, U::Matrix, V::Matrix; step=0.1, max_vert::Int=10000)
	# S... Matlab way.
	xx, yy = x[:,1], y[1,:]		# Assume x,y are meshgrid matrices
	_U = mat2grid(U, xx, yy)
	_V = mat2grid(V, xx, yy)
	streamlines(_U, _V, xx, yy, step=step, max_vert=max_vert)
end

function streamlines(U::GMTgrid, V::GMTgrid; side::Union{String, Symbol}="", step=0.1, max_vert::Int=10000, density=1, max_density=4)
	# This method auto-generates starting positions along one of the 4 sides of the grid.
	if (lowercase(string(side)) == "left")
		sy = (U.registration == 0) ? U.y : U.y[2:end] .- U.inc[2]/2
		sx = (U.registration == 0) ? fill(U.x[1], length(sy)) : fill(U.x[1]+U.inc[1]/2, length(sy))
	elseif (startswith(lowercase(string(side)), "bot"))
		sx = (U.registration == 0) ? U.x : U.x[2:end] .- U.inc[1]/2
		sy = (U.registration == 0) ? fill(U.y[1], length(sx)) : fill(U.y[1] + U.inc[2]/2, length(sx))
	elseif (lowercase(string(side)) == "top")
		sx = (U.registration == 0) ? U.x : U.x[2:end] .- U.inc[1]/2
		sy = (U.registration == 0) ? fill(U.y[end], length(sx)) : fill(U.y[end]-U.inc[2]/2, length(sx))
	elseif (lowercase(string(side)) == "right")
		sy = (U.registration == 0) ? U.y : U.y[2:end] .- U.inc[2]/2
		sx = (U.registration == 0) ? fill(U.x[end], length(sy)) : fill(U.x[end]-U.inc[1]/2, length(sy))
	else
		return equistreams(U, V; density=density, max_density=max_density)
	end
	streamlines(U, V, sx, sy, step=step, max_vert=max_vert)
end

function streamlines(U::GMTgrid, V::GMTgrid, sx, sy; step=0.1, max_vert::Int=10000)
	# Method that let one of sx or sy (or both) be a constant.
	if (isa(sx, Real) && isvector(sy))
		streamlines(U, V, fill(sx, length(sy)), sy, step=step, max_vert=max_vert)
	elseif (isa(sy, Real) && isvector(sx))
		streamlines(U, V, sx, fill(sx, length(sx)), step=step, max_vert=max_vert)
	elseif (isa(sx, Real) && isa(sy, Real))
		streamlines(U, V, [sx], [sy], step=step, max_vert=max_vert)
	end
end
function streamlines(U::GMTgrid, V::GMTgrid, D::GMTdataset; step=0.1, max_vert::Int=10000)
	# Method that sends the initial position in a GMTdataset
	streamlines(U, V, D.data[:,1], D.data[:,2], step, max_vert)
end

function streamlines(U::GMTgrid, V::GMTgrid, sx::VMr, sy::VMr; step=0.1, max_vert::Int=10000)
	# Method for 2D grids
	@assert(size(U) == size(V))
	(ndims(U) > 2) && error("This streamlines method is for 2D grids only. Not cubes.")

	n_allocated::Int = 2000
	n_rows::Int, n_cols::Int = size(U)
	isT = false
	if (!isempty(U.layout) && U.layout[2] == 'R')
		n_rows, n_cols, isT = n_cols, n_rows, true
	end

	x_flow = Vector{Float64}(undef, n_allocated)
	y_flow = Vector{Float64}(undef, n_allocated)

	# ---------------------------------------
	function helper_stream(x_pos, y_pos, x_vec, y_vec, n_rows, n_cols, isT, n_allocated)
		# x_pos,y_pos -> Streamline starting point
		n_vert = 1;
		while(true)
			(x_pos < 1 || x_pos >= n_cols || y_pos < 1 || y_pos >= n_rows || n_vert > max_vert) && break
	
			ind_x, ind_y = trunc(Int, x_pos), trunc(Int, y_pos)
			x_frac = x_pos - ind_x;
			y_frac = y_pos - ind_y;

			if (n_vert > n_allocated)				# Increase allocated mem by 50 %
				more_alloc::Int = round(Int, n_allocated * 0.5)
				append!(x_flow, Vector{Float64}(undef, more_alloc))
				append!(y_flow, Vector{Float64}(undef, more_alloc))
				n_allocated += more_alloc
			end

			dx = x_vec[ind_x+1] - x_vec[ind_x]	# Could be using grid's `inc` but this allows irregular grids
			dy = y_vec[ind_y+1] - y_vec[ind_y]
			x_flow[n_vert] = x_vec[ind_x] + x_frac * dx
			y_flow[n_vert] = y_vec[ind_y] + y_frac * dy

			# If it stops we are done
			(n_vert >= 2 && x_flow[n_vert] ≈ x_flow[n_vert-1] && y_flow[n_vert] ≈ y_flow[n_vert-1]) && break
			n_vert += 1

			if (isT)		# Grids have layout = TRB (read by GDAL) 
				ind_y, ind_x = ind_x, n_rows-ind_y+1
				u = bilinearRM(U, ind_x, ind_y, x_frac, y_frac)	# Interpolate u,v at current position
				v = bilinearRM(V, ind_x, ind_y, x_frac, y_frac)
			else
				u = bilinearCM(U, ind_x, ind_y, x_frac, y_frac)	# Interpolate u,v at current position
				v = bilinearCM(V, ind_x, ind_y, x_frac, y_frac)
			end

			(dx != 0) && (u /= dx)			# M/s * 1/M = s^-1
			(dy != 0) && (v /= dy)
			max_scaled_uv = (abs(u) > abs(v)) ? abs(u) : abs(v)	+ eps()	# s^-1
			x_pos += u * step / max_scaled_uv	# s^-1 * M / s^-1 = M
			y_pos += v * step / max_scaled_uv
		end

		return [x_flow[1:n_vert-1] y_flow[1:n_vert-1]], n_allocated
	end

	# Here we need to meshgrid when any of the locations is a vector
	if (length(sx) > 1 || length(sy) > 1)
		sx_, sy_ = meshgrid(Float64.(sx), Float64.(sy))
		_sx, _sy = sx_[:], sy_[:]
	else
		_sx, _sy = Float64.(sx[:]), Float64.(sy[:])
	end

	if     (length(U.x) == 1)  x_vec = U.y;	y_vec = U.z		# Take into account that they may be cube slices.
	elseif (length(U.y) == 1)  x_vec = U.x;	y_vec = U.z
	else                       x_vec = U.x;	y_vec = U.y
	end

	if (length(_sx) == 1)		# Scalar input
		x = interp_vec(x_vec, _sx[1])
		y = interp_vec(y_vec, _sy[1])
		t, n_allocated = helper_stream(x, y, x_vec, y_vec, n_rows, n_cols, isT, n_allocated)
		return !isempty(t) ? mat2ds(t) : GMTdataset()
	else
		D = Vector{GMTdataset}(undef, length(_sx))
		kk, c = 0, false
		for k = 1:numel(_sx)
			x = interp_vec(x_vec, _sx[k])
			y = interp_vec(y_vec, _sy[k])
			t, n_allocated = helper_stream(x, y, x_vec, y_vec, n_rows, n_cols, isT, n_allocated)
			!isempty(t) ? (D[kk += 1] = mat2ds(t)) : (c = true)
		end
		(c) && deleteat!(D, kk+1:length(_sx))	# If some were empty we must remove them (they are at the end)
		set_dsBB!(D)							# Compute and set the global BoundingBox for this dataset
	end
	return D
end

# -----------------------------------------------------------------------------------------------------------
function streamlines(U::GMTgrid, V::GMTgrid, W::GMTgrid; axis::Bool=false, startx::Union{Nothing, Real}=nothing,
		starty::Union{Nothing, Real}=nothing, startz::Union{Nothing, Real}=nothing, step=0.1, max_vert::Int=10000)
	# Method where only one of startx, starty, startz is valid and we do a slice of the cube at that dimension.
	# Ex: D, = streamlines(U, V, W, startz=5, axis=true);
	(startx === nothing && starty === nothing && startz === nothing) && error("Must select which dimension to slice.")
	@assert(size(U) == size(V));	@assert(size(V) == size(W))
	(ndims(U) != 3) && error("This streamlines method is for cubes only.")

	if (axis)
		(startx !== nothing) && (A = slicecube(V, startx, axis="x");	B = slicecube(W, startx, axis="x"))
		(starty !== nothing) && (A = slicecube(U, starty, axis="y");	B = slicecube(W, starty, axis="y"))
		(startz !== nothing) && (A = slicecube(U, startz, axis="z");	B = slicecube(V, startz, axis="z"))
	end
	s,a = streamlines(A, B, step=step, max_vert=max_vert)

	return s,a
end

# -----------------------------------------------------------------------------------------------------------
function streamlines(U::GMTgrid, V::GMTgrid, W::GMTgrid, startx, starty, startz; step=0.1, max_vert::Int=10000)
	# Method that let startx, starty or startz be a constant or vectors
	@assert(size(U) == size(V));	@assert(size(V) == size(W))
	(ndims(U) != 3) && error("This streamlines method is for cubes only.")

	x_len = isvector(startx) ? length(startx) : 1
	y_len = isvector(starty) ? length(starty) : 1
	z_len = isvector(startz) ? length(startz) : 1
	len = max(z_len, max(x_len, y_len))
	if (len == 1)		# They are all scalars
		streamlines(U, V, W, [startx], [starty], [startz], step=step, max_vert=max_vert)
	else
		streamlines(U, V, W, (x_len == 1) ? [startx] : startx, (y_len == 1) ? [starty] : starty, (z_len == 1) ? [startz] : startz, step=step, max_vert=max_vert)
	end
end

# -----------------------------------------------------------------------------------------------------------
function streamlines(U::GMTgrid, V::GMTgrid, W::GMTgrid, sx::VMr, sy::VMr, sz::VMr; step=0.1, max_vert::Int=10000)

	n_allocated::Int = 2000
	n_rows::Int, n_cols::Int, n_levels::Int = size(U)
	isT::Bool = false
	if (!isempty(U.layout) && U.layout[2] == 'R')
		n_rows, n_cols, isT = n_cols, n_rows, true
	end

	x_flow = Vector{Float64}(undef, n_allocated)
	y_flow = Vector{Float64}(undef, n_allocated)
	z_flow = Vector{Float64}(undef, n_allocated)
	z_coord::Vector{Float64} = Float64.(W.v)

	# ------------------------------------------
	function helper_stream(x, y, z, n_rows, n_cols, isT, n_allocated)
		# x,y,z -> Streamline starting point
		n_vert = 1;
		while(true)
			(x < 1 || x >= n_cols || y < 1 || y >= n_rows || z < 1 || z >= n_levels || n_vert > max_vert) && break
	
			ind_x, ind_y, ind_z = trunc(Int, x), trunc(Int, y), trunc(Int, z)
			x_frac, y_frac, z_frac = x - ind_x, y - ind_y, z - ind_z

			if (n_vert > n_allocated)				# Increase allocated mem by 50 %
				more_alloc::Int = round(Int, n_allocated * 0.5)
				append!(x_flow, Vector{Float64}(undef, more_alloc))
				append!(y_flow, Vector{Float64}(undef, more_alloc))
				append!(z_flow, Vector{Float64}(undef, more_alloc))
				n_allocated += more_alloc
			end

			dx = U.x[ind_x+1] - U.x[ind_x]	# Could be using grid's `inc` but this allows irregular grids
			dy = U.y[ind_y+1] - U.y[ind_y]
			dz = z_coord[ind_z+1] - z_coord[ind_z]
			x_flow[n_vert] = U.x[ind_x] + x_frac * dx
			y_flow[n_vert] = U.y[ind_y] + y_frac * dy
			z_flow[n_vert] = z_coord[ind_z] + z_frac * dz

			# If it stops we are done
			(n_vert >= 2 && x_flow[n_vert] ≈ x_flow[n_vert-1] && y_flow[n_vert] ≈ y_flow[n_vert-1] && z_flow[n_vert] ≈ z_flow[n_vert-1]) && break
			n_vert += 1

			if (isT)		# Grids have layout = TRB (read by GDAL) 
				ind_y, ind_x = ind_x, n_rows-ind_y+1
				u = bilinearRM(U, ind_x, ind_y, ind_z, x_frac, y_frac, z_frac)
				v = bilinearRM(V, ind_x, ind_y, ind_z, x_frac, y_frac, z_frac)
				w = bilinearRM(W, ind_x, ind_y, ind_z, x_frac, y_frac, z_frac)
			else
				u = bilinearCM(U, ind_x, ind_y, ind_z, x_frac, y_frac, z_frac)
				v = bilinearCM(V, ind_x, ind_y, ind_z, x_frac, y_frac, z_frac)
				w = bilinearCM(W, ind_x, ind_y, ind_z, x_frac, y_frac, z_frac)
			end

			(dx != 0) && (u /= dx)			# M/s * 1/M = s^-1
			(dy != 0) && (v /= dy)
			(dz != 0) && (w /= dz)

			max_scaled_uvw = (abs(u) > abs(v)) ? abs(u) : abs(v) + eps()	# s^-1
			(abs(w) > max_scaled_uvw) && (max_scaled_uvw = abs(w))
			#(max_scaled_uvw == 0) && break
			x += u * step / max_scaled_uvw	# s^-1 * M / s^-1 = M
			y += v * step / max_scaled_uvw
			z += w * step / max_scaled_uvw
		end

		return [x_flow[1:n_vert-1] y_flow[1:n_vert-1] z_flow[1:n_vert-1]], n_allocated
	end

	# Here we need to meshgrid when any of the locations is a vector
	if (length(sx) > 1 || length(sy) > 1 || length(sz) > 1)
		sx_, sy_, sz_ = meshgrid(Float64.(sx), Float64.(sy), Float64.(sz))
		_sx, _sy, _sz = sx_[:], sy_[:], sz_[:]
	else
		_sx, _sy, _sz = Float64.(sx[:]), Float64.(sy[:]), Float64.(sz[:])
	end

	if (length(_sx) == 1)		# Scalar input
		x = interp_vec(U.x,  _sx[1])
		y = interp_vec(V.y,  _sy[1])
		z = interp_vec(z_coord, _sz[1])
		t, n_allocated = helper_stream(x, y, z, n_rows, n_cols, isT, n_allocated)
		return !isempty(t) ? mat2ds(t) : GMTdataset()
	else
		D = Vector{GMTdataset}(undef, length(_sx))
		kk, c = 0, false
		for k = 1:numel(_sx)
			x = interp_vec(U.x,  _sx[k])
			y = interp_vec(V.y,  _sy[k])
			z = interp_vec(z_coord, _sz[k])
			t, n_allocated = helper_stream(x, y, z, n_rows, n_cols, isT, n_allocated)
			!isempty(t) ? (D[kk += 1] = mat2ds(t)) : (c = true)
		end
		(c) && deleteat!(D, kk+1:length(_sx))	# If some were empty we must remove them (they are at the end)
		set_dsBB!(D)							# Compute and set the global BoundingBox for this dataset
	end
	return D
end

# -----------------------------------------------------------------------------
function bilinearCM(V, ind_x, ind_y, x_frac, y_frac)				# 2D
	# Method for grid with a layout BC, that is ColumnMajor
	v1 = V[ind_y,   ind_x] + (V[ind_y,   ind_x+1] - V[ind_y,   ind_x]) * x_frac
	v2 = V[ind_y+1, ind_x] + (V[ind_y+1, ind_x+1] - V[ind_y+1, ind_x]) * x_frac
	v1 + (v2 - v1) * y_frac
end
function bilinearCM(V, ind_x, ind_y, ind_z, x_frac, y_frac, z_frac)	# 3D
	v1 = V[ind_y,   ind_x, ind_z] + (V[ind_y,   ind_x+1, ind_z] - V[ind_y,   ind_x, ind_z]) * x_frac
	v2 = V[ind_y+1, ind_x, ind_z] + (V[ind_y+1, ind_x+1, ind_z] - V[ind_y+1, ind_x, ind_z]) * x_frac
	vxyz1 = v1 + (v2 - v1) * y_frac
	v1 = V[ind_y,   ind_x, ind_z+1] + (V[ind_y,   ind_x+1, ind_z+1] - V[ind_y,   ind_x, ind_z+1]) * x_frac
	v2 = V[ind_y+1, ind_x, ind_z+1] + (V[ind_y+1, ind_x+1, ind_z+1] - V[ind_y+1, ind_x, ind_z+1]) * x_frac
	vxyz2 = v1 + (v2 - v1) * y_frac
	vxyz1 + (vxyz2 - vxyz1) * z_frac
end
function bilinearRM(V, ind_x, ind_y, x_frac, y_frac)				# 2D
	# Method for grid with a layout TR, that is RowMajor (as those recived when reading with GDAL)
	v1 = V[ind_y,   ind_x] + (V[ind_y+1, ind_x]   - V[ind_y, ind_x])   * x_frac
	v2 = V[ind_y, ind_x-1] + (V[ind_y+1, ind_x-1] - V[ind_y, ind_x-1]) * x_frac
	v1 + (v2 - v1) * y_frac
end
function bilinearRM(V, ind_x, ind_y, ind_z, x_frac, y_frac, z_frac)	# 3D
	v1 = V[ind_y,   ind_x, ind_z] + (V[ind_y+1, ind_x,   ind_z] - V[ind_y, ind_x,   ind_z]) * x_frac
	v2 = V[ind_y, ind_x-1, ind_z] + (V[ind_y+1, ind_x-1, ind_z] - V[ind_y, ind_x-1, ind_z]) * x_frac
	vxyz1 = v1 + (v2 - v1) * y_frac
	v1 = V[ind_y,   ind_x, ind_z+1] + (V[ind_y+1, ind_x,   ind_z+1] - V[ind_y, ind_x,   ind_z+1]) * x_frac
	v2 = V[ind_y, ind_x-1, ind_z+1] + (V[ind_y+1, ind_x-1, ind_z+1] - V[ind_y, ind_x-1, ind_z+1]) * x_frac
	vxyz2 = v1 + (v2 - v1) * y_frac
	vxyz1 + (vxyz2 - vxyz1) * z_frac
end

# ----------------------------------------------------------------------------------
function equistreams(u::GMTgrid, v::GMTgrid; density=1, max_density=4)
	# This function uses a modified version of Matlab's nicestream() function which is a variant of:
	#
	# Jobard, B., & Lefer, W. (1997). Creating Evenly-Spaced Streamlines of
	# Arbitrary Density. In W. Lefer & M. Grave (Eds.), Visualization in
	# Scientific Computing ?97: Proceedings of the Eurographics Workshop in
	# Boulogne-sur-Mer France, April 28--30, 1997 (pp. 43?55). inbook,
	# Vienna: Springer Vienna. http://doi.org/10.1007/978-3-7091-6876-9_5

	x, y = u.x, u.y

	step = min(0.1, (minimum(size(v))-1)/100)
	max_vert::Int = Int(min(10000,sum(size(v))*2/step))

	n_rows_coarse = ceil(Int, size(u,1)*density)
	n_cols_coarse = ceil(Int, size(u,2)*density)
	n_rows_fine = ceil(Int, size(u,1)*density*max_density)
	n_cols_fine = ceil(Int, size(u,2)*density*max_density)

	xmin, ymin = minimum(x), minimum(y)
	x_range = maximum(x) - xmin
	y_range = maximum(y) - ymin

	inc_x_coarse = x_range/n_cols_coarse
	inc_y_coarse = y_range/n_rows_coarse
	inc_x_fine = x_range/n_cols_fine
	inc_y_fine = y_range/n_rows_fine

	startgrid = zeros(Bool, n_rows_coarse, n_cols_coarse)
	endgrid   = zeros(Bool, n_rows_fine, n_cols_fine)

	vo = Vector{Matrix{<:Real}}(undef, 2)
	D  = Vector{GMTdataset}(undef, n_rows_coarse*n_cols_coarse)
	count_streams = 0

	for r = 1:n_rows_coarse, c = 1:n_cols_coarse	# Changing the loops order changes the result. And this makes a symetric case symetric
		startgrid[r,c] && continue		# One line already passed in this cell
		startgrid[r,c] = true
		xstart = xmin + (c-0.5) * inc_x_coarse
		ystart = ymin + (r-0.5) * inc_y_coarse
		t = streamlines(u,  v, xstart, ystart; step=step, max_vert=max_vert)
		vertsf::Matrix{Float64} = streamlines(u,  v, xstart, ystart; step=step, max_vert=max_vert).data
		vertsb::Matrix{Float64} = streamlines(-u,-v, xstart, ystart; step=step, max_vert=max_vert).data
		(isempty(vertsf) || isempty(vertsb)) && continue	# Maybe we are loosing a good one but it would error below

		for q = 1:2
			vv = (q == 1) ? vertsf : vertsb
			tcc = floor(Int, (vv[1,1]-xmin) / inc_x_fine) + 1
			trr = floor(Int, (vv[1,2]-ymin) / inc_y_fine) + 1

			jj = 0
			for j = 1:size(vv,1)
				xc, yc = vv[j,1], vv[j,2]

				# Find the cell that is crossed by the flowline and flag it so it wont be the locus of
				# starting a new one.
				cc::Int = floor(Int, (xc-xmin) / inc_x_coarse ) + 1
				rr::Int = floor(Int, (yc-ymin) / inc_y_coarse ) + 1
				(cc <= n_cols_coarse && rr <= n_rows_coarse) && (startgrid[rr,cc] = true)

				# Now use the finer grid. All nodes visited by a flowline is flagged sutch it will not
				# be the locus of starting flowline and if a growing one crosses that cell it will be finished.
				cc = floor(Int, (xc-xmin) / inc_x_fine) + 1
				rr = floor(Int, (yc-ymin) / inc_y_fine) + 1
				if (cc > n_cols_fine || rr > n_rows_fine)
					break
				elseif endgrid[rr,cc]
					~(any(cc == tcc) && any(rr == trr)) && break
				else
					tcc = cc;		trr = rr;
					endgrid[rr,cc] = true
				end
				jj = j
			end
			vo[q] = vv[1:jj-1, :];
		end
		D[count_streams += 1] = mat2ds([vo[2][end:-1:1,:]; vo[1][2:end,:]])
	end
	deleteat!(D, count_streams+1:n_rows_coarse*n_cols_coarse)
	set_dsBB!(D)				# Compute and set the global BoundingBox for this dataset
	A = arrowheads_pos(D, x, y, n_cols_coarse, n_rows_coarse)
	return D, A
end

# -----------------------------------------------------
function arrowheads_pos(D, x, y, n_cols_coarse, n_rows_coarse)
	# Estimate the position along the flowlines in D where to put the arrow heads.
	xmin, ymin = minimum(x), minimum(y)
	inv_range_x = n_cols_coarse / (maximum(x) - xmin)
	inv_range_y = n_rows_coarse / (maximum(y) - ymin)
	arrowgrid = ones(Bool, n_rows_coarse, n_cols_coarse)
	arrowgrid[2:3:end, 2:3:end] .= false
	Da = Vector{GMTdataset}(undef, length(D))
	this_stream = Matrix{Float64}(undef, 50, 2)
	count = 0

	for k = 1:numel(D)
		jj = 0
		for j = 1:size(D[k], 1)
			xc, yc = D[k][j,1], D[k][j,2]
			c = floor(Int, (xc-xmin) * inv_range_x) + 1
			r = floor(Int, (yc-ymin) * inv_range_y) + 1
			if (!arrowgrid[r,c] && j > 1 && c > 0 && c <= n_cols_coarse && r > 0 && r <= n_rows_coarse)
				this_stream[jj+=1, :] = [xc yc]
				arrowgrid[r,c] = true
			end
		end
		(jj > 0) && (Da[count += 1] = mat2ds(this_stream[1:jj, :]))
	end
	deleteat!(Da, count+1:length(D))
	set_dsBB!(Da)				# Compute and set the global BoundingBox for this dataset
	Da
end

#=
function expandmat!(mat; nrows::Int=0, ncols::Int=0, fill=nothing)
	ny,nx = size(mat)
	mat = reshape(mat, nx*ny)
	if (ncols > 0)
	else
		append!(mat, Vector{eltype(mat)}(undef, nx * nrows))
		c = 0
		for col = nx:-1:2
			iend = ny * nx - c*ny;		istart = iend - ny + 1
			println("col = ",col, "\t\tistart = ",istart, "\tiend = ",iend)
			n = 0
			for k = iend:-1:istart
				kk = col*(ny+nrows)-nrows - n
				mat[kk] = mat[k]
				n += 1
				println("  daqui = ",k,"\tprali = ",kk)
			end
			c += 1
		end
		mat = reshape(mat, ny+nrows, nx)
	end
end
=#