mutable struct legend_bag
	label::Vector{String}
	cmd::Vector{String}
	cmd2::Vector{String}
	opt_l::String
	optsDict::Dict{Symbol,Any}
	Vd::Int
end
legend_bag() = legend_bag(Vector{String}(), Vector{String}(), Vector{String}(), "", Dict{Symbol,Any}(), 0)

# --------------------------------------------------------------------------------------------------
function put_in_legend_bag(d::Dict{Symbol,Any}, cmd::Vector{String}, arg, O::Bool=false, opt_l::String="")
	# So far this fun is only called from plot() and stores line/symbol info in a const global var LEGEND_TYPE

	_valLegend = find_in_dict(d, [:legend :l], false)[1]	# false because we must keep it alive till digests_legend_bag()
	_valLabel  = find_in_dict(d, [:label])[1]				# These guys are always Any
	((_valLegend === nothing || _valLegend == "") && _valLabel === nothing) && return # Nothing to do here

	function assign_colnames(arg)
		# Return the columname(s) to be used as entries in a legend
		(isa(arg, GMTdataset)) && return [arg.colnames[2]]
		valLabel_loc = Vector{String}(undef, size(arg))
		for k = 1:numel(arg) valLabel_loc[k] = arg[k].colnames[2]  end
		return valLabel_loc
	end

	dd = Dict{Symbol, Any}()
	valLabel_vec::Vector{String} = String[]		# Use different containers to try to control the f Anys.
	valLabel::String = ""
	have_ribbon = false
	if (_valLabel === nothing)					# See if it has a legend=(label="blabla",) or legend="label"
		if (isa(_valLegend, NamedTuple))		# legend=(label=..., ...)
			dd = nt2dict(_valLegend)
			if (((the_pos = get(dd, :pos, nothing)) !== nothing) && (dd[:pos] == :auto))	# If pos=:auto, find the best position for the legend
				dd[:pos] = best_legend_pos(arg)	# Update this first
				d[:legend] = NamedTuple(dd)		# Must modify the main Dict because that is what is used in digests_legend_bag()
			end
			_valLabel = find_in_dict(dd, [:label], false)[1]
			if ((isa(_valLabel, StrSymb)))
				_valLab = string(_valLabel)::String
				(lowercase(_valLab) == "colnames") ? (valLabel_vec = assign_colnames(arg)) : valLabel = _valLab
			elseif (_valLabel !== nothing)
				valLabel_vec = [string.(_valLabel)...]		# We may have shits here
			end
			if ((ribs = hlp_desnany_str(dd, [:ribbon, :band], false)) !== "")
				(valLabel != "") && (valLabel_vec = [valLabel, ribs]; valLabel="")	# *promote* valLabel
				have_ribbon = true
			end

		elseif (isa(_valLegend, StrSymb))
			_valLab = string(_valLegend)::String
			(_valLab == "") && return			# If Label == "" we forget this one
			(lowercase(_valLab) == "colnames") ? (valLabel_vec = assign_colnames(arg)) : valLabel = _valLab

		elseif (isa(_valLegend, Tuple))
			valLabel_vec = [string.(_valLegend)...]
		end
	else
		(isa(_valLabel, String) || isa(_valLabel, Symbol)) ? (valLabel = string(_valLabel)) : (valLabel_vec = [string.(_valLabel)...])				# Risky too
	end
	have_valLabel::Bool = (valLabel != "" || !isempty(valLabel_vec))

	cmd_ = cmd								# Starts to be just a shallow copy
	cmd_ = copy(cmd)						# TODO: pick only the -G, -S, -W opts instead of brute copying.
	_, penC, penS = isa(arg, GMTdataset) ? break_pen(scan_opt(arg.header, "-W")) : break_pen(scan_opt(arg[1].header, "-W"))
	penT, penC_, penS_ = break_pen(scan_opt(cmd_[end], "-W"))
	(penC == "") && (penC = penC_)
	(penS == "") && (penS = penS_)
	cmd_[end] = "-W" * penT * ',' * penC * ',' * penS * " " * cmd_[end]	# Trick to make the parser find this pen

	# For groups, this holds the indices of the group's start
	gindex::Vector{Int} = ((val = find_in_dict(d, [:gindex])[1]) === nothing) ? Int[] : val

	nDs::Int = isa(arg, GMTdataset) ? 1 : length(arg)
	!isempty(gindex) && (nDs = length(gindex))
	pens = Vector{String}(undef, max(1,nDs-1));
	k_vec = isempty(gindex) ? collect(2:nDs) : gindex[2:end]
	isempty(k_vec) && (k_vec = [1])		# Don't let it be empty
	for k = 1:max(1,nDs-1)
		t::String = isa(arg, GMTdataset) ? scan_opt(arg.header, "-W") : scan_opt(arg[k_vec[k]].header, "-W")
		if     (t == "")          pens[k] = " -W" * penT			# Was " -W0."
		elseif (t[1] == ',')      pens[k] = " -W" * penT * t		# Can't have, e.g., ",,230/159/0" => Crash
		elseif (occursin(",",t))  pens[k] = " -W" * t  
		else                      pens[k] = " -W" * penT * ',' * t	# Not sure what this case covers now
		end
	end

	if (isa(arg, GMTdataset) && nDs > 1)	# Piggy back the pens with the eventuals -S, -G options
		extra_opt  = ((t = scan_opt(cmd_[1], "-S", true)) != "") ? t : ""
		extra_opt *= ((t = scan_opt(cmd_[1], "-G", true)) != "") ? t : ""
		for k = 1:numel(pens)  pens[k] *= extra_opt  end
		if ((ind = findfirst(arg.colnames .== "Zcolor")) !== nothing)
			rgb = [0.0, 0.0, 0.0, 0.0]
			P::Ptr{GMT_PALETTE} = palette_init(G_API[], CURRENT_CPT[])	# A pointer to a GMT CPT
			gmt_get_rgb_from_z(G_API[], P, arg[gindex[1],ind], rgb)
			cmd_[1] *= " -G" * arg2str(rgb[1:3].*255)
			(rgb[4] > 0.0) && (cmd_[1] *= "@$(rgb[4]*100)")				# Add transparency if any
			for k = 1:numel(pens)
				gmt_get_rgb_from_z(G_API[], P, arg[gindex[k+1],ind]+10eps(), rgb)
				pens[k] *= @sprintf(" -G%.0f/%.0f/%.0f", rgb[1]*255, rgb[2]*255, rgb[3]*255)
				(rgb[4] > 0.0) && (pens[k] *= "@$(rgb[4]*100)")
			end
		end
	end
	append!(cmd_, pens)			# Append the 'pens' var to the input arg CMD

	if (have_ribbon)			# Add a square marker to represent the ribbon
		t  = ((t = scan_opt(cmd_[1], "-G", true)) != "") ? t : ""
		nDs += 1;	cmd_[end] *= " -Ss0.4" * t	# Cheat cmd_[end] to add the square marker
	end

	lab = Vector{String}(undef, nDs)
	if (have_valLabel)
		if (valLabel != "")		# One single label, take it as a label prefix
			if (nDs == 1)  lab[1] = string(valLabel)			# But not if a single guy.
			else           for k = 1:nDs  lab[k] = string(valLabel,k)  end
			end
		else
			for k = 1:min(nDs, length(valLabel_vec))  lab[k] = string(valLabel_vec[k])  end
			if (length(valLabel_vec) < nDs)	# Probably shit, but don't error because of it
				for k = length(valLabel_vec)+1:nDs  lab[k] = string(valLabel_vec[end],k)  end
			end
		end
	else
		for k = 1:nDs  lab[k] = string('y',k)  end
	end

	(!O) && (LEGEND_TYPE[] = legend_bag())		# Make sure that we always start with an empty one

	if (size(LEGEND_TYPE[].label, 1) == 0)		# First time
		LEGEND_TYPE[] = legend_bag(lab, [cmd_[1]], length(cmd_) == 1 ? [""] : [cmd_[2]], opt_l, dd, 0)
		# Forgot about the logic of the above and it errors when first arg is a GMTdataset vec,
		# so do this till a decent fix gets invented.
		(length(lab) > 1) && (LEGEND_TYPE[] = legend_bag(lab, cmd_, cmd_, opt_l, dd, 0))
	else
		append!(LEGEND_TYPE[].cmd, [cmd_[1]])
		append!(LEGEND_TYPE[].cmd2, (length(cmd_) > 1) ? [cmd_[2]] : [""])
		append!(LEGEND_TYPE[].label, lab)
		# If font, pos, etc are only given at end and no show() is used, they would get lost and not visible by showfig()
		isempty(LEGEND_TYPE[].optsDict) && (LEGEND_TYPE[].optsDict = dd)
	end

	return nothing
