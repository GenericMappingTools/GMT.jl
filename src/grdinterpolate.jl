"""
	grdinterpolate(cmd0="", arg1=nothing, arg2=nothing; kwargs...)

Interpolate a 3-D cube, 2-D grids or 1-D series from a 3-D data cube or stack of 2-D grids.

Full option list at [`grdinterpolate`]($(GMTdoc)/grdinterpolate.html)

Parameters
----------

- **D** | **meta** | **metadata** :: [Type => Str | NamedTuple]  

    Give one or more combinations for values xname, yname, zname (3rd dimension in cube), and dname
    (data value name) and give the names of those variables and in square bracket their units
    ($(GMTdoc)grdinterpolate.html#d)
- **E** | **crossection** :: [Type => Str | GMTdtaset | NamedTuple]

    Specify a crossectinonal profile via a file or from specified line coordinates and modifiers. If a file,
    it must be contain a single segment with either lon lat or lon lat dist records. These must be equidistant. 
    ($(GMTdoc)grdinterpolate.html#e)
- **F** | **interp_type** :: [Type => Str]   ``Arg = l|a|c|n[+1|+2]``

    Choose from l (Linear), a (Akima spline), c (natural cubic spline), and n (no interpolation:
    nearest point) [Default is Akima].
- **G** | **outfile** | **outgrid** :: [Type => Str]

    Output file name. If `range` only selects a single layer then the data cube collapses to a regular 2-D grid file
    ($(GMTdoc)grdinterpolate.html#g)
- $(GMT.opt_R)
- **S** | **track** | **pt** :: [Type => Str | Tuple | Dataset]	`Arg = x/y|pointfile[+hheader]`

    Rather than compute gridded output, create tile/spatial series through the stacked grids at the given point (x/y)
    or the list of points in pointfile. 
    ($(GMTdoc)grdinterpolate.html#s)
- **T** | **range** :: [Type => Str]			`Arg = [min/max/]inc[+i|n] |-Tfile|list`

    Make evenly spaced time-steps from min to max by inc [Default uses input times].
    ($(GMTdoc)grdinterpolate.html#t)
- **Z** | **levels** :: [Type => range]			`Arg = [levels]`

    The `levels` may be specified the same way as in `range`. If not given then we default to an integer
    levels array starting at 0.
    ($(GMTdoc)grdinterpolate.html#z)
- $(GMT.opt_V)
- $(GMT.opt_bi)
- $(GMT.opt_bo)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_n)
- $(GMT.opt_o)
- $(GMT.opt_q)
- $(GMT.opt_s)
- $(GMT.opt_swap_xy)

When using two numeric inputs and no G option, the order of the x,y and grid is not important.
That is, both of this will work: D = grdinterpolate([0 0], G);  or  D = grdinterpolate(G, [0 0]); 
"""
function grdinterpolate(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; kwargs...)

	length(kwargs) == 0 && arg1 === nothing && return monolitic("grdinterpolate", cmd0, arg1, arg2, arg3)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_common_opts(d, "", [:R :V_params :bi :bo :di :e :f :g :h :i :n :o :q :s :yx])
	cmd  = parse_these_opts(cmd, d, [[:G :outfile :outgrid], [:Z :levels]])

	cmd  = add_opt(d, cmd, 'D', [:D :meta :metadata],
           (xname="+x", yname="+y", zname="+z", dname="+d", scale="+s", offset="+o", nodata="+n", title="+t", remark="+r", varname="+v"))
	cmd  = add_opt(d, cmd, 'F', [:F :interp_type],
           (linear="_l", akima="_a", cubic="_c", nearest="_n", first_derivative="+1", second_derivative="+2"))

	cmd, _, arg1 = find_data(d, cmd0, cmd, arg1)

	cmd, args, n1, = add_opt(d, cmd, 'E', [:E :crossection], :line, Vector{Any}([arg1, arg2]), (azim="+a", great_circ="_+g", parallel="_+p", inc="+i", length="+l", npoints="+n", middpoint="+o", radius="+r", loxodrome="_+x"))

	if ((val = find_in_dict(d, [:S :track :pt])[1]) !== nothing)
		if (isa(val, Tuple) || (isa(val, Array{<:Number}) && length(val) == 2))
			cmd *= " -S" * arg2str(val)
		elseif (isa(val, String))
			cmd *= " -S" * val
		elseif (isa(val, Matrix) || isGMTdataset(val))
			(arg1 === nothing) ? arg1 = val : ((arg2 === nothing) ? arg2 = val : arg3 = val)
			cmd *= " -S"
		else  error("Bad data type for option `track` $(typeof(val))")
		end
	end

	cmd = parse_opt_range(d, cmd, "T")[1]

	#!occursin("-G", cmd) && (cmd *= " -G")
	if (isa(arg1, Tuple))
		for k = 1:length(arg1)  cmd *= " ?"  end		# Need as many ? as numel(arg1)
		R = common_grd(d, "grdinterpolate " * cmd, arg1..., arg2, arg3)
	else
		R = common_grd(d, "grdinterpolate " * cmd, arg1, arg2, arg3)
	end

	if (!isa(R, String) && occursin(" -S", cmd) && !occursin(" -o", cmd))	# Here we don't want the default GMT output
		[R[k].data = R[k].data[:, [4,3]] for k = 1:length(R)]
	end
	R
end

# ---------------------------------------------------------------------------------------------------
grdinterpolate(arg1, arg2=nothing, arg3=nothing; kw...) = grdinterpolate("", arg1, arg2, arg3; kw...)