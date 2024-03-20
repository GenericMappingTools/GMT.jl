"""
	histogram(cmd0::String="", arg1=nothing; kwargs...)

Examines the first data column to calculate histogram parameters based on the bin-width provided.
Alternatively, show histograms of GMTimage & GMTgrid objects directly. The
options 'auto=true' or 'thresholds=(0, 0.1)' will find the histogram bounds
convenient for contrast enhancement (histogram stretch). The values represent the percentage of
countings used to estimate the boundings. The option 'zoom=true' will set 'auto=true' and show
histogram only on the region of interest.

See full GMT (not the `GMT.jl` one) docs at [`pshistogram`]($(GMTdoc)histogram.html)

Parameters
----------

- $(GMT._opt_J)
- **A** | **horizontal** :: [Type => Bool]

    Plot the histogram horizontally from x = 0 [Default is vertically from y = 0].
- $(GMT.opt_Jz)
- $(GMT._opt_B)
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
- $(GMT.opt_P)
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
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT._opt_bi)
- $(GMT._opt_di)
- $(GMT.opt_e)
- $(GMT._opt_f)
- $(GMT._opt_h)
- $(GMT._opt_i)
- $(GMT._opt_p)
- $(GMT._opt_t)
- $(GMT.opt_w)
- $(GMT.opt_swap_xy)
- $(GMT.opt_savefig)

To see the full documentation type: ``@? histogram``
"""
histogram(cmd0::String; kwargs...)  = histogram_helper(cmd0, nothing; kwargs...)
histogram(arg1; kwargs...)          = histogram_helper("", arg1; kwargs...)
histogram!(cmd0::String; kwargs...) = histogram_helper(cmd0, nothing; first=false, kwargs...)
histogram!(arg1; kwargs...)         = histogram_helper("", arg1; first=false, kwargs...)

# ---------------------------------------------------------------------------------------------------
function histogram_helper(cmd0::String, arg1; first=true, kwargs...)

	arg2 = nothing		# May be needed if GMTcpt type is sent in via C
	N_args = (arg1 === nothing) ? 0 : 1

	gmt_proggy = (IamModern[1]) ? "histogram " : "pshistogram "

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	if (cmd0 != "" && is_in_dict(d, [:auto :thresholds :zoom]) !== nothing)	# To do auto-limits for stretch we must load data
		arg1 = gmtread(cmd0);		cmd0 = ""
	end

	cmd::String = ""
	opt_Z = add_opt(d, "", "Z", [:Z :kind], (counts = "_0", count = "_0", freq = "_1", frequency = "_1",
	                                         log_count = "_2", log_freq = "_3", log10_count = "_4", log10_freq = "_5", weights = "+w"), true, "")::String
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
		return gmt(gmt_proggy * cmd, arg1)
	end

	cmd, opt_B, opt_J, opt_R ::String= parse_BJR(d, cmd, "histogram", O, " -JX14c/14c")
	cmd = parse_JZ(d, cmd)[1]
	cmd = parse_common_opts(d, cmd, [:UVXY :JZ :c :e :f :p :t :w :params], first)[1]
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
	cmd *= add_opt_pen(d, [:W :pen], "W")
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
		mm = extrema(hst, dims=1)			# 1×2 Array{Tuple{UInt16,UInt16},2}
		x_max = min(limit_R * 1.15, hst[end,1])		# 15% to the right but not fall the cliff
		opt_R_ = " -R$(limit_L * 0.85)/$x_max/0/$(mm[2][2] * 1.1) "
		(opt_R != " ") && @warn("'zoom' option overrides the requested region limits and sets its own")
		cmd = replace(cmd, opt_R => opt_R_, count=1)
		return cmd, opt_R_					# opt_R_ will be needed further down in vline
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
		_min_max = (isa(arg1, GMTgrid)) ? (arg1.range[5], arg1.range[6]) : (got_min_max ? min_max : Float64.(extrema_nan(arg1))) 
		if (opt_T != "")
			inc = parse(Float64, opt_T) + eps()		# + EPS to avoid the extra last bin at right with 1 count only
			n_bins = Int(ceil((_min_max[2] - _min_max[1]) / inc))
		else
			n_bins = Int(ceil(sqrt(length(arg1))))
			reg = isa(arg1, GItype) ? (arg1.registration == 0 ? 1 : 0) : 1	# When called from RemoteS arg1 is a view of a layer.
			inc = (_min_max[2] - _min_max[1]) / (n_bins - reg) + eps()
		end
		(!isa(inc, Real) || inc <= 0) && error("Bin width must be a > 0 number and no min/max")
		hst = zeros(n_bins, 2)
		if (eltype(arg1) <: AbstractFloat)		# Float arrays can have NaNs
			have_nans = !(isa(arg1, GMTgrid) && arg1.hasnans == 1)
			have_nans && (have_nans = any(!isfinite, arg1))
		end
		if (have_nans)							# If we have NaNs in the grid, we need to take a slower branch
			@inbounds for k = 1:numel(arg1)
				!isnan(arg1[k]) && (hst[Int(floor((arg1[k] - _min_max[1]) / inc) + 1), 2] += 1)
			end
		else
			@inbounds for k = 1:numel(arg1)  hst[Int(floor((arg1[k] - _min_max[1]) / inc) + 1), 2] += 1  end
		end
		@inbounds for k = 1:n_bins  hst[k,1] = _min_max[1] + inc * (k - 1)  end

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

	_cmd = [gmt_proggy * cmd]				# In any case we need this
	(length(opt_R) > 5) && (_cmd = frame_opaque(_cmd, opt_B, opt_R, opt_J))		# No -t in frame
	_cmd = fish_bg(d, _cmd)					# See if we have a "pre-command" (background img)

	# Plot the histogram
	out1 = finish_PS_module(d, _cmd, "", K, O, true, arg1, arg2)

	# And if wished, plot the two vertical lines with the limits annotated in them
	if (limit_L !== nothing)
		if (opt_R == " ")					# Set a region for the vlines
			mm = extrema(hst, dims=1)
			opt_R = " -R$(mm[1][1])/$(mm[1][2])/0/$(mm[2][2])"
		end
		vlines!([limit_L], pen="0.5p,blue,dashed", decorated=(quoted = true, n_labels = 1, const_label = "$limit_L", font = 9, pen = (0.5, :red)), R=opt_R[4:end], Vd=Vd_)
		out2 = vlines!([limit_R], pen="0.5p,blue,dashed", decorated=(quoted = true, n_labels = 1, const_label = "$limit_R", font = 9, pen = (0.5, :red)), R=opt_R[4:end], fmt=fmt_, savefig=savefig_, show=show_, Vd=Vd_)
	end
	out = (out1 !== nothing && out2 !== nothing) ? [out1;out2] : ((out1 !== nothing) ? out1 : out2)

