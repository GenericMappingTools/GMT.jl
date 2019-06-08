# axis

- *B* **|** *frame* **|** *axis* **|** *xaxis* **|** *xaxis2* **|** *yaxis* **|** ...

Set map Axes parameters. They are specified by a keyword and a named tuple (but see [1])

    frame=(axes=..., corners=..., xlabel=..., ylabel=..., annot=..., etc)

or separated on a per axes basis by using specific *xaxis*, *yaxis* and *zaxis* that share the same syntax
as the generic *frame* option. The *xaxis2* and *yaxis2* apply when dealing with secondary axes.

Before the rest, note that several modules have axes default settings (`scatter`, `bar`, etc...) but if
no axes is desired, just use *axis=:none*. Also useful is the *axis=:same* to repeat the previously set
(from another call) axis specification.

By default, all 4 map boundaries (or plot axes) are plotted and two annotated. To customize, use the *axes*
keyword that takes as value a tuple with a combination of words. Axes are named *left*, *bottom*, *right*,
*top* and, for the 3D maps, *up*. Next we have three categories of axes: the *annotated and ticked*, the *ticked*
and those with no annoations and no tick marks. We call them *full*, *ticks* and *bare* and combine with the axes
name using an underscore to glue them. Hence *left_full* means draw and annotate left axes, whilst *top_bare*
means draw only top axes. The full combination is *left|bottom|right|top|up_full|ticks|bare*. To not draw a
boundary, simply omit the name of it in tuple. Note that the short one single char naming used by GMT is also
valid. E.g. *axes=:WSn* will draw and annotate left and south boundaries and draw but no ticks or annotations
the top boundary. Two special cases are provided by the *frame=:none* and *frame=:noannot* that do not plot
any axes or just plot but do not annotate or tick them respectively.

If a 3-D base map is selected with *view* and *J=:z*, by default a single vertical axes will be plotted at
the most suitable map corner. Override the default by using the keyword *corners* and any combination of
corner ids **1234**, where **1** represents the lower left corner and the order goes counter-clockwise.

Use *cube=true* to draw the outline of the 3-D cube defined by *region* this option is also needed to display
gridlines in the x-z, y-z planes. Note that for 3-D views the title, if given, will be
suppressed. You can paint the interior of the canvas with `fill=fill` where the *fill* value can be a color
or a pattern.

Use *noframe=true* to have no frame and annotations at all [Default is controlled by the codes].

