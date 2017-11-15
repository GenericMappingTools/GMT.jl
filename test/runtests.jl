using GMT
using Base.Test

# write your own tests here
r = gmt("gmtinfo -C",ones(Float32,9,3)*5);
assert(r[1].data == [5.0 5 5 5 5 5])
r = gmtinfo(ones(Float32,9,3)*5, C=true);
assert(r[1].data == [5.0 5 5 5 5 5])
#
# GRDINFO
G=gmt("grdmath -R0/10/0/10 -I1 5");
r=gmt("grdinfo -C", G);
assert(r[1].data == [0.0  10.0  0.0  10.0  5.0  5.0  1.0  1.0  11.0  11.0])
r2=grdinfo(G, C=true);
assert(r[1].data == r2[1].data)
#
# MAKECPT
cpt = makecpt(range="-1/1/0.1");
assert((size(cpt.colormap,1) == 20) && (cpt.colormap[1,:] == [0.875, 0.0, 1.0]))

# GRDCONTOUR
G = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
C = grdcontour(G, C="+0.7", D=[]);
assert((size(C[1].data,1) == 21) && norm(-0.6 - C[1].data[1,1]) < 1e-8)
# Do the same but write the file on disk first
gmt("write -Tg lixo.grd", G)
GG = gmt("read -Tg lixo.grd");
C = grdcontour("lixo.grd", C="+0.7", D=[]);
assert((size(C[1].data,1) == 21) && norm(-0.6 - C[1].data[1,1]) < 1e-8)
x,y,z=GMT.peaks()
G = gmt("surface -R-3/3/-3/3 -I0.1", [x[:] y[:] z[:]]);
cpt = makecpt(T="-6/8/1");
grdcontour(G, frame="a", fmt="png", color=cpt, pen="+c", X=1, Y=1, U=[])

# GRDTRACK
G = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
D = grdtrack([0 0], G);
assert(D[1].data == [0.0 0 1])
D = grdtrack(G, [0 0]);
D = grdtrack([0 0], G=G);
assert(D[1].data == [0.0 0 1])

# Just create the figs but not check if they are correct.
PS = grdimage(G, J="X10", ps=1);
PS = grdview(G, J="X6i", JZ=5,  Q="s", C="topo", R="-15/15/-15/15/-1/1", view="120/30", ps=1);

# IMSHOW
imshow(rand(128,128),show=false)
imshow(G, frame="a", shade="+a45",show=false)

#
G = surface(rand(100,3) * 150, R="0/150/0/150", I=1, Ll=-100, upper=100);
assert(size(G.z) == (151, 151))

# PLOT
plot(collect(1:10),rand(10), lw=1, lc="blue", fmt="ps", marker="circle", markeredgecolor=0, size=0.2, markerfacecolor="red", title="Bla Bla", x_label="Spoons", y_label="Forks")
plot!(collect(1:10),rand(10), fmt="ps")

# PSBASEMAP
basemap(region="0/100/0/5000", proj="x1p0.5/-0.001", B="x1p+l\"Crustal age\" y500+lDepth")

# PSCOAST
coast(R=[-10 1 36 45], J="M12c", B="a", shore=1, E=("PT",(10,"green")), fmt="ps");
coast(R=[-10 1 36 45], J="M12c", B="a", shore=1, E=(("PT",(20,"green"),"+gcyan"),("ES","+gblue")), fmt="ps");
coast(R=[-10 1 36 45], J="M", B="a", shore=1,  E="PT,+gblue", fmt="ps", borders="a", rivers="a");
coast(R="-10/0/35/45", J="M12c", W=(0.5,"red"), fmt="ps", B="a", N=(1,(1,"green")))

# PSSCALE
C = makecpt(T="-200/1000/100", C="rainbow");
scale(C=C, D="x8c/1c+w12c/0.5c+jTC+h", B="xaf+l\"topography\" y+lkm", fmt="ps")

# PSHISTOGRAM
histogram(randn(1000),W=0.1,center=true,fmt="ps",B="a",N=0, x_offset=1, y_offset=1, stamp=[])

# PSROSE
data=[20 5.4 5.4 2.4 1.2; 40 2.2 2.2 0.8 0.7; 60 1.4 1.4 0.7 0.7; 80 1.1 1.1 0.6 0.6; 100 1.2 1.2 0.7 0.7; 120 2.6 2.2 1.2 0.7; 140 8.9 7.6 4.5 0.9; 160 10.6 9.3 5.4 1.1; 180 8.2 6.2 4.2 1.1; 200 4.9 4.1 2.5 1.5; 220 4 3.7 2.2 1.5; 240 3 3 1.7 1.5; 260 2.2 2.2 1.3 1.2; 280 2.1 2.1 1.4 1.3;; 300 2.5 2.5 1.4 1.2; 320 5.5 5.3 2.5 1.2; 340 17.3 15 8.8 1.4; 360 25 14.2 7.5 1.3];
rose(data, swap_xy=[], A=20, R="0/25/0/360", B="xa10g10 ya10g10 +t\"Sector Diagram\"", W=1, G="orange", F=1, D=1, S=4)

# PSSOLAR
#D=solar(I="-7.93/37.079+d2016-02-04T10:01:00");
#assert(D[1].text[end] == "\tDuration = 10:27")
solar(R="d", W=1, J="Q0/14c", B="a", T="dc")

# PSTEXT
text(text_record("TopLeft"), R="1/10/1/10", J="X10", F="+cTL",fmt="ps")

# GMTSPATIAL
# Test  Cartesian centroid and area
result = gmt("gmtspatial -Q", [0 0; 1 0; 1 1; 0 1; 0 0]);
assert(isapprox(result[1].data, [0.5 0.5 1]))
# Test Geographic centroid and area
result = gmt("gmtspatial -Q -fg", [0 0; 1 0; 1 1; 0 1; 0 0]);
assert(isapprox(result[1].data, [0.5 0.500019546308 12308.3096995]))
# Intersections
l1 = gmt("project -C22/49 -E-60/-20 -G10 -Q");
l2 = gmt("project -C0/-60 -E-60/-30 -G10 -Q");
#int = gmt("gmtspatial -Ie -Fl", l1, l2);       # Error returned from GMT API: GMT_ONLY_ONE_ALLOWED (59)

# TRIANGULATE
G = triangulate(rand(100,3) * 150, R="0/150/0/150", I=1, grid=[]);

# NEARNEIGHBOR
G = nearneighbor(rand(100,3) * 150, R="0/150/0/150", I=1, N=4, grid=[], S=10);

# EXAMPLES
plot(collect(1:10),rand(10), lw=1, lc="blue", marker="square",
markeredgecolor=0, size=0.2, markerfacecolor="red", title="Hello World",
x_label="Spoons", y_label="Forks")

x = linspace(0, 2pi,180); seno = sin.(x/0.2)*45;
coast(region="g", proj="A300/30/6c", frame="g", resolution="c", land="navy")
plot!(collect(x)*60, seno, lw=0.5, lc="red", marker="circle",
      markeredgecolor=0, size=0.05, markerfacecolor="cyan")

x,y,z=GMT.peaks()
G = gmt("surface -R-3/3/-3/3 -I0.1", [x[:] y[:] z[:]]);  # Iterpolate into a regular grid
grdcontour(G, cont=1, annot=2, frame="a")
cpt = makecpt(T="-6/8/1");      # Create the color map
grdcontour(G, frame="a", color=cpt, pen="+c")
