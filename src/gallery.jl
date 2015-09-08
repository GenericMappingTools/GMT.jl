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
function ex26()
	# Purpose:   Demonstrate general vertical perspective projection
	# GMT progs: pscoast

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex26/"
	ps = out_path * "example_26.ps"

	# first do an overhead of the east coast from 160 km altitude point straight down
	lat = 41.5;	lon = -74;	alt = 160;	tilt = 0;	azim = 0;	twist = 0;	width = 0;	height = 0;
	PROJ = @sprintf("-JG%f/%f/%f/%f/%f/%f/%f/%f/4i", lon, lat, alt, azim, tilt, twist, width, height)
	gmt("pscoast -Rg " * PROJ * " -X1i -B5g5 -Glightbrown -Slightblue -W -Dl -N1/1p,red -N2,0.5p -P -K -Y5i > " * ps)

	# Now point from an altitude of 160 km with a specific tilt and azimuth and with a wider restricted
	# view and a boresight twist of 45 degrees
	tilt=55;	azim=210;	twist=45;	width=30;	height=30;
	PROJ = @sprintf("-JG%f/%f/%f/%f/%f/%f/%f/%f/5i", lon, lat, alt, azim, tilt, twist, width, height)
	gmt("pscoast -Rg " * PROJ * " -B5g5 -Glightbrown -Slightblue -W -Ia/blue -Di -Na -O -X1i -Y-4i >> " * ps)
end

# -----------------------------------------------------------------------------------------------------
function ex27()
	# Purpose:   Illustrates how to plot Mercator img grids
	# GMT progs: makecpt, mapproject, grdgradient, grdimage, grdinfo, pscoast, img2grd (suppl)

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex27/"
	ps = out_path * "example_27.ps"

	# Gravity in tasman_grav.nc is in 0.1 mGal increments and the grid
	# is already in projected Mercator x/y units. First get gradients.
	Gtasman_grav_i = gmt("grdgradient " * d_path * "tasman_grav.nc -Nt1 -A45 -G");

	# Make a suitable cpt file for mGal
	grav_cpt = gmt("makecpt -T-120/120/240 -Z -Crainbow")

	# Since this is a Mercator grid we use a linear projection
	gmt("grdimage " * d_path * "tasman_grav.nc=ns/0.1 -I -Jx0.25i -C -P -K > " * ps, Gtasman_grav_i, grav_cpt)

	# Then use gmt pscoast to plot land; get original -R from grid remark
	# and use Mercator gmt projection with same scale as above on a spherical Earth

	R = gmt("grdinfo " * d_path * "tasman_grav.nc");
	# Here we need to fish the last word of the third (the 'Remark') line issued by grdinfo
	R = R[3];	k = length(R);
	while (R[k] != ' ')
		k = k - 1;
	end
	R = R[k+1:end];		# The result must be -R145/170/-50.0163575733/-24.9698584055
	gmt("pscoast " * R * " -Jm0.25i -Ba10f5 -BWSne -O -K -Gblack --PROJ_ELLIPSOID=Sphere" *
		" -Cwhite -Dh+ --FORMAT_GEO_MAP=dddF >> " * ps)

	# Put a color legend in top-left corner of the land mask
	gmt("psscale -DjTL+o1c+w2i/0.15i " * R * " -J -C -Bx50f10 -By+lmGal -I -O -F+gwhite+p1p >> " * ps, grav_cpt)
end

# -----------------------------------------------------------------------------------------------------
function ex28()
	# Purpose:   Illustrates how to mix UTM data and UTM gmt projection
	# GMT progs: makecpt, grdgradient, grdimage, grdinfo, grdmath, pscoast, pstext, mapproject

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex28/"
	ps = out_path * "example_28.ps"

	# Get intensity grid and set up a color table
	GKilauea_utm_i = gmt("grdgradient " * d_path * "Kilauea.utm.nc -Nt1 -A45 -G")
	Kilauea_cpt = gmt("makecpt -Ccopper -T0/1500/100 -Z")
	# Lay down the UTM topo grid using a 1:16,000 scale
	gmt("grdimage " * d_path * "Kilauea.utm.nc -I -C -Jx1:160000 -P -K" *
		" --FORMAT_FLOAT_OUT=%.10g --FONT_ANNOT_PRIMARY=9p > " * ps, GKilauea_utm_i, Kilauea_cpt)
	# Overlay geographic data and coregister by using correct region and gmt("projection with the same scale
	gmt("pscoast -R" * d_path * "Kilauea.utm.nc -Ju5Q/1:160000 -O -K -Df+ -Slightblue -W0.5p -B5mg5m -BNE" *
		" --FONT_ANNOT_PRIMARY=12p --FORMAT_GEO_MAP=ddd:mmF >> " * ps)
	gmt("pstext -R -J -O -K -F+f12p,Helvetica-Bold+jCB >> " * ps, "155:16:20W 19:26:20N KILAUEA")
	gmt("psbasemap -R -J -O -K --FONT_ANNOT_PRIMARY=9p -Lg155:07:30W/19:15:40N+c19:23N+jTC+f+w5k+l1:16,000+u" *
		" --FONT_LABEL=10p >> " * ps)
	# Annotate in km but append ,000m to annotations to get customized meter labels
	gmt("psbasemap -R" * d_path * "Kilauea.utm.nc+Uk -Jx1:160 -B5g5+u\"@:8:000m@::\"" * 
		" -BWSne -O --FONT_ANNOT_PRIMARY=10p --MAP_GRID_CROSS_SIZE_PRIMARY=0.1i --FONT_LABEL=10p >> " * ps)
