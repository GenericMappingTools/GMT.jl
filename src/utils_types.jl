function text_record(data, text, hdr=Vector{String}())
	# Create a text record to send to pstext. DATA is the Mx2 coordinates array.
	# TEXT is a string or a cell array

	(isa(data, Vector)) && (data = data[:,:]) 		# Needs to be 2D
	#(!isa(data, Array{Float64})) && (data = Float64.(data))

	if (isa(text, String))
		_hdr = isempty(hdr) ? "" : hdr[1]
		T = GMTdataset(data, Float64[], Float64[], Dict{String, String}(), String[], [text], _hdr, String[], "", "", 0)
	elseif (isa(text, Vector{String}))
		if (text[1][1] == '>')			# Alternative (but risky) way of setting the header content
			T = GMTdataset(data, Float64[], Float64[], Dict{String, String}(), String[], text[2:end], text[1], String[], "", "", 0)
		else
			_hdr = isempty(hdr) ? "" : (isa(hdr, Vector{String}) ? hdr[1] : hdr)
			T = GMTdataset(data, Float64[], Float64[], Dict{String, String}(), String[], text, _hdr, String[], "", "", 0)
		end
	elseif (isa(text, Array{Array}) || isa(text, Array{Vector{String}}))
		nl_t = length(text);	nl_d = size(data,1)
		(nl_d > 0 && nl_d != nl_t) && error("Number of data points ($nl_d) is not equal to number of text strings ($nl_t).")
		T = Vector{GMTdataset}(undef,nl_t)
		for k = 1:nl_t
			T[k] = GMTdataset((nl_d == 0 ? fill(NaN, length(text[k]) ,2) : data[k]), Float64[], Float64[], Dict{String, String}(), String[], text[k], (isempty(hdr) ? "" : hdr[k]), Vector{String}(), "", "", 0)
		end
	else
		error("Wrong type ($(typeof(text))) for the 'text' argin")
	end
	return T
end
text_record(text::String, hdr::String="") = text_record(fill(NaN,1,2), text, (hdr == "") ? String[] : [hdr])
text_record(text::Vector{String}, hdr::Union{String,Vector{String}}=String[]) = text_record(fill(NaN,length(text),2), text, hdr)
#text_record(text::AbstractVector, hdr::Vector{String}=String[]) = text_record(Array{Float64,2}(undef,0,0), text, hdr)
text_record(text) = text_record(Array{Float64,2}(undef,0,0), text)

# ---------------------------------------------------------------------------------------------------
"""
    D = mat2ds(mat [,txt]; x=nothing, text=nothing, multi=false, geom=0, kwargs...)

Take a 2D `mat` array and convert it into a GMTdataset. `x` is an optional coordinates vector (must have the
same number of elements as rows in `mat`). Use `x=:ny` to generate a coords array 1:n_rows of `mat`.
  - `txt`:   Return a Text record which is a Dataset with data = Mx2 and text in third column. The ``text``
     can be an array with same size as ``mat`` rows or a string (will be reapeated n_rows times.) 
  - `x`:   An optional vector with the xx coordinates
  - `hdr`: optional String vector with either one or n_rows multisegment headers.
  - `color`: optional array of strings with color names/values. Its length can be smaller than n_rows, case in
     which colors will be cycled.
  - `linethick` or `lt`: for selecting different line thicknesses. Works like `color`, but should be 
     a vector of numbers, or just a single number that is then applied to all lines.
  - `fill`:  Optional string array with color names or array of "patterns".
  - `ls` or `linestyle`:  Line style. A string or an array of strings with ``length = size(mat,1)`` with line styles.
  - `lt` or `linethick`:  Line thickness.
  - `multi`: When number of columns in `mat` > 2, or == 2 and x != nothing, make an multisegment Dataset with
     first column and 2, first and 3, etc. Convenient when want to plot a matrix where each column is a line. 
  - `datatype`: Keep the original data type of `mat`. Default, converts to Float64.
  - `geom`: The data geometry. By default we set ``wkbUnknown`` but try to do some basic guess.
  - `proj` or `proj4`:  A proj4 string for dataset SRS.
  - `wkt`:  A WKT SRS.
  - `colnames`: Optional string vector with names for each column of `mat`.
"""
mat2ds(mat::GDtype) = mat		# Method to simplify life and let call mat2ds on a already GMTdataset
function mat2ds(mat, txt::Vector{String}=String[]; hdr=String[], geom=0, kwargs...)
	d = KW(kwargs)

	(!isempty(txt)) && return text_record(mat, txt,  hdr)
	((text = find_in_dict(d, [:text])[1]) !== nothing) && return text_record(mat, text, hdr)

	val = find_in_dict(d, [:multi :multicol])[1]
	multi = (val === nothing) ? false : ((val) ? true : false)	# Like this it will error if val is not Bool

	if ((x = find_in_dict(d, [:x])[1]) !== nothing)
		n_ds::Int = (multi) ? size(mat, 2) : 1
		xx::Vector{Float64} = (x == :ny || x == "ny") ? collect(1.0:size(mat, 1)) : x
		(length(xx) != size(mat, 1)) && error("Number of X coordinates and MAT number of rows are not equal")
	else
		n_ds = (ndims(mat) == 3) ? size(mat,3) : ((multi) ? size(mat, 2) - 1 : 1)
		xx = Vector{Float64}()
	end

	if (!isempty(hdr) && isa(hdr, String))	# Accept one only but expand to n_ds with the remaining as blanks
		_hdr::Vector{String} = Base.fill("", n_ds);	_hdr[1] = hdr
	elseif (!isempty(hdr) && length(hdr) != n_ds)
		error("The header vector can only have length = 1 or same number of MAT Y columns")
	else
		_hdr = vec(hdr)
	end

	if ((color = find_in_dict(d, [:color])[1]) !== nothing)
		_color::Vector{String} = isa(color, Array{String}) ? vec(color) : ["#0072BD", "#D95319", "#EDB120", "#7E2F8E", "#77AC30", "#4DBEEE", "#A2142F"]
	end
	_fill::Vector{String} = helper_ds_fill(d)

	# ---  Here we deal with line colors and line thickness.
	if ((val = find_in_dict(d, [:lt :linethick :linethickness])[1]) !== nothing)
		_lt::Vector{Float64} = vec(Float64.(val))
		_lts::Vector{String} = Vector{String}(undef, n_ds)
		n_thick::Integer = length(_lt)
		for k = 1:n_ds
			_lts[k] = " -W" * string(_lt[((k % n_thick) != 0) ? k % n_thick : n_thick])
		end
	else
		_lts = fill("", n_ds)
	end

	if (color !== nothing)
		n_colors::Int = length(_color)
		if (isempty(_hdr))
			_hdr = Vector{String}(undef, n_ds)
			for k = 1:n_ds  _hdr[k] = _lts[k] * string(",", _color[((k % n_colors) != 0) ? k % n_colors : n_colors])  end
		else
			for k = 1:n_ds  _hdr[k] *= _lts[k] * string(",", _color[((k % n_colors) != 0) ? k % n_colors : n_colors])  end
		end
	else						# Here we just overriding the GMT -W default that is too thin.
		if (isempty(_hdr))
			_hdr = Vector{String}(undef, n_ds)
			for k = 1:n_ds  _hdr[k]  = _lts[k]  end
		else
			for k = 1:n_ds  _hdr[k] *= _lts[k]  end
		end
	end
	# ----------------------------------------

	if ((ls = find_in_dict(d, [:ls :linestyle])[1]) !== nothing && ls != "")
		if (isa(ls, AbstractString) || isa(ls, Symbol))
			for k = 1:n_ds  _hdr[k] = string(_hdr[k], ',', ls)  end
		else
			for k = 1:n_ds  _hdr[k] = string(_hdr[k], ',', ls[k])  end
		end
	end

	if (!isempty(_fill))				# Paint the polygons (in case of)
		n_colors = length(_fill)
		if (isempty(_hdr))
			_hdr = Vector{String}(undef, n_ds)
			for k = 1:n_ds  _hdr[k]  = " -G" * _fill[((k % n_colors) != 0) ? k % n_colors : n_colors]  end
		else
			for k = 1:n_ds  _hdr[k] *= " -G" * _fill[((k % n_colors) != 0) ? k % n_colors : n_colors]  end
		end
	end

	prj::String = ((proj = find_in_dict(d, [:proj :proj4])[1]) !== nothing) ? proj : ""
	(prj == "geo" || prj == "geog") && (prj = prj4WGS84)
	(prj != "" && !startswith(prj, "+proj=")) && (prj = "+proj=" * prj)
	wkt::String = ((wk = find_in_dict(d, [:wkt])[1]) !== nothing) ? wk : ""
	(prj == "" && wkt != "") && (prj = wkt2proj(wkt))

	is_geog::Bool = false
	if (prj != "")
		is_geog = (contains(prj, "=longlat") || contains(prj, "=latlong")) ? true : false
	end
	coln::Vector{String} = ((val = find_in_dict(d, [:colnames])[1]) === nothing) ? String[] : val

	function fill_colnames(coln::Vector{String}, nc::Int, is_geog::Bool)	# Fill the column names vector
		if isempty(coln)
			(coln = (is_geog) ? ["Lon", "Lat"] : ["X", "Y"])
			(nc == 1) ? append!(coln, ["Z"]) : append!(coln, ["Z$i" for i=1:nc])
		end
		return coln
	end

	D::Vector{GMTdataset} = Vector{GMTdataset}(undef, n_ds)

	# By default convert to Doubles, except if instructed to NOT to do it.
	#(find_in_dict(d, [:datatype])[1] === nothing) && (eltype(mat) != Float64) && (mat = Float64.(mat))
	_geom::Int = Int((geom == 0 && (2 <= length(mat) <= 3)) ? Gdal.wkbPoint : (geom == 0 ? Gdal.wkbUnknown : geom))	# Guess geom
	(multi && _geom == 0 && size(mat,1) == 1) && (_geom = Int(Gdal.wkbPoint))	# One row with many columns and MULTI => Points
	if (isempty(xx))				# No coordinates transmitted
		if (ndims(mat) == 3)
			coln = fill_colnames(coln, size(mat,2)-2, is_geog)
			for k = 1:n_ds
				D[k] = GMTdataset(mat[:,:,k], Float64[], Float64[], Dict{String, String}(), coln, String[], (isempty(_hdr) ? "" : _hdr[k]), String[], prj, wkt, _geom)
			end
		elseif (!multi)
			coln = fill_colnames(coln, size(mat,2)-2, is_geog)
			D[1] = GMTdataset(mat, Float64[], Float64[], Dict{String, String}(), coln, String[], (isempty(_hdr) ? "" : _hdr[1]), String[], prj, wkt, _geom)
		else
			isempty(coln) && (coln = (is_geog) ? ["Lon", "Lat"] : ["X", "Y"])
			for k = 1:n_ds
				D[k] = GMTdataset(mat[:,[1,k+1]], Float64[], Float64[], Dict{String, String}(), coln, String[], (isempty(_hdr) ? "" : _hdr[k]), String[], prj, wkt, _geom)
			end
		end
	else
		if (!multi)
			coln = fill_colnames(coln, size(mat,2)-1, is_geog)
			D[1] = GMTdataset(hcat(xx,mat), Float64[], Float64[], Dict{String, String}(), coln, String[], (isempty(_hdr) ? "" : _hdr[1]), String[], prj, wkt, _geom)
		else
			isempty(coln) && (coln = (is_geog) ? ["Lon", "Lat"] : ["X", "Y"])
			for k = 1:n_ds
				D[k] = GMTdataset(hcat(xx,mat[:,k]), Float64[], Float64[], Dict{String, String}(), coln, String[], (isempty(_hdr) ? "" : _hdr[k]), String[], prj, wkt, _geom)
			end
		end
	end
	set_dsBB!(D)				# Compute and set the global BoundingBox for this dataset
	return (length(D) == 1 && !multi) ? D[1] : D		# Drop the damn Vector singletons
