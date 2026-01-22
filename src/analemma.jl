"""
	analemma(; lon=0, lat=0, hour=12, year=2024, lonlat=false, data=false, cmap=:turbo, kwargs...)

Plot the analemma.

The analemma is the figure-8 pattern traced by the Sun's position in the sky
when observed from the same location at the same mean solar time throughout the year.

### Arguments
- `lon` : Observer longitude in degrees.
- `lat` : Observer latitude in degrees. If both `lon` and `lat` are equal to zero (the default)
   we compute your approximate location using web service based your IP address
   (this adds a delay to the calculations).
- `year` : Year for calculation (default: 2026). This is of minor importance but things slowly change with time.
- `hour` : Local mean solar time hour (0-24, default: 12 = noon)
- `cmap` : Colormap for day-of-year coloring (default: :turbo)
- `lonlat=false`: If `true`, plot longitude vs latitude; if `false` (default), plot azimuth vs elevation.
- `data=false`: If `true`, return the CO2 data in a GMTdataset.
- Additional kwargs are passed to `plot`

### Example
```julia
analemma(lon=-9, lat=38.7)     # Noon analemma in Lisbon
analemma(lat=-23.5, hour=9)    # 9 AM analemma in tropics

D = analemma(lon=-9, lat=38.7, lonlat=true, data=true)   # Get analemma in lon,lat as a GMTdataset
```
"""

function analemma(; lon::Real=0, lat::Real=0, hour::Real=12, year::Int=2026,
				  lonlat=false, data=false, cmap=:turbo, kwargs...)
	d = KW(kwargs)
	if (lon == 0 && lat == 0)  lon, lat = get_my_lonlat()  end
	_analemma(Float64(lon), Float64(lat), year, Float64(hour), cmap, lonlat==1, data==1, d)
end

function _analemma(lon, lat, year, hour, cmap, lonlat::Bool, data::Bool, d)

	TZ = round(Int, 90 / 15)		# Approximate time zone from longitude
	n_days = Dates.isleapyear(year) ? 366 : 365
	ana = Matrix{Float64}(undef, n_days, 4)
	k = lonlat ? (1,2,3,4) : (3,4,1,2)		# lonlat: lon, lat, az, el ; else: az, el, lon, lat
	cnames = lonlat ? ["Lon", "Lat", "Azimuth", "Elevation"] : ["Azimuth", "Elevation", "Lon", "Lat"]

	hhmm = @sprintf("T%02d:%02d:00", floor(Int, hour), round(Int, getdecimal(hour) * 60))

	for day in 1:n_days
		date = Date(year, 1, 1) + Dates.Day(day - 1)
		datetime_str = Dates.format(date, "yyyy-mm-dd") * hhmm

		result = gmt(@sprintf("solar -I%g/%g+d%s+z%d -C", lon, lat, datetime_str, TZ))
		ana[day, 1], ana[day, 2], ana[day, 3], ana[day, 4] = result.data[k[1]], result.data[k[2]], result.data[k[3]], result.data[k[4]]
	end

	D = mat2ds(ana)
	data && (D.colnames = cnames; return D)

	do_show = ((val = find_in_dict(d, [:show])[1]) === nothing) ? true : false	# Default is to show
	C = makecpt(cmap=cmap, range=(1, n_days))
	plot(D, marker="c", markersize="4p", cmap=C, zcolor=collect(1:n_days), colorbar=(xlabel="Day of year",),
	     xlabel= lonlat ? "Longitude" : "Azimuth", ylabel= lonlat ? "Latitude"  : "Elevation",
		 title=@sprintf("Analemma %02d:00 lat=%.1f", floor(Int, hour), lat), show=do_show, d...)
end

# ---------------------------------------------------------------------------------------------------
"""
	sunsetrise(; lon=0, lat=0, year=2026, TZ::Int=50, raise=false, both=false, data=false; kwargs...)

Plot sunrise and sunset times throughout the year for a given location.

Uses GMT's `solar` module for calculations.

### Arguments
- `lon` : Observer longitude in degrees.
- `lat` : Observer latitude in degrees. If both `lon` and `lat` are equal to zero (the default)
   we compute your approximate location using web service based your IP address
   (this adds a delay to the calculations).
- `year` : Year for calculation (default: 2026). This is of minor importance but things slowly change with time.
- `TZ` : Time zone offset in hours. By default (when the default value of 50 stands) we compute
  it from longitude but it doesn't take into account daylight saving time.
- `raise=false`: If `true`, plot sunrise times; if `false`, plot sunset times.
- `both=false`: If `true`, plot both sunrise and sunset times.
- `data=false`: If `true`, return the sunset or sunrise data (depending on `rise`)
   or both if `both=true` in a GMTdataset.
- Additional kwargs are passed to `plot`

### Returns
If `data=true` returns a GMTdataset if `both` is not set (false) or a tuple of GMTdatasets with
sunrise and sunset data if `both=true`. Returns `nothing` if a plot is made.

Example
-------
```julia
	sunsetrise(lat=38.7, lon=-9)  # Lisbon
	sunsetrise(lat=60)            # High latitude with long summer days

	Dsrise, Dsset = sunsetrise(lat=38.7, lon=-9, both=true, data=true)  # Get sunrise/set data
```
"""
function sunsetrise(; lon=0.0, lat=0.0, year::Int=2026, TZ::Int=50, raise=false, both=false,
                    data::Bool=false, kwargs...)
	d = KW(kwargs)
	_TZ = (TZ == 50) ? round(Int, (datetime2unix(now()) - datetime2unix(now(UTC))) / 3600) : TZ
	if (lon == 0 && lat == 0)  lon, lat = get_my_lonlat()  end
	_sunsetrise(Float64(lon), Float64(lat), year, _TZ, raise==1, both==1, data==1, d)
