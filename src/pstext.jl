"""
	text(cmd0::String="", arg1=nothing; kwargs...)

Plots text strings of variable size, font type, and orientation. Various map projections are
provided, with the option to draw and annotate the map boundaries.

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

- $(opt_savefig)

To see the full documentation type: ``@? pstext``
"""
function text(cmd0::String="", arg1=nothing; first=true, kwargs...)
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode
	_text(wrapDatasets(cmd0, arg1), isa(arg1, Matrix), O, K, d)
end
function text(arg1::Matrix{<:Real}, text::Vector{<:AbstractString}; first=true, kwargs...)
	# Method to allow calling text(Mat, ["A", "B", "C"])
	size(arg1,1) != length(text) && error("Number of text elements and coordinates must be the same,")
	d, K, O = init_module(first, kwargs...)
	D = mat2ds(Float64.(arg1), text)
	_text(wrapDatasets("", D), false, O, K, d)
end
function _text(w::wrapDatasets, ismatrix::Bool, O::Bool, K::Bool, d::Dict{Symbol,Any})
	cmd0, arg1 = unwrapDatasets(w::wrapDatasets)
	ismatrix && (arg1 = arg1.data)		# If the user sent in a Matrix, we need to extract the data for the text record (see Line 102)

	(is_in_dict(d, [:L :list]) !== nothing) && return gmt("pstext -L")

	gmt_proggy = (IamModern[]) ? "text " : "pstext "

	arg3 = nothing			# May be needed if a text position is passed in via -D
	N_args = (arg1 === nothing) ? 0 : 1
	first = !O

	function parse_xy(d::Dict{Symbol,Any}, arg)
		# Deal with cases (txt="Bla", x=0.5, y=0.5) or (data="Bla", x=0.5, y=0.5)
		((x = find_in_dict(d, [:x])[1]) === nothing) &&
			error("When the 'text' keyword is used, must provide coordinates in either a x matrix or two x,y vectors.")
		(((y = find_in_dict(d, [:y])[1]) === nothing) && size(x,2) == 1) &&
			error("When Y is not transmitted, X must be a Matrix.")
		!isa(arg, AbstractString) && !isa(arg, Symbol) && !isa(arg, Vector{<:AbstractString}) &&
			error("The 'text' option must be a text or a Symbol but was $(typeof(arg))")

		if (isa(arg, AbstractString) || isa(arg, Symbol))
			_arg1 = (y === nothing) ? text_record(x, [string(arg)]) : text_record(length(x) == 1 ? [x y] : hcat(x[:],y[:]), [string(arg)])
		else
			_arg1 = (y === nothing) ? text_record(x, arg) : text_record(length(x) == 1 ? [x y] : hcat(x[:],y[:]), arg)
		end
		_arg1
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
	cmd, = parse_common_opts(d, cmd, [:a :e :f :p :t :w :JZ :UVXY :margin :params]; first=first, is3D=_is3D)
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

	# Deal with the -D option
	if ((symb = is_in_dict(d, [:D :offset])) !== nothing && (isa(d[symb], AbstractArray)))	# See if a text positions was passed via Matrix/DS
		vpen = pop!(d, :leader, nothing)	# Optional leader-line pen set by annotate(); avoids build_pen's :line intercept
		cmd *= (vpen !== nothing) ? " -D+f+v$(vpen)" : " -D+f"
		fpos::GMTdataset = mat2ds(d[symb])
		delete!(d, symb)
		(N_args == 0) ? arg1 = fpos : (N_args == 1) ? arg2 = fpos : arg3 = fpos
	end

	opt_D = add_opt(d, "", "D", [:D :offset], (away=("j", nothing, 1), corners=("J", nothing, 1), shift="", line=("+v",add_opt_pen), offsets=("+f",parse_Df)))
	if ((ind = findfirst("+f", opt_D)) !== nothing)
		if (opt_D[ind[1]+2] == '?')
			opt_D = replace(opt_D, "+f?" => "+f")
			fpos = mat2ds(CTRL.pocket_d[1][:offsets]);		CTRL.pocket_d[1] = Dict{String, Any}()	# :offsets comes from the add_opt() above
			(N_args == 0) ? arg1 = fpos : (N_args == 1) ? arg2 = fpos : arg3 = fpos
		end
	end
	cmd *= opt_D

	opt_F = add_opt(d, "", "F", [:F :attrib],
		(angle="+a", Angle="+A", font=("+f", font), justify="+j", region_justify="+c", header="_+h", label="_+l", rec_number="_+r", text="+t", zvalues="_+z"); expand=true)
	(((justify = pop!(d, :justify, "")) !== "") && (!contains(opt_F, "+j"))) && (opt_F *= string("+j", justify))	# To allow justify=?? when font=?? was also set (annotate)

	cmd = add_opt_fill(cmd, d, [:G :fill], "G")
	contains(cmd, " -G") && (CTRL.pocket_B[3] = ".")	# Signal gmt() that it needs to restart because the fill f the API
	cmd *= add_opt_pen(d, [:W :pen], opt="W")

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
	if ((val_s = hlp_desnany_str(d, [:outline])) !== "")
		outline = (val_s == "1") ? "1p,white" : val_s
		if (opt_F == "")
			opt_F = " -F+f"
			outline = "black=~" * outline * " "
		else
			if (findfirst("+f", opt_F) !== nothing)
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
	if ((r = check_dbg_print_cmd(d, _cmd)) !== nothing)
		isa(arg1, GDtype) && (pocket_call[][1] = arg1)	# For the case this is a nested call
		return r
	end
	prep_and_call_finish_PS_module(d, _cmd, "", K, O, true, arg1, arg2, arg3)
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

