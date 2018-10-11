#The examples Gallery in Julia

using GMT
using DelimitedFiles

# When calling the gallery() function directly and with only one argument, one need to edit
# these two for own paths. Otherwise this same job is done in gmtest()
global g_root_dir = "C:/progs_cygw/GMTdev/gmt5/5.4/"
global out_path = "V:/"			# Leave it empty to write files in current directory

# -----------------------------------------------------------------------------------------------------
function gallery(opt::String)
# If called with one input only, the other two must be in the globals below.
	global g_root_dir, out_path
	gallery(opt, g_root_dir, out_path)
end

# -----------------------------------------------------------------------------------------------------
function gallery(opt::String, g_root_dir::String, out_path::String)
# This function is useful when we want to call the examples from a loop and build OPT as a string
# All of this because I don't know how to make an 'eval("string")' call a function.
	if (opt == "ex01")			ps, path = ex01(g_root_dir, out_path)
	elseif (opt == "ex02")		ps, path = ex02(g_root_dir, out_path)
	elseif (opt == "ex03")		ps, path = ex03(g_root_dir, out_path)
	elseif (opt == "ex04")		ps, path = ex04(g_root_dir, out_path)
	elseif (opt == "ex05")		ps, path = ex05(g_root_dir, out_path)
	elseif (opt == "ex06")		ps, path = ex06(g_root_dir, out_path)
	elseif (opt == "ex07")		ps, path = ex07(g_root_dir, out_path)
	elseif (opt == "ex08")		ps, path = ex08(g_root_dir, out_path)
	elseif (opt == "ex09")		ps, path = ex09(g_root_dir, out_path)
	elseif (opt == "ex10")		ps, path = ex10(g_root_dir, out_path)
	elseif (opt == "ex11")		ps, path = ex11(g_root_dir, out_path)	# Strange failure
	elseif (opt == "ex12")		ps, path = ex12(g_root_dir, out_path)
	elseif (opt == "ex13")		ps, path = ex13(g_root_dir, out_path)
	elseif (opt == "ex14")		ps, path = ex14(g_root_dir, out_path)
	elseif (opt == "ex15")		ps, path = ex15(g_root_dir, out_path)
	elseif (opt == "ex16")		ps, path = ex16(g_root_dir, out_path)	# Not yet
	elseif (opt == "ex17")		ps, path = ex17(g_root_dir, out_path)
	elseif (opt == "ex18")		ps, path = ex18(g_root_dir, out_path)
	elseif (opt == "ex19")		ps, path = ex19(g_root_dir, out_path)
	elseif (opt == "ex20")		ps, path = ex20(g_root_dir, out_path)
	elseif (opt == "ex21")		ps, path = ex21(g_root_dir, out_path)
	elseif (opt == "ex22")		ps, path = ex22(g_root_dir, out_path)
	elseif (opt == "ex23")		ps, path = ex23(g_root_dir, out_path)
	elseif (opt == "ex24")		ps, path = ex24(g_root_dir, out_path)
	elseif (opt == "ex25")		ps, path = ex25(g_root_dir, out_path)
	elseif (opt == "ex26")		ps, path = ex26(g_root_dir, out_path)
	elseif (opt == "ex27")		ps, path = ex27(g_root_dir, out_path)
	elseif (opt == "ex28")		ps, path = ex28(g_root_dir, out_path)
	elseif (opt == "ex29")		ps, path = ex29(g_root_dir, out_path)
	elseif (opt == "ex30")		ps, path = ex30(g_root_dir, out_path)
	elseif (opt == "ex31")		ps, path = ex31(g_root_dir, out_path)	# Not yet
	elseif (opt == "ex32")		ps, path = ex32(g_root_dir, out_path)
	elseif (opt == "ex33")		ps, path = ex33(g_root_dir, out_path)
	elseif (opt == "ex34")		ps, path = ex34(g_root_dir, out_path)
	elseif (opt == "ex35")		ps, path = ex35(g_root_dir, out_path)
	elseif (opt == "ex36")		ps, path = ex36(g_root_dir, out_path)
	elseif (opt == "ex37")		ps, path = ex37(g_root_dir, out_path)
	elseif (opt == "ex38")		ps, path = ex38(g_root_dir, out_path)
	elseif (opt == "ex39")		ps, path = ex39(g_root_dir, out_path)
	elseif (opt == "ex40")		ps, path = ex40(g_root_dir, out_path)
	elseif (opt == "ex41")		ps, path = ex41(g_root_dir, out_path)
	elseif (opt == "ex42")		ps, path = ex42(g_root_dir, out_path)
	elseif (opt == "ex43")		ps, path = ex43(g_root_dir, out_path)	# Not yet
	elseif (opt == "ex44")		ps, path = ex44(g_root_dir, out_path)
	elseif (opt == "ex45")		ps, path = ex45(g_root_dir, out_path)
	elseif (opt == "ex46")		ps, path = ex46(g_root_dir, out_path)
	else
		@warn("Example " * opt * " does not exits or not implemented.")
		ps = [];	path = []
	end
	return ps, path
end

# -----------------------------------------------------------------------------------------------------
function ex01(g_root_dir, out_path)
	# Purpose:    Make two contour maps based on the data in the file osu91a1f_16.nc
	# GMT progs:  gmtset, grdcontour, psbasemap, pscoast

	d_path = g_root_dir * "doc/examples/ex01/"
	ps = out_path * "example_01.ps"

	gmt("gmtset MAP_GRID_CROSS_SIZE_PRIMARY 0 FONT_ANNOT_PRIMARY 10p PROJ_LENGTH_UNIT inch PS_CHAR_ENCODING Standard+ PS_MEDIA letter")
	gmt("destroy")
	gmt("psbasemap -R0/6.5/0/7.5 -Jx1i -B0 -P -K > " * ps)
	gmt("pscoast -Rg -JH0/6i -X0.25i -Y0.2i -O -K -Bg30 -Dc -Glightbrown -Slightblue >> " * ps)
	cmd = "grdcontour @osu91a1f_16.nc"
	gmt(cmd * " -J -C10 -A50+f7p -Gd4i -L-1000/-1 -Wcthinnest,- -Wathin,- -O -K -T+d0.1i/0.02i >> " * ps)
	gmt(cmd * " -J -C10 -A50+f7p -Gd4i -L-1/1000 -O -K -T+d0.1i/0.02i >> " * ps)
	gmt("pscoast -Rg -JH6i -Y3.4i -O -K -B+t\"Low Order Geoid\" -Bg30 -Dc -Glightbrown -Slightblue >> " * ps)
	gmt(cmd * " -J -C10 -A50+f7p -Gd4i -L-1000/-1 -Wcthinnest,- -Wathin,- -O -K -T+d0.1i/0.02i+l >> " * ps)
	gmt(cmd * " -J -C10 -A50+f7p -Gd4i -L-1/1000 -O -T+d0.1i/0.02i+l >> " * ps)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex02(g_root_dir, out_path)
	# Purpose:	Make two color images based gridded data
	# GMT progs:	gmtset, grd2cpt, grdgradient, grdimage, makecpt, psscale, pstext

	d_path = g_root_dir * "doc/examples/ex02/"
	ps = out_path * "example_02.ps"

	gmt("gmtset -Du")
	gmt("gmtset FONT_TITLE 30p MAP_ANNOT_OBLIQUE 0")
	gmt("destroy")
	g_cpt = gmt("makecpt -Crainbow -T-2/14/2")
	gmt("grdimage @HI_geoid_02.nc -R160/20/220/30r -JOc190/25.5/292/69/4.5i -C" *
	    " -E50 -K -P -B10 -X1.5i -Y1.25i > " * ps, g_cpt)
	gmt("psscale -DJRM+o0.6i/0+e+mc -R -J -O -K -Bx2+lGEOID -By+lm >> " * ps, g_cpt)
	t_cpt = gmt("grd2cpt @HI_topo_02.nc -Crelief -Z")
	gmt("grdimage @HI_topo_02.nc -I+a0 -R -J -B+t\"H@#awaiian@# T@#opo and @#G@#eoid@#\"" *
	    " -B10 -E50 -O -K -C -Y4.5i --MAP_TITLE_OFFSET=0.5i >> " * ps, t_cpt)
	gmt("psscale -DJRM+o0.6i/0+mc -R -J -O -K -I0.3 -Bx2+lTOPO -By+lkm >> " * ps, t_cpt)
	if (GMTver < 6)
		T = Any["-0.4 7.5 a)", "-0.4 3.0 b)"]
	else
		T = text_record([-0.4 7.5; -0.4 3.0], ["a)", "b)"])
	end
	gmt("pstext -R0/8.5/0/11 -Jx1i -F+f30p,Helvetica-Bold+jCB -O -N -Y-4.5i >> " * ps, T)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex03(g_root_dir, out_path)	
	# Purpose:   
	# GMT progs: 

	d_path = g_root_dir * "doc/examples/ex03/"
	ps = out_path * "example_03.ps"

	gmt("gmtset -Du GMT_FFT kiss")
	gmt("destroy")
	
	cpos  = gmt("fitcircle @sat_03.xyg -L2 -Fm")
	cposx = cpos[1].data[1,1];		cposy = cpos[1].data[1,2]
	ppos  = gmt("fitcircle @sat_03.xyg -L2 -Fn")
	pposx = ppos[1].data[1,1];		pposy = ppos[1].data[1,2]

	# Now we use "gmt project" to gmt project the data in both sat.xyg and ship.xyg
	# into data.pg, where g is the same and p is the oblique longitude around
	# the great circle.  We use -Q to get the p distance in kilometers, and -S
	# to sort the output into increasing p values.

	sat_pg  = gmt(@sprintf("project @sat_03.xyg -C%f/%f -T%f/%f -S -Fpz -Q", cposx, cposy, pposx, pposy));
	ship_pg = gmt(@sprintf("project @ship_03.xyg -C%f/%f -T%f/%f -S -Fpz -Q", cposx, cposy, pposx, pposy));
	sat_pg  = sat_pg[1].data;
	ship_pg = ship_pg[1].data;

	# The gmtinfo utility will report the minimum and maximum values for all columns. 
	# We use this information first with a large -I value to find the appropriate -R
	# to use to plot the .pg data. 
	R = gmt("gmtinfo -I100/25", [sat_pg; ship_pg])
	R = R[1].text[1]
	gmt("psxy " * R * " -UL/-1.75i/-1.25i/\"Example 3a in Cookbook\" -BWeSn" *
		" -Bxa500f100+l\"Distance along great circle\" -Bya100f25+l\"Gravity anomaly (mGal)\"" *
		" -JX8i/5i -X2i -Y1.5i -K -Wthick > " * ps, sat_pg)
	gmt("psxy -R -JX -O -Sp0.03i >> " * ps, ship_pg)

	# From this plot we see that the ship data have some "spikes" and also greatly
	# differ from the satellite data at a point about p ~= +250 km, where both of
	# them show a very large anomaly.

	# To facilitate comparison of the two with a cross-spectral analysis using "gmt spectrum1d",
	# we resample both data sets at intervals of 1 km.  First we find out how the data are
	# typically spaced using $AWK to get the delta-p between points and view it with "gmt pshistogram".

	ps = out_path * "example_03b.ps"

	gmt("pshistogram -W0.1 -Gblack -JX3i -K -X2i -Y1.5i -B0 -B+t\"Ship\" -UL/-1.75i/-1.25i/\"Example 3b in Cookbook\"" *
		" > " * ps, diff(ship_pg, dims=1))
	gmt("pshistogram  -W0.1 -Gblack -JX3i -O -X5i -B0 -B+t\"Sat\" >> " * ps, diff(sat_pg, dims=1))

	# This experience shows that the satellite values are spaced fairly evenly, with
	# delta-p between 3.222 and 3.418.  The ship values are spaced quite unevenly, with
	# delta-p between 0.095 and 9.017.  This means that when we want 1 km even sampling,
	# we can use "gmt sample1d" to interpolate the sat data, but the same procedure applied
	# to the ship data could alias information at shorter wavelengths.  So we have to use
	# "gmt filter1d" to resample the ship data.  Also, since we observed spikes in the ship
	# data, we use a median filter to clean up the ship values.  We will want to use "paste"
	# to put the two sampled data sets together, so they must start and end at the same
	# point, without NaNs.  So we want to get a starting and ending point which works for
	# both of them.  This is a job for gmt gmtmath UPPER/LOWER.

	sampr1 = gmt("gmtmath ? -Ca -Sf -o0 UPPER CEIL =",  [ship_pg[1:1,:]; sat_pg[1:1,:]])
	sampr2 = gmt("gmtmath ? -Ca -Sf -o0 LOWER FLOOR =", [ship_pg[end:end,:]; sat_pg[end:end,:]])

	# Now we can use sampr1|2 in gmt gmtmath to make a sampling points file for gmt sample1d:
	samp_x = gmt(@sprintf("gmtmath -T%d/%d/1 -N1/0 T =", sampr1[1].data[1,1], sampr2[1].data[1,1]))

	# Now we can resample the gmt projected satellite data:
	samp_sat_pg = gmt("sample1d -N", sat_pg, samp_x)

	# For reasons above, we use gmt filter1d to pre-treat the ship data.  We also need to sample
	# it because of the gaps > 1 km we found.  So we use gmt filter1d | gmt sample1d.  We also
	# use the -E on gmt filter1d to use the data all the way out to sampr1/sampr2 :
	t = gmt(@sprintf("filter1d -Fm1 -T%d/%d/1 -E", sampr1[1].data[1], sampr2[1].data[1]), ship_pg)
	samp_ship_pg = gmt("sample1d -N", t, samp_x)

	ps = out_path * "example_03c.ps"

	# Now we plot them again to see if we have done the right thing:
	gmt("psxy " * R * " -JX8i/5i -X2i -Y1.5i -K -Wthick" *
		" -Bxa500f100+l\"Distance along great circle\" -Bya100f25+l\"Gravity anomaly (mGal)\"" *
		" -BWeSn -UL/-1.75i/-1.25i/\"Example 3c in Cookbook\" > " * ps, samp_sat_pg)
	gmt("psxy -R -JX -O -Sp0.03i >> " * ps, samp_ship_pg)

	# Now to do the cross-spectra, assuming that the ship is the input and the sat is the output 
	# data, we do this:
	t = [samp_ship_pg[1].data[:,2] samp_sat_pg[1].data[:,2]]
	spects = gmt("spectrum1d -S256 -D1 -W -C -N", t)
 
	# Now we want to plot the spectra. The following commands will plot the ship and sat 
	# power in one diagram and the coherency on another diagram, both on the same page.  
	# Note the extended use of gmt pstext and gmt psxy to put labels and legends directly on the
	# plots. For that purpose we often use -Jx1i and specify positions in inches directly:

	ps = out_path * "example_03.ps"

	gmt("psxy -Bxa1f3p+l\"Wavelength (km)\" -Bya0.25f0.05+l\"Coherency@+2@+\" -BWeSn+g240/255/240" *
		" -JX-4il/3.75i -R1/1000/0/1 -P -K -X2.5i -Sc0.07i -Gpurple -Ey/0.5p -Y1.5i > " * ps, spects[1].data[:,[1,16,17]])
	
	gmt("pstext -R -J -F+cTR+f18p,Helvetica-Bold -Dj0.1i -O -K >> " * ps, text_record("Coherency@+2@+"))
	gmt("psxy -Bxa1f3p -Bya1f3p+l\"Power (mGal@+2@+km)\" -BWeSn+t\"Ship and Satellite Gravity\"+g240/255/240" *
		" -Gred -ST0.07i -O -R1/1000/0.1/10000 -JX-4il/3.75il -Y4.2i -K -Ey/0.5p >> " * ps, spects[1].data[:,1:3])
	gmt("psxy -R -JX -O -K -Gblue -Sc0.07i -Ey/0.5p >> " * ps, spects[1].data[:,[1,4,5]])
	gmt("pstext -R0/4/0/3.75 -Jx1i -F+cTR+f18p,Helvetica-Bold -Dj0.1i -O -K >> " * ps, text_record("Input Power"))

	legend = text_record(["S 0.1i T 0.07i red - 0.3i Ship", "S 0.1i c 0.07i blue - 0.3i Satellite"])
	gmt("pslegend -R -J -O -DjBL+w1.2i+o0.25i -F+gwhite+pthicker --FONT_ANNOT_PRIMARY=14p,Helvetica-Bold >> " * ps, legend)

	# Now we wonder if removing that large feature at 250 km would make any difference.
	# We could throw away a section of data with $AWK or sed or head and tail, but we
	# demonstrate the use of "gmt trend1d" to identify outliers instead.  We will fit a
	# straight line to the samp_ship.pg data by an iteratively-reweighted method and
	# save the weights on output.  Then we will plot the weights and see how things look:

	ps = out_path * "example_03d.ps"

	samp_ship_xw = gmt("trend1d -Fxw -Np2+r", samp_ship_pg)
	gmt("psxy " * R * " -JX8i/4i -X2i -Y1.5i -K -Sp0.03i" *
		" -Bxa500f100+l\"Distance along great circle\" -Bya100f25+l\"Gravity anomaly (mGal)\"" *
		" -BWeSn -UL/-1.75i/-1.25i/\"Example 3d in Cookbook\" > " * ps, samp_ship_pg)
	R = gmt("gmtinfo -I100/1.1", samp_ship_xw)
	gmt("psxy " * R[1].text[1] * " -JX8i/1.1i -O -Y4.25i -Bxf100 -Bya0.5f0.1+l\"Weight\" -BWesn -Sp0.03i >> " * ps, samp_ship_xw)
	rm("gmt.conf")

	return out_path * "example_03.ps", d_path
