"""
	gravprisms(cmd0::String="", arg1=nothing; kwargs...)

Compute the gravity/magnetic anomaly of a 3-D body by the method of Okabe.

See full GMT docs at [`gravprisms`]($(GMTdoc)supplements/potential/gravprisms.html)

Parameters
----------

- **A** | **zup** :: [Type => Bool]

    The z-axis should be positive upwards [Default is down].
- **D** | **density** :: [Type => Str | GMTgrid]

    Sets body density in SI. Provide either a constant density or a grid with a variable one.
- **E** | **dxdy** | **xy_sides** :: [Type => Number | Tuple numbers]

    If all prisms in table have constant x/y-dimensions then they can be set here. In that case table must~
    only contain the centers of each prism and the z range
- **F** | **component** :: [Type => Str]

    Specify desired gravitational field component.
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = gravprisms(....) form.
- **H** | **radial_rho** :: [Type => Str | Tuple]

    Set reference seamount parameters for an ad-hoc variable radial density function with depth.
- $(opt_I)
- **L** | **base** :: [Type => Number ! Grid]

    Give name of the base surface grid for a layer we wish to approximate with prisms, or give a constant z-level [0].
- **M** | **units** :: [Type => Str]

    Sets distance units used. units=:horizontal to indicate that both horizontal distances are in km [m]. 
- **N** | **track** :: [Type => Str | Matrix | GMTdataset]

    Specifies individual (x, y[, z]) locations where we wish to compute the predicted value.
- $(_opt_R)
- **S** | **topography** :: [Type => Number]

    Give name of grid with the full seamount heights, either for making prisms or as required by H.
- **T** | **top** :: [Type => Number | Grid]

    Give name of the top surface grid for a layer we wish to approximate with prisms, or give a constant z-level.
- **Z** | **z_obs** | **observation_level** :: [Type => Number | Grid]

    Set observation level, either as a constant or variable by giving the name of a grid with observation levels.
- **T** | **top** :: [Type => Number | Grid]

    Give name of the top surface grid for a layer we wish to approximate with prisms, or give a constant z-level.
- **W** | **out_mean_rho** :: [Type => Str]

    Give name of an output grid with spatially varying, vertically-averaged prism densities created by C and H.
"""
function gravprisms(cmd0::String="", arg1::GDtype=GMTdataset(); kw...)
	d = init_module(false, kw...)[1]
	gravprisms(cmd0, arg1, d)
end
function gravprisms(cmd0::String, arg1::GDtype, d::Dict{Symbol, Any})

	Gs = Vector{GMTgrid}(undef, 5)
	N_used = 0
	arg2::GDtype=GMTdataset()

	function fish_grids(d, Gs, cmd, symbs, opt, N)
		if ((_val = find_in_dict(d, symbs)[1]) !== nothing)
			if (isa(_val, Real) || isa(_val, String))
				cmd *= string(" -", opt, _val)::String
			else
				isa(_val, GMTgrid) ? (Gs[N+=1] = _val; cmd *= " -D") : error("Invalid type $(typeof(_val)) for option $opt")
			end
		end
		return cmd, N
	end

	# Deal first with the options that may pass a GMTdataset (-C & -N)
	cmd = add_opt(d, "", "C", [:C :prisms], (quit="_+q", save="+w", dz="+z"))
	cmd  == "" && cmd0 == "" && isempty(arg1) && error("Missing input table describing the prisms.")
	(cmd == "" && cmd0 != "") && (arg1 = gmtread(cmd0))

	cmd::String = parse_common_opts(d, cmd, [:G :RIr :V_params :bo :d :f :i :o :r :x])[1]
	is_geog = contains(cmd, "-fg")
	cmd = parse_these_opts(cmd, d, [[:A :zup], [:E :dxdy :xy_sides], [:W :hvar_rho :avedens]])

	if ((val = find_in_dict(d, [:N :track])[1]) !== nothing)
		cmd *= " -N"	
		if (isa(val, GMTdataset) || isa(val, Matrix))
			isempty(arg1) ? (arg1 = mat2ds(val)) : (arg2 = mat2ds(val))
		else
			cmd *= string(val)
		end
	end

	# Deals with options that may pass GMTgrids or file names of them.
	cmd, N_used = fish_grids(d, Gs, cmd, [:D :density], 'D', N_used)
	cmd, N_used = fish_grids(d, Gs, cmd, [:S :topography], 'S', N_used)
	cmd, N_used = fish_grids(d, Gs, cmd, [:L :base], 'L', N_used)
	cmd, N_used = fish_grids(d, Gs, cmd, [:T :top], 'T', N_used)
	cmd, N_used = fish_grids(d, Gs, cmd, [:Z :level :reference_level], 'Z', N_used)
	deleteat!(Gs, N_used+1:length(Gs))

	opt_F = add_opt(d, "", "F", [:F :component], (faa="_f", geoid="_n", vgrad="_v"))
	valname = contains(opt_F, "Fn") ? "Geoid" : contains(opt_F, "Fv") ? "VGG" : "FAA"
	cmd *= opt_F
	cmd = add_opt(d, cmd, "H", [:H :radial_rho], (height="", low_high_rho="", boost="_+b", pressure_rho="+d", power="+p"))
	cmd = add_opt(d, cmd, "M", [:M :units], (horizontal="_h", vertical="_v"))

	(!occursin(" -N", cmd) && !occursin(" -G", cmd)) && (cmd *= " -G")
	args = isempty(Gs) ? nothing : Gs[:]

	if (!isempty(arg1) && !isempty(arg2))
		R = finish_PS_module(d, "gravprisms " * cmd, "", true, false, false, arg1, arg2, args)
	elseif (!isempty(arg1) && isempty(arg2))
		R = finish_PS_module(d, "gravprisms " * cmd, "", true, false, false, arg1, args)
	elseif (isempty(arg1) && isempty(arg2))
		R = finish_PS_module(d, "gravprisms " * cmd, "", true, false, false, args)
	else
		error("Shit, case not foreseen.")
	end
	isa(R, GMTdataset) && (R.colnames = is_geog ? ["lon", "lat", "z", valname] : ["x", "y", "z", valname])
	return R
end
