"""
	sphtriangulate(cmd0::String="", arg1=nothing, kwargs...)

Delaunay or Voronoi construction of spherical lon,lat data

Parameters
----------

- **A** | **area** :: [Type => Bool]

    Compute the area of the spherical triangles (Qd) or polygons (Qv) and write the areas in the output segment headers
- **C** | **save_mem** :: [Type => Bool]

    For large data sets you can save some memory (at the expense of more processing).
- **D** | **skipdup** :: [Type => Bool]

    Delete any duplicate points [Default assumes there are no duplicates].
- **L** | **unit** :: [Type => Str]          ``Arg = e|f|k|m|n|u|d``

    Specify the unit used for distance and area calculations.
- **N** | **nodes** :: [Type => Str]         ``Arg = `file``

    Write the information pertaining to each polygon to a separate file.
- **Q** | **voronoi** :: [Type => Str]     ``Arg = d|v``

    Append d for Delaunay triangles or v for Voronoi polygons [Delaunay].
- **T** | **arcs** :: [Type => Bool | Str]

    Write the unique arcs of the construction [Default writes fillable triangles or polygons].
    When used with -A we store arc length in the segment header in chosen unit.
- $(opt_V)
- $(opt_b)
- $(opt_d)
- $(opt_e)
- $(_opt_h)
- $(_opt_i)
- $(opt_swap_xy)

To see the full documentation type: ``@? sphtriangulate``
"""
function sphtriangulate(cmd0::String="", arg1=nothing; kw...)
	d = init_module(false, kw...)[1]		# Also checks if the user wants ONLY the HELP mode
	sphtriangulate(cmd0, arg1, d)
end
function sphtriangulate(cmd0::String, arg1, d::Dict{Symbol, Any})
	cmd, = parse_common_opts(d, "", [:V_params :b :d :e :h :i :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :area], [:C :save_mem], [:D :skipdup :duplicates :skip], [:L :unit], [:N :nodes], [:Q :voronoi], [:T :arcs]])
	common_grd(d, cmd0, cmd, "sphtriangulate ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
sphtriangulate(arg1; kw...) = sphtriangulate("", arg1; kw...)