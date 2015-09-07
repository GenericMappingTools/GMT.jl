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
	gmt("psxy " * d_path * "quakes.xym -R -J -O -K -h1 -Sci -i0,1,2s0.01 -Gred -Wthinnest >> " * ps)
	gmt("psxy -R -J -O -K " * d_path * "isochron.xy -Wthin,blue >> " * ps)
	gmt("psxy -R -J -O -K " * d_path * "ridge.xy -Wthicker,orange >> " * ps)
	gmt("psxy -R -J -O -K -Gwhite -Wthick -A >> " * ps, [-14.5 15.2; -2 15.2; -2 17.8; -14.5 17.8])
	gmt("psxy -R -J -O -K -Gwhite -Wthinner -A >> " * ps, [-14.35 15.35; -2.15 15.35; -2.15 17.65; -14.35 17.65])
	gmt("psxy -R -J -O -K -Sc0.08i -Gred -Wthinner >> " * ps, [-13.5 16.5])
	gmt("pstext -R -J -F+f18p,Times-Italic+jLM -O -K >> " * ps, "-12.5 16.5 ISC Earthquakes")
	gmt("pstext -R -J -O -F+f30,Helvetica-Bold,white=thin >> " * ps, "-43 -5 SOUTH' '-43 -8 AMERICA' '-7 11 AFRICA")
end

# -----------------------------------------------------------------------------------------------------
function ex08()
	# Purpose:    Make a 3-D bar plot
	# GMT progs:  grd2xyz, pstext, psxyz

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex08/"
	ps = out_path * "example_08.ps"

	xyz = gmt("grd2xyz " * d_path * "guinea_bay.nc")
	gmt("psxyz -B1 -Bz1000+l\"Topography (m)\" -BWSneZ+b+tETOPO5" *
		" -R-0.1/5.1/-0.1/5.1/-5000/0 -JM5i -JZ6i -p200/30 -So0.0833333ub-5000 -P" *
		" -Wthinnest -Glightgreen -K > " * ps, xyz)
	gmt("pstext -R -J -JZ -Z0 -F+f24p,Helvetica-Bold+jTL -p -O >> " * ps, "0.1 4.9 This is the surface of cube")
end

# -----------------------------------------------------------------------------------------------------
function ex09()
	# Purpose:    Make wiggle plot along track from geoid deflections
	# GMT progs:  gmtconvert, pswiggle, pstext, psxy

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex09/"
	ps = out_path * "example_09.ps"

	gmt("pswiggle " * d_path * "tracks.txt -R185/250/-68/-42 -K -Jm0.13i -Ba10f5 -BWSne+g240/255/240 -G+red" *
		" -G-blue -Z2000 -Wthinnest -S240/-67/500/@~m@~rad --FORMAT_GEO_MAP=dddF > " * ps)
	gmt("psxy -R -J -O -K " * d_path * "ridge.xy -Wthicker >> " * ps)
	gmt("psxy -R -J -O -K " * d_path * "fz.xy    -Wthinner,- >> " * ps)
	# Take label from segment header and plot near coordinates of last record of each track
	t = gmt("gmtconvert -El " * d_path * "tracks.txt")
	gmt("pstext -R -J -F+f10p,Helvetica-Bold+a50+jRM+h -D-0.05i/-0.05i -O >> " * ps, t)
end

