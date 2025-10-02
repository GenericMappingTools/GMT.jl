"""
	gravmag3d(cmd0::String=""; kwargs...)

Compute the gravity/magnetic anomaly of a 3-D body by the method of Okabe.

See full GMT docs at [`gmtgravmag3d`]($(GMTdoc)supplements/potential/gmtgravmag3d.html)

Parameters
----------

- **C** | **density** :: [Type => Str | GMTgrid]

    Sets body density in SI. Provide either a constant density or a grid with a variable one.
- **F** | **track** :: [Type => Str | Matrix | GMTdataset]

    Provide locations where the anomaly will be computed. Note this option is mutually exclusive with `outgrid`.
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = gmtgravmag3d(....) form.
- **H** | **mag_params** :: [Type => Number]

    Sets parameters for computation of magnetic anomaly. Alternatively, provide a magnetic intensity grid. 
- $(opt_I)
- **L** | **z_obs** | **observation_level** :: [Type => Number]

    Sets level of observation [Default = 0]. That is the height (z) at which anomalies are computed.
- **M** | **body** :: [Type => Str | Tuple]

    Create geometric bodies and compute their grav/mag effect.
- $(_opt_R)
- **S** | **radius** :: [Type => Number]

    Set search radius in km (valid only in the two grids mode OR when `thickness`) [Default = 30 km].
- **T+v** | **index** :: [Type => Str]
- **T+r** | **raw_triang** :: [Type => Str]
- **T+s** | **stl** :: [Type => Str]

    Gives names of a xyz and vertex (ndex="vert_file") files defining a close surface.
- **Z** | **level** | **reference_level** :: [Type => Number]

    Level of reference plane [Default = 0].

### Example
```julia
	G = gmtgravmag3d(M=(shape=:prism, params=(1,1,1,5)), inc=1.0, region="-15/15/-15/15", mag_params="10/60/10/-10/40");
	imshow(G)
```
"""
gravmag3d(cmd0::String; kwargs...) = gravmag3d_helper(cmd0, nothing; kwargs...)
gravmag3d(arg1; kwargs...)         = gravmag3d_helper("", arg1; kwargs...)
gravmag3d(; kwargs...)             = gravmag3d_helper("", nothing; kwargs...)

function gravmag3d_helper(cmd0::String, arg1; kwargs...)
	(cmd0 == "" && arg1 === nothing && length(kwargs) == 0) && return gmt("gmtgravmag3d")
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	(cmd0 != "") && (arg1 = gmtread(cmd0, data=true))
	if (isa(arg1, GMTfv))
		v = mat2ds(arg1.verts) 
		f = arg1.faces[1]# .- 1
		d[:Tf] = f
		d[:Q] = true
		arg1 = v
	end
	isa(arg1, Matrix{<:AbstractFloat}) && (arg1 = mat2ds(arg1))		# Ensure we always send a GMTdataset
	_gravmag3d_helper(arg1, d)
end

