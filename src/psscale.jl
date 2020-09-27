"""
	colorbar(cmd0::String="", arg1=nothing; kwargs...)
	
Plots gray scales or color scales on maps.

Full option list at [`psscale`]($(GMTdoc)psscale.html)

- **D** | **pos** | **position** :: [Type => Str]

    Defines the reference point on the map for the color scale using one of four coordinate systems.
    ($(GMTdoc)psscale.html#d)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **F** | **box** :: [Type => Str]

    Draws a rectangular border around the scale.
    ($(GMTdoc)psscale.html#f)
- **G** | **truncate** :: [Type => Str]  

    Truncate the incoming CPT so that the lowest and highest z-levels are to zlo and zhi.
    ($(GMTdoc)psscale.html#g)
- **I** | **shade** :: [Type => Number | []] 

    Add illumination effects.
    ($(GMTdoc)psscale.html#i)
- $(GMT.opt_J)
- $(GMT.opt_Jz)
- **L** | **equal** | **equal_size** :: [Type => Str | []]

    Gives equal-sized color rectangles. Default scales rectangles according to the z-range in the CPT.
    ($(GMTdoc)psscale.html#l)
- **M** | **monochrome** :: [Type => Bool]

    Force conversion to monochrome image using the (television) YIQ transformation.
    ($(GMTdoc)psscale.html#m)
- **N** | **dpi** :: [Type => Str | Number]

    Controls how the color scale is represented by the PostScript language.
    ($(GMTdoc)psscale.html#n)
- **Q** | **log** :: [Type => Str]

    Selects a logarithmic interpolation scheme [Default is linear].
    ($(GMTdoc)psscale.html#q)
- $(GMT.opt_R)
- **S** | **nolines** :: [Type => Bool | []]

    Do not separate different color intervals with black grid lines.
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** | **zscale** :: [Type => Number]

    Multiply all z-values in the CPT by the provided scale.
    ($(GMTdoc)psscale.html#w)
- **Z** | **zfile** :: [Type => Str]

    File with colorbar-width per color entry.
    ($(GMTdoc)psscale.html#z)
"""
function colorbar(cmd0::String="", arg1=nothing; first=true, kwargs...)

	gmt_proggy = (IamModern[1]) ? "colorbar "  : "psscale "
	(length(kwargs) == 0) && return monolitic(gmt_proggy, cmd0, arg1)

	d = KW(kwargs)
	help_show_options(d)		# Check if user wants ONLY the HELP mode
	K, O = set_KO(first)		# Set the K O dance

	cmd, opt_B, = parse_BJR(d, "", "", O, "")
	cmd, = parse_common_opts(d, cmd, [:F :UVXY :params :c :p :t], first)
	cmd  = parse_these_opts(cmd, d, [[:G :truncate], [:I :shade], [:M :monochrome], [:N :dpi],
	                                [:Q :log], [:S :nolines], [:W :zscale], [:Z :zfile]])
	#cmd = add_opt(cmd, "D", d, [:D :pos :position],
	#    (map=("g", nothing, 1), inside=("j", nothing, 1), paper=("x", nothing, 1), anchor=("", arg2str, 2), length="+w",
	#     triangles="+e", justify="+j", offset="+o", horizontal="_+h", move_annot="+m", neon="_+mc", nan="+n"))
	cmd = parse_type_anchor(d, cmd, [:D :pos :position])

	cmd, arg1, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', 0, arg1)
	if (!isa(arg1, GMTcpt) && !occursin("-C", cmd))	# If given no CPT, try to see if we have a current one stored in global
		if ((cpt = current_cpt) !== nothing)
			cmd *= " -C";	arg1 = cpt
		end
	end

	cmd = add_opt(cmd, 'L', d, [:L :equal :equal_size], (range="i", gap=""))
	if (!occursin(" -D", cmd))  cmd *= " -Dx8c/1c+w12c/0.5c+jTC+h"  end      #  So that we can call it with just a CPT

	r = finish_PS_module(d, gmt_proggy * cmd, "", K, O, true, arg1)
	gmt("destroy")      # Probably because of the rasters in cpt
	return r
end

# ---------------------------------------------------------------------------------------------------
colorbar(arg1; kw...) = colorbar("", arg1; first=true, kw...)
colorbar!(arg1; first=false, kw...) = colorbar("", arg1; first=first, kw...)
colorbar!(cmd0::String="", arg1=nothing; first=false, kw...) = colorbar(cmd0, arg1; first=first, kw...)

const psscale  = colorbar         # Alias
const psscale! = colorbar!        # Alias
const colorscale  = colorbar      # Alias
const colorscale! = colorbar!     # Alias
