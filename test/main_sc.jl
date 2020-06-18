# main-sc for movies
gmtset(FONT_TAG="14p,Helvetica-Bold")
grdimage("USEast_Coast.nc", proj="GMOVIE_COL0/MOVIE_COL1/160/210/55/0/36/34/MOVIE_WIDTH+", region=:g, I="int_US.nc", C="globe_US.cpt", X=0, Y=0)
plot("flight_path.txt", lw=1)