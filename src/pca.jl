"""
    score, coeff, latent, explained, mu, ems = princomp!(X, q=0)

- `X`: A n-by-p data matrix X. Rows of X correspond to observations and columns correspond to variables.
  Must be a Float type (either 32 or 64).

- `q`: The number of eigenvectors used to construct the solution. Its value must be in the range [1, p].
  The default `q=0` means we use the full solution, that is q = p.

### Returns

- `score`: The principal components
- `coeff`: The principal component coefficients for the matrix X. Rows of X correspond to observations and
  columns correspond to variables. The coefficient matrix is q-by-n. Each column of coeff contains coefficients
  for one principal component, and the columns are in descending order of component variance.
- `latent`: The principal component variances. (The eigenvalues of cov(X))
- `explained`: The percentage of the total variance explained by each principal component.
- `mu`: The mean of each variable in X.
- `ems`: The mean square error incurred in using only the `q` eigenvectors corresponding to the largest
  eigenvalues. `ems` is 0 if q = n (the default). 
 
Note, this function follows approximately the Matlab one and has influences of a similar function in the
*Digital Image Processing Using MATLAB* book.
"""
princomp!(X) = princomp!(X, 0)
function princomp!(X, q)

	n_rows, n_vars = size(X,1), size(X,2)
	(q == 0) && (q = n_vars)

	cov_X = cov(X)							# The covariance matrix
	F = eigen(cov_X)
	idx = sortperm(F.values, rev=true)
	latent::Vector{eltype(X)} = F.values[idx]	# Eigenvalues (latent is what Matlab calls to this in pca() ??)
	V::Matrix{eltype(X)}      = F.vectors[:, idx]
	#U, S, Vt = svd(cov_X)
	#idx = sortperm(S, rev=true)
	#latent::Vector{eltype(X)} = S[idx]
	#V::Matrix{eltype(X)}      = U[:, idx]
	coeff = V[:, 1:q]						# first q rows of V.

	mu = sum(X, dims=1) / n_rows
	@inbounds for j = 1:q, i = 1:n_rows		# Remove mean of each dimension
		X[i,j] -= mu[j]
	end

	score = X * coeff
	ems = sum(latent[q+1:n_vars])			# Equal zero when q == n_vars
	#cov_Y = coeff' * cov_X * coeff			# Covariance matrix of the score's
	explained = latent / sum(latent) * 100
	return score, coeff, latent, explained, collect(mu'), ems
end

#=
function covzm(x::AbstractMatrix)
	x = x .- mean(x, dims=1)
	C = x'x	
    T = promote_type(typeof(first(C) / 1), eltype(C))
    A = convert(AbstractMatrix{T}, C)
    b = 1/(size(x, 1) - 1)
    A .= A .* b
    return A
end
=#

# ---------------------------------------------------------------------------------------------------
"""
    score, coeff, latent, explained, mu, ems = pca(X; DT::DataType=Float32, npc=0)

- `X`: A n-by-p data matrix X. Rows of X correspond to observations and columns correspond to variables.
  Must be a Float type (either 32 or 64).
  
- `npc`: The number of eigenvectors used to construct the solution. Its value must be in the range [1, npc].
  The default `npc=0` means we use the full solution, that is npc = p. Use this option when `X` is *big* and
  you want to save some resources (time, memory) by not computing components that will have a very small
  explained variance.

- `DT`: The Data Type. Internally, the algorithm makes a copy of the input `X` matrix because it will be
  modified. `DT` controls what type that copy will assume. ``Float32`` or ``Float64``? By default, we use the same
  data type as in `X`, but for big matrices it may be desirable to use ``Float32`` if that saves memory.
  Note: the default is different in the methods referred below, where it defaults to ``Float32`` because image
  data is almost always ``UInt8`` or ``UInt16`` and grids are ``Float32``.
  
### Returns
  
- `score`: The principal components.
- `coeff`: The principal component coefficients for the matrix X. Rows of X correspond to observations and
  columns correspond to variables. The coefficient matrix is npc-by-n. Each column of coeff contains coefficients
  for one principal component, and the columns are in descending order of component variance.
- `latent`: The principal component variances. (The eigenvalues of cov(X))
- `explained`: The percentage of the total variance explained by each principal component.
- `mu`: The mean of each variable in X.
- `ems`: The mean square error incurred in using only the `npc` eigenvectors corresponding to the largest
  eigenvalues. `ems` is 0 if npc = n (the default). 


    Ipca = pca(I::GMTimage; DT::DataType=Float32, npc=0) -> GMTimage{UInt8}

This method takes a ``GMTimage`` cube, normally satellite data of ``UInt16`` type created with the ``RemoteS`` package,
and returns a ``GMTimage`` cube of ``UInt8`` of the principal components in decreasing order of explained variance.
The ``truecolor(Ipca)`` (from ``RemoteS``) will show a false color image made of the three largest components.

    Gpca = pca(G::GMTgrid; DT::DataType=Float32, npc=0) -> GMTgrid{DT}

This method takes a ``GMTgrid`` cube and returns another grid, of type `DT` (``Float32`` by default), with principal
components in decreasing order of explained variance.
"""
function pca(X::Union{GMTdataset, Matrix{<:Real}}; DT::DataType=Float32, npc::Int=0)
	eltype(X) <: Integer ? princomp!(DT.(X), npc) : princomp!(copy(X), npc)
end

# ---------------------------------------------------------------------------------------------------
function pca(I::GMTimage; DT::DataType=Float32, npc::Int=0)
	n_rows, n_cols, n_bands = size(I)
	(npc > n_bands) && error("'npc' larger than number of bands ($(n_bands)) in input.")
	(npc > 0) && (n_bands = npc) 
	(n_bands == 1) && (error("With one band only it is not possible to compute PCA.")) 
	Y, _, _, explained, = princomp!(GI2vectors(I, DT), npc)
	P = reshape(Y, n_rows, n_cols, n_bands)
	Ipca::GMTimage = mat2img(copy(I.image), I)
	for k = 1:n_bands
		viewmat = view(P,:,:,k)
		mi, ma = extrema(viewmat)
		if (isnan(mi))			# Shit, such a memory waste we need to do.
			mi, ma = extrema_nan(viewmat)
			t = Float32.((viewmat .- mi) ./ (ma - mi) .* 255)
			for k in CartesianIndices(t)  isnan(t[k]) && (t[k] = 255f0)  end
			Ipca[:,:,k] = round.(UInt8, t)
		else
			Ipca[:,:,k] = round.(UInt8, (viewmat .- mi) ./ (ma - mi) .* 255) 
		end
	end
	Ipca.names = [@sprintf("PC %d, explained variance %.1f", k, explained[k]) for k = 1:n_bands]
	Ipca.range[5:6] = [0, 255]
	(I.layout[3] == 'P') && ((I.layout[2] == 'R') ? (Ipca.layout = "TRBa") : (Ipca.layout = I.layout[1:2] * "Ba"))
	return Ipca
end

# ---------------------------------------------------------------------------------------------------
function pca(G::GMTgrid; DT::DataType=Float32, npc::Int=0)
	n_rows, n_cols, n_layers = size(G)
	(npc > n_layers) && error("'npc' larger than number of layers ($(n_layers)) in input.")
	(npc > 0) && (n_layers = npc) 
	(n_layers == 1) && (error("With one layer only it is not possible to compute PCA.")) 
	Y, _, _, explained, = princomp!(GI2vectors(G, DT), npc)
	Gpca = mat2grid(reshape(Y, n_rows, n_cols, n_layers), G)
	Gpca.names = [@sprintf("PC %d, explained variance %.1f", k, explained[k]) for k = 1:n_layers]
	return Gpca
end


# ---------------------------------------------------------------------------------------------------
function GI2vectors(GI, DT::DataType=Float32)
	# Make a copy of the reformated 3D Image/Grid of size M-by-N-by-P in to a matrix MN-by-P where MN = M * N
	(ndims(GI) != 3) && error("Input must be a 3D array")
	n_rows, n_cols, n_layers = size(GI)
	n_rc = n_rows * n_cols
	if (isa(GI, GMTimage) && (GI.layout[3] == 'P'))		# Shit, pixel interleaved
		img = Matrix{DT}(undef, n_rc, n_layers)
		n = 0
		@inbounds for b = 1:n_layers, k = 0:n_rc-1
			img[n+=1] = GI.image[k*3+b]
		end
		return img
	else
		return isa(GI, GMTgrid) ? DT.(reshape(GI.z, n_rc, n_layers)) : DT.(reshape(GI.image, n_rc, n_layers))
	end
end

# ---------------------------------------------------------------------------------------------------
"""
    Ik = kmeans(I::GMTimage, k=5; seeds=nothing, maxiter=100, tol=1e-7, V=false) -> GMTimage

Compute a k-means clustering on an RGB image `I`. It produces a fixed number of clusters, each associated
with a center, and each RGB color is assigned to a cluster with the nearest center.

- `I`: The input ``GMTimage`` object.
- `k`: The number of clusters when using unsupervised classification.
- `seeds`: For supervised classifications this is Mx3 UInt8 matrix with the colors of the cluster
  centers. The algorithm than aggregates  all colors in the image around these M seed colors.
  Attention, if provided, this option resets `k`.
- `maxiter`: Maximum number of iterations that the algorithm may run till reach a solution.
- `tol`: Alternatively, sets the minimal allowed change of the objective during convergence.
  The iteration process stops when one of the two conditions is met first.
- `V`: Print some info at the end of the iterative loop (number of iterations, time spent).


    kmeans(X::Union{GMTdataset, Matrix{<:Real}}, k=3; seeds=nothing, maxiter=100, tol=1e-7,
           raw::Bool=false, V=false) -> Vector{GMTdataset} | idx, centers, counts

This method accepts a M-by-d matrix or a ``GMTdataset`` where columns represent the data points and
rows the `d`-dimensional data point.

- `raw`: A Boolean that if `false` makes the return data be a vector of ``GMTdatset``, one for each
  cluster found in input data. If `raw=true`, we return: `idx, centers, counts`, where
  - `idx`: A vector of ints with the assignments of each data points (by position in the `idx` vector) to clusters.
  - `centers`: A k-by-d matrix with the centers of each cluster.
  - `counts`: A matrix of integers with the cluster number in first column, and number of elements
    in that cluster in second column.

### Example
    D = gmtread(GMT.TESTSDIR * "iris.dat");

	Dk = kmeans(D, k=3)		# Unsupervised segment data into 3 clusters.
"""
function kmeans(I::GMTimage, k=5; seeds=nothing, maxiter=100, tol=1e-7, V=false)
	X = GI2vectors(I, eltype(I))

	dist, centers = helper_kmeans(X, k; seeds=seeds, maxiter=maxiter, tol=tol, V=V)
	t = [convert(eltype(I), (argmin(_dist)-1)) for _dist in eachrow(dist)]
	Ik = mat2img(reshape(t, size(I,1), size(I,2)), I)
	Ik.colormap = zeros(Int32, 256 * 3)
	Ik.n_colors, Ik.color_interp = 256,  "Palette"	# Because for GDAL we always send 256 even if they are not all filled
	for n = 1:3, m = 1:size(centers, 1)				# Write 'colormap' col-wise
		@inbounds Ik.colormap[m + (n-1)*Ik.n_colors] = round(Int32, centers[m,n]);
	end
	return Ik
end

# ---------------------------------------------------------------------------------------------------
function kmeans(X::Union{GMTdataset, Matrix{<:Real}}, k=3; seeds=nothing, maxiter=100, tol=1e-7,
                raw::Bool=false, V=false)
	dist, centers = helper_kmeans(X, k; seeds=seeds, maxiter=maxiter, tol=tol, V=V)
	idx = argmin.(eachrow(dist))
	classes = sort(unique(idx))
	
	(raw) && return idx, centers, [classes [sum(idx .== classes[n]) for n = 1:numel(classes)]]

	Dv = Vector{GMTdataset}(undef, length(classes))
	colnames = isa(X, GMTdataset) ? X.colnames : String[]
	has_text = isa(X, GMTdataset) && !isempty(X.text)
	for n = 1:numel(classes)
		ind = (idx .== classes[n])
		txt = has_text ? X.text[ind] : String[]
		Dv[n] = mat2ds(X[ind, :], txtcol=txt, colnames=colnames, geom=wkbPoint)
		Dv[n].comment = ["kmeans-class = $(classes[n]); centers = $(round.(centers[classes[n],:], digits=4))"]
	end
	return Dv
end

# ---------------------------------------------------------------------------------------------------
function helper_kmeans(X, k=5; seeds=nothing, maxiter=100, tol=1e-7, V=false)
	(seeds === nothing) && (seeds = X[round.(Int, rand(k) * (size(X,1) - 1) .+ 1), :])
	k = size(seeds, 1)				# Needed when seeds != nothing
	centers = Float32.(seeds)
	OldCenters = copy(centers)

	V == 1 && tic()
	n, change = 0, 1e8
	dist = Matrix{Float32}(undef, size(X,1), k)
	while (n < maxiter && change > tol)
		# Not particularly faster than "sum((centers.^2), dims=2)' .- 2.0f0 * X * centers'" but uses less memory
		t1, t2 = sum((centers.^2), dims=2)', 2.0f0 * X * centers'
		for i = 1:k, j = 1:size(X,1)
			@inbounds dist[j,i] = t1[i] - t2[j,i]	# i.e. d^2 = (x-c)^2 = x^2 + c^2 -2xc (droped x^2 because is a constant)
		end
		# label of nearest center for each pointalongline
		center = [Int8(argmin(_dist)) for _dist in eachrow(dist)]	# argmin.(eachrow(dist)) returns Int64
		for j = 1:k
			idx = (center .== j)
			if (any(idx))
				@inbounds centers[j,:] = mean(X[idx,:], dims=1)
			end
		end

		change = sum(abs.(OldCenters .- centers))
		OldCenters = copy(centers)
		n += 1
	end
	V == 1 && (toc(); println("\tN iterations = ",n, "\tTol = ", change))
	return dist, centers
end