end

# --------------------------------------------------------------------------------------------------
function digests_legend_bag(d::Dict{Symbol, Any}, del::Bool=true)
	# Plot a legend if the leg or legend keywords were used. Legend info is stored in LEGEND_TYPE global variable
	(size(LEGEND_TYPE[].label, 1) == 0) && return nothing

	dd::Dict{Symbol, Any} = ((val = find_in_dict(d, [:leg :legend :l], false)[1]) !== nothing && isa(val, NamedTuple)) ? nt2dict(val) : Dict{Symbol, Any}()

	kk, fs = 0, 8				# Font size in points
	symbW = 0.65				# Symbol width. Default to 0.75 cm (good for lines but bad for symbols)
	nl, count_no = length(LEGEND_TYPE[].label), 0
	leg::Vector{String} = Vector{String}(undef, 3nl)
	all(contains.(LEGEND_TYPE[].cmd, "-S")) && (symbW = 0.25)	# When all entries are symbols shrink the 'symbW'

	#lab_width = maximum(length.(LEGEND_TYPE[].label[:])) * fs / 72 * 2.54 * 0.50 + 0.25	# Guess label width in cm
	# Problem is that we may have a lot more chars in label than those effectively printed (PS octal chars etc)
	n_max_chars = 0
	for k = 1:numel(LEGEND_TYPE[].label)
		s = split(LEGEND_TYPE[].label[k], "`")		# Means that after the '`' comes the this string char counting
		n_chars = (length(s) == 2) ? (LEGEND_TYPE[].label[k] = s[1]; parse(Int,s[2])) : length(LEGEND_TYPE[].label[k])
		n_max_chars = max(n_chars, n_max_chars)
	end
	lab_width = n_max_chars * fs / 72 * 2.54 * 0.50 + 0.25	# Guess label width in cm

	for k = 1:nl						# Loop over number of entries
		(LEGEND_TYPE[].label[k] == " ") && (count_no += 1;	continue)	# Sometimes we may want to open a leg entry but not plot it
		if ((symb = scan_opt(LEGEND_TYPE[].cmd[k], "-S")) == "")  symb = "-"
		else                                                      symbW_ = symb[2:end];
		end
		((fill = scan_opt(LEGEND_TYPE[].cmd[k], "-G")) == "") && (fill = "-")
		pen  = scan_opt(LEGEND_TYPE[].cmd[k], "-W");
		(pen == "" && symb[1] != '-' && fill != "-") ? pen = "-" : (pen == "" ? pen = "0.25p" : pen = pen)
		if (symb[1] == '-')
			leg[kk += 1] = @sprintf("S %.3fc %s %.2fc %s %s %.2fc %s",
			                symbW/2, symb[1], symbW, fill, pen, symbW+0.14, LEGEND_TYPE[].label[k])
			if ((symb2 = scan_opt(LEGEND_TYPE[].cmd2[k], "-S")) != "")		# A line + a symbol
				leg[kk += 1] = "G -1l"			# Go back one line before plotting the overlaying symbol
				xx = split(pen, ',')
				if (length(xx) == 2)  fill = xx[2]
				else                  fill = ((c = scan_opt(LEGEND_TYPE[].cmd2[k], "-G")) != "") ? c : "black"
				end
				penS = scan_opt(LEGEND_TYPE[].cmd2[k], "-W");
				leg[kk += 1] = @sprintf("S - %s %s %s %s - %s", symb2[1], symb2[2:end], fill, penS, "")
			end
		elseif (symb[1] == '~' || symb[1] == 'q' || symb[1] == 'f')
			if (startswith(symb, "~d"))
				ind = findfirst(':', symb)
				(ind === nothing) && error("Error: missing colon (:) in decorated string opt.")
				symb = string(symb[1],"n1", symb[ind[1]:end])
			end
			leg[kk += 1] = @sprintf("S - %s %s %s %s - %s", symb, symbW, fill, pen, LEGEND_TYPE[].label[k])
		else
			leg[kk += 1] = @sprintf("S - %s %s %s %s - %s", symb[1], symbW_, fill, pen, LEGEND_TYPE[].label[k])	# Who is this?
		end
	end
	(count_no > 0) && (resize!(leg, nl-count_no))

	fnt = get_legend_font(dd, fs)	# Parse the eventual 'font' or 'fontsize' options

	# Because we accept extended settings either from first or last legend() commands we must seek which
	# one may have the desired keyword. First command is stored in 'LEGEND_TYPE[].optsDict' and last in 'dd'
	_d::Dict{Symbol,Any} = (haskey(dd, :pos) || haskey(dd, :position)) ? dd :
	     (haskey(LEGEND_TYPE[].optsDict, :pos) || haskey(LEGEND_TYPE[].optsDict, :position)) ?
		 LEGEND_TYPE[].optsDict : Dict{Symbol,Any}()

	_opt_D = hlp_desnany_str(d, [:pos, :position], false)
	if ((opt_D::String = parse_type_anchor(_d, "", [:_ :pos :position],
	                                       (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), width=("+w", arg2str), justify="+j", spacing="+l", offset=("+o", arg2str)), 'j')) == "")
		opt_D = @sprintf("jTR+w%.3f+o0.1", symbW*1.2 + lab_width)
	else
		offset = "0.1"		# The default offset. Will be changed in the outside case if we have tick marks
		# The problem is that the -DJ behaves a bit crazilly on the corners, so we're forced to do some gymns
		# to not plot the legend "on the diagonal" and that implies the use of +j that is a very confusing option
		if ((startswith(opt_D,"JTL") || startswith(opt_D,"JTR") || startswith(opt_D,"JBL") || startswith(opt_D,"JBR")) && !contains(opt_D, "+j"))
			opt_D *= "+j" * opt_D[2] * (opt_D[3] == 'L' ? 'R' : 'L')
			if (!occursin("+o", opt_D))
				# Try to find a -Baxes token and see if 'axes' contains an annotated axis on the same side as the legend
				s = split(LEGEND_TYPE[].cmd[1], " -B")
				for t in s
					t[1] == '-' && continue				# This one can't be of any interest
					ss = split(split(t)[1],'+')[1]		# If we have an annotated or with ticks guestimate an offset
					(opt_D[end] == 'L' && contains(ss, 'e') || opt_D[end] == 'R' && contains(ss, 'W')) && (offset = "0.2/0")
					if (opt_D[end] == 'L' && contains(ss, 'E') || opt_D[end] == 'R' && contains(ss, 'W'))
						o = round((abs(floor(log10(CTRL.limits[10]))) + 1) * 12 * 2.54 / 72, digits=1)	# crude estimate
						(opt_D *= "+o$o" * "/0")
					end
				end
			end
		else
			(_opt_D != "") && (opt_D = _opt_D)
			t = justify(opt_D, true)
			if (length(t) == 2)
				opt_D = "j" * t
			end
		end
		(!occursin("+w", opt_D)) && (opt_D = @sprintf("%s+w%.3f", opt_D, symbW*1.2 + lab_width))
		(!occursin("+o", opt_D)) && (opt_D *= "+o" * offset)
	end

	_d = (haskey(dd, :box) && dd[:box] !== nothing) ? dd : haskey(LEGEND_TYPE[].optsDict, :box) ? LEGEND_TYPE[].optsDict : Dict{Symbol, Any}()
	opt_F::String = add_opt(_d, "", "", [:box], (clearance="+c", fill=("+g", add_opt_fill), inner="+i", pen=("+p", add_opt_pen), rounded="+r", shade="+s"); del=false)		# FORCES RECOMPILE plot
	if (opt_F == "")
		opt_F = "+p0.5+gwhite"
	else
		if (opt_F == "none")
			opt_F = "+gwhite"
		else
			(!occursin("+p", opt_F)) && (opt_F *= "+p0.5")
			(!occursin("+g", opt_F)) && (opt_F *= "+gwhite")
		end
	end
	
	if (LEGEND_TYPE[].Vd > 0)  d[:Vd] = LEGEND_TYPE[].Vd;  dbg_print_cmd(d, leg[1:kk])  end	# Vd=2 wont work
	(LEGEND_TYPE[].Vd > 0) && println("F=",opt_F, " D=",opt_D, " font=",fnt)
	gmt_restart()		# Some things with the themes may screw
	
	#legend!(text_record(leg[1:kk]), F=opt_F, D=opt_D, par=(:FONT_ANNOT_PRIMARY, fnt), Vd=1)
	# This reproduces the actualy visited lines of the above legend!() command but let it work in GMT_base (if ...)
	proggy = (IamModern[]) ? "legend"  : "pslegend"
	opt_R = " -R"
	(!IamModern[] && !CTRL.IamInPaperMode[1] && opt_R == " -R" && CTRL.pocket_R[1] != "") && (opt_R = CTRL.pocket_R[1])
	prep_and_call_finish_PS_module(Dict{Symbol, Any}(), [proggy * " -J $opt_R -F$(opt_F) -D$(opt_D) --FONT_ANNOT_PRIMARY=$fnt"],
	                               "", true, true, true, text_record(leg[1:kk]))

	LEGEND_TYPE[] = legend_bag()			# Job done, now empty the bag

	return nothing
