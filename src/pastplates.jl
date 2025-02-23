"""
    pastplates(; time=100, proj="", title="time", coastlines=true, fmt="png", name="", data=false, show=true)

Plots the reconstruction of the past plates at a given time. Data is extracted from the GPLATES
https://gws.gplates.org website.

# Kwargs
- `time`: Time in Ma. Default is 100 Ma.
- `proj`: A projection string like that used, or example, in `coast()`. 
- `title`: Title of the plot
- `coastlines`: A boolean indicating if want to plot the coastlines.
- `fmt`: Format of the plot (Default is `png`)
- `name`: Name of the plot. Instead of using a default name, provide one and figure will be saved with that name.
- `data`: If true `pastplates` return the data in a form of a vector of `GMTdataset` instead of plotting it.
   The default is produce a minimally nice plot but for further enhancements, download the data and make a plot yourself. 
- `show`: If true (the default), automatically show the plot (ignored if `data=true`).

# Examples
```julia
pastplates()
```
"""
function pastplates(; time=100, proj="", title="time", coastlines=true, fmt="png", name="", data=false, Vd=0, show=true)
	(proj == "") && (proj = "guess")
	if (coastlines)
		url = "https://gws.gplates.org/reconstruct/coastlines_low/?&time="
	else
		url = "https://gws.gplates.org/reconstruct/static_polygons/?time="
	end
	url *= string(time)
	coastlines && (url *= "&model=SETON2012&avoid_map_boundary")
	D = gdalread(url)
	(data == 1) && return D

	plot(D, proj=proj, title="Time = $time Ma", show=show, name=name, fmt=fmt, Vd=Vd)
end
