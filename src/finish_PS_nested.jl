
# ---------------------------------------------------------------------------------------------------
function finish_PS_nested(d::Dict, cmd::Vector{String})::Vector{String}
	# Finish the PS creating command, but check also if we have any nested module calls like 'coast', 'colorbar', etc
	!has_opt_module(d) && return cmd
	proj_linear_bak = CTRL.proj_linear[1]
	cmd2::Vector{String} = add_opt_module(d)
	CTRL.proj_linear[1]  = proj_linear_bak		# Because add_opt_module may change it (coast does that)
	helper_finish_PS_nested(cmd, cmd2)
end

function helper_finish_PS_nested(cmd::Vector{String}, cmd2::Vector{String})::Vector{String}
	if (!isempty(cmd2) && startswith(cmd2[1], "clip"))	# Deal with the particular psclip case (Tricky)
		opt_R = scan_opt(cmd[1], "-R", true)
		opt_J = scan_opt(cmd[1], "-J", true)
		extra::String = strtok(cmd2[1])[2] * " "		# When psclip recieved extra arguments
		t::String = extra * opt_R * " " * opt_J
		(!contains(cmd2[1], "pscoast")) && (t = "psclip " * t)
		opt_B::String, opt_B1::String = "", ""
		ind = findall(" -B", cmd[1])
		if (!isempty(ind))
			for k = 1:lastindex(ind)
				opt_B *= " " * strtok(cmd[1][ind[k][1]:end])[1]
			end
			# Here we need to reset any -B parts that do NOT include the plotting area and which were clipped.
			if (CTRL.pocket_B[1] == "" && CTRL.pocket_B[2] == "")
				opt_B1 = opt_B * " -R -J"
			else
				(CTRL.pocket_B[1] != "") && (opt_B1 = replace(opt_B,  CTRL.pocket_B[1] => ""))	# grid
				(CTRL.pocket_B[2] != "") && (opt_B1 = replace(opt_B1, CTRL.pocket_B[2] => ""))	# Fill
				(occursin("-Bp ", opt_B1)) && (opt_B1 = replace(opt_B1, "-Bp " => ""))		# Delete stray -Bp 
				opt_B1 = replace(opt_B1, "-B " => "")		#			""
				(endswith(opt_B1, " -B")) && (opt_B1 = opt_B1[1:end-2])
				(opt_B1 != "") && (opt_B1 *= " -R -J")		# When not-empty it needs the -R -J
				CTRL.pocket_B[1] = CTRL.pocket_B[2] = ""	# Empty these guys
			end
		end
		cmd = [t; cmd; cmd2[2:length(cmd2)]; "psclip -C" * opt_B1]
	else
		append!(cmd, cmd2)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function has_opt_module(d::Dict)::Bool
	for symb in CTRL.callable			# Loop over modules list that can be called inside other modules
		haskey(d, symb) && return true
	end
	return false
