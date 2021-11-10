# blockmean

blockmean(cmd0::String="", arg1=nothing; kwargs...)

Description
-----------

Block average (x,y,z) data tables by mean estimation.

Reads arbitrarily located (x,y,z) triples [or optionally weighted quadruples (x,y,z,w)] and computes
a mean position and value for every non-empty block in a grid region defined by the **region** and **increment** parameters.

Takes a Mx3 matrix, a GMTdataset, or a file name as input and returns either a table (a GMTdataset) or one or more
grids (GMTgrid). Aternatively, save the result directly in a disk file.

Required Arguments
------------------

*table*\
    3 (or 4, see **weights**) column data table file (or binary, see **binary_in**) holding (*x,y,z[,w]*)
	data values, where [ *w*] is an optional weight for the data.

- **I** or **inc** or **increment** or **spacing** : -- *inc=x_inc* **|** *inc=(x_inc, y_inc)* **|** *inc="xinc[+e|n][/yinc[+e|n]]"*
   Specify the grid increments or the block sizes. Extended at [spacing](@ref)

- **R** or *region* or *limits* : -- *limits=(xmin, xmax, ymin, ymax)* **|** *limits=(BB=(xmin, xmax, ymin, ymax),)*
   **|** *limits=(LLUR=(xmin, xmax, ymin, ymax),units="unit")* **|** ...more \
   Specify the region of interest. Default limits are computed from data extents. Extended at [limits](@ref)

Optional Arguments
------------------

- **A** or **field** or **fields**: -- *field=mean|std|highest|lowest|weights*\
    Output is a grid with one of the select fields. `field=mean` writes the mean of *z*. Other options are:
    *std* (standard deviation), *lowest* (lowest value), *highest* (highest value) and *weights* (the output weight;
    requires the **weights** option). The deafault is `field=mean`. Alternatively, one can use a condensed
    form which uses the first character (except the mean) of the above options, separated by commas, to compute more than one grid.
    For example: `fields="z,s"` computes two grids; one with the means and the other with the standard deviations.

- **C** or **center** : -- *center=true*\
    Use the center of the block as the output location [Default uses the mean location]. Not used whith **fields**.

- **E** or **extend** : --- *extend=true* **|** *extend="+p"* **|** *extend="+P"*\
    Provide Extended report which includes **s** (the standard deviation about the mean), **l**, the lowest value,
    and **h**, the high value for each block. Output order becomes *x,y,z,s,l,h*[,*w*]. Default outputs
    *x,y,z*[ ,*w*]. See **weights** for enabling *w* output.
    If `extend="+p"` or  `extend="+P"` is used then input data uncertainties are expected and *s*
    becomes the propagated error of the weighted (**+p**) or simple (**+P**) *z* mean.

- **G** or **save** or **outgrid** or **outfile** : -- *save=file_name.grd*\
    Write one or more fields directly to grids on disk; no data is returned to the Julia REPL.
    If more than one fields are specified via **fields** then *file_name* must contain the format flag
    %s so that we can embed the field code in the file names.

- **S** or **statistic** : -- *statistic=:m|:n|:s|:w*\
    Use `statistic=:m` to report the mean value in each blaock, `statistic=:n` to report the number of points
    inside each block, `statistic=:s` to report the sum of all z-values inside a block, `statistic=:w` to report
    the sum of weights [Default (or `statistic=:m` reports mean value]. This option works both for returning the result
    in a table in a GMTdataset or in a grid. For this later case, however, one must use the **grid=true** option.

- **V** or *verbose* : -- *verbose=true* **|** *verbose=level*\
   Select verbosity level. More at [verbose](@ref)

- **W** or **weights** : -- *weights=:i* **|** *weights=:o* **|** *weights="i+s"* **|** *weights="i|o+s|+w"*\
    Weighted modifier[s]. Unweighted input and output have 3 columns *x,y,z*; Weighted i/o has 4 columns *x,y,z,w*.
    Weights can be used in input to construct weighted mean values for each block. Weight sums can be reported in
    output for later combining several runs, etc. Use **weights** for weighted i/o, **weights=:i** for weighted
    input only, and **weights=:o** for weighted output only. [Default uses unweighted i/o]. If your weights are
    actually uncertainties (one sigma) then append the string **+s** (as in **weights="i+s"**) and we compute
    weight = 1/sigma. Otherwise (or via **+w**) we use the weights directly.

- **bi** or **binary_in**

- **bo** or **binary_out**

- **di** or **nodata_in**

- **e** or **pattern**

- **f** or **colinfo**

- **h** or **header**

- **i** or **incol**

- **o** or **outcol**

- **q** or **inrows**

- **r** or **reg** or **registration** : -- *reg=:p* **|** *reg=:g*\
   Select gridline or pixel node registration. Used only when output is a grid.

- **w** or **wrap** or **cyclic**

- **yx** : -- *yx=true*\
   Swap 1st and 2nd column on input and/or output.


Examples
--------

To find 5 by 5 minute block mean values from the ASCII data in ship_15.txt, run

```julia
    D = blockmean("@ship_15.txt", region=(245,255,20,30), inc="5m");
```

To determine how many values were found in each 5x5 minute bin, try

```julia
    D = blockmean("@ship_15.txt", region=(245,255,20,30), inc="5m", count=true);
```

To determine the mean and standard deviation per 10 minute bin and save these to two separate grids
called field_z.nc and field_s.nc, run

```julia
    blockmean("@ship_15.txt", spacing="10m", region=(-115,-105,20,30), extend=true, save="field_%s.nc", fields="z,s")
```

The same as above but this time returns the two grids to the Julia REPL

```julia
    Z,S = blockmean("@ship_15.txt", spacing="10m", region=(-115,-105,20,30), extend=true, fields="z,s")
```

See Also
--------

The [`GMT man page`](http://docs.generic-mapping-tools.org/latest/blockmean.html)
[blockmedian](@ref)
[blockmode](@ref)