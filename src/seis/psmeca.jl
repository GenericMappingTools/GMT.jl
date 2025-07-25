"""
	meca(cmd0::String="", arg1=nothing; kwargs...)

Plot focal mechanisms.

See full GMT (not the `GMT.jl` one) docs at [`meca`]($(GMTdoc)supplements/seis/meca.html)

Parameters
----------

- $(_opt_J)
- $(_opt_R)

- $(_opt_B)
- **A** | **offset** :: [Type => Bool | Str | GMTcpt]

    Offsets focal mechanisms to the longitude, latitude specified in the last two columns of the input
- **C** | **color** | **cmap** :: [Type => Number | Str | GMTcpt]

    Give a CPT and let compressive part color be determined by the z-value in the third column. 
- **D** | **depth_limits** :: [Type => Str | Tuple]

    Plots events between depmin and depmax.
- **E** | **fill_extensive** | **extensionfill** :: [Type => Str | Number]

    Selects filling of extensive quadrants. [Default is white].
- **Fa** | **Fe** | **Fg** | **Fo** | **Fp** | **Fr** | **Ft** | **Fz** :: [Type => ]

    Sets one or more attributes.
- **G** | **fill** | **compressionfill** :: [Type => Str | Number]

    Selects shade, color or pattern for filling the sectors [Default is no fill].
- $(opt_P)
- **L** | **outline_pen** | **pen_outline** :: [Type => Str | Number | Tuple]

    Draws the “beach ball” outline with pen attributes instead of with the default pen set by **pen**
- **M** | **same_size** | **samesize** :: [Type => Bool]

    Use the same size for any magnitude. Size is given with **S**
- **N** | **no_clip** | **noclip** :: [Type => Str | []]

    Do NOT skip symbols that fall outside frame boundary.
- **Sc|aki** | **Sc|CMT|gcmt** | **Sm|mt|moment_tensor** | ... :: [Type => Str]

    Selects the meaning of the columns in the input data.
- **convention=:Sa|:aki|:Sc|:CMT|:gcmt|:Sm|:mt|:moment_tensor|:Sd|:mt_closest|:moment_closest|:Sz|:mt_deviatoric :moment_deviatoric|:Sp :partial|:Sx|:principal|:principal_axis|:Sy|:principal_closest|:St|:principal_deviatoric

    Alternative way of selecting the meaning of the columns in the input data.
- **T** | **nodal** :: [Type => Number | Str]

    Plots the nodal planes and outlines the bubble which is transparent.
- **W** | **pen** :: [Type => Str | Tuple]

    Set pen attributes for all lines and the outline of symbols.
- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)
- $(_opt_di)
- $(opt_e)
- $(_opt_h)
- $(_opt_i)
- $(_opt_p)
- $(_opt_t)
- $(opt_swap_xy)

Example: Plot a focal mechanism using the Aki & Richards convention 

```julia
    psmeca([0.0 3.0 0.0 0 45 90 5 0 0], aki=true, fill=:black, region=(-1,4,0,6), proj=:Merc, show=1)
```
The same but add a Label
```julia
    psmeca(mat2ds([0.0 3.0 0.0 0 45 90 5 0 0], ["Thrust"]), aki=true, fill=:black, region=(-1,4,0,6), proj=:Merc, show=1)
```
"""
meca(cmd0::String; kwargs...)  = meca_helper(cmd0, nothing; kwargs...)
meca(arg1; kwargs...)          = meca_helper("", arg1; kwargs...)
meca!(cmd0::String; kwargs...) = meca_helper(cmd0, nothing; first=false, kwargs...)
meca!(arg1; kwargs...)         = meca_helper("", arg1; first=false, kwargs...)

# ---------------------------------------------------------------------------------------------------
function meca_helper(cmd0::String, arg1; first=true, kwargs...)

    proggy = (IamModern[1]) ? "meca "  : "psmeca "
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode
	common_mecas(cmd0, arg1, d, proggy, first, K, O)
