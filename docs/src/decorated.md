# Line decorations

There are two different types of decorated lines. Lines decorated with text (quoted lines) and lines decorated
with symbols. This second category is still subdivided in two algorithms. They are all specified by a keyword
(*decorated*) and a named tuple.

    decorated=(dist=..., symbol=..., pen=..., quoted=true, etc)

## Front lines

- *dist=xx* or *distance=xx*\
   Distance gap between symbols and symbol size. If *xx* is a two elements
   array or tuple the first element is *gap* and second the *size*. However, *size* may be ommited
   (defaulting to 30% of the *gap*) and in this case *xx* may be a scalar or a string.
- *number=xx*\
   Instead of the above, use this option to set the number of symbols along the front instead,
   but in this case *xx* must be a two elements array or tuple with the number and size.
- *left=true*\
   Plot symbols on the left side of the front
- *right=true*\
   Plot symbols on the right side of the front
- *len=xx* or *length=xx*\
   Length of the vector head. *xx* may be numeric, a string with the length
   and the units attached (as in len="2c") or a tuple with length and units as in *len=(2,:centimeters)*
- *pen=pen*\
   Use an alternate pen. The *pen* value may contain any of valid ways of specifying pens.
- *symbol=* -- Specify which symbol to plot:
  - *symbol=:box*
  - *symbol=:circle*
  - *symbol=:fault*
  - *symbol=:triangle*
  - *symbol=:slip*  -- Left-lateral or right-lateral strike-slip arrows.
  - *symbol=:arcuate*  -- Draws arcuate arrow heads
- *offset=xx* -- Offset the first symbol from the beginning of the front by that amount [0].

## Decorated lines

To select this type the *dec2=true* keyword/value must be present in the *decorated* args.
The required setting controls the placement of labels along the quoted lines. Choose among the controlling
algorithms.

### [Placement methods:](@id placement_method_dec)

- *dist=xx* or *distance=xx*\
   Give distances between labels on the plot in your preferred measurement unit.
  *xx* may be a scalar or a string. Use strings when appending the units c (cm), i (inch), or p (points).
- *distmap=xx*\
   Like above but specify distances in map units and append the unit; choose among e (m),
   f (foot), k (km), M (mile), n (nautical mile) or u (US survey foot), and d (arc degree), m (arc minute),
   or s (arc second)
- *line=xx*\
   Give the coordinates of the end points for one or more straight line segments.
   Symbols will be placed where these lines intersect the decorated lines. *xx* format is a Mx4 array
   with the coordinates of the line's end points. The format of each line specification is
   [start_x start_y stop_x stop_y]. These can be replaced by by a 2-character key that uses the justification
   format employed in text to indicate a point on the frame or center of the map, given as [**LCR**][**BMT**]. In addition, you can use **Z-**, **Z+** to mean the global minimum and maximum locations in the grid (*i.e. line="Z-/Z+"*).
- *Line=xx*\
   Like *line* But will interpret the point pairs as defining great circles.
- *n_labels=xx* or *:n_symbols=xx*\
   Specifies the number of equidistant labels for quoted lines [1].
- *N_labels=xx* or *:N_symbols=xx*\
   Same as above but starts labeling exactly at the start of the line
   [Default centers them along the line]. Optionally, append /min_dist[c|i|p] to enforce that a minimum distance
   separation between successive labels is enforced. In this case *xx* must obviously be a string.

### [Symbol formatting:](@id symb_format_dec)

- *marker=symb* or *symbol=symb*\
   Selects the decorating symbol *symb*. See the [Symbols](@ref) for the list of symbols available.
- *size=xx* or *markersize* or *symbsize* or *symbolsize*\
   Use any of these to set the symbol size. Sizes can be scalars, strings or tuples if a unit is used.
- *angle=xx*\
   For symbols at a fixed angle.
- *debug=true*\
   Turns on debug which will draw helper points and lines to illustrate the workings
   of the decorated line setup.
- *fill=color*\
   Sets the symbol fill. The *color* is a [Setting color](@ref) element.
- *pen=pen*\
   Draws the outline of symbols; optionally specify pen for outline [Default is width = 0.25p,
   color = black, style = solid]. The *pen* value may contain any of valid ways of specifying pens.
- *nudge=xx*\
   Nudges the placement of symbols by the specified amount. *xx* may be a scalar, a 2 elements
   array (to separate x and y nudges) or a string. Must use a string if units are used.
- *n_data=xx*\
   Specifies how many (x,y) points will be used to estimate symbol angles [Default is 10].

## Quoted lines

