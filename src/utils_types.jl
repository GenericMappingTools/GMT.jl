function text_record(data, text::Union{String, Vector{String}, Vector{Vector{String}}}, hdr=Vector{String}())
	# Create a text record to send to pstext. DATA is the Mx2 coordinates array.
	# TEXT is a string or a cell array

	(data == []) && (data = [NaN NaN])
	(isa(data, Vector)) && (data = data[:,:]) 		# Needs to be 2D
	#(!isa(data, Array{Float64})) && (data = Float64.(data))

	if (isa(text, String))
		_hdr = isempty(hdr) ? "" : hdr[1]
		T = GMTdataset(data, Float64[], Float64[], DictSvS(), String[], [text], _hdr, String[], "", "", 0, 0)
	elseif (isa(text, Vector{String}))
		if (text[1][1] == '>')			# Alternative (but risky) way of setting the header content
			T = GMTdataset(data, Float64[], Float64[], DictSvS(), String[], text[2:end], text[1], String[], "", "", 0, 0)
		else
			_hdr = isempty(hdr) ? "" : (isa(hdr, Vector{String}) ? hdr[1] : hdr)
			T = GMTdataset(data, Float64[], Float64[], DictSvS(), String[], text, _hdr, String[], "", "", 0, 0)
		end
	elseif (isa(text, Array{Array}) || isa(text, Array{Vector{String}}))
		nl_t = length(text);	nl_d = size(data,1)
		(nl_d > 0 && nl_d != nl_t) && error("Number of data points ($nl_d) is not equal to number of text strings ($nl_t).")
		T = Vector{GMTdataset}(undef,nl_t)
		for k = 1:nl_t
			T[k] = GMTdataset((nl_d == 0 ? fill(NaN, length(text[k]) ,2) : data[k]), Float64[], Float64[], DictSvS(), String[], text[k], (isempty(hdr) ? "" : hdr[k]), Vector{String}(), "", "", 0, 0)
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
Alternatively, if `mat` is a string or vector of strings we return a dataset with NaN's in the place of
the coordinates. This form is useful to pass to `text` when using the `region_justify` option that
does not need explicit coordinates to place the text.
  - `txt`: Return a Text record which is a Dataset with data = Mx2 and text in third column. The ``text``
     can be an array with same size as `mat` rows or a string (will be repeated n_rows times.) 
  - `x`:   An optional vector with the _xx_ coordinates
  - `hdr`: optional String vector with either one or n_rows multi-element headers.
  - `lc` or `linecolor` or `color`: optional array of strings/symbols with color names/values. Its length can be
     smaller than n_cols, case in which colors will be cycled. If `color` is not an array of strings, e.g.
     `color="yes"`, the colors cycle trough a pre-defined set of colors (same colors as in Matlab). If you
     want the same color repeated for many lines pass color as a vector. *e.g,* `color=[color]`
  - `linethick` or `lt`: for selecting different line thicknesses. Works like `color`, but should be 
     a vector of numbers, or just a single number that is then applied to all lines.
  - `fill`:  Optional string array (or a String of comma separated color names, or a Tuple of color names)
             with color names or array of "patterns".
  - `fillalpha` : When `fill` option is used, we can set the transparency of filled polygons with this
     option that takes in an array (vec or 1-row matrix) with numeric values between [0-1] or ]1-100],
     where 100 (or 1) means full transparency.
  - `is3D`:  If input 'mat' contains at least x,y,z (?).
  - `ls` or `linestyle`:  Line style. A string or an array of strings with `length = size(mat,2)` with line styles.
  - `front`:  Front Line style. A string or an array of strings with `length = size(mat,2)` with front line styles.
  - `pen`:  A full pen setting. A string or an array of strings with `length = size(mat,2)` with pen settings.
     This differs from `lt` in the sense that `lt` does not directly set the line thickness.
  - `multi` or `multicol`: When number of columns in `mat` > 2, or == 2 and x != nothing, make an multisegment Dataset
     with first column and 2, first and 3, etc. Convenient when want to plot a matrix where each column is a line. 
  - `segnan` or `nanseg`: Boolean. If true make a multi-segment made out of segments separated by NaNs.
  - `datatype`: Keep the original data type of `mat`. Default converts to Float64.
  - `geom`: The data geometry. By default, we set `wkbUnknown` but try to do some basic guess.
  - `proj` or `proj4`:  A proj4 string for dataset SRS.
  - `wkt`:  A WKT SRS.
  - `colnames`: Optional string vector with names for each column of `mat`.
  - `attrib`: Optional dictionary{String, String} with attributes of this dataset.
  - `ref:` Pass in a reference GMTdataset from which we'll take the georeference info as well as `attrib` and `colnames`
  - `txtcol` or `textcol`: Vector{String} with text to add into the .text field. Warning: no testing is done
     to check if ``length(txtcol) == size(mat,1)`` as it must.
"""
mat2ds(mat::Nothing) = mat		# Method to simplify life and let call mat2ds on a nothing
mat2ds(mat::GDtype)  = mat		# Method to simplify life and let call mat2ds on a already GMTdataset
mat2ds(text::Union{AbstractString, Vector{<:AbstractString}}) = text_record(text)	# Now we can hide text_record
mat2ds(text::Vector{String}; hdr::String="") = text_record(fill(NaN,length(text),2), text, [hdr])
#function mat2ds(mat::Matrix{Any}; hdr=String[], geom=0, kwargs...)
function mat2ds(mat::AbstractMatrix; hdr=String[], geom=0, kwargs...)::GMTdataset
	# Here we are expecting that Any-ness results from columns with DateTime. If not returm 'mat' as is
	# DateTime columns are converted to seconds and a regular GMTdatset with appropriate column names and attribs is return 
	c = zeros(Bool, size(mat, 2))
	for k = 1:size(mat,2)
		if (typeof(mat[1,k]) == DateTime)
			mat[:,k] = Dates.value.(mat[:,k]) ./ 1000;
			c[k] = true
		end
	end
	#!any(c) && return mat		# Oops, no DateTime? Ok, go to your life and probably blow somewhere.

	D::GMTdataset = mat2ds(convert(Matrix{Float64}, mat); hdr=hdr, geom=geom, kwargs...)
	ind = findall(c)
	if (!isempty(ind))
		Tc = ""
		for k = 1:numel(ind)
			D.colnames[ind[k]] = "Time";		(k > 1) && (D.colnames[ind[k]] *= "$k")
			Tc = (Tc == "") ? "$k" : Tc * ",$k"			# Accept more than one time columns
		end
		(Tc != "") && (D.attrib["Timecol"] = Tc;	D.attrib["Time_epoch"] = " --TIME_EPOCH=0000-12-31T00:00:00 --TIME_UNIT=s")
	end
	D
end

# Method for catching external types of data (e.g. DataFrame)
mat2ds(X; kw...) = tabletypes2ds(X, ((val = find_in_dict(KW(kw), [:interp])[1]) !== nothing) ? interp=val : interp=0)

# ---------------------------------------------------------------------------------------------------
"""
    D = mat2ds(mat::Vector{<:AbstractMatrix}; hdr=String[], kwargs...)::Vector{GMTdataset}

Create a multi-segment GMTdataset (a vector of GMTdataset) from matrices passed in a vector-of-matrices `mat`.
The matrices elements of `mat` do not need to have the same number of rows. Think on this as specifying groups
of lines/points each sharing the same settings. KWarg options of this form are more limited in number than
in the general case, but can take the form of a Vector{Vector}, Vector or scalars.
In the former case (Vector{Vector}) the length of each Vector[i] must equal to the number of rows of each mat[i].

  - `hdr`: optional String vector with either one or `length(mat)` multi-segment headers.
  - `pen`:  A full pen setting. A string or an array of strings with `length = length(mat)` with pen settings.
  - `lc` or `linecolor` or `color`: optional color or array of strings/symbols with color names/values.
  - `linethick` or `lt`: for selecting different line thicknesses. Works like `color`, but should be 
     a vector of numbers, or just a single number that is then applied to all lines.
  - `ls` or `linestyle`:  Line style. A string or an array of strings with `length = length(mat)` with line styles.
  - `front`:  Front Line style. A string or an array of strings with `length = length(mat)` with front line styles.
  - `fill`:  Optional string array (or a String of comma separated color names, or a Tuple of color names)
             with color names or array of "patterns".
  - `fillalpha`: When `fill` option is used, we can set the transparency of filled polygons or symbols with this
     option that takes in an array (vec or 1-row matrix) with numeric values between [0-1] or ]1-100],
     where 100 (or 1) means full transparency.

### Example:
  D = mat2ds([rand(6,3), rand(4,3), rand(3,3)], fill=[[:red], [:green], [:blue]], fillalpha=[0.5,0.7,0.8])
"""
function mat2ds(mat::Vector{<:AbstractMatrix}; hdr=String[], kwargs...)
	d = KW(kwargs)
	mat2ds(mat, hdr, d)
end
#function mat2ds(mat::Vector{<:AbstractMatrix}; hdr=String[], kwargs...)
function mat2ds(mat::Vector{<:AbstractMatrix}, hdr::Vector{String}, d::Dict)
	#d = KW(kwargs)
	D::Vector{GMTdataset} = Vector{GMTdataset}(undef, length(mat))
	pen   = find_in_dict(d, [:pen])[1]
	color = find_in_dict(d, [:lc :linecolor :color])[1]
	ls    = find_in_dict(d, [:ls :linestyle])[1]
	lt    = find_in_dict(d, [:lt :linethick :lw])[1]
	front = find_in_dict(d, [:front])[1]
	fill  = find_in_dict(d, [:fill :fillcolor])[1]
	alpha = find_in_dict(d, [:fillalpha])[1]
	coln  = find_in_dict(d, [:colnames])[1]
	geom::Int  = ((val = find_in_dict(d, [:geom])[1]) === nothing) ? 0 : val
	proj4, wkt, epsg, _, _ = helper_set_crs(d)	# Fish the eventual CRS options.
	for k = 1:length(mat)
		_hdr = length(hdr) <= 1 ? hdr : hdr[k]
		_pen   = (pen   !== nothing) ? (isa(pen, Vector)   ? (length(pen)   == 1 ? pen   : pen[k])   : [pen]) : pen
		_ls    = (ls    !== nothing) ? (isa(ls, Vector)    ? (length(ls)    == 1 ? ls    : ls[k])    : [ls]) : ls
		_lt    = (lt    !== nothing) ? (isa(lt, Vector)    ? (length(lt)    == 1 ? lt    : lt[k])    : [lt]) : lt
		_front = (front !== nothing) ? (isa(front, Vector) ? (length(front) == 1 ? front : front[k]) : [front]) : front
		_color = (color !== nothing) ? (isa(color, Vector) ? (length(color) == 1 ? color : color[k]) : [color]) : color
		_fill  = (fill  !== nothing) ? (isa(fill, Vector)  ? (length(fill)  == 1 ? fill  : fill[k])  : [fill]) : fill
		_alpha = (alpha !== nothing) ? (isa(alpha, Vector) ? (length(alpha) == 1 ? alpha : alpha[k]) : [alpha]) : alpha
		if (k == 1)
			D[k] = mat2ds(mat[k], hdr=_hdr, color=_color, fill=_fill, fillalpha=_alpha, pen=_pen, lt=_lt, ls=_ls, front=_front, geom=geom, colnames=coln, proj4=proj4, wkt=wkt, epsg=epsg)
		else
			D[k] = mat2ds(mat[k], hdr=_hdr, color=_color, fill=_fill, fillalpha=_alpha, pen=_pen, lt=_lt, ls=_ls, front=_front, geom=geom)
		end
	end
	set_dsBB!(D, false)
	return D
end

# ---------------------------------------------------------------------------------------------------
function helper_set_crs(d)
	# Return CRS info eventually passed in kwargs (converted into 'd') + attrib & colnames if :ref is used
	if ((val = find_in_dict(d, [:ref])[1]) !== nothing)		# ref has to be a D but we'll not test it
		Dt::GMTdataset = val		# To try to escape the f... Any's
		prj, wkt, epsg = Dt.proj4, Dt.wkt, Dt.epsg
		return prj, wkt, epsg, Dt.attrib, Dt.colnames
	end

	ref_attrib, ref_coln = Dict(), String[]
	prj::String = ((proj = find_in_dict(d, [:proj :proj4])[1]) !== nothing) ? proj : ""
	(prj == "geo" || prj == "geog") && (prj = prj4WGS84)
	(prj != "" && !startswith(prj, "+proj=")) && (prj = "+proj=" * prj)
	wkt::String = ((wk = find_in_dict(d, [:wkt])[1]) !== nothing) ? wk : ""
	(prj == "" && wkt != "") && (prj = wkt2proj(wkt))
	epsg::Int = ((ep = find_in_dict(d, [:epsg])[1]) !== nothing) ? ep : 0
	(prj == "" && wkt == "" && epsg != 0) && (prj = epsg2proj(epsg))
	return prj, wkt, epsg, ref_attrib, ref_coln
end

# ---------------------------------------------------------------------------------------------------
"""
    D = mat2ds(mat::Array{T,N}, D::GMTdataset)

