@testset "UTILS" begin

	year = 1750:25:2000;
	pop = 1e6*[791 856 978 1050 1262 1544 1650 2532 6122 8170 11560];
	p = GMT.polyfit(year, pop, 5);
	f = GMT.polyval(p, year);
end
