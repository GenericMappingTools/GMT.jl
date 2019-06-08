const GMTdoc = "http://docs.generic-mapping-tools.org/latest/"

const opt_C = "**C** : **color** : **cmap** : -- Str --		``Flags = [cpt |master[+izinc] |color1,color2[,*color3*,…]]``

    Give a CPT name or specify -Ccolor1,color2[,color3,...] to build a linear continuous CPT from those
    colors automatically.
    [`-C`](http://docs.generic-mapping-tools.org/latest/grdimage.html#c)"

const opt_J = "**J** : **proj** : -- ::String --

    Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.
    [`-J`](http://docs.generic-mapping-tools.org/latest/gmt.html#j-full)"

const opt_Jz = "**Jz** : **z_axis** : -- ::String --

    Set z-axis scaling. 
    [`-Jz`](http://docs.generic-mapping-tools.org/latest/gmt.html#jz-full)"

const opt_R = "**R** : **region** : **limits** : -- Str or list or GMTgrid|image --		``Flags = xmin/xmax/ymin/ymax[+r][+uunit]``

    Specify the region of interest. Set to data minimum BoundinBox if not provided.
    [`-R`](http://docs.generic-mapping-tools.org/latest/gmt.html#r-full)"

const opt_B = "**B** : **axis** : -- Str -- 

    Set map boundary frame and axes attributes.
    [`-B`](http://docs.generic-mapping-tools.org/latest/gmt.html#b-full)"

const opt_P = "**P** : **portrait** : --- Bool or [] --

    Tell GMT to **NOT** draw in portriat mode (that is, make a Landscape plot)"

const opt_U = "**U** : **stamp** : -- Str or Bool or [] --	`Flags = [[just]/dx/dy/][c|label]`

    Draw GMT time stamp logo on plot.
    [`-U`](http://docs.generic-mapping-tools.org/latest/gmt.html#u-full)"

const opt_V = "**V** : **verbose** : -- Bool or Str --		``Flags = [level]``

    Select verbosity level, which will send progress reports to stderr.
    [`-V`](http://docs.generic-mapping-tools.org/latest/gmt.html#v-full)"

const opt_X = "**X** : **x_offset** : -- Str --     ``Flags = [a|c|f|r][x-shift[u]]``" 

const opt_Y = "**Y** : **y_offset** : -- Str --     ``Flags = [a|c|f|r][y-shift[u]]``

    Shift plot origin relative to the current origin by (x-shift,y-shift) and optionally
    append the length unit (c, i, or p). 
    [`-Y`](http://docs.generic-mapping-tools.org/latest/gmt.html#xy-full)"

const opt_a = "**a** : **aspatial** : -- Str --			``Flags = [col=]name[…]``

    Control how aspatial data are handled in GMT during input and output.
    [`-a`](http://docs.generic-mapping-tools.org/latest/gmt.html#aspatial-full)"

const opt_b = "**b** : **binary** : -- Str --

    [`-b`](http://docs.generic-mapping-tools.org/latest/gmt.html#b-full)"

const opt_bi = "**bi** : **binary_in** : -- Str --			``Flags = [ncols][type][w][+L|+B]``

    Select native binary format for primary input (secondary inputs are always ASCII).
    [`-bi`](http://docs.generic-mapping-tools.org/latest/gmt.html#bi-full)"

const opt_bo = "**bo** : **binary_out** : -- Str --			``Flags = [ncols][type][w][+L|+B]``

    Select native binary output.
    [`-bo`](http://docs.generic-mapping-tools.org/latest/gmt.html#bo-full)"

const opt_c = "**c** : **nodata** : -- Str --				``Flags = row,col``

    Used to advance to the selected subplot panel. Only allowed when in subplot mode.
    [`-c`](http://docs.generic-mapping-tools.org/latest/gmt.html#c-full)"

const opt_d = "**d** : **nodata** : -- Str or Number --		``Flags = [i|o]nodata``

    Control how user-coded missing data values are translated to official NaN values in GMT.
    [`-d`](http://docs.generic-mapping-tools.org/latest/gmt.html#d-full)"

const opt_di = "**di** : **nodata_in** : -- Str or Number --      ``Flags = nodata``

    Examine all input columns and if any item equals nodata we interpret this value as a
    missing data item and substitute the value NaN.
    [`-di`](http://docs.generic-mapping-tools.org/latest/gmt.html#di-full)"

const opt_do = "**do** : **nodata_out** : -- Str or Number --     ``Flags = nodata``

    Examine all output columns and if any item equals NAN substitute it with
    the chosen missing data value.
    [`-do`](http://docs.generic-mapping-tools.org/latest/gmt.html#do-full)"

const opt_e = "**e** : **pattern** : -- Str --        ``Flags = [~]”pattern” | -e[~]/regexp/[i]``

    Only accept ASCII data records that contains the specified pattern.
    [`-e`](http://docs.generic-mapping-tools.org/latest/gmt.html#e-full)"

const opt_f = "**f** : **colinfo** : -- Str --        ``Flags = [i|o]colinfo``

    Specify the data types of input and/or output columns (time or geographical data).
    [`-f`](http://docs.generic-mapping-tools.org/latest/gmt.html#f-full)"

const opt_g = "**g** : **gaps** : -- Str --           ``Flags = [a]x|y|d|X|Y|D|[col]z[+|-]gap[u]``

    Examine the spacing between consecutive data points in order to impose breaks in the line.
    [`-g`](http://docs.generic-mapping-tools.org/latest/gmt.html#g-full)"

const opt_h = "**h** : **header** : -- Str --        ``Flags = [i|o][n][+c][+d][+rremark][+ttitle]``

    Primary input file(s) has header record(s).
    [`-h`](http://docs.generic-mapping-tools.org/latest/gmt.html#h-full)"

const opt_i = "**i** : **incol** : -- Str --      ``Flags = cols[+l][+sscale][+ooffset][,…]``

    Select specific data columns for primary input, in arbitrary order.
    [`-i`](http://docs.generic-mapping-tools.org/latest/gmt.html#icols-full)"

const opt_j = "**j** : **cart_dist** : -- Str --     ``Flags = e|f|g``

    Determine how spherical distances are calculated in modules that support this.
    [`-j`](http://docs.generic-mapping-tools.org/latest/gmt.html#j-full)"

const opt_n = "**n** : **interp** : **interpol** : -- Str --         ``Flags = [b|c|l|n][+a][+bBC][+c][+tthreshold]``

    Select grid interpolation mode by adding b for B-spline smoothing, c for bicubic interpolation,
    l for bilinear interpolation, or n for nearest-neighbor value.
    [`-n`](http://docs.generic-mapping-tools.org/latest/gmt.html#n-full)"

const opt_o = "**o** : **outcol** : -- Str --     ``Flags = cols[,…]``

    Select specific data columns for primary output, in arbitrary order.
    [`-o`](http://docs.generic-mapping-tools.org/latest/gmt.html#ocols-full)"

const opt_p = "**p** : **view** : **perspective** : -- Str or List --   `Flags = [x|y|z]azim[/elev[/zlevel]][+wlon0/lat0[/z0]][+vx0/y0]`

    Selects perspective view and sets the azimuth and elevation of the viewpoint [180/90].
    [`-p`](http://docs.generic-mapping-tools.org/latest/gmt.html#perspective-full)"

const opt_r = "**r** : **reg** : **registration** : -- Bool or [] --

    Force pixel node registration [Default is gridline registration].
    [`-r`](http://docs.generic-mapping-tools.org/latest/gmt.html#r-full)"

const opt_s = "**s** : **skip_NaN** : -- Str --       ``Flags = [cols][a|r]``

    Suppress output for records whose z-value equals NaN.
    [`-s`](http://docs.generic-mapping-tools.org/latest/gmt.html#s-full)"

const opt_t = "**t** : **alpha** : **transparency** : -- Str --   ``Flags = transp``

    Set PDF transparency level for an overlay, in (0-100] percent range. [Default is 0, i.e., opaque].
    [`-t`](http://docs.generic-mapping-tools.org/latest/gmt.html#t-full)"

const opt_x = "**x** : **cores** : **n_threads** : -- Str or Number --  ``Flags = [[-]n]``

    Limit the number of cores to be used in any OpenMP-enabled multi-threaded algorithms.
    [`-x`](http://docs.generic-mapping-tools.org/latest/gmt.html#x-full)"

const opt_swap_xy = "**yx** : Str or Bool or [] --     ``Flags = [i|o]``

    Swap 1st and 2nd column on input and/or output.
    [`-:`](http://docs.generic-mapping-tools.org/latest/gmt.html#colon-full)"

const opt_write = "**write** : **|>** : Str --     ``Flags = fname``

    Save result to ASCII file instead of returning to a Julia variable. Give file name as argument.
    Use the bo option to save as a binary file."

const opt_append = "**append** : Str --     ``Flags = fname``

    Append result to an existing file named ``fname`` instead of returning to a Julia variable.
    Use the bo option to save as a binary file."
