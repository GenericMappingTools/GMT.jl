function text_record(data, text, hdr=Vector{String}())
	# Create a text record to send to pstext. DATA is the Mx2 coordinates array.
	# TEXT is a string or a cell array

	(data == []) && (data = [NaN NaN])
	(isa(data, Vector)) && (data = data[:,:]) 		# Needs to be 2D
	#(!isa(data, Array{Float64})) && (data = Float64.(data))

	if (isa(text, String))
		_hdr = isempty(hdr) ? "" : hdr[1]
		T = GMTdataset(data, Float64[], Float64[], Dict{String, String}(), String[], [text], _hdr, String[], "", "", 0, 0)
	elseif (isa(text, Vector{String}))
		if (text[1][1] == '>')			# Alternative (but risky) way of setting the header content
			T = GMTdataset(data, Float64[], Float64[], Dict{String, String}(), String[], text[2:end], text[1], String[], "", "", 0, 0)
		else
			_hdr = isempty(hdr) ? "" : (isa(hdr, Vector{String}) ? hdr[1] : hdr)
			T = GMTdataset(data, Float64[], Float64[], Dict{String, String}(), String[], text, _hdr, String[], "", "", 0, 0)
		end
	elseif (isa(text, Array{Array}) || isa(text, Array{Vector{String}}))
		nl_t = length(text);	nl_d = size(data,1)
		(nl_d > 0 && nl_d != nl_t) && error("Number of data points ($nl_d) is not equal to number of text strings ($nl_t).")
		T = Vector{GMTdataset}(undef,nl_t)
		for k = 1:nl_t
			T[k] = GMTdataset((nl_d == 0 ? fill(NaN, length(text[k]) ,2) : data[k]), Float64[], Float64[], Dict{String, String}(), String[], text[k], (isempty(hdr) ? "" : hdr[k]), Vector{String}(), "", "", 0, 0)
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
     can be an array with same size as `mat` rows or a string (will be reapeated n_rows times.) 
  - `x`:   An optional vector with the _xx_ coordinates
  - `hdr`: optional String vector with either one or n_rows multisegment headers.
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
     This differes from `lt` in the sense that `lt` does not directly set the line thickness.
  - `multi` or `multicol`: When number of columns in `mat` > 2, or == 2 and x != nothing, make an multisegment Dataset
     with first column and 2, first and 3, etc. Convenient when want to plot a matrix where each column is a line. 
  - `segnan` or `nanseg`: Boolean. If true make a multisegment made out of segments separated by NaNs.
  - `datatype`: Keep the original data type of `mat`. Default, converts to Float64.
  - `geom`: The data geometry. By default we set `wkbUnknown` but try to do some basic guess.
  - `proj` or `proj4`:  A proj4 string for dataset SRS.
  - `wkt`:  A WKT SRS.
  - `colnames`: Optional string vector with names for each column of `mat`.
  - `attrib`: Optional dictionary{String, String} with attributes of this dataset.
  - `ref:` Pass in a reference GMTdataset from which we'll take the georeference info as well as `attrib` and `colnames`
  - `txtcol` or `textcol`: Vector{String} with text to add into the .text field. Warning: no testing is done
     to check if ``length(txtcol) == size(mat,1)`` as it must.

###   D = mat2ds(mat::Vector{<:AbstractMatrix}; hdr=String[], kwargs...)::Vector{GMTdataset}

Create a multi-segment GMTdataset (a vector of GMTdataset) from matrices passed in a vector-of-matrices `mat`.
The matrices elements of `mat` do not need to have the same number of rows. Think on this as specifying groups
of lines/points each sharing the same settings. KWarg options of this form are more limitted in number than
in the general case, but can take the form of a Vector{Vector}, Vector or scalars.
In the former case (Vector{Vector}) the length of each Vector[i] must equal to the number of rows of each mat[i].

  - `hdr`: optional String vector with either one or `length(mat)` multisegment headers.
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
mat2ds(mat::Nothing) = mat		# Method to simplify life and let call mat2ds on a nothing
mat2ds(mat::GDtype)  = mat		# Method to simplify life and let call mat2ds on a already GMTdataset
mat2ds(text::Union{AbstractString, Vector{<:AbstractString}}) = text_record(text)	# Now we can hide text_record
#function mat2ds(mat::Matrix{Any}; hdr=String[], geom=0, kwargs...)
function mat2ds(mat::AbstractMatrix; hdr=String[], geom=0, kwargs...)
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

	D = mat2ds(convert(Matrix{Float64}, mat); hdr=hdr, geom=geom, kwargs...)::GMTdataset
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

# ---------------------------------------------------------------------------------------------------
function mat2ds(mat::Vector{<:AbstractMatrix}; hdr=String[], kwargs...)
	d = KW(kwargs)
	D::Vector{GMTdataset} = Vector{GMTdataset}(undef, length(mat))
	pen   = find_in_dict(d, [:pen])[1]
	color = find_in_dict(d, [:lc :linecolor :color])[1]
	ls    = find_in_dict(d, [:ls :linestyle])[1]
	lt    = find_in_dict(d, [:lt :linethick])[1]
	front = find_in_dict(d, [:front])[1]
	fill  = find_in_dict(d, [:fill :fillcolor])[1]
	alpha = find_in_dict(d, [:fillalpha])[1]
	for k = 1:length(mat)
		_hdr = length(hdr) <= 1 ? hdr : hdr[k]
		_pen   = (pen   !== nothing) ? (isa(pen, Vector)   ? (length(pen)   == 1 ? pen   : pen[k])   : [pen]) : pen
		_ls    = (ls    !== nothing) ? (isa(ls, Vector)    ? (length(ls)    == 1 ? ls    : ls[k])    : [ls]) : ls
		_lt    = (lt    !== nothing) ? (isa(lt, Vector)    ? (length(lt)    == 1 ? lt    : lt[k])    : [lt]) : lt
		_front = (front !== nothing) ? (isa(front, Vector) ? (length(front) == 1 ? front : front[k]) : [front]) : front
		_color = (color !== nothing) ? (isa(color, Vector) ? (length(color) == 1 ? color : color[k]) : [color]) : color
		_fill  = (fill  !== nothing) ? (isa(fill, Vector)  ? (length(fill)  == 1 ? fill  : fill[k])  : [fill]) : fill
		_alpha = (alpha !== nothing) ? (isa(alpha, Vector) ? (length(alpha) == 1 ? alpha : alpha[k]) : [alpha]) : alpha
		D[k] = mat2ds(mat[k], hdr=_hdr, color=_color, fill=_fill, fillalpha=_alpha, pen=_pen, lt=_lt, ls=_ls, front=_front)
	end
	set_dsBB!(D, false)
	D[1].proj4, D[1].wkt, D[1].epsg, _, _ = helper_set_crs(d)	# Fish the eventual CRS options.
	return D
