# Parse the common options that all GMT modules share, plus some others functions of also common usage

const KW = Dict{Symbol,Any}
nt2dict(nt::NamedTuple) = nt2dict(; nt...)
nt2dict(; kw...) = Dict(kw)
# Need the Symbol.() below in oder to work from PyCall
# A darker an probably more efficient way is: ((; kw...) -> kw.data)(; d...) but breaks in PyCall
dict2nt(d::Dict)::NamedTuple = NamedTuple{Tuple(Symbol.(keys(d)))}(values(d))

function find_in_dict(d::Dict, symbs::VMs, del::Bool=true, help_str::String="")
	# See if D contains any of the symbols in SYMBS. If yes, return corresponding value
	(SHOW_KWARGS[1] && help_str != "") && return (print_kwarg_opts(symbs, help_str), Symbol())
	for symb in symbs
		if (haskey(d, symb))
			val = d[symb]				# SHIT is that 'val' is always a ANY
			(del) && delete!(d, symb)
			return val, Symbol(symb)
		end
	end
	return nothing, Symbol()
end

"""
    delete!(d::Dict, symbs::Vector{T}) where T

## example
delete!(d, [:a :b])
delete!(d, [:a, :b])
delete!(d, [[:a, :b], [:c]])
delete!(d, [[:a :b] [:c]])
"""
function Base.delete!(d::Dict, symbs::Array{T, N}) where {T, N}
    for symb in symbs
        delete!(d, symb)
    end
    return d
end

function find_in_kwargs(p, symbs::VMs, del::Bool=true, primo::Bool=true, help_str::String="")
	# See if P contains any of the symbols in SYMBS. If yes, return corresponding value
	(SHOW_KWARGS[1] && help_str != "") && return (print_kwarg_opts(symbs, help_str), Symbol())
	_k = keys(p)
	for symb in symbs
		if ((ind = findfirst(_k .== symb)) !== nothing)
			val = p[_k[ind]]
			#(del) && consume(_k, symb, primo)
			return val, symb
		end
	end
	return nothing, Symbol()
end

function is_in_dict(d::Dict, symbs::VMs, help_str::String=""; del::Bool=false)
	# See if D contains any of the symbols in SYMBS. If yes, return the used smb in symbs
	(SHOW_KWARGS[1] && help_str != "") && return print_kwarg_opts(symbs, help_str)
	for symb in symbs
		if (haskey(d, symb))
			del && delete!(d, symb)
			return symb
		end
	end
	return nothing
end

#=
function consume(ops::Tuple, drop::Symbol, primo::Bool=true)
	t = ops[findall(ops .!= drop)]
	primo ? (unused_opts[1] = t) : (unused_subopts[1] = t)
end

function del_from_nt(p, symbs::Array{Symbol})
	p = Base.structdiff(p, NamedTuple{(symbs...)})
end
=#

function init_module(first::Bool, kwargs...)
	# All ps modules need these 3 lines
	d = KW(kwargs)
	!isempty(d) && help_show_options(d)		# Check if user wants ONLY the HELP mode
	K = true; O = !first
	return d, K, O
end

function GMTsyntax_opt(d::Dict, cmd::String, del::Bool=true)::Tuple{String, String}
	o::String = ""
	if haskey(d, :compact)
		o = d[:compact]
		(o == "") && (delete!(d, :compact); return cmd, "")
		cmd = (o[1] == ' ') ? cmd * o : cmd * " " * o
		del && delete!(d, :compact)
	end
	return cmd, o
end

# ---------------------------------------------------------------------------------------------------
function parse_paper(d::Dict)
	# If user set the 'paper' option, move to paper coordinates. By default set a background
	# canvas of 2x2 m. But for tuning it may be useful to plot a grid. For that use 'paper=:grid'
	# Other option is to set the units to inches. For it use 'paper=:inch'
	# If both inches and grid is intended use 'paper=(:inch,:grid)'
	((val = find_in_dict(d, [:paper])[1]) === nothing) && return nothing

	opt_J::String, opt_B::String, opt_R::String = " -Jx1c", "", " -R0/200/0/200"
	if (isa(val, Tuple) && string(val[1])[1] == 'i' && string(val[2])[1] == 'g')
		opt_J, opt_B, opt_R = " -Jx1i", " -Ba1f1g1", " -R0/12/0/12"
	elseif (isa(val, String) || isa(val, Symbol))
		c::Char = string(val)[1]
		(c == 'i') && (opt_J = " -Jx1i")
		(c == 'g') && (opt_B = " -Ba1f1g1"; opt_R = " -R0/30/0/30")
	end
	o = (CTRL.IamInPaperMode[2]) ? " -X-5c -Y-5c" : ""	# Take care to only offset once
	(o != "") && (CTRL.IamInPaperMode[2] = false)

	proggy = (IamModern[1]) ? "plot -T" : "psxy -T"
	t::String = IamModern[1] ? "" : o * " -O -K >> " * PSname[1]::String
	gmt(proggy * opt_R * opt_J * opt_B * t)
	CTRL.IamInPaperMode[1] = true
	return nothing
end
function leave_paper_mode()
	# Reset the -R -J previous to the paper mode setting
	!CTRL.IamInPaperMode[1] && return nothing
	t::String = IamModern[1] ? "" : " -O -K >> " * PSname[1]::String
	CTRL.IamInPaperMode[1] && gmt("psxy -T " * CTRL.pocket_R[1] * CTRL.pocket_J[1] * CTRL.pocket_J[3] * t)
	CTRL.IamInPaperMode[1] = false
	return nothing
end

# ---------------------------------------------------------------------------------------------------
parse_RIr(d::Dict, cmd::String, O::Bool=false, del::Bool=true) = parse_R(d, cmd, O, del, true)
function parse_R(d::Dict, cmd::String, O::Bool=false, del::Bool=true, RIr::Bool=false)::Tuple{String, String}
	# Build the option -R string. Make it simply -R if overlay mode (-O) and no new -R is fished here
	# The RIr option is to assign also the -I and -r when R was given a GMTgrid|image value. This is a
	# workaround for a GMT bug that ignores this behaviour when from externals.

	(SHOW_KWARGS[1]) && return (print_kwarg_opts([:R :region :limits], "GMTgrid | NamedTuple |Tuple | Array | String"), "")

	opt_R::String = ""
	val, symb = find_in_dict(d, [:R :region :limits :region_llur :limits_llur :limits_diag :region_diag], del)
	if (val !== nothing)
		opt_R = build_opt_R(val, symb)
	elseif (IamModern[1] && !RIr)
		return cmd, ""
	end

	opt_R = merge_R_and_xyzlims(d, opt_R)	# Let a -R be partially changed by the use of optional xyzlim

	if (RIr)
		if (isa(val, GItype))
			opt_I = parse_I(d, "", [:I :inc :increment :spacing], "I")
			(opt_I == "") && (cmd *= " -I" * arg2str(val.inc))::String
			opt_r = parse_r(d, "")[2]
			(opt_r == "") && (cmd *= " -r" * ((val.registration == 0) ? "g" : "p"))
		else				# Here we must parse the -I and -r separately.
			cmd = parse_I(d, cmd, [:I :inc :increment :spacing], "I", del)
			cmd = parse_r(d, cmd, del)[1]
		end
	end

	(O && opt_R == "") && (opt_R = " -R")
	if (opt_R != "" && opt_R != " -R" && !IamInset[1])		# Save limits in numeric
		bak = IamModern[1]
		try
			limits = opt_R2num(opt_R)
			CTRL.limits[7:7+length(limits)-1] = limits		# The plot limits
			(opt_R != " -Rtight" && opt_R !== nothing && limits != zeros(4) && all(CTRL.limits[1:4] .== 0)) &&
				(CTRL.limits[1:length(limits)] = limits)	# And this makes data = plot limits, IF data is empty.
			contains(opt_R, "+r") && (CTRL.limits[13] = 1.0)# To know that -R...+r was used.
		catch
			CTRL.limits .= 0.0
			IamModern[1] = bak
		end
		(opt_R != " -R") && (CTRL.pocket_R[1] = opt_R)
	end
	cmd = cmd * opt_R
	return cmd, opt_R
end

# ---------------------------------------------------------------------------------------------------
function merge_R_and_xyzlims(d::Dict, opt_R::String)::String
	# Let a -R be partially changed by the use of optional xyzlim

#=
	function parse_lims(d::Dict{Symbol, Any}, eixo::Char)::String
		# Parse both the simple case where -R is passed in a xlim, ylim[,zlim] or the broken axes case.
		ind = (eixo == 'x') ? 1 : (eixo == 'y') ? 2 : 3
		symbs = (ind == 1) ? [:xlim :xlims :xlimits] : (ind == 2) ? [:ylim :ylims :ylimits] : [:zlim :zlims :zlimits]
		((val = find_in_dict(d, symbs, false)[1]) === nothing) && return ""
		((isa(val, Tuple) || isvector(val)) && eltype(val) <: Real) && return @sprintf("%.15g/%.15g", val[1], val[2])
		!(eltype(val) <: Tuple{Real, Real}) && error("Wrong data type: $(typeof(val)). Should be ((x1,x2),(x3,x4))")
		# Here we are dealing with a broken axes limits
		lims::Vector{Float64} = [val[1][1] val[1][2] val[2][1] val[2][2]]		# To get rid of the Anys
		frac = (lims[2] - lims[1]) / (lims[4] - lims[1])	# Fractional size of this axis
		CTRL.figsize[ind+3] = CTRL.figsize[ind]				# Store the axis total length
		CTRL.figsize[ind] *= frac							# Store this sub-axis size for later use in ...
		@sprintf("%.15g/%.15g", val[1][1], val[1][2])
	end
	xlim, ylim, zlim = parse_lims(d, 'x'), parse_lims(d, 'y'), parse_lims(d, 'z')
=#

	xlim::String = ((val = find_in_dict(d, [:xlim :xlims :xlimits], false)[1]) !== nothing) ?
	                @sprintf("%.15g/%.15g", val[1], val[2]) : ""
	ylim::String = ((val = find_in_dict(d, [:ylim :ylims :ylimits], false)[1]) !== nothing) ?
	                @sprintf("%.15g/%.15g", val[1], val[2]) : ""
	zlim::String = ((val = find_in_dict(d, [:zlim :zlims :zlimits], false)[1]) !== nothing) ?
	                @sprintf("%.15g/%.15g", val[1], val[2]) : ""
	(xlim == "" && ylim == "" && zlim == "") && return opt_R
	function clear_xyzlims(d::Dict, xlim, ylim, zlim)
		# When calling this fun, if they exist they were used too so must remove them
		# In the other case - they exist but were not used - we keep them to be eventually used in read_data()
		(xlim != "") && delete!(d, [:xlim, :xlims, :xlimits])
		(ylim != "") && delete!(d, [:ylim, :ylims, :ylimits])
		(zlim != "") && delete!(d, [:zlim, :zlims, :zlimits])
	end

	if (opt_R == "" && xlim != "" && ylim != "")	# Deal with this easy case
		opt_R = " -R" * xlim * "/" * ylim
		(zlim != "") && (opt_R *= "/" * zlim)
		clear_xyzlims(d, xlim, ylim, zlim)
		return opt_R
	end
	(opt_R == "") && return ""						# Clear this case too. If no -R there is nothing to replace
	# OK, so here we have some x|y|zlim not empty either an opt_R != ""
	s = split(opt_R, "/")
	(xlim != "") && (s[1] = xlim; s[2] = "")		# xlim has both s[1] & s[2] so need to empty second of them
	(ylim != "") && (s[3] = ylim; s[4] = "")
	(zlim != "" && length(s) == 6) && (s[6] = zlim; s[5] = "")
	opt_R = join(s,"/")
	opt_R = opt_R[1:end-1]							# Need to strip the last char that was a '/'
	(zlim != "" && length(s) == 4) && (opt_R *= "/" * zlim)		# This case was still left to be handled
	clear_xyzlims(d, xlim, ylim, zlim)
	return opt_R
end

# ---------------------------------------------------------------------------------------------------
function build_opt_R(val, symb::Symbol=Symbol())::String		# Generic function that deals with all but NamedTuple args
	R::String = ""
	if (isa(val, String) || isa(val, Symbol))
		r::String = string(val)
		if     (r == "global")     R = " -Rd"
		elseif (r == "global360")  R = " -Rg"
		elseif (r == "same")       R = " -R"
		else                       R = " -R" * r
		end
	elseif ((isvector(val) || isa(val, Tuple)) && (length(val) == 4 || length(val) == 6))
		if (symb ∈ (:region_llur, :limits_llur, :limits_diag, :region_diag))
			_val::Vector{<:Float64} = vec(Float64.(collect(val)))
			R = " -R" * @sprintf("%.15g/%.15g/%.15g/%.15g+r", _val[1], _val[3], _val[2], _val[4])::String
		else
			R = " -R" * rstrip(arg2str(val)::String, '/')		# Remove last '/'
		end
	elseif (isa(val, GItype))
		R = @sprintf(" -R%.15g/%.15g/%.15g/%.15g", val.range[1], val.range[2], val.range[3], val.range[4])
	elseif (isa(val, GDtype))
		bb::Vector{<:Float64} = isa(val, GMTdataset) ? val.bbox : val[1].ds_bbox
		R = (symb ∈ (:region_llur, :limits_llur, :limits_diag, :region_diag)) ?
			@sprintf(" -R%.15g/%.15g/%.15g/%.15g", bb[1], bb[3], bb[2], bb[4]) :
			@sprintf(" -R%.15g/%.15g/%.15g/%.15g", bb[1], bb[2], bb[3], bb[4])
	end
	return R
end

# ---------------------------------------------------------------------------------------------------
function build_opt_R(arg::NamedTuple, symb::Symbol=Symbol())::String
	# Option -R can also be diabolicly complicated. Try to addres it. Stil misses the Time part.
	BB::String = ""
	d = nt2dict(arg)					# Convert to Dict
	if ((val = find_in_dict(d, [:limits :region])[1]) !== nothing)
		if ((isa(val, Array{<:Real}) || isa(val, Tuple)) && (length(val) == 4 || length(val) == 6))
			vval::Vector{<:Float64} = vec(Float64.(collect(val)))
			if (haskey(d, :diag) || haskey(d, :diagonal))		# The diagonal case
				BB = @sprintf("%.15g/%.15g/%.15g/%.15g+r", vval[1], vval[3], vval[2], vval[4])
			else
				BB = join([@sprintf("%.15g/", Float64(x)) for x in vval])
				BB = rstrip(BB, '/')		# and remove last '/'
			end
		elseif (isa(val, String) || isa(val, Symbol))
			BB = string(val) 			# Whatever good stuff or shit it may contain
		end
	elseif ((val = find_in_dict(d, [:limits_diag :region_diag])[1]) !== nothing)	# Alternative way of saying "+r"
		_val::Vector{<:Float64} = collect(Float64, val)
		BB = @sprintf("%.15g/%.15g/%.15g/%.15g+r", _val[1], _val[3], _val[2], _val[4])
	elseif ((val = find_in_dict(d, [:continent :cont])[1]) !== nothing)
		val_::String = uppercase(string(val))
		if     (startswith(val_, "AF"))  BB = "=AF"
		elseif (startswith(val_, "AN"))  BB = "=AN"
		elseif (startswith(val_, "AS"))  BB = "=AS"
		elseif (startswith(val_, "EU"))  BB = "=EU"
		elseif (startswith(val_, "OC"))  BB = "=OC"
		elseif (val_[1] == 'N')  BB = "=NA"
		elseif (val_[1] == 'S')  BB = "=SA"
		else   error("Unknown continent name")
		end
	elseif ((val = find_in_dict(d, [:ISO :iso])[1]) !== nothing)
		(!isa(val, String) && !isa(val, Symbol)) && error("argument to the ISO key must be a string with country codes")
		BB = string(val)
	end

	if ((val = find_in_dict(d, [:adjust :pad :extend :expand])[1]) !== nothing)
		if (isa(val, String) || isa(val, Real))
			t::String = string(val)
		elseif (isa(val, Array{<:Real}) || isa(val, Tuple))
			t = join([@sprintf("%.15g/", Float64(x)) for x in val])
			t = rstrip(t, '/')		# and remove last '/'
		else
			error("Increments for limits must be a String, a Number, Array or Tuple")
		end
		BB = (haskey(d, :adjust)) ? BB * "+r" * t : BB * "+R" * t
	end

	(haskey(d, :unit)) && (BB *= "+u" * string(string(d[:unit])[1])::String)	# (e.g., -R-200/200/-300/300+uk)

	(BB == "") && error("No, no, no. Nothing useful in the region named tuple arguments")
	return " -R" * BB
end

# ---------------------------------------------------------------------------------------------------
function opt_R2num(opt_R::String)
	# Take a -R option string and convert it to numeric
	(opt_R == "") && error("opt_R is empty but that shouldn't happen here.")
	(endswith(opt_R, "Rg")) && return [0.0, 360., -90., 90.]
	(endswith(opt_R, "Rd")) && return [-180.0, 180., -90., 90.]
	if (findfirst("/", opt_R) !== nothing && !contains(opt_R, ":"))
		isdiag = false
		if ((ind = findfirst("+r", opt_R)) !== nothing)		# Diagonal mode
			opt_R = opt_R[1:ind[1]-1];	isdiag = true		# Strip the "+r"
		end
		rs = split(opt_R, '/')
		limits::Vector{<:Float64} = zeros(length(rs))
		fst = ((ind = findfirst("R", rs[1])) !== nothing) ? ind[1] : 0
		#contains(rs[2], "T") || contains(rs[2], "t")
		limits[1] = parse(Float64, rs[1][fst+1:end])
		for k = 2:lastindex(rs)  limits[k] = parse(Float64, rs[k])  end
		#if (isdiag)  limits[2], limits[4] = limits[4], limits[2]  end
		# Don't know anymore how -R...+r limits should be stored in CTRL.limits
	elseif (opt_R != " -R" && opt_R != " -Rtight")	# One of those complicated -R forms. Ask GMT the limits (but slow. It takes 0.2 s)

		# If opt_R is not a grid's name, we are f.
		((ind = findfirst("-R@", opt_R)) !== nothing) && return grdinfo(opt_R[ind[3]:end], C=true)[1:4]	# should be a cache file
		(((f = guess_T_from_ext(opt_R)) == " -Tg") || f == " -Ti") && return grdinfo(opt_R[4:end], C=true)[1:4]	# any local file

		kml::GMTdataset = gmt("gmt2kml " * opt_R, [0 0])		# for example, opt_R = " -RPT"
		limits = zeros(4)
		t::String = kml.text[28][12:end];	ind = findfirst("<", t)		# north
		limits[4] = parse(Float64, t[1:(ind[1]-1)])
		t = kml.text[29][12:end];	ind = findfirst("<", t)		# south
		limits[3] = parse(Float64, t[1:(ind[1]-1)])
		t = kml.text[30][11:end];	ind = findfirst("<", t)		# east
		limits[2] = parse(Float64, t[1:(ind[1]-1)])
		t = kml.text[31][11:end];	ind = findfirst("<", t)		# east
		limits[1] = parse(Float64, t[1:(ind[1]-1)])
	else
		limits = zeros(4)
	end
	return limits
end

# ---------------------------------------------------------------------------------------------------
function parse_JZ(d::Dict, cmd::String, del::Bool=true; O::Bool=false, is3D::Bool=false)
	symbs = [:JZ :Jz :zscale :zsize]
	(SHOW_KWARGS[1]) && return (print_kwarg_opts(symbs, "String | Number"), "")
	opt_J::String = "";		seek_JZ = true
	if ((val = find_in_dict(d, [:aspect3])[1]) !== nothing)
		o = scan_opt(cmd, "-J")
		(o == "") && (o = " ")		# When scaning a string with only -J (i.e., no args), do not error
		(o[1] != 'X' || o[end] == 'd') &&  @warn("aspect3 works only in linear projections (and no geog), ignoring it.") 
		if (o[1] == 'X' && o[end] != 'd' && length(o) > 1)
			opt_J = " -JZ" * split(o[2:end],'/')[1];		seek_JZ = false
			cmd *= opt_J
		end
	end
	if (seek_JZ)
		val, symb = find_in_dict(d, symbs, del)
		if (val !== nothing)
			opt_J = (symb == :JZ || symb == :zsize) ? " -JZ" * arg2str(val) : " -Jz" * arg2str(val)
			cmd *= opt_J
		end
	end
	#CTRL.pocket_J[3] = opt_J
	(is3D && O && opt_J == "" && CTRL.pocket_J[3] != "") ? (opt_J = CTRL.pocket_J[3]; cmd *= opt_J) : CTRL.pocket_J[3] = opt_J
	return cmd, opt_J
end

# ---------------------------------------------------------------------------------------------------
function parse_J(d::Dict, cmd::String, default::String="", map::Bool=true, O::Bool=false, del::Bool=true)
	# Build the option -J string. Make it simply -J if in overlay mode (-O) and no new -J is fished here
	# Default to 15c if no size is provided.
	# If MAP == false, do not try to append a fig size

	(SHOW_KWARGS[1]) && return (print_kwarg_opts([:J :proj :projection], "NamedTuple | String"), "")

	opt_J::String = "";		mnemo::Bool = false
	if ((val = find_in_dict(d, [:J :proj :projection], del)[1]) !== nothing)
		isa(val, Dict) && (val = Base.invokelatest(dict2nt,val))
		opt_J, mnemo = build_opt_J(val)		# mnemo = true when the projection name used a mnemonic for the projection
	elseif (IamModern[1] && ((val = is_in_dict(d, [:figscale :fig_scale :scale :figsize :fig_size])) === nothing))
		# Subplots do not rely in the classic default mechanism
		(IamInset[1] && !contains(cmd, " -J")) && (cmd *= CTRL.pocket_J[1]::String) 	# Workaround GMT bug (#7005)
		return cmd, ""
	end
	CTRL.proj_linear[1] = (length(opt_J) >= 4 && opt_J[4] != 'X' && opt_J[4] != 'x' && opt_J[4] != 'Q' && opt_J[4] != 'q') ? false : true
	(!map && opt_J != "") && return cmd * opt_J, opt_J

	(O && opt_J == "") && (opt_J = " -J")

	if (!O)
		if (default == "guess" && opt_J == "")
			opt_J = guess_proj(CTRL.limits[7:8], CTRL.limits[9:10]);	mnemo = true	# To force append fig size
		end
		(opt_J == "") && (opt_J = " -JX")
		# If only the projection but no size, try to get it from the kwargs.
		if ((s = helper_append_figsize(d, opt_J, O, del)) != "")		# Takes care of both fig scales and fig sizes
			opt_J = s
		elseif (default != "" && opt_J == " -JX")
			opt_J = IamSubplot[1] ? " -JX?" : (default != "guess" ? default : opt_J) 	# -JX was a working default
		elseif (occursin("+width=", opt_J))		# OK, a proj4 string, don't touch it. Size already in.
		elseif (occursin("+proj", opt_J))		# A proj4 string but no size info. Use default size
			opt_J *= "+width=" * string(split(DEF_FIG_SIZE, '/')[1])::String
		elseif (mnemo)							# Proj name was obtained from a name mnemonic and no size. So use default
			opt_J = append_figsize(d, opt_J)
		elseif (!isdigit(opt_J[end]) && (length(opt_J) < 6 || (isletter(opt_J[5]) && !isdigit(opt_J[6]))) )
			if (!IamSubplot[1])
				if (((val = find_in_dict(d, [:aspect], del)[1]) !== nothing) || haskey(d, :aspect3))
					opt_J *= set_aspect_ratio(val, "", true, haskey(d, :aspect3))::String
				else
					opt_J = (!startswith(opt_J, " -JX")) ? append_figsize(d, opt_J) :
					         opt_J * DEF_FIG_SIZE::String; CTRL.pocket_J[2] = DEF_FIG_SIZE
				end
				#CTRL.pocket_J[1] = opt_J
			elseif (!occursin("?", opt_J))		# If we dont have one ? for size/scale already
				opt_J *= "/?"
			end
		end
	else										# For when a new size is entered in a middle of a script
		if ((s = helper_append_figsize(d, opt_J, O, del)) != "")
			if (opt_J == " -J")
				(CTRL.pocket_J[1] != s) &&		# Composed funs (ex: fill_between) would trigger this warning
					println("SEVERE WARNING: When appending a new fig with a different size you SHOULD set the `projection`. \n\tAdding `projection=:linear` at your own risk.");
				opt_J *= "X" * s[4:end]::String
			else
				opt_J = s
			end
		end
	end
	CTRL.proj_linear[1] = (length(opt_J) >= 4 && opt_J[4] != 'X' && opt_J[4] != 'x' && opt_J[4] != 'Q' && opt_J[4] != 'q') ? false : true

	(opt_J == " ") && (opt_J = "")		# We use " " when wanting to prevent the default -J
	fish_size_from_J(opt_J)				# So far we only need this in plot(hexbin)
	((length(opt_J) > 4) && !contains(opt_J, "?")) && (CTRL.pocket_J[1] = opt_J)
	cmd *= opt_J
	return cmd, opt_J
end

function size_unit(dim::AbstractString)
	# Convert a size string appended with a unit char code into numeric. Also accepts dim as a num string
	fact(c::Char) = (c == 'c') ? 1.0 : (c == 'i' ? 2.54 : (c == 'p' ? 2.54/72 : 1.0))
	isletter(dim[end]) ? parse(Float64, dim[1:end-1]) * fact(dim[end]) : parse(Float64, dim)
end
size_unit(dim::Vector{<:AbstractString})::Vector{Float64} = [size_unit(t) for t in dim]

function fish_size_from_J(opt_J)
	# There are many ways by which a fig size ends up in the -J string. So lets try here to fish the fig
	# dimensions, at least the fig width, from opt_J. Ofc, several things can go wrong.
	(length(opt_J) < 5 || (opt_J[4] != 'X' && opt_J[4] != 'x')) && return nothing	# Up to " -JX" and only linear
	(occursin('d', opt_J) || occursin('p', opt_J)) && return nothing	# if it has a 'd' it means it's a geog. 

	fact(c::Char) = (c == 'c') ? 1.0 : (c == 'i' ? 2.54 : (c == 'p' ? 2.54/72 : 1.0))
	ws = opt_J[5:end]
	dim = split(ws, '/')
	isscale = occursin(':', ws)				# Compliction. A scale in form 1:xxxx
	try
	if (!isscale)
		for k = 1:lastindex(dim)
			CTRL.figsize[k] = isletter(dim[k][end]) ? parse(Float64, dim[k][1:end-1]) * fact(dim[k][end]) : parse(Float64, dim[k])
		end
	end
	if (!isuppercase(opt_J[4]) || isscale)		# Shit, a scale. Hopefuly, -R was already parsed and CTRL.limits is known
		if (isscale)
			t = parse.(Float64, split(dim[1], ':'))
			CTRL.figsize[1] = t[2] / t[1]
		end
		CTRL.figsize[1] *= (CTRL.limits[8] - CTRL.limits[7])	# Prey
	end
	catch
	end
	return nothing
end

function get_figsize(opt_R::String="", opt_J::String="")
	# Compute the current fig dimensions in paper coords using the know -R -J
	(opt_R == "" || opt_R == " -R") && (opt_R = CTRL.pocket_R[1])
	(opt_J == "" || opt_J == " -J") && (opt_J = CTRL.pocket_J[1])
	((opt_R == "" || opt_J == "") && !IamModern[1]) && error("One or both of 'limits' ($opt_R) or 'proj' ($opt_J) is empty. Cannot compute fig size.")
	Dwh = gmt("mapproject -W " * opt_R * opt_J)
	return Dwh[1], Dwh[2]		# Width, Height
end

function helper_append_figsize(d::Dict, opt_J::String, O::Bool, del::Bool=true)::String
	val_, symb = find_in_dict(d, [:figscale :fig_scale :scale :figsize :fig_size], del)
	(val_ === nothing && is_in_dict(d, [:flipaxes :flip_axes]) === nothing) && return ""
	val::String = arg2str(val_)
	if (occursin("scale", arg2str(symb)))		# We have a fig SCALE request
		(O && opt_J == " -J") && error("In Overlay mode you cannot change a fig scale and NOT repeat the projection")
		if     (IamSubplot[1] && val == "auto")       val = "?"
		elseif (IamSubplot[1] && val == "auto,auto")  val = "?/?"
		end
		if (opt_J == " -JX")
			val = check_flipaxes(d, val)
			opt_J::String = isletter(val[1]) ? " -J" * val : " -Jx" * val		# FRAGILE
		else                          opt_J = append_figsize(d, opt_J, val, true)
		end
	else										# A fig SIZE request
		(haskey(d, :units)) && (val *= d[:units][1]::String)
		if (occursin("+proj", opt_J)) opt_J *= "+width=" * val
		else                          opt_J = append_figsize(d, opt_J, val)
		end
	end
	return opt_J
end

function append_figsize(d::Dict, opt_J::String, width::String="", scale::Bool=false)::String
	# Appending either a fig width or fig scale depending on what projection.
	# Sometimes we need to separate with a '/' others not. If WIDTH == "" we
	# use the DEF_FIG_SIZE, otherwise use WIDTH that can be a size or a scale.

	if (width == "")
		width::String = (IamSubplot[1]) ? "?" : split(DEF_FIG_SIZE, '/')[1]		# In subplot "?" is auto width
	elseif (IamSubplot[1] && (width == "auto" || width == "auto,auto"))	# In subplot one can say figsize="auto" or figsize="auto,auto"
		width = (width == "auto") ? "?" : "?/?"
	elseif (((val = find_in_dict(d, [:aspect])[1]) !== nothing) || haskey(d, :aspect3))
		(occursin("/", width)) && @warn("Ignoring the 'aspect' request because fig's Width and Height already provided.")
		if (!occursin("/", width))
			width = set_aspect_ratio(val, width, false, haskey(d, :aspect3))
		end
	end

	slash::String = "";		de::String = ""
	if (opt_J[end] == 'd')  opt_J = opt_J[1:end-1];		de = "d"  end
	if (isdigit(opt_J[end]) && ~startswith(opt_J, " -JXp"))    slash = "/";#opt_J *= "/" * width
	else
		if (occursin("Cyl_", opt_J) || occursin("Poly", opt_J))  slash = "/";#opt_J *= "/" * width
		elseif (startswith(opt_J, " -JU") && length(opt_J) > 4)  slash = "/";#opt_J *= "/" * width
		else								# Must parse for logx, logy, loglog, etc
			if (startswith(opt_J, " -JXl") || startswith(opt_J, " -JXp") ||
				startswith(opt_J, " -JXT") || startswith(opt_J, " -JXt"))
				ax = opt_J[6];	flag = opt_J[5];
				if (flag == 'p' && length(opt_J) > 6)  flag *= opt_J[7:end]  end	# Case p<power>
				opt_J = opt_J[1:4]			# Trim the consumed options
				w_h = split(width,"/")
				if (length(w_h) == 2)		# Must find which (or both) axis is scaling be applyied
					(ax == 'x') ? w_h[1] *= flag : ((ax == 'y') ? w_h[2] *= flag : w_h .*= flag)
					width = w_h[1] * "/" * w_h[2]
				elseif (ax == 'y')  error("Can't select Y scaling and provide X dimension only")
				else
					width *= flag
					(ax == 'l' && flag == 'l') && (width = IamModern[1] ? width * "/?l" : width * "/l")	# The loglog case
					(width[1] == '?' && !contains(width, '/')) && (width *= "/?")
				end
			end
		end
	end
	width = check_flipaxes(d, width)
	opt_J *= slash * width * de
	CTRL.pocket_J[1], CTRL.pocket_J[2] = opt_J, width		# Save these for eventual (in -B) change if flip dims dir
	if (scale)  opt_J = opt_J[1:3] * lowercase(opt_J[4]) * opt_J[5:end]  end 		# Turn " -JX" to " -Jx"
	return opt_J
end

