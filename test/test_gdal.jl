@testset "GDAL" begin

#=
Gdal.GDALAllRegister()

version = Gdal.GDALVersionInfo("--version")
n_gdal_driver = Gdal.GDALGetDriverCount()
n_ogr_driver = Gdal.OGRGetDriverCount()
@info """$version
$n_gdal_driver GDAL drivers found
$n_ogr_driver OGR drivers found
"""

driver = Gdal.GDALGetDriverByName("GTiff")

srs = Gdal.OSRNewSpatialReference(C_NULL)
Gdal.OSRImportFromEPSG(srs, 4326) 			# fails if GDAL_DATA is not set correctly

Gdal.GDALDestroyDriverManager()
=#

dataset = creategd("", driver = getdriver("MEM"), width=240, height=180, nbands=1, dtype=Float64)
	crs = toWKT(importPROJ4("+proj=latlong"));
	writegd!(dataset, rand(180,240), 1)
	setproj!(dataset, crs)
	band = getband(dataset)


end