end

# ---------------------------------------------------------------------------------------------------
function helper_set_crs(d)
	# Return CRS info eventually passed in kwargs (converted into 'd') + attrib & colnames if :ref is used
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
	(prj == "" && wkt == "" && epsg != 0) && (prj = epsg2proj(epsg))
	return prj, wkt, epsg, ref_attrib, ref_coln
end

# ---------------------------------------------------------------------------------------------------
function mat2ds(mat::Array{T,N}, txt::Vector{String}=String[]; hdr=String[], geom=0, kwargs...) where {T,N}
	d = KW(kwargs)

	(!isempty(txt)) && return text_record(mat, txt,  hdr)
	((text = find_in_dict(d, [:text])[1]) !== nothing) && return text_record(mat, text, hdr)
	is3D = (find_in_dict(d, [:is3D])[1] === nothing) ? false : true		# Should account for is3D == false?

	val = find_in_dict(d, [:multi :multicol])[1]
	multi = (val === nothing) ? false : ((val) ? true : false)	# Like this it will error if val is not Bool
	segnan = (find_in_dict(d, [:segnan :nanseg])[1] !== nothing) ? true : false		# A classic GMT multi-segment sep with NaNs
	segnan && (multi = true)

	if ((x = find_in_dict(d, [:x])[1]) !== nothing)
		n_ds::Int = segnan ? 1 : ((multi) ? size(mat, 2) : 1)
		xx::Vector{Float64} = (x == :ny || x == "ny") ? collect(1.0:size(mat, 1)) : vec(x)
		(length(xx) != size(mat, 1)) && error("Number of X coordinates and MAT number of rows are not equal")
	else
		n_ds = (ndims(mat) == 3) ? size(mat,3) : ((multi) ? size(mat, 2) - segnan - (1+is3D) : 1)
		xx = Vector{Float64}()
	end

	if (!isempty(hdr) && isa(hdr, String))	# Accept one only but expand to n_ds with the remaining as blanks
		_hdr::Vector{String} = Base.fill("", n_ds);	_hdr[1] = hdr
	elseif (!isempty(hdr) && length(hdr) != n_ds)
		error("The header vector can only have length = 1 or same number of MAT Y columns")
	else
		_hdr = vec(hdr)
	end

	color_cycle = false
	if ((color = find_in_dict(d, [:lc :linecolor :color])[1]) !== nothing && color != false)
		_color::Vector{String} = (isa(color, Array{String}) && !isempty(color)) ? vec(color) : matlab_cycle_colors
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

	att = ((v = find_in_dict(d, [:attrib])[1]) !== nothing && isa(v, Dict{String, String})) ? v : Dict{String, String}()
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
			segN[s:e, :] = [_xx mat[:,k]]
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
			coln = fill_colnames(coln, size(mat,2)-2, is_geog)
			(size(mat,2) == 1) && (coln = coln[1:1])		# Because it defaulted to two.
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
	(length(ref_coln) >= size(D[1],2)) && (D[1].colnames = ref_coln[1:size(D[1],2)])	# This still loses Text colname
	CTRL.pocket_d[1] = d		# Store d that may be not empty with members to use in other functions
	set_dsBB!(D)				# Compute and set the global BoundingBox for this dataset
	return (find_in_kwargs(kwargs, [:letsingleton])[1] !== nothing) ? D : (length(D) == 1 && !multi) ? D[1] : D
end

# ---------------------------------------------------------------------------------------------------
function mat2ds(D::GMTdataset, inds)::GMTdataset
	# Cut a GMTdataset D with the indices in INDS but updating the colnames and the Timecol info.
	# INDS is a Tuple of 2 with ranges in rows and columns. Ex: (:, 1:3) or (:, [1,4,7]), etc...
	# Attention, if original had attributes other than 'Timeinfo' there is no guarentie that they remain correct. 
	(length(inds) != ndims(D)) && error("\tNumber of GMTdataset dimensions and indices components must be the same.\n")
	_coln = !isempty(D.colnames) ? D.colnames[inds[2]] : String[]
	(!isempty(_coln) && (typeof(inds[1]) == Colon) && length(D.colnames) > size(D,2)) && append!(_coln, [D.colnames[end]])	# Append text colname if exists
	_D = mat2ds(D.data[inds...], proj4=D.proj4, wkt=D.wkt, epsg=D.epsg, geom=D.geom, colnames=_coln, attrib=D.attrib)
	(!isempty(D.text)) && (_D.text = D.text[inds[1]])
	(typeof(inds[2]) == Colon) && return _D		# We are done here

	if (inds[2][1] != 1 || inds[2][2] != 2)		# If any of the first or second columns has gone we know no more about CRS
		_D.proj4 = "";	_D.wkt = "";	_D.epsg = 0
	end
	i = findall(startswith.(_D.colnames, "Time"))
	isempty(i) && return _D						# No TIME columns. We are done
	(length(i) == 1) ? (Tc::String = "$(i[1])") : _i = i[2:end]
	_D.attrib["Timecol"] = (length(i) == 1) ? Tc : [Tc *= ",$k" for k in _i]
	return _D
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
function set_dsBB!(D, all_bbs::Bool=true)
	# Compute and set the global and individual BoundingBox for a Vector{GMTdataset} + the trivial cases.
	# If ALL_BBS is false then assume individual BBs are already knwon.
	isempty(D) && return nothing

	if (all_bbs)		# Compute all BBs
		if isa(D, GMTdataset)
			(size(D,1) == 1) && return nothing		# Single liners have no BB
			D.ds_bbox = D.bbox = collect(Float64, Iterators.flatten(extrema(D.data, dims=1)))
			return nothing
		else
			for k = 1:lastindex(D)
				bb = Base.invokelatest(extrema, D[k].data, dims=1)		# A N Tuple.
				_bb = collect(Float64, Iterators.flatten(bb))
				if (any(isnan.(_bb)))				# Shit, we don't have a minimum_nan(A, dims)
					n = 1
					for kk = 1:size(D[k].data, 2)
						isnan(_bb[n]) && (_bb[n:n+1] .= extrema_cols(D[k], col=kk))
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
	# Take a vector of GS and collapse it into a single GMTdataset DS. Some metadata, proj, colnames
	# and attributes are copied from first segment. Colors in header and text are lost.
	tot_rows = sum(size.(D,1))
	data = zeros(tot_rows, size(D[1],2))
	s, e = 1, size(D[1],1)
	data[s:e, :] = D[1].data
	for k = 2:numel(D)
		s  = e + 1
		e += size(D[k],1)
		data[s:e, :] = D[k].data
	end
	mat2ds(data, proj=D[1].proj4, wkt=D[1].wkt, epsg=D[1].epsg, geom=D[1].geom, colnames=D[1].colnames, attrib=D[1].attrib)