end
function _sunsetrise(lon, lat, year::Int, TZ::Int, raise::Bool, both::Bool, data::Bool, d)

	n_days = Dates.isleapyear(year) ? 366 : 365
	sunrise = Matrix{Float64}(undef, n_days, 2)
	both && (sunset = Matrix{Float64}(undef, n_days, 2))
	sun = sunrise			# For raise or set
	ind = raise ? 5 : 6		# 5 for raise, 6 for set

	for day in 1:n_days
		date = Date(year, 1, 1) + Dates.Day(day - 1)
		datetime_str = Dates.format(date, "yyyy-mm-dd")

		# Use solar: columns are lon, lat, az, el, sunrise, sunset, noon, duration, ...
		# Values are in fraction of day, multiply by 24 to get hours
		result = gmt(@sprintf("solar -I%g/%g+d%s+z%d -C", lon, lat, datetime_str, TZ))
		ydec = datetime2unix(yeardecimal(year + (day - 0.5) / n_days))
		both ? (sunrise[day, 1] = ydec; sunrise[day, 2] = result[1,5] * 24;
		        sunset[day, 1]  = ydec; sunset[day, 2]  = result[1,6] * 24) :
		       (sun[day, 1] = ydec; sun[day, 2] = result[1,ind] * 24)
	end
	
	doy = dayofyear(today())

	both ? (Dsr = mat2ds(sunrise); settimecol!(Dsr, col=1); Dss = mat2ds(sunset); settimecol!(Dss, col=1)) :
	       (Dsun = mat2ds(sun); settimecol!(Dsun, col=1))

	data && return both ? (Dsr, Dss) : Dsun

	title = @sprintf("%s lon=%.2f lat=%.2f", raise ? "Sunrise" : both ? "Sunrise/Sunset" : "Sunset", lon, lat)
	y_label = "Hour (UTC $(TZ))"
	xaxis_nt = (axes=:Sen, annot=1, annot_unit=:month, ticks=7, ticks_unit=:day_date)
	yaxis_nt = (annot=15, annot_unit=:minute2, ticks=5, ticks_unit=:minute2, label=y_label)
	par = (FORMAT_DATE_MAP="o", FORMAT_TIME_PRIMARY_MAP="abbreviated")

	do_show = ((val = find_in_dict(d, [:show])[1]) === nothing) ? true : false	# Default is to show
	fmt::String = ((val = find_in_dict(d, [:fmt])[1]) !== nothing) ? arg2str(val)::String : FMT[]::String
	savefig = ((val = find_in_dict(d, [:savefig :figname :name])[1]) !== nothing) ? arg2str(val)::String : nothing
	opt_R = ((val = find_in_dict(d, [:R :region :limits])[1]) !== nothing) ? val : "tightx"
	both ? plotyy(Dsr, Dss, yaxis=yaxis_nt, title=title, conf=par, R=opt_R, lw=1; d...) :
		   plot(Dsun, xaxis=xaxis_nt, yaxis=yaxis_nt, title=title, lc="#0072BD", lw="1p", conf=par, R=opt_R; d...)

	use_back  = (CTRL.limits[7] == 0.0 && CTRL.limits[8] == 0.0)	# Only used if -Rtight
	back_lims = CTRL.limits[1:4]
	both ? plot!([Dsr[doy:doy,1:2]; Dss[doy:doy,1:2]], marker=:circle, mc=:yellow, ms="6p", mec=:black, fmt=fmt, name=savefig, show=do_show) :
	       plot!(Dsun[doy:doy,1:2], marker=:circle, mc=:yellow, ms="6p", mec=:black)

	if (!both)
		lims = use_back ? back_lims : CTRL.limits[7:10]
		opt_R=@sprintf("%f/%f/%ft/%ft", lims[1], lims[2], lims[3]/24, lims[4]/24)
		basemap!(frame=(axes=:W, annot="15m", ticks="5m", label=y_label), axis2=(annot=1, annot_unit=:hour), R=opt_R, name=savefig,
		         fmt=fmt, conf=(FORMAT_CLOCK_MAP="-hham", FONT_ANNOT_PRIMARY="+9p", TIME_UNIT="d"), show=do_show)
	end
end

