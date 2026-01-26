@testset "CHOROPLETHS" begin

	println("	CHOROPLETHS")

	D = getdcw("PT,ES,FR", file=:ODS);
	choropleth(D, ["PT","ES","FR"], [10.0, 20.0, 30.0])

	# Using a Dict
	choropleth(D, Dict("PT"=>10, "ES"=>20, "FR"=>30))

	# With custom colormap and no outlines
	choropleth(D, ["PT","ES","FR"], [1.0, 2.0, 3.0], cmap="bamako", outline=false)

	# The example in "Tutorials"
	#D = getdcw("US", states=true, file=:ODS);
	#Df = filter(D, _region=(-125,-66,24,50), _unique=true);
	#pop = gmtread(TESTSDIR * "assets/uspop.csv");
	#choropleth(Df, pop, "NAME", show=false)
end