Take a 2D `mat` array and convert it into a GMTdataset. Pass in a reference GMTdataset from which we'll take
the georeference info as well as `attrib` and `colnames`.
"""
mat2ds(mat::Array{T,N}, ref::GMTdataset) where {T,N} = mat2ds(mat; ref=ref)

# ---------------------------------------------------------------------------------------------------
function mat2ds(mat::Array{T,N}, txt::Union{String,Vector{String}}=String[]; hdr::Union{String,VecOrMat{String}}=String[], geom=0, kwargs...)::GDtype where {T,N}
	d = KW(kwargs)
	_mat2ds(mat, txt, isa(hdr, String) ? [hdr] : vec(hdr), Int(geom), d)
end
function _mat2ds(mat::Array{T,N}, txt::Union{String,Vector{String}}, hdr::Vector{String}, geom::Int, d::Dict)::GDtype where {T,N}

	(!isempty(txt)) && return text_record(mat, txt,  hdr)
	((text = find_in_dict(d, [:text])[1]) !== nothing) && return text_record(mat, text, hdr)
	is3D = (find_in_dict(d, [:is3D])[1] === nothing) ? false : true		# Should account for is3D == false?
	isa(mat, Vector) && (mat = reshape(mat, length(mat), 1))

	val = find_in_dict(d, [:multi :multicol])[1]
	multi = (val === nothing) ? false : ((val) ? true : false)	# Like this it will error if val is not Bool
	segnan = (find_in_dict(d, [:segnan :nanseg])[1] !== nothing) ? true : false		# A classic GMT multi-segment sep with NaNs
	segnan && (multi = true)

	if ((x = find_in_dict(d, [:x])[1]) !== nothing)
		n_ds::Int = segnan ? 1 : ((multi) ? Int(size(mat, 2)) : 1)
		xx::Vector{Float64} = (x == :ny || x == "ny") ? collect(1.0:size(mat, 1)) : vec(x)
		(length(xx) != size(mat, 1)) && error("Number of X coordinates and MAT number of rows are not equal")
	else
		n_ds = (ndims(mat) == 3) ? size(mat,3) : ((multi) ? size(mat, 2) - segnan - (1+is3D) : 1)
		xx = Vector{Float64}()
	end

	if (!isempty(hdr) && length(hdr) == 1)	# Accept one only but expand to n_ds with the remaining as blanks
		_hdr::Vector{String} = Base.fill("", n_ds);	_hdr[1] = hdr[1]
	elseif (!isempty(hdr) && length(hdr) != n_ds)
		error("The header vector can only have length = 1 or same number of MAT Y columns")
	else
		_hdr = hdr
	end

	color_cycle = false
	if ((color = find_in_dict(d, [:lc :linecolor :color])[1]) !== nothing && color != false)
		_color::Vector{String} = (isa(color, VecOrMat{String}) && !isempty(color)) ? vec(string.(color)) : (!isa(color, Vector) && !isa(color, Bool) && color != :cycle) ? [string(color)] : matlab_cycle_colors
		color_cycle = true
	end
	_fill::Vector{String} = helper_ds_fill(d)

	# ---  Here we deal with line colors and line thickness.
	if ((val = find_in_dict(d, [:lt :linethick :linethickness])[1]) !== nothing)
		if     (isa(val, AbstractString))  _lt::Vector{Float64} = [size_unit(val)]
		elseif (isa(val, Vector{String}))  _lt = size_unit(val)
		else                               _lt = isa(val, Real) ? [val] : vec(Float64.(val))
		end
		_lts::Vector{String} = Vector{String}(undef, n_ds)
		n_thick::Integer = length(_lt)
		for k = 1:n_ds
			_lts[k] = " -W" * string(_lt[((k % n_thick) != 0) ? k % n_thick : n_thick])
		end
	else
		theW = (color_cycle || haskey(d, :ls) || haskey(d, :linestyle) || haskey(d, :pen)) ? " -W" : ""
		_lts = fill(theW, n_ds)		# If no pen setting no need to set -W
	end

	if (color_cycle)
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
		(_hdr[1] == " -W") && (for k = 1:n_ds  _hdr[k] *= ","  end)	# If here we have no color set must make it -W,,ls
		if (isa(ls, AbstractString) || isa(ls, Symbol))
			for k = 1:n_ds  _hdr[k] = string(_hdr[k], ',', ls)  end
		else
			for k = 1:n_ds  _hdr[k] = string(_hdr[k], ',', ls[k])  end
		end
	elseif ((ls = find_in_dict(d, [:pen])[1]) !== nothing && ls != "")
		if (isa(ls, AbstractString) || isa(ls, Symbol))
			for k = 1:n_ds  _hdr[k] = string(_hdr[k], ls)  end
		elseif (isa(ls, Tuple))
			for k = 1:n_ds  _hdr[k] = string(_hdr[k], parse_pen(ls))  end
		else
			for k = 1:n_ds  _hdr[k] = string(_hdr[k], ls[k])  end
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

	if ((val = find_in_dict(d, [:front])[1]) !== nothing)
		_lf::Vector{String} = isa(val, Vector{String}) ? val : [string(val)]	# Second case is free to error 
		n_thick = length(_lf)		# Save to reuse var since data type does not change
		for k = 1:n_ds
			_hdr[k] *= " -Sf" * _lf[((k % n_thick) != 0) ? k % n_thick : n_thick]
		end
	end

	#=
	ref_attrib, ref_coln = Dict(), String[]
	if ((val = find_in_dict(d, [:ref])[1]) !== nothing)		# ref has to be a D but we'll not test it
		Dt::GMTdataset = val		# To try to escape the f... Any's
		prj, wkt, epsg = Dt.proj4, Dt.wkt, Dt.epsg
		ref_attrib, ref_coln = Dt.attrib, Dt.colnames
	end

	prj::String = ((proj = find_in_dict(d, [:proj :proj4])[1]) !== nothing) ? proj : ""
	(prj == "geo" || prj == "geog") && (prj = prj4WGS84)
	(prj != "" && !startswith(prj, "+proj=")) && (prj = "+proj=" * prj)
	wkt::String = ((wk = find_in_dict(d, [:wkt])[1]) !== nothing) ? wk : ""
	(prj == "" && wkt != "") && (prj = wkt2proj(wkt))
	epsg::Int = ((ep = find_in_dict(d, [:epsg])[1]) !== nothing) ? ep : 0
	(prj == "" && epsg != 0) && (prj = epsg2proj(wkt))
	(wkt == "" && epsg != 0) && (prj = epsg2wkt(wkt))
	=#
	
	prj, wkt, epsg, ref_attrib, ref_coln = helper_set_crs(d)

	is_geog::Bool = isgeog(prj)
	coln::Vector{String} = ((val = find_in_dict(d, [:colnames])[1]) === nothing) ? String[] : (isa(val, String) ? [val] : val)

	function fill_colnames(coln::Vector{String}, nc::Int, is_geog::Bool)	# Fill the column names vector
		if isempty(coln)
			(coln = (is_geog) ? ["Lon", "Lat"] : ["X", "Y"])
			(nc == 1) ? append!(coln, ["Z"]) : append!(coln, ["Z$i" for i=1:nc])
		end
		return coln
	end

	att::DictSvS = ((v = find_in_dict(d, [:attrib])[1]) !== nothing && isa(v, Dict)) ? v : DictSvS()
	!isempty(att) && !isa(att, Dict{String, Union{String, Vector{String}}}) && error("Attributs must be a Dict{String, Union{String, Vector{String}}}")
	txtcol::Vector{String} = ((val = find_in_dict(d, [:txtcol :textcol])[1]) !== nothing) ? val : String[]

	D::Vector{GMTdataset} = Vector{GMTdataset}(undef, n_ds)

	function segnan_mat(mat, coln, _hdr, is_geog, prj, _geom, xx=Float64[])
		# Create a multi-segment where segments are separated by NaNs.
		isempty(coln) && (coln = (is_geog) ? ["Lon", "Lat"] : ["X", "Y"])
		off = isempty(xx) ? 1 : 0
		n_rows, n_cols = size(mat)
		segN = Matrix{Float64}(undef, n_rows * (n_cols-off) + (n_cols-off-1), 2)
		_xx = isempty(xx) ? view(mat, :, 1) : xx
		s = 1
		for k = 1+off:n_cols
			e = s + n_rows - 1
			#segN[s:e, :] = [_xx mat[:,k]]
			segN[s:e, :] = vcat(_xx, mat[:, k])
			if (k < n_cols)
				segN[e+1, :] = [NaN NaN]
				s += n_rows+1
			end
		end
		GMTdataset(segN, Float64[], Float64[], att, coln, String[], (isempty(_hdr) ? "" : _hdr[1]), String[], prj, wkt, epsg, _geom)
	end

	# By default convert to Doubles, except if instructed to NOT to do it.
	#(find_in_dict(d, [:datatype])[1] === nothing) && (eltype(mat) != Float64) && (mat = Float64.(mat))
	_geom::Int = Int((geom == 0 && (2 <= length(mat) <= 3)) ? Gdal.wkbPoint : (geom == 0 ? Gdal.wkbUnknown : geom))	# Guess geom
	(multi && _geom == 0 && size(mat,1) == 1) && (_geom = Int(Gdal.wkbPoint))	# One row with many columns and MULTI => Points
	if (isempty(xx))				# No coordinates transmitted
		if (ndims(mat) == 3)
			coln = fill_colnames(coln, size(mat,2)-2, is_geog)
			for k = 1:n_ds
				D[k] = GMTdataset(mat[:,:,k], Float64[], Float64[], att, coln, txtcol, (isempty(_hdr) ? "" : _hdr[k]), String[], prj, wkt, epsg, _geom)
			end
		elseif (!multi)
			if (size(mat,2) == 1 && length(coln) == 2 && !isempty(txtcol))	# Do nothing to 'coln'
			else
				coln = fill_colnames(coln, size(mat,2)-2, is_geog)
				(size(mat,2) == 1) && (coln = coln[1:1])		# Because it defaulted to two.
			end
			D[1] = GMTdataset(mat, Float64[], Float64[], att, coln, txtcol, (isempty(_hdr) ? "" : _hdr[1]), String[], prj, wkt, epsg, _geom)
		elseif (segnan)
			D[1] = segnan_mat(mat, coln, _hdr, is_geog, prj, _geom)
		else						# 2D MULTICOL case(s)
			isempty(coln) && (coln = (is_geog) ? ["Lon", "Lat"] : ["X", "Y"])
			for k = 1:n_ds
				# If colnames was transmitted try to assign the right names to each column
				_coln = length(coln) > size(mat, 2) ? [coln[1], coln[k+1], coln[end]] : length(coln) == size(mat, 2) ? [coln[1], coln[k+1]] : coln
				D[k] = GMTdataset(mat[:,[1,k+1]], Float64[], Float64[], att, _coln, txtcol, (isempty(_hdr) ? "" : _hdr[k]), String[], prj, wkt, epsg, _geom)
			end
		end
	else							# With xx coords transmitted.
		if (!multi)
			coln = fill_colnames(coln, size(mat,2)-1, is_geog)
			D[1] = GMTdataset(hcat(xx,mat), Float64[], Float64[], att, coln, String[], (isempty(_hdr) ? "" : _hdr[1]), String[], prj, wkt, epsg, _geom)
		elseif (segnan)
			D[1] = segnan_mat(mat, coln, _hdr, is_geog, prj, _geom, xx)
		else
			isempty(coln) && (coln = (is_geog) ? ["Lon", "Lat"] : ["X", "Y"])
			for k = 1:n_ds
				# If colnames was transmitted try to assign the right names to each column
				_coln = length(coln) > size(mat, 2) ? [coln[1], coln[k], coln[end]] : length(coln) == size(mat, 2) ? [coln[1], coln[k]] : coln
				D[k] = GMTdataset(hcat(xx,mat[:,k]), Float64[], Float64[], att, _coln, String[], (isempty(_hdr) ? "" : _hdr[k]), String[], prj, wkt, epsg, _geom)
			end
		end
	end
	!isempty(ref_attrib) && (D[1].attrib = ref_attrib)		# When a reference Ds was used
	(length(ref_coln) >= size(D[1].data,2)) && (D[1].colnames = ref_coln[1:size(D[1].data,2)])	# This still loses Text colname
	CTRL.pocket_d[1] = d		# Store d that may be not empty with members to use in other functions
	set_dsBB!(D)				# Compute and set the global BoundingBox for this dataset
	#return (find_in_kwargs(kwargs, [:letsingleton])[1] !== nothing) ? D : (length(D) == 1 && !multi) ? D[1] : D
	return (find_in_dict(d, [:letsingleton])[1] !== nothing) ? D : (length(D) == 1 && !multi) ? D[1] : D
end

# ---------------------------------------------------------------------------------------------------
"""
    D = mat2ds(D::GMTdataset, inds::Tuple) -> GMTdataset

Cut a GMTdataset D with the indices in INDS but updating the colnames and the Timecol info.
INDS is a Tuple of 2 with ranges in rows and columns. Ex: (:, 1:3) or (:, [1,4,7]), etc...
Attention, if original had attributes other than 'Timeinfo' there is no guarentie that they remain correct. 
"""
function mat2ds(D::GMTdataset, inds)::GMTdataset
	(length(inds) != ndims(D)) && error("\tNumber of GMTdataset dimensions and indices components must be the same.\n")
	_coln = isempty(D.colnames) ? String[] : (inds[2] === Colon() || last(inds[2]) <= length(D.colnames) ? D.colnames[inds[2]] : String[])
	(!isempty(_coln) && (typeof(inds[1]) == Colon) && length(D.colnames) > size(D,2)) && append!(_coln, [D.colnames[end]])	# Append text colname if exists
	_D = mat2ds(D.data[inds...], proj4=D.proj4, wkt=D.wkt, epsg=D.epsg, geom=D.geom, colnames=_coln, attrib=D.attrib, hdr=D.header)
	(!isempty(D.text)) && (_D.text = D.text[inds[1]])
	(typeof(inds[2]) == Colon) && return _D		# We are done here

	if (size(_D,2) < 2 || inds[2][1] != 1 || inds[2][2] != 2)	# If any of the first or second columns has gone we know no more about CRS
		_D.proj4 = "";	_D.wkt = "";	_D.epsg = 0
	end
	i = findall(startswith.(_D.colnames, "Time"))
	isempty(i) && return _D						# No TIME columns. We are done
	(length(i) == 1) ? (Tc::String = "$(i[1])") : _i = i[2:end]
	_D.attrib["Timecol"] = (length(i) == 1) ? Tc : [Tc *= ",$k" for k in _i]
	(get(D.attrib, "linearfit", "") != "") && (		# A linefit, keep the attribs.
		_D.attrib["Goodness_of_fit"] = D.attrib["Goodness_of_fit"];
		_D.attrib["sigma95_b"] = D.attrib["sigma95_b"];
		_D.attrib["ci"] = D.attrib["ci"];
		_D.attrib["b"] = D.attrib["b"];
		_D.attrib["linearfit"] = D.attrib["linearfit"];
		_D.attrib["sigma_b"] = D.attrib["sigma_b"];
		_D.attrib["sigma95_a"] = D.attrib["sigma95_a"];
		_D.attrib["Pearson"] = D.attrib["Pearson"];
		_D.attrib["a"] = D.attrib["a"];
		)

	return _D
end

# ---------------------------------------------------------------------------------------------------
"""
    mat2dsnan(mat::Matrix{<:Real}; is3D=false, kw...)

Break the matrix `mat` in a series of GMTdatasets using NaN as the breaking flag. By default it only
checks for NaNs in the first two columns. Use `is3D=true` to also check the third column. The `kw`
argument is the same as used in `mat2ds()`.

### Example, create a vector of 2 GMTdatasets:
   mat2dsnan([0 1; 1 1; NaN 0; 2 2 3 3])
