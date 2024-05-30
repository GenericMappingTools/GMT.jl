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
	IamSubplot[1] = false
	FirstModern[1] = true			# To know if we need to compute -R in plot. Due to a GMT6.0 BUG
	isJupyter[1] = isdefined(Main, :IJulia)		# show fig relies on this
	!isJupyter[1] && (isJupyter[1] = (isdefined(Main, :VSCodeServer) && get(ENV, "DISPLAY_IN_VSC", "") != ""))
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
	(verbose !== nothing) && (cmd *= " -V" * string(verbose))
	if (IamSubplot[1])		# This should never happen. Unless user error of calling gmtend() before time.
		@warn("ERROR USING SUBPLOT. You should not call gmtend() before subplot(:end)")
		gmt("subplot end")
	end
	((arg !== nothing || show != 0) && !isFranklin[1]) ? (helper_showfig4modern("show")) : gmt(cmd)
	resetGMT()
	isPSclosed[1] = true
	return nothing
end
 
"""
	gmtfig(name::String; fmt=nothing, opts="")

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

# ---------------------------------------------------------------------------------------------------
function inset(fim::StrSymb=""; stop=false, kwargs...)
 
	d = KW(kwargs)
	cmd, = parse_common_opts(d, "", [:c :F :V_params], true)
	cmd  = parse_these_opts(cmd, d, [[:M :margins], [:N :no_clip :noclip]])
	cmd  = parse_type_anchor(d, cmd, [:D :inset :inset_box :insetbox],
	                        (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), width="+w", size="+w", justify="+j", offset=("+o", arg2str)), 'j')
	cmd = add_opt(d, cmd, "C", [:C :clearance],
				  (left=(" -Cw", arg2str), right=(" -Ce", arg2str), bott=(" -Cs", arg2str), bottom=(" -Cs", arg2str), top=(" -Cn", arg2str), lr=(" -Cx", arg2str), tb=(" -Cy", arg2str)))

	do_show = false
	if (fim != "")
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
	CTRL.pocket_d[1] = d		# Store d that may be not empty with members to use in other modules
end

function get_format(name, fmt=nothing, d=nothing)
	# Get the fig name and format. If format is not specified, default to FMT (ps)
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

# ---------------------------------------------------------------------------------------------------
function inset_cm(nt::NamedTuple, n)		# With this method, the first el of NT contains the data
	k,v = keys(nt), values(nt)
	d = Dict{Symbol,Any}(k[2:end] .=> v[2:end])			# Drop first el because it contains the input data
	(!(:inset_box in k) && !(:insetbox in k) && !(:D in k)) && (d[:D] = (anchor=:TR, width=5, offset=0.1))
	inset_cm(nt[1], n; d...)
end
function inset_cm(GI::GItype, n; kwargs...)
	d = KW(kwargs)
	d, fname, opt_B, opt_J, opt_R = helper1_inset_cm(d)			# fname is gmt_0.ps- file in modern session

	if (opt_J == "")
		opt_J = isgeog(GI) ? guess_proj(GI.range[1:2], GI.range[3:4]) : " -JX"
		opt_J = contains(opt_J, "/") ? opt_J * "/?" : opt_J * "?"
		CTRL.pocket_d[1][:J] = opt_J[4:end]
	end
	if (opt_R == "")
		opt_R = sprintf(" -R%.12g/%.12g/%.12g/%.12g", GI.range[1], GI.range[2], GI.range[3], GI.range[4])	# Get the current GI
		CTRL.pocket_d[1][:R] = opt_R[4:end]
	end
	(opt_B == "") && (CTRL.pocket_d[1][:B] = opt_B[4:end])

	grdimage(GI; CTRL.pocket_d[1]...)
	helper2_inset_cm(fname, n)			# end's inset(), moves fname to TMP and calls gmtend()
end

# ---------------------------------------------------------------------------------------------------
function inset_cm(D::GDtype, n; kwargs...)
	d = KW(kwargs)
	d, fname, opt_B, opt_J, opt_R = helper1_inset_cm(d; isplot=true)	# Calls inset(). fname is gmt_0.ps- file in modern session

	(opt_J == "") && (d[:J] = "X?/?")
	if (opt_R == "")
		bb = getbb(D)
		opt_R = sprintf("%.12g/%.12g/%.12g/%.12g", bb...)
		d[:R] = opt_R
	end
	(opt_B != "") && (d[:B] = opt_B[4:end])

	plot(D; Vd=1, d...)
	helper2_inset_cm(fname, n)			# end's inset(), moves fname to TMP and calls gmtend()
end

# ---------------------------------------------------------------------------------------------------
function inset_cm(f::Function, n; kwargs...)
	d = KW(kwargs)
	d, fname, opt_B, opt_J, opt_R = helper1_inset_cm(d; iscoast=true)	# fname is gmt_0.ps- file in modern session

	# J option, if provided, comes out with the size too but we don't want it. Ex: pocket_J[1] = [" -JG0/0/15c", "15c"]
	(opt_J != "") && (opt_J = replace(opt_J[4:end], CTRL.pocket_J[2] => "?"))	#  becomes "G0/0/?"
	d[:J] = (opt_J == "") ? "X?" : opt_J
	(opt_B == "") && (d[:B] = opt_B[4:end])
	(opt_R != "") && (d[:R] = opt_R[4:end])

	f(; d...)
	helper2_inset_cm(fname, n)			# end's inset(), moves fname to TMP and calls gmtend()
end

function helper1_inset_cm(d; iscoast=false, isplot=false)
	# All inset_cm methods start with this. Also sets some defaults.
	fig_opt_R, fig_opt_J = CTRL.pocket_R[1], CTRL.pocket_J[1]	# Main fig region and proj. Need these to cheat the modern session
	_, opt_B::String, opt_J::String, opt_R::String = parse_BJR(d, "", "", false, " ")
	fname = hack_modern_session(fig_opt_R, fig_opt_J)	# Start a modern session and return the full name of the gmt_0.ps- file
	!haskey(d, :box) && (d[:F] = iscoast ? "+c1p+p0.5+gwhite" : isplot ? "+gwhite" : "+c1p+p0.5")
	if (isplot)
		(is_in_dict(d, [:D :inset_box :insetbox]) === nothing) && (d[:D] = "jTR+w6/5+o0.1")
		(is_in_dict(d, [:N :no_clip :noclip]) === nothing) && (d[:N] = true)
	end
	inset(; d...)
	delete!(d, [[:D :inset_box :insetbox], [:F :box]])	# Some of these exist in module called in inset, so must remove them now
	return d, fname, opt_B, opt_J, opt_R
end
function helper2_inset_cm(fname, n)
	# All inset_cm methods end with this
	inset(:end)
	mv(fname, TMPDIR_USR[1] * "/" * "GMTjl__inset__$(n).ps", force=true)
	gmtend()		# hack_modern_session() issued the opening gmtbegin() call
end

# ---------------------------------------------------------------------------------------------------
function hack_modern_session(opt_R, opt_J)
	gmt("begin")
	gmt("basemap " * opt_R * opt_J * " -Blrbt")
	API = unsafe_load(convert(Ptr{GMTAPI_CTRL}, G_API[1]))
	session_dir = unsafe_string(API.gwf_dir)
	fname = session_dir * filesep * "gmt_0.ps-"
	rm(fname)				# To remove PS headers and such
	touch(fname)			# Create a new empty one that is needed to later code be appended.
	return fname
end
##

# ---------------------------------------------------------------------------------------------------
# To have to do this every time we need to get the bounding box of a dataset (or vector of them)
getbb(D::GDtype) = isa(D, Vector) ? D[1].ds_bbox : D.ds_bbox
