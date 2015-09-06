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