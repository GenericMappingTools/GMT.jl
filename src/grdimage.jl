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
- **Q** | **nan_t** | **nan_alpha** :: [Type => Bool]

    Make grid nodes with z = NaN transparent, using the colormasking feature in PostScript Level 3.
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

	d = KW(kwargs)
	help_show_options(d)			# Check if user wants ONLY the HELP mode
    K, O = set_KO(first)			# Set the K O dance

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd, = parse_common_opts(d, cmd, [:UVXY :params :c :f :n :p :t], first)
	cmd  = parse_these_opts(cmd, d, [[:A :img_out :image_out], [:D :img_in :image_in], [:E :dpi], [:G :bit_color],
	                                 [:M :monochrome], [:N :noclip], [:Q :nan_t :nan_alpha], ["," :mem :mem_layout]])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)		# Find how data was transmitted
	if (got_fname == 0 && isa(arg1, Tuple))			# Then it must be using the three r,g,b grids
		cmd, got_fname, arg1, arg2, arg3 = find_data(d, cmd0, cmd, arg1, arg2, arg3)
	end

	if (isa(arg1, Array{<:Number}))
		if (isa(arg1, Array{UInt8}) || isa(arg1, Array{UInt16}))
			arg1 = mat2img(arg1; d...)
		else
			arg1 = mat2grid(arg1)
			(isa(arg2, Array{<:Number})) && (arg2 = mat2grid(arg2))
			(isa(arg3, Array{<:Number})) && (arg3 = mat2grid(arg3))
		end
	end

	#if (GMTver >= 6.1 && occursin("earth_relief_", cmd0))  push!(d, :this_cpt => "geo")  end	# Make this the default CPT

	cmd, N_used, arg1, arg2, arg3 = common_get_R_cpt(d, cmd0, cmd, opt_R, got_fname, arg1, arg2, arg3, "grdimage")
	cmd, arg1, arg2, arg3, arg4 = common_shade(d, cmd, arg1, arg2, arg3, arg4, "grdimage")

	if (isa(arg1, GMTimage))
		if (!occursin("-D", cmd))  cmd *= " -D"  end	# GMT bug. It says not need but it is.
		if (isa(arg1.image, Array{UInt16}))
			arg1 = mat2img(arg1; d...)					# Get a new UInt8 scaled image
			if (haskey(d, :histo_bounds))  delete!(d, :histo_bounds)  end
		end
	end

	cmd = "grdimage " * cmd				# In any case we need this
	do_finish = false
	if (!occursin("-A", cmd))			# -A means that we are requesting the image directly
		cmd, K = finish_PS_nested(d, cmd, "", K, O, [:coast :colorbar :basemap])
		do_finish = true
	end
	return finish_PS_module(d, cmd, "", K, O, do_finish, arg1, arg2, arg3, arg4)
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
				cmd = add_opt(cmd, 'I', d, [:I :shading :shade :intensity],
							  (auto="_+", azim="+a", azimuth="+a", norm="+n", default="_+d+a-45+nt1"))
			end
		else
			if (prog == "grdimage")  cmd, N_used = put_in_slot(cmd, val, 'I', [arg1, arg2, arg3, arg4])
			else                     cmd, N_used = put_in_slot(cmd, val, 'I', [arg1, arg2, arg3])
			end
			if     (N_used == 1)  arg1 = val
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
function common_get_R_cpt(d::Dict, cmd0::String, cmd::String, opt_R, got_fname, arg1, arg2, arg3, prog::String)
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
grdimage!(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; first=false, kw...) =
	grdimage(cmd0, arg1, arg2, arg3; first=false, kw...) 

grdimage(arg1,  arg2=nothing, arg3=nothing; first=true, kw...)  = grdimage("", arg1, arg2, arg3; first=first, kw...)
grdimage!(arg1, arg2=nothing, arg3=nothing; first=false, kw...) = grdimage("", arg1, arg2, arg3; first=first, kw...)