"""
	gmtbegin(name::String=""; fmt)

Start a GMT session in modern mode (GMT >= 6).
'name' contains the figure name with or without extension. If an extension is used 
(e.g. "map.pdf") it is used to select the image format.

As an alternative use 'fmt' as a string or symbol containing the format (ps, pdf, png, PNG, tif, jpg, eps).

By default name="GMTplot" and fmt="ps"
"""
function gmtbegin(name::String=""; fmt=nothing, verbose=nothing)
	cmd = "begin"       # Default name (GMTplot.ps) is set in gmt_main()
	if (name != "")  cmd *= " " * get_format(name, fmt)  end
	if (verbose !== nothing)  cmd *= " -V" * string(verbose)  end
	gmt(cmd)
	return nothing
end

"""
	gmtend(show=false, verbose=nothing)

Ends a GMT session in modern mode (GMT >= 6) and optionaly shows the figure
"""
function gmtend(show=nothing; verbose=nothing)
	cmd = "end"
	if (show !== nothing)  cmd *= " show"  end
	if (verbose !== nothing)  cmd *= " -V" * string(verbose)  end
	gmt(cmd)
	return nothing
end
 
"""
	function gmtfig(name::String; fmt=nothing, opts="")

Set attributes for the current modern mode session figure.
'name' name of the new (or resumed) figure. It may contain an extension.
'fmt'  figures graphics format (or formats, e.g. fmt="eps,pdf"). Not needed if 'name' has extension
'opts' Sets one or more comma-separated options (and possibly arguments) that can be passed to psconvert when preparing this figure.
"""
function gmtfig(name::String; fmt=nothing, opts="")
	global IamModern
	if (!IamModern)  error("Not in modern mode. Must run 'gmtbegin' first")  end
 
	cmd = "figure"       # Default name (GMTplot.ps) is set in gmt_main()
	if (name == "")  error("figure name cannot be empty")   end
	cmd *= " " * get_format(name, fmt)
	if (opts != "")  cmd *= " " * opts  end
	gmt(cmd)
	return nothing
end

function inset(fim=nothing; stop=false, kwargs...)

	global IamModern
	if (!IamModern)  error("Not in modern mode. Must run 'gmtbegin' first")  end
 
	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:c :F :V_params], true)
	cmd = parse_these_opts(cmd, d, [[:M :margins]])
    cmd = parse_type_anchor(d, cmd, [[:D :inset :inset_box]])

	do_show = false
	if (fim !== nothing)
		t = lowercase(string(fim))
		if     (t == "end" || t == "stop")  stop = true
		elseif (t == "show")  stop = true;  do_show = true
		end
	end

	if (!stop)
		if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end		# Vd=2 cause this return
		gmt("inset begin " * cmd);
	else
		gmt("inset end");
		if (do_show || haskey(d, :show))  gmt("end" * show);  end
	end
end

function get_format(name, fmt=nothing, d=nothing)
	# Get the fig name and format. If format not specified, default to FMT (ps)
	# NAME is supposed to always exist (otherwise, errors)
	fname, ext = splitext(string(name))
	if (ext != "")
		fname *= " " * ext[2:end]
	elseif (fmt !== nothing)
		fname *= " " * string(fmt)      # No checking
	elseif (d !== nothing)
		if (haskey(d, :fmt))  fname *= " " * string(d[:fmt])
		else                  fname *= " " * FMT		# Then use default format
		end
	else
		fname *= " " * FMT
	end
	return fname
end