end

# ---------------------------------------------------------------------------------------------------
function set_dsBB!(D, all_bbs::Bool=true)
	# Compute and set the global and individual BoundingBox for a Vector{GMTdataset} + the trivial cases.
	# If ALL_BBS is false then assume individual BBs are already knwon.
	isempty(D) && return nothing

	if (all_bbs)
		if isa(D, GMTdataset)
			D.ds_bbox = D.bbox = collect(Float64, Iterators.flatten(extrema(D.data, dims=1)))
			return nothing
		else
			for k = 1:length(D)
				bb = extrema(D[k].data, dims=1)		# A N Tuple.
				D[k].bbox = collect(Float64, Iterators.flatten(bb))
			end
		end
	end

	(isa(D, GMTdataset)) && (D.ds_bbox = D.bbox;	return nothing)
	(length(D) == 1)     && (D[1].ds_bbox = D[1].bbox;	return nothing)
	isempty(D[1].bbox)   && return nothing
	bb = copy(D[1].bbox)
	for k = 2:length(D)
		for n = 1:2:length(bb)
			bb[n]   = min(D[k].bbox[n],   bb[n])
			bb[n+1] = max(D[k].bbox[n+1], bb[n+1])
		end
	end
	D[1].ds_bbox = bb
	return nothing
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
		n_colors::Int = Int(val)
	end

	n_ds = size(D.data, 1)
	if (!isempty(_fill))				# Paint the polygons (in case of)
		_hdr::Vector{String} = Vector{String}(undef, n_ds)
		for k = 1:n_ds
			_hdr[k] = " -G" * _fill[((k % n_colors) != 0) ? k % n_colors : n_colors]
		end
		(D.header != "") && (_hdr[1] = D.header * _hdr[1])	# Copy eventual contents of first header
	end

	Dm = Vector{GMTdataset}(undef, n_ds)
	for k = 1:n_ds
		Dm[k] = GMTdataset(D.data[k:k, :], Float64[], Float64[], Dict{String, String}(), String[], String[], (isempty(_fill) ? "" : _hdr[k]), String[], "", "", 0)
	end
	Dm[1].comment = D.comment;	Dm[1].proj4 = D.proj4;	Dm[1].wkt = D.wkt;	Dm[1].colnames = D.colnames
	(size(D.text) == n_ds) && [Dm.text[k] = D.text[k] for k = 1:n_ds]
	Dm
end

