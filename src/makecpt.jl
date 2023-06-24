"""
	makecpt(cmd0::String="", arg1=nothing; kwargs...)
or

	makecpt(name::Symbol; kwargs...)

Make static color palette tables (CPTs). The second form accepts a name of one of the GMT CPT defaults.

See full GMT (not the `GMT.jl` one) docs at [`makecpt`]($(GMTdoc)makecpt.html)

- **A** | **alpha** | **transparency** :: [Type => Str]

    Sets a constant level of transparency (0-100) for all color slices.
- $(GMT.opt_C)
- **D** | **bg** | **background** :: [Type => Str | []]			`Arg = [i|o]`

    Select the back- and foreground colors to match the colors for lowest and highest
    z-values in the output CPT. 
- **E** | **nlevels** :: [Type => Int | []]		`Arg = [nlevels]`

    Implies reading data table(s) from file or arrays. We use the last data column to
    determine the data range
- **F** | **color_model** :: [Type => Str | []]		`Arg = [R|r|h|c][+c]]`

    Force output CPT to written with r/g/b codes, gray-scale values or color name.
- **G** | **truncate** :: [Type => Str]              `Arg = zlo/zhi`

    Truncate the incoming CPT so that the lowest and highest z-levels are to zlo and zhi.
- **I** | **inverse** | **reverse** :: [Type => Str]	`Arg = [c][z]`

    Reverse the sense of color progression in the master CPT.
- **M** | **overrule_bg** :: [Type => Bool]

    Overrule background, foreground, and NaN colors specified in the master CPT with the values of
    the parameters COLOR_BACKGROUND, COLOR_FOREGROUND, and COLOR_NAN.
- **N** | **no_bg** | **nobg** :: [Type => Bool]

    Do not write out the background, foreground, and NaN-color fields.
- **Q** | **log** :: [Type => Bool | Str]			`Arg = [i|o]`

    Selects a logarithmic interpolation scheme [Default is linear].
- **S** | **auto** :: [Type => Bool | Str]			`Arg = [mode]`

    Determine a suitable range for the -T option from the input table(s) (or stdin).
- **T** | **range** :: [Type => Str]			`Arg = [min/max/inc[+b|l|n]|file|list]`

    Defines the range of the new CPT by giving the lowest and highest z-value and interval.
- **W** | **wrap** | **categorical** :: [Type => Bool | Str | []]      `Arg = [w]`

    Do not interpolate the input color table but pick the output colors starting at the
    beginning of the color table, until colors for all intervals are assigned.
- **Z** | **continuous** :: [Type => Bool]

    Creates a continuous CPT [Default is discontinuous, i.e., constant colors for each interval].
- $(GMT._opt_bi)
- $(GMT._opt_di)
- $(GMT._opt_h)
- $(GMT._opt_i)

To see the full documentation type: ``@? makecpt``
"""
makecpt(cmd0::Symbol; kwargs...) = makecpt(""; C=string(cmd0), kwargs...)	# Ex: makecpt(:gray)
function makecpt(cmd0::String="", arg1=nothing; kwargs...)::Union{String, GMTcpt}

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:V_params])

    # If file name sent in, read it and compute a tight -R if this was not provided 
    cmd, arg1, = read_data(d, cmd0, cmd, arg1, " ")
	cmd, arg1, = add_opt_cpt(d, cmd, CPTaliases, 'C', 0, arg1)
	cmd, Tvec = helper_cpt(d, cmd)
	cmd = parse_E_mkcpt(d, [:E :nlevels], cmd, arg1)
	got_N = (is_in_dict(d, [:N :no_bg :nobg], del=true) !== nothing)

	cmd = "makecpt " * cmd
	(dbg_print_cmd(d, cmd) !== nothing) && return cmd
	(arg1 === nothing && !isempty(Tvec)) && (arg1 = Tvec; Tvec = Float64[])
	_r = gmt(cmd, arg1, !isempty(Tvec) ? Tvec : nothing)
	r = (_r !== nothing) ? _r : GMTcpt()	# _r === nothing when we save CPT on disk.
	(got_N && !isempty(r)) && (r.bfn = ones(3,3))	# Cannot remove the bfn like in plain GMT so make it all whites
	current_cpt[1] = r
	return r
end

# ---------------------------------------------------------------------------------------------------
function parse_E_mkcpt(d::Dict, symbs::Array{<:Symbol}, cmd::String, arg1)
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "Number")
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		(arg1 === nothing && cmd[1] == ' ') && error("E option requires that a data table is provided as well")
		cmd *= " -E" * arg2str(val)::String
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function helper_cpt(d::Dict, cmd::String)
	# Common to both make & grd cpt
	cmd = parse_these_opts(cmd, d, [[:A :alpha :transparency], [:D :bg :background], [:F :color_model], [:G :truncate],
	                                [:I :inverse :reverse], [:L :datarange :clim], [:M :overrule_bg], [:Q :log], [:S :auto :symetric], [:W :wrap :categorical], [:Z :continuous]])
	cmd, Tvec = parse_opt_range(d, cmd, "T")
	if ((val = find_in_dict(d, [:name :save])[1]) !== nothing)
		(IamModern[1]) && (cmd *= " -H")
		cmd *=  " > " * string(val)::String
	elseif (IamModern[1])  cmd *= " -H"
	end
	return cmd, Tvec
end

# -------------------------------------------------------------------------------------------
function parse_opt_range(d::Dict, cmd::String, opt::String="")::Tuple{String, Vector{Float64}}
	symbs = [:T :range :inc :bin]
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "Tuple | Array | String | Number"), Float64[]	# Just print the options
	Tvec::Vector{Float64} = Float64[]
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		if (isa(val, Tuple))
			n = length(val)
			out::String = arg2str(val[1:min(n,3)])
			if (n > 3)
				for k = 4:n			# N should be at most = 5 (e.g. +n+b)
					_opt::String = string(val[k])
					if     (startswith(_opt, "sli") || startswith(_opt, "num"))   out *= "+n"
					elseif (startswith(_opt, "log2"))  out *= "+b"
					elseif (startswith(_opt, "log1"))  out *= "+l"
					else   @warn("Unkown option \"$_opt\" in range option")
					end
				end
			end
		elseif (isa(val, VMr))
			out = arg2str(val,',')		# This works arround a semi-bug in GMT that was not (up to 6.4) able to recognize num lists.
			#Tvec, out = vec(Float64.(val)), ""	# In 6.5, Tvec needs to be a GMTdataset with comment = LIST
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
makecpt(b, e, inc=nothing; kw...) = makecpt("", nothing; T= (inc === nothing) ? (b,e) : (b,e,inc), kw...)
