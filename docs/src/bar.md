# bar

	bar(cmd0::String="", arg1=[]; kwargs...)

Reads (x,y) pairs and plots a bar graph. This module is a subset of `plot` to make it simpler to draw bar
plots. So not all (fine) controlling parameters are listed here. For a finer control, user should
consult the `plot` module.

If input is a MxN array and N > 2 it will plot a bar-group with M groups and N-1 bars in each group (first
column holds always the coordinates).

Parameters
----------

- **B** or *axis* or *frame*\
  Set map boundary frame and axes attributes. Default is to draw and annotate left and bottom axes.
  More at [axis](@ref)

- **J** or *proj* : -- *proj=<parameters>*\
  Select map projection. Default is linear and 14 cm width. More at [proj](@ref)

- **R** or *region* or *limits* : -- *limits=(xmin, xmax, ymin, ymax)* **|** *limits=(BB=(xmin, xmax, ymin, ymax),)*
   **|** *limits=(LLUR=(xmin, xmax, ymin, ymax),units="unit")* **|** ...more \
   Specify the region of interest. Default limits are computed from data extents. More at [limits](@ref)

- **G** or *markerfacecolor* or *MarkerFaceColor* or *mc* or *fill*\
   Select color or pattern for filling of symbols [Default is no fill]. Note that plot will search for *fill*
   and *pen* settings in all the segment headers (when passing a GMTdaset or file of a multi-segment dataset)
   and let any values thus found over-ride the command line settings (but those must be provided in the terse GMT
   syntax). See [Setting color](@ref) for extend color selection (including color map generation).

- *bar*\
   Vertical bar extending from base to *y*. By default, base is 0 and the bar widths are 0.8 of the width in
   x-units. You can change this by using (in alternative):
     - *width=xx*\
        where *xx* is the bar width in x-units (bar base remains = 0).
     - *base=xx*\
        where *xx* is the base value (bar width remains = 0.8).
     - *bar=??*\
        where *??* is a string with a full GMT syntax for this option (**-Sb**)
     - *bar=(width=xx,unit=xx,base=xx,height=xx)*\
        Attention, the order of members matters but only *width* is mandatory.
       - *width*\
          The bar width in x-units. To specify it in plot units, use the *unit* member with `cm`, `inch` or `point`.
       - *unit*\
          In case *width* is given in plot units. Valid units are `cm`, `inch` or `point`.
       - *base=xx*\
          where *xx* is the base value.
       - *height*\
          If the bar height is measured relative to base *xx* [Default is relative to origin].
          Cannot be used together with *base*.

- *hbar*\
   Horizontal bar extending from base to x. Same as *bar* but now with respect to y axis, except that one
   cannot use *width* or *base* to change just those defaults (the use of it is restricted to the vertical
   bars case).

- *fill=["color1", "color2", ...]* **|** *fill=("color1", "color2", ...)* **|** *fill=(1,2,...)*\
   List of colors used to wrapp the bars inside each group. When using numbers that means patterns codes.

- *fillalpha=[...]*\
   When *fill* was used, control the transparency level. Numbers v=can be flots <= 1.0 or integeres in 0-100 range.

- *stack*\
   Plot a vertically stacked group plot

Examples
--------

A simple bar plot with 10 bars and automatic limits.

```julia
    bar(rand(10), show=true)
```

A bar group with selected colors and transparency.
```julia
    bar([0. 1 2 3; 1 2 3 4], fillalpha=[0.3 0.5 0.7], show=1,  fmt=:png, fill=["red" "green" "blue"], fmt=:png)
```

A bar group with bars filled with patterns.
```julia
    bar([0 1 2 3; 1 2 3 4], fill=(1,2,3), show=1, fmt=:png)
```

A bar group with error bars
```julia
    bar([0. 1 2 3; 1 2 3 4], error_bars=(y=[0.1 0.2 0.33; 0.2 0.3 0.4],), show=1, fmt=:png)
```

See also
--------

The [`GMT man page`](https://gmt.soest.hawaii.edu/doc/latest/plot.html)