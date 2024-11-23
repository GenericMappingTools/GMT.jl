@testset "BEZIERS" begin

	println("	BEZIERS")
	
	D = bezier(mat2ds([30. -15; 30 45; -30 45; -30 -15], proj4="geog"));
	D = bezier(mat2ds([30. -15; 30 45; -30 45; -30 -15], proj4="geog"), pure=true, np=10);
	D = bezier(mat2ds([30. -15; 30 45; -30 45; -30 -15; -20 -25], proj4="geog"));
	D = bezier(mat2ds([30. -15; 30 45; -30 45; -30 -15; -20 -25; -30 -30], proj4="geog"), firstcurve=false);
	D1 = bezier(mat2ds([392 196 -56; 280 153 -75; 321 140 10; 356 200 148]));
	D2 = bezier(mat2ds([356 200 148; 400 250 153; 300 220 40; 250 260 -148]));
end
