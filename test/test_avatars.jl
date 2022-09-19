	println("	PLOT")
	# PLOT
	plot(collect(1:10),rand(10), lw=1, lc="blue", fmt=:ps, marker="circle", markeredgecolor=0, size=0.2, markerfacecolor="red", title="Bla Bla", xlabel="Spoons", ylabel="Forks", savefig="lixo")
	plot(mat2ds(GMT.fakedata(6,6), x=:ny, color=[:red, :green, :blue, :yellow], ls=:dashdot, multi=true), leg=true, label="Bla")
	plot("",hcat(collect(1:10)[:],rand(10,1)))
	plot!("",hcat(collect(1:10)[:],rand(10,1)), Vd=dbg2)
	plot(hcat(collect(1:10)[:],rand(10,1)), Vd=dbg2)
	plot!(hcat(collect(1:10)[:],rand(10,1)), Vd=dbg2)
	plot!(collect(1:10),rand(10), fmt="ps")
	plot(0.5,0.5, R="0/1/0/1", Vd=dbg2)
	plot!(0.5,0.5, R="0/1/0/1", Vd=dbg2)
	plot(1:10,rand(10), S=(symb=:c,size=7,unit=:point), color=:rainbow, zcolor=rand(10))
	plot(1:10,rand(10)*3, S="c7p", color=:rainbow, Vd=dbg2)
	plot(1:10,rand(10)*3, S="c7p", color=:rainbow, zcolor=rand(10)*3)
	plot(1:2pi, rand(6), xaxis=(pi=1,), Vd=dbg2)
	plot(1:2pi, rand(6), xaxis=(pi=(1,2),), Vd=dbg2)
	plot([5 5], region=(0,10,0,10), frame=(annot=:a, ticks=:a, grid=5), figsize=10, symbol=:p, markerline=0.5, fill=:lightblue, E=(Y=[2 3 6 9],pen=1,cap="10p"), Vd=dbg2);
	plot(rand(10,4), S=:c, ms=0.2, markeredgecolor=:red, ml=2, Vd=dbg2)
	plot(rand(10,4), S=:c, ms=0.2, marker=:star, ml=2, W=1, Vd=dbg2)
	plot([0.0 0; 1.1 1], theme=(name=:dark, bg_color="gray"), lc=:white, Vd=dbg2)
	#plot([0.0 0; 1.1 1], theme=(name=:modern,), Vd=dbg2)
	plot(1:4, rand(4,4), theme=(name=:none, save=true), leg=true)	# Resets default conf and delete the theme_jl file
	@test startswith(plot!([1 1], marker=(:r, [2 3]), Vd=dbg2), "psxy  -R -J -Sr")
	xy = [0. 0.; 1 1; 2 1; 0 0];
	plot(xy, region=(-1,3,-1,2), clip=(xy, N=true), frame=(axes=:WEsn, grid=0.2, fill=:darkgray), Vd=dbg2);
	plot(x=[-1.0, -1.0], y=[-1.0, 1.0], pen="1p,black+ve0.2c")
	@test occursin(" -Sr", plot!([1 1], marker=(:r, [2 3]), Vd=dbg2))
	@test_throws ErrorException("Wrong number of extra columns for marker (r). Got 3 but expected 2") plot!([1 1], marker=(:r, [2 3 4]), Vd=dbg2)
	@test_throws ErrorException("Unknown graphics file extension (.ppf)") plot(rand(5,2), savefig="la.ppf")
	@test startswith(plot!([1 1], marker=(:Web, [2 3], (inner=5, arc=30,radial=45, pen=(2,:red))), Vd=dbg2), "psxy  -R -J -SW/5+a30+r45+p2,red")
	@test startswith(plot!([1 1], marker=(Web=true, inner=5, arc=30,radial=45, pen=(2,:red)), Vd=dbg2), "psxy  -R -J -SW/5+a30+r45+p2,red")
	@test startswith(plot!([1 1], marker="W/5+a30", Vd=dbg2), "psxy  -R -J -SW/5+a30")
	@test startswith(plot!([1 1], marker=:Web, Vd=dbg2), "psxy  -R -J -SW")
	@test startswith(plot!([1 1], marker=:W, Vd=dbg2), "psxy  -R -J -SW")
	@test startswith(plot([5 5], marker=(:E, 500), Vd=dbg2), "psxy  -JX" * GMT.def_fig_size * " -Baf -BWSen -R4.74/5.26/4.74/5.26 -SE-500")
	@test startswith(plot(region=(0,10,0,10), marker=(letter="blaBla", size="16p"), Vd=dbg2), "psxy  -R0/10/0/10 -JX" * GMT.def_fig_size * " -Baf -BWSen -Sl16p+tblaBla")
	@test startswith(plot([5 5], region=(0,10,0,10), marker=(bar=true, size=0.5, base=0,), Vd=dbg2), "psxy  -R0/10/0/10 -JX" * GMT.def_fig_size * " -Baf -BWSen -Sb0.5+b0")
	@test startswith(plot([5 5], region=(0,10,0,10), marker=(custom=:sun, size=0.5), Vd=dbg2), "psxy  -R0/10/0/10 -JX" * GMT.def_fig_size * " -Baf -BWSen -Sksun/0.5")
	plot([5 5 0 45], region=(0,10,0,10), marker=(pie=true, arc=15, radial=30), Vd=dbg2)
	plot([0.5 1 1.75 5 85], region=(0,5,0,5), figsize=12, marker=(matang=true, arrow=(length=0.75, start=true, stop=true, half=:right)), ml=(0.5,:red), fill=:blue, Vd=dbg2)
	plot([2.5 2.5], region=(0,4,0,4), figsize=12, marker=(:matang, [2 50 350], (length=0.75, start=true, stop=true, half=:right)), ml=(0.5,:red), fill=:blue, Vd=dbg2)
	plot([1 1], limits=(0,6,0,6), figsize=7, marker=:circle, ms=0.5, error_bars=(x=:x, cline=true), Vd=dbg2)	# Warning line
	plot(rand(5,3), region=[0,1,0,1])
	plot("polyg_hole.gmt")
	plot(x -> x^3 - 2x^2 + 3x - 1, xlim=(-5,5), Vd=dbg2)
	plot(x -> x^3 - 2x^2 + 3x - 1, -10:10, Vd=dbg2)
	plot!(x -> x^3 - 2x^2 + 3x - 1, 10, Vd=dbg2)
	plot!(x -> x^3 - 2x^2 + 3x - 1, Vd=dbg2)
	plot!(x -> cos(x) * x, y -> sin(y) * y, linspace(0,2pi,100), Vd=dbg2)
	plot(1:5, rand(5), ls="Line&Bla Bla&", lc=:red, Vd=dbg2)
	plot(1:5, rand(5), ls="Line&Circ", lc=:red, Vd=dbg2)
	plot(rand(5,2), ls="DotCirc", Vd=dbg2)
	plot(rand(5,2), ls="DotCirc#", Vd=dbg2)
	plot(rand(5,2), ls="DashDot", Vd=dbg2)
	plot(rand(5,2), ls="-.", Vd=dbg2)
	@test_throws ErrorException("Bad line style. Options are (for example) [Line|DashDot|Dash|Dot]Circ") plot(rand(5,2), ls="Dat")
	plot(rand(5,2), pen=(2,:gradient),Vd=3);
	plot([1. 2; 3 4], title=(str="Bla bla", font=50, offset="-70p"), subtitle=:Bluuu, xlabel="aa", ylabel="bb", zlabel="cc",Vd=dbg2)
	plot(rand(8,2), bg="-circ")
	plot(rand(8,2), bg="x", Vd=dbg2)
	plot(rand(8,2), bg="blabla.png", Vd=dbg2)
	plot(rand(8,2), bg=mat2grid(rand(64,64)), Vd=dbg2)
	plot(rand(8,2), bg=(:somb, :turbo), Vd=dbg2)

	D = mat2ds(rand(8,5))
	plot(D, yvar=:Z1, Vd=dbg2)
	plot(D, xvar=1, yvar=:Z1, Vd=dbg2)
	plot(D, xvar=1, yvar=[:Y, :Z1], Vd=dbg2)
	plot(D, xvar=1, yvar=(:Y, :Z1), Vd=dbg2)
	plot(D, xvar=1, yvar=[2, 3], Vd=dbg2)
	plot(D, xvar=1, yvar=(2, 3), Vd=dbg2)

	D = [mat2ds([0 0; 0 1; 1 1; 1 0.3; 0 0])[1], mat2ds([1 1; 1 2; 2 2; 2 1; 1 1])[1]];
	C = makecpt(cmap = :hot, range = (0, 5));
	r = psxy!(D, C=C, Z=[1,4], pen=2, Vd=2)
	@test contains(r, " -G+z -L -W2 -K")
	r = psxy!(D, C=C, Z=[1,4], pen=(pen=2, zlevels=true), Vd=2)
	@test contains(r, " -G+z -L -W2+z -K")
	r = psxy!(D, C=C, Z=(data=[1,4], outline=true, nofill=true), Vd=2)
	@test contains(r, " -W0.5+z -K")
	r = psxy!(D, C=C, Z=(data=[1,4], outline=true), Vd=2)
	@test contains(r, " -G+z -L -W0.5+z -K")
	r = psxy!(D, C=C, Z=(data=[1,4], nofill=true), Vd=2)
	@test contains(r, " -W0.5+z -K")

	println("	LINES")
	lines([0 0; 10 20], R="-2/12/-2/22", J="M2.5", W=1, G=:red, decorated=(dist=(1,0.25), symbol=:box))
	lines([-50 40; 50 -40],  R="-60/60/-50/50", J="X10", W=0.25, B=:af, box_pos="+p0.5", leg_pos=(offset=0.5,), leg=:TL)
	lines!([-50 40; 50 -40], R="-60/60/-50/50", W=1, offset="0.5i/0.25i", Vd=dbg2)
	lines(1:10,rand(10), W=0.25, Vd=dbg2)
	lines!(1:10,rand(10), W=0.25, Vd=dbg2)
	lines!("", rand(10), W=0.25, Vd=dbg2)
	xy = gmt("gmtmath -T0/180/1 T SIND 4.5 ADD");
	lines(xy, R="-5/185/-0.1/6", J="X6i/9i", B=:af, W=(1,:red), decorated=(dist=(2.5,0.25), symbol=:star, symbolsize=1, pen=(0.5,:green), fill=:blue, dec2=1))
	D = histogram(randn(100), I=:o, T=0.1);
	@test_throws ErrorException("Something went wrong when calling the module. GMT error number = 72") histogram(randn(100), I=:o, V=:q, W=0.1);
	lines(D, steps=(x=true,), close=(bot=true,))
	x = GMT.linspace(0, 2pi);  y = cos.(x)*0.5;
	r = lines(x,y, limits=(0,6.0,-1,0.7), figsize=(40,8), pen=(lw=2,lc=:sienna), decorated=(quoted=true, n_labels=1, const_label="ai ai", font=60, curved=true, fill=:blue, pen=(0.5,:red)), par=(:PS_MEDIA, :A1), axis=(fill=220,),Vd=dbg2);
	@test startswith(r, "psxy  -R0/6.0/-1/0.7 -JX40/8 -Baf -BWSen+g220 --PS_MEDIA=A1 -Sqn1:+f60+l\"ai ai\"+v+p0.5,red -W2,sienna")

	bar!(x -> x^3 - 2x^2 + 3x - 1, Vd=dbg2)
	lines!(x -> x^3 - 2x^2 + 3x - 1, Vd=dbg2)
	lines!(x -> cos(x) * x, y -> sin(y) * y, linspace(0,2pi,100), Vd=dbg2)
	x = LinRange(0,2π,50);
	lines(x, sin.(x), ls="FrontSlip", legend=true, figname="lixo", theme=("A2"))
	lines(x, sin.(x), ls="lineCirc", legend=(label="sin(x)", box=:none), lc=:red, figname="lixo")
	lines(x, sin.(x), ls="FrontCircLeft", legend=(label="sin(x)"), mc=:red, figname="lixo")
	lines(x, sin.(x), ls="linediamond", theme=(:A0atg), Vd=dbg2) 
	lines(x, sin.(x), ls="linediamond", theme=(:A2atg), Vd=dbg2) 
	lines(x, sin.(x), ls="linediamond", theme=(:A2agITGraph), Vd=dbg2)
	theme("classic", noticks=true, graygrid=true)
	theme("modern")		# Must reset otherwise many tests would fail due to different configs
	scatter!(x -> x^3 - 2x^2 + 3x - 1, Vd=dbg2)
	scatter!(x -> cos(x) * x, y -> sin(y) * y, linspace(0,2pi,100), Vd=dbg2)
	hlines!([0.2, 0.6], pen=(1, :red))
	vlines!([0.2, 0.6], pen=(1, :red))

	println("	STAIRS")
	x = linspace(0, 4*pi, 50);
	stairs(x, sin.(x), Vd=dbg2)
	stairs!(x, sin.(x), Vd=dbg2)
	stairs([x sin.(x)], step=:pre, Vd=dbg2)
	stairs!([x sin.(x)], step=:pre, Vd=dbg2)
	stairs!("", [x sin.(x)], Vd=dbg2)

	println("	BAND")
	vband([1 2; 2.5 3; 4 5], fill=(:red, :blue), alpha=(0.75, 0.5, 0.3), region=(0,5,-1,5), Vd=dbg2)
	vband!([1 2; 2.5 3; 4 5], fill=(:red, :blue), alpha=(0.75, 0.5, 0.3), region=(0,5,-1,5), Vd=dbg2)
	hband([1 2; 2.5 3; 4 5], fill=(:red, :blue), alpha=(0.75, 0.5, 0.3), region=(0,5,-1,5), Vd=dbg2)
	hband!([1 2; 2.5 3; 4 5], fill=(:red, :blue), alpha=(0.75, 0.5, 0.3), region=(0,5,-1,5), Vd=dbg2)
	band(x->sin(x)/x, 10, width=0.1, fill="green@80", Vd=dbg2)
	band!(x->sin(x)/x, 10, width=0.1, fill="green@80", Vd=dbg2)
	x = -10:0.11:10;
	band(mat2ds([x sin.(x)./x]), width=0.1, fill="green@80", Vd=dbg2)
	band!(mat2ds([x sin.(x)./x]), width=(0.1,0.2), fill="green@80", Vd=dbg2)
	band("",[mat2ds([x sin.(x)./x])], width=0.1, fill="green@80", Vd=dbg2)
	band!("",[mat2ds([x sin.(x)./x])], width=(0.1,0.2), fill="green@80", Vd=dbg2)
	band(x, sin.(x)./x, width=0.1, Vd=dbg2)
	band!(x, sin.(x)./x, width=0.1, Vd=dbg2)
	band(mat2ds([x sin.(x)./x]), sin.(x)./x, sin.(x)./x, envelope=true, Vd=dbg2)	# Crashes GMT
	band!(mat2ds([x sin.(x)./x]), sin.(x)./x, sin.(x)./x, envelope=true, Vd=dbg2)
	GMT.cat_2_arg2(rand(3), mat2ds(rand(3,2)));
	GMT.cat_2_arg2(mat2ds(rand(3,2)), rand(3));
	GMT.cat_2_arg2(mat2ds(rand(3,2)), mat2ds(rand(3,2)));
	GMT.cat_3_arg2(rand(3),rand(3),rand(3));
	GMT.cat_3_arg2(mat2ds(rand(3,2)),rand(3),rand(3));

	plotyy([1 1; 2 2], [1.5 1.5; 3 3], R="0.8/3/0/5", title="Ai", ylabel=:Bla, xlabel=:Ble, seclabel=:Bli, Vd=dbg2);

	println("	PLOT3D")
	plot3d(rand(5,3), marker=:cube)
	plot3d!(rand(5,3), marker=:cube, Vd=dbg2)
	plot3d("", rand(5,3), Vd=dbg2)
	plot3d!("", rand(5,3), Vd=dbg2)
	plot3d(1:10, rand(10), rand(10), Vd=dbg2)
	plot3d!(1:10, rand(10), rand(10), Vd=dbg2)
	plot3d!(x -> sin(x), y -> cos(y), 0:pi/50:10pi, Vd=dbg2)
	plot3d!(x -> sin(x)*cos(10x), y -> sin(y)*sin(10y), z -> cos(z), 0:pi/100:pi, Vd=dbg2)
	r = plot3([1 2 4], frame=(flipx=1,), yaxis=(flip=1,), zaxis=(flip=1,), Vd=2)
	@test occursin("-JX-14c/-9.5", r)
	@test occursin("-JZ-", r)
	scatter3!(x -> sin(x), y -> cos(y), 0:pi/50:10pi, Vd=dbg2)
	scatter3!(x -> sin(x)*cos(10x), y -> sin(y)*sin(10y), z -> cos(z), 0:pi/100:pi, Vd=dbg2)

	println("	ARROWS")
	arrows([0 8.2 0 6], R="-2/4/0/9", arrow=(len=2,stop=1,shape=0.5,fill=:red), J=:X14, B=:a, pen="6p")
	arrows([0 8.2 0 6], R="-2/4/0/9", arrow=(len=2,start=:arrow,stop=:tail,shape=0.5), J=:X14, B=:a, pen="6p")
	arrows!([0 8.2 0 6], R="-2/4/0/9", arrow=(len=2,start=:arrow,shape=0.5), pen="6p", Vd=dbg2)
	arrows!("", [0 8.2 0 6], R="-2/4/0/9", arrow=(len=2,start=:arrow,shape=:V, pen=(1,:red)), pen="6p", Vd=dbg2)
	@test_throws ErrorException("Bad data type for the 'shape' option") arrows!("", [0 8.2 0 6], R="-2/4/0/9", arrow=(len=2,justify=:center,middle=:reverse,shape='1'), pen="6p", Vd=dbg2)
	@test occursin("-SvB4p/18p/7.5p", arrows([1 0 45 4], R="0/6/-1/1", J="x2.5", pen=(1,:blue), arrow4=(align=:mid, head=(arrowwidth="4p", headlength="18p", headwidth="7.5p"), double=true), Vd=dbg2))
	@test occursin("-SvB4p/18p/7.5p", arrows([1 0 45 4], R="0/6/-1/1", J="x2.5", lw=1, arrow4=(align=:mid, head=("4p","18p", "7.5p"), double=true), Vd=dbg2))
	@test occursin("-Svs4p/18p/7.5p", arrows([1 0 45 4], R="0/6/-1/1", J="x2.5", lw=1, arrow4=(align=:pt, head="4p/18p/7.5p"), Vd=dbg2))

	println("	PCOLOR")
	G = GMT.peaks(N=21);
	pcolor(G, outline=(0.5,:dot), Vd=dbg2)
	pcolor!("", G, outline=(0.5,:dot), Vd=dbg2)
	pcolor!(G, T=true, Vd=dbg2)
	pcolor(G.x, G.y, G.z, Vd=dbg2)
	G = GMT.peaks(N=21, pixreg=true);
	pcolor!(G.x, G.y, G.z, R="-3/3/-3/3", Vd=dbg2)
	X,Y = GMT.meshgrid(-3:6/17:3);	XX = 2*X .* Y;	YY = X.^2 .- Y.^2;
	pcolor(XX,YY, reshape(repeat([1:18; 18:-1:1], 9,1), size(XX)), lc=:black, Vd=dbg2)
	pcolor(G.x, G.y, G.z, labels=:y, show=false)
	pcolor(G.x, G.y, G.z, labels=1)
	pcolor(G, labels=1, font=(angle=45, font=(5,:red)))

	println("	SCATTER")
	sizevec = [s for s = 1:10] ./ 10;
	scatter(1:10, 1:10, markersize = sizevec, aspect=:equal, B=:a, marker=:square, fill=:green)
	scatter(rand(10), leg=:bottomrigh, fill=:red)	# leg wrong on purpose
	scatter(1:10,rand(10)*3, S="c7p", color=:rainbow, zcolor=rand(10)*3, show=1, Vd=dbg2)
	scatter(rand(50),rand(50), markersize=rand(50), zcolor=rand(50), aspect=:equal, alpha=50, Vd=dbg2)
	scatter(1:10, rand(10), fill=:red, B=:a)
	scatter!(1:10, rand(10), fill=:red, B=:a, Vd=dbg2)
	scatter(1:10, Vd=dbg2)
	scatter!(1:10, Vd=dbg2)
	scatter(rand(5,5))
	scatter!(rand(5,5), Vd=dbg2)
	scatter("",rand(5,5), Vd=dbg2)
	scatter!("",rand(5,5), Vd=dbg2)
	scatter(1:20,rand(20), size=[2,20], Vd=dbg2)
	scatter(1:20,rand(20), size=(log10, [2,20]), Vd=dbg2)
	scatter3(rand(5,5,3))
	scatter3!(rand(5,5,3), Vd=dbg2)
	scatter3("", rand(5,5,3), Vd=dbg2)
	scatter3!("", rand(5,5,3), Vd=dbg2)
	scatter3(1:10, rand(10), rand(10), fill=:red, B=:a, Vd=dbg2)
	scatter3!(1:10, rand(10), rand(10), Vd=dbg2)

	println("	BARPLOT")
	bar(sort(randn(10)), G=0, B=:a)
	bar(rand(20),bar=(width=0.5,), Vd=dbg2)
	bar!(rand(20),bar=(width=0.5,), Vd=dbg2)
	bar(1:20,  rand(20),bar=(width=0.5,), Vd=dbg2)
	bar!(1:20, rand(20),bar=(width=0.5,), Vd=dbg2)
	bar(rand(20),hbar=(width=0.5,unit=:c, base=9), Vd=dbg2)
	bar(rand(20),bar="0.5c+b9",  Vd=dbg2)
	bar(rand(20),hbar="0.5c+b9",  Vd=dbg2)
	bar(rand(10), xaxis=(custom=(pos=1:5,type="A"),), Vd=dbg2)
	bar(rand(10), axis=(custom=(pos=1:5,label=[:a :b :c :d :e]),), Vd=dbg2)
	bar((1,2,3), Vd=dbg2)
	bar((1,2,3), (1,2,3), Vd=dbg2)
	bar!((1,2,3), Vd=dbg2)
	bar!((1,2,3), (1,2,3), Vd=dbg2)
	bar([3 31], C=:lightblue, Vd=dbg2)
	bar("", [3 31], C=:lightblue, Vd=dbg2)
	bar!("", [3 31], C=:lightblue, frame=:noannot, Vd=dbg2)
	men_means, men_std = (20, 35, 30, 35, 27), (2, 3, 4, 1, 2);
	x = collect(1:length(men_means));
	bar(x.-0.35/2, collect(men_means), width=0.35, color=:lightblue, limits=(0.5,5.5,0,40), frame=:none, error_bars=(y=men_std,), Vd=dbg2)
	bar([0. 1 2 3; 1 2 3 4], error_bars=(y=[0.1 0.2 0.33; 0.2 0.3 0.4],), fillalpha=[0.3 0.5 0.7], Vd=dbg2)
	bar([0. 1 2 3; 1 2 3 4], fill=(1,2,3), Vd=dbg2)
	bar([0. 1 2 3; 1 2 3 4], stack=1, Vd=dbg2)
	bar(1:5, [20 25; 35 32; 30 34; 35 20; 27 25], fill=["lightblue", "brown"], xaxis=(ticks=(:G1, :G2, :G3, "G4"),), Vd=dbg2)
	bar(1:5, [20 25; 35 32; 30 34; 35 20; 27 25], fill=["lightblue", "brown"], xticks=(:G1, :G2, :G3, :G4), zticks=(:Z1,:Z2), Vd=dbg2)
	bar(1:3,[-5 -15 20; 17 10 21; 10 5 15], stacked=1, Vd=dbg2)
	bar([0. 1 2 3; 1 2 3 4], fill=("red", "green", "blue"), Vd=dbg2)
	bar(rand(15), color=:rainbow, Y=3)
	T = mat2ds([1.0 0.446143; 2.0 0.581746; 3.0 0.268978], text=[" "; " "; " "]);
	bar(T, color=:rainbow, figsize=(14,8), title="Colored bars", Vd=dbg2)
	T = mat2ds([1.0 0.446143 0; 2.0 0.581746 0; 3.0 0.268978 0], text=[" "; " "; " "]);
	bar(T, color=:rainbow, figsize=(14,8), mz=[3 2 1], Vd=dbg2)
	bar(1:5, (20, 35, 30, 35, 27), width=0.35, color=:lightblue,limits=(0.5,5.5,0,40),E=(y=(2,3,4,1,2),), Vd=dbg2)
	bar([0. 1 2 3; 1 2 3 4], stack=true, hbar=true, fill=["red", "green", "blue"])
	bar(0:3, [2.9, 5, 2.2, 1], fill=["red", "green", "blue", "orange"], Vd=dbg2)
	D = mat2ds([0 0],["aa"]);
	#sprint(print, D);

	println("	BAR3")
	G = gmt("grdmath -R-15/15/-15/15 -I1 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
	gmtwrite("lixo.grd", G)
	bar3(G, lw=:thinnest)
	bar3("lixo.grd", grd=true, lw=:thinnest, Vd=dbg2)
	bar3!(G, lw=:thinnest, Vd=dbg2)
	bar3!("", G, lw=:thinnest, Vd=dbg2)
	bar3(G, lw=:thinnest, bar=(width=0.085,), Vd=dbg2)
	bar3(G, lw=:thinnest, nbands=3, Vd=dbg2)
	bar3(G, region="-15/15/-15/15/-2/2", lw=:thinnest, noshade=1, Vd=dbg2)
	bar3(rand(4,4), Vd=dbg2)
	D = grd2xyz(G);
	bar3(D, width=0.01, Nbands=3, Vd=dbg2)
	@test_throws ErrorException("BAR3: When first arg is a name, must also state its type. e.g. grd=true or dataset=true") bar3("lixo.grd")
	gmtwrite("lixo.gmt", D);	# This one is going to used in test_misc.jl
	gmtwrite("lixo.xyz", D);
	grdconvert("lixo.xyz");		# Read it back with GDAL
	@test_throws ErrorException("BAR3: When NOT providing *width* data must contain at least 5 columns.") bar3("lixo.xyz", dataset=true)
	rm("lixo.xyz")