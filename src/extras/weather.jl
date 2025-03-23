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