Optionally append *pole="plon/plat"* (or *pole=(plon,plat)* to draw oblique gridlines about
specified pole [regular gridlines]. Ignored if gridlines are not requested (below) and disallowed for the oblique
Mercator projection.

For Cartesian plots the *slanted=angle* allows for the optional angle to plot slanted annotations; the angle
is with respect to the horizontal and must be in the -90 <= *angle* <= 90 range only. This applies to the x-axis
only, with the exception of the *slanted=:parallel* form that plots the y annotations parallel to y-axis.

To add a plot title do *title="My title"* The Frame setting is optional but can be invoked once to override
the above defaults.

GMT uses the notion of *primary* (the default) and *secondary* axes. To set an axes as secondary, use
*secondary=true* (mostly used for time axes annotations).

The *xaxis* *yaxis* and *zaxis* specify which axis you are providing information for. The syntax is the same
as for the *axis* keyword but allows fine tuning of different options for the 4 (or 5) axes.

To add a label, to an axis use *label="Label text"* if using the *xaxis* etc form, or use the *xlabel*, *ylabel*
and *zlabel* keywords in the common *axis* tuple of options.

Use *Yhlabel=true* to force a horizontal label for *y*-axes (useful for very short labels).

If the axis annotation should have a leading text prefix (e.g., dollar sign for those plots of your net worth)
you can add *prefix="prefix"* For geographic maps the addition of degree symbols, etc. is automatic (and
controlled by the GMT default setting [FORMAT\_GEO\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-geo-map)).
However, for other plots you can add specific units by adding *label_unit="unit"*

Annotations, ticks and grid intervals are specified with the *annot*, *ticks* and *grid* keywords, which take
as value the desired stride interval. As an example, *annot=10* means annotate at spacing of 10 data units.
Alternatively, for linear maps, we can use the special value *:auto* annotations at automatically determined
intervals.

- **annot=:auto, grid=:auto** plots both annotations and grid lines with the same spacing,
- **annot=:auto, ticks=:auto, grid=:auto** adds suitable minor tick intervals,
- **grid=:auto** plots grid lines with the same interval as if **ticks=:auto** was used.

The optional *phase_add=xx* and *phase_sub=xx* shifts the annotation interval by tht *xx* amount
(positive or negative).

The optional *annot_unit* indicates the unit of the *stride* and can be any of the ones listed below:

- **:year**  or **:Y** (year, plot with 4 digits)
- **:year2** or **:y** (year, plot with 2 digits)
- **:month** or **:O** (month, plot using [FORMAT\_DATE\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-date-map))
- **:month2** or **:o** (month, plot with 2 digits)
- **:ISOweek** or **:U** (ISO week, plot using [FORMAT\_DATE\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-date-map))
- **:ISOweek2** or **:u** (ISO week, plot using 2 digits)
- **Gregorian_week** or **:r** (Gregorian week, 7-day stride from start of week [TIME\_WEEK\_START](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#time-week-start))
- **:ISOweekday** or **:K** (ISO weekday, plot name of day)
- **:date** or **:D** (date, plot using [FORMAT\_DATE\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-date-map))
- **:day_date** or **:d** (day, plot day of month 0-31 or year 1-366, via [FORMAT\_DATE\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-date-map))
- **:day_week** or **:R** (day, same as **d**, aligned with [TIME\_WEEK\_START](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#time-week-start))
- **:hour**    or **:H** (hour, plot using [FORMAT\_CLOCK\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-clock-map))
- **:hour2**   or **:h** (hour, plot with 2 digits)
- **:minute**  or **:M** (minute, plot using [FORMAT\_CLOCK\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-clock-map))
- **:minute2** or **:m** (minute, plot with 2 digits)
- **:second**  or **:S** (second, plot using [FORMAT\_CLOCK\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-clock-map))
- **:second2** or **:s** (second, plot with 2 digits).


Note for geographic axes **m** and **s** instead mean arc minutes and arc seconds.
All entities that are language-specific are under control by [GMT\_LANGUAGE](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#gmt-language). 

For custom annotations and intervals, let *intervals* be given as *custom="intfile"*, where
*intfile* contains any number of records with *coord * *type* [*label*]. Here, *type* is one or more
letters from **a** or **i**, **f**, and **g**. For **a** or **i** you must supply a *label* that will
be plotted at the *coord* location.

For non-geographical projections: Give negative scale (in *proj="x scale"* or axis length
(in *proj="X map width"* to change the direction of increasing coordinates (i.e., to make the y-axis
positive down).

For log10 axes: Annotations can be specified in one of three ways: 

1. *stride* can be 1, 2, 3, or -*n*. Annotations will then occur at 1,
       1-2-5, or 1-2-3-4-...-9, respectively; for -*n* we annotate every
       *n*'t magnitude. This option can also be used for the frame and grid intervals. 

2. Use *log=true*, then log10 of the tick value is plotted at every integer log10 value.

3. Use *10log=true*, or *pow=true* then annotations appear as 10 raised to log10 of the tick value.

For power axes: Annotations can be specified in one of two ways:

1. *stride* sets the regular annotation interval.

2. Use *exp=true*, then, the annotation interval is
       expected to be in transformed units, but the annotation value will
       be plotted as untransformed units. E.g., if *stride* = 1 and *power*
       = 0.5 (i.e., sqrt), then equidistant annotations labeled 1-4-9...  will appear.

Finally, if your axis is in radians you can use multiples or fractions of **pi** to
set such annotation intervals. The format is *pi=n* or *pi=(n,m)*, for an optional
integer *n* and optional *m* fractions 2, 3, or 4.

These GMT parameters can affect the appearance of the map boundary:
[MAP\_ANNOT\_MIN\_ANGLE](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-annot-min-angle),
[MAP\_ANNOT\_MIN\_SPACING](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-annot-min-spacing),
[FONT\_ANNOT\_PRIMARY](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#font-annot-primary),
[FONT\_ANNOT\_SECONDARY](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#font-annot-secondary),
[MAP\_ANNOT\_OFFSET\_PRIMARY](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-annot-offset-primary),
[MAP\_ANNOT\_OFFSET\_SECONDARY](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-annot-offset-secondary),
[MAP\_ANNOT\_ORTHO](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-annot-ortho),
[MAP\_FRAME\_AXES](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-frame-axes),
[MAP\_DEFAULT\_PEN](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-default-pen),
[MAP\_FRAME\_TYPE](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-frame-type),
[FORMAT\_GEO\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-geo-map),
[MAP\_FRAME\_PEN](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-frame-pen),
[MAP\_FRAME\_WIDTH](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-frame-width),
[MAP\_GRID\_CROSS\_SIZE\_PRIMARY](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-grid-cross-size-primary),
[MAP\_GRID\_PEN\_PRIMARY](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-grid-pen-primary),
[MAP\_GRID\_CROSS\_SIZE\_SECONDARY](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#language),
[MAP\_GRID\_PEN\_SECONDARY](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-grid-pen-seondary),
[FONT\_TITLE](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#font-title),
[FONT\_LABEL](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#font-label),
[MAP\_LINE\_STEP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-line-step),
[MAP\_ANNOT\_OBLIQUE](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-annot-oblique),
[FORMAT\_CLOCK\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-clock-map),
[FORMAT\_DATE\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-date-map),
[FORMAT\_TIME\_PRIMARY\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-time-primary-map),
[FORMAT\_TIME\_SECONDARY\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-time-secondary-map),
[GMT\_LANGUAGE](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#gmt-language),
[TIME\_WEEK\_START](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#time-week-start),
[MAP\_TICK\_LENGTH\_PRIMARY](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-tick-length-primary),
and [MAP\_TICK\_PEN\_PRIMARY](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#map-tick-pen-primary)

## Axis options table

The entire parameters collection is displayed in the following table

| keyword       | value          | type            | meaning     |
| ------------- |:--------------:|:---------------:| -----------:|
| frame         | false         | Str or Symb   | Do not plot any axis |
| frame         | noannot\|bare | Str or Symb   | Plot axes but no annot |
| axes          | left_full     | Str or Symb   | Annot and tick left axis |
|               | left_ticks    | Str or Symb   | Tick left axis |
|               | left_bare     | Str or Symb   | Just draw left axis |
|               | bottom_full   | Str or Symb   | Same for bottom axis |
|               | right_full    | Str or Symb   | Same for right axis |
|               | top_full      | Str or Symb   | Same for top axis |
|               | up_full       | Str or Symb   | Same for z axis |
|               | WESNwesn...   | Str or Symb   | The classic GMT syntax |
| corners       | 1234          | Str or Symb   | Vertical axis |
| scondary      | true or false | Bool          | Secondary axis info |
| fill          | `color`       | Str or Symb   | Paint interior |
| cube          | anything      | Sym or Bool   | Draw outline of the 3-D cube |
| noframe       | anything      | Sym or Bool   | No frame and annotations at all |
| pole          | lon lat       | Str or Tuple  | Draw oblique gridlines abot pole |
| title         | the title     | Str or Symb   | Add a plot title |
| label         | axis label    | Str or Symb   | Add a label to an axis |
| Yhlabel       | y-axis hlabel | Str or Symb   | Horizontal label for y-axes |
| prefix        | annot prefix  | Str or Symb   | Annot leading text prefix |
| suffix        | annot suffix  | Str or Symb   | Annot trailing text suffix |
| xlabel        | x-axis label  | Str or Symb   | Add a label to X axis |
| ylabel        | y-axis label  | Str or Symb   | Add a label to Y axis |
| zlabel        | z-axis label  | Str or Symb   | Add a label to Z axis |
| seclabel      | second label  | Str or Symb   | Add a seconadry label to X|Y|Z axis |
| annot         | annot interval| Symb or Num   | Annot stride interval |
| ticks         | tick interval | Symb or Num   | Tick interval |
| grid          | grid interval | Symb or Num   | Grid lines interval |
| slanted       | x-annot angle | Symb or Num   | Angle of slanted annotations |
| phase_add     | xx            | Numb          | Shifts right the annot interval |
| phase_sub     | xx            | Numb          | Shifts left the annot interval |
| annot_unit    | annot unit    | Str or Symb   | Unit of the *stride* |
| custom        | custom annot  | Str or Symb   | Custom annotations file |
| pi            | n or (n,m)    | Num or Tuple  | If axis is in radians |
| scale         | log           | Str or Symb   | log10 of the tick value |
|               | 10log or pow  | Str or Symb   | Annot as 10 raised to log10 |
|               | exp           | Str or Symb   | Annot interval in transformed units |

   [1] However, the original GMT compact syntax can also be used. I.e, *axis=:a*, or *frame=:WSen*
   or *frame="a1Of1d WS"* also work.

   [`-B GMT doc`](https://www.generic-mapping-tools.org/gmt/latest/gmt.html#b-full)

## Examples

Demonstrates use of dual (left vs right, bottom vs top) Cartesian axis labels

```julia
basemap(limits=(0,50,0,7), figsize=8,
        xaxis=(annot=:auto, ticks=:auto, label="Bottom Label", seclabel="Top label"),
        yaxis=(annot=:auto, ticks=:auto, label="Left label", seclabel="Right label"), show=1)
```

we can obtain the same result with a slightly shorter version of the above that shows how can mix *frame* and *xaxis* calls.

```julia
basemap(limits=(0,50,0,7), figsize=8,
        frame=(annot=:auto, ticks=:auto, xlabel="Bottom Label", ylabel="Left label"),
        xaxis=(seclabel="Top label",), yaxis=(seclabel="Right label",), show=1)
```

Show inside labeling (use default fig size).

```julia
basemap(limits=(0,13,0,10), frame=(annot=2, ticks=0.5), par=(:MAP_FRAME_TYPE,:inside), show=1)
```

Show horizontal and vertical annotations

```julia
basemap(region=[0 1000 0 1000], figsize=5,
        frame=(axes=(:left_full,:bottom_full,:right_full,:top_full), annot=200,
               ticks=100, xlabel=:horizontal, ylabel=:vertical),
        par=(FONT_ANNOT_PRIMARY=10, FONT_LABEL=16, MAP_ANNOT_ORTHO=:we))

basemap!(frame=(axes=(:left_full,:bottom_full,:right_full,:top_full), annot=200,
                ticks=100, xlabel=:horizontal, ylabel=:vertical),
         par=(FONT_ANNOT_PRIMARY=10, FONT_LABEL=16, MAP_ANNOT_ORTHO=:sn),
         x_offset=9, show=1)
```

Show `Yhlabel` for horizontal labels for y-axis 

```julia
basemap(region="-30/30/-20/20", figsize=(12,8),
        frame=(annot=:a, ticks=:a, xlabel="Standard horizontal label", Yhlabel="@~Y(q)@~",
               title="Vertical Y-axis label"), show=1)
```

--------------------------

# limits

- *R* **|** *region* **|** *limits* **|** *xlimits*,*ylimits*

   *xmin*, *xmax*, *ymin*, and *ymax* specify the region of interest (aka, BoundingBox). For geographic
   regions, these limits correspond to *west*, *east*, *south*, and *north* and you may specify them in
   decimal degrees or in [+|-]dd:mm[:ss.xxx][W|E|S|N] format.
   
   Using the form *region = [xmin xmax ymin ymax]* or the equivalent tuple alternative covers the largest
   chunk of user cases. However, for fine tunning the limits setting we have an extended syntax that
   involves the use of Named Tuples. Next needed case is when one want/need to specify the BoundingBox
   with the *(xmin, ymin, xmax, ymax)* corners. As mentioned, this involves a NamedTuple keyword that
   can have any of the following members name/value:

   - *R=xx*, *region=xx* or *limits=xx* -- where *xx* is a string is interpreted as a GMT **-R** syntax string.
   - *bb*, *lmits*, *region* -- a four (or six) elements array or tuple with *xmin, xmax, ymin, ymax [zmin zmax]*
   - *bb=global* or *bb=:d* -- shorthand for *bb=[-180 180 -90 90] 
   - *bb=global360* or *bb=:g* -- shorthand for *bb=[0 360 -90 90] 
   - *bb_diag*, *limits_diag*, *region_diag* or *LLUR* -- a four elements array with *xmin, ymin, xmax, ymax*
   - *diag=true* -- makes the *bb* mean *bb_diag*
   - *cont* or *continents=continent name* where *continent name* is any of: *Africa*, *Antarctica*,
     *Asia*, *Europe*, *Oceania*,  *North America* or *South America* (or the shorthands: *AF, AN, AS, EU,
      OC, NA, SA*). This sets the geographic limts covered by these continents.
   - *ISO=code* -- use ISO country codes from the Digital Chart of the World. Append one or more comma-separated
      countries using the 2-character ISO 3166-1 alpha-2 convention. To select a state of a country
      (if available), append .state, e.g, US.TX for Texas.
   - *adjust=xx* -- where *xx* is either a String, a Number or an Array/Tuple to set an *inc*, *xinc yinc*,
      or *winc einc sinc ninc* to adjust the region to be a multiple of these steps steps.
   - *pad=xx*, *extend=xx* or *expand=xx* -- same as above but extend the region outward by adding these
      increments instead.
   - *unit=val* -- use Cartesian projected coordinates compatible with the chosen projection. Append the
      length unit (e.g. "k" for kilometer). These coordinates are internally converted to the corresponding
      geographic (longitude, latitude) coordinates for the lower left and upper right corners. This form is
      convenient when you want to specify a region directly in the projected units (e.g., UTM meters). For
      Cartesian data in radians you can also use [+|-][s]pi[f], for optional integer scales *s* and fractions *f*.

   The *xlimts*, *ylimits* is used to break the specification into two pairs but it won't support all the
   options of the *limits* functionality.

   [`-R GMT doc`](https://www.generic-mapping-tools.org/gmt/latest/gmt.html#r-full)

--------------------------

# proj

- *J* **|** *proj* : *projection* : *proj=<parameters>*

Select map projection. The following table describes the projections available as well as extra parameters
needed to set a specific projection. If the *proj* argument is a string then it is assumed that it contains
a full GMT **-J** style specification. Please refer to the GMT manual to learn how that works.
[`-J GMT doc`](https://www.generic-mapping-tools.org/gmt/latest/gmt.html#j-full)
In the table, the *center* column indicates if a projection needs to set a projection center or if that is optional
(when the parameters are under []). Several projections not to set also the standard paralalle(s). Those are
indicated by a non-empty *parallels* column. Still, other projections accept an optional *horizon* parameter,
which is an angle that specifies the max distance from projection center (in degrees, <= 180, default 90) that
is plotted.

Given the different needs to specify a projection we can either use a simple form when only the projection
name is required, *e.g. proj=Mercator* or in the more elaborated cases, a named tuple with fields *name, center,
horizon, parallels*. An example of this later case would be to set an Oblique Mercator projection with center at
280ºW, 25.5ºN and standard parallels at 22 and 60ºN. We would do that with
*proj=(name=:omercp, center=[280 25.5], parallels=[22 69])*. Note that we can either use arrays or tuples to
specify pairs of values.

In case the central meridian is an optional parameter and it is being omitted, then the center of the longitude
range given by the *limits* option is used. The default standard parallel is the equator. 

For linear (Cartesian) projections one can use *proj=:linear* but the simplest is just to omit the projection
setting, which will default to a fig with of 12 cm. To set other fig dimensions, use the *figsize* specification
with *figsize=(width, height)* (both numeric or string) or just *figsize=width* and the *height* is computed
automatically from the fig limits aspect ratio. We can also specify the scale separately: *e.g.* *figscale=x*,
*figscale=1:xxxx*. As mentioned, when no size is provided a default width value of 12 cm is assumed.

When specifying a *figsize*, the UNIT is cm by default but it can be overridden by appending **i**, or **p** to
the scale or width values. Append **h**, **+**, or **-** to the given width if you instead want to set map height,
the maximum dimension, or the minimum dimension, respectively [Default is **w** for width]. Off course, when these
settings are used, the argument to *figsize* must be in the form of strings.

The ellipsoid used in the map projections is user-definable by editing the gmt.conf file in your home directory.
73 commonly used ellipsoids and spheroids are currently supported, and users may also specify their own custom
ellipsoid parameters [Default is WGS-84]. Several GMT parameters can affect the projection: *PROJ\_ELLIPSOID*,
*GMT\_INTERPOLANT*, *PROJ\_SCALE\_FACTOR*, and *PROJ\_LENGTH\_UNIT*; see the gmt.conf man page for details.

See [GMT Map Projections](@ref) for a list of projection examples 

| name                 | center     | horizon | parallels | GMT code | Description |
| -------------------- |:----------:|:------:| :---------:| -------- | ------- |
| aea, Alberts               | ``lon_0lat_0`` | *NA*  | ``lat_1lat_2`` | **B**``lon_0/lat_0/lat_1/lat_2`` | Albers conic equal area |
| aeqd, azimuthalEquidistant | ``lon_0lat_0`` | *yes* | *NA*           | **E**``lon_0/lat_0`` | Azimuthal equidistant |
| Cyl_stere, cylindricalStereographic  | ``[lon_0[lat_0]]`` | *NA*  | *NA* | **Cyl_stere**``[lon_0[/lat_0]]`` | Cylindrical stereographic |
| cass, Cassini   | ``lon_0lat_0`` | *NA*     | *NA* | **C**``lon_0/lat_0`` | Cassini cylindrical |
| cea, cylindricalEqualarea  | ``lon_0lat_0`` | *NA*  | *NA*           | **Y**``lon_0/lat_0`` | Cylindrical equal area |
| eqdc, conicEquidistant     | ``lon_0lat_0`` | *NA*  | ``lat_1lat_2`` | **D**``lon_0/lat_0/lat_1/lat_2`` | Equidistant conic |
| eqc, PlateCarree, equidistant | ``[lon_0[lat_0]]``  | *NA*  | *NA* | **Q**``[lon_0[/lat_0]]`` | Equidistant cylindrical |
| eck4, EckertIV             | ``[lon_0]``    | *NA*  | *NA* | **Kf**``[lon_0]`` | Eckert IV equal area |
| eck6, EckertVI             | ``[lon_0]``    | *NA*  | *NA* | **Ks**``[lon_0]`` | Eckert VI equal area |
| gnom, Gnomonic  | ``lon_0lat_0`` | *yes*    | *NA* | **F**``lon_0/lat_0`` | Azimuthal gnomonic |
| hamm, Hammer    | ``[lon_0]``    | *NA*     | *NA* | **H**``[lon_0]`` | Hammer equal area |
| laea, lambertAzimuthal     | ``lon_0lat_0`` | *yes* | *NA*           | **A**``lon_0/lat_0`` | Lambert azimuthal equal area |
| lcc, lambertConic          | ``lon_0lat_0`` | *NA*  | ``lat_1lat_2`` | **L**``lon_0/lat_0/lat_1/lat_2`` | Lambert conic conformal |
| lin, Linear     |  | *NA*        | *NA* | **X**[l|pexp|T|t][/height[l|pexp|T|t]][d] | Linear, log_{10}, x^a-y^b, and time |
| merc, Mercator  | ``[lon_0[lat_0]]`` | *NA* | *NA* | **M**``[lon_0[/lat_0]]`` | Mercator cylindrical |
| mill, Miller    | ``[lon_0]``    | *NA*     | *NA* | **J**``[lon_0]`` | Miller cylindrical |
| moll, Molweide  | ``[lon_0]``    | *NA*     | *NA* | **W**``[lon_0]`` | Mollweide |
| omerc, obliqueMerc1        | ``lon_0lat_0`` | *NA*  | ``azim`` | **Oa**``lon_0/lat_0/azim`` | Oblique Mercator, 1: origin and azim |
| omerc2, obliqueMerc2       | ``lon_0lat_0`` | *NA*  | ``lon_1lat_1`` | **Ob**``lon_0/lat_0/lon_1/lat_1`` | Oblique Mercator, 2: two points |
| omercp, obliqueMerc3       | ``lon_0lat_0`` | *NA*  | ``lon_plat_p`` | **Oc**``lon_0/lat_0/lon_p/lat_p`` | Oblique Mercator, 3: origin and pole |
| ortho, Orthographic  | ``lon_0lat_0`` | *yes* | *NA* | **G**``lon_0/lat_0`` | Azimuthal orthographic |
| poly, PolyConic | ``[lon_0[lat_0]]``  | *NA*  | *NA* | **Poly**``[lon_0[/lat_0]]`` | (American) polyconic |
| robin, Robinson | ``[lon_0]``    | *NA*  | *NA* | **N**``[lon_0]`` | Robinson |
| stere, Stereographic | ``lon_0lat_0`` | *yes*   | *NA* | **S**``lon_0/lat_0`` | General stereographic |
| sinu, Sinusoidal | ``[lon_0]``    | *NA*  | *NA* | **I**``[lon_0]`` | Sinusoidal equal area |
| tmerc, transverseMercator  | ``[lon_0[lat_0]]`` | *NA*  | *NA* | **T**``[lon_0[/lat_0]]`` | Transverse Mercator |
| utm*xx*, UTM*xx* | *NA*           | *NA*  | *NA* | **U**``zone`` | Universal Transverse Mercator (UTM) |
| vand, VanDerGritten | ``[lon_0]`` | *NA*  | *NA* | **V**``[lon_0]`` | Van der Grinten |
| win, WinkelTripel   | ``[lon_0]`` | *NA*  | *NA* | **R**``[lon_0]`` | Winkel Tripel |


   [`-J GMT doc`](https://www.generic-mapping-tools.org/gmt/latest/gmt.html#j-full)

--------------------------

# stamp

- *U* **|** *stamp* **|** *time_stamp* : *stamp=(just="code", pos=(dx,dy), label="label", com=true)*

   Draw Unix System time stamp on plot. By adding [*just*\ ]\ */dx/dy/*, the
   user may specify the justification of the stamp and where the stamp
   should fall on the page relative to lower left corner of the plot.
   For example, BL/0/0 will align the lower left corner of the time
   stamp with the lower left corner of the plot [LL]. Optionally, append a
   *label*, or **c** (which will plot the command string.). The GMT
   parameters `MAP\_LOGO`, `MAP\_LOGO\_POS`, and
   `FORMAT\_TIME\_STAMP` can affect the appearance; see the
   `gmt.conf` man page for details. The time string will be in the
   locale set by the environment variable **TZ** (generally local time).

   [`-U GMT doc`](https://www.generic-mapping-tools.org/gmt/latest/gmt.html#u-full)

--------------------------

# verbose

- *V* **|** *verbose* : *verbose=true* **|** *verbose=level*

   Select verbose mode, which will send progress reports to *stderr*.
   Choose among 6 levels of verbosity; each level adds more messages:
   - **q** -- Complete silence, not even fatal error messages are produced.
   - **n** -- Normal verbosity: produce only fatal error messages.
   - **c** -- Produce also compatibility warnings (same as when *verbose* is omitted).
   - **v** -- Produce also warnings and progress messages (same as *verbose* only).
   - **l** -- Produce also detailed progress messages.
   - **d** -- Produce also debugging messages.

--------------------------

# x_off

- *X* **|** *x_off*  **|** *x_offset* : *x_off=[]* **|** *x_off=x-shift* **|** *x_off=(shift=x-shift, mov="a|c|f|r")*

# y_off

- *Y* **|** *y_off*  **|** *y_offset* : *y_off=[]* **|** *y_off=y-shift* **|** *y_off=(shift=y-shift, mov="a|c|f|r")*

   Shift plot origin relative to the current origin by (*x-shift*, *y-shift*) and optionally append the
   length unit (**c**, **i**, or **p**). This second case (with units) implies that *x-shift* must be a
   string. To make non-default sifts, use the form *x_off=(shift=x-shift, mov="a|c|f|r")* where **a**
   shifts the origin back to the original position after plotting; **c** centers the plot on the center of
   the paper (optionally add shift); **f** shifts the origin relative to the fixed lower left corner of the
   page, and **r** [Default] to move the origin relative to its current location. For overlays the default
   (*x-shift*, *y-shift*) is (r0), otherwise it is (r1i). When *x_off* or *y_off* are used without any
   further arguments, the values from the last use of that option in a previous GMT command will be used.
   Note that *x_off* and *y_off* can also access the previous plot dimensions *w* and *h* and construct
   offsets that involves them. For instance, to move the origin up 2 cm beyond the height of the previous
   plot, use *y_off="h+2c"*. To move the origin half the width to the right, use *x_off="w/2"*.

# perspective

- **p** **|** **view** **|** **perspective** : *view=(azim, elev)*\
   Selects perspective view and sets the azimuth and elevation of the viewpoint (180,90). When **view**
   is used in consort with **Jz** or **JZ**, a third value can be appended which indicates at which
   z-level all 2D material, like the plot frame, is plotted (in perspective). [Default is at the bottom
   of the z-axis]. 

   [`-p GMT doc`](https://www.generic-mapping-tools.org/gmt/latest/gmt.html#p-full)

# Spherical distance

- **j | spheric_dist** : -- *spheric_dist=:e|:f|:g*\
    Determine how spherical distances are calculated in modules that support this. By default (**spheric_dist=:g**) we perform great circle distance calculations and parameters such as distance increments or radii will be compared against calculated great circle distances. To simplify and speed up calculations you can select Flat Earth mode (**spheric_dist=:f**) which gives an approximate and fast result. Alternatively, you can select ellipsoidal (**spheric_dist=:e**) or geodesic mode for the highest precision (and slowest calculation time). All spherical distance calculations depends on the current ellipsoid (``PROJ_ELLIPSOID``), the definition of the mean radius (``PROJ_MEAN_RADIUS``), and the specification of latitude type (``PROJ_AUX_LATITUDE``). Geodesic distance calculations is also controlled by method (``PROJ_GEODESIC``).

# interp

- **n** **|** *interp* **|** *interpol* : *interp="[b|c|l|n][+a][+bBC][+c][+tthreshold]"*\

   Select grid interpolation mode by adding b for B-spline smoothing, c for bicubic interpolation,
   l for bilinear interpolation, or n for nearest-neighbor value (for example to plot categorical data).
   Optionally, append +a to switch off antialiasing (where supported). Append +bBC to override the boundary
   conditions used, adding g for geographic, p for periodic, or n for natural boundary conditions. For the
   latter two you may append x or y to specify just one direction, otherwise both are assumed. Append +c
   to clip the interpolated grid to input z-min/max [Default may exceed limits]. Append +tthreshold to
   control how close to nodes with NaNs the interpolation will go. A threshold of 1.0 requires all (4 or 16)
   nodes involved in interpolation to be non-NaN. 0.5 will interpolate about half way from a non-NaN value;
   0.1 will go about 90% of the way, etc. [Default is bicubic interpolation with antialiasing and a threshold
   of 0.5, using geographic (if grid is known to be geographic) or natural boundary conditions].

   [`-n GMT doc`](https://www.generic-mapping-tools.org/gmt/latest/gmt.html#n-full)
