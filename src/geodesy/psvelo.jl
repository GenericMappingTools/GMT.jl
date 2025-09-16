"""
	velo(cmd0::String="", arg1=nothing; kwargs...)

Plot velocity vectors, crosses, and wedges.

See full GMT (not the `GMT.jl` one) docs at [`velo`]($(GMTdoc)supplements/seis/velo.html)

```julia
    velo(mat2ds([0. -8 0 0 4 6 0.5; -8 5 3 3 0 0 0.5], ["4x6", "3x3"]), pen=(0.6,:red), fill_wedges=:green, outlines=true, Se="0.2/0.39/18", arrow="0.3c+p1p+e+gred", region=(-15,10,-10,10), show=1)
```
"""
function velo(cmd0::String="", arg1=nothing; first=true, kwargs...)

    proggy = (IamModern[1]) ? "velo "  : "psvelo "

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd, _, _, opt_R = parse_BJR(d, "", "", O, " -JX12cd/0d")
	cmd, = parse_common_opts(d, cmd, [:UVXY :di :e :p :t :params]; first=first)

	if ((val = find_in_dict(d, [:A :arrow])[1]) !== nothing)
		cmd = (isa(val, String)) ? cmd * " -A" * val : cmd * " -A" * vector_attrib(val) 
	end

	cmd = add_opt_fill(cmd, d, [:E :fill_wedges], 'E')
	cmd = add_opt_fill(cmd, d, [:G :fill :fill_symbols], 'G')
	cmd = parse_these_opts(cmd, d, [[:D :sigma_scale], [:L :outlines], [:N :no_clip :noclip]])

	if     (haskey(d, :Se) || haskey(d, :vel_NE))       symbs = [:Se :vel_NE]
	elseif (haskey(d, :Sn) || haskey(d, :barscale))     symbs = [:Sn :barscale]
	elseif (haskey(d, :Sr) || haskey(d, :vel_rotated))  symbs = [:Sr :vel_rotated]
	elseif (haskey(d, :Sw) || haskey(d, :wedges))       symbs = [:Sw :wedges]
	elseif (haskey(d, :Sx) || haskey(d, :cross_scale))  symbs = [:Sx :cross_scale]
	elseif (SHOW_KWARGS[1])  symbs = [:Se :vel_NE :Sn :barscale :Sr :vel_rotated :Sw :wedges :Sx :cross_scale]
	else  error("Must select one convention (S options. Run gmthelp(velo) to learn about them)")
	end
	cmd = add_opt(d, cmd, string(symbs[1]), symbs)
	cmd *= opt_pen(d, 'W', [:W :pen])

	# If file name sent in, read it and compute a tight -R if it was not provided 
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)
	cmd = proggy * cmd
	((r = check_dbg_print_cmd(d, cmd)) !== nothing) && return r
	prep_and_call_finish_PS_module(d, cmd, "", K, O, true, arg1)
end

# ---------------------------------------------------------------------------------------------------
velo!(cmd0::String="", arg1=nothing; kw...) = velo(cmd0, arg1; first=false, kw...)
velo(arg1; kw...) = velo("", arg1; first=true, kw...)
velo!(arg1; kw...) = velo("", arg1; first=false, kw...)

const psvelo  = velo 			# Alias
const psvelo! = velo!			# Alias