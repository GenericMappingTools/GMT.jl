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
	G3 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", G1.names, x, y, v,
	             G1.z .+ G2.z, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad)
	setgrdminmax!(G3)		# Also take care of NaNs
	return G3
end

# ---------------------------------------------------------------------------------------------------
Base.:+(shift::Real, G1::GMTgrid) = Base.:+(G1::GMTgrid, shift::Real)
function Base.:+(G1::GMTgrid, shift::Real)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	_shift = convert(eltype(G1.z), shift)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", G1.names, x, y, v,
	             G1.z .+ _shift, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad)
	G2.range[5:6] .+= shift
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:-(G1::GMTgrid, G2::GMTgrid)
# Subtract two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be subtracted.")
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G3 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", G1.names, x, y, v,
	             G1.z .- G2.z, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad)
	setgrdminmax!(G3)		# Also take care of NaNs
	return G3
end

# ---------------------------------------------------------------------------------------------------
function Base.:-(G1::GMTgrid, shift::Real)
	_shift = convert(eltype(G1.z), shift)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", G1.names, x, y, v,
	             G1.z .- _shift, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad)
	G2.range[5:6] .-= shift
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:*(G1::GMTgrid, G2::GMTgrid)
# Multiply two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be multiplied.")
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G3 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", G1.names, x, y, v,
	             G1.z .* G2.z, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad)
	setgrdminmax!(G3)		# Also take care of NaNs
	return G3
end

# ---------------------------------------------------------------------------------------------------
Base.:-(G1::GMTgrid) = -1 * G1
Base.:*(scale::Real, G1::GMTgrid) = Base.:*(G1::GMTgrid, scale::Real)
function Base.:*(G1::GMTgrid, scale::Real)
	_scale = convert(eltype(G1.z), scale)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", G1.names, x, y, v,
	             G1.z .* _scale, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad)
	G2.range[5:6] .*= scale
	return G2
end

# ---------------------------------------------------------------------------------------------------
Base.:^(G1::GMTgrid, scale::Int) = Base.:^(G1::GMTgrid, Float64(scale))
function Base.:^(G1::GMTgrid, scale::Real)
	_scale = convert(eltype(G1.z), scale)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", G1.names, x, y, v,
	             G1.z.^_scale, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad)
	G2.range[5:6] .^= scale
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:/(G1::GMTgrid, G2::GMTgrid)
# Divide two grids, element by element. Inherit header parameters from G1 grid
	if (size(G1.z) != size(G2.z))  error("Grids have different sizes, so they cannot be divided.")  end
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G3 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", G1.names, x, y, v,
	             G1.z ./ G2.z, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad)
	setgrdminmax!(G3)		# Also take care of NaNs
	return G3
end

# ---------------------------------------------------------------------------------------------------
function Base.:/(G1::GMTgrid, scale::Real)
	_scale = convert(eltype(G1.z), scale)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", G1.names, x, y, v,
	             G1.z ./ _scale, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad)
	G2.range[5:6] ./= scale
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:sqrt(G1::GMTgrid)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", G1.names, x, y, v,
	             sqrt.(G1.z), G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad)
	setgrdminmax!(G2)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:log(G1::GMTgrid)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", G1.names, x, y, v,
	             log.(G1.z), G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad)
	setgrdminmax!(G2)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:log10(G1::GMTgrid)
	epsg, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, range, inc, registration, nodata, "", "", "", G1.names, x, y, v,
	             log10.(G1.z), G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad)
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
