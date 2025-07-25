"""
	legend(cmd0::String="", arg1=nothing; kwargs...)

Make legends that can be overlaid on maps. It reads specific legend-related information from input or file file.

See full GMT (not the `GMT.jl` one) docs at [`legend`]($(GMTdoc)legend.html)

Parameters
----------

- $(_opt_B)
- $(_opt_J)
- $(_opt_R)
- **C** | **clearance** :: [Type => Str]

    Sets the clearance between the legend frame and the internal items [4p/4p].
- **D** | **pos** | **position** :: [Type => Str]  `Arg=[g|j|J|n|x]refpoint+wwidth[/height][+jjustify][+lspacing][+odx[/dy]]`

    Defines the reference point on the map for the legend using one of four coordinate systems.
- **F** | **box** :: [Type => Str | Number]   `Arg=[+cclearances][+gfill][+i[[gap/]pen]][+p[pen]][+r[radius]][+s[[dx/dy/][shade]]]`

    Without further options, draws a rectangular border around the legend using *MAP_FRAME_PEN*.
- **M** | **source** :: [Type => Bool]

    Modern mode only:
- **S** | **scale** :: [Type => Number]

    Scale all symbol sizes by a common scale
- **T** | **leg_file** :: [Type => Str]

    Modern mode only: Write hidden legend specification file to fname.
- $(opt_Jz)
- $(opt_P)
- $(opt_U)
- $(opt_V)
- $(opt_X)
- $(opt_Y)
- $(_opt_p)
- $(opt_q)
- $(_opt_t)
- $(opt_savefig)

To see the full documentation type: ``@? legend``
"""
function legend(cmd0::String="", arg1=nothing; first::Bool=true, kwargs...)

    gmt_proggy = (IamModern[1]) ? "legend "  : "pslegend "

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	if (cmd0 == "" && arg1 === nothing && !IamModern[1])
		first && error("Need input data or file for legend")
		# Here we have a bit of a convoluted case. This section is for the case where 'legend' is called without
		# input data and relies on the data stored in previous commands by using the 'legend' keyword. That is,
		# we use the keyword option 'position', 'fontsize', etc args as kwargs to 'legend'. As said, convoluted. 
		#
		# The call to digests_legend_bag(d) will call 'legend' again, making this a recursive call.
		# On that recursive call 'arg1 !== nothing' and it not pass in this code chunk, but upon return
		# from the digests_legend_bag() we'll return here again and either show, save or return quietly.
		do_show = ((val = find_in_dict(d, [:show])[1]) !== nothing && val != 0)
		figname::String = ((val = find_in_dict(d, [:savefig :figname :name])[1]) !== nothing) ? val : ""

		# Need to save the legend options in the global variable 'LEGEND_TYPE'
		# Must also recreate a NT if any of 'fontsize' or 'font' is present in 'd' (because of how digests_legend_bag works)
		((val = find_in_dict(d, [:fontsize])[1]) !== nothing) && (d[:leg] = (fontsize=val,))
		((val = find_in_dict(d, [:font])[1]) !== nothing) && (haskey(d, :leg) ? d[:leg] = (fontsize=d[:leg], font=val) : d[:leg] = (font=val,))
		((val = find_in_dict(d, [:pos :position])[1]) !== nothing) && (LEGEND_TYPE[1].optsDict = Dict(:pos => val))

		digests_legend_bag(d)	# It's over now, lets show up (or not) and return
		return (do_show || figname != "") ? showfig(show=do_show, savefig=figname) : nothing
	end

	def_J = " -JX" * split(DEF_FIG_SIZE, '/')[1] * "/0"
	cmd, _, _, opt_R = parse_BJR(d, "", "", O, def_J)
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)	# If called from classic without input it hangs here.
	
	# Trouble here is that 'legend' may be called from modern mode (inside gmtbegin()), case in which so far we want to
	# maintain the GMT default of using the gmt.conf font settings (and scalings), or from the GMT.jl classic-but-modern
	# where the default is 8 pts. This allows for the user to set options 'fontsize' or 'font' to override the defaults.
	((fnt = get_legend_font(d, IamModern[1] ? 0 : 8; modern=IamModern[1])) != "") && (cmd *= " --FONT_ANNOT_PRIMARY=" * fnt)

	cmd, = parse_common_opts(d, cmd, [:F :c :p :q :t :JZ :UVXY :params]; first=first)

	opt_D = parse_type_anchor(d, "", [:D :pos :position],
	                         (map=("g", arg2str, 1), outside=("J", arg2str, 1), inside=("j", arg2str, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), width=("+w", arg2str), justify="+j", spacing="+l", offset=("+o", arg2str)), 'j')
	cmd  = parse_these_opts(cmd, d, [[:C :clearance], [:M :source], [:S :scale], [:T :leg_file]])

	SHOW_KWARGS[1] && legend_help()
	(opt_D == "") && error("The `position` argument is mandatory.")
	#!contains(opt_D, "+w") && error("The `position` argument MUST contain the legend's width specification.")
	cmd *= opt_D
	isa(arg1, NamedTuple) && (arg1 = text_record(Base.invokelatest(mk_legend, arg1)))
	if (dbg_print_cmd(d, cmd) !== nothing)  return cmd  end
	r = prep_and_call_finish_PS_module(d, gmt_proggy * cmd, "", K, O, true, arg1)
	gmt("destroy")
	return r
