G = gmt("grdmath -R-2/2/-2/2 -I1 X");
gmtwrite("lixo.grd", G)

println("	GRDIMAGE")
# Just create the figs but no check if they are correct.
@test_throws ErrorException("Missing input data to run this module.") grdimage("", J="X10", Vd=dbg2)
PS = grdimage(G, J="X10", ps=1);
gmt("destroy")
grdimage!(G, J="X10", Vd=dbg2);
grdimage!("", G, J="X10", Vd=dbg2);
Gr=mat2grid(rand(Float32, 128, 128)*255); Gg=mat2grid(rand(Float32, 128, 128)*255); Gb=mat2grid(rand(Float32, 128, 128)*255);
grdimage(rand(UInt8,64,64), Vd=dbg2);
grdimage(rand(UInt16,64,64), Vd=dbg2);
grdimage(rand(Float32, 128, 128)*255, rand(Float32, 128, 128)*255, rand(Float32, 128, 128)*255, J="X10")
grdimage(data=(Gr,Gg,Gb), J=:X10, I=mat2grid(rand(Float32,128,128)), Vd=dbg2)
grdimage(rand(Float32, 128, 128), shade=(default=30,), coast=(W=1,), Vd=dbg2)
grdimage(rand(Float32, 128, 128), colorbar=(color=:rainbow, pos=(anchor=:RM,length=8)), Vd=dbg2)
grdimage(rand(Float32, 128, 128), percent=90, Vd=dbg2)
grdimage(rand(Float32, 128, 128), clim=[0.1, 0.9], Vd=dbg2)
grdimage("@earth_relief_01d_g", percent=98, Vd=dbg2)
grdimage("@earth_relief_01d_g", clim=[-4000 4000], Vd=dbg2)
grdimage("lixo.grd", coast=true, colorbar=true, logo=true, Vd=dbg2)
G = gmt("grdmath -Rg -fg -I5 X");
gmtwrite("lixo.grd", G)
grdimage("lixo.grd", proj=:Winkel, colorbar=true, coast=true)

println("	GRDVIEW")
PS = grdview(G, J="X6i", JZ=5,  I=45, Q="s", C="topo", R="-15/15/-15/15/-1/1", view="120/30", ps=1);
gmt("destroy")
grdview!("",G, J="X6i", JZ=5, I=45, Q="s", C="topo", R="-15/15/-15/15/-1/1", view="120/30", Vd=dbg2);
grdview!(G, J="X6i", JZ=5,  I=45, Q="s", C="topo", R="-15/15/-15/15/-1/1", view="120/30", Vd=dbg2);
grdview!(G, G=G, J="X6i", JZ=5,  I=45, Q="s", C="topo", R="-15/15/-15/15/-1/1", view="120/30", Vd=dbg2);
r = grdview!(G, plane=(-6,:lightgray), surftype=(surf=true,mesh=:red), view="120/30", Vd=dbg2);
@test startswith(r, "grdview  -R -J -n+a -p120/30 -N-6+glightgray -Qsmred")
r = grdview(G, surf=(waterfall=(:rows,:red),surf=true, mesh=true, img=50), Vd=dbg2);
@test startswith(r, "grdview  -R0/360/-90/90 -JX" * split(GMT.DEF_FIG_SIZE, '/')[1] * "/0" * " -Baf -Bza -n+a -Qmyredsmi50")
@test startswith(grdview(G, surf=(waterfall=:rows,), Vd=dbg2), "grdview  -R0/360/-90/90 -JX" * split(GMT.DEF_FIG_SIZE, '/')[1] * "/0" * " -Baf -Bza -n+a -Qmy")
@test startswith(grdview(G, surf=(waterfall=(rows=true, fill=:red),), Vd=dbg2), "grdview  -R0/360/-90/90 -JX" * split(GMT.DEF_FIG_SIZE, '/')[1] * "/0" * " -Baf -Bza -n+a -Qmyred")
@test_throws ErrorException("Wrong way of setting the drape (G) option.")  grdview(rand(16,16), G=(1,2))
I = mat2grid(rand(Float32,128,128));
grdview(rand(128,128), G=(Gr,Gg,Gb), I=I, J=:X12, JZ=5, Q=:i, view="145/30")
gmtwrite("lixo.grd", I)
	@info "1..."
