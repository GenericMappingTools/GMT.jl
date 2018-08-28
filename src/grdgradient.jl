"""
	grdgradient(cmd0::String="", arg1=[], kwargs...)

Compute the directional derivative in a given direction, or to find the direction [and the magnitude]
of the vector gradient of the data.

Full option list at [`grdgradient`](http://gmt.soest.hawaii.edu/doc/latest/grdgradient.html)

Parameters
----------

- **A** : **azim** : -- Str or Number --    Flags = azim[/azim2]

    Azimuthal direction for a directional derivative. 
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/grdgradient.html#a)
- **D** : **find_dir** : -- Str --      Flags = [a][c][o][n]

    Find the direction of the positive (up-slope) gradient of the data.
	[`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdgradient.html#d)
- **G** : **outgrid** : -- Str --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdgradient(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdgradient.html#g)
- **E** : **lambertian** : -- Str --    Flags = [m|s|p]azim/elev[+aambient][+ddiffuse][+pspecular][+sshine] 

    Compute Lambertian radiance appropriate to use with grdimage and grdview.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#e)
- **L** : **bc** : **boundary** : -- Str --

    Boundary condition flag.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/grdgradient.html#l)
- **N** : **normalize** : -- Str --     Flags = [e|t][amp][+ssigma][+ooffset]

    Normalization. [Default is no normalization.] The actual gradients g are offset and scaled
    to produce normalized gradients.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdgradient.html#n)
- $(GMT.opt_R)
- **S** : **slopegrid** : -- Str --

    Name of output grid file with scalar magnitudes of gradient vectors. Requires D but makes G optional.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/grdgradient.html#s)
- $(GMT.opt_R)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grdgradient(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("grdgradient", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)

	cmd, = parse_R("", d)
	cmd = parse_V_params(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_n(cmd, d)

    cmd = add_opt(cmd, 'A', d, [:A :azim])
    cmd = add_opt(cmd, 'D', d, [:D :find_dir])
    cmd = add_opt(cmd, 'G', d, [:G :outgrid])
    cmd = add_opt(cmd, 'E', d, [:E :lambertian])
	cmd = add_opt(cmd, 'L', d, [:L :bc :boundary])
	cmd = add_opt(cmd, 'N', d, [:N :normalize])
    cmd = add_opt(cmd, 'S', d, [:S :slopegrid])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "grdgradient", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdgradient(arg1=[], cmd0::String=""; kw...) = grdgradient(cmd0, arg1; kw...)