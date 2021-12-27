"""
    mblevitus(cmd0::String=""; kwargs...)

Create a water velocity profile which is representative of the mean annual water column for a specified
1 degree by 1 degree region.

Parameters
----------

- **A** | **all4** :: [Type => Bool]

    Pint also depth, velocity, temperature, salinity.
- **L** | **location** :: [Type => Str | Tuple]		``Arg = lon/lat``

    Sets the longitude and latitude of the location of the water velocity profile.
- **O** | **outfile** | **out_file** :: [Type => Str]

    Write the SVP to <outfile>.
- **H** | **help** :: [Type => Bool]

    Print out program's description.
- **z** | **z_down** :: [Type => Bool]

    Makes Z axes positive down (default here is Z-up).
- $(GMT.opt_V)
"""
function mblevitus(cmd0::String=""; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("mblevitus", cmd0)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd = parse_common_opts(d, "", [:yx :V_params :o])[1]
	cmd = add_opt(d, cmd, "L", [:L :location :R])
	(!occursin("-L", cmd)) && (cmd *= " -L0/0")
	cmd = parse_these_opts(cmd, d, [[:A :all4], [:O :outfile :output_file], [:H :help], [:z :z_down]])
	((val = find_in_dict(d, [:z :z_down])[1]) === nothing) && (cmd *= " -z")	# Means here default is Z-up
	(!occursin("-:", cmd)) && (cmd = "-:" * cmd)		# Means that the default here (contrary to C version) is speed-dept

	finish_PS_module(d, "mblevitus " * cmd, "", true, false, false)
end