end

# -----------------------------------------------------------------------------------------------------
function ex04(g_root_dir, out_path)	
	# Purpose:   3-D mesh and color plot of Hawaiian topography and geoid
	# GMT progs: grdcontour, grdgradient, grdimage, grdview, psbasemap, pscoast, pstext

	d_path = g_root_dir * "doc/examples/ex04/"
	ps = out_path * "example_04.ps"

	gmt("gmtset -Du")
	gmt("destroy")

	C = gmt("makecpt -C255,100 -T-10/10/10 -N")

	gmt("grdcontour @HI_geoid_04.nc -R195/210/18/25 -Jm0.45i -p60/30 -C1 -A5+o -Gd4i -K -P -X1.25i -Y1.25i > " * ps)
	gmt("pscoast -R -J -p -B2 -BNEsw -Gblack -O -K -TdjBR+o0.1i+w1i+l >> " * ps)
	gmt("grdview @HI_topo_04.nc -R195/210/18/25/-6/4 -J -Jz0.34i -p -C -O -K" *
		" -N-6+glightgray -Qsm -B2 -Bz2+l\"Topo (km)\" -BneswZ -Y2.2i >> " * ps, C)
	gmt("pstext -R0/10/0/10 -Jx1i -F+f60p,ZapfChancery-MediumItalic+jCB -O >> " *  ps,
		text_record([3.25 5.75], "H@#awaiian@# R@#idge@#"))

	if (GMTver < 6)
		t_cpt = d_path * "topo.cpt";	g_cpt =  d_path * "geoid.cpt"
	else
		t_cpt = "@topo_04.cpt";			g_cpt = "@geoid_04.cpt"
	end
	ps = out_path * "example_04c.ps"
	gmt("grdimage @HI_geoid_04.nc -I+nt0.75+a0 -R195/210/18/25 -JM6.75i -p60/30 -C" * g_cpt * " -E100 -K -P -X1.25i -Y1.25i > " * ps)
	gmt("pscoast -R -J -p -B2 -BNEsw -Gblack -O -K >> " * ps)
	gmt("psbasemap -R -J -p -O -K -TdjBR+o0.1i+w1i+l --COLOR_BACKGROUND=red --FONT=red" *
		" --MAP_TICK_PEN_PRIMARY=thinner,red >> " * ps)
	gmt("psscale -R -J -p240/30 -DJBC+o0/0.5i+w5i/0.3i+h -C" * g_cpt * " -I -O -K -Bx2+l\"Geoid (m)\" >> " * ps)
	gmt("grdview @HI_topo_04.nc -I+nt0.75+a0 -R195/210/18/25/-6/4 -J -C" * t_cpt *
		" -JZ3.4i -p60/30 -O -K -N-6+glightgray -Qc100 -B2 -Bz2+l\"Topo (km)\" -BneswZ -Y2.2i >> " * ps)
	gmt("pstext -R0/10/0/10 -Jx1i -F+f60p,ZapfChancery-MediumItalic+jCB -O >> " * ps,
		text_record([3.25 5.75], "H@#awaiian@# R@#idge@#"))
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex05(g_root_dir, out_path)
	# Purpose:   Generate grid and show monochrome 3-D perspective
	# GMT progs: grdgradient, grdmath, grdview, pstext

	d_path = g_root_dir * "doc/examples/ex05/"
	ps = out_path * "example_05.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	Gsombrero = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
	C = gmt("makecpt -C128 -T-5,5 -N")
	gmt("grdview -JX6i -JZ2i -B5 -Bz0.5 -BSEwnZ -N-1+gwhite -Qs -I+nt0.75+a225 -X1.5i" *
		" -C -R-15/15/-15/15/-1/1 -K -p120/30 > " * ps, Gsombrero, C)
	gmt("pstext -R0/11/0/8.5 -Jx1i -F+f50p,ZapfChancery-MediumItalic+jBC -O >> " * ps,
		text_record([4.1 5.5], "z(r) = cos (2@~p@~r/8) @~\\327@~e@+-r/10@+"))
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex06(g_root_dir, out_path)
	# Purpose:    Make standard and polar histograms
	# GMT progs:  pshistogram, psrose

	d_path = g_root_dir * "doc/examples/ex06/"
	ps = out_path * "example_06.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	gmt("psrose @fractures_06.txt -: -A10r -S1.8in -P -Gorange -R0/1/0/360 -X2.5i -K -Bx0.2g0.2" *
		" -By30g30 -B+glightblue -W1p > " * ps)
	gmt("pshistogram -Bxa2000f1000+l\"Topography (m)\" -Bya10f5+l\"Frequency\"+u\" %\"" *
		" -BWSne+t\"Histograms\"+glightblue @v3206_06.txt -R-6000/0/0/30 -JX4.8i/2.4i -Gorange -O" *
		" -Y5.0i -X-0.5i -L1p -Z1 -W250 >> " * ps)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex07(g_root_dir, out_path)
	# Purpose:    Make a basemap with earthquakes and isochrons etc
	# GMT progs:  pscoast, pstext, psxy

	d_path = g_root_dir * "doc/examples/ex07/"
	ps = out_path * "example_07.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	gmt("pscoast -R-50/0/-10/20 -JM9i -K -Slightblue -GP300/26:FtanBdarkbrown -Dl -Wthinnest" *
		" -B10 --FORMAT_GEO_MAP=dddF > " * ps)
	gmt("psxy -R -J -O -K @fz_07.txt -Wthinner,- >> " * ps)
	gmt("psxy @quakes_07.txt -R -J -O -K -h1 -Sci -i0,1,2s0.01 -Gred -Wthinnest >> " * ps)
	gmt("psxy -R -J -O -K @isochron_07.txt -Wthin,blue >> " * ps)
	gmt("psxy -R -J -O -K @ridge_07.txt -Wthicker,orange >> " * ps)
	gmt("pslegend -R -J -O -K -DjTR+w2.2i+o0.2i -F+pthick+ithinner+gwhite --FONT_ANNOT_PRIMARY=18p,Times-Italic >> " * ps,
		text_record("S 0.1i c 0.08i red thinnest 0.3i ISC Earthquakes"))
	gmt("pstext -R -J -O -F+f30,Helvetica-Bold,white=thin >> " * ps,
		text_record([-43 -5; -43 -8; -7 11], ["SOUTH", "AMERICA", "AFRICA"]))
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex08(g_root_dir, out_path)
	# Purpose:    Make a 3-D bar plot
	# GMT progs:  grd2xyz, pstext, psxyz

	d_path = g_root_dir * "doc/examples/ex08/"
	ps = out_path * "example_08.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	xyz = gmt("grd2xyz @guinea_bay.nc")
	gmt("psxyz -B1 -Bz1000+l\"Topography (m)\" -BWSneZ+b+tETOPO5" *
		" -R-0.1/5.1/-0.1/5.1/-5000/0 -JM5i -JZ6i -p200/30 -So0.0833333ub-5000 -P" *
		" -Wthinnest -Glightgreen -K > " * ps, xyz)
	gmt("pstext -R -J -JZ -Z0 -F+f24p,Helvetica-Bold+jTL -p -O >> " * ps, text_record([0.1 4.9], "This is the surface of cube"))
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex09(g_root_dir, out_path)
	# Purpose:    Make wiggle plot along track from geoid deflections
	# GMT progs:  gmtconvert, pswiggle, pstext, psxy

	d_path = g_root_dir * "doc/examples/ex09/"
	ps = out_path * "example_09.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	gmt("pswiggle @tracks_09.txt -R185/250/-68/-42 -K -Jm0.13i -Ba10f5 -BWSne+g240/255/240 -G+red" *
		" -G-blue -Z2000 -Wthinnest -S240/-67/500/@~m@~rad --FORMAT_GEO_MAP=dddF > " * ps)
	gmt("psxy -R -J -O -K @ridge_09.txt -Wthicker >> " * ps)
	gmt("psxy -R -J -O -K @fz_09.txt    -Wthinner,- >> " * ps)
	# Take label from segment header and plot near coordinates of last record of each track
	t = gmt("gmtconvert -El @tracks_09.txt")
	for k = 1:length(t)		t[k].text = [t[k].header]	end
	gmt("pstext -R -J -F+f10p,Helvetica-Bold+a50+jRM+h -D-0.05i/-0.05i -O >> " * ps, t)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex10(g_root_dir, out_path)
	# Purpose:    Make 3-D bar graph on top of perspective map
	# GMT progs:  pscoast, pstext, psxyz, pslegend

	d_path = g_root_dir * "doc/examples/ex10/"
	ps = out_path * "example_10.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	gmt("pscoast -Rd -JX8id/5id -Dc -Sazure2 -Gwheat -Wfaint -A5000 -p200/40 -K > " * ps)
	str = readdlm(d_path * "languages.txt",'\t','\n', comments=true)
	nl  = size(str,1)
	array = zeros(nl, 7)
	for row = 1:nl
		for col = 1:7
			array[row,col] = Float64(str[row,col])
		end
	end
	if (GMTver < 6)
		t = Array{Any}(nl,1)
		for k = 1:nl
			t[k] = @sprintf("%d %d %d\n",array[k,1], array[k,2], sum(array[k,3:end]))
		end
	else
		tt = Array{Any}(undef, nl)
		for k = 1:nl  tt[k] = @sprintf("%d",sum(array[k,3:end])) end
		t = text_record(array, tt)
	end
	gmt("pstext -R -J -O -K -p -Gwhite@30 -D-0.25i/0 -F+f30p,Helvetica-Bold,firebrick=thinner+jRM >> " * ps, t)
	gmt("psxyz " * d_path * "languages.txt -R-180/180/-90/90/0/2500 -J -JZ2.5i -So0.3i -Gpurple -Wthinner" *
		" --FONT_TITLE=30p,Times-Bold --MAP_TITLE_OFFSET=-0.7i -O -K -p --FORMAT_GEO_MAP=dddF" *
		" -Bx60 -By30 -Bza500+lLanguages -BWSneZ+t\"World Languages By Continent\" >> " * ps)
	gmt("psxyz -R -J -JZ -So0.3ib -Gblue -Wthinner -O -K -p >> " * ps, [array[:,1:2] sum(array[:,3:4],dims=2) array[:,3]])
	gmt("psxyz -R -J -JZ -So0.3ib -Gdarkgreen -Wthinner -O -K -p >> " * ps, [array[:,1:2] sum(array[:,3:5],dims=2) sum(array[:,3:4],dims=2)])
	gmt("psxyz -R -J -JZ -So0.3ib -Gyellow -Wthinner -O -K -p >> " * ps, [array[:,1:2] sum(array[:,3:6],dims=2) sum(array[:,3:5],dims=2)])
	gmt("psxyz -R -J -JZ -So0.3ib -Gred -Wthinner -O -K -p >> " * ps, [array[:,1:2] sum(array[:,3:7],dims=2) sum(array[:,3:6],dims=2)])
	gmt("pslegend -R -J -JZ -DjLB+o0.2i+w1.35i/0+jBL -O --FONT=Helvetica-Bold" *
		" -F+glightgrey+pthinner+s-4p/-6p/grey20@40 -p " * d_path * "legend.txt >> " * ps)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex11(g_root_dir, out_path)	
	# Purpose:   
	# GMT progs: 

	d_path = g_root_dir * "doc/examples/ex11/"
	ps = out_path * "example_11.ps"

	gmt("gmtset MAP_TICK_LENGTH_PRIMARY 0 FONT_ANNOT_PRIMARY 12p,Helvetica-Bold PROJ_LENGTH_UNIT inch PS_CHAR_ENCODING Standard+ PS_MEDIA letter")
	gmt("destroy")

	gmt("psxy @cut-here_11.txt -Wthinnest,. -R-51/306/0/1071 -JX3.5i/10.5i -X2.5i -Y0.5i -P -K > " * ps)

	# First, create grids of ascending X and Y and constant 0.
	# These are to be used to represent R, G and B values of the darker 3 faces of the cube.
	x_nc = gmt("grdmath -I1 -R0/255/0/255 X =")
	y_nc = gmt("grdmath -I1 -R Y =")
	c_nc = gmt("grdmath -I1 -R 0 =")

	gmt("grdimage -JX2.5i/-2.5i -R -K -O -X0.5i >> " * ps, x_nc, y_nc, c_nc)
	gmt("psxy -Wthinner,white,- @rays_11.txt -J -R -K -O >> " * ps)
	if (GMTver < 6)
		T = Any[
			"128 128 -45 12p 60\\217"
			"102  26 -90 12p 0.4"
			"204  26 -90 12p 0.8"
			"10  140 180 16p G"]
	else
		T = text_record([128 128 -45; 102  26 -90; 204  26 -90; 10  140 180], ["12p 60\\217"; "12p 0.4"; "12p 0.8"; "16p G"])
	end
	gmt("pstext --FONT=white -J -R -K -O -F+a+f >> " * ps, T)
	gmt("psxy -N -Sv0.15i+s+e -Gwhite -W2p,white -J -R -K -O >> " * ps, [0 0 0 128])

	gmt("grdimage -JX2.5i/2.5i -R -K -O -Y2.5i >> " * ps, x_nc, c_nc, y_nc)
	gmt("psxy -Wthinner,white,- @rays_11.txt -J -R -K -O >> " * ps)
	if (GMTver < 6)
		T = Any[
			"128 128 45 12p  300\\217"
			"26  102  0 12p  0.4"
			"26  204  0 12p  0.8"
			"140  10 -90 16p R"
			"100 100 -45 16p V"]
	else
		T = text_record([128 128 45; 26 102 0; 26 204 0; 140 10 -90; 100 100 -45], ["12p 300\\217"; "12p 0.4"; "12p 0.8"; "16p R"; "16p V"]);
	end
	gmt("pstext --FONT=white -J -R -K -O -F+a+f >> " * ps, T)

	gmt("psxy -N -Sv0.15i+s+e -Gwhite -W2p,white -J -R -K -O >> " * ps, [0 0 128 0])
	gmt("psxy -N -Sv0.15i+s+e -Gwhite -W2p,white -J -R -K -O >> " * ps, [0 0 90 90])

	gmt("grdimage -JX-2.5i/2.5i -R -K -O -X-2.5i >> " * ps, c_nc, x_nc, y_nc)
	gmt("psxy -Wthinner,white,- @rays_11.txt -J -R -K -O >> " * ps)
	if (GMTver < 6)
		T = Any[
			"128 128 135 12p 180\\217"
			"102  26 90 12p  0.4"
			"204  26 90 12p  0.8"
			"10  140  0 16p  B"]
	else
		T = text_record([128 128 135; 102  26 90; 204  26 90; 10  140  0], ["12p 180\\217"; "12p 0.4"; "12p 0.8"; "16p B"]);
	end
	gmt("pstext --FONT=white -J -R -K -O -F+a+f >> " * ps, T)

	gmt("psxy -N -Sv0.15i+s+e -Gwhite -W2p,white -J -R -K -O >> " * ps, [0 0 0 128])
	gmt("psxy -N -Sv0.15i+s+e -Gwhite -W2p,white -J -R -K -O >> " * ps, [0 0 128 0])

	# Second, create grids of descending X and Y and constant 255.
	# These are to be used to represent R, G and B values of the lighter 3 faces of the cube.

	x_nc = gmt("grdmath -I1 -R 255 X SUB =")
	y_nc = gmt("grdmath -I1 -R 255 Y SUB =")
	c_nc = gmt("grdmath -I1 -R 255       =")

	gmt("grdimage -JX-2.5i/-2.5i -R -K -O -X2.5i -Y2.5i >> " * ps, x_nc, y_nc, c_nc)
	gmt("psxy -Wthinner,black,- @rays_11.txt -J -R -K -O >> " * ps)
	if (GMTver < 6)
		T = Any[
			"128 128 225 12p 240\\217"
			"102  26 270 12p 0.4"
			"204  26 270 12p 0.8"]
	else
		T = text_record([128 128 225; 102  26 270; 204  26 270], ["12p 240\\217"; "12p 0.4"; "12p 0.8"])
	end
	gmt("pstext -J -R -K -O -F+a+f >> " * ps, T)

	gmt("grdimage -JX2.5i/-2.5i -R -K -O -X2.5i >> " * ps, c_nc, y_nc, x_nc)
	gmt("psxy -Wthinner,black,- @rays_11.txt -J -R -K -O >> " * ps)
	if (GMTver < 6)
		T = Any[
			"128 128 -45 12p 0\\217"
			"26  102   0 12p 0.4"
			"26  204   0 12p 0.8"
			"100 100  45 16p S"
			"204  66  90 16p H"]
	else
		T = text_record([128 128 -45; 26 102 0; 26 204 0; 100 100  45; 204 66 90], ["12p 0\\217"; "12p 0.4"; "12p 0.8"; "16p S"; "16p H"])
	end
	gmt("pstext -J -R -K -O -F+a+f >> " * ps, T)

	gmt("psxy -N -Sv0.15i+s+e -Gblack -W2p -J -R -O -K >> " * ps, [0 0 90 90])
	gmt("psxy -N -Sv0.15i+s+e -Gblack -W2p -J -R -O -K >> " * ps, [204 204 204 76])

	gmt("grdimage -JX-2.5i/2.5i -R -K -O -X-2.5i -Y2.5i >> " * ps, x_nc, c_nc, y_nc)
	gmt("psxy -Wthinner,black,- @rays_11.txt -J -R -K -O >> " * ps)
	if (GMTver < 6)
		T = Any[
			"128 128 135 12p 120\\217"
			"26  102 180 12p 0.4"
			"26  204 180 12p 0.8"
			"200 200 225 16p GMT 5"]
	else
		T = text_record([128 128 135; 26  102 180; 26  204 180; 200 200 225], ["12p 120\\217"; "12p 0.4"; "12p 0.8"; "16p GMT 5"])
	end
	gmt("pstext -J -R -O -F+a+f >> " * ps, T)

	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex12(g_root_dir, out_path)
	# Purpose:    Illustrates Delaunay triangulation of points, and contouring
	# GMT progs:  makecpt, gmtinfo, pscontour, pstext, psxy, triangulate

	d_path = g_root_dir * "doc/examples/ex12/"
	ps = out_path * "example_12.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	net_xy = gmt("triangulate @table_5.11 -M");
	gmt("psxy -R0/6.5/-0.2/6.5 -JX3.06i/3.15i -B2f1 -BWSNe -Wthinner -P -K -X0.9i -Y4.65i > " * ps, net_xy)
	gmt("psxy @table_5.11 -R -J -O -K -Sc0.12i -Gwhite -Wthinnest >> " * ps)
	gmt("pstext -R -J -F+f6p+r -O -K @table_5.11 >> " * ps)

	# Then draw network and print the node values
	gmt("psxy -R -J -B2f1 -BeSNw -Wthinner -O -K -X3.25i >> " * ps, net_xy)
	gmt("psxy -R -J -O -K @table_5.11 -Sc0.03i -Gblack >> " * ps)
	gmt("pstext @table_5.11 -R -J -F+f6p+jLM -O -K -Gwhite -W -C0.01i -D0.08i/0i -N >> " * ps)

	# Then contour the data and draw triangles using dashed pen; use "gmt gmtinfo" and "gmt makecpt" to make a
	# color palette (.cpt) file
	T = gmt("gmtinfo -T25+c2 @table_5.11")
	topo_cpt = gmt("makecpt -Cjet " * T[1].text[1])
	gmt("pscontour -R -J @table_5.11 -B2f1 -BWSne -Wthin -C -Lthinnest,-" *
		" -Gd1i -X-3.25i -Y-3.65i -O -K >> " * ps, topo_cpt)
	gmt("pscontour -R -J @table_5.11 -B2f1 -BeSnw -C -I -X3.25i -O -K >> " * ps, topo_cpt)
	gmt("pstext -R0/8/0/11 -Jx1i -F+f30p,Helvetica-Bold+jCB -O -X-3.25i >> " * ps, text_record([3.16 8], "Delaunay Triangulation"))
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex13(g_root_dir, out_path)
	# Purpose:    Illustrate vectors and contouring
	# GMT progs:  grdmath, grdcontour, grdvector, pstext

	d_path = g_root_dir * "doc/examples/ex13/"
	ps = out_path * "example_13.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	Gz = gmt("grdmath -R-2/2/-2/2 -I0.1 X Y R2 NEG EXP X MUL =")
	Gdzdx = gmt("grdmath ? DDX", Gz)
	Gdzdy = gmt("grdmath ? DDY", Gz);
	gmt("grdcontour -JX3i -B1 -BWSne -C0.1 -A0.5 -K -P -Gd2i -S4 -T+d0.1i/0.03i > " * ps, Gdzdx)
	gmt("grdcontour -J -B -C0.05 -A0.2 -O -K -Gd2i -S4 -T+d0.1i/0.03i -Xa3.45i >> " * ps, Gdzdy)
	gmt("grdcontour -J -B -C0.05 -A0.1 -O -K -Gd2i -S4 -T+d0.1i/0.03i -Y3.45i  >> " * ps, Gz)
	gmt("grdcontour -J -B -C0.05 -O -K -Gd2i -S4 -X3.45i >> " * ps, Gz)
	gmt("grdvector -I0.2 -J -O -K -Q0.1i+e+n0.25i -Gblack -W1p -S5i --MAP_VECTOR_SHAPE=0.5 >> " * ps, Gdzdx, Gdzdy)
	gmt("pstext -R0/6/0/4.5 -Jx1i -F+f40p,Times-Italic+jCB -O -X-3.45i >> " * ps,
		text_record([3.2 3.6], "z(x,y) = x@~\\327@~exp(-x@+2@+-y@+2@+)"))
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex14(g_root_dir, out_path)
	# Purpose:    Showing simple gridding, contouring, and resampling along tracks
	# GMT progs:  blockmean, grdcontour, grdtrack, grdtrend, gmtinfo, project, gmtset, pstext, psbasemap, psxy, surface

	d_path = g_root_dir * "doc/examples/ex14/"
	ps = out_path * "example_14.ps"

	# First draw network and label the nodes
	gmt("gmtset MAP_GRID_PEN_PRIMARY thinnest,- PROJ_LENGTH_UNIT inch PS_CHAR_ENCODING Standard+ PS_MEDIA letter")
	gmt("destroy")
	gmt("psxy @table_5.11 -R0/7/0/7 -JX3.06i/3.15i -B2f1 -BWSNe -Sc0.05i -Gblack -P -K -Y6.45i > " * ps)
	gmt("pstext @table_5.11 -R -J -D0.1c/0 -F+f6p+jLM -O -K -N >> " * ps)
	mean_xyz = gmt("blockmean @table_5.11 -R0/7/0/7 -I1");

	# Then draw gmt blockmean cells
	gmt("psbasemap -R0.5/7.5/0.5/7.5 -J -O -K -Bg1 -X3.25i >> " * ps)
	gmt("psxy -R0/7/0/7 -J -B2f1 -BeSNw -Ss0.05i -Gblack -O -K >> " * ps, mean_xyz)
	# Reformat to one decimal for annotation purposes
	#t = cellstr(num2str(mean_xyz,'%g %g %.1f'));	# Round to nearest 0.1 and convert to cells
	nl = size(mean_xyz[1].data,1)
	if (GMTver < 6)
		t = Array{Any}(nl,1)
		for k = 1:nl
			t[k] = @sprintf("%f %f %.1f", mean_xyz[1].data[k,1], mean_xyz[1].data[k,2], mean_xyz[1].data[k,3])
		end
	else
		tt = Array{Any}(undef, nl)
		for k = 1:nl
			tt[k] = @sprintf("%.1f", mean_xyz[1].data[k,3])
		end
		t = text_record(mean_xyz[1].data, tt);
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
	data  = gmt("grdtrack -G -o2,3", track, Gdata);
	trend = gmt("grdtrack -G -o2,3", track, Gtrend);
	t = gmt("gmtinfo -I0.5/25", trend, data);
	gmt("psxy -JX6.3i/1.4i "  * t[1].text[1] * " -Wthick -O -K -X-3.25i -Y-1.9i -Bx1 -By50 -BWSne >> " * ps, data)
	gmt("psxy -R -J -Wthinner,- -O >> " * ps, trend)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex15(g_root_dir, out_path)
	# Purpose:    Gridding and clipping when data are missing
	# GMT progs:  blockmedian, gmtconvert, grdclip, grdcontour, grdinfo, gmtinfo, nearneighbor, pscoast, psmask, pstext, surface

	d_path = g_root_dir * "doc/examples/ex15/"
	ps = out_path * "example_15.ps"

	gmt("gmtset -Du")
	gmt("destroy")

	ship_d = gmt("gmtread -Td @ship_15.xyz")
	region = gmt("gmtinfo -I1", ship_d)

	region = region[1].text[1]
	Gship  = gmt("nearneighbor " * region * " -I10m -S40k", ship_d)
	gmt("grdcontour -JM3i -P -B2 -BWSne -C250 -A1000 -Gd2i -K > " * ps, Gship)

	ship_10m = gmt("blockmedian " * region * " -I10m", ship_d)
	Gship = gmt("surface " * region * " -I10m", ship_10m)
	gmt("psmask " * region * " -I10m -J -O -K -T -Glightgray -X3.6i >> " * ps, ship_d)
	gmt("grdcontour -J -B -C250 -L-8000/0 -A1000 -Gd2i -O -K >> " * ps, Gship)

	gmt("psmask " * region * " -I10m -J -B -O -K -X-3.6i -Y3.75i >> " * ps, ship_10m)
	gmt("grdcontour -J -C250 -A1000 -L-8000/0 -Gd2i -O -K >> " * ps, Gship)
	gmt("psmask -C -O -K >> " * ps)

	Gship_clipped = gmt("grdclip -Sa-1/NaN -G", Gship)
	gmt("grdcontour -J -B -C250 -A1000 -L-8000/0 -Gd2i -O -K -X3.6i >> " * ps, Gship_clipped)
	gmt("pscoast " * region * " -J -O -K -Ggray -Wthinnest >> " * ps)
	info = gmt("grdinfo -C -M", Gship)
	gmt("psxy -R -J -O -K -Sa0.15i -i10,11 -Wthick >> " * ps, info)
	gmt("pstext -R0/3/0/4 -Jx1i -F+f24p,Helvetica-Bold+jCB -O -N >> " * ps, text_record([-0.3 3.6], "Gridding with missing data"))
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex16(g_root_dir, out_path)	
	# Purpose:   
	# GMT progs: 

	d_path = g_root_dir * "doc/examples/ex16/"
	ps = out_path * "example_16.ps"

	if (GMTver < 6)  cpt = d_path * "ex16.cpt";
	else             cpt = "@ex_16.cpt";
	end
	gmt("gmtset FONT_ANNOT_PRIMARY 9p PROJ_LENGTH_UNIT inch PS_CHAR_ENCODING Standard+ PS_MEDIA letter")
	gmt("destroy")

	gmt("pscontour -R0/6.5/-0.2/6.5 -Jx0.45i -P -K -Y5.5i -Ba2f1 -BWSne @table_5.11 -C" * cpt * " -I > " * ps)
	gmt("pstext -R -J -O -K -N -F+f18p,Times-Roman+jCB >> " * ps, text_record([3.25 7], "pscontour (triangulate)"))

	Graws0 = gmt("surface @table_5.11 -R -I0.2")
	gmt("grdview -R -J -B -C" * cpt * " -Qs -O -K -X3.5i >> " * ps, Graws0)
	gmt("pstext -R -J -O -K -N -F+f18p,Times-Roman+jCB >> " * ps, text_record([3.25 7], "surface (tension = 0)"))

	Graws5 = gmt("surface @table_5.11 -R -I0.2 -G -T0.5")
	gmt("grdview -R -J -B -C" * cpt * " -Qs -O -K -Y-3.75i -X-3.5i >> " * ps, Graws5)
	gmt("pstext -R -J -O -K -N -F+f18p,Times-Roman+jCB >> " * ps, text_record([3.25 7], "surface (tension = 0.5)"))

	Grawt = gmt("triangulate @Table_5_11.txt -G -R -I0.2")
	Gfiltered = gmt("grdfilter -G -D0 -Fc1", Grawt)
	gmt("grdview -R -J -B -C" * cpt * " -Qs -O -K -X3.5i >> " * ps, Gfiltered)
	gmt("pstext -R -J -O -K -N -F+f18p,Times-Roman+jCB >> " * ps, text_record([3.25 7], "triangulate @~\\256@~ grdfilter"))
	gmt("pstext -R0/10/0/10 -Jx1i -O -K -N -F+f32p,Times-Roman+jCB -X-3.5i >> " * ps, text_record([3.2125 7.5], "Gridding of Data"))
	gmt("psscale -Dx3.25i/0.35i+jTC+w5i/0.25i+h -C" * cpt * " -O -Y-0.75i >> " * ps)

	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex17(g_root_dir, out_path)
	# Purpose:    Illustrates clipping of images using coastlines
	# GMT progs:  grd2cpt, grdgradient, grdimage, pscoast, pstext

	d_path = g_root_dir * "doc/examples/ex17/"
	ps = out_path * "example_17.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	# First generate geoid image w/ shading
	geoid_cpt = gmt("grd2cpt @india_geoid.nc -Crainbow")
	gmt("grdimage @india_geoid.nc -I+a45+nt1 -JM6.5i -C -P -K > " * ps, geoid_cpt)

	# Then use gmt pscoast to initiate clip path for land
	if (GMTver < 6.0)
		gmt("pscoast -R" * d_path * "india_geoid.nc -J -O -K -Dl -Gc >> " * ps)
	else
		gmt("pscoast -R@india_geoid.nc -J -O -K -Dl -Gc >> " * ps)
	end

	# Now generate topography image w/shading
	fid = open("gray.cpt","w");		println(fid, "-10000 150 10000 150");	close(fid)
	gmt("grdimage @india_topo.nc -I+a45+nt1 -J -Cgray.cpt -O -K >> " * ps)

	# Finally undo clipping and overlay basemap
	gmt("pscoast -R -J -O -K -Q -B10f5 -B+t\"Clipping of Images\" >> " * ps)

	# Put a color legend on top of the land mask
	gmt("psscale -DjTR+o0.3i/0.1i+w4i/0.2i+h -R -J -C -Bx5f1 -By+lm -I -O -K >> " * ps, geoid_cpt)

	# Add a text paragraph
	t = ["> 90 -10 12p 3i j"
		"@_@%5%Example 17.@%%@_  We first plot the color geoid image"
		"for the entire region, followed by a gray-shaded @#etopo5@#"
		"image that is clipped so it is only visible inside the coastlines."]
	gmt("pstext -R -J -O -M -Gwhite -Wthinner -TO -D-0.1i/0.1i -F+f12,Times-Roman+jRB >> " * ps, text_record(t))
	rm("gray.cpt");
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex18(g_root_dir, out_path)
	# Purpose:    Illustrates volumes of grids inside contours and spatial selection of data
	# GMT progs:  gmtset, gmtselect, gmtspatial, grdclip, grdcontour, grdgradient, grdimage
	# GMT progs:  grdmath, grdvolume, makecpt, pscoast, psscale, pstext, psxy

	d_path = g_root_dir * "doc/examples/ex18/"
	ps = out_path * "example_18.ps"

	# Use spherical gmt projection since SS data define on sphere
	gmt("gmtset PROJ_ELLIPSOID Sphere FORMAT_FLOAT_OUT %g PROJ_LENGTH_UNIT inch PS_CHAR_ENCODING Standard+ PS_MEDIA letter")
	gmt("destroy")

	# Define location of Pratt seamount and the 400 km diameter
	pratt = [-142.65 56.25 400]

	# First generate gravity image w/ shading, label Pratt, and draw a circle
	# of radius = 200 km centered on Pratt.

	grav_cpt = gmt("makecpt -Crainbow -T-60/60");
	GAK_gulf_grav_i = gmt("grdgradient @AK_gulf_grav.nc -Nt1 -A45");
	gmt("grdimage @AK_gulf_grav.nc -I -JM5.5i -C -B2f1 -P -K -X1.5i" *
		" -Y5.85i > " * ps, GAK_gulf_grav_i, grav_cpt)
	if (GMTver < 6.0)
		gmt("pscoast -R" * d_path * "AK_gulf_grav.nc -J -O -K -Di -Ggray -Wthinnest >> " * ps)
	else
		gmt("pscoast -R@AK_gulf_grav.nc -J -O -K -Di -Ggray -Wthinnest >> " * ps)
	end
	gmt("psscale -DJBC+o0/0.4i -R -J -C -Bx20f10 -By+l\"mGal\" -O -K >> " * ps, grav_cpt)
	gmt("pstext -R -J -O -K -D0.1i/0.1i -F+f12p,Helvetica-Bold+jLB >> " * ps, text_record(pratt, "Pratt"))
	gmt("psxy -R -J -O -K -SE- -Wthinnest >> " * ps, pratt)

	# Then draw 10 mGal contours and overlay 50 mGal contour in green
	gmt("grdcontour @AK_gulf_grav.nc -J -C20 -B2f1 -BWSEn -O -K -Y-4.85i >> " * ps)
	# Save 50 mGal contours to individual files, then plot them
	gmt("grdcontour @AK_gulf_grav.nc -C10 -L49/51 -Dsm_%c.txt")
	gmt("psxy -R -J -O -K -Wthin,green sm_C.txt >> " * ps)
	gmt("psxy -R -J -O -K -Wthin,green sm_O.txt >> " * ps)
	gmt("pscoast -R -J -O -K -Di -Ggray -Wthinnest >> " * ps)
	gmt("psxy -R -J -O -K -SE- -Wthinnest >> " * ps, pratt)
	rm("sm_O.txt")		# Only consider the closed contours

	# Now determine centers of each enclosed seamount > 50 mGal but only plot
	# the ones within 200 km of Pratt seamount.

	# First determine mean location of each closed contour and add it to the file centers.txt
	centers = gmt("gmtspatial -Q -fg sm_C.txt")

	# Only plot the ones within 200 km
	t = gmt("gmtselect -C+d200k -fg", centers, pratt)
	gmt("psxy -R -J -O -K -SC0.04i -Gred -Wthinnest >> " * ps, t)
	gmt("psxy -R -J -O -K -ST0.1i -Gyellow -Wthinnest >> " * ps, pratt)

	# Then report the volume and area of these seamounts only
	# by masking out data outside the 200 km-radius circle
	# and then evaluate area/volume for the 50 mGal contour

	Gmask = gmt("grdmath -R " * @sprintf("%f %f", pratt[1], pratt[2]) * " SDIST =")
	Gmask = gmt("grdclip -Sa200/NaN -Sb200/1", Gmask)
	if (GMTver < 6)
		Gtmp = gmt("grdmath " * d_path * "AK_gulf_grav.nc ? MUL =", Gmask);
	else
		Gtmp = gmt("grdmath @AK_gulf_grav.nc ? MUL =", Gmask);
	end
	area = gmt("grdvolume -C50 -Sk", Gtmp); 	# | cut -f2`
	volume = gmt("grdvolume -C50 -Sk -fg", Gtmp); # | cut -f3`

	T = text_record(["> -149 52.5 14p 2.6i j"
		@sprintf("Volumes: %d mGal\\264km@+2@+", volume[1].data[3])
		""
		@sprintf("Areas: %.2f km@+2@+", area[1].data[2])])

	gmt("pstext -R -J -O -M -Gwhite -Wthin -Dj0.3i -F+f14p,Helvetica-Bold+jLB -C0.1i >> " * ps, T)

	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex19(g_root_dir, out_path)
