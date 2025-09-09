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

    # Test basic padding with zeros
    a = [1 2; 3 4]
    padded = padarray(a, 1, padval=0)
    @test size(padded) == (4,4)
    @test padded == [0 0 0 0; 0 1 2 0; 0 3 4 0; 0 0 0 0]

    # Test asymmetric padding
    padded_asym = padarray(a, (2,1), padval=0)
    @test size(padded_asym) == (6,4)
	
	# Test with Float32 array
	a_float = Float32[1.0 2.0; 3.0 4.0]
	padded_float = padarray(a_float, 1, padval=0.0)
	@test eltype(padded_float) == Float32
	@test padded_float[1,1] == 0.0

	# imcomplement
	I = gmtread(GMT.TESTSDIR * "assets/table_flowers.jpg");
	imcomplement(I);
	imcomplement!(I);

	I = gmtread(GMT.TESTSDIR * "assets/coins.jpg");
	binarize(I, band=1);
	binarize(I, [30, 80]);

	# Anaglyph
	anaglyph("@earth_relief_10m", region=(-10, -6, 36, 42));
	anaglyph("@earth_relief_10m", region=(-10, -6, 36, 42), view3d=true);
end
