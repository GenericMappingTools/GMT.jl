"""
	wiggle(cmd0::String="", arg1=[]; kwargs...)

Reads (length,azimuth) pairs from file and plot a windwiggle diagram.

Full option list at [`pswiggle`](http://gmt.soest.hawaii.edu/doc/latest/pswiggle.html)

Parameters
----------

- $(GMT.opt_R)
- **Z** : **scale** : -- Number or Str --

    Gives anomaly scale in data-units/distance-unit.
	[`-Z`](http://gmt.soest.hawaii.edu/doc/latest/pswiggle.html#z)
- **A** : **azimuth** : -- Str or number --

    Sets the preferred positive azimuth. Positive wiggles will “gravitate” towards that direction.
	[`-A`](http://gmt.soest.hawaii.edu/doc/latest/pswiggle.html#a)
- $(GMT.opt_B)
- **C** : **center** : -- Number --

    Subtract center from the data set before plotting [0].
	[`-C`](http://gmt.soest.hawaii.edu/doc/latest/pswiggle.html#c)
- **D** : **scale_bar** : -- Str --

    Defines the reference point on the map for the vertical scale bar using one of four coordinate systems.
	[`-D`](http://gmt.soest.hawaii.edu/doc/latest/pswiggle.html#d)
- **F** : **bar_rectangle** : -- Str --

    Without further options, draws a rectangular border around the vertical scale bar.
	[`-F`](http://gmt.soest.hawaii.edu/doc/latest/pswiggle.html#f)
- **G** : **fill** : -- Number or Str --

    Set fill shade, color or pattern for positive and/or negative wiggles [Default is no fill].
	[`-G`](http://gmt.soest.hawaii.edu/doc/latest/pswiggle.html#g)
- **I** : **fixed_azim** : -- Number --

    Set a fixed azimuth projection for wiggles [Default uses track azimuth, but see -A].
	[`-I`](http://gmt.soest.hawaii.edu/doc/latest/pswiggle.html#i)
- $(GMT.opt_J)
- $(GMT.opt_Jz)
- $(GMT.opt_P)
- **T** : **pen** : -- Number or Str or Tuple or [] --

    Draw track [Default is no track]. Append pen attributes to use [Defaults: width = 0.25p, color =
    black, style = solid].
	[`-T`](http://gmt.soest.hawaii.edu/doc/latest/pswiggle.html#t)
- **W** : **pen** : -- Number or Str or tuple or [] --

    Specify outline pen attributes [Default is no outline].
	[`-W`](http://gmt.soest.hawaii.edu/doc/latest/pswiggle.html#w)
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

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, cmd0, "", "", O, " -JX12c/12c")
	cmd = parse_JZ(cmd, d)
	cmd = parse_UVXY(cmd, d)
	cmd, opt_bi = parse_bi(cmd, d)
	cmd, opt_di = parse_di(cmd, d)
	cmd, = parse_e(cmd, d)
	cmd, = parse_f(cmd, d)
	cmd, = parse_g(cmd, d)
	cmd, = parse_h(cmd, d)
	cmd, opt_i = parse_i(cmd, d)
	cmd, = parse_p(cmd, d)
	cmd, = parse_t(cmd, d)
	cmd, = parse_swap_xy(cmd, d)
	cmd = parse_params(cmd, d)

	cmd, K, O, opt_B = set_KO(cmd, opt_B, first, K, O)		# Set the K O dance

	# If file name sent in, read it and compute a tight -R if this was not provided
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R, opt_i, opt_bi, opt_di)

	cmd = add_opt(cmd, 'A', d, [:A :azimuth])
	cmd = add_opt(cmd, 'C', d, [:C :center])
	cmd = add_opt(cmd, 'D', d, [:D :scale_bar])
	cmd = add_opt(cmd, 'F', d, [:F :bar_rectangle])
	cmd = add_opt(cmd, 'G', d, [:G :fill])
	cmd = add_opt(cmd, 'I', d, [:I :fixed_azim])
	cmd = cmd * opt_pen(d, 'T', [:T :pen])
	cmd = cmd * opt_pen(d, 'W', [:W :pen])
	cmd = add_opt(cmd, 'Z', d, [:Z :scale])

	cmd = finish_PS(d, cmd0, cmd, output, K, O)

	return finish_PS_module(d, cmd, "", arg1, [], [], [], [], [], output, fname_ext, opt_T, K, "pswiggle")
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