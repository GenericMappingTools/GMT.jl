"""
	grdcontour(cmd0::String="", arg1=[]; data=[], fmt="", K=false, O=false,
	           first=true, kwargs...)

Reads a 2-D grid file or a GMTgrid type and produces a contour map by tracing each
contour through the grid.

Parameters
----------

- $(GMT.opt_J)
- **A** : **annot** : -- Str or Number --
    Save an image in a raster format instead of PostScript.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#a)
- $(GMT.opt_B)
- **C** : **cont** : **contour** : -- Str or Number --
    Contours to be drawn.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#c)
- **D** : **dump** : -- Str --
    Dump contours as data line segments; no plotting takes place.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#d)
- **F** : **force** : -- Str or [] --
    Force dumped contours to be oriented so that higher z-values are to the left (-Fl [Default]) or right.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#f)
- **G** : **labels** : -- Str --
    Controls the placement of labels along the quoted lines.
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#g)
- $(GMT.opt_Jz)
- **L** : **range** : -- Str --
    Limit range: Do not draw contours for data values below low or above high.
    [`-L`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#l)
- **Q** : **cut** : -- Str or Number --
    Do not draw contours with less than cut number of points.
    [`-Q`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#q)
- **S** : **smooth** : -- Number --
    Used to resample the contour lines at roughly every (gridbox_size/smoothfactor) interval.
    [`-S`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#s)
- **T** : **ticks** : -- Str --
    Draw tick marks pointing in the downward direction every *gap* along the innermost closed contours.
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#t)
- $(GMT.opt_R)
- $(GMT.opt_U)
- $(GMT.opt_V)
- **W** : **pen** : -- Str or Number --
    Sets the attributes for the particular line.
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#w)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- **Z** : **scale** : -- Str --
    Use to subtract shift from the data and multiply the results by factor before contouring starts.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/grdcontour.html#z)
- $(GMT.opt_bo)
- $(GMT.opt_do)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_h)
- $(GMT.opt_p)
- $(GMT.opt_t)
"""
# ---------------------------------------------------------------------------------------------------
function grdcontour(cmd0::String="", arg1=[]; data=[], fmt="", K=false, O=false, first=true, kwargs...)

	if (length(kwargs) == 0)		# Good, speed mode
		return gmt("grdcontour " * cmd0)
	end

	if (!isempty_(data) && !isempty_(arg1))
		warn("Conflicting ways of providing input data. Both a file name via positional and
			  a data array via keyword args were provided. Ignoring former argument")
	end

	output = fmt
	if (!isa(output, String))
		error("Output format or name must be a String")
	else
		output, opt_T, fname_ext = fname_out(output)		# OUTPUT may have been an extension only
	end

	d = KW(kwargs)
	cmd = ""
	maybe_more = false			# If latter set to true, search for lc & lc pen settings
	cmd, opt_R = parse_R(cmd, d)
	cmd, opt_J = parse_J(cmd, d)
	cmd, opt_B = parse_B(cmd, d)
	cmd = parse_U(cmd, d)
	cmd = parse_V(cmd, d)
	cmd = parse_X(cmd, d)
	cmd = parse_Y(cmd, d)
	cmd = parse_bo(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_h(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)

	if (first)  K = true;	O = false
	else        K = true;	O = true;	cmd = replace(cmd, opt_B, "");	opt_B = ""
	end

	cmd = add_opt(cmd, 'A', d, [:A :annot])
	cmd = add_opt(cmd, 'C', d, [:C :cont :contour])
	cmd = add_opt(cmd, 'D', d, [:D :dump])
	cmd = add_opt(cmd, 'F', d, [:F :force])
	cmd = add_opt(cmd, 'G', d, [:G :labels])
	cmd = add_opt(cmd, 'L', d, [:L :range])
	cmd = add_opt(cmd, 'Q', d, [:Q :cut])
	cmd = add_opt(cmd, 'S', d, [:S :smooth])
	cmd = add_opt(cmd, 'T', d, [:T :ticks])
	cmd = add_opt(cmd, 'W', d, [:W :pen])
	cmd = add_opt(cmd, 'Z', d, [:Z :scale])

	if (!isempty_(data))
		if (!isempty_(arg1))
			warn("Conflicting ways of providing input data. Both a file name via positional and
				  a data array via kwyword args were provided. Ignoring later argument")
		else
			if (isa(data, String)) 		# OK, we have data via file
				cmd = cmd * " " * data
			else
				arg1 = data				# Whatever this is
			end
		end
	end

	cmd = finish_PS(d, cmd0, cmd, output, K, O)

	if (haskey(d, :ps))           PS = true		# To know if returning PS to the REPL was requested
	elseif (contains(cmd, "-D"))  PS = true		# Contour dump
	else                          PS = false
	end

	(haskey(d, :Vd)) && println(@sprintf("\tgrdcontour %s", cmd))

	P = nothing
	if (!isempty_(arg1))
		if (PS) P = gmt("grdcontour " * cmd, arg1)                 # A numeric input
		else        gmt("grdcontour " * cmd, arg1)
		end
	else
		if (PS) P = gmt("grdcontour " * cmd)                       # Ploting from file
		else        gmt("grdcontour " * cmd)
		end
	end
    show_or_save(d, output, fname_ext, opt_T, K)    # Display Fig in default viewer or save it to file
	return P
end

# ---------------------------------------------------------------------------------------------------
grdcontour!(cmd0::String="", arg1=[]; data=[], fmt="", K=true, O=true, first=false, kw...) =
	grdcontour(cmd0, arg1; data=data, fmt=fmt, K=true, O=true, first=false, kw...)

grdcontour(arg1::GMTgrid, cmd0::String=""; data=[], fmt="", K=false, O=false, first=true, kw...) =
	grdcontour(cmd0, arg1; data=data, fmt=fmt, K=K, O=O, first=first, kw...)

grdcontour!(arg1::GMTgrid, cmd0::String=""; data=[], fmt="", K=true, O=true, first=false, kw...) =
	grdcontour(cmd0, arg1; data=data, fmt=fmt, K=true, O=true, first=false, kw...)