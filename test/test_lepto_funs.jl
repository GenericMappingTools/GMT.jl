@testset "img2pix tests" begin
	# Test row-major layout
	img_data = reshape(UInt8.(1:100), 10, 10);
	gmt_img = mat2img(img_data, layout="TRB");
	pix = GMT.img2pix(gmt_img);
	@test GMT.pixGetWidth(pix.ptr) == 10
	@test GMT.pixGetHeight(pix.ptr) == 10
	@test GMT.pixGetDepth(pix.ptr) == 8
 
	# Test column-major layout
	img_data_col = collect(reshape(UInt8.(1:100), 10, 10)');
	gmt_img_col = mat2img(img_data_col, layout="TCB");
	pix_col = GMT.img2pix(gmt_img_col);
	@test GMT.pixGetWidth(pix_col.ptr) == 10
	@test GMT.pixGetHeight(pix_col.ptr) == 10
 
	# Test small image
	small_img = mat2img(reshape(UInt8.(1:4), 2, 2), layout="TRB");
	small_pix = GMT.img2pix(small_img);
	@test GMT.pixGetWidth(small_pix.ptr) == 2
	@test GMT.pixGetHeight(small_pix.ptr) == 2
end

@testset "imreconstruct tests" begin
	# Test with UInt8 matrices
	seed = fill(UInt8(0), 10, 10);
	mask = fill(UInt8(255), 10, 10);
	mask[5, 5] = UInt8(0);
	result = GMT.imreconstruct(seed, mask, conn=4);
	@test size(result) == (10, 10)
	@test result[5, 5] == 0

	# Test with GMTimage
	gmt_seed = mat2img(seed, layout="TRB");
	gmt_mask = mat2img(mask, layout="TRB");
	result_gmt = GMT.imreconstruct(gmt_seed, gmt_mask, conn=4);
	@test GMT.getsize(result_gmt) == (10, 10)
	@test result_gmt.image[5, 5] == 0

	#= Test with Bool matrices
	seed_bool = fill(false, 10, 10);
	mask_bool = fill(true, 10, 10);
	mask_bool[5, 5] = false;
	result_bool = GMT.imreconstruct(seed_bool, mask_bool, conn=4);
	@test size(result_bool) == (10, 10)
	@test result_bool[5, 5] == false
	=#
end

@testset "imfill tests" begin
	# Test with UInt8 matrix
	mat = fill(UInt8(255), 10, 10);
	mat[2:9, 2:9] .= 0;
	filled_mat = imfill(mat, conn=4);
	@test size(filled_mat) == (10, 10)
	@test filled_mat[1, 1] == 255

	# Test with GMTimage
	gmt_mat = mat2img(mat, layout="TRB")
	filled_gmt = imfill(gmt_mat, conn=4)
	@test GMT.getsize(filled_gmt) == (10, 10)
	@test filled_gmt.image[1, 1] == 255
end

#=
@testset "bwconncomp tests" begin
	I = gdalread(TESTSDIR * "assets/packman.png");
	cc1 = bwconncomp(I);
	@test cc1.num_objects == 2
	I = gdalread(TESTSDIR * "assets/packman.png", layout="BCBa");
	cc2 = bwconncomp(I);
	@test cc2.num_objects == 2
	@test cc1.bboxs == cc2.bboxs
	#I = gdalread(TESTSDIR * "assets/packman.png", layout="TCBa");	# Need to fix bug in gdalread for this to work
	#cc2 = bwconncomp(I);
	#@test cc2.num_objects == 2
	#@test cc1.bboxs == cc2.bboxs

	mat = zeros(Bool,8,9); mat[2:5,2:3] .= true; mat[4:5,4] .= true; mat[5:8,6:8] .= true; mat[4,7] = true;
	gdalwrite("c2.png", mat2img(mat))
	I = gdalread("c2.png");		# Comes in with layout TRBa
	cc = bwconncomp(I);
	@test cc.num_objects == 2
	I2 = cc2bw(cc);
	@test I == I2

	I = mat2img(mat);			# Comes in with layout TCBa
	cc = bwconncomp(I);
	I2 = cc2bw(cc);
	@test I == I2

	I = mat2img(flipud(mat)); I.layout = "BCBa";
	cc = bwconncomp(I);
	I2 = cc2bw(cc);
	@test I == I2
end
=#

G = peaks();
G2 = fillsinks(G);

fillsinks(grdcut(G, region="-1.1678/1.786/-3.0/-0.57243"));
@test G2.range[5] > -0.35

BW1 = Bool.([1 0 0 0 0 0 0 0; 1 1 1 1 1 0 0 0; 1 0 0 0 1 0 1 0; 1 0 0 0 1 1 1 0; 1 1 1 1 0 1 1 1; 1 0 0 1 1 0 1 0; 1 0 0 0 1 0 1 0; 1 0 0 0 1 1 1 0]);
BW2 = imfill(BW1);
@test isa(BW2, BitMatrix)
@test sum(BW2) == 40

I = gmtread(TESTSDIR * "assets/chip.png");
imerode(I, sel=strel("disk", 10));
imdilate(I, sel=strel("disk", 10));

x = [0.0 0 0 0 0; 0 1 1 0 0; 0 1 1 0 0; 0 0 0 0 0];
resp = ones(size(x));	resp[:,end] .= 0;
@test imdilate(x) == resp
@test all(imerode(x, Bool[0 1 0; 1 1 1; 0 1 0]) .== 0)

I = gmtread(TESTSDIR * "assets/text.png");
bwconncomp(I);

I = gmtread(TESTSDIR * "assets/packman.png");
imopen(I, sel=strel("box", 20));
imclose(I, sel=strel("box", 20));

interval = [2 2 2; 2 1 1; 2 1 0];
I = gmtread(TESTSDIR * "assets/small_squares.png");
J = bwhitmiss(I, interval);
J = imrankfilter(I, width=10);

a = fill(UInt8(10),10,10);
a[2:4,2:4] .= UInt8(13);
a[6:8,6:8] .= UInt8(18);
I = imhmin(mat2img(a), 4);

a = fill(UInt8(10),10,10);
a[2:4,2:4] .= UInt8(13);
a[6:8,6:8] .= UInt8(18);
I = imhmax(mat2img(a), 4);

I = gmtread(TESTSDIR * "assets/j.png");
J = immorphgrad(I, hsize=5, vsize=5);

I = gmtread(TESTSDIR * "assets/circles.png");
J = bwperim(I);

I = gmtread(TESTSDIR * "assets/rice.png");
J = imtophat(I, hsize=11, vsize=11);
J = imbothat(I, hsize=11, vsize=11);
J = imsobel(I);

I = gmtread(TESTSDIR * "assets/bone.png");
J = bwskell(I);

I = gmtread(TESTSDIR * "assets/bunny_cenora.jpg");
J = imsegment(I, colors=7);

I = gmtread(TESTSDIR * "assets/moon.png");
J = imfilter(I, [1 0 -1; 2 0 -2; 1 0 -1]);
J = imfilter(I, [1 0 -1; 2 0 -2; 1 0 -1], sep=true);

G = peaks();
imregionalmin(G);
imregionalmax(G);

I = gmtread(TESTSDIR * "assets/circles.png");
J = imclearborder(I)