end

# -----------------------------------------------------------------------------------------------------
function ex29()
	# Purpose:   Illustrates spherical surface gridding with Green's function of splines
	# GMT progs: makecpt, grdcontour, grdgradient, grdimage, grdmath greenspline, psscale, pstext

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex29/"
	ps = out_path * "example_29.ps"

	# This example uses 370 radio occultation data for Mars to grid the topography.
	# Data and information from Smith, D. E., and M. T. Zuber (1996), The shape of
	# Mars and the topographic signature of the hemispheric dichotomy, Science, 271, 184-187.

	# Make Mars PROJ_ELLIPSOID given their three best-fitting axes:
	a = 3399.472;	b = 3394.329;	c = 3376.502;

	#Gproj_ellipsoid = gmt(@sprintf("grdmath -Rg -I4 -r X COSD %f DIV DUP MUL X SIND %f DIV DUP MUL" *
	#	" ADD Y COSD DUP MUL MUL Y SIND %f DIV DUP MUL ADD SQRT INV =", a, b, c))
	# It doesn't let me break the @sprintf call !!!
	Gproj_ellipsoid = gmt("grdmath -Rg -I4 -r X COSD " * "$a" * " DIV DUP MUL X SIND " * "$b" * 
		" DIV DUP MUL ADD Y COSD DUP MUL MUL Y SIND " * "$c" * " DIV DUP MUL ADD SQRT INV =")
	#  Do both Parker and Wessel/Becker solutions (tension = 0.9975)
	Gmars  = gmt("greenspline -R\$ " * d_path * "mars370.in -D4 -Sp -G", Gproj_ellipsoid);
	Gmars2 = gmt("greenspline -R\$ " * d_path * "mars370.in -D4 -Sq0.9975 -G", Gproj_ellipsoid);
	# Scale to km and remove PROJ_ELLIPSOID
	Gmars  = gmt("grdmath \$ 1000 DIV \$ SUB =", Gmars,  Gproj_ellipsoid)
	Gmars2 = gmt("grdmath \$ 1000 DIV \$ SUB =", Gmars2, Gproj_ellipsoid)
	mars_cpt = gmt("makecpt -Crainbow -T-7/15/22 -Z");
	Gmars2_i = gmt("grdgradient -fg -Ne0.75 -A45 -G", Gmars2)
	gmt("grdimage -I -C -B30g30 -BWsne -JH0/7i -P -K -E200" *
		" --FONT_ANNOT_PRIMARY=12p -X0.75i > " * ps, Gmars2_i, mars_cpt, Gmars2)
	gmt("grdcontour -J -O -K -C1 -A5 -Glz+/z- >> " * ps, Gmars2)
	gmt("psxy -Rg -J -O -K -Sc0.045i -Gblack " * d_path * "mars370.in  >> " * ps)
	gmt("pstext -R -J -O -K -N -D-3.5i/-0.2i -F+f14p,Helvetica-Bold+jLB >> " * ps, "0 90 b)")
	Gmars_i = gmt("grdgradient -fg -Ne0.75 -A45 -G", Gmars);
	gmt("grdimage -I -C -B30g30 -BWsne -J -O -K -Y4.2i -E200" *
		" --FONT_ANNOT_PRIMARY=12p >> " * ps, Gmars_i, mars_cpt, Gmars)
	gmt("grdcontour -J -O -K -C1 -A5 -Glz+/z- >> " * ps, Gmars)
	gmt("psxy -Rg -J -O -K -Sc0.045i -Gblack " * d_path * "mars370.in  >> " * ps)
	gmt("psscale -C -O -K -R -J -DJBC+o0/0.15i+w6i/0.1i+h -I --FONT_ANNOT_PRIMARY=12p -Bx2f1 -By+lkm >> " * ps, mars_cpt)
	gmt("pstext -R -J -O -N -D-3.5i/-0.2i -F+f14p,Helvetica-Bold+jLB >> " * ps, "0 90 a)")
end

