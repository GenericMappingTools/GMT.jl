function text_record(data, text, hdr=Vector{String}())
	# Create a text record to send to pstext. DATA is the Mx2 coordinates array.
	# TEXT is a string or a cell array

	if (isa(data, Vector))  data = data[:,:]  end 	# Needs to be 2D
	if (!isa(data, Array{Float64}))  data = Float64.(data)  end

	if (isa(text, String))
		T = GMTdataset(data, [text], "", Vector{String}(), "", "", 0)
	elseif (isa(text, Array{String}))
		if (text[1][1] == '>')			# Alternative (but risky) way of setting the header content
			T = GMTdataset(data, text[2:end], text[1], Vector{String}(), "", "", 0)
		else
			T = GMTdataset(data, text, (isempty(hdr) ? "" : hdr), Vector{String}(), "", "", 0)
		end
	elseif (isa(text, Array{Array}) || isa(text, Array{Vector{String}}))
		nl_t = length(text);	nl_d = length(data)
		(nl_d > 0 && nl_d != nl_t) && error("Number of data points is not equal to number of text strings.")
		T = Vector{GMTdataset}(undef,nl_t)
		for k = 1:nl_t
			T[k] = GMTdataset((nl_d == 0 ? data : data[k]), text[k], (isempty(hdr) ? "" : hdr[k]), Vector{String}(), "", "", 0)
		end
	else
		error("Wrong type ($(typeof(text))) for the 'text' argin")
	end
	return T
end
text_record(text) = text_record(Array{Float64,2}(undef,0,0), text)
text_record(text::Array{String}, hdr::String) = text_record(Array{Float64,2}(undef,0,0), text, hdr)

# ---------------------------------------------------------------------------------------------------
"""
    D = mat2ds(mat [,txt]; x=nothing, hdr=nothing, color=nothing, fill=nothing, ls=nothing, text=nothing, multi=false)

Take a 2D `mat` array and convert it into a GMTdataset. `x` is an optional coordinates vector (must have the
same number of elements as rows in `mat`). Use `x=:ny` to generate a coords array 1:n_rows of `mat`.
  - `hdr` optional String vector with either one or n_rows multisegment headers.
  - `color` optional array of strings with color names/values. Its length can be smaller than n_rows, case in
     which colors will be cycled.
  - `linethick`, or `lt` for selecting different line thicknesses. Work alike `color`, but should be 
     a vector of numbers, or just a single number that is then appl	ied to all lines.
  - `fill`  Optional string array with color names or array of "patterns"
  - `ls`    Line style. A string or an array of strings with ``length = size(mat,1)`` with line styles.
  - `txt`   Return a Text record which is a Dataset with data = Mx2 and text in third column. The ``text``
     can be an array with same size as ``mat``rows or a string (will be reapeated n_rows times.) 
  - `multi` When number of columns in `mat` > 2, or == 2 and x != nothing, make an multisegment Dataset with
     first column and 2, first and 3, etc. Convenient when want to plot a matrix where each column is a line. 
"""
function mat2ds(mat, txt=Vector{String}(); hdr=Vector{String}(), geom=0, kwargs...)
	d = KW(kwargs)

	(!isempty(txt)) && return text_record(mat, txt,  hdr)
	((text = find_in_dict(d, [:text])[1]) !== nothing) && return text_record(mat, text, hdr)

	val = find_in_dict(d, [:multi :multicol])[1]
	multi = (val === nothing) ? false : ((val) ? true : false)	# Like this it will error if val is not Bool

	if ((x = find_in_dict(d, [:x])[1]) !== nothing)
		n_ds = (multi) ? size(mat, 2) : 1
		xx = (x == :ny || x == "ny") ? collect(1.0:size(mat, 1)) : x
		(length(xx) != size(mat, 1)) && error("Number of X coordinates and MAT number of rows are not equal")
	else
		n_ds = (ndims(mat) == 3) ? size(mat,3) : ((multi) ? size(mat, 2) - 1 : 1)
		xx = Vector{Float64}()
	end

	if (!isempty(hdr) && isa(hdr, String))	# Accept one only but expand to n_ds with the remaining as blanks
		bak = hdr;		hdr = Base.fill("", n_ds);	hdr[1] = bak
	elseif (!isempty(hdr) && length(hdr) != n_ds)
		error("The header vector can only have length = 1 or same number of MAT Y columns")
	end

	if ((color = find_in_dict(d, [:color])[1]) !== nothing)
		_color::Array{String} = isa(color, Array{String}) ? color : ["#0072BD", "#D95319", "#EDB120", "#7E2F8E", "#77AC30", "#4DBEEE", "#A2142F"]
	end
	_fill = helper_ds_fill(d)

	# ---  Here we deal with line colors and line thickness. If not provided we override the GMR defaultb -Wthin ---
	val = find_in_dict(d, [:lt :linethick :linethickness])[1]
	_lt = (val === nothing) ? [0.5] : val
	_lts = Vector{String}(undef, n_ds)
	n_thick = length(_lt)
	[_lts[k] = " -W" * string(_lt[((k % n_thick) != 0) ? k % n_thick : n_thick])  for k = 1:n_ds]

	if (color !== nothing)
		n_colors = length(_color)
		if (isempty(hdr))
			hdr = Vector{String}(undef, n_ds)
			[hdr[k]  = _lts[k] * string(",", _color[((k % n_colors) != 0) ? k % n_colors : n_colors])  for k = 1:n_ds]
		else
			[hdr[k] *= _lts[k] * string(",", _color[((k % n_colors) != 0) ? k % n_colors : n_colors])  for k = 1:n_ds]
		end
	else						# Here we just overriding the GMT -W default that is too thin.
		if (isempty(hdr))
			hdr = Vector{String}(undef, n_ds)
			[hdr[k]  = _lts[k] for k = 1:n_ds]
		else
			[hdr[k] *= _lts[k] for k = 1:n_ds]
		end
	end
	# ----------------------------------------

	if ((ls = find_in_dict(d, [:ls :linestyle])[1]) !== nothing && ls != "")
		if (isa(ls, AbstractString) || isa(ls, Symbol))
			[hdr[k] = string(hdr[k], ',', ls) for k = 1:n_ds]
		else
			[hdr[k] = string(hdr[k], ',', ls[k]) for k = 1:n_ds]
		end
	end

	if (!isempty(_fill))				# Paint the polygons (in case of)
		n_colors = length(_fill)
		if (isempty(hdr))
			hdr = Array{String,1}(undef, n_ds)
			[hdr[k]  = " -G" * _fill[((k % n_colors) != 0) ? k % n_colors : n_colors]  for k = 1:n_ds]
		else
			[hdr[k] *= " -G" * _fill[((k % n_colors) != 0) ? k % n_colors : n_colors]  for k = 1:n_ds]
		end
	end

	prj = ((proj = find_in_dict(d, [:proj :proj4])[1]) !== nothing) ? proj : ""
	(prj != "" && !startswith(prj, "+proj=")) && (prj = "+proj=" * prj)
	wkt = ((wk = find_in_dict(d, [:wkt])[1]) !== nothing) ? wk : ""

	D = Vector{GMTdataset}(undef, n_ds)

	if (!isa(mat, Array{Float64}))  mat = Float64.(mat)  end
	if (isempty(xx))
		if (ndims(mat) == 3)
			[D[k] = GMTdataset(view(mat,:,:,k), String[], (isempty(hdr) ? "" : hdr[k]), String[], prj, wkt, geom) for k = 1:n_ds]
		elseif (!multi)
			D[1] = GMTdataset(mat, String[], (isempty(hdr) ? "" : hdr[1]), String[], prj, wkt, geom)
		else
			[D[k] = GMTdataset(mat[:,[1,k+1]], String[], (isempty(hdr) ? "" : hdr[k]), String[], prj, wkt, geom) for k = 1:n_ds]
		end
	else
		if (!multi)
			D[1] = GMTdataset(hcat(xx,mat), String[], (isempty(hdr) ? "" : hdr[1]), String[], prj, wkt, geom)
		else
			[D[k] = GMTdataset(hcat(xx,mat[:,k]), String[], (isempty(hdr) ? "" : hdr[k]), String[], prj, wkt, geom) for k = 1:n_ds]
		end
	end
	return D
