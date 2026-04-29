using HTTP		# triggers GMTDGTLidarExt load

println("		Entering: test_dgt.jl")

@testset "DGT LIDAR Extension" begin

	ext = Base.get_extension(GMT, :GMTDGTLidarExt)
	@test ext !== nothing

	# ------------------------------------------------------------------
	@testset "_make_cookie_header" begin
		result = ext._make_cookie_header(Dict("session" => "abc", "token" => "xyz"))
		@test occursin("session=abc", result)
		@test occursin("token=xyz", result)
		@test occursin(";", result)
		@test ext._make_cookie_header(Dict{String,String}()) == ""
		@test ext._make_cookie_header(Dict("k" => "v")) == "k=v"
	end

	# ------------------------------------------------------------------
	@testset "_get_file_extension" begin
		@test ext._get_file_extension("image/tiff; application=geotiff") == ".tiff"
		@test ext._get_file_extension("image/tiff") == ".tiff"
		@test ext._get_file_extension("application/vnd.laszip") == ".laz"
		@test ext._get_file_extension("application/json") == ""
		@test ext._get_file_extension("") == ""
	end

	# ------------------------------------------------------------------
	@testset "collection validation" begin
		@test_throws ErrorException GMT.dgt_lidar([0.,1.,0.,1.]; collection="INVALID")
	end

	# ------------------------------------------------------------------
	@testset "_divide_bbox" begin
		# Small bbox (~11x11 km) → single sub-bbox
		small = (-9.1, -9.0, 38.7, 38.8)
		result = ext._divide_bbox(small)
		@test length(result) == 1
		@test result[1] == small

		# Large bbox (Portugal mainland) → multiple sub-bboxes
		large = (-9.5, -6.2, 37.0, 42.0)
		result = ext._divide_bbox(large)
		@test length(result) > 1
		# Sub-bboxes collectively cover the original extent
		@test minimum(b[1] for b in result) ≈ large[1]
		@test maximum(b[2] for b in result) ≈ large[2]
		@test minimum(b[3] for b in result) ≈ large[3]
		@test maximum(b[4] for b in result) ≈ large[4]

		# Custom max area
		tiny_result = ext._divide_bbox(large, 50)
		@test length(tiny_result) > length(result)
	end

	# ------------------------------------------------------------------
	@testset "_parse_stac_response" begin
		# Empty features
		r = ext._parse_stac_response("{\"features\":[]}")
		@test isempty(r["features"])

		# Single feature — fields correctly extracted
		json = """{"features":[{"type":"Feature","collection":"MDS-2m","id":"tile_001","links":[{"rel":"self","href":"https://cdd.dgt.gov.pt/items/tile_001"}],"assets":{"data":{"href":"https://s3.example.com/tile_001.tiff","type":"image/tiff; application=geotiff"}}}]}"""
		r = ext._parse_stac_response(json)
		@test length(r["features"]) == 1
		feat = r["features"][1]
		@test feat["collection"] == "MDS-2m"
		@test feat["id"] == "tile_001"
		@test length(feat["links"]) == 1
		@test feat["links"][1]["rel"] == "self"
		@test feat["links"][1]["href"] == "https://cdd.dgt.gov.pt/items/tile_001"
		@test length(feat["assets"]) == 1

		# LAZ asset type — href before type
		json_laz = """{"features":[{"type":"Feature","collection":"LAZ","id":"cloud_001","links":[],"assets":{"d":{"href":"https://s3.example.com/cloud.laz","type":"application/vnd.laszip"}}}]}"""
		r2 = ext._parse_stac_response(json_laz)
		@test r2["features"][1]["collection"] == "LAZ"
		@test length(r2["features"][1]["assets"]) == 1

		# LAZ asset type — type before href (real API may return this order)
		json_laz2 = """{"features":[{"type":"Feature","collection":"LAZ","id":"cloud_002","links":[],"assets":{"d":{"type":"application/vnd.laszip","href":"https://s3.example.com/cloud2.laz"}}}]}"""
		r3 = ext._parse_stac_response(json_laz2)
		@test length(r3["features"][1]["assets"]) == 1
		asset3 = first(values(r3["features"][1]["assets"]))
		@test asset3["href"] == "https://s3.example.com/cloud2.laz"
		@test asset3["type"] == "application/vnd.laszip"
	end

	# ------------------------------------------------------------------
	@testset "_collect_urls" begin
		# Empty input
		@test isempty(ext._collect_urls(Dict("features" => [])))

		# TIFF feature — correct collection/url/ext, item_id from self link
		feature = Dict(
			"collection" => "MDS-2m",
			"id"         => "tile_001",
			"links"      => [Dict("rel" => "self", "href" => "https://cdd.dgt.gov.pt/items/tile_001")],
			"assets"     => Dict("d" => Dict("href" => "https://s3.example.com/tile_001.tiff",
			                                 "type" => "image/tiff; application=geotiff"))
		)
		r = ext._collect_urls(Dict("features" => [feature]))
		@test haskey(r, "MDS-2m")
		@test length(r["MDS-2m"]) == 1
		url, id, ext_str = r["MDS-2m"][1]
		@test url == "https://s3.example.com/tile_001.tiff"
		@test id  == "tile_001"
		@test ext_str == ".tiff"

		# Duplicate URL → deduplicated
		r2 = ext._collect_urls(Dict("features" => [feature, feature]))
		@test length(r2["MDS-2m"]) == 1

		# LAZ feature — item_id falls back to "id" field when no self link
		laz_feat = Dict(
			"collection" => "LAZ",
			"id"         => "cloud_001",
			"links"      => [],
			"assets"     => Dict("d" => Dict("href" => "https://s3.example.com/cloud.laz",
			                                 "type" => "application/vnd.laszip"))
		)
		r3 = ext._collect_urls(Dict("features" => [laz_feat]))
		_, laz_id, laz_ext = r3["LAZ"][1]
		@test laz_id  == "cloud_001"
		@test laz_ext == ".laz"

		# Two different collections → two keys
		r4 = ext._collect_urls(Dict("features" => [feature, laz_feat]))
		@test haskey(r4, "MDS-2m")
		@test haskey(r4, "LAZ")
	end

	# ------------------------------------------------------------------
	@testset "_extract_form_data" begin
		html = """<html><body>
		<form id="kc-form-login" action="https://auth.example.com/login">
		<input type="hidden" name="session_code" value="abc123">
		<input type="hidden" name="execution" value="def456">
		<input type="text" name="username">
		</form></body></html>"""
		action, form_data = ext._extract_form_data(html)
		@test action == "https://auth.example.com/login"
		@test form_data["session_code"] == "abc123"
		@test form_data["execution"] == "def456"
		@test !haskey(form_data, "username")	# type=text, not hidden

		# No form
		action2, form_data2 = ext._extract_form_data("<html><body>nothing</body></html>")
		@test action2 === nothing
		@test isempty(form_data2)
	end

	# ------------------------------------------------------------------
	@testset "_extract_cookies" begin
		mock_resp = (headers = [
			"Set-Cookie"   => "session=abc123; Path=/; HttpOnly",
			"Content-Type" => "text/html",
			"Set-Cookie"   => "token=xyz789; Path=/; Secure",
		],)
		cookies = ext._extract_cookies(mock_resp)
		@test cookies["session"] == "abc123"
		@test cookies["token"] == "xyz789"
		@test !haskey(cookies, "Content-Type")

		# Cookie with = in value (limit=2 on split)
		mock_resp2 = (headers = ["Set-Cookie" => "data=a=b=c; Path=/"],)
		cookies2 = ext._extract_cookies(mock_resp2)
		@test cookies2["data"] == "a=b=c"

		# No Set-Cookie headers
		@test isempty(ext._extract_cookies((headers = ["Content-Type" => "application/json"],)))
	end

	# ------------------------------------------------------------------
	@testset "_read_dgt_credentials" begin
		mktempdir() do tmpdir
			dgt_file = joinpath(tmpdir, ".dgt")

			# Valid file with comment
			write(dgt_file, "# Login data for the DGT LIDAR downloads\nlogin user@test.pt\npassword secret123\n")
			u, p = ext._read_dgt_credentials(dgt_file)
			@test u == "user@test.pt"
			@test p == "secret123"

			# Extra whitespace around values
			write(dgt_file, "# comment\nlogin  user@test.pt  \npassword  secret123  \n")
			u2, p2 = ext._read_dgt_credentials(dgt_file)
			@test u2 == "user@test.pt"
			@test p2 == "secret123"

			# Missing password line → error
			write(dgt_file, "# comment\nlogin user@test.pt\n")
			@test_throws ErrorException ext._read_dgt_credentials(dgt_file)

			# Missing login line → error
			write(dgt_file, "# comment\npassword secret\n")
			@test_throws ErrorException ext._read_dgt_credentials(dgt_file)

			# File not found → error
			@test_throws ErrorException ext._read_dgt_credentials(joinpath(tmpdir, "no_such_file"))
		end
	end

	# ------------------------------------------------------------------
	@testset "dgt_mosaic" begin
		tmpdir = mktempdir()
		#mktempdir() do tmpdir
			coll_dir = joinpath(tmpdir, "MDS-2m")
			mkpath(coll_dir)

			# Error: no .tiff files in collection dir
			@test_throws ErrorException GMT.dgt_mosaic([-9.15,-9.05,38.72,38.78];
			                                           src_dir=tmpdir, outfile=joinpath(tmpdir,"out.tiff"))

			# Error: collection dir does not exist
			@test_throws ErrorException GMT.dgt_mosaic([-9.15,-9.05,38.72,38.78]; src_dir=tmpdir, collection="NO-SUCH")

			# Create a synthetic WGS84 GeoTIFF covering [-9.2,-9.0] × [38.7,38.9]
			ds = Gdal.create("", driver=getdriver("MEM"), width=100, height=100, nbands=1, dtype=Float32)
			Gdal.write!(ds, rand(Float32, 100, 100), 1)
			setproj!(ds, toWKT(importEPSG(4326)))
			# geotransform: [x_origin, x_pixel, 0, y_origin, 0, y_pixel]
			setgeotransform!(ds, [-9.2, 0.002, 0.0, 38.9, 0.0, -0.002])
			tif_path = joinpath(coll_dir, "tile_test.tiff")
			gdaltranslate(ds, ["-of", "GTiff"]; save=tif_path)
			@test isfile(tif_path)

			bbox = [-9.15, -9.05, 38.72, 38.78]

			# gdaltranslate path (inc=0, default)
			outfile = joinpath(tmpdir, "mosaic.tiff")
			result = GMT.dgt_mosaic(bbox; src_dir=tmpdir, outfile=outfile)
			@test result == outfile
			@test isfile(outfile)

			# gdalwarp path (inc != 0), default cubicspline
			outfile2 = joinpath(tmpdir, "mosaic_warp.tiff")
			result2 = GMT.dgt_mosaic(bbox; src_dir=tmpdir, outfile=outfile2, inc=0.001)
			@test isfile(outfile2)

			# gdalwarp path with explicit method
			outfile3 = joinpath(tmpdir, "mosaic_bilinear.tiff")
			result3 = GMT.dgt_mosaic(bbox; src_dir=tmpdir, outfile=outfile3, inc=0.001, method="bilinear")
			@test isfile(outfile3)

			# _underscored src_dir resolves to GMTuserdir()/DGT/<name>
			# Just check the resolution logic by testing the error path (dir won't exist)
			@test_throws ErrorException GMT.dgt_mosaic(bbox; src_dir="_nonexistent_test_subdir")
			#GMT.resetGMT()		# TIFF files are still under GDAL grip and wont let be deleted
		#end
		#rm(tmpdir, recursive=true, force=true)
	end