# -----------------------------------------------------------------------------------------------------
function ex30()
	# Purpose:   Show graph mode and math angles
	# GMT progs: gmtmath, psbasemap, pstext and psxy

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex30/"
	ps = out_path * "example_30.ps"

	gmt("psbasemap -R0/360/-1.25/1.75 -JX8i/6i -Bx90f30+u\"\\312\" -By1g10 -BWS+t\"Two Trigonometric Functions\"" *
		" -K --MAP_FRAME_TYPE=graph --MAP_VECTOR_SHAPE=0.5 > " * ps)

	#Draw sine an cosine curves
	t = gmt("gmtmath -T0/360/0.1 T COSD =");
	gmt("psxy -R -J -O -K -W3p >>  " * ps, t)
	t = gmt("gmtmath -T0/360/0.1 T SIND =");
	gmt("psxy -R -J -O -K -W3p,0_6:0 --PS_LINE_CAP=round >> " * ps, t)

	# Indicate the x-angle = 120 degrees
	gmt("psxy   -R -J -O -K -W0.5p,- >> " * ps, [120 -1.25; 120 1.25])
	gmt("pstext -R -J -O -K -Dj0.2c -N -F+f+j >> " * ps, Any[
		"360 1 18p,Times-Roman RB x = cos(@%12%a@%%)"
		"360 0 18p,Times-Roman RB y = sin(@%12%a@%%)"
		"120 -1.25 14p,Times-Roman LB 120\\312"
		"370 -1.35 24p,Symbol LT a"
		"-5 1.85 24p,Times-Roman RT x,y"])

	# Draw a circle and indicate the 0-70 degree angle
	gmt("psxy -R-1/1/-1/1 -Jx1.5i -O -K -X3.625i -Y2.75i -Sc2i -W1p -N >> " * ps, [0 0])
	gmt("psxy -R-1/1/-1/1 -J -O -K -W1p >> " * ps,
		[
		NaN NaN
# 		> x-gridline  -Wdefault
		-1 0
		1 0
		NaN NaN
# 		> y-gridline  -Wdefault
		0 -1
		0 1
		NaN NaN
# 		> angle = 0
		0 0
		1 0
		NaN NaN
# 		> angle = 120
		0 0
		-0.5 0.866025
		NaN NaN
# 		> x-gmt projection -W2p
		-0.3333	0
		0	0
		NaN NaN
# 		> y-gmt projection -W2p
		-0.3333 0.57735
		-0.3333 0])

	gmt("pstext -R-1/1/-1/1 -J -O -K -Dj0.05i -F+f+a+j >> " * ps, Any[
		"-0.16666 0 12p,Times-Roman 0 CT x"
		"-0.3333 0.2888675 12p,Times-Roman 0 RM y"
		"0.22 0.27 12p,Symbol -30 CB a"
		"-0.33333 0.6 12p,Times-Roman 30 LB 120\\312"])

	gmt("psxy -R -J -O -Sm0.15i+e -W1p -Gblack >> " * ps, [0 0 1.26 0 120])

end

# -----------------------------------------------------------------------------------------------------
function ex33()
	# Purpose:   Show graph mode and math angles
	# GMT progs: gmtmath, psbasemap, pstext and psxy

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex33/"
	ps = out_path * "example_33.ps"

	# Extract a subset of ETOPO1m for the East Pacific Rise
	# gmt grdcut etopo1m_grd.nc -R118W/107W/49S/42S -Gspac.nc
	z_cpt = gmt("makecpt -Crainbow -T-5000/-2000/500 -Z");
	Gspac_int = gmt("grdgradient " * d_path * "spac.nc -A15 -Ne0.75 -G");
	gmt("grdimage " * d_path * "spac.nc -I -C -JM6i -P -Baf -K -Xc --FORMAT_GEO_MAP=dddF > " * ps, Gspac_int, z_cpt)
	# Select two points along the ridge
	ridge_pts = [-111.6 -43.0; -113.3 -47.5];
	# Plot ridge segment and end points
	gmt("psxy -R" * d_path * "spac.nc -J -O -K -W2p,blue >> " * ps, ridge_pts)
	gmt("psxy -R -J -O -K -Sc0.1i -Gblue >> " * ps, ridge_pts)
	# Generate cross-profiles 400 km long, spaced 10 km, samped every 2km
	# and stack these using the median, write stacked profile
	table = gmt("grdtrack -G" * d_path * "spac.nc -C400k/2k/10k -Sm+sstack.txt", ridge_pts)
	gmt("psxy -R -J -O -K -W0.5p >> " * ps, table)
	# Show upper/lower values encountered as an envelope
	env = gmt("gmtconvert stack.txt -o0,5");
	env = [env; gmt("gmtconvert stack.txt -o0,6 -I -T")];		# Concat the two matrices
	gmt("psxy -R-200/200/-3500/-2000 -Bxafg1000+l\"Distance from ridge (km)\" -Byaf+l\"Depth (m)\" -BWSne" *
		" -JX6i/3i -O -K -Glightgray -Y6.5i >> " * ps, env)
	gmt("psxy -R -J -O -K -W3p stack.txt >> " * ps)
	gmt("pstext -R -J -O -K -Gwhite -F+jTC+f14p -Dj0.1i >> " * ps, "0 -2000 MEDIAN STACKED PROFILE")
	gmt("psxy -R -J -O -T >> " * ps)
	rm("stack.txt")
