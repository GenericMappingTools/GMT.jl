"""
    gmtinfo(cmd0::String="", arg1=[]; kwargs...)

Reads files and finds the extreme values in each of the columns.

Full option list at [`gmtinfo`](http://gmt.soest.hawaii.edu/doc/latest/gmtinfo.html)

Parameters
----------

- **A** : -- Str --

    Specify how the range should be reported.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/gmtinfo.html#a)
- **C** : **per_column** : -- Bool or [] --

    Report the min/max values per column in separate columns [Default uses <min/max> format].
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/gmtinfo.html#c)
- **D** : **center** : -- Bool or [] --  

    Modifies results obtained by -I by shifting the region to better align with the center of the data.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/gmtinfo.html#d)
- **E** : **get_record** : -- Str or [] --

    Returns the record whose column col contains the minimum (l) or maximum (h) value. 
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/gmtinfo.html#e)
- **F** : **counts** : -- Str or [] --

    Returns the counts of various records depending on the appended mode.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/gmtinfo.html#f)
- **I** : **report_region** : -- Number or Str --

    Report the min/max of the first n columns to the nearest multiple of the provided increments
    and output results in the form -Rw/e/s/n 
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/gmtinfo.html#i)
- **L** : **common_limits** : -- Bool or [] --

    Determines common limits across tables or segments.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/gmtinfo.html#l)
- **S** : **for_error_bars** : -- Str or [] --

    Add extra space for error bars. Useful together with I option and when later plotting with `plot E`.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/gmtinfo.html#s)
- **T** : **nearest_multiple** : -- Number or Str --

    Report the min/max of the first (0’th) column to the nearest multiple of dz and output this as
    the string -Tzmin/zmax/dz.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/gmtinfo.html#t)
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_o)
- $(GMT.opt_r)
- $(GMT.opt_swap_xy)
"""
function gmtinfo(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && !isa(arg1, GMTdataset) && return monolitic("gmtinfo", cmd0, arg1)

	d = KW(kwargs)
	cmd, opt_bi = parse_bi("", d)
	cmd, opt_di = parse_di(cmd, d)
	cmd, opt_i  = parse_i(cmd, d)
	cmd = parse_common_opts(d, cmd, [:V_params :e :f :h :o :r :xy])
	cmd = parse_these_opts(cmd, d, [[:A], [:C :per_column], [:D :center], [:E :get_record], [:F :counts],
		[:I :report_region], [:L :common_limits], [:S :for_error_bars], [:T :nearest_multiple]])

	# If file name sent in, read it.
	cmd, arg1, = read_data(d, cmd0, cmd, arg1, " ", opt_i, opt_bi, opt_di)

	(haskey(d, :Vd)) && println(@sprintf("\tgmtinfo %s", cmd))

	return gmt("gmtinfo " * cmd, arg1)
end

# ---------------------------------------------------------------------------------------------------
gmtinfo(arg1, cmd0::String=""; kw...) = gmtinfo(cmd0, arg1; kw...)