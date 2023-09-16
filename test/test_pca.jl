@testset "PCA" begin

	println("	PCA")
	
	pca(rand(25,6));
	pca(mat2grid(rand(64,64,4)));
	pca(mat2grid(rand(Float32,64,64,4)), DT=Float64, npc=3);
	pca(mat2img(rand(UInt8, 64,64,4)));
	pca(mat2img(rand(UInt8, 64,64,5)), npc=4);
end
