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
- $(GMT.opt_B)
- **C** | **clearance** :: [Type => Str | number]

    Reserve a space of dimension clearance between the margin and the subplot on the specified side. Settings specified under **begin** directive apply to all panels.
    [`-C`](http://docs.generic-mapping-tools.org/latest/subplot.html#c)
- $(GMT.opt_J)
- **M** | **margins** :: [Type => Str]

    The margin space that is added around each subplot beyond the automatic space allocated for tick marks, annotations, and labels.
    [`-M`](http://docs.generic-mapping-tools.org/latest/subplot.html#m)
- $(GMT.opt_R)
- **SC** | **SR** | **row_axes** | **col_axes** :: [Type => Str | NamedTuple]

    Set subplot layout for shared axes. Set separately for rows (SR) and columns (SC).
    [`-S`](http://docs.generic-mapping-tools.org/latest/subplot.html#s)
- **T** | **title** :: [Type => Str]

    While individual subplots can have titles, the entire figure may also have a overarching title.
    [`-T`](http://docs.generic-mapping-tools.org/latest/subplot.html#t)
"""
function subplot(fim=nothing; stop=false, kwargs...)

	FirstModern[1] = true			# To know if we need to compute -R in plot. Due to a GMT6.0 BUG
 
	d = KW(kwargs)
	# In case :title exists we must use and delete it to avoid double parsing
	cmd = ((val = find_in_dict(d, [:T :title])[1]) !== nothing) ? " -T\"" * val * "\"" : ""
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd, "", false, " ")
	cmd = parse_common_opts(d, cmd, [:params], true)
	cmd = parse_these_opts(cmd, d, [[:M :margins]])
	cmd = add_opt(cmd, "A", d, [:A :autolabel :fixedlabel],
                  (Anchor=("+J", arg2str), anchor=("+j", arg2str), label="", clearance=("+c", arg2str), justify="+j", fill=("+g", add_opt_fill), pen=("+p", add_opt_pen), offset=("+o", arg2str), roman="_+r", Roman="_+R", vertical="_+v"))
	cmd = add_opt(cmd, "SC", d, [:SC :col_axes],
	              (top=("t", nothing, 1), bott=("b", nothing, 1), bottom=("b", nothing, 1), label="+l"))
	cmd = add_opt(cmd, "SR", d, [:SR :row_axes],
	              (left=("l", nothing, 1), right=("r", nothing, 1), label="+l", parallel="_+p", row_title="_+t", top_row_title="_+tc"))
	cmd = add_opt(cmd, "", d, [:C :clearance],
				  (left=(" -Cw", arg2str), right=(" -Ce", arg2str), bott=(" -Cs", arg2str), bottom=(" -Cs", arg2str), top=(" -Cn", arg2str)))

	if ((val = find_in_dict(d, [:F :dims :dimensions :size :sizes], false)[1]) !== nothing)
		if (isa(val, NamedTuple) && haskey(nt2dict(val), :width))	# Preferred way
			cmd *= " -F" * helper_sub_F(val)		# VAL = (width=x, height=x, fwidth=(...), fheight=(...))
			del_from_dict(d, [:F :dims :dimensions :size :sizes])
		else
			cmd = add_opt(cmd, "F", d, [:F :dims :dimensions :size :sizes],
			              (panels=("s", nothing, 1), size=("", helper_sub_F), sizes=("", helper_sub_F), frac=("+f", helper_sub_F), fractions=("+f", helper_sub_F)))
		end
	end

	do_set = false;		do_show = false
	if (fim !== nothing)
		t = lowercase(string(fim))
		if     (t == "end" || t == "stop")  stop = true
		elseif (t == "show")  stop = true;  do_show = true
		elseif (t == "set")   do_set = true
		end
	end
	# ------------------------------ End parsing inputs --------------------------------

	if (!stop && !do_set)
		#if (!haskey(d, :grid))  error("SUBPLOT: 'grid' keyword is mandatory")  end
		#cmd = arg2str(d[:grid], 'x') * " " * cmd
		if ((val = find_in_dict(d, [:grid])[1]) === nothing)
			error("SUBPLOT: 'grid' keyword is mandatory")
		end
		cmd = arg2str(val, 'x') * " " * cmd
		if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end		# Vd=2 cause this return

		if (!IamModern[1])			# If we are not in modern mode, issue a gmt("begin") first
			fname = ""				# Default name (GMTplot.ps) is set in gmt_main()
			if ((val = find_in_dict(d, [:name :savefig])[1]) !== nothing)
				fname = get_format(string(val), nothing, d)		# Get the fig name and format.
			end
			gmt("begin " * fname)
		end
		gmt("subplot begin " * cmd);
		IamSubplot[1] = true
	elseif (do_set)
		if (!IamSubplot[1])  error("Cannot call subplot(set, ...) before setting dimensions")  end
		lix, pane = parse_c(cmd, d)
		cmd = pane * cmd				# Here we don't want the "-c" part
		if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end		# Vd=2 cause this return
		gmt("subplot set " * cmd)
	else
		(do_show || haskey(d, :show)) ? show = " show" : show = ""
		try
			gmt("subplot end");		gmt("end" * show);		catch
		end
		IamModern[1] = false;		IamSubplot[1] = false
	end
	return nothing
end

# --------------------------------------------------------------------------
function helper_sub_F(arg, dumb=nothing)
	# dims=(1,2)
	# dims=(size=(1,2), frac=((2,3),(3,4,5)))
	# dims=(width=xx, height=yy, fwidth=(), fheight=())
	out = ""
	if (isa(arg, String))
		out = arg2str(arg)
	elseif (isa(arg, NamedTuple) || isa(arg, Dict))
		d = (isa(arg, NamedTuple)) ? nt2dict(arg) : arg
		val, symb = find_in_dict(d, [:size :sizes :frac :fractions])	# ex: dims=(size=(1,2), frac=((2,3),(3,4,5)))
		if (val !== nothing)
			if (isa(val, Tuple{Tuple, Tuple}))		# ex: dims=(panels=true, sizes=((2,4),(2.5,5,1.25)))
				out *= arg2str(val[1], ',') * '/' * arg2str(val[2], ',')
			else
				if (symb == :size || symb == :sizes)  out = arg2str(val)
				else                                  error("'frac' option must be a tuple(tuple, tuple)")
				end
			end
		else
			if (!haskey(d, :width))  error("SUBPLOT: 'width' is a mandatory parameter")  end
			out = string(d[:width], '/')
			if (!haskey(d, :height))  out *= '0'	# Allow this for geog cases
			else                      out *= string(d[:height])
			end
			if (haskey(d, :fwidth))
				out *= "+f" * arg2str(d[:fwidth], ',')
				if (!haskey(d, :fheight))  error("SUBPLOT: when using 'fwidth' must also set 'fheight'")  end
				out *= '/' * arg2str(d[:fheight], ',')
			end
		end
	end
	if (out == "")  error("SUBPLOT: garbage in DIMS option")  end
	return out
end