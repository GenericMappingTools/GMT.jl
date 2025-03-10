"""
	gmtselect(cmd0::String="", arg1=nothing, kwargs...)

Select data table subsets based on multiple spatial criteria.

See full GMT (not the `GMT.jl` one) docs at [`gmtselect`]($(GMTdoc)gmtselect.html)

Parameters
----------

- $(_opt_R)
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
- **I** | **invert** | **reverse** :: [Type => Str | []]    `Arg = [cflrsz]`

    Reverses the sense of the test for each of the criteria specified.
- $(_opt_J)
- **L** | **dist2line** :: [Type => Str | NamedTuple]    `Arg = linefile+ddist[unit][+p] | (pts=Array, dist=xx, ortho=_)`

    Pass all records whose location is within dist of any of the line segments in the ASCII
    multiple-segment file linefile.
- **N** | **mask** :: [Type => Str | List]     `Arg = ocean/land/lake/island/pond or wet/dry`

    Pass all records whose location is inside specified geographical features.
- **Z** | **in_range** :: [Type => Str | List]     `Arg = min[/max][+a][+ccol][+i]`

    Pass all records whose 3rd column (z; col = 2) lies within the given range or is NaN.
- $(opt_V)
- $(opt_write)
- $(opt_append)
- $(opt_b)
- $(opt_d)
- $(opt_e)
- $(_opt_f)
- $(opt_g)
- $(_opt_h)
- $(_opt_i)
- $(opt_o)
- $(opt_w)
- $(opt_swap_xy)
"""
function gmtselect(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing, arg4=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd::String = parse_common_opts(d, "", [:R :V_params :b :d :e :f :g :h :i :o :w :yx])[1]
	cmd = parse_these_opts(cmd, d, [[:A :area], [:D :res :resolution], [:E :boundary],
	                                [:G :gridmask], [:I :invert :reverse], [:N :mask], [:Z :in_range]])
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

# ---------------------------------------------------------------------------------------------
function clipbyrect(D::Vector{<:GMTdataset}, limits; revert::Bool=false)
	# gmtselect -R (and maybe others) is screwing by not respecting some segments.
	# This function replaces that functionality. Ideally it should behave differently when clipping lines or polygons 
	in    = zeros(Bool, numel(D))
	cross = zeros(Bool, numel(D))
	for k = 1:numel(D)
		in[k] = D[k].bbox[1] >= limits[1] &&  D[k].bbox[2] <= limits[2]
		in[k] && (in[k] = D[k].bbox[3] >= limits[3] && D[k].bbox[4] <= limits[4])
		out = !in[k]	# In the end a out[k] is one that is not 'in' nor 'cross'
		if (!in[k])
			out = D[k].bbox[2] < limits[1] || D[k].bbox[1] > limits[2]
			!out && (out = (D[k].bbox[4] < limits[3] || D[k].bbox[3] > limits[4]))
		end
		cross[k] = !in[k] && !out
	end
	revert && (in .= .!in)
	Dclipped = Vector{GMTdataset{Float64,2}}(undef, sum(in)+sum(cross))
	m = 0
	for k = 1:numel(D)
		in[k] && (Dclipped[m+=1] = deepcopy(D[k]))
		if (cross[k])
			in_seg = zeros(Bool, size(D[k],1))
			for n = 1:size(D[k],1)
				in_seg[n] = D[k][n,1] <= limits[2] && D[k][n,1] >= limits[1]
				in_seg[n] && (in_seg[n] = (D[k][n,2] <= limits[4] && D[k][n,2] >= limits[3]))
			end
			Dclipped[m+=1] = mat2ds(D[k].data[in_seg,:])
		end
	end
	set_dsBB!(Dclipped, false)
	if (!isempty(Dclipped)) Dclipped[1].proj4, Dclipped[1].wkt, Dclipped[1].epsg = D[1].proj4, D[1].wkt, D[1].epsg  end
	return Dclipped
end
