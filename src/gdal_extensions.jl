# This file hosts functions that mimic some GEOS functions and interfaces the use off
# GMT and GDAL data types.

"""
    setproj!(type, proj)

Set a referencing system to the `type` object. This object can be a `GMTgrid`, a `GMTimage`,
a `GMTdataset` or an `AbstractDataset`.

- `proj` Is either a Proj4 string or a WKT. Alternatively, it can also be another grid, image or dataset
         type, in which case its referencing system is copied into `type`
"""
function setproj!(tipo::AbstractArray, proj::String="")
	(!isa(tipo, GMTgrid) && !isa(tipo, GMTimage) && !isa(tipo, GMTdataset) && !isa(tipo, Vector{<:GMTdataset})) &&
		error("Wrong data type for this function. Must be a grid, image or dataset")
	(proj == "") && error("the projection string cannot obviously be empty")
	isproj4 = (startswith(proj, "+proj") !== nothing)
	obj = (isa(tipo, Vector{<:GMTdataset})) ? tipo[1] : tipo
	(isproj4) ? (obj.proj4 = proj) : (obj.wkt = proj)
	return nothing
end
function setproj!(tipo::AbstractArray, ref)
	(!isa(ref, GMTgrid) && !isa(ref, GMTimage) && !isa(ref, GMTdataset) && !isa(ref, Vector{<:GMTdataset})) &&
		error("Wrong REFERENCE data type for this function. Must be a grid, image or dataset")
	obj = (isa(ref, Vector{<:GMTdataset})) ? ref[1] : ref
	((prj = obj.proj4) == "") && (prj = obj.wkt)
	(prj == "") && error("The REFERENCE type is not referenced with either PROJ4 or WKT string")
	setproj!(tipo, prj)
end
function setproj!(dataset::AbstractDataset, projstring::AbstractString)
	result = GDALSetProjection(dataset.ptr, projstring)
	@cplerr result "Could not set projection"
	return dataset
end

# ---------------------------------------------------------------------------------------------------
"""
    buffer(geom, dist::Real, quadsegs::Integer=30; gdataset=false)

Compute buffer of a geometry.

### Parameters
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `dist`: the buffer distance to be applied. Should be expressed into the
    same unit as the coordinates of the geometry.
* `quadsegs`: the number of segments used to approximate a 90 degree (quadrant) of curvature.

### Keywords
* `gdataset`: Returns a GDAL IGeometry even when input is a GMTdataset or Matrix

Builds a new geometry containing the buffer region around the geometry on which
it is invoked. The buffer is a polygon containing the region within the buffer
distance of the original geometry.

Some buffer sections are properly described as curves, but are converted to
approximate polygons. The `quadsegs` parameter can be used to control how many
segments should be used to define a 90 degree curve - a quadrant of a circle.
A value of 30 is a reasonable default. Large values result in large numbers of
vertices in the resulting buffer geometry while small numbers reduce the
accuracy of the result.

### Returns
A GMT dataset when input is a Matrix or a GMT type (except if `gdaset=true`), or a GDAL IGeometry otherwise
"""
buffer(geom::AbstractGeometry, dist::Real, quadsegs::Integer=30) = IGeometry(OGR_G_Buffer(geom.ptr, dist, quadsegs))
function buffer(D::AbstractArray, dist::Real, quadsegs::Integer=30; gdataset=false)
	geom = helper_1geom(D)
	ig = IGeometry(OGR_G_Buffer(geom.ptr, dist, quadsegs))
	return (gdataset) ? ig : gd2gmt(ig)
end

# ---------------------------------------------------------------------------------------------------
"""
    centroid(geom; gdataset=false)

### Parameters
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of them), or a Matrix

### Keywords
* `gdataset`: Returns a GDAL IGeometry even when input is a GMTdataset or Matrix

Compute the geometry centroid.

The centroid is not necessarily within the geometry.

(This method relates to the SFCOM ISurface::get_Centroid() method however the current implementation
based on GEOS can operate on other geometry types such as multipoint, linestring, geometrycollection
such as multipolygons. OGC SF SQL 1.1 defines the operation for surfaces (polygons). SQL/MM-Part 3
defines the operation for surfaces and multisurfaces (multipolygons).)

### Returns
A GMT dataset when input is a Matrix or a GMT type (except if `gdaset=true`), or a GDAL IGeometry otherwise
"""
function centroid(geom::AbstractGeometry)
	point = createpoint()
	centroid!(geom, point)
	return point
