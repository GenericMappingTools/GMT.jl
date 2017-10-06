"""
"""
# ---------------------------------------------------------------------------------------------------
function grdcontour(cmd0::String="", arg1=[]; Vd=false, data=[], portrait=true, fmt="", K=false, 
                    O=false, first=true, kwargs...)

	if (length(kwargs) == 0)		# Good, speed mode
		return gmt("grdcontour " * cmd0)
	end

	if (!isempty_(data) && !isempty_(arg1))
		warn("Conflicting ways of providing input data. Both a file name via positional and
			  a data array via keyword args were provided. Ignoring former argument")
	end

	output = fmt
	if (!isa(output, String))
		error("Output format or name must be a String")
	else
		output, opt_T, fname_ext = fname_out(output)		# OUTPUT may have been an extension only
	end

	d = KW(kwargs)
	cmd = ""
	maybe_more = false			# If latter set to true, search for lc & lc pen settings
	cmd, opt_R = parse_R(cmd, d)
	cmd, opt_J = parse_J(cmd, d)
	cmd, opt_B = parse_B(cmd, d)
	cmd = parse_U(cmd, d)
	cmd = parse_V(cmd, d)
	cmd = parse_X(cmd, d)
	cmd = parse_Y(cmd, d)
	cmd = parse_bo(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_h(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)

	if (first)  K = true;	O = false
	else        K = true;	O = true;	cmd = replace(cmd, opt_B, "");	opt_B = ""
	end

	cmd = add_opt(cmd, 'A', d, [:A :annot])
	cmd = add_opt(cmd, 'C', d, [:C :cont :contour])
	cmd = add_opt(cmd, 'D', d, [:D :dump])
	cmd = add_opt(cmd, 'F', d, [:F :force])
	cmd = add_opt(cmd, 'G', d, [:G :labels])
	cmd = add_opt(cmd, 'L', d, [:L :range])
	cmd = add_opt(cmd, 'Q', d, [:Q :cut])
	cmd = add_opt(cmd, 'S', d, [:S :smooth])
	cmd = add_opt(cmd, 'T', d, [:T :ticks])
	cmd = add_opt(cmd, 'W', d, [:W :pen])
	cmd = add_opt(cmd, 'Z', d, [:Z :scale])

	if (!isempty_(data))
		if (!isempty_(arg1))
			warn("Conflicting ways of providing input data. Both a file name via positional and
				  a data array via kwyword args were provided. Ignoring later argument")
		else
			if (isa(data, String)) 		# OK, we have data via file
				cmd = cmd * " " * data
			else
				arg1 = data				# Whatever this is
			end
		end
	end

	cmd = finish_PS(cmd0, cmd, output, portrait, K, O)

	if (haskey(d, :ps)) PS = true			# To know if returning PS to the REPL was requested
	else                PS = false
	end

	Vd && println(@sprintf("\tgrdcontour %s", cmd))

	P = nothing
	if (!isempty_(arg1))
		if (PS) P = gmt("grdcontour " * cmd, arg1)                 # A numeric input
		else        gmt("grdcontour " * cmd, arg1)
		end
	else
		if (PS) P = gmt("grdcontour " * cmd)                       # Ploting from file
		else        gmt("grdcontour " * cmd)
		end
	end
    show_or_save(d, output, fname_ext, opt_T, K)    # Display Fig in default viewer or save it to file
	return P
end

# ---------------------------------------------------------------------------------------------------
grdcontour!(cmd0::String="", arg1=[]; Vd=false, data=[], portrait=true, fmt="", K=true, O=true, first=false, kw...) =
    grdcontour(cmd0, arg1; Vd=Vd, data=data, portrait=portrait, fmt=fmt, K=true, O=true, first=false, kw...)