"""
function mat2dsnan(mat::Matrix{<:Real}; is3D=false, kw...)
	ind = isnan.(view(mat, :, 1)) .| isnan.(view(mat, :, 2))
	is3D && (ind = ind .| isnan.(view(mat, :, 3)))
	ind2 = [1, findall(diff(ind) .!= 0) .+ 1 ..., size(mat,1)+1]	# Indices of boundaries between NaNs
	n_ds = length(ind2) - 1
	Dm = Vector{GMTdataset}(undef, n_ds)
	for k = 1:n_ds
		Dm[k] = mat2ds(mat[ind2[k]:ind2[k+1]-1, :], kw...)
	end
	return Dm
end

# ---------------------------------------------------------------------------------------------------
function add2ds!(D::GMTdataset, mat, ind::Int=0; name::AbstractString="", names::Vector{<:AbstractString}=AbstractString[])
	# Add the Vector or Matrix 'mat' to D where 'ind' is the column index of the insertion point.
	# Takes care also of updating the column names.
	# If 'ind=0' append 'mat' at the end of 'D'
	# If 'mat' is a vector optionally use the 'name' for the new inserted column
	# If 'mat' is a matrix optionally use a 'names' vector (must have size(mat,2) elements) of new column names.
	(isvector(mat) && size(D,1) != length(mat)) && error("Number of rows in GMTdataset and adding vector elements do not match.")
	(isa(mat, Matrix) && size(mat,1) > 1 && size(D,1) != size(mat,1)) && error("Number of rows in GMTdataset and adding matrix do not match.")
	n_newCols = isvector(mat) ? 1 : size(mat,2)
	_names = (n_newCols == 1 && name == "") ? ["Zadd"] :
	         (n_newCols == 1 ? [name] : !isempty(names) ? names : [string("Zadd_",k) for k=1:n_newCols])

	if (!isempty(D.colnames))
		t_col = (!isempty(D.text) && length(D.colnames) > size(D,2)) ? D.colnames[end] : ""
	end
	if (ind == 0 || ind == size(D,2))
		if (!isempty(D.colnames))
			(size(D,2) > length(D.colnames)) && (append!(D.colnames, ["Bug"]))		# I fck cant get rid of this
			D.colnames = !isempty(t_col) ? [D.colnames[1:size(D,2)]..., _names..., t_col] :	[D.colnames[1:size(D,2)]..., _names...]
		end
		D.data = hcat(D.data, isvector(mat) ? mat[:] : mat)
	elseif (ind == 1)
		D.data = hcat(isvector(mat) ? mat[:] : mat, D.data)
		!isempty(D.colnames) && (D.colnames = [_names..., D.colnames...])
	else
		D.data = isvector(mat) ? hcat(D.data[:,1:ind-1], mat[:], D.data[:,ind+1:end]) : hcat(D.data[:,1:ind-1], mat, D.data[:,ind+1:end])
		!isempty(D.colnames) && (D.colnames = [D.colnames[1:ind-1]..., _names..., D.colnames[ind+1:end]...])
	end
	set_dsBB!(D)
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function add2ds!(D::Vector{<:GMTdataset}, mat, ind::Int=0; name::AbstractString="", names::Vector{<:AbstractString}=AbstractString[])::Union{Nothing,Matrix{<:Real}}
	for k = 1:numel(D)  add2ds!(D[k], mat, ind; name=name, names=names)  end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function add2ds!(D::GMTdataset; name::AbstractString="", names::Vector{<:AbstractString}=AbstractString[])
	# Method for fixing the colnames and/or the bbox in DS that had their matrix extended.
	# 'name' and 'names' are only usable if 'D' already has 'colnames'
	isempty(D.colnames) && (D.colnames = [string("Col.",k) for k=1:size(D,2)])
	if ((n_newCols = size(D,2) - length(D.colnames)) > 0)
		_names = (n_newCols == 1 && name == "") ? ["Zadd"] :
		         (n_newCols == 1 ? [name] : !isempty(names) ? names : [string("Zadd_",k) for k=1:n_newCols])
		D.colnames = [D.colnames..., _names...]
	end
	(length(D.bbox) != 2 * size(D,2)) && set_dsBB!(D)
end

# ---------------------------------------------------------------------------------------------------
function set_dsBB(D, all_bbs::Bool=true)
	# This method returns the modified 'D'
	set_dsBB!(D, all_bbs)
	return D
end

# ---------------------------------------------------------------------------------------------------
function set_dsBB!(D, all_bbs::Bool=true)
	# Compute and set the global and individual BoundingBox for a Vector{GMTdataset} + the trivial cases.
	# If ALL_BBS is false then assume individual BBs are already knwon.
	isempty(D) && return nothing

	if (all_bbs)		# Compute all BBs
		if isa(D, GMTdataset)
			(size(D,1) == 1) && return nothing		# Single liners have no BB
			D.ds_bbox = D.bbox = collect(Float64, Iterators.flatten(extrema(D.data, dims=1)))
			ind = findall(.!isfinite.(D.bbox))		# If we have some columns with NaNs or Infs
			if (!isempty(ind))
				for k = 2:2:length(ind)
					k2 = div(k,2)
					D.ds_bbox[k2*2-1], D.ds_bbox[k2*2] = extrema_cols_nan(D.data, col=k2)
				end
				D.bbox = D.ds_bbox
			end
			return nothing
		else
			for k = 1:lastindex(D)
				bb = Base.invokelatest(extrema, D[k].data, dims=1)		# A N Tuple.
				_bb = collect(Float64, Iterators.flatten(bb))
				if (any(isnan.(_bb)))				# Shit, we don't have a minimum_nan(A, dims)
					n = 1
					for kk = 1:size(D[k].data, 2)
						isnan(_bb[n]) && (_bb[n:n+1] .= extrema_cols(D[k].data, col=kk))
						n += 2
					end
					all(isnan.(_bb)) && continue	# Shit, they are all still NaNs
				end
				D[k].bbox = _bb
			end
		end
	end

	(isa(D, GMTdataset)) && (D.ds_bbox = D.bbox;	return nothing)
	(length(D) == 1)     && (D[1].ds_bbox = D[1].bbox;	return nothing)
	kk = 0
	while (isempty(D[kk+=1].bbox) && kk < length(D))  continue  end
	bb = copy(D[kk].bbox)
	for k = kk+1:lastindex(D)
		for n = 1:2:length(bb)
			isempty(D[k].bbox) && continue
			bb[n]   = min(D[k].bbox[n],   bb[n])
			bb[n+1] = max(D[k].bbox[n+1], bb[n+1])
		end
	end
	D[1].ds_bbox = bb
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function ds2ds(D::Vector{<:GMTdataset})::GMTdataset
	# Take a vector of DS and collapse it into a single GMTdataset DS. Some metadata, proj, colnames
	# and attributes are copied from first segment. Colors in header and text are lost.
	tot_rows = sum(size.(D,1))
	data = zeros(eltype(D[1]), tot_rows, size(D[1],2))
	s, e = 1, size(D[1],1)
	data[s:e, :] = D[1].data
	for k = 2:numel(D)
		s  = e + 1
		e += size(D[k],1)
		data[s:e, :] = D[k].data
	end
	mat2ds(data, proj=D[1].proj4, wkt=D[1].wkt, epsg=D[1].epsg, geom=D[1].geom, colnames=D[1].colnames, attrib=D[1].attrib)
end

Base.:stack(D::Vector{<:GMTdataset}) = ds2ds(D)

# ---------------------------------------------------------------------------------------------------
function ds2ds(D::GMTdataset; is3D::Bool=false, kwargs...)::Vector{<:GMTdataset}
	d = KW(kwargs)
	ds2ds(D, is3D, d)
end
#function ds2ds(D::GMTdataset; is3D::Bool=false, kwargs...)::Vector{<:GMTdataset}
function ds2ds(D::GMTdataset, is3D::Bool, d::Dict)::Vector{<:GMTdataset}
	# Take one DS and split it into an array of DS's, one for each row and optionally add -G<fill>
	# Alternativelly, if [:multi :multicol] options lieve in 'd', split 'D' by columns: [1,2], [1,3], [1,4], ...
	# So far only for internal use but may grow in function of needs
	#d = KW(kwargs)

	#multi = 'r'		# Default split by rows
	#if ((val = find_in_dict(d, [:multi :multicol], false)[1]) !== nothing)  multi = 'c'  end		# Then by columns
	# Split by rows or columns
	multi = ((find_in_dict(d, [:multi :multicol], false)[1]) !== nothing) ? 'c' : 'r'
	_fill = (multi == 'r') ? helper_ds_fill(d) : String[]		# In the columns case all is dealt in mat2ds.

	n_colors = length(_fill)
	if ((val = find_in_dict(d, [:color_wrap])[1]) !== nothing)	# color_wrap is a kind of private option for bar-stack
		n_colors::Int = Int(val)
	end

	n_ds = size(D.data, multi == 'r' ? 1 : 2)
	(multi == 'c') && (n_ds -= 1+is3D)
	if (!isempty(_fill))				# Paint the polygons (in case of)
		_hdr::Vector{String} = Vector{String}(undef, n_ds)
		for k = 1:n_ds
			_hdr[k] = " -G" * _fill[((k % n_colors) != 0) ? k % n_colors : n_colors]
		end
		(D.header != _hdr[1]) && (_hdr[1] = D.header * _hdr[1])	# Copy eventual contents of first header
	end

	Dm = Vector{GMTdataset}(undef, n_ds)
	if (multi == 'r')
		for k = 1:n_ds
			Dm[k] = GMTdataset(D.data[k:k, :], Float64[], Float64[], DictSvS(), String[], String[], (isempty(_fill) ? "" : _hdr[k]), String[], "", "", 0, wkbPoint)
		end
		Dm[1].colnames = D.colnames
		(size(D.text) == n_ds) && (for k = 1:n_ds  Dm[k].text = D.text[k]  end)
	else
		Dm = mat2ds(D.data; colnames=D.colnames, d...)
	end
	Dm[1].comment = D.comment;	Dm[1].proj4 = D.proj4;	Dm[1].wkt = D.wkt;	Dm[1].epsg = D.epsg;
	Dm
end

# ----------------------------------------------
function helper_ds_fill(d::Dict; del::Bool=true, symbs=[:fill :fillcolor], nc=0)::Vector{String}
	# Shared by ds2ds & mat2ds & statplots
	# The NC parameter is used to select the color schema: <= 8 ==> 'matlab_cycle_colors'; otherwise 'simple_distinct'
	# By using a non-default SYMBS we can use this function for other than selecting fill colors.
	if ((fill_val = find_in_dict(d, symbs, del)[1]) !== nothing)
		if (isa(fill_val, StrSymb))
			fill_val_s = string(fill_val)::String
			if contains(fill_val_s, ",")  _fill::Vector{String} = collect(split(fill_val_s, ","))
			elseif (fill_val_s == "yes" || fill_val_s == "cycle")
			                               _fill = (nc <= 8) ? copy(matlab_cycle_colors) : copy(simple_distinct)
			elseif (fill_val_s == "none")  _fill = [" "]
			else	                       _fill = [fill_val_s]
			end
		elseif (isa(fill_val, Tuple) && eltype(fill_val) == Symbol)
			_fill = [string.(fill_val)...]
		elseif (isa(fill_val, VecOrMat{String}) && !isempty(fill_val))
			_fill = vec(fill_val)
		elseif (isa(fill_val, VecOrMat{Symbol}))
			_fill = vec(string.(fill_val))
		else
			_fill = (nc <= 8) ? copy(matlab_cycle_colors) : copy(simple_distinct)
		end
		n_colors::Int = length(_fill)
		if ((alpha_val = find_in_dict(d, [:fillalpha])[1]) !== nothing)
			(eltype(alpha_val) <: AbstractFloat && maximum(alpha_val) <= 1) && (alpha_val = collect(alpha_val) .* 100)
			_alpha::Vector{String} = Vector{String}(undef, n_colors)
			na::Int = min(length(alpha_val), n_colors)
			for k = 1:na  _alpha[k] = join(string('@',alpha_val[k]))  end
			if (na < n_colors)
				for k = na+1:n_colors  _alpha[k] = ""  end
			end
			for k = 1:n_colors  _fill[k] *= _alpha[k]  end	# And finaly apply the transparency
		end
		(_fill[1] == " ") && (_fill = Vector{String}())		# Passing a fill=[" "] is programatically handy to say no fill
	else
		_fill = Vector{String}()
	end
	return _fill
end

const matlab_cycle_colors = ["#0072BD", "#D95319", "#EDB120", "#7E2F8E", "#77AC30", "#4DBEEE", "#A2142F", "0/255/0"]
# https://en.wikipedia.org/wiki/Help:Distinguishable_colors
const alphabet_colors = ["#2BCE48", "#4C005C", "#005C31", "#5EF1F2", "#8F7C00", "#9DCC00", "#0075DC", "#94FFB5", "#740AFF", "#993F00", "#00998F", "#003380", "#191919", "#426600", "#808080", "#990000", "#C20088", "#E0FF66", "#F0A3FF", "#FF0010", "#FF5005", "#FFA8BB", "#FFA405", "#FFCC99", "#FFE100", "#FFFF80"]
# https://sashamaps.net/docs/resources/20-colors/
const simple_distinct = ["#e6194b", "#3cb44b", "#ffe119", "#4363d8", "#f58231", "#911eb4", "#46f0f0", "#f032e6", "#bcf60c", "#fabebe", "#008080", "#e6beff", "#9a6324", "#fffac8", "#800000", "#aaffc3", "#808000", "#ffd8b1", "#000075", "#808080"]
 
# ---------------------------------------------------------------------------------------------------
"""
    FV = fv2fv(F, V; proj="", proj4="", wkt="", epsg=0) -> GMTfv

Create a FacesVertices object from a matrix of faces indices and another matrix of vertices (a Mx3 matrix).

### Args
- `F`:  A matrix of faces indices or a vector of matrices when defining bodies made of multiple
   surfaces (cylinders for example).
- `V`:  A Mx3 matrix of vertices.

### Kargs
- `proj` or `proj4`:  A proj4 string for setting the Coordinate Referencing System
- `wkt`:  A WKT SRS.
- `epsg`: Same as `proj` but using an EPSG code
"""
function fv2fv(F::Vector{<:AbstractMatrix{<:Integer}}, V; color_vwall::String="", zscale=1.0, bfculling=true, proj="", proj4="", wkt="", epsg=0)::GMTfv
	(isempty(proj4) && !isempty(proj)) && (proj4 = proj)	# Allow both proj4 or proj keywords
	bbox = extrema(V, dims=1)
	_bbox::Vector{Float64} = [bbox[1][1], bbox[1][2], bbox[2][1], bbox[2][2], bbox[3][1], bbox[3][2]]
	isflat = zeros(Bool, length(F))			# Needs thinking
	GMTfv(verts=collect(V), faces=collect.(F), bbox=_bbox, color_vwall=color_vwall, zscale=zscale, bfculling=bfculling,
	      isflat=isflat, proj4=proj4, wkt=wkt, epsg=epsg)
end

fv2fv(F::Matrix{<:Integer}, V; color_vwall::String="", zscale=1.0, bfculling=true, proj="", proj4="", wkt="", epsg=0) =
	fv2fv([F], V; color_vwall=color_vwall, zscale=zscale, bfculling=bfculling, proj=proj, proj4=proj4, wkt=wkt, epsg=epsg)

"""
When using Meshing.jl we can use the output of the ``isosurface`` function, "verts, faces" as input to this function.

- `F`:  A vector of Tuple{Int, Int, Int} with the body faces indices
- `V`:  A vector of Tuple{Float64, Float64, Float64} with the body vertices

### Example
```julia
gyroid(v) = cos(v[1])*sin(v[2])+cos(v[2])*sin(v[3])+cos(v[3])*sin(v[1]);
gyroid_shell(v) = max(gyroid(v)-0.4,-gyroid(v)-0.4);
xr,yr,zr = ntuple(_ -> LinRange(0,pi*4,50), 3);
A = [gyroid_shell((x,y,z)) for x in xr, y in yr, z in zr];
A[1,:,:] .= 1e10; A[:,1,:] .= 1e10; A[:,:,1] .= 1e10; A[end,:,:] .= 1e10; A[:,end,:] .= 1e10; A[:,:,end] .= 1e10;
vts, fcs = isosurface(A, MarchingCubes());
FV = fv2fv(fcs, vts)
viz(FV, cmap=makecpt(T="0/1", cmap="darkgreen,lightgreen"))
```
"""
function fv2fv(F::Vector{Tuple{Int, Int, Int}}, V::Vector{Tuple{Float64, Float64, Float64}};
               zscale=1.0, bfculling=true, proj="", proj4="", wkt="", epsg=0)::GMTfv
	verts = reshape(reinterpret(Float64, V), (3,:))'
	faces = [reshape(reinterpret(Int, F), (3,:))']
	fv2fv(faces, verts; zscale=zscale, bfculling=bfculling, proj=proj, proj4=proj4, wkt=wkt, epsg=epsg)
end

# ---------------------------------------------------------------------------------------------------
"""
    FV = surf2fv(X::Matrix{T}, Y::Matrix{T}, Z::Matrix{T}; type=:tri, bfculling=true,
                 proj="", proj4="", wkt="", epsg=0, top=nothing, bottom=nothing) -> GMTfv

Create a three-dimensional FacesVertices object.

This function is suitable for 3D plotting either of closed bodies or 3D surfaces.
The values in matrix Z represent the heights above a grid in the x-y plane defined by X and Y

### Args
- `X,Y,Z`: Three matrices of the same size and type float.

### Kwargs
- `type`: The face type. Either ``:tri`` (the default) or ``:quad`` for triangular or quadrangular faces.
- `bfculling`: Boolean that specifies if culling of invisible faces is wished (default is ``true``)
- `proj` or `proj4`:  A proj4 string for setting the Coordinate Referencing System (optional).
- `wkt`: A WKT SRS (optional).
- `epsg`: Same as `proj` but using an EPSG code (optional).
- `top`: A Faces 1 row matrix with the top of the body (optional). Note that we have to impose that this
   is an already created faces matrix because inside this function we no longer know what the order of
   the ``X`` and ``Y`` matrices represent.
- `bottom`: A Faces 1 row matrix with the bottom of the body (optional).

### Example
```julia
X,Y = meshgrid(1:0.5:10,1.:20);
Z = sin.(X) .+ cos.(Y);
FV = surf2fv(X, Y, Z);
viz(FV)
```
"""
function surf2fv(X::Matrix{T}, Y::Matrix{T}, Z::Matrix{T}; type=:tri, bfculling=true, mask=BitArray(undef,0,0),
                 proj="", proj4="", wkt="", epsg=0, top=nothing, bottom=nothing)::GMTfv where {T <: AbstractFloat}
	@assert length(X) == length(Y) == length(Z)
	(type != :tri && type != :quad) && error("type must be :tri or :quad")

	have_mask = !isempty(mask)
	n_rows, n_cols = size(X)
	n_faces = (have_mask) ? sum(mask) : (n_rows - 1) * (n_cols - 1)
	(have_mask && n_faces == 0) && error("Something is wrong. The 'mask' matrix is filled with 'false' only.")
	c1, c2 = (type == :tri) ? (2, 3) : (1, 4)
	if (bottom === nothing && top === nothing)
		F = [fill(0, c1 * n_faces, c2)]
		indS = 1
	elseif (bottom === nothing && top !== nothing)
		F = [fill(0, c1 * n_faces, c2), top]
		indS = 1
	elseif (bottom !== nothing && top !== nothing)
		F = [bottom, fill(0, c1 * n_faces, c2), top]
		indS = 2
	elseif (bottom !== nothing && top === nothing)
		F = [bottom, fill(0, c1 * n_faces, c2)]
		indS = 2
	end

	n = 0
	if (type == :tri)
		for col = 1:n_cols - 1
			for row = 1:n_rows - 1
				r = row + (col - 1) * n_rows
				c = r + n_rows
				n += 1
				F[indS][n,1], F[indS][n,2], F[indS][n,3] = r, r+1, c
				n += 1
				F[indS][n,1], F[indS][n,2], F[indS][n,3] = r+1, r+1+n_rows, c
			end
		end
	else
		for col = 1:n_cols - 1
			for row = 1:n_rows - 1
				have_mask && !mask[row,col] && continue
				r = row + (col - 1) * n_rows
				c = r + n_rows
				n += 1
				F[indS][n,1], F[indS][n,2], F[indS][n,3], F[indS][n,4] = r, r+1, c+1, c
			end
		end
	end
	fv2fv(F, [X[:] Y[:] Z[:]]; bfculling=bfculling, proj=proj, proj4=proj4, wkt=wkt, epsg=epsg)
end

# ---------------------------------------------------------------------------------------------------
"""
    v, names = splitds(D::Vector{<:GMTdataset}; groupby::String="") --> Tuple{Vector{Vector{Int}}, Vector{String}}

Compute the indices that split a vector of datasets into groups. The grouping is done either by a provided 
attribute name (`groupby`) or by the Feature_ID attribute. This function is mostly used internally by `zonal_statistics`

- `D`: A vector of GMTdataset

- `groupby`: If provided, it must be an attribute name, for example, `groupby="NAME"`. If not provided, we use
  the `Feature_ID` attribute that is a unique identifier assigned during an OGR file reading (by the GMT6.5 C lib).
  If the `Feature_ID` attribute does not exist, you must use a valid attribute name passed in `groupby`.
  If neither of those exists, an error is thrown.

### Returns
- `v`: A Vector{Vector{Int}} with the indices that split the datasets into groups. The length of `v` is the
  number of groups found and each element of `v` is a vector of indices that belong to that group.

- `names`: A Vector{String} with the names of the groups. These names are fetched from the attributes.
  It will be the values of the attribute name provided by `groupby` or those of the first attribute value
  if that option is not used.
"""
function splitds(D::Vector{<:GMTdataset}; groupby::String="")
	# Split a vector of datasets into groups by the Feature_ID attribute.
	if (groupby != "")		# Use the attribute selected by the user
		att_names = vec(string.(keys(D[1].attrib)))
		ind = findfirst(groupby .== att_names)
		(ind === nothing) && error("Attribute '$groupby' not found in dataset!")
		names = Vector{String}(undef, length(D))
		for k = 1:length(D)  names[k] = D[k].attrib[att_names[ind]]  end

		feature_names = unique(names)
		nf = length(feature_names)
		vv = Vector{Vector{Int}}(undef, nf)
		for k = 1:nf  vv[k] = findall(names .== feature_names[k])  end
	else					# Use the 'Feature_ID' attribute
		get(D[1].attrib, "Feature_ID", "") == "" && error("Attribute 'Feature_ID' not found in dataset!")
		nf = parse(Int, D[end].attrib["Feature_ID"])
		vv = Vector{Vector{Int}}(undef, nf)
		for k = 1:nf  vv[k] = filter(D, indices=true, Feature_ID = "$k")  end
		att_ref = (get(D[1].attrib, "NAME", "") == "") ? "NAME" : collect(keys(D[1].attrib))[1]
		feature_names = Vector{String}(undef, nf)
		for k = 1:nf  feature_names[k] = D[vv[k][1]].attrib[att_ref]  end
	end
	return vv, feature_names
end

# ---------------------------------------------------------------------------------------------------
function tabletypes2ds(arg, interp=0)
	# Try guesswork to convert Tables types into GMTdatasets usable in plots.
	#(arg === nothing || isa(arg, GDtype) || isa(arg, Matrix{<:Real})) && return arg
	isdataframe(arg) && return df2ds(arg)				# DataFrames are(?) easier to deal with.
	isODE(arg) && return ODE2ds(arg, interp=interp)		# DifferentialEquations type is a complex beast.
	(isa(arg, GMT.Gdal.AbstractDataset) || isa(arg, GMT.Gdal.AbstractGeometry)) && return gd2gmt(arg)

	# Guesswork, it may easily screw.
	colnames = [i for i in fields(arg) if Base.nonmissingtype(eltype(getproperty(arg, i))) <: AbstractFloat]
	vv = [getproperty(arg,i) for i in colnames]			# A f. Vector-of-vectors
	mat2ds(reduce(hcat,vv), colnames=string.(colnames))	# More f. cryptic cmds
end

# ---------------------------------------------------------------------------------------------------
"""
    D = mesh2ds(mesh) -> Vector{GMTdataset}

