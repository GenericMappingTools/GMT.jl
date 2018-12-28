"""
    image(cmd0::String="", arg1=[]; kwargs...)

Place images or EPS files on maps.

Full option list at [`psimage`](http://gmt.soest.hawaii.edu/doc/latest/psimage.html)

Parameters
----------

- $(GMT.opt_B)
- **D** : **ref_point** : -- Str --  

    Sets reference point on the map for the image using one of four coordinate systems.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/psimage.html#d)
- **F** : **box** : -- Str or [] --

    Without further options, draws a rectangular border around the image using MAP_FRAME_PEN.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/psimage.html#f)
- **I** : **invert_1bit** : -- Number or Str --

    Invert 1-bit image before plotting.
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/psimage.html#i)
- $(GMT.opt_J)
- $(GMT.opt_Jz)
- **M** : **monochrome** : -- Bool or [] --

    Convert color image to monochrome grayshades using the (television) YIQ-transformation.
    [`-M`](http://gmt.soest.hawaii.edu/doc/latest/psimage.html#m)
- $(GMT.opt_R)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_p)
- $(GMT.opt_t)
"""
function image(cmd0::String="", arg1=[]; first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("psimage", cmd0, arg1)

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	K, O = set_KO(first)		# Set the K O dance
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/12c")
	cmd = parse_common_opts(d, cmd, [:UVXY :JZ :p :t :params])
	cmd = parse_these_opts(cmd, d, [[:D :ref_point], [:G :bit_color], [:I :invert_1bit], [:M :monochrome]])
	cmd = add_opt(cmd, 'F', d, [:F :box], (clearance="+c", fill=("+g", add_opt_fill), inner="+i",
	                                       pen=("+p", add_opt_pen), rounded="+r", shade="+s"))

	cmd, got_fname, arg1 = find_data(d, cmd0, cmd, 1, arg1)		# Find how data was transmitted

	cmd = finish_PS(d, cmd, output, K, O)
	return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, "psimage", arg1)
end

# ---------------------------------------------------------------------------------------------------
image!(cmd0::String="", arg1=[]; kw...) = image(cmd0, arg1; first=false, kw...)

# ---------------------------------------------------------------------------------------------------
const psimage  = image			# Alias
const psimage! = image!			# Alias