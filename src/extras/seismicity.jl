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
                      mindepth=0, maxdepth=0, last::Union{Int, String}=0, year::Int=0, printurl::Bool=false, layers=3, legend=true, show=true, kw...)
	d = KW(kw)
	_last = ((isa(last, Int) ? last : 0), isa(last, String) ? last : "")
	_seismicity(d, string(starttime), string(endtime), Float64(minmagnitude), Float64(mindepth), Float64(maxdepth), _last, year, printurl, layers, legend==1, show==1)
end
function _seismicity(d::Dict{Symbol, Any}, starttime::String, endtime::String, minmagnitude::Float64, mindepth::Float64,
                     maxdepth::Float64, last::Tuple{Int, String}, year::Int, printurl::Bool, layers::Int, legend::Bool, show::Bool)

	(layers != 3 && layers != 4) && error("Only 3 or 4 (depth) layers are allowed.")
	# Ask NEWEST-FIRST, with an explicit limit. The service caps one answer at 20000 records and the
	# cap keeps the FRONT of the ordering, so 'time-asc' silently drops the RECENT end of a query that
	# overruns it (and with no explicit limit the service errors instead of answering). The records are
	# sorted back into ascending time after reading, so what comes back is in the same order as always.
	url = "https://earthquake.usgs.gov/fdsnws/event/1/query.csv?format=csv&orderby=time&limit=$USGS_EVENT_LIMIT&minmagnitude=$minmagnitude"

	url = helper_get_date_interval(d, last, url, starttime, endtime, year, "&starttime=", "&endtime=")	# See if a period was requested
	url = usgs_endtime_whole_day(url)		# An 'endtime' as a bare date means MIDNIGHT, losing the end day

	if ((opt_R::String = parse_R(d, "")[2]) != "")
		(opt_R[end] == 'r') && error("Region as lon_min/lat_min/lon_max/lat_max form is not supported here.")
		!contains(opt_R, '/') && (opt_R = " " * coast(getR=opt_R[4:end]))
		contains(opt_R, "NaN") && (@warn("Bad 'region' argument. Defaulting to global."); opt_R = " -R-180/180/-90/90")
		spli = split(opt_R[4:end], '/')
		x1, x2, y1, y2 = usgs_query_box(parse.(Float64, spli[1:4])...)	# opt_R itself is left alone (it draws the map)
		url *= "&minlongitude=" * @sprintf("%.6g", x1)
		url *= "&maxlongitude=" * @sprintf("%.6g", x2)
		url *= "&minlatitude="  * @sprintf("%.6g", y1)
		url *= "&maxlatitude="  * @sprintf("%.6g", y2)
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
	no_plot = (find_in_dict(d, [:data])[1] !== nothing)
	D = usgs_events(url, no_plot)
	(D === nothing) && (println("\tThe query return an empty result."); return nothing)

	no_plot && return D			# No map, just return the data.

	Vd::Int = get(d, :Vd, 0)
	name_bak::String = hlp_desnany_str(d, [:savefig, :figname, :name])	# Tmp remove it
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

	_, opt_S = parse_opt_S(d, view(D, :, 4))

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
	st = (starttime != "") ? starttime : string(Date(now() - Dates.Day(30)))
	et = (endtime != "") ? endtime : string(Date(now()))
	legend && seislegend(; title="From "*st*" to "*et, cmap=C, mags=ms, pos="JBC+o0/1c+w12c/2.3c", d...)
end

# ------------------------------------------------------------------------------------------------------
const USGS_EVENT_LIMIT = 20000		# The FDSN service's own ceiling on the number of records in one answer

"""
    W, E, S, N = usgs_query_box(W, E, S, N)

Turn a region into a box the USGS FDSN service accepts. A region can legitimately arrive as something
that is not a legal query box — a map view fitted a hair wider than the world (-180.5/180.5/-90.5/90.5),
or a Pacific window that runs past +180 (150/210). The service answers HTTP 400 for a latitude outside
±90 and for a longitude outside ±360, so:

- latitudes are clamped;
- a full turn (or more) of longitude collapses to the whole world;
- a window crossing the dateline is shifted WHOLE into the negative half. -210/-150 asks for exactly
  the same 60 degrees of Pacific that 150/210 means, and it keeps `maxlongitude` at or below +180.
"""
function usgs_query_box(W::Float64, E::Float64, S::Float64, N::Float64)::NTuple{4, Float64}
	S, N = min(S, N), max(S, N)
	S = clamp(S, -90.0, 90.0);	N = clamp(N, -90.0, 90.0)
	W, E = min(W, E), max(W, E)
	(E - W >= 360.0) && return (-180.0, 180.0, S, N)
	if (E > 180.0)
		k = ceil((E - 180.0) / 360.0);		W -= 360.0 * k;		E -= 360.0 * k
	end
	(W < -360.0) && return (-180.0, 180.0, S, N)		# Nothing sane left to ask for
	return (W, E, S, N)