end

# ---------------------------------------------------------------------------------------------------
function get_legend_font(d::Dict{Symbol,Any}, fs=0; modern::Bool=false)::String
	# This fun gets the font size to be used in legends, but it serves two masters. On one side we want to keep the
	# legend defaults in modern mode (inside gmtbegin()) using the gmt.conf setings. For that pass FS=0 and MODERN=TRUE
	# On the other hand, from the GMT.jl classic-but-modern, the default (on calling this) is FS=8.
	# This allows for the user to set options 'fontsize' or 'font' to override the defaults for both modes.
	(haskey(d, :fontsize)) && (fs = d[:fontsize])
	
	fnt::String = (haskey(d, :font)) ? font(d[:font]) : string(fs)
	delete!(d, [:font :fontsize])
	(modern && fnt == "0") && return ""	# gmtbegin calls this fun with fs=0 and we don't want to change the defaults in gmt.conf

	if (fnt != string(fs))
		s = split(fnt, ',')
		(length(s) == 1) &&  (fnt = string(fs, ',', s[1]))				# s[1] must be font name
		(length(s) == 2) &&  (fnt = string(fs, ',', s[1], ',', s[2]))	# s[1] font name, s[2] font color
	end
	return fnt
end

# --------------------------------------------------------------------------------------------------
"""
    best_legend_pos(xy; legendsize=(0.2, 0.15), margin=0.03) -> String

Find the best position for a legend in an x-y plot to minimize overlap with plotted curves.
Uses the same algorithm as matplotlib's `loc='best'`: tests 9 candidate positions (corners,
edge midpoints, center) and picks the one with the lowest "badness" score. The score counts
data vertices inside the legend box plus curve segments that cross its edges.

### Arguments
- `xy`: data curves. A Nx2+ matrix, a GMTdataset, or a Vector of these.
- `legendsize`: `(width, height)` as fractions of the plot region (default 20% x 15%).
- `margin`: margin from plot edges as fraction of plot dimensions (default 0.03).

### Returns
A GMT justification code string: `"TR"`, `"TL"`, `"BR"`, `"BL"`, `"MR"`, `"ML"`, `"TC"`, `"BC"`, or `"MC"`.
"""
function best_legend_pos(xy::GDtype; legendsize=(0.2, 0.15), margin=0.03)::String
	# This code was created by Claude and, according to it, inspired by the matplotlib code for loc='best'

	xmin, xmax, ymin, ymax = getregion(xy)
	dx, dy = xmax - xmin, ymax - ymin
	lw, lh = legendsize[1] * dx, legendsize[2] * dy
	mx, my = margin * dx, margin * dy
	xc, yc = (xmin + xmax) / 2, (ymin + ymax) / 2

	# Candidate positions: (code, legend_lower_left_x, legend_lower_left_y)
	candidates = (
		("TR", xmax-mx-lw, ymax-my-lh), ("TL", xmin+mx, ymax-my-lh),
		("BR", xmax-mx-lw, ymin+my),    ("BL", xmin+mx, ymin+my),
		("MR", xmax-mx-lw, yc-lh/2),    ("ML", xmin+mx, yc-lh/2),
		("TC", xc-lw/2,    ymax-my-lh), ("BC", xc-lw/2, ymin+my),
		("MC", xc-lw/2,    yc-lh/2),
	)

	best_code, best_bad = "TR", typemax(Int)
	for (code, lx, ly) in candidates
		bad = _blp_badness(xy, lx, ly, lx + lw, ly + lh)
		if (bad < best_bad)
			best_bad = bad;  best_code = code
		end
		bad == 0 && break
	end
	return best_code
end

function _blp_badness(curves::GMTdataset, rxmin::Float64, rymin::Float64, rxmax::Float64, rymax::Float64)
	helper_badness(curves, rxmin, rymin, rxmax, rymax, 0)
end

function _blp_badness(curves::Vector{<:GMTdataset}, rxmin::Float64, rymin::Float64, rxmax::Float64, rymax::Float64)
	badness = 0
	for c in curves
		badness += helper_badness(c, rxmin, rymin, rxmax, rymax, badness)
	end
	return badness
end

function helper_badness(c, rxmin, rymin, rxmax, rymax, badness)
	n = size(c, 1)
	@inbounds for i in 1:n
		x, y = c[i,1], c[i,2]
		(isnan(x) || isnan(y)) && continue
		(rxmin <= x <= rxmax && rymin <= y <= rymax) && (badness += 1)		# Vertex inside?
		if (i < n)		# Segment crosses edge?
			x2, y2 = c[i+1,1], c[i+1,2]
			(isnan(x2) || isnan(y2)) && continue
			_blp_seg_crosses_rect(x, y, x2, y2, rxmin, rymin, rxmax, rymax) && (badness += 1)
		end
	end
	return badness
end

# Check if segment (x1,y1)-(x2,y2) crosses any edge of the rectangle
function _blp_seg_crosses_rect(x1::Float64, y1::Float64, x2::Float64, y2::Float64,
                               rxmin::Float64, rymin::Float64, rxmax::Float64, rymax::Float64)
	_blp_seg2cross(x1,y1,x2,y2, rxmin,rymin, rxmax,rymin) && return true   # bottom
	_blp_seg2cross(x1,y1,x2,y2, rxmax,rymin, rxmax,rymax) && return true   # right
	_blp_seg2cross(x1,y1,x2,y2, rxmin,rymax, rxmax,rymax) && return true   # top
	_blp_seg2cross(x1,y1,x2,y2, rxmin,rymin, rxmin,rymax) && return true   # left
	return false
end

# Do two segments (a1→a2) and (b1→b2) properly cross each other?
function _blp_seg2cross(ax1::Float64, ay1::Float64, ax2::Float64, ay2::Float64,
                        bx1::Float64, by1::Float64, bx2::Float64, by2::Float64)
	d1 = (ax2 - ax1) * (by1 - ay1) - (ay2 - ay1) * (bx1 - ax1)
	d2 = (ax2 - ax1) * (by2 - ay1) - (ay2 - ay1) * (bx2 - ax1)
	d3 = (bx2 - bx1) * (ay1 - by1) - (by2 - by1) * (ax1 - bx1)
	d4 = (bx2 - bx1) * (ay2 - by1) - (by2 - by1) * (ax2 - bx1)
	return ((d1 > 0) != (d2 > 0)) && ((d3 > 0) != (d4 > 0))
end

