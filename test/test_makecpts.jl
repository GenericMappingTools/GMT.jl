@testset "MAKECPT" begin

	println("	MAKECPT")
	C = makecpt(C="categorical", T="0/10/1");
	makecpt(rand(10,1), E="", C=:rainbow, cmap="lixo.cpt");
	@test_throws ErrorException("E option requires that a data table is provided as well") makecpt(E="", C=:rainbow)
	cpt = makecpt(range="-1/1/0.1");
	cpt = makecpt(-1,1,0.1);
	#C = cpt4dcw("eu");
	C = cpt4dcw("PT,ES,FR", [3., 5, 8], range=[3,9,1]);
	C = cpt4dcw("PT,ES,FR", [.3, .5, .8], cmap=cpt);
	@test_throws ErrorException("Unknown continent ue") cpt4dcw("ue")
	GMT.iso3to2_eu();
	GMT.iso3to2_af();
	GMT.iso3to2_na();
	GMT.iso3to2_world();
	GMT.mk_codes_values(["PRT", "ESP", "FRA"], [1.0, 2, 3], region="eu");
	@test_throws ErrorException("The region ue is invalid or has not been implemented yet.") GMT.mk_codes_values(["PRT"], [1.0], region="ue")

end
