"""
	grdgradient(cmd0::String="", arg1=nothing, kwargs...)

Compute the directional derivative in a given direction, or to find the direction [and the magnitude]
of the vector gradient of the data.

Full option list at [`grdgradient`]($(GMTdoc)grdgradient.html)

Parameters
----------

- **A** | **azim** :: [Type => Str | Number]    ``Arg = azim[/azim2]``

    Azimuthal direction for a directional derivative. 
    ($(GMTdoc)grdgradient.html#a)
- **D** | **find_dir** :: [Type => Str]      ``Arg = [a][c][o][n]``

    Find the direction of the positive (up-slope) gradient of the data.
    ($(GMTdoc)grdgradient.html#d)
- **G** | **outgrid** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdgradient(....) form.
    ($(GMTdoc)grdgradient.html#g)
- **E** | **lambert** :: [Type => Str]    ``Arg = [m|s|p]azim/elev[+aambient][+ddiffuse][+pspecular][+sshine] ``

    Compute Lambertian radiance appropriate to use with grdimage and grdview.
    ($(GMTdoc)grdgradient.html#e)
- **N** | **norm** | **normalize** :: [Type => Str]     ``Arg = [e|t][amp][+ssigma][+ooffset]``

    Normalization. [Default is no normalization.] The actual gradients g are offset and scaled
    to produce normalized gradients.
    ($(GMTdoc)grdgradient.html#n)
- **Q** | **save_stats** :: [Type => Str]		``Arg = c|r|R``

    Controls how normalization via N is carried out.
    ($(GMTdoc)grdgradient.html#q)
- $(GMT.opt_R)
- **S** | **slopegrid** :: [Type => Str]

    Name of output grid file with scalar magnitudes of gradient vectors. Requires D but makes G optional.
    ($(GMTdoc)grdgradient.html#s)
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