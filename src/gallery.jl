#The examples Gallery in Julia

using GMT

# Need to edit these two for you own paths
global g_root_dir = "C:/progs_cygw/GMTdev/gmt5/branches/5.2.0/"
global out_path = "V:/"			# Leave it empty to write files in current directory

# -----------------------------------------------------------------------------------------------------
function ex01()
	# Purpose:    Make two contour maps based on the data in the file osu91a1f_16.nc
	# GMT progs:  gmtset, grdcontour, psbasemap, pscoast

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex01"
	ps = out_path * "example_01.ps"

	gmt("gmtset MAP_GRID_CROSS_SIZE_PRIMARY 0 FONT_ANNOT_PRIMARY 10p")
	gmt("psbasemap -R0/6.5/0/7.5 -Jx1i -B0 -P -K > " * ps)
	gmt("pscoast -Rg -JH0/6i -X0.25i -Y0.2i -O -K -Bg30 -Dc -Glightbrown -Slightblue >> " * ps)
	cmd = @sprintf("grdcontour %s/osu91a1f_16.nc", d_path)
	gmt(cmd * " -J -C10 -A50+f7p -Gd4i -L-1000/-1 -Wcthinnest,- -Wathin,- -O -K -T+d0.1i/0.02i >> " * ps)
	gmt(cmd * " -J -C10 -A50+f7p -Gd4i -L-1/1000 -O -K -T+d0.1i/0.02i >> " * ps)
	gmt("pscoast -Rg -JH6i -Y3.4i -O -K -B+t\"Low Order Geoid\" -Bg30 -Dc -Glightbrown -Slightblue >> " * ps)
	gmt(cmd * " -J -C10 -A50+f7p -Gd4i -L-1000/-1 -Wcthinnest,- -Wathin,- -O -K -T+d0.1i/0.02i+l >> " * ps)
	gmt(cmd * " -J -C10 -A50+f7p -Gd4i -L-1/1000 -O -T+d0.1i/0.02i+l >> " * ps)
	rm("gmt.conf")
end

# -----------------------------------------------------------------------------------------------------
function ex02()	
	# Purpose:	Make two color images based gridded data
	# GMT progs:	gmtset, grd2cpt, grdgradient, grdimage, makecpt, psscale, pstext

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex02"
	ps = out_path * "example_02.ps"

	gmt("gmtset FONT_TITLE 30p MAP_ANNOT_OBLIQUE 0")
	g_cpt = gmt("makecpt -Crainbow -T-2/14/2")
	cmd = @sprintf("grdimage %s/HI_geoid2.nc", d_path)
	gmt(cmd * " -R160/20/220/30r -JOc190/25.5/292/69/4.5i -E50 -K -P -B10 -X1.5i -Y1.25i > " * ps, g_cpt)
	gmt("psscale -DjRM+o0.6i/0+jLM+w2.88i/0.4i+mc+e -R -J -O -K -Bx2+lGEOID -By+lm >> " * ps, g_cpt)
	t_cpt = gmt(@sprintf("grd2cpt %s/HI_topo2.nc -Crelief -Z", d_path))
	GHI_topo2_int = gmt(@sprintf("grdgradient %s/HI_topo2.nc -A0 -Nt", d_path))
	cmd = @sprintf("grdimage %s/HI_topo2.nc", d_path)
	gmt(cmd * " -I\$ -R -J -B+t\"H@#awaiian@# T@#opo and @#G@#eoid@#\"" *
        " -B10 -E50 -O -K -C\$ -Y4.5i --MAP_TITLE_OFFSET=0.5i >> " * ps, GHI_topo2_int, t_cpt)
	gmt("psscale -DjRM+o0.6i/0+jLM+w2.88i/0.4i+mc -R -J -O -K -I0.3 -Bx2+lTOPO -By+lkm >> " * ps, t_cpt)
	gmt("pstext -R0/8.5/0/11 -Jx1i -F+f30p,Helvetica-Bold+jCB -O -N -Y-4.5i >> " * ps,
		Any["-0.4 7.5 a)", "-0.4 3.0 b)"])
	rm("gmt.conf")
end