# --------------------------------------------------------------------------------------------------
"""
    best_label_pos(curves, labels; fontsize::Int=8) -> Vector{NamedTuple}

Find optimal non-overlapping positions to annotate curves in an x-y plot. For each curve, tests
candidate positions along 10%–90% of the arc length, scores them by overlap with other curves and
already-placed labels, and greedily assigns the best position.

### Arguments
- `curves`: data curves. A Nx2+ matrix, a GMTdataset, or a Vector of these.
- `labels`: Vector of label strings, one per curve.
- `fontsize`: font size in points (default 8). Used to estimate text bounding box.
- `prefer`: preferred label zone along the curve. One of `:begin`, `:middle` (default), or `:end`.
- `xvals`: scalar or vector of x-coordinates where labels should be placed (by intersecting each curve).
  A scalar uses the same x for all curves; a vector specifies one x per curve.
- `yvals`: same as `xvals` but for y-coordinates. If multiple crossings exist, the one closest to the
  curve midpoint is chosen.

### Returns
A `Matrix{Float64}` of size `(ncurves, 4)` where each row `[x1, y1, x2, y2]` defines a short
line segment perpendicular to the curve at the chosen label position, in data coordinates.
These can be used directly with GMT's quoted line option `-Sql<x1/y1/x2/y2>`.
"""
function best_label_pos(curves::GDtype, labels::Vector{<:AbstractString}; fontsize::Int=8, prefer::Symbol=:middle,
                        xvals::Union{Real, Vector{<:Real}, Nothing}=nothing, yvals::Union{Real, Vector{<:Real}, Nothing}=nothing)
	D = isa(curves, GMTdataset) ? [curves] : (isa(curves, Vector{<:GMTdataset}) ? curves : [curves])
	nc = length(D)
	_labels = String[string(l) for l in labels]
	nc != length(_labels) && error("Number of curves ($nc) must match number of labels ($(length(_labels)))")

	# If xvals or yvals provided, place labels at those specific coordinates
	if xvals !== nothing || yvals !== nothing
		_xv::Vector{Float64} = xvals === nothing ? Float64[] : isa(xvals, Real) ? fill(Float64(xvals), nc) : Float64.(xvals)
		_yv::Vector{Float64} = yvals === nothing ? Float64[] : isa(yvals, Real) ? fill(Float64(yvals), nc) : Float64.(yvals)
		return _label_pos_at_vals(D, nc, _xv, _yv)
	end

	_best_label_pos(D, _labels, nc, Int(fontsize), prefer)
end

function _best_label_pos(D::Vector{<:GMTdataset}, labels::Vector{String}, nc::Int, fontsize::Int, prefer::Symbol)
	# Use the actual plot region (not data bbox) so cm↔data conversion matches the axes
	if CTRL.limits[7] != 0
		xmin, xmax, ymin, ymax = CTRL.limits[7:10]
	else
		xmin, xmax, ymin, ymax = getregion(D)
	end
	pw, ph = _get_plotsize()
	sx, sy = pw / (xmax - xmin), ph / (ymax - ymin)

	# Convert to cm space — only the visible portion of each curve (inside the plot region)
	crv = Vector{Matrix{Float64}}(undef, nc)
	for k in 1:nc
		pts = D[k].data
		mask = vec((pts[:,1] .>= xmin) .& (pts[:,1] .<= xmax) .& (pts[:,2] .>= ymin) .& (pts[:,2] .<= ymax))
		vis = sum(mask) >= 2 ? pts[mask, :] : pts
		crv[k] = hcat((vis[:,1] .- xmin) .* sx, (vis[:,2] .- ymin) .* sy)
	end

	# Text half-dimensions in cm
	fs = fontsize * 2.54 / 72
	char_w = 0.55 * fs
	char_h = fs
	hws = [length(l) * char_w / 2 for l in labels]    # half-width per label
	hh  = char_h * 0.9                                 # half-height (shared)

	# Preferred zone for targets (where labels WANT to be)
	prefer in (:begin, :middle, :end) || error("prefer must be :begin, :middle, or :end")
	frac_lo, frac_hi = prefer == :begin ? (0.05, 0.30) :
	                   prefer == :end   ? (0.60, 0.95) : (0.20, 0.80)
	center = prefer == :begin ? 0.17 : prefer == :end ? 0.83 : 0.50
	if nc == 1
		frac_targets = [center]
	else
		half_spread = min(0.20, 0.04 * nc)
		frac_targets = [center + half_spread * (2.0 * (i - 1) / (nc - 1) - 1.0) for i in 1:nc]
	end

	# Candidate range is wider than target zone — labels prefer the target but CAN escape if all
	# candidates in the preferred zone have crossings (e.g. steep curves bunched at the center)
	cand_lo = max(0.05, frac_lo - 0.15)
	cand_hi = min(0.95, frac_hi + 0.15)
	ncand = 29
	cands = [_bla_gen_candidates(crv[i], ncand, cand_lo, cand_hi) for i in 1:nc]

	# Greedy placement: maximize minimum clearance to other curves
	placed_cx = Float64[];  placed_cy = Float64[];  placed_a = Float64[]
	placed_hw = Float64[];  placed_hh = Float64[]
	result = Matrix{Float64}(undef, nc, 4)	# each row: x1, y1, x2, y2

	half_cross = 0.3	# half-length of crossing segment in cm

	for i in 1:nc
		hw_i = hws[i]

		# Phase 1: compute a quality score for every candidate (higher = fewer problems)
		nj = length(cands[i])
		qualities = Vector{Float64}(undef, nj)
		curvs     = Vector{Float64}(undef, nj)
		fracs     = Vector{Float64}(undef, nj)

		# For each candidate: count crossings with other curves through the label bbox, measure clearance
		ncross_j  = Vector{Int}(undef, nj)
		clears_j  = Vector{Float64}(undef, nj)
		overlaps_j = falses(nj)

		for j in 1:nj
			cx, cy, ang, curv = cands[i][j]
			fracs[j] = cand_lo + (cand_hi - cand_lo) * (j - 1) / max(nj - 1, 1)
			curvs[j] = curv

			# Count how many OTHER curves cross through the label bounding box
			ncross = 0
			if nc > 1
				corners = _bla_corners(cx, cy, ang, hw_i, hh)
				for k in 1:nc
					k == i && continue
					for ei in 1:4
						eni = mod1(ei + 1, 4)
						ncross += _bla_crossing_count(corners[ei][1], corners[ei][2], corners[eni][1], corners[eni][2], crv[k])
					end
				end
			end
			ncross_j[j] = ncross

			# Min distance to nearest other curve
			clearance = nc > 1 ? 1e10 : 0.0
			for k in 1:nc
				k == i && continue
				c = crv[k];  n = size(c, 1)
				@inbounds for s in 1:n-1
					d = _bla_pt_seg_dist(cx, cy, c[s,1], c[s,2], c[s+1,1], c[s+1,2])
					clearance = min(clearance, d)
				end
			end
			clears_j[j] = clearance

			# Reject candidates too close to plot edges (label or crossing segment would be clipped)
			margin = hh * 2.0
			if cx < margin || cy < margin || cx > pw - margin || cy > ph - margin
				overlaps_j[j] = true		# reuse flag to mark as unusable
				continue
			end

			# Check overlap with already-placed labels (with padding so labels don't get too close)
			pad = hh * 0.5		# extra margin around each label box
			for p in eachindex(placed_cx)
				if _bla_rboxes_overlap(cx, cy, ang, hw_i + pad, hh + pad,
				                       placed_cx[p], placed_cy[p], placed_a[p], placed_hw[p] + pad, placed_hh[p] + pad)
					overlaps_j[j] = true;  break
				end
			end
		end

		# Pick best: filter by crossings → label overlap → clearance → curvature; pick closest to frac_target
		min_ncross = minimum(ncross_j)
		clear_thresh = hh * 3.0		# min clearance from other curves (not squeezed)
		sorted_curvs = sort(curvs)
		curv_thresh  = sorted_curvs[round(Int, nj * 0.75)]	# 75th percentile — only reject extreme curvature

		# Minimum clearance: curve must NOT touch label box — use diagonal of half-dimensions
		min_clear = hypot(hw_i, hh) * 1.2

		# Try with progressively relaxed clearance, but NEVER below min_clear
		best_j = 1
		best_dist = Inf
		for ct in (clear_thresh, (clear_thresh + min_clear) / 2, min_clear)
			for j in 1:nj
				ncross_j[j] > min_ncross && continue
				overlaps_j[j] && continue
				clears_j[j] < ct && continue
				curvs[j] > curv_thresh && continue
				frac_dist = abs(fracs[j] - frac_targets[i])
				if frac_dist < best_dist
					best_dist = frac_dist;  best_j = j
				end
			end
			best_dist < Inf && break
		end

		if best_dist == Inf		# relax curvature filter, keep min_clear
			for ct in (clear_thresh, min_clear)
				for j in 1:nj
					ncross_j[j] > min_ncross && continue
					overlaps_j[j] && continue
					clears_j[j] < ct && continue
					frac_dist = abs(fracs[j] - frac_targets[i])
					if frac_dist < best_dist
						best_dist = frac_dist;  best_j = j
					end
				end
				best_dist < Inf && break
			end
		end

		if best_dist == Inf		# all labels overlap — farthest from placed labels, then closest to target
			max_sep = -Inf
			for j in 1:nj
				ncross_j[j] > min_ncross && continue
				cx_j, cy_j = cands[i][j][1], cands[i][j][2]
				min_d = isempty(placed_cx) ? Inf : minimum(hypot(cx_j - placed_cx[p], cy_j - placed_cy[p]) for p in eachindex(placed_cx))
				max_sep = max(max_sep, min_d)
			end
			thresh_sep = max_sep * 0.8
			best_dist = Inf
			for j in 1:nj
				ncross_j[j] > min_ncross && continue
				cx_j, cy_j = cands[i][j][1], cands[i][j][2]
				min_d = isempty(placed_cx) ? Inf : minimum(hypot(cx_j - placed_cx[p], cy_j - placed_cy[p]) for p in eachindex(placed_cx))
				min_d < thresh_sep && continue
				frac_dist = abs(fracs[j] - frac_targets[i])
				if frac_dist < best_dist
					best_dist = frac_dist;  best_j = j
				end
			end
		end

		if best_dist == Inf		# absolute last resort: closest to target, NO filters at all
			for j in 1:nj
				frac_dist = abs(fracs[j] - frac_targets[i])
				if frac_dist < best_dist
					best_dist = frac_dist;  best_j = j
				end
			end
		end

		cx, cy, ang = cands[i][best_j][1], cands[i][best_j][2], cands[i][best_j][3]
		push!(placed_cx, cx);  push!(placed_cy, cy);  push!(placed_a, ang)
		push!(placed_hw, hw_i);  push!(placed_hh, hh)

		# Convert to data coords; perpendicular in data-space from the cm-space tangent angle
		cx_dat = cx / sx + xmin
		cy_dat = cy / sy + ymin
		nx_d, ny_d = -sin(ang) / sy, cos(ang) / sx		# perpendicular to tangent in data-space
		nd = hypot(nx_d, ny_d)
		nx_d /= nd;  ny_d /= nd
		half_d = min(xmax - xmin, ymax - ymin) * 0.015
		s_neg, s_pos = half_d, half_d
		if nx_d > 0       s_neg = min(s_neg, (cx_dat - xmin) / nx_d);  s_pos = min(s_pos, (xmax - cx_dat) / nx_d)
		elseif nx_d < 0   s_neg = min(s_neg, (xmax - cx_dat) / -nx_d); s_pos = min(s_pos, (cx_dat - xmin) / -nx_d)
		end
		if ny_d > 0       s_neg = min(s_neg, (cy_dat - ymin) / ny_d);  s_pos = min(s_pos, (ymax - cy_dat) / ny_d)
		elseif ny_d < 0   s_neg = min(s_neg, (ymax - cy_dat) / -ny_d); s_pos = min(s_pos, (cy_dat - ymin) / -ny_d)
		end
		s_neg = max(s_neg, 1e-6);  s_pos = max(s_pos, 1e-6)
		result[i,1] = cx_dat - nx_d * s_neg
		result[i,2] = cy_dat - ny_d * s_neg
		result[i,3] = cx_dat + nx_d * s_pos
		result[i,4] = cy_dat + ny_d * s_pos
	end
	return result
