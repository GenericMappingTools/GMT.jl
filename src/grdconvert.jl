"""
	grdconvert(fname::AbstractString; kwargs...)

"""
# ---------------------------------------------------------------------------------------------------
function grdconvert(cmd0::AbstractString; kw...)::Union{Nothing, GMTgrid, String}
	d = init_module(false, kw...)[1]
	grdconvert(cmd0, d)
end
function grdconvert(cmd0::AbstractString, d::Dict{Symbol, Any})::Union{Nothing, GMTgrid, String}
	cmd::String, opt_R::String = parse_R(d, "")
    cmd, = parse_common_opts(d, cmd, [:G :V_params :f])
	cmd = parse_these_opts(cmd, d, [[:C :cmdhist], [:N :no_header], [:Z :scale]])
	R = common_grd(d, cmd0, cmd, "grdconvert ", nothing)
	(R !== nothing && ((prj = planets_prj4(cmd0)) != "")) && (R.proj4 = prj)	# Get cached (@moon_..., etc) planets proj4
	return R
end