function parse_Df(d::Dict{Symbol, Any}, s::Vector{Symbol})
	arg = d[s[1]]		# s is a vector with only one element
	isa(arg, String) && return arg
	if (isa(arg, AbstractArray))
		CTRL.pocket_d[1] = d			# Store the offsets array in this 'd'. A hack but we don't have a global pocket
		return "?"
	end
	error("Bad arguments type")
end

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

# ---------------------------------------------------------------------------------------------------
"""
    annotate(labels, points; kwargs...)
    annotate!(labels, points; kwargs...)

Add annotated text labels to a plot, optionally connected to data points by leader lines.
Similar in spirit to Makie's `annotation` and matplotlib's `annotate`.

### Positional Arguments
- `labels`: `Vector{String}` with annotation text, one per point.
- `points`: `Nx2` matrix or `GMTdataset` with `(x, y)` anchor coordinates.

### Keyword Arguments
- `text_pos`: `Nx2` matrix or `GMTdataset` with explicit label positions in **data coordinates**.
  When provided, labels are placed here and leader lines connect them back to `points`.
  When omitted (and `offsets` is also omitted), positions are computed automatically via `textrepel`.
- `offsets`: `Nx2` matrix of per-label displacements in **cm** from each anchor point.
  Uses GMT's `-D+f` per-record offset mechanism. When omitted (together with `text_pos`),
  offsets are computed automatically by `textrepel` with `offsets=true`.
- `arrowprops`: Controls the arrow drawn from each anchor to its label. `false` (default) —
  no arrow. `true` — draws a default arrow (`pen=1, arrow=(len=0.6,stop=true), fill=:black`).
  A `NamedTuple` with any kwargs accepted by `arrows!()` — custom arrow.
- `justify`: GMT justification code (default `"CM"`).
- `leader`: pen string for a thin GMT leader line (`-D+f+v<pen>`) drawn instead of, or in
  addition to, the arrow. E.g. `leader="0.5p,gray"`.
- `nobox`: If `true`, render the label with fill only — no box border is drawn and clearance
  is forced to `"0p"` so the fill hugs the text. Useful for clean map labels with a coloured
  background but no visible rectangle.
- `nofill`: If `true`, render the label as plain text with no box and no background fill.
- `fontsize`: Font size in points for `textrepel` bounding-box estimation (default 10).
  Use `font="12p,Helvetica"` (or `F=(font=...)`) to control the rendered font.
- `force_push`, `force_pull`, `max_iter`, `pad`, `min_offset`: `textrepel` tuning
  parameters (used only when neither `text_pos` nor `offsets` is given).
- Remaining kwargs are forwarded to `text()`.
"""
function annotate(points::Union{Matrix{<:Real}, GMTdataset}, labels::Vector{<:AbstractString}; first=true, kwargs...)
	isa(points, Matrix) && (points = mat2ds(points))
	_annotate(points, labels, first, KW(kwargs))