end

# ---------------------------------------------------------------------------------------------------
function ds2ds(D::GMTdataset; is3D::Bool=false, kwargs...)::Vector{<:GMTdataset}
	# Take one DS and split it into an array of DS's, one for each row and optionally add -G<fill>
	# Alternativelly, if [:multi :multicol] options lieve in 'd', split 'D' by columns: [1,2], [1,3], [1,4], ...
	# So far only for internal use but may grow in function of needs
	d = KW(kwargs)

	multi = 'r'		# Default split by rows
	if ((val = find_in_dict(d, [:multi :multicol], false)[1]) !== nothing)  multi = 'c'  end		# Then by columns
	_fill = (multi == 'r') ? helper_ds_fill(d) : String[]	# In the columns case all is dealt in mat2ds.

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
			Dm[k] = GMTdataset(D.data[k:k, :], Float64[], Float64[], Dict{String, String}(), String[], String[], (isempty(_fill) ? "" : _hdr[k]), String[], "", "", 0, wkbPoint)
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
function helper_ds_fill(d::Dict, del::Bool=true; symbs=[:fill :fillcolor], nc=0)::Vector{String}
	# Shared by ds2ds & mat2ds & statplots
	# The NC parameter is used to select the color schema: <= 8 ==> 'matlab_cycle_colors'; otherwise 'simple_distinct'
	# By using a non-default SYMBS we can use this function for other than selecting fill colors.
	if ((fill_val = find_in_dict(d, symbs, del)[1]) !== nothing)
		if (isa(fill_val, StrSymb))
			isa(fill_val, Symbol) && (fill_val = string(fill_val)::String)
			if contains(fill_val, ",")  _fill::Vector{String} = collect(split(fill_val, ","))
			elseif (fill_val == "yes" || fill_val == "cycle")
					                     _fill = (nc <= 8) ? copy(matlab_cycle_colors) : copy(simple_distinct)
			elseif (fill_val == "none")  _fill = [" "]
			else	                     _fill = [fill_val]
			end
		elseif (isa(fill_val, Tuple) && eltype(fill_val) == Symbol)
			_fill = [string.(fill_val)...]
		elseif (isa(fill_val, Array{String}) && !isempty(fill_val))
			_fill = vec(fill_val)
		elseif (isa(fill_val, Array{Symbol}))
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
function tabletypes2ds(arg)
	# Try guesswork to convert Tables types into GMTdatasets usable in plots.
	#(arg === nothing || isa(arg, GDtype) || isa(arg, Matrix{<:Real})) && return arg
	isdataframe(arg) && return df2ds(arg)				# DataFrames are(?) easier to deal with.
	isODE(arg) && return ODE2ds(arg)					# DifferentialEquations type is a complex beast.

	# Guesswork, it may easily screw.
	colnames = [i for i in fields(arg) if Base.nonmissingtype(eltype(getproperty(arg, i))) <: AbstractFloat]
	vv = [getproperty(arg,i) for i in colnames]			# A f. Vector-of-vectors
	mat2ds(reduce(hcat,vv), colnames=string.(colnames))	# More f. cryptic cmds
end

