# ---------------------------------------------------------------------------------------------------
function dup_G_meta(G)
	# Need to duplicate these otherwise changing them (like the range) would modify original G values too
	copy(G.epsg), copy(G.range), copy(G.inc), copy(G.registration), copy(G.nodata), copy(G.x), copy(G.y), copy(G.v), copy(G.pad)	
end

# ---------------------------------------------------------------------------------------------------
function Base.:+(G1::GMTgrid, G2::GMTgrid)
# Add two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be added.")
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	hasnans = (G1.hasnans == 0 && G2.hasnans == 0) ? 0 : ((G1.hasnans + G2.hasnans) == 2) ? 1 : 2
	G3 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z .+ G2.z, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, hasnans)
	setgrdminmax!(G3)		# Also take care of NaNs
	return G3
end

# ---------------------------------------------------------------------------------------------------
Base.:+(shift::Real, G1::GMTgrid) = Base.:+(G1::GMTgrid, shift::Real)
function Base.:+(G1::GMTgrid, shift::Real)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	_shift = convert(eltype(G1.z), shift)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z .+ _shift, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	G2.range[5:6] .+= shift
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:-(G1::GMTgrid, G2::GMTgrid)
# Subtract two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be subtracted.")
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	hasnans = (G1.hasnans == 0 && G2.hasnans == 0) ? 0 : ((G1.hasnans + G2.hasnans) == 2) ? 1 : 2
	G3 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z .- G2.z, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, hasnans)
	setgrdminmax!(G3)		# Also take care of NaNs
	return G3
end

# ---------------------------------------------------------------------------------------------------
function Base.:-(G1::GMTgrid, shift::Real)
	_shift = convert(eltype(G1.z), shift)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z .- _shift, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	G2.range[5:6] .-= shift
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:*(G1::GMTgrid, G2::GMTgrid)
# Multiply two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be multiplied.")
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	hasnans = (G1.hasnans == 0 && G2.hasnans == 0) ? 0 : ((G1.hasnans + G2.hasnans) == 2) ? 1 : 2
	G3 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z .* G2.z, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, hasnans)
	setgrdminmax!(G3)		# Also take care of NaNs
	return G3
end

# ---------------------------------------------------------------------------------------------------
Base.:-(G1::GMTgrid) = -1 * G1
Base.:*(scale::Real, G1::GMTgrid) = Base.:*(G1::GMTgrid, scale::Real)
function Base.:*(G1::GMTgrid, scale::Real)
	_scale = convert(eltype(G1.z), scale)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z .* _scale, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	G2.range[5:6] .*= scale
	return G2
end

# ---------------------------------------------------------------------------------------------------
Base.:^(G1::GMTgrid, scale::Int) = Base.:^(G1::GMTgrid, Float64(scale))
function Base.:^(G1::GMTgrid, scale::Real)
	_scale = convert(eltype(G1.z), scale)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z.^_scale, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	G2.range[5:6] .^= scale
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:/(G1::GMTgrid, G2::GMTgrid)
# Divide two grids, element by element. Inherit header parameters from G1 grid
	if (size(G1.z) != size(G2.z))  error("Grids have different sizes, so they cannot be divided.")  end
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	hasnans = (G1.hasnans == 0 && G2.hasnans == 0) ? 0 : ((G1.hasnans + G2.hasnans) == 2) ? 1 : 2
	G3 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z ./ G2.z, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, hasnans)
	setgrdminmax!(G3)		# Also take care of NaNs
	return G3
end

# ---------------------------------------------------------------------------------------------------
function Base.:/(G1::GMTgrid, scale::Real)
	_scale = convert(eltype(G1.z), scale)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z ./ _scale, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	G2.range[5:6] ./= scale
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:sqrt(G1::GMTgrid)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             sqrt.(G1.z), G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	setgrdminmax!(G2)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:log(G1::GMTgrid)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             log.(G1.z), G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	setgrdminmax!(G2)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:log10(G1::GMTgrid)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             log10.(G1.z), G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	setgrdminmax!(G2)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function setgrdminmax!(G::GMTgrid)
	# The non-nan version is way faster so use it as a proxy of NaNs and recompute if needed.
	min = minimum(G.z);
	!isnan(min) ? (G.range[5:6] = [min, maximum(G.z)]) : (G.range[5:6] = [minimum_nan(G.z), maximum_nan(G.z)])
	return nothing
	#=
	if !isnan(min)
		G.range[5:6] = [min, maximum(G.z)]
	else
		tic()
		t = G.layout;	G.layout = "TRBa"
		info = grdinfo(G, C=:n, L=0, Vd=1)
		G.range[5:6] = info[5:6]
		G.layout = t
		toc()
	end
	=#
end

# ---------------------------------------------------------------------------------------------------
function Base.:permutedims(G1::GMTgrid, inds; nodata=nothing)
	epsg, range, inc, registration, _nodata, x, y, v, pad = dup_G_meta(G1)
	_range = [range[1:2], range[3:4], range[7:8]]
	if (isempty(v) && ndims(G1) == 3)
		v, inc::Vector{<:Float64}  = collect(1.0:size(G1,3)), [inc[:]..., 1.0]
	end
	mat = permutedims(G1.z, inds)
	# 3,2,1  3,1,2, 2,1,3  2,3,1  1,3,2
	if     (inds == [3,2,1])  x, v, x_unit = v, x, G1.z_unit
	elseif (inds == [3,1,2])  x, y, v, x_unit = v, x, y, G1.z_unit
	end
	if (nodata !== nothing && eltype(G1) <: AbstractFloat && !isnan(nodata))
		this_NaN = (eltype(G1) == Float32) ? NaN32 : NaN64
		if (nodata > 0)		# More often than not, nodata !== NaN are stupid float numbers with tons of decimals
			@inbounds @simd for k = 1:numel(G1)
				(G1.z[k] >= nodata) && (G1.z[k] = this_NaN)
			end
		else
			@inbounds @simd for k = 1:numel(G1)
				(G1.z[k] <= nodata) && (G1.z[k] = this_NaN)
			end
		end
		_nodata = this_NaN
	end
	range = [_range[inds[1]]..., _range[inds[2]]..., range[5:6]..., _range[inds[3]]...]
	GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	        mat, G1.z_unit, G1.y_unit, G1.x_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
end
