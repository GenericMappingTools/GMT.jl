@testset "LASZ" begin

	out = [0.0 0 0; 1 0 1; 0 1 1; 1 1 2; 0 0 2];
	dat2las("lixo.laz", out);
	
	in = las2dat("lixo.laz");
	t = getproperty(in, Symbol(in.stored))
	
	@test t == out
	
	# Remove garbage
	rm("lixo.laz")

end
