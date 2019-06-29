# Spiders

Plot Pies, Wedges or Web (spiders). They are all synonims. We show here
three different ways of plotting this symbol (depending of its complexity)

```julia
plot([0.5 0.5 30 100], limits=(0,6,0,3), figscale=2.5, frame="afg",
     marker=:wedge, ms=5, fill=:lightyellow, ml=2)
plot!([2.5 0.5 30 100], marker=:wedge, ms=5, fill=:yellow)
plot!([0.5 1.75 30 100], marker=(web=true, size=5, arc=0.7, pen=(0.5,:red)), ml=1)
plot!([2.5 1.75 30 100], marker=(web=true, size=5, radial=15),
      fill=:lightyellow, ml=0.5)
# But we can also send the Web angle info via marker and use a Tuple as argument.
plot!([4.5 1.75], marker=(:web, [30 330], (size=5, arc=0.7, radial=15, pen=0.25)),
      fill=:pink, ml=1, fmt=:png, show=true)
```

```@raw html
<img src="../figs/spiders.png" width="500" class="center"/>
```