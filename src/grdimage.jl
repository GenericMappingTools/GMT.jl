"""
    grdimage(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; kwargs...)

Produces a gray-shaded (or colored) map by plotting rectangles centered on each grid node and assigning them a gray-shade (or color) based on the z-value.

Full option list at [`grdimage`]($(GMTdoc)grdimage.html)

Parameters
----------

- **A** | **img_out** | **image_out** :: [Type => Str]

    Save an image in a raster format instead of PostScript.
    ($(GMTdoc)grdimage.html#a)
- $(GMT.opt_J)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **D** | **img_in** | **image_in** :: [Type => Str]

    Specifies that the grid supplied is an image file to be read via GDAL.
    ($(GMTdoc)grdimage.html#d)
- **E** | **dpi** :: [Type => Int]

    Sets the resolution of the projected grid that will be created.
    ($(GMTdoc)grdimage.html#e)
- **G** | **bit_color** :: [Type => Int]

    ($(GMTdoc)grdimage.html#g)
- **I** | **shade** | **shading** | **intensity** :: [Type => Bool | Str | GMTgrid]

    Gives the name of a grid file or GMTgrid with intensities in the (-1,+1) range,
    or a grdgradient shading flags.
    ($(GMTdoc)grdimage.html#i)
- **M** | **monochrome** :: [Type => Bool]

    Force conversion to monochrome image using the (television) YIQ transformation.
    ($(GMTdoc)grdimage.html#m)
- **N** | **noclip** :: [Type => Bool]

    Do not clip the image at the map boundary.
    ($(GMTdoc)grdimage.html#n)
- $(GMT.opt_P)
- **Q** | **alpha_color** | **nan_alpha** :: [Type => Bool | Tuple | Str]	``Q = true | Q = (r,g,b)``

	Make grid nodes with z = NaN transparent, or pick a color for transparency in a image.
- $(GMT.opt_R)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_f)
- $(GMT.opt_n)
- $(GMT.opt_p)
- $(GMT.opt_t)
"""
function grdimage(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; first=true, kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("grdimage", cmd0, arg1, arg2, arg3)
	arg4 = nothing		# For the r,g,b + intensity case

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode
	common_insert_R!(d, O, cmd0, arg1)			# Set -R in 'd' out of grid/images (with coords) if limits was not used

	has_opt_B = (find_in_dict(d, [:B :frame :axis :axes], false)[1] !== nothing)
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX" * split(def_fig_size, '/')[1] * "/0")
	(!has_opt_B && isa(arg1, GMTimage) && (isimgsize(arg1) || CTRL.limits[1:4] == zeros(4)) && opt_B == def_fig_axes) &&
		(cmd = replace(cmd, opt_B => ""))	# Dont plot axes for plain images if that was not required

	cmd, = parse_common_opts(d, cmd, [:UVXY :params :c :f :n :p :t], first)
	cmd  = parse_these_opts(cmd, d, [[:A :img_out :image_out], [:D :img_in :image_in], [:E :dpi], [:G :bit_color],
	                                 [:M :monochrome], [:N :noclip], [:Q :nan_alpha :alpha_color]])
	cmd = add_opt(d, cmd, "%", [:layout :mem_layout], nothing)

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)		# Find how data was transmitted
	if (got_fname == 0 && isa(arg1, Tuple))			# Then it must be using the three r,g,b grids
		cmd, got_fname, arg1, arg2, arg3 = find_data(d, cmd0, cmd, arg1, arg2, arg3)
	end

	if (isa(arg1, Array{<:Real}))
		if (isa(arg1, Array{UInt8}) || isa(arg1, Array{UInt16}))
			arg1 = mat2img(arg1; d...)
		else
			arg1 = mat2grid(arg1)
			(isa(arg2, Array{<:Real})) && (arg2 = mat2grid(arg2))
			(isa(arg3, Array{<:Real})) && (arg3 = mat2grid(arg3))
		end
	end

	# if (GMTver >= v"6.1" && occursin("earth_relief_", cmd0))  push!(d, :this_cpt => "geo")  end	# Make this the default CPT

	cmd, N_used, arg1, arg2, arg3 = common_get_R_cpt(d, cmd0, cmd, opt_R, got_fname, arg1, arg2, arg3, "grdimage")
	cmd, arg1, arg2, arg3, arg4   = common_shade(d, cmd, arg1, arg2, arg3, arg4, "grdimage")

	if (isa(arg1, GMTimage) && !occursin("-Q", cmd))
		if (!occursin("-D", cmd))  cmd *= " -D"  end	# GMT bug. It says not need but it is.
	end

	do_finish = false
	if (!occursin("-A", cmd))			# -A means that we are requesting the image directly
		_cmd, K = finish_PS_nested(d, ["grdimage " * cmd], K)
		do_finish = true
	else
		_cmd = ["grdimage " * cmd]
	end
	(isa(arg1, GMTimage) && GMTver <= v"6.1.1" && !occursin("-A", _cmd[1])) && (arg1 = ind2rgb(arg1))	# Prev to 6.2 indexed imgs lost colors

	_cmd, K = finish_PS_nested(d, _cmd, K)
	return finish_PS_module(d, _cmd, "", K, O, do_finish, arg1, arg2, arg3, arg4)
