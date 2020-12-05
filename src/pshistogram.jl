"""
	histogram(cmd0::String="", arg1=nothing; kwargs...)

Examines the first data column to calculate histogram parameters based on the bin-width provided.
Alternatively, show histograms of GMTimage & GMTgrid objects directly. In the GMTimage case, the
options 'auto=true' or 'thresholds=(0, 0.1)' will find the histogram bounds of UInt16 images
convenient for contrast enhancement (histogram stretch). The values represent the percentage of
countings used to estimate the boundings. The option 'zoom=true' will set 'auto=true' and show
histogram only on the region of interest.

Full option list at [`pshistogram`]($(GMTdoc)histogram.html)

Parameters
----------

- $(GMT.opt_J)
- **A** | **horizontal** :: [Type => Bool]

    Plot the histogram horizontally from x = 0 [Default is vertically from y = 0].
    ($(GMTdoc)histogram.html#a)
- $(GMT.opt_B)
- **C** | **color** | **cmap** :: [Type => Str | GMTcpt]

    Give a CPT. The mid x-value for each bar is used to look-up the bar color.
    ($(GMTdoc)histogram.html#c)
- **D** | **annot** | **annotate** | **counts** :: [Type => Str | Tuple]

    Annotate each bar with the count it represents.
    ($(GMTdoc)histogram.html#d)
- **E** | **width** :: [Type => Bool]			`Arg = width[+ooffset]`

    Use an alternative histogram bar width than the default set via T, and optionally shift all bars by an offset.
    ($(GMTdoc)histogram.html#e)
- **F** | **center** :: [Type => Bool]

    Center bin on each value. [Default is left edge].
    ($(GMTdoc)histogram.html#f)
- **G** | **fill** :: [Type => Number | Str]

    Select filling of bars [if no G, L or C set G=100].
    ($(GMTdoc)histogram.html#g)
- **I** | **inquire** | **bins** :: [Type => Bool | :O | :o | bins=(all=true,) | bins=(no_zero=true,) ]

    Inquire about min/max x and y after binning OR output the binned array.
    ($(GMTdoc)histogram.html#i)
- **L** | **out_range** :: [Type => Str]			`Arg = l|h|b`

    Handling of extreme values that fall outside the range set by **T**.
    ($(GMTdoc)histogram.html#l)
- **N** | **distribution** :: [Type => Str]

    Draw the equivalent normal distribution; append desired pen [0.5p,black].
    ($(GMTdoc)histogram.html#n)
- $(GMT.opt_P)
- **Q** | **cumulative** :: [Type => Bool | "r"]

    Draw a cumulative histogram. Append r to instead compute the reverse cumulative histogram.
    ($(GMTdoc)histogram.html#q)
- **R** | **region** :: [Type => Str]

    Specifies the ‘region’ of interest in (r,azimuth) space. r0 is 0, r1 is max length in units.
    ($(GMTdoc)histogram.html#r)
- **S** | **stairs** :: [Type => Str | number]

    Draws a stairs-step diagram which does not include the internal bars of the default histogram.
    ($(GMTdoc)histogram.html#s)
- **T** | **range** | **bin** :: [Type => Str]			`Arg = [min/max/]inc[+n] | file|list]`

    Defines the range of the new CPT by giving the lowest and highest z-value and interval.
    ($(GMTdoc)histogram.html#t)
- **W** | **pen** :: [Type => Str | Tuple]

	Set pen attributes for sector outline or rose plot. [Default is no outline].
	($(GMTdoc)histogram.html#w)
- **Z** | **kind** :: [Type => Number | Str]

    Choose between 6 types of histograms.
    ($(GMTdoc)histogram.html#z)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_p)
- $(GMT.opt_t)
- $(GMT.opt_swap_xy)
"""
function histogram(cmd0::String="", arg1=nothing; first=true, kwargs...)

	arg2 = nothing		# May be needed if GMTcpt type is sent in via C
	N_args = (arg1 === nothing) ? 0 : 1

	gmt_proggy = (IamModern[1]) ? "histogram "  : "pshistogram "
	length(kwargs) == 0 && return monolitic(gmt_proggy, cmd0, arg1, arg2)

	d = KW(kwargs)
	help_show_options(d)		# Check if user wants ONLY the HELP mode

	cmd = ""
	opt_Z = add_opt(d, "", 'Z', [:Z :kind], (counts = "0", count = "0", freq = "1", log_count = "2", log_freq = "3",
	                                         log10_count = "4", log10_freq = "5", weights = "+w"), true, "")
	opt_T = parse_opt_range(d, "", "")		# [:T :range :inc :bin]
	(isa(arg1, GMTimage) || isa(arg1, GMTgrid)) && occursin("/", opt_T) && error("here 'inc' must be a scalar")

	# If inquire, no plotting so do it and return
	opt_I = add_opt(d, "", "I", [:I :inquire :bins], (all = "O", no_zero = "o"))
	if (opt_I != "")
		cmd *= opt_I
		if ((r = dbg_print_cmd(d, cmd)) !== nothing)  return r  end
		cmd, arg1, = read_data(d, cmd0, cmd, arg1, " ")
		if (isa(arg1, GMTimage))		# If it's an image with no bin option, default to bin=1
			arg1, cmd = loc_histo(arg1, cmd, opt_T, opt_Z)
		else
			cmd *= opt_Z
			if (opt_T != "")  cmd *= " -T" * opt_T  end
		end
		return gmt(gmt_proggy * cmd, arg1)
	end

	K, O = set_KO(first)		# Set the K O dance

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd, "histogram", O, " -JX12c/12c")
	cmd = parse_common_opts(d, cmd, [:UVXY :JZ :c :e :p :t :params], first)[1]
	cmd = parse_these_opts(cmd, d, [[:A :horizontal], [:F :center], [:Q :cumulative], [:S :stairs]])
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd = add_opt(d, cmd, 'D', [:D :annot :annotate :counts], (beneath = "_+b", font = "+f", offset = "+o", vertical = "_+r"))
	cmd = parse_INW_coast(d, [[:N :distribution :normal]], cmd, "N")
	(show_kwargs[1]) && print_kwarg_opts(symbs, "NamedTuple | Tuple | Dict | String")
	(isa(arg1, GMTimage) || isa(arg1, GMTgrid)) && occursin("/", opt_T) && error("here 'inc' must be a scalar")

	if (GMTver >= v"6.2")  cmd = add_opt(d, cmd, 'E', [:E :width], (width = "", off = "+o", offset = "+o"))  end

	# If file name sent in, read it and compute a tight -R if this was not provided
	if (opt_R == "")  opt_R = " "  end			# So it doesn't try to find the -R in next call
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_args, arg1, arg2)

	cmd  = add_opt(d, cmd, 'L', [:L :out_range], (first = "l", last = "h", both = "b"))
	cmd *= add_opt_pen(d, [:W :pen], "W", true)     	# TRUE to also seek (lw|lt,lc,ls)
	if (!occursin("-G", cmd) && !occursin("-C", cmd) && !occursin("-S", cmd))
		cmd *= " -G150"
    	elseif (occursin("-S", cmd) && !occursin("-W", cmd))
		cmd *= " -W0.3p"
	end

	limit_L = nothing
	if (isa(arg1, GMTimage))		# If it's an image with no bin option, default to bin=1
		do_clip = (isa(arg1[1], UInt16) && (val = find_in_dict(d, [:full_histo])[1]) === nothing) ? true : false
		do_auto = ((val_auto = find_in_dict(d, [:auto :threshols])[1]) !== nothing) ? true : false	# Automatic bounds detetion
		do_zoom = ((find_in_dict(d, [:zoom])[1]) !== nothing) ? true : false	# Automatic zoom to interesting region
		if (do_zoom && !do_auto)  val_auto = nothing  end	# I.e. 'zoom' sets also the auto mode
		hst, cmd = loc_histo(arg1, cmd, opt_T, opt_Z)
		if (do_clip && (all(hst[3:10,2] .== 0)))  hst[1,2] = 0; hst[2,2] = 0  end
		if (do_auto || do_zoom)
			limit_L, limit_R = find_histo_limits(arg1, val_auto, 200)
			if (do_zoom)
				mm = extrema(hst, dims=1)		# 1×2 Array{Tuple{UInt16,UInt16},2}
				x_max = min(limit_R * 1.15, hst[end,1])		# 15% to the right but not fall the cliff
				opt_R_ = " -R$(limit_L * 0.85)/$x_max/0/$(mm[2][2] * 1.1) "
				(opt_R != " ") && @warn("'zoom' option overrides the requested region limits and sets its own")
				cmd = replace(cmd, opt_R => opt_R_, count=1)
				opt_R = opt_R_					# It will be needed further down in vlines
			end
		end
		arg1 = hst		# We want to send the histogram, not the GMTimage
    	elseif (isa(arg1, GMTgrid))
		if (opt_T != "")
			inc = parse(Float64, opt_T) + eps()		# + EPS to avoid the extra last bin at right with 1 count only
			n_bins = Int(ceil((arg1.range[6] - arg1.range[5]) / inc))
		else
			n_bins = Int(ceil(sqrt(length(arg1.z))))
			inc = (arg1.range[6] - arg1.range[5]) / n_bins + eps()
		end
		(!isa(inc, Real) || inc <= 0) && error("Bin width must be a > 0 number and no min/max")
		hst = zeros(n_bins, 2)
		@inbounds for k = 1:length(arg1)  hst[Int(floor((arg1[k] - arg1.range[5]) / inc) + 1), 2] += 1  end
		[@inbounds hst[k,1] = arg1.range[5] + inc * (k - 1) for k = 1:n_bins]

		cmd = (opt_Z == "") ? cmd * " -Z0" : cmd * opt_Z
		if (!occursin("+w", cmd))  cmd *= "+w"  end		# Pretending to be weighted is crutial for the trick
		cmd *= " -T$(arg1.range[5])/$(arg1.range[6])/$inc"
		arg1 = hst		# We want to send the histogram, not the GMTgrid
    	else
		if (opt_T != "")  opt_T = " -T" * opt_T  end	# It lacked the -T so that it could be used in loc_histo()
		cmd *= opt_T * opt_Z
	end

	# The following looks a bit messy but it's needed to auto plotting verical lines with the limits
	show_ = false;		fmt_ = "ps";		savefig_ = nothing
	if (limit_L !== nothing)
		if (haskey(d, :show))  show_ = (d[:show] != 0)  end				# Backup the :show val
		d[:show] = false
		if (haskey(d, :fmt))  fmt_ = d[:fmt]; delete!(d, :fmt)  end		# Backup the :show val
		if ((val = find_in_dict(d, [:savefig :figname :name])[1]) !== nothing) savefig_ = val  end
	end

	out2 = nothing;		Vd_ = 0				# Backup values
	if (haskey(d, :Vd))  Vd_ = d[:Vd]  end
	
	# Plot the histogram
	out1 = finish_PS_module(d, gmt_proggy * cmd, "", K, O, true, arg1, arg2)

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
function find_histo_limits(In, thresholds=nothing, width=200)
	# Find the histogram limits of a UInt16 GMTimage that allow to better stretch the histogram
	# THRESHOLDS is an optional Tuple input containing the left and right thresholds, in percentage,
	# between which the histogram values will be retained. Defaults are (0,0.5) percent
	# WIDTH is bin width used to obtain a rough histogram that is used to compute the limits.
	if (isa(In, Array{UInt16,3}) || isa(In, Array{UInt8,3}))
		L1 = find_histo_limits(view(In, :, :, 1), thresholds, width)
		L2 = find_histo_limits(view(In, :, :, 2), thresholds, width)
		L3 = find_histo_limits(view(In, :, :, 3), thresholds, width)
		return (L1[1], L1[2], L2[1], L2[2], L3[1], L3[2])
	end
	hst = loc_histo(In, "", string(width), "")[1]
	if (size(hst, 1) >= 5)
		all(hst[2:5,2] .== 0) && (hst[1,2] = 0)	# Here we always check for high counts in zero bin
	end
	max_ = maximum(hst, dims=1)[2]
	(max_ == 0) && error("This histogram had nothing but countings ONLY in first bin. No point to proceed.")
	thresh_l = 0.0;		thresh_r = 0.005
	if (isa(thresholds, Tuple) && length(thresholds) == 2)
		thresh_l, thresh_r = thresholds[:] ./ 100
	end
	thresh_l *= max_
	thresh_r *= max_
	kl = 1;		kr = size(hst, 1)
	while (hst[kl,2] == 0 || hst[kl,2] < thresh_l)  kl += 1  end
	while (hst[kr,2] == 0 || hst[kr,2] < thresh_r)  kr -= 1  end
	return Int(hst[kl,1]), Int(min(hst[kr,1] + width, hst[end,1]))
