"""
    [D =] weather(lon=0.0, lat=0.0; city::String="", last=0, days=7, year::Int=0, starttime::Union{DateTime, String}="",
	              endtime::Union{DateTime, String}="", variable="temperature_2m", dryrun=false, show=false, kw...)

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
- `dryrun`: Print the url of the requested data and return.
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
                 endtime::Union{DateTime, String}="", variable="temperature_2m", dryrun=false, debug=false, show=false, kw...)

	# Keep the deprecated option 'debug' for now but remove it in the future (17-May-2025)
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

	(dryrun != 0 || debug != 0) && (println(url); return)

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
    ecmwf(; filename="", cb::Bool=false, dataset="", params::AbstractString="", key::String="",
          url::String="", region="", format="netcdf", dryrun::Bool=false, verbose::Bool=true)

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
   and pressure levels, if desired, must be provided via the `region` and `levlist` options. The `region`
   option has the same syntax in all other GMT.jl modules that use it, _e.g._ the ``coast`` function.
- `key`: The API key for the CDSAPI server. Default is the value in the ``.cdsapirc`` file in the home directory.
   but if that file does not exist, the user can provide the `key` and `url` as arguments. Instructions on how
   to create the ``.cdsapirc`` file for your user account can be found at https://cds.climate.copernicus.eu/how-to-api 
- `url`: The URL of the CDS API server. Default is https://cds.climate.copernicus.eu/api
- `levlist`: List of pressure levels to retrieve. It can be a string to select a unique level, or a vector
   of strings or Ints to select multiple levels. But it can also be a range of levels, e.g. "1000:-100:500". 
   This option is only used when the `params` argument is provided as a string vector.
- `region`: Specify a region of a specific geographic area. It can be provided as a string with form "N/W/S/E"
   or a 4-element vector or tuple with numeric data. This option is only used when the `params` argument is
   provided as a string vector.
- `format`: The format of the data to download. Default is "netcdf". Other options is "grib".
- `dryrun`: A boolean indicating whether to print the `params` from the outputs of the `era5vars()` and
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
ecmwf(dataset="reanalysis-era5-single-levels", cb=true)
```

### Let's dare and build the request ourselves
```julia
var = era5vars(["t2m", "skt"])			# "t2m" is the 2m temperature and "skt" is the skin temperature
datetime = era5time(hour=10:14);
ecmwf(dataset="reanalysis-era5-land", params=[var, datetime], region=(-10, 0, 30, 45))
```

-----
    ecmwf(:forecast; levlist="", kw...)

Download a forecast dataset from the ECMWF.

### Kwargs
- `cube`: If true [the default], when downloading pressure levels variables, save them data as a netCDF 3D cubes instead
   of one file per layer (when `cube=false`).
- `date`: The date to select. It can be a string to select a unique date, a ``DateTime`` object, or a Int.
   Where the Int is the number of days to go back from today. If the Int is greater than 3, an error is raised.
   If the date is a string, it must be in the form YYYYMMDD or YYYY-MM-DD.
- `dryrun`: Print the URL of the requested data and return without trying to download anything.
- `format`: The format in which to save the downloaded data. It can be "grib" or "netcdf". Default is "netcdf".
- `levlist`: The pressure levels to select. It can be a string to select a unique pressure level,
   or a vector of strings or Ints to select multiple pressure levels.
- `model`: A string with the model to select. Either "ifs" or "aifs". Default is "ifs".
- `param, variable, var, vars`: The variable(s) to select. It can be a string to select a unique variable, or a vector
   of strings or Ints to select multiple variables. When variable(s) is requested, we download only those
   variables as separate files. The names of those files are the same as the variable names with the .grib2 extension.
   NOTE: Not specifying a variable will download the entire forecast grib file for each forecast step selected with the `step` option.
- `root`: The root URL of the CDS ERA5 dataset. Default is "https://data.ecmwf.int/forecasts".
- `step`: An Int with the forecast step to select.
- `stream`: The stream to select. It can be one of: "oper", "enfo", "waef", "wave", "scda", "scwv", "mmsf". Default is "oper".
- `time`: The time in hours to select. It can be a string a ``Time`` object, or a Int. What ever it is,
   it will floored to 0, 6, 12 or 18. The default is the current hour.
- `stream`: A string with the stream to select, it must be one of: "oper", "enfo", "waef", "wave", "scda", "scwv", "mmsf". Default is "oper".
- `type`: A string with the type of forecast to select, it must be one of: "fc", "ef", "ep", "tf". Default is "fc".

### Example
Try to get the latest 10m wind and 2m temperature forecast for today. It probably will fail because
the data is likely not available yet. Adding a good `date` will make it work.	
```julia
ecmwf(:forecast, vars=["10u", "2t"])
```
"""
function ecmwf(source::Symbol=:reanalysis; filename="", cb::Bool=false, dataset="", params::Union{AbstractString, Vector{String}}="", key::String="", url::String="", wait=1.0, levlist="", region="", format="netcdf", dryrun=false, verbose::Bool=true, kw...)

	(source == :forecast) && return ecmwf_fc(; levlist=levlist, dryrun=dryrun, kw...)

	function cdsapikey()::Tuple{String, String}
		# Get the API key and URL from the ~/.cdsapirc file
		credfile = joinpath(homedir(), ".cdsapirc")
		!isfile(credfile) && return "", ""
		creds = Dict{String, String}()
		open(credfile) do f
			for line in readlines(f)
				_key_, _val_ = strip.(split(line, ':', limit=2))
				creds[_key_] = _val_
			end
		end
		return string(creds["key"]), string(creds["url"])
	end

	function parse_request(request::String)::Tuple{String, String}
		bv = BitVector(undef, length(request))
		t = collect(request)
		for k = 1:numel(request)
			bv[k] = (t[k] != ' ' && t[k] != '\n' && t[k] != '\r')
		end
		request[end] == ',' && (bv[end] = false)	# Remove the last comma if present. It is not a valid JSON syntax
		t2 = join(t[bv])
		if t2[1] == '{' && t2[end] == '}'		# We got a JSON request string like the CDSAPI example
			(t2[end-1] == ',') && (t2 = replace(t2, ",}" => "}"))	# Shit, an extra comma in the end. Illegal JSON
			t2 = replace(t2, ",]" => "]")		# Python cdsapi examples are full of shits like this that cause JSON errors
			return "{\"inputs\":" * t2 * "}", ""
		else
			_dataset_  = ""		# Accept that no dataset name was provided if from clipboard
			if ((_ind_ = findfirst("dataset=\"", t2)) !== nothing)	# "import cdsapi\n\ndataset = \"reanalysis-era5-land\"\nrequest = {\n
				_ind2_ = findfirst("request={", t2)
				_dataset_ = string(t2[_ind_[end]+1:_ind2_[1]-2])
				ind3 = findlast('}', t2)
				t2 = t2[_ind2_[end]:ind3] * "}"
			end
			t2 = replace(replace(t2, ",]" => "]"), ",}" => "}")		# Just in case we have those extra commas
			return "{\"inputs\":" * t2, _dataset_
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
			if (levlist != "")		# Pressure levels are provided
				pr = getdtp(levlist, "1000");	(pr === nothing) && error("Unknown type for 'levlist'")
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
			dryrun && (println(params);		return nothing)		# <== EXIT here
		end
		body, _dataset = parse_request(params)
	end
	(dataset == "" && _dataset == "") && error("'dataset' not provided, Neither as an argument nor in the clipboard.")
	(dataset == "" && _dataset != "") && (dataset = _dataset)

	s = curl_post(URL * "/retrieve/v1/processes/$dataset/execute", body, KEY)
	ind::Union{Nothing, Int} = findfirst(startswith.(s,"\"status"))		# Annotate it otherwise it's a spee Anys
	(ind === nothing) && throw(ArgumentError("The request was not accepted, probably a malformed one. Check it the 'dryrun' option."))
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