end

# ---------------------------------------------------------------------------------------------------
function common_insert_R!(d::Dict, O::Bool, cmd0, I_G)
	# Set -R in 'd' under several conditions. We may need this to make -J=:guess to work
	O && return
	if ((val = find_in_dict(d, [:R :region :limits], false)[1]) === nothing && (isa(I_G, GMTimage) || isa(I_G, GMTgrid)))
		if (isa(I_G, GMTgrid) || !isimgsize(I_G))
			d[:R] = sprintf("%.15g/%.15g/%.15g/%.15g", I_G.range[1], I_G.range[2], I_G.range[3], I_G.range[4])
		end
	elseif ((isa(cmd0, String) && cmd0 != "") && (CTRL.limits[1:4] != zeros(4) || snif_GI_set_CTRLlimits(cmd0)) )
		d[:R] = sprintf("%.15g/%.15g/%.15g/%.15g", CTRL.limits[1], CTRL.limits[2], CTRL.limits[3], CTRL.limits[4])
	end
end
function isimgsize(I_G)
	xy = (length(I_G.layout) > 1 && I_G.layout[2] == 'R') ? [1,2] : [2,1]	# 'R' means array is row major and first dim is xx
	(I_G.range[2] - I_G.range[1]) == size(I_G, xy[1]) && (I_G.range[4] - I_G.range[3]) == size(I_G, xy[2])
end

# ---------------------------------------------------------------------------------------------------
function common_shade(d::Dict, cmd::String, arg1, arg2, arg3, arg4, prog)
	# Used both by grdimage and grdview
	symbs = [:I :shade :shading :intensity]
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "GMTgrid | String"), arg1, arg2, arg3, arg4

	if ((val = find_in_dict(d, symbs, false)[1]) !== nothing)
		if (!isa(val, GMTgrid))			# Uff, simple. Either a file name or a -A type modifier
			if (isa(val, String) || isa(val, Symbol) || isa(val, Bool))
				val = arg2str(val)
				(val == "" || val == "default" || val == "auto") ? cmd *= " -I+a-45+nt1" : cmd *= " -I" * val
    			else
				cmd = add_opt(d, cmd, 'I', [:I :shading :shade :intensity],
							  (auto = "_+", azim = "+a", azimuth = "+a", norm = "+n", default = "_+d+a-45+nt1"))
			end
		else
			if (prog == "grdimage")  cmd, N_used = put_in_slot(cmd, val, 'I', [arg1, arg2, arg3, arg4])
			else                     cmd, N_used = put_in_slot(cmd, val, 'I', [arg1, arg2, arg3])
			end
			if (N_used == 1)  arg1 = val
			elseif (N_used == 2)  arg2 = val
			elseif (N_used == 3)  arg3 = val
			elseif (N_used == 4)  arg4 = val	# grdview doesn't have this case but no harm to not test for that
			end
		end
		del_from_dict(d, [:I :shade :shading :intensity])
	end
	return cmd, arg1, arg2, arg3, arg4
end

# ---------------------------------------------------------------------------------------------------
function common_get_R_cpt(d::Dict, cmd0::String, cmd::String, opt_R::String, got_fname::Int, arg1, arg2, arg3, prog::String)
	# Used by several proggys
	if (convert_syntax[1])		# Here we cannot rist to execute any code. Just parsing. Movie stuff
		cmd, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C')
		N_used = !isempty_(arg1) + !isempty_(arg2) + !isempty_(arg3)
	else
		cmd, N_used, arg1, arg2, arg3 = get_cpt_set_R(d, cmd0, cmd, opt_R, got_fname, arg1, arg2, arg3, prog)
	end
	return cmd, N_used, arg1, arg2, arg3
end

# ---------------------------------------------------------------------------------------------------
grdimage!(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; kw...) =
	grdimage(cmd0, arg1, arg2, arg3; first=false, kw...) 

grdimage(arg1,  arg2=nothing, arg3=nothing; kw...) = grdimage("", arg1, arg2, arg3; first=true, kw...)
grdimage!(arg1, arg2=nothing, arg3=nothing; kw...) = grdimage("", arg1, arg2, arg3; first=false, kw...)
