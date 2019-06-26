# Compass

This exmple plots a compass in a map, including a magnetic component.
Because several parameters used here deviate from the defaults we have
an unusualy large list of parameter settings

```julia
basemap(region=(-7,7,-6,6), proj=:Mercator,
        compass=(map=true, anchor=(0,0), width=6, dec=-14.5, annot=(45,10,5,30,10,2),
                 rose_primary=(0.25,:blue), rose_secondary=0.5, labels="", justify=:CM),
        par=(FONT_ANNOT_PRIMARY=9, FONT_LABEL=14, FONT_TITLE=24, MAP_TITLE_OFFSET="7p",
             MAP_VECTOR_SHAPE=0.5, MAP_TICK_PEN_SECONDARY="thinner,red", MAP_TICK_PEN_PRIMARY="thinner,blue"),
        figsize=15, fmt=:png, savefig="compass", show=true)
```

```@raw html
<img src="../figs/compass.png" width="500" class="center"/>
```