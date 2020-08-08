# contourf

    contourf(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

Create filled contour mapps.

Description
-----------

This module is a wrapper to *grdview*, *contour* and *grdcontour* and as such it works with two different kinds of input data. If input is a grid (either a grid file name or a GMTgrid object) it will make a filled contour with *grdview* and optionally  overlay contours by calling *grdcontour*. If, on the other hand, the input data is table data file or a Mx3 array (or GMTdataset), it first compute a Delaunay triangulation and makes the plot from it. In this later case, the job is done by *contour* module alone.

The **region** option can be used to select a map region larger or smaller than that implied by the extent of the grid. 

Required Arguments
------------------

The input data set to be filled/contoured. It can be 2-D gridded data GMTgrid) or a Mx3 table (or GNTdataset). In these cases
the data type detection is automatic. Alterativelly, one can provide the file name. In that case, if the data has
known extensions (*.grd* or *.nc* among others for grids or *.dat*, *.bin* (need to use **iput_type**) for tables) the
type detection is also automatic. And, for grids, passing a file name is actually the most efficient way os using thsi module.
Still, if data type is not automatically detected, we can help the module by passing the **grid=true** or **data=true**
options.

Not exactly required but convinient, the second input argument can be a GMTcpt object. The advantage of this is that it
releases the **contour** option to pass only options that control what contours to plot.

Optional Arguments
------------------

- **A** or **annot** : -- *annot=annot\_int* **|** *annot=(int=annot\_int, disable=true, single=true, labels=labelinfo)*\
   *annot\_int* is annotation interval in data units; it is ignored if contour levels are given in a file.
   [Default is no annotations]. Use *annot=(disable=true,)* to disable all annotations implied by **cont**.
   Alternatively do *annot=(single=true, int=val)* to plot *val* as a single contour. The optional *labelinfo* controls the specifics of the label formatting and consists of a named tuple with the following control arguments [`Label formatting`](@ref label_format_quot)

- **B** or **axis** or **frame**\
   Set map boundary frame and axes attributes. More at [axis](@ref)

- **C** or **cont** or **contour** or **contours** or **levels** : -- *cont=cont\_int*\
   The contours to be drawn may be specified in one of two possible ways:

   1. If ``cont_int`` is a *GMTcpt* object (or a string and has the suffix ".cpt" and can be opened as a file).
      The color boundaries are then used as contour levels. If the CPT has annotation flags in the
      last column then those contours will be annotated. By default all contours are labeled;
      use *annot=(disable=true,))* (or *annot=:none*) to disable all annotations.

   2. If ``cont_int`` is a constant or an array it means plot those contour intervals. This works also to draw
      single contours. *E.g.* **contour=[0]** will draw only the zero contour. The **annot** option offers the same
	  possibility so they may be used together to plot a single annotated contour and another single non-annotated contour,
	  as in **anot=[10], cont=[5]** that plots an annotated 10 contour and an non-annotated 5 contour. If **annot** is set
	  and **cont** is not, then the contour interval is set equal to the specified annotation interval.

	If no **contour** option and no *GMTcpt* are passed then for grid a default color map is computed and all of
	those automatically contours are drwan. Also, no *GMTcpt* and **contour=[array]** computes a cmap with only the
	contour values specified in *array*. When passing a *Mx3* array or a *GMTdataset* the default behavior is
	basically the same.

- **E** or **index** : -- *index=tri_network*\
   Give a Mx3 array or name of file with network information. Each record must contain triplets of node numbers for
   a triangle [Default computes these using Delaunay triangulation (see triangulate)].

- **G** or **labels** : -- *labels=()*\
   The required argument controls the placement of labels along the quoted lines. Choose among five
   controlling algorithms as explained in [`Placement methods`](@ref placement_method_quot)

- **J** or **proj** : -- *proj=<parameters>*\
   Select map projection. More at [proj](@ref)

- **Q** or **cut** : -- *cut=np* **|** *cut=length&unit[+z]*\
   Do not draw contours with less than *np* number of points [Draw all contours]. Alternatively, give
   instead a minimum contour length in distance units, including **c** (Cartesian distances using user
   coordinates) or **C** for plot length units in current plot units after projecting the coordinates.
   Optionally, append **+z** to exclude the zero contour.

- **R** or **region** or **limits** : -- *limits=(xmin, xmax, ymin, ymax)* **|** *limits=(BB=(xmin, xmax, ymin, ymax),)*
   **|** *limits=(LLUR=(xmin, xmax, ymin, ymax),units="unit")* **|** ...more\
   Specify the region of interest. More at [limits](@ref). For perspective view **view**, optionally add
   *zmin,zmax*. This option may be used to indicate the range used for the 3-D axes [Default is region given
   by the reliefgrid]. You may ask for a larger w/e/s/n region to have more room between the image and the axes.
   A smaller region than specified in the reliefgrid will result in a subset of the grid.