# -----------------------------------------------------------------------------------------------------
function ex10()
	# Purpose:    Make 3-D bar graph on top of perspective map
	# GMT progs:  pscoast, pstext, psxyz, pslegend

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex10/"
	ps = out_path * "example_10.ps"

	gmt("pscoast -Rd -JX8id/5id -Dc -Sazure2 -Gwheat -Wfaint -A5000 -p200/40 -K > " * ps)
	str = open(readall, d_path * "languages.txt", "r")
	k = 1
	while (str[k](1) == "#")
		k = k + 1
	end
	str = str[k:end]		# Remove the comment lines
	nl = numel(str)
	array = zeros(nl, 7)
	for (k = 1:nl)
		array[k,:] = strread(str[k], "%f", 7);
	end
	t = cell(nl,1)
	for (k = 1:nl)
		t[k] = @sprintf("%d %d %d\n",array[k,1], array[k,2], sum(array[k,3:end]))
	end
	gmt("pstext -R -J -O -K -p -Gwhite@30 -D-0.25i/0 -F+f30p,Helvetica-Bold,firebrick=thinner+jRM >> " * ps, t)
	gmt("psxyz " * d_path * "languages.txt -R-180/180/-90/90/0/2500 -J -JZ2.5i -So0.3i -Gpurple -Wthinner" *
		" --FONT_TITLE=30p,Times-Bold --MAP_TITLE_OFFSET=-0.7i -O -K -p --FORMAT_GEO_MAP=dddF" *
		" -Bx60 -By30 -Bza500+lLanguages -BWSneZ+t\"World Languages By Continent\" >> " * ps)
	gmt("psxyz -R -J -JZ -So0.3ib -Gblue -Wthinner -O -K -p >> " * ps, [array[:,1:2] sum(array[:,3:4],2) array[:,3]])
	gmt("psxyz -R -J -JZ -So0.3ib -Gdarkgreen -Wthinner -O -K -p >> " * ps, [array[:,1:2] sum(array[:,3:5],2) sum(array[:,3:4],2)])
	gmt("psxyz -R -J -JZ -So0.3ib -Gyellow -Wthinner -O -K -p >> " * ps, [array[:,1:2] sum(array[:,3:6],2) sum(array[:,3:5],2)])
	gmt("psxyz -R -J -JZ -So0.3ib -Gred -Wthinner -O -K -p >> " * ps, [array[:,1:2] sum(array[:,3:7],2) sum(array[:,3:6],2)])
	gmt("pslegend -R -J -JZ -DjLB+o0.2i+w1.35i/0+jBL -O --FONT=Helvetica-Bold" *
		" -F+glightgrey+pthinner+s-4p/-6p/grey20@40 -p " * d_path * "legend.txt >> " * ps)
end

# -----------------------------------------------------------------------------------------------------
function ex12()
	# Purpose:    Illustrates Delaunay triangulation of points, and contouring
	# GMT progs:  makecpt, gmtinfo, pscontour, pstext, psxy, triangulate

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex12/"
	ps = out_path * "example_12.ps"

	net_xy = gmt("triangulate " * d_path * "table_5.11 -M");
	gmt("psxy -R0/6.5/-0.2/6.5 -JX3.06i/3.15i -B2f1 -BWSNe -Wthinner -P -K -X0.9i -Y4.65i > " * ps, net_xy)
	gmt("psxy " * d_path * "table_5.11 -R -J -O -K -Sc0.12i -Gwhite -Wthinnest >> " * ps)
	t = readdlm(d_path * "table_5.11")
	nl = size(t,1)
	c = cell(nl,1)
	for (k = 1:nl)
		c[k] = @sprintf("%f %f %d\n", t[k,1], t[k,2], k-1)
	end
	gmt("pstext -R -J -F+f6p -O -K >> " * ps, c)

	# Then draw network and print the node values
	gmt("psxy -R -J -B2f1 -BeSNw -Wthinner -O -K -X3.25i >> " * ps, net_xy)
	gmt("psxy -R -J -O -K " * d_path * "table_5.11 -Sc0.03i -Gblack >> " * ps)
	gmt("pstext " * d_path * "table_5.11 -R -J -F+f6p+jLM -O -K -Gwhite -W -C0.01i -D0.08i/0i -N >> " * ps)

	# Then contour the data and draw triangles using dashed pen; use "gmt gmtinfo" and "gmt makecpt" to make a
	# color palette (.cpt) file
	T = gmt("info -T25/2 " * d_path * "table_5.11")
	topo_cpt = gmt("makecpt -Cjet " * T[1])
	gmt("pscontour -R -J " * d_path * "table_5.11 -B2f1 -BWSne -Wthin -C -Lthinnest,-" *
		" -Gd1i -X-3.25i -Y-3.65i -O -K >> " * ps, topo_cpt)
	gmt("pscontour -R -J " * d_path * "table_5.11 -B2f1 -BeSnw -C -I -X3.25i -O -K >> " * ps, topo_cpt)
	gmt("pstext -R0/8/0/11 -Jx1i -F+f30p,Helvetica-Bold+jCB -O -X-3.25i >> " * ps, "3.16 8 Delaunay Triangulation")
