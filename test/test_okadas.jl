@testset "OKADA" begin

	println("	OKADA")
	
	airy1830   = GMT.Ellipsoid(a = "6377563.396", b = "6356256.909", name=:airy1830);

	x=2; y=3; W = 2; L=3; depth=4; strike=90; dip=70; rake=0; slip=1; 
	@test okada([x-L/2], [y-cosd(dip)*W/2], depth=depth-sind(dip)*W/2, strike=strike, dip=dip, L=L, W=W, rake=rake, slip=slip)[1] ≈ -0.0027474058
	ue,un,uz = okada([x-L/2], [y-cosd(dip)*W/2], depth=depth-sind(dip)*W/2, strike=strike, dip=dip, L=L, W=W, rake=rake, slip=slip, enz=1)
	@test [ue[1], un[1], uz[1]] ≈ [-0.008689165, -0.004297582, -0.0027474058]
	
	ue,un,uz = okada([x-L/2], [y-cosd(dip)*W/2], depth=depth-sind(dip)*W/2, strike=strike, dip=dip, L=L, W=W, rake=90, slip=slip, enz=1)
	@test [ue[1], un[1], uz[1]] ≈ [-0.0046823486, -0.035267267, -0.035638556]
	
	ue,un,uz = okada([x-L/2], [y-cosd(dip)*W/2], depth=depth-sind(dip)*W/2, strike=strike, dip=dip, L=L, W=W, rake=0, slip=0, open=1, enz=1)
	@test [ue[1], un[1], uz[1]] ≈ [-0.000265996, 0.010564075, 0.003214193]

	G = mat2grid(hdr=[-17.5 -5.049999999999997 31.05 40.45 1 1 0 0.01666666666666667 0.01666666666666667]);
	Gdef = okada(G, x_start=-12.13355, y_start=35.68912, depth=0, strike=65.3, dip=90, L=180, W=45, rake=90, slip=1);
end