end

# ------------------------------------------------------------------------------------------------------
# An 'endtime' given as a bare date means MIDNIGHT that morning, so the whole of the end day is thrown
# away. Extend it to the end of that day. Done here and not in helper_get_date_interval() because that
# helper is shared with weather(), which talks to a different service.
function usgs_endtime_whole_day(url::String)::String
	((k = findfirst("endtime=", url)) === nothing) && return url
	(first(k) > 1 && url[first(k)-1] != '&' && url[first(k)-1] != '?') && return url		# 'starttime=' & friends
	i = last(k) + 1										# First char of the value
	j = something(findnext('&', url, i), lastindex(url) + 1) - 1
	return occursin('T', url[i:j]) ? url : url[1:j] * "T23:59:59" * url[j+1:end]
end

# ------------------------------------------------------------------------------------------------------
# Fetch `url` into MEMORY and hand back the answer as one String. No file is written anywhere.
# Downloads first (in-process), curl only as the fallback — this service resets the connection now and
# then and curl gets through where Downloads does not. curl's stdout is read, so it writes nothing either.
function usgs_download(url::String)::String
	for k = 1:3							# This service resets the connection now and then, curl included
		try
			txt::String = ""
			if (k == 1)
				io = IOBuffer();	Downloads.download(url, io);	txt = String(take!(io))
			else
				txt = read(`curl -s --show-error --fail --max-time 180 $url`, String)
			end
			!isempty(txt) && return txt
		catch err
			(k == 3) && rethrow(err)
			@warn("Download of the USGS query failed ($(err)). Retrying with curl.")
		end
	end
	error("The USGS query returned nothing.")
end

# ------------------------------------------------------------------------------------------------------
# The csv answer -> the GMTdataset, parsed in memory. No csv reader is needed: the five columns wanted
# (time, latitude, longitude, depth, mag) are the FIRST five of the service's fixed layout and all of
# them come BEFORE its one quoted field ('place', column 14), so a plain comma split is exact. What is
# built is what `gmtread(file, h=1, i="2,1,3,4,0")` used to build: columns lon,lat,depth,mag[,time],
# the rest of each record kept as trailing text, and the same colnames/Timecol. `wanttime` adds the
# time column (the 'data' option); without it the columns are the four the map needs.
# Records come back newest-first (see the url) and are sorted here into ascending time.
function usgs_events(url::String, wanttime::Bool)::Union{GMTdataset{Float64, 2}, Nothing}
	txt::String = usgs_download(url)
	lon, lat, dep, mag, t, rest = Float64[], Float64[], Float64[], Float64[], Float64[], String[]
	hdr = true
	for line in split(txt, '\n')
		s = strip(line)
		isempty(s) && continue
		if (hdr)  hdr = false;	continue  end			# The one header line
		f = split(s, ','; limit=6)						# time,latitude,longitude,depth,mag,<rest>
		(length(f) < 5) && continue
		push!(t,   usgs_isotime(f[1]))
		push!(lat, usgs_num(f[2]));		push!(lon, usgs_num(f[3]))
		push!(dep, usgs_num(f[4]));		push!(mag, usgs_num(f[5]))
		push!(rest, length(f) == 6 ? String(f[6]) : "")
	end
	isempty(lon) && return nothing
	(length(lon) >= USGS_EVENT_LIMIT) &&
		@warn("The query hit the $(USGS_EVENT_LIMIT) events ceiling. Older events were dropped, not recent ones.")

	k = sortperm(t)										# Back to ascending time, as 'time-asc' used to give
	mat = wanttime ? [lon[k] lat[k] dep[k] mag[k] t[k]] : [lon[k] lat[k] dep[k] mag[k]]
	coln = wanttime ? ["longitude", "latitude", "depth", "mag", "Time", "magType"] :
	                  ["longitude", "latitude", "depth", "mag", "magType"]
	D::GMTdataset{Float64, 2} = mat2ds(mat; text=rest[k], colnames=coln)
	wanttime && (D.attrib["Timecol"] = "5")
	return D
end

usgs_num(f::Union{String, SubString{String}})::Float64 =
	(s = strip(f); isempty(s) ? NaN : something(tryparse(Float64, s), NaN))

