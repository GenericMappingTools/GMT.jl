"""
	histogram(cmd0::String="", arg1=nothing; kwargs...)

Examines the first data column to calculate histogram parameters based on the bin-width provided.
Alternatively, show histograms of GMTimage & GMTgrid objects directly. The
options 'auto=true' or 'thresholds=(0, 0.1)' will find the histogram bounds
convenient for contrast enhancement (histogram stretch). The values represent the percentage of
countings used to estimate the boundings. The option 'zoom=true' will set 'auto=true' and show
histogram only on the region of interest.

Parameters
----------

- $(_opt_J)
- **A** | **horizontal** :: [Type => Bool]

    Plot the histogram horizontally from x = 0 [Default is vertically from y = 0].
- $(opt_Jz)
- $(_opt_B)
- **C** | **color** | **cmap** :: [Type => Str | GMTcpt]

    Give a CPT. The mid x-value for each bar is used to look-up the bar color.
- **D** | **annot** | **annotate** | **counts** :: [Type => Str | Tuple]

    Annotate each bar with the count it represents.
- **E** | **width** :: [Type => Bool]			`Arg = width[+ooffset]`

    Use an alternative histogram bar width than the default set via T, and optionally shift all bars by an offset.
- **binmethod** | *BinMethod** :: [Type => Str]			`Arg = method`

    Binning algorithm: "scott", "fd", "sturges" or "sqrt" for floating point data. "second", "minute", "hour",
    "day", "week", "month" or "year" for DateTime data.
- **F** | **center** :: [Type => Bool]

    Center bin on each value. [Default is left edge].
- **G** | **fill** :: [Type => Number | Str]

    Select filling of bars [if no G, L or C set G=100].
- **I** | **inquire** | **bins** :: [Type => Bool | :O | :o | bins=(all=true,) | bins=(no_zero=true,) ]

    Inquire about min/max x and y after binning OR output the binned array.
- **L** | **out_range** :: [Type => Str]			`Arg = l|h|b`

    Handling of extreme values that fall outside the range set by **T**.
- **N** | **distribution** | **normal** :: [Type => Str]

    Draw the equivalent normal distribution; append desired pen [0.5p,black].
- $(opt_P)
- **Q** | **cumulative** :: [Type => Bool | "r"]

    Draw a cumulative histogram. Append r to instead compute the reverse cumulative histogram.
- **R** | **region** :: [Type => Str]

    Specifies the ‘region’ of interest in (r,azimuth) space. r0 is 0, r1 is max length in units.
- **S** | **stairs** :: [Type => Str | number]

    Draws a stairs-step diagram which does not include the internal bars of the default histogram.
- **T** | **range** | **bin** :: [Type => Str]			`Arg = [min/max/]inc[+n] | file|list]`

    Make evenly spaced array of bin boundaries from min to max by inc. If min/max are not given then we
    default to the range in `region`. For constant bin width use `bin=val`..
- **W** | **pen** :: [Type => Str | Tuple]

    Set pen attributes for sector outline or rose plot. [Default is no outline].
- **Z** | **kind** :: [Type => Number | Str]

    Choose between 6 types of histograms.

- $(opt_savefig)

To see the full documentation type: ``@? histogram``
"""
histogram(cmd0::String; kwargs...)  = histogram_helper(cmd0, nothing; kwargs...)
histogram(arg1; kwargs...)          = histogram_helper("", arg1; kwargs...)
histogram!(cmd0::String; kwargs...) = histogram_helper(cmd0, nothing; first=false, kwargs...)
histogram!(arg1; kwargs...)         = histogram_helper("", arg1; first=false, kwargs...)

function histogram_helper(cmd0::String="", arg1=nothing; first=true, kwargs...)
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode
	if (cmd0 != "" && is_in_dict(d, [:auto :thresholds :zoom]) !== nothing)	# To do auto-limits for stretch we must load data
		arg1 = gmtread(cmd0);		cmd0 = ""
	end
	invokelatest(histogram_helper, cmd0, arg1, O, K, d)
end

