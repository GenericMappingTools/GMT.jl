# arrows

	arrows(cmd0::String="", arg1=nothing; kwargs...)

Reads (x,y,a,b) data and make arrow plots. The input can either be a file name of a file with at least
four columns, but optionally more, or an Mx2 Array or GMTdatset object with the same characteristics in
terms of columns number.

This module is a subset of `plot` to make it simpler to draw arrow plots. So not all (fine)
controlling parameters are listed here. For the finest control, user should consult the [plot](@ref) module.

Parameters
----------

- **B** or **axes** or **frame**\
  Set map boundary frame and axes attributes. Default is to draw and annotate left and bottom axes.
  More at [frame](@ref)

- **J** or **proj** : *proj=<parameters>*\
  Select map projection. Default is linear and 14 cm width. More at [proj](@ref)

- **R** or **region** or **limits** : -- *limits=(xmin, xmax, ymin, ymax)* **|** *limits=(BB=(xmin, xmax, ymin, ymax),)*
   **|** *limits=(LLUR=(xmin, xmax, ymin, ymax),units="unit")* **|** ...more \
   Specify the region of interest. Default limits are computed from data extents. More at [limits](@ref)

- **G** or **markerfacecolor** or **MarkerFaceColor** or **mc** or **fill**\
   Select color or pattern for filling of vector heads [Default is no fill]. See [Setting color](@ref)
   for extend color selection (including colormap generation).

- **W** or **pen**=`pen`\
   Set pen attributes for the arrow stem [Defaults: width = default, color = black,
   style = solid]. See [Pen attributes](@ref)

- **arrow**\
   Direction (in degrees counter-clockwise from horizontal) and length must be found in columns 3 and 4,
   and size, if not specified on the command-line, should be present in column 5. The size is the length of
   the vector head. Vector stem width is set by *pen*. By default, a vector head of 0.5 cm is set but see
   [Vector Attributes](@ref) for overwriting this default and specifying other attributes.

- **U** or **time_stamp** : -- *time_stamp=true* **|** *time_stamp=(just="code", pos=(dx,dy), label="label", com=true)*\

- **V** or **verbose** : -- *verbose=true* **|** *verbose=level*\
   Select verbosity level. More at [verbose](@ref)

- **X** or **xshift** or **x_offset** : *xshift=[] **|** *xshift=x-shift* **|** *xshift=(shift=x-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [xshift](@ref)

- **Y** or **yshift** or **y_offset** : *yshift=[] **|** *yshift=y-shift* **|** *yshift=(shift=y-shift, mov="a|c|f|r")*\
   Shift plot origin. More at [yshift](@ref)

- **figname** or **savefig** or **name** :: *figname=`name.png`*\
   Save the figure with the `figname=name.ext` where `ext` chooses the figure format

Examples
--------

Plot a single arrow with head and tail.

```julia
    arrows([0 8.2 0 6], limits=(-1,4,7,9), arrow=(len=2,start=:arrow,stop=:tail,shape=0.5),
           figsize=(12,4), axes=:a, pen="4p", show=true)
```

Let us see the effect of the scale factor in quiver plots (components given in *u,v*). Plot a single vector
with length 0f ~7 cm (sqrt(50)). Notice that map limits and map size are equal to 5.

```julia
   arrows([0.0 0 5 5], limits=(0,5,0,5), figsize=5, frame=(annot=:a, grid=1),
          arrow=(len=0.5,stop=1,uv=1), show=true)
```

now, we increase the fig size to 10 cm and because the vector magnitude is half ot it (= 7) we see that the
vector is now plot from 0 to ~3.54 figure units. In fact, the vector has exactly the same size as in previous
example but the figure is now twice as large.

```julia
   arrows([0.0 0 5 5], limits=(0,5,0,5), figsize=10, frame=(annot=1, ticks=0.5, grid=1),
          arrow=(len=0.5,stop=1,uv=1), show=true)
```

and finally we will change the vector size again but this time by applying a factor scale of 0.5. The vector
is now ~1.77 figure units long.

```julia
   arrows([0.0 0 5 5], limits=(0,5,0,5), figsize=10, frame=(annot=0.5, ticks=0.25, grid=0.5),
          arrow=(len=0.5,stop=1,uv=0.5), show=true)
```

See Also
--------

[plot](@ref), [lines](@ref), [scatter](@ref)