# The record's ISO-8601 instant ("2026-08-24T00:00:48.085Z") as seconds since 1970 (what gmtread's
# time column carried). NaN when unparsable, so one malformed row never kills the whole answer.
function usgs_isotime(f::Union{String, SubString{String}})::Float64
	s = strip(f)
	(length(s) < 19) && return NaN
	endswith(s, "Z") && (s = s[1:end-1])
	dt = tryparse(DateTime, String(s))
	return dt === nothing ? NaN : datetime2unix(dt)
end

# ------------------------------------------------------------------------------------------------------
function helper_get_date_interval(d::Dict{Symbol, Any}, last::Tuple{Int, String}, url, starttime::String, endtime::String, year::Int, sstart, send)
	# Helper function used both in seismicity and weather functions.

	function test_last(last::Tuple{Int, String}, msg::String)
		# If option 'last' was used when it shouldn't return true a blank it
		(last[1] != 0 || last[2] != "") && (@warn(msg); return (0, ""))
		return last
	end

	if (year != 0)
		last = test_last(last, "Options 'year' and 'last' are incompatible. Dropping 'last'.")
		starttime = "$year-01-01"
		endtime = (parse(Int,string(today())[1:4]) == year) ? string(today()) : "$year-12-31"
	end
	(starttime === "") && (starttime = hlp_desnany_str(d, [:startdate, :start_date, :start_time]))
	(endtime === "")   && (endtime   = hlp_desnany_str(d, [:enddate, :end_date, :end_time]))
	(starttime !== "") && (last = test_last(last, "Options 'starttime' and 'last' are incompatible. Droping 'last'."))
	(endtime   !== ""  && starttime === "") && (@warn("Gave a 'endtime' but not a 'starttime'. Ignoring it."); endtime = "")
	(last[1] > 0)      && (starttime = string(Date(now() - Dates.Day(last[1]))))
	if (last[2] !== "")			# Requests of Weeks, Months, Years
		_last = lowercase(last[2])
		if     ((ind = findfirst('y', _last)) !== nothing)  starttime = string(Date(now() - Dates.Year(parse(Int, _last[1:ind-1]))))
		elseif ((ind = findfirst('m', _last)) !== nothing)  starttime = string(Date(now() - Dates.Month(parse(Int, _last[1:ind-1]))))
		elseif ((ind = findfirst('w', _last)) !== nothing)  starttime = string(Date(now() - Dates.Week(parse(Int, _last[1:ind-1]))))
		end
		(send == "&end_date=") && (endtime = Date(now()))	# Because weather() needs an end date too.
	end
	(starttime != "") && (url *= sstart * starttime)
	(endtime != "")   && (url *= send   * endtime)
	return url
end

# ------------------------------------------------------------------------------------------------------
"""
    seislegend(; title="", font=(16,"Times-Roman"), cmap=GMTcpt(), mags=Float64[], lowermag=3.0, kw...)

Adds a legend to plots produced by `seismicity` function. All options are optional.

- `cmap`: A colormap (CPT) with either 3 or 4 colors only. This is used to paint symbols according to depth layer.
- `mags`: The seizes in cm for the magnitudes 3 to 9.
- `title`: The legend head title.
- `font`: The legend head font.
"""
function seislegend(; title="", font=(16,"Times-Roman"), cmap=GMTcpt(), mags::VecOrMat=Float64[], lowermag=3.0, kw...)
	d = KW(kw)
	_seislegend(d, string(title), font, cmap, vec(Float64.(mags)), Float64(lowermag))
end
function _seislegend(d::Dict{Symbol,Any}, title::String, font, cmap::GMTcpt, mags::Vector{Float64}, lowermag::Float64)
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
	!is_in_kwargs(d, [:D :pos :position]) && (d[:D] = (paper=(0.25,0.25), width=14, justify=:BL, spacing=1.2))
	#(is_in_dict(d, [:D :pos :position]) === nothing) && (d[:D] = (paper=(0.25,0.25), width=14, justify=:BL, spacing=1.2))
	!is_in_kwargs(d, [:C :clearance]) && (d[:C] = (0.25,0.25))
	!is_in_kwargs(d, [:F :box]) && (d[:F] = (pen=0.5, fill=:azure1))
	!is_in_kwargs(d, [:R :region :limits]) && (d[:R] = (0,10,0,4))
	!is_in_kwargs(d, [:par]) && (d[:par] = (:FONT_ANNOT_PRIMARY, 8))		# Shitty solution. Must use conf for other configs

	legend("", (
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
	), true, true, d)
end
