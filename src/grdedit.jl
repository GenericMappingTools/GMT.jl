"""
Reads the header information in a binary 2-D grid file and replaces the information with
values provided on the command line.

If single input is a G GMTgrid object, it will update the z_min|max values of the G.range member

To see the documentation, type: ``@? grdedit``
"""
grdedit(cmd0::String; kw...) = grdedit_helper(cmd0, nothing; kw...)
grdedit(arg1; kw...)         = grdedit_helper("", arg1; kw...)

# ---------------------------------------------------------------------------------------------------
function grdedit_helper(cmd0::String, arg1; kw...)
	(isa(arg1, GMTgrid) && length(kw) == 0) && (arg1.range[5:6] .= extrema(arg1); return arg1)  # Update the z_min|max
	d = init_module(false, kw...)[1]
	grdedit_helper(cmd0, arg1, d)
end
function grdedit_helper(cmd0::String, arg1, d::Dict{Symbol, Any})

	arg2 = nothing

	cmd, = parse_common_opts(d, "", [:G :R :V_params :bi :di :e :f :w :yx])
	cmd = parse_J(d, cmd, default=" ")[1]       # No default J here.
	cmd  = parse_these_opts(cmd, d, [[:A :adjust_inc], [:C :clear_history], [:D :header :metadata], [:E :flip],
	                                 [:L :adust_lon], [:S :wrap], [:T :toggle :toggle_reg]])
	cmd, args, n, = add_opt(d, cmd, "N", [:N :replace], :data, Array{Any,1}([arg1, arg2]), (x="",))
	if (n > 0)  arg1, arg2 = args[:]  end

    (arg1 !== nothing) && (wkt = arg1.wkt; arg1.wkt = ""; proj4 = arg1.proj4; arg1.proj4 = "")  # GMT bug fixed 18-4-2023
	G = common_grd(d, cmd0, cmd, "grdedit ", arg1, arg2)		# Finish build cmd and run it
    (arg1 !== nothing) && (G.wkt = wkt; G.proj4 = proj4)
    G
end
