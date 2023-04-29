"""
	gmtselect(cmd0::String="", arg1=nothing, kwargs...)

Select data table subsets based on multiple spatial criteria.

See full GMT (not the `GMT.jl` one) docs at [`gmtselect`]($(GMTdoc)gmtselect.html)

Parameters
----------

- $(GMT._opt_R)
- **A** | **area** :: [Type => Str | Number]

    Features with an area smaller than min_area in km^2 or of hierarchical level that is
    lower than min_level or higher than max_level will not be plotted.
- **C** | **dist2pt** | **dist** :: [Type => Str | NamedTuple]   `Arg = pointfile+ddist[unit] | (pts=Array, dist=xx)`

    Pass all records whose location is within dist of any of the points in the ASCII file pointfile.
    If dist is zero then the 3rd column of pointfile must have each point’s individual radius of influence.
- **D** | **res** | **resolution** :: [Type => Str]      `Arg = c|l|i|h|f`

    Ignored unless N is set. Selects the resolution of the coastline data set to use
    ((f)ull, (h)igh, (i)ntermediate, (l)ow, or (c)rude).
- **E** | **boundary** :: [Type => Str | []]            `Arg = [fn]`

    Specify how points exactly on a polygon boundary should be considered.
- **F** | **polygon** :: [Type => Str | GMTdaset | Mx2 array]     `Arg = polygonfile`

    Pass all records whose location is within one of the closed polygons in the multiple-segment
    file ``polygonfile`` or a GMTdataset type or a Mx2 array defining the polygon.
- **G** | **gridmask** :: [Type => Str | GRDgrid]        `Arg = gridmask`

    Pass all locations that are inside the valid data area of the grid gridmask.
    Nodes that are outside are either NaN or zero.
- **I** | **reverse** | **revert** :: [Type => Str | []]    `Arg = [cflrsz]`

    Reverses the sense of the test for each of the criteria specified.
- $(GMT._opt_J)
- **L** | **dist2line** :: [Type => Str | NamedTuple]    `Arg = linefile+ddist[unit][+p] | (pts=Array, dist=xx, ortho=_)`

    Pass all records whose location is within dist of any of the line segments in the ASCII
    multiple-segment file linefile.
- **N** | **mask** :: [Type => Str | List]     `Arg = ocean/land/lake/island/pond or wet/dry`

    Pass all records whose location is inside specified geographical features.
- **Z** | **in_range** :: [Type => Str | List]     `Arg = min[/max][+a][+ccol][+i]`

    Pass all records whose 3rd column (z; col = 2) lies within the given range or is NaN.
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT._opt_f)
- $(GMT.opt_g)
- $(GMT._opt_h)
- $(GMT._opt_i)
- $(GMT.opt_o)
- $(GMT.opt_w)
- $(GMT.opt_swap_xy)
"""
function gmtselect(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing, arg4=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd::String = parse_common_opts(d, "", [:R :V_params :b :d :e :f :g :h :i :o :w :yx])[1]
	cmd = parse_these_opts(cmd, d, [[:A :area], [:D :res :resolution], [:E :boundary],
	                                [:G :gridmask], [:I :reverse :revert], [:N :mask], [:Z :in_range]])
	#cmd = add_opt(d, cmd, "N', [:N :mask], (ocean=("", arg2str, 1), land=("", arg2str, 2)) )
	#=
	if ((val = find_in_dict(d, [:F :polygon])[1]) !== nothing)
		cmd *= " -F"
		if (isa(val, Matrix) || (isa(val, GDtype)))
			_, n = put_in_slot("", ' ', arg1, arg2, arg3, arg4)
			(n == 1) ? arg1 = val : (n == 2 ? arg2 = val : (n == 3 ? arg3 = val : arg4 = val))
		elseif (!isa(val, String))  error("`polygon` option must be a String or a Matrix/GMTdataset. It was $(typeof(val))")
		end
	end
	=#
	cmd, arg1, arg2, arg3, arg4 = arg_in_slot(d, cmd, [:F :polygon], Union{Matrix, GDtype}, arg1, arg2, arg3, arg4)

	cmd, args, n, = add_opt(d, cmd, "C", [:C :dist2pt :dist], :pts, Array{Any,1}([arg1, arg2]), (dist="+d",))
	if (n > 0)  arg1, arg2 = args[:]  end
	cmd, args, n, = add_opt(d, cmd, "L", [:L :dist2line], :line, Array{Any,1}([arg1, arg2, arg3]), (dist="+d", ortho="_+p"))
	if (n > 0)  arg1, arg2, arg3 = args[:]  end

	common_grd(d, cmd0, cmd, "gmtselect ", arg1, arg2, arg3, arg4)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtselect(arg1; kw...) = gmtselect("", arg1; kw...)