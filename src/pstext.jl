"""
	text(cmd0::String="", arg1=nothing; kwargs...)

Plots text strings of variable size, font type, and orientation. Various map projections are
provided, with the option to draw and annotate the map boundaries.

See full GMT (not the `GMT.jl` one) docs at [`pstext`]($(GMTdoc)pstext.html)

Parameters
----------

- $(_opt_J)
- $(_opt_R)
- $(_opt_B)
- **A** | **azimuth** | **azim** :: [Type => Bool]

    Angles are given as azimuths; convert them to directions using the current projection.
- **C** | **clearance** :: [Type => Str]

    Sets the clearance between the text and the surrounding box [15%].
- **D** | **offset** :: [Type => Str]

    Offsets the text from the projected (x,y) point by dx,dy [0/0].
- **F** | **attrib** :: [Type => Str | Tuple]

    Specify up to three text attributes (font, angle, and justification).
- **G** | **fill** :: [Type => Str | Number]

    Sets the shade or color used for filling the text box [Default is no fill].
- $(opt_Jz)
- **L** | **list** :: [Type => Bool]

    Lists the font-numbers and font-names available, then exits.
- **M** | **paragraph** :: [Type => Str | []]

    Paragraph mode.
- **N** | **no_clip** | **noclip** :: [Type => Str | []]

    Do NOT clip text at map boundaries.
- $(opt_P)
- **Q** | **change_case** :: [Type => Str]

    Change all text to either lower or upper case.
- **S** | **shade** :: [Type => Str | Tuple | Bool]		``Arg = [dx/dy][/shade]``

    Plot an offset background shaded region beneath the text box (GMT6.2).
- **T** | **text_box** :: [Type => Str]

    Specify the shape of the textbox when using G and/or W.
- **W** | **pen** :: [Type => Str]

    Sets the pen used to draw a rectangle around the text string.
- **Z** | **threeD** :: [Type => Str]

    For 3-D projections: expect each item to have its own level given in the 3rd column.
- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)
- $(opt_a)
- $(_opt_bi)
- $(_opt_di)
- $(opt_e)
- $(_opt_f)
- $(opt_g)
- $(_opt_h)
- $(_opt_p)
- $(_opt_t)
- $(opt_swap_xy)
- $(opt_savefig)

To see the full documentation type: ``@? pstext``
"""
function text(cmd0::String="", arg1=nothing; first=true, kwargs...)

	(find_in_kwargs(kwargs, [:L :list])[1] !== nothing) && return gmt("pstext -L")

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

	parse_paper(d)		# See if user asked to temporarily pass into paper mode coordinates

	if (!isa(arg1, GDtype) && (val = find_in_dict(d, [:text :txt], false)[1]) !== nothing)		# Accept ([x y], text=...)
		if (!haskey(d, :region_justify))	# To accept also text="Bla", region_justify=?? i.e. without x=?, y=?
			arg1 = (!haskey(d, :x) && isa(arg1, Matrix) || isvector(arg1)) ? mat2ds(arg1, [string(val)]) : parse_xy(d, val)
			delete!(d, [[:text, :txt], [:region_justify]])
		end
	elseif (cmd0 != "" && !isfile(cmd0) && (cmd0[1] != '@' || cmd0[1] == '@' && !isletter(cmd0[2])))	# To accept text("BlaBla", x=?, y=?, ...)
		arg1 = parse_xy(d, cmd0)
		cmd0 = ""
	end

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX" * split(DEF_FIG_SIZE, '/')[1] * "/0")
	_is3D = (isa(arg1, GDtype) && getsize(arg1)[2] == 3)		# But this does not check the reading file path
	cmd, = parse_common_opts(d, cmd, [:a :e :f :p :t :w :JZ :UVXY :params]; first=first, is3D=_is3D)
	cmd  = parse_these_opts(cmd, d, [[:A :azimuths :azimuth :azim], [:M :paragraph], [:N :no_clip :noclip],
	                                 [:Q :change_case], [:S :shade], [:T :text_box], [:Z :threeD]])
	cmd  = add_opt(d, cmd, "C", [:C :clearance], (margin="#", round="_+tO", concave="_+tc", convex="_+tC"))

	# If file name sent in, read it and compute a tight -R if this was not provided
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)
	contains(opt_R, "NaN") && error("Text element has no coordinates. So you cannot show it in the first command.")

	(isa(arg1, AbstractString) || isa(arg1, Vector{<:AbstractString})) && (arg1 = parse_xy(d, arg1))	# See if x=.., y=..
	if (isa(arg1, Array{<:Real}))
		arg1 = [GMTdataset(arg1, Float64[], Float64[], DictSvS(), String[], String[], "", String[], "", "", 0, 0)]
	end

	cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, [:C :color], 'C', N_args, arg1)

	cmd = add_opt(d, cmd, "D", [:D :offset], (away=("j", nothing, 1), corners=("J", nothing, 1), shift="", line=("+v",add_opt_pen)), true)
	opt_F = add_opt(d, "", "F", [:F :attrib],
		(angle="+a", Angle="+A", font=("+f", font), justify="+j", region_justify="+c", header="_+h", label="_+l", rec_number="_+r", text="+t", zvalues="_+z"), true, true)
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	contains(cmd, " -G") && (CTRL.pocket_B[3] = ".")	# Signal gmt() that it needs to restart because the fill f the API
	cmd *= add_opt_pen(d, [:W :pen], "W")

	if (!occursin(" -F", cmd))		# Test if the GMTdataset has text or if a numeric column is to be used as such
		if ((isa(arg1, GMTdataset) && isempty(arg1.text)) || (isa(arg1, Vector{<:GMTdataset}) && isempty(arg1[1].text)) )
			(isa(arg1, GMTdataset)) && (arg1 = [arg1])
			for n = 1:lastindex(arg1)
				nr, nc = size(arg1[n].data)
				(nc < 3) && error("TEXT: input file must have at least three columns")
				arg1[n].text = Array{String,1}(undef, nr)
				for k = 1:nr
					arg1[n].text[k] = @sprintf("%.16g", arg1[n].data[k,3])
				end
			end
		end
	end

	# Didn't find this from the GMT manual, but trials showd that the (almost) documented first form:
	# echo 1 13 black=~3p,green blue | gmt text -R0/18/0/15 -Jx1c -B5g1 -BWSne --FONT=28p,Helvetica-Bold -F+f+jBL -png lixo
	# is equivalent to this second form and avoids the use of the "--FONT" mechanism.
	# echo 1 13 28p,Helvetica-Bold,black=~3p,green blue | gmt text -R0/18/0/15 -Jx1c -B5g1 -BWSne  -F+f+jBL -png lixo
	# But it requires quite a bit of gymnastics moving around the pen,font settings.
	if ((val = find_in_dict(d, [:outline])[1]) !== nothing)
		outline::String = (val == 1) ? "1p,white" : string(val)
		if (opt_F == "")
			opt_F = " -F+f"
			outline = "black=~" * outline * " "
		else
			if ((ind = findfirst("+f", opt_F)) !== nothing)
				if ((s = split(split(opt_F, "+f")[2], '+')[1]) != "")	# Example: split(split("-F+f28p,Times", "+f")[2], '+')[1] = "28p,Times"
					opt_F = replace(opt_F, s => "")						# Remove the old font specification from -F
					t_color = (count_chars(s, ',') <= 1) ? ",black=~" : "=~"
					outline = s * t_color * outline * " "				# Example: 28p,Times,black=~3p,green
				end
			else
				opt_F *= "+f"
			end
		end
		for n = 1:size(arg1.data, 1)
			arg1.text[n] = outline * arg1.text[n]
		end
	end
	(opt_F != "") && (cmd *= opt_F)						# Needed, whether or not 'outline' is used

	_cmd = [gmt_proggy * cmd]
	_cmd = frame_opaque(_cmd, gmt_proggy, opt_B, opt_R, opt_J)		# No -t in frame
	r = finish_PS_module(d, _cmd, "", K, O, true, arg1, arg2)
	if (isa(r, String) && startswith(r, gmt_proggy))	# It's a string when called with Vd = 2 and it may be a nested call
		isa(arg1, GDtype) && (CTRL.pocket_call[1] = arg1)
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

