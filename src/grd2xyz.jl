"""
	grd2xyz(cmd0::String="", arg1=nothing, kwargs...)

Reads one 2-D grid and returns xyz-triplets.

Full option list at [`grd2xyz`]($(GMTdoc)grd2xyz.html)

Parameters
----------

- $(GMT.opt_J)
- **C** | **rcnumbers** | **row_col** :: [Type => Bool]

    Replace the x- and y-coordinates on output with the corresponding column and row numbers.
    ($(GMTdoc)grd2xyz.html#c)
- **L** | **hvline** :: [Type => String]

    Limit the output of records to a single row or column.
- $(GMT.opt_R)
- **T** | **stl** | **STL** :: [Type => String]

    Compute a STL triangulation for 3-D printing.
- $(GMT.opt_V)
- **W** | **weight** :: [Type => Str]           `Arg = [a|weight]`

    Write out x,y,z,w, where w is the supplied weight (or 1 if not supplied) [Default writes x,y,z only].
    ($(GMTdoc)grd2xyz.html#w)
- **Z** | **onecol** :: [Type => Str]

    Write a 1-column table. Output will be organized according to the specified ordering
    convention contained in ``flags``.
    ($(GMTdoc)grd2xyz.html#z)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_bo)
- $(GMT.opt_d)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_o)
- $(GMT.opt_s)
"""
function grd2xyz(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:R :V_params :bo :d :f :h :o :s])
	cmd  = parse_these_opts(cmd, d, [[:C :rcnumbers :row_col], [:L :hvline], [:T :stl :STL], [:W :weight], [:Z :onecol]])
	((val = find_in_dict(d, [:name :save])[1]) !== nothing) && (cmd *=  " > " * string(val))
	common_grd(d, cmd0, cmd, "grd2xyz ", arg1)	# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grd2xyz(arg1; kw...) = grd2xyz("", arg1; kw...)