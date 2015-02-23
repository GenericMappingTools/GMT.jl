using GMT

# -------------------------------------------------------------------------
function blockmean()
	gmt("blockmean -R0/150/0/100 -I10 -V > V:/ave1.txt", rand(Float64,100,3)*150)
	B = gmt("blockmean -R0/150/0/100 -I10", rand(Float64,100,3)*100);
	gmt("write -Td V:/ave2.txt", B)
	return B
end

# -------------------------------------------------------------------------
function surface()
	gmt("surface -R0/150/0/100 -I1 -GV:/lixo.grd -V", rand(Float64,100,3)*150)
	G = gmt("surface -R0/150/0/100 -I1", rand(Float64,100,3)*150)
	return G
end

# -------------------------------------------------------------------------
function pscoast()
	gmt("pscoast -R-10/0/35/45 -B1 -W1 -Gbrown -JM14c -P -V > V:/lixo.ps")
end

# -------------------------------------------------------------------------
function gmtinfo()
	r = gmt("gmtinfo -C -V",ones(Float32,9,3)*5)
	info = gmt("blockmean -R0/5/0/5 -I1 -V", rand(Float32,2048,3)*5)
end

# -------------------------------------------------------------------------
function gmtread()
	G = gmt("gmtread -Tg V:/lixo.grd")
	return G
end

# -------------------------------------------------------------------------
function gmtwrite()
	G = gmt("gmtread -Tg V:/lixo.grd")
	gmt("write -Tg V:/crap.grd", G)
	return G
end

# -------------------------------------------------------------------------
function grdimage()
	G = gmt("surface -R0/150/0/100 -I1", rand(Float64,100,3)*150)
	gmt("grdimage -JX8c -Ba -P -Cblue,red > V:/crap_img.ps", G)
end

# -------------------------------------------------------------------------
function gridbox()
	grd = ones(Float32,9,9)*5
	hdr = float64([0,8,0,8,0,1,0,1,1])
	grd_box = GMT_grd_container(9, 9, pointer(grd), pointer(hdr))
	#gmt("grdinfo -L0 -V", grd_box)
	gmt("write -Tg V:/lixo.grd -Vl", grd_box)
end

# -------------------------------------------------------------------------
function grd2xyz_box()
	grd = ones(Float32,9,9)*5
	hdr = float64([0,8,0,8,0,1,0,1,1])
	grd_box = GMT_grd_container(9, 9, pointer(grd), pointer(hdr))
	xyz = gmt("grd2xyz -V", grd_box)
	return xyz
end

# -------------------------------------------------------------------------
function grd2xyz()
	G = gmt("surface -R0/150/0/100 -I1", rand(Float64,100,3)*150)
	xyz = gmt("grd2xyz -V", G)
	return xyz
end

# -------------------------------------------------------------------------
function filter1d()
	t = zeros(100,2)
	t[:,1] = 1:100
	t[:,2] = rand(100,1) * 100
	gmt("filter1d -Fg10 -E > V:/filt1.txt", t)
	F = gmt("filter1d -Fg10 -E", t)
	gmt ("write -Td V:/filt2.txt", F)
end

# -------------------------------------------------------------------------
function gmtsimplify()
	println("Test gmtsimplify")
	t = gmt("simplify -T0.2", rand(50,2))
end

#end