# T_XTIDE - Tidal prediction using XTide harmonics
# Converted from MATLAB by J. Luis
# Original: R. Pawlowicz 1/Dec/2001, Version 1.0
# Requires the xtide harmonics file - see https://flaterco.com/xtide/files.html

using Dates, SparseArrays

# ========================================================================================
"""
    XTideHarmonics

Structure holding the per-station harmonic data read from an XTide harmonics file.

### Fields
- `station::Vector{String}`: Station names
- `units::Vector{String}`: Original units per station
- `longitude::Vector{Float64}`: Station longitudes
- `latitude::Vector{Float64}`: Station latitudes
- `timezone::Vector{Float64}`: UTC offset (hours)
- `datum::Vector{Float64}`: Datum level
- `A::SparseMatrixCSC{Float64}`: Amplitudes (nsta x ncon)
- `kappa::SparseMatrixCSC{Float64}`: Phases (nsta x ncon)
"""
struct XTideHarmonics
	station::Vector{String}
	units::Vector{String}
	longitude::Vector{Float64}
	latitude::Vector{Float64}
	timezone::Vector{Float64}
	datum::Vector{Float64}
	A::SparseMatrixCSC{Float64,Int}
	kappa::SparseMatrixCSC{Float64,Int}
end

# ========================================================================================
"""
    XTideConstituents

Structure holding the tidal constituent data (speeds, equilibrium arguments, node factors).

### Fields
- `name::Matrix{Char}`: Constituent names (ncon x 8)
- `speed::Vector{Float64}`: Angular speeds (deg/hour)
- `startyear::Int`: First year of epoch tables
- `equilibarg::Matrix{Float64}`: Equilibrium arguments (ncon x nyears)
- `nodefactor::Matrix{Float64}`: Node factors (ncon x nyears)
"""
struct XTideConstituents
	name::Matrix{Char}
	speed::Vector{Float64}
	startyear::Int
	equilibarg::Matrix{Float64}
	nodefactor::Matrix{Float64}
end

# ========================================================================================
"""
    t_gcdist(lat1, lon1, lat2, lon2) -> (d, hdg)

Compute great circle distance (km) and heading (degrees) between positions.

Assumes -90 <= lat <= 90 and -180 <= lon <= 180. North and East are positive.
Uses law of cosines in spherical coordinates.

### Arguments
- `lat1, lon1`: Reference point(s) latitude/longitude in degrees
- `lat2, lon2`: Target point(s) latitude/longitude in degrees

### Returns
- `d`: Distance in kilometers
- `hdg`: Heading in degrees (0=North, 90=East, etc.)

Code from Richard Dewey.
"""
function t_gcdist(lat1, lon1, lat2, lon2)
	degrad = π / 180

	la1 = lat1 .* degrad
	la2 = lat2 .* degrad
	lo1 = copy(Float64.(lon1 isa Number ? [lon1] : lon1))
	lo2 = copy(Float64.(lon2 isa Number ? [lon2] : lon2))
	lo1[lo1 .> 180] .-= 360
	lo2[lo2 .> 180] .-= 360
	lo1 = -lo1 .* degrad
	lo2 = -lo2 .* degrad

	cosla1 = cos.(la1);  sinla1 = sin.(la1)
	cosla2 = cos.(la2);  sinla2 = sin.(la2)

	dtmp = cos.(lo1 .- lo2)
	dtmp = sinla1 .* sinla2 .+ cosla1 .* cosla2 .* dtmp
	dtmp = clamp.(dtmp, -1.0, 1.0)

	ad = acos.(dtmp)
	d = 111.112 .* (180 / π) .* ad

	# Heading
	hdgcos = (sinla2 .- sinla1 .* cos.(ad)) ./ (sin.(ad) .* cosla1)
	hdgcos = clamp.(hdgcos, -1.0, 1.0)
	hdg = acos.(hdgcos) .* (180 / π)

	test = sin.(lo2 .- lo1)
	hdg[test .> 0] .= 360 .- hdg[test .> 0]

	# Return scalars if inputs were scalar
	d_out = length(d) == 1 ? d[1] : d
	hdg_out = length(hdg) == 1 ? hdg[1] : hdg
	return d_out, hdg_out
end

