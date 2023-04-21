@testset "NEWPROJS" begin

	println("	NEWPROJS")
	
	GMT.geodetic2enu(-81.998,42.002,1000,-82,42,200);

	G = GMT.worldrectangular("@earth_relief_10m_g", latlim=90);
	G = GMT.worldrectangular("@earth_relief_10m_g", pm=100);
	G = GMT.worldrectangular("@earth_relief_10m_g", pm=-100);	
end
