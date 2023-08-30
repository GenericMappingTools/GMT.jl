@testset "GDALext" begin

	G = mat2grid(rand(Float32, 4,4));
	GMT.setproj!(G, "+proj=longlat")
	@test G.proj4 == "+proj=longlat"
	I = mat2img(rand(UInt8, 4,4));
	GMT.setproj!(I, G)
	@test I.proj4 == "+proj=longlat"

	bf = buffer([0 0], 1)
	@test bf.geom == Gdal.wkbPolygon
	c = centroid(bf)
	D = [mat2ds([0. 0; 1 1; 2 0; 0 0], geom=UInt32(3)), mat2ds([0. 0; 1 1; 2 0; 0 0], geom=UInt32(3))];
	centroid(D);		# Test multipolygons
	#@test c.data ≈ [0. 0.]
	bf2 = buffer([0.5 0], 1);
	polyunion(bf, bf2);
	Gdal.difference(bf, bf2);
	Gdal.symdifference(bf, bf2);
	@test Gdal.distance(bf, bf2) == 0.0
	@test Gdal.equals(bf, bf2) == false
	@test Gdal.disjoint(bf, bf2) == false
	@test Gdal.touches(bf, bf2) == false
	@test Gdal.crosses(bf, bf2) == false
	@test Gdal.within(bf, bf2) == false
	@test Gdal.contains(bf, bf2) == false
	@test Gdal.overlaps(bf, bf2) == true
	@test intersects(bf, [-1 -1;1 1]) == true

	Gdal.geomarea(bf);
	@test Gdal.geomlength([0 0; 1 1]) ≈ sqrt(2)
	Gdal.envelope(bf);
	Gdal.envelope3d(bf);
	Gdal.boundary(bf);
	Gdal.convexhull(bf);
	bf.geom = wkbLineString;
	Gdal.pointalongline(bf, 0.3);
	Gdal.Gdal.arccircle(0, 0, 1., 0., -90);
	g1 = fromWKT("MULTIPOINT(0 0, 10 0, 10 10, 11 10)");
	g2 = delaunay(g1,2.0,true);
	@test toWKT(g2) == "MULTILINESTRING ((0 0,10 10),(0 0,10 0),(10 0,10 10))"
	D1 = mat2ds([0 0;10 0;10 10;11 10], geom=wkbMultiPoint);
	g2 = delaunay(D1,2.0,true, gdataset=true);		# Doesn't error but returns MULTILINESTRING EMPTY 
	@test length(Gdal.simplify([0. 0; 1 1.1; 2.1 2], 0.2)) == 4
	
	D1 = mat2ds([0 0; 10 0; 10 10; 11 10]);
	gdalwrite("lixo1.gmt", D1);
	D2 = gdalread("lixo1.gmt");
	@test D1 == D2
	I1 = mat2img(UInt8.([1 2 3; 4 5 6; 7 8 9]));
	gdalwrite("lixo.png", I1);
	I2 = gdalread("lixo.png");
	@test I1 == I2'		# Because the layout is different

	function test_method(f::Function, wkt1::AbstractString, wkt2::AbstractString, wkt3::AbstractString)
		geom1 = Gdal.fromWKT(wkt1)
		geom2 = Gdal.fromWKT(wkt2)
		result = f(geom1, geom2)
		@test Gdal.toWKT(result) == wkt3
		@test Gdal.toWKT(f(geom1, geom2)) == wkt3
	end

	function test_predicate(f::Function, wkt1, wkt2, result::Bool)
		geom1 = Gdal.fromWKT(wkt1)
		geom2 = Gdal.fromWKT(wkt2)
		@test f(geom1, geom2) == result
	end

	@testset "Intersection" begin
		#test_method(intersection, "POLYGON EMPTY", "POLYGON EMPTY", "GEOMETRYCOLLECTION EMPTY")
		test_method(intersection, "POLYGON((1 1,1 5,5 5,5 1,1 1))", "POINT(2 2)", "POINT (2 2)")
		#test_method(intersection, "MULTIPOLYGON(((0 0,0 10,10 10,10 0,0 0)))", "POLYGON((-1 1,-1 2,2 2,2 1,-1 1))",
					#"POLYGON ((0 1,0 2,2 2,2 1,0 1))")
		#=
		test_method(intersection,
					"MULTIPOLYGON(((0 0,5 10,10 0,0 0),(1 1,1 2,2 2,2 1,1 1),(100 100,100 102,102 102,102 100,100 100)))",
					"POLYGON((0 1,0 2,10 2,10 1,0 1))",
					"GEOMETRYCOLLECTION (POLYGON ((0.5 1.0,1 2,1 1,0.5 1.0)),POLYGON ((2 2,9 2,9.5 1.0,2 1,2 2)),LINESTRING (2 1,1 1),LINESTRING (1 2,2 2))")
		=#
		intersection([0 -1;0 1], [-1 -1;1 1])

		@testset "Intersects" begin
			test_predicate(Gdal.intersects, "POLYGON EMPTY", "POLYGON EMPTY", false)
			test_predicate(Gdal.intersects, "POLYGON((1 1,1 5,5 5,5 1,1 1))", "POINT(2 2)", true)
			test_predicate(Gdal.intersects, "POINT(2 2)", "POLYGON((1 1,1 5,5 5,5 1,1 1))", true)
			test_predicate(Gdal.intersects, "MULTIPOLYGON(((0 0,0 10,10 10,10 0,0 0)))", "POLYGON((1 1,1 2,2 2,2 1,1 1))", true)
			test_predicate(Gdal.intersects, "POLYGON((1 1,1 2,2 2,2 1,1 1))", "MULTIPOLYGON(((0 0,0 10,10 10,10 0,0 0)))", true)
		end
	end

	@test lonlat2xy([150.0 -27.0], "+proj=utm +zone=56 +south +datum=WGS84 +units=m +no_defs") ≈
		[202273.912995055 7010024.033113679]  atol=1e-6
	@test xy2lonlat([202273.912995055 7010024.033113679], "+proj=utm +zone=56 +south +datum=WGS84 +units=m +no_defs") ≈
		[150.0 -27.0] atol=1e-6

	@test xy2lonlat([111319.49079327357 110579.96522189621], s_srs="+proj=merc") ≈ [1 1]
	@test xy2lonlat([111319.49079327357 110579.96522189621], s_srs=3395) ≈ [1 1]
		
	@test xy2lonlat(mat2ds([111319.49079327357 110579.96522189621]), s_srs=3395).data ≈ [1 1]
	@test xy2lonlat(mat2ds([111319.49079327357 110579.96522189621]), s_srs="+proj=merc").data ≈ [1 1]
		
	@test xy2lonlat(mat2ds([111319.49079327357 110579.96522189621]), s_srs="+proj=merc").data ≈ [1 1]
	@test xy2lonlat(mat2ds([111319.49079327357 110579.96522189621]), s_srs=3395).data ≈ [1 1]
		
	@test xy2lonlat([111319.49079327357, 110579.96522189621], s_srs="+proj=merc") ≈ [1, 1]
	@test xy2lonlat([111319.49079327357, 110579.96522189621], s_srs=3395) ≈ [1, 1]
	@test xy2lonlat([111319.49079327357, 110579.96522189621], 3395) ≈ [1, 1]

	@test lonlat2xy(mat2ds([1 1]), t_srs="+proj=merc").data ≈ [111319.49079327357 110579.96522189621]
	@test lonlat2xy(mat2ds([1 1]), t_srs=3395).data ≈ [111319.49079327357 110579.96522189621]
	@test lonlat2xy(mat2ds([1 1]), 3395).data ≈ [111319.49079327357 110579.96522189621]
	@test lonlat2xy(mat2ds([1 1]), t_srs=3395).data ≈ [111319.49079327357 110579.96522189621]

	@test lonlat2xy([1 1], t_srs="+proj=merc") ≈ [111319.49079327357 110579.96522189621]
	@test lonlat2xy([1 1], t_srs=3395) ≈ [111319.49079327357 110579.96522189621]
	@test lonlat2xy([1 1], 3395) ≈ [111319.49079327357 110579.96522189621]

	@test lonlat2xy([1, 1], t_srs="+proj=merc") ≈ [111319.49079327357, 110579.96522189621]
	@test lonlat2xy([1, 1], t_srs=3395) ≈ [111319.49079327357, 110579.96522189621]
end