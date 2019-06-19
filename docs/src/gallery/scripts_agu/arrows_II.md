# Arrows_II

Plot another arrow

```julia
arrows([0.75 0.5 0 8], limits=(-0.1,3,0,2.5), figsize=(16,5),
       arrow=(len=2,start=:arrow,stop=:tail,shape=0.5), fill=:red, pen=6,
       frame=(axes=:WSrt, annot=:auto, title="Arrow II"))
T1 = text_record([0 2.0], "arrows([0 1.0 0 6], limits=(0,3,0,2), figsize=(14,5),");
T2 = text_record([0 1.5], "   arrow=(len=2,start=:arrow,stop=:tail,shape=0.5),");
T3 = text_record([0 1.1], "   pen=6, fill=:red");
pstext!(T1, font=(20,"Times-Italic"), justify=:LB)
pstext!(T2, font=(20,"Times-Italic"), justify=:LB)
pstext!(T3, font=(20,"Times-Italic"), justify=:LB, fmt=:png, show=true)
```

```@raw html
<img src="../figs/arrows_II.png" width="400" class="center"/>
```