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
# ---------------------------------------------------------------------------------------------------
function image(cmd0::String="", arg1=[]; data=[], fmt::String="",
               K=false, O=false, first=true, kwargs...)

	length(kwargs) == 0 && isempty_(data) && return monolitic("psimage", cmd0, arg1)	# Speedy mode
	output, opt_T, fname_ext = fname_out(fmt)		# OUTPUT may have been an extension only

	if (!isempty_(data) && !isa(data, String))
		error("When using 'data', it MUST contain a String data type (the file name)")
	end

	d = KW(kwargs)
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd0, "", "", O, " -JX12c/12c")
	cmd = parse_JZ(cmd, d)
	cmd = parse_UVXY(cmd, d)
	cmd = parse_p(cmd, d)
	cmd = parse_t(cmd, d)

	cmd = add_opt(cmd, 'D', d, [:D :ref_point])
	cmd = add_opt(cmd, 'F', d, [:F :box])
	cmd = add_opt(cmd, 'G', d, [:G :bit_color])
	cmd = add_opt(cmd, 'I', d, [:I :invert_1bit])
	cmd = add_opt(cmd, 'M', d, [:M :monochrome])

	# In case DATA holds a file name, copy it into cmd.
	cmd, arg1, = read_data(data, cmd, arg1)

	(haskey(d, :Vd)) && println(@sprintf("\tpsimage %s", cmd))

	cmd = finish_PS(d, cmd0, cmd, output, K, O)
	return finish_PS_module(d, cmd, "", arg1, [], [], [], [], [], output, fname_ext, opt_T, K, "psimage")
end

# ---------------------------------------------------------------------------------------------------
image!(cmd0::String="", arg1=[]; data=[], fmt::String="", K=true, O=true,  first=false, kw...) =
	image(cmd0, arg1; data=data, fmt=fmt, K=K, O=O,  first=first, kw...)