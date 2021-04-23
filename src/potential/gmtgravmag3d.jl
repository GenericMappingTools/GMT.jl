"""
	gmtgravmag3d(cmd0::String=""; kwargs...)

Compute the gravity/magnetic anomaly of a 3-D body by the method of Okabe.

Full option list at [`gmtgravmag3d`]($(GMTdoc)gmtgravmag3d.html)

```julia
	G = gmtgravmag3d(M=(shape=:prism, params=(1,1,1,5)), I=1.0, R="-15/15/-15/15", H="10/60/10/-10/40");
	imshow(G)
```
"""
function gmtgravmag3d(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("gmtgravmag3d", cmd0, arg1)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	
	cmd = parse_common_opts(d, "", [:R :V_params :bi :f])[1]
	cmd = parse_these_opts(cmd, d, [[:C :density], [:E :thickness], [:F :track], [:G :grid :outgrid], [:I :inc],
	                                [:L :observation_level], [:S :radius], [:Z :reference_level]])
	cmd = add_opt(d, cmd, 'H', [:H :mag_params], (field_dec="", field_dip="", mag="", mag_dec="", mag_dip=""))

	arg2 = nothing;
	if ((val = find_in_dict(d, [:Tv :index], true, "GMTdataset | Mx3 array | String")[1]) !== nothing && val != "")  opt = " -Tv"
	elseif ((val = find_in_dict(d, [:Tr :raw_triang], true, "GMTdataset | Mx3 array | String")[1]) !== nothing && val != "") opt = " -Tr"
	elseif ((val = find_in_dict(d, [:Ts :stl :STL], true, "String (file name)")[1]) !== nothing && val != "")  opt = " -Ts"
	elseif ((val = find_in_dict(d, [:M :body], false, "String | NamedTuple")[1]) !== nothing && val != "")
		cmd = add_opt(d, cmd, 'M', [:M :body], (shape="+s", params=","))
		opt = " -Ts"
	elseif (show_kwargs[1])  opt = "" 
	else   error("Missing one of 'index', 'raw_triang' or 'str' data")
	end
	if (opt != " -Ts")		# The STL format can only be requested via file
		cmd *= opt
		if (isa(val, Array{<:Real}) || isa(val, GMTdataset) || isa(val, Vector{<:GMTdataset}))
			(arg1 === nothing) ? arg1 = val : arg2 = val		# Find the free slot
		else
			cmd *= arg2str(val)
		end
		if (opt == " -Tv")
			(!occursin(" -I", cmd)) && error("For grid output MUST specify grid increment ('I' or 'inc')")
		end
	end
	(!occursin(" -F", cmd) && !occursin(" -G", cmd)) && (cmd *= " -G")

	(opt != " -Tv") && return finish_PS_module(d, "gmtgravmag3d " * cmd, "", true, false, false, arg1, arg2)
	common_grd(d, cmd0, cmd, "gmtgravmag3d ", arg1, arg2)[2]		# Finish build cmd and run it
end