# ---------------------------------------------------------------------------------------------------
export rich, subscript, superscript, underline, smallcaps, greek, mathtex
subscript(arg)   = string("@-", arg, "@-")
superscript(arg) = string("@+", arg, "@+")
underline(arg)   = string("@_", arg, "@_")
smallcaps(arg)   = string("@#", arg, "@#")
greek(arg)       = string("@~", arg, "@~")
mathtex(arg)     = string("@[", arg, "@[")
function rich(args...; kwargs...)
	# rich("H", subscript("2"), greek("O")," is the ", smallcaps("formula")," for ", rich(underline("water"), color=:red, font="Helvetica", size=16))
	tx, close = "", String[]
	for arg in args
		tx *= arg
	end
	for kw in kwargs
		if     (kw[1] == :color)  tx = string("@;", kw[2], ";", tx);	append!(close, ["@;;"])
		elseif (kw[1] == :size)   tx = string("@:", kw[2], ":", tx);	append!(close, ["@::"])
		elseif (kw[1] == :font)   tx = string("@%", kw[2], "%", tx);	append!(close, ["@%%"])
		end
	end
	!isempty(close) && (for k = 1:numel(close)  tx *= close[k]  end)
	tx
end

const pstext  = text			# Alias
const pstext! = text!			# Alias