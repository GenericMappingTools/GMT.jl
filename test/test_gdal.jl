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
	crs = toWKT(importPROJ4("+proj=latlong"), true);
	writegd!(dataset, rand(180,240), 1)
	setproj!(dataset, crs)
	setgeotransform!(dataset, [-4.016666666666667, 0.03333333333333333, 0.0, -3.01666666666, 0.0, 0.03333333333333333])

	show(dataset)

	#readgd(dataset);		# Ambiguo
	#band = getband(dataset);
	readgd(band);
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
	Gdal.getgeotransform(dataset)

	getdriver(dataset)
	getdriver(5)

	toPROJ4(importEPSG(4326))
	importWKT(crs)

	Gdal.shortname(getdriver("GTiff"));
	Gdal.longname(getdriver("GTiff"));
	Gdal.driveroptions("MEM");

	Gdal.GDALError();
	Gdal.CPLGetLastErrorNo();
	Gdal.CPLGetLastErrorMsg();
	Gdal.GDALGetColorInterpretationName(1);
	Gdal.GDALGetPaletteInterpretationName(1);
	Gdal.OCTDestroyCoordinateTransformation(C_NULL);

	ds_small = readgd("utmsmall.tif");
	Gdal.getlayer(ds_small, 1);
	gdalinfo(ds_small, [""]);
	gdalwarp(ds_small, [""]);
	gdaldem(ds_small, "hillshade", ["-q"]);
	gdaltranslate(ds_small, [""]);

	ds_point = readgd("point.geojson");
	ds_grid = gdalgrid(ds_point, ["-of","MEM","-outsize","3", "10","-txe","100","100.3","-tye","0","0.1"]);
	@test getgeotransform(ds_grid) ≈ [100.0,0.1,0.0,0.0,0.0,0.01]
	#readgd(ds_grid)

	ds_csv = gdalvectortranslate(ds_point, ["-f","CSV","-lco", "GEOMETRY=AS_XY"], dest = "point.csv");
	#=
	@test replace(read("point.csv", String), "\r" => "") == """
	X,Y,FID,pointname
	100,0,2,point-a
	100.2785,0.0893,3,point-b
	100,0,0,a
	100.2785,0.0893,3,b
	"""
	=#

end