# pre script for movies
project(C=(-73.8333,40.75), E=(-80.133,25.75), G=30, Q=true, write="flight_path.txt")
grdgradient("@USEast_Coast.nc", A=90, N=:t1, G="int_US.nc")
makecpt(C=:globe, H=true, cptname="globe_US.cpt")