end

# ---------------------------------------------------------------------------------------------------
function find_histo_limits(In, thresholds=nothing, width=20, hst_::Matrix{Float64}=Matrix{Float64}(undef,0,2))
	# Find the histogram limits of a UInt16 GMTimage that allow to better stretch the histogram
	# THRESHOLDS is an optional Tuple input containing the left and right histo thresholds, in percentage,
	# between which the histogram values will be retained. Defaults are (0.1, 0.4) percent. Note, this
	# assumes the histogram follows some sort of Gaussian distribution. It it's flat, shit occurs.
	# WIDTH is bin width used to obtain a rough histogram that is used to compute the limits.
	if (isa(In, Array{UInt16,3}) || isa(In, Array{UInt8,3}))
		L1 = find_histo_limits(view(In, :, :, 1), thresholds, width)
		L2 = find_histo_limits(view(In, :, :, 2), thresholds, width)
		L3 = find_histo_limits(view(In, :, :, 3), thresholds, width)
		return (L1[1], L1[2], L2[1], L2[2], L3[1], L3[2])
	end
	hst = (isempty(hst_)) ? loc_histo(In, "", string(width), "")[1] : hst_
	if (size(hst, 1) > 10)
		all(hst[2:5,2] .== 0) && (hst[1,2] = 0)	# Here we always check for high counts in zero bin
		# Some processed bands leave garbage on the low DNs and that fouls our detecting algo. So check more
		((hst[1,2] != 0) && hst[1,2] > 100 * mean(hst[2:10,2])) && (hst[1,2] = 0)	# Ad-hoc numbers
		# Next is for the case of VIIRS bands that have nodata = 65535 but when called from 'truecolor'
		# it only passes a band view (the array) and we have access to image's header here.
		(width == 20 && eltype(In) == UInt16 && size(hst,1) == 3277) && (hst[end, 2] = 0)
	end
	max_ = maximum(hst, dims=1)[2]
	(max_ == 0) && error("This histogram had nothing but countings ONLY in first bin. No point to proceed.")
	thresh_l::Float64 = 0.001;		thresh_r::Float64 = 0.004
	if (isa(thresholds, Tuple) && length(thresholds) == 2)
		thresh_l, thresh_r = thresholds[:] ./ 100
	end
	thresh_l *= max_
	thresh_r *= max_
	kl = 1;		kr = size(hst, 1)
	while (hst[kl,2] == 0 || hst[kl,2] < thresh_l)  kl += 1  end
	while (hst[kr,2] == 0 || hst[kr,2] < thresh_r)  kr -= 1  end
	#return Int(hst[kl,1]), Int(min(hst[kr,1] + width, hst[end,1]))
	return hst[kl,1], min(hst[kr,1] + width, hst[end,1])