Extract data from a GeometryBasics Mesh type and return it into a vector of GMTdataset.
"""
function mesh2ds(mesh)
	(!startswith(string(typeof(mesh)), "Mesh{3,")) && error("Argument must be a GeometryBasics mesh")
	D = Vector{GMTdataset}(undef, length(mesh))
	for k = 1:numel(mesh)
		D[k] = GMTdataset(data = [mesh[k].points.data[1].data[1] mesh[k].points.data[1].data[2] mesh[k].points.data[1].data[3];
			                      mesh[k].points.data[2].data[1] mesh[k].points.data[2].data[2] mesh[k].points.data[2].data[3];
				                  mesh[k].points.data[3].data[1] mesh[k].points.data[3].data[2] mesh[k].points.data[3].data[3]])
	end
	return set_dsBB(D)
end

# ---------------------------------------------------------------------------------------------------
"""
    D = df2ds(df) -> GMTdataset

Extract numeric data from a DataFrame type and return it into a GMTdataset. Works only with 'simple' DataFrames.
"""
function df2ds(arg)::GMTdataset
	# Try to convert a DataFrame into a GMTdataset. Keep all numerical columns and first Text one
	colnames = [i for i in names(arg) if Base.nonmissingtype(eltype(arg[!,i])) <: Real]
	mat = Matrix(coalesce.(arg[!,[colnames...]], NaN))
	D = mat2ds(mat, colnames=colnames)
	colnames = [i for i in names(arg) if Base.nonmissingtype(eltype(arg[!,i])) <: AbstractString]	# Fish first (if any) text column
	!isempty(colnames) && (D.text = string.(arg[!,colnames[1]]); append!(D.colnames, [colnames[1]]))
	return D
end

# ---------------------------------------------------------------------------------------------------
"""
    D = ODE2ds(sol; interp=0)

Extract data from a DifferentialEquations solution type and return it into a GMTdataset.

- `interp`: == 0 means we return the original points (no interpolation). == 2 => do data interpolation to
    the double of original number of points. == 3 => three times, == n => n times. 
"""
function ODE2ds(arg; interp=0)::GMTdataset
	vv = getproperty(arg,:u)			# A potentially Vector-of-vectors or Vector-of-matrices
	if (interp != 0)
		ts = range(arg.t[1], stop = arg.t[end], length = interp * length(arg.t))
		mat = [ts stack([arg(ts, idxs=k).u for k = 1:numel(arg.u[1])])]
	else
		if isa(vv, Vector{<:Matrix})
			mat = [arg.t reshape(reshape(reduce(hcat,vv),size(first(vv))...,:), length(vv[1]), length(vv))'[:,end:-1:1]]	# No comments
		else
			mat = (isa(vv, Vector{<:Vector})) ? [arg.t reduce(hcat,vv)'] : [arg.t arg.u]
		end
	end
	colnames = Vector{String}(undef, size(mat,2));	colnames[1] = "t"
	(size(mat,2) == 2) ? colnames[2] = "u" : (for k = 1:size(mat,2)-1  colnames[k+1] = "u$k"  end)
	mat2ds(mat, colnames=colnames)
end

# ---------------------------------------------------------------------------------------------------
"""
    G = rasters2grid(arg; scale=1, offset=0)

Deals with Rasters.jl arrays (grids and cubes). The input argument was previously detected (by israsters)
to be a Rasters.jl type. The input array is not copied when it has no 'missings' but is often modified
when replacing abstruse missingval by NaN. And given that the type is immutable we cannot change the
`arg.missingval` and hence some checks # will be repeated everytime this function is run. So the best
is to call ``G = mat2grid(arg)`` once and use `G`

Returns a GMTgrid type.
"""
function rasters2grid(arg; scale::Real=1f0, offset::Real=0f0)::GMTgrid
	_y = collect(arg.dims[2]);	(_y[2] < _y[1]) ? (_y = _y[end:-1:1]; Yorder = 'T') : (Yorder = 'B')
	_v = (size(arg,3) > 1) ? collect(arg.dims[3]) : Float64[]
	#_v = (size(arg,3) > 1) && (eltype(arg.dims[3]) <: TimeType ? [arg.dims[3][i].instant.periods.value for i=1:length(arg.dims[3])] : Float64[])	# Store in milisecs just to have something numeric
	n_cols = size(arg.data)[2]
	is_transp = (n_cols == length(_y))
	layout = is_transp ? Yorder * "RB" : ""

	proj::String, wkt::String, epsg::Int = "", "", 0
	t = !isempty(arg.dims) ? arg.dims[1].val.crs.val : nothing		# It took an awful debug effort to find this
	isa(t, Tuple) && (t = t[1])
	isa(t, Int) ? (epsg = t; proj = epsg2proj(t)) : startswith(t, "GEOGCS") ? (wkt=t; proj=wkt2proj(t)) : startswith(t, "+proj") ? (proj=t) : nothing

	data = nothing
	(isa(arg.missingval, Real) && !isnan(arg.missingval) && eltype(arg.data) <: AbstractFloat) && (@inbounds Threads.@threads for k=1:numel(arg.data) arg.data[k] == arg.missingval && (arg.data[k] = NaN)  end)

	# If Raster{Union{Missing, Float32},2} we're f... Copies and repetions all the time.
	if (ismissing(arg.missingval))
		@inbounds Threads.@threads for k=1:numel(arg.data) ismissing(arg.data[k]) && (arg.data[k] = NaN)  end
		data = convert(Array{eltype(arg.data[1]), ndims(arg)}, arg.data)
	end

	# Only case tested has CF times but I imagine we can have other units that make sense translate to names
	names = String[]
	if (eltype(_v) <: TimeType)
		names = string.(_v)		# Next, strip the "T00:00:00" part if there is no Time info
		endswith(names[1], "T00:00:00") && endswith(names[end], "T00:00:00") &&
			(for k = 1:numel(names) names[k] = names[k][1:10] end)
	end

	dic = !isempty(arg.metadata) ? arg.metadata.val : Dict()
	(scale  == 1) && (scale  = get(dic, "scale", 1.0f0))
	(offset == 0) && (offset = get(dic, "offset", 0.0f0))
	z_unit  = get(dic, "units", "")

	(data === nothing) && (data = collect(arg.data))
	(scale != 1 || offset != 0) && (data = muladd.(data, convert(eltype(data), scale), convert(eltype(data), offset)))
	(eltype(data) == Int16) && (data = convert(Array{Float32, ndims(data)}, data))	# And what about UInt16, UInt8, etc ...?

	(is_transp && Yorder == 'B') && (reverse!(data, dims=2); layout = "TRB")	# GMT expects grids to be scanline and Top->Bot
	mat2grid(data, x=collect(arg.dims[1]), y=_y, v=_v, names=names, tit=string(arg.name), rem="Converted from a Rasters object.", is_transposed=is_transp, layout=layout, proj4=proj, wkt=wkt, epsg=epsg, z_unit=z_unit)
end

# ---------------------------------------------------------------------------------------------------
"""
    G = kde2grid(arg)

Wrap a `KernelDensity` object to a `GMTgrid`
"""
function kde2grid(arg)
	# KernelDensity types come in row major order and rows as columns, so we have to trick things a little bit here.
	G = mat2grid(Float32.(arg.density), arg.y, arg.x)
	G.layout = "TRB"
	G.x, G.y = G.y, G.x
	G.range[1:2], G.range[3:4] = G.range[3:4], G.range[1:2]
	G.inc[1], G.inc[2] = G.inc[2], G.inc[1]
	return G
end

# ---------------------------------------------------------------------------------------------------
# Try to guess if ARG is a DataFrame type. Note, we do this without having DataFrames as a dependency (even indirect)
isdataframe(arg) = (fs = fields(arg); return (isempty(fs) || fs[1] != :columns || fs[end] != :allnotemetadata) ? false : true)
# Check if it is a DifferentialEquations type
isODE(arg) = (fs = fields(arg); return (!isempty(fs) && (fs[1] == :u && any(fs .== :t) && any(fs .== :retcode))) ? true : false)
# See if it is a Rasters type
israsters(arg) = (fs = fields(arg); return (length(fs) >= 6 && (fs[1] == :data && fs[end] == :missingval)) ? true : false)

# ---------------------------------------------------------------------------------------------------
function color_gradient_line(D::Matrix{<:Real}; is3D::Bool=false, color_col::Int=3, first::Bool=true)::Matrix{Real}
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

function color_gradient_line(D::GMTdataset; is3D::Bool=false, color_col::Int=3, first::Bool=true)::GMTdataset
	mat = color_gradient_line(D.data, is3D=is3D, color_col=color_col, first=first)
	mat2ds(mat, proj=D.proj4, wkt=D.wkt, geom=wkbLineString)
end

function color_gradient_line(Din::Vector{<:GMTdataset}; is3D::Bool=false, color_col::Int=3, first::Bool=true)::Vector{GMTdataset}
	D = Vector{GMTdataset}(undef, length(Din))
	for k = 1:length(Din)
		D[k] = color_gradient_line(Din[k], is3D=is3D, color_col=color_col, first=first)
	end
	D
end
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
function line2multiseg(M::Matrix{<:Real}; is3D::Bool=false, color::GMTcpt=GMTcpt(), auto_color::Bool=false, lt=nothing, color_col::Int=0)
	# Take a 2D or 3D poly-line and break it into an array of DS, one for each line segment
	# AUTO_COLOR -> color from 1:size(M,1)
	(!isempty(color) && size(M,2) < 3) && error("For a varying color the input data must have at least 3 columns")
	n_ds = size(M,1)-1
	_hdr::Vector{String} = fill("", n_ds)
	first, use_row_number = true, false
	_lt = (lt === nothing) ? Float64[] : vec(Float64.(lt))
	if (!isempty(_lt))
		nth = length(_lt)
		if (nth < size(M,1))
			if (nth == 2)  th::Vector{Float64} = collect(linspace(_lt[1], _lt[2], n_ds))	# If we have only 2 thicknesses.
			else           th = hlp_var_thk(lt, n_ds)
			end
			for k = 1:n_ds  _hdr[k] = string(" -W", th[k])  end
		else
			for k = 1:n_ds  _hdr[k] = string(" -W", _lt[k])  end
		end
		first = false
	end

	(color_col == 0) && (color_col = 3)		# Set the color column to default if it wasn't sent in.

	if (isempty(color) && auto_color)
		mima = (size(M,2) <= 3) ? (1., Float64(size(M,1))) : Float64.(extrema_cols(M, col=color_col))
		(size(M,2) <= 3) && (use_row_number = true; z4color = 1.:n_ds)
		color::GMTcpt = gmt(@sprintf("makecpt -T%f/%f/65+n -Cturbo -Vq", mima[1]-eps(1e10), mima[2]+eps(1e10)))
	end

	if (!isempty(color))
		z_col = color_col
		rgb = [0.0, 0.0, 0.0, 0.0]
		P::Ptr{GMT_PALETTE} = palette_init(G_API[1], color);		# A pointer to a GMT CPT
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
		Dm[k] = GMTdataset(M[k:k+1, :], Float64[], Float64[], DictSvS(), String[], String[], _hdr[k], String[], "", "", 0, geom)
	end
	Dm
end

function hlp_var_thk(lt, n_ds)
	# The cmd "vec(gmt_GMTdataset("sample1d -T -o1", [collect(1:nth) _lt], collect(linspace(1,nth,n_ds))).data)" causes
	# function invalidation (Fck Julia) that goes up the stack chain. So we approx it with a 2nd order polynomial interp.
	nth = length(lt)
	p = polyfit(1:nth, lt)
	polyval(p, linspace(1, nth, n_ds))
end

function line2multiseg(D::GMTdataset; is3D::Bool=false, color::GMTcpt=GMTcpt(), auto_color::Bool=false, lt=nothing, color_col::Int=0)
	Dm = line2multiseg(D.data, is3D=is3D, color=color, auto_color=auto_color, lt=lt, color_col=color_col)
	Dm[1].proj4, Dm[1].wkt, Dm[1].ds_bbox, Dm[1].colnames = D.proj4, D.wkt, D.ds_bbox, D.colnames
	Dm
end

function line2multiseg(D::Vector{<:GMTdataset}; is3D::Bool=false, color::GMTcpt=GMTcpt(), auto_color::Bool=false, lt=nothing, color_col::Int=0)
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
    I = mat2img(mat::Array{<:Unsigned}; x=[], y=[], hdr=[], proj4="", wkt="", cmap=GMTcpt(), kw...)

Take a 2D 'mat' array and a `hdr` 1x9 [xmin xmax ymin ymax zmin zmax reg xinc yinc] header descriptor
and return a GMTimage type.
Alternatively to `hdr`, provide a pair of vectors, x & y, with the X and Y coordinates.
Optionally, the `hdr` arg may be omitted and it will computed from `mat` alone, but then x=1:ncol, y=1:nrow
When `mat` is a 3D UInt16 array we automatically compute a UInt8 RGB image. In that case `cmap` is ignored.
But if no conversion is wanted use option `noconv=true`

    I = mat2img(mat::Array{UInt16}; x=[], y=[], hdr=[], proj4::String="", wkt::String="", kw...)

Take a `mat` array of UInt16 and scale it down to UInt8. Input can be 2D or 3D.
If the kw variable `stretch` is used, we stretch the intervals in `stretch` to [0 255].
Use this option to stretch the image histogram.
If `stretch` is a scalar, scale the values > `stretch` to [0 255]
  - stretch = [v1 v2] scales all values >= v1 && <= v2 to [0 255]
  - stretch = [v1 v2 v3 v4 v5 v6] scales first band >= v1 && <= v2 to [0 255], second >= v3 && <= v4, same for third
  - stretch = :auto | "auto" | true | 1 will do an automatic stretching from values obtained from histogram thresholds

The `kw...` kwargs search for [:layout :mem_layout], [:names] and [:metadata]
"""
function mat2img(mat::Union{AbstractArray{<:Unsigned}, AbstractArray{<:Bool}}; x=Float64[], y=Float64[], v=Float64[], hdr=Float64[],
                 proj4::String="", wkt::String="", cmap=GMTcpt(), is_transposed::Bool=false, kw...)
	# Take a 2D array of uint8 and turn it into a GMTimage.
	# Note: if HDR is empty we guess the registration from the sizes of MAT & X,Y
	(cmap === nothing && eltype(mat) == Bool) && (cmap = makecpt(T=(0,1), cmap=:gray))
	#helper_mat2img(mat; x=x, y=y, v=v, hdr=hdr, proj4=proj4, wkt=wkt, cmap=cmap, is_transposed=is_transposed, kw...)
	d = KW(kw)
	helper_mat2img(mat, vec(Float64.(x)), vec(Float64.(y)), vec(Float64.(v)), vec(Float64.(hdr)), proj4, wkt, cmap, is_transposed, d)
end

# Special version to desambiguate between UInt8 and UInt16
function mat2img16(mat::AbstractArray{<:Unsigned}; x=Float64[], y=Float64[], v=Float64[], hdr=Float64[],
                   proj4::String="", wkt::String="", cmap=GMTcpt(), is_transposed::Bool=false, kw...)
	#helper_mat2img(mat; x=x, y=y, v=v, hdr=hdr, proj4=proj4, wkt=wkt, cmap=cmap, is_transposed=is_transposed, kw...)
	d = KW(kw)
	helper_mat2img(mat, vec(Float64.(x)), vec(Float64.(y)), vec(Float64.(v)), vec(Float64.(hdr)), proj4, wkt, cmap, is_transposed, d)
end
#function helper_mat2img(mat; x=Float64[], y=Float64[], v=Float64[], hdr=Float64[],
                        #proj4::String="", wkt::String="", cmap=GMTcpt(), is_transposed::Bool=false, kw...)
function helper_mat2img(mat, x::Vector{Float64}, y::Vector{Float64}, v::Vector{Float64}, hdr::Vector{Float64},
                        proj4::String, wkt::String, cmap::GMTcpt, is_transposed::Bool, d::Dict)
	color_interp = "";		n_colors = 0;
	if (!isempty(cmap))
		colormap, labels, n_colors = cpt2cmap(cmap)
	else
		(size(mat,3) == 1) && (color_interp = "Gray")
		if (!isempty(hdr) && (hdr[5] == 0 && hdr[6] == 1))	# A mask. Let's create a colormap for it
			colormap = zeros(Int32, 256 * 3)
			n_colors = 256;					# Because for GDAL we always send 256 even if they are not all filled
			colormap[2] = colormap[258] = colormap[514] = 255
		else
			colormap = zeros(Int32,3)		# Because we need an array
		end
		labels = String[]
	end

	nx = size(mat, 2);		ny = size(mat, 1);
	if (is_transposed)  nx, ny = ny, nx  end
	reg::Int = (!isempty(hdr)) ? Int(hdr[7]) : (nx == length(x) && ny == length(y)) ? 0 : 1
	#hdr::Vector{Float64} = vec(hdr);	x::Vector{Float64} = vec(x);	y::Vector{Float64} = vec(y)	# Otherwis JET screammmms
	x, y, hdr, x_inc, y_inc = grdimg_hdr_xy(mat, reg, hdr, x, y, is_transposed)

	mem_layout = (size(mat,3) == 1) ? "TCBa" : "TCBa"		# Just to have something. Likely wrong for 3D
	#d = KW(kw)
	((val = find_in_dict(d, [:layout :mem_layout])[1]) !== nothing) && (mem_layout = string(val)::String)
	_names::Vector{String} = ((val = find_in_dict(d, [:names])[1]) !== nothing) ? val : String[]
	_meta::Vector{String}  = ((val = find_in_dict(d, [:metadata])[1]) !== nothing) ? val : String[]

	GMTimage(proj4, wkt, 0, -1, hdr[1:6], [x_inc, y_inc], reg, NaN32, color_interp, _meta, _names,
	         x,y,v,mat, colormap, labels, n_colors, Array{UInt8,2}(undef,1,1), mem_layout, 0)
