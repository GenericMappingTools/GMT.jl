const psxy  = plot
const psxy! = plot!
const psxyz  = plot3d
const psxyz! = plot3d!

# ---------------------------------------------------------------------------------------------------
# All this annoying tricks with multiple tinny methods is to avoid the very sad fact that Julia
# RECOMPLILES EVERY TIME we use a new arg in kwargs or EVEN WHEN THEY ARE USED IN DIFFERENT ORDER.
# So, we now pass only a Dict of kwargs. The recompilations still happen, but over the tinny method.
# The risk of this is if the calling function is not expectiong the 'd' Dict to be modified.
function common_plot_xyz(cmd0::String, arg1, caller::String, first::Bool, is3D::Bool; kwargs...)
	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode
	_common_plot_xyz(cmd0, arg1, caller, O, K, is3D, d)
end
function common_plot_xyz(cmd0::String, arg1, caller::String, first::Bool, is3D::Bool, d)
	_common_plot_xyz(cmd0, arg1, caller, !first, true, is3D, d)
end
function _common_plot_xyz(cmd0::String, arg1, caller::String, O::Bool, K::Bool, is3D::Bool, d::Dict)
	first = !O
	(cmd0 != "" && arg1 === nothing && is_in_dict(d, [:groupvar :hue]) !== nothing) && (arg1 = gmtread(cmd0); cmd0 = "")
	(caller != "bar") && (arg1 = if_multicols(d, arg1, is3D))	# Check if it was asked to split a GMTdataset in its columns 

	arg2, arg3, arg4 = nothing, nothing, nothing
	N_args::Int = (arg1 === nothing) ? 0 : 1
	is_ternary = (caller == "ternary") ? true : false
	if     (is3D)       gmt_proggy = (IamModern[1]) ? "plot3d "  : "psxyz "
	elseif (is_ternary) gmt_proggy = (IamModern[1]) ? "ternary " : "psternary "
	else		        gmt_proggy = (IamModern[1]) ? "plot "    : "psxy "
	end

	# ------------- Parse whose caller and some other initializations
	cmd, isFV, caller, sub_module, gmt_proggy, opt_A, g_bar_fill, arg1 = parse_plot_callers(d, gmt_proggy, caller, is3D, O, arg1)

	# --------------------- Check the grid2tri cases --------------------
	cmd, is_gridtri, arg1 = parse_grid2tri_case(d, cmd, caller, is3D, isFV, O, arg1)
	
	isa(arg1, GMTdataset) && (arg1 = with_xyvar(d, arg1))		# See if we have a column request based on column names
	if ((val = hlp_desnany_int(d, [:decimate])) !== -999)		# Asked for a clever data decimation?
		dec_factor::Int = (val == 1) ? 10 : val
		arg1 = lttb(arg1, dec_factor)
	end

	parse_paper(d)				# See if user asked to temporarily pass into paper mode coordinates

	if (is_ternary)
		opt_B::String = ""
		if (haskey(d, :B))						# Not necessarely the case when ternary!
			cmd, opt_B = string(cmd, d[:B]), d[:B]		# B option was parsed in plot/ternary
			delete!(d, :B)
		end
		cmd, opt_R = parse_R(d, cmd, O=O)
	end

	if (is_ternary && !first) 	# Either a -J was set and we'll fish it here or no and we'll use the default.
		def_J = " -JX" * split(DEF_FIG_SIZE, '/')[1]
		cmd, opt_J::String = parse_J(d, cmd, default=def_J)
	else
		def_J = (is_ternary) ? " -JX" * split(DEF_FIG_SIZE, '/')[1] : ""		# Gives "-JX15c" 
		@inbounds (!is_ternary && isa(arg1, GMTdataset) && length(arg1.ds_bbox) >= 4) && (CTRL.limits[1:4] = arg1.ds_bbox[1:4])
		@inbounds (!is_ternary && isa(arg1, Vector{<:GMTdataset}) && length(arg1[1].ds_bbox) >= 4) && (CTRL.limits[1:4] = arg1[1].ds_bbox[1:4])
		(!is_ternary && CTRL.limits[7:10] == [0,0,0,0]) && (CTRL.limits[7:10] = CTRL.limits[1:4])	# Start with plot=data limits
		(!IamModern[1] && haskey(d, :hexbin) && !haskey(d, :aspect)) && (d[:aspect] = :equal)	# Otherwise ... gaps between hexagons
		(isa(arg1, GMTdataset) && size(arg1,2) > 1 && !isempty(arg1.colnames)) && (CTRL.XYlabels[1] = arg1.colnames[1]; CTRL.XYlabels[2] = arg1.colnames[2])
		isa(arg1, Vector{<:GMTdataset}) && !isempty(arg1[1].colnames) && (CTRL.XYlabels[1] = arg1[1].colnames[1]; CTRL.XYlabels[2] = arg1[1].colnames[2])
		if (is_ternary)  cmd, opt_J = parse_J(d, cmd, default=def_J)
		else             cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd, caller, O, def_J)
		end
		# Current parse_B does not add a default -Baz when 3D AND -J has a projection. More or less fix that.
		if (is3D && opt_B != "" && !contains(opt_B, " -Bz"))
			opt_B_copy = opt_B
			opt_B = replace(opt_B, " -BWSen" => "") * " -Bza"	# Remove the " -BWSen" and add " -Bza"
			cmd = replace(cmd, opt_B_copy => opt_B);
		end
	end

	axis_equal = is_axis_equal(d)		# See if the user asked for an equal aspect ratio
	cmd, opt_JZ = parse_JZ(d, cmd; O=O, is3D=is3D)
	cmd, = parse_common_opts(d, cmd, [:a :e :f :g :t :w :margin :params]; first=first)
	cmd, opt_l = parse_l(d, cmd)		# Parse this one (legend) aside so we can use it in classic mode
	cmd, opt_f = parse_f(d, cmd)		# Parse this one (-f) aside so we can check against D.attrib
	cmd  = parse_these_opts(cmd, d, [[:D :shift :offset], [:I :intens], [:N :no_clip :noclip], [:T]])
	parse_ls_code!(d::Dict)				# Check for linestyle codes (must be before the GMTsyntax_opt() call)
	cmd  = GMTsyntax_opt(d, cmd)[1]		# See if an hardcore GMT syntax string has been passed by mk_styled_line!
	(is_ternary) && (cmd = add_opt(d, cmd, "M", [:M :dump]))
	opt_UVXY = parse_UVXY(d, "")		# Need it separate to not risk to double include it.
	cmd, opt_c = parse_c(d, cmd)		# Need opt_c because we may need to remove it from double calls

	if (isa(arg1, GDtype) && !contains(opt_f, "T") && !contains(opt_f, "t") && !contains(opt_R, "T") && !contains(opt_R, "t"))
		cmd = isa(arg1, GMTdataset) ? set_fT(arg1, cmd, opt_f) : set_fT(arg1[1], cmd, opt_f)
	end

	# If a file name sent in, read it and compute a tight -R if this was not provided
	got_usr_R = (opt_R != "") ? true : false			# To know if the user set -R or we estimated it from data
	(opt_R == "" && sub_module == "bar") && (opt_R = "/-0.4/0.4/0")		# Make sure y_min = 0
	if (O && caller == "plotyy")
		cmd = replace(cmd, opt_R => "")					# Must remove old opt_R because a new one will be constructed
		ind = collect(findall("/", BOX_STR[1])[2])		# 'BOX_STR' was set in first call
		opt_R = '/' * BOX_STR[1][4:ind[1]] * "?/?"		# Will become /x_min/x_max/?/?
	end

	cmd, arg1, opt_R, _, opt_i = read_data(d, cmd0, cmd, arg1, opt_R, is3D)

	# We still need to set the right -JZ when the aspect is set to :equal (or :data). We couldn't do it
	# before because only after parsing -R we know the full 3 sides sizes
	if (is3D && axis_equal)
		cmd, opt_JZ = refine_JZ(cmd, opt_JZ)
	end

	(cmd0 != "" && isa(arg1, GMTdataset)) && (arg1 = with_xyvar(d, arg1))	# If we read a file, see if requested cols
	(!got_usr_R && opt_R != "") && (CTRL.pocket_R[1] = opt_R)	# Still on time to store it.
	(N_args == 0 && arg1 !== nothing) && (N_args = 1)	# arg1 might have started as nothing and got values above
	(!O && caller == "plotyy") && (BOX_STR[1] = opt_R)	# This needs modifications (in plotyy) by second call

	check_grouping!(d, arg1)			# See about request to do row groupings (and legends for that case)

	if (isGMTdataset(arg1) && !isTimecol_in_pltcols(arg1) && getproj(arg1, proj4=true) != "" && opt_J == " -JX" * DEF_FIG_SIZE)
		cmd = replace(cmd, opt_J => " -JX" * split(DEF_FIG_SIZE, '/')[1] * "/0")	# If projected, it's a axis equal for sure
	end
	if (is3D && isempty(opt_JZ) && length(collect(eachmatch(r"/", opt_R))) == 5)
		if (O) opt_JZ = (CTRL.pocket_J[3] != "") ? CTRL.pocket_J[3][1:4] : " -JZ"
		else   opt_JZ = CTRL.pocket_J[3] = (is_gridtri) ? " -JZ5c" : " -JZ6c"		# Arbitrary and not satisfactory for all cases.
		end
		cmd *= opt_JZ		# Default -JZ
	end

	# Here we check for a direct -A of and indirect via the stairs module.
	cmd = add_opt(d, cmd, "A", [:A :steps :stairs :straight_lines], (x="x", y="y", meridian="m", parallel="p", r="r", theta="t"))
	if (!contains(cmd, " -A") && opt_A != "")	# When the caller is "stairs" 
		if (opt_A == "post")  cmd *= CTRL.proj_linear[1] ? " -Ax" : " -Ap"	# Still leaves out the Polar case
		else                  cmd *= CTRL.proj_linear[1] ? " -Ay" : " -Am"
		end
	end

	opt_F::String = add_opt(d, "", "", [:F :conn :connection],
	                (continuous=("c", nothing, 1), net=("n", nothing, 1), network=("n", nothing, 1), refpoint=("p", nothing, 1),  ignore_hdr="_a", single_group="_f", segments="_s", segments_reset="_r", anchor=("", arg2str)))
	(opt_F != "" && !occursin("/", opt_F)) && (opt_F = string(opt_F[1]))	# Allow con=:net or con=(1,2)
	(opt_F != "") && (cmd *= " -F" * opt_F)

	# --------------------- Error Bars? --------------------------------
	cmd, got_Ebars, arg1 = parse_Ebars(d, cmd, arg1)

	# ----------------- Look for color request. Do it after error bars because they may add a column
	len_cmd = length(cmd);	n_prev = N_args;
	cmd, N_args, do_Z_fill, got_Zvars, do_Z_outline, arg1, arg2 = parse_color_request(d, cmd, N_args, arg1, arg2)	

	in_bag = (got_Zvars || haskey(d, :hexbin)) ? true : false		# Other cases should add to this list
	opt_T::String = (haskey(d, :hexbin)) ? @sprintf(" -T%s/%s/%d+n",arg1.bbox[5], arg1.bbox[6], 65) : ""
	if (N_args < 2)
		cmd, arg1, arg2, N_args = add_opt_cpt(d, cmd, CPTaliases, 'C', N_args, arg1, arg2, true, true, opt_T, in_bag)
	else			# Here we know that both arg1 & arg2 are already occupied, so must use arg3 only
		cmd, arg3, = add_opt_cpt(d, cmd, CPTaliases, 'C', 0, arg3, nothing, true, true, opt_T, in_bag)
		N_args = 3
	end

	# Need to parse -W here because we need to know if the call to make_color_column() MUST be avoided. 
	opt_W::String = add_opt_pen(d, [:W :pen], opt="W")
	arg1, opt_W, got_color_line_grad, made_it_vector = helper_psxy_line(d, cmd, opt_W, is3D, arg1, arg2, arg3)

	isa(arg1, GDtype) && (arg1, cmd = check_ribbon(d, arg1, cmd, opt_W))	# Do this check here, after -W is known and before parsing -G & -L

	mcc, bar_ok = false, (sub_module == "bar" && !check_bar_group(arg1))
	if (!got_color_line_grad && !is_gridtri && (arg1 !== nothing && !isa(arg1, GMTcpt)) && ((!got_Zvars && !is_ternary) || bar_ok))
		# If "bar" ONLY if not bar-group
		# See if we got a CPT. If yes there may be some work to do if no color column provided in input data.
		cmd, arg1, arg2, N_args, mcc = make_color_column(d, cmd, opt_i, len_cmd, N_args, n_prev, is3D,
		                                                 got_Ebars, bar_ok, g_bar_fill, arg1, arg2)
	end

	cmd, opt_G, opt_Gsymb, opt_L = parse_plot_G_L(d, cmd, g_bar_fill, is_ternary)

	if ((val = find_in_dict(d, [:decorated])[1]) !== nothing)
		cmd = (isa(val, String)) ? cmd * " " * val : cmd * decorated(val)
		if (occursin("~f:", cmd) || occursin("qf:", cmd))	# Here we know val is a NT and `locations` was numeric
			_, arg1, arg2, arg3 = arg_in_slot(nt2dict(val), "", [:locations], GDtype, arg1, arg2, arg3)
		end
	end

	opt_Wmarker::String = ""
	if ((tmec = hlp_desnany_arg2str(d, [:mec :markeredgecolor :MarkerEdgeColor])) !== "")
		!contains(tmec, "p,") && (tmec = "0.25p," * tmec)	# If not provided, default to a line thickness of 0.25p
		opt_Wmarker = tmec
	end

	# This bit is for the -Z option. Must consolidate the options.
	(do_Z_fill && opt_G == "") && (cmd *= " -G+z")
	(do_Z_outline && !contains(opt_W, "+z")) && (opt_W = (opt_W == "") ? " -W0.5+z" : opt_W * "+z")
	(got_Zvars && !do_Z_fill && !do_Z_outline && opt_W == "") && (opt_W = " -W0.5+z")	# Nofill and nothing else defaults to -W+z
	(got_Zvars && (do_Z_fill || opt_G != "") && opt_L == "") && (cmd *= " -L")	# GMT requires -L when -Z fill or -G

	if ((do_Z_fill || do_Z_outline || (got_color_line_grad && !is3D)) && !occursin("-C", cmd))
		if (isempty(CURRENT_CPT[1]))
			if (got_color_line_grad)		# Use the fact that we have min/max already stored
				mima::Vector{Float64} = (arg1.ds_bbox[5+2*is3D]::Float64, arg1.ds_bbox[6+2*is3D]::Float64)
			else
				mima = [extrema(last_non_nothing(arg1, arg2, arg3))...]	# Why 'last'?
			end
			r = makecpt(@sprintf("-T%f/%f/65+n -Cturbo -Vq", mima[1]-eps(1e10), mima[2]+eps(1e10)))
		else
			r = CURRENT_CPT[1]
		end
		(arg1 === nothing) ? arg1 = r : ((arg2 === nothing) ? arg2 = r : (arg3 === nothing ? arg3 = r : arg4 = r))
		cmd *= " -C"
	end

	arg1, opt_S = parse_opt_S(d, arg1, is3D)
	if (opt_S == "" && isa(arg1, GDtype) && !contains(cmd, " -S"))	# Let datasets with point/multipoint geometries plot points
		geom::Int = isa(arg1, Vector) ? arg1[1].geom : arg1.geom
		((geom == wkbPoint || geom == wkbMultiPoint) && caller != "bar") && (opt_S = " -Sp2p")
	end

	opt_ML::String = ""
	if (opt_S != "")
		opt_ML, opt_Wmarker = parse_markerline(d, opt_ML, opt_Wmarker)
	end
	(made_it_vector && opt_S == "") && (cmd *= " -Sv+s")	# No set opt_S because it results in 2 separate commands

	# See if any of the scatter, bar, lines, etc... was the caller and if yes, set sensible defaults.
	_cmd = set_avatar_defaults(d, cmd, mcc, caller, got_usr_R, opt_B, opt_Gsymb, opt_ML, opt_R, opt_S, opt_W, sub_module, g_bar_fill, opt_Wmarker, opt_UVXY, opt_c, O, arg1)

	(got_Zvars && opt_S == "" && opt_W == "" && !occursin(" -G", _cmd[1])) && (_cmd[1] *= " -W0.5")
	(opt_W == "" && caller == "feather") && (_cmd[1] *= " -W0.1")		# feathers are normally many so better they are thin

	# Let matrices with more data columns, and for which Color info was NOT set, plot multiple lines at once
	if (!mcc && sub_module == "bar" && check_bar_group(arg1))	# !mcc because the bar-groups all have mcc = false
		_cmd[1], arg1, cmd2::String = bar_group(d, _cmd[1], opt_R, g_bar_fill, got_Ebars, got_usr_R, arg1)
		(cmd2 != "") && (length(_cmd) == 1 ? (_cmd = [cmd2; _cmd[1]]) :
			(@warn("Can't plot the connector when 'bar' is already a nested call."); CTRL.pocket_call[3] = nothing))
	end

	(!IamModern[1]) && put_in_legend_bag(d, _cmd, arg1, O, opt_l)

	_cmd = gmt_proggy .* _cmd				# In any case we need this
	_cmd = frame_opaque(_cmd, opt_B, opt_R, opt_J, opt_JZ)	# No -t in -B
	(haskey(d, :inset)) && (CTRL.pocket_call[4] = arg1)		# If 'inset', it may be needed from next call
	_cmd = finish_PS_nested(d, _cmd)						# If we have an 'inset', this makes a long tour plotting that inset.

	# If we have a zoom inset call must plot the zoom rectangle and lines connecting it to the inset window.
	if ((ind = findfirst(startswith.(_cmd, "inset_"))) !== nothing)	# inset commands must be the last ones
		ins = popat!(_cmd, ind)		# Remove the 'inset' command
		append!(_cmd, [ins])		# and add it at the end
	end
	if (startswith(_cmd[end], "inset_") && isa(CTRL.pocket_call[4], String))
		_cmd = zoom_reactangle(_cmd, true)
	end

	_cmd = fish_bg(d, _cmd)					# See if we have a "pre-command"
	_cmd = fish_pagebg(d, _cmd, autoJZ=(is3D && axis_equal))	# Last arg tells if JZ was computed automatically

	isa(arg1, GDtype) && plt_txt_attrib!(arg1, d, _cmd)			# Function barrier to plot TEXT attributed labels (in case)

	finish = (is_ternary && occursin(" -M",_cmd[1])) ? false : true		# But this case (-M) is bugged still in 6.2.0
	R = prep_and_call_finish_PS_module(d, _cmd, "", K, O, finish, arg1, arg2, arg3, arg4)
	LEGEND_TYPE[1].Vd = 0					# Because for nested calls with legends this was still > 0, which screwed later
	CTRL.pocket_d[1] = d					# Store d that may be not empty with members to use in other modules
	(opt_B == " -B") && gmt_restart()		# For some Fking mysterious reason (see Ex45)
	return R
