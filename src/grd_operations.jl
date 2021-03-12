
function Base.:+(G1::GMTgrid, G2::GMTgrid)
# Add two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be added.")
	G3 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z .+ G2.z, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout, G1.pad)
	G3.range[5] = minimum(G3.z);	G3.range[6] = maximum(G3.z)
	return G3
end

# ---------------------------------------------------------------------------------------------------
Base.:+(shift::Real, G1::GMTgrid) = Base.:+(G1::GMTgrid, shift::Real)
function Base.:+(G1::GMTgrid, shift::Real)
	_shift = convert(eltype(G1.z), shift)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z .+ _shift, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout, G1.pad)
	G2.range[5:6] .+= shift
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:-(G1::GMTgrid, G2::GMTgrid)
# Subtract two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be subtracted.")
	G3 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z .- G2.z, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout, G1.pad)
	G3.range[5] = minimum(G3.z);	G3.range[6] = maximum(G3.z)
	return G3
end

# ---------------------------------------------------------------------------------------------------
function Base.:-(G1::GMTgrid, shift::Real)
	_shift = convert(eltype(G1.z), shift)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z .- _shift, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout, G1.pad)
	G2.range[5:6] .-= shift
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:*(G1::GMTgrid, G2::GMTgrid)
# Multiply two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be multiplied.")
	G3 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z .* G2.z, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout, G1.pad)
	G3.range[5] = minimum(G3.z);	G3.range[6] = maximum(G3.z)
	return G3
end

# ---------------------------------------------------------------------------------------------------
Base.:-(G1::GMTgrid) = -1 * G1
Base.:*(scale::Real, G1::GMTgrid) = Base.:*(G1::GMTgrid, scale::Real)
function Base.:*(G1::GMTgrid, scale::Real)
	_scale = convert(eltype(G1.z), scale)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z .* _scale, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout, G1.pad)
	G2.range[5:6] .*= scale
	return G2
end

# ---------------------------------------------------------------------------------------------------
Base.:^(G1::GMTgrid, scale::Int) = Base.:^(G1::GMTgrid, Float64(scale))
function Base.:^(G1::GMTgrid, scale::Real)
	_scale = convert(eltype(G1.z), scale)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z.^_scale, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout, G1.pad)
	G2.range[5:6] .^= scale
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:/(G1::GMTgrid, G2::GMTgrid)
# Divide two grids, element by element. Inherit header parameters from G1 grid
	if (size(G1.z) != size(G2.z))  error("Grids have different sizes, so they cannot be divided.")  end
	G3 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z ./ G2.z, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout, G1.pad)
	G3.range[5] = minimum(G3.z);	G3.range[6] = maximum(G3.z)
	return G3
end

# ---------------------------------------------------------------------------------------------------
function Base.:/(G1::GMTgrid, scale::Real)
	_scale = convert(eltype(G1.z), scale)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z ./ _scale, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout, G1.pad)
	G2.range[5:6] ./= scale
	return G2
end