"""
	fitcircle(cmd0::String="", arg1=nothing, kwargs...)

Find mean position and great [or small] circle fit to points on a sphere.

Full option list at [`fitcircle`]($(GMTdoc)fitcircle.html)

Parameters
----------

- **L** | **norm** :: [Type => Int | []]

    Specify the desired norm as 1 or 2, or use [] or 3 to see both solutions.
    ($(GMTdoc)fitcircle.html#l)
- **F** | **coord** | **coordinates** :: [Type => Str]	`Arg = f|m|n|s|c`

    Only return data coordinates, and append Arg to specify which coordinates you would like.
    ($(GMTdoc)fitcircle.html#f)
- **S** | **small_circle** :: [Type => Number]    `Arg = symmetry_factor`

    Attempt to
    ($(GMTdoc)fitcircle.html#s)
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_o)
- $(GMT.opt_swap_xy)
"""
function fitcircle(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:V_params :bi :di :e :f :g :h :i :o :yx])
	cmd  = parse_these_opts(cmd, d, [[:L :norm], [:S :small_circle]])
	((val = find_in_dict(d, [:F :coord :coordinates])[1]) !== nothing) && (cmd *= " -F" * arg2str(val)[1])

	D = common_grd(d, cmd0, cmd, "fitcircle ", arg1)		# Finish build cmd and run it
	if isa(D, GMTdataset)			# Can be a string if Vd=2 was used.
		D.colnames = ["lon", "lat"]
		D.proj4 = "+proj=lonlat"	# Should add that this is spherical, but how to know the Planet?
		D.geom = (size(D,1) == 1) ? wkbPoint : wkbMultiPoint
	end
	D
end

# ---------------------------------------------------------------------------------------------------
fitcircle(arg1; kw...) = fitcircle("", arg1; kw...)