end
centroid(D; gdataset=false) = helper_geoms_run_fun(centroid, D; gdataset=gdataset)

function centroid!(geom::AbstractGeometry, centroid::AbstractGeometry)
	result = OGR_G_Centroid(geom.ptr, centroid.ptr)
	@ogrerr result "Failed to compute the geometry centroid"
	return centroid
end

# ---------------------------------------------------------------------------------------------------
"""
    intersection(geom1, geom2; gdataset=false)

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 

### Keywords
* `gdataset`: Returns a GDAL IGeometry even when input is GMTdataset or Matrix

Returns a new geometry representing the intersection of the geometries, or NULL
if there is no intersection or an error occurs.

Generates a new geometry which is the region of intersection of the two geometries operated on.
The `intersects` function can be used to test if two geometries intersect.

### Returns
A GMT dataset when input is a Matrix or a GMT type (except if `gdaset=true`), or a GDAL IGeometry otherwise
"""
intersection(g1::AbstractGeometry, g2::AbstractGeometry) = IGeometry(OGR_G_Intersection(g1.ptr, g2.ptr))
intersection(D1, D2; gdataset=false) = helper_geoms_run_fun(intersection, D1, D2; gdataset=gdataset)

# ---------------------------------------------------------------------------------------------------
"""
    polyunion(geom1, geom2; gdataset=false)

Computes a new geometry representing the union of the geometries.

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 

### Keywords
* `gdataset`: Returns a GDAL IGeometry even when input is GMTdataset or Matrix

### Returns
A GMT dataset when input is a Matrix or a GMT type (except if `gdaset=true`), or a GDAL IGeometry otherwise
"""
polyunion(g1::AbstractGeometry, g2::AbstractGeometry) = IGeometry(OGR_G_Union(g1.ptr, g2.ptr))
polyunion(D1, D2; gdataset=false) = helper_geoms_run_fun(polyunion, D1, D2; gdataset=gdataset)

# ---------------------------------------------------------------------------------------------------
"""
    difference(geom1, geom2; gdataset=false)

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 

### Keywords
* `gdataset`: Returns a GDAL IGeometry even when input is GMTdataset or Matrix

Generates a new geometry which is the region of this geometry with the region of the other geometry removed.

### Returns
A GMT dataset when input is a Matrix or a GMT type (except if `gdaset=true`), or a GDAL IGeometry otherwise
"""
difference(g1::AbstractGeometry, g2::AbstractGeometry) = IGeometry(OGR_G_Difference(g1.ptr, g2.ptr))
difference(D1, D2; gdataset=false) = helper_geoms_run_fun(difference, D1, D2; gdataset=gdataset)

# ---------------------------------------------------------------------------------------------------
"""
    symdifference(geom1, geom2; gdataset=false)

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 

### Keywords
* `gdataset`: Returns a GDAL IGeometry even when input is GMTdataset or Matrix

Generates a new geometry representing the symmetric difference of the geometries
or NULL if the difference is empty or an error occurs.

### Returns
A GMT dataset when input is a Matrix or a GMT type (except if `gdaset=true`), or a GDAL IGeometry otherwise
"""
symdifference(g1::AbstractGeometry, g2::AbstractGeometry) = IGeometry(OGR_G_SymDifference(g1.ptr, g2.ptr))
symdifference(D1, D2; gdataset=false) = helper_geoms_run_fun(symdifference, D1, D2; gdataset=gdataset)

# ---------------------------------------------------------------------------------------------------
"""
    distance(geom1, geom2)

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 

Returns the distance between the geometries or -1 if an error occurs.
"""
distance(g1::AbstractGeometry, g2::AbstractGeometry) = OGR_G_Distance(g1.ptr, g2.ptr)
distance(D1, D2) = helper_geoms_run_fun(distance, D1, D2, false)