set_aspect_ratio(aspect::Nothing, width::String, def_fig::Bool=false, is_aspect3::Bool=false)::String = set_aspect_ratio("", width, def_fig, is_aspect3)
set_aspect_ratio(aspect::Symbol, width::String, def_fig::Bool=false, is_aspect3::Bool=false)::String = set_aspect_ratio(string(aspect), width, def_fig, is_aspect3)
set_aspect_ratio(aspect::Real, width::String, def_fig::Bool=false, is_aspect3::Bool=false)::String = set_aspect_ratio(string(aspect, ":1"), width, def_fig, is_aspect3)
function set_aspect_ratio(aspect::String, width::String, def_fig::Bool=false, is_aspect3::Bool=false)::String
	# Set the aspect ratio. ASPECT can be "equal", "eq"; "square", "sq" or a ratio in the form "4:3", "16:12", etc.
	def_fig && (width = split(DEF_FIG_SIZE, '/')[1])
	if (startswith(aspect, "eq") || is_aspect3)
		width *= "/0"
	elseif (startswith(aspect, "sq"))
		width *= "/" * width
	elseif (occursin(":", aspect))
		u = isletter(width[end]) ? width[end] : ' '		# See if we have a unit char
		w = (u != ' ') ? parse(Float64, width[1:end-1]) : parse(Float64, width)
		dims = parse.(Float64, split(aspect, ':'))
		h = w * dims[2] / dims[1]						# Apply the aspect ratio
		width = string(width, "/", h)
		(u != ' ') && (width *= u)
	else
		error("Non-sense 'aspect' value ($(aspect)) in set_aspect_ratio()")
	end
	CTRL.pocket_J[2] = width		# Save for the case we need to revert the axis dir
	return width
end

# ----------------------------------------------------------------------------------------------------
"""
    w, h = plot_GI_size(GI, proj="", region="")

Compute the plot width and height in cm given the the region `region` and projection `proj`. Note that
here the `region` and `proj` options, if provided, must be the full " -R...." and " -J..." strings and
the later MUST contain the figure width too. If any of those is empty we get/estimate them from the `GI`
limits, where `GI` is either a grid or an image. For this we use a default value of 15c but this
value is not particularly important because the main idea here is to be able to compute the H/W ratio.

Returns a tuple of Float64 with the width, height in cm.
"""
function plot_GI_size(GI::GItype, opt_J="", opt_R="")
	got_J = (opt_J != "")
	(opt_R == "") && (opt_R = @sprintf(" -R%.10g/%.10g/%.10g/%.10g", GI.range[1:4]...))
	(opt_J == "") && (opt_J = (GI.geog > 0) ? guess_proj(GI.range[1:2], GI.range[3:4]) : " -JX")
	!got_J && (opt_J *= '/' * split(DEF_FIG_SIZE, '/')[1])
	w,h = gmt("mapproject -W " * opt_R * opt_J).data
end

# ----------------------------------------------------------------------------------------------------
function check_flipaxes(d::Dict, width::AbstractString)
	# Deal with the case that we want to invert the axis sense.
	# flipaxes(x=true, y=true) OR  flipaxes("x", :y) OR flipaxes(:xy)
	# Note: 'flipaxes' is meant to be used in subplots only, where we are not(?) supposed to change the
	# figs dimensions directly, but in fact it can be used in normal plots too though the 'flipx', etc...
	# mechanism is clearer to read (NOT WORKING WELL).
	(width == "" || (val = find_in_dict(d, [:flipaxes :flip_axes])[1]) === nothing) && return width

	swap_x = false;		swap_y = false;
	isa(val, Dict) && (val = Base.invokelatest(dict2nt,val))
	if (isa(val, NamedTuple))
		for k in keys(val)
			if     (k == :x)  swap_x = true
			elseif (k == :y)  swap_y = true
			elseif (k == :xy) swap_x = true;  swap_y = true
			end
		end
	elseif (isa(val, Tuple))
		for k in val
			t::String = string(k)
			if     (t == "x")  swap_x = true
			elseif (t == "y")  swap_y = true
			elseif (t == "xy") swap_x = true;  swap_y = true
			end
		end
	elseif (isa(val, String) || isa(val, Symbol))
		t = string(val)
		if     (t == "x")  swap_x = true
		elseif (t == "y")  swap_y = true
		elseif (t == "xy") swap_x = true;  swap_y = true
		end
	end

	if (occursin("/", width))
		sizes = split(width,"/")
		(swap_x) && (sizes[1] = "-" * sizes[1])
		(swap_y) && (sizes[2] = "-" * sizes[2])
		width = sizes[1] * "/" * sizes[2]
	else
		width = "-" * width
	end
	(occursin("?-", width)) && (width = replace(width, "?-" => "-?"))	# It may, from subplots
	return width
end

function build_opt_J(val)::Tuple{String, Bool}
	out::String = "";		mnemo = false
	if (isa(val, String) || isa(val, Symbol))
		if (string(val) == "guess")
			out, mnemo = guess_proj(CTRL.limits[7:8], CTRL.limits[9:10]), true
		else
			prj::String, mnemo = parse_proj(string(val))
			out = " -J" * prj
		end
	elseif (isa(val, NamedTuple))
		prj, mnemo = parse_proj(val)
		out = " -J" * prj
	elseif (isa(val, Real))
		if (!(typeof(val) <: Int) || val < 2000)
			error("The only valid case to provide a number to the 'proj' option is when that number is an EPSG code, but this (" * string(val)::String * ") is clearly an invalid EPSG")
		end
		out = string(" -J", string(val)::String)
	elseif (isempty(val))
		out = " -J"
	end
	return out, mnemo
end

function parse_proj(p::String)::Tuple{String, Bool}
	# See "p" if is a string with a projection name. If yes, convert it into the corresponding -J syntax
	(p == "") && return p, false

	if (p[1] == '+' || startswith(p, "epsg") || startswith(p, "EPSG") || occursin('/', p) || length(p) < 3)
		p = replace(p, " " => "")		# Remove the spaces from proj4 strings
		return p,false
	end
	out::String = ""
	s = lowercase(p);		mnemo = true	# True when the projection name used one of the below mnemonics
	if     (s == "aea"   || s == "albers")                 out = "B0/0"
	elseif (s == "cea"   || s == "cylindricalequalarea")   out = "Y0/0"
	elseif (s == "laea"  || s == "lambertazimuthal")       out = "A0/0"
	elseif (s == "lcc"   || s == "lambertconic")           out = "L0/0"
	elseif (s == "aeqd"  || s == "azimuthalequidistant")   out = "E0/0"
	elseif (s == "eqdc"  || s == "conicequidistant")       out = "D0/90"
	elseif (s == "tmerc" || s == "transversemercator")     out = "T0"
	elseif (s == "eqc"   || startswith(s, "plat") || startswith(s, "equidist") || startswith(s, "equirect"))  out = "Q"
	elseif (s == "eck4"  || s == "eckertiv")               out = "Kf"
	elseif (s == "eck6"  || s == "eckertvi")               out = "Ks"
	elseif (s == "omerc" || s == "obliquemerc1")           out = "Oa"
	elseif (s == "omerc2"|| s == "obliquemerc2")           out = "Ob"
	elseif (s == "omercp"|| s == "obliquemerc3")           out = "Oc"
	elseif (startswith(s, "cyl_") || startswith(s, "cylindricalster"))  out = "Cyl_stere"
	elseif (startswith(s, "cass"))   out = "C0/0"
	elseif (startswith(s, "geo"))    out = "Xd"		# Linear geogs
	elseif (startswith(s, "gnom"))   out = "F0/0"
	elseif (startswith(s, "ham"))    out = "H"
	elseif (startswith(s, "lin"))    out = "X"
	elseif (startswith(s, "logxy"))  out = "Xll"
	elseif (startswith(s, "logx"))   out = "Xlx"
	elseif (startswith(s, "logy"))   out = "Xly"
	elseif (startswith(s, "loglog")) out = "Xll"
	elseif (startswith(s, "powx"))   v = split(s, ',');	length(v) == 2 ? out = "Xpx" * v[2] : out = "Xpx"
	elseif (startswith(s, "powy"))   v = split(s, ',');	length(v) == 2 ? out = "Xpy" * v[2] : out = "Xpy"
	elseif (startswith(s, "Time"))   out = "XTx"
	elseif (startswith(s, "time"))   out = "Xtx"
	elseif (startswith(s, "merc"))   out = "M"
	elseif (startswith(s, "mil"))    out = "J"
	elseif (startswith(s, "mol"))    out = "W"
	elseif (startswith(s, "ortho"))  out = "G0/0"
	elseif (startswith(s, "poly"))   out = "Poly"
	elseif (s == "polar")            out = "P"
	elseif (s == "polar_azim")       out = "Pa"
	elseif (startswith(s, "robin"))  out = "N"
	elseif (startswith(s, "stere"))  out = "S0/90"
	elseif (startswith(s, "sinu"))   out = "I"
	elseif (startswith(s, "utm"))    out = "U" * s[4:end]
	elseif (startswith(s, "vand"))   out = "V"
	elseif (startswith(s, "win"))    out = "R"
	else   out = p;		mnemo = false
	end
	return out, mnemo
end

function parse_proj(p::NamedTuple)::Tuple{String, Bool}
	# Take a proj=(name=xxxx, center=[lon lat], parallels=[p1 p2]), where either center or parallels
	# may be absent, but not BOTH, an create a GMT -J syntax string (note: for some projections 'center'
	# maybe a scalar but the validity of that is not checked here).
	d = nt2dict(p)					# Convert to Dict
	if ((val = find_in_dict(d, [:name])[1]) !== nothing)
		prj::String, mnemo = parse_proj(string(val)::String)
		if (prj != "Cyl_stere" && prj == string(val)::String)
			@warn("Very likely the projection name ($prj) is unknown to me. Expect troubles")
		end
	else
		error("When projection arguments are in a NamedTuple the projection 'name' keyword is madatory.")
	end

	center::String = ""
	if ((val = find_in_dict(d, [:center])[1]) !== nothing)
		if     (isa(val, String))  center = val
		elseif (isa(val, Real))    center = @sprintf("%.12g", val)
		elseif (isa(val, Array) || isa(val, Tuple) && length(val) == 2)
			if (isa(val, Array))   center = @sprintf("%.12g/%.12g", val[1], val[2])
			else		# Accept also strings in tuple (Needed for movie)
				center  = (isa(val[1], String)) ? val[1]::String * "/" : @sprintf("%.12g/", val[1])
				center *= (isa(val[2], String)) ? val[2]::String : @sprintf("%.12g", val[2])::String
			end
		end
	end

	if (center != "" && (val = find_in_dict(d, [:horizon])[1]) !== nothing)  center = string(center, '/',val)  end

	parallels::String = ""
	if ((val = find_in_dict(d, [:parallel :parallels])[1]) !== nothing)
		if     (isa(val, String))  parallels = "/" * val
		elseif (isa(val, Real))    parallels = @sprintf("/%.12g", val)
		elseif (isa(val, Array) || isa(val, Tuple) && (length(val) <= 3 || length(val) == 6))
			parallels = join([@sprintf("/%.12g",x)::String for x in val])
		end
	end

	# Piggy-back `center`. Things can be wrong here is user does stupid things like using zone & parallels
	((val = find_in_dict(d, [:zone])[1]) !== nothing) && (center = string(val))

	if     (center == "" && parallels != "")  center = "0/0" * parallels
	elseif (center != "")                     center *= parallels			# even if par == ""
	else   error("When projection is a named tuple you need to specify also 'center' and|or 'parallels'")
	end
	if (startswith(prj, "Cyl"))  prj = prj[1:9] * "/" * center	# The unique Cyl_stere case
	elseif (prj[1] == 'K' || prj[1] == 'O')  prj = prj[1:2] * center	# Eckert || Oblique Merc
	else                                     prj = prj[1]   * center
	end
	return prj, mnemo
end

# ---------------------------------------------------------------------------------------------------
function guess_proj(lonlim, latlim)::String
	# Select a projection based on map limits. Follows closely the Matlab behavior

	if (lonlim[1] == 0.0 && lonlim[2] == 0.0 && latlim[1] == 0.0 && latlim[2] == 0.0)
		@warn("Numeric values of 'CTRL.limits' not available. Cannot use the 'guess' option (Must specify a projection)")
		return(" -JX")
	end
	mean_x(x) = round(sum(x)/2; digits=3)

	if (latlim == [-90, 90] && (lonlim[2]-lonlim[1]) > 359.99)	# Whole Earth
		proj = string(" -JN", mean_x(lonlim))		# Robinson
	elseif (maximum(abs.(latlim)) < 30)
		proj = " -JM"						# Mercator
	elseif abs(latlim[2]-latlim[1]) <= 90 && abs(sum(latlim)) > 20 && maximum(abs.(latlim)) < 90
		# doesn't extend to the pole, not straddling equator
		parallels = latlim .+ diff(latlim) .* [1/6 -1/6]
		proj = @sprintf(" -JD%.6g/%.6g/%.6g/%.6g", mean_x(lonlim), mean_x(latlim), parallels[1], parallels[2])	# eqdc
	elseif abs(latlim[2]-latlim[1]) < 85 && maximum(abs.(latlim)) < 90	# doesn't extend to the pole, not straddling equator
		proj = string(" -JI", mean_x(lonlim))							# Sinusoidal
	elseif (maximum(latlim) == 90 && minimum(latlim) >= 75)
		proj = string(" -JS", mean_x(lonlim), "/90")					# General Stereographic - North Pole
	elseif (minimum(latlim) == -90 && maximum(latlim) <= -75)
		proj = string(" -JS", mean_x(lonlim), "/-90")					# General Stereographic - South Pole
	elseif maximum(abs.(latlim)) == 90 && abs(lonlim[2]-lonlim[1]) < 180
		proj = string(" -JPoly", mean_x(lonlim), '/', mean_x(latlim))	# Polyconic
	elseif maximum(abs.(latlim)) == 90 && abs(latlim[2]-latlim[1]) < 90
		proj = string(" -JE", mean_x(lonlim), '/', 90 * sign(latlim[2]))# azimuthalequidistant
	else
		proj = string(" -JJ", mean_x(lonlim))							# Miller
	end
end

# ---------------------------------------------------------------------------------------------------
function parse_grid(d::Dict, args, opt_B::String="", stalone::Bool=true)::String
	# Parse the contents of the "grid" option. This option can be used as grid=(pen=:red, x=10), case on
	# which the parsed result will be appended to DEF_FIG_AXES, or as a member of the "frame" option.
	# In this case DEF_FIG_AXES is dropped and only the contents of "frame" will be used. The argument can
	# be a NamedTuple, which allows setting grid pen and individual axes, or as a string (see ex bellow).
	pre::String = (stalone) ? " -B" : ""
	get_int(oo) = return (tryparse(Float64, oo) !== nothing) ? oo : ""	# Micro nested-function
	if (isa(args, NamedTuple))	# grid=(pen=?, x=?, y=?, xyz=?)
		dd = nt2dict(args)
		n = length(opt_B)
		((o::String = string(get(dd, :x, ""))) !== "") && (opt_B *= pre*"xg" * get_int(o))
		((o = string(get(dd, :y, ""))) !== "") && (opt_B *= pre*"yg" * get_int(o))
		((o = string(get(dd, :z, ""))) !== "") && (opt_B *= pre*"zg" * get_int(o))
		((o = string(get(dd, :xyz, ""))) !== "") && (opt_B *= pre*"g -Bzg")
		(n == length(opt_B)) && (opt_B *= pre*"g")		# None of the above default to -Bg
		if (haskey(dd, :pen))
			p::String = opt_pen(dd, 'W', [:pen])[4:end]					# Because p = " -W..."
			# Need to find if we already have a conf and need to append or create one. And we may have [:par :conf :params]
			symb = (haskey(d, :par)) ? :par : (haskey(d, :conf)) ? :conf : (haskey(d, :params)) ? :params : :n
			if (symb == :n)  d[:par] = (MAP_GRID_PEN_PRIMARY=p,)
			else
				d[symb] = isa(d[symb], NamedTuple) ? (d[symb]..., MAP_GRID_PEN_PRIMARY=p,) : (MAP_GRID_PEN_PRIMARY=p,)
			end
		end
	else
		# grid=:on => -Bg;	grid=:x => -Bxg;	grid="x10" => -Bxg10; grid=:y ...;  grid=:xyz => " -Bg -Bzg"
		o = string(args)
		spli = split(opt_B)
		_x::Bool, _y::Bool, _xyz::Bool, _xy::Bool = (o[1] == 'x'), (o[1] == 'y'), (o == "xyz"), (o == "xy")
		if     (_x && !_xy && !_xyz)  opt_B *= pre*"xg" * (length(o) > 1 ? o[2:end] : "")	# grid=:x or grid="x10"
		elseif (_y)           opt_B *= pre*"yg" * (length(o) > 1 ? o[2:end] : "")
		elseif (_xyz)         opt_B *= pre*"g -Bzg"
		elseif (_xy)          spli[1] *= "g";	opt_B = " " * join(spli, " ")
		elseif (o == "true")  opt_B = " " * join(spli .* "g", " ")
		else                  opt_B *= pre*"g"			# For example: grid=:on
		end
	end
	return opt_B
end

# ---------------------------------------------------------------------------------------------------
function parse_B(d::Dict, cmd::String, opt_B__::String="", del::Bool=true)::Tuple{String,String}
	# opt_B is used to transmit a default value. If not empty the Bframe part must be at the end and only one -B...

	(SHOW_KWARGS[1]) && return (print_kwarg_opts([:B :frame :axes :axis :xaxis :yaxis :zaxis :axis2 :xaxis2 :yaxis2], "NamedTuple | String"), "")

	opt_B::String = opt_B__	# Otherwise opt_B is core Boxed??
	parse_theme(d)			# Must be first because some themes change DEF_FIG_AXES
	DEF_FIG_AXES_::String  = (IamModern[1]) ? "" : DEF_FIG_AXES[1]		# DEF_FIG_AXES is a global const
	DEF_FIG_AXES3_::String = (IamModern[1]) ? "" : DEF_FIG_AXES3[1]		# DEF_FIG_AXES is a global const

	have_Bframe, got_Bstring, have_axes::Bool = false, false, false	# To know if the axis() function returns a -B<frame> setting

	extra_parse = true;		have_a_none = false
	if ((val = find_in_dict(d, [:B :frame :axes :axis], del)[1]) !== nothing)		# These four are aliases
		if (isa(val, String) || isa(val, Symbol))
			_val::String = string(val)			# In case it was a symbol
			if (_val == "none")					# User explicitly said NO AXES
				if     (haskey(d, :xlabel))  _val = "-BS";	have_a_none = true		# Unless labels are wanted, but
				elseif (haskey(d, :ylabel))  _val = "-BW";	have_a_none = true		# GMT Bug forces using tricks
				elseif (haskey(d, :title))   _val = "";		have_a_none = true
				else   return cmd, ""
				end
			elseif (_val == "noannot" || _val == "bare")
				return cmd * " -B0", " -B0"
			elseif (_val == "same")				# User explicitly said "Same as previous -B"
				return cmd * " -B", " -B"
			elseif (_val == "full")
				return cmd * " -Baf -BWSEN", " -Baf -BWSEN"
			elseif (startswith(_val, "auto"))
				is3D = false
				if     (occursin("XYZg", _val)) _val = " -Bafg -Bzafg -B+" * "w";  is3D = true
				elseif (occursin("XYZ", _val))  _val = DEF_FIG_AXES3[1];		is3D = true
				elseif (occursin("XYg", _val))  _val = " -Bafg -BWSen"
				elseif (occursin("XY", _val))   _val = DEF_FIG_AXES[1]
				elseif (occursin("Xg", _val))   _val = " -Bafg -BwSen"
				elseif (occursin("X",  _val))   _val = " -Baf -BwSen"
				elseif (occursin("Yg", _val))   _val = " -Bafg -BWsen"
				elseif (occursin("Y",  _val))   _val = " -Baf -BWsen"
				elseif (_val == "auto")         _val = DEF_FIG_AXES[1]		# 2D case
				end
				cmd = guess_WESN(d, cmd)
			elseif (length(_val) <= 5 && !occursin(" ", _val) && occursin(r"[WESNwesnzZ]", _val))
				autoZ = (!contains(_val, " ") && contains(_val, 'Z')) ? " zaf" : ""
				_val *= " af" * autoZ		# To prevent that setting B=:WSen removes all annots
			end

			# Next line is a check if a color bg was passed in -B string. BG colors f screw the API continuity
			(CTRL.pocket_B[3] == "" && contains(_val, "+g")) && (CTRL.pocket_B[3] = ".")	# Signal that a restart is due.

		elseif (isa(val, Real))				# for example, B=0
			_val = string(val)
		end
		isa(val, Dict) && (val = Base.invokelatest(dict2nt,val))
		if (isa(val, NamedTuple))
			_opt_B::String, what_B::Vector{Bool} = axis(val, d);	extra_parse = false
			have_Bframe = what_B[2]
			def_opt_B_split = split(opt_B)
			have_axes = :axes in keys(val)
			if (!have_axes && opt_B != "" && findlast(" ", opt_B)[1] != 1)	# If not have frame=(axes=..., ) use the default
				def_Bframe = def_opt_B_split[end]	# => "-BWSen" when opt_B holds the default " -Baf -BWSen"
				(startswith(def_Bframe, "-Bz") || !occursin(r"[WESNwesnzZ]", def_Bframe)) && (have_Bframe = false; def_Bframe = "")
				if (have_Bframe)					# If we already have a Bframe bit must append it to def_Bframe
					s = split(_opt_B)
					nosplit_spaces!(s)	# Check (and fix) that the above split did not split across multi words sub-options
					opt_B = " " * join(s[1:end-1], " ") * " " * def_Bframe * s[end][3:end]
				else
					opt_B = _opt_B * " " * def_Bframe
					opt_B == " " && (opt_B = "")
				end
				opt_B = consolidate_Baxes(opt_B)
			else
				opt_B = _opt_B
			end
			if (!what_B[1] && opt_B != "")		# If user didn't touch the axes part, so we'll keep the default.
				if (get(val, :axes, nothing) != :none)	# axes=:none is to be respected.
					def_Baxes::String = join(def_opt_B_split[1:end-1], " ")	# => "-Baf" when opt_B holds the default " -Baf -BWSen"
					opt_B = " " * def_Baxes * opt_B
				end
			end
		else
			opt_B = string(_val)
		end
		(extra_parse && (isa(val, String) || isa(val, Symbol))) && (got_Bstring = true)	# Signal to not try to consolidate with DEF_FIG_AXES
		if (got_Bstring)		# Must check for spaces in titles, like in "ya10g10 +t\"Sector Diagram\""
			first = false
			for k in eachindex(opt_B)
				(opt_B[k] == '"') && (first = !first;	continue)	# Do not change more than once until become true again
				if (first && opt_B[k] == ' ')		# Replace space after a \" by the invisible ascii Char(127)
					opt_B = opt_B[1:k-1] * '\x7f' * opt_B[k+1:end]
					continue
				end
			end
		end
	end

	((val = find_in_dict(d, [:grid])[1]) !== nothing) && (opt_B = parse_grid(d, val, opt_B))

	function titlices(d::Dict, arg, fun::Function)
		# Helper function to deal with setting title & cousins while controling also Font & Offset 
		if (haskey(d, Symbol(fun)))
			if isa(arg, StrSymb)	
				farg = arg
				if (string(arg) == "auto")
					farg = (fun == xlabel) ? CTRL.XYlabels[1] : (fun == ylabel) ? CTRL.XYlabels[2] : "auto"
					(farg == "") && (farg = "auto")		# Can't take the risk of letting go a "". GMT would (Ghrr) error
				end
				_tt, a_par = replace(str_with_blancs(farg), ' '=>'\x7f'), ""
			else
				_tt, a_par = fun(;arg...)
			end
			delete!(d, Symbol(fun));
			_tt, a_par
		end
	end

	# Let the :title and x|y_label be given on main kwarg list. Risky if used with NamedTuples way.
	t::String = ""		# Use the trick to replace blanks by Char(127) (invisible) and undo it in extra_parse
	extra_par::String, tt::String, ep::String = "", "", ""
	if (haskey(d, :title))    tt, extra_par = titlices(d, d[:title], title); t *= "+t" * tt  end
	if (haskey(d, :subtitle)) tt, ep = titlices(d, d[:subtitle], subtitle);	 t *= "+s" * tt;   extra_par *= ep  end
	if (haskey(d, :xlabel))   tt, ep = titlices(d, d[:xlabel], xlabel);      t *= " x+l" * tt; extra_par *= ep  end
	if (haskey(d, :ylabel))   tt, ep = titlices(d, d[:ylabel], ylabel);      t *= " y+l" * tt; extra_par *= ep  end
	if (haskey(d, :zlabel))   tt, ep = titlices(d, d[:zlabel], zlabel);      t *= " z+l" * tt; extra_par *= ep  end

	if (t != "")
		if (opt_B == "" && (val = find_in_dict(d, [:xaxis :yaxis :zaxis :xticks :yticks :zticks], false)[1] === nothing))
			(!have_a_none) ? (opt_B = DEF_FIG_AXES_) : have_a_none = false	# False to not trigger the white@100 trick
		elseif (opt_B != "")			# Because  findlast("-B","") Errors!!!!!
			if !(((ind = findlast("-B",opt_B)) !== nothing || (ind = findlast(" ",opt_B)) !== nothing) &&
				 (occursin(r"[WESNwesntlbu+g+o]", opt_B[ind[1]:end])))
				t = " " * t;			# Do not glue, for example, -Bg with :title
			elseif (startswith(t, "+t") && (endswith(opt_B, "-Bafg") || endswith(opt_B, "-Baf") || endswith(opt_B, "-Ba")))
				t = " " * t;
			end
		end
		opt_B *= t;
		extra_parse = true
	end

	# These are not and we can have one or all of them. NamedTuples are dealt at the end
	is_still_Bdef = (opt_B == DEF_FIG_AXES_ || opt_B == DEF_FIG_AXES3_)
	for symb in [:xaxis :yaxis :zaxis :axis2 :xaxis2 :yaxis2]
		if (haskey(d, symb) && !isa(d[symb], NamedTuple) && !isa(d[symb], Dict))
			_ax::String = string(symb);
			_arg::String = string(d[symb])
			a::String = (_arg[1] != _ax[1]) ? string(_ax[1]) : ""	# This test avoids that :xaxis = "xg10" becomes xxg10
			_ps::String = (_ax[end] == '2') ? "s" : "p"
			opt_B = (is_still_Bdef) ? string(" -B", _ps, a, d[symb]) : string(opt_B, " -B", _ps, a, d[symb])
			is_still_Bdef, extra_parse = false, false
			delete!(d, symb)
		end
	end

	if (extra_parse && (opt_B != DEF_FIG_AXES[1] && opt_B != DEF_FIG_AXES3[1]))
		# This is old code that takes care to break a string in tokens and prefix with a -B to each token
		tok = Vector{String}(undef, 10)
		k = 1;		r = opt_B;		found = false
		while (r != "")
			tok[k], r = GMT.strtok(r)
			tok[k] = replace(tok[k], '\x7f'=>' ')
			tok[k] = (!occursin("-B", tok[k])) ? " -B" * tok[k] : " " * tok[k]
			k += 1
		end
		# Rebuild the B option string
		opt_B = ""
		for n = 1:k-1  opt_B *= tok[n]  end
	end

	# We can have one or all of them. Deal separatelly here to allow way code to keep working
	this_opt_B::String = "";
	xax, yax = false, false		# To know if these axis funs (primary) have been called
	for symb in [:yaxis2 :xaxis2 :axis2 :zaxis :yaxis :xaxis]
		add_this, what_B = false, [false, false]
		if (haskey(d, symb) && (isa(d[symb], NamedTuple) || isa(d[symb], Dict) || isa(d[symb], String)))
			isa(d[symb], Dict) && (d[symb] = Base.invokelatest(dict2nt, d[symb]))
			#(!have_axes) && (have_axes = isa(d[symb], NamedTuple) && any(keys(d[symb]) .== :axes))
			if     (symb == :axis2)   this_B, what_B = axis(d[symb], d, secondary=true); add_this = true
			elseif (symb == :xaxis)   this_B, what_B = axis(d[symb], d, x=true); add_this, xax = true, true
			elseif (symb == :xaxis2)  this_B, what_B = axis(d[symb], d, x=true, secondary=true); add_this = true
			elseif (symb == :yaxis)   this_B, what_B = axis(d[symb], d, y=true); add_this, yax = true, true
			elseif (symb == :yaxis2)  this_B, what_B = axis(d[symb], d, y=true, secondary=true); add_this = true
			elseif (symb == :zaxis)   this_B, what_B = axis(d[symb], d, z=true); add_this = true
			end
			(add_this) && (this_opt_B *= this_B)
			(isa(d[symb], String)) && (opt_B = "")		# For string input we must clear what's in opt_B
			have_Bframe = have_Bframe || what_B[2]
			delete!(d, symb)
		end
	end
	(xax && yax) && (opt_B = replace(opt_B, DEF_FIG_AXES_ => ""))	# If x&yaxis have been called, remove default
	(!isempty(opt_B) && (opt_B[1] == '+' || occursin(opt_B[1], "WSENZwsenzlrbtu"))) && (opt_B = " -B" * opt_B)	# If above has removed the " -B". Happens when (xaxis, yaxis, title)

	# These can come up outside of an ?axis tuple, so need to be seeked too.
	got_ticks = false		# To know if we may need to add -Baf when only x|y|z ticks were requested.
	for symb in [:xticks :yticks :zticks]
		if (haskey(d, symb))
			if     (symb == :xticks)  this_opt_B = " -Bpxc" * xticks(d[symb]) * this_opt_B;	delete!(d, symb)
			elseif (symb == :yticks)  this_opt_B = " -Bpyc" * yticks(d[symb]) * this_opt_B;	delete!(d, symb)
			elseif (symb == :zticks)  this_opt_B = " -Bpzc" * zticks(d[symb]) * this_opt_B;	delete!(d, symb)
			end
			got_ticks = true
		end
	end

	if (opt_B != DEF_FIG_AXES_ && opt_B != DEF_FIG_AXES3_)
		opt_B = contains(this_opt_B, "Bpx") && contains(this_opt_B, "Bpy") && startswith(opt_B, " -Baf") ?
			this_opt_B * opt_B[6:end] : this_opt_B * opt_B	# First case drops the starting " -Baf" (fragile...)
	elseif (this_opt_B != "")
		opt_B = this_opt_B
	end
	(got_ticks && opt_B == this_opt_B) && (opt_B *= (contains(opt_B, "-Bpz") ? DEF_FIG_AXES3_ : DEF_FIG_AXES_))	# When only x|y|z ticks were requested.

	if (DEF_FIG_AXES[1] != DEF_FIG_AXES_BAK && opt_B != DEF_FIG_AXES[1])	# Consolidation only under themes
		if (opt_B != "" && !got_Bstring && CTRL.proj_linear[1] && !occursin(DEF_FIG_AXES_, opt_B) &&
			!(occursin("pxc", opt_B) || occursin("pyc", opt_B)))
			# By using DEF_FIG_AXES_ this has no effect in modern mode.
			opt_B = ((have_Bframe) ? split(DEF_FIG_AXES_)[1] : DEF_FIG_AXES_) * opt_B
		end
		opt_B = consolidate_Baxes(opt_B)
	end
	opt_B = consolidate_Bframe(opt_B)
	(have_a_none) && (opt_B *= " --MAP_FRAME_PEN=0.001,white@100")	# Need to resort to this sad trick

	return cmd * opt_B * extra_par, opt_B
end

# ---------------------------------------------------------------------------------------------------
function consolidate_Bframe(opt_B::String)::String
	# Consolidate the 'frame' parte of a multi-pieces -B option and make sure that it comes out at the end
	s::Vector{SubString{String}} = split(opt_B)
	nosplit_spaces!(s)	# Check (and fix) that the above split did not split across multi words (e.g. titles)
	isBframe::Vector{Bool} = zeros(Bool, length(s))
	for k in eachindex(s)
		(occursin(s[k][3], "psxyzafgbc")) && (isBframe[k] = false; continue)	# A FALSE solves the quest imediately
		ss::Vector{SubString{String}} = split(s[k], "+");	len = length(ss)
		isBframe[k] = occursin(r"[WESNZwesnztlbu]", ss[1])	# Search for frame characters in the part before the +flag
		isBframe[k] && (len = 0)		# Tricky way of avoiding next loop when we already have the answer. 
		for kk = 2:len					# Start at 2 because first is never a target
			(occursin(ss[kk][1], "wbgxyzionts")) && (isBframe[k] = true; break)	# Search any of "+w+b+g+x+y+z+i+o+n+t+s"
		end
	end
	#for k = 1:length(s) println(isBframe[k], " ", s[k]) end
	# Example situation here: ["-Bpx+lx", "-B+gwhite", "-Baf", "-BWSen"] we want to join the 4rth & 2nd. NOT 2nd & 4rth
	indFrames = findall(isBframe);	len = length(indFrames)
	if (len > 1)
		ss_ = sort(s[indFrames], rev=true)			# OK, now we have them sorted like ["-BWSen" "-B+gwhite"]
		[ss_[1] *= ss_[k][3:end] for k = 2:len]		# Remove the first "-B" chars from second and on and join with first
		s[indFrames] .= ""							# Clear the Bframe elements from the original split
		opt_B = " " * s[1]
		for k = 2:lastindex(s)
			(s[k] != "") && (opt_B *= " " * s[k])	# Glue all the 'axes' members in a string
		end
		opt_B *= " " * ss_[1]						# and finally add also the the 'frame' part
	elseif (len == 1 && indFrames[1] != length(s))	# Shit, we have only one but it's not the last. Must swapp.
		s[end], s[indFrames[1]] = s[indFrames[1]], s[end]
		opt_B = " " * s[1]
		for k = 2:lastindex(s) opt_B *= " " * s[k] end	# and rebuild now with the right order.
	end
	return opt_B