# ---------------------------------------------------------------------------------------------------------------
function ecmwf_fc(; levlist="", kw...)

	d = KW(kw)
	root = "https://data.ecmwf.int/forecasts"
	if ((val = find_in_dict(d, [:root])[1]) !== nothing)	#
		root = string(val)::String
		(!contains(root, "https://") && !contains(root, "ecmwf")) && error("The 'root' option must be a valid URL")
	end

	# ---------- Stream ------------------------------------------------------
	stream::String = "oper"				# Default is high-res
	if ((val = find_in_dict(d, [:stream])[1]) !== nothing)	# 
		stream = string(val)::String
		!(stream in ["oper", "enfo", "waef", "wave", "scda", "scwv", "mmsf"]) &&
			error("Unknown 'stream' code. Must be either: \"oper\", \"enfo\" , \"waef\", \"wave\", \"scda\", \"scwv\" or \"mmsf\"")
		(stream != "oper") && (model != "ifs") && error("The 'stream' option is not available for the \"ifs\" model")
	end

	# ---------- Variables ---------------------------------------------------
	vars::Union{String, Vector{String}} = ""
	if ((val = find_in_dict(d, [:variable :var :vars :param])[1]) !== nothing)
		vars = getdtp(val, "")
		srf = keys(helper_ecmwf_vars(true, false, "fc")[1])		# Single (surface) vars
		pl  = keys(helper_ecmwf_vars(false, true, "fc")[1])		# Pressure vars
		check_var = zeros(Int, numel(vars))
		for k = 1:numel(vars)			# Check if var is in srf or pl
			if     (vars[k] in srf)  check_var[k] = 1			# A surface var
			elseif (vars[k] in pl)   check_var[k] = 2			# A pressure var
			else                     error("Variable \"$(var[k])\" not found in either surface or pressure level datasets")
			end	
		end
	end

	# ---------- Levels -----------------------------------------------------
	levels::Union{Vector{String}, Nothing} = nothing
	if (levlist != "")				# Pressure levels are provided
		list_levs = ["1000", "925", "850", "700", "500", "300", "250", "200", "50"]	
		levels = (levlist == "all") ? list_levs : getdtp(levlist, "");	(levels === nothing) && error("Unknown type for 'levlist'")
		if (levlist != "all")		# Check if all levels provided are legal values
			res = [it for it in levels if it ∉ ["1000", "925", "850", "700", "500", "300", "250", "200", "50", "5", "4", "3", "2", "1"]]
			(length(res) > 0) && error("Non-existing pressure levels: $(join(res, ", ")) given in 'levlist' option")
		end
	else
		levels = ["1000"]
	end

	# ---------- Steps ------------------------------------------------------
	step = ((val = find_in_dict(d, [:step :steps])[1]) === nothing) ? ["0"] : getdtp(val, ["0"])
	(step === nothing) && error("Unknown type for 'step'")

	# Check if we want to save multi-layer variables as cubes. Default is TRUE
	cubeit = ((val = find_in_dict(d, [:cube])[1]) !== nothing && val == 0) ? false : true
	if (cubeit && length(step) > 1 && length(levels) > 1)
		@warn "Sorry, selecting multi-time-steps and multi-pressure-layers cubes are not supported yet."
		return nothing
	end

	multi_steps = (cubeit && length(step) > 1) ? true : false	# To know if we 'cube' a multi-steps file

	# ---------- Model ------------------------------------------------------
	model::String = ((val = find_in_dict(d, [:model])[1]) === nothing) ? "ifs" : lowercase(string(val)::String)
	(model != "ifs" && model != "aifs") && error("Model must be either \"ifs\" or \"aifs\"")
	(model == "aifs") && (model = "aifs-single")		# This the name of the directory in the ECMWF servers

	# ---------- Forecast ---------------------------------------------------
	type::String = "fc"					# Default is forecast
	if ((val = find_in_dict(d, [:type])[1]) !== nothing)	# 
		type = lowercase(string(val)::String)
		!(type in ["fc", "ef", "ep", "tf"]) && error("Unknown 'type' code. Must be either: \"fc\", \"ef\", \"ep\" or \"tf\"")
	end
	format = (type == "tf") ? "bufr" : "grib2"				# No choices here
	
	# ---------- Date-Time ---------------------------------------------------
	date, tim, msg = parse_date_time_ecmwf(d, step, root, model, stream, type)
	(msg != "") && (@info msg; return nothing)	 			# Requested a non existing thing

	# [ROOT]/[yyyymmdd]/[HH]z/[model]/[resol]/[stream]/[yyyymmdd][HH]0000-[step][U]-[stream]-[type].[format]
	dryrun = (find_in_dict(d, [:dryrun])[1] !== nothing) ? true : false
	if (vars == "")
		destdir::String = ((val = find_in_dict(d, [:destdir])[1]) !== nothing) ? string(val)::String * "/" : ""
		for ns = 1:numel(step)
			fname = "$(date)/$(tim)z/$(model)/0p25/$(stream)/$(date)$(tim)0000-$(step[ns])h-$(stream)-$(type).$format"
			dryrun ? println("$(root)/$(fname)") : run(`curl --show-error $(root)/$(fname) -o $(destdir)$fname`)
		end
		return nothing
	end

	opt_R = parse_R(d, "")[1]
	grdclip_cmd = opt_R * " -Sr1/1 -G"			# Not always used. To be replaced when grdconvert GMT bug is fixed
	(opt_R != "") && (opt_R = opt_R[4:end])
	EXT = (((val = find_in_dict(d, [:format])[1]) !== nothing) && val == "grib") ? ".grib" : ".grd"
	fmt_info = (EXT == ".grib") ? "GRIB" : "netCDF"	# For printing info

	local mat, G::GMTgrid{Float32,2}, x, y, range, inc
	tmp = tempname()
	for ns = 1:numel(step)						# Loop over the steps
		thisFile = root * "/$(date)/$(tim)z/$(model)/0p25/$(stream)/$(date)$(tim)0000-$(step[ns])h-$(stream)-$(type)."
		dryrun && (println(thisFile * "grib2"); continue)	# Dry run

		Downloads.download(thisFile * "index", tmp)

		# Find the 'offset' and 'length' of each variable
		off_len = fish_var_off_len_in_index_file(tmp, vars, levels, check_var)

		url = thisFile * format

		for k = 1:numel(vars)					# Loop over the vars
			@info "Downloading $(vars[k]) from $url and saving to $fmt_info format"

			if (check_var[k] == 2)				# A Pressure level variable
				n_levels = numel(levels)
				for nl = 1:n_levels
					start, len, stop = off_len[k,1,nl], off_len[k,2,nl], off_len[k,1,nl] + off_len[k,2,nl] - 1		# This var byte range
					uname = "/vsisubfile/$(start)_$(len),/vsicurl/" * url		# URL name
					if (cubeit && n_levels > 1)	# Create a cube with all levels
						if (nl == 1)			# First time, read the first level and create a 3d array with the right dims
							G = gmtread(uname, R=opt_R, grd=true, layout="TRB")
							x, y, range, inc = G.x, G.y, G.range, G.inc
							mat = Array{Float32, 3}(undef, size(G,1), size(G,2), length(levels))
						else
							G = gmtread(uname, R=opt_R, grd=true, layout="TRB")
						end
						mat[:,:,nl] .= G.z
					else
						fname = vars[k] * "_step$(step[ns])_level$(levels[nl])_$(model)_$(stream)_$(type)_$(date)_$(tim)$(EXT)"	# This var fname
						(EXT == ".grd") ? gmt("grdclip /vsisubfile/$(start)_$(len)" * ",/vsicurl/" * url * grdclip_cmd * fname) :
					                      run(`curl --show-error --range $(start)-$(stop) $url -o $fname`)
					end
				end

				if (cubeit && n_levels > 1)		# Save the cube (implied by 'cubeit') on a 3D file
					fname = vars[k] * "_step$(step[ns])_$(model)_$(stream)_$(type)_$(date)_$(tim).nc"		# This cube fname
					make_cube_ecmwf(G, mat, x, y, range, inc, levels, "millibars", levels, "Pressure", vars[1], fname)
				end

			else								# A surface variable
				start, len, stop = off_len[k,1,1], off_len[k,2,1], off_len[k,1,1] + off_len[k,2,1] - 1		# This var byte range
				fname = vars[k] * "_step$(step[ns])_$(model)_$(stream)_$(type)_$(date)_$(tim)$(EXT)"		# This var fname
				(EXT == ".grd") ? gmt("grdclip /vsisubfile/$(start)_$(len),/vsicurl/" * url * grdclip_cmd * fname) :
				                  run(`curl --show-error --range $(start)-$(stop) $url -o $fname`)
			end
			
			if (cubeit && multi_steps)
				if (ns == 1)
					G = gmtread(fname, layout="TRB")
					x, y, range, inc = G.x, G.y, G.range, G.inc
					mat = Array{Float32, 3}(undef, size(G,1), size(G,2), length(step))
				else
					G = gmtread(fname, layout="TRB")
				end
				mat[:,:,ns] .= G.z
				rm(fname)
			end
		end
	end
	
	if (cubeit && multi_steps)
		fname = vars[1] * "_step$(step[1])-$(step[end])_$(model)_$(stream)_$(type)_$(date)_$(tim).nc"		# This cube fname
		make_cube_ecmwf(G, mat, x, y, range, inc, step, "hour", step, "time", vars[1], fname)
	end
	!dryrun && rm(tmp)
