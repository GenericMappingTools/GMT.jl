# Draw Frames

## Geographic basemaps

Geographic basemaps may differ from regular plot axis in that some projections support a “fancy”
form of axis and is selected by the MAP_FRAME_TYPE setting. The annotations will be formatted according
to the FORMAT_GEO_MAP template and MAP_DEGREE_SYMBOL setting. A simple example of part of a basemap
is shown in Figure Geographic map border.

```julia
using GMT
basemap(R="-1/2/0/0.4", proj="M8", frame="a1f15mg5m S")
t = [-1.0 0 0 1.0
    0.25 0 0 0.25
    1.25 0 0 0.08333332];
GMT.xy!(t, symbol="v2p+b+e+a60", lw=0.5, fill="black", y_offset="-1.0", no_clip=true)
if (GMTver < 6)
    T = ["-0.5 0.05 annotation", "0.375 0.05 frame", "1.29166666 0.05 grid"];
else
    T = text_record([-0.5 0.05; 0.375 0.05; 1.29166666 0.05], ["annotation", "frame", "grid"]);
end
text!(T, text_attrib="+f9p+jCB", fmt="png", show=true)
```

!["B_geo_1"](figures/B_geo_1.png)

The machinery for primary and secondary annotations axes can be utilized for geographic basemaps. This may
be used to separate degree annotations from minutes- and seconds-annotations. For a more complicated basemap
example using several sets of intervals, including different intervals and pen attributes for grid lines and
grid crosses.

```julia
using GMT
basemap(region="-2/1/0/0.35", proj="M8", frame="pa15mf5mg5m wSe s1f30mg15m", MAP_FRAME_TYPE="fancy+",
	MAP_GRID_PEN_PRIMARY="thinnest,black,.", MAP_GRID_CROSS_SIZE_SECONDARY=0.25, MAP_FRAME_WIDTH=0.2,
	MAP_TICK_LENGTH_PRIMARY=0.25, FORMAT_GEO_MAP="ddd:mm:ssF", FONT_ANNOT_PRIMARY="+8", FONT_ANNOT_SECONDARY=12, fmt="png", show=1)
```

!["B_geo_2"](figures/B_geo_2.png)