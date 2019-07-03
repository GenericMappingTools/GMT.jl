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
function basemap(cmd0::String="", arg1=nothing; first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("psbasemap", cmd0, arg1)
	d = KW(kwargs)
	output, opt_T, fname_ext, K, O = fname_out(d, first)		# OUTPUT may have been an extension only

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd = parse_common_opts(d, cmd, [:F :UVXY :JZ :bo :c :f :p :t :params], first)
    cmd = parse_these_opts(cmd, d, [[:A :polygon]])
    #-D[unit]xmin/xmax/ymin/ymax[r][+sfile][+t] | -D[g|j|J|n|x]refpoint+wwidth[/height][+jjustify][+odx[/dy]][+sfile][+t]
	#cmd = parse_TdTmL(d, cmd)
    cmd = parse_type_anchor(d, cmd, [[:Td :rose], [:Tm :compass], [:L :map_scale], [:D :inset]])

	return finish_PS_module(d, "psbasemap " * cmd, "", output, fname_ext, opt_T, K, O, true, arg1)
end

#= ---------------------------------------------------------------------------------------------------
function parse_TdTmL(d::Dict, cmd::String)
	cmd = add_opt(cmd, "Td", d, [:Td :rose],
        (map=("g", nothing, 1), inside=("j", nothing, 1), anchor=("", arg2str, 2), width="+w", justify="+j",
         fancy="+f", labels="+l", label="+l", offset="+o"))
	cmd = add_opt(cmd, "Tm", d, [:Tm :compass],
        (map=("g", nothing, 1), inside=("j", nothing, 1), anchor=("", arg2str, 2), width="+w", dec="+d", justify="+j",
         rose_primary=("+i", add_opt_pen), rose_secondary=("+p", add_opt_pen), labels="+l", label="+l", annot="+t", offset="+o"))
	cmd = add_opt(cmd, "L", d, [:L :map_scale],
        (map=("g", nothing, 1), inside=("j", nothing, 1), norm=("n", nothing, 1), paper=("x", nothing, 1),
         anchor=("", arg2str, 2), dec="+d", scale_at_lat="+c", length="+w",
         align="+a1", justify="+j", fancy="_+f", label="+l", offset="+o", units="_+u", vertical="_+v"))
end
=#

# ---------------------------------------------------------------------------------------------------
function parse_type_anchor(d::Dict, cmd::String, symbs)
	# SYMBS: [:Td :rose] | [:Tm :compass] | [:L :map_scale] | [:D :inset] [:D :pos :position]
	# or     [[:Td :rose], [:Tm :compass], ...]
    if (isa(symbs, Array{Symbol,2}))  symbs = [symbs]  end      # So that we can always do a loop
	for k = 1:length(symbs)
		opt = add_opt("", "", d, symbs[k],
			(map=("g", nothing, 1), outside=("J", nothing, 1), inside=("j", nothing, 1), norm=("n", nothing, 1), paper=("x", nothing, 1), anchor=("", arg2str, 2), annot="+t", dec="+d", labels="+l", label="+l", length="+w", width="+w", size="+w", align="+a1", justify="+j", fancy="+f", horizontal="_+h", move_annot="+m", neon="_+mc", nan="+n", offset=("+o", arg2str), rose_primary=("+i", add_opt_pen), rose_secondary=("+p", add_opt_pen), save="+s", scale_at_lat="+c", spacing="+l", translate="_+t", triangles="+e", units="_+u", vertical="_+v"))
		if (opt != "" && opt[1] != 'j' && opt[1] != 'J' && opt[1] != 'g' && opt[1] != 'n' && opt[1] != 'x')
		#if (opt != "" && !occursin(r"[Jjgnx]", opt[1]))
			if (symbs[k][2] == :pos || symbs[k][2] == :position)  opt = 'J' * opt   # Colorbar default is outside
			else                                                  opt = 'j' * opt   # All others are inside
			end
		end
		if (opt != "")  cmd *= " -" * string(symbs[k][1]) * opt  end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
basemap!(cmd0::String="", arg1=nothing; first=false, kw...) = basemap(cmd0, arg1; first=first, kw...)

const psbasemap  = basemap 		# Alias
const psbasemap! = basemap!		# Alias