# ---------------------------------------------------------------------------------------------------
function histogram_helper(cmd0::String, arg1, O::Bool, K::Bool, d::Dict{Symbol,Any})

	arg2 = nothing		# May be needed if GMTcpt type is sent in via C
	N_args = (arg1 === nothing) ? 0 : 1

	proggy = (IamModern[1]) ? "histogram " : "pshistogram "

	cmd::String = ""
	opt_Z = add_opt(d, "", "Z", [:Z :kind], (counts = "_0", count = "_0", freq = "_1", frequency = "_1",
	                                         log_count = "_2", log_freq = "_3", log10_count = "_4", log10_freq = "_5", weights = "+w"); del=true, expand_str=true)::String
	opt_T = parse_opt_range(d, "", "")[1]		# [:T :range :inc :bin]
	(isa(arg1, GItype)) && occursin("/", opt_T) && error("here 'bin' must be a scalar")

	# If inquire, no plotting so do it and return
	opt_I::String = add_opt(d, "", "I", [:I :inquire :bins], (all = "_O", no_zero = "_o"))
	if (opt_I != "")
		cmd *= opt_I
		((r = dbg_print_cmd(d, cmd)) !== nothing) && return (!isa(arg1, GMTimage) && opt_T != "") ? r * " -T" * opt_T : r
		if (!isa(arg1, GItype))
			cmd, arg1, = read_data(d, cmd0, cmd, arg1, " ")
		end
		if (isa(arg1, GMTimage))		# If it's an image with no bin option, default to bin=1
			arg1, cmd = loc_histo(arg1, cmd, opt_T, opt_Z)
		else
			cmd *= opt_Z
			(opt_T != "") && (cmd *= " -T" * opt_T)
		end
		cmd = parse_V(d, cmd)
		return gmt(proggy * cmd, arg1)
	end

	cmd, opt_B, opt_J, opt_R ::String= parse_BJR(d, cmd, "histogram", O, " -JX14c/14c")
	cmd = parse_JZ(d, cmd)[1]
	cmd = parse_common_opts(d, cmd, [:UVXY :JZ :c :e :f :p :t :w :params :margin]; first=!O)[1]
	cmd = parse_these_opts(cmd, d, [[:A :horizontal], [:F :center], [:Q :cumulative], [:S :stairs]])
	nofill = ((symb = is_in_dict(d, [:G :fill])) !== nothing && d[symb] == "") ? true : false	# To know if no fill was asked
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd = add_opt(d, cmd, "D", [:D :annot :annotate :counts], (beneath = "_+b", font = "+f", offset = "+o", vertical = "_+r"))
	cmd = parse_INW_coast(d, [[:N :distribution :normal]], cmd, "N")
	(SHOW_KWARGS[1]) && print_kwarg_opts(symbs, "NamedTuple | Tuple | Dict | String")

	cmd = add_opt(d, cmd, "E", [:E :width], (width = "", off = "+o", offset = "+o"))
	
	# If file name sent in, read it and compute a tight -R if this was not provided
	is_datetime = isa(arg1, Array{<:DateTime})
	(opt_R == "" && !isa(arg1, Vector{DateTime})) && (opt_R = " ")	# So it doesn't try to find the -R in next call
	if (!isa(arg1, GItype))
		cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)
	end
	cmd, arg1, arg2,  = add_opt_cpt(d, cmd, CPTaliases, 'C', N_args, arg1, arg2)

	# If we still do not know the bin width, either use the GMT6.2 -E or BinMethod in binmethod()
	got_min_max = false
	is_subarray_float = (typeof(arg1) <: SubArray{Float32})		# This is to allow @subviews that can't go into GMTgrid|image
	is_subarray_uint  = (typeof(arg1) <: SubArray{Unsigned})
	!is_subarray_uint && (is_subarray_uint = eltype(arg1) <: Unsigned)	# For those grids with UInt16 (the VIIRS data)
	issub = (is_subarray_float || is_subarray_uint)
	if (opt_T == "" && !occursin(" -E", cmd) && (arg1 !== nothing) && !isa(arg1, GMTimage) && !isa(arg1, GMTgrid) && !issub)
		opt_T, min_max = binmethod(d, cmd, arg1, is_datetime)	# This comes without the " -T"
		got_min_max = true
		if (is_datetime)
			t = gmt("pshistogram -I -T" * opt_T, arg1)	# Call with inquire option to know y_min|max
			h = round_wesn(t.data)						# Only h[4] is needed
			opt_R *= @sprintf("/0/%.12g", h[4])			# Half -R was computed in read_data()
			cmd *= opt_R * " -T" * opt_T
			opt_T = ""		# Clear it because the GMTimage & GMTgrid use a version without "-T" that is added at end
		end
	end

	cmd  = add_opt(d, cmd, "L", [:L :out_range], (first = "l", last = "h", both = "b"))
	cmd *= add_opt_pen(d, [:W :pen], opt="W")
	if (!occursin("-G", cmd) && !occursin("-C", cmd) && !occursin("-S", cmd))
		!nofill && (cmd *= " -G#0072BD")		# Unless specifically set to no, use a default color
		!occursin("-W", cmd) && (cmd *= " -Wfaint")
    elseif (occursin("-S", cmd) && !occursin("-W", cmd))
		cmd *= " -Wfaint"
	end

	limit_L = nothing
	do_auto = ((val_auto = find_in_dict(d, [:auto :thresholds])[1]) !== nothing) ? true : false	# Automatic bounds detetion
	do_getauto = ((val_getauto = find_in_dict(d, [:getauto :getthresholds])[1]) !== nothing) ? true : false
	do_zoom = ((find_in_dict(d, [:zoom])[1]) !== nothing) ? true : false	# Automatic zoom to interesting region

	function if_zoom(cmd, opt_R, limit_L, hst)
		isempty(hst) && error("No histogram data to compute the region limits.")
		mm = extrema(hst, dims=1)			# 1×2 Array{Tuple{UInt16,UInt16},2}
		x_max = min(limit_R * 1.15, hst[end,1])		# 15% to the right but not fall the cliff
		opt_R_ = " -R$(limit_L * 0.85)/$x_max/0/$(mm[2][2] * 1.1) "
		(opt_R != " ") && @warn("'zoom' option overrides the requested region limits and sets its own")
		cmd = replace(cmd, opt_R => opt_R_, count=1)
		return cmd, opt_R_					# opt_R_ will be needed further down in vline
	end

	# If we have a RGB image, plot 3 histograms and end right now
	if (isa(arg1, GMTimage{UInt8, 3}))
		(arg1.layout != "" && arg1.layout[3] == 'B') && return three_histos(d, arg1, cmd, proggy, O, opt_T, opt_Z, opt_B, opt_R, opt_J)
		@warn("Three histograms of pixel interleaving of RGB images not yet implemented.")
	end

	if (isa(arg1, GMTimage) || is_subarray_uint)				# If it's an image with no bin option, default to bin=1
		do_clip = (isa(arg1[1], UInt16) && (val = find_in_dict(d, [:full_histo])[1]) === nothing) ? true : false
		(do_zoom && !do_auto) && (val_auto = nothing)			# I.e. 'zoom' sets also the auto mode
		hst, cmd = loc_histo(arg1, cmd, opt_T, opt_Z)
		(do_clip && (all(hst[3:10,2] .== 0)) || hst[1,2] > 100 * mean(hst[2:10,2])) && (hst[1,2] = 0; hst[2,2] = 0)
		if (do_auto || do_getauto || do_zoom)
			which_auto = (do_auto) ? val_auto : val_getauto
			limit_L, limit_R = find_histo_limits(arg1, which_auto, 20)
			(do_getauto) && return [Int(limit_L), Int(limit_R)]	# If only want the histogram limits, we are done then.
			if (do_zoom)  cmd, opt_R = if_zoom(cmd, opt_R, limit_L, hst)  end
		end
		arg1 = hst		# We want to send the histogram, not the GMTimage
	elseif (isa(arg1, GMTgrid) || is_subarray_float)
		hst, inc, _min_max = hst_floats(arg1, opt_T; min_max=got_min_max ? min_max : (0.0, 0.0))

		if (do_auto || do_getauto || do_zoom)
			which_auto = (do_auto) ? val_auto : val_getauto
			limit_L, limit_R = find_histo_limits(arg1, which_auto, inc, hst)
			(do_getauto) && return [limit_L, limit_R]	# If only want the histogram limits, we are done then.
			limit_L, limit_R = round(limit_L, digits=4), round(limit_R, digits=4)	# Don't plot an ugly number of decimals
			if (do_zoom)  cmd, opt_R = if_zoom(cmd, opt_R, limit_L, hst)  end
		end

		cmd = (opt_Z == "") ? cmd * " -Z0" : cmd * opt_Z
		if (!occursin("+w", cmd))  cmd *= "+w"  end		# Pretending to be weighted is crutial for the trick
		cmd *= " -T$(_min_max[1])/$(_min_max[2])/$inc"
		arg1 = hst		# We want to send the histogram, not the GMTgrid
	else
		(opt_T != "") && (opt_T = " -T" * opt_T)		# It lacked the -T so that it could be used in loc_histo()
		cmd *= opt_T * opt_Z
		(cmd0 != "" && !occursin(" -T", cmd)) && error("When input is a file name it is mandatory to set the bin width the 'range' option.")
	end

	# The following looks a bit messy but it's needed to auto plotting verical lines with the limits
	show_ = false;		fmt_ = FMT[1];		savefig_ = nothing
	if (limit_L !== nothing)
		haskey(d, :show) && (show_ = (d[:show] != 0))				# Backup the :show val
		d[:show] = false
		haskey(d, :fmt) && (fmt_ = d[:fmt]; delete!(d, :fmt))		# Backup the :fmt val
		((val = find_in_dict(d, [:savefig :figname :name])[1]) !== nothing) && (savefig_ = val)
	end

	out2 = nothing;		Vd_ = 0				# Backup values
	(haskey(d, :Vd)) && (Vd_ = d[:Vd])

	_cmd = [proggy * cmd]				# In any case we need this
	(length(opt_R) > 5) && (_cmd = frame_opaque(_cmd, opt_B, opt_R, opt_J))		# No -t in frame
	_cmd = fish_bg(d, _cmd)					# See if we have a "pre-command" (background img)

	# Plot the histogram
	((r = check_dbg_print_cmd(d, _cmd)) !== nothing) && return r
	out1 = prep_and_call_finish_PS_module(d, _cmd, "", K, O, true, arg1, arg2)

	# And if wished, plot the two vertical lines with the limits annotated in them
	if (limit_L !== nothing)
		if (opt_R == " ")					# Set a region for the vlines
			isempty(hst) && error("No histogram data to compute the region limits.")
			mm = extrema(hst, dims=1)
			opt_R = " -R$(mm[1][1])/$(mm[1][2])/0/$(mm[2][2])"
		end
		vlines!([limit_L], pen="0.5p,blue,dashed", decorated=(quoted = true, n_labels = 1, const_label = "$limit_L", font = 9, pen = (0.5, :red)), R=opt_R[4:end], Vd=Vd_)
		out2 = vlines!([limit_R], pen="0.5p,blue,dashed", decorated=(quoted = true, n_labels = 1, const_label = "$limit_R", font = 9, pen = (0.5, :red)), R=opt_R[4:end], fmt=fmt_, savefig=savefig_, show=show_, Vd=Vd_)
	end
	out = (out1 !== nothing && out2 !== nothing) ? [out1;out2] : ((out1 !== nothing) ? out1 : out2)