end

# ---------------------------------------------------------------------------------------------------
function ds2ds(D::GMTdataset; kwargs...)::Vector{<:GMTdataset}
	# Take one DS and split it in an array of DS, one for each row and optionally add -G,fill>
	# So far only for internal use but may grow in function of needs
	d = KW(kwargs)

	#multi = "r"		# Default split by rows
	#if ((val = find_in_dict(d, [:multi])[1]) !== nothing)  multi = "c"  end		# Then by columns
	_fill = helper_ds_fill(d)

	if ((val = find_in_dict(d, [:color_wrap])[1]) !== nothing)	# color_wrap is a kind of private option for bar-stack
		n_colors = Int(val)
	end

	n_ds = size(D.data, 1)
	if (!isempty(_fill))				# Paint the polygons (in case of)
		hdr = Vector{String}(undef, n_ds)
		[hdr[k] = " -G" * _fill[((k % n_colors) != 0) ? k % n_colors : n_colors]  for k = 1:n_ds]
		if (D.header != "")  hdr[1] = D.header * hdr[1]  end	# Copy eventual contents of first header
	end

	Dm = Vector{GMTdataset}(undef, n_ds)
	for k = 1:n_ds
		Dm[k] = GMTdataset(D.data[k:k, :], String[], (isempty(_fill) ? "" : hdr[k]), String[], "", "", 0)
	end
	Dm[1].comment = D.comment;	Dm[1].proj4 = D.proj4;	Dm[1].wkt = D.wkt
	(size(D.text) == n_ds) && [Dm.text[k] = D.text[k] for k = 1:n_ds]
	Dm
end

