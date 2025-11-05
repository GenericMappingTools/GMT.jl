"""
	gmtbegin(name::String=""; fmt)

Start a GMT session in modern mode (GMT >= 6).
'name' contains the figure name with or without extension. If an extension is used 
(e.g. "map.pdf") it is used to select the image format.

As an alternative use 'fmt' as a string or symbol containing the format (ps, pdf, png, PNG, tif, jpg, eps).

By default name="GMTplot" and fmt="ps"
"""
function gmtbegin(name::String=""; fmt=nothing, verbose=nothing)
	DidOneGmtCmd[] && resetGMT()		# Reset everything to a fresh GMT session. That is reset all global variables to their initial state
	cmd = "begin"       # Default name (GMTplot.ps) is set in gmt_main()
	(name != "") && (cmd *= " " * get_format(name, fmt))
	(verbose !== nothing) && (cmd *= " -V" * string(verbose))
	IamSubplot[] = false
	FirstModern[] = true			# To know if we need to compute -R in plot. Due to a GMT6.0 BUG
	isJupyter[] = isdefined(Main, :IJulia)		# show fig relies on this
	!isJupyter[] && (isJupyter[] = (isdefined(Main, :VSCodeServer) && get(ENV, "DISPLAY_IN_VSC", "") != ""))
	gmt(cmd)
	return nothing
end

