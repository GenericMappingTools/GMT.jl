"""
    mbgetdata(cmd0::String=""; kwargs...)

Extract bathymetry, sidescan or amplitude data from datafiles.

Parameters
----------

- **A** | **flagged** :: [Type => Number]	``Arg = value``

    Replace flagged beans with NaN. Use -A<val> to assign a constant value to the flagged beans.
- $(_opt_J)
- **C** | **datatype** | **data_type** :: [Type => Number | Str | Tuple]	``Arg = 0 or "a"``

    Output SideScan, or amplitude, instead of bathymetry. This case ignores **A**
- **D** | **scaling** :: [Type => Str | Tuple]	``Arg = <mode>/<ampscale>/<ampmin>/<ampmax>``

    Sets scaling of beam amplitude or sidescan pixel values which can be applied before plotting.
- **F** | **format** :: [Type => Int]

    Sets the format for the input swath sonar data using MBIO integer format identifiers.
- **S** | **speed** :: [Type => Number]

    Sets the parameters controlng simulated illumination of bathymetry.
- **T** | **timegap** :: [Type => number]

    Sets the maximum time gap in minutes between adjacent pings before being considered a gap.
- $(_opt_R)
- $(opt_V)
- $(opt_n)
- $(_opt_t)
"""
function mbgetdata(cmd0::String=""; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, opt_R = parse_R(d, "")
	cmd, = parse_common_opts(d, cmd, [:UVXY :params]; first=true)

	cmd  = parse_these_opts(cmd, d, [[:A :flagged], [:D :scaling], [:F :format],
	                                 [:S :speed], [:T :timegap], [:b :star_time], [:e :end_time]])
	cmd = add_opt(d, cmd, "C", [:C :datatype :data_type], (sidescan="_0", amplitude="_a"))

	cmd = "mbgetdata -I" * cmd0 * cmd				# In any case we need this
	prep_and_call_finish_PS_module(d, cmd, "", true, false, false)
end