end
annotate!(points::Union{Matrix{<:Real}, GMTdataset}, labels::Vector{<:AbstractString}; kw...) =
	annotate(points, labels; first=false, kw...)

function _annotate(points::GMTdataset, labels::Vector{<:AbstractString}, first::Bool, d::Dict{Symbol,Any})
	Vd         = pop!(d, :Vd, 0)
	text_pos   = pop!(d, :text_pos, nothing)
	offs       = pop!(d, :offsets, nothing)
	arrowprops = pop!(d, :arrowprops, false)	# false=no arrow (default); true=default arrow; NT=custom arrow
	leader     = pop!(d, :leader, nothing)		# pen for the -D+f+v thin leader line (no arrowhead)
	justify    = pop!(d, :justify, "CM")
	fontsize   = pop!(d, :fontsize, 10)
	force_push = pop!(d, :force_push, 1.0)
	force_pull = pop!(d, :force_pull, 0.01)
	max_iter   = pop!(d, :max_iter, 500)
	pad        = pop!(d, :pad, 0.15)
	min_off    = pop!(d, :min_offset, 10)
	nobox      = pop!(d, :nobox, false)		# fill only, no box border, clearance=0
	nofill     = pop!(d, :nofill, false)	# no box, no fill — plain text

	if nofill
		delete!(d, :fill);  delete!(d, :pen)
	elseif nobox
		delete!(d, :pen)
		!haskey(d, :fill) && (d[:fill] = :white)	# default fill when nobox and user didn't specify one
		!haskey(d, :clearance) && (d[:clearance] = "0p")
	end

	n = size(points, 1)
	length(labels) != n && error("Number of labels ($(length(labels))) must match number of points ($n)")
	(leader !== nothing) && (d[:leader] = leader)
	do_show, fmt, savefig = get_show_fmt_savefig(d, false)

	pts_text = points.text				# Bak it up
	points.text = labels				# Temporarily store the labels in the .text field of the points dataset for use by text()
	if (text_pos !== nothing)			# ── Case A: explicit positions in data coordinates ─────────────────────
		tdata = isa(text_pos, GMTdataset) ? text_pos.data : text_pos
		r = text(points; first=first, justify=justify, Vd=Vd, d...)
		points.text = pts_text
		isa(r, String) && return r		# For tests purpose
		if (arrowprops !== false)
			edge_xy = _annotate_txt_xy_from_center(points, labels, tdata[:,1:2], fontsize, Float64(pad))
			D_arr = mat2ds(hcat(edge_xy, points.data[:,1:2]))
			_annotate_arrows!(D_arr, arrowprops, Vd)
		end
	else								# ── Case B: offset-based (auto via textrepel or caller-supplied) ────────
		if (offs === nothing)
			offs = textrepel(points, labels; fontsize=fontsize, force_push=force_push, force_pull=force_pull,
			                 max_iter=max_iter, pad=pad, offset=min_off, offsets=true)
		end
		r = text(points; first=first, justify=justify, D=offs, Vd=Vd, d...)
		points.text = pts_text
		isa(r, String) && return r		# For tests purpose
		if (arrowprops !== false)
			txy = _annotate_txt_xy(points, labels, offs, fontsize, Float64(pad))
			D_arr = mat2ds(hcat(txy, points.data[:,1:2]))
			_annotate_arrows!(D_arr, arrowprops, Vd)
		end
	end
	(do_show || fmt !== "" || savefig !== "") && showfig(show=do_show, fmt=fmt, savefig=savefig)
end

function _annotate_arrows!(D_arr, arrowprops, Vd)
	if (arrowprops === true || arrowprops === nothing)
		arrows!(D_arr; pen=1, arrow=(len=0.6, stop=true), fill=:black, endpt=true, Vd=Vd)
	elseif isa(arrowprops, NamedTuple)
		arrows!(D_arr; endpt=true, Vd=Vd, pairs(arrowprops)...)
	end
end

