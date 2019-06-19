# Decorated_I

Plot a Decorated line

```julia
xy = sind.(collect(0:180)) .+ 4.5
lines(xy, limits=(-5,185,4,6), figsize=(16,8), pen=(1,:red),
      decorated=(dist=(2.5,0.25), symbol=:star, size=1,
                 pen=(0.5,:green), fill=:blue, dec2=true),
      title=:Decorated, fmt=:png, show=true)
```

```@raw html
<img src="../figs/decorated_I.png" width="400" class="center"/>
```