"""
    image(cmd0::String="", arg1=nothing; kwargs...)

Place images or EPS files on maps.

Full option list at [`psimage`]($(GMTdoc)image.html)

Parameters
----------

- $(GMT.opt_B)
- **D** | **pos** | **position** :: [Type => Str]

    Sets reference point on the map for the image using one of four coordinate systems.
    ($(GMTdoc)image.html#d)
- **F** | **box** :: [Type => Str | []]

    Without further options, draws a rectangular border around the image using MAP_FRAME_PEN.
    ($(GMTdoc)image.html#f)
- **I** | **invert_1bit** :: [Type => Str | Number]

    Invert 1-bit image before plotting.
    ($(GMTdoc)image.html#i)
- $(GMT.opt_J)
- $(GMT.opt_Jz)
- **M** | **monochrome** :: [Type => Bool]

    Convert color image to monochrome grayshades using the (television) YIQ-transformation.
    ($(GMTdoc)image.html#m)
- $(GMT.opt_R)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_p)
- $(GMT.opt_t)
- $(GMT.opt_savefig)
"""
function image(cmd0::String="", arg1=nothing; first=true, kwargs...)

	gmt_proggy = (IamModern[1]) ? "image "  : "psimage "

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd = parse_BJR(d, "", "", O, " -JX" * split(def_fig_size, '/')[1] * "/0")[1]
	cmd = parse_common_opts(d, cmd, [:F :UVXY :JZ :c :p :t :params], first)[1]
	cmd = parse_these_opts(cmd, d,  [[:G :bit_color], [:I :invert_1bit], [:M :monochrome]])
	cmd = parse_type_anchor(d, cmd, [:D :pos :position],
	                        (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), dpi="+r", width=("+w", arg2str), justify="+j", replicate=("+n", arg2str), offset=("+o", arg2str)), 'j')

	cmd, _, arg1 = find_data(d, cmd0, cmd, arg1)		# Find how data was transmitted

	return finish_PS_module(d, gmt_proggy * cmd, "", K, O, true, arg1)
end

# ---------------------------------------------------------------------------------------------------
image!(cmd0::String="", arg1=nothing; kw...) = image(cmd0, arg1; first=false, kw...)

# ---------------------------------------------------------------------------------------------------
const psimage  = image			# Alias
const psimage! = image!			# Alias