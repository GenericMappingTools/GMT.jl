"""
	gmtbegin(name::String=""; fmt)

Start a GMT session in modern mode (GMT >= 6).
'name' contains the figure name with or without extension. If an extension is used 
(e.g. "map.pdf") it is used to select the image format.

As an alternative use 'fmt' as a string or symbol containing the format (ps, pdf, png, PNG, tif, jpg, eps).

By default name="GMTplot" and fmt="ps"
"""
function gmtbegin(name::String=""; fmt=nothing, verbose=nothing)
	FirstModern[1] = true			# To know if we need to compute -R in plot. Due to a GMT6.0 BUG
	cmd = "begin"       # Default name (GMTplot.ps) is set in gmt_main()
	(name != "") && (cmd *= " " * get_format(name, fmt))
	(verbose !== nothing) && (cmd *= " -V" * string(verbose))
	gmt_restart()		# Always start with a clean session
	gmt(cmd)
	return nothing
end

"""
	gmtend(show=false, verbose=nothing)

Ends a GMT session in modern mode (GMT >= 6) and optionaly shows the figure
"""
function gmtend(arg=nothing; show=false, verbose=nothing)
	# To show either do gmtend(whatever) or gmt(show=true)
	cmd = "end"
	if (arg !== nothing || show != 0)  cmd *= " show"  end
	if (verbose !== nothing)  cmd *= " -V" * string(verbose)  end
	gmt(cmd)
	#gmt("destroy")		# Lieve it in a clean state
	IamModern[1] = false;	FirstModern[1] = false
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
	(!IamModern[1]) && error("Not in modern mode. Must run 'gmtbegin' first")
 
	cmd = "figure"       # Default name (GMTplot.ps) is set in gmt_main()
	(name == "") && error("figure name cannot be empty")
	cmd *= " " * get_format(name, fmt)
	if (opts != "")  cmd *= " " * opts  end
	gmt(cmd)
	return nothing
end

function inset(fim=nothing; stop=false, kwargs...)
	if (!IamModern[1])  error("Not in modern mode. Must run 'gmtbegin' first")  end
 
	d = KW(kwargs)
	cmd, = parse_common_opts(d, "", [:c :F :V_params], true)
	cmd  = parse_these_opts(cmd, d, [[:M :margins], [:N :no_clip]])
	#cmd  = parse_type_anchor(d, cmd, [[:D :inset :inset_box]])
	cmd = parse_type_anchor(d, cmd, [:D :inset :inset_box],
	                        (map=("-g", arg2str, 1), outside=("J", nothing, 1), inside=("j", nothing, 1), norm=("-n", arg2str, 1), paper=("-x", arg2str, 1), anchor=("", arg2str, 2), width="+w", size="+w", justify="+j", offset=("+o", arg2str), save="+s", translate="_+t", units="_+u"), 'j')

	do_show = false
	if (fim !== nothing)
		t = lowercase(string(fim))
		if (t == "end" || t == "stop" || t == "show")  stop = true  end
		if (t == "show")  do_show = true  end
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
		else                  fname *= " " * FMT[1]		# Then use default format
		end
	else
		fname *= " " * FMT[1]
	end
	return fname
end