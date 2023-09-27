"""
    gmtinfo(cmd0::String="", arg1=nothing; kwargs...)

Reads files and finds the extreme values in each of the columns.

See full GMT (not the `GMT.jl` one) docs at [`gmtinfo`]($(GMTdoc)gmtinfo.html)

Parameters
----------

- **A** | **ranges** :: [Type => Str]

    Specify how the range should be reported.
- **C** | **numeric** :: [Type => Bool]

    Report the min/max values per column in separate columns [Default uses <min/max> format].
- **D** | **center** :: [Type => Bool]

    Modifies results obtained by -I by shifting the region to better align with the center of the data.
- **E** | **get_record** :: [Type => Str | []]

    Returns the record whose column col contains the minimum (l) or maximum (h) value. 
- **F** | **counts** :: [Type => Str | []]

    Returns the counts of various records depending on the appended mode.
- **I** | **inc** | **increment** | **spacing** :: [Type => Str | Number | Tuple]

    Report the min/max of the first n columns to the nearest multiple of the provided increments
    and output results in the form -Rw/e/s/n 
- **L** | **common_limits** :: [Type => Bool]

    Determines common limits across tables or segments.
- **S** | **for_error_bars** :: [Type => Str | []]

    Add extra space for error bars. Useful together with I option and when later plotting with `plot E`.
- **T** | **nearest_multiple** :: [Type => Str | Number]    ``Arg = dz[+ccol]``

    Report the min/max of the first (0’th) column to the nearest multiple of dz and output this as
    the string -Tzmin/zmax/dz.
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT._opt_bi)
- $(GMT._opt_di)
- $(GMT.opt_e)
- $(GMT._opt_f)
- $(GMT.opt_g)
- $(GMT._opt_h)
- $(GMT._opt_i)
- $(GMT.opt_o)
- $(GMT.opt_r)
- $(GMT.opt_w)
- $(GMT.opt_swap_xy)
"""
function gmtinfo(cmd0::String="", arg1=nothing; kwargs...)::Union{String, GMTdataset}

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd, = parse_common_opts(d, "", [:V_params :e :f :o :r :w :yx])
	(endswith(cmd, "-:")) && (cmd *= "i")    # Need to be -:i not -: to not swap output too
	cmd = parse_these_opts(cmd, d, [[:A :ranges], [:C :numeric :per_column], [:D :center], [:E :get_record], [:F :counts],
	                                [:L :common_limits], [:S :for_error_bars]])
	cmd = add_opt(d, cmd, "I", [:I :inc :increment :spacing],
	              (exact=("e", nothing, 1), polyg=("b", nothing, 1), surface=("s", nothing, 1), fft=("d", nothing, 1), inc=("", arg2str, 2)))
	cmd = add_opt(d, cmd, "T", [:T :nearest_multiple], (dz="", col="+c", column="+c"))

	# If file name sent in, read it.
	if (cmd0 != "")  cmd, arg1, = read_data(d, cmd0, cmd, arg1, " ")  end
	if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end
	isa(arg1, Tuple) ? gmt("gmtinfo " * cmd, arg1...) : gmt("gmtinfo " * cmd, arg1)
end

# ---------------------------------------------------------------------------------------------------
gmtinfo(arg1; kw...) = gmtinfo("", arg1; kw...)