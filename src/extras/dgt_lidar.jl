# Since part of the dgt_lidar() function is based on the code from the dgtcd_downer Python package,
# (https://github.com/qgispt/dgtcd_downer) the license for it is is GPL-2.0 (same as the Py code).
# The dgt_mosaic() is fully original code by Me&Claude, so it's license is MIT (same as GMT.jl)


# Global state for session management. `cookiejar` is the path of the Netscape cookie file
# that curl reads and rewrites on every request (-b/-c), which is what carries the Keycloak
# session across the auth redirects and into the later STAC/download calls.
mutable struct AuthState
	cookiejar::String
	username::String
	password::String
	last_auth_time::Float64
	download_counter::Int
end

const _dgt_auth_state = AuthState("", "", "", 0.0, 0)

struct AuthenticationError <: Exception
	msg::String
end
"""
    dgt_lidar(bbox; user="", password="", save=false, output_dir="", delay=1.0, collection="MDS-2m",
              dry=false, latest=true, mosaic=false, outfile="mosaic.tiff", inc=0, method="cubicspline", verbose=true)
    dgt_lidar(GI::Union{GMTgrid,GMTimage}; ...)
    dgt_lidar(lon, lat; ...)
    dgt_lidar(D::GMTdataset; zoom=0, ...)
    dgt_lidar(lon::Real, lat::Real; neighbors=0, zoom=14, ...)
    dgt_lidar([lon, lat]; neighbors=0, zoom=14, ...)

Download LIDAR tiles from Portugal's national elevation survey via the DGT CDD STAC API.

Authenticates against the DGT (Direção-Geral do Território) Collaborative Data Distribution (CDD)
portal (https://cdd.dgterritorio.gov.pt/) and downloads all tiles intersecting the given bounding box.
Tiles are organized into subdirectories by collection. Downloads are resumable —
existing files are skipped.

### Positional argument — six accepted forms
- `bbox`: A 4-element array or tuple `[min_lon, max_lon, min_lat, max_lat]` in WGS84 degrees.
- `[lon, lat]` (2-element array): Downloads only the tile that contains the given point.
  Use `neighbors` to include surrounding tiles and `zoom` to set the tile-grid size.
- `lon, lat` (two scalars): Same as 2-element array, using separate scalar arguments.
- `GI`: A `GMTgrid` or `GMTimage` with a valid projection. The geographic extent is extracted
  from the grid/image header; non-geographic projections are reprojected to lon/lat automatically.
- `lon, lat`: Two separate vectors or tuples `[min_lon, max_lon]`, `[min_lat, max_lat]`.
- `D`: A `GMTdataset` (e.g. from `geocoder`). The geographic bounding box stored in `D.ds_bbox`
  is used. The optional `zoom` keyword (default `0`) enlarges the query to tile boundaries at the
  specified zoom level via `mosaic(..., mesh=true)`.

### Keyword Args
- `user`: DGT CDD account e-mail. If omitted, read from `~/.dgt`.
- `password`: DGT CDD account password. If omitted, read from `~/.dgt`.
  The `~/.dgt` file format (first line is a comment):
  ```
  # Login data for the DGT LIDAR downloads
  login your@email.pt
  password your_password
  ```
- `save`: If `true`, save `user` and `password` to `~/.dgt` for future use (default: `false`).
- `output_dir`: Root directory for downloaded files (default: `homedir/.gmt/DGT`).
  Prefix with `_` to write inside `homedir/.gmt/DGT/` (e.g. `"_algarve"` → `homedir/.gmt/DGT/algarve`).
- `delay`: Seconds between requests (default: `1.0`). Increase to avoid server throttling.
- `collection`: Collection to download. One of the LIDAR ones — `"LAZ"`, `"MDT-50cm"`, `"MDS-50cm"`,
  `"MDT-2m"`, `"MDS-2m"` — or one of the ORTOS orthophoto ones, `"ORTOS-"` and a survey year:
  `2025`, `2021`, `2018`, `2015`, `2012`, `2010`, `2007`, `2004`, `1995`. Case-insensitive.
  Default `"MDS-2m"`.
- `dry`: If `true`, query the API and print found files but skip all downloads (default: `false`).
- `neighbors`: Number of neighboring DGT tiles to include around a single-point query (default: `0` =
  only the tile containing the point). Can be an integer `N` (N rings of tiles on each side, giving a
  (2N+1)×(2N+1) grid) or a 2-element vector `[Nx, Ny]` for asymmetric east-west/north-south expansion.
  Only used with the 2-element or scalar point forms. The tile size is determined from the actual DGT
  tile boundaries returned by the STAC API, so neighbors always means DGT tiles, not OSM tiles.
- `zoom`: OSM zoom level used only as a fallback when the STAC API cannot determine the central tile's
  bbox (default: `14`). Under normal conditions this parameter has no effect.
- `latest`: If `true` (default), keep only the most recent version of each tile when multiple versions
  exist. DGT names versioned files with a `_v01`, `_v02`, … suffix; the unversioned original is treated
  as version 0. Set to `false` to download every version.
- `compress`: Output format for downloaded tiles. `"tif"` (default) = write compressed GeoTIFF
  (DEFLATE + 512×512 tiling); `"nc"` = write compressed netCDF4 (NC4+DEFLATE); `""` = write as-is
  (uncompressed GeoTIFF). DGT tiles ship uncompressed so `"tif"` and `"nc"` reduce on-disk size
  significantly. Not applied to LAZ files. No effect on dry runs.
- `mosaic`: Output for the mosaic (default: `""` = no mosaic). `"grid"` returns a `GMTgrid` in memory
  (no disk I/O). A path ending in `.tiff`/`.tif` writes a compressed GeoTIFF. A `.nc` extension writes
  a netCDF4 file. Ignored when `dry=true`. (see also the `inc`, `method`, and `proj` kwargs below).
- `inc`: Resample resolution for the mosaic in CRS units (metres). `0` = no resample (default: `0`). Used only when `mosaic != ""`.
- `method`: Resampling algorithm when `inc != 0` (default: `"cubicspline"`). Used only when `mosaic != ""`.
  One of: `near|bilinear|cubic|cubicspline|lanczos|average|rms|mode|min|max|med|q1|q3|sum`.
  See https://gdal.org/en/stable/programs/gdalwarp.html#cmdoption-gdalwarp-r for details.
- `proj`: Reproject the mosaic to a different CRS (default: `""`, no reprojection).
  Accepts any GDAL-recognized CRS: a proj string (`"+proj=utm +zone=29 +datum=WGS84"`), an authority
  string (`"EPSG:32629"`), a bare EPSG number (`"32629"`), or the shorthand `"geog"` for EPSG:4326.
  Forces `gdalwarp` even when `inc=0`.
- `verbose`: Verbosity level (default: `1`). `0` = silent (errors only; dry output always shown);
      `1` = downloaded file names only; `2` = full progress.

### Notes
- Large bounding boxes are auto-subdivided into ~200 km² sub-queries to stay within API limits.
- Session re-authenticates automatically every 25 minutes or every 10 files downloaded.
- Files are streamed directly to disk — no RAM bottleneck on large tiles.
- Uses the `curl` executable (bundled with Windows 10/11, macOS and every Linux) — no extra Julia package needed.

### Credits
- This package is inspired by the `dgtcd_downer` Python package: https://github.com/qgispt/dgtcd_downer
  but highly reworked and extended with substantial help of Claude Code to fit the GMT.jl and API style.

### Example
Save you credentials to `~/.dgt` (optional, but avoids having to pass them every time):
```julia
using GMT

dgt_lidar(rand(4), user="nome@email.pt", password="password", save=true)
```

Download the DSM tiles at 50 cm resolution covering Lisbon area (large download job) and save them
to a custom subdirectory of you home dir.
```julia
using GMT

dgt_lidar([-9.2, -9.1, 38.7, 38.8]; output_dir = "_liboa", collection="MDT-50cm")
```
"""
function dgt_lidar(bbox::Union{Tuple{<:Real}, Array{<:Real}}; user::String="", password::String="", save::Bool=false,
                       output_dir::String="", delay::Real=1.0, collection::String="MDS-2m", dry::Bool=false,
                       mosaic::String="", inc::Real=0, method::String="cubicspline",
                       latest::Bool=true, neighbors=0, zoom::Int=14, compress::String="tif", proj::String="", verbose=true)
	local b::NTuple{4,Float64}
	_nb = 0
	(length(bbox) != 2) && (length(bbox) != 4) &&
		error("bbox must have 2 elements [lon, lat] or 4 elements [min_lon, max_lon, min_lat, max_lat], got $(length(bbox))")
	if length(bbox) == 2
		b   = (Float64(bbox[1]) - 1e-5, Float64(bbox[1]) + 1e-5, Float64(bbox[2]) - 1e-5, Float64(bbox[2]) + 1e-5)
		_nb = neighbors
	else
		b   = (Float64(bbox[1]), Float64(bbox[2]), Float64(bbox[3]), Float64(bbox[4]))
	end
	_dgt_lidar(b, user, password, save, output_dir, Float64(delay), collection, dry, mosaic, Float64(inc),
	           method, latest, Int(verbose), _nb, Int(zoom), compress, proj)
