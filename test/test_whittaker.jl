@testset "WHITTAKER" begin

	println("	WHITTAKER")
	
	D = gmtread(TESTSDIR * "/assets/nmr_with_weights_and_x.csv");
	whittaker(D[:,2], 2e4);
	whittaker(D[:,2], 2e4, 2; weights=D[:,3]);
	whittaker(D, 2e4, 2);
	t = 2001:0.003:2007; _v = 5*cospi.((t .- 2000)/2); v = _v + (5*rand(length(t)) .- 2.5); v[2002.6 .< t .< 2003.4] .= NaN;
	whittaker(t, v, 0.01);
	# z must solve (I + lambda*D'D) z = y once (d = 1), not twice
	y = sin.(0:0.1:20) .+ 0.3*cos.(0:7.3:1460);	z = whittaker(copy(y), 50.0, 1);	r = diff(z);
	@test maximum(abs.(z .+ 50.0 .* [-r[1]; -diff(r); r[end]] .- y)) < 1e-8
end
