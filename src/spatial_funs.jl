# ---------------------------------------------------------------------------------------------------
"""
    zvals = polygonlevels(D::GDtype, ids::VecOrMat{String}, vals::Vector{<:Real}; kw...) -> Vector{Float64}
or

    zvals = polygonlevels(D::GDtype, idvals::GMTdataset; kw...) -> Vector{Float64}

Create a vector with `zvals` to use in `plot` and where length(zvals) == length(D)

The elements of `zvals` are made up from the `vals`.

### Args
- `D`:      The data in a vector of GMTdataset.
- `ids`:    is a string Vector or Matrix with the ids (attribute names) of the GMTdataset `D`.
            If a Matrix (2 columns only) then the `att` bellow must also have the two names (string vector
            with two elements) that will be matched against the two elements of each line of `ids`.
            The idea here is to match two conditions: `att[1] == ids[n,1] && att[2] == ids[n,2]`
- `vals`:   is a vector with the numbers to be used in plot `level` to color the polygons.
- `idvals`: is a GMTdataset with the `text` field containing the ids to match against the `ids` strings.
            The first column of `id_vals` must contain the values to be used in `vals`. This is a comodity
            function when both the `ids` and `vals` are store in a GMTdataset.

### Kwargs
- `attrib` or `att`: Select which attribute to use when matching with contents of the `ids` strings.
- `nocase` or `insensitive`: Perform a case insensitive comparision between the contents of
               `ids` and the attribute specified with `attrib`. Default compares as case sensistive.
- `repeat`: Replicate the previously known value until it finds a new segment ID for the case
            when a polygon have no attributes (may happen for the islands in a country).

Returns a Vector{Float64} with the same length as the number of segments in D. Its content are
made up from the contents of `vals` but may be repeated such that each polygon of the same family, i.e.
with the same `ids`, has the same value.
"""
function polygonlevels(D::Vector{<:GMTdataset}, id_vals::GMTdataset; kw...)
	# This method uses 'ids' from the ext column of 'id_vals' and the 'vals' from first column in the 'id_vals' 
	isempty(id_vals.text) && error("The `id_vals` dataset must have a text field with the ids to match.")
	polygonlevels(D, id_vals.text, view(id_vals,:,1); kw...)	
end
function polygonlevels(D::Vector{<:GMTdataset}, user_ids::VecOrMat{<:AbstractString}, vals; kw...)
	# Damn missings are so annoying. And the f types too. Can't restrict it to Vector{Union{Missing, <:Real}}
	# This method works for both Vector or Matrix 'user_ids'.
	DT = eltype(vals);
	!(DT in (Float64, Float32, Int)) && (DT != Union{Missing, Float64} && DT != Union{Missing, Float32} && DT != Union{Missing, Int}) && @warn("Probable error in data type ($DT)")
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
	# This method either apply changes to header or get the contents of the specifyied option passed in 'opt'
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
    getbyattrib(D::Vector{<:GMTdataset}[, index::Bool=false]; kw...)

or

    filter(D::Vector{<:GMTdataset}; kw...)
or

    findall(D::Vector{<:GMTdataset}; kw...)

Take a GMTdataset vector and return only its elements that match the condition(s) set by the `kw` keywords.
Note, this assumes that `D` has its `attrib` fields set with usable information.

NOTE: Instead of ``getbyattrib`` one case use instead ``filter`` (...,`index=false`) or ``findall`` (..., `index=true`)

### Parameters