end

# -----------------------------------------------------------------------------------------------------
function ex34()
	# Purpose:   Illustrate pscoast with DCW country polygons
	# GMT progs: pscoast, makecpt, grdimage, grdgradient

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex34/"
	ps = out_path * "example_34.ps"

	gmt("gmtset FORMAT_GEO_MAP dddF")
	gmt("pscoast -JM4.5i -R-6/20/35/52 -EFR,IT+gP300/8 -Glightgray -Baf -BWSne -P -K -X2i > " * ps)
	# Extract a subset of ETOPO2m for this part of Europe
	# gmt grdcut etopo2m_grd.nc -R -GFR+IT.nc=ns
	z_cpt = gmt("makecpt -Cglobe -T-5000/5000/500 -Z")
	FR_IT_int = gmt("grdgradient " * d_path * "FR+IT.nc -A15 -Ne0.75 -G")
	gmt("grdimage " * d_path * "FR+IT.nc -I -C -J -O -K -Y4.5i" *
		" -Baf -BWsnE+t\"Franco-Italian Union, 2042-45\" >> " * ps, FR_IT_int, z_cpt)
	gmt("pscoast -J -R -EFR,IT+gred@60 -O >> " * ps)
	rm("gmt.conf")

end

# -----------------------------------------------------------------------------------------------------
function ex35()
	# Purpose:   Illustrate pscoast with DCW country polygons
	# GMT progs: pscoast, makecpt, grdimage, grdgradient

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex35/"
	ps = out_path * "example_35.ps"

	# Get the crude GSHHS data, select GMT format, and decimate to ~20%:
	# gshhs $GMTHOME/src/coast/gshhs/gshhs_c.b | $AWK '{if ($1 == ">" || NR%5 == 0) print $0}' > gshhs_c.txt
	# Get Voronoi polygons
	tt_pol = gmt("sphtriangulate " * d_path * "gshhs_c.txt -Qv -D -Ntt.pol");
	# Compute distances in km
	Gtt = gmt("sphdistance -Rg -I1 -Q\$ -Ntt.pol -G -Lk", tt_pol)
	t_cpt = gmt("makecpt -Chot -T0/3500/500 -Z")
	# Make a basic image plot and overlay contours, Voronoi polygons and coastlines
	gmt("grdimage -JG-140/30/7i -P -K -C -X0.75i -Y2i > " * ps, t_cpt, Gtt)
	gmt("grdcontour -J -O -K -C500 -A1000+f10p,Helvetica,white -L500" *
		" -GL0/90/203/-10,175/60/170/-30,-50/30/220/-5 -Wa0.75p,white -Wc0.25p,white >> " * ps, Gtt)
	gmt("psxy -R -J -O -K -W0.25p,green,. >> " * ps, tt_pol)
	gmt("pscoast -R -J -O -W1p -Gsteelblue -A0/1/1 -B30g30 -B+t\"Distances from GSHHG crude coastlines\" >> " * ps)
	rm("tt.pol")

end

# -----------------------------------------------------------------------------------------------------
function ex36()
	# Purpose:   Illustrate pscoast with DCW country polygons
	# GMT progs: pscoast, makecpt, grdimage, grdgradient

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex36/"
	ps = out_path * "example_36.ps"

	# Interpolate data of Mars radius from Mariner9 and Viking Orbiter spacecrafts
	tt_cpt = gmt("makecpt -Crainbow -T-7000/15000/1000 -Z")
	# Piecewise linear interpolation; no tension
	Gtt = gmt("sphinterpolate " * d_path * "mars370.txt -Rg -I1 -Q0 -G")
	gmt("grdimage -JH0/6i -Bag -C -P -Xc -Y7.25i -K > " * ps, tt_cpt, Gtt)
	gmt("psxy -Rg -J -O -K " * d_path * "mars370.txt -Sc0.05i -G0 -B30g30 -Y-3.25i >> " * ps)
	# Smoothing
	Gtt = gmt("sphinterpolate " * d_path * "mars370.txt -Rg -I1 -Q3 -G")
	gmt("grdimage -J -Bag -C -Y-3.25i -O -K >> " * ps, tt_cpt, Gtt)
	gmt("psxy -Rg -J -O -T >> " * ps)

end

