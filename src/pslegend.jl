"""
	legend(cmd0::String="", arg1=nothing; kwargs...)

Make legends that can be overlaid on maps. It reads specific legend-related information from input or file file.

Full option list at [`legend`](http://gmt.soest.hawaii.edu/doc/latest/pslegend.html)

Parameters
----------

- $(GMT.opt_J)
- $(GMT.opt_R)
- $(GMT.opt_B)
- **C** : **clearance** : -- Str --

    Sets the clearance between the legend frame and the internal items [4p/4p].
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#c)
- **D** : **refpoint** : -- Str --  `Flags=[g|j|J|n|x]refpoint+wwidth[/height][+jjustify][+lspacing][+odx[/dy]]`

    Defines the reference point on the map for the legend using one of four coordinate systems.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#d)
- **F** : **box** : -- Str or number --   `Flags=[+cclearances][+gfill][+i[[gap/]pen]][+p[pen]][+r[radius]][+s[[dx/dy/][shade]]]`

    Without further options, draws a rectangular border around the legend using *MAP_FRAME_PEN*.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/pstext.html#f)
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

	length(kwargs) == 0 && occursin(" -", cmd0) && return monolitic("pslegend", cmd0, arg1)

	d = KW(kwargs)
	output, opt_T, fname_ext, K, O = fname_out(d, first)		# OUTPUT may have been an extension only

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd = parse_common_opts(d, cmd, [:F :c :p :t :JZ :UVXY :params], first)
	#if (!first && current_view !== nothing && !occursin("-p", cmd))  cmd *= current_view  end

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R = read_data(d, cmd0, cmd, arg1, opt_R)

	#cmd = add_opt(cmd, 'D', d, [:D :pos :position :refpoint],
	#			  (map=("g", nothing, 1), inside=("j", nothing, 1), paper=("x", nothing, 1),
	#			  anchor=("", arg2str, 2), width="+w", justify="+j", spacing="+l", offset="+o"))
	cmd = parse_type_anchor(d, cmd, [:D :pos :position :refpoint])
	cmd = add_opt(cmd, 'C', d, [:C :clearance])

	r = finish_PS_module(d, "pslegend " * cmd, "", output, fname_ext, opt_T, K, O, true, arg1)
	gmt("destroy")
	return r
end

# ---------------------------------------------------------------------------------------------------
legend!(cmd0::String="", arg1=nothing; first=false, kw...) = legend(cmd0, arg1;first=false, kw...)
legend(arg1; first=true, kw...)   = legend("", arg1; first=first, kw...)
legend!(arg1; first=false, kw...) = legend("", arg1; first=first, kw...)

const pslegend  = legend			# Alias
const pslegend! = legend!			# Alias