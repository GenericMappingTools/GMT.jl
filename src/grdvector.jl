"""
	grdvector(cmd0::String="", arg1=nothing, arg2=nothing, kwargs...)

Takes two 2-D grid files which represents the x- and y-components of a vector field and produces
a vector field plot by drawing vectors with orientation and length according to the information
in the files. Alternatively, polar coordinate r, theta grids may be given instead.

Full option list at [`grdvector`](http://gmt.soest.hawaii.edu/doc/latest/grdvector.html)

Parameters
----------

- **A** : **polar** : -- Bool or [] --  

    The grid contain polar (r, theta) components instead of Cartesian (x, y) [Default is Cartesian components].
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/grdvector.html#a)
- $(GMT.opt_B)
- **G** : **fill** : -- Str or Number --

    Sets color or shade for vector interiors [Default is no fill].
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdvector.html#g)
- **I** : **inc** : -- Sytr or Number --	`Flags=[x]dx[/dy]`

    Only plot vectors at nodes every x_inc, y_inc apart (must be multiples of original grid spacing).
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grdvector.html#i)
- **N** : **noclip** : **no_clip** : -- Bool or [] --

    Do NOT clip symbols that fall outside map border 
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdvector.html#n)
- **Q** : **vec** : **vector** : **arrow** : -- Str --

    Modify vector parameters. For vector heads, append vector head size [Default is 0, i.e., stick-plot].
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/grdvector.html#q)
- $(GMT.opt_P)
- $(GMT.opt_R)
- **S** : **vec_scale** : -- Str or Number --		`Flags = [i|l]scale[unit]``

    Sets scale for vector plot length in data units per plot distance measurement unit [1].
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/grdvector.html#s)
- **T** : -- Bool or [] --

    Means the azimuths of Cartesian data sets should be adjusted according to the signs of the
    scales in the x- and y-directions [Leave alone].
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grdvector.html#t)
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** : **pen** : -- Str or Number --

    Sets the attributes for the particular line.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/grdvector.html#w)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- **Z** : **azimuth** : -- [] or Bool --

    The theta grid provided contains azimuths rather than directions (implies -A).
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/grdvector.html#z)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grdvector(cmd0::String="", arg1=nothing, arg2=nothing; first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("grdvector", cmd0, arg1, arg2)

	d = KW(kwargs)
	output, opt_T, fname_ext, K, O = fname_out(d, first)		# OUTPUT may have been an extension only

	cmd, opt_B, = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd = parse_common_opts(d, cmd, [:UVXY :f :p :t :params], first)
	cmd = parse_these_opts(cmd, d, [[:A :polar], [:I :inc], [:N :noclip :no_clip], [:S :vec_scale],
				[:T], [:Z :azimuth]])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, arg1)	# Find how data was transmitted

	N_used = got_fname == 0 ? 1 : 0		# To know whether a cpt will go to arg1 or arg2
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_used, arg1, arg2)

	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')

	if ((val = find_in_dict(d, [:Q :vec :vector :arrow], true)[1]) !== nothing)	# and delete to no be reused in :W
		if (isa(val, String))  cmd *= " -Q" * val		# An hard core GMT string directly with options
		else                   cmd *= " -Q" * vector_attrib(val)
		end
	end
	cmd *= add_opt_pen(d, [:W :pen], "W")

    return finish_PS_module(d, "grdvector " * cmd, "", output, fname_ext, opt_T, K, O, true, arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
grdvector(arg1, arg2=nothing, cmd0::String="";  kw...) = grdvector(cmd0, arg1, arg2; first=true, kw...)
grdvector!(cmd0::String="", arg1=nothing, arg2=nothing; kw...) = grdvector(cmd0, arg1, arg2; first=false, kw...)
grdvector!(arg1, arg2=nothing, cmd0::String=""; kw...) = grdvector(cmd0, arg1, arg2; first=false, kw...)
