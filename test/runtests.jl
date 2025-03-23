using GMT, GMT.Drawing, GMT.Gdal
using Test
using Dates, Printf#, Logging
using FFTW

@testset "GMT" begin

	#Logging.disable_logging(Logging.Warn)

	global dbg2 = 2			# Either 2 or 3. 3 to test the used kwargs
	global dbg0 = 0			# With 0 prints only the non-consumed options. Set to -1 to ignore this Vd

	GMT.GMT_Get_Version();
	ma=[0];mi=[0];pa=[0];
	GMT.GMT_Get_Version(ma,mi,pa);
	API = GMT.GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL);
	GMT.GMT_Get_Ctrl(API);

	println("		Entering: test_gd_ext.jl")
	include("test_gd_ext.jl")
	println("		Entering: test_gdal.jl")
	include("test_gdal.jl")			# Fcks the automatic registering because building docs fails
	rm("point.csv")
	#rm("lixo1.gmt")
	rm("lixo2.gmt")

	println("		Entering: test_proj4.jl")
	include("test_proj4.jl")

	include("test_lowess.jl")
	include("test_whittaker.jl")
	include("test_signalcorr.jl")
	println("	MAGREF")
	include("test_mgd77.jl")
	println("	CUBES")
	include("test_cube.jl")

	println("	WMS")
	try
		wms = GMT.wmsinfo("http://tiles.maps.eox.at/wms?")
		show(wms)
		show(wms.layer[1])
		GMT.wmsinfo(wms, layer="coastline", stronly=true);
		GMT.wmstest(wms, layer=33, region=(-8,39, 100000), res=100);
		GMT.wmstest(wms, layer=33, region=(iso="PT"), res=100);
		GMT.wmstest(wms, layer=37, region=(-8,-7,38,39), res="0.001d")
		GMT.wmstest(wms, layer=37, region=(-8,-7,38,39), res=100)
		GMT.wmstest(wms, layer=37, region="7829,6374,14", zoom=3, size=true) == (1635, 2048)
	catch err
		@warn("Failed the WMS test. Error was:\n $err")
	end

	include("test_findpeaks.jl")
	include("test_hampel.jl")
	include("test_maregrams.jl")
	include("test_lepto_funs.jl")
	include("test_beziers.jl")
	include("test_cody.jl")
	include("test_imgfuns.jl")
	include("test_imgtiles.jl")
	include("test_makecpts.jl")
	println("		Entering: test_avatars.jl")
	include("test_avatars.jl")
	println("		Entering: test_misc.jl")
	include("test_misc.jl")
	println("		Entering: test_utils.jl")
	include("test_utils.jl")
	println("		Entering: test_tables.jl")
	include("test_tables.jl")
	println("		Entering: test_common_opts.jl")
	include("test_common_opts.jl")
	println("		Entering: test_B-GMTs.jl")
	include("test_B-GMTs.jl")
	include("test_new_projs.jl")
	println("		Entering: test_GRDs.jl")
	include("test_GRDs.jl")
	println("		Entering: test_views.jl")
	include("test_views.jl")
	println("		Entering: test_PSs.jl")
	include("test_PSs.jl")
	include("test_modern.jl")
	println("		Entering: test_P_a_T.jl")
	include("test_P_a_T.jl")
	println("		Entering: test_solidos.jl")
	include("test_solidos.jl")
	include("test_statplots.jl")
	include("test_texture.jl")
	include("test_pca.jl")
	println("		Entering: test_las.jl")
	include("test_las.jl")

	println("	GREENSPLINE")
	d = [0 6.44; 1820 8.61; 2542 5.24; 2889 5.73; 3460 3.81; 4586 4.05; 6020 2.95; 6841 2.57; 7232 3.37; 10903 3.84; 11098 2.86; 11922 1.22; 12530 1.09; 14065 2.36; 14937 2.24; 16244 2.05; 17632 2.23; 19002 0.42; 20860 0.87; 22471 1.26];
	greenspline(d, R="-2000/25000", I=100, S=:l, D=0, Vd=dbg2)

	println("	MAPPROJECT")
	mapproject([-10 40], J=:u29, C=true, F=true, V=:q);
	mapproject(region=(-15,35,30,48), proj=:merc, figsize=5, map_size=true);
	@test mapproject([1.0 1; 2 2], L=(line=[1.0 0; 4 3], unit=:c), Vd=dbg2) ==  "mapproject  -L+uc"
	@test mapproject([1.0 1; 2 2], L=[1.0 0; 4 3], Vd=dbg2) == "mapproject  -L"
	@test mapproject([1.0 1; 2 2], L="lixo.dat", Vd=dbg2) == "mapproject  -Llixo.dat"
	@test_throws ErrorException("Bad argument type (Tuple{}) to option L") mapproject([1.0 1; 2 2], L=(), Vd=dbg2)
	@test_throws ErrorException("line member cannot be missing") mapproject(mapproject([1.0 1; 2 2], L=(lina=[1.0 0; 4 3], unit=:c), Vd=dbg2))

	println("	PSMECA")
	meca([0.0 3.0 0.0 0 45 90 5 0 0], fill=:black, region=(-1,4,0,6), proj=:Merc, Vd=dbg2)
	meca!([0.0 3.0 0.0 0 45 90 5 0 0], fill=:black, region=(-1,4,0,6), proj=:Merc, Vd=dbg2)
	@test_throws ErrorException("Must select one convention") meca!([0.0 3 0 0 45 90 5 0 0 0], fill=:black, region=(-1,4,0,6), proj=:Merc)
	@test_throws ErrorException("Specifying cross-section type is mandatory") coupe([0.0 3 0 0 45 90 5 0 0], region=(-1,4,0,6))
	velo(mat2ds([0. -8 0 0 4 6 0.5; -8 5 3 3 0 0 0.5], ["4x6", "3x3"]), pen=(0.6,:red), fill_wedges=:green, outlines=true, Se="0.2/0.39/18", arrow="0.3c+p1p+e+gred", region=(-15,10,-10,10), Vd=dbg2)

	#G = gmt("grdmath -R-15/15/-15/15 -I1 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
	#D = grd2xyz(G);
	#gmtwrite("lixo.gmt", D);

	println("	GADM")
	try			# Use a try/catch because the GADM service screwes one-every-other time
	gadm("AND", names=true);
	gadm("AND", "ordino");
	#gadm("AND", children=true);
	#gadm("AND", children_raw=true);
	@test_throws ErrorException("Asked data for a level (3) that is lower than lowest data level (2)") gadm("AND", "ordino", names=true);
	catch
	end

	include("test_parker.jl")

	# Remove garbage
	println("	REMOVE GARBAGE")
	function desgarbage(fname)
		try
			rm(fname)
		catch
			println("Failed to remove " * fname)
		end
	end
	desgarbage("lixo1.gmt")
	desgarbage("gmt.history")
	desgarbage("lixo.ps")
	desgarbage("lixo.png")
	desgarbage("lixo1.png")
	desgarbage("lixo2.png")
	desgarbage("lixo3.png")
	desgarbage("png.png")
	desgarbage("lixo.grd")
	desgarbage("lixo.cpt")
	desgarbage("lixo.dat")
	desgarbage("logo.png")
	desgarbage("lixo.eps")
	desgarbage("lixo.jpg")
	desgarbage("lixo.pdf")
	desgarbage("9px.tif")
	desgarbage("lixo_cube.nc")

end