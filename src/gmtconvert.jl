"""
Convert, Paste, and/or Extract columns from data tables

To see the documentation, type: ``@? gmtconvert``
"""
gmtconvert(cmd0::String; kwargs...) = gmtconvert_helper(cmd0, nothing; kwargs...)
gmtconvert(arg1; kwargs...)         = gmtconvert_helper("", arg1; kwargs...)
function gmtconvert_helper(cmd0::String, arg1; kwargs...)
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	gmtconvert_helper(wrapDatasets(cmd0, arg1), d)
end

# ---------------------------------------------------------------------------------------------------
function gmtconvert_helper(w::wrapDatasets, d::Dict{Symbol,Any})
	cmd0, arg1 = unwrapDatasets(w::wrapDatasets)

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