end

# ---------------------------------------------------------------------------------------------------
# If the input is a GMTdataset and one of its columns is a Time column, automatically set the -fT
function set_fT(D::GMTdataset{T,N}, cmd::String, opt_f::String)::String where {T,N}
	if ((Tc = get(D.attrib, "Timecol", "")) != "")
		tc::Int = parse(Int, Tc) - 1
		_opt_f = (opt_f == "") ? " -f$(tc)T" : opt_f * ",$(tc)T"
		((Tc = get(D.attrib, "Time_epoch", ""))  != "") && (_opt_f *= " --TIME_EPOCH=$(Tc)")	# If other than Unix time
		((Tc = get(D.attrib, "Time_unit", ""))   != "") && (_opt_f *= " --TIME_UNIT=$(Tc)")
		((Tc = get(D.attrib, "Time_system", "")) != "") && (_opt_f *= " --TIME_SYSTEM=$(Tc)")
		return (opt_f == "") ? cmd * _opt_f : replace(cmd, opt_f => _opt_f)
	end
	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_grid2tri_case(d, cmd, caller, is3D, isFV, O, arg1)
	is_gridtri::Bool = false
	is3D && (is_gridtri = deal_gridtri!(arg1, d, O))

	if (!O && occursin('3', caller) && is_in_dict(d, [:p :view :perspective]) === nothing)
		d[:p] = "217.5/30"			# Need this before parse_BJR() so MAP_FRAME_AXES can be guessed.
		CURRENT_VIEW[1] = " -p217.5/30"
	end
	cmd, opt_p = parse_p(d, cmd)	# Parse this one (view angle) aside so we can use it to remove invisible faces (3D)
	(opt_p == "" && !is3D && !O) && (CURRENT_VIEW[1] = "")	# Make sure it empty under these conditions
	(opt_p == "") ? (opt_p = CURRENT_VIEW[1]; cmd *= opt_p)	: (CURRENT_VIEW[1] = opt_p) # Save for eventual use in other modules.

	if (is3D && isFV)				# case of 3D faces
		arg1 = (is_in_dict(d, [:replicate]) !== nothing) ? replicant(arg1, d) : deal_faceverts(arg1, d; del=find_in_dict(d, [:nocull])[1] === nothing)
		(!O && !haskey(d, :aspect3) && is_in_dict(d, [:JZ :Jz :zsize :zscale]) === nothing && !isgeog(arg1)) && (d[:aspect3] = "equal")
		(!O && !haskey(d, :aspect3) && isgeog(arg1)) && (d[:aspect] = "equal")
	elseif (is_gridtri)
		arg1 = sort_visible_triangles(arg1)
		is_in_dict(d, [:Z :level :levels]) === nothing && (d[:Z] = tri_z(arg1))
	end
	return cmd, is_gridtri, arg1
end

# ---------------------------------------------------------------------------------------------------
function parse_Ebars(d::Dict{Symbol, Any}, cmd::String, arg1)
	got_Ebars = false
	val, symb = find_in_dict(d, [:E :error :errorbars :error_bars], false)
	if (val !== nothing)
		if isa(val, String)
			cmd::String *= " -E" * val
		else
			_mat = (arg1 === nothing) ? arg1 : isa(arg1, GMTdataset) ? arg1.data : arg1[1].data
			cmd, mat_t = add_opt(add_opt, (d, cmd, "E", [symb]),
			                     (x="|x",y="|y",xy="|xy",X="|X",Y="|Y", asym="_+a", colored="_+c", cline="_+cl", csymbol="_+cf", notch="|+n", boxwidth="+w", cap="+w", pen=("+p",add_opt_pen)), false, _mat)
			(arg1 !== nothing) && (isa(arg1, GMTdataset) ? (arg1.data = mat_t; append!(arg1.colnames, ["Ebar"])) :
			                       (arg1[1].data = mat_t; append!(arg1[1].colnames, ["Ebar"])))
		end
		got_Ebars = true
		delete!(d, [symb])
	end
	return cmd, got_Ebars, arg1
end

# ---------------------------------------------------------------------------------------------------
function parse_color_request(d::Dict{Symbol, Any}, cmd::String, N_args::Int, arg1, arg2)
	opt_Z, args, n, got_Zvars = add_opt(d, "", "Z", [:Z :level :levels], :data, Any[arg1, arg2], (outline="_o", nofill="_f"))
	(opt_Z == " -Z" && n == 0) && error("The 'level' option (Z) must be set a single value, a file name or a vector os reals.")
	if (isa(arg1, Vector{<:GMTdataset}) && ((ind_att = findfirst('=', opt_Z)) !== nothing))
		# Here we deal with the case where the -Z option refers to a particular attribute.
		# Allow to use "Z=(data="att=XXXX", nofill=true)" when the Di are polygons.
		last_ind, got_extra = length(opt_Z), false
		(opt_Z[end] == 'f' || opt_Z[end] == 'o') && (last_ind -= 1; got_extra = true)
		arg2 = parse.(Float64, make_attrtbl(arg1, att=opt_Z[ind_att+1:last_ind])[1])
		opt_Z = (got_extra) ? " -Z" * opt_Z[end] : ((arg1[1].geom == wkbLineString || arg1[1].geom == wkbLineString) ? " -Zf" : " -Z")
		N_args = 2
	end
	if (contains(opt_Z, "f") && !contains(opt_Z, "o"))	# Short version. If no fill it must outline otherwise nothing
		do_Z_fill, do_Z_outline = false, true;		opt_Z = replace(opt_Z, "f" => "")
	else
		(!contains(opt_Z, "f")) ? do_Z_fill = true : (do_Z_fill = false; opt_Z = replace(opt_Z, "f" => ""))
		(contains(opt_Z, "o")) ? (do_Z_outline = true; opt_Z = replace(opt_Z, "o" => "")) : (do_Z_outline = false)
	end
	(opt_Z != "") && (cmd *= opt_Z)
	(!got_Zvars) && (do_Z_fill = do_Z_outline = false)	# Because they may have wrongly been set above

	if (n > 0)
		arg1, arg2 = args[:]
		N_args = n
	end
	return cmd, N_args, do_Z_fill, got_Zvars, do_Z_outline, arg1, arg2
end

# ---------------------------------------------------------------------------------------------------
function set_avatar_defaults(d, cmd, mcc, caller, got_usr_R, opt_B, opt_Gsymb, opt_ML, opt_R, opt_S, opt_W, sub_module, g_bar_fill, opt_Wmarker, opt_UVXY, opt_c, O, arg1)::Vector{String}
	cmd  = check_caller(d, cmd, opt_S, opt_W, sub_module, g_bar_fill, O)
	(mcc && caller == "bar" && !got_usr_R && opt_R != " -R") && (cmd = recompute_R_4bars!(cmd, opt_R, arg1))	# Often needed
	_cmd = build_run_cmd(cmd, opt_B, opt_Gsymb, opt_ML, opt_S, opt_W, opt_Wmarker, opt_UVXY, opt_c)
	return _cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_plot_G_L(d::Dict{Symbol, Any}, cmd::String, g_bar_fill::Vector{String}, is_ternary::Bool)
	opt_G::String = ""
	if (isempty(g_bar_fill))					# Otherwise bar fill colors are dealt with somewhere else
		((opt_G = add_opt_fill("", d, [:G :fill], 'G')) != "") && (cmd *= opt_G)	# Also keep track if -G was set
	end
	opt_Gsymb::String = add_opt_fill("", d, [:G :mc :markercolor :markerfacecolor :MarkerFaceColor], 'G')	# Filling of symbols
	(opt_Gsymb == " -G") && (opt_Gsymb *= "black")	# Means something like 'mc=true' was used, but we need a color

	opt_L::String = ""
	if (is_ternary)				# Means we are in the psternary mode
		cmd = add_opt(d, cmd, "L", [:L :vertex_labels])
	else
		opt_L = add_opt(d, "", "L", [:L :close :polygon],
		                (left="_+xl", right="_+xr", x0="+x", bot="_+yb", top="_+yt", y0="+y", sym="_+d", asym="_+D", envelope="_+b", pen=("+p",add_opt_pen)))
		(length(opt_L) > 3 && !occursin("-G", cmd) && !occursin("+p", cmd)) && (opt_L *= "+p0.5p")
		cmd *= opt_L
	end
	return cmd, opt_G, opt_Gsymb, opt_L
end

# ---------------------------------------------------------------------------------------------------
function parse_plot_callers(d::Dict{Symbol, Any}, gmt_proggy::String, caller::String, is3D::Bool, O::Bool, arg1)
	isFV = (isa(arg1, GMTfv) || isa(arg1, Vector{GMTfv}))
	(arg1 !== nothing && !isa(arg1, GDtype) && !isa(arg1, Matrix{<:Real}) && !isFV) &&
		(arg1 = tabletypes2ds(arg1, ((val = hlp_desnany_int(d, [:interp])) !== -999) ? interp=val : interp=0))
	(caller != "bar") && (arg1 = if_multicols(d, arg1, is3D))	# Repeat because DataFrames or ODE's have skipped first round
	(!O) && (LEGEND_TYPE[1] = legend_bag())		# Make sure that we always start with an empty one

	cmd::String = "";	sub_module::String = ""	# Will change to "scatter", etc... if called by sub-modules
	opt_A::String = ""							# For the case the caller was in fact "stairs"
	g_bar_fill = Vector{String}()				# May hold a sequence of colors for gtroup Bar plots
	if (caller != "")
		if (occursin(" -", caller))				# some sub-modues use this piggy-backed call to send a cmd
			if ((ind = findfirst('|', caller)) !== nothing)	# A mixed case with "caler|partiall_command"
				_ind::Int = Int(ind)			# Because it still F. insists that 'ind' is a Any
				sub_module = caller[1:_ind-1]
				cmd = caller[_ind+1:end]
				caller = sub_module				# Because of parse_BJR()
				(caller == "events") && (gmt_proggy = "events ")
			else
				cmd = caller
				caller = "others"				# It was piggy-backed
			end
		else
			sub_module = caller
			# Needs to be processed here to distinguish from the more general 'fill'
			(caller == "bar") && (g_bar_fill = helper_gbar_fill(d))
			opt_A = (caller == "lines" && ((val = hlp_desnany_str(d, [:stairs_step])) !== "")) ? val : ""
		end
	end
	return cmd, isFV, caller, sub_module, gmt_proggy, opt_A, g_bar_fill, arg1
end

# ---------------------------------------------------------------------------------------------------
plt_txt_attrib!(D::GMTdataset{T,N}, d::Dict{Symbol, Any}, _cmd::Vector{String}) where {T,N} = plt_txt_attrib!([D], d, _cmd)
function plt_txt_attrib!(D::Vector{<:GMTdataset{T,N}}, d::Dict{Symbol, Any}, _cmd::Vector{String}) where {T,N}
	# Plot TEXT attributed labels and serve as function barrier agains the f Any's (not sure if succeeds)
	((s_val = hlp_desnany_str(d, [:labels])) === "") && return nothing
		
	if ((fnt = add_opt(d, "", "", [:font], (angle="+a", font=("+f", font)); del=false)) !== "")
		(fnt[1] != '+') && (fnt = "+f" * fnt)
		delete!(d, :font)
	end

	if (length(D) == 1 && D[1].geom == wkbPoint)	# Points only. Expected to have a text column
		(CTRL.pocket_call[1] === nothing) ? (CTRL.pocket_call[1] = D[1]) : (CTRL.pocket_call[2] = D[1])
		(fnt === "") && (fnt = "+f6p")
	else
		ts = fish_attrib_in_str(s_val)
		t = vec(make_attrtbl(D, att=ts)[1])
		if (fnt === "")
			nc::Int = round(Int, sqrt(length(D)))				# A crude guess of the number of columns
			fnt = (nc < 5) ? "7p" : (nc < 9 ? "5p" : "4p")		# A simple heuristic
			outline = fnt * ",black=~0.75p,white "				# Apply the outline trick
			fnt = "+f"
			t = outline .* t
		end
		ct::GMTdataset{Float64,2} = mat2ds(gmt_centroid_area(G_API[1], D, Int(isgeog(D))), geom=wkbPoint)
		ct.text = t												# Texts will be plotted at the polygons centroids
		(CTRL.pocket_call[1] === nothing) ? (CTRL.pocket_call[1] = ct) : (CTRL.pocket_call[2] = ct)
	end
	append!(_cmd, ["pstext -R -J -F" * fnt * "+jMC"])
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function fish_attrib_in_str(s::String)::String
	# Fish the contents of 'labels="attrib=???"'
	!(startswith(s, "att") && (contains(s, '=') || contains(s, ':'))) &&
		error("The labels option must be 'labels=\"att=???\"' or 'labels=\"attrib=???\"'")
	((ind = findfirst('=', s)) === nothing) && (ind = findfirst(':', s))
	s[ind+1:end]