# ----------------------------------------------
function helper_ds_fill(d::Dict)::Vector{String}
	# Shared by ds2ds & mat2ds
	if ((fill_val = find_in_dict(d, [:fill :fillcolor])[1]) !== nothing)
		_fill::Vector{String} = (isa(fill_val, Array{String}) && !isempty(fill_val)) ? vec(fill_val) :
		                       ["#0072BD", "#D95319", "#EDB120", "#7E2F8E", "#77AC30", "#4DBEEE", "#A2142F", "0/255/0"]
		n_colors::Int = length(_fill)
		if ((alpha_val = find_in_dict(d, [:fillalpha])[1]) !== nothing)
			if (eltype(alpha_val) <: AbstractFloat && maximum(alpha_val) <= 1)  alpha_val = collect(alpha_val) .* 100  end
			_alpha::Vector{String} = Vector{String}(undef, n_colors)
			na::Int = min(length(alpha_val), n_colors)
			for k = 1:na  _alpha[k] = join(string('@',alpha_val[k]))  end
			if (na < n_colors)
				for k = na+1:n_colors  _alpha[k] = ""  end
			end
			for k = 1:n_colors  _fill[k] *= _alpha[k]  end	# And finaly apply the transparency
		end
	else
		_fill = Vector{String}()
	end
	return _fill
end

# ---------------------------------------------------------------------------------------------------
function color_gradient_line(D::Matrix{<:Real}; is3D::Bool=false, color_col::Int=3, first::Bool=true)
	# Reformat a Mx2 (or Mx3) matrix so that it can be used as vectors with no head/tail but varying
	# color determined by last column and using plot -Sv+s -W+cl
	(!is3D && size(D,2) < 2) && error("This function requires that the data matrix has at least 2 columns")
	(is3D && size(D,2)  < 3) && error("This function requires that the data matrix has at least 3 columns")
	(is3D && color_col == 3) && (color_col = 4)		# Change the default value column number
	dim_col = (is3D) ? 3 : 2		# Select the last coord column. 2nd for 2D and 3rd for is3D

	r = (first) ? (1:size(D,1)-1) : (2:size(D,1))		# Which rows to use to pick the 'value' column
	val = (size(D,2) == dim_col) ? collect(1.:size(D,1)-1) : D[r, color_col]
	[D[1:end-1, 1:dim_col] val D[2:end, 1:dim_col]]
end

function color_gradient_line(D::GMTdataset; is3D::Bool=false, color_col::Int=3, first::Bool=true)
	mat = color_gradient_line(D.data, is3D=is3D, color_col=color_col, first=first)
	mat2ds(mat, proj=D.proj4, wkt=D.wkt, geom=wkbLineString)
end

function color_gradient_line(Din::Vector{<:GMTdataset}; is3D::Bool=false, color_col::Int=3, first::Bool=true)
	D = Vector{GMTdataset}(undef, length(Din))
	for k = 1:length(Din)
		D[k] = color_gradient_line(Din[k], is3D=is3D, color_col=color_col, first=first)
	end
	D
end
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
function line2multiseg(M::Matrix{<:Real}; is3D::Bool=false, color::GMTcpt=GMTcpt(), auto_color::Bool=false, lt=Vector{Real}(), color_col::Int=0)
	# Take a 2D or 3D poly-line and break it into an array of DS, one for each line segment
	# AUTO_COLOR -> color from 1:size(M,1)
	(!isempty(color) && size(M,2) < 3) && error("For a varying color the input data must have at least 3 columns")
	n_ds = size(M,1)-1
	_hdr::Vector{String} = fill("", n_ds)
	first, use_row_number = true, false
	if (!isempty(lt))
		nth = length(lt)
		if (nth < size(M,1))
			if (nth == 2)  th = linspace(lt[1], lt[2], n_ds)		# If we have only 2 thicknesses.
			else           th::Vector{Float64} = vec(gmt("sample1d -T -o1", [collect(1:nth) lt], collect(linspace(1,nth,n_ds))).data)
			end
			for k = 1:n_ds  _hdr[k] = string(" -W", th[k])  end
		else
			for k = 1:n_ds  _hdr[k] = string(" -W", lt[k])  end
		end
		first = false
	end

	(color_col == 0) && (color_col = 3)		# Set the color column to default if it wasn't sent in.

	if (isempty(color) && auto_color)
		mima = (size(M,2) <= 3) ? (1., Float64(size(M,1))) : extrema(view(M, :, color_col))
		(size(M,2) <= 3) && (use_row_number = true; z4color = 1.:n_ds)
		color::GMTcpt = makecpt(@sprintf("-T%f/%f/65+n -Cturbo -Vq", mima[1]-eps(1e10), mima[2]+eps(1e10)))
	end

	if (!isempty(color))
		z_col = color_col
		rgb = [0.0, 0.0, 0.0];
		P::Ptr{GMT.GMT_PALETTE} = palette_init(G_API[1], color);		# A pointer to a GMT CPT
		for k = 1:n_ds
			z = (use_row_number) ? z4color[k] : M[k, z_col]
			gmt_get_rgb_from_z(G_API[1], P, z, rgb)
			t = @sprintf(",%.0f/%.0f/%.0f", rgb[1]*255, rgb[2]*255, rgb[3]*255)
			_hdr[k] = (first) ? " -W"*t : _hdr[k] * t
		end
	end

	Dm = Vector{GMTdataset}(undef, n_ds)
	geom = (is3D) ? Int(Gdal.wkbLineStringZ) : Int(Gdal.wkbLineString)
	for k = 1:n_ds
		Dm[k] = GMTdataset(M[k:k+1, :], Float64[], Float64[], Dict{String, String}(), String[], String[], _hdr[k], String[], "", "", geom)
	end
	Dm
end

function line2multiseg(D::GMTdataset; is3D::Bool=false, color::GMTcpt=GMTcpt(), auto_color::Bool=false, lt=Vector{Real}(), color_col::Int=0)
	Dm = line2multiseg(D.data, is3D=is3D, color=color, auto_color=auto_color, lt=lt, color_col=color_col)
	Dm[1].proj4, Dm[1].wkt, Dm[1].ds_bbox, Dm[1].colnames = D.proj4, D.wkt, D.ds_bbox, D.colnames
	Dm
end

function line2multiseg(D::Vector{<:GMTdataset}; is3D::Bool=false, color::GMTcpt=GMTcpt(), auto_color::Bool=false, lt=Vector{Real}(), color_col::Int=0)
	Dm = line2multiseg(D[1], is3D=is3D, color=color, auto_color=auto_color, lt=lt, color_col=color_col)
	Dm[1].proj4, Dm[1].wkt, Dm[1].colnames = D[1].proj4, D[1].wkt, D[1].colnames
	bb_min = bb_max = D[1].ds_bbox
	for k = 2:length(D)
		Dt = line2multiseg(D[k], is3D=is3D, color=color, auto_color=auto_color, lt=lt, color_col=color_col)
		append!(Dm, Dt)
		bb_max = max(bb_max, D[k].ds_bbox)		# To compute the final ds_bbox
		bb_min = min(bb_min, D[k].ds_bbox)
	end
	Dm[1].ds_bbox = [bb_min bb_max]'[:]
	Dm