"""
	gmtend(show=false, verbose=nothing)

Ends a GMT session in modern mode and optionaly shows the figure
"""
function gmtend(arg=nothing; show=false, verbose=nothing, reset::Bool=true)
	# To show either do gmtend(whatever) or gmt(show=true)
	cmd = "end"
	(verbose !== nothing) && (cmd *= " -V" * string(verbose))
	if (IamSubplot[])		# This should never happen. Unless user error of calling gmtend() before time.
		@warn("ERROR USING SUBPLOT. You should not call gmtend() before subplot(:end)")
		gmt("subplot end")
	end
	((arg !== nothing || show != 0) && !isFranklin[]) ? (helper_showfig4modern("show")) : gmt(cmd)
	reset && resetGMT()
	!reset && (IamModern[] = false;	FirstModern[] = false)
	isPSclosed[] = true
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
	(!IamModern[]) && error("Not in modern mode. Must run 'gmtbegin' first")
 
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
	cmd, = parse_common_opts(d, "", [:c :F :V_params], first=true)
	cmd  = parse_these_opts(cmd, d, [[:M :margins], [:N :no_clip :noclip]])
	cmd  = parse_type_anchor(d, cmd, [:D :pos :position :inset :inset_box :insetbox],
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
		(dbg_print_cmd(d, cmd) !== nothing) && return cmd	# Vd=2 cause this return
		(!IamModern[]) && error("Not in modern mode. Must run 'gmtbegin' first")
		IamInset[1] = true
		contains(cmd, " -J") && (IamInset[2] = true)		# 'true' means we don't fetch the CTRL.pocket_J[1] to prevent GMT bug #7005
		gmt("inset begin " * cmd);
	else
		(!IamModern[]) && error("Not in modern mode. Must run 'gmtbegin' first")
		IamInset[1], IamInset[2] = false, false
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
		else                  fname *= " " * FMT[]::String		# Then use default format
		end
	else
		fname *= " " * FMT[]::String
	end
	return fname
end

#Ex: viz(I15, proj=:guess, inset=(I14, pos=(anchor=:BR, width=5, offset=0.1), F=true, C="5p"))
#im = gmtread("NGC_3372a-full.jpg");
#viz(im, inset=(zoom=(1070,440,50), pos=(width=3,)))
#viz(im, inset=(zoom=(1030,1110,380,500),))
#viz("NGC_3372a-full.jpg", inset=(name="dedo_hr.jpg", pos=(anchor=:BL,)))
#gdal_translate -srcwin 10580 9410 780 860 NGC_3372a-full__.jpg dedo_hr.jpg
#t = 0:0.1:2pi;
#plot(t, cos.(t), inset=(zoom=(pi,pi/4), box=(fill=:gray,)), show=1)
#viz(G, J=:merc, inset=(coast, R="-80/-28/-43/10", J=:merc, shore=true, pos=(anchor=:TR,), plot=(data=[-45.5 -23], marker=:circ, fill=:red) ))
#viz(G, J=:merc, inset=(coast, R="-80/-28/-43/10", J=:merc, shore=true, rect=(2,:red)))
# ---------------------------------------------------------------------------------------------------
function inset_nested(nt::NamedTuple, n)	# In this method, the first el of NT contains the data or a zoom
	# N is the number of the inset. Used only to name the temporary inset PS file
	k,v = keys(nt), values(nt)
	d = Dict{Symbol,Any}(k[2:end] .=> v[2:end])		# Drop first el because it contains the input data
	if (k[1] == :zoom)								# Make a zoom window centered on the coords passed in the zoom tuple
		zoom2inset(d, v[1])							# Compute the -R for the requested rectangle and set in 'd'
		inset_nested(CTRL.pocket_call[4], n; d...)	# Do the plotting in a modern mode session, of the inset contents.
		CTRL.pocket_call[4] = ((opt_R = get(d, :R, "")) != "") ? opt_R : nothing	# Save for drawing zoom rect in the main fig
		# And the helper1_inset_nested() has saved the zoomed rectangle limits in CTRL.pocket_call[5]
	else
		inset_nested(isa(nt[1], Matrix{<:Real}) ? mat2ds(nt[1]) : nt[1], n; d...)
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
inset_nested(fname::String, n; kwargs...) = inset_nested(gmtread(fname), n; kwargs...)

# ---------------------------------------------------------------------------------------------------
function inset_nested(GI::GItype, n; kwargs...)
	d = KW(kwargs)
	W, H = getsize(GI)			# width (columns) and height (rows)
	d, fname, opt_B, opt_J, opt_R = helper1_inset_nested(d, imgdims=(H, W))	# fname is gmt_0.ps- file in modern session

	if (opt_J == "")
		opt_J = isgeog(GI) ? guess_proj(GI.range[1:2], GI.range[3:4]) : " -JX"
		opt_J = contains(opt_J, "/") ? opt_J * "/?" : opt_J * "?"
		contains(opt_J, '?') && (IamInset[2] = true)	# To help avoid GMT bug #7005
	end
	CTRL.pocket_d[1][:J] = opt_J[4:end]

	if (opt_R == "")
		opt_R = @sprintf(" -R%.12g/%.12g/%.12g/%.12g", GI.range[1], GI.range[2], GI.range[3], GI.range[4])	# Get the current GI
		CTRL.pocket_d[1][:R] = opt_R[4:end]
	end
	(opt_B == " -B0") && (opt_B = " -Bnone")	# No frame border so that the inset box pen (-F) may take effect.
	(opt_B != "") && (CTRL.pocket_d[1][:B] = opt_B[4:end])

	grdimage(GI; CTRL.pocket_d[1]...)
	helper2_inset_nested(fname, n)				# end's inset(), moves fname to TMP and calls gmtend()
	CTRL.pocket_call[4] = ((opt_R = get(d, :R, "")) != "") ? opt_R : nothing
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function inset_nested(D::GDtype, n; kwargs...)
	d = KW(kwargs)
	d, fname, opt_B, opt_J, opt_R = helper1_inset_nested(d; isplot=true)	# Calls inset(). fname is gmt_0.ps- file in modern session

	(opt_J == "") && (d[:J] = "X?/?"; IamInset[2] = true)	# IamInset[2] is to help avoid GMT bug #7005
	if (opt_R == "")
		bb = getbb(D)
		opt_R = @sprintf(" -R%.12g/%.12g/%.12g/%.12g", bb...)
	end
	d[:R] = opt_R[4:end]
	(opt_B != "") && (d[:B] = opt_B[4:end])
	d[:par] = ("MAP_FRAME_PEN", "0.75")	# For some reason it lost the theme set value (this) and went back to the GMT default.

	plot(D; d...)						# Do the plotting.
	helper2_inset_nested(fname, n)		# end's inset(), moves fname to TMP and calls gmtend()
end

# ---------------------------------------------------------------------------------------------------
function inset_nested(f::Function, n; kwargs...)::Nothing
	# This method is only called from the first inset_nested(nt::NamedTuple, n) when nt[1] is a function
	d = KW(kwargs)
	d, fname, opt_B, opt_J, opt_R = helper1_inset_nested(d; iscoast=(f == coast))	# fname is gmt_0.ps- file in modern session

	# J option, if provided, comes out with the size too but we don't want it. Ex: pocket_J[1] = [" -JG0/0/15c", "15c"]
	(opt_J != "") && (opt_J = replace(opt_J[4:end], CTRL.pocket_J[2] => "?"))	#  becomes "G0/0/?"
	d[:J] = (opt_J == "") ? "X?" : opt_J
	(opt_B == "") && (d[:B] = opt_B[4:end])
	(opt_R != "") && (d[:R] = opt_R[4:end])

	if (f == coast && (val = find_in_dict(d, [:rect :rectangle])[1]) !== nothing)
		# To draw a rectangle we accept: a Bool, a symbol or a string, or a Tuple of string/symbol and a number
		# If a string or symbol is provided, it is used as the line color. If a number is provided, it is used as the thickness.
		# To set both color and thickness, provide a tuple (lc, lt) or (lt, lc).
		R = CTRL.limits[7:end]
		lc::String, lt::String = "blue", "0.75"				# Defaults (corresponding to rect=true)
		if (isa(val, StrSymb))
			lc = string(val)::String
		elseif (isa(val, Real))
			!isa(val, Bool) && (lt = string(val)::String)
		elseif (isa(val, Tuple))			# (lc, lt) or (lt, lc), where color is a string or a symbol and thickness is a real
			t = string.(val)
			if isa(val[1], StrSymb)  lc,lt = t
			else                     lt,lc = t
			end
		end
		D = mat2ds([R[1] R[3]; R[1] R[4]; R[2] R[4]; R[2] R[3]; R[1] R[3]], lc=lc, lt=lt)
		d[:plot] = (data=D,)				# Draw a box in the inset with the limits of the main fig
	end
	(f == coast && get(d, :N, "") != "") && delete!(d, :N)	# That N was for no-clip
	f(; d...)
	helper2_inset_nested(fname, n)			# end's inset(), moves fname to TMP and calls gmtend()
end

# ---------------------------------------------------------------------------------------------------
function helper1_inset_nested(d; iscoast=false, isplot=false, imgdims=tuple())
	# All inset_nested methods start with this. Also sets some defaults.
	fig_opt_R, fig_opt_J = CTRL.pocket_R[1], CTRL.pocket_J[1]	# Main fig region and proj. Need these to cheat the modern session
	bak = CTRL.limits[7:end]							# Backup these because parse_R will change them
	_, opt_B::String, opt_J::String, opt_R::String = parse_BJR(d, "", "", false, " ")
	CTRL.limits[7:end] = bak							# and we don't want that change to be stored
	islinear = (opt_J == "" || opt_J[4] == 'X' || opt_J[4] == 'x');
	fname = hack_modern_session(fig_opt_R, fig_opt_J)	# Start a modern session and return the full name of the gmt_0.ps- file
	!haskey(d, :box) && (d[:F] = iscoast ? "+c1p+p0.5+gwhite" : isplot ? "+gwhite" : "+p0.5+c1p+gwhite")

	# Something is not right in API. If we call this after fish_size_from_J() (that also calls mapproject) the inset location is wrong.
	if (iscoast || !islinear)  cW, cH = gmt("mapproject -W " * opt_R * opt_J).data  end

	fish_size_from_J(fig_opt_J, onlylinear=false, opt_R=fig_opt_R)		# Get fig size in numeric so we can compute default inset size
	W, H = CTRL.figsize[1:2]
	if (H == 0)								# Happens when we have a -JX15/0
		fig_R = parse.(Float64, string.(split(fig_opt_R[4:end], '/')))	# Het H from the fig's aspect ratio
		H = (fig_R[4] - fig_R[3]) / (fig_R[2] - fig_R[1]) * W			# Hope this is always correct.
		CTRL.figsize[2] = H
	end
	aspect_fig = W / H
	inset_W = W / (isplot ? 3.0 : 4.0)		# Default to 1/3 or 1/4 of the fig width
	inset_H = inset_W / aspect_fig
	anchor = "TR"							# The default anchor location is top right (TR). Bellow we may change this.
	aspect_zoom = 0.0						# Also useful to know if we are zooming.
	if ((val = find_in_dict(d, [:Rzoom_num])[1]) !== nothing)	# The ZOOM case. Get zoom limits in numeric (in data units)
		Rnum::Vector{Float64} = val			# F Anys. In data units
		lims_zoom = gmt("mapproject" * fig_opt_R * fig_opt_J, [Rnum[1] Rnum[3]; Rnum[2] Rnum[4]])	# in paper units (cm)
		aspect_zoom = (lims_zoom[4] - lims_zoom[3]) / (lims_zoom[2] - lims_zoom[1])		# Aspect ratio of the zoom window: Y/X
		inset_H = inset_W * aspect_zoom
		if (inset_H > H - 0.75)				# The 0.75 intends to account for the labels and def offset
			f = (H - 0.75) / inset_H * 0.95
			inset_W *= f;	inset_H *= f
		end
		anchor = floating_window(W, H, inset_W, inset_H, lims_zoom)			# Get the anchor location of the inset
	elseif (!isempty(imgdims))				# The IMAGE case. Use the image dimensions to compute the aspect ratio. -JX only?
		aspect_zoom = (islinear) ? imgdims[1] / imgdims[2] : cH / cW		# image's aspect ratio: Y/X
		inset_H = inset_W * aspect_zoom
		if ((val = find_in_dict(d, [:pzoom])[1]) !== nothing)		# A pseudo-zoom from a single point.
			val_f::Vector{Float64} = [Float64(val[1]), Float64(val[2])]
			d[:R] = @sprintf("%.15g/%.15g/%.15g/%.15g", val_f[1], val_f[1]*1.001, val_f[2], val_f[2]*1.001)
			delete!(d, :pzoom)
		end
		(opt_J != "" && !contains(opt_J, '?')) && (opt_J = replace(opt_J, CTRL.pocket_J[2] => "?"))	# Replace the fig's default size
		(opt_J == "") && (opt_J = " -JX?")
	elseif (iscoast)
		inset_H = inset_W * cH / cW
	end

	(!isplot && opt_B == DEF_FIG_AXES_BAK) && (opt_B = " -B0")		# For images e coast the default is no annots.

	(is_in_dict(d, [:D :pos :position :inset_box :insetbox]) === nothing) && (d[:D] = "j$(anchor)+o0.15+w$(inset_W)/$(inset_H)")

	t::String = get(d, :D, "")				# Don't use d[:D] directly because it's a Any
	(t == "") && (t = parse_type_anchor(d, "", [:D :pos :position :inset_box :insetbox],
	              (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), width="+w", size="+w", justify="+j", offset=("+o", arg2str)), 'j'))
	if     (contains(t, "TR") || contains(t, "RT")) opt_B = replace(opt_B, "WSen" => "WSrt")
	elseif (contains(t, "BR") || contains(t, "RB")) opt_B = replace(opt_B, "WSen" => "WNbr")
	elseif (contains(t, "TL") || contains(t, "LT")) opt_B = replace(opt_B, "WSen" => "SEtl")
	elseif (contains(t, "BL") || contains(t, "LB")) opt_B = replace(opt_B, "WSen" => "ENlb")
	end
	(t[1] == ' ') && (t = t[4:end])			# When a -D was provided and parse_type_anchor was called.
	t[2] == '+' && (t = t[1] * anchor * t[2:end])	# No anchor was provided but we need to have one.
	!contains(t, "+o") && (t *= "+o0.15")	# Use a little margin by default
	if (!contains(t, "+w"))					# If no size was provided
		t *= "+w$(inset_W)/$(inset_H)"
	else
		siz = split(split(t, "+w")[2], '+')[1]	# "jTR+w5+o0.15" becomes "5"
		if (!contains(siz, "/"))				# If both width and height were provided, we don't touch users choice
			inset_H = (aspect_zoom != 0.0) ? parse(Float64, siz) * aspect_zoom : parse(Float64, siz) / aspect_fig
			t = replace(t, "+w$siz" => "+w$siz/$inset_H")
		end
	end
	d[:D] = t									# In case :D got default values above t = d[:D]

	(is_in_dict(d, [:N :no_clip :noclip]) === nothing) && (d[:N] = true)	# Otherwise we loose the annotations
	(opt_R != "") && (d[:R] = opt_R[4:end])
	inset(; d...)								# Initialize the inset but doesn't plot anything yet.
	delete!(d, [[:D :pos :position :inset_box :insetbox], [:F :box]])	# Some of these exist in module called in inset, must remove them now
	CTRL.pocket_call[5] = sniff_inset_coords(fname, fig_opt_R, fig_opt_J)	# inset limts in data units
	return d, fname, opt_B, opt_J, opt_R
