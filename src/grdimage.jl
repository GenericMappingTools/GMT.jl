"""
    grdimage(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; kwargs...)

Produces a gray-shaded (or colored) map by plotting rectangles centered on each grid node and assigning
them a gray-shade (or color) based on the z-value.

Parameters
----------

- **A** | **img_out** | **image_out** :: [Type => Str]

    Save an image in a raster format instead of PostScript.
- $(_opt_J)
- $(_opt_B)
- $(opt_C)
- **D** | **img_in** | **image_in** :: [Type => Str]

    Specifies that the grid supplied is an image file to be read via GDAL.
- **E** | **dpi** :: [Type => Int]

    Sets the resolution of the projected grid that will be created.
- **G** | **bit_color** :: [Type => Int]

- **I** | **shade** | **shading** | **intensity** :: [Type => Bool | Str | GMTgrid]

    Gives the name of a grid file or GMTgrid with intensities in the (-1,+1) range,
    or a grdgradient shading flags.
- **M** | **monochrome** :: [Type => Bool]

    Force conversion to monochrome image using the (television) YIQ transformation.
- **N** | **noclip** :: [Type => Bool]

    Do not clip the image at the map boundary.
- $(opt_P)
- **Q** | **alpha_color** | **nan_alpha** :: [Type => Bool | Tuple | Str]	``Q = true | Q = (r,g,b)``

    Make grid nodes with z = NaN transparent, or pick a color for transparency in a image.
- $(_opt_R)
- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)
- $(_opt_f)
- $(opt_n)
- $(_opt_p)
- $(_opt_t)
- $(opt_savefig)

To see the full documentation type: ``@? grdimage``
"""
function grdimage(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; first=true, kwargs...)
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode
	_grdimage(cmd0, arg1, arg2, arg3, O, K, d)
