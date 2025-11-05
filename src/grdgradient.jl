"""
	grdgradient(cmd0::String="", arg1=nothing, kwargs...)

Compute the directional derivative in a given direction, or to find the direction [and the magnitude]
of the vector gradient of the data.

See full GMT docs at [`grdgradient`]($(GMTdoc)grdgradient.html)

Parameters
----------

- **A** | **azim** | **azimuth** :: [Type => Str | Number]    ``Arg = azim[/azim2]``

    Azimuthal direction for a directional derivative. 
- **D** | **find_dir** :: [Type => Str]      ``Arg = [a][c][o][n]``

    Find the direction of the positive (up-slope) gradient of the data.
- **G** | **save** | **write** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdgradient(....) form.
- **E** | **lambert** :: [Type => Str]    ``Arg = [m|s|p]azim/elev[+aambient][+ddiffuse][+pspecular][+sshine] ``

    Compute Lambertian radiance appropriate to use with grdimage and grdview.
- **N** | **norm** | **normalize** :: [Type => Str]     ``Arg = [e|t][amp][+ssigma][+ooffset]``

    Normalization. [Default is no normalization.] The actual gradients g are offset and scaled
    to produce normalized gradients.
- **Q** | **save_stats** :: [Type => Str]		``Arg = c|r|R``

    Controls how normalization via N is carried out.
- $(_opt_R)
- **S** | **slopegrid** :: [Type => Str]

    Name of output grid file with scalar magnitudes of gradient vectors. Requires D but makes G optional.
- $(opt_V)
- $(_opt_f)

To see the full documentation type: ``@? grdgradient``
"""
function grdgradient(cmd0::String; kwargs...)
	d, cmd = grdgrad_helper(;kwargs...)
	common_grd(d, cmd0, cmd, "grdgradient ", nothing)		# Finish build cmd and run it
end

function grdgradient(arg1; kwargs...)
	d, cmd = grdgrad_helper(;kwargs...)
	common_grd(d, "", cmd, "grdgradient ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
function parse_Q_grdgrad(d::Dict, symbs::Array{<:Symbol}, cmd::String)
	(SHOW_KWARGS[]) && return print_kwarg_opts(symbs, "String")
    if ((val_ = hlp_desnany_str(d, symbs)) !== "")
		val = val_[1]
		(val == 's') && (val = 'c')
		(val == 'c' || val == 'r' || val == 'R') && (cmd *= " -Q" * val)
    end
    return cmd
end

# ---------------------------------------------------------------------------------------------------
function grdgrad_helper(;kw...)
	d = init_module(false, kw...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:G :R :V_params :f :n])
	cmd  = parse_these_opts(cmd, d, [[:A :azim :azimuth], [:D :find_dir], [:S :slopegrid]])
	cmd  = add_opt(d, cmd, "E", [:E :lambert], 
	       (manip=("m", nothing, 1), simple=("s", nothing, 1), peucker=("p", nothing, 1), view=("", arg2str), ambient="+a", difuse="+d", specular="+p", shine="+s") )
	cmd  = add_opt(d, cmd, "N", [:N :norm :normalize],
           (laplace=("e", nothing, 1), cauchy=("t", nothing, 1), amp="", sigma="+s", offset="+o"))
	cmd = parse_Q_grdgrad(d, [:Q :save_stats], cmd)
	return d, cmd
end
