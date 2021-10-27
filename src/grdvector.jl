"""
	grdvector(cmd0::String="", arg1=nothing, arg2=nothing, kwargs...)

Takes two 2-D grid files which represents the x- and y-components of a vector field and produces
a vector field plot by drawing vectors with orientation and length according to the information
in the files. Alternatively, polar coordinate r, theta grids may be given instead.

Full option list at [`grdvector`]($(GMTdoc)grdvector.html)

Parameters
----------

- **A** | **polar** :: [Type => Bool]  

    The grid contain polar (r, theta) components instead of Cartesian (x, y) [Default is Cartesian components].
    ($(GMTdoc)grdvector.html#a)
- $(GMT.opt_B)
- $(GMT.opt_C)
- **G** | **fill** :: [Type => Str | Number]

    Sets color or shade for vector interiors [Default is no fill].
    ($(GMTdoc)grdvector.html#g)
- **I** | **inc** :: [Type => Sytr | Number]	``Arg=[x]dx[/dy]``

    Only plot vectors at nodes every x_inc, y_inc apart (must be multiples of original grid spacing).
    ($(GMTdoc)grdvector.html#i)
- **N** | **noclip** | **no_clip** :: [Type => Bool]

    Do NOT clip symbols that fall outside map border 
    ($(GMTdoc)grdvector.html#n)
- **Q** | **vec** | **vector** | **arrow** :: [Type => Str]

    Modify vector parameters. For vector heads, append vector head size [Default is 0, i.e., stick-plot].
    ($(GMTdoc)grdvector.html#q)
- $(GMT.opt_P)
- $(GMT.opt_R)
- **S** | **vec_scale** :: [Type => Str | Number]		``Arg = [i|l]scale[unit]``

    Sets scale for vector plot length in data units per plot distance measurement unit [1].
    ($(GMTdoc)grdvector.html#s)
- **T** | **sign_scale** :: [Type => Bool]

    Means the azimuths of Cartesian data sets should be adjusted according to the signs of the
    scales in the x- and y-directions [Leave alone].
    ($(GMTdoc)grdvector.html#t)
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** | **pen** :: [Type => Str | Number]

    Sets the attributes for the particular line.
    ($(GMTdoc)grdvector.html#w)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- **Z** | **azimuth** :: [Type => Bool]

    The theta grid provided contains azimuths rather than directions (implies -A).
    ($(GMTdoc)grdvector.html#z)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grdvector(cmd0::String="", arg1=nothing, arg2=nothing; first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("grdvector", cmd0, arg1, arg2)

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd, opt_B, = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd, = parse_common_opts(d, cmd, [:I :UVXY :f :p :t :params], first)
	cmd  = parse_these_opts(cmd, d, [[:A :polar], [:N :noclip :no_clip], [:S :vec_scale], [:T :sign_scale], [:Z :azimuth]])

    # Check case in which the two grids were transmitted by name. 
    (cmd0 != "" && isa(arg1, String)) && (cmd0 *= " " * arg1; arg1 = nothing)

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)	# Find how data was transmitted

	N_used = got_fname == 0 ? 1 : 0		# To know whether a cpt will go to arg1 or arg2
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, CPTaliases, 'C', N_used, arg1, arg2)
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')
	cmd = parse_Q_grdvec(d, [:Q :vec :vector :arrow], cmd)
	cmd *= add_opt_pen(d, [:W :pen], "W", true)     # TRUE to also seek (lw,lc,ls)

    return finish_PS_module(d, "grdvector " * cmd, "", K, O, true, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
function parse_Q_grdvec(d::Dict, symbs::Array{<:Symbol}, cmd::String)
	(show_kwargs[1]) && return print_kwarg_opts(symbs, "NamedTuple | String")
    if ((val = find_in_dict(d, symbs)[1]) !== nothing)
		if (isa(val, String))  cmd *= " -Q" * val		# An hard core GMT string directly with options
		else                   cmd *= " -Q" * vector_attrib(val)
		end
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
grdvector(arg1, arg2=nothing, cmd0::String="";  kw...) = grdvector(cmd0, arg1, arg2; first=true, kw...)
grdvector!(cmd0::String="", arg1=nothing, arg2=nothing; kw...) = grdvector(cmd0, arg1, arg2; first=false, kw...)
grdvector!(arg1, arg2=nothing, cmd0::String=""; kw...) = grdvector(cmd0, arg1, arg2; first=false, kw...)
