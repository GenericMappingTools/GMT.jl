# subplot

	subplot(fim=nothing; stop=false, kwargs...)

**subplot** module is used to split the current figure into a rectangular layout of subplots
that each may contain a single self-contained figure. A subplot setup is started with the **subplot**
directive that defines the layout of the subplots, while positioning to a particular subplot for
plotting is done via the **subplot(:set, ...)** directive. The subplot process is completed via the
**subplot(:end)** or **subplot(:show)** directives.


**subplot** : -- *subplot=(:set, :end, show; grid=..., dims=..., panels_size=..., autolabel=..., clearance=..., axes=..., proj=..., margins=..., region=..., layout, title=..., figname=..., name=..., savefig=..., fmt=...)*

Required Arguments
------------------

- **grid** : *grid="nrows x ncols"* **|** *grid=(nrows, ncols)*\
    Specifies the number of rows and columns of subplots.  Each row will have the same number of subplots.
    **Note1**: Use NO spaces with the first form. *i.e.* **grid="2x2"** and **NOT** *grid=" 2 x 2"*\
    **Note2**: You are not required to place a plot in each subplot.


- **F** or **dims** ir **dimensions** or **size** or **sizes** : -- *dims=(panels=(w,h), size=(w,h), frac=(), clearance=(dx,dy), outline=pen, fill=color, divlines=pen)*\
    Specify the dimensions of the figure. There are two different ways to do this:
    1. With the keyword **size** Specify overall figure dimensions\
    2. With the keyword **panels** specify the dimensions of a single subplot.

    **size**\
    Specify the final figure dimensions. The subplot dimensions are then calculated from the figure dimensions after accounting for the space that optional tick marks, annotations, labels, and margins occupy between subplots. As for other figures, annotations, ticks, and labels along the outside perimeter are not counted as part of the figure dimensions. To specify different subplot dimensions for each row (or column), append **frac** with value given as a tuple of *width* nd *height* fractions. For example **dims=(size=(10,10), frac=((3,1),(1,2)))** will make the first column three times as wide as the second, while the second row will be twice as tall as the first row. A single number means constant widths (or heights) [Default]. If prefered, instead of *size* and/or *frac* as tuples, the **width=x, height=y, fwidth=(...), fheight=(...)** form is also allowed. 

    **panels**\
    Specify the dimensions of each subplot directly. Then, the figure dimensions are computed from the subplot dimensions after adding the space that optional tick marks, annotations, labels, and margins occupy between subplots. As for other figures, annotations, ticks, and labels along the outside perimeter are not counted as part of the figure dimensions. To specify different subplot dimensions for each row (or column), append a comma-separated list of widths, a slash, and then the comma-separated list of heights. A single number means constant widths (or heights) [Default]. For example **dims=(panels=((5,8),8),)** will make the first column 5 cm wide and the second column 8 cm wide, with all having a constant height of 8 cm. The number of values must either be one (constant across the rows or columns) or exactly match the number of rows (or columns). For geographic maps, the height of each subplot depends on your map region and projection. There are two options: (1) Specify both **limits** and **projection** and we use these to compute the height of each subplot. All subplots must share the same region and projection and you specify a zero *height*, or (2) you can select *height* based on trial and error to suit your plot layout.

    Optionally, you may draw the outline (**outline=pen**) or paint (**fill=color**) the figure rectangle behind the subplots, add dividing lines between panels (**divlines=pen**), and even expand it via **clearance=(dx.dy)**. These are most useful if you supply **axes=:none**, meaning no ticks or annotations will take place in the subplots. See [Setting color](@ref) and [Pen attributes](@ref) for extend color and pen selections.

    But when only want to set panels with a constant size one can use the simpler form **subplot(grid=..., panels_size=8, ...)**, *i.e.* without sing the **dims=(panels=())** form. *panels_size*, *panel_size* and *panel_sizes* are all aliases.

Optional Arguments
------------------

- **A** or **autolabel** : -- autolabel=*(Anchor=tag, anchor=tag, label="", clearance=(dx,dy), fill=color, pen=pen, offset=, roman=Bool, Roman=Bool, vertical=Bool)*\
    Specify automatic tagging of each subplot. Use **label=** either a number or letter (as a string) [Default "a"].
    This sets the tag of the first, top-left subplot and others follow sequentially. Surround the number or letter by parentheses on any side if these should be typeset as part of the tag.
    Use **anchor** or **Anchor** **=refpoint** to specify where the tag should be placed in the subplot [TL, meaning TopLeft].
    **Note**: **anchor** sets the justification of the tag to *refpoint* (suitable for interior tags)
    while **Anchor** instead selects the mirror opposite (suitable for exterior tags).
    - Append **clearance=dx** or **clearance=(dx,dy)** to set the clearance between the tag and a surrounding text box requested via **fill** or **pen** [3p/3p, i.e., 15% of the `FONT_TAG` size dimension].
    - Append **fill=color** to paint the tag's text box with *color* [no painting].
    - Append **offset=dx** or **offset=(dx,dy)** to offset the tag's reference point in the direction implied by the justification [4p/4p, i.e., 20% of the `FONT_TAG` size].
    - Append **pen=pen** to draw the outline of the tag's text box using selected *pen* [no outline].
    - Append **roman=true** to typeset your tag numbers using lowercase Roman numerals.
    - Append **Roman=true** for uppercase Roman numerals [Arabic numerals].
    - Append **vertical=true** to increase tag numbers vertically down columns [horizontally across rows].