# ---------------------------------------------------------------------------------------------------
"""
	keeling(; data::Bool=false, kwargs...)

Plot the Keeling Curve - atmospheric CO2 concentration measured at Mauna Loa since 1958.

Data is fetched from NOAA (https://gml.noaa.gov/webdata/ccgg/trends/co2/co2_mm_mlo.txt).

### Arguments
- `data::Bool=false`: If `true`, return the CO2 data in a GMTdataset.
- Additional kwargs are passed to `plot`

### Returns
A GMTdataset of CO2 data if `data=true`, or `nothing` if a plot is made.

### Examples
```julia
D = keeling(data=true)          # Get CO2 data as GMTdataset

keeling(lw=1, lc=:darkgreen)    # Plot with custom line width and color
```
"""
function keeling(; data::Bool=false, kwargs...)

	opt_i = data ? "2,3,4,5,6,7" : "2,3"
	D = gmtread("https://gml.noaa.gov/webdata/ccgg/trends/co2/co2_mm_mlo.txt", i=opt_i)
	setdecyear_time!(D)		# First column is decimal year, make a Time column
	if (data)
		D.colnames[2:end] = ["monthly_average", "de-seasonalized", "#days", "st.dev_of_days", "unc.of_mon_mean"]
		return D
	end

	plot(D, lw=0.75, lc=:red, xlabel="Year", ylabel="CO@-2@- (ppm)", title="Keeling Curve - Mauna Loa CO@-2@-",
	     show=true; kwargs...)
end

# ---------------------------------------------------------------------------------------------------
"""
	enso(; data::Bool=false, data0::Bool=false, kwargs...)

Retrieve ENSO (El Niño-Southern Oscillation) data.

Data is fetched from NOAA (https://www.cpc.ncep.noaa.gov/data/indices/oni.ascii.txt). If plotted,
El Niño events (positive) shown in red, La Niña (negative) in blue.
A plot is generated by default unless `data` or `data0` is set to `true`, case in which the index data
is returned and no figure is generated.

### Arguments
- `data::Bool=false`: If `true`, return the computed ENSO data as a [date index] pair in a GMTdataset.
- `data0::Bool=false`: If `true`, similar to above, but return a 3 column matrix with second column
   all equal to zero. This is useful for plotting purposes when using the `wiggle` function.
- `kwargs...`: Additional keyword arguments passed to underlying plotting function.

Note, the plot is created with a figure size of (14,4), with x-axis labeled "Year" and title
"Oceanic Niño Index", but this can be overwritten via the `xlabel` and `title` options. The option
`data0` returns a dataset with a zero middle column useful for plotting with `wiggle`. The default
plotting command is:
```julia
wiggle(D, track=:faint, ampscale=1.25, figsize=(14,4), R=:tightx, fill=["red+p", "blue+n"], pen=0,
	       xlabel="Year", title="Oceanic Niño Index", show=true; kwargs...)
```
where `D` is the dataset returned when `data0=true`. You can use this to customize a new plot further.

And, it seems that the NOOA site sometimes is quite slow to respond, so be patient!

### Returns
ENSO data indices in a GMTdataset or `nothing` depending on the `data` and `data0` flags.

### Examples
```julia
enso()			# Plot ENSO index
```
"""
function enso(; data::Bool=false, data0::Bool=false, kwargs...)

	# Incredibly, Downloads.download("https://www.cpc.ncep.noaa.gov/data/indices/oni.ascii.txt")
	# hangs most of times or is very slow, but gmtread that also uses curl is fast and works fine!
	# The file, however, has this struct: SEAS  YR  TOTAL  ANOM, where SEAS is a 3-letter code for
	# overlapping 3-month seasons (DJF, JFM, FMA, etc). Being a text we must resort to use -fa but
	# that looses the first column (SEAS), so we read only YR and ANOM (cols 1 and 3 in -fa mode).
	# We then reconstruct the decimal year from the row number.
	opt_i = data ? "1,3" : "0,1,3"
	D = gmtread("https://www.cpc.ncep.noaa.gov/data/indices/oni.ascii.txt", h=1, f=:a, i=opt_i)
	if (data)
		for k = 1:size(D, 1)  D[k, 1] += (rem(k,12) - 0.5) / 12  end
	else
		for k = 1:size(D, 1)  D[k, 1] = D[k, 2] + (rem(k,12) - 0.5) / 12; 	D[k, 2] = 0.0  end
	end
	
	for k = 12:12:size(D, 1)  D[k, 1] = D[k-1, 1] + 1.0/12  end		# Because rem(k,12) = 0 for decembers and the -0.5 we receeded 1 year 
	D.ds_bbox = D.bbox = data ? [extrema(view(D,:,1))..., D.ds_bbox[end-1:end]...] :	# Must update the bbox's
	                            [extrema(view(D,:,1))..., 0.0, 0.0, D.ds_bbox[end-1:end]...]

	setdecyear_time!(D)		# First column is decimal year, make a Time column
	D.colnames[data ? 2 : 3] = "ONI"		# Will be wrong for plotting but in that case we don't care

	(data || data0) && return D

	wiggle(D, track=:faint, ampscale=1.25, figsize=(14,4), R=:tightx, fill=["red+p", "blue+n"], pen=0,
	       xlabel="Year", title="Oceanic Niño Index", show=true; kwargs...)
end