- **S** or **smooth** : -- *smooth=smoothfactor*\
   Resample the contour lines at roughly every (*gridbox\_size/smoothfactor*) interval.
   *This option should be used only when input data is a table*.

- **S** or **skip** : -- *skip=true|"t"*\
   Skip all input xyz points that fall outside the region [Default uses all the data in the triangulation].
   Alternatively, use **skip="t"* to skip triangles whose three vertices are all outside the region.
   *This option should be used only when input data is a grid*.

- **T** or *ticks* : -- *ticks=(local\_high=true, local\_low=true, gap=gap, closed=true, labels=labels)*\
   Will draw tick marks pointing in the downward direction every *gap* along the innermost closed contours only;
   set *closed=true* to tick all closed contours. Use *gap=(gap,length)* and optionally tick mark *length*
   (append units as **c**, **i**, or **p**) or use defaults [*"15p/3p"*]. User may choose to tick only local
   highs or local lows by specifying *local\_high=true*, *local\_low=true*, respectively. Set *labels* to
   annotate the centers of closed innermost contours (i.e., the local lows and highs). If no *labels* (*i.e*,
   set *labels=""*) is set, we use - and + as the labels. Appending exactly two characters, *e.g.*, *labels=:LH*,
   will plot the two characters (here, *L* and *H*) as labels. For more elaborate labels, separate the low and hight
   label strings with a comma (*e.g.*, *labels="lo,hi"*). If a file is given by **cont**, and **ticks** is set,
   then only contours marked with upper case C or A will have tick marks [and annotations].

- **U** or **stamp** : -- *stamp=true* **|** *stamp=(just="code", pos=(dx,dy), label="label", com=true)*\
   Draw GMT time stamp logo on plot. More at [stamp](@ref)

- **V** or **verbose** : -- *verbose=true* **|** *verbose=level*\
   Select verbosity level. More at [verbose](@ref)

- **W** or *pen* : -- *pen=(annot=true, contour=true, pen=pen, colored=true, cline=true, ctext=true)*\
   ``annot=true`` if present, means to annotate contours or ``contour=true`` for regular contours [Default].
   The *pen* sets the attributes for the particular line. Default pen for annotated contours: ``pen=(0.75,:black)``.
   Regular contours use ``pen=(0.25,:black)``. Normally, all contours are drawn with a fixed color determined by
   the pen setting. This option may be repeated, for example to separate contour and annotated contours settings.
   For that the syntax changes to use a Tuple of NamedTuples, *e.g.*  ``pen=((annot=true, contour=true, pen=pen), (annot=true, contour=true, pen=pen))``. If the modifier ``pen=(cline=true,)`` is used then the color of the contour lines are taken from the CPT (see **cont**). If instead ``pen=(ctext=true,)`` is appended then the color from the cpt file is applied to the contour annotations. Select ``pen=(colored=true,)`` for both effects.

- **X** or **x\_off** or **x\_offset** : -- *x\_off=[] **|** *x\_off=x-shift* **|** *x\_off=(shift=x-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [x_off](@ref)

- **Y** or **y\_off** or **y\_offset** : -- *y\_off=[] **|** *y\_off=y-shift* **|** *y\_off=(shift=y-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [y_off](@ref)

- **p** or **view** or **perspective** : -- *view=(azim, elev)*\
   Selects perspective view and sets the azimuth and elevation of the viewpoint. More at [perspective](@ref)

- **t** or **transparency** or **alpha**: -- *alpha=50*\
   Set PDF transparency level for an overlay, in (0-100] percent range. [Default is 0, *i.e.*, opaque].
   Works only for the PDF and PNG formats.

Examples
--------

Using a grid

```julia
	G = GMT.peaks();
	C = makecpt(T=(-7,9,2));

	contourf(G, fmt=:png, show=1)
	contourf(G, C=[-2, 0, 2, 5], fmt=:png, show=1)
	contourf(G, C, contour=[-2, 0, 2, 5], fmt=:png, show=1)
	contourf(G, C, annot=[-2, 0, 2, 5], fmt=:png, show=1)
	contourf(G, C, annot=2, fmt=:png, show=1)
	contourf(G, C, contour=1, annot=[-2, 0, 2, 5], fmt=:png, show=1)
	contourf(G, C, annot=:none, fmt=:png, show=1)
```

Using a table data.

```julia
	d = [0 2 5; 1 4 5; 2 0.5 5; 3 3 9; 4 4.5 5; 4.2 1.2 5; 6 3 1; 8 1 5; 9 4.5 5];
	contourf(d, limits=(-0.5,9.5,0,5), pen=0.25, labels=(line=(:min,:max),), fmt=:png, show=1)
```