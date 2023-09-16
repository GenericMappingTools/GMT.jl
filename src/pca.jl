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
function princomp!(X, q=0)

	n_rows, n_vars = size(X,1), size(X,2)
	(q == 0) && (q = n_vars)

	cov_X = cov(X)							# The covariance matrix
	F = eigen(cov_X)
	idx = sortperm(F.values, rev=true)
	latent::Vector{eltype(X)} = F.values[idx]	# Eigenvalues (latent is what Matlab calls to this in pca() ??)
	V::Matrix{eltype(X)}      = F.vectors[:, idx]
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
	Ipca = deepcopy(I)
	for k = 1:n_bands
		Ipca[:,:,k] = imagesc(P[:,:,k]).image	# Each component must be scaled independently
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
		X = img
	else
		X = DT.(reshape(GI, n_rc, n_layers))
	end
end