end

# ---------------------------------------------------------------------------------------------------
function get_numeric_view()::Tuple{Float64, Float64}
	isempty(CURRENT_VIEW[1]) && error("No perspective setting available yet (CURRENT_VIEW is empty)")
	spl = split(CURRENT_VIEW[1][4:end], '/')
	azim = parse(Float64, spl[1])
	elev = length(spl) > 1 ? parse(Float64, spl[2]) : 90.0
	return azim, elev
end

# ---------------------------------------------------------------------------------------------------
"""
    FV = deal_faceverts(FV::Union{GMTfv, Vector{GMTfv}}, d; del::Bool=true)::GMTfv
	
Deal with the situation where we are plotting 3D FV's.

Here we kill (if del==true) invisible faces and sort them according to the viewing angle. If no fill color is set in
kwargs, we use the dotprod and a gray CPT to set the fill color that will be modulated by normals to each visible face.
"""
function deal_faceverts(arg1, d; del::Bool=true)::Union{GMTfv, Vector{GMTfv}}
	azim, elev = get_numeric_view()
	arg1, dotprod = sort_visible_faces(arg1, azim, elev; del=del)	# Sort & kill (or not) invisible
	have_colors = (isa(arg1, GMTfv) && !isempty(arg1.color[1])) || (isa(arg1, Vector{GMTfv}) && !isempty(arg1[1].color[1]))
	if (is_in_dict(d, [:G :fill]) === nothing && !have_colors)		# If fill not set we use the dotprod and a gray CPT to set the fill
		is_in_dict(d, [:Z :level :levels]) === nothing && (d[:Z] = abs.(dotprod))
		(is_in_dict(d, CPTaliases) === nothing) && (d[:C] = gmt("makecpt -T0/1 -C140,220"))	# Users may still set a CPT
	end
	return arg1
end

# ---------------------------------------------------------------------------------------------------
function deal_gridtri!(arg1, d, O)::Bool
	# Deal with the situation where we are plotting triangulated grids made by grid2tri()
	!is_gridtri(arg1) && return false
	is_in_dict(d, [:G :fill]) === nothing && (d[:G] = "+z")
	if (is_in_dict(d, CPTaliases) === nothing)
		opt_T = (contains(arg1[1].comment[1], "vwall+gridtri_top")) ? "-T$(arg1[1].comment[2])/$(arg1[1].ds_bbox[6]+1e-8)/+n255" :
		        "-T$(arg1[1].ds_bbox[5]-1e-8)/$(arg1[1].ds_bbox[6]+1e-8)/+n255"
		C = gmt("makecpt -Cturbo " * opt_T)
		C.bfn[2, :] .= 0.7			# Set the foreground color used by the vertical wall
		d[:C] = C
	end
	(!O && !haskey(d, :aspect) && !haskey(d, :aspect3)) && (d[:aspect] = "equal")		# At least x,y axes should be data driven
	(is_in_dict(d, [:L :close :polygon]) === nothing) && (d[:L] = "")
	return true
end

# ---------------------------------------------------------------------------------------------------
function frame_opaque(cmd::Vector{String}, oB::String, oR::String, oJ::String, oJZ::String=""; bot::Bool=true)
	# Transparency affects the frame too, which is bad. So, if we have a transparency request we
	# plot the frame first with a call to basemap without -t.
	(!contains(cmd[1], " -t") || length(oB) < 3) && return cmd
	cmd[1] = replace(cmd[1], oB => "")		# Remove the -B's that would be hit by the transparency.
	oX, oY = scan_opt(cmd[1], "-X", true), scan_opt(cmd[1], "-Y", true)
	(oX != "") && (cmd[1] = replace(cmd[1], oX => ""))	# If we have a -X and/or -Y move them to the basemap cmd
	(oY != "") && (cmd[1] = replace(cmd[1], oY => ""))
	p = scan_opt(cmd[1], "-p", true)
	if bot		# Eventual grid will go UNDER the plot
		[(IamModern[1] ? "basemap" : "psbasemap") * " " * oB * " " * oR * " " * oJ * " " * oJZ * oX * oY * p; cmd]
	else		# Eventual grid will go ABOVE the image
		[cmd; (IamModern[1] ? "basemap" : "psbasemap") * " " * oB * " " * oR * " " * oJ * " " * oJZ * oX * oY * p]
	end
end

# ---------------------------------------------------------------------------------------------------
function if_multicols(d, arg1, is3D::Bool)
	# If the input is a GMTdataset and 'multicol' is asked, split the DS into a vector of DS's
	(!MULTI_COL[1] && is_in_dict(d, [:multi :multicol :multicols]) === nothing) && return arg1
	is3D && (delete!(d, [:multi, :multicol, :multicols]); @warn("'multile coluns' in 3D plots are not allowed. Ignoring."))
	(isdataframe(arg1) || isODE(arg1)) && return arg1
	(isa(arg1, Vector{<:GMTdataset}) && (size(arg1,2) > 2+is3D)) && return arg1		# Play safe
	d2 = copy(d)
	!haskey(d, :color) && (d2[:color] = true)	# Default to lines color cycling
	MULTI_COL[1] && (d2[:multi] = true)			# MULTI_COL was set in cat_2_arg2() when 2nd arg had 2 or more cols.
	arg1 = ds2ds(arg1; is3D=is3D, d2...)		# Pass a 'd' copy and remove possible kw that are also parsed in psxy
	delete!(d, [[:multi, :multicol, :multicols], [:lt, :linethick], [:ls, :linestyle], [:fill], [:fillalpha], [:color]])
	MULTI_COL[1] = false						# If it was true, its jobe is done.
	return arg1
end

# ---------------------------------------------------------------------------------------------------
function check_grouping!(d, arg1)
	# See about request to do row groupings. If yes, also set sensible defaults for a scatter plot
	# WARNING. If 'arg1' is a Vector{GMTdataset} then all elements are expected to have the same
	# number of rows but no testing of that is done.

	if (isa(arg1, GDtype))
		gidx, gnames = get_group_indices(d, arg1)
		if (!isempty(gidx))
			zcolor::Vector{Float64} = isa(arg1, Vector{<:GMTdataset}) ? zeros(size(arg1[1],1)::Int) : zeros(size(arg1,1)::Int)
			# Uggly because everything invalidates in this f language, dassss
			for k = 1:numel(gidx), n = 1:length(gidx[k])::Int  zcolor[gidx[k][n]] = k  end
			d[:zcolor] = zcolor
			if (is_in_dict(d, CPTaliases) === nothing)		# No -C provided, use defaults
				N::Int = length(gidx)
				d[:C] = (N <= 7) ? gmt("makecpt -D -T1/$N -C" * join(matlab_cycle_colors[1:N], ",")) :
				                   gmt("makecpt -D -T1/$N -C" * join(simple_distinct[1:N], ","))
			end
			(is_in_dict(d, [:marker, :Marker, :shape]) === nothing) && (d[:marker] = "circ")
			(is_in_dict(d, [:mec :markeredgecolor :MarkerEdgeColor]) === nothing) && (d[:mec] = "0.25p,black")
			(is_in_dict(d, [:ms :markersize :MarkerSize :size]) === nothing) && (d[:ms] = "5p")
			if (haskey(d, :legend))
				d[:label] = gnames
				d[:gindex] = [gidx[k][1] for k=1:numel(gidx)]	# For the legend
			end
		end
	end
	return nothing
end

# ---------------------------------------------------------------------------------------------------
function check_ribbon(d::Dict{Symbol, Any}, arg1::GMTdataset{T,N}, cmd::String, opt_W::String) where {T,N}
	((val = find_in_dict(d, [:ribbon :band])[1]) === nothing) && return arg1, cmd
	ec1, ec2, add_2 = helper_check_ribbon(val)		# Function barrier agains Anys
	(add_2) ? add2ds!(arg1, ec2; names=["Zbnd1","Zbnd2"]) : add2ds!(arg1, ec1; name="Zbnd")
	d[:L] = (add_2) ? "+D" : "+d"
	(!occursin(cmd, "-W") && opt_W == "") && (cmd *= " -W0.5p")		# Do not leave without a line specification
	return arg1, cmd
end

function check_ribbon(d::Dict{Symbol, Any}, arg1::Vector{<:GMTdataset{T,N}}, cmd::String, opt_W::String) where {T,N}
	((val = find_in_dict(d, [:ribbon :band])[1]) === nothing) && return arg1, cmd
	ec1, ec2, add_2 = helper_check_ribbon(val)		# Function barrier agains Anys
	if (add_2)
		for k = 1:numel(arg1)  add2ds!(arg1[k], ec2; names=["Zbnd1","Zbnd2"])  end
	else
		for k = 1:numel(arg1)  add2ds!(arg1[k], ec1; name="Zbnd")  end
	end
	d[:L] = (add_2) ? "+D" : "+d"
	(!occursin(cmd, "-W") && opt_W == "") && (cmd *= " -W0.5p")		# Do not leave without a line specification
	return arg1, cmd
end

function helper_check_ribbon(val)::Tuple{Vector{Float64}, Matrix{Float64}, Bool}
	# Isolate here the fact that 'val' is a Any
	add_2 = true
	ec1, ec2 = Float64[], Matrix{Float64}[]
	if isa(val, Real)
		ec1 = repeat([float(val)::Float64], size(arg1,1)::Int)
		add_2 = false
	elseif (isa(val, VecOrMat{<:Real}) || isa(val, Tuple{<:Real, <:Real}))
		(length(val)::Int == 2) ? (ec2 = repeat([float(val[1])::Float64 float(val[2])::Float64], size(arg1,1)::Int)) :
		                           ec2 = [Float64.(vec(val)) Float64.(vec(val))]
	elseif isa(val, Tuple{Vector{<:Real}, Vector{<:Real}})
		ec2 = [Float64.(val[1]) Float64.(val[2])]
	elseif (isa(val, Matrix{<:Real}) && size(val,2) == 2)
		ec2 = val
	else
		error("Wrong data type for ribbon/band $(typeof(val))")
	end
	ec1, ec2, add_2
end

# ---------------------------------------------------------------------------------------------------
function with_xyvar(d::Dict, arg1::GMTdataset, no_x::Bool=false)::Union{GMTdataset, Vector{<:GMTdataset}}
	# Make a subset of a GMTdataset by selecting which columns to extract. The selection can be done by
	# column numbers or column names. 'xvar' selects only the xx col, but 'yvar' can select more than one.
	# 'no_x' is for croping some columns and not add a x column and not split in many D's (one per column).
	# By default when yvar is a Vec we split the columns by default (for ploting reasons since we want a
	# line per column). Pass nomulticol=1 in 'd' to prevent this.
	# The zvar, [:svar :sizevar] and [:cvar :colorvar] are used to pull out the respective columns.

	((val_y = find_in_dict(d, [:y :yvar])[1]) === nothing) && return arg1	# No y colname, no business
	ycv::Vector{Int}, ismulticol = Int[], false
	if (isa(val_y, Integer) || isa(val_y, String) || isa(val_y, Symbol))
		yc = isa(val_y, Integer) ? val_y : ((ind = findfirst(string(val_y) .== arg1.colnames)) !== nothing ? ind : 0)
		(yc < 1 || yc > size(arg1,2)) && error("'yvar' Name not found in GMTdataset col names or exceed col count.")
		ycv = [yc]
	elseif (isvector(val_y) || isa(val_y, Tuple))
		if (eltype(val_y) <: Integer)
			ycv = [val_y...]
		elseif (eltype(val_y) <: Union{String, Symbol})
			vs = [string.(val_y)...]
			ycv = zeros(Int, length(vs))
			for k = 1:lastindex(vs)
				((ind = findfirst(vs[k] .== arg1.colnames)) !== nothing) && (ycv[k] = ind)
			end
			any(ycv .== 0) && error("One or more column names does not match with data colnames.")
		end
		isempty(ycv) && error("yvar option is non-sense.")
		(minimum(ycv) < 1 || maximum(ycv) > size(arg1,2)) && error("Col names not found in GMTdataset col names or exceed col count.")
		domulticol = ((is_in_dict(d::Dict, [:nomulticol]; del=true)) === nothing) ? true : false
		(domulticol) && (ismulticol = true)
	end

	function getcolvar(d::Dict, var::VMs)::Int
		((_val = find_in_dict(d::Dict, var)[1]) === nothing) && return 0
		!(isa(_val, Integer) || isa(_val, String) || isa(_val, Symbol)) && error("$(var) can only be an Int, a String or a Symbol but was a $(typeof(_val))")
		c = isa(_val, Integer) ? _val : ((_ind = findfirst(string(_val)::String .== arg1.colnames)) !== nothing ? _ind : 0)
		(c < 1 || c > size(arg1,2)) && error("$(var) Col name not found in GMTdataset col names or exceed col count.")
		return c
	end

	xc = getcolvar(d, [:x :xvar])
	zc = getcolvar(d, [:z :zvar]);			(zc != 0) && (ycv = [ycv..., zc])
	cc = getcolvar(d, [:cvar :colorvar]);	(cc != 0) && (ycv = [ycv..., cc])
	sc = getcolvar(d, [:svar :sizevar]);	(sc != 0) && (ycv = [ycv..., sc])
	if (!no_x)
		if (xc == 0)
			colnames = ["X", arg1.colnames[ycv]...]
			!isempty(arg1.text) && (colnames = append!(colnames, [arg1.colnames[end]]))	# Add the text col name
			out = mat2ds(hcat(collect(1:size(arg1,1)), arg1.data[:, ycv]), txtcol=arg1.text, colnames=colnames)
			if ((Tc = get(arg1.attrib, "Timecol", "")) != "")	# Try to keep also an eventual Timecol
				((ind = findfirst(parse(Int, Tc) .== ycv)) !== nothing) && (D.attrib[:Timecol] = (xc !== nothing) ? ind+1 : ind)
			end
		else
			out = mat2ds(arg1, (:, [xc, ycv...]))
		end
		if (ismulticol)
			cycle_color = (haskey(d, :group) || haskey(d, :groupvar)) ? false : true	# In groups, outlines are black
			D = mat2ds(out.data, multi=true, color=cycle_color, txtcol=out.text, colnames=out.colnames)
			if ((Tc = get(arg1.attrib, "Timecol", "")) == "1")	# Try to keep an eventual Timecol
				for k = 1:numel(D)  D[k].attrib["Timecol"] = "1";	D[k].colnames[1] = "Time";  end
			end
		else
			D = out
		end
	else
		D = mat2ds(arg1, (:,ycv))
	end
	return D
