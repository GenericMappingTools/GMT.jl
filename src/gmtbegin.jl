"""
	gmtbegin(name::String=""; fmt)

Start a GMT session in modern mode (GMT >= 6).
'name' contains the figure name with or without extension. If an extension is used 
(e.g. "map.pdf") it is used to select the image format.

As an alternative use 'fmt' as a string or symbol containing the format (ps, pdf, png, PNG, tif, jpg, eps).

By default name="GMTplot" and fmt="ps"
"""
function gmtbegin(name::String=""; fmt=nothing, verbose=nothing)
	resetGMT()			# Reset everything to a fresh GMT session. That is reset all global variables to their initial state
	cmd = "begin"       # Default name (GMTplot.ps) is set in gmt_main()
	(name != "") && (cmd *= " " * get_format(name, fmt))
	(verbose !== nothing) && (cmd *= " -V" * string(verbose))
	IamModern[1], IamSubplot[1] = false, false
	FirstModern[1] = true			# To know if we need to compute -R in plot. Due to a GMT6.0 BUG
	isJupyter[1] = isdefined(Main, :IJulia)		# show fig relies on this
	gmt(cmd)
	return nothing
end

"""
	gmtend(show=false, verbose=nothing)

Ends a GMT session in modern mode and optionaly shows the figure
"""
function gmtend(arg=nothing; show=false, verbose=nothing)
	# To show either do gmtend(whatever) or gmt(show=true)
	cmd = "end"
	((arg !== nothing || show != 0) && !isFranklin[1]) && (cmd *= " show")
	(verbose !== nothing) && (cmd *= " -V" * string(verbose))
	if (IamSubplot[1])		# This should never happen. Unless user error of calling gmtend() before time.
		@warn("ERROR USING SUBPLOT. You should not call gmtend() before subplot(:end)")
		gmt("subplot end")
	end
	gmt(cmd)
	resetGMT()
	isPSclosed[1] = true
	return nothing
end
 
"""
	function gmtfig(name::String; fmt=nothing, opts="")

Set attributes for the current modern mode session figure.
- 'name' name of the new (or resumed) figure. It may contain an extension.
- 'fmt'  figures graphics format (or formats, e.g. fmt="eps,pdf"). Not needed if 'name' has extension
- 'opts' Sets one or more comma-separated options (and possibly arguments) that can be passed to psconvert when preparing this figure.
"""
function gmtfig(name::String; fmt=nothing, opts="")
	(!IamModern[1]) && error("Not in modern mode. Must run 'gmtbegin' first")
 
	cmd = "figure"       # Default name (GMTplot.ps) is set in gmt_main()
	(name == "") && error("figure name cannot be empty")
	cmd *= " " * get_format(name, fmt)
	(opts != "") && (cmd *= " " * opts)
	gmt(cmd)
	return nothing
end

function inset(fim=nothing; stop=false, kwargs...)
 
	d = KW(kwargs)
	cmd, = parse_common_opts(d, "", [:c :F :V_params], true)
	cmd  = parse_these_opts(cmd, d, [[:M :margins], [:N :no_clip :noclip]])
	cmd  = parse_type_anchor(d, cmd, [:D :inset :inset_box :insetbox],
	                        (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), width="+w", size="+w", justify="+j", offset=("+o", arg2str)), 'j')
	cmd = add_opt(d, cmd, "C", [:C :clearance],
				  (left=(" -Cw", arg2str), right=(" -Ce", arg2str), bott=(" -Cs", arg2str), bottom=(" -Cs", arg2str), top=(" -Cn", arg2str), lr=(" -Cx", arg2str), tb=(" -Cy", arg2str)))

	do_show = false
	if (fim !== nothing)
		t = lowercase(string(fim))
		(t == "end" || t == "stop" || t == "show") && (stop = true)
		(t == "show") && (do_show = true)
	end

	if (!stop)
		(dbg_print_cmd(d, cmd) !== nothing) && return cmd		# Vd=2 cause this return
		(!IamModern[1]) && error("Not in modern mode. Must run 'gmtbegin' first")
		IamInset[1] = true
		gmt("inset begin " * cmd);
	else
		(!IamModern[1]) && error("Not in modern mode. Must run 'gmtbegin' first")
		IamInset[1] = false
		gmt("inset end");
		(do_show || haskey(d, :show)) && gmt("end" * show)
	end
end

function get_format(name, fmt=nothing, d=nothing)
	# Get the fig name and format. If format not specified, default to FMT (ps)
	# NAME is supposed to always exist (otherwise, errors)
	fname::String, ext::String = splitext(string(name)::String)
	if (ext != "")
		fname *= " " * ext[2:end]
	elseif (fmt !== nothing)
		fname *= " " * string(fmt)::String      # No checking
	elseif (d !== nothing)
		if (haskey(d, :fmt))  fname *= " " * string(d[:fmt])::String
		else                  fname *= " " * FMT[1]::String		# Then use default format
		end
	else
		fname *= " " * FMT[1]::String
	end
	return fname
end