end	# @testset "DGT LIDAR Extension"

# ------------------------------------------------------------------
# Integration tests — require real DGT credentials in ~/.dgt
# Adjust INTEGRATION_BBOX to a small area that downloads ~2 tiles.
const INTEGRATION_BBOX = [-9.11, -9.0877, 38.728, 38.735]

if isfile(joinpath(homedir(), ".dgt"))
	@testset "DGT LIDAR Integration" begin
		#mktempdir() do tmpdir
		tmpdir = mktempdir()

			# --- dgt_lidar: auth + search, no download ---
			@testset "dry run" begin
				@test_nowarn GMT.dgt_lidar(INTEGRATION_BBOX; output_dir=tmpdir, dry=true)
			end

			# --- dgt_lidar: real download (covers _authenticate, _search_stac, _download_file) ---
			@testset "download" begin
				GMT.dgt_lidar(INTEGRATION_BBOX; output_dir=tmpdir)
				subdirs = filter(isdir, readdir(tmpdir, join=true))
				@test !isempty(subdirs)
				tiffs = [f for d in subdirs for f in readdir(d, join=true) if endswith(lowercase(f), ".tiff")]
				@test !isempty(tiffs)
				println("    Downloaded $(length(tiffs)) tile(s)")
			end

			# --- dgt_mosaic: mosaic downloaded tiles via gdaltranslate ---
			@testset "mosaic gdaltranslate" begin
				outfile = joinpath(tmpdir, "mosaic.tiff")
				result = GMT.dgt_mosaic(INTEGRATION_BBOX; src_dir=tmpdir, outfile=outfile)
				@test isfile(outfile)
				@test result == outfile
				@test filesize(outfile) > 0
			end

			# --- dgt_mosaic: resample via gdalwarp ---
			@testset "mosaic gdalwarp" begin
				outfile = joinpath(tmpdir, "mosaic_2m.tiff")
				GMT.dgt_mosaic(INTEGRATION_BBOX; src_dir=tmpdir, outfile=outfile, inc=2.0)
				@test isfile(outfile)
				@test filesize(outfile) > 0
			end

			# --- re-run: all tiles exist → all skipped (file count unchanged) ---
			@testset "resume (skip existing)" begin
				coll_dir = joinpath(tmpdir, "MDS-2m")
				n_before = length(readdir(coll_dir))
				GMT.dgt_lidar(INTEGRATION_BBOX; output_dir=tmpdir)
				@test length(readdir(coll_dir)) == n_before
			end
			#GMT.resetGMT()		# TIFF files are still under GDAL grip and wont let be deleted
		#end
		#rm(tmpdir, recursive=true, force=true)
	end
end
