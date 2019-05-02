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
function grd2kml(cmd0::String="", arg1=nothing; kwargs...)

    arg2 = nothing;     arg3 = nothing;     # for CPT and/or illum
	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("grd2kml", cmd0, arg1, arg2)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :f])
	cmd = parse_these_opts(cmd, d, [[:E :url], [:F :filter], [:H :sub_pixel], [:L :tile_size],
	                                [:N :prefix], [:Q :nan_t :nan_alpha], [:T :title]])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)		# Find how data was transmitted
	cmd, N_used, arg1, arg2, = get_cpt_set_R(d, cmd0, cmd, opt_R, got_fname, arg1, arg2)
    cmd, arg1, arg2, arg3 = common_shade(d, cmd, arg1, arg2, arg3, nothing, "grd2kml")
	common_grd(d, "grd2kml " * cmd, arg1, arg2, arg3)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grd2kml(arg1, cmd0::String=""; kw...) = grd2kml(cmd0, arg1; kw...)