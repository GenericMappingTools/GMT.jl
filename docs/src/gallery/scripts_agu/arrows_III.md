# Arrows_III

Plot GMT5 and GMT4 arrows 

```julia
# Plot GMT4 style arrows. WE sho here three alternatives to set arrow heads
arrows([1 0 45 4], region=(0,6,-1,1), J="x2.5",
       frame=(annot=0, grid=1, title="GMT4 Vectors"),
       pen=(1,:blue), fill=:red, arrow4=(align=:middle,
       head=(arrowwidth="4p", headlength="18p", headwidth="7.5p"), double=true))
arrows!([3 0 45 4], pen=(1,:blue), fill=:red,
        arrow4=(align=:middle, head=("4p","18p", "7.5p")))
arrows!([5 0 45 4], pen=(1,:blue), fill=:red,
        arrow4=(align=:middle, head="4p/18p/7.5p"))

# Now the GMT5 type arrows
arrows!([1 0 45 4], frame=(annot=0, grid=1, title="GMT5 Vectors"), lw=2, fill=:red,
        arrow=(length="18p", start=true, stop=true, pen=(1,:blue),
               angle=45, justify=:center, shape=0.5), y_off=7)
arrows!([3 0 45 4], lw=2, fill=:red,
        arrow=(length="18p", stop=true, pen="-", angle=45, justify=:center, shape=0.5))
arrows!([5 0 45 4], lw=2, fill=:red,
        arrow=(length="18p", stop=true, angle=45, justify=:center, shape=0.5),
        fmt=:png, show=true)

```

```@raw html
<img src="../figs/arrows_III.png" width="600" class="center"/>
```