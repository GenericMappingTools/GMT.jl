"""
    seismicity(starttime="", endtime="", minmagnitude=3, mindepth=0, maxdepth=0, last=0, year=0, printurl=false, show=true, kw...)

Make automatic maps of of world-wide seismicity obtained from the USGS Earthquake Hazards Program page at
https://earthquake.usgs.gov

- `starttime`: Limit to events on or after the specified start time. NOTE: All times use ISO8601 Date/Time format
    OR a DateTime type. Default is NOW - 30 days.
- `endtime`: Limit to events on or before the specified end time. Same remarks as for `starttime`. Default is present time.
- `minmagnitude`: Limit to events with a magnitude larger than the specified minimum.
- `mindepth`: Limit to events with depth more than the specified minimum (km positive down).
- `maxdepth`: Limit to events with depth less than the specified maximum (km positive down).
- `last`: If value is an integer (*e.g.* `last=90`), select the events in the last n days. If it is a string
   than we expect that it ends with a 'w'(eek), 'm'(onth) or 'y'(ear). Example: `last="2Y"` (period code is caseless)
- `year`: An integer, restrict data download to this year.
- `printurl`: Print the url of the requested data.
- `circle`: A 3 elements Tuple or Array with ``lon,lat,radius``, where ``radius`` is in km, to perform a circle search.
- `data`: The default is to make a seismicity map but if the `data` option is used (containing whatever)
    we return the data in a ``GMTdataset`` 
- `figname`: $(opt_savefig)
- `land`: By default we paint the continents with the "burlywood" color. Like in the ``coast`` module, use
   `land=`"othercolor" to replace it.
- `layers`: By default we divide depth into three layers; 1-100, 100-300 and > 300 km, Use `layers=4` to subdivide
    top layer into 0-50 and 50-100 km.
- `legend`: By default we plot a legend. Particular options for the legend command (e.g. `pos`, `box`, etc) are passed
    via the `kw...` options. Use `legend=false` to have no legend.
- `ocean`: By default we paint the oceans with the "lightblue" color. Use `ocean=`"othercolor" to replace it.
- `region`: The region of interest. By default it is [-180 180 -90 90] but one may pass a sub-region like
    all other modules that accept this option (e.g. ``coast``)
- `proj`: By default we select an appropriate projection based on the `region` extents, but that may be overridden
    by specifying a `proj=xxx` like, for example, in ``coast``.
- `size`: Can be a scalar to plot all events with same size. This size is expected to be in cm but > 1 it is interpreted
    to be in points.
    - `size=[min_sz max_sz]` will scale linearly min/max magnitude to have sizes `min_sz/max_sz`
    - `size=([min_sz max_sz], [min_mag max_mag])` will scale linearly `min_mag/max_mag` magnitude to have sizes `min_sz/max_sz`
    - `size=(fun, [min_sz max_sz] [, [min_mag max_mag]])` does the same as above but the transformation is determined
       by the function 'fun'. Possibles functions are ``exp10``, ``exp``, ``pow`` and ``sqrt``. In the ``pow`` case
       we must pass in also the exponent and the syntax is: `size=((pow,2), [min_sz max_sz])` to have a square scaling.
- `show`: By default this function shows the plot (when no `data` option). Use `show=false` to prevent that (and leave
    the figure open to accept more plots from posterior commands.)

### Examples
```julia
    seismicity(size=8)
    seismicity(marker=:star, size=[3 10])
    seismicity(size=(exp10, [2 12], [3 9]))
```
"""
function seismicity(; starttime::Union{DateTime, String}="", endtime::Union{DateTime, String}="", minmagnitude=3,
                      mindepth=0, maxdepth=0, last=0, year=0, printurl::Bool=false, layers=3, legend=true, show=true, kw...)

	(layers != 3 && layers != 4) && error("Only 3 or 4 (depth) layers are allowed.")
	d = KW(kw)
	url = "https://earthquake.usgs.gov/fdsnws/event/1/query.csv?format=csv&orderby=time-asc&minmagnitude=$minmagnitude"

	url = helper_get_date_interval(d, last, url, starttime, endtime, year=year, sstart="&starttime=", send="&endtime=")	# See if a period was requested

	#=
	(starttime != "" && last != 0) && (@warn("Options 'starttime' and 'last' are incompatible. Droping 'last'."); last=0)
	(endtime != "" && starttime == "") && (@warn("Gave a 'endtime' but not a 'starttime'. Ignoring it."); endtime = "")
	(isa(last, Integer) && last > 0) && (starttime = string(Date(now() - Dates.Day(last))))
	if (isa(last, String))			# Requests of Weeks, Months, Years
		_last = lowercase(last)
		if     ((ind = findfirst('y', _last)) !== nothing)  starttime = Date(now() - Dates.Year(parse(Int, _last[1:ind-1])))
		elseif ((ind = findfirst('m', _last)) !== nothing)  starttime = Date(now() - Dates.Month(parse(Int, _last[1:ind-1])))
		elseif ((ind = findfirst('w', _last)) !== nothing)  starttime = Date(now() - Dates.Week(parse(Int, _last[1:ind-1])))
		end
	end
	(starttime != "") && (url *= "&starttime=" * string(starttime))
	(endtime != "") && (url *= "&endtime=" * string(endtime))
	=#
	if ((opt_R::String = parse_R(d, "")[2]) != "")
		(opt_R[end] == 'r') && error("Region as lon_min/lat_min/lon_max/lat_max form is not supported here.")
		!contains(opt_R, '/') && (opt_R = " " * coast(getR=opt_R[4:end]))
		contains(opt_R, "NaN") && (@warn("Bad 'region' argument. Defaulting to global."); opt_R = " -R-180/180/-90/90")
		spli = split(opt_R[4:end], '/')
		x1, x2 = parse.(Float64, spli[1:2])
		x2 > 180 && (spli[1] = @sprintf("%.6g", x2-180-(x2-x1)); spli[2] = @sprintf("%.6g", x2-180);)
		url *= "&minlongitude="*spli[1]
		url *= "&maxlongitude="*spli[2]
		url *= "&minlatitude="*spli[3]
		url *= "&maxlatitude="*spli[4]
	end
	(opt_R == "") && (opt_R = " -Rd")
	if (((val = find_in_dict(d, [:circle])[1]) !== nothing) && length(val) == 3)
		c::Vector{Float64} = [Float64.(val)...]
		url *= "&longitude=$(c[1])"
		url *= "&latitude=$(c[2])"
		url *= "&maxradiuskm=$(c[3])"
	end
	(mindepth > 0) && (url *= "&mindepth=$mindepth")
	(maxdepth > 0) && (url *= "&maxdepth=$maxdepth")

	printurl && println(url)
	file = Downloads.download(url, "_query.csv")
	no_plot = (find_in_dict(d, [:data])[1] !== nothing)
	opt_i = no_plot ? "2,1,3,4,0" : "2,1,3,4"
	D = gmtread(file, h=1, i=opt_i)
	rm(file)
	isempty(D) && (println("\tThe query return an empty result."); return nothing)

	no_plot && return D			# No map, just return the data.

	Vd::Int = get(d, :Vd, 0)
	name_bak::String = ((val = find_in_dict(d, [:savefig :figname :name])[1]) !== nothing) ? string(val) : ""	# Tmp remove it
	(is_in_dict(d, [:G :land]) === nothing) && (d[:G] = "burlywood")
	(is_in_dict(d, [:S :water :ocean]) === nothing) && (d[:S] = "lightblue")
	r = coast(; R=opt_R[4:end], A="1000", Vd=Vd, d...)
	(Vd == 2) && return r
	d = CTRL.pocket_d[1]
	(name_bak != "") && (d[:savefig] = name_bak)			# Restore the fig name
	C = (layers == 3) ? gmt("makecpt -Cred,green,blue -T0,100,300,10000") : gmt("makecpt -Cred,darkred,green,blue -T0,50,100,300,10000")

	_size_t = get(d, :size, nothing)
	# This gimn is because if size is a scalar we get the wrong answer below in parse_opt_S(). Don't know if its a bug or
	# just bad use. Since that fun is complex it's better not touch it and just make an array by duplicating the scalar.
	_size = (_size_t === nothing) ? _size_t : isa(_size_t, Number) ? [_size_t _size_t] : _size_t

	mag_size, opt_S = parse_opt_S(d, view(D, :, 4))

	if (opt_S == "" || endswith(opt_S, "7p"))
		@inbounds for k =1:size(D,1)  D[k,4] *= 0.02  end
		endswith(opt_S, "7p") && (opt_S = opt_S[1:end-2])	# parse_opt_S() was not meant to be used like this, need strip that 7p
	else
		if (length(opt_S) > 4 && isdigit(opt_S[5]))			# Fixed size in cm or pts, but NO other than pt UNITS allowed
			fac = opt_S[end] == 'p' ? 2.54/2 : 1.0
			siz = (fac == 1) ? parse(Float64, opt_S[5:end]) : parse(Float64, opt_S[5:end-1]) * fac	# Accept only pt as units
			opt_S = opt_S[1:4]								# Drop the size since it will be passed in D[:,4]
			(siz > 1) && ( siz *= 2.54/72)					# If size > 1, assume that it was given in points.
			@inbounds for k =1:size(D,1)  D[k,4] = siz  end
		end
	end
	opt_S = (opt_S == "") ? "c" : opt_S[4:end]

	see = !legend ? show : false
	plot!(D[:,1:4]; ml="faint", S=opt_S, C=C, show=see, Vd=Vd, d...)
	d = CTRL.pocket_d[1]
	d[:show] = show
	ms = (_size !== nothing) ? parse_opt_S(Dict{Symbol,Any}(:size => _size), [3., 4, 5, 6, 7, 8, 9])[1] : [3., 4, 5, 6, 7, 8, 9] .* 0.02
	st = (starttime != "") ? string(starttime) : string(Date(now() - Dates.Day(30)))
	et = (endtime != "") ? string(endtime) : string(Date(now()))
	legend && seislegend(; first=false, title="From "*st*" to "*et, cmap=C, mags=ms, pos="JBC+o0/1c+w12c/2.3c", d...)
