"""
	clip(cmd0::String="", arg1=[]; fmt="", kwargs...)

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
- **T** : **clip_map_region** : -- Bool or [] --
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
# ---------------------------------------------------------------------------------------------------
function clip(cmd0::String="", arg1=[]; data=[], fmt::String="", K=false, O=false, first=true, kwargs...)

	length(kwargs) == 0 && isempty(data) && return monolitic("psclip", cmd0, arg1)	# Speedy mode
	output, opt_T, fname_ext = fname_out(fmt)		# OUTPUT may have been an extension only

	d = KW(kwargs)
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd0, "", "", O, " -JX12c/12c")
	cmd = parse_JZ(cmd, d)
	cmd = parse_UVXY(cmd, d)
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_di = parse_di(cmd, d)
	cmd = parse_e(cmd, d)
	cmd = parse_f(cmd, d)
	cmd = parse_g(cmd, d)
	cmd = parse_h(cmd, d)
	cmd, opt_i = parse_i(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)
	cmd = parse_swap_xy(cmd, d)

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	# If data is a file name, read it and compute a tight -R if this was not provided 
	cmd, arg1, opt_R, opt_i = read_data(data, cmd, arg1, opt_R, opt_i, opt_bi, opt_di)

	cmd = add_opt(cmd, 'A', d, [:A :straight_lines])
	cmd = add_opt(cmd, 'C', d, [:C :end_clip_path])
	cmd = add_opt(cmd, 'N', d, [:N :invert])
	cmd = add_opt(cmd, 'T', d, [:T :clip_map_region])

	cmd = finish_PS(d, cmd0, cmd, output, K, O)

	return finish_PS_module(d, cmd, "", arg1, [], [], [], [], [], output, fname_ext, opt_T, K, "psclip")
end

# ---------------------------------------------------------------------------------------------------
clip!(cmd0::String="", arg1=[]; data=[], fmt::String="", K=true, O=true,  first=false, kw...) =
	clip(cmd0, arg1; data=data, fmt=fmt, K=K, O=O,  first=first, kw...)

clip(arg1=[], cmd0::String=""; data=[], fmt::String="", K=false, O=false,  first=true, kw...) =
	clip(cmd0, arg1; data=data, fmt=fmt, K=K, O=O,  first=first, kw...)

clip!(arg1=[], cmd0::String=""; data=[], fmt::String="", K=true, O=true,  first=false, kw...) =
	clip(cmd0, arg1; data=data, fmt=fmt, K=K, O=O,  first=first, kw...)
