const opt_C = "**C** : **color** : **cmap** : -- Str --
    Name of the CPT (for grd_z only). Alternatively, supply the name of a GMT color
    master dynamic CPT.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/grdimage.html#c)"

const opt_J = "**J** : **proj** : **projection** : -- Str --  
    Select map projection. Defaults to 12x8 cm with linear (non-projected) maps.
    [`-J`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#j-full)"

const opt_Jz = "**Jz** : **z_axis** : -- Str --
    Set z-axis scaling. 
    [`-Jz`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#jz-full)"

const opt_R = "**R** : **region** : **limits** : -- Str or list --
    Specify the region of interest. Set to data minimum BoundinBox if not provided.
    [`-R`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#r-full)"

const opt_B = "**B** : **frame** : **axes** : -- Str --  '[p|s]parameters'
    Set map boundary frame and axes attributes.
    [`-B`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#b-full)"

const opt_P = "**P** : **portrait** : --- Bool or [] --
    Tell GMT to **NOT** draw in portriat mode (that is, make a Landscape plot)"

const opt_U = "**U** : **stamp** : -- Str or Bool or [] --
    Draw GMT time stamp logo on plot.
    [`-U`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#u-full)"

const opt_V = "**V** : **verbose** : -- Bool or Str --
    Select verbosity level 
    [`-V`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#v-full)"

const opt_X = "**X** : **x_offset** : -- Str --"

const opt_Y = "**Y** : **y_offset** : -- Str --
    Shift plot origin. 
    [`-Y`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#xy-full)"

const opt_a = "**a** : **aspatial** : -- Str --
      [`-a`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#aspatial-full)"

const opt_bi = "**bi** : **binary_in** : -- Str --
      [`-bi`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#bi-full)"

const opt_bo = "**bo** : **binary_out** : -- Str --
      [`-bo`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#bo-full)"

const opt_di = "**di** : **nodata_in** : -- Str --
      [`-di`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#di-full)"

const opt_do = "**do** : **nodata_out** : -- Number --
      Examine all output columns and if any item equals NAN substitute it with
      the chosen missing data value
      [`-do`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#do-full)"

const opt_e = "**e** : **patern** : -- Str --
      [`-e`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#e-full)"

const opt_f = "**f** : **colinfo** : -- Str --
      [`-f`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#f-full)"

const opt_g = "**g** : **gaps** : -- Str --
      [`-g`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#g-full)"

const opt_h = "**h** : **headers** : -- Str --
      [`-h`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#h-full)"

const opt_i = "**i** : **input_col** : -- Str --
      [`-i`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#icols-full)"

const opt_n = "**n** : **interp** : -- Str --
      [`-n`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#n-full)"

const opt_p = "**p** : **view** : **perspective** : -- Str --
      [`-p`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#perspective-full)"

const opt_r = "**r** : **reg** : **registration** : -- Str --
      [`-r`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#r-full)"

const opt_t = "**t** : **alpha** : **transparency** : -- Str --
      [`-t`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#t-full)"

const opt_swappxy = "**swappxy** : Str --
      [`-:`](http://gmt.soest.hawaii.edu/doc/latest/gmt.html#colon-full)"
