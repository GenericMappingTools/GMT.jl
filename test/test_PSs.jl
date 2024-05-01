println("	PSBASEMAP")
basemap(region="0/100/0/5000", proj="x1p0.5/-0.001", B="x1p+l\"Crustal age\" y500+lDepth")
basemap!(region="0/100/0/5000", proj="x1p0.5/-0.001", B="x1p+l\"Crustal age\" y500+lDepth", Vd=dbg2)
basemap!(region="0/100/0/5000", proj="x1p0.5/-0.001", B="x1p+l\"Crustal age\" y500+lDepth", Vd=dbg2)
basemap(region="416/542/0/6.2831852", proj="X-12/6.5",
		axis=(axes=(:left_full, :bot_full), fill=:lightblue),
		xaxis=(annot=25, ticks=5, grid=25, suffix=" Ma"),
		xaxis2=(custom=(pos=[416.0; 443.7; 488.3; 542],
				type=["ig Devonian", "ig Silurian", "ig Ordovician", "ig Cambrian"]),),
		yaxis=(custom=(pos=[0 1 2 2.71828 3 3.1415926 4 5 6 6.2831852],
			   type=["a", "a", "f", "ag e", "f", "ag @~p@~", "f", "f", "f", "ag 2@~p@~"]),),
		par=(MAP_ANNOT_OFFSET_SECONDARY="10p", MAP_GRID_PEN_SECONDARY="2p"), Vd=dbg2)
basemap(region="416/542/0/6.2831852", proj="X-12/6.5", axis=(axes=(:left_full, :bot_full), fill=:lightblue), xaxis=(annot=25, ticks=5, grid=25, suffix=" Ma"), xaxis2=(customticks=([416.0; 443.7; 488.3; 542], ["/ig Devonian", "/ig Silurian", "/ig Ordovician", "/ig Cambrian"]),), yticks=([0 1 2 2.71828 3 3.1415926 4 5 6 6.2831852], ["/a", "/a", "/f", "/ag e", "/f", "/ag @~p@~", "/f", "/f", "/f", "/ag 2@~p@~"]), par=(MAP_ANNOT_OFFSET_SECONDARY="10p", MAP_GRID_PEN_SECONDARY="2p"), Vd=dbg2)
basemap(region=:PT, scatter=(data=[-15. 35], mc=:red), Vd=dbg2)
r = basemap(rose=(anchor="10:35/0.7", width=1, fancy=2, offset=0.4), Vd=dbg2);
@test startswith(r,"psbasemap  -JX" * split(GMT.DEF_FIG_SIZE, '/')[1] * "/0" * " -Baf -BWSen -Tdg10:35/0.7+w1+f2+o0.4")
r = basemap(rose=(norm=true, anchor=[0.5 0.7], width=1, fancy=2, offset=0.4), Vd=dbg2);
@test startswith(r,"psbasemap  -JX" * split(GMT.DEF_FIG_SIZE, '/')[1] * "/0" * " -Baf -BWSen -Tdn0.5/0.7+w1+f2+o0.4")
r = basemap(rose=(anchor=:TR, width=1, fancy=2, offset=0.4), Vd=dbg2);
@test startswith(r,"psbasemap  -JX" * split(GMT.DEF_FIG_SIZE, '/')[1] * "/0" * " -Baf -BWSen -TdjTR+w1+f2+o0.4")
r = basemap(rose=(anchor=:TR, width=1, fancy=2, offset=0.4), Vd=dbg2);
@test startswith(r,"psbasemap  -JX" * split(GMT.DEF_FIG_SIZE, '/')[1] * "/0" * " -Baf -BWSen -TdjTR+w1+f2+o0.4")
r = basemap(compass=(anchor=:TR, width=1, dec=-14, offset=0.4), Vd=dbg2);
@test startswith(r,"psbasemap  -JX" * split(GMT.DEF_FIG_SIZE, '/')[1] * "/0" * " -Baf -BWSen -TmjTR+w1+d-14+o0.4")
r = basemap(L=(anchor=:TR, length=1, align=:top, fancy=0.4), Vd=dbg2);
@test startswith(r,"psbasemap  -JX" * split(GMT.DEF_FIG_SIZE, '/')[1] * "/0" * " -Baf -BWSen -LjTR+w1+at+f")
@test startswith(basemap(frame=(annot=10, slanted=:p), Vd=dbg2), "psbasemap  -JX" * split(GMT.DEF_FIG_SIZE, '/')[1] * "/0" * " -Bpa10+ap")
r = basemap(region=(1,1000,0,1), proj=:logx, figsize=(8,0.7), frame=(annot=1, ticks=2, grid=3, scale=:pow), Vd=dbg2);
@test startswith(r, "psbasemap  -R1/1000/0/1 -JX8l/0.7 -Bpa1f2g3p")
r = basemap(region=(1,1000,0,1), proj=:logx, figsize=8, frame=(annot=1, ticks=2, scale=:pow), Vd=dbg2)
@test startswith(r, "psbasemap  -R1/1000/0/1 -JX8l -Bpa1f2p")
r = basemap(region=("0.2t","0.35t",0,1), figsize=(-12,0.25), frame=(axes=:S, annot="15m", ticks="5m"), axis2=(annot=1, annot_unit=:hour), conf=(FORMAT_CLOCK_MAP="-hham", FONT_ANNOT_PRIMARY="+9p", TIME_UNIT="d"), Vd=dbg2);
@test startswith(r, "psbasemap  -R0.2t/0.35t/0/1 -JX-12/0.25 -Bsa1H -Bpa15mf5m -BS --FORMAT_CLOCK_MAP=-hham")
@test_throws ErrorException("slanted option: Only 'parallel' is allowed for the y-axis") basemap(yaxis=(slanted=:o,), Vd=dbg2)

