@testset "IMGFUNS" begin

	println("	IMGFUNS")
	
	I = mat2img(rand(UInt8, 64,64,3));
	isodata(I);
	binarize(I, 127);
	binarize(I, 127,revert= true);
	rgb2gray(I);

	Iycbcr = rgb2YCbCr(mat2img(rand(UInt8, 16, 16, 3)));
	Cb = rgb2YCbCr(mat2img(rand(UInt8, 16, 16, 3)), Cr=true, BT709=true)[3];
end
