"""
	sphtriangulate(cmd0::String="", arg1=nothing, kwargs...)

Delaunay or Voronoi construction of spherical lon,lat data

Full option list at [`sphtriangulate`]($(GMTdoc)sphtriangulate .html)

Parameters
----------

- **A** | **area** :: [Type => Bool]

    Compute the area of the spherical triangles (Qd) or polygons (Qv) and write the areas in the output segment headers
    ($(GMTdoc)sphtriangulate.html#a)
- **C** | **save_mem** :: [Type => Bool]

    For large data sets you can save some memory (at the expense of more processing).
    ($(GMTdoc)sphtriangulate.html#c)
- **D** | **duplicates** | **skip** :: [Type => Bool]

    Delete any duplicate points [Default assumes there are no duplicates].
    ($(GMTdoc)sphtriangulate.html#d)
- **L** | **unit** :: [Type => Str]          ``Arg = e|f|k|m|n|u|d``

    Specify the unit used for distance and area calculations.
    ($(GMTdoc)sphtriangulate.html#l)
- **N** | **nodes** :: [Type => Str]         ``Arg = `file``

    Write the information pertaining to each polygon to a separate file.
    ($(GMTdoc)sphtriangulate.html#n)
- **Q** | **voronoi** :: [Type => Str]     ``Arg = d|v``

    Append d for Delaunay triangles or v for Voronoi polygons [Delaunay].
    ($(GMTdoc)sphtriangulate.html#q)
- **T** :: [Type => Bool | Str]

    Write the unique arcs of the construction [Default writes fillable triangles or polygons].
    When used with -A we store arc length in the segment header in chosen unit.
    ($(GMTdoc)sphtriangulate.html#t)
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

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:V_params :b :d :e :h :i :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :area], [:C :save_mem], [:D :duplicates :skip], [:L :unit], [:N :nodes], [:Q :voronoi], [:T]])
	common_grd(d, cmd0, cmd, "sphtriangulate ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
sphtriangulate(arg1, cmd0::String=""; kw...) = sphtriangulate(cmd0, arg1; kw...)