# -----------------------------------------------------------------------------------------------------
function ex04()	
	# Purpose:   3-D mesh and color plot of Hawaiian topography and geoid
	# GMT progs: grdcontour, grdgradient, grdimage, grdview, psbasemap, pscoast, pstext

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex04/"
	ps = out_path * "example_04.ps"

	fid = open("zero.cpt","w")
	println(fid, "-10  255   0  255")
	println(fid, "0  100  10  100")
	close(fid);

	cmd = @sprintf("grdcontour %sHI_geoid4.nc", d_path)
	gmt(cmd * " -R195/210/18/25 -Jm0.45i -p60/30 -C1 -A5+o -Gd4i -K -P -X1.25i -Y1.25i > " * ps)
	gmt("pscoast -R -J -p -B2 -BNEsw -Gblack -O -K -TdjBR+o0.1i+w1i+l >> " * ps)
	gmt(@sprintf("grdview %sHI_topo4.nc", d_path) * " -R195/210/18/25/-6/4 -J -Jz0.34i -p -Czero.cpt -O -K" *
		" -N-6+glightgray -Qsm -B2 -Bz2+l\"Topo (km)\" -BneswZ -Y2.2i >> " * ps)
	gmt("pstext -R0/10/0/10 -Jx1i -F+f60p,ZapfChancery-MediumItalic+jCB -O >> " *  ps,
		"3.25 5.75 H@#awaiian@# R@#idge@#")
	rm("zero.cpt")

	ps = out_path * "example_04c.ps"
	Gg_intens = gmt(@sprintf("grdgradient %sHI_geoid4.nc", d_path) * " -A0 -Nt0.75 -fg")
	Gt_intens = gmt(@sprintf("grdgradient %sHI_topo4.nc",  d_path) * " -A0 -Nt0.75 -fg")
	gmt(@sprintf("grdimage %sHI_geoid4.nc", d_path) *
		" -I -R195/210/18/25 -JM6.75i -p60/30 -C" * d_path * "geoid.cpt -E100 -K -P -X1.25i -Y1.25i > " * ps, Gg_intens)
	gmt("pscoast -R -J -p -B2 -BNEsw -Gblack -O -K >> " * ps)
	gmt("psbasemap -R -J -p -O -K -TdjBR+o0.1i+w1i+l --COLOR_BACKGROUND=red --FONT=red" *
		" --MAP_TICK_PEN_PRIMARY=thinner,red >> " * ps)
	gmt("psscale -R -J -p240/30 -DJBC+o0/0.5i+w5i/0.3i+h -C" * d_path * "geoid.cpt -I -O -K -Bx2+l\"Geoid (m)\" >> " * ps)
	gmt(@sprintf("grdview %sHI_topo4.nc", d_path) * " -I -R195/210/18/25/-6/4 -J -C" * d_path * "topo.cpt" *
		" -JZ3.4i -p60/30 -O -K -N-6+glightgray -Qc100 -B2 -Bz2+l\"Topo (km)\" -BneswZ -Y2.2i >> " * ps, Gt_intens)
	gmt("pstext -R0/10/0/10 -Jx1i -F+f60p,ZapfChancery-MediumItalic+jCB -O >> " * ps,
		"3.25 5.75 H@#awaiian@# R@#idge@#")
end

# -----------------------------------------------------------------------------------------------------
function ex05()
	# Purpose:   Generate grid and show monochrome 3-D perspective
	# GMT progs: grdgradient, grdmath, grdview, pstext

	global out_path
	ps = out_path * "example_05.ps"

	Gsombrero = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
	fid = open("gray.cpt","w")
	println(fid, "-5 128 5 128");
	close(fid);
	Gintensity = gmt("grdgradient -A225 -G -Nt0.75", Gsombrero);
	gmt("grdview -JX6i -JZ2i -B5 -Bz0.5 -BSEwnZ -N-1+gwhite -Qs -I -X1.5i" *
		" -Cgray.cpt -R-15/15/-15/15/-1/1 -K -p120/30 > " * ps, Gintensity, Gsombrero)
	gmt("pstext -R0/11/0/8.5 -Jx1i -F+f50p,ZapfChancery-MediumItalic+jBC -O >> " * ps,
		"4.1 5.5 z(r) = cos (2@~p@~r/8) @~\\327@~e@+-r/10@+")
	rm("gray.cpt");
end

# -----------------------------------------------------------------------------------------------------
function ex06()
	# Purpose:    Make standard and polar histograms
	# GMT progs:  pshistogram, psrose

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex06/"
	ps = out_path * "example_06.ps"

	gmt("psrose " * d_path * "fractures.d -: -A10r -S1.8in -P -Gorange -R0/1/0/360 -X2.5i -K -Bx0.2g0.2" *
		" -By30g30 -B+glightblue -W1p > " * ps)
	gmt("pshistogram -Bxa2000f1000+l\"Topography (m)\" -Bya10f5+l\"Frequency\"+u\" %\"" *
		" -BWSne+t\"Histograms\"+glightblue " * d_path * "v3206.t -R-6000/0/0/30 -JX4.8i/2.4i -Gorange -O" *
		" -Y5.0i -X-0.5i -L1p -Z1 -W250 >> " * ps)
end