# ------------------------------
function helper_ds_fill(d::Dict)
	# Shared by ds2ds & mat2ds
	if ((fill_val = find_in_dict(d, [:fill :fillcolor])[1]) !== nothing)
		_fill::Array{String} = (isa(fill_val, Array{String}) && !isempty(fill_val)) ? fill_val :
		                       ["#0072BD", "#D95319", "#EDB120", "#7E2F8E", "#77AC30", "#4DBEEE", "#A2142F", "0/255/0"]
		n_colors = length(_fill)
		if ((alpha_val = find_in_dict(d, [:fillalpha])[1]) !== nothing)
			if (eltype(alpha_val) <: AbstractFloat && maximum(alpha_val) <= 1)  alpha_val = collect(alpha_val) .* 100  end
			_alpha = Vector{String}(undef, n_colors)
			na = min(length(alpha_val), n_colors)
			[_alpha[k] = join(string('@',alpha_val[k])) for k = 1:na]
			(na < n_colors) && [_alpha[k] = "" for k = na+1:n_colors]
			[_fill[k] *= _alpha[k] for k = 1:n_colors]		# And finaly apply the transparency
		end
	else
		_fill = Vector{String}()
	end
	return _fill
end

# ---------------------------------------------------------------------------------------------------
"""
    I = mat2img(mat::Array{<:Unsigned}; x=[], y=[], hdr=nothing, proj4::String="", wkt::String="", cmap=nothing, kw...)

Take a 2D 'mat' array and a HDR 1x9 [xmin xmax ymin ymax zmin zmax reg xinc yinc] header descriptor
and return a GMTimage type.
Alternatively to HDR, provide a pair of vectors, x & y, with the X and Y coordinates.
Optionaly, the HDR arg may be ommited and it will computed from 'mat' alone, but then x=1:ncol, y=1:nrow
When 'mat' is a 3D UInt16 array we automatically compute a UInt8 RGB image. In that case 'cmap' is ignored.
But if no conversion is wanted use option 'noconv=true'

    I = mat2img(mat::Array{UInt16}; x=[], y=[], hdr=nothing, proj4::String="", wkt::String="", kw...)

Take a `mat` array of UInt16 and scale it down to UInt8. Input can be 2D or 3D.
If the kw variable `stretch` is used, we stretch the intervals in `stretch` to [0 255].
Use this option to stretch the image histogram.
If `stretch` is a scalar, scale the values > `stretch` to [0 255]
  - stretch = [v1 v2] scales all values >= v1 && <= v2 to [0 255]
  - stretch = [v1 v2 v3 v4 v5 v6] scales firts band >= v1 && <= v2 to [0 255], second >= v3 && <= v4, same for third
  - stretch = :auto | "auto" | true | 1 will do an automatic stretching from values obtained from histogram thresholds
"""
function mat2img(mat::Array{<:Unsigned}, dumb::Int=0; x=Vector{Float64}(), y=Vector{Float64}(), hdr=nothing, proj4::String="", wkt::String="", cmap=nothing, kw...)
	# Take a 2D array of uint8 and turn it into a GMTimage.
	color_interp = "";		n_colors = 0;
	if (cmap !== nothing)
		have_alpha = !all(cmap.alpha .== 0.0)
		nc = have_alpha ? 4 : 3
		colormap = zeros(Clong, 256 * nc)
		n_colors = 256;			# Because for GDAL we always send 256 even if they are not all filled
		@inbounds for n = 1:3	# Write 'colormap' row-wise
			@inbounds for m = 1:size(cmap.colormap, 1)
				colormap[m + (n-1)*n_colors] = round(Int32, cmap.colormap[m,n] * 255);
			end
		end
		if (have_alpha)			# Have alpha color(s)
			[colormap[m + 3*n_colors] = round(Int32, cmap.colormap[m,4] * 255) for m = 1:size(cmap.colormap, 1)]
			n_colors *= 1000				# Flag that we have alpha colors in an indexed image
		end
	else
		if (size(mat,3) == 1)  color_interp = "Gray"  end
		colormap = zeros(Clong,3)			# Because we need an array
	end

	nx = size(mat, 2);		ny = size(mat, 1);
	x, y, hdr, x_inc, y_inc = grdimg_hdr_xy(mat, 1, hdr, x, y)

	mem_layout = (size(mat,3) == 1) ? "TCBa" : "TCBa"		# Just to have something. Likely wrong for 3D
	d = KW(kw)
	if ((val = find_in_dict(d, [:layout :mem_layout])[1]) !== nothing)  mem_layout = string(val)  end

	I = GMTimage(proj4, wkt, 0, hdr[:], [x_inc, y_inc], 1, NaN, color_interp,
	             x,y,mat, colormap, n_colors, Array{UInt8,2}(undef,1,1), mem_layout, 0)
end

