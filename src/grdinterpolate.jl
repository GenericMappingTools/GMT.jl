"""
	grdinterpolate(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

Interpolates the grid(s) at the positions in the table and writes out the table with the
interpolated values added as (one or more) new columns.

Full option list at [`grdinterpolate`]($(GMTdoc)/grdinterpolate.html)

Parameters
----------

- **A** | **interp_path** :: [Type => Str]

    ($(GMTdoc)grdinterpolate.html#a)
- **C** | **equidistant** :: [Type => Str]

    ($(GMTdoc)grdinterpolate.html#c)
- **D** | **dfile** :: [Type => Str]  

    ($(GMTdoc)grdinterpolate.html#d)
- **E** | **by_coord** :: [Type => Str]

    ($(GMTdoc)grdinterpolate.html#e)
- **G** | **grid** :: [Type => Str | GMTgrid | Tuple(GMTgrid's)]

    ($(GMTdoc)grdinterpolate.html#g)
- **N** | **no_skip** :: [Type => Bool]

    ($(GMTdoc)grdinterpolate.html#n)
- $(GMT.opt_R)
- **S** | **stack** :: [Type => Str]

    ($(GMTdoc)grdinterpolate.html#s)
- **T** | **radius** :: [Type => Number, Str | []]

    ($(GMTdoc)grdinterpolate.html#t)
- **Z** | **z_only** :: [Type => Bool]

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
	cmd  = add_opt(d, cmd, 'F', [:F :interp],
           (linear="_l", akima="_a", cubic="_c", nearest="_n", first_derivative="+1", second_derivative="+2"))

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)

	cmd, args, n1, = add_opt(d, cmd, 'E', [:E :crossection], :line, Vector{Any}([arg1, arg2]), (azim="+a", great_circ="_+g", parallel="_+p", inc="+i", length="+l", npoints="+n", middpoint="+o", radius="+r", loxodrome="_+x"))
	if (n1 > 0)
		arg1, arg2 = args[:]
		_Vt = Vector{Any}([arg2, arg3])
	else
		_Vt = Vector{Any}([arg1, arg2])
	end

	cmd, args, n2, = add_opt(d, cmd, 'S', [:S :track], :line, _Vt, (header="+h",))
	if     (n1 == 0 && n2 > 0)  arg1, arg2 = args[:]
	elseif (n2 > 0)             arg2, arg3 = args[:]
	end

	cmd = parse_opt_range(d, cmd, "T")

	#!occursin("-G", cmd) && (cmd *= " -G")
	if (isa(arg1, Tuple))
		for k = 1:length(arg1)  cmd *= " ?"  end		# Need as many ? as numel(arg1)
		common_grd(d, "grdinterpolate " * cmd, arg1..., arg2, arg3)
	else
		common_grd(d, "grdinterpolate " * cmd, arg1, arg2, arg3)
	end

end