println("	PSCLIP")
d = [0.2 0.2; 0.2 0.8; 0.8 0.8; 0.8 0.2; 0.2 0.2];
psclip(d, J="X3i", R="0/1/0/1", N=true, V=:q);
psclip!(d, J="X3i", R="0/1/0/1", Vd=dbg2);
psclip!(d, J="X3i", R="0/1/0/1", Vd=dbg2);

println("	PSCONVERT")
gmt("psbasemap -R-10/0/35/45 -Ba -P -JX10d -Vq > lixo.ps")
psconvert("lixo.ps", adjust=true, fmt="eps", C="-dDOINTERPOLATE")
psconvert("lixo.ps", adjust=true, fmt="eps", C=["-dDOINTERPOLATE" "-dDOINTERPOLATE"])
psconvert("lixo.ps", adjust=true, fmt="tif")
psconvert("lixo.ps", adjust=true, Vd=dbg2)
P = gmtread("lixo.ps", ps=true);
gmtwrite("lixo.ps", P)
psconvert(P, adjust=true, in_memory=true, Vd=dbg2)
gmt("psconvert -Tf lixo.ps");
gmt("psconvert -A lixo.ps");
gmt("write lixo.ps", P)		# Test also this case in gmt_main

println("	PSCOAST")
coast(R=[-10 1 36 45], J=:M12c, B="a", shore=1, E=("PT",(10,"green")), D=:c, borders="1/0.5p")
coast(R=[-10 1 36 45], J="M12c", B="a", shore=1, E=(("PT",(20,"green"),"+gcyan"),("ES","+gblue")), fmt="ps")
coast(R=[-10 1 36 45], J="M12c", B="a", E=("PT", (0.5,"red","--"), "+gblue"), Vd=dbg2)
coast(R=[-10 1 36 45], J="M", B="a", E="PT,+gblue", borders="a", rivers="a", Vd=dbg2)
coast(R="-10/0/35/45", J="M12c", W=(0.5,"red"), B=:a, N=(type=1,pen=(1,"green")), water=:blue, clip=:land, Vd=dbg2)
coast!(R="-10/0/35/45", J="M12c", W=(0.5,"red"), B=:a, N=(type=1,pen=(1,"green")), clip=:stop, rivers="1/0.5p", Vd=dbg2)
coast(region=(continent=:AN,), Vd=dbg2);
coast(region="-10/36/-7/41+r", proj=:guess);
GMT.GMT_Get_Common(GMT.G_API[1], 'R');
@test GMT.parse_dcw("", ((country=:PT, pen=(2,:red), fill=:blue), (country=:ES, pen=(2,:blue)) )) == " -EPT+p2,red+gblue -EES+p2,blue"
r = coast(region=:g, proj=(name=:Gnomonic, center=(-120,35), horizon=60), frame=(annot=30, grid=15), res=:crude, area=10000, land=:tan, ocean=:cyan, shore=:thinnest, figsize=10, Vd=dbg2);
@test startswith(r, "pscoast  -Rg -JF-120/35/60/10 -Bpa30g15 -BWSen -A10000 -Dcrude -Gtan -Scyan -Wthinnest")
r = coast(region=:g, proj="A300/30/14c", axis=:g, resolution=:crude, title="Hello Round World", Vd=dbg2);
@test startswith(r, "pscoast  -Rg -JA300/30/14c -Bg -B+t\"Hello Round World\" -Dcrude")
@test startswith(coast(R=:g, W=(level=1,pen=(2,:green)), Vd=dbg2), "pscoast  -Rg -JN180.0/" * split(GMT.DEF_FIG_SIZE, '/')[1] * " -Baf -BWSen -W1/2,green")
@test startswith(coast(R=:g, W=(2,:green), Vd=dbg2), "pscoast  -Rg -JN180.0/" * split(GMT.DEF_FIG_SIZE, '/')[1] * " -Baf -BWSen -W2,green")
r = coast(R=:g, N=((level=1,pen=(2,:green)), (level=3,pen=(4,:blue, "--"))), Vd=dbg2);
@test startswith(r, "pscoast  -Rg -JN180.0/" * split(GMT.DEF_FIG_SIZE, '/')[1] * " -Baf -BWSen -N1/2,green -N3/4,blue,--")
r = coast(proj=:Mercator, DCW=((country="GB,IT,FR", fill=:blue, pen=(0.25,:red)), (country="ES,PT,GR", fill=:yellow)), Vd=dbg2);
@test startswith(r, "pscoast  -EGB,IT,FR+gblue+p0.25,red -EES,PT,GR+gyellow -Vq")
@test_throws ErrorException("In Overlay mode you cannot change a fig scale and NOT repeat the projection") coast!(region=(-20,60,-90,90), scale=0.03333, Vd=dbg2)
r = coast(DCW=(:AT, "red"), Vd=dbg2)
@test startswith(r, "pscoast  -EAT+gred")
@test coast(getR=:PTC, Vd=0) == "-R-9.56/-6.18/36.955/42.16"