end

"""dgt_lidar(lon, lat; neighbors=0, ...) — scalar point; downloads the tile containing (lon, lat). `neighbors` expands to adjacent DGT tiles."""
function dgt_lidar(lon::Real, lat::Real; user::String="", password::String="", save::Bool=false,
                       output_dir::String="", delay::Real=1.0, collection::String="MDS-2m", dry::Bool=false,
                       mosaic::String="", inc::Real=0, method::String="cubicspline",
                       latest::Bool=true, neighbors=0, compress::String="tif", proj::String="", verbose=true)
	b = (Float64(lon) - 1e-5, Float64(lon) + 1e-5, Float64(lat) - 1e-5, Float64(lat) + 1e-5)
	_dgt_lidar(b, user, password, save, output_dir, Float64(delay), collection, dry, mosaic, Float64(inc),
	           method, latest, Int(verbose), neighbors, 14, compress, proj)
end

"""dgt_lidar(GI; ...) — bbox extracted from a GMTgrid or GMTimage header; non-geographic projections are reprojected."""
function dgt_lidar(GI::GItype; user::String="", password::String="", save::Bool=false,
                       output_dir::String="", delay::Real=1.0, collection::String="MDS-2m", dry::Bool=false,
                       mosaic::String="", inc::Real=0, method::String="cubicspline",
                       latest::Bool=true, compress::String="tif", proj::String="", verbose=true)
	lon, lat = GMT.lonlat_from(GI)
	_dgt_lidar((Float64(lon[1]), Float64(lon[2]), Float64(lat[1]), Float64(lat[2])), user, password, save, output_dir,
	           Float64(delay), collection, dry, mosaic, Float64(inc), method, latest, Int(verbose), 0, 14, compress, proj)
end

"""dgt_lidar(lon, lat; ...) — `lon` and `lat` are separate `[min, max]` vectors or matrices (also accepts PyList from juliacall)."""
function dgt_lidar(lon::AbstractVecOrMat, lat::AbstractVecOrMat; user::String="", password::String="", save::Bool=false,
                       output_dir::String="", delay::Real=1.0, collection::String="MDS-2m", dry::Bool=false,
                       mosaic::String="", inc::Real=0, method::String="cubicspline",
                       latest::Bool=true, compress::String="tif", proj::String="", verbose=true)
	lon, lat = GMT.lonlat_from(lon, lat)
	_dgt_lidar((Float64(lon[1]), Float64(lon[2]), Float64(lat[1]), Float64(lat[2])), user, password, save, output_dir,
	           Float64(delay), collection, dry, mosaic, Float64(inc), method, latest, Int(verbose), 0, 14, compress, proj)
end

"""
dgt_lidar(D::GDtype; zoom=0, ...) — bbox from `D.ds_bbox`. With `zoom > 0` the query is
snapped to tile boundaries at that zoom level (calls `mosaic(..., mesh=true)`).
"""
function dgt_lidar(D::GDtype; user::String="", password::String="", save::Bool=false, zoom::Int=0,
                       output_dir::String="", delay::Real=1.0, collection::String="MDS-2m", dry::Bool=false,
                       mosaic::String="", inc::Real=0, method::String="cubicspline",
                       latest::Bool=true, compress::String="tif", proj::String="", verbose=true, kw...)
	(zoom < 0) && error("Invalid zoom level: $zoom. Must be >= 0.")
	if (zoom == 0)
		lon, lat = GMT.lonlat_from(D; bb=true)
	else
		Dm = GMT.mosaic(D; zoom=zoom, mesh=true, kw...)		# Here kw can contain a 'neighbors' option
		lon, lat = Dm.ds_bbox[1:2], Dm.ds_bbox[3:4]
	end
	get(kw, :neighbors, nothing) !== nothing && @warn("The zoom-based tile snapping in dgt_lidar(D; zoom>0) is designed to work without neighbors expansion. Results may be a bit surprising.")
	_dgt_lidar((Float64(lon[1]), Float64(lon[2]), Float64(lat[1]), Float64(lat[2])), user, password, save, output_dir,
	           Float64(delay), collection, dry, mosaic, Float64(inc), method, latest, Int(verbose), 0, zoom, compress, proj)
end

# --------------------------------------------------------------------------------------------------------------------------
function _pt_overlaps(b::NTuple{4,Float64})
	pt_bbox = (-9.6, -6.1, 36.9, 42.2)			# Portugal bounding box: [min_lon, max_lon, min_lat, max_lat]
	b[1] <= pt_bbox[2] && b[2] >= pt_bbox[1] && b[3] <= pt_bbox[4] && b[4] >= pt_bbox[3]
end

function _validate_pt_bbox(b::NTuple{4,Float64})::NTuple{4,Float64}
	_pt_overlaps(b) && return b
	bs = (b[3], b[4], b[1], b[2])
	_pt_overlaps(bs) && @warn("Coordinates probably given as lat/lon INSTEAD of lon/lat.") && return bs
	error("Coordinates $b do not intersect Portugal (-9.6, -6.1, 36.9, 42.2)")
end

