"""
	segy2grd(cmd0::String="", arg1=nothing; kwargs...)

Create a grid file from an ideographic SEGY file.
"""
segy2grd(cmd0::String=""; kwargs...) = segy2grd_helper(cmd0, nothing; kwargs...)
segy2grd(arg1; kwargs...)            = segy2grd_helper("", arg1; kwargs...)

# ---------------------------------------------------------------------------------------------------
function segy2grd_helper(cmd0::String, arg1; kwargs...)
	d = init_module(false, kwargs...)[1]

	cmd, opt_R = parse_R(d, "")[1:2]
	cmd = parse_common_opts(d, cmd, [:I :V_params :bi :di :r :yx])[1]

	# -G output grid (required)
	cmd = add_opt(d, cmd, "G", [:G :outgrid :save])

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

	# -D grid metadata
	cmd = add_opt(d, cmd, "D", [:D :metadata :header])

	# -L number of samples
	cmd = add_opt(d, cmd, "L", [:L :nsamp :nsamples])

	# -M number of traces
	cmd = add_opt(d, cmd, "M", [:M :ntraces])

	# -Q scale or sample interval
	if ((val = find_in_dict(d, [:Q :adjust])[1]) !== nothing)
		if isa(val, NamedTuple)
			haskey(val, :x) && (cmd *= " -Qx" * string(val.x))
			haskey(val, :xscale) && (cmd *= " -Qx" * string(val.xscale))
			haskey(val, :y) && (cmd *= " -Qy" * string(val.y))
			haskey(val, :sint) && (cmd *= " -Qy" * string(val.sint))
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

	(cmd0 != "") && (cmd *= " " * cmd0)

	cmd = "segy2grd " * cmd
	((r = check_dbg_print_cmd(d, cmd)) !== nothing) && return r
	gmt(cmd, arg1)
end
