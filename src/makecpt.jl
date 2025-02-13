"""
	makecpt(cmd0::String="", arg1=nothing; kwargs...)
or

	makecpt(name::Symbol; kwargs...)

Make static color palette tables (CPTs). The second form accepts a name of one of the GMT CPT defaults.

- **A** | **alpha** | **transparency** :: [Type => Str]

    Sets a constant level of transparency (0-100) for all color slices.
- $(opt_C)
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

To see the full documentation type: ``@? makecpt``
"""
makecpt(cmd0::Symbol; kwargs...) = makecpt(""; C=string(cmd0), kwargs...)	# Ex: makecpt(:gray)
function makecpt(cmd0::String="", arg1=nothing; kwargs...)::Union{String, GMTcpt}
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	makecpt(cmd0, arg1, d)
end
function makecpt(cmd0::String, arg1, d::Dict)::Union{String, GMTcpt}

	cmd, = parse_common_opts(d, "", [:V_params])

	# This deals with the special case of, for example, "makecpt(G, cmap=:gray"). Here, we recieve (makecpt(G,...) is comp)
	# a (C=nothing, cmap=:gray) and because 'C' is searched first we would loose the cmap=:gray. Solution is to delete :C
	((get(d, :C, nothing)) === nothing && is_in_dict(d, [:color :cmap :colormap :colorscale]) !== nothing) && delete!(d, :C)

	# If file name sent in, read it
	cmd, arg1, = read_data(d, cmd0, cmd, arg1, " ")
	cmd, arg1, = add_opt_cpt(d, cmd, CPTaliases, 'C', 0, arg1)
	cmd, Tvec = helper_cpt(d, cmd)
	cmd = parse_E_mkcpt(d, [:E :nlevels], cmd, arg1)
	got_N = (is_in_dict(d, [:N :no_bg :nobg], del=true) !== nothing)

	cmd = "makecpt " * cmd
	(dbg_print_cmd(d, cmd) !== nothing) && return cmd
	(arg1 === nothing && !isempty(Tvec)) && (arg1 = Tvec; Tvec = Float64[])
	_r = gmt(cmd, arg1, !isempty(Tvec) ? Tvec : nothing)
	r::GMTcpt = (_r !== nothing) ? _r : GMTcpt()	# _r === nothing when we save CPT on disk.
	@assert (r isa GMTcpt)
	(got_N && !isempty(r)) && (r.bfn = ones(3,3))	# Cannot remove the bfn like in plain GMT so make it all whites
	CTRL.pocket_d[1] = d					# Store d that may be not empty with members to use in other modules
	CURRENT_CPT[1] = r
	return r
end

function makecpt(G::GMTgrid; equalize=false, kw...)		# A version that works on grids.
	# equalize = true uses default grd2cpt. equalize=n uses grd2cpt -Tn
	# The kw... are those of makecpt or grd2cpt depending on 'equalize'.
	
	val, symb = find_in_kwargs(kw, CPTaliases)
	cpt = (val === nothing) ? ((G.cpt != "") ? G.cpt : :turbo) : nothing
	d = Dict{Symbol, Any}()
	if (equalize == 0 && symb != Symbol() && val === nothing && cpt !== nothing)
		# It means kw have a -C, but it can be a C=nothing. Remove the duplicate  that was in kw.
		d = KW(kw...);	delete!(d, symb)	# This confusion is due to the crazziness possible in lelandshade()
	end
	if (equalize == 0)
		t = isempty(d) ? kw : d
		range::Vector{Float64} = G.range
		loc_eps = 0.0004
		makecpt(; T=@sprintf("%.12g/%.12g/256+n", range[5] - loc_eps*abs(range[5]), range[6] + loc_eps*abs(range[6])), C=cpt, t...)
	else
		(equalize == 1) ? grd2cpt(G, C=cpt, kw...) : grd2cpt(G, T="$equalize", C=cpt, kw...)
	end
end

# ---------------------------------------------------------------------------------------------------
function parse_E_mkcpt(d::Dict, symbs::Array{<:Symbol}, cmd::String, arg1)
	(SHOW_KWARGS[1]) && return print_kwarg_opts(symbs, "Number")
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
	                                [:I :inverse :reverse], [:L :datarange :clim], [:M :overrule_bg], [:Q :log], [:S :auto :symmetric], [:W :wrap :categorical], [:Z :continuous]])
	cmd, Tvec = parse_opt_range(d, cmd, "T")
	!isempty(Tvec) && (cmd *= arg2str(Tvec, ','); Tvec = Float64[]) # Work arround a semi-bug in GMT that is (< 6.5) unable to recognize num lists.
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
	(SHOW_KWARGS[1]) && return print_kwarg_opts(symbs, "Tuple | Array | String | Number"), Float64[]	# Just print the options
	Tvec::Vector{Float64} = Float64[]
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		if (isa(val, Tuple))
			n::Int = length(val)
			out::String = isa(val[1], Symbol) ? arg2str(val[1:min(n,3)], ',') : arg2str(val[1:min(n,3)])
			if (n > 3)
				for k = 4:n			# N should be at most = 5 (e.g. +n+b)
					_opt::String = string(val[k])
					if     (startswith(_opt, "sli") || startswith(_opt, "num"))   out *= "+n"
					elseif (startswith(_opt, "log2"))  out *= "+b"
					elseif (startswith(_opt, "log1"))  out *= "+l"
					else   @warn("Unkown option \"$_opt\" in range option")
					end
				end
			elseif (n == 2)
				out *= "/256+n"
			end
		elseif (isa(val, VMr) || isa(val, GMTdataset))
			Tvec, out = vec(Float64.(val)), ""	# In 6.5, Tvec needs to be a GMTdataset with comment = LIST
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
