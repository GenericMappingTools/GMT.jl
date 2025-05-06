"""
    [D =] weather(lon=0.0, lat=0.0; city::String="", last=0, days=7, year::Int=0, starttime::Union{DateTime, String}="",
	              endtime::Union{DateTime, String}="", variable="temperature_2m", debug=false, show=false, kw...)

Plots and/or retrieve weather data obtained from the [Open-Meteo](https://open-meteo.com/en/docs) API.
Please consult the site for further details. You will find that there are many variables available to plot and with
not so obvious names. There are also _forecast_ and _archive_ versions of the variables. This function tries to guess
that from the variable names. That list of variable names is a bit extensive and we are not reproducing it entirely here,
but given it interest for climatological reason, we do list the so called ``daily`` variables.

- `variable`: "temperature_2m_max", "temperature_2m_min", "apparent_temperature_max", "apparent_temperature_min", "precipitation_sum", "rain_sum", "snowfall_sum", "precipitation_hours", "sunshine_duration", "daylight_duration", "wind_speed_10m_max", "wind_gusts_10m_max", "wind_direction_10m_dominant", "shortwave_radiation_sum", "et0_fao_evapotranspiration"

A word of aknowledge is also due to the [WeatherReport.jl](https://github.com/vnegi10/WeatherReport.jl) project
that inspired this function, that is much smaller (~25 LOC) and has no further dependencies than GMT itself.

- `lon` and `lat`: Explicitly provide the coordinates of the location. If not provided, nor the `city` name,
   the current location is used from an IP location service (see the `whereami` function help).
- `city`: The name of the location that will be used. City names are normally OK but if it fails see the help of the
   `geocoder()` function as that is what is used to transform names to coordinates. The default is to use the current
   geographic location of the user.
- `days`: When asking for forecasts this is the number of days to forecast. Maximum is 16 days. Default is 7.
- `starttime`: Limit to events on or after the specified start time. NOTE: All times use ISO8601 Date/Time format
    OR a DateTime type. Default is NOW - 30 days.
- `endtime`: Limit to events on or before the specified end time. Same remarks as for `starttime`. Default is present time.
- `last`: If value is an integer (*e.g.* `last=90`), select the events in the last n days. If it is a string
   than we expect that it ends with a 'w'(eek), 'm'(onth) or 'y'(ear). Example: `last="2Y"` (period code is caseless)
- `year`: An integer, restrict data download to this year.
- `debug`: Print the url of the requested data and return.
- `data`: The default is to make a seismicity map but if the `data` option is used (containing whatever)
    we return the data in a ``GMTdataset`` 
- `figname`: $(opt_savefig)
- `show`: By default this function just returns the data in a `GMTdataset` but if `show=true` it shows the plot.
   Use `data=true` to also return the data even when `show=true`.

### Examples
```julia
# Plot the temperature forecast of your location. Also returns the data table.
D = weather(data=true, show=true)
```
```julia
# Plot the rain fall during 2023 at Copenhagen
weather(city="Copenhagen", year=2023, variable="rain_sum", show=true)
```
"""
function weather(lon=0.0, lat=0.0; city::String="", last=0, days=7, year::Int=0, starttime::Union{DateTime, String}="",
                 endtime::Union{DateTime, String}="", variable="temperature_2m", debug=false, show=false, kw...)

	d = KW(kw)
	url_forcast = "https://api.open-meteo.com/v1/forecast?format=csv&"
	url_archive = "https://archive-api.open-meteo.com/v1/archive?format=csv&"
	url_air     = "https://air-quality-api.open-meteo.com/v1/air-quality?format=csv&"
	str_loc::String = (lon != 0.0 || lat != 0.0) ? "latitude=$lat&longitude=$lon" : (city != "") ? @sprintf("longitude=%f&latitude=%f", geocoder(city).data...) : @sprintf("longitude=%.3f&latitude=%.3f", whereami().data...)#"latitude=37.0695&longitude=-8.1006"

	variable = string(variable)
	dt = helper_get_date_interval(d, last, "", starttime, endtime, year=year)	# See if a period was requested
	url = ((variable == "pm" && (variable = "pm10")) || variable == "pm10" || variable == "pm2.5" || variable == "dust" || variable == "aerosol_optical_depth") ? url_air : (dt != "") ? url_archive : url_forcast
	(days != 7 && url != url_archive) && (url *= string("forecast_days=", days, "&"))
	url *= str_loc * dt
	daily_vars = ["temperature_2m_max", "temperature_2m_min", "apparent_temperature_max", "apparent_temperature_min", "precipitation_sum", "rain_sum", "snowfall_sum", "precipitation_hours", "sunshine_duration", "daylight_duration", "wind_speed_10m_max", "wind_gusts_10m_max", "wind_direction_10m_dominant", "shortwave_radiation_sum", "et0_fao_evapotranspiration"]
	hourly = any(variable .== daily_vars) ? false : true
	url *= hourly ? "&hourly=" * variable : "&daily=" * variable

	(debug != 0) && (println(url); return)

	file = Downloads.download(url, "_query.csv")
	D = gmtread(file, h=4)			# File has 4 header rows but only the 4rth matters
	rm(file)
	D.comment = [D.comment[4]]		# Retain only the 4rth: "time,temperature_2m (°C)\n"
	helper_set_colnames!(D)			# Set column names based on info stored in the 4rth header line
	D.attrib["Location"] = (city != "") ? city : replace(str_loc, "&" => " ")
	retD = (find_in_dict(d, [:data])[1] !== nothing)
	(show != 0) && plot(D; legend=D.colnames[2], title=D.attrib["Location"], show=true, d...)
	return (retD || show == 0) ? D : nothing
