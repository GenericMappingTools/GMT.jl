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
function inset_nested(nt::NamedTuple, n)	# In this method, the first el of NT contains the data or a zoom
	# N is the number of the inset. Used only to name the temporary inset PS file
	k,v = keys(nt), values(nt)
	d = Dict{Symbol,Any}(k[2:end] .=> v[2:end])			# Drop first el because it contains the input data
	#(!(:inset_box in k) && !(:insetbox in k) && !(:D in k)) && (d[:D] = "jTR")		# Make sure -D is set
	if (k[1] == :zoom)						# Make a zoom window centered on the coords passed in the zoom tuple
		zoom(d, v[1])						# Set the -R for the requested zoom
		inset_nested(CTRL.pocket_call[4], n; d...)
		((opt_R = get(d, :R, "")) != "") && (CTRL.pocket_call[4] = opt_R)	# Save for drawing rect in the main fig
		CTRL.pocket_call[4] = ((opt_R = get(d, :R, "")) != "") ? opt_R : nothing
		# And the helper1_inset_nested() has saved the zoomed rectangle limits in CTRL.pocket_call[5]
	else
		inset_nested(nt[1], n; d...)
	end
end

# ---------------------------------------------------------------------------------------------------
function inset_nested(GI::GItype, n; kwargs...)
	d = KW(kwargs)
	d, fname, opt_B, opt_J, opt_R = helper1_inset_nested(d)			# fname is gmt_0.ps- file in modern session

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
	helper2_inset_nested(fname, n)			# end's inset(), moves fname to TMP and calls gmtend()
end

# ---------------------------------------------------------------------------------------------------
function inset_nested(D::GDtype, n; kwargs...)
	d = KW(kwargs)
	d, fname, opt_B, opt_J, opt_R = helper1_inset_nested(d; isplot=true)	# Calls inset(). fname is gmt_0.ps- file in modern session

	(opt_J == "") && (d[:J] = "X?/?")
	if (opt_R == "")
		bb = getbb(D)
		opt_R = sprintf(" -R%.12g/%.12g/%.12g/%.12g", bb...)
	end
	d[:R] = opt_R[4:end]
	(opt_B != "") && (d[:B] = opt_B[4:end])
	d[:par] = ("MAP_FRAME_PEN", "0.75")	# For some reason it lost the theme set value (this) and went back to the GMT default.

	plot(D; d...)
	helper2_inset_nested(fname, n)		# end's inset(), moves fname to TMP and calls gmtend()
end

# ---------------------------------------------------------------------------------------------------
function inset_nested(f::Function, n; kwargs...)
	# This method is only called from the firs inset_nested(nt::NamedTuple, n) when nt[1] is a function
	d = KW(kwargs)
	d, fname, opt_B, opt_J, opt_R = helper1_inset_nested(d; iscoast=(f == coast))	# fname is gmt_0.ps- file in modern session

	# J option, if provided, comes out with the size too but we don't want it. Ex: pocket_J[1] = [" -JG0/0/15c", "15c"]
	(opt_J != "") && (opt_J = replace(opt_J[4:end], CTRL.pocket_J[2] => "?"))	#  becomes "G0/0/?"
	d[:J] = (opt_J == "") ? "X?" : opt_J
	(opt_B == "") && (d[:B] = opt_B[4:end])
	(opt_R != "") && (d[:R] = opt_R[4:end])

	f(; d...)
	helper2_inset_nested(fname, n)			# end's inset(), moves fname to TMP and calls gmtend()
end