# ---------------------------------------------------------------------------------------------------
function mat2img(mat::Array{UInt16}; x=Vector{Float64}(), y=Vector{Float64}(), hdr=nothing, proj4::String="", wkt::String="", kw...)
	# Take an array of UInt16 and scale it down to UInt8. Input can be 2D or 3D.
	# If the kw variable 'stretch' is used, we stretch the intervals in 'stretch' to [0 255].
	# Use this option to stretch the image histogram.
	# If 'stretch' is a scalar, scale the values > 'stretch' to [0 255]
	# stretch = [v1 v2] scales all values >= v1 && <= v2 to [0 255]
	# stretch = [v1 v2 v3 v4 v5 v6] scales firts band >= v1 && <= v2 to [0 255], second >= v3 && <= v4, same for third
	# Use the keyword NOCONV to return GMTimage UInt16 type. I.e., no conversion to UInt8
	d = KW(kw)
	if ((val = find_in_dict(d, [:noconv])[1]) !== nothing)		# No conversion to UInt8 is wished
		return mat2img(mat, 1; x=x, y=y, hdr=hdr, proj4=proj4, wkt=wkt, d...)
	end
	img = Array{UInt8}(undef,size(mat));
	if ((vals = find_in_dict(d, [:histo_bounds :stretch], false)[1]) !== nothing)
		nz = 1
		isa(mat, Array{UInt16,3}) ? (ny, nx, nz) = size(mat) : (ny, nx) = size(mat)

		(vals == "auto" || vals == :auto || (isa(vals, Bool) && vals) || (isa(vals, Number) && vals == 1)) &&
			(vals = [find_histo_limits(mat)...])	# Out is a tuple, convert to vector
		len = length(vals)

		(len > 2*nz) && error("'stretch' has more elements then allowed by image dimensions")
		(len != 1 && len != 2 && len != 6) &&
			error("Bad 'stretch' argument. It must be a 1, 2 or 6 elements array and not $len")

		val = (len == 1) ? convert(UInt16, vals)::UInt16 : convert(Array{UInt16}, vals)::Array{UInt16}
		if (len == 1)
			sc = 255 / (65535 - val)
			@inbounds for k = 1:length(img)
				img[k] = (mat[k] < val) ? 0 : round(UInt8, (mat[k] - val) * sc)
			end
		elseif (len == 2)
			val = [parse(UInt16, @sprintf("%d", vals[1])) parse(UInt16, @sprintf("%d", vals[2]))]
			sc = 255 / (val[2] - val[1])
			@inbounds for k = 1:length(img)
				img[k] = (mat[k] < val[1]) ? 0 : ((mat[k] > val[2]) ? 255 : UInt8(round((mat[k]-val[1])*sc)))
			end
		else	# len = 6
			nxy = nx * ny
			v1 = [1 3 5];	v2 = [2 4 6]
			sc = [255 / (val[2] - val[1]), 255 / (val[4] - val[3]), 255 / (val[6] - val[5])]
			@inbounds for n = 1:nz, k = 1+(n-1)*nxy:n*nxy
				img[k] = (mat[k] < val[v1[n]]) ? 0 : ((mat[k] > val[v2[n]]) ? 255 : round(UInt8, (mat[k]-val[v1[n]])*sc[n]))
			end
		end
	else
		sc = 255/65535
		@inbounds @simd for k = 1:length(img)
			img[k] = round(UInt8, mat[k]*sc)
		end
	end
	mat2img(img; x=x, y=y, hdr=hdr, proj4=proj4, wkt=wkt, d...)
end

# ---------------------------------------------------------------------------------------------------
function mat2img(img::GMTimage; kw...)
	# Scale a UInt16 GMTimage to UInt8. Return a new object but with all old image parameters
	(!isa(img.image, Array{UInt16}))  && return img		# Nothing to do
	I = mat2img(img.image; kw...)
	I.proj4 = img.proj4;	I.wkt = img.wkt;	I.epsg = img.epsg
	I.range = img.range;	I.inc = img.inc;	I.registration = img.registration
	I.nodata = img.nodata;	I.color_interp = img.color_interp;
	I.x = img.x;	I.y = img.y;	I.colormap = img.colormap;
	I.n_colors = img.n_colors;		I.alpha = img.alpha;	I.layout = img.layout;
	return I
end

# ---------------------------------------------------------------------------------------------------
# This method creates a new GMTimage but retains all the header data from the IMG object
function mat2img(mat, I::GMTimage)
	range = deepcopy(I.range);	(size(mat,3) == 1) && (range[5:6] .= extrema(mat))
	GMTimage(I.proj4, I.wkt, I.epsg, range, deepcopy(I.inc), I.registration, I.nodata, I.color_interp, deepcopy(I.x), deepcopy(I.y), mat, deepcopy(I.colormap), I.n_colors, Array{UInt8,2}(undef,1,1), I.layout, I.pad)
end