end

# -----------------------------------------------------------------------------------------------------
function ex13()
	# Purpose:    Illustrate vectors and contouring
	# GMT progs:  grdmath, grdcontour, grdvector, pstext

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex13/"
	ps = out_path * "example_13.ps"

	Gz = gmt("grdmath -R-2/2/-2/2 -I0.1 X Y R2 NEG EXP X MUL =")
	Gdzdx = gmt("grdmath \$ DDX", Gz)
	Gdzdy = gmt("grdmath \$ DDY", Gz);
	gmt("grdcontour -JX3i -B1 -BWSne -C0.1 -A0.5 -K -P -Gd2i -S4 -T+d0.1i/0.03i > " * ps, Gdzdx)
	gmt("grdcontour -J -B -C0.05 -A0.2 -O -K -Gd2i -S4 -T+d0.1i/0.03i -Xa3.45i >> " * ps, Gdzdy)
	gmt("grdcontour -J -B -C0.05 -A0.1 -O -K -Gd2i -S4 -T+d0.1i/0.03i -Y3.45i  >> " * ps, Gz)
	gmt("grdcontour -J -B -C0.05 -O -K -Gd2i -S4 -X3.45i >> " * ps, Gz)
	gmt("grdvector  \$ \$ -I0.2 -J -O -K -Q0.1i+e+n0.25i -Gblack -W1p -S5i --MAP_VECTOR_SHAPE=0.5 >> " * ps, Gdzdx, Gdzdy)
	gmt("pstext -R0/6/0/4.5 -Jx1i -F+f40p,Times-Italic+jCB -O -X-3.45i >> " * ps,
		"3.2 3.6 z(x,y) = x@~\\327@~exp(-x@+2@+-y@+2@+)")
end

# -----------------------------------------------------------------------------------------------------
function ex14()
	# Purpose:    Showing simple gridding, contouring, and resampling along tracks
	# GMT progs:  blockmean, grdcontour, grdtrack, grdtrend, gmtinfo, project, gmtset, pstext, psbasemap, psxy, surface

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex14/"
	ps = out_path * "example_14.ps"

	# First draw network and label the nodes
	gmt("gmtset MAP_GRID_PEN_PRIMARY thinnest,-")
	gmt("psxy " * d_path * "table_5.11 -R0/7/0/7 -JX3.06i/3.15i -B2f1 -BWSNe -Sc0.05i -Gblack -P -K -Y6.45i > " * ps)
	gmt("pstext " * d_path * "table_5.11 -R -J -D0.1c/0 -F+f6p+jLM -O -K -N >> " * ps)
	mean_xyz = gmt("blockmean " * d_path * "table_5.11 -R0/7/0/7 -I1");

	# Then draw gmt blockmean cells
	gmt("psbasemap -R0.5/7.5/0.5/7.5 -J -O -K -Bg1 -X3.25i >> " * ps)
	gmt("psxy -R0/7/0/7 -J -B2f1 -BeSNw -Ss0.05i -Gblack -O -K >> " * ps, mean_xyz)
	# Reformat to one decimal for annotation purposes
	#t = cellstr(num2str(mean_xyz,'%g %g %.1f'));	# Round to nearest 0.1 and convert to cells
	nl = size(mean_xyz,1)
	t = cell(nl,1)
	for (k = 1:nl)
		t[k] = @sprintf("%f %f %.1f", mean_xyz[k,1], mean_xyz[k,2], mean_xyz[k,3])
	end
	gmt("pstext -R -J -D0.15c/0 -F+f6p+jLM -O -K -Gwhite -W -C0.01i -N >> " * ps, t)

	# Then gmt surface and contour the data
	Gdata = gmt("surface -R -I1", mean_xyz);
	gmt("grdcontour -J -B2f1 -BWSne -C25 -A50 -Gd3i -S4 -O -K -X-3.25i -Y-3.55i >> " * ps, Gdata)
	gmt("psxy -R -J -Ss0.05i -Gblack -O -K >> " * ps, mean_xyz)

	# Fit bicubic trend to data and compare to gridded gmt surface
	Gtrend = gmt("grdtrend -N10 -T", Gdata);
	track  = gmt("project -C0/0 -E7/7 -G0.1 -N");
	gmt("grdcontour -J -B2f1 -BwSne -C25 -A50 -Glct/cb -S4 -O -K -X3.25i >> " * ps, Gtrend)
	gmt("psxy -R -J -Wthick,. -O -K >> " * ps, track)

	# Sample along diagonal
	data  = gmt("grdtrack -G -o2,3", Gdata, track);
	trend = gmt("grdtrack -G -o2,3", Gtrend, track);
	t = gmt("info -I0.5/25", data, trend);
	gmt("psxy -JX6.3i/1.4i "  * t[1] * " -Wthick -O -K -X-3.25i -Y-1.9i -Bx1 -By50 -BWSne >> " * ps, data)
	gmt("psxy -R -J -Wthinner,- -O >> " * ps, trend)
