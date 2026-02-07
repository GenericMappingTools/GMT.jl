"""
	grdlandmask([monolithic::String="";] area=, resolution=, bordervalues=, save=, maskvalues=, registration=, verbose=, cores=)

Create a grid file with set values for land and water.

Read the selected shoreline database and create a grid to specify which nodes in the specified grid
are over land or over water. The nodes defined by the selected region and lattice spacing will be
set according to one of two criteria: (1) land vs water, or (2) the more detailed (hierarchical)
ocean vs land vs lake vs island vs pond.

See full GMT docs at [`grdlandmask`]($(GMTdoc)grdlandmask.html)

Parameters
----------

- $(_opt_R)
- $(opt_I)
- **A** | **area** :: [Type => Str | Number]

    Features with an area smaller than min_area in km^2 or of hierarchical level that is lower than min_level
    or higher than max_level will not be plotted.
- **D** | **res** | **resolution** :: [Type => Str]

    Selects the resolution of the data set to use ((f)ull, (h)igh, (i)ntermediate, (l)ow, and (c)rude).
- **E** | **border** | **bordervalues** :: [Type => Str | List]    ``Arg = cborder/lborder/iborder/pborder or bordervalue``

    Nodes that fall exactly on a polygon boundary should be considered to be outside the polygon
    [Default considers them to be inside].
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdlandmask(....) form.
- **N** | **maskvalues** | **mask** :: [Type => Str | List]    ``Arg = wet/dry or ocean/land/lake/island/pond``

    Sets the values that will be assigned to nodes. Values can be any number, including the textstring NaN
- $(opt_V)
- $(opt_r)
- $(opt_x)

To see the full documentation type: ``@? grdlandmask``
"""
grdlandmask(cmd0::String; kwargs...) = grdlandmask_helper(cmd0, nothing; kwargs...)
grdlandmask(arg1::GItype; kwargs...) = grdlandmask_helper("", arg1; kwargs...)
grdlandmask(; kwargs...)             = grdlandmask_helper("", nothing; kwargs...)
function grdlandmask_helper(cmd0::String, arg1; kwargs...)
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	grdlandmask_helper(cmd0, arg1, d)
end

# ---------------------------------------------------------------------------------------------------
function grdlandmask_helper(cmd0::String, arg1, d::Dict{Symbol, Any})

    cmd::String, prj::String = "", ""
	if (arg1 !== nothing)
		prj = getproj(arg1, proj4=true)
		(contains(prj, "=lon") || contains(prj, "=lat")) && (prj = "")  # Cool, it's geog, no proj needed.
		if (prj == "")
			d[:R] = @sprintf("%.12g/%.12g/%.12g/%.12g", arg1.range[1:4]...)
			d[:I] = @sprintf("%.12g/%.12g", arg1.inc[1:2]...)
		else
			t = xy2lonlat([arg1.range[1] 0; arg1.range[2] 0; 0 arg1.range[3]; 0 arg1.range[4]], s_srs=prj, t_srs="+proj=longlat +datum=WGS84")
			d[:R] = @sprintf("%.12g/%.12g/%.12g/%.12g", t[1, 1], t[2, 1], t[3, 2], t[4, 2])
			height, width = dims(arg1)
			d[:I] = "$(width)" * "+n/" * "$(height)" * "+n"
		end
		isa(arg1, GMTgrid) ? (cmd *= " -&" * arg1.layout) : (cmd *= " -%" * arg1.layout)
	end
	cmd, = parse_common_opts(d, cmd, [:G :RIr :V_params :x])
	cmd  = parse_these_opts(cmd, d, [[:A :area], [:D :res :resolution], [:E :border :bordervalues]])
	opt_N = add_opt(d, "", "N", [:N :mask :maskvalues])
	cmd *= opt_N
	r = common_grd(d, "grdlandmask " * cmd, nothing)		# Finish build cmd and run it
	if (arg1 !== nothing && prj != "")			# project the mask grid to be compatible with the original grid.
		r.z = reshape(r.z, width, height)
		r = gdalwarp(r, ["-of","MEM","-t_srs",prj,"-ts","$(width)", "$(height)", "-te", @sprintf("%.12g", arg1.range[1]), @sprintf("%.12g", arg1.range[3]), @sprintf("%.12g", arg1.range[2]), @sprintf("%.12g", arg1.range[4])], layout=r.layout)	# Many things can go wrong here.
	end
	if (isa(arg1, GMTgrid))
		if (r.hasnans == 2 || opt_N == "")  r *= arg1	# If clipping val is NaN or 0
		else
			cv = parse(Float32, split(opt_N[4:end], "/")[1])
			mask = isnodata(r.z, cv)
			r.z[mask] .= 1				# First set the clipping zone to neutral
			r *= arg1					# Apply mask
			r.z[mask] .= cv				# Then set the clipping value back
			r.range[5], r.range[6] = max(r.range[5], cv), max(r.range[6], cv)
		end
	elseif (isa(arg1, GMTimage))		# Here, if image is RGB we may say insitu=true to get the alpha added to original
		mask = isnodata(r)
		I = size(arg1,3) == 1 ? ind2rgb(arg1) : (find_in_dict(d, [:insitu])[1] !== nothing) ? arg1 : deepcopy(arg1)
		image_alpha!(I, alpha_band=mask)
		return I
	end
	return r
end