# ---------------------------------------------------------------------------------------------------
"""
    I = image_alpha!(img::GMTimage; alpha_ind::Integer, alpha_vec::Vector{Integer}, alpha_band::UInt8)

Change the alpha transparency of the GMTimage object 'img'. If the image is indexed, one can either
change just the color index that will be made transparent by uing 'alpha_ind=n' or provide a vector
of transaparency values in the range [0 255]; This vector can be shorter than the orginal number of colors.
Use `alpha_band` to change, or add, the alpha of true color images (RGB).

    Example1: change to the third color in cmap to represent the new transparent color
        image_alpha!(img, alpha_ind=3)

    Example2: change to the first 6 colors in cmap by assigning them random values
        image_alpha!(img, alpha_vec=round.(Int32,rand(6).*255))
"""
function image_alpha!(img::GMTimage; alpha_ind=nothing, alpha_vec=nothing, alpha_band=nothing)
	# Change the alpha transparency of an image
	n_colors = img.n_colors
	if (n_colors > 100000)  n_colors = Int(floor(n_colors / 1000))  end
	if (alpha_ind !== nothing)			# Change the index of the alpha color
		(alpha_ind < 0 || alpha_ind > 255) && error("Alpha color index must be in the [0 255] interval")
		img.n_colors = n_colors * 1000 + Int32(alpha_ind)
	elseif (alpha_vec !== nothing)		# Replace/add the alpha column of the colormap matrix. Allow also shorter vectors
		@assert(isa(alpha_vec, Vector{<:Integer}))
		(length(alpha_vec) > n_colors) && error("Length of alpha vector is larger than the number of colors")
		n_col = div(length(img.colormap), n_colors)
		vec = convert.(Int32, alpha_vec)
		if (n_col == 4)  img.colormap[(end-length(vec)+1):end] = vec;
		else             img.colormap = [img.colormap; [vec[:]; round.(Int32, ones(n_colors - length(vec)) .* 255)]]
		end
		img.n_colors = n_colors * 1000
	elseif (alpha_band !== nothing)		# Replace the entire alpha band
		@assert(isa(alpha_band, Array{<:UInt8, 2}))
		ny1, nx1, = size(img.image)
		ny2, nx2  = size(alpha_band)
		(ny1 != ny2 || nx1 != nx2) && error("alpha channel has wrong dimensions")
		(size(img.image, 3) != 3) ? @warn("Adding alpha band is restricted to true color images (RGB)") :
		                            img.alpha = alpha_band
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    image_cpt!(img::GMTimage, cpt::GMTcpt, clear=false)
or
    image_cpt!(img::GMTimage, cpt::String, clear=false)

Add (or replace) a colormap to a GMTimage object from the colors in the cpt.
This should have effect only if IMG is indexed.
Use `image_cpt!(img, clear=true)` to remove a previously existent `colormap` field in IMG
"""
image_cpt!(img::GMTimage, cpt::String) = image_cpt!(img, gmtread(cpt))
function image_cpt!(img::GMTimage, cpt::GMTcpt)
	# Insert the cpt info in the img.colormap member
	n = 1
	colormap = fill(Int32(255), size(cpt.colormap,1) * 4)
	for k = 1:size(cpt.colormap,1)
		colormap[n:n+2] = round.(Int32, cpt.colormap[k,:] .* 255);	n += 4
	end
	img.colormap = colormap
	img.n_colors = size(cpt.colormap,1)
	return nothing
end
function image_cpt!(img::GMTimage; clear::Bool=true)
	if (clear)
		img.colormap, img.n_colors = fill(Int32(0), 3), 0
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    I = ind2rgb(I)

Convert an indexed image I to RGB. It uses the internal colormap to do the conversion.
"""
function ind2rgb(img::GMTimage)
	# ...
	(size(img.image, 3) >= 3) && return img 	# Image is already RGB(A)
	imgRGB = zeros(UInt8,size(img.image,1), size(img.image,2), 3)
	n = 1
	for k = 1:length(img.image)
		start_c = img.image[k] * 4
		for c = 1:3
			imgRGB[n] = img.colormap[start_c+c];	n += 1
		end
	end
	mat2img(imgRGB, x=img.x, y=img.y, proj4=img.proj4, wkt=img.wkt, mem_layout="BRPa")
end

# ---------------------------------------------------------------------------------------------------
"""
    G = mat2grid(mat; reg=nothing, x=[], y=[], hdr=nothing, proj4::String="", wkt::String="", tit::String="", rem::String="", cmd::String="")

Take a 2D `mat` array and a HDR 1x9 [xmin xmax ymin ymax zmin zmax reg xinc yinc] header descriptor
and return a grid GMTgrid type.
Alternatively to HDR, provide a pair of vectors, x & y, with the X and Y coordinates.
Optionaly, the HDR arg may be ommited and it will computed from `mat` alone, but then x=1:ncol, y=1:nrow
When HDR is not used, REG == nothing [default] means create a gridline registration grid and REG == 1,
or REG="pixel" a pixel registered grid.

Other methods of this function do:

    G = mat2grid([val]; hdr=hdr_vec, reg=nothing, proj4::String="", wkt::String="", tit::String="", rem::String="")

Create Float GMTgrid with size, coordinates and increment determined by the contents of the HDR var. This
array, which is now MANDATORY, has either the same meaning as above OR, alternatively, containng only
[xmin xmax ymin ymax xinc yinc]
VAL is the value that will be fill the matrix (default VAL = Float32(0)). To get a Float64 array use, for
example, VAL = 1.0 Ay other non Float64 will be converted to Float32

    Example: mat2grid(1, hdr=[0. 5 0 5 1 1])

    G = mat2grid(f::Function, x, y; reg=nothing, proj4::String="", wkt::String="", epsg::Int=0, tit::String="", rem::String="")

Where F is a function and X,Y the vectors coordinates defining it's domain. Creates a Float32 GMTgrid with
size determined by the sizes of the X & Y vectors.

    Example: f(x,y) = x^2 + y^2;  G = mat2grid(f, x = -2:0.05:2, y = -2:0.05:2)

    G = mat2grid(f::String, x=[], y=[])

Whre F is a pre-set function name. Currently available:
   - "ackley", "eggbox", "sombrero", "parabola" and "rosenbrock" 
X,Y are vectors coordinates defining the function's domain, but default values are provided for each function.
creates a Float32 GMTgrid.

    Example: G = mat2grid("sombrero")
"""
function mat2grid(val::Real=Float32(0); reg=nothing, hdr=nothing, proj4::String="", wkt::String="", epsg::Int=0, tit::String="", rem::String="")
	(hdr === nothing) && error("When creating grid type with no data the 'hdr' arg cannot be missing")
	(!isa(hdr, Array{Float64})) && (hdr = Float64.(hdr))
	(!isa(val, AbstractFloat)) && (val = Float32(val))		# We only want floats here
	if (length(hdr) == 6)
		hdr = [hdr[1], hdr[2], hdr[3], hdr[4], val, val, reg === nothing ? 0. : 1., hdr[5], hdr[6]]
	end
	mat2grid([nothing val]; reg=reg, hdr=hdr, proj4=proj4, wkt=wkt, epsg=epsg, tit=tit, rem=rem)