end

# -----------------------------------------------------------------------------------------------------
function ex15()
	# Purpose:    Gridding and clipping when data are missing
	# GMT progs:  blockmedian, gmtconvert, grdclip, grdcontour, grdinfo, gmtinfo, nearneighbor, pscoast, psmask, pstext, surface

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex15/"
	ps = out_path * "example_15.ps"

	gmt("gmtconvert " * d_path * "ship.xyz -bo > ship.b")

	region = gmt("info ship.b -I1 -bi3d")
	region = region[1]				# We want this to be a string, not a cell
	Gship  = gmt("nearneighbor " * region * " -I10m -S40k ship.b -bi")
	gmt("grdcontour -JM3i -P -B2 -BWSne -C250 -A1000 -Gd2i -K > " * ps, Gship)

	ship_10m = gmt("blockmedian " * region * " -I10m ship.b -b3d")
	Gship = gmt("surface " * region * " -I10m", ship_10m)
	gmt("psmask " * region * " -I10m ship.b -J -O -K -T -Glightgray -bi3d -X3.6i >> " * ps)
	gmt("grdcontour -J -B -C250 -L-8000/0 -A1000 -Gd2i -O -K >> " * ps, Gship)

	gmt("psmask " * region * " -I10m -J -B -O -K -X-3.6i -Y3.75i >> " * ps, ship_10m)
	gmt("grdcontour -J -C250 -A1000 -L-8000/0 -Gd2i -O -K >> " * ps, Gship)
	gmt("psmask -C -O -K >> " * ps)

	Gship_clipped = gmt("grdclip -Sa-1/NaN -G", Gship)
	gmt("grdcontour -J -B -C250 -A1000 -L-8000/0 -Gd2i -O -K -X3.6i >> " * ps, Gship_clipped)
	gmt("pscoast " * region * " -J -O -K -Ggray -Wthinnest >> " * ps)
	info = gmt("grdinfo -C -M", Gship)
	gmt("psxy -R -J -O -K -Sa0.15i -Wthick >> " * ps, info[11:12])			# <--------- DOES NOT SHOW UP
	gmt("pstext -R0/3/0/4 -Jx1i -F+f24p,Helvetica-Bold+jCB -O -N >> " * ps, "-0.3 3.6 Gridding with missing data")
	rm("ship.b")
end

# -----------------------------------------------------------------------------------------------------
function ex17()
	# Purpose:    Illustrates clipping of images using coastlines
	# GMT progs:  grd2cpt, grdgradient, grdimage, pscoast, pstext

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex17/"
	ps = out_path * "example_17.ps"

	# First generate geoid image w/ shading
	geoid_cpt = gmt("grd2cpt " * d_path * "india_geoid.nc -Crainbow")
	Gindia_geoid_i = gmt("grdgradient " * d_path * "india_geoid.nc -Nt1 -A45 -G")
	gmt("grdimage " * d_path * "india_geoid.nc -I -JM6.5i -C -P -K > " * ps, Gindia_geoid_i, geoid_cpt)

	# Then use gmt pscoast to initiate clip path for land
	gmt("pscoast -R" * d_path * "india_geoid.nc -J -O -K -Dl -Gc >> " * ps)

	# Now generate topography image w/shading
	fid = open("gray.cpt","w");		println(fid, "-10000 150 10000 150");	close(fid)
	Gindia_topo_i = gmt("grdgradient " * d_path * "india_topo.nc -Nt1 -A45 -G")
	gmt("grdimage " * d_path * "india_topo.nc -I -J -Cgray.cpt -O -K >> " * ps, Gindia_topo_i)

	# Finally undo clipping and overlay basemap
	gmt("pscoast -R -J -O -K -Q -B10f5 -B+t\"Clipping of Images\" >> " * ps)

	# Put a color legend on top of the land mask
	gmt("psscale -DjTR+o0.3i/0.1i+w4i/0.2i+h -R -J -C -Bx5f1 -By+lm -I -O -K >> " * ps, geoid_cpt)

	# Add a text paragraph
	t = Any["> 90 -10 12p 3i j"
		"@_@%5%Example 17.@%%@_  We first plot the color geoid image"
		"for the entire region, followed by a gray-shaded @#etopo5@#"
		"image that is clipped so it is only visible inside the coastlines."]
	gmt("pstext -R -J -O -M -Gwhite -Wthinner -TO -D-0.1i/0.1i -F+f12,Times-Roman+jRB >> " * ps, t)
	rm("gray.cpt")

