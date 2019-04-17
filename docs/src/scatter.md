# scatter

	scatter(cmd0::String="", arg1=nothing; kwargs...)

Reads (x,y) pairs and plot symbols at those locations on a map/figure. The input can either be a file
name of a file with at least two columns (x,y), but optionally more, a GMTdatset object with also two
or more columns.

This module is a subset of `plot` to make it simpler to draw scatter plots. So many (fine)
controlling parameters are not listed here. For a finer control, user should consult the `plot` module.

Required Arguments
------------------

There are no required arguments but

Optional Arguments
------------------

- **B** or *axis* or *frame*\
  Set map boundary frame and axes attributes. Default is to draw and annotate left and bottom axes.
  Extended at [axis](@ref)

- **J** or *proj* : -- *proj=<parameters>*\
  Select map projection. Default is linear and 14 cm width. Extended at [proj](@ref)

- **R** or *region* or *limits* : -- *limits=(xmin, xmax, ymin, ymax)* **|** *limits=(BB=(xmin, xmax, ymin, ymax),)*
   **|** *limits=(LLUR=(xmin, xmax, ymin, ymax),units="unit")* **|** ...more \
   Specify the region of interest. Default limits are computed from data extents. Extended at [limits](@ref)

- **G** or *markerfacecolor* or *MarkerFaceColor* or *mc* or *fill*\
   Select color or pattern for filling of symbols [Default is no fill]. Note that plot will search for *fill*
   and *pen* settings in all the segment headers (when passing a GMTdaset or file of a multi-segment dataset)
   and let any values thus found over-ride the command line settings (but those must be provided in the terse GMT
   syntax). See [Setting color](@ref) for extend color selection (including color map generation).

- **S** or *symbol* or *marker* or *Marker* or *shape* : -- Default is `circle` with a diameter of 7 points
   - *symbol=symbol* string\
      A full GMT compact string.
   - *symbol=(symb=??, size=??, unit=??)*\
      Where *symb* is one [Symbols](@ref) like `:circle`, *size* is symbol size in cm, unless *unit*
      is specified i.e. `:points`

   In alternative to the ``symbol`` keyword, user can select the symbol name with either ``marker`` or ``shape``
   and symbol size with ``markersize`` ``ms`` or just ``size`` The value of these keywords can be either numeric
   (symb meaning size in cm) or string if an unit is appended, *e.g.*  ``markersize="5p"`` This form of symbol
   selection allows also to specify a variable symbol size. All it's need for this is that the keyword's value
   be an array with the same number of elements as the number of data points. 


Examples
--------

A simple scatter of ten points plotted as red circles of 7 points size

```julia
    scatter(1:10,rand(10), fill=:red, show=true)
```

A plot where symbol's size grows linearly

```julia
    sizevec = [s for s = 1:10] ./ 10;
    scatter(1:10, 1:10, markersize = sizevec, marker=:square, fill=:green, show=1)
```


See also
--------

The [`GMT man page`](https://gmt.soest.hawaii.edu/doc/latest/plot.html)