end

function mat2grid(mat::DenseMatrix, xx=Vector{Float64}(), yy=Vector{Float64}(); reg=nothing, x=Vector{Float64}(), y=Vector{Float64}(), hdr=nothing, proj4::String="", wkt::String="", epsg::Int=0, tit::String="", rem::String="", cmd::String="")
# Take a 2D array of floats and turn it into a GMTgrid

	!isa(mat[2], Real) && error("input matrix must be of Real numbers")
	reg_ = 0
	if (isa(reg, String) || isa(reg, Symbol))
		t = lowercase(string(reg))
		reg_ = (t != "pixel") ? 0 : 1
	elseif (isa(reg, Number))
		reg_ = (reg == 0) ? 0 : 1
	end
	if (isempty(x) && !isempty(xx))  x = xx  end
	if (isempty(y) && !isempty(yy))  y = yy  end
	x, y, hdr, x_inc, y_inc = grdimg_hdr_xy(mat, reg_, hdr, x, y)

	# Now we still must check if the method with no input MAT was called. In that case mat = [nothing val]
	# and the MAT must be finally computed.
	nx = size(mat, 2);		ny = size(mat, 1);
	if (ny == 1 && nx == 2 && mat[1] === nothing)
		fill_val = mat[2]
		mat = zeros(eltype(fill_val), length(y), length(x))
		(fill_val != 0) && fill!(mat, fill_val)
	end

	G = GMTgrid(proj4, wkt, epsg, hdr[1:6], [x_inc, y_inc], reg_, NaN, tit, rem, cmd, x, y, mat, "x", "y", "z", "BCB", 0)
end

# This method creates a new GMTgrid but retains all the header data from the G object
function mat2grid(mat::DenseMatrix, G::GMTgrid)
	Go = GMTgrid(G.proj4, G.wkt, G.epsg, deepcopy(G.range), deepcopy(G.inc), G.registration, G.nodata, G.title, G.remark, G.command, deepcopy(G.x), deepcopy(G.y), mat, G.x_unit, G.y_unit, G.z_unit, G.layout, G.pad)
	grd_min_max!(Go)		# Also take care of NaNs
	Go
end
function mat2grid(mat::DenseMatrix, I::GMTimage)
	Go = GMTgrid(I.proj4, I.wkt, I.epsg, I.range, I.inc, I.registration, I.nodata, "", "", "", I.x, I.y, mat, "", "", "", I.layout, I.pad)
	(length(Go.layout) == 4) && (Go.layout = Go.layout[1:3])	# No space for the a|A
	grd_min_max!(Go)		# Also take care of NaNs
	Go
end

function mat2grid(f::Function, x, y; reg=nothing, proj4::String="", wkt::String="", epsg::Int=0, tit::String="", rem::String="")
	z = Array{Float32,2}(undef,length(y),length(x))
	for i = 1:length(x)
		for j = 1:length(y)
			z[j,i] = f(x[i],y[j])
		end
	end
	mat2grid(z; reg=reg, x=x, y=y, proj4=proj4, wkt=wkt, epsg=epsg, tit=tit, rem=rem)
end

