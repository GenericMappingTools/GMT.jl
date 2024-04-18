# ---------------------------------------------------------------------------------------------------
function dup_G_meta(G)
	# Need to duplicate these otherwise changing them (like the range) would modify original G values too
	copy(G.epsg), copy(G.geog), copy(G.range), copy(G.inc), copy(G.registration), copy(G.nodata), copy(G.x), copy(G.y), copy(G.v), copy(G.pad)	
end

# ---------------------------------------------------------------------------------------------------
function Base.:+(G1::GMTgrid, G2::GMTgrid)
# Add two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be added.")
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	hasnans = (G1.hasnans == 0 && G2.hasnans == 0) ? 0 : ((G1.hasnans + G2.hasnans) == 2) ? 1 : 2
	G3 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z .+ G2.z, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, hasnans)
	setgrdminmax!(G3)		# Also take care of NaNs
	return G3
end

# ---------------------------------------------------------------------------------------------------
Base.:+(shift::Real, G1::GMTgrid) = Base.:+(G1::GMTgrid, shift::Real)
function Base.:+(G1::GMTgrid, shift::Real)
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	_shift = convert(eltype(G1.z), shift)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z .+ _shift, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	G2.range[5:6] .+= shift
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:-(G1::GMTgrid, G2::GMTgrid)
# Subtract two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be subtracted.")
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	hasnans = (G1.hasnans == 0 && G2.hasnans == 0) ? 0 : ((G1.hasnans + G2.hasnans) == 2) ? 1 : 2
	G3 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z .- G2.z, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, hasnans)
	setgrdminmax!(G3)		# Also take care of NaNs
	return G3
end

# ---------------------------------------------------------------------------------------------------
function Base.:-(G1::GMTgrid, shift::Real)
	_shift = convert(eltype(G1.z), shift)
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z .- _shift, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	G2.range[5:6] .-= shift
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:*(G1::GMTgrid, G2::GMTgrid)
# Multiply two grids, element by element. Inherit header parameters from G1 grid
	(size(G1.z) != size(G2.z)) && error("Grids have different sizes, so they cannot be multiplied.")
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	hasnans = (G1.hasnans == 0 && G2.hasnans == 0) ? 0 : ((G1.hasnans + G2.hasnans) == 2) ? 1 : 2
	G3 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z .* G2.z, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, hasnans)
	setgrdminmax!(G3)		# Also take care of NaNs
	return G3
end

# ---------------------------------------------------------------------------------------------------
Base.:-(G1::GMTgrid) = -1 * G1
Base.:*(scale::Real, G1::GMTgrid) = Base.:*(G1::GMTgrid, scale::Real)
function Base.:*(G1::GMTgrid, scale::Real)
	_scale = convert(eltype(G1.z), scale)
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z .* _scale, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	G2.range[5:6] .*= scale
	return G2
end

# ---------------------------------------------------------------------------------------------------
Base.:^(G1::GMTgrid, scale::Integer) = Base.:^(G1::GMTgrid, Float64(scale))
function Base.:^(G1::GMTgrid, scale::AbstractFloat)
	_scale = convert(eltype(G1.z), scale)
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z.^_scale, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	G2.range[5:6] .^= scale
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:/(G1::GMTgrid, G2::GMTgrid)
# Divide two grids, element by element. Inherit header parameters from G1 grid
	if (size(G1.z) != size(G2.z))  error("Grids have different sizes, so they cannot be divided.")  end
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	hasnans = (G1.hasnans == 0 && G2.hasnans == 0) ? 0 : ((G1.hasnans + G2.hasnans) == 2) ? 1 : 2
	G3 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z ./ G2.z, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, hasnans)
	setgrdminmax!(G3)		# Also take care of NaNs
	return G3
end

