"""
	colorbar(arg1=nothing; kwargs...)
	
Plots gray scales or color scales on maps.

See full GMT (not the `GMT.jl` one) docs at [`psscale`]($(GMTdoc)psscale.html)

- **D** | **pos** | **position** :: [Type => Str]

    Defines the reference point on the map for the color scale using one of four coordinate systems.
- $(_opt_B)
- $(opt_C)
- **F** | **box** :: [Type => Str]

    Draws a rectangular border around the scale.
- **G** | **truncate** :: [Type => Str]  

    Truncate the incoming CPT so that the lowest and highest z-levels are to zlo and zhi.
- **I** | **shade** :: [Type => Number | Str]

    Add illumination effects.
- $(_opt_J)
- $(opt_Jz)
- **L** | **equal** | **equal_size** :: [Type => Str | Bool]		`Arg = [i][gap]`

    Gives equal-sized color rectangles. Default scales rectangles according to the z-range in the CPT.
- **M** | **monochrome** :: [Type => Bool]

    Force conversion to monochrome image using the (television) YIQ transformation.
- **N** | **dpi** :: [Type => Str | Number]

    Controls how the color scale is represented by the PostScript language.
- **Q** | **log** :: [Type => Str]

    Selects a logarithmic interpolation scheme [Default is linear].
- $(_opt_R)
- **S** | **appearance** | **nolines** :: [Type => Bool | []]

    Do not separate different color intervals with black grid lines.
- $(opt_U)
- $(opt_V)
- **W** | **scale** :: [Type => Number]

    Multiply all z-values in the CPT by the provided scale.
- **Z** | **zfile** :: [Type => Str]

    File with colorbar-width per color entry.
- $(opt_savefig)

To see the full documentation type: ``@? colorbar``
"""
function colorbar(arg1::Union{Nothing, GMTcpt}=nothing; first=true, kwargs...)

	gmt_proggy = (IamModern[1]) ? "colorbar "  : "psscale "
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	parse_paper(d)		# See if user asked to temporarily pass into paper mode coordinates

	cmd = parse_BJR(d, "", "", O, defaultJ="")[1]
	opt_B = (!contains(cmd, " -B") && !IamModern[1]) ? DEF_FIG_AXES[1] : ""
	cmd = parse_JZ(d, cmd; O=O, is3D=(CTRL.pocket_J[3] != ""))[1]		# We can't use parse_J(d)[1]
	cmd = parse_common_opts(d, cmd, [:F :UVXY :params :margin :c :p :t]; first=first)[1]
	cmd = parse_these_opts(cmd, d, [[:G :truncate], [:I :shade], [:M :monochrome], [:N :dpi],
	                                [:Q :log], [:S :appearance :nolines], [:W :scale], [:Z :zfile]])
	opt_D = parse_type_anchor(d, "", [:D :pos :position],
	                          (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), length=("+w", arg2str), size=("+w", arg2str), justify="+j", triangles="+e", horizontal="_+h", move_annot="+m", neon="_+mc", nan="+n", offset=("+o", arg2str)), 'J')

	(!isempty(opt_D)) && (!contains(opt_D, "DJ") && !contains(opt_D, "Dj") && !contains(opt_D, "Dg")) && (cmd = replace(cmd, "-R " => ""))
	cmd *= opt_D
	cmd, arg1, = add_opt_cpt(d, cmd, CPTaliases, 'C', 0, arg1)
	if (!isa(arg1, GMTcpt) && !occursin("-C", cmd))	# If given no CPT, try to see if we have a current one stored in global
		if (!isempty(CURRENT_CPT[1]))
			cmd *= " -C";	arg1 = CURRENT_CPT[1]
		end
	end

	cmd = add_opt(d, cmd, "L", [:L :equal :equal_size], (range="i", gap=""))	# Aditive
	(opt_B != "" && !contains(cmd, " -L")) && (cmd *= opt_B)					# If no -B & no -L, add default -B
	isempty(opt_D) && (cmd *= " -DJMR")			#  So that we can call it with just a CPT

	r = finish_PS_module(d, gmt_proggy * cmd, "", K, O, true, arg1)
	(!isa(r,String)) && gmt("destroy")      # Probably because of the rasters in cpt
	return r
end

# ---------------------------------------------------------------------------------------------------
#colorbar(arg1; kw...) = colorbar("", arg1; first=true, kw...)
colorbar!(arg1::Union{Nothing, GMTcpt}=nothing; kw...) = colorbar(arg1; first=false, kw...)
#colorbar!(cmd0::String="", arg1=nothing; kw...) = colorbar(cmd0, arg1; first=false, kw...)

const psscale  = colorbar         # Alias
const psscale! = colorbar!        # Alias
const colorscale  = colorbar      # Alias
const colorscale! = colorbar!     # Alias
