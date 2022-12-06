"""
	subplot(fim=nothing; kwargs...)

Manage figure subplot configuration and selection.

Full option list at [`subplot`](http://docs.generic-mapping-tools.org/latest/subplot.html)

Parameters
----------

- **grid** :: [Type => Str | Tuple | Array]

    Specifies the number of rows and columns of subplots. Ex grid=(2,3)
- **F** | **dims** | **dimensions** | **size** | **sizes** :: [Type => Str | Tuple, NamedTuple]

    Specify the dimensions of the figure.
    [`-F`](http://docs.generic-mapping-tools.org/latest/subplot.html#f)
- **A** | **autolabel** | **fixedlabel** :: [Type => Str | number]

    Specify automatic tagging of each subplot. This sets the tag of the first, top-left subplot and others follow sequentially.
    [`-A`](http://docs.generic-mapping-tools.org/latest/subplot.html#a)
- $(GMT._opt_B)
- **C** | **clearance** :: [Type => Str | number]

    Reserve a space of dimension clearance between the margin and the subplot on the specified side. Settings specified under **begin** directive apply to all panels.
    [`-C`](http://docs.generic-mapping-tools.org/latest/subplot.html#c)
- $(GMT._opt_J)
- **M** | **margin** | **margins** :: [Type => Str]

    The margin space that is added around each subplot beyond the automatic space allocated for tick marks, annotations, and labels.
    [`-M`](http://docs.generic-mapping-tools.org/latest/subplot.html#m)
- $(GMT._opt_R)
- **SC** | **SR** | **col_axes** | **row_axes** :: [Type => Str | NamedTuple]

    Set subplot layout for shared axes. Set separately for rows (SR) and columns (SC).
    [`-S`](http://docs.generic-mapping-tools.org/latest/subplot.html#s)
- **T** | **title** :: [Type => Str]

    While individual subplots can have titles, the entire figure may also have a overarching title.
    [`-T`](http://docs.generic-mapping-tools.org/latest/subplot.html#t)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
"""
function subplot(fim=nothing; stop=false, kwargs...)

	FirstModern[1] = true			# To know if we need to compute -R in plot. Due to a GMT6.0 BUG
 
	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode

	# In case :title exists we must use and delete it to avoid double parsing
	cmd = ((val = find_in_dict(d, [:T :title])[1]) !== nothing) ? " -T\"" * val * "\"" : ""
	val_grid = find_in_dict(d, [:grid])[1]		# Must fish this one right now because parse_B also looks for (another) :grid
	cmd, = parse_BJR(d, cmd, "", false, " ")
	cmd, = parse_common_opts(d, cmd, [:params], true)
	cmd  = parse_these_opts(cmd, d, [[:M :margin :margins]])
	cmd  = add_opt(d, cmd, "A", [:A :autolabel],
                  (Anchor=("+J", arg2str), anchor=("+j", arg2str), label="", clearance=("+c", arg2str), fill=("+g", add_opt_fill), pen=("+p", add_opt_pen), offset=("+o", arg2str), roman="_+r", Roman="_+R", vertical="_+v"))
	cmd = add_opt(d, cmd, "SC", [:SC :col_axes :colaxes :sharex],
	              (top=("t", nothing, 1), bott=("b", nothing, 1), bottom=("b", nothing, 1), label="+l", grid=("+w", add_opt_pen)))
	cmd = add_opt(d, cmd, "SR", [:SR :row_axes :rowaxes :sharey],
	              (left=("l", nothing, 1), right=("r", nothing, 1), label="+l", parallel="_+p", row_title="_+t", top_row_title="_+tc", grid=("+w", add_opt_pen)))
	opt_C = add_opt(d, "", "", [:C :clearance],
				  (left=(" -Cw", arg2str), right=(" -Ce", arg2str), bott=(" -Cs", arg2str), bottom=(" -Cs", arg2str), top=(" -Cn", arg2str)))
	cmd = add_opt(d, cmd, "Fs", [:Fs :panels_size :panel_size :panel_sizes])
	cmd = add_opt(d, cmd, "Ff", [:Ff :splot_size])

	if ((val = find_in_dict(d, [:F :dims :dimensions :size :sizes], false)[1]) !== nothing || show_kwargs[1])
		if (isa(val, NamedTuple) && haskey(nt2dict(val), :width))	# Preferred way
			cmd *= " -F" * helper_sub_F(val)		# VAL = (width=x, height=x, fwidth=(...), fheight=(...))
			del_from_dict(d, [:F, :dims, :dimensions, :size, :sizes])
		else
			cmd = add_opt(d, cmd, "F", [:F :dims :dimensions :size :sizes],
			              (panels=("-s", helper_sub_F, 1), figsize=("_f", helper_sub_F, 1), size=("", helper_sub_F, 2), sizes=("", helper_sub_F, 2), frac=("+f", helper_sub_F), fractions=("+f", helper_sub_F), clearance=("+c", arg2str), outine=("+p", add_opt_pen), fill=("+g", add_opt_fill), divlines=("+w", add_opt_pen)))
		end
	end

	do_set = false;		do_show = false
	if (fim !== nothing)
		t = lowercase(string(fim))
		if     (t == "end" || t == "stop")  stop = true
		elseif (t == "show")  stop, do_show = true, true
		elseif (t == "set")   do_set = true
		end
	elseif (haskey(d, :show) && d[:show] != 0)					# Let this form work too
		do_show, stop = true, true
	else
		if (!stop && length(kwargs) == 0)  stop = true  end		# To account for the subplot() call case
	end
	# ------------------------------ End parsing inputs --------------------------------

	if (!stop && !do_set)
		(val_grid === nothing) && error("SUBPLOT: 'grid' keyword is mandatory")
		cmd = arg2str(val_grid, 'x') * " " * cmd * opt_C		# Also add the eventual global -C clearance option
		cmd = guess_panels_size(cmd, val_grid)					# For limitted grid dims, guess panel sizes if not provided
		(dbg_print_cmd(d, cmd) !== nothing) && return cmd		# Vd=2 cause this return

		if (!IamModern[1])			# If we are not in modern mode, issue a gmt("begin") first
			# Default name (GMTplot.ps) is set in gmt_main()
			fname = ((val_ = find_in_dict(d, [:fmt])[1]) !== nothing) ? string("GMTplot ", val_) : ""
			if ((val_ = find_in_dict(d, [:figname :name :savefig])[1]) !== nothing)
				fname = get_format(string(val_), nothing, d)		# Get the fig name and format.
			end
			gmt("begin " * fname)
			IamModernBySubplot[1] = true	# We need this to know if subplot(:end) should call gmtend() or not
		end
		try
			gmt("subplot begin " * cmd);
			# This is the most strange. For some reason the annot font of first panel is slightly different from the
			# others WHEN the first plot does not have the -c option (iplicitly -c0). If it has, then they are equal
			# but equal to others than first. Oddly, running the gmtset, which should be doing nothing because the
			# map type is already 'fancy' by default, seems to solve this issue.
			gmt("gmtset  MAP_FRAME_TYPE fancy")
		catch; resetGMT()
		end
		IamSubplot[1], IamModern[1] = true, true
	elseif (do_set)
		(!IamSubplot[1]) && error("Cannot call subplot(set, ...) before setting dimensions")
		_, pane = parse_c(d, cmd)
		cmd = pane * cmd				# Here we don't want the "-c" part
		cmd = add_opt(d, cmd, "A", [:fixedlabel]) * opt_C			# Also add the eventual this panel -C clearance option
		if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end		# Vd=2 cause this return
		gmt("subplot set " * cmd)
	else
		if (IamModernBySubplot[1])
			IamModernBySubplot[1] = false
			show = (do_show || haskey(d, :show)) ? " show" : ""
			helper_showfig4modern(show)
		else
			gmt("subplot end");	IamSubplot[1] = false
		end
	end
	return nothing