end

# ------------------------------------------------------------------------------------------------------------------------
"""
    era5(; filename="", cb::Bool=false, dataset="", params::AbstractString="", key::String="",
         url::String="", region="", format="netcdf", debug::Bool=false, verbose::Bool=true)

This function retrieves data from the Climate Data Store (CDS) (https://cds.climate.copernicus.eu) service.

- `filename`: The name of the file to save the data to. If not provided, the function will generate a
  name based on the dataset and the data format.
- `cb`: A boolean indicating whether to use the clipboard contents. If true, the function will use the
  ``clipboard()`` to fetch its contents. The clipboard should contain a valid API request code as generated
  by the CDS website. This site provides a ``Show API request`` button at the bottom of the download tab
  of each dataset. After clicking it, the user can copy the request code with a Control-C (or click ``Copy``
  button) which will and paste it into the clipboard.
- `dataset`: The name of the dataset to retrieve. This option can be skipped if the `dataset` option
  is provided in the `params` argument, or is included clipboard copy (the `cb` option is set to true).
- `params`: A JSON string containing the request parameters. This string should be in the format expected
  by the CDSAPI. When using input via this option the `dataset` option is mandatory.
  If you feel brave, you can create the request parametrs yourself and pass them as a two elements string
  vector with the output of the ``era5vars()`` and ``era5time()`` functions. In this case, a region selection
  and pressure levels, if desired, must be provided via the `region` and `pressure` options. The `region`
  option has the same syntax in all other GMT.jl modules that use it, _e.g._ the ``coast`` function.
- `key`: The API key for the CDSAPI server. Default is the value in the ``.cdsapirc`` file in the home directory.
  but if that file does not exist, the user can provide the `key` and `url` as arguments. Instructions on how
  to create the ``.cdsapirc`` file for your user account can be found at https://cds.climate.copernicus.eu/how-to-api 
- `url`: The URL of the CDS API server. Default is https://cds.climate.copernicus.eu/api
- `pressure`: List of pressure levels to retrieve. It can be a string to select a unique level, or a vector
  of strings or Ints to select multiple levels. But it can also be a range of levels, e.g. "1000:-100:500". 
  This option is only used when the `params` argument is provided as a string vector.
- `region`: Specify a region of a specific geographic area. It can be provided as a string with form "N/W/S/E"
  or a 4-element vector or tuple with numeric data. This option is only used when the `params` argument is
  provided as a string vector.
- `format`: The format of the data to download. Default is "netcdf". Other options is "grib".
- `debug`: A boolean indicating whether to print the `params` from the outputs of the `era5vars()` and
  `era5time()` functions. I this case, we just print the `params` and return without trying to download any file.
- `verbose`: A boolean indicating whether to print the attemps to connect to the CDS server. Default is true.

### Credits
This function is based in part on bits of CDSAPI.jl but doesn't require any of the dependencies of that package.

### Examples
```julia
# Copy the following code by selecting it and pressing Ctrl-C

{"product_type": ["reanalysis"],
    "variable": [
        "10m_u_component_of_wind",
        "10m_v_component_of_wind"
    ],
    "year": ["2024"],
    "month": ["12"],
    "day": ["06"],
    "time": ["16:00"],
    "data_format": "netcdf",
    "download_format": "unarchived",
    "area": [58, 6, 55, 9]
}

# Now call the function but WARNING: DO NOT COPY_PASTE it as it would replace the clipboard contents
era5(dataset="reanalysis-era5-single-levels", cb=true)
```

### Let's dare and build the request ourselves
```julia
var = era5vars(["t2m", "skt"])			# "t2m" is the 2m temperature and "skt" is the skin temperature
datetime = era5time(hour=10:14);
era5(dataset="reanalysis-era5-land", params=[var, datetime], region=(-10, 0, 30, 45))
```
"""
function era5(reanalysis::Symbol=:reanalysis; filename="", cb::Bool=false, dataset="", params::Union{AbstractString, Vector{String}}="", key::String="", url::String="", wait=1.0, pressure="", region="", format="netcdf", debug::Bool=false, verbose::Bool=true)

	function cdsapikey()::Tuple{String, String}
		# Get the API key and URL from the ~/.cdsapirc file
		credfile = joinpath(homedir(), ".cdsapirc")
		!isfile(credfile) && return "", ""
		creds = Dict()
		open(credfile) do f
			for line in readlines(f)
				key, val = strip.(split(line, ':', limit=2))
				creds[key] = val
			end
		end
		return string(creds["key"]), string(creds["url"])
	end

	function parse_request(request::String)
		bv = BitVector(undef, length(request))
		t = collect(request)
		for k = 1:numel(request)
			bv[k] = (t[k] != ' ' && t[k] != '\n')
		end
		t2 = join(t[bv])
		if t2[1] == '{' && t2[end] == '}'		# We got a JSON request string like the CDSAPI example
			return "{\"inputs\":" * t2 * "}", ""
		else
			dataset  = ""		# Accept that no dataset name was provided if from clipboard
			if ((ind = findfirst("dataset=\"", t2)) !== nothing)	# "import cdsapi\n\ndataset = \"reanalysis-era5-land\"\nrequest = {\n
				ind2 = findfirst("request={", t2)
				dataset = string(t2[ind[end]+1:ind2[1]-2])
				ind3 = findlast('}', t2)
			end
			return "{\"inputs\":" * t2[ind2[end]:ind3] * "}", dataset
		end
	end

	function curl_post(url, body, key)
		open(`curl -s --show-error --header "Content-Type: application/json" --request POST -H "PRIVATE-TOKEN":$key $url -d $body`, "r", stdout) do io
			split(readlines(io)[1], ',')
		end
	end
	function curl_get(url, key)
		open(`curl -s --show-error --header "Content-Type: application/json" --request GET -H "PRIVATE-TOKEN":$key $url`, "r", stdout) do io
			split(readlines(io)[1], ',')
		end
	end
	# ======================== End of nested functions ========================

	if (key == "")
		KEY, URL = cdsapikey()
		(KEY == "") && error("The 'key' option was not used and credentials file $(joinpath(homedir(), ".cdsapirc")) not found")
	else
		KEY = key
		URL = (url != "") ? url : "https://cds.climate.copernicus.eu/api"		# Default URL for CDSAPI
	end

	if (cb && params == "")
		tcb = clipboard()
		!contains(tcb, "variable\"") && error("Clipboard does not contain a valid API request code")
		body, _dataset = parse_request(tcb)
	else
		if isa(params, Vector)
			params = join(params, '\n')
			if (pressure != "")		# Pressure levels are provided
				pr = getdtp(pressure, "1000");	(pr == "e") && error("Unknown type for 'pressure'")
				sp = @sprintf("\"pressure_level\": [\"%s\"],\n", pr)
				sp = replace(sp, "[\"[" => "[");	sp = replace(sp, "]\"]" => "]");	# Remove double [[ & ]]
				params *= sp
			end
			params *= (format == "netcdf") ? "\"data_format\": \"netcdf\",\n" : "\"data_format\": \"grib\",\n"
			last = (region == "") ? "\n" : ",\n"	# Having an extra comma at the end of the line is a json syntax error
			params *= "\"download_format\": \"unarchived\"" * last
			if (region != "")		# The region is provided by parse_R() as a string like " -R58/6/55/9" (N/W/S/E)
				optR = split(parse_R(Dict(:R => region), "")[1], '/')
				params *= "\"area\": [" * optR[1][4:end] * ", " * optR[4] * ", " * optR[2] * ", " * optR[3] * "]\n"
			end
			params = "{\"product_type\": [\"reanalysis\"],\n" * params * "}"
			debug && (println(params);		return nothing)		# <== EXIT here
		end
		body, _dataset = parse_request(params)
	end
	(dataset == "" && _dataset == "") && error("'dataset' not provided, Neither as an argument nor in the clipboard.")
	(dataset == "" && _dataset != "") && (dataset = _dataset)

	s = curl_post(URL * "/retrieve/v1/processes/$dataset/execute", body, KEY)
	ind = findfirst(startswith.(s,"\"status"))
	(ind === nothing) && throw(ArgumentError("The request was not accepted, probably a malformed one. Check it the 'debug' option."))
	status = s[ind][11:end-1]			# It has the form "{\"status\":\"accepted\""
	if (contains(s[ind], ":4"))
		ind = findfirst(startswith.(s,"\"title"))
		throw(ArgumentError(split(s[ind], ':')[2][2:end-1]))	# It has the form "\"title\":\"Autentication failed\""
	end
	ind = findfirst(startswith.(s,"{\"href"))
	endpoint = s[ind][10:end-1]			# It has the form "{\"href\":\"https://cds.climate...\""
	while (status != "successful")
		s = curl_get(endpoint, KEY)
		st_line = findfirst(startswith.(s,"\"status"))
		contains(s[st_line], "404") && throw(ArgumentError("""The requested dataset $dataset was not found."""))
		status = s[st_line][11:end-1]
		verbose && @info "Request status: dataset = $dataset;    status = $status"
        if (status == "failed")
			throw(ErrorException("""Request to dataset $dataset failed. Check https://cds.climate.copernicus.eu/requests
			for more information (after login)."""))
		end
		(status != "successful") && (sleep(wait))
		wait = min(1.4 * wait, 3.0)
	end

	s = curl_get(endpoint * "/results", KEY)

	ind = findfirst(startswith.(s,"\"href"))
	urlname = string(s[ind][9:end-1])				# It has the form "\"href\":\"https://object-store...\""
	if (filename == "")								# Now we know the filename extension. It's in the urlname
		filename = dataset * splitext(urlname)[2]
	end
	verbose && @info "Request is now completed. Downloading $(uppercase(dataset))" URL=urlname Destination=filename; flush(stderr)

	run(`curl --show-error $urlname -o $filename`)