- `attrib name(s)=value(s)`: Easier to explain by examples: `NAME="Antioquia"`, select all elements that have
  that attribute/value combination. `NAME=("Antioquia", "Caldas")`, pick elements that have those `NAME` attributes.
  Add as many as wished. If using two `kwargs` the second works as a condition. ``(..., NAME=("Antioquia", "Caldas"), feature_id=0)``
  means select all elements from ``Antioquia`` and ``Caldas`` that have the attribute `feature_id` = 0.

  A second set of attributes can be used to select elements by region, number of polygon vertices and area.
  For that, name the keyword with a leading underscore, e.g. `_region`, `_nps`, `_area`. Their values are
  passed respectively a 4 elements tuple and numbers. E.g. `_region=(-8.0, -7.0, 37.0, 38.0)`, `_nps=100`, `_area=10`.
  Areas are in square km when input is in geographic coordinates, otherwise squre data unites.

- `invert, or reverse, or not`: If `true` return all segments that do NOT match the query condition(s).

- `attrib` or `att`: (OLD SYNTAX) A NamedTuple with the attribname, attribvalue as in `att=(NAME_2="value",)`.
  Use more elements if wishing to do a composite match. E.g. `att=(NAME_1="val1", NAME_2="val2")` in which
  case only segments matching the two conditions are returned.

- `index`: Use this `positional` argument = `true` to return only the segment indices that match the `att` condition(s).

### Returns
Either a vector of GMTdataset, or a vector of Int with the indices of the segments that match the query condition.
Or `nothing` if the query results in an empty GMTdataset 

## Examples

    D = filter(D, NAME_2="Porto");

    D = filter(D, _region="(-8.0, -7.0, 37.0, 38.0)", _nps=100);