end

# ---------------------------------------------------------------------------------------------------
function cpt2cmap(cpt::GMTcpt, start::Float32=NaN32, force_alpha::Bool=true)
	# Convert a GMT CPT into a colormap to be ingested by GDAL
	s = isnan(start) ? 0 : (start == 0) ? 1 : 0		# When I has a nodata = 0, make first color white.
	(size(cpt.colormap,1) + s > 256) && error("Size of CPT + nodata value is greater than 256. Can't be.")
	have_alpha = !all(cpt.alpha .== 0.0)
	nc = (have_alpha || force_alpha) ? 4 : 3
	cmap = zeros(Int32, 256 * nc)
	(s == 1) && (cmap[1] = 255; cmap[257] = 255; cmap[513] = 255)	# nodata pixel color = white
	n_colors = 256;			# Because for GDAL we always send 256 even if they are not all filled
	gray_max = (cpt.minmax[2] == 1) ? 1 : 255		# First, carefull, change. Probably should be 'gray_max = cpt.minmax[2]'
	for n = 1:3				# Write 'cmap' col-wise
		for m = 1:size(cpt.colormap, 1)
			@inbounds cmap[m+s + (n-1)*n_colors] = round(Int32, cpt.colormap[m,n] * gray_max);
		end
	end
	if (have_alpha)						# Have alpha color(s)
		for m = 1:size(cpt.colormap, 1)
			@inbounds cmap[m + 3*n_colors] = round(Int32, cpt.colormap[m,4] * 255)
		end
		n_colors *= 1000				# Flag that we have alpha colors in an indexed image
	elseif (force_alpha)
		cmap[256*3+1:end] .= Int32(255)
	end
	return cmap, cpt.label, n_colors# - s	# Subtract s to account for when nodata != NaN (= 0)	
end

# ---------------------------------------------------------------------------------------------------
"""
    C = map2cpt(I::GMTimage) -> GMTcpt

Converts the `I` colormap, which is a plain vector, into a GMTcpt.
"""
function cmap2cpt(I::GMTimage)
	(length(I.colormap) <= 4) && (@warn("This image has no associated colormap");	return nothing)
	_nc = length(I.colormap) / I.n_colors
	(_nc != 4 && _nc != 3) && error("Something is wrong with this Image colormap. No RGB nor RGBA.")

	nc, n_colors, n = Int(_nc), I.n_colors, I.n_colors
	cmap = reshape(I.colormap, n, nc)
	while (n > 0)
		n = (cmap[n,1] == 0 && cmap[n,2] == 0 && cmap[n,3] == 0) ? n-1 : -n
	end
	n  = -n								# Revert the negative sign with which it left the while loop.
	if (I.nodata == 0.0)  s, nn, f = 2, n-1, 1.0	# If nodata = 0, jump first color in 'cmap'
	else                  s, nn, f = 1, n,   0.0
	end
	cm = cmap[s:n,1:3]/255
	alpha = length(I.alpha) == n_colors ? I.alpha[s:n]/255 : (nc == 4) ? cmap[s:n,4] * 0.0 : zeros(nn)
	lab = !isempty(I.labels) ? I.labels : fill("",nn)
	key = !isempty(I.labels) ? string.(f:nn) : fill("",nn)
	GMTcpt(cm, alpha, [f:nn f+1.0:nn+1], [f, nn], ones(3,3), 24, NaN, [cm cm], 0, lab, key, "rgb", ["Converted from GDAL cmap"])
end

# ---------------------------------------------------------------------------------------------------
function mat2img(mat::Union{AbstractMatrix{UInt16},AbstractArray{UInt16,3}}; x=Float64[], y=Float64[], v=Float64[], hdr=Float64[], proj4::String="", wkt::String="", img8::AbstractMatrix{UInt8}=Matrix{UInt8}(undef,0,0), kw...)
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
	x::Vector{Float64} = vec(x);	y::Vector{Float64} = vec(y);	v::Vector{Float64} = vec(v);
	hdr::Vector{Float64} = vec(hdr)
	if ((val = find_in_dict(d, [:noconv])[1]) !== nothing)		# No conversion to UInt8 is wished
		return mat2img16(mat; x=x, y=y, v=v, hdr=hdr, proj4=proj4, wkt=wkt, d...)
	end

	img = isempty(img8) ? Array{UInt8, ndims(mat)}(undef, size(mat)) : img8
	(size(img) != size(mat)) && error("Incoming matrix and image holder have different sizes")
	if ((vals = find_in_dict(d, [:histo_bounds :stretch], false)[1]) !== nothing)
		nz = 1
		isa(mat, Array{UInt16,3}) ? (ny, nx, nz) = size(mat) : (ny, nx) = size(mat)

		(vals == "auto" || vals == :auto || (isa(vals, Real) && vals == 1)) &&
			(vals = [find_histo_limits(mat)...])	# Out is a tuple, convert to vector
		len::Int = length(vals)

		(len > 2*nz) && error("'stretch' has more elements then allowed by image dimensions")
		(len != 1 && len != 2 && len != 6) &&
			error("Bad 'stretch' argument. It must be a 1, 2 or 6 elements array and not $len")

		#val = (len == 1) ? convert(UInt16, vals)::UInt16 : convert(Vector{UInt16}, vals)::Vector{UInt16}
		(len > 1) && (val26::Vector{UInt16} = convert(Vector{UInt16}, vec(vals)))
		if (len == 1)
			val1::UInt16 = convert(UInt16, vals)
			sc = 255 / (65535 - val1)
			@inbounds @simd for k = 1:numel(img)
				img[k] = (mat[k] < val1) ? 0 : round(UInt8, (mat[k] - val1) * sc)
			end
		elseif (len == 2)
			val_ = [parse(UInt16, @sprintf("%d", val26[1])) parse(UInt16, @sprintf("%d", val26[2]))]
			sc = 255 / (val_[2] - val_[1])
			@inbounds @simd for k = 1:numel(img)
				img[k] = (mat[k] < val_[1]) ? 0 : ((mat[k] > val_[2]) ? 255 : round(UInt8, (mat[k]-val_[1])*sc))
			end
		else	# len = 6
			nxy = nx * ny
			v1 = [1 3 5];	v2 = [2 4 6]
			sc = [255 / (val26[2] - val26[1]), 255 / (val26[4] - val26[3]), 255 / (val26[6] - val26[5])]
			@inbounds @simd for n = 1:nz
				@inbounds @simd for k = 1+(n-1)*nxy:n*nxy
					img[k] = (mat[k] < val26[v1[n]]) ? 0 : ((mat[k] > val26[v2[n]]) ? 255 : round(UInt8, (mat[k]-val26[v1[n]])*sc[n]))
				end
			end
		end
	else
		sc = 255/65535
		@inbounds @simd for k = 1:numel(img)
			img[k] = round(UInt8, mat[k]*sc)
		end
	end
	(haskey(d, :scale_only)) && return img			# Only the scaled array is needed. Alows it to be a view
	mat2img(img; x=x, y=y, v=v, hdr=hdr, proj4=proj4, wkt=wkt, d...)
end

# ---------------------------------------------------------------------------------------------------
function mat2img(img::GMTimage; kw...)
	# Scale a UInt16 GMTimage to UInt8. Return a new object but with all old image parameters
	(eltype(img.image) != UInt16) && return img			# Nothing to do
	I = mat2img(img.image; kw...)
	I.proj4 = img.proj4;	I.wkt = img.wkt;	I.epsg = img.epsg
	I.range = img.range;	I.inc = img.inc;	I.registration = img.registration
	I.nodata = img.nodata;	I.color_interp = img.color_interp;
	I.names = img.names;	I.metadata = img.metadata
	I.x = img.x;	I.y = img.y;	I.colormap = img.colormap;	I.labels = img.labels
	I.n_colors = img.n_colors;		I.alpha = img.alpha;	I.layout = img.layout;
	return I
end

# ---------------------------------------------------------------------------------------------------
function mat2img(mat::Union{GMTgrid,Matrix{<:AbstractFloat}}; x=Float64[], y=Float64[], hdr=Float64[],
	             proj4::String="", wkt::String="", GI::Union{GItype,Nothing}=nothing, clim=[0,255], cmap=GMTcpt(), kw...)
	# This is the same as Matlab's imagesc() ... plus some extras.
	mi, ma = (isa(mat,GMTgrid)) ? mat.range[5:6] : extrema(mat)
	(isa(mat,GMTgrid) && mat.hasnans == 2) && (mi = NaN)		# Don't know yet so force checking
	if (isnan(mi))			# Shit, such a memory waste we need to do.
		mi, ma = extrema_nan(mat)
		t = isa(mat, GMTgrid) ? Float32.((mat.z .- mi) ./ (ma - mi) .* 255) : Float32.((mat .- mi) ./ (ma - mi) .* 255)
		for k in CartesianIndices(t)  isnan(t[k]) && (t[k] = 255f0)  end
		img = round.(UInt8, t)
	else
		img = isa(mat,GMTgrid) ? round.(UInt8, (mat.z .- mi) ./ (ma - mi) .* 255) : round.(UInt8, (mat .- mi) ./ (ma - mi) .* 255) 
	end

	(clim[1] >= clim[2]) && error("CLIM values are non-sense (min > max)")
	if (clim[1] > 0 && clim[1] < 255)
		for k in eachindex(img)  if (img[k] < clim[1])  img[k] = clim[1]  end  end
	end
	if (clim[2] < 255 && clim[2] > 0)
		for k in eachindex(img)  if (img[k] > clim[2])  img[k] = clim[2]  end  end
	end
	is_transp = isa(mat, GItype) ? ((mat.layout[2] == 'R') ? true : false) : false
	if (!isa(mat, GMTgrid) && GI !== nothing)
		I = mat2img(img, GI)
		if (!isempty(cmap))  I.colormap, I.labels, I.n_colors = cpt2cmap(cmap)
		else                 I.colormap, I.labels, I.n_colors = zeros(Int32,3), String[], 0	# Do not inherit this from GI
		end
	elseif (isa(mat, GMTgrid))
		(isa(cmap, Symbol) || isa(cmap, String)) && (cmap = grd2cpt(mat, E=256, C=cmap))
		I = mat2img(img; x=mat.x, y=mat.y, hdr=hdr, proj4=mat.proj4, wkt=mat.wkt, cmap=cmap, is_transposed=is_transp, kw...)
	else
		I = mat2img(img; x=x, y=y, hdr=hdr, proj4=proj4, wkt=wkt, cmap=cmap, is_transposed=is_transp, kw...)
	end
	isa(mat,GMTgrid) && (I.layout = mat.layout[1:3] * "a")
	return I
end

"""
    I = imagesc(mat; x=, y=, hdr=, proj4=, wkt=, GI=, clim=, cmap=, kw...)

imagesc takes a Float matrix or a GMTgrid type and scales it (by default) to the [0, 255] interval.
In the process it creates a GMTimage type. Those types can account for coordinates and projection
information, hence the optional arguments. Contrary to its Matlab cousin, it doesn't display the
result (that we easily do with `imshow(mat)`) but return instead a GMTimage object.

  - `clim`: Specify clims as a two-element vector of the form [cmin cmax], where values of the scaled image
     less than or equal to cmin are assigned that value. The same goes for cmax.
  - `cmap`: If provided, `cmap` is a GMTcpt and its contents is converted to the `GMTimage` colormap.
  - `GI`: This can be either a GMTgrid or a GMTimage and its contents is used to set spatial contents
     (x,y coordinates) and projection info that one may attach to the created image result. This is
     a handy alterative to the `x=, y=, proj4=...` options.
  - `stretch`: This option is indicated to select an interval of the range of the `z` values and use only
     those to scale to the [0 255] interval. A `stretch=true` automatically determines good values for
     histogram stretching via a call to `histogram`. The form `stretch=(zmin,zmax)` allows specifying the
     input limits directly. A previous plot of ``histogram(mat, show=true)`` can help determine good values.
     Note that when this option `stretch` is used, ALL OTHER options are ignored. See also the ``rescale`` function.

If 'mat' is instead a UInt16 GMTimage type we call `rescale(I, stretch=true, type=UInt8)` instead of
issuing an error. In this case `clim` can be a two elements vector to specify the desired stretch range.
The default is to let `histogram` guess these values.
"""
function imagesc(mat::Union{GMTgrid,Matrix{<:AbstractFloat}}; x=Float64[], y=Float64[], hdr=Float64[],
	             proj4::String="", wkt::String="", GI::Union{GItype,Nothing}=nothing, clim=[0,255], cmap=GMTcpt(), kw...)
	
	# Call 'rescale' and return if the kw 'stretch' is used
	((stretch = find_in_kwargs(kw, [:stretch])[1]) !== nothing) && return rescale(mat, stretch=stretch, type=UInt8)
	mat2img(mat; x=x, y=y, hdr=hdr, proj4=proj4, wkt=wkt, GI=GI, clim=clim, cmap=cmap, kw...)
end

function imagesc(I::GMTimage{<:UInt16}; clim=0)
	# User probably meant to use 'rescale(I,stretch=1,type=UInt8)' instead of 'imagesc(I)' for scaling a
	# UInt16 GMTimage directly, so do it instead of erroring as we used to do.
	return clim == 0 ? rescale(I, stretch=1, type=UInt8) : rescale(I, stretch=[clim[1],clim[2]], type=UInt8)
end

# ---------------------------------------------------------------------------------------------------
# This method creates a new GMTimage but retains all the header data from the IMG object
function mat2img(mat, I::GMTimage; names::Vector{String}=String[], metadata::Vector{String}=String[])
	range = copy(I.range);	(size(mat,3) == 1) && (range[5:6] .= extrema(mat))
	GMTimage(I.proj4, I.wkt, I.epsg, I.geog, range, copy(I.inc), I.registration, NaN32, I.color_interp, metadata, names, copy(I.x), copy(I.y), zeros(size(mat,3)), mat, copy(I.colormap), String[], I.n_colors, Array{UInt8,2}(undef,1,1), I.layout, 0)
end
function mat2img(mat, G::GMTgrid; names::Vector{String}=String[], metadata::Vector{String}=String[])
	range = copy(G.range);	range[5:6] .= (size(mat,3) == 1) ? extrema(mat) : [0., 255]
	GMTimage(G.proj4, G.wkt, G.epsg, G.geog, range, copy(G.inc), G.registration, NaN32, "Gray", metadata, names, copy(G.x), copy(G.y), zeros(size(mat,3)), mat, zeros(Int32,3), String[], 0, Array{UInt8,2}(undef,1,1), G.layout*"a", 0)
end

# ---------------------------------------------------------------------------------------------------
"""
    slicecube(I::GMTimage, layer::Union{Int, AbstractVector{<:Int}})

Take a slice of a multylayer GMTimage. Return the result still as a GMTimage. `layer` is the z slice number.

    slicecube(G::GMTgrid, slice::Union{Int, AbstractVector{<:Int}}; axis="z")

Extract a slice from a GMTgrid cube.

- `slice`: If it is an Int it will return a GMTgrid corresponding to that layer.
  However, if `slice` is a float this is interpreted to mean: search that dimension (see the `axis` below)
  coordinates and find the closest layer that has coordinate = `slice`. If the `slice` value is not within
  10% of the coordinate of closest layer, the returned layer is obtained by linear interpolation of the
  neighboring layers. For example, `slice=2.5` on a cube were layers are one unit apart will interpolate
  between layers 2 and 3 where each layer weights 50% in the end result. NOTE: the return type is
  still a cube but with one layer only (and the corresponding axis coordinate).
  `slice` Can also be a vector of integers representing the slices we want to extract. The output is another cube.

- `axis`: denotes the dimension being sliced. The default, "z", means the slices are taken from the
  vertical axis. `axis="x"` means slice along a column, and `axis="y"` slice along a row.

	slicecube(GI::GItype; slice::Int=0, angle=0.0, axis="x", cmap=GMTcpt())

Take a slice of a GMTgrid or GMTimage in an oblique direction. Take the cube's layer `slice` and rotate it
by `angle` degrees about the `axis`. This one can only be `axis=:x` or `axis=:y`. Depending on the data
type of input a different output is produces. If `GI` is a GMTgrid, the output is 2 GMTgrids: one with `z`
levels and the other with cube's z levels along that plane. On the other hand, if GI isa GMTimage the
first output is similar to previus case but the second will be a GMTimage. In this case the `cmap` option
may be used to assign a colortable to the image type.

The value at the slice point, P(x[i,j], y[i,j], z[i, j)), is the interpolated value of the two nearest
voxels on the same vertical.

### Example
Get the fourth layer of the multi-layered 'I' GMTimage object 

```
I = slicecube(I, 4)
```
"""
function slicecube(I::GMTimage, layer::Union{Int, AbstractVector{<:Int}})
	isvec = !isa(layer, Int)
	first_layer = isa(layer, Int) ? layer : layer[1]
	last_layer  = isa(layer, Int) ? layer : layer[end]
	(first_layer < 1 || last_layer > size(I,3)) && error("Layer value(s) is out of bounds of image size ($size(I,3))")
	if (I.layout[3] == 'P')			# Shit, Pixel interleaving
		(first_layer != last_layer) && (@warn("Slicing a Pixel interleaved image only works with a single layer"); return I)
		mat = zeros(eltype(I), size(I,1), size(I,2))
		np  = size(I,3)
		for k = 1:size(I,1) * size(I,2)  mat[k] = I.image[layer + (k-1) * np]  end
	else							# Still fails in the Line interleaving case.
		mat = I.image[:,:,layer]
	end
	range = copy(I.range);	range[5:6] .= extrema(mat)
	names = (!isempty(I.names) && !all(I.names .== "")) ? (isvec ? I.names[layer] : [I.names[layer]]) : I.names
	GMTimage(I.proj4, I.wkt, I.epsg, I.geog, range, copy(I.inc), I.registration, I.nodata, "Gray", I.metadata, names, copy(I.x), copy(I.y), [0.], mat, zeros(Int32,3), String[], 0, Array{UInt8,2}(undef,1,1), I.layout, I.pad)
