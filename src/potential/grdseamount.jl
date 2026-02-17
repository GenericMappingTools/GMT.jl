"""
    grdseamount(cmd0::String="", arg1=nothing; kwargs...)

Create synthetic seamounts (Gaussian, parabolic, polynomial, cone or disc; circular or elliptical).
"""
grdseamount(cmd0::String; kw...) = grdseamount_helper(cmd0, nothing; kw...)
grdseamount(arg1; kw...)         = grdseamount_helper("", arg1; kw...)

function grdseamount_helper(cmd0::String, arg1; kw...)
	d = init_module(false, kw...)[1]		# Also checks if the user wants ONLY the HELP mode
	(cmd0 != "") && (arg1 = gmtread(cmd0))
	isa(arg1, Matrix{<:Real}) && (arg1 = mat2ds(Float64.(arg1)))
	grdseamount_helper(arg1, d)
end

# ---------------------------------------------------------------------------------------------------
function grdseamount_helper(arg1::GDtype, d::Dict{Symbol,Any})

	arg2, arg3 = nothing, nothing
	cmd::String = parse_common_opts(d, "", [:G :RIr :V_params :bi :e :f :h :i :r :yx])[1]
	cmd = add_opt(d, cmd, "C", [:C :shapefun :shape_fun], (gaussian="_g", polynomial="_o", cone="_c", parabola="_p", disk="_d"))
	cmd = add_opt(d, cmd, "H", [:H :rhofun :rho_fun], (height="", low_high_rho="", boost="_+b", pressure_rho="_+d", power="_+p"))

	cmd = parse_these_opts(cmd, d, [[:A :mask], [:D :unit], [:E :elliptic], [:F :flattening], [:L :list], [:M :listfiles],
                                    [:N :norm], [:Q :bmode], [:S :landslides :land_slides], [:T :timeinc :time_inc], [:Z :level]])
	(!occursin(" -G", cmd) && !occursin(" -L", cmd)) && (cmd *= " -G")

	if ((val = find_in_dict(d, [:K :rhomodel :rho_model])[1]) !== nothing)
		if     (isa(val, GMTgrid))  arg2 = val;		cmd *= " -K"
		elseif (isa(val, StrSymb))  cmd *= string(" -K", val)
		else   error("Invalid type $(typeof(val)) for option 'rhomodel'")
		end
	end
	if ((val = find_in_dict(d, [:W :averho :ave_rho])[1]) !== nothing)
		if     (isa(val, GMTgrid))  arg2 === nothing ? arg2 = val : arg3 = val;	cmd *= " -W"
		elseif (isa(val, StrSymb))  cmd *= string(" -W", val)
		else   error("Invalid type $(typeof(val)) for option 'averho'")
		end
	end

	cmd = "grdseamount " * cmd
	((r = check_dbg_print_cmd(d, cmd)) !== nothing) && return r
	prep_and_call_finish_PS_module(d, cmd, "", true, false, false, arg1, arg2, arg3)
end
