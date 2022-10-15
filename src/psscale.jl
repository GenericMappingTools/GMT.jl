"""
	colorbar(cmd0::String="", arg1=nothing; kwargs...)
	
Plots gray scales or color scales on maps.

Full option list at [`psscale`]($(GMTdoc)psscale.html)

- **D** | **pos** | **position** :: [Type => Str]

    Defines the reference point on the map for the color scale using one of four coordinate systems.
    ($(GMTdoc)psscale.html#d)
- $(GMT._opt_B)
- $(GMT.opt_C)
- **F** | **box** :: [Type => Str]

    Draws a rectangular border around the scale.
    ($(GMTdoc)psscale.html#f)
- **G** | **truncate** :: [Type => Str]  

    Truncate the incoming CPT so that the lowest and highest z-levels are to zlo and zhi.
    ($(GMTdoc)psscale.html#g)
- **I** | **shade** :: [Type => Number | Str]

    Add illumination effects.
    ($(GMTdoc)psscale.html#i)
- $(GMT._opt_J)
- $(GMT.opt_Jz)
- **L** | **equal** | **equal_size** :: [Type => Str | Bool]		`Arg = [i][gap]`

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
- $(GMT._opt_R)
- **S** | **nolines** :: [Type => Bool | []]

    Do not separate different color intervals with black grid lines.
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** | **scale** :: [Type => Number]

    Multiply all z-values in the CPT by the provided scale.
    ($(GMTdoc)psscale.html#w)
- **Z** | **zfile** :: [Type => Str]

    File with colorbar-width per color entry.
    ($(GMTdoc)psscale.html#z)
- $(GMT.opt_savefig)
"""
function colorbar(cmd0::String="", arg1=nothing; first=true, kwargs...)

	gmt_proggy = (IamModern[1]) ? "colorbar "  : "psscale "
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd, opt_B, = parse_BJR(d, "", "", O, "")
	cmd  = parse_JZ(d, cmd)[1]
	cmd, = parse_common_opts(d, cmd, [:F :UVXY :params :c :p :t], first)
	cmd  = parse_these_opts(cmd, d, [[:G :truncate], [:I :shade], [:M :monochrome], [:N :dpi],
	                                [:Q :log], [:S :nolines], [:W :scale], [:Z :zfile]])
	cmd = parse_type_anchor(d, cmd, [:D :pos :position],
							(map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), length=("+w", arg2str), size=("+w", arg2str), justify="+j", triangles="+e", horizontal="_+h", move_annot="+m", neon="_+mc", nan="+n", offset=("+o", arg2str)), 'J')

	cmd, arg1, = add_opt_cpt(d, cmd, CPTaliases, 'C', 0, arg1)
	if (!isa(arg1, GMTcpt) && !occursin("-C", cmd))	# If given no CPT, try to see if we have a current one stored in global
		if (!isempty(current_cpt[1]))
			cmd *= " -C";	arg1 = current_cpt[1]
		end
	end

	cmd = add_opt(d, cmd, "L", [:L :equal :equal_size], (range="i", gap=""))	# Aditive
	(!occursin(" -D", cmd)) && (cmd *= " -DJMR")			#  So that we can call it with just a CPT

	r = finish_PS_module(d, gmt_proggy * cmd, "", K, O, true, arg1)
	(!isa(r,String)) && gmt("destroy")      # Probably because of the rasters in cpt
	return r
end

# ---------------------------------------------------------------------------------------------------
colorbar(arg1; kw...) = colorbar("", arg1; first=true, kw...)
colorbar!(arg1; kw...) = colorbar("", arg1; first=false, kw...)
colorbar!(cmd0::String="", arg1=nothing; kw...) = colorbar(cmd0, arg1; first=false, kw...)

const psscale  = colorbar         # Alias
const psscale! = colorbar!        # Alias
const colorscale  = colorbar      # Alias
const colorscale! = colorbar!     # Alias
