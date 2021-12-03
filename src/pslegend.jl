"""
	legend(cmd0::String="", arg1=nothing; kwargs...)

Make legends that can be overlaid on maps. It reads specific legend-related information from input or file file.

Full option list at [`legend`]($(GMTdoc)legend.html)

Parameters
----------

- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- **C** | **clearance** :: [Type => Str]

    Sets the clearance between the legend frame and the internal items [4p/4p].
    ($(GMTdoc)legend.html#c)
- **D** | **pos** | **position** :: [Type => Str]  `Arg=[g|j|J|n|x]refpoint+wwidth[/height][+jjustify][+lspacing][+odx[/dy]]`

    Defines the reference point on the map for the legend using one of four coordinate systems.
    ($(GMTdoc)legend.html#d)
- **F** | **box** :: [Type => Str | Number]   `Arg=[+cclearances][+gfill][+i[[gap/]pen]][+p[pen]][+r[radius]][+s[[dx/dy/][shade]]]`

    Without further options, draws a rectangular border around the legend using *MAP_FRAME_PEN*.
    ($(GMTdoc)legend.html#f)
- $(GMT.opt_Jz)
- $(GMT.opt_P)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_p)
- $(GMT.opt_t)
- $(GMT.opt_swap_xy)
"""
function legend(cmd0::String="", arg1=nothing; first=true, kwargs...)

    gmt_proggy = (IamModern[1]) ? "legend "  : "pslegend "
	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic(gmt_proggy, cmd0, arg1)

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd, _, _, opt_R = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd, = parse_common_opts(d, cmd, [:F :c :p :t :JZ :UVXY :params], first)

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)

	cmd = parse_type_anchor(d, cmd, [:D :pos :position],
	                        (map=("g", arg2str, 1), inside=("j", nothing, 1), norm=("n", arg2str, 1), paper=("x", arg2str, 1), anchor=("", arg2str, 2), width=("+w", arg2str), justify="+j", spacing="+l", offset=("+o", arg2str)), 'j')
	cmd = add_opt(d, cmd, 'C', [:C :clearance])

	isa(arg1, NamedTuple) && (arg1 = text_record(mk_legend(arg1)))
	r = finish_PS_module(d, gmt_proggy * cmd, "", K, O, true, arg1)
	gmt("destroy")
	return r
end

