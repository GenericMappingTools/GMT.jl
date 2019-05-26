"""
	grdgradient(cmd0::String="", arg1=nothing, kwargs...)

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
- **E** : **lambert** : -- Str --    Flags = [m|s|p]azim/elev[+aambient][+ddiffuse][+pspecular][+sshine] 

    Compute Lambertian radiance appropriate to use with grdimage and grdview.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#e)
- **N** : **norm** : **normalize** : -- Str --     Flags = [e|t][amp][+ssigma][+ooffset]

    Normalization. [Default is no normalization.] The actual gradients g are offset and scaled
    to produce normalized gradients.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdgradient.html#n)
- **Q** : **save_stats** : -- Str --		Flags = c|r|R

    Controls how normalization via N is carried out.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/grdgradient.html#q)
- $(GMT.opt_R)
- **S** : **slopegrid** : -- Str --

    Name of output grid file with scalar magnitudes of gradient vectors. Requires D but makes G optional.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/grdgradient.html#s)
- $(GMT.opt_R)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grdgradient(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("grdgradient", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :f :n])
	cmd = parse_these_opts(cmd, d, [[:A :azim], [:D :find_dir], [:G :outgrid], [:S :slopegrid]])
	cmd = add_opt(cmd, 'E', d, [:E :lambert], 
	      (manip=("m", nothing, 1), simple=("s", nothing, 1), peucker=("p", nothing, 1), view=("", arg2str), ambient="+a", difuse="+d", specular="+p", shine="+s") )
	cmd = add_opt(cmd, 'N', d, [:N :norm :normalize],
		  (laplace=("e", nothing, 1), cauchy=("t", nothing, 1), amp="", sigma="+s", offset="+o"))
    if ((val = find_in_dict(d, [:Q :save_stats])[1]) !== nothing)
		val = string(val)[1]
		if (val == 's')  val = 'c'  end
        if (val == 'c' || val == 'r' || val == 'R')  cmd *= " -Q" * val  end
    end

	common_grd(d, cmd0, cmd, "grdgradient ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdgradient(arg1, cmd0::String=""; kw...) = grdgradient(cmd0, arg1; kw...)