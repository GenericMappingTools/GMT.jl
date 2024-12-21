"""
    binstats(cmd0::String="", arg1=nothing; kwargs...)

Reads arbitrarily located (x,y[,z][,w]) points (2-4 columns) and for each node in the specified grid layout
determines which points are within the given radius. These point are then used in the calculation of the
specified statistic. The results may be presented as is or may be normalized by the circle area to perhaps
give density estimates. Alternatively, select hexagonal tiling instead or a rectangular grid layout.
	
Parameters
----------

- **C** | **stats** | **statistic** :: [Type => String | NamedTuple]

    Choose the statistic that will be computed per node based on the points that are within radius distance of the node.
- $(opt_I)
- **E** | **empty** :: [Type => Number]

    Set the value assigned to empty nodes [NaN].
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = gmtbinstats(....) form.
- **N** | **normalize** :: [Type => Bool]

    Normalize the resulting grid values by the area represented by the `search_radius`.
- **S** | **search_radius** :: [Type => Number]

    Sets the search_radius that determines which data points are considered close to a node. Not compatible with `tiling`
- $(_opt_R)
- **T** | **tiling** | **bins** :: [Type => String | NamedTuple]

    Instead of circular, possibly overlapping areas, select non-overlapping tiling. Choose between
    rectangular hexagonal binning.
- $(opt_V)
- **W** | **weights** :: [Type => Bool | String]

    Input data have a 4th column containing observation point weights.

To see the full documentation type: ``@? gmtbinstats``
"""
function binstats(fname::String; nbins=0, kwargs...)
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	arg1 = read_data(d, fname, "", nothing, " ", false, true)[2]	# Make sure we have the data here
	binstats_helper(arg1, nbins, d)
end

function binstats(arg1; nbins=0, kwargs...)
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
    binstats_helper(mat2ds(arg1), nbins, d)
end

function binstats_helper(data::GDtype, nbins::Int, d::Dict{Symbol,Any})

	isa(data, Vector{<:GMTdataset}) && isempty(data[1].ds_bbox) && set_dsBB!(data)

	cmd, = parse_common_opts(d, "", [:G :I :R :V_params :a :bi :di :e :f :g :h :i :q :r :w :yx])
	cmd  = parse_these_opts(cmd, d, [[:E :empty], [:N :normalize], [:S :search_radius], [:W :weights]])
	if ((val = find_in_dict(d, [:C :stats :statistic])[1]) !== nothing)
		s::String = string(val)
		if     (s == "average" || s == "mean")          cmd *= " -Ca"
		elseif (s == "mad")                             cmd *= " -Cd"
		elseif (s == "range")                           cmd *= " -Cg"
		elseif (s == "iq"      || s == "interquartil")  cmd *= " -Ci"
		elseif (s == "min_pos" || s == "minimum_pos")   cmd *= " -CL"
		elseif (s == "min"     || s == "minimum")       cmd *= " -Cl"
		elseif (s == "median")                          cmd *= " -Cm"
		elseif (s == "number"  || s == "count")         cmd *= " -Cn"
		elseif (s == "LMS")      cmd *= " -Co"
		elseif (s == "mode")     cmd *= " -Cp"
		elseif (s == "rms")      cmd *= " -Cr"
		elseif (s == "std")      cmd *= " -Cs"
		elseif (s == "max"     || s == "maximum")       cmd *= " -Cu"
		elseif (s == "max_neg" || s == "maximum_neg")   cmd *= " -CU"
		elseif (s == "sum")      cmd *= " -Cz"
		elseif (startswith(s, "quantil"))  cmd *= " -Cq"
			(length(s) > 7) && (cmd *= s[8:end])		# In case a stats="quantil75" was transmitted.
		elseif (length(s) == 1)  cmd *= " -C" * s		# When a C=:a was used
		elseif (s[1] == 'q' && isdigit(s[2]))  cmd *= " -C" * s
		else
			error("Bad argument for the 'tile' option ($(s))")
		end
	end
	if ((val = find_in_dict(d, [:T :tiling :bins])[1]) !== nothing)
		t::Char = string(val)[1]
		cmd = (t == 'r') ? cmd * " -Tr" : (t == 'h' ? cmd * " -Th" : error("Bad method for option 'tiling'")) 
	end

	mima = isa(data, Vector{<:GMTdataset}) ? data[1].ds_bbox[1:4] : data.ds_bbox[1:4]
	#mima = round_wesn(data.ds_bbox[1:4])
	if (contains(cmd, " -Th"))
		if (!contains(cmd, " -I"))
			nb = 50
			if (nbins == 0 && CTRL.figsize[1] != 0)
				nb = (CTRL.figsize[1] <= 7) ? 30 : (CTRL.figsize[1] <= 10) ? 45 : 60
			end
			inc = (mima[2] - mima[1]) / nb
			cmd *= @sprintf(" -I%.8g", inc)
		else
			inc = parse(Float64, scan_opt(cmd, "-I"))
		end
		mima[4] = mima[3] + ceil((mima[4] - mima[3]) / inc) * inc	# To avoid the annoying warning.
	end
	(!contains(cmd, " -R")) && (cmd *= @sprintf(" -R%.10g/%.10g/%.10g/%.10g", mima...))
	val = find_in_dict(d, [:threshold])[1]

	R = common_grd(d, "", cmd, "gmtbinstats ", data)		# Finish build cmd and run it
	if (isa(R, GMTdataset) && (val !== nothing))
		th::Float64 = val		# Don't use the bloody Anys in next comparison.
		#R.data = R[(view(R.data,:,3) .>= th), :]
		R.data = R[(Base.invokelatest(view,R.data,:,3) .>= th), :]
		set_dsBB!(R)		# Need to update BBs
	end
	if (!isempty(R) && !isa(R, String) && occursin(" -Th", cmd))
		opt_I = scan_opt(cmd, "-I")			# CHECK IF inc HAS UNITS?
		R.attrib = Dict("hexbin" => opt_I)
	end
	R
end

# ---------------------------------------------------------------------------------------------------
const gmtbinstats = binstats			# Alias