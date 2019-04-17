# scatter3

	scatter3(cmd0::String="", arg1=[]; kwargs...)

Reads (x,y,z) triplets and plot symbols at those locations on a map. This module is a subset of `plot` to make
it simpler to draw scatter plots. So many (fine) controlling parameters are not listed here. For a
finer control, user should consult the `plot` module.

Parameters
----------

- **B** or *axis* or *frame*\
  Set map boundary frame and axes attributes. Default is to draw and annotate left, bottom and verical
  axes and just draw left and tp axes. More at [axis](@ref)

- **J** or *proj* : -- *proj=<parameters>*\
  Select map projection. Default is linear and 14 cm width. More at [proj](@ref)

- **R** or *region* or *limits* : -- *limits=(xmin, xmax, ymin, ymax)* **|** *limits=(BB=(xmin, xmax, ymin, ymax),)*
   **|** *limits=(LLUR=(xmin, xmax, ymin, ymax),units="unit")* **|** ...more \
   Specify the region of interest. Default limits are computed from data extents. More at [limits](@ref)

- **G** or *markerfacecolor* or *MarkerFaceColor* or *mc* or *fill*\
   Select color or pattern for filling of symbols [Default is black cubes]. Note that plot will search for *fill*
   and *pen* settings in all the segment headers (when passing a GMTdaset or file of a multi-segment dataset)
   and let any values thus found over-ride the command line settings (but those must provided in the terse GMT
   syntax). See [Setting color](@ref) for extend color selection (including color map generation).

- **S** or *symbol* or *marker* or *Marker* or *shape* : --  Default is `cube` with size of 7 points
   - *symbol=symbol string*\
      A full GMT compact string.
   - *symbol=(symb=??, size=??, unit=??)*\
      Where *symb* is one [Symbols](@ref) like `:circle`, *size* is
      symbol size in cm, unless *unit* is specified i.e. `:points`

   In alternative to the *symbol* keyword, user can select the symbol name with either *marker* or *shape*
   and symbol size with *markersize*, *ms* or just *size*. The value of these keywords can be either numeric
   (symb meaning size in cm) or string if an unit is appended, *e.g.*  *markersize=5p*. This form of symbol
   selection allows also to specify a variable symbol size. All it's need for this is that the keywrd's value
   be an array with the same number of elements as the number of data points. 

- **p** or *view*\
   Default is viewpoin from an azimuth of 200 and elevation of 30 degrees. Specify the viewpoint in terms
   of azimuth and elevation. The azimuth is the horizontal rotation about the z-axis as measured in degrees
   from the positive y-axis. That is, from North. This option is not yet fully expanded. Current alternatives
   are:
     - *view=??*\
        A full GMT compact string with the full set of options.
     - *view=(azim,elev)*\
        A two elements tuple with azimuth and elevation

Examples
--------

A scatter of ten points plotted as black cubes of 7 points size using the default perspective of 200,30

```julia
    scatter3(rand(10,10,3), show=true)
```

See also
--------

The [`GMT man page`](https://gmt.soest.hawaii.edu/doc/latest/plot.html)