end

# Place labels at user-specified x or y coordinates by interpolating each curve.
function _label_pos_at_vals(D::Vector{<:GMTdataset}, nc::Int, xvals::Vector{Float64}, yvals::Vector{Float64})
	half_cross = 0.3
	result = Matrix{Float64}(undef, nc, 4)
	use_x = !isempty(xvals)
	vv = use_x ? xvals : yvals
	length(vv) != nc && error("Length of $(use_x ? "xvals" : "yvals") ($(length(vv))) must match number of curves ($nc)")
	col_interp = use_x ? 1 : 2		# column to search in
	col_result = use_x ? 2 : 1		# column to interpolate

	for i in 1:nc
		data = D[i].data
		n = size(data, 1)
		target = vv[i]

		# Find all segments that bracket the target value
		best_px, best_py, best_ang = 0.0, 0.0, 0.0
		best_dist = Inf				# distance to curve midpoint (by index)
		mid_idx = n / 2.0
		found = false

		@inbounds for s in 1:n-1
			v1, v2 = data[s, col_interp], data[s+1, col_interp]
			(min(v1, v2) > target || max(v1, v2) < target) && continue
			dv = v2 - v1
			t = dv != 0.0 ? (target - v1) / dv : 0.5
			t = clamp(t, 0.0, 1.0)
			px = data[s,1] + t * (data[s+1,1] - data[s,1])
			py = data[s,2] + t * (data[s+1,2] - data[s,2])
			ang = atan(data[s+1,2] - data[s,2], data[s+1,1] - data[s,1])
			dist = abs(s + t - mid_idx)
			if dist < best_dist
				best_px, best_py, best_ang = px, py, ang
				best_dist = dist
				found = true
			end
		end

		!found && error("Value $(target) not found on curve $i")

		# Build short perpendicular segment in data coordinates, guaranteed to stay inside the plot region.
		if CTRL.limits[7] != 0
			xmin, xmax, ymin, ymax = CTRL.limits[7:10]
		else
			xmin, xmax, ymin, ymax = getregion(D)
		end
		scale = max(xmax - xmin, ymax - ymin) * 0.005
		scale = max(scale, 1e-6)
		nx, ny = -sin(best_ang), cos(best_ang)

		# Asymmetric limits: each endpoint limited independently so the segment stays inside
		# but extends as far as possible in the direction that has room.
		s_neg, s_pos = scale, scale		# scale for (center - n*s) and (center + n*s)
		if nx > 0       s_neg = min(s_neg, (best_px - xmin) / nx);  s_pos = min(s_pos, (xmax - best_px) / nx)
		elseif nx < 0   s_neg = min(s_neg, (xmax - best_px) / -nx); s_pos = min(s_pos, (best_px - xmin) / -nx)
		end
		if ny > 0       s_neg = min(s_neg, (best_py - ymin) / ny);  s_pos = min(s_pos, (ymax - best_py) / ny)
		elseif ny < 0   s_neg = min(s_neg, (ymax - best_py) / -ny); s_pos = min(s_pos, (best_py - ymin) / -ny)
		end
		s_neg = max(s_neg, 1e-6);  s_pos = max(s_pos, 1e-6)

		result[i,1] = best_px - nx * s_neg
		result[i,2] = best_py - ny * s_neg
		result[i,3] = best_px + nx * s_pos
		result[i,4] = best_py + ny * s_pos
	end
	return result
end

# Count how many segments of `curve` the segment (x1,y1)-(x2,y2) crosses
function _bla_crossing_count(x1::Float64, y1::Float64, x2::Float64, y2::Float64, curve::Matrix{Float64})
	count = 0
	n = size(curve, 1)
	@inbounds for i in 1:n-1
		_blp_seg2cross(x1, y1, x2, y2, curve[i,1], curve[i,2], curve[i+1,1], curve[i+1,2]) && (count += 1)
	end
	return count
end

# Shortest distance from point (px,py) to line segment (x1,y1)-(x2,y2)
function _bla_pt_seg_dist(px::Float64, py::Float64, x1::Float64, y1::Float64, x2::Float64, y2::Float64)
	dx, dy = x2 - x1, y2 - y1
	len2 = dx * dx + dy * dy
	len2 == 0.0 && return hypot(px - x1, py - y1)
	t = clamp(((px - x1) * dx + (py - y1) * dy) / len2, 0.0, 1.0)
	return hypot(px - (x1 + t * dx), py - (y1 + t * dy))
end

# Generate ncand candidate positions along a curve (cm space).
# Returns Vector of (x, y, tangent_angle, curvature) where curvature = max angle change (rad) over a local window.
function _bla_gen_candidates(c::Matrix{Float64}, ncand::Int, frac_lo::Float64=0.1, frac_hi::Float64=0.9)
	n = size(c, 1)
	# Per-segment angles
	seg_ang = Vector{Float64}(undef, max(n - 1, 1))
	@inbounds for i in 1:n-1
		seg_ang[i] = atan(c[i+1,2] - c[i,2], c[i+1,1] - c[i,1])
	end
	# Distribute candidates evenly by INDEX (not arc-length) so that steep curves
	# don't bunch all candidates in the same visual spot.
	result = Vector{NTuple{4,Float64}}(undef, ncand)
	@inbounds for j in 1:ncand
		frac = frac_lo + (frac_hi - frac_lo) * (j - 1) / max(ncand - 1, 1)
		fidx = frac * (n - 1) + 1		# 1-based float index
		idx = clamp(floor(Int, fidx), 1, n - 1)
		t = fidx - idx
		px = c[idx,1] + t * (c[idx+1,1] - c[idx,1])
		py = c[idx,2] + t * (c[idx+1,2] - c[idx,2])
		# Smoothed tangent over a few neighboring segments
		i1 = max(1, idx - 2)
		i2 = min(n, idx + 3)
		ang = atan(c[i2,2] - c[i1,2], c[i2,1] - c[i1,1])
		# Curvature: mean absolute angle change between consecutive segments in a ±1 window
		w1 = max(1, idx - 1)
		w2 = min(n - 1, idx + 1)
		curv = 0.0
		nw = 0
		for k in w1:w2-1
			da = abs(seg_ang[k+1] - seg_ang[k])
			da > π && (da = 2π - da)		# wrap
			curv += da;  nw += 1
		end
		curv = nw > 0 ? curv / nw : 0.0
		result[j] = (px, py, ang, curv)
	end
	return result