end

# --------------------------------------------------------------------------
function guess_panels_size(cmd, opt)
	(contains(cmd, " -F")) && return cmd	# Ok, Ok panel sizes provided

	if (isa(opt, String))
		((ind = findfirst('x', opt)) === nothing) && error("'grid' option does not have the form NxM (misses the 'x'")
		n_rows, n_cols = parse(Int, opt[1:ind-1]), parse(Int, opt[ind+1:end])
	else
		n_rows, n_cols = opt[1], opt[2]
	end
	F = ""
	if     (n_cols == 3)  F = " -Fs6/6";	M = " -M0.2c/0.2c"
	elseif (n_cols > 3 && n_cols == n_rows) F = " -Fs$(n_cols/20)/$(n_cols/20)";	M = " -M0.15c/0.15c"
	elseif (n_rows == 2 && n_cols == 2)     F = " -Fs8/8";	M = " -M0.3c/0.2c"
	elseif (n_rows == 1)
		if     (n_cols == 2)  F = " -Fs8/8";	M = " -M0.3c" 
		elseif (n_cols == 3)  F = " -Fs6/6";	M = " -M0.3c" 
		elseif (n_cols == 4)  F = " -Fs5/5";	M = " -M0.2c" 
		end
	elseif (n_cols == 1)
		if     (n_rows == 2)  F = " -Fs12/8";	M = " -M0.3c"
		elseif (n_rows == 3)  F = " -Fs12/6";	M = " -M0.3c"
		elseif (n_rows == 4)  F = " -Fs12/5";	M = " -M0.2c"
		elseif (5 <= n_rows <= 7)  F = " -Fs12/4";	M = " -M0.15c"
		end
	end
	(F == "") && error("No panels/fig size provided and the grid panels dimension is not within the subset that we guess for")
	!contains(cmd, " -M") && (cmd *= M)		# No margins provided. Use our poor guess.
	cmd *= F