end

# ---------------------------------------------------------------------------------------------------
"""
    cmd = fish_pagebg(d::Dict, cmd::Vector{String}) -> Vector{String}

Check if using a background image to replace the page color.

This function checks for the presence of a `pagebg` option that sets the page background image.
Note that this is different from the `background` or `bg` option that sets the plotting canvas background color.

- `pagebg`: a NamedTuple with the following members
    - `image`: the image name or a GMTimage/GMTgrid object
    - `logo`: To plot the GMT logo (from the global ``timestamp`` option) at the lower left corner.
    - `width`: the width of the background image in percentage of the page width (default: 0.8)
    - `offset`: the offset in paper units (cm prefrably) with respect to the center of the background
       image (default: (0.0,0.0)). If only one value is provided it is used for the X offset only.

OR 

- `pagebg`: an image file name or a GMTimage/GMTgrid object
   In this case the above defaults for the _width_ and _offset_ parameters are used
"""
function fish_pagebg(d::Dict, cmd::Vector{String}; autoJZ::Bool=true)::Vector{String}
	((val = find_in_dict(d, [:pagebg])[1]) === nothing) && return cmd
	width::Float64 = 0.8;	off_X::Float64 = 0.0;	off_Y::Float64 = 0.0	# The off's are offsets from the center
	opt_U = ""
	if isa(val, NamedTuple)
		!haskey(val, :image) && error("pagebg: NamedTuple must contain the member 'image'")
		fname = helper_fish_bgs(val[:image])		# Get the image name or set it under the hood if input is a GMTimage
		haskey(val, :width) && (width = val[:width])
		(width <= 0 || width > 1) && error("pagebg: width is a normalized value, must be between 0 and 1")
		if (haskey(val, :offset) || haskey(val, :off))
			off = (haskey(val, :offset)) ? val[:offset] : val[:off]
			isa(off, Real) ? (off_X = off) : length(off) == 2 ? (off_X = off[1]; off_Y = off[2]) :
				error("pagebg: offset must be a Real or a two elements Array/Tuple")
		end
		haskey(val, :logo) && (opt_U = " -U+o0+t")
	else				# Here, val is just the file name or a GMTimage
		fname = helper_fish_bgs(val)	# Get the image name or set it under the hood if input is a GMTimage
	end

	if contains(CTRL.pocket_J[2], "/")  Wt, Ht = split(CTRL.pocket_J[2], '/')
	else                                Wt = CTRL.pocket_J[2]; Ht = "/0"
	end
	isletter(Wt[end]) ? (cw=Wt[end]; Wt = Wt[1:end-1]) : (cw = 'c')
	isletter(Ht[end]) ? (ch=Ht[end]; Ht = Ht[1:end-1]) : (ch = 'c');	(Ht == "0") && (Ht = "/0")
	W = parse(Float64, Wt)
	if (Ht != "" && Ht != "/0")			# User gave an explicit height
		H = parse(Float64, Ht) * width	# r = H / W; H = r * width * W; = H * width
		Ht = @sprintf("/%.4g%c", H, ch)
	end

	off_XY = @sprintf(" -X%.4g%c", off_X + (1-width)/2 * W, cw)
	(off_Y != 0.0) && (off_XY *= @sprintf(" -Y%.4g%c", off_Y, cw))
	opt_J = scan_opt(cmd[1], "-J", true)
	new_J = string(opt_J[1:4], width * W, cw, Ht)

	# If the 'bg' option is also set it sits in cmd[1] and then we want to modify cmd[2].
	ind_cmd = startswith(cmd[1], "grdimage") ? 2 : 1	# The presence of 'grdimage' says that 'bg' was used.

	cmd[ind_cmd] = replace(cmd[ind_cmd], opt_J => new_J * off_XY)
	if (autoJZ && (opt_JZ = scan_opt(cmd[1], "-JZ", true)) != "")	# Only do this for JZ that was set automatically
		z = parse(Float64, isletter(opt_JZ[end]) ? opt_JZ[5:end-1] : opt_JZ[5:end]) * width
		CTRL.pocket_J[3] = @sprintf(" -JZ%.4g%c", z, cw)
		cmd[ind_cmd] = replace(cmd[ind_cmd], opt_JZ => CTRL.pocket_J[3])
	end
	proggy = IamModern[1] ? "image " : "psimage "
	[proggy * fname * CTRL.pocket_J[1] * CTRL.pocket_R[1] * opt_U * " -Dx0/0+w"*Wt*cw, cmd...]
end

# ---------------------------------------------------------------------------------------------------
"""
    cmd = fish_bg(d::Dict, cmd::Vector{String}) -> Vector{String}

Check if a background image in a plot area is requested.

Check if the background image is used and if yes insert a first command that calls grdimage to fill
the canvas with that bg image. The BG image can be a file name, the name of one of the pre-defined
functions, or a GMTgrid/GMTimage object. By default we use a trimmed gray scale (between ~64 & 240)
but if user wants to control the colormap then the option's argument can be a tuple where the second
element is cpt name or a GMTcpt obj.

### Example

```julia
plot(rand(8,2), bg=(:somb, :turbo), show=1)

# To revert the sense of the color progression prefix the cpt name or of the pre-def function with a '-'

plot(rand(8,2), bg="-circ", show=1)
```
"""
function fish_bg(d::Dict, cmd::Vector{String})::Vector{String}
	((val = find_in_dict(d, [:bg :background])[1]) === nothing) && return cmd
	fname = helper_fish_bgs(val)

	opt_p = scan_opt(cmd[1], "-p", true);		opt_c = scan_opt(cmd[1], "-c", true)
	opt_D = (IamModern[1]) ? " -Dr " : " -D "	# Found this difference by experience. It might break in future GMTs
	["grdimage" * opt_D * fname * CTRL.pocket_J[1] * opt_p * opt_c, cmd...]
end

function helper_fish_bgs(val)::String
	arg1, arg2 = isa(val, Tuple) ? val[:] : (val, nothing)
	(arg2 !== nothing && (!isa(arg2, GMTcpt) && !isa(arg2, StrSymb))) &&
		error("When a Tuple is used in argument of the background image option, the second element must be a string or a GMTcpt object.")
	gotfname, fname::String, opt_I::String = false, "", ""
	if (isa(arg1, StrSymb))
		if (splitext(string(arg1)::String)[2] != "")	# Assumed to be an image file name
			fname, gotfname = arg1, true
		else											# A pre-set fun name
			fun::String = string(arg1)
			(fun[1] == '-') && (fun = fun[2:end]; opt_I = " -I")
			I::GMTimage = imagesc(mat2grid(fun))
		end
	elseif (isa(arg1, GMTgrid) || isa(arg1, GMTimage))
		I = isa(arg1, GMTgrid) ? imagesc(arg1) : val
	end
	if (!gotfname)
		((arg2 !== nothing) && isa(arg2, String) && (arg2[1] == '-')) && (arg2 = arg2[2:end]; opt_I = " -I")
		opt_H = (IamModern[1]) ? " -H" : ""
		C::GMTcpt = (arg2 === nothing) ? gmt("makecpt -T0/256/1 -G0.25/0.94 -Cgray"*opt_I*opt_H) :	# The default gray scale
		                                 isa(arg2, GMTcpt) ? gmt("makecpt -T0/256/1 -C" * opt_H, arg2) :
							        	 gmt("makecpt -T0/256/1 -C" * string(arg2)::String * opt_I * opt_H)
		image_cpt!(I, C)
		CTRL.pocket_call[3] = I			# This signals finish_PS_module() to run _cmd first
	end
	FIG_MARGIN[1] = 0
	return fname
end

# ---------------------------------------------------------------------------------------------------
function isTimecol_in_pltcols(D::GDtype)
	# See if we have a Timecol in one of the ploting columns
	(isa(D, GMTdataset) && ((Tc = get(D.attrib, "Timecol", "")) == "")) && return false
	(isa(D, Vector{<:GMTdataset}) && ((Tc = get(D[1].attrib, "Timecol", "")) == "")) && return false
	tc = parse(Int, Tc)
	return (tc <= 2) ? true : false
end

# ---------------------------------------------------------------------------------------------------
function helper_psxy_line(d::Dict, cmd::String, opt_W::String, is3D::Bool, arg1, arg2, arg3)
	haskey(d, :multicol) && return arg1, opt_W, false, false	# NOT OBVIOUS IF THIS IS WHAT WE WANT TO DO
	made_it_vector, rep_str = false, ""
	got_color_line_grad = contains(opt_W, ",grad")		# Checks both ",gradient" and ",grad"

	# If we get a line thickness variation we must always call line2multiseg(). The :var_lt was set in build_pen()
	got_variable_lt = ((val = find_in_dict(d, [:var_lt])[1]) !== nothing)

	if (got_color_line_grad)
		cpt = helper_psxy_line_barr1(cmd, is3D, arg1, arg2, arg3)
	end

	if (got_color_line_grad && !got_variable_lt)
		arg1, made_it_vector, rep_str = helper_psxy_line_barr2(arg1, cpt, is3D)
	elseif (got_variable_lt)	# Otherwise just return without doing anything
		arg1 = helper_psxy_line_barr3(arg1, val, cpt, is3D, got_color_line_grad)
	#else						# Means this function call did nothing
	end
	contains(opt_W, ",gradient") && (opt_W = replace(opt_W, ",gradient" => rep_str))
	contains(opt_W, ",grad")     && (opt_W = replace(opt_W, ",grad" => rep_str))
	(opt_W == " -W") && (opt_W = "")	# All -W options are set in dataset headers, so no need for -W
	return arg1, opt_W, got_color_line_grad, made_it_vector
end

# ---------------------------------------------------------------------------------------------------
# Barrier functions to limit the damage of invalidations, that helper_psxy_line() still has
function helper_psxy_line_barr3(arg1, val, cpt::GMTcpt, is3D::Bool, got_color_line_grad::Bool)
	lt::Vector{Float64} = vec(Float64.(val))
	if (got_color_line_grad)  arg1 = line2multiseg(arg1, is3D=is3D, lt=lt, color=cpt)
	else                      arg1 = line2multiseg(arg1, is3D=is3D, lt=lt)
	end
end

function helper_psxy_line_barr2(arg1, cpt::GMTcpt, is3D::Bool)
	made_it_vector, rep_str = false, ""
	if (!is3D)
		arg1 = mat2ds(color_gradient_line(arg1, is3D=is3D))
		made_it_vector, rep_str = true, "+cl"
	else
		arg1 = line2multiseg(arg1, is3D=true, color=cpt)
	end
	return arg1, made_it_vector, rep_str
end

function helper_psxy_line_barr1(cmd::String, is3D::Bool, arg1, arg2, arg3)::GMTcpt
	if (occursin("-C", cmd))
		cpt = get_first_of_this_type(GMTcpt, arg1, arg2, arg3)
		if (cpt === nothing)
			CPTname = scan_opt(cmd, "-C")
			cpt::GMTcpt = gmtread(CPTname, cpt=true)
		end
	elseif (!isempty(CURRENT_CPT[1]))
		cpt = CURRENT_CPT[1]
	else
		mima = (size(arg1,2) == 2) ? (1,size(arg1,1)) : (arg1.ds_bbox[5+0*is3D], arg1.ds_bbox[6+0*is3D])
		cpt = gmt(@sprintf("makecpt -T%f/%f/65+n -Cturbo -Vq", mima[1]-eps(1e10), mima[2]+eps(1e10)))
	end
	return cpt
end
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
parse_opt_S(d::Dict, arg1::Union{GMTfv, Vector{GMTfv}}, is3D::Bool) = arg1, ""	# Just to have a method for FVs
function parse_opt_S(d::Dict, arg1, is3D::Bool=false)

	opt_S::String, have_custom = "", false
	is1D = isvector(arg1)
	# First see if the requested symbol is a custom one from GMT.jl share/custom
	if ((symb = is_in_dict(d, [:csymbol :cmarker :custom_symbol :custom_marker])) !== nothing)
		marca::String = add_opt(d, "", "", [symb], (name="", size="/", unit="1"))
		have_custom, custom_no_size = true, !isdigit(marca[end])	# So that we can have custom symbs with sizes in arg1
		marca_fullname::String = seek_custom_symb(marca)
		(marca_fullname != "") && (opt_S = " -Sk" * marca_fullname)
	else
		opt_S = add_opt(d, "", "S", [:S :symb :symbol], (symb="1", size="", unit="1"))
	end
	
	_scale(isInt::Bool) = (isInt) ? 2.54/72 : 1.0
	function helper_varsizes(arg1, n_args, mi_sz, ma_sz, mi_val, ma_val, isInt)
		if (n_args == 2)
			arg1[arg1 .< mi_val] .= mi_sz
			arg1[arg1 .> ma_val] .= ma_sz
		end
		((sc_local = _scale(isInt)) != 1.0) && (arg1 .*= sc_local)
	end

	if (opt_S == "" || (have_custom && custom_no_size))		# OK, no symbol given via the -S option. So fish in aliases
		marca, arg1, more_cols = get_marker_name(d, arg1, [:marker, :Marker, :shape], is3D, true)
		if ((_val = find_in_dict(d, [:ms :markersize :MarkerSize :size])[1]) !== nothing)
			(marca == "") && (marca = "c")		# If a marker name was not selected, defaults to circle
			val = isa(_val, Tuple) ? _val : isa(_val, VMr) && is1D ? (_val,) : _val		# Let also size=[3 20] && is1D do it right
			if (isa(val, VMr))
				val_::Vector{Float64} = vec(Float64.(val))
				if (length(val_) == 2)			# A two elements array is interpreted as [min max]
					sc = _scale(eltype(val) <: Integer)
					arg1 = hcat(arg1, linspace(val_[1], val_[2], size(arg1,1)) .* sc)
				else
					(length(val_) != size(arg1,1)) &&
						error("The size array must have the same number of elements as rows in data")
					arg1 = hcat(arg1, val_[:])
				end
			elseif (isa(val, Tuple))
				# size=([3 10])  => Scale extrema(arg1) berween 3 and 10
				# size=([3 10],[1 2])  => All numbers in arg1 <= 1 get size 3; >= 2 get size 10; in between interpolate
				# size(fun,[]); size(fun,[],[])  => Same but using scaling function 'fun' instead of linear.
				if (is1D)
					n_args::Int = length(val)
					fun = isa(val[1], Function) ? val[1] : isa(val[1], Tuple) && isa(val[1][1], Function) ? val[1][1] : nothing
					(fun == pow) && (exponent = val[1][2])
					(n_args == 1 && fun !== nothing) && error("Cannot pass a Function and no size limits.")
					isInt = (fun !== nothing ? (eltype(val[2][1]) <: Integer) : (eltype(val[1][1]) <: Integer)) 
					mi_sz::Float64, ma_sz::Float64 = (fun === nothing) ? val[1] : val[2]
					mi_val::Float64, ma_val::Float64 = val[end]
					mi, ma = extrema(arg1)
					if (fun !== nothing)
						# size=(exp10, [10 40]); plot(0:0.1:1, exp10.(log10(31) .* (0:0.1:1)).+9, show=1)
						arg1 .= (arg1 .- mi) ./ (ma - mi)		# [0 1.0]
						if (fun == exp10 || fun == exp)
							lo = mi_sz - 1; hi = ma_sz - mi_sz + 1
							fun_inv = (fun == exp10) ? log10 : log
							arg1 .= fun.(fun_inv(hi) .* arg1) .+ lo
						elseif (fun == pow || fun == sqrt)
							lo = mi_sz; hi = ma_sz - mi_sz
							arg1 .= (fun == pow) ? pow.(pow(hi, 1/exponent) .* arg1, exponent) .+ lo : sqrt.(hi ^2 .* arg1) .+ lo
						end
						helper_varsizes(arg1, n_args, mi_sz, ma_sz, mi_val, ma_val, isInt)
					else
						mi, ma = (n_args == 1) ? extrema(arg1) : val[2]
						arg1 .= (mi_sz .+ (arg1 .- mi) ./ (ma - mi) .* (ma_sz - mi_sz))
						helper_varsizes(arg1, n_args, mi_sz, ma_sz, mi_val, ma_val, isInt)
					end
				elseif (isa(val, Tuple) && isa(val[1], Function) && isa(val[2], VMr))	# ~useless size=(fun, [2,20]) but no col size
					val2::Tuple = val
					sc = _scale(eltype(val2[2]) <: Integer)
					arg1 = hcat(arg1, funcurve(val2[1], vec(Float64.(val2[2] .* sc)), size(arg1,1)))
				end
			elseif (string(val)::String != "indata")	# WTF is "indata"?
				marca *= arg2str(val)::String
			end
			opt_S = " -S" * marca
		elseif (marca != "")					# User only selected a marker name but no size.
			opt_S = " -S" * marca
			# If data comes from a file, then no automatic symbol size is added
			op = lowercase(marca[1])
			def_size::String = (op == 'p') ? "2p" : "7p"	# 'p' stands for symbol points, not units. Att 7p used in seismicity() 
			(!more_cols && arg1 !== nothing && !isa(arg1, GMTcpt) && !occursin(op, "bekmrvw")) && (opt_S *= def_size)
		elseif (haskey(d, :hexbin))
			inc::Float64 = parse(Float64, arg1.attrib["hexbin"])
			r::Float64   = (CTRL.limits[8] - CTRL.limits[7]) / sqrt(3) / inc
			(CTRL.figsize[1] == 0) && @warn("Failed to automatically fetch the fig width. Using 15 cm to show something.")
			w::Float64 = (CTRL.figsize[1] != 0) ? CTRL.figsize[1] : 15.0
			opt_S = " -Sh$(w / (r * 1.5))"		# Is it always 1.5?
			delete!(d, :hexbin)
		elseif (is_in_dict(d, [:arrow :geovec :geovector]) !== nothing)
			opt_S = " -S" * helper_arrows(d)
		end
	else
		symb = is_in_dict(d, [:ms :markersize :MarkerSize :size]; del=true)
		(symb !== nothing) && @warn("option *$(symb)* is ignored when either 'S' or 'symbol' options are used")
		symb = is_in_dict(d, [:marker :Marker :shape]; del=true)
		(symb !== nothing) && @warn("option *$(symb)* is ignored when either 'S' or 'symbol' options are used")
	end
	return arg1, opt_S
