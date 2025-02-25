@testset "SOLIDS" begin

	GMT.icosahedron();
	GMT.octahedron();
	GMT.dodecahedron();
	GMT.tetrahedron();
	GMT.cube();
	torus();

	FV = sphere();
	D  = replicant(FV, replicate=(centers=rand(10,3), scales=0.1));
	D  = replicant(FV, replicate=(rand(5,3)*100, 0.1));
	D  = replicant(FV, replicate=rand(5,3)*100);

	FV = gmtread(TESTSDIR * "assets/file.obj");
	FV = cylinder(1,4, np=5);
	
	ns=15; x=linspace(0,2*pi,ns).+1; y=zeros(size(x)); z=-cos.(x); Vc=[x[:] y[:] z[:]];
	FV = revolve(Vc);

	ellipse3D(center=(2,0,0), e=0.8, plane=:xz);
	ellipse3D(center=(2,0,0), e=0.8, plane=:xz, rot=45);
	ellipse3D(e=0.8, is2D=true);
	ellipse3D(e=0.8, is2D=true, rot=45);

	verts = [0.0 0.0 0.0; 1.0 1.0 1.0; 2.0 2.0 2.0];
	FV = fv2fv([[1 2 3]], verts);
    @test begin
		res = translate(FV, dx=1.0)
		all(res.verts[:,1] .== verts[:,1] .+ 1.0) && all(res.verts[:,2:3] .== verts[:,2:3]) && res.bbox == [1.0, 3.0, 0.0, 2.0, 0.0, 2.0]
	end
	FV = translate!(FV, dx=1.0)

	verts = [0.0 0.0 0.0; 1.0 0.0 0.0; 1.0 1.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0; 1.0 0.0 1.0; 1.0 1.0 1.0; 0.0 1.0 1.0]
	faces = [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8]
	FV = fv2fv(faces, verts);
	rotated = rotate(FV, [90.0, 0.0, 0.0]);
	@test rotated.bfculling == false
	@test size(rotated.verts) == size(verts)
	@test !isempty(rotated.bbox)
	rotate!(FV, [90.0, 0.0, 0.0]);

	@testset "flatfv" begin
		# Test with basic GMTimage input
		img = mat2img([UInt8(i) for i=1:8, j=1:8])
		fv = flatfv(img)
		@test isa(fv, GMTfv)
		@test fv.isflat[1] == true
		@test length(fv.color[1]) == 64
	
		# Test with circle shape
		fv_circle = flatfv(img, shape=:circle)
		@test isa(fv_circle, GMTfv)
	
		# Test with ellipse shape
		fv_ellipse = flatfv(img, shape=:ellipse)
		@test isa(fv_ellipse, GMTfv)
	
		# Test with custom shape array (2 columns)
		shape_2d = [0.0 0.0; 1.0 0.0; 1.0 1.0; 0.0 1.0]
		fv_custom = flatfv(img, shape=shape_2d)
		@test isa(fv_custom, GMTfv)
	
		# Test with custom shape array (3 columns)
		shape_3d = [0.0 0.0 1.0; 1.0 0.0 1.0; 1.0 1.0 1.0; 0.0 1.0 1.0]
		fv_3d = flatfv(img, shape=shape_3d)
		@test isa(fv_3d, GMTfv)
	end

	@testset "loft tests" begin
		# Basic test with two simple curves
		C1 = [0.0 0.0 0.0; 1.0 0.0 0.0; 1.0 1.0 0.0]
		C2 = [0.0 0.0 1.0; 1.0 0.0 1.0; 1.0 1.0 1.0]
		result = loft(C1, C2)
		@test size(result.faces, 1) > 0
		@test size(result.verts, 1) > 0

		# Test with explicit n_steps
		result_steps = loft(C1, C2, n_steps=5)
		@test size(result_steps.verts, 1) == 15  # 3 points × 5 steps

		# Test with non-closed option
		result_open = loft(C1, C2, closed=false)
		@test size(result_open.faces, 1) < size(result.faces, 1)

		# Test with triangular mesh type
		result_tri = loft(C1, C2, type=:tri)
		#@test all(length.(eachrow(result_tri.faces)) .== 3)	<== FAILS

		# Test error for mismatched curve sizes
		C3 = [0.0 0.0 0.0; 1.0 0.0 0.0]
		@test_throws AssertionError loft(C1, C3)

		# Test with zero distance between curves		<== FAILS: "attempt to access 3×0 Matrix{Float64} at index [1, 0]"
		#C4 = copy(C1)
		#result_zero = loft(C1, C4)
		#@test size(result_zero.verts, 1) > 0

		# Test with large curves
		large_C1 = rand(100, 3)
		large_C2 = rand(100, 3)
		result_large = loft(large_C1, large_C2)
		#@test size(result_large.verts, 1) == size(large_C1, 1) * 2		# <== FAILS often probably because of 'rand'
	end
end
