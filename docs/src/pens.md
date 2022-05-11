# Pen attributes

A pen in GMT has three attributes: width, color, and style. Most programs will accept pen attributes in the form
of an option argument, with commas separating the given attributes, e.g.,

```
pen=(width, color, style)
or
pen=(width=?, color=?, style=?)
```

### width

Width is by default measured in points (1/72 of an inch). Append *c*, *i*, or *p* to specify pen width
in cm, inch, or points, respectively (but note that this form requires using a string instead of a number).
Minimum-thickness pens can be achieved by giving zero width. The result is device-dependent but typically
means that as you zoom in on the feature in a display, the line thickness stays at the minimum.
For plotting poly-lines `width` can be a vector of thicknesses in which case a line of varible thickness will
be plotted. Linear interpolation to is applyied to the thickness vector in order to obtain an idividual
thickness for each of the segments of the poly-line.

### color

The color can be specified in each following ways:

1. Gray. Specify a gray shade in the range 0–255 (linearly going from black [0] to white [255]).
2. RGB. Specify r/g/b, each ranging from 0–255. Here 0/0/0 is black, 255/255/255 is white, 255/0/0 is red, etc.
   Alternatively, you can give RGB in hexadecimal using the #rrggbb format. All of these forms must be provided
   as strings
3. HSV. Specify hue-saturation-value, with the former in the 0–360 degree range while the latter two take
   on the range 0–1 17 (string).
4. CMYK. Specify cyan/magenta/yellow/black, each ranging from 0–100% (string).
5. Name. Specify one of 663 valid color names. See gmtcolors for a list of all valid names.
   A very small yet versatile subset consists of the 29 choices white, black, and [light|dark]
   {red, orange, yellow, green, cyan, blue, magenta, gray|grey, brown}. The color names are case-insensitive,
   so mixed upper and lower case can be used (like DarkGreen). This can be provided as a String or Symbol.
6. For 2D or 3D polylines `grad` or `gradient` means each line segment will be colored by consulting a
   colormap. If that colormap is not provided we create one based on the poly-line number of segments.
### line style

The style attribute controls the appearance of the line. Giving `dot` or `.` yields a dotted line,
whereas a dashed pen is requested with `dash` or `-`. Also combinations of dots and dashes, like `.-`
for a dot-dashed line, are allowed. The lengths of dots and dashes are scaled relative to the pen width
(dots has a length that equals the pen width while dashes are 8 times as long; gaps between segments are
4 times the pen width). It is however not possible to mix the word and char forms. Valid styles are for
example `DashDot`, `dashdashdot`, `dotdotdash`, `-.` , `--.` The style words are case-insensitive.

For more detailed attributes including exact dimensions you may specify string, where string is a series
of numbers separated by underscores. These numbers represent a pattern by indicating the length of line
segments and the gap between segments. For example, if you want a yellow line of width 0.1 cm that alternates
between long dashes (4 points), an 8 point gap, then a 5 point dash, then another 8 point gap, specify
`pen=("0.1c",:yellow,"4_8_5_8")`. Just as with pen width, the default style units are points, but can also
be explicitly specified in cm, inch, or points.

Line styles can also be provided autonomously via the `linestyle` (or short `ls`) keywords. For example,
`ls=:dash`. An interesting extension to the above line styles is when we add also a symbol and make an
annotated line. The syntax is to add the symbol name to the style specification separated by one the
three characters `&`, `_` or `!`. *e.g.* `"Line&Circ"` or
`:DashDot!Square`. This will draw an open symbol with outline color and thickness equal to line width.
The symbols size and spacing are computed to be 4 times the line width and spacing. Append a non-letter
char like `#` or `%` (*e.g.* `"Line&Triang#"`) to plot symbols with a white outline and filled with
line color. If you want to annotate with a text string, wrap whatever text in a pair of those three characters.
For example `"Line&Silly saying&"`

[Front lines](https://docs.generic-mapping-tools.org/latest/plot.html#id7) can also be drawn with the
`linestyle` mechanism. For that, use the form: "FrontSymbol[left|right]" where `Symbol` can be any of
`Circle`, `Box`, `Triangle`, `Slip`, `Fault` (case-insensitive and only first char is parsed). The `Left`
or `Right` options mean that only half of the symbol will be plotted. Either on the left or right side
of the line. Example `ls=FrontTriangleLeft` will draw a ``subduction zone`` line.

The above line and symbol at fixed spacing is nice but there are many instances where one wants to have
a line and symbols only at vertex locations. While that can generally be achieved by using the `marker`,
`markersize` (`mc`), `markercolor` (`mc`) and `linecolor` (`lc`), `linewidth` (`lw`)
keywords we can also use a condensed form similar to the annotated lines above. In this case we drop
the separating char and compose it only with the line style and symbol name, *e.g.* `"LineCirc"`.

The annotated, quoted and front lines short forms presented here use several heuristics to decide
on symbol size, symbol separation, fill collor, outline pen, etc ... But one can overwrite most of
those guesses by using the `markersize`, `markecolor`, `markerline` options of the `plot` module.

In addition to these pen settings there are several PostScript settings that can affect the appearance of lines.
These are controlled via the GMT defaults settings `PS_LINE_CAP`, `PS_LINE_JOIN`, and `PS_MITER_LIMIT`.
See the end of the GMT CookBook section on [Specifying pen attributes](https://docs.generic-mapping-tools.org/latest/cookbook/features.html#specifying-pen-attributes)
for a visual display on the effect of changing these defaults.