end

# ---------------------------------------------------------------------------------------------------
function parse_markerline(d::Dict, opt_ML::String, opt_Wmarker::String)::Tuple{String, String}
	# Make this code into a function so that it can also be called from mk_styled_line!()
	if ((val = find_in_dict(d, [:ml :markerline :MarkerLine])[1]) !== nothing)
		if (isa(val, Tuple))           opt_ML::String = " -W" * parse_pen(val) # This can hold the pen, not extended atts
		elseif (isa(val, NamedTuple))  opt_ML = add_opt_pen(nt2dict(val), [:pen], opt="W")
		else                           opt_ML = " -W" * arg2str(val)
		end
		if (opt_Wmarker != "")
			@warn("markerline overrides markeredgecolor");		opt_Wmarker = ""
		end
	end
	return opt_ML, opt_Wmarker
end

# ---------------------------------------------------------------------------------------------------
function build_run_cmd(cmd, opt_B, opt_Gsymb, opt_ML, opt_S, opt_W, opt_Wmarker, opt_UVXY, opt_c)::Vector{String}
	# Build the executble command vector
	if (opt_W != "" && opt_S == "") 							# We have a line/polygon request
		_cmd = [cmd * opt_W * opt_UVXY]

	elseif (opt_W == "" && (opt_S != "" || opt_Gsymb != ""))	# We have a symbol request
		(opt_Wmarker != "" && opt_W == "") && (opt_Gsymb *= " -W" * opt_Wmarker)	# reuse var name
		(opt_ML != "") && (cmd *= opt_ML)					# If we have a symbol outline pen
		_cmd = [cmd * opt_S * opt_Gsymb * opt_UVXY]

	elseif (opt_W != "" && opt_S != "")							# We have both line/polygon and a symbol
		(occursin(opt_Gsymb, cmd)) && (opt_Gsymb = "")
		c = lowercase(opt_S[4])
		if (c == 'v' || c == 'm' || c == 'w' || c == '=' || c == 'q')	# Are there more cases where the pen applies to the symbol?
			_cmd = [cmd * opt_W * opt_S * opt_Gsymb * opt_UVXY]
		else
			(opt_Wmarker != "") && (opt_Wmarker = " -W" * opt_Wmarker)		# Set Symbol edge color
			cmd1 = cmd * opt_W * opt_UVXY
			(opt_B != " " && opt_B != "") && (cmd = replace(cmd, opt_B => ""))	# Some themes make opt_B = " "
			cmd2 = cmd * opt_S * opt_Gsymb * opt_Wmarker	# Don't repeat option -B
			(opt_c != "")  && (cmd2 = replace(cmd2, opt_c => ""))  				# Not in scond call (subplots)
			(opt_ML != "") && (cmd2 = cmd2 * opt_ML)			# If we have a symbol outline pen
			_cmd = [cmd1; cmd2]
		end

	else
		_cmd = [cmd * opt_UVXY]
	end
end

# ---------------------------------------------------------------------------------------------------
function helper_gbar_fill(d::Dict)::Vector{String}
	# This is a function that tryies to hammer the insistence that g_bar_fill is a Any
	# g_bar_fill may hold a sequence of colors for group Bar plots
	gval = find_in_dict(d, [:fill :fillcolor], false)[1]	# Used for group colors
	if (isa(gval, Array{String}) && length(gval)::Int > 1)
		g_bar_fill::Vector{String} = String[]
		append!(g_bar_fill, gval)
	elseif ((isa(gval, Array{Int}) || isa(gval, Tuple) && eltype(gval) == Int) && length(gval)::Int > 1)
		g_bar_fill = Vector{String}(undef, length(gval)::Int)			# Patterns
		for k in eachindex(gval)  g_bar_fill[k] = string('p', gval[k])  end
	elseif (isa(gval, Tuple) && (eltype(gval) == String || eltype(gval) == Symbol) && length(gval) > 1)
		g_bar_fill = Vector{String}(undef, length(gval)::Int)			# Patterns
		for k in eachindex(gval)  g_bar_fill[k] = string(gval[k])::String  end
	else
		g_bar_fill = String[]		# To have somthing to return
	end
	return g_bar_fill
end

# ---------------------------------------------------------------------------------------------------
# Check if a group bar request or just bars. Returns TRUE in first case and FALSE in second
check_bar_group(arg1) = ( (isa(arg1, Vector{<:GMTdataset}) ? size(arg1[1],2) > 2 : size(arg1,2) > 2) )::Bool

# ---------------------------------------------------------------------------------------------------
function bar_group(d::Dict, cmd::String, opt_R::String, g_bar_fill::Vector{String}, got_Ebars::Bool, got_usr_R::Bool, arg1)::Tuple{String, Vector{<:GMTdataset}, String}
	# Convert input array into a multi-segment Dataset where each segment is an element of a bar group
	# Example, plot two groups of 3 bars each: bar([0 1 2 3; 1 2 3 4], xlabel="BlaBla")

	cmd2::String = ""			# Only used in the waterfall case to hold the 'connector' command
	if (got_Ebars)
		opt_E = scan_opt(cmd, "-E")
		((ind  = findfirst("+", opt_E)) !== nothing) && (opt_E = opt_E[1:ind[1]-1])	# Strip eventual modifiers
		(((ind = findfirst("X", opt_E)) !== nothing) || ((ind = findfirst("Y", opt_E)) !== nothing)) && return cmd, arg1
		n_xy_bars = (findfirst("x", opt_E) !== nothing) + (findfirst("y", opt_E) !== nothing)
		n_cols = size(arg1,2)
		((n_cols - n_xy_bars) == 2) && return cmd, arg1			# Only one-bar groups
		(iseven(n_cols)) && error("Wrong number of columns in error bars array (or prog error)")
		n = Int((n_cols - 1) / 2)
		_arg = Float64.(arg1.data[:, 1:(n+1)])	# No need to care with GMTdatasets because case was dealt in 'got_Ebars'
		bars_cols = arg1.data[:,(n + 2):end]	# We'll use this to append to the multi-segments
	else
		_arg = isa(arg1, GMTdataset) ? Float64.(copy(arg1.data)) : Float64.(copy(arg1[1].data))
		bars_cols = missing
	end

	do_multi = true;	is_stack = false		# True for grouped; false for stacked groups
	is_waterfall = false
	is_hbar = occursin("-SB", cmd)				# An horizontal bar plot

	if ((val = hlp_desnany_str(d, [:stack :stacked])) !== "")
		# Take this (two groups of 3 bars) [0 1 2 3; 1 2 3 4]  and compute this (the same but stacked)
		# [0 1 0; 0 3 1; 0 6 3; 1 2 0; 1 5 2; 1 9 4]
		# Taking for example the first group, [0 1 0; 0 3 1; 0 6 3] this means:
		# [|x=0 base=0, y=1|; |x=0 base=1, y=3|; |x=0, base=3, y=6]
		is_waterfall = startswith(val, "water")
		nl::Int = size(_arg,2)-1				# N layers in stack
		tmp = zeros(size(_arg,1)*nl, 3)

		for m = 1:size(_arg, 1)			# Loop over number of groups
			tmp[(m-1)*nl+1,1] = _arg[m,1];		tmp[(m-1)*nl+1,2] = _arg[m,2];	# 3rd col is zero
			for n = 2:nl				# Loop over number of layers (n bars in a group)
				tmp[(m-1)*nl+n,1] = _arg[m,1]
				if (sign(tmp[(m-1)*nl+n-1,2]) == sign(_arg[m,n+1]))		# When we have neg & pos, case is diff
					tmp[(m-1)*nl+n,2] = tmp[(m-1)*nl+n-1,2] + _arg[m,n+1]
					tmp[(m-1)*nl+n,3] = tmp[(m-1)*nl+n-1,2]
				else
					if (is_waterfall)
						tmp[(m-1)*nl+n,3] = tmp[(m-1)*nl+n-1,2]
						tmp[(m-1)*nl+n,2] = tmp[(m-1)*nl+n,3] + _arg[m,n+1]
						(tmp[(m-1)*nl+n,2] == tmp[(m-1)*nl+n,3]) && (tmp[(m-1)*nl+n,3] = 0)		# A 'total' column
					else
						tmp[(m-1)*nl+n,2] = _arg[m,n+1]
						tmp[(m-1)*nl+n,3] = 0
					end
				end
			end
		end
		if (is_waterfall)
			for k = 2:nl  tmp[k] += (k-1)  end			# Set the x coordinates of each bar

			tricol = ["darkgreen", "tomato", "gray70"]	# The default colors when no other were sent in args
			if (!isempty(g_bar_fill))					# Bar colors sent in as args to this function.
				tricol[1:2] = string.(g_bar_fill[1:2])	# If < 2 it will error
				(length(g_bar_fill) > 2) && (tricol[3] = string(g_bar_fill[3]))
			end
			g_bar_fill = fill(tricol[1], nl)
			g_bar_fill[_arg[2:end] .< 0]  .= tricol[2]
			g_bar_fill[_arg[2:end] .== 0] .= tricol[3]

			if (is_in_dict(d, [:connector]) !== nothing)
				# Here we need to know the bar width but that info was fetch in check_caller. So fish it from -Sb0.8u+b0
				bw  = parse(Float64, split(split(split(cmd, "-S")[2])[1], "u+")[1][2:end])
				bw2 = bw / 2
				con = fill(NaN, (nl-1)*3, 2)
				for k = 1:nl-1
					con[(k-1)*3+1:(k-1)*3+2, :] = [tmp[k]+bw2 tmp[k,2]; tmp[k+1]-bw2 tmp[k+1,3]]
					(_arg[k+2] == 0) && (con[(k-1)*3+2, 2] = tmp[k+1,2])	# 'total' bars are always 0->top
				end
				CTRL.pocket_call[3] = con
				cmd2 = add_opt_pen(d, [:connector], opt="W")
			end
		end
		(is_hbar) && (tmp = [tmp[:,2] tmp[:,1] tmp[:,3]])		# Horizontal bars must swap 1-2 cols
		_arg = tmp
		do_multi = false;		is_stack = true
	end

	if ((isempty(g_bar_fill) || is_waterfall) && findfirst("-G0/115/190", cmd) !== nothing)		# Remove auto color
		cmd = replace(cmd, " -G0/115/190" => "")
	end

	# Convert to a multi-segment GMTdataset. There will be as many segments as elements in a group
	# and as many rows in a segment as the number of groups (number of bars if groups had only one bar)
	alpha = find_in_dict(d, [:alpha :fillalpha :transparency])[1]
	_argD::Vector{GMTdataset{eltype(_arg), 2}} =
		Base.invokelatest(mat2ds, _arg; fill=g_bar_fill, multi=do_multi, fillalpha=alpha, letsingleton=true)
	(is_stack) && (_argD = ds2ds(_argD[1], fill=g_bar_fill, color_wrap=nl, fillalpha=alpha))
	if (is_hbar && !is_stack)					# Must swap first & second col
		for k = 1:lastindex(_argD)  _argD[k].data = [_argD[k].data[:,2] _argD[k].data[:,1]]  end
	end
	(!isempty(g_bar_fill)) && delete!(d, :fill)

	if (bars_cols !== missing)		# Loop over number of bars in each group and append the error bar
		for k = 1:lastindex(_argD)
			_argD[k].data = reshape(append!(_argD[k].data[:], bars_cols[:,k]), size(_argD[k].data,1)::Int, :)
		end
	end

	# Must fish-and-break-and-rebuild -S option
	opt_S = scan_opt(cmd, "-S")
	sub_b = ((ind = findfirst("+", opt_S)) !== nothing) ? opt_S[ind[1]:end] : ""	# The +Base modifier
	(sub_b != "") && (opt_S = opt_S[1:ind[1]-1])	# Strip it because we need to (re)find Bar width
	bw::Float64 = (isletter(opt_S[end])) ? parse(Float64, opt_S[3:end-1]) : parse(Float64, opt_S[2:end])	# Bar width
	n_in_group = length(_argD)						# Number of bars in the group
	new_bw::Float64 = (is_stack) ? bw : bw / n_in_group	# 'width' does not change in bar-stack
	new_opt_S::String = "-S" * opt_S[1] * "$(new_bw)u"
	cmd = (is_stack) ? replace(cmd, "-S"*opt_S*sub_b => new_opt_S*"+b") : replace(cmd, "-S"*opt_S => new_opt_S)

	if (!is_stack)									# 'Horizontal stack'
		col = (is_hbar) ? 2 : 1						# Horizontal and Vertical bars get shits in different columns
		n_groups = size(_argD[1].data,1)
		n_in_each_group = fill(0, n_groups)			# Vec with n_in_group elements
		for k = 1:n_groups n_in_each_group[k] = sum(.!isnan.(_arg[k,:][2:end]))  end
		if (sum(n_in_each_group) == n_in_group * n_groups)
			g_shifts_ = linspace((-bw + new_bw)/2, (bw - new_bw)/2, n_in_group)
			for k = 1:n_in_group					# Loop over number of bars in a group
				for r = 1:n_groups  _argD[k].data[r, col] += g_shifts_[k]  end
			end
		else
			ic::Int   = ceil(Int, (size(_arg,2)-1)/2)		# index of the center bar (left from middle if even)
			g_shifts0 = linspace((-bw + new_bw)/2, (bw - new_bw)/2, n_in_group)
			for m = 1:n_groups						# Loop over number of groups
				if (n_in_each_group[m] == n_in_group)	# This group is simple. It has all the bars
					for k = 1:n_in_group  _argD[k].data[m, col] += g_shifts0[k]  end	# Loop over all the bars in group
					continue
				end

				g_shifts = collect(g_shifts0)
				x     = isnan.(_arg[m,:][2:end])
				n_low = sum(.!x[1:ic]);		n_high = sum(.!x[ic+1:end])
				clow  = !all(x[1:ic-1]);	chigh = !all(x[ic+1:end])	# See if both halves want the center pos
				dx = (clow && chigh) ? new_bw/2 : 0.0
				for n = 1:ic					# Lower half
					g_shifts[n] += ((ic-n)-sum(.!x[n+1:ic])) * new_bw - dx
				end
				for n = ic+1:n_in_group			# Upper half
					g_shifts[n] -= ((n-ic)-sum(.!x[ic:n-1])+!x[ic]) * new_bw - dx
				end

				# Compensate when bar distribution is not symetric about the center
				if     (n_high == 0 && n_in_each_group[m] > 1)  g_shifts .+= (n_low-1) * new_bw/2
				elseif (n_low == 0 && n_in_each_group[m] > 1)   g_shifts .-= (n_high-1) * new_bw/2
				elseif (n_in_each_group[m] > 1)                 g_shifts .-= (n_high - n_low) * new_bw/2
				end
				(iseven(n_in_group)) && (g_shifts .+= new_bw/2)		# Don't get it why I have to do this

				for k = 1:n_in_group  _argD[k].data[m, col] += g_shifts[k]  end		# Loop over all the bars in this group
			end
		end
	end

	if (!got_usr_R)									# Need to recompute -R
		info::GMTdataset = gmt("gmtinfo -C", _argD)
		data::Matrix{<:Float64} = info.data
		(data[3] > 0.0) && (data[3] = 0.0)	# If not negative then must be 0
		if (!is_hbar)
			dx::Float64 = (data[2] - data[1]) * 0.005 + new_bw/2;
			dy::Float64 = (data[4] - data[3]) * 0.005;
			data[1] -= dx;	data[2] += dx;	data[4] += dy;
			(data[3] != 0) && (data[3] -= dy);
		else
			dx = (data[2] - data[1]) * 0.005
			dy = (data[4] - data[3]) * 0.005 + new_bw/2;
			data[1] = 0.0;	data[2] += dx;	data[3] -= dy;	data[4] += dy;
			(data[1] != 0) && (data[1] -= dx);
		end
		data = round_wesn(data)		# Add a pad if not tight
		new_opt_R = @sprintf(" -R%.15g/%.15g/%.15g/%.15g", data[1], data[2], data[3], data[4])
		cmd = replace(cmd, opt_R => new_opt_R)
		(is_waterfall) && (cmd2 *= CTRL.pocket_J[1] * new_opt_R)
	end
	(is_waterfall && got_usr_R) && (cmd2 *= CTRL.pocket_J[1] * CTRL.pocket_R[1])
	return cmd, _argD, cmd2
