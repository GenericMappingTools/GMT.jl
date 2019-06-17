# plot

	plot(cmd0::String="", arg1=[]; kwargs...)


Reads (x,y) pairs and plot lines, polygons, or symbols with different levels of decoration. The input can either be a file name of a file with at least two columns (x,y),but optionally more, a *GMTdatset* object with also two or more columns.
If a symbol is selected and no symbol size given, then it will interpret the third column of the input data as symbol size.
Symbols whose *size* is <= 0 are skipped. If no symbols are specified then the symbol code (see **symbol** below) must be present as last column in the input. If **symbol** is not used, a line connecting the data points will be drawn instead. To explicitly close polygons, use **close**. Select a fill with **fill**. If **fill** is set, **pen** will control whether the polygon outline is drawn or not. If a symbol is selected, **fill** and **pen** determines the fill and outline/no outline, respectively.

Since many options imply further data, to control symbol size and/or color for example, columns beyond 2 for **plot** or 3 for **plot3d** cannot be used to plot multiple lines at once (like Matlab does). However, that is stil possible if one uses the form `plot(x, y, ...`) where *x* is the coordinates vector or a matrix with only one column or row and *y* is a matrix with *N* columns representing the individual lines and *M* rows, as many as elements in *x*. This case, off course, looses the possibility of having extra columns with options auxiliary data. Still, another possibility to achieve this when *arg1* is a *MxN* matrix is to use the key/val **multicol=true**. Automatic legends are obtained by using **legend=true**.

Selecting both a **symbol** and a **pen** plots a line and add the sybols at the vertex.

Parameters
----------

- **A** or *steps* : -- *steps=true* **|** *steps=:meridian|:parallel|:x|:y*\
   By default, geographic line segments are drawn as great circle arcs. To draw them as straight lines, use the **steps=true**. Alternatively, use **steps=:meridian** to draw the line by first following a meridian, then a parallel. Or append **steps=:parallel** to start following a parallel, then a meridian. (This can be practical to draw a line along parallels, for example). For Cartesian data, points are simply connected, unless you use **steps=:x** or **steps=:y** to draw stair-case curves that whose first move is along *x* or *y*, respectively.

- **B** or *axis* or *frame*\
   Set map boundary frame and axes attributes. Default is to draw and annotate left and bottom axes.
   More at [axis](@ref)