# ---------------------------------------------------------------------------------------------------
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
function ODE2ds(arg)::GMTdataset
	vv = getproperty(arg,:u)			# A potentially Vector-of-vectors or Vector-of-matrices
	if isa(vv, Vector{<:Matrix})
		mat = [arg.t reshape(reshape(reduce(hcat,vv),size(first(vv))...,:), length(vv[1]), length(vv))'[:,end:-1:1]]	# No comments
	else
		mat = (isa(vv, Vector{<:Vector})) ? [arg.t reduce(hcat,vv)'] : [arg.t arg.u]
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
	isa(t, Int) ? (epsg = t; proj = epsg2proj(t)) : startswith(t, "GEOGCS") ? (wkt=t; proj=wkt2proj(t)) : startswith(t, "+proj") ? (proj=t) : nothing

	data = nothing
	(isa(arg.missingval, Real) && !isnan(arg.missingval)) && (@inbounds Threads.@threads for k=1:numel(arg.data) arg.data[k] == arg.missingval && (arg.data[k] = NaN)  end)

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

	(data === nothing) && (data = collect(arg.data))
	(scale != 1 || offset != 0) && (data = muladd.(data, scale, offset))

	(is_transp && Yorder == 'B') && (reverse!(data, dims=2); layout = "TRB")	# GMT expects grids to be scanline and Top->Bot
	mat2grid(data, x=collect(arg.dims[1]), y=_y, v=_v, names=names, tit=string(arg.name), rem="Converted from a Rasters object.", is_transposed=is_transp, layout=layout, proj4=proj, wkt=wkt, epsg=epsg)
end

# ---------------------------------------------------------------------------------------------------
# Try to guess if ARG is a DataFrame type. Note, we do this without having DataFrames as a dependency (even indirect)
isdataframe(arg) = (fs = fields(arg); return (isempty(fs) || fs[1] != :columns || fs[end] != :allnotemetadata) ? false : true)
# Check if it is a DifferentialEquations type
isODE(arg) = (fs = fields(arg); return (!isempty(fs) && (fs[1] == :u && any(fs .== :t) && fs[end] == :retcode)) ? true : false)
# See if it is a Rasters type
israsters(arg) = (fs = fields(arg); return (length(fs) == 6 && (fs[1] == :data && fs[end] == :missingval)) ? true : false)

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
		mima = (size(M,2) <= 3) ? (1., Float64(size(M,1))) : Float64.(extrema_cols(M, col=color_col))
		(size(M,2) <= 3) && (use_row_number = true; z4color = 1.:n_ds)
		color::GMTcpt = gmt(@sprintf("makecpt -T%f/%f/65+n -Cturbo -Vq", mima[1]-eps(1e10), mima[2]+eps(1e10)))
	end

	if (!isempty(color))
		z_col = color_col
		rgb = [0.0, 0.0, 0.0];
		P::Ptr{GMT.GMT_PALETTE} = palette_init(G_API[1], color);		# A pointer to a GMT CPT
		for k = 1:n_ds
			z = (use_row_number) ? z4color[k] : M[k, z_col]
			@GC.preserve color gmt_get_rgb_from_z(G_API[1], P, z, rgb)
			t = @sprintf(",%.0f/%.0f/%.0f", rgb[1]*255, rgb[2]*255, rgb[3]*255)
			_hdr[k] = (first) ? " -W"*t : _hdr[k] * t
		end
	end

	Dm = Vector{GMTdataset}(undef, n_ds)
	geom = (is3D) ? Int(Gdal.wkbLineStringZ) : Int(Gdal.wkbLineString)
	for k = 1:n_ds
		Dm[k] = GMTdataset(M[k:k+1, :], Float64[], Float64[], Dict{String, String}(), String[], String[], _hdr[k], String[], "", "", 0, geom)
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
function mat2img(mat::AbstractArray{<:Unsigned}, dumb::Int=0; x=Vector{Float64}(), y=Vector{Float64}(),
	             v=Vector{Float64}(), hdr=nothing, proj4::String="", wkt::String="", cmap=nothing, is_transposed::Bool=false, kw...)
	# Take a 2D array of uint8 and turn it into a GMTimage.
	# Note: if HDR is empty we guess the registration from the sizes of MAT & X,Y
	color_interp = "";		n_colors = 0;
	if (cmap !== nothing)
		colormap, n_colors = cmap2colormap(cmap)
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
	((val = find_in_dict(d, [:layout :mem_layout])[1]) !== nothing) && (mem_layout = string(val)::String)
	_names = ((val = find_in_dict(d, [:names])[1]) !== nothing) ? val : String[]
	_meta  = ((val = find_in_dict(d, [:metadata])[1]) !== nothing) ? val : String[]

	GMTimage(proj4, wkt, 0, -1, hdr[1:6], [x_inc, y_inc], reg, zero(eltype(mat)), color_interp, _meta, _names,
	         x,y,v,mat, colormap, n_colors, Array{UInt8,2}(undef,1,1), mem_layout, 0)
end

# ---------------------------------------------------------------------------------------------------
function cmap2colormap(cmap::GMTcpt, force_alpha=true)
	# Convert a GMT CPT into a colormap to be ingested by GDAL
	have_alpha = !all(cmap.alpha .== 0.0)
	nc = (have_alpha || force_alpha) ? 4 : 3
	colormap = zeros(Int32, 256 * nc)
	n_colors = 256;			# Because for GDAL we always send 256 even if they are not all filled
	@inbounds for n = 1:3	# Write 'colormap' col-wise
		@inbounds for m = 1:size(cmap.colormap, 1)
			colormap[m + (n-1)*n_colors] = round(Int32, cmap.colormap[m,n] * 255);
		end
	end
	if (have_alpha)						# Have alpha color(s)
		for m = 1:size(cmap.colormap, 1)
			colormap[m + 3*n_colors] = round(Int32, cmap.colormap[m,4] * 255)
		end
		n_colors *= 1000				# Flag that we have alpha colors in an indexed image
	elseif (force_alpha)
		colormap[256*3+1:end] = zeros(UInt32, 256)
	end
	return colormap, n_colors
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
			@inbounds @simd for k = 1:numel(img)
				img[k] = (mat[k] < val) ? 0 : round(UInt8, (mat[k] - val) * sc)
			end
		elseif (len == 2)
			val = [parse(UInt16, @sprintf("%d", vals[1])) parse(UInt16, @sprintf("%d", vals[2]))]
			sc = 255 / (val[2] - val[1])
			@inbounds @simd for k = 1:numel(img)
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
function mat2img(mat::Union{GMTgrid,Matrix{<:AbstractFloat}}; x=Vector{Float64}(), y=Vector{Float64}(), hdr=nothing,
	             proj4::String="", wkt::String="", GI::Union{GItype,Nothing}=nothing, clim=[0,255], cmap=nothing, kw...)
	# This is the same as Matlab's imagesc() ... plus some extras.
	mi, ma = (isa(mat,GMTgrid)) ? mat.range[5:6] : extrema(mat)
	(isa(mat,GMTgrid) && mat.hasnans > 1) && (mi = NaN)		# Don't know yet so force checking
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
	if (!isa(mat, GMTgrid) && GI !== nothing)
		I = mat2img(img, GI)
		if (cmap !== nothing)  I.colormap, I.n_colors = cmap2colormap(cmap)
		else                   I.colormap, I.n_colors = zeros(Int32,3), 0	# Do not inherit this from GI
		end
	elseif (isa(mat, GMTgrid))
		I = mat2img(img; x=mat.x, y=mat.y, hdr=hdr, proj4=mat.proj4, wkt=mat.wkt, cmap=cmap, kw...)
	else
		I = mat2img(img; x=x, y=y, hdr=hdr, proj4=proj4, wkt=wkt, cmap=cmap, kw...)
	end
	isa(mat,GMTgrid) && (I.layout = mat.layout[1:3] * "a")
	return I
end

"""
    imagesc(mat; x=, y=, hdr=, proj4=, wkt=, GI=, clim=, cmap=, kw...)

imagesc takes a Float matrix or a GMTgrid type and scales it (by default) to the [0, 255] interval.
In the process it creates a GMTimage type. Those types can account for coordinates and projection
information, hence the optional arguments. Contrary to its Matlab cousin, it doesn't display the
result (that we easily do with `imshow(mat)`) but return instead a GMTimage object.

  - `clim`: Specify clims as a two-element vector of the form [cmin cmax], where values of the scaled image
     less than or equal to cmin are assigned that value. The same goes for cmax.
  - `cmap`: If provided, `cmap` is a GMTcpt and its contents is converted to the `GMTimage` colormp.
  - `GI`: This can be either a GMTgrid or a GMTimage and its contents is used to set spatial contents
     (x,y coordinates) and projection info that one may attach to the created image result. This is
     a handy alterative to the `x=, y=, proj4=...` options.
"""
function imagesc(mat::Union{GMTgrid,Matrix{<:AbstractFloat}}; x=Vector{Float64}(), y=Vector{Float64}(), hdr=nothing,
	             proj4::String="", wkt::String="", GI::Union{GItype,Nothing}=nothing, clim=[0,255], cmap=nothing, kw...)
	mat2img(mat, x=x, y=y, hdr=hdr, proj4=proj4, wkt=wkt, GI=GI, clim=clim, cmap=cmap, kw...)
end
# ---------------------------------------------------------------------------------------------------
# This method creates a new GMTimage but retains all the header data from the IMG object
function mat2img(mat, I::GMTimage; names::Vector{String}=String[], metadata::Vector{String}=String[])
	range = copy(I.range);	(size(mat,3) == 1) && (range[5:6] .= extrema(mat))
	GMTimage(I.proj4, I.wkt, I.epsg, I.geog, range, copy(I.inc), I.registration, I.nodata, I.color_interp, metadata, names, copy(I.x), copy(I.y), zeros(size(mat,3)), mat, copy(I.colormap), I.n_colors, Array{UInt8,2}(undef,1,1), I.layout, 0)
end
function mat2img(mat, G::GMTgrid; names::Vector{String}=String[], metadata::Vector{String}=String[])
	range = copy(G.range);	range[5:6] .= (size(mat,3) == 1) ? extrema(mat) : [0., 255]
	GMTimage(G.proj4, G.wkt, G.epsg, G.geog, range, copy(G.inc), G.registration, zero(eltype(mat)), "Gray", metadata, names, copy(G.x), copy(G.y), zeros(size(mat,3)), mat, zeros(Int32,3), 0, Array{UInt8,2}(undef,1,1), G.layout*"a", 0)
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
	(size(I,3) == 1) && return I		# There is nothing to slice here, but save the user from the due deserved insult.
	mat = I.image[:,:,layer]
	range = copy(I.range);	range[5:6] .= extrema(mat)
	names = (!isempty(I.names) && !all(I.names .== "")) ? (isvec ? I.names[layer] : [I.names[layer]]) : I.names
	GMTimage(I.proj4, I.wkt, I.epsg, I.geog, range, copy(I.inc), I.registration, I.nodata, "Gray", I.metadata, names, copy(I.x), copy(I.y), [0.], mat, zeros(Int32,3), 0, Array{UInt8,2}(undef,1,1), I.layout, I.pad)
end

function slicecube(G::GMTgrid, slice::Union{Int, AbstractVector{<:Int}}; axis="z")
	# Method that slices grid cubes. SLICE is the row|col|layer number. AXIS picks the axis to be sliced
	(ndims(G) < 3 || size(G,3) < 2) && error("This is not a cube grid.")
	_axis = lowercase(string(axis))

	dim = (_axis == "z") ? 3 : (_axis == "y" ? 1 : 2)		# First try to pick which dimension to slice
	if (G.layout[2] == 'R' && dim < 3)  dim = (dim == 1) ? 2 : 1  end	# For RowMajor swap dim from 1 to 2
	this_size = size(G,dim)
	isvec = !isa(slice, Int)
	(!isvec && slice > this_size) && error("Slice number ($slice) is larger than grid size ($this_size)")
	(!isvec && slice[end] > this_size) && error("Last slice number ($(slice[end])) is larger than grid size ($this_size)") 

	isempty(G.v) && (G.v = collect(1:size(G,3)))
	if (_axis == "z")
		G_ = mat2grid(G[:,:,slice], G.x, G.y, isvec ? G.v[slice] : [G.v[slice]], reg=G.registration, is_transposed=(G.layout[2] == 'R'))
		G_.names = (!isempty(G.names) && !all(G.names .== "")) ? (isvec ? G.names[layer] : [G.names[layer]]) : G.names
	elseif (_axis == "y")
		if (G.layout[2] == 'C')  G_ = mat2grid(G[slice,:,:], G.x, G.v, reg=G.registration, names=G.names)
		else                     G_ = mat2grid(G[:,slice,:], G.x, G.v, reg=G.registration, is_transposed=true, names=G.names)
		end
		G_.v = G_.y;	G_.y = isvec ? G.y[slice] : [G.y[slice]]	# Shift coords vectors since mat2grid doesn't know how-to.
	else
		if (G.layout[2] == 'C')  G_ = mat2grid(G[:,slice,:], G.y, G.v, reg=G.registration, names=G.names)
		else                     G_ = mat2grid(G[slice,:,:], G.y, G.v, reg=G.registration, is_transposed=true, names=G.names)
		end
		G_.v = G_.y;	G_.y = G_.x;	G_.x = isvec ? G.x[slice] : [G.x[slice]]
	end
	G_.proj4, G_.wkt, G_.epsg, G_.geog, G_.layout = G.proj4, G.wkt, G.epsg, G.geog, G.layout
	return G_
end

function slicecube(G::GMTgrid, slice::AbstractFloat; axis="z")
	# Method that slices grid cubes. SLICE is the x|y|z coordinate where to slice. AXIS picks the axis to be sliced
	(ndims(G) < 3 || size(G,3) < 2) && error("This is not a cube grid.")
	_axis = lowercase(string(axis))

	which_coord_vec = (_axis == "z") ? G.v : (_axis == "y" ? G.y : G.x)
	x = interp_vec(which_coord_vec, slice)
	layer = trunc(Int, x)
	frac = x - layer			# Used for layer interpolation.
	(frac < 0.1) && return slicecube(G, layer)		# If 'slice' is within 10% of lower or upper layer just
	(frac > 0.9) && return slicecube(G, layer+1)	# return that layer and do no interpolation between layers.

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
		if (cmap !== nothing)  I.colormap, I.n_colors = cmap2colormap(cmap)
		else                   I.colormap, I.n_colors = zeros(Int32,3), 0	# Do not inherit this from GI
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
    xyzw2cube(fname::AbstractString; datatype::DataType=Float32, proj4::String="", wkt::String="",
	          epsg::Int=0, tit::String="", names::Vector{String}=String[])

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

### Returns
A GMTgrid cube object.
"""
function xyzw2cube(fname::AbstractString="ALL_dRho.dat"; datatype::DataType=Float32, proj4::String="",
	wkt::String="", epsg::Int=0, tit::String="", names::Vector{String}=String[])
	# Convert a cube stored in a text file into GMTgrid (cube).
	function examine_col(fname, col)
		x = gmtread(fname, T="d", i=col);
		mima = extrema(x)
		n = length(x)
		d = x[2] - x[1]
		(d != 0) && return mima, d, n, true
		k = 1
		while (x[k] == x[k+=1]) end
		d = x[k] - x[k-1]
		(d != 0) && return mima, d, n, false
	end

	mima_X, dx, n, rowmajor = examine_col(fname, 0)
	n_cols = round(Int, (mima_X[2] - mima_X[1]) / dx) + 1
	mima_Y, dy, _, colmajor = examine_col(fname, 1)
	n_rows = round(Int, (mima_Y[2] - mima_Y[1]) / dy) + 1

	w = gmtread(fname, T="d", i=2);
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

	z = gmtread(fname, T="d", i=3);
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

	mat2grid(cube, linspace(mima_X[1],mima_X[2],n_cols), linspace(mima_Y[1],mima_Y[2],n_rows), v; proj4=proj4, wkt=wkt, epsg=epsg, tit=tit, names=names)
end

# ---------------------------------------------------------------------------------------------------
"""
    stackgrids(names::Vector{String}, v=nothing; zcoord=nothing, zdim_name="time",
	           z_unit="", save="", mirone=false)

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
change just the color index that will be made transparent by using `alpha_ind=n` or provide a vector
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
Use `image_cpt!(img, clear=true)` to remove a previously existant `colormap` field in IMG
"""
image_cpt!(I::GMTimage, cpt::String) = image_cpt!(I, gmtread(cpt))
function image_cpt!(I::GMTimage, cpt::GMTcpt)
	# Insert the cpt info in the img.colormap member
	I.colormap, I.n_colors = cmap2colormap(cpt)
	I.color_interp = "Palette"
	return nothing
end
function image_cpt!(img::GMTimage; clear::Bool=true)
	if (clear)
		img.colormap, img.n_colors, img.color_interp = fill(Int32(0), 3), 0, "Gray"
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    I = ind2rgb(I::GMTimage, cmap::GMTcpt=GMTcpt(), layout="BRPa")

Convert an indexed image I to RGB. If `cmap` is not provided, it uses the internal colormap to do the conversion.
If neither them exists, the layer is replicated 3 times thus resulting in a gray scale image.
"""
function ind2rgb(I::GMTimage, cmap::GMTcpt=GMTcpt(), layout="BRPa")
	(size(I.image, 3) >= 3) && return I 	# Image is already RGB(A)

	# If the CPT is shorter them maximum in I, reinterpolate the CPT
	(!isempty(cmap) && (ma = maximum(I)) > size(cmap.colormap,1)) && (cmap = gmt("makecpt -T0/{$ma}/+n{$ma}", cmap))
	_cmap = (!isempty(cmap)) ? cmap2colormap(cmap::GMTcpt)[1] : I.colormap

	have_alpha = (length(I.colormap) / I.n_colors) == 4 && !all(I.colormap[end-Int(I.n_colors/4+1):end] .== 255)
	if (I.n_colors == 0 && isempty(cmap))		# If no cmap just replicate the first layer.
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
			layout = (I.layout[2] == 'R') ? "TCBa" : I.layout
			img    = (I.layout[2] == 'R') ? I.image' : I.image
			for c = 1:3+have_alpha
				start_c = (c - 1) * I.n_colors + 1		# +1 because indices start a 1
				for k in eachindex(I.image)
					imgRGB[n+=1] = _cmap[img[k] + start_c];
				end
			end
		end
	end
	mat2img(imgRGB, x=I.x, y=I.y, proj4=I.proj4, wkt=I.wkt, mem_layout=layout)
end

# ---------------------------------------------------------------------------------------------------
"""
    G = mat2grid(mat; reg=nothing, x=[], y=[], v=[], hdr=nothing, proj4::String="",
	             wkt::String="", title::String="", rem::String="", cmd::String="",
				 names::Vector{String}=String[], scale::Float32=1f0, offset::Float32=0f0)

Take a 2/3D `mat` array and a HDR 1x9 [xmin xmax ymin ymax zmin zmax reg xinc yinc] header descriptor and 
return a grid GMTgrid type. Alternatively to HDR, provide a pair of vectors, `x` & `y`, with the X and Y coordinates.
Optionaly add a `v` vector with vertical coordinates if `mat` is a 3D array and one wants to create a ``cube``.
Optionaly, the HDR arg may be ommited and it will computed from `mat` alone, but then x=1:ncol, y=1:nrow
When HDR is not used, REG == nothing [default] means create a gridline registration grid and REG == 1,
or REG="pixel" a pixel registered grid.

For 3D arrays the `names` option is used to give a description for each layer (also saved to file when using a GDAL function).

The `scale` and `offset` options are used when `mat` is an Integer type and we want to save the grid with an scale/offset.  

Other methods of this function do:

    G = mat2grid([val]; hdr=hdr_vec, reg=nothing, proj4::String="", wkt::String="", title::String="", rem::String="")

Create Float GMTgrid with size, coordinates and increment determined by the contents of the HDR var. This
array, which is now MANDATORY, has either the same meaning as above OR, alternatively, containng only
[xmin xmax ymin ymax xinc yinc]
VAL is the value that will be fill the matrix (default VAL = Float32(0)). To get a Float64 array use, for
example, VAL = 1.0 Ay other non Float64 will be converted to Float32

    Example: mat2grid(1, hdr=[0. 5 0 5 1 1])

    G = mat2grid(f::Function, x, y; reg=nothing, proj4::String="", wkt::String="", epsg::Int=0, title::String="", rem::String="")

Where F is a function and X,Y the vectors coordinates defining it's domain. Creates a Float32 GMTgrid with
size determined by the sizes of the X & Y vectors.

    Example: f(x,y) = x^2 + y^2;  G = mat2grid(f, x = -2:0.05:2, y = -2:0.05:2)

    G = mat2grid(f::String)

Whre f is a pre-set function name. Currently available:
   - "ackley", "eggbox", "sombrero", "parabola" and "rosenbrock" 
X,Y are vectors coordinates defining the function's domain, but default values are provided for each function.
creates a Float32 GMTgrid.

    Example: G = mat2grid("sombrero")
"""
function mat2grid(val::Real=Float32(0); reg=nothing, hdr=nothing, proj4::String="", proj::String="",
                  wkt::String="", epsg::Int=0, geog::Int=-1, title::String="", tit::String="", rem::String="",
                  names::Vector{String}=String[])

	(hdr === nothing) && error("When creating grid type with no data the 'hdr' arg cannot be missing")
	(!isa(hdr, Array{Float64})) && (hdr = Float64.(hdr))
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

function mat2grid(mat, xx=Vector{Float64}(), yy=Vector{Float64}(), zz=Vector{Float64}(); reg=nothing,
                  x=Vector{Float64}(), y=Vector{Float64}(), v=Vector{Float64}(), hdr=nothing, proj4::String="",
                  proj::String="", wkt::String="", epsg::Int=0, geog::Int=-1, title::String="", tit::String="",
                  rem::String="", cmd::String="", names::Vector{String}=String[], scale::Real=1f0,
                  offset::Real=0f0, layout::String="", is_transposed::Bool=false)
	# Take a 2/3D array and turn it into a GMTgrid

	israsters(mat) && return rasters2grid(mat, scale=scale, offset=offset)
	!isa(mat[2], Real) && error("input matrix must be of Real numbers")
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
	(isempty(x) && !isempty(xx)) && (x = vec(xx))
	(isempty(y) && !isempty(yy)) && (y = vec(yy))
	(isempty(v) && !isempty(zz)) && (v = vec(zz))
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
		if (isempty(v))  inc, range = [x_inc, y_inc, 1.], [vec(hdr[1:6]); [1., size(mat,3)]]
		else             inc, range = [x_inc, y_inc, v[2] - v[1]], [vec(hdr[1:6]); [v[1], v[end]]]
		end
	end
	hasnans = any(!isfinite, mat) ? 2 : 1
	_layout = (layout == "") ? "BCB" : layout
	(geog == -1 && helper_geod(proj4, wkt, epsg, false)[3]) && (geog = (range[2] <= 180) ? 1 : 2)	# Signal if grid is geog.
	(tit == "") && (tit = title)		# Some versions from 1.2 remove 'tit'
	GMTgrid(proj4, wkt, epsg, geog, range, inc, reg_, NaN, tit, rem, cmd, "", names, vec(x), vec(y), vec(v), isT ? copy(mat) : mat, "x", "y", "v", "z", _layout, scale, offset, 0, hasnans)
end

# This method creates a new GMTgrid but retains all the header data from the G object
function mat2grid(mat::Array{T,N}, G::GMTgrid) where {T,N}
	isT = istransposed(mat)
	hasnans = any(!isfinite, mat) ? 2 : 1
	Go = GMTgrid(G.proj4, G.wkt, G.epsg, G.geog, deepcopy(G.range), deepcopy(G.inc), G.registration, G.nodata, G.title, G.remark, G.command, "", String[], deepcopy(G.x), deepcopy(G.y), [0.], isT ? copy(mat) : mat, G.x_unit, G.y_unit, G.v_unit, G.z_unit, G.layout, 1f0, 0f0, G.pad, hasnans)
	setgrdminmax!(Go)		# Also take care of NaNs
	Go
end
function mat2grid(mat, I::GMTimage)
	isT = istransposed(mat)
	hasnans = any(!isfinite, mat) ? 2 : 1
	Go = GMTgrid(I.proj4, I.wkt, I.epsg, I.geog, I.range, I.inc, I.registration, NaN, "", "", "", "", String[], I.x, I.y, [0.], isT ? copy(mat) : mat, "", "", "", "", I.layout, 1f0, 0f0, I.pad, hasnans)
	(length(Go.layout) == 4) && (Go.layout = Go.layout[1:3])	# No space for the a|A
	setgrdminmax!(Go)		# Also take care of NaNs
	Go
end

function mat2grid(f::Function, xx::AbstractVector{<:Float64}=Vector{Float64}(),
                  yy::AbstractVector{<:Float64}=Vector{Float64}(); reg=nothing, x::AbstractVector{<:Float64}=Vector{Float64}(), y::AbstractVector{<:Float64}=Vector{Float64}(), proj4::String="", proj::String="", wkt::String="", epsg::Int=0, tit::String="", rem::String="")
	(isempty(x) && !isempty(xx)) && (x = xx)
	(isempty(y) && !isempty(yy)) && (y = yy)
	(isempty(x) || isempty(y)) && error("Must transmit the domain coordinates over which to calculate function.")
	(isempty(proj4) && !isempty(proj)) && (proj4 = proj)	# Allow both proj4 or proj keywords
	z = Array{Float32,2}(undef, length(y), length(x))
	for i in eachindex(x), j in eachindex(y)
		z[j,i] = f(x[i], y[j])
	end
	mat2grid(z; reg=reg, x=x, y=y, proj4=proj4, wkt=wkt, epsg=epsg, tit=tit, rem=rem)
end

function mat2grid(f::String, xx::AbstractVector{<:Float64}=Vector{Float64}(),
	              yy::AbstractVector{<:Float64}=Vector{Float64}(); x::AbstractVector{<:Float64}=Vector{Float64}(), y::AbstractVector{<:Float64}=Vector{Float64}())
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
function grdimg_hdr_xy(mat, reg, hdr, x=Vector{Float64}(), y=Vector{Float64}(), is_transposed=false)
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
    zvals = polygonlevels(D::GDtype, ids::Vector{String}, vals::Vector{<:Real}; kw...) -> Vector{Float64}
or

    zvals = polygonlevels(D::GDtype, ids::Matrix{String}, vals::Vector{<:Real}; kw...) -> Vector{Float64}

Creates a vector with `zvals` to use in `plot` and where length(zvals) == length(D)
The elements of `zvals` are made up from the `vals`.

- `ids`:    is a string Vector or Matrix with the ids (attribute names) of the GMTdataset D.
            If a Matrix (2 columns only) then the `att` bellow must also have the two names (string vector
            with two elements) that will be matched against the two elements of each line of `ids`.
            The idea here is to match two conditions: `att[1] == ids[n,1] && att[2] == ids[n,2]`
- `vals`:   is a vector with the numbers to be used in plot `level` to color the polygons.
- `attrib` or `att`: keyword to select which attribute to use when matching with contents of the `ids` strings.
- `nocase` or `insensitive`: a keyword from `kw`. Perform a case insensitive comparision between the contents of
               `ids` and the attribute specified with `attrib`. Default compares as case sensistive.
- `repeat`: keyword to replicate the previously known value until it finds a new segment ID for the case
            when a polygon have no attributes (may happen for the islands in a country).

Returns a Vector{Float64} with the same length as the number of segments in D. Its content are
made up from the contents of `vals` but may be repeated such that each polygon of the same family, i.e.
with the same `ids`, has the same value.
"""
function polygonlevels(D::Vector{<:GMTdataset}, user_ids::VecOrMat{<:AbstractString}, vals; kw...)
	# Damn missings are so annoying. And the f types too. Can't restrict it to Vector{Union{Missing, <:Real}}
	# This method works for both Vector or Matrix 'user_ids'.
	et = eltype(vals);
	(et != Union{Missing, Float64} && et != Union{Missing, Float32} && et != Union{Missing, Int}) && @warn("Probable error in data type ($et)")
	inds, _vals = ismissing.(vals), collect(skipmissing(vals))
	any(inds) && (user_ids = isa(user_ids, Matrix) ? user_ids[:,.!inds] : user_ids[.!inds])
	polygonlevels(D, user_ids, _vals; kw...)
end
function polygonlevels(D::Vector{<:GMTdataset}, user_ids::Vector{<:AbstractString}, vals::Vector{<:Real}; kw...)::Vector{Float64}
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

function polygonlevels(D::Vector{<:GMTdataset}, user_ids::Matrix{<:AbstractString}, vals::Vector{<:Real}; kw...)::Vector{Float64}
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
		[D[ind[k]].header *= string(opt, vals[k])  for k = 1:lastindex(ind)]
	else
		D.header *= string(opt, vals[1])::String
	end
	return nothing
end
function edit_segment_headers!(D::GMTdataset, opt::Char, op::Symbol=:get, txt::String="")::String
	# This method either apply changes to header or get the ccontents of the specifyied option passed in 'opt'
	# Used only for gettting/setting GMT options, not general text.
	(op == :get) && return scan_opt(D.header, "-"*opt)
	if (op == :set || op == :add)
		if ((t = scan_opt(D.header, "-"*opt)) == "")  D.header *= string(" -", opt, txt)
		else                                          D.header = replace(D.header, "-"*opt*t => "-"*opt*txt)
		end
		return D.header
	end
end

# ---------------------------------------------------------------------------------------------------
"""
    ids, ind = dsget_segment_ids(D)::Tuple{Vector{String}, Vector{Int}}

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
	for k = 1:numel(ind)  ids[k] = d[ind[k]]  end
	return ids, ind
end

# ---------------------------------------------------------------------------------------------------
"""
    getbyattrib(D::Vector{<:GMTdataset}[, index::Bool]; kw...)

Take a GMTdataset vector and return only its elememts that match the condition(s) set by the `attrib` keywords.
Note, this assumes that `D` has its `attrib` fields set with usable information.

### Parameters
- `attrib` or `att`: keyword with the attribute `name` used in selection. It can be a single name as in `att="NAME_2"`
        or a NamedTuple with the attribname, attribvalue as in `att=(NAME_2="value")`. Use more elements if
        wishing to do a composite match. E.g. `att=(NAME_1="val1", NAME_2="val2")` in which case oly segments
        matching the two conditions are returned.
- `val` or `value`: keyword with the attribute ``value`` used in selection. Use this only when `att` is not a NamedTuple.
- `index`: Use this `positional` argument = `true` to return only the segment indices that match the `att` condition(s).

### Returns
Either a vector of GMTdataset, or a vector of Int with the indices of the segments that match the query condition.
Or `nothing` if the query results in an empty GMTdataset 

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
	for n = 1:numel(atts)
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