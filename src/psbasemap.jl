"""
    basemap(cmd0::String=""; kwargs...)

Plot base maps and frames.

Full option list at [`psbasemap`]($(GMTdoc)basemap.html)

Parameters
----------

- $(GMT.opt_J)
- $(GMT.opt_R)
- **A** | **polygon** :: [Type => Str | []]

    No plotting is performed. Instead, we determine the geographical coordinates of the polygon
    outline for the (possibly oblique) rectangular map domain. 
    ($(GMTdoc)basemap.html#a)
- $(GMT.opt_B)
- **D** | **inset** | **inset_box** :: [Type => Str]

    Draw a simple map insert box on the map. Requires -F.
    ($(GMTdoc)basemap.html#d)
- **F** | **box** :: [Type => Str]

    Without further options, draws a rectangular border around any map insert (D), map scale (L)
    or map rose (T)
    ($(GMTdoc)basemap.html#f)
- $(GMT.opt_Jz)
- **L** | **map_scale** :: [Type => Str]

    Draw a map scale.
    ($(GMTdoc)basemap.html#l)
- $(GMT.opt_P)
- **Td** | **rose** :: [Type => Str]

    Draws a map directional rose on the map at the location defined by the reference and anchor points.
    ($(GMTdoc)basemap.html#t)
- **Tm** | **compass** :: [Type => Str]

    Draws a map magnetic rose on the map at the location defined by the reference and anchor points.
    ($(GMTdoc)basemap.html#t)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bo)
- $(GMT.opt_f)
- $(GMT.opt_p)
- $(GMT.opt_t)
"""
function basemap(cmd0::String="", arg1=nothing; first=true, kwargs...)

    length(kwargs) == 0 && return monolitic("psbasemap", cmd0, arg1)

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd, = parse_common_opts(d, cmd, [:F :UVXY :JZ :bo :c :f :p :t :params], first)
    cmd  = parse_these_opts(cmd, d, [[:A :polygon]])
	cmd  = parse_Td(d, cmd)
	cmd  = parse_Tm(d, cmd)
	cmd  = parse_L(d, cmd)
	cmd = parse_type_anchor(d, cmd, [:D :inset :inset_box],
	                        (map=("-g", arg2str, 1), outside=("J", nothing, 1), inside=("j", nothing, 1), norm=("-n", arg2str, 1), paper=("-x", arg2str, 1), anchor=("", arg2str, 2), width="+w", size="+w", justify="+j", offset=("+o", arg2str), save="+s", translate="_+t", units="_+u"), 'j')
	finish_PS_module(d, "psbasemap " * cmd, "", K, O, true, arg1)
end

# ---------------------------------------------------------------------------------------------------
basemap!(cmd0::String="", arg1=nothing; kw...) = basemap(cmd0, arg1; first=false, kw...)

const psbasemap  = basemap 		# Alias
const psbasemap! = basemap!		# Alias