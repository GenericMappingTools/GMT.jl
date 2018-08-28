"""
	gmtwich(cmd0::String="", arg1=[], kwargs...)

Time domain filtering of 1-D data tables.

Full option list at [`gmtwich`](http://gmt.soest.hawaii.edu/doc/latest/gmtwich.html)

Parameters
----------

- **A** : **with_permissions** : -- Bool or [] --

    Only consider files that the user has permission to read [Default consider all files found].
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/gmtwich.html#a)
- **C** : **confirm** : -- Bool or [] --

    Instead of reporting the paths, print the confirmation Y if the file is found and N if it is not.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/gmtwich.html#c)
- **D** : **report_dir** : -- Bool or [] --

    Instead of reporting the paths, print the directories that contains the files.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/gmtwich.html#d)
- **G** : **download** : -- Str or [] --      Flags = [c|l|u]

    If a file argument is a downloadable file (either a full URL, a @file for downloading from
    the GMT Site Cache, or @earth_relief_*.grd) we will try to download the file if it is not
    found in your local data or cache dirs.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/gmtwich.html#g)
- $(GMT.opt_V)
"""
function gmtwich(cmd0::String="", arg1=[]; kwargs...)

	length(kwargs) == 0 && return monolitic("gmtwich", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	cmd = parse_V_params("", d)

    cmd = add_opt(cmd, 'A', d, [:A :with_permissions])
    cmd = add_opt(cmd, 'C', d, [:C :confirm])
	cmd = add_opt(cmd, 'D', d, [:D :report_dir])
	cmd = add_opt(cmd, 'G', d, [:G :download])

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)
	return common_grd(d, cmd, got_fname, 1, "gmtwich", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
gmtwich(arg1=[], cmd0::String=""; kw...) = gmtwich(cmd0, arg1; kw...)