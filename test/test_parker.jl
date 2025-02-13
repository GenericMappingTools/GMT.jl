@testset "PARKERFFT" begin

	println("	PARKERFFT")
	
	m = zeros(Float32, 64,64);  m[32:40,32:40] .= 10; h = fill(-2.0f0, 64,64);
	Gm = GMT.mat2grid(m, hdr=[30., 30.32, 30., 30.32]);
	Gh = GMT.mat2grid(h, hdr=[30., 30.32, 30., 30.32]);
	f3d = parkermag(Gm,  Gh, "dir", year=2000, thickness=1, pct=0);
	m3d = parkermag(f3d, Gh, "inv", year=2000, thickness=1, pct=0);

	Gbat = gmtread(GMT.TESTSDIR * "/assets/model_interface_4parker.grd");
	Ggrv = parkergrav(Gbat, rho=400, nterms=10);
	Gbat_inv = parkergrav(Ggrv, "inv", rho=400, depth=20.0, pct=50);
	Ggrv_rec = parkergrav(Gbat_inv, rho=400, nterms=10);
end
