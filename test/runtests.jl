using GMT, GMT.Drawing, GMT.Gdal
using Test
using Dates

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
	ma=[0];mi=[0];pa=[0];
	GMT.GMT_Get_Version(ma,mi,pa);
	API = GMT.GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL);
	GMT.GMT_Get_Ctrl(API);

	include("test_gdal.jl")
	include("test_common_opts.jl")
	include("test_B-GMTs.jl")
	include("test_avatars.jl")
	include("test_GRDs.jl")
	include("test_views.jl")
	include("test_PSs.jl")
	include("test_modern.jl")

	println("	GREENSPLINE")
	d = [0 6.44; 1820 8.61; 2542 5.24; 2889 5.73; 3460 3.81; 4586 4.05; 6020 2.95; 6841 2.57; 7232 3.37; 10903 3.84; 11098 2.86; 11922 1.22; 12530 1.09; 14065 2.36; 14937 2.24; 16244 2.05; 17632 2.23; 19002 0.42; 20860 0.87; 22471 1.26];
	greenspline(d, R="-2000/25000", I=100, S=:l, D=0, Vd=dbg2)

	println("	MAKECPT")
	cpt = makecpt(range="-1/1/0.1");
	makecpt(rand(10,1), E="", C=:rainbow, cptname="lixo.cpt");
	@test_throws ErrorException("E option requires that a data table is provided as well") makecpt(E="", C=:rainbow)
	C = cpt4dcw("eu");
	C = cpt4dcw("PT,ES,FR", [3., 5, 8], range=[1,4,1]);
	C = cpt4dcw("PT,ES,FR", [.3, .5, .8], cmap=cpt);
	GMT.iso3to2_eu();
	GMT.iso3to2_af();
	GMT.iso3to2_na();
	GMT.iso3to2_world();
	GMT.mk_codes_values(["PRT", "ESP", "FRA"], [1.0, 2, 3], region="eu");

	println("	MAPPROJECT")
	mapproject([-10 40], J=:u29, C=true, F=true, V=:q);
	mapproject(region=(-15,35,30,48), proj=:merc, figsize=5, map_size=true);
	@test mapproject([1.0 1; 2 2], L=(line=[1.0 0; 4 3], unit=:c), Vd=dbg2) ==  "mapproject  -L+uc "
	@test mapproject([1.0 1; 2 2], L=[1.0 0; 4 3], Vd=dbg2) == "mapproject  -L "
	@test mapproject([1.0 1; 2 2], L="lixo.dat", Vd=dbg2) == "mapproject  -Llixo.dat "
	@test_throws ErrorException("Bad argument type (Tuple{}) to option L") mapproject([1.0 1; 2 2], L=(), Vd=dbg2)
	@test_throws ErrorException("line member cannot be missing") mapproject(mapproject([1.0 1; 2 2], L=(lina=[1.0 0; 4 3], unit=:c), Vd=dbg2))

	# Test ogrread. STUPID OLD Linux for travis is still on GDAL 1.11
	API = GMT.GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL + GMT.GMT_SESSION_COLMAJOR);
	gmtread("lixo.gmt");
	GMT.gmt_ogrread(API, "lixo.gmt", C_NULL);		# Keep testing the old gmt_ogrread API.
	GMT.GMT_Get_Default(API, "API_VERSION", "        ");

	println("	PROJECT")
	project(C="15/15", T="85/40", G="1/110", L="-20/60");	# Fails in GMT5
	project(nothing, C="15/15", T="85/40", G="1/110", L="-20/60");	# bit of cheating

	println("	SAMPLE1D")
	d = [-5 74; 38 68; 42 73; 43 76; 44 73];
	sample1d(d, T="2c", A=:r);	

	println("	SPECTRUM1D")
	D = gmt("gmtmath -T0/10239/1 T 10240 DIV 360 MUL 400 MUL COSD");
	spectrum1d(D, S=256, W=true, par=(GMT_FFT=:brenner,), N=true, i=1);

	println("	SPHTRIANGULATE")
	D = sphtriangulate(rand(10,3), V=:q);		# One dataset per triangle????

	println("	SPHINTERPOLATE")
	sphinterpolate(rand(10,3), I=0.1, R="0/1/0/1");

	println("	SPHDISTANCE")
	# SPHDISTANCE  (would fail with: Could not obtain node-information from the segment headers)
	G = sphdistance(R="0/10/0/10", I=0.1, Q=D, L=:k, Vd=dbg2);	# But works with data from sph_3.sh test
	@test sphdistance(nothing, R="0/10/0/10", I=0.1, Q="D", L=:k, Vd=dbg2) == "sphdistance  -I0.1 -R0/10/0/10 -Lk -QD"

	println("	SURFACE")
	G = surface(rand(100,3) * 150, R="0/150/0/150", I=1, Ll=-100, upper=100, V=:q);
	@assert(size(G.z) == (151, 151))


	# SPLITXYZ (fails)
	splitxyz([-14.0708 35.0730 0; -13.7546 35.5223 0; -13.7546 35.5223 0; -13.2886 35.7720 0; -13.2886 35.7720 0; -12.9391 36.3711 0], C=45, A="45/15", f="g", Vd=dbg2)

	println("	TRIANGULATE")
	G = triangulate(rand(100,3) * 150, R="0/150/0/150", I=1, grid=[]);
	triangulate(rand(5,3), R="0/150/0/150", voronoi=:pol, Vd=dbg2);

	println("	NEARNEIGHBOR")
	G = nearneighbor(rand(100,3) * 150, R="0/150/0/150", I=1, N=4, S=10, r=true);

	println("	XYZ2GRD")
	D=grd2xyz(G); # Use G of previous test
	xyz2grd(D, R="0/150/0/150", I=1, r=true);
	xyz2grd(D, xlim=(0,150), ylim=(0,150), I=1, r=true);

	println("	TREND1D")
	D = gmt("gmtmath -T10/110/1 T 50 DIV 2 POW 2 MUL T 60 DIV ADD 4 ADD 0 0.25 NRAND ADD T 25 DIV 2 MUL PI MUL COS 2 MUL 2 ADD ADD");
	trend1d(D, N="p2,F1+o0+l25", F=:xm);

	println("	TREND2D")
	trend2d(D, F=:xyr, N=3);

	println("	PSMECA")
	meca([0.0 3.0 0.0 0 45 90 5 0 0], fill=:black, region=(-1,4,0,6), proj=:Merc, Vd=dbg2)
	meca!([0.0 3.0 0.0 0 45 90 5 0 0], fill=:black, region=(-1,4,0,6), proj=:Merc, Vd=dbg2)
	@test_throws ErrorException("Must select one convention") meca!("", [0.0 3 0 0 45 90 5 0 0 0], fill=:black, region=(-1,4,0,6), proj=:Merc)
	@test_throws ErrorException("Specifying cross-section type is mandatory") coupe([0.0 3 0 0 45 90 5 0 0], region=(-1,4,0,6))
	velo(mat2ds([0. -8 0 0 4 6 0.5; -8 5 3 3 0 0 0.5], ["4x6", "3x3"]), pen=(0.6,:red), fill_wedges=:green, outlines=true, Se="0.2/0.39/18", arrow="0.3c+p1p+e+gred", region=(-15,10,-10,10), Vd=dbg2)

	@test_throws ErrorException("Must select one convention (S options. Run gmthelp(velo) to learn about them)") velo!("",mat2ds([0. -8 0 0 4 6 0.5; -8 5 3 3 0 0 0.5], ["4x6", "3x3"]), region=(-15,10,-10,10))

	println("	MISC")
	G = GMT.mat2grid(G.z; reg=0, hdr=[G.range; G.registration; G.inc]);
	G1 = gmt("grdmath -R-2/2/-2/2 -I0.5 X Y MUL");
	G2 = G1;
	G3 = G1 + G2;
	G3 = G1 + 1;
	G3 = 1 + G1;
	G3 = G1 - G2;
	G3 = G1 - 1;
	G3 = G1 * G2;
	G3 = G1 * 2;
	G3 = 2 * G1;
	G3 = G1 ^ 2;
	G3 = -G1;
	G3 = G1 / G2;
	G3 = G1 / 2;
	G1 = mat2grid([0.0 1; 2 3]);
	G2 = mat2grid([4 5; 6 7; 8 9]);
	@test_throws ErrorException("The HDR array must have 9 elements") mat2grid(rand(4,4), reg=0, hdr=[0. 1 0 1 0 1]);
	@test_throws ErrorException("Grids have different sizes, so they cannot be added.") G1 + G2;
	@test_throws ErrorException("Grids have different sizes, so they cannot be subtracted.") G1 - G2;
	@test_throws ErrorException("Grids have different sizes, so they cannot be multiplied.") G1 * G2;
	@test_throws ErrorException("Grids have different sizes, so they cannot be divided.") G1 / G2;
	G1 = GMT.mat2grid(rand(4,4));
	G2 = GMT.mat2grid(rand(Float32,4,4));
	G2 = GMT.mat2grid(rand(Int32,4,4));
	G2 = GMT.mat2grid(rand(4,4));
	G1 .* G2;
	getindex(G1,1:2);
	setindex!(G1, [-1 -1],1:2)
	size(G1)

	Base.BroadcastStyle(typeof(G1))
	getindex(G1,1)

	GMT.find4similar(G1)
	GMT.find4similar(G1,0)
	GMT.find4similar(1)
	GMT.find4similar(())
	GMT.find4similar((0,1))
	GMT.find4similar([],0)
	I = mat2img(rand(UInt8,4,4,3))
	GMT.find4similar(I,0)
	size(I)
	Base.BroadcastStyle(typeof(I))
	getindex(I,1);
	setindex!(I, [101 1],1:2)
	I .+ UInt8(0)

	GMT.GMTdataset();
	GMT.GMTdataset(rand(2,2), "lixo");
	D = mat2ds(GMT.fakedata(4,4), x=:ny, color=:cycle, multi=true)
	D[1].text = ["lixo", "l", "p", "q"];
	GMT.find4similar(D[1],0)
	getindex(D[1],1);
	setindex!(D[1], 1,1)
	Base.BroadcastStyle(typeof(D[1]))
	display(D);
	plot(D, legend=true, Vd=dbg2)
	mat2ds(rand(5,4), x=:ny, color=:cycle, hdr=" -W1");
	mat2ds(rand(5,4), x=1:5, hdr=[" -W1" "a" "b" "c"], multi=true);
	@test_throws ErrorException("The header vector can only have length = 1 or same number of MAT Y columns") mat2ds(rand(2,3), hdr=["a" "b"]);

	GMT.mat2grid(rand(Float32, 10,10), reg=1);
	GMT.mat2grid(1, hdr=[0. 5 0 5 1 1])
	GMT.num2str(rand(2,3));
	text_record([-0.4 7.5; -0.4 3.0], ["a)", "b)"]);
	text_record(["aa", "bb"], "> 3 5 18p 5i j");
	text_record(["> 3 5 18p 5i j", "aa", "bb"]);
	text_record(Array[["aa", "bb"],["cc", "dd", "ee"]]);
	text_record([["aa", "bb"],["cc", "dd", "ee"]]);

	# TEST THE API DIRECTLY (basically to improve coverage under GMT6)
	PS = plot(rand(3,2), ps=1);
	API = GMT.GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL + GMT.GMT_SESSION_COLMAJOR);
	GMT.ps_init(API, PS, 0);
	gmt("destroy")

	# Test ogr2GMTdataset
	D = gmtconvert([1.0 2 3; 2 3 4], a="2=lolo+gPOINT");	# There's a bug in GMT for this. No data points are printed
	gmtwrite("lixo.gmt", D)
	@test gmtconvert([1.0 2 3; 2 3 4], binary_out="3f", write="a.bin", Vd=2) == "gmtconvert  > a.bin -bo3f"
	@test gmtconvert([1.0 2 3; 2 3 4], binary_out="3f", append="a.bin", Vd=2) == "gmtconvert  >> a.bin -bo3f"
	#API = GMT.GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL + GMT.GMT_SESSION_COLMAJOR);
	#GMT.ogr2GMTdataset(GMT.gmt_ogrread(API, "lixo.gmt"));
	rm("lixo.gmt")

	if (GMTver >= v"6.1")
		check = UInt8[zeros(9,9) ones(9,9) ones(9,9).*2; ones(9,9).*3 ones(9,9).*4 ones(9,9).*5; ones(9,9).*6 ones(9,9).*7 ones(9,9).*8];
		C = makecpt(range=(0,9,1));
		I = mat2img(check, cmap=C);
		rgb = GMT.ind2rgb(I);
		image_alpha!(I, alpha_ind=5);
		image_alpha!(I, alpha_vec=round.(UInt32,rand(6).*255));
		image_alpha!(I, alpha_band=round.(UInt8,rand(27,27).*255))
	end

	GMT.linspace(1,1,100);
	GMT.logspace(1,5);
	GMT.fakedata(50,1);
	GMT.meshgrid(1:5, 1:5, 1:5);
	fields(7);
	fields(rand(2,2))
	tic();toc()
	@test_throws ErrorException("`toc()` without `tic()`") toc()

	# MB-System
	println("	MB-System")
	mbgetdata("aa", Vd=2)
	mbimport("aa", Vd=2)
	mbsvplist("aa", Vd=2)
	mblevitus(Vd=2)

	println("	EXAMPLES")
	# EXAMPLES
	plot(1:10,rand(10), lw=1, lc="blue", marker="square", markeredgecolor=:white, size=0.2, markerfacecolor="red", title="Hello World", xlabel="Spoons", ylabel="Forks")

	x = range(0, stop=2pi, length=180);	seno = sin.(x/0.2)*45;
	coast(region="g", proj="A300/30/6c", axis="g", resolution="c", land="navy")
	plot!(collect(x)*60, seno, lw=0.5, lc="red", marker="circle", markeredgecolor=0, size=0.05, markerfacecolor="cyan")

	G = GMT.peaks();
	show(G);
	grdcontour(G, cont=1, annot=2, axis="a")
	cpt = makecpt(T="-6/8/1");      # Create the color map
	grdcontour(G, axis="a", color=cpt, pen="+c", fmt=:png, savefig="lixo")
	D = grdcontour(G, cont=[-2,0,5], dump=true);

	GMT.geodetic2enu(-81.998,42.002,1000,-82,42,200);

	println("	DRAWING")
	circle(0,0,1,first=true,Vd=dbg2)
	cross(0,0,1,Vd=dbg2)
	custom(0,0, "bla", 1,Vd=dbg2)
	diamond(0,0,1,Vd=dbg2)
	hexagon(0,0,1,Vd=dbg2)
	itriangle(0,0,1,Vd=dbg2)
	letter(0,0, 1, "A", "Helvetica", "CM",Vd=dbg2)
	minus(0,0,1,Vd=dbg2)
	pentagon(0,0,1,Vd=dbg2)
	plus(0,0,1,Vd=dbg2)
	square(0,0,1,Vd=dbg2)
	star(0,0,1,Vd=dbg2)
	triangle(0,0,1,Vd=dbg2)
	ydash(0,0,1,Vd=dbg2)
	box(0,0,1,1,Vd=dbg2)
	rect(0,0,1,1,Vd=dbg2)
	ellipseAz(0,0, 0, 1, 1,Vd=dbg2)
	rotrect(0,0, 0, 1, 1,Vd=dbg2)
	rotrectAz(0,0, 0, 1, 1,Vd=dbg2)
	roundrect(0,0, 1, 1, 1,Vd=dbg2)
	ellipse(300,201,0, 200, 50, first=true, units=:points, fill=:purple, pen=1)
	circle(305,185,56, fill=:black, figname="lixo.ps")

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
	#@static if (Sys.iswindows())  run(`rmdir /S /Q NUL`)  end

end					# End valid testing zone
