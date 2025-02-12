"""
	gravfft(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

Spectral calculations of gravity, isostasy, admittance, and coherence for grids.

See full GMT (not the `GMT.jl` one) docs at [`gravfft`]($(GMTdoc)supplements/potential/gravfft.html)

Parameters
----------

- **D** | **density** :: [Type => Str | GMTgrid]

    Sets body density in SI. Provide either a constant density or a grid with a variable one.
- **E** | **n_terms** :: [Type => Number]

    Number of terms used in Parker expansion [Default = 3].
- **F** | **geopotential** :: [Type => Str | Tuple]

    Specify desired geopotential field: compute geoid rather than gravity 
- **I** | **admittance** :: [Type => Number]

    Use ingrid2 and ingrid1 (a grid with topography/bathymetry) to estimate admittance|coherence and return a GMTdataset.
- **N** | **inquire** :: [Type => Str]         ``Arg = [a|f|m|r|s|nx/ny][+a|[+d|h|l][+e|n|m][+twidth][+v][+w[suffix]][+z[p]]``

    Choose or inquire about suitable grid dimensions for FFT and set optional parameters. Control the FFT dimension:
- **Q** | **flex_topo** | **flexural_topography** :: [Type => Bool]

    Computes grid with the flexural topography.
- **S** | **subplate** | **subplate_load** :: [Type => Bool]

    Computes predicted gravity or geoid grid due to a subplate load produced by the current bathymetry and the theoretical model.
- **T** | **topo_load** :: [Type => Str]

    Compute the isostatic compensation from the topography load (input grid file) on an elastic plate of thickness `te`.
- **W** | **z_obs** | **observation_level** :: [Type => Number]

    Set water depth (or observation height) relative to topography in meters [0]. Append k to indicate km.
- **Z** | **moho_depth** :: [Type => Number]

    Moho [and swell] average compensation depths (in meters positive down).
- $(opt_V)
- $(_opt_f)

### Example. Compute the gravity effect of the Gorringe bank.
```julia
    G = grdcut("@earth_relief_10m", region=(-12.5,-10,35.5,37.5));
	G2 = gravfft(G, density=1700, F=(faa=6,slab=4), f=:g);
	imshow(G2)
```
"""
gravfft(arg1, arg2=nothing; kw...) = gravfft("", arg1, arg2; kw...)
function gravfft(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

	arg3 = nothing
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd::String = parse_common_opts(d, "", [:G :V_params :f])[1]
	cmd = parse_these_opts(cmd, d, [[:C :theoretical_admittance], [:E :n_terms], [:I :admittance], [:N :inquire],
	                                [:Q :flex_topo :flexural_topography], [:S :subplate :subplate_load], [:T :topo_load], [:W :z_obs :observation_level], [:Z :moho_depth]])

	cmd, _, arg1 = find_data(d, cmd0, cmd, arg1)	# Find how data was transmitted

	cmd, arg = get_opt_str_or_obj(d, cmd, [:D :density], GMTgrid)
	(arg !== nothing) && (arg1 === nothing ? arg1 = arg : (arg2 === nothing ? arg2 = arg : arg3 = arg))

	cmd = add_opt(d, cmd, "F", [:F :geopotential], (faa="_f", slab="_+s", bouguer="_b", geoid="_g", vgg="_v", east="_e", north="_n"))

	common_grd(d, cmd0, cmd, "gravfft ", arg1, arg2, arg3)		# Finish build cmd and run it
end
