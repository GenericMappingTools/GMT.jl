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
- **N** : **no_clip** : -- Bool or [] --

    Do NOT clip symbols that fall outside map border 
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdvector.html#n)
- **Q** : **vec** : **vector** : **arrow** : -- Str --

    Modify vector parameters. For vector heads, append vector head size [Default is 0, i.e., stick-plot].
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/grdvector.html#q)
- $(GMT.opt_P)
- $(GMT.opt_R)
- **S** : **scale** : -- Str or Number --		Flags = [i|l]scale[unit]

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
function grdvector(cmd0::String="", arg1=nothing, arg2=nothing; K=false, O=false, first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("grdvector", cmd0, arg1)

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

    cmd, opt_B, = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd  = parse_UVXY(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_p(cmd, d)
	cmd, = parse_t(cmd, d)
	cmd  = parse_params(cmd, d)

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance
	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)	# Find how data was transmitted

	N_used = got_fname == 0 ? 1 : 0		# To know whether a cpt will go to arg1 or arg2
	cmd, arg1, arg2, = add_opt_cpt(d, cmd, [:C :color :cmap], 'C', N_used, arg1, arg2)

	cmd = add_opt(cmd, 'A', d, [:A :polar])
	cmd = add_opt(cmd, 'G', d, [:G :fill])
	cmd = add_opt(cmd, 'I', d, [:I :inc])
	cmd = add_opt(cmd, 'N', d, [:N :no_clip])
	cmd = add_opt(cmd, 'S', d, [:S :scale])
	cmd = add_opt(cmd, 'T', d, [:T])
	cmd = cmd * add_opt_pen(d, [:W :pen], "W")
	cmd = add_opt(cmd, 'Z', d, [:Z :azimuth])

	for symb in [:Q :vec :vector :arrow]
		if (haskey(d, symb))
			if (isa(d[symb], String))		# An hard core GMT string directly with options
				cmd = cmd * " -Q" * d[symb]
			else
				cmd = cmd * " -Q" * vector_attrib(d[symb])
			end
			break
		end
	end

	cmd = finish_PS(d, cmd, output, K, O)
    return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, "grdvector", arg1, arg2)
end

# ---------------------------------------------------------------------------------------------------
grdvector(arg1=nothing, arg2=nothing, cmd0::String=""; K=false, O=false, first=true,  kw...) =
	grdvector(cmd0, arg1, arg2; K=false, O=false, first=true,  kw...)

grdvector!(cmd0::String="", arg1=nothing, arg2=nothing; K=true, O=true, first=false, kwargs...) =
	grdvector(cmd0, arg1, arg2; K=K, O=O, first=first,  kw...)

grdvector!(arg1=nothing, arg2=nothing, cmd0::String=""; K=true, O=true, first=false,  kw...) =
	grdvector(cmd0, arg1, arg2; K=K, O=O, first=false,  kw...)