end

# ---------------------------------------------------------------------------------------------------
function consolidate_Baxes(opt_B::String)::String
	# Consolidate a multi-pieces opt_B. Tries to join pieces that are joinable in terms of axes
	# components and interleaving of frame and axes settings that cause GMT parse errors. This is
	# a very difficult task and this function will likely fail for certain combinations.

	function helper_consolidate_B(opt_B::String, flag::String, have_Bpx::Bool, have_Bpy::Bool)::String
		if (have_Bpx && have_Bpy) opt_B = replace(opt_B, " -B" * flag => " -B")	# Have both, just remove the repeated 'a'
		elseif (have_Bpx)         opt_B = replace(opt_B, " -B" * flag => " -By" * flag)	# Add 'ya' because 'a' stands for both
		elseif (have_Bpy)         opt_B = replace(opt_B, " -B" * flag => " -Bx" * flag)
		else   opt_B
		end
	end

	(opt_B == "") && return ""
	# Detect the presence of 'a', 'f' or 'g' in the first -B axes settings token
	have_Bpxa, have_Bpya = occursin("Bpxa", opt_B), occursin("Bpya", opt_B)
	have_Bpa = occursin("Bpa", opt_B)		# Bpa worths Bpxa & Bpya
	have_Bpxa, have_Bpya = (have_Bpxa || have_Bpa), (have_Bpya || have_Bpa)
	have_Bpxf, have_Bpxg, got_x, have_Bpyf, have_Bpyg, got_y = false, false, false, false, false, false
	s = split(opt_B)
	nosplit_spaces!(s)	# Check (and fix) that the above split did not split across multi words sub-options
	for tok in s
		if (!got_x && startswith(tok, "-Bpx"))
			have_Bpxf, have_Bpxg, got_x = occursin("f", tok), occursin("g", tok), true;	continue
		elseif (!got_y && startswith(tok, "-Bpy"))
			have_Bpyf, have_Bpyg, got_y = occursin("f", tok), occursin("g", tok), true
		end
	end

	r = (s[1] == "-Bafg") ? " -Ba -Bf -Bg" : ((s[1] == "-Baf") ? " -Ba -Bf" : ((s[1] == "-Bag") ? " -Ba -Bg" : ((s[1] == "-Ba") ? " -Ba" : "")))
	(r != "") && (opt_B = replace(opt_B, s[1] => r))
	if (occursin("pxc", opt_B) || occursin("pyc", opt_B))
		# When we have a custom axis, make sure we don't have any automatic -Ba, -Bf or -Bg
		occursin("-Ba", opt_B) && (opt_B = replace(opt_B, "-Ba" => ""))
		occursin("-Bf", opt_B) && (opt_B = replace(opt_B, "-Bf" => ""))
		occursin("-Bg", opt_B) && (opt_B = replace(opt_B, "-Bg" => ""))
	end

	sdef = split(DEF_FIG_AXES[1])			# sdef[1] should contain only axes settings
	occursin("a", sdef[1]) && (opt_B = helper_consolidate_B(opt_B, "a", have_Bpxa, have_Bpya))
	occursin("f", sdef[1]) && (opt_B = helper_consolidate_B(opt_B, "f", have_Bpxf, have_Bpyf))
	occursin("g", sdef[1]) && (opt_B = helper_consolidate_B(opt_B, "g", have_Bpxg, have_Bpyg))
	opt_B = replace(opt_B, "-B " => "")		# Remove singleton "-B"

	s = split(opt_B)
	got_x, got_y = false, false
	for k = 1:length(s)-1
		if (startswith(s[k], "-Bpx") && startswith(s[k+1], "-Bpx") && s[k+1][5] != 'c')		# -Bpxc... cannot be glued
			s[k], s[k+1], got_x = s[k] * s[k+1][5:end], "", true
		elseif (startswith(s[k], "-Bpy") && startswith(s[k+1], "-Bpy") && s[k+1][5] != 'c')	# But very fragile
			s[k], s[k+1], got_y = s[k] * s[k+1][5:end], "", true
		end
	end
	if (got_x || got_y)
		opt_B = " " * s[1]
		for k = 2:lastindex(s)
			(s[k] != "") && (opt_B *= " " * s[k])	# Glue all the 'axes' members in a string
		end
	else
		opt_B = replace(opt_B, "   " => " ")		# Remove double spaces
		opt_B = replace(opt_B, "  "  => " ")		# Remove double spaces
	end
	opt_B
end

# ---------------------------------------------------------------------------------------------------
title(; str::AbstractString="",  font=nothing, offset=0) = titles_e_comp(str, font, offset)
subtitle(; str::AbstractString="", font=nothing, offset=0) = titles_e_comp(str, font, offset, "s")
xlabel(; str::AbstractString="", font=nothing, offset=0) = titles_e_comp(str, font, offset, "x")
ylabel(; str::AbstractString="", font=nothing, offset=0) = titles_e_comp(str, font, offset, "y")
zlabel(; str::AbstractString="", font=nothing, offset=0) = titles_e_comp(str, font, offset, "z")
function titles_e_comp(str::AbstractString, fnt, offset, tipo::String="")::Tuple{String, String}
	f::String = (fnt !== nothing) ? font(fnt) : ""
	o::String = (offset != 0) ? string(offset) : ""
	(str == "") && return str, ""
	if (tipo == "")
		r2 = (f != "") ? " --FONT_TITLE=" * f : ""
		(o != "") && (r2 *= " --MAP_TITLE_OFFSET=" * o)
	elseif (tipo == "s")
		r2 = (f != "") ? " --FONT_SUBTITLE=" * f : ""
	else
		r2 = (f != "") ? " --FONT_LABEL=" * f : ""
		(o != "") && (r2 *= " --MAP_LABEL_OFFSET=" * o)
	end
	replace(str_with_blancs(str), ' '=>'\x7f'), r2
end

# ---------------------------------------------------------------------------------------------------
function nosplit_spaces!(in)
	# A problem with spliting a B option is that it also splits the text strings with spaces (e.g. titles)
	# This function finds those cases and join back what were considered BadBreaks
	function glue()
		isBB = zeros(Bool, length(in))
		for k = 2:lastindex(in)
			if (!startswith(in[k], "-B"))	# Find elements that do not start with a "-B"
				in[k-1] *= " " * in[k]		# Join them with previous element (and keep the separating space)
				isBB[k] = true				# Flag elemento die
				break						# We can only do one at a time, so stop here.
			end
		end
		had_one = any(isBB)
		(had_one) && deleteat!(in, isBB)	# If we found one remove the now moved piece.
		had_one
	end
	while (glue()) glue() end				# While we had a BadBreak, scan it again.
end

# ---------------------------------------------------------------------------------------------------
function guess_WESN(d::Dict, cmd::String)::String
	# For automatic -B option settings add MAP_FRAME_AXES option such that only the two closest
	# axes will be annotated. For now this function is only used in 3D modules.
	if ((val = find_in_dict(d, [:p :view :perspective], false)[1]) !== nothing && (isa(val, Tuple) || isa(val, String)))
		if (isa(val, String))					# imshows sends -p already digested. Must reverse
			_val::Float64 = tryparse(Float64, split(val, "/")[1])
			quadrant = mod(div(_val, 90), 4)	# But since the angle is azim those are not the trig quadrants
		else
			quadrant = mod(div(val[1], 90), 4)
		end
		if     (quadrant == 0)  axs = "wsNEZ"	# Trig first quadrant
		elseif (quadrant == 1)  axs = "wSnEZ"	# Trig fourth quadrant
		elseif (quadrant == 2)  axs = "WSneZ"	# Trig third quadrant
		else   axs = "WseNZ"	# Trig second quadrant
		end
		cmd *= " --MAP_FRAME_AXES=" * axs
	end
	cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_BJR(d::Dict, cmd::String, caller::String, O::Bool, defaultJ::String="", del::Bool=true)
	# Join these three in one function. CALLER is non-empty when module is called by plot()
	cmd, opt_R = parse_R(d, cmd, O, del)
	cmd, opt_J = parse_J(d, cmd, defaultJ, true, O, del)

	parse_theme(d)		# Must be first because some themes change DEF_FIG_AXES
	is3D = (is_in_dict(d, [:JZ :Jz :zscale :zsize]) !== nothing)
	DEF_FIG_AXES_::String = (IamModern[1]) ? "" : is3D ? DEF_FIG_AXES3[1] : DEF_FIG_AXES[1]	# DEF_FIG_AXES is global

	if (caller != "" && occursin("-JX", opt_J))		# e.g. plot() sets 'caller'
		if (occursin("3", caller) || caller == "grdview")
			DEF_FIG_AXES3_::String = (IamModern[1]) ? "" : DEF_FIG_AXES3[1]
			cmd, opt_B = parse_B(d, cmd, (O ? "" : DEF_FIG_AXES3_), del)
		else
			xx::String = (O ? "" : caller != "ternary" ? DEF_FIG_AXES_ : string(split(DEF_FIG_AXES_)[1]))
			cmd, opt_B = parse_B(d, cmd, xx, del)	# For overlays, default is no axes
		end
	else
		cmd, opt_B = parse_B(d, cmd, (O ? "" : DEF_FIG_AXES_), del)
	end
	return cmd, opt_B, opt_J, opt_R
end

# ---------------------------------------------------------------------------------------------------
function parse_F(d::Dict, cmd::String)::String
	cmd = add_opt(d, cmd, "F", [:F :box], (clearance="+c", fill=("+g", add_opt_fill), inner="+i",
	                                       pen=("+p", add_opt_pen), rounded="+r", shaded=("+s", arg2str), shade=("+s", arg2str)) )
end

# ---------------------------------------------------------------------------------------------------
function parse_Td(d::Dict, cmd::String)::String
	cmd = parse_type_anchor(d, cmd, [:Td :rose],
							(map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), width="+w", justify="+j", fancy="+f", labels="+l", label="+l", offset=("+o", arg2str)), 'j')
end
function parse_Tm(d::Dict, cmd::String)::String
	cmd = parse_type_anchor(d, cmd, [:Tm :compass],
	                        (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), width="+w", dec="+d", justify="+j", rose_primary=("+i", add_opt_pen), rose_secondary=("+p", add_opt_pen), labels="+l", label="+l", annot=("+t", arg2str), offset=("+o", arg2str)), 'j')
end
function parse_L(d::Dict, cmd::String)::String
	cmd = parse_type_anchor(d, cmd, [:L :map_scale],
	                        (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), scale_at_lat="+c", length="+w", width="+w", align="+a1", justify="+j", fancy="_+f", label="+l", offset=("+o", arg2str), units="_+u", vertical="_+v"), 'j')
end

# ---------------------------------------------------------------------------------------------------
function parse_type_anchor(d::Dict, cmd::String, symbs::VMs, mapa::NamedTuple, def_CS::Char, del::Bool=true)
	# SYMBS: [:D :pos :position] | ...
	# MAPA is the NamedTuple of suboptions
	# def_CS is the default "Coordinate system". Colorbar has 'J', logo has 'g', many have 'j'
	(SHOW_KWARGS[1]) && return print_kwarg_opts(symbs, mapa)	# Just print the kwargs of this option call
	got_str = false
	for s in symbs		# Check if arg value is a string. If yes, ignore 'def_CS'
		(haskey(d, s) && isa(d[s], String)) && (got_str = true; break)
	end
	opt::String = add_opt(d, "", "", symbs, mapa, del)
	if (!got_str && opt != "" && opt[1] != 'j' && opt[1] != 'J' && opt[1] != 'g' && opt[1] != 'n' && opt[1] != 'x')
		opt = def_CS * opt
	end
	(opt != "") && (cmd = (symbs[1] != :_) ? cmd * " -" * string(symbs[1]) * opt : cmd * opt)
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_UXY(cmd::String, d::Dict, aliases, opt::Char)::String
	# Parse the global -U, -X, -Y options. Return CMD same as input if no option OPT in args
	# ALIASES: [:X :xshift :x_offset] (same for Y) or [:U :time_stamp :timestamp]
	val, symb = find_in_dict(d, aliases, true)
	if (val !== nothing)
		cmd::String = string(cmd, " -", opt, val)
	end
	# If -X|Y assume it's a new fig so plot any legend that may be trailing around.
	# This may screw but also screws if we don't do it. 
	(symb in [:X :xshift :x_offset :Y :yshift :y_offset]) && digests_legend_bag(d)
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_V(d::Dict, cmd::String)::String
	# Parse the global -V option. Return CMD same as input if no -V option in args
	if ((val = find_in_dict(d, [:V :verbose], true)[1]) !== nothing)
		if (isa(val, Bool) && val) cmd *= " -V"
		else                       cmd *= " -V" * arg2str(val)::String
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_V_params(d::Dict, cmd::String)
	# Parse the global -V option and the --PAR=val. Return CMD same as input if no options in args
	cmd = parse_V(d, cmd)
	return parse_params(d, cmd)
end

# ---------------------------------------------------------------------------------------------------
function parse_UVXY(d::Dict, cmd::String)
	cmd = parse_V(d, cmd)
	cmd = parse_UXY(cmd, d, [:X :x_offset :xshift], 'X')
	cmd = parse_UXY(cmd, d, [:Y :y_offset :yshift], 'Y')
	cmd = parse_UXY(cmd, d, [:U :time_stamp :timestamp], 'U')
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_a(d::Dict, cmd::String)
	# Parse the global -a option. Return CMD same as input if no -a option in args
	parse_helper(cmd, d, [:a :aspatial], " -a")
end

# ---------------------------------------------------------------------------------------------------
function parse_b(d::Dict, cmd::String, symbs::Array{Symbol}=[:b :binary], io::String="")
	# Parse the global -b option. Return CMD same as input if no -b option in args
	cmd_::String = add_opt(d, "", string(symbs[1])*io, symbs, 
	               (ncols=("", arg2str, 1), type=("", data_type, 2), swapp_bytes="_w", little_endian="_+l", big_endian="+b"))
	return cmd * cmd_, cmd_
end
parse_bi(d::Dict, cmd::String) = parse_b(d, cmd, [:b :bi :binary :binary_in],  "i")
parse_bo(d::Dict, cmd::String) = parse_b(d, cmd, [:b :bo :binary_out], "o")
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
function parse_c(d::Dict, cmd::String)::Tuple{String, String}
	# Most of the work here is because GMT counts from 0 but here we count from 1, so conversions needed
	opt_val::String = ""
	if ((val = find_in_dict(d, [:c :panel])[1]) !== nothing)
		if (isa(val, Tuple) || isa(val, Array{<:Real}) || isa(val, Integer))
			opt_val = arg2str(val .- 1, ',')
		elseif (isa(val, String) || isa(val, Symbol))
			_val::String = string(val)		# In case it was a symbol
			if ((ind = findfirst(",", _val)) !== nothing)	# Shit, user really likes complicating
				opt_val = string(parse(Int, val[1:ind[1]-1]) - 1, ',', parse(Int, _val[ind[1]+1:end]) - 1)
			elseif (_val != "" && _val != "next")
				opt_val = string(parse(Int, _val) - 1)
			end
		end
		cmd *= " -c" * opt_val
	end
	return cmd, opt_val
end

# ---------------------------------------------------------------------------------------------------
function parse_d(d::Dict, cmd::String, symbs::VMs=[:d :nodata])
	(SHOW_KWARGS[1]) && return (print_kwarg_opts(symbs, "$(symbs[2])=val"),"")
	parse_helper(cmd, d, [:d :nodata], " -d")
end
parse_di(d::Dict, cmd::String) = parse_d(d, cmd, [:di :nodata_in])
parse_do(d::Dict, cmd::String) = parse_d(d, cmd, [:do :nodata_out])
parse_e(d::Dict,  cmd::String) = parse_helper(cmd, d, [:e :pattern :find], " -e")
parse_g(d::Dict,  cmd::String) = parse_helper(cmd, d, [:g :gap], " -g")
parse_h(d::Dict,  cmd::String) = parse_helper(cmd, d, [:h :header], " -h")
parse_i(d::Dict,  cmd::String) = parse_helper(cmd, d, [:i :incols :incol], " -i", ',')
parse_j(d::Dict,  cmd::String) = parse_helper(cmd, d, [:j :spherical_dist :spherical], " -j")

# ---------------------------------------------------------------------------------
function parse_f(d::Dict, cmd::String)
	# For plotting time (-ft) in X one must add 'T' to -JX but that is boring and difficult to automatize
	# GMT6.3 now has it internal but previous versions no. So do that job here.
	cmd, opt_f = parse_helper(cmd, d, [:f :colinfo :coltypes :coltype], " -f")
	return cmd, opt_f
end

# ---------------------------------------------------------------------------------
function parse_l(d::Dict, cmd::String, del::Bool=false)
	cmd_::String = add_opt(d, "", "l", [:l :legend],
		(text=("", arg2str, 1), hline=("+D", add_opt_pen), vspace="+G", header="+H", image="+I", line_text="+L", n_cols="+N", ncols="+N", ssize="+S", start_vline=("+V", add_opt_pen), end_vline=("+v", add_opt_pen), font=("+f", font), fill="+g", justify="+j", offset="+o", frame_pen=("+p", add_opt_pen), width="+w", scale="+x"), del)
	# Now make sure blanks in legend text are wrapped in ""
	if ((ind = findfirst("+", cmd_)) !== nothing)
		cmd_ = " -l" * str_with_blancs(cmd_[4:ind[1]-1]) * cmd_[ind[1]:end]
	elseif (cmd_ != "")
		cmd_ = " -l" * str_with_blancs(cmd_[4:end])
	end
	(IamModern[1]) && (cmd *= cmd_)			# l option is only available in modern mode
	return cmd, cmd_
end

# ---------------------------------------------------------------------------------
function parse_n(d::Dict, cmd::String, gmtcompat::Bool=false)
	# Parse the global -n option. Return CMD same as input if no -n option in args
	# The GMTCOMPAT arg is used to reverse the default aliasing in GMT, which is ON by default
	# However, practise has shown that this makes projecting images significantly slower with not clear benefits
	cmd_::String = add_opt(d, "", "n", [:n :interp :interpolation], 
				   (B_spline=("b", nothing, 1), bicubic=("c", nothing, 1), bilinear=("l", nothing, 1), near_neighbor=("n", nothing, 1), aliasing="_+a", antialiasing="_-a", bc="+b", clipz="_+c", threshold="+t"))
	# Some gymnics to make aliasing de default (contrary to GMT default). Use antialiasing=Any to revert this.
	if (!gmtcompat)
		if (cmd_ != "" && !occursin("+a", cmd_)) 
			cmd_ = (occursin("-a", cmd_)) ? replace(cmd_, "-a" => "") : cmd_ * "+a"
			(cmd_ == " -n") && (cmd_ = "")	# Happens when only n="-a" was transmitted.
		elseif (cmd_ == "")
			cmd_ *= " -n+a"		# Default to no-aliasing. Antialising on map projection is very slow and often not needed.
		end
	end
	return cmd * cmd_, cmd_
end

# ---------------------------------------------------------------------------------
parse_o(d::Dict, cmd::String) = parse_helper(cmd, d, [:o :outcols :outcol], " -o", ',')
parse_p(d::Dict, cmd::String) = parse_helper(cmd, d, [:p :view :perspective], " -p")

# ---------------------------------------------------------------------------------
function parse_q(d::Dict, cmd::String)
	parse_helper(cmd, d, [:q :inrow :inrows], " -q")
	parse_helper(cmd, d, [:qo :outrow :outrows], " -qo")
end

# ---------------------------------------------------------------------------------------------------
# Parse the global -: option. Return CMD same as input if no -: option in args
# But because we can't have a variable called ':' we use only the aliases
parse_swap_xy(d::Dict, cmd::String) = parse_helper(cmd, d, [:yx :swap_xy], " -:")

# ---------------------------------------------------------------------------------------------------
# Parse the global -? option. Return CMD same as input if no -? option in args
parse_s(d::Dict, cmd::String) = parse_helper(cmd, d, [:s :skiprows :skip_NaN], " -s")
parse_x(d::Dict, cmd::String) = parse_helper(cmd, d, [:x :cores :n_threads], " -x")

# ---------------------------------------------------------------------------------------------------
function parse_w(d::Dict, cmd::String)
	# -wy|a|w|d|h|m|s|cperiod[/phase][+ccol]
	val, symb = find_in_dict(d, [:w :wrap :cyclic], false)
	(val === nothing) && return cmd, ""
	if isa(val, StrSymb)
		t = string(val)::String
		if (contains(t, "+c") || contains(t, '/'))	# Contains a period/phase or column form, assume a plain GMT opt
			delete!(d, symb)
			t = " -w" * t
			return cmd * t, t
		end
		opt_w::String = (t[1] == 'y' || t[1] == 'a' || t[1] == 'w' || t[1] == 'd' || t[1] == 'h' || t[1] == 'm' || t[1] == 's') ? string(" -w", t[1]) : error("Bad coordinate name ($t) for option 'cyclic'")
	elseif (isa(val, Real))
		opt_w = string(" -wc", val)::String
	elseif (isa(val, Tuple) && eltype(val) <: Real)		# custom passed in as w=(period, phase)
		opt_w = " -wc" * arg2str(val)
	else
		opt_w = add_opt(d, "", "w", [:w :wrap :cyclic],
		                (year=("y", nothing, 1), annual=("a", nothing, 1), week=("w", nothing, 1), day=("d", nothing, 1),  hour=("h", nothing, 1), minute=("m", nothing, 1), second=("s", nothing, 1), period=("c", arg2str, 1), col=("+c", arg2str)))
	end
	return cmd * opt_w, opt_w
end

# ---------------------------------------------------------------------------------------------------
function parse_r(d::Dict, cmd::String, del::Bool=true)
	# Accept both numeric (0 or != 0) and string/symbol arguments
	opt_val::String = ""
	if ((val = find_in_dict(d, [:r :reg :registration], del)[1]) !== nothing)
		(isa(val, String) || isa(val, Symbol)) && (opt_val = string(" -r",val)[1:4])
		(isa(val, Integer)) && (opt_val = (val == 0) ? " -rg" : " -rp")
		cmd *= opt_val
	end
	return cmd, opt_val
end

# ---------------------------------------------------------------------------------------------------
function parse_t(d::Dict, cmd::String, del::Bool=true)
	opt_val::String = ""
	if ((val = find_in_dict(d, [:t :alpha :transparency], del)[1]) !== nothing)
		(val == "" || val == 0) && return cmd, ""		# To allow programatically calls were -t is unknown
		t::Float64 = (isa(val, String)) ? parse(Float64, val) : Float64(val)
		if (t < 1) t *= 100  end
		opt_val = string(" -t", t)
		cmd *= opt_val
	end
	return cmd, opt_val
end

# ---------------------------------------------------------------------------------------------------
function parse_write(d::Dict, cmd::String)::String
	if ((val = find_in_dict(d, [:write :savefile :|>], true)[1]) !== nothing)
		cmd *=  " > " * val::String
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_append(d::Dict, cmd::String)::String
	if ((val = find_in_dict(d, [:append], true)[1]) !== nothing)
		cmd *=  " >> " * val::String
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_helper(cmd::String, d::Dict, symbs::VMs, opt::String, sep='/')
	# Helper function to the parse_?() global options.
	(SHOW_KWARGS[1]) && return (print_kwarg_opts(symbs, "(Common option not yet expanded)"),"")
	opt_val::String = ""
	if ((val = find_in_dict(d, symbs, true)[1]) !== nothing)
		opt_val = opt * arg2str(val, sep)::String
		cmd *= opt_val
	end
	return cmd, opt_val
end

# ---------------------------------------------------------------------------------------------------
function parse_common_opts(d::Dict, cmd::String, opts::VMs, first::Bool=true)
	(SHOW_KWARGS[1]) && return (print_kwarg_opts(opts, "(Common options)"),"")	# Just print the options

	ignore_J, ignore_R, ignore_p, ignore_t = false, false, false, false
	cmd, _cmd = GMTsyntax_opt(d, cmd)		# See if an hardcore GMT syntax string has been passed
	if (_cmd != "")							# Yes, it was. Take care wont repeat from inheritances.
		ignore_p = (:p in opts) && contains(_cmd, " -p")
		ignore_t = (:t in opts) && contains(_cmd, " -t")
		ignore_J = (:J in opts) && contains(_cmd, " -J")
		ignore_R = (:R in opts) && contains(_cmd, " -R")
	end
	
	opt_p = nothing;	o::String = ""
	for opt in opts
		if     (opt == :RIr)  cmd, o = parse_RIr(d, cmd)
		elseif (opt == :R && !ignore_R)  cmd, o = parse_R(d, cmd)
		elseif (opt == :I)  cmd  = parse_I(d, cmd, [:I :inc :increment :spacing], "I")
		elseif (opt == :J && !ignore_J)  cmd, o = parse_J(d, cmd)
		elseif (opt == :JZ) cmd, o = parse_JZ(d, cmd)
		elseif (opt == :G)  cmd, = parse_G(d, cmd)
		elseif (opt == :F)  cmd  = parse_F(d, cmd)
		elseif (opt == :UVXY)     cmd = parse_UVXY(d, cmd)
		elseif (opt == :V_params) cmd = parse_V_params(d, cmd)
		elseif (opt == :a)  cmd, o = parse_a(d, cmd)
		elseif (opt == :b)  cmd, o = parse_b(d, cmd)
		elseif (opt == :c)  cmd, o = parse_c(d, cmd)
		elseif (opt == :bi) cmd, o = parse_bi(d, cmd)
		elseif (opt == :bo) cmd, o = parse_bo(d, cmd)
		elseif (opt == :d)  cmd, o = parse_d(d, cmd)
		elseif (opt == :di) cmd, o = parse_di(d, cmd)
		elseif (opt == :do) cmd, o = parse_do(d, cmd)
		elseif (opt == :e)  cmd, o = parse_e(d, cmd)
		elseif (opt == :f)  cmd, o = parse_f(d, cmd)
		elseif (opt == :g)  cmd, o = parse_g(d, cmd)
		elseif (opt == :h)  cmd, o = parse_h(d, cmd)
		elseif (opt == :i)  cmd, o = parse_i(d, cmd)
		elseif (opt == :j)  cmd, o = parse_j(d, cmd)
		elseif (opt == :l)  cmd, o = parse_l(d, cmd)
		elseif (opt == :n)  cmd, o = parse_n(d, cmd)
		elseif (opt == :o)  cmd, o = parse_o(d, cmd)
		elseif (opt == :p && !ignore_p)  cmd, opt_p = parse_p(d, cmd)
		elseif (opt == :r)  cmd, o = parse_r(d, cmd)
		elseif (opt == :s)  cmd, o = parse_s(d, cmd)
		elseif (opt == :x)  cmd, o = parse_x(d, cmd)
		elseif (opt == :t && !ignore_t)  cmd, o = parse_t(d, cmd)
		elseif (opt == :w)  cmd, o = parse_w(d, cmd)
		elseif (opt == :yx) cmd, o = parse_swap_xy(d, cmd)
		elseif (opt == :params)   cmd = parse_params(d, cmd)
		elseif (opt == :write)    cmd = parse_write(d, cmd)
		elseif (opt == :append)   cmd = parse_append(d, cmd)
		end
	end
	if (opt_p !== nothing)		# Restrict the contents of this block to when -p was used
		if (opt_p != "")
			if (opt_p == " -pnone")  CURRENT_VIEW[1] = "";	cmd = cmd[1:end-7];	opt_p = ""
			elseif (startswith(opt_p, " -pa") || startswith(opt_p, " -pd"))
				CURRENT_VIEW[1] = " -p210/30";
				cmd = replace(cmd, opt_p => "") * CURRENT_VIEW[1]::String		# auto, def, 3d
			else
				CURRENT_VIEW[1] = opt_p
			end
		elseif (!first && CURRENT_VIEW[1] != "")
			cmd *= CURRENT_VIEW[1]::String
		elseif (first)
			CURRENT_VIEW[1] = ""		# Ensure we start empty
		end
	end
	#cmd   = GMTsyntax_opt(d, cmd)		# See if an hardcore GMT syntax string has been passed
	((val = find_in_dict(d, [:pagecolor])[1]) !== nothing) && (cmd *= string(" --PS_PAGE_COLOR=", val)::String)
	return cmd, o
end

# ---------------------------------------------------------------------------------------------------
function parse_theme(d::Dict, del::Bool=true)
	# This must always be processed before parse_B so it's the first call in that function
	if ((val = find_in_dict(d, [:theme], del)[1]) !== nothing)
		isa(val, NamedTuple) && theme(string(val[1])::String; nt2dict(val)...)
		(isa(val, String) || isa(val, Symbol)) && theme(string(val)::String)
	end
end

# ---------------------------------------------------------------------------------------------------
function parse_these_opts(cmd::String, d::Dict, opts, del::Bool=true)::String
	# Parse a group of options that individualualy would had been parsed as (example):
	# cmd = add_opt(d, cmd, "A", [:A :horizontal])
	for opt in opts
		cmd = add_opt(d, cmd, string(opt[1]), opt, nothing, del)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
# This is not a global option but it repeats at many occasions.
parse_G(d::Dict, cmd::String) = parse_helper(cmd, d, [:G :save :write :outgrid :outfile], " -G")

