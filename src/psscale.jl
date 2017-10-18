"""
	psscale(cmd0::String="", arg1=[]; fmt="", kwargs...)
	
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
# ---------------------------------------------------------------------------------------------------
function psscale(cmd0::String="", arg1=[]; fmt="", K=false, O=false, first=true, kwargs...)

	output = fmt
	if (!isa(output, String))
		error("Output format or name must be a String")
	else
		output, opt_T, fname_ext = fname_out(output)		# OUTPUT may have been an extension only
	end

	d = KW(kwargs)
	cmd = ""
	cmd, opt_B = parse_B(cmd, d)
	cmd, opt_R = parse_R(cmd, d, O)
	cmd, opt_J = parse_J(cmd, d, O)
	if (O && K && isempty(opt_J))  cmd = cmd * " -J"  end
	cmd = parse_U(cmd, d)
	cmd = parse_V(cmd, d)
	cmd = parse_X(cmd, d)
	cmd = parse_Y(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)

	for sym in [:C :color :cmap]
		if (haskey(d, sym))
			if (isa(d[sym], GMT.GMTcpt))
				cmd = cmd * " -C"
				arg1 = d[sym]
			else
				cmd = cmd * " -C" * arg2str(d[sym])
			end
			break
		end
	end

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

	if (first)  K = true;	O = false
	else        K = true;	O = true;	cmd = replace(cmd, opt_B, "");	opt_B = ""
	end

	cmd = finish_PS(d, cmd0, cmd, output, K, O)

	(haskey(d, :Vd)) && println(@sprintf("\tpsscale %s", cmd))

	if (haskey(d, :ps)) PS = true			# To know if returning PS to the REPL was requested
	else                PS = false
	end

    P = nothing
	if (isempty_(arg1))
        if (PS) P = gmt("psscale " * cmd)
        else        gmt("psscale " * cmd)
        end
    else
        if (PS) P = gmt("psscale " * cmd, arg1)
        else        gmt("psscale " * cmd, arg1)
        end
    end
	show_or_save(d, output, fname_ext, opt_T, K)    # Display Fig in default viewer or save it to file
	return P
end

# ---------------------------------------------------------------------------------------------------
psscale!(cmd0::String="", arg1=[]; fmt="", K=false, O=false, first=false, kw...) =
    psscale(cmd0, arg1; fmt=fmt, K=true, O=true, first=false, kw...)
