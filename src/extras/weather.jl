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
    era5(; filename="", dataset="", cb::Bool=false, params::AbstractString="", key::String="",
         url::String="", verbose::Bool=true)

This function retrieves data from the Climate Data Store (CDS) (https://cds.climate.copernicus.eu) service.

- `filename`: The name of the file to save the data to. If not provided, the function will generate a
  name based on the dataset and the data format.
- `dataset`: The name of the dataset to retrieve. This option can be skipped if the `dataset` option
  is provided in the `params` argument, or is included clipboard copy (the `cb` option is set to true).
- `cb`: A boolean indicating whether to use the clipboard contents. If true, the function will use the
  ``clipboard()`` to fetch its contents. The clipboard should contain a valid API request code as generated
  by the CDS website. This site provides a ``Show API request`` button at the bottom of the download tab
  of each dataset. After clicking it, the user can copy the request code with a Control-C (or click ``Copy``
  button) which will and paste it into the clipboard.
- `params`: A JSON string containing the request parameters. This string should be in the format expected
  by the CDSAPI. When using input via this option the `dataset` option is mandatory.
- `key`: The API key for the CDSAPI server. Default is the value in the ``.cdsapirc`` file in the home directory.
  but if that file does not exist, the user can provide the `key` and `url` as arguments. Instructions on how
  to create the ``.cdsapirc`` file for your user account can be found at https://cds.climate.copernicus.eu/how-to-api 
- `url`: The URL of the CDS API server. Default is https://cds.climate.copernicus.eu/api
- `verbose`: A boolean indicating whether to print the attemps to connect to the CDS server. Default is true.

### Credits
This function is based in part on bits of CDSAPI.jl but doesn't require any of the dependencies of that package.

### Example
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
"""
function era5(reanalysis::Symbol=:reanalysis; filename="", dataset="", cb::Bool=false, params::AbstractString="", key::String="", url::String="", wait=1.0, verbose::Bool=true)

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
		body, _dataset = parse_request(params)
	end
	(dataset == "" && _dataset == "") && error("'dataset' not provided, Neither as an argument nor in the clipboard.")
	(dataset == "" && _dataset != "") && (dataset = _dataset)

	s = curl_post(URL * "/retrieve/v1/processes/$dataset/execute", body, KEY)
	st_line = findfirst(startswith.(s,"\"status"))
	if (contains(s[st_line], ":4"))
		ind = findfirst(startswith.(s,"\"title"))
		throw(ArgumentError(split(s[ind], ':')[2][2:end-1]))	# It has the form "\"title\":\"Autentication failed\""
	end
	status = s[st_line][11:end-1]			# It has the form "{\"status\":\"accepted\""
	ep_line = findfirst(startswith.(s,"{\"href"))
	endpoint = s[ep_line][10:end-1]			# It has the form "{\"href\":\"https://cds.climate...\""
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

	#ind = findfirst(startswith.(s,"\"file:size"))
	#fsize = parse(Float64, s[ind][13:end-1])		# It has the form "\"file:size\":34063"
	ind = findfirst(startswith.(s,"\"href"))
	urlname = string(s[ind][9:end-1])				# It has the form "\"href\":\"https://object-store...\""
	if (filename == "")								# Now we know the filename extension. It's in the urlname
		filename = dataset * splitext(urlname)[2]
	end
	verbose && @info "Request is now completed. Downloading $(uppercase(dataset))" URL=urlname Destination=filename; flush(stderr)

	run(`curl --show-error $urlname -o $filename`)
end
