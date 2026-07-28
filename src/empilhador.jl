# Port of Mirone's empilhador.m -- stack a bunch of 2-D grids/scenes into one 3-D file.
#
# Original copyright (c) 2004-2020 by J. Luis (GNU LGPL v2.1+)
#
# The Matlab original leans on the netCDF/HDF MEXs (hdf_funs, nc_io, gmtmbgrid_m, c_nearneighbor,
# cvlib_mex, grdutils). NONE of them is used here: every file access goes through GDAL (gdalinfo /
# gdalread / gdaltranslate / gdalbuildvrt) and every interpolation through GMT itself.
#
# On the interpolation, for the record: mex/gmtmbgrid_m.c IS GMT's `surface` vendored into a MEX
# (SURFACE_BRIGGS, remove_planar_trend, fill_in_forecast, iterate -- Smith & Wessel 1990 over
# Briggs 1974), and its -C<n> "retain nodes within n cells of data" is `surface -M<n>c`. So calling
# `surface` is the same algorithm, not a lookalike replacement. The other Mirone branch,
# c_nearneighbor -N/-S, is `nearneighbor` with the same options.
#
# What the GUI (InteractiveGMT's Tools > Empilhador) needs is all here: `empilhador` does the work
# and reports progress through the `progress` keyword.

# The bit numbers of the OceanColor l2_flags array. Straight from empilhador.m's `fmap`.
const L2_FLAGBITS = Dict{String,Int}(
	"ATMFAIL"=>1, "LAND"=>2, "HIGLINT"=>4, "HILT"=>5, "HISATZEN"=>6, "STRAYLIGHT"=>9,
	"CLDICE"=>10, "COCCOLITH"=>11, "HISOLZEN"=>13, "LOWLW"=>15, "CHLFAIL"=>16, "NAVWARN"=>17,
	"MAXAERITER"=>20, "CHLWARN"=>22, "ATMWARN"=>23, "NAVFAIL"=>26, "FILTER"=>27,
	"SSTWARN"=>28, "SSTFAIL"=>29)

# The flag list that empilhador.m hardwires when L2config.txt has no MIR_EMPILHADOR_F key.
const L2_DEFAULT_FLAGS = "ATMFAIL,LAND,HIGLINT,HILT,HISATZEN,STRAYLIGHT,CLDICE,COCCOLITH," *
                         "HISOLZEN,LOWLW,CHLFAIL,NAVWARN,MAXAERITER,CHLWARN,ATMWARN,NAVFAIL,FILTER"

"""
    empilhador(listfile::String; kwargs...)
    empilhador(fnames::Vector{String}; kwargs...)

Stack a collection of 2-D grids (or MODIS/VIIRS/SeaWiFS L2 scenes) into a single 3-D file.

### Arguments
- `listfile`: A text file with the list of file names (1, 2 or 3 columns, see below). It may also
  be a wildcard request of the form `"C:/a1/*.L2_LAC_SST4 ? -sst4"`, in which case the list file is
  built on the fly next to the data.
- `fnames`: Alternatively, the vector of file names itself.

### Keywords
- `outfile` | `save`: Name of the output file. When not given (and no `-G` in the list file header)
  the stack is returned in memory as a `GMTgrid` cube (`:netcdf`/`:tiff` only).
- `format`: `:netcdf` (default), `:tiff` (multi-band GeoTIFF), `:vtk`, or `:vrt` (a multi-band VRT
  built with `gdalbuildvrt -resolution lowest -separate`).
- `region`: Sub-region as `(west, east, south, north)`.
- `sds`: Sub-dataset selector, either the number (`3` or `"sds3"`) or the name (`"-sst4"`, `"sst4"`).
- `quality`: SST quality level in [-2 2] (OceanColor `qual_sst`). Values `> quality` are dropped;
  a NEGATIVE value instead turns the array into the 0/1 mask of pixels with `qual >= -quality`.
- `bitflags`: `true` to mask with `l2_flags` instead of `qual_sst`, or a comma-separated list of
  flag names to use in place of the default one. Keys: $(join(sort(collect(keys(L2_FLAGBITS))), ", ")).
- `l2`: `true` to run the "L2 magic" (sensor -> geographic reinterpolation). Implied by `inc`.
- `config`: Path of an L2config.txt to read the -R/-I/-C/-N/-S and flag keys from. `true` means
  the default `~/.gmt/L2config.txt` (created with sane defaults if missing).
- `inc`: Cell size of the L2 reinterpolation (L2config's `-I`).
- `ncells`: `surface`'s mask radius in cells (L2config's `-C`), i.e. only nodes within `ncells`
  cells of a datum survive. `0` disables it.
- `nearneighbor`: `true` to grid the L2 scene with `nearneighbor` instead of `surface`. Can also be
  the `(-N, -S)` pair, e.g. `("2", "0.04")`.
- `despike`: `true` to run `clipMySpikes!` on the MODIS L2 SST every-other-10-rows noise.
- `description`: Goes into the netCDF global attribute `description`.
- `append`: `true` to append the new layers to an existing `outfile`.
- `time_from_name`, `year_in_name`: see the `?`, `?+` and `?Y` list-file markers below.
- `zdim_name`, `z_unit`: name and units of the 3rd (vertical/time) dimension, default `"time"` and
  none. They land on the cube's `v_unit` and on the netCDF `<dim>#units` attribute.
- `progress`: A `f(k, n, name)` callback, called before each file is read. The GUI uses it to walk
  its list box; the default prints nothing.

### List file format
Column 1 is the file name (absolute, relative, or bare if it sits next to the list file).
Column 2 is the "time" of the layer, or one of:
- `?`  extract it from the file name (`YYYYDDDHHMMSS`, `YYYYMMDDHHMMSS-...`, or
  `TERRA_MODIS.20181223T234501.L2.SST.nc`),
- `?+` carry the time that lives inside the file,
- `?Y` compose a decimal year from a year in the name (`A2016_SST...`) plus the internal times,
- `*`  just use the running number.
Column 3, when present, is the sub-dataset: `sdsN` (number) or `-name` (name).

A single header line starting with `#` may carry `-A`, `-B<n>`, `-R<w/e/s/n>`, `-G<outfile>`,
`-D<description>` (or `-D"more than one word"`) and `-F<flagSDS>_<minQuality>`.
Lines `>include <path>` splice another list file in. Lines starting with `@` are Mirone's
"change the CD now" markers and are skipped with a warning (there are no removable media prompts
here).

### Returns
The output file name when one was written, or a `GMTgrid` cube when it was not.

### Example
```julia
empilhador("list.txt", outfile="stack.nc", region=(-25,0,20,45))
```
"""
function empilhador(listfile::String; kwargs...)
	d = KW(kwargs)
	fname = _emp_wildcard_list(listfile)		# 'path/*.nc ? -sst4 [-R..]' -> a real list file
	names, times, sds, opts = _emp_parse_list(fname)
	return _emp_core(names, times, sds, opts, d)
end

function empilhador(fnames::Vector{String}; kwargs...)
	d = KW(kwargs)
	times = [string(k) for k = 1:length(fnames)]
	return _emp_core(fnames, times, fill("", length(fnames)), EmpOpts(), d)
end

# -------------------------------------------------------------------------------------------------
"""Options gathered from the list-file header (`-A -B -R -G -D -F`) and from the keywords."""
Base.@kwdef mutable struct EmpOpts
	do_append::Bool = false
	restart_at::Int = 0
	outname::String = ""
	desc::String = ""
	region::NTuple{4,Float64} = (0.0, 0.0, 0.0, 0.0)
	got_R::Bool = false
	sds_flag::String = ""			# SDS name of a quality array, from -F<name>_<qual>
	min_quality::Int = 0
	year_in_name::Bool = false
	carry_time::Bool = false
end

"""The L2 reinterpolation settings, from L2config.txt and/or the keywords."""
Base.@kwdef mutable struct EmpL2
	active::Bool = false
	inc::Float64 = 0.01				# -I
	ncells::Int = 2					# -C, surface's -M<n>c
	nearneighbor::Bool = false		# -N present in L2config, or the `nearneighbor` keyword
	opt_N::String = "2"
	opt_S::String = "0.04"
	quality::Int = 0				# qual_sst threshold, [-2 2]
	use_quality::Bool = true
	bitflags::Vector{Int} = Int[]	# l2_flags bit numbers; non-empty means mask by them
	despike::Bool = false
	region::NTuple{4,Float64} = (0.0, 0.0, 0.0, 0.0)
	got_R::Bool = false
end

"""What one file (or one of its sub-datasets) turned out to be. The Julia stand-in for Mirone's `att`."""
Base.@kwdef mutable struct EmpAtt
	fname::String = ""
	driver::String = ""
	nx::Int = 0
	ny::Int = 0
	nbands::Int = 0
	sds_name::Vector{String} = String[]		# SUBDATASET_n_NAME= values, '=' already stripped
	sds_desc::Vector{String} = String[]		# the matching SUBDATASET_n_DESC=
	all_sds_name::Vector{String} = String[]	# the ROOT file's list, kept when we descend into an SDS
	all_sds_desc::Vector{String} = String[]
	meta::Vector{String} = String[]			# every "key=value" line of every metadata domain
	hdr::Vector{Float64} = zeros(9)			# [xmin xmax ymin ymax zmin zmax reg xinc yinc]
	meta_hdr::Bool = false					# `hdr` was rebuilt from the metadata and beats what GDAL says
	nodata::Float64 = NaN
	has_nodata::Bool = false				# GDAL DECLARED one, so never overwrite it with a guess
	gdal_scaled::Bool = false				# GDAL already applied a scale/offset when reading
	subds::String = ""						# the short name of the sub-dataset we descended into
	slope::Float64 = 1.0
	intercept::Float64 = 0.0
	base::Float64 = 1.0
	is_modis::Bool = false
	is_linear::Bool = false
	is_log::Bool = false
	needs_georef::Bool = false				# a L2 scene in sensor coordinates