# -----------------------------------------------------------------------------------------------------
function ex07()
	# Purpose:    Make a basemap with earthquakes and isochrons etc
	# GMT progs:  pscoast, pstext, psxy

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex07/"
	ps = out_path * "example_07.ps"

	gmt("pscoast -R-50/0/-10/20 -JM9i -K -Slightblue -GP300/26:FtanBdarkbrown -Dl -Wthinnest" *
		" -B10 --FORMAT_GEO_MAP=dddF > " * ps)
	gmt("psxy -R -J -O -K " * d_path * "fz.xy -Wthinner,- >> " * ps)
	gmt("psxy ' d_path '/quakes.xym -R -J -O -K -h1 -Sci -i0,1,2s0.01 -Gred -Wthinnest >> " * ps)
	gmt("psxy -R -J -O -K " * d_path * "isochron.xy -Wthin,blue >> " * ps)
	gmt("psxy -R -J -O -K " * d_path * "ridge.xy -Wthicker,orange >> " * ps)
	gmt("psxy -R -J -O -K -Gwhite -Wthick -A >> " * ps, [-14.5 15.2; -2 15.2; -2 17.8; -14.5 17.8])
	gmt("psxy -R -J -O -K -Gwhite -Wthinner -A >> " * ps, [-14.35 15.35; -2.15 15.35; -2.15 17.65; -14.35 17.65])
	gmt("psxy -R -J -O -K -Sc0.08i -Gred -Wthinner >> " * ps, [-13.5 16.5])
	gmt("pstext -R -J -F+f18p,Times-Italic+jLM -O -K >> " * ps, "-12.5 16.5 ISC Earthquakes")
	gmt("pstext -R -J -O -F+f30,Helvetica-Bold,white=thin >> " * ps, "-43 -5 SOUTH' '-43 -8 AMERICA' '-7 11 AFRICA")
end

# -----------------------------------------------------------------------------------------------------
function ex23()
	# Purpose:    Plot distances from Rome and draw shortest paths
	# GMT progs:  grdmath, grdcontour, pscoast, psxy, pstext, grdtrack

	global out_path
	ps = out_path * "example_23.ps"

	# Position and name of central point:
	lon  = 12.50
	lat  = 41.99
	#lon = -78.8416666666666667
	#lat = 9.4683333333
	name = "Rome"

	Gdist = gmt(@sprintf("grdmath -Rg -I1 %f %f SDIST", lon, lat))

	gmt("pscoast -Rg -JH90/9i -Glightgreen -Sblue -A1000 -Dc -Bg30 -B+t\"Distances from " * 
		name * " to the World\" -K -Wthinnest > " * ps)
	gmt("grdcontour -A1000+v+u\" km\"+fwhite -Glz-/z+ -S8 -C500 -O -K -JH90/9i -Wathin,white " *
		"-Wcthinnest,white,- >> " * ps, Gdist)
	
	# Location info for 5 other cities + label justification
	cities = cell(5)
	cities[1] = "105.87 21.02 LM HANOI"
	cities[2] = "282.95 -12.1 LM LIMA"
	cities[3] = "178.42 -18.13 LM SUVA"
	cities[4] = "237.67 47.58 RM SEATTLE"
	cities[5] = "28.20 -25.75 LM PRETORIA"
	fid = open("cities.d","w")
	for (k = 1:5)
		println(fid, cities[k])
	end
	close(fid)

	# For each of the cities, plot great circle arc to Rome with gmt psxy
	gmt("psxy -R -J -O -K -Wthickest,red >> " * ps, [lon lat; 105.87 21.02])
	gmt("psxy -R -J -O -K -Wthickest,red >> " * ps, [lon lat; 282.95 -12.1])
	gmt("psxy -R -J -O -K -Wthickest,red >> " * ps, [lon lat; 178.42 -18.13])
	gmt("psxy -R -J -O -K -Wthickest,red >> " * ps, [lon lat; 237.67 47.58])
	gmt("psxy -R -J -O -K -Wthickest,red >> " * ps, [lon lat; 28.20 -25.75])

	# Plot red squares at cities and plot names:
	for (k = 1:5)
		gmt("pstext -R -J -O -K -Dj0.15/0 -F+f12p,Courier-Bold,red+j -N >> " * ps, cities[k])
	end

	# Place a yellow star at Rome
	gmt("psxy -R -J -O -K -Sa0.2i -Gyellow -Wthin >> " * ps, [12.5 41.99])

	# Sample the distance grid at the cities and use the distance in km for labels
	dist = gmt("grdtrack cities.d -G", Gdist);
	t = cell(5);
	for (k = 1:5)
		t[k] = @sprintf("%f %f %d", dist[k,1], dist[k,2], dist[k,end]);
	end
	gmt("pstext -R -J -O -D0/-0.2i -N -Gwhite -W -C0.02i -F+f12p,Helvetica-Bold+jCT >> " * ps, t)
	rm("cities.d");
end

