"""
	sphtriangulate(cmd0::String="", arg1=nothing, kwargs...)

Delaunay or Voronoi construction of spherical lon,lat data

Full option list at [`sphtriangulate`](http://gmt.soest.hawaii.edu/doc/latest/sphtriangulate .html)

Parameters
----------

- **A** : **area** : -- Bool or [] --

    Compute the area of the spherical triangles (Qd) or polygons (Qv) and write the areas in the output segment headers
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/sphtriangulate.html#a)
- **C** : **save_mem** : -- Bool or [] --

    For large data sets you can save some memory (at the expense of more processing).
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/sphdistance.html#c)
- **D** : **skip** : -- Bool or [] --

    Skip the last (repeated) input vertex at the end of a closed segment if it equals the first point in the segment.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/sphtriangulate.html#d)
- **L** : **unit** : -- Str --          Flags = e|f|k|m|n|u|d

    Specify the unit used for distance and area calculations.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/sphtriangulate.html#l)
- **N** : **nodes** : -- Str --         Flags = ``nfile``

    Write the information pertaining to each polygon to a separate file.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/sphtriangulate.html#n)
- **Q** : **voronoi** : -- Str --     Flags = d|v

    Append d for Delaunay triangles or v for Voronoi polygons [Delaunay].
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/sphtriangulate .html#q)
- **T** : -- Bool or Str --

    Write the unique arcs of the construction [Default writes fillable triangles or polygons].
    When used with -A we store arc length in the segment header in chosen unit.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/sphtriangulate.html#t)
- $(GMT.opt_V)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_swap_xy)
"""
function sphtriangulate(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("sphtriangulate ", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :b :d :e :h :i :yx])
	cmd = parse_these_opts(cmd, d, [[:A :area], [:C :save_mem], [:D :skip], [:L :unit], [:N :nodes], [:Q :voronoi], [:T]])

	common_grd(d, cmd0, cmd, "sphtriangulate ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
sphtriangulate(arg1, cmd0::String=""; kw...) = sphtriangulate(cmd0, arg1; kw...)