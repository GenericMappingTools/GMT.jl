"""
  streamlines(U::GMTgrid, V::GMTgrid, startX, startY, step=0.1, max_vert::Int=10000)

Compute 2-D streamlines as a 2-D matrix (in fact, a GMTdataset) of vector fields.
The inputs `U` and `V` are GMTgrids with the ``x`` and ``y`` velocity components, and `startX` and
`startY` are the starting positions of the streamlines. `step` is the step size in data units for
interpolating the vector data and `max_vert` is the maximum number of vertices in a streamline.

`startX` and `startY` can both be scalars, vectors or one a scalar and the other a vector.

  streamlines(U::GMTgrid, V::GMTgrid, D::GMTdataset, step=0.1, max_vert::Int=10000)

In this method the streamlines starting positions are fetch from the 2 columns of the `D` argument.

  streamlines(U::GMTgrid, V::GMTgrid; side::Union{String, Symbol}="left", step=0.1, max_vert::Int=10000)

Here we auto-generate the starting positions along one of the 4 sides of the grid.

  streamlines(x, y, U::Matrix, V::Matrix, sx, sy, step=0.1, max_vert::Int=10000)

This last method let users pass the `x` and `y` vector data coordinates, U and V are matrices with the
velocity data and the remaining arguments have the same meaning as in the other methods.
"""
function streamlines(x, y, Ugrd::Matrix, Vgrd::Matrix, sx, sy, step=0.1, max_vert::Int=10000)
	U = mat2grid(Ugrd, x, y)
	V = mat2grid(Vgrd, x, y)
	streamlines(U, V, sx, sy, step, max_vert)
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
	streamlines(U, V, sx, sy, step, max_vert)
end

function streamlines(U::GMTgrid, V::GMTgrid, sx, sy, step=0.1, max_vert::Int=10000)
	# Method that let one of sx or sy (or both) be a constant.
	if (isa(sx, Real) && isvector(sy))
		streamlines(U, V, fill(sx, length(sy)), sy, step, max_vert)
	elseif (isa(sy, Real) && isvector(sx))
		streamlines(U, V, sx, fill(sx, length(sx)), step, max_vert)
	elseif (isa(sx, Real) && isa(sy, Real))
		streamlines(U, V, [sx], [sy], step, max_vert)
	end
end
function streamlines(U::GMTgrid, V::GMTgrid, D::GMTdataset, step=0.1, max_vert::Int=10000)
	# Method that sends the initial position in a GMTdataset
	streamlines(U, V, D.data[:,1], D.data[:,2], step, max_vert)
end

function streamlines(Ugrd::GMTgrid, Vgrd::GMTgrid, sx::VMr, sy::VMr, step=0.1, max_vert::Int=10000)

	n_rows::Int, n_cols::Int = size(Ugrd)
	n_allocated::Int = 2000

	x_flow = Vector{Float64}(undef, n_allocated)
	y_flow = Vector{Float64}(undef, n_allocated)

	# ------------------------------------------------
	function bilinear(V, ind_x, ind_y, x_frac, y_frac)
		v1 = V[ind_y, ind_x]   + (V[ind_y, ind_x+1]   - V[ind_y, ind_x])   * x_frac
		v2 = V[ind_y+1, ind_x] + (V[ind_y+1, ind_x+1] - V[ind_y+1, ind_x]) * x_frac
		v1 + (v2 - v1) * y_frac
	end

	# -------------------------
	function interp_vec(x, val)
		# Returns the positional fraction that `val` ocupies in the `x` vector 
		(val < x[1] || val > x[end]) && error("Interpolating point is not inside the vector range.")
		k = 0
		while(val < x[k+=1]) end
		frac = (val - x[k]) / (x[k+1] - x[k])
		return k + frac
	end

	# ---------------------------------------
	function helper_stream(x, y, n_allocated)
		# x,y -> Streamline starting point
		n_vert = 1;
		while(true)
			(x < 1 || x >= n_cols || y < 1 || y >= n_rows || n_vert > max_vert) && break
	
			ind_x, ind_y = trunc(Int, x), trunc(Int, y)
			x_frac = x - ind_x;
			y_frac = y - ind_y;

			if (n_vert > n_allocated)				# Increase allocated mem by 50 %
				more_alloc::Int = round(Int, n_allocated * 0.5)
				append!(x_flow, Vector{Float64}(undef, more_alloc))
				append!(y_flow, Vector{Float64}(undef, more_alloc))
				n_allocated += more_alloc
			end

			dx = Ugrd.x[ind_x+1] - Ugrd.x[ind_x]	# Could be using grid's `inc` but this allows irregular grids
			dy = Ugrd.y[ind_y+1] - Ugrd.y[ind_y]
			x_flow[n_vert] = Ugrd.x[ind_x] + x_frac * dx
			y_flow[n_vert] = Ugrd.y[ind_y] + y_frac * dy

			# If it stops we are done
			(n_vert >= 2 && x_flow[n_vert] == x_flow[n_vert-1] && y_flow[n_vert] == y_flow[n_vert-1]) && break
			n_vert += 1

			u = bilinear(Ugrd, ind_x, ind_y, x_frac, y_frac)
			v = bilinear(Vgrd, ind_x, ind_y, x_frac, y_frac)

			(dx != 0) && (u /= dx)			# M/s * 1/M = s^-1
			(dy != 0) && (v /= dy)

			max_scaled_uv = (abs(u) > abs(v)) ? abs(u) : abs(v)		# s^-1
			u *= step / max_scaled_uv		# s^-1 * M / s^-1 = M
			v *= step / max_scaled_uv
			x += u;		y  += v
		end

		deleteat!(x_flow, n_vert:length(x_flow))
		deleteat!(y_flow, n_vert:length(y_flow))
		n_allocated = n_vert-1	# Update this because we may needed in next (eventual) flowline
		return [x_flow y_flow], n_allocated
	end

	if (length(sy) == 1)		# Scalar input
		x = interp_vec(Ugrd.x, sx[1])
		y = interp_vec(Ugrd.y, sy[1])
		t, n_allocated = helper_stream(x, y, n_allocated)
		return !isempty(t) ? mat2ds(t) : nothing
	else
		D = Vector{GMTdataset}(undef, length(sy))
		kk, c = 0, false
		for k = 1:length(sy)
			x = interp_vec(Ugrd.x, sx[k])
			y = interp_vec(Ugrd.y, sy[k])
			t, n_allocated = helper_stream(x, y, n_allocated)
			!isempty(t) ? (D[kk += 1] = mat2ds(t)) : (c = true)
		end
		(c) && deleteat!(D, kk+1:length(sy))	# If some were empty we must remove them (they are at the end)
		set_dsBB!(D)							# Compute and set the global BoundingBox for this dataset
	end
	return D