end

# ------------------------------------------------------------------------------------------------------
function helper_get_date_interval(d, last, url, starttime, endtime; year::Int=0, sstart="&start_date=", send="&end_date=")
	# Helper function used both in seismicity and weather functions.
	if (year != 0)
		(last != 0) && (@warn("Options 'year' and 'last' are incompatible. Droping 'last'."); last=0)
		starttime = "$year-01-01"
		endtime = (parse(Int,string(today())[1:4]) == year) ? string(today()) : "$year-12-31"
	end
	(starttime == "") && ((val = find_in_dict(d, [:startdate :start_date :start_time])[1]) !== nothing) && (starttime = string(val)::String)
	(endtime == "")   && ((val = find_in_dict(d, [:enddate :end_date :end_time])[1]) !== nothing) && (endtime = string(val)::String)
	(starttime != ""  && last != 0)       && (@warn("Options 'starttime' and 'last' are incompatible. Droping 'last'."); last=0)
	(endtime   != ""  && starttime == "") && (@warn("Gave a 'endtime' but not a 'starttime'. Ignoring it."); endtime = "")
	(isa(last, Integer) && last > 0)      && (starttime = string(Date(now() - Dates.Day(last))))
	if (isa(last, String))			# Requests of Weeks, Months, Years
		_last = lowercase(last)
		if     ((ind = findfirst('y', _last)) !== nothing)  starttime = Date(now() - Dates.Year(parse(Int, _last[1:ind-1])))
		elseif ((ind = findfirst('m', _last)) !== nothing)  starttime = Date(now() - Dates.Month(parse(Int, _last[1:ind-1])))
		elseif ((ind = findfirst('w', _last)) !== nothing)  starttime = Date(now() - Dates.Week(parse(Int, _last[1:ind-1])))
		end
		(send == "&end_date=") && (endtime = Date(now()))	# Because weather() needs an end date too.
	end
	(starttime != "") && (url *= sstart * string(starttime))
	(endtime != "")   && (url *= send   * string(endtime))
	return url
