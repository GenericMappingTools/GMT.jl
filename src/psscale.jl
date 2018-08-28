"""
	colorbar(cmd0::String="", arg1=[]; kwargs...)
	
Plots gray scales or color scales on maps.

Full option list at [`psscale`](http://gmt.soest.hawaii.edu/doc/latest/psscale.html)

- **D** : **position** : -- Str --

    Defines the reference point on the map for the color scale using one of four coordinate systems.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/psscale.html#d)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **F** : **box** : -- Str --

    Draws a rectangular border around the scale.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/psscale.html#f)
- **G** : **truncate** : -- Str --  

    Truncate the incoming CPT so that the lowest and highest z-levels are to zlo and zhi.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/psscale.html#g)
- **I** : **shade** : -- Number or [] --  

    Add illumination effects.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/psscale.html#i)
- $(GMT.opt_J)
- $(GMT.opt_Jz)
- **L** : **equal_size** : -- Str or [] --

    Gives equal-sized color rectangles. Default scales rectangles according to the z-range in the CPT.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/psscale.html#l)
- **M** : **monochrome** : -- Bool or [] --

    Force conversion to monochrome image using the (television) YIQ transformation.
    [`-M`](http://gmt.soest.hawaii.edu/doc/latest/psscale.html#m)
- **N** : **dpi** : -- Str or number --

    Controls how the color scale is represented by the PostScript language.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/psscale.html#n)
- **Q** : **log** : -- Str --

    Selects a logarithmic interpolation scheme [Default is linear].
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/psscale.html#q)
- $(GMT.opt_R)
- **S** : **nolines** : -- Bool or [] --

    Do not separate different color intervals with black grid lines.
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** : **zscale** : -- Number --

    Multiply all z-values in the CPT by the provided scale.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/psscale.html#w)
- **Z** : **zfile** : -- Str --

    File with colorbar-width per color entry.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/psscale.html#z)
"""
function colorbar(cmd0::String="", arg1=[]; K=false, O=false, first=true, kwargs...)

    length(kwargs) == 0 && isempty(data) && return monolitic("psscale", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

    cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd0, "", "", O, "")
	cmd = parse_UVXY(cmd, d)
	cmd, = parse_p(cmd, d)
	cmd, = parse_t(cmd, d)
	cmd  = parse_params(cmd, d)

	cmd, arg1, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', 0, arg1, [])

	cmd = add_opt(cmd, 'D', d, [:D :position])
	cmd = add_opt(cmd, 'F', d, [:F :box])
	cmd = add_opt(cmd, 'G', d, [:G :truncate])
    cmd = add_opt(cmd, 'I', d, [:I :shade])
	cmd = add_opt(cmd, 'L', d, [:L :equal_size])
	cmd = add_opt(cmd, 'M', d, [:M :monochrome])
	cmd = add_opt(cmd, 'N', d, [:N :dpi])
    cmd = add_opt(cmd, 'Q', d, [:Q :log])
	cmd = add_opt(cmd, 'S', d, [:S :nolines])
	cmd = add_opt(cmd, 'W', d, [:W :zscale])
	cmd = add_opt(cmd, 'Z', d, [:Z :zfile])

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	cmd = finish_PS(d, cmd0, cmd, output, K, O)
    return finish_PS_module(d, cmd, "", arg1, [], [], [], [], [], output, fname_ext, opt_T, K, "psscale")
end

# ---------------------------------------------------------------------------------------------------
colorbar!(cmd0::String="", arg1=[]; K=false, O=false, first=false, kw...) =
    colorbar(cmd0, arg1; K=K, O=O, first=first, kw...)