end

# -------------------------------------------------------------------------------------------------
# ------------------------------------ list file handling -----------------------------------------
# -------------------------------------------------------------------------------------------------
"""
    _emp_wildcard_list(strin::String) -> String

Mirone's `check_wildcard_fname`. If `strin` is a plain file name, return it untouched. If it holds
a wildcard (plus optionally the "time" and SDS columns and any of -A -B -D -F -G -R), expand the
wildcard and write an `automatic_list.txt` next to the data, then return ITS name.
"""
function _emp_wildcard_list(strin::String)::String
	(!occursin('*', strin) && !occursin('?', strin)) && return strin	# A normal name. Nothing to do

	# Pull the options out first so the leftovers are only 'pattern [time [sds]]'
	rest = strin
	optstr = String[]
	for tag in ("-A", "-B", "-F", "-G", "-R")
		(m = match(Regex("(?:^|\\s)($tag\\S*)"), rest)) === nothing && continue
		push!(optstr, m.captures[1])
		rest = replace(rest, m.match => " ")
	end
	if ((m = match(r"(?:^|\s)(-D\"[^\"]*\")", rest)) !== nothing) ||
	   ((m = match(r"(?:^|\s)(-D\S*)", rest)) !== nothing)
		push!(optstr, m.captures[1])
		rest = replace(rest, m.match => " ")
	end

	rest = replace(strip(rest), '\\' => '/')
	parts = split(rest, r"\s+")
	pattern = String(parts[1])
	tcol = (length(parts) >= 2) ? String(parts[2]) : ""
	scol = (length(parts) >= 3) ? String(parts[3]) : ""

	flist = _emp_expand_wildcard(pattern)
	isempty(flist) && error("empilhador: the wildcard search '$pattern' returned an empty result.")

	pato = dirname(pattern);	isempty(pato) && (pato = ".")
	fname = joinpath(pato, "automatic_list.txt")
	open(fname, "w") do fid
		isempty(optstr) || println(fid, "# ", join(optstr, ' '))
		for f in flist
			isempty(tcol) ? println(fid, f) :
			isempty(scol) ? println(fid, f, '\t', tcol) : println(fid, f, '\t', tcol, '\t', scol)
		end
	end
	return fname
end

"""
    _emp_expand_wildcard(pattern::String) -> Vector{String}

Expand `"/path/to/*.nc"` into the sorted list of matching names. `*` and `?` only, as in `dir()`.
"""
function _emp_expand_wildcard(pattern::String)::Vector{String}
	pato = dirname(pattern);	isempty(pato) && (pato = ".")
	!isdir(pato) && return String[]
	pat = basename(pattern)
	# Escape everything the shell-style pattern does NOT mean, then translate '*' and '?'
	re = Regex("^" * replace(pat, r"([.\\+^$(){}\[\]|])" => s"\\\1", "*" => ".*", "?" => ".") * "\$")
	flist = String[]
	for f in readdir(pato)
		(occursin(re, f) && isfile(joinpath(pato, f))) && push!(flist, joinpath(pato, f))
	end
	return sort!(flist)
end

"""
    _emp_parse_list(fname) -> (names, times, sds, opts::EmpOpts)

Read a list file: the `#` header line, the `>include` directives and the 1, 2 or 3 columns.
"""
function _emp_parse_list(fname::String)
	isfile(fname) || error("empilhador: list file '$fname' does not exist.")
	lines = readlines(fname)
	isempty(lines) && error("empilhador: the list file is empty.")

	opts = EmpOpts()
	(!isempty(strip(lines[1])) && strip(lines[1])[1] == '#') && _emp_parse_header!(opts, lines[1])
	lines = _emp_expand_includes(lines)
	pato = dirname(fname)

	names, times, sds = String[], String[], String[]
	k = 0
	for ln in lines
		ln = strip(ln)
		(isempty(ln) || ln[1] == '#') && continue
		if (ln[1] == '@')				# Mirone stopped here and asked for another CD/DVD
			@warn "empilhador: skipping the '@' change-media marker: $(ln[2:end])"
			continue
		end
		k += 1
		parts = split(ln, r"\s+", limit=3)
		nm = String(parts[1])
		(dirname(nm) == "" && !isempty(pato)) && (nm = joinpath(pato, nm))

		t, s = string(k), ""
		if (length(parts) >= 2)
			c2 = String(parts[2])
			if (c2[1] == '?')
				get_year = false
				if (length(c2) > 1)
					opts.carry_time = true
					(c2[2] != '+') && (opts.year_in_name = true; get_year = true)
				end
				t = _emp_time_from_name(nm, get_year)
			elseif (c2[1] == '*')
				t = string(k)
			elseif (startswith(lowercase(c2), "sds") || c2[1] == '-')
				s = c2					# Two columns with the SDS in the second one
			else
				t = c2
			end
			(length(parts) >= 3) && (s = String(parts[3]))
		end
		push!(names, nm);	push!(times, t);	push!(sds, s)
	end
	isempty(names) && error("empilhador: the list file had nothing but a bunch of trash.")

	mask = isfile.(names)
	if !all(mask)
		@warn "empilhador: $(count(.!mask)) of the $(length(names)) listed files do not exist. Skipping them."
		names, times, sds = names[mask], times[mask], sds[mask]
	end
	isempty(names) && error("empilhador: none of the listed files exists.")
	return names, times, sds, opts
end

"""Parse the single `#` header line: `-A -B<n> -R<w/e/s/n> -G<out> -D<desc> -F<sds>_<qual>`."""
function _emp_parse_header!(opts::EmpOpts, header::String)
	occursin(r"(?:^|\s)-A", header) && (opts.do_append = true)
	if ((m = match(r"(?:^|\s)-B(\d+)", header)) !== nothing)
		opts.restart_at = parse(Int, m.captures[1])
		opts.do_append = true
		@info "empilhador: -B$(opts.restart_at) is a Matlab-era workaround for a GDAL memory leak. " *
		      "It only turns -A on here; nothing stops and restarts."
	end
	if ((m = match(r"(?:^|\s)-R(\S+)", header)) !== nothing)
		v = tryparse.(Float64, split(m.captures[1], '/'))
		if (length(v) != 4 || any(x -> x === nothing, v))
			@warn "empilhador: the -R string is badly formed. Ignoring it."
		elseif (v[1] >= v[2] || v[3] >= v[4])
			@warn "empilhador: West >= East or South >= North in -R. Ignoring it."
		else
			opts.region = (v[1], v[2], v[3], v[4]);		opts.got_R = true
		end
	end
	((m = match(r"(?:^|\s)-G(\S+)", header)) !== nothing) && (opts.outname = String(m.captures[1]))
	if ((m = match(r"(?:^|\s)-D\"([^\"]+)\"", header)) !== nothing)
		opts.desc = String(m.captures[1])
	elseif ((m = match(r"(?:^|\s)-D(\S+)", header)) !== nothing)
		opts.desc = String(m.captures[1])
	end
	if ((m = match(r"(?:^|\s)-F(\S+)", header)) !== nothing)
		t = String(m.captures[1])
		idx = findlast('_', t)
		q = (idx === nothing) ? nothing : tryparse(Float64, t[idx+1:end])
		if (q === nothing)
			@warn "empilhador: the quality value in -F is wrong or missing. Ignoring the option."
		else
			opts.sds_flag = t[1:idx-1];		opts.min_quality = round(Int, q)
		end
	end
	return nothing
end

"""Splice in the contents of every `>include <file>` line (their own `#` lines are dropped)."""
function _emp_expand_includes(lines::Vector{String})::Vector{String}
	any(l -> startswith(strip(l), '>'), lines) || return lines		# The common case
	out = String[]
	for ln in lines
		s = strip(ln)
		if (startswith(s, ">include") || startswith(s, "> include"))
			inc = String(strip(s[(startswith(s, "> include") ? 10 : 9):end]))
			if isfile(inc)
				for il in readlines(inc)
					(isempty(strip(il)) || strip(il)[1] == '#') && continue
					push!(out, il)
				end
			else
				@warn "empilhador: include file not found: $inc"
			end
		else
			push!(out, ln)
		end
	end
	return out
end

