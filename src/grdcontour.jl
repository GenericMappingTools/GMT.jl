"""
	grdcontour(cmd0::String="", arg1=nothing; kwargs...)

Read a 2-D grid file or a GMTgrid type and produces a contour map by tracing each
contour through the grid.

Parameters
----------

- $(_opt_J)
- **A** | **annot** | **annotation** :: [Type => Str or Number]       ``Arg = [-|[+]annot_int][labelinfo]``

    *annot_int* is annotation interval in data units; it is ignored if contour levels are given in a file.
- $(_opt_B)
- **C** | **cont** | **contour** | **contours** | **levels** :: [Type => Str | Number | GMTcpt]  ``Arg = [+]cont_int``

    Contours to be drawn may be specified in one of three possible ways.
- **D** | **dump** :: [Type => Str]

    Dump contours as data line segments; no plotting takes place.
- **F** | **force** :: [Type => Str | []]

    Force dumped contours to be oriented so that higher z-values are to the left (-Fl [Default]) or right.
- **G** | **labels** :: [Type => Str]

    Controls the placement of labels along the quoted lines.
- $(opt_Jz)
- **L** | **range** :: [Type => Str]

    Limit range: Do not draw contours for data values below low or above high.
- **N** | **fill** | **colorize** :: [Type => Bool]

    Fill the area between contours using the discrete color table given by cpt.
- $(opt_P)
- **Q** | **cut** :: [Type => Str | Number]

    Do not draw contours with less than cut number of points.
- **S** | **smooth** :: [Type => Number]

    Used to resample the contour lines at roughly every (gridbox_size/smoothfactor) interval.
- **T** | **ticks** :: [Type => Str]

    Draw tick marks pointing in the downward direction every *gap* along the innermost closed contours.
- $(_opt_R)
- $(opt_U)
- $(opt_V)
- **W** | **pen** :: [Type => Str | Number]

    Sets the attributes for the particular line.
- $(opt_X)
- $(opt_Y)
- **Z** | **muladd** | **scale** :: [Type => Str]

    Use to subtract shift from the data and multiply the results by factor before contouring starts.
- $(opt_bo)
- $(opt_do)
- $(opt_e)
- $(_opt_f)
- $(_opt_h)
- $(_opt_p)
- $(_opt_t)
- $(opt_savefig)

To see the full documentation type: ``@? grdcontour``
"""
grdcontour(cmd0::String; kw...) = grdcontour_helper(cmd0, nothing; kw...)
grdcontour(arg1; kw...) = grdcontour_helper("", arg1; kw...)
grdcontour!(cmd0::String; kw...) = grdcontour_helper(cmd0, nothing; first=false, kw...)
grdcontour!(arg1; kw...) = grdcontour_helper("", arg1; first=false, kw...)

# ---------------------------------------------------------------------------------------------------
function grdcontour_helper(cmd0::String, arg1; first=true, kw...)
	d, K, O = init_module(first, kw...)		# Also checks if the user wants ONLY the HELP mode
	_grdcontour_helper(cmd0, arg1, O, K, d)
