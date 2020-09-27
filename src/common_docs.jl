const GMTdoc = "http://docs.generic-mapping-tools.org/latest/"

const opt_C = "**C** | **color** | **cmap** :: [Type => Str]		``Arg = [cpt |master[+izinc] |color1,color2[,*color3*,…]]``

    Give a CPT name or specify -Ccolor1,color2[,color3,...] to build a linear continuous CPT from those
    colors automatically.
    (http://docs.generic-mapping-tools.org/latest/grdimage.html#c)"

const opt_J = "**J** | **proj** | **projection** :: [Type => String]

    Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#j-full)"

const opt_Jz = "**Jz** | **zscale** | **zsize** :: [Type => String]"
const opt_JZ = "**JZ** | **zsize** :: [Type => String]

    Set z-axis scaling. 
    (http://docs.generic-mapping-tools.org/latest/gmt.html#jz-full)"

const opt_R = "**R** | **region** | **limits** :: [Type => Str or list or GMTgrid|image]	``Arg = (xmin,xmax,ymin,ymax)``

    Specify the region of interest. Set to data minimum BoundinBox if not provided.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#r-full)"

const opt_B = "**B** | **frame** | **axis** | **xaxis yaxis**:: [Type => Str] 

    Set map boundary frame and axes attributes.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#b-full)"

const opt_P = "**P** | **portrait** :: [Type => Bool or []]

    Tell GMT to **NOT** draw in portriat mode (that is, make a Landscape plot)"

const opt_U = "**U** | **stamp** :: [Type => Str or Bool or []]	``Arg = [[just]/dx/dy/][c|label]``

    Draw GMT time stamp logo on plot.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#u-full)"

const opt_V = "**V** | **verbose** :: [Type => Bool or Str]		``Arg = [level]``

    Select verbosity level, which will send progress reports to stderr.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#v-full)"

const opt_X = "**X** | **xoff** | **x_off** | **x_offset** :: [Type => Str]     ``Arg = [a|c|f|r][x-shift[u]]``" 

const opt_Y = "**Y** | **yoff** | **y_off** | **y_offset** :: [Type => Str]     ``Arg = [a|c|f|r][y-shift[u]]``

    Shift plot origin relative to the current origin by (x-shift,y-shift) and optionally
    append the length unit (c, i, or p). 
    (http://docs.generic-mapping-tools.org/latest/gmt.html#xy-full)"

const opt_a = "**a** | **aspatial** :: [Type => Str]			``Arg = [col=]name[…]``

    Control how aspatial data are handled in GMT during input and output.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#aspatial-full)"

const opt_b = "**b** | **binary** :: [Type => Str]

    (http://docs.generic-mapping-tools.org/latest/gmt.html#b-full)"

const opt_bi = "**bi** | **binary_in** :: [Type => Str]			``Arg = [ncols][type][w][+L|+B]``

    Select native binary format for primary input (secondary inputs are always ASCII).
    (http://docs.generic-mapping-tools.org/latest/gmt.html#bi-full)"

const opt_bo = "**bo** | **binary_out** :: [Type => Str]			``Arg = [ncols][type][w][+L|+B]``

    Select native binary output.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#bo-full)"

const opt_c = "**c** | **panel** :: [Type => Tuple | Array | Number | String]	``Arg = row,col``

    Used to advance to the selected subplot panel. Only allowed when in subplot mode.
    Attention, row,col start counting at 1 (contrary to GMT, where they start at 0)
    http://docs.generic-mapping-tools.org/latest/gmt.html#c-full)"

const opt_d = "**d** | **nodata** :: [Type => Str or Number]		``Arg = [i|o]nodata``

    Control how user-coded missing data values are translated to official NaN values in GMT.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#d-full)"

const opt_di = "**di** | **nodata_in** :: [Type => Str or Number]      ``Arg = nodata``

    Examine all input columns and if any item equals nodata we interpret this value as a
    missing data item and substitute the value NaN.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#di-full)"

const opt_do = "**do** | **nodata_out** :: [Type => Str or Number]     ``Arg = nodata``

    Examine all output columns and if any item equals NAN substitute it with
    the chosen missing data value.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#do-full)"

const opt_e = "**e** | **pattern** :: [Type => Str]        ``Arg = [~]”pattern” | -e[~]/regexp/[i]``

    Only accept ASCII data records that contains the specified pattern.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#e-full)"

const opt_f = "**f** | **colinfo** :: [Type => Str]        ``Arg = [i|o]colinfo``

    Specify the data types of input and/or output columns (time or geographical data).
    (http://docs.generic-mapping-tools.org/latest/gmt.html#f-full)"

const opt_g = "**g** | **gaps** :: [Type => Str]           ``Arg = [a]x|y|d|X|Y|D|[col]z[+|-]gap[u]``

    Examine the spacing between consecutive data points in order to impose breaks in the line.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#g-full)"

const opt_h = "**h** | **header** :: [Type => Str]        ``Arg = [i|o][n][+c][+d][+rremark][+ttitle]``

    Primary input file(s) has header record(s).
    (http://docs.generic-mapping-tools.org/latest/gmt.html#h-full)"

const opt_i = "**i** | **incol** :: [Type => Str]      ``Arg = cols[+l][+sscale][+ooffset][,…]``

    Select specific data columns for primary input, in arbitrary order.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#icols-full)"

const opt_j = "**j** | **spheric_dist** | **spherical_dist** :: [Type => Str]     ``Arg = e|f|g``

    Determine how spherical distances are calculated in modules that support this.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#j-full)"

const opt_l = "**l** | **legend** :: [Type => Str]     ``Arg = [label][+dpen][+ffont][+ggap][+hheader][+jjust][+ncols][+ssize][+v[pen]][+wwidth][+xscale``

    Add a map legend entry to the session legend information file for the current plot.
    ($(GMTdoc)gmt.html#l-full)"

const opt_n = "**n** | **interp** | **interpol** :: [Type => Str]         ``Arg = [b|c|l|n][+a][+bBC][+c][+tthreshold]``

    Select grid interpolation mode by adding b for B-spline smoothing, c for bicubic interpolation,
    l for bilinear interpolation, or n for nearest-neighbor value.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#n-full)"

const opt_o = "**o** | **outcol** :: [Type => Str]     ``Arg = cols[,…]``

    Select specific data columns for primary output, in arbitrary order.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#ocols-full)"

const opt_p = "**p** | **view** | **perspective** :: [Type => Str or List]   ``Arg = [x|y|z]azim[/elev[/zlevel]][+wlon0/lat0[/z0]][+vx0/y0]``

    Selects perspective view and sets the azimuth and elevation of the viewpoint [180/90].
    (http://docs.generic-mapping-tools.org/latest/gmt.html#perspective-full)"

const opt_q = "**q** | **inrow** :: [Type => Str]       ``Arg = [i|o][~]rows[+ccol][+a|f|s]``

    Select specific data rows to be read (-qi [Default]) or written (-qo) [all]. 
    (http://docs.generic-mapping-tools.org/latest/gmt.html#q-full)"

const opt_r = "**r** | **reg** | **registration** :: [Type => Bool or []]

    Force pixel node registration [Default is gridline registration].
    (http://docs.generic-mapping-tools.org/latest/gmt.html#r-full)"

const opt_s = "**s** | **skip_NaN** :: [Type => Str]       ``Arg = [cols][a|r]``

    Suppress output for records whose z-value equals NaN.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#s-full)"

const opt_t = "**t** | **alpha** | **transparency** :: [Type => Str]   ``Arg = transp``

    Set PDF transparency level for an overlay, in (0-100] percent range. [Default is 0, i.e., opaque].
    (http://docs.generic-mapping-tools.org/latest/gmt.html#t-full)"

const opt_x = "**x** | **cores** | **n_threads** :: [Type => Str or Number]  ``Arg = [[-]n]``

    Limit the number of cores to be used in any OpenMP-enabled multi-threaded algorithms.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#x-full)"

const opt_swap_xy = "**yx** :: [Type => Str or Bool or []]     ``Arg = [i|o]``

    Swap 1st and 2nd column on input and/or output.
    (http://docs.generic-mapping-tools.org/latest/gmt.html#colon-full)"

const opt_write = "**write** | **|>** :: [Type => Str]     ``Arg = fname``

    Save result to ASCII file instead of returning to a Julia variable. Give file name as argument.
    Use the bo option to save as a binary file."

const opt_append = "**append** :: [Type => Str]     ``Arg = fname``

    Append result to an existing file named ``fname`` instead of returning to a Julia variable.
    Use the bo option to save as a binary file."
