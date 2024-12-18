"""
    nearneighbor(cmd0::String="", arg1=nothing; kwargs...)

Reads arbitrarily located (x,y,z[,w]) triples [quadruplets] and uses a nearest neighbor algorithm
to assign an average value to each node that have one or more points within a radius centered on the node.
The average value is computed as a weighted mean of the nearest point from each sector inside the search
radius. The weighting function used is w(r) = 1 / (1 + d ^ 2), where d = 3 * r / search_radius and r is
distance from the node. This weight is modulated by the weights of the observation points [if supplied].
	
Parameters
----------

- $(opt_I)
- **N** | **sectors** | **nn** | **nearest** :: [Type => Number | Str | Bool (for nn or nearest)]

    The circular area centered on each node is divided into `sectors` sectors.
- $(_opt_R)
- **S** | **search_radius** :: [Type => Number]

    Sets the search_radius that determines which data points are considered close to a node.

- **E** | **empty** :: [Type => Bool]

    Set the value assigned to empty nodes when G is set [NaN].
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = nearneighbor(....) form.
- $(opt_V)
- **W** | **weights** :: [Type => Bool]

    Input data have a 4th column containing observation point weights.
- $(_opt_bi)
- $(_opt_di)
- $(opt_e)
- $(_opt_f)
- $(_opt_h)
- $(_opt_i)
- $(opt_n)
- $(opt_r)
- $(opt_w)
- $(opt_swap_xy)

To see the full documentation type: ``@? nearneighbor``
"""
nearneighbor(cmd0::String; kwargs...) = nearneighbor_helper(cmd0, nothing; kwargs...)
nearneighbor(arg1; kwargs...)         = nearneighbor_helper("", arg1; kwargs...)
nearneighbor(; kwargs...)             = nearneighbor_helper("", nothing; kwargs...)		# To allow nearneighbor(data=..., ...)

# ---------------------------------------------------------------------------------------------------
function nearneighbor_helper(cmd0::String, arg1; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	d = seek_auto_RI(d, cmd0, arg1)				# If -R -I (or one of them) not set, guess.
	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :bi :di :e :f :h :i :n :w :yx])
	cmd  = parse_these_opts(cmd, d, [[:E :empty], [:S :search_radius], [:W :weights], [:A]])
	cmd  = add_opt(d, cmd, "N", [:N :sectors], (n="", min_sectors="+m"))
	opt  = add_opt(d, "", "N", [:N :nn :nearest])
	if (opt != "")  cmd *= " -Nn"  end

	common_grd(d, cmd0, cmd, "nearneighbor ", arg1)		# Finish build cmd and run it
end