end

# --------------------------------------------------------------------------------------------------------
function parse_date_time_ecmwf(d, step, root::String, model::String, stream::String, type::String)
	# Parse the date and time and mostrly check that the dir/data exists. When no date is given
	# we use the current date and try to find the directory of the most recent data.

	# ---------- Date -------------------------------------------------------
	date::String, tim::String, _h::Int = "", "", 0
	if ((val = find_in_dict(d, [:date])[1]) !== nothing)
		if (isa(val, String))
			data::String = val			# To f the Any
			date = (length(data) == 8) ? data : (length(data) == 10 && contains(data, "-")) ? data[1:4] * data[6:7] * data[9:10] : error("When string, 'date' must be in the form YYYYMMDD")
		elseif (isa(val, Date) || isa(val, DateTime))
			date = Dates.format(val, dateformat"yyyymmdd")
			isa(val, DateTime) && (_h = hour(val))
		elseif (isa(val, Int))
			n::Int = Int(abs(val))::Int
			(n > 3) && error(" Forecasts older than 3 days are no longer available")
			date = Dates.format(now()-Day(n), dateformat"yyyymmdd");
		end
		autodate = false
	else								# If no date is given, use the current date
		date = Dates.format(now(), dateformat"yyyymmdd");	_h = hour(now())
		!check_url(root * "/$date") && (date = Dates.format(now()-Day(1), dateformat"yyyymmdd"); _h = 18)	# Too soon? Get yesterday's date
		# And the 'ifs' dir exists too?
		(_h == 18 && model == "ifs" && !check_url(root * "/$(date)/$(tim)z/ifs")) && (tim = @sprintf("%.02d", (_h -= 6)))
		autodate = true					# To know if we need to check the time too.
	end
	
	# ---------- Time -------------------------------------------------------
	if ((val = find_in_dict(d, [:time])[1]) !== nothing)	# Even if gotten above, a explicit mention to time takes precedence
		if (isa(val, String))   _h = parse(Int, val)::Int
		elseif (isa(val, Time)) _h = hour(val)::Int
		elseif (isa(val, Int))	_h = val
		end
	end
	_h -= rem(_h, 6)					# To get only 0, 6, 12 or 18 hours
	tim = @sprintf("%.02d", _h)

	# --------- Now test if this date/time is available in the server --------
	if (!check_url(root*"/$(date)/$(tim)z/$(model)/0p25/$(stream)"))	# Check if the URL exists
		if (autodate)
			found = false
			while (_h > 0 && !found)	# Check if the date is available in the server. If not, go back 6 hours and check again.
				tim = @sprintf("%.02d", (_h -= 6))
				found = check_url(root * "/$(date)/$(tim)z")
			end
			# OK, but does the 'model' have this date/time? If not, go back another 6 hours and check again.
			@label try_again
			if (!check_url(root * "/$(date)/$(tim)z/$model"))
				tim = @sprintf("%.02d", (_h -= 6))
				(!check_url(root * "/$(date)/$(tim)z/$(model)/0p25/$stream")) && (tim = @sprintf("%.02d", (_h -= 6)))
				(_h < 0) && return "","", "Sorry, giving up trying to find the latest dataset for the requested parameters. Must pass a date/time manually."
			else		# And does the 'stream' exist?
				if !check_url(root * "/$(date)/$(tim)z/$(model)/0p25/$stream")	# Ghrrr!, no. Must go back to another time
					tim = @sprintf("%.02d", (_h -= 6))
					(!check_url(root * "/$(date)/$(tim)z/$(model)/0p25/$stream")) && (tim = @sprintf("%.02d", (_h -= 6)))
				else	# OK, but does the .index file exist?
					if !check_url(root * "/$(date)/$(tim)z/$(model)/0p25/$(stream)/$(date)$(tim)0000-$(step[1])h-$(stream)-$(type).index")	# F...
						tim = @sprintf("%.02d", (_h -= 6))
						@goto try_again
					end
				end
			end
		else
			return "", "", "The requested combination date $date and time $tim is not available in the server. Either too soon or too old. \nManually check the $root to see what is available."
		end
	end

	# All in all, does the base directory exist? (Above checks are not complete)
	if (!check_url(root * "/$(date)/$(tim)z/$(model)/0p25/$(stream)"))
		return "", "", "The requested $(root)/$(date)/$(tim)z/$(model)/0p25/$(stream) directory does not (yet?) exists. You must manually check what's available."
	end

	return date, tim, ""