# ---------------------------------------------------------------------------------------------------
function parse_I(d::Dict, cmd::String, symbs, opt::String, del::Bool=true)::String
	# Parse the quasi-global -I option. But arguments can be strings, arrays, tuples or NamedTuples
	# At the end we must recreate this syntax: xinc[unit][+e|n][/yinc[unit][+e|n]] or
	get_that_string(arg)::String = string(arg)::String		# Function barrier. Shuting up JET, etc.

	if ((val = find_in_dict(d, symbs, del)[1]) !== nothing)
		isa(val, Dict) && (val = Base.invokelatest(dict2nt,val))
		if (isa(val, NamedTuple))
			x::String = "";	y::String = "";	u::String = "";	e = false
			fn = fieldnames(typeof(val))
			for k = 1:numel(fn)
				if     (fn[k] == :x)     x  = get_that_string(val[k])
				elseif (fn[k] == :y)     y  = get_that_string(val[k])
				elseif (fn[k] == :unit)  u  = get_that_string(val[k])
				elseif (fn[k] == :extend) e = true
				end
			end
			(x == "") && error("Need at least the x increment")
			cmd = string(cmd, " -", opt, x)
			if (u != "")
				u = parse_unit_unit(u)
				(u != "u") && (cmd *= u)		# "u" is only for the `scatter` modules
			end
			(e) && (cmd *= "+e")
			if (y != "")
				cmd = string(cmd, "/", y, u)
				(e) && (cmd *= "+e")			# Should never have this and u != ""
			end
		else
			if (opt != "")  cmd  = string(cmd, " -", opt, arg2str(val))
			else            cmd *= arg2str(val)::String
			end
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_params(d::Dict, cmd::String, del::Bool=true)::String
	# Parse the gmt.conf parameters when used from within the modules. Return a --PAR=val string
	# The input to this kwarg can be a tuple (e.g. (PAR,val)) or a NamedTuple (P1=V1, P2=V2,...)

	((val = find_in_dict(d, [:conf :par :params], del)[1]) === nothing) && return cmd
	_cmd::String = deepcopy(cmd)
	isa(val, Dict) && (val = Base.invokelatest(dict2nt,val))
	(!isa(val, NamedTuple) && !isa(val, Tuple)) && @warn("BAD usage: Parameter is neither a Tuple or a NamedTuple")
	if (isa(val, NamedTuple))
		fn = fieldnames(typeof(val))
		for k = 1:numel(fn)		# Suspect that this is higly inefficient but N is small
			_cmd *= " --" * string(fn[k])::String * "=" * string(val[k])::String
		end
	elseif (isa(val, Tuple))
		_cmd *= " --" * string(val[1])::String * "=" * string(val[2])::String
	end
	usedConfPar[1] = true
	return _cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt_pen(d::Dict, symbs::Union{Nothing, VMs}, opt::String="", del::Bool=true)::String
	# Build a pen option. Input can be either a full hard core string or spread in lw (or lt), lc, ls, etc or a tuple

	(SHOW_KWARGS[1]) && return print_kwarg_opts(symbs, "NamedTuple | Tuple | String | Number")	# Just print the options

	if (opt != "")  opt = " -" * opt  end		# Will become -W<pen>, for example
	out::String = ""
	pen::String = build_pen(d, del)				# Either a full pen string or empty ("") (Seeks for lw (or lt), lc, etc)
	if (pen != "")
		out = opt * pen
	else
		if ((val = find_in_dict(d, symbs, del)[1]) !== nothing)
			isa(val, Dict) && (val = Base.invokelatest(dict2nt, val))
			if (isa(val, Tuple))				# Like this it can hold the pen, not extended atts
				if (isa(val[1], NamedTuple))	# Then assume they are all NTs
					for v in val
						d2 = nt2dict(v)			# Decompose the NT and feed it into this-self
						out *= opt * add_opt_pen(d2, symbs, "", false)
					end
				else
					out = opt * parse_pen(val)	# Should be a better function
				end
			elseif (isa(val, NamedTuple))		# Make a recursive call. Will screw if used in mix mode
				# This branch is very convoluted and fragile
				# Cases like pen=(width=0.1, color=:red, style=".") were failing. But because we may break other
				# working cases, just try to catch this case and turn it into a `pen=(0.1, :red. ".")` call.
				k = keys(val)
				w::String = (:width in k) ? string(val[:width]) : ""
				c::String = (:color in k) ? string(val[:color]) : ""
				s::String = (:style in k) ? string(val[:style]) : ""
				if (w != "" || c != "" || s != "")
					out = opt * add_opt_pen(Dict(:pen => (w,c,s)), symbs, "", false)
				else
					d2 = nt2dict(val)				# Decompose the NT and feed into this-self
					t = add_opt_pen(d2, symbs, "", false)
					if (t == "")
						d, out = nt2dict(val), opt
					else
						out = opt * t
						d = Dict{Symbol,Any}()		# Just let it go straight to end. Returning here seems bugged
					end
				end
			else
				(val != :none && val != "none") && (out = opt * arg2str(val)::String)
			end
		end
	end

	# All further options prepend or append to an existing pen. So, if empty we are donne here.
	(out == "") && return out

	# -W in ps|grdcontour may have extra flags at the begining but take care to not prepend on a blank
	if     (out[1] != ' ' && haskey(d, :cont) || haskey(d, :contour))  out = "c" * out
	elseif (out[1] != ' ' && haskey(d, :annot))                        out = "a" * out
	end

	# Some -W take extra options to indicate that color comes from CPT
	if (haskey(d, :colored))  out *= "+c"
	elseif (find_in_dict(d, [:zlevel :zlevels])[1] !== nothing) out *= "+z"
	else
		((val = find_in_dict(d, [:cline :color_line :color_lines])[1]) !== nothing) && (out *= "+cl")
		((val = find_in_dict(d, [:ctext :color_text :color_symbols :color_symbol])[1]) !== nothing) && (out *= "+cf")
	end
	if (haskey(d, :bezier))  out *= "+s";  delete!(d, [:bezier])  end
	if (haskey(d, :offset))  out *= "+o" * arg2str(d[:offset])::String   end

	if (out != "")		# Search for eventual vec specs, but only if something above has activated -W
		v = false
		r = helper_arrows(d)
		if (r != "")
			if (haskey(d, :vec_start))  out *= "+vb" * r[2:end];  v = true  end	# r[1] = 'v'
			if (haskey(d, :vec_stop))   out *= "+ve" * r[2:end];  v = true  end
			if (!v)  out *= "+" * r  end
		end
	end

	return out
end

# ---------------------------------------------------------------------------------------------------
function opt_pen(d::Dict, opt::Char, symbs::VMs)::String
	# Create an option string of the type -Wpen
	(SHOW_KWARGS[1]) && return print_kwarg_opts(symbs, "Tuple | String | Number")	# Just print the options

	out::String = ""
	pen = build_pen(d)						# Either a full pen string or empty ("")
	if (!isempty(pen))
		out = string(" -", opt, pen)
	else
		if ((val = find_in_dict(d, symbs)[1]) !== nothing)
			if (isa(val, String) || isa(val, Real) || isa(val, Symbol))
				out = string(" -", opt, val)
			elseif (isa(val, Tuple))	# Like this it can hold the pen, not extended atts
				out = string(" -", opt, parse_pen(val))
			else
				error(string("Nonsense in ", opt, " option"))
			end
		end
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
parse_pen(pen::Real)::String = string(pen)
parse_pen(pen::Symbol)::String = string(pen)
parse_pen(pen::String)::String = pen
function parse_pen(pen::Tuple)::String
	# Convert an empty to 3 args tuple containing (width[c|i|p]], [color], [style[c|i|p|])
	s::String = arg2str(pen[1])					# First arg is different because there is no leading ','
	if (length(pen) > 1)
		s *= ',' * get_color(pen[2])
		if (length(pen) > 2)
			ls::String = arg2str(pen[3])
			_ls = lowercase(ls)
			if     (startswith(_ls, "dashdot"))     ls = "-."
			elseif (startswith(_ls, "dashdashdot")) ls = "--."
			elseif (startswith(_ls, "dash"))        ls = "-"
			elseif (startswith(_ls, "dotdotdash"))  ls = "..-"
			elseif (startswith(_ls, "dot"))         ls = "."
			end
			s *= ',' * ls
		end
	end
	return s
end

# ---------------------------------------------------------------------------------------------------
function parse_pen_color(d::Dict, symbs=nothing, del::Bool=false)::String
	# Need this as a separate fun because it's used from modules
	lc::String = ""
	(symbs === nothing) && (symbs = [:lc :linecolor])
	if ((val = find_in_dict(d, symbs, del)[1]) !== nothing)
		lc = string(get_color(val))
	end
	return lc
end

# ---------------------------------------------------------------------------------------------------
function build_pen(d::Dict, del::Bool=false)::String
	# Search for lw, lc, ls in d and create a pen string in case they exist
	# If no pen specs found, return the empty string ""

	val, symb = find_in_dict(d, [:lw :lt :linewidth :linethick :linethickness], false)
	if (isa(val, VMr))			# Got a line thickness variation.
		if (!haskey(d, :multicol))	# 'multicol' is a separate story (till when?)
			delete!(d, symb)		# Remove it now because it wasn't in the find_in_dict() call above
			d[:var_lt] = val		# This particular one is going to be fetch in _helper_psxy_line()
		end
		lw::String = ""
	else
		lw = add_opt(d, "", "", [:lw :lt :linewidth :linethick :linethickness], nothing, del)	# Line width
	end
	(lw == "" && find_in_dict(d, [:line])[1] !== nothing) && (lw = "0.5p")	# Means, accept also line=true

	ls::String = add_opt(d, "", "", [:ls :linestyle], nothing, del)			# Line style
	lc::String = parse_pen_color(d, [:lc :linecolor], del)
	out::String = ""
	if (lw != "" || lc != "" || ls != "")
		out = lw * "," * lc * "," * ls
		while (out[end] == ',')  out = rstrip(out, ',')  end	# Strip unneeded commas
	end
	return out
end

# ----------------------------------------------------------------------------------------------------------
function break_pen(pen::AbstractString)::Tuple{String, String, String}
	# Break up a pen string in its three tokens. PEN can be "lw,lc,ls", or "lw,ls", or ",,ls" etc.
	(pen == "") && return "", "", ""
	sp = split(pen, ',')
	lw::String, lc::String, ls::String = string(sp[1]), "", ""
	(length(sp) == 3) && (ls = string(sp[3]))
	if (length(sp) > 1)
		t2 = lowercase(sp[2])
		(startswith(t2, "da") || startswith(t2, "do") || contains(t2, "_")) && (ls = t2)	# That "_" is risky.
		(length(sp) == 2 && ls != "") && return lw, "", ls	# We are done here. Got a pen="linewidth,linestile"
		# OK, arrived here means `ls` is either in 3 or non-existent so pos 2 must contain `lc` (or empty)
		lc = t2
	end
	return lw, lc, ls
end

# ---------------------------------------------------------------------------------------------------
function parse_arg_and_pen(arg::Tuple, sep::String="/", pen::Bool=true, opt::String="")::String
	# Parse an ARG of the type (arg, (pen)) and return a string. These may be used in pscoast -I & -N
	# OPT is the option code letter including the leading - (e.g. -I or -N). This is only used when
	# the ARG tuple has 4, 6, etc elements (arg1,(pen), arg2,(pen), arg3,(pen), ...)
	# When pen=false we call the get_color function instead
	# SEP is normally "+g" when this function is used in the "parse_arg_and_color" mode
	if (isa(arg[1], String) || isa(arg[1], Symbol) || isa(arg[1], Real))  s::String = string(arg[1])
	else	error("parse_arg_and_pen: Nonsense first argument")
	end
	if (length(arg) > 1)
		if (isa(arg[2], Tuple))  s *= sep::String * (pen ? parse_pen(arg[2]) : get_color(arg[2]))::String
		else                     s *= sep::String * string(arg[2])::String		# Whatever that is
		end
	end
	if (length(arg) >= 4) s *= " " * opt::String * parse_arg_and_pen((arg[3:end]))::String end		# Recursive call
	return s
end

# ---------------------------------------------------------------------------------------------------
function parse_ls_code!(d::Dict)
	if ((val = find_in_dict(d, [:ls :linestyle])[1]) !== nothing)
		if (isa(val, String) && (val[1] == '-' || val[1] == '.' || isdigit(val[1])))
			d[:ls] = val	# Assume it's a "--." or the more complex len_gap_len_gap... form. So reset it and return
		else
			o = mk_styled_line!(d, val)
			(o !== nothing) && (d[:ls] = o)		# Means used an option like for example ls="DashDot"
		end
	end
	return nothing
end

function mk_styled_line!(d::Dict, code)
	# Parse the CODE string and generate line style. These line styles can be a single annotated line with symbols
	# or two lines, one a plain line and the other the symbols to plot. This is achieved by tweaking the D dict
	# and inserting in it the members that the common_plot_xyz function is expecting.
	# To get the first type use CODEs as "LineCirc" or "DashDotSquare" or "LineTriang#". The last form will invert
	# the way the symbol is plotted by drawing a white outline and a filled circle, making it similar to GitHub Traffic.
	# The second form (annotated line) requires separating the style and marker name by a '&', '_' or '!'. The last
	# two ways allow sending CODE as a Symbol (e.g. :line!circ). Enclose the "Symbol" in a pair of those markersize
	# to create an annotated line instead. E.g. ls="Line&Bla Bla Bla&"
	isa(code, Symbol) && (code = string(code)::String)
	_code::String = lowercase(code)
	inv = !isletter(code[end])					# To know if we want to make white outline and fill = lc
	is1line = (occursin("&", _code) || occursin("_", _code) || occursin("!", _code))	# e.g. line&Circ
	decor_str = false
	if (is1line && (_code[end] == '&' || _code[end] == '_' || _code[end] == '!') &&		# For case code="Dash&Bla Bla&"
		(length(findall("&",_code)) == 2 || length(findall("_",_code)) == 2 || length(findall("!",_code)) == 2))
		decor_str, inv = true, true				# Setting inv=true is an helper. It avoids reading the flag as part of text
	end

	if     (startswith(_code, "line"))        ls = "";     symbol = (length(_code) == 4)  ? "" : code[5 + is1line : end-inv]
	elseif (startswith(_code, "dashdot"))     ls = "-.";   symbol = (length(_code) == 7)  ? "" : code[8 + is1line : end-inv]
	elseif (startswith(_code, "dashdashdot")) ls = "--.";  symbol = (length(_code) == 11) ? "" : code[12+ is1line : end-inv]
	elseif (startswith(_code, "dash"))        ls = "-";    symbol = (length(_code) == 4)  ? "" : code[5 + is1line : end-inv]
	elseif (startswith(_code, "dotdotdash"))  ls = "..-";  symbol = (length(_code) == 10) ? "" : code[11+ is1line : end-inv]
	elseif (startswith(_code, "dot"))         ls = ".";    symbol = (length(_code) == 3)  ? "" : code[4 + is1line : end-inv]
	elseif (startswith(_code, "front"))       ls = "";     symbol = (length(_code) == 5)  ? "" : _code[6 + is1line : end]
	else   error("Bad line style. Options are (for example) [Line|DashDot|Dash|Dot]Circ")
	end

	(symbol == "") && return ls		# It means only the line style was transmitted. Return to allow use as ls="DashDot"

	lc::String = parse_pen_color(d, [:lc :linecolor], false)
	(lc == "") && (lc = "black")
	lw::String = add_opt(d, "", "", [:lw :linewidth])		# Line width
	d[:ls] = ls										# The linestyle picked above
	d[:lw] = (lw != "") ? lw : "0.75"
	isfront = (_code[1] == 'f')

	if (is1line || isfront)							# e.g. line&Circ or line_Triang or line!Square
		if (decor_str)
			d[:compact] = line_decorated_with_string(symbol)
		else
			d[:compact] = line_decorated_with_symbol(d, isfront, lw=lw, lc=lc, symbol=symbol)
		end
	else											# e.g. lineCirc
		marca = get_marker_name(Dict(:marker => symbol), nothing, [:marker], false)[1]	# This fun lieves in psxy.jl
		(marca == "") && error("The selected symbol [$(symbol)] is invalid")
		noinv_ML = isletter(code[end])				# If false, by default use a white outline and a fill color

		# Fill the symbol with WHITE or line color or :mc if that was used
		def_fill = (noinv_ML) ? "white" : lc
		_fill = ((c = add_opt_fill("", d, [:G :mc :markercolor :markerfacecolor :MarkerFaceColor], "")) != "") ? c : def_fill

		# Get the markerline. It can have a color set automatically (white or :lc) or explicitly set by using :ml
		def_ML = (noinv_ML) ? (lc == "") ? d[:lw] : (d[:lw], lc) : (d[:lw], "white")
		_ml = ((opt_ML = parse_markerline(d, "", "")[1]) != "") ? opt_ML[4:end] : def_ML

		d[:marker], d[:ml], d[:mc] = marca, _ml, _fill
		if ((find_in_dict(d, [:ms :markersize :MarkerSize], false)[1]) === nothing)	# If ms explicitly set, takes precedence
			f = (noinv_ML) ? 5 : 6		# Multiplying factor for the symbol size. But this can be overuled by using :ms
			d[:ms] = string(round(f * parse(Float64,d[:lw]) * 2.54/72, digits=2))
		end
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function line_decorated_with_symbol(d::Dict, isfront::Bool=false; lw=0.75, lc="black", ms=0, symbol="circ", dist=0, fill="white")::String
	# Create an Annotated line with few controls. We estimate the symbol size after the line thickness.
	(lc == "") && (lc = "black")
	_lw = (lw == "") ? 0.75 : isa(lw, String) ? parse(Float64, lw) : lw		# If last case is not numeric ...
	_ss = (ms != 0) ? ms : round(4 * _lw * 2.54/72, digits=2)
	ss = ((val = find_in_dict(d, [:ms :markersize :MarkerSize])[1]) !== nothing) ? val : _ss	# Let ms be used here
	_dist = (dist == 0) ? 8_ss : dist * _ss		# Compute dist/gap based on size obtained from line width and not :ms
	def_fill = (isfront) ? lc : fill
	_fill = ((c = add_opt_fill("", d, [:G :mc :markercolor :markerfacecolor :MarkerFaceColor], "")) != "") ? c : def_fill
	_ml = ((opt_ML = parse_markerline(d, "", "")[1]) != "") ? opt_ML[4:end] : lc
	(isfront) ? line_front(d, _dist, _lw, _ml, _fill, symbol, ss) :
	            decorated(dist=_dist, symbol=symbol, size=ss, pen=(_lw, _ml), fill=_fill, dec2=true)
end

# ---------------------------------------------------------------------------------------------------
function line_front(d::Dict, gap, lw, lc, fill, symbol, ss)::String
	d[:G] = fill
	if (symbol[1] == 's')				# Arrows (slips) are tricky
		ss *= 4;	gap *= 2
		(!endswith(symbol, "left") && !endswith(symbol, "right")) && (symbol *= "right")	# Must have one of them.
	end
	nt = (dist=gap, symbol=symbol, size=ss, pen=(lw,lc))		# Create a NT with args so we can increase it
	endswith(symbol, "left")  && (nt = merge(nt, (left=1,)))	# in case we need it.
	endswith(symbol, "right") && (nt = merge(nt, (right=1,)))
	decorated(; nt...)
end

# ---------------------------------------------------------------------------------------------------
function line_decorated_with_string(str::AbstractString; dist=0)::String
	# Create an Quoted line with few controls.
	str_len = length(str) * 4 * 2.54/72		# Very rough estimate of line length assuming a font of ~9 pts
	_dist = (dist == 0) ? max(3, round(str_len * 3, digits=1)) : dist	# Simple heuristic to estimate dist
	decorated(dist=_dist, const_label=str, quoted=true, curved=true)
end

# ---------------------------------------------------------------------------------------------------
function arg2str(d::Dict, symbs)::String
	# Version that allow calls from add_opt()
	return ((val = find_in_dict(d, symbs)[1]) !== nothing) ? arg2str(val) : ""
end

# ---------------------------------------------------------------------------------------------------
function arg2str(arg, sep='/')::String
	# Convert an empty, a numeric or string ARG into a string ... if it's not one to start with
	# ARG can also be a Bool, in which case the TRUE value is converted to "" (empty string)
	# SEP is the char separator used when ARG is a tuple or array of numbers
	if (isa(arg, AbstractString) || isa(arg, Symbol))
		out::String = string(arg)::String
		if (occursin(" ", out) && !startswith(out, "\""))	# Wrap it in quotes
			out = "\"" * out * "\""
		end
	elseif ((isa(arg, Bool) && arg) || isempty_(arg))
		out = ""
	elseif (isa(arg, Real))		# Have to do it after the Bool test above because Bool is a Number too
		out = @sprintf("%.12g", arg)::String
	elseif (isa(arg, Array{<:Real}) || (isa(arg, Tuple) && !isa(arg[1], String)) )
		out = join([string(x, sep)::String for x in arg])
		out = rstrip(out, sep)		# Remove last '/'
	elseif (isa(arg, Tuple) && isa(arg[1], String))		# Maybe better than above but misses nice %.xxg
		out = join(arg, sep)
	else
		error("arg2str: argument 'arg' can only be a String, Symbol, Number, Array or a Tuple, but was $(typeof(arg))")
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
function arg2str(arg::GMTdataset, sep='/')::String
	# This method is mainly to allow passing the direct output of gmtinfo()
	(size(arg,1) != 1) && error("When passing a GMTdataset to arg2str, it must have only one row")
	out = join([string(x, sep)::String for x in arg.data])
	rstrip(out, sep)		# Remove last '/'
end

# ---------------------------------------------------------------------------------------------------
function finish_PS_nested(d::Dict, cmd::Vector{String})::Vector{String}
	# Finish the PS creating command, but check also if we have any nested module calls like 'coast', 'colorbar', etc
	!has_opt_module(d) && return cmd
	cmd2::Vector{String} = add_opt_module(d)

	if (!isempty(cmd2) && startswith(cmd2[1], "clip"))		# Deal with the particular psclip case (Tricky)
		if (isa(CTRL.pocket_call[1], Symbol) || isa(CTRL.pocket_call[1], String))	# Assume it's a clip=end
			cmd::Vector{String}, CTRL.pocket_call[1] = [cmd; "psclip -C"], nothing
		else
			ind = findfirst(" -R", cmd[1]);		opt_R::String = strtok(cmd[1][ind[1]:end])[1]
			ind = findfirst(" -J", cmd[1]);		opt_J::String = strtok(cmd[1][ind[1]:end])[1]
			extra::String = strtok(cmd2[1])[2] * " "	# When psclip recieved extra arguments
			t::String, opt_B::String, opt_B1::String = "psclip " * extra * opt_R * " " * opt_J, "", ""
			ind = findall(" -B", cmd[1])
			if (!isempty(ind) && (findfirst("-N", extra) === nothing))
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
			cmd = [t; cmd; "psclip -C" * opt_B1]
		end
	else
		append!(cmd, cmd2)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function finish_PS(d::Dict, cmd::Vector{String}, output::String, K::Bool, O::Bool)::Vector{String}
	# Finish a PS creating command. All PS creating modules should use this.
	IamModern[1] && return cmd  			# In Modern mode this fun does not play
	for k = 1:length(cmd)
		if (!occursin(" >", cmd[k]))	# Nested calls already have the redirection set
			cmd[k] = (k == 1) ? finish_PS(d, cmd[k], output, K, O) : finish_PS(d, cmd[k], output, true, true)
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function finish_PS(d::Dict, cmd::String, output::String, K::Bool, O::Bool)::String
	if (!O && ((val = find_in_dict(d, [:P :portrait])[1]) === nothing))  cmd *= " -P"  end

	opt = (K && !O) ? " -K" : ((K && O) ? " -K -O" : "")

	if (output != "")
		if (K && !O)          cmd *= opt * " > " * output
		elseif (!K && !O)     cmd *= opt * " > " * output
		elseif (O)            cmd *= opt * " >> " * output
		end
	else
		if ((K && !O) || (!K && !O) || O)  cmd *= opt  end
	end
	!O && !startswith(cmd, "psxy") && (LEGEND_TYPE[1] = legend_bag())	# Make sure that we always start with an empty one
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function prepare2geotif(d::Dict, cmd::Vector{String}, opt_T::String, O::Bool)::Tuple{Vector{String}, String}
	# Prepare automatic settings to allow creating a GeoTIF or a KML from a PS map
	# Makes use of psconvert -W option
	function helper2geotif(cmd::String)::String
		# Strip all -B's and add convenient settings for creating GeoTIFF's and KLM's
		opts = split(cmd, " ");		cmd  = ""
		for opt in opts
			if     (startswith(opt, "-JX12c"))  cmd *= "-JX30cd/0 "		# Default size is too small
			elseif (!startswith(opt, "-B"))     cmd *= opt * " "
			end
		end
		cmd *= " -B0 --MAP_FRAME_TYPE=inside --MAP_FRAME_PEN=0.1,254"
	end

	if (!O && ((val = find_in_dict(d, [:geotif])[1]) !== nothing))		# Only first layer
		cmd[1] = helper2geotif(cmd[1])
		if (startswith(string(val)::String, "trans"))  opt_T::String = " -TG -W+g"  end	# A transparent GeoTIFF
	elseif (!O && ((val = find_in_dict(d, [:kml])[1]) !== nothing))		# Only first layer
		if (!occursin("-JX", cmd[1]) && !occursin("-Jx", cmd[1]))
			@warn("Creating KML requires the use of a cartesian projection of geographical coordinates. Not your case")
			return cmd, opt_T
		end
		cmd[1] = helper2geotif(cmd[1])
		if (isa(val, String) || isa(val, Symbol))	# A transparent KML
			if (startswith(string(val)::String, "trans"))  opt_T = " -TG -W+k"
			else                                           opt_T = string(" -TG -W+k", val)		# Whatever 'val' is
			end
		elseif (isa(val, NamedTuple) || isa(val, Dict))
			# [+tdocname][+nlayername][+ofoldername][+aaltmode[alt]][+lminLOD/maxLOD][+fminfade/maxfade][+uURL]
			isa(val, Dict) && (val = Base.invokelatest(dict2nt, val))
			opt_T = add_opt(Base.invokelatest(Dict,:kml => val), " -TG -W+k", "", [:kml],
							(title="+t", layer="+n", layername="+n", folder="+o", foldername="+o", altmode="+a", LOD=("+l", arg2str), fade=("+f", arg2str), URL="+u"))
		end
	end
	return cmd, opt_T
end

# ---------------------------------------------------------------------------------------------------
function add_opt_1char(cmd::String, d::Dict, symbs::Vector{Matrix{Symbol}}, del::Bool=true)::String
	# Scan the D Dict for SYMBS keys and if found create the new option OPT and append it to CMD
	# If DEL == true we remove the found key.
	# The keyword value must be a string, symbol or a tuple of them. We only retain the first character of each item
	# Ex:  GMT.add_opt_1char("", Dict(:N => ("abc", "sw", "x"), :Q=>"datum"), [[:N :geod2aux], [:Q :list]]) == " -Nasx -Qd"
	(SHOW_KWARGS[1]) && return print_kwarg_opts(symbs, "Str | Symb | Tuple")
	for opt in symbs
		((val = find_in_dict(d, opt, del)[1]) === nothing) && continue
		args::String = ""
		if (isa(val, String) || isa(val, Symbol))
			((args = arg2str(val)) != "") && (args = string(args[1]))
		elseif (isa(val, Tuple))
			for k = 1:numel(val)
				args *= arg2str(val[k])[1]::Char
			end
		end
		cmd = string(cmd, " -", opt[1], args)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt(d::Dict, cmd::String, opt::String, symbs::VMs, mapa=nothing, del::Bool=true, arg=nothing)::String
	# Scan the D Dict for SYMBS keys and if found create the new option OPT and append it to CMD
	# If DEL == false we do not remove the found key.
	# ARG, is a special case to append to a matrix (can't realy be done in Julia)
	# ARG can also be a Bool, in which case when MAPA is a NT we expand each of its members as sep options
	# If ARG is a string, then the keys of MAPA can be used as values of SYMBS and are replaced by vals of MAPA
	#    Example (hitogram -Z): add_opt(d, "", "Z", [:Z :kind], (counts="0", freq="1",...)) Z=freq => -Z1
	#  But this only works when sub-options have default values. i.e. they are aliases
	(SHOW_KWARGS[1]) && return print_kwarg_opts(symbs, mapa)	# Just print the kwargs of this option call

	if ((val = find_in_dict(d, symbs, del)[1]) === nothing)
		if (isa(arg, Bool) && isa(mapa, NamedTuple))	# Make each mapa[i] a mapa[i]key=mapa[i]val
			local cmd_::String = ""
			for k in keys(mapa)
				((val_ = find_in_dict(d, [k], false)[1]) === nothing) && continue	# This mapa key was not used
				if (isa(mapa[k], Tuple))    cmd_ *= mapa[k][1]::String * mapa[k][2](d, [k])::String	# mapa[k][2] is a function
				else
					if (mapa[k][1] == '_')  cmd_ *= mapa[k][2:end]::String		# Keep only the flag
					else                    cmd_ *= mapa[k] * arg2str(val_)::String
					end
				end
				delete!(d, [k])		# Now we can delete the key
			end
			(cmd_ != "") && (cmd *= " -" * opt * cmd_)
		end
		return cmd
	elseif (isa(arg, String) && isa(mapa, NamedTuple))	# Use the mapa KEYS as possibe values of 'val'
		local cmd_ = ""
		for k in keys(mapa)
			if (string(val) == string(k))
				cmd_ = " -" * opt
				#(length(mapa[k][1]) == 0) && error("Need alias value. Cannot be empty")
				first_ind = (mapa[k][1] == '_') ? 2 : 1
				cmd_ *= mapa[k][first_ind:end]::String
				break
			end
		end
		(cmd_ != "") && return cmd * cmd_	# Otherwise continue to see if the other (NT) form was provided
	end

	args::Vector{String} = Vector{String}(undef,1)
	isa(val, Dict) && (val = Base.invokelatest(dict2nt, val))
	if (isa(val, NamedTuple) && isa(mapa, NamedTuple))
		args[1] = Base.invokelatest(add_opt, val, mapa, arg)
	elseif (isa(val, Tuple) && length(val) > 1 && isa(val[1], NamedTuple))	# In fact, all val[i] -> NT
		# Used in recursive calls for options like -I, -N , -W of pscoast. Here we assume that opt != ""
		_args::String = ""
		for k = 1:numel(val)
			_args *= " -" * opt * Base.invokelatest(add_opt, val[k], mapa, arg)::String
		end
		return cmd * _args
	elseif (isa(mapa, Tuple) && length(mapa) > 1 && isa(mapa[2], Function))	# grdcontour -G
		(!isa(val, NamedTuple) && !isa(val, String)) && error("Option argument must be a NamedTuple, not a Tuple")
		if (isa(val, NamedTuple))
			args[1] = (mapa[2] == helper_decorated) ? mapa[2](val, true) : args[1] = mapa[2](val)	# 2nd case not yet inv
		elseif (isa(val, String))  args[1] = val
		end
	else
		args[1] = arg2str(val)
		if isa(mapa, NamedTuple)		# Let aa=(bb=true,...) be addressed as aa=:bb
			s = Symbol(args[1])
			for k in keys(mapa)
				(s != k) && continue
				v = mapa[k]
				if (isa(v, String) && (v != "") && (v[1] == '_'))	# Only the modifier matters
					args[1] = v[2:end]
				elseif (isa(v, Tuple) && length(v) == 3 && v[2] === nothing)	# A ("t", nothing, 1) type
					args[1] = v[1]
				end
				break
			end
		end
	end

	cmd = (opt != "") ? string(cmd, " -", opt, args[1]) : string(cmd, args[1])

	return cmd
end

