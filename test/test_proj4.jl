# Must increase the number of tests and add some that actually do numeric comparisons

@testset "PROJ4" begin
	geod([0, 0], 90, 111000)
	geod([0, 0], [30 60], 111000)
	geod([0, 0], 30, [50, 111], unit=:k)
	geod([0, 0], [30 60], [50, 111], unit=:k)
	geod([0., 0], [15., 45], [[0, 10000, 50000, 111000.], [0., 50000]])
	geod([0 0], [30, 190], 50000, backward=true, dataset=true)
	invgeod([0., 0], [1., 0])
	invgeod([0., 0], [1., 0], backward=true)
	invgeod([0. 0; 0 0.5], [1. 0; 1 1], backward=true)
	@test_throws ErrorException("'azimuth' MUST be either a scalar or a 1-dim array, and 'distance' may also be a Vector{Vector}") geod([0, 0], [30 8; 1 1], [50 111], unit=:k)
	GMT.proj_info()
	a,ind = GMT.vecangles([0,0], [5 5; 10 5])
	a,ind = GMT.vecangles([0,0], [5 5; 10 5], sorted=false)

	pj = GMT.proj_create_crs_to_crs("EPSG:4326", "+proj=utm +zone=32 +datum=WGS84", C_NULL)	# target, also EPSG:32632
	#@test GMT.is_latlong(GMT.proj_create("+proj=longlat +datum=WGS84 +no_defs"))
	@test circgeo(0.,0, radius=50, dataset=true, unit=:k).data[1] == 0.0
	@test_throws ErrorException("Bad shape name (a)") circgeo(0.,0, radius=50, shape=:a)
	circgeo([0 0; 0 2], radius=50, unit=:k)
	buffergeo(mat2ds([0 0; 5 5]), width=100, unit=:k, tol=0)
	buffergeo([mat2ds([0 0; 5 5])], width=100, unit=:k, tol=0)
	buffergeo(mat2ds([178 73; -175 74]), width=100, unit=:k)
	wkt = epsg2wkt(4326)
	prj = epsg2proj(4326)
	proj2wkt(prj)
	wkt2proj(wkt)
	loxo = loxodrome_direct(0,0,45, 10000)
	loxo = loxodrome([0 0; 30 50], step=500, unit=:k);
	loxo = loxodrome(mat2ds([0 0; 30 50]), step=500, unit=:k);
	loxo = loxodrome(0, 0, 30, 50, step=500, unit=:k);
	orto = geodesic(mat2ds([0 0; 30 50]), step=500, unit=:k);
	orto = geodesic([mat2ds([0 0; 30 50])], step=500, unit=:k);
	geodesic(mat2ds([0 0; 15 25; 30 50]), step=500, unit=:k)
	orthodrome(0, 0, 30, 50, step=500, unit=:k);
	geodesic([162.23333 58.61667], [66.66667 25.28333], longest=true);
	dist, azim = GMT.loxodrome_inverse(0,0,5,5)
end