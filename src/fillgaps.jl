# fillgaps.jl — fill NaN holes in a grid by minimum-curvature interpolation (surface) over a
# small PADDED window around each hole, instead of resurfacing the whole grid. Holes are found with
# polygonize (gdal_tools.jl, GDALPolygonize under the hood) on the NaN mask, not a hand-rolled
# flood fill.
#
# Per hole: take its polygon bbox, pad it by `pad` grid nodes (clamped to the grid), gather the
# VALID (non-NaN) nodes in that padded window, and re-surface just that window with surface.
# Only the nodes that were actually NaN get overwritten — the padded ring of real data is control
# data for the interpolation only, never touched.

# Bounding box (xmin,xmax,ymin,ymax) -> padded NODE index window (1-based, inclusive), clamped to
# the grid so a hole near an edge never overflows.
function _hole_idx_window(xv::Vector{Float64}, yv::Vector{Float64}, bbox::Vector{Float64}, pad::Int)
	dx = xv[2] - xv[1];  dy = yv[2] - yv[1]
	c0 = round(Int, (bbox[1] - xv[1]) / dx) + 1 - pad
	c1 = round(Int, (bbox[2] - xv[1]) / dx) + 1 + pad
	r0 = round(Int, (bbox[3] - yv[1]) / dy) + 1 - pad
	r1 = round(Int, (bbox[4] - yv[1]) / dy) + 1 + pad
	return clamp(r0, 1, length(yv)), clamp(r1, 1, length(yv)), clamp(c0, 1, length(xv)), clamp(c1, 1, length(xv))
end

"""
    Gout, holes = fillgaps(G::GMTgrid; pad::Int=4, tension::Float64=0.25)

Fill NaN holes in `G` by re-interpolating a small window around each hole from its own
surrounding valid data (`GMT.surface`, minimum curvature), instead of resurfacing the whole grid.

1. Mask the NaN nodes and find each hole's boundary with `GMT.polygonize`.
2. Pad each hole's bounding box by `pad` grid nodes (clamped to the grid).
3. Interpolate that padded window from its valid (non-NaN) nodes with `GMT.surface`.
4. Paste the interpolated values back — ONLY at the nodes that were actually NaN.

Returns the filled grid and a mask image (GMTimage{Bool,2}) of the holes that were filled.
Use this mask to restore the original NaNs if you want to revert the fill.
"""
function fillgaps(G::GMTgrid{Float32,2}; pad::Int=4, tension::Float64=0.25)
	Gout = deepcopy(G)
	mask_grid = fillgaps!(Gout; pad, tension)
	return Gout, mask_grid
end

"""
    mask_grid = fillgaps!(G::GMTgrid; pad::Int=4, tension::Float64=0.25)

In-place version of — mutates `G.z` directly and returns the mask_grid GMTimage{Bool,2} mask.
"""
function fillgaps!(G::GMTgrid{Float32,2}; pad::Int=4, tension::Float64=0.25)::GMTimage{Bool,2}
	(G.hasnans == 1) && return GMTimage{Bool,2}()		# Grid says it has no NaNs to fill
	nanmask = isnan.(G.z)
	any(nanmask) || return GMTimage{Bool,2}()			# If G.hasnans == 0 , it was a "Don't know"

	mask_grid = mat2img(collect(nanmask), G)
	D = polygonize(mask_grid)
	D isa GMTdataset && (D = [D])

	xv, yv = G.x, G.y
	dx, dy = G.inc[1], G.inc[2]
	regflag = (G.registration == 1) ? " -r" : ""

	for d in D
		r0, r1, c0, c1 = _hole_idx_window(xv, yv, d.bbox, pad)
		sub     = @view G.z[r0:r1, c0:c1]
		submask = @view nanmask[r0:r1, c0:c1]
		valid   = .!submask
		count(valid) < 4 && continue                # not enough control points to interpolate

		SX = repeat(reshape(xv[c0:c1], 1, :), r1 - r0 + 1, 1)
		SY = repeat(reshape(yv[r0:r1], :, 1), 1, c1 - c0 + 1)
		XX, YY, ZZ = SX[valid], SY[valid], Float64.(sub[valid])

		opts  = "surface -R$(xv[c0])/$(xv[c1])/$(yv[r0])/$(yv[r1]) -I$(dx)/$(dy) -T$(tension)$regflag"
		Gtile = gmt(opts, [XX YY ZZ])

		idx = findall(submask) .+ CartesianIndex(r0 - 1, c0 - 1)
		G.z[idx] .= Gtile.z[submask]
	end

	setgrdminmax!(G)
	return mask_grid
end
