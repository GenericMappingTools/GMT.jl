```julia
legend((header=(text="SEISMICITY AND THE RING OF FIRE", font=(16,"Helvetica-Bold")),
        hline1=(pen=0.5,),
        ncolumns1=3,
        vline1=(pen=1,),
        symbol1=(marker=:circ, dx_left=0.25, size=0.25, fill=:red, pen=0.25, dx_right=0.5, text="Shallow depth (0-100 km)"),
        symbol2=(marker=:circ, dx_left=0.25, size=0.25, fill=:green, pen=0.25, dx_right=0.5, text="Intermediate depth (100-300 km)"),
        symbol3=(marker=:circ, dx_left=0.25, size=0.25, fill=:blue, pen=0.25, dx_right=0.5, text="Very deep (> 300 km)"),
        hline2=(pen=0.5,),
        vline2=(pen=0.5,),
        ncolumns2=7,
        symbol4=(marker=:circ, dx_left=0.25, size=0.15, fill=:black, dx_right=0.75, text="M 3"),
        symbol5=(marker=:circ, dx_left=0.25, size=0.20, fill=:black, dx_right=0.75, text="M 4"),
        symbol6=(marker=:circ, dx_left=0.25, size=0.25, fill=:black, dx_right=0.75, text="M 5"),
        symbol7=(marker=:circ, dx_left=0.25, size=0.30, fill=:black, dx_right=0.75, text="M 6"),
        symbol8=(marker=:circ, dx_left=0.25, size=0.35, fill=:black, dx_right=0.75, text="M 7"),
        symbol9=(marker=:circ, dx_left=0.25, size=0.40, fill=:black, dx_right=0.75, text="M 8"),
        symbol10=(marker=:circ,dx_left=0.25, size=0.45, fill=:black, dx_right=0.75, text="M 9"),
        ncolumns3=1,
        vspace="9p",
        label=(txt="Data from the US National Earthquake Information Center", justify=:R, font=(12, "Times-Italic"))
       ),
       pos=(paper=(0,0), width=18, justify=:BL, offset=(0,1)),
       box=(fill=:floralwhite, pen=1, inner=0.25, clearance="2p", shaded=true),
       par=(FONT_ANNOT_PRIMARY="10p", FONT_TITLE="18p"), show=true
      )
```