# --------------------------------------------------------------------------------------------------------------------------
function _dgt_lidar(bbox, user::String, password::String, save::Bool, output_dir::String, delay::Float64, collection::String,
                    dry::Bool, mosaic::String, inc::Float64, method::String, latest::Bool, verbose::Int,
                    _neighbors, _zoom::Int, compress::String, proj::String)

	bbox = _validate_pt_bbox(NTuple{4,Float64}(bbox))
	# The LIDAR collections, then the ORTOS (orthophoto) ones — the portal serves both through the
	# very same catalogue, authentication and download endpoint, so the only thing that ever kept
	# them out of here was this list. Names verified against
	# https://cdd.dgterritorio.gov.pt/dgt-be/v1/collections.
	_valid = ("LAZ", "MDT-50cm", "MDS-50cm", "MDT-2m", "MDS-2m",
	          "ORTOS-2025", "ORTOS-2021", "ORTOS-2018", "ORTOS-2015", "ORTOS-2012",
	          "ORTOS-2010", "ORTOS-2007", "ORTOS-2004", "ORTOS-1995")
	_coll = uppercase(collection)		# Because of Core.Boxes
	_canonical = findfirst(c -> uppercase(c) == _coll, _valid)
	_canonical === nothing && error("Invalid collection \"$collection\". Valid: $(join(_valid, ", "))")
	collection = _valid[_canonical]
	do_mosaic = !isempty(mosaic)
	if isempty(user) || isempty(password)
		user, password = _read_dgt_credentials()
	end
	if save
		dgt_file = joinpath(homedir(), ".dgt")
		_usr, _passwd = user, password		# Otherwise they are Core.Boxed(???)
		open(dgt_file, "w") do io
			println(io, "# Login data for the DGT LIDAR downloads")
			println(io, "login $_usr")
			println(io, "password $_passwd")
		end
		verbose == 2 && println("Credentials saved to $dgt_file")
	end
	!_authenticate(string(user), string(password), verbose) && error("Authentication failed.")

	# For point+neighbors queries, expand the epsilon bbox to actual DGT tile boundaries
	_nb_nonzero = isa(_neighbors, Int) ? (_neighbors > 0) : any(_neighbors .> 0)
	if _nb_nonzero
		lon = (bbox[1] + bbox[2]) / 2.0
		lat = (bbox[3] + bbox[4]) / 2.0
		bbox = _point_neighbors_bbox(lon, lat, _neighbors, collection, _zoom)
		verbose == 2 && println("  Point+neighbors bbox: $bbox")
	end

	output_dir = isempty(output_dir) ? joinpath(GMT.GMTuserdir[1], "DGT") :
	             startswith(output_dir, "_") ? joinpath(GMT.GMTuserdir[1], "DGT", output_dir[2:end]) : output_dir

	if (verbose == 2)
		println("\n--- DGT CDD LIDAR Downloader$(dry ? " [DRY RUN]" : "") ---")
		println("Bounding box : $bbox")
		dry || println("Output dir   : $output_dir")
		println("Collections  : $(collection)\n")
	end

	small_bboxes = _divide_bbox(bbox)
	verbose == 2 && println("Bbox divided into $(length(small_bboxes)) sub-queries")

	all_urls = Dict{String,Vector{Tuple{String,String,String}}}()

	for (i, sub_bbox) in enumerate(small_bboxes)
		verbose == 2 && println("Querying sub-bbox $i/$(length(small_bboxes)): $sub_bbox")
		stac_response = _search_stac(sub_bbox; collections=collection, delay=Float64(delay))
		urls = _collect_urls(stac_response)

		for (coll, pairs) in urls
			!haskey(all_urls, coll) && (all_urls[coll] = Tuple{String,String,String}[])
			append!(all_urls[coll], pairs)
		end

		n = isempty(urls) ? 0 : sum(length(v) for v in values(urls))
		verbose == 2 && println("  Found $n items")
	end

	if latest
		n_before = isempty(all_urls) ? 0 : sum(length(v) for v in values(all_urls))
		_filter_latest!(all_urls)
		n_after  = isempty(all_urls) ? 0 : sum(length(v) for v in values(all_urls))
		verbose == 2 && n_before > n_after && println("  Keeping latest versions: $(n_before - n_after) older file(s) excluded")
	end

	total = isempty(all_urls) ? 0 : sum(length(v) for v in values(all_urls))
	add_t = (total == 0) ? "\nNothing else to do. Quiting here\n" : ""
	if (verbose == 2 || total == 0)
		println("\nTotal unique URLs found: $total" * add_t)
	end
	(total == 0) && return nothing

	if dry
		if (verbose <= 2)		# == 3 when run from tests (be silent)
			for (coll, pairs) in all_urls
				println("\nCollection: $coll ($(length(pairs)) files)")
				for (_, item_id, ext) in pairs
					println("  $item_id$ext")
				end
			end
		end
		return nothing
	end

	downloaded = 0
	skipped    = 0
	_dgt_auth_state.download_counter = 0

	for (coll, pairs) in all_urls
		(verbose == 1 || verbose == 2) && println("\nDownloading collection: $coll")
		coll_dir = joinpath(output_dir, coll)
		for (j, (url, item_id, ext)) in enumerate(pairs)
			eff_ext   = (compress == "nc" && ext == ".tiff") ? ".nc" : ext
			file_path = joinpath(coll_dir, "$item_id$eff_ext")
			already   = isfile(file_path)
			(verbose == 1 || verbose == 2) && !already && println("  [$j/$(length(pairs))] $url")
			result = _download_file(url, item_id, ext, coll_dir; delay=delay, verbose=verbose, compress=compress)
			result && (already ? (skipped += 1) : (downloaded += 1))
		end
	end

	(verbose == 1 || verbose == 2) && println("\nDone: $downloaded downloaded, $skipped already downloaded.")
	if do_mosaic
		_tiles = String[]
		for (coll, pairs) in all_urls
			uppercase(coll) == uppercase(collection) || continue
			coll_dir_t = joinpath(output_dir, coll)
			for (_, item_id, ext) in pairs
				eff_ext = (compress == "nc" && ext == ".tiff") ? ".nc" : ext
				fpath = replace(joinpath(coll_dir_t, "$item_id$eff_ext"), '\\' => '/')
				isfile(fpath) && push!(_tiles, fpath)
			end
		end
		result = GMT.dgt_mosaic(bbox; src_dir=output_dir, collection=collection, outfile=mosaic, inc=inc, method=method, proj=proj, verbose=verbose, tiles=_tiles)
		mosaic == "grid" && return result
	end
	return nothing
end