function mat2grid(f::String, x=Vector{Float64}(), y=Vector{Float64}())
	# Something is very wrong here. If I add named vars it annoyingly warns
	#	WARNING: Method definition f2(Any, Any) in module GMT at C:\Users\joaqu\.julia\dev\GMT\src\gmt_main.jl:1556 overwritten on the same line.
	if (startswith(f, "ack"))				# Ackley (inverted) https://en.wikipedia.org/wiki/Ackley_function
		f_ack(x,y) = 20 * exp(-0.2 * sqrt(0.5 * (x^2 + y^2))) + exp(0.5*(cos(2pi*x) + cos(2pi*y))) - 22.718281828459045
		if (isempty(x))  x = -5:0.05:5;	y = -5:0.05:5;  end
		mat2grid(f_ack, x, y)
	elseif (startswith(f, "egg"))
		f_egg(x, y) = (sin(x*10) + cos(y*10)) / 4
		if (isempty(x))  x = -1:0.01:1;	y = -1:0.01:1;  end
		mat2grid(f_egg, x, y)
	elseif (startswith(f, "para"))
		f_parab(x,y) = x^2 + y^2
		if (isempty(x))  x = -2:0.05:2;	y = -2:0.05:2;  end
		mat2grid(f_parab, x, y)
	elseif (startswith(f, "rosen"))			# rosenbrock
		f_rosen(x,y) = (1 - x)^2 + 100 * (y - x^2)^2
		if (isempty(x))  x = -2:0.05:2;	y = -1:0.05:3;  end
		mat2grid(f_rosen, x, y)
	elseif (startswith(f, "somb"))			# sombrero
		f_somb(x,y) = cos(sqrt(x^2 + y^2) * 2pi / 8) * exp(-sqrt(x^2 + y^2) / 10)
		if (isempty(x))  x = -15:0.2:15;	y = -15:0.2:15;  end
		mat2grid(f_somb, x, y)
	else
		@warn("Unknown surface '$f'. Just giving you a parabola.")
		mat2grid("para")
	end
end

# ---------------------------------------------------------------------------------------------------
function grdimg_hdr_xy(mat, reg, hdr, x=Vector{Float64}(), y=Vector{Float64}())
# Generate x,y coords array and compute/update header plus increments for grids/images
	nx = size(mat, 2);		ny = size(mat, 1);

	if (!isempty(x) && !isempty(y))		# But not tested if they are equi-spaced as they MUST be
		if ((length(x) != (nx+reg) || length(y) != (ny+reg)) && (length(x) != 2 || length(y) != 2))
			error("size of x,y vectors incompatible with 2D array size")
		end
		one_or_zero = reg == 0 ? 1 : 0
		if (length(x) != 2)				# Check that REGistration and coords are compatible
			(reg == 1 && round((x[end] - x[1]) / (x[2] - x[1])) != nx) &&		# Gave REG = pix but xx say grid
				(@warn("Gave REGistration = 'pixel' but X coordinates say it's gridline. Keeping later reg."); one_or_zero = 1)
		else
			x = collect(range(x[1], stop=x[2], length=nx+reg))
			y = collect(range(y[1], stop=y[2], length=ny+reg))
		end
		x_inc = (x[end] - x[1]) / (nx - one_or_zero)
		y_inc = (y[end] - y[1]) / (ny - one_or_zero)
		zmin, zmax = extrema_nan(mat)
		hdr = [x[1], x[end], y[1], y[end], zmin, zmax]
	elseif (hdr === nothing)
		zmin, zmax = extrema_nan(mat)
		if (reg == 0)  x = collect(1.0:nx);		y = collect(1.0:ny)
		else           x = collect(0.5:nx+0.5);	y = collect(0.5:ny+0.5)
		end
		hdr = [x[1], x[end], y[1], y[end], zmin, zmax]
		x_inc = 1.0;	y_inc = 1.0
	else
		(length(hdr) != 9) && error("The HDR array must have 9 elements")
		(!isa(hdr, Array{Float64})) && (hdr = Float64.(hdr))
		one_or_zero = (hdr[7] == 0) ? 1 : 0
		if (ny == 1 && nx == 2 && mat[1] === nothing)
			# In this case the 'mat' is a tricked matrix with [nothing val]. Compute nx,ny from header
			# The final matrix will be computed in the main mat2grid method
			nx = Int(round((hdr[2] - hdr[1]) / hdr[8] + one_or_zero))
			ny = Int(round((hdr[4] - hdr[3]) / hdr[9] + one_or_zero))
		end
		x = collect(range(hdr[1], stop=hdr[2], length=nx))
		y = collect(range(hdr[3], stop=hdr[4], length=ny))
		# Recompute the x|y_inc to make sure they are right.
		x_inc = (hdr[2] - hdr[1]) / (nx - one_or_zero)
		y_inc = (hdr[4] - hdr[3]) / (ny - one_or_zero)
	end
	if (isa(x, UnitRange))  x = collect(x)  end			# The AbstractArrays are much less forgivable
	if (isa(y, UnitRange))  y = collect(y)  end
	if (!isa(x, Vector{Float64}))  x = Float64.(x)  end
	if (!isa(y, Vector{Float64}))  y = Float64.(y)  end
	return x, y, hdr, x_inc, y_inc
end

# ---------------------------------------------------------------------------------------------------
# Convert the HDR vector from grid to pixel registration or vice-versa
grid2pix(GI; pix=true) = grid2pix([GI.range; GI.registration; GI.inc], pix=pix)
function grid2pix(hdr::Vector{Float64}; pix=true)
	((pix && hdr[7] == 1) || (!pix && hdr[7] == 0)) && return hdr 		# Nothing to do
	if (pix)  hdr[1] -= hdr[8]/2; hdr[2] += hdr[8]/2; hdr[3] -= hdr[9]/2; hdr[4] += hdr[9]/2;	hdr[7] = 1.
	else      hdr[1] += hdr[8]/2; hdr[2] -= hdr[8]/2; hdr[3] += hdr[9]/2; hdr[4] -= hdr[9]/2;	hdr[7] = 0.
	end
	return hdr
