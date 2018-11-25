"""
	grdhisteq(cmd0::String="", arg1=[], kwargs...)

Find the data values which divide a given grid file into patches of equal area. One common use of
grdhisteq is in a kind of histogram equalization of an image.

Full option list at [`grdhisteq`](http://gmt.soest.hawaii.edu/doc/latest/grdhisteq.html)

Parameters
----------

- **D** : **dump** : -- Str or [] --

    Dump level information to file, or standard output if no file is provided.
	[`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdhisteq.html#d)
- **G** : **outgrid** : -- Str --

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdhisteq(....) form.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdhisteq.html#g)
- **N** : **gaussian** : -- Number or [] --

    Gaussian output.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/grdhisteq.html#n)
- **Q** : **quadratic** : -- Bool --

    Quadratic output. Selects quadratic histogram equalization. [Default is linear].
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/grdhisteq.html#q)
- $(GMT.opt_R)
- $(GMT.opt_V)
"""
function grdhisteq(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("grdhisteq", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:R :V_params])
	cmd = add_opt(cmd, 'C', d, [:C :n_cells])
	cmd = add_opt(cmd, 'D', d, [:D :dump])
	cmd = add_opt(cmd, 'G', d, [:G :outgrid])
	cmd = add_opt(cmd, 'N', d, [:N :gaussian])
	cmd = add_opt(cmd, 'Q', d, [:Q :quadratic])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	if (isa(arg1, Array{<:Number}))		arg1 = mat2grid(arg1)	end
	return common_grd(d, cmd, got_fname, 1, "grdhisteq", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdhisteq(arg1=[], cmd0::String=""; kw...) = grdhisteq(cmd0, arg1; kw...)