end
function _grdimage(cmd0::String, arg1, arg2, arg3, O::Bool, K::Bool, d::Dict)

	arg4 = nothing		# For the r,g,b + intensity case
	first = !O
	(cmd0 != "" && arg1 === nothing && haskey(d, :inset)) && (arg1 = gmtread(cmd0); cmd0 = "")
	common_insert_R!(d, O, cmd0, arg1)			# Set -R in 'd' out of grid/images (with coords) if limits was not used
	
	# Remote files with no -R are all global. Set CTRL.limits so we can guess the projection.
	(!haskey(d, :R) && any(startswith.(cmd0, ["@earth_", "@mars_", "@pluto_", "@moon_", "@venus_"]))) &&
		(CTRL.limits[1:4] = CTRL.limits[7:10] = [-180, 180, -90, 90])

	if (arg1 === nothing && haskey(d, :R) && guess_T_from_ext(cmd0) == " -Ti")
		_opt_R = d[:R]
		t = (isa(_opt_R, Tuple) || isa(_opt_R, VMr)) ?
			["$(_opt_R[1])", "$(_opt_R[2])", "$(_opt_R[3])", "$(_opt_R[4])"] : split(_opt_R, '/')
		opts = ["-projwin", t[1], t[4], t[2], t[3]]		# -projwin <ulx> <uly> <lrx> <lry>
		I = cut_with_gdal(cmd0, opts)
		(arg1 === nothing) ? arg1 = I : ((arg2 === nothing) ? arg2 = I : ((arg3 === nothing) ? arg3 = I : arg4 = I))
		cmd0 = ""
	end

	# Prevent that J=guess is applied to a non-geog grid/image
	(arg1 !== nothing && (symb = is_in_dict(d, [:proj :projection])) !== nothing && (d[symb] == "guess" || d[symb] == :guess) && !isgeog(arg1)) &&
		delete!(d, symb)

	has_opt_B = (is_in_dict(d, [:B :frame :axis :axes]) !== nothing)
	(is_in_dict(d, [:A :img_out :image_out]) !== nothing) && (d[:B] = "none")	# When -A is used, -B is forbiden
	cmd::String, opt_B::String, opt_J::String, opt_R::String = parse_BJR(d, "", "", O, " -JX" * split(DEF_FIG_SIZE, '/')[1] * "/0")
	(startswith(opt_J, " -JX") && !contains(opt_J, "/")) && (cmd = replace(cmd, opt_J => opt_J * "/0")) # When sub-regions
	(!has_opt_B && isa(arg1, GMTimage) && (isimgsize(arg1) || CTRL.limits[1:4] == zeros(4)) && opt_B == DEF_FIG_AXES_BAK) &&
		(cmd = replace(cmd, opt_B => ""))			# Dont plot axes for plain images if that was not required

	cmd, = parse_common_opts(d, cmd, [:UVXY :params :margin :c :f :n :p :t]; first=first)
	cmd  = parse_these_opts(cmd, d, [[:A :img_out :image_out], [:D :img_in :image_in], [:E :dpi], [:G :bit_color],
	                                 [:M :monochrome], [:N :noclip], [:Q :nan_alpha :alpha_color]])
	cmd = add_opt(d, cmd, "%", [:layout :mem_layout])
	cmd = add_opt(d, cmd, "T", [:T :no_interp :tiles], (skip="_+s", skip_nan="_+s", outlines=("+o", add_opt_pen)))

	if (isa(arg1, GMTgrid) && length(opt_R) > 3 && !isapprox(CTRL.limits[1:4], arg1.range[1:4]))
		# If a -R is used and grid is in mem, better to crop it right now. Also helps with getting the auto CPT from crop
		arg1 = grdcut(arg1, R=opt_R[4:end], J=opt_J[4:end])
		got_fname = 0
	else
		cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)		# Find how data was transmitted
		if (got_fname == 0 && isa(arg1, Tuple))		# Then it must be using the three r,g,b grids
			cmd, got_fname, arg1, arg2, arg3 = find_data(d, cmd0, cmd, arg1, arg2, arg3)
		end
	end

	if (isa(arg1, Matrix{<:Real}) || isa(arg1, Array{<:Real,3}))
		if (isa(arg1, Matrix{UInt8}) || isa(arg1, Matrix{UInt16}) || isa(arg1, Array{UInt8,3}))
			arg1 = mat2img(arg1; d...)
		else
			arg1 = mat2grid(arg1)
			(isa(arg2, Matrix{<:Real})) && (arg2 = mat2grid(arg2))
			(isa(arg3, Matrix{<:Real})) && (arg3 = mat2grid(arg3))
		end
	elseif (isa(arg1, GMTimage) && size(arg1, 3) <= 3 && eltype(arg1.image) <: UInt16)
		arg1 = mat2img(arg1; d...)
		(haskey(d, :stretch) || haskey(d, :histo_bounds)) && delete!(d, [:histo_bounds, :stretch])
	end

	set_defcpt!(d, cmd0, arg1)	# When dealing with a remote grid assign it a default CPT
	(isa(arg1, GMTgrid) && arg1.cpt != "") && (d[:this_cpt] = arg1.cpt)
	(haskey(d, :this_cpt) && isfile(d[:this_cpt])) && (CURRENT_CPT[1] = gmtread(d[:this_cpt]))

	cmd, _, arg1, arg2, arg3 = common_get_R_cpt(d, cmd0, cmd, opt_R, got_fname, arg1, arg2, arg3, "grdimage")
	cmd, arg1, arg2, arg3, arg4 = common_shade(d, cmd, arg1, arg2, arg3, arg4, "grdimage")

	if (isa(arg1, GMTimage) && !occursin("-Q", cmd))
		if (!occursin("-D", cmd))  cmd *= " -D"  end	# Lost track why but need this so gmt_main knows it should init a img
		#(!occursin("-D", cmd) && !occursin(" -C", cmd)) && (cmd *= " -D")	# Lost track why but need this so gmt_main knows it should init a img
		(length(opt_J) > 3 && (opt_J[4] != 'X' && opt_J[4] != 'x')) && (cmd *= "r")	# GMT crashes when just -D and proj
	end

	do_finish = false
	_cmd = ["grdimage " * cmd]
	_cmd = frame_opaque(_cmd, opt_B, opt_R, opt_J; bot=false)		# No -t in frame
	if (!occursin("-A", cmd))			# -A means that we are requesting the image directly
		(haskey(d, :inset)) && (CTRL.pocket_call[4] = arg1)			# If 'inset', it may be needed from next call
		_cmd = finish_PS_nested(d, _cmd)
		if ((ind = findfirst(startswith.(_cmd, "inset_"))) !== nothing)	# inset commands must be the last ones
			ins = popat!(_cmd, ind)		# Remove the 'inset' command
			append!(_cmd, [ins])		# and add it at the end
		end
		if (startswith(_cmd[end], "inset_") && isa(CTRL.pocket_call[4], String))
			_cmd = zoom_reactangle(_cmd, false)
		end
		do_finish = true
	end

	if (length(_cmd) > 1 && cmd0 != "")		# In these cases no -R is passed so the nested calls set an unknown -R
		for k = 2:lastindex(_cmd)  _cmd[k] = replace(_cmd[k], "-R " => "-R" * cmd0 * " ")  end
	end
	finish_PS_module(d, _cmd, "", K, O, do_finish, arg1, arg2, arg3, arg4)
end