# ---------------------------------------------------------------------------------------------------
function genFun(this_key::Symbol, user_input::NamedTuple, mapa::NamedTuple)::String
	(!haskey(mapa, this_key)) && return		# Should it be a error?
	out::String = ""
	key = keys(user_input)					# user_input = (rows=1, fill=:red)
	val_namedTup = mapa[this_key]			# water=(rows="my", cols="mx", fill=add_opt_fill)
	for k = 1:length(user_input)
		if (haskey(val_namedTup, key[k]))
			val = val_namedTup[key[k]]
			if (isa(val, Function))
				if (val == add_opt_fill) out *= val(Dict(key[k] => user_input[key[k]]))::String end
			else
				out *= string(val_namedTup[key[k]])::String
			end
		end
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
function add_opt(nt::NamedTuple, mapa::NamedTuple, arg=nothing)::String
	# Generic parser of options passed in a NT and whose last element is anther NT with the mapping
	# between expanded sub-options names and the original GMT flags.
	# ARG, is a special case to append to a matrix (can't realy be done in Julia)
	# Example:
	#	add_opt((a=(1,0.5),b=2), (a="+a",b="-b"))
	# translates to:	"+a1/0.5-b2"
	key = keys(nt);						# The keys actually used in this call
	d = nt2dict(mapa)					# The flags mapping as a Dict (all possible flags of the specific option)
	cmd::String = "";		cmd_hold = Vector{String}(undef, 2);	order = zeros(Int,2,1);  ind_o = 0
	count = zeros(Int, length(key))
	for k = 1:numel(key)::Int			# Loop over the keys of option's tuple
		!haskey(d, key[k]) && continue
		count[k] = k
		isa(nt[k], Dict) && (nt[k] = Base.invokelatest(dict2nt, nt[k]))
		if (isa(d[key[k]], Tuple))		# Complexify it. Here, d[key[k]][2] must be a function name.
			if (isa(nt[k], NamedTuple))
				if (d[key[k]][2] == add_opt_fill)
					cmd *= string(d[key[k]][1])::String * d[key[k]][2]("", Dict(key[k] => nt[k]), [key[k]])::String
				else
					local_opt = (d[key[k]][2] == helper_decorated) ? true : nothing		# 'true' means single argout
					cmd *= string(d[key[k]][1])::String * d[key[k]][2](nt2dict(nt[k]), local_opt)::String
				end
			else						#
				if (length(d[key[k]]) == 2)		# Run the function
					cmd *= string(d[key[k]][1])::String * d[key[k]][2](Dict(key[k] => nt[k]), [key[k]])::String
				else					# This branch is to deal with options -Td, -Tm, -L and -D of basemap & psscale
					ind_o += 1
					(ind_o > 2) && (@warn("You passed more than 1 of the exclusive options in a anchor type option, keeping first but this may break."); ind_o = 1)
					if (d[key[k]][2] === nothing)  cmd_hold[ind_o] = d[key[k]][1]	# Only flag char and order matters
					elseif (length(d[key[k]][1]) == 2 && d[key[k]][1][1] == '-' && !isa(nt[k], Tuple))	# e.g. -L (&g, arg2str, 1)
						cmd_hold[ind_o] = string(d[key[k]][1][2])	# where g<scalar>
					else		# Run the fun
						cmd_hold[ind_o] = (d[key[k]][1] == "") ? d[key[k]][2](nt[k]) : string(d[key[k]][1][end])::String * d[key[k]][2](nt[k])::String
					end
					order[ind_o]    = d[key[k]][3];				# Store the order of this sub-option
				end
			end
		elseif (isa(d[key[k]], NamedTuple))		#
			if (isa(nt[k], NamedTuple))
				cmd *= genFun(key[k], nt[k], mapa)::String
			else						# Create a NT where value = key. For example for: surf=(waterfall=:rows,)
				if (!isa(nt[1], Tuple))			# nt[1] may be a symbol, or string. E.g.  surf=(water=:cols,)
					cmd *= genFun(key[k], (; Symbol(nt[1]) => nt[1]), mapa)::String
				else
					if ((val = find_in_dict(d, [key[1]])[1]) !== nothing)		# surf=(waterfall=(:cols,:red),)
						cmd *= genFun(key[k], (; Symbol(nt[1][1]) => nt[1][1], keys(val)[end] => nt[1][end]), mapa)::String
					end
				end
			end
		elseif (d[key[k]] == "1")		# Means that only first char in value is retained. Used with units
			t::String = arg2str(nt[k])::String
			if (t != "")  cmd *= t[1]
			else          cmd *= "1"	# "1" is itself the flag
			end
		elseif (d[key[k]] != "" && d[key[k]][1] == '|')		# Potentialy append to the arg matrix (here in vector form)
			if (isa(nt[k], AbstractArray) || isa(nt[k], Tuple))
				if (isa(nt[k], AbstractArray))  append!(arg, reshape(nt[k], :))
				else                            append!(arg, reshape(collect(nt[k]), :))
				end
			end
			cmd *= string(d[key[k]][2:end])::String		# And now append the flag
		elseif (d[key[k]] != "" && d[key[k]][1] == '_')		# Means ignore the content, only keep the flag
			cmd *= string(d[key[k]][2:end])::String		# Just append the flag
		elseif (d[key[k]] != "" && d[key[k]][end] == '1')	# Means keep the flag and only first char of arg
			cmd *= string(d[key[k]][1:end-1])::String * string(string(nt[k])[1])::String
		elseif (d[key[k]] != "" && d[key[k]][end] == '#')	# Means put flag at the end and make this arg first in cmd (coast -W)
			cmd = arg2str(nt[k])::String * string(d[key[k]][1:end-1])::String * cmd
		else
			cmd *= d[key[k]]::String * arg2str(nt[k])::String
		end
	end

	#if (sum(count) > 0 && any(count .== 0))
		#for k = 1:numel(key) count[k] == 0 && println("\t\tWarning: keyword '$(key[k])' was not consumed") end
	#end

	if (ind_o > 0)			# We have an ordered set of flags (-Tm, -Td, -D, etc...). Not so trivial case
		if     (order[1] == 1 && order[2] == 2)  cmd = cmd_hold[1] * cmd_hold[2] * cmd;		last = 2
		elseif (order[1] == 2 && order[2] == 1)  cmd = cmd_hold[2] * cmd_hold[1] * cmd;		last = 1
		else                                     cmd = cmd_hold[1] * cmd;		last = 1
		end
		if (occursin(':', cmd_hold[last]))		# It must be a geog coordinate in dd:mm
			cmd = "g" * cmd
#=
		elseif (length(cmd_hold[last]) > 2)		# Temp patch to avoid parsing single char flags
			rs = split(cmd_hold[last], '/')
			if (length(rs) == 2)
				x = tryparse(Float64, rs[1]);		y = tryparse(Float64, rs[2]);
				if (x !== nothing && y !== nothing && 0 <= x <= 1.0 && 0 <= y <= 1.0 && !occursin(r"[gjJxn]", string(cmd[1])))  cmd = "n" * cmd  end		# Otherwise, either a paper coord or error
			end
=#
		end
	end

	return cmd
end

# ---------------------------------------------------------------------------------------------------
function add_opt(fun::Function, t1::Tuple, t2::NamedTuple, del::Bool, mat)
	# Crazzy shit to allow increasing the arg1 matrix
	(mat === nothing) && return fun(t1..., t2, del, mat), mat  # psxy error_bars may send mat = nothing
	n_rows = size(mat, 1)
	mat = reshape(mat, :)
	cmd::String = fun(t1..., t2, del, mat)
	mat = reshape(mat, n_rows, :)
	return cmd, mat
end

# ---------------------------------------------------------------------------------------------------
function add_opt(d::Dict, cmd::String, opt::String, symbs::VMs, need_symb::Symbol, args, nt_opts::NamedTuple)
	# This version specializes in the case where an option may transmit an array, or read a file, with optional flags.
	# When optional flags are used we need to use NamedTuples (the NT_OPTS arg). In that case the NEED_SYMB
	# is the keyword name (a symbol) whose value holds the array. An error is raised if this symbol is missing in D
	# ARGS is a 1-to-3 array of GMT types in which some may be NOTHING. If the value is an array, it will be
	# stored in first non-empty element of ARGS.
	# Example where this is used (plot -Z):  Z=(outline=true, data=[1, 4])
	(SHOW_KWARGS[1]) && print_kwarg_opts(symbs)		# Just print the kwargs of this option call

	N_used = 0;		got_one = false
	val, symb = find_in_dict(d, symbs, false)
	if (val !== nothing)
		to_slot = true
		isa(val, Dict) && (val = Base.invokelatest(dict2nt, val))
		if (isa(val, Tuple) && length(val) == 2)
			# This is crazzy trickery to accept also (e.g) C=(pratt,"200k") instead of C=(pts=pratt,dist="200k")
			d[symb] = Base.invokelatest(dict2nt, Dict(need_symb => val[1], keys(nt_opts)[1] => val[2]))	# Need to patch also the input option
			val = d[symb]
		end
		if (isa(val, NamedTuple))
			di::Dict = nt2dict(val)
			((val = find_in_dict(di, [need_symb], false)[1]) === nothing) && error(string(need_symb, " member cannot be missing"))
			if (isa(val, Real) || isa(val, String))	# So that this (psxy) also works:	Z=(outline=true, data=3)
				opt = string(opt,val)
				to_slot = false
			end
			cmd = add_opt(d, cmd, opt, symbs, nt_opts)
		elseif (isa(val, Array{<:Real}) || isa(val, GDtype) || isa(val, GMTcpt) || typeof(val) <: AbstractRange)
			if (typeof(val) <: AbstractRange)  val = collect(val)  end
			cmd = string(cmd, " -", opt)
		elseif (isa(val, Array{<:Union{Missing, Real}}))	# DataFrames produce these guys
			val = replace(val, missing => NaN)		# Even if there are no missings it will be converted do Float64
			cmd = string(cmd, " -", opt)
		elseif (isa(val, String) || isa(val, Symbol) || isa(val, Real))
			cmd = string(cmd, " -", opt * arg2str(val)::String)
			to_slot = false
		else
			error("Bad argument type ($(typeof(val))) to option $opt")
		end
		if (to_slot)
			for k = 1:numel(args)
				if (args[k] === nothing)
					args[k] = val
					N_used = k
					break
				end
			end
		end
		delete!(d, symbs)
		got_one = true
	end
	return cmd, args, N_used, got_one
end

# ---------------------------------------------------------------------------------------------------
function add_opt_cpt(d::Dict, cmd::String, symbs::VMs, opt::Char, N_args::Int=0, arg1=nothing, arg2=nothing,
	                 store::Bool=false, def::Bool=false, opt_T::String="", in_bag::Bool=false)
	# Deal with options of the form -Ccolor, where color can be a string or a GMTcpt type
	# SYMBS is normally: CPTaliases
	# N_args only applyies to when a GMTcpt was transmitted. Then it's either 0, case in which
	# the cpt is put in arg1, or 1 and the cpt goes to arg2.
	# STORE, when true, will save the cpt in the global state
	# DEF, when true, means to use the default cpt (Turbo)
	# OPT_T, when != "", contains a min/max/n_slices/+n string to calculate a cpt with n_slices colors between [min max]
	# IN_BAG, if true means that, if not empty, we return the contents of `CURRENT_CPT`

	(SHOW_KWARGS[1]) && return print_kwarg_opts(symbs, "GMTcpt | Tuple | Array | String | Number"), arg1, arg2, N_args

	function equalize(d, arg1, cptname::String, opt_T::String)::GMTcpt
		if ((isa(arg1, GMTgrid) || isa(arg1, String)) && (val_eq = find_in_dict(d, [:equalize])[1]) !== nothing)
			n::Int = convert(Int, val_eq)				# If val is other than Bool or number it will error
			if (isa(arg1, String))
				(n > 1) ? gmt("grd2cpt -E$n+c -C" * cptname * " " * arg1) : gmt("grd2cpt -C" * cptname * " " * arg1)
			else
				(n > 1) ? gmt("grd2cpt -E$n+c -C" * cptname, arg1) : gmt("grd2cpt -C" * cptname, arg1)
			end
		else
			gmt("makecpt " * opt_T * " -C" * cptname)
		end
	end

	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		if (isa(val, GMT.GMTcpt))
			(N_args > 1) && error("Can't send the CPT data via option AND input array")
			cmd, arg1, arg2, N_args = helper_add_cpt(cmd, opt, N_args, arg1, arg2, val, store)
		else
			if (opt_T != "")
				cpt::GMTcpt = makecpt(opt_T * " -C" * get_color(val)::String)
				cmd, arg1, arg2, N_args = helper_add_cpt(cmd, opt, N_args, arg1, arg2, cpt, store)
			else
				c = get_color(val)::String
				opt_C = " -" * opt * c		# This is pre-made GMT cpt
				cmd *= opt_C
				if (store && c != "" && tryparse(Float32, c) === nothing)	# Because if !== nothing then it's a number and -Cn is not valid
					try			# Wrap in try because not always (e.g. grdcontour -C) this is a makecpt callable
						r = makecpt(opt_C * " -Vq")
						global CURRENT_CPT[1] = (r !== nothing) ? r : GMTcpt()
					catch
					end
				elseif (in_bag && !isempty(CURRENT_CPT[1]))	# If we have something in Bag, return it
					cmd, arg1, arg2, N_args = helper_add_cpt(cmd, "", N_args, arg1, arg2, CURRENT_CPT[1], false)
				end
			end
		end
	elseif (def && opt_T != "")						# Requested use of the default color map
		if (IamModern[1])  opt_T *= " -H"  end		# Piggy back this otherwise we get no CPT back in Modern
		if (haskey(d, :this_cpt) && d[:this_cpt] != "")		# A specific CPT name was requested
			cpt_name::String = d[:this_cpt]			# Because of the terrible invalidations
			cpt = equalize(d, arg1, cpt_name, opt_T);	delete!(d, :this_cpt)
		else
			cpt = equalize(d, arg1, "turbo", opt_T)	# In fact it only equalizes if the equalize option is in d
			cpt.bfn[3, :] = [1.0 1.0 1.0]	# Some deep bug, in occasions, returns grays on 2nd and on calls
		end
		cmd, arg1, arg2, N_args = helper_add_cpt(cmd, opt, N_args, arg1, arg2, cpt, store)
	elseif (in_bag && !isempty(CURRENT_CPT[1]))		# If everything else has failed and we have one in the Bag, return it
		cmd, arg1, arg2, N_args = helper_add_cpt(cmd, opt, N_args, arg1, arg2, CURRENT_CPT[1], false)
	end
	if (occursin(" -C", cmd))
		if ((val = find_in_dict(d, [:hinge])[1]) !== nothing)       cmd *= string("+h", val)::String  end
		if ((val = find_in_dict(d, [:meter2unit])[1]) !== nothing)  cmd *= "+U" * parse_unit_unit(val)::String  end
		if ((val = find_in_dict(d, [:unit2meter])[1]) !== nothing)  cmd *= "+u" * parse_unit_unit(val)::String  end
	end
	return cmd, arg1, arg2, N_args
end
# ---------------------
function helper_add_cpt(cmd::String, opt, N_args::Int, arg1, arg2, val::GMTcpt, store::Bool)
	# Helper function to avoid repeating 3 times the same code in add_opt_cpt
	(N_args == 0) ? arg1 = val : arg2 = val;	N_args += 1
	if (store)  global CURRENT_CPT[1] = val  end
	(isa(opt, Char) || (isa(opt, String) && opt != "")) && (cmd *= " -" * opt)
	return cmd, arg1, arg2, N_args
end

# ---------------------------------------------------------------------------------------------------
#add_opt_fill(d::Dict, opt::String="") = add_opt_fill("", d, [d[collect(keys(d))[1]]], opt)	# Use ONLY when len(d) == 1
function add_opt_fill(d::Dict, opt::String="")
	add_opt_fill(d, [collect(keys(d))[1]], opt)			# Use ONLY when len(d) == 1
end
add_opt_fill(d::Dict, symbs::VMs, opt="") = add_opt_fill("", d, symbs, opt)
function add_opt_fill(cmd::String, d::Dict, symbs::VMs, opt="", del::Bool=true)::String
	# Deal with the area fill attributes option. Normally, -G
	(SHOW_KWARGS[1]) && return print_kwarg_opts(symbs, "NamedTuple | Tuple | Array | String | Number")
	((val = find_in_dict(d, symbs, del)[1]) === nothing) && return cmd
	isa(val, Dict) && (val = Base.invokelatest(dict2nt, val))
	(val == true && symbs == [:G :fill]) && (val="#0072BD")		# Let fill=true mean a default color
	(val == "" && symbs == [:G :fill]) && return cmd			# Let fill="" mean no fill (handy for proggy reasons)
	(opt != "") && (opt = string(" -", opt))
	return add_opt_fill(val, cmd, opt)
end

function add_opt_fill(val, cmd::String="",  opt="")::String
	# This method can be called directy with VAL as a NT or a string
	if (isa(val, Tuple) && length(val) == 2 && (isa(val[1], Tuple) || isa(val[1], NamedTuple)))
		# wiggle, for example, may want to repeat the call to fill (-G). Then we expect a Tuple of -G's
		cmd::String = add_opt_fill(val[1], cmd,  opt)
		cmd = add_opt_fill(val[2], cmd,  opt)
	elseif (isvector(val) && length(val) == 2 && isa(val[1], String))
		# The above case works but may be uggly sometimes; e.g. fill=(("red+p",), ("blue+n",))
		# So accept also a vector of strings and do not try to interpret its contents. Ex: fill(["red+p", "blue+n"]
		(opt != "" && !startswith(opt, " -")) && (opt = string(" -", opt))
		cmd = cmd * opt * val[1]::String * opt * val[2]::String
	elseif (isa(val, NamedTuple))
		d2::Dict = nt2dict(val)
		cmd *= opt
		if     (haskey(d2, :pattern))     cmd *= 'p' * add_opt(d2, "", "", [:pattern])::String
		elseif (haskey(d2, :inv_pattern)) cmd *= 'P' * add_opt(d2, "", "", [:inv_pattern])::String
		else   error("For 'fill' option as a NamedTuple, you MUST provide a 'patern' member")
		end

		((val2 = find_in_dict(d2, [:bg :bgcolor :background], false)[1]) !== nothing) && (cmd *= "+b" * get_color(val2)::String)
		((val2 = find_in_dict(d2, [:fg :fgcolor :foreground], false)[1]) !== nothing) && (cmd *= "+f" * get_color(val2)::String)
		(haskey(d2, :dpi)) && (cmd = string(cmd, "+r", d2[:dpi]))
	else
		t = get_color(val)
		(t != "none") ? (cmd *= string(opt, t)::String) : (cmd *= opt)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function get_cpt_set_R(d::Dict, cmd0::String, cmd::String, opt_R::String, got_fname::Int, arg1, arg2=nothing, arg3=nothing, prog::String="")
	# Get CPT either from keyword input of from CURRENT_CPT.
	# Also puts -R in cmd when accessing grids from grdimage|view|contour, etc... (due to a GMT bug that doesn't do it)
	# Use CMD0 = "" to use this function from within non-grd modules
	global CURRENT_CPT
	cpt_opt_T::String = ""
	if (isa(arg1, GItype))			# GMT bug, -R will not be stored in gmt.history
		range::Vector{Float64} = isa(arg1.range, Float64) ? vec(arg1.range) : vec(arg1.range[1:6])	# Beyond 6 can be a Time
	elseif (cmd0 != "" && cmd0[1] != '@')
		info = grdinfo(cmd0 * " -C");	range = vec(info.data)
	end
	if (isa(arg1, GItype) || (cmd0 != "" && cmd0[1] != '@'))
		if (isempty(CURRENT_CPT[1]) && (val = find_in_dict(d, CPTaliases, false)[1]) === nothing)
			# If no cpt name sent in, then compute (later) a default cpt
			if (isa(arg1, GMTgrid) && ((val = find_in_dict(d, [:percent :pct])[1])) !== nothing)
				lh = quantile(any(!isfinite, arg1) ? skipnan(vec(arg1)) : vec(arg1), [(100 - val)/200, (1 - (100 - val)/200)])
				cpt_opt_T = @sprintf(" -T%.12g/%.12g/256+n -D", lh[1], lh[2])	# Piggyback -D
			elseif ((val = find_in_dict(d, [:percent :pct])[1]) !== nothing)			# Case of a grid file
				range = vec(grdinfo(cmd0 * " -C -T+a$(100-val)"::String).data);
				cpt_opt_T = @sprintf(" -T%.12g/%.12g/256+n -D", range[5], range[6])
			elseif ((val = find_in_dict(d, [:clim])[1]) !== nothing)
				(length(val) != 2) && error("The clim option must have two elements and not $(length(val)::Int)")
				cpt_opt_T = @sprintf(" -T%.12g/%.12g/256+n -D", val[1], val[2])	# Piggyback -D
			else
				((range[6] - range[5]) > 1e6) && @warn("The z range expands to more then 6 orders of magnitude. Missed to replace the nodatavalues?\n\n")
				cpt_opt_T = @sprintf(" -T%.12g/%.12g/256+n", range[5] - 1e-6, range[6] + 1e-6)
			end
			(range[5] > 1e100) && (cpt_opt_T = "")	# cmd0 is an image name and now grdinfo does not compute its min/max
		end
		if (opt_R == "" && (!IamModern[1] || (IamModern[1] && FirstModern[1])) )	# No -R ovewrite by accident
			cmd *= @sprintf(" -R%.14g/%.14g/%.14g/%.14g", range[1], range[2], range[3], range[4])
		end
	elseif (cmd0 != "" && cmd0[1] == '@')		# No reason not to let @grids use clim=[...]
		if ((val = find_in_dict(d, [:clim])[1]) !== nothing)
			(length(val) != 2) && error("The clim option must have two elements and not $(length(val)::Int)")
			cpt_opt_T = @sprintf(" -T%.12g/%.12g/256+n -D", val[1], val[2])
		elseif (any(contains.(cmd0, ["_01d", "_30m", "_20m", "_15m", "_10m", "_06m"])) && (val = find_in_dict(d, [:percent :pct])[1]) !== nothing)
			infa = grdinfo(cmd0 * " -T+a$(100-val)"::String).text[1]	# Bloody complicated output
			mima = split(infa[3:end], "/")		# Because the output is like "-T-5384/2729"
			cpt_opt_T = " -T" * mima[1] * "/" * mima[2] * "/256+n -D"
		elseif (haskey(d, :equalize))
			arg1, cpt_opt_T = cmd0, " "			# This is a trick to let add_opt_cpt() compute the equalization
		end
	end

	N_used = (got_fname == 0) ? 1 : 0			# To know whether a cpt will go to arg1 or arg2
	get_cpt = false;	in_bag = true;			# IN_BAG means seek if CURRENT_CPT != nothing and return it
	if (prog == "grdview")
		get_cpt = true
		if ((val = find_in_dict(d, [:G :drapefile], false)[1]) !== nothing)
			(isa(val, Tuple) && length(val) == 3) && (get_cpt = false)		# Playing safe
		end
		(get_cpt && isa(arg1, GMTgrid) && arg1.cpt != "") && (d[:this_cpt] = arg1.cpt)
	elseif (prog == "grdimage")
		if (!isa(arg1, GMTimage) && (arg3 === nothing && !occursin("-D", cmd)) )
			get_cpt = true		# This still leaves out the case when the r,g,b were sent as a text.
		elseif (find_in_dict(d, CPTaliases, false)[1] !== nothing)
			@warn("You are possibly asking to assign a CPT to an image. That is not allowed by GMT. See function image_cpt!")
			get_cpt = true		# 
		end
		(isa(arg1, GMTgrid) && arg1.cpt != "") && (d[:this_cpt] = arg1.cpt)		# Use the grid's default CPT
	elseif (prog == "grdcontour" || prog == "pscontour")	# Here C means Contours but we cheat, so always check if C, color, ... is present
		get_cpt = true;		cpt_opt_T = ""		# This is hell. And what if I want to auto generate a cpt?
		if (prog == "grdcontour" && !occursin("+c", cmd))  in_bag = false  end
	end
	if (get_cpt)
		cmd, arg1, arg2, = add_opt_cpt(d, cmd, CPTaliases, 'C', N_used, arg1, arg2, true, true, cpt_opt_T, in_bag)
		N_used = (arg1 !== nothing) + (arg2 !== nothing)
	end

	if (IamModern[1] && FirstModern[1])  FirstModern[1] = false;  end
	return cmd, N_used, arg1, arg2, arg3
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

	for symb in CTRL.callable			# Loop over modules list that can be called inside other modules
		r::String = ""
		if (haskey(d, symb))
			val = d[symb]
			isa(val, Dict) && (val = Base.invokelatest(dict2nt, val))
			if (isa(val, NamedTuple))
				nt::NamedTuple = val
				if     (symb == :coast)     r = coast!(; Vd=2, nt...)
				elseif (symb == :colorbar)  r = colorbar!(; Vd=2, nt...)
				elseif (symb == :basemap)   r = basemap!(; Vd=2, nt...)
				elseif (symb == :logo)      r = logo!(; Vd=2, nt...)
				elseif (symb == :clip)		# Need lots of little shits to parse the clip options
					CTRL.pocket_call[1] = val[1];
					k,v = keys(nt), values(nt)
					nt = NamedTuple{Tuple(Symbol.(k[2:end]))}(v[2:end])		# Fck, what a craziness to remove 1 el from a nt
					r = clip!(""; Vd=2, nt...)
					r = r[1:findfirst(" -K", r)[1]];	# Remove the "-K -O >> ..."
					r = replace(r, " -R -J" => "")
					r = "clip " * strtok(r)[2]			# Make sure the prog name is 'clip' and not 'psclip'
				else
					!(symb in CTRL.callable) && error("Nested Fun call $symb not in the callable nested functions list")
					_d = nt2dict(nt)
					(haskey(_d, :data)) && (CTRL.pocket_call[1] = _d[:data]; delete!(d, [:data]))
					this_symb = CTRL.callable[findfirst(symb .== CTRL.callable)]
					fn = getfield(GMT, Symbol(string(this_symb, "!")))
					if (this_symb in [:vband, :hband, :vspan, :hspan])
						r = fn(CTRL.pocket_call[1]; nested=true, Vd=2, nt...)
					else
						r = fn(; Vd=2, nt...)
					end
				end
			elseif (isa(val, Real) && (val != 0))		# Allow setting coast=true || colorbar=true
				if     (symb == :coast)    r = coast!(W=0.5, A="200/0/2", Vd=2)
				elseif (symb == :colorbar) r = colorbar!(pos=(anchor="MR",), B="af", Vd=2)
				elseif (symb == :logo)     r = logo!(Vd=2)
				end
			elseif (symb == :colorbar && (isa(val, String) || isa(val, Symbol)))
				t::Char = lowercase(string(val)[1])		# Accept "Top, Bot, Left" but default to Right
				anc = (t == 't') ? "TC" : (t == 'b' ? "BC" : (t == 'l' ? "ML" : "MR"))
				r = colorbar!(pos=(anchor=anc,), B="af", Vd=2)
			elseif (symb == :clip)
				CTRL.pocket_call[1] = val;	r = "clip"
			end
			delete!(d, symb)
		end
		(r != "") && append!(out, [r])
	end
	return out
end

# ---------------------------------------------------------------------------------------------------
function get_color(val)::String
	# Parse a color input. Always return a string
	# color1,color2[,color3,…] colorn can be a r/g/b triplet, a color name, or an HTML hexadecimal color (e.g. #aabbcc
	(isa(val, AbstractString) || isa(val, Symbol) || isa(val, Real)) && return isa(val, Bool) ? "" : string(val)

	@warn("got this bad data type: $(typeof(val))")		# Need to split because f julia change in 6.1
	error("\tGET_COLOR: got an unsupported data type")
end
function get_color(val::Tuple)::String
	out::String = ""
	for k = 1:numel(val)
		if (isa(val[k], Tuple) && (length(val[k]) == 3))
			s = 1
			if (val[k][1] <= 1 && val[k][2] <= 1 && val[k][3] <= 1)  s = 255  end	# colors in [0 1]
			out *= @sprintf("%.0f/%.0f/%.0f,", val[k][1]*s, val[k][2]*s, val[k][3]*s)
		elseif (isa(val[k], Symbol) || isa(val[k], String) || isa(val[k], Real))
			out *= string(val[k],",")::String
		else
			error("Color tuples must have only one or three elements")
		end
	end
	out = rstrip(out, ',')		# Strip last ','
end
function get_color(val::Array{<:Real})::String
	out::String = ""
	if (isa(val, Vector))  val = val'  end
	(size(val, 2) != 3) && error("\tGET_COLOR: Input as Array must be a Mx3 matrix or 3 elements Vector.")
	copia = (val[1,1] <= 1 && val[1,2] <= 1 && val[1,3] <= 1) ? Float64.(val) .* 255 : Float64.(val)	# Do not change the original
	out = @sprintf("%.0f/%.0f/%.0f", copia[1,1], copia[1,2], copia[1,3])
	for k = 2:size(copia, 1)
		out = @sprintf("%s,%.0f/%.0f/%.0f", out, copia[k,1], copia[k,2], copia[k,3])
	end
	out
end

# ---------------------------------------------------------------------------------------------------
function font(d::Dict, symbs)::String
	((val = find_in_dict(d, symbs)[1]) !== nothing) ? font(val) : ""
end
font(val::String)::String = val
font(val::Real)::String = string(val)
function font(val::Tuple)::String
	# parse and create a font string.
	# TODO: either add a NammedTuple option and/or guess if 2nd arg is the font name or the color
	# And this: Optionally, you may append =pen to the fill value in order to draw the text outline with
	# the specified pen; if used you may optionally skip the filling of the text by setting fill to -.

	s::String = parse_units(val[1])
	if (length(val) > 1)
		s = string(s,',',val[2])
		(length(val) > 2) && (s = string(s, ',', get_color(val[3])))
	end
	return s
end

# ---------------------------------------------------------------------------------------------------
function parse_units(val)::String
	# Parse a units string in the form d|e|f|k|n|M|n|s or expanded
	(isa(val, String) || isa(val, Symbol) || isa(val, Real)) && return string(val)

	!(isa(val, Tuple) && (length(val) == 2)) && error("PARSE_UNITS, got and unsupported data type: $(typeof(val))")
	return string(val[1], parse_unit_unit(val[2]))
end

# ---------------------------
function parse_unit_unit(str)::String
	!isa(str, StrSymb) && error("Argument data type must be String or Symbol but was: $(typeof(str))")
	if (isa(str, Symbol))  str = string(str)  end

	if     (str == "e" || str == "meter")  out = "e";
	elseif (str == "M" || str == "mile")   out = "M";
	elseif (str == "nodes")                out = "+n";
	elseif (str == "data")                 out = "u";		# For the `scatter` modules
	else                                   out = string(str[1])		# To be type-stable
	end
	return out
end
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
function data_type(val)
	# Parse data type for using in -b
	str::String = string(val)
	d = Dict("char" => "c", "int8" => "c", "uint8" => "u", "int16" => "h", "uint16" => "H", "int32" => "i", "uint32" => "I", "int64" => "l", "uint64" => "L", "float" => "f", "single" => "f", "double" => "d")
	out = haskey(d, str) ? d[str] : "d"
end