end

# Check if two rotated boxes overlap (corner-in-box + edge crossings)
function _bla_rboxes_overlap(cx1::Float64, cy1::Float64, a1::Float64, hw1::Float64, hh1::Float64,
                             cx2::Float64, cy2::Float64, a2::Float64, hw2::Float64, hh2::Float64)
	# Quick rejection
	dist = hypot(cx2 - cx1, cy2 - cy1)
	(dist > hypot(hw1, hh1) + hypot(hw2, hh2)) && return false

	# Corners of box2 inside box1?
	c2 = _bla_corners(cx2, cy2, a2, hw2, hh2)
	cosA1, sinA1 = cos(-a1), sin(-a1)
	for (px, py) in c2
		lx = cosA1 * (px - cx1) - sinA1 * (py - cy1)
		ly = sinA1 * (px - cx1) + cosA1 * (py - cy1)
		(-hw1 <= lx <= hw1 && -hh1 <= ly <= hh1) && return true
	end

	# Corners of box1 inside box2?
	c1 = _bla_corners(cx1, cy1, a1, hw1, hh1)
	cosA2, sinA2 = cos(-a2), sin(-a2)
	for (px, py) in c1
		lx = cosA2 * (px - cx2) - sinA2 * (py - cy2)
		ly = sinA2 * (px - cx2) + cosA2 * (py - cy2)
		(-hw2 <= lx <= hw2 && -hh2 <= ly <= hh2) && return true
	end

	# Edge crossings
	for i in 1:4
		ni = mod1(i + 1, 4)
		for k in 1:4
			nk = mod1(k + 1, 4)
			_blp_seg2cross(c1[i][1], c1[i][2], c1[ni][1], c1[ni][2],
			               c2[k][1], c2[k][2], c2[nk][1], c2[nk][2]) && return true
		end
	end
	return false
end

# 4 corners of a rotated box centred at (cx,cy) with half-dims (hw,hh) and angle ang
function _bla_corners(cx::Float64, cy::Float64, ang::Float64, hw::Float64, hh::Float64)
	cosA, sinA = cos(ang), sin(ang)
	return ((cx + cosA*(-hw) - sinA*(-hh), cy + sinA*(-hw) + cosA*(-hh)),
			(cx + cosA*( hw) - sinA*(-hh), cy + sinA*( hw) + cosA*(-hh)),
			(cx + cosA*( hw) - sinA*( hh), cy + sinA*( hw) + cosA*( hh)),
			(cx + cosA*(-hw) - sinA*( hh), cy + sinA*(-hw) + cosA*( hh)))
end

# --------------------------------------------------------------------------------------------------
"""
    add_labellines(curves, val)

Add inline curve labels using GMT's quoted line option `-Sq` in segment headers.
Called from `_common_plot_xyz()` when the `labellines` keyword is used.

- `val` can be a `Vector{<:AbstractString}` with one label per curve, or a NamedTuple with fields
  `labels` (required), `fontsize` (default 8), and `prefer` (`:begin`, `:middle`, or `:end`; default `:middle`).
"""
function add_labellines!(curves, d::Dict{Symbol,Any}, _cmd::Vector{String})::Nothing
	val = find_in_dict(d, [:labellines])[1]
	if isa(val, Vector{<:AbstractString})
		labels = [string(l) for l in val]
		xv = find_in_dict(d, [:xvals])[1]
		yv = find_in_dict(d, [:yvals])[1]
		if xv !== nothing || yv !== nothing
			nc = length(curves)
			_xv = xv === nothing ? Float64[] : isa(xv, Real) ? fill(Float64(xv), nc) : Float64.(collect(xv))
			_yv = yv === nothing ? Float64[] : isa(yv, Real) ? fill(Float64(yv), nc) : Float64.(collect(yv))
			pos = _label_pos_at_vals(curves, nc, _xv, _yv)
			_add_labellines_apply(curves, _cmd, labels, 8, pos)
		else
			_add_labellines(curves, _cmd, labels, 8, :middle)
		end
		return nothing
	end
	# NamedTuple path — dispatch to the right inner function based on which options are set
	dd = nt2dict(val)
	labels::Vector{String} = [string(l) for l in dd[:labels]::Vector]
	fnt = Int(get(dd, :fontsize, 8))
	prefer = Symbol(get(dd, :prefer, :middle))
	if get(dd, :outside, false) == true
		text_cmd = _inject_outside_labels!(d, curves, labels, fnt, _cmd)
		push!(_cmd, text_cmd)
		return nothing
	end
	xv = get(dd, :xvals, nothing)
	yv = get(dd, :yvals, nothing)
	if xv !== nothing || yv !== nothing
		nc = length(curves)
		_xv::Vector{Float64} = xv === nothing ? Float64[] : isa(xv, Real) ? fill(Float64(xv), nc) : Float64.(xv)
		_yv::Vector{Float64} = yv === nothing ? Float64[] : isa(yv, Real) ? fill(Float64(yv), nc) : Float64.(yv)
		pos = _label_pos_at_vals(curves, nc, _xv, _yv)
		_add_labellines_apply(curves, _cmd, labels, fnt, pos)
		return nothing
	end
	_add_labellines(curves, _cmd, labels, fnt, prefer)
	return nothing
end

function _add_labellines(arg1::Vector{<:GMTdataset}, _cmd::Vector{String}, labels::Vector{String}, fontsize::Int, prefer::Symbol)
	pos = best_label_pos(arg1, labels; fontsize=fontsize, prefer=prefer)
	_add_labellines_apply(arg1, _cmd, labels, fontsize, pos)
end

function _add_labellines_apply(arg1::Vector{<:GMTdataset}, _cmd::Vector{String}, labels::Vector{String}, fontsize::Int, pos::Matrix{Float64})
	_cmd[1] *= " -Sq"
	for k in 1:length(labels)
		color = _extract_W_color(arg1[k].header)
		font = color != "" ? "$(fontsize)p,,$color" : "$(fontsize)p"
		lbl = occursin(' ', labels[k]) ? "\"$(labels[k])\"" : labels[k]
		sq = @sprintf("-Sql%.7g/%.7g/%.7g/%.7g:+l%s+f%s+v+c0.1/0.1", pos[k,1], pos[k,2], pos[k,3], pos[k,4], lbl, font)
		hdr = replace(arg1[k].header, r" -Sq(?:[^\s\"]|\"[^\"]*\")*" => "")	# Remove any previous -Sq option
		arg1[k].header = string(hdr, " ", sq)
	end
end

# Inject outside labels with per-curve font colors.
# Writes a temp file in GMT traditional text format (x y angle font justify text) and
# calls text!() directly with the filename so GMT parses each record's font+color.
function _inject_outside_labels!(d::Dict{Symbol,Any}, D::Vector{<:GMTdataset}, labels::Vector{String}, fontsize::Int, _cmd::Vector{String})
	info = _outside_label_data(D, labels, fontsize)
	tmpf = joinpath(TMPDIR_USR.dir, "GMTjl_outside_labels.txt")
	open(tmpf, "w") do io
		for k in 1:length(labels)
			c = info.colors[k]
			fnt = c != "" ? "$(fontsize)p,,$c" : "$(fontsize)p"
			@printf(io, "%.10g %.10g %s LM %s\n", info.x[k], info.y[k], fnt, info.labels[k])
		end
	end
	#text!(tmpf, offset=(0.15, 0.0), F="+a0+f+j", noclip=true, Vd=2)
	"pstext $(tmpf) -J -R -F+a0+f+j -D0.2/0.0 -N"		# Return the text command to be added to the main plot command
end