# -----------------------------------------------------------------------------------------------------
function ex37()
	# Purpose:   Illustrate pscoast with DCW country polygons
	# GMT progs: pscoast, makecpt, grdimage, grdgradient

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex37/"
	ps = out_path * "example_37.ps"

	# Testing gmt grdfft coherence calculation with Karen Marks example data
	G = d_path * "grav.V18.par.surf.1km.sq.nc"
	T = d_path * "mb.par.surf.1km.sq.nc"
	gmt("gmtset FONT_TITLE 14p")

	z_cpt  = gmt("makecpt -Crainbow -T-5000/-3000/100 -Z")
	g_cpt  = gmt("makecpt -Crainbow -T-50/25/5 -Z")
	bbox   = gmt("grdinfo -Ib " * T)
	GG_int = gmt("grdgradient -A0 -Nt1 -G " * G)
	GT_int = gmt("grdgradient -A0 -Nt1 -G " * T)
	scl    = "1.4e-5"
	sclkm  = "1.4e-2"
	gmt("grdimage " * T * " -I -Jx" * scl *"i -C -P -K -X1.474i -Y1i > " * ps, GT_int, z_cpt)
	gmt("psbasemap -R-84/75/-78/81 -Jx" * sclkm *"i -O -K -Ba -BWSne+t\"Multibeam bathymetry\" >> " * ps)
	gmt("grdimage " * G * " -I -Jx" * scl *"i -C -O -K -X3.25i >> " * ps, GG_int, g_cpt)
	gmt("psbasemap -R-84/75/-78/81 -Jx" * sclkm *"i -O -K -Ba -BWSne+t\"Satellite gravity\" >> " * ps)

	cross = gmt("grdfft " * T * " " * G * " -Ewk -N192/192+d+wtmp")			# <---- ERRORS HERE
	GG_tmp_int = gmt("grdgradient " * G[1:end-3] * "_tmp.nc -A0 -Nt1 -G")
	GT_tmp_int = gmt("grdgradient " * T[1:end-3] * "_tmp.nc -A0 -Nt1 -G")

	z_cpt = gmt("makecpt -Crainbow -T-1500/1500/100 -Z")
	g_cpt = gmt("makecpt -Crainbow -T-40/40/5 -Z")

	gmt("grdimage " * T[1:end-3] * "_tmp.nc -I -Jx" * scl *"i -C -O -K -X-3.474i -Y3i >> " * ps, GT_tmp_int, z_cpt)
	gmt("psxy -R" * T[1:end-3] * "_tmp.nc -J -O -K -L -W0.5p,- >> " * ps, bbox)
	gmt("psbasemap -R-100/91/-94/97 -Jx" * sclkm *"i -O -K -Ba -BWSne+t\"Detrended and extended\" >> " * ps)

	gmt("grdimage " * G[1:end-3] * "_tmp.nc -I -Jx" * scl *"i -C -O -K -X3.25i >> " * ps, GG_tmp_int, g_cpt)
	gmt("psxy -R" * G[1:end-3] * "_tmp.nc -J bbox -O -K -L -W0.5p,- >> " * ps)
	gmt("psbasemap -R-100/91/-94/97 -Jx" * sclkm *"i -O -K -Ba -BWSne+t\"Detrended and extended\" >> " * ps)
 
 	gmt("gmtset FONT_TITLE 24p")
	gmt("psxy -R2/160/0/1 -JX-6il/2.5i -Bxa2f3g3+u\" km\" -Byafg0.5+l\"Coherency@+2@+\"" *
		" -BWsNe+t\"Coherency between gravity and bathymetry\" -O -K -X-3.25i -Y3.3i -i0,15 -W0.5p >> " * ps, cross)
	gmt("psxy -R -J -O -K -i0,15,16 -Sc0.075i -Gred -W0.25p -Ey >> " * ps, cross)
 	gmt("psxy -R -J -O -T >> " * ps)
end

# -----------------------------------------------------------------------------------------------------
function ex38()
	# Purpose:   Illustrate histogram equalization on topography grids
	# GMT progs: psscale, pstext, makecpt, grdhisteq, grdimage, grdinfo, grdgradientt

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex38/"
	ps = out_path * "example_38.ps"

	t_cpt = gmt("makecpt -Crainbow -T0/1700/100 -Z");
	c_cpt = gmt("makecpt -Crainbow -T0/15/1");
	Gitopo = gmt("grdgradient " * d_path * "topo.nc -Nt1 -fg -A45 -G")
	Gout  = gmt("grdhisteq " * d_path * "topo.nc -G -C16")
	gmt("grdimage " * d_path * "topo.nc -I -C -JM3i -Y5i -K -P -B5 -BWSne > " * ps, Gitopo, t_cpt)
	gmt("pstext -R" * d_path * "topo.nc -J -O -K -F+jTR+f14p -T -Gwhite -W1p -Dj0.1i >> " * ps, "315 -10 Original")
	gmt("grdimage -C -J -X3.5i -K -O -B5 -BWSne >> " * ps, c_cpt, Gout)
	gmt("pstext -R -J -O -K -F+jTR+f14p -T -Gwhite -W1p -Dj0.1i >> " * ps, "315 -10 Equalized")
	gmt("psscale -Dx0i/-0.4i+jTC+w5i/0.15i+h+e+n -O -K -C -Ba500 -By+lm >> " * ps, t_cpt)
	Gout = gmt("grdhisteq " * d_path * "topo.nc -G -N")
	c_cpt = gmt("makecpt -Crainbow -T-3/3/0.1 -Z")
	gmt("grdimage -C -J -X-3.5i -Y-3.3i -K -O -B5 -BWSne >> " * ps, c_cpt, Gout)
	gmt("pstext -R -J -O -K -F+jTR+f14p -T -Gwhite -W1p -Dj0.1i >> " * ps, "315 -10 Normalized")
	Gout = gmt("grdhisteq " * d_path * "topo.nc -G -N")
	gmt("grdimage -C -J -X3.5i -K -O -B5 -BWSne >> " * ps, c_cpt, Gout)
	gmt("pstext -R -J -O -K -F+jTR+f14p -T -Gwhite -W1p -Dj0.1i >> " * ps, "315 -10 Quadratic")
	gmt("psscale -Dx0i/-0.4i+w5i/0.15i+h+jTC+e+n -O -C -Bx1 -By+lz >> " * ps, c_cpt)
