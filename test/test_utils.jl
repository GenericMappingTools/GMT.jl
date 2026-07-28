@testset "UTILS" begin

	year = 1750:25:2000;
	pop = 1e6*[791 856 978 1050 1262 1544 1650 2532 6122 8170 11560];
	p = GMT.polyfit(year, pop, 5);
	f = GMT.polyval(p, year);

	R1 = [0.0, 3, 0, 2]; R2 = [5., 10, 5, 8];
	l1, l2 = GMT.connect_rectangles(R1, R2);

	GMT.facenorm([0. 0 0; 1 1 0; 2 0 0]) == [0.0, 0.0, -1.0]

	A = GMTdataset(data=[1. 2; 3 4], proj4="merc");
	B = GMTdataset(data=[1. 2; 3 4]);
	GMT.copyrefA2B!(A, B);
	@test A.proj4 == B.proj4
	
	@test GMT.wrap2pi(2π) < eps()

	function test_circfit()
		#Random.seed!(123)
		radius = 3
		theta = linspace(0, 2*pi, 200)
		theta = theta[rand(1:length(theta), 20)]	# Retain only a few points
		x = radius * cos.(theta)
		y = radius * sin.(theta)
		x .+= (rand(length(x)) .- 0.5) * radius/4	# Add noise
		y .+= (rand(length(y)) .- 0.5) * radius/4
	
		x1, y1, R1, err1 = circfit([x y])
		x2, y2, R2, err2 = circfit(x, y, taubin=true)
		return [x y], x1, y1, R1, err1, x2, y2, R2, err2
	end
	test_circfit();

	A, B, C, D = GMT.eq_plane(0, 45, 10);
	GMT.eye()

	n = GMT.bitcat2(10, 20);
	n1, n2 = GMT.bituncat2(n);
	@test n1 == 10 && n2 == 20

	@test !bissextile(100)
	@test bissextile(-4)

	println("	TESTS function")
	# With extension - must find the file and return a non-empty path
	@test tests("cameraman.png") == joinpath(TESTSDIR, "assets", "cameraman.png")
	# Without extension - must find a matching file in assets/
	@test tests("cameraman") == joinpath(TESTSDIR, "assets", "cameraman.png")
	# Non-existent file - must warn and return ""
	@test (@test_logs (:warn,) tests("nao_existe_xpto.dat")) == ""
	# Non-existent file without extension
	@test (@test_logs (:warn,) tests("nao_existe_xpto")) == ""

	mat = ones(Float32, 5,5); mat[3,3] = NaN;	G = mat2grid(mat);
	G2 = fillgaps(G)[1];
	@test G2.z[3,3] == 1

	println("	RGB <-> HSV")
	# Known anchors: red, green, blue, white, black, grey (grey has no hue and no saturation).
	@test all(rgb2hsv(1f0, 0f0, 0f0) .≈ (0f0,   1f0, 1f0))
	@test all(rgb2hsv(0f0, 1f0, 0f0) .≈ (120f0, 1f0, 1f0))
	@test all(rgb2hsv(0f0, 0f0, 1f0) .≈ (240f0, 1f0, 1f0))
	@test all(rgb2hsv(1f0, 1f0, 1f0) .≈ (0f0,   0f0, 1f0))
	@test all(rgb2hsv(0f0, 0f0, 0f0) .≈ (0f0,   0f0, 0f0))
	@test all(hsv2rgb(0f0, 0f0, 0.5f0) .≈ (0.5f0, 0.5f0, 0.5f0))

	RGB = rand(Float32, 8, 6, 3)
	HSV = rgb2hsv(RGB)
	@test isa(HSV, Array{Float32,3}) && size(HSV) == size(RGB)
	@test all(0 .<= HSV[:,:,1] .<= 360) && all(0 .<= HSV[:,:,2] .<= 1) && all(0 .<= HSV[:,:,3] .<= 1)
	@test maximum(abs.(hsv2rgb(HSV) .- RGB)) < 1e-6			# round trip
	# UInt8 (a GMTimage's layout) must give the same answer as the same colours scaled to [0,1]
	U = rand(UInt8, 8, 6, 3)
	@test maximum(abs.(rgb2hsv(U) .- rgb2hsv(Float32.(U) ./ 255f0))) < 1e-4
	@test_throws ErrorException rgb2hsv(rand(Float32, 4, 4, 2))
	@test_throws ErrorException hsv2rgb(rand(Float32, 4, 4, 4))
end
