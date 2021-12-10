"""
    nearneighbor(cmd0::String="", arg1=nothing; kwargs...)

Reads arbitrarily located (x,y,z[,w]) triples [quadruplets] and uses a nearest neighbor algorithm
to assign an average value to each node that have one or more points within a radius centered on the node.
The average value is computed as a weighted mean of the nearest point from each sector inside the search
radius. The weighting function used is w(r) = 1 / (1 + d ^ 2), where d = 3 * r / search_radius and r is
distance from the node. This weight is modulated by the weights of the observation points [if supplied].
	
Full option list at [`nearneighbor`]($(GMTdoc)nearneighbor.html)

Parameters
----------

- $(GMT.opt_I)
    ($(GMTdoc)nearneighbor.html#i)
- **N** | **sectors** | **nn** | **nearest** :: [Type => Number | Str | Bool (for nn or nearest)]

    The circular area centered on each node is divided into `sectors` sectors.
    ($(GMTdoc)nearneighbor.html#n)
- $(GMT.opt_R)
- **S** | **search_radius** :: [Type => Number]

    Sets the search_radius that determines which data points are considered close to a node.
    ($(GMTdoc)nearneighbor.html#s)

- **E** | **empty** :: [Type => Bool]

    Set the value assigned to empty nodes when G is set [NaN].
    ($(GMTdoc)nearneighbor.html#e)
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = nearneighbor(....) form.
    ($(GMTdoc)nearneighbor.html#g)
- $(GMT.opt_V)
- **W** | **weights** :: [Type => Bool]

    Input data have a 4th column containing observation point weights.
    ($(GMTdoc)nearneighbor.html#w)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_n)
- $(GMT.opt_r)
- $(GMT.opt_w)
- $(GMT.opt_swap_xy)
"""
function nearneighbor(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("nearneighbor", cmd0, arg1)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :bi :di :e :f :h :i :n :w :yx])
	cmd  = parse_these_opts(cmd, d, [[:E :empty], [:S :search_radius], [:W :weights], [:A]])
	cmd  = add_opt(d, cmd, 'N', [:N :sectors], (n="", min_sectors="+m"), true)
	opt  = add_opt(d, "", 'N', [:N :nn :nearest])
	if (opt != "")  cmd *= " -Nn"  end

	#if (isa(arg1, Matrix{<:Real}))  arg1 = GMTdataset(arg1)  end      # Must find why need this
	common_grd(d, cmd0, cmd, "nearneighbor ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
nearneighbor(arg1, cmd0::String=""; kw...) = nearneighbor(cmd0, arg1; kw...)