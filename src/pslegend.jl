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

	r = finish_PS_module(d, gmt_proggy * cmd, "", K, O, true, arg1)
	gmt("destroy")
	return r
end

#=
function mk_legend(codes::Vector{NamedTuple})
	# code = (Symbol=:circ, size=0.15, dx_left=0.1, fill="p300/12", dx_righ=0.3, text="This circ")
	for code in codes
		k = keys(code)
		lowercase(string(k[1]))
		code[1]
	end
end
=#

# ---------------------------------------------------------------------------------------------------
legend!(cmd0::String="", arg1=nothing; kw...) = legend(cmd0, arg1; first=false, kw...)
legend(arg1; kw...)  = legend("", arg1; first=true, kw...)
legend!(arg1; kw...) = legend("", arg1; first=false, kw...)

const pslegend  = legend			# Alias
const pslegend! = legend!			# Alias