# ========================================================================================
"""
    convert_units(unt::String, origunits::String) -> (units, convf)

Get conversion factor between tidal units.

### Supported conversions
- meters <-> feet
- m/s <-> knots

### Returns
- `units`: Result unit string
- `convf`: Multiplicative conversion factor
"""
function convert_units(unt::AbstractString, origunits::AbstractString)
	u3 = lowercase(unt[1:min(3, length(unt))])
	o3 = lowercase(origunits[1:min(3, length(strip(origunits)))])

	(u3 == o3 || u3 == "ori") && return strip(origunits), 1.0

	if u3 == "fee"
		o3 == "met" && return "feet", 3.2808399
	elseif u3 == "met"
		o3 == "fee" && return "meters", 0.3048
	elseif u3 == "m/s"
		o3 == "kno" && return "meters/sec", 0.51444444
	elseif u3 == "kno"
		o3 == "m/s" && return "knots", 1.9438445
	end
	return strip(origunits), 1.0
end

# ========================================================================================
"""
    fgetl_nocom(io::IO) -> String

Read the next non-comment line (lines starting with '#' are skipped).
"""
function fgetl_nocom(io::IO)
	while !eof(io)
		l = readline(io)
		(isempty(l) || l[1] != '#') && return l
	end
	return ""
end

# ========================================================================================
"""
    read_xtidefile(fname::String) -> (xtide::XTideConstituents, xharm::XTideHarmonics)

Read an XTide harmonics text file and return constituent and station data.

The harmonics file can be obtained from https://flaterco.com/xtide/files.html

### Arguments
- `fname`: Path to the harmonics text file

### Returns
- `xtide`: Constituent speeds, equilibrium arguments and node factors
- `xharm`: Per-station amplitudes, phases, locations, etc.
"""
function read_xtidefile(fname::String)
	io = open(fname, "r")
	result = read_xtidefile(io)
	close(io)
	return result
end

function read_xtidefile(io::IO)
	l = fgetl_nocom(io)
	ncon = parse(Int, strip(l))

	con_names = Matrix{Char}(undef, ncon, 8)
	fill!(con_names, ' ')
	speed = zeros(ncon)

	for k in 1:ncon
		l = fgetl_nocom(io)
		nm = l[1:min(8, length(l))]
		for (j, c) in enumerate(nm)
			con_names[k, j] = c
		end
		speed[k] = parse(Float64, strip(l[9:end]))
	end

	startyear = parse(Int, strip(fgetl_nocom(io)))
	nyear = parse(Int, strip(fgetl_nocom(io)))

	equilibarg = zeros(ncon, nyear)
	for k in 1:ncon
		readline(io)		# constituent name header line
		vals = Float64[]
		while length(vals) < nyear
			parts = split(strip(readline(io)))
			append!(vals, parse.(Float64, parts))
		end
		equilibarg[k, :] = vals[1:nyear]
	end
	readline(io)		# *END*

	nyear2 = parse(Int, strip(fgetl_nocom(io)))

	nodefactor = zeros(ncon, nyear2)
	for k in 1:ncon
		readline(io)		# constituent name header line
		vals = Float64[]
		while length(vals) < nyear2
			parts = split(strip(readline(io)))
			append!(vals, parse.(Float64, parts))
		end
		nodefactor[k, :] = vals[1:nyear2]
	end
	l = readline(io)		# *END*

	# Read station data
	stations = String[]
	units_vec = String[]
	longitudes = Float64[]
	latitudes = Float64[]
	timezones = Float64[]
	datums = Float64[]
	A_rows = Vector{Float64}[]
	K_rows = Vector{Float64}[]

	nh = 0
	while !eof(io)
		l = readline(io)
		isempty(strip(l)) && continue

		# Skip until we find a "# !" line
		while !eof(io) && (length(l) < 3 || l[1:3] != "# !")
			l = readline(io)
		end
		eof(io) && break

		# Parse metadata lines starting with "# !"
		unit = ""
		lon = NaN
		lat = NaN
		while length(l) >= 3 && l[1:3] == "# !"
			tag = length(l) >= 7 ? l[4:7] : ""
			colon = findfirst(':', l)
			if colon !== nothing
				val_str = strip(l[colon+1:end])
				if tag == "unit"
					unit = val_str
				elseif tag == "long"
					lon = parse(Float64, val_str)
				elseif tag == "lati"
					lat = parse(Float64, val_str)
				end
			end
			l = readline(io)
		end

		# Station name line
		sta_name = strip(l)
		isempty(sta_name) && continue
		sta_name[1] == '#' && continue		# Commented out station

		nh += 1

		# Timezone line
		tz_line = readline(io)
		colon_pos = findfirst(':', tz_line)
		if colon_pos !== nothing
			hrs = parse(Float64, strip(tz_line[1:colon_pos-1]))
			mins = parse(Float64, strip(tz_line[colon_pos+1:min(colon_pos+2, length(tz_line))]))
			tz = hrs + mins / 60
		else
			tz = parse(Float64, strip(tz_line))
		end

		# Datum line
		datum = parse(Float64, strip(readline(io)))

		# Constituent amplitudes and phases
		a_row = zeros(ncon)
		k_row = zeros(ncon)
		for k in 1:ncon
			cl = readline(io)
			if !isempty(cl) && cl[1] != 'x'
				parts = split(strip(cl))
				# Find the numeric parts (skip constituent name)
				nums = Float64[]
				for p in parts
					v = tryparse(Float64, p)
					v !== nothing && push!(nums, v)
				end
				if length(nums) >= 2
					a_row[k] = nums[end-1]
					k_row[k] = nums[end]
				end
			end
		end

		push!(stations, sta_name)
		push!(units_vec, unit)
		push!(longitudes, lon)
		push!(latitudes, lat)
		push!(timezones, tz)
		push!(datums, datum)
		push!(A_rows, a_row)
		push!(K_rows, k_row)

		rem(nh, 50) == 0 && print(".")
	end
	println()

	nsta = length(stations)
	A_dense = zeros(nsta, ncon)
	K_dense = zeros(nsta, ncon)
	for i in 1:nsta
		A_dense[i, :] = A_rows[i]
		K_dense[i, :] = K_rows[i]
	end

	xtide = XTideConstituents(con_names, speed, startyear, equilibarg, nodefactor)
	xharm = XTideHarmonics(stations, units_vec, longitudes, latitudes, timezones, datums,
	                        sparse(A_dense), sparse(K_dense))
	return xtide, xharm
