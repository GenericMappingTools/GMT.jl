"""
	grd2cpt(cmd0::String="", arg1=nothing, kwargs...)

Make linear or histogram-equalized color palette table from grid

See full GMT (not the `GMT.jl` one) docs at [`grd2cpt`]($(GMTdoc)grd2cpt.html)

Parameters
----------

- **A** | **alpha** | **transparency** :: [Type => Str]

    Sets a constant level of transparency (0-100) for all color slices.
- $(GMT.opt_C)
- **D** | **bg** | **background** :: [Type => Str | []]			`Arg = [i|o]`

    Select the back- and foreground colors to match the colors for lowest and highest
    z-values in the output CPT. 
- **E** | **nlevels** :: [Type => Int | []]		`Arg = [nlevels]`

    Create a linear color table by using the grid z-range as the new limits in the CPT.
    Alternatively, append nlevels and we will resample the color table into nlevels equidistant slices.
- **F** | **color_model** :: [Type => Str | []]		`Arg = [R|r|h|c][+c]]`

    Force output CPT to written with r/g/b codes, gray-scale values or color name.
- **G** | **truncate** :: [Type => Str]             `Arg = zlo/zhi`

    Truncate the incoming CPT so that the lowest and highest z-levels are to zlo and zhi.
- **I** | **inverse** | **reverse** :: [Type => Str]	    `Arg = [c][z]`

    Reverse the sense of color progression in the master CPT.
- **L** | **datarange** | **clim** :: [Type => Str]			`Arg = minlimit/maxlimit`

    Limit range of CPT to minlimit/maxlimit, and don’t count data outside this range when estimating CDF(Z).
    [Default uses min and max of data.]
- **M** | **overrule_bg** :: [Type => Bool]

    Overrule background, foreground, and NaN colors specified in the master CPT with the values of
    the parameters COLOR_BACKGROUND, COLOR_FOREGROUND, and COLOR_NAN.
- **N** | **no_bg** | **nobg** :: [Type => Bool]

    Do not write out the background, foreground, and NaN-color fields.
- **Q** | **log** :: [Type => Bool]

    Selects a logarithmic interpolation scheme [Default is linear].
- $(GMT._opt_R)
- **S** | **symetric** :: [Type => Str]			`Arg = h|l|m|u`

    Force the color table to be symmetric about zero (from -R to +R).

- **T** | **range** :: [Type => Str]			`Arg = (min,max,inc) or = "n"`

    Set steps in CPT. Calculate entries in CPT from zstart to zstop in steps of (zinc). Default
    chooses arbitrary values by a crazy scheme based on equidistant values for a Gaussian CDF.
- $(GMT.opt_V)
- **W** | **wrap** | **categorical** :: [Type => Bool | Str | []]      `Arg = [w]`

    Do not interpolate the input color table but pick the output colors starting at the
    beginning of the color table, until colors for all intervals are assigned.
- **Z** | **continuous** :: [Type => Bool]

    Creates a continuous CPT [Default is discontinuous, i.e., constant colors for each interval].
- $(GMT.opt_V)
- $(GMT.opt_write)
"""
function grd2cpt(cmd0::String="", arg1=nothing; kw...)

	d = init_module(false, kw...)[1]			# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_common_opts(d, "", [:R :V_params :b :h :t])
	cmd, Tvec = helper_cpt(d, cmd)
	!isempty(Tvec) && error("grd2cpt does not accept an array argument in the 'range' option")
	if ((val = find_in_dict(d, [:E :nlevels])[1]) !== nothing)  cmd *= " -E" * arg2str(val)  end
	got_N = (is_in_dict(d, [:N :no_bg :nobg], del=true) !== nothing)

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)
	N_used = got_fname == 0 ? 1 : 0			# To know whether a cpt will go to arg1 or arg2
    isa(arg1, GMTgrid) && ((val = find_in_kwargs(kw, CPTaliases)[1]) === nothing) && (d[:C] = (arg1.cpt != "") ? arg1.cpt : :turbo)
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, CPTaliases, 'C', N_used, arg1)

	r = common_grd(d, "grd2cpt " * cmd, arg1, arg2)		# r may be a tuple if -E+f was used
	(isa(r, String)) && (return got_N ? r * " -N" : r)	# If it's a String it's beause of a Vd=2
	got_N && (r.bfn = ones(3,3))	# Cannot remove the bfn like in plain GMT so make it all whites
	CURRENT_CPT[1] = (r !== nothing) ? (isa(r, Tuple) ? r[1] : r) : GMTcpt()
	isa(r, Tuple) && (r[2].colnames = ["Z", "CDF(Z)"])
	CTRL.pocket_d[1] = d			# Store d that may be not empty with members to use in other modules
	return r
end

# ---------------------------------------------------------------------------------------------------
grd2cpt(arg1; kw...) = grd2cpt("", arg1; kw...)