# -------------------------------------------------------------------------------------------------
"""
    _emp_time_from_name(name::String, get_year::Bool=false) -> String

Mirone's `squeeze_time_from_name`. Turn an OceanColor/GHRSST file name into the layer's time:
- `A2012024021000.L2_LAC_SST4`  -> decimal day of year,
- `20100109005439-NODC-...nc`   -> `YYYY.DDDdddd`,
- `TERRA_MODIS.20181223T234501.L2.SST.nc` -> decimal day of year,
- with `get_year`, just the 4-digit year of `A2016_SST...` or `2016_...`.
"""
function _emp_time_from_name(name::String, get_year::Bool=false)::String
	fn = basename(name)
	FNAME, EXT = splitext(fn)
	dots = findall('.', FNAME)
	new_naming = false

	if (!isempty(dots) && length(FNAME) >= 17 && uppercase(FNAME[16:17]) == "L2")
		FNAME = FNAME[1:dots[1]-1]							# S1998001130607.L2_MLAC_OC.x.hdf
	elseif (length(EXT) >= 3 && uppercase(EXT[2:3]) == "L2")
		# A2012024021000.L2_LAC_SST4 -- FNAME is already what we want
	elseif (uppercase(EXT) == ".NC" && length(FNAME) >= 15 && FNAME[15] == '-')
		FNAME = FNAME[1:14]									# 20100109005439-NODC-...
	elseif (length(dots) >= 3 && length(FNAME) >= dots[2]+2 && uppercase(FNAME[dots[2]+1:dots[2]+2]) == "L2")
		FNAME = FNAME[1:dots[2]-1]							# TERRA_MODIS.20181223T234501.L2.SST
		new_naming = true
	elseif get_year
		t = (length(FNAME) >= 5) ? tryparse(Int, FNAME[2:5]) : nothing
		(t === nothing && length(FNAME) >= 4) && (t = tryparse(Int, FNAME[1:4]))
		(t !== nothing) && return string(t)
		@warn "empilhador: cannot fish a year out of '$fn'. Using 0."
		return "0"
	else
		@warn "empilhador: '$fn' is neither a MODIS, a GHRSST nor a year-parseable name. Using 0."
		return "0"
	end

	if (length(FNAME) >= 14 && all(isdigit, FNAME[1:14]))	# YYYYMMDDHHMMSS -> YYYY.DDDdddd
		yr = parse(Int, FNAME[1:4])
		dt = DateTime(yr, parse(Int, FNAME[5:6]), parse(Int, FNAME[7:8]),
		              parse(Int, FNAME[9:10]), parse(Int, FNAME[11:12]), parse(Int, FNAME[13:14]))
		dn = Dates.value(dt - DateTime(yr, 1, 1)) / 86400000.0 + 1.0		# 1-based day of year
		return @sprintf("%d.%03d%04d", yr, floor(Int, dn), round(Int, (dn - floor(dn)) * 10000))
	elseif new_naming										# TERRA_MODIS.20181223T234501
		d1 = dots[1]
		yr = parse(Int, FNAME[d1+1:d1+4])
		dt = DateTime(yr, parse(Int, FNAME[d1+5:d1+6]), parse(Int, FNAME[d1+7:d1+8]),
		              parse(Int, FNAME[d1+10:d1+11]), parse(Int, FNAME[d1+12:d1+13]), 0)
		return @sprintf("%f", Dates.value(dt - DateTime(yr, 1, 1)) / 86400000.0 + 1.0)
	else													# A2012024021000
		dd = parse(Int, FNAME[6:8]);	hh = parse(Int, FNAME[9:10]);	mm = parse(Int, FNAME[11:12])
		return @sprintf("%f", dd + (hh + mm / 60.0) / 24.0)
	end
end

"""Mirone's `compose_date`: a decimal year when the year came from the name, the plain time otherwise."""
function _emp_compose_date(year_in_name::Bool, time_val::Float64, year_str::String)::String
	!year_in_name && return @sprintf("%.18g", time_val)
	year = something(tryparse(Float64, year_str), 0.0)
	yr = round(Int, year)
	isleap = (yr % 4 == 0 && yr % 100 != 0) || (yr % 400 == 0)
	return @sprintf("%.12g", year + time_val / (365 + isleap))
end

# -------------------------------------------------------------------------------------------------
# --------------------------------------- L2config.txt --------------------------------------------
# -------------------------------------------------------------------------------------------------
"""
    l2config_file(create::Bool=false) -> String

Path of the L2config.txt that drives the "L2 magic": `~/.gmt/L2config.txt`, the same home as the
other GMT.jl/iGMT settings (Mirone kept it in `<mirone>/data/`). With `create=true` a default one
is written when it does not exist yet, so the file is always there to be edited.
"""
function l2config_file(create::Bool=false)::String
	fname = joinpath(GMTuserdir[1], "L2config.txt")
	(!create || isfile(fname)) && return fname
	open(fname, "w") do fid
		println(fid, "# Variables used in converting L2 satellite images from sensor to geographical coordinates.")
		println(fid, "# The first key holds the interpolation parameters (-C is the 'surface' mask radius, in cells)")
		println(fid, "# and the second the quality flags. Lines starting with a hash are comments.")
		println(fid, "#")
		println(fid, "MIR_EMPILHADOR -R-25/0/20/45 -I0.02 -C1")
		println(fid, "MIR_EMPILHADOR_F ", L2_DEFAULT_FLAGS, ",SSTWARN,SSTFAIL")
		println(fid, "# Uncomment to despike the MODIS L2 SST noise that shows every other 10 rows")
		println(fid, "#MIR_EMPILHADOR_C AVG")
	end
	return fname
end

"""
    _emp_sniff_config(fname::String, L2::EmpL2)

Mirone's `sniff_in_OPTcontrol`. Fill `L2` from the `MIR_EMPILHADOR*` keys of `fname`:
`-R -I -C -N -S` on the main key, `_F <flaglist>`, `_Q <quality>` and `_C` (despike).
"""
function _emp_sniff_config(fname::String, L2::EmpL2)
	isfile(fname) || (@warn "empilhador: the config file '$fname' does not exist. Ignoring it."; return L2)
	flaglist = ""
	for ln in readlines(fname)
		ln = strip(ln)
		startswith(ln, "MIR_EMPILHADOR") || continue
		p = split(ln, r"\s+", limit=2)
		key  = String(p[1])
		rest = (length(p) > 1) ? String(p[2]) : ""
		if (key == "MIR_EMPILHADOR")
			for t in split(rest, r"\s+")
				(length(t) < 3) && continue
				o, val = t[1:2], String(t[3:end])
				if (o == "-R")
					v = tryparse.(Float64, split(val, '/'))
					if (length(v) == 4 && !any(x -> x === nothing, v))
						L2.region = (v[1], v[2], v[3], v[4]);	L2.got_R = true
					end
				elseif (o == "-I")
					((x = tryparse(Float64, val)) !== nothing) && (L2.inc = x)
				elseif (o == "-C")
					((x = tryparse(Int, val)) !== nothing) && (L2.ncells = x)
				elseif (o == "-N")
					L2.opt_N = val;		L2.nearneighbor = true
				elseif (o == "-S")
					L2.opt_S = val
				end
			end
		elseif (key == "MIR_EMPILHADOR_F")
			flaglist = rest
		elseif (key == "MIR_EMPILHADOR_Q")
			q = tryparse(Float64, rest)
			(q !== nothing && -2 <= q <= 2) && (L2.quality = round(Int, q))
		elseif (key == "MIR_EMPILHADOR_C")
			L2.despike = true				# The single argument, 'AVG', is the only one there ever was
		end
	end
	!isempty(flaglist) && (L2.bitflags = _emp_flagbits(flaglist))
	return L2
end

"""Turn `"ATMFAIL,LAND,..."` into the vector of l2_flags bit numbers."""
function _emp_flagbits(flaglist::AbstractString)::Vector{Int}
	bits = Int[]
	for f in split(flaglist, ',')
		f = strip(f)
		isempty(f) && continue
		b = get(L2_FLAGBITS, uppercase(String(f)), 0)
		(b == 0) ? (@warn "empilhador: unknown l2_flags key '$f'. Ignoring it.") : push!(bits, b)
	end
	return sort!(unique!(bits))
end