end

# ========================================================================================
# Fixed-width, space-padded UInt16 char row (MATLAB char array, one row per record) -> String.
_mat_charrow(row) = String(strip(String(Char.(row))))

# One MATLAB v7.3 (HDF5) sparse double matrix, stored under `HDF5:"fname"://group` as three
# sibling datasets (`ir` = 0-based row indices, `jc` = CSC column pointers, `data` = nonzero
# values). MATLAB serializes sparse matrices column-sorted already, so this maps straight onto
# `SparseMatrixCSC`'s own (1-based) `colptr`/`rowval`/`nzval` layout with no re-sort needed.
function _mat_sparse(fname::String, group::String, nrows::Int, ncols::Int)
	ir  = vec(gdalread("HDF5:\"$fname\"://$group/ir"))
	jc  = vec(gdalread("HDF5:\"$fname\"://$group/jc"))
	dat = vec(gdalread("HDF5:\"$fname\"://$group/data"))
	return SparseMatrixCSC(nrows, ncols, Int.(jc) .+ 1, Int.(ir) .+ 1, Float64.(dat))
end

# ========================================================================================
"""
    read_xtidemat(fname::String) -> (xtide::XTideConstituents, xharm::XTideHarmonics)

Read an XTide harmonics database straight out of a MATLAB v7.3 (HDF5) `.mat` file (e.g.
Mirone's `xtide.mat`) -- the binary twin of `read_xtidefile`'s ASCII harmonics-file reader,
same two return structs. Uses `gdalread` on GDAL's HDF5 driver subdataset paths
(`HDF5:"fname"://xharm/<field>`, `HDF5:"fname"://xtide/<field>`) -- no HDF5.jl dependency.

The MATLAB struct arrays carry unused slots (blank station name, 0/0 lon-lat) interleaved with
real stations; callers that need a clean station list should filter those out (blank name, or
lon==lat==0.0) same as InteractiveGMT's Geography > Tide Stations does.
"""
function read_xtidemat(fname::String)
	lon = vec(gdalread("HDF5:\"$fname\"://xharm/longitude"))
	lat = vec(gdalread("HDF5:\"$fname\"://xharm/latitude"))
	tz  = vec(gdalread("HDF5:\"$fname\"://xharm/timezone"))
	dtm = vec(gdalread("HDF5:\"$fname\"://xharm/datum"))
	statc = gdalread("HDF5:\"$fname\"://xharm/station")	# (nsta, 79) UInt16, space-padded
	unitc = gdalread("HDF5:\"$fname\"://xharm/units")	# (nsta, 8)  UInt16, space-padded
	nsta = length(lon)
	station = [_mat_charrow(view(statc, k, :)) for k in 1:nsta]
	units   = [_mat_charrow(view(unitc, k, :)) for k in 1:nsta]

	speed      = vec(gdalread("HDF5:\"$fname\"://xtide/speed"))
	startyear  = Int(gdalread("HDF5:\"$fname\"://xtide/startyear")[1])
	equilibarg = gdalread("HDF5:\"$fname\"://xtide/equilibarg")	# (ncon, nyear)
	nodefactor = gdalread("HDF5:\"$fname\"://xtide/nodefactor")
	namec      = gdalread("HDF5:\"$fname\"://xtide/name")		# (ncon, 8) UInt16
	ncon = length(speed)
	con_names = Matrix{Char}(undef, ncon, 8)
	fill!(con_names, ' ')
	for k in 1:ncon
		nm = _mat_charrow(view(namec, k, :))
		for (j, c) in enumerate(nm); j <= 8 && (con_names[k, j] = c); end
	end

	A     = _mat_sparse(fname, "xharm/A", nsta, ncon)
	kappa = _mat_sparse(fname, "xharm/kappa", nsta, ncon)

	xtide = XTideConstituents(con_names, speed, startyear, equilibarg, nodefactor)
	xharm = XTideHarmonics(station, units, lon, lat, tz, dtm, A, kappa)
	return xtide, xharm
