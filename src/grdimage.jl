"""
    grdimage(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; kwargs...)

Produces a gray-shaded (or colored) map by plotting rectangles centered on each grid node and assigning them a gray-shade (or color) based on the z-value.

Full option list at [`grdimage`](http://gmt.soest.hawaii.edu/doc/latest/grdimage.html)

Parameters
----------

- **A** : **img_out** : **image_out** : -- Str --

    Save an image in a raster format instead of PostScript.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/grdimage.html#a)
- $(GMT.opt_J)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **D** : **img_in** : **image_in** : -- Str or [] --

    Specifies that the grid supplied is an image file to be read via GDAL.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdimage.html#d)
- **E** : **dpi** : -- Int or [] --  

    Sets the resolution of the projected grid that will be created.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/grdimage.html#e)
- **G** : -- Str or Int --

    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdimage.html#g)
- **I** : **shade** : **intensity** : -- Str or GMTgrid --

    Gives the name of a grid file or GMTgrid with intensities in the (-1,+1) range,
    or a grdgradient shading flags.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grdimage.html#i)
- **M** : **monochrome** : -- Bool or [] --

    Force conversion to monochrome image using the (television) YIQ transformation.
    [`-M`](http://gmt.soest.hawaii.edu/doc/latest/grdimage.html#m)
- **N** : **noclip** : -- Bool or [] --

    Do not clip the image at the map boundary.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdimage.html#n)
- $(GMT.opt_P)
- **Q** : **nan_t** : **nan_alpha** : -- Bool or [] --

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
	output, opt_T, fname_ext, K, O = fname_out(d, first)		# OUTPUT may have been an extension only

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd = parse_common_opts(d, cmd, [:UVXY :params :c :f :n :p :t], first)
	cmd = parse_these_opts(cmd, d, [[:A :img_out :image_out], [:D :img_in :image_in], [:E :dpi], [:G],
				[:M :monochrome], [:N :noclip], [:Q :nan_t :nan_alpha], ["," :mem :mem_layout]])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)		# Find how data was transmitted
	if (got_fname == 0 && isa(arg1, Tuple))			# Then it must be using the three r,g,b grids
		cmd, got_fname, arg1, arg2, arg3 = find_data(d, cmd0, cmd, arg1, arg2, arg3)
	end

	if (isa(arg1, Array{<:Number}))
		arg1 = mat2grid(arg1)
		if (isa(arg2, Array{<:Number}))  arg2 = mat2grid(arg2)  end
		if (isa(arg3, Array{<:Number}))  arg3 = mat2grid(arg3)  end
	end

	cmd, N_used, arg1, arg2, arg3 = get_cpt_set_R(d, cmd0, cmd, opt_R, got_fname, arg1, arg2, arg3, "grdimage")
	cmd, arg1, arg2, arg3, arg4 = common_shade(d, cmd, arg1, arg2, arg3, arg4, "grdimage")

	if (isa(arg1, GMTimage) && !occursin("-D", cmd))  cmd *= " -D"  end	# GMT bug. It says not need but it is.
	cmd = "grdimage " * cmd				# In any case we need this
	if (!occursin("-A", cmd))			# -A means that we are requesting the image directly
		cmd, K = finish_PS_nested(d, cmd, output, K, O, [:coast :colorbar :basemap])
	end
	return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, O, false, arg1, arg2, arg3, arg4)
end

# ---------------------------------------------------------------------------------------------------
function common_shade(d, cmd, arg1, arg2, arg3, arg4, prog)
	# Used both by grdimage and grdview
	if ((val = find_in_dict(d, [:I :shade :intensity])[1]) !== nothing)
		if (!isa(val, GMTgrid))			# Uff, simple. Either a file name or a -A type modifier
			if (isa(val, String) || isa(val, Symbol))
				val = arg2str(val)
				val == "default" ? cmd *= " -I+a-45+nt1" : cmd *= " -I" * val
			else
				cmd = add_opt(cmd, 'I', d, [:I :shade :intensity],
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
	end
	return cmd, arg1, arg2, arg3, arg4
end

# ---------------------------------------------------------------------------------------------------
grdimage!(cmd0::String="", arg1=nothing, arg2=nothing, arg3=nothing; first=false, kw...) =
	grdimage(cmd0, arg1, arg2, arg3; first=false, kw...) 

grdimage(arg1,  arg2=nothing, arg3=nothing; first=true, kw...)  = grdimage("", arg1, arg2, arg3; first=first, kw...)
grdimage!(arg1, arg2=nothing, arg3=nothing; first=false, kw...) = grdimage("", arg1, arg2, arg3; first=first, kw...)