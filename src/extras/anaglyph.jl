"""
	I = anaglyph(G|fname, vscale=1, sscale=2; kw...)

Generate an anaglyph image from the input grid `G`.

### Args
- `G`: The input GMTgrid or filename of data to be processed.
- `vscale`: Vertical scale factor (default: 1).
- `sscale`: Stereo separation scale factor (default: 2).

### Kwargs
- `R`: Region of interest when reading a grid from disk (default: entire grid).
  Ignored when `G` is a GMTgrid.

### Returns
An anaglyph image suitable for viewing with red-cyan glasses.

### Example
```julia
	I = anaglyph("@earth_relief_30s", region="-13/-5.5/35/44")
```
"""
function anaglyph(fname::String, vscale=1, sscale=2; kw...)
	d = KW(kw)
	opt_R::String = parse_R(d, "")[2]
	G = (opt_R === "") ? gmtread(fname) : gmtread(fname, R=opt_R[4:end])
	!isa(G, GMTgrid) && error("Input must be a GMTgrid")
	anaglyph(G, vscale, sscale)
end
function anaglyph(G::GMTgrid, vscale=1, sscale=2; kw...)

	m_scale = -vscale / 50	# Amp factor

	function gra(G, scale)
		azim,elev = 0.0, 30.0
		s = [sind(azim) * cosd(elev); cosd(azim) * cosd(elev); sind(elev)]
		data = zeros(Float32, size(G))
		@inbounds Threads.@threads for c = 2:size(G,1)-1
			@inbounds for r = 2:size(G,2)-1
				dzdx = (G[c+1, r] - G[c-1, r]) * scale
				dzdy = (G[c, r+1] - G[c, r+1]) * scale
				data[c,r] = Float32((dzdy*s[1] + dzdx*s[2] + 2*s[3]) / (sqrt(dzdy * dzdy + dzdx * dzdx + 4)))
			end
		end
		data
	end

	sh = imagesc(gra(G, m_scale))		# A gray-scale image

	if isgeog(G)
		deg2m = 111194.9
		p_size = sqrt((G.inc[1] * deg2m) * (G.inc[2] * deg2m * cosd((G.range[3] + G.range[4]) * 0.5)))
	else
		p_size = G.inc[1] * G.inc[2]
	end

	z_min, z_max = G.range[5], G.range[6] + 1
	alpha = tand(25) * sscale / p_size
	decal = floor(Int, 2 * alpha * (z_max - z_min))
	decal = max(8, decal + mod(decal, 2)) # Make it always even and with a minimum of 8
	decal > 100 && error("decal=$decal is too big. Your grid is probably in geographic coordinates but it hasn't set it in metadata.")

	ny, nx = size(G)
	l, r = 0, 0
	inner_ind = ((decal ÷ 2) + 1):(nx + (decal ÷ 2))
	left = fill(UInt8(255), nx + decal);	right = similar(left)
	argg = fill(UInt8(0), ny, nx, 3)

	@inbounds for i = 1:ny
		@inbounds for j = 1:nx
			iz = floor(Int, alpha * (G[i, j] - z_min))
			if j == 1
				left[j + iz] = sh[i, j]
				right[decal + j - iz] = sh[i, j]
			else
				@inbounds for k in r:(decal + j - iz)
					right[k] = sh[i, j]
				end
				@inbounds for k in l:(j + iz)
					left[k] = sh[i, j]
				end
			end
			l = j + iz
			r = decal + j - iz
		end
		for k = 1:nx  argg[i, k, 1] = left[inner_ind[k]]  end
		for k = 1:nx  argg[i, k, 2] = argg[i, k, 3] = right[inner_ind[k]]  end
		left .= UInt8(0);	right .= UInt8(0)
	end
	mat2img(argg, G)
end