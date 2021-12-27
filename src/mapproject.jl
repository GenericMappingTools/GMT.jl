"""
	mapproject(cmd0::String="", arg1=nothing, kwargs...)

Forward and inverse map transformations, datum conversions and geodesy.

Full option list at [`mapproject`]($(GMTdoc)mapproject.html)

Parameters
----------

- $(GMT.opt_R)
- $(GMT.opt_J)

- **A** | **origin** :: [Type => Str]    ``Arg = b|B|f|F|o|O[lon0/lat0][+v]``

    Calculate azimuth along track or to the optional fixed point set with lon0/lat0.
    ($(GMTdoc)mapproject.html#a)
- **C** | **center** :: [Type => Str | List | []]     ``Arg = [dx/dy]``

    Set center of projected coordinates to be at map projection center [Default is lower left corner].
    ($(GMTdoc)mapproject.html#c)
- **D** | **override_units** :: [Type => Str]    ``Arg = c|i|p``

    Temporarily override PROJ_LENGTH_UNIT and use c (cm), i (inch), or p (points) instead.
    ($(GMTdoc)mapproject.html#d)
- **E** | **geod2ecef** | **ecef** :: [Type => Str | []]    ``Arg = [datum]``

    Convert from geodetic (lon, lat, height) to Earth Centered Earth Fixed (ECEF) (x,y,z) coordinates.
    ($(GMTdoc)mapproject.html#e)
- **F** | **one2one** :: [Type => Str | []]    ``Arg = [unit]``

    Force 1:1 scaling, i.e., output (or input, see I) data are in actual projected meters.
    ($(GMTdoc)mapproject.html#f)
- **G** | **track_distances** :: [Type => Str | List]    ``Arg = [lon0/lat0][+a][+i][+u[+|-]unit][+v]``

    Calculate distances along track or to the optional fixed point set with G="lon0/lat0".
    ($(GMTdoc)mapproject.html#g)
- **I** | **inverse** :: [Type => Bool]

    Do the Inverse transformation, i.e., get (longitude,latitude) from (x,y) data.
    ($(GMTdoc)mapproject.html#i)
- **L** | **dist2line** :: [Type => Str | NamedTuple]   ``Arg = line.xy[+u[+|-]unit][+p] | (line=Matrix, unit=x, fractional_pt=_,cartesian=true, projected=true)``

    Determine the shortest distance from the input data points to the line(s) given in the
    ASCII multisegment file line.xy.
    ($(GMTdoc)mapproject.html#l)
- **N** | **geod2aux** :: [Type => Str | []]       ``Arg = [a|c|g|m]``

    Convert from geodetic latitudes to one of four different auxiliary latitudes (longitudes are unaffected).
    ($(GMTdoc)mapproject.html#n)
- **Q** | **list** :: [Type => Str | []]           ``Arg = [d|e]``

    List all projection parameters. To only list datums, use Q=:d, to only list ellipsoids, use Q=:e.
    ($(GMTdoc)mapproject.html#q)
- **S** | **supress** :: [Type => Bool]

    Suppress points that fall outside the region.
    ($(GMTdoc)mapproject.html#s)
- **T** | **change_datum** :: [Type => Str]    ``Arg = [h]from[/to]``

    Coordinate conversions between datums from and to using the standard Molodensky transformation.
    ($(GMTdoc)mapproject.html#t)
- **W** | **map_size** :: [Type => Str | []]    ``Arg = [w|h]``

    Prints map width and height on standard output. No input files are read.
    ($(GMTdoc)mapproject.html#w)
- **Z** | **travel_times** :: [Type => Str | Number]    ``Arg = [speed][+a][+i][+f][+tepoch]``

    Calculate travel times along track as specified with -G.
    ($(GMTdoc)mapproject.html#z)

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
function mapproject(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("mapproject", cmd0, arg1, arg2)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:R :V_params :b :d :e :f :g :h :i :j :o :p :s :yx])
	cmd  = parse_these_opts(cmd, d, [[:C :center], [:E :geod2ecef :ecef], [:I :inverse], [:S :supress], #[:L :dist2line],
	                                 [:T :change_datum], [:W :map_size], [:Z :travel_times]])
	cmd  = add_opt_1char(cmd, d, [[:D :override_units], [:F :one2one], [:Q :list], [:N :geod2aux]])

	cmd = add_opt(d, cmd, "A", [:A :azim],
	              (fixed_pt=("", arg2str), back=("b", nothing, 1), back_geocentric=("B", nothing, 1), forward=("f", nothing, 1), forward_geocentric=("F", nothing, 1), orientation=("o", nothing, 1), orientation_geocentric=("O", nothing, 1), unit="+u1", var_pt="_+v"))
	cmd = add_opt(d, cmd, "G", [:G :track_distances],
	              (fixed_pt=("", arg2str, 1), accumulated="_+a", incremental="_+i", unit="+u1", var_pt="_+v"))

    cmd, args, n, = add_opt(d, cmd, "L", [:L :dist2line], :line, Array{Any,1}([arg1, arg2]),
                            (unit="+u1", cartesian="_+uc", project="_+uC", fractional_pt="_+p"))
	if (n > 0)
		arg1, arg2 = args[:]
	end

	if (!occursin("-G", cmd))
		map = occursin(" -W", cmd) ? true : false
		cmd, = parse_J(d, cmd, " ", map)		# Do not append a default fig size
	end

	if (occursin(" -W", cmd))				# No input data in this case
		(dbg_print_cmd(d, cmd) !== nothing) && return cmd
		gmt("mapproject " * cmd)
	else
	    #cmd, got_fname, arg1, arg2 = find_data(d, cmd0, cmd, arg1, arg2)
		R = common_grd(d, cmd0, cmd, "mapproject ", arg1, arg2)
        (isa(R, Vector{GMTdataset}) && contains(cmd, " -I")) && (R[1].proj4 = prj4WGS84)
        R
	end
end

# ---------------------------------------------------------------------------------------------------
mapproject(arg1, arg2=nothing, cmd0::String=""; kw...) = mapproject(cmd0, arg1, arg2; kw...)

#mapproject(, G=(fixed_pt=[1 2], unit=:n,accumulated=1,incremental=1), azim=(fixed_pt=(3,4),forward=1), Vd=2) = "mapproject  -Af3/4 -G1/2+un+a+i"