end

# --------------------------------------------------------------------------------------------------------
function make_cube_ecmwf(G, mat, x, y, range, inc, the_levels, z_unit, names, dim_name, band_name, cube_name)
	# Make a cube from a 3D array of size (size(G,1), size(G,2), length(names))
	cube = mat2grid(mat, G)
	cube.x = x;		cube.y = y;		cube.range = range;		cube.inc = inc;		cube.z_unit = z_unit
	cube.names = names;				cube.v = parse.(Float64, the_levels);		cube.proj4 = prj4WGS84
	append!(cube.range, [cube.v[1], cube.v[end]])
	gdalwrite(cube, cube_name, cube.v, dim_name=dim_name, band_name=band_name)
end

# --------------------------------------------------------------------------------------------------------
function check_url(url::AbstractString)::Bool
	# Check if the URL exists. Returns true if it does, false otherwise.
	ret = true
	try		# Need a try catch because it screems when it fails
		open(`curl -s --head --silent --fail $url`, "r", stdout) do io
			split(readlines(io)[1], ',')
		end
	catch; ret = false
	end
	return ret
end

# --------------------------------------------------------------------------------------------------------
function fish_var_off_len_in_index_file(fname, vars, levels, check_var)
	# Find the 'offset' and 'length' of each variable in 'vars' in the index file 'fname'
	# Return a 3D array of size (length(vars), 2, length(levels)) with the offsets and lengths in col1 and col2
	# The 3rd dimension is for the case where a variable spans over multiple levels.
	off_len = zeros(Int, length(vars), 2, (levels === nothing) ? 1 : numel(levels))
	fid = open(fname)
	iter = eachline(fid)
	for k = 1:numel(vars)						# Scan the index file to get the offset and length of each variable
		first_lev = 1
		_var = "\"$(vars[k])\""
		for it in iter							# Loop over the lines in the index file
			!contains(it, _var) && continue
			if (check_var[k] == 2)				# A Pressure level variable
				for lev = first_lev:numel(levels)
					this_lev = "\"$(levels[lev])\""
					!contains(it, "\"levelist\": $this_lev") && @goto next_it		# Not found, read next line
					s = split(it, ',')[12:13]	# Should contain the "_offset": XX, "_length": YY
					off_len[k, 1, lev], off_len[k, 2, lev] = parse(Int, s[1][12:end]), parse(Int, s[2][12:end-1])
					seekstart(fid)
					iter = eachline(fid)
					first_lev += 1				# So that next time this loop is executed it will start from the next level
				end
			else								# A sigle level variable
				s = split(it, ',')[11:12]		# Should contain the "_offset": XX, "_length": YY
				off_len[k, 1, 1], off_len[k, 2, 1] = parse(Int, s[1][12:end]), parse(Int, s[2][12:end-1])	# end-1 becase last char is the '}'
			end
			break								# No need to continue, we found what we were looking for
			@label next_it
		end
	end
	close(fid)
	return off_len