"""
function getbyattrib(D::Vector{<:GMTdataset}, ind_::Bool; kw...)::Vector{Int}
	# This method does the work but it's not the one normally used by the public.
	# It returns the indices of the selected segments.
	(isempty(D[1].attrib)) && (@warn("This datset does not have an `attrib` field and is hence unusable here."); return Int[])
	dounion = Int(1e9)		# Just a big number
	invert = (find_in_kwargs(kw, [:invert :not :revert :reverse])[1] !== nothing)
	if ((_att = find_in_kwargs(kw, [:att :attrib])[1]) !== nothing)		# For backward compat.
		if !isa(_att, NamedTuple)
			((val = find_in_kwargs(kw, [:val :value])[1])  === nothing) && error("Must provide the `attribute` VALUE.")
		end
		atts, vals = isa(_att, NamedTuple) ? (string.(keys(_att)), string.(values(_att))) : ((string(_att),), (string(val),))
		_keys = repeat(" ", length(kw))
	else
		# FCK unbelievable case. Julia can be f. desparing. It took me an whole afternoon to make this work.
		#d = KW(kw); Keys = keys(d);
		#Keys[1] => Internal Error: MethodError: no method matching getindex(::Base.KeySet{Symbol, Dict{Symbol, Any}}, ::Int64)
		count, kk = 0, 1
		v = values(kw)
		_keys = string.(keys(kw))
		for k = 1:numel(kw)
			count += (_keys[k][1] != '_') && (isa(values(v[k]), Tuple) || isa(values(v[k]), Vector{String})) ? length(values(v[k])) : 1
		end
		atts, vals = Vector{String}(undef, count), Vector{String}(undef, count)

		for k = 1:numel(kw)
			vv = values(v[k])
			if (isa(vv, Tuple) && (_keys[k][1] != '_'))
				atts[kk:kk+length(vv)-1] .= _keys[k]
				vals[kk:kk+length(vv)-1] .= string.(vv)
				kk += length(vv) 
			elseif (isa(vv, Vector{String}))
				atts[kk:kk+length(vv)-1] .= _keys[k]
				vals[kk:kk+length(vv)-1] .= vv
				kk += length(vv) 
			else
				atts[kk], vals[kk] = _keys[k], string(vv)
				kk += 1
			end
			(k == 1) && (dounion = kk)		# Index that separates the unions from the interceptions
		end
	end

	function clip_region(D, _region, _tf)		# Clip by region
		xc_1, yc_1 = (_region[1] + _region[2]) /2, (_region[3] + _region[4]) /2
		width1, height1 = _region[2] - _region[1], _region[4] - _region[3]
		for k = 1:numel(D)
			xc_2, yc_2 = (D[k].bbox[1] + D[k].bbox[2]) /2, (D[k].bbox[3] + D[k].bbox[4]) /2
			width2, height2 = D[k].bbox[2] - D[k].bbox[1], D[k].bbox[4] - D[k].bbox[3]
			_tf[k] = rect_overlap(xc_1, yc_1, xc_2, yc_2, width1, height1, width2, height2)[1]
		end
		_tf
	end
	function clip_np(D, nps_, _tf)				# Clip by number of points
		for k = 1:numel(D)  _tf[k] = size(D[k].data,1) >= nps_  end
		_tf
	end
	function clip_area(D, areas_, area_, _tf)				# Clip by number of points
		for k = 1:numel(D)  _tf[k] = areas_[k] >= area_  end
		_tf
	end

	(ind = findfirst(atts .== "_region")) !== nothing && (lims = parse.(Float64, split(vals[ind][2:end-1], ", ")))
	(ind = findfirst(atts .== "_nps"))    !== nothing && (nps  = parse.(Float64, vals[ind]))
	(ind = findfirst(atts .== "_area"))   !== nothing && (area = parse.(Float64, vals[ind]); areas = gmt_centroid_area(G_API[1], D, Int(isgeog(D)))[:,3])

	indices::Vector{Int} = Int[]
	ky = keys(D[1].attrib)
	for n = 1:numel(atts)
		special = (length(_keys) >= n && _keys[n][1] == '_')	# _keys can be shorter than atts
		(!special && (ind = findfirst(ky .== atts[n])) === nothing) && continue
		tf = fill(false, length(D))
		if (special)
			if     (atts[n] == "_region") tf = clip_region(D, lims, tf)
			elseif (atts[n] == "_area")   tf = clip_area(D, areas, area, tf)
			else                          tf = clip_np(D, nps, tf)
			end
		else
			for k = 1:length(D)
				(!isempty(D[k].attrib) && (D[k].attrib[atts[n]] == vals[n])) && (tf[k] = true)
			end
		end
		(invert) && (tf .= .!tf)
		if (n == 1)  indices = findall(tf)
		else         indices = (dounion > n) ? union(indices, findall(tf)) : intersect(indices, findall(tf))
		end
	end
	return indices
end

function getbyattrib(D::Vector{<:GMTdataset}; indices=false, kw...)::Union{Nothing, Vector{<:GMTdataset}, Vector{Int}}
	# This is the intended public method. It returns a subset of the selected segments
	ind = getbyattrib(D, true; kw...)
	isempty(ind)   && return nothing
	(indices == 1) && return ind
	o = D[ind]
	set_dsBB!(o, false)
	o[1].proj4, o[1].wkt, o[1].epsg = D[1].proj4, D[1].wkt, D[1].epsg
	return o
end

# ---------------------------------------------------------------------------------------------------
Base.:filter(D::Vector{<:GMTdataset}; kw...) = getbyattrib(D; kw...)
Base.:findall(D::Vector{<:GMTdataset}; kw...) = getbyattrib(D, true; kw...)

# ---------------------------------------------------------------------------------------------------
"""
    in = pip(x, y, polygon::Matrix)
or

    in = pip(point::VecOrMat, polygon::Matrix)

Returns `in` indicating if the query points specified by `x` and `y` are inside of the polygon area defined by
`polygon` where `polygon` is an Mx2 matrix of reals that should have the first and last elements equal.

## Returns:
- in = 1
- on = 0
- out = -1

## Reference