end

# -----------------------------------------------------------------------------------------------------
function ex39()
	# Purpose:   Illustrate evaluation of spherical harmonic coefficients
	# GMT progs: psscale, pstext, makecpt, grdimage, grdgradient, sph2grd

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex39/"
	ps = out_path * "example_39.ps"

	# Evaluate the first 180, 90, and 30 order/degrees of Venus spherical
	# harmonics topography model, skipping the L = 0 term (radial mean).
	# File truncated from http://www.ipgp.fr/~wieczor/SH/VenusTopo180.txt.zip
	# Wieczorek, M. A., Gravity and topography of the terrestrial planets,
	#   Treatise on Geophysics, 10, 165-205, doi:10.1016/B978-044452748-6/00156-5, 2007

	Gv1 = gmt("sph2grd " * d_path * "VenusTopo180.txt -I1 -Rg -Ng -G -F1/1/25/30")
	Gv2 = gmt("sph2grd " * d_path * "VenusTopo180.txt -I1 -Rg -Ng -G -F1/1/85/90")
	Gv3 = gmt("sph2grd " * d_path * "VenusTopo180.txt -I1 -Rg -Ng -G -F1/1/170/180")
	t_cpt = gmt("grd2cpt -Crainbow -E16 -Z", Gv3)
	Gvint = gmt("grdgradient -Nt0.75 -A45 -G", Gv1)
	gmt("grdimage -I -JG90/30/5i -P -K -Bg -C -X3i -Y1.1i > " * ps, Gvint, t_cpt, Gv1)
	gmt("pstext -R0/6/0/6 -Jx1i -O -K -Dj0.2i -F+f16p+jLM -N >> " * ps, "4 4.5 L = 30")
	gmt("psscale --FORMAT_FLOAT_MAP=\"%g\" -C -O -K -Dx1.25i/-0.2i+jTC+w5.5i/0.1i+h -Bxaf -By+lm >> " * ps, t_cpt)
	Gvint = gmt("grdgradient -Nt0.75 -A45 -G", Gv2)
	gmt("grdimage -I -JG -O -K -Bg -C -X-1.25i -Y1.9i >> " * ps, Gvint, t_cpt, Gv2)
	gmt("pstext -R0/6/0/6 -Jx1i -O -K -Dj0.2i -F+f16p+jLM -N >> " * ps, "4 4.5 L = 90")
	Gv3 = gmt("sph2grd " * d_path * "VenusTopo180.txt -I1 -Rg -Ng -G -F1/1/170/180")
	Gvint = gmt("grdgradient -Nt0.75 -A45 -G", Gv3)
	gmt("grdimage -I -JG -O -K -Bg -C -X-1.25i -Y1.9i >> " * ps, Gvint, t_cpt, Gv3)
	gmt("pstext -R0/6/0/6 -Jx1i -O -K -Dj0.2i -F+f16p+jLM -N >> " * ps, "4 4.5 L = 180")
	gmt("pstext -R0/6/0/6 -Jx1i -O -F+f24p+jCM -N >> " * ps, "3.75 5.4 Venus Spherical Harmonic Model")
end

