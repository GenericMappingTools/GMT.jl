"""
	colorbar(arg1=nothing; kwargs...)
	
Plots gray scales or color scales on maps.

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
	d, K, O = init_module(first==1, kwargs...)		# Also checks if the user wants ONLY the HELP mode
	dbg_cmd, d, cmd, arg1 = colorbar_parser(arg1, O, d)
	(dbg_cmd !== nothing) && return dbg_cmd
	r = prep_and_call_finish_PS_module(d, cmd, "", K, O, true, arg1)
	(!isa(r,String)) && gmt("destroy")      # Probably because of the rasters in cpt
end

function colorbar_parser(arg1::Union{Nothing, GMTcpt}, O::Bool, d::Dict{Symbol, Any})
	gmt_proggy = (IamModern[]) ? "colorbar "  : "psscale "

	parse_paper(d)		# See if user asked to temporarily pass into paper mode coordinates

	isBnone = (get(d, :B, nothing) == :none)
	cmd = parse_BJR(d, "", "", O, "")[1]
	contains(cmd, "Bpx+l") && (cmd = replace(cmd, "Bpx+" => "Bpxaf+"))	# Because a simple -Bx would make annots at every color transition
	opt_B = (!contains(cmd, " -B") && !isBnone) ? DEF_FIG_AXES[] : ""
	cmd = parse_JZ(d, cmd; O=O, is3D=(CTRL.pocket_J[3] != ""))[1]		# We can't use parse_J(d)[1]
	cmd = parse_common_opts(d, cmd, [:F :UVXY :params :margin :c :p :t]; first=!O)[1]
	cmd = parse_these_opts(cmd, d, [[:G :truncate], [:I :shade], [:M :monochrome], [:N :dpi],
	                                [:Q :log], [:S :appearance :nolines], [:W :scale], [:Z :zfile]])
	opt_D = parse_type_anchor(d, "", [:D :pos :position],
	                          (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), length=("+w", arg2str), size=("+w", arg2str), justify="+j", triangles="+e", horizontal="_+h", move_annot="+m", neon="_+mc", nan="+n", offset=("+o", arg2str)), 'J')

	(!isempty(opt_D)) && (!contains(opt_D, "DJ") && !contains(opt_D, "Dj") && !contains(opt_D, "Dg")) && (cmd = replace(cmd, "-R " => ""))
	cmd *= opt_D
	cmd, arg1, = add_opt_cpt(d, cmd, CPTaliases, 'C', 0, arg1)
	if (opt_D === "" && ((val = hlp_desnany_str(d, [:triangles])) !== ""))	# User asked for triangles but did not set pos
		(val == "true") && (val = "tri")			# Means just triangles
		anc_tris = colorbar_triangles(val)			# Returns anchor+triangles string
		cmd *= " -DJ" * anc_tris
	end
	if (!isa(arg1, GMTcpt) && !occursin("-C", cmd))	# If given no CPT, try to see if we have a current one stored in global
		if (!isempty(CURRENT_CPT[]))
			cmd *= " -C";	arg1 = CURRENT_CPT[]
		end
	end

	cmd = add_opt(d, cmd, "L", [:L :equal :equal_size], (range="i", gap=""))	# Aditive
	(opt_B != "" && !contains(cmd, " -L")) && (cmd *= opt_B)					# If no -B & no -L, add default -B
	(isempty(opt_D) && !contains(cmd, " -D")) && (cmd *= " -DJMR")				#  So that we can call it with just a CPT

	cmd = gmt_proggy * cmd
	r = check_dbg_print_cmd(d, cmd)
	return r, d, cmd, arg1
end

# ---------------------------------------------------------------------------------------------------
colorbar!(arg1::Union{Nothing, GMTcpt}=nothing; kw...) = colorbar(arg1; first=false, kw...)

const psscale  = colorbar         # Alias
const psscale! = colorbar!        # Alias
const colorscale  = colorbar      # Alias
const colorscale! = colorbar!     # Alias
