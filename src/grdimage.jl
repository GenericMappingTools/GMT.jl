"""
    grdimage(cmd0::String="", arg1=[], arg2=[], arg3=[]; fmt="", kwargs...)

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
- **I** : **shade** : **intensity** : **intensfile** : -- Str or GMTgrid --
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
# ---------------------------------------------------------------------------------------------------
function grdimage(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[]; data=[], fmt::String="", 
                  K=false, O=false, first=true, kwargs...)

	length(kwargs) == 0 && isempty(data) && return monolitic("grdimage", cmd0, arg1)	# Speedy mode

	if (!isempty_(data) && isa(data, Tuple) && !isa(data[1], GMTgrid))
		error("When 'data' is a tuple, it MUST contain a GMTgrid data type")
	end

	output, opt_T, fname_ext = fname_out(fmt)		# OUTPUT may have been an extension only

	d = KW(kwargs)
	cmd = ""
    cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd0, cmd, "", O, " -JX12c/0")
	cmd = parse_UVXY(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_n(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	cmd = add_opt_s(cmd, 'A', d, [:A :img_out :image_out])
	cmd = add_opt(cmd, 'D', d, [:D :img_in :image_in])
	cmd = add_opt(cmd, 'E', d, [:E :dpi])
	cmd = add_opt(cmd, 'G', d, [:G])
	cmd = add_opt(cmd, 'M', d, [:M :monochrome])
	cmd = add_opt(cmd, 'N', d, [:N :noclip])
	cmd = add_opt(cmd, 'Q', d, [:Q :nan_t :nan_alpha])

	# In case DATA holds a grid file name, copy it into cmd. If Grids put them in ARGs
	cmd, arg1, arg2, arg3 = read_data(data, cmd, arg1, arg2, arg3)

	for sym in [:C :color :cmap]
		if (haskey(d, sym))
			if (!isa(d[sym], GMTcpt))		# Uff, simple. Either a file name or a -A type modifier
				cmd = cmd * " -C" * arg2str(d[sym])
			else
				cmd, N_cpt = put_in_slot(cmd, d[sym], 'C', [arg1, arg2, arg3, arg4])
				if (N_cpt == 1)     arg1 = d[sym]
				elseif (N_cpt == 2) arg2 = d[sym]
				elseif (N_cpt == 3) arg3 = d[sym]
				elseif (N_cpt == 4) arg4 = d[sym]
				end
			end
			break
		end
	end

	for sym in [:I :shade :intensity :intensfile]
		if (haskey(d, sym))
			if (!isa(d[sym], GMTgrid))		# Uff, simple. Either a file name or a -A type modifier
				cmd = cmd * " -I" * arg2str(d[sym])
			else
				cmd,N_shade = put_in_slot(cmd, d[sym], 'I', [arg1, arg2, arg3])
				if (N_shade == 1)     arg1 = d[sym]
				elseif (N_shade == 2) arg2 = d[sym]
				elseif (N_shade == 3) arg3 = d[sym]
				end
			end
			break
		end
	end

	cmd = finish_PS(d, cmd0, cmd, output, K, O)
    return finish_PS_module(d, cmd, "", arg1, arg2, arg3, arg4, [], [], output, fname_ext, opt_T, K, "grdimage")
end

# ---------------------------------------------------------------------------------------------------
grdimage!(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[]; data=[],
          fmt::String="", K=true, O=true, first=false, kw...) =
	grdimage(cmd0, arg1, arg2, arg3, arg4; data=data, fmt=fmt, K=true, O=true, first=false, kw...) 

grdimage(arg1::GMTgrid, cmd0::String="", arg2=[], arg3=[], arg4=[]; data=[], fmt::String="", 
         K=false, O=false, first=true, kw...) =
	grdimage(cmd0, arg1, arg2, arg3, arg4; data=data, fmt=fmt, K=K, O=O, first=first, kw...)

grdimage!(arg1::GMTgrid, cmd0::String="", arg2=[], arg3=[], arg4=[]; data=[], fmt::String="", 
          K=true, O=true, first=false, kw...) =
	grdimage(cmd0, arg1, arg2, arg3, arg4; data=data, fmt=fmt, K=true, O=true, first=false, kw...)