# -----------------------------------------------------------------------------------------------------
function ex40()
	# Purpose:   Illustrate evaluation of spherical harmonic coefficients
	# GMT progs: psscale, pstext, makecpt, grdimage, grdgradient, sph2grd

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex40/"
	ps = out_path * "example_40.ps"

	centroid = gmt("gmtspatial " * d_path * "GSHHS_h_Australia.txt -fg -Qk")
	#centroid = [133.913549887 -22.9337944115 7592694.55567]
	gmt("psbasemap -R112/154/-40/-10 -JM5.5i -P -K -B20 -BWSne+g240/255/240 -Xc > " * ps)
	gmt("psxy " * d_path * "GSHHS_h_Australia.txt -R -J -O -Wfaint -G240/240/255 -K >> " * ps)
	gmt("psxy " * d_path * "GSHHS_h_Australia.txt -R -J -O -Sc0.01c -Gred -K >> " * ps)
	T500k = gmt("gmtsimplify " * d_path * "GSHHS_h_Australia.txt -T500k");
	t = gmt("gmtspatial " * d_path * "GSHHS_h_Australia.txt -fg -Qk");
	area = @sprintf("Full area = %.0f km@+2@+", t[3]);
	t = gmt("gmtspatial -fg -Qk", T500k); 
	area_T500k = @sprintf("Reduced area = %.0f km@+2@+", t[3]);
	gmt("psxy -R -J -O -K -W1p,blue >> " * ps, T500k)
	gmt("psxy -R -J -O -K -Sx0.3i -W3p >> " * ps, centroid)
	gmt("pstext -R -J -O -K -Dj0.1i/0.1i -F+jTL+f18p >> " * ps, "112 -10 T = 500 km")
	gmt("pstext -R -J -O -K -F+14p+cCM >> " * ps, area)
	gmt("pstext -R -J -O -K -F+14p+cLB -Dj0.2i >> " * ps, area_T500k)
	gmt("psbasemap -R -J -O -K -B20+lightgray -BWsne+g240/255/240 -Y4.7i >> " * ps)
	gmt("psxy " * d_path * "GSHHS_h_Australia.txt -R -J -O -Wfaint -G240/240/255 -K >> " * ps)
	gmt("psxy " * d_path * "GSHHS_h_Australia.txt -R -J -O -Sc0.01c -Gred -K >> " * ps)
	T100k = gmt("gmtsimplify " * d_path * "GSHHS_h_Australia.txt -T100k");
	t = gmt("gmtspatial -fg -Qk", T100k);
	area_T100k = @sprintf("Reduced area = %.0f km@+2@+", t[3]);
	gmt("psxy -R -J -O -K -W1p,blue >> " * ps, T100k)
	gmt("psxy -R -J -O -K -Sx0.3i -W3p >> " * ps, centroid)
	gmt("pstext -R -J -O -K -Dj0.1i/0.1i -F+jTL+f18p >> " * ps, "112 -10 T = 100 km")
	gmt("pstext -R -J -O -K -F+14p+cCM >> " * ps, area)
	gmt("pstext -R -J -O -K -F+14p+cLB -Dj0.2i >> " * ps, area_T100k)
	gmt("psxy -R -J -O -T >> " * ps)
end

# -----------------------------------------------------------------------------------------------------
function ex41()
	# Purpose:   Illustrate typesetting of legend with table
	# GMT progs: pscoast, pslegend, psxy

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex41/"
	ps = out_path * "example_41.ps"

	gmt("gmtset FONT_ANNOT_PRIMARY 12p FONT_LABEL 12p")
	gmt("pscoast -R130W/50W/8N/56N -JM5.6i -B0 -P -K -Glightgray -Sazure1 -A1000 -Wfaint -Xc -Y1.2i --MAP_FRAME_TYPE=plain > " * ps)
	gmt("pscoast -R -J -O -K -EUS+glightyellow+pfaint -ECU+glightred+pfaint -EMX+glightgreen+pfaint -ECA+glightblue+pfaint >> " * ps)
	gmt("pscoast -R -J -O -K -N1/1p,darkred -A1000/2/2 -Wfaint -Cazure1 >> " * ps)
	gmt("psxy -R -J -O -K -Sk" * d_path * "my_symbol/0.1i -C" * d_path * "my_color.cpt -W0.25p -: " *
		d_path * "my_data.txt >> " * ps)
	gmt("pslegend -R0/6/0/9.1 -Jx1i -Dx3i/4.5i+w5.6i+jBC+l1.2 -C0.05i -F+p+gsnow1 -B0 -O " *
		d_path * "my_table.txt -X-0.2i -Y-0.2i >> " * ps)
	rm("gmt.conf")
end

