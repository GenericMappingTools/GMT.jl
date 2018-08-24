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

	if (isempty(cmd0) && isempty_(arg1))
		error("Must provide the grid to work with.")
	end

	d = KW(kwargs)

	cmd, opt_R = parse_R("", d)
	cmd = parse_V(cmd, d)
	cmd = parse_params(cmd, d)

	cmd = add_opt(cmd, 'C', d, [:C :n_cells])
	cmd = add_opt(cmd, 'D', d, [:D :dump])
	cmd = add_opt(cmd, 'G', d, [:G :outgrid])
	cmd = add_opt(cmd, 'N', d, [:N :gaussian])
	cmd = add_opt(cmd, 'Q', d, [:Q :quadratic ])

	no_output = common_grd(cmd, 'G')		# See if an output is requested (or write result in grid file)
	return common_grd(d, cmd0, cmd, arg1, [], no_output, "grdhisteq")	# Shared by several grdxxx modules
end

# ---------------------------------------------------------------------------------------------------
grdhisteq(arg1=[], cmd0::String=""; kw...) = grdhisteq(cmd0, arg1; kw...)