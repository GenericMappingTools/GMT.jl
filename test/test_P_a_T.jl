println("	PROJECT")
project(C="15/15", T="85/40", G="1/110", L="-20/60");	# Fails in GMT5
project(nothing, C="15/15", T="85/40", G="1/110", L="-20/60");	# bit of cheating

println("	SAMPLE1D")
d = [-5 74; 38 68; 42 73; 43 76; 44 73];
sample1d(d, T="2c", A=:r);
@test sample1d([0 0], F=:akima, Vd=2) == "sample1d  -Fa"
@test sample1d([0 0], F="sp0.1+d2", Vd=2) == "sample1d  -Fsp0.1+d2"
@test sample1d([0 0], F="smoothp0.1+d2", Vd=2) == "sample1d  -Fsp0.1+d2"
@test sample1d([0 0], F="cubic+d1", Vd=2) == "sample1d  -Fc+d1"
@test sample1d([0 0], F=(:akima, "first"), Vd=2) == "sample1d  -Fa+d1"
@test sample1d([0 0], F=(:smothing, 0.1), Vd=2) == "sample1d  -Fsp0.1"
@test sample1d([0 0], F=(:smothing, 0.1, :seconf), Vd=2) == "sample1d  -Fsp0.1+d2"

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

println("	SPLITXYZ")
# SPLITXYZ (fails?)
gmtsplit([-14.0708 35.0730 0; -13.7546 35.5223 0; -13.7546 35.5223 0; -13.2886 35.7720 0; -13.2886 35.7720 0; -12.9391 36.3711 0], C=45, A="45/15", f="g", Vd=dbg2)

println("	TRIANGULATE")
G = triangulate(rand(100,3) * 150, R="0/150/0/150", I=1);
triangulate(rand(5,3), R="0/150/0/150", voronoi=:pol, Vd=dbg2);

println("	TRIPLOT")
xy = rand(7,2);
triplot(xy, voronoi=1, lc=:blue, onlyedges=true, region=(0,1,0,1))
triplot!(xy, lc=:red)
pts = [[1 2 3;1 2 3;1 2 3][:] [1 1 1;2 2 2; 3 3 3][:]]
D = triplot(pts, noplot=true);
@test inwhichpolygon(D, [2.4 1.2; 1.4 1.4]) == [5,1]

println("	NEARNEIGHBOR")
G = nearneighbor(rand(100,3) * 150, R="0/150/0/150", I=1, N=4, S=10, r=true);

println("	XYZ2GRD")
D=grd2xyz(G); # Use G of previous test
xyz2grd(D, R="0/150/0/150", I=1, r=true);
xyz2grd(D, xlim=(0,150), ylim=(0,150), I=1, r=true);
xyz2grd(x=[0,1,2], y=[0,1,2], z=[0,1,2], R="0/2/0/2", I=1);

println("	TREND1D")
D = gmt("gmtmath -T10/110/1 T 50 DIV 2 POW 2 MUL T 60 DIV ADD 4 ADD 0 0.25 NRAND ADD T 25 DIV 2 MUL PI MUL COS 2 MUL 2 ADD ADD");
trend1d(D, N="p2,F1+o0+l25", F=:xm);

println("	TREND2D")
trend2d(D, F=:xyr, N=3);