* Hao et al. 2018. [Optimal Reliable Point-in-Polygon Test and Differential Coding Boolean Operations on Polygons]
  (https://www.mdpi.com/2073-8994/10/10/477)
"""
pip(point::VecOrMat, polygon) = pip(point[1], point[2], polygon)
function pip(x, y, polygon)
	# From https://github.com/JuliaGeometry/PolygonOps.jl/blob/master/src/inpolygon.jl

	OUT, ON, IN = -1, 0, 1
	n = size(polygon, 1)
	k = 0

	@inbounds for i = 1:n-1

		xi, yi = polygon[i,1],   polygon[i,2]
		xj, yj = polygon[i+1,1], polygon[i+1,2]
		v1, v2 = yi - y, yj - y

		((v1 < 0 && v2 < 0) || (v1 > 0 && v2 > 0))	&& continue		# case 11, 26

		u1, u2 = xi - x, xj - x
		f = u1 * v2 - u2 * v1

		if (v2 > 0 && v1 ≤ 0)			# case 3, 9, 16, 21, 13, 24
			(f == 0) && return ON		# case 16, 21
			(f  > 0) && (k += 1)		# Case 3 or 9
		elseif (v1 > 0 && v2 ≤ 0)		# case 4, 10, 19, 20, 12, 25
			(f == 0) && return ON		# case 19, 20
			(f  < 0) && (k += 1)		# Case 4, 10
		elseif (v2 == 0 && v1 < 0)		# case 7, 14, 17
			(f == 0) && return ON		# case 17
		elseif (v1 == 0 && v2 < 0)		# case 8, 15, 18
			(f == 0) && return ON		# case 18
		elseif (v1 == 0 && v2 == 0)		# case 1, 2, 5, 6, 22, 23
			((u2 ≤ 0 && u1 ≥ 0) || (u1 ≤ 0 && u2 ≥ 0)) && return ON	# case 1, 2
		end
	end

	return iseven(k) ? OUT : IN
end

# ---------------------------------------------------------------------------------------------------
"""
    ids = inwhichpolygon(point::Matrix{Real}, D::Vector{GMTdataset}; on_is_in=false, pack=false)
or

    ids = inwhichpolygon(x, y, D::Vector{GMTdataset}; on_is_in=false, pack=false)

Finds the IDs of the polygons enclosing the query points in `point`. Each row in the matrix `point` contains
the coordinates of a query point. Query points that don't fall in any polygon get an ID = 0.
Returns either an ``Int`` or a ``Vector{Int}`` depending on the number of input query points.

- `D`: A Vector of GMTdadaset defining the polygons.
- `point`: A Mx2 matrix or a two elements vector with the x and y point coordinates.
- `x, y`:  Specifies the x-coordinates and y-coordinates of 2-D query points as separate vectors (or two scalars).
- `on_is_in`: If `on_is_in=true` then points exactly on the border are considered inside. Default is `false`.
- `pack`: If `pack=true` then a vector of vectors is returned with the IDs of the hit polygons and the indices
  of the query points that hit each polygon. That is: ids[1] contains indices of `D` that recieved at least a hit;
  ids[2] contains the indices of the query `point` that hit the polygon D[ids[1]], etc.

### Example:
    pts = [[1 2 3;1 2 3;1 2 3][:] [1 1 1;2 2 2; 3 3 3][:]];
    D = triplot(pts, noplot=true);
    points = [2.4 1.2; 1.4 1.4];
    ids = inwhichpolygon(points, D);
    # Plot the triangulation and the query points.
    plot(D)
    plot!(D[ids[1]], fill=:grey)
    plot!(D[ids[2]], fill=:green)
    plot!(points, marker=:star, ms="12p", fill=:blue, show=true)
"""
inwhichpolygon(D::Vector{<:GMTdataset}, x, y; on_is_in=false, pack=false) = inwhichpolygon([x y], D; on_is_in=on_is_in, pack=pack)
inwhichpolygon(x::Union{Vector{<:Real}, Real}, y::Union{Vector{<:Real}, Real}, D::Vector{<:GMTdataset}; on_is_in=false, pack=false) = inwhichpolygon([x y], D; on_is_in=on_is_in, pack=pack)
inwhichpolygon(D::Vector{<:GMTdataset}, point::VecOrMat{<:Real}; on_is_in=false, pack=false) =
	inwhichpolygon(point, D; on_is_in=on_is_in, pack=pack)
inwhichpolygon(point::Tuple{Vector{<:Real}, Vector{<:Real}}, D::Vector{<:GMTdataset}; on_is_in=false, pack=false) =
	inwhichpolygon([point[1] point[2]], D; on_is_in=on_is_in, pack=pack)
function inwhichpolygon(point::VecOrMat{<:Real}, D::Vector{<:GMTdataset}; on_is_in=false, pack=false)::Union{Int, Vector{Int}, Vector{Vector{Int}}}
	pt = isa(point, Vector) ? [point[1] point[2]] : point
	npts::Int = size(pt,1);		ind_pol = zeros(Int, npts)
	fun = on_is_in ? ≥(x,y)=y<=x : >(x,y)=y<x	# To choose if points exactly on border are in or out.

	for n = 1:npts
		for k = 1:length(D)
			!inbbox(pt[n,1], pt[n,2], D[k].bbox) && continue
			#if (!isempty((r = gmtselect(pt[n:n, :], polygon=D[k]))))
			r = pip(pt[n, 1], pt[n, 2], D[k].data)
			if fun(r, 0)
				ind_pol[n] = k
				break
			end
		end
	end

	(pack != 1) && return (npts == 1) ? ind_pol[1] : ind_pol
	helper_pack_inwhichpolygon(ind_pol)
end

# This method takes a vector of GMTdatsets with point geometry and another vector of polygons.
function inwhichpolygon(Dpt::Vector{<:GMTdataset}, Dpol::Vector{<:GMTdataset}; on_is_in=false, pack=false)
	(Dpt[1].geom != wkbPoint && Dpt[1].geom != wkbPointZ) &&
		throw(DomainError("First argument, being a vector of GMTdatasets, must contain a point dataset"))
	n_pts = length(Dpt)
	ind = zeros(Int, n_pts)
	[ind[k] = inwhichpolygon(Dpt[k].data, Dpol, on_is_in=on_is_in) for k = 1:n_pts]
	(pack != 1) && return ind
	helper_pack_inwhichpolygon(ind)
end

function helper_pack_inwhichpolygon(ind_pol)
	# Pack the output of inwhichpolygon in a vector of vectors
	u = unique(ind_pol)
	out = [u]					# First element contains the indices of hit polygons.
	for k = 1:numel(u)
		push!(out, findall(ind_pol .== u[k]))
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
"""
    in = inpolygon(x, y, polygon)
or

    in = inpolygon(point, polygon)

Returns `in` indicating if the query points specified by `x` and `y` are inside of the polygon area defined by:
- `polygon`: a GMTdatset defining the polygon or a Mx2 matrix of reals that should have the
  first and last elements equal.
- `point`: a Mx2 matrix or a two elements vector with the x and y point coordinates. Depending on the number of
  query points in `point`, we return either an ``Int`` or a ``Vector{Int}``.

## Returns:
- in = 1
- on = 0
- out = -1

## Reference

* Hao et al. 2018. [Optimal Reliable Point-in-Polygon Test and Differential Coding Boolean Operations on Polygons]
  (https://www.mdpi.com/2073-8994/10/10/477)
"""
inpolygon(x, y, D::GMTdataset) = pip(x, y, D.data)
inpolygon(x, y, poly::Matrix{T}) where T = pip(x, y, poly)
inpolygon(pt::VecOrMat, D::GMTdataset) = inpolygon(pt, D.data)
inpolygon(pt::GMTdataset, D::GMTdataset) = inpolygon(pt.data, D.data)
function inpolygon(pt::VecOrMat, poly::Matrix{T}) where T
	isvector(pt) && return pip(pt[1], pt[2], poly)
	n_pts = size(pt, 1)
	ind = zeros(Int, n_pts)
	[ind[k] = pip(pt[k,1], pt[k,2], poly) for k = 1:n_pts]
end

# ---------------------------------------------------------------------------------------------------
"""
    D = randinpolygon(Din; density=0.1, np::Int=0)

Generate random samples inside polygons. The method used here is that of poin-in-polygon. That is,
we generate random points inside a rectangular BoundingBox of each polygon and retain those inside
the polygon. For geographical polygons we generate random angles but do NOT connect the polygon
sides with great circles, so solution is not really geographic but the error is rather small if the
polygon vertices are close to each other.

- `Din`: The input polygons. It can be a ``GMTdaset``, a vector of them or a Mx2 matrix with the polygon vertices.
- `density`: the average density of the randomly generated points. For the Cartesian case this is a percentage
  that can be expressed in the ]0 1] or ]0 100] interval. For example, the default `density=0.1` means that points
  are created more or less at 1/10th of polygon's side. For geographical polygons (identified by the `proj` fields
  of the `GMTdataset`) the `density` means number of points per degree. The default of 20 represents a point
  scattering of about 1 every 5 km.
