"""
	wiggle(cmd0::String="", arg1=nothing; kwargs...)

Reads (length,azimuth) pairs from file and plot a windwiggle diagram.

Full option list at [`pswiggle`]($(GMTdoc)wiggle.html)

Parameters
----------

- $(GMT.opt_R)
- **Z** | **scale** :: [Type => Number | Str]

    Gives anomaly scale in data-units/distance-unit.
    ($(GMTdoc)wiggle.html#a)
- **A** | **azimuth** :: [Type => Str | number]

    Sets the preferred positive azimuth. Positive wiggles will “gravitate” towards that direction.
    ($(GMTdoc)wiggle.html#a)
- $(GMT.opt_B)
- **C** | **center** :: [Type => Number]

    Subtract center from the data set before plotting [0].
    ($(GMTdoc)wiggle.html#c)
- **D** | **scale_bar** :: [Type => Str]

    Defines the reference point on the map for the vertical scale bar using one of four coordinate systems.
    ($(GMTdoc)wiggle.html#d)
- **F** | **box** :: [Type => Str]

    Without further options, draws a rectangular border around the vertical scale bar.
    ($(GMTdoc)wiggle.html#f)
- **G** | **fill** :: [Type => Number | Str]

    Set fill shade, color or pattern for positive and/or negative wiggles [Default is no fill].
    ($(GMTdoc)wiggle.html#g)
- **I** | **fixed_azim** :: [Type => Number]

    Set a fixed azimuth projection for wiggles [Default uses track azimuth, but see -A].
    ($(GMTdoc)wiggle.html#i)
- $(GMT.opt_J)
- $(GMT.opt_P)
- **T** | **track** :: [Type => Number or Str | Tuple | []]

    Draw track [Default is no track]. Append pen attributes to use [Defaults: width = 0.25p, color =
    black, style = solid].
    ($(GMTdoc)wiggle.html#t)
- **W** | **pen** :: [Type => Number | Str | tuple | []]

    Specify outline pen attributes [Default is no outline].
    ($(GMTdoc)wiggle.html#w)
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
    K, O = set_KO(first)		# Set the K O dance

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

	return finish_PS_module(d, "pswiggle " * cmd, "", K, O, true, arg1)
end

# ---------------------------------------------------------------------------------------------------
wiggle!(cmd0::String="", arg1=nothing; first=false, kw...) = wiggle(cmd0, arg1; first=first, kw...)
wiggle(arg1,  cmd0::String=""; first=true, kw...)  = wiggle(cmd0, arg1; first=first, kw...)
wiggle!(arg1, cmd0::String=""; first=false, kw...) = wiggle(cmd0, arg1; first=first, kw...)

const pswiggle  = wiggle			# Alias
const pswiggle! = wiggle!			# Alias