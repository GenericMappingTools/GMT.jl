"""
	colorbar(cmd0::String="", arg1=[]; kwargs...)
	
Plots gray scales or color scales on maps.

Full option list at [`psscale`](http://gmt.soest.hawaii.edu/doc/latest/psscale.html)

- **D** : **pos** : **position** : -- Str --

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
- **L** : **equal** : **equal_size** : -- Str or [] --

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
function colorbar(cmd0::String="", arg1=[]; first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("psscale", cmd0, arg1)

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	K, O = set_KO(first)		# Set the K O dance
	cmd, opt_B, = parse_BJR(d, "", "", O, "")
	cmd = parse_common_opts(d, cmd, [:UVXY :params :p :t])
	cmd = parse_these_opts(cmd, d, [[:G :truncate], [:I :shade], [:M :monochrome], [:N :dpi],
	                                [:Q :log], [:S :nolines], [:W :zscale], [:Z :zfile]])
	cmd = add_opt(cmd, "D", d, [:D :pos :position],
        (map=("g", nothing, 1), inside=("j", nothing, 1), anchor=("", arg2str, 2), length="+w", triangles="+e",
         justify="+j", offset="+o", horizontal="_+h", move_annot="+m", neon="_+mc", nan="+n"))

	cmd, arg1, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', 0, arg1, [])
	if (!occursin("-C", cmd))	# If given no CPT, try to see if we have a current one stored in global
		if ((global cpt = current_cpt) !== nothing)
			cmd *= " -C";	arg1 = cpt
		end
	end

	cmd = add_opt(cmd, 'F', d, [:F :box], (clearance="+c", fill=("+g", add_opt_fill), inner="+i",
	                                       pen=("+p", add_opt_pen), rounded="+r", shade="+s"))
	cmd = add_opt(cmd, 'L', d, [:L :equal :equal_size], (range="i", gap=""))

	cmd = finish_PS(d, cmd, output, K, O)
	return finish_PS_module(d, "psscale " * cmd, "", output, fname_ext, opt_T, K, arg1)
end

# ---------------------------------------------------------------------------------------------------
colorbar(arg1=[]; kw...) = colorbar("", arg1; first=true, kw...)
colorbar!(arg1=[]; first=false, kw...) = colorbar("", arg1; first=first, kw...)
colorbar!(cmd0::String="", arg1=[]; first=false, kw...) = colorbar(cmd0, arg1; first=first, kw...)

const psscale  = colorbar         # Alias
const psscale! = colorbar!        # Alias