end

# ------------------------------------------------------------------------------------------------------------------------
"""
    listera5vars(; single::Bool=true, pressure::Bool=false, contain::AbstractString="")

Print a list of CDS ERA5 variables.

### Kwargs
- `single`: If true, only single-level variables are listed. If false, pressure-level variables are listed [Default is true].
- `pressure`: If true, only pressure-level variables are listed. If false, single-level variables are listed.
- `contain`: A string to filter the variables by their Name. Only those containing this string (case sensitive)
  are listed. If not provided, all variables are listed.

#### Example
```julia
# Print all pressure-level variables.
listera5vars(pressure=true)

# Print only single-level variables containing "Temperature" in their name.
listera5vars(contain="Temperature")
```
"""
function listera5vars(; single::Bool=true, pressure::Bool=false, contain::AbstractString="", test::Bool=false)
	d, title_str = helper_era5vars(single::Bool, pressure::Bool)
	if (contain != "")
		d = filter(((k,v),) -> contains(v[2], contain), d)
		isempty(d) && (@info "No variables found in the dataset for the search string \"$contain\""; return nothing)
	end
	ds = sort(d, by=first)
	test && return nothing
	pretty_table(hcat(collect(keys(ds)),stack(values(ds), dims=1)),header=["ID","Long-Name (nc var name)","Name","Units"],
	             alignment=[:c,:l,:l,:c], title=title_str * "-level variables", title_alignment=:c, crop=:horizontal)
