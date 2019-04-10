"""
	grd2kml(cmd0::String="", arg1=nothing, kwargs...)

Reads a 2-D grid file and makes a quadtree of PNG images and KML wrappers for Google Earth
using the selected tile size [256x256 pixels].

Full option list at [`grd2kml`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html)

Parameters
----------

- $(GMT.opt_C)
- **E** : **url** : -- Str --		Flags = `url``

    Instead of hosting the files locally, prepend a site URL. The top-level prefix.kml file
    will then use this URL to find the other files it references.``
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#e)
- **F** : **filter** : -- Str --

    Specifies the filter to use for the downsampling of the grid for more distant viewing.
    Choose among boxcar, cosine arch, gaussian, or median [Gaussian].
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#f)
- **H** : **sub_pixel** : -- Int --         Flags = ``factor`

    Improve the quality of rasterization by passing the sub-pixel smoothing factor to psconvert.
    [`-H`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#h)
- **I** : **shade** : **intensity** : **intensfile** : -- Str or GMTgrid --

    Gives the name of a grid file or GMTgrid with intensities in the (-1,+1) range,
    or a grdgradient shading flags.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#i)
- **L** : **tile_size** : -- Number --			Flags = `tilesize`

    Sets the fixed size of the image building blocks. Must be an integer that is radix 2.
    Typical values are 256 or 512 [256].
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#l)
- **N** : **prefix** -- Str --		            Flags = `prefix`

    Sets a unique name prefixed used for the top-level KML filename and the directory where all
    referenced KML files and PNG images will be written [GMT_Quadtree].
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#n)
- **Q** : **nan_t** : **nan_alpha** : -- Bool or [] --

    Make grid nodes with z = NaN transparent, using the color-masking feature in PostScript Level 3.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#q)
- **T** : **title** : -- Str --			        Flags = `title`

    Sets the title of the top-level document (i.e., its description).
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#t)
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_f)
"""
function grd2kml(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("grd2kml", cmd0, arg1, arg2)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :f])
    cmd = parse_these_opts(cmd, d, [[:E :url], [:F :filter], [:H :sub_pixel], [:L :tile_size],
                                    [:N :prefix], [:Q :nan_t :nan_alpha], [:T :title]])

	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', 0, arg1, arg2)

	if ((val = find_in_dict(d, [:I :shade :intensity :intensfile])[1]) !== nothing)
		if (!isa(val, GMTgrid))		# Uff, simple. Either a file name or a -A type modifier
			cmd *= " -I" * arg2str(val)
		else
			cmd,N_shade = put_in_slot(cmd, val, 'I', [arg1, arg2])
			if (N_shade == 1)     arg1 = val
			elseif (N_shade == 2) arg2 = val
			end
		end
	end

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	if (isa(arg1, Array{<:Number}))		arg1 = mat2grid(arg1)	end
	return common_grd(d, "grd2kml " * cmd, got_fname, 1, arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grd2kml(arg1, arg2=nothing, cmd0::String=""; kw...) = grd2kml(cmd0, arg1, arg2; kw...)