end

# ---------------------------------------------------------------------------------------------------
function helper2_inset_nested(fname, n)::Nothing
	# All inset_nested methods end with this
	inset(:end)
	mv(fname, TMPDIR_USR[1] * "/" * "GMTjl__inset__$(n).ps", force=true)
	gmtend()		# hack_modern_session() issued the opening gmtbegin() call
	return nothing
end

# ---------------------------------------------------------------------------------------------------
"""
    code = floating_window(fig_W, fig_H, float_W, float_H, lims_zoom) -> String

Given the size of the figure, the size of the inset and the zoom limits, compute the anchor location
of the inset such that it doesn't overlap with the zoom window. All inputs are in paper units.

It works like this: The figure window is divided in a 3x3 cells matrix. We compute in which cell falls the
center of the zoom window. Next, we try to place the inset either above or below the zoom window.
The rational for this is that if those positions are good it si almost sure that the inset will not overlap
the data being displayed. If it doesn't fit, we try the next position to the right along the top or bottom
rows of the 3x3 matrix. In each test, we always check if zoom and inset windows overlap.

- `fig_W` and `fig_H` are the size of the figure in paper units:
- `float_W` and `float_H` are the size of the inset in paper units:
- `lims_zoom`: is a vector of 4 numbers: [xmin xmax ymin ymax] in paper units with limits of the zoom window.
"""
function floating_window(fig_W, fig_H, float_W, float_H, lims_zoom)

	zoom_W, zoom_H = lims_zoom[2] - lims_zoom[1], lims_zoom[4] - lims_zoom[3]
	zoom_c  = ((lims_zoom[1] + lims_zoom[2]) / 2, (lims_zoom[3] + lims_zoom[4]) / 2)
	col = div(zoom_c[1], fig_W / 3) + 1		# Column index
	row = div(zoom_c[2], fig_H / 3) + 1		# Row index
	float_W2, float_H2, fig_W3 = float_W / 2, float_H / 2, fig_W / 3

	if (row == 1)
		if (col == 1)
			xc_2, yc_2 = float_W2, fig_H - float_H2
			anchor = "TR"			# When the other positions fail resort to this
			if     (!rect_overlap(zoom_c[1], zoom_c[2], xc_2, yc_2, zoom_W, zoom_H, float_W, float_H)[1])        anchor = "TL"
			elseif (!rect_overlap(zoom_c[1], zoom_c[2], xc_2+fig_W3, yc_2, zoom_W, zoom_H, float_W, float_H)[1]) anchor = "TC"
			end
		elseif (col == 2)
			xc_2, yc_2 = fig_W3 + float_W2, fig_H - float_H2
			anchor = "TL"			# When the other positions fail resort to this
			if     (!rect_overlap(zoom_c[1], zoom_c[2], xc_2, yc_2, zoom_W, zoom_H, float_W, float_H)[1])        anchor = "TC"
			elseif (!rect_overlap(zoom_c[1], zoom_c[2], xc_2+fig_W3, yc_2, zoom_W, zoom_H, float_W, float_H)[1]) anchor = "TR"
			end
		else						# col = 3
			xc_2, yc_2 = 2fig_W3 + float_W2, fig_H - float_H2
			anchor = "TL"			# When the other positions fail resort to this
			if     (!rect_overlap(zoom_c[1], zoom_c[2], xc_2, yc_2, zoom_W, zoom_H, float_W, float_H)[1])        anchor = "TR"
			elseif (!rect_overlap(zoom_c[1], zoom_c[2], xc_2-fig_W3, yc_2, zoom_W, zoom_H, float_W, float_H)[1]) anchor = "TC"
			end
		end
	elseif (row == 2)
		if (col == 1)
			xc_2, yc_2 = float_W2, fig_H - float_H2
			anchor = "TR"			# When the other positions fail resort to this
			if     (!rect_overlap(zoom_c[1], zoom_c[2], xc_2, yc_2, zoom_W, zoom_H, float_W, float_H)[1])     anchor = "TL"
			elseif (!rect_overlap(zoom_c[1], zoom_c[2], xc_2, float_H2, zoom_W, zoom_H, float_W, float_H)[1]) anchor = "BL"
			end
		elseif (col == 2)
			xc_2, yc_2 = fig_W3 + float_W2, fig_H - float_H2
			anchor = "TR"			# When the other positions fail resort to this
			if     (!rect_overlap(zoom_c[1], zoom_c[2], xc_2, yc_2, zoom_W, zoom_H, float_W, float_H)[1])      anchor = "TC"
			elseif (!rect_overlap(zoom_c[1], zoom_c[2], xc_2, float_H2, zoom_W, zoom_H, float_W, float_H)[1])  anchor = "BC"
			end
		else						# col = 3
			xc_2, yc_2 = 2fig_W3 + float_W2, fig_H - float_H2
			anchor = "TL"			# When the other positions fail resort to this
			if     (!rect_overlap(zoom_c[1], zoom_c[2], xc_2, yc_2, zoom_W, zoom_H, float_W, float_H)[1])      anchor = "TR"
			elseif (!rect_overlap(zoom_c[1], zoom_c[2], xc_2, float_H2, zoom_W, zoom_H, float_W, float_H)[1])  anchor = "BR"
			end
		end
	else							# row = 3
		if (col == 1)
			xc_2, yc_2 = float_W2, float_H2
			anchor = "BR"			# When the other positions fail resort to this
			if     (!rect_overlap(zoom_c[1], zoom_c[2], xc_2, yc_2, zoom_W, zoom_H, float_W, float_H)[1])         anchor = "BL"
			elseif (!rect_overlap(zoom_c[1], zoom_c[2], xc_2+fig_W3, yc_2, zoom_W, zoom_H, float_W, float_H)[1])  anchor = "BC"
			end
		elseif (col == 2)
			xc_2, yc_2 = fig_W3 + float_W2, float_H2
			anchor = "BL"			# When the other positions fail resort to this
			if     (!rect_overlap(zoom_c[1], zoom_c[2], xc_2, yc_2, zoom_W, zoom_H, float_W, float_H)[1])         anchor = "BC"
			elseif (!rect_overlap(zoom_c[1], zoom_c[2], xc_2+fig_W3, yc_2, zoom_W, zoom_H, float_W, float_H)[1])  anchor = "BR"
			end
		else						# col = 3
			xc_2, yc_2 = 2fig_W3 + float_W2, float_H2
			anchor = "BL"			# When the other positions fail resort to this
			if     (!rect_overlap(zoom_c[1], zoom_c[2], xc_2, yc_2, zoom_W, zoom_H, float_W, float_H)[1])         anchor = "BR"
			elseif (!rect_overlap(zoom_c[1], zoom_c[2], xc_2-fig_W3, yc_2, zoom_W, zoom_H, float_W, float_H)[1])  anchor = "BC"
			end
		end
	end
	return anchor
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
function hack_modern_session(opt_R, opt_J, opt_B=" -Blrbt"; fullremove=false)
	# This function is now used in more places than just 'inset nested', but the defaults are still for it 
	opt_R == "" && throw(ArgumentError("The 'limits' option cannot be empty in hack_modern_session()"))
	opt_J == "" && throw(ArgumentError("The 'proj' option cannot be empty in hack_modern_session()"))
	gmt("begin")
	gmt("basemap " * opt_R * opt_J * opt_B)
	API = unsafe_load(convert(Ptr{GMTAPI_CTRL}, G_API[]))
	session_dir = unsafe_string(API.gwf_dir)
	fname = session_dir * filesep * "gmt_0.ps-"
	rm(fname)						# To remove PS headers and such
	!fullremove && touch(fname)		# Create a new empty one that is needed to later code be appended.
	return fname