# ---------------------------------------------------------------------------------------------------
axis(nt::NamedTuple, D::Dict=Dict(); x::Bool=false, y::Bool=false, z::Bool=false, secondary::Bool=false) = axis(D;x=x, y=y, z=z, secondary=secondary, nt...)
function axis(D::Dict=Dict(); x::Bool=false, y::Bool=false, z::Bool=false, secondary::Bool=false, kwargs...)::Tuple{String, Vector{Bool}}
	# Build the (terrible) -B option
	d = KW(kwargs)			# These kwargs always come from the fields of a NamedTuple 

	# Before anything else
	(haskey(d, :none)) && return " -B0", [false, false]

	primo = secondary ? "s" : "p"					# Primary or secondary axis
	(z) && (primo = "")								# Z axis have no primary/secondary
	axe::String = x ? "x" : (y ? "y" : (z ? "z" : ""))		# Are we dealing with a specific axis?

	# See if we have a request for axis direction flipping. If yes, just store that info to be used elsewhere.
	# But it's so fck irritating that we can't change a string. Have to do this stupid gymnastic.
	_jx, _jy, _jz = CTRL.pocket_J[4][1]::Char, CTRL.pocket_J[4][2]::Char, CTRL.pocket_J[4][3]::Char
	if (axe == "")
		(is_in_dict(d, [:xflip, :flipx], del=true) !== nothing) && (_jx = 'Y')
		(is_in_dict(d, [:yflip, :flipy], del=true) !== nothing) && (_jy = 'Y')
		(is_in_dict(d, [:zflip, :flipz], del=true) !== nothing) && (_jz = 'Y')
	else
		(x && (is_in_dict(d, [:flip, :xflip, :flipx], del=true) !== nothing)) && (_jx = 'Y')
		(y && (is_in_dict(d, [:flip, :yflip, :flipy], del=true) !== nothing)) && (_jy = 'Y')
		(z && (is_in_dict(d, [:flip, :zflip, :flipz], del=true) !== nothing)) && (_jz = 'Y')
	end
	CTRL.pocket_J[4] = _jx * _jy * _jz

	opt::String = " -B"
	is3D = (is_in_dict(D, [:JZ :Jz :zscale :zsize]) !== nothing) ? true : false
	if ((val = find_in_dict(d, [:axes :frame])[1]) !== nothing)
		isa(val, Dict) && (val = Base.invokelatest(dict2nt, val))
		o::String = helper0_axes(val)
		opt = (o == "full") ? opt * "WSEN" : (o == "none") ? opt : opt * o
	end

	haskey(d, :corners) && (opt *= string(d[:corners])::String)		# 1234
	val, symb = find_in_dict(d, [:fill :bg :bgcolor :background], false)
	if (val !== nothing)
		tB = "+g" * add_opt_fill(d, [symb])::String
		opt *= tB					# Works, but patterns can screw
		CTRL.pocket_B[2] = tB		# Save this one because we may need to revert it during psclip parsing
		CTRL.pocket_B[3] = "."		# Signal gmt() to call gmt_restart because bg screws the API continuity
	end
	((val = find_in_dict(d, [:Xfill :Xbg :Xwall])[1]) !== nothing) && (opt = add_opt_fill(val, opt, "+x"))
	((val = find_in_dict(d, [:Yfill :Ybg :Ywall])[1]) !== nothing) && (opt = add_opt_fill(val, opt, "+y"))
	((val = find_in_dict(d, [:Zfill :Zbg :Zwall])[1]) !== nothing) && (opt = add_opt_fill(val, opt, "+z"))
	((p = add_opt_pen(d, [:wall_outline], "+w")) != "") && (opt *= p)
	(haskey(d, :cube))     && (opt *= "+b")
	(haskey(d, :internal)) && (opt *= "+i" * arg2str(d[:internal])::String)
	(startswith(opt, " -B+") && !startswith(opt, " -B+g")) && (opt = " -BWSENZ" * opt[4:end])	# Without axes prev opts screw -B
	(haskey(d, :noframe))  && (opt *= "+n")
	(haskey(d, :pole))     && (opt *= "+o" * arg2str(d[:pole])::String)
	if (haskey(d, :title))
		opt *= "+t" * str_with_blancs(arg2str(d[:title]))::String
		(haskey(d, :subtitle)) && (opt *= "+s" * str_with_blancs(arg2str(d[:subtitle])::String))
	end

	opt_Bframe::String = (opt != " -B") ? opt : ""		# Make a copy to append only at the end
	opt = ""

	# axes supps
	ax_sup::String = ""
	(haskey(d, :seclabel)) && (ax_sup *= "+s" * str_with_blancs(arg2str(d[:seclabel])::String) )

	if (haskey(d, :label))
		opt *= " -B" * primo * axe * "+l"  * str_with_blancs(arg2str(d[:label])::String) * ax_sup
	else
		if (haskey(d, :xlabel))  opt *= " -B" * primo * "x+l" * str_with_blancs(arg2str(d[:xlabel])::String) * ax_sup  end
		if (haskey(d, :zlabel))  opt *= " -B" * primo * "z+l" * str_with_blancs(arg2str(d[:zlabel])::String) * ax_sup  end
		if (haskey(d, :ylabel))
			opt *= " -B" * primo * "y+l" * str_with_blancs(arg2str(d[:ylabel])::String) * ax_sup
		elseif (haskey(d, :Yhlabel))
			opt_L = (axe != "y") ? "y+L" : "+L"
			opt *= " -B" * primo * axe * opt_L * str_with_blancs(arg2str(d[:Yhlabel])::String) * ax_sup
		end
		haskey(d, :alabel) && (opt *= " -Ba+l" * str_with_blancs(arg2str(d[:alabel])::String))	# For Ternary
		haskey(d, :blabel) && (opt *= " -Bb+l" * str_with_blancs(arg2str(d[:blabel])::String))
		haskey(d, :clabel) && (opt *= " -Bc+l" * str_with_blancs(arg2str(d[:clabel])::String))
	end

	# intervals
	ints::String, ann_2, ann_3, tic_2, tic_3, gri_2, gri_3, gri_d  = "", "", "", "", "", "", "", ""
	if (haskey(d, :annot))      ints *= "a" * helper1_axes(d[:annot], is3D, 'a')  end
	contains(ints, ' ') && (spli = split(ints); ints = string(spli[1]); ann_2 = string(spli[2]); ann_3 = string(spli[3]))
	(haskey(d, :annot_unit)) && (ints *= helper2_axes(d[:annot_unit]))

	if (haskey(d, :ticks))      ints *= "f" * helper1_axes(d[:ticks], is3D, 'f')  end
	contains(ints, ' ') && (spli = split(ints); ints = string(spli[1]); tic_2 = string(spli[2]); tic_3 = string(spli[3]))
	(haskey(d, :ticks_unit)) && (ints *= helper2_axes(d[:ticks_unit]))

	if (haskey(d, :grid))
		if (isa(d[:grid], NamedTuple))  gri_d = parse_grid(D, d[:grid], "", false)		# Whatever comes out
		else                            gri_d = "g" * helper1_axes(d[:grid], is3D, 'g')
		end
		contains(gri_d, ' ') && (spli = split(gri_d); gri_d = string(spli[1]); gri_2 = string(spli[2]); gri_3 = string(spli[3]))
		ints *= gri_d;	CTRL.pocket_B[1] = gri_d	# If gri_d has a space in it a guess some shit will happen later
	end

	# Time to join the afg pieces (if that's the case)
	afg_y, afg_z = "", ""
	nBs = (ann_3 != "" || tic_3 != "" || gri_3 != "") ? 3 : (ann_2 != "" || tic_2 != "" || gri_2 != "") ? 2 : 1
	if (nBs > 1)									# We have multi -B axes.
		afg2, afg3 = ann_2 * tic_2 * gri_2, ann_3 * tic_3 * gri_3
		(nBs == 3) && (afg_y = afg2; afg_z = afg3)	# This is for sure because it's a 3D case
		(nBs == 2) && (is3D ? (afg_z = afg2) : (afg_y = afg2))
	end

	(haskey(d, :prefix)) && (ints *= "+p" * str_with_blancs(arg2str(d[:prefix])::String))
	(haskey(d, :suffix)) && (ints *= "+u" * str_with_blancs(arg2str(d[:suffix])::String))
	if (haskey(d, :slanted))
		s::String = arg2str(d[:slanted])
		if (s != "")
			if (!isdigit(s[1]) && s[1] != '-' && s[1] != '+')
				s = string(s[1])
				(axe == "y" && s != 'p') && error("slanted option: Only 'parallel' is allowed for the y-axis")
			end
			ints *= "+a" * s
		end
	end
	if (haskey(d, :custom))
		if (isa(d[:custom], String))  ints *= "c" * d[:custom]::String
		else
			if ((r = helper3_axes(d[:custom], primo, axe)) != "")  ints *= "c" * r  end
		end
	elseif (haskey(d, :customticks))			# These ticks are custom axis
		((r = ticks(d[:customticks]; axis=axe, primary=primo)) != "") && (ints *= "c" * r)
	elseif (haskey(d, :pi))
		if (isa(d[:pi], Real))
			ints = string(ints, d[:pi], "pi")				# (n)pi
		elseif (isa(d[:pi], Array) || isa(d[:pi], Tuple))
			ints = string(ints, d[:pi][1], "pi", d[:pi][2])	# (n)pi(m)
		end
	elseif (haskey(d, :scale))
		s = arg2str(d[:scale])
		if     (s == "log")                  ints *= 'l'
		elseif (s == "10log" || s == "pow")  ints *= 'p'
		elseif (s == "exp")                  ints *= 'p'
		end
	end
	if     (haskey(d, :phase_add))  ints *= "+" * arg2str(d[:phase_add])::String
	elseif (haskey(d, :phase_sub))  ints *= "-" * arg2str(d[:phase_sub])::String
	end
	_axe = (nBs == 1) ? axe : "x"
	(ints != "") && (opt = " -B" * primo * _axe * ints * opt)
	# If some of afg was explicitly passed
	(afg_z != "") ? (opt *= " -B" * primo * "y" * afg_y * " -Bz" * afg_z) : (afg_y != "") ? (opt *= " -B" * primo * "y" * afg_y) : nothing 
	(is3D && afg_z == "" && (ints == "" || contains(opt_Bframe, 'Z'))) && (opt *= ((gri_d == "g") ? " -Bzafg" : " -Bzaf"))
	(is3D && gri_d == "g" && !contains(opt, "-Bz")) && (opt *= " -Bzg")		# Case of 'frame=(grid=true,)'

	# Check if ax_sup was requested
	(opt == "" && ax_sup != "") && (opt = " -B" * primo * axe * ax_sup)
	have_Baxes = (opt != "")
	opt *= opt_Bframe

	#----------------------------------------------------
	function consume_used(d::Dict, symbs::Vector{Symbol})
		# Remove symbs from 'd' so that at the end we can check for unused entries (user errors) 
		for symb in symbs
			haskey(d, symb) && delete!(d, symb)
		end
	end
	consume_used(d, [:corners, :internal, :cube, :noframe, :pole, :title, :subtitle, :seclabel, :label, :xlabel, :ylabel, :zlabel, :Yhlabel, :alabel, :blabel, :clabel, :annot, :annot_unit, :ticks, :ticks_unit, :prefix, :suffix, :grid, :slanted, :custom, :customticks, :pi, :scale, :phase_add, :phase_sub])
	(length(d) > 0) && println("Warning: the following sub-options were not consumed in 'frame' => ", keys(d))
	# ----------------------------------------------------

	return opt, [have_Baxes, (opt_Bframe != "")]
end

function axis(opt::String, D::Dict; x::Bool=false, y::Bool=false, z::Bool=false, secondary::Bool=false)::Tuple{String, Vector{Bool}}
	# Method for axes setting already passed as a string
	(x && opt[1] != 'x') && (opt = "x" * opt)
	(y && opt[1] != 'y') && (opt = "y" * opt)
	(z && opt[1] != 'z') && (opt = "z" * opt)
	(secondary && !z && opt[1] != 's') && (opt = "s" * opt)
	return " -B" * opt, [false, false]
end

# ------------------------
function helper0_axes(arg)::String
	# Deal with the available ways of specifying the WESN(Z),wesn(z),lbrt(u)
	# The solution is very enginious and allows using "left_full", "l_full" or only "l_f"
	# to mean 'W'. Same for others:
	# bottom|bot|b_f(ull);  right|r_f(ull);  t(op)_f(ull);  up_f(ull)  => S, E, N, Z
	# bottom|bot|b_t(icks); right|r_t(icks); t(op)_t(icks); up_t(icks) => s, e, n, z
	# bottom|bot|b_b(are);  right|r_b(are);  t(op)_b(are);  up_b(are)  => b, r, t, u

	(isa(arg, String) || isa(arg, Symbol)) && return string(arg) # Assume that a WESNwesn was already sent in.
	!isa(arg, Tuple) && error("'axes' argument must be a String, Symbol or a Tuple but was ($(typeof(arg)))")

	opt = "";	lbrtu = "lbrtu";	WSENZ = "WSENZ";	wsenz = "wsenz";	lbrtu = "lbrtu"
	for k = 1:numel(arg)
		t = string(arg[k])::String		# For the case it was a symbol
		if (occursin("_f", t))
			for n = 1:5  (t[1] == lbrtu[n]) && (opt *= WSENZ[n]; continue)  end
		elseif (occursin("_t", t))
			for n = 1:5  (t[1] == lbrtu[n]) && (opt *= wsenz[n]; continue)  end
		elseif (occursin("_b", t))
			for n = 1:5  (t[1] == lbrtu[n]) && (opt *= lbrtu[n]; continue)  end
		end
	end
	return opt
end

# ------------------------
function helper1_axes(arg, is3D::Bool, c::Char)::String
	# Used by annot, ticks and grid to accept also 'auto' and "" to mean automatic
	out::String = arg2str(arg)
	(out != "" && out[1] == 'a') && return ""
	if ((is3D || isa(arg, Tuple)) && ((nc = count_chars(out, '/')) > 0))
		nc == 1 && return @sprintf("%.12g %s%.12g %s%.12g", arg[1], c, arg[1], c, arg[2])::String
		nc == 2 && return @sprintf("%.12g %s%.12g %s%.12g", arg[1], c, arg[2], c, arg[3])::String
	end
	(out != "" && isletter(out[1]) && out[1] != 'p') &&	# "pi" is allowed
		(@warn("Probable misuse of the 'grid' sub-otpion. Defaulting to a valid value."); out = "")
	return out
end
# ------------------------
function helper2_axes(arg)::String
	# Used by
	out::String = arg2str(arg)
	if (out == "")
		@warn("Empty units. Ignoring this units request.");		return out
	end
	if     (out == "Y" || out == "year")     out = "Y"
	elseif (out == "y" || out == "year2")    out = "y"
	elseif (out == "O" || out == "month")    out = "O"
	elseif (out == "o" || out == "month2")   out = "o"
	elseif (out == "U" || out == "ISOweek")  out = "U"
	elseif (out == "u" || out == "ISOweek2") out = "u"
	elseif (out == "r" || out == "Gregorian_week") out = "r"
	elseif (out == "K" || out == "ISOweekday") out = "K"
	elseif (out == "k" || out == "weekday")  out = "k"
	elseif (out == "D" || out == "date")     out = "D"
	elseif (out == "d" || out == "day_date") out = "d"
	elseif (out == "R" || out == "day_week") out = "R"
	elseif (out == "H" || out == "hour")     out = "H"
	elseif (out == "h" || out == "hour2")    out = "h"
	elseif (out == "M" || out == "minute")   out = "M"
	elseif (out == "m" || out == "minute2")  out = "m"
	elseif (out == "S" || out == "second")   out = "S"
	elseif (out == "s" || out == "second2")  out = "s"
	else
		@warn("Unknown units request (" * out * ") Ignoring it")
		out = ""
	end
	return out
end
# ------------------------------------------------------------
function helper3_axes(arg, primo::String, axe::String)::String
	# Parse the custom annotations arg, save result into a tmp file and return its name

	label = [""]
	if (isa(arg, AbstractArray))
		pos, n_annot = arg, length(pos)
		tipo = fill('a', n_annot)			# Default to annotate
	elseif (isa(arg, NamedTuple) || isa(arg, Dict))
		if (isa(arg, NamedTuple))  d = nt2dict(arg)  end
		!haskey(d, :pos) && error("Custom annotations NamedTuple must contain the member 'pos'")
		pos = isa(d[:pos], Vector{<:AbstractRange}) ? collect(d[:pos][1]) : d[:pos]
		n_annot = length(pos);		got_tipo = false
		if ((val = find_in_dict(d, [:type])[1]) !== nothing)
			if (isa(val, Char) || isa(val, String) || isa(val, Symbol))
				tipo = Vector{String}(undef, n_annot)
				for k = 1:n_annot  tipo[k] = string(val)  end	# Repeat the same 'type' n_annot times
			else
				tipo = val		# Assume it's a good guy, otherwise ...
			end
			got_tipo = true
		end

		if (haskey(d, :label))
			_label = d[:label]
			label = isa(_label, Symbol) ? [string(_label)] : (isa(_label, String) ? [_label] : _label)
			n_annot = min(n_annot, length(d[:label]))
			tipo = Vector{String}(undef, n_annot)
			for k = 1:n_annot
				if (isa(label[k], Symbol) || label[k] == "" || label[k][1] != '/')
					tipo[k] = "a"
				else
					t = split(label[k])
					tipo[k] = t[1][2:end]
					if (length(t) > 1)
						label[k] = join([t[n] * " " for n =2:numel(t)])
						label[k] = rstrip(label[k], ' ')		# and remove last ' '
					else
						label[k] = ""
					end
				end
			end
		elseif (!got_tipo)
			tipo = fill("a", n_annot)		# Default to annotate
		end
	else
		@warn("Argument of the custom annotations must be an N-array or a NamedTuple");		return ""
	end

	temp::String = "GMTjl_custom_" * primo * "_" * tmpdir_usr[2]
	(axe != "") && (temp *= axe)
	fname = joinpath(tmpdir_usr[1], temp * ".txt")
	fid = open(fname, "w")
	if (label != [""])
		for k = 1:n_annot
			println(fid, pos[k], ' ', tipo[k], ' ', label[k])
		end
	else
		for k = 1:n_annot
			println(fid, pos[k], ' ', tipo[k])
		end
	end
	close(fid)
	return fname
end

# --------------------------------------------------------
xticks(labels, pos=nothing) = ticks(labels, pos; axis="x")
yticks(labels, pos=nothing) = ticks(labels, pos; axis="y")
zticks(labels, pos=nothing) = ticks(labels, pos; axis="z")
function ticks(labels, pos=nothing; axis="x", primary="p")
	# Simple plot of custom ticks.
	# LABELS can be an Array or Tuple of strings or symbols with the labels to be plotted at ticks in POS
	if (isa(labels, Tuple) && length(labels) == 2 && isa(labels[1], AbstractArray))
		# helper3 wants (Array{Real}, Array{String}) but here we accept both orders, just need to figure out which
		inds = (eltype(labels[1]) <: AbstractString) ? [2,1] : [1,2]
		!(isa(labels[inds[1]], AbstractArray) && eltype(labels[inds[1]][1]) <: Real) &&
			error("Input must be: (Vector{Real}, Vector{String}) (in any order)")
		r = helper3_axes((pos=labels[inds[1]], label=labels[inds[2]]), primary, axis)
	else
		_pos = (pos === nothing) ? (1:length(labels)) : pos
		r = helper3_axes((pos=_pos, label=labels), primary, axis)
	end
	r
end
# ---------------------------------------------------------------------------------------------------

function str_with_blancs(str)::String
	# If the STR string has spaces enclose it with quotes
	out = string(str)
	(occursin(" ", out) && !startswith(out, "\"")) && (out = string("\"", out, "\""))
	return out
end

# ---------------------------------------------------------------------------------------------------
vector_attrib(d::Dict, lixo=nothing) = vector_attrib(; d...)	# When comming from add_opt()
vector_attrib(t::NamedTuple) = vector_attrib(; t...)
function vector_attrib(; kwargs...)::String
	d = KW(kwargs)
	cmd::String = add_opt(d, "", "", [:len :length])
	(haskey(d, :angle)) && (cmd = string(cmd, "+a", d[:angle]))
	if (haskey(d, :middle))
		cmd *= "+m";
		(d[:middle] == "reverse" || d[:middle] == :reverse) && (cmd *= "r")
		cmd = helper_vec_loc(d, :middle, cmd)
	else
		for symb in [:start :stop]
			if (haskey(d, symb) && symb == :start)
				cmd *= "+b";
				cmd = helper_vec_loc(d, :start, cmd)
			elseif (haskey(d, symb) && symb == :stop)
				cmd *= "+e";
				cmd = helper_vec_loc(d, :stop, cmd)
			end
		end
	end

	if (haskey(d, :justify))
		t::Char = string(d[:justify])[1]
		if     (t == 'b')  cmd *= "+jb"		# "begin"
		elseif (t == 'e')  cmd *= "+je"		# "end"
		elseif (t == 'c')  cmd *= "+jc"		# "center"
		end
	end

	if ((val = find_in_dict(d, [:half :half_arrow])[1]) !== nothing)
		cmd = (val == "left" || val == :left) ? cmd * "+l" : cmd * "+r"
	end

	if (haskey(d, :fill))
		if (d[:fill] == "none" || d[:fill] == :none) cmd *= "+g-"
		else
			cmd *= "+g" * get_color(d[:fill])		# MUST GET TESTS TO THIS
			!haskey(d, :pen) && (cmd = cmd * "+p") 	# Let FILL paint the whole header (contrary to >= GMT6.1)
		end
	end

	(haskey(d, :norm)) && (cmd = string(cmd, "+n", arg2str(d[:norm])))
	(haskey(d, :pole)) && (cmd *= "+o" * arg2str(d[:pole])::String)
	if (haskey(d, :pen))
		((p = add_opt_pen(d, [:pen], "")) != "") && (cmd *= "+p" * p)
	end

	if (haskey(d, :shape))
		if (isa(d[:shape], String) || isa(d[:shape], Symbol))
			t = string(d[:shape])[1]
			if     (t == 't')  cmd *= "+h0"		# triang
			elseif (t == 'a')  cmd *= "+h1"		# arrow
			elseif (t == 'V')  cmd *= "+h2"		# V
			else	error("Shape string can be only: 'triang', 'arrow' or 'V'")
			end
		elseif (isa(d[:shape], Real))
			(d[:shape] < -2 || d[:shape] > 2) && error("Numeric shape code must be in the [-2 2] interval.")
			cmd = string(cmd, "+h", d[:shape])
		else
			error("Bad data type for the 'shape' option")
		end
	end

	(haskey(d, :magcolor)) && (cmd *= "+c")
	(haskey(d, :trim)) && (cmd *= "+t" * arg2str(d[:trim]))
	(haskey(d, :ang1_ang2) || haskey(d, :start_stop)) && (cmd *= "+q")
	(haskey(d, :endpoint)  || haskey(d, :endpt)) && (cmd *= "+s")
	(haskey(d, :scale)) && (cmd *= "+v" * arg2str(d[:scale]))
	(haskey(d, :uv)) && (cmd *= "+z" * arg2str(d[:uv]))
	return cmd
end

# ---------------------------------------------------------------------------------------------------
#vector4_attrib(d::Dict, lixo=nothing) = vector4_attrib(; d...)	# When comming from add_opt()
vector4_attrib(t::NamedTuple) = vector4_attrib(; t...)
function vector4_attrib(; kwargs...)::String
	# Old GMT4 vectors (still supported in GMT6)
	d = KW(kwargs)
	cmd::String = "t"
	if ((val = find_in_dict(d, [:align :center])[1]) !== nothing)
		c::Char = string(val)[1]
		if     (c == 'h' || c == 'b')  cmd = "h"		# Head
		elseif (c == 'm' || c == 'c')  cmd = "b"		# Middle
		elseif (c == 'p')              cmd = "s"		# Point
		end
	end
	(haskey(d, :double) || haskey(d, :double_head)) && (cmd = uppercase(cmd))
	(haskey(d, :norm)) && (cmd = string(cmd, "n", d[:norm]))

	if ((val = find_in_dict(d, [:head])[1]) !== nothing)
		if (isa(val, NamedTuple) || isa(val, Dict))
			ha::String = "0.075c";	hl::String = "0.3c";	hw::String = "0.25c"
			dh = isa(val, NamedTuple) ? nt2dict(val) : val
			haskey(dh, :arrowwidth) && (ha = string(dh[:arrowwidth]))
			haskey(dh, :headlength) && (hl = string(dh[:headlength]))
			haskey(dh, :headwidth)  && (hw = string(dh[:headwidth]))
			hh::String = ha * '/' * hl * '/' * hw
		elseif (isa(val, Tuple) && length(val) == 3)  hh = arg2str(val)
		elseif (isa(val, String))                     hh = val		# No checking
		end
		cmd *= hh
	end
	return cmd
end

# -----------------------------------
function helper_vec_loc(d::Dict, symb, cmd::String)::String
	# Helper function for the 'begin', 'middle', 'end' vector attrib function
	(isa(d[symb], Bool) && d[symb]) && return cmd	# We don't want a 'true' becoming a "i"
	t::String = string(d[symb])
	if     (t[1] == 'l'    )	cmd *= "t"		# line
	elseif (t[1] == 'a'    )	cmd *= "a"		# arrow
	elseif (t[1] == 'c'    )	cmd *= "c"		# circle
	elseif (t[1] == 's'    )	cmd *= "s"		# square
	elseif (t[1] == 't'    )	cmd *= "i"		# tail
	elseif (t[1] == 'f'    )	cmd = cmd[1:end-2]	# means false and remove the +? flag set before.
	elseif (t == "open_arrow")	cmd *= "A"
	elseif (t == "open_tail" )	cmd *= "I"
	elseif (startswith(t, "left"))	cmd *= "l"
	elseif (startswith(t, "right"))	cmd *= "r"
	end
	return cmd
end
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
decorated(nt::NamedTuple) = decorated(;nt...)
function decorated(;kwargs...)::String
	d = KW(kwargs)
	cmd::String, optD::String = helper_decorated(d)

	if (haskey(d, :dec2))				# -S~ mode (decorated, with symbols, lines).
		cmd *= ":"
		marca = get_marker_name(d, nothing, [:marker, :symbol], false)[1]	# This fun lieves in psxy.jl
		if (marca == "")
			cmd = "+sa0.5" * cmd
		else
			marca, marca_name = seek_custom_symb(marca, true)	# 'marca' may have been changed to a full name/size
			cmd *= "+s" * marca
			((val = find_in_dict(d, [:size :ms :markersize :symbolsize])[1]) !== nothing) && (cmd *= arg2str(val))
		end
		if (haskey(d, :angle))   cmd = string(cmd, "+a", d[:angle]) end
		if (haskey(d, :debug))   cmd *= "+d"  end
		if (haskey(d, :fill))    cmd *= "+g" * get_color(d[:fill])::String  end
		if (haskey(d, :nudge))   cmd *= "+n" * arg2str(d[:nudge])::String   end
		if (haskey(d, :n_data))  cmd *= "+w" * arg2str(d[:n_data])::String  end
		(optD == "") && (optD = "d")		# Really need to improve the algo of this
		opt_S = " -S~"
	elseif (haskey(d, :quoted))				# -Sq mode (quoted lines).
		cmd *= ":"
		cmd = parse_quoted(d, cmd)
		(optD == "") && (optD = "d")		# Really need to improve the algo of this
		opt_S = " -Sq"
	else									# -Sf mode (front lines).
		((val = find_in_dict(d, [:size])[1]) !== nothing) && (cmd *= "/" * arg2str(val)::String)
		if     (haskey(d, :left))  cmd *= "+l"
		elseif (haskey(d, :right)) cmd *= "+r"
		elseif (haskey(d, :side))
			c::Char = string(d[:side])[1]
			(c == 'l' || c == 'r') && (cmd *= "+" * c)	# Otherwise user screwed and we ignore the 'side'
		end
		if (haskey(d, :symbol))
			symb::Char = string(d[:symbol])[1]
			if (symb == 'b' || symb == 'c' || symb == 'f' || symb == 't' || symb == 's')
				cmd *= "+" * symb
			elseif (symb == 'a')  cmd *= "+S"
			else                  @warn(string("DECORATED: unknown symbol: ", d[:symbol]))
			end
		end
		if (haskey(d, :offset))  cmd *= "+o" * arg2str(d[:offset])::String;	delete!(d, :offset)  end
		opt_S = " -Sf"
	end

	if (haskey(d, :pen))
		cmd *= "+p"
		(!isa(d[:pen], Bool) && !isempty_(d[:pen])) && (cmd *= add_opt_pen(d, [:pen]))
	end
	(haskey(d, :noline)) && (cmd *= "+i")
	return opt_S * optD * cmd
end

# ---------------------------------------------------------
helper_decorated(nt::NamedTuple, compose=false) = helper_decorated(nt2dict(nt), compose)
function helper_decorated(d::Dict, compose=false)
	# Helper function to deal with the gap and symbol size parameters.
	# At same time it's also what we need to call to build up the grdcontour -G option.
	cmd::String = "";	optD::String = ""
	val, symb = find_in_dict(d, [:dist :distance :distmap :number])
	if (val !== nothing)
		# The String assumes all is already encoded. Number, Array only accept numerics
		# Tuple accepts numerics and/or strings.
		if (isa(val, String) || isa(val, Real) || isa(val, Symbol))
			cmd = string(val)
		elseif (isa(val, Array) || isa(val, Tuple))
			if (symb == :number)  cmd = "-" * string(val[1], '/', val[2])::String
			else                  cmd = string(val[1], '/', val[2])
			end
		else
			error("DECORATED: 'dist' (or 'distance') option. Unknown data type.")
		end
		if     (symb == :distmap)  optD = "D"		# Here we know that we are dealing with a -S~ for sure.
		elseif (symb != :number && compose)  optD = "d"		# I fear the case :number is not parsed anywhere
		end
	elseif ((val = find_in_dict(d, [:locations])[1]) !== nothing)
		if (isa(val, AbstractString))  cmd = val
		elseif (GMTver < v"6.4.0" && (isa(val, Matrix) || isa(val, GDtype)))
			cmd = joinpath(tmpdir_usr[1], "GMTjl_decorated_loc_" * tmpdir_usr[2] * ".dat")
			gmtwrite(cmd, val)
		end
		optD = "f"
	end
	if (cmd == "")
		val, symb = find_in_dict(d, [:line :Line])
		flag = (symb == :line) ? 'l' : 'L'
		if (val !== nothing)
			if (isa(val, Array{<:Real}))
				(size(val,2) !=4) && error("DECORATED: 'line' option. When array, it must be an Mx4 one")
				optD = string(flag,val[1,1],'/',val[1,2],'/',val[1,3],'/',val[1,4])
				for k = 2:size(val,1)
					optD = string(optD,',',val[k,1],'/',val[k,2],'/',val[k,3],'/',val[k,4])
				end
			elseif (isa(val, Tuple))
				if (length(val) == 2 && (isa(val[1], String) || isa(val[1], Symbol)) )
					t1::String = string(val[1]);	t2::String = string(val[2])	# t1/t2 can also be 2 char or a LongWord justification
					t1 = startswith(t1, "min") ? "Z-" : justify(t1)
					t2 = startswith(t2, "max") ? "Z+" : justify(t2)
					optD = flag * t1 * "/" * t2
				else
					optD = flag * arg2str(val)
				end
			elseif (isa(val, String))
				optD = flag * val
			else
				@warn("DECORATED: lines option. Unknown option data type. Ignoring this.")
			end
		end
	end
	if (cmd == "" && optD == "")
		optD = ((val = find_in_dict(d, [:n_labels :n_symbols])[1]) !== nothing) ? string("n",val) : "n1"
	end
	if (cmd == "")
		if ((val = find_in_dict(d, [:N_labels :N_symbols])[1]) !== nothing)
			optD = string("N", val);
		end
	end
	if (compose)
		return optD * cmd			# For example for grdgradient -G
	else
		return cmd, optD
	end
end

# -------------------------------------------------
function parse_quoted(d::Dict, opt)::String
	# This function is isolated from () above to allow calling it seperately from grdcontour
	# In fact both -A and -G grdcontour options are almost equal to a decorated line in psxy.
	# So we need a mechanism to call it all at once (psxy) or in two parts (grdcontour).
	cmd::String = (isa(opt, String)) ? opt : ""			# Need to do this to prevent from calls that don't set OPT
	if (haskey(d, :angle))   cmd  = string(cmd, "+a", d[:angle])  end
	if (haskey(d, :debug))   cmd *= "+d"  end
	if (haskey(d, :clearance ))  cmd *= "+c" * arg2str(d[:clearance])::String end
	if (haskey(d, :delay))   cmd *= "+e"  end
	if (haskey(d, :font))    cmd *= "+f" * font(d[:font])::String    end
	if (haskey(d, :color))   cmd *= "+g" * arg2str(d[:color])::String   end
	if (haskey(d, :justify)) cmd = string(cmd, "+j", d[:justify]) end
	if (haskey(d, :const_label)) cmd = string(cmd, "+l", str_with_blancs(d[:const_label]))  end
	if (haskey(d, :nudge))   cmd *= "+n" * arg2str(d[:nudge])::String   end
	if (haskey(d, :rounded)) cmd *= "+o"  end
	if (haskey(d, :min_rad)) cmd *= "+r" * arg2str(d[:min_rad])::String end
	if (haskey(d, :unit))    cmd *= "+u" * arg2str(d[:unit])::String    end
	if (haskey(d, :curved))  cmd *= "+v"  end
	if (haskey(d, :n_data))  cmd *= "+w" * arg2str(d[:n_data])::String  end
	if (haskey(d, :prefix))  cmd *= "+=" * arg2str(d[:prefix])::String  end
	if (haskey(d, :suffices)) cmd *= "+x" * arg2str(d[:suffices])::String  end		# Only when -SqN2
	if (haskey(d, :label))
		if (isa(d[:label], String))
			cmd *= "+L" * d[:label]::String
		elseif (isa(d[:label], Symbol))
			if     (d[:label] == :header)  cmd *= "+Lh"
			elseif (d[:label] == :input)   cmd *= "+Lf"
			else   error("Wrong content for the :label option. Must be only :header or :input")
			end
		elseif (isa(d[:label], Tuple))
			if     (d[:label][1] == :plot_dist)  cmd *= "+Ld" * string(d[:label][2])::String
			elseif (d[:label][1] == :map_dist)   cmd *= "+LD" * parse_units(d[:label][2])
			else   error("Wrong content for the :label option. Must be only :plot_dist or :map_dist")
			end
		else
			@warn("'label' option must be a string or a NamedTuple. Since it wasn't I'm ignoring it.")
		end
	end
	return cmd
end
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
function fname_out(d::Dict, del::Bool=false)
	# Create a file name in the TMP dir when OUT holds only a known extension. The name is: GMT_user.ext

	EXT::String = FMT[1];	fname::AbstractString = ""
	if ((val = find_in_dict(d, [:savefig :figname :name], del)[1]) !== nothing)
		fname, EXT = splitext(string(val)::String)
		EXT = (EXT == "") ? FMT[1] : EXT[2:end]
	end
	if (EXT == FMT[1] && haskey(d, :fmt))
		EXT = string(d[:fmt])::String
		(del) && delete!(d, :fmt)
	end
	(EXT == "" && !Sys.iswindows()) && error("Return an image is only for Windows")

	if (haskey(d, :ps))				# In any case this means we want the PS sent back to Julia
		fname, EXT, ret_ps = "", "ps", true
		(del) && delete!(d, :ps)
		CTRL.returnPS[1] = true		# Reset to false only when showfig or save file
	else
		ret_ps = CTRL.returnPS[1] ? (!IamModern[1] ? true : false) : false	# To know if we want to save PS in mem
	end

	opt_T::String = "";
	if (fname != "" || haskey(d, :show) && d[:show] != 0)	# Only last command (either show or save) may set -T
		(EXT == "pdfg" || EXT == "gpdf") && (EXT = "pdg")	# Trick to keep the ext with only 3 chars (for GeoPDFs)
		ext = lowercase(EXT)
		if     (ext == "ps")   EXT = ext
		elseif (ext == "pdf")  opt_T = " -Tf";	EXT = ext
		elseif (ext == "eps")  opt_T = " -Te";	EXT = ext
		elseif (EXT == "PNG")  opt_T = " -TG";	EXT = "png"		# Don't want it to be .PNG
		elseif (ext == "png")  opt_T = " -Tg";	EXT = ext
		elseif (ext == "jpg")  opt_T = " -Tj";	EXT = ext
		elseif (ext == "tif")  opt_T = " -Tt";	EXT = ext
		elseif (ext == "tiff") opt_T = " -Tt -W+g";	EXT = ext
		elseif (ext == "kml")  opt_T = " -Tt -W+k";	EXT = ext
		elseif (ext == "pdg")  opt_T = " -Tf -Qp";	EXT = "pdf"
		else   error("Unknown graphics file extension (.$EXT)")
		end
	end

	(fname != "") && (fname *= "." * EXT)
	def_name::String = PSname[1]		# "GMT_user.ps" in TMP dir
	return def_name, opt_T, EXT, fname, ret_ps