end
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
"""
    I = mat2img(mat::Array{<:Unsigned}; x=[], y=[], hdr=nothing, proj4="", wkt="", cmap=nothing, kw...)

Take a 2D 'mat' array and a HDR 1x9 [xmin xmax ymin ymax zmin zmax reg xinc yinc] header descriptor
and return a GMTimage type.
Alternatively to HDR, provide a pair of vectors, x & y, with the X and Y coordinates.
Optionaly, the HDR arg may be ommited and it will computed from 'mat' alone, but then x=1:ncol, y=1:nrow
When 'mat' is a 3D UInt16 array we automatically compute a UInt8 RGB image. In that case 'cmap' is ignored.
But if no conversion is wanted use option `noconv=true`

    I = mat2img(mat::Array{UInt16}; x=[], y=[], hdr=nothing, proj4::String="", wkt::String="", kw...)

Take a `mat` array of UInt16 and scale it down to UInt8. Input can be 2D or 3D.
If the kw variable `stretch` is used, we stretch the intervals in `stretch` to [0 255].
Use this option to stretch the image histogram.
If `stretch` is a scalar, scale the values > `stretch` to [0 255]
  - stretch = [v1 v2] scales all values >= v1 && <= v2 to [0 255]
  - stretch = [v1 v2 v3 v4 v5 v6] scales firts band >= v1 && <= v2 to [0 255], second >= v3 && <= v4, same for third
  - stretch = :auto | "auto" | true | 1 will do an automatic stretching from values obtained from histogram thresholds

The `kw...` kwargs search for [:layout :mem_layout], [:names] and [:metadata]
"""
function mat2img(mat::AbstractArray{<:Unsigned}, dumb::Int=0; x=Vector{Float64}(), y=Vector{Float64}(), v=Vector{Float64}(), hdr=nothing, proj4::String="", wkt::String="", cmap=nothing, is_transposed::Bool=false, kw...)
	# Take a 2D array of uint8 and turn it into a GMTimage.
	# Note: if HDR is empty we guess the registration from the sizes of MAT & X,Y
	color_interp = "";		n_colors = 0;
	if (cmap !== nothing)
		have_alpha = !all(cmap.alpha .== 0.0)
		nc = have_alpha ? 4 : 3
		colormap = zeros(Int32, 256 * nc)
		n_colors = 256;			# Because for GDAL we always send 256 even if they are not all filled
		@inbounds for n = 1:3	# Write 'colormap' row-wise
			@inbounds for m = 1:size(cmap.colormap, 1)
				colormap[m + (n-1)*n_colors] = round(Int32, cmap.colormap[m,n] * 255);
			end
		end
		if (have_alpha)						# Have alpha color(s)
			for m = 1:size(cmap.colormap, 1)
				colormap[m + 3*n_colors] = round(Int32, cmap.colormap[m,4] * 255)
			end
			n_colors *= 1000				# Flag that we have alpha colors in an indexed image
		end
	else
		(size(mat,3) == 1) && (color_interp = "Gray")
		if (hdr !== nothing && (hdr[5] == 0 && hdr[6] == 1))	# A mask. Let's create a colormap for it
			colormap = zeros(Int32, 256 * 3)
			n_colors = 256;					# Because for GDAL we always send 256 even if they are not all filled
			colormap[2] = colormap[258] = colormap[514] = 255
		else
			colormap = zeros(Int32,3)		# Because we need an array
		end
	end

	nx = size(mat, 2);		ny = size(mat, 1);
	reg = (hdr !== nothing) ? Int(hdr[7]) : (nx == length(x) && ny == length(y)) ? 0 : 1
	x, y, hdr, x_inc, y_inc = grdimg_hdr_xy(mat, reg, hdr, x, y, is_transposed)

	mem_layout = (size(mat,3) == 1) ? "TCBa" : "TCBa"		# Just to have something. Likely wrong for 3D
	d = KW(kw)
	((val = find_in_dict(d, [:layout :mem_layout])[1]) !== nothing) && (mem_layout = string(val))
	_names = ((val = find_in_dict(d, [:names])[1]) !== nothing) ? val : String[]
	_meta  = ((val = find_in_dict(d, [:metadata])[1]) !== nothing) ? val : String[]

	I = GMTimage(proj4, wkt, 0, hdr[1:6], [x_inc, y_inc], reg, zero(eltype(mat)), color_interp, _meta, _names,
	             x,y,v,mat, colormap, n_colors, Array{UInt8,2}(undef,1,1), mem_layout, 0)
end

# ---------------------------------------------------------------------------------------------------
function mat2img(mat::AbstractArray{UInt16}; x=Vector{Float64}(), y=Vector{Float64}(), v=Vector{Float64}(), hdr=nothing, proj4::String="", wkt::String="", img8=Matrix{UInt8}(undef,0,0), kw...)
	# Take an array of UInt16 and scale it down to UInt8. Input can be 2D or 3D.
	# If the kw variable 'stretch' is used, we stretch the intervals in 'stretch' to [0 255].
	# Use this option to stretch the image histogram.
	# If 'stretch' is a scalar, scale the values > 'stretch' to [0 255]
	# stretch = [v1 v2] scales all values >= v1 && <= v2 to [0 255]
	# stretch = [v1 v2 v3 v4 v5 v6] scales firts band >= v1 && <= v2 to [0 255], second >= v3 && <= v4, same for third
	# If the img8 argument is used, it should contain a pre-allocated UInt8 array with the exact same size as MAT.
	# The 'scale_only' kw option makes it return just the scaled array an no GMTimage creation (useful when img8 is a view).
	# Use the keyword NOCONV to return GMTimage UInt16 type. I.e., no conversion to UInt8

	d = KW(kw)
	if ((val = find_in_dict(d, [:noconv])[1]) !== nothing)		# No conversion to UInt8 is wished
		return mat2img(mat, 1; x=x, y=y, v=v, hdr=hdr, proj4=proj4, wkt=wkt, d...)
	end
	img = isempty(img8) ? Array{UInt8}(undef, size(mat)) : img8
	(size(img) != size(mat)) && error("Incoming matrix and image holder have different sizes")
	if ((vals = find_in_dict(d, [:histo_bounds :stretch], false)[1]) !== nothing)
		nz = 1
		isa(mat, Array{UInt16,3}) ? (ny, nx, nz) = size(mat) : (ny, nx) = size(mat)

		(vals == "auto" || vals == :auto || (isa(vals, Bool) && vals) || (isa(vals, Real) && vals == 1)) &&
			(vals = [find_histo_limits(mat)...])	# Out is a tuple, convert to vector
		len = length(vals)

		(len > 2*nz) && error("'stretch' has more elements then allowed by image dimensions")
		(len != 1 && len != 2 && len != 6) &&
			error("Bad 'stretch' argument. It must be a 1, 2 or 6 elements array and not $len")

		val = (len == 1) ? convert(UInt16, vals)::UInt16 : convert(Array{UInt16}, vals)::Array{UInt16}
		if (len == 1)
			sc = 255 / (65535 - val)
			@inbounds @simd for k = 1:length(img)
				img[k] = (mat[k] < val) ? 0 : round(UInt8, (mat[k] - val) * sc)
			end
		elseif (len == 2)
			val = [parse(UInt16, @sprintf("%d", vals[1])) parse(UInt16, @sprintf("%d", vals[2]))]
			sc = 255 / (val[2] - val[1])
			@inbounds @simd for k = 1:length(img)
				img[k] = (mat[k] < val[1]) ? 0 : ((mat[k] > val[2]) ? 255 : round(UInt8, (mat[k]-val[1])*sc))
			end
		else	# len = 6
			nxy = nx * ny
			v1 = [1 3 5];	v2 = [2 4 6]
			sc = [255 / (val[2] - val[1]), 255 / (val[4] - val[3]), 255 / (val[6] - val[5])]
			@inbounds @simd for n = 1:nz
				@inbounds @simd for k = 1+(n-1)*nxy:n*nxy
					img[k] = (mat[k] < val[v1[n]]) ? 0 : ((mat[k] > val[v2[n]]) ? 255 : round(UInt8, (mat[k]-val[v1[n]])*sc[n]))
				end
			end
		end
	else
		sc = 255/65535
		@inbounds @simd for k = 1:length(img)
			img[k] = round(UInt8, mat[k]*sc)
		end
	end
	(haskey(d, :scale_only)) && return img			# Only the scaled array is needed. Alows it to be a view
	mat2img(img; x=x, y=y, v=v, hdr=hdr, proj4=proj4, wkt=wkt, d...)