# ------------------------------------------------------------------------------------------
"""
    dgt_mosaic(bbox; src_dir="", collection="MDS-2m", outfile="mosaic.tiff", inc=0, method="cubicspline", vrt="", verbose=true)

Mosaic downloaded DGT LIDAR tiles covering `bbox` into a single GeoTIFF.

Reads all `.tif` files in `src_dir/collection/`, builds an in-memory VRT mosaic,
clips to `bbox`, and writes the result to `outfile`.

### Args
- `bbox`: Bounding box `[min_lon, max_lon, min_lat, max_lat]` in WGS84 degrees.

### Keyword Args
- `src_dir`: Root directory of downloaded tiles (default: `homedir/.gmt/DGT`).
  Prefix with `_` to read from `homedir/.gmt/DGT/` (e.g. `"_algarve"` → `homedir/.gmt/DGT/algarve`).
- `collection`: Collection subdirectory to mosaic (default: `"MDS-2m"`).
- `outfile`: Output path (default: `"mosaic.tiff"`). Format is determined by the extension
  (`.tiff`/`.tif` for compressed GeoTIFF, `.nc` for netCDF4). Use `"grid"` to skip disk I/O
  and return the result as a `GMTgrid` object instead.
- `inc`: If non-zero, resample the mosaic to this resolution (in the raster's CRS units, typically metres)
  via `gdalwarp`. Default `0` (no resample, use `gdaltranslate`).
- `vrt`: If non-empty, save the intermediate VRT mosaic to this file path (default: `""`, in-memory only).
- `method`: Resampling algorithm used when `inc != 0` or `proj != ""` (default: `"cubicspline"`).
  One of: `near|bilinear|cubic|cubicspline|lanczos|average|rms|mode|min|max|med|q1|q3|sum`.
  See https://gdal.org/en/stable/programs/gdalwarp.html#cmdoption-gdalwarp-r for details.
- `proj`: Reproject the mosaic to a different CRS (default: `""`, no reprojection).
  Accepts any GDAL-recognized CRS: a proj string (`"+proj=utm +zone=29 +datum=WGS84"`), an authority
  string (`"EPSG:32629"`), a bare EPSG number (`"32629"`), or the shorthand `"geog"` for EPSG:4326.
  Forces `gdalwarp` even when `inc=0`.

### Example
```julia
using GMT
dgt_mosaic([-9.2, -9.1, 38.7, 38.8]; src_dir="_lisboa")
```
"""
function dgt_mosaic(bbox::Union{NTuple{4, <:Real}, Array{<:Real}}; src_dir::String="", collection::String="MDS-2m",
                        outfile::String="mosaic.tiff", inc::Real=0, method::String="cubicspline", vrt::String="",
                        proj::String="", verbose::Int=1, tiles::Vector{String}=String[])
	_dgt_mosaic((Float64(bbox[1]), Float64(bbox[2]), Float64(bbox[3]), Float64(bbox[4])), src_dir, collection,
	            outfile, Float64(inc), method, vrt, proj, verbose, tiles)
end

function _dgt_mosaic(bbox, src_dir::String, collection::String, outfile::String, inc::Float64,
                     method::String, vrt::String, proj::String, verbose::Int=1, tiles::Vector{String}=String[])

	dgt_root = joinpath(GMT.GMTuserdir[1], "DGT")
	is_named = startswith(src_dir, "_")
	src_dir  = isempty(src_dir) ? dgt_root :
	           is_named ? joinpath(dgt_root, src_dir[2:end]) : src_dir
	coll_dir = replace(abspath(joinpath(src_dir, collection)), '\\' => '/')

	if !isempty(tiles)
		tif_files = tiles
	else
		isdir(coll_dir) || error("Directory not found: $coll_dir. Run dgt_lidar() first.")
		tif_files = [replace(f, '\\' => '/') for f in readdir(coll_dir, join=true) if endswith(lowercase(f), ".tiff")]
		# When using a named (_prefix) src_dir, also include tiles from the root DGT pool (~/.gmt/DGT/<collection>/).
		# This lets a regional mosaic transparently absorb tiles downloaded without a prefix.
		if is_named
			root_coll = replace(abspath(joinpath(dgt_root, collection)), '\\' => '/')
			if isdir(root_coll) && root_coll != coll_dir
				append!(tif_files, [replace(f, '\\' => '/') for f in readdir(root_coll, join=true) if endswith(lowercase(f), ".tiff")])
			end
		end
		isempty(tif_files) && error("No .tiff files in $coll_dir$(is_named ? " or $(joinpath(dgt_root, collection))" : "")")
	end

	verbose == 2 && println("Building VRT from $(length(tif_files)) tiles...")
	vrt_ds = GMT.gdalbuildvrt(tif_files)
	isempty(vrt) || GMT.gdalbuildvrt(tif_files; save=vrt)

	use_mem  = (outfile == "grid")
	ext_lc   = use_mem ? ".tiff" : lowercase(splitext(outfile)[2])
	fmt_opts = ext_lc == ".nc" ? ["-of", "netCDF", "-co", "FORMAT=NC4", "-co", "COMPRESS=DEFLATE", "-co", "ZLEVEL=4"] :
	           use_mem          ? ["-of", "GTiff"] :
	                              ["-of", "GTiff", "-co", "COMPRESS=ZSTD",
	                               "-co", "PREDICTOR=" * _gtiff_predictor(isempty(tif_files) ? "" : tif_files[1]),
	                               "-co", "TILED=YES", "-co", "BLOCKXSIZE=512", "-co", "BLOCKYSIZE=512"]

	# Resolve output CRS: "geog" → EPSG:4326, bare digits → EPSG:<n>, anything else → pass directly
	t_srs = isempty(proj)  ? "" :
	        startswith(proj, "geo") ? "EPSG:4326" :
	        all(isdigit, proj) ? "EPSG:$proj" : proj

	# When tiles are explicitly provided from dgt_lidar, STAC selected exactly the right tiles — no clipping needed.
	# For point queries the bbox is epsilon (lon±1e-5) — also skip clip.
	skip_clip = !isempty(tiles) || ((bbox[2]-bbox[1]) < 0.001 && (bbox[4]-bbox[3]) < 0.001)

	if (inc != 0) || !isempty(t_srs)
		# gdalwarp: -te xmin ymin xmax ymax (bbox[1]=min_lon, bbox[3]=min_lat, bbox[2]=max_lon, bbox[4]=max_lat)
		opts = String[]
		if !skip_clip
			append!(opts, ["-te", string(bbox[1]), string(bbox[3]), string(bbox[2]), string(bbox[4]), "-te_srs", "EPSG:4326"])
		end
		!isempty(t_srs) && append!(opts, ["-t_srs", t_srs])
		inc != 0        && append!(opts, ["-tr", string(inc), string(inc)])
		append!(opts, ["-r", method, fmt_opts..., "-dstnodata","NaN"])
		if use_mem
			vsimem = "/vsimem/dgt_mosaic_$(rand(UInt32)).tiff"
			GMT.gdalwarp(vrt_ds, opts; dest=vsimem)
			G = GMT.gd2gmt(GMT.Gdal.read(vsimem), gridreg=false)
			GMT.Gdal.VSIUnlink(vsimem)
			return G
		end
		GMT.gdalwarp(vrt_ds, opts; dest=outfile)
	else
		# bbox = [min_lon, max_lon, min_lat, max_lat]; -projwin expects: ulx uly lrx lry
		opts = skip_clip ? ["-a_nodata", "NaN", fmt_opts...] :
		       ["-a_nodata", "NaN", "-projwin", string(bbox[1]), string(bbox[4]), string(bbox[2]), string(bbox[3]),
		        "-projwin_srs", "EPSG:4326", fmt_opts...]
		if use_mem
			vsimem = "/vsimem/dgt_mosaic_$(rand(UInt32)).tiff"
			GMT.gdaltranslate(vrt_ds, opts; save=vsimem)
			G = GMT.gd2gmt(GMT.Gdal.read(vsimem), gridreg=false)
			GMT.Gdal.VSIUnlink(vsimem)
			return G
		end
		GMT.gdaltranslate(vrt_ds, opts; save=outfile)
	end
	verbose == 2 && println("Mosaic saved to $outfile")
	return outfile
