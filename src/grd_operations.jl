
function Base.:+(G1::GMTgrid, G2::GMTgrid)
# Add two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be added.")
	G3 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z .+ G2.z, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G3.range[5] = minimum(G3.z);	G3.range[6] = maximum(G3.z)
	return G3
end

# ---------------------------------------------------------------------------------------------------
Base.:+(shift::Real, G1::GMTgrid) = Base.:+(G1::GMTgrid, shift::Real)
function Base.:+(G1::GMTgrid, shift::Real)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z .+ shift, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G2.range[5:6] .+= shift
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:sum!(G1::GMTgrid, G2::GMTgrid)
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be added.")
	G1.z .= G1.z .+ G2.z
	G1.range[5] = minimum(G1.z);	G1.range[6] = maximum(G1.z)
	return G1
end

# ---------------------------------------------------------------------------------------------------
Base.:sum!(shift::Real, G1::GMTgrid) = Base.:sum!(G1::GMTgrid, shift::Real)
function Base.:sum!(G1::GMTgrid, shift::Real)
	G1.z .+= shift;		G1.range[5:6] .+= shift
	return G1
end
	
# ---------------------------------------------------------------------------------------------------
function Base.:-(G1::GMTgrid, G2::GMTgrid)
# Subtract two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be subtracted.")
	G3 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z .- G2.z, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G3.range[5] = minimum(G3.z);	G3.range[6] = maximum(G3.z)
	return G3
end

# ---------------------------------------------------------------------------------------------------
function Base.:-(G1::GMTgrid, shift::Real)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z .- shift, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G2.range[5:6] .-= shift
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:*(G1::GMTgrid, G2::GMTgrid)
# Multiply two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be multiplied.")
	G3 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z .* G2.z, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G3.range[5] = minimum(G3.z);	G3.range[6] = maximum(G3.z)
	return G3
end

# ---------------------------------------------------------------------------------------------------
Base.:-(G1::GMTgrid) = -1 * G1
Base.:*(scale::Real, G1::GMTgrid) = Base.:*(G1::GMTgrid, scale::Real)
function Base.:*(G1::GMTgrid, scale::Real)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z .* scale, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G2.range[5:6] .*= scale
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:prod!(G1::GMTgrid, G2::GMTgrid)
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be multiplied.")
	G1.z .= G1.z .* G2.z
	G1.range[5] = minimum(G1.z);	G1.range[6] = maximum(G1.z)
	return G1
end

# ---------------------------------------------------------------------------------------------------
Base.:prod!(shift::Real, G1::GMTgrid) = Base.:sum!(G1::GMTgrid, shift::Real)
function Base.:prod!(G1::GMTgrid, shift::Real)
	G1.z .*= shift;		G1.range[5:6] .*= shift
	return G1
end

# ---------------------------------------------------------------------------------------------------
function Base.:^(G1::GMTgrid, scale::Real)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z.^scale, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G2.range[5:6] .^= scale
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:/(G1::GMTgrid, G2::GMTgrid)
# Divide two grids, element by element. Inherit header parameters from G1 grid
	if (size(G1.z) != size(G2.z))  error("Grids have different sizes, so they cannot be divided.")  end
	G3 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z ./ G2.z, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G3.range[5] = minimum(G3.z);	G3.range[6] = maximum(G3.z)
	return G3
end

# ---------------------------------------------------------------------------------------------------
function Base.:/(G1::GMTgrid, scale::Real)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, G1.z ./ scale, G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G2.range[5:6] ./= scale
	return G2
end

# ---------------------------------------------- TRIG -----------------------------------------------
# ---------------------------------------------------------------------------------------------------
function Base.:cos(G1::GMTgrid)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, cos.(G1.z), G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G2.range[5] = minimum(G2.z);	G2.range[6] = maximum(G2.z)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:cosd(G1::GMTgrid)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, cosd.(G1.z), G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G2.range[5] = minimum(G2.z);	G2.range[6] = maximum(G2.z)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function cos!(G1::GMTgrid)
	G1.z = cos.(G1.z)
	G1.range[5] = minimum(G1.z);	G1.range[6] = maximum(G1.z)
	return G1
end

# ---------------------------------------------------------------------------------------------------
function cosd!(G1::GMTgrid)
	G1.z = cosd.(G1.z);		G1.range[5] = minimum(G1.z);	G1.range[6] = maximum(G1.z)
	return G1
end

# ---------------------------------------------------------------------------------------------------
function Base.:sin(G1::GMTgrid)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, sin.(G1.z), G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G2.range[5] = minimum(G2.z);	G2.range[6] = maximum(G2.z)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:sind(G1::GMTgrid)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, sind.(G1.z), G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G2.range[5] = minimum(G2.z);	G2.range[6] = maximum(G2.z)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function sin!(G1::GMTgrid)
	G1.z = sin.(G1.z);		G1.range[5] = minimum(G1.z);	G1.range[6] = maximum(G1.z)
	return G1
end

# ---------------------------------------------------------------------------------------------------
function sind!(G1::GMTgrid)
	G1.z = sind.(G1.z);		G1.range[5] = minimum(G1.z);	G1.range[6] = maximum(G1.z)
	return G1
end

# ---------------------------------------------------------------------------------------------------
function Base.:tan(G1::GMTgrid)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, tan.(G1.z), G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G2.range[5] = minimum(G2.z);	G2.range[6] = maximum(G2.z)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:tand(G1::GMTgrid)
	G2 = GMTgrid(G1.proj4, G1.wkt, G1.epsg, G1.range, G1.inc, G1.registration, G1.nodata, G1.title, G1.remark,
				 G1.command, G1.x, G1.y, tand.(G1.z), G1.x_unit, G1.y_unit, G1.z_unit, G1.layout)
	G2.range[5] = minimum(G2.z);	G2.range[6] = maximum(G2.z)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function tan!(G1::GMTgrid)
	G1.z = tan.(G1.z);		G1.range[5] = minimum(G1.z);	G1.range[6] = maximum(G1.z)
	return G1
end

# ---------------------------------------------------------------------------------------------------
function tand!(G1::GMTgrid)
	G1.z = tand.(G1.z);		G1.range[5] = minimum(G1.z);	G1.range[6] = maximum(G1.z)
	return G1
end