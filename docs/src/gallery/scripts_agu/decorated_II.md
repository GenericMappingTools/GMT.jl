# Decorated_II

Plot a text decorated line

```julia
# Create a log spiral
t = linspace(0,2pi,100);
x = cos.(t) .* t;       y = sin.(t) .* t;
txt = " In Vino Veritas  - In Aqua, Rãs & Toads"
lines(x,y, region=(-4,7,-5.5,2.5), lw=2, lc=:sienna,
      decorated=(quoted=true, const_label=txt, font=(25,"Times-Italic"),
                 curved=true, pen=(0.5,:red)),
      aspect=:equal, fmt=:png, show=true)
```

```@raw html
<img src="../figs/decorated_txt.png" width="600" class="center"/>
```