end

# ---------------------------------------------------------------------------------------------------
function recompute_R_4bars!(cmd::String, opt_R::String, arg1)
	# Recompute the -R for bar plots (non-grouped), taking into account the width embeded in option S
	opt_S = scan_opt(cmd, "-S")
	opt_S == "" && return cmd				# Nothing to do
	sub_b = ((ind = findfirst("+", opt_S)) !== nothing) ? opt_S[ind[1]:end] : ""	# The +Base modifier
	(sub_b != "") && (opt_S = opt_S[1:ind[1]-1])# Strip it because we need to (re)find Bar width
	bw = (isletter(opt_S[end])) ? parse(Float64, opt_S[3:end-1]) : parse(Float64, opt_S[2:end])	# Bar width
	info = gmt("gmtinfo -C", arg1)
	dx::Float64 = (info.data[2] - info.data[1]) * 0.005 + bw/2;
	dy::Float64 = (info.data[4] - info.data[3]) * 0.005;
	info.data[1] -= dx;	info.data[2] += dx;	info.data[4] += dy;
	info.data = round_wesn(info.data)		# Add a pad if not-tight
	new_opt_R::String = @sprintf(" -R%.15g/%.15g/%.15g/%.15g", info.data[1], info.data[2], 0, info.data[4])
	cmd = replace(cmd, opt_R => new_opt_R)
end

# ---------------------------------------------------------------------------------------------------
function get_sizes(arg)::Tuple{Int,Int}
	(!isGMTdataset(arg)) && error("Input can only be a GMTdataset(s), not $(typeof(arg))")
	if     (isa(arg, Vector{<:GMTdataset}))  n_rows, n_col = size(arg[1])
	else                                     n_rows, n_col = size(arg)
	end
	return n_rows, n_col
end

# ---------------------------------------------------------------------------------------------------
function make_color_column(d::Dict, cmd::String, opt_i::String, len_cmd::Int, N_args::Int, n_prev::Int, is3D::Bool, got_Ebars::Bool, bar_ok::Bool, bar_fill, arg1, arg2)
	# See if we got a CPT. If yes, there is quite some work to do if no color column provided in input data.
	# N_ARGS will be == n_prev+1 when a -Ccpt was used. Otherwise they are equal.

	mz, the_kw = find_in_dict(d, [:zcolor :markerz :mz :level])
	no_mz = (the_kw === Symbol())			# Means, no zcolor request 
	if ((!(N_args > n_prev || len_cmd < length(cmd)) && no_mz) && !bar_ok)		# No color request, so return right away
		return cmd, arg1, arg2, N_args, false
	end

	# Filled polygons with -Z don't need extra col
	((val = hlp_desnany_str(d, [:G :fill], false)) == "+z") && return cmd, arg1, arg2, N_args, false

	n_rows, n_col = get_sizes(arg1)		# Deal with the matrix, DS & Vec{DS} cases
	(isa(mz, Bool) && mz) && (mz = collect(1:n_rows))

	if ((!no_mz && length(mz)::Int != n_rows) || (no_mz && opt_i != ""))
		warn1 = string("Probably color column in '", the_kw, "' has incorrect dims (", length(mz), " vs $n_rows). Ignoring it.")
		warn2 = "Plotting with color table requires adding one more column to the dataset but your 'incols'
		option didn't do it, so you won't get what you expect. Try incols=\"0-1,1\" for 2D or \"=0-2,2\" for 3D plots"
		(!no_m) ? @warn(warn1) : @warn(warn2)
		return cmd, arg1, arg2, N_args, true
	end

	if (!isempty(bar_fill))
		if (isa(arg1,GMTdataset))
			add2ds!(arg1, 1:n_rows; name="Zcolor")
		else	# Must be a Vector{<:GMTdataset}, otherwise errors
			for k = 1:numel(arg1)  add2ds!(arg1[k], 1:n_rows; name="Zcolor")  end		# Will error if the n_rows varies
		end
		arg2::GMTcpt = gmt(string("makecpt -T1/$(n_rows+1)/1 -C" * join(bar_fill, ",")))
		CURRENT_CPT[1] = arg2
		(!occursin(" -C", cmd)) && (cmd *= " -C")	# Need to inform that there is a cpt to use
		find_in_dict(d, [:G :fill])					# Deletes the :fill. Not used anymore
		return cmd, arg1, arg2, 2, true
	end

	make_color_column_(d, cmd, len_cmd, N_args, n_prev, is3D, got_Ebars, arg1, arg2, !no_mz, mz, n_col)
end

# ---------------------------------------------------------------------------------------------------
function make_color_column_(d::Dict, cmd::String, len_cmd::Int, N_args::Int, n_prev::Int, is3D::Bool, got_Ebars::Bool, arg1, arg2, have_mz, mz, n_col::Int)
	# Broke this out of make_color_column() to try to limit effect of invalidations but with questionable results.
	if (n_col <= 2+is3D)
		if (have_mz)
			if (isa(arg1,GMTdataset))
				add2ds!(arg1, mz; name="Zcolor")
			elseif (isa(arg1, Vector{<:GMTdataset}))
				for k = 1:numel(arg1)  add2ds!(arg1[k], mz; name="Zcolor")  end		# Will error if the n_rows varies
			end
		else
			cmd *= " -i0-$(1+is3D),$(1+is3D)"
			if ((val = find_in_dict(d, [:markersize :ms :size], false)[1]) !== nothing && isa(val, Vector))
				cmd *= "-$(2+is3D)"		# Because we know that an extra col will be added later
			end
		end
	else
		if (have_mz)				# Here we must insert the color col right after the coords
			if (isa(arg1,GMTdataset))
				add2ds!(arg1, mz, 3+is3D; name="Zcolor")
			elseif (isa(arg1, Vector{<:GMTdataset}))
				for k = 1:numel(arg1)  add2ds!(arg1[k], mz, 3+is3D; name="Zcolor")  end		# Will error if the n_rows varies
			end
		elseif (got_Ebars)				# The Error bars case is very multi. Don't try to guess then.
			cmd *= " -i0-$(1+is3D),$(1+is3D),$(2+is3D)-$(n_col-1)"
		end
	end

	if (N_args == n_prev)				# No cpt transmitted, so need to compute one
		if (have_mz)   mi::Float64, ma::Float64 = extrema(mz)
		else
			the_col = min(n_col,3)+is3D
			(the_col > n_col) && (the_col = n_col)	# Shitty logic before may have lead to this need.
			got_Ebars && (the_col -= 1)				# Bars => 2 cols
			if   (isa(arg1, Vector{<:GMTdataset}))  mi, ma = arg1[1].ds_bbox[2the_col-1:2the_col]
			else                                    mi, ma = arg1.ds_bbox[2the_col-1:2the_col]
			end
		end
		just_C = cmd[len_cmd+2:end];	reset_i = ""
		if ((ind = findfirst(" -i", just_C)) !== nothing)
			reset_i = just_C[ind[1]:end]
			just_C  = just_C[1:ind[1]-1]
		end
		arg2 = gmt(string("makecpt -T", mi-0.001*abs(mi), '/', ma+0.001*abs(ma), " ", just_C) * (IamModern[1] ? " -H" : ""))
		CURRENT_CPT[1] = arg2
		if (occursin(" -C", cmd))  cmd = cmd[1:len_cmd+3]  end		# Strip the cpt name
		if (reset_i != "")  cmd *= reset_i  end		# Reset -i, in case it existed

		(!occursin(" -C", cmd)) && (cmd *= " -C")	# Need to inform that there is a cpt to use
		N_args = 2
	end

	return cmd, arg1, arg2, N_args, true
end

# ---------------------------------------------------------------------------------------------------
function get_marker_name(d::Dict, arg1, symbs::Vector{Symbol}, is3D::Bool, del::Bool=true)
	marca::String = "";		N = 0
	for symb in symbs
		if (haskey(d, symb))
			t = d[symb]
			if (isa(t, Tuple))				# e.g. marker=(:r, [2 3])
				msg = "";	cst = false
				opt = ""	# Probably this defaut value is never used but avoids compiling helper_markers(opt,) with a non def var
				o::String = string(t[1])
				if     (startswith(o, "E"))  opt = "E";  N = 3; cst = true
				elseif (startswith(o, "e"))  opt = "e";  N = 3
				elseif (o == "J" || startswith(o, "Rot"))  opt = "J";  N = 3; cst = true
				elseif (o == "j" || startswith(o, "rot"))  opt = "j";  N = 3
				elseif (o == "M" || startswith(o, "Mat"))  opt = "M";  N = 3
				elseif (o == "m" || startswith(o, "mat"))  opt = "m";  N = 3
				elseif (o == "R" || startswith(o, "Rec"))  opt = "R";  N = 3
				elseif (o == "r" || startswith(o, "rec"))  opt = "r";  N = 2
				elseif (o == "V" || startswith(o, "Vec"))  opt = "V";  N = 2
				elseif (o == "v" || startswith(o, "vec"))  opt = "v";  N = 2
				elseif (startswith(o, "geovec"))  opt = "=";  N = 2
				elseif (o == "w" || o == "pie" || o == "web" || o == "wedge")  opt = "w";  N = 2
				elseif (o == "W" || o == "Pie" || o == "Web" || o == "Wedge")  opt = "W";  N = 2
				end
				if (N > 0)  marca, arg1, msg = helper_markers(opt, t[2], arg1, N, cst)  end
				(msg != "") && error(msg)
				if (length(t) == 3 && isa(t[3], NamedTuple))
					if (marca == "w" || marca == "W")	# Ex (spiderweb): marker=(:pie, [...], (inner=1,))
						marca *= add_opt(t[3], (inner="/", arc="+a", radial="+r", size=("", arg2str, 1), pen=("+p", add_opt_pen)) )
					elseif (marca == "m" || marca == "M" || marca == "=")
						marca *= vector_attrib(t[3])
					end
				end
			elseif (isa(t, NamedTuple))		# e.g. marker=(pie=true, inner=1, ...)
				key = keys(t)[1];	opt = ""
				if     (key == :w || key == :pie || key == :web || key == :wedge)  opt = "w"
				elseif (key == :W || key == :Pie || key == :Web || key == :Wedge)  opt = "W"
				elseif (key == :b || key == :bar)     opt = "b"
				elseif (key == :B || key == :HBar)    opt = "B"
				elseif (key == :l || key == :letter)  opt = "l"
				elseif (key == :K || key == :Custom)  opt = "K"
				elseif (key == :k || key == :custom)  opt = "k"
				elseif (key == :M || key == :Matang)  opt = "M"
				elseif (key == :m || key == :matang)  opt = "m"
				elseif (key == :geovec)  opt = "="
				end
				if (opt == "w" || opt == "W")
					marca = opt * add_opt(t, (size=("", arg2str, 1), inner="/", arc="+a", radial="+r", pen=("+p", add_opt_pen)))
				elseif (opt == "b" || opt == "B")
					marca = opt * add_opt(t, (size=("", arg2str, 1), base="+b", Base="+B"))
				elseif (opt == "l")
					marca = opt * add_opt(t, (size=("", arg2str, 1), letter="+t", justify="+j", font=("+f", font)))
				elseif (opt == "m" || opt == "M" || opt == "=")
					marca = opt * add_opt(t, (size=("", arg2str, 1), arrow=("", vector_attrib)))
				elseif (opt == "k" || opt == "K")
					marca = opt * add_opt(t, (custom="", size="/"))
				end
			else
				t1::String = string(t)
				(t1[1] != 'T') && (t1 = lowercase(t1))
				if     (t1 == "-" || t1 == "x-dash")    marca = "-"
				elseif (t1 == "+" || t1 == "plus")      marca = "+"
				elseif (t1 == "a" || t1 == "*" || t1 == "star")  marca = "a"
				elseif (t1 == "k" || t1 == "custom")    marca = "k"
				elseif (t1 == "x" || t1 == "cross")     marca = "x"
				elseif (is3D && (t1 == "u" || t1 == "cube"))  marca = "u"	# Must come before next line
				elseif (t1[1] == 'c')                   marca = "c"
				elseif (t1[1] == 'd')                   marca = "d"		# diamond
				elseif (t1 == "g" || t1 == "octagon")   marca = "g"
				elseif (t1[1] == 'h')                   marca = "h"		# hexagon
				elseif (t1 == "i" || t1 == "inverted_tri")  marca = "i"
				elseif (t1[1] == 'l')                   marca = "l"		# letter
				elseif (t1 == "n" || t1 == "pentagon")  marca = "n"
				elseif (t1 == "p" || t1 == "." || t1 == "point")  marca = "p"
				elseif (t1[1] == 's')                   marca = "s"		# square
				elseif (t1[1] == 't' || t1 == "^")      marca = "t"		# triangle
				elseif (t1[1] == 'T')                   marca = "T"		# Triangle
				elseif (t1[1] == 'y')                   marca = "y"		# y-dash
				elseif (t1[1] == 'f')                   marca = "f"		# for Faults in legend
				elseif (t1[1] == 'q')                   marca = "q"		# for Quoted in legend
				end
				t1 = string(t)		# Repeat conversion for the case it was lower-cased above
				# Still need to check the simpler forms of these
				if (marca == "")  marca = helper2_markers(t1, ["e", "ellipse"])   end
				if (marca == "")  marca = helper2_markers(t1, ["E", "Ellipse"])   end
				if (marca == "")  marca = helper2_markers(t1, ["j", "rotrect"])   end
				if (marca == "")  marca = helper2_markers(t1, ["J", "RotRect"])   end
				if (marca == "")  marca = helper2_markers(t1, ["m", "matangle"])  end
				if (marca == "")  marca = helper2_markers(t1, ["M", "Matangle"])  end
				if (marca == "")  marca = helper2_markers(t1, ["r", "rectangle"])   end
				if (marca == "")  marca = helper2_markers(t1, ["R", "RRectangle"])  end
				if (marca == "")  marca = helper2_markers(t1, ["v", "vector"])  end
				if (marca == "")  marca = helper2_markers(t1, ["V", "Vector"])  end
				if (marca == "")  marca = helper2_markers(t1, ["w", "pie", "web"])  end
				if (marca == "")  marca = helper2_markers(t1, ["W", "Pie", "Web"])  end
			end
			(del) && delete!(d, symb)
			break
		end
	end
	return marca, arg1, N > 0
