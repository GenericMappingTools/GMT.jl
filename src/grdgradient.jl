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
	cmd = parse_these_opts(cmd, d, [[:A :azim], [:D :find_dir], [:G :outgrid], [:E :lambert],
				[:N :norm :normalize], [:S :slopegrid]])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	if (isa(arg1, Array{<:Number}))		arg1 = mat2grid(arg1)	end
	return common_grd(d, "grdgradient " * cmd, got_fname, 1, arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdgradient(arg1, cmd0::String=""; kw...) = grdgradient(cmd0, arg1; kw...)