# The use of the circuit.ras screws the PS (to investigate)
	# Purpose:    Illustrates various color pattern effects for maps
	# GMT progs:  gmtset, grdimage, grdmath, makecpt, pscoast, pstext, psimage

	d_path = g_root_dir * "doc/examples/ex19/"
	ps = out_path * "example_19.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	# First make a worldmap with graded blue oceans and rainbow continents
	Glat = gmt("grdmath -Rd -I1 -r Y COSD 2 POW =")
	Glon = gmt("grdmath -Rd -I1 -r X =")
	fid = open("lat.cpt","w");		println(fid, "0 white 1 blue");		close(fid)
	lon_cpt = gmt("makecpt -Crainbow -T-180/180")
	gmt("grdimage -JI0/6.5i -Clat.cpt -P -K -Y7.5i -B0 -nl > " * ps, Glat)
	gmt("pscoast -R -J -O -K -Dc -A5000 -Gc >> " * ps)
	gmt("grdimage -J -C -O -K -nl >> " * ps, Glon, lon_cpt)
	gmt("pscoast -R -J -O -K -Q >> " * ps)
	gmt("pscoast -R -J -O -K -Dc -A5000 -Wthinnest >> " * ps)
	gmt("pstext -R -J -O -K -F+f32p,Helvetica-Bold,red=thinner >> " * ps, text_record([0 20], "15TH INTERNATIONAL"))
	gmt("pstext -R -J -O -K -F+f32p,Helvetica-Bold,red=thinner >> " * ps, text_record([0 -10], "GMT CONFERENCE"))
	gmt("pstext -R -J -O -K -F+f18p,Helvetica-Bold,green=thinnest >> " * ps, text_record([0 -30], "Honolulu, Hawaii, April 1, 2018"))

	# Then show example of color patterns and placing a PostScript image
	if (GMTver < 6)
		gmt("pscoast -R -J -O -K -Dc -A5000 -Gp86+fred+byellow+r100 -Sp100/" * d_path * "circuit.ras -B0 -Y-3.25i >> " * ps)
	else
		gmt("pscoast -R -J -O -K -Dc -A5000 -Gp86+fred+byellow+r100 -Sp@circuit.png+r100 -B0 -Y-3.25i >> " * ps)
	end
	gmt("pstext -R -J -O -K -F+f32p,Helvetica-Bold,lightgreen=thinner >> " * ps, text_record([0 30], "SILLY USES OF"))
	gmt("pstext -R -J -O -K -F+f32p,Helvetica-Bold,magenta=thinner >> " * ps, text_record([0 -30], "COLOR PATTERNS"))
	if (GMTver < 6)
		gmt("psimage -DjCM+w3i -R -J " * d_path * "GMT_covertext.eps -O -K >> " * ps)
	else
		gmt("psimage -DjCM+w3i -R -J @GMT_covertext.eps -O -K >> " * ps)
	end

	# Finally repeat 1st plot but exchange the patterns
	gmt("grdimage -J -C -O -K -Y-3.25i -B0 -nl >> " * ps, Glon, lon_cpt)
	gmt("pscoast -R -J -O -K -Dc -A5000 -Gc >> " * ps)
	gmt("grdimage -J -Clat.cpt -O -K -nl >> " * ps, Glat)
	gmt("pscoast -R -J -O -K -Q >> " * ps)
	gmt("pscoast -R -J -O -K -Dc -A5000 -Wthinnest >> " * ps)
	gmt("pstext -R -J -O -K -F+f32p,Helvetica-Bold,red=thinner >> " * ps, text_record([0 20], "15TH INTERNATIONAL"))
	gmt("pstext -R -J -O -K -F+f32p,Helvetica-Bold,red=thinner >> " * ps, text_record([0 -10], "GMT CONFERENCE"))
	gmt("pstext -R -J -O -F+f18p,Helvetica-Bold,green=thinnest >> " * ps, text_record([0 -30], "Honolulu, Hawaii, April 1, 2018"))
	rm("lat.cpt");	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex20(g_root_dir, out_path)
	# Purpose:    Extend GMT to plot custom symbols
	# GMT progs:  pscoast, psxy

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

	gmt("gmtset -Du")
	gmt("destroy")
	gmt("pscoast -Rg -JR9i -Bx60 -By30 -B+t\"Hotspot Islands and Hot Cities\" -Gdarkgreen -Slightblue -Dc -A5000 -K > " * ps)
	gmt("psxy -R -J @hotspots.txt -Skvolcano -O -K -Wthinnest -Gred >> " * ps)

	# Overlay a few bullseyes at NY, Cairo, and Perth
	cities = [-74 40.45 0.5; 31.15 30.03 0.5; 115.49 -31.58 0.5; -56.16 -34.9 0.5]
	if (GMTver < 6)
		gmt("psxy -R -J -Sk" * d_path * "bullseye -O >> " * ps, cities)
	else
		gmt("psxy -R -J -Sk@bullseye -O >> " * ps, cities)
	end
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex21(g_root_dir, out_path)	
	# Purpose:   
	# GMT progs: 

	d_path = g_root_dir * "doc/examples/ex21/"
	ps = out_path * "example_21.ps"

	# File has time stored as dd-Mon-yy so set input format to match it
	gmt("gmtset FORMAT_DATE_IN dd-o-yy FORMAT_DATE_MAP o FONT_ANNOT_PRIMARY +10p" *
		" FORMAT_TIME_PRIMARY_MAP abbreviated PS_CHAR_ENCODING ISOLatin1+ PROJ_LENGTH_UNIT inch PS_MEDIA letter")
	gmt("destroy")

	# Pull out a suitable region string in yyy-mm-dd format
	R = gmt("gmtinfo -fT -I50 @RHAT_price.csv");		# The output is a cell
	R = R[1].text[1]
	ind = strfind(R, "/")
	wT = R[3:ind[1]-1]				# West and East in T time coordinates (to be used later)
	eT = R[ind[1]+1:ind[2]-1]
	sF = R[ind[2]+1:ind[3]-1]

	# Lay down the basemap:
	gmt("psbasemap " * R * " -JX9i/6i -K -Bsx1Y -Bpxa3Of1o -Bpy50+p\"\\044 \"" *
		" -BWSen+t\"RedHat (RHT) Stock Price Trend since IPO\"+glightgreen > " * ps)

	# Plot main window with open price as red line over yellow envelope of low/highs

	RHAT1_env = gmt("gmtconvert -o0,2 -f0T @RHAT_price.csv")
	RHAT2_env = gmt("gmtconvert -o0,3 -f0T -I -T @RHAT_price.csv")
	RHAT_env = [RHAT1_env[1].data; RHAT2_env[1].data]
	gmt("psxy -R -J -Gyellow -O -K >> " * ps, RHAT_env)
	gmt("psxy -R -J @RHAT_price.csv -Wthin,red -O -K >> " * ps)

	# Draw P Wessel's purchase price as line and label it.  Note we temporary switch
	# back to default yyyy-mm-dd format since that is what gmt info gave us.
	fid = open("RHAT.pw","w")
	println(fid, "05-May-00	0")
	println(fid, "05-May-00	300")
	close(fid)
	gmt("psxy -R -J RHAT.pw -Wthinner,- -O -K >> " * ps)
	fid = open("RHAT.pw","w")
	println(fid, "01-Jan-99	25")
	println(fid, "01-Jan-02	25")
	close(fid)
	gmt("psxy -R -J RHAT.pw -Wthick,- -O -K >> " * ps)
	gmt("pstext -R -J -O -K -D1.5i/0.05i -N -F+f12p,Bookman-Demi+jLB --FORMAT_DATE_IN=yyyy-mm-dd >> " * ps,
		text_record(wT * " 25 PW buy"))

	# Draw P Wessel's sales price as line and label it.
	fid = open("RHAT.pw","w")
	println(fid, "25-Jun-07	0")
	println(fid, "25-Jun-07	300")
	close(fid)
	gmt("psxy -R -J RHAT.pw -Wthinner,- -O -K >> " * ps)
	fid = open("RHAT.pw","w")
	println(fid, "01-Aug-06	23.8852");
	println(fid, "01-Jan-08	23.8852");
	close(fid);
	gmt("psxy -R -J RHAT.pw -Wthick,- -O -K >> " * ps)
	gmt("pstext -R -J -O -K -Dj0.8i/0.05i -N -F+f12p,Bookman-Demi+jRB --FORMAT_DATE_IN=yyyy-mm-dd >> " * ps,
		text_record(eT * " 23.8852 PW sell"))

	# Get smaller region for insert for trend since 2004
	R = @sprintf("-R2004T/%s/%s/40", eT, sF)

	# Lay down the basemap, using Finnish annotations and place the insert in the upper right
	gmt("psbasemap --GMT_LANGUAGE=fi " * R * " -JX6i/3i -Bpxa3Of3o -Bpy10+p\"\\044 \" -BESw+glightblue -Bsx1Y" *
		" -O -K -X3i -Y3i >> " * ps)

	# Again, plot close price as red line over yellow envelope of low/highs

	gmt("psxy -R -J -Gyellow -O -K >> " * ps, RHAT_env)
	gmt("psxy -R -J @RHAT_price.csv -Wthin,red -O -K >> " * ps)

	# Draw P Wessel's sales price as dashed line
	gmt("psxy -R -J RHAT.pw -Wthick,- -O -K >> " * ps)

	# Mark sales date
	fid = open("RHAT.pw","w")
	println(fid, "25-Jun-07	0")
	println(fid, "25-Jun-07	300")
	close(fid)
	gmt("psxy -R -J RHAT.pw -Wthinner,- -O >> " * ps)

	rm("RHAT.pw")
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex22(g_root_dir, out_path)
	# Purpose:    Automatic map of last 7 days of world-wide seismicity
	# GMT progs:  gmtset, pscoast, psxy, pslegend

	d_path = g_root_dir * "doc/examples/ex22/"
	ps = out_path * "example_22.ps"

	gmt("gmtset -Du")
	gmt("gmtset FONT_ANNOT_PRIMARY 10p FONT_TITLE 18p FORMAT_GEO_MAP ddd:mm:ssF")
	gmt("destroy")

	# Get the data (-q quietly) from USGS using the wget (comment out in case
	# your system does not have wget or curl)
	# 
	# wget http://neic.usgs.gov/neis/gis/bulletin.asc -q -O neic_quakes.txt
	# curl http://neic.usgs.gov/neis/gis/bulletin.asc -s > neic_quakes.txt
	# 
	# Count the number of events (to be used in title later. one less due to header)

	if (GMTver < 6)
		n = 77
		USGS = d_path * "USGS.ras"
	else
		n = gmt("info @neic_quakes_22.txt -h1 -Fi -o2")
		n = n[1].data[1]
		USGS = "@USGS.png"
	end
	
	# Pull out the first and last timestamp to use in legend title
	#gmt("info -h1 -f0T -i0 @neic_quakes_22.txt -C --TIME_UNIT=d -I1 -o0 --FORMAT_CLOCK_OUT=- > F.txt")
	#gmt("info -h1 -f0T -i0 @neic_quakes_22.txt -C --TIME_UNIT=d -I1 -o1 --FORMAT_CLOCK_OUT=- > L.txt")
	#first = rstrip(readstring("F.txt"))
	#last  = rstrip(readstring("L.txt"))
	first = "04/04/19 00:04:33"
	last  = "04/04/25 11:11:33"

	# Assign a string that contains the current user @ the current computer node.
	# Note that two @@ is needed to print a single @ in gmt pstext:

	# set me = "$user@@`hostname`"
	me = "GMT guru @@ GMTbox"

	# Start plotting. First lay down map, then plot quakes with size = magintude/50":
	neis = gmt("makecpt -Cred,green,blue -T0,100,300,10000 -N")
	gmt("pscoast -Rg -JK180/9i -B45g30 -B+t\"World-wide earthquake activity\" -Gbrown" *
		" -Slightblue -Dc -A1000 -K -Y2.75i > " * ps)
	gmt("psxy -R -JK -O -K -C -Sci -Wthin -h -i3,2,5,4+s0.02 @neic_quakes_22.txt >> " * ps, neis)

	# Create legend input file for NEIS quake plot
	neis_legend = text_record([
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
	 "G 0.25l"
	 "P"
	 "T USGS/NEIS most recent earthquakes for the last seven days. The data were"
	 "T obtained automatically from the USGS Earthquake Hazards Program page at"
	 "T @_http://neic/usgs.gov @_. Interested users may also receive email alerts"
	 "T from the USGS."
	 "T This script can be called daily to update the latest information."
	 "G 0.4i"
	 "I " * USGS * " 1i RT"
	 "G -0.3i"
	 @sprintf("L 12 6 LB %s", me)])
	 
	# OK, now we can actually run gmt pslegend.  We center the legend below the map.
	# Trial and error shows that 1.7i is a good legend height:

	gmt("pslegend -DJBC+o0/0.4i+w7i/1.7i -R -J -O -F+p+glightyellow >> " * ps, neis_legend)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex23(g_root_dir, out_path)
	# Purpose:    Plot distances from Rome and draw shortest paths
	# GMT progs:  grdmath, grdcontour, pscoast, psxy, pstext, grdtrack

	d_path = g_root_dir * "doc/examples/ex23/"
	ps = out_path * "example_23.ps"

	# Position and name of central point:
	lon  = 12.50
	lat  = 41.99
	#lon = -78.8416666666666667
	#lat = 9.4683333333
	name = "Rome"

	gmt("gmtset -Du")
	gmt("destroy")
	Gdist = gmt(@sprintf("grdmath -Rg -I1 %f %f SDIST", lon, lat))

	gmt("pscoast -Rg -JH90/9i -Glightgreen -Sblue -A1000 -Dc -Bg30 -B+t\"Distances from " * 
		name * " to the World\" -K -Wthinnest > " * ps)
	gmt("grdcontour -A1000+v+u\" km\"+fwhite -Glz-/z+ -S8 -C500 -O -K -JH90/9i -Wathin,white " *
		"-Wcthinnest,white,- >> " * ps, Gdist)
	
	# Location info for 5 other cities + label justification
	if (GMTver < 6)
		cities = Array{Any}(5)
		cities[1] = "105.87 21.02 LM HANOI"
		cities[2] = "282.95 -12.1 LM LIMA"
		cities[3] = "178.42 -18.13 LM SUVA"
		cities[4] = "237.67 47.58 RM SEATTLE"
		cities[5] = "28.20 -25.75 LM PRETORIA"
		fid = open("cities.txt","w")
		for k = 1:5
			println(fid, cities[k])
		end
		close(fid)
	else
		cities = [105.87 21.02; 282.95  -12.1; 178.42 -18.13; 237.67 47.58; 28.20 -25.75];
		just_names = ["LM HANOI", "LM LIMA", "LM SUVA", "RM SEATTLE", "LM PRETORIA"];
		D = text_record(cities, just_names)
	end

	# For each of the cities, plot great circle arc to Rome with gmt psxy
	gmt("psxy -R -J -O -K -Wthickest,red >> " * ps, [lon lat; 105.87 21.02])
	gmt("psxy -R -J -O -K -Wthickest,red >> " * ps, [lon lat; 282.95 -12.1])
	gmt("psxy -R -J -O -K -Wthickest,red >> " * ps, [lon lat; 178.42 -18.13])
	gmt("psxy -R -J -O -K -Wthickest,red >> " * ps, [lon lat; 237.67 47.58])
	gmt("psxy -R -J -O -K -Wthickest,red >> " * ps, [lon lat; 28.20 -25.75])

	# Plot red squares at cities and plot names:
	if (GMTver < 6)
		gmt("psxy -R -J -O -K -Ss0.2 -Gred -Wthinnest cities.txt >> " * ps)
		gmt("pstext -R -J -O -K -Dj0.15/0 -F+f12p,Courier-Bold,red+j -N >> " * ps, cities)
	else
		gmt("psxy -R -J -O -K -Ss0.2 -Gred -Wthinnest >> " * ps, cities)
		gmt("pstext -R -J -O -K -Dj0.15/0 -F+f12p,Courier-Bold,red+j -N >> " * ps, D)
	end

	# Place a yellow star at Rome
	gmt("psxy -R -J -O -K -Sa0.2i -Gyellow -Wthin >> " * ps, [12.5 41.99])

	# Sample the distance grid at the cities and use the distance in km for labels
	if (GMTver < 6)
		dist = gmt("grdtrack cities.txt -G", Gdist);
		t = Array{Any}(5);
		for k = 1:5
			t[k] = @sprintf("%f %f %d", dist[1].data[k,1], dist[1].data[k,2], dist[1].data[k,end]);
		end
		gmt("pstext -R -J -O -D0/-0.2i -N -Gwhite -W -C0.02i -F+f12p,Helvetica-Bold+jCT >> " * ps, t)
		rm("cities.txt");
	else
		dist = gmt("grdtrack -G", D, Gdist);
		gmt("pstext -R -J -O -D0/-0.2i -N -Gwhite -W -C0.02i -F+f12p,Helvetica-Bold+jCT+z%.0f >> " * ps, dist)
	end
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex24(g_root_dir, out_path)
	# Purpose:   Display distribution of antipode types
	# GMT progs: gmtset, grdlandmask, grdmath, grd2xyz, gmtmath, grdimage, pscoast, pslegend

	# Highlight oceanic earthquakes within 3000 km of Hobart and > 1000 km from dateline
	d_path = g_root_dir * "doc/examples/ex24/"
	ps = out_path * "example_24.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	dateline = [180 0; 180 -90];

	if (GMTver < 6)
		fid = open("point.txt", "w");	println(fid, "147:13 -42:48 6000 Hobart");	close(fid);
		T = "147:13 -42:48 Hobart"
	else
		T= text_record([147.216666666667 -42.8], "Hobart")
	end

	R = gmt("gmtinfo -I10 @oz_quakes_24.txt");
	gmt("pscoast " * R[1].text[1] * " -JM9i -K -Gtan -Sdarkblue -Wthin,white -Dl -A500 -Ba20f10g10 -BWeSn > " * ps)
	gmt("psxy -R -J -O -K @oz_quakes_24.txt -Sc0.05i -Gred >> " * ps)
	t = gmt("gmtselect @oz_quakes_24.txt -L+d1000k -Nk/s -C+d3000k -fg -R -Il", dateline, [147.216666666667 -42.8])
	gmt("psxy -R -JM -O -K -Sc0.05i -Ggreen >> " * ps, t)
	if (GMTver < 6)
		gmt("psxy point.txt -R -J -O -K -SE- -Wfat,white >> " * ps)
		gmt("pstext -R -J -O -K -F+f14p,Helvetica-Bold,white+jLT -D0.1i/-0.1i >> " * ps, T)
		gmt("psxy -R -J -O -K point.txt -Wfat,white -S+0.2i >> " * ps)
		rm("point.txt");
	else
		gmt("psxy -R -J -O -K -SE- -Wfat,white >> " * ps, [147.2166666666666667 -42.8 6000])
		gmt("pstext -R -J -O -K -F+f14p,Helvetica-Bold,white+jLT -D0.1i/-0.1i >> " * ps, T)
		gmt("psxy -R -J -O -K -Wfat,white -S+0.2i >> " * ps, [147.216666666666667 -42.8 6000])
	end
	gmt("psxy -R -J -O -Wfat,white -A >> " * ps, dateline)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex25(g_root_dir, out_path)
	# Purpose:   Display distribution of antipode types
	# GMT progs: gmtset, grdlandmask, grdmath, grd2xyz, gmtmath, grdimage, pscoast, pslegend

	# Create D minutes global grid with -1 over oceans and +1 over land
	d_path = g_root_dir * "doc/examples/ex25/"
	ps = out_path * "example_25.ps"
	
	D  = 30

	gmt("gmtset -Du")
	gmt("destroy")
	Gwetdry = gmt(@sprintf("grdlandmask -Rg -I%dm -Dc -A500 -N-1/1/1/1/1 -r", D))
	# Manipulate so -1 means ocean/ocean antipode, +1 = land/land, and 0 elsewhere
	Gkey = gmt("grdmath -fg ? DUP 180 ROTX FLIPUD ADD 2 DIV =", Gwetdry)
	# Calculate percentage area of each type of antipode match.
	Gscale = gmt(@sprintf("grdmath -Rg -I%dm -r Y COSD 60 %d DIV 360 MUL DUP MUL PI DIV DIV 100 MUL =", D, D))
	#Gtmp   = gmt("grdmath -fg ? -1 EQ 0 NAN ? MUL =", Gkey, Gscale)
	Gtmp   = gmt("grdmath -fg ? -1 EQ 0 NAN =", Gkey)
	Gtmp.z = Gtmp.z .* Gscale.z

	key    = gmt("grd2xyz -s -ZTLf", Gtmp)
	ocean  = gmt("gmtmath -bi1f -Ca -S ? SUM UPPER RINT =", key)
