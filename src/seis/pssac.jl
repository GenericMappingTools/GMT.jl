"""
	sac(cmd0::String="", arg1=nothing; kwargs...)

Plot seismograms in SAC format.

See full GMT docs at [`sac`]($(GMTdoc)supplements/seis/sac.html)

Parameters
----------

- $(_opt_J)
- $(_opt_R)
- $(_opt_B)

- **C** | **timewindow** | **cut** :: [Type => Str | Tuple]

    Read and plot seismograms in timewindow between t0 and t1 only.
    Times are relative to reference time set by **T**.
- **D** | **offset** :: [Type => Str | Number | Tuple]

    Offset seismogram positions by dx/dy. If dy is omitted it equals dx.
- **E** | **profile** | **profile_type** :: [Type => Str | Symbol]

    Choose profile type: :a|:azimuth, :b|:back_azimuth, :k|:km, :d|:degree,
    :n|:number, :u|:user. Append n for :number or :user types.
- **F** | **preprocess** :: [Type => Str | Tuple | Bool]

    Data preprocessing: :i|:integrate, :q|:square, :r|:remove_mean.
    Options are stackable, e.g., preprocess=(:i,:r) or preprocess="ir"
- **G** | **fill** :: [Type => Str | NamedTuple]

    Paint positive or negative portion of traces.
    fill=(positive=true, color=:red, zero=0, timewindow=(t0,t1))
    fill=(negative=true, color=:blue)
- **M** | **size** | **vertical_scale** :: [Type => Str | Number | Tuple]

    Vertical scaling. size=value or size=(value, :unit) or size=(value, :unit, alpha)
- **Q** | **vertical** :: [Type => Bool]

    Plot traces vertically.
- **S** | **timescale** | **time_scale** :: [Type => Str | Number]

    Set time scale in seconds per unit. Use negative value or append 'i' for inverse.
- **T** | **time** | **time_align** :: [Type => Str | NamedTuple]

    Time alignment. time=(reduce=vel, shift=sec, mark=n)
    or time="+r4+s-5+t2"
- **W** | **pen** :: [Type => Str | Tuple]

    Set pen attributes for all traces.
- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)
- $(_opt_h)
- $(_opt_p)
- $(_opt_t)

Example: Plot SAC files
```julia
    sac("*.sac", region=(0,100,-1,1), proj=:X10c/5c, show=true)
```
"""
sac(cmd0::String; kwargs...)  = sac_helper(cmd0; kwargs...)
sac!(cmd0::String; kwargs...) = sac_helper(cmd0; first=false, kwargs...)
function sac_helper(cmd0; first=true, kw...)
	d, K, O = init_module(first, kw...)		# Also checks if the user wants ONLY the HELP mode
	sac_helper(cmd0, O, K, d)
end

# ---------------------------------------------------------------------------------------------------
function sac_helper(cmd0::String, O::Bool, K::Bool, d::Dict{Symbol, Any})
	proggy = (IamModern[]) ? "sac " : "pssac "

	cmd, _, _, opt_R = parse_BJR(d, "", "", O, " -J$(DEF_FIG_SIZE)")
	cmd, = parse_common_opts(d, cmd, [:UVXY :c :h :p :t :params]; first=!O)

	cmd = parse_these_opts(cmd, d, [[:C :timewindow :cut], [:Q :vertical]])
	((str = hlp_desnany_arg2str(d, [:D :offset])) !== "") && (cmd *= " -D" * str)	# -D offset
	((str = hlp_desnany_arg2str(d, [:S :timescale :time_scale])) !== "") && (cmd *= " -S" * str)	# -S time scale
	((str = hlp_desnany_arg2str(d, [:M :size :vertical_scale])) !== "") && (cmd *= " -M" * str)		# -M vertical scale

	# -E profile type
	if ((val = find_in_dict(d, [:E :profile :profile_type])[1]) !== nothing)
		profile_map = Dict(:a => "a", :azimuth => "a", :b => "b", :back_azimuth => "b",
		                   :k => "k", :km => "k", :d => "d", :degree => "d",
		                   :n => "n", :number => "n", :u => "u", :user => "u")
		if isa(val, Symbol)
			cmd *= " -E" * get(profile_map, val, string(val))
		elseif isa(val, Tuple)
			cmd *= " -E" * get(profile_map, val[1], string(val[1])) * string(val[2])
		else
			cmd *= " -E" * string(val)
		end
	end

	# -F preprocess
	if ((val = find_in_dict(d, [:F :preprocess])[1]) !== nothing)
		pre_map = Dict(:i => "i", :integrate => "i", :q => "q", :square => "q",
		               :r => "r", :remove_mean => "r")
		if isa(val, Symbol)
			cmd *= " -F" * get(pre_map, val, string(val))
		elseif isa(val, Tuple)
			cmd *= " -F" * join([get(pre_map, v, string(v)) for v in val])
		elseif isa(val, Bool) && val
			cmd *= " -F"
		else
			cmd *= " -F" * string(val)
		end
	end

	# -G fill
	if ((val = find_in_dict(d, [:G :fill])[1]) !== nothing)
		if isa(val, NamedTuple)
			opt_G = " -G"
			haskey(val, :positive) && val.positive && (opt_G *= "p")
			haskey(val, :negative) && val.negative && (opt_G *= "n")
			haskey(val, :color) && (opt_G *= "+g" * get_color(val.color))
			haskey(val, :fill) && (opt_G *= "+g" * get_color(val.fill))
			haskey(val, :zero) && (opt_G *= "+z" * string(val.zero))
			haskey(val, :timewindow) && (opt_G *= "+t" * arg2str(val.timewindow, '/'))
			cmd *= opt_G
		else
			cmd *= " -G" * arg2str(val)
		end
	end

	# -T time alignment
	if ((val = find_in_dict(d, [:T :time :time_align])[1]) !== nothing)
		if isa(val, NamedTuple)
			opt_T = " -T"
			haskey(val, :reduce) && (opt_T *= "+r" * string(val.reduce))
			haskey(val, :shift) && (opt_T *= "+s" * string(val.shift))
			haskey(val, :mark) && (opt_T *= "+t" * string(val.mark))
			cmd *= opt_T
		else
			cmd *= " -T" * arg2str(val)
		end
	end

	# -W pen
	cmd *= opt_pen(d, 'W', [:W :pen])

	cmd = read_data(d, cmd0, cmd, nothing, opt_R)[1]

	cmd = proggy * cmd
	((r = check_dbg_print_cmd(d, cmd)) !== nothing) && return r
	prep_and_call_finish_PS_module(d, cmd, "", K, O, true, nothing)
end

# ---------------------------------------------------------------------------------------------------
const pssac  = sac			# Alias
const pssac! = sac!			# Alias
