"""
    basemap(cmd0::String=""; kwargs...)

Plot base maps and frames.

Full option list at [`psbasemap`](http://gmt.soest.hawaii.edu/doc/latest/psbasemap.html)

Parameters
----------

- $(GMT.opt_J)
- $(GMT.opt_R)
- **A** : **polygon** : -- Str or [] --

    No plotting is performed. Instead, we determine the geographical coordinates of the polygon
    outline for the (possibly oblique) rectangular map domain. 
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/psbasemap.html#a)
- $(GMT.opt_B)
- **D** : **inset** : -- Str --

    Draw a simple map insert box on the map. Requires -F.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/psbasemap.html#d)
- **F** : **box** : -- Str --

    Without further options, draws a rectangular border around any map insert (D), map scale (L)
    or map rose (T)
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/psbasemap.html#f)
- $(GMT.opt_Jz)
- **L** : **map_scale** : -- Str --

    Draw a map scale.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/psbasemap.html#l)
- $(GMT.opt_P)
- **Td** : **rose`** : -- Str --

    Draws a map directional rose on the map at the location defined by the reference and anchor points.
    [`-Td`](http://gmt.soest.hawaii.edu/doc/latest/psbasemap.html#t)
- **Tm** : **compass** : -- Str --

    Draws a map magnetic rose on the map at the location defined by the reference and anchor points.
    [`-Tm`](http://gmt.soest.hawaii.edu/doc/latest/psbasemap.html#t)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bo)
- $(GMT.opt_f)
- $(GMT.opt_p)
- $(GMT.opt_t)
"""
function basemap(cmd0::String="", arg1=[]; first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("psbasemap", cmd0, arg1)
	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	K, O = set_KO(first)		# Set the K O dance
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd = parse_common_opts(d, cmd, [:UVXY :JZ :bo :f :p :t :params])
	cmd = parse_these_opts(cmd, d, [[:A :polygon], [:D :inset]])
	cmd = add_opt(cmd, 'F', d, [:F :box], (clearance="+c", fill=("+g", add_opt_fill), inner="+i",
	                                       pen=("+p", add_opt_pen), rounded="+r", shade="+s"))
	cmd = parse_TdTmL(d, cmd)

	cmd = finish_PS(d, cmd, output, K, O)
    return finish_PS_module(d, "psbasemap " * cmd, "", output, fname_ext, opt_T, K, arg1)
    end

# ---------------------------------------------------------------------------------------------------
function parse_TdTmL(d::Dict, cmd::String)
	cmd = add_opt(cmd, "Td", d, [:Td :rose],
        (map=("g", nothing, 1), inside=("j", nothing, 1), anchor=("", arg2str, 2), width="+w", justify="+j",
         fancy="+f", labels="+l", label="+l", offset="+o"))
	cmd = add_opt(cmd, "Tm", d, [:Tm :compass],
        (map=("g", nothing, 1), inside=("j", nothing, 1), anchor=("", arg2str, 2), width="+w", dec="+d", justify="+j",
         rose_primary=("+i", add_opt_pen), rose_secondary=("+p", add_opt_pen), labels="+l", label="+l", annot="+t", offset="+o"))
	cmd = add_opt(cmd, "L", d, [:L :map_scale],
        (map=("g", nothing, 1), inside=("j", nothing, 1), anchor=("", arg2str, 2), scale_at_lat="+c", length="+w",
         align="+a1", justify="+j", fancy="_+f", label="+l", offset="+o", units="_+u", vertical="_+v"))
end

# ---------------------------------------------------------------------------------------------------
basemap!(cmd0::String="", arg1=[]; first=false, kw...) = basemap(cmd0, arg1; first=first, kw...)
basemap(arg1=[]; first=true, kw...) = basemap("", arg1; first=first, kw...)
basemap!(arg1=[]; first=false, kw...) = basemap("", arg1; first=first, kw...)

const psbasemap  = basemap 		# Alias
const psbasemap! = basemap!		# Alias