end

#= ---------------------------------------------------------------------------------------------------
function mksymbol(f::Function, cmd0::String="", arg1=nothing; kwargs...)
	# Make a fig and convert it to EPS so it can be used as a custom symbol is plot(3)
	d = KW(kwargs)
	t = ((val = find_in_dict(d, [:symbname :symb_name :symbol])[1]) !== nothing) ? string(val) : "GMTsymbol"
	d[:savefig] = t * ".eps"
	f(cmd0, arg1; d...)
end
mksymbol(f::Function, arg1; kw...) = mksymbol(f, "", arg1; kw...)
=#

# ---------------------------------------------------------------------------------------------------
"""
    make_zvals_vec(D, user_ids::Vector{String}, vals::Array{<:Real}, sub_head=0, upper=false, lower=false)

  - USER_IDS -> is a string vector with the ids (names in header) of the GMTdataset D 
  - VALS     -> is a vector with the the numbers to be used in plot -Z to color the polygons.
  - SUB_HEAD -> Position in header where field is to be found in the comma separated string.
Create a vector with ZVALS to use in plot where length(ZVALS) == length(D)
The elements of ZVALS are made up from the VALS but it can be larger if there are segments with
no headers. In that case it replicates the previously known value until it finds a new segment ID.

Returns a Vector{Float64} with the same length as the number of segments in D. The content is
made up after the contents of VALS but repeated such that each polygon of the same family, i.e.
with the same USER_ID, has the same value.
"""
function make_zvals_vec(D, user_ids::Vector{String}, vals::Array{<:Real}, sub_head::Int=0, case::Int=0)::Vector{Float64}

	n_user_ids = length(user_ids)
	@assert(n_user_ids == length(vals))
	data_ids, ind = get_segment_ids(D, case)
	(ind[1] != 1) && error("This function requires that first segment has a a header with an id")
	n_data_ids = length(data_ids)
	(n_user_ids > n_data_ids) &&
		@warn("Number of segment IDs requested is larger than segments with headers in data")

	if (sub_head != 0)
		[data_ids[k] = split(data_ids[k],',')[sub_head]  for k = 1:length(ind)]
	end
 
	n_seg = (isa(D, Array)) ? length(D) : 1
	zvals = fill(NaN, n_seg)
	n = 1
	for k = 1:n_data_ids
		for m = 1:n_user_ids
			if startswith(data_ids[k], user_ids[m])			# Find first occurence of user_ids[k] in a segment header
				last = (k < n_data_ids) ? ind[k+1]-1 : n_seg
				[zvals[j] = vals[m] for j = ind[k]:last]		# Repeat the last VAL for segments with no headers
				#println("k = ", k, " m = ",m, " pol_id = ", data_ids[k], ";  usr id = ", user_ids[m], " Racio = ", vals[m], " i1 = ", ind[k], " i2 = ",last)
				n = last + 1					# Prepare for next new VAL
				break
			end
		end
	end
	return zvals
end

# ---------------------------------------------------------------------------------------------------
function edit_segment_headers!(D, vals::Array, opt::String)
	# Add an option OPT to segment headers with a val from VALS. Number of elements of VALS must be
	# equal to the number of segments in D that have a header. If numel(val) == 1 must encapsulate it in []

	ids, ind = get_segment_ids(D)
	if (isa(D, Array))
		[D[ind[k]].header *= string(opt, vals[k])  for k = 1:length(ind)]
	else
		D.header *= string(opt, vals[1])
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    ids, ind = get_segment_ids(D, case=0)::Tuple{Vector{String}, Vector{Int}}

Where D is a GMTdataset of a vector of them, returns the segment ids (first text after the '>') and
the idices of those segments.
"""
function get_segment_ids(D, case::Int=0)::Tuple{Vector{String}, Vector{Int}}
	# Get segment ids (first text after the '>') and the idices of those segments
	# CASE -> If == 1 force return in LOWER case. If == 2 force upper case. Default (case = 0) dosen't touch
	if (isa(D, Array))  n = length(D);	d = Dict(k => D[k].header for k = 1:n)
	else                n = 1;			d = Dict(1 => D.header)
	end
	tf = Vector{Bool}(undef,n)					# pre-allocate
	[tf[k] = (d[k] !== "" && d[k][1] != ' ') ? true : false for k = 1:n];	# Mask of non-empty headers
	ind = 1:n
	ind = ind[tf]			# OK, now we have the indices of the segments with headers != ""
	ids = Vector{String}(undef,length(ind))		# pre-allocate
	if (case == 1)
		[ids[k] = lowercase(d[ind[k]]) for k = 1:length(ind)]	# indices of non-empty segments
	elseif (case == 2)
		[ids[k] = uppercase(d[ind[k]]) for k = 1:length(ind)]
	else
		[ids[k] = d[ind[k]] for k = 1:length(ind)]
	end
	return ids, ind
end
