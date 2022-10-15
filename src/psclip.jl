"""
	clip(cmd0::String="", arg1=nothing; kwargs...)

Reads (length,azimuth) pairs from file and plot a windclip diagram.

Full option list at [`psclip`]($(GMTdoc)psclip.html)

Parameters
----------

- **C** | **endclip** | **end_clip_path** :: [Type => Bool]

    Mark end of existing clip path. No input file is needed.
    ($(GMTdoc)psclip.html#c)
- $(GMT._opt_J)

- **A** | **steps** :: [Type => Str or []]

    By default, geographic line segments are connected as great circle arcs. To connect them as straight lines, use **A** 
    ($(GMTdoc)psclip.html#a)
- $(GMT._opt_B)
- $(GMT.opt_Jz)
- **N** | **invert** :: [Type => Bool]

    Invert the sense of the test, i.e., clip regions where there is data coverage.
    ($(GMTdoc)psclip.html#n)
- $(GMT.opt_P)
- $(GMT._opt_R)
- **T** | **clip_limits** :: [Type => Bool]

    Rather than read any input files, simply turn on clipping for the current map region.
    ($(GMTdoc)psclip.html#t)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_f)
- $(GMT.opt_g)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_p)
- $(GMT.opt_t)
- $(GMT.opt_swap_xy)
"""
function clip(cmd0::String="", arg1=nothing; first=true, kwargs...)

	gmt_proggy = (IamModern[1]) ? "clip " : "psclip "

	d, K, O = init_module(first, kwargs...)		# Also checks if the user wants ONLY the HELP mode

	cmd, _, _, opt_R = parse_BJR(d, "", "", O, " -JX" * split(def_fig_size, '/')[1] * "/0")
	cmd, = parse_common_opts(d, cmd, [:UVXY :JZ :c :e :f :g :p :t :yx :params], first)
	cmd  = parse_these_opts(cmd, d, [[:A :steps :straight_lines], [:C :endclip :end_clip_path], [:N :invert], [:T :clip_limits]])
	cmd *= add_opt_pen(d, [:W :pen], "W")

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, = read_data(d, cmd0, cmd, arg1, opt_R)

	finish_PS_module(d, gmt_proggy * cmd, "", K, O, true, arg1)
end

# ---------------------------------------------------------------------------------------------------
clip!(cmd0::String="", arg1=nothing; kw...) = clip(cmd0, arg1; first=false, kw...)
clip(arg1, cmd0::String=""; kw...)  = clip(cmd0, arg1; first=true, kw...)
clip!(arg1, cmd0::String=""; kw...) = clip(cmd0, arg1; first=false, kw...)

psclip  = clip			# Alias
psclip! = clip!			# Alias
