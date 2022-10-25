@testset "STATPLOTS" begin
	println("	STATPLOTS")
	y = randn(200,3);
	violin(y)
	boxplot!(y, Vd=dbg2)
end