println("	PSCONTOUR")
x,y,z=GMT.peaks(grid=false);
contour([x[:] y[:] z[:]], cont=1, annot=2, axis="a")
contour([x[:] y[:] z[:]], I=true, axis="a", Vd=dbg2)
contour!([x[:] y[:] z[:]], cont=1, Vd=dbg2)
contour!([x[:] y[:] z[:]], cont=1, E="lixo", Vd=dbg2)	# Cheating E opt because Vd=dbg2 prevents its usage
contour!([x[:] y[:] z[:]], cont=1, Vd=dbg2)
D = contour([x[:] y[:] z[:]], cont=[1,3,5], dump=true);
contour([x[:] y[:] z[:]],cont=[-2,0,3], Vd=dbg2)
#@test_throws ErrorException("fill option rquires passing a CPT") contour(rand(5,2),cont=[-2,0,3], I=true)

println("	PSIMAGE")
psimage("lixo.png", D="x0.5c/0.5c+jBL+w6c", R="0/1/0/1", J=:X7)
psimage!("lixo.png", D="x0.5c/0.5c+jBL+w6c", R="0/1/0/1", J=:X7, Vd=dbg2)
image("@vader1.png", bit_bg=:darkgray, bit_fg=:yellow, Vd=dbg2)

println("	PSSCALE")
C = makecpt(T="-200/1000/100", C="rainbow");
colorbar(C=C, D="x8c/1c+w12c/0.5c+jTC+h", B="xaf+l\"topography\" y+lkm", fmt="ps", par=(MAP_FRAME_WIDTH=0.2,))
colorbar!(C=C, D="x8c/1c+w12c/0.5c+jTC+h", B="xaf+l\"topography\" y+lkm", Vd=dbg2)
colorbar(C, D="x8c/1c+w12c/0.5c+jTC+h", B="xaf+l\"topography\" y+lkm", Vd=dbg2)
colorbar!(C, D="x8c/1c+w12c/0.5c+jTC+h", B="xaf+l\"topography\" y+lkm", Vd=dbg2)

