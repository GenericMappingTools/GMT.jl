# solar

	solar(cmd0::String="", arg1=[]; kwargs...)

Calculate and plot the day-night terminator and the civil, nautical and astronomical twilights.


Required Arguments
------------------

There are no required arguments but either *sun* or *terminators* must be selected.

Optional Arguments
------------------

- *B* | *axis* | *frame* [The axis control](@ref)  
  Set map boundary frame and axes attributes.

- *C=true*   
  Formats the report selected by *sun=??* using tab-separated fields on a single line. The
  output is Sun *Lon Lat Azimuth Elevation* in degrees, *Sunrise Sunset Noon* in decimal days,
  *day length* in minutes, *SolarElevationCorrected* corrected for the effect of refraction index
  and *Equation of time* in minutes. Note that if no position is provided in *sun=(lon,lat)* the
  data after *Elevation* refers to the point (0,0).

- *G* or *fill* : *fill=color* | *fill=color* | *G=:c*  
   Select color or pattern for filling of terminators; or use *G=:c* for clipping [Default is no fill].
   Deactivate clipping by appending the output of gmt :doc:`clip` **C**.

- *I* or *sun* : *sun=true* | *sun=(lon,lat)* | *sun="lon/lat+ddate* | *sun="lon/lat+ddate+zTZ"*  
   Print current sun position as well as Azimuth and Elevation. Use *sun=(lon,lat)* to print also the times of
   Sunrise, Sunset, Noon and length of the day. Add **+ddate** in ISO format (and therefore use a string), e.g,
   **+d2000-04-25**, to compute sun parameters for this date. If necessary, append time zone via **+zTZ**.

- *M* or *dump* : *dump=true*
    Write terminator(s) as a multisegment file to standard output. No plotting occurs.

- *N* or *invert* : *invert=true*
    Invert the sense of what is inside and outside the terminator. Only used with clipping (*G=:c*) and
    cannot be used together with *axis*.

- *R* or *region* or *limits* :

- *T* or *terminators* : *terminators="d|c|n|a"* | *terminators="d|c|n|a+ddate* | *terminators="d|c|n|a+ddate+zTZ"*  
    Plot (or dump; see *dump*) one or more terminators defined via the **dcna** flags. Where:
    **d** means day/night terminator; **c** means civil twilight; **n** means nautical twilight;
    **a** means astronomical twilight. Add **+ddate** in ISO format (and therefore use a string), e.g,
    **+d2000-04-25** to know where the day-night was at that date. If necessary, append time zone via
    **+zTZ** (`This option is not yet fully ported to expanded syntax`)

- *W* | *pen* :
  Set pen attributes for lines or the outline of symbols [Defaults: width = default, color = black, style = solid].