end

function helper_markers(opt::String, ext, arg1::GMTdataset, N::Int, cst::Bool)
	# Helper function to deal with the cases where one sends marker's extra columns via command
	# Example that will land and be processed here:  marker=(:Ellipse, [30 10 15])
	# N is the number of extra columns
	marca::String = "";	 msg = ""
	if (size(ext,2) == N && arg1 !== nothing)	# Here ARG1 is supposed to be a matrix that will be extended.
		S = Symbol(opt)
		t = arg1.data	# Because we need to passa matrix to this method of add_opt()
		marca, t = add_opt(add_opt, (Dict(S => (par=ext,)), opt, "", [S]), (par="|",), true, t)
		arg1.data = t;		add2ds!(arg1)
	elseif (cst && length(ext) == 1)
		marca = opt * "-" * string(ext)::String
	else
		msg = string("Wrong number of extra columns for marker (", opt, "). Got ", size(ext,2), " but expected ", N)
	end
	return marca, arg1, msg
end

function helper2_markers(opt::String, alias::Vector{String})::String
	marca = ""
	if (opt == alias[1])			# User used only the one letter syntax
		marca = alias[1]
	else
		for k = 2:length(alias)		# Loop because of cases like ["w" "pie" "web"]
			o2 = alias[k][1:min(2,length(alias[k]))]	# check the first 2 chars and Ro, Rotrect or RotRec are all good
			#if (startswith(opt, o2))  marca = alias[1]; break  end		# Good when, for example, marker=:Pie
			if (startswith(opt, o2))	# Good when, for example, marker=:Pie
				marca = alias[1];
				(opt[end] == '-') && (marca *= '-')
				break 
			end
		end
	end

	# If we still have found nothing, assume that OPT is a full GMT opt string (e.g. W/5+a30+r45+p2,red)
	(marca == "" && opt[1] == alias[1][1]) && (marca = opt)
	return marca
end

# ---------------------------------------------------------------------------------------------------
function seek_custom_symb(marca::AbstractString, with_k::Bool=false)::String
	# If 'marca' is a custom symbol, seek it first in GMT.jl share/custom dir.
	# Return the full name of the marker plus extension
	# The WITH_K arg is to allow calling this fun with a sym name already prefaced with 'k', or not
	(with_k && marca[1] != 'k') && return marca		# Not a custom symbol, return what we got.

	function find_this_file(pato, symbname)
		for (root, dirs, files) in walkdir(pato)
			ind = findfirst(startswith.(files, symbname))
			if (ind !== nothing)  return joinpath(root, files[ind])  end
		end
		return ""
	end

	s = split(marca, '/')
	ind_s = with_k ? 2 : 1
	symbname = s[1][ind_s:end]
	cus_path = joinpath(dirname(pathof(GMT))[1:end-4], "share", "custom")

	fullname = find_this_file(cus_path, symbname)
	if (fullname == "")
		cus_path2 = joinpath(GMTuserdir[1], "cache_csymb")
		cus_path2 = replace(cus_path2, "/" => "\\")	# Otherwise it will produce currupted PS
		fullname  = find_this_file(cus_path2, symbname)
	end

	(fullname == "") && return marca		# Assume it's a custom symbol from the official GMT collection.

	_siz  = split(marca, '/')[2]			# The custom symbol size
	_marca = (with_k ? "k" : "")  * fullname * "/" * _siz
	(GMTver <= v"6.4" && (length(_marca) - length(_siz) -2) > 62) && warn("Due to a GMT <= 6.4 limitation the length of full (name+path) custom symbol name cannot be longer than 62 bytes.")
	return _marca
end

# ---------------------------------------------------------------------------------------------------
function check_caller(d::Dict, cmd::String, opt_S::String, opt_W::String, caller::String, g_bar_fill::Vector{String}, O::Bool)::String
	# Set sensible defaults for the sub-modules "scatter" & "bar"
	if (caller == "scatter")
		if (opt_S == "")  cmd *= " -Sc5p"  end
	elseif (caller == "scatter3")
		if (opt_S == "")  cmd *= " -Su2p"  end
	elseif (caller == "lines")
		if (!occursin("+p", cmd) && opt_W == "") cmd *= " -W0.5p"  end # Do not leave without a pen specification
	elseif (caller == "bar")
		if (opt_S == "")
			bar_type = 0
			if (haskey(d, :bar))
				cmd, bar_opts = parse_bar_cmd(d, :bar, cmd, "Sb")
				bar_type = 1;	delete!(d, :bar)
			elseif (haskey(d, :hbar))
				cmd, bar_opts = parse_bar_cmd(d, :hbar, cmd, "SB")
				bar_type = 2;	delete!(d, :hbar)
			end
			if (bar_type == 0 || bar_opts == "")	# bar_opts == "" means only bar=true or hbar=true was used
				val = hlp_desnany_float(d, [:bargap])
				gap = (isnan(val)) ? 0.8 : (val > 1 ? (1.0 - val/100) : (1-val))		# Gap between bars in a group
				opt = (haskey(d, :width)) ? add_opt(d, "", "",  [:width]) : "$gap"	# 0.8 is the default
				_Stype = (bar_type == 2) ? " -SB" : " -Sb"
				cmd *= _Stype * opt * "u"

				optB = (haskey(d, :base)) ? add_opt(d, "", "",  [:base]) : "0"
				cmd *= "+b" * optB
			end
		end
		(isempty(g_bar_fill) && !occursin(" -G", cmd) && !occursin(" -C", cmd)) && (cmd *= " -G0/115/190")	# Default color
	elseif (caller == "bar3")
		if (haskey(d, :noshade) && occursin("-So", cmd))
			cmd = replace(cmd, "-So" => "-SO", count=1);
			delete!(d, :noshade)
		end
		if (!occursin(" -G", cmd) && !occursin(" -C", cmd))  cmd *= " -G0/115/190"	end
		if (!occursin(" -J", cmd))  cmd *= " -JX12c/0"  end
	end

	if (occursin('3', caller))
		(!occursin(" -B", cmd) && !O && (get(POSTMAN[1], "noframe", "") == ""))  && (cmd *= DEF_FIG_AXES3[1])	# For overlays default is no axes
		(get(POSTMAN[1], "noframe", "") != "") && delete!(POSTMAN[1], "noframe")
	end

	return cmd
end

# ---------------------------------------------------------------------------------------------------
function parse_bar_cmd(d::Dict, key::Symbol, cmd::String, optS::String; no_u::Bool=false)::Tuple{String, String}
	# Deal with parsing the 'bar' & 'hbar' keywors of psxy. Also called by plot/bar3. For this
	# later module if input is not a string or NamedTuple the scatter options must be processed in bar3().
	# KEY is either :bar or :hbar
	# OPTS is either "Sb", "SB" or "So"
	# NO_U if true means to NOT automatic adding of flag 'u'
	opt::String = "";	got_str = false
	if (haskey(d, key))
		if (isa(d[key], String))
			opt, got_str = d[key], true
			cmd *= " -" * optS * opt;	delete!(d, key)
		elseif (isa(d[key], NamedTuple))
			opt = add_opt(d, "", optS, [key], (width="",unit="1",base="+b",height="+B",nbands="+z",Nbands="+Z"))
		elseif (isa(d[key], Bool) && d[key])
		else
			error("Argument of the *bar* keyword can be only a string or a NamedTuple.")
		end
	end

	if (opt != "" && !got_str)				# Still need to finish parsing this
		flag_u = no_u ? "" : 'u'
		if ((ind = findfirst("+", opt)) !== nothing)	# See if need to insert a 'u'
			if (!isletter(opt[ind[1]-1]))  opt = opt[1:ind[1]-1] * flag_u * opt[ind[1]:end]  end
		else
			pb = (optS != "So") ? "+b0" : ""		# The default for bar3 (So) is set in the bar3() fun
			if (!isletter(opt[end]))  opt *= flag_u	  end	# No base set so default to ...
			opt *= pb
		end
		cmd *= opt
	end
	return cmd, opt
end

# ---------------------------------------------------------------------------------------------------
function zoom_reactangle(_cmd, isplot::Bool)
	# Generate a rectangle delimiting the zoom on a region of interest plus the connection lines
	# to the inset window. This is used only (so far) from nested inset() call with auto-zoom.
	Rs::String = CTRL.pocket_call[4]	# Don't use it directly because it's a Any
	R = parse.(Float64, split(Rs, "/"))
	l1, l2 = connect_rectangles(R, CTRL.pocket_call[5])
	lc = (isplot) ? "gray" : "black"
	lw = (isplot) ? [0.5, 0.75, 0.75] : [0.5, 0.5, 0.5]
	Drec = mat2ds([[R[1] R[3]; R[1] R[4]; R[2] R[4]; R[2] R[3]; R[1] R[3]], l1, l2], lc=lc,
	              ls=["","dash","dash"], lw=lw)
	put_pocket_call(Drec)				# Store it in CTRL.pocket_call
	ins = pop!(_cmd)					# Remove the inset call
	append!(_cmd, ["psxy -R -J -W0.4p"])
	append!(_cmd, [ins])				# Add the inset call again
	return _cmd
end

# ---------------------------------------------------------------------------------------------------
function faces_normals_view(V::GMTdataset{Float64,2}, F::GMTdataset{Int,2}, view_vec)
	# Compute the dot product between the view vector and the normal of each face
	# Faces whose dot product is <= 0 are not visible
	n_faces = size(F.data, 1)		# Number of segments or faces (polygons)
	n_verts = size(F.data, 2)		# Number of vertices of the polygon
	tmp     = zeros(n_verts, 3)
	proj    = zeros(n_faces)
	for face = 1:n_faces 			# Each row in F (a face) is a new data segment (a polygon)
		for c = 1:3, v = 1:n_verts
			tmp[v,c] = V.data[F.data[face,v], c]
		end
		proj[face] = dot(facenorm(tmp), view_vec, normalize=false)
	end
	return proj
end

# ---------------------------------------------------------------------------------------------------
"""
    FV, projs = sort_visible_faces(FV, azim, elev; del=true) -> Tuple{Vector{GMTdataset}, Vector{Float64}}

Sort faces by distance and optionally delete the invisible ones.

Take a Faces-Vertices dataset and delete the invisible faces from view vector. Next sort them by distance so
that the furthest faces are drawn first and hence do not hide the others. NOTE: to not change the original
FV we store the resultant matix(ces) of faces in a FV0s fiels called "faces_view", which is a vector
of matrices, one for each geometry (e.g. triangles, quadrangles, etc).

### Args
- `FV`: The Faces-Vertices dataset.
- `azim`: Azimuth angle in degrees. Positive clock-wise from North.
- `elev`: Elevation angle in degrees above horizontal plane.

### Kwargs
- `del`: Boolean to control whether to delete invisible faces. True by default. But this can be
  overwriten by the value of the ``bfculling`` member of the FV object.
"""
function sort_visible_faces(FV::Vector{GMTfv}, azim, elev; del::Bool=true)::Tuple{Vector{GMTfv}, Vector{Float64}}
	# This method is for the case when FV is a vector of FV's. The 'projs' here worth nothing and is returned
	# as a empty vector only for simetry with the case when FV is a single FV.
	projs = Float64[]
	for k = 1:numel(FV)
		FV[k], _projs = sort_visible_faces(FV[k], azim, elev; del=del)
		!isempty(_projs) && append!(projs, _projs)
	end
	return FV, projs