println("	PSHISTOGRAM")
histogram(randn(1000),T=0.1,center=true,B=:a,N=0, x_offset=1, y_offset=1, timestamp=[], t=50)
histogram(randn(100),T=0.1,center=true, Z=:counts, Vd=dbg2)
histogram!(randn(1000),T=0.1,center=true,N="1+p0.5", Vd=dbg2)
histogram!(randn(1000),T=0.1,center=true,N=(mode=1,pen=(1,:red)), Vd=dbg2)
I = mat2img(rand(UInt8,4,4));
histogram(I, Vd=dbg2);
histogram(I, I=:o);
GMT.histogray(I);
#I16 = mat2img(UInt16.([0 1 3 4; 5 6 7 8; 0 1 10 11]),noconv=1);
I16 = mat2img(rand(UInt16,8,8),noconv=1);
histogram(I16, auto=true);
histogram(I16, zoom=true, Vd=dbg2);
histogram(I16, S=1, Vd=dbg2);
histogram(I16, I=:O);
histogram(rand(UInt8, 4,4,3))
G = GMT.peaks();
histogram(G, zoom=true, Vd=dbg2);
histogram(G, T=0.3, Vd=dbg2);
histogram(rand(10), Vd=dbg2);
histogram(collect(Dates.DateTime(Dates.now()):Dates.Month(6):Dates.DateTime(Dates.now() + Dates.Year(20))))
@test_throws ErrorException("Unknown BinMethod lala") histogram(rand(100), binmethod="lala")

println("	PSLEGEND")
T = text_record(["P", "T d = [0 0; 1 1; 2 1; 3 0.5; 2 0.25]"]);
legend(T, R="-3/3/-3/3", J=:X12,  D="g-1.8/2.6+w12c+jTL", F="+p+ggray")
legend!(T, R="-3/3/-3/3", J=:X12, D="g-1.8/2.6+w12c+jTL", Vd=dbg2)
legend!("", T, R="-3/3/-3/3", J=:X12, D="g-1.8/2.6+w12c+jTL", Vd=dbg2)
@test GMT.mk_legend(gap="-0.1i")[1] == "G -0.1i"
@test GMT.mk_legend(header=(text="My Legend", font=(24,"Times-Roman")))[1] == "H 24,Times-Roman My Legend"
@test GMT.mk_legend(hline=(pen=1, offset="0.2i"))[1] == "D 0.2i 1"
@test GMT.mk_legend(ncolumns=2, vline=(pen=1, offset=0)) == ["N 2", "V 0 1"]
@test GMT.mk_legend(symbol=(marker=:circ, size="0.15i", dx_left="0.1i", fill="p300/12", dx_right="0.3i", text="This circle"))[1] == "S 0.1i c 0.15i p300/12 - 0.3i This circle"
@test GMT.mk_legend(hline2=(pen=1, offset="0.2i"), map_scale=(x=5,y=5,length="600+u+f")) == ["D 0.2i 1", "M 5 5 600+u+f"]
@test GMT.mk_legend(image=(width="3i", fname="@SOEST_block4.png",justify=:CT))[1] == "I @SOEST_block4.png 3i CT"
@test GMT.mk_legend(label=(txt="Smith al., @%5%J. 99@%%", justify=:R, font=(9, "Times-Roman")))[1] == "L 9,Times-Roman R Smith al., @%5%J. 99@%%"
@test GMT.mk_legend(text1="Let us just try")[1] == "T Let us just try"
@test GMT.mk_legend(colorbar=(name="tt.cpt", offset=0.5, height=0.5, extra="-B0"))[1] == "B tt.cpt 0.5 0.5 -B0"
@test GMT.mk_legend(textcolor=:red, fill=(c1=:blue, c2="100/30/200")) == ["C red", "F blue 100/30/200 "]
@test GMT.mk_legend((cmap="lixo", paragraph=true, popo=true)) == ["A lixo", "P "]
GMT.legend_help(true)
x = collect(1:10);
basemap(limits=(1,10,-1,1),figsize=(6,4),frame=:a)
lines!(x,sin.(x),legend="sin(x)")
legend!(fontsize=6,position=(inside="RT",width=1.5))

