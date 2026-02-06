"""
	segy(cmd0::String=""; kwargs...)

Plot a SEGY file as a seismic data image.
"""
segy!(cmd0::String; kwargs...) = segy_helper(cmd0; first=false, kwargs...)
function segy(cmd0::String; first=true, kw...)
	#(cmd0 === "") && error("Missing input segY file name to run this module.")
	d, K, O = init_module(first==1, kw...)		# Also checks if the user wants ONLY the HELP mode
	segy_helper(cmd0, O, K, d)
end

# ---------------------------------------------------------------------------------------------------
function segy_helper(cmd0::String, O::Bool, K::Bool, d::Dict{Symbol, Any})

	cmd = ((IamModern[]) ? "segy "  : "pssegy ") * cmd0
	cmd = parse_BJR(d, cmd, "", O, "")[1]
	cmd = parse_common_opts(d, cmd, [:V_params :UVXY :p :t :params]; first=!O)[1]
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

	((r = check_dbg_print_cmd(d, cmd)) !== nothing) && return r
	!isfile(cmd0) && error("segY file $cmd0 does not exist.")	# Testing here only allows pass a Vd=2 for test parsing
	finish_PS_module(d, cmd, "", K, O, true)
end

# ---------------------------------------------------------------------------------------------------
"""
	segyz(cmd0::String=""; kwargs...)

Plot a SEGY file in 3-D as a seismic data image.
"""
segyz!(cmd0::String; kwargs...) = segyz_helper(cmd0; first=false, kwargs...)
function segyz(cmd0::String; first=true, kw...)
	d, K, O = init_module(first==1, kw...)		# Also checks if the user wants ONLY the HELP mode
	segyz_helper(cmd0, O, K, d)
end

# ---------------------------------------------------------------------------------------------------
function segyz_helper(cmd0::String, O::Bool, K::Bool, d::Dict{Symbol, Any})

	cmd = ((IamModern[]) ? "segyz "  : "pssegyz ") * cmd0
	cmd = parse_BJR(d, "", "", O, "")[1]
	cmd = parse_common_opts(d, cmd, [:V_params :UVXY :p :t :params], first=!O)[1]
	cmd, opt_JZ = parse_JZ(d, cmd, O=O, is3D=true)
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

	((r = check_dbg_print_cmd(d, cmd)) !== nothing) && return r
	!isfile(cmd0) && error("segY file $cmd0 does not exist.")	# Testing here only allows pass a Vd=2 for test parsing
	finish_PS_module(d, cmd, "", K, O, true)
end

# ---------------------------------------------------------------------------------------------------
# Shared options between segy and segyz
function segy_common(d::Dict, cmd::String)

	((s = hlp_desnany_str(d, [:F :fill :color])) !== "") && (cmd *= " -F" * s)		# -F fill color

	cmd = parse_these_opts(cmd, d, [[:A :byteswap :swap], [:C :clip], [:D :dev :deviation], [:I :negative :fillneg],
	                                [:L :nsamp :nsamples], [:M :ntraces], [:N :normalize :norm], [:W :wiggle], [:Z :skipzero :nozero]])
	!contains(cmd, " -D") && error("Option 'D' or 'dev' or 'deviation' is required")
	!contains(cmd, " -F") && !contains(cmd, " -W") && (cmd *= " -W")

	if ((val = find_in_dict(d, [:Q :adjust])[1]) !== nothing)		# -Q adjustments
		if isa(val, NamedTuple)
			for key = keys(val)
				key in (:b, :bias)   && (cmd *= " -Qb" * string(val[key]))
				key in (:i, :dpi)    && (cmd *= " -Qi" * string(val[key]))
				key in (:u, :redvel) && (cmd *= " -Qu" * string(val[key]))
				key in (:x, :xmult)  && (cmd *= " -Qx" * string(val[key]))
				key in (:y, :dy)     && (cmd *= " -Qy" * string(val[key]))
			end
		else
			cmd *= " -Q" * arg2str(val)
		end
	end

	return cmd
end
