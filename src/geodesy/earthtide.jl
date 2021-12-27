"""
	earthtide(cmd0::String=""; kwargs...)

Compute grids or time-series of solid Earth tides.

Full option list at [`earthtide`]($(GMTdoc)earthtide.html)

```julia
	G = earthtide();
	imshow(G)
```
"""
function earthtide(cmd0::String=""; kwargs...)

	(cmd0 != "") && return monolitic("earthtide", cmd0)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	
	cmd = "earthtide " * parse_common_opts(d, "", [:R :I :V_params :r])[1]
	cmd = parse_opt_range(d, cmd, "T")[1]
	if ((opt_S = add_opt(d, "", "S", [:S :sun_moon])) != "")
		return finish_PS_module(d, cmd * opt_S, "", true, false, false)
	elseif ((opt_L = add_opt(d, "", "L", [:L :location])) != "")
		return finish_PS_module(d, cmd * opt_L, "", true, false, false)
	end

	cmd = ((opt_C = add_opt(d, "", "C", [:C :components])) != "") ? cmd * opt_C : cmd * " -Cz"
	opt_G = add_opt(d, "", "G", [:G :grid :outgrid])
	(length(opt_G) > 3) && (cmd *= opt_G)		# G=true will give " -G", which we'll ignore  (Have to)

	return (dbg_print_cmd(d, cmd) !== nothing) ? cmd : gmt(cmd)
end