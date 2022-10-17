"""
    binstats(cmd0::String="", arg1=nothing; kwargs...)

Reads arbitrarily located (x,y[,z][,w]) points (2-4 columns) and for each node in the specified grid layout
determines which points are within the given radius. These point are then used in the calculation of the
specified statistic. The results may be presented as is or may be normalized by the circle area to perhaps
give density estimates. Alternatively, select hexagonal tiling instead or a rectangular grid layout.
	
Full option list at [`gmtbinstats`]($(GMTdoc)gmtbinstats.html)

Parameters
----------

- **C** | **stats** | **statistic** :: [Type => String | NamedTuple]

    Choose the statistic that will be computed per node based on the points that are within radius distance of the node.
    ($(GMTdoc)gmtbinstats.html#c)
- $(GMT.opt_I)
    ($(GMTdoc)gmtbinstats.html#i)
- **E** | **empty** :: [Type => Number]

    Set the value assigned to empty nodes [NaN].
    ($(GMTdoc)gmtbinstats.html#e)
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = gmtbinstats(....) form.
    ($(GMTdoc)gmtbinstats.html#g)
- **N** | **normalize** :: [Type => Bool]

    Normalize the resulting grid values by the area represented by the `search_radius`.
    ($(GMTdoc)gmtbinstats.html#n)
- **S** | **search_radius** :: [Type => Number]

    Sets the search_radius that determines which data points are considered close to a node. Not compatible with `tiling`
    ($(GMTdoc)gmtbinstats.html#s)
- $(GMT._opt_R)
- **T** | **tiling** | **bins** :: [Type => String | NamedTuple]

    Instead of circular, possibly overlapping areas, select non-overlapping tiling. Choose between
    rectangular hexagonal binning.
    ($(GMTdoc)gmtbinstats.html#t)
- $(GMT.opt_V)
- **W** | **weights** :: [Type => Bool | String]

    Input data have a 4th column containing observation point weights.
    ($(GMTdoc)gmtbinstats.html#w)
- $(GMT.opt_a)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_q)
- $(GMT.opt_r)
- $(GMT.opt_w)
- $(GMT.opt_swap_xy)
"""
function binstats(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:G :RIr :V_params :a :bi :di :e :f :g :h :i :q :w :yx])
	cmd  = parse_these_opts(cmd, d, [[:E :empty], [:N :normalize], [:S :search_radius], [:W :weights]])
	if ((val = find_in_dict(d, [:C :stats :statistic])[1]) !== nothing)
		s::String = string(val)
		if     (s == "average")  cmd *= " -Ca"
		elseif (s == "mad")      cmd *= " -Cd"
		elseif (s == "range")    cmd *= " -Cg"
		elseif (s == "interquartil")  cmd *= " -Ci"
		elseif (s == "minimum_pos")   cmd *= " -CL"
		elseif (s == "minimum")  cmd *= " -Cl"
		elseif (s == "median")   cmd *= " -Cm"
		elseif (s == "number")   cmd *= " -Cn"
		elseif (s == "LMS")      cmd *= " -Co"
		elseif (s == "mode")     cmd *= " -Cp"
		elseif (s == "rms")      cmd *= " -Cr"
		elseif (s == "std")      cmd *= " -Cs"
		elseif (s == "maximum")  cmd *= " -Cu"
		elseif (s == "maximum_neg") cmd *= " -CU"
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

	R = common_grd(d, cmd0, cmd, "gmtbinstats ", arg1)		# Finish build cmd and run it
	if (!isempty(R) && !isa(R, String) && occursin(" -Th", cmd))
		opt_I = scan_opt(cmd, "-I")			# CHECK IF inc HAS UNITS?
		R.attrib = Dict("hexbin" => opt_I)
	end
	R
end

# ---------------------------------------------------------------------------------------------------
binstats(arg1; kw...) = binstats("", arg1; kw...)

const gmtbinstats = binstats			# Alias