end

# -----------------------------------------------------------------------------------------------------------
function streamlines(Ugrd::GMTgrid, Vgrd::GMTgrid, Wgrd::GMTgrid, sx::VMr, sy::VMr, sz::VMr, step=0.1, max_vert::Int=10000)

	n_rows::Int, n_cols::Int, n_levels::Int = size(Ugrd)
	n_allocated::Int = 2000

	x_flow = Vector{Float64}(undef, n_allocated)
	y_flow = Vector{Float64}(undef, n_allocated)
	z_flow = Vector{Float64}(undef, n_allocated)

	# ------------------------------------------
	function helper_stream(x, y, z, n_allocated)
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

			dx = Ugrd.x[ind_x+1] - Ugrd.x[ind_x]	# Could be using grid's `inc` but this allows irregular grids
			dy = Ugrd.y[ind_y+1] - Ugrd.y[ind_y]
			dz = Wgrd.v[ind_z+1] - Wgrd.v[ind_z]
			x_flow[n_vert] = Ugrd.x[ind_x] + x_frac * dx
			y_flow[n_vert] = Ugrd.y[ind_y] + y_frac * dy
			z_flow[n_vert] = Wgrd.v[ind_z] + z_frac * dz

			# If it stops we are done
			(n_vert >= 2 && x_flow[n_vert] == x_flow[n_vert-1] && y_flow[n_vert] == y_flow[n_vert-1] && z_flow[n_vert] == z_flow[n_vert-1]) && break
			n_vert += 1

			u = bilinear(Ugrd, ind_x, ind_y, ind_z, x_frac, y_frac, z_frac)
			v = bilinear(Vgrd, ind_x, ind_y, ind_z, x_frac, y_frac, z_frac)
			w = bilinear(Wgrd, ind_x, ind_y, ind_z, x_frac, y_frac, z_frac)

			(dx != 0) && (u /= dx)			# M/s * 1/M = s^-1
			(dy != 0) && (v /= dy)
			(dz != 0) && (w /= dz)

			max_scaled_uvw = (abs(u) > abs(v)) ? abs(u) : abs(v)		# s^-1
			(abs(w) > max_scaled_uvw) && (max_scaled_uvw = abs(w))
			u *= step / max_scaled_uvw		# s^-1 * M / s^-1 = M
			v *= step / max_scaled_uvw
			w *= step / max_scaled_uvw
			x += u;		y  += v;	z += w
		end

		deleteat!(x_flow, n_vert:length(x_flow))
		deleteat!(y_flow, n_vert:length(y_flow))
		deleteat!(z_flow, n_vert:length(z_flow))
		n_allocated = n_vert-1	# Update this because we may needed in next (eventual) flowline
		return [x_flow y_flow z_flow], n_allocated
	end

	if (length(sy) == 1)		# Scalar input
		x = interp_vec(Ugrd.x, sx[1])
		y = interp_vec(Vgrd.y, sy[1])
		v = interp_vec(Wgrd.v, sz[1])
		t, n_allocated = helper_stream(x, y, v, n_allocated)
		return !isempty(t) ? mat2ds(t) : nothing
	else
		D = Vector{GMTdataset}(undef, length(sy))
		kk, c = 0, false
		for k = 1:length(sy)
			x = interp_vec(Ugrd.x, sx[k])
			y = interp_vec(Vgrd.y, sy[k])
			v = interp_vec(Wgrd.v, sz[k])
			t, n_allocated = helper_stream(x, y, v, n_allocated)
			!isempty(t) ? (D[kk += 1] = mat2ds(t)) : (c = true)
		end
		(c) && deleteat!(D, kk+1:length(sy))	# If some were empty we must remove them (they are at the end)
		set_dsBB!(D)							# Compute and set the global BoundingBox for this dataset
	end
	return D
