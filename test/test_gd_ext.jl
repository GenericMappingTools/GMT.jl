@testset "GDAL" begin

	G = mat2grid(rand(Float32, 4,4));
	GMT.setproj!(G, "+proj=longlat")
	@test G.proj4 == "+proj=longlat"
	I = mat2img(rand(UInt8, 4,4));
	GMT.setproj!(I, G)
	@test I.proj4 == "+proj=longlat"

	bf = buffer([0 0], 1)
	@test bf[1].geom == 2
end