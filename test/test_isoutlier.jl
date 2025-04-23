@testset "PCA" begin

	println("	ISOUTLIER")
	
	x = [57, 59, 60, 100, 59, 58, 57, 58, 300, 61, 62, 60, 62, 58, 57];
	@test findall(isoutlier(x)) == [4, 9]

	x = -50.0:50;y = x / 50 .+ 3 .+ 0.25 * rand(length(x)); y[[30,50,60]] = [4,-3,6];
	isoutlier([x y], width=5);
	isoutlier([x y], threshold=0.1);
end
