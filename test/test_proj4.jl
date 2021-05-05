# Must increase the number of tests and add some that actually do numeric comparisons

@testset "PROJ4" begin
	geod([0, 0], 90, 111000)
	geod([0, 0], [30 60], 111000)
	geod([0, 0], [30 60], [50, 111], unit=:k)
	geod([0., 0], [15., 45], [[0, 10000, 50000, 111000.], [0., 50000]])[1]
	invgeod([0., 0], [1., 0])
	GMT.proj_info()
end