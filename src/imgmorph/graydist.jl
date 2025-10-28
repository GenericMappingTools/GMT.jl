# Written by Claude
# ----------------------------------------------------------------------------------------
function graydist(I::AbstractMatrix, ind::Union{Vector{Int}, Int}, method="quasi-euclidean")
	mask = falses(size(I))
	isa(ind, Int) ? (mask[ind] = true) : (mask[ind] .= true)
	return graydist(I, mask, method)
end
function graydist(I::AbstractMatrix, i::Integer, j::Integer, method="quasi-euclidean")
	ind = LinearIndices(I)[i, j]
	graydist(I, ind, method)
end
# ----------------------------------------------------------------------------------------
"""
    graydist(I::AbstractArray{T,2}, mask::AbstractArray{Bool,2}, method="quasi-euclidean") where T

Compute grayscale geodesic distance using Soille's geodesic time algorithm.

Based on: Soille, P. "Generalized geodesy via geodesic time." 
Pattern Recognition Letters. Vol.15, December 1994, pp. 1235–1240

Uses fast raster scanning with forward and backward passes.

# Arguments
- `I`: Input grayscale image (2D array)
- `mask`: Binary mask indicating seed points (2D boolean array)
- `method::String`: Distance metric, either "chessboard", "cityblock", or "quasi-euclidean" (default)

# Returns
- Geodesic distance map (same size as input)
"""
function graydist(I::AbstractArray{T,2}, mask::AbstractArray{Bool,2}, method="quasi-euclidean") where T
    rows, cols = size(I)
    @assert size(mask) == (rows, cols) "Image and mask must have same dimensions"
    
    # Initialize distance map with infinity
    D = fill(Inf, rows, cols)
    
    # Initialize seed points (always 0, even if Inf)
    for idx in findall(mask)
        i, j = Tuple(idx)
        D[i, j] = 0.0
    end
    
    # Precompute neighbor offsets and distances

	# Define neighborhood offsets and weights based on method
	if (startswith(method, "city"))			# method == "cityblock"
		#offsets = [(-1, 0), (1, 0), (0, -1), (0, 1)]
		#weights = [1.0, 1.0, 1.0, 1.0]
    	forward_neighbors = ((-1, 0, 1.0), (1, 0, 1.0))
    	backward_neighbors = ((0, -1, 1.0), (0, 1, 1.0))
	elseif startswith(method, "chess")		# method == "chessboard"
		#offsets = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
		#weights = fill(1.0, 8)
    	forward_neighbors = ((-1, -1, 1.0), (-1, 0, 1.0), (-1, 1, 1.0), (0, -1, 1.0))
    	backward_neighbors = ((0, 1, 1.0), (1, -1, 1.0), (1, 0, 1.0), (1, 1, 1.0))
	elseif startswith(method, "quasi")		# method == "quasi-euclidean"
		#offsets = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]
		#weights = [√2, 1.0, √2, 1.0, 1.0, √2, 1.0, √2]
    	# Forward scan: top-left to bottom-right neighbors
    	forward_neighbors = ((-1, -1, √2), (-1, 0, 1.0), (-1, 1, √2), (0, -1, 1.0))
    	# Backward scan: bottom-right to top-left neighbors
    	backward_neighbors = ((0, 1, 1.0), (1, -1, √2), (1, 0, 1.0), (1, 1, √2))
	else
		error("Unknown method: $method. Use 'cityblock', 'chessboard', or 'quasi-euclidean'")
	end

    
    # Helper function to update distance
    @inline function update_distance(D, I, i, j, ni, nj, spatial_dist, rows, cols)
        if ni < 1 || ni > rows || nj < 1 || nj > cols
            return false
        end
        
        if isinf(I[i, j]) || isinf(I[ni, nj])
            return false
        end
        
        # Geodesic cost: spatial distance weighted by average intensity
        avg_intensity = (I[i, j] + I[ni, nj]) / 2.0
        geodesic_cost = spatial_dist * avg_intensity
        new_dist = D[ni, nj] + geodesic_cost
        
        if new_dist < D[i, j]
            D[i, j] = new_dist
            return true
        end
        return false
    end
    
    # Iterate until convergence
    max_iterations = 100
    for iter in 1:max_iterations
        changed = false
        
        # Forward pass: scan from top-left to bottom-right
        for i in 1:rows
            for j in 1:cols
                if isinf(I[i, j])
                    continue
                end
                
                for (di, dj, spatial_dist) in forward_neighbors
                    ni, nj = i - di, j - dj  # Note: reversed because we look at where we came from
                    if update_distance(D, I, i, j, ni, nj, spatial_dist, rows, cols)
                        changed = true
                    end
                end
            end
        end
        
        # Backward pass: scan from bottom-right to top-left
        for i in rows:-1:1
            for j in cols:-1:1
                if isinf(I[i, j])
                    continue
                end
                
                for (di, dj, spatial_dist) in backward_neighbors
                    ni, nj = i - di, j - dj  # Note: reversed because we look at where we came from
                    if update_distance(D, I, i, j, ni, nj, spatial_dist, rows, cols)
                        changed = true
                    end
                end
            end
        end
        
        if !changed
            break
        end
    end
    
    return D
