"""
	grd2cpt(cmd0::String="", arg1=nothing, kwargs...)

Make linear or histogram-equalized color palette table from grid

Full option list at [`grd2cpt`]($(GMTdoc)grd2cpt.html)

Parameters
----------

- **A** | **alpha** | **transparency** :: [Type => Str]

    Sets a constant level of transparency (0-100) for all color slices.
    ($(GMTdoc)grd2cpt.html#a)
- $(GMT.opt_C)
- **D** | **bg** | **background** :: [Type => Str | []]			`Arg = [i|o]`

    Select the back- and foreground colors to match the colors for lowest and highest
    z-values in the output CPT. 
    ($(GMTdoc)grd2cpt.html#d)
- **E** | **nlevels** :: [Type => Int | []]		`Arg = [nlevels]`

    Create a linear color table by using the grid z-range as the new limits in the CPT.
    Alternatively, append nlevels and we will resample the color table into nlevels equidistant slices.
    ($(GMTdoc)grd2cpt.html#e)
- **F** | **force_rgb** :: [Type => Str | []]		`Arg = [R|r|h|c][+c]]`

    Force output CPT to written with r/g/b codes, gray-scale values or color name.
    ($(GMTdoc)grd2cpt.html#f)
- **G** | **truncate** :: [Type => Str]             `Arg = zlo/zhi`

    Truncate the incoming CPT so that the lowest and highest z-levels are to zlo and zhi.
    ($(GMTdoc)grd2cpt.html#g)
- **I** | **inverse** | **reverse** :: [Type => Str]	    `Arg = [c][z]`

    Reverse the sense of color progression in the master CPT.
    ($(GMTdoc)grd2cpt.html#i)
- **L** | **range** :: [Type => Str]			`Arg = minlimit/maxlimit`

    Limit range of CPT to minlimit/maxlimit, and don’t count data outside this range when estimating CDF(Z).
    [Default uses min and max of data.]
    ($(GMTdoc)grd2cpt.html#l)
- **M** | **overrule_bg** [Type => Bool]

    Overrule background, foreground, and NaN colors specified in the master CPT with the values of
    the parameters COLOR_BACKGROUND, COLOR_FOREGROUND, and COLOR_NAN.
    ($(GMTdoc)grd2cpt.html#m)
- **N** | **no_bg** | **nobg** :: [Type => Bool]

    Do not write out the background, foreground, and NaN-color fields.
    ($(GMTdoc)grd2cpt.html#n)
- **Q** | **log** :: [Type => Bool]

    Selects a logarithmic interpolation scheme [Default is linear].
    ($(GMTdoc)grd2cpt.html#q)
- **C** | **row_col** :: [Type => Bool]

    Replace the x- and y-coordinates on output with the corresponding column and row numbers.
    ($(GMTdoc)grd2cpt.html#c)
- $(GMT.opt_R)
- **S** | **steps** :: [Type => Bool | Str]			`Arg = zstart/zstop/zinc or n`

    Set steps in CPT. Calculate entries in CPT from zstart to zstop in steps of (zinc). Default
    chooses arbitrary values by a crazy scheme based on equidistant values for a Gaussian CDF.
    ($(GMTdoc)grd2cpt.html#s)
- **T** | **symetric** :: [Type => Str]			`Arg = -|+|_|=`

    Force the color table to be symmetric about zero (from -R to +R).
    ($(GMTdoc)grd2cpt.html#t)
- $(GMT.opt_V)
- **W** | **wrap** | **categorical** :: [Type => Bool | Str | []]      `Arg = [w]`

    Do not interpolate the input color table but pick the output colors starting at the
    beginning of the color table, until colors for all intervals are assigned.
    ($(GMTdoc)grd2cpt.html#w)
- **Z** | **continuous** :: [Type => Bool]

    Creates a continuous CPT [Default is discontinuous, i.e., constant colors for each interval].
    ($(GMTdoc)grd2cpt.html#z)
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
	if (IamModern[1] && ((val = find_in_dict(d, [:H :getcpt])[1]) === nothing))  cmd *= " -H"  end
	global current_cpt = common_grd(d, "grd2cpt " * cmd, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
grd2cpt(arg1; kw...) = grd2cpt("", arg1; kw...)