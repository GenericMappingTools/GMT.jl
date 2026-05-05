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
	# New dispatch methods — use collection="BAD" to trigger collection-validation error inside
	# _dgt_lidar *before* any authentication or network call. Getting that error proves coordinate
	# extraction succeeded and the right method was dispatched.
	@testset "new dispatch methods (no network)" begin

		@testset "two-array (lon, lat)" begin
			@test_throws r"Invalid collection" GMT.dgt_lidar([-9.11,-9.0877], [38.728,38.735]; collection="BAD", verbose=3)
		end

		@testset "GItype (GMTgrid with projection)" begin
			G = mat2grid(rand(Float32, 5, 5), hdr=[-9.11, -9.0877, 38.728, 38.735], proj4=GMT.prj4WGS84)
			@test_throws r"Invalid collection" GMT.dgt_lidar(G; collection="BAD", verbose=3)
		end

		@testset "GDtype (GMTdataset), zoom=0" begin
			# mat2ds with two lon/lat rows → ds_bbox auto-set to [min_lon, max_lon, min_lat, max_lat]
			D = mat2ds([-9.11 38.728; -9.0877 38.735])
			@test D.ds_bbox[1:4] ≈ [-9.11, -9.0877, 38.728, 38.735]
			@test_throws r"Invalid collection" GMT.dgt_lidar(D; collection="BAD", verbose=3)
		end

		@testset "GDtype, negative zoom rejected" begin
			D = mat2ds([-9.11 38.728; -9.0877 38.735])
			@test_throws r"Invalid zoom" GMT.dgt_lidar(D; zoom=-1, collection="MDS-2m", verbose=3)
		end

		# Point / scalar dispatch (neighbors=0 → tiny ε-box, no mosaic call)
		@testset "scalar (lon, lat) — dispatches to _dgt_lidar" begin
			@test_throws r"Invalid collection" GMT.dgt_lidar(-9.1, 38.7; collection="BAD", verbose=3)
		end

		@testset "2-element array [lon, lat] — dispatches to _dgt_lidar" begin
			@test_throws r"Invalid collection" GMT.dgt_lidar([-9.1, 38.7]; collection="BAD", verbose=3)
		end

		@testset "wrong-length array → error" begin
			@test_throws r"must have 2 elements" GMT.dgt_lidar([1.0, 2.0, 3.0]; collection="BAD", verbose=3)
		end

		# proj kwarg threaded through all dispatches
		@testset "proj passthrough to _dgt_lidar" begin
			@test_throws r"Invalid collection" GMT.dgt_lidar([-9.11,-9.0877,38.728,38.735]; collection="BAD", proj="geog", verbose=3)
		end

		# latest kwarg — collection "BAD" still errors regardless of latest value
		@testset "latest=true (default)" begin
			@test_throws r"Invalid collection" GMT.dgt_lidar([-9.11,-9.0877,38.728,38.735]; collection="BAD", latest=true, verbose=3)
		end

		@testset "latest=false passthrough" begin
			@test_throws r"Invalid collection" GMT.dgt_lidar([-9.11,-9.0877,38.728,38.735]; collection="BAD", latest=false, verbose=3)
		end

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
	@testset "_filter_latest!" begin
		# No versioned files → nothing filtered
		u1 = Dict("MDS-2m" => [("url1","tile_001_2024",".tiff"),
		                        ("url2","tile_002_2024",".tiff")])
		ext._filter_latest!(u1)
		@test length(u1["MDS-2m"]) == 2

		# One versioned file (_v01) replaces unversioned base
		u2 = Dict("MDS-2m" => [("url1","tile_001_2024",".tiff"),
		                        ("url2","tile_001_2024_v01",".tiff")])
		ext._filter_latest!(u2)
		@test length(u2["MDS-2m"]) == 1
		@test u2["MDS-2m"][1][2] == "tile_001_2024_v01"

		# Multiple versions → keep highest
		u3 = Dict("MDS-2m" => [("url1","tile_001_2024",".tiff"),
		                        ("url2","tile_001_2024_v01",".tiff"),
		                        ("url3","tile_001_2024_v02",".tiff")])
		ext._filter_latest!(u3)
		@test length(u3["MDS-2m"]) == 1
		@test u3["MDS-2m"][1][2] == "tile_001_2024_v02"

		# Mixed: tile_001 has versions, tile_002 does not → 2 unique bases remain
		u4 = Dict("MDS-2m" => [("url1","tile_001_2024",    ".tiff"),
		                        ("url2","tile_001_2024_v01",".tiff"),
		                        ("url3","tile_002_2024",    ".tiff")])
		ext._filter_latest!(u4)
		@test length(u4["MDS-2m"]) == 2
		ids4 = Set(t[2] for t in u4["MDS-2m"])
		@test "tile_001_2024_v01" in ids4
		@test "tile_002_2024"     in ids4
		@test "tile_001_2024"    ∉ ids4

		# Empty collection → no crash
		u5 = Dict("MDS-2m" => Tuple{String,String,String}[])
		ext._filter_latest!(u5)
		@test isempty(u5["MDS-2m"])

		# Multiple collections filtered independently
		u6 = Dict("MDS-2m" => [("u1","tile_A",".tiff"),("u2","tile_A_v01",".tiff")],
		          "LAZ"    => [("u3","cloud_1",".laz"), ("u4","cloud_1_v01",".laz"),
		                       ("u5","cloud_2",".laz")])
		ext._filter_latest!(u6)
		@test length(u6["MDS-2m"]) == 1
		@test u6["MDS-2m"][1][2] == "tile_A_v01"
		@test length(u6["LAZ"]) == 2
		laz_ids = Set(t[2] for t in u6["LAZ"])
		@test "cloud_1_v01" in laz_ids
		@test "cloud_2"     in laz_ids
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

			# proj="geog" forces gdalwarp even with inc=0
			outfile4 = joinpath(tmpdir, "mosaic_geog.tiff")
			GMT.dgt_mosaic(bbox; src_dir=tmpdir, outfile=outfile4, proj="geog")
			@test isfile(outfile4)

			# proj bare EPSG digits → EPSG:32629 (UTM zone 29N)
			outfile5 = joinpath(tmpdir, "mosaic_utm.tiff")
			GMT.dgt_mosaic(bbox; src_dir=tmpdir, outfile=outfile5, proj="32629")
			@test isfile(outfile5)

			# proj full authority string
			outfile6 = joinpath(tmpdir, "mosaic_epsg.tiff")
			GMT.dgt_mosaic(bbox; src_dir=tmpdir, outfile=outfile6, proj="EPSG:4326")
			@test isfile(outfile6)

			# proj + inc together (both warp options active)
			outfile7 = joinpath(tmpdir, "mosaic_geog_inc.tiff")
			GMT.dgt_mosaic(bbox; src_dir=tmpdir, outfile=outfile7, proj="geog", inc=0.001)
			@test isfile(outfile7)

			# outfile="grid" → returns GMTgrid, no file written
			G_mem = GMT.dgt_mosaic(bbox; src_dir=tmpdir, outfile="grid")
			@test G_mem isa GMT.GMTgrid
			@test size(G_mem) != (0, 0)

			# _underscored src_dir resolves to GMTuserdir()/DGT/<name>
			# Just check the resolution logic by testing the error path (dir won't exist)
			@test_throws ErrorException GMT.dgt_mosaic(bbox; src_dir="_nonexistent_test_subdir")
		#end
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

			# --- dgt_lidar: auth + search, no download (primary bbox form) ---
			@testset "dry run (bbox array)" begin
				@test_nowarn GMT.dgt_lidar(INTEGRATION_BBOX; output_dir=tmpdir, dry=true, verbose=3)
			end

			# --- new dispatch forms: dry run only, no download ---
			@testset "dry run (two-array dispatch)" begin
				lo, hi = INTEGRATION_BBOX[1:2], INTEGRATION_BBOX[3:4]
				@test_nowarn GMT.dgt_lidar(lo, hi; dry=true, verbose=3)
			end

			@testset "dry run (GItype dispatch)" begin
				G = mat2grid(rand(Float32, 5, 5), hdr=INTEGRATION_BBOX, proj4=GMT.prj4WGS84)
				@test_nowarn GMT.dgt_lidar(G; dry=true, verbose=3)
			end

			@testset "dry run (GDtype dispatch, zoom=0)" begin
				D = mat2ds([INTEGRATION_BBOX[1] INTEGRATION_BBOX[3]; INTEGRATION_BBOX[2] INTEGRATION_BBOX[4]])
				@test_nowarn GMT.dgt_lidar(D; dry=true, verbose=3)
			end

			# --- new point / scalar dispatch forms: dry run, no download ---
			@testset "dry run (scalar lon, lat)" begin
				lon, lat = (INTEGRATION_BBOX[1] + INTEGRATION_BBOX[2]) / 2,
				           (INTEGRATION_BBOX[3] + INTEGRATION_BBOX[4]) / 2
				@test_nowarn GMT.dgt_lidar(lon, lat; dry=true, verbose=3)
			end

			@testset "dry run (2-element array [lon, lat])" begin
				lon, lat = (INTEGRATION_BBOX[1] + INTEGRATION_BBOX[2]) / 2,
				           (INTEGRATION_BBOX[3] + INTEGRATION_BBOX[4]) / 2
				@test_nowarn GMT.dgt_lidar([lon, lat]; dry=true, verbose=3)
			end

			# --- dgt_lidar: real download (covers _authenticate, _search_stac, _download_file) ---
			@testset "download" begin
				GMT.dgt_lidar(INTEGRATION_BBOX; output_dir=tmpdir, verbose=3)
				subdirs = filter(isdir, readdir(tmpdir, join=true))
				@test !isempty(subdirs)
				tiffs = [f for d in subdirs for f in readdir(d, join=true) if endswith(lowercase(f), ".tiff")]
				@test !isempty(tiffs)
				println("    Downloaded $(length(tiffs)) tile(s)")
			end

			# --- dgt_mosaic: mosaic downloaded tiles via gdaltranslate ---
			@testset "mosaic gdaltranslate" begin
				outfile = joinpath(tmpdir, "mosaic.tiff")
				result = GMT.dgt_mosaic(INTEGRATION_BBOX; src_dir=tmpdir, outfile=outfile, verbose=3)
				@test isfile(outfile)
				@test result == outfile
				@test filesize(outfile) > 0
			end

			# --- dgt_mosaic: outfile="grid" → returns GMTgrid ---
			@testset "mosaic outfile=grid" begin
				G = GMT.dgt_mosaic(INTEGRATION_BBOX; src_dir=tmpdir, outfile="grid", verbose=3)
				@test G isa GMT.GMTgrid
				@test size(G) != (0, 0)
			end

			# --- dgt_lidar: mosaic="file.tiff" writes mosaic to disk ---
			@testset "dgt_lidar mosaic writes file" begin
				outfile = joinpath(tmpdir, "implicit_mosaic.tiff")
				GMT.dgt_lidar(INTEGRATION_BBOX; output_dir=tmpdir, mosaic=outfile, verbose=3)
				@test isfile(outfile)
				@test filesize(outfile) > 0
			end

			# --- dgt_mosaic: resample via gdalwarp ---
			@testset "mosaic gdalwarp" begin
				outfile = joinpath(tmpdir, "mosaic_2m.tiff")
				GMT.dgt_mosaic(INTEGRATION_BBOX; src_dir=tmpdir, outfile=outfile, inc=2.0, verbose=3)
				@test isfile(outfile)
				@test filesize(outfile) > 0
			end

			# --- dgt_mosaic: reproject to geographic (EPSG:4326) ---
			@testset "mosaic proj=geog" begin
				outfile = joinpath(tmpdir, "mosaic_geog.tiff")
				GMT.dgt_mosaic(INTEGRATION_BBOX; src_dir=tmpdir, outfile=outfile, proj="geog", verbose=3)
				@test isfile(outfile)
				@test filesize(outfile) > 0
			end

			# --- dgt_mosaic: reproject to UTM zone 29N (bare EPSG digits) ---
			@testset "mosaic proj=32629" begin
				outfile = joinpath(tmpdir, "mosaic_utm29n.tiff")
				GMT.dgt_mosaic(INTEGRATION_BBOX; src_dir=tmpdir, outfile=outfile, proj="32629", verbose=3)
				@test isfile(outfile)
				@test filesize(outfile) > 0
			end

			# --- latest=false: same area, more files (or same) than latest=true ---
			@testset "latest=false dry run (no error)" begin
				@test_nowarn GMT.dgt_lidar(INTEGRATION_BBOX; dry=true, latest=false, verbose=3)
			end

			# --- re-run: all tiles exist → all skipped (file count unchanged) ---
			@testset "resume (skip existing)" begin
				coll_dir = joinpath(tmpdir, "MDS-2m")
				n_before = length(readdir(coll_dir))
				GMT.dgt_lidar(INTEGRATION_BBOX; output_dir=tmpdir, verbose=3)
				@test length(readdir(coll_dir)) == n_before
			end
		#end
	end
end
