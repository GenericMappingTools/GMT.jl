"""
	grdgravmag3d(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

Compute the gravity/magnetic anomaly of the volume contained between a surface provided by one grid
and a plane, or between a top and a bottom surface provided by two grids.

Full option list at [`grdgravmag3d`]($(GMTdoc)grdgravmag3d.html)

Parameters
----------

- **C** | **density** :: [Type => Str | GMTgrid]

    Sets body density in SI. Provide either a constant density or a grid with a variable one.
    ($(GMTdoc)grdgravmag3d.html#c)
- **F** | **track** :: [Type => Str | Matrix | GMTdataset]

    Provide locations where the anomaly will be computed. Note this option is mutually exclusive with `outgrid`.
    ($(GMTdoc)grdgravmag3d.html#f)
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdgravmag3d(....) form.
    ($(GMTdoc)grdgravmag3d.html#g)
- **E** | **thickness** :: [Type => Number]

    Provide the layer thickness in m [Default = 500 m].
    ($(GMTdoc)grdgravmag3d.html#e)
- **H** | **mag_params** :: [Type => Number]

    Sets parameters for computation of magnetic anomaly. Alternatively, provide a magnetic intensity grid. 
    ($(GMTdoc)grdgravmag3d.html#h)
- $(GMT.opt_I)
    ($(GMTdoc)grdgravmag3d.html#i)
- **L** | **z_obs** | **observation_level** :: [Type => Number]

    Sets level of observation [Default = 0]. That is the height (z) at which anomalies are computed.
    ($(GMTdoc)grdgravmag3d.html#l)
- **Q** | **pad** :: [Type => Number]

    Extend the domain of computation with respect to output `region`.
    ($(GMTdoc)grdgravmag3d.html#q)
- $(GMT.opt_R)
- **S** | **radius** :: [Type => Number]

    Set search radius in km (valid only in the two grids mode OR when `thickness`) [Default = 30 km].
    ($(GMTdoc)grdgravmag3d.html#s)
- **Z** | **z_level** | **reference_level** :: [Type => Number]

    Level of reference plane [Default = 0].
    ($(GMTdoc)grdgravmag3d.html#z)
- $(GMT.opt_V)
- $(GMT.opt_f)
- $(GMT.opt_x)

### Example. Compute the gravity effect of the Gorringe bank.
```julia
	G = grdgravmag3d("@earth_relief_10m", region=(-12.5,-10,35.5,37.5), density=2700, inc=0.05, pad=0.5, z_level=:bottom, f=:g);
	imshow(G)
```
"""
grdgravmag3d(arg1, arg2=nothing, cmd0::String=""; kw...) = grdgravmag3d(cmd0, arg1, arg2; kw...)
function grdgravmag3d(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

	arg3, arg4 = nothing, nothing
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd::String = parse_common_opts(d, "", [:I :G :R :V_params :f :x])[1]
	cmd = parse_these_opts(cmd, d, [[:E :thickness], [:Q :pad], [:L :z_obs :observation_level], [:S :radius]])
	opt_Z = add_opt(d, "", "Z", [:Z :z_level :reference_level])
	if (opt_Z != "")
		if     (opt_Z[4] == 't')  cmd *= " -Zt"
		elseif (opt_Z[4] == 'b')  cmd *= " -Zb"
		else   cmd *= opt_Z			# Here we may have junk, but so be it.
		end
	end

	cmd, _, arg1 = find_data(d, cmd0, cmd, arg1)	# Find how data was transmitted

	val, symb = find_in_dict(d, [:H :mag_params], false)
	if (isa(val, GMTgrid))
		(arg1 === nothing) ? arg1 = val : (arg2 === nothing ? arg2 = val : arg3 = val)
		delete!(d, symb)
	else
		cmd = add_opt(d, cmd, "H", [:H :mag_params], (field_dec="", field_dip="", mag="", mag_dec="", mag_dip=""))
	end

	cmd, arg = get_opt_str_or_obj(d, cmd, [:C :density], GMTgrid)
	(arg !== nothing) &&
		(arg1 === nothing ? arg1 = arg : (arg2 === nothing ? arg2 = arg : (arg3 === nothing ? arg3 = arg : arg4 = arg)))
	(show_kwargs[1]) && print_kwarg_opts([:C :density], " Density value/gridname, or density grid")
	cmd, arg = get_opt_str_or_obj(d, cmd, [:F :track], GDtype)
	(arg !== nothing) &&
		(arg1 === nothing ? arg1 = arg : (arg2 === nothing ? arg2 = arg : (arg3 === nothing ? arg3 = arg : arg4 = arg)))
	(show_kwargs[1]) && print_kwarg_opts([:F :track], " Filename or GMTdataset with locations where to compute the anomaly")

	(!occursin(" -F", cmd) && !occursin(" -G", cmd)) && (cmd *= " -G")

	common_grd(d, cmd0, cmd, "grdgravmag3d ", arg1, arg2, arg3, arg4)		# Finish build cmd and run it
end

# --------------------------------------------------------------------------
function get_opt_str_or_obj(d::Dict, cmd::String, symbs::VMs, objtype)
	# Deal with options that may accept either a string, a number or a GMT type.
	arg = nothing
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		cmd *= string(" -", symbs[1])
		if     (isa(val, String) || isa(val, Real))  cmd *= string(val)
		elseif (isa(val, objtype))                   arg = val
		else  error("Bad data type in option $(symbs[1])")
		end
	end
	return cmd, arg
end