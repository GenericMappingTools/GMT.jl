"""
    grdimage(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[]; Vd=false, data=[], portrait=true, 
			 fmt="", K=false, O=false, first=true, kwargs...)

Produces a gray-shaded (or colored) map by plotting rectangles centered on each grid node and assigning them a gray-shade (or color) based on the z-value.

Full option list at http://gmt.soest.hawaii.edu/doc/latest/grdimage.html

	Parameters
	----------
	J : Str
		Select map projection.
	R : Str or list
		'xmin/xmax/ymin/ymax[+r][+uunit]'.
		Specify the region of interest.
	A : Str or number
		'min_area[/min_level/max_level][+ag|i|s|S][+r|l][+ppercent]'
		Features with an area smaller than min_area in km^2 or of
		hierarchical level that is lower than min_level or higher than
		max_level will not be plotted.
	B : Str
		Set map boundary frame and axes attributes.
	C : Str
		Set the shade, color, or pattern for lakes and river-lakes.
	D : Str
		Selects the resolution of the data set to use ((f)ull, (h)igh,
		(i)ntermediate, (l)ow, and (c)rude).
	E : Str; Tuple(Str, Str); Tuple("code", (pen)), ex: ("PT",(0.5,"red","--")); Tuple((...),(...),...)
		'code1,code2,...[+l|L][+gfill][+ppen]'		
		Select painting or dumping country polygons from the Digital Chart of the World
	G : Str
		Select filling or clipping of “dry” areas.
	I : Str
		'river[/pen]'
		Draw rivers. Specify the type of rivers and [optionally] append pen
		attributes.
	N : Str
		'border[/pen]'
		Draw political boundaries. Specify the type of boundary and
		[optionally] append pen attributes
	S : Str
		Select filling or clipping of “wet” areas.
	U : Str or []
		Draw GMT time stamp logo on plot.
    V : Bool or Str   '[level]'
        Select verbosity level 
		http://gmt.soest.hawaii.edu/doc/latest/grdimage.html#v
	W : Str
		'[level/]pen'
		Draw shorelines [Default is no shorelines]. Append pen attributes.
    X : Str    '[a|c|f|r][x-shift[u]]'
    Y : Str    '[a|c|f|r][y-shift[u]]'
        Shift plot origin. 
		http://gmt.soest.hawaii.edu/doc/latest/grdimage.html#x
"""
# ---------------------------------------------------------------------------------------------------
function grdimage(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[]; Vd=false, data=[], portrait=true, 
                                   fmt="", K=false, O=false, first=true, kwargs...)

	if (length(kwargs) == 0)		# Good, speed mode
		return gmt("grdimage " * cmd0)
	end

	if (!isempty_(data) && isa(data, Tuple) && !isa(data[1], GMTgrid))
		error("When 'data' is a tuple, it MUST contain a GMTgrid data type")
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
	cmd = parse_f(cmd, d)
	cmd = parse_n(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)

	if (first)  K = true;	O = false
	else        K = true;	O = true;	cmd = replace(cmd, opt_B, "");	opt_B = ""
	end

	cmd = add_opt_s(cmd, 'A', d, [:A :img_out :image_out])
	cmd = add_opt(cmd, 'D', d, [:D :img_in :image_in])
	cmd = add_opt(cmd, 'E', d, [:E :dpi])
	cmd = add_opt(cmd, 'G', d, [:G])
	cmd = add_opt(cmd, 'M', d, [:M :monochrome])
	cmd = add_opt(cmd, 'N', d, [:M :noclip])
	cmd = add_opt(cmd, 'Q', d, [:Q :nan_t :nan_alpha])

	if (!isempty_(data))
		if (!isempty_(arg1))
			warn("Conflicting ways of providing input data. Both a file name via positional and
				  a data array via kwyword args were provided. Ignoring later argument")
		else
			if (isa(data, String)) 		# OK, we have data via file
				cmd = cmd * " " * data
			elseif (isa(data, Tuple) && length(data) == 3)
				arg1 = data[1];     arg2 = data[2];     arg3 = data[3]
			else
				arg1 = data				# Whatever this is
			end
		end
	end

	for sym in [:C :cpt :cmap]
		if (haskey(d, sym))
			if (!isa(d[sym], GMTcpt))					# Uff, simple. Either a file name or a -A type modifier
				cmd = cmd * " -C" * arg2str(d[sym])
			else
				cmd, N_cpt = put_in_slot(cmd, d[sym], 'C', (arg1, arg2, arg3, arg4))
				if (N_cpt == 1)     arg1 = [d[sym]]
				elseif (N_cpt == 2) arg2 = [d[sym]]
				elseif (N_cpt == 3) arg3 = [d[sym]]
				elseif (N_cpt == 4) arg4 = [d[sym]]
				end
			end
			break
		end
	end

	for sym in [:I :shade :intensity :intensfile]
		if (haskey(d, sym))
			if (!isa(d[sym], GMTgrid))                  # Uff, simple. Either a file name or a -A type modifier
				cmd = cmd * " -I" * arg2str(d[sym])
			else
				cmd,N_shade = put_in_slot(cmd, d[sym], 'I', (arg1, arg2, arg3))
				if (N_shade == 1)     arg1 = [d[sym]]
				elseif (N_shade == 2) arg2 = [d[sym]]
				elseif (N_shade == 3) arg3 = [d[sym]]
				end
			end
			break
		end
	end

	cmd = finish_PS(cmd0, cmd, output, portrait, K, O)

	if (haskey(d, :ps)) PS = true			# To know if returning PS to the REPL was requested
	else                PS = false
	end

	Vd && println(@sprintf("\tgrdimage %s", cmd))

	P = nothing
	if (PS)
		if (!isempty_(arg4))      P = gmt("grdimage " * cmd, arg1[1], arg2[1], arg3[1], arg4[1])
		elseif (!isempty_(arg3))  P = gmt("grdimage " * cmd, arg1[1], arg2[1], arg3[1])
		elseif (!isempty_(arg2))  P = gmt("grdimage " * cmd, arg1[1], arg2[1])
		elseif (!isempty_(arg1))  P = gmt("grdimage " * cmd, arg1[1])
		else                     P = gmt("grdimage " * cmd)
		end
	else
		if (!isempty_(arg4))      gmt("grdimage " * cmd, arg1[1], arg2[1], arg3[1], arg4[1])
		elseif (!isempty_(arg3))  gmt("grdimage " * cmd, arg1[1], arg2[1], arg3[1])
		elseif (!isempty_(arg2))  gmt("grdimage " * cmd, arg1[1], arg2[1])
		elseif (!isempty_(arg1))  gmt("grdimage " * cmd, arg1[1])
		else                     gmt("grdimage " * cmd)
		end
	end
	show_or_save(d, output, fname_ext, opt_T, K)    # Display Fig in default viewer or save it to file
	return P
end

# ---------------------------------------------------------------------------------------------------
grdimage!(cmd0::String="", arg1=[], arg2=[], arg3=[], arg4=[]; Vd=false, data=[], portrait=true,
          fmt="", K=true, O=true, first=false, kw...) =
	grdimage(cmd0, arg1, arg2, arg3, arg4; Vd=Vd, data=data, portrait=portrait,
	         fmt=fmt, K=true, O=true, first=false, kw...) 