end

# ---------------------------------------------------------------------------------------------------
function read_data(d::Dict, fname::String, cmd::String, arg, opt_R::String="", is3D::Bool=false, get_info::Bool=false)
	# Use 'get_info=true' to force reading the file when fname != ""
	cmd::String, opt_i::String  = parse_i(d, cmd)	# If data is to be read with some column order
	cmd, opt_bi::String = parse_bi(d, cmd)			# If data is to be read as binary
	cmd, opt_di::String = parse_di(d, cmd)			# If data missing data other than NaN
	cmd, opt_h::String  = parse_h(d, cmd)
	cmd, opt_yx::String = parse_swap_xy(d, cmd)
	#(CTRL.proj_linear[1]) && (opt_yx *= " -fc")	# To avoid the lib remembering last eventual geog case, but it f time
	endswith(opt_yx, "-:") && (opt_yx *= "i")		# Need to be -:i not -: to not swap output too

	(fname == "") && return _read_data(d, cmd, arg, opt_R, is3D, get_info, opt_i, opt_di, opt_yx)

	if (((!IamModern[1] && opt_R == "") || get_info) && !CONVERT_SYNTAX[1])		# Must read file to find -R
		if (!IamSubplot[1] || GMTver > v"6.1.1")	# Protect against a GMT bug
			arg::GDtype = gmt("read -Td " * opt_i * opt_bi * opt_di * opt_h * opt_yx * " " * fname)
			helper_set_colnames!(arg)				# Set colnames if file has a comment line supporting it
			# Try guess if ascii file has time columns and if yes leave trace of it in GMTdadaset metadata.
			(opt_bi == "") && file_has_time!(fname, arg)	# If fname is a .gmt file this does not make much sense.
			# Remove the these options from cmd. Their job is done
			if (opt_i != "")  cmd = replace(cmd, opt_i => "");	opt_i = ""  end
			if (opt_h != "")  cmd = replace(cmd, opt_h => "");	opt_h = ""  end
		end
	else							# No need to find -R so let the GMT module read the file
		cmd = fname * " " * cmd
	end

	no_R = (opt_R == "" || opt_R[1] == '/' || opt_R == " -Rtight")
	if (!CONVERT_SYNTAX[1] && !IamModern[1] && no_R)
		wesn_f64::Matrix{Float64} = gmt("gmtinfo -C" * opt_bi * opt_i * opt_di * opt_h * opt_yx * " " * fname).data	#
		opt_R::String = @sprintf(" -R%.12g/%.12g/%.12g/%.12g", wesn_f64[1], wesn_f64[2], wesn_f64[3], wesn_f64[4])
		(is3D) && (opt_R = @sprintf("%s/%.12g/%.12g", opt_R, wesn_f64[5], wesn_f64[6]))
		cmd *= opt_R
	end

	(SHOW_KWARGS[1]) && return cmd, arg, opt_R, [NaN NaN NaN NaN], ""		# In HELP mode we do nothing here

	_read_data(d, cmd, arg, opt_R, is3D, get_info, opt_i, opt_di, opt_yx)
end

function _read_data(d::Dict, cmd::String, arg, opt_R::String="", is3D::Bool=false, get_info::Bool=false,
	opt_i::String="", opt_di::String="", opt_yx::String="")#::Tuple{String, Union{Nothing, GDtype}, String, Matrix{Float64}, String}
	# In case DATA holds a file name, read that data and put it in ARG
	# Also compute a tight -R if this was not provided. This forces reading a the `fname` file if provided.

	(IamModern[1] && FirstModern[1]) && (FirstModern[1] = false)

	if (haskey(d, :data))
		arg = mat2ds(d[:data]);		delete!(d, [:data])
	elseif (arg === nothing)	# OK, last chance of findig the data is in the x=..., y=... kwargs
		if (haskey(d, :x) && haskey(d, :y))
			_arg = cat_2_arg2(d[:x], d[:y])
			(haskey(d, :z)) && (_arg = hcat(_arg, d[:z][:]);	delete!(d, [:z]))
			delete!(d, [[:x, :x], [:y]])		# [:x :x] to satisfy signature ::Vector{Vector{Symbol}} != ::Array{Array{Symbol}}
			arg = mat2ds(_arg)
		elseif (haskey(d, :x) && length(d[:x]) > 1)	# Only this guy. I guess that histogram may use this
			arg = mat2ds(d[:x]);		delete!(d, [:x])
		end
	end

	# See if we have DateTime objects
	got_datetime, is_onecol = false, false
	if (isa(arg, Vector{DateTime}))					# Must convert to numeric
		min_max::Vector{DateTime} = round_datetime(extrema(arg))		# Good numbers for limits
		arg = mat2ds(Dates.value.(arg) ./ 1000);		cmd *= " --TIME_EPOCH=0000-12-31T00:00:00 --TIME_UNIT=s"
		got_datetime, is_onecol = true, true
	elseif (isa(arg, Matrix{Any}) && typeof(arg[1]) == DateTime)	# Matrix with DateTime in first col
		min_max = round_datetime(extrema(view(arg, :, 1)))
		arg[:,1] = Dates.value.(arg[:,1]) ./ 1000;		cmd *= " --TIME_EPOCH=0000-12-31T00:00:00 --TIME_UNIT=s"
		arg, got_datetime = mat2ds(convert(Matrix{Float64}, arg)), true
	end

	have_info = false
	no_R = (opt_R == "" || opt_R[1] == '/' || opt_R == " -Rtight")
	prj::String = (isGMTdataset(arg)) ? getproj(arg, proj4=true) : ""
	is_geo = contains(prj, "longlat") || contains(prj, "latlong")
	ds_bbox = isGMTdataset(arg) ? (isa(arg, GMTdataset) ? arg.ds_bbox : arg[1].ds_bbox) : Float64[]

	if (!CONVERT_SYNTAX[1] && !IamModern[1] && no_R)	# Here 'arg' can no longer be a file name (string)
		if (opt_i == "" && opt_di == "" && opt_yx == "" && !isempty(ds_bbox))
			wesn_f64::Matrix{<:Float64} = reshape(copy(ds_bbox), 1, length(ds_bbox))
		else
			wesn_f64 = gmt("gmtinfo -C" * opt_i * opt_di * opt_yx, arg).data		# Avoid bloody Any's
		end
		(length(wesn_f64) == 2) && (is_onecol = true)
		have_info = true
		# Workaround a bug/feature in GMT when -: is arround
		if (wesn_f64[1] > wesn_f64[2])  wesn_f64[2], wesn_f64[1] = wesn_f64[1], wesn_f64[2]  end
		if (opt_R != "" && opt_R[1] == '/')			# Modify what will be reported as a -R string
			rs = split(opt_R, '/')
			if (!occursin("?", opt_R))
				# Example "///0/" will set y_min=0 if wesn_f64[3] > 0 and no other changes otherwise
				for k = 2:lastindex(rs)
					(rs[k] == "") && continue
					x = parse(Float64, rs[k])
					if (x == 0.0)
						wesn_f64[k-1] = (wesn_f64[k-1] > 0) ? 0 : wesn_f64[k-1]
					end
				end
			else
				# Example: "/1/2/?/?"  Retain x_min = 1 & x_max = 2 and get y_min|max from data. Used by plotyy
				for k = 2:lastindex(rs)
					(rs[k] != "?") && (wesn_f64[k-1] = parse(Float64, rs[k]))	# Keep value already in previous -R
				end
			end
		end
		if (opt_R != " -Rtight" && (!is_geo || (is_geo && (wesn_f64[2] - wesn_f64[1]) < 360.0)))
			if (!occursin("?", opt_R) && !is_onecol)		# is_onecol is true for DateTime data
				dx::Float64 = (wesn_f64[2] - wesn_f64[1]) * 0.005;	dy::Float64 = (wesn_f64[4] - wesn_f64[3]) * 0.005;
				wesn_f64[1] -= dx;	wesn_f64[2] += dx;	wesn_f64[3] -= dy;	wesn_f64[4] += dy;
				wesn_f64 = round_wesn(wesn_f64, is_geo)		# Add a pad if not-tight
				if (isGMTdataset(arg))						# Needed for the guess_proj case
					if ((wesn_f64[3] < -90 || wesn_f64[4] > 90) || ((wesn_f64[2] - wesn_f64[1]) > 360))
						guessed_J = (prj == "") && !contains(cmd, " -J ") && !contains(cmd, " -JX") && !contains(cmd, " -Jx")
						if (guessed_J || is_geo)
							(wesn_f64[3] < -90.) && (wesn_f64[3] = -90.)
							(wesn_f64[4] >  90.) && (wesn_f64[4] =  90.)
							if ((wesn_f64[2] - wesn_f64[1]) > 360)		# Here are normally fck because above we added a pad
								if ((wesn_f64[1] + wesn_f64[2]) / 2 < 100)  wesn_f64[1] = -180.;	wesn_f64[2] = 180.
								else                                        wesn_f64[1] = 0.;		wesn_f64[2] = 360.
								end
							end
						end
					end
				end
			elseif (!is_onecol)
				t = round_wesn(wesn_f64)		# Add a pad
				for k = 2:lastindex(rs)
					(rs[k] == "?") && (wesn_f64[k-1] = t[k-1])
				end
			end
		else
			cmd = replace(cmd, " -Rtight" => "")	# Must remove old -R
		end
		if (got_datetime)
			opt_R = " -R" * Dates.format(min_max[1], "yyyy-mm-ddTHH:MM:SS.s") * "/" *
			        Dates.format(min_max[2], "yyyy-mm-ddTHH:MM:SS.s")
			(!is_onecol) && (opt_R *= @sprintf("/%.12g/%.12g", wesn_f64[3], wesn_f64[4])::String)
		elseif (is3D)
			opt_R = @sprintf(" -R%.12g/%.12g/%.12g/%.12g/%.10g/%.10g", wesn_f64[1], wesn_f64[2],
			                 wesn_f64[3], wesn_f64[4], wesn_f64[5], wesn_f64[6])
		else
			opt_R = @sprintf(" -R%.12g/%.12g/%.12g/%.12g", wesn_f64[1], wesn_f64[2], wesn_f64[3], wesn_f64[4])
		end
		(opt_R != " -Rtight" && !is_onecol) && (opt_R = merge_R_and_xyzlims(d, opt_R))	# We may have some hanging xyzlim requests
		(!is_onecol) && (cmd *= opt_R)		# The onecol case (for histogram) has an imcomplete -R
	end

	if (!CONVERT_SYNTAX[1] && get_info && !have_info)
		wesn_f64 = gmt("gmtinfo -C" * opt_i * opt_di * opt_yx, arg).data
		if (wesn_f64[1] > wesn_f64[2])		# Workaround a bug/feature in GMT when -: is arround
			wesn_f64[2], wesn_f64[1] = wesn_f64[1], wesn_f64[2]
		end
	elseif (!have_info)
		wesn_f64 = [NaN NaN NaN NaN]		# Need something to return
	end

	return cmd, arg, opt_R, wesn_f64, opt_i
end

# ---------------------------------------------------------------------------------------------------
round_wesn(wesn::Array{Int}, geo::Bool=false, pad=zeros(2)) = round_wesn(float(wesn), geo, pad)
function round_wesn(wesn::Array{Float64, 2}, geo::Bool=false, pad=zeros(2))::Array{Float64, 2}
	# When input is an one row matix return an output of same size
	_wesn = vec(wesn)
	_wesn = round_wesn(_wesn, geo, pad)
	reshape(_wesn, 1, length(_wesn))
end
function round_wesn(_wesn::Vector{Float64}, geo::Bool=false, pad=zeros(2))::Vector{Float64}
	# Use data range to round to nearest reasonable multiples
	# If wesn has 6 elements (is3D), last two are not modified.
	# PAD is an optional 2 elements vector in percentage to extend original limits before rounding
	wesn::Vector{Float64} = copy(_wesn)		# To not change the input
	if (pad != zeros(2))
		dx = (wesn[2] - wesn[1]) * pad[1]
		dy = (wesn[4] - wesn[3]) * pad[2]
		wesn[1:4] = [wesn[1]-dx, wesn[2]+dx, wesn[3]-dy, wesn[4]+dy]
	end
	set::Vector{Bool} = zeros(Bool, 2)
	range::Vector{Float64} = [0.0, 0.0]
	if (wesn[1] == wesn[2])
		wesn[1] -= abs(wesn[1]) * 0.05;	wesn[2] += abs(wesn[2]) * 0.05
		if (wesn[1] == wesn[2])  wesn[1] = -0.1;	wesn[2] = 0.1;	end		# x was = 0
	end
	if (wesn[3] == wesn[4])
		wesn[3] -= abs(wesn[3]) * 0.05;	wesn[4] += abs(wesn[4]) * 0.05
		if (wesn[3] == wesn[4])  wesn[3] = -0.1;	wesn[4] = 0.1;	end		# y was = 0
	end
	range[1] = wesn[2] - wesn[1]
	range[2] = wesn[4] - wesn[3]
	if (geo) 					# Special checks due to periodicity
		if (range[1] > 306.0) 	# If within 15% of a full 360 we promote to 360
			if ((wesn[1] + wesn[2]) / 2 < 100)  wesn[1] = -180.;	wesn[2] = 180.
			else                                wesn[1] = 0.;		wesn[2] = 360.
			end
			set[1] = true
		end
		if (range[2] > 153.0) 	# If within 15% of a full 180 we promote to 180
			wesn[3] = -90.0;	wesn[4] = 90.0
			set[2] = true
		end
	end

	_log10(x) = log(x) / 2.30258509299	# Compute log10 with ln because JET & SnoopCompile acuse it of "failed to optimize"
	item = 1
	for side = 1:2
		set[side] && continue			# Done above */
		mag::Float64 = round(_log10(range[side])) - 1.0
		inc = exp10(mag)
		if ((range[side] / inc) > 10.0) inc *= 2.0	end	# Factor of 2 in the rounding
		if ((range[side] / inc) > 10.0) inc *= 2.5	end	# Factor of 5 in the rounding
		s = 1.0
		if (geo) 	# Use arc integer minutes or seconds if possible
			if (inc < 1.0 && inc > 0.05) 				# Nearest arc minute
				s, inc = 60.0, 1.0
				if ((s * range[side] / inc) > 10.0) inc *= 2.0	end		# 2 arcmin
				if ((s * range[side] / inc) > 10.0) inc *= 2.5	end		# 5 arcmin
			elseif (inc < 0.1 && inc > 0.005) 			# Nearest arc second
				s, inc = 3600.0, 1.0
				if ((s * range[side] / inc) > 10.0) inc *= 2.0	end		# 2 arcsec
				if ((s * range[side] / inc) > 10.0) inc *= 2.5	end		# 5 arcsec
			elseif (inc > 1)							# Nearest degree
				inc = 1.0
			end
			wesn[item] = (floor(s * wesn[item] / inc) * inc) / s;	item += 1;
			wesn[item] = (ceil(s * wesn[item] / inc) * inc) / s;	item += 1;
		else
			# Round BB to the next fifth of a decade.
			one_fifth_dec = inc / 5					# One fifth of a decade
			x = (floor(wesn[item] / inc) * inc);
			wesn[item] = x - ceil((x - wesn[item]) / one_fifth_dec) * one_fifth_dec;	item += 1
			x = (ceil(wesn[item] / inc) * inc);
			wesn[item] = x - floor((x - wesn[item]) / one_fifth_dec) * one_fifth_dec;	item += 1
		end
	end
	CTRL.limits[7:min(12,6+length(wesn))] = wesn[1:min(6,length(wesn))]	# In plot(), at least, we may need to know the plotting limits.
	return wesn
end

# ---------------------------------------------------------------------------------------------------
"""
Round a Vector or Tuple (2 elements) of DateTime type to a nearest nice number to use in plot limits
"""
round_datetime(val::Tuple{DateTime, DateTime}) = round_datetime([val[1], val[2]])
function round_datetime(val::AbstractVector{DateTime})::Vector{DateTime}
	r = Dates.value(val[end] - val[1])
	if (r > 86400000 * 365.25)  rfac = Dates.Year;		add = Dates.Year(1)
	elseif (r > 86400000 * 31)  rfac = Dates.Month;		add = Dates.Month(1)
	elseif (r > 86400000 * 7)   rfac = Dates.Week;		add = Dates.Week(1)
	elseif (r > 86400000)       rfac = Dates.Day;		add = Dates.Day(1)
	elseif (r > 3600000)        rfac = Dates.Hour;		add = Dates.Hour(1)
	elseif (r > 60000)          rfac = Dates.Minute;	add = Dates.Minute(1)
	elseif (r > 1000)           rfac = Dates.Second;	add = Dates.Second(1)
	else                        rfac = Dates.Millisecond;	add = Dates.Millisecond(1)
	end
	return [floor(val[1], rfac)-add, ceil(val[end], rfac)+add]
end

#= ---------------------------------------------------------------------------------------------------
function round_pretty(val)
	log = floor(log10(val))
	frac = (log > 1) ? 4 : 1		# This keeps from adding digits after the decimal
	round(val * frac * 10^ -log) / frac / 10^-log
end
=#

# ---------------------------------------------------------------------------------------------------
"""
    isvector(x)::Bool

Return true if x is a vector in the Matlab sense.
"""
function isvector(x)::Bool
	isa(x, AbstractVector) || (isa(x, Matrix) && ( ((size(x,1) == 1) && size(x,2) > 1) || ((size(x,1) > 1) && size(x,2) == 1) ))
end

# ---------------------------------------------------------------------------------------------------
# Convenient function to tell if x is a GMTdataset (or vector of it) or not
isGMTdataset(x)::Bool = (isa(x, GMTdataset) || isa(x, Vector{<:GMTdataset}))

# ---------------------------------------------------------------------------------------------------
function find_data(d::Dict, cmd0::String, cmd::String, args...)
	# ...

	(SHOW_KWARGS[1]) && return cmd, 0, nothing		# In HELP mode we do nothing here

	got_fname = 0;		data_kw = nothing
	if (haskey(d, :data))  data_kw = d[:data];  delete!(d, :data)  end
	if (cmd0 != "")						# Data was passed as file name
		cmd = cmd0 * " " * cmd
		got_fname = 1
	end

	tipo = length(args)
	if (tipo == 1)
		# Accepts "input1"; arg1; data=input1;
		if (got_fname != 0 || args[1] !== nothing)
			return cmd, got_fname, args[1]		# got_fname = 1 => data is in cmd;	got_fname = 0 => data is in arg1
		elseif (data_kw !== nothing)
			if (isa(data_kw, String))
				cmd = data_kw::String * " " * cmd
				return cmd, 1, args[1]			# got_fname = 1 => data is in cmd
			else
				return cmd, 0, data_kw 			# got_fname = 0 => data is in arg1
			end
		else
			error("Missing input data to run this module.")
		end
	elseif (tipo == 2)			# Two inputs (but second can be optional in some modules)
		# Accepts "input1 input2"; "input1", arg1; "input1", data=input2; arg1, arg2; data=(input1,input2)
		if (got_fname != 0)
			(args[1] === nothing && data_kw === nothing) &&
				return cmd, 1, args[1], args[2]		# got_fname = 1 => all data is in cmd
			(args[1] !== nothing) &&
				return cmd, 2, args[1], args[2]		# got_fname = 2 => data is in cmd and arg1
			(data_kw !== nothing && length(data_kw) == 1) &&
				return cmd, 2, data_kw, args[2]		# got_fname = 2 => data is in cmd and arg1
		else
			if (args[1] !== nothing && args[2] !== nothing)
				return cmd, 0, args[1], args[2]				# got_fname = 0 => all data is in arg1,2
			elseif (args[1] !== nothing && args[2] === nothing && data_kw === nothing)
				return cmd, 0, args[1], args[2]				# got_fname = 0 => all data is in arg1
			elseif (args[1] !== nothing && args[2] === nothing && data_kw !== nothing && length(data_kw) == 1)
				return cmd, 0, args[1], data_kw			# got_fname = 0 => all data is in arg1,2
			elseif (data_kw !== nothing && length(data_kw) == 2)
				return cmd, 0, data_kw[1], data_kw[2]	# got_fname = 0 => all data is in arg1,2
			end
		end
		error("Missing input data to run this module.")
	elseif (tipo == 3)			# Three inputs
		# Accepts "input1 input2 input3"; arg1, arg2, arg3; data=(input1,input2,input3)
		if (got_fname != 0)
			(args[1] !== nothing || data_kw !== nothing) && error("Cannot mix input as file names and numeric data.")
			return cmd, 1, args[1], args[2], args[3]			# got_fname = 1 => all data is in cmd
		else
			(args[1] === nothing && args[2] === nothing && args[3] === nothing) &&
				return cmd, 0, args[1], args[2], args[3]			# got_fname = 0 => ???
			(data_kw !== nothing && length(data_kw) == 3) &&
				return cmd, 0, data_kw[1], data_kw[2], data_kw[3]	# got_fname = 0 => all data in arg1,2,3

			return cmd, 0, args[1], args[2], args[3]
		end
	end
end

# ---------------------------------------------------------------------------------------------------
function write_data(d::Dict, cmd::String)::String
	# Check if we need to save to file (redirect stdout)
	if     ((val = find_in_dict(d, [:|>])[1])     !== nothing)  cmd = string(cmd, " > ", val)
	elseif ((val = find_in_dict(d, [:write])[1])  !== nothing)  cmd = string(cmd, " > ", val)
	elseif ((val = find_in_dict(d, [:append])[1]) !== nothing)  cmd = string(cmd, " >> ", val)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function common_grd(d::Dict, cmd0::String, cmd::String, prog::String, args...)
	n_args = 0
	for k = 1:numel(args) if (args[k] !== nothing)  n_args += 1  end  end	# Drop the nothings
	if     (n_args <= 1)  cmd, got_fname, arg1 = find_data(d, cmd0, cmd, args[1])
	elseif (n_args == 2)  cmd, got_fname, arg1, arg2 = find_data(d, cmd0, cmd, args[1], args[2])
	elseif (n_args == 3)  cmd, got_fname, arg1, arg2, arg3 = find_data(d, cmd0, cmd, args[1], args[2], args[3])
	end
	if (arg1 !== nothing && isa(arg1, Matrix{<:Real}) && startswith(prog, "grd"))  arg1 = mat2grid(arg1)  end
	(n_args <= 1) ? common_grd(d, prog * cmd, arg1) : (n_args == 2) ? common_grd(d, prog * cmd, arg1, arg2) : common_grd(d, prog * cmd, arg1, arg2, arg3)
end

# ---------------------------------------------------------------------------------------------------
function common_grd(d::Dict, cmd::String, args...)
	# This chunk of code is shared by several grdxxx & other modules, so wrap it in a function
	IamModern[1] && (cmd = replace(cmd, " -R " => " "))
	(haskey(d, :Vd) && d[:Vd] > 2) && show_args_types(args...)
	(dbg_print_cmd(d, cmd) !== nothing) && return cmd		# Vd=2 cause this return
	# First case below is of a ARGS tuple(tuple) with all numeric inputs.
	R = isa(args, Tuple{Tuple}) ? gmt(cmd, args[1]...) : gmt(cmd, args...)
	(isGMTdataset(R) && contains(cmd, " -fg") && getproj(R) == "") && (isa(R, GMTdataset) ? R.proj4 = prj4WGS84 : R[1].proj4 = prj4WGS84)
	show_non_consumed(d, cmd)
	return R
end

# ---------------------------------------------------------------------------------------------------
dbg_print_cmd(d::Dict, cmd::String) = dbg_print_cmd(d, [cmd])
function dbg_print_cmd(d::Dict, cmd::Vector{String})
	# Print the gmt command when the Vd>=1 kwarg was used.
	# In case of CONVERT_SYNTAX = true, just put the cmds in a global var 'cmds_history' used in movie

	if (SHOW_KWARGS[1])  SHOW_KWARGS[1] = false; return ""  end	# If in HELP mode

	if ( ((Vd = find_in_dict(d, [:Vd])[1]) !== nothing) || CONVERT_SYNTAX[1])
		(CONVERT_SYNTAX[1]) && return update_cmds_history(cmd)	# For movies mainly.
		(Vd <= 0) && (d[:Vd] = 0)		# Later, if Vd == 0, do not print the "not consumed" warnings
		(Vd <= 0) && return nothing

		if (Vd >= 2)					# Delete these first before reporting
			delete!(d, [[:show], [:leg, :legend], [:box_pos], [:leg_pos], [:figname], [:name], [:savefig]])
			CTRL.pocket_call[3] = nothing	# This is mostly for testing purposes, but potentially needed elsewhere.
			CTRL.limits[1:12] = zeros(12)
			# Some times an automtic CPT has been generated by the Vd'ed cmd but when that happens MUST debug it
			#GMT.CURRENT_CPT[1] = GMT.GMTcpt()		# Can't do this because it would f. plot(..., colorbar=true)
		end
		if (length(d) > 0)
			dd = deepcopy(d)		# Make copy so that we can harmlessly delete those below
			delete!(dd, [[:show], [:leg, :legend], [:box_pos], [:leg_pos], [:fmt, :savefig, :figname, :name], [:linefit, :linearfit]])
			prog = isa(cmd, String) ? split(cmd)[1] : split(cmd[1])[1]
			(length(dd) > 0) && println("Warning: the following options were not consumed in $prog => ", keys(dd))
		end
		(size(LEGEND_TYPE[1].label, 1) != 0) && (LEGEND_TYPE[1].Vd = Vd)	# So that autolegend can also work
		(Vd == 1) && println("\t", length(cmd) == 1 ? cmd[1] : cmd)
		(Vd >= 2) && return length(cmd) == 1 ? cmd[1] : cmd
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function show_args_types(args...)
	for k in eachindex(args)
		args[k] === nothing && break
		println("arg",k, " = ", typeof(args[k]))
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function update_cmds_history(cmd::Vector{String})
	# Separate into fun to work as a function barrier for var stability
	global cmds_history
	cmd_ = cmd[1]			# AND WHAT ABOUT THE OTHER ELEMENTS? DO THEY EXIST?
	if (length(cmds_history) == 1 && cmds_history[1] == "")		# First time here
		cmds_history[1] = cmd_
	else
		push!(cmds_history, cmd_)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
"""
    showfig([fmt="format", figname="figname[.fmt]"])

Finish the PostScript file and convert&display the figure.

- `fmt`: Create the raster figure in format `format`. Default is `fmt=:png`. To get it in PDF do `fmt=:pdf`
- `figname`: To create a figure in local directory and with a name `figname`. If `figname` has an extension
   that is used to select the fig format. *e.g.* `figname=fig.pdf` creates a PDF file localy called 'fig.pdf' 
"""
function showfig(d::Dict, fname_ps::String, fname_ext::String, opt_T::String, K::Bool=false, fname::String="")
	# Take a PS file, convert it with psconvert (unless opt_T == "" meaning file is PS)
	# and display it in default system viewer
	# FNAME_EXT holds the extension when not PS
	# OPT_T holds the psconvert -T option, again when not PS
	# FNAME is for when using the savefig option

	global CURRENT_CPT[1] = GMTcpt()			# Reset to empty when fig is finalized

	digests_legend_bag(d)						# Plot the legend if requested

	if (fname == "" && (isdefined(Main, :IJulia) && Main.IJulia.inited) ||
	                    isdefined(Main, :PlutoRunner) && Main.PlutoRunner isa Module)
		opt_T = " -Tg"; fname_ext = "png"		# In Jupyter or Pluto, png only
	end
	if (opt_T != "")
		(K) && close_PS_file(fname_ps)			# Close the PS file first
		((val = find_in_dict(d, [:dpi :DPI])[1]) !== nothing) && (opt_T *= string(" -E", val))
		gmt("psconvert -A2p -Qg4 -Qt4 " * fname_ps * opt_T * " *")
		reset_theme()
		out::AbstractString = fname_ps[1:end-2] * fname_ext
		(fname != "") && (out = mv(out, fname, force=true))
	elseif (fname_ps != "")
		(K) && close_PS_file(fname_ps)			# Close the PS file first
		out = (fname != "") ? mv(fname_ps, fname, force=true) : fname_ps
	end

	retPluto = false					# To know if we are in Plut
	if (haskey(d, :show) && d[:show] != 0)
		if (isdefined(Main, :IJulia) && Main.IJulia.inited) #|| isdefined(Main, :VSCodeServer)		# From Jupyter?
			#https://stackoverflow.com/questions/70620607/how-can-i-programmatically-check-that-i-am-running-code-in-a-notebook-in-julia
			(fname == "") ? display("image/png", read(out)) : @warn("In Jupyter you can only visualize png files. File $fname was saved in disk though.")
		elseif isdefined(Main, :PlutoRunner) && Main.PlutoRunner isa Module
			retPluto = true
		elseif (!isFranklin[1])			# !isFranklin is true when building the docs and there we don't want displays.
			display_file(out)
		end
		reset_theme()
	end
	CTRL.limits .= 0.0;		CTRL.figsize .= 0.0;	CTRL.proj_linear[1] = true;		# Reset these for safety
	CTRL.pocket_J[1], CTRL.pocket_J[2], CTRL.pocket_J[3], CTRL.pocket_J[4] = "", "", "", "   ";
	CTRL.pocket_R[1] = ""
	return retPluto ? WrapperPluto(out) : nothing	# retPluto should make it all way down to base so that Plut displays it
end

function display_file(out)
	@static if (Sys.iswindows()) out = replace(out, "/" => "\\"); run(ignorestatus(`explorer $out`))
	elseif (Sys.isapple()) run(`open $(out)`)
	elseif (Sys.islinux() || Sys.isbsd()) run(`xdg-open $(out)`)
	end
end

function reset_theme()
	if (ThemeIsOn[1])
		theme_modern();		ThemeIsOn[1] = false
		DEF_FIG_AXES[1] = DEF_FIG_AXES_BAK;		DEF_FIG_AXES3[1] = DEF_FIG_AXES3_BAK;
	end
	desconf()
end
function desconf(resetdef::Bool=true)
	# Undo the gmtset() doing and delete eventual gmt.conf files in current dir.
	!GMTCONF[1] && return nothing			# No gmtset was used in classic or outside a modern mode block	
	resetdef && resetdefaults(G_API[1])		# Set the modern mode settings (will clear eventual gmt.conf contents)
	isfile("gmt.conf") && rm("gmt.conf")	# If gmt.conf file is to be kept, save it at ~.gmt/gmt.conf
	GMTCONF[1] = false
	return nothing
end

# ---------------------------------------------------------------------------------------------------
# Use only to close PS fig and optionally convert/show
function showfig(; kwargs...)
	helper_showfig4modern() && return nothing		# If called from modern mode we are done here.
	d = KW(kwargs)
	(!haskey(d, :show)) && (d[:show] = true)		# The default is to show
	CTRL.limits .= 0.0;		CTRL.proj_linear[1] = true;		# Reset these for safety
	!isempty(LEGEND_TYPE[1].optsDict) && (d[:legend] = dict2nt(LEGEND_TYPE[1].optsDict))	# Recover opt settings
	digests_legend_bag(d)							# Plot the legend if requested
	finish_PS_module(d, "psxy -R0/1/0/1 -JX0.001c -T -O", "", false, true, true)
