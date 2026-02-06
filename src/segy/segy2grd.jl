"""
	segy2grd(cmd0::String=""; kwargs...)

Create a grid file from an ideographic SEGY file.
"""
function segy2grd(cmd0::String; kwargs...)
	d = init_module(false, kwargs...)[1]
	segy2grd_helper(cmd0, d)
end

# ---------------------------------------------------------------------------------------------------
function segy2grd_helper(cmd0::String, d::Dict{Symbol, Any})

	cmd, opt_R = parse_R(d, "")[1:2]
	(opt_R === "") && error("Missing R or region option.")
	cmd = parse_common_opts(d, cmd, [:I :V_params :bi :di :r :yx])[1]
	!contains(cmd, " -I") && error("Option 'I' or 'inc' is required")

	# -A add up or count
	if ((val = find_in_dict(d, [:A :add :count])[1]) !== nothing)
		if val == :n || val == :count
			cmd *= " -An"
		elseif val == :z || val == :sum
			cmd *= " -Az"
		elseif isa(val, Bool) && val
			cmd *= " -A"
		else
			cmd *= " -A" * arg2str(val)
		end
	end

	cmd = parse_these_opts(cmd, d, [[:D :metadata :header], [:G :outgrid :save], [:L :nsamp :nsamples], [:M :ntrace]])

	if ((val = find_in_dict(d, [:Q :adjust])[1]) !== nothing)	# -Q scale or sample interval
		if isa(val, NamedTuple)
			for key = keys(val)
				key in (:x, :xscale) && (cmd *= " -Qx" * string(val[key]))
				key in (:y, :sint)   && (cmd *= " -Qy" * string(val[key]))
			end
		else
			cmd *= " -Q" * arg2str(val)
		end
	end

	# -S variable spacing
	if ((val = find_in_dict(d, [:S :spacing :varspacing])[1]) !== nothing)
		sp_map = Dict(:c => "c", :cdp => "c", :o => "o", :offset => "o")
		if isa(val, Symbol)
			cmd *= " -S" * get(sp_map, val, string(val))
		elseif isa(val, NamedTuple)
			haskey(val, :cdp) && val.cdp && (cmd *= " -Sc")
			haskey(val, :offset) && val.offset && (cmd *= " -So")
			haskey(val, :byte) && (cmd *= " -Sb" * string(val.byte))
		else
			cmd *= " -S" * arg2str(val)
		end
	end

	cmd = "segy2grd " * cmd0 * cmd
	((r = check_dbg_print_cmd(d, cmd)) !== nothing) && return r
	!isfile(cmd0) && error("segY file $cmd0 does not exist.")	# Testing here only allows pass a Vd=2 for test parsing
	gmt(cmd, arg1)
end
