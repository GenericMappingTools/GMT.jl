"""
    D = maregrams(list::Bool=false, code="", name="", days::Real=2, starttime::String="", printurl=false)::GMTdataset
	D = maregrams(lon::Real, lat::Real; days=2, starttime::String="")::GMTdataset

Download maregrams data from http://www.ioc-sealevelmonitoring.org.

The default is to download the last 2 days, but length and duration is configurable by input options.
Since the use of this function requires knowing the station code or name, we provide also the possibility
to use coordinates to find the nearest station. The file with stations data locations and names is stored in
the `TESTSDIR/assets/maregs_online.csv` file, which can be accessed using `d = GMT.read_maregrams()` and its
contents are returned in the `d` dictionary. Note that not all stations sites are always on and running, so
errors when requesting data from some stations are, unfortunately, not so uncommon.

Our reference stations data is a bit old (needs update) and we can find more stations online listed at the
http://www.ioc-sealevelmonitoring.org site. If user provides a station code that we don't know about, but is
a valid one, we still return the data for that station. Example:
`D = maregrams(code="tdoj")`

### Args
- `lon, lat`: (Second form) Coordinates of a point that is used to find the closest station to that point.
   This is an alternative way of selecting a station instead of using `code` or `name` that require knowing them.

### Kwargs
- `list::Bool`: If true, returns a GMTdataset with the list all available stations and their codes and coords.
- `code`: Station code (See the output of `list`)
- `name`: In alternative to `code` give the station name (See the output of `list`)
- `days`: Number of days to be downloaded. It can be a decimal number.
- `starttime`: Start time in ISO8601 format (_e.g._ `"2019-01-01T00:00:00"`, or just the date `"2019-01-01"`).
- `printurl`: If true, prints the station's URL. Useful for getting more info about the sation and its data.

### Returns
- `D`: GMTdataset with the maregrams data.

### Examples
Get the time series for 4 days starting at February 1 2025 for the station with code "lgos" (Lagos, Portugal)

```julia
D = maregrams(code="lgos", days=4, starttime="2025-02-01")
viz(D, title="Tide Gauge at Lagos (Portugal)")
```	
"""
function maregrams(; list::Bool=false, code="", name="", days=2, starttime::String="", printurl::Bool=false)::GMTdataset
	(list == true) && return gmtread(TESTSDIR * "/assets/maregs_online.csv")
	@assert days > 0  "Number of days must be > 0."
	_code::String = string(code)		# To let 'code' be a symbol as well
	d = read_maregrams()
	have_code = true
	(code != "" && !(_code in d[:code])) &&
		(have_code=false; println("The code '$code' was not a found in reference stations file, but maybe it's valid one."))
	(name != "" && !(name in d[:names])) && error("The code '$names' is not a valid station name.")

	# The shit here is that the site wants the endtime instead of starttime, sowe must do the maths to get it right.
	(starttime != "") &&
		try DateTime(starttime) catch; error("The start time '$starttime' is not a valid date.") end 
	endtime = (starttime == "") ? DateTime(now()) : DateTime(starttime) + Dates.Day(days)
	endtime > DateTime(now()) && (days -= round((endtime - DateTime(now())).value / (24*3600000), digits=6); endtime = DateTime(now()))
	url = "http://www.ioc-sealevelmonitoring.org/bgraph.php?code=$_code&output=asc&period=$days&endtime=$endtime"
	printurl && println(url[1:(54+length(_code))])		# Station's URL
	file = Downloads.download(url, "_query.csv")

	n_lines = countlines(file) - 2				# -2 to ignore the two header lines
	(n_lines <= 0) && (println("This station has no data or a file tranfer error occured."); return GMTdataset())

	mat = Matrix{Float64}(undef, n_lines, 2)
	n = -2
	var_in_mareg = ["prs(m)"]
	open(file, "r") do io
        for line in eachline(io)
			if ((n += 1) <= 0)					# To jump the first two (header) lines
				(n == -1) && continue			# Header line with station name
				what = split(line, "\t")
				((ind = findfirst(what .== "prs(m)")) === nothing) && (ind = findfirst(what .== "rad(m)"))
				(ind === nothing) && error("Sorry, but no 'prs' or 'rad' variables in this file. Quiting.")
				var_in_mareg[1] = what[ind]
				continue
			end
			t = split(line, "\t")
			mat[n, 1] = datetime2unix(DateTime(replace(t[1], " " => "T")))
			mat[n, 2] = (t[ind] != "") ? parse(Float64, t[ind]) : NaN
		end
	end
	try rm(file) catch end

	D = GMTdataset(mat)
	set_dsBB!(D)
	if (isnan(D.bbox[3]))  D.bbox[3], D.bbox[4] = extrema_nan(view(D.data, :, 2))  end
	D.colnames = ["time", var_in_mareg[1]]
	D.attrib["Timecol"] = "1"
	if (have_code)			# When we have the code in our small data file
		ind = (code != "") ? findfirst(code .== d[:code]) : findfirst(stname .== d[:name])
		D.attrib["Country"] = d[:country][ind]
		D.attrib["ST_name"] = d[:name][ind]
		D.attrib["ST_code"] = d[:code][ind]
	else					# One that exists but we don't know about
		D.attrib["Country"] = "Unknown"
		D.attrib["ST_code"] = code
	end
	return D
end

# ---------------------------------------------------------------------------------------------------
function maregrams(x::Real, y::Real; days=2, starttime::String="", printurl::Bool=false)::GMTdataset
	# Find the closest station to input x,y
	@assert -180 <= x <= 360 && -90 <= y <= 90  "Coordinates must be between -180 and 360 and -90 and 90."
	d = read_maregrams()
	dists = mapproject(d[:pos], G="$x/$y", o=2)
	ind = argmin(dists)
	maregrams(code=d[:code][ind], days=days, starttime=starttime, printurl=printurl)
end

# ---------------------------------------------------------------------------------------------------
function read_maregrams(fname=TESTSDIR * "/assets/maregs_online.csv")
	mat = Matrix{Float64}(undef, 378, 2)
	names = Vector{String}(undef, 378)
	codes = Vector{String}(undef, 378)
	countries = Vector{String}(undef, 378)
	n = -1
	open(fname, "r") do io
        for line in eachline(io)
			x, y, name, code, country = split(line, ",")
			((n += 1) == 0) && continue						# The header line
			mat[n, 1], mat[n, 2] = parse(Float64, x), parse(Float64, y)
			names[n], codes[n], countries[n] = name, code, country
		end
	end
	Dict(:pos => mat, :name => names, :code => codes, :country => countries)
end
