# Bezier

Plot a Bezier curve

```julia
x = [0, 1, 2, 3, 2];  y = [0, 1, 1, 0.5, 0.25];
lines(x,y, limits=(-1,4,-0.5,2.0), scale=3.0, lw=1, markerfacecolor=:red,
      size=0.5, bezier=true, title="Bezier curve", fmt=:png, show=true)
```

```@raw html
<img src="../figs/bezier.png" width="400" class="center"/>
```