#	Gtmp   = gmt("grdmath -fg ? 1 EQ 0 NAN ? MUL =", Gkey, Gscale)
	Gtmp   = gmt("grdmath -fg ? 1 EQ 0 NAN =", Gkey)
	Gtmp.z = Gtmp.z .* Gscale.z
	key    = gmt("grd2xyz -s -ZTLf", Gtmp)
	land   = gmt("gmtmath -bi1f -Ca -S ? SUM UPPER RINT =", key)
#	Gtmp   = gmt("grdmath -fg ? 0 EQ 0 NAN ? MUL", Gkey, Gscale)
	Gtmp   = gmt("grdmath -fg ? 0 EQ 0 NAN", Gkey)
	Gtmp.z = Gtmp.z .* Gscale.z
	key    = gmt("grd2xyz -s -ZTLf", Gtmp)
	mixed  = gmt("gmtmath -bi1f -Ca -S ? SUM UPPER RINT =", key)

	# Generate corresponding color table
	C = gmt("makecpt -Cblue,gray,red -T-1.5/1.5/1")
	# But unfortunately this palette is not correct, so lets patch it
	C.colormap[1,1:2] = 0;		C.colormap[1,3] = 1;
	C.colormap[3,2:3] = 0;		C.colormap[3,1] = 1;

	# Create the final plot and overlay coastlines
	gmt("gmtset FONT_ANNOT_PRIMARY +10p FORMAT_GEO_MAP dddF PROJ_LENGTH_UNIT inch PS_CHAR_ENCODING Standard+ PS_MEDIA letter")
	gmt("destroy")
	gmt("grdimage -JKs180/9i -Bx60 -By30 -BWsNE+t\"Antipodal comparisons\" -K -C -Y1.2i -nn > " * ps, Gkey, C)
	gmt("pscoast -R -J -O -K -Wthinnest -Dc -A500 >> " * ps)
	# Place an explanatory legend below
	gmt("pslegend -R -J -O -DJBC+w6i -Y-0.2i -F+pthick >> " * ps, text_record([
		"N 3"
		@sprintf("S 0.15i s 0.2i red  0.25p 0.3i Terrestrial Antipodes [%d %%]", land[1].data[1])
		@sprintf("S 0.15i s 0.2i blue 0.25p 0.3i Oceanic Antipodes [%d %%]", ocean[1].data[1])
		@sprintf("S 0.15i s 0.2i gray 0.25p 0.3i Mixed Antipodes [%d %%]", mixed[1].data[1])]))
	
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex26(g_root_dir, out_path)
	# Purpose:   Demonstrate general vertical perspective projection
	# GMT progs: pscoast

	d_path = g_root_dir * "doc/examples/ex26/"
	ps = out_path * "example_26.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	# first do an overhead of the east coast from 160 km altitude point straight down
	lat = 41.5;	lon = -74;	alt = 160;	tilt = 0;	azim = 0;	twist = 0;	width = 0;	height = 0;
	PROJ = @sprintf("-JG%f/%f/%f/%f/%f/%f/%f/%f/4i", lon, lat, alt, azim, tilt, twist, width, height)
	gmt("pscoast -Rg " * PROJ * " -X1i -B5g5 -Glightbrown -Slightblue -W -Dl -N1/1p,red -N2,0.5p -P -K -Y5i > " * ps)

	# Now point from an altitude of 160 km with a specific tilt and azimuth and with a wider restricted
	# view and a boresight twist of 45 degrees
	tilt=55;	azim=210;	twist=45;	width=30;	height=30;
	PROJ = @sprintf("-JG%f/%f/%f/%f/%f/%f/%f/%f/5i", lon, lat, alt, azim, tilt, twist, width, height)
	gmt("pscoast -Rg " * PROJ * " -B5g5 -Glightbrown -Slightblue -W -Ia/blue -Di -Na -O -X1i -Y-4i >> " * ps)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex27(g_root_dir, out_path)
	# Purpose:   Illustrates how to plot Mercator img grids
	# GMT progs: makecpt, mapproject, grdgradient, grdimage, grdinfo, pscoast, img2grd (suppl)

	d_path = g_root_dir * "doc/examples/ex27/"
	ps = out_path * "example_27.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	# Gravity in tasman_grav.nc is in 0.1 mGal increments and the grid
	# is already in projected Mercator x/y units.

	# Make a suitable cpt file for mGal
	grav_cpt = gmt("makecpt -T-120/120 -Crainbow")

	# Since this is a Mercator grid we use a linear projection
	gmt("grdimage @tasman_grav.nc=ns/0.1 -I+a45+nt1 -Jx0.25i -C -P -K > " * ps, grav_cpt)

	# Then use gmt pscoast to plot land; get original -R from grid remark
	# and use Mercator gmt projection with same scale as above on a spherical Earth

	R = gmt("grdinfo @tasman_grav.nc")
	# Here we need to fish the last word of the third (the 'Remark') line issued by grdinfo
	R = R[1].text[3];	k = length(R);
	while (R[k] != ' ')
		k = k - 1;
	end
	R = R[k+1:end];		# The result must be -R145/170/-50.0163575733/-24.9698584055
	gmt("pscoast " * R * " -Jm0.25i -Ba10f5 -BWSne -O -K -Gblack --PROJ_ELLIPSOID=Sphere" *
		" -Cwhite -Dh+ --FORMAT_GEO_MAP=dddF >> " * ps)

	# Put a color legend in top-left corner of the land mask
	gmt("psscale -DjTL+o1c+w2i/0.15i " * R * " -J -C -Bx50f10 -By+lmGal -I -O -F+gwhite+p1p >> " * ps, grav_cpt)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex28(g_root_dir, out_path)
	# Purpose:   Illustrates how to mix UTM data and UTM gmt projection
	# GMT progs: makecpt, grdgradient, grdimage, grdinfo, grdmath, pscoast, pstext, mapproject

	d_path = g_root_dir * "doc/examples/ex28/"
	ps = out_path * "example_28.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	if (GMTver < 6)  Kilauea = d_path * "Kilauea.utm.nc"
	else             Kilauea = "@Kilauea.utm.nc"
	end
	# Get intensity grid and set up a color table
	GKilauea_utm_i = gmt("grdgradient @Kilauea.utm.nc -Nt1 -A45 -G")
	Kilauea_cpt = gmt("makecpt -Ccopper -T0/1500")
	# Lay down the UTM topo grid using a 1:16,000 scale
	gmt("grdimage  @Kilauea.utm.nc -I -C -Jx1:160000 -P -K" *
		" --FORMAT_FLOAT_OUT=%.10g --FONT_ANNOT_PRIMARY=9p > " * ps, GKilauea_utm_i, Kilauea_cpt)
	# Overlay geographic data and coregister by using correct region and gmt("projection with the same scale
	gmt("pscoast -R" * Kilauea * " -Ju5Q/1:160000 -O -K -Df+ -Slightblue -W0.5p -B5mg5m -BNE" *
		" --FONT_ANNOT_PRIMARY=12p --FORMAT_GEO_MAP=ddd:mmF >> " * ps)
	gmt("pstext -R -J -O -K -F+f12p,Helvetica-Bold+jCB >> " * ps, text_record([-155.272222222222 19.4388888888889], "KILAUEA"))
	gmt("psbasemap -R -J -O -K --FONT_ANNOT_PRIMARY=9p -LjRB+c19:23N+f+w5k+l1:16,000+u+o0.2i" *
		" --FONT_LABEL=10p >> " * ps)
	# Annotate in km but append ,000m to annotations to get customized meter labels
	gmt("psbasemap -R" * Kilauea * "+Uk -Jx1:160 -B5g5+u\"@:8:000m@::\"" * 
		" -BWSne -O --FONT_ANNOT_PRIMARY=10p --MAP_GRID_CROSS_SIZE_PRIMARY=0.1i --FONT_LABEL=10p >> " * ps)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex29(g_root_dir, out_path)
	# Purpose:   Illustrates spherical surface gridding with Green's function of splines
	# GMT progs: makecpt, grdcontour, grdgradient, grdimage, grdmath greenspline, psscale, pstext

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
	gmt("gmtset -Du")
	gmt("destroy")
	Gproj_ellipsoid = gmt("grdmath -Rg -I4 -r X COSD " * "$a" * " DIV DUP MUL X SIND " * "$b" * 
		" DIV DUP MUL ADD Y COSD DUP MUL MUL Y SIND " * "$c" * " DIV DUP MUL ADD SQRT INV =")
	#  Do both Parker and Wessel/Becker solutions (tension = 0.9975)
	Gmars  = gmt("greenspline -R? @mars370.txt -D4 -Sp -G", Gproj_ellipsoid);
	Gmars2 = gmt("greenspline -R? @mars370.txt -D4 -Sq0.9975 -G", Gproj_ellipsoid);
	# Scale to km and remove PROJ_ELLIPSOID
	Gmars  = gmt("grdmath ? 1000 DIV ? SUB =", Gmars,  Gproj_ellipsoid)
	Gmars2 = gmt("grdmath ? 1000 DIV ? SUB =", Gmars2, Gproj_ellipsoid)
	mars_cpt = gmt("makecpt -Crainbow -T-7/15");
	Gmars2_i = gmt("grdgradient -fg -Ne0.75 -A45 -G", Gmars2)
	gmt("grdimage -I -C -B30g30 -BWsne -JH0/7i -P -K -E200" *
		" --FONT_ANNOT_PRIMARY=12p -X0.75i > " * ps, Gmars2, Gmars2_i, mars_cpt)
	gmt("grdcontour -J -O -K -C1 -A5 -Glz+/z- >> " * ps, Gmars2)
	gmt("psxy -Rg -J -O -K -Sc0.045i -Gblack @mars370.txt  >> " * ps)
	gmt("pstext -R -J -O -K -N -D-3.5i/-0.2i -F+f14p,Helvetica-Bold+jLB >> " * ps, text_record([0 90], "b)"))
	Gmars_i = gmt("grdgradient -fg -Ne0.75 -A45 -G", Gmars);
	gmt("grdimage -I -C -B30g30 -BWsne -J -O -K -Y4.2i -E200" *
		" --FONT_ANNOT_PRIMARY=12p >> " * ps, Gmars, Gmars_i, mars_cpt)
	gmt("grdcontour -J -O -K -C1 -A5 -Glz+/z- >> " * ps, Gmars)
	gmt("psxy -Rg -J -O -K -Sc0.045i -Gblack @mars370.txt  >> " * ps)
	gmt("psscale -C -O -K -R -J -DJBC+o0/0.15i+w6i/0.1i+h -I --FONT_ANNOT_PRIMARY=12p -Bx2f1 -By+lkm >> " * ps, mars_cpt)
	gmt("pstext -R -J -O -N -D-3.5i/-0.2i -F+f14p,Helvetica-Bold+jLB >> " * ps, text_record([0 90], "a)"))
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex30(g_root_dir, out_path)
	# Purpose:   Show graph mode and math angles
	# GMT progs: gmtmath, psbasemap, pstext and psxy

	d_path = g_root_dir * "doc/examples/ex30/"
	ps = out_path * "example_30.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	gmt("psbasemap -R0/360/-1.25/1.75 -JX8i/6i -Bx90f30+u\"\\312\" -By1g10 -BWS+t\"Two Trigonometric Functions\"" *
		" -K --MAP_FRAME_TYPE=graph --MAP_VECTOR_SHAPE=0.5 > " * ps)

	#Draw sine an cosine curves
	t = gmt("gmtmath -T0/360/0.1 T COSD =");
	gmt("psxy -R -J -O -K -W3p >>  " * ps, t)
	t = gmt("gmtmath -T0/360/0.1 T SIND =");
	gmt("psxy -R -J -O -K -W3p,0_6:0 --PS_LINE_CAP=round >> " * ps, t)

	# Indicate the x-angle = 120 degrees
	gmt("psxy   -R -J -O -K -W0.5p,- >> " * ps, [120 -1.25; 120 1.25])
	if (GMTver < 6)
		T = [
			"360 1 18p,Times-Roman RB x = cos(@%12%a@%%)"
			"360 0 18p,Times-Roman RB y = sin(@%12%a@%%)"
			"120 -1.25 14p,Times-Roman LB 120\\312"
			"370 -1.35 24p,Symbol LT a"
			"-5 1.85 24p,Times-Roman RT x,y"]
	else
		T = text_record([360 1; 360 0; 120 -1.25; 370 -1.35; -5 1.85],
			["18p,Times-Roman RB x = cos(@%12%a@%%)", "18p,Times-Roman RB y = sin(@%12%a@%%)", 
			"14p,Times-Roman LB 120\\312", "24p,Symbol LT a", "24p,Times-Roman RT x,y"])
	end

	gmt("pstext -R -J -O -K -Dj0.2c -N -F+f+j >> " * ps, T)

	# Draw a circle and indicate the 0-70 degree angle
	gmt("psxy -R-1/1/-1/1 -Jx1.5i -O -K -X3.625i -Y2.75i -Sc2i -W1p -N >> " * ps, [0 0])
	gmt("psxy -R-1/1/-1/1 -J -O -K -Wdefault >> " * ps,
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
		-0.5 0.866025])
	gmt("psxy -R-1/1/-1/1 -J -O -K -W2p >> " * ps,
		[
		NaN NaN
# 		> x-gmt projection -W2p
		-0.3333	0
		0	0
		NaN NaN
# 		> y-gmt projection -W2p
		-0.3333 0.57735
		-0.3333 0])

	if (GMTver < 6)
		T = [
			"-0.16666 0         0  12p,Times-Roman CT x"
			"-0.3333  0.2888675 0  12p,Times-Roman RM y"
			"0.22     0.27     -30 12p,Symbol CB a"
			"-0.33333 0.6       30 12p,Times-Roman LB 120\\312"]
	else
		T = text_record([-0.16666 0 0; -0.3333 0.2888675 0; 0.22 0.27 -30; -0.33333 0.6 30],
			["12p,Times-Roman CT x", "12p,Times-Roman RM y", "12p,Symbol CB a", "12p,Times-Roman LB 120\\312"])
	end
	gmt("pstext -R-1/1/-1/1 -J -O -K -Dj0.05i -F+a+f+j >> " * ps, T)

	gmt("psxy -R -J -O -Sm0.15i+e -W1p -Gblack >> " * ps, [0 0 0.5 0 120])
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex31(g_root_dir, out_path)	
	# Purpose:   
	# GMT progs: 

	d_path = g_root_dir * "doc/examples/ex31/"
	ps = out_path * "example_31.ps"
	return [], []
