# Some of these tests are from the ImageMorphology package

@testset "IMGMORPH" begin

	println("	IMGMORPH")
	
	function ind2cart(F)
		s = CartesianIndices(axes(F))
		return map(i -> CartesianIndex(s[i]), F)
	end
	@testset "Square Images" begin
		# (1)
		A = [true false; false true]
		F = GMT.feature_transform(A)
		@test F == ind2cart([1 1; 1 4])
		D = GMT.distance_transform(F)
		@test D == [0 1; 1 0]

		# (2)
		A = [true true; false true]
		F = GMT.feature_transform(A)
		@test F == ind2cart([1 3; 1 4])
		D = GMT.distance_transform(F)
		@test D == [0 0; 1 0]

		# (3)
		A = [false false; false true]
		F = GMT.feature_transform(A)
		@test F == ind2cart([4 4; 4 4])
		D = GMT.distance_transform(F)
		@test D ≈ [sqrt(2) 1.0; 1.0 0.0]

		# (4)
		A = [true false true; false true false; true true false]
		F = GMT.feature_transform(A)
		@test F == ind2cart([1 1 7; 1 5 5; 3 6 6])
		D = GMT.distance_transform(F)
		@test D == [0 1 0; 1 0 1; 0 0 1]

		# (5)
		A = [false false true; true true false; true true true]
		F = GMT.feature_transform(A)
		@test F == ind2cart([2 5 7; 2 5 5; 3 6 9])
		D = GMT.distance_transform(F)
		@test D == [1 1 0; 0 0 1; 0 0 0]

		# (6)
		A = [
			true false true true
			false true false false
			false true true false
			true false false false
		]
		F = GMT.feature_transform(A)
		@test F == ind2cart([1 1 9 13; 1 6 6 13; 4 7 11 11; 4 4 11 11])
		D = GMT.distance_transform(F)
		@test D ≈ [0.0 1.0 0.0 0.0; 1.0 0.0 1.0 1.0; 1.0 0.0 0.0 1.0; 0.0 1.0 1.0 sqrt(2)]
	end

	@testset "Rectangular Images" begin
		# (1)
		A = [true false true; false true false]
		F = GMT.feature_transform(A)
		@test F == ind2cart([1 1 5; 1 4 4])
		D = GMT.distance_transform(F)
		@test D == [0 1 0; 1 0 1]

		# (2)
		A = [true false; false false; false true]
		F = GMT.feature_transform(A)
		@test F == ind2cart([1 1; 1 6; 6 6])
		D = GMT.distance_transform(F)
		@test D == [0 1; 1 1; 1 0]

		# (3)
		A = [
			true false false
			true false false
			false true true
			true true true
			false true false
		]
		F = GMT.feature_transform(A)
		@test F == ind2cart([1 1 1; 2 2 13; 2 8 13; 4 9 14; 4 10 10])
		D = GMT.distance_transform(F)
		@test D == [0.0 1.0 2.0; 0.0 1.0 1.0; 1.0 0.0 0.0; 0.0 0.0 0.0; 1.0 0.0 1.0]

	end

	collect(GMT.SplitAxis(1:16, 4))
	collect(GMT.SplitAxes(axes(rand(3, 16)), 4))

	bw = zeros(5,5); bw[2,2] = 1; bw[4,4] = 1;  
	bwdist(bw);
	bwdist_idx(bw);

	A = magic(3);
	@test graydist(A,1, "chessboard") + graydist(A,9, "chessboard") == [10.0  11.0  17.0; 13.0  10.0  13.0; 17.0  17.0  10.0]
	@test graydist(A,1,1, "chessboard") + graydist(A,3,3, "chessboard") == [10.0  11.0  17.0; 13.0  10.0  13.0; 17.0  17.0  10.0]

	marker = [0 0 0 0 0; 0 0 0 0 0; 0 0 1 0 0; 0 0 0 0 0; 0 0 0 0 0]; mask = [0 0 0 0 0; 0 1 1 1 0; 0 1 1 1 0; 0 1 1 1 0; 0 0 0 0 0];
	imreconstruct(marker, mask);
	marker = ones(5, 5); marker[1]=Inf; mask = [1 1 1 1 1; 1 0 0 0 1; 1 0 0 0 1; 1 0 0 0 1; 1 1 1 1 1];
	imreconstruct(marker, mask);

end