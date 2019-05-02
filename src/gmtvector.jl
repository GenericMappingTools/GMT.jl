"""
	gmtvector(cmd0::String="", arg1=nothing, kwargs...)

Time domain filtering of 1-D data tables.

Full option list at [`gmtvector`](http://gmt.soest.hawaii.edu/doc/latest/gmtvector.html)

Parameters
----------

- **A** : **single_vec** : -- Str --   Flags = m[conf]|vector

    Specify a single, primary vector instead of reading tables.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/gmtvector.html#a)
- **C** : **cartesian** : -- Str or [] --        Flags = [i|o]

    Select Cartesian coordinates on input and output.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/gmtvector.html#c)
- **E** : **geod2geoc** : -- Bool or [] --

    Convert input geographic coordinates from geodetic to geocentric and output geographic
    coordinates from geocentric to geodetic.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/gmtvector.html#e)
- **N** : **normalize** : -- Bool or [] --

    Normalize the resultant vectors prior to reporting the output.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/gmtvector.html#n)
- **S** : **secondary_vec** : -- Str or List --    Flags = [vector]

    Specify a single, secondary vector in the same format as the first vector.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/gmtvector.html#s)
- **T** : **transform** : -- List or Str --     Flags = a|d|D|paz|s|r[arg|R|x]

    Specify the vector transformation of interest.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/gmtvector.html#t)
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
function gmtvector(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("gmtvector", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :b :d :e :f :g :h :i :o :yx])
	cmd = parse_these_opts(cmd, d, [[:A :single_vec], [:C :cartesian], [:E :geod2geoc], [:N :normalize],
				[:S :secondary_vec], [:T :transform]])

	common_grd(d, cmd0, cmd, "gmtvector ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtvector(arg1; kw...) = gmtvector("", arg1; kw...)