# -----------------------------------------------------------------------------------------------------
function ex42()
	# Purpose:   Illustrate Antarctica and stereographic projection
	# GMT progs: makecpt, grdimage, pscoast, pslegend, psscale, pstext, psxy

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex42/"
	ps = out_path * "example_42.ps"

	gmt("set FONT_ANNOT_PRIMARY 12p FONT_LABEL 12p PROJ_ELLIPSOID WGS-84 FORMAT_GEO_MAP dddF")
	# Data obtained via website and converted to netCDF thus:
	# curl http://www.antarctica.ac.uk//bas_research/data/access/bedmap/download/bedelev.asc.gz
	# gunzip bedelev.asc.gz
	# grdreformat bedelev.asc BEDMAP_elevation.nc=ns -V
	gmt("makecpt -Cbathy -T-7000/0/200 -N -Z > t.cpt")			# How to combine CPT objects?
	gmt("makecpt -Cdem4 -T0/4000/200 -N -Z >> t.cpt")
	gmt("grdimage -Ct.cpt " * d_path * "BEDMAP_elevation.nc -Jx1:60000000 -Q -P -K > " * ps)
	gmt("pscoast -R-180/180/-90/-60 -Js0/-90/-71/1:60000000 -Bafg -Di -W0.25p -O -K >> " * ps)
	gmt("psscale -Ct.cpt -DjRM+w2.5i/0.2i+o0.5i/0+jLM+mc -R -J -O -K -F+p+i -Bxa1000+lELEVATION -By+lm >> " * ps)
	# GSHHG
	gmt("pscoast -R-180/180/-90/-60 -J -Di -Glightblue -Sroyalblue2 -O -K -X2i -Y4.75i >> " * ps)
	gmt("pscoast -R-180/180/-90/-60 -J -Di -Glightbrown -O -K -A+ag -Bafg >> " * ps)
	gmt("pslegend -DjLM+w1.7i+jRM+o0.5i/0 -R-180/180/-90/-60 -J -O -K -F+p+i >> " * ps, Any[
		"H 18 Times-Roman Legend"
		"D 0.1i 1p"
		"S 0.15i s 0.2i blue  0.25p 0.3i Ocean"
		"S 0.15i s 0.2i lightblue  0.25p 0.3i Ice front"
		"S 0.15i s 0.2i lightbrown  0.25p 0.3i Grounding line"])

	# Fancy line
	gmt("psxy -R0/7.5/0/10 -Jx1i -O -K -B0 -W2p -X-2.5i -Y-5.25i >> " * ps,
		[0 5.55
		2.5 5.55
		5.0 4.55
		7.5 4.55])

	gmt("pstext -R0/7.5/0/10 -J -O -F+f18p+jBL -Dj0.1i/0 >> " * ps, Any["0 5.2 BEDMAP" "0 9.65 GSHHG"])
	rm("gmt.conf");	rm("t.cpt");
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
function ex45()
	# Purpose:   Illustrate Antarctica and stereographic projection
	# GMT progs: makecpt, grdimage, pscoast, pslegend, psscale, pstext, psxy

	global g_root_dir, out_path
	d_path = g_root_dir * "doc/examples/ex45/"
	ps = out_path * "example_45.ps"

	# Basic LS line y = a + bx
	model = gmt("trend1d -Fxm " * d_path * "CO2.txt -Np1")
	gmt("psxy -R1958/2016/310/410 -JX6i/1.9i -P -Bxaf -Byaf+u\" ppm\" -BWSne+gazure1 -Sc0.05c -Gred -K " *
		d_path * "CO2.txt -X1.5i > " * ps)
	gmt("psxy -R -J -O -K -W0.5p,blue >> " * ps, model)
	gmt("pstext -R -J -O -K -F+f12p+cTL -Dj0.1i -Glightyellow >> " * ps, "m@-2@-(t) = a + b\\264t")
	# Basic LS line y = a + bx + cx^2
	model = gmt("trend1d -Fxm " * d_path * "CO2.txt -Np2")
	gmt("psxy -R -J -O -Bxaf -Byaf+u\" ppm\" -BWSne+gazure1 -Sc0.05c -Gred -K " * d_path * "CO2.txt -Y2.3i >> " * ps)
	gmt("psxy -R -J -O -K -W0.5p,blue >> " * ps, model)
	gmt("pstext -R -J -O -K -F+f12p+cTL -Dj0.1i -Glightyellow >> " * ps, "m@-3@-(t) = a + b\\264t + c\\264t@+2@+")
	# Basic LS line y = a + bx + cx^2 + seasonal change
	model = gmt("trend1d -Fxmr " * d_path * "CO2.txt -Np2,f1+o1958+l1")
	gmt("psxy -R -J -O -Bxaf -Byaf+u\" ppm\" -BWSne+gazure1 -Sc0.05c -Gred -K " * d_path * "CO2.txt -Y2.3i >> " * ps)
	gmt("psxy -R -J -O -K -W0.25p,blue >> " * ps, model)
	gmt("pstext -R -J -O -K -F+f12p+cTL -Dj0.1i -Glightyellow >> " * ps,
		"m@-5@-(t) = a + b\\264t + c\\264t@+2@+ + d\\264cos(2@~p@~t) + e\\264sin(2@~p@~t)")
	# Plot residuals of last model
	gmt("psxy -R1958/2016/-4/4 -J -Bxaf -Byafg10+u\" ppm\" -BWSne+t\"The Keeling Curve [CO@-2@- at Mauna Loa]\"+gazure1" *
		" -Sc0.05c -Gred -O -K -i0,2 -Y2.3i >> " * ps, model)
	gmt("pstext -R -J -O -F+f12p+cTL -Dj0.1i -Glightyellow >> " * ps, "@~e@~(t) = y(t) - m@-5@-(t)")
end

# -----------------------------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------------------------
