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
	(!isa(tipo, GMT.GMTgrid) && !isa(tipo, GMT.GMTimage) && !isa(tipo, GMT.GMTdataset) && !isa(tipo, Vector{GMT.GMTdataset})) &&
		error("Wrong data type for this function. Must be a grid, image or dataset")
	(proj == "") && error("the projection string cannot obviously be empty")
	isproj4 = (startswith(proj, "+proj") !== nothing)
	obj = (isa(tipo, Vector{GMT.GMTdataset})) ? tipo[1] : tipo
	(isproj4) ? (obj.proj4 = proj) : (obj.wkt = proj)
	return nothing
end
function setproj!(tipo::AbstractArray, ref)
	(!isa(ref, GMT.GMTgrid) && !isa(ref, GMT.GMTimage) && !isa(ref, GMT.GMTdataset) && !isa(ref, Vector{GMT.GMTdataset})) &&
		error("Wrong REFERENCE data type for this function. Must be a grid, image or dataset")
	obj = (isa(ref, Vector{GMT.GMTdataset})) ? ref[1] : ref
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
    buffer(geom, dist::Real, quadsegs::Integer = 30; gdataset=false)

### Parameters
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `dist`: the buffer distance to be applied. Should be expressed into the
    same unit as the coordinates of the geometry.
* `quadsegs`: the number of segments used to approximate a 90 degree (quadrant) of curvature.
* `gdataset`: Returns a GDAL IGeometry even when input is a GMTdataset or Matrix

Compute buffer of geometry.

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
* `geom`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
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
* `gdataset`: Returns a GDAL IGeometry even when input are GMTdataset or Matrix

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

### Parameters
* `geom1`: the geometry. This can either be a GDAL AbstractGeometry or a GMTdataset (or vector of it), or a Matrix
* `geom2`: Second geometry. AbstractGeometry if `geom1::AbstractGeometry` or a GMTdataset/Matrix if `geom1` is GMT type 
* `gdataset`: Returns a GDAL IGeometry even when input are GMTdataset or Matrix

Computes a new geometry representing the union of the geometries.

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
* `gdataset`: Returns a GDAL IGeometry even when input are GMTdataset or Matrix

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
* `gdataset`: Returns a GDAL IGeometry even when input are GMTdataset or Matrix

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
    delaunay(geom::AbstractGeometry, tol::Real, onlyedges::Bool)

### Parameters
* `geom`: the geometry.
* `tol`: optional snapping tolerance to use for improved robustness
* `onlyedges`: if `true`, will return a MULTILINESTRING, otherwise it
    will return a GEOMETRYCOLLECTION containing triangular POLYGONs.

Return a Delaunay triangulation of the vertices of the geometry.
"""
delaunaytriangulation(geom::AbstractGeometry, tol::Real, edges::Bool) = IGeometry(OGR_G_DelaunayTriangulation(geom.ptr, tol, edges))
function delaunaytriangulation(D, tol::Real, edges::Bool; gdataset=false)
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
contains(g1::AbstractGeometry, g2::AbstractGeometry) = Bool(OGR_G_Contains(g1.ptr, g2.ptr))
contains(D1, D2) = helper_geoms_run_fun(contains, D1, D2, false)

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
	(!intersects(g1, g2)) && @warn("These two geometries do not intersect")
	ig = f(g1, g2)
	(gdataset) && (retds = false)
	return (retds) ? gd2gmt(ig) : ig
end
function helper_geoms_run_fun(f::Function, D, retds::Bool=true; gdataset=false)
	geom = helper_1geom(D)
	ig = f(geom)
	(gdataset) && (retds = false)
	return (retds) ? gd2gmt(ig) : ig
end

function helper_2geoms(D1, D2)
	# Helpr function that deals with arg checking and data type conversions, This is common to several funs here
	(!isa(D1, Matrix{<:Real}) && !isa(D2, Matrix{<:Real}) && !isa(D1, GMT.GMTdataset) && !isa(D1, Vector{<:GMT.GMTdataset}) && !isa(D2, GMT.GMTdataset) && !isa(D2, Vector{<:GMT.GMTdataset})) && error("Input mut be GMTdatset or Matrix{Real}")
	ds1 = gmt2gd(D1)
	ds2 = gmt2gd(D2)
	g1  = getgeom(unsafe_getfeature(getlayer(ds1, 0),0))
	g2  = getgeom(unsafe_getfeature(getlayer(ds2, 0),0))
	return g1, g2
end

function helper_1geom(D)
	(!isa(D, Matrix{<:Real}) && !isa(D, Matrix{<:Real}) && !isa(D, GMT.GMTdataset) && !isa(D, Vector{<:GMT.GMTdataset}) ) && error("Input mut be GMTdatset or Matrix{Real}")
	ds = gmt2gd(D)
	geom = getgeom(unsafe_getfeature(getlayer(ds, 0),0))
end