- **B** or **axes** or *frame*\
   Set map boundary frame and axes attributes. More at [frame](@ref)

- **C** or **clearance** : -- *clearance=(left=val, right=val, bott=val, bottom=val, top=val))*\
    Reserve a space of dimension *val* between the margin and the subplot on the specified side, using *side* values from **left=val**, **right=val**, **bottom=val**, or **top=val**. No *side* means all sides. Can specify more than one side. Such space will be left untouched by the main map plotting but can be accessed by modules that plot scales, bars, text, etc. Settings specified under **begin** directive apply to all subplots, while settings under **set** only apply to the selected (active) subplot.  **Note**: Common options **x_off** and **y_off** are not available during subplots; use **clearance** instead.

- **J** or **proj** : *proj=<parameters>*\
   Select map projection. More at [proj](@ref)

- **-M** or **margins** : -- *margins=val*\
    This is margin space that is added *between* neighboring subplots (i.e., the interior margins) *in addition*
    to the automatic space added for tick marks, annotations, and labels. The margins can be specified as
    a single value (for same margin on all sides), a pair of values separated by slashes
    (for setting separate horizontal and vertical margins), or the full set of four slash-separated margins
    (for setting separate left, right, bottom, and top margins). The actual gap created is always a sum of
    the margins for the two opposing sides (e.g., east plus west or south plus north margins) [Default is
    half the primary annotation font size, giving the full annotation font size as the default gap].

- **R** or **region** or **limits** : *limits=(xmin, xmax, ymin, ymax)* **|** *limits=(BB=(xmin, xmax, ymin, ymax),)*
   **|** *limits=(LLUR=(xmin, xmax, ymin, ymax),units="unit")* **|** ...more 
   This is useful when all subplots share a common plot domain. In this module, the chosen region will also
   become the default for any data region needed by computational modules. More at [limits](@ref)

- **SC** or **col_axes** : -- *col_axes=(top="", bott="", bottom="", label="", grid=pen))*\
- **SR** or **row_axes** : -- *row_axes=(left="", right="", label="", parallel="", row_title="t", top_row_title="", grid=pen))*\
    Set subplot layout for shared axes. May be set separately for rows (**row_axes**) and columns (**col_axes**).\
    Considerations for **col_axes**:\
    Use when all subplots in a column share a common *x*-range. The first (i.e., **top**) and the last (i.e., **bottom**) rows will have *x* annotations; append **top=""** or **bott=""** to select only one of those two rows [both].
    - Append **label=""** if annotated *x*-axes should have a label [none]; optionally append the label if it is the same for the entire subplot.
      Labels and titles that depends on which row or column are specified as usual via a subplot's own **axes** setting.\
    Considerations for **row_axes**:\
    Use when all subplots in a row share a common *y*-range. The first (i.e., **left**) and the last (i.e., **right**) columns will have *y*-annotations; append **left=""** or **right=""** to select only one of those two columns [both].
    - Append **left=""** if annotated *y*-axes will have a label [none]; optionally, append the label if it is the same for the entire subplot.
    - Append **row_title** to make space for subplot titles for each row; use **top_row_title** for top row titles only [no subplot titles].
    - Append **parallel=""** to make all annotations axis-parallel [horizontal]; if not used you may have to set **clearance** to secure extra space for long horizontal annotations.
    - Append **grid=pen** to draw horizontal and vertical lines between interior panels using selected pen [no lines].

- **T** or **title** : -- *title="Heading"*\
    While individual subplots can have titles (see **-S** or **axes**), the entire figure may also have a
    overarching *heading* [no heading]. Font is determined by setting `FONT_HEADING`.


Synopsis (set mode)
-------------------

- **subplot(:set, panel=..., fixedlabel="Label", clearance=...)**\

