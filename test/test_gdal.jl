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

	dataset = Gdal.create("", driver = getdriver("MEM"), width=241, height=181, nbands=1, dtype=Float64)
	Gdal.gdal_get_limits(dataset)
	crs = toWKT(importPROJ4("+proj=latlong"), true);
	crs = toWKT(importPROJ4("+proj=latlong"));
	importWKT(crs)
	Gdal.importWKT!(importWKT(crs), toWKT(importPROJ4("+proj=latlong")))
	Gdal.write!(dataset, rand(181,241), 1)
	setproj!(dataset, crs)
	setgeotransform!(dataset, [-4.016666666666667, 0.03333333333333333, 0.0, -3.01666666666, 0.0, 0.03333333333333333])
	Gdal.gdal_get_limits(dataset)
	Gdal.listcapability(dataset)

	#show(dataset)
	sprint(print, dataset)

	band = getband(dataset);
	Gdal.read(band);
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

	gdalinfo("utmsmall.tif");
	GMT.regiongeog("utmsmall.tif")
	ds_small = Gdal.read("utmsmall.tif");
	Gdal.getlayer(ds_small, 1);
	gdalinfo(ds_small);
	#gdaldem("utmsmall.tif", "hillshade", ["-q"], save="lixo.nc");
	#rm("lixo.nc")
	gdaldem(ds_small, "hillshade", ["-az", "10"]);
	gdaltranslate(ds_small);
	gdaltranslate("utmsmall.tif", R="442000/445000/3747000/3750000");
	gdaltranslate("utmsmall.tif+b0");
	gdaltranslate("utmsmall.tif", ["-b","1"]);
	@info "1..."
	try		# Stupid Macports gdal does not have AAIGrid driver
	ds_tiny = gdaltranslate(ds_small, ["-of","AAIGrid","-r","cubic","-tr","1200","1200"], gdataset=true) # resample to a 5×5 ascii grid
	@info "2..."
	@test Gdal.read(ds_tiny, 1) == [128  171  127   93   83; 126  164  148  114  101;
									161  175  177  164  140; 185  206  205  172  128;
									193  205  209  181  122]
	
	ds_vrt = gdalbuildvrt([ds_tiny])
	@test Gdal.read(ds_vrt, 1) == [128  171  127   93   83; 126  164  148  114  101;
									161  175  177  164  140; 185  206  205  172  128;
									193  205  209  181  122]
	catch
	end

	gdalwarp(ds_small);
	ds_warped = gdalwarp("utmsmall.tif", ["-of","MEM","-t_srs","EPSG:4326"], I=0.005, gdataset=true)
	ds_warped = gdalwarp("utmsmall.tif", ["-of","MEM","-t_srs","EPSG:4326"], gdataset=true)
	@test Gdal.width(ds_warped) == 109
	@test Gdal.height(ds_warped) == 91

	ds_point = Gdal.read("point.geojson");
	ds_grid = gdalgrid(ds_point, ["-of","MEM","-outsize","3", "10","-txe","100","100.3","-tye","0","0.1"], gdataset=true);
	#@test getgeotransform(ds_grid) ≈ [100.0,0.1,0.0,0.0,0.0,0.01]
	ds_point = Gdal.read("point.geojson");
	layer = Gdal.getlayer(ds_point, 0);
	feature = Gdal.nextfeature(layer)
	@test Gdal.asdouble(feature, 0) ≈ 2.0
	@test Gdal.asstring(feature, 1) == "point-a"
	sprint(print, feature)
	sprint(print, Gdal.getfielddefn(feature, 1))
	sprint(print, Gdal.getgeomdefn(feature, 0))
	sprint(print, ds_point)

	ds_rasterize = gdalrasterize(ds_point, ["-of","MEM","-tr","0.05","0.05"], gdataset=true)
	@test getgeotransform(ds_rasterize) ≈ [99.975,0.05,0.0,0.1143,0.0,-0.05]

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

	Gdal.createmultipoint([(1251243.7361610543, 598078.7958668759), (1250318.7031934808, 606404.0925750365)]);

	@test GMT.R_inc_to_gd([0.01], " -R-11/-1/33/45")[1] == "-txe";

	dataset = Gdal.create(Gdal.getdriver("MEMORY"))
	layer = Gdal.createlayer(name = "point_out", dataset = dataset, geom = Gdal.wkbPoint)
	Gdal.addfielddefn!(layer, "Name", Gdal.OFTString, nwidth = 32)
	featuredefn = Gdal.layerdefn(layer)
	@test Gdal.getname(featuredefn) == "point_out"
	@test Gdal.nfeature(layer) == 0
	Gdal.createfeature(layer) do feature
		Gdal.setfield!(feature, Gdal.findfieldindex(feature, "Name"), "myname")
		Gdal.setgeom!(feature, Gdal.createpoint(100.123, 0.123))
	end
	@test Gdal.nfeature(layer) == 1

	ds_src = Gdal.read("utmsmall.tif")
	isa(ds_src, Gdal.RasterDataset{UInt8})
	Gdal.write(ds_src, "/vsimem/utmsmall.tif")
	ds_copy = Gdal.read("/vsimem/utmsmall.tif")
	@test Gdal.read(ds_src) == Gdal.read(ds_copy)
	@test Gdal.metadata(ds_src) == ["AREA_OR_POINT=Area"]
	@test Gdal.metadataitem(ds_src, "AREA_OR_POINT") == "Area"
	@test Gdal.metadata(ds_src, domain = "IMAGE_STRUCTURE") == ["INTERLEAVE=BAND"]
	@test Gdal.metadatadomainlist(ds_src) == ["IMAGE_STRUCTURE", "", "DERIVED_SUBDATASETS"]
	@test Gdal.getconfigoption("GDAL_CACHEMAX") == ""
	Gdal.setconfigoption("GDAL_CACHEMAX", "64")
	@test Gdal.getconfigoption("GDAL_CACHEMAX") == "64"
	Gdal.clearconfigoption("GDAL_CACHEMAX")
	@test Gdal.getconfigoption("GDAL_CACHEMAX", "128") == "128"

	Gdal.GDALGetDescription(ds_src.ptr)
	imshow(ds_src, Vd=dbg2)

	rb = Gdal.getband(ds_src, 1)
	#@test Gdal.getnodatavalue(rb) === nothing
	Gdal.setnodatavalue!(rb, -100)
	@test Gdal.getnodatavalue(rb) ≈ -100
	Gdal.getcolorinterp(rb)

	ct = Gdal.createcolortable(1)		# GDAL.GPI_RGB = 1
	Gdal.createcolorramp!(ct, 128, Gdal.GDALColorEntry(0,0,0,0), 255, Gdal.GDALColorEntry(0,0,255,0))

	line = Gdal.createlinestring()
	Gdal.addpoint!(line, 1116651.439379124,  637392.6969887456)
	Gdal.OGR_G_SetPoints(line.ptr, 3, [1.,2,3], sizeof(Float64), [4.,5,6], sizeof(Float64), [7.,8,9], sizeof(Float64))
	xx = Gdal.getpoint(line, 1)
	@test xx == (2.0, 5.0, 8.0)

	G = GMT.peaks()
	gdalshade(G, C=makecpt(T=(-7,8,1)), zfactor=2);
	GMT.gammacorrection(mat2img(rand(UInt8, 3,4)), 1.1)
	ds = gmt2gd(G)
	G  = gd2gmt(ds)
	G = gd2gmt("utmsmall.tif");
	GMT.regiongeog(G)
	ds = gmt2gd(G)
	gdalinfo(ds);
	D = mat2ds([0 0; 10 0; 10 10; 11 10], geom=4);
	Dv = gd2gmt(gmt2gd(D));
	@test D == Dv

	GMT.get_FillValue("_FillValue=9999")
	GMT.helper_gmt2gd_xyz(GMT.GMTdataset(rand(Float32,3,3), Float64[], Float64[], GMT.DictSvS(), String[], String[], "", String[], "", "", 0, 0),3)
	@test GMT.gd2gmt_helper_scalefac([1  1; 1 1], 2, 0, false, 0) == [2 2; 2 2]
	@test GMT.gd2gmt_helper_scalefac([1. 1; 1 1], 2, 0, false, 0) == [2. 2.; 2. 2.]

	# Test that we recover the original.
	G = mat2grid(reshape(collect(1.0:12), 3, 4));
	Gv = gd2gmt(gmt2gd(G), layout="BCB");
	@test G == Gv

	I = grdcut("utmsmall.tif", R="442000/445000/3747000/3750000", img=1);
	grdcut("utmsmall.tif", R="442000/445000/3747000/3750000", img=1, save="lixo.tif");
	grdcut("utmsmall.tif", R="442000/445000/3747000/3750000", img=1, save="lixo.tif");

	GMT.Gdal.getmetadata("rgbsmall.tif");
	I = Gdal.dither("rgbsmall.tif");
	gmt2gd(I);
	Gdal.dither("rgbsmall.tif", save="lixo.tif");
	Gdal.dither("rgbsmall.tif", save="lixo.tof");			# .tof to trigger the warning
	Gdal.gdal_opts2vec("aa bb 'vv pp' aa \"ad uuu\"");

	Gdal.GDALGetDataTypeByName("GTiff");
	Gdal.IFieldDefnView(C_NULL);
	Gdal.IGeomFieldDefnView(C_NULL);
	Gdal.GeomFieldDefn(C_NULL);
	@info "3..."
	Gdal.RasterBand(C_NULL);
	Gdal.destroy(Gdal.Driver(C_NULL));
	Gdal.destroy(Gdal.Feature(C_NULL));
	Gdal.destroy(Gdal.CoordTransform(C_NULL));
	Gdal.destroy(Gdal.FeatureDefn(C_NULL));
	Gdal.destroy(Gdal.IFieldDefnView(C_NULL));
	Gdal.destroy(Gdal.IGeomFieldDefnView(C_NULL));

	ds = gmt2gd(mat2ds([-8. 37.0; -8.1 37.5; -8.5 38.0]))
	Gdal.getx(Gdal.getgeom(Gdal.unsafe_getfeature(Gdal.getlayer(ds, 0),0)),1)
	Gdal.gety(Gdal.getgeom(Gdal.unsafe_getfeature(Gdal.getlayer(ds, 0),0)),1)
	Gdal.getz(Gdal.getgeom(Gdal.unsafe_getfeature(Gdal.getlayer(ds, 0),0)),1)
	Gdal.buffer(Gdal.getgeom(Gdal.unsafe_getfeature(Gdal.getlayer(ds, 0),0)), 0.2)
	Gdal.GDALGetSpatialRef(ds.ptr)
	Gdal.GDALDatasetGetLayerByName(ds.ptr, "0")
	Gdal.GDALGetPaletteInterpretation(ds.ptr)
	GMT.Gdal.getmetadata(ds)

	#Gdal.identifydriver("lixo.gmt")
	D = mat2ds([-8. 37.0; -8.1 37.5; -8.5 38.0; -8. 37.0], proj="+proj=longlat");
	ds = gmt2gd(D)
	@info "4..."
	ds = gmt2gd(D, geometry="Polygon")
	gmt2gd(mat2ds([0 10; 1 11; 0 10], x=[0, 1, 2], multi=true), geometry="line")
	gmt2gd(mat2ds([0 10; 1 11; 0 10; 0 10], x=[0, 1, 2, 0], multi=true), geometry="polyg")
	ogr2ogr(D, dest="lixo1.gmt")
	gmt2gd(D, save="lixo2.gmt")
	ds = gmt2gd(D)
	ds2=ogr2ogr(ds, ["-t_srs", "+proj=utm +zone=29", "-overwrite"])
	gd2gmt(ds2)
	ogr2ogr(D, "-t_srs '+proj=utm +zone=29' -overwrite")	# Returns a GMT datset directly
	#ogr2ogr(D[1], "-t_srs '+proj=utm +zone=29' -overwrite")

	D1 = mat2ds([0.0 0.0; 1.0 1.0; 1.0 0.0; 0.0 0.0], geom=wkbPoint);
	gmt2gd(D1); gmt2gd(D1, geometry="line"); gmt2gd(D1, geometry="point")
	D2 = mat2ds([0.0 0.0 1.; 1.0 1.0 2.; 1.0 0.0 3.; 0.0 0.0 1.], geom=wkbPoint);

	gmt2gd(D2);		gmt2gd(D2, geometry="line");	gmt2gd(D2, geometry="point")

	wkt = "POLYGON ((1179091. 712782.,1161053. 667456.,1214705. 641092.,1228580. 682719.,1218405. 721108.,1179091. 712782.))";
	@test Gdal.getgeomtype(Gdal.forceto(Gdal.fromWKT(wkt), Gdal.wkbMultiPolygon)) == Gdal.wkbMultiPolygon
	wkt = "POINT (1198054.34 648493.09)";
	bf = Gdal.buffer(Gdal.fromWKT(wkt), 500);
	@test Gdal.getgeomtype(bf) == Gdal.wkbPolygon
	show(bf); println()

	@testset "Calculate the Area of a Geometry" begin
		wkt = "POLYGON ((1162440. 672081., 1162440. 647105., 1195279. 647105., 1195279. 672081., 1162440. 672081.))"
		poly = Gdal.fromWKT(wkt)
		@test Gdal.geomarea(poly) ≈ 8.20186864e8
	end

	@testset "Calculate the Length of a Geometry" begin
		wkt = "LINESTRING (1181866.263593049 615654.4222507705, 1205917.1207499576 623979.7189589312, 1227192.8790041457 643405.4112779726, 1224880.2965852122 665143.6860159477)"
		line = Gdal.fromWKT(wkt)
		@test Gdal.geomlength(line) ≈ 76121.94397805972
	end

	mp = Gdal.createmultipolygon_noholes(Vector{Tuple{Float64,Float64}}[
		[(1204067., 634617.), (1204067., 620742.), (1215167., 620742.), (1215167., 634617.), (1204067., 634617.)],
		[(1179553., 647105.), (1179553., 626292.), (1194354., 626292.), (1194354., 647105.), (1179553., 647105.)] ])
	Gdal.wrapgeom(mp)

	gdalinfo("poly_spatialite.sqlite");
	Gdal.read("poly_spatialite.sqlite");
	@info "3..."
	Gdal.inspect("SELECT HEX(GeomFromText('POINT(10 20)'))", "poly_spatialite.sqlite");

	I1 = mat2img(reshape(collect(UInt8(1):UInt8(20)), 4, 5))	#  layout = TCBa
	I2 = mat2img(reshape(collect(UInt8(11):UInt8(30)), 4, 5))
	GMT.blendimg!(I1, I2)
	I2.layout = "BCBa"
	GMT.blendimg!(I1, I2)
	I2.layout = "BRBa"
	GMT.blendimg!(I1, I2)
	I2.layout = "TRBa"
	GMT.blendimg!(I1, I2)
	I1 = mat2img(reshape(collect(UInt8(1):UInt8(60)), 4, 5, 3))
	I1.layout = "TRPa"
	I2.image[end] = UInt8(200)		# to make tests visit another if branch
	GMT.blendimg!(I1, I2)

	G = GMT.peaks()
	G[10:15, 15:20] .= NaN;
	fillnodata!(G);
	@test GMT.isgeog(4326) == true

	gmtwrite("9px.tif", mat2img(round.(UInt8,round.(rand(6,6))*255)))
	polygonize("9px.tif", nmin=2, sort=true);

	gdaldrivers(:vec, out=true);
end