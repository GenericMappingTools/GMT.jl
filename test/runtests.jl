using GMT, GMT.Drawing, GMT.Gdal
using Test
using Dates, Printf

try
	run(`gmt --version`)	# Will fail if GMT is not installed.
	global got_it = true
catch
	@test 1 == 1			# Let tests pass for sake of not triggering a PkgEval failure
	global got_it = false
end

if (got_it)					# Otherwise go straight to end

	const dbg2 = 3			# Either 2 or 3. 3 to test the used kwargs
	const dbg0 = 0			# With 0 prints only the non-consumed options. Set to -1 to ignore this Vd

	GMT.GMT_Get_Version();
	GMT._precompile_()
	ma=[0];mi=[0];pa=[0];
	GMT.GMT_Get_Version(ma,mi,pa);
	API = GMT.GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL);
	GMT.GMT_Get_Ctrl(API);

	#println("		Entering: test_proj4.jl")
	#include("test_proj4.jl")
	println("		Entering: test_gd_ext.jl")
	include("test_gd_ext.jl")
	println("		Entering: test_gdal.jl")
	include("test_gdal.jl")			# Fcks the automatic registering because building docs fails
	println("		Entering: test_common_opts.jl")
	include("test_common_opts.jl")
	println("		Entering: test_B-GMTs.jl")
	include("test_B-GMTs.jl")
	println("		Entering: test_avatars.jl")
	include("test_avatars.jl")
	println("		Entering: test_GRDs.jl")
	include("test_GRDs.jl")
	println("		Entering: test_views.jl")
	include("test_views.jl")
	println("		Entering: test_PSs.jl")
	include("test_PSs.jl")
	println("		Entering: test_modern.jl")
	include("test_modern.jl")
	println("		Entering: test_P_a_T.jl")
	include("test_P_a_T.jl")
	println("		Entering: test_misc.jl")
	include("test_misc.jl")

	println("	GREENSPLINE")
	d = [0 6.44; 1820 8.61; 2542 5.24; 2889 5.73; 3460 3.81; 4586 4.05; 6020 2.95; 6841 2.57; 7232 3.37; 10903 3.84; 11098 2.86; 11922 1.22; 12530 1.09; 14065 2.36; 14937 2.24; 16244 2.05; 17632 2.23; 19002 0.42; 20860 0.87; 22471 1.26];
	greenspline(d, R="-2000/25000", I=100, S=:l, D=0, Vd=dbg2)

	println("	MAKECPT")
	cpt = makecpt(range="-1/1/0.1");
	makecpt(rand(10,1), E="", C=:rainbow, cptname="lixo.cpt");
	@test_throws ErrorException("E option requires that a data table is provided as well") makecpt(E="", C=:rainbow)
	C = cpt4dcw("eu");
	C = cpt4dcw("PT,ES,FR", [3., 5, 8], range=[3,9,1]);
	C = cpt4dcw("PT,ES,FR", [.3, .5, .8], cmap=cpt);
	@test_throws ErrorException("Unknown continent ue") cpt4dcw("ue")
	GMT.iso3to2_eu();
	GMT.iso3to2_af();
	GMT.iso3to2_na();
	GMT.iso3to2_world();
	GMT.mk_codes_values(["PRT", "ESP", "FRA"], [1.0, 2, 3], region="eu");
	@test_throws ErrorException("The region ue is invalid or has not been implemented yet.") GMT.mk_codes_values(["PRT"], [1.0], region="ue")

	println("	MAPPROJECT")
	mapproject([-10 40], J=:u29, C=true, F=true, V=:q);
	mapproject(region=(-15,35,30,48), proj=:merc, figsize=5, map_size=true);
	@test mapproject([1.0 1; 2 2], L=(line=[1.0 0; 4 3], unit=:c), Vd=dbg2) ==  "mapproject  -L+uc "
	@test mapproject([1.0 1; 2 2], L=[1.0 0; 4 3], Vd=dbg2) == "mapproject  -L "
	@test mapproject([1.0 1; 2 2], L="lixo.dat", Vd=dbg2) == "mapproject  -Llixo.dat "
	@test_throws ErrorException("Bad argument type (Tuple{}) to option L") mapproject([1.0 1; 2 2], L=(), Vd=dbg2)
	@test_throws ErrorException("line member cannot be missing") mapproject(mapproject([1.0 1; 2 2], L=(lina=[1.0 0; 4 3], unit=:c), Vd=dbg2))

	println("	PSMECA")
	meca([0.0 3.0 0.0 0 45 90 5 0 0], fill=:black, region=(-1,4,0,6), proj=:Merc, Vd=dbg2)
	meca!([0.0 3.0 0.0 0 45 90 5 0 0], fill=:black, region=(-1,4,0,6), proj=:Merc, Vd=dbg2)
	@test_throws ErrorException("Must select one convention") meca!("", [0.0 3 0 0 45 90 5 0 0 0], fill=:black, region=(-1,4,0,6), proj=:Merc)
	@test_throws ErrorException("Specifying cross-section type is mandatory") coupe([0.0 3 0 0 45 90 5 0 0], region=(-1,4,0,6))
	velo(mat2ds([0. -8 0 0 4 6 0.5; -8 5 3 3 0 0 0.5], ["4x6", "3x3"]), pen=(0.6,:red), fill_wedges=:green, outlines=true, Se="0.2/0.39/18", arrow="0.3c+p1p+e+gred", region=(-15,10,-10,10), Vd=dbg2)

	# Remove garbage
	println("	REMOVE GARBAGE")
	rm("gmt.history")
	rm("gmt.conf")
	rm("lixo.ps")
	rm("lixo.png")
	#rm("lixo.grd")
	rm("lixo.tif")
	rm("lixo.cpt")
	rm("lixo.dat")
	rm("logo.png")
	rm("lixo.eps")
	rm("lixo.jpg")
	rm("point.csv")
	rm("lixo1.gmt")
	rm("lixo2.gmt")
	#@static if (Sys.iswindows())  run(`rmdir /S /Q NUL`)  end

end					# End valid testing zone
