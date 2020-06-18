# pre script for movies
project(C=(-73.8333,40.75), E=(-80.133,25.75), G=30, Q=true, write="flight_path.txt")
grdmath("-R-100/-70/10/50 -I0.5 X Y MUL = USEast_Coast.nc")	# Just a fake one since original was deleted from GMT server
grdgradient("USEast_Coast.nc", A=90, N=:t1, G="int_US.nc")
makecpt(C=:globe, H=true, cptname="globe_US.cpt")