grdview(rand(128,128), G=I, I=I, J=:X12, JZ=5, Q=:i, view="145/30")
	@info "2..."
grdview(rand(128,128), G="lixo.grd", I=I, J=:X12, JZ=5, Q=:i, view="145/30", Vd=dbg2)
I = mat2img(rand(UInt8,89,120,3), proj4="+proj=longlat +datum=WGS84 +no_defs");	# 'proj' is ignored
gmtwrite("lixo.tif", I)
grdview(rand(90,120), G="lixo.tif", J=:X12, JZ=5, Q=:i, view="145/30", V=:q)
grdview(rand(90,120), G=I, J=:X12, JZ=5, Q=:i, view="145/30", V=:q)
# If I use proj4 something in the above fcks the memory state and one of next tests would crash. 

println("	IMSHOW")
imshow(rand(UInt16, 128,128),show=false)
imshow(rand(128,128), view=:default, Vd=dbg2)
imshow(G, axis=:a, shade="+a45",show=false, contour=true)
imshow(G, clip=[-1. -1; 0 1; 1 -1], Vd=dbg2)
imshow(G, p=(25,30), tiles=true, Vd=dbg2)
imshow(rand(128,128), shade="+a45",show=false)
imshow("lixo.tif",show=false)
imshow(rand(UInt8(0):UInt8(255),256,256), colorbar=true, show=false)
imshow(rand(UInt8(0):UInt8(255),256,256), colorbar="bottom", show=false)
I = mat2img(rand(UInt8,32,32),x=[220800 453600], y=[3.5535e6 3.7902e6], proj4="+proj=utm+zone=28+datum=WGS84");
imshow(I, coast=(land=:red,), show=false)
I = mat2img(rand(UInt16,32,32),x=[220800 453600], y=[3.5535e6 3.7902e6]);
imshow(I, show=false)
x = range(-10, 10, length = 30);
f(x,y) = sqrt(x^2 + y^2);
imshow(x,x,f, Vd=dbg2);
imshow(x,f, Vd=dbg2);
imshow(f, x, Vd=dbg2);
imshow(f, x, x, Vd=dbg2);
imshow(-2:0.1:2, -1:0.1:3,"rosenbrock", Vd=dbg2);
imshow(-2:0.1:2, "rosenbrock", Vd=dbg2);
imshow("lixo", Vd=dbg2);
mat = reshape(UInt8.([255 0 0 0 0 0 0 0 0 0 0 0 0 255 0 0 0 0 0 0 0 0 0 0 0 0 255]), 3,3,3);
I = mat2img(mat, hdr=[0.0 3 0 3 0 255 1 1 1]);
imshow(I, J=:Merc, show=false)
I = GMT.GMTimage("", "", 0, 0, [1., 10, 1, 10, 0, 1, 1, 1, 1], [1., 1], 1, zero(UInt16), "gray", String[], String[], collect(1.:11), collect(1.:11), [0.],rand(UInt16,10,10), zeros(Int32,3), 0, Array{UInt8,2}(undef,1,1), "TRBa", 0);
imshow(I,Vd=dbg2)
imshow(mat2ds([0 0; 10 0; 10 10; 11 10]), Vd=dbg2)
imshow(makecpt(1,5, cmap=:polar), Vd=dbg2)
imshow(:gray, Vd=dbg2)
GMT.CURRENT_CPT[1] = GMT.GMTcpt()		# The fact that I need to do this because prev line did no "show", shows a subtle bug.
X4 = mat2grid(rand(Float32,32,32,4), title="lixo");
viz(X4, show=false)
GMT.mat2grid("ackley");
GMT.mat2grid("egg");
GMT.mat2grid("sombrero");
GMT.mat2grid("rosenbrock");