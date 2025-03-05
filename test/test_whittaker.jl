@testset "WHITTAKER" begin

	println("	WHITTAKER")
	
	D = gmtread(TESTSDIR * "/assets/nmr_with_weights_and_x.csv");
	whittaker(D[:,2], 2e4);
	whittaker(D[:,2], 2e4, 2; weights=D[:,3]);
	whittaker(D, 2e4, 2);
	t = 2001:0.003:2007; _v = 5*cospi.((t .- 2000)/2); v = _v + (5*rand(length(t)) .- 2.5); v[2002.6 .< t .< 2003.4] .= NaN;
	whittaker(t, v, 0.01);
end
