"""
	grd2cpt(cmd0::String="", arg1=[], kwargs...)

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
- **N** : **no_bg** -- Bool or [] --

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
"""
function grd2cpt(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && (findfirst(" -", cmd0) != nothing) && return monolitic("grd2cpt", cmd0, arg1)	# Speedy mode

	if (isempty(cmd0) && isempty_(arg1))
		error("Must provide the grid to work with.")
	end

	d = KW(kwargs)

	cmd, opt_R = parse_R("", d)
	cmd = parse_V(cmd, d)
    cmd = parse_params(cmd, d)

	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', 0, arg1)

	cmd = add_opt(cmd, 'A', d, [:A :alpha :transparency])
	cmd = add_opt(cmd, 'D', d, [:D :bg :background])
	cmd = add_opt(cmd, 'E', d, [:E :nlevels])
	cmd = add_opt(cmd, 'F', d, [:F :force_rgb])
	cmd = add_opt(cmd, 'G', d, [:G :truncate])
	cmd = add_opt(cmd, 'I', d, [:I :inverse :reverse])
	cmd = add_opt(cmd, 'L', d, [:L :limit])
	cmd = add_opt(cmd, 'M', d, [:M :overrule_bg])
	cmd = add_opt(cmd, 'N', d, [:N :no_bg])
	cmd = add_opt(cmd, 'Q', d, [:Q :log])
	cmd = add_opt(cmd, 'S', d, [:S :steps])
	cmd = add_opt(cmd, 'T', d, [:T :symetric])
	cmd = add_opt(cmd, 'W', d, [:W :no_interp])
	cmd = add_opt(cmd, 'Z', d, [:Z :continuous])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "grd2cpt", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grd2cpt(arg1=[], cmd0::String=""; kw...) = grd2cpt(cmd0, arg1; kw...)