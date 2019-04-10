"""
	gmtselect(cmd0::String="", arg1=nothing, kwargs...)

Select data table subsets based on multiple spatial criteria.

Full option list at [`gmtselect`](http://gmt.soest.hawaii.edu/doc/latest/gmtselect.html)

Parameters
----------

- $(GMT.opt_R)
- **A** : **area** : -- Str or Number --

    Features with an area smaller than min_area in km^2 or of hierarchical level that is
    lower than min_level or higher than max_level will not be plotted.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/gmtselect.html#a)
- **C** : **point_file** : -- Str --   Flags = pointfile+ddist[unit]

    Pass all records whose location is within dist of any of the points in the ASCII file pointfile.
    If dist is zero then the 3rd column of pointfile must have each point’s individual radius of influence.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/gmtselect.html#c)
- **D** : **res** : **resolution** : -- Str --      Flags = c|l|i|h|f

    Ignored unless N is set. Selects the resolution of the coastline data set to use
    ((f)ull, (h)igh, (i)ntermediate, (l)ow, or (c)rude).
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/gmtselect.html#d)
- **E** : **boundary** : -- Str or [] --            Flags = [fn]

    Specify how points exactly on a polygon boundary should be considered.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/gmtselect.html#e)
- **F** : **polygon** : -- Str or GMTdaset oe Mx2 array --   Flags = polygonfile

    Pass all records whose location is within one of the closed polygons in the multiple-segment
    file ``polygonfile`` or a GMTdataset type or a Mx2 array defining the polygon.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/gmtselect.html#f)
- **G** : **gridmask** : -- Str or GRDgrid type --      Flags = gridmask

    Pass all locations that are inside the valid data area of the grid gridmask.
    Nodes that are outside are either NaN or zero.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/gmtselect.html#g)
- **I** : **reverse** : -- Str or [] --    Flags = [cflrsz]

    Reverses the sense of the test for each of the criteria specified.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/gmtselect.html#i)
- $(GMT.opt_J)
- **L** : **dist2line** : -- Str --    Flags = linefile+ddist[unit][+p]

    Pass all records whose location is within dist of any of the line segments in the ASCII
    multiple-segment file linefile.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/gmtselect.html#l)
- **N** : **mask_geog** : -- List or Str --     Flags = ocean/land/lake/island/pond or wet/dry

    Pass all records whose location is inside specified geographical features.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/gmtselect.html#n)
- **Z** : **in_range** : -- List or Str --     Flags = min[/max][+a][+ccol][+i]

    Pass all records whose 3rd column (z; col = 2) lies within the given range or is NaN.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/gmtselect.html#z)
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_o)
- $(GMT.opt_swap_xy)
"""
function gmtselect(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("gmtselect", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :b :d :e :f :g :h :i :o :yx])
    cmd = parse_these_opts(cmd, d, [[:A :area], [:C :point_file], [:D :res :resolution], [:E :boundary],
                [:F :polygon], [:G :gridmask], [:I :reverse], [:L :dist2line], [:N :mask_geog], [:Z :in_range]])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, "gmtselect " * cmd, got_fname, 1, arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtselect(arg1, cmd0::String=""; kw...) = gmtselect(cmd0, arg1; kw...)