end

# ---------------------------------------------------------------------------------------------------
function zoom2inset(d, center)
	# Compute the -R for the requested rectangle and set in 'd'.

	function helper(D, center)
		isincreasing = (sum(diff(D.data[1:5])) > 0) ? true : false
		if (eltype(center) <: AbstractString || eltype(center) == Date || eltype(center) == DateTime)
			t1, t2 = parse_zoom_window(center)
			xmima::Vector{Float64} = [max(t1, D.bbox[1]), min(t2, D.bbox[2])]
		else
			xmima = [max(center[1] - center[2], D.bbox[1]), min(center[1] + center[2], D.bbox[2])]
		end
		n1, n2 = 0, 0
		if (isincreasing)
			while(D[n1+=1,1] < xmima[1]) end			# When it finish data[n1] >= xmima[1]
			while(D[n2+=1,1] < xmima[2]) end			# When it finish data[n2] >= xmima[2]
		else
			while(D[n1+=1,1] > xmima[1]) end
			while(D[n2+=1,1] > xmima[2]) end
		end
		if !isincreasing  n1, n2 = n2, n1  end
		return n1, n2
	end

	data::Union{GDtype, GItype} = CTRL.pocket_call[4]

	if (isa(data, GItype))
		if (length(center) == 4)
			zoom_lims = [center...]
		else
			zoom_lims = [max(center[1] - center[3], data.range[1]), min(center[1] + center[3], data.range[2]), max(center[2] - center[3], data.range[3]), min(center[2] + center[3], data.range[4])]
		end
	else
		bak = CTRL.limits[7:end]						# Backup these because round_wesn will change them
		nDS = (isa(data, Vector)) ? length(data) : 1
		D = Vector{GMTdataset{Float64, 2}}(undef, nDS)
		zoom_lims::Vector{Float64} = [Inf, -Inf, Inf, -Inf]
		for k = 1:nDS
			if (nDS == 1)
				n1, n2 = helper(data, center)
				D[1] = mat2ds(data, (n1:n2, 1:2))
			else
				n1, n2 = helper(data[k], center)
				D[k] = mat2ds(data[k], (n1:n2, 1:2))
			end
			DYpct = (D[k].ds_bbox[4] - D[k].ds_bbox[3]) * 0.01	# 1% of the Y data limits
			D[k].ds_bbox[3] -= DYpct
			D[k].ds_bbox[4] += DYpct
			t_lims = round_wesn(D[k].ds_bbox)
			zoom_lims[1] = min(zoom_lims[1], t_lims[1]);	zoom_lims[2] = max(zoom_lims[2], t_lims[2])
			zoom_lims[3] = min(zoom_lims[3], t_lims[3]);	zoom_lims[4] = max(zoom_lims[4], t_lims[4])
		end
		CTRL.pocket_call[4] = (nDS == 1) ? D[1] : D
		CTRL.limits[7:end] = bak						# Reset the backed up values
	end
	d[:R] = @sprintf("%.15g/%.15g/%.15g/%.15g", zoom_lims...)
	d[:Rzoom_num] = zoom_lims
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function parse_zoom_window(window::Tuple{<:AbstractString, <:AbstractString})
	# Parse time strings in the form "YYYY-mm-dd", "YYYY-mm-ddThh", "YYYY-mm-ddThh:mm", "YYYY-mm-ddThh:mm:ss"
	# or "dd-Jan-YY" or "dd-Jan-YYYY"
	t1, t2 = ISOtime2unix(window[1]), ISOtime2unix(window[2])
	t2 <= t1 && error("The end time must be greater than the start time.")
	return t1, t2
