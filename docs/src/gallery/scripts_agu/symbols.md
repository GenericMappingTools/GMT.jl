# Symbols

Plot some symbol examples

```julia
plot([0 0], limits=(-1,6,-1,6), figsize=(15,15), marker=:circle, ms=0.75,
     fill=:green, frame=(axes=:WSen, annot=2,grid=1, title="Symbols & pens"))
plot!([1 0], marker=:circle, ms=0.75, fill=:green, ml=(1,:black))
plot!([2 0], marker=:circle, ms=0.75, fill=:green, ml=(1,"0/130/0"))
plot!([3 0], marker=:circle, ms=0.75, fill=:green, ml=(1,:black, :dashed))
plot!([4 0], marker=:circle, ms=0.75, fill=:green, ml=(1,:black, "-."))
plot!([5 0], marker=:circle, ms=0.75, fill="-",    ml=(1,"0/130/0"))
plot!([0 1], marker=:star,   ms=0.75, fill=:red,   ml=(1,:black))
plot!([1 1], marker=:triang, ms=0.75, fill=:red,   ml=(1,:black,:dashed))
plot!([2 1], marker=:diamond,ms=0.75, fill=:red)
plot!([3 1], marker=:hexagon,ms=0.75, fill=:red,   ml=(0.5,:black))
plot!([4 1], marker=:plus,   ms=0.75, ml=(2,:red))
plot!([5 1], marker=:square, ms=0.75, fill=:red)
plot!([0 3], marker=(custom="flash", size=1.5),  ml=1, fill=:brown)
plot!([1 3], marker=(custom="hurricane", size=1.5),  ml=1, fill=:blue)
plot!([2 3], marker=(custom="pacman", size=1.5),  ml=1, fill=:gray)
plot!([3 3], marker=(custom="star3", size=1.5),  ml=1, fill=:brown)
plot!([4 3], marker=(custom="sun", size=1.5),  ml=1, fill=:yellow)
plot!([5 3], marker=(custom="volcano", size=1.5),  ml=1, fill=:red)
plot!([1 5], marker=(custom="@gallo", size=3.5))
plot!([4 5], marker=(custom="@sardinha", size=6.0), show=1, name="symbols.png")
```

```@raw html
<img src="../figs/symbols.png" width="600" class="center"/>
```