end

# ------------------------------------------------------------------------------------------------------------------------
"""
    listecmwfvars(source::Symbol=:reanalysis; single::Bool=true, levlist::Bool=false, contain::AbstractString="")

Print a list of CDS ERA5 variables.

### Args
- `source`: The source of the data. It can be either ``:reanalysis`` or ``:forecast``. Default is `:reanalysis`.

### Kwargs
- `single`: If true, only single-level variables are listed. If false, pressure-level variables are listed [Default is true].
- `pressure`: If true, only pressure-level variables are listed. If false, single-level variables are listed.
- `contain`: A string to filter the variables by their Name. Only those containing this string (case sensitive)
  are listed. If not provided, all variables are listed.

#### Example
```julia
# Print all pressure-level variables.
listecmwfvars(pressure=true)

# Print only single-level variables containing "Temperature" in their name from the foorecast datasets.
listecmwfvars(:forecast, contain="Temperature")
```
"""
function listecmwfvars(source::Symbol=:reanalysis; single::Bool=true, pressure::Bool=false, contain::AbstractString="", test::Bool=false)
	what = (source == :reanalysis) ? "era5" : "fc"
	d, title_str = helper_ecmwf_vars(single, pressure, what)
	if (contain != "")
		d = filter(((k,v),) -> contains(v[2], contain), d)
		isempty(d) && (@info "No variables found in the dataset for the search string \"$contain\""; return nothing)
	end
	ds = sort(d, by=first)
	header = (what == "fc") ? ["ID","Name","Units"] : ["ID","Long-Name (nc var name)","Name","Units"]
	align = (what == "fc") ? [:c,:l,:c] : [:c,:l,:l,:c]
	t = (what == "fc") ? " (Forecast)" : " (ERA5)";	
	test && return nothing
	pretty_table(hcat(collect(keys(ds)),stack(values(ds), dims=1)), header=header, alignment=align,
	             title=title_str * "-level variables" * t, title_alignment=:l, crop=:horizontal)
