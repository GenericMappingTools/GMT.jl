"""
	wiggle(cmd0::String="", arg1=nothing; kwargs...)

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
function wiggle(cmd0::String="", arg1=nothing; first=true, kwargs...)

	length(kwargs) == 0 && return monolitic("pswiggle", cmd0, arg1)

	d = KW(kwargs)
	output, opt_T, fname_ext, K, O = fname_out(d, first)		# OUTPUT may have been an extension only

	cmd, opt_B, opt_J, opt_R = parse_BJR(d, "", "", O, " -JX12c/0")
	cmd = parse_common_opts(d, cmd, [:c :e :f :g :p :t :yx :F :UVXY :params], first)
	cmd = parse_these_opts(cmd, d, [[:A :azimuth], [:C :center], [:I :fixed_azim], [:S], [:Z :scale]])

	# If file name sent in, read it and compute a tight -R if this was not provided
	cmd, arg1, opt_R, = read_data(d, cmd0, cmd, arg1, opt_R)

	cmd = add_opt(cmd, "D", d, [:D :scale_bar],
        (map=("g", nothing, 1), inside=("j", nothing, 1), anchor=("", arg2str, 2), width="+w", justify="+j", label_left="_+al", labels="+l", label="+l", offset="+o"))
    #cmd = parse_type_anchor(d, cmd, [[:D :scale_bar]])
	cmd *= opt_pen(d, 'T', [:T :track])
	cmd *= opt_pen(d, 'W', [:W :pen])
	cmd = add_opt_fill(cmd, d, [:G :fill], 'G')

	return finish_PS_module(d, "pswiggle " * cmd, "", output, fname_ext, opt_T, K, O, true, arg1)
end

# ---------------------------------------------------------------------------------------------------
wiggle!(cmd0::String="", arg1=nothing; first=false, kw...) = wiggle(cmd0, arg1; first=first, kw...)
wiggle(arg1,  cmd0::String=""; first=true, kw...)  = wiggle(cmd0, arg1; first=first, kw...)
wiggle!(arg1, cmd0::String=""; first=false, kw...) = wiggle(cmd0, arg1; first=first, kw...)

const pswiggle  = wiggle			# Alias
const pswiggle! = wiggle!			# Alias