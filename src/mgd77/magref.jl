"""
	magref(cmd0::String="", arg1=nothing; kwargs...)

Evaluate the IGRF or CM4 magnetic field models.

To see the full documentation type: ``@? magref``

### Example
```julia
	G = magref(R=:d, time=2020);
	viz(G, coast=true)
```
"""
magref(cmd0::String; kwargs...) = magref_helper(cmd0, nothing; kwargs...)
magref(arg1; kwargs...)         = magref_helper("", arg1; kwargs...)
magref(; kwargs...)             = magref_helper("", nothing; kwargs...)

function magref_helper(cmd0::String, arg1; kwargs...)::Union{GDtype, GMTgrid, String}
	(cmd0 == "" && arg1 === nothing && length(kwargs) == 0) && return gmt("mgd77magref ")
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	(cmd0 != "") && (arg1 = gmtread(cmd0, data=true))
	isgrid = false
	if (arg1 === nothing && (opts = parse_common_opts(d, "", [:RIr])[1]) != "")
		!contains(opts, "-R") && error("When not providing input locations, need to provide grid limits")
		!contains(opts, "-I") && !region_is_global() && error("For non global grids, must provide grid increments.")
		!contains(opts, "-I") && (opts *= " -I0.25/0.25")		# Default to 0.25 degree increments
		arg1 = gmt("grd2xyz  -o0,1", gmt("grdmath " * opts * " 0"))
		isgrid, d[:isG] = true, true
	end
	isa(arg1, Matrix{<:AbstractFloat}) && (arg1 = mat2ds(arg1))		# Ensure we always send a GMTdataset
	r = magref_helper(arg1, d)
	return (!isgrid || isa(r, String)) ? r : gmt("xyz2grd " * opts, r)
end

# ---------------------------------------------------------------------------------------------------
function magref_helper(arg1::GDtype, d::Dict{Symbol,Any})
	
	cmd = parse_common_opts(d, "", [:V_params :bi :f :hi :o :yx])[1]
	cmd = parse_these_opts(cmd, d, [[:C :cm4file], [:D :dstfile], [:E :f107file]])

	opt_A = add_opt(d, cmd, "A", [:A :input_params], (alt="+a", altitude="+a", time="+t"); expand=true)
	n_cols = getsize(arg1)[2]
	if (opt_A == "")		# Only check if n cols in is == 2. Other cases are just too painfull to test here.
		(n_cols == 2) && (opt_A = " -A+a0+t" * "$(yeardecimal(now()))" * "+y")	# Avisar perigo por causa do 'now()'
	else			# Here we test if the time is a number and add the "+y" ourselves.
		(n_cols == 2 && !contains(opt_A, "+a")) && (opt_A *= "+a0")
		(contains(opt_A, "+t") && tryparse(Float32, split.(split(opt_A, "+t"), '+')[2][1]) !== nothing) && (opt_A *= "+y")
	end
	cmd *= opt_A
	
	cmd = add_opt(d, cmd, "S", [:Sc :core_coef], (low=("c", arg2str, 1), high=("/", arg2str, 2)))
	cmd = add_opt(d, cmd, "S", [:Sl :litho_coef], (low=("l", arg2str, 1), high=("/", arg2str, 2)))
	(find_in_dict(d, [:G :geocentric])[1] !== nothing) && (cmd *= " -G" )
	isgrid = (find_in_dict(d, [:isG])[1] !== nothing)

	# ------- -F ------
	got_F = false				# Will be set to true if user explicitly set -F
	opt_F1 = add_opt(d, "", "F", [:F :internal], (all_input="_r", total="_t", T="_t", horizontal="_h", H="_h", X="_x",
	                              Y="_y", Z="_z", dec="_d", declination="_d", inc="_i", inclination="_i"); del=false, expand=true)
	(length(opt_F1) > 4) && (opt_F1 = "")		# Happens for example when 'F=:CM4litho', which returns " -FCM4litho"
	opt_F2 = add_opt(d, "", "", [:F :internal], (IGRF="_0", CM4core="_1", CM4litho="_2", CM4mag_p="_3",
	                             CM4mag_i="_4", CM4iono_p="_5", CM4iono_i="_6", CM4toroid="_7", IGRG_CM4="_8"); expand=true)
	(opt_F1 == "" && opt_F2 != "") && (opt_F1 = " -Frt")	# Like this we let user to set only the F2 and use a default F1
	if (opt_F1 != "")
		(isgrid && !contains(opt_F1, 'r')) && (opt_F1 = " -Fr" * opt_F1[4])		# The grid case needs 'r' and just one contribution
		(isgrid && length(opt_F2) > 1) && (opt_F2 = string(opt_F2[1]))
		opt_F = (opt_F2 == "") ? opt_F1 * "/0" : opt_F1 * "/" * opt_F2
		got_F = true
	else
		opt_F = isgrid ? " -Frt/0" : " -Frthxyzdi/0"		# The default when no -F
	end
	# -----------------
	
	# ------- -L ------
	got_L = (is_in_dict(d, [:L :external]) !== nothing)
	if (!got_F && got_L)
		opt_L1 = add_opt(d, "", "L", [:L :external], (all_input="_r", total="_t", T="_t", X="_x", Y="_y", Z="_z"); del=false)
		(length(opt_L1) > 4) && (opt_L1 = "")				# Happens for example when 'L=:iono_p', which returns " -Liono_p"
		opt_L2 = add_opt(d, "", "", [:L :external], (mag_i="_1", iono_p="_2", iono_i="_3", poloidal="_4"); expand=true)
		(opt_L1 == "" && opt_L2 != "") && (opt_L1 = " -Lrt")	# Like this we let user to set only the L2 and use a default L1
		if (opt_L1 != "")
			(isgrid && !contains(opt_L1, 'r')) && (opt_L1 = " -Lr" * opt_L1[4])		# The grid case needs 'r' and just one contribution
			(opt_L2 == "") && (opt_L2 = "1")
			cmd *= opt_L1 * "/" * opt_L2
		else
			cmd *= isgrid ? " -Lrt/1" : " -Lrtxyz/1"		# The default when no -L
		end
	else
		(got_F && got_L) && (delete!(d, [:L :external]);
			@warn("Cannot request both 'internal' (F) and 'external' (L) fiels contributions. Ignoring 'external'."))
		cmd *= opt_F
	end
	# -----------------

	(dbg_print_cmd(d, "'magref'") !== nothing) && return cmd
	finish_PS_module(d, "mgd77magref " * cmd, "", true, false, false, arg1)
end

const mgd77magref = magref		# Alias