Before you start plotting you must first select the active subplot.
**Note**: If any **figsize** or **figscale** option is passed with **auto** as width or scale when plotting subplots,
then the dimensions of the map are automatically determined by the subplot size and your region.
For Cartesian plots: If you want the scale to apply *equally* to both dimensions
then you must specify **proj=:linear, figscale="auto"** [The default **figsize="auto"** will fill the subplot by using unequal scales].

  Optional Arguments
------------------

  - **panel=(row,col)**\
      Sets the current subplot until further notice. **Note**: First *row* or *col* is 1 not 0 like in plain GMT. If not given we go to the next subplot by order specified via **autolabel=(vertical=true,)**. As an alternative, you may bypass the **set** mode and instead supply the common option **panel=(row,col)** to the first plot command you issue in that subplot. GMT maintains information about the current figure and subplot. Also, you may give the one-dimensional *index* instead which starts at 1 and follows the row or column order set via **autolabel=(vertical=true,)**. **panel="next"** or **panel=""** are alternative *index* syntaxes

  - **A** or **fixedlabel** : -- *fixedlabel="Label"*\
      Overrides the automatic labeling with the given string. No modifiers are allowed. Placement, justification, etc. are all inherited from how **autolablel** was specified.

  - **C** or **clearance** : -- *clearance=(left=val, right=val, bott=val, bottom=val, top=val))*\
      Reserve a space of dimension *clearance* between the margin and the subplot on the specified side. This setting has the same syntax and overrides the common clearances set by **clearance** outside the **subplot(:set, ...)** command.


Any number of plotting command can now take place and all output will be directed to the
selected subplot. There are a few other rules that need to be followed:\
(1) The subplot machinery expects the first plotting command in a new subplot window
to take care of plotting the base frame. The particulars of this frame may have been
specified by the **row|col_axes** option. In either case, should you need to set or override
frame and axes parameters then you must specify these **axes** options with this first plot
command.\
(2) The subplot machinery automatically uses the **x_off** and **y_off** options under
the hood so these options are not available while a subplot is active.

Synopsis (end mode)
-------------------

- **subplot(:end)** or **subplot(:show)**\

This command finalizes the current subplot, including any placement of tags, and updates the gmt.history to reflect the dimensions and linear projection required to draw the entire figure outline. This allows subsequent commands, such as colorbar, to use **pos=...** to place bars with
reference to the complete figure dimensions. We also reset the current plot location to where it was prior to the subplot. The keyword **:end** just finishes the plot silently whislst with **:show** the plot is displayed automatically.

- **V** or *verbose* : *verbose=true* **|** *verbose=level*\
   Select verbosity level. More at [verbose](@ref)

- **X** or *x_off* or *x_offset* : *x_off=[] **|** *x_off=x-shift* **|** *x_off=(shift=x-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [x_off](@ref)

- **Y** or *y_off* or *y_offset* : *y_off=[] **|** *y_off=y-shift* **|** *y_off=(shift=y-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [y_off](@ref)

Examples
--------

To make a minimalistic 3x3 basemap layout called panels.pdf, try::

```julia
    subplot(grid="3x3", panels_size=(5,7), region=(0, 100, 0, 80), frame=:WSen, autolabel=1, margins="6p", name="panels.pdf")
        gmtset(MAP_FRAME_TYPE=:plain)

        basemap(panel=1)
        basemap(panel=2, proj=:linear)		# Same as above
        basemap(panel="next", proj=:linear, figsize="auto,auto")

        basemap(panel="", proj=:linear, figsize="auto,auto", axesswap=:x)
        basemap(panel="", proj=:linear, figsize="auto,auto", axesswap=:y)
        basemap(panel="", proj=:linear, figsize="auto,auto", axesswap=:xy)

        basemap(panel=(3,1), proj=:linear, figscale="auto,auto", axesswap=:x)
        basemap(panel="next", proj=:geog, figsize="auto,auto")
        basemap(panel="next", proj=:geog, figsize="auto")
    subplot(:show)
```

and a 2x2 with some symbols and showing more ways of setting the panel sizes and selection

```julia
    subplot(grid=(2,2), panels_size=8, region=(0, 100, 0, 80), margins="5p", autolabel=true, col_axes=(bott=true,), row_axes=(left=true,), axes="wstr", name="panels.pdf")
        subplot(:set)
        basemap(region=(0,80,0,50))
        subplot(:set)
        plot([50 40], marker=:circle, mc=:red)
        subplot(:set)
        plot([50 40], marker=:square, mc=:green)
        subplot(:set, panel=(2,2))
        plot([50 40], marker=:star, mc=:blue)
    subplot(:show)
```

Restriction
-----------

Currently, nesting of subplots is not implemented. With the ``geog`` projection one cannot set the fist axes to ``geog`` and the other to *whatever* because only last dimension is assigned that label. The solution to fine control here is to use the GMT syntax given as a string