end

# ========================================================================================
"""
    xtide_predict(xtide, xharm, ista::Int, tim; units="original") -> Vector{Float64}

Predict tidal elevation/current time series at station index `ista`.

### Arguments
- `xtide::XTideConstituents`: Constituent data (from `read_xtidefile`)
- `xharm::XTideHarmonics`: Station harmonic data (from `read_xtidefile`)
- `ista::Int`: Station index
- `tim`: Time vector, ALWAYS in UTC/GMT -- Julia `DateTime` values, or MATLAB-style serial day
  numbers (Float64 vector; also UTC).

### Keywords
- `units`: Output units: "original" (default), "meters", "feet", "m/s", "knots"

### Returns
- `pred`: Predicted tidal values, one per UTC instant in `tim`

### Timezone

The harmonic constants (`kappa`) in an XTide database are referenced to the STATION's own local
standard time (`xharm.timezone[ista]`, hours; local = UTC + timezone), not to Greenwich -- the
opposite of the international/Admiralty "kappa-prime" convention, but standard for the NOS-style
harmonics files this format descends from. Feeding UTC straight into the harmonic sum without
correction reproduces the right CURVE SHAPE but the wrong CLOCK: every event lands `timezone`
hours off (verified empirically against NOAA CO-OPS: Boston, tz=-5, predicted highs/lows landed
exactly 5h early). Fixed by shifting the query instants into the station's local-standard-time
frame before evaluating the harmonic sum -- the input/output contract (`tim` in, `pred` out) stays
UTC; only the internal phase reference moves.
"""
function xtide_predict(xtide::XTideConstituents, xharm::XTideHarmonics, ista::Int, tim;
                       units::AbstractString="original")

	# Convert DateTime to MATLAB serial day numbers if needed
	if eltype(tim) <: DateTime
		# MATLAB datenum: days since 0000-Jan-0 (datenum(0,1,1) = 1)
		# Julia DateTime(0,1,1) is year 0, month 1, day 1
		epoch0 = DateTime(0, 1, 1)
		sdays = [Dates.value(t - epoch0) / 86400000.0 + 1.0 for t in tim]
	else
		sdays = Float64.(tim)
	end

	_, convf = convert_units(units, xharm.units[ista])
	lt = length(sdays)

	# UTC -> station local standard time (kappa's own reference frame, see docstring "Timezone").
	sdays_local = sdays .+ xharm.timezone[ista] / 24.0

	# Year index into epoch tables
	mid = mean_datetime(sdays_local)
	mid_yr = year_from_serialday(mid)
	iyr = mid_yr - xtide.startyear + 1
	(iyr < 1 || iyr > size(xtide.equilibarg, 2)) &&
		error("Year $mid_yr outside epoch table range ($(xtide.startyear) - $(xtide.startyear + size(xtide.equilibarg,2) - 1))")

	# Hours since beginning of year (station local standard time)
	jan1 = serialday_from_ymd(mid_yr, 1, 1)
	xtim = (sdays_local .- jan1) .* 24.0

	# Core prediction: datum + sum of harmonics with node factors
	ncon = length(xtide.speed)
	nf  = xtide.nodefactor[:, iyr]
	ea  = xtide.equilibarg[:, iyr]
	Ai  = Vector(xharm.A[ista, :])
	ki  = Vector(xharm.kappa[ista, :])

	pred = fill(xharm.datum[ista], lt)
	deg2rad = π / 180
	for c in 1:ncon
		(Ai[c] == 0) && continue
		amp_c = nf[c] * Ai[c]
		for j in 1:lt
			pred[j] += amp_c * cos((xtide.speed[c] * xtim[j] + ea[c] - ki[c]) * deg2rad)
		end
	end

	pred .*= convf
	return pred