end

# ---------------------------------------------------------------------------------------------------
function mat2img(img::GMTimage; kw...)
	# Scale a UInt16 GMTimage to UInt8. Return a new object but with all old image parameters
	(!isa(img.image, Array{UInt16}))  && return img		# Nothing to do
	I = mat2img(img.image; kw...)
	I.proj4 = img.proj4;	I.wkt = img.wkt;	I.epsg = img.epsg
	I.range = img.range;	I.inc = img.inc;	I.registration = img.registration
	I.nodata = img.nodata;	I.color_interp = img.color_interp;
	I.names = img.names;	I.metadata = img.metadata
	I.x = img.x;	I.y = img.y;	I.colormap = img.colormap;
	I.n_colors = img.n_colors;		I.alpha = img.alpha;	I.layout = img.layout;
	return I
end

# ---------------------------------------------------------------------------------------------------
# This method creates a new GMTimage but retains all the header data from the IMG object
function mat2img(mat, I::GMTimage; names::Vector{String}=String[], metadata::Vector{String}=String[])
	range = copy(I.range);	(size(mat,3) == 1) && (range[5:6] .= extrema(mat))
	GMTimage(I.proj4, I.wkt, I.epsg, range, copy(I.inc), I.registration, I.nodata, I.color_interp, metadata, names, copy(I.x), copy(I.y), zeros(size(mat,3)), mat, copy(I.colormap), I.n_colors, Array{UInt8,2}(undef,1,1), I.layout, 0)
end
function mat2img(mat, G::GMTgrid; names::Vector{String}=String[], metadata::Vector{String}=String[])
	range = copy(G.range);	range[5:6] .= (size(mat,3) == 1) ? extrema(mat) : [0., 255]
	GMTimage(G.proj4, G.wkt, G.epsg, range, copy(G.inc), G.registration, zero(eltype(mat)), "Gray", metadata, names, copy(G.x), copy(G.y), zeros(size(mat,3)), mat, zeros(Int32,3), 0, Array{UInt8,2}(undef,1,1), G.layout*"a", 0)
end

# ---------------------------------------------------------------------------------------------------
"""
    slicecube(I::GMTimage, layer::Int)

Take a slice of a multylayer GMTimage. Return the result still as a GMTimage. `layer` is the slice number.

### Example
Get the fourth layer of the multi-layered 'I' GMTimage object 

```
I = slicecube(I, 4)
```
"""
function slicecube(I::GMTimage, layer::Int)
	(layer < 1 || layer > size(I,3)) && error("Layer number ($layer) is out of bounds of image size ($size(I,3))")
	(size(I,3) == 1) && return I		# There is nothing to slice here, but save the user fro the due deserved insult.
	mat = I.image[:,:,layer]
	range = copy(I.range);	range[5:6] .= extrema(mat)
	names = (!isempty(I.names)) ? [I.names[layer]] : I.names
	GMTimage(I.proj4, I.wkt, I.epsg, range, copy(I.inc), I.registration, I.nodata, "Gray", I.metadata, names, copy(I.x), copy(I.y), [0.], mat, zeros(Int32,3), 0, Array{UInt8,2}(undef,1,1), I.layout, I.pad)
end

function slicecube(G::GMTgrid, slice::Int; axis="z")
	# Method that slices grid cubes. SLICE is the row|col|layer number. AXIS picks the axis to be sliced
	(ndims(G) < 3 || size(G,3) < 2) && error("This is not a cube grid.")
	_axis = lowercase(string(axis))

	dim = (_axis == "z") ? 3 : (_axis == "y" ? 1 : 2)		# First try to pick which dimension to slice
	if (G.layout[2] == 'R' && dim < 3)  dim = (dim == 1) ? 2 : 1  end	# For RowMajor swap dim from 1 to 2
	(slice > size(G,dim)) && error("Slice number ($slice) is larger than grid size ($size(G,$dim))")

	if (_axis == "z")
		G_ = mat2grid(G[:,:,slice], G.x, G.y, [G.v[slice]], reg=G.registration, is_transposed=(G.layout[2] == 'R'))
	elseif (_axis == "y")
		if (G.layout[2] == 'C')  G_ = mat2grid(G[slice,:,:], G.x, G.v, reg=G.registration)
		else                     G_ = mat2grid(G[:,slice,:], G.x, G.v, reg=G.registration, is_transposed=true)
		end
		G_.v = G_.y;	G_.y = [G.y[slice]]		# Shift coords vectors since mat2grid doesn't know how-to.
	else
		if (G.layout[2] == 'C')  G_ = mat2grid(G[:,slice,:], G.y, G.v, reg=G.registration)
		else                     G_ = mat2grid(G[slice,:,:], G.y, G.v, reg=G.registration, is_transposed=true)
		end
		G_.v = G_.y;	G_.y = G_.x;	G_.x = [G.x[slice]]	
	end
	G_.layout = G.layout
	return G_
end

function slicecube(G::GMTgrid, slice::AbstractFloat; axis="z")
	# Method that slices grid cubes. SLICE is the x|y|z coordinate where to slice. AXIS picks the axis to be sliced
	(ndims(G) < 3 || size(G,3) < 2) && error("This is not a cube grid.")
	_axis = lowercase(string(axis))

	which_coord_vec = (_axis == "z") ? G.v : (_axis == "y" ? G.y : G.x)
	x = interp_vec(which_coord_vec, slice)
	layer = trunc(Int, x)
	frac = x - layer
	nxy = size(G,1)*size(G,2)
	if (_axis == "z")
		mat = [G[k] + (G[k+nxy] - G[k]) * frac for k = (layer-1)*nxy+1 : layer*nxy]
		G_ = mat2grid(reshape(mat,size(G,1),size(G,2)), G.x, G.y, [Float64(slice)], reg=G.registration, is_transposed=(G.layout[2] == 'R'))
	elseif (_axis == "y")
		if (G.layout[2] == 'C')  mat = G[layer,:,:] .+ (G[layer+1,:,:] .- G[layer,:,:]) .* frac
		else                     mat = G[:,layer,:] .+ (G[:,layer+1,:] .- G[:,layer,:]) .* frac		# from GDAL
		end
		G_ = mat2grid(mat, G.x, G.v, reg=G.registration, is_transposed=(G.layout[2] == 'R'))
		G_.v = G_.y;	G_.y = [Float64(slice)]		# Shift coords vectors since mat2grid doesn't know how-to.
	else
		if (G.layout[2] == 'C')  mat = G[:,layer,:] .+ (G[:,layer+1,:] .- G[:,layer,:]) .* frac
		else                     mat = G[layer,:,:] .+ (G[layer+1,:,:] .- G[layer,:,:]) .* frac		# from GDAL
		end
		G_ = mat2grid(mat, G.y, G.v, reg=G.registration, is_transposed=(G.layout[2] == 'R'))
		G_.v = G_.y;	G_.y = G_.x;	G_.x = [Float64(slice)]	
	end
	G_.layout = G.layout
	return G_
end