end

# ------------------------------------------------------------------------------------------------------
"""
    seislegend(; title="", font=(16,"Times-Roman"), cmap=GMTcpt(), mags=Float64[], lowermag=3, kw...)

Adds a legend to plots produced by `seismicity` function. All options are optional.

- `cmap`: A colormap (CPT) with either 3 or 4 colors only. This is used to paint symbols according to depth layer.
- `mags`: The seizes in cm for the magnitudes 3 to 9.
- `title`: The legend head title.
- `font`: The legend head font.
"""
function seislegend(; title="", font=(16,"Times-Roman"), cmap=GMTcpt(), mags::VecOrMat=Float64[], lowermag=3, first=true,  kw...)
	# ...
	mags = isempty(mags) ? [3., 4, 5, 6, 7, 8, 9] .* 0.02 : mags

	nc = isempty(cmap) ? 3 : size(cmap.colormap, 1)
	if isempty(cmap)
		nt1 = (symbol1=(marker=:circ, dx_left=0., size=0.2, fill="red", dx_right=0.2, text="Shallow (0-100 km)"),
			symbol2=(marker=:circ, dx_left=0., size=0.2, fill="green", dx_right=0.2, text="Intermediate (100-300 km)"),
			symbol3=(marker=:circ, dx_left=0., size=0.2, fill="blue", dx_right=0.2, text="Very deep (> 300 km)"))
	else
		nt1 = NamedTuple()
		leg_d = (nc == 3) ? ["Shallow (0-100 km)", "Intermediate (100-300 km)", "Very deep (> 300 km)"] :
		                    ["Shallow (0-50 km)", "(50-100 km)", "Intermediate (100-300 km)", "Very deep (> 300 km)"]
		for k = 1:nc
			nt1 = (; nt1..., Symbol("symbol$k") => (marker=:circ, dx_left=0., size=0.2, fill=arg2str(cmap.colormap[k,:].*255), dx_right=0.2, text=leg_d[k]))
		end
	end

	i, lm = nc+1, lowermag
	nt2 = NamedTuple()
	for k = 1:numel(mags)
		nt2 = (; nt2..., Symbol("symbol$i") => (marker=:circ, dx_left=0.25, size=mags[k], pen=0.25, dx_right=0.75, text="M$lm"))
		i += 1; lm += 1
	end

	extra_vs = maximum(mags) > 0.3 ? 0.05 : 0.		# When symbols are big we need extra space between the hlines.
	d = KW(kw)
	!is_in_kwargs(kw, [:D :pos :position]) && (d[:D] = (paper=(0.25,0.25), width=14, justify=:BL, spacing=1.2))
	!is_in_kwargs(kw, [:C :clearance]) && (d[:C] = (0.25,0.25))
	!is_in_kwargs(kw, [:F :box]) && (d[:F] = (pen=0.5, fill=:azure1))
	!is_in_kwargs(kw, [:R :region :limits]) && (d[:R] = (0,10,0,4))
	!is_in_kwargs(kw, [:par]) && (d[:par] = (:FONT_ANNOT_PRIMARY, 8))		# Shitty solution. Must use conf for other configs

	legend((
       vspace=-0.25,
       header=(text= (title != "") ? title : "Map Legend", font=font),
       hline=(pen=0.75,),
       ncolumns = (nc == 3) ? "0.29 0.38 0.33" : "0.24 0.17 0.32 0.27",
	   vline=(pen=0.75, offset=0),
	   nt1...,
	   hline2=(pen=0.75,),
	   vline2=(pen=0.75, offset=0),
       vspace1=extra_vs,
	   ncolumns2=length(mags),
	   vline3=(pen=0.75, offset=0),
	   nt2...,
       vspace2=extra_vs,
	   hline3=(pen=0.75,),
	   vline4=(pen=0.75,),
	   ncolumns3=1,
	   label=(txt="Data from the US National Earthquake Information Center", justify=:R, font=(8,"Times-Italic")),
	); first=first, d...)
end
