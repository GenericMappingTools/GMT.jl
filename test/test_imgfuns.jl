@testset "IMGFUNS" begin

	println("	IMGFUNS")
	
	I = mat2img(rand(UInt8, 64,64,3));
	isodata(I);
	binarize(I, 127);
	binarize(I, 127,revert= true);
	rgb2gray(I);
end
