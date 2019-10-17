"""
	gmtconnect(cmd0::String="", arg1=nothing, kwargs...)

Connect individual lines whose end points match within tolerance

Full option list at [`gmtconnect`]($(GMTdoc)gmtconnect.html)

Parameters
----------

- **C** | **closed** :: [Type => Str | []]        `Arg = [closed]`

    Write all the closed polygons to closed [gmtgmtconnect_closed.txt] and return all other
    segments as they are. No gmtconnection takes place.
    ($(GMTdoc)gmtconnect.html#c)
- **D** | **dump** :: [Type => Str | []]   `Arg = [template]`

    For multiple segment data, dump each segment to a separate output file
    ($(GMTdoc)gmtconnect.html#d)
- **L** | **linkfile** :: [Type => Str | []]      `Arg = [linkfile]`

    Writes the link information to the specified file [gmtgmtconnect_link.txt].
    ($(GMTdoc)gmtconnect.html#l)
- **Q** | **list_file** :: [Type => Str | []]      `Arg =  [listfile]`

    Used with **D** to write a list file with the names of the individual output files.
    ($(GMTdoc)gmtconnect.html#q)
- **T** | **tolerance ** :: [Type => Str | List]    `Arg = [cutoff[unit][/nn_dist]]`

    Specifies the separation tolerance in the data coordinate units [0]; append distance unit.
    If two lines has end-points that are closer than this cutoff they will be joined.
    ($(GMTdoc)gmtconnect.html#t)
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_o)
- $(GMT.opt_swap_xy)
"""
function gmtconnect(cmd0::String="", arg1=nothing, arg2=nothing; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("gmtconnect", cmd0, arg1)

	d = KW(kwargs)
	cmd = parse_common_opts(d, "", [:V_params :b :d :e :f :g :h :i :o :yx])
	cmd = parse_these_opts(cmd, d, [[:C :closed], [:D :dump], [:L :linkfile], [:Q :list_file], [:T :tolerance]])

	common_grd(d, cmd0, cmd, "gmtconnect ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtconnect(arg1, arg2=nothing, cmd0::String=""; kw...) = gmtconnect(cmd0, arg1, arg2; kw...)