# ---------------------------------------------------------------------------------------------------
function common_insert_R!(d::Dict, O::Bool, cmd0, I_G; is3D=false)
	# Set -R in 'd' under several conditions. We may need this to make -J=:guess to work
	O && return
	CTRL.limits .= 0.0			# Have to play safe on this because some eventual show calls may have left this non-empty
	opt_R::String = ""

	# When grdview and -p is used we must set also Z lims in -R. If p does not have 'elev' we do nothing 
	function add_Zlims_in_R(d, opt_R, zmin, zmax)
		((val = find_in_dict(d, [:p :view :perspective], false)[1]) === nothing) && return opt_R	# Nothing to change
		!contains(arg2str(val), '/') && return opt_R	# Just p=azim, nothing to change in -R
		t = round_wesn([zmin zmin zmax zmax])			# Raw numbers gives uggly limits
		return @sprintf("%s/%.15g/%.15g", opt_R, t[1], t[4])
	end

	if ((val = find_in_dict(d, [:R :region :limits], false)[1]) === nothing && (isa(I_G, GItype)))
		opt_R = @sprintf("%.15g/%.15g/%.15g/%.15g", I_G.range[1], I_G.range[2], I_G.range[3], I_G.range[4])	# auto inset-zoom needs it
		if (isa(I_G, GMTgrid) || !isimgsize(I_G))
			is3D && (opt_R = add_Zlims_in_R(d, opt_R, I_G.range[5], I_G.range[6]))
			d[:R] = opt_R
		end
	elseif (val === nothing && IamModern[1] && CTRL.limits[13] == 1.0)
		# Should it apply also to classic? And should the -R be rebuilt here?
	elseif (val === nothing && (isa(cmd0, String) && cmd0 != "") && !CONVERT_SYNTAX[1] && snif_GI_set_CTRLlimits(cmd0))
		opt_R = @sprintf("%.15g/%.15g/%.15g/%.15g", CTRL.limits[1], CTRL.limits[2], CTRL.limits[3], CTRL.limits[4])
		is3D && (opt_R = add_Zlims_in_R(d, opt_R, CTRL.limits[5], CTRL.limits[6]))
		d[:R] = opt_R
	elseif (val !== nothing)
		if (isa(val, StrSymb))
			s = string(val)::String
			d[:R] = (s == "global" || s == "d") ? (-180,180,-90,90) : (s == "global360" || s == "g") ? (0,360,-90,90) : val
		elseif (isa(val, Tuple) || isa(val, VMr))
			d[:R] = val
		end
		try			# Can't risk to error here
			opt_R = @sprintf("%.15g/%.15g/%.15g/%.15g", d[:R][1], d[:R][2], d[:R][3], d[:R][4])
		catch
		end
		delete!(d, [:region, :limits])
	end
	(opt_R != "") && (CTRL.pocket_R[1] = " -R" * opt_R)
end
function isimgsize(GI)::Bool
	width, height = getsize(GI)
	(GI.range[2] - GI.range[1]) == width && (GI.range[4] - GI.range[3]) == height
end

# ---------------------------------------------------------------------------------------------------
function common_shade(d::Dict, cmd::String, arg1, arg2, arg3, arg4, prog)
	# Used both by grdimage and grdview
	symbs = [:I :shade :shading :intensity]
	(SHOW_KWARGS[1]) && return print_kwarg_opts(symbs, "GMTgrid | String"), arg1, arg2, arg3, arg4

	if ((val = find_in_dict(d, symbs, false)[1]) !== nothing)
		if (!isa(val, GMTgrid))			# Uff, simple. Either a file name or a -A type modifier
			if (isa(val, String) || isa(val, Symbol) || isa(val, Bool))
				val_str::String = arg2str(val)
				(val_str == "" || val_str == "default" || val_str == "auto") ? cmd *= " -I+a-45+nt1" : cmd *= " -I" * val_str
    		else
				cmd = add_opt(d, cmd, "I", [:I :shading :shade :intensity],
							  (auto = "_+", azim = "+a", azimuth = "+a", norm = "+n", default = "_+d+a-45+nt1"))
			end
		else
			valG::GMTgrid = val
			if (prog == "grdimage")  cmd, N_used = put_in_slot(cmd, 'I', arg1, arg2, arg3, arg4)
			else                     cmd, N_used = put_in_slot(cmd, 'I', arg1, arg2, arg3)
			end
			(N_used == 1) ? arg1 = valG : ((N_used == 2) ? arg2 = valG : ((N_used == 3) ? arg3 = valG : arg4 = valG))
		end
		delete!(d, [:I, :shade, :shading, :intensity])
	end
	return cmd, arg1, arg2, arg3, arg4
end

# ---------------------------------------------------------------------------------------------------
grdimage!(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; kw...) =
	grdimage(cmd0, arg1, arg2, arg3; first=false, kw...) 

grdimage(arg1,  arg2=nothing, arg3=nothing; kw...) = grdimage("", arg1, arg2, arg3; first=true, kw...)
grdimage!(arg1, arg2=nothing, arg3=nothing; kw...) = grdimage("", arg1, arg2, arg3; first=false, kw...)
