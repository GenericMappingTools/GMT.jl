"""
	gmtconvert(cmd0::String="", arg1=[], kwargs...)

Convert, Paste, and/or Extract columns from data tables

Full option list at [`gmtconvert`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html)

Parameters
----------

- **A** : **h_cat** : -- Str or [] --

    The records from the input files should be pasted horizontally, not appended vertically [Default].
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html#A)
- **C** : **n_records** : -- Str --  Flags = [+lmin][+umax][+i]

    Only output segments whose number of records matches your given criteria:
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html#c)
- **D** : **dump** : -- Str or [] --   Flags = [template[+oorig]]

    For multiple segment data, dump each segment to a separate output file.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html#d)
- **E** : **first_last** : -- Str or [] --   Flags = [f|l|m|Mstride]

    Only extract the first and last record for each segment of interest.
    [`-E`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html#e)
- **F** : **conn_method** : -- Str or [] --   Flags = [c|n|r|v][refpoint]

    Alter the way points are connected (by specifying a scheme) and data are grouped (by specifying a method).
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html#f)
- **I** : **invert** : -- Str or [] --      Flags = [tsr]

    Invert the order of items, i.e., output the items in reverse order, starting with the last
    and ending up with the first item.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html#i)
- **L** : **list_only** : -- Bool or [] --

    Only output a listing of all segment header records and no data records.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html#l)
- **N** : **sort** : -- Str or Number --      Flags = [- |+]col

    Numerically sort each segment based on values in column col.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html#n)
- **Q** : **select_num** : -- Str --      Flags =  [~]selection

    Only write segments whose number is included in ``selection`` and skip all others.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html#q)
- **S** : **select_hdr** : -- Str --      Flags =  [~]”search string” or [~]/regexp/[i]

    Only output those segments whose header record contains the specified text string.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html#s)
- **T** : **suppress ** : -- Str or [] --    Flags = [h|d]

    Suppress the writing of certain records on output. Append h to suppress segment headers
    [Default] or d to suppress duplicate data records. Use T=:hd to suppress both types of records.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html#t)
- **W** : **gmtconvert** : -- Str or [] --      Flags =  [+n]

    Attempt to gmtconvert each word in the trialing text to a number and append such values
    to the numerical output columns.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html#w)
- **Z** : **range** : -- Str or [] --      Flags =  [first][:last]

    Limit output to the specified record range. If first is not set it defaults to record 0
    (very first record) and if last is not set then it defaults to the very last record.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/gmtconvert.html#z)
- $(GMT.opt_V)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_o)
- $(GMT.opt_s)
- $(GMT.opt_swap_xy)
"""
function gmtconvert(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("gmtconvert", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)

	cmd = parse_V_params("", d)
	cmd, = parse_b(cmd, d)
	cmd, = parse_d(cmd, d)
	cmd, = parse_e(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_g(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, = parse_i(cmd, d)
	cmd, = parse_o(cmd, d)
	cmd, = parse_s(cmd, d)
	cmd, = parse_swap_xy(cmd, d)

	cmd = add_opt(cmd, 'A', d, [:A :h_cat])
	cmd = add_opt(cmd, 'C', d, [:C :n_records])
	cmd = add_opt(cmd, 'D', d, [:D :dump])
	cmd = add_opt(cmd, 'E', d, [:E :first_last])
	cmd = add_opt(cmd, 'F', d, [:F :conn_method])
	cmd = add_opt(cmd, 'I', d, [:I :invert])
	cmd = add_opt(cmd, 'L', d, [:L :list_only])
	cmd = add_opt(cmd, 'N', d, [:N :sort])
	cmd = add_opt(cmd, 'Q', d, [:Q :select_num])
	cmd = add_opt(cmd, 'S', d, [:S :select_hdr])
	cmd = add_opt(cmd, 'T', d, [:T :suppress])
	cmd = add_opt(cmd, 'W', d, [:W :gmtconvert])
	cmd = add_opt(cmd, 'Z', d, [:Z :range])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "gmtconvert", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtconvert(arg1=[], cmd0::String=""; kw...) = gmtconvert(cmd0, arg1; kw...)