println("	PSROSE")
data=[20 5.4 5.4 2.4 1.2; 40 2.2 2.2 0.8 0.7; 60 1.4 1.4 0.7 0.7; 80 1.1 1.1 0.6 0.6; 100 1.2 1.2 0.7 0.7; 120 2.6 2.2 1.2 0.7; 140 8.9 7.6 4.5 0.9; 160 10.6 9.3 5.4 1.1; 180 8.2 6.2 4.2 1.1; 200 4.9 4.1 2.5 1.5; 220 4 3.7 2.2 1.5; 240 3 3 1.7 1.5; 260 2.2 2.2 1.3 1.2; 280 2.1 2.1 1.4 1.3; 300 2.5 2.5 1.4 1.2; 320 5.5 5.3 2.5 1.2; 340 17.3 15 8.8 1.4; 360 25 14.2 7.5 1.3];
rose(data, yx=true, A=20, R="0/25/0/360", B="xa10g10 ya10g10 +t\"Sector Diagram\"", W=1, G="orange", F=true, D=true, S=4)
rose!(data, yx=true, A=20, R="0/25/0/360", B="xa10g10 ya10g10", W=1, G="orange", D=true, S=4, Vd=dbg2)
rose(data, A=20, I=true);

println("	PSMASK")
D = gmtmath("-T-90/90/10 -N2/1 0");
mask(D, G=:yellow, I="30m", R="-75/75/-90/90", J="Q0/7i", S="4d", T=true, B="xafg180 yafg10")
mask!(D, G=:yellow, I="30m", R="-75/75/-90/90", J="Q0/7i", S="4d", T=true, Vd=dbg2)
mask!("", D, G=:yellow, I="30m", R="-75/75/-90/90", J="Q0/7i", S="4d", T=true, Vd=dbg2)
D = coast(DCW=:HR, dump=true);
I = gmtread("@earth_day_05m", region=D, V=:q);
mask(I, D);

println("	PSSOLAR")
#D=solar(I="-7.93/37.079+d2016-02-04T10:01:00");
#@assert(D[1].text[end] == "\tDuration = 10:27")
solar(R="d", W=1, J="Q0/14c", B="a", T="dc")
solar!(R="d", W=1, J="Q0/14c", T="dc", Vd=dbg2)
solar(sun=(date="2016-02-09T16:00:00",), format=true);
t = pssolar(sun=(date="2016-02-09T16:00:00",), format=true);