- `np`: The approximate number of points in each polygon. Note that this option overrides `density` and is not
  an exact requirement. That is `np=10` might return 9 or 11 or other number of points.

### Returns
A GMTdatset if only one polygon was passed or a Vector{GMTaset} otherwise.
"""
randinpolygon(mat::Matrix{<:AbstractFloat}; density=0.1, np::Int=0) = randinpolygon(mat2ds(mat); density=density, np=np)
function randinpolygon(Din::GDtype; density=0.1, np::Int=0)

	D = Vector{GMTdataset{Float64, 2}}(undef, isa(Din, Vector) ? length(Din) : 1)

	function get_the_points(_D, dx, dy, density, np, isgeo)
		# Points are returned in same data types as those of _D
		_dens = (!isgeo && density > 1) ? density / 10.0 : density
		_np = (np > 0) ? np : round(Int, (dx + dy) * 0.5 * ((isgeo && _dens == 0.1) ? 20 : _dens))	# In geog case default is 20/degree
		DT = eltype(_D)
		(DT == Float64) ? (_dx = dx; _dy = dy; x0 = _D.bbox[1]; y0 = _D.bbox[3]) : (_dx = convert(DT, dx); _dy = convert(DT, dy); x0 = convert(DT, _D.bbox[1]); y0 = convert(DT, _D.bbox[3]))
		if (isgeo)
			D2R = pi / 180
			x = rand(DT, _np) * _dx * D2R .+ x0 * D2R
			y = rand(DT, _np) * _dy * D2R .+ y0 * D2R
			x /= D2R;		y /= D2R
		else
			x = rand(DT, _np) * _dx .+ x0
			y = rand(DT, _np) * _dy .+ y0
		end
		gmtselect([x y], polygon=_D)
	end

	isgeo = isgeog(Din)
	nelm = isa(Din, Vector) ? length(Din) : 1	# Number of polygons
	for k = 1:nelm				# Loop over number of polygons
		isa(Din, Vector) ? ((dx, dy) = (Din[k].bbox[2] - Din[k].bbox[1], Din[k].bbox[4] - Din[k].bbox[3])) :
		                   ((dx, dy) = (Din.bbox[2] - Din.bbox[1], Din.bbox[4] - Din.bbox[3]))
		_D = isa(Din, Vector) ? Din[k] : Din
		insist = true
		local r
		while (insist)					# Insist untill we get points inside the polygon
			r = get_the_points(_D, dx, dy, density, np, isgeo)
			insist = isempty(r)			# No points found
			insist && (density *= 1.5)	# Increase density to make next attempt more likely of success
		end
		r.attrib, r.geom, r.proj4, r.wkt, r.epsg = _D.attrib, wkbMultiPoint, _D.proj4, _D.wkt, _D.epsg
		D[k] = r
	end
	set_dsBB!(D, false)
	return length(D) == 1 ? D[1] : D
end

# ---------------------------------------------------------------------------------------------------
"""
    lon, lat = randgeo(n; rad=false, limits=nothing, do360=false)