- **C** or **color** or **cmap** : *color=cpt*\
   Give a CPT or specify **color="color1,color2 [,color3 ,...]"** or **color=((r1,g1,b1),(r2,g2,b2),...)** to build a linear continuous CPT from those colors automatically, where *z* starts at 0 and is incremented by one for each color. In this case *color_n* can be a [r g b] triplet, a color name, or an HTML hexadecimal color (e.g. #aabbcc ). If **-S** is set, let symbol fill color be determined by the z-value in the third column. Additional fields are shifted over by one column (optional size would be 4th rather than 3rd field, etc.). If **-S** is not set, then it expects the user to supply a multisegment file where each segment header contains a **-Z**\ *val* string. The *val* will control the color of the line or polygon (if **-L** is set) via the CPT.

- **D** or *shift* or *offset* : *offset=(dx,dy)* **|** *offset=dx*\
   Offset the plot symbol or line locations by the given amounts *dx,dy* [Default is no offset]. If *dy* is not given it is set equal to *dx*.

- **E** or *error* or *error_bars* : -- *error=(x|y|X|Y=true, wiskers=true, cap=width, pen=pen, colored=true, cline=true, csymbol=true)*\
   Draw symmetrical error bars. Use **error=(x=true)** and/or **error=(y=true)** to indicate which bars you want to draw (Default is both x and y). The x and/or y errors must be stored in the columns after the (x,y) pair [or (x,y,z) triplet]. If **asym=true** is appended then we will draw asymmetrical error bars; these requires two rather than one extra data column, with the low and high value. If upper case **error=(X=true)** and/or **Y** are used we will instead draw "box-and-whisker" (or "stem-and-leaf") symbols. The x (or y) coordinate is then taken as the median value, and four more columns are expected to contain the minimum (0% quantile), the 25% quantile, the 75% quantile, and the maximum (100% quantile) values. The 25-75% box may be filled by using **fill**. If **wiskers=true** is appended the we draw a notched "box-and-whisker" symbol where the notch width reflects the uncertainty in the median. This symbol requires a 5th extra data column to contain the number of points in the distribution. The **cap=width** modifier sets the *cap* width that indicates the length of the end-cap on the error bars [**7p**]. Pen attributes for error bars may also be set via **pen=pen**. [Defaults: width = default, color = black, style = solid]. When **color** is used we can control how the look-up color is applied to our symbol. Add **cline=true** to use it to fill the symbol, while **csymbol=true** will just set the error pen color and turn off symbol fill. Giving **colored=true** will set both color items.

- **F** or *conn* or *connection* : -- *conn=(continuous=true, net|network=true, refpoint=true, ignore_hdr=true, single_group=true, segments=true, anchor=(x,y))*\
   Alter the way points are connected (by specifying a *scheme*) and data are grouped (by specifying a *method*).
   Use one of three line connection schemes:\
   **continuous=true** : Draw continuous line segments for each group [Default].\
   **refpoint=true** : Draw line segments from a reference point reset for each group.\
   **network=true** : Draw networks of line segments between all points in each group.\
   Optionally, use one of four segmentation methods to define the group:\
   **ignore_hdr=true** : Ignore all segment headers, i.e., let all points belong to a single group, and set group reference point to the very first point of the first file.
   **single_group=true** : Consider all data in each file to be a single separate group and reset the group reference point to the first point of each group.
   **segments=true** : Segment headers are honored so each segment is a group; the group reference point is reset to the first point of each incoming segment [Default].
   **segments_reset=true** : Same as **segments=true**, but the group reference point is reset after each record to the previous point (this method is only available with the **refpoint=true** scheme). Instead of the codes **ignore_hdr**, **single_group**, **segments**, **segments_reset** you may append the coordinates of a **anchor=(x,y)** which will serve as a fixed external reference point for all groups.

- **J** or *proj* : *proj=<parameters>*\
   Select map projection. Default is linear and 14 cm width. More at [proj](@ref)

- **Jz** or **JZ** or *zscale* or *zsize* (*for* **plot3d** *only*) : -- *zscale=scale* **|** *zsize=size*\
   Set z-axis scaling or or z-axis size. ``zsize=size`` sets the size to the fixed value *size*
   (for example *zsize=10* or *zsize=4i*). ``zscale=scale`` sets the vertical scale to UNIT/z-unit.

- **R** or *region* or *limits* : *limits=(xmin, xmax, ymin, ymax)* **|** *limits=(BB=(xmin, xmax, ymin, ymax),)*
   **|** *limits=(LLUR=(xmin, xmax, ymin, ymax),units="unit")* **|** ...more \
   Specify the region of interest. By default, the limits are computed from data extents. More at [limits](@ref)

- **G** or *markerfacecolor* or *mc* or *fill*\
   Select color or pattern for filling of symbols or polygons [Default is no fill]. Note that plot will search for *fill* and *pen* settings in all the segment headers (when passing a GMTdaset or file of a multi-segment dataset) and let any values thus found over-ride the command line settings (but those must be provided in the terse GMT syntax). See [Setting color](@ref) for extend color selection (including colormap generation).

- **-I** or **shade** : -- *shade=intens*\
    Use the supplied *intens* value (nominally in the -1 to +1 range) to modulate the fill color by simulating illumination [none]. If no intensity is provided (*e.g.* **shade=""**) we will instead read *intens* from the first data column after the symbol parameters (if given).

- **-L** or *close* : -- *close=(sym=true, asym=true, envelope=true, left=true, right=true, x0=x0, top=true, bot=true, y0=y0, pen=pen)*\
    Force closed polygons. Alternatively, add modifiers to build a polygon from a line segment.
    Add **sym=true** to build symmetrical envelope around y(x) using deviations dy(x) given in extra column 3.
    Add **asym=true** to build asymmetrical envelope around y(x) using deviations dy1(x) and dy2(x) from extra columns 3-4.
    Add **envelope=true** to build asymmetrical envelope around y(x) using bounds yl(x) and yh(x) from extra columns 3-4.
    Add **left=true** or **right=true** or **x0=x0** to connect first and last point to anchor points at either *xmin*, *xmax*, or *x0*, or\
    **bot=true** or **top=true** or **y0=y0** to connect first and last point to anchor points at either *ymin*, *ymax*, or *y0*.\
    Polygon may be painted (**fill**) and optionally outlined by adding **pen=pen**.

- **N** or **noclip** or **no\_clip** : *noclip=true* **|** *noclip=:r* **|** *noclip=:c*\
   Do NOT clip symbols that fall outside map border [Default plots points whose coordinates are strictly inside the map border only]. This option does not apply to lines and polygons which are always clipped to the map region. For periodic (360-longitude) maps we must plot all symbols twice in case they are clipped by the repeating boundary. The **noclip** will turn off clipping and not plot repeating symbols. Use **noclip=:r** to turn off clipping but retain the plotting of such repeating symbols, or use **noclip=:c** to retain clipping but turn off plotting of repeating symbols.

- **S** or *symbol* : -- *symbol=(symb=name, size=val, unit=unity)* or *marker|Marker|shape=name*, *markersize| MarkerSize|ms|size=val*\
   Plot symbols (including vectors, pie slices, fronts, decorated or quoted lines). If present, size is symbol size in the unit set in gmt.conf (unless *c*, *i*, or *p* is appended to **markersize** or synonym or *cm*, *inch*, *point* as unity when using the **symbol=(symb=name,size=val,unitunity)** form). If the symbol name is not given it will be read from the last column in the input data (must come from a file name or a *GMTdataset*); this cannot be used in conjunction with binary input (data from file). Optionally, append c, i,or p to indicate that the size information in the input data is in units of cm, inch, or point, respectively [Default is ``PROJ\_LENGTH\_UNIT``]. Note: if you provide both size and symbol via the input file you must use ``PROJ\_LENGTH\_UNIT`` to indicate the unit used for the symbol size or append the units to the sizes in the file. If symbol sizes are expected via the third data column then you may convert those values to suitable symbol sizes via the **incol** mechanism.\
   You can change symbols by adding the required -S option to any of your multisegment headers (*GMTdataset* only). Choose between these symbol codes:\
   **-** or **x-dash**  size is the length of a short horizontal (x-dir) line segment.\
   **+** or **plus**    size is diameter of circumscribing circle.\
   **a** or * or **star**  size is diameter of circumscribing circle.\
   **c** or **circle**  size is diameter of circle.\
   **d** or **diamond** size is diameter of circumscribing circle.\
   **e** or **ellipse** Direction (in degrees counter-clockwise from horizontal), major\_axis, and minor\_axis must be found in columns 3, 4, and 5.\
   **E** or **Ellipse** Same as **ellipse**, except azimuth (in degrees east of north) should be given instead of direction. The azimuth will be mapped into an angle based on the chosen map projection (**ellipse** leaves the directions unchanged.) Furthermore, the axes lengths must be given in geographical instead of plot-distance units. An exception occurs for a linear projection in which we assume the ellipse axes are given in the same units as **region**. For degenerate ellipses (circles) with just the diameter given, use **Ellipse-**. The diameter is excepted to be given in column 3. Alternatively, append the desired diameter to **E-** and this fixed diameter is used instead (*e.g.* **symbol="E-500"**). For allowable geographical units, see UNITS.\
   **front**    Draw a front. See [Front lines](@ref)\
   **g** or **octagon**  size is diameter of circumscribing circle.\
   **h** or **hexagon**  size is diameter of circumscribing circle.\
   **i** or **v** or **inverted\_tri**  size is diameter of circumscribing circle.\
   **j** or **rotated\_rec**  Rotated rectangle. Direction (in degrees counter-clockwise from horizontal), x-dimension, and y-dimension must be found in columns 3, 4, and 5.\
   **J** or **Rotated\_rec**  Same as **rotated\_rec**, except azimuth (in degrees east of north) should be given instead of direction. The azimuth will be mapped into an angle based on the chosen map projection (**rotated\_rec** leaves the directions unchanged.) Furthermore, the dimensions must be given in geographical instead of plot-distance units. For a degenerate rectangle (square) with one dimension given, use **J-**. The dimension is excepted to be given in column 3. Alternatively, append the dimension diameter to **J-** and this fixed dimension is used instead. An exception occurs for a linear projection in which we assume the dimensions are given in the same units as **region**. For allowable geographical units, see UNITS.\
   **m** or **matang**  math angle arc, optionally with one or two arrow heads [Default is no arrow heads]. The size is the length of the vector head. Arc width is set by **pen**, with vector head outlines defaulting to half of arc width. The radius of the arc and its start and stop directions (in degrees counter-clockwise from horizontal) must be given in columns 3-5. See [Vector Attributes](@ref) for specifying other attributes.\
   **M** or **Matang**  Same as **matang** but switches to straight angle symbol if angles subtend 90 degrees exactly.\
   **n** or **pentagon**  size is diameter of circumscribing circle.\
   **p** or **point**  No size needs to be specified (1 pixel is used).\
   **quoted lines**    i.e., lines with annotations such as contours. See [Quoted lines](@ref)\
   **r** or **rectangle**  No size needs to be specified, but the x- and y-dimensions must be found in columns 3 and 4.\
   **R** or **roundrect**  Rounded rectangle. No size needs to be specified, but the x- and y-dimensions and corner radius must be found in columns 3, 4, and 5.\
   **s** or **square**    size is diameter of circumscribing circle.\
   **t** or **^** or **triangle**  size is diameter of circumscribing circle.\
   **x** or **cross**    size is diameter of circumscribing circle.\
   **y** or **y-dash**  (|). size is the length of a short vertical (y-dir) line segment.\
   **decorated**    i.e., lines with symbols along them. See [Decorated lines](@ref)\

- **W** or *pen=pen*\
   Set pen attributes for lines or the outline of symbols [Defaults: width = default, color = black, style = solid]. See [Pen attributes](@ref). 
   If the modifier **pen=(cline=true)** is appended then the color of the line are taken from the CPT (see **cmap**). If instead modifier **pen=(csymbol=true)** is appended then the color from the cpt file is applied to symbol fill. Use **pen=(colored=true)** for both effects.
   You can also append one or more additional line attribute modifiers: **offset=val** will start and stop drawing the line the given distance offsets from the end point. Append unit **u** from **c** | **i** | **p** to indicate plot distance on the map or append map distance units instead (see below);
   **bezier=true** will draw the line using a Bezier spline; *vspecs* will place a vector head at the ends of the lines. You can use **vec\_start** and **vec\_stop** to specify separate vector specs at each end [shared specs]. See the [Vector Attributes](@ref) for more information.

- **U** or *stamp* : *stamp=true* **|** *stamp=(just="code", pos=(dx,dy), label="label", com=true)*\
   Draw GMT time stamp logo on plot. More at [stamp](@ref)

- **V** or *verbose* : *verbose=true* **|** *verbose=level*\
   Select verbosity level. More at [verbose](@ref)

- **X** or *x_off* or *x_offset* : *x_off=[] **|** *x_off=x-shift* **|** *x_off=(shift=x-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [x_off](@ref)

- **Y** or *y_off* or *y_offset* : *y_off=[] **|** *y_off=y-shift* **|** *y_off=(shift=y-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [y_off](@ref)

Units
-----

For map distance unit, append unit **d** for arc degree, **m** for arc minute, and **s** for arc second, or **e** for meter [Default], **f** for foot, **k** for km, **M** for statute mile, **n** for nautical mile, and **u** for US survey foot. By default we compute such distances using a spherical approximation with great circles (**spheric\_dist=:g**). You can use **spheric\_dist=:f** to perform “Flat Earth” calculations (quicker but less accurate) or **spheric\_dist=:e** to perform exact geodesic calculations (slower but more accurate; see ``PROJ\_GEODESIC`` for method used).

Examples
--------

Decorated curve with blue stars

```julia
    xy = gmt("gmtmath -T0/180/1 T SIND 4.5 ADD");
    lines(xy, axis=:af, pen=(1,:red), decorated=(dist=(2.5,0.25), symbol=:star,
          symbsize=1, pen=(0.5,:green), fill=:blue, dec2=true), show=true)
```