end

# ------------------------------------------------------------------------------------------------------------------------
"""
    era5vars(varID; single::Bool=true, pressure::Bool=false) -> String

Selec one or more variables from a CDS ERA5 dataset.

This function returns a JSON formatted string that can be used as an input to the ``ecmwf()`` function `params` option.
See the ``listecmwfvars()`` function for a list of available variables.

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
	d = helper_ecmwf_vars(single, pressure, "era5")[1]
	_vars = (eltype(varID) == Symbol) ? string.(varID) : varID
	for k = 1:numel(_vars)
		!haskey(d, _vars[k]) && error("Variable \"$_vars[$k]\" not found in the dataset")
	end
	# Next line took me HOURS to figure it out. Shame on your printf Julia, shame on you.
	@sprintf("\"variable\": [\n\t\"%s\"\n],", join([d[k][1] for k in _vars], "\",\n\t\""))
end

# ---------------------------------------------------------------------------------------------------------------
function helper_ecmwf_vars(single::Bool, pressure::Bool, prefix::String)::Tuple{Dict{String, Vector{String}}, String}
	pressure && (single = false);	!single && (pressure = true)
	dim_char = (single) ? "2" : "3";	title_str = ((single) ? "\nSingle" : "\nPressure")
	return include(joinpath(dirname(pathof(GMT)), "extras/" * prefix * "vars" * dim_char * "d.jl")), title_str
end
	
# ---------------------------------------------------------------------------------------------------------------
"""
    era5time(; year="", month="", day="", hour="") -> String

