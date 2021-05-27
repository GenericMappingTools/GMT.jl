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
- **E** | **nlevels** :: [Type => Int | []]		`Arg = [nlevels]`

    Implies reading data table(s) from file or arrays. We use the last data column to
    determine the data range
    ($(GMTdoc)makecpt.html#e)
- **F** | **color_model** :: [Type => Str | []]		`Arg = [R|r|h|c][+c]]`

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
- $(GMT.opt_h)
- $(GMT.opt_i)
"""
function makecpt(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("makecpt", cmd0, arg1)	# Monolithic mode

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:V_params])

    # If file name sent in, read it and compute a tight -R if this was not provided 
    cmd, arg1, = read_data(d, cmd0, cmd, arg1, " ")
	cmd, arg1, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', 0, arg1)
	cmd, Tvec = helper_cpt(d, cmd)
	cmd = parse_E_mkcpt(d, [:E :nlevels], cmd, arg1)

	cmd = "makecpt " * cmd
	(dbg_print_cmd(d, cmd) !== nothing) && return cmd
	r = gmt(cmd, arg1, !isempty(Tvec) ? Tvec : nothing)
	current_cpt[1] = (r !== nothing) ? r : GMTcpt()
    return r
end

# ---------------------------------------------------------------------------------------------------
function parse_E_mkcpt(d::Dict, symbs::Array{<:Symbol}, cmd::String, arg1)
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "Number")
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		(arg1 === nothing) && error("E option requires that a data table is provided as well")
		cmd *= " -E" * arg2str(val)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function helper_cpt(d::Dict, cmd::String)
	# Common to both make & grd cpt
	cmd = parse_these_opts(cmd, d, [[:A :alpha :transparency], [:D :bg :background], [:F :color_model], [:G :truncate],
	                                [:I :inverse :reverse], [:M :overrule_bg], [:N :no_bg :nobg], [:Q :log], [:S :auto], [:W :wrap :categorical], [:Z :continuous]])
	cmd, Tvec = parse_opt_range(d, cmd, "T")
	if ((val = find_in_dict(d, [:cptname :cmapname])[1]) !== nothing)
		(IamModern[1]) && (cmd *= " -H")
		cmd *=  " > " * string(val)
	elseif (IamModern[1])  cmd *= " -H"
	end
	return cmd, Tvec
end

# -------------------------------------------------------------------------------------------
function parse_opt_range(d::Dict, cmd::String, opt::String="")::Tuple{String, Vector{Float64}}
	symbs = [:T :range :inc :bin]
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "Tuple | Array | String | Number")	# Just print the options
	Tvec = Vector{Float64}()
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		if (isa(val, Tuple))
			n = length(val)
			out = arg2str(val[1:min(n,3)])
			if (n > 3)
				for k = 4:n			# N should be at most = 5 (e.g. +n+b)
					_opt = string(val[k])
					if     (startswith(_opt, "sli") || startswith(_opt, "num"))   out *= "+n"
					elseif (startswith(_opt, "log2"))  out *= "+b"
					elseif (startswith(_opt, "log1"))  out *= "+l"
					else   @warn("Unkown option \"$_opt\" in range option")
					end
				end
			end
		elseif (isa(val, Vector{<:Real}) || isa(val, Matrix{<:Real}))
			out = arg2str(val,',')
			if (length(val) == 1)  out *= ","  end
			if (length(out) > 1023)  Tvec, out = vec(val), ""  end		# Should be temporary till all that use -T catch up with Vec
		else
			out = arg2str(val)		# Everything fits here if given as a string
		end
		if (opt != "")  out = " -" * opt  * out end
		cmd *= out
	end
	return cmd, Tvec
end

# ---------------------------------------------------------------------------------------------------
# Version to use with the -E option
makecpt(arg1; kw...) = makecpt("", arg1; kw...)