end

# ========================================================================================
"""
    xtide_hilo(xtide, xharm, ista::Int, tim; units="original") -> (times, values, types)

Find high/low tide times and values by computing a 1-minute resolution prediction.

### Arguments
Same as `xtide_predict`.

### Returns
- `times`: Serial day numbers of high/low events
- `values`: Predicted values at those times
- `types`: 1 = high tide, 0 = low tide
"""
function xtide_hilo(xtide::XTideConstituents, xharm::XTideHarmonics, ista::Int, tim;
                    units::AbstractString="original")
	# Generate 1-minute resolution time vector
	if eltype(tim) <: DateTime
		epoch0 = DateTime(0, 1, 1)
		sd = [Dates.value(t - epoch0) / 86400000.0 + 1.0 for t in tim]
	else
		sd = Float64.(tim)
	end

	t_min = minimum(sd)
	t_max = maximum(sd)
	dt_min = 1.0 / 1440.0		# 1 minute in days
	tim_fine = collect(t_min:dt_min:t_max)

	pred = xtide_predict(xtide, xharm, ista, tim_fine; units=units)

	# Detect hi/lo: second derivative of sign changes
	dpred = diff(pred)
	signs = dpred .> 0
	ddsign = diff(Int.(signs))

	flat = findall(ddsign .!= 0) .+ 1

	times  = tim_fine[flat]
	values = pred[flat]
	types  = zeros(Int, length(flat))
	types[ddsign[flat .- 1] .< 0] .= 1		# 0=lo, 1=hi

	return times, values, types
end

# ========================================================================================
"""
    xtide_find_station(xharm, lon, lat) -> (ista, dist_km, station_name)

Find the closest tidal station to the given coordinates.

### Returns
- `ista`: Station index
- `dist_km`: Distance in km
- `station_name`: Station name string
"""
function xtide_find_station(xharm::XTideHarmonics, lon::Real, lat::Real)
	d, _ = t_gcdist(xharm.latitude, xharm.longitude, lat, lon)
	ista = argmin(d)
	return ista, d[ista], xharm.station[ista]
end

# ========================================================================================
# Internal helpers for date conversion (MATLAB serial day <-> year/month/day)
# MATLAB datenum(Y,M,D) convention: datenum(0,1,1) = 1

function serialday_from_ymd(y::Int, m::Int, d::Int)
	# Convert to MATLAB serial day number
	dt = DateTime(y, m, d)
	epoch0 = DateTime(0, 1, 1)
	return Dates.value(dt - epoch0) / 86400000.0 + 1.0
end

function year_from_serialday(sd::Float64)
	epoch0 = DateTime(0, 1, 1)
	dt = epoch0 + Dates.Millisecond(round(Int64, (sd - 1.0) * 86400000))
	return Dates.year(dt)
end

function mean_datetime(sdays::Vector{Float64})
	return (minimum(sdays) + maximum(sdays)) / 2
end