# ---------------------------------------------------------------------------------------------------
"""
    stackgrids(names::Vector{String}, v=nothing; zcoord=nothing, zdim_name="time", z_unit="", save="", mirone=false)

Stack a bunch of single grids in a multiband cube like file.

- `names`: A string vector with the names of the grids to stack
- `v`: A vector with the vertical coordinates. If not provided one with 1:length(names) will be generated.
  - If `v` is a TimeType use the `z_unit` keyword to select what to store in file (case insensitive).
    - `decimalyear` or `yeardecimal` converts the DateTime to decimal years (Floa64)
	- `milliseconds` (or just `mil`) will store the DateTime as milliseconds since 0000-01-01T00:00:00 (Float64)
	- `seconds` stores the DateTime as seconds since 0000-01-01T00:00:00 (Float64)
	- `unix` stores the DateTime as seconds since 1970-01-01T00:00:00 (Float64)
	- `rata` stores the DateTime as days since 0000-12-31T00:00:00 (Float64)
	- `Date` or `DateTime` stores as a string representation of a DateTime.
- `zdim_name`: The name of the vertical axes (default is "time")
- `zcoord`: Keyword same as `v` (may use one or the other).
- `save`: The name of the file to be created.
- `mirone`: Does not create a cube file but instead a file named "automatic_list.txt" (or whaterver `save=xxx`)
   to be used in the Mirone `Empilhador` tool.
"""
function stackgrids(names::Vector{String}, v=nothing; zcoord=nothing, zdim_name::String="time", z_unit::String="",
                    save::String="", mirone::Bool=false)
	(v === nothing && zcoord !== nothing) && (v = zcoord)	# Accept both positional and named var for vertical coordinates

	if (isa(v, Vector{<:TimeType}))
		_z_unit = lowercase(z_unit)
		(mirone && z_unit == "") && (_z_unit = "decimalyear")		# For Mirone the default is DecimalYear
		if (_z_unit == "decimalyear" || _z_unit == "yeardecimal")
			v = GMT.yeardecimal.(v);				z_unit = "Decimal year"
		elseif (startswith(_z_unit, "mil"))
			v = Dates.datetime2epochms.(v);	z_unit = "Milliseconds since 0000-01-01T00:00:00"
		elseif (_z_unit == "seconds")
			v = Dates.datetime2epochms.(v) / 1000.;	z_unit = "Seconds since 0000-01-01T00:00:00"
		elseif (_z_unit == "" || _z_unit == "unix")					# Make it default for all and now
			v = Dates.datetime2unix.(v);			z_unit = "Seconds since 1970-01-01T00:00:00"
		elseif (_z_unit == "rata")
			v = Dates.datetime2rata.(v);			z_unit = "Days since 0000-12-31T00:00:00"
		elseif (_z_unit == "date" || _zunit == "datetime")			# Crashes Mirone
			v = string.(v);							z_unit = "ISO Date Time"
		end
	end

	_v = isa(v, Int64) ? Float64.(v) : ((v === nothing) ? Vector{Float64}() : v)	# Int64 Crashes Mirone

	if (mirone)
		(save == "") && (save = "automatic_list.txt")
		fid = open(save, "w")
		if isempty(_v)
			[write(fid, name, "\n") for name in names]
		else
			[write(fid, names[k], "\t", string(_v[k]), "\n") for k = 1:length(names)]
		end
		close(fid)
		return nothing
	end

	G = gmtread(names[1], grid=true)	# reading with GDAL f screws sometimes with the "is not a Latitude/Y dimension."
	x, y, range, inc = G.x, G.y, G.range, G.inc		# So read first with GMT anf keep only the coords info.
	G = gdaltranslate(names[1])
	mat = Array{eltype(G)}(undef, size(G,1), size(G,2), length(names))
	mat[:,:,1] = G.z
	for k = 2:length(names)
		G = gdaltranslate(names[k])
		mat[:,:,k] = G.z
	end
	cube = mat2grid(mat, G)
	cube.x = x;		cube.y = y;		cube.range = range;		cube.inc = inc
	cube.z_unit = z_unit
	(isempty(_v) || eltype(_v) == String) ? append!(cube.range, [0., 1.]) : append!(cube.range, [_v[1], _v[end]])
	cube.names = names;		cube.v = _v
	(save != "") && gdalwrite(cube, save, _v, dim_name=zdim_name)
	return (save != "") ? nothing : cube
end

# ---------------------------------------------------------------------------------------------------
"""
    I = image_alpha!(img::GMTimage; alpha_ind::Integer, alpha_vec::Vector{Integer}, alpha_band::UInt8)

Change the alpha transparency of the GMTimage object `img`. If the image is indexed, one can either
change just the color index that will be made transparent by uing `alpha_ind=n` or provide a vector
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
		@assert(eltype(alpha_band) == UInt8)
		ny1, nx1, = size(img.image)
		ny2, nx2  = size(alpha_band)
		(ny1 != ny2 || nx1 != nx2) && error("alpha channel has wrong dimensions")
		(size(img.image, 3) != 3) ? @warn("Adding alpha band is restricted to true color images (RGB)") :
		                            img.alpha = (isa(alpha_band,GMTimage)) ? alpha_band.image : alpha_band
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
	if (img.n_colors == 0)				# If no cmap just replicate the first layer.
		imgRGB = repeat(img.image, 1, 1, 3)
	else
		imgRGB = zeros(UInt8,size(img.image,1), size(img.image,2), 3)
		n = 1
		@inbounds for k = 1:length(img.image)
			start_c = img.image[k] * 4
			for c = 1:3
				imgRGB[n] = img.colormap[start_c+c];	n += 1
			end
		end
	end
	mat2img(imgRGB, x=img.x, y=img.y, proj4=img.proj4, wkt=img.wkt, mem_layout=img.layout)
end

# ---------------------------------------------------------------------------------------------------
"""
    G = mat2grid(mat; reg=nothing, x=[], y=[], v=[], hdr=nothing, proj4::String="", wkt::String="", tit::String="",
                 rem::String="", cmd::String="", names::Vector{String}=String[], scale::Float32=1f0, offset::Float32=0f0)

Take a 2/3D `mat` array and a HDR 1x9 [xmin xmax ymin ymax zmin zmax reg xinc yinc] header descriptor and 
return a grid GMTgrid type. Alternatively to HDR, provide a pair of vectors, `x` & `y`, with the X and Y coordinates.
Optionaly add a `v` vector with vertical coordinates if `mat` is a 3D array and one wants to create a ``cube``.
Optionaly, the HDR arg may be ommited and it will computed from `mat` alone, but then x=1:ncol, y=1:nrow
When HDR is not used, REG == nothing [default] means create a gridline registration grid and REG == 1,
or REG="pixel" a pixel registered grid.

For 3D arrays the `names` option is used to give a description for each layer (also saved to file when using a GDAL function).

The `scale` and `offset` options are used when `mat` is an Integer type and we want to save the grid with an scale/offset.  

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
function mat2grid(val::Real=Float32(0); reg=nothing, hdr=nothing, proj4::String="", wkt::String="", epsg::Int=0,
	tit::String="", rem::String="", names::Vector{String}=String[])

	(hdr === nothing) && error("When creating grid type with no data the 'hdr' arg cannot be missing")
	(!isa(hdr, Array{Float64})) && (hdr = Float64.(hdr))
	(!isa(val, AbstractFloat)) && (val = Float32(val))		# We only want floats here
	if (length(hdr) == 6)
		hdr = [hdr[1], hdr[2], hdr[3], hdr[4], val, val, reg === nothing ? 0. : 1., hdr[5], hdr[6]]
	end
	mat2grid([nothing val]; reg=reg, hdr=hdr, proj4=proj4, wkt=wkt, epsg=epsg, tit=tit, rem=rem, cmd="", names=names)