Generate random longitude and latitude coordinates.

By default the coordinates are in degrees and in the [-180 180] range. Set `do360` to `true` to get the
coordinates in the [0 360] range. Set `rad` to `true` to get the coordinates in radians instead of degrees.

Optionally, you can pass a 4-element array or tuple with the limits of the coordinates. `limits` must then
contain the lon_min, lon_max, lat_min, lat_max of the region where you want to generate random points.
"""
function randgeo(n; rad=false, limits=nothing, do360=false)
	(n <= 0) && error("Funny isn't it?. Zero or less number of points?")
	(limits !== nothing && length(limits) != 4) && throw(DomainError("limits must be a 4-element array or tuple"))
	R2D = (rad != 1) ? 180.0 / pi : 1.0
	shift180 = (do360 == 1) ? 0.0 : 180.0
	shift_lon = 0.0
	d_lon = 2pi
	fact1_lat, fact2_lat = 1.0, 1.0
	if (limits !== nothing)						# WRONG. NOT WORKING.
		d_lon *= (limits[2] - limits[1]) / 360.
		shift_lon = limits[1] - 180.0
		fact1_lat = sind(limits[4])
		fact2_lat = (sind(limits[4]) - sind(limits[3])) / 2
	end
	lon = d_lon * rand(n) * R2D .- shift180 .- shift_lon
	lat = -(acos.(fact1_lat .- 2 * fact2_lat * rand(n)) .- pi/2) * R2D
	return lon, lat
end

# ---------------------------------------------------------------------------------------------------
"""
    inout = inbbox(x::Real, y::Real, bbox) -> Bool