# -----------------------------------------------------------------------------------------------------
function ex25()
	# Purpose:   Display distribution of antipode types
	# GMT progs: gmtset, grdlandmask, grdmath, grd2xyz, gmtmath, grdimage, pscoast, pslegend

	# Create D minutes global grid with -1 over oceans and +1 over land
	global out_path
	ps = out_path * "example_25.ps"
	D  = 30

	Gwetdry = gmt(@sprintf("grdlandmask -Rg -I%dm -Dc -A500 -N-1/1/1/1/1 -r", D))
	# Manipulate so -1 means ocean/ocean antipode, +1 = land/land, and 0 elsewhere
	Gkey = gmt("grdmath -fg \$ DUP 180 ROTX FLIPUD ADD 2 DIV =", Gwetdry)
	# Calculate percentage area of each type of antipode match.
	Gscale = gmt(@sprintf("grdmath -Rg -I%dm -r Y COSD 60 %d DIV 360 MUL DUP MUL PI DIV DIV 100 MUL =", D, D))
	Gtmp   = gmt("grdmath -fg \$ -1 EQ 0 NAN \$ MUL =", Gkey, Gscale)

	key    = gmt("grd2xyz -s -ZTLf", Gtmp)
	ocean  = gmt("gmtmath -bi1f -Ca -S \$ SUM UPPER RINT =", key)
	Gtmp   = gmt("grdmath -fg \$ 1 EQ 0 NAN \$ MUL =", Gkey, Gscale)
	key    = gmt("grd2xyz -s -ZTLf", Gtmp)
	land   = gmt("gmtmath -bi1f -Ca -S \$ SUM UPPER RINT =", key)
	Gtmp   = gmt("grdmath -fg \$ 0 EQ 0 NAN \$ MUL", Gkey, Gscale)
	key    = gmt("grd2xyz -s -ZTLf", Gtmp)
	mixed  = gmt("gmtmath -bi1f -Ca -S \$ SUM UPPER RINT =", key)

	# Generate corresponding color table
	C = gmt("makecpt -Cblue,gray -T-1.5/0.5/1")
	# Create the final plot and overlay coastlines
	gmt("grdimage -JKs180/9i -Bx60 -By30 -BWsNE+t\"Antipodal comparisons\" -K -C\$ -Y1.2i -nn > " * ps, Gkey, C)
	gmt("pscoast -R -J -O -K -Wthinnest -Dc -A500 >> " * ps)
end

# -----------------------------------------------------------------------------------------------------
function ex44()
	# Purpose:   Illustrate use of map inserts
	# GMT progs: pscoast, psbasemap, mapproject

	global out_path
	ps = out_path * "example_04.ps"

	# Bottom map of Australia
	gmt("pscoast -R110E/170E/44S/9S -JM6i -P -Baf -BWSne -Wfaint -N2/1p  -EAU+gbisque -Gbrown" *
		" -Sazure1 -Da -K -Xc --FORMAT_GEO_MAP=dddF > " * ps)
	gmt("psbasemap -R -J -O -K -DjTR+w1.5i+o0.15i/0.1i+sxx000 -F+gwhite+p1p+c0.1c+s >> " * ps)
	t = readdlm("xx000");		# x0 y0 w h
	cmd = @sprintf("pscoast -Rg -JG120/30S/%f -Da -Gbrown -A5000 -Bg -Wfaint -EAU+gbisque -O -K -X%f -Y%f >> %s",
		t[3], t[1], t[2], ps);
	gmt(cmd)
	gmt(@sprintf("psxy -R -J -O -K -T -X-%f -Y-%f >> %s", t[1], t[2], ps))
	# Determine size of insert map of Europe
	t = gmt("mapproject -R15W/35E/30N/48N -JM2i -W");	# w h
	gmt("pscoast -R10W/5E/35N/44N -JM6i -Baf -BWSne -EES+gbisque -Gbrown -Wfaint -N1/1p -Sazure1" *
		" -Df -O -K -Y4.5i --FORMAT_GEO_MAP=dddF >> " * ps)
	gmt(@sprintf("psbasemap -R -J -O -K -DjTR+w%f/%f+o0.15i/0.1i+sxx000 -F+gwhite+p1p+c0.1c+s >> %s", t[1], t[2], ps))
	t = readdlm("xx000");		# x0 y0 w h
	cmd = @sprintf("pscoast -R15W/35E/30N/48N -JM%f -Da -Gbrown -B0 -EES+gbisque -O -K -X%f -Y%f", t[3], t[1], t[2]);
	gmt(cmd * " --MAP_FRAME_TYPE=plain >> " * ps)
	gmt(@sprintf("psxy -R -J -O -T -X-%f -Y-%f >> %s", t[1], t[2], ps))
	rm("xx000")
end

# -----------------------------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------------------------
