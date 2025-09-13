"""
	rose(cmd0::String="", arg1=nothing; kwargs...)

Reads (length,azimuth) pairs and plot a windrose diagram (polar histograms).

See full GMT (not the `GMT.jl` one) docs at [`psrose`]($(GMTdoc)rose.html)

Parameters
----------

- $(_opt_J)
- **A** | **sector** | **sectors** :: [Type => Str | Number]

	Gives the sector width in degrees for sector and rose diagram.
- $(_opt_B)
- **C** | **color** :: [Type => Str | GMTcpt]

	Give a CPT. The mid x-value for each bar is used to look-up the bar color.
- **E** | **vectors** :: [Type => Str]

	Plot vectors showing the principal directions given in the mode_file file.
- **D** | **shift** :: [Type => Bool]

	Shift sectors so that they are centered on the bin interval (e.g., first sector is centered on 0 degrees).
- **F** | **no_scale** :: [Type => Bool]

	Do not draw the scale length bar [Default plots scale in lower right corner].
- **G** | **fill** :: [Type => Str | Number]

	Selects shade, color or pattern for filling the sectors [Default is no fill].
- **I** | **inquire** :: [Type => Bool]

	Inquire. Computes statistics needed to specify a useful -R. No plot is generated.
- **L** | **labels** :: [Type => Str | Number]

	Specify labels for the 0, 90, 180, and 270 degree marks.
- **M** | **vector_params** :: [Type => Str]

	Used with -C to modify vector parameters.
- $(opt_P)
- **Q** | **alpha** :: [Type => Str | []]

	Sets the confidence level used to determine if the mean resultant is significant.
- $(_opt_R)
- **S** | **norm** | **normalize** :: [Type => Bool]

	Specifies radius of plotted circle (append a unit from c|i|p).
- **T** | **orientation** :: [Type => Bool]

	Specifies that the input data are orientation data (i.e., have a 180 degree ambiguity)
	instead of true 0-360 degree directions [Default].
- **W** | **pen** :: [Type => Str | Tuple]

	Set pen attributes for sector outline or rose plot. [Default is no outline].
- **Z** | **scale** :: [Type => Str]

	Multiply the data radii by scale.
- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)
- $(_opt_bi)
- $(_opt_di)
- $(opt_e)
- $(_opt_h)
- $(_opt_i)
- $(_opt_p)
- $(_opt_t)
- $(opt_w)
- $(opt_swap_xy)
- $(opt_savefig)

To see the full documentation type: ``@? rose``
"""
rose(cmd0::String; kwargs...)  = rose_helper(cmd0, nothing; kwargs...)
rose(arg1; kwargs...)          = rose_helper("", arg1; kwargs...)
rose!(cmd0::String; kwargs...) = rose_helper(cmd0, nothing; first=false, kwargs...)
rose!(arg1; kwargs...)         = rose_helper("", arg1; first=false, kwargs...)

# ---------------------------------------------------------------------------------------------------
function rose_helper(cmd0::String, arg1; first=true, kwargs...)

    gmt_proggy = (IamModern[1]) ? "rose "  : "psrose "

	arg2 = nothing		# May be needed if GMTcpt type is sent in via C
	N_args = (arg1 === nothing) ? 0 : 1

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	# If inquire, no plotting so do it and return
	cmd = add_opt(d, "", "I", [:I :inquire])
	if (cmd != "")
		cmd = add_opt(d, cmd, "A", [:A :sector :sectors])
		if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end
		return gmt("psrose " * cmd, arg1)
	end

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c")
	cmd, = parse_common_opts(d, cmd, [:UVXY :c :e :p :t :w :margin :params]; first=first)
	cmd  = parse_these_opts(cmd, d, [[:D :shift], [:F :no_scale], [:L :labels], [:M :vector_params], [:N :vonmises],
	                                 [:Q :alpha], [:S :norm :normalize], [:T :orientation], [:Z :scale]])
	cmd = add_opt(d, cmd, "A", [:A :sector :sectors], (width="", rose="_+r"))

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)
	if (isa(arg1, Array{<:GMTdataset,1}))  arg1 = arg1[1].data  end	# WHY I HAVE TO DO THIS?

	cmd = add_opt(d, cmd, "E", [:E :vectors])
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, CPTaliases, 'C', N_args, arg1, arg2)
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd *= opt_pen(d, 'W', [:W :pen])

	_cmd = [gmt_proggy * cmd]
	_cmd = frame_opaque(_cmd, opt_B, opt_R, opt_J)		# No -t in frame
	((r = check_dbg_print_cmd(d, _cmd)) !== nothing) && return r
	prep_and_call_finish_PS_module(d, _cmd, "", K, O, true, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
const psrose  = rose 			# Alias
const psrose! = rose!			# Alias