# ---------------------------------------------------------------------------------------------------
function _gravmag3d_helper(arg1, d::Dict{Symbol,Any})
	
	cmd = parse_common_opts(d, "", [:G :RIr :V_params :bi :f])[1]
	cmd = parse_these_opts(cmd, d, [[:C :density], [:E :thickness], [:L :z_obs :observation_level], [:S :radius], [:Z :level :reference_level]])
	cmd = add_opt(d, cmd, "H", [:H :mag_params], (field_dec="", field_dip="", mag="", mag_dec="", mag_dip=""))

	arg2, arg3 = nothing, nothing;
	if ((val = find_in_dict(d, [:Tv :index], true, "GMTdataset | Mx3 array | String")[1]) !== nothing && val != "")  opt = " -Tv"
	elseif ((val = find_in_dict(d, [:Tr :raw :raw_triang], true, "GMTdataset | Mx3 array | String")[1]) !== nothing && val != "") opt = " -Tr"
	elseif ((val = find_in_dict(d, [:Tf], true)[1]) !== nothing && val != "") opt = " -Tf"
	elseif ((val = find_in_dict(d, [:Ts :stl :STL], true, "String (file name)")[1]) !== nothing && val != "")  opt = " -Ts"
	elseif ((val = find_in_dict(d, [:M :body], false, "String | NamedTuple")[1]) !== nothing && val != "")
		if (isa(val, Tuple))
			cmd = add_opt(Dict(:body => val[1]), cmd, "M", [:M :body], (shape="+s", params=","))
			for n = 2:numel(val)
				cmd = add_opt(Dict(:body => val[n]), cmd, "", [:M :body], (shape="+s", params=","))
			end
			delete!(d, [:M :body])
		else
			cmd = add_opt(d, cmd, "M", [:M :body], (shape="+s", params=","))
		end
		opt = " -Ts"
	elseif (SHOW_KWARGS[1])  opt = "" 
	else   error("Missing one of 'index', 'raw_triang' or 'str' data")
	end
	
	(find_in_dict(d, [:Q :onebased :one_based])[1] !== nothing) && (cmd *= " -Q")	# Tells to use 1 based in the C side

	if (opt != " -Ts")		# The STL format can only be requested via file (so we can keep testing that with old syntax)
		if (isa(val, Array{<:Real}) || isa(val, GDtype))
			(arg1 === nothing) ? arg1 = val : arg2 = val		# Find the free slot (update. I think now arg1 is always a GMTdatset)
			cmd *= " -T+" * opt[end]		# New -T syntax
		else
			cmd *= isa(val, String) ? " -T" * arg2str(val) * "+" * opt[end] : " -T+" * opt[end]
		end
	elseif (isa(val, String))				# STL case, which can only be a file name
		cmd *= " -T" * val * "+s"
	end

	(find_in_dict(d, [:noswap :no_swap])[1] !== nothing) && (cmd *= "+n")	# 

	if ((val = find_in_dict(d, [:F :track], true, "GMTdataset | Mx2 array | String")[1]) !== nothing && val != "")
		cmd *= " -F"
		isa(val, String) ? (cmd *= val) : (arg1 === nothing) ? arg1 = val : (arg2 === nothing) ? arg2 = val : arg3 = val
	end

	(!occursin(" -F", cmd) && !occursin(" -G", cmd)) && (cmd *= " -G")
	cmd = "gmtgravmag3d " * cmd
	((r = check_dbg_print_cmd(d, cmd)) !== nothing) && return r
	prep_and_call_finish_PS_module(d, cmd, "", true, false, false, arg1, arg2, arg3)
end

const gmtgravmag3d = gravmag3d		# Alias

#=
# ---------------------------------------------------------------------------------------------------
function sph_analytic(; z0=-15, d=1000)

	G = 6.6743e-11
	mass = 4/3 * pi * 10^3 * d;
	Gm = G*mass * 1e+5		# To give results in mGal
	y=-50:50;	x=-50:50
	g = Matrix{Float32}(undef, length(y), length(x))
	z2 = z0 * z0
	Threads.@threads for row = 1:numel(x)
		for col = 1:numel(y)
			@inbounds g[col,row] = Float32(Gm * z0 / (x[col]*x[col] + y[row]*y[row] + z2)^(1.5))
		end
	end
	mat2grid(g, x, y)
end

# ---------------------------------------------------------------------------------------------------
# 2pi r^2 G zRho / (x^2 + y^2 + z^2)


function gravity_effect_of_prism(x, y, z, prism_params)
	G = 6.67430e-11  # Gravitational constant in m^3 kg^-1 s^-2
    # Unpack prism parameters
    x1, y1, z1, x2, y2, z2 = prism_params
    
    # Calculate intermediate values
    a = (x - x1) / sqrt((y - y1)^2 + (z - z1)^2)
    b = (x - x2) / sqrt((y - y2)^2 + (z - z2)^2)
    
    # Calculate the gravity effect
    gz = G * (z1 * log(a) - z2 * log(b)) / (4π)
    
    return gz
end

function calculate_gravity_anomaly(prism_params, grid_points)
    gz = zeros(length(grid_points))
    
    for i in 1:length(grid_points)
        x, y, z = grid_points[i]
        gz[i] = gravity_effect_of_prism(x, y, z, prism_params)
    end
    
    return gz
end

# Example usage:
prism_params = [0, 0, 0, 10, 0, 100]  # Prism corners: (x1, y1, z1), (x2, y2, z2)
grid_points = [(0, 0, 0), (10, 0, 0), (5, 5, 0)]  # Points to calculate gravity at

gz = calculate_gravity_anomaly(prism_params, grid_points)
=#