"""
	earthtide(; kwargs...)

Compute grids or time-series of solid Earth tides.

See full GMT docs at [`earthtide`]($(GMTdoc)supplements/geodesy/earthtide.html)

```julia
	G = earthtide();
	imshow(G)
```
"""
function earthtide(; kw...)
	d = init_module(false, kw...)[1]
	earthtide(d)
end
function earthtide(d::Dict{Symbol, Any})

	cmd = "earthtide " * parse_common_opts(d, "", [:R :I :V_params :r])[1]
	cmd = parse_opt_range(d, cmd, "T")[1]
	if ((opt_S = add_opt(d, "", "S", [:S :sun_moon])) != "")
		cmd *= opt_S
		((r = check_dbg_print_cmd(d, cmd)) !== nothing) && return r
		return gmt(cmd)
	elseif ((opt_L = add_opt(d, "", "L", [:L :location])) != "")
		cmd *= opt_L
		((r = check_dbg_print_cmd(d, cmd)) !== nothing) && return r
		R = gmt(cmd)
		R.colnames = ["Time", "East", "North", "Vertical"]
		R.attrib = Dict("Timecol" => "1")
		return R
	end

	cmd = ((opt_C = add_opt(d, "", "C", [:C :component :components])) != "") ? cmd * opt_C : cmd * " -Cz"
	opt_G = add_opt(d, "", "G", [:G :grid :outgrid])
	(length(opt_G) > 3) && (cmd *= opt_G)		# G=true will give " -G", which we'll ignore  (Have to)

	return (dbg_print_cmd(d, cmd) !== nothing) ? cmd : gmt(cmd)
end