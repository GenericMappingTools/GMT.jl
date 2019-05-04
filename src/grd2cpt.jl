"""
	grd2cpt(cmd0::String="", arg1=nothing, kwargs...)

Make linear or histogram-equalized color palette table from grid

Full option list at [`grd2cpt`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html)

Parameters
----------

- **A** : **alpha** : **transparency** : -- Str --

    Sets a constant level of transparency (0-100) for all color slices.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#a)
- $(GMT.opt_C)
- **D** : -- Str or [] --			Flags = [i|o]

    Select the back- and foreground colors to match the colors for lowest and highest
    z-values in the output CPT. 
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#d)
- **E** : **nlevels** : -- Int or [] --		Flags = [nlevels]

    Create a linear color table by using the grid z-range as the new limits in the CPT.
    Alternatively, append nlevels and we will resample the color table into nlevels equidistant slices.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#e)
- **F** : **force_rgb** : -- Str or [] --		Flags = [R|r|h|c][+c]]

    Force output CPT to written with r/g/b codes, gray-scale values or color name.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#f)
- **G** : **truncate** : -- Str --              Flags = zlo/zhi

    Truncate the incoming CPT so that the lowest and highest z-levels are to zlo and zhi.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#g)
- **I** : **inverse** : **reverse** : -- Str --	Flags = [c][z]

    Reverse the sense of color progression in the master CPT.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#i)
- **L** : **range** : -- Str --			Flags = minlimit/maxlimit

    Limit range of CPT to minlimit/maxlimit, and don’t count data outside this range when estimating CDF(Z).
    [Default uses min and max of data.]
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#l)
- **M** : **overrule_bg** -- Bool or [] --

    Overrule background, foreground, and NaN colors specified in the master CPT with the values of
    the parameters COLOR_BACKGROUND, COLOR_FOREGROUND, and COLOR_NAN.
    [`-M`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#m)
- **N** : **no_bg** : **nobg** : -- Bool or [] --

    Do not write out the background, foreground, and NaN-color fields.
- **Q** : **log** : -- Bool or [] --

    Selects a logarithmic interpolation scheme [Default is linear].
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#q)
- **C** : **row_col** : -- Bool --

    Replace the x- and y-coordinates on output with the corresponding column and row numbers.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#c)
- $(GMT.opt_R)
- **S** : **steps** : -- Bool or [] or Str --			Flags = zstart/zstop/zinc or n

    Set steps in CPT. Calculate entries in CPT from zstart to zstop in steps of (zinc). Default
    chooses arbitrary values by a crazy scheme based on equidistant values for a Gaussian CDF.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#s)
- **T** : **symetric** : -- Str --			Flags = -|+|_|=

    Force the color table to be symmetric about zero (from -R to +R).
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#t)
- $(GMT.opt_V)
- **W** : **wrap** : **categorical** : -- Bool or Str or [] --      Flags = [w]

    Do not interpolate the input color table but pick the output colors starting at the
    beginning of the color table, until colors for all intervals are assigned.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#w)
- **Z** : **continuous** : -- Bool or [] --

    Creates a continuous CPT [Default is discontinuous, i.e., constant colors for each interval].
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/grd2cpt.html#z)
- $(GMT.opt_V)
- $(GMT.opt_write)
"""
function grd2cpt(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("grd2cpt", cmd0, arg1)

	d = KW(kwargs)

	cmd = parse_common_opts(d, "", [:R :V_params])
	cmd = parse_these_opts(cmd, d, [[:A :alpha :transparency], [:D :bg :background], [:E :nlevels],
				[:G :truncate], [:F :force_rgb], [:I :inverse :reverse], [:L :limit], [:M :overrule_bg],
				[:N :no_bg :nobg], [:Q :log], [:S :steps], [:T :symetric], [:W :no_interp], [:Z :continuous]])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)
	N_used = got_fname == 0 ? 1 : 0			# To know whether a cpt will go to arg1 or arg2
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_used, arg1)
	global current_cpt = common_grd(d, "grd2cpt " * cmd, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
grd2cpt(arg1; kw...) = grd2cpt("", arg1; kw...)