Select one or more date-times from a CDS ERA5 dataset.

This function returns a JSON formatted string that can be used as an input to the ``ecmwf()`` function `params` option.

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
	yr = getdtp(year, [_y]);	(yr === nothing) && error("Unknown type for 'year'")
	mo = getdtp(month, [_m]);	(mo === nothing) && error("Unknown type for 'month'")
	dy = getdtp(day, [_d]);	(dy === nothing) && error("Unknown type for 'day'")
	hr = getdtp(hour, [_h]);	(hr === nothing) && error("Unknown type for 'hour'")
	s = @sprintf("\"year\": [\"%s\"],\n\"month\": [\"%s\"],\n\"day\": [\"%s\"],\n\"time\": [\"%s\"],\n", yr, mo, dy, hr)
	s = replace(s, "[\"[" => "[");	s = replace(s, "]\"]" => "]");		# Remove double [[ & ]]
	return s
end
	
function getdtp(x, def)::Union{Vector{String}, Nothing}		# used also in ecmwf() to get the pressure levels
	(x == "") ? def : (typeof(x) <: OrdinalRange) ? string.(collect(x)) : isa(x, Vector{Int}) ? string.(x) : isa(x, Vector{String}) ? x : isa(x, String) ? [x] : nothing
end

function agora()	# Must put this in a separate function because I want to use the keywords year, month, etc
	t = now()-Day(5)	# 5 days ago because the 5 in ERA5 means that the most recent data is 5 days ago.
	return string(year(t)), string(month(t)), string(day(t)), string(hour(t))
end
