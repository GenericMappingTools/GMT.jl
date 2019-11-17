"""
	grdcontour(cmd0::String="", arg1=nothing; kwargs...)

Reads a 2-D grid file or a GMTgrid type and produces a contour map by tracing each
contour through the grid.

Full option list at [`grdcontour`]($(GMTdoc)grdcontour.html)

Parameters
----------

- $(GMT.opt_J)
- **A** | **annot** :: [Type => Str or Number]       ``Arg = [-|[+]annot_int][labelinfo]``

    *annot_int* is annotation interval in data units; it is ignored if contour levels are given in a file.
    ($(GMTdoc)grdcontour.html#a)
- $(GMT.opt_B)
- **C** | **cont** | **contours** | **levels** :: [Type => Str or Number]

    Contours to be drawn.
    ($(GMTdoc)grdcontour.html#c)
- **D** | **dump** :: [Type => Str]

    Dump contours as data line segments; no plotting takes place.
    ($(GMTdoc)grdcontour.html#d)
- **F** | **force** :: [Type => Str | []]

    Force dumped contours to be oriented so that higher z-values are to the left (-Fl [Default]) or right.
    ($(GMTdoc)grdcontour.html#f)
- **G** | **labels** :: [Type => Str]

    Controls the placement of labels along the quoted lines.
    ($(GMTdoc)grdcontour.html#g)
- $(GMT.opt_Jz)
- **L** | **range** :: [Type => Str]

    Limit range: Do not draw contours for data values below low or above high.
    ($(GMTdoc)grdcontour.html#l)
- **N** | **fill** | **colorize** :: [Type => Bool]

    Fill the area between contours using the discrete color table given by cpt.
    ($(GMTdoc)grdcontour.html#n)
- $(GMT.opt_P)
- **Q** | **cut** :: [Type => Str | Number]

    Do not draw contours with less than cut number of points.
    ($(GMTdoc)grdcontour.html#q)
- **S** | **smooth** :: [Type => Number]

    Used to resample the contour lines at roughly every (gridbox_size/smoothfactor) interval.
    ($(GMTdoc)grdcontour.html#s)
- **T** | **ticks** :: [Type => Str]

    Draw tick marks pointing in the downward direction every *gap* along the innermost closed contours.
    ($(GMTdoc)grdcontour.html#t)
- $(GMT.opt_R)
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** | **pen** :: [Type => Str | Number]

    Sets the attributes for the particular line.
    ($(GMTdoc)grdcontour.html#w)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- **Z** | **scale** :: [Type => Str]

    Use to subtract shift from the data and multiply the results by factor before contouring starts.
    ($(GMTdoc)grdcontour.html#z)
- $(GMT.opt_bo)
- $(GMT.opt_do)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_p)
- $(GMT.opt_t)
"""
function grdcontour(cmd0::String="", arg1=nothing; first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("grdcontour", cmd0, arg1)
	arg2 = nothing

	d = KW(kwargs)
    K, O = set_KO(first)		# Set the K O dance

	cmd, opt_B, = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd = parse_common_opts(d, cmd, [:UVXY :params :bo :e :f :h :p :t], first)
	cmd = parse_these_opts(cmd, d, [[:D :dump], [:F :force], [:L :range], [:Q :cut], [:S :smooth]])
	cmd = parse_contour_AGTW(d::Dict, cmd::String)
	cmd = add_opt(cmd, 'Z', d, [:Z :scale], (factor="+s", shift="+o", periodic="_+p"))

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)	# Find how data was transmitted
	if (isa(arg1, Array{<:Number}))		arg1 = mat2grid(arg1)	end

	#N_used = got_fname == 0 ? 1 : 0		# To know whether a cpt will go to arg1 or arg2
	#cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_used, arg1, arg2)
	cmd, N_used, arg1, arg2, = get_cpt_set_R(d, cmd0, cmd, opt_R, got_fname, arg1, arg2, nothing, "grdcontour")

	if (!occursin(" -C", cmd))			# Otherwise ignore an eventual :cont because we already have it
		cmd = add_opt(cmd, 'C', d, [:C :cont :contours :levels])
	end

	if ((val = find_in_dict(d, [:N :fill :colorize])[1]) !== nothing)
		if (isa(val, GMTcpt))
			if (!isempty_(arg2))	# Already have one cpt in arg2, replace it by new one
				arg2 = nothing
			end
			cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:N :fill], 'N', N_used, arg1, arg2)
		else
			cmd *= " -N"
		end
	end

	opt_extra = "";		do_finish = true
	if (occursin("-D", cmd))
		opt_extra = "-D";		do_finish = false;	cmd = replace(cmd, opt_J => "")
	end
    return finish_PS_module(d, "grdcontour " * cmd, opt_extra, K, O, do_finish, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
function parse_contour_AGTW(d::Dict, cmd::String)
	# Common to both grd and ps contour
	cmd = add_opt(cmd, 'A', d, [:A :annot], (disable=("-", nothing, 1), single=("+", nothing, 1),
	                                         int="", interval="", labels=("", parse_quoted)) )
	cmd = add_opt(cmd, 'G', d, [:G :labels], ("", helper_decorated))
	cmd = add_opt(cmd, 'T', d, [:T :ticks], (local_high=("h", nothing, 1), local_low=("l", nothing, 1),
	                                         labels="+l", closed="_+a", gap="+d") )
	cmd = add_opt(cmd, 'W', d, [:W :pen], (cont="_c", contour="_c", annot="_a", pen=("", add_opt_pen),
	                                       colored="_+c", cline="_+cl", ctext="_+cf"))
end

# ---------------------------------------------------------------------------------------------------
grdcontour!(cmd0::String="", arg1=nothing; first=false, kw...) = grdcontour(cmd0, arg1; first=false, kw...)
grdcontour(arg1, cmd0::String=""; first=true, kw...) = grdcontour(cmd0, arg1; first=first, kw...)
grdcontour!(arg1, cmd0::String=""; first=false, kw...) = grdcontour(cmd0, arg1; first=false, kw...)