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
- **S** | **shade** :: [Type => Str | Tuple | Bool]		``Arg = [dx/dy][/shade]``

    Plot an offset background shaded region beneath the text box (GMT6.2).
    ($(GMTdoc)text.html#s)
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
- $(GMT.opt_savefig)
"""
function text(cmd0::String="", arg1=nothing; first=true, kwargs...)

    gmt_proggy = (IamModern[1]) ? "text " : "pstext "

	N_args = (arg1 === nothing) ? 0 : 1
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	function parse_xy(d, arg)
		# Deal with cases (txt="Bla", x=0.5, y=0.5) or (data="Bla", x=0.5, y=0.5)
		((x = find_in_dict(d, [:x])[1]) === nothing) &&
			error("When the 'text' keyword is used, must provide coordinates in either a x matrix or two x,y vectors.")
		(((y = find_in_dict(d, [:y])[1]) === nothing) && size(x,2) == 1) &&
			error("When Y is not transmitted, X must be a Matrix.")
		!isa(arg, AbstractString) && !isa(arg, Symbol) && !isa(arg, Vector{<:AbstractString}) &&
			error("The 'text' option must be a text or a Symbol but was $(typeof(arg))")

		if (isa(arg, AbstractString) || isa(arg, Symbol))
			arg1 = (y === nothing) ? text_record(x, [string(arg)]) : text_record(length(x) == 1 ? [x y] : hcat(x[:],y[:]), [string(arg)])
		else
			arg1 = (y === nothing) ? text_record(x, arg) : text_record(length(x) == 1 ? [x y] : hcat(x[:],y[:]), arg)
		end
		arg1
	end

	if (!isa(arg1, GDtype) && (val = find_in_dict(d, [:text :txt])[1]) !== nothing)
		arg1 = parse_xy(d, val)
	end

	cmd, _, _, opt_R = parse_BJR(d, "", "", O, " -JX" * split(def_fig_size, '/')[1] * "/0")
	cmd, = parse_common_opts(d, cmd, [:c :e :f :p :t :JZ :UVXY :params], first)
	cmd  = parse_these_opts(cmd, d, [[:A :azimuths], [:L :list], [:M :paragraph],
	                                 [:N :no_clip :noclip], [:Q :change_case], [:S :shade], [:T :text_box], [:Z :threeD]])
	cmd  = add_opt(d, cmd, "C", [:C :clearance], (margin="#", round="_+tO", concave="_+tc", convex="_+tC"))

	# If file name sent in, read it and compute a tight -R if this was not provided
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)
	(isa(arg1, AbstractString) || isa(arg1, Vector{<:AbstractString})) && (arg1 = parse_xy(d, arg1))	# See if x=.., y=..
	if (isa(arg1, Array{<:Real}))
		arg1 = [GMTdataset(arg1, Float64[], Float64[], Dict{String, String}(), String[], String[], "", String[], "", "", 0)]
	end

	cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color], 'C', N_args, arg1)

	cmd = add_opt(d, cmd, "D", [:D :offset], (away=("j", nothing, 1), corners=("J", nothing, 1), shift="", line=("+v",add_opt_pen)), true)
	cmd = add_opt(d, cmd, "F", [:F :attrib],
		(angle="+a", Angle="+A", font=("+f", font), justify="+j", region_justify="+c", header="_+h", label="_+l", rec_number="_+r", text="+t", zvalues="_+z"), true, true)
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd *= add_opt_pen(d, [:W :pen], "W", true)     # TRUE to also seek (lw,lc,ls)

	if (!occursin(" -F", cmd))		# Test if the GMTdataset has text or if a numeric column is to be used as such
		if ((isa(arg1, GMTdataset) && isempty(arg1.text)) || (isa(arg1, Vector{<:GMTdataset}) && isempty(arg1[1].text)) )
			(isa(arg1, GMTdataset)) && (arg1 = [arg1])
			for n = 1:length(arg1)
				nr, nc = size(arg1[n].data)
				(nc < 3) && error("TEXT: input file must have at least three columns")
				arg1[n].text = Array{String,1}(undef, nr)
				for k = 1:nr
					arg1[n].text[k] = @sprintf("%.16g", arg1[n].data[k,3])
				end
			end
		end
	end

	r = finish_PS_module(d, gmt_proggy * cmd, "", K, O, true, arg1, arg2)
	if (isa(r, String) && startswith(r, gmt_proggy))	# It's a string when called with Vd = 2 and it may be a nested call
		isa(arg1, GDtype) && (CTRL.pocket_call[1] = arg1)	# No need to call gmt_restart() because pstext was not executed yet
	else
		gmt_restart()
	end
	return r
end

# ---------------------------------------------------------------------------------------------------
text!(cmd0::String="", arg1=nothing; kw...) = text(cmd0, arg1; first=false, kw...)
text(arg1;  kw...) = text("", arg1; first=true, kw...)
text!(arg1; kw...) = text("", arg1; first=false, kw...)

# ---------------------------------------------------------------------------------------------------
function text(txt::Vector{String}; x=nothing, y=nothing, first=true, kwargs...)
	# Versions to allow calling 
	(x === nothing) && error("Must provide coordinates in either a x matrix or two x,y vectors.")
	(length(txt) != length(x)) && error("Number of TEXT lines and coordinates must be the same,")
	(y === nothing && size(x,2) == 1) && error("When Y is not transmitted, X must be a Matrix.")
	D = (y === nothing) ? text_record(x, txt) : text_record(length(x) == 1 ? [x y] : hcat(x[:],y[:]), txt)
	text("", D; first=first, kwargs...)
end
text!(txt::Vector{String}; x=nothing, y=nothing, kw...) = text(txt; x=x, y=y, first=false, kw...)

#= ---------------------------------------------------------------------------------------------------
function text(; text::Union{AbstractString, Vector{AbstractString}}="", x=nothing, y=nothing, first=true, kw...)
	(isempty(text)) && error("Must provide the plotting text via the 'text' keyword or use another method.")
	isa(text, String) ? text([text]; x=x, y=y, first=first, kw...) : text(text; x=x, y=y, first=first, kw...)
end
text!(; text::Union{AbstractString, Vector{AbstractString}}="", x=nothing, y=nothing, kw...) =
	text(; text=text, x=x, y=y, first=false, kw...)
=#

const pstext  = text			# Alias
const pstext! = text!			# Alias