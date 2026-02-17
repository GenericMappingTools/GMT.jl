"""
	gmtsplit(cmd0::String="", arg1=nothing; kwargs...)

Reads a series of (x,y[,z]) records [or optionally (x,y,z,d,h)] and splits this into separate lists
of (x,y[,z]) series, such that each series has a nearly constant azimuth through the x,y plane.

See full GMT docs at [`gmtsplit`]($(GMTdoc)gmtsplit.html)

Parameters
----------

- **A** | **azim_tol** :: [Type => Str | Array]  

    Write out only those segments which are within +/- tolerance degrees of azimuth in heading,
    measured clockwise from North, [0 - 360].
- **C** | **course_change** :: [Type => Number]

    Terminate a segment when a course change exceeding course_change degrees of heading is detected.
- **D** | **min_dist** | **min_distance** :: [Type => Number]

    Do not write a segment out unless it is at least minimum_distance units long.
- **F** | **filter** :: [Type => Str | Array]

    Filter the z values and/or the x,y values, assuming these are functions of d coordinate.
    xy_filter and z_filter are filter widths in distance units.
- **N** | **multi** | **multifile** :: [Type => Bool | Str]

    Write each segment to a separate output file.
- **Q** | **fields** :: [Type => Str]

    Specify your desired output using any combination of xyzdh, in any order.
- **S** | **dh** | **dist_head** :: [Type => Bool]

    Both d and h are supplied. In this case, input contains x,y,z,d,h. [Default expects (x,y,z) input,
    and d,h are computed from delta x, delta y.
- $(opt_V)
- $(opt_write)
- $(opt_append)
- $(_opt_bi)
- $(opt_bo)
- $(_opt_di)
- $(opt_do)
- $(opt_e)
- $(_opt_f)
- $(opt_g)
- $(_opt_h)
- $(_opt_i)
- $(opt_swap_xy)

To see the full documentation type: ``@? splitxyz``
"""
gmtsplit(cmd0::String; kw...) = gmtsplit_helper(cmd0, nothing; kw...)
gmtsplit(arg1; kw...)         = gmtsplit_helper("", arg1; kw...)

# ---------------------------------------------------------------------------------------------------
function gmtsplit_helper(cmd0::String, arg1; kw...)
	d = init_module(false, kw...)[1]		    # Also checks if the user wants ONLY the HELP mode
	gmtsplit_helper(cmd0, arg1, d)
end
function gmtsplit_helper(cmd0::String, arg1, d::Dict{Symbol, Any})
	cmd, = parse_common_opts(d, "", [:V_params :bi :bo :di :do :e :f :g :h :i :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :azim_tol], [:C :course_change], [:D :min_dist :min_distance], [:F :filter],
	                                 [:N :multi :multifile], [:Q :fields :xyzdh], [:S :dh :dist_head]])
	common_grd(d, cmd0, cmd, "gmtsplit" * " ", arg1)	# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
const splitxyz = gmtsplit			# Alias