# ---------------------------------------------------------------------------------------------------
function Base.:/(G1::GMTgrid, scale::Real)
	_scale = convert(eltype(G1.z), scale)
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             G1.z ./ _scale, G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	G2.range[5:6] ./= scale
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:sqrt(G1::GMTgrid)
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             sqrt.(G1.z), G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	setgrdminmax!(G2)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:log(G1::GMTgrid)
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             log.(G1.z), G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	setgrdminmax!(G2)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:log10(G1::GMTgrid)
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             log10.(G1.z), G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	setgrdminmax!(G2)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:<(G1::GMTgrid, val::Number)
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             Int8.(G1.z .< val), G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	setgrdminmax!(G2)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:<=(G1::GMTgrid, val::Number)
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             Int8.(G1.z .<= val), G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	setgrdminmax!(G2)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:>(G1::GMTgrid, val::Number)
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             Int8.(G1.z .> val), G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	setgrdminmax!(G2)
	return G2
end

# ---------------------------------------------------------------------------------------------------
function Base.:>=(G1::GMTgrid, val::Number)
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(G1)
	G2 = GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, nodata, "", "", "", "", G1.names, x, y, v,
	             Int8.(G1.z .>= val), G1.x_unit, G1.y_unit, G1.v_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
	setgrdminmax!(G2)
	return G2
end

# ---------------------------------------------------------------------------------------------------
"""
Subtract two boolean/uint8 mask images. It applies the logical `I1 && !I2` operation. Inherit header parameters from I1 image
"""
Base.:-(I1::GMTimage{<:Bool},  I2::GMTimage{<:Bool})  = helper_bool_img(I1, collect(I1.image .& .!I2.image))
Base.:-(I1::GMTimage{<:UInt8}, I2::GMTimage{<:UInt8}) =
	helper_bool_img(I1, collect(reinterpret(Bool, I1.image) .& .!reinterpret(Bool, I2.image)))

# ---------------------------------------------------------------------------------------------------
"""
Add two boolean mask/uint8 images. It applies the logical `I1 || I2` operation. Inherit header parameters from I1 image

The infix operation `I1 | I2` is a synonym for `+(I1,I2)`.
"""
Base.:+(I1::GMTimage{<:Bool},  I2::GMTimage{<:Bool})  = helper_bool_img(I1, collect(I1.image .| I2.image))
Base.:|(I1::GMTimage{<:Bool},  I2::GMTimage{<:Bool})  = +(I1, I2)
Base.:|(I1::GMTimage{<:UInt8}, I2::GMTimage{<:UInt8}) = +(I1, I2)
Base.:+(I1::GMTimage{<:UInt8}, I2::GMTimage{<:UInt8}) =
	helper_bool_img(I1, collect(reinterpret(Bool, I1.image) .| reinterpret(Bool, I2.image)))

# ---------------------------------------------------------------------------------------------------
"""
Intersect two boolean/uint8 mask images. It applies the logical `I1 && I2` operation. Inherit header parameters from I1 image
"""
Base.:&(I1::GMTimage{<:Bool},  I2::GMTimage{<:Bool})  = helper_bool_img(I1, collect(I1.image .& I2.image))
Base.:&(I1::GMTimage{<:UInt8}, I2::GMTimage{<:UInt8}) =
	helper_bool_img(I1, collect(reinterpret(Bool, I1.image) .& reinterpret(Bool, I2.image)))

# ---------------------------------------------------------------------------------------------------
"""
Bitwise exclusive or of `I1` and `I2` boolean images. Inherits metadata from `I1`.

The infix operation `I1 ⊻ I2` is a synonym for `xor(I1,I2)`, and
	`⊻` can be typed by tab-completing `\\xor` or `\\veebar` in the Julia REPL.
"""
Base.:xor(I1::GMTimage{<:Bool}, I2::GMTimage{<:Bool}) = helper_bool_img(I1, collect(xor.(I1.image, I2.image)))
⊻(I1::GMTimage{<:Bool},  I2::GMTimage{<:Bool})  = xor(I1, I2)
⊻(I1::GMTimage{<:UInt8}, I2::GMTimage{<:UInt8}) = xor(I1, I2)
Base.:xor(I1::GMTimage{<:UInt8}, I2::GMTimage{<:UInt8}) =
	helper_bool_img(I1, collect(xor.(reinterpret(Bool, I1.image), reinterpret(Bool, I2.image))))