end

# ---------------------------------------------------------------------------------------------------
const psmeca  = meca 			# Alias
const psmeca! = meca!			# Alias

"""
	coupe(cmd0::String="", arg1=nothing; kwargs...)

Plot cross-sections of focal mechanisms.

See full GMT (not the `GMT.jl` one) docs at [`pscoupe`]($(GMTdoc)coupe.html).
Essentially the same as **meca** plus **A**. Run `gmthelp(coupe)` to see the list of options.
"""
coupe(cmd0::String; kwargs...)  = coupe_helper(cmd0, nothing; kwargs...)
coupe(arg1; kwargs...)          = coupe_helper("", arg1; kwargs...)
coupe!(cmd0::String; kwargs...) = coupe_helper(cmd0, nothing; first=false, kwargs...)
coupe!(arg1; kwargs...)         = coupe_helper("", arg1; first=false, kwargs...)

# ---------------------------------------------------------------------------------------------------
function coupe_helper(cmd0::String, arg1; first=true, kwargs...)

    proggy = (IamModern[1]) ? "coupe "  : "pscoupe "
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode
	common_mecas(cmd0, arg1, d, proggy, first, K, O)
end

const pscoupe  = coupe 			# Alias
const pscoupe! = coupe!			# Alias

# ---------------------------------------------------------------------------------------------------
function common_mecas(cmd0, arg1, d, proggy, first, K, O)
	# Helper function to both psmeca & pscoupe

	arg2 = nothing		# May be needed if GMTcpt type is sent in via C
	N_args = (arg1 === nothing) ? 0 : 1

	if (occursin("meca", proggy))
		cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12cd/0d")
		cmd, = parse_common_opts(d, cmd, [:UVXY :c :di :e :p :t :params]; first=first)
		(haskey(d, :A) || haskey(d, :offset) && GMTver <= v"6.4.0" && isa(arg1, GDtype)) &&
			@warn("Due to a GMT bug (fixed in GMT > 6.4.0) plotting with offsets works only when data is in a disk file.")
		cmd  = parse_these_opts(cmd, d, [[:A :offset], [:D :depth_limits]])
	else
		cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX14c/10c")
		cmd, = parse_common_opts(d, cmd, [:UVXY :c :di :e :p :t :params]; first=first)
		cmd_ = add_opt(d, "", "Aa", [:Aa :cross_ll_pts], (lon1="", lat1="", lon2="", lat2="", dip="", width="", dmin="", dmax="", frame="_+f"))
		if (cmd_ == "")
			cmd_ = add_opt(d, "", "Ab", [:Ab :cross_ll_azim], (lon1="", lat1="", strike="", length="", dip="", width="", dmin="", dmax="", frame="_+f"))
		end
		if (cmd_ == "")
			cmd_ = add_opt(d, "", "Ac", [:Ac :cross_xy_pts], (x1="", y1="", x2="", y2="", dip="", width="", dmin="", dmax="", frame="_+f"))
		end
		if (cmd_ == "")
			cmd_ = add_opt(d, "", "Ad", [:Ad :cross_xy_azim], (x1="", y1="", strike="", length="", dip="", width="", dmin="", dmax="", frame="_+f"))
		end
		(cmd_ == "" && !SHOW_KWARGS[1]) && error("Specifying cross-section type is mandatory")
		cmd *= cmd_
	end

	cmd = add_opt_fill(cmd, d, [:E :fill_extensive :extensionfill], 'E')
	cmd  = parse_these_opts(cmd, d, [[:L :outline_pen :pen_outline], [:M :same_size :samesize],
	                                 [:N :no_clip :noclip], [:T :nodal]])
	cmd  = parse_these_opts(cmd, d, [[:Fa :PT_axes], [:Fe :T_axis_color], [:Fg :P_axis_color], [:Fo :psvelo],
	                                 [:Fp :P_axis_pen], [:Fr :label_box], [:Ft :T_axis_pen], [:Fz :zero_trace]])
	cmd = add_opt_fill(cmd, d, [:G :fill :compressionfill], 'G')
	#(occursin("coupe", proggy)) && (cmd = add_opt(d, cmd, "Q", [:Q]))

	# If file name sent in, read it and compute a tight -R if it was not provided 
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)
	n_cols = (isa(arg1, Matrix) || isa(arg1, GMTdataset)) ? size(arg1,2) : 0

	if     ((val = is_in_dict(d, [:Sa :aki])) !== nothing) symbs = [:Sa val]
	elseif ((val = is_in_dict(d, [:Sc :CMT :gcmt])) !== nothing) symbs = [:Sc val]
	elseif ((val = is_in_dict(d, [:Sm :mt :moment_tensor])) !== nothing) symbs = [:Sm val]
	elseif ((val = is_in_dict(d, [:Sd :mt_closest :moment_closest])) !== nothing) symbs = [:Sd val]
	elseif ((val = is_in_dict(d, [:Sz :mt_deviatoric :moment_deviatoric])) !== nothing) symbs = [:Sz val]
	elseif (haskey(d, :Sp) || haskey(d, :partial))  symbs = [:Sp :partial]
	elseif ((val = is_in_dict(d, [:Sx :principal :principal_axis])) !== nothing) symbs = [:Sx val]
	elseif (haskey(d, :Sy) || haskey(d, :principal_closest))     symbs = [:Sy :principal_closest]
	elseif (haskey(d, :St) || haskey(d, :principal_deviatoric))  symbs = [:St :principal_deviatoric]
	elseif ((val = find_in_dict(d, [:convention])[1]) !== nothing)
		_val = Symbol(val)::Symbol
		symbs = (_val == :aki) ? [:Sa _val] : (_val == :CMT || _val == :gcmt) ? [:Sc _val] : (_val == :mt || _val == :moment_tensor) ? [:Sm _val] : (_val == :mt_closest || _val == :moment_closest) ? [:Sd _val] : (_val == :mt_deviatoric || _val == :moment_deviatoric) ? [:Sz _val] : (_val == :partial) ? [:Sp _val] : (_val == :principal || _val == :principal_axis) ? [:Sx _val] : (_val == :principal_closest) ? [:Sy _val] : (_val == :principal_deviatoric) ? [:St _val] : error("Unknown convention $_val")
		d[_val] = true
	elseif (n_cols >= 7 && n_cols < 10)  d[:Sa] = true; symbs = [:Sa]		# Implicit Aki
	elseif (n_cols >= 11 && n_cols < 14) d[:Sc] = true; symbs = [:Sc]		# Implicit CMT
	elseif (SHOW_KWARGS[1])  symbs = [:Sa :aki :Sc :CMT :gcmt :Sm :mt :Sd :mt_closest :moment_closest :Sz :mt_deviatoric :moment_deviatoric :Sp :partial :Sx :principal :principal_axis :Sy :principal_closest :St :principal_deviatoric]
	else  error("Must select one convention")
	end
	cmd_ = add_opt(d, "", string(symbs[1]), symbs, (scale="", angle="+a", font=("+f", font), justify="+j",
	               radius_moment="_+l", same_size="_+m", refmag="+s", offset="+o"))
	if (length(cmd_) != 0 && (length(cmd_) == 4 || cmd_[5] == '+'))		# If scale not given search for the 'scale' kwarg
		cmd = ((val = find_in_dict(d, [:scale])[1]) !== nothing) ? cmd * string(cmd_,val) : cmd * cmd_ * "2.5c"
	else
		cmd *= cmd_
	end

	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:Z :C :color :cmap], 'Z', N_args, arg1, arg2)
	cmd *= opt_pen(d, 'W', [:W :pen])

	prep_and_call_finish_PS_module(d, proggy * cmd, "", K, O, true, arg1, arg2)
end