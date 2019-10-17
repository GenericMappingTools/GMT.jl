"""
	gmtselect(cmd0::String="", arg1=nothing, kwargs...)

Select data table subsets based on multiple spatial criteria.

Full option list at [`gmtselect`]($(GMTdoc)gmtselect.html)

Parameters
----------

- $(GMT.opt_R)
- **A** | **area** :: [Type => Str | Number]

    Features with an area smaller than min_area in km^2 or of hierarchical level that is
    lower than min_level or higher than max_level will not be plotted.
    ($(GMTdoc)gmtselect.html#a)
- **C** | **dist2pt** :: [Type => Str]   `Arg = pointfile+ddist[unit]`

    Pass all records whose location is within dist of any of the points in the ASCII file pointfile.
    If dist is zero then the 3rd column of pointfile must have each point’s individual radius of influence.
    ($(GMTdoc)gmtselect.html#c)
- **D** | **res** | **resolution** :: [Type => Str]      `Arg = c|l|i|h|f`

    Ignored unless N is set. Selects the resolution of the coastline data set to use
    ((f)ull, (h)igh, (i)ntermediate, (l)ow, or (c)rude).
    ($(GMTdoc)gmtselect.html#d)
- **E** | **boundary** :: [Type => Str | []]            `Arg = [fn]`

    Specify how points exactly on a polygon boundary should be considered.
    ($(GMTdoc)gmtselect.html#e)
- **F** | **polygon** :: [Type => Str | GMTdaset | Mx2 array]     `Arg = polygonfile`

    Pass all records whose location is within one of the closed polygons in the multiple-segment
    file ``polygonfile`` or a GMTdataset type or a Mx2 array defining the polygon.
    ($(GMTdoc)gmtselect.html#f)
- **G** | **gridmask** :: [Type => Str | GRDgrid]        `Arg = gridmask`

    Pass all locations that are inside the valid data area of the grid gridmask.
    Nodes that are outside are either NaN or zero.
    ($(GMTdoc)gmtselect.html#g)
- **I** | **reverse** :: [Type => Str | []]    `Arg = [cflrsz]`

    Reverses the sense of the test for each of the criteria specified.
    ($(GMTdoc)gmtselect.html#i)
- $(GMT.opt_J)
- **L** | **dist2line** :: [Type => Str]    `Arg = linefile+ddist[unit][+p]`

    Pass all records whose location is within dist of any of the line segments in the ASCII
    multiple-segment file linefile.
    ($(GMTdoc)gmtselect.html#l)
- **N** | **mask** :: [Type => Str | List]     `Arg = ocean/land/lake/island/pond or wet/dry`

    Pass all records whose location is inside specified geographical features.
    ($(GMTdoc)gmtselect.html#n)
- **Z** | **in_range** :: [Type => Str | List]     `Arg = min[/max][+a][+ccol][+i]`

    Pass all records whose 3rd column (z; col = 2) lies within the given range or is NaN.
    ($(GMTdoc)gmtselect.html#z)
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_o)
- $(GMT.opt_swap_xy)
"""
function gmtselect(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("gmtselect", cmd0, arg1, arg2, arg3)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :b :d :e :f :g :h :i :o :yx])
	cmd = parse_these_opts(cmd, d, [[:A :area], [:D :res :resolution], [:E :boundary], [:F :polygon],
	                [:G :gridmask], [:I :reverse], [:N :mask], [:Z :in_range]])
	#cmd = add_opt(cmd, 'N', d, [:N :mask], (ocean=("", arg2str, 1), land=("", arg2str, 2)) )

	cmd, arg2 = dist2PtLine(d, cmd, 'C')
	cmd, arg3 = dist2PtLine(d, cmd, 'L')
	if (arg1 === nothing)  arg1 = arg2;  arg2 = arg3;  arg3 = nothing  end
	if (arg2 === nothing && arg3 !== nothing)  arg2 = arg3  end

	common_grd(d, cmd0, cmd, "gmtselect ", arg1, arg2, arg3)		# Finish build cmd and run it
end

function dist2PtLine(d, cmd, opt)
	# Accept (GMTdataset[,dist [,whatever]]); or (fname[,dist [,whatever]]); or 'fname' or full GMT syntax (string)
	# Accept dist2line|dist2pt(line=fname|dataset, pts=fname|datset [,dist=value [,ortho=whatever]])
	arg = nothing
	opt == 'C' ? symbs = [:C :dist2pt :dist] : symbs = [:L :dist2line]
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		cmd *= " -" * opt
		if (isa(val, NamedTuple))
			d = nt2dict(val)
			if ((target = find_in_dict(d, [:line :pts])[1]) === nothing)  error(":line or :pts member cannot be missing")  end
			dist = "+d0"		# The default when dist is not provided
			if ((dist = find_in_dict(d, [:dist])[1]) !== nothing)  dist = "+d" * arg2str(dist)  end
			(isa(target, String) || isa(target, String)) ? cmd *= target : arg = target
			cmd *= dist
			if (haskey(d, :ortho))  cmd *= "+p"  end
		elseif (isa(val, Tuple))
			if (isa(val[1], String) || isa(val[1], Symbol))
				cmd = string(cmd, val[1], "+d", val[2])
			else
				cmd = string(cmd, "+d", val[2]);	arg = val[1]
			end
			if (length(val) == 3)  cmd *= "+p"  end
		elseif (isa(val, String) || isa(val, Symbol))
			cmd *= string(val)
		end
	end
	return cmd, arg
end

# ---------------------------------------------------------------------------------------------------
gmtselect(arg1, cmd0::String=""; kw...) = gmtselect(cmd0, arg1; kw...)