# -------------------------------------------------------------------------------------------------
# ------------------------------------- GDAL attributes -------------------------------------------
# -------------------------------------------------------------------------------------------------
"""
    _emp_att(fname::String) -> EmpAtt

Mirone's `get_baseNameAttribs`: everything `gdalinfo` knows about a file (or a sub-dataset),
parsed into an `EmpAtt`. This is what replaces the hdfinfo/nc_funs MEXs.
"""
function _emp_att(fname::String)::EmpAtt
	fname = _emp_vsi(fname)					# read .gz/.zip in place, no temporary copy
	info = gdalinfo(fname)
	(info === nothing) && error("empilhador: GDAL could not read '$fname'")
	att = EmpAtt(fname = fname)

	if ((m = match(r"^Driver:\s*(\S+?)/", info, )) !== nothing)
		att.driver = String(m.captures[1])
	elseif ((m = match(r"Driver:\s*(\S+?)/", info)) !== nothing)
		att.driver = String(m.captures[1])
	end
	if ((m = match(r"Size is (\d+),\s*(\d+)", info)) !== nothing)
		att.nx = parse(Int, m.captures[1]);		att.ny = parse(Int, m.captures[2])
	end
	att.nbands = length(collect(eachmatch(r"^Band \d+ Block=", info, )))
	(att.nbands == 0) && (att.nbands = length(collect(eachmatch(r"\nBand \d+ Block=", info))))

	# ---- Sub-datasets. GDAL prints the NAME/DESC pairs, keep them in two parallel vectors.
	for m in eachmatch(r"SUBDATASET_(\d+)_NAME=([^\n\r]+)", info)
		push!(att.sds_name, String(m.captures[2]))
	end
	for m in eachmatch(r"SUBDATASET_(\d+)_DESC=([^\n\r]+)", info)
		push!(att.sds_desc, String(m.captures[2]))
	end
	# The OceanColor netCDF driver also exposes the coordinate vectors as [1xN] singletons. Kill them.
	if (length(att.sds_desc) == length(att.sds_name))
		keep = [!occursin("[1x", d) for d in att.sds_desc]
		att.sds_name = att.sds_name[keep];		att.sds_desc = att.sds_desc[keep]
	end

	# ---- Metadata: every indented "key=value" line, whatever domain it lives in.
	for ln in split(info, '\n')
		s = strip(ln)
		(isempty(s) || !occursin('=', s) || startswith(s, "SUBDATASET_")) && continue
		startswith(ln, ' ') && push!(att.meta, String(s))
	end

	# ---- Georeferencing. GDAL says Origin/Pixel Size; turn that into a GMT-style header.
	ox, oy, dx, dy = 0.0, 0.0, 1.0, 1.0
	if ((m = match(r"Origin = \(\s*([-\d.eE+]+),\s*([-\d.eE+]+)\)", info)) !== nothing)
		ox = parse(Float64, m.captures[1]);		oy = parse(Float64, m.captures[2])
	end
	if ((m = match(r"Pixel Size = \(\s*([-\d.eE+]+),\s*([-\d.eE+]+)\)", info)) !== nothing)
		dx = parse(Float64, m.captures[1]);		dy = abs(parse(Float64, m.captures[2]))
	end
	# GDAL reports a unit transform when there is no SRS at all -- then coordinates ARE pixels.
	if (ox == 0.0 && oy == 0.0 && dx == 1.0 && dy == 1.0)
		att.hdr = [1.0, Float64(att.nx), 1.0, Float64(att.ny), 0.0, 0.0, 0.0, 1.0, 1.0]
	else
		att.hdr = [ox, ox + att.nx * dx, oy - att.ny * dy, oy, 0.0, 0.0, 0.0, dx, dy]
	end

	if ((m = match(r"NoData Value=([-\d.eE+naN]+)", info)) !== nothing)
		att.nodata = something(tryparse(Float64, m.captures[1]), NaN)
		att.has_nodata = !isnan(att.nodata)
	end
	# When GDAL itself reports a scale/offset it also APPLIES it on read, so we must not do it again.
	if ((m = match(r"Offset:\s*([-\d.eE+]+),\s*Scale:\s*([-\d.eE+]+)", info)) !== nothing)
		off = something(tryparse(Float64, m.captures[1]), 0.0)
		scl = something(tryparse(Float64, m.captures[2]), 1.0)
		att.gdal_scaled = (scl != 1.0 || off != 0.0)
	end
	return att
end

"""Does any metadata item contain `what`? (Mirone tested `~isempty(search_scaleOffset(...))`.)"""
_emp_has(meta::Vector{String}, what::String)::Bool = any(m -> occursin(what, m), meta)

"""
    _emp_meta(meta::Vector{String}, what::String) -> Union{Float64, Vector{Float64}, Nothing}

Mirone's `search_scaleOffset` for the cell-array (metadata) case: find the item whose key contains
`what` and return its value, as a number or, for `{a,b,c}` lists, as a vector.
"""
function _emp_meta(meta::Vector{String}, what::String)
	for item in meta
		occursin(what, item) || continue
		(eq = findfirst('=', item)) === nothing && continue
		v = strip(item[eq+1:end])
		if (startswith(v, '{') && endswith(v, '}'))
			nums = tryparse.(Float64, split(v[2:end-1], ','))
			any(x -> x === nothing, nums) || return Float64[x for x in nums]
			continue
		end
		((x = tryparse(Float64, v)) !== nothing) && return x
	end
	return nothing
end

"""
    _emp_find_sds(att::EmpAtt, name::String) -> Int

Mirone's `find_in_subdatasets`. netCDF puts the array name at the tail of the NAME string, HDF4
only in the middle word of DESC. Returns the 1-based index into `att.all_sds_name`, or 0.
"""
function _emp_find_sds(att::EmpAtt, name::String)::Int
	nms = isempty(att.all_sds_name) ? att.sds_name : att.all_sds_name
	dsc = isempty(att.all_sds_desc) ? att.sds_desc : att.all_sds_desc
	if (!isempty(nms) && occursin("NETCDF", nms[1]))
		for k = 1:length(nms)
			ind = findlast(':', nms[k])
			(ind !== nothing && occursin(name, nms[k][ind+1:end])) && return k
		end
	else
		for k = 1:length(dsc)			# HDF4: "[2030x1354] sst (16-bit integer)" -- the middle word
			w = split(strip(dsc[k]), r"\s+")
			length(w) < 2 && continue
			t = String(w[2])
			occursin(name, t) || continue
			(ind = findlast('/', t)) !== nothing && (t = t[ind+1:end])	# //geophysical_data/sst
			(t == name) && return k
		end
	end
	return 0
end

"""Mirone's `guess_nodataval`: the undeclared no-data of the known HDF4 (MODIS) arrays."""
function _emp_guess_nodata(dsname::String)
	startswith(dsname, "sst")  && return -32767.0
	(dsname == "l3m_data")     && return 65535.0
	(dsname == "chlor_a")      && return -1.0
	startswith(dsname, "nLw_") && return 0.0
	(dsname == "K_490")        && return -5000.0
	(dsname == "tau_869")      && return 0.0
	(dsname == "eps_78")       && return 0.0
	(dsname == "angstrom_531") && return -32767.0
	return nothing
end

"""The short name of a sub-dataset, i.e. `sst` out of `NETCDF:"f.nc"://geophysical_data/sst`."""
function _emp_sds_shortname(sdsname::String)::String
	t = sdsname
	(ind = findlast(':', t)) !== nothing && (t = t[ind+1:end])
	(ind = findlast('/', t)) !== nothing && (t = t[ind+1:end])
	return String(t)
end

"""
    _emp_resolve_sds(att::EmpAtt, sds::String) -> EmpAtt

Mirone's `get_att`: when the file is only a shell of sub-datasets, descend into the requested one
(`"sds3"`/`"3"` by number, `"-sst4"`/`"sst4"` by name) and return ITS attributes, with the root's
sub-dataset list carried along in `all_sds_*` (the L2 code needs it to find longitude/latitude).
"""
function _emp_resolve_sds(att::EmpAtt, sds::String)::EmpAtt
	(att.nbands > 0 || isempty(att.sds_name)) && return att		# Nothing to descend into

	idx = 0
	s = strip(sds)
	if isempty(s)
		if (length(att.sds_name) == 1 || startswith(att.driver, "HDF4"))
			idx = 1			# Mirone: a single SDS is taken as implicitly selected; HDF4 defaults to the 1st
		else
			error("empilhador: '$(att.fname)' has Sub-Datasets but you told me nothing about it. " *
			      "Use the `sds` keyword or a 3rd column in the list file.")
		end
	elseif startswith(lowercase(s), "sds")
		idx = something(tryparse(Int, s[4:end]), 0)
		(idx < 1 || idx > length(att.sds_name)) &&
			error("empilhador: sub-dataset number $(s[4:end]) is not in '$(att.fname)'.")
	elseif ((n = tryparse(Int, s)) !== nothing)
		idx = n
		(idx < 1 || idx > length(att.sds_name)) &&
			error("empilhador: sub-dataset number $n is not in '$(att.fname)'.")
	else
		(s[1] == '-') && (s = s[2:end])
		idx = _emp_find_sds(att, String(s))
		(idx == 0) && error("empilhador: the sub-dataset '$s' does not exist in '$(att.fname)'.")
	end

	full = att.sds_name[idx]
	(ind = findfirst('=', full)) !== nothing && startswith(full, "SUBDATASET_") && (full = full[ind+1:end])
	sub = _emp_att(full)
	sub.all_sds_name = att.sds_name;		sub.all_sds_desc = att.sds_desc
	sub.subds = _emp_sds_shortname(full)
	isempty(sub.meta) && (sub.meta = att.meta)		# HDF4 keeps the useful metadata at the root
	append!(sub.meta, att.meta)
	return sub
end

