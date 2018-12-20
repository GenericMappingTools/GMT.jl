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
	gmt("write -Td V:/filt2.txt", F)
	return F
end

# -------------------------------------------------------------------------
function gmtsimplify()
	println("Test gmtsimplify")
	t = gmt("simplify -T0.2", rand(50,2))
end

# -------------------------------------------------------------------------
function makecpt()
	C = gmt("makecpt -Crainbow -T5/35/5")
	gmt("psscale -D4/4/4/0.5 -P -Baf > V:/t.ps", C)
end

# -------------------------------------------------------------------------
function grdinfo()
	G = gmt("surface -R0/150/0/150 -I1", rand(100,3) * 100)
	T = gmt("grdinfo -V", G)
end

# -------------------------------------------------------------------------
function pstext()
	lines = Any["5 6 Some label", "6 7 Another label"]
	gmt("pstext -R0/10/0/10 -JM6i -Bafg -F+f18p -P > V:/text.ps", lines)
end

# -------------------------------------------------------------------------
function jlogo(L)
	# Create the Julia "Terminator" 3 colored circles triangle
	# L is the length of the equilateral triangle
	W = 2 * L 					# Region width
	H = L * sind(60) 			# Triangle height
	s_size = 0.8 * L 			# Circle diameter
	l_thick = s_size * 0.06 	# Line thickness

	com = @sprintf("psxy -Sc%fc -G191/101/95  -Jx1 -R0/%f/0/%f -W%fc,171/43/33  -P -K >  V:/Jlogo.ps", s_size, W, W, l_thick)
	gmt(com, [L/2 L/2])
	com = @sprintf("psxy -Sc%fc -G158/122/190 -Jx1 -R0/%f/0/%f -W%fc,130/83/171 -O -K >> V:/Jlogo.ps", s_size, W, W, l_thick)
	gmt(com, [L+L/2 L/2])
	com = @sprintf("psxy -Sc%fc -G128/171/93  -Jx1 -R0/%f/0/%f -W%fc,81/143/24  -O    >> V:/Jlogo.ps", s_size, W, W, l_thick)
	gmt(com, [L L/2+H])
end

jlogo() = jlogo(5)
# If not provided, make a logo where the triangle has a side of 5 cm.
