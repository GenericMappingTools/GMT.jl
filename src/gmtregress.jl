"""
Linear regression of 1-D data sets.

To see the documentation, type: ``@? regress``
"""
function regress(cmd0::String="", arg1=nothing; kw...)
	d = init_module(false, kw...)[1]
	regress(cmd0, arg1, d)
end
function regress(cmd0::String, arg1, d::Dict{Symbol, Any})

	cmd, = parse_common_opts(d, "", [:V_params :b :d :e :g :h :i :o :w :yx])
    cmd  = parse_these_opts(cmd, d, [[:A :all_slopes], [:C :ci :cl :confidence_level], [:E :regression_type], [:N :norm],
                                     [:F :column_combination], [:S :restrict], [:T :equi_space], [:W :weights :weighted]])

	common_grd(d, cmd0, cmd, "gmtregress ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
regress(arg1; kw...) = regress("", arg1; kw...)

gmtregress = regress 		# Alias