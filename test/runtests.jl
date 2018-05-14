using GMT
using Test
using LinearAlgebra

# write your own tests here
r = gmt("gmtinfo -C",ones(Float32,9,3)*5);
@assert(r[1].data == [5.0 5 5 5 5 5])
r = gmtinfo(ones(Float32,9,3)*5, C=true, V=:q);
@assert(r[1].data == [5.0 5 5 5 5 5])

# BLOCK*s
d = [0.1 1.5 1; 0.5 1.5 2; 0.9 1.5 3; 0.1 0.5 4; 0.5 0.5 5; 0.9 0.5 6; 1.1 1.5 7; 1.5 1.5 8; 1.9 1.5 9; 1.1 0.5 10; 1.5 0.5 11; 1.9 0.5 12];
G = blockmedian(region=[0 2 0 2], inc=1, fields="z", reg=1, d);
if (G != nothing)	# If run from GMT5 it will return nothing
	G = blockmean(d, region=[0 2 0 2], inc=1, grid=true, reg=1, S=:n);	# Number of points in cell
	G,L = blockmode(region=[0 2 0 2], inc=1, fields="z,l", reg=1, d);
end

# GRDINFO
G=gmt("grdmath -R0/10/0/10 -I1 5");
r=gmt("grdinfo -C", G);
@assert(r[1].data == [0.0  10.0  0.0  10.0  5.0  5.0  1.0  1.0  11.0  11.0])
r2=grdinfo(G, C=true, V=true);
@assert(r[1].data == r2[1].data)

# MAKECPT
cpt = makecpt(range="-1/1/0.1");
@assert((size(cpt.colormap,1) == 20) && (cpt.colormap[1,:] == [0.875, 0.0, 1.0]))

# GRDCONTOUR
G = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
C = grdcontour(G, C="+0.7", D=[]);
@assert((size(C[1].data,1) == 21) && norm(-0.6 - C[1].data[1,1]) < 1e-8)
# Do the same but write the file on disk first
gmt("write -Tg lixo.grd", G)
GG = gmt("read -Tg lixo.grd");
C = grdcontour("lixo.grd", C="+0.7", D=[]);
@assert((size(C[1].data,1) == 21) && norm(-0.6 - C[1].data[1,1]) < 1e-8)
x,y,z=GMT.peaks()
G = gmt("surface -R-3/3/-3/3 -I0.1", [x[:] y[:] z[:]]);
cpt = makecpt(T="-6/8/1");
grdcontour(G, frame="a", fmt="png", color=cpt, pen="+c", X=1, Y=1, U=[])

# GRDTRACK
G = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
D = grdtrack([0 0], G);
@assert(D[1].data == [0.0 0 1])
D = grdtrack(G, [0 0]);
D = grdtrack([0 0], G=G);
@assert(D[1].data == [0.0 0 1])

# Just create the figs but not check if they are correct.
PS = grdimage(G, J="X10", ps=1);
gmt("destroy")
PS = grdview(G, J="X6i", JZ=5,  Q="s", C="topo", R="-15/15/-15/15/-1/1", view="120/30", ps=1);
gmt("destroy")

# IMSHOW
imshow(rand(128,128),show=false)
imshow(G, frame=:a, shade="+a45",show=false)

# SURFACE
G = surface(rand(100,3) * 150, R="0/150/0/150", I=1, Ll=-100, upper=100);
@assert(size(G.z) == (151, 151))

# PLOT
plot(collect(1:10),rand(10), lw=1, lc="blue", fmt=:ps, marker="circle", markeredgecolor=0, size=0.2, markerfacecolor="red", title="Bla Bla", x_label="Spoons", y_label="Forks")
plot!(collect(1:10),rand(10), fmt="ps")

# PSBASEMAP
basemap(region="0/100/0/5000", proj="x1p0.5/-0.001", B="x1p+l\"Crustal age\" y500+lDepth")

# PSCONVERT
#gmt("psbasemap -R-10/0/35/45 -Ba -P -JX10d > lixo.ps")
#psconvert("lixo.ps", adjust=true, fmt="eps", Z=true)

# PSCOAST
coast(R=[-10 1 36 45], J=:M12c, B="a", shore=1, E=("PT",(10,"green")), D=:c, fmt="ps");
coast(R=[-10 1 36 45], J="M12c", B="a", shore=1, E=(("PT",(20,"green"),"+gcyan"),("ES","+gblue")), fmt="ps");
coast(R=[-10 1 36 45], J="M", B="a", shore=1,  E="PT,+gblue", fmt="ps", borders="a", rivers="a");
coast(R="-10/0/35/45", J="M12c", W=(0.5,"red"), fmt="ps", B="a", N=(1,(1,"green")))

# PSIMAGE
#gmt("psbasemap -R-10/0/35/45 -Ba -P -JX10d > lixo.ps")

# PSSCALE
C = makecpt(T="-200/1000/100", C="rainbow");
colorbar(C=C, D="x8c/1c+w12c/0.5c+jTC+h", B="xaf+l\"topography\" y+lkm", fmt="ps")

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

