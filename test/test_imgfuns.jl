@testset "IMGFUNS" begin

	println("	IMGFUNS")
	
	I = mat2img(rand(UInt8, 64,64,3));
	isodata(I);
	binarize(I, 127);
	binarize(I, 127,revert= true);
	rgb2gray(I);

	I = mat2img(rand(UInt8, 16, 16, 3));
	Iycbcr = rgb2YCbCr(I);
	Cb = rgb2YCbCr(I, Cr=true, BT709=true)[3];
	rgb2lab(I);
	rgb2lab(I, L=true);
	I.layout = "TCPa";
	Iycbcr = rgb2YCbCr(I);
	rgb2lab(I);
end
