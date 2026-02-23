"""
	grd2xyz(cmd0::String="", arg1=nothing, kwargs...)

Reads one 2-D grid and returns xyz-triplets.

See full GMT docs at [`grd2xyz`]($(GMTdoc)grd2xyz.html)

Parameters
----------

- $(_opt_J)
- **C** | **row_col** | **rowcol** :: [Type => Bool]

    Replace the x- and y-coordinates on output with the corresponding column and row numbers.
- **L** | **hvline** :: [Type => String]

    Limit the output of records to a single row or column.
- $(_opt_R)
- **T** | **stl** | **STL** :: [Type => String]

    Compute a STL triangulation for 3-D printing.
- $(opt_V)
- **W** | **weight** :: [Type => Str]           `Arg = [a|weight]`

    Write out x,y,z,w, where w is the supplied weight (or 1 if not supplied) [Default writes x,y,z only].
- **Z** | **onecol** | **one_col** :: [Type => Str]

    Write a 1-column table. Output will be organized according to the specified ordering
    convention contained in ``flags``.
- $(opt_write)
- $(opt_append)
- $(opt_bo)
- $(opt_d)
- $(_opt_f)
- $(_opt_h)
- $(opt_o)
- $(opt_s)
"""
grd2xyz(cmd0::String; kwargs...) = grd2xyz_helper(cmd0, nothing; kwargs...)
grd2xyz(arg1; kwargs...)         = grd2xyz_helper("", arg1; kwargs...)
function grd2xyz_helper(cmd0::String, arg1; kwargs...)
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	grd2xyz_helper(wrapGrids(cmd0, arg1), d)
end

# ---------------------------------------------------------------------------------------------------
function grd2xyz_helper(w::wrapGrids, d::Dict{Symbol, Any})
	cmd0, arg1 = unwrapGrids(w)

	cmd, = parse_common_opts(d, "", [:R :V_params :bo :d :f :h :o :s])
	cmd  = parse_these_opts(cmd, d, [[:C :rcnumbers :row_col :rowcol], [:L :hvline], [:T :stl :STL], [:W :weight], [:Z :onecol :one_col]])
	((val = find_in_dict(d, [:name :save])[1]) !== nothing) && (cmd *=  " > " * string(val))
	common_grd(d, cmd0, cmd, "grd2xyz ", arg1)	# Finish build cmd and run it
end