#=
GMT.mk_legend(gap="-0.1i", header=(text="My Map Legend", font=(24,"Times-Roman")), hline=(pen=1, offset="0.2i"), ncolumns=2, vline=(pen=1, offset=0), symbol=(marker=:circ, size="0.15i", dx_left="0.1i", fill="p300/12", dx_right="0.3i", text="This circle is hachured"), Symbol1=(marker=:ellipse, size="0.15i", dx_left="0.1i", fill=:yellow, dx_right="0.3i", text="This ellipse is yellow"), Symbol2=(marker=:wedge, size="0.15i", dx_left="0.1i", fill=:green, dx_right="0.3i", text="This wedge is green"), hline2=(pen=1, offset="0.2i"), ncolumns2=2, map_scale=(x=5,y=5,length="600+u+f"), gap2="0.05i", image=(width="3i", fname="@SOEST_block4.png",justify=:CT), gap3="0.05i", label=(txt="Smith et al., @%5%J. Geophys. Res., 99@%%", justify=:R, font=(9, "Times-Roman")), gap4="0.1i", text1="Let us just try some simple text that can go on a few lines.", text2="There is no easy way to predetermine how many lines may be required")
=#
mk_legend(nt::NamedTuple) = mk_legend(; nt...)
function mk_legend(; kwargs...)
	leg::Vector{String} = Vector{String}(undef, length(kwargs))
	c = zeros(Bool, length(kwargs))
	ky = keys(kwargs)

	function check_unused(d::Dict, opt::String, symb=nothing)
		(symb !== nothing) && del_from_dict(d, [symb])
		(length(d) > 0) && println("\tThe following options were not consumed in the legend's '$(opt)' option => ", keys(d))
	end

	for n = 1:length(ky)
		code = isa(kwargs[n], NamedTuple) ? kwargs[n] : NamedTuple([ky[n]] .=> [kwargs[n]])
		kw_str = lowercase(string(ky[n]))
		k = keys(code)
		if (startswith(kw_str, "header"))		# code = (header=txt, font=?)	H 24p,Times-Roman My Map Legend
			d = nt2dict(code)
			f::String = ((val = find_in_dict(d, [:font])[1]) === nothing) ? "-" : font(val)
			leg[n] = "H " * f * " " * string(d[Symbol.(keys(d))[1]])
			check_unused(d, kw_str, Symbol.(keys(d))[1])

		elseif (startswith(kw_str, "cpt") || startswith(kw_str, "cmap"))
			leg[n] = "A " * string(code[1])

		elseif (startswith(kw_str, "colorbar"))	# code = (name="tt.cpt", offset=0.5, height=0.5) B tt.cpt 0.2i 0.2i -B0
			d = nt2dict(code)
			((val = find_in_dict(d, [:offset])[1]) === nothing) && error("Must specify the 'offset' in 'colorbar'")
			f = string(val)
			((val = find_in_dict(d, [:height])[1]) === nothing) && error("Must specify the 'height' in 'colorbar'")
			f *= " " * string(val)
			((val = find_in_dict(d, [:extra :options])[1]) !== nothing) && (f *= " " * string(val))
			leg[n] = "B " * string(d[Symbol.(keys(d))[1]]) * " " * f
			check_unused(d, kw_str, Symbol.(keys(d))[1])

		elseif (startswith(kw_str, "textcolor"))
			leg[n] = "C " * get_color(code[1])

		elseif (startswith(kw_str, "hline"))	# code = (hline=pen, offset=?)	D 0.2i 1p
			d = nt2dict(code)
			f = ((val = find_in_dict(d, [:offset])[1]) === nothing) ? "" : string(val)
			leg[n] = "D " * f * " " * add_opt_pen(d, [:pen :header], "", true)
			check_unused(d, kw_str)

		elseif (startswith(kw_str, "fill"))
			leg[n] = "F " *  join([@sprintf("%s ", get_color(x)) for x in code])

		elseif (startswith(kw_str, "vspace") || startswith(kw_str, "gap"))	# code = (vspace=val)	G -0.1i
			leg[n] = "G " * string(code[1])

		elseif (startswith(kw_str, "image"))	# code = (image=fname)	I @SOEST_block4.png 3i CT
			d = nt2dict(code)
			((val = find_in_dict(d, [:width])[1]) === nothing) && error("Must specify the 'width' in 'image'")
			f = string(val)
			((val = find_in_dict(d, [:justify :justification])[1]) === nothing) && error("Must specify the 'justify' in 'image'")
			f *= " " *string(val)
			leg[n] = "I " * string(d[Symbol.(keys(d))[1]]) * " " * f
			check_unused(d, kw_str, Symbol.(keys(d))[1])

		elseif (startswith(kw_str, "label"))	# code = L 9p,Times-Roman R Smith et al., @%5%J. Geophys. Res., 99@%%, 2000
			d = nt2dict(code)
			((val = find_in_dict(d, [:justify :justification])[1]) === nothing) && error("Must specify the 'justify' in 'label'")
			f = string(val)
			f = ((val = find_in_dict(d, [:font])[1]) === nothing) ? "-" : font(val) * " " * f
			leg[n] = "L " * f * " " * string(d[Symbol.(keys(d))[1]])
			check_unused(d, kw_str, Symbol.(keys(d))[1])

		elseif (occursin("scale", kw_str))		# code = (map_scale=)	M 5 5 600+u+f
			d = nt2dict(code)
			f = ((val = find_in_dict(d, [:lon :x])[1]) === nothing) ? "-" : string(val)
			((val = find_in_dict(d, [:lat :y])[1]) === nothing) && error("Must specify the 'lat or y' in map_scale")
			leg[n] = "M " * f * " " * string(val)
			((val = find_in_dict(d, [:length])[1]) === nothing) && error("Must specify the 'length' in map_scale")
			leg[n] *= " " * string(val)
			opt_R = parse_R(d, "", false, false)[1]
			opt_J = parse_J(d, "", " ", true, false, false)[1]
			opt_F = parse_F(d, "")
			leg[n] *= opt_F * opt_R * opt_J
			check_unused(d, kw_str)

		elseif (startswith(kw_str, "ncol"))		# code = (ncolumns=?)	N 2
			leg[n] = "N " * arg2str(code[1])

		elseif (startswith(kw_str, "parag"))	# NOTE: Pargraph also accepts options like pstext -M but that's too complicated to parse
			t = (isa(code[1], Bool) && code[1]) ? "" : string(code[1])
			leg[n] = "P " * t

		elseif (startswith(kw_str, "symb"))
			# code = (symbol=:circ, size=0.15, dx_left=0.1, fill="p300/12", dx_righ=0.3, text="This circ")
			# S [dx1 symbol size fill pen [ dx2 text ]]
			d = nt2dict(code)
			marca::String = get_marker_name(d, nothing, [:symbol, :marker], false, true)[1]
			f = ((val = find_in_dict(d, [:dx_left])[1]) === nothing) ? "- " : string(val, " ");	dx1 = f
			f = ((val = find_in_dict(d, [:fill])[1]) === nothing) ? "- " : get_color(val);			fill = f
			f = add_opt_pen(d, [:pen], "", true);	pen = f		# TRUE to also seek (lw,lc,ls)
			((val = find_in_dict(d, [:size])[1]) === nothing) && error("Must specify the 'size' in 'symbol'")
			_size = arg2str(val)
			f = ((val = find_in_dict(d, [:label :text])[1]) === nothing) ? "" : string(val);	label = f
			if (label != "")
				f = ((val = find_in_dict(d, [:dx_right])[1]) === nothing) ? "- " : string(val, " ");	dx2 = f
				label = " " * dx2 * label
			end
			leg[n] = "S " * dx1 * marca * " " * _size * " " * fill * pen * label
			check_unused(d, kw_str)

		elseif (startswith(kw_str, "text"))
			leg[n] = "T " * string(code[1])

		elseif (startswith(kw_str, "vline"))		# code = (vline=pen, offset=?)	V 0 1p
			d = nt2dict(code)
			f = ((val = find_in_dict(d, [:offset])[1]) === nothing) ? "" : string(val)
			leg[n] = "V " * f * " " * add_opt_pen(d, [:pen :header], "", true)
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