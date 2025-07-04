"""
	contour(cmd0::String="", arg1=nothing; kwargs...)

Reads a table data and produces a raw contour plot by triangulation.

See full GMT (not the `GMT.jl` one) docs at [`contour`]($(GMTdoc)contour.html)

Parameters
----------

- $(_opt_J)
- **A** | **annot** | **annotation** :: [Type => Str | Number]       ``Arg = [-|[+]annot_int][labelinfo]``

    *annot_int* is annotation interval in data units; it is ignored if contour levels are given in a file.
- $(_opt_B)
- **C** | **cont** | **contour** | **contours** | **levels** :: [Type => Str | Number | GMTcpt]  ``Arg = [+]cont_int``

    Contours to be drawn may be specified in one of three possible ways.
- **D** | **dump** :: [Type => Str]

    Dump contours as data line segments; no plotting takes place.
- **E** | **index** :: [Type => Str | Mx3 array]

    Give name of file with network information. Each record must contain triplets of node
    numbers for a triangle.
- **G** | **labels** :: [Type => Str]

    Controls the placement of labels along the quoted lines.
- **I** | **fill** | **colorize** :: [Type => Bool]

    Color the triangles using the color scale provided via **C**.
- $(opt_Jz)
- **L** | **mesh** :: [Type => Str | Number]

    Draw the underlying triangular mesh using the specified pen attributes (if not provided, use default pen)
- **N** | **no_clip** :: [Type => Bool]

    Do NOT clip contours or image at the boundaries [Default will clip to fit inside region].
- $(opt_P)
- **Q** | **cut** :: [Type => Str | Number]         ``Arg = [cut[unit]][+z]]``

    Do not draw contours with less than cut number of points.
- **S** | **skip** :: [Type => Str | []]            ``Arg = [p|t]``

    Skip all input xyz points that fall outside the region.
- **T** | **ticks** :: [Type => Str]                 ``Arg = [+|-][+a][+dgap[/length]][+l[labels]]``

    Draw tick marks pointing in the downward direction every *gap* along the innermost closed contours.
- $(_opt_R)
- $(opt_U)
- $(opt_V)
- **W** | **pen** :: [Type => Str | Number]

    Sets the attributes for the particular line.
- $(opt_X)
- $(opt_Y)
- **Z** | **scale** :: [Type => Str]

    Use to subtract shift from the data and multiply the results by factor before contouring starts.
- $(_opt_bi)
- $(opt_bo)
- $(opt_d)
- $(_opt_di)
- $(opt_do)
- $(opt_e)
- $(_opt_h)
- $(_opt_i)
- $(_opt_p)
- $(_opt_t)
- $(opt_swap_xy)
- $(opt_savefig)

To see the full documentation type: ``@? contour``
"""
contour(cmd0::String; kwargs...)  = contour_helper(cmd0, nothing; kwargs...)
contour(arg1; kwargs...)          = contour_helper("", arg1; kwargs...)
contour!(cmd0::String; kwargs...) = contour_helper(cmd0, nothing; first=false, kwargs...)
contour!(arg1; kwargs...)         = contour_helper("", arg1; first=false, kwargs...)

# ---------------------------------------------------------------------------------------------------
function contour_helper(cmd0::String, arg1; first=true, kwargs...)

    gmt_proggy = (IamModern[1]) ? "contour " : "pscontour "

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode
	dict_auto_add!(d)			# The ternary module may send options via another channel

	cmd, _, _, opt_R = parse_BJR(d, "", "", O, " -JX" * split(DEF_FIG_SIZE, '/')[1] * "/0")
	cmd, = parse_common_opts(d, cmd, [:UVXY :bo :c :d :do :e :p :t :params :margin]; first=first)
	cmd  = parse_these_opts(cmd, d, [[:D :dump], [:I :fill :colorize], [:N :no_clip], [:Q :cut], [:S :skip]])
	cmd *= add_opt_pen(d, [:L :mesh], opt="L")
	cmd, opt_W = parse_contour_AGTW(d, cmd)

	# If file name sent in, read it and compute a tight -R if this was not provided
	arg2 = nothing;		arg3 = nothing
	cmd, arg1, opt_R, wesn = read_data(d, cmd0, cmd, arg1, opt_R, false, true)
	if (occursin(" -I", cmd) || occursin("+c", opt_W))			# Only try to load cpt if -I was set
		cmd, _, arg1, arg2, arg3 = get_cpt_set_R(d, "", cmd, opt_R, (arg1 === nothing ? 1 : 0), arg1, arg2, arg3, "pscontour")
	end
	N_used = (arg1 !== nothing) + (arg2 !== nothing) + (arg3 !== nothing)

	if (!occursin(" -C", cmd))			# Otherwise ignore an eventual :cont because we already have it
		cmd, args, n, = add_opt(d, cmd, "C", [:C :cont :contour :contours :levels], :data, Array{Any,1}([arg1, arg2, arg3]), (x="",))
		if (n > 0)
			for k = 3:-1:1
				(args[k] === nothing) && continue
				if (isa(args[k], Array{<:Number}))
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

	if ((val = find_in_dict(d, [:E :index])[1]) !== nothing)
		cmd *= " -E"
		if (isa(val, Matrix{<:Real}) || isa(val, GDtype))   # Now need to find the free slot where to store the indices array
			(N_used == 0) ? arg1 = val : (N_used == 1 ? arg2 = val : arg3 = val)
		else
			cmd *= arg2str(val)
		end
	end

	if (!occursin(" -W", cmd) && !occursin(" -I", cmd) && !occursin(" -D", cmd))  cmd *= " -W"  end	# Use default pen

	if (occursin("-I", cmd) && !occursin("-C", cmd))
		r = round_wesn([wesn[5], wesn[6], wesn[5], wesn[6]])
		wesn[5], wesn[6] = r[1], r[2]
		opt_T = (isempty(CURRENT_CPT[1])) ? @sprintf(" -T%.14g/%.14g/11+n", wesn[5], wesn[6]) : ""
		if (N_used <= 1)
			cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C], 'C', N_used, arg1, arg2, true, true, opt_T, true)
		else
			cmd, arg2, arg3, = add_opt_cpt(d, cmd, [:C], 'C', N_used, arg2, arg3, true, true, opt_T, true)
		end
	end

#	if (occursin(" -I", cmd) && (!isa(arg1, GMTcpt) && !isa(arg2, GMTcpt) && !isa(arg3, GMTcpt)))
#		# If arg to a -C ends with .cpt, accept it
#		if ((ind = findfirst("-C", cmd)) !== nothing && !endswith(split(cmd[ind[2]+1:end])[1], ".cpt"))
#			error("fill option rquires passing a CPT")
#		end
#	end

	_cmd = finish_PS_nested(d, [gmt_proggy * cmd])
	prep_and_call_finish_PS_module(d, _cmd, "-D", K, O, true, arg1, arg2, arg3)
end

# ---------------------------------------------------------------------------------------------------
const pscontour  = contour
const pscontour! = contour!
