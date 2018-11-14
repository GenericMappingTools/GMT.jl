# solar

	solar(cmd0::String="", arg1=[]; kwargs...)

Calculate and plot the day-night terminator and the civil, nautical and astronomical twilights.


Required Arguments
------------------

There are no required arguments but either *sun* or *terminators* must be selected.

Optional Arguments
------------------

- *B* | *axis* | *frame*

  Set map boundary frame and axes attributes. More at [axis](@ref)

- *C=true*

   Formats the report selected by *sun=??* using tab-separated fields on a single line. The
   output is Sun *Lon Lat Azimuth Elevation* in degrees, *Sunrise Sunset Noon* in decimal days,
   *day length* in minutes, *SolarElevationCorrected* corrected for the effect of refraction index
   and *Equation of time* in minutes. Note that if no position is provided in *sun=(lon,lat)* the
   data after *Elevation* refers to the point (0,0).

- *G* or *fill* : *fill=color* | *fill=color* | *G=:c*

   Select color or pattern for filling of terminators; or use *G=:c* for clipping [Default is no fill].
   Deactivate clipping by appending the output of gmt :doc:`clip` **C**.

- *I* or *sun* : *sun=true* | *sun=(lon,lat)* | *sun=(pos=(lon,lat), date=date)* | *sun=(pos=(lon,lat), date=date, TZ=tzone)*

   Print current sun position as well as Azimuth and Elevation. Use *sun=(lon,lat)* to print also the times of
   Sunrise, Sunset, Noon and length of the day. To add a date, use a NamedTuple instead and add the element
   *date=date* in ISO format, e.g, *date="2000-04-25"* to compute sun parameters for this date. If necessary,
   add another element with the time zone via *TZ=tzone*.

- *M* or *dump* : *dump=true*

    Write terminator(s) as a multisegment file to standard output. No plotting occurs.

- *N* or *invert* : *invert=true*

   Invert the sense of what is inside and outside the terminator. Only used with clipping (*G=:c*) and
   cannot be used together with *axis*.

- *R* or *region* or *limits* :

- *T* or *terminators* : *terminators="d|c|n|a"* | *terminators=(terms="d|c|n|a", date=date)* | *terminators=(terms="d|c|n|a", date=date), TZ=tzone)*

   Plot (or dump; see *dump*) one or more terminators defined via the **dcna** flags. Where: **d** means
   day/night terminator; **c** means civil twilight; **n** means nautical twilight; **a** means astronomical
   twilight. To add a date, use a NamedTuple instead and add the element *date=date* in ISO format, e.g,
   *date="2000-04-25"* to know where the day-night was at that date. If necessary, add another element with
   the time zone via *TZ=tzone*. 

- *U* or *stamp* : *stamp=true* **|** *stamp=(just="code", pos=(dx,dy), label="label", com=true)*

   Draw GMT time stamp logo on plot. More at [stamp](@ref)

- *V* or *verbose* : *verbose=true* **|** *verbose=level*

   Select verbosity level. More at [verbose](@ref)

- *X* or *x_off* or *x_offset : *x_off=[] **|** *x_off=x-shift* **|** *x_off=(shift=x-shift, mov="a|c|f|r")*

   Shift plot origin. More at [x_off](@ref)

- *Y* or *y_off* or *y_offset : *y_off=[] **|** *y_off=y-shift* **|** *y_off=(shift=y-shift, mov="a|c|f|r")*

   Shift plot origin. More at [y_off](@ref)

- *W* | *pen* :

   Set pen attributes for lines or the outline of symbols [Defaults: width = default, color = black, style = solid].

Examples
--------

Print current Sun position and Sunrise, Sunset times at:

```julia
    solar(sun=(pos=(-7.93,37.079), date="2016-02-04T10:01:00"))
```

Plot the day-night and civil twilight 

```julia
    coast(region=:d, pen=0.1, proj="Q0/14c", axis=(annot=:auto, axes="WSen"),
          resolution=:low, area=1000)
    solar!(pen=1, terminators="dc", show=true)
```

See also
--------

The [`GMT man page`](https://gmt.soest.hawaii.edu/doc/latest/solar.html)