end

# ---------------------------------------------------------------------------------------------------
function three_histos(d::Dict, I::GMTimage{UInt8, 3}, cmd, proggy, O, opt_T, opt_Z, opt_B, opt_R, opt_J)
	fmt_ = FMT[1];		show_ = false;	savefig_ = nothing
	haskey(d, :show) && (show_ = (d[:show] != 0))				# Backup the :show val
	d[:show] = false
	haskey(d, :fmt) && (fmt_ = d[:fmt]; delete!(d, :fmt))		# Backup the :fmt val
	((val = find_in_dict(d, [:savefig :figname :name])[1]) !== nothing) && (savefig_ = val)

	s = split(opt_J, '/')
	H = (CTRL.limits[8] == 0.0) ? 5.0 : (parse(Float64, isletter(s[2][end]) ? s[2][1:end-1] : s[2]) / 3.0)
	cmd = replace(cmd, opt_J => s[1] * "/$H")
	_cmd = proggy * cmd				# In any case we need this
	(length(opt_R) > 5) && (_cmd = frame_opaque(_cmd, opt_B, opt_R, opt_J))		# No -t in frame
	_cmd = fish_bg(d, [_cmd])[1]					# See if we have a "pre-command" (background img)

	hst, _cmd = loc_histo(view(I, :, :, 1), _cmd, opt_T, opt_Z)
	_cmd = replace(_cmd, "-G#0072BD" => "-Gred")
	prep_and_call_finish_PS_module(d, [_cmd], "", true, O, true, hst)
	O = true
	hst, = loc_histo(view(I, :, :, 2), _cmd, "", "")
	_cmd = replace(_cmd, "-Gred" => "-Ggreen")
	(opt_B == DEF_FIG_AXES_BAK) && (_cmd = replace(_cmd, opt_B => " -Baf -BWsen"))
	prep_and_call_finish_PS_module(d, [_cmd * " -Y$(H)c"], "", true, O, true, hst)
	hst, = loc_histo(view(I, :, :, 3), _cmd, "", "")
	_cmd = replace(_cmd, "-Ggreen" => "-Gblue")

	(d[:show] = show_; d[:fmt] = fmt_; d[:savefig] = savefig_)		# 
	prep_and_call_finish_PS_module(d, [_cmd * " -Y$(H)c"], "", true, O, true, hst)
end

# ---------------------------------------------------------------------------------------------------
const pshistogram  = histogram			# Alias
const pshistogram! = histogram!			# Alias