end

# ------------------------------------------------------------------------------------------------------------------------
"""
    era5vars(varID; single::Bool=true, pressure::Bool=false) -> String

Selec one or more variables from a CDS ERA5 dataset.

This function returns a JSON formatted string that can be used as an input to the ``era5()`` function `params` option.
See the ``listera5vars()`` function for a list of available variables.

### Args
- `varID`: The variable name. It can be a string or a symbol to select a unique variavle, or a vector of
  strings/symbols to select multiple variables.

### Kwargs
- `single`: If true, only single-level variables are listed. If false, pressure-level variables are listed [Default is true].
- `pressure`: If true, only pressure-level variables are listed. If false, single-level variables are listed.
  [Default is false].

### Returns
A string with the JSON formatted variable name.

### Example
```julia
# "t2m" is the 2m temperature and "skt" is the skin temperature
var = era5vars(["t2m", "skt"])
```
"""
era5vars(varID::Union{String, Symbol}; single::Bool=true, pressure::Bool=false) = era5vars([string(varID)], single=single, pressure=pressure)
function era5vars(varID::Union{Vector{String}, Vector{Symbol}}; single::Bool=true, pressure::Bool=false)::String
	d = helper_era5vars(single::Bool, pressure::Bool)[1]
	_vars = (eltype(varID) == Symbol) ? string.(varID) : varID
	for k = 1:numel(_vars)
		!haskey(d, _vars[k]) && error("Variable \"$_vars[$k]\" not found in the dataset")
	end
	# Next line took me HOURS to figure it out. Shame on your printf Julia, shame on you.
	@sprintf("\"variable\": [\n\t\"%s\"\n],", join([d[k][1] for k in _vars], "\",\n\t\""))