end

# ---------------------------------------------------------------------------------------------------
function loc_histo(in, cmd::String="", opt_T::String="", opt_Z::String="")
	# Very simple function to compute histograms of images (integers)
	# We put the countings in a Mx2 arrray to trick GMT (pshistogram) to think it's recieving a weighted input.
	(!isa(in[1], UInt16) && !isa(in[1], UInt8)) && error("Only UInt8 or UInt16 image types allowed here")

	inc::Float64 = (opt_T != "") ? parse(Float64, opt_T) : 1.0
	(inc <= 0) && error("Bin width must be a number > 0 and no min/max")

	n_bins::Int = (isa(in[1], UInt8)) ? 256 : Int(ceil((maximum(in) + 1) / inc))	# For UInt8 use the full [0 255] range
	hst = zeros(n_bins, 2)
	pshst_wall!(in, hst, inc, n_bins)

	cmd = (opt_Z == "") ? cmd * " -Z0" : cmd * opt_Z
	(!occursin("+w", cmd)) && (cmd *= "+w")			# Pretending to be weighted is crutial for the trick

	return hst, cmd * " -T0/$(n_bins * inc)/$inc"
end

# ---------------------------------------------------------------------------------------------------
function pshst_wall!(in, hst, inc, n_bins::Int)
	# Function barrier for type instability. With the body of this in the calling fun the 'inc' var
	# introduces a mysterious type instability and execution times multiply by 3.
	if (inc == 1)
		@inbounds Threads.@threads for k = 1:numel(in)  hst[in[k] + 1, 2] += 1  end
    else
		@inbounds Threads.@threads for k = 1:numel(in)  hst[Int(floor(in[k] / inc) + 1), 2] += 1  end
	end
	(isa(in, GItype) && in.nodata == typemax(eltype(in))) && (hst[end] = 0)
	@inbounds Threads.@threads for k = 1:n_bins  hst[k,1] = inc * (k - 1)  end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function binmethod(d::Dict, cmd::String, X, is_datetime::Bool)
	# Compute bin width for a series of binning alghoritms or intervals when X (DateTime) comes in seconds
	val::String = ((val_ = find_in_dict(d, [:binmethod :BinMethod])[1]) !== nothing) ? lowercase(string(val_)) : ""
	min_max = (zero(eltype(X)), zero(eltype(X)))
	(!is_datetime) && (min_max = extrema(X))		# X should already be sorted but don't trust that
	if (val == "")
		if (!is_datetime)
			val = "sqrt"
		else
			min_max = extrema(X)		# X should already be sorted but don't trust that
			rng = (min_max[2] - min_max[1])
			if     (rng < 150)                 val = "second"
			elseif (rng / (60) < 150)          val = "minute"
			elseif (rng / (3600)  < 150)       val = "hour"
			elseif (rng / (86400) < 150)       val = "day"
			elseif (rng / (86400 * 7)  < 150)  val = "week"
			elseif (rng / (86400 * 31) < 150)  val = "month"
			else                               val = "year"
			end
		end
	end

	n_bins = 0.0;	bin = 0
	if     (val == "scott")   n_bins = 3.5 .* std(X) .* length(X)^(-1/3)
	elseif (val == "fd")      n_bins = 2 .* IQR(X) .* length(X)^(-1/3)
	elseif (val == "sturges") n_bins = ceil.(1 .+ log2.(length(X)))
	elseif (val == "sqrt")    n_bins = ceil.(sqrt(length(X)))
	elseif (val == "year")    bin = 86400 * 365.25
	elseif (val == "month")   bin = 86400 * 31
	elseif (val == "week")    bin = 86400 * 7
	elseif (val == "day")     bin = 86400
	elseif (val == "hour")    bin = 3600
	elseif (val == "minute")  bin = 60
	elseif (val == "second")  bin = 1
	elseif (!is_datetime)     error("Unknown BinMethod $val")
	end
	if (bin == 0)
		bin = (min_max[2] - min_max[1]) / n_bins	# Should be made a "pretty" number?
	end
	return @sprintf("%.12g", bin), min_max
end

# ---------------------------------------------------------------------------------------------------
# This version computes the histogram for a UInt8 image band with a bin width of 1
histogray(img::GMTimage{<:UInt8}; band=1) = histogray(view(img.image, :, :, band))
function histogray(img::AbstractMatrix{UInt8})
	edges, counts = 0:255, fill(0, 256)
	Threads.@threads for v in img
		@inbounds counts[v+1] += 1
	end
	return counts, edges
end

# ---------------------------------------------------------------------------------------------------
const pshistogram  = histogram			# Alias
const pshistogram! = histogram!			# Alias