end

# -----------------------------------------------------------------------------------------------------
function ex32(g_root_dir, out_path)
	# Purpose:   Show graph mode and math angles
	# GMT progs: gmtmath, psbasemap, pstext and psxy

	d_path = g_root_dir * "doc/examples/ex32/"
	ps = out_path * "example_32.ps"

	gmt("gmtset -Du")
	gmt("destroy")

	# Here we get and convert the flag of Europe directly from the web through grdconvert using
	# GDAL support. We take into account the dimension of the flag (1000x667 pixels)
	# for a ratio of 3x2.
	# Because GDAL support will not be standard for most users, we have stored
	# the result, euflag.nc in this directory.

	Rflag = "-R3/9/50/54"
	# gmt grdconvert \
	#   http://upload.wikimedia.org/wikipedia/commons/thumb/b/b7/Flag_of_Europe.svg/1000px-Flag_of_Europe.svg.png=gd \
	#   euflag.nc=ns
	# gmt grdedit euflag.nc -fg $Rflag

	# Now get the topography for the same area from GTOPO30 and store it as topo.nc.
	# The DEM file comes from http://eros.usgs.gov/#/Find_Data/Products_and_Data_Available/gtopo30/w020n90
	# We make an gradient grid as well, which we will use to "illuminate" the flag.

	# The color map assigns "Reflex Blue" to the lower half of the 0-255 range and
	# "Yellow" to the upper half.
	fid = open("euflag.cpt","w")
	println(fid, "0	0/51/153	127	0/51/153")
	println(fid, "127	255/204/0	255	255/204/0")
	close(fid)

	# The next step is the plotting of the image.
	# We use gmt grdview to plot the topography, euflag.nc to give the color, and illum.nc to give
	# the shading.

	Rplot = Rflag * "/-10/790"
	gmt("grdview @topo_32.nc -JM13c " * Rplot * " -Ceuflag.cpt -G@euflag.nc" *
		" -I+a0/270+ne0.6 -Qc -JZ1c -p157.5/30 -P -K > " * ps)

	# We now add borders. Because we have a 3-D plot, we want them to be plotted "at elevation".
	# So we write out the borders, pipe them through grdtack and then plot them with psxyz.

	t = gmt("pscoast " * Rflag * " -Df -M -N1");
	t = gmt("grdtrack -G@topo_32.nc -sa", t);
	gmt("psxyz " * Rplot * " -J -JZ -p -W1p,white -O -K >> " * ps, t)

	# Finally, we add dots and names for three cities.
	# Again, gmt grdtrack is used to put the dots "at elevation".
	fid = open("cities.txt", "w")
	println(fid, "05:41:27 50:51:05 Maastricht")
	println(fid, "04:21:00 50:51:00 Bruxelles")
	println(fid, "07:07:03 50:43:09 Bonn")
	close(fid)
	t = gmt("grdtrack -G@topo_32.nc cities.txt")
	if (GMTver < 6)
		gmt("psxyz -i0,1,3 " * Rplot * " -J -JZ -p -Sc7p -W1p,white -Gred -K -O >> " * ps, t)
	else
		gmt("psxyz " * Rplot * " -J -JZ -p -Sc7p -W1p,white -Gred -K -O >> " * ps, t)
	end
	gmt("pstext " * Rplot * " -J -JZ -p -F+f12p,Helvetica-Bold,red+jRM -Dj0.1i/0.0i -O cities.txt >> " * ps)
	rm("cities.txt");	rm("euflag.cpt");	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex33(g_root_dir, out_path)
	# Purpose:   Show graph mode and math angles
	# GMT progs: gmtmath, psbasemap, pstext and psxy

	d_path = g_root_dir * "doc/examples/ex33/"
	ps = out_path * "example_33.ps"

	# Extract a subset of ETOPO1m for the East Pacific Rise
	# gmt grdcut etopo1m_grd.nc -R118W/107W/49S/42S -Gspac.nc
	gmt("gmtset -Du")
	gmt("destroy")
	if (GMTver < 6)  spac = d_path * "spac.nc"
	else             spac = "@spac_33.nc"
	end
	z_cpt = gmt("makecpt -Crainbow -T-5000/-2000")
	Gspac_int = gmt("grdgradient @spac_33.nc -A15 -Ne0.75 -G")
	gmt("grdimage @spac_33.nc -I -C -JM6i -P -Baf -K -Xc --FORMAT_GEO_MAP=dddF > " * ps, Gspac_int, z_cpt)
	# Select two points along the ridge
	ridge_pts = [-111.6 -43.0; -113.3 -47.5];
	# Plot ridge segment and end points
	gmt("psxy -R" * spac * " -J -O -K -W2p,blue >> " * ps, ridge_pts)
	gmt("psxy -R -J -O -K -Sc0.1i -Gblue >> " * ps, ridge_pts)
	# Generate cross-profiles 400 km long, spaced 10 km, samped every 2km
	# and stack these using the median, write stacked profile
	table = gmt("grdtrack -G@spac_33.nc -C400k/2k/10k -Sm+sstack.txt", ridge_pts)
	gmt("psxy -R -J -O -K -W0.5p >> " * ps, table)
	# Show upper/lower values encountered as an envelope
	env1 = gmt("gmtconvert stack.txt -o0,5")
	env2 = gmt("gmtconvert stack.txt -o0,6 -I -T")
	env = [env1[1].data; env2[1].data];		# Concat the two matrices
	gmt("psxy -R-200/200/-3500/-2000 -Bxafg1000+l\"Distance from ridge (km)\" -Byaf+l\"Depth (m)\" -BWSne" *
		" -JX6i/3i -O -K -Glightgray -Y6.5i >> " * ps, env)
	gmt("psxy -R -J -O -K -W3p stack.txt >> " * ps)
	gmt("pstext -R -J -O -K -Gwhite -F+jTC+f14p -Dj0.1i >> " * ps, text_record([0 -2000], "MEDIAN STACKED PROFILE"))
	gmt("psxy -R -J -O -T >> " * ps)
	rm("stack.txt")
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex34(g_root_dir, out_path)
	# Purpose:   Illustrate pscoast with DCW country polygons
	# GMT progs: pscoast, makecpt, grdimage, grdgradient

	d_path = g_root_dir * "doc/examples/ex34/"
	ps = out_path * "example_34.ps"

	gmt("gmtset FORMAT_GEO_MAP dddF PROJ_LENGTH_UNIT inch PS_CHAR_ENCODING Standard+ PS_MEDIA letter")
	gmt("destroy")
	gmt("pscoast -JM4.5i -R-6/20/35/52 -EFR,IT+gP300/8 -Glightgray -Baf -BWSne -P -K -X2i > " * ps)
	# Extract a subset of ETOPO2m for this part of Europe
	# gmt grdcut etopo2m_grd.nc -R -GFR+IT.nc=ns
	z_cpt = gmt("makecpt -Cglobe -T-5000/5000/50 -Z")
	gmt("grdimage @FR+IT.nc -I+a15+ne0.75 -C -J -O -K -Y4.5i" *
		" -Baf -BWsnE+t\"Franco-Italian Union, 2042-45\" >> " * ps, z_cpt)
	gmt("pscoast -J -R -EFR,IT+gred@60 -O >> " * ps)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex35(g_root_dir, out_path)
	# Purpose:   Illustrate pscoast with DCW country polygons
	# GMT progs: pscoast, makecpt, grdimage, grdgradient

	d_path = g_root_dir * "doc/examples/ex35/"
	ps = out_path * "example_35.ps"

	# Get the crude GSHHS data, select GMT format, and decimate to ~20%:
	# gshhs $GMTHOME/src/coast/gshhs/gshhs_c.b | $AWK '{if ($1 == ">" || NR%5 == 0) print $0}' > gshhs_c.txt
	# Get Voronoi polygons
	gmt("gmtset -Du")
	gmt("destroy")
	pol, nodes = gmt("sphtriangulate @gshhs_c.txt -Qv -D -N")
	# Compute distances in km
	Gtt = gmt("sphdistance -Rg -I1 -Q -N -G -Lk", pol, nodes)
	t_cpt = gmt("makecpt -Chot -T0/3500")
	# Make a basic image plot and overlay contours, Voronoi polygons and coastlines
	gmt("grdimage -JG-140/30/7i -P -K -C -X0.75i -Y2i > " * ps, Gtt, t_cpt)
	gmt("grdcontour -J -O -K -C500 -A1000+f10p,Helvetica,white -L500" *
		" -GL0/90/203/-10,175/60/170/-30,-50/30/220/-5 -Wa0.75p,white -Wc0.25p,white >> " * ps, Gtt)
	gmt("psxy -R -J -O -K -W0.25p,green,. >> " * ps, pol)
	gmt("pscoast -R -J -O -W1p -Gsteelblue -A0/1/1 -B30g30 -B+t\"Distances from GSHHG crude coastlines\" >> " * ps)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex36(g_root_dir, out_path)
	# Purpose:   Illustrate pscoast with DCW country polygons
	# GMT progs: pscoast, makecpt, grdimage, grdgradient

	d_path = g_root_dir * "doc/examples/ex36/"
	ps = out_path * "example_36.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	# Interpolate data of Mars radius from Mariner9 and Viking Orbiter spacecrafts
	tt_cpt = gmt("makecpt -Crainbow -T-7000/15000")
	# Piecewise linear interpolation; no tension
	Gtt = gmt("sphinterpolate @mars370d.txt -Rg -I1 -Q0 -G")
	gmt("grdimage -JH0/6i -Bag -C -P -Xc -Y7.25i -K > " * ps, Gtt, tt_cpt)
	gmt("psxy -Rg -J -O -K @mars370d.txt -Sc0.05i -G0 -B30g30 -Y-3.25i >> " * ps)
	# Smoothing
	Gtt = gmt("sphinterpolate @mars370d.txt -Rg -I1 -Q3 -G")
	gmt("grdimage -J -Bag -C -Y-3.25i -O -K >> " * ps, Gtt, tt_cpt)
	gmt("psxy -Rg -J -O -T >> " * ps)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex37(g_root_dir, out_path)
	# Purpose:   Illustrate pscoast with DCW country polygons
	# GMT progs: pscoast, makecpt, grdimage, grdgradient

	d_path = g_root_dir * "doc/examples/ex37/"
	ps = out_path * "example_37.ps"

	# Testing gmt grdfft coherence calculation with Karen Marks example data
	G = "@grav.V18.par.surf.1km.sq.nc"
	T = "@mb.par.surf.1km.sq.nc"
	gmt("gmtset FONT_TITLE 14p GMT_FFT kiss PROJ_LENGTH_UNIT inch PS_CHAR_ENCODING Standard+ PS_MEDIA letter")
	gmt("destroy")

	z_cpt  = gmt("makecpt -Crainbow -T-5000/-3000")
	g_cpt  = gmt("makecpt -Crainbow -T-50/25")
	bbox_t = gmt("grdinfo -Ib " * T)	# Trouble here bbox_t is a cell array of text and we need it to be a matrix
	if (GMTver < 6)
		bbox = zeros(4,2)
		for k = 1:4
			bbox[k,:] = float(split(bbox_t[1].text[k+1]))
		end
	else
		bbox = bbox_t
	end
	GG_int = gmt("grdgradient -A0 -Nt1 -G " * G)
	GT_int = gmt("grdgradient -A0 -Nt1 -G " * T)
	scl    = "1.4e-5"
	sclkm  = "1.4e-2"
	gmt("grdimage " * T * " -I -Jx" * scl *"i -C -P -K -X1.474i -Y1i > " * ps, GT_int, z_cpt)
	gmt("psbasemap -R-84/75/-78/81 -Jx" * sclkm *"i -O -K -Ba -BWSne+t\"Multibeam bathymetry\" >> " * ps)
	gmt("grdimage " * G * " -I -Jx" * scl *"i -C -O -K -X3.25i >> " * ps, GG_int, g_cpt)
	gmt("psbasemap -R-84/75/-78/81 -Jx" * sclkm *"i -O -K -Ba -BWSne+t\"Satellite gravity\" >> " * ps)

	cross = gmt("grdfft " * T * " " * G * " -Ewk -N192/192+d+wtmp")
	# grav.V18.par.surf.1km.sq_tmp.nc and mb.par.surf.1km.sq_tmp.nc are created by the '+wtmp' above
	GG_tmp_int = gmt("grdgradient grav.V18.par.surf.1km.sq_tmp.nc -A0 -Nt1 -G")
	GT_tmp_int = gmt("grdgradient mb.par.surf.1km.sq_tmp.nc -A0 -Nt1 -G")

	z_cpt = gmt("makecpt -Crainbow -T-1500/1500")
	g_cpt = gmt("makecpt -Crainbow -T-40/40")

	gmt("grdimage mb.par.surf.1km.sq_tmp.nc -I -Jx" * scl *"i -C -O -K -X-3.474i -Y3i >> " * ps, GT_tmp_int, z_cpt)
	gmt("psxy -Rmb.par.surf.1km.sq_tmp.nc -J -O -K -L -W0.5p,- >> " * ps, bbox)
	gmt("psbasemap -R-100/91/-94/97 -Jx" * sclkm *"i -O -K -Ba -BWSne+t\"Detrended and extended\" >> " * ps)

	gmt("grdimage grav.V18.par.surf.1km.sq_tmp.nc -I -Jx" * scl *"i -C -O -K -X3.25i >> " * ps, GG_tmp_int, g_cpt)
	gmt("psxy -Rgrav.V18.par.surf.1km.sq_tmp.nc -J -O -K -L -W0.5p,- >> " * ps, bbox)
	gmt("psbasemap -R-100/91/-94/97 -Jx" * sclkm *"i -O -K -Ba -BWSne+t\"Detrended and extended\" >> " * ps)
 
	gmt("psxy -R2/160/0/1 -JX-6il/2.5i -Bxa2f3g3+u\" km\" -Byafg0.5+l\"Coherency@+2@+\"" *
		" -BWsNe+t\"Coherency between gravity and bathymetry\" -O -K -X-3.25i -Y3.3i -i0,15 -W0.5p --FONT_TITLE=24p >> " * ps, cross)

	# These two lines serve also to show that there is a bug in the previous psxy, which completely ignores the plot line order
	lix = gmt("gmtconvert -o0,15", cross)
	gmt("psxy -R -J -O -K -W0.5p >> " * ps, lix)

	gmt("psxy -R -J -O -K -i0,15,16 -Sc0.075i -Gred -W0.25p -Ey >> " * ps, cross)
 	gmt("psxy -R -J -O -T >> " * ps)
 	rm("grav.V18.par.surf.1km.sq_tmp.nc"), 	rm("mb.par.surf.1km.sq_tmp.nc")
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex38(g_root_dir, out_path)
	# Purpose:   Illustrate histogram equalization on topography grids
	# GMT progs: psscale, pstext, makecpt, grdhisteq, grdimage, grdinfo, grdgradientt

	d_path = g_root_dir * "doc/examples/ex38/"
	ps = out_path * "example_38.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	if (GMTver < 6)  topo = d_path * "topo.nc"
	else             topo = "@topo_38.nc"
	end
	t_cpt = gmt("makecpt -Crainbow -T0/1700");
	c_cpt = gmt("makecpt -Crainbow -T0/15/1");
	Gout  = gmt("grdhisteq @topo_38.nc -C16")
	gmt("grdimage @topo_38.nc -I+a45+nt1 -C -JM3i -Y6i -K -P -B5 -BWSne > " * ps, t_cpt)
	gmt("pstext -R" * topo * " -J -O -K -F+jTR+f14p -T -Gwhite -W1p -Dj0.1i >> " * ps, text_record([315 -10], "Original"))
	gmt("grdimage -C -J -X3.5i -K -O -B5 -BWSne >> " * ps, Gout, c_cpt)
	gmt("pstext -R -J -O -K -F+jTR+f14p -T -Gwhite -W1p -Dj0.1i >> " * ps, text_record([315 -10], "Equalized"))
	gmt("psscale -Dx0i/-0.4i+jTC+w5i/0.15i+h+e+n -O -K -C -Ba500 -By+lm >> " * ps, t_cpt)
	Gout = gmt("grdhisteq @topo_38.nc -N")
	c_cpt = gmt("makecpt -Crainbow -T-3/3")
	gmt("grdimage -C -J -X-3.5i -Y-3.3i -K -O -B5 -BWSne >> " * ps, Gout, c_cpt)
	gmt("pstext -R -J -O -K -F+jTR+f14p -T -Gwhite -W1p -Dj0.1i >> " * ps, text_record([315 -10], "Normalized"))
	Gout = gmt("grdhisteq @topo_38.nc -Q")
	q_cpt = gmt("makecpt -Crainbow -T0/15")
	gmt("grdimage -C -J -X3.5i -K -O -B5 -BWSne >> " * ps, Gout, q_cpt)
	gmt("pstext -R -J -O -K -F+jTR+f14p -T -Gwhite -W1p -Dj0.1i >> " * ps, text_record([315 -10], "Quadratic"))
	gmt("psscale -Dx0i/-0.4i+w5i/0.15i+h+jTC+e+n -O -K -C -Bx1 -By+l\"z@-n@-\" >> " * ps, c_cpt)
	gmt("psscale -Dx0i/-1.0i+w5i/0.15i+h+jTC+e+n -O -C -Bx1 -By+l\"z@-q@-\" >> " * ps, q_cpt)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex39(g_root_dir, out_path)
	# Purpose:   Illustrate evaluation of spherical harmonic coefficients
	# GMT progs: psscale, pstext, makecpt, grdimage, grdgradient, sph2grd

	d_path = g_root_dir * "doc/examples/ex39/"
	ps = out_path * "example_39.ps"

	# Evaluate the first 180, 90, and 30 order/degrees of Venus spherical
	# harmonics topography model, skipping the L = 0 term (radial mean).
	# File truncated from http://www.ipgp.fr/~wieczor/SH/VenusTopo180.txt.zip
	# Wieczorek, M. A., Gravity and topography of the terrestrial planets,
	#   Treatise on Geophysics, 10, 165-205, doi:10.1016/B978-044452748-6/00156-5, 2007

	gmt("gmtset -Du")
	gmt("destroy")
	Gv1 = gmt("sph2grd @VenusTopo180.txt -I1 -Rg -Ng -G -F1/1/25/30")
	Gv2 = gmt("sph2grd @VenusTopo180.txt -I1 -Rg -Ng -G -F1/1/85/90")
	Gv3 = gmt("sph2grd @VenusTopo180.txt -I1 -Rg -Ng -G -F1/1/170/180")
	t_cpt = gmt("grd2cpt -Crainbow -E", Gv3)
	gmt("grdimage -I+a45+nt0.75 -JG90/30/5i -P -K -Bg -C -X3i -Y1.1i > " * ps, Gv1, t_cpt)
	gmt("pstext -R0/6/0/6 -Jx1i -O -K -Dj0.2i -F+f16p+jLM -N >> " * ps, text_record([4 4.5], "L = 30"))
	gmt("psscale --FORMAT_FLOAT_MAP=\"%'g\" -C -O -K -Dx1.25i/-0.2i+jTC+w5.5i/0.1i+h -Bxaf -By+lm >> " * ps, t_cpt)
	gmt("grdimage -I+a45+nt0.75 -JG -O -K -Bg -C -X-1.25i -Y1.9i >> " * ps, Gv2, t_cpt)
	gmt("pstext -R0/6/0/6 -Jx1i -O -K -Dj0.2i -F+f16p+jLM -N >> " * ps, text_record([4 4.5], "L = 90"))
	Gv3 = gmt("sph2grd @VenusTopo180.txt -I1 -Rg -Ng -G -F1/1/170/180")
	gmt("grdimage -I+a45+nt0.75 -JG -O -K -Bg -C -X-1.25i -Y1.9i >> " * ps, Gv3, t_cpt)
	gmt("pstext -R0/6/0/6 -Jx1i -O -K -Dj0.2i -F+f16p+jLM -N >> " * ps, text_record([4 4.5], "L = 180"))
	gmt("pstext -R0/6/0/6 -Jx1i -O -F+f24p+jCM -N >> " * ps, text_record([3.75 5.4], "Venus Spherical Harmonic Model"))
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex40(g_root_dir, out_path)
	# Purpose:   Illustrate evaluation of spherical harmonic coefficients
	# GMT progs: psscale, pstext, makecpt, grdimage, grdgradient, sph2grd

	d_path = g_root_dir * "doc/examples/ex40/"
	ps = out_path * "example_40.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	centroid = gmt("gmtspatial @GSHHS_h_Australia.txt -fg -Qk")
	#centroid = [133.913549887 -22.9337944115 7592694.55567]
	gmt("psbasemap -R112/154/-40/-10 -JM5.5i -P -K -B20 -BWSne+g240/255/240 -Xc > " * ps)
	gmt("psxy @GSHHS_h_Australia.txt -R -J -O -Wfaint -G240/240/255 -K >> " * ps)
	gmt("psxy @GSHHS_h_Australia.txt -R -J -O -Sc0.01c -Gred -K >> " * ps)
	T500k = gmt("gmtsimplify @GSHHS_h_Australia.txt -T500k");
	t = gmt("gmtspatial @GSHHS_h_Australia.txt -fg -Qk");
	area = @sprintf("Full area = %.0f km@+2@+", t[1].data[3]);
	t = gmt("gmtspatial -fg -Qk", T500k); 
	area_T500k = @sprintf("Reduced area = %.0f km@+2@+", t[1].data[3]);
	gmt("psxy -R -J -O -K -W1p,blue >> " * ps, T500k)
	gmt("psxy -R -J -O -K -Sx0.3i -W3p >> " * ps, centroid)
	gmt("pstext -R -J -O -K -Dj0.1i/0.1i -F+jTL+f18p >> " * ps, text_record([112 -10], "T = 500 km"))
	gmt("pstext -R -J -O -K -F+f14p+cCM >> " * ps, text_record(area))
	gmt("pstext -R -J -O -K -F+f14p+cLB -Dj0.2i >> " * ps, text_record(area_T500k))
	gmt("psbasemap -R -J -O -K -B20+lightgray -BWsne+g240/255/240 -Y4.7i >> " * ps)
	gmt("psxy @GSHHS_h_Australia.txt -R -J -O -Wfaint -G240/240/255 -K >> " * ps)
	gmt("psxy @GSHHS_h_Australia.txt -R -J -O -Sc0.01c -Gred -K >> " * ps)
	T100k = gmt("gmtsimplify @GSHHS_h_Australia.txt -T100k");
	t = gmt("gmtspatial -fg -Qk", T100k);
	area_T100k = @sprintf("Reduced area = %.0f km@+2@+", t[1].data[3]);
	gmt("psxy -R -J -O -K -W1p,blue >> " * ps, T100k)
	gmt("psxy -R -J -O -K -Sx0.3i -W3p >> " * ps, centroid)
	gmt("pstext -R -J -O -K -Dj0.1i/0.1i -F+jTL+f18p >> " * ps, text_record([112 -10], "T = 100 km"))
	gmt("pstext -R -J -O -K -F+f14p+cCM >> " * ps, text_record(area))
	gmt("pstext -R -J -O -K -F+f14p+cLB -Dj0.2i >> " * ps, text_record(area_T100k))
	gmt("psxy -R -J -O -T >> " * ps)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex41(g_root_dir, out_path)
	# Purpose:   Illustrate typesetting of legend with table
	# GMT progs: pscoast, pslegend, psxy

	d_path = g_root_dir * "doc/examples/ex41/"
	ps = out_path * "example_41.ps"

	if (GMTver < 6)  symb = d_path * "my_symbol"
	else             symb = "@symbol_41"
	end
	gmt("gmtset FONT_ANNOT_PRIMARY 12p FONT_LABEL 12p PROJ_LENGTH_UNIT inch PS_CHAR_ENCODING Standard+ PS_MEDIA letter")
	gmt("destroy")
	C = gmt("makecpt -Cred,orange,yellow,green,bisque,cyan,magenta,white,gray -T1/10/1 -N")
	gmt("pscoast -R130W/50W/8N/56N -JM5.6i -B0 -P -K -Glightgray -Sazure1 -A1000 -Wfaint -Xc -Y1.2i --MAP_FRAME_TYPE=plain > " * ps)
	gmt("pscoast -R -J -O -K -EUS+glightyellow+pfaint -ECU+glightred+pfaint -EMX+glightgreen+pfaint -ECA+glightblue+pfaint >> " * ps)
	gmt("pscoast -R -J -O -K -N1/1p,darkred -A1000/2/2 -Wfaint -Cazure1 >> " * ps)
	gmt("psxy -R -J -O -K -Sk" * symb * "/0.1i -C -W0.25p -: @data_41.txt >> " * ps, C)
	gmt("pslegend -R0/6/0/9.1 -Jx1i -Dx3i/4.5i+w5.6i+jBC+l1.2 -C0.05i -F+p+gsnow1 -B0 -O @table_41.txt -X-0.2i -Y-0.2i >> " * ps)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex42(g_root_dir, out_path)
	# Purpose:   Illustrate Antarctica and stereographic projection
	# GMT progs: makecpt, grdimage, pscoast, pslegend, psscale, pstext, psxy

	d_path = g_root_dir * "doc/examples/ex42/"
	ps = out_path * "example_42.ps"

	gmt("gmtset FONT_ANNOT_PRIMARY 12p FONT_LABEL 12p PROJ_ELLIPSOID WGS-84 FORMAT_GEO_MAP dddF" *
		" PROJ_LENGTH_UNIT inch PS_CHAR_ENCODING Standard+ PS_MEDIA letter")
	gmt("destroy")
	# Data obtained via website and converted to netCDF thus:
	# curl http://www.antarctica.ac.uk//bas_research/data/access/bedmap/download/bedelev.asc.gz
	# gunzip bedelev.asc.gz
	# grdreformat bedelev.asc BEDMAP_elevation.nc=ns -V
	t_cpt = gmt("makecpt -Cearth -T-7000/4000 -N")
	gmt("grdimage -C @BEDMAP_elevation.nc -Jx1:60000000 -Q -P -K > " * ps, t_cpt)
	gmt("pscoast -R-180/180/-90/-60 -Js0/-90/-71/1:60000000 -Bafg -Di -W0.25p -O -K >> " * ps)
	gmt("psscale -C -DjRM+w2.5i/0.2i+o0.5i/0+jLM+mc -R -J -O -K -F+p+i -Bxa1000+lELEVATION -By+lm >> " * ps, t_cpt)
	# GSHHG
	gmt("pscoast -R-180/180/-90/-60 -J -Di -Glightblue -Sroyalblue2 -O -K -X2i -Y4.75i >> " * ps)
	gmt("pscoast -R-180/180/-90/-60 -J -Di -Glightbrown -O -K -A+ag -Bafg >> " * ps)
	gmt("pslegend -DjLM+w1.7i+jRM+o0.5i/0 -R-180/180/-90/-60 -J -O -K -F+p+i >> " * ps, text_record([
		"H 18 Times-Roman Legend"
		"D 0.1i 1p"
		"S 0.15i s 0.2i blue  0.25p 0.3i Ocean"
		"S 0.15i s 0.2i lightblue  0.25p 0.3i Ice front"
		"S 0.15i s 0.2i lightbrown  0.25p 0.3i Grounding line"]))

	# Fancy line
	gmt("psxy -R0/7.5/0/10 -Jx1i -O -K -B0 -W2p -X-2.5i -Y-5.25i >> " * ps,
		[0 5.55
		2.5 5.55
		5.0 4.55
		7.5 4.55])

	gmt("pstext -R0/7.5/0/10 -J -O -F+f18p+jBL -Dj0.1i/0 >> " * ps, text_record([0 5.2; 0 9.65], ["BEDMAP", "GSHHG"]))
	rm("gmt.conf");
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex43(g_root_dir, out_path)	
	# Purpose:   
	# GMT progs: 

	d_path = g_root_dir * "doc/examples/ex43/"
	ps = out_path * "example_43.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	model    = gmt("gmtregress -Ey -Nw -i0:1l @bb_weights.txt")
	rls_line = gmt("gmtregress -Ey -Nw -i0:1l @bb_weights.txt -Fxmc -T-2/6/0.1")
	ls_line  = gmt("gmtregress -Ey -N2 -i0:1l @bb_weights.txt -Fxm -T-2/6/8")
	rm("gmt.conf")

	return [], []
