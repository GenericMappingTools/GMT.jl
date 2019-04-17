"""
	text(cmd0::String="", arg1=nothing; kwargs...)

Plots text strings of variable size, font type, and orientation. Various map projections are
provided, with the option to draw and annotate the map boundaries.

Full option list at [`pstext`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html)

Parameters
----------

- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- **A** : **azimuths** : -- Bool or [] --

    Angles are given as azimuths; convert them to directions using the current projection.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#a)
- **C** : **clearance** : -- Str --

    Sets the clearance between the text and the surrounding box [15%].
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#c)
- **D** : **offset** : -- Str --

    Offsets the text from the projected (x,y) point by dx,dy [0/0].
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#d)
- **F** : **attrib** : -- Str or Tuple --

    Specify up to three text attributes (font, angle, and justification).
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#f)
- **G** : **fill** : -- Number or Str --

    Sets the shade or color used for filling the text box [Default is no fill].
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#g)
- $(GMT.opt_Jz)
- **L** : **list** : -- Bool or [] --

    Lists the font-numbers and font-names available, then exits.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#l)
- **N** : **noclip** : **no_clip** : --- Str or [] --

    Do NOT clip text at map boundaries.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#n)
- $(GMT.opt_P)
- **Q** : **change_case** : --- Str --

    Change all text to either lower or upper case.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#q)
- **T** : **text_box** : --- Str --

    Specify the shape of the textbox when using G and/or W.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#t)
- **W** : **line_attribs** : -- Str --

    Sets the pen used to draw a rectangle around the text string.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#w)
- **Z** : **threeD** : -- Str --

    For 3-D projections: expect each item to have its own level given in the 3rd column.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#z)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_a)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_p)
- $(GMT.opt_t)
- $(GMT.opt_swap_xy)
"""
function text(cmd0::String="", arg1=nothing; first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("pstext", cmd0, arg1)

	arg2 = nothing		# May be needed if GMTcpt type is sent in via G
	N_args = isempty_(arg1) ? 0 : 1

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	K, O = set_KO(first)		# Set the K O dance
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_di = parse_di(cmd, d)
	cmd = parse_common_opts(d, cmd, [:e :f :p :t :yx :JZ :UVXY :params])
	cmd = parse_these_opts(cmd, d, [[:A :horizontal], [:C :clearance], [:L :list], [:M :paragraph],
	                 [:N :noclip :no_clip], [:Q :change_case], [:T :text_box], [:Z :threeD]])

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R, "", opt_bi, opt_di)
	cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color], 'C', N_args, arg1, arg2)

	cmd = add_opt(cmd, 'D', d, [:D :offset], (shift="", line="+v", pen=("",add_opt_pen)), true)
	cmd = add_opt(cmd, 'F', d, [:F :attrib],
		(angle="+a", font=("+f", font), justify="+j", region_justify="+c", header="+h", label="+l",
		rec_number="+r", text="+t", zvalues="+z"))
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd *= add_opt_pen(d, [:W :pen], "W")

	cmd = finish_PS(d, cmd, output, K, O)
	r = finish_PS_module(d, "pstext " * cmd, "", output, fname_ext, opt_T, K, arg1, arg2)
	gmt("destroy")
	return r
end

# ---------------------------------------------------------------------------------------------------
text!(cmd0::String="", arg1=nothing; first=false, kw...) = text(cmd0, arg1; first=false, kw...)
text(arg1;  first=true, kw...)  = text("", arg1; first=first, kw...)
text!(arg1; first=false, kw...) = text("", arg1; first=first, kw...)

const pstext  = text			# Alias
const pstext! = text!			# Alias