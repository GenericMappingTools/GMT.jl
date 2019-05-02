"""
	fitcircle(cmd0::String="", arg1=nothing, kwargs...)

Find mean position and great [or small] circle fit to points on a sphere.

Full option list at [`fitcircle`](http://gmt.soest.hawaii.edu/doc/latest/fitcircle.html)

Parameters
----------

- **L** : **norm** : -- Int or [] --

    Specify the desired norm as 1 or 2, or use [] or 3 to see both solutions.
	[`-D`](http://gmt.soest.hawaii.edu/doc/latest/fitcircle.html#d)

- **F** : **coord** : **coordinates** : -- Str --	Flags = f|m|n|s|c

    Only return data coordinates, and append flags to specify which coordinates you would like.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/fitcircle.html#f)
- **S** : **symetry** : -- Number --    Flags = symmetry_factor

    Attempt to
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/fitcircle.html#s)
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

	length(kwargs) == 0 && return monolitic("fitcircle", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :bi :di :e :f :g :h :i :o :yx])
	cmd = parse_these_opts(cmd, d, [[:L :norm], [:F :coord :coordinates], [:S :small_circle]])

	common_grd(d, cmd0, cmd, "fitcircle ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
fitcircle(arg1, cmd0::String=""; kw...) = fitcircle(cmd0, arg1; kw...)