end
function _grdcontour_helper(cmd0::String, arg1, O::Bool, K::Bool, d::Dict)
	arg2, arg3 = nothing, nothing
	dict_auto_add!(d)					# The ternary module may send options via another channel

	cmd::String, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX" * split(DEF_FIG_SIZE, '/')[1] * "/0")
	cmd, = parse_common_opts(d, cmd, [:UVXY :margin :params :bo :c :e :f :h :p :t]; first=!O)
	cmd  = parse_these_opts(cmd, d, [[:D :dump], [:F :force], [:L :range], [:Q :cut], [:S :smooth]])
	cmd  = parse_contour_AGTW(d::Dict, cmd::String)[1]
	cmd  = add_opt(d, cmd, "Z", [:Z :muladd :scale], (factor = "+s", shift = "+o", periodic = "_+p"))

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)	# Find how data was transmitted
	if (isa(arg1, Matrix{<:Real}))	arg1 = mat2grid(arg1)	end

	cmd, N_used, arg1, arg2, = common_get_R_cpt(d, cmd0, cmd, opt_R, got_fname, arg1, arg2, nothing, "grdcontour")

	got_N_cpt = false		# Shits because 6.1 still cannot process N=cpt (6.1.1 can)
	if ((val = find_in_dict(d, [:N :fill :colorize], false)[1]) !== nothing)
		if (isa(val, GMTcpt))
			N = (N_used > 1) ? 1 : N_used		# Trickery because add_opt_cpt() is not able to deal with 3 argX
			if (isa(arg1, GMTgrid))
				cmd, arg2, arg3, = add_opt_cpt(d, cmd, [:N :fill :colorize], 'N', N, arg2, arg3)
    		else
				cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:N :fill :colorize], 'N', N, arg1, arg2)
			end
			got_N_cpt = true
		else
			cmd *= " -N"
			delete!(d, [:N, :fill, :colorize])
		end
	end

	if (!occursin(" -C", cmd))			# Otherwise ignore an eventual :cont because we already have it
		cmd, args, n, = add_opt(d, cmd, "C", [:C :cont :contour :contours :levels], :data, Array{Any,1}([arg1, arg2, arg3]), (x = "",))
		if (n > 0)
			for k = 3:-1:1
				(args[k] === nothing) && continue
				if (isa(args[k], Array{<:Real}))
					cmd *= arg2str(args[k], ',')
					if (length(args[k]) == 1)  cmd *= ","  end		# A single contour needs to end with a ","
					break
				elseif (isa(args[k], GMTcpt))
					arg1, arg2, arg3 = args[:]
					break
				end
			end
		end
	end

	# -N option is bugged up to 6.1.0 because it lacked the apropriate KEY, so trickery is needed.
	if (occursin(" -N", cmd))
		if (occursin(" -C", cmd) && (isa(arg1, GMTcpt) || isa(arg2, GMTcpt)))
			if (!got_N_cpt)		# C=cpt, N=true. Must replicate the CPT into N
				isa(arg1, GMTcpt) ? arg2 = arg1 : arg3 = arg2
			end
		end
	elseif (got_N_cpt && !occursin(" -C", cmd))		# N=cpt and no C. Work around the bug
		d[:C] = isa(arg1, GMTcpt) ? arg1 : arg2
	end

	opt_extra = "";		finish = true
	if (occursin("-D", cmd))
		opt_extra = "-D";		finish = false;	cmd = replace(cmd, opt_J => "")
	end

	_cmd = ["grdcontour " * cmd]
	_cmd = frame_opaque(_cmd, "grdcontour", opt_B, opt_R, opt_J)		# No -t in frame
	_cmd = finish_PS_nested(d, _cmd)
	prep_and_call_finish_PS_module(d, _cmd, opt_extra, K, O, finish, arg1, arg2, arg3)
end

# ---------------------------------------------------------------------------------------------------
function parse_contour_AGTW(d::Dict, cmd::String)
	# Common to both grd and ps contour
	if ((val = find_in_dict(d, [:A :annot :annotation], false)[1]) !== nothing && isa(val, Array{<:Real}))
		cmd *= " -A" * arg2str(val, ',')
		if (!occursin(",", cmd))  cmd *= ","  end
		delete!(d, [:A, :annot])
	elseif (isa(val, String) || isa(val, Symbol))
		arg::String = string(val)
		cmd *= (arg == "none") ? " -A-" : " -A" * arg
		delete!(d, [:A, :annot])
	else
		cmd = add_opt(d, cmd, "A", [:A :annot],
		              (disable = ("_-", nothing, 1), none = ("_-", nothing, 1), single = ("+", nothing, 1), int = "", interval = "", labels = ("", parse_quoted)) )
	end
	cmd = add_opt(d, cmd, "G", [:G :labels], ("", helper_decorated))
	cmd = add_opt(d, cmd, "T", [:T :ticks], (local_high = ("h", nothing, 1), local_low = ("l", nothing, 1),
	                                         labels = "+l", closed = "_+a", gap = "+d") )
	opt_W = add_opt_pen(d, [:W :pen], opt="W")
	return cmd * opt_W, opt_W
end
