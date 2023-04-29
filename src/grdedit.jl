"""
	grdedit(cmd0::String="", arg1=nothing, kwargs...)

Reads the header information in a binary 2-D grid file and replaces the information with
values provided on the command line.

If single input is a G GMTgrid object, it will update the z_min|max values of the G.range member

See full GMT (not the `GMT.jl` one) docs at [`grdedit`]($(GMTdoc)grdedit.html)

Parameters
----------

- **A** | **adjust_inc** :: [Type => Bool]

    If necessary, adjust the file’s x_inc, y_inc to be compatible with its domain.
- **C** | **adjust_inc** :: [Type => Bool]

    Clear the command history from the grid header.
- **D** | **header** :: [Type => Str]    ``Arg = [+xxname][+yyname][+zzname][+sscale][+ooffset][+ninvalid][+ttitle][+rremark``

    Change these header parameters.
- **E** | **header** :: [Type => Str]    ``Arg = [a|h|l|r|t|v]``

    Transform the grid in one of six ways and (for l|r|t) interchange the x and y information
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdedit(....) form.
- $(GMT._opt_J)
- **N** | **replace** :: [Type => Str | Mx3 array]      ``Arg = replace=fname | replace=Array``

    Read the ASCII (or binary) file table and replace the corresponding nodal values in the
    grid with these x,y,z values. Alternatively, provide a Mx3 matrix with values to be changed. 
- $(GMT._opt_R)
- **S** | **wrap** :: [Type => Bool]

    For global, geographical grids only. Grid values will be shifted longitudinally according to
    the new borders given in ``limits`` (R option).
- **T** | **toggle_reg** | **toggle** :: [Type => Bool]

    Make necessary changes in the header to convert a gridline-registered grid to a pixel-registered
    grid, or vice-versa.
- $(GMT.opt_V)
- $(GMT._opt_bi)
- $(GMT._opt_di)
- $(GMT.opt_e)
- $(GMT._opt_f)
- $(GMT.opt_swap_xy)
"""
function grdedit(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	arg2 = nothing
	(isa(arg1, GMTgrid) && length(kwargs) == 0) && (arg1.range[5:6] .= extrema(arg1); return arg1)  # Update the z_min|max

	cmd, = parse_common_opts(d, "", [:G :R :V_params :bi :di :e :f :w :yx])
	cmd = parse_J(d, cmd, " ")[1]       # No default J here.
	cmd  = parse_these_opts(cmd, d, [[:A :adjust_inc], [:C :clear_history], [:D :header], [:E :flip],
	                                 [:L :adust_lon], [:S :wrap], [:T :toggle :toggle_reg]])
	cmd, args, n, = add_opt(d, cmd, "N", [:N :replace], :data, Array{Any,1}([arg1, arg2]), (x="",))
	if (n > 0)  arg1, arg2 = args[:]  end

    (arg1 !== nothing) && (wkt = arg1.wkt; arg1.wkt = ""; proj4 = arg1.proj4; arg1.proj4 = "")  # GMT bug fixed 18-4-2023
	G = common_grd(d, cmd0, cmd, "grdedit ", arg1, arg2)		# Finish build cmd and run it
    (arg1 !== nothing) && (G.wkt = wkt; G.proj4 = proj4)
    G
end

# ---------------------------------------------------------------------------------------------------
grdedit(arg1; kw...) = grdedit("", arg1; kw...)