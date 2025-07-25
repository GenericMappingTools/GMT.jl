@testset "LASZ" begin

	out = [0.0 0 0; 1 0 1; 0 1 1; 1 1 2; 0 0 2];
	lazwrite("lixo.laz", out);
	
	in = lazread("lixo.laz");
	t = getproperty(in, Symbol(in.stored))
	lazinfo("lixo.laz", veronly=1);
	lazinfo("lixo.laz");
	
	@test t == out
	
	lazwrite("lixo.laz", peaks());
	lazread("lixo.laz")

	# Remove garbage
	rm("lixo.laz")

	@testset "lasread/lazread basic API" begin
		# These tests assume you have a sample LAZ or LAS file for testing.
		# Replace "test.laz" with the path to a real file for actual tests.
		testfile = TESTSDIR * "/assets/test.laz"
		if isfile(testfile)
			# Test reading xyz
			out = lazread(testfile, out="xyz")
			@test isa(out, GMT.Laszip.lasout_types)
			@test out.stored == "ds" || out.stored == "grd"
			if out.stored == "ds"
				@test isa(out.ds, GMTdataset)
				@test size(out.ds.data, 2) == 3
			end

			# Test reading with grid output
			out_grid = lazread(testfile, grid=true)
			@test isa(out_grid, GMT.Laszip.lasout_types)
			@test out_grid.stored == "grd"
			@test isa(out_grid.grd, GMTgrid)

			# Test reading with image output (if RGB present)
			try
				out_img = lazread(testfile, image=true)
				@test isa(out_img, GMT.Laszip.lasout_types)
				@test out_img.stored == "img"
			catch e
				@test occursin("error", String(e))
			end

			# Test reading with intensity
			out_xyzi = lazread(testfile, out="xyzi")
			@test isa(out_xyzi, GMT.Laszip.lasout_types)
			@test isa(out_xyzi.dsv, Vector)
			@test length(out_xyzi.dsv) == 2

			# Test reading with classification (if present)
			out_xyzc = lazread(testfile, out="xyzc")
			@test isa(out_xyzc, GMT.Laszip.lasout_types)
			@test isa(out_xyzc.dsv, Vector)
			@test length(out_xyzc.dsv) == 2

			# Test reading with time (if present)
			#out_xyzt = lazread(testfile, out="xyzt")
			#@test isa(out_xyzt, GMT.Laszip.lasout_types)
			#@test out_xyzt.stored == "ds"
			#@test size(out_xyzt.ds.data, 2) == 4
		else
			@info "Test file $testfile not found. Skipping lasread/lazread tests."
		end
	end

	@testset "lazinfo basic API" begin
		testfile = TESTSDIR * "/assets/test.laz"
		if isfile(testfile)
			info = lazinfo(testfile)
			@test info !== nothing
		else
			@info "Test file $testfile not found. Skipping lazinfo tests."
		end
	end

	@testset "lasout_types struct" begin
		# Test default constructor
		s = GMT.Laszip.lasout_types()
		@test s.stored == ""
		@test isa(s.grd, GMTgrid)
		@test isa(s.img, GMTimage)
		@test isa(s.ds, GMTdataset)
		@test isa(s.dsv, Vector)
	end
end