end
function add_opt_module(d::Dict)::Vector{String}
	#  SYMBS should contain a module name (e.g. 'coast' or 'colorbar'), and if present in D,
	# 'val' can be a NamedTuple with the module's arguments or a 'true'.
	out = Vector{String}()
	n_inset = 0							# To count "inset" calls

	for symb in CTRL.callable			# Loop over modules list that can be called inside other modules
		!(haskey(d, symb)) && continue
		r::Union{String, Vector{String}} = ""
		val = d[symb]
		isa(val, AbstractDict) && (val = Base.invokelatest(dict2nt, val))
		if (symb == :inset)				# The inset case must come first because it is a special case
			n_inset += 1
			inset_nested(isa(val, Matrix{<:Real}) ? mat2ds(val) : val, n_inset)
			r = "inset_$(n_inset)"
		elseif (isa(val, NamedTuple))
			r = add_opt_module_barr1(val, symb)
		elseif (isa(val, Real) && (val != 0))			# Allow setting coast=true || colorbar=true
			r = add_opt_module_barr2(symb)
		elseif (symb == :colorbar && (isa(val, StrSymb)))
			# Accepts generic psscale opts string or limitted: Top/TopTri[High|Low], Bottom/BottomTri, Left/LeftTri, Right/RightTri or triangles (caseless)
			opt_RJ = !IamModern[] ? CTRL.pocket_R[1] * " -J" : ""
			s_val::String = string(val)							# Shoot the Any
			if (isa(val, String) && (!contains(s_val, "tri") && !(lowercase(s_val[1]) in ('t', 'b', 'l')))) # tbl cases are dealt in colorbar_triangles() 
				!contains(s_val, " -B") && (s_val *= " -Baf")	# Add default -B if not present
				(lowercase(s_val[1]) in ('j', 'j', 'n', 'x')) && (s_val = " -D" * s_val)
				r = "psscale $opt_RJ -C " * s_val
			else
				anc_tris = colorbar_triangles(val)
				r = "psscale $opt_RJ -Baf -C -DJ"  * anc_tris
			end
		elseif (symb == :clip)
			if (isa(val, String) || isa(val, Symbol))	# Accept also "land", "water" or "ocean" or DCW country codes(s) or a hard -E string
				_str::String = string(val)				# Shoot the Any
				if     (_str == "land")                     r = "clip pscoast -Gc"
				elseif (_str == "water" || _str == "ocean") r = "clip pscoast -Sc"
				elseif (length(_str) == 2 || _str[1] == '=' || contains(_str, ',') || contains(_str, "+f"))
					r = (_str[1] == '-') ? "clip pscoast " * _str : "clip pscoast -E" * _str * "+c"	# Accept also clip="-E..."
				else   @error("Invalid string for clip option: $_str")
				end
			else
				(pocket_call[][1] === nothing) ? (pocket_call[][1] = val) : (pocket_call[][2] = val)
				r = "clip"
			end
		elseif (symb == :grdcontour)
			(pocket_call[][1] === nothing) ? (pocket_call[][1] = val) : (pocket_call[][2] = val)
			r = "grdcontour -J -R"
		end
		delete!(d, symb)

		(isa(r, Vector) && !isempty(r)) && append!(out, r)
		(isa(r, String) && (r != "")) && append!(out, [r])
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
colorbar_triangles(val::StrSymb)::String = colorbar_triangles(lowercase(string(val)))
function colorbar_triangles(val_str::String)::String
	# Accepts Top/TopTri[High|Low], Bottom/BottomTri, Left/LeftTri, Right/RightTri or triangles (caseless)
	anc = "RM";		tris = ""		# Default anchor Right Middle and no triangles
	if (contains(val_str, "tri") && !isempty(CURRENT_CPT[]))	# Sets CPT.bfn to match colormap end colors
		if (CURRENT_CPT[].bfn[1,:] == [0.0, 0.0, 0.0] && CURRENT_CPT[].bfn[1,:] == [1.0, 1.0, 1.0])
			# If bfn is not set, set it to the end colors of the colormap
			CURRENT_CPT[].bfn[1,:] .= CURRENT_CPT[].colormap[1,:]
			CURRENT_CPT[].bfn[2,:] .= CURRENT_CPT[].colormap[end,:]
			tris = contains(val_str, "high") ? "+ef" : contains(val_str, "low") ? "+eb" : "+e"
		end
	end
	if (!startswith(val_str, "tri"))			# Means that not just triangles were requested
		t::Char = val_str[1]					# Accept "Top, Bot, Left" but default to Right
		anc = (t == 't') ? "TC" : (t == 'b' ? "BC" : (t == 'l' ? "LM" : "RM"))
	end
	return anc * tris
end