end

# ---------------------------------------------------------------------------------------------------
function loc_histo(in, cmd::String="", opt_T::String="", opt_Z::String="")
	# Very simple function to compute histograms of images (integers)
	# We put the countings in a Mx2 arrray to trick GMT (pshistogram) to think it's recieving a weighted input.
	(!isa(in[1], UInt16) && !isa(in[1], UInt8)) && error("Only UInt8 or UInt16 image types allowed here")

	inc = (opt_T != "") ? Float64(Meta.parse(opt_T)) : 1.0
	(!isa(inc, Real) || inc <= 0) && error("Bin width must be a > 0 number and no min/max")

	n_bins = (isa(in[1], UInt8)) ? 256 : Int(ceil((maximum(in) + 1) / inc))	# For UInt8 use the full [0 255] range
	hst = zeros(n_bins, 2)
	pshst_wall!(in, hst, inc, n_bins)

	cmd = (opt_Z == "") ? cmd * " -Z0" : cmd * opt_Z
	if (!occursin("+w", cmd))  cmd *= "+w"  end		# Pretending to be weighted is crutial for the trick

	return hst, cmd * " -T0/$(n_bins * inc)/$inc"
end

function pshst_wall!(in, hst, inc, n_bins::Int)
	# Function barrier for type instability. With the body of this in calling fun the 'inc' var
	# introduces a mysterious type instability and execution times multiply by 3.
	if (inc == 1)
		@inbounds for k = 1:length(in)  hst[in[k] + 1, 2] += 1  end
    	else
		@inbounds for k = 1:length(in)  hst[Int(floor(in[k] / inc) + 1), 2] += 1  end
	end
	[@inbounds hst[k,1] = inc * (k - 1) for k = 1:n_bins]
	return nothing
end

# ---------------------------------------------------------------------------------------------------
histogram!(cmd0::String="", arg1=nothing; kw...) = histogram(cmd0, arg1; first=false, kw...)
histogram(arg1; kw...)  = histogram("", arg1; first=true, kw...)
histogram!(arg1; kw...) = histogram("", arg1; first=false, kw...)

const pshistogram  = histogram			# Alias
const pshistogram! = histogram!			# Alias