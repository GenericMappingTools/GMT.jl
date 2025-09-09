"""
	I = anaglyph(G|fname; vscale=1, sscale=2, kw...)

---

	I = anaglyph(G|fname; view3d::Bool=false, zsize=4, azim=190, dazim=2, cmap="gray", kw...)

---

Generate an anaglyph image from the input grid `G`.

### Args
- `G`: The input GMTgrid or filename of data to be processed.

### Kwargs
- `vscale`: Terrain vertical scale factor (default: 1). Applyies only to first method.
- `sscale`: Stereo separation scale factor (default: 2). . Applyies only to first method.
- `R`: Region of interest when reading a grid from disk (default: entire grid).
   Ignored when `G` is a GMTgrid.
- `view3d`: If true, selects an alternative and slower method that generates 2 3D views using the `grdview` program 
   and construct the anaglyph from those two images (default: false).
- `zsize`: z-axis size of the 3D view. Same as in `grdview` (default: 4 cm).
- `azim`: Azimuth of the 3D view (default: 190).
- `dazim`: Azimuth step (default: 2). It means, create the anaglyph from the pair of images obtained
   with `azim` and `azim - dazim`.
- `cmap`: Color map (default: "gray").

### Returns
An anaglyph image suitable for viewing with red-cyan glasses.

### Credits
The method that uses the grid's gradient is based on an ancient program called ManipRaster by Tierrt Souriot.
The second method, the one that uses the `grdview` program, was proposed by Tim Hume in the GMT forum.
(https://forum.generic-mapping-tools.org/t/bringing-the-third-dimension-to-gmt-stereograms/6189)

### Example
```
	I = anaglyph("@earth_relief_30s", region="-13/-5.5/35/44")
```
"""
function anaglyph(fname::String; vscale=1, sscale=2, view3d::Bool=false, zsize=4, azim=190, dazim=2, cmap="gray", kw...)

	d = KW(kw)
	opt_R::String = parse_R(d, "")[2]
	G = (opt_R === "") ? gmtread(fname) : gmtread(fname, R=opt_R[4:end])
	!isa(G, GMTgrid) && error("Input must be a GMTgrid")
	return view3d ? anaglyph_3d(G, zsize=zsize, azim=azim, dazim=dazim, cmap=cmap) : anaglyph(G, vscale=vscale, sscale=sscale)
end

function anaglyph(G::GMTgrid; vscale=1, sscale=2, view3d=false, zsize=4, azim=190, dazim=2, cmap="gray")

	view3d && return anaglyph_3d(G, zsize=zsize, azim=azim, dazim=dazim, cmap=cmap)

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

	deg2m = 111194.9
	p_size = isgeog(G) ? sqrt((G.inc[1] * deg2m) * (G.inc[2] * deg2m * cosd((G.range[3] + G.range[4]) * 0.5))) : G.inc[1] * G.inc[2]

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

# ---------------------------------------------------------------------------------------------------
function anaglyph_3d(G::GMTgrid; zsize=4, azim=190, dazim=2, cmap="gray")

	p_left, p_right = "$(azim)/30/0", "$(azim - dazim)/30/0"
	pato = TMPDIR_USR[1] * "/" * "GMTjl_" * TMPDIR_USR[2] * TMPDIR_USR[3]
	grdview(G, J="Q20c", JZ="$zsize", B=:none, C=string(cmap), Q=:i, p=p_left, I=true, figname=pato * ".jpg")
	Il = gdalread(pato * ".jpg", "-b 1", layout="TCBa")
	nr_l, nc_l = size(Il,1), size(Il,2)
	grdview(G, J="Q20c", JZ="$zsize", B=:none, C=string(cmap), Q=:i, p=p_right, I=true, figname=pato * ".jpg")
	Ir = gdalread(pato * ".jpg", layout="TCBa")
	nr_r, nc_r = size(Ir,1), size(Ir,2)

	center_left  = (nr_l ÷ 2 + 1, nc_l ÷ 2 + 1)
	center_right = (nr_r ÷ 2 + 1, nc_r ÷ 2 + 1)

	nc, nr = round(Int, min(nc_l, nc_r)*0.85), round(Int, min(nr_l, nr_r)*0.85)
	nc2, nr2 = div(nc, 2), div(nr, 2)

	im_right = Ir[center_right[1]-nr2:center_right[1]+nr2 , center_right[2]-nc2:center_right[2]+nc2, :]
	im_left  = Il[center_left[1]-nr2:center_left[1]+nr2 , center_left[2]-nc2:center_left[2]+nc2]
	im_right[:,:,1] = im_left
	im_right[:,:,2] = im_right[:,:,3]
	mat2img(im_right)
end