# ---------------------------------------------------------------------------------------------------
function helper1_inset_nested(d; iscoast=false, isplot=false)
	# All inset_nested methods start with this. Also sets some defaults.
	fig_opt_R, fig_opt_J = CTRL.pocket_R[1], CTRL.pocket_J[1]	# Main fig region and proj. Need these to cheat the modern session
	bak = CTRL.limits[7:end]						# Backup these because parse_R will change them
	_, opt_B::String, opt_J::String, opt_R::String = parse_BJR(d, "", "", false, " ")
	CTRL.limits[7:end] = bak						# and we don't want that change to be stored
	fname = hack_modern_session(fig_opt_R, fig_opt_J)	# Start a modern session and return the full name of the gmt_0.ps- file
	!haskey(d, :box) && (d[:F] = iscoast ? "+c1p+p0.5+gwhite" : isplot ? "+gwhite" : "+c1p+p0.5")

	fish_size_from_J(fig_opt_J)				# Get fig size in numeric so we can compute aspect ratio and default inset size
	W, H = CTRL.figsize[1:2]
	aspect_fig = W / H
	inset_W = W / 2.5						# Default to 1/2.5 of the fig width
	inset_H = inset_W / aspect_fig
	anchor = "TR"							# The default anchor location is top right (TR). Bellow we may change this.
	if ((val = find_in_dict(d, [:Rzoom_num])[1]) !== nothing)	# Get zoom limits in numeric
		Rnum::Vector{Float64} = val			# F Anys
		lims_zoom = gmt("mapproject" * fig_opt_R * fig_opt_J, [Rnum[1] Rnum[3]; Rnum[2] Rnum[4]])
		center_zoom = ((Rnum[1] + Rnum[2]) / 2, (Rnum[3] + Rnum[4]) / 2)
		center_fig  = ((CTRL.limits[8] + CTRL.limits[7]) / 2, (CTRL.limits[10] + CTRL.limits[9]) / 2)

		if (center_zoom[1] <= center_fig[1])
			quad = (center_zoom[2] <= center_fig[2]) ? 3 : 2
		else
			quad = (center_zoom[2] <= center_fig[2]) ? 4 : 1
		end
		anchor = (quad == 1) ? "BL" : (quad == 2) ? "BR" : (quad == 3) ? "TR" : "TL"	# Put inset in the opposite quadrant of the zoom window

		aspect_zoom = (lims_zoom[4] - lims_zoom[3]) / (lims_zoom[2] - lims_zoom[1])		# Aspect ratio of the zoom window: Y/X
		inset_H = inset_W * aspect_zoom
		if (inset_H > H - 0.75)				# The 0.75 intends to account for the labels and def offset
			f = (H - 0.75) / inset_H * 0.95
			inset_W *= f;	inset_H *= f
		end
		delete!(d, :Rzoom_num)
	end

	(is_in_dict(d, [:D :inset_box :insetbox]) === nothing) &&
		(d[:D] = isplot ? "j$(anchor)+o0.15+w$(inset_W)/$(inset_H)" : "j$(anchor)+o0.15+w$inset_W")

	t::String = get(d, :D, "")				# Don't use d[:D] directly because it's a Any
	(t == "") && (t = parse_type_anchor(d, "", [:D :inset :inset_box :insetbox],
	              (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), width="+w", size="+w", justify="+j", offset=("+o", arg2str)), 'j'))
	if     (contains(t, "TR") || contains(t, "RT")) opt_B = replace(opt_B, "WSen" => "WSrt")
	elseif (contains(t, "BR") || contains(t, "RB")) opt_B = replace(opt_B, "WSen" => "WNbr")
	elseif (contains(t, "TL") || contains(t, "LT")) opt_B = replace(opt_B, "WSen" => "SEtl")
	elseif (contains(t, "BL") || contains(t, "LB")) opt_B = replace(opt_B, "WSen" => "ENlb")
	end
	(t[1] == ' ') && (t = t[4:end])			# When a -D was provided and parse_type_anchor was called.
	!contains(t, "+o") && (t *= "+o0.15")	# Use a little margin by default
	!contains(t, "+w") && (t *= isplot ? "+w$(inset_W)/$(inset_H)" : "+w$inset_W")	# If no size was provided
	d[:D] = t

	if (isplot)
		(is_in_dict(d, [:N :no_clip :noclip]) === nothing) && (d[:N] = true)	# Otherwise we loose the annotations
	end
	(opt_R != "") && (d[:R] = opt_R[4:end])
	inset(; d...)
	delete!(d, [[:D :inset_box :insetbox], [:F :box]])	# Some of these exist in module called in inset, so must remove them now
	CTRL.pocket_call[5] = sniff_inset_coords(fname, fig_opt_R, fig_opt_J)		# inset limts in data units
	return d, fname, opt_B, opt_J, opt_R
end

function helper2_inset_nested(fname, n)
	# All inset_nested methods end with this
	inset(:end)
	mv(fname, TMPDIR_USR[1] * "/" * "GMTjl__inset__$(n).ps", force=true)
	gmtend()		# hack_modern_session() issued the opening gmtbegin() call
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    limits = sniff_inset_coords(fname, opt_R, opt_J) -> Matrix(4x4)

Sniff in the session's gmt.inset.0 file and extract the inset limits in data units.
"""
function sniff_inset_coords(psname, fig_opt_R, fig_opt_J)
	name = split(psname, "gmt_0.ps-")[1] * "gmt.inset.0"
	fid  = open(name, "r")
	iter = eachline(fid)
	local o, d
	for it in iter
		startswith(it, "# ORIGIN: ")    && (o = parse.(Float64, string.(split(it[11:end])))*2.54)
		startswith(it, "# DIMENSION: ") && (d = parse.(Float64, string.(split(it[14:end])))*2.54; break)
	end
	close(fid)
	diag = gmt("mapproject -I" * fig_opt_R * fig_opt_J, [o[1] o[2]; o[1]+d[1] o[2]+d[2]])
	return [diag[1], diag[2], diag[3], diag[4]]		# Like the -R args
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

# ---------------------------------------------------------------------------------------------------
function zoom(d, center)
	# Compute the -R for the requested rectangle and set in 'd'.
	data::Union{GDtype, GItype} = CTRL.pocket_call[4]
	if (isa(data, GItype))
		zoom_lims = [max(center[1] - center[3], data.range[1]), min(center[1] + center[3], data.range[2]), max(center[1] + center[3], data.range[3]), min(center[2] + center[3], data.range[4])]
	else
		if (isa(data, GDtype))
			xmima::Vector{Float64} = [max(center[1] - center[2], data.bbox[1]), min(center[1] + center[2], data.bbox[2])]
			n1, n2 = 0, 0
			while(data[n1+=1,1] < xmima[1]) end			# When it finish data[n1] >= xmima[1]
			while(data[n2+=1,1] < xmima[2]) end			# When it finish data[n2] >= xmima[2]
			#ymima::Vector{Float64} = [extrema(data[n1:n2,2])...]
		end
		D = mat2ds(data.data[n1:n2, 1:2], data)			# WTF do I have to do this? -R should be enough.
		DYpct = (D.ds_bbox[4] - D.ds_bbox[3]) * 0.01	# 1% of the Y data limits
		D.ds_bbox[3] -= DYpct
		D.ds_bbox[4] += DYpct
		bak = CTRL.limits[7:end]						# Backup these because round_wesn will change them
		zoom_lims::Vector{Float64} = round_wesn(D.ds_bbox)
		CTRL.limits[7:end] = bak						# and we don't want that change to be stored
		CTRL.pocket_call[4] = D
	end
	d[:R] = sprintf("%.15g/%.15g/%.15g/%.15g", zoom_lims...)
	d[:Rzoom_num] = zoom_lims
	return nothing
end
