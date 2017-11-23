# Draw Frames

## Geographic basemaps

Geographic basemaps may differ from regular plot axis in that some projections support a “fancy”
form of axis and is selected by the MAP_FRAME_TYPE setting. The annotations will be formatted according
to the FORMAT_GEO_MAP template and MAP_DEGREE_SYMBOL setting. A simple example of part of a basemap
is shown in Figure Geographic map border.

```julia
using GMT
basemap(R="-1/2/0/0.4", proj="M8", frame="a1f15mg5m S")
t = [-0.5 0 0 0.5
    -0.5 0 180 0.5
    0.375 0 0 0.125
    0.375 0 180 0.125
    1.29166666 0 0 0.04166666
    1.29166666 0 180 0.04166666];
GMT.xy!(t, symbol="v2p+e+a60", lw=0.5, fill="black", y_offset="-0.9", no_clip=true)
if (GMTver < 6)
    T = ["-0.5 0.05 annotation", "0.375 0.05 frame", "1.29166666 0.05 grid"];
else
    T = text_record([-0.5 0.05; 0.375 0.05; 1.29166666 0.05], ["annotation", "frame", "grid"]);
end
text!(T, F="+f9p+jCB", fmt="png", show=true)
```

!["B_geo_1"](figures/B_geo_1.png)