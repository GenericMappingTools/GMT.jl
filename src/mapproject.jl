"""
	mapproject(cmd0::String="", arg1=nothing, kwargs...)

Forward and inverse map transformations, datum conversions and geodesy.

Full option list at [`mapproject`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html)

Parameters
----------

- $(GMT.opt_R)
- $(GMT.opt_J)

- **A** : **origin** : -- Str --    Flags = b|B|f|F|o|O[lon0/lat0][+v]

    Calculate azimuth along track or to the optional fixed point set with lon0/lat0.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html#a)
- **C** : **center** : -- Str or list or [] --    Flags = [dx/dy]

    Set center of projected coordinates to be at map projection center [Default is lower left corner].
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html#c)
- **D** : **override_units** : -- Str --    Flags = c|i|p

    Temporarily override PROJ_LENGTH_UNIT and use c (cm), i (inch), or p (points) instead.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html#d)
- **E** : **geod2ecef** : -- Str or [] --    Flags = [datum]

    Convert from geodetic (lon, lat, height) to Earth Centered Earth Fixed (ECEF) (x,y,z) coordinates.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html#e)
- **F** : **one2one** : -- Str or [] --    Flags = [unit]

    Force 1:1 scaling, i.e., output (or input, see I) data are in actual projected meters.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html#f)
- **G** : **track_distances** : -- Str or List --    Flags = [lon0/lat0][+a][+i][+u[+|-]unit][+v]

    Calculate distances along track or to the optional fixed point set with G="lon0/lat0".
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html#g)
- **L** : **dist2line** : -- Str --    Flags = line.xy[+u[+|-]unit][+p]

    Determine the shortest distance from the input data points to the line(s) given in the
    ASCII multisegment file line.xy.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html#l)
- **N** : **geod2aux** : -- Str or [] --       Flags = [a|c|g|m]

    Convert from geodetic latitudes to one of four different auxiliary latitudes (longitudes are unaffected).
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html#n)
- **Q** : **list** : -- Str or [] --           Flags = [d|e]

    List all projection parameters. To only list datums, use Q=:d, to only list ellipsoids, use Q=:e.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html#q)
- **S** : **supress** : -- Bool or [] --

    Suppress points that fall outside the region.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html#s)
- **T** : **change_datum** : -- Str --    Flags = [h]from[/to]

    Coordinate conversions between datums from and to using the standard Molodensky transformation.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html#t)
- **W** : **map_size** : -- Str or [] --    Flags = [w|h]

    Prints map width and height on standard output. No input files are read.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html#w)
- **Z** : **travel_times** : -- Str or Number --    Flags = [speed][+a][+i][+f][+tepoch]

    Calculate travel times along track as specified with -G.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/mapproject.html#z)

- $(GMT.opt_V)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_o)
- $(GMT.opt_p)
- $(GMT.opt_s)
- $(GMT.opt_swap_xy)
"""
function mapproject(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("mapproject", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :b :d :e :f :g :h :i :o :p :s :yx])
	cmd = parse_these_opts(cmd, d, [[:A :azim], [:C :center], [:D :override_units], [:E :geod2ecef],
				[:F :one2one], [:G :track_distances], [:I :inverse], [:L :dist2line], [:N :geod2aux],
	            [:Q :list], [:S :supress], [:T :change_datum], [:W :map_size], [:Z :travel_times]])
	if (!occursin("-G", cmd))
		map = occursin(" -W", cmd) ? true : false
		cmd, = parse_J(cmd, d, "", map)		# Do not append a default fig size
	end

	if (occursin(" -W", cmd))				# No input data in this case
		if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end	
		gmt("mapproject " * cmd)
	else
		common_grd(d, cmd0, cmd, "mapproject ", arg1)
	end
end

# ---------------------------------------------------------------------------------------------------
mapproject(arg1, cmd0::String=""; kw...) = mapproject(cmd0, arg1; kw...)