end

# -----------------------------------------------------------------------------------------------------
function ex18()
	# Purpose:    Illustrates volumes of grids inside contours and spatial selection of data
	# GMT progs:  gmtset, gmtselect, gmtspatial, grdclip, grdcontour, grdgradient, grdimage
	# GMT progs:  grdmath, grdvolume, makecpt, pscoast, psscale, pstext, psxy

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex18/"
	ps = out_path * "example_18.ps"

	# Use spherical gmt projection since SS data define on sphere
	gmt("gmtset PROJ_ELLIPSOID Sphere FORMAT_FLOAT_OUT %g")

	# Define location of Pratt seamount and the 400 km diameter
	pratt = [-142.65 56.25 400]

	# First generate gravity image w/ shading, label Pratt, and draw a circle
	# of radius = 200 km centered on Pratt.

	grav_cpt = gmt("makecpt -Crainbow -T-60/60/120 -Z");
	GAK_gulf_grav_i = gmt("grdgradient " * d_path * "AK_gulf_grav.nc -Nt1 -A45 -G");
	gmt("grdimage " * d_path * "AK_gulf_grav.nc -I -JM5.5i -C -B2f1 -P -K -X1.5i" *
		" -Y5.85i > " * ps, GAK_gulf_grav_i, grav_cpt)
	gmt("pscoast -R" * d_path * "AK_gulf_grav.nc -J -O -K -Di -Ggray -Wthinnest >> " * ps)
	gmt("psscale -DJBC+o0/0.4i+w4i/0.15i+h -R -J -C -Bx20f10 -By+l\"mGal\" -O -K >> " * ps, grav_cpt)
	gmt("pstext -R -J -O -K -D0.1i/0.1i -F+f12p,Helvetica-Bold+jLB >> " * ps, 
		@sprintf("%f %f Pratt", pratt[1], pratt[2]))
	gmt("psxy -R -J -O -K -SE- -Wthinnest >> " * ps, pratt)

	# Then draw 10 mGal contours and overlay 50 mGal contour in green
	gmt("grdcontour " * d_path * "AK_gulf_grav.nc -J -C20 -B2f1 -BWSEn -O -K -Y-4.85i >> " * ps)
	# Save 50 mGal contours to individual files, then plot them
	gmt("grdcontour " * d_path * "AK_gulf_grav.nc -C10 -L49/51 -Dsm_%c.txt")
	gmt("psxy -R -J -O -K -Wthin,green sm_C.txt >> " * ps)
	gmt("psxy -R -J -O -K -Wthin,green sm_O.txt >> " * ps)
	gmt("pscoast -R -J -O -K -Di -Ggray -Wthinnest >> " * ps)
	gmt("psxy -R -J -O -K -SE- -Wthinnest >> " * ps, pratt)
	rm("sm_O.txt")		# Only consider the closed contours

	# Now determine centers of each enclosed seamount > 50 mGal but only plot
	# the ones within 200 km of Pratt seamount.

	# First determine mean location of each closed contour and add it to the file centers.d
	centers = gmt("gmtspatial -Q -fg sm_C.txt")			# <---------- CRASHES HERE

	# Only plot the ones within 200 km
	t = gmt("gmtselect -C200k/\$ -fg", pratt, centers)
	gmt("psxy -R -J -O -K -SC0.04i -Gred -Wthinnest >> " * ps, t)
	gmt("psxy -R -J -O -K -ST0.1i -Gyellow -Wthinnest >> " * ps, pratt)

	# Then report the volume and area of these seamounts only
	# by masking out data outside the 200 km-radius circle
	# and then evaluate area/volume for the 50 mGal contour

	Gmask = gmt("grdmath -R " * @sprintf("%f %f", pratt[1], pratt[2]) * " SDIST =")
	Gmask = gmt("grdclip -Sa200/NaN -Sb200/1 -G", Gmask)
	Gtmp = gmt("grdmath " * d_path * "AK_gulf_grav.nc \$ MUL =", Gmask);
	area = gmt("grdvolume -C50 -Sk", Gtmp); 	# | cut -f2`
	volume = gmt("grdvolume -C50 -Sk", Gtmp); # | cut -f3`

	gmt("psxy -R -J -A -O -K -L -Wthin -Gwhite >> " * ps,
		[-148.5	52.75
		-141	52.75
		-141	53.75
		-148.5	53.75])

	gmt("pstext -R -J -O -F+f14p,Helvetica-Bold+jLM >> " * ps,
		Any[@sprintf("-148 53.08 Areas: %f.2 km@+2@+", area[3])
		 @sprintf("-148 53.42 Volumes: %d mGal\\264km@+2@+", volume[4])])

