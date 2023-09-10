# ---------------------------------------------------------------------------------------------------
"""
    blendimg!(color::GMTimage, shade::GMTimage; new=false)

Blend the RGB `color` GMTimage with the `shade` intensity image (normally obtained with gdaldem)
The `new` argument determines if we return a new RGB image or update the `color` argument.

The blending method is the one explained in https://gis.stackexchange.com/questions/255537/merging-hillshade-dem-data-into-color-relief-single-geotiff-with-qgis-and-gdal/255574#255574

### Returns
A GMT RGB Image

    blendimg!(img1::GMTimage, img2::GMTimage; new=false, transparency=0.5)

Blend two 2D UInt8 or 2 RGB images using transparency. 
  - `transparency` The default value, 0.5, gives equal weight to both images. 0.75 will make
    `img` weight 3/4 of the total sum, and so forth.
  - `new` If true returns a new GMTimage object, otherwise it changes the `img1` content.

### Returns
A GMT intensity Image
"""
function blendimg!(color::GMTimage{UInt8, 3}, shade::GMTimage{UInt8, 2}; new=false)

	blend = (new) ? Array{UInt8,3}(undef, size(shade,1), size(shade,2), 3) : color.image

	n_pix = length(shade)
	if (color.layout[3] == 'B')			# Band interleaved
		for n = 1:3
			off = (n - 1) * n_pix
			@inbounds @simd for k = 1:n_pix
				t = shade.image[k] / 255
				blend[k+off] = (t < 0.5) ? round(UInt8, 2t * color.image[k+off]) : round(UInt8, (1 - 2*(1 - t) * (1 - color.image[k+off]/255)) * 255)
			end
		end
	else								# Assume Pixel interleaved
		nk = 1
		@inbounds @simd for k = 1:n_pix
			t = shade.image[k] / 255
			if (t < 0.5)
				blend[nk] = round(UInt8, 2t * color.image[nk]);		nk += 1
				blend[nk] = round(UInt8, 2t * color.image[nk]);		nk += 1
				blend[nk] = round(UInt8, 2t * color.image[nk]);		nk += 1
			else
				blend[nk] = round(UInt8, (1 - 2*(1 - t) * (1 - color.image[nk]/255)) * 255);	nk += 1
				blend[nk] = round(UInt8, (1 - 2*(1 - t) * (1 - color.image[nk]/255)) * 255);	nk += 1
				blend[nk] = round(UInt8, (1 - 2*(1 - t) * (1 - color.image[nk]/255)) * 255);	nk += 1
			end
		end
	end
	return (new) ? mat2img(blend, color) : color
end

