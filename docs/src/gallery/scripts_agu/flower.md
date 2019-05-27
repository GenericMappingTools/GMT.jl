# Filled flower with pattern

Draw a flower filled from a pattern in a .jpg file.

```julia
t = GMT.linspace(0,2pi,360);
x = cos.(4*t) .* cos.(t);
y = cos.(4*t) .* sin.(t);

lines([-0.7 -0.25 0], [-1.5 -0.8 0], # The flower stem
      limits=(-1,1,-1.5,1),          # Fig limits
      lw=9,                          # Stem's line width in points
      lc=:darkgreen,                 # Stem's line color
      bezier=true,                   # Smooth the stem polyne as a Bezier curve
      figsize=(14,0),                # Fig size. Second arg = 0 means compute the height keeping aspect ratio
      frame=:none)                   # Do not plot the frame
plot!(x, y,
      fill=(pattern="C:/progs_cygw/GMTdev/gmt5/master/test/psxy/tiling2.jpg",  # Fill pattern file
      dpi=200),                      # The pattern DPI
      fmt=:png,                      # The image format
      show=true)                     # Show the result
```

As one-liners (to facilitate copy-paste):

```julia
t=GMT.linspace(0,2pi,360);
x = cos.(4*t) .* cos.(t);
y = cos.(4*t) .* sin.(t);
lines([-0.7 -0.25 0], [-1.5 -0.8 0], limits=(-1,1,-1.5,1), lw=9, lc=:darkgreen, bezier=true, frame=:none, figsize=(14,0))
plot!(x, y, fill=(pattern="C:/progs_cygw/GMTdev/gmt5/master/test/psxy/tiling2.jpg", dpi=200), fmt=:png, savefig="flower", show=true)
```

```@raw html
<img src="../figs/flower.png" width="400" class="center"/>
```