# Compute label positions outside the plot (at the right edge), with vertical repel to avoid overlaps.
function _outside_label_data(D::Vector{<:GMTdataset}, labels::Vector{String}, fontsize::Int)
	nc = length(D)

	# Get plot region limits
	if CTRL.limits[7] != 0
		ymin, ymax = CTRL.limits[9], CTRL.limits[10]
	else
		_, _, ymin, ymax = getregion(D)
	end
	(ymax - ymin) < 1e-10 && (ymin -= 0.5; ymax += 0.5)	# degenerate range fallback

	# x positions: at the right edge of the plot region so labels start just beyond the axis
	xmax = (CTRL.limits[7] != 0) ? CTRL.limits[8] : getregion(D)[2]
	xs = Vector{Float64}(undef, nc)
	ys = Vector{Float64}(undef, nc)
	colors = Vector{String}(undef, nc)
	for k in 1:nc
		xs[k] = xmax
		ys[k] = D[k].data[end, 2]
		colors[k] = _extract_W_color(D[k].header)
	end

	# Repel overlapping labels vertically
	pw, ph = _get_plotsize()
	sy = ph / (ymax - ymin)
	label_h = fontsize * 2.54 / 72 * 1.4	# label height in cm with some padding
	min_sep = label_h / sy					# minimum separation in data units

	order = sortperm(ys)
	ys_sorted = ys[order]
	for i in 2:nc
		if (ys_sorted[i] - ys_sorted[i-1] < min_sep)
			ys_sorted[i] = ys_sorted[i-1] + min_sep
		end
	end
	shift = (sum(ys[order]) - sum(ys_sorted)) / nc
	ys_sorted .+= shift
	for i in eachindex(order)
		ys[order[i]] = ys_sorted[i]
	end

	return (x=xs, y=ys, labels=labels, fontsize=fontsize, colors=colors)
end

# Extract the color component from a -W option in a GMT header string.
# -W can have forms like: -W0.5,red  -W,blue  -W1p,red,dash  -W0.5,200/100/50  -W#0072BD  -Wred
# The color is the second comma-separated field, or the only field if it looks like a color (not a pen width).
function _extract_W_color(header::AbstractString)::String
	m = match(r"-W([^, ]*),([^, ]+)", header)
	m !== nothing && return String(m.captures[2])
	# No comma: -W<something> where <something> might be just a color (e.g. -W#0072BD, -Wred)
	m2 = match(r"-W([^ ]+)", header)
	m2 === nothing && return ""
	s = m2.captures[1]
	# It's a color if it starts with # (hex), contains / (r/g/b), or is not a pure number/pen-width
	(startswith(s, "#") || contains(s, "/") || match(r"^[\d.]+[cipmn]?$", s) === nothing) && return String(s)
	return ""
end

# --------------------------------------------------------------------------------------------------
"""
    textrepel(points, labels; fontsize=10, force_push=1.0, force_pull=0.01,
               max_iter=500, pad=0.15, offset=10, offsets=false) -> Matrix{Float64}

Compute adjusted text label positions so that they do not overlap each other or the data points,
similar to R's `ggrepel`. Uses a force-directed simulation: labels repel each other and data points
(Coulomb-like force) while being attracted back to their anchor points (spring / Hooke force).

### Arguments
- `points`: Nx2 matrix or GMTdataset with (x,y) anchor points.
- `labels`: Vector of label strings, one per point.
- `fontsize`: font size in points (default 10).
- `force_push`: repulsion strength multiplier (default 1.0).
- `force_pull`: attraction strength back to anchor (default 0.01).
- `max_iter`: maximum number of simulation iterations (default 500).
- `pad`: extra padding around text boxes in cm (default 0.15).
- `offset`: minimum distance between label and anchor point in points (default 10).
- `offsets`: if `true`, return label displacements in cm from each anchor point instead of
  absolute data coordinates (default `false`).

### Returns
A `Matrix{Float64}` of size `(N, 2)`. When `offsets=false` (default), values are adjusted
`(x, y)` positions in data coordinates. When `offsets=true`, values are `(dx, dy)` offsets
in centimetres from each original anchor point.
"""
function textrepel(points::Union{Matrix{<:Real}, GMTdataset}, labels::Vector{<:AbstractString}; fontsize::Int=10, force_push::Real=1.0,
                   force_pull::Real=0.01, max_iter::Int=500, pad::Real=0.15, offset::Int=10, offsets::Bool=false)
	isa(points, Matrix) && (points = mat2ds(Float64.(points)))
	_textrepel(points, labels; fontsize=fontsize, force_push=Float64(force_push), force_pull=Float64(force_pull),
	           max_iter=max_iter, pad=Float64(pad), offset=offset, offsets=offsets)
end
function _textrepel(points::GMTdataset, labels::Vector{<:AbstractString}; fontsize::Int=10, force_push::Float64=1.0,
                    force_pull::Float64=0.01, max_iter::Int=500, pad::Float64=0.15, offset::Int=10, offsets::Bool=false)
	ax, ay, pw, ph, sx, sy, xmin, ymin, n = _repel_setup(points)
	n != length(labels) && error("Number of points ($n) must match number of labels ($(length(labels)))")
	fs = fontsize * 2.54 / 72
	hws = [length(l) * 0.55 * fs / 2 + pad for l in labels]
	hhs = fill(fs / 2 + pad, n)
	return _repel_core(ax, ay, hws, hhs, pw, ph, sx, sy, xmin, ymin, Float64(force_push),
	                   force_pull, offset * 2.54 / 72, max_iter, offsets)
end

# --------------------------------------------------------------------------------------------------
function circlerepel(points; diameter::Real=10, force_push::Real=1.0, force_pull::Real=0.01,
                     max_iter::Int=500, offset=10, offsets::Bool=false)
	isa(points, Matrix) && (points = mat2ds(Float64.(points)))
	_circlerepel(points; diameter=Float64(diameter), force_push=Float64(force_push), force_pull=Float64(force_pull),
	              max_iter=max_iter, offset=offset, offsets=offsets)
end
function _circlerepel(points::GMTdataset; diameter::Float64=10, force_push::Float64=1.0, force_pull::Float64=0.01,
                      max_iter::Int=500, offset::Int=10, offsets::Bool=false)
	ax, ay, pw, ph, sx, sy, xmin, ymin, n = _repel_setup(points)
	rad = diameter * 2.54 / 72 / 2
	hws, hhs = fill(rad, n), fill(rad, n)
	return _repel_core(ax, ay, hws, hhs, pw, ph, sx, sy, xmin, ymin, Float64(force_push),
	                   force_pull, offset * 2.54 / 72, max_iter, offsets)
end

# --------------------------------------------------------------------------------------------------
function _repel_setup(points::GMTdataset)
	n = size(points,1)
	xmin, xmax, ymin, ymax = (CTRL.limits[7] != 0 || CTRL.limits[8] != 0) ?
	                         (CTRL.limits[7], CTRL.limits[8], CTRL.limits[9], CTRL.limits[10]) :
	                         (CTRL.limits[1] != CTRL.limits[2]) ?
	                         (CTRL.limits[1], CTRL.limits[2], CTRL.limits[3], CTRL.limits[4]) :
	                         (points.bbox[1], points.bbox[2], points.bbox[3], points.bbox[4])
	dx = xmax - xmin;  dy = ymax - ymin
	(dx == 0) && (xmin -= 0.5; xmax += 0.5; dx = 1.0)
	(dy == 0) && (ymin -= 0.5; ymax += 0.5; dy = 1.0)
	pw, ph = _get_plotsize()
	sx, sy = pw / dx, ph / dy
	ax = (points[:,1] .- xmin) .* sx
	ay = (points[:,2] .- ymin) .* sy
	return ax, ay, pw, ph, sx, sy, xmin, ymin, n
end

