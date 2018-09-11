"""
	text(cmd0::String="", arg1=[]; kwargs...)

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
- **F** : **text_attrib** : -- Str or number --

    Specify up to three text attributes (font, angle, and justification).
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#f)
- **G** : **fill** : -- Number or Str --

    Sets the shade or color used for filling the text box [Default is no fill].
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#g)
- $(GMT.opt_Jz)
- **L** : **list** : -- Bool or [] --

    Lists the font-numbers and font-names available, then exits.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#l)
- **N** : **no_clip** : --- Str or [] --

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
function text(cmd0::String="", arg1=[]; caller=[], K=false, O=false, first=true, kwargs...)

	arg2 = []		# May be needed if GMTcpt type is sent in via G
	N_args = isempty_(arg1) ? 0 : 1

	length(kwargs) == 0 && return monolitic("pstext", cmd0, arg1)	# Speedy mode

    d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

    cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", caller, O, " -JX12c/0")
	cmd = parse_JZ(cmd, d)
	cmd = parse_UVXY(cmd, d)
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_di = parse_di(cmd, d)
	cmd, = parse_e(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, = parse_p(cmd, d)
	cmd, = parse_t(cmd, d)
	cmd = parse_params(cmd, d)

    cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, opt_i = read_data(d, cmd0, cmd, arg1, opt_R, "", opt_bi, opt_di)

	cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color], 'C', N_args, arg1, arg2)

	cmd = add_opt(cmd, 'A', d, [:A :horizontal])
	cmd = add_opt(cmd, 'D', d, [:D :annot :annotate])
	cmd = add_opt(cmd, 'F', d, [:F :text_attrib])
    cmd = add_opt(cmd, 'G', d, [:G :fill])
	cmd = add_opt(cmd, 'I', d, [:I :inquire])
	cmd = add_opt(cmd, 'L', d, [:L :pen])
	cmd = add_opt(cmd, 'N', d, [:N :no_clip])
	cmd = add_opt(cmd, 'Q', d, [:Q :change_case])
	cmd = add_opt(cmd, 'T', d, [:T :text_box])
	cmd = add_opt(cmd, 'Z', d, [:Z :threeD])

	opt_W = ""
	pen = build_pen(d)						# Either a full pen string or empty ("")
	if (!isempty(pen))
		opt_W = " -W" * pen
	else
		for sym in [:W :line_attrib]
			if (haskey(d, sym))
				if (isa(d[sym], String))
					opt_W = " -W" * arg2str(d[sym])
				elseif (isa(d[sym], Tuple))	# Like this it can hold the pen, not extended atts
					opt_W = " -W" * parse_pen(d[sym])
				else
					error("Nonsense in W option")
				end
				break
			end
		end
	end

	if (!isempty(opt_W)) 		# We have a rectangle request
		cmd = finish_PS(d, cmd * opt_W, output, K, O)
	else
		cmd = finish_PS(d, cmd, output, K, O)
	end

    return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, "pstext", arg1, arg2, [], [], [], [])
end

# ---------------------------------------------------------------------------------------------------
text!(cmd0::String="", arg1=[]; caller=[], K=true, O=true,  first=false, kw...) =
    text(cmd0, arg1; caller=caller, K=K, O=O,  first=false, kw...)

text(arg1=[]; caller=[], K=false, O=false, first=true, kw...) =
    text("", arg1; caller=caller, K=K, O=O, first=first, kw...)

text!(arg1=[]; caller=[],  K=true, O=true, first=false, kw...) =
    text("", arg1; caller=caller, K=K, O=O, first=first, kw...)

pstext  = text			# Alias
pstext! = text!			# Alias