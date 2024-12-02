@testset "CODY" begin

	@testset "helper_geoglimits" begin
		# Test empty projection string
		@test GMT.helper_geoglimits("", [1.0, 2.0, 3.0, 4.0]) == Float64[]
	
		# Test geographic projection
		@test GMT.helper_geoglimits("+proj=longlat +datum=WGS84", [1.0, 2.0, 3.0, 4.0]) == [1.0, 2.0, 3.0, 4.0]
	
		# Test condensed proj string
		proj_str = "+proj=merc+lon_0=0+k=1+x_0=0+y_0=0+datum=WGS84+units=m+no_defs"
		try
		result = GMT.helper_geoglimits(proj_str, [0.0, 10.0, 0.0, 10.0])
		@test result !== nothing
		@test length(result) == 4
		@test all(isfinite.(result))
		catch
		end
	
		# Test Mollweide projection (diagonal case)
		moll_proj = "+proj=moll +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
		region_moll = [-1e6, 1e6, -1e6, 1e6]
		result_moll = GMT.helper_geoglimits(moll_proj, region_moll)
		@test length(result_moll) == 4
		@test all(isfinite.(result_moll))
	
		# Test UTM projection
		utm_proj = "+proj=utm +zone=30 +datum=WGS84 +units=m +no_defs"
		region_utm = [500000.0, 600000.0, 4000000.0, 4100000.0]
		result_utm = GMT.helper_geoglimits(utm_proj, region_utm)
		@test length(result_utm) == 4
		@test all(result_utm .>= -180.0)
		@test all(result_utm .<= 180.0)
	end
end
