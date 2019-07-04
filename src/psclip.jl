"""
	clip(cmd0::String="", arg1=nothing; kwargs...)

Reads (length,azimuth) pairs from file and plot a windclip diagram.

Full option list at [`psclip`](http://gmt.soest.hawaii.edu/doc/latest/psclip.html)

Parameters
----------

- **C** : **end_clip_path** : -- Bool or [] --

    Mark end of existing clip path. No input file is needed.
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/psclip.html#C)
- $(GMT.opt_J)

- **A** : **inc** : -- Str or [] --

    By default, geographic line segments are connected as great circle arcs. To connect them as straight lines, use **A** 
	[`-A`](http://gmt.soest.hawaii.edu/doc/latest/psclip.html#A)
- $(GMT.opt_B)
- $(GMT.opt_Jz)
- **N** : **invert** : -- Bool or [] --

    Invert the sense of the test, i.e., clip regions where there is data coverage.
    [`-N`](http://gmt.soest.hawaii.edu/doc/latest/psclip.html#n)
- $(GMT.opt_P)
- $(GMT.opt_R)
- **T** : **clip_limits** : -- Bool or [] --

    Rather than read any input files, simply turn on clipping for the current map region.
	[`-T`](http://gmt.soest.hawaii.edu/doc/latest/psclip.html#t)
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

	length(kwargs) == 0 && return monolitic("psclip", cmd0, arg1)

	d = KW(kwargs)
	output, opt_T, fname_ext, K, O = fname_out(d, first)		# OUTPUT may have been an extension only

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/12c")
	cmd = parse_common_opts(d, cmd, [:UVXY :JZ :c :e :f :g :p :t :yx :params], first)
	cmd = parse_these_opts(cmd, d, [[:A :straight_lines], [:C :end_clip_path], [:N :invert], [:T :clip_limits]])

	# If file name sent in, read it and compute a tight -R if this was not provided 
	cmd, arg1, = read_data(d, cmd0, cmd, arg1, opt_R)

	return finish_PS_module(d, "psclip " * cmd, "", output, fname_ext, opt_T, K, O, true, arg1)
end

# ---------------------------------------------------------------------------------------------------
clip!(cmd0::String="", arg1=nothing; first=false, kw...) = clip(cmd0, arg1; first=first, kw...)
clip(arg1, cmd0::String=""; first=true, kw...)   = clip(cmd0, arg1; first=first, kw...)
clip!(arg1, cmd0::String=""; first=false, kw...) = clip(cmd0, arg1; first=first, kw...)

psclip  = clip			# Alias
psclip! = clip!			# Alias
