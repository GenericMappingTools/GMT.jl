"""
Connect individual lines whose end points match within tolerance

To see the documentation, type: ``@? gmtconnect``
"""
function gmtconnect(cmd0::String="", arg1=nothing, arg2=nothing; kw...)
	d = init_module(false, kw...)[1]
	gmtconnect(cmd0, arg1, d)
end
function gmtconnect(cmd0::String, arg1, d::Dict{Symbol, Any})

	cmd, = parse_common_opts(d, "", [:V_params :b :d :e :f :g :h :i :o :yx])
	cmd  = parse_these_opts(cmd, d, [[:C :closed], [:D :dump], [:L :links :linkfile], [:Q :list :listfile], [:T :tolerance]])

	common_grd(d, cmd0, cmd, "gmtconnect ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtconnect(arg1, arg2=nothing; kw...) = gmtconnect("", arg1, arg2; kw...)