# ---------------------------------------------------------------------------------------------------
function helper_bool_img(I, z)
	# Helper function with common code all image boolean operations
	epsg, geog, range, inc, registration, nodata, x, y, v, pad = dup_G_meta(I)
	
	if (eltype(I.image) <: Bool)
		colormap, n_colors, color_interp = cpt2cmap(makecpt(T=(0,1), cmap=:gray))[1], 2, "Gray"
	else
		colormap, n_colors, color_interp = zeros(Int32,3), 0, ""
	end

	(eltype(I.image) <: UInt8) && (z = reinterpret(UInt8, z) .* UInt8(255))
	Io = GMTimage(I.proj4, I.wkt, epsg, geog, range, inc, registration, nodata, color_interp, String[], String[], x, y, v,
	              z, colormap, String[], n_colors, Array{UInt8,2}(undef,1,1), I.layout, pad)
	Io.range[5:6] .= extrema(z)
	return Io
end
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
"""
Compute the logical complement of a boolean GMTimage. Inherits metadata from input image.
"""
function Base.:!(I::GMTimage{<:Bool})
	Io = deepcopy(I)
	Io.image .= .!Io.image
	return Io
end

# ---------------------------------------------------------------------------------------------------
Base.:+(add::T, D1::GMTdataset) where T<:AbstractArray = Base.:+(D1::GMTdataset, add)
Base.:+(add::Real, D1::GMTdataset) = Base.:+(D1::GMTdataset, [add;;])
Base.:+(D1::GMTdataset, add::Real) = Base.:+(D1::GMTdataset, [add;;])
function Base.:+(D1::GMTdataset, add::T) where T<:AbstractArray
	# Add constant(s) on a per column basis. If 'add' is a scalar add it to first column.
	# Use a 1 row matrix to add different values to each column.
	if (size(D1) == size(add))
		_data = isa(add, GMTdataset) ? D1.data .+ add.data : D1.data .+ add
	else
		!isa(add, Matrix) && error("Add factors must be a scalar or a one row matrix.")
		_data, _add = copy(D1.data), copy(add)
		(length(_add) > size(_data,2)) && error("Number of adding factores greater than number of columns in dataset")
		(length(_add) < size(_data,2)) && (_add = [_add fill(zero(eltype(add)), 1, size(_data,2)-length(add))])
		_data .+= _add
	end
	D2 = GMTdataset(_data, D1.ds_bbox, D1.bbox, D1.attrib, D1.colnames, D1.text, D1.header, D1.comment, D1.proj4, D1.wkt, D1.epsg, D1.geom)
	set_dsBB!(D2)

	return D2
end
function Base.:+(D1::GMTdataset, D2::GMTdataset)
	(size(D1) != size(D2)) && error("Can not add two datasets that do not have the same size.")
	_data = D1.data .+ D2.data
	D = GMTdataset(_data, D1.ds_bbox, D1.bbox, D1.attrib, D1.colnames, D1.text, D1.header, D1.comment, D1.proj4, D1.wkt, D1.epsg, D1.geom)
	set_dsBB!(D)
	return D
end
function Base.:-(D1::GMTdataset, D2::GMTdataset)
	(size(D1) != size(D2)) && error("Can not subtract two datasets that do not have the same size.")
	_data = D1.data .- D2.data
	D = GMTdataset(_data, D1.ds_bbox, D1.bbox, D1.attrib, D1.colnames, D1.text, D1.header, D1.comment, D1.proj4, D1.wkt, D1.epsg, D1.geom)
	set_dsBB!(D)
	return D
end

# ---------------------------------------------------------------------------------------------------
Base.:-(add::T, D1::GMTdataset) where T<:AbstractArray = Base.:-(D1::GMTdataset, add)
Base.:-(add::Real, D1::GMTdataset) = Base.:+(D1::GMTdataset, [-add;;])
Base.:-(D1::GMTdataset, add::Real) = Base.:+(D1::GMTdataset, [-add;;])
Base.:-(D1::GMTdataset, add::T) where T<:AbstractArray = D1 + -add

