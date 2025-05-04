@testset "MISC" begin

	@test_throws ErrorException("Must select one convention (S options. Run gmthelp(velo) to learn about them)") velo!("",mat2ds([0. -8 0 0 4 6 0.5; -8 5 3 3 0 0 0.5], ["4x6", "3x3"]), region=(-15,10,-10,10))

	println("	MISC")
	GMT.resetGMT()
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
	G1 >  1;
	G1 >= 1;
	G1 <  1;
	G1 <= 1;
	G1 = mat2grid([0.0 1; 2 3]);
	G2 = mat2grid([4 5; 6 7; 8 9]);
	@test_throws ErrorException("The HDR array must have 4 or 9 elements") mat2grid(rand(4,4), reg=0, hdr=[0. 1 0 1 0 1]);
	@test_throws ErrorException("Grids have different sizes, so they cannot be added.") G1 + G2;
	@test_throws ErrorException("Grids have different sizes, so they cannot be subtracted.") G1 - G2;
	@test_throws ErrorException("Grids have different sizes, so they cannot be multiplied.") G1 * G2;
	@test_throws ErrorException("Grids have different sizes, so they cannot be divided.") G1 / G2;
	G1 = GMT.mat2grid(rand(4,4));
	G2 = GMT.mat2grid(rand(Float32,4,4), G1);
	I = mat2img(rand(UInt8,8,8), G1);
	flipud(I)
	fliplr(I)
	G2 = mat2grid(rand(Float32,4,4), mat2img(rand(UInt16,32,32),x=[220800 453600], y=[3.5535e6 3.7902e6]));
	G2 = GMT.mat2grid(rand(Int32,4,4));
	G2 = GMT.mat2grid(rand(4,4));
	G1 .* G2;
	G = mat2grid(ones(Float32, 4,4))
	setnodata!(G, 50)		# Actually this does nothing in this case
	sqrt(G);
	log(G);
	log10(G);
	getindex(G1,1:2);
	setindex!(G1, [-1 -1],1:2)
	size(G1)
	size(GMT.GMTcpt())
	flipud(G)
	fliplr(G)
	flipdim(G.z,1)
	fileparts("C:/a/b/c.d");
	GMT.resetGMT()

	I1 = mat2img(fill(UInt8(255), 3, 3));
	grid2img(img2grid(I1))
	I2 = mat2img(fill(UInt8(0), 3, 3)); I2[2,2] = 255;
	I1 - I2;
	I1 + I2;
	I1 | I2;
	I1 & I2;
	xor(I1, I2);
	I1 ⊻ I2;
	!I1;
	I1 = mat2img(fill(true, 3, 3));
	I2 = mat2img(fill(false, 3, 3)); I2[2,2] = true;
	I1 - I2;
	I1 + I2;
	I1 | I2;
	I1 & I2;
	xor(I1, I2);
	I1 ⊻ I2;
	!I1;

	@test GMT.bin2dec("10111") == 23
	@test GMT.dec2bin(23) == "10111"
	@test GMT.sub2ind((3,3), [1 2 3 1], [2 2 2 3]) == [4  5  6  7]

	A = [3 1; 3 3; 1 3; 3 2; 2 3; 1 1; 1 2; 2 3; 3 3; 3 3];
	C, ia, ic = GMT.uniq(A; dims=1);
	@test ia == [6, 7, 3, 5, 1, 4, 2]
	@test ic == [5, 7, 3, 6, 4, 1, 2, 4, 7, 7]
	@test isapprox(mad(ia)[1], 2.965204437)

	D = mat2ds(ones(3,2));
	@test D + 2 == [3 1; 3 1; 3 1];
	@test 2 + D == [3 1; 3 1; 3 1];
	@test D - 2 == [-1 1; -1 1; -1 1];
	@test 2 - D == [-1 1; -1 1; -1 1];
	@test D + [2 1] == [3 2; 3 2; 3 2]
	@test [2 1] + D == [3 2; 3 2; 3 2]
	@test D - [2 1] == [-1 0; -1 0; -1 0]
	@test [2 1] - D == [-1 0; -1 0; -1 0]
	@test D + D == [2 2; 2 2; 2 2]
	@test D - D == [0 0; 0 0; 0 0]

	D2=grd2xyz(gmt("grdmath", "-R0/10/0/10 -I2 X"))
	cat(D, D2);
	cat([D], D2);
	cat([D], [D2]);
	
	permutedims(mat2grid(rand(Float32,3,10,20)), [3,1,2], nodata=1e30);
	permutedims(mat2grid(rand(Float32,3,10,20)), [3,1,2], nodata=-1e30);

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
	I .+ UInt8(0);

	@info "linearfitxy"
	GMT.resetGMT()
	D = linearfitxy([0.0, 0.9, 1.8, 2.6, 3.3, 4.4, 5.2, 6.1, 6.5, 7.4], [5.9, 5.4, 4.4, 4.6, 3.5, 3.7, 2.8, 2.8, 2.4, 1.5], sx=1 ./ sqrt.([1000., 1000, 500, 800, 200, 80,  60, 20, 1.8, 1]), sy=1 ./ sqrt.([1., 1.8, 4, 8, 20, 20, 70, 70, 100, 500]));
	plot(D, linefit=true, band_ab=true, band_CI=true, ellipses=true, Vd=dbg2);
	plot!(D, linefit=true, Vd=dbg2)
	@info "ablines"
	ablines!(D, Vd=dbg2)
	ablines!(0,1, Vd=dbg2)
	ablines!([1, 2, 3], [1, 1.5, 2], linecolor=[:red, :orange, :pink], linestyle=:dash, linewidth=2, Vd=dbg2)

	isempty(GMT.GMTcpt())
	size(GMT.GMTcpt())
	isempty(GMT.GMTps())
	GMT.GMTdataset(rand(2,2), "lixo");
	GMT.GMTdataset(rand(Float32, 2,2), ["aiai"])
	GMT.GMTdataset(rand(Float32, 2,2), "aiai")
	GMT.GMTdataset(rand(Float32, 2,2))
	D = mat2ds(GMT.fakedata(4,4), x=:ny, color=:cycle, multi=true);
	D[1].text = ["lixo", "l", "p", "q"];
	GMT.set_dsBB!(D[1]);
	GMT.find4similar(D[1],0);
	getindex(D[1],1);
	setindex!(D[1], 1,1);
	Base.BroadcastStyle(typeof(D[1]));
	D = mat2ds(rand(3,3), colnames=["Time","b","c"]); D.attrib = Dict("Timecol" => "1");
	D[:Time];
	D["Time", "b"];
	try
	display(D);		# It seems the pretty tables solution has an Heisenbug.
	catch
	end
	plot(D, legend=true, Vd=dbg2);
	mat2ds(rand(5,4), x=:ny, color=:cycle, hdr=" -W1");
	mat2ds(rand(5,4), x=1:5, hdr=[" -W1" "a" "b" "c"], multi=true);
	D = mat2ds(rand(5,3), attrib=Dict("Timecol" => "1"), colnames=["Time","a","b"])
	mat2ds(D, [:,1:2])
	GMT.ds2ds(mat2ds(rand(4,4), multi=true))
	@test_throws ErrorException("The header vector can only have length = 1 or same number of MAT Y columns") mat2ds(rand(2,3), hdr=["a" "b"]);
	GMT.color_gradient_line(rand(3,2));
	GMT.color_gradient_line(mat2ds(rand(3,2)));
	GMT.color_gradient_line([mat2ds(rand(3,2)), mat2ds(rand(4,2))]);
	#GMT.line2multiseg(mat2ds(rand(5,2)), lt=[1,2], auto_color=true);
	#GMT.line2multiseg(mat2ds(rand(5,2)), lt=[1,2,4], auto_color=true);
	#GMT.line2multiseg(mat2ds(rand(3,2)), lt=[1,2,4]);
	#GMT.line2multiseg([mat2ds(rand(3,2)), mat2ds(rand(4,2))], lt=[1,2], auto_color=true);
	#GMT.resetGMT()

	stats(D);
	stats(D, 2);
	@test groupby(mat2ds([1.0 44; 1 7; 2 9; 2 5]), 1)[1].data == [1.0 44; 1 7]
	@test groupby(mat2ds([1.0 44; 1 7; 2 9; 2 5], ["A", "A", "B", "B"]), "Text")[1].data == [1.0 44; 1 7]

	GMT.mat2grid(rand(Float32, 10,10), reg=1);
	GMT.mat2grid(1, hdr=[0. 5 0 5 1 1])
	GMT.num2str(rand(2,3));
	text_record([-0.4 7.5; -0.4 3.0], ["a)", "b)"]);
	text_record(["aa", "bb"], "> 3 5 18p 5i j");
	text_record(["> 3 5 18p 5i j", "aa", "bb"]);
	text_record([["aa", "bb"],["cc", "dd", "ee"]]);

	# TEST THE API DIRECTLY (basically to improve coverage under GMT6)
	PS = plot(rand(3,2), ps=1);
	API = GMT.GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL + GMT.GMT_SESSION_COLMAJOR);
	GMT.ps_init(API, PS, 0);
	GMT.gmtlib_getparameter(API, "MAP_ORIGIN_X")
	gmt("destroy")

	# Test ogr2GMTdataset
	API = GMT.GMT_Create_Session("GMT", 2, GMT.GMT_SESSION_NOEXIT + GMT.GMT_SESSION_EXTERNAL + GMT.GMT_SESSION_COLMAJOR);
	gmtread("lixo.gmt");		# This "lixo.gmt" was created in test_avatars.jl
	if (GMTver > v"6.1.1")
		#GMT.gmt_ogrread(API, "lixo.gmt", C_NULL);		# Keep testing the old gmt_ogrread API.
	end
	GMT.GMT_Get_Default(API, "API_VERSION", "        ");
	D = gmtconvert([1.0 2 3; 2 3 4], a="2=lolo+gPOINT");	# There's a bug in GMT for this. No data points are printed
	gmtwrite("lixo.gmt", D)
	@test gmtconvert([1.0 2 3; 2 3 4], binary_out="3f", write="a.bin", Vd=2) == "gmtconvert  > a.bin -bo3f"
	@test gmtconvert([1.0 2 3; 2 3 4], binary_out="3f", append="a.bin", Vd=2) == "gmtconvert  >> a.bin -bo3f"
	rm("lixo.gmt")

	check = UInt8[zeros(9,9) ones(9,9) ones(9,9).*2; ones(9,9).*3 ones(9,9).*4 ones(9,9).*5; ones(9,9).*6 ones(9,9).*7 ones(9,9).*8];
	C = makecpt(range=(0,9,1));
	I = mat2img(check);
	I.n_colors = 0
	rgb = GMT.ind2rgb(I);
	GMT.resetGMT()
	I = mat2img(check, cmap=C);
	rgb = GMT.ind2rgb(I);
	println()
	@info "before image_alpha!"
	image_alpha!(I, alpha_ind=5);
	@info "before 2"
	image_alpha!(I, alpha_vec=round.(UInt32,rand(6).*255));
	@info "before 3"
	image_alpha!(I, alpha_band=round.(UInt8,rand(27,27).*255))
	img = mat2img(rand(UInt8, 6, 6, 3));
	mask = fill(UInt8(0), 6, 6);
	mask[3:4,3:4] .= 255;
	@info "before 4"
	image_alpha!(img, alpha_band=mask, burn=:red)
	mask[1] = 100;		# Force variable mask
	@info "before 5"
	image_alpha!(img, alpha_band=mask, burn=(0,255,0))
	@info "after image_alpha!"

	I1 = mat2img(rand(UInt8, 16,16)); I2 = mat2img(rand(UInt8, 16,16)); I3 = mat2img(rand(UInt8, 16,16));
	grays2rgb(I1,I2,I3);
	grays2rgb(I1.image,I2.image,I3.image);

	GMT.resetGMT()
	try
		upGMT()
	catch
	end
	image_cpt!(I, C)
	GMT.cmap2cpt(I)
	GMT.transpcmap!(I, true)
	GMT.transpcmap!(I, false)
	@info "before image_cpt!"
	image_cpt!(I, clear=true)
	@info "after image_cpt!"

	GMT.linspace(1,1,100);
	GMT.logspace(1,5);
	GMT.fakedata(50,1);
	GMT.meshgrid(1:5, 1:5, 1:5);
	GMT.cart2pol(5,0);
	GMT.pol2cart(5,0);
	GMT.sph2cart([0.7854 0.7854], [0.6155 -0.6155], [1.7321 1.7321]);
	GMT.cart2sph([1 1], [1 1], [1 -1]);
	GMT.findmax_nan([1., 3, NaN, 8])
	GMT.findmin_nan([1., 3, NaN, 8])
	extrema(rand(Complex{Int16}, 3,3))
	extrema(rand(Complex{Float32}, 3,3))
	fields(7);
	fields(rand(2,2))
	tic();toc();
	@test_throws ErrorException("`toc()` without `tic()`") toc()

	GMT.zscale(0:9999)

	# Orbits
	println("	Orbits")
	@test_throws ErrorException("Only Orthographic projection is allowed.") orbits!();
	@test_throws ErrorException("Only Orthographic projection is allowed.") orbits!(mat2ds(rand(10,3)));
	orbits()
	orbits(mat2ds(rand(10,3)))
	@test_throws ErrorException("Orbit height cannot be 0 when input is in degrees.") orbits([0.0 0; 1 1]);

	# Seismicity
	println("	Seismicity")
	seismicity(last="1w", circle=(-90,10,500), data=1)
	seismicity(last="1w", R=:d, show=false);
	seismicity(last="1w", R=:d, size=5, show=false);
	GMT.seislegend(Vd=2);

	# Weather
	println("	Weather")
	weather(year=2023, debug=1);
	weather(city="Quarteira", var="rain");

	dataset = "reanalysis-era5-single-levels"
	request = """{
		"product_type": ["reanalysis"],
		"variable": [
			"10m_u_component_of_wind",
			"10m_v_component_of_wind"
		],
		"year": ["2024"],
		"month": ["12"],
		"day": ["06"],
		"time": ["16:00"],
		"data_format": "netcdf",
		"download_format": "unarchived",
		"area": [58, 6, 55, 9]
	}"""
	@test_throws ArgumentError era5(dataset=dataset, params=request, key="blabla");
	clipboard(request)
	@test_throws ArgumentError era5(cb=true, dataset=dataset, key="blabla");

	# MB-System
	println("	MB-System")
	mbgetdata("aa", Vd=2)
	mbimport("aa", Vd=2)
	mbsvplist("aa", Vd=2)
	mblevitus(Vd=2)

	println("	EXAMPLES")
	# EXAMPLES
	whereami();
	plot(1:10,rand(10), lw=1, lc="blue", marker="square", markeredgecolor=:white, size=0.2, markerfacecolor="red", title="Hello World", xlabel="Spoons", ylabel="Forks")

	x = range(0, stop=2pi, length=180);	seno = sin.(x/0.2)*45;
	coast(region="g", proj="A300/30/6c", axis="g", resolution="c", land="navy")
	plot!(collect(x)*60, seno, lw=0.5, lc="red", marker="circle", markeredgecolor=0, size=0.05, markerfacecolor="cyan")

	G = GMT.peaks();
	setsrs!(G, prj="geog")
	setcoords!(G, x=[0,10], y=[5,15])
	info(GMT.peaks(N=2), full=true);
	info(mat2ds(rand(2,3), multi=true));
	grdcontour(G, cont=1, annot=2, axis="a")
	cpt = makecpt(T="-6/8/1");      # Create the color map
	grdcontour(G, axis="a", color=cpt, pen="+c", fmt=:png, savefig="lixo1")
	D = grdcontour(G, cont=[-2,0,5], dump=true);

	GMT.replicateline([0 0; 1 1; 2 1], 0.1);

	info(makecpt(C=:rainbow));
	makecpt(G);
	makecpt(G, equalize=true);

	add2PSfile("Bla")
	add2PSfile(["Bla", "Bla"])

	GMT.funcurve(GMT.square, [1 10])
	@test_throws ErrorException("Function tan not implemented in funcurve().") GMT.funcurve(tan, [1 10]);

	println("	DRAWING")
	circle(0,0,1,first=true,Vd=dbg2);
	cross(0,0,1,Vd=dbg2);
	custom(0,0, "bla", 1,Vd=dbg2);
	diamond(0,0,1,Vd=dbg2);
	hexagon(0,0,1,Vd=dbg2);
	itriangle(0,0,1,Vd=dbg2);
	letter(0,0, 1, "A", "Helvetica", "CM",Vd=dbg2);
	minus(0,0,1,Vd=dbg2);
	pentagon(0,0,1,Vd=dbg2);
	plus(0,0,1,Vd=dbg2);
	square(0,0,1,Vd=dbg2);
	star(0,0,1,Vd=dbg2);
	triangle(0,0,1,Vd=dbg2);
	ydash(0,0,1,Vd=dbg2);
	box(0,0,1,1,Vd=dbg2);
	rect(0,0,1,1,Vd=dbg2);
	ellipseAz(0,0, 0, 1, 1,Vd=dbg2);
	rotrect(0,0, 0, 1, 1,Vd=dbg2);
	rotrectAz(0,0, 0, 1, 1,Vd=dbg2);
	roundrect(0,0, 1, 1, 1,Vd=dbg2);
	ellipse(300,201,0, 200, 50, first=true, units=:points, fill=:purple, pen=1, X=0, Y=0);
	circle(305,185,56, fill=:black, figname="lixo.ps");

	println("	REMOTEGRID")
	remotegrid("venus", "3m") == "@venus_relief_03m"
	remotegrid("moon", "3m", reg="pi") == "@moon_relief_03m_p"
	remotegrid("relief", "5m") == "@earth_relief_05m"
	remotegrid("earth_relief", "5m") == "@earth_relief_05m"
	remotegrid("mag", "1d", reg="p") == "@earth_mag_01d_p"

end
