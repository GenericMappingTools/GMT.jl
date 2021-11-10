# blockmode

blockmode(cmd0::String="", arg1=nothing; kwargs...)

Description
-----------

Block average (x,y,z) data tables by mode estimation.

Reads arbitrarily located (x,y,z) triples [or optionally weighted quadruples (x,y,z,w)] and computes
a mode position and value for every non-empty block in a grid region defined by the **region** and **increment** parameters.

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

- **A** or **field** or **fields**: -- *field=mode|scale|highest|lowest|weights*\
    Output is a grid with one of the select fields. `field=mode` writes the modal data *z*. Other options are:
    *scale* (the L1 scale of the mode), *lowest* (lowest value), *highest* (highest value) and *weights* (the output weight;
    requires the **weights** option). The deafault is `field=mode`. Alternatively, one can use a condensed
    form which uses the first character (except the mean) of the above options, separated by commas, to compute more than one grid.
    For example: `fields="z,h"` computes two grids; one with the modes and the other with the highest values in blocks.

- **C** or **center** : -- *center=true*\
    Use the center of the block as the output location [Default uses the modal xy location (but see **quick**)].
    **center** overrides **quick**.

- **D** or **histogram_binning** : -- *histogram_binning=true* **|** *histogram_binning=[width][+c][+a|+l|+h]*\
    Perform unweighted mode calculation via histogram binning, using the specified histogram `width`. Append **+c**
    to center bins so that their mid point is a multiple of width [uncentered]. If multiple modes are found for a block
    we return the average mode [**+a**]. Append **+l** or **+h** to return the low of high mode instead, respectively. If width
    is not given it will default to 1 provided your data set only contains integers. Also, for integer data and integer
    bin width we enforce bin centering (**+c**) and select the lowest mode (**+l**) if there are multiples.
    Default mode is normally the Least Median of Squares (LMS) statistic.

- **E** or **extend** : --- *extend=true* **|** *extend="r|s[+l|+h]"*\
    Provide Extended report which includes **s** (the L1 scale of the mode),
    **l**, the lowest value, and **h**, the high value for each block. Output order becomes *x,y,z,s,l,h*[,*w*]. Default outputs
    *x,y,z*[ ,*w*]. See **weights** for enabling *w* output.

    If `extend="r|s[+l|+h]"` is used then provide source id **s** or record number **r** output, i.e., append the
    source id or record number associated with the median value. If tied then report the record number of the higher
    of the two values (i.e., **+h** is the default); append **+l** to instead report the record number of the lower value.

    Note that **extend** may be repeated so that both `extend=true` and `extend="r[+l|+h]"` can be specified.
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

To find 5 by 5 minute block mode values from the ASCII data in ship_15.txt, run

```julia
    D = blockmode("@ship_15.txt", region=(245,255,20,30), inc="5m");
```

To determine the most frequently occurring values per 2x2 block using histogram binning, with data representing integer counts, try:

```julia
    D = blockmode("@ship_15.txt", region=:global, inc="5m", center=true, histogram_binning=true);
```

To determine the mode and L1 scale (MAD) on the mode per 10 minute bin and save these to two separate grids called
field_z.nc and field_s.nc, run:

```julia
    blockmode("@ship_15.txt", spacing="10m", region=(-115,-105,20,30), extend=true, save="field_%s.nc", fields="z,s")
```

See Also
--------

The [`GMT man page`](http://docs.generic-mapping-tools.org/latest/blockmean.html)
[blockmean](@ref)
[blockmedian](@ref)