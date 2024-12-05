@testset "MOSAIC" begin

	println("	TILES MOSAIC")
	
	@test quadkey(-9,39, 8) == ([121, 97, 8], ["03311003";;])
	quadkey(-9,39, 8, bounds=true)
	@test quadkey([121, 97, 8], bounds=false) == "03311003"
	@test GMT.XY2quadtree(7829, 6376, 14) == "03311032212101"
	@test quadkey([7829, 6376, 14], bounds=false) == "03311032212101"
	mosaic(0.1,0.1,zoom=1);
	mosaic([0.0 50],[0.0 40],zoom=1);
	GMT.getprovider("OSM", 2);
	GMT.getprovider("moon", 2);
	GMT.getprovider("esri", 2);
	GMT.getprovider(("goo","sat"), 2);
	quadtree = mosaic([-10. -8],[37. 39.], quadonly=1)[1];
	quadbounds(quadtree[1]);
	quadbounds(quadtree);
	GMT.meridionalRad(6371007.0, 0.0)
	D = geocoder("Universidade do Algarve, Gambelas");
	mosaic(D, zoom=2, quadonly=1);
	mosaic(D, zoom=2, bb=1, quadonly=1);
	mosaic(R=(91,110,6,22), quadonly=1);
	mosaic(-90,25, zoom=1, provider="nimb",key="0", quadonly=1);
	G = peaks(); G.proj4 = "+proj=lonlat";
	mosaic(G, quadonly=1);
	G = gdalwarp(G, ["-t_srs","+proj=merc"])
	#mosaic(G, quadonly=1);		# This now decided to randomly fail
	D15 = mosaic("7829,6374,14", zoom=1, mesh=true);

	struct Provider
		url::String
		options::Dict{Symbol,Any}
	end
	p = Provider("https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/{variant}/default/{date}/GoogleMapsCompatible_Level{max_zoom}/{z}/{y}/{x}.{format}", Dict(:variant => "VIIRS_CityLights_2012", :name => :NASAGIBSTimeseries, :format => "jpeg", :max_zoom => 8));
	GMT.getprovider(p, 2);
end