# ---------------------------------------------------------------------------------------------------
"""
    geomarea(geom)

### Parameters
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix

Returns the area of the geometry or 0.0 for unsupported geometry types.
"""
geomarea(geom::AbstractGeometry) = OGR_G_Area(geom.ptr)
geomarea(D) = helper_geoms_run_fun(geomarea, D, false)

# ---------------------------------------------------------------------------------------------------
"""
    geodesicarea(geom)

Compute geometry area, considered as a surface on the underlying ellipsoid of the SRS attached to the geometry.
The returned area will always be in square meters, and assumes that polygon edges describe geodesic lines on the ellipsoid.
If the geometry' SRS is not a geographic one, geometries are reprojected to the underlying geographic SRS of the geometry' SRS.

### Parameters
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix

Returns the area of the geometry in square meters or a negative value in case of error for unsupported geometry types.
"""
geodesicarea(geom::AbstractGeometry) = OGR_G_GeodesicArea(geom.ptr)
geodesicarea(D) = helper_geoms_run_fun(geodesicarea, D, false)

# ---------------------------------------------------------------------------------------------------
"""
    geomlength(geom)

### Parameters
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix

Returns the length of the geometry, or 0.0 for unsupported geometry types.
"""
geomlength(geom::AbstractGeometry) = OGR_G_Length(geom.ptr)
geomlength(D) = helper_geoms_run_fun(geomlength, D, false)

# ---------------------------------------------------------------------------------------------------
"""
    envelope(geom)

### Parameters
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix

Computes and returns the bounding envelope for this geometry.
"""
function envelope(geom::AbstractGeometry)
    envelope = Ref{OGREnvelope}(OGREnvelope(0, 0, 0, 0))
    OGR_G_GetEnvelope(geom.ptr, envelope)
    return envelope[]
end
envelope(D) = helper_geoms_run_fun(envelope, D, false)

# ---------------------------------------------------------------------------------------------------
"""
    envelope3d(geom)

### Parameters
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix

Computes and returns the bounding envelope (3D) for this geometry
"""
function envelope3d(geom::AbstractGeometry)
    envelope = Ref{OGREnvelope3D}(OGREnvelope3D(0, 0, 0, 0, 0, 0))
    OGR_G_GetEnvelope3D(geom.ptr, envelope)
    return envelope[]
end
envelope3d(D) = helper_geoms_run_fun(envelope3d, D, false)

# ---------------------------------------------------------------------------------------------------
"""
    simplify(geom::AbstractGeometry, tol::Real; gdataset=false)

Compute a simplified geometry.

### Parameters
* `geom`: the geometry.
* `tol`: the distance tolerance for the simplification.

### Keywords
* `gdataset`: Returns a GDAL IGeometry even when input is GMTdataset or Matrix
"""
simplify(geom::AbstractGeometry, tol::Real) = IGeometry(OGR_G_Simplify(geom.ptr, tol))
function simplify(D, tol::Real; gdataset=false)
	ig = simplify(helper_1geom(D), tol)
	return (gdataset) ? ig : gd2gmt(ig)
end

# ---------------------------------------------------------------------------------------------------
"""
    delaunay(geom::AbstractGeometry, tol::Real=0, onlyedges::Bool=true; gdataset=false)

### Parameters
* `geom`: the geometry.
* `tol`: optional snapping tolerance to use for improved robustness
* `onlyedges`: if `true`, will return a MULTILINESTRING, otherwise it
    will return a GEOMETRYCOLLECTION containing triangular POLYGONs.
* `gdataset`: Returns a GDAL IGeometry even when input is GMTdataset or Matrix

Return a Delaunay triangulation of the vertices of the geometry.
"""
delaunaytriangulation(geom::AbstractGeometry, tol::Real, edges::Bool) = IGeometry(OGR_G_DelaunayTriangulation(geom.ptr, tol, edges))
function delaunaytriangulation(D, tol::Real=0, edges::Bool=true; gdataset=false)
	geom = helper_1geom(D)
	ig = delaunaytriangulation(geom, tol, edges)
	return (gdataset) ? ig : gd2gmt(ig)
end

