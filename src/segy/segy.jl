"""
	segy(cmd0::String="", arg1=nothing; kwargs...)

Plot a SEGY file as a seismic data image.
"""
segy(cmd0::String=""; kwargs...)  = segy_helper(cmd0, nothing; kwargs...)
segy(arg1; kwargs...)             = segy_helper("", arg1; kwargs...)

# ---------------------------------------------------------------------------------------------------
function segy_helper(cmd0::String, arg1; first=true, kwargs...)
	d, K, O = init_module(first, kwargs...)

	cmd, _, _, opt_R = parse_BJR(d, "", "", O, "")
	cmd, = parse_common_opts(d, cmd, [:V_params :UVXY :p :t :params], first)
	cmd = segy_common(d, cmd)

	# -E error tolerance (segy only)
	cmd = add_opt(d, cmd, "E", [:E :error])

	# -S trace location header (segy: single header)
	if ((val = find_in_dict(d, [:S :header :traceheader])[1]) !== nothing)
		hdr_map = Dict(:c => "c", :cdp => "c", :o => "o", :offset => "o")
		if isa(val, Symbol)
			cmd *= " -S" * get(hdr_map, val, string(val))
		elseif isa(val, NamedTuple)
			haskey(val, :cdp) && val.cdp && (cmd *= " -Sc")
			haskey(val, :offset) && val.offset && (cmd *= " -So")
			haskey(val, :byte) && (cmd *= " -Sb" * string(val.byte))
		else
			cmd *= " -S" * arg2str(val)
		end
	end

	# -T trace list file (segy only)
	cmd = add_opt(d, cmd, "T", [:T :tracelist :tracefile])

	(cmd0 != "") && (cmd *= " " * cmd0)

	cmd = "segy " * cmd
	finish_PS_module(d, cmd, "", K, O, true)
end

# ---------------------------------------------------------------------------------------------------
"""
	segyz(cmd0::String="", arg1=nothing; kwargs...)

Plot a SEGY file in 3-D as a seismic data image.
"""
segyz(cmd0::String=""; kwargs...)  = segyz_helper(cmd0, nothing; kwargs...)
segyz(arg1; kwargs...)             = segyz_helper("", arg1; kwargs...)

# ---------------------------------------------------------------------------------------------------
function segyz_helper(cmd0::String, arg1; first=true, kwargs...)
	d, K, O = init_module(first, kwargs...)

	cmd, _, _, opt_R = parse_BJR(d, "", "", O, "")
	cmd = parse_common_opts(d, cmd, [:Jz :V_params :UVXY :p :t :params], first)[1]
	cmd = segy_common(d, cmd)

	# -S trace location header (segyz: header_x/header_y)
	if ((val = find_in_dict(d, [:S :header :traceheader])[1]) !== nothing)
		if isa(val, Tuple) && length(val) == 2
			hdr_map = Dict(:c => "c", :cdp => "c", :o => "o", :offset => "o")
			hx = isa(val[1], Symbol) ? get(hdr_map, val[1], string(val[1])) : string(val[1])
			hy = isa(val[2], Symbol) ? get(hdr_map, val[2], string(val[2])) : string(val[2])
			cmd *= " -S" * hx * "/" * hy
		elseif isa(val, NamedTuple)
			opt_S = " -S"
			hdr_map = Dict(:c => "c", :cdp => "c", :o => "o", :offset => "o")
			if haskey(val, :x)
				opt_S *= isa(val.x, Symbol) ? get(hdr_map, val.x, string(val.x)) : string(val.x)
			end
			opt_S *= "/"
			if haskey(val, :y)
				opt_S *= isa(val.y, Symbol) ? get(hdr_map, val.y, string(val.y)) : string(val.y)
			end
			cmd *= opt_S
		else
			cmd *= " -S" * arg2str(val)
		end
	end

	(cmd0 != "") && (cmd *= " " * cmd0)

	cmd = "segyz " * cmd
	finish_PS_module(d, cmd, "", K, O, true)
end

# ---------------------------------------------------------------------------------------------------
# Shared options between segy and segyz
function segy_common(d::Dict, cmd::String)
	# -D deviation (required)
	cmd = add_opt(d, cmd, "D", [:D :dev :deviation])

	# -F fill color
	if ((val = find_in_dict(d, [:F :fill :color])[1]) !== nothing)
		if isa(val, Bool) && val
			cmd *= " -F"
		else
			cmd *= " -F" * arg2str(val)
		end
	end

	# -W wiggle trace
	cmd = parse_these_opts(cmd, d, [[:W :wiggle]])

	# -A byte swap
	cmd = parse_these_opts(cmd, d, [[:A :byteswap :swap]])

	# -C clip
	cmd = add_opt(d, cmd, "C", [:C :clip])

	# -I fill negative
	cmd = parse_these_opts(cmd, d, [[:I :negative :fillneg]])

	# -L samples per trace
	cmd = add_opt(d, cmd, "L", [:L :nsamp :nsamples])

	# -M number of traces
	cmd = add_opt(d, cmd, "M", [:M :ntraces])

	# -N normalize
	cmd = parse_these_opts(cmd, d, [[:N :normalize :norm]])

	# -Q adjustments
	if ((val = find_in_dict(d, [:Q :adjust])[1]) !== nothing)
		if isa(val, NamedTuple)
			haskey(val, :bias) && (cmd *= " -Qb" * string(val.bias))
			haskey(val, :b) && (cmd *= " -Qb" * string(val.b))
			haskey(val, :dpi) && (cmd *= " -Qi" * string(val.dpi))
			haskey(val, :i) && (cmd *= " -Qi" * string(val.i))
			haskey(val, :redvel) && (cmd *= " -Qu" * string(val.redvel))
			haskey(val, :u) && (cmd *= " -Qu" * string(val.u))
			haskey(val, :xmult) && (cmd *= " -Qx" * string(val.xmult))
			haskey(val, :x) && (cmd *= " -Qx" * string(val.x))
			haskey(val, :dy) && (cmd *= " -Qy" * string(val.dy))
			haskey(val, :y) && (cmd *= " -Qy" * string(val.y))
		else
			cmd *= " -Q" * arg2str(val)
		end
	end

	# -Z skip zero rms
	cmd = parse_these_opts(cmd, d, [[:Z :skipzero :nozero]])

	return cmd
end
