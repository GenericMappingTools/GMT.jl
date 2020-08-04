"""
	gmtconvert(cmd0::String="", arg1=nothing, kwargs...)

Convert, Paste, and/or Extract columns from data tables

Full option list at [`gmtconvert`]($(GMTdoc)gmtconvert.html)

Parameters
----------

- **A** | **h_cat** :: [Type => Str | []]

    The records from the input files should be pasted horizontally, not appended vertically [Default].
    ($(GMTdoc)gmtconvert.html#a)
- **C** | **n_records** :: [Type => Str]  ``Arg = [+lmin][+umax][+i]``

    Only output segments whose number of records matches your given criteria:
    ($(GMTdoc)gmtconvert.html#c)
- **D** | **dump** :: [Type => Str | []]   ``Arg = [template[+oorig]]``

    For multiple segment data, dump each segment to a separate output file.
    ($(GMTdoc)gmtconvert.html#d)
- **E** | **first_last** :: [Type => Str | []]   ``Arg = [f|l|m|Mstride]``

    Only extract the first and last record for each segment of interest.
    ($(GMTdoc)gmtconvert.html#e)
- **F** | **conn_method** :: [Type => Str | []]   ``Arg = [c|n|r|v][refpoint]``

    Alter the way points are connected (by specifying a scheme) and data are grouped (by specifying a method).
    ($(GMTdoc)gmtconvert.html#f)
- **I** | **invert** | **reverse** :: [Type => Str | Bool]      ``Arg = [tsr]``

    Invert the order of items, i.e., output the items in reverse order, starting with the last
    and ending up with the first item.
    ($(GMTdoc)gmtconvert.html#i)
- **L** | **list_only** :: -[Type => Bool]

    Only output a listing of all segment header records and no data records.
    ($(GMTdoc)gmtconvert.html#l)
- **N** | **sort** :: [Type => Str | Number]      ``Arg = [-|+]col``

    Numerically sort each segment based on values in column col.
    ($(GMTdoc)gmtconvert.html#n)
- **Q** | **select_num** :: [Type => Str]      ``Arg =  [~]selection``

    Only write segments whose number is included in ``selection`` and skip all others.
    ($(GMTdoc)gmtconvert.html#q)
- **S** | **select_hdr** :: [Type => Str]      ``Arg =  [~]”search string” or [~]/regexp/[i]``

    Only output those segments whose header record contains the specified text string.
    ($(GMTdoc)gmtconvert.html#s)
- **T** | **suppress** | **skip** :: [Type => Str | []]    ``Arg = [h|d]``

    Suppress the writing of certain records on output. Append h to suppress segment headers
    [Default] or d to suppress duplicate data records. Use T=:hd to suppress both types of records.
    ($(GMTdoc)gmtconvert.html#t)
- **W** | **word2num** :: [Type => Str | []]      ``Arg = [+n]``

    Attempt to gmtconvert each word in the trialing text to a number and append such values
    to the numerical output columns.
    ($(GMTdoc)gmtconvert.html#w)
- **Z** | **range** :: [Type => Str | []]      ``Arg =  [first][:last]``

    Limit output to the specified record range. If first is not set it defaults to record 0
    (very first record) and if last is not set then it defaults to the very last record.
    ($(GMTdoc)gmtconvert.html#z)
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_b)
- $(GMT.opt_bo)
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
function gmtconvert(cmd0::String="", arg1=nothing; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("gmtconvert", cmd0, arg1)

	d = KW(kwargs)
	cmd, = parse_common_opts(d, "", [:V_params :write :append :a :b :bo :d :e :f :g :h :i :o :s :yx])
	cmd  = parse_these_opts(cmd, d, [[:A :h_cat], [:C :n_records], [:D :dump], [:E :first_last], [:F :conn_method],
	                                 [:I :invert :reverse], [:L :list_only], [:N :sort], [:Q :select_num], [:S :select_hdr], [:T :suppress :skip], [:W :word2num], [:Z :range]])

	common_grd(d, cmd0, cmd, "gmtconvert ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtconvert(arg1; kw...) = gmtconvert("", arg1; kw...)