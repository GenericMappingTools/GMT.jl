# grdview

    grdview(cmd0::String=""; kwargs...)

Create 3-D perspective image or surface mesh from a grid

Description
-----------

Reads a 2-D grid and produces a a 3-D perspective plot by drawing a mesh, painting a colored/grayshaded
surface made up of polygons, or by scanline conversion of these polygons to a raster image. Options
include draping a data set on top of a surface, plotting of contours on top of the surface, and apply
artificial illumination based on intensities provided in a separate grid.

The **region** option can be used to select a map region larger or smaller than that implied by the extent of the grid. 

Required Arguments
------------------

- **J** or *proj* : *proj=<parameters>*\
   Select map projection. More at [proj](@ref)

- **Jz** or **JZ** or *zscale* or *zsize* : *zscale=scale* **|** *zsize=size*\
   Set z-axis scaling or or z-axis size. ``zsize=size`` sets the size to the fixed value *size*
   (for example *zsize=10* or *zsize=4i*). ``zscale=scale`` sets the vertical scale to UNIT/z-unit.

Optional Arguments
------------------

- **B** or *axis* or *frame*\
   Set map boundary frame and axes attributes. More at [axis](@ref)

- **C** or *color* or *cmap* : *color=cpt*\
   Where *cpt* is a *GMTcpt* type or a cpt file name. Alternatively, supply the name of a GMT color master
   dynamic CPT [jet] to automatically determine a continuous CPT from the grid's z-range; you may round
   up/down the z-range by adding **+i** *zinc*. Yet another option is to specify ``color="color1,color2[,color3 ,...]"`` or ``color=((r1,g1,b1),(r2,g2,b2),...)`` to build a linear continuous CPT from those colors automatically (see [Setting color](@ref)). When not explicitly set, but a color map is needed, we will either use the current color map, if available (set by a previous call to *makecpt*), or the default *jet* color map. Must be present if you want (1) mesh plot with contours (``surftype=(mesh=true,)``), or (2) shaded/colored perspective image (``surftype=(surface=true,)`` or ``surftype=(img=true,)``). For ``surftype=(surface=true,)`` you can specify that you want to skip a z-slice by setting the red r/g/b component to **-**.

- **G** or *drape* : *drape=grid* **|** *drape=(grid\_r, grid\_g, grid\_b)*\
   Drape the image in drapegrid on top of the relief provided by reliefgrid. [Default determines colors from
   reliefgrid]. Note that **zsize** and **plane** always refers to the reliefgrid. The drapegrid only provides
   the information pertaining to colors, which (if drapegrid is a grid) will be looked-up via the CPT (see
   **color**). Instead, you may give three grid files via separate **drape** options in the specified order.
   These files must contain the red, green, and blue colors directly (in 0-255 range) and no CPT is needed.
   The drapegrid may be of a different resolution than the reliefgrid. Finally, drapegrid may be an image to
   be draped over the surface, in which case the **color** option is not required.

- **I** or *shade* or *intensity* : *shade=grid* **|** *shade=azim* **|** *shade=(azimuth=az, norm=params, auto=true)*\
   Gives the name of a grid with intensities in the (-1,+1) range, or a constant intensity to apply everywhere
   (affects the ambient light). Alternatively, derive an intensity grid from the input data grid *grd\_z* via a
   call to `grdgradient`; use ``shade=(azimuth=az,)`` or ``shade=(azimuth=az, norm=params)`` to specify azimuth
   and intensity arguments for that module or just give ``shade=(auto=true,)`` to select the default arguments
   (``azim=-45,norm=:t1``). If you want a more specific intensity scenario then run grdgradient separately first.

- **N** or *plane* : *plane=lev* **|** *plane=(lev, fill)*\
    Draws a plane at this z-level. If the optional color is provided via ``plane=(lev, fill)``, and the
    projection is not oblique, the frontal facade between the plane and the data perimeter is colored.
    See -Wf for setting the pen used for the outline.

- **Q** or *surf* or *surftype* : *surftype=(mesh=true, waterfall=true, surface=true, image=true, nan\_alpha=true, monochrome=true)*\
    Select one of following settings. For any of these choices, you may force a monochrome image by setting
    ``monochrome=true``. Colors are then converted to shades of gray using the (monochrome television) YIQ
    transformation. Note: pay attention to always use a tuple, even when only one option is used. This is
    correct: *surf=(img=true,)* but this is wrong: *surf=(img=true)*