end

# -----------------------------------------------------------------------------
function bilinear(V, ind_x, ind_y, x_frac, y_frac)					# 2D
	v1 = V[ind_y, ind_x]   + (V[ind_y, ind_x+1]   - V[ind_y, ind_x])   * x_frac
	v2 = V[ind_y+1, ind_x] + (V[ind_y+1, ind_x+1] - V[ind_y+1, ind_x]) * x_frac
	v1 + (v2 - v1) * y_frac
end
function bilinear(V, ind_x, ind_y, ind_z, x_frac, y_frac, z_frac)	# 3D
	v1 = V[ind_y, ind_x, ind_z]   + (V[ind_y, ind_x+1, ind_z]   - V[ind_y, ind_x, ind_z])   * x_frac
	v2 = V[ind_y+1, ind_x, ind_z] + (V[ind_y+1, ind_x+1, ind_z] - V[ind_y+1, ind_x, ind_z]) * x_frac
	vxyz1 = v1 + (v2 - v1) * y_frac
	v1 = V[ind_y, ind_x, ind_z+1]   + (V[ind_y, ind_x+1, ind_z+1]   - V[ind_y, ind_x, ind_z+1])   * x_frac
	v2 = V[ind_y+1, ind_x, ind_z+1] + (V[ind_y+1, ind_x+1, ind_z+1] - V[ind_y+1, ind_x, ind_z+1]) * x_frac
	vxyz2 = v1 + (v2 - v1) * y_frac
	vxyz1 + (vxyz2 - vxyz1) * z_frac
end
# -------------------------
function interp_vec(x, val)
	# Returns the positional fraction that `val` ocupies in the `x` vector 
	(val < x[1] || val > x[end]) && error("Interpolating point is not inside the vector range.")
	k = 0
	while(val < x[k+=1]) end
	frac = (val - x[k]) / (x[k+1] - x[k])
	return k + frac
end

# ----------------------------------------------------------------------------------
function equistreams(u::GMTgrid, v::GMTgrid; density=1, max_density=4)
	# This function uses a modified version of the Mathworks nicestream() function which is a variant of:
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

	# startgrid and endgrid are used to keep track of the location/density of streamlines.
	# As new streamlines are created, the values in these matrices will indicate whether a
	# streamline has passed through each quadrant of the data space. startgrid is coarser grid,
	# while endgrid is a finer grid. startgrid is used to decide whether to start a new streamline.
	# If an existing streamline has already passed through a quadrant, we won't start a new streamline.
	# endgrid is used to limit the density of the final streamlines. New streamlines will stop when
	# the reach a quandrant that is already occupied by an existing streamline.
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
		vertsf::Matrix{Float64} = streamlines(u,  v, xstart, ystart, step, max_vert).data
		vertsb::Matrix{Float64} = streamlines(-u,-v, xstart, ystart, step, max_vert).data
		(isempty(vertsf) || isempty(vertsb)) && continue	# Maybe we are loosing a good one but it would error below

		for q = 1:2
			vv = (q == 1) ? vertsf : vertsb
			tcc = floor(Int, (vv[1,1]-xmin) / inc_x_fine) + 1
			trr = floor(Int, (vv[1,2]-ymin) / inc_y_fine) + 1

			jj = 0
			for j = 1:size(vv,1)
				xc, yc = vv[j,1], vv[j,2]

				# Calculate indices into startgrid (rr,cc), based on the coordinates of this particular
				# data point on this streamline. As a streamline passes through coordinates,
				# mark them off so that we do not start new streamlines in those coordinates.
				cc::Int = floor(Int, (xc-xmin) / inc_x_coarse ) + 1
				rr::Int = floor(Int, (yc-ymin) / inc_y_coarse ) + 1
				(cc <= n_cols_coarse && rr <= n_rows_coarse) && (startgrid[rr,cc] = true)

				# Now calculate rr and cc using a finer mesh so that they are indices into endgrid.
				# As a streamline passes through coordinates, mark them off so that we do not start
				# new streamlines in those coordinates. If a new streamline hits an existing streamline,
				# then the new streamline will be truncated.
				cc = floor(Int, (xc-xmin) / inc_x_fine) + 1
				rr = floor(Int, (yc-ymin) / inc_y_fine) + 1
				if (cc > n_cols_fine || rr > n_rows_fine)
					break
				elseif endgrid[rr,cc]
					if ~(any(cc == tcc) && any(rr == trr))
						break
					end
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

	for k = 1:length(D)
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