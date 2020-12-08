"""
	gmtwhich(cmd0::String; kwargs...)

Find full path to specified files

Full option list at [`gmtwhich`]($(GMTdoc)gmtwhich.html)

Parameters
----------

- **A** | **with_permissions** :: [Type => Bool]

	Only consider files that the user has permission to read [Default consider all files found].
    ($(GMTdoc)gmtwhich.html#a)
- **C** | **confirm** :: [Type => Bool]

	Instead of reporting the paths, print the confirmation Y if the file is found and N if it is not.
    ($(GMTdoc)gmtwhich.html#c)
- **D** | **report_dir** :: [Type => Bool]

	Instead of reporting the paths, print the directories that contains the files.
    ($(GMTdoc)gmtwhich.html#d)
- **G** | **download** :: [Type => Str | []]      ``Arg = [c|l|u]``

	If a file argument is a downloadable file (either a full URL, a @file for downloading from
	the GMT Site Cache, or @earth_relief_*.grd) we will try to download the file if it is not
	found in your local data or cache dirs.
    ($(GMTdoc)gmtwhich.html#g)
- $(GMT.opt_V)
"""
function gmtwhich(cmd0::String; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("gmtwhich", cmd0)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	cmd = parse_V_params(d, "")
    cmd = parse_these_opts(cmd, d, [[:A :with_permissions], [:C :confirm], [:D :report_dir], [:G :download]])

	common_grd(d, cmd0, cmd, "gmtwhich ", nothing)		# Finish build cmd and run it
end