function blendimg!(img1::GMTimage, img2::GMTimage; new=false, transparency=0.5)
	# This method blends two UInt8 images with transparency
	@assert eltype(img1) == eltype(img2)
	@assert length(img1) == length(img2)
	same_layout = (img1.layout[1:2] == img2.layout[1:2])
	blend = (new) ? Array{eltype(img1), ndims(img1)}(undef, size(img1)) : img1.image
	t, o = transparency, 1. - transparency
	if (same_layout)
		@inbounds @simd for k = 1:length(img1)
			blend[k] = round(UInt8, t * img1.image[k] + o * img2.image[k])
		end
	else
		#(size(img1,3) == 1) && error("Sorry, blending RGB images of different mem layouts is not yet implemented")
		flip, transp = img1.layout[1] != img2.layout[1], img1.layout[2] != img2.layout[2]
		if     (flip && !transp)  blend = reverse(img2.image, dims=1)
		elseif (!flip && transp)  blend = collect(img2.image')
		else                      blend = reverse(img2.image', dims=1)
		end
		@inbounds @simd for k = 1:length(img1)
			blend[k] = round(UInt8, t * img1.image[k] + o * blend[k])
		end
		(!new) && (img1.image = blend)
	end
	return (new) ? mat2img(blend, img1) : img1
end

# ---------------------------------------------------------------------------------------------------
"""
    gammacorrection(I::GMTimage, gamma; contrast=[0.0, 1.0], brightness=[0.0, 1.0])

Apply a gamma correction to a 2D (intensity) GMTimage using the exponent `gamma`.
Optionally set also `contrast` and/or `brightness`

### Returns
A GMT intensity Image
"""
function gammacorrection(I::GMTimage, gamma; contrast=[0.0, 1.0], brightness=[0.0, 1.0])

	@assert 0.0 <= contrast[1] < 1.0;	@assert 0.0 < contrast[2] <= 1.0;	@assert contrast[2] > contrast[1]
	@assert 0.0 <= brightness[1] < 1.0;	@assert 0.0 < brightness[2] <= 1.0;	@assert brightness[2] > brightness[1]
	contrast_min, contrast_max, brightness_min, brightness_max = 0.0, 1.0, 0.0, 1.0
	lut = (eltype(I) == UInt8) ? linspace(0.0, 1, 256) : linspace(0.0, 1, 65536)
	lut = max.(contrast[1], min.(contrast[2], lut))
	lut = ((lut .- contrast[1]) ./ (contrast[2] - contrast[1])) .^ gamma;
	lut = lut .* (brightness[2] - brightness[1]) .+ brightness[1];		# If brightness[1] != 0 || brightness[2] != 1
	lut = (eltype(I) == UInt8) ? round.(UInt8, lut .* 255) : round.(UInt16, lut .* 65536)
	intlut(I, lut)
end

"""
    intlut(I, lut)

Creates an array containing new values of `I` based on the lookup table, `lut`. `I` can be a GMTimage or an uint matrix.
The types of `I` and `lut` must be the same and the number of elements of `lut` is eaqual to intmax of that type.
E.g. if eltype(lut) == UInt8 then it must contain 256 elements.

### Returns
An object of the same type as I
"""
function intlut(I, lut)
	@assert eltype(I) == eltype(lut)
	mat = Array{eltype(I), ndims(I)}(undef, size(I))
	@inbounds for n in eachindex(I)
		mat[n] = lut[I[n]+1]
	end
	return (isa(I, GMTimage)) ? mat2img(mat, I) : mat
end

# ---------------------------------------------------------------------------------------------------
"""
    texture_img(G::GMTgrid; detail=1.0, contrast=2.0, intensity=false)

Compute the Texture Shading calling functions from the software from Leland Brown at
http://www.textureshading.com/Home.html

- `G`: The ``GMTgrid`` from which to compute the Leland texture illumination image.
- `detail` is the amount of texture detail. Lower values of detail retain more elevation information,
  giving more sense of the overall, large structures and elevation trends in the terrain, at the expense
  of fine texture detail. Higher detail enhances the texture but gives an overall "flatter" general appearance,
  with elevation changes and large structure less apparent.
- `contrast` is a parameter called “vertical enhancement.” Higher numbers increase contrast in the midtones,
  but may lose detail in the lightest and darkest features. Lower numbers highlight only the sharpest ridges
  and deepest canyons but reduce contrast overall.
- `intensity | uint16` controls if output is a UInt16 or a UInt8 image (the default). Note that the original code
  writes only UInt16 images but if we want to combine this with the hillshade computed with ``gdaldem``,
  a UInt8 image is more handy.

### Returns
A UInt8 (or 16) GMT Image
"""
function texture_img(G::GMTgrid; detail=1.0, contrast=2.0, uint16=false, intensity=false)
	# Here we have a similar problem with the memory layout as described in gmt2ds(). Specialy with the
	# variants of the TRB layout. Other than that, it's strange (probably to dive in the C code to relearn)
	# why the memory layout of the BCB mode needs to changed in the way we do below.
	memlayout = (!isempty(G.layout)) ? G.layout : "BCB"		# Shield against no layout info
	if (memlayout[2] == 'C')  texture = reshape(reverse(G.z', dims=2), size(G))
	else                      texture = (size(G.z,1) == length(G.x) - G.registration) ?
	                                     reshape(copy(G.z), (length(G.y), length(G.x)) .- G.registration) : deepcopy(G.z)
	end
	n_rows, n_cols = size(texture,1), size(texture,2)
	terrain_filter(texture, detail, n_rows, n_cols, G.inc[1], G.inc[2], 0)
	(startswith(G.proj4, "+proj=merc")) && fix_mercator(texture, detail, n_rows, n_cols, G.range[3], G.range[4])
	(intensity) && (uint16 = true)
	terrain_image_data(texture, contrast, n_rows, n_cols, 0.0, (uint16) ? 65535.0 : 255.0)
	if (intensity) 
		texture = texture ./ 65535 .* 2 .- 1
		Go = mat2grid(texture, G)
		Go.range[5:6] .= extrema(Go.z)
	else
		mat = (uint16) ? round.(UInt16, texture) : round.(UInt8, texture)
		Go = mat2img(mat, hdr=grid2pix(G), proj4=G.proj4, wkt=G.wkt, noconv=true, layout="TRBa")#layout=G.layout*"a")
		Go.range[5:6] .= extrema(Go.image)
	end
	Go
end

# ---------------------------------------------------------------------------------------------------
"""
    [I = ] lelandshade(G::GMTgrid; detail=1.0, contrast=2.0, intensity=false, zfactor=3, transparency=0.6,
                       show=false, color=false, opts=String[], cmap="", kw...)

Compute a grayscale or color shaded illumination image using the thechnique developed by [Leland Brown's "texture shading"](http://www.textureshading.com/Home.html) 

- `G`: A ``GMTgrid`` or a grid file name from which to compute the Leland texture illumination image.
- `detail` is the amount of texture detail. Lower values of detail retain more elevation information,
  giving more sense of the overall, large structures and elevation trends in the terrain, at the expense
  of fine texture detail. Higher detail enhances the texture but gives an overall "flatter" general appearance,
  with elevation changes and large structure less apparent.
- `contrast` is a parameter called “vertical enhancement.” Higher numbers increase contrast in the midtones,
  but may lose detail in the lightest and darkest features. Lower numbers highlight only the sharpest ridges
  and deepest canyons but reduce contrast overall.
- `intensity | uint16` controls if output is a UInt16 or a UInt8 image (the default). Note that the original code
  writes only UInt16 images but if we want to combine this with the hillshade computed with ``gdaldem``,
  a UInt8 image is more handy.
- `zfactor`: A terrain amplification factor used in ``gdaldem`` when computing the "hillshade"
- `transparency`: The transparency of the texture image computed with the Leland algorithm when blended with
  hillshade computed with ``gdaldem``. The default value, 0.5, gives equal weight to both images. A value of
  0.75 will make the texture image weight 3/4 of the total sum, and so forth.
- `color`: Boolean that selects if the output is a color or a grayscale image (the default). For color images
  we create a default linear color map (via a call to ``makecpt``), but this can be overruled with the `cmap` option.
- `equalize`: For color images one may select to histogram equalize the colors (via a call to ``grd2cpt``).
  This option alone (as well as `cmap`) also sets `color=true`. 
- `opts`: A (optional) string vector with ``gdaldem`` dedicated options (see its man mage). Use this to fine tune
  the "hillshade" part of the final image.
- `cmap`: When doing color images and don't want the default cmap, pass a color map (cpt) name (file or master
  cpt name) or ``GMTcpt``. This also sets `color=true`.
- `colorbar`: Boolean, used only when `show=true`, to add a colorbar on the right side of the image.
- `show`: Boolean that if set to `true` will show the result immediately. If `false`, a ``GMTimage`` object
  is returned.
- `kw`: The keword/value pairs that can be used to pass arguments to ``makecpt``, ``grd2cpt`` and ``gdaldem``.

### Examples:
    lelandshade(gmtread("@earth_relief_01s", region=(-114,-113,35,36)), color=true, colorbar=true, show=true)

### Returns
A GMTimage object (8 or 16 bits depending on the `intensity` option) if show == false, or nothing otherwise.
"""
function lelandshade(G::String; detail=1.0, contrast=2.0, uint16=false, intensity=false, zfactor=3, transparency=0.6,
                     color=false, equalize=false, opts::Vector{String}=String[], cmap="", colorbar=false, show=false, kw...)
	lelandshade(gmtread(G); detail=detail, contrast=contrast, uint16=uint16, intensity=intensity, zfactor=zfactor,
                transparency=transparency, color=color, equalize=equalize, opts=opts, cmap=cmap, colorbar=colorbar, show=show, kw...)
end
function lelandshade(G::GMTgrid; detail=1.0, contrast=2.0, uint16=false, intensity=false, zfactor=3, transparency=0.6,
                     color=false, equalize=false, opts::Vector{String}=String[], cmap="", colorbar=false, show=false, kw...)
	(cmap != "" || equalize != 0) && (color = true)
	(cmap == "" && (isa(color, GMTcpt) || isa(color, StrSymb))) && (cmap = color) 	# Allow color=cpt under the hood.
	gray = (color == 1) ? false : true
	(color != 0) && (gray = false)
	I1 = texture_img(G, detail=detail, contrast=contrast, uint16=uint16, intensity=intensity)	# Compute the texture
	Ihill = gdaldem(G, "hillshade", opts; zfactor=zfactor, Vd=-1, kw...)	# Compute the hillshade. zfactor is a terrain amp factor
	if (gray == 1)
		blendimg!(I1, Ihill, transparency=transparency)
	else
		iscptmaster = (cmap != "") && (isa(cmap, Symbol) || (isa(cmap, String) && !endswith(cmap, ".cpt")))
		_cpt = iscptmaster ? cmap : nothing
		if (cmap != "")
			cpt = cmap
			isa(cpt, GMTcpt) && (CURRENT_CPT[1] = cpt)
		elseif (equalize == 0)
			cpt = makecpt(G; C=_cpt, Vd=-1, kw...)		# The 'nothing' branch will pick G's cpt
		else
			cpt = (equalize == 1) ? grd2cpt(G, C=_cpt, kw...) : grd2cpt(G, T="$equalize", C=_cpt, Vd=-1, kw...)
		end
		color = gdaldem(G, "color-relief"; color=cpt, kw...)
		blendimg!(I1, Ihill)
		blendimg!(color, I1)
		I1 = color			# To use the same name as in the gray branch
	end
	
	return show == 1 ? viz(I1; colorbar=colorbar, Vd=-1, kw...) : I1
end
