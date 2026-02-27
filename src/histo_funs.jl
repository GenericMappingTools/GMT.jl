function find_histo_limits(In, thresholds=nothing, width=20, hst::Matrix{Float64}=Matrix{Float64}(undef,0,2))
	 _find_histo_limits(In, thresholds === nothing ? () : thresholds, Float64(width), hst)
end
function _find_histo_limits(@nospecialize(In), thresholds::Tuple, width::Float64, hst_::Matrix{Float64})
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
function hst_floats(arg1, opt_T::String=""; min_max=(0.0, 0.0))
	# Compute the histogram of a grid or matrix
	# Made a separate function to let it be called from rescale() and thus avoid calling the main histogram()
	# that seems to be be too havy (at least according to JET)
	_min_max::Tuple{Float64,Float64} = (isa(arg1, GMTgrid)) ?
	                                   (arg1.range[5], arg1.range[6]) : (min_max != (0.0, 0.0) ? min_max : Float64.(extrema_nan(arg1))) 
	if (opt_T != "")
		inc = parse(Float64, opt_T) + eps()		# + EPS to avoid the extra last bin at right with 1 count only
		n_bins = Int(ceil((_min_max[2] - _min_max[1]) / inc))
	else
		n_bins = Int(ceil(sqrt(length(arg1))))
		reg = isa(arg1, GMTgrid) ? (1 - arg1.registration) : 1	# When called from RemoteS arg1 is a view of a layer.
		inc = (_min_max[2] - _min_max[1]) / (n_bins - reg) + eps()
	end
	(!isa(inc, Real) || inc <= 0) && error("Bin width must be a > 0 number and no min/max")
	hst = zeros(n_bins, 2)
	have_nans = false
	if (eltype(arg1) <: AbstractFloat)		# Float arrays can have NaNs
		have_nans = !(isa(arg1, GMTgrid) && arg1.hasnans == 1)
		have_nans && (have_nans = any(!isfinite, arg1))
	end

	_inc = inc + 10eps()					# To avoid cases when index computing fall of by 1
	if (have_nans)							# If we have NaNs in the grid, we need to take a slower branch
		@inbounds for k = 1:numel(arg1)
			!isnan(arg1[k]) && (hst[Int(floor((arg1[k] - _min_max[1]) / _inc) + 1), 2] += 1)
		end
	else
		@inbounds for k = 1:numel(arg1)  hst[Int(floor((arg1[k] - _min_max[1]) / _inc) + 1), 2] += 1  end
	end
	@inbounds for k = 1:n_bins  hst[k,1] = _min_max[1] + inc * (k - 1)  end
	return hst, inc, _min_max
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