function _annotate_txt_xy_from_center(points::GMTdataset, labels::Vector{<:AbstractString}, centers::Matrix{Float64}, fontsize::Int, pad::Float64)
	# Like _annotate_txt_xy but accepts already-computed text centers in data coords (Case A).
	fs = fontsize * 2.54 / 72
	pw, ph = _get_plotsize()
	lims = (CTRL.limits[7] != 0 || CTRL.limits[8] != 0) ?
	       (CTRL.limits[7], CTRL.limits[8], CTRL.limits[9], CTRL.limits[10]) :
	       (CTRL.limits[1] != CTRL.limits[2]) ?
	       (CTRL.limits[1], CTRL.limits[2], CTRL.limits[3], CTRL.limits[4]) :
	       (points.bbox[1], points.bbox[2], points.bbox[3], points.bbox[4])
	dx = lims[2] - lims[1];  dy = lims[4] - lims[3]
	(dx == 0.0) && (dx = 1.0);  (dy == 0.0) && (dy = 1.0)
	sx = dx / pw;  sy = dy / ph
	mat = Matrix{Float64}(undef, size(points, 1), 2)
	for i in 1:size(points, 1)
		cx = centers[i,1];  cy = centers[i,2]
		ax = points.data[i,1];  ay = points.data[i,2]
		ddx = ax - cx;  ddy = ay - cy
		dist = hypot(ddx, ddy)
		if dist < 1e-10;  mat[i,1] = cx;  mat[i,2] = cy;  continue;  end
		ux = ddx/dist;  uy = ddy/dist
		hw = (length(labels[i]) * 0.55 * fs / 2 + pad) * sx
		hh = (fs / 2 + pad) * sy
		t = min(abs(ux) > 1e-10 ? hw/abs(ux) : Inf, abs(uy) > 1e-10 ? hh/abs(uy) : Inf)
		mat[i,1] = cx + t * ux;  mat[i,2] = cy + t * uy
	end
	return mat
end

function _annotate_txt_xy(points::GMTdataset, labels::Vector{<:AbstractString}, offs, fontsize::Int, pad::Float64)
	# Return the point on the text-box edge nearest to the anchor, in data coordinates.
	# Using the box edge (not the center) ensures the arrow starts visually at the box boundary.
	pw, ph = _get_plotsize()
	lims = (CTRL.limits[7] != 0 || CTRL.limits[8] != 0) ?
	       (CTRL.limits[7], CTRL.limits[8], CTRL.limits[9], CTRL.limits[10]) :
	       (CTRL.limits[1] != CTRL.limits[2]) ?
	       (CTRL.limits[1], CTRL.limits[2], CTRL.limits[3], CTRL.limits[4]) :
	       (points.bbox[1], points.bbox[2], points.bbox[3], points.bbox[4])
	dx = lims[2] - lims[1];  dy = lims[4] - lims[3]
	(dx == 0.0) && (dx = 1.0);  (dy == 0.0) && (dy = 1.0)
	sx = dx / pw;  sy = dy / ph    # data per cm
	fs = fontsize * 2.54 / 72      # cm
	mat = Matrix{Float64}(undef, size(points, 1), 2)
	for i in 1:size(points, 1)
		ax = points.data[i,1];  ay = points.data[i,2]     # anchor (data coords)
		cx = ax + offs[i,1] * sx;  cy = ay + offs[i,2] * sy   # text center (data coords)
		ddx = ax - cx;  ddy = ay - cy                          # vector: text center → anchor
		dist = hypot(ddx, ddy)
		if dist < 1e-10        # label on top of anchor: return center as-is
			mat[i,1] = cx;  mat[i,2] = cy;  continue
		end
		ux = ddx / dist;  uy = ddy / dist
		hw = (length(labels[i]) * 0.55 * fs / 2 + pad) * sx   # box half-width in data units
		hh = (fs / 2 + pad) * sy                               # box half-height in data units
		t = min(abs(ux) > 1e-10 ? hw / abs(ux) : Inf,
		        abs(uy) > 1e-10 ? hh / abs(uy) : Inf)          # distance to box edge in direction (ux,uy)
		mat[i,1] = cx + t * ux
		mat[i,2] = cy + t * uy
	end
	return mat
end
