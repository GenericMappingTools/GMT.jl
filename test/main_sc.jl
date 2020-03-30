# main-sc for movies
gmtset(FONT_TAG="14p,Helvetica-Bold")
gmt("grdmath -R-100/-70/10/50 -I0.5 X Y MUL = USEast_Coast.nc")	# Just a fake one since original was deleted from GMT server
grdimage("USEast_Coast.nc", proj="GMOVIE_COL0/MOVIE_COL1/160/210/55/0/36/34/MOVIE_WIDTH+", region=:g, I="int_US.nc", C="globe_US.cpt", X=0, Y=0)
plot("flight_path.txt", lw=1)
rm("USEast_Coast.nc")			# Now its a fake one computed in pre_sc.jl