"""
    nearneighbor(cmd0::String="", arg1=[]; kwargs...)

Reads arbitrarily located (x,y,z[,w]) triples [quadruplets] and uses a nearest neighbor algorithm
to assign an average value to each node that have one or more points within a radius centered on the node.
The average value is computed as a weighted mean of the nearest point from each sector inside the search
radius. The weighting function used is w(r) = 1 / (1 + d ^ 2), where d = 3 * r / search_radius and r is
distance from the node. This weight is modulated by the weights of the observation points [if supplied].
	
Full option list at [`nearneighbor`](http://gmt.soest.hawaii.edu/doc/latest/nearneighbor.html)

Parameters
----------

- **I** : **inc** : -- Str or Number --
	*x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/nearneighbor.html#i)
- **N** : **sectors** : -- Number or Str --
    The circular area centered on each node is divided into `sectors` sectors.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/nearneighbor.html#n)
- $(GMT.opt_R)
- **S** : **search_radius** : -- Number --  
    Sets the search_radius that determines which data points are considered close to a node.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/nearneighbor.html#s)

- **E** : **empty** : -- Bool or [] --
    Set the value assigned to empty nodes when G is set [NaN].
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/nearneighbor.html#e)
- **G** : **grid** : -- Str or [] --
	Optional output grid file name. If not provided return a GMTgrid type.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/nearneighbor.html#g)
- $(GMT.opt_V)
- **W** : **weights** : -- Bool or [] --
    Input data have a 4th column containing observation point weights.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/nearneighbor.html#w)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_n)
- $(GMT.opt_r)
- $(GMT.opt_swappxy)
"""
# ---------------------------------------------------------------------------------------------------
function nearneighbor(cmd0::String="", arg1=[]; data=[], kwargs...)

	length(kwargs) == 0 && isempty(data) && return monolitic("nearneighbor", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	cmd, opt_R = parse_R("", d)
	cmd, opt_J = parse_J(cmd, d)
	cmd = parse_V(cmd, d)
	cmd, = parse_bi(cmd, d)
	cmd, = parse_di(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd = parse_n(cmd, d)
	cmd = parse_r(cmd, d)
	cmd = parse_swappxy(cmd, d)

	cmd = add_opt(cmd, 'E', d, [:E :empty])
    cmd = add_opt(cmd, 'G', d, [:G :grid])
    ind = searchindex(cmd, "-G")
    if (ind > 0 && cmd[min(ind+2,length(cmd))] != ' ')      # A file name was provided
        no_output = true
    else
        no_output = false
    end
	cmd = add_opt(cmd, 'I', d, [:I :inc])
	cmd = add_opt(cmd, 'N', d, [:N :ids])
	cmd = add_opt(cmd, 'S', d, [:S :search_radius])
	cmd = add_opt(cmd, 'W', d, [:Z :weights])

    cmd, arg1, = read_data(data, cmd, arg1)

	(haskey(d, :Vd)) && println(@sprintf("\tnearneighbor %s", cmd))

	G = nothing
	if (no_output)
		if (!isempty_(arg1))  gmt("nearneighbor " * cmd, arg1)
		else                  gmt("nearneighbor " * cmd)
		end
	else
		if (!isempty_(arg1))  G = gmt("nearneighbor " * cmd, arg1)
		else                  G = gmt("nearneighbor " * cmd)
		end
	end
	return G
end

# ---------------------------------------------------------------------------------------------------
nearneighbor(arg1::Array, cmd0::String=""; data=[], kw...) = nearneighbor(cmd0, arg1; data=data, kw...)