end

_is_session_expired() = (time() - _dgt_auth_state.last_auth_time) > 25 * 60		# 25 minutes
_is_session_valid(stac_url::String) = _test_session(stac_url)

# ------------------------------------------------------------------------------------------
# Minimal curl wrappers. curl keeps the session cookies itself in a jar file, so no cookie
# parsing/serializing is needed here (that's the whole reason HTTP.jl could be dropped).
const _DGT_UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

function _curl_jar()
	isempty(_dgt_auth_state.cookiejar) && (_dgt_auth_state.cookiejar = tempname() * ".cookies")
	return _dgt_auth_state.cookiejar
end

# Split curl's stdout into (status, body, redirect_url). The trailer is appended by the
# --write-out format "\n%{http_code} %{redirect_url}" that every wrapper below passes.
function _curl_split(out::String)
	i = findlast('\n', out)
	i === nothing && return 0, "", ""
	tail   = strip(out[nextind(out, i):end])
	body   = String(out[1:prevind(out, i)])
	parts  = split(tail, ' '; limit=2)
	status = something(tryparse(Int, parts[1]), 0)
	return status, body, (length(parts) == 2 ? String(strip(parts[2])) : "")
end

function _curl_base(jar::Bool, follow::Bool, timeout::Int, headers::Vector{String})
	args = String["--silent", "--show-error", "--user-agent", _DGT_UA, "--max-time", string(timeout),
	              "--write-out", "\n%{http_code} %{redirect_url}"]
	follow && push!(args, "--location")
	if (jar)
		j = _curl_jar()
		append!(args, ["--cookie", j, "--cookie-jar", j])
	end
	for h in headers
		append!(args, ["-H", h])
	end
	return args
end

# GET. `query` entries are "key=value" pairs that curl percent-encodes and appends to the URL.
function _curl_get(url::String; jar::Bool=true, follow::Bool=true, timeout::Int=30,
                   headers::Vector{String}=String[], query::Vector{String}=String[])
	args = _curl_base(jar, follow, timeout, headers)
	if !isempty(query)
		push!(args, "-G")
		for q in query
			append!(args, ["--data-urlencode", q])
		end
	end
	push!(args, url)
	out = try read(`curl $args`, String) catch; return 0, "", "" end
	return _curl_split(out)
end

function _curl_post_json(url::String, payload::String; jar::Bool=true, follow::Bool=true, timeout::Int=30)
	args = _curl_base(jar, follow, timeout, ["Content-Type: application/json"])
	append!(args, ["--data-binary", payload, url])
	out = try read(`curl $args`, String) catch; return 0, "", "" end
	return _curl_split(out)
end

# POST application/x-www-form-urlencoded — curl encodes each field itself (--data-urlencode).
function _curl_post_form(url::String, fields::Dict{String,String}; jar::Bool=true, follow::Bool=true,
                         timeout::Int=30, headers::Vector{String}=String[])
	args = _curl_base(jar, follow, timeout, headers)
	for (k, v) in fields
		append!(args, ["--data-urlencode", "$k=$v"])
	end
	push!(args, url)
	out = try read(`curl $args`, String) catch; return 0, "", "" end
	return _curl_split(out)
end

# Stream a (possibly large) body straight to disk. --speed-time/--speed-limit aborts a stalled
# transfer instead of capping the total time, so big tiles are not killed mid-download.
function _curl_download(url::String, file_path::String; jar::Bool=false)
	args = String["--silent", "--show-error", "--fail", "--location", "--user-agent", _DGT_UA,
	              "--speed-limit", "1", "--speed-time", "120"]
	if (jar)
		j = _curl_jar()
		append!(args, ["--cookie", j, "--cookie-jar", j])
	end
	append!(args, ["--output", file_path, url])
	run(`curl $args`)
	return nothing
end

# ------------------------------------------------------------------------------------------
function _read_dgt_credentials(dgt_file::String=joinpath(homedir(), ".dgt"))
	isfile(dgt_file) || error("No credentials given and no ~/.dgt file found. Create it with:\n  # Login data for the DGT LIDAR downloads\n  login your@email.pt\n  password your_password")
	user = ""
	password = ""
	for line in eachline(dgt_file)
		line = strip(line)
		startswith(line, "#") && continue
		isempty(line) && continue
		if startswith(line, "login ")
			user = strip(line[7:end])
		elseif startswith(line, "password ")
			password = strip(line[10:end])
		end
	end
	(isempty(user) || isempty(password)) && error("~/.dgt: missing 'login' or 'password' line.")
	return String(user), String(password)		# strip() gives SubStrings; _authenticate wants Strings
end

