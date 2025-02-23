"""
    maregrams(; list::Bool=false, code="", stname="", ndays=2, endtime::String="")


"""
function maregrams(; list::Bool=false, code="", stname="", ndays=2, endtime::String="")::GMTdataset
	(list == true) && return gmtread(TESTSDIR * "/assets/maregs_online.csv")
	d = read_maregrams()
	(code != "" && !(code in d[:code])) && error("The code '$code' is not a valid station code.")
	(stname != "" && !(stname in d[:names])) && error("The code '$names' is not a valid station name.")
	endtime == "" && (endtime = string(Date(now()))), rm
	url = "http://www.ioc-sealevelmonitoring.org/bgraph.php?code=$code&output=asc&period=$ndays&endtime=$endtime"
	file = Downloads.download(url, "_query.csv")

	n_lines = countlines(file) - 2				# -2 to ignore the two header lines
	mat = Matrix{Float64}(undef, n_lines, 2)
	n = -2
	open(file, "r") do io
        for line in eachline(io)
			((n += 1) <= 0) && continue			# Jump the first two (header) lines
			date_time, _, prs, = split(line, "\t")
			mat[n, 1] = datetime2unix(DateTime(replace(date_time, " " => "T")))
			mat[n, 2] = (prs != "") ? parse(Float64, prs) : NaN
		end
	end
	try rm(file) catch end

	D = GMTdataset(mat)
	set_dsBB!(D)
	if (isnan(D.bbox[3]))  D.bbox[3], D.bbox[4] = extrema_nan(view(D.data, :, 2))  end
	D.colnames = ["time", "prs(m)"]
	D.attrib["Timecol"] = "1"
	ind = (code != "") ? findfirst(code .== d[:code]) : findfirst(stname .== d[:name])
	D.attrib["Country"] = d[:country][ind]
	D.attrib["ST_name"] = d[:name][ind]
	return D
end

# ---------------------------------------------------------------------------------------------------
function maregrams(x::Real, y::Real; ndays=2, endtime::String="")::GMTdataset
	# Find the closest station to input x,y
	@assert -180 <= x <= 360 && -90 <= y <= 90  "Coordinates must be between -180 and 360 and -90 and 90."
	d = read_maregrams()
	dists = mapproject(d[:pos], G="$x/$y", o=2)
	ind = argmin(dists)
	maregrams(code=d[:code][ind], ndays=ndays, endtime=endtime)
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