Find out if points `x,y` are inside a bounding box.

- `x, y`: point coordinates.
- `bbox` is a 4-element array (vector, matrix or tuple) with xmin, xmax, ymin, ymax.

### Returns
`true` for points inside the bounding box and `false` for those outside

"""
inbbox(x::Real, y::Real, bbox) = (x >= bbox[1] && x <= bbox[2] && y >= bbox[3] && y <= bbox[4])

# ---------------------------------------------------------------------------------------------------
function Base.:in(D1::GMTdataset, D2::GMTdataset)::Union{Bool, Int, Vector{Int}}
	# Accepts D1 -> Point and D2 -> Polygon, or vice-versa, or both of them as Polygons
	indPoint = (D1.geom == wkbPoint || D1.geom == wkbMultiPoint) ? 1 : 0
	indPoint = (indPoint == 0 && (D2.geom == wkbPoint || D2.geom == wkbMultiPoint)) ? 2 : indPoint
	indPol = (D1.geom == wkbPolygon || D1.geom == wkbPolygon25D) ? 1 : 0
	indPol = (indPol == 0 && (D2.geom == wkbPolygon || D2.geom == wkbPolygon25D)) ? 2 : indPol
	is2Pol = ((D2.geom == wkbPolygon || D2.geom == wkbPolygon25D) && (D1.geom == wkbPolygon || D1.geom == wkbPolygon25D))
	(!is2Pol && indPoint == 0 && indPol == 0) && error("Input arguments must have a Point and Polygon geometries, or both be Polygons.")
	if     (indPoint == 1 && indPol == 2)  inwhichpolygon([D2], D1.data)
	elseif (indPoint == 2 && indPol == 1)  inwhichpolygon([D1], D2.data)
	else   GMT.contains(D1, D2)		# Returns `true` if D1 contains D2.
	end
end

function Base.:in(D1::GDtype, D2::GDtype)::Union{Int, Vector{Int}}
	# Vector version. Accepts D1 -> Point and D2 -> Polygon, or vice-versa, or both of them as Polygons
	if (isa(D1, GMTdataset) && (D1.geom == wkbPoint || D1.geom == wkbMultiPoint) && isa(D2, Vector) && D2[1].geom == wkbPolygon)
		inwhichpolygon(D2, D1.data)
	elseif (isa(D2, GMTdataset) && (D2.geom == wkbPoint || D2.geom == wkbMultiPoint) && isa(D1, Vector) && D1[1].geom == wkbPolygon)
		inwhichpolygon(D1, D2.data)
	elseif (isa(D1, Vector) && isa(D2, Vector) && D1[1].geom == wkbPolygon && D2[1].geom == wkbPolygon)	# polygon(s) in polygon(s)
		ind = helper_ptvec_joins(D1, D2, contains, ispts=false)
		return length(ind) == 1 ? ind[1] : ind
	else
		error("One of the input arguments must have a Point and the other a Polygon geometries, or both be Polygons.")
	end
end

# ---------------------------------------------------------------------------------------------------
# Still need to figure out how to create a join table from the indices that we calculate here.
function spatialjoin(D1::GMTdataset, D2::Vector{<:GMTdataset}; pred::Function=intersects, kind=:left, kwargs...)
	!(D1.geom == wkbPoint || D1.geom == wkbMultiPoint) && error("First input must have a Point or Multipoint geometry.")
	ind = helper_ptvec_joins(D1, D2, pred, ispts=true)
	all(ind .== 0) && return D1						# Nothing joined. Warn?
	att_names = collect(keys(D2[1].attrib))			# Get all attributes names of D2
	idx = findfirst("Feature_ID" .== att_names)		# Find the "Feature_ID" attribute
	idx !== nothing && deleteat!(att_names, idx)	# And remove it if exists
	atts_vec = Vector{Vector{String}}(undef, length(att_names))

	function fill_atts_vec(D2, ind, atts_vec, att_names, isleft=true)
		[atts_vec[l] = Vector{String}(undef, length(ind)) for l = 1:length(att_names)]
		for k = 1:numel(ind)						# Loop over number of points in D1
			(isleft && ind[k] == 0) && ([atts_vec[l][k] = "" for l = 1:length(att_names)];	continue)	# Skip if not joined
			dic = D2[ind[k]].attrib					# Get the attributes Dict from this D2 polygon
			for l = 1:numel(att_names)				# Loop over the attributes
				atts_vec[l][k] = dic[att_names[l]]
			end
		end
		return atts_vec
	end

	if (kind == :left)
		atts_vec = fill_atts_vec(D2, ind, atts_vec, att_names)
		[D1.attrib[att_names[l]] = atts_vec[l] for l = 1:numel(att_names)]	# Add the new attributes to D1.attrib
		return D1
	else
		(kind != :inner) && error("Only :left or :inner joins are supported")
		ind_retain = findall(ind .!= 0)				# Indices of points to retain
		deleteat!(ind, findall(ind .== 0))			# Remove points that are not joined
		atts_vec = fill_atts_vec(D2, ind, atts_vec, att_names, false)
		D = mat2ds(D1, (ind_retain,:))				# TODO: Make this case a view
		[D.attrib[att_names[l]] = atts_vec[l] for l = 1:numel(att_names)]	# Add the new attributes to D.attrib
		return D
	end
end

function helper_ptvec_joins(D1, D2, pred; ispts=true)
	ind = Vector{Int}(undef, size(D1.data,1))
	nv = length(D2)
	for k = 1:size(D1.data,1)
		first_arg = ispts ? D1.data[k:k,1:2] : D1[k]	# A point or a higher order geometry
		m = 1
		while (m <= nv && !pred(first_arg, D2[m]))
			m += 1
		end
		ind[k] = m > nv ? 0 : m
	end
	ind
end