To select this type the *quoted=true* keyword/value must be present in the *decorated* args.
Lines with annotations such as contours. The required setting controls the placement of labels along the quoted
lines. Choose among the controlling algorithms.

### [Placement methods:](@id placement_method_quot)

- *dist=xx* or *distance=xx*\
   Give distances between labels on the plot in your preferred measurement unit.
  *xx* may be a scalar or a string. Use strings when appending the units c (cm), i (inch), or p (points).
- *distmap=xx*\
   Similar to above but specify distances in map units and append the unit; choose among e (m),
   f (foot), k (km), M (mile), n (nautical mile) or u (US survey foot), and d (arc degree), m (arc minute),
   or s (arc second).
- *line=xx*\
   Give the coordinates of the end points for one or more straight line segments.
   Symbols will be placed where these lines intersect the quoted lines. *xx* format is a Mx4 array
   with the coordinates of the line's end points. The format of each line specification is
   [start_x start_y stop_x stop_y]. These can be replaced by a 2-character key that uses the justification
   format employed in text to indicate a point on the frame or center of the map, given as [**LCR**][**BMT**].
- *Line=xx*\
   Like *line* But will interpret the point pairs as defining great circles.
- *n_labels=xx* or *:n_symbols=xx*\
   Specifies the number of equidistant labels for quoted lines [1].
- *N_labels=xx* or *:N_symbols=xx*\
   Same as above but starts labeling exactly at the start of the line
   [Default centers them along the line]. Optionally, append /min_dist[c|i|p] to enforce that a minimum distance
   separation between successive labels is enforced. In this case *xx* must obviously be a string.

### [Label formatting:](@id label_format_quot)

- *angle=xx*\
   For symbols at a fixed angle.
- *clearance=xx*\
   Sets the clearance between label and optional text box. *xx* may be a scalar, a 2 elements
   array (to separate x and y clearances) or a string. Must use a string if units are used. Use % to indicate
   a percentage of the label font size [15%].
- *color=color*\
   Selects opaque text boxes [Default is transparent]; optionally specify the color [Default is PS\_PAGE\_COLOR].
   The *color* is a [Setting color](@ref) element.
- *const_label="xx"*\
   Sets the constant label text.
- *curved=true*\
   Specifies curved labels following the path [Default is straight labels].
- *debug=true*\
   Turns on debug which will draw helper points and lines to illustrate the workings
   of the decorated line setup.
- *delay=true*\
   Delay the plotting of the text. This is used to build a clip path based on the text, then lay
   down other overlays while that clip path is in effect, then turning of clipping with clip -Cs which
   finally plots the original text.
- *font=xx*\
   Sets the desired font [Default FONT_ANNOT_PRIMARY with its size changed to 9p]. *xx* is a
   [Setting fonts](@ref) element.
- *justify=xx*\
   Sets label justification [Default is MC]. *xx* is a two char justification code (see [Justify](@ref)).
- *label=xx*\
  Sets the label text according to the specified option. Where *xx* may be a symbol or a tuple:
  - *label=:header*  -- Take the label from the current segment header
  - *label=:input*   -- Use text after the 2nd column in the fixed label location file as the label.
     Requires the fixed label location setting.
  - *label=(:plot_dist,"unit")*  -- Take the Cartesian plot distances along the line as the label.
     Use any of c|i|p as the *unit*.
  - *label=(:map_dist,"unit")* --  Calculate actual map distances. Use any of d|e|f|k|n|M|n|s as the *unit*.
- *min_rad=xx*\
   Do not place labels where the line’s radius of curvature is less than min_rad [Default is 0]. 
- *nudge=xx*\
   Nudges the placement of symbols by the specified amount. *xx* may be a scalar, a 2 elements
   array (to separate x and y nudges) or a string. Must use a string if units are used.
- *n_data=xx*\
   Specifies how many (x,y) points will be used to estimate symbol angles [Default is 10].
- *pen=pen*\
   Draws the outline of text boxes; optionally specify pen for outline
   [Default is width = 0.25p, color = black, style = solid]. The *pen* value may contain any of valid ways
   of specifying pens.
- *prefix=xx*\
   Prepends prefix (*xx* is a string) to all line labels. If prefix starts with a leading hyphen
   (-) then there will be no space between label value and the prefix.
- *rounded=true*\
   Selects rounded rectangular text box [Default is rectangular].
- *suffices="first,last"*\
   Append the suffices `first` and `last` to the corresponding labels. Used to
   annotate the start and end of a line [Default just adds a prime to the second label].
- *unit=xx*\
   Appends unit (*xx* is a string) to all line labels. If unit starts with a leading hyphen (-)
   then there will be no space between label value and the unit. [Default is no unit]. 
