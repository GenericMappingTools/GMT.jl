@testset "GDAL" begin

#=
Gdal.GDALAllRegister()

driver = Gdal.GDALGetDriverByName("GTiff")
srs = Gdal.OSRNewSpatialReference(C_NULL)
Gdal.OSRImportFromEPSG(srs, 4326) 			# fails if GDAL_DATA is not set correctly
Gdal.GDALDestroyDriverManager()
=#

	version = Gdal.GDALVersionInfo("--version")
	n_gdal_driver = Gdal.GDALGetDriverCount()
	n_ogr_driver = Gdal.OGRGetDriverCount()
	@info """$version
	$n_gdal_driver GDAL drivers found
	$n_ogr_driver OGR drivers found
	"""

	dataset = creategd("", driver = getdriver("MEM"), width=240, height=180, nbands=1, dtype=Float64)
	crs = toWKT(importPROJ4("+proj=latlong"));
	writegd!(dataset, rand(180,240), 1)
	setproj!(dataset, crs)
	setgeotransform!(dataset, [-4.016666666666667, 0.03333333333333333, 0.0, -3.01666666666, 0.0, 0.03333333333333333])

	#readgd(dataset);		# Ambiguo
	getproj(dataset)
	band = getband(dataset)
	Gdal.width(dataset)
	Gdal.width(band)
	Gdal.height(dataset)
	Gdal.height(band)
	Gdal.nlayer(dataset)
	Gdal.nraster(dataset)
	Gdal.filelist(dataset)
	Gdal.accessflag(band)
	Gdal.indexof(band)
	Gdal.pixeltype(band)
	Gdal.getcolorinterp(band)

	getdriver(dataset)
	getdriver(5)

	toPROJ4(importEPSG(4326))
	importWKT(crs)

	Gdal.shortname(getdriver("GTiff"));
	Gdal.longname(getdriver("GTiff"));
	Gdal.driveroptions("MEM");

end