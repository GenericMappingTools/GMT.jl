"""
	grdfilter(cmd0::String="", arg1=nothing, kwargs...)

Filter a grid file in the time domain using one of the selected convolution or non-convolution 
isotropic or rectangular filters and compute distances using Cartesian or Spherical geometries.

Full option list at [`grdfilter`](http://gmt.soest.hawaii.edu/doc/latest/grdfilter.html)

Parameters
----------

- **F** : **filter** : -- Str --

    Sets the filter type. 
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/grdfilter.html#f)
- **D** : **distflag** : **distance** : -- Number --

    Distance flag tells how grid (x,y) relates to filter width.
	[`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdfilter.html#d)

- **G** : **outgrid** : -- Str --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdfilter(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdfilter.html#g)
- **I** : **inc** : -- Str or Number --

    *x_inc* [and optionally *y_inc*] is the grid spacing.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/grdfilter.html#i)
- **N** : **nans** : -- Str --

    Determine how NaN-values in the input grid affects the filtered output. Values are i|p|r
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdfilter.html#n)
- $(GMT.opt_R)
- **T** : **toggle** : -- Bool --

    Toggle the node registration for the output grid so as to become the opposite of the input grid
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grdfilter.html#t)
- $(GMT.opt_V)
- $(GMT.opt_f)
"""
function grdfilter(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && return monolitic("grdfilter", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params :f])
	cmd = parse_these_opts(cmd, d, [[:D :distflag :distance], [:F :filter], [:G :outgrid], [:I :inc],
				[:N :nans], [:G :outgrid :table], [:T :toggle]])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	if (isa(arg1, Array{<:Number}))		arg1 = mat2grid(arg1)	end
	return common_grd(d, "grdfilter " * cmd, got_fname, 1, arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdfilter(arg1, cmd0::String=""; kw...) = grdfilter(cmd0, arg1; kw...)