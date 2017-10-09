"""
    psscale(cmd0::String="", arg1=[]; portrait=true, fmt="", K=false, O=false, first=true, kwargs...)
"""
# ---------------------------------------------------------------------------------------------------
function psscale(cmd0::String="", arg1=[]; portrait=true, fmt="", K=false, O=false, first=true, kwargs...)

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

	for sym in [:C :color]
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
    cmd = add_opt(cmd, 'I', d, [:I :shading])
	cmd = add_opt(cmd, 'L', d, [:L :equal_size])
	cmd = add_opt(cmd, 'M', d, [:M :monochrome])
	cmd = add_opt(cmd, 'N', d, [:N :dpi])
    cmd = add_opt(cmd, 'Q', d, [:Q :log])
	cmd = add_opt(cmd, 'S', d, [:S :nolines])
	cmd = add_opt(cmd, 'W', d, [:W :z_scale])
	cmd = add_opt(cmd, 'Z', d, [:Z :zfile])

	cmd = finish_PS(cmd0, cmd, output, portrait, K, O)

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
psscale!(cmd0::String="", arg1=[]; portrait=true, fmt="", K=false, O=false, first=false, kw...) =
    psscale(cmd0, arg1; portrait=portrait, fmt=fmt, K=true, O=true, first=false, kw...)