# ------------------------------------------------------------------------------------------
# Minimal JSON parser for STAC API responses — avoids JSON.jl dependency.
# Tracks when we enter the "features" array (at any nesting depth) so feature
# detection is independent of key ordering inside each feature object and works
# with both direct FeatureCollection responses and wrapped {"status":...,"data":{...}} envelopes.
function _parse_stac_response(json_str::String)
	features = []
	in_string         = false
	escape_next       = false
	depth             = 0
	feature_start     = 0
	feature_depth     = 0
	in_features_array = false
	features_depth    = 0
	last_str          = ""
	str_start         = firstindex(json_str)

	for i in eachindex(json_str)
		c = json_str[i]

		if escape_next
			escape_next = false
			continue
		elseif (c == '\\')
			escape_next = true
			continue
		end
		if c == '"'
			if in_string
				in_string = false
				last_str  = json_str[str_start:prevind(json_str, i)]
			else
				in_string = true
				str_start = nextind(json_str, i)
			end
			continue
		end
		in_string && continue

		if (c == '[')
			# No depth restriction — handles both direct FeatureCollection (depth 1) and
			# wrapped responses {"status":...,"data":{"features":[...]}} (depth 2+)
			if !in_features_array && last_str == "features"
				in_features_array = true
				features_depth    = depth
			end
		elseif (c == ']')
			if in_features_array && depth == features_depth
				in_features_array = false
			end
		elseif (c == '{')
			depth += 1
			if feature_start == 0 && in_features_array && depth == features_depth + 1
				feature_start = i
				feature_depth = depth
			end
		elseif (c == '}')
			if feature_start > 0 && depth == feature_depth
				feature_str   = json_str[feature_start:i]
				feature_start = 0
				feature       = Dict{String,Any}()

				m = match(r"\"collection\"\s*:\s*\"([^\"]+)\"", feature_str)
				m !== nothing && (feature["collection"] = m.captures[1])

				m = match(r"\"id\"\s*:\s*\"([^\"]+)\"", feature_str)
				m !== nothing && (feature["id"] = m.captures[1])

				# The tile's OUTLINE, in WGS84: "geometry":{"type":"Polygon","coordinates":[[[lon,lat],…]]}.
				# Kept as it comes (a vector of [lon,lat] pairs) because it is the tile's true shape, and
				# it is also the only footprint some collections give: an MDS item's own "bbox" field is
				# in projected metres, and a LAZ item's is a 3-D bbox (see below).
				geom_m = match(r"\"geometry\"\s*:\s*\{[^{}]*\"coordinates\"\s*:\s*\[\s*\[(.*?)\]\s*\]\s*\}", feature_str)
				if (geom_m !== nothing)
					pts = NTuple{2,Float64}[]
					for p in eachmatch(r"\[\s*(-?[\d.eE+]+)\s*,\s*(-?[\d.eE+]+)\s*\]", geom_m.captures[1])
						lon = tryparse(Float64, p.captures[1]);  lat = tryparse(Float64, p.captures[2])
						(lon === nothing || lat === nothing) && continue
						(-180 ≤ lon ≤ 180 && -90 ≤ lat ≤ 90) && push!(pts, (lon, lat))
					end
					if !isempty(pts)
						feature["geometry"] = pts
						# ...and the bbox it implies, which is authoritative: derived from the outline in
						# lon/lat, not from whichever "bbox" field happens to be first in the item.
						feature["bbox"] = [minimum(p[1] for p in pts), minimum(p[2] for p in pts),
						                   maximum(p[1] for p in pts), maximum(p[2] for p in pts)]
					end
				end

				# No geometry: fall back to a "bbox" field whose values look like WGS84 (lon ∈ [-180,180],
				# lat ∈ [-90,90]). DGT STAC assets also carry a bbox in projected metres (EPSG:3763) — skip
				# those. A SIX-element bbox is the 3-D form [min_lon,min_lat,min_z,max_lon,max_lat,max_z]
				# (what the LAZ collection returns), so the horizontal corners are 1,2 and 4,5 — taking the
				# first four reads the minimum ELEVATION as the maximum longitude.
				if !haskey(feature, "bbox")
					for bbox_m in eachmatch(r"\"bbox\"\s*:\s*\[([^\]]+)\]", feature_str)
						parts = split(bbox_m.captures[1], ',')
						(length(parts) != 4 && length(parts) != 6) && continue
						idx  = (length(parts) == 6) ? (1, 2, 4, 5) : (1, 2, 3, 4)
						vals = try [parse(Float64, strip(parts[k])) for k in idx] catch; nothing end
						vals === nothing && continue
						if -180 ≤ vals[1] ≤ 180 && -90 ≤ vals[2] ≤ 90 && -180 ≤ vals[3] ≤ 180 && -90 ≤ vals[4] ≤ 90
							feature["bbox"] = vals
							break
						end
					end
				end

				feature["links"] = []
				for link_m in eachmatch(r"\"rel\"\s*:\s*\"([^\"]+)\"[^}]*\"href\"\s*:\s*\"([^\"]+)\"", feature_str)
					push!(feature["links"], Dict("rel" => link_m.captures[1], "href" => link_m.captures[2]))
				end

				feature["assets"] = Dict{String,Any}()
				asset_num = 1
				seen_asset_hrefs = Set{String}()
				# href before type  ([^{}]* prevents crossing object boundaries)
				for asset_m in eachmatch(r"\"href\"\s*:\s*\"(https?://[^\"]+)\"[^{}]*\"type\"\s*:\s*\"([^\"]+)\"", feature_str)
					url = asset_m.captures[1]
					url in seen_asset_hrefs && continue
					push!(seen_asset_hrefs, url)
					feature["assets"]["asset_$asset_num"] = Dict{String,Any}("href" => url, "type" => asset_m.captures[2])
					asset_num += 1
				end
				# type before href
				for asset_m in eachmatch(r"\"type\"\s*:\s*\"([^\"]+)\"[^{}]*\"href\"\s*:\s*\"(https?://[^\"]+)\"", feature_str)
					url = asset_m.captures[2]
					url in seen_asset_hrefs && continue
					push!(seen_asset_hrefs, url)
					feature["assets"]["asset_$asset_num"] = Dict{String,Any}("href" => url, "type" => asset_m.captures[1])
					asset_num += 1
				end

				push!(features, feature)
			end
			depth -= 1
		end
	end

	return Dict("features" => features)
end

#= ------------------------------------------------------------------------------------------
function _dgt_collections()
	if isempty(_dgt_auth_state.cookiejar)
		user, password = _read_dgt_credentials()
		!_authenticate(user, password, 0) && error("Authentication failed.")
	end
	try
		_, body = _curl_get("https://cdd.dgterritorio.gov.pt/dgt-be/v1/collections";
		                    headers=["Content-Type: application/json"], timeout=30)
		println(body)
	catch e
		println("Error: $e")
	end
end
=#

# ------------------------------------------------------------------------------------------
function _test_session(stac_url::String="https://cdd.dgterritorio.gov.pt/dgt-be/v1/search")
	isempty(_dgt_auth_state.cookiejar) && return false
	status, = _curl_post_json(stac_url, "{\"bbox\":[-9.0,38.0,-8.0,39.0],\"limit\":1}"; timeout=15)
	return status == 200
end

# ------------------------------------------------------------------------------------------
function _extract_form_data(html::String)
	m = match(r"<form[^>]*id=['\"]kc-form-login['\"][^>]*action=['\"]([^'\"]+)['\"]", html)
	form_action = m === nothing ? nothing : m.captures[1]
	form_data = Dict{String,String}()
	for m in eachmatch(r"<input[^>]*type=['\"]hidden['\"][^>]*name=['\"]([^'\"]+)['\"][^>]*value=['\"]([^'\"]*)['\"]", html)
		form_data[m.captures[1]] = m.captures[2]
	end
	return form_action, form_data
end

# ------------------------------------------------------------------------------------------
function _authenticate(username::String, password::String, verbose::Int=1)
	auth_base_url = "https://auth.cdd.dgterritorio.gov.pt/realms/dgterritorio/protocol/openid-connect"
	redirect_uri  = "https://cdd.dgterritorio.gov.pt/auth/callback"
	client_id     = "aai-oidc-dgt"
	main_site     = "https://cdd.dgterritorio.gov.pt"

	headers = ["Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
	           "Accept-Language: pt-PT,pt;q=0.9,en;q=0.8",
	           "Connection: keep-alive"]

	try
		verbose == 2 && println("Starting DGT authentication...")
		isfile(_curl_jar()) && rm(_dgt_auth_state.cookiejar; force=true)		# Start from a clean session

		_curl_get(main_site; headers=headers)

		_, html = _curl_get("$auth_base_url/auth"; headers=headers,
		                    query=["client_id=$client_id", "response_type=code",
		                           "redirect_uri=$redirect_uri", "scope=openid profile email"])

		form_action, form_data = _extract_form_data(html)

		if form_action === nothing
			verbose == 2 && println("No login form found, checking if already authenticated...")
			if _test_session()
				verbose == 2 && println("Already authenticated!")
				_dgt_auth_state.username       = username
				_dgt_auth_state.password       = password
				_dgt_auth_state.last_auth_time = time()
				return true
			else
				throw(AuthenticationError("Could not find login form and session test failed."))
			end
		end

		verbose == 2 && println("Submitting credentials...")
		form_data["username"] = username
		form_data["password"] = password

		login_url = String(startswith(form_action, "/") ?
					"https://auth.cdd.dgterritorio.gov.pt$form_action" : form_action)

		_curl_post_form(login_url, form_data;
		                headers=[headers; "Origin: https://auth.cdd.dgterritorio.gov.pt"])

		if _test_session()
			verbose == 2 && println("Authentication successful!")
			_dgt_auth_state.username       = username
			_dgt_auth_state.password       = password
			_dgt_auth_state.last_auth_time = time()
			return true
		else
			throw(AuthenticationError("Authentication failed. Please check credentials."))
		end

	catch e
		isa(e, AuthenticationError) ? println("Authentication error: $(e.msg)") : println("Network error during authentication: $e")
		return false
	end
