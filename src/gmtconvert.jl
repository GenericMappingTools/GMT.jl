"""
	gmtconvert(cmd0::String="", arg1=nothing, kwargs...)

Convert, Paste, and/or Extract columns from data tables

Parameters
----------

- **A** | **hcat** :: [Type => Str | []]

    The records from the input files should be pasted horizontally, not appended vertically [Default].
- **C** | **n_records** :: [Type => Str]  ``Arg = [+lmin][+umax][+i]``

    Only output segments whose number of records matches your given criteria:
- **D** | **dump** :: [Type => Str | []]   ``Arg = [template[+oorig]]``

    For multiple segment data, dump each segment to a separate output file.
- **E** | **first_last** :: [Type => Str | []]   ``Arg = [f|l|m|Mstride]``

    Only extract the first and last record for each segment of interest.
- **F** | **conn_method** :: [Type => Str | []]   ``Arg = [c|n|r|v][refpoint]``

    Alter the way points are connected (by specifying a scheme) and data are grouped (by specifying a method).
- **I** | **invert** | **reverse** :: [Type => Str | Bool]      ``Arg = [tsr]``

    Invert the order of items, i.e., output the items in reverse order, starting with the last
    and ending up with the first item.
- **L** | **list_only** :: -[Type => Bool]

    Only output a listing of all segment header records and no data records.
- **N** | **sort** :: [Type => Str | Number]      ``Arg = [-|+]col``

    Numerically sort each segment based on values in column col.
- **Q** | **segments** :: [Type => Str]      ``Arg =  [~]selection``

    Only write segments whose number is included in ``selection`` and skip all others.
- **S** | **select_hdr** :: [Type => Str]      ``Arg =  [~]”search string” or [~]/regexp/[i]``

    Only output those segments whose header record contains the specified text string.
- **T** | **suppress** | **skip** :: [Type => Str | []]    ``Arg = [h|d]``

    Suppress the writing of certain records on output. Append h to suppress segment headers
    [Default] or d to suppress duplicate data records. Use T=:hd to suppress both types of records.
- **W** | **word2num** :: [Type => Str | []]      ``Arg = [+n]``

    Attempt to gmtconvert each word in the trialing text to a number and append such values
    to the numerical output columns.
- **Z** | **transpose** :: [Type => Str | []]      ``Arg =  [first][:last]``

    Limit output to the specified record range. If first is not set it defaults to record 0
    (very first record) and if last is not set then it defaults to the very last record.

To see the full documentation type: ``@? gmtconvert``
"""
gmtconvert(cmd0::String; kwargs...) = gmtconvert_helper(cmd0, nothing; kwargs...)
gmtconvert(arg1; kwargs...)         = gmtconvert_helper("", arg1; kwargs...)

function gmtconvert_helper(cmd0::String, arg1; kwargs...)
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
    gmtconvert_helper(cmd0, arg1, d)
end
# ---------------------------------------------------------------------------------------------------
function gmtconvert_helper(cmd0::String, arg1, d::Dict{Symbol,Any})

	cmd, = parse_common_opts(d, "", [:V_params :append :a :b :bo :d :e :g :h :i :o :q :s :w :yx])
    cmd, opt_f = parse_f(d, cmd)		# Must have easier acces to opt_f

	# GMT is not able to return a converted time table, so we create a temporary file if time conversions are involved
	used_tmp_file = false
	if (contains(opt_f, "-fo") && is_in_dict(d, [:write :savefile :|>]) === nothing)
		s = split(opt_f)[end]
		if (contains(s, 'T') || contains(s, 't'))
			fname = TMPDIR_USR.dir * "/" * "GMTjl_time_" * TMPDIR_USR.username * TMPDIR_USR.pid_suffix * ".txt"
			d[:write] = fname
			used_tmp_file = true
		end
	end

	cmd = parse_write(d, cmd)
	cmd  = parse_these_opts(cmd, d, [[:A :hcat], [:C :n_records], [:D :dump], [:E :first_last], [:F :conn_method],
	                                 [:I :invert :reverse], [:L :list_only], [:N :sort], [:Q :segments], [:S :select_hdr], [:T :suppress :skip], [:W :word2num], [:Z :transpose]])


	out = common_grd(d, cmd0, cmd, "gmtconvert ", arg1)		# Finish build cmd and run it
	if (used_tmp_file)			# Read the conversion results and clean up temporary file.
		out = gmtread(fname)
		rm(fname, force=true)
	else
		(!contains(cmd, " -b") && isa(out, GDtype) && cmd0 != "" && guess_T_from_ext(cmd0) == " -Td") && file_has_time!(cmd0, out)  # Try to guess if time columns
	end
	return out
end