# -------------------------------------------------------------------------------------------------
# ------------------------------ the product-family header logic ----------------------------------
# -------------------------------------------------------------------------------------------------
"""
    _emp_from_meta!(att::EmpAtt, got_R::Bool, R::NTuple{4,Float64})

Mirone's `getFromMETA`. Work out, from the metadata alone, which product family this is and hence
the scaling equation (`slope`/`intercept`/`base`, linear or logarithmic), the true geographic
header, and the no-data value that these formats so often forget to declare.
"""
function _emp_from_meta!(att::EmpAtt, got_R::Bool, R::NTuple{4,Float64})
	is_HDFEOS = _emp_has(att.meta, "HDFEOSVersion")
	is_ESA    = is_HDFEOS && _emp_has(att.meta, "ENVISAT")
	modis_or_seawifs = (!is_HDFEOS && _emp_has(att.meta, "MODIS")) ||
	                   _emp_has(att.meta, "VIIRS") || _emp_has(att.meta, "SeaWiFS")

	# The new OceanColor files come through the HDF5 driver but want the old HDF4 pathways.
	fake_hdf4 = (att.driver == "HDF5Image" || att.driver == "HDF5")
	isHDF4 = (startswith(att.driver, "HDF4") && !fake_hdf4)

	if (modis_or_seawifs && _emp_has(att.meta, "Level-2") &&
	    (startswith(att.driver, "HDF4") || att.driver == "netCDF" || fake_hdf4))
		# ---- MODIS/VIIRS/SeaWiFS Level 2, in SENSOR coordinates ---------------------------------
		# NASA moved from slope/intercept to the CF scale_factor/add_offset and broke everything.
		what = fake_hdf4 ? "scale_factor" : "slope"
		if ((out = _emp_meta(att.meta, what)) !== nothing && isa(out, Float64))
			att.slope = out
			if (att.slope != 1)
				w2 = fake_hdf4 ? "add_offset" : "intercept"
				((o2 = _emp_meta(att.meta, w2)) !== nothing && isa(o2, Float64)) && (att.intercept = o2)
				att.is_linear = true
			end
		end
		att.hdr[1:4] = [1.0, Float64(att.nx), 1.0, Float64(att.ny)]
		# Mirone hardwired -32767 here and then guessed per array name, because the HDF4 format never
		# declared a no-data -- and it needed a "DIRTY PATCH" further down to undo the guess when it
		# misfired (chlor_a's -1 against a real -32767 fill). The modern netCDF products DO declare
		# _FillValue and GDAL has already NaNified it, so guess ONLY when nothing was declared. That
		# removes the misfire at its source instead of patching it afterwards.
		if !att.has_nodata
			att.nodata = -32767.0		# The format does not declare it. Good for SST.
			if !isempty(att.subds)
				nd = _emp_guess_nodata(att.subds)
				(nd !== nothing) && (att.nodata = nd)
			end
		end
		att.is_modis = true
		att.needs_georef = true			# The whole reason "L2 magic" exists
		return att, false				# -R cannot be honoured before the reinterpolation

	elseif (modis_or_seawifs && isHDF4)
		# ---- MODIS/SeaWiFS Level 3, a plain global grid -----------------------------------------
		x_max = _emp_meta(att.meta, "Easternmost");		x_min = _emp_meta(att.meta, "Westernmost")
		y_max = _emp_meta(att.meta, "Northernmost");	y_min = _emp_meta(att.meta, "Southernmost")
		if all(v -> isa(v, Float64), (x_min, x_max, y_min, y_max))
			dx = (x_max - x_min) / att.nx
			x_min += dx/2;	x_max -= dx/2;	y_min += dx/2;	y_max -= dx/2	# was pixel registered
			att.hdr[1:4] = [x_min, x_max, y_min, y_max]
			att.hdr[8:9] = [dx, dx]
			att.meta_hdr = true
		end
		att.hdr[7] = 0.0
		if _emp_has(att.meta, "linear")
			((v = _emp_meta(att.meta, "Slope"))     isa Float64) && (att.slope = v)
			((v = _emp_meta(att.meta, "Intercept")) isa Float64) && (att.intercept = v)
			att.is_linear = true
		elseif _emp_has(att.meta, "logarithmic")
			((v = _emp_meta(att.meta, "Base"))      isa Float64) && (att.base = v)
			((v = _emp_meta(att.meta, "Slope"))     isa Float64) && (att.slope = v)
			((v = _emp_meta(att.meta, "Intercept")) isa Float64) && (att.intercept = v)
			att.is_log = true
		end
		if !att.has_nodata									# Undeclared, again -- same rule as above
			att.nodata = 65535.0
			((nv = _emp_meta(att.meta, "Fill")) isa Float64) && (att.nodata = nv)
		end
		att.is_modis = true

	elseif (!is_HDFEOS && !modis_or_seawifs && isHDF4)
		# ---- AVHRR PATHFINDER (TEMP -> SST). slope/intercept, sometimes CF-named -----------------
		if ((v = _emp_meta(att.meta, "slope")) isa Float64)
			att.slope = v
			((o = _emp_meta(att.meta, "intercept")) isa Float64) && (att.intercept = o)
		end
		if (att.slope == 1 && (v = _emp_meta(att.meta, "scale_factor")) isa Float64)
			att.slope = v
			((o = _emp_meta(att.meta, "add_off")) isa Float64) && (att.intercept = o)
		end
		att.hdr[7] = 0.0
		att.is_linear = true

	elseif (is_HDFEOS && !is_ESA)
		x_min = _emp_meta(att.meta, "WESTBOUNDINGCOORDINATE");	x_max = _emp_meta(att.meta, "EASTBOUNDINGCOORDINATE")
		y_min = _emp_meta(att.meta, "SOUTHBOUNDINGCOORDINATE");	y_max = _emp_meta(att.meta, "NORTHBOUNDINGCOORDINATE")
		rows  = _emp_meta(att.meta, "DATAROWS");					cols  = _emp_meta(att.meta, "DATACOLUMNS")
		if all(v -> isa(v, Float64), (x_min, x_max, y_min, y_max, rows, cols)) && rows > 0 && cols > 0
			att.hdr[1:4] = [x_min, x_max, y_min, y_max]
			att.hdr[7:9] = [0.0, (x_max - x_min) / cols, (y_max - y_min) / rows]
			att.meta_hdr = true
		end
		att.is_linear = true

	elseif (is_HDFEOS && is_ESA)
		# ---- The 5-degree ESA tiles, whose only reliable spatial info is in the FILE NAME --------
		# ESA uses a grid registration but calls it pixel: the left side aligns with a multiple of 5
		# and the last row/column is missing.
		t = basename(att.fname)
		(ind = findlast('_', t)) !== nothing && (t = t[ind+1:end])
		iH = findfirst('H', t);		iV = findfirst('V', t);		iD = findfirst('.', t)
		if (iH === nothing || iV === nothing || iD === nothing)
			@warn "empilhador: '$(att.fname)' is not a 5-degree tile of the undocumented ESA product. Leaving its header alone."
		else
			x_min = parse(Float64, t[iH+1:iV-1]) * 5 - 180
			y_max = 90 - parse(Float64, t[iV+1:iD-1]) * 5
			dx = 5 / att.nx;	dy = 5 / att.ny
			att.hdr[1:4] = [x_min, x_min + 5 - dx, y_max - 5 + dx, y_max]
			att.hdr[7:9] = [0.0, dx, dy]
			att.meta_hdr = true
		end
	end
	return att, got_R
end

# -------------------------------------------------------------------------------------------------
"""
    _emp_srcwin(att::EmpAtt, W, E, S, N) -> (String, Vector{Float64})

The `-srcwin` that crops `att` to the requested region, and the four limits that window really
lands on. Computed in PIXELS, exactly as Mirone did, because these products are so often not
really georeferenced.
"""
function _emp_srcwin(att::EmpAtt, W::Float64, E::Float64, S::Float64, N::Float64)
	x_min, y_min, dx, dy = att.hdr[1], att.hdr[3], att.hdr[8], att.hdr[9]
	(dx == 0 || dy == 0) && return "", Float64[]
	c1 = round(Int, (W - x_min) / dx);		c2 = round(Int, (E - x_min) / dx)
	r1 = round(Int, (S - y_min) / dy);		r2 = round(Int, (N - y_min) / dy)
	(c1 < 0 || c2 > att.nx) && error("empilhador: the sub-region West/East is outside the grid's limits.")
	(r1 < 0 || r2 > att.ny) && error("empilhador: the sub-region South/North is outside the grid's limits.")
	yoff = att.ny - r2			# Rows count downwards in image space
	lims = [x_min + c1*dx, x_min + c2*dx, y_min + r1*dy, y_min + r2*dy]
	return @sprintf("-srcwin %d %d %d %d", c1, max(yoff, 0), max(c2 - c1, 1), max(r2 - r1, 1)), lims
end

# -------------------------------------------------------------------------------------------------
# ------------------------------------- reading one layer -----------------------------------------
# -------------------------------------------------------------------------------------------------
"""
    _emp_vsi(name::String) -> String

Mirone's `deal_with_compressed`, without the temporary file. It shelled out to `bzip2`/`gunzip`,
wrote the decompressed copy next to the data and deleted it afterwards; GDAL reads straight out of
the archive through its virtual filesystem, so nothing is written and nothing has to be cleaned up.
`.bz2` has no GDAL handler -- say so plainly rather than fail deep inside a read.
"""
function _emp_vsi(name::String)::String
	startswith(name, "/vsi") && return name					# already a virtual path
	ext = lowercase(splitext(name)[2])
	(ext == ".gz" || ext == ".z") && return "/vsigzip/" * name
	(ext == ".zip")              && return "/vsizip/" * name
	(ext == ".bz2") && error("empilhador: GDAL cannot read bzip2 ('$name'). Decompress it first.")
	return name
end

_emp_read(name::String, srcwin::String="") =
	(n = _emp_vsi(name); isempty(srcwin) ? gdaltranslate(n) : gdaltranslate(n, srcwin))

"""
    _emp_raw(name::String, srcwin::String) -> Matrix

Read an array through GDAL. Kept in one place so the sub-dataset, the flags array and the
longitude/latitude arrays all come in the same way.
"""
function _emp_raw(name::String, srcwin::String="")
	G = _emp_read(name, srcwin)
	return isa(G, GMTgrid) ? G.z : G.image