end

# ------------------------------------------------------------------------------------------
# The GTiff PREDICTOR for `src`'s data type. It is NOT a free choice: 3 is the FLOATING-POINT
# predictor and GDAL refuses to create the file with it for an integer/byte raster — refuses
# SILENTLY, writing no file and throwing nothing — while 2 is the integer (horizontal differencing)
# one. A hard-coded 3 therefore produced no output at all for every byte raster, which is exactly
# what the ORTOS orthophoto tiles are (RGB, Byte). Unreadable source -> 2, which is valid for every
# integer type and merely compresses a float raster a little less well.
function _gtiff_predictor(src::String)::String
	isempty(src) && return "2"
	try
		return occursin("Type=Float", string(GMT.gdalinfo(src))) ? "3" : "2"
	catch
		return "2"
	end
end

# ------------------------------------------------------------------------------------------
function _get_file_extension(mime_type::String)
	mime_to_ext = Dict("image/tiff; application=geotiff" => ".tiff",
	                   "image/tiff"                      => ".tiff",
	                   "application/vnd.laszip"          => ".laz")
	haskey(mime_to_ext, mime_type) && return mime_to_ext[mime_type]
	# A STAC asset's type carries MIME PARAMETERS, and the set of them is not fixed: the ORTOS
	# (orthophoto) collections announce "image/tiff; application=geotiff; profile=cloud-optimized",
	# which an exact-match lookup misses. An unmatched type returns "" and _collect_urls then DROPS
	# the asset, so a search that really found tiles ends in "Nothing else to do" with no error
	# anywhere. The extension is decided by the base type, so match on that.
	base = String(strip(first(split(mime_type, ';'))))
	return get(mime_to_ext, base, "")
end

# ------------------------------------------------------------------------------------------
function _divide_bbox(bbox, max_area_km2::Int=200)
	min_lon, max_lon, min_lat, max_lat = bbox
	deg_to_km = 111.0
	width_km  = (max_lon - min_lon) * deg_to_km * cosd((min_lat + max_lat) / 2)
	height_km = (max_lat - min_lat) * deg_to_km

	width_km * height_km <= max_area_km2 && return [bbox]

	splits_x  = ceil(Int, width_km  / sqrt(max_area_km2))
	splits_y  = ceil(Int, height_km / sqrt(max_area_km2))
	delta_lon = (max_lon - min_lon) / splits_x
	delta_lat = (max_lat - min_lat) / splits_y

	small_bboxes = Vector{Float64}[]
	for i in 0:splits_x-1, j in 0:splits_y-1
		push!(small_bboxes, [min_lon + i * delta_lon, min(min_lon + (i+1) * delta_lon, max_lon),
		                     min_lat + j * delta_lat, min(min_lat + (j+1) * delta_lat, max_lat)])
	end
	return small_bboxes
end

# ------------------------------------------------------------------------------------------
function _search_stac(bbox; collections::String="", delay::Float64=0.2)
	sleep(delay)
	bbox_str = "[$(bbox[1]),$(bbox[3]),$(bbox[2]),$(bbox[4])]"  # STAC expects [min_lon,min_lat,max_lon,max_lat]
	payload  = if isempty(collections)
		"{\"bbox\":$bbox_str,\"limit\":1000}"
	else
		"{\"bbox\":$bbox_str,\"collections\":[\"$collections\"],\"limit\":1000}"
	end

	try
		status, body = _curl_post_json("https://cdd.dgterritorio.gov.pt/dgt-be/v1/search", payload; timeout=30)
		status != 200 && error("HTTP $status")
		return _parse_stac_response(body)
	catch e
		println("STAC API query error: $e")
		return Dict("features" => [])
	end
end

# ------------------------------------------------------------------------------------------
# For point+neighbors queries: find the actual DGT tile bbox from STAC, then expand by N tiles.
# neighbors can be Int (symmetric) or 2-element [Nx, Ny] (asymmetric east-west / north-south).
# Falls back to OSM tile grid (zoom-based) if STAC returns no bbox for the central tile.
function _point_neighbors_bbox(lon::Float64, lat::Float64, neighbors, collection::String, zoom::Int=14)
	tiny = (lon - 1e-5, lon + 1e-5, lat - 1e-5, lat + 1e-5)
	resp = _search_stac(tiny; collections=collection, delay=0.0)
	feats = get(resp, "features", [])
	for item in feats
		bb = get(item, "bbox", nothing)
		(bb === nothing || length(bb) < 4) && continue
		# STAC bbox order: [min_lon, min_lat, max_lon, max_lat]
		tlon1, tlat1, tlon2, tlat2 = Float64(bb[1]), Float64(bb[2]), Float64(bb[3]), Float64(bb[4])
		dlon = tlon2 - tlon1
		dlat = tlat2 - tlat1
		nx = isa(neighbors, AbstractArray) ? Int(neighbors[1]) : Int(neighbors)
		ny = isa(neighbors, AbstractArray) && length(neighbors) > 1 ? Int(neighbors[2]) : nx
		result = (tlon1 - nx*dlon, tlon2 + nx*dlon, tlat1 - ny*dlat, tlat2 + ny*dlat)
		return result
	end
	Dm = GMT.mosaic(lon, lat; zoom=zoom, neighbors=neighbors, mesh=true)
	return (Float64(Dm.ds_bbox[1]), Float64(Dm.ds_bbox[2]), Float64(Dm.ds_bbox[3]), Float64(Dm.ds_bbox[4]))
end

# ------------------------------------------------------------------------------------------
# When latest=true, keep only the highest-version entry for each base filename.
# Versioned files end with _vNN (e.g. _v01, _v02); unversioned files are treated as version 0.
function _filter_latest!(all_urls::Dict{String,Vector{Tuple{String,String,String}}})
	pat = r"_v(\d+)$"i
	for (coll, pairs) in all_urls
		best = Dict{String, Tuple{Int,String,String,String}}()  # base → (ver, url, item_id, ext)
		for (url, item_id, ext) in pairs
			m    = match(pat, item_id)
			base = m === nothing ? item_id : item_id[1:end-length(m.match)]
			ver  = m === nothing ? 0 : parse(Int, m.captures[1])
			if !haskey(best, base) || ver > best[base][1]
				best[base] = (ver, url, item_id, ext)
			end
		end
		all_urls[coll] = Tuple{String,String,String}[(v[2], v[3], v[4]) for v in values(best)]
	end
