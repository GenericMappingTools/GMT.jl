"""
	fitcircle(cmd0::String="", arg1=nothing, kwargs...)

Find mean position and great [or small] circle fit to points on a sphere.

See full GMT (not the `GMT.jl` one) docs at [`fitcircle`]($(GMTdoc)fitcircle.html)

Parameters
----------

- **L** | **norm** :: [Type => Int | []]

    Specify the desired norm as 1 or 2, or use [] or 3 to see both solutions.
- **F** | **coord** | **coordinates** :: [Type => Str]	`Arg = f|m|n|s|c`

    Only return data coordinates, and append Arg to specify which coordinates you would like.
- **S** | **small_circle** :: [Type => Number]    `Arg = symmetry_factor`

    Attempt to
- $(opt_V)
- $(opt_write)
- $(opt_append)
- $(_opt_bi)
- $(_opt_di)
- $(opt_e)
- $(_opt_f)
- $(opt_g)
- $(_opt_h)
- $(_opt_i)
- $(opt_o)
- $(opt_swap_xy)
"""
fitcircle(cmd0::String; kwargs...) = fitcircle_helper(cmd0, nothing; kwargs...)
fitcircle(arg1; kwargs...)         = fitcircle_helper("", arg1; kwargs...)

# ---------------------------------------------------------------------------------------------------
function fitcircle_helper(cmd0::String, arg1; kwargs...)

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
