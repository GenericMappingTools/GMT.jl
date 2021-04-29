"""
    mbimport(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; kwargs...)

Produces a gray-shaded (or colored) map by plotting rectangles centered on each grid node and assigning them a gray-shade (or color) based on the z-value.

Parameters
----------

- **A** | **footprint** :: [Type => Str | Tuple]	``Arg = factor/mode/depth``

    Determines how the along-track dimension of the beam or pixel footprints is calculated.
- $(GMT.opt_J)
- $(GMT.opt_C)
- **D** | **scaling** :: [Type => Str | Tuple]	``Arg = mode/scale/min/max``

    Sets scaling of beam amplitude or sidescan pixel values which can be applied before plotting.
- **E** | **dpi** :: [Type => Int]

    Sets the resolution of the projected image that will be created.
- **G** | **bit_color** :: [Type => Str | Tuple]	``Arg = magnitude/azimuth or magnitude/median``

    Sets the parameters controlng simulated illumination of bathymetry.
- **S** | **speed** :: [Type => Number]

    Sets the minimum speed in km/hr (5.5 kts ~ 10 km/hr) allowed in the input data.
- **T** | **timegap** :: [Type => number]

    Sets the maximum time gap in minutes between adjacent pings before being considered a gap.
- **Z** | **type_plot** :: [Type => Str | Number]

    Sets the style of the plot.
- $(GMT.opt_R)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_n)
- $(GMT.opt_t)
"""
function mbimport(cmd0::String=""; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("mbimport", cmd0)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, opt_R = parse_R(d, "")
	cmd, opt_J = parse_J(d, cmd, " -JX12cd/0", true)
	cmd, = parse_common_opts(d, cmd, [:UVXY :params :n :t], true)

	cmd  = parse_these_opts(cmd, d, [[:A :footprint], [:D :scaling], [:F :format], [:E :dpi], [:G :shade],
	                                 [:S :speed], [:T :timegap], [:b :star_time], [:e :end_time]])
	cmd = add_opt(d, cmd, 'Z', [:Z :type_plot], (bat="_1", shaded_bat="_2", shaded_amp="_3", amp="_4", sscan="_5"))

	cmd = add_opt(d, cmd, "%", [:layout :mem_layout], nothing)
	cmd, arg1, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', 0, nothing)
	N_args = (arg1 === nothing) ? 0 : 1
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:N :color_amp], 'N', N_args, arg1, nothing)

	cmd = "mbimport -I" * cmd0 * cmd				# In any case we need this
	finish_PS_module(d, cmd, "", true, false, false, arg1, arg2)
end