end

#=
GMT.mk_legend(gap="-0.1i", header=(text="My Map Legend", font=(24,"Times-Roman")), hline=(pen=1, offset="0.2i"), ncolumns=2, vline=(pen=1, offset=0), symbol=(marker=:circ, size="0.15i", dx_left="0.1i", fill="p300/12", dx_right="0.3i", text="This circle is hachured"), Symbol1=(marker=:ellipse, size="0.15i", dx_left="0.1i", fill=:yellow, dx_right="0.3i", text="This ellipse is yellow"), Symbol2=(marker=:wedge, size="0.15i", dx_left="0.1i", fill=:green, dx_right="0.3i", text="This wedge is green"), hline2=(pen=1, offset="0.2i"), ncolumns2=2, map_scale=(lon=5,lat=5,length="600+u+f"), gap2="0.05i", image=(width="3i", fname="@SOEST_block4.png",justify=:CT), gap3="0.05i", label=(txt="Smith et al., @%5%J. Geophys. Res., 99@%%", justify=:R, font=(9, "Times-Roman")), gap4="0.1i", text1="Let us just try some simple text that can go on a few lines.", text2="There is no easy way to predetermine how many lines may be required")
=#

function legend_help(test::Bool=false)
	io = (!test) ? stdout : IOBuffer()
	println(io, "\n\tLegend Codes\n")
	println(io, "  header=(text=?(a text) [, font=?(text font)])  (H) --> Plots a centered text string")
	println(io, "  cmap|cpt=?(CPT file name)  (A) --> Symbol or cell color fills may be given indirectly via a z-value")
	println(io, "  colorbar=(name=?(CPT file name), offset=?, height=? [, extra=?(extra opts)])  (B) --> Plot horizontal colorbar")
	println(io, "  textcolor=?(color)  (C) --> Color with which the remaining text is to be printed via z=value")
	println(io, "  hline=(pen=?(pen)[, offset=?])  (D) --> Horizontal line with specified pen across the legend")
	println(io, "  fill=?(color))  --> (F) Fill (color of pattern) for cells")
	println(io, "  gap|vspace=?(amount))  --> (G) Specifies a vertical gap of the given length")
	println(io, "  image=(name=?(img file name), width=?, justify=?(2 char code))  --> (I) Place image justified relative to the current point")
	println(io, "  label=(text=?(a text), justify=?(L|R|C)[, font=?(text font)])  --> (L) Plots a (L)eft, (C)entered, or (R)ight-justified text")
	println(io, "  map_scale=([lon=?,] lat|y=?(lat of scale), length=? [box=?(map panel), region=?, proj=?])  --> (M) Place a map scale")
	println(io, "  ncol[xx]=?(number of columns)  --> (N) Change the number of columns in the legend")
	println(io, "  paragraph=?(Bool or a String)  --> (P) Start a new text paragraph")
	println(io, "  symbol[xx]=([dx_left=?,] marker=?(symbol name), size=?(symbol size), [fill=?(color), pen=?(outline)] [, dx_right=?, label=?(text)])  --> (S) Plots the selected symbol")
	println(io, "  text[xx]=?(the text)  (T) --> One or more of these records with paragraph-text")
	println(io, "  vline=(pen=?(pen)[, offset=?])  (V) --> Draws a vertical line between columns")
