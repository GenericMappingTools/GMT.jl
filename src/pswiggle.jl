"""
	wiggle(cmd0::String="", arg1=[]; kwargs...)

Reads (length,azimuth) pairs from file and plot a windwiggle diagram.

Full option list at [`pswiggle`](http://gmt.soest.hawaii.edu/doc/latest/wiggle.html)

Parameters
----------

- $(GMT.opt_R)
- **Z** : **scale** : -- Number or Str --

    Gives anomaly scale in data-units/distance-unit.
    [`-Z`](http://gmt.soest.hawaii.edu/doc/latest/wiggle.html#z)
- **A** : **azimuth** : -- Str or number --

    Sets the preferred positive azimuth. Positive wiggles will “gravitate” towards that direction.
    [`-A`](http://gmt.soest.hawaii.edu/doc/latest/wiggle.html#a)
- $(GMT.opt_B)
- **C** : **center** : -- Number --

    Subtract center from the data set before plotting [0].
    [`-C`](http://gmt.soest.hawaii.edu/doc/latest/wiggle.html#c)
- **D** : **scale_bar** : -- Str --

    Defines the reference point on the map for the vertical scale bar using one of four coordinate systems.
    [`-D`](http://gmt.soest.hawaii.edu/doc/latest/wiggle.html#d)
- **F** : **box** : -- Str --

    Without further options, draws a rectangular border around the vertical scale bar.
    [`-F`](http://gmt.soest.hawaii.edu/doc/latest/wiggle.html#f)
- **G** : **fill** : -- Number or Str --

    Set fill shade, color or pattern for positive and/or negative wiggles [Default is no fill].
    [`-G`](http://gmt.soest.hawaii.edu/doc/latest/wiggle.html#g)
- **I** : **fixed_azim** : -- Number --

    Set a fixed azimuth projection for wiggles [Default uses track azimuth, but see -A].
    [`-I`](http://gmt.soest.hawaii.edu/doc/latest/wiggle.html#i)
- $(GMT.opt_J)
- $(GMT.opt_Jz)
- $(GMT.opt_P)
- **T** : **track** : -- Number or Str or Tuple or [] --

    Draw track [Default is no track]. Append pen attributes to use [Defaults: width = 0.25p, color =
    black, style = solid].
    [`-T`](http://gmt.soest.hawaii.edu/doc/latest/wiggle.html#t)
- **W** : **pen** : -- Number or Str or tuple or [] --

    Specify outline pen attributes [Default is no outline].
    [`-W`](http://gmt.soest.hawaii.edu/doc/latest/wiggle.html#w)
- $(GMT.opt_U)
- $(GMT.opt_V)
- $(GMT.opt_X)
- $(GMT.opt_Y)
- $(GMT.opt_bi)
- $(GMT.opt_di)
- $(GMT.opt_e)
- $(GMT.opt_h)
- $(GMT.opt_i)
- $(GMT.opt_p)
- $(GMT.opt_t)
- $(GMT.opt_swap_xy)
"""
function wiggle(cmd0::String="", arg1=[]; K=false, O=false, first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("pswiggle", cmd0, arg1)	# Speedy mode

	d = KW(kwargs)
	output, opt_T, fname_ext = fname_out(d)		# OUTPUT may have been an extension only

	K, O = set_KO(first)		# Set the K O dance
	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/12c")
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_di = parse_di(cmd, d)
	cmd, opt_i  = parse_i(cmd, d)
	cmd = parse_common_opts(d, cmd, [:e :f :g :h :p :t :xy :JZ :UVXY :params])
	cmd = parse_these_opts(cmd, d, [[:A :azimuth], [:C :center], [:D :scale_bar], [:I :fixed_azim], [:Z :scale]])

	# If file name sent in, read it and compute a tight -R if this was not provided
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R, opt_i, opt_bi, opt_di)

	cmd = add_opt(cmd, 'F', d, [:F :box], (clearance="+c", fill=("+g", add_opt_fill), inner="+i",
	                                       pen=("+p", add_opt_pen), rounded="+r", shade="+s"))
	cmd *= opt_pen(d, 'T', [:T :track])
	cmd *= opt_pen(d, 'W', [:W :pen])
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')

	cmd = finish_PS(d, cmd, output, K, O)
	return finish_PS_module(d, cmd, "", output, fname_ext, opt_T, K, "pswiggle", arg1)
end

# ---------------------------------------------------------------------------------------------------
wiggle!(cmd0::String="", arg1=[]; K=true, O=true,  first=false, kw...) =
	wiggle(cmd0, arg1; K=K, O=O,  first=first, kw...)

wiggle(arg1=[], cmd0::String=""; K=false, O=false,  first=true, kw...) =
	wiggle(cmd0, arg1; K=K, O=O,  first=first, kw...)

wiggle!(arg1=[], cmd0::String=""; K=true, O=true,  first=false, kw...) =
	wiggle(cmd0, arg1; K=K, O=O,  first=first, kw...)

pswiggle  = wiggle			# Alias
pswiggle! = wiggle!			# Alias