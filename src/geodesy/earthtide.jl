"""
	earthtide(cmd0::String=""; kwargs...)

Compute grids or time-series of solid Earth tides.

See full GMT (not the `GMT.jl` one) docs at [`earthtide`]($(GMTdoc)supplements/geodesy/earthtide.html)

```julia
	G = earthtide();
	imshow(G)
```
"""
function earthtide(cmd0::String=""; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd = "earthtide " * parse_common_opts(d, "", [:R :I :V_params :r])[1]
	cmd = parse_opt_range(d, cmd, "T")[1]
	if ((opt_S = add_opt(d, "", "S", [:S :sun_moon])) != "")
		(dbg_print_cmd(d, cmd) !== nothing) && return cmd * opt_S
		return finish_PS_module(d, cmd * opt_S, "", true, false, false)
	elseif ((opt_L = add_opt(d, "", "L", [:L :location])) != "")
		(dbg_print_cmd(d, cmd) !== nothing) && return cmd * opt_L
		R = finish_PS_module(d, cmd * opt_L, "", true, false, false)
		R.colnames = ["Time", "East", "North", "Vertical"]
		R.attrib = Dict("Timecol" => "1")
		return R
	end

	cmd = ((opt_C = add_opt(d, "", "C", [:C :components])) != "") ? cmd * opt_C : cmd * " -Cz"
	opt_G = add_opt(d, "", "G", [:G :grid :outgrid])
	(length(opt_G) > 3) && (cmd *= opt_G)		# G=true will give " -G", which we'll ignore  (Have to)

	return (dbg_print_cmd(d, cmd) !== nothing) ? cmd : gmt(cmd)
end