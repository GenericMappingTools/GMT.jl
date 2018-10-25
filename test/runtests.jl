using GMT
using Test
using LinearAlgebra

try
	run(`gmt --version`)	# Will fail if GMT is not installed.
	global got_it = true
catch
	@test 1 == 1			# Let tests pass for sake of not triggering a PkgEval failure
	global got_it = false
end

if (got_it)					# Otherwise go straight to end

	# write your own tests here
	r = gmt("gmtinfo -C", ones(Float32,9,3)*5);
	@assert(r[1].data == [5.0 5 5 5 5 5])
	r = gmtinfo(ones(Float32,9,3)*5, C=true, V=:q);
	@assert(r[1].data == [5.0 5 5 5 5 5])

	# BLOCK*s
	d = [0.1 1.5 1; 0.5 1.5 2; 0.9 1.5 3; 0.1 0.5 4; 0.5 0.5 5; 0.9 0.5 6; 1.1 1.5 7; 1.5 1.5 8; 1.9 1.5 9; 1.1 0.5 10; 1.5 0.5 11; 1.9 0.5 12];
	G = blockmedian(region=[0 2 0 2], inc=1, fields="z", reg=1, d);
	if (G !== nothing)	# If run from GMT5 it will return nothing
		G = blockmean(d, region=[0 2 0 2], inc=1, grid=true, reg=1, S=:n);	# Number of points in cell
		G,L = blockmode(region=[0 2 0 2], inc=1, fields="z,l", reg=1, d);
	end

	# FILTER1D
	raw = [collect((1.0:50)) rand(50)];
	filter1d(raw, F="m15");

	# GMTLOGO
	logo(D="x0/0+w2i")
	logo(julia=8)

	# GMTSPATIAL
	# Test  Cartesian centroid and area
	result = gmt("gmtspatial -Q", [0 0; 1 0; 1 1; 0 1; 0 0]);
	@assert(isapprox(result[1].data, [0.5 0.5 1]))
	# Test Geographic centroid and area
	result = gmt("gmtspatial -Q -fg", [0 0; 1 0; 1 1; 0 1; 0 0]);
	@assert(isapprox(result[1].data, [0.5 0.500019546308 12308.3096995]))
	# Intersections
	l1 = gmt("project -C22/49 -E-60/-20 -G10 -Q");
	l2 = gmt("project -C0/-60 -E-60/-30 -G10 -Q");
	#int = gmt("gmtspatial -Ie -Fl", l1, l2);       # Error returned from GMT API: GMT_ONLY_ONE_ALLOWED (59)

	# GMTREADWRITE
	G=gmt("grdmath", "-R0/10/0/10 -I1 5");
	if (GMTver >= 6)
		gmtwrite("lixo.grd", G,  scale=10, offset=-10)
		GG = gmtread("lixo.grd", grd=true);
		@assert(sum(G.z[:] - GG.z[:]) == 0)
		gmtwrite("lixo.tif", rand(UInt8,32,32,3), driver=:GTiff)
	else
		gmtwrite("lixo.grd", G)
		GG = gmtread("lixo.grd", grd=true);
	end

	# GRDINFO
	G=gmt("grdmath", "-R0/10/0/10 -I1 5");
	r=gmt("grdinfo -C", G);
	@assert(r[1].data == [0.0  10.0  0.0  10.0  5.0  5.0  1.0  1.0  11.0  11.0])
	r2=grdinfo(G, C=true, V=true);
	@assert(r[1].data == r2[1].data)

	# GRD2CPT
	G=gmt("grdmath", "-R0/10/0/10 -I1 X");
	C=grd2cpt(G);

	# GRD2XYZ
	D=grd2xyz(G); # Use G of previous test

	# GRDBLEND
	if (GMTver >= 6)
		G3=gmt("grdmath", "-R5/15/0/10 -I1 X Y");
		G2=grdblend(G,G3);
	end

	# GRDCLIP
	G2=grdclip(G,above=[5 6], low=[2 2], between="3/4/3.5"); # Use G of previous test

	# GRDCONTOUR
	G = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
	C = grdcontour(G, C="+0.7", D=[]);
	@assert((size(C[1].data,1) == 21) && norm(-0.6 - C[1].data[1,1]) < 1e-8)
	# Do the same but write the file on disk first
	gmt("write lixo.grd", G)
	GG = gmt("read -Tg lixo.grd");
	C = grdcontour("lixo.grd", C="+0.7", D=[]);
	@assert((size(C[1].data,1) == 21) && norm(-0.6 - C[1].data[1,1]) < 1e-8)
	x,y,z=GMT.peaks()
	G = gmt("surface -R-3/3/-3/3 -I0.1", [x[:] y[:] z[:]]);
	cpt = makecpt(T="-6/8/1");
	grdcontour(G, frame="a", fmt="png", color=cpt, pen="+c", X=1, Y=1, U=[])

	# GRDCUT
	G=gmt("grdmath", "-R0/10/0/10 -I1 X Y");
	G2=grdcut(G, limits=[3 9 2 8]);
	G2=grdcut("lixo.grd", limits=[3 9 2 8]);	# lixo.grd was written above in the gmtwrite test
	G2=grdcut(data="lixo.grd", limits=[3 9 2 8]);
	G2=grdcut(data=G, limits=[3 9 2 8]);

	# GRDEDIT
	# TODO

	# GRDFFT
	G2=grdfft(G, upward=800); 	# Use G of previous test
	G2=grdfft(G, G, E=[]);

	# GRDFILTER
	G2=grdfilter(G, filter="m600", distflag=4, inc=0.5); # Use G of previous test

	# GRDGRADIENT
	G2=grdgradient(G, azim="0/270", normalize="e0.6");	# Use G of previous test

	# GRDHISTEQ
	G2=grdhisteq(G, gaussian=[]);	# Use G of previous test

	# GRDLANDMASK
	G2=grdlandmask(R="-10/4/37/45", res=:c, inc=0.1);
	G2=grdlandmask("-R-10/4/37/45 -Dc -I0.1");			# Monolithitc

	# GRDPASTE
	G3=gmt("grdmath", "-R10/20/0/10 -I1 X");
	G2=grdpaste(G,G3);

	# GRDPROJECT	-- Works but does not save projection info in header
	G2=grdproject(G, proj="u29/1:1", F=[], C=[]); 		# Use G of previous test
	G2=grdproject("-Ju29/1:1 -F -C", G);				# Monolithic

	# GRDSAMPLE
	G2=grdsample(G, inc=0.5);		# Use G of previous test

	# GRDTREND
	G2=grdtrend(G, model=3);
	G2=grdtrend(G, model=3, diff=[]);

	# GRDTRACK
	G = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
	D = grdtrack([0 0], G);
	@assert(D[1].data == [0.0 0 1])
	D = grdtrack(G, [0 0]);
	D = grdtrack([0 0], G=G);
	@assert(D[1].data == [0.0 0 1])

	# GRDVECTOR
	G = gmt("grdmath -R-2/2/-2/2 -I0.1 X Y R2 NEG EXP X MUL");
	dzdy = gmt("grdmath ? DDY", G);
	dzdx = gmt("grdmath ? DDX", G);
	grdvector(dzdx, dzdy, I=0.2, vector=vector_attrib(head_size=0.25, stop=1, norm=0.65, shape=0.5), G=:black, W="1p", S=12)

	# Just create the figs but not check if they are correct.
	PS = grdimage(G, J="X10", ps=1);
	gmt("destroy")
	#grdimage("@earth_relief_05m", J="S21/90/15c", R="10/68/50/80r", B=:afg, X=:c, I="+")
	PS = grdview(G, J="X6i", JZ=5,  Q="s", C="topo", R="-15/15/-15/15/-1/1", view="120/30", ps=1);
	gmt("destroy")

	# IMSHOW
	imshow(rand(128,128),show=false)
	imshow(G, frame=:a, shade="+a45",show=false)

	# MAKECPT
	cpt = makecpt(range="-1/1/0.1");
	@assert((size(cpt.colormap,1) == 20) && (cpt.colormap[1,:] == [0.875, 0.0, 1.0]))

	# PLOT
	plot(collect(1:10),rand(10), lw=1, lc="blue", fmt=:ps, marker="circle", markeredgecolor=0, size=0.2, markerfacecolor="red", title="Bla Bla", x_label="Spoons", y_label="Forks")
	plot!(collect(1:10),rand(10), fmt="ps")

	# ARROWS
	arrows([0 8.2 0 6], R="-2/4/0/9", vec=vector_attrib(size=2,stop=1,shape=0.5,fill=:red), J=14, B=:a, pen="6p")
	arrows([0 8.2 0 6], R="-2/4/0/9", vec=vector_attrib(size=2,start=:arrow,stop=:tail,shape=0.5), J=14, B=:a, pen="6p")

	# LINES
	lines([0 0; 10 20], R="-2/12/-2/22", J="M2.5", W=1, G=:red, front=front(dist=(gap=1,size=0.25), symbol=:box))
	lines([-50 40; 50 -40],  R="-60/60/-50/50", J="X10", W=0.25, B=:af)
	lines!([-50 40; 50 -40], R="-60/60/-50/50", W=1, offset="0.5i/0.25i", vec=(size=0.65, fill=:red))
	#lines!([-50 40; 50 -40], R="-60/60/-50/50", W="1p+o1.25/0.25i+v0.65+gred", show=1)

	# SCATTER
	sizevec = [s for s = 1:10] ./ 10;
	scatter(1:10, 1:10, markersize = sizevec, axis=:equal, B=:a, marker=:square, fill=:green)
	scatter(1:10,rand(10), fill=:red, B=:a)

	# BARPLOT
	data = sort(randn(10));
	bar(data,G=0,B=:a)

	# BAR3
	G = gmt("grdmath -R-15/15/-15/15 -I0.5 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
	bar3(G, lw=:thinnest)

	# PSBASEMAP
	basemap(region="0/100/0/5000", proj="x1p0.5/-0.001", B="x1p+l\"Crustal age\" y500+lDepth")

	# PSCONVERT
	gmt("psbasemap -R-10/0/35/45 -Ba -P -JX10d > lixo.ps")
	psconvert("lixo.ps", adjust=true, fmt="eps")
	psconvert("lixo.ps", adjust=true, fmt="png")
	gmt("grdinfo lixo.png");

	# PSCOAST
	coast(R=[-10 1 36 45], J=:M12c, B="a", shore=1, E=("PT",(10,"green")), D=:c, fmt="ps");
	coast(R=[-10 1 36 45], J="M12c", B="a", shore=1, E=(("PT",(20,"green"),"+gcyan"),("ES","+gblue")), fmt="ps");
	coast(R=[-10 1 36 45], J="M", B="a", shore=1,  E="PT,+gblue", fmt="ps", borders="a", rivers="a");
	coast(R="-10/0/35/45", J="M12c", W=(0.5,"red"), fmt="ps", B="a", N=(1,(1,"green")))

	# PSCONTOUR
	x,y,z=GMT.peaks();
	contour([x[:] y[:] z[:]], cont=1, annot=2, frame="a")

	# PSIMAGE
	#gmt("psbasemap -R-10/0/35/45 -Ba -P -JX10d > lixo.ps")

	# PSSCALE
	C = makecpt(T="-200/1000/100", C="rainbow");
	colorbar(C=C, D="x8c/1c+w12c/0.5c+jTC+h", B="xaf+l\"topography\" y+lkm", fmt="ps", par=(MAP_FRAME_WIDTH=0.2))

	# PSHISTOGRAM
	histogram(randn(1000),W=0.1,center=true,fmt="ps",B=:a,N=0, x_offset=1, y_offset=1, stamp=[], t=50)

	# PSROSE
	data=[20 5.4 5.4 2.4 1.2; 40 2.2 2.2 0.8 0.7; 60 1.4 1.4 0.7 0.7; 80 1.1 1.1 0.6 0.6; 100 1.2 1.2 0.7 0.7; 120 2.6 2.2 1.2 0.7; 140 8.9 7.6 4.5 0.9; 160 10.6 9.3 5.4 1.1; 180 8.2 6.2 4.2 1.1; 200 4.9 4.1 2.5 1.5; 220 4 3.7 2.2 1.5; 240 3 3 1.7 1.5; 260 2.2 2.2 1.3 1.2; 280 2.1 2.1 1.4 1.3;; 300 2.5 2.5 1.4 1.2; 320 5.5 5.3 2.5 1.2; 340 17.3 15 8.8 1.4; 360 25 14.2 7.5 1.3];
	rose(data, swap_xy=[], A=20, R="0/25/0/360", B="xa10g10 ya10g10 +t\"Sector Diagram\"", W=1, G="orange", F=1, D=1, S=4)

	# PSSOLAR
	#D=solar(I="-7.93/37.079+d2016-02-04T10:01:00");
	#@assert(D[1].text[end] == "\tDuration = 10:27")
	solar(R="d", W=1, J="Q0/14c", B="a", T="dc")

	# PSTEXT
	text(text_record("TopLeft"), R="1/10/1/10", J="X10", F="+cTL",fmt="ps")

	# PSWIGGLE
	t=[0 7; 1 8; 8 3; 10 7];
	t1=gmt("sample1d -I5k", t); t2 = gmt("mapproject -G+uk", t1); t3 = gmt("math ? -C2 10 DIV COS", t2);
	wiggle(t3,R="-1/11/0/12", J="M8",B="af WSne", W="0.25p", Z="4c", G="+green", T="0.5p", A=1, Y="0.75i", S="8/1/2")

	# SURFACE
	G = surface(rand(100,3) * 150, R="0/150/0/150", I=1, Ll=-100, upper=100);
	@assert(size(G.z) == (151, 151))

	# SPLITXYZ (fails)
	#splitxyz([-14.0708 35.0730 0; -13.7546 35.5223 0; -13.7546 35.5223 0; -13.2886 35.7720 0; -13.2886 35.7720 0; -12.9391 36.3711 0], C=45, A="45/15", f="g")

	# TRIANGULATE
	G = triangulate(rand(100,3) * 150, R="0/150/0/150", I=1, grid=[]);

	# NEARNEIGHBOR
	G = nearneighbor(rand(100,3) * 150, R="0/150/0/150", I=1, N=4, S=10, r=true);

	# MISC
	G = GMT.grid_type(G.z);

	# Test common_options
	d = Dict(:xlim => (1,2), :ylim => (3,4));
	r = GMT.parse_R("", d);		@test r[1] == " -R1/2/3/4"
	d = Dict(:inc => (x=1.5, y=2.6, unit="meter"));
	r = GMT.parse_inc("",d,[:I :inc], "I");		@test r == " -I1.5e/2.6e"
	d = Dict(:inc => (x=1.5, y=2.6, unit="data"));
	r = GMT.parse_inc("",d,[:I :inc], "I");		@test r == " -I1.5/2.6u"
	d = Dict(:inc => (x=1.5, y=2.6, extend="data"));
	r = GMT.parse_inc("",d,[:I :inc], "I");		@test r == " -I1.5+e/2.6+e"
	d = Dict(:inc => (x=1.5, y=2.6, unit="nodes"));
	r = GMT.parse_inc("",d,[:I :inc], "I");		@test r == " -I1.5+n/2.6+n"
	d = Dict(:inc => (2,4));
	r = GMT.parse_inc("",d,[:I :inc], "I");		@test r == " -I2/4"
	d = Dict(:inc => [2 4]);
	r = GMT.parse_inc("",d,[:I :inc], "I");		@test r == " -I2/4"
	d = Dict(:inc => "2");
	r = GMT.parse_inc("",d,[:I :inc], "I");		@test r == " -I2"

	r = vector_attrib(size=2.2,stop=[],norm="0.25i",shape=:arrow,half_arrow=:right,
	                  justify=:end,fill=:none,trim=0.1,uv=true,scale=6.6);
	@test r == "2.2+e+je+r+g-+n0.25i+h1+t0.1+s+z6.6"

	r = front(dist=(gap="0.4i",size=0.25), symbol=:arcuate, pen=2, offset="10i", right=1);
	@test r == "0.4i/0.25+r+S+o10i+p2"

	# EXAMPLES
	plot(collect(1:10),rand(10), lw=1, lc="blue", marker="square",
	markeredgecolor=0, size=0.2, markerfacecolor="red", title="Hello World",
	x_label="Spoons", y_label="Forks")

	x = range(0, stop=2pi, length=180);	seno = sin.(x/0.2)*45;
	coast(region="g", proj="A300/30/6c", frame="g", resolution="c", land="navy")
	plot!(collect(x)*60, seno, lw=0.5, lc="red", marker="circle",
		markeredgecolor=0, size=0.05, markerfacecolor="cyan")

	x,y,z=GMT.peaks()
	G = surface([x[:] y[:] z[:]], R="-3/3/-3/3", I=0.1);	# Iterpolate into a regular grid
	grdcontour(G, cont=1, annot=2, frame="a")
	cpt = makecpt(T="-6/8/1");      # Create the color map
	grdcontour(G, frame="a", color=cpt, pen="+c")

	# Remove garbage
	rm("gmt.history")
	rm("lixo.ps")
	rm("lixo.eps")
	rm("lixo.grd")
	rm("lixo.png")
	if (GMTver >= 6)
		rm("lixo.tif")
	end

end					# End valid testing zone
