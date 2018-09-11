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
function basemap(cmd0::String="", arg1=[]; K=false, O=false, first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("psbasemap", cmd0, arg1)	# Speedy mode
	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

    cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd = parse_JZ(cmd, d)
	cmd = parse_UVXY(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_p(cmd, d)
	cmd, = parse_t(cmd, d)
	cmd, = parse_bo(cmd, d)
	cmd  = parse_params(cmd, d)

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	cmd = add_opt(cmd, 'A', d, [:A :polygon])
	cmd = add_opt(cmd, 'D', d, [:D :inset])
	cmd = add_opt(cmd, 'F', d, [:F :box])
	cmd = add_opt(cmd, 'L', d, [:L :map_scale])
	cmd = add_opt(cmd, "Td", d, [:Td :rose])
	cmd = add_opt(cmd, "Tm", d, [:Td :compass])

	cmd = finish_PS(d, cmd, output, K, O)
    return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, "psbasemap", arg1)
end

# ---------------------------------------------------------------------------------------------------
basemap!(cmd0::String="", arg1=[]; K=true, O=true, first=false, kw...) = 
	basemap(cmd0, arg1; K=K, O=O, first=first, kw...)
basemap(arg1=[]; K=false, O=false, first=true, kw...) = basemap("", arg1; K=K, O=O, first=first, kw...)
basemap!(arg1=[]; K=true, O=true, first=false, kw...) = basemap("", arg1; K=K, O=O, first=first, kw...)

psbasemap  = basemap 		# Alias
psbasemap! = basemap!		# Alias