end

function slicecube(G::GMTgrid, slice::Union{Int, AbstractVector{<:Int}}; axis="z",
                   x::Union{VecOrMat{<:Real}, Tuple}=Float64[], y::Union{VecOrMat{<:Real}, Tuple}=Float64[])
	# Method that slices grid cubes. SLICE is the row|col|layer number. AXIS picks the axis to be sliced
	# This method lets us slice a cube along any or all of the x|y|z axis
	(ndims(G) < 3 || size(G,3) < 2) && error("This is not a cube grid.")
	_axis = lowercase(string(axis))

	dim = (_axis == "z") ? 3 : (_axis == "y" ? 1 : 2)		# First try to pick which dimension to slice
	if (G.layout[2] == 'R' && dim < 3)  dim = (dim == 1) ? 2 : 1  end	# For RowMajor swap dim from 1 to 2
	this_size = size(G,dim)
	isvec = !isa(slice, Int)
	(!isvec && slice > this_size) && error("Slice number ($slice) is larger than grid size ($this_size)")
	(!isvec && slice[end] > this_size) && error("Last slice number ($(slice[end])) is larger than grid size ($this_size)") 

	(isempty(G.v) || length(G.v) == 1) && (G.v = collect(1:size(G,3)))
	rng = isvec ? slice : slice:slice
	colmajor, ix, iy, ixp, iyp = helper_slicecube(G, x, y)

	if (_axis == "z")				# A horizontal slice (plane xy)
		_ix, _iy = colmajor ? (ix, iy) : (iy, ix)
		G_ = mat2grid(G[_iy,_ix,slice], G.x[ixp], G.y[iyp], isvec ? G.v[slice] : [G.v[slice]], reg=G.registration, is_transposed=!colmajor)
		G_.names = (!isempty(G.names) && !all(G.names .== "")) ? (isvec ? G.names[slice] : [G.names[slice]]) : G.names
		G_.proj4, G_.wkt, G_.epsg, G_.geog, G_.layout = G.proj4, G.wkt, G.epsg, G.geog, G.layout
	elseif (_axis == "y")			# A slice in xz plane
		(!colmajor && G.layout[1] == 'T') && (rng = (size(G,2)+1 - rng[end]):(size(G,2)+1 - rng[1]))	# Believe that (10 - rng) errors but (10 - 1:1) NOT!!!!!
		yv = G.y[slice:slice+G.registration]
		if (colmajor)  G_ = mat2grid(G[rng,ix,:], G.x[ixp], yv, G.v, reg=G.registration, names=G.names)
		else           G_ = mat2grid(G[ix,rng,:], G.x[ixp], yv, G.v, reg=G.registration, is_transposed=true, names=G.names)
		end
		G_.proj4, G_.wkt, G_.epsg, G_.geog, G_.layout = "", "", 0, 0, "TRB"
	else							# A slice in yz plane
		_iy = (!colmajor && G.layout[1] == 'T') ? ((size(G,2)+1 - iy[end]):(size(G,2)+1 - iy[1])) : iy
		xv = G.x[slice:slice+G.registration]
		if (colmajor)  G_ = mat2grid(G[iy,rng,:],  xv, G.y[iyp], G.v, reg=G.registration, names=G.names)
		else           G_ = mat2grid(G[rng,_iy,:], xv, G.y[iyp], G.v, reg=G.registration, is_transposed=true, names=G.names)
		               (G.layout[1] == 'T') && (G_.z = fliplr(G_.z))	# The debugger told me to do this.
		end
		G_.proj4, G_.wkt, G_.epsg, G_.geog, G_.layout = "", "", 0, 0, "TRB"
	end
	return G_
end

function helper_slicecube(G, x, y)
	# Shared between two methods of slicecube.
	colmajor = (G.layout[2] == 'C')
	tx = isempty(x) ? [1 colmajor ? size(G,2) : size(G,1)] : round.(Int,interp_vec(G.x, x))
	ix = tx[1]:tx[2]
	ty = isempty(y) ? [1 colmajor ? size(G,1) : size(G,2)] : round.(Int,interp_vec(G.y, y))
	iy = ty[1]:ty[2]
	# The pixel registration case is more complicated. Not sure that the following is the right way to do it.
	ixp, iyp = (G.registration == 0) ? (ix, iy) : (ix[1]:ix[end]+1, iy[1]:iy[end]+1)
	return colmajor, ix, iy, ixp, iyp
end

function slicecube(G::GMTgrid, slice::AbstractFloat; axis="z",
                   x::Union{VecOrMat{<:Real}, Tuple}=Float64[], y::Union{VecOrMat{<:Real}, Tuple}=Float64[])
	# Method that slices grid cubes. SLICE is the x|y|z coordinate where to slice. AXIS picks the axis to be sliced
	# So far horizontal slices are unique (single slice) but vertical slices can slice sub-cubes.
	(ndims(G) < 3 || size(G,3) < 2) && error("This is not a cube grid.")
	_axis = lowercase(string(axis))

	which_coord_vec = (_axis == "z") ? G.v : (_axis == "y" ? G.y : G.x)
	isempty(which_coord_vec) && (which_coord_vec = collect(1.0:size(G,3)))	# To at least have something.
	xf = interp_vec(which_coord_vec, slice)
	layer = trunc.(Int, xf)
	frac = xf .- layer			# Used for layer interpolation.
	all(frac .< 0.1) && return slicecube(G, layer, axis=_axis, x=x, y=y)	# If 'slice' is within 10% of lower or upper layer just
	all(frac .> 0.9) && return slicecube(G, layer.+1, axis=_axis, x=x, y=y)	# return that layer and do not interpolation between layers.

	nxy = size(G,1) * size(G,2)
	l = layer
	colmajor, ix, iy, ixp, iyp = helper_slicecube(G, x, y)

	if (_axis == "z")				# A horizontal slice (plane xy)
		mat = [G[k] + (G[k+nxy] - G[k]) * frac for k = (layer-1)*nxy+1 : layer*nxy]
		G_ = mat2grid(reshape(mat,size(G,1),size(G,2)), G.x, G.y, [Float64(slice)], reg=G.registration, is_transposed=!colmajor, layout=G.layout)
		if (!isempty(x) || !isempty(y))		# It would have been too complicated to do this with the "mat = ..." above
			isempty(x) && (x = [G.range[1], G.range[2]])
			isempty(y) && (y = [G.range[3], G.range[4]])
			G_ = crop(G_, region=(x[1], x[2], y[1], y[2]))
		end
	elseif (_axis == "y")			# A slice in xz plane
		if (colmajor)  mat = G[l:l,ix,:] .+ (G[l+1:l+1,ix,:] .- G[l:l,ix,:]) .* frac
		else           mat = G[ix,l:l,:] .+ (G[ix,l+1:l+1,:] .- G[ix,l:l,:]) .* frac
		end
		G_ = mat2grid(mat, G.x[ixp], [G.y[l]], G.v, reg=G.registration, is_transposed=!colmajor, layout="TRB")
	else							# A slice in yz plane
		if (colmajor)  mat = G[iy,l:l,:] .+ (G[iy,l+1:l+1,:] .- G[iy,l:l,:]) .* frac
		else           mat = G[l:l,iy,:] .+ (G[l+1:l+1,iy,:] .- G[l:l,iy,:]) .* frac
		end
		G_ = mat2grid(mat, [G.x[l]], G.y[iyp], G.v, reg=G.registration, is_transposed=!colmajor, layout="TRB")
	end
	return G_
end

function slicecube(GI::GItype; slice::Int=0, α=0.0, angle=0.0, axis="x", cmap=GMTcpt())
	# Adapted from function in https://discourse.julialang.org/t/oblique-slices-in-makie/83879/8
	# Returns a GMTgrid, GMTimage in case GI is an GMTimage, or two GMTgrids otherwise.
	_axis = lowercase(string(axis))
	(_axis != "x" && _axis != "y") && error("rotate only about xaxis or yaxis")
	(ndims(GI) < 3 || size(GI,3) < 2) && error("This is not a cube grid/image.")
	r, c, h = size(GI)
	xl = 0:1:c-1
	yl = 0:1:r-1
	(α == 0 && angle != 0) && (α = angle)
	α = Float32(deg2rad(α))
	if (_axis == "x")  z = slice / cos(α) .+ yl .* ones(Float32,r,c)   .* tan(α)
	else               z = slice / cos(α) .- ones(Float32,r, c) .* xl' .* tan(α)  
	end

	# the value at the slice point, P(x[i,j], y[i,j], z[i, j)), is the
	# interpolated value of the two nearest voxels on the same vertical
	if (isa(GI, GMTimage))
		sc = fill(UInt8(255), r, c)
		for idx in CartesianIndices(z) 
			s = floor(Int, z[idx])
			if 0 <= z[idx] <= h-1
				t = z[idx] - s
				tt = (1-t) * GI[idx, s+1] + t * GI[idx, s+2]
				sc[idx] = tt < 0 ? 0 : (tt > 255 ? 255 : round(UInt8,tt))
			end
		end
		I = mat2img(sc, GI)
		if (!isempty(cmap))  I.colormap, I.labels, I.n_colors = cpt2cmap(cmap)
		else                 I.colormap, I.labels, I.n_colors = zeros(Int32,3), String[], 0	# Do not inherit this from GI
		end
		return mat2grid(z, GI), I
	else
		sc = similar(z) 	#surfacecolor
		for idx in CartesianIndices(z) 
			s = floor(Int, z[idx])
			if 0 <= z[idx] <= h-1
				t = z[idx] - s
				sc[idx] = (1-t) * GI[idx, s+1] + t * GI[idx, s+2]
			else
				sc[idx] = NaN
			end
		end
		return mat2grid(z, GI), mat2grid(sc, GI)
	end
end

const cubeslice = slicecube		# I'm incapable of remembering which one it is.

# ---------------------------------------------------------------------------------------------------
"""
    Gs = squeeze(G::GMTgrid) -> GMTgrid

Remove singleton dimension from a grid. So far only for vertical slices of 3D grids.
"""
function squeeze(G::GMTgrid)
	dims = size(G)
	if ((ind = findfirst(dims .== 1)) !== nothing)
		which_x = (length(G.x) > 1) ? G.x : G.y		# Rather than relying in mem_layout, pick the non-singleton vector
		(ind == 1) && return mat2grid(reshape(G.z, dims[2], dims[3]), x=which_x, y=G.v, reg=G.registration, layout="TRB", is_transposed=true)
		(ind == 2) && return mat2grid(reshape(G.z, dims[1], dims[3]), x=which_x, y=G.v, reg=G.registration, layout="TRB", is_transposed=true)
	end
end

# ---------------------------------------------------------------------------------------------------
"""
    xyzw2cube(fname::AbstractString; zcol::Int=4, datatype::DataType=Float32, proj4::String="", wkt::String="",
	          epsg::Int=0, tit::String="", names::Vector{String}=String[], varnames::Vector{String}=String[])
or

    xyzw2cube(D::GMTdataset; zcol::Int=4, datatype::DataType=Float32, tit::String="",
	          names::Vector{String}=String[], varnames::Vector{String}=String[])

Convert data table containing a cube into a GMTgrid cube. The input data must contain a completelly filled
3D matrix and the data layout is guessed from file analysis (if it fails ... bad chance). 

### Parameters
  - `fname`: The filename of the cube in text format
  - `datatype`:  The data type where the data will be stored. The default is Float32.
  - `tit`:  A title string to describe this cube.
  - `proj4`:  A proj4 string for dataset SRS.
  - `wkt`:  Projection given as a WKT SRS.
  - `epsg`: Same as `proj` but using an EPSG code
  - `names`: used to give a description for each layer (also saved to file when using a GDAL function).
  - `varnames`: A string vector with the names of the variables in the cube. By default we get those from the
    column names (when available). Example: `varnames=["lon", "lat", "depth", "temp"]`.	
  - `zcol`: The column number where the z values are stored. The default is 4. Use a higher number if the
    data set has more than 4 columns and you want to use one of those last columns as z values.

### Returns
A GMTgrid cube object.
"""
function xyzw2cube(fname::AbstractString; zcol::Int=4, datatype::DataType=Float32, proj4::String="",
	wkt::String="", epsg::Int=0, tit::String="", names::Vector{String}=String[], varnames::Vector{String}=String[])
	# Convert a cube stored in a text file into GMTgrid (cube).

	xy = gmtread(fname, data=true, i="0,1")
	mima_X, mima_Y = xy.bbox[1:2], xy.bbox[3:4]
	xy_colnames = (!isempty(xy.colnames) && !startswith(xy.colnames[1], "col")) ? xy.colnames : String[]

	dx, n, rowmajor = helper1_xyzw2grid(view(xy, :,1))
	n_cols = round(Int, (mima_X[2] - mima_X[1]) / dx) + 1
	dy, _, colmajor = helper1_xyzw2grid(view(xy, :,2))
	n_rows = round(Int, (mima_Y[2] - mima_Y[1]) / dy) + 1

	xy = gmtread(fname, data=true, i="2,$(zcol-1)")
	cube, v = helper2_xyzw2grid(view(xy, :,1), view(xy, :,2), n, n_rows, n_cols, rowmajor, colmajor, datatype)
	x_unit, y_unit, v_unit, z_unit = helper3_xyzw2grid(varnames, xy_colnames, xy.colnames, proj4, wkt, epsg)

	mat2grid(cube, linspace(mima_X[1],mima_X[2],n_cols), linspace(mima_Y[1],mima_Y[2],n_rows), v; proj4=proj4, wkt=wkt, epsg=epsg, tit=tit, names=names, x_unit=x_unit, y_unit=y_unit, v_unit=v_unit, z_unit=z_unit)
end

# Version with a GMTdataset
function xyzw2cube(D::GMTdataset; zcol::Int=4, datatype::DataType=Float32, tit::String="",
                   names::Vector{String}=String[], varnames::Vector{String}=String[])

	(size(D,2) < 4) && error("The dataset must contain at least 4 columns (x,y,z,w)")
	mima_X, mima_Y = D.bbox[1:2], D.bbox[3:4]
	xy_colnames = (!isempty(D.colnames) && !startswith(D.colnames[1], "col")) ? D.colnames[1:2] : String[]
	wz_colnames = (!isempty(D.colnames) && !startswith(D.colnames[1], "col")) ? [D.colnames[3], D.colnames[zcol]] : String[]

	dx, n, rowmajor = helper1_xyzw2grid(view(D, :,1))
	n_cols = round(Int, (mima_X[2] - mima_X[1]) / dx) + 1
	dy, _, colmajor = helper1_xyzw2grid(view(D, :,2))
	n_rows = round(Int, (mima_Y[2] - mima_Y[1]) / dy) + 1

	cube, v = helper2_xyzw2grid(view(D, :,3), view(D, :,zcol), n, n_rows, n_cols, rowmajor, colmajor, datatype)
	x_unit, y_unit, v_unit, z_unit = helper3_xyzw2grid(varnames, xy_colnames, wz_colnames, D.proj4, D.wkt, D.epsg)

	mat2grid(cube, linspace(mima_X[1],mima_X[2],n_cols), linspace(mima_Y[1],mima_Y[2],n_rows), v; proj4=D.proj4, wkt=D.wkt, epsg=D.epsg, tit=tit, names=names, x_unit=x_unit, y_unit=y_unit, v_unit=v_unit, z_unit=z_unit)
end

function helper1_xyzw2grid(x)
	n = length(x)
	d = x[2] - x[1]
	(d != 0) && return d, n, true
	k = 1
	while (x[k] == x[k+=1]) end
	d = x[k] - x[k-1]
	(d != 0) && return d, n, false
end

function helper2_xyzw2grid(w,z, n, n_rows, n_cols, rowmajor, colmajor, datatype)
	t = n / (n_rows * n_cols)
	frac = getdecimal(t)		# Get the fractional/decimal part of t 
	(frac != 0.) && error("This file does not have the full 3D elements. Implementation for this is not yet ... implemented.")
	n_levs = Int(t)
	v = zeros(n_levs)
	for k = 1:n_levs-1
		v[k] = w[k * (n_rows * n_cols)]
	end
	v[end] = w[end]		# We didn't compute v[end] in the for loop
	levmajor = ((w[2] - w[1]) != 0)		#Is it 'level-major'?

	cube = Array{datatype,3}(undef, n_rows, n_cols, n_levs)
	j = 0
	if (rowmajor && !levmajor)
		for k = 1:n_levs, m = 1:n_rows, n = 1:n_cols
			cube[m,n,k] = z[j+=1]
		end
	elseif (colmajor && !levmajor)
		for k = 1:n_levs, n = 1:n_cols, m = 1:n_rows
			cube[m,n,k] = z[j+=1]
		end
	else			# Must be level-major
		if (rowmajor)
			for m = 1:n_rows, n = 1:n_cols, k = 1:n_levs
				cube[m,n,k] = z[j+=1]
			end
		else
			for n = 1:n_cols, m = 1:n_rows, k = 1:n_levs
				cube[m,n,k] = z[j+=1]
			end
		end
	end
	return cube, v
