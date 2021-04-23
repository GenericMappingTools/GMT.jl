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
    buffer(geom::AbstractGeometry, dist::Real, quadsegs::Integer = 30)
or
    buffer(geom::GMTdataset, dist::Real, quadsegs::Integer = 30)

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

### Parameters
* `geom`: the geometry. This can either be a GDAL type or a GMTdataset (or vector of it), or a Matrix
* `dist`: the buffer distance to be applied. Should be expressed into the
    same unit as the coordinates of the geometry.
* `quadsegs`: the number of segments used to approximate a 90 degree (quadrant) of curvature.

### Returns
A GMT dataset when input is a Matrix or a GMT type, or a GDAL IGeometry otherwise
"""
buffer(geom::AbstractGeometry, dist::Real, quadsegs::Integer=30) = IGeometry(OGR_G_Buffer(geom.ptr, dist, quadsegs))
function buffer(D::AbstractArray, dist::Real, quadsegs::Integer=30)
	(isa(D, Vector{<:Real})) && error("Input data cannot be a Vector of numbers. In this case it must be a Matrix")
	ds = gmt2gd(D)
	geom = getgeom(unsafe_getfeature(getlayer(ds, 0),0))
	ig = IGeometry(OGR_G_Buffer(geom.ptr, dist, quadsegs))
	gd2gmt(ig)
end
