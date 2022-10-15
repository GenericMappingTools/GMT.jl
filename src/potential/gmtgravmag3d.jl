"""
	gmtgravmag3d(cmd0::String=""; kwargs...)

Compute the gravity/magnetic anomaly of a 3-D body by the method of Okabe.

Full option list at [`gmtgravmag3d`]($(GMTdoc)gmtgravmag3d.html)

Parameters
----------

- **C** | **density** :: [Type => Str | GMTgrid]

    Sets body density in SI. Provide either a constant density or a grid with a variable one.
    ($(GMTdoc)gmtgravmag3d.html#c)
- **F** | **track** :: [Type => Str | Matrix | GMTdataset]

    Provide locations where the anomaly will be computed. Note this option is mutually exclusive with `outgrid`.
    ($(GMTdoc)gmtgravmag3d.html#f)
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = gmtgravmag3d(....) form.
    ($(GMTdoc)gmtgravmag3d.html#g)
- **H** | **mag_params** :: [Type => Number]

    Sets parameters for computation of magnetic anomaly. Alternatively, provide a magnetic intensity grid. 
    ($(GMTdoc)gmtgravmag3d.html#h)
- $(GMT.opt_I)
    ($(GMTdoc)gmtgravmag3d.html#i)
- **L** | **z_obs** | **observation_level** :: [Type => Number]

    Sets level of observation [Default = 0]. That is the height (z) at which anomalies are computed.
    ($(GMTdoc)gmtgravmag3d.html#l)
- **M** | **body** :: [Type => Str | Tuple]

    Create geometric bodies and compute their grav/mag effect.
    ($(GMTdoc)gmtgravmag3d.html#m)
- $(GMT._opt_R)
- **S** | **radius** :: [Type => Number]

    Set search radius in km (valid only in the two grids mode OR when `thickness`) [Default = 30 km].
    ($(GMTdoc)gmtgravmag3d.html#s)
- **Tv** | **index** :: [Type => Str]
- **Tr** | **raw_triang** :: [Type => Str]
- **Ts** | **stl** :: [Type => Str]

    Gives names of a xyz and vertex (ndex="vert_file") files defining a close surface.
    ($(GMTdoc)gmtgravmag3d.html#t)
- **Z** | **z_level** | **reference_level** :: [Type => Number]

    Level of reference plane [Default = 0].
    ($(GMTdoc)gmtgravmag3d.html#z)

### Example
```julia
	G = gmtgravmag3d(M=(shape=:prism, params=(1,1,1,5)), inc=1.0, region="-15/15/-15/15", mag_params="10/60/10/-10/40");
	imshow(G)
```
"""
function gmtgravmag3d(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	
	cmd = parse_common_opts(d, "", [:I :R :V_params :bi :f])[1]
	cmd = parse_these_opts(cmd, d, [[:C :density], [:E :thickness], [:F :track], [:G :grid :outgrid],
	                                [:L :observation_level], [:S :radius], [:Z :reference_level]])
	cmd = add_opt(d, cmd, "H", [:H :mag_params], (field_dec="", field_dip="", mag="", mag_dec="", mag_dip=""))

	arg2 = nothing;
	if ((val = find_in_dict(d, [:Tv :index], true, "GMTdataset | Mx3 array | String")[1]) !== nothing && val != "")  opt = " -Tv"
	elseif ((val = find_in_dict(d, [:Tr :raw_triang], true, "GMTdataset | Mx3 array | String")[1]) !== nothing && val != "") opt = " -Tr"
	elseif ((val = find_in_dict(d, [:Ts :stl :STL], true, "String (file name)")[1]) !== nothing && val != "")  opt = " -Ts"
	elseif ((val = find_in_dict(d, [:M :body], false, "String | NamedTuple")[1]) !== nothing && val != "")
		cmd = add_opt(d, cmd, "M", [:M :body], (shape="+s", params=","))
		opt = " -Ts"
	elseif (show_kwargs[1])  opt = "" 
	else   error("Missing one of 'index', 'raw_triang' or 'str' data")
	end

	if (opt != " -Ts")		# The STL format can only be requested via file
		cmd *= opt
		if (isa(val, Array{<:Real}) || isa(val, GDtype))
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
	common_grd(d, cmd0, cmd, "gmtgravmag3d ", arg1, arg2)		# Finish build cmd and run it
end