end

"""Take the georeferencing of what GDAL actually handed us -- the truth, when the metadata is silent."""
function _emp_adopt_hdr!(att::EmpAtt, G)
	(isa(G, GMTgrid) || isa(G, GMTimage)) || return att
	(length(G.range) < 4 || length(G.inc) < 2) && return att
	att.hdr[1:4] = G.range[1:4]
	att.hdr[7:9] = [Float64(G.registration), G.inc[1], G.inc[2]]
	return att
end

"""
    _emp_sanitize(Z, att::EmpAtt) -> (Matrix{Float32}, have_nans::Bool)

Mirone's `sanitizeZ`: NaNify the no-data and apply the scaling equation -- but never twice, since
GDAL itself already applies any scale/offset that it managed to see (`att.gdal_scaled`).
"""
function _emp_sanitize(Z, att::EmpAtt)
	Zf = (eltype(Z) === Float32) ? Z : Float32.(Z)
	have_nans = false

	if (!isnan(att.nodata))
		nd = Float32(att.nodata)
		@inbounds for k in eachindex(Zf)
			(Zf[k] == nd) && (Zf[k] = NaN32; have_nans = true)
		end
	else
		have_nans = any(isnan, Zf)
	end

	if (att.is_linear && !att.gdal_scaled && (att.slope != 1 || att.intercept != 0))
		s, i0 = Float32(att.slope), Float32(att.intercept)
		@inbounds for k in eachindex(Zf)  Zf[k] = Zf[k] * s + i0  end
	elseif (att.is_log && !att.gdal_scaled)
		b, s, i0 = att.base, att.slope, att.intercept
		@inbounds for k in eachindex(Zf)  Zf[k] = Float32(b ^ (Float64(Zf[k]) * s + i0))  end
	end
	return Zf, have_nans
end

"""
    _emp_getZ(name, sds, att, L2, opts, srcwin) -> (Matrix{Float32}, EmpAtt, was_empty::Bool)

Mirone's `getZ` + `read_gdal`: read the (sub-)dataset, sanitize it and, when it is a L2 scene in
sensor coordinates, run the whole georeferencing chain.
"""
function _emp_getZ(name::String, sds::String, L2::EmpL2, opts::EmpOpts, W, E, S, N, got_R::Bool)
	root = _emp_att(name)
	att  = _emp_resolve_sds(root, sds)
	att, use_R = _emp_from_meta!(att, got_R, (W, E, S, N))

	srcwin, lims = (use_R && !att.needs_georef) ? _emp_srcwin(att, W, E, S, N) : ("", Float64[])
	target = isempty(att.subds) ? name : att.fname
	G = _emp_read(target, srcwin)
	Z = isa(G, GMTgrid) ? G.z : G.image
	if !att.needs_georef			# The L2 branch gets its header from the reinterpolation, later
		att.meta_hdr ? (!isempty(lims) && (att.hdr[1:4] = lims)) : _emp_adopt_hdr!(att, G)
		att.nx, att.ny = size(Z, 2), size(Z, 1)
	end
	Zf, _ = _emp_sanitize(Z, att)

	# ---- The -F<flagSDS>_<minQuality> of the list-file header (GHRSST netCDF) --------------------
	if (!isempty(opts.sds_flag))
		ind = findlast(':', att.fname)
		if (ind !== nothing)
			fl = att.fname[1:ind] * opts.sds_flag
			try
				F = _emp_raw(fl, srcwin)
				(size(F) == size(Zf)) && (Zf[F .< opts.min_quality] .= NaN32)
			catch err
				@warn "empilhador: could not read the quality array '$fl': $err"
			end
		end
	end

	att.needs_georef || return Zf, att, all(isnan, Zf)
	return _emp_georef_L2(Zf, att, L2)
end

# -------------------------------------------------------------------------------------------------
# -------------------------------- L2: sensor -> geographic ---------------------------------------
# -------------------------------------------------------------------------------------------------
"""
    _emp_georef_L2(Z, att, L2) -> (Matrix{Float32}, EmpAtt, was_empty::Bool)

The "L2 magic". Fish the per-pixel longitude/latitude arrays out of the scene, apply the quality
and/or `l2_flags` masking, optionally despike, then interpolate the scattered pixels onto the
regular geographic grid asked for by `-R`/`-I`.
"""
function _emp_georef_L2(Z::Matrix{Float32}, att::EmpAtt, L2::EmpL2)
	!L2.got_R && error("empilhador: this is a L2 scene in sensor coordinates and needs a region " *
	                   "(-R, the `region` keyword or a L2config.txt) to be reinterpolated onto.")

	lon, lat = _emp_lonlat(att, size(Z))
	(lon === nothing) && error("empilhador: could not find the longitude/latitude arrays of '$(att.fname)'.")

	# ---- masking --------------------------------------------------------------------------------
	if !isempty(L2.bitflags)
		flagsID = _emp_find_sds(att, "l2_flags")
		if (flagsID == 0)
			@warn "empilhador: a l2_flags masking was requested but '$(att.fname)' has no l2_flags array."
		else
			Zf = _emp_raw(_emp_trim_sds(att.all_sds_name[flagsID]))
			if (size(Zf) == size(Z))
				mask = UInt32(0)
				for b in L2.bitflags  mask |= UInt32(1) << (b - 1)  end
				if (att.subds == "l2_flags")	# Asked for the flags themselves: grid the mask, not the data
					@inbounds for k in eachindex(Z)  Z[k] = ((UInt32(Zf[k]) & mask) != 0) ? 1f0 : 0f0  end
				else
					@inbounds for k in eachindex(Z);  ((UInt32(Zf[k]) & mask) != 0) && (Z[k] = NaN32)  end
				end
			end
		end
	elseif L2.use_quality
		qID = _emp_find_sds(att, "qual_sst")
		if (qID != 0)
			qual = _emp_raw(_emp_trim_sds(att.all_sds_name[qID]))
			if (size(qual) == size(Z))
				if (L2.quality < 0)			# Mirone: turn the scene into the 0/1 mask of good pixels
					thr = -L2.quality
					@inbounds for k in eachindex(Z)  Z[k] = (qual[k] >= thr) ? 1f0 : 0f0  end
					Z[:, 1:min(5, size(Z,2))] .= NaN32			# The outer columns are always flagged bad
					Z[:, max(1, size(Z,2)-4):end] .= NaN32
				else
					@inbounds for k in eachindex(Z);  (qual[k] > L2.quality) && (Z[k] = NaN32)  end
				end
			end
		end
	end

	L2.despike && clipMySpikes!(Z)

	# NASA really does write -999 and -32767 into coordinate arrays. Drop those pixels with the data.
	good = trues(length(Z))
	@inbounds for k in eachindex(Z)
		(isnan(Z[k]) || lon[k] == -999 || lat[k] == -999 || lon[k] == -32767 || lat[k] == -32767) && (good[k] = false)
	end

	W, E, S, N = L2.region
	inc = L2.inc
	n_cols = round(Int, (E - W) / inc) + 1
	n_rows = round(Int, (N - S) / inc) + 1

	if !any(good)					# An entirely empty scene. Give back a NaN grid of the right size
		return fill(NaN32, n_rows, n_cols), _emp_setgeo!(att, W, E, S, N, inc, n_rows, n_cols), true
	end

	x = Float64.(lon[good]);	y = Float64.(lat[good]);	z = Float64.(Z[good])
	Zo, was_empty = _emp_smart_grid(x, y, z, L2, W, E, S, N, n_rows, n_cols)
	return Zo, _emp_setgeo!(att, W, E, S, N, inc, n_rows, n_cols), was_empty || all(isnan, Zo)
end

"""Strip the leading `SUBDATASET_n_NAME=` off a sub-dataset string."""
function _emp_trim_sds(s::String)::String
	(startswith(s, "SUBDATASET_") && (ind = findfirst('=', s)) !== nothing) && return String(s[ind+1:end])
	return s
end

"""Stamp the geographic header the L2 scene has just acquired."""
function _emp_setgeo!(att::EmpAtt, W, E, S, N, inc, n_rows, n_cols)
	att.hdr = [W, E, S, N, 0.0, 0.0, 0.0, inc, inc]
	att.nx = n_cols;	att.ny = n_rows
	att.needs_georef = false
	att.nodata = NaN
	return att
end

"""
    _emp_lonlat(att, sz) -> (lon, lat)

The per-pixel coordinates of a L2 scene. When the longitude/latitude arrays are already full size
they are used as they are; when they are the (much smaller) control-point arrays, each row is
Akima-interpolated up to full width using `cntl_pt_cols`, exactly as `empilhador.m` did with its
`akimaspline` MEX -- only here every read is a GDAL read, no hdfread anywhere.
"""
function _emp_lonlat(att::EmpAtt, sz::Tuple{Int,Int})
	lonID = _emp_find_sds(att, "longitude");	latID = _emp_find_sds(att, "latitude")
	(lonID == 0 || latID == 0) && return nothing, nothing
	lon = Float64.(_emp_raw(_emp_trim_sds(att.all_sds_name[lonID])))
	lat = Float64.(_emp_raw(_emp_trim_sds(att.all_sds_name[latID])))
	(size(lon) == sz) && return lon, lat

	cpID = _emp_find_sds(att, "cntl_pt_cols")
	(cpID == 0) && return nothing, nothing
	cols = vec(Float64.(_emp_raw(_emp_trim_sds(att.all_sds_name[cpID]))))
	xi = collect(1.0:sz[2])
	lon_f = Matrix{Float64}(undef, sz);		lat_f = Matrix{Float64}(undef, sz)
	for r = 1:sz[1]
		lon_f[r, :] = _emp_akima(cols, vec(lon[r, :]), xi)
		lat_f[r, :] = _emp_akima(cols, vec(lat[r, :]), xi)
	end
	return lon_f, lat_f
