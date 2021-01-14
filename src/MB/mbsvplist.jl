"""
    mbsvplist(cmd0::String=""; kwargs...)

List water sound velocity profiles in swath sonar data files.

Parameters
----------

- **C** | **uniquesvp** :: [Type => Bool]

    Output the number of unique SVPs in each file.
- **F** | **format** :: [Type => Int]

    Sets the format for the input swath sonar data.
- **M** | **mode** :: [Type => Int]		``Arg = 1 or 2 or 3``

    Sets the SVP output mode..
- **S** | **ssv** :: [Type => Bool]

    Sets the minimum speed in km/hr (5.5 kts ~ 10 km/hr) allowed in the input data.
- **Z** | **firstiszero** :: [Type => Bool]

    Sets the style of the plot.
- $(GMT.opt_R)
- $(GMT.opt_V)
"""
function mbsvplist(cmd0::String=""; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("mbsvplist", cmd0)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd = parse_common_opts(d, "", [:R :yx :V_params :o])[1]
	cmd = parse_these_opts(cmd, d, [[:C :uniquesvp], [:F :format], [:H :help], [:M :mode], [:S :ssv], [:Z :firstiszero], [:z :z_down]])
	((val = find_in_dict(d, [:z :z_down])[1]) === nothing) && (cmd *= " -z")	# Means here default is Z-up
	(!occursin("-:", cmd)) && (cmd = " -:" * cmd)		# Means that the default here (contrary to C version) is speed-dept

	cmd = "mbsvplist -I" * cmd0 * cmd				# In any case we need this
	finish_PS_module(d, cmd, "", true, false, false)
end