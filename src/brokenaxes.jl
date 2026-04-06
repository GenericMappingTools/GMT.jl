# ─────────────────────────────────────────────────────────────────────────────
# Broken-axis feature, activated from plot() when breakx/breaky/xranges/yranges
# are present in d.
#
# Broken-axis-specific options (all others pass through to plot() as normal):
#   breakx=(x1,x2)           — interval to skip on X; panels from data bbox
#   xranges=[(a,b),(c,d),...] — explicit X panel ranges
#   breaky=(y1,y2)           — interval to skip on Y; panels from data bbox
#   yranges=[(a,b),(c,d),...] — explicit Y panel ranges (bottom to top)
#   gap=0.5                  — gap between panels in cm
#   widths=[...]             — explicit panel widths in cm (X-broken)
#   heights=[...]            — explicit panel heights in cm (Y-broken)
#   break_angle=70           — angle of break marks from horizontal (degrees)
#   break_size=0.35          — length of each break mark in cm
#   break_spacing=0.15       — perpendicular distance between the two marks in cm
#   no_break_symbols=false   — skip drawing break symbols
#
# All other plot() options (region, figsize, title, xlabel, ...) stay in d and are
# consumed by parse_R, parse_J, parse_B, etc. inside common_plot_xyz as normal.
# ─────────────────────────────────────────────────────────────────────────────
function _brokenplot(arg1, first::Bool, d::Dict{Symbol,Any})

	breakx           = pop!(d, :breakx,  nothing)
	breaky           = pop!(d, :breaky,  nothing)
	xranges          = pop!(d, :xranges, nothing)
	yranges          = pop!(d, :yranges, nothing)
	widths_arg       = pop!(d, :widths,  nothing)
	heights_arg      = pop!(d, :heights, nothing)
	gap              = Float64(pop!(d, :gap, 0.5))
	break_angle      = Float64(pop!(d, :break_angle,   70.0))
	break_size       = Float64(pop!(d, :break_size,    0.35))
	break_spacing    = Float64(pop!(d, :break_spacing, 0.15))
	no_break_symbols = pop!(d, :no_break_symbols, false)

	bb = getregion(arg1)	# (xmin, xmax, ymin, ymax)

	has_xbreak = (breakx !== nothing) || (xranges !== nothing)
	has_ybreak = (breaky !== nothing) || (yranges !== nothing)

	(!has_xbreak && !has_ybreak) && error("brokenplot: provide breakx/xranges or breaky/yranges")
	(has_xbreak  &&  has_ybreak) && error("brokenplot: provide breakx/xranges OR breaky/yranges (not both simultaneously)")

	do_show, fmt, savefig = get_show_fmt_savefig(d, false)
	axis = has_xbreak ? :x : :y

	# Call parse_R to consume region from d (same as common_plot_xyz would).
	# After this, CTRL.limits[7:10] = (xmin, xmax, ymin, ymax) if region was given.
	opt_R = parse_R(d, "")[2]
	has_region = (opt_R != "")

	# ── Build broken-axis ranges ──────────────────────────────────────────
	if axis === :x
		if (xranges === nothing)
			(breakx === nothing) && error("plot: provide `breakx=(a,b)` or `xranges=[(a,b),...]`")
			xranges = [(bb[1], Float64(breakx[1])), (Float64(breakx[2]), bb[2])]
		end
		brkranges = [(Float64(r[1]), Float64(r[2])) for r in xranges]
		fixed_range = has_region ? (CTRL.limits[9], CTRL.limits[10]) :
		              (bb[3] - max((bb[4]-bb[3])*0.05, 1e-10), bb[4] + max((bb[4]-bb[3])*0.05, 1e-10))
	else
		if (yranges === nothing)
			(breaky === nothing) && error("plot: provide `breaky=(a,b)` or `yranges=[(a,b),...]`")
			yranges = [(bb[3], Float64(breaky[1])), (Float64(breaky[2]), bb[4])]
		end
		brkranges = [(Float64(r[1]), Float64(r[2])) for r in yranges]
		fixed_range = has_region ? (CTRL.limits[7], CTRL.limits[8]) :
		              (bb[1] - max((bb[2]-bb[1])*0.05, 1e-10), bb[2] + max((bb[2]-bb[1])*0.05, 1e-10))
	end

	# ── Compute variable panel sizes ──────────────────────────────────────
	# Default total: 15 cm wide × 10 cm tall. Users needing other sizes provide widths=/heights=.
	nranges     = length(brkranges)
	range_spans = [r[2] - r[1] for r in brkranges]
	if axis === :x
		avail     = 15.0 - gap * (nranges - 1)
		sizes_arg = widths_arg
		fixed_sz  = 10.0
	else
		avail     = 10.0 - gap * (nranges - 1)
		sizes_arg = heights_arg
		fixed_sz  = 15.0
	end
	t = avail / sum(range_spans)
	panel_sizes = (sizes_arg === nothing) ?  [t * s for s in range_spans] : Float64.(sizes_arg)
	scale_fixed = fixed_sz / (fixed_range[2] - fixed_range[1])

	_brokenplot_core(arg1, first, axis, brkranges, fixed_range, panel_sizes, gap,
	                 fixed_sz, scale_fixed, break_angle, break_size, break_spacing,
	                 no_break_symbols, d)

	(do_show || fmt !== "" || savefig !== "") && showfig(show=do_show, fmt=fmt, savefig=savefig)
