"""
	rose(cmd0::String="", arg1=[]; kwargs...)

Reads (length,azimuth) pairs and plot a windrose diagram.

Full option list at [`psrose`](http://gmt.soest.hawaii.edu/doc/latest/rose.html)

Parameters
----------

- $(GMT.opt_J)
- **A** : **sector** : -- Str or number --

    Gives the sector width in degrees for sector and rose diagram.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#a)
- $(GMT.opt_B)
- **C** : **color** : -- Str or GMTcpt --

    Give a CPT. The mid x-value for each bar is used to look-up the bar color.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#c)
- **E** : **vectors** : -- Str --

    Plot vectors showing the principal directions given in the mode_file file.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#e)
- **D** : **shift** : -- Bool or [] --

    Shift sectors so that they are centered on the bin interval (e.g., first sector is centered on 0 degrees).
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#d)
- **F** : **no_scale** : -- Bool or [] --

    Do not draw the scale length bar [Default plots scale in lower right corner].
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#f)
- **G** : **fill** : -- Number or Str --

    Selects shade, color or pattern for filling the sectors [Default is no fill].
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#g)
- **I** : **inquire** : -- Bool or [] --

    Inquire. Computes statistics needed to specify a useful -R. No plot is generated.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#i)
- **L** : **labels** : -- Number or Str --

    Specify labels for the 0, 90, 180, and 270 degree marks.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#l)
- **M** : -- Bool or [] --

    Used with -C to modify vector parameters.
    [`-M`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#m)
- $(GMT.opt_P)
- **Q** : **alpha** : -- Str or [] --

    Sets the confidence level used to determine if the mean resultant is significant.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#q)
- $(GMT.opt_R)
- **S** : **radius** : -- Bool or [] --

    Specifies radius of plotted circle (append a unit from c|i|p).
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#s)
- **T** : **orientation** : -- Bool or [] --

    Specifies that the input data are orientation data (i.e., have a 180 degree ambiguity)
    instead of true 0-360 degree directions [Default].
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#t)
- **W** : **pen** : -- Str or tuple --

    Set pen attributes for sector outline or rose plot. [Default is no outline].
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#w)
- **Z** : **scale** : -- Str --

    Multiply the data radii by scale.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/rose.html#z)
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
function rose(cmd0::String="", arg1=[]; K=false, O=false, first=true, kwargs...)

	arg2 = []		# May be needed if GMTcpt type is sent in via C
	N_args = isempty_(arg1) ? 0 : 1

	length(kwargs) == 0 && return monolitic("psrose", cmd0, arg1)

	d = KW(kwargs)

	# If inquire, no plotting so do it and return
	cmd = add_opt("", 'I', d, [:I :inquire])
	if (cmd != "")
		cmd = add_opt(cmd, 'A', d, [:A :sector])
		(haskey(d, :Vd)) && println(@sprintf("\tpsrose %s", cmd))
		if (!isempty_(arg1))  return gmt("psrose " * cmd, arg1)
		else                  return gmt("psrose " * cmd)
		end
	end

	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	K, O = set_KO(first)		# Set the K O dance
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, "")
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_di = parse_di(cmd, d)
	cmd, opt_i  = parse_i(cmd, d)
	cmd = parse_common_opts(d, cmd, [:UVXY :e :h :p :t :xy :params])
    cmd = parse_these_opts(cmd, d, [[:A :sector], [:D :shift], [:F :no_scale], [:L :labels], [:M],
                [:Q :alpha], [:S :radius], [:T :orientation], [:Z :scale]])

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R, opt_i, opt_bi, opt_di)
	if (isa(arg1, Array{GMT.GMTdataset,1}))		# TODO. MUST DEBUG TO SEE WHY I HAVE TO DO THIS
		arg1 = arg1[1].data
	end

	if (GMTver >= 6)		# This changed letter between 5 and 6
		cmd = add_opt(cmd, 'E', d, [:E :vectors])
		cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1, arg2)
	else
		cmd = add_opt(cmd, 'C', d, [:C :vectors])
	end
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd *= opt_pen(d, 'W', [:W :pen])

	cmd = finish_PS(d, cmd, output, K, O)
	return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, "psrose", arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
rose!(cmd0::String="", arg1=[]; K=true, O=true,  first=false, kw...) =
	rose(cmd0, arg1; K=K, O=O,  first=first, kw...)

rose(arg1=[], cmd0::String=""; K=false, O=false,  first=true, kw...) =
	rose(cmd0, arg1; K=K, O=O,  first=first, kw...)

rose!(arg1=[], cmd0::String=""; K=true, O=true,  first=false, kw...) =
	rose(cmd0, arg1; K=K, O=O,  first=first, kw...)

psrose  = rose 			# Alias
psrose! = rose!			# Alias