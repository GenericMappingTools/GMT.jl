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
	DT = eltype(vals);
	(DT != Union{Missing, Float64} && DT != Union{Missing, Float32} && DT != Union{Missing, Int}) && @warn("Probable error in data type ($DT)")
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
  that attribute/value combination. `NAME=("Antioquia", "Caldas"), pick elements that have those `NAME` attributes.
  Add as many as wished. If using two `kwargs` the second works as a condition. ``(..., NAME=("Antioquia", "Caldas"), feature_id=0)``
  means select all elements from ``Antioquia`` and ``Caldas`` that have the attribute `feature_id` = 0.
- `attrib` or `att`: (OLD SYNTAX) A NamedTuple with the attribname, attribvalue as in `att=(NAME_2="value",)`.
  Use more elements if wishing to do a composite match. E.g. `att=(NAME_1="val1", NAME_2="val2")` in which
  case only segments matching the two conditions are returned.
- `index`: Use this `positional` argument = `true` to return only the segment indices that match the `att` condition(s).

### Returns
Either a vector of GMTdataset, or a vector of Int with the indices of the segments that match the query condition.
Or `nothing` if the query results in an empty GMTdataset 

## Example:

    D = filter(D, NAME_2="Porto");
"""
function getbyattrib(D::Vector{<:GMTdataset}, ind_::Bool; kw...)::Vector{Int}
	# This method does the work but it's not the one normally used by the public.
	# It returns the indices of the selected segments.
	(isempty(D[1].attrib)) && (@warn("This datset does not have an `attrib` field and is hence unusable here."); return Int[])
	dounion = Int(1e9)		# Just a big number
	if ((_att = find_in_kwargs(kw, [:att :attrib])[1]) !== nothing)		# For backward compat.
		if !isa(_att, NamedTuple)
			((val = find_in_kwargs(kw, [:val :value])[1])  === nothing) && error("Must provide the `attribute` VALUE.")
		end
		atts, vals = isa(_att, NamedTuple) ? (string.(keys(_att)), string.(values(_att))) : ((string(_att),), (string(val),))
	else
		# FCK unbelievable case. Julia can be f. desparing. It took me an whole afternoon to make this work.
		#d = KW(kw); Keys = keys(d);
		#Keys[1] => Internal Error: MethodError: no method matching getindex(::Base.KeySet{Symbol, Dict{Symbol, Any}}, ::Int64)
		count, kk = 0, 1
		v = values(kw)
		for k = 1:numel(kw)  count += (isa(values(v[k]), Tuple)) ? length(values(v[k])) : 1  end
		atts, vals = Vector{String}(undef, count), Vector{String}(undef, count)

		_keys = string.(keys(kw))
		for k = 1:numel(kw)
			vv = values(v[k])
			if (isa(vv, Tuple))
				atts[kk:kk+length(vv)-1] .= _keys[k]
				vals[kk:kk+length(vv)-1] .= string.(vv)
				kk += length(vv) 
			else
				atts[kk], vals[kk] = _keys[k], string(vv)
				kk += 1
			end
			(k == 1) && (dounion = kk)		# Index that separates the unions from the interceptions
		end
	end

	indices::Vector{Int} = Int[]
	ky = keys(D[1].attrib)
	for n = 1:numel(atts)
		((ind = findfirst(ky .== atts[n])) === nothing) && continue
		tf = fill(false, length(D))
		for k = 1:length(D)
			(!isempty(D[k].attrib) && (D[k].attrib[atts[n]] == vals[n])) && (tf[k] = true)
		end
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
	return o
end

# ---------------------------------------------------------------------------------------------------
Base.:filter(D::Vector{<:GMTdataset}; kw...) = getbyattrib(D; kw...)
Base.:findall(D::Vector{<:GMTdataset}; kw...) = getbyattrib(D, true; kw...)

# ---------------------------------------------------------------------------------------------------
"""
    inwhichpolygon(D::Vector{GMTdataset}, point::Matrix{Real})
or

    inwhichpolygon(D::Vector{GMTdataset}, x, y)

Finds the IDs of the polygons enclosing the query points in `point`. Each row in the matrix `point` contains
the coordinates of a query point. Query points that don't fall in any polygon get an ID = 0.
Returns either an ``Int`` or a ``Vector{Int}`` depending on the number of input quiery points.

- `D`: A Vector of GMTdadaset defining the polygons.
- `point`: A Mx2 matrix or a two elements vector with the x and y point coordinates.
- `x, y`:  Specifies the x-coordinates and y-coordinates of 2-D query points as separate vectors (or two scalars).

### Example:
    pts = [[1 2 3;1 2 3;1 2 3][:] [1 1 1;2 2 2; 3 3 3][:]];
    D = triplot(pts, noplot=true);
    points = [2.4 1.2; 1.4 1.4];
    ids = inwhichpolygon(D, points);
    # Plot the triangulation and the query points.
    plot(D)
    plot!(D[ids[1]], fill=:grey)
    plot!(D[ids[2]], fill=:green)
    plot!(points, marker=:star, ms="12p", fill=:blue, show=true)
"""
inwhichpolygon(D::Vector{<:GMTdataset}, x, y) = inwhichpolygon(D, [x y])
function inwhichpolygon(D::Vector{<:GMTdataset}, point::VMr)::Union{Int, Vector{Int}}
	pt::Matrix{<:Real} = isa(point, Vector) ? [point[1] point[2]] : point

	iswithin(bbox, x, y) = (x >= bbox[1] && x <= bbox[2] && y >= bbox[3] && y <= bbox[4])

	npts = size(pt,1);		ind_pol = zeros(Int, npts)
	for n = 1:npts
		for k = 1:length(D)
			!iswithin(D[k].bbox, pt[n,1], pt[n,2]) && continue
			r = gmtselect(pt[n:n, :], polygon=D[k])
			if (!isempty(r))
				ind_pol[n] = k
				break
			end
		end
	end
	return (npts == 1) ? ind_pol[1] : ind_pol
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

	D::Vector{GMTdataset} = Vector{GMTdataset}(undef, isa(Din, Vector) ? length(Din) : 1)

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