end

# -----------------------------------------------------------------------------------------------------
function ex44(g_root_dir, out_path)
	# Purpose:   Illustrate use of map inserts
	# GMT progs: pscoast, psbasemap, mapproject

	d_path = g_root_dir * "doc/examples/ex44/"
	ps = out_path * "example_44.ps"

	gmt("gmtset -Du")
	gmt("destroy")
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
	gmt(@sprintf("psbasemap -R -J -O -K -DjTR+w%f/%f+o0.15i/0.1i+sxx000 -F+gwhite+p1p+c0.1c+s >> %s", t[1].data[1], t[1].data[2], ps))
	t = readdlm("xx000");		# x0 y0 w h
	cmd = @sprintf("pscoast -R15W/35E/30N/48N -JM%f -Da -Gbrown -B0 -EES+gbisque -O -K -X%f -Y%f", t[3], t[1], t[2]);
	gmt(cmd * " --MAP_FRAME_TYPE=plain >> " * ps)
	gmt(@sprintf("psxy -R -J -O -T -X-%f -Y-%f >> %s", t[1], t[2], ps))
	rm("xx000")
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex45(g_root_dir, out_path)
	# Purpose:   Illustrate Antarctica and stereographic projection
	# GMT progs: makecpt, grdimage, pscoast, pslegend, psscale, pstext, psxy

	d_path = g_root_dir * "doc/examples/ex45/"
	ps = out_path * "example_45.ps"

	gmt("gmtset -Du")
	gmt("destroy")
	# Basic LS line y = a + bx
	model = gmt("trend1d -Fxm @MaunaLoa_CO2.txt -Np1")
	gmt("psxy -R1958/2016/310/410 -JX6i/1.9i -P -Bxaf -Byaf+u\" ppm\" -BWSne+gazure1 -Sc0.05c -Gred -K @MaunaLoa_CO2.txt -X1.5i > " * ps)
	gmt("psxy -R -J -O -K -W0.5p,blue >> " * ps, model)
	gmt("pstext -R -J -O -K -F+f12p+cTL -Dj0.1i -Glightyellow >> " * ps, text_record("m@-2@-(t) = a + b\\264t"))
	# Basic LS line y = a + bx + cx^2
	model = gmt("trend1d -Fxm @MaunaLoa_CO2.txt -Np2")
	gmt("psxy -R -J -O -Bxaf -Byaf+u\" ppm\" -BWSne+gazure1 -Sc0.05c -Gred -K @MaunaLoa_CO2.txt -Y2.3i >> " * ps)
	gmt("psxy -R -J -O -K -W0.5p,blue >> " * ps, model)
	gmt("pstext -R -J -O -K -F+f12p+cTL -Dj0.1i -Glightyellow >> " * ps, text_record("m@-3@-(t) = a + b\\264t + c\\264t@+2@+"))
	# Basic LS line y = a + bx + cx^2 + seasonal change
	model = gmt("trend1d -Fxmr @MaunaLoa_CO2.txt -Np2,f1+o1958+l1")
	gmt("psxy -R -J -O -Bxaf -Byaf+u\" ppm\" -BWSne+gazure1 -Sc0.05c -Gred -K @MaunaLoa_CO2.txt -Y2.3i >> " * ps)
	gmt("psxy -R -J -O -K -W0.25p,blue >> " * ps, model)
	gmt("pstext -R -J -O -K -F+f12p+cTL -Dj0.1i -Glightyellow >> " * ps,
		text_record("m@-5@-(t) = a + b\\264t + c\\264t@+2@+ + d\\264cos(2@~p@~t) + e\\264sin(2@~p@~t)"))
	# Plot residuals of last model
	gmt("psxy -R1958/2016/-4/4 -J -Bxaf -Byafg10+u\" ppm\" -BWSne+t\"The Keeling Curve [CO@-2@- at Mauna Loa]\"+gazure1" *
		" -Sc0.05c -Gred -O -K -i0,2 -Y2.3i >> " * ps, model)
	gmt("pstext -R -J -O -F+f12p+cTL -Dj0.1i -Glightyellow >> " * ps, text_record("@~e@~(t) = y(t) - m@-5@-(t)"))
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------
function ex46(g_root_dir, out_path)
	# Purpose:   Illustrate use of pssolar to plot day/night terminators
	# GMT progs: pssolar, pscoast, psxy

	d_path = g_root_dir * "doc/examples/ex46/"
	ps = out_path * "example_46.ps"

	gmt("gmtset -Du")
	gmt("destroy")

	if (GMTver < 6)  symb = d_path * "sunglasses"
	else             symb = "@sunglasses"
	end
	gmt("pscoast -Rd -JKs0/10i -Dl -A5000 -W0.5p -N1/0.5p,gray -S175/210/255 -Bafg --MAP_FRAME_TYPE=plain -K -Xc > " * ps)
	gmt("pssolar -R  -J -Td+d2016-02-09T16:00:00 -Gnavy@95 -K -O >> " * ps)
	gmt("pssolar -R  -J -Tc+d2016-02-09T16:00:00 -Gnavy@85 -K -O >> " * ps)
	gmt("pssolar -R  -J -Tn+d2016-02-09T16:00:00 -Gnavy@80 -K -O >> " * ps)
	gmt("pssolar -R  -J -Ta+d2016-02-09T16:00:00 -Gnavy@80 -K -O >> " * ps)
	t = gmt("pssolar -I+d2016-02-09T16:00:00 -C -o0,1");
	gmt("psxy -R -J -Sk" * symb * "/1.5c -Gyellow -O >> " * ps, t)
	rm("gmt.conf")
	return ps, d_path
end

# -----------------------------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------------------------
