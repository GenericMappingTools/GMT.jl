"""
    image(cmd0::String="", arg1=nothing; kwargs...)

Place images or EPS files on maps.

Parameters
----------

- $(_opt_B)
- **D** | **pos** | **position** :: [Type => Str]

    Sets reference point on the map for the image using one of four coordinate systems.
- **F** | **box** :: [Type => Str | []]

    Without further options, draws a rectangular border around the image using MAP_FRAME_PEN.
- **G** | **bitcolor** | **bit_color** | **bit_bg|fg|alpha**:: [Type => Str]

    Change certain pixel values to another color or make them transparent.
- **I** | **invert** :: [Type => Str | Number]

    Invert 1-bit image before plotting.
- $(_opt_J)
- $(opt_Jz)
- **M** | **monochrome** :: [Type => Bool]

    Convert color image to monochrome grayshades using the (television) YIQ-transformation.
- $(_opt_R)
- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)
- $(_opt_p)
- $(_opt_t)
- $(opt_savefig)

To see the full documentation type: ``@? image``
"""
image(cmd0::String; kwargs...)  = image_helper(cmd0, nothing; kwargs...)
image(arg1; kwargs...)          = image_helper("", arg1; kwargs...)
image!(cmd0::String; kwargs...) = image_helper(cmd0, nothing; first=false, kwargs...)
image!(arg1; kwargs...)         = image_helper("", arg1; first=false, kwargs...)

function image_helper(cmd0::String="", arg1=nothing; first=true, kwargs...)
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode
	image_helper(cmd0, arg1, O, K, d)
end

# ---------------------------------------------------------------------------------------------------
function image_helper(cmd0::String, arg1, O::Bool, K::Bool, d::Dict{Symbol,Any})

	proggy = (IamModern[1]) ? "image "  : "psimage "

	cmd = parse_BJR(d, "", "", O, " -JX" * split(DEF_FIG_SIZE, '/')[1] * "/0")[1]
	cmd = parse_common_opts(d, cmd, [:F :UVXY :JZ :c :p :t :params :margin]; first=!O)[1]
	cmd = parse_these_opts(cmd, d,  [[:I :invert], [:M :monochrome]])
	((val = find_in_dict(d, [:G :bitcolor :bit_color])[1]) !== nothing && isa(val, String)) && (cmd *= string(" -G", val))
	((val = find_in_dict(d, [:bit_bg])[1]) !== nothing) && (cmd = add_opt_fill(val, cmd, " -G") * "+b")
	((val = find_in_dict(d, [:bit_fg])[1]) !== nothing) && (cmd = add_opt_fill(val, cmd, " -G") * "+f")
	((val = find_in_dict(d, [:bit_alpha])[1]) !== nothing) && (cmd = add_opt_fill(val, cmd, " -G") * "+t")

	cmd = parse_type_anchor(d, cmd, [:D :pos :position],
	                        (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), dpi="+r", width=("+w", arg2str), justify="+j", repeat=("+n", arg2str), offset=("+o", arg2str)), 'j')

	cmd, _, arg1 = find_data(d, cmd0, cmd, arg1)		# Find how data was transmitted

	cmd = proggy * cmd
	((r = check_dbg_print_cmd(d, cmd)) !== nothing) && return r
	prep_and_call_finish_PS_module(d, cmd, "", K, O, true, arg1)
end

# ---------------------------------------------------------------------------------------------------
const psimage  = image			# Alias
const psimage! = image!			# Alias