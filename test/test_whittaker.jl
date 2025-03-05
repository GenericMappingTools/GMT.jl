@testset "WHITTAKER" begin

	println("	WHITTAKER")
	
	D = gmtread(TESTSDIR * "/assets/nmr_with_weights_and_x.csv");
	whittaker(D[:,2], 2e4);
	whittaker(D[:,2], 2e4, 2; weights=D[:,3]);
	whittaker(D, 2e4, 2);
end