end
function sort_visible_faces(FV::GMTfv, azim, elev; del::Bool=true)::Tuple{GMTfv, Vector{Float64}}
	cos_az, cos_el, sin_az, sin_el = cosd(azim), cosd(elev), sind(azim), sind(elev)
	view_vec = [sin_az * cos_el, cos_az * cos_el, sin_el]
	projs = Float64[]

	if (!isempty(FV.color_vwall))
		P::Ptr{GMT_PALETTE} = palette_init(G_API[1], gmt("makecpt -T0/1 -C" * FV.color_vwall));	# A pointer to a GMT CPT
		rgb = [0.0, 0.0, 0.0, 0.0]
	end

	FV.faces_view = Vector{Matrix{Int}}(undef,numel(FV.faces))
	first_face_vis = true
	for k = 1:numel(FV.faces)					# Loop over number of face groups (we can have triangles, quads, etc)
		isPlane = FV.isflat[k]
		have_colorwall = length(FV.color) >= k && !isassigned(FV.color[k], 1) && !isempty(FV.color_vwall)
		needNormals = have_colorwall || (length(FV.color) >= k && isempty(FV.color[k])) 	# No color, no normals
		if (isPlane && !needNormals)			# But there is still a flaw in the 'needNormals' logic
			FV.faces_view[k] = FV.faces[k];
			_tmp = [FV.verts[FV.faces[k][1,v], c] for v = 1:size(FV.faces[k], 2), c = 1:3]
			this_proj = dot(facenorm(_tmp, zfact=FV.zscale), view_vec)
			append!(projs, this_proj)			# But since it has no color and is flat, we need to store the normal.
			continue							# Nothing more to do in this case.
		end
		del = !isPlane && FV.bfculling			# bfculling should become a vector too?
		have_colors = length(FV.color) >= k && !isempty(FV.color[k])	# Does this FV has a color for each polygon?

		n_faces::Int = size(FV.faces[k], 1)		# Number of faces (polygons)
		this_face_nverts::Int = size(FV.faces[k], 2)
		tmp = zeros(this_face_nverts, 3)
		del && (isVisible = fill(false, n_faces))
		dists = NTuple{2,Float64}[]
		_projs = Float64[]
		for face = 1:n_faces					# Loop over the faces of this group
			for c = 1:3, v = 1:this_face_nverts								# Build the polygon from the FV collection
				tmp[v,c] = FV.verts[FV.faces[k][face,v], c]
			end
			this_proj = dot(facenorm(tmp, zfact=FV.zscale), view_vec)
			if (!del || (isVisible[face] = this_proj > 0))
				if (!isPlane)				# Planes do not need sorting
					cx, cy, cz = sum(tmp[:,1]), sum(tmp[:,2]), sum(tmp[:,3])	# Pseudo-centroids. Good enough for sorting
					push!(dists, (cx * sin_az + cy * cos_az, cz * sin_el))
				end
				push!(_projs, this_proj)	# But need the normals as stated at the begining of this function
				if (have_colorwall)
					gmt_get_rgb_from_z(G_API[1], P, this_proj, rgb)
					FV.color[k][face] = @sprintf("-G#%.2x%.2x%.2x", round(Int, rgb[1]*255), round(Int, rgb[2]*255), round(Int, rgb[3]*255)) 
				end
			end
		end

		(have_colorwall) && (FV.color[k] = FV.color[k][isVisible])		# SO FUNCIONA A PRIMEIRA VEZ
		data::Matrix{Integer} = del ? FV.faces[k][isVisible, :] : FV.faces[k]
		isempty(data) && continue			# These 'continues' leave out #undefs in FV.faces_view that need to be deleted
		ind  = sortperm(dists)
		data = data[ind, :]
		FV.faces_view[k] = data
		projs = (first_face_vis) ? _projs[ind] : append!(projs, _projs[ind])
		(have_colors || have_colorwall) && (FV.color[k] = FV.color[k][ind])
		first_face_vis = false
	end

	c = [isassigned(FV.faces_view, k) && !isempty(FV.faces_view[k]) for k = 1:numel(FV.faces_view)]
	!all(c) && (FV.faces_view = FV.faces_view[c])	# Delete eventual #undefs

	vis = sum(size.(FV.faces_view, 1))		# If = 0, it must have been a plane.
	vis > 0 && vis < sum(size.(FV.faces, 1) / 3) &&
		@warn("More than 2/3 of the faces found invisible (actually: $(100 - sum(size.(FV.faces_view, 1)) / sum(size.(FV.faces, 1))*100)%). This often indicates that the Z and X,Y units are not the same. Consider setting `bfculling` to false or use the `nocull=true` option, or using the `zscale` field of the `FV` input.")

	return FV, projs
end

# ---------------------------------------------------------------------------------------------------
"""
	Dv = sort_visible_triangles(Dv::Vector{<:GMTdataset}; del_hidden=false, zfact=1.0) -> Vector{GMTdataset}

Take a Faces-Vertices dataset produced by grid2tri() and sort them by distance so that the furthest faces are
drawn on first and hence do not hide others. Optionally remove the invisible triangles. This not true by default
because we may want to see the inside of a top surface.

`zfact` is a factor use to bring the z units to the same of the x,y units as for example when `z` is in km
and `x` and `y` are in degrees, case in which an automatic projection takes place, or in meters. We need this
if we want that the normal compuations makes sense.
"""
function sort_visible_triangles(Dv::Vector{<:GMTdataset}; del_hidden=false, zfact=1.0)
	azim, elev = parse.(Float64, split(CURRENT_VIEW[1][4:end], '/'))
	sin_az, cos_az, sin_el = sind(azim), cosd(azim), sind(elev)
	prj, wkt, epsg = Dv[1].proj4, Dv[1].wkt, Dv[1].epsg
	top_comment = Dv[1].comment		# save this for later restore as it can be used by tri_z() to detect vertical walls

	(del_hidden != 1 && contains(Dv[1].comment[1], "vwall")) && (del_hidden = true)	# If have vwalls, need to del invis
	if (del_hidden == 1)		# Remove the triangles that are not visible from the normal view_vec
		bak_view = CURRENT_VIEW[1]	# Save because mapproject will reset it to "" (parsing on a module that has first = true)
		t = isgeog(Dv) ? mapproject(Dv, J="t$((Dv[1].ds_bbox[1] + Dv[1].ds_bbox[2])/2)/1:1", C=true, F=true) : Dv
		CURRENT_VIEW[1] = bak_view 
		view_vec = [sin_az * cosd(elev), cos_az * cosd(elev), sin_el]
		is_vis = [dot(facenorm(t[k].data, zfact=zfact, normalize=false), view_vec) > 0 for k in eachindex(t)]
		Dv = Dv[is_vis]
	end

	# ---------------------- Now sort by distance to the viewer ----------------------
	Dc = gmtspatial(Dv, Q=true, o="0,1")	# Should this directly in Julia and avoid calling GMT (=> a copy of Dv)
	dists = [(Dc.data[1,1] * sin_az + Dc.data[1,2] * cos_az, (Dv[1].bbox[5] + Dv[1].bbox[6]) / 2 * sin_el)]
	for k = 2:size(Dc, 1)
		push!(dists, (Dc.data[k,1] * sin_az + Dc.data[k,2] * cos_az, (Dv[k].bbox[5] + Dv[k].bbox[6]) / 2 * sin_el))
	end

	ind = sortperm(dists)			# Sort in growing distances.
	Dv = Dv[ind]
	set_dsBB!(Dv)
	Dv[1].proj4 = prj; Dv[1].wkt = wkt; Dv[1].epsg = epsg	# Because first triangle may have been deleted or reordered.
	Dv[1].comment = top_comment		# Restore the original comment that holds info abot this gridtri dataset
	return Dv
end

#= ---------------------------------------------------------------------------------------------------
function tri_normals(Dv::Vector{<:GMTdataset}; zfact=1.0)
	t = isgeog(Dv) ? mapproject(Dv, J="t$((Dv[1].ds_bbox[1] + Dv[1].ds_bbox[2])/2)/1:1", C=true, F=true) : Dv
	Dc = gmtspatial(Dv, Q=true)
	nx = Vector{Float64}(undef, length(t)); ny = copy(nx); nz = copy(nx)
	for k in eachindex(t)
		nx[k], ny[k], nz[k] = facenorm(t[k].data; zfact=zfact)
		Dc.data[k,3] = (t[k].bbox[5] + t[k].bbox[6]) / 2	# Reuse the area column to store the triangle mean height
	end
	return Dc, nx, ny, nz
end

# ---------------------------------------------------------------------------------------------------
function quiver3(Dv::Vector{<:GMTdataset}; first=true, zfact=1.0, kwargs...)
	Dc, nx, ny, nz = tri_normals(Dv, zfact=zfact)
	mat = fill(NaN, size(Dc,1) * 3 - 1, 3)
	for k in eachindex(Dv)
		kk = (k-1) * 3
		mat[kk+=1,1], mat[kk,2], mat[kk,3] = Dc.data[k,1], Dc.data[k,2], Dc.data[k,3]
		mat[kk+=1,1], mat[kk,2], mat[kk,3] = Dc.data[k,1]+nx[k]/2, Dc.data[k,2]+ny[k]/2, Dc.data[k,3]+nz[k]/2
	end
	D = mat2ds(mat, geom=wkbLineStringZ)
	common_plot_xyz("", D, "plot3d", first, true, kwargs...)
end
=#

# ---------------------------------------------------------------------------------------------------
"""
    replicant(FV; kwargs...) -> Vector{GMTdataset}

Take a Faces-Vertices dataset describing a 3D body and replicate it N number of times with the option of
assigning different colors and scales to each copy. The end result is a single Vector{GMTdataset} with
the replicated body.

### Args
- `FV`: A Faces-Vertices dataset describing a 3D body.

### Kwargs
- `replicate`: A NamedTuple with one or more of the following fields: `centers`, a Mx3 Matrix with the centers of the copies;
  `zcolor`, a vector of length ``size(centers, 1)``, specifying a variable that will be used together with the `cmap`
  option to assign a color of each copy (default is the ``1:size(centers, 1)``); `cmap`, a GMTcpt object; `scales`,
  a scalar or a vector of ``size(centers, 1)``, specifying the scale factor of each copy.
- `replicate`: A Mx3 Matrix with the centers of the each copy.
- `replicate`: A Tuple with a Matrix and a scalar or a vector. The first element is the centers Mx3 matrix and the
   second is the scale factor (or vector of factors).
- `scales`: Scale the copies by this factor, or vector of scales (same length as number of copies)
- `view or perspective`: Set the view angle for the replication. The default is `217.5/30`. Surface elements
   that are not visible from this persective are eliminated.

### Returns
A Vector{GMTdataset} with the replicated body. Normally, a triangulated surface.

### Examples
```julia
FV = sphere();
D  = replicant(FV, replicate=(centers=rand(10,3), scales=0.1));

or, to plot them

viz(FV, replicate=(centers=rand(10,3)*10, scales=0.1))
```
"""
function replicant(FV::GMTfv; kwargs...)		# For direct calls to replicat()
	d = KW(kwargs)
	(is_in_dict(d, [:p :view :perspective]) === nothing) && (CURRENT_VIEW[1] = " -p217.5/30")
	replicant(FV, d)
end

# ---------------------------------------------------------------------------------------------------
function replicant(FV::GMTfv, d::Dict{Symbol, Any})
	(val = find_in_dict(d, [:replicate])[1]) === nothing && error("Can't replicate without the 'replicate' option")

	cpt::GMTcpt = GMTcpt()
	if (isa(val, NamedTuple))
		((xyz = get(val, :centers, nothing)) === nothing) && error("Can't replicate without centers")
		_xyz::Matrix{<:Real} = (promote_type(eltype(FV.verts), eltype(xyz))).(xyz)	# Attempt to not have auto promotions to Float64
		((zcolor = get(val, :zcolor, nothing)) === nothing) && (zcolor = collect(1.0:size(xyz, 1)))
		cpt = get(val, :cmap, GMTcpt())
		isempty(cpt) && (cpt = get(val, :C, GMTcpt()))
		isempty(cpt) && (cpt = get(val, :color, GMTcpt()))
		scales = get(val, :scales, nothing)				# Scales can be a nothing or a number or a vector
		(scales === nothing) && (scales = get(val, :scale, nothing))	# Try also 'scale'
	elseif (isa(val, Matrix{<:Real}))					# User just passed replicate=centers
		_xyz = (promote_type(eltype(FV.verts), eltype(val))).(val)
		zcolor = collect(1.0:size(_xyz, 1))
		scales = one(eltype(FV.verts))
	elseif (isa(val, Tuple{Matrix{<:Real}, Union{Real, Vector{<:Real}}}))	# User passed replicate=(centers, scales)
		_xyz = (promote_type(eltype(FV.verts), eltype(val[1]))).(val[1])
		zcolor = collect(1.0:size(_xyz, 1))
		scales = val[2]
	else
		error("Unexpected 'replicate' option")
	end

	if (scales !== nothing)
		(length(scales) == 1) && (scales = fill(scales, length(zcolor)))
		@assert length(scales) == length(zcolor)
	end

	_scales = (scales === nothing) ? fill(one(eltype(FV.verts)), length(zcolor)) :		# Try to make _scales the same type as the V points
	          (eltype(scales) == Float64 && eltype(FV.verts) == Float32) ? Float32.(scales) : scales
	(length(_scales) == 1) && (_scales = fill(scales, length(zcolor)))

	# If no CPT, make one
	(isempty(cpt)) && (cpt = gmt("makecpt -T1/$(length(zcolor))"))

	azim, elev = get_numeric_view()
	replicant_worker(FV, _xyz, azim, elev, zcolor, cpt, _scales)
end

# ---------------------------------------------------------------------------------------------------
function replicant_worker(FV::GMTfv, xyz, azim, elev, cval, cpt, scales)
	# This guy is the one who does the replicant work

	FV, normals = sort_visible_faces(FV, azim, elev)	# Return a modified FV containing info about the sorted visible faces.

	n_faces_tot = sum(size.(FV.faces_view, 1))			# Total number of segments or faces (polygons)

	# ---------- First we convert the FV into a vector of GMTdataset
	t = zeros(eltype(FV.verts), maximum(size.(FV.faces_view,2)), 3)	# The maximum number of vertices in any polygon of all geometries
	D1 = Vector{GMTdataset{eltype(t),2}}(undef, n_faces_tot)
	count_face = 0

	for geom = 1:numel(FV.faces_view)					# If we have more than one type of geometries (e.g. triangles and quadrangles)
		n_faces = size(FV.faces_view[geom], 1)			# Number of segments or faces (polygons) in this geometry
		n_rows  = size(FV.faces_view[geom], 2)			# Number of rows (vertices of the polygon) in this geometry
		for face = 1:n_faces							# Loop over faces
			count_face += 1								# Counter that keeps track on the current number of polygon. 
			for c = 1:3, r = 1:n_rows
				t[r,c] = FV.verts[FV.faces_view[geom][face, r], c]
			end
			D1[count_face] = GMTdataset(data=copy(t))
		end
	end

	P::Ptr{GMT_PALETTE} = palette_init(G_API[1], cpt)	# A pointer to a GMT CPT
	rgb = [0.0, 0.0, 0.0, 0.0]
	cor = [0.0, 0.0, 0.0]
	D2 = Vector{GMTdataset{promote_type(eltype(xyz), eltype(scales), eltype(t)),2}}(undef, size(xyz, 1) * n_faces_tot)

	# ---------- Now we do the replication
	for k = 1:size(xyz, 1)								# Loop over number of positions. For each of these we have a new body
		gmt_get_rgb_from_z(G_API[1], P, cval[k], rgb)
		for face = 1:n_faces_tot						# Loop over number of faces of the base body
			cor[1], cor[2], cor[3] = rgb[1], rgb[2], rgb[3]
			gmt_illuminate(G_API[1], normals[face], cor)
			txt = @sprintf("-G%.0f/%.0f/%.0f", cor[1]*255, cor[2]*255, cor[3]*255)
			D2[(k-1)*n_faces_tot+face] = GMTdataset(data=(D1[face].data * scales[k] .+ xyz[k:k,1:3]), header=txt)
		end
	end
	return set_dsBB(D2)
end
