@testset "LOWESS" begin

	println("	LOWESS")
	
	x = sort(10 .* rand(100));
	y = sin.(x) .+ 0.5 * rand(100);
	ys = lowess(x, y, span=0.2);
	ys = lowess(mat2ds([x y]), span=0.2);
end