end

# ---------------------------------------------------------------------------------------------
"""
marker = [0 0 0 0 0; 0 0 0 0 0; 0 0 1 0 0; 0 0 0 0 0; 0 0 0 0 0]; mask = [0 0 0 0 0; 0 1 1 1 0; 0 1 1 1 0; 0 1 1 1 0; 0 0 0 0 0];
imreconstruct(marker, mask)
marker = ones(5, 5); marker[1]=Inf; mask = [1 1 1 1 1; 1 0 0 0 1; 1 0 0 0 1; 1 0 0 0 1; 1 1 1 1 1];
"""

"""
    imreconstruct(marker::AbstractArray{T,N}, mask::AbstractArray{<:Real,N}; 
                  conn=1) where {T,N}

Morphological reconstruction by dilation or erosion.

Uses the fast hybrid grayscale reconstruction algorithm from:
Vincent, L., "Morphological Grayscale Reconstruction in Image Analysis: 
Applications and Efficient Algorithms," IEEE Transactions on Image Processing, 
Vol. 2, No. 2, April, 1993, pp. 176-201.

# Arguments
- `marker`: Marker image (starting point for reconstruction)
- `mask`: Mask image (defines the constraint/boundary)
- `conn`: Connectivity for neighborhood (1 for 4-connected in 2D, 2 for 8-connected in 2D)

# Returns
- Reconstructed image (same size and type as input)
"""
function imreconstruct(marker::AbstractArray{T,N}, mask::AbstractArray{<:Real,N}; conn::Int=8) where {T,N}
	@assert (1 <= N <= 3) "Unsupported dimensionality: $N"
	(N == 2 && !(conn == 4 || conn == 8)) && error("For the 2D case connectivity must be 4 or 8")
	(N == 3 && !(conn == 6 || conn == 18 || conn == 26)) && error("For the 3D case connectivity must be 6, 18 or 26")
	@assert size(marker) == size(mask) "Marker and mask must have same dimensions"

	# Determine reconstruction type
	is_dilation = sum(marker .< mask) > sum(marker .> mask)
	
	# Initialize: clip marker to mask
	recon = (is_dilation) ? min.(marker, mask) : max.(marker, mask)
	
	neighbors = get_neighbors(N, conn)
	dims = size(recon)
	
	# Vincent's fast hybrid algorithm:
	# 1. Raster scan (forward and backward)
	# 2. Queue-based propagation for remaining pixels
	
	# FIFO queue for pixels that need propagation
	queue = CartesianIndex{N}[]
	in_queue = falses(dims)
	
	# Forward raster scan
	@inbounds for idx in CartesianIndices(dims)
		# For each pixel, check if any neighbor can improve it
		if is_dilation				# Dilation: can grow up to mask[idx]
			@inbounds for offset in neighbors
				neighbor_idx = idx + CartesianIndex(offset)
				if checkbounds(Bool, recon, neighbor_idx)
					# Propagate neighbor value, limited by mask
					new_val = min(recon[neighbor_idx], mask[idx])
					recon[idx] = max(recon[idx], new_val)
				end
			end
		else						# Erosion: can shrink down to mask[idx]
			@inbounds for offset in neighbors
				neighbor_idx = idx + CartesianIndex(offset)
				if checkbounds(Bool, recon, neighbor_idx)
					# Propagate neighbor value, but not below mask
					# If neighbor is at its mask, we should be at ours
					if recon[neighbor_idx] <= mask[neighbor_idx]
						recon[idx] = min(recon[idx], mask[idx])
					end
				end
			end
		end
	end
	
	# Backward raster scan and queue initialization
	@inbounds for idx in Iterators.reverse(CartesianIndices(dims))
		if is_dilation				# Dilation: can grow up to mask[idx]
			@inbounds for offset in neighbors
				neighbor_idx = idx + CartesianIndex(offset)
				if checkbounds(Bool, recon, neighbor_idx)
					new_val = min(recon[neighbor_idx], mask[idx])
					recon[idx] = max(recon[idx], new_val)
				end
			end
		else						# Erosion: can shrink down to mask[idx]
			@inbounds for offset in neighbors
				neighbor_idx = idx + CartesianIndex(offset)
				if checkbounds(Bool, recon, neighbor_idx)
					if recon[neighbor_idx] <= mask[neighbor_idx]
						recon[idx] = min(recon[idx], mask[idx])
					end
				end
			end
		end
		
		# Add to queue if pixel can still propagate to neighbors
		@inbounds for offset in neighbors
			neighbor_idx = idx + CartesianIndex(offset)
			if checkbounds(Bool, recon, neighbor_idx)
				if is_dilation
					if recon[idx] > recon[neighbor_idx] && recon[idx] < mask[neighbor_idx]
						if !in_queue[neighbor_idx]
							push!(queue, neighbor_idx)
							in_queue[neighbor_idx] = true
						end
					end
				else
					if recon[idx] < recon[neighbor_idx] && recon[idx] > mask[neighbor_idx]
						if !in_queue[neighbor_idx]
							push!(queue, neighbor_idx)
							in_queue[neighbor_idx] = true
						end
					end
				end
			end
		end
	end
	
	# Propagation using FIFO queue
	while !isempty(queue)
		idx = popfirst!(queue)
		in_queue[idx] = false
		
		@inbounds for offset in neighbors
			neighbor_idx = idx + CartesianIndex(offset)
			if checkbounds(Bool, recon, neighbor_idx)
				if is_dilation
					new_val = min(recon[idx], mask[neighbor_idx])
					if new_val > recon[neighbor_idx]
						recon[neighbor_idx] = new_val
						if !in_queue[neighbor_idx]
							push!(queue, neighbor_idx)
							in_queue[neighbor_idx] = true
						end
					end
				else
					new_val = max(recon[idx], mask[neighbor_idx])
					if new_val < recon[neighbor_idx]
						recon[neighbor_idx] = new_val
						if !in_queue[neighbor_idx]
							push!(queue, neighbor_idx)
							in_queue[neighbor_idx] = true
						end
					end
				end
			end
		end
	end
	
	return recon
end

function get_neighbors(N::Int, conn::Int)
	# Get neighbor offsets for N-dimensional arrays with given connectivity.
	if (N == 2)
		if conn == 4		# 4-connectivity
			return ((-1, 0), (1, 0), (0, -1), (0, 1))
		else						# 8-connectivity
			return ((-1, -1), (-1, 0), (-1, 1),
					(0, -1),           (0, 1),
					(1, -1),  (1, 0),  (1, 1))
		end
	elseif (N == 1)
		return ((-1,), (1,))
	else			# if N == 3
		if (conn == 6)		# 6-connectivity
			return ((-1, 0, 0), (1, 0, 0), (0, -1, 0), (0, 1, 0), (0, 0, -1), (0, 0, 1))
		end
		neighbors = Tuple{Int,Int,Int}[]

		for i in -1:1, j in -1:1, k in -1:1
			if (i != 0 || j != 0 || k != 0)
				if (conn == 26) || !((i != 0) && (j != 0) && (k != 0))	# if conn == 18, Exclude corners (where all three are non-zero)
					push!(neighbors, (i, j, k))
				end	
			end
		end

		return Tuple(neighbors)
	end
end