end

"""
    _emp_akima(x, y, xi) -> Vector{Float64}

Akima (1970) sub-spline interpolation -- the algorithm behind Mirone's `akimaspline` MEX and behind
GMT's `sample1d -Fa`. Written out here because it is called once per scene row and going through
GMT that many times would cost more than the interpolation itself.
"""
function _emp_akima(x::Vector{Float64}, y::Vector{Float64}, xi::Vector{Float64})::Vector{Float64}
	n = length(x)
	(n < 3) && return [y[max(1, min(n, searchsortedfirst(x, v)))] for v in xi]

	m = Vector{Float64}(undef, n + 3)			# Slopes, with 2 extrapolated at each end
	@inbounds for i = 1:n-1  m[i+2] = (y[i+1] - y[i]) / (x[i+1] - x[i])  end
	m[2]   = 2m[3]   - m[4]
	m[1]   = 2m[2]   - m[3]
	m[n+2] = 2m[n+1] - m[n]
	m[n+3] = 2m[n+2] - m[n+1]

	t = Vector{Float64}(undef, n)				# The Akima slope at each knot
	@inbounds for i = 1:n
		w1 = abs(m[i+3] - m[i+2]);		w2 = abs(m[i+1] - m[i])
		t[i] = (w1 + w2 == 0) ? (m[i+1] + m[i+2]) / 2 : (w1 * m[i+1] + w2 * m[i+2]) / (w1 + w2)
	end

	out = Vector{Float64}(undef, length(xi))
	@inbounds for k in eachindex(xi)
		v = xi[k]
		i = clamp(searchsortedlast(x, v), 1, n - 1)
		h = x[i+1] - x[i];		d = v - x[i]
		b = (3m[i+2] - 2t[i] - t[i+1]) / h
		c = (t[i] + t[i+1] - 2m[i+2]) / (h * h)
		out[k] = y[i] + t[i] * d + b * d * d + c * d * d * d
	end
	return out
end

"""
    _emp_smart_grid(x, y, z, L2, W, E, S, N, n_rows, n_cols) -> (Matrix{Float32}, was_empty)

Mirone's `smart_grid`. A L2 scene usually covers a small slice of the working region, so interpolate
only over the sub-region the data actually spans and paste the result into the full-size NaN grid.

The interpolation itself is `surface` (Briggs minimum curvature, with `-M<ncells>c` = the `-C` of
gmtmbgrid) or, when asked for, `nearneighbor -N/-S`.
"""
function _emp_smart_grid(x::Vector{Float64}, y::Vector{Float64}, z::Vector{Float64}, L2::EmpL2,
                         W::Float64, E::Float64, S::Float64, N::Float64, n_rows::Int, n_cols::Int)
	inc = L2.inc
	X = collect(range(W, E, length=n_cols))
	Y = collect(range(S, N, length=n_rows))
	x_min, x_max = extrema(x);		y_min, y_max = extrema(y)

	c1 = max(1, something(findfirst(>(x_min), X), 1) - 1)
	c2 = something(findfirst(>(x_max), X), n_cols)
	r1 = max(1, something(findfirst(>(y_min), Y), 1) - 1)
	r2 = something(findfirst(>(y_max), Y), n_rows)

	if (c2 <= 1 || r2 <= 1 || c1 >= n_cols || r1 >= n_rows)		# All data outside the working region
		return fill(NaN32, n_rows, n_cols), true
	end

	full = (c1 <= 3 && c2 >= n_cols - 3 && r1 <= 3 && r2 >= n_rows - 3)
	Rs = full ? @sprintf("%.10f/%.10f/%.10f/%.10f", W, E, S, N) :
	            @sprintf("%.10f/%.10f/%.10f/%.10f", X[c1], X[c2], Y[r1], Y[r2])
	# Everything goes as KEYWORDS, not in a command string: `nearneighbor` has no (cmd, data) method
	# at all, and `surface`'s parser hands an unknown -M to the common-option scanner, which rejects
	# it ("Option -M is not a recognized common option"). -M is surface's `mask`.

	local G
	try
		G = L2.nearneighbor ? nearneighbor([x y z], R=Rs, I=inc, N=L2.opt_N, S=L2.opt_S) :
		    (L2.ncells > 0) ? surface([x y z], R=Rs, I=inc, mask="$(L2.ncells)c") :
		                      surface([x y z], R=Rs, I=inc)
	catch err
		@warn "empilhador: the interpolation failed ($err). Returning an empty layer."
		return fill(NaN32, n_rows, n_cols), true
	end
	(G === nothing || isempty(G.z)) && return fill(NaN32, n_rows, n_cols), true

	full && return Float32.(G.z), all(isnan, G.z)

	Zo = fill(NaN32, n_rows, n_cols)
	nr = min(size(G.z, 1), r2 - r1 + 1);	nc = min(size(G.z, 2), c2 - c1 + 1)
	Zo[r1:r1+nr-1, c1:c1+nc-1] = Float32.(G.z[1:nr, 1:nc])
	return Zo, all(isnan, Zo)
end

# -------------------------------------------------------------------------------------------------
"""
    clipMySpikes!(Z::Matrix{<:AbstractFloat}) -> Z

MODIS L2 SST carries a strong noise that peaks every other 10 rows in sensor coordinates. Replacing
the spiky value by the average of its two neighbours reduces (does not eliminate) the effect.
"""
function clipMySpikes!(Z::Matrix{<:AbstractFloat})
	n_rows = size(Z, 1)
	(n_rows < 17) && return Z
	spikes = 11:10:n_rows-5
	for j = 1:size(Z, 2), i in spikes
		avg = (Z[i+1, j] + Z[i-1, j]) / 2
		isnan(avg) || (Z[i, j] = avg)
	end
	return Z
end