# SPLITXYZ (fails)
#splitxyz([-14.0708 35.0730 0; -13.7546 35.5223 0; -13.7546 35.5223 0; -13.2886 35.7720 0; -13.2886 35.7720 0; -12.9391 36.3711 0], C=45, A="45/15", f="g")

# TRIANGULATE
G = triangulate(rand(100,3) * 150, R="0/150/0/150", I=1, grid=[]);

# NEARNEIGHBOR
G = nearneighbor(rand(100,3) * 150, R="0/150/0/150", I=1, N=4, grid=[], S=10);

# EXAMPLES
plot(collect(1:10),rand(10), lw=1, lc="blue", marker="square",
markeredgecolor=0, size=0.2, markerfacecolor="red", title="Hello World",
x_label="Spoons", y_label="Forks")

x = range(0, stop=2pi, length=180);	seno = sin.(x/0.2)*45;
coast(region="g", proj="A300/30/6c", frame="g", resolution="c", land="navy")
plot!(collect(x)*60, seno, lw=0.5, lc="red", marker="circle",
	markeredgecolor=0, size=0.05, markerfacecolor="cyan")

x,y,z=GMT.peaks()
G = gmt("surface -R-3/3/-3/3 -I0.1", [x[:] y[:] z[:]]);  # Iterpolate into a regular grid
grdcontour(G, cont=1, annot=2, frame="a")
cpt = makecpt(T="-6/8/1");      # Create the color map
grdcontour(G, frame="a", color=cpt, pen="+c")

function testa_conf(;kw...)
	d = GMT.KW(kw)
	cmd = GMT.parse_gmtconf_MAP("", d)
	cmd = GMT.parse_gmtconf_FONT(cmd, d)
	cmd = GMT.parse_gmtconf_FORMAT(cmd, d)
	cmd = GMT.parse_gmtconf_TIME(cmd, d)
	return nothing
end
testa_conf(MAP_ANNOT_MIN_ANGLE=:a,MAP_ANNOT_MIN_SPACING=:a,MAP_ANNOT_OBLIQUE=:a,MAP_ANNOT_OFFSET_PRIMARY=:a, 
MAP_ANNOT_OFFSET=:a, MAP_ANNOT_OFFSET_SECONDARY=:a, MAP_ANNOT_ORTHO=:a, MAP_DEFAULT_PEN=:a,
MAP_DEGREE_SYMBOL=:a, MAP_TICK_LENGTH=:a, MAP_TICK_PEN=:a,
MAP_FRAME_AXES=:a, MAP_FRAME_PEN=:a, MAP_FRAME_TYPE=:a, MAP_FRAME_WIDTH=:a, MAP_GRID_CROSS_SIZE_PRIMARY=:a, 
MAP_GRID_CROSS_SIZE_SECONDARY=:a, MAP_GRID_PEN_PRIMARY=:a, MAP_GRID_PEN_SECONDARY=:a, MAP_HEADING_OFFSET=:a, 
MAP_LABEL_OFFSET=:a, MAP_LINE_STEP=:a, MAP_LOGO=:a, MAP_LOGO_POS=:a, MAP_ORIGIN_X=:a, MAP_ORIGIN_Y=:a, 
MAP_POLAR_CAP=:a, MAP_SCALE_HEIGHT=:a, MAP_TICK_LENGTH_PRIMARY=:a, MAP_TICK_LENGTH_SECONDARY=:a, 
MAP_TICK_PEN_PRIMARY=:a, MAP_TICK_PEN_SECONDARY=:a, MAP_TITLE_OFFSET=:a, MAP_VECTOR_SHAPE=:a,
MAP_GRID_CROSS_SIZE=:a, MAP_GRID_CROSS_PEN=:a);

testa_conf(FONT_ANNOT_PRIMARY=:a, FONT_ANNOT_SECONDARY=:a, FONT_HEADING=:a, FONT_LABEL=:a, FONT_LOGO=:a,
FONT_TAG=:a, FONT_TITLE=:a, FORMAT_CLOCK_IN=:a, FORMAT_CLOCK_OUT=:a, FORMAT_CLOCK_MAP=:a, FORMAT_DATE_IN=:a,
FORMAT_DATE_OUT=:a, FORMAT_DATE_MAP=:a, FORMAT_GEO_OUT=:a, FORMAT_GEO_MAP=:a, FORMAT_FLOAT_OUT=:a,
FORMAT_FLOAT_MAP=:a, FORMAT_TIME_PRIMARY_MAP=:a, FORMAT_TIME_SECONDARY_MAP=:a, FORMAT_TIME_STAMP =:a,
FONT=:a, FONT_ANNOT=:a, FORMAT_TIME_MAP=:a);

testa_conf(TIME_EPOCH=:a, TIME_IS_INTERVAL=:a, TIME_INTERVAL_FRACTION=:a, TIME_LEAP_SECONDS=:a,
TIME_REPORT=:a, TIME_UNIT=:a, TIME_WEEK_START=:a, TIME_Y2K_OFFSET_YEAR=:a, TIME_SYSTEM=:a);