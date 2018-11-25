"""
    grdimage(cmd0::String="", arg1=[], arg2=[], arg3=[]; kwargs...)

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
function grdimage(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[]; K=false, O=false, first=true, kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("grdimage", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	cmd, opt_B, = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd = parse_common_opts(d, cmd, [:UVXY :params :f :n :p :t])

	cmd, K, O, = set_KO(cmd, opt_B, first, K, O)			# Set the K O dance

	cmd = add_opt(cmd, 'A', d, [:A :img_out :image_out])
	cmd = add_opt(cmd, 'D', d, [:D :img_in :image_in])
	cmd = add_opt(cmd, 'E', d, [:E :dpi])
	cmd = add_opt(cmd, 'G', d, [:G])
	cmd = add_opt(cmd, 'M', d, [:M :monochrome])
	cmd = add_opt(cmd, 'N', d, [:N :noclip])
	cmd = add_opt(cmd, 'Q', d, [:Q :nan_t :nan_alpha])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)		# Find how data was transmitted
	if (got_fname == 0 && isempty_(arg1))			# Than it must be using the three r,g,b grids
		cmd, got_fname, arg1, arg2, arg3 = find_data(d, cmd0, cmd, 3, arg1, arg2, arg3)
		if (got_fname == 0 && isempty_(arg1))
			error("No input data to use in grdimage.")
		end
	end

	if (isa(arg1, Array{<:Number}))
		arg1 = mat2grid(arg1)
		if (!isempty_(arg2) && isa(arg2, Array{<:Number}))  arg2 = mat2grid(arg2)  end
		if (!isempty_(arg3) && isa(arg3, Array{<:Number}))  arg3 = mat2grid(arg3)  end
	end

	N_used = got_fname == 0 ? 1 : 0		# To know whether a cpt will go to arg1 or arg2
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_used, arg1, arg2)
	if (!isempty_(arg3) && occursin("-C", cmd))		# This lieves out the case when the r,g,b were sent as a text.
		error("Cannot use the three R,G,B grids and a color table.")
	end

	for sym in [:I :shade :intensity :intensfile]
		if (haskey(d, sym))
			if (!isa(d[sym], GMTgrid))		# Uff, simple. Either a file name or a -A type modifier
				cmd = cmd * " -I" * arg2str(d[sym])
			else
				cmd, N = put_in_slot(cmd, d[sym], 'I', [arg1, arg2, arg3, arg4])
				if (N == 1)     arg1 = d[sym]
				elseif (N == 2) arg2 = d[sym]
				elseif (N == 3) arg3 = d[sym]
				elseif (N == 4) arg4 = d[sym]
				end
			end
			break
		end
	end

	cmd = finish_PS(d, cmd, output, K, O)
    return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, "grdimage", arg1, arg2, arg3, arg4)
end

# ---------------------------------------------------------------------------------------------------
grdimage!(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[]; K=true, O=true, first=false, kw...) =
	grdimage(cmd0, arg1, arg2, arg3, arg4; K=true, O=true, first=false, kw...) 

grdimage(arg1, cmd0::String="", arg2=[], arg3=[], arg4=[]; K=false, O=false, first=true, kw...) =
	grdimage(cmd0, arg1, arg2, arg3, arg4; K=K, O=O, first=first, kw...)

grdimage!(arg1, cmd0::String="", arg2=[], arg3=[], arg4=[]; K=true, O=true, first=false, kw...) =
	grdimage(cmd0, arg1, arg2, arg3, arg4; K=K, O=O, first=first, kw...)