end

# ------------------------------------------------------------------------------------------
function _collect_urls(stac_response)
	urls_per_collection = Dict{String,Vector{Tuple{String,String,String}}}()
	seen_urls = Set{String}()

	for item in get(stac_response, "features", [])
		collection = string(get(item, "collection", "unknown"))
		item_id    = "unknown"

		for link in get(item, "links", [])
			if get(link, "rel", "") == "self"
				item_id = split(string(get(link, "href", "")), "/")[end]
				break
			end
		end
		item_id == "unknown" && (item_id = string(get(item, "id", "unknown")))

		for asset in values(get(item, "assets", Dict()))
			url = string(get(asset, "href", ""))
			(isempty(url) || url in seen_urls) && continue

			mime_type = string(get(asset, "type", ""))
			ext       = _get_file_extension(mime_type)
			isempty(ext) && continue
			!haskey(urls_per_collection, collection) && (urls_per_collection[collection] = Tuple{String,String,String}[])
			push!(urls_per_collection[collection], (url, item_id, ext))
			push!(seen_urls, url)
		end
	end

	return urls_per_collection
end

#= ------------------------------------------------------------------------------------------
function _validate_downloaded_file(file_path::String, extension::String)
	filesize(file_path) < 1024 && error("Downloaded file too small ($(filesize(file_path)) bytes) — likely an error response")
	open(file_path, "r") do io
		magic = read(io, 4)
		if extension == ".tiff"
			# TIFF: II (little-endian) or MM (big-endian)
			ok = (length(magic) >= 4) && ((magic[1] == 0x49 && magic[2] == 0x49) || (magic[1] == 0x4D && magic[2] == 0x4D))
			ok || error("File is not a valid TIFF (bad magic bytes) — likely a server error response")
		elseif extension == ".laz"
			# LAZ/LAS: magic "LASF"
			ok = (length(magic) >= 4) && magic[1:4] == UInt8[0x4C, 0x41, 0x53, 0x46]
			ok || error("File is not a valid LAZ (bad magic bytes) — likely a server error response")
		end
	end
end

# Rewrite a GeoTIFF in-place with DEFLATE compression + tiling.
# PREDICTOR=3 (horizontal differencing) improves ratio for integer/float data alike.
function _compress_tiff(file_path::String)
	tmp = file_path * ".tmp.tiff"
	try
		GMT.gdaltranslate(file_path, ["-co", "COMPRESS=DEFLATE", "-co", "PREDICTOR=3",
		                              "-co", "TILED=YES", "-co", "BLOCKXSIZE=512", "-co", "BLOCKYSIZE=512"]; save=tmp)
		mv(tmp, file_path; force=true)
	catch e
		isfile(tmp) && rm(tmp; force=true)
		rethrow(e)
	end
end
=#

function _download_file(url::String, item_id::String, extension::String, output_dir::String; delay::Real=5.0, verbose::Int=1, compress::String="tif")
	_dgt_auth_state.download_counter += 1
	if _dgt_auth_state.download_counter % 10 == 0 && (_is_session_expired() || !_is_session_valid("https://cdd.dgterritorio.gov.pt/dgt-be/v1/search"))
		verbose == 2 && println("\n[Re-authenticating...]")
		_authenticate(_dgt_auth_state.username, _dgt_auth_state.password, verbose) || throw(AuthenticationError("Re-authentication failed"))
	end

	eff_ext   = (compress == "nc" && extension == ".tiff") ? ".nc" : extension
	# Tentative filename from STAC item_id — may be replaced by real name from redirect URL
	filename  = isempty(item_id) || item_id == "unknown" ? "$(split(url, '/')[end])$eff_ext" : "$item_id$eff_ext"
	file_path = joinpath(output_dir, filename)

	if isfile(file_path)
		verbose == 2 && println("Skipping $file_path (already exists)")
		return true
	end

	sleep(delay)

	for retry in 1:3
		try
			mkpath(output_dir)

			# Resolve redirect first (server returns 302 to presigned S3/MinIO URL). curl's
			# %{redirect_url} hands back the absolute target without following it.
			status, body, final_url = _curl_get(url; follow=false, timeout=30)

			if status in (301, 302, 303, 307, 308)
				isempty(final_url) && error("Redirect with no Location header")
				# Session expired: DGT redirects to login page instead of a presigned download URL.
				# Presigned URL carries its own auth — no cookies needed.
				contains(final_url, "/login") && (http_login(file_path, final_url); continue)

				# Use GDAL /vsicurl/ to translate remote TIFF in one step (no download-then-recompress).
				if extension == ".tiff" && compress == "tif"
					GMT.gdaltranslate("/vsicurl/" * final_url,
					                  ["-co", "COMPRESS=ZSTD",
					                   "-co", "PREDICTOR=" * _gtiff_predictor("/vsicurl/" * final_url),
					                   "-co", "TILED=YES",
					                   "-co", "BLOCKXSIZE=512", "-co", "BLOCKYSIZE=512"]; save=file_path)
				elseif extension == ".tiff" && compress == "nc"
					GMT.gdaltranslate("/vsicurl/" * final_url,
					                  ["-of", "netCDF", "-co", "FORMAT=NC4", "-co", "COMPRESS=DEFLATE", "-co", "ZLEVEL=4", "-co", "BLOCKSIZE=500,500"]; save=file_path)
				else
					_curl_download(final_url, file_path)
				end
				#_validate_downloaded_file(file_path, eff_ext)		# Should not be necessary but leave it just in case.
			elseif status == 200
				println("Warning: Expected redirect but got 200 OK for $url\n Must uncomment code around line 850 of GMTDGTLidarExt.jl")
				#=
				# No content-type sniff: _validate_downloaded_file's magic-byte check below already
				# rejects an HTML/XML/JSON error page served with a 200.
				if extension == ".tiff" && compress == "nc"
					tmp = replace(file_path, r"\.nc$" => ".tmp.tiff")
					write(tmp, body)
					try
						GMT.gdaltranslate(tmp, ["-of", "netCDF", "-co", "FORMAT=NC4", "-co", "COMPRESS=DEFLATE", "-co", "ZLEVEL=4"]; save=file_path)
					finally
						isfile(tmp) && rm(tmp; force=true)
					end
				else
					write(file_path, body)
					extension == ".tiff" && compress == "tif" && _compress_tiff(file_path)
				end
				_validate_downloaded_file(file_path, eff_ext)
				=#
			else
				error("HTTP $status")
			end
			file_size = filesize(file_path)
			(verbose == 1 || verbose == 2) && println("Downloaded $file_path ($file_size bytes)")
			return true

		catch e
			isfile(file_path) && rm(file_path; force=true)
			if retry < 3
				(verbose == 1 || verbose == 2) && println("Error (attempt $retry/3): $e")
				sleep(0.5)
			else
				(verbose == 1 || verbose == 2) && println("Failed to download $filename: $e")
				return false
			end
		end
	end
	return false
end

# ------------------------------------------------------------------------------------------
# For some reason the login made by this http call works better and following calls from
# gdal in _download_file succeed.
function http_login(file_path, final_url)
	_curl_download(final_url, file_path)
	rm(file_path; force=true)
end

