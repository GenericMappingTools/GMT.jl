	println("	GRDINFO")
	G=gmt("grdmath", "-R0/10/0/10 -I1 5");
	r=gmt("grdinfo -C", G);
	@assert(r.data[1:1,1:10] == [0.0  10.0  0.0  10.0  5.0  5.0  1.0  1.0  11.0  11.0])
	r2=grdinfo(G, C=true, V=:q);
	@assert(r.data == r2.data)
	grdinfo(mat2grid(rand(4,4)));				# Test the doubles branch in grid_init
	grdinfo(mat2grid(rand(Float32,4,4)));		# Test the float branch in grid_init
	nx = 3; ny = 2; rang = [1, nx, 1, ny, 0.0,1]; x = collect(1.0:nx); y = collect(1.0:ny); inc = [1.0, 1];
	zz = rand(1:nx,ny,nx); z = zeros(Float32, ny+4, nx+4); z[3:end-2, 3:end-2] = zz;
	G = GMT.GMTgrid("","",0,rang, inc,0,NaN,"","","","",String[],x,y,[0.],deepcopy(collect(z')),"","","","","TRB",1f0, 0f0, 2, 0)
	grdinfo(G);

	println("	GRD2CPT")
	G=gmt("grdmath", "-R0/10/0/10 -I2 X");
	C=grd2cpt(G);
	grd2cpt(G, cmap="lixo.cpt")

	# GRD2XYZ (It's tested near the end)
	#D=grd2xyz(G); # Use G of previous test
	gmtwrite("lixo.grd", G)
	D1=grd2xyz(G);
	D2=grd2xyz("lixo.grd");
	@assert(sum(D1.data) == sum(D2.data))

	println("	GRD2KML")
	G=gmt("grdmath", "-R0/10/0/10 -I1 X -fg");
	grd2kml(G, I="+", N="NUL", V="q", Vd=dbg2)

	println("	GRDBLEND")
	G3=gmt("grdmath", "-R5/15/0/10 -I1 X Y -Vq");
	grdblend(G,G3);

	println("	GRDCLIP")
	grdclip(G,above="5/6", low=[2 2], between=[3 4.5 4]);	 # Use G of previous test
	@test_throws ErrorException("Wrong number of elements in S option") grdclip(G,above="5/6", low=[2], between=[3 4 4.5]);
	@test_throws ErrorException("OPT_S: argument must be a string or a two elements array.") grdclip(G,above=5, low=[2 2]);

	println("	GRDCONTOUR")
	G = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
	C = grdcontour(G, C="+0.7", D=[]);
	@assert((size(C.data,1) == 21) && abs(-0.6 - C.data[1,1]) < 1e-8)
	# Do the same but write the file on disk first
	gmt("write lixo.grd", G)
	GG = gmt("read -Tg lixo.grd");
	C = grdcontour("lixo.grd", C="+0.7", D=[]);
	@assert((size(C.data,1) == 21) && abs(-0.6 - C.data[1,1]) < 1e-8)
	r = grdcontour("lixo.grd", cont=10, A=(int=50,labels=(font=7,)), G=(dist="4i",), L=(-1000,-1), W=((contour=1,pen="thinnest,-"), (annot=1, pen="thin,-")), T=(gap=("0.1i","0.02i"),), Vd=dbg2);
	@test startswith(r, "grdcontour lixo.grd  -JX" * split(GMT.def_fig_size, '/')[1] * "/0" * " -Baf -BWSen -L-1000/-1 -A50+f7 -Gd4i -T+d0.1i/0.02i -Wcthinnest,- -Wathin,- -R-15/15/-15/15 -C10")
	r = grdcontour("lixo.grd", A="50+f7p", G="d4i", W=((contour=1,pen="thinnest,-"), (annot=1, pen="thin,-")), Vd=dbg2);
	@test startswith(r, "grdcontour lixo.grd  -JX" * split(GMT.def_fig_size, '/')[1] * "/0" * " -Baf -BWSen -A50+f7p -Gd4i -Wcthinnest,- -Wathin,-")
	G = GMT.peaks()
	cpt = makecpt(T="-6/8/1");
	grdcontour(G, axis="a", fmt="png", color=cpt, pen="+c", X=1, Y=1, N=true, U=[])
	grdcontour!(G, axis="a", color=cpt, pen="+c", X=1, Y=1, N=true, Vd=dbg2)
	grdcontour!("", G, axis="a", color=cpt, pen="+c", X=1, Y=1, N=cpt, Vd=dbg2)

	println("	GRDCUT")
	G=gmt("grdmath", "-R0/10/0/10 -I1 X Y MUL");
	grdcut(G, limits=[3 9 2 8]);
	grdcut("lixo.grd", limits=[3 9 2 8], V=:q);	# lixo.grd was written above in the gmtwrite test
	grdcut(data="lixo.grd", limits=[3 9 2 8], V=:q);
	grdcut(data=G, limits=[3 9 2 8]);

	println("	CROP")
	im = mat2img(UInt8.(GMT.magic(9)))
	D = mat2ds([1.6 2.6; 1.6 4.4; 4.4 4.4; 4.4 2.6; 1.6 2.6])
	crop(im, region=D)[1].image == UInt8.([27 29 40; 28 39 50])
	colorzones!(D, img=im)		# A bit out of place but it reuses the variables above
	G = GMT.peaks();
	D = mat2ds([-1 -1; 1 1; 1 -1; -1 -1]);
	GMT.rasterzones!(G, D, mean)
	I = GMT.mat2img(rand(UInt8, 32, 32, 3));
	D = mat2ds([10 10; 15 20; 20 10; 10 10]);
	GMT.rasterzones!(I, D, mean)

	# GRDEDIT
	grdedit(G, C=true);

	println("	GRDFFT")
	grdfft(G, upward=800); 	# Use G of previous test
	grdfft(G, G, E=[]);

	println("	GRDFIL")
	grdmask([3 3], R="0/6/0/6", I=1, N="10/NaN/NaN", S=0);
	grdfill(G, algo=:n);

	println("	GRDFILTER")
	grdfilter(G, filter="m60", distflag=0, inc=0.5); # Use G of previous test

	println("	GRDGRADIENT")
	grdgradient(G, azim="0/270", normalize="e0.6");
	grdgradient(G, azim="0/270", normalize="e0.6", Q=:save, Vd=dbg2);

	println("	GRDHISTEQ")
	grdhisteq(G, gaussian=[]);	# Use G of previous test

	if (GMTver > v"6.1.1")
		println("	GRDINTERPOLATE")
		G = grdinterpolate("cube.nc", T=4)
		C = grdinterpolate("cube.nc", T="3/4/0.25");
		grdinfo(C)
	end

	println("	GRDLANDMASK")
	grdlandmask(R="-10/4/37/45", res=:c, inc=0.1);

	println("	GRDMASK")
	grdmask([10 20; 40 40; 70 20; 10 20], R="0/100/0/100", out_edge_in=[100 0 0], I=2);
	@test_throws ErrorException("Failed to automatically load the input file. You must do it manually and pass it as numeric.") grdmask("aiai");

	println("	GRDPASTE")
	G3 = grdmath("-R10/20/0/10 -I1 X");
	grdpaste(G,G3);

	println("	GRDPROJECT")
	# GRDPROJECT	-- Works but does not save projection info in header
	grdproject(G, proj="u29/1:1", F=[], C=[]); 		# Use G of previous test

	println("	GRDROTATER")
	grdrotater(G, rotation="-40.8/32.8/-12.9", Vd=dbg2);

	println("	GRDSAMPLE")
	grdsample(G, inc=0.5);		# Use G of previous test

	println("	GRDTREND")
	G  = gmt("grdmath", "-R0/10/0/10 -I1 X Y MUL");
	grdtrend(G, model=3);
	mat2grid(ones(Float32, size(G.z,1), size(G.z,2)));
	W = mat2grid(rand(16,16), x=11:26, y=1:16);
	mat2grid([3 4 5; 1 2 5; 5 5 5], reg=:pixel, x=[1 3], y=[1 3]);
	grdtrend(G, model=3, diff=[], trend=true);
	#grdtrend(G, model="3+r", W=W);
	grdtrend(G, model="3+r", W=(W,0), Vd=dbg2);

	println("	GRDTRACK")
	#G = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
	G = gmt("grdmath -R-2/2/-2/2 -I1 1");
	gmtwrite("lixo.grd", G)
	D = grdtrack([0 0], G);
	@assert(D.data == [0.0 0 1])
	D = grdtrack([0 0], G="lixo.grd");
	@assert(D.data == [0.0 0 1])
	grdtrack("lixo.grd", [0 0]);
	grdtrack(G, [0 0]);
	grdtrack([0 0], G=G);
	D = grdtrack([0 0], G=(G,G));
	@assert(D.data == [0.0 0 1 1])

	println("	GRDVECTOR")
	G = gmt("grdmath -R-2/2/-2/2 -I0.1 X Y R2 NEG EXP X MUL");
	dzdy = gmt("grdmath ? DDY", G);
	dzdx = gmt("grdmath ? DDX", G);
	grdvector(dzdx, dzdy, I=0.2, vector=(len=0.25, stop=1, norm=0.65, shape=0.5), G=:black, W="1p", S=12, V="q")
	grdvector!(dzdx, dzdy, I=0.2, vector=(len=0.25, stop=1, norm=0.65, shape=0.5), W="1p", S=12, Vd=dbg2)
	r = grdvector!("",dzdx, dzdy, I=0.2, vector=(len=0.25, stop=1, norm=0.65), W="1p", S=12, Vd=dbg2);
	@test startswith(r, "grdvector  -R -J -I0.2 -S12 -W1p -Q0.25+e+n0.65")
	r = grdvector!("", 1, 2, I=0.2, vec="0.25+e+n0.66", W=1, S=12, Vd=dbg2);
	@test startswith(r, "grdvector  -R -J -I0.2 -S12 -W1 -Q0.25+e+n0.66")

	println("	GRDVOLUME")
	grdvolume(G);