end

# ─────────────────────────────────────────────────────────────────────────────
# Generic core: axis = :x → side-by-side panels; axis = :y → stacked panels.
#
# brkranges   — ranges along the broken axis [(lo,hi), ...]
# fixed_range — (lo, hi) of the fixed axis
# panel_sizes — cm size of each panel along the broken axis
# fixed_sz    — cm size along the fixed axis (constant across panels)
# scale_fixed — cm per data unit on the fixed axis
# ─────────────────────────────────────────────────────────────────────────────
function _brokenplot_core(arg1, first::Bool, axis::Symbol, brkranges, fixed_range, panel_sizes, gap, fixed_sz, scale_fixed,
                           break_angle, break_size, break_spacing, no_break_symbols, d)

	nranges     = length(brkranges)
	range_spans = [r[2] - r[1] for r in brkranges]
	#scale_brks  = [panel_sizes[i] / range_spans[i] for i in 1:nranges]
	flo, fhi    = fixed_range[1], fixed_range[2]
	shift_key   = axis === :x ? :X : :Y

	# Projection strings: broken-axis size varies per panel, fixed-axis size is constant
	projs = (axis === :x) ?
		["X$(panel_sizes[i])c/$(fixed_sz)c" for i in 1:nranges] :
		["X$(fixed_sz)c/$(panel_sizes[i])c" for i in 1:nranges]

	# Frame sides: suppress inner borders on the broken-axis direction
	(axis === :x) ? (sides_fst = "WSN"; sides_lst = "ESN"; sides_mid = "SN") : (sides_fst = "WSe"; sides_lst = "WNe"; sides_mid = "We")

	# X-broken: title on panel 1; Y-broken: title on topmost panel (nranges)
	title_panel = (axis === :x) ? 1 : nranges

	# ── Draw panels ───────────────────────────────────────────────────────
	# Keep a master copy so style options (lw, lc, pen, …) survive across panels.
	# Each panel gets a fresh copy; common_plot_xyz consumes from the copy only.
	d0 = copy(d)
	for i in 1:nranges
		di = copy(d0)
		blo, bhi = brkranges[i]
		di[:region] = axis === :x ? (blo, bhi, flo, fhi) : (flo, fhi, blo, bhi)
		di[:proj]   = projs[i]
		sides = (nranges == 1) ? "WSEN" : (i == 1) ? sides_fst : (i == nranges) ? sides_lst : sides_mid
		di[:frame]  = (axes = sides, annot = :auto, ticks = :auto)
		(i > 1) && (di[shift_key] = "$(panel_sizes[i-1] + gap)c")
		# title/subtitle only on title_panel; xlabel/ylabel only on panel 1
		(i != title_panel) && (delete!(di, :title); delete!(di, :subtitle))
		(i != 1)           && (delete!(di, :xlabel); delete!(di, :ylabel))
		common_plot_xyz("", arg1, "plot", i == 1 && first, false, di)
	end

	#=
	no_break_symbols && return nothing

	# ── Draw break symbols ────────────────────────────────────────────────
	# cumulative[i] = offset (cm) of panel i along the broken axis from panel 1
	cumulative = zeros(nranges)
	for i in 2:nranges
		cumulative[i] = cumulative[i-1] + panel_sizes[i-1] + gap
	end
	current_panel = nranges   # PS origin is currently at the last panel

	for i in 1:(nranges - 1)
		edge_L = brkranges[i][2];   sc_L = scale_brks[i]
		edge_R = brkranges[i+1][1]; sc_R = scale_brks[i+1]

		reg_L = axis === :x ? (brkranges[i][1], edge_L, flo, fhi) : (flo, fhi, brkranges[i][1], edge_L)
		reg_R = axis === :x ? (edge_R, brkranges[i+1][2], flo, fhi) : (flo, fhi, edge_R, brkranges[i+1][2])

		for fpos in (flo, fhi)
			bx_L, by_L, sx_L, sy_L = (axis === :x) ? (edge_L, fpos, sc_L, scale_fixed) : (fpos, edge_L, scale_fixed, sc_L)
			dshift = cumulative[i] - cumulative[current_panel]
			_ba_break_symbol!(bx_L, by_L, dshift, reg_L, projs[i], sx_L, sy_L, break_angle, break_size, break_spacing, axis)
			current_panel = i

			bx_R, by_R, sx_R, sy_R = (axis === :x) ? (edge_R, fpos, sc_R, scale_fixed) : (fpos, edge_R, scale_fixed, sc_R)
			dshift = cumulative[i+1] - cumulative[current_panel]
			_ba_break_symbol!(bx_R, by_R, dshift, reg_R, projs[i+1], sx_R, sy_R, break_angle, break_size, break_spacing, axis)
			current_panel = i + 1
		end
	end
	=#
	return nothing
