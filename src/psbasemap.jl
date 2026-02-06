"""
    basemap(; kwargs...)

Plot base maps and frames.

Parameters
----------

- $(_opt_J)
- $(_opt_R)
- **A** | **polygon** :: [Type => Str | []]

    No plotting is performed. Instead, we determine the geographical coordinates of the polygon
    outline for the (possibly oblique) rectangular map domain. 
- $(_opt_B)
- **inset** :: [Type => NamedTuple]

    Draw a simple map insert box on the map.
- **F** | **box** :: [Type => Str]

    Without further options, draws a rectangular border around any map insert (D), map scale (L)
    or map rose (T)
- $(opt_Jz)
- **L** | **map_scale** :: [Type => Str]

    Draw a map scale.
- $(opt_P)
- **Td** | **rose** :: [Type => Str]

    Draws a map directional rose on the map at the location defined by the reference and anchor points.
- **Tm** | **compass** :: [Type => Str]

    Draws a map magnetic rose on the map at the location defined by the reference and anchor points.
- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)
- $(opt_bo)
- $(_opt_f)
- $(_opt_p)
- $(_opt_t)

To see the full documentation type: ``@? basemap``
"""
basemap(; first=true, kwargs...) = helper_basemap(; first=first, kwargs...)
basemap!(; kwargs...) = helper_basemap(; first=false, kwargs...)
function helper_basemap(; first=first, kw...)
	d, K, O = init_module(first==1, kw...)		# Also checks if the user wants ONLY the HELP mode
	helper_basemap(O, K, d)
end

function helper_basemap(O::Bool, K::Bool, d::Dict{Symbol, Any})

	proggy = (IamModern[]) ? "basemap "  : "psbasemap "

	cmd, = parse_BJR(d, "", "", O, " -JX" * split(DEF_FIG_SIZE, '/')[1] * "/0")
	cmd, = parse_JZ(d, cmd)
	cmd, = parse_common_opts(d, cmd, [:F :UVXY :bo :c :f :p :t :params :margin]; first=!O)
	cmd  = parse_these_opts(cmd, d, [[:A :polygon]])
	cmd  = parse_Td(d, cmd)
	cmd  = parse_Tm(d, cmd)
	cmd  = parse_L(d, cmd)
	#opt_D = parse_type_anchor(d, "", [:D :inset :inset_box],
	                        #(map=("g", arg2str, 1), outside=("J", nothing, 1), inside=("j", nothing, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), width="+w", size="+w", justify="+j", offset=("+o", arg2str), save="+s", translate="_+t", units="_+u"), 'j')
	#(!IamModern[] && opt_D != "") && (cmd *= opt_D)
	#(IamModern[] && opt_D != "") && @warn("The `inset` option is not available in modern mode. Please use the `inset()` function.")
	_cmd = finish_PS_nested(d, [proggy * cmd])
	CTRL.pocket_d[1] = d		# Store d that may be not empty with members to use in other modules
	((r = check_dbg_print_cmd(d, _cmd)) !== nothing) && return r
	prep_and_call_finish_PS_module(d, _cmd, "", K, O, true)
end

# ---------------------------------------------------------------------------------------------------
const psbasemap  = basemap 		# Alias
const psbasemap! = basemap!		# Alias