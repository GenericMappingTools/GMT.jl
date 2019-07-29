# Lines

Plot some line examples

```julia
plot([0 0; 10 1], limits=(-1,11,-1,11), figsize=14, lw=1, lc=:red)
plot!([0 1; 10 2], lw=3, lc=:green)
plot!([0 2; 10 3], pen=(3,:blue,:dashed))
plot!([0 3; 10 4], pen=(1,:black,:dotted))
plot!([0 4; 10 5], pen=(1,"0/150/0","-."))
plot!([0 5; 10 6], pen=(4,:black,:dashed), par=(:PS_LINE_CAP,:round))
lines!([0 7; 10 7], lw=1, lc=:sienna,
       decorated=(quoted=true, n_labels=15, const_label="~", font=25))
text!(mat2ds([5 7.1],"Now, a bit harder"), clearance=true, fill=:white,
      font=18, justify=:MC)
plot!([0 8; 10 9], pen=(10,:orange,"0_20:0"), par=(:PS_LINE_CAP,:round))
plot!([0 9; 10 10], pen=(6,:brown,"0_20:0"), par=(:PS_LINE_CAP,:round))
plot!([0 9; 10 10], pen=(3,:green,"0_20:10"), par=(:PS_LINE_CAP,:round),
      show=true, savefig="lines.png")
```

```@raw html
<img src="../figs/lines.png" width="600" class="center"/>
```