> - Specify ``mesh=true`` for mesh plot [Default], and optionally set a color (see [Setting color](@ref)), with ``mesh=color``, for a different mesh paint.

> - Specify ``waterfall=true`` or my for waterfall plots (row or column profiles). Specify color as for plain *mesh*.

> - Specify ``surface=true`` for surface plot, and optionally add *mesh=true* to have mesh lines drawn on top of surface.

> - Specify ``image=true`` for image plot. Optionally use ``image=dpi`` to set the effective dpi resolution for the rasterization [100].

> - Specify ``nan\_alpha=true`` to do similar the aame as ``image=true`` but will make nodes with z = NaN transparent, using the colormasking feature in PostScript Level 3.

- **R** or *region* or *limits* : *limits=(xmin, xmax, ymin, ymax)* **|** *limits=(BB=(xmin, xmax, ymin, ymax),)*
   **|** *limits=(LLUR=(xmin, xmax, ymin, ymax),units="unit")* **|** ...more\
   Specify the region of interest. More at [limits](@ref). For perspective view **view**, optionally add
   *zmin,zmax*. This option may be used to indicate the range used for the 3-D axes [Default is region given
   by the reliefgrid]. You may ask for a larger w/e/s/n region to have more room between the image and the axes.
   A smaller region than specified in the reliefgrid will result in a subset of the grid.

- **S** or *smooth* : *smooth=smoothfactor*\
   Used to resample the contour lines at roughly every (*gridbox\_size/smoothfactor*) interval.

- **T** or *no\_interp* : *no\_interp=(skip=true, outlines=true)*\
   Plot image without any interpolation. This involves converting each node-centered bin into a polygon
   which is then painted separately. Use ``skip=true`` to skip nodes with z = NaN. This option is useful
   for categorical data where interpolating between values is meaningless. Optionally, add ``outlines=true``
   to draw the tile outlines. If the default pen is not to your liking, use ``outlines=pen``
   (see [Pen attributes](@ref)). As this option produces a flat surface it cannot be combined with -JZ or -Jz.

- **U** or *stamp* : *stamp=true* **|** *stamp=(just="code", pos=(dx,dy), label="label", com=true)*\
   Draw GMT time stamp logo on plot. More at [stamp](@ref)

- **V** or *verbose* : *verbose=true* **|** *verbose=level*\
   Select verbosity level. More at [verbose](@ref)

- **W** or *pens*\
> - **pens=(contour=true,)**\
>>   Draw contour lines on top of surface or mesh (not image). Use ``pens=(contour=true, pen)`` to set pen
>>   attributes used for the contours. [Default: width = 0.75p, color = black, style = solid].

> - **pens=(mesh=true, pen)**\
>>   Sets the pen attributes used for the mesh. [Default: width = 0.25p, color = black, style = solid]. You must also select ``surftype=(mesh=true,)`` or ``surftype=(surface=true, mesh=true)`` for meshlines to be drawn.

> - **pens=(facade=true, pen)**\
>>   Sets the pen attributes used for the facade. [Default: width = 0.25p, color = black, style = solid]. You must also select **plane** for the facade outline to be drawn.

- **X** or *x\_off* or *x\_offset* : *x\_off=[] **|** *x\_off=x-shift* **|** *x\_off=(shift=x-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [x_off](@ref)

- **Y** or *y\_off* or *y\_offset* : *y\_off=[] **|** *y\_off=y-shift* **|** *y\_off=(shift=y-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [y_off](@ref)

- **n** or *interp* or *interpol* : *interp=params*\
   Select interpolation mode for grids. More at [interp](@ref)

- **p** or *view* or *perspective* : *view=(azim, elev)*\
   Selects perspective view and sets the azimuth and elevation of the viewpoint. More at [perspective](@ref)

- **t** or *transparency* or *alpha*: *alpha=50*\
   Set PDF transparency level for an overlay, in (0-100] percent range. [Default is 0, *i.e.*, opaque].
   Works only for the PDF and PNG formats.

Examples
--------

See the Example 04 at the Historical Collection gallery.