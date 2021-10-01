@testset "MISC" begin

	@test_throws ErrorException("Must select one convention (S options. Run gmthelp(velo) to learn about them)") velo!("",mat2ds([0. -8 0 0 4 6 0.5; -8 5 3 3 0 0 0.5], ["4x6", "3x3"]), region=(-15,10,-10,10))

	println("	MISC")
	G = nearneighbor(rand(100,3) * 150, R="0/150/0/150", I=1, N=4, S=10, r=true);
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
	G2 = GMT.mat2grid(rand(Float32,4,4), G1);
	GMT.mat2img(rand(UInt8,8,8), G1);
	G2 = mat2grid(rand(Float32,4,4), mat2img(rand(UInt16,32,32),x=[220800 453600], y=[3.5535e6 3.7902e6]));
	G2 = GMT.mat2grid(rand(Int32,4,4));
	G2 = GMT.mat2grid(rand(4,4));
	G1 .* G2;
	getindex(G1,1:2);
	setindex!(G1, [-1 -1],1:2)
	size(G1)

	GMT.WrapperPluto("aaa")
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
	isempty(GMT.GMTcpt())
	size(GMT.GMTcpt())
	isempty(GMT.GMTps())
	GMT.GMTdataset(rand(2,2), "lixo");
	GMT.GMTdataset(rand(Float32, 2,2), ["aiai"])
	GMT.GMTdataset(rand(Float32, 2,2), "aiai")
	GMT.GMTdataset(rand(Float32, 2,2))
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
	API = GMT.GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL + GMT.GMT_SESSION_COLMAJOR);
	gmtread("lixo.gmt");		# This "lixo.gmt" was created in test_avatars.jl
	if (GMTver > v"6.1.1")
		GMT.gmt_ogrread(API, "lixo.gmt", C_NULL);		# Keep testing the old gmt_ogrread API.
	end
	GMT.GMT_Get_Default(API, "API_VERSION", "        ");
	D = gmtconvert([1.0 2 3; 2 3 4], a="2=lolo+gPOINT");	# There's a bug in GMT for this. No data points are printed
	gmtwrite("lixo.gmt", D)
	@test gmtconvert([1.0 2 3; 2 3 4], binary_out="3f", write="a.bin", Vd=2) == "gmtconvert  > a.bin -bo3f"
	@test gmtconvert([1.0 2 3; 2 3 4], binary_out="3f", append="a.bin", Vd=2) == "gmtconvert  >> a.bin -bo3f"
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
		image_cpt!(I, C)
		GMT.transpcmap!(I, true)
		GMT.transpcmap!(I, false)
		image_cpt!(I, clear=true)
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
	show(mat2ds(rand(2,13), multi=true));
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
end
