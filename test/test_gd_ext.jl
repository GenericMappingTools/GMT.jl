@testset "GDAL" begin

	G = mat2grid(rand(Float32, 4,4));
	GMT.setproj!(G, "+proj=longlat")
	@test G.proj4 == "+proj=longlat"
	I = mat2img(rand(UInt8, 4,4));
	GMT.setproj!(I, G)
	@test I.proj4 == "+proj=longlat"

	bf = buffer([0 0], 1)
	@test bf[1].geom == 2
	c = centroid(bf)
	#@test c[1].data ≈ [0. 0.]

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
		test_method(intersection, "POLYGON EMPTY", "POLYGON EMPTY", "GEOMETRYCOLLECTION EMPTY")
		test_method(intersection, "POLYGON((1 1,1 5,5 5,5 1,1 1))", "POINT(2 2)", "POINT (2 2)")
		test_method(intersection, "MULTIPOLYGON(((0 0,0 10,10 10,10 0,0 0)))", "POLYGON((-1 1,-1 2,2 2,2 1,-1 1))",
					"POLYGON ((0 1,0 2,2 2,2 1,0 1))")
		#=
		test_method(intersection,
					"MULTIPOLYGON(((0 0,5 10,10 0,0 0),(1 1,1 2,2 2,2 1,1 1),(100 100,100 102,102 102,102 100,100 100)))",
					"POLYGON((0 1,0 2,10 2,10 1,0 1))",
					"GEOMETRYCOLLECTION (POLYGON ((0.5 1.0,1 2,1 1,0.5 1.0)),POLYGON ((2 2,9 2,9.5 1.0,2 1,2 2)),LINESTRING (2 1,1 1),LINESTRING (1 2,2 2))")
		=#

		@testset "Intersects" begin
			test_predicate(Gdal.intersects, "POLYGON EMPTY", "POLYGON EMPTY", false)
			test_predicate(Gdal.intersects, "POLYGON((1 1,1 5,5 5,5 1,1 1))", "POINT(2 2)", true)
			test_predicate(Gdal.intersects, "POINT(2 2)", "POLYGON((1 1,1 5,5 5,5 1,1 1))", true)
			test_predicate(Gdal.intersects, "MULTIPOLYGON(((0 0,0 10,10 10,10 0,0 0)))", "POLYGON((1 1,1 2,2 2,2 1,1 1))", true)
			test_predicate(Gdal.intersects, "POLYGON((1 1,1 2,2 2,2 1,1 1))", "MULTIPOLYGON(((0 0,0 10,10 10,10 0,0 0)))", true)
		end
	end


end