"""
	contour(cmd0::String="", arg1=nothing; kwargs...)

Reads a table data and produces a raw contour plot by triangulation.

Full option list at [`contour`]($(GMTdoc)contour.html)

Parameters
----------

- $(GMT.opt_J)
- **A** | **annot** :: [Type => Str | Number]       ``Arg = [-|[+]annot_int][labelinfo]``

    *annot_int* is annotation interval in data units; it is ignored if contour levels are given in a file.
    ($(GMTdoc)contour.html#a)
- $(GMT.opt_B)
- **C** | **cont** | **contour** | **contours** | **levels** :: [Type => Str | Number | GMTcpt]  ``Arg = [+]cont_int``

    Contours to be drawn may be specified in one of three possible ways.
    ($(GMTdoc)contour.html#c)
- **D** | **dump** :: [Type => Str]

    Dump contours as data line segments; no plotting takes place.
    ($(GMTdoc)contour.html#d)
- **E** | **index** :: [Type => Str | Mx3 array]

    Give name of file with network information. Each record must contain triplets of node
    numbers for a triangle.
    ($(GMTdoc)contour.html#e)
- **G** | **labels** :: [Type => Str]

    Controls the placement of labels along the quoted lines.
    ($(GMTdoc)contour.html#g)
- **I** | **fill** | **colorize** :: [Type => Bool]

    Color the triangles using the color scale provided via **C**.
    ($(GMTdoc)contour.html#i)
- $(GMT.opt_Jz)
- **L** | **mesh** :: [Type => Str | Number]

    Draw the underlying triangular mesh using the specified pen attributes (if not provided, use default pen)
    ($(GMTdoc)contour.html#l)
- **N** | **no_clip** :: [Type => Bool]

    Do NOT clip contours or image at the boundaries [Default will clip to fit inside region].
    ($(GMTdoc)contour.html#n)
- $(GMT.opt_P)
- **Q** | **cut** :: [Type => Str | Number]         ``Arg = [cut[unit]][+z]]``

    Do not draw contours with less than cut number of points.
    ($(GMTdoc)contour.html#q)
- **S** | **skip** :: [Type => Str | []]            ``Arg = [p|t]``

    Skip all input xyz points that fall outside the region.
    ($(GMTdoc)contour.html#s)
- **T** | **ticks** :: [Type => Str]                 ``Arg = [+|-][+a][+dgap[/length]][+l[labels]]``

    Draw tick marks pointing in the downward direction every *gap* along the innermost closed contours.
    ($(GMTdoc)contour.html#t)
- $(GMT.opt_R)
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** | **pen** :: [Type => Str | Number]

    Sets the attributes for the particular line.
    ($(GMTdoc)contour.html#w)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- **Z** | **scale** :: [Type => Str]

    Use to subtract shift from the data and multiply the results by factor before contouring starts.
    ($(GMTdoc)contour.html#z)
- $(GMT.opt_bi)
- $(GMT.opt_bo)
- $(GMT.opt_d)
- $(GMT.opt_di)
- $(GMT.opt_do)
- $(GMT.opt_e)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_p)
- $(GMT.opt_t)
- $(GMT.opt_swap_xy)
"""
function contour(cmd0::String="", arg1=nothing; first=true, kwargs...)

    gmt_proggy = (IamModern[1]) ? "contour "  : "pscontour "
	length(kwargs) == 0 && return monolitic(gmt_proggy, cmd0, arg1)

	d = KW(kwargs)
    K, O = set_KO(first)		# Set the K O dance

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd, = parse_common_opts(d, cmd, [:UVXY :bo :c :d :do :e :p :t :params], first)
	cmd  = parse_these_opts(cmd, d, [[:D :dump], [:I :fill :colorize], [:N :no_clip], [:Q :cut], [:S :skip]])
	cmd *= add_opt_pen(d, [:L :mesh], "L", true)     # TRUE to also seek (lw,lc,ls)
	cmd  = parse_contour_AGTW(d::Dict, cmd::String)

	# If file name sent in, read it and compute a tight -R if this was not provided
	cmd, arg1, opt_R, info = read_data(d, cmd0, cmd, arg1, opt_R, false, true)
	cmd, N_used_, arg1, arg2, arg3 = get_cpt_set_R(d, "", cmd, opt_R, (arg1 === nothing), arg1, nothing, nothing, "pscontour")
	N_used = (arg1 !== nothing) + (arg2 !== nothing) + (arg3 !== nothing)

	if (!occursin(" -C", cmd))			# Otherwise ignore an eventual :cont because we already have it
		cmd, args, n, = add_opt(cmd, 'C', d, [:C :cont :contour :contours :levels], :data, Array{Any,1}([arg1, arg2, arg3]), (x="",))
		if (n > 0)
			for k = 3:-1:1
				if (args[k] === nothing)  continue  end
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
		if (isa(val, Array{<:Number}) || isa(val, GMTdataset) || isa(val, Array{<:GMTdataset}))   # Now need to find the free slot where to store the indices array
			(N_used == 0) ? arg1 = val : (N_used == 1 ? arg2 = val : arg3 = val)
		else
			cmd *= arg2str(val)
		end
	end

	if (!occursin(" -W", cmd) && !occursin(" -I", cmd) && !occursin(" -D", cmd))  cmd *= " -W"  end	# Use default pen

	if (occursin("-I", cmd) && !occursin("-C", cmd))
		info[1].data[5], info[1].data[6] = round_wesn([info[1].data[5], info[1].data[6], info[1].data[5], info[1].data[6]])
		opt_T = (current_cpt === nothing) ? @sprintf(" -T%.14g/%.14g/11+n", info[1].data[5], info[1].data[6]) : ""
		if (N_used <= 1)
			cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C], 'C', N_used, arg1, arg2, true, true, opt_T, true)
		else
			cmd, arg2, arg3, = add_opt_cpt(d, cmd, [:C], 'C', N_used, arg2, arg3, true, true, opt_T, true)
		end
	end

	if (occursin(" -I", cmd) && (!isa(arg1, GMTcpt) && !isa(arg2, GMTcpt) && !isa(arg3, GMTcpt)))
		# If arg to a -C ends with .cpt, accept it
		if ((ind = findfirst("-C", cmd)) !== nothing && !endswith(split(cmd[ind[2]+1:end])[1], ".cpt"))
			error("fill option rquires passing a CPT")
		end
	end

	cmd, K = finish_PS_nested(d, gmt_proggy * cmd, "", K, O, [:coast :colorbar])
	return finish_PS_module(d, cmd, "-D", K, O, true, arg1, arg2, arg3)
end

# ---------------------------------------------------------------------------------------------------
contour!(cmd0::String="", arg1=nothing; first=false, kw...) = contour(cmd0, arg1; first=false, kw...)
contour(arg1, cmd0::String=""; first=true, kw...) = contour(cmd0, arg1; first=first, kw...)
contour!(arg1, cmd0::String=""; first=false, kw...) = contour(cmd0, arg1; first=false, kw...)

# ---------------------------------------------------------------------------------------------------
const pscontour  = contour
const pscontour! = contour!