end

function helper3_xyzw2grid(varnames, xy_colnames, wz_colnames, proj4, wkt, epsg)
	# Seek for the names/units of the x, y, w and z variables
	if (isgeog(proj4) || isgeog(wkt) || isgeog(epsg))
		x_unit, y_unit = "lon", "lat"
	else
		x_unit = (length(varnames) > 0) ? varnames[1] : !isempty(xy_colnames) ? xy_colnames[1] : ""
		y_unit = (length(varnames) > 1) ? varnames[2] : !isempty(xy_colnames) ? xy_colnames[2] : ""
	end
	v_unit = (length(varnames) > 2) ? varnames[3] : !isempty(wz_colnames) ? wz_colnames[1] : ""
	z_unit = (length(varnames) > 3) ? varnames[4] : !isempty(wz_colnames) ? wz_colnames[2] : ""
	return x_unit, y_unit, v_unit, z_unit
end

# ---------------------------------------------------------------------------------------------------
"""
    stackgrids(names::Vector{String}, v=nothing; zcoord=nothing, zdim_name="time",
	           z_unit="", save="", mirone=false)

Stack a bunch of single grids in a multiband cube like file.

- `names`: A string vector with the names of the grids to stack
- `v`: A vector with the vertical coordinates. If not provided, one with 1:length(names) will be generated.
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
			v = yeardecimal.(v);					z_unit = "Decimal year"
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

	#G = gmtread(names[1], grid=true)	# reading with GDAL f screws sometimes with the "is not a Latitude/Y dimension."
	#x, y, range, inc = G.x, G.y, G.range, G.inc		# So read first with GMT anf keep only the coords info.
	G = gdaltranslate(names[1])
	x, y, range, inc = G.x, G.y, G.range, G.inc
	mat = Array{eltype(G), 3}(undef, size(G,1), size(G,2), length(names))
	mat[:,:,1] .= G.z
	for k = 2:length(names)
		G = gdaltranslate(names[k])
		mat[:,:,k] .= G.z
	end
	cube = mat2grid(mat, G)
	cube.x = x;		cube.y = y;		cube.range = range;		cube.inc = inc
	cube.z_unit = z_unit
	isempty(_v) && (_v = collect(linspace(range[5], range[6], size(cube, 3))))
	(eltype(_v) == String) ? append!(cube.range, [0., 1.]) : append!(cube.range, [_v[1], _v[end]])
	cube.names = names;		cube.v = _v
	(save != "") && gdalwrite(cube, save, _v, dim_name=zdim_name)
	return (save != "") ? nothing : cube
end

# ---------------------------------------------------------------------------------------------------
"""
    I = image_alpha!(img::GMTimage; alpha_ind::Integer, alpha_vec::Vector{Integer}, alpha_band::UInt8, burn=false)

Change the alpha transparency of the GMTimage object `img`. If the image is indexed, one can either
change just the color index that will be made transparent by using `alpha_ind=n` or provide a vector
of transaparency values in the range [0 255]; This vector can be shorter than the orginal number of colors.
Use `alpha_band` to change, or add, the alpha of true color images (RGB).

- `burn`: The background color to be used in the compositing. It can be a 3-tuple of integers in the range [0 255]
   or a symbol or string that will a color name. _e.g._, `bg=:blue`. The default is `:white`. This option
   is only usable for true color images and `alpha_band`. Then instead of adding the alpha band, that band is
   used to replace or compose (when the alpha_band values are variable to other than 0 or 255) the background color.

### Examples
```jldoctest
# Example1: change to the third color in cmap to represent the new transparent color
julia> image_alpha!(img, alpha_ind=3)

#Example2: change to the first 6 colors in cmap by assigning them random values
julia> image_alpha!(img, alpha_vec=round.(Int32,rand(6).*255))

# Burn the red color in a random image
julia> img = mat2img(rand(UInt8, 750, 750, 3));
julia> mask = rand(Bool, 750, 750);
julia> image_alpha!(img, alpha_band=mask, burn=:red);
```
"""
function image_alpha!(img::GMTimage; alpha_ind=nothing, alpha_vec::Vector{<:Integer}=Int[], alpha_band=nothing, burn=false)
	# Change the alpha transparency of an image
	n_colors = img.n_colors
	if (n_colors > 100000)  n_colors = Int(floor(n_colors / 1000))  end
	if (alpha_ind !== nothing)			# Change the index of the alpha color
		(alpha_ind < 0 || alpha_ind > 255) && error("Alpha color index must be in the [0 255] interval")
		#img.n_colors = n_colors * 1000 + Int32(alpha_ind)
		n_col = div(length(img.colormap), n_colors)
		(n_col == 3) && (img.colormap = [img.colormap; fill(Int32(255), n_colors)])		# If only Mx3, add a 4rth column
		img.colormap[3*n_colors + alpha_ind] = 0
	elseif (!isempty(alpha_vec))		# Replace/add the alpha column of the colormap matrix. Allow also shorter vectors
		(length(alpha_vec) > n_colors) && error("Length of alpha vector is larger than the number of colors")
		n_col = div(length(img.colormap), n_colors)
		vec = convert.(Int32, alpha_vec)
		if (n_col == 4)  img.colormap[(end-length(vec)+1):end] = vec;
		else             img.colormap = [img.colormap; [vec[:]; round.(Int32, ones(n_colors - length(vec)) .* 255)]]
		end
		img.n_colors = n_colors * 1000
	elseif (alpha_band !== nothing)		# Replace the entire alpha band
		@assert (eltype(alpha_band) == UInt8 || eltype(alpha_band) == Bool) "Alpha band must be a UInt8 or Bool array"
		helper_alpha!(img, alpha_band)
		(size(img.image, 3) != 3) && (@warn("Adding alpha band is restricted to true color images (RGB)"); return nothing)
		alfa = (isa(alpha_band, GMTimage)) ? alpha_band.image : alpha_band
		bg = (burn == 1) ? (255.0, 255.0, 255.0) : burn
		(burn != 0) ? burn_alpha!(img, alfa, bg=bg) : (img.alpha = (eltype(alfa) == UInt8) ? alfa : reinterpret(UInt8, alfa))
	end
	return nothing
end

"""
    burn_alpha!(img::GMTimage{<:UInt8, 3}, alpha; bg=:white)

Burn the alpha channel into the image by compositing the image values with the background color at locations where alpha is non-zero.

- `img`: The RGB image to be modified by the alpha channel.
- `alpha`: A GMTimage or a matrix of uint8/boolean values indicating the locations where the corresponding locations
   in the image should be burned. All non-zero values will be used to composite the image with the background color.
   For example, a value of 255 will replace a pixel by the background color, a value of 127 will compose the image
   and background witha weight of 50% each.
- `bg`: The background color to be used in the compositing. It can be a 3-tuple of integers in the range [0 255]
   or a symbol or string that will a color name. _e.g._, `bg=:blue`. The default is `:white`.

"""
burn_alpha!(img::GMTimage{<:UInt8, 3}, alpha::Matrix{Bool}; bg=:white) = burn_alpha!(img, reinterpret(UInt8, alpha); bg=bg)
function burn_alpha!(img::GMTimage{<:UInt8, 3}, alpha::Matrix{UInt8}; bg=:white)
	helper_alpha!(img, alpha)			# Error if sizes of img and alpha do not match.
	!(isa(bg, Symbol) || isa(bg, String) || isa(bg, Tuple{Real,Real,Real})) && error("Invalid background color specification")

	bg_r, bg_g, bg_b = 255.0, 255.0, 255.0		# Background color
	if (isa(bg, Symbol) || isa(bg, String))
		rgb = [0.0, 0.0, 0.0]
		(gmt_getrgb(G_API[1], string(bg), rgb) != 0) && return nothing		# A GMT error was printed already
		bg_r, bg_g, bg_b = rgb[1]*255, rgb[2]*255, rgb[3]*255
	elseif isa(bg, Tuple)
		bg_r, bg_g, bg_b = Float64(bg[1]), Float64(bg[2]), Float64(bg[3])
	end

	u255 = UInt8(255)
	nm = numel(alpha)
	un = unique(alpha)
	if (numel(un) == 2 && un[2] == 255)
		u_r, u_g, u_b = round(UInt8, bg_r), round(UInt8, bg_g), round(UInt8, bg_b)
		@inbounds for k = 1:nm
			alpha[k] == u255 && continue
			img.image[k], img.image[k+=nm], img.image[k+=nm] = u_r, u_g, u_b
		end
	else
		@inbounds for k = 1:nm
			alpha[k] == u255 && continue
			o = alpha[k] / 255;		t = 1.0 - o;
			img.image[k] = round(UInt8, o * img.image[k] + t * bg_r)
			img.image[k+=nm] = round(UInt8, o * img.image[k] + t * bg_g)
			img.image[k+=nm] = round(UInt8, o * img.image[k] + t * bg_b)
		end
	end
end

function helper_alpha!(img, alpha_band)
	ny1, nx1, = size(img.image)
	ny2, nx2  = size(alpha_band)
	(ny1 != ny2 || nx1 != nx2) && error("alpha channel has wrong dimensions ($(size(alpha_band)) != $(size(img.image)))")
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    image_cpt!(img::GMTimage, cpt::GMTcpt, clear=false)
or

    image_cpt!(img::GMTimage, cpt::String, clear=false)

Add (or replace) a colormap to a GMTimage object from the colors in the cpt.
This should have effect only if IMG is indexed.
Use `image_cpt!(img, clear=true)` to remove a previously existant `colormap` field in IMG
"""
image_cpt!(I::GMTimage, cpt::String) = image_cpt!(I, gmtread(cpt))
function image_cpt!(I::GMTimage, cpt::GMTcpt)
	# Insert the cpt info in the img.colormap member
	(cpt.categorical > 0 && I.range[5] == 1 && isnan(I.nodata)) && (I.nodata = 0.0)
	I.colormap, I.labels, I.n_colors = cpt2cmap(cpt, I.nodata)
	I.color_interp = "Palette"
	return nothing
end
function image_cpt!(img::GMTimage; clear::Bool=true)
	if (clear)
		img.colormap, img.labels, img.n_colors, img.color_interp = fill(Int32(0), 3), String[], 0, "Gray"
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    I = ind2rgb(I::GMTimage, cpt::GMTcpt=GMTcpt(), layout="BRPa"; cmap=GMTcpt())

Convert an indexed image I to RGB. If `cmap` is not provided, it uses the internal colormap to do the conversion.
If neither them exists, the layer is replicated 3 times thus resulting in a gray scale image.

Use the `cmap` keyword in alternative to the `cpt` positional variable. 
"""
function ind2rgb(I::GMTimage, cpt::GMTcpt=GMTcpt(), layout="BRPa"; cmap::GMTcpt=GMTcpt())
	(size(I.image, 3) >= 3) && return I 		# Image is already RGB(A)

	(isempty(cpt) && isa(cmap, Symbol) || isa(cmap, String)) && (cpt = makecpt(I.range[6]-I.range[5]+1, C=cmap))

	# If the CPT is shorter them maximum in I, reinterpolate the CPT
	(!isempty(cpt) && (ma = maximum(I.image)) > size(cpt.colormap,1)) && (cpt = gmt("makecpt -T0/{$ma}/+n{$ma}", cpt))
	_cmap = (!isempty(cpt)) ? cpt2cmap(cpt::GMTcpt, I.nodata)[1] : I.colormap

	have_alpha = (length(I.colormap) / I.n_colors) == 4 && !all(I.colormap[end-Int(I.n_colors/4+1):end] .== 255)
	if (I.n_colors == 0 && isempty(cpt))		# If no cmap just replicate the first layer.
		imgRGB = repeat(I.image, 1, 1, 3)
		layout = I.layout
	else
		imgRGB = Array{UInt8,3}(undef, size(I,1), size(I,2), 3+have_alpha)
		n = 0
		if (startswith(I.layout, "BRP") && startswith(layout, "BRP"))
			jp1, jp2, jp3, jp4 = 1, I.n_colors + 1, 2 * I.n_colors + 1, 3 * I.n_colors + 1
			for k in eachindex(I.image)
				imgRGB[n+=1] = _cmap[I.image[k] + jp1]
				imgRGB[n+=1] = _cmap[I.image[k] + jp2]
				imgRGB[n+=1] = _cmap[I.image[k] + jp3]
				have_alpha && (imgRGB[n+=1] = _cmap[I.image[k] + jp4])
			end
		else
			layout = (I.layout[2] == 'R') ? I.layout : "TCBa"
			img    = (I.layout[2] == 'R') ? I.image  : I.image'
			for c = 1:3+have_alpha
				start_c = (c - 1) * I.n_colors + 1		# +1 because indices start a 1
				for k in eachindex(I.image)
					imgRGB[n+=1] = _cmap[img[k] + start_c];
				end
			end
		end
	end
	istransposed = (dims(I)[1] != size(I, 1)) ? true : false
	mat2img(imgRGB, x=I.x, y=I.y, proj4=I.proj4, wkt=I.wkt, mem_layout=layout, is_transposed=istransposed)
end

# ----------------------------------------------------------------------------------------------------------
"""
    I = grays2rgb(bandR, bandG, bandB, GI=nothing) -> GMTimage

Take three grayscale images as UInt8 matrices or GMTimages and compose an RGB image by simply copying
the values of each band into the respective color channel of the output image. When the inputs are UInt8
matrices optionally provide a GMTgrid or GMTimage as fourth argument to set georeferencing info on output.
The output is always a GMTimage object.

Note, do not confuse this function with `ind2rgb` that takes a single indexed image and creates a RGB
using the image's colormap.

### Example
```juliadoc
I1 = mat2img(rand(UInt8, 16,16)); I2 = mat2img(rand(UInt8, 16,16)); I3 = mat2img(rand(UInt8, 16,16));
Irgb = grays2rgb(I1,I2,I3)
```
"""
function grays2rgb(bandR::GMTimage{UInt8,2}, bandG::GMTimage{UInt8,2}, bandB::GMTimage{UInt8,2})
	@assert size(bandR) == size(bandG) == size(bandB)
	img = Array{UInt8}(undef, size(bandR,1), size(bandR,2), 3)
	img[:,:,1] .= bandR.image;		img[:,:,2] .= bandG.image;		img[:,:,3] .= bandB.image
	mat2img(img, bandR)
end
function grays2rgb(bandR::Matrix{UInt8}, bandG::Matrix{UInt8}, bandB::Matrix{UInt8}, GI::Union{GItype, Nothing}=nothing)
	@assert size(bandR) == size(bandG) == size(bandB)
	img = Array{UInt8}(undef, size(bandR,1), size(bandR,2), 3)
	img[:,:,1] .= bandR;		img[:,:,2] .= bandG;		img[:,:,3] .= bandB
	return GI !== nothing ? mat2img(img, GI) : mat2img(img)
end

# ---------------------------------------------------------------------------------------------------
"""
    [I =] grays2cube(layers::GMTimage{UInt8,2}...; names::Vector{String}=String[], save::String="") -> GMTimage

Take N grayscale UInt8 GMTimages and agregate them into an image cube. Optionally provide a vector of names for each layer.
If the `save` option is provided, we save the cube as a GeoTIFF file. Note, no need to provide an extension as the
output name will always be '*.tiff'.

### Example
```juliadoc
# Make a cube with the Cb, Cr, a* and b* comonents of YCbCR & La*b* color spaces of an RGB image
I = mat2image(rand(UInt8,128, 128, 3))		# Create sample RGB image
_,Cb,Cr = rgb2YCbCr(I, Cb=true, Cr=true);	# Extract Cb and Cr components
L,a,b   = rgb2lab(I, L=true);				# Extract La*b* components
Icube = grays2cube(Cb, Cr, a, b; names=["Cb", "Cr", "a", "b"]);
```
"""
function grays2cube(layers::GMTimage{UInt8,2}...; names::Vector{String}=String[], save::String="")
	I = mat2grid(cat(layers..., dims=3), layers[1])
	length(names) == size(I,3) && (I.names = names)
	length(names) != 0 && length(names) != size(I,3) && @warn("Number of names must match number of layers. Ignoring names request.")
	if (save != "")
		save = splitext(save)[1]			# Drop extension if provided to make it always be .tiff
		return gdaltranslate(cube, dest=save * "tiff")
	end
	I
end

# ---------------------------------------------------------------------------------------------------
"""
    G = mat2grid(mat; reg=nothing, x=[], y=[], v=[], hdr=[], proj4::String="", wkt::String="",
                 title::String="", rem::String="", cmd::String="", names::Vector{String}=String[],
                 scale::Float32=1f0, offset::Float32=0f0, eqc=false)

Take a 2/3D `mat` array and a HDR 1x9 [xmin xmax ymin ymax zmin zmax reg xinc yinc] header descriptor and 
return a grid GMTgrid type. Alternatively to HDR, provide a pair of vectors, `x` & `y`, with the X and Y coordinates.
Optionally add a `v` vector with vertical coordinates if `mat` is a 3D array and one wants to create a ``cube``.
Optionally, the HDR arg may be omitted and it will computed from `mat` alone, but then x=1:ncol, y=1:nrow
When HDR is not used, REG == nothing [default] means create a gridline registration grid and REG = 1,
or REG="pixel" a pixel registered grid.

