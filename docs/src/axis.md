# The axis control

Set map Axes parameters. They are specified by a keyword and a named tuple (but see [1])

    axis=(axes=..., corners=..., xlabel=..., ylabel=..., annot=..., etc)

or separated on a per axes basis by using specific *xaxis*, *yaxis* and *zaxis* that share the same syntax
as the generic *axis* option.

By default, all 4 map boundaries (or plot axes) are plotted and annotated. To customize, use the *axes*
keyword that takes as value a tuple with a combination of words. Axes are named *left*, *bottom*, *right*,
*top* and, for the 3D maps, *up*. Next we have three categories of axes: the *annotated and ticked*, the *ticked*
and those with no annoations and no tick marks. We call them *full*, *ticks* and *bare* and combine with the axes
name using an underscore to glue them. Hence *left_full* means draw and annotate left axes, whilst *top_bare*
means draw only top axes. The full combination is *left|bottom|right|top|up_full|ticks|bare*. To not draw a
boundary, simply ommit the name of it in tuple. Note that the short one single char naming used by GMT is also
valide. E.g. *axes=:WSn* will draw and annotate left and south bondaries and draw but no ticks or anotations
the top boundary.

If a 3-D basemap is selected with *view* and *J=:z*, by default a single vertical axes will be plotted at
the most suitable map corner. Override the default by using the keyword *corners* and any combination of
corner ids **1234**, where **1** represents the lower left corner and the order goes counter-clockwise.

Use *cube=true* to draw the outline of the 3-D cube defined by *region* this option is also needed to display
gridlines in the x-z, y-z planes. Note that for 3-D views the title, if given, will be
suppressed. You can paint the interior of the canvas with `fill=fill` where the *fill* value can be a color or a pattern.

Use *noframe=true* to have no frame and annotations at all [Default is controlled by the codes].

Optionally append *oblique_pole="plon/plat"* (or *oblique_pole=(plon,plat)* to draw oblique gridlines about
specified pole [regular gridlines]. Ignored if gridlines are not requested (below) and disallowed for the oblique
Mercator projection.

To add a plot title do *title="My title"* The Frame setting is optional but can be invoked once to override the above defaults.

GMT uses the notion of *primary* (the default) and *secondary* axes. To set an axes as secondary, use
*secondary=true* (mostly used for time axes annotations).

The *xaxis* *yaxis* and *zaxis* specify which axis you are providing information for. The syntax is the same as for
the *axis* keyword but allows fine tunning of different options for the 4 (or 6) axis.

To add a label to an axis use *label="Label text"* if using the *xaxis* etc form, or use the *xlabel*, *ylabel*
and *zlabel* keywords in the common *axis* tuple of options.

Use *Yhlabel=true* to force a horizontal label for *y*-axes (useful for very short labels).

If the axis annotation should have a leading text prefix (e.g., dollar sign for those plots of your net worth) you can
add *prefix="prefix"* For geographic maps the addition of degree symbols, etc. is automatic (and controlled by the
GMT default setting [FORMAT\_GEO\_MAP](http://gmt.soest.hawaii.edu/doc/latest/gmt.conf.html#format-geo-map)).
However, for other plots you can add specific units by adding *label_unit="unit"*

Annotations, ticks and grid intervals are specified with the *annot*, *ticks* and *grid* keywords, which take
as value the desired stride interval. As an example, *annot=10* means annotate at spacing of 10 data units.
Alternatively, for linear maps, we can use the special value *:auto* annotations at automatically determined intervals.

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
*intfile* contains any number of records with *coord* *type* [*label*]. Here, *type* is one or more
letters from **a** or **i**, **f**, and **g**. For **a** or **i** you must supply a *label* that will
be plotted at the *coord* location.

For non-geographical projections: Give negative scale (in *proj="x scale"* or axis length (in *proj="X map width"*
to change the direction of increasing coordinates (i.e., to make the y-axis positive down).

For log10 axes: Annotations can be specified in one of three ways: 

1. *stride* can be 1, 2, 3, or -*n*. Annotations will then occur at 1,
       1-2-5, or 1-2-3-4-...-9, respectively; for -*n* we annotate every
       *n*'t magnitude. This option can also be used for the frame and grid intervals. 

2. Use *log=true*, then log10 of the tick value is plotted at every integer log10 value.

3. Use *10log=true*, then annotations appear as 10 raised to log10 of the tick value.

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
| axes          | left_full     | Str or Symb   | Annot and tick left axis |
|               | left_ticks    | Str or Symb   | Tick left axis |
|               | left_bare     | Str or Symb   | Just draw left axis |
|               | bottom_full   | Str or Symb   | Same for bottom axis |
|               | right_full    | Str or Symb   | Same for right axis |
|               | top_full      | Str or Symb   | Same for top axis |
|               | up_full       | Str or Symb   | Same for z axis |
| corners       | 1234          | Str or Symb   | Vertical axis |
| scondary      | true or false | Bool          | Secondary axis info |
| fill          | `color`       | Str or Symb   | Paint interior |
| cube          | anything      | Sym or Bool   | Draw outline of the 3-D cube |
| noframe       | anything      | Sym or Bool   | No frame and annotations at all |
| oblique_pole  | lon lat       | Str or Tuple  | Draw oblique gridlines abot pole |
| title         | the title     | Str or Symb   | Add a plot title |
| label         | axis label    | Str or Symb   | Add a label to an axis |
| Ylabel        | y-axis hlabel | Str or Symb   | Horizontal label for y-axes |
| prefix        | annot prefix  | Str or Symb   | Annot leading text prefix |
| xlabel        | x-axis label  | Str or Symb   | Add a label to X axis |
| ylabel        | y-axis label  | Str or Symb   | Add a label to Y axis |
| zlabel        | z-axis label  | Str or Symb   | Add a label to Z axis |
| annot         | annot interval| Symb or Num   | Annot stride interval |
| ticks         | tick interval | Symb or Num   | Tick interval |
| grid          | grid interval | Symb or Num   | Grid lines interval |
| phase_add     | xx            | Numb          | Shifts right the annot interval |
| phase_sub     | xx            | Numb          | Shifts left the annot interval |
| annot_unit    | annot unit    | Str or Symb   | Unit of the *stride* |
| custom        | custom annot  | Str or Symb   | Custom annotations file |
| pi            | n or (n,m)    | Num or Tuple  | If axis is in radians |
| scale         | log           | Str or Symb   | log10 of the tick value |
|               | 10log         | Str or Symb   | Annot as 10 raised to log10 |
|               | exp           | Str or Symb   | Annot interval in transformed units |

[1] However, the original GMT compact syntax can also be used. I.e, *axis=:a*, or *frame=:WSen*
or *frame="a1Of1d WS"* also work.

## Examples