end

# --------------------------------------------------------------------------
function helper_sub_F(arg, dumb=nothing)::String
	# dims=(1,2)
	# dims=(panels=(1,2), frac=((2,3),(3,4,5)))
	# dims=(width=xx, height=yy, fwidth=(), fheight=(), fill=:red, outline=(3,:red))
	out::String = ""
	if (isa(arg, String))
		out = arg2str(arg)
	elseif (isa(arg, NamedTuple) || isa(arg, Dict) || isa(arg, Tuple{Tuple, Tuple}) || isa(arg, Tuple{Tuple, Number}))
		d = mura_arg(arg)
		if ((val = find_in_dict(d, [:panels])[1]) !== nothing)
			if (isa(val, Tuple{Tuple, Tuple}))		# ex: dims=(panels=((2,4),(2.5,5,1.25)),)
				out *= arg2str(val[1], ',') * '/' * arg2str(val[2], ',')
			else
				out = arg2str(val)
			end
		end
		if ((val = find_in_dict(d, [:frac :fractions])[1]) !== nothing)		# ex: dims=(frac=((2,3),(3,4,5)))
			!isa(val, Tuple{Tuple, Tuple}) && error("'frac' option must be a tuple(tuple, tuple)")
			out *= arg2str(val[1], ',') * '/' * arg2str(val[2], ',')			
		end
		if (haskey(d, :width))
			out *= string(d[:width], '/')
			out = (!haskey(d, :height)) ? string(out, d[:width]) : string(out, d[:height])
		end
		if (haskey(d, :fwidth))
			out *= "+f" * arg2str(d[:fwidth], ',')
			(!haskey(d, :fheight)) && error("SUBPLOT: when using 'fwidth' must also set 'fheight'")
			out *= '/' * arg2str(d[:fheight], ',')
		end
		if ((val = find_in_dict(d, [:fill], false)[1]) !== nothing)  out *= "+g" * add_opt_fill(val)  end
		if ((val = find_in_dict(d, [:clearance], false)[1]) !== nothing)  out *= "+c" * arg2str(val)  end
		if (haskey(d, :outline))   out *= "+p" * add_opt_pen(d, [:outline])  end
		if (haskey(d, :divlines))  out *= "+w" * add_opt_pen(d, [:divlines]) end
	elseif (isa(arg, Tuple))		# Hopefully only for the "dims=(panels=(xsize, ysize),)"
		out = arg2str(arg)
	end
	(out == "") && error("SUBPLOT: garbage in DIMS option")
	return out
end

# --------------------------------------------------------------------------
function mura_arg(arg)::Dict
	# Barrier function to contain a possible type instability
	if (isa(arg, Tuple{Tuple, Real}))  arg = (arg[1], (arg[2],))  end	# This looks terribly type instable
	# Need first case because for example dims=(panels=((2,4),(2.5,5,1.25)),) shows up here only as
	# arg = ((2, 4), (2.5, 5, 1.25)) because this function was called from within add_opt()
	if (isa(arg, Tuple{Tuple, Tuple}))  d = Dict(:panels => arg)
	else                                d = (isa(arg, NamedTuple)) ? nt2dict(arg) : arg
	end
	d
end