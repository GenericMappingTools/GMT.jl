"""
    image(cmd0::String="", arg1=nothing; kwargs...)

Place images or EPS files on maps.

See full GMT (not the `GMT.jl` one) docs at [`psimage`]($(GMTdoc)image.html)

Parameters
----------

- $(GMT._opt_B)
- **D** | **pos** | **position** :: [Type => Str]

    Sets reference point on the map for the image using one of four coordinate systems.
- **F** | **box** :: [Type => Str | []]

    Without further options, draws a rectangular border around the image using MAP_FRAME_PEN.
- **G** | **bit_color** | **bit_bg|fg|alpha**:: [Type => Str]

    Change certain pixel values to another color or make them transparent.
- **I** | **invert** :: [Type => Str | Number]

    Invert 1-bit image before plotting.
- $(GMT._opt_J)
- $(GMT.opt_Jz)
- **M** | **monochrome** :: [Type => Bool]

    Convert color image to monochrome grayshades using the (television) YIQ-transformation.
- $(GMT._opt_R)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT._opt_p)
- $(GMT._opt_t)
- $(GMT.opt_savefig)

To see the full documentation type: ``@? image``
"""
function image(cmd0::String="", arg1=nothing; first=true, kwargs...)

	gmt_proggy = (IamModern[1]) ? "image "  : "psimage "

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd = parse_BJR(d, "", "", O, " -JX" * split(def_fig_size, '/')[1] * "/0")[1]
	cmd = parse_common_opts(d, cmd, [:F :UVXY :JZ :c :p :t :params], first)[1]
	cmd = parse_these_opts(cmd, d,  [[:I :invert], [:M :monochrome]])
	((val = find_in_dict(d, [:G :bit_color])[1]) !== nothing && isa(val, String)) && (cmd *= string(" -G", val))
	((val = find_in_dict(d, [:bit_bg])[1]) !== nothing) && (cmd = add_opt_fill(val, cmd, " -G") * "+b")
	((val = find_in_dict(d, [:bit_fg])[1]) !== nothing) && (cmd = add_opt_fill(val, cmd, " -G") * "+f")
	((val = find_in_dict(d, [:bit_alpha])[1]) !== nothing) && (cmd = add_opt_fill(val, cmd, " -G") * "+t")

	cmd = parse_type_anchor(d, cmd, [:D :pos :position],
	                        (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), dpi="+r", width=("+w", arg2str), justify="+j", repeat=("+n", arg2str), offset=("+o", arg2str)), 'j')

	cmd, _, arg1 = find_data(d, cmd0, cmd, arg1)		# Find how data was transmitted

	return finish_PS_module(d, gmt_proggy * cmd, "", K, O, true, arg1)
end

# ---------------------------------------------------------------------------------------------------
image!(cmd0::String="", arg1=nothing; kw...) = image(cmd0, arg1; first=false, kw...)

image(arg1; kw...)  = image("", arg1; first=true, kw...)
image!(arg1; kw...) = image("", arg1; first=false, kw...)

# ---------------------------------------------------------------------------------------------------
const psimage  = image			# Alias
const psimage! = image!			# Alias