end

mk_legend(nt::NamedTuple) = mk_legend(; nt...)
function mk_legend(; kwargs...)
	leg::Vector{String} = Vector{String}(undef, length(kwargs))
	c = zeros(Bool, length(kwargs))
	ky = keys(kwargs)

	function check_unused(d::Dict, opt::String, symb=nothing)
		(symb !== nothing) && delete!(d, [symb])
		(length(d) > 0) && println("\tThe following options were not consumed in the legend's '$(opt)' option => ", keys(d))
	end

	for n = 1:numel(ky)
		code = isa(kwargs[n], NamedTuple) ? kwargs[n] : NamedTuple([ky[n]] .=> [kwargs[n]])
		kw_str = lowercase(string(ky[n]))
		k = keys(code)
		if (kw_str == "H" || startswith(kw_str, "header"))		# code = (header=txt, font=?)	H 24p,Times-Roman My Map Legend
			d = nt2dict(code)
			f::String = ((val = find_in_dict(d, [:font])[1]) === nothing) ? "-" : font(val)
			leg[n] = "H " * f * " " * string(d[Symbol.(keys(d))[1]])::String
			check_unused(d, kw_str, Symbol.(keys(d))[1])

		elseif (kw_str == "A" || startswith(kw_str, "cpt") || startswith(kw_str, "cmap"))
			leg[n] = "A " * string(code[1])::String

		elseif (kw_str == "B" || startswith(kw_str, "colorbar"))	# code = (name="tt.cpt", offset=0.5, height=0.5)
			d = nt2dict(code)
			((val = find_in_dict(d, [:offset])[1]) === nothing) && error("Must specify the 'offset' in 'colorbar'")
			f = string(val)
			((val = find_in_dict(d, [:height])[1]) === nothing) && error("Must specify the 'height' in 'colorbar'")
			f *= " " * string(val)::String
			((val = find_in_dict(d, [:extra :options])[1]) !== nothing) && (f *= " " * string(val)::String)
			leg[n] = "B " * string(d[Symbol.(keys(d))[1]])::String * " " * f
			check_unused(d, kw_str, Symbol.(keys(d))[1])

		elseif (kw_str == "C" || startswith(kw_str, "textcolor"))
			leg[n] = "C " * get_color(code[1])

		elseif (kw_str == "D" || startswith(kw_str, "hline"))	# code = (hline=pen, offset=?)	D 0.2i 1p
			d = nt2dict(code)
			f = ((val = find_in_dict(d, [:offset])[1]) === nothing) ? "" : string(val)
			leg[n] = "D " * f * " " * add_opt_pen(d, [:pen], opt="")
			check_unused(d, kw_str)

		elseif (kw_str == "F" || startswith(kw_str, "fill"))
			leg[n] = "F " *  join([@sprintf("%s ", get_color(x)) for x in code])

		elseif (kw_str == "G" || startswith(kw_str, "vspace") || startswith(kw_str, "gap"))	# code = (vspace=val)	G -0.1i
			leg[n] = "G " * string(code[1])::String

		elseif (kw_str == "I" || startswith(kw_str, "image"))	# code = (image=fname)	I @SOEST_block4.png 3i CT
			d = nt2dict(code)
			((val = find_in_dict(d, [:width])[1]) === nothing) && error("Must specify the 'width' in 'image'")
			f = string(val)
			((val = find_in_dict(d, [:justify :justification])[1]) === nothing) && error("Must specify the 'justify' in 'image'")
			f *= " " * string(val)::String
			leg[n] = "I " * string(d[Symbol.(keys(d))[1]])::String * " " * f
			check_unused(d, kw_str, Symbol.(keys(d))[1])

		elseif (kw_str == "L" || startswith(kw_str, "label"))	# code = L 9p,Times-Roman R Smith et al., @%5%J. Geophys. Res., 99@%%, 2000
			d = nt2dict(code)
			((val = find_in_dict(d, [:justify :justification])[1]) === nothing) && error("Must specify the 'justify' in 'label'")
			f = string(val)
			f = (((val = find_in_dict(d, [:font])[1]) === nothing) ? "-" : font(val)) * " " * uppercase(f[1])
			leg[n] = "L " * f * " " * string(d[Symbol.(keys(d))[1]])::String
			check_unused(d, kw_str, Symbol.(keys(d))[1])

		elseif (kw_str == "M" || occursin("scale", kw_str))		# code = (map_scale=)	M 5 5 600+u+f
			d = nt2dict(code)
			f = ((val = find_in_dict(d, [:lon :x])[1]) === nothing) ? "-" : string(val)
			((val = find_in_dict(d, [:lat :y])[1]) === nothing) && error("Must specify the 'lat or y' in map_scale")
			leg[n] = "M " * f * " " * string(val)::String
			((val = find_in_dict(d, [:length])[1]) === nothing) && error("Must specify the 'length' in map_scale")
			leg[n] *= " " * string(val)::String
			opt_R::String = parse_R(d, "", O=false, del=false)[1]
			opt_J::String = parse_J(d, "", default=" ", map=true, O=false, del=false)[1]
			opt_F::String = parse_F(d, "")
			leg[n] *= opt_F * opt_R * opt_J
			check_unused(d, kw_str)

		elseif (kw_str == "N" || startswith(kw_str, "ncol"))		# code = (ncolumns=?)	N 2
			leg[n] = "N " * string(code[1])::String

		elseif (kw_str == "P" || startswith(kw_str, "parag"))
			# NOTE: Pargraph also accepts options like pstext -M but that's too complicated to parse
			t::String = (isa(code[1], Bool) && code[1]) ? "" : string(code[1])
			leg[n] = "P " * t

		elseif (kw_str == "S" || startswith(kw_str, "symb"))
			# code = (symbol=:circ, size=0.15, dx_left=0.1, fill="p300/12", dx_righ=0.3, text="This circ")
			# S [dx1 symbol size fill pen [ dx2 text ]]
			d = nt2dict(code)
			marca::String = get_marker_name(d, nothing, [:symbol, :marker], false, true)[1]
			f = ((val = find_in_dict(d, [:dx_left])[1]) === nothing) ? "- " : string(val, " ");	dx1 = f
			f = ((val = find_in_dict(d, [:fill])[1]) === nothing) ? "- " : get_color(val);			fill = f
			f = add_opt_pen(d, [:pen], opt="");	pen = (f == "") ? " -" : " " * f		# TRUE to also seek (lw,lc,ls)
			((val = find_in_dict(d, [:size])[1]) === nothing) && error("Must specify the 'size' in 'symbol'")
			_size::String = arg2str(val)
			f = ((val = find_in_dict(d, [:label :text])[1]) === nothing) ? "" : string(val);	label = f
			if (label != "")
				f = ((val = find_in_dict(d, [:dx_right])[1]) === nothing) ? "- " : string(val, " ");	dx2 = f
				label = " " * dx2 * label
			end
			leg[n] = "S " * dx1 * marca * " " * _size * " " * fill * pen * label
			check_unused(d, kw_str)

		elseif (kw_str == "T" || startswith(kw_str, "text"))
			leg[n] = "T " * string(code[1])::String

		elseif (kw_str == "V" || startswith(kw_str, "vline"))		# code = (vline=pen, offset=?)	V 0 1p
			d = nt2dict(code)
			f = ((val = find_in_dict(d, [:offset])[1]) === nothing) ? "" : string(val)
			leg[n] = "V " * f * " " * add_opt_pen(d, [:pen], opt="")
			check_unused(d, kw_str)

		else
			@warn("Unrecognizable option $(ky[n]) in 'legend'.")
			c[n] = true
		end
	end
	any(c) && (leg = leg[.!c])		# Remove entries corresponding to bad options to not let go undefineds
	leg
end

# ---------------------------------------------------------------------------------------------------
legend!(cmd0::String="", arg1=nothing; kw...) = legend(cmd0, arg1; first=false, kw...)
legend(arg1; kw...)  = legend("", arg1; first=true, kw...)
legend!(arg1; kw...) = legend("", arg1; first=false, kw...)

const pslegend  = legend			# Alias
const pslegend! = legend!			# Alias