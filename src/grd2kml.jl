"""
	grd2kml(cmd0::String="", arg1=[], kwargs...)

Reads a 2-D grid file and makes a quadtree of PNG images and KML wrappers for Google Earth
using the selected tile size [256x256 pixels].

Full option list at [`grd2kml`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html)

Parameters
----------

- $(GMT.opt_C)
- **E** : **url** : -- Str --		Flags = ``url``

    Instead of hosting the files locally, prepend a site URL. The top-level prefix.kml file
    will then use this URL to find the other files it references.``
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#e)
- **F** : **filter** : -- Str --

    Specifies the filter to use for the downsampling of the grid for more distant viewing.
    Choose among boxcar, cosine arch, gaussian, or median [Gaussian].
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#f)
- **H** : **sub_pixel** : -- Int --         Flags = ``factor``

    Improve the quality of rasterization by passing the sub-pixel smoothing factor to psconvert.
    [`-H`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#h)
- **I** : **shade** : **intensity** : **intensfile** : -- Str or GMTgrid --

    Gives the name of a grid file or GMTgrid with intensities in the (-1,+1) range,
    or a grdgradient shading flags.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#i)
- **L** : **tile_size** : -- Number --			Flags = tilesize

    Sets the fixed size of the image building blocks. Must be an integer that is radix 2.
    Typical values are 256 or 512 [256].
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#l)
- **N** : **prefix** -- Str --		            Flags = ``prefix``

    Sets a unique name prefixed used for the top-level KML filename and the directory where all
    referenced KML files and PNG images will be written [GMT_Quadtree].
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#n)
- **Q** : **nan_t** : **nan_alpha** : -- Bool or [] --

    Make grid nodes with z = NaN transparent, using the color-masking feature in PostScript Level 3.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#q)
- **T** : **title** : -- Str --			        Flags = ``title``

    Sets the title of the top-level document (i.e., its description).
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grd2kml.html#t)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grd2kml(cmd0::String="", arg1=[], arg2=[]; kwargs...)

	length(kwargs) == 0 && (findfirst(" -", cmd0) != nothing) && return monolitic("grd2kml", cmd0, arg1)	# Speedy mode

	if (isempty(cmd0) && isempty_(arg1))
		error("Must provide the grid to work with.")
	end

	d = KW(kwargs)

	cmd = parse_V("", d)
	cmd = parse_f(cmd, d)
    cmd = parse_params(cmd, d)

	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', 0, arg1, arg2)

	for sym in [:I :shade :intensity :intensfile]
		if (haskey(d, sym))
			if (!isa(d[sym], GMTgrid))		# Uff, simple. Either a file name or a -A type modifier
				cmd = cmd * " -I" * arg2str(d[sym])
			else
				cmd,N_shade = put_in_slot(cmd, d[sym], 'I', [arg1, arg2])
				if (N_shade == 1)     arg1 = d[sym]
				elseif (N_shade == 2) arg2 = d[sym]
				end
			end
			break
		end
    end

	cmd = add_opt(cmd, 'E', d, [:E :url])
	cmd = add_opt(cmd, 'F', d, [:F :filter])
	cmd = add_opt(cmd, 'H', d, [:H :sub_pixel])
	cmd = add_opt(cmd, 'L', d, [:L :tile_size])
	cmd = add_opt(cmd, 'N', d, [:N :prefix])
	cmd = add_opt(cmd, 'Q', d, [:Q :nan_t :nan_alpha])
	cmd = add_opt(cmd, 'T', d, [:T :title])

	return common_grd(d, cmd0, cmd, arg1, [], true, "grd2kml")	# Shared by several grdxxx modules
end

# ---------------------------------------------------------------------------------------------------
grd2kml(arg1=[], arg2=[], cmd0::String=""; kw...) = grd2kml(cmd0, arg1, arg2; kw...)