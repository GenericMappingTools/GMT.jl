"""
    gmtinfo(cmd0::String="", arg1=nothing; kwargs...)

Reads files and finds the extreme values in each of the columns.

Parameters
----------

- **A** | **ranges** :: [Type => Str]

    Specify how the range should be reported.
- **C** | **numeric** | **per_column** :: [Type => Bool]

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
- $(opt_V)
- $(opt_write)
- $(opt_append)

To see the full documentation type: ``@? gmtinfo``
"""
gmtinfo(cmd0::String; kwargs...) = gmtinfo_helper(cmd0, nothing; kwargs...)
gmtinfo(arg1; kwargs...)         = gmtinfo_helper("", arg1; kwargs...)

function gmtinfo_helper(cmd0::String, arg1; kwargs...)
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
    gmtinfo_helper(cmd0, arg1, d)
end

# ---------------------------------------------------------------------------------------------------
function gmtinfo_helper(cmd0::String, arg1, d::Dict{Symbol,Any})::Union{String, GMTdataset}

	#=
	#cmd, = parse_common_opts(d, "", [:V_params :e :f :i :o :r :w :yx])
	cmd = parse_V_params(d, "")
	cmd = parse_e(d, cmd)[1]
	cmd = parse_f(d, cmd)[1]
	cmd = parse_i(d, cmd)[1]
	cmd = parse_o(d, cmd)[1]
	cmd = parse_r(d, cmd)[1]
	cmd = parse_w(d, cmd)[1]
	cmd = parse_swap_xy(d, cmd)[1]
	(endswith(cmd, "-:")) && (cmd *= "i")    # Need to be -:i not -: to not swap output too
	cmd = parse_these_opts(cmd, d, [[:A :ranges], [:C :numeric :per_column], [:D :center], [:E :get_record], [:F :counts],
	                                [:L :common_limits], [:S :for_error_bars]])
	cmd = add_opt(d, cmd, "I", [:I :inc :increment :spacing],
	              (exact=("e", nothing, 1), polyg=("b", nothing, 1), surface=("s", nothing, 1), fft=("d", nothing, 1), inc=("", arg2str, 2)); del=false, expand=true)
	cmd = add_opt(d, cmd, "T", [:T :nearest_multiple], (dz="", col="+c", column="+c"))
	=#

	cmd = gmtinfo_helper_helper(d)		# Parse only options that do not depend on the (fcking Any) 'arg1'

	if     (cmd0 != "")             cmd = cmd * " " * cmd0
	elseif (eltype(arg1) == String) cmd = cmd * " " * join(arg1, ' '); arg1 = nothing		# Accept also tuples/vecs of file names
	end
	cmd = "gmtinfo " * cmd
	if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end
	isa(arg1, Tuple) ? gmt(cmd, arg1...) : gmt(cmd, arg1)
end

function gmtinfo_helper_helper(d::Dict{Symbol,Any})::String
	cmd = parse_V_params(d, "")
	cmd = parse_e(d, cmd)[1]
	cmd = parse_f(d, cmd)[1]
	cmd = parse_i(d, cmd)[1]
	cmd = parse_o(d, cmd)[1]
	cmd = parse_r(d, cmd)[1]
	cmd = parse_w(d, cmd)[1]
	cmd = parse_swap_xy(d, cmd)[1]
	(endswith(cmd, "-:")) && (cmd *= "i")    # Need to be -:i not -: to not swap output too
	cmd = parse_these_opts(cmd, d, [[:A :ranges], [:C :numeric :per_column], [:D :center], [:E :get_record], [:F :counts],
	                                [:L :common_limits], [:S :for_error_bars]])
	cmd = add_opt(d, cmd, "I", [:I :inc :increment :spacing],
	              (exact=("e", nothing, 1), polyg=("b", nothing, 1), surface=("s", nothing, 1), fft=("d", nothing, 1), inc=("", arg2str, 2)); del=false, expand=true)
	add_opt(d, cmd, "T", [:T :nearest_multiple], (dz="", col="+c", column="+c"))
end
