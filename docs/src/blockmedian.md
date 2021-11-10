# blockmedian

blockmedian(cmd0::String="", arg1=nothing; kwargs...)

Description
-----------

Block average (x,y,z) data tables by median estimation.

Reads arbitrarily located (x,y,z) triples [or optionally weighted quadruples (x,y,z,w)] and computes
a median position and value for every non-empty block in a grid region defined by the **region** and **increment** parameters.

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

- **A** or **field** or **fields**: -- *field=median|scale|highest|lowest|weights*\
    Output is a grid with one of the select fields. `field=median` writes the mean of *z*. Other options are:
    *scale* (the L1 scale of the median), *lowest* (lowest value), *highest* (highest value) and *weights* (the output weight;
    requires the **weights** option). The deafault is `field=median`. Alternatively, one can use a condensed
    form which uses the first character (except the mean) of the above options, separated by commas, to compute more than one grid.
    For example: `fields="z,l"` computes two grids; one with the medians and the other with the lowest value in each block.

- **C** or **center** : -- *center=true*\
    Use the center of the block as the output location [Default uses the mean location]. Not used whith **fields**.

- **E** or **extend** : --- *extend=true* **|** *extend=:b* **|** *extend="r|s[+l|+h]"*\
    Provide Extended report which includes **s** ((the L1 scale of the median, i.e., 1.4826 * median absolute deviation [MAD]),
    **l**, the lowest value, and **h**, the high value for each block. Output order becomes *x,y,z,s,l,h*[,*w*]. Default outputs
    *x,y,z*[ ,*w*]. For box-and-whisker calculation, use `extend=:b` which will output *x,y,z,l,q25,q75,h[,w]*, where 
    *q25* and *q75* are the 25% and 75% quantiles, respectively.  See **weights** for enabling *w* output.

    If `extend="r|s[+l|+h]"` is used then provide source id **s** or record number **r** output, i.e., append the
    source id or record number associated with the median value. If tied then report the record number of the higher
    of the two values (i.e., **+h** is the default); append **+l** to instead report the record number of the lower value.

    Note that **extend** may be repeated so that both `extend=true[:b]` and `extend="r[+l|+h]"` can be specified.
    But in this case (repeated **extend** option) one must encapsulate the intire option in a Tuple because
    option names can not be repeated (not yet imlemented).
    For `extend=:s` we expect input records of the form *x,y,z[,w],sid*, where *sid* is an unsigned integer source id.

- **G** or **save** or **outgrid** or **outfile** : -- *save=file_name.grd*\
    Write one or more fields directly to grids on disk; no data is returned to the Julia REPL.
    If more than one fields are specified via **fields** then *file_name* must contain the format flag
    %s so that we can embed the field code in the file names.

- **Q** or **quick** : -- *quick=true*\
    (Quicker) Finds median z and (x,y) at that the median z [Default finds median x, median y independent of z].
    Also see **center**.

- **T** or **quantile** : -- *quantile=val*\
    Sets the quantile of the distribution to be returned [Default is 0.5 which returns the median z]. Here, 0 < val < 1.

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

To find 5 by 5 minute block medians values from the ASCII data in ship_15.txt, run

```julia
    D = blockmedian("@ship_15.txt", region=(245,255,20,30), inc="5m");
```

To compute the shape of a data distribution per bin via a box-and-whisker diagram we need the 0%, 25%, 50%, 75%,
and 100% quantiles. To do so on a global 5 by 5 degree basis from the ASCII table mars370.txt do:

```julia
    D = blockmedian("@ship_15.txt", region=:global, inc="5m", extend=:b);
```

To determine the median and L1 scale (MAD) on the median per 10 minute bin and save these to two separate grids
called field_z.nc and field_s.nc, run

```julia
    blockmedian("@ship_15.txt", spacing="10m", region=(-115,-105,20,30), extend=true, save="field_%s.nc", fields="z,s")
```

The same as above but this time returns the two grids to the Julia REPL

```julia
    Z,S = blockmedian("@ship_15.txt", spacing="10m", region=(-115,-105,20,30), extend=true, fields="z,s")
```

See Also
--------

The [`GMT man page`](http://docs.generic-mapping-tools.org/latest/blockmean.html)
[blockmean](@ref)
[blockmode](@ref)