# ---------------------------------------------------------------------------------------------------
Base.:cat(D1::Vector{<:GMTdataset}, D2::GMTdataset) = Base.cat(D1, [D2])		# LINTER IS WRONG
Base.:cat(D1::GMTdataset, D2::Vector{<:GMTdataset}) = Base.cat([D1], D2)
Base.:cat(D1::GMTdataset, D2::GMTdataset) = Base.cat([D1], [D2])
function Base.:cat(D1::Vector{<:GMTdataset}, D2::Vector{<:GMTdataset})
	# Concat 2 Vector{GMTdataset}. The important point is that the final 'ds_bbox' field gets set correctly
	# because plot() uses it to set automatic limits. 
	D = vcat(D1, D2)
	for k = 1:2:length(D1[1].ds_bbox)		# Udate the cat'ed ds_bbox. This is crutial
		D[1].ds_bbox[k]   = min(D1[1].ds_bbox[k], D2[1].ds_bbox[k])
		D[1].ds_bbox[k+1] = max(D1[1].ds_bbox[k+1], D2[1].ds_bbox[k+1])
	end
	D[length(D1)+1].ds_bbox = D[length(D1)+1].bbox	# Not really important, but it was now wrong.
	return D
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
	epsg, geog, range, inc, registration, _nodata, x, y, v, pad = dup_G_meta(G1)
	_range = [range[1:2], range[3:4], range[7:8]]
	if (isempty(v) && ndims(G1) == 3)
		v, inc::Vector{<:Float64}  = collect(1.0:size(G1,3)), [inc[:]..., 1.0]
	end
	mat = permutedims(G1.z, inds)
	# 3,2,1  3,1,2, 2,1,3  2,3,1  1,3,2
	if     (inds == [3,2,1])  x, v, x_unit = v, x, G1.z_unit
	elseif (inds == [3,1,2])  x, y, v, x_unit = v, x, y, G1.z_unit
	end
	_nodata = G1.nodata
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
	GMTgrid(G1.proj4, G1.wkt, epsg, geog, range, inc, registration, _nodata, "", "", "", "", G1.names, x, y, v,
	        mat, G1.z_unit, G1.y_unit, G1.x_unit, G1.z_unit, G1.layout, 1f0, 0f0, pad, G1.hasnans)
end

# ---------------------------------------------------------------------------------------------------
flipud(G::GMTgrid) = GMTgrid(G.proj4, G.wkt, G.epsg, G.geog, G.range, G.inc, G.registration, G.nodata, G.title, G.remark, G.command, G.cpt, G.names, G.x, G.y, G.v, flipud(G.z), G.x_unit, G.y_unit, G.v_unit, G.z_unit, G.layout, G.scale, G.offset, G.pad, G.hasnans)
fliplr(G::GMTgrid) = GMTgrid(G.proj4, G.wkt, G.epsg, G.geog, G.range, G.inc, G.registration, G.nodata, G.title, G.remark, G.command, G.cpt, G.names, G.x, G.y, G.v, fliplr(G.z), G.x_unit, G.y_unit, G.v_unit, G.z_unit, G.layout, G.scale, G.offset, G.pad, G.hasnans)
flipud(I::GMTimage) = GMTimage(I.proj4, I.wkt, I.epsg, I.geog, I.range, I.inc, I.registration, I.nodata, I.color_interp, I.metadata, I.names, I.x, I.y, I.v, flipud(I.image), I.colormap, I.labels, I.n_colors, flipud(I.alpha), I.layout, I.pad)
fliplr(I::GMTimage) = GMTimage(I.proj4, I.wkt, I.epsg, I.geog, I.range, I.inc, I.registration, I.nodata, I.color_interp, I.metadata, I.names, I.x, I.y, I.v, fliplr(I.image), I.colormap, I.labels, I.n_colors, fliplr(I.alpha), I.layout, I.pad)