end

# ------------------------------------------------------------------------------------------------------------------------
function helper_era5vars(single::Bool, pressure::Bool)
	pressure && (single = false);	!single && (pressure = true)
	dim_char = (single) ? "2" : "3";	title_str = (single) ? "Single" : "Pressure"
	return include(joinpath(dirname(pathof(GMT)), "extras/era5vars" * dim_char * "d.jl")), title_str
end

# ------------------------------------------------------------------------------------------------------------------------
"""
    era5time(; year="", month="", day="", hour="") -> String

Select one or more fate-times from a CDS ERA5 dataset.

This function returns a JSON formatted string that can be used as an input to the ``era5()`` function `params` option.

### Kwargs
- `year`: The year(s) to select. It can be a string to select a unique year, or a vector of strings or Ints to select multiple years.
  It can also be a range of years, e.g. "2010:2020".
- `month`: The month(s) to select. It can be a string to select a unique month, or a vector of strings or Ints to select multiple months.
  It can also be a range of months, e.g. "01:06".
- `day`: The day(s) to select. It can be a string to select a unique day, or a vector of strings or Ints to select multiple days.
  It can also be a range of days, e.g. "01:20".
- `hour`: The hour(s) to select. It can be a string to select a unique hour, or a vector of strings or Ints to select multiple hours.
  It can also be a range of hours, e.g. "01:10".

### Returns
A string with the JSON formatted date-time.

### Example
```julia
# All times in 2023
var = era5time(year="2023")
```
"""
function era5time(; year="", month="", day="", hour="")
	_y, _m, _d, _h = agora()
	yr = getdtp(year, _y);	(yr == "e") && error("Unknown type for 'year'")
	mo = getdtp(month, _m);	(mo == "e") && error("Unknown type for 'month'")
	dy = getdtp(day, _d);	(dy == "e") && error("Unknown type for 'day'")
	hr = getdtp(hour, _h);	(hr == "e") && error("Unknown type for 'hour'")
	s = @sprintf("\"year\": [\"%s\"],\n\"month\": [\"%s\"],\n\"day\": [\"%s\"],\n\"time\": [\"%s\"],\n", yr, mo, dy, hr)
	s = replace(s, "[\"[" => "[");	s = replace(s, "]\"]" => "]");		# Remove double [[ & ]]
	return s
end
	
function getdtp(x, def)		# used also in era5() to get the pressure levels
	(x == "") ? def : (typeof(x) <: OrdinalRange) ? string.(collect(x)) : isa(x, Vector{Int}) ? string.(x) : isa(x, Vector{String}) ? x : "e"
end

function agora()	# Must put this in a separate function because I want to use the keywords year, month, etc
	t = now()
	return string(year(t)), string(month(t)), string(day(t)), string(hour(t))
end