end

# This is the way I found to find if a matrix is transposed. There must be better ways but couldn't find them.
istransposed(mat) = !isempty(fields(mat)) && (fields(mat)[1] == :parent)

function mat2grid(mat, xx=Vector{Float64}(), yy=Vector{Float64}(), zz=Vector{Float64}(); reg=nothing,
	x=Vector{Float64}(), y=Vector{Float64}(), v=Vector{Float64}(), hdr=nothing, proj4::String="", wkt::String="",
	epsg::Int=0, tit::String="", rem::String="", cmd::String="", names::Vector{String}=String[], scale::Float32=1f0,
	offset::Float32=0f0, is_transposed::Bool=false)
	# Take a 2/3D array and turn it into a GMTgrid

	!isa(mat[2], Real) && error("input matrix must be of Real numbers")
	reg_ = 0
	if (isa(reg, String) || isa(reg, Symbol))
		t = lowercase(string(reg))
		reg_ = (t != "pixel") ? 0 : 1
	elseif (isa(reg, Real))
		reg_ = (reg == 0) ? 0 : 1
	end
	if (isempty(x) && !isempty(xx))  x = vec(xx)  end
	if (isempty(y) && !isempty(yy))  y = vec(yy)  end
	if (isempty(v) && !isempty(zz))  v = vec(zz)  end
	x, y, hdr, x_inc, y_inc = grdimg_hdr_xy(mat, reg_, hdr, x, y, is_transposed)

	# Now we still must check if the method with no input MAT was called. In that case mat = [nothing val]
	# and the MAT must be finally computed.
	nx = size(mat, 2);		ny = size(mat, 1);
	if (ny == 1 && nx == 2 && mat[1] === nothing)
		fill_val = mat[2]
		mat = zeros(eltype(fill_val), length(y), length(x))
		(fill_val != 0) && fill!(mat, fill_val)
	end

	isT = istransposed(mat)
	if (ndims(mat) == 2)
		inc, range = [x_inc, y_inc], hdr[1:6]
	else
		if (isempty(v))  inc, range = [x_inc, y_inc, 1.], [vec(hdr[1:6]); [1., size(mat,3)]]
		else             inc, range = [x_inc, y_inc, v[2] - v[1]], [vec(hdr[1:6]); [v[1], v[end]]]
		end
	end
	GMTgrid(proj4, wkt, epsg, range, inc, reg_, NaN, tit, rem, cmd, names, vec(x), vec(y), vec(v), isT ? copy(mat) : mat, "x", "y", "v", "z", "BCB", scale, offset, 0)
end

# This method creates a new GMTgrid but retains all the header data from the G object
function mat2grid(mat, G::GMTgrid)
	isT = istransposed(mat)
	Go = GMTgrid(G.proj4, G.wkt, G.epsg, deepcopy(G.range), deepcopy(G.inc), G.registration, G.nodata, G.title, G.remark, G.command, String[], deepcopy(G.x), deepcopy(G.y), [0.], isT ? copy(mat) : mat, G.x_unit, G.y_unit, G.v_unit, G.z_unit, G.layout, 1f0, 0f0, G.pad)
	grd_min_max!(Go)		# Also take care of NaNs
	Go
end
function mat2grid(mat, I::GMTimage)
	isT = istransposed(mat)
	Go = GMTgrid(I.proj4, I.wkt, I.epsg, I.range, I.inc, I.registration, NaN, "", "", "", String[], I.x, I.y, [0.], isT ? copy(mat) : mat, "", "", "", "", I.layout, 1f0, 0f0, I.pad)
	(length(Go.layout) == 4) && (Go.layout = Go.layout[1:3])	# No space for the a|A
	grd_min_max!(Go)		# Also take care of NaNs
	Go
end

function mat2grid(f::Function, xx=Vector{Float64}(), yy=Vector{Float64}(); reg=nothing, x=Vector{Float64}(), y=Vector{Float64}(), proj4::String="", wkt::String="", epsg::Int=0, tit::String="", rem::String="")
	(isempty(x) && !isempty(xx)) && (x = xx)
	(isempty(y) && !isempty(yy)) && (y = yy)
	z = Array{Float32,2}(undef,length(y),length(x))
	for i = 1:length(x)
		for j = 1:length(y)
			z[j,i] = f(x[i],y[j])
		end
	end
	mat2grid(z; reg=reg, x=x, y=y, proj4=proj4, wkt=wkt, epsg=epsg, tit=tit, rem=rem)
end

function mat2grid(f::String, xx=Vector{Float64}(), yy=Vector{Float64}(); x=Vector{Float64}(), y=Vector{Float64}())
	# Something is very wrong here. If I add named vars it annoyingly warns
	# WARNING: Method definition f2(Any, Any) in module GMT at C:\Users\joaqu\.julia\dev\GMT\src\gmt_main.jl:1556 overwritten on the same line.
	(isempty(x) && !isempty(xx)) && (x = xx)
	(isempty(y) && !isempty(yy)) && (y = yy)
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
function grdimg_hdr_xy(mat, reg, hdr, x=Vector{Float64}(), y=Vector{Float64}(), is_transposed=false)
# Generate x,y coords array and compute/update header plus increments for grids/images
# Arrays coming from GDAL are often scanline so they are transposed. In that case is_transposed should be true
	row_dim, col_dim = (is_transposed) ? (2,1) : (1,2) 
	nx = size(mat, col_dim);		ny = size(mat, row_dim);

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
		hdr = Float64.([x[1], x[end], y[1], y[end], zmin, zmax])
	elseif (hdr === nothing)
		zmin, zmax = extrema_nan(mat)
		if (reg == 0)  x = collect(1.0:nx);		y = collect(1.0:ny)
		else           x = collect(0.5:nx+0.5);	y = collect(0.5:ny+0.5)
		end
		hdr = Float64.([x[1], x[end], y[1], y[end], zmin, zmax])
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
		x = collect(range(hdr[1], stop=hdr[2], length=(nx+Int(hdr[7])) ))
		y = collect(range(hdr[3], stop=hdr[4], length=(ny+Int(hdr[7])) ))
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
    polygonlevels(D::GDtype, ids::Vector{String}, vals::Vector{<:Real}; kw...) -> Vector{Float64}
or

    polygonlevels(D::GDtype, ids::Matrix{String}, vals::Vector{<:Real}; kw...) -> Vector{Float64}

Creates a vector with ZVALS to use in ``plot`` and where length(ZVALS) == length(D)
The elements of ZVALS are made up from the `vals`.

- `ids`:    is a string Vector or Matrix with the ids (attrinute names) of the GMTdataset D.
            If a Matrix (2 columns only) then the `att` bellow must also have two names (string vector
            with two elements) that will be matched against the two eements of each line of `user_ids`.
            The idea here is to match two conditions: ``att[1] == ids[n,1] && att[2] == ids[n,2]``
- `vals`:      is a vector with the numbers to be used in plot ``level`` to color the polygons.
- `attrib` or `att`: keyword to selecect which attribute to use when matching with contents of the `ids` strings.
- `nocase` or `insensitive`: a keyword from `kw`. Perform a case insensitive comparision between the contents of
               `ids` and the attribute specified with `attrib`. Default compares as case sensistive.
- `repeat`: keyword to replicate the previously known value until it finds a new segment ID for the case
            when a polygon have no attributes (may happen for the islands of country).