# Add to split code from above in these 2 function barriers to avoid all finish_PS_nested() invalidations
function add_opt_module_barr2(symb::Symbol)::Union{String, Vector{String}}
	r::Union{String, Vector{String}} = ""
	#if     (symb == :coast)    r = coast_parser(false, "", W=0.5, A="200/0/2", Vd=2)[1]		# coast!(W=0.5, A="200/0/2", Vd=2)
	#elseif (symb == :colorbar) r = colorbar_parser(pos=(anchor="RM",), B="af", first=false, Vd=2)[1]
	opt_RJ = !IamModern[] ? "-R -J" : ""
	if     (symb == :coast)    r = "pscoast $opt_RJ -A200/0/2 -W0.5 -Da"		# coast!(W=0.5, A="200/0/2", Vd=2)
	elseif (symb == :colorbar) r = "psscale $opt_RJ -Baf -DJRM -C"
	elseif (symb == :logo)     r = "gmtlogo -Dx0/0+w5c $opt_RJ"; 	# logo!(Vd=2)
	end
	(r !== "" && CTRL.pocket_R[1] !== "") && (r = replace(r, "-R" => CTRL.pocket_R[1]))
	return r
end

function add_opt_module_barr1(nt::NamedTuple, symb::Symbol)::Union{String, Vector{String}}
	r::Union{String, Vector{String}} = ""
	if     (symb == :coast)     r = coast!(; Vd=2, nt...)
	elseif (symb == :basemap)   r = basemap!(; Vd=2, nt...)
	elseif (symb == :grdcontour) r = grdcontour!(; Vd=2, nt...)		# Not working
	elseif (symb == :logo)      r = logo!(; Vd=2, nt...)
	elseif (symb == :colorbar)
		r = colorbar!(; Vd=2, nt...)
		!contains(r, " -B") && (r = replace(r, "psscale" => "psscale -Baf"))		# Add -B if not present
	elseif (symb == :clip)		# Need lots of little shits to parse the clip options
		if ((isa(nt, NamedTuple) && (isa(nt[1], String) || isa(nt[1], Symbol))) || isa(nt[1], NamedTuple))
			r = (isa(nt, NamedTuple)) ? coast!(; Vd=2, E=nt) : coast!(; Vd=2, nt...)
			opt_E = scan_opt(r, "-E")	# We are clipping so opt_E must contain eith +c or +C. If not, add +c
			startswith(opt_E, "=land")  && (r = replace(r, " -E"*opt_E => " -Gc"))	# Stupid user mistakes. Try to recover
			startswith(opt_E, "=ocean") && (r = replace(r, " -E"*opt_E => " -Sc"))
			(!contains(opt_E, "+c") && !contains(opt_E, "+C")) && (r = replace(r, opt_E => opt_E * "+c"))
			is_coast = true
		else
			(pocket_call[][1] === nothing) ? (pocket_call[][1] = nt[1]) : (pocket_call[][2] = nt[1])
			k,v = keys(nt), values(nt)
			nt = NamedTuple{Tuple(Symbol.(k[2:end]))}(v[2:end])		# Fck, what a craziness to remove 1 el from a nt
			r = clip!(""; Vd=2, nt...)
			is_coast = false
		end
		((ff = findfirst(" -K", r)) !== nothing) && (r = r[1:ff[1]])	# Remove the "-K -O >> ..."
		opt_R = scan_opt(r, "-R", true)
		r = replace(r, opt_R * " -J" => "")	# Mus fish -R first because now all -R are complete (not just -R)
		r = (is_coast) ? "clip " * r : "clip " * strtok(r)[2]	# coast case returns a "clip pscoast ..." string that caller can parse 
	else
		!(symb in CTRL.callable) && error("Nested Fun call $symb not in the callable nested functions list")
		_d::Dict{Symbol, Any} = nt2dict(nt)
		ind_pocket = (pocket_call[][1] === nothing) ? 1 : 2
		(haskey(_d, :data)) && (pocket_call[][ind_pocket] = _d[:data]; delete!(_d, :data))
		this_symb = CTRL.callable[findfirst(symb .== CTRL.callable)]
		fn::Function = getfield(GMTmodule[], Symbol(string(this_symb, "!")))	# GMT = getfield(Main, nameof(@__MODULE__))
		if (this_symb in [:vband, :hband, :vspan, :hspan])
			r = fn(pocket_call[][ind_pocket]; nested=true, Vd=2, nt...)
		else
			r = fn(; Vd=2, nt...)
		end
	end
	return r
end