println("	PSTERNARY")
ternary([0.16 0.331 0.509 9.344], R="0/100/0/100/0/100", J="X6i", X=:c, B=:a, S="c0.1c");
ternary!([0.16 0.331 0.509 9.344], R="0/100/0/100/0/100", J="X6i", shape=:square, ms=0.1, markerline=1,Vd=dbg2);
ternary!("", [0.16 0.331 0.509 9.344], R="0/100/0/100/0/100", J="X6i", ms=0.1, lw=1,markeredgecolor=:red, Vd=dbg2);
d = [0.16 0.331 0.509 9.344; 0.86 0.11  0.027 7.812; 0.25 0.167 0.579 3.766; 0.5 0.339 0.161 15.203];
ternary(d, R="0/100/0/100/0/100", B="afg", contour=(annot=20, cont=10), clockwise=true)
ternary(d, R="0/100/0/100/0/100", B="afg", contourf=true)
ternary(d, R="0/100/0/100/0/100", B="afg", image=true, contour=true, Vd=dbg2)
ternary()
d = Dict(:a=>"", :frame => (annot=:a, grid=8, alabel=:a, blabel=:b, clabel=:c, suffix=" %"));
GMT.parse_B4ternary!(d);
@test d[:B] == " -Baag8+u\" %\"+la -Bbag8+u\" %\"+lb -Bcag8+u\" %\"+lc"
d = Dict(:a=>"", :labels => (:a, :b, :c));
GMT.parse_B4ternary!(d);
@test d[:B] == " -Baafg+la -Bbafg+lb -Bcafg+lc"

println("	PSTEXT")
text(text_record("TopLeft"), R="1/10/1/10", J="X10", F="+cTL",fmt="ps",savefig="lixo.ps")
text!(text_record("TopLeft"), R="1/10/1/10", J="X10", F="+cTL",Vd=dbg2)
text!("", text_record("TopLeft"), R="1/10/1/10", J="X10", F="+cTL",Vd=dbg2)
t = ["46p A Tale of Two Cities", "32p Dickens, Charles", "24p 1812-1973"];
pstext(text_record([3 8; 3 7; 3 6.4],t), R="0/6/0/9", J=:x1i, B=0, F="+f+jCM")
t = ["\tIt was the best of times, it was the worst of times, it was the age of wisdom, it was the age of,",
	"",
	"\tThere were a king with a large jaw and a queen with a plain face,"];
T = text_record(t,"> 3 5 18p 5i j");
pstext!(T, F="+f16p,Times-Roman,red+jTC", M=true)
pstext!(T, font=(16,"Times-Roman",:red), justify=:TC, M=true)
pstext!(["MERDA"], x=2.0, y=2.0, Vd=dbg2)
text(text="aiai", x=1, y=2.6, Vd=dbg2)
text(text=["aiai"], x=1, y=2.6, Vd=dbg2)
@test startswith(GMT.text([1 2 3; 4 5 6], Vd=dbg2), "pstext  -JX" * split(GMT.DEF_FIG_SIZE, '/')[1] * "/0" * " -Baf -BWSen -R0.9/4.1/1.9/5.1")
@test_throws ErrorException("TEXT: input file must have at least three columns") text([1 2; 4 5], Vd=dbg2)
text(rich("H", subscript("2"), greek("O")," is the ", smallcaps("formula")," for ", rich(underline("water"), color=:red, font=4, size=18)), x=1, y=1, Vd=dbg2)
@test superscript("4") == "@+4@+"
@test mathtex("4") == "@[4@["

println("	PSWIGGLE")
t=[0 7; 1 8; 8 3; 10 7];
t1=gmt("sample1d -I5k", t); t2 = gmt("mapproject -G+uk", t1); t3 = gmt("math ? -C2 10 DIV COS", t2);
wiggle(t3,R="-1/11/0/12", J="M8",B="af WSne", W="0.25p", Z="4c", G="+green", T="0.5p", A=1, Y="0.75i")
wiggle!(t3,R="-1/11/0/12", J="M8",Z="4c", A=1, Y="0.75i", S="8/1/2", Vd=dbg2)