println("	PROJECT")
project(C="15/15", T="85/40", G="1/110", L="-20/60");	# Fails in GMT5
project(nothing, C="15/15", T="85/40", G="1/110", L="-20/60");	# bit of cheating

println("	SAMPLE1D")
d = [-5 74; 38 68; 42 73; 43 76; 44 73];
sample1d(d, T="2c", A=:r);	

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
splitxyz([-14.0708 35.0730 0; -13.7546 35.5223 0; -13.7546 35.5223 0; -13.2886 35.7720 0; -13.2886 35.7720 0; -12.9391 36.3711 0], C=45, A="45/15", f="g", Vd=dbg2)

println("	TRIANGULATE")
G = triangulate(rand(100,3) * 150, R="0/150/0/150", I=1, grid=[]);
triangulate(rand(5,3), R="0/150/0/150", voronoi=:pol, Vd=dbg2);

println("	NEARNEIGHBOR")
G = nearneighbor(rand(100,3) * 150, R="0/150/0/150", I=1, N=4, S=10, r=true);

println("	XYZ2GRD")
D=grd2xyz(G); # Use G of previous test
xyz2grd(D, R="0/150/0/150", I=1, r=true);
xyz2grd(D, xlim=(0,150), ylim=(0,150), I=1, r=true);

println("	TREND1D")
D = gmt("gmtmath -T10/110/1 T 50 DIV 2 POW 2 MUL T 60 DIV ADD 4 ADD 0 0.25 NRAND ADD T 25 DIV 2 MUL PI MUL COS 2 MUL 2 ADD ADD");
trend1d(D, N="p2,F1+o0+l25", F=:xm);

println("	TREND2D")
trend2d(D, F=:xyr, N=3);