"""
	makecpt(cmd0::String="", arg1=nothing; kwargs...)

Make static color palette tables (CPTs).

Full option list at [`makecpt`]($(GMTdoc)makecpt.html)

- **A** | **alpha** | **transparency** :: [Type => Str]

    Sets a constant level of transparency (0-100) for all color slices.
    ($(GMTdoc)makecpt.html#a)
- $(GMT.opt_C)
- **D** | **bg** | **background** :: [Type => Str | []]			`Arg = [i|o]`

    Select the back- and foreground colors to match the colors for lowest and highest
    z-values in the output CPT. 
    ($(GMTdoc)makecpt.html#d)
- **E** | **data_levels** :: [Type => Int | []]		`Arg = [nlevels]`

    Implies reading data table(s) from file or arrays. We use the last data column to
    determine the data range
    ($(GMTdoc)makecpt.html#e)
- **F** | **force_rgb** :: [Type => Str | []]		`Arg = [R|r|h|c][+c]]`

    Force output CPT to written with r/g/b codes, gray-scale values or color name.
    ($(GMTdoc)makecpt.html#f)
- **G** | **truncate** :: [Type => Str]              `Arg = zlo/zhi`

    Truncate the incoming CPT so that the lowest and highest z-levels are to zlo and zhi.
    ($(GMTdoc)makecpt.html#g)
- **H** | **save** :: [Type => Bool]

    Modern mode only: Write the CPT to disk [Default saves the CPT as the session current CPT].
    Required for scripts used to make animations via movie where we must pass named CPT files.
    ($(GMTdoc)makecpt.html#h)
- **I** | **inverse** | **reverse** :: [Type => Str]	`Arg = [c][z]`

    Reverse the sense of color progression in the master CPT.
    ($(GMTdoc)makecpt.html#i)
- **M** | **overrule_bg** :: [Type => Bool]

    Overrule background, foreground, and NaN colors specified in the master CPT with the values of
    the parameters COLOR_BACKGROUND, COLOR_FOREGROUND, and COLOR_NAN.
    ($(GMTdoc)makecpt.html#m)
- **N** | **no_bg** | **nobg** :: [Type => Bool]

    Do not write out the background, foreground, and NaN-color fields.
    ($(GMTdoc)makecpt.html#n)
- **Q** | **log** :: [Type => Bool | Str]			`Arg = [i|o]`

    Selects a logarithmic interpolation scheme [Default is linear].
    ($(GMTdoc)makecpt.html#q)
- **S** | **auto** :: [Type => Bool | Str]			`Arg = [mode]`

    Determine a suitable range for the -T option from the input table(s) (or stdin).
    ($(GMTdoc)makecpt.html#s)
- **T** | **range** :: [Type => Str]			`Arg = [min/max/inc[+b|l|n]|file|list]`

    Defines the range of the new CPT by giving the lowest and highest z-value and interval.
    ($(GMTdoc)makecpt.html#t)
- **W** | **wrap** | **categorical** :: [Type => Bool | Str | []]      `Arg = [w]`

    Do not interpolate the input color table but pick the output colors starting at the
    beginning of the color table, until colors for all intervals are assigned.
    ($(GMTdoc)makecpt.html#w)
- **Z** | **continuous** :: [Type => Bool]

    Creates a continuous CPT [Default is discontinuous, i.e., constant colors for each interval].
    ($(GMTdoc)makecpt.html#z)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_i)
"""
function makecpt(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("makecpt", cmd0, arg1)	# Monolithic mode

	d = KW(kwargs)
	cmd, = parse_common_opts(d, "", [:V_params])

    # If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, " ")
	cmd, arg1, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', 0, arg1)
	cmd = parse_these_opts(cmd, d, [[:A :alpha :transparency], [:D :bg :background], [:F :force_rgb], [:G :truncate],
	                                [:I :inverse :reverse], [:M :overrule_bg], [:N :no_bg :nobg], [:Q :log], [:S :auto], [:T :range], [:W :wrap :categorical], [:Z :continuous]])

	if ((val = find_in_dict(d, [:E :data_levels])[1]) !== nothing)
		if (arg1 === nothing)  error("E option requires that a data table is provided as well")
		else                   cmd *= " -E" * arg2str(val)
		end
	end

	if ((val = find_in_dict(d, [:cptname :cmapname])[1]) !== nothing)
		if (IamModern[1])  cmd *= " -H"  end
		cmd *=  " > " * string(val)
	elseif (IamModern[1])  cmd *= " -H"
	end
	cmd = "makecpt " * cmd
	if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end
	global current_cpt = gmt(cmd, arg1)
end

# ---------------------------------------------------------------------------------------------------
# Version to use with the -E option
makecpt(arg1; kw...) = makecpt("", arg1; kw...)