# ---------------------------------------------------------------------------------------------------
"""
    intersects(geom1, geom2)

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 

Returns whether the geometries intersect

Determines whether two geometries intersect. If GEOS is enabled, then this is done in rigorous fashion
otherwise `true` is returned if the envelopes (bounding boxes) of the two geometries overlap.
"""
intersects(g1::AbstractGeometry, g2::AbstractGeometry) = Bool(OGR_G_Intersects(g1.ptr, g2.ptr))
function intersects(D1, D2)::Bool
	g1, g2 = helper_2geoms(D1, D2)
	intersects(g1, g2)
end

# ---------------------------------------------------------------------------------------------------
"""
    equals(geom1, geom2)

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 

Returns `true` if the geometries are equivalent.
"""
equals(g1::AbstractGeometry, g2::AbstractGeometry) = Bool(OGR_G_Equals(g1.ptr, g2.ptr))
equals(D1, D2) = helper_geoms_run_fun(equals, D1, D2, false)

# ---------------------------------------------------------------------------------------------------
"""
    disjoint(geom1, geom2)

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 

Returns `true` if the geometries are disjoint.
"""
disjoint(g1::AbstractGeometry, g2::AbstractGeometry) = Bool(OGR_G_Disjoint(g1.ptr, g2.ptr))
disjoint(D1, D2) = helper_geoms_run_fun(disjoint, D1, D2, false)

# ---------------------------------------------------------------------------------------------------
"""
    touches(geom1, geom2)

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 

Returns `true` if the geometries are touching.
"""
touches(g1::AbstractGeometry, g2::AbstractGeometry) = Bool(OGR_G_Touches(g1.ptr, g2.ptr))
touches(D1, D2) = helper_geoms_run_fun(touches, D1, D2, false)

# ---------------------------------------------------------------------------------------------------
"""
    crosses(geom1, geom2)

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 

Returns `true` if the geometries are crossing.
"""
crosses(g1::AbstractGeometry, g2::AbstractGeometry) = Bool(OGR_G_Crosses(g1.ptr, g2.ptr))
crosses(D1, D2) = helper_geoms_run_fun(crosses, D1, D2, false)

# ---------------------------------------------------------------------------------------------------
"""
    within(geom1, geom2)

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 

Returns `true` if g1 is contained within g2.
"""
within(g1::AbstractGeometry, g2::AbstractGeometry) = Bool(OGR_G_Within(g1.ptr, g2.ptr))
within(D1, D2) = helper_geoms_run_fun(within, D1, D2, false)

# ---------------------------------------------------------------------------------------------------
"""
    contains(geom1, geom2)

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 

Returns `true` if g1 contains g2.
"""
Base.:contains(g1::AbstractGeometry, g2::AbstractGeometry) = Bool(OGR_G_Contains(g1.ptr, g2.ptr))
Base.:contains(D1::Union{Matrix{<:Real}, GDtype}, D2::Union{Matrix{<:Real}, GDtype}) = helper_geoms_run_fun(contains, D1, D2, false)

# ---------------------------------------------------------------------------------------------------
"""
    overlaps(geom1, geom2)

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 

Returns `true` if the geometries overlap.
"""
overlaps(g1::AbstractGeometry, g2::AbstractGeometry) = Bool(OGR_G_Overlaps(g1.ptr, g2.ptr))
overlaps(D1, D2) = helper_geoms_run_fun(overlaps, D1, D2, false)

# ---------------------------------------------------------------------------------------------------
"""
    boundary(geom; gdataset=false)

### Parameters
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `gdataset`: Returns a GDAL IGeometry even when input are GMTdataset or Matrix

A new geometry object is created and returned containing the boundary of the
geometry on which the method is invoked.

### Returns
A GMT dataset when input is a Matrix or a GMT type (except if `gdaset=true`), or a GDAL IGeometry otherwise
"""
boundary(geom::AbstractGeometry) = IGeometry(OGR_G_Boundary(geom.ptr))
boundary(D; gdataset=false) = helper_geoms_run_fun(boundary, D; gdataset=gdataset)