end

# ---------------------------------------------------------------------------------------------------
function parse_zoom_window(window::Tuple{<:Union{Date, DateTime}, <:Union{Date, DateTime}})
	t1, t2 = datetime2unix(DateTime(window[1])), datetime2unix(DateTime(window[2]))
	t2 <= t1 && error("The end time must be greater than the start time.")
	return t1, t2
end

# ---------------------------------------------------------------------------------------------------
"""
    t = ISOtime2unix(ts::AbstractString) -> Float64

Take a string representing a time and return the equivalent Unix time. The `ts` string may take one of these forms:
- "YYYY-mm-dd", or "YYYY-mm-ddThh", or "YYYY-mm-ddThh:mm", or "YYYY-mm-ddThh:mm:ss", or "dd-Jan-YY" or "dd-Jan-YYYY"

### Examples
```julia
using Dates
t = ISOtime2unix("2019-01-01T12")
1.546344e9

t = ISOtime2unix("25-Apr-1974")
1.3608e8
```
"""
function ISOtime2unix(ts::AbstractString)
	dash_pos = findall('-', ts)
	if (length(ts) >= 10 && length(dash_pos) == 2 && (dash_pos[2]-dash_pos[1]) == 3)
		if     (length(ts) == 10)  ts *= "T00:00:00"
		elseif (ts[11] != 'T')     error("The time string $ts is not following the ISO YYYY-mm-ddThh:mm:ss format.")
		elseif (length(ts) == 13)  ts *= ":00:00"
		elseif (length(ts) == 16 && contains(ts, ":"))  ts *= ":00"
		elseif (length(ts) != 19 && length(findall(':', ts)) != 2)  error("The time string $ts is not following the ISO YYYY-mm-ddThh:mm:ss format.")
		end
	elseif ((length(ts) == 8 || length(ts) == 9 || length(ts) == 11) && length(dash_pos) == 2 && (dash_pos[2]-dash_pos[1]) == 4)
		spli = split(ts, '-')
		ano = parse(Int, spli[3])
		(ano < 100) && (ano >= 50 ? ano += 1900 : ano += 2000)
		ind = findfirst(lowercase(string(spli[2])) .== ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"])
		(ind === nothing) && error("The month string $(spli[2]) is not a valid month.")
		dd = (length(spli[1]) == 1) ? "0$(spli[1])" : string(spli[1])
		ts = @sprintf("%.4d-%.2d-%sT00:00:00", ano, ind, dd)
	else
		error("Unrecognized time string $ts format.")
	end
	return datetime2unix(DateTime(ts, dateformat"yyyy-mm-ddTHH:MM:SSs"))
end
