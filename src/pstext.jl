"""
	text(cmd0::String="", arg1=nothing; kwargs...)

Plots text strings of variable size, font type, and orientation. Various map projections are
provided, with the option to draw and annotate the map boundaries.

Full option list at [`pstext`]($(GMTdoc)pstext.html)

Parameters
----------

- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- **A** | **azimuths** :: [Type => Bool]

    Angles are given as azimuths; convert them to directions using the current projection.
    ($(GMTdoc)text.html#a)
- **C** | **clearance** :: [Type => Str]

    Sets the clearance between the text and the surrounding box [15%].
    ($(GMTdoc)text.html#c)
- **D** | **offset** :: [Type => Str]

    Offsets the text from the projected (x,y) point by dx,dy [0/0].
    ($(GMTdoc)text.html#d)
- **F** | **attrib** :: [Type => Str | Tuple]

    Specify up to three text attributes (font, angle, and justification).
    ($(GMTdoc)text.html#f)
- **G** | **fill** :: [Type => Str | Number]

    Sets the shade or color used for filling the text box [Default is no fill].
    ($(GMTdoc)text.html#g)
- $(GMT.opt_Jz)
- **L** | **list** :: [Type => Bool]

    Lists the font-numbers and font-names available, then exits.
    ($(GMTdoc)text.html#l)
- **M** | **paragraph** :: [Type => Str | []]

    Paragraph mode.
    ($(GMTdoc)text.html#m)
- **N** | **no_clip** | **noclip** :: [Type => Str | []]

    Do NOT clip text at map boundaries.
    ($(GMTdoc)text.html#n)
- $(GMT.opt_P)
- **Q** | **change_case** :: [Type => Str]

    Change all text to either lower or upper case.
    ($(GMTdoc)text.html#q)
- **T** | **text_box** :: [Type => Str]

    Specify the shape of the textbox when using G and/or W.
    ($(GMTdoc)text.html#t)
- **W** | **pen** :: [Type => Str]

    Sets the pen used to draw a rectangle around the text string.
    ($(GMTdoc)text.html#w)
- **Z** | **threeD** :: [Type => Str]

    For 3-D projections: expect each item to have its own level given in the 3rd column.
    ($(GMTdoc)text.html#z)
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

    gmt_proggy = (IamModern[1]) ? "text "  : "pstext "
	length(kwargs) == 0 && return monolitic(gmt_proggy, cmd0, arg1)

	N_args = (arg1 === nothing) ? 0 : 1

	d = KW(kwargs)
    K, O = set_KO(first)		# Set the K O dance

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd, = parse_common_opts(d, cmd, [:c :e :f :p :t :JZ :UVXY :params], first)
	cmd  = parse_these_opts(cmd, d, [[:A :azimuths], [:L :list], [:M :paragraph],
	                                 [:N :no_clip :noclip], [:Q :change_case], [:T :text_box], [:Z :threeD]])
	cmd  = add_opt(cmd, 'C', d, [:C :clearance], (margin="#", round="_+tO", concave="_+tc", convex="_+tC"))

	# If file name sent in, read it and compute a tight -R if this was not provided
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)
	if (isa(arg1, Array{<:Number}))
		arg1 = [GMTdataset(arg1, Array{String,1}(), "", Array{String,1}(), "", "")]
	end

	cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color], 'C', N_args, arg1)

	cmd = add_opt(cmd, 'D', d, [:D :offset], (away=("j", nothing, 1), corners=("J", nothing, 1), shift="", line=("+v",add_opt_pen)), true)
	cmd = add_opt(cmd, 'F', d, [:F :attrib],
		(angle="+a", Angle="+A", font=("+f", font), justify="+j", region_justify="+c", header="_+h", label="_+l", rec_number="+r", text="+t", zvalues="+z"), true, true)
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd *= add_opt_pen(d, [:W :pen], "W", true)     # TRUE to also seek (lw,lc,ls)

	if (!occursin(" -F", cmd))		# Test if the GMTdataset has text or if a numeric column is to be used as such
		if ((isa(arg1, GMTdataset) && isempty(arg1.text)) || (isa(arg1, Array{GMT.GMTdataset,1}) && isempty(arg1[1].text)) )
			if (isa(arg1, GMTdataset))  arg1 = [arg1]  end
			for n = 1:length(arg1)
				nr, nc = size(arg1[n].data)
				if (nc < 3)  error("TEXT: input file must have at least three columns")  end
				arg1[n].text = Array{String,1}(undef, nr)
				for k = 1:nr
					arg1[n].text[k] = @sprintf("%.16g", arg1[n].data[k,3])
				end
			end
		end
	end

	r = finish_PS_module(d, gmt_proggy * cmd, "", K, O, true, arg1, arg2)
	gmt("destroy")
	return r
end

# ---------------------------------------------------------------------------------------------------
#function text(arg::DataFrame, cols...; first=true, kw...)
#	arg1 = text_record([arg.cols[1] arg.col[2]], [arg.col[3]])
#	text("", arg1; first=first, kw...)
#end
text!(cmd0::String="", arg1=nothing; first=false, kw...) = text(cmd0, arg1; first=false, kw...)
text(arg1;  first=true, kw...)  = text("", arg1; first=first, kw...)
text!(arg1; first=false, kw...) = text("", arg1; first=first, kw...)

const pstext  = text			# Alias
const pstext! = text!			# Alias