# ---------------------------------------------------------------------------------------------------
"""
    convexhull(geom; gdataset=false)

### Parameters
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `gdataset`: Returns a GDAL IGeometry even when input are GMTdataset or Matrix

A new geometry object is created and returned containing the convex hull of the geometry on which the method is invoked.

### Returns
A GMT dataset when input is a Matrix or a GMT type (except if `gdaset=true`), or a GDAL IGeometry otherwise
"""
convexhull(geom::AbstractGeometry) = IGeometry(OGR_G_ConvexHull(geom.ptr))
convexhull(D; gdataset=false) = helper_geoms_run_fun(convexhull, D; gdataset=gdataset)

# ---------------------------------------------------------------------------------------------------
"""
    concavehull(geom, ratio, allow_holes::Bool=true; gdataset=false)

### Parameters
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `ratio`: Ratio of the area of the convex hull and the concave hull. 
* `allow_holes`: Whether holes are allowed.
* `gdataset`: Returns a GDAL IGeometry even when input are GMTdataset or Matrix

### Returns
A GMT dataset when input is a Matrix or a GMT type (except if `gdaset=true`), or a GDAL IGeometry otherwise
"""
concavehull(geom::AbstractGeometry, ratio, holes::Bool=true) = IGeometry(OGR_G_ConcaveHull(geom.ptr, Float64(ratio), holes))
concavehull(D, ratio, holes::Bool=true; gdataset=false) = helper_geoms_run_fun(concavehull, D, Float64(ratio), holes; gdataset=gdataset)

# ---------------------------------------------------------------------------------------------------
"""
    pointalongline(geom, distance::Real; gdataset=false)

### Parameters
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `distance`: distance along the curve at which to sample position. This
    distance should be between zero and geomlength() for this curve.
* `gdataset`: Returns a GDAL IGeometry even when input are GMTdataset or Matrix

Fetch point (or NULL) at given distance along curve.

### Returns
A GMT dataset when input is a Matrix or a GMT type (except if `gdaset=true`), or a GDAL IGeometry otherwise
"""
pointalongline(geom::AbstractGeometry, distance::Real) = IGeometry(OGR_G_Value(geom.ptr, distance))
function pointalongline(D, distance::Real; gdataset=false)
	geom = helper_1geom(D)
	ig = pointalongline(geom, distance)
	return (gdataset) ? ig : gd2gmt(ig)
end

# ---------------------------------------------------------------------------------------------------
"""
    arccircle(x0, y0, radius, start_angle, end_angle; z0=0, inc=2, gdataset=false)

### Parameters
* `x0`: center X
* `y0`: center Y
* `radius`: radius of the circle.
* `start_angle`: angle to first point on arc (clockwise of X-positive) 
* `end_angle`: angle to last point on arc (clockwise of X-positive) 

### Keywords
* `z0`: center Z. Optional, if not provided the output is flat 2D
* `inc`: the largest step in degrees along the arc. Default is 2 degree
* `gdataset`: Returns a GDAL IGeometry even when input are GMTdataset or Matrix

### Returns
A GMT dataset or a GDAL IGeometry
"""
arccircle(x0, y0, r, a1, a2; z0=NaN, inc=0.0, gdataset=false) =
	arcellipse(x0, y0, r, r, a1, a2; rotation=0.0, z0=z0, inc=inc, gdataset=gdataset)

# ---------------------------------------------------------------------------------------------------
"""
    arcellipse(x0, y0, primary_radius, secondary_radius, start_angle, end_angle; rotation=0, z0=0, inc=2, gdataset=false)

### Parameters
* `x0`: center X
* `y0`: center Y
* `primary_radius`: X radius of ellipse.
* `secondary_radius`: Y radius of ellipse.
* `start_angle`: angle to first point on arc (clockwise of X-positive)
* `end_angle`: angle to last point on arc (clockwise of X-positive)
### Keywords
* `rotation`: rotation of the ellipse clockwise.
* `z0`: center Z. Optional, if not provided the output is flat 2D
* `inc`: the largest step in degrees along the arc. Default is 2 degree
* `gdataset`: Returns a GDAL IGeometry even when input are GMTdataset or Matrix

### Returns
A GMT dataset or a GDAL IGeometry
"""
function arcellipse(x0, y0, r1, r2, a1, a2; rotation=0.0, z0=NaN, inc=2.0, gdataset=false)
	_z0 = isnan(z0) ? 0.0 : Float64(inc)
	ig = IGeometry(OGR_G_ApproximateArcAngles(x0, y0, _z0, r1, r2, rotation, a1, a2, inc))
	(gdataset) && return ig
	D = gd2gmt(ig)
	D.colnames = (isnan(z0)) ? ["x", "y"] : ["x", "y", "z"]
	if (isnan(z0))		# Drop the z0 = 0 col. It was not asked for.
		D.data = D.data[:,1:2];	D.bbox = D.bbox[1:4];	D.ds_bbox = D.ds_bbox[1:4];
	end 
	D
