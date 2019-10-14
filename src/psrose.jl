"""
	rose(cmd0::String="", arg1=nothing; kwargs...)

Reads (length,azimuth) pairs and plot a windrose diagram.

Full option list at [`psrose`]($(GMTdoc)rose.html)

Parameters
----------

- $(GMT.opt_J)
- **A** | **sector** : [Type => Str | Number]

    Gives the sector width in degrees for sector and rose diagram.
    ($(GMTdoc)rose.html#a)
- $(GMT.opt_B)
- **C** | **color** : [Type => Str | GMTcpt]

    Give a CPT. The mid x-value for each bar is used to look-up the bar color.
    ($(GMTdoc)rose.html#c)
- **E** | **vectors** : [Type => Str]

    Plot vectors showing the principal directions given in the mode_file file.
    ($(GMTdoc)rose.html#e)
- **D** | **shift** : [Type => Bool]

    Shift sectors so that they are centered on the bin interval (e.g., first sector is centered on 0 degrees).
    ($(GMTdoc)rose.html#d)
- **F** | **no_scale** : [Type => Bool]

    Do not draw the scale length bar [Default plots scale in lower right corner].
    ($(GMTdoc)rose.html#f)
- **G** | **fill** : [Type => Str | Number]

    Selects shade, color or pattern for filling the sectors [Default is no fill].
    ($(GMTdoc)rose.html#g)
- **I** : **inquire** : [Type => Bool]

    Inquire. Computes statistics needed to specify a useful -R. No plot is generated.
    ($(GMTdoc)rose.html#i)
- **L** : **labels** : [Type => Str | Number]

    Specify labels for the 0, 90, 180, and 270 degree marks.
    ($(GMTdoc)rose.html#l)
- **M** : [Type => Bool]

    Used with -C to modify vector parameters.
    ($(GMTdoc)rose.html#m)
- $(GMT.opt_P)
- **Q** | **alpha** : [Type => Str | []]

    Sets the confidence level used to determine if the mean resultant is significant.
    ($(GMTdoc)rose.html#q)
- $(GMT.opt_R)
- **S** | **radius** : [Type => Bool]

    Specifies radius of plotted circle (append a unit from c|i|p).
    ($(GMTdoc)rose.html#s)
- **T** : **orientation** : [Type => Bool]

    Specifies that the input data are orientation data (i.e., have a 180 degree ambiguity)
    instead of true 0-360 degree directions [Default].
    ($(GMTdoc)rose.html#t)
- **W** | **pen** : [Type => Str | Tuple]

    Set pen attributes for sector outline or rose plot. [Default is no outline].
    ($(GMTdoc)rose.html#w)
- **Z** | **scale** : [Type => Str]

    Multiply the data radii by scale.
    ($(GMTdoc)rose.html#z)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_p)
- $(GMT.opt_t)
- $(GMT.opt_swap_xy)
"""
function rose(cmd0::String="", arg1=nothing; first=true, kwargs...)

	arg2 = nothing		# May be needed if GMTcpt type is sent in via C
	N_args = (arg1 === nothing) ? 0 : 1

	length(kwargs) == 0 && return monolitic("psrose", cmd0, arg1)

	d = KW(kwargs)

	# If inquire, no plotting so do it and return
	cmd = add_opt("", 'I', d, [:I :inquire])
	if (cmd != "")
		cmd = add_opt(cmd, 'A', d, [:A :sector])
		if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end
		return gmt("psrose " * cmd, arg1)
	end

    K, O = set_KO(first)		# Set the K O dance

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, "")
	if (GMTver < 6)  cmd = replace(cmd, opt_J => "")  end	# GMT5 doesn't accept a -J
	cmd = parse_common_opts(d, cmd, [:UVXY :c :e :p :t :yx :params], first)
	cmd = parse_these_opts(cmd, d, [[:A :sector], [:D :shift], [:F :no_scale], [:L :labels], [:M],
	                                [:Q :alpha], [:S :radius], [:T :orientation], [:Z :scale]])

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)
	if (isa(arg1, Array{GMT.GMTdataset,1}))  arg1 = arg1[1].data  end	# WHY I HAVE TO DO THIS?

	if (GMTver >= 6)		# This changed letter between 5 and 6
		cmd = add_opt(cmd, 'E', d, [:E :vectors])
		cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1, arg2)
	else
		cmd = add_opt(cmd, 'C', d, [:C :vectors])
	end
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd *= opt_pen(d, 'W', [:W :pen])

	return finish_PS_module(d, "psrose " * cmd, "", K, O, true, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
rose!(cmd0::String="", arg1=nothing; first=false, kw...) = rose(cmd0, arg1; first=first, kw...)
rose(arg1,  cmd0::String=""; first=true, kw...)  = rose(cmd0, arg1; first=first, kw...)
rose!(arg1, cmd0::String=""; first=false, kw...) = rose(cmd0, arg1; first=first, kw...)

const psrose  = rose 			# Alias
const psrose! = rose!			# Alias