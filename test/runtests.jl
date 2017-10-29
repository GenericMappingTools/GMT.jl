using GMT
using Base.Test

# write your own tests here
r = gmt("gmtinfo -C",ones(Float32,9,3)*5);
assert(r[1].data == [5.0 5 5 5 5 5])
r = gmtinfo(ones(Float32,9,3)*5, C=true);
assert(r[1].data == [5.0 5 5 5 5 5])
#
G=gmt("grdmath -R0/10/0/10 -I1 5");
r=gmt("grdinfo -C", G);
assert(r[1].data == [0.0  10.0  0.0  10.0  5.0  5.0  1.0  1.0  11.0  11.0])
#
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
pscoast(R=[-10 1 36 45], J="M12c", B="a", shore=1, E=("PT",(10,"green")), fmt="ps");
pscoast(R=[-10 1 36 45], J="M12c", B="a", shore=1, E=(("PT",(20,"green"),"+gcyan"),("ES","+gblue")), fmt="ps");
pscoast(R=[-10 1 36 45], J="M", B="a", shore=1,  E="PT,+gblue", fmt="ps");

#
# Just create the figs but not check if they are correct.
PS = grdimage(G, J="X10", ps=1);
PS = grdview(G, J="X6i", JZ=5,  Q="s", C="topo", R="-15/15/-15/15/-1/1", view="120/30", ps=1);
#
G = surface(rand(100,3) * 150, R="0/150/0/150", I=1, Ll=-100, upper=100);
assert(size(G.z) == (151, 151))
#
plot(collect(1:10),rand(10), lw=1, lc="blue", fmt="ps", marker="circle", markeredgecolor=0, size=0.2, markerfacecolor="red", title="Bla Bla", x_label="Spoons", y_label="Forks")
plot!(collect(1:10),rand(10), fmt="ps")
#
pscoast(R="-10/0/35/45", J="M12c", W=(0.5,"red"), fmt="ps", B="a", N=(1,(1,"green")))
#
C = makecpt(T="-200/1000/100", C="rainbow");
psscale(C=C, D="x8c/1c+w12c/0.5c+jTC+h", B="xaf+l\"topography\" y+lkm", fmt="ps")

# PSTEXT
pstext(text_record("TopLeft"), R="1/10/1/10", J="X10", F="+cTL",fmt="ps")

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