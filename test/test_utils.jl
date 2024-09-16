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
	GMT.refsystem_A2B!(A, B)
	@test A.proj4 == B.proj4
	
	@test wrap2pi(2π) < eps()
end
