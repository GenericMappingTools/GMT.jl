"""
	velo(cmd0::String="", arg1=nothing; kwargs...)

Plot velocity vectors, crosses, and wedges.

See full GMT docs at [`velo`]($(GMTdoc)supplements/seis/velo.html)

```julia
    velo(mat2ds([0. -8 0 0 4 6 0.5; -8 5 3 3 0 0 0.5], ["4x6", "3x3"]), pen=(0.6,:red), fill_wedges=:green, outlines=true, Se="0.2/0.39/18", arrow="0.3c+p1p+e+gred", region=(-15,10,-10,10), show=1)
```
"""
velo!(cmd0::String="", arg1=nothing; kw...) = velo(cmd0, arg1; first=false, kw...)
velo(arg1; kw...) = velo("", arg1; first=true, kw...)
velo!(arg1; kw...) = velo("", arg1; first=false, kw...)
function velo(cmd0::String="", arg1=nothing; first=true, kw...)
	d, K, O = init_module(first, kw...)		# Also checks if the user wants ONLY the HELP mode
	velo(cmd0, arg1, O, K, d)
end
function velo(cmd0::String, arg1, O::Bool, K::Bool, d::Dict{Symbol, Any})

    proggy = (IamModern[]) ? "velo "  : "psvelo "

	cmd, _, _, opt_R = parse_BJR(d, "", "", O, " -JX15cd/0d")
	cmd, = parse_common_opts(d, cmd, [:UVXY :di :e :p :t :params]; first=!O)

	if ((val = find_in_dict(d, [:A :arrow :arrows])[1]) !== nothing)
		cmd = (isa(val, String)) ? cmd * " -A" * val : cmd * " -A" * vector_attrib(val) 
	end

	cmd = add_opt_fill(cmd, d, [:E :fill_wedges :uncertaintyfill], 'E')
	cmd = add_opt_fill(cmd, d, [:G :fill :fill_symbols], 'G')
	cmd = parse_these_opts(cmd, d, [[:D :sigma_scale], [:L :outlines], [:N :no_clip :noclip]])

	if     (haskey(d, :Se) || haskey(d, :velo_NE))      symbs = [:Se :vel_NE]
	elseif (haskey(d, :Sn) || haskey(d, :aniso))        symbs = [:Sn :barscale]
	elseif (haskey(d, :Sr) || haskey(d, :velo_rotated)) symbs = [:Sr :vel_rotated]
	elseif (haskey(d, :Sw) || haskey(d, :wedges))       symbs = [:Sw :wedges]
	elseif (haskey(d, :Sx) || haskey(d, :strain))       symbs = [:Sx :strain]
	elseif (SHOW_KWARGS[])  symbs = [:Se :velo_NE :Sn :aniso :Sr :velo_rotated :Sw :wedges :Sx :strain]
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

const psvelo  = velo 			# Alias
const psvelo! = velo!			# Alias