- `eqc`: If true, it means we got a matrix representing a Equidistant Cylindrical projection but with no coords.
  The output grid will have global coordinates between [-180 180] and [-90 90]. The xinc and yinc will be computed
  from the `mat` size and and a guess of the registration type based on the if dims are even (pixel) or odd (grid).
  Override the registration guessing with the `reg` option. For non Earth bodies user must specify a `proj4` option.

For 3D arrays the `names` option is used to give a description for each layer (also saved to file when using a GDAL function).

The `scale` and `offset` options are used when `mat` is an Integer type and we want to save the grid with a scale/offset.  

Other methods of this function do:

    G = mat2grid(val=0.0f; hdr=hdr_vec, reg=0, proj4::String="", wkt::String="", title::String="", rem::String="")

Create Float GMTgrid with size, coordinates and increment determined by the contents of the HDR var. This
array, which is now MANDATORY, has either the same meaning as above OR, alternatively, containing only
[xmin xmax ymin ymax xinc yinc]
VAL is the value that will be fill the matrix (default VAL = Float32(0)). To get a Float64 array use, for
example, VAL = 1.0 Any other non Float64 will be converted to Float32

    Example: mat2grid(1, hdr=[0. 5 0 5 1 1])

    G = mat2grid(f::Function, x, y; reg=nothing, proj4::String="", wkt::String="", epsg::Int=0, title::String="", rem::String="")

Where F is a function and X,Y the vectors coordinates defining it's domain. Creates a Float32 GMTgrid with
size determined by the sizes of the X & Y vectors.

    Example: f(x,y) = x^2 + y^2;  G = mat2grid(f, x = -2:0.05:2, y = -2:0.05:2)

    G = mat2grid(f::String)

Where f is a pre-set function name. Currently available:
   - "ackley", "eggbox", "sombrero", "parabola" and "rosenbrock" 
X,Y are vectors coordinates defining the function's domain, but default values are provided for each function.
creates a Float32 GMTgrid.

    Example: G = mat2grid("sombrero")
"""
function mat2grid(val::Real=Float32(0); reg=nothing, hdr=Float64[], proj4::String="", proj::String="",
                  wkt::String="", epsg::Int=0, geog::Int=-1, title::String="", tit::String="", rem::String="",
                  names::Vector{String}=String[], x_unit::String="", y_unit::String="", v_unit::String="",
				  z_unit::String="")

	isempty(hdr) && error("When creating grid type with no data the 'hdr' arg cannot be missing")
	(eltype(hdr) != Float64) && (hdr = Float64.(hdr))
	(!isa(val, AbstractFloat)) && (val = Float32(val))		# We only want floats here
	if (length(hdr) == 6)
		hdr = [hdr[1], hdr[2], hdr[3], hdr[4], val, val, reg === nothing ? 0. : 1., hdr[5], hdr[6]]
	end
	(isempty(proj4) && !isempty(proj)) && (proj4 = proj)	# Allow both proj4 or proj keywords
	(tit == "") && (tit = title)		# Some versions from 1.2 remove 'tit'
	mat2grid([nothing val]; reg=reg, hdr=hdr, proj4=proj4, wkt=wkt, epsg=epsg, geog=geog, tit=tit, rem=rem, cmd="", names=names)
end

# This is the way I found to find if a matrix is transposed. There must be better ways but couldn't find them.
istransposed(mat) = !isempty(fields(mat)) && (fields(mat)[1] == :parent)

mat2grid(mat, xx, yy, zz=Float64[];
         reg=nothing, hdr=Float64[], proj4::String="", proj::String="", wkt::String="", epsg::Int=0, geog::Int=-1, title::String="", tit::String="", rem::String="", cmd::String="", names::Vector{String}=String[], scale::Real=1f0, offset::Real=0f0, layout::String="", is_transposed::Bool=false, x_unit::String="", y_unit::String="", v_unit::String="", z_unit::String="") =
	mat2grid(mat; x=xx, y=yy, v=zz, reg=reg, hdr=hdr, proj4=proj4, proj=proj, wkt=wkt, epsg=epsg, geog=geog,
	         title=title, tit=tit, rem=rem, cmd=cmd, names=names, scale=scale, offset=offset, layout=layout, is_transposed=is_transposed, x_unit=x_unit, y_unit=y_unit, v_unit=v_unit, z_unit=z_unit)

function mat2grid(mat; reg=nothing, x=Float64[], y=Float64[], v=Float64[], hdr=Float64[], proj4::String="", proj::String="",
                  wkt::String="", epsg::Int=0, geog::Int=-1, title::String="", tit::String="", rem::String="", cmd::String="",
                  names::Vector{String}=String[], scale::Real=1f0, offset::Real=0f0, layout::String="", is_transposed::Bool=false,
                  x_unit::String="x", y_unit::String="y", v_unit::String="v", z_unit::String="z", eqc=false)

	israsters(mat) && return rasters2grid(mat, scale=scale, offset=offset)
	(fields(mat) == (:x, :y, :density)) && return kde2grid(mat)		# A KernelDensity type
	(isempty(proj4) && !isempty(proj)) && (proj4 = proj)	# Allow both proj4 or proj keywords
	if (!isempty(proj4) && !startswith(proj4, "+proj=") && !startswith(proj4, "proj="))
		proj4 = "+proj=" * proj4		# NOW I SHOULD TEST THIS IS A VALID PROJ4 STRING. BUT HOW?
	end
	reg_ = 0
	if (isa(reg, String) || isa(reg, Symbol))
		t = lowercase(string(reg))
		reg_ = (t != "pixel") ? 0 : 1
	elseif (isa(reg, Real))
		reg_ = (reg == 0) ? 0 : 1
	end

	# Check case where we got a matrix representing a Equidistant Cylindrical projection but no coords
	(eqc != 0 && (!isempty(x) || !isempty(hdr))) && @warn "eqc=true but x or hdr are not empty. Ignoring eqc=true"
	if (eqc != 0 && isempty(x) && isempty(hdr))
		n_rows, n_cols, = size(mat)
		# The default here is pixel registration when the matrix is of even size, or grid reg otherwise
		(reg === nothing) && (iseven(n_rows) && iseven(n_cols) ? (reg_ = 1) : (reg_ = 0))
		x_inc = 360.0 / (n_cols - (reg_ == 1));		y_inc = 180.0 / (n_rows - (reg_ == 1))
		mima = extrema_nan(mat)
		hdr = [-180.0, 180.0, -90.0, 90.0, mima[1], mima[2], reg_, x_inc, y_inc]
		geog = 1
		(proj4 == "") && (proj4 = prj4WGS84)
	end
	x, y, hdr, x_inc, y_inc = grdimg_hdr_xy(mat, reg_, hdr, x, y, is_transposed)

	# Now we still must check if the method with no input MAT was called. In that case mat = [nothing val]
	# and the MAT must be finally computed.
	nx = size(mat, 2);		ny = size(mat, 1);
	if (ny == 1 && nx == 2 && mat[1] === nothing)
		fill_val = mat[2]
		mat = zeros(eltype(fill_val), length(y), length(x))
		(fill_val != 0) && fill!(mat, fill_val)
	end

	isT = istransposed(mat)			# Checks if mat is of a transposed type (not if the array is transposed).
	if (ndims(mat) == 2)
		inc, range = [x_inc, y_inc], hdr[1:6]
	else
		(length(v) <= 1) && (v = collect(linspace(hdr[5], hdr[6], size(mat,3))))	# We need a v vector
		inc, range = [x_inc, y_inc, v[2] - v[1]], [vec(hdr[1:6]); [v[1], v[end]]]
	end
	hasnans = any(!isfinite, mat) ? 2 : 1
	_layout = (layout == "") ? "BCB" : layout
	(geog == -1 && helper_geod(proj4, wkt, epsg, false)[3]) && (geog = (range[2] <= 180) ? 1 : 2)	# Signal if grid is geog.
	(tit == "") && (tit = title)		# Some versions from 1.2 remove 'tit'
	GMTgrid(proj4, wkt, epsg, geog, range, inc, reg_, NaN, tit, rem, cmd, "", names, vec(x), vec(y), vec(v), isT ? copy(mat) : mat, x_unit, y_unit, v_unit, z_unit, _layout, scale, offset, 0, hasnans)
end

# This method creates a new GMTgrid but retains all the header data from the GI object
function mat2grid(mat::Array{T,N}, GI::GItype) where {T,N}
	isT = istransposed(mat)
	hasnans = any(!isfinite, mat) ? 2 : 1
	x_unit, y_unit, v_unit, z_unit = isa(GI, GMTgrid) ? (GI.x_unit, GI.y_unit, GI.v_unit, GI.z_unit) : ("", "", "", "")
	Go = GMTgrid(GI.proj4, GI.wkt, GI.epsg, GI.geog, copy(GI.range), copy(GI.inc), GI.registration, NaN, "", "", "", "", String[], copy(GI.x), copy(GI.y), [0.], isT ? copy(mat) : mat, x_unit, y_unit, v_unit, z_unit, GI.layout, 1f0, 0f0, GI.pad, hasnans)
	(length(Go.layout) == 4) && (Go.layout = Go.layout[1:3])	# No space for the a|A
	setgrdminmax!(Go)		# Also take care of NaNs
	Go
end

mat2grid(f::Function, xx::AbstractVector{<:Float64}, yy::AbstractVector{<:Float64}; reg=nothing, proj4::String="", proj::String="", wkt::String="", epsg::Int=0, tit::String="", rem::String="") =
	mat2grid(f; x=xx, y=yy, reg=reg, proj4=proj4, proj=proj, wkt=wkt, epsg=epsg, tit=tit, rem=rem)

function mat2grid(f::Function; reg=nothing, x::AbstractVector{<:Float64}=Float64[], y::AbstractVector{<:Float64}=Float64[], proj4::String="", proj::String="", wkt::String="", epsg::Int=0, tit::String="", rem::String="")
	(isempty(x) || isempty(y)) && error("Must transmit the domain coordinates over which to calculate function.")
	(isempty(proj4) && !isempty(proj)) && (proj4 = proj)	# Allow both proj4 or proj keywords
	z = Array{Float32,2}(undef, length(y), length(x))
	for i in eachindex(x), j in eachindex(y)
		z[j,i] = f(x[i], y[j])
	end
	mat2grid(z; reg=reg, x=x, y=y, proj4=proj4, wkt=wkt, epsg=epsg, tit=tit, rem=rem)
end

mat2grid(f::String, xx::AbstractVector{<:Float64}, yy::AbstractVector{<:Float64}) = mat2grid(f; x=xx, y=yy)
function mat2grid(f::String; x::AbstractVector{<:Float64}=Float64[], y::AbstractVector{<:Float64}=Float64[])
	if (startswith(f, "ack"))				# Ackley (inverted) https://en.wikipedia.org/wiki/Ackley_function
		f_ack(x,y) = 20 * exp(-0.2 * sqrt(0.5 * (x^2 + y^2))) + exp(0.5*(cos(2pi*x) + cos(2pi*y))) - 22.718281828459045
		if (isempty(x))  x = -5:0.05:5;	y = -5:0.05:5;  end
		mat2grid(f_ack, x, y)
	elseif (startswith(f, "egg"))
		f_egg(x, y) = (sin(x*10) + cos(y*10)) / 4
		if (isempty(x))  x = -1:0.01:1;	y = -1:0.01:1;  end
		mat2grid(f_egg, x, y)
	elseif (startswith(f, "circ"))
		if (isempty(x))  x = -1:0.01:1;	y = -1:0.01:1;  end
		mat2grid((x,y) -> sqrt(x^2 + y^2), x, y)
	elseif (startswith(f, "para"))
		if (isempty(x))  x = -2:0.02:2;	y = -2:0.02:2;  end
		mat2grid((x,y) -> x^2 + y^2, x, y)
	elseif (startswith(f, "rosen"))			# rosenbrock
		f_rosen(x,y) = (1 - x)^2 + 100 * (y - x^2)^2
		if (isempty(x))  x = -2:0.02:2;	y = -1:0.02:3;  end
		mat2grid(f_rosen, x, y)
	elseif (startswith(f, "somb"))			# sombrero
		f_somb(x,y) = cos(sqrt(x^2 + y^2) * 2pi / 8) * exp(-sqrt(x^2 + y^2) / 10)
		if (isempty(x))  x = -15:0.1:15;	y = -15:0.1:15;  end
		mat2grid(f_somb, x, y)
	elseif (f == "x" || f == "y" || f == "x+y" || f == "x*y" || f == "xy")	# X,Y,XY
		if (isempty(x))  x = -1:0.01:1;	y = -1:0.01:1;  end
		_f(x,y) = (f == "x") ? x : (f == "y") ? -y : (f == "x+y") ? x-y : -x*y
		mat2grid(_f, x, y)
	else
		@warn("Unknown surface '$f'. Just giving you a parabola.")
		mat2grid("para")
	end
end

# ---------------------------------------------------------------------------------------------------
"""
    G = img2grid(I::GMTimage; type=eltype(I.image))

Converts an GMTimage object to a grid. If the `type` option is not set the image data type is preserved
and the array in NOT copied. Otherwise the image data is converted to the specified type and a copy is made.
"""
function img2grid(I::GMTimage; type=eltype(I.image))
	z = (type == eltype(I.image)) ? I.image : convert(Array{type}, I.image)
	GMTgrid(I.proj4, I.wkt, I.epsg, I.geog, copy(I.range), copy(I.inc), I.registration, NaN, "", "", "", "", String[], copy(I.x), copy(I.y), [0.], z, "", "", "", "", I.layout, 1f0, 0f0, I.pad, 1)
end

"""
    I = grid2img(G::GMTgrid{<:Unsigned})

Converts a GMTgrid of type Unsigned into a GMTimage. Data array is not copied nor its type is changed.
"""
function grid2img(G::GMTgrid{<:Unsigned})
	GMTimage(G.proj4, G.wkt, G.epsg, G.geog, copy(G.range), copy(G.inc), G.registration, NaN32, "", String[], String[], copy(G.x), copy(G.y), [0.], G.z, zeros(Int32,3), String[], 0, Array{UInt8,2}(undef,1,1), G.layout, 0)
end

# ---------------------------------------------------------------------------------------------------
function grdimg_hdr_xy(mat, reg, hdr, x=Float64[], y=Float64[], is_transposed=false)
# Generate x,y coords array and compute/update header plus increments for grids/images
# Arrays coming from GDAL are often scanline so they are transposed. In that case is_transposed should be true
	row_dim, col_dim = (is_transposed) ? (2,1) : (1,2) 
	nx = size(mat, col_dim);		ny = size(mat, row_dim);

	if (!isempty(x) && !isempty(y))		# But not tested if they are equi-spaced as they MUST be
		if ((length(x) != (nx+reg) || length(y) != (ny+reg)) && (length(x) != 2 || length(y) != 2))
			(length(x) != (nx+reg)) && @warn("length x = $(length(x))  nx = $nx, registration = $reg")
			(length(y) != (ny+reg)) && @warn("length y = $(length(y))  ny = $ny, registration = $reg")
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
		x_inc = (x[end] - x[1]) / (nx - one_or_zero);	isnan(x_inc) && (x_inc = 0.0)	# When vertical slices
		y_inc = (y[end] - y[1]) / (ny - one_or_zero);	isnan(y_inc) && (y_inc = 0.0)
		zmin::Float64, zmax::Float64 = extrema_nan(mat)
		hdr = Float64.([x[1], x[end], y[1], y[end], zmin, zmax])
	elseif (isempty(hdr))
		zmin, zmax = extrema_nan(mat)
		if (reg == 0)  x = collect(1.0:nx);		y = collect(1.0:ny)
		else           x = collect(0.5:nx+0.5);	y = collect(0.5:ny+0.5)
		end
		hdr = Float64.([x[1], x[end], y[1], y[end], zmin, zmax])
		x_inc = 1.0;	y_inc = 1.0
	else
		(length(hdr) != 9) && error("The HDR array must have 9 elements")
		(eltype(hdr) != Float64) && (hdr = Float64.(hdr))
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

# ---------------------------------------------------------------------------------------------------
"""
    is_stored_transposed(GI::GItype) -> Bool

Return true if the data in the GMTgrid or GMTimage `GI` is stored transposed or false otherwise.
See more details in the comments of the `gmt2gd` function.
"""
function is_stored_transposed(GI::GItype)
	width, height = (length(GI.x), length(GI.y)) .- GI.registration
	return width == size(GI, 1) && height == size(GI, 2)
end

# ---------------------------------------------------------------------------------------------------
"""
    mksymbol(f::Function, cmd0::String="", arg1=nothing; kwargs...)
"""
function mksymbol(f::Function, cmd0::String="", arg1=nothing; kwargs...)
	# Make a fig and convert it to EPS so it can be used as a custom symbol in plot(3)
	d = KW(kwargs)
	t::String = ((val = find_in_dict(d, [:symbname :symb_name :symbol])[1]) !== nothing) ? string(val) : "GMTsymbol"
	(t == "GMTsymbol" && (f == flower_minho || f == matchbox)) && (t = string(f))
	!haskey(d, :name) && (d[:name] = t * ".eps")
	if (f == flower_minho || f == matchbox)			# Special case for the Flower Minho symbol
		f(; d...)			# If no name provided, use the default one (flower_minho)
	else
		(t == "GMTsymbol") && error("Need to provide a name for the symbol")
		_, name = helper_cusymb(true, t, ".eps", "")
		d[:name] = name * ".eps"
		(is_in_dict(d, [:B :frame :axes :axis :xaxis :yaxis :zaxis :axis2 :xaxis2 :yaxis2]) === nothing) && (d[:frame] = "none")
		f(cmd0, arg1; d...)
	end
	return nothing
end
mksymbol(f::Function, arg1; kw...) = mksymbol(f, "", arg1; kw...)
