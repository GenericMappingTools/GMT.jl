@testset "MOSAIC" begin

	println("	TILES MOSAIC")
	
	quadkey(-9,39, 8) == ([121, 97, 8], ["03311003";;])
	quadkey(-9,39, 8, bounds=true)
	quadkey([121, 97, 8], bounds=false) == "03311003"
	mosaic(0.1,0.1,zoom=1);
	GMT.getprovider("OSM", 2);
	GMT.getprovider("moon", 2);
	GMT.getprovider("esri", 2);
	GMT.getprovider("go", 2);
	quadtree = mosaic([-10. -8],[37. 39.], zoom=8, quadonly=1)[1];
	quadbounds(quadtree);
end