end

#= ─────────────────────────────────────────────────────────────────────────────
"""
Draw a double-slash break symbol centred at (data_x, data_y).

- `dshift`: relative shift (cm) to reach this panel from the current PS origin.
- `axis`: `:x` — X-break (eraser horizontal, navigate via `X=`);
          `:y` — Y-break (eraser vertical, navigate via `Y=`).
"""
function _ba_break_symbol!(data_x::Float64, data_y::Float64,
                            dshift::Float64,
                            reg::Tuple, prj::String,
                            sx::Float64, sy::Float64,
                            break_angle::Float64,
                            break_size::Float64,
                            break_spacing::Float64,
                            axis::Symbol = :x)
	a = break_angle * π / 180.0
	ca, sa = cos(a), sin(a)

	hl_x = break_size    / 2.0 * ca / sx
	hl_y = break_size    / 2.0 * sa / sy
	hs_x = break_spacing / 2.0 * (-sa) / sx
	hs_y = break_spacing / 2.0 * ca  / sy

	if axis === :x
		erase_half = (break_size * 0.7) / sx
		plot!([data_x - erase_half, data_x + erase_half], [data_y, data_y]; region=reg, proj=prj, lw=6, lc=:white, X="$(dshift)c")
	else
		erase_half = (break_size * 0.7) / sy
		plot!([data_x, data_x], [data_y - erase_half, data_y + erase_half]; region=reg, proj=prj, lw=6, lc=:white, Y="$(dshift)c")
	end

	for sign in (-1.0, 1.0)
		cx = data_x + sign * hs_x
		cy = data_y + sign * hs_y
		plot!([cx - hl_x, cx + hl_x], [cy - hl_y, cy + hl_y]; region=reg, proj=prj, lw=1.5, lc=:black, X="0c")
	end
end
=#