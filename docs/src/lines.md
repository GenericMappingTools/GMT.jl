# lines

	lines(cmd0::String="", arg1=[]; kwargs...)

Reads (x,y) pairs and plot lines with different levels of decoration. The input can either be a file
name of a file with at least two columns (x,y), but optionally more, a GMTdatset object with also two
or more columns.

This module plots a large variety of lines and polygons. It goes from *simple* lines and polygons
(color/pattern filled or not) to the so called *decorated* lines. That is, lines decorated with
symbols and text patterns.

This module is a subset of `plot` to make it simpler to draw line plots. So not all (fine)
controlling parameters are not listed here. For the finest control, user should consult the `plot` module.

Parameters
----------

- **B** or *axis* or *frame*\
  Set map boundary frame and axes attributes. Default is to draw and annotate left and bottom axes.
  More at [axis](@ref)

- **J** or *proj* : *proj=<parameters>*\
  Select map projection. Default is linear and 14 cm width. More at [proj](@ref)

- **R** or *region* or *limits* : *limits=(xmin, xmax, ymin, ymax)* **|** *limits=(BB=(xmin, xmax, ymin, ymax),)*
   **|** *limits=(LLUR=(xmin, xmax, ymin, ymax),units="unit")* **|** ...more \
   Specify the region of interest. Default limits are computed from data extents. More at [limits](@ref)

- **G** or *markerfacecolor* or *mc* or *fill*\
   Select color or pattern for filling of polygons [Default is no fill]. Note that plot will search for *fill*
   and *pen* settings in all the segment headers (when passing a GMTdaset or file of a multi-segment dataset)
   and let any values thus found over-ride the command line settings (but those must be provided in the terse GMT
   syntax). See [Setting color](@ref) for extend color selection (including colormap generation).

- **W** or *pen=pen*\
   Set pen attributes for lines or the outline of symbols (except for the *decorated* lines that have their own
   options to do it) [Defaults: width = default, color = black, style = solid]. See [Pen attributes](@ref)

- **decorated**\
   For all types of line decorations: symbols [Decorated lines](@ref), fronts [Front lines](@ref),
   text [Quoted lines](@ref), etc... see [Line decorations](@ref)

- **U** or *stamp* : *stamp=true* **|** *stamp=(just="code", pos=(dx,dy), label="label", com=true)*\
   Draw GMT time stamp logo on plot. More at [stamp](@ref)

- **V** or *verbose* : *verbose=true* **|** *verbose=level*\
   Select verbosity level. More at [verbose](@ref)

- **X** or *x_off* or *x_offset* : *x_off=[] **|** *x_off=x-shift* **|** *x_off=(shift=x-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [x_off](@ref)

- **Y** or *y_off* or *y_offset* : *y_off=[] **|** *y_off=y-shift* **|** *y_off=(shift=y-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [y_off](@ref)

Examples
--------

Decorated curve with blue stars

```julia
    xy = gmt("gmtmath -T0/180/1 T SIND 4.5 ADD");
    lines(xy, axis=:af, pen=(1,:red), decorated=(dist=(2.5,0.25), symbol=:star,
          symbsize=1, pen=(0.5,:green), fill=:blue, dec2=true), show=true)
```