Returns a Vector{Float64} with the same length as the number of segments in D. Its content are
made up after the contents of `vals` but may be repeated such that each polygon of the same family, i.e.
with the same `ids`, has the same value.
"""
function polygonlevels(D::Vector{<:GMTdataset}, user_ids::Vector{String}, vals::Vector{<:Real}; kw...)::Vector{Float64}
	@assert((n_user_ids = length(user_ids)) == length(vals))
	((att = find_in_kwargs(kw, [:att :attrib])[1]) === nothing) && error("Must provide the `attribute` NAME.")
	nocase = (find_in_kwargs(kw, [:nocase :insensitive])[1] === nothing) ? true : false
	repeat = (find_in_kwargs(kw, [:repeat])[1] === nothing) ? false : true

	n_seg = length(D)
	zvals = fill(NaN, n_seg)
	if (nocase)
		for m = 1:n_seg
			isempty(D[m].attrib) && (repeat && (zvals[m] = zvals[m-1]); continue)
			for k = 1:n_user_ids
				if (D[m].attrib[att] == user_ids[k])
					zvals[m] = vals[k];		break
				end
			end
		end
	else
		for m = 1:n_seg
			isempty(D[m].attrib) && (repeat && (zvals[m] = zvals[m-1]); continue)
			t = lowercase(D[m].attrib[att])
			for k = 1:n_user_ids
				if (t == lowercase(user_ids[k]))
					zvals[m] = vals[k];		break
				end
			end
		end
	end
	return zvals
end

function polygonlevels(D::Vector{<:GMTdataset}, user_ids::Matrix{String}, vals::Vector{<:Real}; kw...)::Vector{Float64}
	@assert((n_user_ids = size(user_ids,1)) == length(vals))
	((att = find_in_kwargs(kw, [:att :attrib :attribute])[1]) === nothing) && error("Must provide the `attribute(s)` NAME.")
	(size(user_ids,2) != length(att)) && error("The `attribute` size must match the number of columns in `user_ids`")
	nocase = (find_in_kwargs(kw, [:nocase :insensitive])[1] === nothing) ? true : false
	repeat = (find_in_kwargs(kw, [:repeat])[1] === nothing) ? false : true

	n_seg = length(D)
	zvals = fill(NaN, n_seg)
	if (nocase)
		for m = 1:n_seg
			isempty(D[m].attrib) && (repeat && (zvals[m] = zvals[m-1]); continue)
			for k = 1:n_user_ids
				if (D[m].attrib[att[1]] == user_ids[k,1] && D[m].attrib[att[2]] == user_ids[k,2])
					zvals[m] = vals[k];		break
				end
			end
		end
	else
		for m = 1:n_seg
			isempty(D[m].attrib) && (repeat && (zvals[m] = zvals[m-1]); continue)
			tt = [lowercase(D[m].attrib[att[1]]) lowercase(D[m].attrib[att[2]])]
			for k = 1:n_user_ids
				if (tt[1] == lowercase(user_ids[k,1]) && tt[2] == lowercase(user_ids[k,2]))
					zvals[m] = vals[k];		break
				end
			end
		end
	end
	return zvals
end

# ---------------------------------------------------------------------------------------------------
function edit_segment_headers!(D, vals::Array, opt::String)
	# Add an option OPT to segment headers with a val from VALS. Number of elements of VALS must be
	# equal to the number of segments in D that have a header. If numel(val) == 1 must encapsulate it in []

	ids, ind = dsget_segment_ids(D)
	if (isa(D, Array))
		[D[ind[k]].header *= string(opt, vals[k])  for k = 1:length(ind)]
	else
		D.header *= string(opt, vals[1])
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    ids, ind = dsget_segment_ids(D, case=0)::Tuple{Vector{String}, Vector{Int}}

Where D is a GMTdataset or a vector of them, returns the segment ids (first text after the '>') and
the indices of those segments.
"""
function dsget_segment_ids(D)::Tuple{Vector{AbstractString}, Vector{Int}}
	# Get segment ids (first text after the '>') and the indices of those segments
	if (isa(D, Array))  n = length(D);	d = Dict(k => D[k].header for k = 1:n)
	else                n = 1;			d = Dict(1 => D.header)
	end
	tf::Vector{Bool} = Vector{Bool}(undef,n)			# pre-allocate
	[tf[k] = (d[k] !== "" && d[k][1] != ' ') ? true : false for k = 1:n];	# Mask of non-empty headers
	ind::Vector{Int} = 1:n
	ind = ind[tf]			# OK, now we have the indices of the segments with headers != ""
	ids = Vector{AbstractString}(undef,length(ind))		# pre-allocate
	[ids[k] = d[ind[k]] for k = 1:length(ind)]
	return ids, ind
end

# ---------------------------------------------------------------------------------------------------
"""
    getbyattrib(D::Vector{<:GMTdataset}[, index::Bool]; kw...)

Take a GMTdataset vector and return only its elememts that match the condition(s) set by the `attrib` keywords.
Note, this assumes that `D` has its `attrib` fields set with usable information.

### Parameters
- `attrib` or `att`: keyword with the attribute ``name`` used in selection. It can be a single name as in `att="NAME_2"`
        or a NamedTuple with the attribname, attribvalue as in `att=(NAME_2="value")`. Use more elements if
        wishing to do a composite match. E.g. `att=(NAME_1="val1", NAME_2="val2")` in which case oly segments
        matching the two conditions are returned.
- `val` or `value`: keyword with the attribute ``value`` used in selection. Use this only when `att` is not a NamedTuple.
- `index`: Use this ``positional`` argument = `true` to return only the segment indices that match the `att` condition(s).

### Returns
Either a vector of GMTdataset, or a vector of Int with the indices of the segments that match the query condition.
Or ``nothing`` if the query results in an empty GMTdataset 

## Example:

    D = getbyattrib(D, attrib="NAME_2", val="Porto");
"""
function getbyattrib(D::Vector{<:GMTdataset}, ind_::Bool; kw...)::Vector{Int}
	# This method does the work but it's not the one normally used by the public.
	# It returns the indices of the selected segments.
	(isempty(D[1].attrib)) && (@warn("This datset does not have an `attrib` field and is hence unusable here."); return Int[])
	((_att = find_in_kwargs(kw, [:att :attrib])[1]) === nothing) && error("Must provide the `attribute` NAME.")
	if isa(_att, NamedTuple)
		atts, vals = string.(keys(_att)), string.(values(_att))
	else
		atts = (string(_att),)
		((val = find_in_kwargs(kw, [:val :value])[1])  === nothing) && error("Must provide the `attribute` VALUE.")
		vals = (string(val),)
	end

	indices::Vector{Int} = Int[]
	for n = 1:length(atts)
		ky = keys(D[1].attrib)
		((ind = findfirst(ky .== atts[n])) === nothing) && return Int[]
		tf = fill(false, length(D))
		for k = 1:length(D)
			(!isempty(D[k].attrib) && (D[k].attrib[atts[n]] == vals[n])) && (tf[k] = true)
		end
		if (n == 1)  indices = findall(tf)
		else         indices = intersect(indices, findall(tf))
		end
	end
	return indices
end

function getbyattrib(D::Vector{<:GMTdataset}; kw...)::Union{Nothing, Vector{GMTdataset}}
	# This is the intended public method. It returns a subset of the selected segments
	ind = getbyattrib(D, true; kw...)
	return isempty(ind) ? nothing : D[ind]
end