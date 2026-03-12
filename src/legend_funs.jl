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
