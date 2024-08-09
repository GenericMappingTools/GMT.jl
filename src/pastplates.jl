function pastplates(; time=100, proj="", title="time", coastlines=true,
    show=true, fmt="png", name="", data=false)
    if (coastlines)
        url = "https://gws.gplates.org/reconstruct/coastlines_low/?&time="
    else
        url = "https://gws.gplates.org/reconstruct/static_polygons/?time="
    end
    url *= string(time)
    coastlines && (url *= "&model=SETON2012&avoid_map_boundary")
    D = gdalread(url)
    (data == 1) && return D

    (proj == "") && (proj = "guess")
    plot(D, proj=proj, title="Time = $time", show=show, fmt=fmt)
end