end

# -----------------------------------------------------------------------------------------------------
function ex19()
# The use of the circuit.ras screws the PS (to investigate)
	# Purpose:    Illustrates various color pattern effects for maps
	# GMT progs:  gmtset, grdimage, grdmath, makecpt, pscoast, pstext, psimage

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex19/"
	ps = out_path * "example_19.ps"

	# First make a worldmap with graded blue oceans and rainbow continents
	Glat = gmt("grdmath -Rd -I1 -r Y COSD 2 POW =")
	Glon = gmt("grdmath -Rd -I1 -r X =")
	fid = open("lat.cpt","w");		println(fid, "0 white 1 blue");		close(fid)
	lon_cpt = gmt("makecpt -Crainbow -T-180/180/360 -Z")
	gmt("grdimage -JI0/6.5i -Clat.cpt -P -K -Y7.5i -B0 -nl > " * ps, Glat)
	gmt("pscoast -R -J -O -K -Dc -A5000 -Gc >> " * ps)
	gmt("grdimage -J -C -O -K -nl >> " * ps, lon_cpt, Glon)
	gmt("pscoast -R -J -O -K -Q >> " * ps)
	gmt("pscoast -R -J -O -K -Dc -A5000 -Wthinnest >> " * ps)
	gmt("pstext -R -J -O -K -F+f32p,Helvetica-Bold,red=thinner >> " * ps, "0 20 12TH INTERNATIONAL")
	gmt("pstext -R -J -O -K -F+f32p,Helvetica-Bold,red=thinner >> " * ps, "0 -10 GMT CONFERENCE")
	gmt("pstext -R -J -O -K -F+f18p,Helvetica-Bold,green=thinnest >> " * ps, "0 -30 Honolulu, Hawaii, April 1, 2015")

	# Then show example of color patterns and placing a PostScript image
	gmt("pscoast -R -J -O -K -Dc -A5000 -Gp100/86:FredByellow -Sp100/" * d_path * "circuit.ras -B0 -Y-3.25i >> " * ps)
	gmt("pstext -R -J -O -K -F+f32p,Helvetica-Bold,lightgreen=thinner >> " * ps, "0 30 SILLY USES OF")
	gmt("pstext -R -J -O -K -F+f32p,Helvetica-Bold,magenta=thinner >> " * ps, "0 -30 COLOR PATTERNS")
	gmt("psimage -DjCM+w3i -R -J " * d_path * "GMT_covertext.eps -O -K >> " * ps)

	# Finally repeat 1st plot but exchange the patterns
	gmt("grdimage -J -C -O -K -Y-3.25i -B0 -nl >> " * ps, lon_cpt, Glon)
	gmt("pscoast -R -J -O -K -Dc -A5000 -Gc >> " * ps)
	gmt("grdimage -J -Clat.cpt -O -K -nl >> " * ps, Glat)
	gmt("pscoast -R -J -O -K -Q >> " * ps)
	gmt("pscoast -R -J -O -K -Dc -A5000 -Wthinnest >> " * ps)
	gmt("pstext -R -J -O -K -F+f32p,Helvetica-Bold,red=thinner >> " * ps, "0 20 12TH INTERNATIONAL")
	gmt("pstext -R -J -O -K -F+f32p,Helvetica-Bold,red=thinner >> " * ps, "0 -10 GMT CONFERENCE")
	gmt("pstext -R -J -O -F+f18p,Helvetica-Bold,green=thinnest >> " * ps, "0 -30 Honolulu, Hawaii, April 1, 2015")
	rm("lat.cpt")