end

# ---------------------------------------------------------------------------------------------------
"""
    polygonize(geom; gdataset=false)

### Parameters
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `gdataset`: Returns a GDAL IGeometry even when input are GMTdataset or Matrix

Polygonizes a set of sparse edges.

A new geometry object is created and returned containing a collection of
reassembled Polygons: NULL will be returned if the input collection doesn't
correspond to a MultiLinestring, or when reassembling Edges into Polygons is
impossible due to topological inconsistencies.

### Returns
A GMT dataset when input is a Matrix or a GMT type (except if `gdaset=true`), or a GDAL IGeometry otherwise
"""
polygonize(geom::AbstractGeometry) = IGeometry(OGR_G_Polygonize(geom.ptr))
polygonize(D; gdataset=false) = helper_geoms_run_fun(polygonize, D; gdataset=gdataset)

# ---------------------------------------------------------------------------------------------------
function helper_geoms_run_fun(f::Function, D1, D2, retds::Bool=true; gdataset=false)
	# Helper function that checks if geoms intersect and then run the F function
	# If GDATASET is true, return the GDAL dataset
	g1, g2 = helper_2geoms(D1, D2)
	ig = f(g1, g2)
	(gdataset) && (retds = false)
	return (retds) ? gd2gmt(ig) : ig
end
function helper_geoms_run_fun(f::Function, D, retds::Bool=true; gdataset=false)
	(gdataset) && (retds = false)
	if (isa(D, Vector{<:GMTdataset}) && (f == centroid))
		# Don't know if due to bad implementation or it's the way it is, the centroid function only Computes
		# that of first polygon, so we have to loop over D[k]. Restrictred so far to the centroid function.
		mat = Array{Float64,2}(undef, length(D), 2)
		for k = 1:lastindex(D)
			geom = helper_1geom(D[k])
			ig = f(geom)
			mat[k,1], mat[k,2] = Gdal.getx(ig, 0), Gdal.gety(ig, 0)
		end
		Dc = mat2ds(mat, geom=1, proj4=D[1].proj4, wkt=D[1].wkt, epsg=D[1].epsg)
		!isempty(D[1].colnames) && (Dc.colnames = D[1].colnames[1:2])
		Dc.comment = ["Centroids"]
		return (retds) ? Dc : gmt2gd(Dc)
	end
	geom = helper_1geom(D)
	ig = f(geom)
	return (retds) ? gd2gmt(ig) : ig
end
function helper_geoms_run_fun(f::Function, D, ratio::Float64, holes::Bool=true; gdataset=false)
	geom = helper_1geom(D)
	ig = f(geom, ratio, holes)
	(isa(ig, Gdal.IGeometry) && ig.ptr == C_NULL) && error("Error in $f. Output is NULL")
	return (gdataset) ? ig : gd2gmt(ig)
end

function helper_2geoms(D1::Union{Matrix{<:Real}, GDtype}, D2::Union{Matrix{<:Real}, GDtype})
	# Helper function that deals with arg checking and data type conversions, This is common to several funs here
	ds1 = gmt2gd(D1)
	ds2 = gmt2gd(D2)
	g1  = getgeom(unsafe_getfeature(getlayer(ds1, 0),0))
	g2  = getgeom(unsafe_getfeature(getlayer(ds2, 0),0))
	return g1, g2
end

function helper_1geom(D::Union{Matrix{<:Real}, GDtype})
	ds = gmt2gd(D)
	getgeom(unsafe_getfeature(getlayer(ds, 0),0))
end
