# Arrows_I

Plot an arrow

```julia
arrows([0.5 0.5 0 8], limits=(-0.1,3,0,2.5), figsize=(16,5),
       arrow=(len=2,stop=1,shape=0.5), pen=6,
       frame=(axes=:WSrt, annot=:auto, title="Arrow I"))
T1 = text_record([0 2.0], "arrows([0 1.0 0 6], limits=(0,3,0,2), figsize=(14,5),");
T2 = text_record([0 1.5], "   arrow=(len=2,stop=1,shape=0.5), pen=6");
pstext!(T1, font=(20,"Times-Italic"), justify=:LB)
pstext!(T2, font=(20,"Times-Italic"), justify=:LB, fmt=:png, show=true)
```

```@raw html
<img src="../figs/arrows_I.png" width="400" class="center"/>
```