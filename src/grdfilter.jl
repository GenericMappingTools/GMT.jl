"""
	grdfilter(cmd0::String="", arg1=[], arg2=[]; kwargs...)

Filter a grid file in the time domain using one of the selected convolution or non-convolution 
isotropic or rectangular filters and compute distances using Cartesian or Spherical geometries.

Full option list at [`grdfilter`](http://gmt.soest.hawaii.edu/doc/latest/grdfilter.html)

Parameters
----------

- $(GMT.opt_R)
- **I** : **inc** : -- Str or Number --
	*x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/surface.html#i)
- **N** : **model** : -- Str or Number --
	Contours to be drawn.
	[`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdfilter.html#n)
- **D** : **diff** : -- Str or [] --
	Dump contours as data line segments; no plotting takes place.
	[`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdfilter.html#d)
- **T** : **trend** : -- Str or [] --
	Output the trend surface 
	[`-T`](http://gmt.soest.hawaii.edu/doc/latest/grdfilter.html#t)
- **W** : **weights** : -- Str --
	Used to 
	[`-W`](http://gmt.soest.hawaii.edu/doc/latest/grdfilter.html#w)
- $(GMT.opt_R)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grdfilter(cmd0::String="", arg1=[], kwargs...)

	length(kwargs) == 0 && return monolitic("grdfilter", cmd0, arg1)	# Speedy mode

	if (isempty(cmd0) && isempty_(arg1))
		error("Must provide the grid to work with.")
	end

	d = KW(kwargs)

	cmd, opt_R = parse_R("", d)
	cmd = parse_V(cmd, d)
	cmd = parse_f(cmd, d)

    cmd = add_opt(cmd, 'D', d, [:D :distflag :distance])
    cmd = add_opt(cmd, 'F', d, [:F :filter])
    cmd = add_opt(cmd, 'G', d, [:G :outgrid])
    cmd = add_opt(cmd, 'I', d, [:I :inc])
	cmd = add_opt(cmd, 'N', d, [:N :nans])
	cmd = add_opt(cmd, 'T', d, [:T :toggle])

	ff = findfirst("-G", cmd)
	ind = (ff == nothing) ? 0 : first(ff)
	if (ind > 0 && cmd[ind+2] != ' ')      # A file name was provided
		no_output = true
	else
		no_output = false
	end

    O = nothing
	if (isempty_(arg1) && !isempty(cmd0))	# Grid was passed as file name
		cmd = cmd0 * " " * cmd
		(haskey(d, :Vd)) && println(@sprintf("\tgrdtrend %s", cmd))
		if (no_output)
			gmt("grdfilter " * cmd)
		else
			O = gmt("grdfilter " * cmd)
		end
	else
		(haskey(d, :Vd)) && println(@sprintf("\tgrdtrend %s", cmd))
		if (no_output)
			gmt("grdfilter " * cmd, arg1)
		else
			O = gmt("grdfilter " * cmd, arg1)
		end
    end
    return O
end

# ---------------------------------------------------------------------------------------------------
grdfilter(arg1=[], cmd0::String=""; kw...) = grdfilter(cmd0, arg1; kw...)