end
function helper_showfig4modern(show::String="show")::Bool
	# If called from modern mode, do the equivalent of classic to close and show fig
	# Use show="" in modern when only wanting to finish plot but NOT display it.
	!IamModern[1] && return false
	try
		gmt("subplot end");		IamSubplot[1] = false
	catch erro;		println(erro)
	end
	IamModern[1] = false
	isFranklin[1] ? gmt("end") : (show == "") ? gmt("end") : gmt("end " * show)	# isFranklin = true when building the docs
	desconf(false)		# FALSE because modern mode calls do a gmt_restart() in the gmt() main function.
	return true
end

# ---------------------------------------------------------------------------------------------------
function close_PS_file(fname::AbstractString)
	gmt("psxy -T -O >> " * fname)
	# Do the equivalent of "psxy -T -O"
	#=
	fid = open(fname, "a")
	write(fid, "\n0 A\nFQ\nO0\n0 0 TM\n\n")
	write(fid, "%%BeginObject PSL_Layer_2\n0 setlinecap\n0 setlinejoin\n3.32550952342 setmiterlimit\n%%EndObject\n")
	write(fid, "\ngrestore\nPSL_movie_label_completion /PSL_movie_label_completion {} def\n")
	write(fid, "PSL_movie_prog_indicator_completion /PSL_movie_prog_indicator_completion {} def\n")
	write(fid, "%PSL_Begin_Trailer\n%%PageTrailer\nU\nshowpage\n\n%%Trailer\n\nend\n%%EOF")
	close(fid)
	=#
end

# ---------------------------------------------------------------------------------------------------
"""
    add2PSfile(text)

Add commands to the GMT PostScript file while it is not yet finished.

- `text`: is a string, with optional line breaks in it, or a vector of strings.

This option is for PostScript gurus that want/need to mess with the PS plot file in the middle of its construction.
"""
function add2PSfile(txt::Union{String, Vector{String}})
	fid = open(PSname[1], "a")
	if (isa(txt, String))
		write(fid, "\n$txt\n")
	else
		write(fid, "\n");	[println(fid, txt[t]) for t in eachindex(txt)];		write(fid, "\n")
	end
	close(fid)
end

# ---------------------------------------------------------------------------------------------------
function isempty_(arg)::Bool
	# F... F... it's a shame having to do this
	(arg === nothing) && return true
	try
		vazio = isempty(arg)
		return vazio
	catch
		return false
	end
end

# ---------------------------------------------------------------------------------------------------
function put_in_slot(cmd::String, opt::Char, args...)
	# Find the first non-empty slot in ARGS and assign it the val of OPT
	# Return also the index of that first non-empty slot in ARGS
	k = 1
	for arg in args					# Find the first empty slot
		if (arg === nothing)
			cmd = string(cmd, " -", opt)
			break
		end
		k += 1
	end
	return cmd, k
end

# ---------------------------------------------------------------------------------------------------
function arg_in_slot(d::Dict, cmd::String, symbs::VMs, objtype, arg1, arg2)
	# Either put the contents of an option in first empty arg? when it's a GMT type 
	# or add it to cmd if it's a string (e.g., file name) or a number.
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		cmd *= string(" -", symbs[1])
		if (isa(val, objtype))
			_, n = put_in_slot("", ' ', arg1, arg2)
			(n == 1) ? arg1 = val : arg2 = val
		elseif (isa(val, String) || isa(val, Real) || isa(val, Symbol))
			cmd *= string(val)::String
		else  error("Wrong data type ($(typeof(val))) for option $(symbs[1])")
		end
	end
	return cmd, arg1, arg2
end

function arg_in_slot(d::Dict, cmd::String, symbs::VMs, objtype, arg1, arg2, arg3)
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		cmd *= string(" -", symbs[1])
		if (isa(val, objtype))
			_, n = put_in_slot("", ' ', arg1, arg2, arg3)
			(n == 1) ? arg1 = val : (n == 2 ? arg2 = val : arg3 = val)
		elseif (isa(val, String) || isa(val, Real) || isa(val, Symbol))
			cmd *= string(" -", symbs[1], val)::String
		else  error("Wrong data type ($(typeof(val))) for option $(symbs[1])")
		end
	end
	return cmd, arg1, arg2, arg3
end

function arg_in_slot(d::Dict, cmd::String, symbs::VMs, objtype, arg1, arg2, arg3, arg4)
	if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		cmd *= string(" -", symbs[1])::String
		if (isa(val, objtype))
			_, n = put_in_slot("", ' ', arg1, arg2, arg3, arg4)
			(n == 1) ? arg1 = val : (n == 2 ? arg2 = val : (n == 3 ? arg3 = val : arg4 = val))
		elseif (isa(val, String) || isa(val, Real) || isa(val, Symbol))
			cmd *= string(" -", symbs[1], val)::String
		else  error("Wrong data type ($(typeof(val))) for option $(symbs[1])")
		end
	end
	return cmd, arg1, arg2, arg3, arg4
end
# ---------------------------------------------------------------------------------------------------

function last_non_nothing(args...)
	# Return the last element of ARGS that is !== nothing
	k = length(args) + 1
	while (args[k-=1] === nothing && k > 1) end
	(k == 1) && @warn("All elements of `args` === nothing. Expect ...")
	return args[k]
end
function get_first_of_this_type(type::DataType, args...)
	# Return the first in args that is of the requested type, or nothing if not found.
	k = 0
	while (!isa(args[k+=1], type) && k < length(args)) end
	return (k == length(args) && !isa(args[k], type)) ? nothing : args[k]
end
#is_this_type(type::DataType, arg) = isa(arg, type)
#validate_VMr(arg)::VMr = return isa(arg, VMr) ? arg : VMr[]

# ---------------------------------------------------------------------------------------------------
finish_PS_module(d::Dict, cmd::String, opt_extra::String, K::Bool, O::Bool, finish::Bool, args...) =
	finish_PS_module(d, [cmd], opt_extra, K, O, finish, args...)
function finish_PS_module(d::Dict, cmd::Vector{String}, opt_extra::String, K::Bool, O::Bool, finish::Bool, args...)
	# FNAME_EXT hold the extension when not PS
	# OPT_EXTRA is used by grdcontour -D or pssolar -I to not try to create and view an img file

	#while (length(args) > 1 && args[end] === nothing)  pop!(args)  end		# Remove trailing nothings
	
	reverse_plot_axes!(cmd)		# If CTRL.pocket_J[4] != "   " there is some work to do. Otherwise return unchanged

	(!O && CTRL.returnPS[1]) && (CTRL.returnPS[1] = false)	# Ensure that a first call starts in the write to file mode
	output::String, opt_T::String, fname_ext::String, fname, ret_ps = fname_out(d, true)
	(ret_ps) && (output = "") 	 						# Here we don't want to save to file
	cmd, opt_T = prepare2geotif(d, cmd, opt_T, O)		# Settings for the GeoTIFF and KML cases
	(finish) && (cmd = finish_PS(d, cmd, output, K, O))

	have_Vd = haskey(d, :Vd)
	(have_Vd && d[:Vd] > 2) && show_args_types(args...)
	if ((r = dbg_print_cmd(d, cmd)) !== nothing)  return length(r) == 1 ? r[1] : r  end
	IMG_MEM_LAYOUT[1] = add_opt(d, "", "", [:layout])
	(IMG_MEM_LAYOUT[1] == "images") && (IMG_MEM_LAYOUT[1] = "I   ")		# Special layout for Images.jl

	if (fname_ext != "ps" && !IamModern[1] && !O)		# Exptend to a larger paper size
		cmd[1] *= " --PS_MEDIA=32767x32767"				# In Modern mode GMT takes care of this.
	elseif (fname_ext == "ps" && !IamModern[1] && !O)	# First time that a return PS is asked
		cmd[1] *= " --PS_MEDIA=1194x1441"				# add 600 pt to A4 to account for the 20 cm
	end

	orig_J::String = ""		# To use in the case of a double Cartesian/Geog frame.
	fi = 1
	if (CTRL.pocket_call[3] !== nothing)	# Case where we want to run a "pre command" whose data is in pocket_call[3]
		P = (isa(CTRL.pocket_call[3], String)) ? gmt(cmd[1]) : gmt(cmd[1], CTRL.pocket_call[3]) 
		CTRL.pocket_call[3] = nothing		# Reset
		fi = 2		# First index, the one that the args... respect, start at 2
	end
	for k = fi:lastindex(cmd)
		is_psscale = (startswith(cmd[k], "psscale") || startswith(cmd[k], "colorbar"))
		is_pscoast = (startswith(cmd[k], "pscoast") || startswith(cmd[k], "coast"))
		is_basemap = (startswith(cmd[k], "psbasemap") || startswith(cmd[k], "basemap"))
		if (k >= 1+fi && is_psscale && !isa(args[1], GMTcpt))	# Ex: imshow(I, cmap=C, colorbar=true)
			arg1  = add_opt_cpt(d, cmd[k], CPTaliases, 'C', 0, nothing, nothing, false, false, "", true)[2]
			(arg1 === nothing && haskey(d, :this_cpt)) && (arg1 = gmt("makecpt -C" * d[:this_cpt]::String))	# May bite back.
			(arg1 === nothing && isa(args[1], GMTimage) && !isempty(args[1].colormap)) && (arg1 = cmap2cpt(args[1]))
			(arg1 === nothing) && (@warn("No cmap found to use in colorbar. Ignoring this command."); continue)
			(arg1.label[1] != "") && (cmd[k] = replace(cmd[k], "-Baf" => "-L0.1c"))	# If it has labels, use them. The gap should be calculated.
			P = gmt(cmd[k], arg1)
			continue
		elseif (k >= 1+fi && (is_pscoast || is_basemap) && (isa(args[1], GMTimage) || isa(args[1], GMTgrid)))
			proj4::String = args[1].proj4
			(proj4 == "" && args[1].wkt != "") && (proj4 = toPROJ4(importWKT(args[1].wkt)))
			if ((proj4 != "") && !startswith(proj4, "+proj=lat") && !startswith(proj4, "+proj=lon"))
				opt_J = replace(proj4, " " => "")
				lims = args[1].range
				D::GMTdataset = mapproject([lims[1] lims[3]; lims[2] lims[4]], J=opt_J, I=true)
				xmi::Float64, ymi::Float64, xma::Float64, yma::Float64 = D.data[1],D.data[3],D.data[2],D.data[4]
				opt_R::String = @sprintf(" -R%f/%f/%f/%f+r ", xmi,ymi,xma,yma)
				o = scan_opt(cmd[1], "-J")
				size_::String = (o[1] == 'x') ? "+scale=" * o[2:end] : (o[1] == 'X') ? "+width=" * o[2:end] : ""
				(size_ == "") && @warn("Could not find the right fig size used. Result will be wrong")  
				cmd[k] = replace(cmd[k], " -J" => " -J" * opt_J * size_)
				cmd[k] = replace(cmd[k], " -R" => opt_R)
				have_Vd && println("\t",cmd[k])		# Useful to know what command was actually executed.
				orig_J, orig_R::String = o, scan_opt(cmd[1], "-R")
			end
		elseif (k >= 1+fi && !is_psscale && !is_pscoast && !is_basemap && CTRL.pocket_call[1] !== nothing)
			# For nested calls that need to pass data
			P = gmt(cmd[k], CTRL.pocket_call[1])
			CTRL.pocket_call[1] = nothing			# Clear it right away
			continue
		elseif (startswith(cmd[k], "psclip"))		# Shitty case. Pure (unique) psclip requires args. Compose cmd not
			P = (CTRL.pocket_call[1] !== nothing) ? gmt(cmd[k], CTRL.pocket_call[1]) :
			                                        (length(cmd) > 1) ? gmt(cmd[k]) : gmt(cmd[k], args...)
			CTRL.pocket_call[1] = nothing					# For the case it was not yet empty
			continue
		end
		P = gmt(cmd[k], args...)

		# If we had a double frame to plot Geog on a Cartesian plot we must reset memory to original -J & -R so
		# that appending other plots to same fig can continue to work and not fail because proj had become Geog.
		apenda = ((orig_J != "") && !CTRL.returnPS[1]) ? " >> " : ""
		(orig_J != "") && (gmt("psxy -T -J" * orig_J * " -R" * orig_R * " -O -K" * apenda * output);  orig_J = "")
	end

	leave_paper_mode()				# See if we were in an intermediate state of paper coordinates
	if (usedConfPar[1])				# Hacky shit to force start over when --PAR options were use
		usedConfPar[1] = false;		#gmt_restart()
		theme_modern()
	end

	if (!IamModern[1])
		if (fname_ext == "" && opt_extra == "")		# Return result as an GMTimage
			P = showfig(d, output, fname_ext, "", K)
			CTRL.limits .= 0.0
			LEGEND_TYPE[1] = legend_bag()
			gmt_restart()							# Returning a PS screws the session
		elseif ((haskey(d, :show) && d[:show] != 0) || fname != "" || opt_T != "")
			P = showfig(d, output, fname_ext, opt_T, K, fname)	# Return something here for the case we are in Pluto
			(typeof(P) == Base.Process) && (P = nothing)		# Don't want spurious message on REPL when plotting
			CTRL.IamInPaperMode[2] = true			# Means, next time a paper mode is used offset XY only on first call 
			CTRL.limits .= 0.0
			LEGEND_TYPE[1] = legend_bag()
		end
	elseif ((haskey(d, :show) && d[:show] != 0))	# Let modern mode also call show=true
		helper_showfig4modern()
		CTRL.limits .= 0.0
		LEGEND_TYPE[1] = legend_bag()
	end
	CTRL.XYlabels[1] = "";	CTRL.XYlabels[2] = "";	# Reset these in case they weren't empty
	show_non_consumed(d, cmd)
	#(GMTver < v"6.5" && isa(P, GMTps)) && gmt_restart()
	return P
end

#= --------------------------------------------------------------------------------------------------
function do_the_plot(cmd::String, O::Bool, args...)
	P = gmt(cmd, args...)
	(CTRL.limits[4] == 0 && CTRL.limits[5] == 0 && CTRL.limits[6] == 0) && return P
	if (CTRL.limits[4] != 0)
	end
end
=#

# --------------------------------------------------------------------------------------------------
function reverse_plot_axes!(cmd::Vector{String})
	# See if there are requests to change axes directions. If yes we change the -J in the cmd[1] string
	# CTRL.pocket_J = [opt_J width opt_Jz codes-to-tell-which-axis-to-reverse]
	(CTRL.pocket_J[4] == "   ") && return
	s = split(CTRL.pocket_J[2],"/")
	s1 = (CTRL.pocket_J[4][1] != ' ') ? "-" * s[1] : s[1]
	s2 = (CTRL.pocket_J[4][2] != ' ' && length(s) == 2) ? "-" * s[2] : (length(s) == 2 ? s[2] : "")

	if (s[1] == '-' || (s2 != "" && s2[1] == '-'))	# It will not be the case if only Z dim flip was requested
		newsize = (length(s) == 2) ? s1 * "/" * s2 : s1
		t = replace(CTRL.pocket_J[1], CTRL.pocket_J[2] => newsize)
		cmd[1] = replace(cmd[1], CTRL.pocket_J[1] => t)
	end
	if (CTRL.pocket_J[4][3] != ' ' && CTRL.pocket_J[3] != "")		# OK, here we have to patch the -JZ option
		t = CTRL.pocket_J[3][1:4] * "-" * CTRL.pocket_J[3][5:end]
		cmd[1] = replace(cmd[1], CTRL.pocket_J[3] => t)
		CTRL.pocket_J[3] = ""
	end

	CTRL.pocket_J[4] = "   "			# It's enough to reset this one only
	nothing
end

# --------------------------------------------------------------------------------------------------
"""
    regiongeog(GI)::Tuple

Returns a tuple with (lon_min, lon_max, lat_min, lat_max) of the projected `GI` object limits converted
to geographic coordinates. Returns an empty tuple if `GI` has no registered referencing system.
`GI` can either a `GMTgrid`, a `GMTimage` or a file name (String) of one those types.
"""
function regiongeog(GI::GItype)::Tuple
	((prj = getproj(GI, wkt=true)) == "") && (@warn("Input grid/image has no projection info"); return ())
	c = xy2lonlat([GI.range[1] GI.range[3]; GI.range[2] GI.range[4]]; s_srs=prj)
	tuple(c...)
end
function regiongeog(fname::String)::Tuple
	((prj = getproj(fname, wkt=true)) == "") && (@warn("Input grid/image has no projection info"); return ())
	info = grdinfo(fname, C=true);		# It should also report the
	c = xy2lonlat([info.data[1] info.data[3]; info.data[2] info.data[4]]; s_srs=prj)
	tuple(c...)
end

# --------------------------------------------------------------------------------------------------
"""
    append2fig(fname::String)

Move the file `fname` to the default name and location (GMT_user.ps in tmp). The `fname` should be
a PS file that has NOT been closed. Posterior calls to plotting methods will append to this file.
Useful when creating figures that use a common base map that may be heavy (slow) to compute.
"""
function append2fig(fname::String)
	mv(fname, PSname[1], force=true); nothing
end

# --------------------------------------------------------------------------------------------------
function show_non_consumed(d::Dict, cmd)
	# First delete some that could not have been delete earlier (from legend for example)
	delete!(d, [[:fmt], [:show], [:leg, :legend], [:box_pos], [:leg_pos], [:P, :portrait], [:this_cpt], [:linefit, :linearfit]])
	!isempty(CURRENT_CPT[1]) && delete!(d, [[:percent], [:clim]])	# To not (wrongly) complain about these
	if (!haskey(d, :Vd) && length(d) > 0)		# Vd, if exists, must be a Vd=0 to signal no warnings.
		prog = isa(cmd, String) ? split(cmd)[1] : split(cmd[1])[1]
		println("Warning: the following options were not consumed in $prog => ", keys(d))
	end
	(haskey(d, :Vd) && d[:Vd] == 0) && delete!(d, :Vd)	# It was a "use once only" option.
end

# --------------------------------------------------------------------------------------------------
mutable struct legend_bag
	label::Vector{String}
	cmd::Vector{String}
	cmd2::Vector{String}
	opt_l::String
	optsDict::Dict
	Vd::Int
end
legend_bag() = legend_bag(Vector{String}(), Vector{String}(), Vector{String}(), "", Dict(), 0)

# --------------------------------------------------------------------------------------------------
function put_in_legend_bag(d::Dict, cmd, arg, O::Bool=false, opt_l::String="")
	# So far this fun is only called from plot() and stores line/symbol info in a const global var LEGEND_TYPE

	_valLegend = find_in_dict(d, [:legend], false)[1]	# false because we must keep it alive till digests_legend_bag()
	_valLabel  = find_in_dict(d, [:label])[1]			# These guys are always Any
	((_valLegend === nothing || _valLegend == "") && _valLabel === nothing) && return # Nothing to do here

	function assign_colnames(arg)
		# Return the columname(s) to be used a entries in a legend
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
			_valLabel = find_in_dict(dd, [:label], false)[1]
			if ((isa(_valLabel, String) || isa(_valLabel, Symbol)))
				_valLab = string(_valLabel)::String
				(lowercase(_valLab) == "colnames") ? (valLabel_vec = assign_colnames(arg)) : valLabel = _valLab
			elseif (_valLabel !== nothing)
				valLabel_vec = [string.(_valLabel)...]		# We may have shits here
			end
			if ((ribs = find_in_dict(dd, [:ribbon :band], false)[1]) !== nothing)
				(valLabel != "") && (valLabel_vec = [valLabel, string(ribs)::String]; valLabel="")	# *promote* valLabel
				have_ribbon = true
			end

		elseif (isa(_valLegend, String) || isa(_valLegend, Symbol))
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
		if     (t == "")          pens[k] = " -W0."
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
			rgb = [0.0, 0.0, 0.0]
			P::Ptr{GMT.GMT_PALETTE} = palette_init(G_API[1], CURRENT_CPT[1])	# A pointer to a GMT CPT
			gmt_get_rgb_from_z(G_API[1], P, arg[gindex[1],ind], rgb)
			cmd_[1] *= " -G" * arg2str(rgb.*255)
			for k = 1:numel(pens)
				gmt_get_rgb_from_z(G_API[1], P, arg[gindex[k+1],ind]+10eps(), rgb)
				pens[k] *= " -G" * arg2str(rgb.*255)
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

	(!O) && (LEGEND_TYPE[1] = legend_bag())		# Make sure that we always start with an empty one

	if (size(LEGEND_TYPE[1].label, 1) == 0)		# First time
		LEGEND_TYPE[1] = legend_bag(lab, [cmd_[1]], length(cmd_) == 1 ? [""] : [cmd_[2]], opt_l, dd, 0)
		# Forgot about the logic of the above and it errors when first arg is a GMTdataset vec,
		# so do this till a decent fix gets invented.
		(length(lab) > 1) && (LEGEND_TYPE[1] = legend_bag(lab, cmd_, cmd_, opt_l, dd, 0))
	else
		append!(LEGEND_TYPE[1].cmd, [cmd_[1]])
		append!(LEGEND_TYPE[1].cmd2, (length(cmd_) > 1) ? [cmd_[2]] : [""])
		append!(LEGEND_TYPE[1].label, lab)
	end

	return nothing
end

# --------------------------------------------------------------------------------------------------
function digests_legend_bag(d::Dict, del::Bool=true)
	# Plot a legend if the leg or legend keywords were used. Legend info is stored in LEGEND_TYPE global variable
	(size(LEGEND_TYPE[1].label, 1) == 0) && return

	dd::Dict = ((val = find_in_dict(d, [:leg :legend], false)[1]) !== nothing && isa(val, NamedTuple)) ? nt2dict(val) : Dict{Symbol, Any}()

	kk, fs = 0, 8				# Font size in points
	symbW = 0.65				# Symbol width. Default to 0.75 cm (good for lines but bad for symbols)
	nl, count_no = length(LEGEND_TYPE[1].label), 0
	leg::Vector{String} = Vector{String}(undef, 3nl)
	all(contains.(LEGEND_TYPE[1].cmd, "-S")) && (symbW = 0.25)	# When all entries are symbols shrink the 'symbW'

	#lab_width = maximum(length.(LEGEND_TYPE[1].label[:])) * fs / 72 * 2.54 * 0.50 + 0.25	# Guess label width in cm
	# Problem is that we may have a lot more chars in label than those effectively printed (PS octal chars etc)
	n_max_chars = 0
	for k = 1:numel(LEGEND_TYPE[1].label)
		s = split(LEGEND_TYPE[1].label[k], "`")		# Means that after the '`' comes the this string char counting
		n_chars = (length(s) == 2) ? (LEGEND_TYPE[1].label[k] = s[1]; parse(Int,s[2])) : length(LEGEND_TYPE[1].label[k])
		n_max_chars = max(n_chars, n_max_chars)
	end
	lab_width = n_max_chars * fs / 72 * 2.54 * 0.50 + 0.25	# Guess label width in cm

	for k = 1:nl						# Loop over number of entries
		(LEGEND_TYPE[1].label[k] == " ") && (count_no += 1;	continue)	# Sometimes we may want to open a leg entry but not plot it
		if ((symb = scan_opt(LEGEND_TYPE[1].cmd[k], "-S")) == "")  symb = "-"
		else                                                       symbW_ = symb[2:end];
		end
		((fill = scan_opt(LEGEND_TYPE[1].cmd[k], "-G")) == "") && (fill = "-")
		pen  = scan_opt(LEGEND_TYPE[1].cmd[k], "-W");
		(pen == "" && symb[1] != '-' && fill != "-") ? pen = "-" : (pen == "" ? pen = "0.25p" : pen = pen)
		if (symb[1] == '-')
			leg[kk += 1] = @sprintf("S %.3fc %s %.2fc %s %s %.2fc %s",
			                symbW/2, symb[1], symbW, fill, pen, symbW+0.14, LEGEND_TYPE[1].label[k])
			if ((symb2 = scan_opt(LEGEND_TYPE[1].cmd2[k], "-S")) != "")		# A line + a symbol
				leg[kk += 1] = "G -1l"			# Go back one line before plotting the overlaying symbol
				xx = split(pen, ',')
				if (length(xx) == 2)  fill = xx[2]
				else                  fill = ((c = scan_opt(LEGEND_TYPE[1].cmd2[k], "-G")) != "") ? c : "black"
				end
				penS = scan_opt(LEGEND_TYPE[1].cmd2[k], "-W");
				leg[kk += 1] = @sprintf("S - %s %s %s %s - %s", symb2[1], symb2[2:end], fill, penS, "")
			end
		elseif (symb[1] == '~' || symb[1] == 'q' || symb[1] == 'f')
			if (startswith(symb, "~d"))
				ind = findfirst(':', symb)
				(ind === nothing) && error("Error: missing colon (:) in decorated string opt.")
				symb = string(symb[1],"n1", symb[ind[1]:end])
			end
			leg[kk += 1] = @sprintf("S - %s %s %s %s - %s", symb, symbW, fill, pen, LEGEND_TYPE[1].label[k])
		else
			leg[kk += 1] = @sprintf("S - %s %s %s %s - %s", symb[1], symbW_, fill, pen, LEGEND_TYPE[1].label[k])	# Who is this?
		end
	end
	(count_no > 0) && (resize!(leg, nl-count_no))

	(haskey(dd, :fontsize)) && (fs = dd[:fontsize])
	
	fnt::String = (haskey(dd, :font)) ? font(dd[:font]) : string(fs)
	if (fnt != string(fs))
		s = split(fnt, ',')
		(length(s) == 1) &&  (fnt = string(fs, ',', s[1]))				# s[1] must be font name
		(length(s) == 2) &&  (fnt = string(fs, ',', s[1], ',', s[2]))	# s[1] font name, s[2] font color
	end

	# Because we accept extended settings either from first or last legend() commands we must seek which
	# one may have the desired keyword. First command is stored in 'LEGEND_TYPE[1].optsDict' and last in 'dd'
	_d = (haskey(dd, :pos) || haskey(dd, :position)) ? dd :
	     (haskey(LEGEND_TYPE[1].optsDict, :pos) || haskey(LEGEND_TYPE[1].optsDict, :position)) ?
		 LEGEND_TYPE[1].optsDict : Dict()

	_opt_D = (((val = find_in_dict(_d, [:pos :position], false)[1]) !== nothing) && isa(val, StrSymb)) ? string(val)::String : ""
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
				s = split(LEGEND_TYPE[1].cmd[1], " -B")
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

	_d = (haskey(dd, :box) && dd[:box] !== nothing) ? dd : haskey(LEGEND_TYPE[1].optsDict, :box) ? LEGEND_TYPE[1].optsDict : Dict()
	if ((opt_F::String = add_opt(_d, "", "", [:box],
		(clearance="+c", fill=("+g", add_opt_fill), inner="+i", pen=("+p", add_opt_pen), rounded="+r", shade="+s"), false)) == "")
		opt_F = "+p0.5+gwhite"
	else
		if (opt_F == "none")
			opt_F = "+gwhite"
		else
			(!occursin("+p", opt_F)) && (opt_F *= "+p0.5")
			(!occursin("+g", opt_F)) && (opt_F *= "+gwhite")
		end
	end
	
	if (LEGEND_TYPE[1].Vd > 0)  d[:Vd] = LEGEND_TYPE[1].Vd;  dbg_print_cmd(d, leg[1:kk])  end	# Vd=2 wont work
	(LEGEND_TYPE[1].Vd > 0) && println("F=",opt_F, " D=",opt_D, " font=",fnt)
	gmt_restart()		# Some things with the themes may screw
	legend!(text_record(leg[1:kk]), F=opt_F, D=opt_D, par=(:FONT_ANNOT_PRIMARY, fnt))
	LEGEND_TYPE[1] = legend_bag()			# Job done, now empty the bag

	return nothing
end

# --------------------------------------------------------------------------------------------------
"""
    str = scan_opt(cmd::AbstractString, opt::String, keepX=false)

Scans the CMD string for the OPT option. Note, OPT must be a 2 chars -X GMT option.
'keepX' retains the OPT 2 chars -X GMT option in output.

### Example
    scan_opt(" -Baf", "-B", true)
	" -Baf"
"""
function scan_opt(cmd::AbstractString, opt::String, keepX::Bool=false)::String
	out = ((ind = findfirst(opt, cmd)) !== nothing) ? (ind[end] == length(cmd)) ? "" : strtok(cmd[ind[1]+2:end])[1] : ""
	(out != "" && cmd[ind[1]+2] == ' ') && (out = "")		# Because seeking -R in a " -R -JX" would ret "-JX"
	(keepX && out != "") && (out = string(' ', opt, out))	# Keep the option flag in output
	return out
end

# --------------------------------------------------------------------------------------------------
function justify(arg, nowarn::Bool=false)::String
	# Take a string or symbol in ARG and return the two chars justification code.
	isa(arg, Symbol) && (arg = string(arg))
	(length(arg) == 2) && return arg		# Assume it's already the 2 chars code (no further checking)
	_arg::String = lowercase(arg)
	if     (startswith(_arg, "topl"))     out = "TL"
	elseif (startswith(_arg, "middlel"))  out = "ML"
	elseif (startswith(_arg, "bottoml"))  out = "BL"
	elseif (startswith(_arg, "topc"))     out = "TC"
	elseif (startswith(_arg, "middlec"))  out = "MC"
	elseif (startswith(_arg, "bottomc"))  out = "BC"
	elseif (startswith(_arg, "topr"))     out = "TR"
	elseif (startswith(_arg, "middler"))  out = "MR"
	elseif (startswith(_arg, "bottomr"))  out = "BR"
	else
		if (nowarn)  out = arg		# Just return unchanged
		else         @warn("Justification code provided ($arg) is not valid. Defaulting to TopRight");	out = "TR"
		end
	end
	return out
end

# --------------------------------------------------------------------------------------------------
"""
    frac = interp_vec(x, val)

Returns the positional fraction that `val` ocupies in the `x` vector 
"""
function interp_vec(x, val)
	(val < x[1] || val > x[end]) && error("Interpolating point ($val) is not inside the vector range [$(x[1]) $(x[end])].")
	k = 0
	while(val < x[k+=1]) end
	frac = (val - x[k]) / (x[k+1] - x[k])
	return k + frac
end

# --------------------------------------------------------------------------------------------------
function help_show_options(d::Dict)
	if (find_in_dict(d, [:help])[1] !== nothing)  SHOW_KWARGS[1] = true  end	# Put in HELP mode
end

# --------------------------------------------------------------------------------------------------
function print_kwarg_opts(symbs::VMs, mapa=nothing)::String
	# Print the kwargs options
	opt::String = "Option: " * join([@sprintf("%s, or ",x) for x in symbs])[1:end-5]::String
	if (isa(mapa, NamedTuple))
		keys_ = keys(mapa)
		vals = Vector{String}(undef, length(keys_))
		for k = 1:numel(keys_)
			t = mapa[keys_[k]]
			vals[k] = (isa(t, Tuple)) ? "?(" * t[1]::String : "?(" * t::String
			if (length(vals[k]) > 2 && vals[k][3] == '_')  vals[k] = "Any(" * vals[k][4:end]  end
		end
		sub_opt::String = join([@sprintf("%s=%s), ",keys_[k], vals[k]) for k = 1:numel(keys_)])
		opt *= " => (" * sub_opt * ")"
	elseif (isa(mapa, String))
		opt *= " => " * mapa::String
	else
		opt *= " => Tuple | String | Number | Bool [Possibly not yet expanded]"
	end
	println(opt)
	return ""		# Must return != nothing so that dbg_print_cmd() signals stop progam's execution
end

# --------------------------------------------------------------------------------------------------
function gmthelp(opt)
	SHOW_KWARGS[1] = true
	if (isa(opt, Array{Symbol}))
		for o in opt  gmthelp(o)  end
	else
		o::String = string(opt)
		try
			(length(o) <= 2) ? getfield(GMT, Symbol(string("parse_",o)))(Dict(), "") : getfield(GMT, Symbol(o))(help=1) 
		catch err
			println("   ==>  '$o' is not a valid option/module name, or its help is not yet implemented")
			println("   LastError ==>  '$err'")
		end
	end
	SHOW_KWARGS[1] = false
	return nothing
end

# --------------------------------------------------------------------------------------------------
macro var"?"(name)
	# Macro to open module manuals that have individual html pages.
	# For other functions that are exported but do not have individual pages we get a 404
	quote
		try
			getfield(Main, Symbol($name))
			s = string("https://www.generic-mapping-tools.org/GMTjl_doc/documentation/modules/", $name,"/")
			display_file(s)
		catch err
			println(err)
		end
	end
end
