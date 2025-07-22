@testset "LASZ" begin

	out = [0.0 0 0; 1 0 1; 0 1 1; 1 1 2; 0 0 2];
	lazwrite("lixo.laz", out);
	
	in = lazread("lixo.laz");
	t = getproperty(in, Symbol(in.stored))
	lazinfo("lixo.laz", veronly=1);
	lazinfo("lixo.laz");
	
	@test t == out
	
	lazwrite("lixo.laz", peaks());
	lazread("lixo.laz")

	# Remove garbage
	rm("lixo.laz")

end