end

# -----------------------------------------------------------------------------------------------------
function ex20()
	# Purpose:    Extend GMT to plot custom symbols
	# GMT progs:  pscoast, psxy

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex20/"
	ps = out_path * "example_20.ps"

	fogspots = [
		55.5	-21.0	0.25
		63.0	-49.0	0.25
		-12.0	-37.0	0.25
		-28.5	29.34	0.25
		48.4	-53.4	0.25
		155.5	-40.4	0.25
		-155.5	19.6	0.5
		-138.1	-50.9	0.25
		-153.5	-21.0	0.25
		-116.7	-26.3	0.25
		-16.5	64.4	0.25]

	gmt("pscoast -Rg -JR9i -Bx60 -By30 -B+t\"Hotspot Islands and Cities\" -Gdarkgreen -Slightblue -Dc -A5000 -K > " * ps)
	gmt("psxy -R -J -Skvolcano -O -K -Wthinnest -Gred >> " * ps, fogspots)

	# Overlay a few bullseyes at NY, Cairo, and Perth
	cities = [286 40.45 0.8; 31.15 30.03 0.8; 115.49 -31.58 0.8]
	gmt("psxy -R -J -Sk" * d_path * "bullseye -O >> " * ps, cities)
end

# -----------------------------------------------------------------------------------------------------
function ex22()
	# Purpose:    Automatic map of last 7 days of world-wide seismicity
	# GMT progs:  gmtset, pscoast, psxy, pslegend

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex22/"
	ps = out_path * "example_22.ps"

	gmt("gmtset FONT_ANNOT_PRIMARY 10p FONT_TITLE 18p FORMAT_GEO_MAP ddd:mm:ssF")

	# Get the data (-q quietly) from USGS using the wget (comment out in case
	# your system does not have wget or curl)
	# 
	# wget http://neic.usgs.gov/neis/gis/bulletin.asc -q -O neic_quakes.d
	# curl http://neic.usgs.gov/neis/gis/bulletin.asc -s > neic_quakes.d
	# 
	# Count the number of events (to be used in title later. one less due to header)

	# n=`cat neic_quakes.d | wc -l`
	# n=`expr $n - 1`
	n = 77
	
	# Pull out the first and last timestamp to use in legend title

	# first=`sed -n 2p neic_quakes.d | awk -F, '{printf "%s %s\n", $1, $2}'`
	# last=`sed -n '$p' neic_quakes.d | awk -F, '{printf "%s %s\n", $1, $2}'`
	first = "04/04/19 00:04:33"
	last  = "04/04/25 11:11:33"


	# Assign a string that contains the current user @ the current computer node.
	# Note that two @@ is needed to print a single @ in gmt pstext:

	# set me = "$user@@`hostname`"
	me = "GMT guru @@ GMTbox"

	# Create standard seismicity color table

	fid = open("neis.cpt","w")
	println(fid, "0	red	100	red")
	println(fid, "100	green	300	green")
	println(fid, "300	blue	10000	blue")
	close(fid)

	# Start plotting. First lay down map, then plot quakes with size = magintude/50":

	gmt("pscoast -Rg -JK180/9i -B45g30 -B+t\"World-wide earthquake activity\" -Gbrown" *
		" -Slightblue -Dc -A1000 -K -Y2.75i > " * ps)
	#gawk -F, "{ print $4, $3, $6, $5*0.02}" neic_quakes.d |
	t = gmt("gmtconvert -h " * d_path * "neic_quakes.d -i3,2,5,4")
	gmt("psxy -R -JK -O -K -Cneis.cpt -Sci -Wthin >> " * ps, [t[:,1:3] t[:,4]*0.02])

	# Create legend input file for NEIS quake plot
	neis_legend = Any[
	 @sprintf("H 16 1 %d events during %s to %s", n, first, last)
	 "D 0 1p"
	 "N 3"
	 "V 0 1p"
	 "S 0.1i c 0.1i red 0.25p 0.2i Shallow depth (0-100 km)"
	 "S 0.1i c 0.1i green 0.25p 0.2i Intermediate depth (100-300 km)"
	 "S 0.1i c 0.1i blue 0.25p 0.2i Very deep (> 300 km)"
	 "D 0 1p"
	 "V 0 1p"
	 "N 7"
	 "V 0 1p"
	 "S 0.1i c 0.06i - 0.25p 0.3i M 3"
	 "S 0.1i c 0.08i - 0.25p 0.3i M 4"
	 "S 0.1i c 0.10i - 0.25p 0.3i M 5"
	 "S 0.1i c 0.12i - 0.25p 0.3i M 6"
	 "S 0.1i c 0.14i - 0.25p 0.3i M 7"
	 "S 0.1i c 0.16i - 0.25p 0.3i M 8"
	 "S 0.1i c 0.18i - 0.25p 0.3i M 9"
	 "D 0 1p"
	 "V 0 1p"
	 "N 1"
	 # Put together a reasonable legend text, and add logo and user's name:
	 "G 0.25"
	 "P"
	 "T USGS/NEIS most recent earthquakes for the last seven days. The data were"
	 "T obtained automatically from the USGS Earthquake Hazards Program page at"
	 "T @_http://neic/usgs.gov @_. Interested users may also receive email alerts"
	 "T from the USGS."
	 "T This script can be called daily to update the latest information."
	 "G 0.4i"
	 # Add USGS logo
	 "I " * d_path * "USGS.ras 1i RT"
	 "G -0.3i"
	 @sprintf("L 12 6 LB %s", me)];
	 
	# OK, now we can actually run gmt pslegend.  We center the legend below the map.
	# Trial and error shows that 1.7i is a good legend height:

	gmt("pslegend -DJBC+o0/0.4i+w7i/1.7i -R -J -O -F+p+glightyellow >> " * ps, neis_legend)
	rm("gmt.conf");		rm("neis.cpt");
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
function ex24()
	# Purpose:   Display distribution of antipode types
	# GMT progs: gmtset, grdlandmask, grdmath, grd2xyz, gmtmath, grdimage, pscoast, pslegend

	# Create D minutes global grid with -1 over oceans and +1 over land
	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex24/"
	ps = out_path * "example_24.ps"

	# Currently there is no way of avoiding creating files for this
	fid = open("dateline.d", "w");
	println(fid, "> Our proxy for the dateline");
	println(fid, "180 0")
	println(fid, "180 -90")
	close(fid)

	fid = open("point.d", "w");		println(fid, "147:13 -42:48 6000 Hobart");	close(fid);

	R = gmt("info -I10 " * d_path * "oz_quakes.d");
	gmt("pscoast " * R[1] * " -JM9i -K -Gtan -Sdarkblue -Wthin,white -Dl -A500 -Ba20f10g10 -BWeSn > " * ps)
	gmt("psxy -R -J -O -K " * d_path * "oz_quakes.d -Sc0.05i -Gred >> " * ps)
	t = gmt("gmtselect " * d_path * "oz_quakes.d -L1000k/dateline.d -Nk/s -C3000k/point.d -fg -R -Il")
	gmt("psxy -R -JM -O -K -Sc0.05i -Ggreen >> " * ps, t)
	gmt("psxy point.d -R -J -O -K -SE- -Wfat,white >> " * ps)
	gmt("pstext -R -J -O -K -F+f14p,Helvetica-Bold,white+jLT -D0.1i/-0.1i >> " * ps, "147:13 -42:48 Hobart")
	gmt("psxy -R -J -O -K point.d -Wfat,white -S+0.2i >> " * ps)
	gmt("psxy dateline.d -R -J -O -Wfat,white -A >> " * ps)
	rm("point.d");	rm("dateline.d");

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