# -------------------------------------------------------------------------------------------------
# ------------------------------------------- the core --------------------------------------------
# -------------------------------------------------------------------------------------------------
function _emp_core(names::Vector{String}, times::Vector{String}, sds::Vector{String},
                   opts::EmpOpts, d::Dict{Symbol,Any})

	outfile = haskey(d, :outfile) ? string(pop!(d, :outfile)) :
	          haskey(d, :save)    ? string(pop!(d, :save))    : opts.outname
	fmt::Symbol = haskey(d, :format) ? Symbol(pop!(d, :format)) : :netcdf
	(fmt in (:netcdf, :nc, :tiff, :tif, :vtk, :vrt)) ||
		error("empilhador: unknown `format` :$fmt. Use :netcdf, :tiff, :vtk or :vrt.")
	(fmt == :nc) && (fmt = :netcdf);	(fmt == :tif) && (fmt = :tiff)

	zdim  = haskey(d, :zdim_name)   ? string(pop!(d, :zdim_name))   : "time"
	zunit = haskey(d, :z_unit)      ? string(pop!(d, :z_unit))      : ""
	desc  = haskey(d, :description) ? string(pop!(d, :description)) : opts.desc
	haskey(d, :append) && (opts.do_append = (pop!(d, :append) == true))
	haskey(d, :year_in_name)   && (opts.year_in_name = (pop!(d, :year_in_name) == true))
	haskey(d, :time_from_name) && (opts.carry_time   = (pop!(d, :time_from_name) == true))
	progress::Function = haskey(d, :progress) ? pop!(d, :progress) : (k, n, nm) -> nothing

	# ---- the region ------------------------------------------------------------------------------
	got_R = opts.got_R
	W, E, S, N = opts.region
	if haskey(d, :region)
		r = pop!(d, :region)
		(isa(r, Tuple) || isa(r, Vector)) && length(r) == 4 || error("empilhador: `region` must be (W, E, S, N).")
		W, E, S, N = Float64.(Tuple(r));	got_R = true
	end

	# ---- the sub-dataset --------------------------------------------------------------------------
	if haskey(d, :sds)
		v = pop!(d, :sds)
		sds = fill(isa(v, Integer) ? "sds$v" : string(v), length(names))
	end

	# ---- the L2 settings: config file first, keywords on top of it --------------------------------
	L2 = EmpL2()
	if haskey(d, :config)
		c = pop!(d, :config)
		_emp_sniff_config(isa(c, AbstractString) ? string(c) : l2config_file(true), L2)
		L2.active = true
	end
	haskey(d, :l2)      && (L2.active  = (pop!(d, :l2) == true))
	haskey(d, :inc)     && (L2.inc     = Float64(pop!(d, :inc)); L2.active = true)
	haskey(d, :ncells)  && (L2.ncells  = Int(pop!(d, :ncells)))
	haskey(d, :despike) && (L2.despike = (pop!(d, :despike) == true))
	if haskey(d, :nearneighbor)
		v = pop!(d, :nearneighbor)
		if (isa(v, Tuple) && length(v) == 2)
			L2.opt_N, L2.opt_S = string(v[1]), string(v[2]);		L2.nearneighbor = true
		else
			L2.nearneighbor = (v == true)
		end
	end
	if haskey(d, :quality)
		q = round(Int, pop!(d, :quality))
		(-2 <= q <= 2) || error("empilhador: `quality` must be in [-2 2], got $q.")
		L2.quality = q;		L2.use_quality = true
	end
	if haskey(d, :bitflags)
		v = pop!(d, :bitflags)
		L2.bitflags = isa(v, AbstractString) ? _emp_flagbits(v) :
		              (v == true) ? _emp_flagbits(L2_DEFAULT_FLAGS) : Int[]
		!isempty(L2.bitflags) && (L2.use_quality = false)	# For SST we don't care about bitflags, and vice-versa
	end
	# The GUI/keyword region always wins over the one in L2config.txt
	if got_R
		L2.region = (W, E, S, N);		L2.got_R = true
	elseif L2.got_R
		W, E, S, N = L2.region;			got_R = true
	end

	!isempty(d) && @warn "empilhador: ignoring the unknown keyword(s) $(collect(keys(d)))"

	# ---- the VRT branch: no reading at all, gdalbuildvrt does everything --------------------------
	if (fmt == :vrt)
		isempty(outfile) && (outfile = joinpath(dirname(names[1]), "stack.vrt"))
		gdalbuildvrt(names, ["-resolution", "lowest", "-separate"], save=outfile)
		return outfile
	end

	# ---- read every layer -------------------------------------------------------------------------
	layers = Matrix{Float32}[]
	tvals  = Float64[]
	lnames = String[]
	empties = String[]
	att1 = EmpAtt()
	n_rows, n_cols = 0, 0

	for k = 1:length(names)
		progress(k, length(names), names[k])
		local Z, att, was_empty
		try
			Z, att, was_empty = _emp_getZ(names[k], sds[k], L2, opts, W, E, S, N, got_R)
		catch err
			@warn "empilhador: error reading '$(names[k])'. Ignoring it.\n  $err"
			push!(empties, names[k])
			continue
		end
		if (n_rows == 0)
			n_rows, n_cols = size(Z, 1), size(Z, 2);	att1 = att
		elseif ((size(Z,1), size(Z,2)) != (n_rows, n_cols))
			@warn "empilhador: '$(names[k])' is $(size(Z,1))x$(size(Z,2)) and the others are " *
			      "$(n_rows)x$(n_cols). Jumping it."
			push!(empties, names[k])
			continue
		end
		was_empty && push!(empties, names[k])

		# A 3-D input contributes all its own layers, and then its internal times rule (Mirone's got_3D)
		if (ndims(Z) == 3)
			its = _emp_meta(att.meta, "NETCDF_DIM_time_VALUES")
			for lay = 1:size(Z, 3)
				push!(layers, Z[:, :, lay])
				push!(tvals, _emp_layer_time(opts, its, lay, times[k], length(tvals) + 1))
				push!(lnames, string(names[k], " [", lay, "]"))
			end
		else
			push!(layers, Z)
			push!(tvals, something(tryparse(Float64, times[k]), Float64(length(tvals) + 1)))
			push!(lnames, names[k])
		end
	end
	isempty(layers) && error("empilhador: not a single layer could be read.")
	!isempty(empties) && @info "empilhador: $(length(empties)) of $(length(names)) files gave no data: " *
	                           join(first(empties, 5), ", ") * (length(empties) > 5 ? ", ..." : "")

	# ---- assemble and write ------------------------------------------------------------------------
	if (fmt == :vtk)
		isempty(outfile) && error("empilhador: the :vtk format needs an `outfile`.")
		_emp_write_vtk(outfile, layers, tvals, att1)
		return outfile
	end

	cube = _emp_build_cube(layers, tvals, lnames, att1, zdim, zunit, desc)

	if (opts.do_append && !isempty(outfile) && isfile(outfile))
		cube = _emp_append_cube(outfile, cube)
	end

	isempty(outfile) && return cube
	if (fmt == :tiff)
		gdalwrite(outfile, cube)
	else
		gdalwrite(cube, outfile, tvals, dim_name=zdim, dim_units=zunit)
	end
	return outfile
end

"""The time of layer `lay` of a 3-D input: the file's own times when we are told to carry them."""
function _emp_layer_time(opts::EmpOpts, its, lay::Int, str_time::String, running::Int)::Float64
	if ((opts.carry_time || opts.year_in_name) && isa(its, Vector{Float64}) && length(its) >= lay)
		return something(tryparse(Float64, _emp_compose_date(opts.year_in_name, its[lay], str_time)), Float64(running))
	end
	return Float64(running)
end

"""Stack the layers into a `GMTgrid` cube carrying the geography of the first one."""
function _emp_build_cube(layers::Vector{Matrix{Float32}}, tvals::Vector{Float64},
                         lnames::Vector{String}, att::EmpAtt, zdim::String, zunit::String, desc::String)
	n_rows, n_cols, nz = size(layers[1], 1), size(layers[1], 2), length(layers)
	Zc = Array{Float32,3}(undef, n_rows, n_cols, nz)
	@inbounds for k = 1:nz  Zc[:, :, k] = layers[k]  end

	x = collect(range(att.hdr[1], att.hdr[2], length=n_cols))
	y = collect(range(att.hdr[3], att.hdr[4], length=n_rows))
	# An all-NaN stack is a legitimate outcome (every scene missed the region, or the masking took
	# everything), so it must not blow up in `extrema`.
	finite = filter(!isnan, Zc)
	zmin, zmax = isempty(finite) ? (NaN, NaN) : extrema(finite)
	cube = GMTgrid(range = [att.hdr[1], att.hdr[2], att.hdr[3], att.hdr[4], zmin, zmax,
	                        minimum(tvals), maximum(tvals)],
	               inc = [att.hdr[8], att.hdr[9]], registration = round(Int, att.hdr[7]),
	               nodata = NaN, x = x, y = y, v = tvals, z = Zc, names = lnames,
	               v_unit = zunit, remark = desc, layout = "BCB", hasnans = 2)
	(att.hdr[1] >= -360 && att.hdr[2] <= 360 && att.hdr[3] >= -90 && att.hdr[4] <= 90) && (cube.geog = 1)
	return cube
end

"""Mirone's `-A`: put the layers already in `fname` in front of the new ones."""
function _emp_append_cube(fname::String, cube::GMTgrid)
	local old
	try
		old = gdalread(fname)		# NOT gmtread: that one gives back band 1 only, and -A would lose layers
	catch err
		@warn "empilhador: -A was asked for but '$fname' could not be read back ($err). Overwriting it."
		return cube
	end
	(size(old, 1) != size(cube, 1) || size(old, 2) != size(cube, 2)) &&
		error("empilhador: cannot append -- '$fname' is $(size(old,1))x$(size(old,2)) and the new " *
		      "layers are $(size(cube,1))x$(size(cube,2)).")
	nold = (ndims(old) == 3) ? size(old, 3) : 1
	Zc = Array{Float32,3}(undef, size(cube, 1), size(cube, 2), nold + size(cube, 3))
	@inbounds for k = 1:nold  Zc[:, :, k] = (ndims(old) == 3) ? old.z[:, :, k] : old.z  end
	@inbounds for k = 1:size(cube, 3)  Zc[:, :, nold+k] = cube.z[:, :, k]  end
	oldv = isempty(old.v) ? collect(1.0:nold) : Float64.(old.v)
	cube.z = Zc
	cube.v = vcat(oldv, cube.v)
	cube.names = vcat(isempty(old.names) ? fill("", nold) : old.names, cube.names)
	cube.range[7:8] = [minimum(cube.v), maximum(cube.v)]
	return cube
end

# -------------------------------------------------------------------------------------------------
"""
    _emp_write_vtk(fname, layers, times, att)

Write the stack as a binary VTK RECTILINEAR_GRID -- Mirone's `write_vtk`, header and all, in one go
instead of layer by layer (there is no MEX leak to dodge here). VTK is big-endian.
"""
function _emp_write_vtk(fname::String, layers::Vector{Matrix{Float32}}, times::Vector{Float64}, att::EmpAtt)
	ny, nx = size(layers[1]);		nz = length(layers)
	open(fname, "w") do fid
		write(fid, "# vtk DataFile Version 2.0\n")
		write(fid, "Converted by GMT.jl empilhador\n")
		write(fid, "BINARY\n")
		write(fid, "DATASET RECTILINEAR_GRID\n")
		write(fid, "DIMENSIONS $nx $ny $nz\n")
		write(fid, "X_COORDINATES $nx float\n")
		write(fid, hton.(Float32.(range(att.hdr[1], att.hdr[2], length=nx))))
		write(fid, "Y_COORDINATES $ny float\n")
		write(fid, hton.(Float32.(range(att.hdr[3], att.hdr[4], length=ny))))
		write(fid, "Z_COORDINATES $nz float\n")
		write(fid, hton.(Float32.(times)))
		write(fid, "POINT_DATA $(nx * ny * nz)\n")
		write(fid, "SCALARS data float 1\n")
		write(fid, "LOOKUP_TABLE default\n")
		for k = 1:nz
			write(fid, hton.(vec(permutedims(layers[k], (2, 1)))))		# VTK wants row-major
		end
	end
	return nothing
end