# --------------------------------------------------------------------------------------------------
function _repel_core(ax, ay, hws, hhs, pw, ph, sx, sy, xmin, ymin, fp, fa, min_off, max_iter, offsets::Bool=false)
	n = length(ax)
	lx = copy(ax)
	ly = copy(ay)
	vx = zeros(n)
	vy = zeros(n)
	fx = zeros(n)
	fy = zeros(n)
	decay = 0.7

	global iters = 0
	move_hist = fill(Inf, 10)
	for _iter in 1:max_iter
		fill!(fx, 0.0)
		fill!(fy, 0.0)

		# Repulsion between label pairs
		for i in 1:n-1, j in i+1:n
			ox = (hws[i] + hws[j]) - abs(lx[i] - lx[j])
			oy = (hhs[i] + hhs[j]) - abs(ly[i] - ly[j])
			(ox <= 0 || oy <= 0) && continue
			area = ox * oy
			dx = lx[i] - lx[j]
			dy = ly[i] - ly[j]
			dist = max(hypot(dx, dy), 1e-6)
			force = fp * area / dist
			fdx = force * dx / dist
			fdy = force * dy / dist
			fx[i] += fdx;  fy[i] += fdy
			fx[j] -= fdx;  fy[j] -= fdy
		end

		# Repulsion from data points — box-edge aware.
		# Acts whenever the nearest box edge is within min_off of the anchor,
		# so diagonal labels are pushed far enough even when anchor is outside the box.
		for i in 1:n, j in 1:n
			dx = lx[i] - ax[j]
			dy = ly[i] - ay[j]
			near_x = clamp(ax[j], lx[i]-hws[i], lx[i]+hws[i])
			near_y = clamp(ay[j], ly[i]-hhs[i], ly[i]+hhs[i])
			edge_dist = hypot(ax[j]-near_x, ay[j]-near_y)
			(edge_dist >= min_off) && continue
			dist = max(hypot(dx, dy), 1e-6)
			force = fp * 0.5 * (1.0 - edge_dist / max(min_off, 1e-10)) / dist
			fx[i] += force * dx / dist
			fy[i] += force * dy / dist
		end

		# Attraction back to own anchor
		for i in 1:n
			fx[i] -= fa * (lx[i] - ax[i])
			fy[i] -= fa * (ly[i] - ay[i])
		end

		# Update velocities and positions
		max_move = 0.0
		for i in 1:n
			vx[i] = (vx[i] + fx[i]) * decay
			vy[i] = (vy[i] + fy[i]) * decay
			spd = hypot(vx[i], vy[i])
			if spd > 0.5
				vx[i] *= 0.5 / spd
				vy[i] *= 0.5 / spd
			end
			old_x, old_y = lx[i], ly[i]
			lx[i] += vx[i]
			ly[i] += vy[i]
			cx = clamp(lx[i], hws[i], pw - hws[i])
			cy = clamp(ly[i], hhs[i], ph - hhs[i])
			(cx != lx[i]) && (vx[i] = 0.0)
			(cy != ly[i]) && (vy[i] = 0.0)
			lx[i] = cx;  ly[i] = cy
			max_move = max(max_move, abs(lx[i] - old_x), abs(ly[i] - old_y))
		end
		iters += 1
		#println("  iter $iters: max_move = $max_move")
		move_hist[mod1(_iter, 10)] = max_move
		(_iter >= 50 && minimum(move_hist) >= maximum(move_hist) * 0.9) && break
	end
	#println("textrepel: completed $iters iterations")

	# Enforce minimum center-distance between anchor and label center (original behaviour).
	# This respects min_off for all label directions, especially horizontal/vertical.
	if min_off > 0
		for i in 1:n
			dx = lx[i] - ax[i]
			dy = ly[i] - ay[i]
			dist = hypot(dx, dy)
			if dist < min_off && dist > 1e-6
				scale = min_off / dist
				lx[i] = ax[i] + dx * scale
				ly[i] = ay[i] + dy * scale
				lx[i] = clamp(lx[i], hws[i], pw - hws[i])
				ly[i] = clamp(ly[i], hhs[i], ph - hhs[i])
			elseif dist < 1e-6
				ly[i] = ay[i] + min_off
				ly[i] = clamp(ly[i], hhs[i], ph - hhs[i])
			end
		end
	end

	# Diagonal correction: for labels at an angle (not near-horizontal/vertical),
	# push the label further so the box does not visually overlap the anchor marker.
	# The extra distance scales with the box height (∝ fontsize, independent of text length)
	# and is applied ONLY when both x and y placement components are significant.
	for i in 1:n
		dx = lx[i] - ax[i]
		dy = ly[i] - ay[i]
		dist = max(hypot(dx, dy), 1e-6)
		(abs(dx / dist) <= 0.25 || abs(dy / dist) <= 0.25) && continue  # near-horiz/vert: skip
		near_x = clamp(ax[i], lx[i]-hws[i], lx[i]+hws[i])
		near_y = clamp(ay[i], ly[i]-hhs[i], ly[i]+hhs[i])
		clr = hhs[i] / 2				# minimum edge-clearance for diagonal labels
		(hypot(ax[i]-near_x, ay[i]-near_y) >= clr) && continue  # already clear enough
		ux_s = dx / dist;  uy_s = dy / dist
		lo, hi = 0.0, hypot(hws[i], hhs[i]) + clr + dist
		for _ in 1:30
			mid = (lo + hi) / 2
			nlx = lx[i] + mid * ux_s;  nly = ly[i] + mid * uy_s
			nnx = clamp(ax[i], nlx-hws[i], nlx+hws[i])
			nny = clamp(ay[i], nly-hhs[i], nly+hhs[i])
			if hypot(ax[i]-nnx, ay[i]-nny) < clr
				lo = mid
			else
				hi = mid
			end
		end
		lx[i] = clamp(lx[i] + hi * ux_s, hws[i], pw - hws[i])
		ly[i] = clamp(ly[i] + hi * uy_s, hhs[i], ph - hhs[i])
	end

	# Pull-back: minimize offset without creating overlaps
	for _pull in 1:50
		moved = false
		for i in 1:n
			tox = ax[i] - lx[i]
			toy = ay[i] - ly[i]
			cur_dist = hypot(tox, toy)
			(cur_dist < 1e-6) && continue
			max_pull = min_off > 0 ? max(cur_dist - min_off, 0.0) / cur_dist : 1.0
			(max_pull < 1e-6) && continue

			lo, hi, best_t = 0.0, max_pull, 0.0
			for _ in 1:20
				t = (lo + hi) * 0.5
				nx = lx[i] + t * tox
				ny = ly[i] + t * toy
				ok = true
				for j in 1:n
					(i == j) && continue
					if (hws[i] + hws[j]) - abs(nx - lx[j]) > 0 && (hhs[i] + hhs[j]) - abs(ny - ly[j]) > 0
						ok = false; break
					end
				end
				if ok
					for j in 1:n
						if j == i
							# Own anchor: diagonal labels need edge-clearance; others just can't have anchor inside box
							ddx = nx - ax[i];  ddy = ny - ay[i]
							ddist = max(hypot(ddx, ddy), 1e-6)
							if abs(ddx/ddist) > 0.25 && abs(ddy/ddist) > 0.25
								nnx = clamp(ax[i], nx-hws[i], nx+hws[i])
								nny = clamp(ay[i], ny-hhs[i], ny+hhs[i])
								if hypot(ax[i]-nnx, ay[i]-nny) < hhs[i]/2
									ok = false; break
								end
							elseif abs(nx - ax[i]) < hws[i] && abs(ny - ay[i]) < hhs[i]
								ok = false; break
							end
						elseif abs(nx - ax[j]) < hws[i] && abs(ny - ay[j]) < hhs[i]
							ok = false; break
						end
					end
				end
				if ok
					best_t = t;  lo = t
				else
					hi = t
				end
			end
			if best_t > 1e-6
				lx[i] += best_t * tox
				ly[i] += best_t * toy
				moved = true
			end
		end
		!moved && break
	end

	result = Matrix{Float64}(undef, n, 2)
	if offsets
		for i in 1:n
			result[i, 1] = lx[i] - ax[i]   # cm offset from anchor
			result[i, 2] = ly[i] - ay[i]
		end
	else
		for i in 1:n
			result[i, 1] = lx[i] / sx + xmin
			result[i, 2] = ly[i] / sy + ymin
		end
	end
	return result
end

# --------------------------------------------------------------------------------------------------
function _get_plotsize()::Tuple{Float64, Float64}
	# Parse the plot size from CTRL.pocket_J[2] (e.g., "15c/10c" or "15c")
	s = CTRL.pocket_J[2]
	(s == "") && (s = DEF_FIG_SIZE)
	parts = split(s, '/')
	w_str = parts[1]
	isletter(w_str[end]) && (w_str = w_str[1:end-1])
	W = parse(Float64, w_str)
	if length(parts) == 2 && parts[2] != "0"
		h_str = parts[2]
		isletter(h_str[end]) && (h_str = h_str[1:end-1])
		H = parse(Float64, h_str)
	else
		H = W * 2 / 3		# Default aspect ratio
	end
	return (W, H)
end
