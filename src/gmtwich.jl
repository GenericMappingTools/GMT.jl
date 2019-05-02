"""
	gmtwhich(cmd0::String; kwargs...)

Find full path to specified files

Full option list at [`gmtwhich`](http://gmt.soest.hawaii.edu/doc/latest/gmtwhich.html)

Parameters
----------

- **A** : **with_permissions** : -- Bool or [] --

	Only consider files that the user has permission to read [Default consider all files found].
	[`-A`](http://gmt.soest.hawaii.edu/doc/latest/gmtwhich.html#a)
- **C** : **confirm** : -- Bool or [] --

	Instead of reporting the paths, print the confirmation Y if the file is found and N if it is not.
	[`-C`](http://gmt.soest.hawaii.edu/doc/latest/gmtwhich.html#c)
- **D** : **report_dir** : -- Bool or [] --

	Instead of reporting the paths, print the directories that contains the files.
	[`-D`](http://gmt.soest.hawaii.edu/doc/latest/gmtwhich.html#d)
- **G** : **download** : -- Str or [] --      Flags = [c|l|u]

	If a file argument is a downloadable file (either a full URL, a @file for downloading from
	the GMT Site Cache, or @earth_relief_*.grd) we will try to download the file if it is not
	found in your local data or cache dirs.
	[`-G`](http://gmt.soest.hawaii.edu/doc/latest/gmtwhich.html#g)
- $(GMT.opt_V)
"""
function gmtwhich(cmd0::String; kwargs...)

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("gmtwhich", cmd0)

	d = KW(kwargs)
	cmd = parse_V_params("", d)
    cmd = parse_these_opts(cmd, d, [[:A :with_permissions], [:C :confirm], [:D :report_dir], [:G :download]])

	common_grd(d, cmd0, cmd, "gmtwhich ", nothing)		# Finish build cmd and run it
end
